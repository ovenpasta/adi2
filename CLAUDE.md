# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Adi is a GUI library written in Ada 2022 that provides a widget-based UI framework with CSS-like styling capabilities. The library uses SDL3 for windowing/rendering and SDL3_render / SDL3_ttf for vector graphics.

## Build System

This project uses **Alire** (Ada's package manager) with GPR project files:

### Building the library
```bash
alr build
you normally don't use gprbuild directly but through alr exec -- gprbuild
```

This automatically builds the library and runs post-build actions to compile all tests and examples.

### Building specific tests
```bash
# Build a specific test by setting TEST_KIND scenario variable
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=styles
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=layout_test
```

### Building specific examples
```bash
# Build a specific example by setting EXAMPLE_KIND scenario variable
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=label_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=widget_demo
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=button_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=transition_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=text_input_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=demo_flex
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=stack_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=list_box_example
```

### Running tests
```bash
# Tests are built to tests/bin/
./tests/bin/styles
./tests/bin/layout_test
```

### Running examples
```bash
# Examples are built to examples/bin/
./examples/bin/label_example
./examples/bin/widget_demo
./examples/bin/button_example
./examples/bin/transition_example
./examples/bin/text_input_example
./examples/bin/demo_flex
./examples/bin/stack_example
./examples/bin/list_box_example
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
- Shared input enums: `Mouse_Button` (Left/Middle/Right/X1/X2)

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
- Box shadow with blur, spread, offset, and color
- Comprehensive style properties matching CSS box model
- Transition support: `Transition_Spec` with duration, easing, and property filter
- `Animatable_Property` enum and `Property_Set` for targeting specific properties
- `Normalize_Color` helper for extracting RGBA from any `Color_Value` variant

**Adi.Widget_Styles** (`adi-widget_styles.ads`): Widget state-based styling
- State-specific styles: `Normal`, `Hovered`, `Pressed`, `Focused`, `Disabled`, `Selected`
- Style builder pattern for fluent API
- Resolves CSS styles to final computed values
- `With_Transition(Duration, [Properties], [Easing])`: sets transition on base style

**Adi.Widget.Part_Styles** (`adi-widget-part_styles.ads`): Multi-part widget style builder
- Fluent API for composing per-part styles (Main, Label, Icon, Indicator, etc.)
- State-dependent styling per part
- Predefined templates: Button, Checkbox, Scrollbar
- Theme styles: Primary, Secondary, Danger, Card

**Adi.Event** (`adi-event.ads`): Event system
- Discriminant-based event record with `Mouse_Move` event kind
- Timestamp and mouse position/speed data

**Adi.Render** (`adi-render.ads`): Per-renderer context and caches
- `Render_Context`: Bundles an `SDL_Renderer_Ptr` with its per-renderer caches (shadow textures, TTF text engine)
- Shadow texture cache with `Shadow_Key` lookup and LRU eviction (max 32 entries)
- Lazy-created TTF text engine via `Get_Text_Engine`
- Threaded through `Render_Items`, `Render_Tree`, `Update_And_Render` instead of raw `SDL_Renderer_Ptr`
- Owned by `Adi.Window`; created after the renderer, destroyed before it

**Adi.Animation** (`adi-animation.ads`): CSS-like style transitions
- `Part_Transition` record: tracks active animation state per widget part
- `Advance`: steps a transition forward by delta time, outputs interpolated style
- `Interpolate`: field-by-field lerp between two `Resolved_Style` values
- Lerp helpers: `Lerp_Color`, `Lerp_Length`, `Lerp_Box`, `Lerp_Border_*`, `Lerp_Box_Shadow`
- Easing functions: `Linear`, `Ease_In` (cubic), `Ease_Out`, `Ease_In_Out`
- Property filtering: only properties in `Transition_Spec.Properties` are interpolated; others snap

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
- Concrete rendering: `Render_Items`, `Render_Tree`, `Update_And_Render` (take `Render_Context`)
- Image rendering: `Render_Rounded_Image` clips textures to rounded rects via UV-mapped triangle fans
- `object-fit` modes: `Fill`, `Cover` (UV cropping), `Contain`, `None`, `Scale_Down`
- Contain/None/Scale_Down adjust corner radii based on image inset from container edges
- Per-corner border radius: `Render_Rounded_Rect` overload accepts `Corner_Pixels`
- **Animation**: Per-part `Part_Transition_Array` tracks active transitions; `Tick_Animations` advances them each frame; `Apply_Styles_To_Items` starts transitions when resolved style targets change

**Adi.Text_Buffer** (`adi-text_buffer.ads`): Shared text editing core
- Line-oriented text storage for editing widgets
- Caret model with line/column positions
- Selection support and editing/navigation operations (`Insert_Text`, `Delete_Backward`, `Move_Left`, etc.)
- Reusable foundation for single-line and future multiline text editors
- UTF-8 aware caret movement/editing: left/right/delete/backspace operate on character boundaries (not raw bytes)
- Selection introspection API: `Get_Selection_Range`

**Adi.Widget.Text_Input** (`adi-widget-text_input.ads`): Single-line text input widget
- Uses `Adi.Text_Buffer` for text/caret/selection state
- Supports keyboard navigation/editing (arrows, home/end, backspace/delete, select-all)
- Receives `On_Key_Down` and `On_Text_Input` through window focus dispatch
- Renders a styled caret via `Cursor_Part`
- Renders selection highlight via `Selected_Part`
- Mouse hit-testing uses SDL_ttf measurement (`TTF_MeasureString`) for UTF-8-safe caret/selection placement
- Click behavior: single click places caret, double click selects word, triple click selects all text
- Long single-line content does not wrap; it scrolls horizontally to keep the caret visible
- Text rendering uses a fixed clip region (input content box) with a text X offset for horizontal scrolling
- Selection highlight is clamped to content bounds (no overflow outside the widget)
- Dragging selection left of the widget clamps to the start of text (column 0)
- Double-click word selection is deferred until mouse-up; moving past a small threshold converts to normal drag selection
- `Create` does not apply built-in styles; examples/apps define `Main/Label/Cursor/Selected` part styles explicitly

**Adi.Widget.List_Box** (`adi-widget-list_box.ads`): Generic list container widget
- Generic over row widget type (`Row_Widget` / `Row_Widget_Access`)
- Manages rows, row heights, row gaps, and vertical scrolling with wheel + keyboard navigation
- Selection modes: `No_Selection`, `Single_Selection`, `Multi_Selection`, `Range_Selection`
- Supports anchor-based range selection (`Shift+Click` / `Shift+Arrow`); `Multi_Selection` also supports toggle (`Ctrl+Click`)
- Renders scrollbar track/knob parts (`Scroll_Part`, `Knob_Part`) with draggable knob + track paging
- Scrollbar geometry is style-driven from `::scroll`/`::knob` CSS (`width`, `margin`, `padding`, `min-height`)
- Focusable + scrollable by default, participates in Tab focus traversal
- Selection APIs: `Select_Row`, `Toggle_Row_Selected`, `Clear_Selection`, `Get_Selected_Count`
- Callbacks: `On_Item_Clicked`, `On_Item_Activated`, `On_Selection_Changed`
- Current limitation: `:hover`/`:pressed` selectors are widget-state scoped; part-scoped selector disambiguation (e.g. `list::scroll:hover` vs `list:hover::scroll`) is deferred for later refactor

**Adi.Widget.Stack** (`adi-widget-stack.ads`): Generic stack container widget
- Generic over `Page_Id` discrete type (typically an enum)
- Shows one child at a time; pages keyed by `Page_Id`
- `Add_Page(Id, Page)`: registers a page; first page added auto-activates
- `Set_Active(Id)`: hides old page, shows new, fires callback
- `Get_Page(Id)`: returns page widget (null if never added)
- All children receive full layout so page switching is instant
- Rendering/hit-testing of hidden pages excluded via `Visible` flag checks in `Render_Tree` and `Find_Widget_At`
- Single item: `Panel_Item` (Main_Part) background
- Type-safe binding with `Button.Options`: instantiate both over the same enum, wire `On_Changed` to `Set_Active`
- Internally stores `array (Page_Id) of Widget_Access` — enum is the key, no index tracking

**Adi.Layout_Util** (`adi-layout_util.ads`): Layout algorithms
- Box model calculations: `Content_Box`, `Padding_Box`
- Edge/border pixel extraction
- Alignment utilities (horizontal/vertical)
- Flexbox layout support (in progress)

**Adi.Window** (`adi-window.ads`): Window management
- Wraps SDL window and renderer
- Owns a `Render_Context` for per-renderer caches
- Root widget container
- Mouse event handling with widget hit testing
- Keyboard focus handling with Tab traversal across focusable/visible widgets (Shift+Tab reverse, wraps around)
- `Tick(DT)`: advances animations on the widget tree each frame
- Window resize/reshape handling

**Adi.App** (`adi-app.ads`): Application entry point
- Initialization and main loop
- Window management
- Frame rate management: `Set_Target_FPS`, `Get_Delta_Time`
- Proper frame timing with `Ada.Real_Time` (`delay until`) instead of fixed delay
- Each frame: compute delta time, tick animations, render, wait for next frame

### Widget Rendering Pipeline

1. **Build Phase**: `Build_Items` creates renderable `Item` records for each visual element
2. **Style Resolution**: Each item references a `Part_Kind`, which has a `Widget_Style` that resolves to `Resolved_Style` based on current widget states
3. **Layout Phase**: `Layout` calculates geometry for widget and children
4. **Render Phase**: `Render_Items` draws each item using its computed style, geometry, and a `Render_Context` (which holds the renderer, shadow cache, and text engine)
   - Rounded borders always use `Render_Rounded_Border_Ring` (annulus) + separate background fill
   - Non-rounded borders use fast SDL rect primitives
   - **Text positions are snapped to integer pixels** (`Float'Floor`) before drawing to prevent sub-pixel blurring from texture interpolation
   - Font hinting uses `TTF_HINTING_LIGHT_SUBPIXEL` for consistent glyph quality across all font sizes

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
  adi-animation.ad[bs] - Style transition animation and interpolation
  adi-sdl-*.ad[bs]    - SDL3 bindings (core, video, render, events, mouse, ttf, image, surface)
tests/
  src/                - Test programs
    styles.adb        - Style system test
    layout_test.adb   - Flexbox layout unit test
  tests.gpr           - Test project file (uses TEST_KIND scenario)
examples/
  label_example.adb   - Label widget example with styling
  widget_demo.adb     - Widget demo with background image
  button_example.adb  - Button states, callbacks, and option groups
  transition_example.adb - Transition/easing showcase
  text_input_example.adb - Text input widget demo
  demo_flex.adb       - Flexbox layout demo
  stack_example.adb   - Stack container with tab switching
  list_box_example.adb - List box selection/scrolling demo
  css/                - CSS sources for generated example styles
  generated/          - Auto-generated Ada style packages from CSS
  examples.gpr        - Example project file (uses EXAMPLE_KIND scenario)
tools/
  css_to_ada.py       - Python tool to generate Ada style code from CSS
  generate_example_styles.sh - Generates example style packages before examples build
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
- `Adi.Widget.Box`, `Adi.Widget.Label`, `Adi.Widget.Text_Input`, `Adi.Widget.List_Box`, `Adi.Widget.Stack` - Concrete widgets
- `Adi.Widget.Part_Styles` - Multi-part style builder
- `Adi.Text_Buffer` - Shared text editing model
- `Adi.Animation` - CSS-like style transitions and interpolation
- `Adi.Event` - Event types
- `Adi.Font` - Font loading and caching
- `Adi.Image` - Image resource management
- `Adi.Layout_Util` - Layout algorithms
- `Adi.Render` - Per-renderer context and caches
- `Adi.Window` - Window management
- `Adi.App` - Application entry point
- `Adi.SDL.*` - SDL3 bindings (core, Video, Render, Events, Mouse, TTF, Image, Surface, PixelFormat)

### Naming Patterns
- Types: `Widget`, `Rectangle`, `Color_Value`
- Access types: `Widget_Access`, `Window_Access`
- Functions returning accessors: `Create`, `Get_*`
- Procedures for mutation: `Set_*`, `Add_*`, `Remove_*`

## CSS Style Generation

The `tools/css_to_ada.py` tool converts CSS files to Ada code using the library's style API:

```bash
python tools/css_to_ada.py input.css output.ads --package-name=My_Styles
```

This generates Ada package specifications with style constants that can be applied to widgets.

Selector conventions:
- `.widget` applies to `Main_Part`
- `.widget::label`, `.widget::cursor`, `.widget::selected`, etc. target specific parts
- Generated packages include both per-style `*_Widget` constants and grouped `*_Part_Styles` arrays for convenient `Set_Part_Styles` calls

### Supported CSS Properties

The tool supports a comprehensive set of CSS properties including:

- **Box model**: `width`, `height`, `min-width`, `max-width`, `min-height`, `max-height`, `padding`, `margin`
- **Borders**: `border`, `border-width`, `border-color`, `border-style`, `border-radius`
- **Colors**: `color`, `background-color` (named colors, hex, rgb, rgba)
- **Typography**: `font-size`, `font-weight`, `font-style`, `text-align`, `vertical-align`, `text-decoration`, `line-height`, `white-space`, `text-overflow`, `text-wrap-mode`
- **Layout**: `display`, `position`, `overflow`, `visibility`, `opacity`
- **Flexbox**: `flex-direction`, `flex-wrap`, `justify-content`, `align-items`, `align-self`, `align-content`, `gap`, `flex-grow`, `flex-shrink`, `flex-basis`, `order`
- **Effects**: `box-shadow` (with offset, blur, spread, and color), `cursor`
- **Images**: `object-fit`, `object-position`
- **Transitions**: `transition` (duration, easing, property filter)

### Box Shadow Syntax

The `box-shadow` property follows standard CSS syntax:

```css
.card {
  box-shadow: 2px 4px 10px rgba(0, 0, 0, 0.25);
  /* offset-x offset-y blur-radius [spread-radius] [color] */
}

.elevated {
  box-shadow: 0 8px 16px 0 rgba(0, 0, 0, 0.15);
}

.no-shadow {
  box-shadow: none;
}
```

Generates Ada code like:

```ada
Card_Base_Style : constant Style_Rules := (
   Box_Shadow => Set (Shadow (Px (2.0), Px (4.0), Px (10.0), Px (0.0),
                              RGBA (0, 0, 0, 0.25))),
   others => <>
);
```

## Library Build Configuration

The library can be built as:
- Static library (default): `LIBRARY_TYPE=static`
- Shared library: `LIBRARY_TYPE=relocatable`
- Position-independent static: `LIBRARY_TYPE=static-pic`

Set via environment variable or GPR external:
```bash
gprbuild -P adi.gpr -XADI_LIBRARY_TYPE=relocatable
```


### Git
Never add co-authored-by: line on commit messages
