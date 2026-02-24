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

**Adi.Image** (`adi-image.ads`): Image resource with surface-based loading and lazy GPU texture creation.
- Raster images are loaded as `SDL_Surface` (CPU memory) via `IMG_Load` — no renderer required at load time
- GPU textures are created lazily per renderer on first `Get_Texture(Renderer)` call, cached by renderer pointer for multi-window support
- SVG images store the parsed document and rasterize on demand per `(renderer, size)` tuple
- `Load_From_File(Path)`: loads raster as surface, SVG as parsed document — no renderer parameter
- `Load_SVG_From_String(Source)`: loads SVG markup directly into an image resource
- `Load_SVG_Path(Path_Data, Size, ...)`: builds an SVG image from a single path string
- `Get_Texture(Img, Renderer)`: returns cached texture or creates one from the surface for that renderer
- `Get_Texture_For_Size(Img, Renderer, W, H)`: for SVG, rasterizes and caches per `(renderer, width, height)`
- `Release_Textures_For_Renderer(Img, Renderer)`: evicts and destroys all cached textures for a specific renderer from one image
- `Release_All_Textures_For_Renderer(Renderer)`: global — iterates all live images via an internal registry and evicts textures for that renderer; called automatically by `Adi.Window.Finalize` before destroying the renderer
- `Free(Img)`: destroys internals, unregisters from the live image registry, and deallocates the `Image_Access` object; safe to call with null
- All constructors register the returned `Image_Access` in a package-body-level live image set; `Destroy`/`Free` unregister

**Adi.Assets** (`adi-assets.ads`): Global cached asset loader with scheme-based URI routing.
- Module-level API (like `Adi.Font`) — no instance type, no Window/Renderer dependency
- `Add_Path(Path, Scheme, Flatten)`: register a search directory; if `Scheme` is non-empty (e.g. `"app"`), the directory is only searched for `scheme://path` URIs; empty scheme directories handle plain relative paths. When `Flatten => True`, assets are looked up by basename only — the root of the directory is tried first, then subdirectories are walked depth-first until a matching filename is found
- `Remove_Path(Path, Scheme, Flatten)`: remove a previously registered search directory (must match all three fields)
- `Clear_Paths`: remove all search directories
- `Get_String(Path)`: resolve and read file contents as a string, cached by path
- `Get_Image(Path)`: resolve and load image via `Adi.Image.Load_From_File` (surface-based, no renderer needed), cached by path
- `Get_Animated_Image(Path)`: resolve and load animated image via `Adi.Animated_Image.Load_From_File` (surface-based, no renderer needed), cached by path; returns `Animated_Image_Access`
- `Clear_Cache` / `Clear_String_Cache` / `Clear_Image_Cache` / `Clear_Animated_Image_Cache`: drop cached entries, destroy and deallocate objects; previously returned access values become invalid
- `Invalidate(Path)`: remove one entry from all caches, freeing associated objects
- URI parsing: `"app://icons/star.svg"` splits into scheme `"app"` + relative `"icons/star.svg"`; plain paths search default directories
- Path sanitization: rejects `..` traversal, normalizes backslashes, strips leading slashes
- Directories searched in insertion order; first match wins
- CSS `background-image: url(...)` resolves through this module — widgets call `Get_Image(URI)` in `Build_Items`

**Adi.SVG** (`src/svg/adi-svg.ads`): SVG loading/raster API used by `Adi.Image` and HTML image flows.
- Compile-time backend selection via `-XADI_SVG_BACKEND=<plutosvg|ada>`
- `plutosvg` backend (default) lives in `src/svg/plutosvg` and uses vendored C libraries under `vendor/plutosvg/`
- `ada` backend lives in `src/svg/ada` (native parser/rasterizer)
- Shared public API surface: `Load_From_File`, `Load_From_String`, `Get_Size`, `Render_ARGB32`, `Destroy`, `Backend_Name`

**Adi.SVG_Sprites** (`adi-svg_sprites.ads`): SVG sprite sheet loader for icon fonts (e.g. FontAwesome).
- Parses `<symbol>` elements from SVG sprite files, keyed by `id`
- `Load` / `Load_From_String` parse and store all symbols
- `Get_Image` extracts a symbol as a standalone SVG `Image_Access`
- `Has_Symbol` / `Symbol_Count` for querying available icons

