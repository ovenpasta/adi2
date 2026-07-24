# WebAssembly + Emscripten + SDL3 for Ada (GNAT-LLVM / AdaWebPack)

Reference notes for porting Ada GUI code to the browser. Everything here is
distilled from `/src/gnat-llvm` (compiler + runtime) and
`/src/gnat-llvm/llvm-interface/adawebpack_src` (WASM RTS overrides + SDL3
example suite).

> **2026-07 update**: native WebAssembly exception handling landed
> (gnat-llvm `8b432571`, adawebpack `0067d6a`). Real Ada raise/catch across
> frames — with finalization during unwind and
> `Exception_Name`/`Message`/`Identity`/`Exception_Occurrence` — works on the
> new `-eh` runtimes. The RTS also gained file-based `Ada.Text_IO`,
> `Ada.Directories`, `Ada.Streams.Stream_IO`, `Ada.Environment_Variables`,
> and `Ada.Numerics.Float_Random`. HAC (an Ada compiler in Ada) runs
> **unmodified** in the browser on this stack
> (`adawebpack_src/examples/hac_web/`). Sections below updated accordingly;
> superseded statements are corrected in place.

## 1. Toolchain Overview

Three cooperating pieces:

| Layer       | Source                                    | Role                                           |
|-------------|-------------------------------------------|------------------------------------------------|
| Compiler    | `gnat-llvm` (+ GCC 16 frontend)           | Ada -> LLVM IR -> `wasm32` object files        |
| Ada RTS     | `adawebpack_src/source/rtl` (+ RTS core)  | Runtime libs (`libgnat.a`) compiled for WASM   |
| Link / load | `emcc` + JS glue                          | Link `.o` / `.a` into `.wasm` + `.js` shell    |

Pinned versions actually verified:

- LLVM 21.1.x (other versions fail). Arch: `/usr/lib/llvm21/bin`.
- GCC 16 sources (for the Ada frontend consumed by GNAT-LLVM).
- Emscripten (`/usr/lib/emscripten/emcc`).
- AdaWebPack branch `gcc-16-wasm-rts`.

Required PATH additions when building:

```bash
export PATH=/usr/lib/llvm21/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib/llvm21/lib
```

## 2. Six WASM Runtimes (allocator × exception model)

GNAT-LLVM now ships six runtimes under `lib/gnat-llvm/wasm32/`, the cross
product of allocator and exception model:

| Directory                | Allocator          | Exceptions                          | Use when                                  |
|--------------------------|--------------------|-------------------------------------|-------------------------------------------|
| `rts-wasm`               | TLSF (in RTS)      | `No_Exception_Propagation` (local only) | Standalone, no emcc, no EH needed     |
| `rts-wasm-eh`            | TLSF (in RTS)      | Native wasm EH (legacy `try`/`catch`) | Standalone with full exceptions         |
| `rts-wasm-eh-exnref`     | TLSF (in RTS)      | Native wasm EH (`exnref` encoding)  | Standalone, standardized EH encoding      |
| `rts-wasm-emcc`          | Emscripten dlmalloc| `No_Exception_Propagation` (local only) | Browser app that never propagates     |
| `rts-wasm-emcc-eh`       | Emscripten dlmalloc| Native wasm EH (legacy `try`/`catch`) | **Browser app — default choice**        |
| `rts-wasm-emcc-eh-exnref`| Emscripten dlmalloc| Native wasm EH (`exnref` encoding)  | Browser app, standardized EH encoding     |

For an SDL3 browser app, use **`rts-wasm-emcc-eh`**. It provides
`Ada.Calendar`, full exception propagation, and the largest set of standard
libraries. (Correction to earlier revisions of this file: `Ada.Real_Time`
is NOT provided by any WASM runtime — only `Ada.Calendar`. See Section 3.)

The `-eh` runtimes are back-end-ZCX builds: the compiler emits LLVM funclet
EH (catchswitch/catchpad, `__gxx_wasm_personality_v0`) lowered to wasm
`try`/`catch`/`throw`. The legacy encoding is the default; setting
`GNAT_WASM_EH=exnref` at RTS *and* app build time selects the standardized
`try_table`/`throw_ref` encoding and appends `-exnref` to the RTS directory
name so the two encodings can never be mixed in one link. An unrecognized
value is rejected outright.

