# `Adi.Widget.Html_View`

A widget that renders documentation-style HTML: block and inline flow,
lists, images, inline SVG, a tag/class/id/inline cascade over the CSS
properties the library already resolves, and hyperlinks that reach an
application callback. It is render-only: the application decides what
to trust and where a link leads.

Text decoration (`underline`, `line-through`, `overline`) is drawn by
`Adi.Widget` rather than by SDL_ttf, whose renderer text engine fills
decorations in white for coloured text; the upstream issue and patch
are under `deps/issues/`.

## Supported Tags
- Block: `div`, `p`, `h1`–`h6`, `ul`, `ol`, `li`, `hr`, `center`, `pre`, `blockquote`, `dl`, `dt`, `dd`, `section`, `article`, `header`, `footer`, `nav`, `main`, `aside`, `figure`, `figcaption`
- Inline: `span`, `b`, `strong`, `em`, `i`, `code`, `a`, `s`, `del`, `ins`, `u`, `small`, `mark`, `abbr`, `kbd`, `var`, `samp`, `q`, `cite`, `time`, `img` (inline atomic box), `svg` (inline atomic box), `br`
- Unknown tags: transparent containers (children preserved and rendered).
- Tag defaults are structural only (`display`, `white-space` for `pre`). Typographic defaults (font sizes, weights, margins, text-decoration) come from a stylesheet loaded through `Set_Default_Stylesheet`.

## Attributes
- Common: `id`, `class`, `style`
- `img`: `src`, `alt`, `width`, `height`
- `svg`: standard nested inline SVG content (for example `<svg ...><path .../></svg>`)
- `a`: `href`, optional `title`

Attributes other than the above may be parsed and ignored.

## Public Widget API
Package: `Adi.Widget.Html_View`

- **Creation**
  - `function Create_Handle return Html_View_Handle;`
  - The view needs no window attachment.

- **Content**
  - `procedure Set_HTML (Self : in out Html_View; Source : String);`
  - `function Get_HTML (Self : Html_View) return String;`

- **Hyperlink signal**
  - ```ada
    type Link_Click_Callback is access procedure
      (Self : Html_View_Handle;
       Href : String);
    procedure Connect_Link_Click
      (Self : in out Html_View; CB : Link_Click_Callback);
    function Connect_Link_Click
      (Self : in out Html_View; CB : Link_Click_Callback)
       return Link_Click_Signals.Connection_Id;
    procedure Disconnect_Link_Click
      (Self : in out Html_View; Id : Link_Click_Signals.Connection_Id);
    ```
  - Emitted on left-button release when the pointer is still over the same link run.

- **Asset loading callback (`img` resources)**
  - ```ada
    with Adi.Image;

    type Asset_Load_Callback is access function
      (Self : Html_View_Handle;
       URI  : String)
       return Adi.Image.Image_Handle;

    procedure Set_On_Load_Asset
      (Self     : in out Html_View;
       Callback : Asset_Load_Callback);
    ```
  - Ownership: the callback returns an `Image_Handle`, which keeps
    nothing. The callback must hold an `Image_Owner` for as long as the
    view draws the image — typically the asset cache's, or one of its
    own. Loading into a local owner and returning its handle yields a
    handle that is already stale.
  - Resolution path for `img src`:
    1. If `On_Load_Asset` is set, call it first with the raw `src` value.
    2. If the callback returns a valid handle, use it.
    3. If the callback is null or the handle names nothing, the image is treated as unavailable (render `alt` fallback if present).
  - The view caches what the callback gave it, keyed by `src`. An entry
    whose image has since been released is dropped and the callback
    asked again, so an owner may be let go and the image reloaded on the
    next request.
  - Callback may implement custom URI schemes (e.g. `app://`, in-memory bundles, virtual FS).
  - Widget does not take ownership of callback internals; image lifetime follows normal `Adi.Image` ownership conventions.

- **Resource loading callback (`<link rel="stylesheet">`)**
  - ```ada
    type Resource_Load_Callback is access function
      (Self : Html_View_Handle;
       URI  : String) return String;

    procedure Set_On_Load_Resource
      (Self     : in out Html_View;
       Callback : Resource_Load_Callback);
    ```
  - Used to resolve linked stylesheet resources by URI.
  - Invoked for `<link rel="stylesheet" href="...">` entries in HTML content.
  - An empty string means the resource was not found.
  - Resources are callback-owned; the widget reads no file itself.

