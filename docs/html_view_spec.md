# `Adi.Widget.Html_View` v1 Technical Spec

## Goals
- Render lightweight documentation-style HTML inside Adi widgets.
- Reuse existing Adi layout/style systems where practical, without browser-level complexity.
- Support clickable hyperlinks via `<a>` that invoke an application callback.

## Non-Goals
- No DOM API, JavaScript, navigation stack, forms, iframes, or script execution.
- No complex CSS selectors/combinators (v1 remains tag/class/id + inline style).
- No full HTML5 parsing compliance; deterministic, documented recovery rules are enough.

## Implementation Status
- Next-phase milestone completed on 2026-02-13.
- Renderer now uses an internal element tree (`Element`, `Text`, `Break`) with per-element attribute-driven cascade and line-box layout.
- Phase 2 milestone completed on 2026-02-14.
- Added line finalization alignment (`center` / `text-align`), html content scaling API, `vw`/`vh` support, block margin/padding flow participation, and expanded runtime parser support (`line-height`, `white-space`, `text-decoration`, `text-overflow`, `object-fit`, `visibility`).
- Phase 3 milestone completed on 2026-03-01.
- Added default stylesheet system (`Set_Default_Stylesheet`, `Set_Default_Stylesheet_String`) with browser-like typographic defaults in `examples/assets/html/default.css`.
- Fixed `em` unit resolution in text measurement functions (was incorrectly using viewport height as font size).
- `hr` block element now respects CSS margins.
- Phase 4 milestone completed on 2026-05-09.
- Implemented full CSS vertical margin collapsing: adjacent siblings, parent ↔ first/last child collapse-through across transparent wrappers, padding/border as collapse stoppers, and rendered-newline / `<br>` / `<hr>` commit semantics.
- Temporary decoration workaround is active in `Adi.Widget` for `underline`, `line-through`, and `overline`.
  - Reason: current SDL_ttf renderer text engine can render decoration fill ops with white RGB for non-white text colors.
  - Upstream issue draft and patch are tracked in `deps/issues/sdl_ttf_text_decoration_color_issue.md` and `deps/issues/sdl_ttf_text_decoration_color.patch`.

## Supported Tags (v1)
- Block: `div`, `p`, `h1`–`h6`, `ul`, `ol`, `li`, `hr`, `center`, `pre`, `blockquote`, `dl`, `dt`, `dd`, `section`, `article`, `header`, `footer`, `nav`, `main`, `aside`, `figure`, `figcaption`
- Inline: `span`, `b`, `strong`, `em`, `i`, `code`, `a`, `s`, `del`, `ins`, `u`, `small`, `mark`, `abbr`, `kbd`, `var`, `samp`, `q`, `cite`, `time`, `img` (inline atomic box), `svg` (inline atomic box), `br`
- Unknown tags: transparent containers (children preserved and rendered).
- No visual defaults are applied by the widget itself. Users may load a default stylesheet via `Set_Default_Stylesheet` to get browser-like typographic defaults (font sizes, weights, margins, text-decoration). Only structural properties (`display`, `white-space` for `pre`) are set as tag defaults.

## Attributes (v1)
- Common: `id`, `class`, `style`
- `img`: `src`, `alt`, `width`, `height`
- `svg`: standard nested inline SVG content (for example `<svg ...><path .../></svg>`)
- `a`: `href`, optional `title`

Attributes other than the above may be parsed and ignored.

## Public Widget API (Proposed)
Package: `Adi.Widget.Html_View`

- **Creation**
  - `function Create return Html_View_Access;`
  - No window attachment call is required; `Html_View` is window-agnostic.

- **Content**
  - `procedure Set_HTML (Self : in out Html_View; Source : String);`
  - `function Get_HTML (Self : Html_View) return String;`

- **Hyperlink callback**
  - ```ada
    type Link_Click_Callback is access procedure
      (Self : access Html_View;
       Href : String);
    procedure Set_On_Link_Click
      (Self     : in out Html_View;
       Callback : Link_Click_Callback);
    ```
  - Triggered on left-button release when pointer is still over the same link run.
  - If no callback is set, link clicks are ignored.