**Adi.Animated_Image** (`adi-animated_image.ads`): Multi-frame animation via `IMG_LoadAnimation`, per-frame delay, playback controls.
- `Load_From_File(Path)`: loads all frames as surfaces (via `SDL_DuplicateSurface` + `Create_From_Surface`) — no renderer required at load time; GPU textures created lazily per frame on first render
- Loadable through `Adi.Assets.Get_Animated_Image` for URI-based cached access

**Adi.RLottie** (`adi-rlottie.ads`): Lottie JSON via rlottie C API, CPU-rendered frame cache with background preload task. No renderer required at load time; surfaces are wrapped in `Image_Access` on first display and GPU textures created lazily per frame.

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
- Grid track sizing: `Grid_Track_List` carries per-column `auto`/`fr`/`px` specs (up to 16 tracks). `Compute_Grid_Layout` implements a 5-pass algorithm: (1) size `auto` columns to max child preferred width, (2) assign initial widths from track specs (`px` fixed, `fr` = 0), (3) distribute remaining space to `fr` columns, (4) expand columns/rows for `min-width`/`min-height` (skips `fr` columns — their floor is 0), (5) re-distribute `fr` columns after Pass 4 may have grown `auto`/`px` columns. Rows use an analogous 2-pass scheme: Pass 4 expands to content minimums, then remaining height is shared equally. When `overflow: visible` and rows overflow the allocated height (e.g. after text-wrap discovery), the grid container grows to fit.
- `fr` measurement in `Measure_Content` (`Adi.Widget.Box`): `fr` columns contribute their children's intrinsic **minimum** width (not the full preferred width) to the grid's content size. This follows CSS `minmax(auto, Xfr)` semantics — the grid allocates enough room for `fr` content at its minimum, while keeping `fr` columns shrinkable so text wraps when the container is constrained. `auto` columns still contribute their full preferred width.
- DIP scaling: `Set/Get_Active_DIP_Scale`; `Length_To_Px` scales `dip` by active value

**Adi.Window** (`adi-window.ads`): Window management.
- Wraps SDL window/renderer, owns `Render_Context`
- `Set_Root`, `Add_Overlay`, `Remove_Overlay` accept `access Adi.Widget.Widget'Class`
- Overlay hit testing prioritized above root; overlays render after root
- Widget part tracking for hover/press; scrollbar hit routing prefers nearest scrollable ancestor
- Tab focus traversal (wraps, Shift+Tab reverse); overlay-scoped when overlays present
- Click dispatch on left button release only
- DIP scale refresh from `SDL_GetWindowDisplayScale`
- **Layout-driven SDL minimum size**: `Set_Enforce_Layout_Min_Size` (default on) calls `SDL_SetWindowMinimumSize` from root layout sizing and reapplies it after each relayout pass (including resize-triggered relayouts), keeping SDL minimums synchronized with wrapped/unwrapped content changes. Minimum width uses a geometry-dependent guard: when preferred width tracks the current root geometry (typical wrapped-text feedback), width falls back to `Get_Min_Size(root)` to avoid ratcheting to the current window width. Minimum height follows preferred height so unwrap on widen can lower the enforced floor. Computed minimums are capped to display usable bounds via `SDL_GetDisplayUsableBounds`, and if current window size is already below the computed minimum, `SDL_SetWindowSize` clamps up immediately.
- Debug: `ADI_DEBUG_LOOP=1` for tick/render diagnostics

**Adi.App** (`adi-app.ads`): Application entry point, main loop, frame timing (`Ada.Real_Time`), `Set_Target_FPS`.

## Widgets

**Adi.Widget** (`adi-widget.ads`): Base abstraction.
- Part system: `Main_Part`, `Indicator_Part`, `Label_Part`, `Icon_Part`, `Cursor_Part`, `Selected_Part`, `Scroll_Part`, `Knob_Part`
- Item system: `Panel_Item`, `Text_Item`, `Image_Item`
- Flags: `Clickable`, `Focusable`, `Scrollable`, `Draggable`, `Visible`
- Visibility model:
  - Hard hide (no layout/render/input): `Visible=False` or main-part `display:none`
  - Soft hide (layout kept, paint/input suppressed): `visibility:hidden|collapse`
  - `visibility` follows CSS-style inheritance during tree traversal (descendant `visibility:visible` can override hidden ancestor)
  - Part-scoped `display:none` removes that part from internal part layout/rendering; part-scoped `visibility:hidden` keeps layout slot but does not paint