- **Default stylesheet**
  - ```ada
    procedure Set_Default_Stylesheet
      (Self : in out Html_View;
       Path : String);
    procedure Set_Default_Stylesheet_String
      (Self : in out Html_View;
       CSS  : String);
    function Get_Default_Stylesheet (Self : Html_View) return String;
    ```
  - `Set_Default_Stylesheet` reads a CSS file from the filesystem and stores its content. Errors (missing file, permission denied) are logged and the default CSS is cleared.
  - `Set_Default_Stylesheet_String` accepts CSS text directly.
  - Both prepend the stored CSS before all document-embedded CSS.
  - Both trigger an immediate reparse of the current document (like `Set_On_Load_Resource`).
  - `Get_Default_Stylesheet` returns the stored CSS text.
  - Set to empty string to disable.

- **Optional helper**
  - `procedure Clear (Self : in out Html_View);`

- **Content scale**
  - `procedure Set_Content_Scale (Self : in out Html_View; Scale : Pixel_Type);`
  - `function Get_Content_Scale (Self : Html_View) return Pixel_Type;`
  - Scale affects absolute/content units (`px`, `dip`, `em`, `rem`) and typography metrics.
  - Scale does not multiply `%`, `vw`, or `vh` resolution.
  - `rem` remains scoped to the `Html_View` stylesheet root (`:root { font-size: ... }`), not to global parser state.

## Internal Model

### Parse Tree
- Parse source into a small normalized tree:
  - Node kinds: `Element_Node`, `Text_Node`, `Line_Break_Node`.
  - Element stores: tag kind, filtered attributes, inline style text, children.
- Tag names are ASCII case-insensitive (`DIV`, `Div`, `div` are equivalent).

### Layout Boxes
- Convert parse tree into layout boxes/runs:
  - Block box list for block tags.
  - Inline run sequence for text-level content.
  - Atomic inline items for `img`, inline `svg`, and inline `code` segments.
- `br` inserts a forced line break in the active inline context.
- `hr` creates a dedicated block separator box.

## Flow and Layout Rules

### Block Flow
- Parent block content is laid out top-to-bottom.
- Block width is container content width unless constrained by explicit width rules.
- Vertical margins/padding/border participate via existing style resolution.
- Block elements emit panel items with the resolved element style, so block
  `background-color`/`border*` visuals are rendered.

### Vertical Margin Collapsing
The renderer implements CSS-style vertical margin collapsing:

- **Adjacent siblings**: two adjacent block siblings' touching margins
  collapse to `max(prev.bottom, next.top)`, not the sum.
- **Collapse-through (parent ↔ first/last child)**: when a parent has no
  top padding/border, its top margin collapses with the first child's top
  margin and propagates outward; same for bottom. This makes transparent
  wrappers like `<center>`, `<div>` (no padding), and `<section>` rhythm
  the same way as inline-level structural HTML.
- **Stoppers**: any of the following commits a pending margin and
  prevents collapse-through past it:
  - Top/bottom padding or border on the block.
  - Inline content (text run, `<img>`, `<svg>`).
  - `<br>` and rendered newlines inside `white-space: pre`, `pre-wrap`,
    or `pre-line`.
  - `<hr>` (rendered as a replaced block; participates in collapsing on
    both sides but does not allow collapse through itself).
- **Whitespace-only text nodes** between block boundaries (the indentation
  in pretty-printed HTML) are not committing events: they leave the
  pending margin alone so collapse-through survives source formatting.

### Inline Flow
- Inline content is line-wrapped by available width (similar to text widgets).
- Wrapping opportunities:
  - At collapsible whitespace boundaries.
  - Between runs with different styles.
  - Around atomic inline objects (`img`, `svg`, `code` chunks when split is allowed by text wrapping).
- `br` always terminates current line and starts next line.

### Whitespace Normalization
- Outside `code`, consecutive ASCII whitespace collapses to a single space.
- Leading/trailing collapsible whitespace around block boundaries is trimmed.
- Newline characters in source are treated as collapsible whitespace.
- Inside `code`, whitespace is preserved (subject to clipping/wrapping policy below).

### `code` Behavior
- Render with monospace family if configured; otherwise fallback to current resolved family.
- Default tag style may include subtle background + small horizontal padding.
- Wrapping:
  - Wraps at normal whitespace boundaries.

### Lists (`ul`/`ol`/`li`)
- Each `li` is a block row with marker area + content area.
- Marker rules are style-driven from `list-style*` properties:
  - `list-style-type`: `disc`, `circle`, `square`, `decimal`, `none`, or quoted custom marker text.
  - `list-style-image`: `none` or callback-loaded `url(...)` marker asset.
  - `list-style-position`: `outside` and `inside`.
- Ordered list item numbering supports `<li value="N">` overrides.
- Wrapped lines in an `li` align to the content area (not marker origin).
- Nesting increases indentation by a fixed style-driven step.

