# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Adi is a GUI library written in Ada 2022 that provides a widget-based UI framework with CSS-like styling capabilities. The library uses SDL3 for windowing/rendering and SDL3_render / SDL3_ttf for vector graphics.

## Build System

This project uses **Alire** (Ada's package manager) with GPR project files:

### Building the library
```bash
alr build
```

This automatically builds the library and runs post-build actions to compile all tests and examples.

### Building specific tests
```bash
# Build a specific test by setting TEST_KIND scenario variable
gprbuild -P tests/tests.gpr -XTEST_KIND=styles
gprbuild -P tests/tests.gpr -XTEST_KIND=flex
gprbuild -P tests/tests.gpr -XTEST_KIND=layout_test
```

### Building specific examples
```bash
# Build a specific example by setting EXAMPLE_KIND scenario variable
gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=ttf_example
gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=label_example
gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=widget_demo
```

### Running tests
```bash
# Tests are built to tests/bin/
./tests/bin/styles
./tests/bin/flex
./tests/bin/layout_test
```

### Running examples
```bash
# Examples are built to examples/bin/
./examples/bin/ttf_example
./examples/bin/label_example
./examples/bin/widget_demo
```

### External Dependencies
- **SDL3**: Required for windowing and event handling (linked via `-lSDL3`)
- **SDL3_ttf**: Required for TrueType font rendering (linked via `-lSDL3_ttf`)
- **SDL3_image**: Required for image loading (linked via `-lSDL3_image`)
- **gnatcoll_minimal**: Ada library dependency managed by Alire

## Architecture

### Core Components

**Adi.Core** (`adi-core.ads`): Foundational types
- Geometric primitives: `Point`, `Size_2D`, `Rectangle`, `Pixel_Type`
- Color types: `Color` (normalized 0.0-1.0), `Color_8` (0-255)

**Adi.Style** (`adi-style.ads`): Comprehensive CSS-like style system
- Dimension values: pixels, DIPs, percentages, `fr` units
- Box model, flexbox, and grid layout properties
- Typography properties and color constants
- Widget states and style rule management

**Adi.CSS_Styles** (`adi-css_styles.ads`): CSS-like styling system
- Length units: `Px`, `Dip`, `Em`, `Root_Em`, `Pct`
- Color values: Named colors, RGB, RGBA
- Optional values pattern for style inheritance/cascading
- Border, padding, margin, background properties
- Comprehensive style properties matching CSS box model

**Adi.Widget_Styles** (`adi-widget_styles.ads`): Widget state-based styling
- State-specific styles: `Normal`, `Hovered`, `Pressed`, `Focused`, `Disabled`, `Selected`
- Style builder pattern for fluent API
- Resolves CSS styles to final computed values

**Adi.Widget.Part_Styles** (`adi-widget-part_styles.ads`): Multi-part widget style builder
- Fluent API for composing per-part styles (Main, Label, Icon, Indicator, etc.)
- State-dependent styling per part
- Predefined templates: Button, Checkbox, Scrollbar
- Theme styles: Primary, Secondary, Danger, Card

**Adi.Event** (`adi-event.ads`): Event system
- Discriminant-based event record with `Mouse_Move` event kind
- Timestamp and mouse position/speed data

**Adi.Image** (`adi-image.ads`): Image resource management
- SDL texture wrapper with file loading
- Size queries and lifecycle management

**Adi.Widget** (`adi-widget.ads`): Base widget abstraction
- Abstract tagged type with hierarchy management (parent/children)
- **Part system**: Widgets are composed of styleable parts (`Main_Part`, `Indicator_Part`, `Label_Part`, etc.)
- **Item system**: Renderable primitives (`Panel_Item`, `Text_Item`, `Image_Item`) that compose a widget
- Each part has its own `Widget_Style` that resolves based on widget states
- Widget flags: `Clickable`, `Focusable`, `Scrollable`, `Draggable`, `Visible`
- Dirty tracking for efficient updates
- Abstract methods: `Build_Items` (construct renderable items), `Layout` (calculate geometry)
- Concrete rendering: `Render_Items`, `Render_Tree`, `Update_And_Render`

**Adi.Layout_Util** (`adi-layout_util.ads`): Layout algorithms
- Box model calculations: `Content_Box`, `Padding_Box`
- Edge/border pixel extraction
- Alignment utilities (horizontal/vertical)
- Flexbox layout support (in progress)

**Adi.Window** (`adi-window.ads`): Window management
- Wraps SDL window and renderer
- Root widget container
- Mouse event handling with widget hit testing
- Window resize/reshape handling

**Adi.App** (`adi-app.ads`): Application entry point
- Initialization and main loop
- Window management

### Widget Rendering Pipeline

1. **Build Phase**: `Build_Items` creates renderable `Item` records for each visual element
2. **Style Resolution**: Each item references a `Part_Kind`, which has a `Widget_Style` that resolves to `Resolved_Style` based on current widget states
3. **Layout Phase**: `Layout` calculates geometry for widget and children
4. **Render Phase**: `Render_Items` draws each item using its computed style and geometry

### SDL Integration

The library provides Ada bindings for SDL3 in `adi-sdl*.ads` files:
- `Adi.SDL`: Core SDL types and initialization (defines `Uint8`, `Uint32`, `C_bool`, `SDL_Rect`, etc.)
- `Adi.SDL.Video`: Window management bindings
- `Adi.SDL.Render`: Renderer bindings
- `Adi.SDL.Events`: Event handling bindings
- `Adi.SDL.Mouse`: Mouse input bindings
- `Adi.SDL.TTF`: TrueType font rendering bindings (SDL3_ttf)
- `Adi.SDL.TTF.TextEngine`: Advanced text layout and rendering callbacks (SDL3_ttf)
- `Adi.SDL.Image`: Image file loading/saving bindings (SDL3_image)
- `Adi.SDL.Surface`: Low-level pixel buffer and surface bindings
- `Adi.SDL.PixelFormat`: Pixel format constant enumerations

**Binding Design Pattern**: These are clean, hand-crafted bindings that:
- Use native Ada types (`Uint8`, `Uint32`, `C_bool`, `int`, `Float`) instead of raw C imports
- Avoid dependencies on auto-generated bindings (no `stddef_h`, `SDL3_SDL_stdinc_h`, etc.)
- Use incomplete types for opaque structures: `type TTF_Font is limited null record;`
- Use proper Ada enumerations with representation clauses for C enums
- Follow consistent naming and formatting conventions

Note: These are custom bindings, not the SDLAda project (which is commented out in `adi.gpr`).

## Project Structure

```
src/                  - Main library source files
  adi-*.ad[bs]        - All library modules follow Ada package naming
  adi-widget-*.ad[bs] - Widget implementations (Box, Label)
  adi-sdl-*.ad[bs]    - SDL3 bindings (core, video, render, events, mouse, ttf, image, surface)
tests/
  src/                - Test programs
    styles.adb        - Style system test
    flex.adb          - Flexbox layout test
    layout_test.adb   - Flexbox layout unit test
    css_to_ada.py     - Python tool to generate Ada style code from CSS
  tests.gpr           - Test project file (uses TEST_KIND scenario)
examples/
  ttf_example.adb     - TTF font rendering example
  label_example.adb   - Label widget example with styling
  widget_demo.adb     - Widget demo with background image
  examples.gpr        - Example project file (uses EXAMPLE_KIND scenario)
config/               - Build configuration
  adi_config.ads/gpr  - Generated by Alire
deps/                 - Alire-managed dependencies
alire.toml            - Alire project manifest
adi.gpr               - Main GPR project file
```

## Coding Conventions

### Ada Standards
- Uses **Ada 2022** with GNAT extensions (`-gnat2022 -gnatX0`)
- Library uses `-gnatef` for full error paths
- Tests use `-g -gnatwa -gnata` (debug, all warnings, assertions)

### Package Hierarchy
All packages are rooted under `Adi`:
- `Adi` - Root package
- `Adi.Core` - Core types
- `Adi.Style` - CSS-like style properties and rules
- `Adi.CSS_Styles` - CSS value types and style resolution
- `Adi.Widget_Styles` - State-based widget styling
- `Adi.Widget` - Base widget abstraction
- `Adi.Widget.Box`, `Adi.Widget.Label` - Concrete widgets
- `Adi.Widget.Part_Styles` - Multi-part style builder
- `Adi.Event` - Event types
- `Adi.Font` - Font loading and caching
- `Adi.Image` - Image resource management
- `Adi.Layout_Util` - Layout algorithms
- `Adi.Window` - Window management
- `Adi.App` - Application entry point
- `Adi.SDL.*` - SDL3 bindings (core, Video, Render, Events, Mouse, TTF, Image, Surface, PixelFormat)

### Naming Patterns
- Types: `Widget`, `Rectangle`, `Color_Value`
- Access types: `Widget_Access`, `Window_Access`
- Functions returning accessors: `Create`, `Get_*`
- Procedures for mutation: `Set_*`, `Add_*`, `Remove_*`

## CSS Style Generation

The `tests/src/css_to_ada.py` tool converts CSS files to Ada code using the library's style API:

```bash
python tests/src/css_to_ada.py input.css output.ads --package-name=My_Styles
```

This generates Ada package specifications with style constants that can be applied to widgets. See `tests/src/prova_css.ads` for an example.

## Library Build Configuration

The library can be built as:
- Static library (default): `LIBRARY_TYPE=static`
- Shared library: `LIBRARY_TYPE=relocatable`
- Position-independent static: `LIBRARY_TYPE=static-pic`

Set via environment variable or GPR external:
```bash
gprbuild -P adi.gpr -XADI_LIBRARY_TYPE=relocatable
```
