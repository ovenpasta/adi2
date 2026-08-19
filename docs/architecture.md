# Architecture

## Core Components

**Adi.Core** (`adi-core.ads`): Foundational types — geometric primitives (`Point`, `Size_2D`, `Rectangle`, `Pixel_Type`), color types (`Color` 0.0-1.0, `Color_8` 0-255), input enums (`Mouse_Button`).

**Adi.Style** (`adi-style.ads`): CSS-like style system — dimension values (px, dip, %, fr), box model, flexbox, grid layout, typography, color constants, widget states, style rule management.

**Adi.CSS_Styles** (`adi-css_styles.ads`): CSS value types and style resolution.
- Length units: `Px`, `Pix`, `Dip`, `Em`, `Root_Em`, `Pct`, `Vw`, `Vh` — `Pix` is one renderer pixel regardless of scale or the `px` → dip mapping
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
- `Attach_Window(Source, Window_Handle)`: associates a window with the source so CSS metadata is applied to it automatically on every load/reload. Currently propagates `:root { font-size }` → `Window.Set_Root_Font_Size`. Properties absent from the CSS leave the window unchanged (no reset to defaults).

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
- `Render_Context`: bundles `SDL_Renderer_Ptr` with the texture cache and TTF text engine
- Texture cache: reached through `Find_Texture`/`Store_Texture`/`Borrow_Texture`, never handed out — a reference to it could outlive `Destroy`. Budgeted at `Default_Texture_Budget` (64 MiB) of **idle** residency — what the cache retains for reuse, not what the scene may display. Per context and never per process: a texture belongs to the renderer that made it
- `Advance_Frame`: called by `Adi.Window` once per frame that is actually drawn, so idle ticks do not age entries
- Owned by `Adi.Window`; threaded through render calls
- Budget and residency are reachable from a window via `Set_Texture_Budget` and `Get_Texture_Stats`, which reports per-kind active/idle/retired bytes; compare `idle_bytes` against the budget, not total residency

**Adi.Texture_Cache** (`adi-texture_cache.ads`): GPU textures under a byte budget.
- Budget is bytes, not entries: a blurred shadow runs from under 2 KB to several MB
- Eviction ranks by rebuilding time per byte held; build time is measured by the caller, never guessed
- Standings sit on a floor that rises to whatever was last evicted, so entries lose ground as the cache works rather than as the clock runs
- Callers keep generational `Texture_Handle`s; the SDL pointer is reachable only inside a scoped `Borrow`, which pins the entry against eviction mid-draw
- Eviction takes only **idle** entries — unborrowed and undrawn for more than one frame. A texture the scene is using is never reclaimed: taking it would rebuild it next frame having freed nothing. Total residency therefore exceeds the budget by the working set
- Box shadows are keyed `(Shadow_Texture, blur, corner radius)` — colour and offset are applied at draw time, so one texture serves every tint. Charged `Tex_Size²×4`; `Adi.Widget` times the whole build (mask, surface, upload, mode calls) and passes it as `Build_Time`

**Adi.Animation** (`adi-animation.ads`): CSS-like style transitions.
- `Part_Transition`: per-widget-part animation state
- `Advance`/`Interpolate`: field-by-field lerp between `Resolved_Style` values
- Easing: Linear, Ease_In (cubic), Ease_Out, Ease_In_Out
- Property filtering: only properties in `Transition_Spec.Properties` are interpolated

**Adi.Image** (`adi-image.ads`): Image resource with surface-based loading and lazy GPU texture creation.
- Raster images are loaded as `SDL_Surface` (CPU memory) via `IMG_Load` — no renderer required at load time
- GPU textures are created lazily on first lease and held by the render context's texture cache, so two windows keep two sets
- SVG images store the parsed document and rasterize on demand per `(renderer, size)` tuple
- `Load_From_File(Path)`: loads raster as surface, SVG as parsed document — no renderer parameter
- `Load_SVG_From_String(Source)`: loads SVG markup directly into an image resource
- `Load_SVG_Path(Path_Data, Size, ...)`: builds an SVG image from a single path string
- `Create_From_Surface(Surface)`: wraps an existing `SDL_Surface` — used by raster crop in `Adi.Assets`
- `Get_Surface(Img)`: returns the underlying `SDL_Surface_Ptr` (null for SVG images)
- `Acquire_Texture(Img, Ctx, W, H)`: leases a texture from the context's `Adi.Texture_Cache`, rasterizing or uploading one if none is held. The SDL pointer is reachable only through the returned `Texture_Ref` and only while it lives; the lease pins the entry against eviction and outlives the image with its texture intact; it may outlive the context only as readable bookkeeping with a null texture, since the renderer goes with the context
- `Image_Scale_Mode`: `Scale_Linear` (default bilinear), `Scale_Nearest` (sharp nearest-neighbor), `Scale_Pixelart` (nearest with integer snap, SDL 3.3+)
- `Set_Scale_Mode(Img, Mode)` / `Get_Scale_Mode(Img)`: per-image texture scaling; the mode is part of a texture's key, so a later lease finds or builds one made for it
- `Set_Tintable(Img)` / `Is_Tintable(Img)`: mark/query tintable flag (white-on-transparent, recolored by CSS `color`)
- Freeing an **ungrouped** image leaves its entries resident until budget pressure or context destruction reclaims them. They keep the standing they earned; what changes is that nothing hits them again, so the rising floor overtakes them
- A **grouped** image's textures go when their owner releases the group, in every renderer that holds them, counted as `released` rather than as pressure. `Create_From_Surface` takes the group; the image holds it without owning it, so the group must outlive every image naming it
- Constructors return an `Image_Owner`; `To_Handle(O)` gives the weak `Image_Handle` everything else holds
- `Release(O)`: the last owner frees the image and retires its slot, so every handle to it goes stale at once. An owner also releases on leaving scope; one held in a container is released before it is removed
- Each constructor assigns a `Source_Id` from a counter rather than reusing the image's address, which a later allocation could repeat and so find a dead image's cache entries