### Build the runtimes

```bash
cd /src/gnat-llvm/llvm-interface
make build LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
# Switch to the AdaWebPack Makefile.target
mv Makefile.target Makefile.target.orig
ln -s adawebpack_src/source/rtl/Makefile.target Makefile.target
make wasm-emcc    LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
make wasm-emcc-eh LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
# optionally: make wasm-eh, and GNAT_WASM_EH=exnref variants of both
```

Output: `lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/{adainclude,adalib,target.atp,...}`

The GCC tree must carry the two EH patches (in addition to the Repinfo one):
`gcc-16-allow-reraise-no-propagation.patch` and
`gcc-16-wasm-eh-raise-gcc.patch` (see `adawebpack_src/README.md`).

## 3. What the WASM RTS Does / Does NOT Provide

Inventory from
`/src/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/adainclude/`
(445 files; `rts-wasm-emcc` has the same list minus the ~29 exception-
machinery units: `a-exexpr`, `s-excmac`, `s-traceb`, `raise-gcc.c`, ...).

### Present

- `Ada.Calendar` (+ `Formatting`, `Time_Zones`; UTC-only tz stub)
- `Ada.Strings.Fixed`, `.Bounded`, `.Unbounded`, `.Maps`, `.Search`,
  `.Superbounded`, `.Hash`
- `Ada.Strings.UTF_Encoding` (+ `.Strings`, `.Wide_Strings`,
  `.Wide_Wide_Strings`)
- `Ada.Characters.Handling`, `Ada.Numerics.*_Elementary_Functions`
- `Ada.Streams` (base type)
- `Ada.Finalization`, `Ada.Tags`
- `Ada.Exceptions` -- **full semantics on the `-eh` runtimes**: raise /
  propagate across frames, `Exception_Occurrence`, `Exception_Name` /
  `Message` / `Identity`, reraise, finalization during unwind
  (adawebpack `0067d6a`). On the non-eh runtimes still minimal
  (local handlers + last-chance only).
- `Ada.Text_IO` -- **full file-based variant** on both emcc runtimes:
  `File_Type`, `Open`, `Create`, `Close`, `Put_Line (File, ...)`,
  `Get_Line (File, ...)`, `End_Of_File` over Emscripten's
  MEMFS / NODEFS / IDBFS (adawebpack `45f5388`). The standalone
  `rts-wasm*` runtimes keep the stripped console-only variant.
- `Ada.Integer_Text_IO`, `Ada.Float_Text_IO` -- generics + predefined
  instantiations.
- `Ada.Directories` -- on the emcc runtimes, backed by upstream
  `adaint.c` over Emscripten libc (adawebpack `b148b37`): `Exists`,
  `Create_Directory`, directory iteration, `Modification_Time`, etc.
- `Ada.Streams.Stream_IO` -- on the emcc runtimes, with 64-bit
  positioning shims (`__gnat_ftell64` / `__gnat_fseek64`).
- `Ada.Environment_Variables` -- read path (`Value`, `Exists`) via
  `__gnat_getenv` (adawebpack `980a730`, `b148b37`).
- `Ada.Command_Line` -- argv + exit status supported under emcc
  (adawebpack `8eca1bf`); with `-sNODERAWFS=1` a wasm CLI is a drop-in
  for a native binary (see the `hac_cli` example).
- `Ada.Numerics.Float_Random` + `System.Random_Numbers` (wasm fork,
  adawebpack `7f2a2b6`).
- `Ada.Containers.Vectors`, `Doubly_Linked_Lists`, `Hashed_Maps`,
  `Hashed_Sets`, `Ordered_Maps`, `Ordered_Sets`, `Multiway_Trees` +
  all seven `Indefinite_*` variants + `Indefinite_Holders`.
- `System.OS_Lib` (`Rename_File`, `Errno`, ...) and, since adawebpack
  `fae4f04` (2026-07-19), the `GNAT.OS_Lib` rename spec on the emcc
  runtimes.
- `GNAT.IO`, `GNAT.Regpat`, `GNAT.String_Split`, `GNAT.Array_Split`,
  `GNAT.Compiler_Version`

### Absent (callers must provide a stub or refactor)

