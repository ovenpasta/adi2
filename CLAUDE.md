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
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=css_parser_test
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=css_source_test
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=text_buffer_test
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=text_layout_test
```

### Building specific examples
```bash
# Build a specific example by setting EXAMPLE_KIND scenario variable
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=label_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=widget_demo
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=button_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=transition_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=text_input_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=text_editor_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=demo_flex
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=stack_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=list_box_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=combo_box_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=overflow_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=grid_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=dialog_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=font_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=runtime_css_example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=animated_image_example
```

### Running tests
```bash
# Tests are built to tests/bin/
./tests/bin/styles
./tests/bin/layout_test
./tests/bin/css_parser_test
./tests/bin/css_source_test
./tests/bin/text_buffer_test
./tests/bin/text_layout_test
```

### Running examples
```bash
# Examples are built to examples/bin/
./examples/bin/label_example
./examples/bin/widget_demo
./examples/bin/button_example
./examples/bin/transition_example
./examples/bin/text_input_example
./examples/bin/text_editor_example
./examples/bin/demo_flex
./examples/bin/stack_example
./examples/bin/list_box_example
./examples/bin/combo_box_example
./examples/bin/overflow_example
./examples/bin/grid_example
./examples/bin/dialog_example
./examples/bin/font_example
./examples/bin/runtime_css_example
./examples/bin/animated_image_example
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
- `Style_Rules` carries optional/unset values for CSS cascade/override semantics; `Resolved_Style` is fully concrete with defaults (safe to read directly)
- Border, padding, margin, background properties
- Box shadow with blur, spread, offset, and color
- Comprehensive style properties matching CSS box model
- Transition support: `Transition_Spec` with duration, easing, and property filter
- `Animatable_Property` enum and `Property_Set` for targeting specific properties
- `Normalize_Color` helper for extracting RGBA from any `Color_Value` variant

**Adi.CSS_Parser** (`adi-css_parser.ads`): Runtime CSS loader/parser
- Loads stylesheet text from strings/files into `Part_Style_Array` maps
- Supports selector kinds: class (`.x`), id (`#x`), and tag (`button`)
- Public lookup/apply APIs are selector-kind aware (`Has/Styles_For/Apply/Bind` + class/id/tag convenience wrappers)
- Supports file watching reload flow via `Reload_If_Changed`, reapplying styles to bound widgets
- Parses `transition` with duration (`ms`/`s`), easing, and property filter

**Adi.CSS_Source** (`adi-css_source.ads`): Dynamic/static style source switcher
- Unifies runtime dynamic CSS (`Adi.CSS_Parser`) and compiled static style arrays
- Runtime mode switch: `Dynamic_Mode` (file-backed, optional auto-reload) or `Static_Mode` (compiled constants)
- Supports single selector bind/apply (`class`, `id`, `tag`) and composite selector-set bind/apply
- Composite selector set applies CSS-like specificity order: `tag < class < id`
- Designed for dev/release workflows: dynamic reload while developing, static-only styles in release

**Adi.Widget_Styles** (`adi-widget_styles.ads`): Widget state-based styling
- State-specific styles: `Normal`, `Hovered`, `Pressed`, `Focused`, `Disabled`, `Selected`
- Style builder pattern for fluent API
- Resolves CSS styles to final computed values
- Selector scopes: widget-state and part-state are distinct (`When_State`/`When_Not` vs `When_Part_State`/`When_Part_Not`)
- `With_Transition(Duration, [Properties], [Easing])`: sets transition on base style

**Adi.Widget.Part_Styles** (`adi-widget-part_styles.ads`): Multi-part widget style builder
- Fluent API for composing per-part styles (Main, Label, Icon, Indicator, etc.)
- State-dependent styling per part
- Predefined templates for part enable/disable composition (Button, Checkbox, Scrollbar, Input, List, Slider)
- No built-in visual theme defaults in the library; applications/examples provide explicit styles (typically via generated CSS packages)

**Adi.Event** (`adi-event.ads`): Event system
- Discriminant-based event record with `Mouse_Move` event kind
- Timestamp and mouse position/speed data

