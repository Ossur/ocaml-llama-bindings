open Ctypes

module Types = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct
  open F

  let backend_init = foreign "llama_backend_init" (void @-> returning void)
  let backend_free = foreign "llama_backend_free" (void @-> returning void)

  let model_default_params =
    foreign "llama_model_default_params" (void @-> returning Types.model_params)

  let context_default_params =
    foreign "llama_context_default_params" (void @-> returning Types.context_params)

  let sampler_chain_default_params =
    foreign "llama_sampler_chain_default_params"
      (void @-> returning Types.sampler_chain_params)

  let model_load_from_file =
    foreign "llama_model_load_from_file"
      (string @-> Types.model_params @-> returning Types.llama_model)

  let model_free = foreign "llama_model_free" (Types.llama_model @-> returning void)

  let model_get_vocab =
    foreign "llama_model_get_vocab" (Types.llama_model @-> returning Types.llama_vocab)

  let init_from_model =
    foreign "llama_init_from_model"
      (Types.llama_model @-> Types.context_params @-> returning Types.llama_context)

  let free = foreign "llama_free" (Types.llama_context @-> returning void)

  let vocab_is_eog =
    foreign "llama_vocab_is_eog" (Types.llama_vocab @-> int32_t @-> returning bool)

  let tokenize =
    foreign "llama_tokenize"
      (Types.llama_vocab @-> string @-> int32_t @-> ptr int32_t @-> int32_t @-> bool
      @-> bool @-> returning int32_t)

  let token_to_piece =
    foreign "llama_token_to_piece"
      (Types.llama_vocab @-> int32_t @-> ptr char @-> int32_t @-> int32_t @-> bool
      @-> returning int32_t)

  let batch_get_one =
    foreign "llama_batch_get_one" (ptr int32_t @-> int32_t @-> returning Types.batch)

  let decode =
    foreign "llama_decode" (Types.llama_context @-> Types.batch @-> returning int32_t)

  let sampler_chain_init =
    foreign "llama_sampler_chain_init"
      (Types.sampler_chain_params @-> returning Types.llama_sampler)

  let sampler_chain_add =
    foreign "llama_sampler_chain_add"
      (Types.llama_sampler @-> Types.llama_sampler @-> returning void)

  let sampler_init_greedy =
    foreign "llama_sampler_init_greedy" (void @-> returning Types.llama_sampler)

  let sampler_init_temp =
    foreign "llama_sampler_init_temp" (float @-> returning Types.llama_sampler)

  let sampler_init_dist =
    foreign "llama_sampler_init_dist" (uint32_t @-> returning Types.llama_sampler)

  let sampler_sample =
    foreign "llama_sampler_sample"
      (Types.llama_sampler @-> Types.llama_context @-> int32_t @-> returning int32_t)

  let sampler_free = foreign "llama_sampler_free" (Types.llama_sampler @-> returning void)
end
