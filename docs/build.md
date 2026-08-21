# Build System

## Quick Reference

### Alire
```bash
alr build          # the library only
alr test           # build and run every test (tools/run_tests.sh)
tools/build_examples.sh   # regenerate example sources, then build examples
```

Each command does one thing: `alr build` never builds tests or
examples, so a consumer pulling the crate pays only for the library.

### Direct gprbuild (configure once, build from generated projects)
```bash
# Prefer Alire environment wrapping for direct gprbuild invocations:
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=styles

tools/configure.sh --build-dir build-linux --target linux --build-profile development
build-linux/build_all.sh
```

Example sources are generated from their CSS/XML/asset/PO inputs.
`tools/build_examples.sh` runs the generators for you; when driving
gprbuild directly, run them first:
```bash
bash tools/generate_example_styles.sh
bash tools/generate_example_ui.sh
bash tools/generate_example_bundles.sh
bash tools/generate_example_translations.sh
```

### Cross-compile
```bash
tools/configure.sh --build-dir build-win32 \
  --target windows \
  --build-profile release \
  --pkg-config /usr/bin/i686-w64-mingw32.static-pkg-config \
  --cgpr path/to/win32.cgpr
build-win32/build_all.sh
```

## Building Specific Targets

```bash
# Tests (TEST_KIND scenario variable)
gprbuild -P tests/tests.gpr -XADI_PLATFORM=linux -XTEST_KIND=styles
# Or via configure output:
gprbuild -P build-linux/projects/tests_build.gpr -XADI_PLATFORM=linux -XTEST_KIND=styles

# Examples (EXAMPLE_KIND scenario variable)
gprbuild -P examples/examples.gpr -XADI_PLATFORM=linux -XEXAMPLE_KIND=label_example
gprbuild -P build-linux/projects/examples_build.gpr -XADI_PLATFORM=linux -XEXAMPLE_KIND=label_example
```

### SVG rendering

SVG is rendered through the vendored plutosvg / plutovg C library
(`vendor/plutosvg/`). There is nothing to configure — it is built
automatically as part of the library.

### Valid TEST_KIND values
The `Test_Kind` enumeration in `tests/tests.gpr` is the single source of
truth — `tools/configure.sh` and `tools/run_tests.sh` both derive their
lists from it.

### Valid EXAMPLE_KIND values
See the `Example_Kind` enumeration in `examples/examples.gpr`.

## Running

```bash
./tests/bin/<test_name>       # e.g. ./tests/bin/styles
./examples/bin/<example_name> # e.g. ./examples/bin/label_example

# Whole test suite: builds every Ada test (sequentially), runs them
# plus the Python generator tests, exits nonzero on any failure; uses
# SDL's dummy video driver when headless. Also wired as the alr test
# action.
tools/run_tests.sh
```

## Using Adi from another project

`with "adi.gpr"` in your project file. The SDL linker options
(`-lSDL3 -lSDL3_ttf -lSDL3_image -lm`, plus the macOS SDK/Homebrew
switches) are exported from `adi.gpr` as `Linker_Options`, so your
executable links without repeating them.

Adi's public specs use Ada 2022 constructs, and GNAT defaults to Ada 2012,
so units that `with Adi.*` packages need `pragma Ada_2022;` or the
`-gnat2022` switch. Adi itself is built with `-gnatX0`, but that is
internal and does not carry over.

```
with "path/to/adi2/adi.gpr";
project My_App is
   for Main use ("my_app.adb");
   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2022");
   end Compiler;
end My_App;
```

## External Dependencies
- **SDL3**, **SDL3_ttf**, **SDL3_image** — all required

## Vendored Dependencies
- **plutosvg** / **plutovg** — SVG rendering (in `vendor/plutosvg/`)
- **rlottie** — Lottie animation rendering (in `vendor/rlottie/`)

## Library Type
```bash
gprbuild -P adi.gpr -XADI_PLATFORM=linux -XADI_LIBRARY_TYPE=relocatable  # or static (default), static-pic
```

## Configure Script Details

Writes only under `--build-dir`:
- `config/adi_linker_config.gpr` — linker switches from pkg-config (sdl3, sdl3-ttf, sdl3-image)
- `projects/{adi_build.gpr, tests_build.gpr, examples_build.gpr}`
- `build_all.sh` — full build script

Target selection:
- `--target linux` uses `config/posix`
- `--target darwin` uses `config/darwin` (adds macOS SDK syslibroot + Homebrew lib path + `-lc++` to linker switches; vendor C/C++ uses Apple clang)
- `--target windows` uses `config/windows`
- `--macos-sdkroot <path>` overrides the auto-detected SDK (default: `xcrun --show-sdk-path`)
- `--build-profile` sets default profile for generated `build_all.sh`: `development`, `validation`, or `release`
- generated build scripts pass `-XADI_PLATFORM=<target>`

See also: [docs/gprbuild_without_alire.md](gprbuild_without_alire.md)

## Runtime Logging
- Library/runtime logging goes through `Adi.Log`.
- Logging is a **no-op** in `release` and `validation` build profiles — no `debug.log` is created and nothing is written to stdout.
- In the `development` profile, on Windows (`-XADI_PLATFORM=windows`), logs are written to `debug.log` to avoid crashes from missing console output handles in GUI apps.
- In the `development` profile, on Linux (`-XADI_PLATFORM=linux`) and macOS (`-XADI_PLATFORM=darwin`), logs go to standard output.