**Adi.Render** (`adi-render.ads`): Per-renderer context and caches
- `Render_Context`: Bundles an `SDL_Renderer_Ptr` with its per-renderer caches (shadow textures, TTF text engine)
- Shadow texture cache with `Shadow_Key` lookup and bounded eviction (max 256 entries)
- `Shadow_Key` is shape-based (`blur + corner radius`); shadow color/alpha is applied via texture modulation at draw time
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

**Adi.Animated_Image** (`adi-animated_image.ads`): Animated image resource management
- Loads multi-frame animations via `SDL3_image` (`IMG_LoadAnimation`)
- Converts decoded frames to SDL textures (`Image_Access` per frame)
- Playback controls: `Start`, `Stop`, `Reset`, `Set_Looping`, `Advance`
- Uses per-frame delay metadata from source animation (`delays[]` in milliseconds)

**Adi.Widget** (`adi-widget.ads`): Base widget abstraction
- `Add_Child`/`Remove_Child` accept `access Widget'Class` (no `Widget_Access` cast needed at call sites)
- Abstract tagged type with hierarchy management (parent/children)
- **Part system**: Widgets are composed of styleable parts (`Main_Part`, `Indicator_Part`, `Label_Part`, etc.)
- **Item system**: Renderable primitives (`Panel_Item`, `Text_Item`, `Image_Item`) that compose a widget
- Each part has its own `Widget_Style` that resolves based on widget states
- Widget flags: `Clickable`, `Focusable`, `Scrollable`, `Draggable`, `Visible`
- Generic context-menu hook for any widget: `Set_On_Context_Menu` with ancestor bubbling via `Bubble_Context_Menu` (menu UI/styling is app-defined)
- Shared vertical overflow scrolling for any widget:
  - `overflow: auto|scroll` (or `Scrollable` flag) enables wheel/drag scrolling
  - Shared scrollbar parts (`Scroll_Part`/`Knob_Part`) are rendered by base `Render_Tree`
  - Knob hit-testing uses a small slop margin to avoid accidental track page-jumps on near-knob clicks
  - Shared helpers: `Set/Get_Scroll_Offset_Y`, `Get_Scroll_Content_Height`, `Get_Scroll_Max_Offset_Y`
  - Shared input/tick hooks: `Handle_Scroll_Mouse_*`, `Tick_Scroll_Animations`
- Dirty tracking for efficient updates
- Abstract methods: `Build_Items` (construct renderable items), `Layout` (calculate geometry)
- Concrete rendering: `Render_Items`, `Render_Tree`, `Update_And_Render` (take `Render_Context`)
- Image rendering: `Render_Rounded_Image` clips textures to rounded rects via UV-mapped triangle fans
- `object-fit` modes: `Fill`, `Cover` (UV cropping), `Contain`, `None`, `Scale_Down`
- Contain/None/Scale_Down adjust corner radii based on image inset from container edges
- Per-corner border radius: `Render_Rounded_Rect` overload accepts `Corner_Pixels`
- Default geometry initializes to `(0, 0, 0, 0)` (no synthetic default size)
- Non-rounded panel border rendering supports per-edge widths/colors/styles (e.g. horizontal-only separators)
- Label text wrapping honors both `text-wrap-mode` and `white-space` (`white-space: nowrap` prevents wrapping)
- Text rendering applies `font-weight`, `font-style`, and `text-decoration` (`underline`/`line-through`); `overline` is parsed but intentionally not rendered yet
- **Animation**: Per-part `Part_Transition_Array` tracks active transitions; `Tick_Animations` advances them each frame; `Apply_Styles_To_Items` starts transitions when resolved style targets change
- State invalidation is style-aware: widget/part state changes only mark dirty when resolved style output actually changes (prevents unnecessary rerenders for no-op hover/focus changes)
- **Per-frame hook**: `On_Tick(DT)` (default null) runs from `Tick_Animations` for widget-specific time-based behavior (e.g. inertial scrolling)