**Adi.Assets** (`adi-assets.ads`): Global cached asset loader with scheme-based URI routing.
- Module-level API (like `Adi.Font`) — no instance type, no Window/Renderer dependency
- `Add_Path(Path, Scheme, Flatten)`: register a search directory; if `Scheme` is non-empty (e.g. `"app"`), the directory is only searched for `scheme://path` URIs; empty scheme directories handle plain relative paths. When `Flatten => True`, assets are looked up by basename only — the root of the directory is tried first, then subdirectories are walked depth-first until a matching filename is found
- `Remove_Path(Path, Scheme, Flatten)`: remove a previously registered search directory (must match all three fields)
- `Clear_Paths`: remove all search directories
- `Get_String(Path)`: resolve and read file contents as a string, cached by path
- `Get_Image(Path)`: resolve and load image, cached by path. Supports query-parameter syntax for sprite extraction and scaling:
  - `file.svg?id=name` — SVG sprite: loads/caches sprite sheet via `Adi.SVG_Sprites`, extracts `<symbol>` by id. Result is tintable by default
  - `file.png?x=N&y=N&w=N&h=N` — Raster crop: loads source image, blits rectangle into a new surface via `SDL_BlitSurface`. Coordinates clamped to source bounds
  - `?render=pixelated|nearest|linear` — Sets `Image_Scale_Mode` on the result. Combinable with sprite/crop params
  - Sprite sheets are cached separately by resolved filesystem path and shared across symbols
  - Plain paths without `?` follow the normal `Adi.Image.Load_From_File` path unchanged
- `Get_Animated_Image(Path)`: resolve and load animated image via `Adi.Animated_Image.Load_From_File` (surface-based, no renderer needed), cached by path; returns `Animation_Handle`
- `Clear_Cache` / `Clear_String_Cache` / `Clear_Image_Cache` / `Clear_Animated_Image_Cache`: drop cached entries and destroy what they held. Every handle previously returned goes stale, images and animations alike, so a widget still holding one draws nothing until it reacquires. Image cache clear also destroys sprite sheet cache
- `Invalidate(Path)`: remove one entry from all caches, releasing the owners they held. Handles returned for that path go stale. Also removes all derived `path?...` cache entries and the corresponding sprite sheet cache entry
- URI parsing: `"app://icons/star.svg"` splits into scheme `"app"` + relative `"icons/star.svg"`; plain paths search default directories. Query `?` splitting happens before scheme parsing, so `app://icons.svg?id=home` works correctly
- Path sanitization: rejects `..` traversal, normalizes backslashes, strips leading slashes
- Directories searched in insertion order; first match wins
- CSS `background-image: url(...)` resolves through this module — widgets call `Get_Image(URI)` in `Build_Items`

**Adi.SVG** (`src/svg/adi-svg.ads`): SVG loading/raster API used by `Adi.Image` and HTML image flows.
- Rendering backend lives in `src/svg/plutosvg` and uses the vendored plutosvg / plutovg C libraries under `vendor/plutosvg/`
- Public API surface: `Load_From_File`, `Load_From_String`, `Get_Size`, `Render_ARGB32`, `Destroy`, `Backend_Name`
- The SVG path parser (`src/svg/adi-svg-parser.ads`) is shared and also drives `Adi.SVG_Sprites`

**Adi.SVG_Sprites** (`adi-svg_sprites.ads`): SVG sprite sheet loader for icon fonts (e.g. FontAwesome).
- Parses `<symbol>` elements from SVG sprite files, keyed by `id`
- `Load` / `Load_From_String` parse and store all symbols
- `Get_Image` extracts a symbol as a standalone SVG `Image_Owner`
- `Has_Symbol` / `Symbol_Count` for querying available icons

**Adi.Animated_Image** (`adi-animated_image.ads`): Multi-frame animation via `IMG_LoadAnimation`, per-frame delay, playback controls.
- `Load_From_File(Path)`: loads all frames as surfaces (via `SDL_DuplicateSurface` + `Create_From_Surface`) — no renderer required at load time; GPU textures created lazily per frame on first render
- Callers hold a generational `Animation_Handle` from an `Adi.Handle_Store`; `Destroy` retires the slot, so every copy goes stale together. The raw type is private to the package and its children
- Every frame image joins the animation's `Texture_Group`, so destruction takes its textures out of each renderer that drew them rather than leaving them for eviction
- Playback samples an `Adi.Playback_Clock`, so several widgets drawing one animation advance the single playhead once per tick rather than once per viewer
- Loadable through `Adi.Assets.Get_Animated_Image` for URI-based cached access

**Adi.RLottie** (`adi-rlottie.ads`): Lottie JSON via the rlottie C API.
- Loading parses the model only. `Prepare (W, H)` records the size frames will be drawn at; each frame is rasterised when playback first reaches it and kept afterwards, so a loop pays for each frame once. A different extent replaces the frames once the request has stood still for 150 ms
- Every frame image joins its extent's `Texture_Group`, so replacing an extent takes that extent's textures out of every renderer rather than leaving them to be evicted under pressure
- Residency is per renderer but the group spans them: one animation drawn in two windows has frames in two caches, and releasing reaches both
- Callers hold a generational `Animation_Handle` from an `Adi.Handle_Store`; `Destroy` retires the slot, so every copy goes stale together. The raw `RLottie_Animation` is private to the package and its children
- Destroying it releases its frames, so a widget still naming one holds a stale handle and draws nothing. Runs on the render thread

**Adi.Log** (`adi-log.ads`): Central runtime logging.
- Safe logging entry points: `Write`, `Debug`, `Info`, `Warning`, `Error`
- All logging is a no-op in `release` and `validation` build profiles
- Windows/development: writes to `debug.log` (append/create), avoids GUI-crash risk from missing console handles
- Non-Windows/development: writes to standard output
- Library runtime modules use this instead of direct `Ada.Text_IO.Put_Line`

