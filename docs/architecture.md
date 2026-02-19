# Architecture

## Core Components

**Adi.Core** (`adi-core.ads`): Foundational types — geometric primitives (`Point`, `Size_2D`, `Rectangle`, `Pixel_Type`), color types (`Color` 0.0-1.0, `Color_8` 0-255), input enums (`Mouse_Button`).

**Adi.Style** (`adi-style.ads`): CSS-like style system — dimension values (px, dip, %, fr), box model, flexbox, grid layout, typography, color constants, widget states, style rule management.

**Adi.CSS_Styles** (`adi-css_styles.ads`): CSS value types and style resolution.
- Length units: `Px`, `Dip`, `Em`, `Root_Em`, `Pct`
- `Style_Rules`: optional/unset values for CSS cascade/override semantics
- `Resolved_Style`: fully concrete with defaults (safe to read directly)
- `Transition_Spec` with duration, easing, and `Property_Set` filter
- `Animatable_Property` enum for targeting specific lerpable fields
- `Normalize_Color` helper for extracting RGBA from any `Color_Value` variant

**Adi.CSS_Parser** (`adi-css_parser.ads`): Runtime CSS loader/parser.
- Loads stylesheets from strings/files into `Part_Style_Array` maps
- Selector kinds: class (`.x`), id (`#x`), tag (`button`)
- Comma-separated selector groups are supported (for example `li, ul, p { ... }`)
- Public APIs: `Has/Styles_For/Apply/Bind` + `_Class`/`_Id`/`_Tag` convenience wrappers
- File watching reload: `Reload_If_Changed`, reapplying to bound widgets
- Parses `transition` with duration (`ms`/`s`), easing, property filter
- `dp` accepted as alias of `dip`

**Adi.CSS_Source** (`adi-css_source.ads`): Dynamic/static style source switcher.
- `Dynamic_Mode`: file-backed, optional auto-reload
- `Static_Mode`: compiled constant style entries
- In `Static_Mode`, repeated entries for the same selector are merged in insertion order
- Single selector bind/apply (`class`, `id`, `tag`) and composite selector-set bind/apply
- `Bind_Class` accepts space-separated class names; styles are merged left-to-right
- Public `Merge_Part_Styles` for combining `Part_Style_Array` values outside the binding system
- Composite specificity: tag < class < id

**Adi.Widget_Styles** (`adi-widget_styles.ads`): Widget state-based styling.
- States: Normal, Hovered, Pressed, Focused, Disabled, Selected
- Disabled is **inherited**: `Is_Disabled` walks the parent chain, so disabling a container disables all descendants for both interaction and styling
- Style builder pattern (fluent API)
- Widget-state vs part-state scopes (`When_State`/`When_Not` vs `When_Part_State`/`When_Part_Not`)
- `With_Transition(Duration, [Properties], [Easing])`

**Adi.Widget.Part_Styles** (`adi-widget-part_styles.ads`): Multi-part style builder.
- Fluent API for per-part styles (Main, Label, Icon, Indicator, etc.)
- Predefined templates: Button, Checkbox, Scrollbar, Input, List, Slider
- No built-in visual theme — apps provide explicit styles

**Adi.Event** (`adi-event.ads`): Discriminant-based event record with mouse/keyboard data.

**Adi.Render** (`adi-render.ads`): Per-renderer context and caches.
- `Render_Context`: bundles `SDL_Renderer_Ptr` with shadow texture cache and TTF text engine
- Shadow cache: shape-based `Shadow_Key` (blur + corner radius), color applied via texture modulation
- Owned by `Adi.Window`; threaded through render calls

**Adi.Animation** (`adi-animation.ads`): CSS-like style transitions.
- `Part_Transition`: per-widget-part animation state
- `Advance`/`Interpolate`: field-by-field lerp between `Resolved_Style` values
- Easing: Linear, Ease_In (cubic), Ease_Out, Ease_In_Out
- Property filtering: only properties in `Transition_Spec.Properties` are interpolated

**Adi.Image** (`adi-image.ads`): SDL texture wrapper with file/memory SVG loading.
- `Load_SVG_From_String` loads SVG markup directly into an image resource.
- `Load_SVG_Path` builds an SVG image from a single path string using typed Ada values:
  `Size_2D`, `Color_8` fill/stroke, and `Pixel_Type` stroke width.

**Adi.SVG** (`src/svg/adi-svg.ads`): SVG loading/raster API used by `Adi.Image` and HTML image flows.
- Compile-time backend selection via `-XADI_SVG_BACKEND=<plutosvg|ada>`
- `plutosvg` backend (default) lives in `src/svg/plutosvg` and uses vendored C libraries under `plutosvg/`
- `ada` backend lives in `src/svg/ada` (native parser/rasterizer)
- Shared public API surface: `Load_From_File`, `Load_From_String`, `Get_Size`, `Render_ARGB32`, `Destroy`, `Backend_Name`