**Adi.Text_Buffer** (`adi-text_buffer.ads`): Shared text editing core
- Line-oriented text storage for editing widgets
- Caret model with line/column positions
- Selection support and editing/navigation operations (`Insert_Text`, `Delete_Backward`, `Move_Left`, etc.)
- Reusable foundation for single-line and multiline text editors
- UTF-8 aware caret movement/editing: left/right/delete/backspace operate on character boundaries (not raw bytes)
- Selection introspection API: `Get_Selection_Range`, `Get_Selected_Text`
- Extended navigation: `Move_Page_Up`, `Move_Page_Down`, `Move_To_Start`, `Move_To_End`
- Undo/redo history with snapshot restore of text, caret, and selection (`Undo`, `Redo`, `Can_Undo`, `Can_Redo`)
- History is capped (200 edits) and redo history is invalidated by new edits after undo
- Clipboard edit commands live in the buffer: `Copy_Selection_To_Clipboard`, `Cut_Selection_To_Clipboard`, `Paste_From_Clipboard([Single_Line])`

**Adi.Text_Layout** (`adi-text_layout.ads`): Visual-row layout helper for text widgets
- Converts logical buffer lines into visual rows using style-aware wrapping (`white-space`, `text-wrap-mode`, viewport width)
- UTF-8-safe row slicing and row text extraction
- Caret/point mapping helpers: position -> row index, row+x -> position, point -> position
- Column-to-pixel helper (`X_Offset_For_Column`) used for caret/selection geometry in wrapped editors

**Adi.Widget.Text_Input** (`adi-widget-text_input.ads`): Single-line text input widget
- Uses `Adi.Text_Buffer` for text/caret/selection state
- Supports keyboard navigation/editing (arrows, home/end, backspace/delete, select-all, undo/redo)
- Clipboard support is delegated to `Adi.Text_Buffer` APIs (single-line paste strips LF/CR)
- Undo/redo shortcuts: Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z
- Shared text context menu support: `Attach_Window` wires a factory-built menu with Undo/Redo/Cut/Copy/Paste/Select All
- Menu visuals are app-supplied via `Set_Context_Menu_Part_Styles` and `Set_Context_Menu_Item_Part_Styles`
- Receives `On_Key_Down`, `On_Key_Up`, and `On_Text_Input` through window focus dispatch
- Renders a styled caret via `Cursor_Part`
- Renders selection highlight via `Selected_Part`
- Mouse hit-testing uses SDL_ttf measurement (`TTF_MeasureString`) for UTF-8-safe caret/selection placement
- Click behavior: single click places caret, double click selects word, triple click selects all text
- Long single-line content does not wrap; it scrolls horizontally to keep the caret visible
- Text rendering uses a fixed clip region (input content box) with a text X offset for horizontal scrolling
- Selection highlight is clamped to content bounds (no overflow outside the widget)
- Dragging selection left of the widget clamps to the start of text (column 0)
- Double-click word selection is deferred until mouse-up; moving past a small threshold converts to normal drag selection
- Empty text still shows caret with proper line-height fallback metrics (caret no longer disappears)
- `Create` sets `Clickable` and `Focusable` so caret placement/selection works with mouse routing
- `Create` does not apply built-in styles; examples/apps define `Main/Label/Cursor/Selected` part styles explicitly

**Adi.Widget.Text_Editor** (`adi-widget-text_editor.ads`): Multiline plain-text editor widget
- Uses `Adi.Text_Buffer` for multiline text storage, caret, and selection state
- Supports full keyboard navigation: arrows, Home/End, Ctrl+Home/End, Page Up/Down, Shift+arrows for selection, Ctrl+A select-all
- Clipboard support is delegated to `Adi.Text_Buffer` APIs (multiline paste preserved)
- Undo/redo shortcuts: Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z
- Shared text context menu support: `Attach_Window` wires a factory-built menu with Undo/Redo/Cut/Copy/Paste/Select All
- Menu visuals are app-supplied via `Set_Context_Menu_Part_Styles` and `Set_Context_Menu_Item_Part_Styles`
- Enter inserts newline, Tab inserts spaces, Backspace/Delete work across lines
- Uses `Adi.Text_Layout` to render per-visible visual rows (supports wrapped text without widget-level wrap math)
- Selection highlights are per-visible-line `Selected_Part` panels, dynamically sized
- Caret rendered via `Cursor_Part`, hidden when not focused or offscreen
- In wrap mode, `Up/Down/PageUp/PageDown` move by visual rows while preserving preferred caret X
- Shared vertical scrollbar via `Scroll_Part`/`Knob_Part` (reuses base overflow-scroll system)
- Widget manages its own `Scroll_Content_H` (not derived from children); `Update_Shared_Scroll_Layout` skips content-height override when widget has no children
- Mouse interaction: click places caret, drag selects, double-click selects word, triple-click selects line
- Mouse wheel scrolls, scrollbar drag supported
- `Create` sets `Clickable`, `Focusable`, `Scrollable` flags
- Parts used: `Main_Part` (background), `Label_Part` (text), `Cursor_Part` (caret), `Selected_Part` (selection), `Scroll_Part`/`Knob_Part` (scrollbar)