**Adi.Signal** (generic, `adi-signal.ads`): Multi-subscriber signal/slot mechanism.
- Generic over `Callback_Type` and `Null_Callback`
- `Connect` subscribes a handler, returns a `Connection_Id` for later disconnection
- `Connect_Unique` subscribes only if the same callback is not already active; returns existing ID on duplicate
- `Disconnect(Id)` tombstones a slot; trailing tombstones are compacted
- `Disconnect_All` clears all subscriptions
- `For_Each` generic iterates active subscribers; emit sites instantiate with a local visitor
- Emit-during-modify safe: `For_Each` snapshots length; connects during emit fire next emit; disconnects take effect immediately

**Adi.Dispatch** (`adi-dispatch.ads`): Thread-safe deferred execution queue.
- `Post(Proc)` queues a library-level procedure to run on the main thread next frame; thread-safe
- `Drain` executes all pending procs in FIFO order then clears; called by `Adi.App.Run` each frame
- Re-entrant safe: `Drain` swaps the queue before executing, so `Post` during `Drain` defers to next frame
- `Pending_Count` for diagnostics

**Adi.Handle_Store** (`adi-handle_store.ads`): Generic generational ownership store.
- `Object_Id` (`Index`, `Gen`) with slot `0` reserved as null
- `Register`, `Get`, `Is_Valid`, `Request_Destroy`, `Pump`
- `Pin`/`Unpin` plus `Borrow` (`Implicit_Dereference`) for scoped safe access
- `Set_Strict`/`Is_Strict`: strict-mode policy (default True). When enabled, `Get` raises `Program_Error` for non-null stale handles instead of returning null. `Null_Id` always returns null silently.
- Used by widgets, context menus, and windows (separate store instantiations)

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
- Grid track sizing: `Grid_Track_List` carries per-column `auto`/`fr`/`px`/`pix` specs (up to 16 tracks). `Compute_Grid_Layout` implements a 5-pass algorithm: (1) size `auto` columns to max child preferred width, (2) assign initial widths from track specs (`px` and `pix` fixed, `fr` = 0), (3) distribute remaining space to `fr` columns, (4) expand `auto`/`px`/`pix` columns and rows for `min-width`/`min-height`, and record a floor for each `fr` column from its items' minimum contribution, (5) re-distribute `fr` columns by flex factor, freezing any that fall below their floor and resharing among the rest until stable — the grid overflows when the floors alone exceed the space. Rows use an analogous 2-pass scheme: Pass 4 expands to content minimums, then remaining height is shared equally. When `overflow: visible` and rows overflow the allocated height (e.g. after text-wrap discovery), the grid container grows to fit.
- `fr` measurement in `Measure_Content` (`Adi.Widget.Box`): `fr` columns contribute their children's intrinsic **minimum** width to the grid's content size, so `fr` columns stay shrinkable and text wraps when the container is constrained. `auto` columns contribute their full preferred width. Known deviation: this also makes a grid whose only column is `fr` report the same preferred and min-content width — CSS would derive a common flex fraction from max-content contributions. See `docs/layout_minimums.md`.
- Low-level unit conversion state: `Length_To_Px` scales `dip` by OS DIP scale plus active user UI scale; `Font_Length_To_Px` also applies active text scale. App code should normally change user scaling through `Adi.Window`, not by mutating `Layout_Util` directly.

**Adi.Window** (`adi-window.ads`): Window management.
- Wraps SDL window/renderer, owns `Render_Context`
- Handle-first API:
  - `Create_Window_Handle`, `Window_Handle`, `Destroy`, `Is_Valid`, `Resolve_Window_Handle`
  - Backward-compatible `Create_Window`/`Window_Access` remains available
