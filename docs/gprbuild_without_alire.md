# Building Without Alire

This flow is file-based and fish-friendly: run `configure` once, then build from generated projects.

## One-command full build

```bash
tools/build_all.sh --build-dir build-linux --source-dir .
```

Cross toolchain example:

```bash
tools/build_all.sh \
  --build-dir build-win32 \
  --source-dir . \
  --pkg-config /usr/bin/i686-w64-mingw32.static-pkg-config \
  --gpr-config path/to/win32.cgpr
```

## 1) Configure build dir

```bash
tools/configure.sh --build-dir build-linux
```

Cross toolchain example:

```bash
tools/configure.sh \
  --build-dir build-win32 \
  --pkg-config /usr/bin/i686-w64-mingw32.static-pkg-config
```

Optional explicit source dir:

```bash
tools/configure.sh --source-dir /path/to/adi --build-dir /tmp/adi-build
```

Generated files:
- `<build-dir>/config/adi_linker_config.gpr` (link flags from pkg-config, with defaults if unavailable)
- `<build-dir>/projects/adi_build.gpr`
- `<build-dir>/projects/tests_build.gpr`
- `<build-dir>/projects/examples_build.gpr`

## 2) Build using generated projects

```bash
gprbuild -P build-linux/projects/adi_build.gpr
gprbuild -P build-linux/projects/tests_build.gpr -XTEST_KIND=styles
gprbuild -P build-linux/projects/examples_build.gpr -XEXAMPLE_KIND=label_example
```

## 3) Cross-target with `.cgpr`

```bash
gprbuild --config=path/to/target.cgpr -P build-win32/projects/adi_build.gpr
gprbuild --config=path/to/target.cgpr -P build-win32/projects/tests_build.gpr -XTEST_KIND=styles
```

Notes:
- No writes to source `config/`; all generated files live under `--build-dir`.
- Alire builds remain supported (`alr build`, `alr exec -- gprbuild ...`).