**Adi.Widget.Context_Menu** (`adi-widget-context_menu.ads`): Generic popup context menu overlay
- Reusable overlay popup menu with dismiss layer and row callbacks
- No theme defaults required; applications can inject menu and row part styles

**Adi.Widget.Text_Context_Menu** (`adi-widget-text_context_menu.ads`): Shared text-menu factory
- Builds the standard text menu once (`Undo/Redo/Cut/Copy/Paste/Select All`)
- Binds menu commands to any `Adi.Text_Buffer` (`Single_Line` mode supported)
- Binds right-click request handling to any widget via `Bind_Widget_Request`

**Adi.Widget.List_Box** (`adi-widget-list_box.ads`): Generic list container widget
- Generic over row widget type (`Row_Widget` / `Row_Widget_Access`)
- Manages rows, row heights, row gaps, and vertical scrolling with wheel + keyboard navigation
- Selection modes: `No_Selection`, `Single_Selection`, `Multi_Selection`, `Range_Selection`
- Supports anchor-based range selection (`Shift+Click` / `Shift+Arrow`); `Multi_Selection` also supports toggle (`Ctrl+Click`)
- Reuses base shared overflow-scroll logic (scrollbar rendering, drag, wheel momentum, pressed-state launch effect)
- Scrollbar geometry is style-driven from `::scroll`/`::knob` CSS (`width`, `margin`, `padding`, `min-height`)
- Supports part-scoped selectors for scrollbars (e.g. `list::scroll:hover`, `list::knob:pressed`) distinct from widget-scoped selectors (e.g. `list:hover::scroll`)
- Hovering the knob also highlights the track (knob-hover propagates to `Scroll_Part`)
- Inertial scrolling: wheel/drag input feeds velocity with friction-based decay for momentum
- Launch effect: high scroll velocity/active drag sets scrollbar parts to pressed state for stronger visual feedback
- Focusable + scrollable by default, participates in Tab focus traversal
- Selection APIs: `Select_Row`, `Toggle_Row_Selected`, `Clear_Selection`, `Get_Selected_Count`
- Callbacks: `On_Item_Clicked`, `On_Item_Activated`, `On_Selection_Changed`

**Adi.Widget.Combo_Box** (`adi-widget-combo_box.ads`): Select/dropdown widget built from reusable parts
- Main control uses `Main/Label/Indicator` parts and popup content is a `List_Box` overlay
- Popup close behavior supports outside click dismissal via a transparent dismiss overlay behind the list
- Keyboard interaction supports `Up/Down`, `Return`, and `Escape`
- Row widgets are `Label`s so row visuals reuse existing part-style APIs
- Popup height is style-driven from CSS (`min-height`/`max-height`) plus row preferred heights, gaps, padding, and border
- APIs include item management, selection callbacks, popup open/close, and per-part style injection for dropdown/rows