- Inherited disabled: `Is_Disabled` returns True when any ancestor has `State_Disabled`; `Get_States` injects the inherited flag so CSS `:disabled` styles apply to descendants; `Set_Disabled` bumps `Style_Version` and marks all descendants dirty so `Apply_Styles_To_Items` re-resolves inherited disabled styles immediately
- Abstract: `Build_Items`, `Layout`; Concrete: `Render_Items`, `Render_Tree`, `Update_And_Render`
- Size calculation: `Measure_Content` (dispatching) returns preferred content size; `Get_Min_Size` (dispatching) returns minimum size floor — base returns CSS `min-width`/`min-height`, Label overrides to return `max(CSS_min, intrinsic_text_min)`; `Get_Preferred_Size` (`Widget'Class`) returns CSS `width`/`height` or falls back to `Measure_Content`, except auto-width with `overflow-x: auto|scroll` uses the min-width + chrome floor, and auto-height with scrolling enabled (`overflow-y: auto|scroll` or internal `Scrollable` flag) uses the min-height + chrome floor
- Shared overflow scrolling with scrollbar parts — scroll offset applied at render time via `Render_Context.Scroll_Y`, not by shifting child geometries; hit-testing reverses the offset
- Context menu hook with ancestor bubbling
- Per-part transitions; `Tick_Animations` advances each frame — layout-affecting properties (`padding`, `margin`, `border-width`, `font-size`) trigger relayout; visual-only properties trigger repaint only
- Style-aware state invalidation with relevance masks: `Widget_Style` tracks which `Widget_State` values appear in any rule selector; `Set_State`/`Set_Part_State` skip style recomputation for states no rule references
- Style versioning: `Style_Version` counter incremented on state/style changes; `Apply_Styles_To_Items` skips work when version unchanged and no animations active
- `On_Tick(DT)` per-frame hook
- Image rendering: `object-fit` modes (Fill, Cover, Contain, None, Scale_Down), rounded clipping
- Label icon sizing honors `Icon_Part` `width`/`height` styles in both measurement and layout

**Text_Input**: Single-line editor using `Text_Buffer`. Horizontal scroll, caret, selection, context menu. Double-click word select, triple-click select all.

**Text_Editor**: Multiline editor using `Text_Buffer` + `Text_Layout`. Vertical scrollbar, visual-row navigation, word/line selection.

**List_Box** (generic over row widget): Selection modes (None/Single/Multi/Range), anchor-based range, inertial scrolling, style-driven scrollbar.
- **Grid layout mode**: CSS `grid-template-columns` activates grid layout (e.g., `repeat(3, 1fr)` for 3 columns). Gap between rows/columns comes from CSS `gap`/`row-gap`/`column-gap`. Layout uses `Compute_Grid_Layout` from `Adi.Layout_Util`.
- **Grid keyboard navigation**: Left/Right arrows move between columns (±1 item), Up/Down move between rows (±N items). PageUp/PageDown jump by visible-rows × columns. Home/End go to first/last item.
- **Grid hit-testing**: Click detection uses cached cell rectangles (both X and Y), so clicks map correctly to grid cells. Cell positions are computed during layout and cached in `Cell_Rects` for O(N) lookup.
- **Scrolling**: Vertical scrolling works in both modes. `Ensure_Row_Visible` uses cached cell positions to scroll the correct row into view.
- **Preferred height policy**: With auto height, preferred height is bounded by min-height + chrome floor (not total row content height), since list-box scrolling is internal.

**Combo_Box**: Dropdown using Main/Label/Indicator parts + List_Box overlay popup.

**Dialog**: Modal overlay with backdrop, title/message/buttons, dismiss policies, button presets.

**Stack** (generic over `Page_Id` enum): One visible child at a time, type-safe page switching, binds to `Button.Options`.
- Measurement/min-size is derived from participating pages (visible + `display != none`), so inactive pages do not inflate preferred/min size.

**Slider** (generic over numeric type): Draggable track+knob control. Core implementation in `Slider_Impl` (generic with `private` type + formal functions), thin wrappers `Slider` (`digits <>`) and `Integer_Slider` (`range <>`). Uses Main/Indicator/Knob parts. Supports horizontal/vertical orientation, step snapping, keyboard (arrows/Home/End) and mouse wheel input. All event handlers guard against `Is_Disabled`. CSS `:disabled` rules must target each part (`::main`, `::indicator`, `::knob`) since opacity is not inherited across parts.

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