- `Ada.Real_Time` (use `Ada.Calendar` or SDL ticks; frame pacing on the
  web is driven by the browser anyway). NOTE: earlier revisions of this
  file wrongly listed it as present. adi2 no longer references it — the
  `Adi.Clock` seam wraps it natively (`PORT_REPORT.md` Section 14).
- `Ada.Wide_*_IO`
- `Ada.Numerics.Discrete_Random` (`Float_Random` is in; the generic
  discrete instantiation is not shipped)
- `Ada.Task_Identification` and all tasking units (tasks unsupported)

### Unsupported language features

Current status (the "Unsupported features" list in
`adawebpack_src/README.md` predates the EH runtimes for items 1-2):

1. ~~Nested subprograms~~ -- **supported** on `wasm32`. Every subprogram
   carries an explicit activation-record parameter
   (`Uses_Explicit_Activation_Record_Parameter`), and taking
   `'Access`/`'Address` of a nested subprogram no longer emits a
   trampoline (gnat-llvm `7ca44392`). HAC compiles unmodified; adi2's
   nested subprograms compile as-is (verified 2026-07-19).
2. ~~Exception propagation across frames~~ -- **supported** on the `-eh`
   runtimes (link with `emcc -fwasm-exceptions`). Still unsupported on
   `rts-wasm` / `rts-wasm-emcc`.
3. Tasks and protected objects -- still unsupported
   (`construct not allowed in configurable run-time mode`).
4. `'Address` clauses that alias between objects -- still unsupported.
5. Frontend quirk: GCC 16.1's GNAT rejects `'Reduce` over an
   enum-indexed iterated aggregate (`[for S in Some_Enum => ...]'Reduce`)
   with a bogus `expected type "Standard.Integer"` error, and other
   `'Reduce` phrasings misbehave too (bogus `Constraint_Error` warning
   on an Integer-range variant). Workaround: rewrite as a plain loop in
   a body — verified clean. See `PORT_REPORT.md` Section 16.

## 4. SDL3 Browser App Pattern

Emscripten cannot block the main JS thread, so a classic
`while not Quit loop ... end loop` does not work. Use SDL3's main-callback
API:

```ada
with Interfaces.C; use Interfaces.C;

package body My_App is
   Window   : access SDL_Window;
   Renderer : access SDL_Renderer;

   function SDL_AppInit (AppState : System.Address;
                         Argc     : int;
                         Argv     : System.Address) return SDL_App_Result
   with Export => True, Convention => C, External_Name => "SDL_AppInit";

   function SDL_AppIterate (AppState : System.Address) return SDL_App_Result
   with Export => True, Convention => C, External_Name => "SDL_AppIterate";

   function SDL_AppEvent (AppState : System.Address;
                          Event    : access SDL_Event) return SDL_App_Result
   with Export => True, Convention => C, External_Name => "SDL_AppEvent";

   procedure SDL_AppQuit (AppState : System.Address; Result : SDL_App_Result)
   with Export => True, Convention => C, External_Name => "SDL_AppQuit";

   procedure Run is
      Status : constant int :=
         SDL_EnterAppMainCallbacks (Argc => 0, Argv => System.Null_Address,
                                    AppInit => ..., AppIterate => ...,
                                    AppEvent => ..., AppQuit => ...);
   begin
      if Status = 0 then
         Emscripten_Exit_With_Live_Runtime;  -- keeps WASM alive
      end if;
   end Run;
end My_App;
```

Full working source in
`/src/gnat-llvm/llvm-interface/adawebpack_src/examples/sdl3/basic/basic_app.adb`.

Key points from the basic example:

- Window, renderer, counters all live at package body level (module state).
- Bindings use `Convention => C, Import => True, External_Name => "SDL_..."`.
- SDL opaque structs are bound as `type SDL_Window is null record;` with
  `access SDL_Window` used for handles.
- Text is passed via `Interfaces.C.Strings.New_String` / `Free`.
- The basic example predates the EH runtimes and returns all errors via
  the callbacks (`Continue` / `Success` / `Failure`); on
  `rts-wasm-emcc-eh` ordinary Ada exception handlers work too.

## 5. Building SDL3 Itself

From `adawebpack_src/examples/sdl3/README.md`:

