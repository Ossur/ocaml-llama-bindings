let () =
  match Sys.argv with
  | [| _; model_path; prompt |] ->
    Llama.with_model model_path (fun model ->
        Llama.with_context model (fun ctx ->
            Llama.with_sampler ~kind:(Llama.Temperature { temp = 0.8; seed = 1234l }) ()
              (fun sampler ->
                let output = Llama.generate ctx sampler ~prompt ~max_tokens:128 in
                print_string output;
                print_newline ())))
  | _ ->
    Printf.eprintf "usage: %s <model.gguf> <prompt>\n" Sys.argv.(0);
    exit 1
