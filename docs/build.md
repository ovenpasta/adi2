# Build System

## Quick Reference

### Alire
```bash
alr build                    # builds library + all tests + examples (and runs incremental example CSS generation)
```

### Direct gprbuild (configure once, build from generated projects)
```bash
# Prefer Alire environment wrapping for direct gprbuild invocations:
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=styles

tools/configure.sh --build-dir build-linux --target linux --build-profile development
build-linux/build_all.sh
```

When building outside Alire (no post-build actions), run code generation scripts first:
```bash
bash tools/generate_example_styles.sh
bash tools/generate_example_ui.sh
bash tools/generate_example_bundles.sh
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

### SVG backend selection

`Adi` now supports two compile-time SVG backends:

- `plutosvg` (default): vendored C backend (`vendor/plutosvg/` + `vendor/plutosvg/plutovg/`)
- `ada`: native Ada backend (`src/svg/ada`)

Select backend with `ADI_SVG_BACKEND`:

```bash
# default (plutosvg)
gprbuild -P adi.gpr -XADI_PLATFORM=linux

# force Ada backend
gprbuild -P adi.gpr -XADI_PLATFORM=linux -XADI_SVG_BACKEND=ada
```

Configure-generated builds can also set backend default:

```bash
tools/configure.sh --build-dir build-linux --target linux --svg-backend plutosvg
```

### Valid TEST_KIND values
`styles`, `layout_test`, `layout_flex_grid_test`, `css_parser_test`, `css_source_test`, `text_buffer_test`, `text_layout_test`, `html_view_test`, `svg_test`, `svg_perf_test`, `disabled_test`, `image_widget_test`, `slider_test`, `value_input_test`, `svg_sprites_test`, `min_size_test`, `layout_perf_test`, `style_storage_equivalence_test`, `window_resize_safety_test`, `mcp_test`, `bundle_test`, `signal_test`, `dispatch_test`, `i18n_test`, `settings_test`, `close_request_test`, `window_handle_test`, `text_editor_test`, `handle_store_test`, `widget_handle_test`

### Valid EXAMPLE_KIND values
`label_example`, `widget_demo`, `button_example`, `transition_example`, `text_input_example`, `text_editor_example`, `demo_flex`, `stack_example`, `list_box_example`, `combo_box_example`, `overflow_example`, `grid_example`, `dialog_example`, `font_example`, `runtime_css_example`, `animated_image_example`, `rlottie_example`, `html_view_example`, `assets_example`

## Running

```bash
./tests/bin/<test_name>       # e.g. ./tests/bin/styles
./examples/bin/<example_name> # e.g. ./examples/bin/label_example
```

## SVG performance comparison

Use the helper script to compare both backends in `development` and `release` profiles:

```bash
./tools/compare_svg_perf.sh linux
```

The report prints both:

- `cold_ms`: first render for a size (no warm cache)
- `avg_ms`: repeated renders for the same size (hot path)

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
- `--target windows` uses `config/windows`
- `--build-profile` sets default profile for generated `build_all.sh`: `development`, `validation`, or `release`
- generated build scripts pass `-XADI_PLATFORM=<target>`

See also: [docs/gprbuild_without_alire.md](gprbuild_without_alire.md)

## Runtime Logging
- Library/runtime logging goes through `Adi.Log`.
- On Windows targets (`-XADI_PLATFORM=windows`), logs are written to `debug.log` to avoid crashes from missing console output handles in GUI apps.
- On Linux targets (`-XADI_PLATFORM=linux`), logs go to standard output.
