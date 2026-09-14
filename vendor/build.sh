#!/usr/bin/env bash
# Builds llama.cpp (pinned submodule) as a static library and installs it
# under vendor/install, with a pkg-config file for dune's ctypes stanza to find.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/llama.cpp"
BUILD="$HERE/build"
PREFIX="$HERE/install"

cmake -S "$SRC" -B "$BUILD" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_TOOLS=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DLLAMA_BUILD_APP=OFF \
  -DLLAMA_CURL=OFF

cmake --build "$BUILD" --config Release -j"$(nproc)"
cmake --install "$BUILD"

echo "Installed llama.cpp to $PREFIX"
