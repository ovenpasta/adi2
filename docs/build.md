# Build System

## Quick Reference

### Alire
```bash
alr build                    # builds library + all tests + examples
```

### Direct gprbuild (configure once, build from generated projects)
```bash
tools/configure.sh --build-dir build-linux --target linux
build-linux/build_all.sh
```

### Cross-compile
```bash
tools/configure.sh --build-dir build-win32 \
  --target windows \
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

### Valid TEST_KIND values
`styles`, `layout_test`, `css_parser_test`, `css_source_test`, `text_buffer_test`, `text_layout_test`

### Valid EXAMPLE_KIND values
`label_example`, `widget_demo`, `button_example`, `transition_example`, `text_input_example`, `text_editor_example`, `demo_flex`, `stack_example`, `list_box_example`, `combo_box_example`, `overflow_example`, `grid_example`, `dialog_example`, `font_example`, `runtime_css_example`, `animated_image_example`, `rlottie_example`

## Running

```bash
./tests/bin/<test_name>       # e.g. ./tests/bin/styles
./examples/bin/<example_name> # e.g. ./examples/bin/label_example
```

## External Dependencies
- **SDL3**, **SDL3_ttf**, **SDL3_image** — all required
- **rlottie** — optional, only for `rlottie_example`

## Library Type
```bash
gprbuild -P adi.gpr -XADI_PLATFORM=linux -XADI_LIBRARY_TYPE=relocatable  # or static (default), static-pic
```

## Configure Script Details

Writes only under `--build-dir`:
- `config/adi_linker_config.gpr` — linker switches from pkg-config (sdl3, sdl3-ttf, sdl3-image, rlottie)
- `projects/{adi_build.gpr, tests_build.gpr, examples_build.gpr}`
- `build_all.sh` — full build script

Target selection:
- `--target linux` uses `config/posix`
- `--target windows` uses `config/windows`
- generated build scripts pass `-XADI_PLATFORM=<target>`

See also: [docs/gprbuild_without_alire.md](gprbuild_without_alire.md)