All three are built with `-fwasm-exceptions`: the EH runtime links with
that flag, and every static library in the link must carry it too
(SDL3_ttf's vendored freetype uses setjmp/longjmp, and JS-based and
wasm-based longjmp encodings cannot mix in one link). The adawebpack
sdl3 examples README has the full pinned-version recipe; the shape is:

```bash
# SDL3
git clone --depth=1 https://github.com/libsdl-org/SDL.git sdl3-src
cd sdl3-src
emcmake cmake -B build-wasm \
   -DCMAKE_C_FLAGS="-fwasm-exceptions" \
   -DCMAKE_CXX_FLAGS="-fwasm-exceptions" \
   -DSDL_STATIC=ON -DSDL_SHARED=OFF \
   -DCMAKE_INSTALL_PREFIX=$PWD/../sdl3-prefix
cmake --build build-wasm --target install -- -j$(nproc)

# SDL3_ttf (needs vendored freetype/harfbuzz)
git clone --depth=1 https://github.com/libsdl-org/SDL_ttf.git sdl3-ttf-src
cd sdl3-ttf-src
./external/download.sh
emcmake cmake -B build-wasm \
   -DCMAKE_C_FLAGS="-fwasm-exceptions" \
   -DCMAKE_CXX_FLAGS="-fwasm-exceptions" \
   -DSDL3_DIR=$PWD/../sdl3-prefix/lib/cmake/SDL3 \
   -DCMAKE_INSTALL_PREFIX=$PWD/../sdl3-ttf-prefix
cmake --build build-wasm --target install -- -j$(nproc)

# SDL3_image (same recipe)
```

The result is a collection of static archives under `sdl3-prefix/lib/` used
at link time by `emcc`.

## 6. Linking / JS Shell

The SDL3 example `common.mk` shows the link step:

```
EMCC_COMMON_FLAGS = -O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1
ADA_EMCC_FLAGS    = -sSTACK_SIZE=8388608 -sINVOKE_RUN=0

emcc $(EMCC_COMMON_FLAGS) $(ADA_EMCC_FLAGS) \
   $(OBJS) \
   $(ADA_RTS)/adalib/libgnat.a \
   $(SDL3_PREFIX)/lib/libSDL3.a \
   $(SDL3_TTF_PREFIX)/lib/libSDL3_ttf.a \
   $(SDL3_IMAGE_PREFIX)/lib/libSDL3_image.a \
   --pre-js ada_runtime_support.js \
   --pre-js sdl3_ada_pre.js \
   --embed-file assets@/assets \
   -o out/index.html
```

JS glue (under `adawebpack_src/examples/sdl3/`):

- `ada_runtime_support.js` defines `__gnat_grow` and `__gnat_put_exception`
  (needed by the RTS).
- `sdl3_ada_pre.js` defers invoking the Ada entry point until Emscripten
  has initialized.

Important flags:

- `-fwasm-exceptions` -- **required when linking against an `-eh`
  runtime**; keeps the wasm EH personality / unwind tables. (See
  `examples/hac_web/Makefile`.) Add `-sWASM_LEGACY_EXCEPTIONS=0` when
  using the `-exnref` encoding.
- `-sALLOW_MEMORY_GROWTH=1` -- Ada programs allocate a lot; fixed memory
  runs out quickly.
- `-sSTACK_SIZE=8388608` -- 8 MB stack avoids overflow in deeply nested
  frames.
- `-sINVOKE_RUN=0` -- suppress auto-invoking C `main`; app calls
  `SDL_EnterAppMainCallbacks` manually.