Render scheduling note: relayout runs only when layout/geometry is dirty (`Mark_Dirty`); pure visual updates (state changes, scroll-offset, visual-only animations) use `Mark_Render_Dirty` for repaint without forcing full tree relayout.

**Debug stats overlay**: `Set_Debug_Stats(True)` enables a 2-line HUD showing frame number, FPS, per-stage timing (Update/Layout/Draw/Present in microseconds), layout count, layout trigger reason, style cache hit ratio (`S:hits/total`), layout call/skip counts (`LC:calls+skips`), and preferred-size cache ratio (`P:hits/total`). Renders only when the scene is already being redrawn — does not force extra frames.

### Layout Performance Optimizations

Three optimizations reduce layout cost for large widget trees (e.g. 280+ widgets in list_box_example):

**Resolved style cache** (`Get_Resolved_Part_Style`): Each widget caches its resolved style per part, keyed on `(Style_Version, Get_States(W), Part_States(P))`. Using `Get_States` (not raw `W.States`) ensures inherited `:disabled` state is included. When the widget-level key changes (version or effective states), ALL per-part cache entries are invalidated — this prevents sub-parts that inherit from Main_Part from returning stale results. Cache writes use `'Unrestricted_Access` on the read-only `Widget'Class` parameter (safe because the cache is a pure memo).

**Epoch-based layout deduplication** (`Layout_Tree` / `Layout_Child`): A global `Current_Layout_Epoch` counter increments once per `Layout_Tree` call via `Bump_Layout_Epoch`. The public `Layout_Tree` bumps the epoch then delegates to a private `Layout_Tree_Impl` for recursive descent — this ensures every external call (root, overlay, or dialog subtree) gets a fresh epoch while recursive children share the same epoch for dedup. Containers (flex, grid, list_box, stack) call `Layout_Child(Child)` instead of bare `Layout(Child)` — this stamps `Child.Last_Layout_Epoch := Current_Layout_Epoch`. When `Layout_Tree_Impl` later recurses into those children, it skips the redundant `Layout` call if the epoch matches. `Bump_Layout_Epoch` wraps to 1 (not 0) at `Natural'Last` to avoid matching the default `Last_Layout_Epoch := 0` init value. This eliminates ~50% of layout calls in container-heavy trees.

**Preferred size cache** (`Get_Preferred_Size`): Each widget caches its computed preferred size, keyed on `(Current_Layout_Epoch, Style_Version, Content_Version, Get_States(W), Geometry.Width, Geometry.Height)`. The cache is pass-scoped (valid within one layout epoch) and mutation-keyed (invalidated by style changes, content changes, state changes, or geometry changes). `Content_Version` is a per-widget counter bumped by `Mark_Dirty` (which is called by `Set_Text`, `Add_Child`, etc.) — it detects content mutations that don't affect `Style_Version`. `Cached_Pref_Epoch` is initialized to `Natural'Last` to prevent false hits before the first `Layout_Tree` call. Achieves ~56% hit rate in list_box_example (280+ widgets).

**Version bump helpers**: `Bump_Style_Version`, `Bump_Layout_Epoch`, and `Bump_Content_Version` are private auxiliary procedures that handle `Natural'Last` wraparound consistently. Layout epoch and content version wrap to 1 (not 0) to avoid matching default init values.

**Performance counters**: `Reset_Perf_Counters` / `Get_Perf_*` functions in `Adi.Widget` track style resolves, cache hits, layout calls, layout skips, preferred-size calls, and preferred-size cache hits per frame. Counters are reset before `Update` so that all work (including `Build_Items`) is captured. The Window captures these after each layout pass for the debug stats overlay.

## SDL Bindings

Hand-crafted Ada bindings in `adi-sdl*.ads`:
- `Adi.SDL` (core, clipboard), `.Video`, `.Render`, `.Events`, `.Mouse`, `.TTF`, `.TTF.TextEngine`, `.Image`, `.Surface`, `.PixelFormat`
- Native Ada types, incomplete types for opaque C structs, proper enumerations
- Not SDLAda (which is commented out in `adi.gpr`)