**Adi.SVG_Sprites** (`adi-svg_sprites.ads`): SVG sprite sheet loader for icon fonts (e.g. FontAwesome).
- Parses `<symbol>` elements from SVG sprite files, keyed by `id`
- `Load` / `Load_From_String` parse and store all symbols
- `Get_Image` extracts a symbol as a standalone SVG `Image_Access`
- `Has_Symbol` / `Symbol_Count` for querying available icons

**Adi.Animated_Image** (`adi-animated_image.ads`): Multi-frame animation via `IMG_LoadAnimation`, per-frame delay, playback controls.

**Adi.RLottie** (`adi-rlottie.ads`): Lottie JSON via rlottie C API, CPU-rendered frame cache with background preload task, streaming SDL texture upload.

**Adi.Log** (`adi-log.ads`): Central runtime logging.
- Safe logging entry points: `Write`, `Debug`, `Info`, `Warning`, `Error`
- Windows behavior: writes to `debug.log` (append/create), avoids GUI-crash risk from missing console handles
- Non-Windows behavior: writes to standard output
- Library runtime modules use this instead of direct `Ada.Text_IO.Put_Line`

**Adi.Font** (`adi-font.ads`): Font loading and caching.
- `Font_Handle` = font family (file path)
- `Font_Attributes` groups family/size/weight/style/decoration
- Sized `TTF_Font` instances cached per `(handle, size)` pair
- Variant-aware cache with `Register_Variant` and fallback probing
- Platform font paths selected via `Adi.Build_Target.Is_Windows`

**Adi.Text_Buffer** (`adi-text_buffer.ads`): Shared text editing core.
- Line-oriented storage, caret with line/column, selection
- UTF-8 aware navigation and editing
- Undo/redo (200-entry cap), clipboard integration

**Adi.Text_Layout** (`adi-text_layout.ads`): Visual-row layout for text widgets.
- Converts logical lines to visual rows with style-aware wrapping
- Caret/point mapping helpers, column-to-pixel offset

**Adi.Layout_Util** (`adi-layout_util.ads`): Layout algorithms.
- Box model, edge/border extraction, alignment
- Flexbox and grid layout (`Compute_Grid_Layout` / `Grid_To_Rectangles`)
- DIP scaling: `Set/Get_Active_DIP_Scale`; `Length_To_Px` scales `dip` by active value

**Adi.Window** (`adi-window.ads`): Window management.
- Wraps SDL window/renderer, owns `Render_Context`
- `Set_Root`, `Add_Overlay`, `Remove_Overlay` accept `access Adi.Widget.Widget'Class`
- Overlay hit testing prioritized above root; overlays render after root
- Widget part tracking for hover/press; scrollbar hit routing prefers nearest scrollable ancestor
- Tab focus traversal (wraps, Shift+Tab reverse); overlay-scoped when overlays present
- Click dispatch on left button release only
- DIP scale refresh from `SDL_GetWindowDisplayScale`
- Debug: `ADI_DEBUG_LOOP=1` for tick/render diagnostics

**Adi.App** (`adi-app.ads`): Application entry point, main loop, frame timing (`Ada.Real_Time`), `Set_Target_FPS`.

## Widgets

**Adi.Widget** (`adi-widget.ads`): Base abstraction.
- Part system: `Main_Part`, `Indicator_Part`, `Label_Part`, `Icon_Part`, `Cursor_Part`, `Selected_Part`, `Scroll_Part`, `Knob_Part`
- Item system: `Panel_Item`, `Text_Item`, `Image_Item`
- Flags: `Clickable`, `Focusable`, `Scrollable`, `Draggable`, `Visible`
- Inherited disabled: `Is_Disabled` returns True when any ancestor has `State_Disabled`; `Get_States` injects the inherited flag so CSS `:disabled` styles apply to descendants; `Set_Disabled` marks all descendants dirty for re-styling
- Abstract: `Build_Items`, `Layout`; Concrete: `Render_Items`, `Render_Tree`, `Update_And_Render`
- Shared overflow scrolling with scrollbar parts
- Context menu hook with ancestor bubbling
- Per-part transitions; `Tick_Animations` advances each frame
- Style-aware state invalidation (dirty only when resolved output changes)
- `On_Tick(DT)` per-frame hook
- Image rendering: `object-fit` modes (Fill, Cover, Contain, None, Scale_Down), rounded clipping
- Label icon sizing honors `Icon_Part` `width`/`height` styles in both measurement and layout