**Adi.Widget.Dialog** (`adi-widget-dialog.ads`): Modal dialog/alert widget
- Single overlay widget: renders a full-window semi-transparent backdrop (`Main_Part` panel) with a centered content panel
- Content panel is a `Box_Widget` child containing title label, message label, and button row (flex row)
- Buttons are internal `Dialog_Button_Widget` (extends `Button_Widget`) that forward Escape key to parent dialog
- Dismiss policies: `Set_Dismiss_On_Backdrop` and `Set_Dismiss_On_Escape` (both default `True`)
- Button presets: `Set_OK_Button`, `Set_OK_Cancel`, `Set_Yes_No`, `Set_Yes_No_Cancel`
- Result callback: `Dialog_Result_Callback` receives button index (1-based) and text; index 0 means dismissed
- Style injection: `Set_Panel_Style`, `Set_Title_Style`, `Set_Message_Style`, `Set_Button_Row_Style`, `Set_Button_Style`
- Layout handled in `Build_Items` (overlays bypass `Layout_Tree`): measures content, clamps to min/max width from panel style, centers in window
- `Show`/`Hide` add/remove self as window overlay via `Attach_Window` host

**Adi.Widget.Stack** (`adi-widget-stack.ads`): Generic stack container widget
- Generic over `Page_Id` discrete type (typically an enum)
- Shows one child at a time; pages keyed by `Page_Id`
- `Add_Page(Id, Page)`: accepts `access Widget'Class`; registers a page; first page added auto-activates
- `Set_Active(Id)`: hides old page, shows new, fires callback
- `Get_Page(Id)`: returns page widget (null if never added)
- All children receive full layout so page switching is instant
- Rendering/hit-testing of hidden pages excluded via `Visible` flag checks in `Render_Tree` and `Find_Widget_At`
- Single item: `Panel_Item` (Main_Part) background
- Type-safe binding with `Button.Options`: instantiate both over the same enum, wire `On_Changed` to `Set_Active`
- Internally stores `array (Page_Id) of Widget_Access` — enum is the key, no index tracking

**Adi.Widget.Animated_Image** (`adi-widget-animated_image.ads`): Animated image display widget
- Renders animated frames through `Icon_Part` (image) and `Main_Part` (container)
- Supports widget-level playback controls: `Start`, `Stop`, `Reset`, loop toggle
- `On_Tick` advances animation by delta time and marks dirty only when frame changes
- Can load from file directly (`Load_From_File`) or consume preloaded `Animated_Image_Access`

**Adi.Layout_Util** (`adi-layout_util.ads`): Layout algorithms
- Box model calculations: `Content_Box`, `Padding_Box`
- Edge/border pixel extraction
- Alignment utilities (horizontal/vertical)
- Floating panel helper: `Clamp_And_Center` clamps preferred size to min/max and centers within a container
- Flexbox layout support (child margins are applied on main/cross axes)
- Grid layout support with reusable core algorithm (`Compute_Grid_Layout` / `Grid_To_Rectangles`)
- Named root font-size default is used for `em/root-em` conversions (no hardcoded magic font-size literals)

**Adi.Window** (`adi-window.ads`): Window management
- Wraps SDL window and renderer
- Owns a `Render_Context` for per-renderer caches
- Root widget container
- `Set_Root`, `Add_Overlay`, `Remove_Overlay` accept `access Adi.Widget.Widget'Class` (fully qualified to avoid package/type ambiguity)
- Mouse event handling with widget hit testing
- Overlay support for top-level floating widgets (`Add_Overlay`, `Remove_Overlay`, `Clear_Overlays`, `Overlay_Count`)
- Overlay hit testing is prioritized above the root tree; overlays render after root content
- During render, overlays are laid out/updated before `Render_Tree`; this keeps popup widgets (e.g. combo dropdown list scrollbars) in sync with current geometry/content
- Right-click routes context-menu requests from the hit widget upward through ancestors (`Bubble_Context_Menu`)
- Tracks hovered/pressed widget part; updates part states on pointer movement so part-scoped selectors resolve correctly
- Scrollbar hit routing prefers the nearest ancestor widget whose part-at-point is `Scroll_Part`/`Knob_Part`, so scrollbar hover/press/drag works even when deepest child under cursor is not scrollable/clickable
- Keyboard focus handling with Tab traversal across focusable/visible widgets (Shift+Tab reverse, wraps around)
- When overlays are present, keyboard traversal/routing is scoped to the topmost visible overlay (e.g. dialog buttons receive Tab navigation and Escape reaches dialog dismiss handlers)
- Forwards both key-down and key-up events to the focused widget
- Click activation (`On_Click`) is dispatched on left mouse button release (right-click no longer triggers click callbacks)
- `Tick(DT)`: advances animations on the widget tree each frame
- Optional loop diagnostics: set `ADI_DEBUG_LOOP=1` to log tick dirty transitions and render/relayout triggers
- Optional minimum-size policy can enforce window min size from layout (`Set_Enforce_Layout_Min_Size`, `Apply_Window_Min_Size_From_Layout`)
- Window resize/reshape handling
- Image convenience loaders: `Load_Image` and `Load_Animated_Image`