- `-sASYNCIFY` -- legacy; adds ~50% runtime overhead and does NOT
  compose with `-fwasm-exceptions`. For blocking loops use
  `-sJSPI -sJSPI_EXPORTS=main` instead (VM-level stack switching,
  composes with wasm EH; Phase 4 standard, shipped in Chromium,
  flagged in Firefox, Safari pending — see `PORT_REPORT.md`, "What
  JSPI is"). With SDL main callbacks you need neither.
- `-sNODERAWFS=1` -- CLI builds under Node get transparent access to the
  real filesystem (`hac_cli` uses this).

## 7. Consumer Project (`.gpr`)

From the basic example:

```gpr
project Basic is
   for Target use "llvm";
   for Object_Dir use ".objs";
   for Source_Dirs use (".", "../bindings");
   for Main use ("basic_main.adb");

   package Compiler is
      for Switches ("Ada") use
         ("--target=wasm32", "-O1", "-gnatp");
   end Compiler;
end Basic;
```

Build command:

```bash
PATH=$GNAT_LLVM/bin:$PATH \
  gprbuild -c -b --target=llvm \
    --RTS=$GNAT_LLVM/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh \
    -P basic.gpr
```

(`rts-wasm-emcc-eh` shown; use plain `rts-wasm-emcc` only for code that
never propagates exceptions. The RTS choice must match the emcc link
flags — `-fwasm-exceptions` goes with the `-eh` trees.)

The binder produces `b__basic_main.o`; the `emcc` link step above pulls
it plus every `.o` into the final `.wasm`.

Notes:

- `--target=llvm` tells gprbuild which compiler driver (`llvm-gcc`) to
  pick up from `PATH`.
- `--RTS=<dir>` is required for non-host targets; gprbuild does not yet
  auto-select based on triple.
- `-gnatp` disables runtime checks; useful for smaller WASM output but
  can be dropped during development.

## 8. Assets

`--embed-file DIR@/MOUNT` packs `DIR` into the WASM binary, visible at
`/MOUNT` via MEMFS. SDL3_image / SDL3_ttf / SDL_LoadFile all accept
those paths normally.

For GNAT-LLVM WASM programs that need font / image bytes at startup, the
existing adi2 "bundle mode" (`Adi.Assets.Bundle_Mode`) with
`binary_to_ada.py` is an alternative: the bytes live in `.rodata` inside
the WASM and no MEMFS lookup is needed. That is preferable on the web.

## 9. Running the Result

After linking you get three files: `app.html`, `app.js`, `app.wasm`.
Emscripten's shell is fine for testing. Serve them over HTTP (modern
browsers refuse `file://` WASM):

```bash
cd out
python3 -m http.server 8000
# then open http://localhost:8000/app.html
```

## 10. Known Compiler-Side Fixes

These are already applied upstream in the gnat-llvm main line, but worth
knowing:

- Native wasm exception handling (`8b432571`): funclet EH
  (catchswitch / catchpad / cleanuppad with `funclet` operand bundles)
  lowered to wasm try/catch/throw; `__gxx_wasm_personality_v0`
  personality; target machine rebuilt with the wasm exception model.
  Enabled when compiling against an `-eh` runtime; the
  `No_Exception_Propagation` landingpad path is byte-unchanged.
- EH encoding selection (`94741108`): `GNAT_WASM_EH=exnref` switches the
  backend to `try_table`/`throw_ref`; default is legacy `try`/`catch`.
- Trampoline skip (`7ca44392`): `'Access`/`'Address` of nested
  subprograms uses the explicit activation-record parameter instead of
  `llvm.init.trampoline` (which crashed on wasm32). This is what makes
  nested subprograms and in-procedure generic container instantiations
  work.
- `gnatllvm-blocks.adb` -- `Push_Block` passes an activation-record arg
  to `__finalizer` procedures even when no uplevel references exist,
  keeping the calling convention consistent on WASM.
- GCC patches to apply before building the compiler:
  `patches/gcc-16-repinfo-accessors.patch` (always),
  `patches/gcc-16-allow-reraise-no-propagation.patch` and
  `patches/gcc-16-wasm-eh-raise-gcc.patch` (for the EH runtimes).

## 11. References in the Tree

- `/src/gnat-llvm/README.md`                              -- top-level build
- `/src/gnat-llvm/llvm-interface/BUILD-WASM.md`           -- full WASM flow
- `/src/gnat-llvm/llvm-interface/adawebpack_src/README.md` -- RTS overrides
- `/src/gnat-llvm/llvm-interface/adawebpack_src/examples/sdl3/README.md`
- `.../adawebpack_src/examples/sdl3/basic/`               -- minimal SDL3 app
- `.../adawebpack_src/examples/sdl3/common.mk`            -- emcc link rules
- `.../adawebpack_src/examples/sdl3/bindings/`            -- SDL3/SDL3_ttf/
  Emscripten Ada bindings
- `.../adawebpack_src/examples/hac_web/`                  -- HAC compiler in
  the browser, unmodified, on `rts-wasm-emcc-eh`; its Makefile is the
  reference for EH link flags and for a Node CLI build (`-sNODERAWFS=1`)
