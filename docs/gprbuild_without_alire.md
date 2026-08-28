# Building Without Alire

`configure` writes the project files once; building from them afterwards needs no Alire environment.

## 1) Configure build dir

```bash
tools/configure.sh --build-dir build-linux --target linux
```

Cross toolchain example:

```bash
tools/configure.sh \
  --build-dir build-win32 \
  --target windows \
  --pkg-config /usr/bin/i686-w64-mingw32.static-pkg-config \
  --cgpr path/to/win32.cgpr
```

macOS example:

```bash
tools/configure.sh --build-dir build-macos --target darwin
# Override the SDK path if `xcrun --show-sdk-path` is not what you want:
tools/configure.sh --build-dir build-macos --target darwin \
  --macos-sdkroot /Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk
```

The darwin target adds `-Wl,-syslibroot,<sdk>`, `-L/opt/homebrew/lib`,
`-Wl,-rpath,/opt/homebrew/lib`, and `-lc++` to the linker switches. SDL3 is
expected at the Homebrew default prefix; install via `brew install sdl3
sdl3_image sdl3_ttf`. Vendor C/C++ (rlottie, plutosvg) uses Apple `clang`
on darwin (set by the project gpr files via `-XADI_PLATFORM=darwin`).

Optional explicit source dir:

```bash
tools/configure.sh --source-dir /path/to/adi --build-dir /tmp/adi-build
```

Generated files:
- `<build-dir>/config/adi_linker_config.gpr` (link flags from pkg-config, with defaults if unavailable)
- `<build-dir>/projects/adi_build.gpr`
- `<build-dir>/projects/tests_build.gpr`
- `<build-dir>/projects/examples_build.gpr`
- `<build-dir>/build_all.sh` (full build command using configured paths/options)
- `config/adi2_config.gpr` in the *source* tree, and only when absent — see below

## One-command full build (from build dir)

```bash
build-linux/build_all.sh
build-win32/build_all.sh
```

## 2) Build using generated projects

```bash
gprbuild -P build-linux/projects/adi_build.gpr -XADI_PLATFORM=linux
gprbuild -P build-linux/projects/tests_build.gpr -XADI_PLATFORM=linux -XTEST_KIND=styles
gprbuild -P build-linux/projects/examples_build.gpr -XADI_PLATFORM=linux -XEXAMPLE_KIND=label_example
```

## 3) Cross-target with `.cgpr`

```bash
gprbuild --config=path/to/target.cgpr -P build-win32/projects/adi_build.gpr -XADI_PLATFORM=windows
gprbuild --config=path/to/target.cgpr -P build-win32/projects/tests_build.gpr -XADI_PLATFORM=windows -XTEST_KIND=styles
```

Notes:
- One file is written to the source tree: `config/adi2_config.gpr`. `adi.gpr`
  withs it to learn which build profile was chosen, and a `with` on a relative
  path resolves next to the project file, so it cannot live under `--build-dir`.
  Alire writes it on every build; `configure.sh` writes a stub only when no file
  is there, and never replaces one. It is gitignored, like the rest of the
  Alire-generated files already in `config/`. Everything else configure.sh
  generates lives under `--build-dir`.
- Platform is explicit: `--target linux|darwin|windows` in `configure.sh` and `-XADI_PLATFORM=<linux|darwin|windows>` in manual `gprbuild`.
- `build_all.sh` skips `mcp_test` unless the build is a development profile for
  a non-Windows target, which is where `adi.gpr` compiles the real `Adi.MCP`.
- Alire builds remain supported (`alr build`, `alr exec -- gprbuild ...`).
