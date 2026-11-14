# Adi2 in the browser

WebAssembly build of the Adi2 examples. Live demo:
<https://pizzahack.eu/adi2/demo/>

## Toolchain

- **GNAT-LLVM**, prebuilt as the `gnat_llvm` Alire toolchain, with the
  wasm runtimes. `alire.toml` here depends on it; add its index once:

  ```sh
  alr index --add git+https://github.com/ovenpasta/alire-index-gnat-llvm --name gnat_llvm
  ```

  Under `alr exec` it sets `GNAT_LLVM_PREFIX` and puts its compiler,
  clang and wasm-ld on `PATH`. The desktop build keeps its own compiler.
- **Emscripten 5.0.2**, from emsdk, with `emcc` on `PATH`:

  ```sh
  git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
  ~/emsdk/emsdk install 5.0.2 && ~/emsdk/emsdk activate 5.0.2
  source ~/emsdk/emsdk_env.sh      # in each shell that builds
  ```

- **SDL3 3.4.2, SDL3_image 3.4.0 and SDL3_ttf 3.2.2** built for
  Emscripten with `-fwasm-exceptions`, installed as `sdl3-prefix`,
  `sdl3-image-prefix` and `sdl3-ttf-prefix` in one directory, which
  `build_sdl3.sh DIR` does (it needs `cmake` and `ninja`, and emsdk's
  environment). The commands are adawebpack's
  [`examples/sdl3/README.md`](https://github.com/ovenpasta/adawebpack/blob/master/examples/sdl3/README.md).

Makefile variables, override as needed:

| Variable           | Value                                          |
|--------------------|------------------------------------------------|
| `SDL3_ROOT`        | *(required)* — the directory holding the three SDL prefixes |
| `GNAT_LLVM_PREFIX` | set by `alr exec`                              |
| `EMCC`, `EMXX`     | `emcc`, `em++`                                 |
| `EM_CACHE`         | Emscripten's own cache                         |
| `GPRBUILD`         | `gprbuild`                                     |

## Build and run

```sh
cd wasm
source ~/emsdk/emsdk_env.sh
#  Exported once: every build goal needs it, only serve/serve-dist/clean do not.
export SDL3_ROOT=/path/to/sdl3

alr exec -- make EXAMPLE=button_example
make serve                    # http://localhost:8000/button_example.html
alr exec -- make showcase     # every browser-capable example + index page
alr exec -- make dist         # publishable copy of the above
make serve-dist               # http://localhost:8000/ against that copy
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

`make showcase` builds 25 of the 28 example mains. `html_view_example`
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
  depends on `showcase`, which rebuilds all 25, but a one-off
  `make EXAMPLE=foo` against a dirty dir will mix source generations.
  The tell is a `wasm-ld` signature mismatch naming an `obj/` file.
- **Do not add `-gnatW8`.** Generated UI packages carry raw UTF-8 in
  String literals with byte semantics; W8 lexes those as wide
  characters and rejects them. Native `examples.gpr` builds without it
  too.

Warnings that are expected and not worth chasing:

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
`examples/css`, and the Regular, Bold, Italic and BoldItalic fonts under
`vendor/open-sans/static/`. `adi_env.js` pins Regular as the fallback face
so text metrics do not depend on the build machine's installed fonts.

## Documentation

- `FINDINGS.md` — reference notes on the GNAT-LLVM/AdaWebPack/Emscripten
  stack, independent of Adi2: what the WASM RTS provides, the SDL3
  browser app pattern, link flags, and the compiler-side fixes this
  port depends on.
