# CLAUDE.md

Ada 2022 GUI library using SDL3. Widget-based with CSS-like styling.

## Build

```bash
alr build                    # Alire: library + tests + examples
tools/configure.sh --build-dir build-linux && build-linux/build_all.sh  # direct gprbuild
```

```bash
gprbuild -P tests/tests.gpr -XTEST_KIND=styles                   # single test
gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=label_example   # single example
./tests/bin/styles                                                # run test
./examples/bin/label_example                                      # run example
```

TEST_KIND: `styles`, `layout_test`, `css_parser_test`, `css_source_test`, `text_buffer_test`, `text_layout_test`

EXAMPLE_KIND: `label_example`, `widget_demo`, `button_example`, `transition_example`, `text_input_example`, `text_editor_example`, `demo_flex`, `stack_example`, `list_box_example`, `combo_box_example`, `overflow_example`, `grid_example`, `dialog_example`, `font_example`, `runtime_css_example`, `animated_image_example`, `rlottie_example`

Dependencies: SDL3, SDL3_ttf, SDL3_image (required); rlottie (optional).

## Key Patterns

- **Ada 2022** with GNAT extensions (`-gnat2022 -gnatX0`)
- All packages under `Adi`. Widgets in `Adi.Widget.*`, SDL bindings in `Adi.SDL.*`
- **`Style_Rules`** = optional/cascade values; **`Resolved_Style`** = concrete with defaults
- **Build_Items**: create items once (when vector empty), update in-place. Fixed indices per widget
- **Items_List**: `Ada.Containers.Vectors` (not Indefinite). Items persist across frames
- **Font cache**: sized `TTF_Font` per `(handle, size)` — never `TTF_SetFontSize` on shared fonts
- **TTF_Text cache**: in `Item.Cached_TTF_Text`, update via `TTF_SetTextString`
- **Hierarchy calls** use `access Widget'Class` (no `Widget_Access` casts at call sites)
- **Internal storage**: `C.all'Unchecked_Access` to avoid accessibility `PROGRAM_ERROR`
- **Callbacks**: named access types; examples use `'Unrestricted_Access`
- No built-in visual theme — apps provide styles (typically via generated CSS packages)
- CSS generation: `python tools/css_to_ada.py input.css output.ads --package-name=Name`
- Selector pseudo before `::part` = widget-scoped; after `::part` = part-scoped

## Project Layout

```
src/adi-*.ads/adb           - Library (core, styles, widgets, SDL bindings, animation, font, layout)
tests/src/                  - Tests (TEST_KIND scenario)
examples/                   - Examples (EXAMPLE_KIND scenario) + css/ + generated/
tools/                      - css_to_ada.py, configure.sh, generate_example_styles.sh
config/                     - Build config (posix/ and windows/ variants)
```

## Detailed Docs

- [docs/architecture.md](docs/architecture.md) — component descriptions, widget details, rendering pipeline
- [docs/build.md](docs/build.md) — full build system reference
- [docs/css_styling.md](docs/css_styling.md) — CSS properties, selectors, generation, runtime parser
- [docs/coding_conventions.md](docs/coding_conventions.md) — naming, API conventions, project structure
- [docs/gprbuild_without_alire.md](docs/gprbuild_without_alire.md) — configure script details

### Git
Never add co-authored-by: line on commit messages
