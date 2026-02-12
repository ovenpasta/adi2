# Building Without Alire

This project can be built directly with `gprbuild` and optional `.cgpr` target files.

## 1) Configure linker flags

Preferred (uses `pkg-config`):

```bash
source tools/setup_pkg_config_env.sh
```

If building `rlottie_example`:

```bash
source tools/setup_pkg_config_env.sh --with-rlottie
```

Manual overrides (if `pkg-config` is not available):

```bash
export ADI_SDL_LINKER_FLAGS="-lSDL3 -lSDL3_ttf -lSDL3_image -lm"
export ADI_RLOTTIE_LINKER_FLAGS="-lrlottie"
export ADI_PLATFORM_LINKER_FLAGS=""
```

## 2) Build library/tests/examples

```bash
gprbuild -P adi.gpr
gprbuild -P tests/tests.gpr -XTEST_KIND=styles
gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=label_example
```

## 3) Cross-target with `.cgpr`

Use GPR's target config directly:

```bash
gprbuild --config=path/to/target.cgpr -P adi.gpr
gprbuild --config=path/to/target.cgpr -P tests/tests.gpr -XTEST_KIND=styles
```

## Useful project variables

- `-XADI_BUILD_PROFILE=development|validation|release`
- `-XADI_LIBRARY_VERSION=<version>`

Notes:
- `config/adi_config.gpr` is no longer required for direct builds.
- Alire builds remain supported (`alr build`, `alr exec -- gprbuild ...`).
