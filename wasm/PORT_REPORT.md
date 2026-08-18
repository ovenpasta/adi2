# Porting adi2 to WebAssembly

Concrete plan to build adi2 with GNAT-LLVM + AdaWebPack + Emscripten + SDL3.
Companion to `FINDINGS.md`. File paths are under `/src/ada/adi2/`.

> **2026-07-19 status**: re-verified against the EH-enabled toolchain
> (`rts-wasm-emcc-eh`, native wasm exception handling). Every library body
> in `src/` was trial-compiled with
> `llvm-gcc -c --target=wasm32 --RTS=rts-wasm-emcc-eh -gnat2022 -gnatX0 -O1`.
> Result: the exception, nested-subprogram, Text_IO, Directories,
> Stream_IO, and Environment_Variables blockers are **gone** — no source
> changes needed for any of them. The `Ada.Real_Time` gap is fixed
> in-source (`Adi.Clock` seam), the `GNAT.OS_Lib` gap upstream (the RTS
> ships `g-os_lib.ads` as of adawebpack `fae4f04`), and the `'Reduce`
> frontend quirk too (`Specificity` moved to the body as a loop). What
> remains is the SDL main-callback refactor, the `Adi.Dispatch`
> protected object, the tiny `adi-clock__wasm.adb` body, and the build
> plumbing.

## Summary of Blockers

Sorted roughly by disruption:

| # | Area                         | Severity   | Where                                                      |
|---|------------------------------|------------|------------------------------------------------------------|
| 1 | Protected objects            | Resolved   | `src/adi-dispatch.adb` has a wasm body; rlottie has none   |
| 2 | Tasks                        | Resolved   | rlottie rasterises lazily on the calling thread            |
| 3 | Blocking frame loop          | Hard block | `src/adi-app.adb` (`Run`)                                  |
| 4 | Exception handlers           | Resolved   | native wasm EH (`rts-wasm-emcc-eh` + `-fwasm-exceptions`)  |
| 5 | Nested subprograms           | Resolved   | explicit AREC param, no trampolines (gnat-llvm `7ca44392`) |
| 6 | Indefinite containers        | Resolved   | shipped in rts-wasm-emcc as of adawebpack e46767f          |
| 7 | `Ada.Text_IO` (console)      | Resolved   | stripped Text_IO + Integer/Float_Text_IO shipped e46767f   |
| 7b| `Ada.Text_IO` (file I/O)     | Resolved   | full file-based Text_IO over MEMFS/NODEFS/IDBFS (`45f5388`)|
| 8 | `Ada.Directories`            | Resolved   | shipped in emcc runtimes (`b148b37`); live-reload still off|
| 9 | `Ada.Streams.Stream_IO`      | Resolved   | shipped in emcc runtimes (`b148b37`)                       |
|10 | `Ada.Environment_Variables`  | Resolved   | read path shipped (`980a730`)                              |
|11 | rlottie C++ vendor lib       | Resolved   | built by `em++`, threads off via `LOTTIE_NO_THREADS`       |
|12 | plutosvg C vendor lib        | Small      | `vendor/plutosvg/` (plain C, `emcmake` build)              |
|13 | Build system                 | Small      | new `wasm/adi.gpr`, Makefile, asset pipeline               |
|14 | `Ada.Real_Time` missing      | Fixed      | `Adi.Clock` seam landed; wasm body (`adi-clock__wasm.adb`) pending |
|15 | `GNAT.OS_Lib` spec missing   | Fixed      | RTS ships `g-os_lib.ads` (adawebpack `fae4f04`); no adi2 change |
|16 | `'Reduce` frontend quirk     | Fixed      | `Specificity` moved to `adi-widget_styles.adb` as a loop   |

## 1. Dispatch (protected object -> plain vector)

`src/adi-dispatch.adb` uses a `protected Queue` for the deferred-callback
queue. Single-threaded WASM does not need synchronization.

Plan:

- Replace the protected type with a package-body `Vectors` instance of
  `Dispatch_Callback_Access`.
- `Enqueue` / `Drain` / `Pending_Count` become plain subprograms.
- `Adi.App.Run` already calls `Pending_Count` + `Drain` on the main
  thread; no call-site change needed.

Risk: any current off-thread caller breaks. Grep confirms
`Adi.Dispatch.Enqueue` is called from callbacks that run on the main
thread (CSS live-reload, widget store pumping). No background tasks post
to it in the portable code.

## 2. RLottie

The Ada side is no longer a blocker. `Adi.RLottie` declares no task and
no protected type: a frame is rasterised on the thread that asks for it,
the first time playback reaches it, and kept afterwards. Both the spec
and the body compile under `pragma Restrictions (No_Tasking)`, and no
wasm-specific body is needed or wanted.