**Adi.App** (`adi-app.ads`): Application entry point
- Initialization and main loop
- Window management
- Frame rate management: `Set_Target_FPS`, `Get_Delta_Time`
- Proper frame timing with `Ada.Real_Time` (`delay until`) instead of fixed delay
- Event loop dispatches mouse, key-down, key-up, and text-input events to `Adi.Window`
- Each frame: compute delta time, tick animations, render, wait for next frame

### Widget Rendering Pipeline

1. **Build Phase**: `Build_Items` creates renderable `Item` records for each visual element
2. **Style Resolution**: Each item references a `Part_Kind`, which has a `Widget_Style` that resolves to `Resolved_Style` based on current widget states
3. **Layout Phase**: `Layout` calculates geometry for widget and children
4. **Render Phase**: `Render_Items` draws each item using its computed style, geometry, and a `Render_Context` (which holds the renderer, shadow cache, and text engine)
   - Rounded borders always use `Render_Rounded_Border_Ring` (annulus) + separate background fill
   - Non-rounded borders render per-edge fills (supports asymmetric border widths/colors/styles)
   - Overflow clipping follows CSS overflow (`visible` does not clip, `hidden/scroll/auto` clip) and applies to descendants; widget own background/border render before clip
   - **Text positions are snapped to integer pixels** (`Float'Floor`) before drawing to prevent sub-pixel blurring from texture interpolation
   - Font hinting uses `TTF_HINTING_LIGHT_SUBPIXEL` for consistent glyph quality across all font sizes

### SDL Integration

The library provides Ada bindings for SDL3 in `adi-sdl*.ads` files:
- `Adi.SDL`: Core SDL types, initialization, clipboard (`SDL_SetClipboardText`, `SDL_GetClipboardText`, `SDL_free`)
- `Adi.SDL.Video`: Window management bindings
- `Adi.SDL.Render`: Renderer bindings
- `Adi.SDL.Events`: Event handling bindings
- `Adi.SDL.Mouse`: Mouse input bindings
- `Adi.SDL.TTF`: TrueType font rendering bindings (SDL3_ttf)
- `Adi.SDL.TTF.TextEngine`: Advanced text layout and rendering callbacks (SDL3_ttf)
- `Adi.SDL.Image`: Image file loading/saving bindings (SDL3_image)
- `Adi.SDL.Surface`: Low-level pixel buffer and surface bindings
- `Adi.SDL.PixelFormat`: Pixel format constant enumerations

Recent binding additions:
- `Adi.SDL`: `SDL_SetClipboardText`, `SDL_GetClipboardText`, `SDL_free`
- `Adi.SDL.Video`: `SDL_SetWindowMinimumSize`
- `Adi.SDL.Events`: `SDL_SCANCODE_ESCAPE`, `SDL_SCANCODE_SPACE`, `SDL_SCANCODE_Y`, `SDL_SCANCODE_Z`

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
  adi-text_layout.ad[bs] - Shared visual-row text layout/mapping helpers
  adi-widget-*.ad[bs] - Widget implementations (Box, Label)
  adi-widget-combo_box.ad[bs] - Combo box widget with overlay popup list
  adi-widget-context_menu.ad[bs] - Generic context menu popup overlay
  adi-widget-text_context_menu.ad[bs] - Factory/binding for text-buffer context menus
  adi-widget-text_editor.ad[bs] - Multiline plain-text editor widget
  adi-widget-dialog.ad[bs] - Modal dialog/alert widget with overlay backdrop
  adi-animation.ad[bs] - Style transition animation and interpolation
  adi-sdl-*.ad[bs]    - SDL3 bindings (core, video, render, events, mouse, ttf, image, surface)
