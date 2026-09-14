# ocaml_llama_bindings

OCaml bindings for [llama.cpp](https://github.com/ggml-org/llama.cpp) (pinned
at `v0.4.0`), built with dune's ctypes stub generator (no hand-written C
stubs, no hand-transcribed struct layouts — offsets/sizes are queried from
the real header by the C compiler at build time).

Requires OCaml >= 5.3.

## Layout

- `vendor/llama.cpp` — the llama.cpp source, as a pinned git submodule.
- `vendor/build.sh` — builds llama.cpp as a static, position-independent
  library and installs it to `vendor/install`.
- `lib/bindings` — the raw ctypes bindings (`Llama_bindings.C.Types`,
  `Llama_bindings.C.Functions`), generated from `include/llama.h` at build
  time.
- `lib/llama` — a small idiomatic OCaml wrapper (`Llama.with_model`,
  `Llama.with_context`, `Llama.with_sampler`, `Llama.generate`).
- `bin/main.ml` — a smoke-test CLI: `dune exec bin/main.exe -- model.gguf "prompt"`.

## Prerequisites

OCaml >= 5.3, opam packages `ctypes` and `ctypes-foreign`, and a toolchain
able to build llama.cpp: `cmake`, a C/C++ compiler, and OpenMP (`libgomp`).

## Building

```sh
git submodule update --init --recursive
./vendor/build.sh      # builds + installs libllama.a etc. to vendor/install
dune build
```

## Scope (v1)

Model load/free, context creation, tokenize/token-to-piece, single-sequence
greedy or temperature+distribution sampling, and blocking text generation.
Not yet covered: streaming, batching/multi-sequence, GPU backends, LoRA,
grammar-constrained sampling, chat templates, `llama_detokenize`.