**Text_Input**: Single-line editor using `Text_Buffer`. Horizontal scroll, caret, selection, context menu. Double-click word select, triple-click select all.

**Text_Editor**: Multiline editor using `Text_Buffer` + `Text_Layout`. Vertical scrollbar, visual-row navigation, word/line selection.

**List_Box** (generic over row widget): Selection modes (None/Single/Multi/Range), anchor-based range, inertial scrolling, style-driven scrollbar.

**Combo_Box**: Dropdown using Main/Label/Indicator parts + List_Box overlay popup.

**Dialog**: Modal overlay with backdrop, title/message/buttons, dismiss policies, button presets.

**Stack** (generic over `Page_Id` enum): One visible child at a time, type-safe page switching, binds to `Button.Options`.

**Slider** (generic over numeric type): Draggable track+knob control. Core implementation in `Slider_Impl` (generic with `private` type + formal functions), thin wrappers `Slider` (`digits <>`) and `Integer_Slider` (`range <>`). Uses Main/Indicator/Knob parts. Supports horizontal/vertical orientation, step snapping, keyboard (arrows/Home/End) and mouse wheel input.

**Value_Input** (generic over numeric type, derives from `Text_Input`): Numeric text field with input filtering, clamping, and formatting. Core in `Value_Input_Impl`, wrappers `Value_Input` (`digits <>`) and `Integer_Value_Input` (`range <>`). Filters non-numeric keystrokes, parses on Enter/focus-lost, supports Up/Down/PageUp/PageDown stepping and mouse wheel.

**Animated_Widget**: Unified animated image/Lottie display. Child package `RLottie` isolates rlottie coupling.

**Html_View**: Documentation-oriented HTML widget (`Adi.Widget.Html_View`).
- Internal parse model uses `Element`/`Text`/`Break` nodes with permissive malformed HTML recovery
- Per-element cascade is deterministic: `defaults < tag < class < id < inline`
- Line-box layout keeps ascent/descent/baseline local to each line to avoid cross-block metric leakage
- Line finalization applies `text-align` (including `<center>` default centering)
- Block flow applies per-element margin/padding in the html layout pass
- Optional content scale API (`Set/Get_Content_Scale`) scales absolute/content units without changing `%`/`vw`/`vh` fit semantics
- Html `vw`/`vh` resolve against the html content viewport (normal widget `vw`/`vh` resolve against SDL window size)
- Hyperlink interaction via `Set_On_Link_Click` with clipping-aware hit regions from final laid-out runs
- Resource loading is callback-driven: `Set_On_Load_Asset` for `img`, `Set_On_Load_Resource` for linked stylesheets
- Embedded `<style>` and callback-loaded `<link rel="stylesheet">` are parsed with `Adi.CSS_Parser`
- Standard inline SVG blocks are supported (`<svg ...><path .../></svg>`) and rendered as inline image items
- Block elements emit styled panel items, so element `background`/`border` styles are visible in Html_View output

**Context_Menu** / **Text_Context_Menu**: Popup overlay menu; shared factory for Undo/Redo/Cut/Copy/Paste/Select All.

## Widget Rendering Pipeline

1. **Build**: `Build_Items` creates `Item` records
2. **Style**: Each item either resolves from `Part_Kind` via widget states or uses an explicit per-item style override
3. **Layout**: Calculate geometry for widget and children
4. **Render**: Draw items via `Render_Context`
   - Rounded borders: annulus ring + background fill
   - Non-rounded: per-edge fills (asymmetric widths/colors supported)
   - Overflow clipping follows CSS (`visible` = no clip, `hidden/scroll/auto` = clip)
   - For clipped containers, descendants are skipped when the effective clip region is non-positive
   - Text positions snapped to integer pixels
   - Font hinting: `TTF_HINTING_LIGHT_SUBPIXEL`
   - Temporary decoration workaround: `underline`/`line-through`/`overline` are drawn manually in `Adi.Widget` to avoid SDL_ttf renderer text-engine white-line color behavior; upstream patch draft is stored in `deps/issues/`

Render scheduling note: relayout runs only when layout/geometry is dirty; pure visual updates (for example scroll-offset changes) trigger repaint without forcing full tree relayout.

## SDL Bindings

Hand-crafted Ada bindings in `adi-sdl*.ads`:
- `Adi.SDL` (core, clipboard), `.Video`, `.Render`, `.Events`, `.Mouse`, `.TTF`, `.TTF.TextEngine`, `.Image`, `.Surface`, `.PixelFormat`
- Native Ada types, incomplete types for opaque C structs, proper enumerations
- Not SDLAda (which is commented out in `adi.gpr`)