tests/
  src/                - Test programs
    styles.adb        - Style system test
    layout_test.adb   - Flexbox layout unit test
    css_parser_test.adb - Runtime CSS parser test coverage (selectors, properties, reload, malformed input)
    css_source_test.adb - CSS source mode/specificity test coverage (dynamic/static + tag/class/id precedence)
    text_buffer_test.adb - Text buffer undo/redo edge-case coverage
    text_layout_test.adb - Text layout row mapping and wrap-mode behavior coverage
  tests.gpr           - Test project file (uses TEST_KIND scenario)
examples/
  label_example.adb   - Label widget example with styling
  widget_demo.adb     - Widget demo with background image
  button_example.adb  - Button states, callbacks, and option groups
  transition_example.adb - Transition/easing showcase
  text_input_example.adb - Text input widget demo
  text_editor_example.adb - Multiline text editor demo with scrolling and selection
  animated_image_example.adb - Animated image widget demo with start/stop/reset/loop controls
  demo_flex.adb       - Flexbox layout demo
  stack_example.adb   - Stack container with tab switching
  list_box_example.adb - List box selection/scrolling demo
  combo_box_example.adb - Combo box example with styled popup/list interactions
  overflow_example.adb - Overflow demo with 3 rows: block overflow, horizontal text overflow, and wrapped-text vertical overflow (`visible` vs `hidden`)
  grid_example.adb     - CSS grid layout demo with rows/columns and spans
  dialog_example.adb   - Modal dialog/alert demo with alert and confirm dialogs
  font_example.adb     - Typography demo for weight/style/decoration and wrapping
  runtime_css_example.adb - Runtime CSS demo using `Adi.CSS_Source` with button toggle between dynamic and static sources
  css/widget_defaults.css - Shared default visual styles used by multiple examples
  css/runtime_css_example.css - Runtime stylesheet used by runtime_css_example
  css/text_editor_example.css - Text editor widget styles
  css/animated_image_example.css - Animated image example styles
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
- `Adi.Widget.Box`, `Adi.Widget.Label`, `Adi.Widget.Text_Input`, `Adi.Widget.Text_Editor`, `Adi.Widget.List_Box`, `Adi.Widget.Stack`, `Adi.Widget.Combo_Box`, `Adi.Widget.Dialog`, `Adi.Widget.Button.Switch` - Concrete widgets
- `Adi.Widget.Animated_Image` - Animated image display widget
- `Adi.Widget.Context_Menu` - Generic context menu overlay widget
- `Adi.Widget.Text_Context_Menu` - Shared factory for buffer-backed text context menus
- `Adi.Widget.Part_Styles` - Multi-part style builder
- `Adi.Text_Buffer` - Shared text editing model
- `Adi.Text_Layout` - Visual-row text layout/mapping abstraction for wrapped editing
- `Adi.Animation` - CSS-like style transitions and interpolation
- `Adi.Event` - Event types
- `Adi.Font` - Font loading and caching
  - `Font_Attributes` record groups family/size/weight/style/decoration
  - Variant-aware font cache and `Register_Variant` API
  - Fallback font variant probing for Linux-style suffixes (`Regular`, `Medium`, `Light`, `Thin`, `Black`, `Bold`, with italic/oblique combinations)
- `Adi.Image` - Image resource management
- `Adi.Animated_Image` - Animated image resource management
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