The C++ vendor library builds too:

- `wasm/Makefile` compiles `vendor/rlottie` with `em++` into
  `obj/rlottie/`, alongside the plutosvg rule. `-DLOTTIE_NO_THREADS`
  keeps `src/config.h` from defining `LOTTIE_THREAD_SUPPORT`, and
  `LOTTIE_LOGGING_SUPPORT` is never defined; those two guard every
  `std::thread` use. `-U` cannot serve, the header defining the macro
  during inclusion.
- `Common_Excluded` in `wasm/adi_wasm.gpr` is down to `adi-clock.adb`
  and `adi-dispatch.adb`.
- `rlottie_example` is in the showcase and the navigator.

The resulting wasm imports nothing thread-related: the 18 imports whose
names contain "thread" are SDL3's `emscripten_set_*_callback_on_thread`
HTML5 event API, and the set is identical to `label_example`'s.

Measured on the eight-emoji example: rasterising one frame for each of
eight animations costs 1.2 ms at 72 px and 2.3 ms at 128 px on the
Chromium main thread, against a 16.7 ms budget.

## 3. Main loop (delay until -> SDL main callbacks)

`src/adi-app.adb:100-307` runs a classic `while not Should_Quit loop ...
delay until Next_Frame end loop`. Emscripten cannot support that without
Asyncify, and even then it is expensive.

Plan:

- Split `Run` into four exported procedures modeled on
  `adawebpack_src/examples/sdl3/basic/basic_app.adb`:
  - `SDL_AppInit` -- does what `Init` + pre-loop setup does today (SDL
    init, create window, etc.). Stores `App` state at package-body level.
  - `SDL_AppIterate` -- one frame: drain dispatch, pump stores, `Tick`,
    `Render`. No `delay`.
  - `SDL_AppEvent` -- one event: the existing `case Event.Event_Type`
    dispatch.
  - `SDL_AppQuit` -- `Adi.Window.Destroy (A.Main_Window)` and SDL quit.
- Remove the manual frame-rate limiter; the browser drives cadence via
  `requestAnimationFrame` (SDL_AppIterate is called per vsync by default
  in the SDL3 Emscripten backend).
- Expose a wrapper `Adi.App.Run` that on native still runs the blocking
  loop, but on WASM calls `SDL_EnterAppMainCallbacks` +
  `Emscripten_Exit_With_Live_Runtime`.

Implementation shape:

```
src/adi-app.adb             -- native body, keeps current loop
src/adi-app__wasm.adb       -- WASM body, exports SDL_App* + Run uses main-callbacks
```

Both share a thin `Adi.App.Impl` helper package holding the per-frame
steps so the two bodies stay in sync.

### Nested subprograms inside `Run`

`Main`, `Convert_Event_To_Render_Coordinates`, and the
`Ada.Unchecked_Conversion` instantiations are nested in `Run`. When `Run`
is decomposed into package-level callbacks they become either:

- package-body helpers (move them out), or
- naturally-top-level generic instantiations.

This falls out of the callback refactor; no extra work.

## 4. Exception handlers -- RESOLVED

Native WebAssembly exception handling (gnat-llvm `8b432571`, adawebpack
`0067d6a`) gives real raise/catch across frames with finalization and
`Exception_Occurrence` semantics. Requirements:

- compile against `rts-wasm-emcc-eh` (built with `make wasm-emcc-eh`);
- link with `emcc -fwasm-exceptions`.

All ~14 handler files (`adi-css_parser`, `adi-css_source`, `adi-log`,
`adi-settings-json_backend`, `adi-widget*`, `adi-svg*`) compile and keep
their handlers **unchanged** — verified by trial compile 2026-07-19.
HAC, whose control flow is exception-based end to end, runs unmodified
on this stack (`adawebpack_src/examples/hac_web/`), so "log and
continue" recovery in adi2 needs no result-code rewrite.

MCP files (`src/mcp/`) ship a stub variant (`src/mcp_stub/`). For WASM
still select the stub -- the MCP server uses filesystem IPC to talk to
an external process, which does not exist in the browser.

## 5. Nested subprograms -- RESOLVED

No hoisting needed. On wasm32 every subprogram carries an explicit
activation-record parameter, and gnat-llvm `7ca44392` stopped emitting
trampolines for `'Access`/`'Address` of nested subprograms. The whole
`src/` tree (including the widget stack with its nested helpers and
in-procedure generic instantiations) compiles as-is for wasm32.

## 6. Indefinite containers -- RESOLVED

As of adawebpack commit `e46767f` (2026-04-20) all seven indefinite
containers ship in `rts-wasm-emcc`:

