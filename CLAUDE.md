# CLAUDE.md

## Project Overview

Adi is a GUI library in Ada 2022 using SDL3 for windowing/rendering and SDL3_ttf for text. It provides a widget-based UI framework with CSS-like styling, declarative XML UI generation, and runtime CSS live-reload.

## Read the Docs First

Before making changes, read the relevant documentation. Do not guess at APIs or conventions — the docs are authoritative.

| Topic | File |
|-------|------|
| Architecture & core components | `docs/architecture.md` |
| Coding conventions | `docs/coding_conventions.md` |
| CSS styling (selectors, properties, runtime API, code generation) | `docs/css_styling.md` |
| XML UI system (declarative widgets, code generation, components) | `docs/xml_ui_system.md` |
| Build system (Alire, gprbuild, configure) | `docs/build.md` |
| gprbuild without Alire | `docs/gprbuild_without_alire.md` |
| HTML view widget | `docs/html_view_spec.md` |
| Adding a new CSS property | `docs/adding_css_property.md` |
| Antialiased rendering (AA fringe, ring patterns) | `docs/rendering_aa.md` |

## Build Commands

```bash
# Full build (library + tests + examples, incremental CSS/UI generation)
alr build

# Build a specific test
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=css_parser_test

# Build a specific example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=stack_example

# Run tests (built to tests/bin/)
./tests/bin/styles
./tests/bin/layout_test
./tests/bin/css_parser_test
./tests/bin/css_source_test
./tests/bin/text_buffer_test
./tests/bin/text_layout_test
./tests/bin/html_view_test
./tests/bin/disabled_test
```

For direct gprbuild (no Alire), see `docs/gprbuild_without_alire.md` and `docs/build.md`.

## Code Generation Pipelines

### CSS → Ada (`tools/css_to_ada.py`)

```bash
python3 tools/css_to_ada.py input.css output.ads --package-name=My_Styles
```

Incremental build for all examples: `tools/generate_example_styles.sh`. Full reference in `docs/css_styling.md`.

### XML → Ada (`tools/xml_to_ada.py`)

```bash
python3 tools/xml_to_ada.py input.xml --output-dir out/ --package-name My_UI
```

Incremental build for examples: `tools/generate_example_ui.sh`. Full reference in `docs/xml_ui_system.md`.

Widget grammar is defined in `tools/widgets.xml` (13 widget types). Extensible via `--grammar`.

## Key Architecture Points

- **Ada 2022** with GNAT extensions (`-gnat2022 -gnatX0`)
- All packages rooted under `Adi`
- **Item record** is flattened (no discriminant variant); `Kind` distinguishes usage
- **Build_Items convention**: create items once (when vector is empty), update in-place on subsequent calls
- **Font system**: `Font_Handle` = font family. Sized `TTF_Font` instances cached per `(handle, size)` pair. Never call `TTF_SetFontSize` on shared fonts.
- **TTF_Text caching**: stored in `Item.Cached_TTF_Text`, created on first render, updated via `TTF_SetTextString`
- **Style_Rules** carries optional/unset values for CSS cascade; **Resolved_Style** is fully concrete
- **Widget_Style** fluent builder: `From(base).On(When_State(...), style).Build`
- **Hierarchy calls** use `access Widget'Class` (no `Widget_Access` cast needed at call sites)
- **Callbacks** use named access types; `'Unrestricted_Access` required for local subprograms

## Common Pitfalls

- `C_bool` ambiguity: both `Adi.SDL` and `Interfaces.C` define it. Qualify as `Adi.SDL.C_bool`.
- `Indefinite_Vectors` vs `Vectors`: only needed for discriminated types without defaults. Item is flattened, so use regular Vectors.
- SDL3_ttf font sharing: each `TTF_Font` is at a specific size. Changing size invalidates all `TTF_Text` objects. Use separate instances per size.
- Generic access types: local generic instantiation creates local access types. Convert via intermediate `access Widget'Class` variable with `'Unchecked_Access`, then cast to `Widget_Access`.
- `others` not allowed in delta aggregates: use `[for I in T => I = X]` pattern.

## CSS Quick Reference

- Selectors: `.class`, `#id`, `tag`; part selectors `::main`, `::label`, `::icon`, `::cursor`, `::selected`, `::indicator`, `::scroll`, `::knob`, `::items`
- Pseudo-classes: `:hover`, `:pressed`/`:active`, `:focus`, `:disabled`, `:checked`/`:selected`, `:not()`
- Pseudo placement: before `::part` = widget-scoped; after `::part` = part-scoped
- Runtime: `Adi.CSS_Source` (Dynamic_Mode for dev live-reload, Static_Mode for release)
- Full property list and details in `docs/css_styling.md`

## SDL Bindings

When adding new SDL API bindings (new functions, new subsystems), follow this workflow:

1. **Check `bindings/` first** — it contains 80+ auto-generated Ada bindings from SDL3/SDL3_ttf/SDL3_image C headers. These are the reference for function signatures, types, and constants.
2. **Do not use the auto-generated bindings directly** — they have complex dependency chains (`stddef_h`, `SDL3_SDL_stdinc_h`, etc.) and raw C types.
3. **Create or extend hand-crafted bindings in `src/adi-sdl*.ads`** — scan the relevant auto-generated file in `bindings/` for the function signature, then write a clean Ada binding in the appropriate `Adi.SDL.*` child package.
4. **Follow the established binding pattern** documented in `src/SDL_BINDINGS_README.md`:
   - Use native Ada types from `Adi.SDL` (`Uint8`, `Uint32`, `C_bool`, `int`, `Float`)
   - Use incomplete types for opaque structures: `type T is limited null record;`
   - Use Ada enumerations with `Convention => C` for C enums
   - Use constants with `new Uint32` for bitflags
   - No dependencies on auto-generated bindings

Existing hand-crafted binding modules:

| Module | File | Covers |
|--------|------|--------|
| `Adi.SDL` | `adi-sdl.ads` | Core types, init, clipboard |
| `Adi.SDL.Video` | `adi-sdl-video.ads` | Window management |
| `Adi.SDL.Render` | `adi-sdl-render.ads` | 2D rendering, textures |
| `Adi.SDL.TTF` | `adi-sdl-ttf.ads` | Font loading, text rendering |
| `Adi.SDL.TTF.TextEngine` | `adi-sdl-ttf-textengine.ads` | Advanced text layout |
| `Adi.SDL.Events` | `adi-sdl-events.ads` | Event handling, scancodes |
| `Adi.SDL.Mouse` | `adi-sdl-mouse.ads` | Mouse state, cursors |
| `Adi.SDL.Surface` | `adi-sdl-surface.ads` | Pixel buffers |
| `Adi.SDL.PixelFormat` | `adi-sdl-pixelformat.ads` | Pixel format constants |
| `Adi.SDL.Image` | `adi-sdl-image.ads` | Image file loading |

## Project Structure

```
src/                  Main library (adi-*.ads/adb)
bindings/             Auto-generated SDL3 bindings (reference only, do not use directly)
tests/src/            Test programs (built to tests/bin/)
examples/             Example programs (built to examples/bin/)
examples/css/         CSS source files
examples/xml/         XML UI definitions
examples/generated/   Auto-generated Ada from CSS and XML
tools/                Code generators and build scripts
docs/                 Reference documentation
```

## Testing

- Always write tests for new functionality when feasible, covering all corner cases
- Never fix or weaken a test to accommodate a missing or incorrect implementation — ask for clarification on how to proceed instead

## Git Conventions

- Never add co-authored-by line on commit messages
- Always provide both a short subject line and a brief multi-line body describing what changed and why
