# Adi2 in the browser

WebAssembly build of the Adi2 examples. Live demo:
<https://pizzahack.eu/adi2/demo/>

## Toolchain

Two forks provide the compiler and the WASM Ada runtime, prebuilt
instructions included in their READMEs:

- <https://github.com/ovenpasta/gnat-llvm> — GNAT-LLVM with the wasm32
  target (build the EH runtime: `make wasm-emcc-eh`)
- <https://github.com/ovenpasta/adawebpack> — WASM RTS overrides, JS
  glue, and the SDL3/SDL3_ttf/SDL3_image wasm prefixes, all built with
  `-fwasm-exceptions` per its sdl3 examples README (checked out inside
  gnat-llvm as `llvm-interface/adawebpack_src`)

Plus a system `emscripten`.

Makefile variables, override as needed:

| Variable             | Value                                |
|----------------------|--------------------------------------|
| `LLVM_INTERFACE_DIR` | *(required)* — your gnat-llvm checkout's `llvm-interface` |
| `LLVM_SYS_BIN`       | `/usr/lib/llvm21/bin`                |
| `EMCC`               | `/usr/lib/emscripten/emcc`           |
| `FONT_FILE`          | `/usr/share/fonts/noto/NotoSans-Regular.ttf` |
| `GPRBUILD`           | `gprbuild` (use `alr exec -- gprbuild` under Alire) |

## Build and run

```sh
cd wasm
#  Exported once: every build goal needs it, only serve/deploy/clean do not.
export LLVM_INTERFACE_DIR=/path/to/gnat-llvm/llvm-interface
export GPRBUILD="alr exec -- gprbuild"   # under Alire

make EXAMPLE=button_example
make serve            # http://localhost:8000/button_example.html
make showcase         # every browser-capable example + index page
make deploy           # dist/ with content-hashed js/wasm names
```

Two main-loop modes:

- `LOOP=callbacks` — SDL main callbacks. This is the normal way to
  target the browser: it runs everywhere. Main's stack is torn down
  after startup, so application state and callbacks must live at
  package level.
- `LOOP=blocking` — the native `Adi.App` loop suspended via JSPI
  (`emscripten_sleep`). Runs the desktop examples verbatim: their
  locals and nested callbacks survive because main's stack never
  unwinds. The showcase defaults to this mode since its examples are
  desktop code reused unchanged. Requires a JSPI-capable browser
  (Chrome).

## Documentation

- `PORT_REPORT.md` — the port itself: blockers found and their fixes,
  build strategy, JSPI notes, example status
- `FINDINGS.md` — reference notes on the GNAT-LLVM/AdaWebPack/Emscripten
  stack, independent of Adi2