### `center`
- Treated as block container with default `text-align: center` for descendant inline formatting context.

## Hyperlink (`a`) Semantics
- `<a>` is an inline style/run container.
- Default visual style (overrideable): link color + underline.
- Hit-testing:
  - Each laid-out link fragment stores rect + `href`.
  - Hover state tracked per fragment for style resolution.
  - Click dispatch calls `On_Link_Click (Href)` once per completed click.
- Links activate by pointer only.

## CSS and Cascade
- Style sources:
  1. Tag defaults (structural only: `display`, `white-space` for `pre`)
  2. Default stylesheet (if set via `Set_Default_Stylesheet`) — prepended before all document CSS
  3. CSS extracted from embedded `<style> ... </style>` blocks
  4. CSS extracted from `<link rel="stylesheet" href="...">` resources (via callback)
  5. Tag/class/id selectors from parsed stylesheets
  6. Inline `style` attributes
- Implemented precedence: `defaults < default-stylesheet < tag < class < id < inline`.
- `demos/assets/html/default.css` is a browser-like typographic default sheet for `Set_Default_Stylesheet`. Document CSS always overrides the default stylesheet.
- Inline style declarations are parsed once and cached by normalized declaration text.
- Document CSS and every inline `style` attribute go through `Adi.CSS_Parser.Rule_Sheet`, which answers a selector's `Style_Rules` and interns none of them. The view cascades those rules itself and never asks for a part, a state or a `Widget_Style`, so the round trip a `Stylesheet` makes through the rule-set and style stores would leave a permanent entry per distinct rule block and per distinct inline style. A `Rule_Sheet` is an ordinary object: the document's dies with the view, an inline style's with the call that parsed it.
- `:root` metadata is host-scoped inside the widget:
  - root styles apply to the html content root only
  - `:root { font-size: ... }` defines the local `rem` base for that `Html_View`
  - parsing html-local CSS does not mutate window-level or global root-font state

### Runtime property coverage used by Html_View
- Typography/text flow: `font-size`, `font-weight`, `font-style`, `text-align`, `text-decoration`, `white-space`, `text-wrap-mode`, `text-overflow`, `line-height`.
- Lists: `list-style`, `list-style-type`, `list-style-image`, `list-style-position`.
- Box/layout basics: `display`, `margin*`, `padding*`, `width/height/min/max`, `overflow`.
- Visuals: `color`, `background-color`, `border*`, `box-shadow`, `opacity`, `visibility`.
- Images: `object-fit`.

## Unit Resolution Semantics
- Supported length units include: `px`, `dip`/`dp`, `em`, `rem`, `%`, `vw`, `vh`.
- For `Html_View`, `vw`/`vh` are resolved against the html content viewport.
- For `Html_View`, `rem` is resolved from the widget's own stylesheet root font, falling back to the default root size when the document does not specify one.
- For normal widget styling, `vw`/`vh` are resolved against SDL window pixel size.

## Parser Recovery Rules
- Best-effort tree construction for malformed input.
- Unclosed tags auto-close at end of parent/document.
- `<li>` implies close of any open `<li>` in the same list scope (does not cross `<ul>`/`<ol>` boundaries).
- Unexpected closing tag closes up-stack until match; if no match, ignore close token.
- Text outside known structure is preserved as text nodes.
- Entities: `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&apos;`, and numeric references up to `&#255;`.
- Unknown entities remain literal text.

## Images (`img`/`svg`) and `hr`
- `img`:
  - Source resolution is callback-driven through `Set_On_Load_Asset`.
  - Missing/failed `src` load renders `alt` text when present, otherwise empty inline placeholder.
  - `width`/`height` attributes override intrinsic size when provided.
  - If only one dimension is provided, preserve intrinsic aspect ratio.
  - Final painted size is clamped by available line width (inline) or container width policy.
- Inline `svg`:
  - Standard nested SVG markup in HTML content is supported.
  - The inline SVG source is converted to an image via `Adi.Image.Load_SVG_From_String`.
  - Width/height styling follows the same inline sizing path used by `img`.
- `hr`:
  - Block element with default thin line style and vertical margins.
  - Implemented using standard box rendering primitives for themeability.

## Event Integration
- Pointer move updates hover fragment for links.
- Pointer down stores candidate link fragment.
- Pointer up on same fragment triggers callback.
- Non-link clicks are ignored by default and may bubble per normal widget behavior.

## Window Integration
- Rendering, list markers and inline SVG/image handling are self-contained in the widget; it has no `Attach_Window`.

