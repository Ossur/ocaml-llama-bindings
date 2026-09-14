open Ctypes
module C = Llama_bindings.C

type model = { model_p : unit ptr; mutable model_freed : bool }
type context = { ctx_p : unit ptr; vocab_p : unit ptr; mutable ctx_freed : bool }
type sampler = { smpl_p : unit ptr; mutable smpl_freed : bool }

let backend_initialized = ref false

let ensure_backend_init () =
  if not !backend_initialized then begin
    C.Functions.backend_init ();
    backend_initialized := true
  end

let load_model ?(n_gpu_layers = 0) path =
  ensure_backend_init ();
  let params = C.Functions.model_default_params () in
  setf params C.Types.mp_n_gpu_layers (Int32.of_int n_gpu_layers);
  let model_p = C.Functions.model_load_from_file path params in
  if is_null model_p then failwith (Printf.sprintf "failed to load model: %s" path);
  { model_p; model_freed = false }

let free_model m =
  if not m.model_freed then begin
    C.Functions.model_free m.model_p;
    m.model_freed <- true
  end

let new_context ?(n_ctx = 4096) ?(n_threads = 4) (m : model) =
  let params = C.Functions.context_default_params () in
  setf params C.Types.cp_n_ctx (Unsigned.UInt32.of_int n_ctx);
  setf params C.Types.cp_n_batch (Unsigned.UInt32.of_int n_ctx);
  setf params C.Types.cp_n_threads (Int32.of_int n_threads);
  setf params C.Types.cp_n_threads_batch (Int32.of_int n_threads);
  let ctx_p = C.Functions.init_from_model m.model_p params in
  if is_null ctx_p then failwith "failed to create llama context";
  let vocab_p = C.Functions.model_get_vocab m.model_p in
  { ctx_p; vocab_p; ctx_freed = false }

let free_context c =
  if not c.ctx_freed then begin
    C.Functions.free c.ctx_p;
    c.ctx_freed <- true
  end

type sampler_kind =
  | Greedy
  | Temperature of { temp : float; seed : int32 }

let new_sampler ?(kind = Greedy) () =
  let chain_params = C.Functions.sampler_chain_default_params () in
  let smpl_p = C.Functions.sampler_chain_init chain_params in
  (match kind with
  | Greedy -> C.Functions.sampler_chain_add smpl_p (C.Functions.sampler_init_greedy ())
  | Temperature { temp; seed } ->
    C.Functions.sampler_chain_add smpl_p (C.Functions.sampler_init_temp temp);
    C.Functions.sampler_chain_add smpl_p
      (C.Functions.sampler_init_dist (Unsigned.UInt32.of_int32 seed)));
  { smpl_p; smpl_freed = false }

let free_sampler s =
  if not s.smpl_freed then begin
    C.Functions.sampler_free s.smpl_p;
    s.smpl_freed <- true
  end

(* Two-pass ctypes idiom used throughout llama.cpp's C API: call once with a
   buffer that may be too small to learn the required size (returned back
   as a negative count), then call again with a buffer of that size. *)
let tokenize (c : context) ~add_special ~parse_special (text : string) : int32 array =
  let text_len = Int32.of_int (String.length text) in
  let try_tokenize n =
    let buf = CArray.make int32_t n in
    let written =
      C.Functions.tokenize c.vocab_p text text_len (CArray.start buf) (Int32.of_int n)
        add_special parse_special
    in
    (written, buf)
  in
  let n_written, buf = try_tokenize (String.length text + 8) in
  let n_written, buf =
    if Int32.to_int n_written < 0 then try_tokenize (- (Int32.to_int n_written))
    else (n_written, buf)
  in
  Array.init (Int32.to_int n_written) (fun i -> CArray.get buf i)

let token_to_piece (c : context) (token : int32) : string =
  let try_piece n =
    let buf = CArray.make char n in
    let written =
      C.Functions.token_to_piece c.vocab_p token (CArray.start buf) (Int32.of_int n) 0l true
    in
    (written, buf)
  in
  let n_written, buf = try_piece 32 in
  let n_written, buf =
    if Int32.to_int n_written < 0 then try_piece (- (Int32.to_int n_written))
    else (n_written, buf)
  in
  string_from_ptr (CArray.start buf) ~length:(Int32.to_int n_written)

let is_eog (c : context) (token : int32) = C.Functions.vocab_is_eog c.vocab_p token

(* Runs [prompt] through the model and greedily/temp-samples one token at a
   time, feeding each sampled token back in, until end-of-generation or
   [max_tokens] is reached. Blocking; releases the OCaml runtime lock while
   inside llama_decode (see the [concurrency unlocked] ctypes stub setting),
   so other domains keep running during a long decode. *)
let generate (c : context) (s : sampler) ~(prompt : string) ~(max_tokens : int) : string =
  let prompt_tokens = tokenize c ~add_special:true ~parse_special:true prompt in
  let buf = Buffer.create 256 in
  let decode_tokens (tokens : int32 array) =
    let arr = CArray.make int32_t (Array.length tokens) in
    Array.iteri (fun i t -> CArray.set arr i t) tokens;
    let batch = C.Functions.batch_get_one (CArray.start arr) (Int32.of_int (Array.length tokens)) in
    let rc = C.Functions.decode c.ctx_p batch in
    (* keep [arr] alive across the (runtime-lock-releasing) decode call above:
       [batch] only holds its raw address, not a reference to the block *)
    ignore (Sys.opaque_identity arr);
    if rc <> 0l then failwith (Printf.sprintf "llama_decode failed: %ld" rc)
  in
  decode_tokens prompt_tokens;
  let rec loop n token =
    if n >= max_tokens || is_eog c token then ()
    else begin
      Buffer.add_string buf (token_to_piece c token);
      decode_tokens [| token |];
      let next = C.Functions.sampler_sample s.smpl_p c.ctx_p (-1l) in
      loop (n + 1) next
    end
  in
  let first = C.Functions.sampler_sample s.smpl_p c.ctx_p (-1l) in
  loop 0 first;
  Buffer.contents buf

let with_model ?n_gpu_layers path f =
  let m = load_model ?n_gpu_layers path in
  Fun.protect ~finally:(fun () -> free_model m) (fun () -> f m)

let with_context ?n_ctx ?n_threads m f =
  let c = new_context ?n_ctx ?n_threads m in
  Fun.protect ~finally:(fun () -> free_context c) (fun () -> f c)

let with_sampler ?kind () f =
  let s = new_sampler ?kind () in
  Fun.protect ~finally:(fun () -> free_sampler s) (fun () -> f s)