### Widget API Conventions
- **Hierarchy calls use `access Widget'Class`**: `Add_Child`, `Remove_Child`, `Set_Root`, `Add_Overlay`, `Remove_Overlay`, `Add_Page` all accept anonymous access parameters so callers don't need `Widget_Access(...)` casts
- **Dot notation in examples**: `Root.Add_Child (Label1)` instead of `Add_Child (Root.all, Widget_Access (Label1))`
- **Implementation detail for hierarchy storage**: when converting anonymous access params to stored `Widget_Access` inside internals (children/overlay lists), use `C.all'Unchecked_Access` on the designated object rather than `Widget_Access (C)` to avoid runtime accessibility `PROGRAM_ERROR` checks
- **Callbacks use named access types**: e.g. `Click_Callback`, `Toggle_Callback`, `Change_Callback` — Ada accessibility rules (RM 3.10.2) prevent using anonymous access-to-subprogram in record fields
- **`'Unrestricted_Access` for callbacks in examples**: callbacks declared inside `main` have deeper accessibility than library-level named access types, so `'Access` won't compile; `'Unrestricted_Access` (GNAT extension) is required

## CSS Style Generation

The `tools/css_to_ada.py` tool converts CSS files to Ada code using the library's style API:

```bash
python tools/css_to_ada.py input.css output.ads --package-name=My_Styles
```

This generates Ada package specifications with style constants that can be applied to widgets.
Example style generation via `tools/generate_example_styles.sh` is incremental: files are regenerated only when the source CSS or generator script changed.

Selector conventions:
- `.widget` applies to `Main_Part`
- `.widget::label`, `.widget::cursor`, `.widget::selected`, etc. target specific parts
- Generated packages include selector-type distinction in constants:
  - `*_Class_Part_Styles`
  - `*_Id_Part_Styles`
  - `*_Tag_Part_Styles`
  (plus per-style `*_Widget` constants)

## Runtime CSS Parser

`Adi.CSS_Parser` provides runtime stylesheet loading from strings/files, with optional file-change reload and rebinding.

Selector API conventions:
- Class selector API: `Has_Class`, `Styles_For_Class`, `Apply_Class`, `Bind_Class`
- Id selector API: `Has_Id`, `Styles_For_Id`, `Apply_Id`, `Bind_Id`
- Tag selector API: `Has_Tag`, `Styles_For_Tag`, `Apply_Tag`, `Bind_Tag`
- Generic selector API: `Has/Styles_For/Apply/Bind` with `Selector_Kind`

State selector behavior matches generator semantics:
- Pseudo before `::part` => widget-scoped state
- Pseudo after `::part` => part-scoped state for non-main parts

## Runtime CSS Source

`Adi.CSS_Source` is the higher-level entry point for applications that need both dev-time and release-time styling.

Mode behavior:
- `Dynamic_Mode`: load CSS from disk (`Set_Dynamic_File`) and optionally auto-reload with `Tick`
- `Static_Mode`: apply compiled style entries (`Set_Static_Entries`) generated by `css_to_ada.py`

Binding behavior:
- Single selector APIs: `Bind_Class`, `Bind_Id`, `Bind_Tag` (and corresponding `Apply_*`)
- Composite selector API: `Bind_Selector_Set` / `Apply_Selector_Set` with `Tag_Name`, `Class_Name`, `Id_Name`
- Composite precedence is CSS-like: tag styles merged first, then class, then id (id wins)

### Supported CSS Properties

The tool supports a comprehensive set of CSS properties including:

- **Box model**: `width`, `height`, `min-width`, `max-width`, `min-height`, `max-height`,
  `padding`, `margin`, `padding-top/right/bottom/left`, `margin-top/right/bottom/left`
- **Borders**: `border`, `border-width`, `border-color`, `border-style`, `border-radius`
- **Colors**: `color`, `background-color` (named colors, hex, rgb, rgba)
- **Typography**: `font-size`, `font-weight`, `font-style`, `text-align`, `vertical-align`, `text-decoration`, `line-height`, `white-space`, `text-overflow`, `text-wrap-mode`
- **Layout**: `display`, `position`, `overflow`, `visibility`, `opacity`
- **Flexbox**: `flex-direction`, `flex-wrap`, `justify-content`, `align-items`, `align-self`, `align-content`, `gap`, `flex-grow`, `flex-shrink`, `flex-basis`, `order`
- **Grid (first-pass)**: `grid-template-columns`, `grid-template-rows`, `grid-column`, `grid-row`
- **Effects**: `box-shadow` (with offset, blur, spread, and color), `cursor`
- **Images**: `object-fit`, `object-position`
- **Transitions**: `transition` (duration, easing, property filter)

Selector pseudo-class placement:
- Before `::part` => widget-scoped state (`.list:hover::scroll`)
- After `::part` => part-scoped interaction state for non-main parts (`.list::scroll:hover`, `.list::knob:pressed`)
- For `::main`, interactive pseudos remain widget-scoped (`.button::main:hover` behaves like button hover, not child-part hover)

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