- **Asset loading callback (`img` resources)**
  - ```ada
    with Adi.Image;

    type Asset_Load_Callback is access function
      (Self : access Html_View;
       URI  : String)
       return Adi.Image.Image_Access;

    procedure Set_On_Load_Asset
      (Self     : in out Html_View;
       Callback : Asset_Load_Callback);
    ```
  - Resolution path for `img src`:
    1. If `On_Load_Asset` is set, call it first with the raw `src` value.
    2. If callback returns non-null, use returned image.
    3. If callback is null or returns null, image is treated as unavailable (render `alt` fallback if present).
  - Callback may implement custom URI schemes (e.g. `app://`, in-memory bundles, virtual FS).
  - Widget does not take ownership of callback internals; image lifetime follows normal `Adi.Image` ownership conventions.

- **Resource loading callback (`<link rel="stylesheet">`)**
  - ```ada
    type Resource_Load_Callback is access function
      (Self : access Html_View;
       URI  : String) return String;

    procedure Set_On_Load_Resource
      (Self     : in out Html_View;
       Callback : Resource_Load_Callback);
    ```
  - Used to resolve linked stylesheet resources by URI.
  - Invoked for `<link rel="stylesheet" href="...">` entries in HTML content.
  - Return empty string to indicate resource-not-found.
  - No file-system fallback is performed by the widget; resources are callback-owned.

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
  - Default v1: permit wrapping at normal whitespace boundaries.
  - No horizontal scrolling in v1.

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
- Keyboard activation for links is out of scope for v1 unless the widget is later made focus-fragment aware.

## CSS and Cascade
- Style sources:
  1. Tag defaults (structural only: `display`, `white-space` for `pre`)
  2. Default stylesheet (if set via `Set_Default_Stylesheet`) — prepended before all document CSS
  3. CSS extracted from embedded `<style> ... </style>` blocks
  4. CSS extracted from `<link rel="stylesheet" href="...">` resources (via callback)
  5. Tag/class/id selectors from parsed stylesheets
  6. Inline `style` attributes
- Implemented precedence: `defaults < default-stylesheet < tag < class < id < inline`.
- The widget ships with no built-in visual defaults. Users may load `examples/assets/html/default.css` via `Set_Default_Stylesheet` for browser-like typographic defaults (font sizes, weights, margins, text-decoration). Document CSS always overrides the default stylesheet.
- Inline style declarations are parsed once and cached by normalized declaration text.
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
- Entities supported in v1: `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`.
- Unknown entities remain literal text.

## Images (`img`/`svg`) and `hr`
- `img`:
  - Source resolution is callback-driven through `Set_On_Load_Asset` (no widget-side filesystem fallback).
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
- `Html_View` does not expose or require an `Attach_Window` API.
- All rendering behavior (including list markers and inline SVG/image handling) is self-contained in the widget.
- Text editors, text inputs, and combo boxes resolve overlay host windows automatically from widget-tree membership.
- Dialog widgets still require explicit host attachment via `Attach_Window`.

## Performance and Caching
- `Set_HTML` reparses and rebuilds internal run/tree caches, then marks widget dirty.
- Re-layout only when width or style-affecting state changes.
- Image cache is keyed by `src` within the widget instance to avoid repeated callback loads.
- Inline style declarations are cached to reduce repeated parse cost.

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

## Implementation Milestones
1. Parser + normalized node model + recovery/entity handling.
2. Block/inline layout engine with list markers and line-break semantics.
3. Rendering integration (text, boxes, images, `hr`) with style cascade.
4. Link fragment hit-testing + callback dispatch.
5. Test suite and example program (`examples/html_view_example.adb`, optional in v1).

## Open Decisions (Default Choices)
- Link keyboard activation: defer to v2.
- Rich URL policy (`mailto:`, custom schemes): pass `href` string unchanged to app callback.
- Sanitization: widget is render-only; application decides trust and navigation policy in callback.