- `a-coinve__wasm.adb` -- `Indefinite_Vectors`
- `a-cidlli__wasm.adb` -- `Indefinite_Doubly_Linked_Lists`
- `a-cihama__wasm.adb` -- `Indefinite_Hashed_Maps`
- `a-cihase__wasm.adb` -- `Indefinite_Hashed_Sets`
- `a-ciorma__wasm.adb` -- `Indefinite_Ordered_Maps`
- `a-ciorse__wasm.adb` -- `Indefinite_Ordered_Sets`
- `a-coinho__wasm.adb` -- `Indefinite_Holders`

All use the same `raise -> Abort_Program` transform already applied to
the definite variants. No adi2 source changes needed for any of the
following users: `adi-settings`, `adi-css_source`, `adi-css_parser`,
`adi-i18n-catalog`, `adi-assets`, `adi-assets-bundle`, `adi-font`,
`adi-widget-combo_box`, `adi-widget-context_menu`, `adi-widget-dialog`,
`adi-widget-html_view`.

## 7. `Ada.Text_IO` -- RESOLVED

adawebpack `45f5388` ships **full file-based `Ada.Text_IO`** in the emcc
runtimes (upstream `System.File_IO` + `Interfaces.C_Streams` over
Emscripten's libc): `File_Type`, `Open`, `Create`, `Close`,
`Put_Line (File, ...)`, `Get_Line (File, ...)`, `End_Of_File` all work
over MEMFS / NODEFS / IDBFS. The earlier stripped console-only variant
remains only in the standalone `rts-wasm*` runtimes.

Consequences for adi2 (all verified by trial compile):

- `src/adi-log.adb` compiles unchanged, including `Write_To_File`. Log
  files land in MEMFS (per-session, in-memory) — harmless. Optionally
  mount IDBFS for persistence; not required.
- `src/adi-widget-value_input.adb` (`Float_IO` string forms) unchanged.
- `src/adi-css_parser.adb`, `src/adi-settings-json_backend.adb`
  file-handle I/O compiles unchanged.

## 8. `Ada.Directories` -- RESOLVED (RTS); live-reload stays off

adawebpack `b148b37` ships `Ada.Directories` in the emcc runtimes,
backed by upstream `adaint.c` over Emscripten libc. All ~8 adi2 call
sites compile unchanged.

Semantics note: the browser filesystem is MEMFS — files exist only if
`--embed-file`d or created at runtime. So:

- Asset discovery works against embedded files, but **bundle mode**
  (`Adi.Assets.Bundle_Mode` + `tools/binary_to_ada.py`) is still the
  preferred default — no MEMFS packing step, assets live in `.rodata`.
- CSS live-reload stays disabled on WASM — nothing edits MEMFS from
  outside. Use Static_Mode CSS (`tools/css_to_ada.py`). This is a
  configuration choice now, not a porting task.

## 9. `Ada.Streams.Stream_IO` -- RESOLVED

Shipped in the emcc runtimes with 64-bit positioning shims
(`__gnat_ftell64` / `__gnat_fseek64`). All six adi2 call sites
(`adi-css_source`, `adi-assets`, `adi-svg_sprites`,
`adi-settings-json_backend`, `adi-widget-html_view`, `src/svg/adi-svg`)
compile unchanged. The previously planned `Adi.IO.Read_File_Bytes`
abstraction is no longer required for the port.

Settings persistence: `adi-settings-json_backend` compiles, but writes
go to MEMFS and vanish on reload. Mounting IDBFS (plus a `syncfs` call
in JS glue) makes it genuinely persistent — small stretch goal, no Ada
changes. One real gap: it `with`s `GNAT.OS_Lib` for `Rename_File`, and
the RTS ships `System.OS_Lib` but not the `g-os_lib.ads` rename spec.
Fix either by adding the one-line spec to the RTS (preferred, upstream)
or by switching the `with` to `System.OS_Lib`.

## 10. `Ada.Environment_Variables` -- RESOLVED

Read path (`Value`, `Exists`) shipped via `__gnat_getenv`
(adawebpack `980a730`). Both call sites (`adi-window`, `adi-font`)
compile and behave sensibly (unset variables in the browser).

## 11. rlottie

`vendor/rlottie/rlottie.gpr` compiles C++14 with `-fno-exceptions
-fno-rtti`. Internally rlottie uses `std::thread` for frame decoding,
behind `LOTTIE_THREAD_SUPPORT`; `vdebug.cpp` uses threads behind
`LOTTIE_LOGGING_SUPPORT`.

The Ada side no longer needs anything from this (Section 2). What is
left is building the library:

- The vendored sources are compiled by `em++` with **both** macros
  absent. `-U` does not do it: `src/config.h` defines
  `LOTTIE_THREAD_SUPPORT` during inclusion, so that file now guards it
  with `#ifndef LOTTIE_NO_THREADS`, which the wasm build defines.
- Verified on this machine: with both absent the wasm has no thread or
  pthread imports, and the eight-emoji example costs 1.2 ms per tick at
  72 px on the Chromium main thread.
- `wasm/Makefile` builds it into `obj/rlottie/`, modelled on the
  plutosvg rule. Note `src/lottie/zip/zip.cpp` is a source too; missing
  it leaves undefined `zip_*` at link.

`wasm/adi_wasm.gpr` no longer excludes any rlottie file.

## 12. plutosvg

`vendor/plutosvg` is plain C. Build with `emcmake cmake` and link
statically. Should just work.

## 13. Build system

Create under `wasm/`:

- `wasm/adi.gpr` -- project file with `for Target use "llvm";` and
  `Switches ("Ada") use ("--target=wasm32", "-O1", "-gnatp");`
  Excludes the native `adi-clock.adb` and `adi-dispatch.adb` via
  `for Excluded_Source_Files`; selects `adi-app__wasm.adb` via the
  `Naming` package.
- `wasm/examples/<name>/<name>.gpr` per example.
- `wasm/Makefile` -- templated on `adawebpack_src/examples/sdl3/common.mk`:
  - `gprbuild --target=llvm --RTS=$(ADA_RTS) -c -b -P adi.gpr`
  - `emcc` link step with static SDL3 / SDL3_ttf / SDL3_image archives.
- `wasm/pre-js/` -- copy `ada_runtime_support.js` and
  `sdl3_ada_pre.js` from adawebpack.
- `wasm/shell.html` -- optional custom HTML shell.

Assets: prefer **bundle mode**. The existing
`tools/binary_to_ada.py` + `Adi.Assets.Bundle_Mode` already compiles
assets into `.rodata`. On WASM this is the right default because there
is no filesystem.

CSS: prefer **Static_Mode** with `tools/css_to_ada.py` generated
packages. No live-reload on the web.

The gprbuild step must use the EH runtime and the emcc link step must
carry `-fwasm-exceptions` (template: `examples/hac_web/Makefile` in
adawebpack, which also shows `-sMODULARIZE` / exported-function glue).

## 14. `Ada.Real_Time` -- FIXED IN SOURCE (`Adi.Clock` seam)

`Ada.Real_Time` is not in any WASM runtime (earlier revisions of
`FINDINGS.md` wrongly listed it as present), and shipping a partial
`a-reatim` in the RTS was rejected: `delay until` needs the tasking
runtime's `Timed_Delay`, which cannot be provided, and on the web the
browser owns the clock anyway (frame cadence = requestAnimationFrame;
`SDL_GetTicksNS` is the same timebase).

Landed 2026-07-19: `src/adi-clock.ads/adb` — a private `Time`/
`Time_Span` pair (Duration-based, monotonic since program start) with
`Now`, `"-"`/`"+"`, `Microseconds`, `To_Duration`, `Sleep_Until`. All
arithmetic lives in the spec's private part as expression functions;
the body only supplies `Now` and `Sleep_Until`. Native body wraps
`Ada.Real_Time`. `adi-app`, `adi-window`, `adi-widget` no longer
reference `Ada.Real_Time` and now compile for wasm32 (verified;
`adi-widget`'s `with` turned out to be dead and was simply removed,
which also unblocked `adi-widget-box`). Covered by
`tests/bin/clock_test`.

Still to do in the port: `adi-clock__wasm.adb` selected via the
`Naming` package in `wasm/adi.gpr` — `Now` over `SDL_GetTicksNS`
(binding may need adding to `Adi.SDL`), `Sleep_Until` a no-op since the
browser drives cadence.

## 15. `GNAT.OS_Lib` spec -- RESOLVED UPSTREAM (no adi2 change)

The emcc runtimes now ship the `g-os_lib.ads` rename spec (adawebpack
`fae4f04`, 2026-07-19). adi2 keeps its original `with GNAT.OS_Lib`
call sites (`adi-settings-json_backend.adb`, `src/mcp/adi-mcp.adb`) —
an interim switch to `System.OS_Lib` was reverted once the RTS spec
landed. Verified: native build + `settings_test` 86/86 + `mcp_test`
58/58, and the settings backend compiles warning-free for wasm32.

Do NOT "simplify" these call sites to `Ada.Directories.Rename`: GNAT's
implementation (native and wasm RTS alike, `a-direct.adb`) raises
`Use_Error` when the target exists, so it cannot atomically replace a
file — which is the entire point of `Atomic_Write` (write `.tmp`,
`rename()` over the live file).

## 16. `'Reduce` aggregate frontend quirk -- FIXED IN SOURCE

GCC 16.1's GNAT (used by GNAT-LLVM) rejects
`[for S in Widget_State => ...]'Reduce ("+", 0)` in `Specificity`
(`src/adi-widget_styles.ads`) with a bogus
`expected type "Standard.Integer"` error. Every `'Reduce` phrasing tried
either errors (qualified `State_Count_Array'[...]` fails resolving
`"+"`) or draws a `Constraint_Error will be raised at run time` warning
(Integer-range + `'Val` variant).

Landed 2026-07-19: `Specificity` is now a plain loop in
`adi-widget_styles.adb`. Verified: native build + styles/css_parser/
layout suites green, and `adi-widget_styles.adb` / `adi-css_parser.adb`
/ widget bodies compile warning-free for wasm32 straight from the tree.

Worth reporting upstream (GCC frontend), but this was the **only**
frontend incompatibility in the whole `src/` tree.

## Appendix: Trial-Compile Sweep (2026-07-19)

All 61 library bodies (`src/*.adb`, `src/svg/*.adb`,
`src/svg/plutosvg/adi-svg.adb`) compiled with
`llvm-gcc -c --target=wasm32 --RTS=rts-wasm-emcc-eh -gnat2022 -gnatX0
-O1` (Specificity fix from Section 16 applied). Result: **52 clean**
(2 of those with pre-existing warnings only), 9 failures from exactly
4 root causes, all already tracked above:

| Root cause                    | Files                                                                  | Tracked in |
|-------------------------------|------------------------------------------------------------------------|------------|
| `Ada.Real_Time` not in RTS    | `adi-app.adb`, `adi-window.adb`, `adi-widget.adb` (+ `adi-widget-box.adb` transitively, via inlining against `Adi.Widget`'s body) — **since fixed** via `Adi.Clock` | Section 14 |
| Protected object              | `adi-dispatch.adb`                                                     | Section 1  |
| Task + protected (rlottie)    | `adi-rlottie.adb`, `adi-widget-rlottie.adb`, `adi-widget-animated_widget-rlottie.adb` — **since fixed**: rlottie rasterises lazily, with no task or protected type | Section 2  |
| `g-os_lib.ads` not in RTS     | `adi-settings-json_backend.adb` — **since fixed** via `System.OS_Lib`  | Section 15 |

Everything else — the full CSS engine, all remaining widgets, HTML view,
i18n, settings core, fonts, assets, SVG (Ada side), signals, layout —
compiles for wasm32 without any source change.

After the 2026-07-19 fixes (re-verified): only `adi-dispatch.adb`, the
three rlottie bodies, and the native `adi-clock.adb` (replaced by the
port's `__wasm` body) failed to compile for wasm32. The rlottie bodies
have since been made taskless and compile; `adi-app.adb`,
`adi-window.adb`, `adi-widget.adb`, `adi-widget-box.adb`, and
`adi-settings-json_backend.adb` are clean.

## Suggested Order of Work (updated 2026-07-19)

Steps about containers, IO abstractions, exception audits, and nested
subprogram hoisting from earlier revisions are all obsolete — the
runtime/compiler resolved them. What is actually left:

1. ~~`Specificity` `'Reduce` rewrite~~ — done (Section 16).
2. **`Adi.Dispatch`**: replace the protected queue with a plain vector
   (Section 1). Smallest mechanical win; prerequisite for the callback
   refactor.
3. ~~Clock / `g-os_lib`~~ — done (Sections 14–15). Only the
   `adi-clock__wasm.adb` body remains, alongside step 4.
4. **`Adi.App` main-callback variant** (Section 3): `adi-app__wasm.adb`
   exporting `SDL_AppInit/Iterate/Event/Quit`. Same commit:
   `adi-clock__wasm.adb` (`Now` on
   `SDL_GetTicksNS`, `Sleep_Until` no-op). Note: the wasm32 compile of
   `adi-app.adb` warns about unchecked-conversion size mismatches on
   the SDL event casts (32-bit pointers) — review those conversions
   against the wasm32 SDL ABI during this step.
5. **Build plumbing** (Section 13): `wasm/adi.gpr` (Naming selects the
   WASM bodies, `src/mcp_stub` selected), `wasm/Makefile` with `--RTS=rts-wasm-emcc-eh` and
   `emcc -fwasm-exceptions`; `emcmake` builds of SDL3 / SDL3_ttf /
   SDL3_image / plutosvg.
6. **Assets + CSS end-to-end**: bundle mode + Static_Mode CSS wired for
   one example.
7. **Port a real example** (e.g. `examples/label_example.adb` or
   `examples/hello_example.adb`) as the first browser deliverable.
8. ~~rlottie~~ — done (Sections 2 and 11). **Later**: IDBFS-backed
   settings persistence, more examples.

## Build Strategy (decided 2026-07-19, implemented in this directory)

Everything lives under `wasm/`; the desktop tree (`../adi.gpr`, `alr
build`, `src/`) is not touched and never sees these files. Code
duplication with `src/adi-app.adb` is accepted deliberately — when
changing event handling, update BOTH bodies.

```
wasm/
  adi_wasm.gpr         separate project: Target "llvm", wasm32 switches,
                       Naming selects the __wasm bodies,
                       mcp_stub + config/posix + config/development
  src/adi-clock__wasm.adb     Now = SDL_GetTicksNS, Sleep_Until = no-op
  src/adi-dispatch__wasm.adb  plain vector queue (single-threaded)
  src/adi-app__wasm.adb       SDL main callbacks; duplicated event
                              dispatch; catch-all handlers log via
                              Adi.Log and return SDL_APP_FAILURE
  Makefile             gprbuild -c -b (EH runtime) + emcc -fwasm-exceptions
                       link; plutosvg/plutovg compiled with emcc;
                       NotoSans embedded at /usr/share/fonts for the
                       Adi.Font fallback scan (works over MEMFS)
  pre-js/              sdl3_ada_pre.js (deferred main), ada_runtime_support.js
  site/index.html      instant redirect to the default example
                       (material_demo) — no gallery page; the shell's
                       dropdown is the navigation
  site/shell.html      custom emscripten --shell-file for every example
                       page: blue navbar with example-switcher dropdown,
                       About modal (explanation + browser note +
                       credits), collapsible log, centered transparent
                       canvas (the canvas is letterboxed wider than the
                       app render — don't give it a visible
                       background/border), no emscripten branding. Keep
                       the dropdown list in sync with SHOWCASE_EXAMPLES.
                       Excluded: hello_raw, runtime_css,
                       text_editor (22 examples shown).
                       Browser caching:
                       python http.server + Chrome heuristics can serve
                       stale pages after a rebuild — hard-reload when
                       testing; use content-hashed deploys (hac_web
                       Makefile pattern) for production.
```

**Status (2026-07-19): `label_example` AND `button_example` RUN IN THE
BROWSER, fully interactive.** CSS styling, SDL3_ttf text via the
embedded NotoSans fallback, plutosvg icons, flex layout, clicks,
toggle-switch animation, radio-group state — all verified in Chrome
with zero console errors. Build and serve:

```sh
cd wasm && make EXAMPLE=button_example GPRBUILD="alr exec -- gprbuild" && make serve
# http://localhost:8000/button_example.html
```

Two main-loop modes exist (`LOOP=blocking|callbacks`, gpr scenario
`WASM_MAIN_LOOP`). **callbacks is the normal, portable mode** for
applications written for the browser; **blocking (JSPI) exists to run
the desktop examples verbatim** and is the showcase default for that
reason only, see below.

Emscripten lifecycle facts (learned the hard way — the first run died
with a bogus "stale handle" on frame 1):

- `SDL_EnterAppMainCallbacks` **returns immediately** on Emscripten
  (registers the RAF loop; SDL's "orderly return" comment refers to
  quit). Main's entire stack — the example's locals and its `App`
  variable — is torn down before the first frame. The wasm `Adi.App`
  body therefore copies the App record **by value** to package level;
  never keep pointers into Run's caller frames. Widgets/windows are
  safe: handles are plain IDs, the objects live in package-level
  stores (heap).
- `Run` then calls `emscripten_exit_with_live_runtime`, which throws
  the JS `'unwind'` exception; the pre-js catches it. Bonus: the throw
  bypasses the binder's sequential `adafinal`, so library-level
  finalization (stores, caches — all still needed by the live
  callbacks) correctly never runs.
- **Nested local callbacks — SOLVED by the JSPI mode**. In
  `callbacks` mode, examples that pass `'Unrestricted_Access` of
  procedures nested in their main and capture main's locals get dead
  activation records once main's stack is gone. The default
  **`blocking` mode removes the problem entirely**: the NATIVE
  `Adi.App.Run` loop (unmodified `../src/adi-app.adb` — it compiles
  for wasm thanks to the Adi.Clock seam) runs under `-sJSPI`
  (WebAssembly stack switching); `Adi.Clock.Sleep_Until`
  (`adi-clock__wasm_jspi.adb`) suspends via `emscripten_sleep`, so
  main's stack — every example local, generic instantiation, and
  nested callback frame — stays alive forever. Verified:
  `button_example`'s click callbacks, its locally-instantiated
  radio-group generic, and the switch animation all work unchanged.
  JSPI composes fine with `-fwasm-exceptions` (both are VM features).
  Requires a JSPI-capable browser (Chrome ships it; that's the
  `callbacks` fallback's reason to exist).
- **JSPI invocation rule**: main must be entered through Emscripten's
  own `run()`/`callMain` (the promising wrapper). Do NOT use
  `-sINVOKE_RUN=0` + pre-js calling the raw `_main` export — the first
  suspension never resumes (symptom: first frame renders, then the app
  freezes silently). `emscripten_exit_with_live_runtime` is not needed
  in this mode: main simply never returns.

### What JSPI is, and browser coverage (checked 2026-07-19)

JSPI (JavaScript Promise Integration) is the WebAssembly standard for
**stack switching**: when wasm calls a suspending import (our
`emscripten_sleep`), the VM parks the entire wasm call stack as a
first-class object and returns to the browser event loop; when the
promise resolves (frame timer), the stack resumes where it was. That
is why the native blocking `Run` works unchanged — main's stack, with
all example locals and nested callback frames, physically persists
between frames instead of being unwound. It is a VM feature (no
Asyncify-style code instrumentation), which is also why it composes
cleanly with `-fwasm-exceptions`. The proposal reached **Phase 4 in
2026** — standardized by the W3C Wasm CG.

| Engine                    | Status                                             |
|---------------------------|----------------------------------------------------|
| Chrome / Edge / Chromium  | Shipped by default since Chrome 137 (all desktop platforms, x64 + Arm) |
| Firefox                   | Implemented in Firefox 139, behind a flag (`javascript.options.wasm_js_promise_integration`); unflagging expected post-Phase-4 |
| Safari                    | Not yet; WebKit withdrew its objection late 2025, engineer assigned, implementation anticipated |
| Node.js                   | Available behind the V8 JSPI flag (relevant for a future CLI/test build) |

Implications for this port:

- `LOOP=callbacks` is the portable mode and the normal way to write a
  browser application: package-level state, runs in every browser.
- `LOOP=blocking` (JSPI) is the showcase default only because the
  examples are desktop code reused unchanged — their locals and nested
  callbacks need main's stack alive. Hoisting the examples' captured
  state to package level would let the showcase run under callbacks
  everywhere; deferred.
- For public deployment, a page-side feature detect
  (`"Suspending" in WebAssembly`) can choose between the two builds
  automatically.

Sources: developer.chrome.com/blog/webassembly-jspi-origin-trial,
v8.dev/blog/jspi, chromestatus.com/feature/5674874568704000,
caniuse.com/wf-wasm-jspi, platform.uno/blog/the-state-of-webassembly-2025-2026,
github.com/WebAssembly/js-promise-integration.
- **Synthetic event testing**: SDL3's Emscripten backend listens for
  **Pointer Events** (`pointerdown`/`pointermove`/...), not legacy
  mouse events — dispatch `PointerEvent`s when driving the canvas from
  scripts/tests.
- **Nested-callback AREC bug — FIXED UPSTREAM**: on wasm32, an indirect call
  through access-to-subprogram to a NESTED subprogram passed a garbage
  activation record — explicit parameters arrived, uplevel references
  read/wrote wild memory. One bug, many faces: stack tabs highlighted
  but pages didn't switch; dialogs never appeared (dialog_example,
  material_demo); `'Image` of a procedure-local enum printed empty
  (its literal table is AREC-reached too); callbacks without uplevel
  refs worked by luck. Fixed by adawebpack `08b2a3d`: the RTS flips
  `Always_Compatible_Rep` to False, activating GNAT's existing fat
  (code + AREC) access-to-subprogram representation for the
  trampoline-less target. **ABI change**: any object compiled against
  the old RTS is invalid — always `rm -rf obj out` and rebuild clean
  after updating the RTS (the Makefile does not track the RTS as a
  dependency). Repro verified fixed 2026-07-19: all four expected
  lines, including `image=GREEN`.

Hard-won link facts:

- **SJLJ vs wasm EH**: freetype (inside `libSDL3_ttf.a`) and
  `plutovg-ft-raster.c` use `setjmp`/`longjmp`. Objects compiled with
  Emscripten's default JS-SJLJ cannot link into a `-fwasm-exceptions`
  binary (`undefined symbol: emscripten_longjmp`). Anything using SJLJ
  must be compiled with `-fwasm-exceptions` too: plutovg gets it in
  `PLUTO_CFLAGS`, and the SDL3/SDL3_ttf/SDL3_image prefixes come from
  adawebpack, which now builds all three with `-fwasm-exceptions` (its
  sdl3 examples README; SDL3_ttf was originally rebuilt locally into
  `wasm/sdl3-ttf-prefix` until that landed upstream). `libSDL3.a` and
  `libSDL3_image.a` contain no SJLJ users anyway.
- **RTS wart (upstream)**: wasm-ld warns about signature mismatches for
  `__gnat_dup2` / `__gnat_lseek` / `strncpy` between `s-os_lib.o`
  (procedure imports) and `adaint.o`/libc (int-returning). Harmless
  unless those specific routines are called; worth fixing in adawebpack.
- **ABI audit**: wasm32 compile warns `cannot pass "FG"/"BG" by copy`
  on `Adi.SDL.TTF`'s LCD render bindings — moot, adi2 never calls the
  LCD functions (grep-verified). The SDL event unchecked-conversion
  size warnings (32-bit pointers shrink the sub-event records) remain
  an open item to validate at runtime: field offsets should match the
  wasm32 C ABI since the bindings use Interfaces.C types throughout,
  but event decoding must be exercised in the browser to confirm.

## Example Set (26 mains in `examples/`)

Once the library steps above land, the expected split is:

- **Buildable for the browser (23)** — everything except the three
  below. `html_view_example` and `material_demo` reference `Adi.MCP`,
  which resolves to the `src/mcp_stub` no-ops; `combo_box_example` and
  `label_example` use Settings, which work in-session (MEMFS) without
  changes. Each example needs its assets bundled
  (`tools/binary_to_ada.py`) or `--embed-file`d.
  With the default JSPI `blocking` mode there is no callback caveat —
  examples run unchanged, callbacks and all.

**Showcase status (2026-07-19, `make showcase` + `wasm/site/index.html`
→ `out/index.html`, Bulma light theme):**

- **All 22 examples build and run in `blocking` (JSPI) mode.** (Count
  as of 2026-07-19; the showcase has since gained `overflow_example`,
  `demo_flex` and `svg_example`.)
  Verified interactively after the AREC fix (adawebpack `08b2a3d`):
  stack switching, dialogs (modal alert over backdrop), material_demo
  tabs + forms page, button callbacks with correct enum `'Image`, and
  html_view rendering its full document.
- History note: `html_view_example` originally died under JSPI with an
  unhandled exception; it was attributed here to a JSPI stack limit
  (`Storage_Error` hypothesis) — **that was wrong**. It was the
  nested-callback AREC bug corrupting the HTML renderer's internals
  (even the callbacks-mode build had a blank content pane); with the
  fat-pointer fix it runs perfectly under JSPI, and the showcase no
  longer special-cases it. Remaining upstream QoL item: exceptions
  escaping main surface as a raw `WebAssembly.Exception` with no
  message (no last-chance handler on that path).
- `demo_flex` was excluded while it withed `GNAT.Traceback.Symbolic`,
  which the RTS has no `g-traceb`/`g-trasym` spec for. The example is
  now generated from XML and carries no GNAT dependency, so it is in the
  showcase.
- Build gotcha: do NOT compile with `-gnatW8` — native `examples.gpr`
  builds without it, and generated UI packages carry raw UTF-8 in
  String literals (byte semantics); W8 lexes them as wide characters
  and rejects them.
- Makefile structure: shared per-mode object dir (`obj/<loop>`), the
  library compiles once, each example adds its main; the link step
  excludes other mains/binders (wasm-ld gc's unused generated
  packages). Global embeds: `examples/assets` (also the `app://` root),
  `examples/css`, NotoSans, OpenSans-Regular. Sequential gprbuild only.
- **In — `rlottie_example`**: eight Animated Noto Emoji, rasterised on
  the calling thread.
- **Out — `runtime_css_example`**: its purpose is Dynamic_Mode
  live-reload, which has no browser equivalent.
- **Deferred — `text_editor_example`**: uses native open/save file
  dialogs (`Adi.OS_Integration`); browser file access needs separate JS
  glue.

## Out of Scope (for the first port)

- Any future async IO — tasks and protected objects remain unsupported
  on wasm32. Nothing in the library uses either today.
- File dialogs / native clipboard (browser permissions API is separate
  and requires JS glue; SDL3's Emscripten backend covers only parts).
- MCP runtime introspection (filesystem IPC with an external process —
  meaningless inside a browser sandbox; `src/mcp_stub` is selected).
- Settings persistence beyond the in-memory session (IDBFS mount +
  `syncfs` glue is a small stretch goal, no longer blocked on Ada).
- CSS live-reload (Dynamic_Mode) — nothing can touch MEMFS from
  outside; Static_Mode generated CSS is the browser configuration.

## Reference Files Inside This Repo

- `src/adi-app.adb`                       -- frame loop to restructure
- `src/adi-dispatch.ads/adb`              -- protected queue to replace
- `src/adi-rlottie.ads/adb`               -- taskless, lazy frames
- `src/adi-widget_styles.ads`             -- `Specificity` 'Reduce rewrite
- `src/adi-sdl*.ads`                      -- existing SDL3 Ada bindings; compare
                                             against adawebpack's and merge
- `CLAUDE.md`, `docs/architecture.md`     -- project overview
- `tools/binary_to_ada.py`                -- asset bundling, ready for WASM
- `tools/css_to_ada.py`                   -- CSS compile, ready for WASM
