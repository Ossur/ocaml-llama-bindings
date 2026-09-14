open Ctypes

(* llama_model / llama_context / llama_vocab / llama_sampler are opaque,
   forward-declared C structs (incomplete types) - only ever used behind a
   pointer, so we bind them as plain [ptr void], never as [structure]. *)
module Types (F : Ctypes.TYPE) = struct
  open F

  let llama_model = ptr void
  let llama_context = ptr void
  let llama_vocab = ptr void
  let llama_sampler = ptr void

  (* For the value-type structs below we only declare the fields we
     actually read or write. Because dune's ctypes stub generator queries
     offsetof/sizeof from the real "llama.h" via the C compiler, the
     structs are still sized and laid out correctly even though most
     fields (callbacks, GPU split arrays, experimental knobs, ...) are
     left undeclared here. *)

  type model_params
  let model_params : model_params structure typ = structure "llama_model_params"
  let mp_n_gpu_layers = field model_params "n_gpu_layers" int32_t
  let () = seal model_params

  type context_params
  let context_params : context_params structure typ = structure "llama_context_params"
  let cp_n_ctx = field context_params "n_ctx" uint32_t
  let cp_n_batch = field context_params "n_batch" uint32_t
  let cp_n_threads = field context_params "n_threads" int32_t
  let cp_n_threads_batch = field context_params "n_threads_batch" int32_t
  let () = seal context_params

  (* No fields of llama_sampler_chain_params are needed: we take the
     library's defaults as-is. *)
  type sampler_chain_params
  let sampler_chain_params : sampler_chain_params structure typ =
    structure "llama_sampler_chain_params"
  let () = seal sampler_chain_params

  (* llama_batch is only ever produced by [llama_batch_get_one] and passed
     straight into [llama_decode] - we never touch its fields from OCaml,
     so it stays fully opaque (still correctly sized/aligned via seal). *)
  type batch
  let batch : batch structure typ = structure "llama_batch"
  let () = seal batch
end
