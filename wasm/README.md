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
| `GPRBUILD`           | `gprbuild` (use `alr exec -- gprbuild` under Alire) |

## Build and run

```sh
cd wasm
#  Exported once: every build goal needs it, only serve/serve-dist/clean do not.
export LLVM_INTERFACE_DIR=/path/to/gnat-llvm/llvm-interface
export GPRBUILD="alr exec -- gprbuild"   # under Alire

make EXAMPLE=button_example
make serve            # http://localhost:8000/button_example.html
make showcase         # every browser-capable example + index page
make dist             # publishable copy of the above
make serve-dist       # http://localhost:8000/ against that copy
```

Two output directories:

- `build/` — what emcc links, under plain names. `make serve` serves it.
  The iterate-and-refresh surface.
- `dist/` — a copy of `build/` with the `.js` and `.wasm` renamed to carry
  a content hash, so they can be served with a far-future `Cache-Control`
  and a stale `.wasm` can never pair against a fresh `.js`. Example
  *pages* keep plain names so deep links stay valid; only the assets they
  load are hashed, and each page's hash goes into the index's `BUILD`
  map. This is the directory you upload.

`make dist` builds the showcase first, so it cannot publish a stale
binary. Nothing here uploads anything.

## Main-loop modes

- `LOOP=callbacks` — SDL main callbacks. This is the normal way to
  target the browser: it runs everywhere. Main's stack is torn down
  after startup, so application state and callbacks must live at
  package level.
- `LOOP=blocking` — the native `Adi.App` loop suspended via JSPI
  (`emscripten_sleep`). Runs the desktop examples verbatim: their
  locals and nested callbacks survive because main's stack never
  unwinds. The showcase defaults to this mode since its examples are
  desktop code reused unchanged. Requires a JSPI-capable browser.

JSPI (JavaScript Promise Integration) is the WebAssembly standard for
**stack switching**: when wasm calls a suspending import — here
`emscripten_sleep` — the VM parks the whole wasm call stack as a
first-class object and returns to the browser event loop, then resumes
it where it left off when the frame timer resolves. That is why the
native blocking `Run` works unchanged: main's stack, with every example
local and nested callback frame, physically persists between frames
instead of being unwound. It is a VM feature rather than code
instrumentation, which is also why it composes with
`-fwasm-exceptions`. The proposal reached Phase 4 in 2026.

| Engine                   | JSPI status                                    |
|--------------------------|------------------------------------------------|
| Chrome / Edge / Chromium | Shipped by default since Chrome 137            |
| Firefox                  | Firefox 139, behind `javascript.options.wasm_js_promise_integration` |
| Safari                   | Not yet; WebKit objection withdrawn, engineer assigned |
| Node.js                  | Behind the V8 JSPI flag                        |

Hoisting the examples' captured state to package level would let the
showcase run under `callbacks` everywhere; not done. A page-side
feature detect (`"Suspending" in WebAssembly`) can pick between two
builds if you ship both.

## What the showcase contains

`make showcase` builds 24 of the 27 example mains. `html_view_example`
and `material_demo` reach `Adi.MCP`, which resolves to the
`src/mcp_stub` no-ops; `combo_box_example` and `label_example` use
Settings, which work for the session over MEMFS. Three are excluded:

- `runtime_css_example` — its purpose is Dynamic_Mode live-reload, and
  nothing outside the page can touch MEMFS.
- `text_editor_example` — native open/save dialogs
  (`Adi.OS_Integration`); browser file access needs its own JS glue.
- `hello_raw_example` — renders identically to `hello_example`.

Not available inside the browser sandbox: tasks and protected objects
(unsupported on wasm32, and the library uses neither), native file
dialogs and clipboard, MCP introspection (its IPC is filesystem plus an
external process), CSS live-reload, and settings persistence beyond the
session — an IDBFS mount plus `syncfs` glue would lift that last one.

## Build hygiene

- **After updating the RTS, wipe `obj/`.** adawebpack `08b2a3d` flipped
  `Always_Compatible_Rep` to False to give access-to-subprogram values
  a fat (code + activation record) representation. That is an ABI
  change, and the Makefile does not track the RTS as a dependency, so
  objects compiled against an older RTS are silently invalid.
- **Before a publishable build, wipe `obj/<loop>`.** The link step
  globs every object in the shared per-mode object dir, and gprbuild
  only refreshes the closure of the example it is building, so objects
  left from an older source state are linked as they are. `make dist`
  depends on `showcase`, which rebuilds all 24, but a one-off
  `make EXAMPLE=foo` against a dirty dir will mix source generations.
  The tell is a `wasm-ld` signature mismatch naming an `obj/` file.
- **Do not add `-gnatW8`.** Generated UI packages carry raw UTF-8 in
  String literals with byte semantics; W8 lexes those as wide
  characters and rejects them. Native `examples.gpr` builds without it
  too.

Warnings that are expected and not worth chasing:

- `wasm-ld` signature mismatches for `__gnat_dup2`, `__gnat_lseek` and
  `strncpy` between `s-os_lib.o` (procedure imports) and
  `adaint.o`/libc (int-returning). An RTS wart, harmless unless those
  routines are called; worth fixing in adawebpack.
- `cannot pass "FG"/"BG" by copy` on `Adi.SDL.TTF`'s LCD render
  bindings — adi2 never calls the LCD functions.
- `-sJSPI (ASYNCIFY=2) is still experimental` from emcc.

Still open: the SDL event unchecked conversions warn about size on
wasm32, where 32-bit pointers shrink the sub-event records. Offsets
should match the wasm32 C ABI since the bindings use `Interfaces.C`
types throughout, but event decoding has only been confirmed by use,
not audited. Exceptions that escape main surface as a bare
`WebAssembly.Exception` with no message: the RTS has no last-chance
handler on that path.

## Layout

```
adi_wasm.gpr   compiles + binds one example's Ada closure (gprbuild
               only: -c -b; emcc does the link)
src/           wasm substitute bodies — Adi.Dispatch as a plain vector
               queue, Adi.Clock over SDL ticks, and the SDL
               main-callback Adi.App used by LOOP=callbacks
pre-js/        ada_runtime_support.js (__gnat_grow, __gnat_put_exception),
               sdl3_ada_pre.js (defers main in callbacks mode),
               adi_env.js (pins ADI_FALLBACK_FONT to the embed)
site/index.html   the navigator: navbar with the example switcher, About
               modal, and an iframe holding the current example. Keep
               its list in sync with SHOWCASE_EXAMPLES.
site/shell.html   emcc --shell-file for every example page: centered
               transparent canvas, collapsible log, no emscripten
               branding. Opened directly it forwards to index.html so a
               bookmarked page keeps its switcher.
```

Embedded into every example at the repo-relative paths it uses natively
(Emscripten's CWD is `/`): `examples/assets` — also the `app://` root —
`examples/css`, and `OpenSans-Regular.ttf`, which `adi_env.js` pins as
the fallback face so text metrics do not depend on the build machine's
installed fonts.

## Documentation

- `FINDINGS.md` — reference notes on the GNAT-LLVM/AdaWebPack/Emscripten
  stack, independent of Adi2: what the WASM RTS provides, the SDL3
  browser app pattern, link flags, and the compiler-side fixes this
  port depends on.