## Performance and Caching
- `Set_HTML` reparses and rebuilds internal run/tree caches, then marks widget dirty.
- Re-layout only when width or style-affecting state changes.
- Image cache is keyed by `src` within the widget instance to avoid repeated callback loads.
- Inline style declarations are cached to reduce repeated parse cost.
- The laid-out document is cached whole and re-emitted while its `Cache_Key` holds: the document and font generations, the resolved-style store's generation, the scales, the content box, the root font size and the widget's own main and text resolved styles. The store generation is there because the cached items name their styles by handle, and a `Collect` that cleared leaves every one of them naming nothing. It moves only at such a clear — past `Adi.Resolved_Styles.Entry_Cap`, 16,384 entries — but when it does, every view in the process re-lays out its whole document on the next frame. An application sitting above that cap clears repeatedly and pays that repeatedly; `perf_stats` reports `resolved_generation` beside the count for exactly this.
- `Measure_Content` reports the real document height the document needs at its current width (cached in `Cached_Content_W` / `Cached_Content_H`, populated at the end of every `Layout_And_Build` pass). On the very first measure — before any layout has run — it returns a small `(320, 120)` stub so the parent flex has something to assign; subsequent measures use the cached real values. `Set_HTML` invalidates both fields, and `Clear` resets them along with the scroll offset, so a cleared view measures as one that never held a document.

## Scroll Behavior and CSS Overflow
- `Html_View` installs no styles at construction and does not set the `Scrollable` flag. Scrolling and clipping come entirely from CSS `overflow-x` / `overflow-y`, whose initial value is `visible`.
- Scrolling is opt-in: `overflow-y: auto` (or `scroll`) makes the widget a viewport that clips its document and scrolls it. `demos/css/html_view_example.css` shows the usual form.
- Left at `visible`, `Get_Preferred_Size` routes through `Measure_Content` and the widget sizes itself to its document height — useful for short, static documents such as inline code blocks that should grow to fit.
- `overflow-x: auto` clips; a horizontal offset and scrollbar are the subject of [`proposals/horizontal_scrolling.md`](proposals/horizontal_scrolling.md).
- Appearance — background, border, radius, padding, text and link colours, scrollbar track and knob — is entirely the stylesheet's. A fresh view draws none of it.

## Testing Coverage (`tests/src/html_view_test.adb`)
- Parsing and recovery:
  - Case-insensitive tag names, unknown tag transparency, malformed close handling.
  - Entity decoding for supported entities.
- Layout:
  - `div` nesting and block flow.
  - `span` inline overrides.
  - `br` forced line breaks.
  - `hr` block separator geometry.
  - `code` whitespace preservation and wrapping.
  - List marker placement and wrapped-line indentation.
- Styling/cascade:
  - `tag < class < id < inline style` precedence assertions.
- Line metrics:
  - mixed-inline baseline alignment and heading isolation checks.
- Alignment:
  - `center` and `text-align: center` geometry assertions.
- Inheritance:
  - body font-size inheritance checks for descendant text runs.
- Scaling and units:
  - html content scale behavior (`1.0` vs higher scales).
  - `vw`/`vh` context checks (active viewport and html-local viewport).
- Link behavior:
  - `<a href>` fragment hit-test mapping.
  - Click callback called with exact `href`.
  - No callback call when pointer down/up are on different fragments.
- Clipping:
  - visible clipped link fragments clickable, scrolled-out fragments not clickable.
- Image behavior:
  - Callback-first asset loading path and fallback path.
  - Missing source fallback (`alt` path).
- Default stylesheet:
  - `Set_Default_Stylesheet_String` / `Get_Default_Stylesheet` round-trip.
  - `Set_Default_Stylesheet` from file path and graceful bad-path handling.
  - `em` font-size resolves against root font size, not viewport.
  - User CSS overrides default stylesheet rules.
  - Defaults survive `Clear` + re-set.
  - Late `Set_Default_Stylesheet_String` triggers reparse of current content.
- Vertical margin collapsing:
  - Adjacent siblings collapse to `max(prev.bottom, next.top)`.
  - Collapse-through last child of a transparent parent (e.g. `<center>`)
    on pretty-printed source.
  - Collapse-through first child of a transparent parent on pretty-printed
    source.
  - Top padding/border traps the inner block's top margin
    (collapse-through stops at the padding edge).
  - `<br>` commits pending margins and stops collapse-through.
  - Rendered newlines inside `white-space: pre-line` commit pending
    margins (same path also covers `pre` and `pre-wrap`).
  - `<hr>` participates in collapsing on both top and bottom edges.

## Policy
- Link keyboard activation: pointer only.
- URL policy (`mailto:`, custom schemes): `href` reaches the callback unchanged.
- Sanitization: the widget is render-only; the application decides trust and navigation in the callback.