- `Set_Root`, `Add_Overlay`, `Remove_Overlay` accept both handles and anonymous access
- Overlay hit testing prioritized above root; overlays render after root
- Programmatic focus API: `Set_Focus(Window, Target)` sets focus to a widget in the window root/overlay trees (or clears focus with `null`), and ignores out-of-window targets
- Resize behavior: `Handle_Resize` marks both root and overlay trees dirty on size changes so overlay-driven widgets (for example dialogs) recompute geometry immediately on the next render pass, without waiting for hover/state events
- Widget part tracking for hover/press; scrollbar hit routing prefers nearest scrollable ancestor
- Tab focus traversal (wraps, Shift+Tab reverse); overlay-scoped when overlays present
- Click dispatch on left button release only
- Overlay focus cleanup: `Remove_Overlay` and `Clear_Overlays` clear focus when the focused widget belongs to removed overlays, preventing stale detached focus targets
- **Pixel coordinate space**: windows are created with `SDL_WINDOW_HIGH_PIXEL_DENSITY` and the renderer runs with `SDL_LOGICAL_PRESENTATION_DISABLED`, so `1` render unit = `1` physical pixel. `W.Size`, `W.Geometry`, `Get_Size`, `Actual_Size`, viewport size and mouse-event coordinates (after `SDL_ConvertEventToRenderCoordinates`) are all in physical pixels. The user-supplied `Size_2D` to `Create_Window_Handle` is what SDL receives as the window dimension (logical points on macOS, pixels elsewhere); after creation, `W.Size` is overwritten with `SDL_GetWindowSizeInPixels`.
- **Mouse coordinate space**: `On_Mouse_Down`, `On_Mouse_Move` and `On_Mouse_Up` receive points in **stored layout space** — the same space `Get_Geometry` reports, not zero-based widget-local coordinates. `Map_Window_Point_To_Widget` converts a window point by adding the scroll offset of every ancestor of the target (the target's own offset moves its children, not itself), so the delivered point falls inside the widget's stored rectangle however deeply it is scrolled. X passes through unchanged while horizontal scrolling is unsupported. Context-menu coordinates (`Bubble_Context_Menu`) stay in window space: they position an overlay, not content inside the widget. `tests/src/window_resize_safety_test.adb` pins the contract through two nested scroll containers.
- DIP scale refresh from `SDL_GetWindowDisplayScale`; `Active_DIP_Scale` is what the `dp`/`dip` length unit multiplies by, and is the only mechanism for density-independent sizing.
- App-facing scaling API: `Set_UI_Scale` and `Set_Text_Scale` update the active user scales and invalidate the window root plus overlays for relayout/redraw
- CSS-px-as-logical-px opt-in: `Adi.Layout_Util.Set_Px_Maps_To_Dip (True)` makes `Length_To_Px` route the `Px` branch through the same `Amount * Active_DIP_Scale * Active_UI_Scale` formula as `Dip`, so CSS `px` behaves like a browser/Qt logical pixel for the whole app. Off by default — both conventions are first-class; see `docs/css_styling.md` "Treating CSS `px` as logical pixels".
- Widget helper for pre-resolved lengths: `Adi.Layout_Util.Pixels_As_Length (P)` returns a `Dip`-valued `Length_Value` that re-resolves to exactly `P` pixels regardless of the toggle or current scales. Widgets that compute a final pixel size during measurement and need to pass it through a `Length_Value` field (e.g. `Item.Style_Override.Font_Size`) use this to avoid being scaled a second time at render.
- Window state API: `Maximize`, `Minimize`, `Restore`, `Set_Fullscreen` delegate directly to SDL3; `Is_Maximized`, `Is_Minimized`, `Is_Fullscreen` query the live SDL window flags. All have `Window` and `Window_Handle` overloads. SDL may not honor requests on all platforms.
- **Layout-driven SDL minimum size**: `Set_Enforce_Layout_Min_Size` (default on) calls `SDL_SetWindowMinimumSize` from root layout sizing and reapplies it after each relayout pass (including resize-triggered relayouts). Minimum **width** is `Effective_Min_Size (root)`: the smallest the content can be squeezed to, including an explicit `min-width` that exceeds the preferred width. Preferred width is the *max-content* width, at which wrapping content does not wrap. Minimum **height** is `Measure_At_Width (root, current width)` — the height the content needs at the width the window actually has, so unwrapping on widen lowers the floor again. Computed minimums are capped to display usable bounds via `SDL_GetDisplayUsableBounds`, and if the current window size is already below the computed minimum, `SDL_SetWindowSize` clamps up immediately.
- Deterministic teardown: widget trees are destroyed before SDL resources in `Finalize`; public `Destroy` invalidates window handles through the store.
- Callback-safe destroy: destroy requests made during active window callback dispatch are queued and applied by `Pump_Window_Store` after dispatch unwinds.
- Debug: `ADI_DEBUG_LOOP=1` for tick/render diagnostics

**Adi.App** (`adi-app.ads`): Application entry point, main loop, frame timing (`Adi.Clock`), `Set_Target_FPS`.

**Adi.Clock** (`adi-clock.ads`): Monotonic program clock (`Time`, `Time_Span`, `Now`, `Sleep_Until`) — the single seam between library timing and the platform. Native body wraps `Ada.Real_Time`; WASM builds substitute an SDL-ticks body (`wasm/PORT_REPORT.md`).
- Main window ownership is now `Window_Handle` (with access overload bridge in `Add_Window`).
- Per-frame store drain includes widget/menu/window stores.

## Widgets

**Adi.Widget** (`adi-widget.ads`): Base abstraction.
- Ownership is store-backed with generational `Widget_Handle`; typed handles wrap the same store IDs.
- Scoped borrow API: `Borrow (Widget_Handle) return Widget_Ref` (`Implicit_Dereference`) pins while in scope.
- `Resolve_Handle` remains as compatibility bridge; new code should prefer typed handles and/or `Borrow`.
- Migration direction is handle-first public APIs, with `Widget_Access` planned to move toward private/internal usage once compatibility bridges are no longer needed.
- Part system: `Main_Part`, `Indicator_Part`, `Label_Part`, `Text_Part`, `Icon_Part`, `Cursor_Part`, `Selected_Part`, `Scroll_Part`, `Knob_Part`
- Item system: `Panel_Item`, `Text_Item`, `Image_Item`
- Flags: `Clickable`, `Focusable`, `Scrollable`, `Draggable`, `Visible`. A separate private dispatching primitive, `Clips_Own_Content`, marks widgets that scroll their own content without being scroll containers — text inputs, and value inputs by inheritance. It clips only the parts the widget scrolls (`Text_Part`, `Cursor_Part`, `Selected_Part`) on both axes, so a floating `Label_Part` sitting above the border still draws. It is the equivalent of a browser's user-agent `overflow: hidden` on an input, and being private a stylesheet cannot switch it off.
- Visibility model:
  - Hard hide (no layout/render/input): `Visible=False` or main-part `display:none`
  - Soft hide (layout kept, paint/input suppressed): `visibility:hidden|collapse`
  - `visibility` follows CSS-style inheritance during tree traversal (descendant `visibility:visible` can override hidden ancestor)
  - Part-scoped `display:none` removes that part from internal part layout/rendering; part-scoped `visibility:hidden` keeps layout slot but does not paint
- Inherited disabled: `Is_Disabled` returns True when any ancestor has `State_Disabled`; `Get_States` injects the inherited flag so CSS `:disabled` styles apply to descendants; `Set_Disabled` bumps `Style_Version` and marks all descendants dirty so `Apply_Styles_To_Items` re-resolves inherited disabled styles immediately
- Abstract: `Build_Items`, `Layout`; Concrete: `Render_Items`, `Render_Tree`, `Update_And_Render`
- Size calculation: `Measure_Content` (dispatching) returns preferred content size; `Get_Min_Size` (dispatching) returns the minimum the widget *demands* — explicit CSS `min-width`/`min-height` only — while `Get_Content_Min_Size` (dispatching, default zero) reports how small its content can be squeezed. `Effective_Min_Size` combines them the way containers need: an explicit `min-width`/`min-height` *replaces* the automatic contribution rather than flooring it, so `min-width: 0` really does let an item shrink past its own content. Left automatic, the contribution is the content minimum, dropped to zero on an axis whose overflow is not `visible` (that axis shows its content a piece at a time, so it needs room for none of it) and otherwise capped by a definite declared size — CSS's specified size suggestion. A percentage caps only where a container size is known to resolve it against; the flex main axis passes one, `Effective_Min_Size` does not. `Adi.Widget.Box` and `Adi.Widget.Stack` both aggregate that, so a child cannot force its parent wider than the size it declared; `Get_Preferred_Size` (`Widget'Class`) returns CSS `width`/`height` or falls back to `Measure_Content`, except auto-width with horizontal scrolling enabled (`overflow-x: auto|scroll` or internal `Scrollable` flag) uses the min-width + chrome floor, and auto-height with vertical scrolling enabled (`overflow-y: auto|scroll` or internal `Scrollable` flag) uses the min-height + chrome floor
- Shared overflow scrolling with scrollbar parts — scroll offset applied at render time via `Render_Context.Scroll_Y`, not by shifting child geometries; hit-testing reverses the offset. Two override points let an item-only / virtualised widget participate without populating `W.Scroll_Content_H` from child geometries:
  - `Get_Scroll_Content_Height (W : Widget) return Pixel_Type` — dispatching primitive; default returns the cached `W.Scroll_Content_H` written by `Update_Shared_Scroll_Layout` from children. Override to report a virtual document size (e.g. `Total_Rows * Line_Height` for a hex/log viewer over 1M+ rows).
  - `On_Scroll_Changed (W; Old_Offset, New_Offset)` — dispatching hook fired by `Set_Scroll_Offset_Y` after a real change (no-op writes do not fire), with the post-clamp `New_Offset` the widget actually holds. Override to recycle / refill an item pool when the visible window moves, instead of polling from `On_Tick`.
  - `Connect_Scroll_Changed` / `Disconnect_Scroll_Changed` — library-wide multicast fired from the same place, for observers outside the widget that scrolled. Used by combo boxes to re-anchor an open dropdown: dropdowns are window overlays placed during layout, and scrolling only marks rendering dirty, so nothing else would move them. The observer receives the scrolled widget as `access Widget'Class` rather than a handle, since it fires for every widget including ones never registered in the store, and the pointer chain (`Get_Parent`) is what an observer can filter on in that case. The signal object itself is private; connect through the wrappers.
- Context menu hook with ancestor bubbling
- Per-part transitions; `Tick_Animations` advances each frame — layout-affecting properties (`padding`, `margin`, `border-width`, `font-size`) trigger relayout; visual-only properties trigger repaint only
- Style-aware state invalidation with relevance masks: `Widget_Style` tracks which `Widget_State` values appear in any rule selector; `Set_State`/`Set_Part_State` skip style recomputation for states no rule references
- Style versioning: `Style_Version` counter incremented on state/style changes; `Apply_Styles_To_Items` skips work when version unchanged and no animations active
- `On_Tick(DT)` per-frame hook
- Image rendering: `object-fit` modes (Fill, Cover, Contain, None, Scale_Down), rounded clipping
- Label icon sizing honors `Icon_Part` `width`/`height` styles in both measurement and layout
- Label text Y-offset honours CSS `vertical-align` on the label part: `baseline`/`top` (default) pins text to the top of the assigned slot, `middle` centres it, `bottom`/`text-bottom` pins it to the bottom. The slack is `slot_height − measured_text_height`; the default keeps historical top-aligned rendering so existing layouts are unaffected
- **No hardcoded sizing fallbacks.** Widgets that have no inherent content size (e.g. `Adi.Widget.Button.Switch`) return `(0, 0)` from `Measure_Content` instead of a hardcoded pixel constant. CSS class rules must set `width`/`height` on the widget and `::knob`/`::indicator`/etc. on the moving parts; a class that forgets to size the switch produces a 0×0 widget — loud failure, surfaces the missing CSS rule. Avoids the trap where a hardcoded fallback rendered at "physical pixels regardless of DIP scale" — looking microscopic on Retina even though CSS lengths around it scaled correctly

**Text_Input**: Single-line editor using `Text_Buffer`. Horizontal scroll, caret, selection, context menu. Double-click word select, triple-click select all.
- `Min_Visible_Chars` (default 20): controls the preferred width as a character count. The input does not grow with its text content; long text scrolls horizontally. Set via `Set_Min_Visible_Chars`, query via `Get_Min_Visible_Chars`. Width is computed as `char_width("M") × Min_Visible_Chars` plus padding/border.
- **Password mode**: `Set_Password_Mode`/`Is_Password_Mode` masks each codepoint of the buffer with `Password_Character` (default U+2022 BULLET `•`, configurable via `Set_Password_Character`, which rejects anything that is not exactly one UTF-8 codepoint). The buffer itself is unchanged, so `Get_Text` still returns the real text. Clipboard export is suppressed: Ctrl+C / Ctrl+X are no-ops and the context-menu `Cut` / `Copy` items are disabled while password mode is on; `Paste` is unaffected. Double-click falls back to `Select_All` so word boundaries cannot leak the underlying structure. XML grammar exposes `password-mode` and `password-character` on `<text-input>`.

**Text_Editor**: Multiline editor using `Text_Buffer` + `Text_Layout`. Vertical scrollbar, visual-row navigation, word/line selection.
- **Read-only mode**: `Set_Read_Only`/`Is_Read_Only` blocks keyboard editing (insert, delete, backspace, return, tab, undo, redo, cut, paste) while allowing navigation, selection, and copy. Context menu disables undo/redo/cut/paste items when read-only.
- **Append_Text**: Appends text at end of buffer without moving caret or disturbing selection. `Record_Undo` parameter (default `True`) controls undo history; `Text_Editor.Append_Text` passes `not Read_Only` so log-viewer mode skips undo snapshots. When `Record_Undo => False`, the redo stack is still cleared to prevent stale redo entries from overwriting appended content.
- **Scroll_To_End**: Deferred scroll consumed after scroll metrics are computed but before visible-row culling, so geometry is current on the same frame.

**List_Box** (generic over row widget): Selection modes (None/Single/Multi/Range), anchor-based range, inertial scrolling, style-driven scrollbar.
- **Grid layout mode**: CSS `grid-template-columns` activates grid layout (e.g., `repeat(3, 1fr)` for 3 columns). Gap between rows/columns comes from CSS `gap`/`row-gap`/`column-gap`. Layout uses `Compute_Grid_Layout` from `Adi.Layout_Util`.
- **Grid keyboard navigation**: Left/Right arrows move between columns (±1 item), Up/Down move between rows (±N items). PageUp/PageDown jump by visible-rows × columns. Home/End go to first/last item.
- **Grid hit-testing**: Click detection uses cached cell rectangles (both X and Y), so clicks map correctly to grid cells. Cell positions are computed during layout and cached in `Cell_Rects` for O(N) lookup.
- **Scrolling**: Vertical scrolling works in both modes. `Ensure_Row_Visible` uses cached cell positions to scroll the correct row into view.
- **Preferred height policy**: With auto height, preferred height is bounded by min-height + chrome floor (not total row content height), since list-box scrolling is internal.

**Combo_Box**: Dropdown using Main/Text/Indicator/Icon parts + List_Box overlay popup.
- Items are stored as `Combo_Item` records `(Text, Icon, Data)`. `Icon` is an `Adi.Image.Image_Handle`
  shown in the selected-item display (`Icon_Part`) and in each popup row (via `Label.Set_Icon`).
  `Data` is an `Item_Data_Access` — a borrowed reference to any user-defined tagged type derived
  from `Item_Data`; the combo box never frees it.
- **`Add_Item`**: `Add_Item (W, Text [, Icon] [, Data])` — both widget and handle overloads;
  `Icon` and `Data` default to `null` so existing callers compile unchanged.
- **Read accessors**: `Get_Item_Icon (W, Index)`, `Get_Item_Data (W, Index)` index into the
  stored vector (1-based; out-of-range returns `null`). `Get_Selected_Data (W)` returns
  `Data` for the currently selected item (`null` when nothing is selected). All have
  corresponding handle overloads.
- **Icon layout**: the `Icon_Part` flex item follows the same sizing rules as `Label.Icon_Part`:
  CSS fixed width/height via `Size_To_Px`, aspect-ratio preservation when only one dimension is
  fixed, intrinsic fallback. The icon item is created as a 4th render item (`Icon_Idx = 4`);
  `Build_Items` hides it (`Image_Source := null`, zero geometry) when no icon is selected.
- **CSS**: style `::icon` on the combo selector to control icon size, alignment, or display.
  `display: none` on `::icon` suppresses the icon part entirely.

**Dialog**: Modal overlay with backdrop, title/message/buttons, dismiss policies, button presets. Supports custom content via `Set_Content` which replaces the built-in message label with an arbitrary widget tree (pass `null` to restore the message label). The panel resolves `min-width`, `max-width`, `min-height`, `max-height`, and `margin` from CSS — margin shrinks the centering viewport, size constraints cap the panel dimensions.
- Handle-first internals: all sub-widgets stored as typed handles (`Box_Handle`, `Label_Handle`, `Widget_Handle`). Full handle API via `Dialog_Handle` (`Create_Handle`, `Set_Title`, `Set_Message`, `Add_Button`, `Show`, `Hide`, `Connect_Result`, style setters, etc.).
- Result callback signature: `(W : Widget_Handle; Button_Index : Natural; Button_Text : String)`.
- Default/primary button API:
  - `Set_Default_Button(Index)` marks the default action (`0` clears; out-of-range nonzero indices are stored and take effect once a button exists at that index)
  - `Get_Button_Handle(Index)` returns a `Button_Handle` for per-button customization. `Get_Button(Index)` is obsolescent.
  - Presets auto-mark natural defaults (`OK`/`Yes`)
- Focus behavior:
  - `Show` auto-focuses the default button when a valid default index exists
  - Callers can override immediately with `Adi.Window.Set_Focus(...)` after `Show`
- Style behavior:
  - Normal button style: per-dialog `Set_Button_Style` > package default `Set_Default_Button_Style` > empty styles
  - Primary button style: per-dialog `Set_Primary_Button_Style` > package default `Set_Default_Primary_Button_Style` > resolved normal style
  - Style application is explicit for every button on each re-evaluation, so changing default index cannot leave stale primary styling on demoted buttons

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
- `:root` metadata is host-scoped to each `Html_View`: the widget stores its own root font size for `rem`, and parsing embedded/linked css does not mutate global parser root-font state
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

**State-change dirty classification** (`Set_State` / `Set_Part_State`): when a state flips, the runtime compares the old and new resolved styles via `Widget_State_Style_Effect` / `Part_State_Style_Effect`, which return `Diff_None` / `Diff_Render_Only` / `Diff_Layout_Affecting`. The result picks the cheapest valid invalidation: `Diff_None` → no work; `Diff_Render_Only` → `Mark_Render_Dirty`; `Diff_Layout_Affecting` → `Mark_Dirty`. `Layout_Affecting_Diff` covers the layout surface (border, padding, margin, width/height, min/max, font, line-height, text wrap, white-space, display, position, inset, overflow, flex-*, grid-*, gap). Without this classification, a `:selected` rule that toggles only `display: none ↔ block` (a layout-affecting change) would only mark render-dirty and the bullet's new size wouldn't be assigned until the next genuine layout invalidation — the cause of the "first reveal step shows nothing" bug we hit on the workshop deck.

**Debug stats overlay**: `Set_Debug_Stats(True)` enables a 2-line HUD showing frame number, FPS, per-stage timing (Update/Layout/Draw/Present in microseconds), layout count, layout trigger reason, style cache hit ratio (`S:hits/total`), layout call/skip counts (`LC:calls+skips`), and preferred-size cache ratio (`P:hits/total`). Renders only when the scene is already being redrawn — does not force extra frames.

### Layout Performance Optimizations

Three optimizations reduce layout cost for large widget trees (e.g. 280+ widgets in list_box_example):

**Resolved style caching and evaluation** (`Get_Resolved_Part_Style` / `Get_Part_Style_Rules`):
- Widget part styles are stored internally as interned style handles (private representation), not embedded `Widget_Style` payloads per widget part.
- Rule evaluation order is prepared once per interned style (effective priority: explicit `Priority`, else selector `Specificity`; stable source-order tie behavior). Runtime resolution reuses this prepared order and avoids per-call rule sorting.
- Per-widget cache remains in place for hot repeated accesses, keyed by style version + effective widget state (`Get_States`) + part state, with per-part entries invalidated when widget-level key changes.
- A global resolved-style memo adds a second cache layer across widgets. Its key includes:
  - effective part handle
  - effective main-part handle (for sub-part inheritance cases)
  - packed effective widget states
  - packed part states
  - packed main-part states
- On global-cache overflow (`32k` entries), the cache is cleared (deterministic bounded-memory policy).
- Cache writes use `'Unrestricted_Access` on the read-only `Widget'Class` parameter (safe because caches are internal memoization only).

**Epoch-based layout deduplication** (`Layout_Tree` / `Layout_Child`): A global `Current_Layout_Epoch` counter increments once per `Layout_Tree` call via `Bump_Layout_Epoch`. The public `Layout_Tree` bumps the epoch then delegates to a private `Layout_Tree_Impl` for recursive descent — this ensures every external call (root, overlay, or dialog subtree) gets a fresh epoch while recursive children share the same epoch for dedup. Containers (flex, grid, list_box, stack) call `Layout_Child(Child)` instead of bare `Layout(Child)` — this stamps `Child.Last_Layout_Epoch := Current_Layout_Epoch`. When `Layout_Tree_Impl` later recurses into those children, it skips the redundant `Layout` call if the epoch matches. `Bump_Layout_Epoch` wraps to 1 (not 0) at `Natural'Last` to avoid matching the default `Last_Layout_Epoch := 0` init value. This eliminates ~50% of layout calls in container-heavy trees.

**Preferred size cache** (`Get_Preferred_Size`): Each widget caches its computed preferred size, keyed on `(Current_Layout_Epoch, Style_Version, Content_Version, Get_States(W), Geometry.Width, Geometry.Height)`. The cache is pass-scoped (valid within one layout epoch) and mutation-keyed (invalidated by style changes, content changes, state changes, or geometry changes). `Content_Version` is a per-widget counter bumped by `Mark_Dirty` (which is called by `Set_Text`, `Add_Child`, etc.) — it detects content mutations that don't affect `Style_Version`. `Cached_Pref_Epoch` is initialized to `Natural'Last` to prevent false hits before the first `Layout_Tree` call. Achieves ~56% hit rate in list_box_example (280+ widgets).

**Version bump helpers**: `Bump_Style_Version`, `Bump_Layout_Epoch`, and `Bump_Content_Version` are private auxiliary procedures that handle `Natural'Last` wraparound consistently. Layout epoch and content version wrap to 1 (not 0) to avoid matching default init values.

**Performance counters**: `Reset_Perf_Counters` / `Get_Perf_*` functions in `Adi.Widget` track style resolves, cache hits, layout calls, layout skips, preferred-size calls, and preferred-size cache hits per frame. Counters are reset before `Update` so that all work (including `Build_Items`) is captured. The Window captures these after each layout pass for the debug stats overlay.

### Width-Aware Measurement (Text Wrap)

A `Layout_Tree` pass is **measure → assign → recursive-layout** in a top-down sweep, and a wrapping widget's height depends on the width the assign step is about to give it — a question it cannot answer while it is being measured.

Two primitives answer the two different questions:

- `Measure_Content` — the unconstrained (max-content) size. Geometry-independent: consulting the widget's current width makes the width it was given last pass the width it asks for next pass, which ratchets in one direction only.
- `Measure_Content_At_Width (W, Assigned_Width)` — the same measurement with the assigned *outer* width known. Dispatching, defaults to `Measure_Content`, and overridden by widgets whose height depends on their width. It is a query: it must not change observable layout state (internal memoisation is fine — an answer must not commit the widget to it).

`Measure_At_Width` is the non-dispatching wrapper around the second, applying CSS sizing on top exactly as `Get_Preferred_Size` does for the first: a definite declared width or height wins over what the content measured. A percentage size is left alone — it resolves against a container this query knows nothing about.

Minimums are width-dependent for the same reason, and have the same pair:

- `Get_Content_Min_Size` — the widthless content minimum. Geometry-independent for the reason above: a wrapping widget with no width to measure at reports its unwrapped minimum rather than reading back the width it happened to carry, which would make every answer one pass late.
- `Get_Content_Min_Size_At_Width (W, Assigned_Width)` — the same minimum at a known width. Dispatching, defaults to `Get_Content_Min_Size` (dispatching through `Widget'Class`, so a widget that overrides only the widthless form is still heard), overridden by `Label`, `Box` and `Stack`.

`Effective_Min_Size_At_Width` is the non-dispatching wrapper, applying `min-*`, declared sizes and overflow policy exactly as `Effective_Min_Size` does for the widthless form.

### Flex Lines

`Form_Flex_Lines` partitions items into lines wherever the next item's outer hypothetical main size no longer fits. A line always takes at least one item, so an item larger than the container overflows its own line rather than opening an empty one ahead of itself. `nowrap` yields a single line.

Each line then flexes on its own: `Distribute_Main_Sizes` runs per line, so what one line grew into says nothing about what is left on the next, and items are justified and positioned relative to their own line. A line is as deep as its deepest item, except a single `nowrap` line, which takes the container's cross size — that is what lets `align-items: stretch` fill an unwrapped container. `align-content` then spreads the lines over the cross axis, and `wrap-reverse` mirrors their positions across it.

`align-items`/`align-self` resolve against the item's *own line's* depth, not the container's, so a shallow item on a shallow line centres within that line. `wrap-reverse` swaps cross-start for cross-end throughout: the margin on the starting side becomes the bottom one and placement is measured from the far edge back, so `flex-start` comes to rest at the bottom of a reversed row. `baseline` falls back to `flex-start`, and `order` does not reorder anything — both are accepted values with no effect (`docs/css_styling.md`).

Along the main axis a wrapping container's minimum is its largest single item's contribution, with no gaps: it can always break, so it never needs room for the sum. `nowrap` needs every item plus the gaps between them.

Measurement follows the same partition: a wrapping row is as deep as its lines summed plus the cross gaps between them, in both `Measure_Content_At_Width` and the minimum aggregation. Taking one global maximum there reserves a single line and lets every line below it escape the container.

`Resolved_Flex_Base` answers what main-axis size an item is laid out from before it grows or shrinks: a definite `flex-basis` exactly — including `0`, a demand for nothing — and otherwise the item's content size at its assigned width. Aggregation and the flex algorithm both resolve the base through it, so a container cannot reserve room on one rule while layout places on another.

`auto` and `content` differ in what they let stand in for the content: `auto` takes the item's declared `width`/`height` when it has one, `content` ignores it and measures. Both reflow with the assigned width. `Resolved_Flex_Base` reaches the first through `Measure_At_Width`/`Get_Preferred_Size`, which apply CSS sizing, and the second through `Measure_Content_At_Width`/`Measure_Content`, which do not.

Wrapping itself never breaks a word: `Effective_Wrap_Width` floors the wrap width at the widest word, and the measurement, the post-flex re-measure and `Render_Text_Item` all go through it, so what layout reserves is what the renderer draws. See `docs/css_styling.md` for the policy and its limits — it approximates `overflow-wrap: normal` rather than implementing it.

**Containers** ask the query after they know the width:

- **Flex** forms lines, computes intrinsic bases, assigns main sizes, then re-measures each child at its assigned width and re-runs if any answer changed. Base sizes and automatic minimums are both updated there — the minimum is width-dependent too, and is recomputed whether or not the base moved. A declared basis is not a measurement and is left alone. An item that scrolls *its own* content still has no automatic minimum; the container's overflow says nothing about that.
- **Box** aggregating child minimums asks each child at the width that child will be laid out at. On a row that is whatever the distribution hands it — a declared width is the item's *basis* there and still grows or shrinks from it, so two `width: 200px` items in a 300px row are measured at 150, not 200. On a column it is the declared width, or the line when the child stretches, so a `width: 100px` wrapping label in a 300px column is not measured at 300. A non-shrinkable child is floored at its resolved flex base, because that is the size it will be placed at.
- **Grid** asks at the width the cell will actually render at — the child's own declared width when it has one, the track width otherwise (`Grid_Child_Width`), so a `width: 100px` label in a 300px cell is not measured at 300.

**Implemented for**: `Label` (wrapping, icon column, padding/border), `Box`, `Stack`. One deliberate fallback returns the unconstrained preference instead:

- `Html_View` — its layout writes into the widget (cached document size, block rectangles, scroll content height), so it cannot answer without mutating state. Refactoring it to measure purely is a follow-up.

A **multi-child row** is answered by running the distribution itself: `Flex_Row_Child_Widths` builds each child's `Flex_Child_Info` through the same `Make_Flex_Child_Info` the layout uses, calls `Distribute_Main_Sizes`, and reports the resulting widths. Only the main axis is resolved — cross sizing would stretch the children and contaminate an answer that was asked how wide they are — and nothing is written back, so measurement stays a query.

## Settings

**Adi.Settings** (`adi-settings.ads`): Persistent key-value store for application settings. `Setting_Value` is a managed recursive variant (null, string, integer, float, boolean, list, map) with controlled deep-copy/free semantics. `Settings_Store` provides typed getters/setters with dot-path keys (`.` separator, `\.` escape) and auto-creation of intermediate maps. Pluggable `Settings_Backend` interface; default `JSON_Settings_Backend` serializes via `Adi.JSON.JSON_Writer` and reads via `Adi.JSON.Parsers`. File path: `Pref_Path(Org, App) & "settings.json"`. Saves atomically (temp + rename). Full reference in `docs/settings.md`.

**Adi.JSON** (`adi-json.ads`): JSON support — wraps the vendor parser (`json-ada`) for reading and provides `JSON_Writer` (streaming builder with automatic comma tracking, pretty-printing, depth tracking) and `Escape_String` (UTF-8 safe) for writing. Used by both `Adi.Settings.JSON_Backend` and `Adi.MCP`.

## SDL Bindings

Hand-crafted Ada bindings in `adi-sdl*.ads`:
- `Adi.SDL` (core, clipboard), `.Video`, `.Render`, `.Events`, `.Mouse`, `.TTF`, `.TTF.TextEngine`, `.Image`, `.Surface`, `.PixelFormat`
- Native Ada types, incomplete types for opaque C structs, proper enumerations
- Not SDLAda (which is commented out in `adi.gpr`)
