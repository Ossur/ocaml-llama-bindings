(** Idiomatic OCaml wrapper around the llama.cpp C API (v0.4.0). *)

type model
type context
type sampler

type sampler_kind =
  | Greedy
  | Temperature of { temp : float; seed : int32 }

val load_model : ?n_gpu_layers:int -> string -> model
val free_model : model -> unit

val new_context : ?n_ctx:int -> ?n_threads:int -> model -> context
val free_context : context -> unit

val new_sampler : ?kind:sampler_kind -> unit -> sampler
val free_sampler : sampler -> unit

val with_model : ?n_gpu_layers:int -> string -> (model -> 'a) -> 'a
val with_context : ?n_ctx:int -> ?n_threads:int -> model -> (context -> 'a) -> 'a
val with_sampler : ?kind:sampler_kind -> unit -> (sampler -> 'a) -> 'a

val tokenize : context -> add_special:bool -> parse_special:bool -> string -> int32 array
val token_to_piece : context -> int32 -> string
val is_eog : context -> int32 -> bool

(** Tokenizes [prompt], decodes it, then greedily or temperature-samples one
    token at a time (feeding each back in) until end-of-generation or
    [max_tokens] is reached. Blocking. *)
val generate : context -> sampler -> prompt:string -> max_tokens:int -> string
