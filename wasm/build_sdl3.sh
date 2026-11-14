#!/usr/bin/env bash
# SDL3, SDL3_image and SDL3_ttf for Emscripten, built with -fwasm-exceptions
# as the Makefile links them, and installed as sdl3-prefix,
# sdl3-image-prefix and sdl3-ttf-prefix in DIR: the Makefile's SDL3_ROOT.
# Usage: wasm/build_sdl3.sh DIR [WORK]
# emcmake must be on PATH (emsdk_env.sh), and cmake and ninja installed.
# WORK holds the sources and build trees; by default a temporary
# directory, removed afterwards.
set -euo pipefail

SDL_VERSION=3.4.2
SDL_IMAGE_VERSION=3.4.0
SDL_TTF_VERSION=3.2.2

DIR=$(mkdir -p "${1:?usage: $0 DIR [WORK]}" && cd "$1" && pwd)
if [ -n "${2:-}" ]; then
    WORK=$(mkdir -p "$2" && cd "$2" && pwd)
else
    WORK=$(mktemp -d)
    trap 'rm -rf "$WORK"' EXIT
fi
cd "$WORK"

FLAGS=(-G Ninja -DCMAKE_BUILD_TYPE=Release
       -DCMAKE_C_FLAGS=-fwasm-exceptions -DCMAKE_CXX_FLAGS=-fwasm-exceptions)

# fetch NAME URL: the release tarball, unpacked once
fetch() {
    [ -f "$1.tar.gz" ] || curl -fsSL -o "$1.tar.gz" "$2"
    [ -d "$1" ] || tar -xf "$1.tar.gz"
}

echo "== SDL3 $SDL_VERSION"
fetch "SDL3-$SDL_VERSION" \
    "https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VERSION/SDL3-$SDL_VERSION.tar.gz"
emcmake cmake -S "SDL3-$SDL_VERSION" -B sdl3-build "${FLAGS[@]}" \
    -DSDL_SHARED=OFF -DSDL_STATIC=ON \
    -DCMAKE_INSTALL_PREFIX="$DIR/sdl3-prefix"
cmake --build sdl3-build
cmake --install sdl3-build

echo "== SDL3_image $SDL_IMAGE_VERSION"
fetch "SDL3_image-$SDL_IMAGE_VERSION" \
    "https://github.com/libsdl-org/SDL_image/releases/download/release-$SDL_IMAGE_VERSION/SDL3_image-$SDL_IMAGE_VERSION.tar.gz"
emcmake cmake -S "SDL3_image-$SDL_IMAGE_VERSION" -B sdl3-image-build "${FLAGS[@]}" \
    -DBUILD_SHARED_LIBS=OFF -DSDLIMAGE_SAMPLES=OFF -DSDLIMAGE_TESTS=OFF \
    -DSDL3_DIR="$WORK/sdl3-build" \
    -DCMAKE_INSTALL_PREFIX="$DIR/sdl3-image-prefix"
cmake --build sdl3-image-build
cmake --install sdl3-image-build

echo "== SDL3_ttf $SDL_TTF_VERSION"
fetch "SDL3_ttf-$SDL_TTF_VERSION" \
    "https://github.com/libsdl-org/SDL_ttf/releases/download/release-$SDL_TTF_VERSION/SDL3_ttf-$SDL_TTF_VERSION.tar.gz"
# FreeType and HarfBuzz, vendored
[ -d "SDL3_ttf-$SDL_TTF_VERSION/external/freetype/src" ] ||
    (cd "SDL3_ttf-$SDL_TTF_VERSION/external" && sh download.sh --depth 1)
emcmake cmake -S "SDL3_ttf-$SDL_TTF_VERSION" -B sdl3-ttf-build "${FLAGS[@]}" \
    -DBUILD_SHARED_LIBS=OFF -DSDLTTF_VENDORED=ON -DSDLTTF_HARFBUZZ=ON \
    -DSDLTTF_PLUTOSVG=OFF -DSDLTTF_SAMPLES=OFF -DSDLTTF_INSTALL=ON \
    -DSDL3_DIR="$WORK/sdl3-build" \
    -DCMAKE_INSTALL_PREFIX="$DIR/sdl3-ttf-prefix"
cmake --build sdl3-ttf-build
cmake --install sdl3-ttf-build

ls -l "$DIR/sdl3-prefix/lib/libSDL3.a" \
      "$DIR/sdl3-image-prefix/lib/libSDL3_image.a" \
      "$DIR/sdl3-ttf-prefix/lib/libSDL3_ttf.a"
