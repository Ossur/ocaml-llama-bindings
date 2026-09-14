(lang dune 3.17)
(using ctypes 0.3)

(name ocaml_llama_bindings)

(package
 (name ocaml_llama_bindings)
 (allow_empty)
 (synopsis "OCaml bindings for llama.cpp")
 (description "ctypes-based OCaml bindings for the llama.cpp C API (llama.cpp v0.4.0)")
 (depends
  (ocaml (>= 5.3))
  dune
  ctypes
  ctypes-foreign))
