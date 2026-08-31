# CSS Styling System

Adi uses a CSS-like styling system with two paths:

- **Compile-time** — `tools/css_to_ada.py` converts `.css` files into Ada constant packages
- **Runtime** — `Adi.CSS_Source` and `Adi.CSS_Parser` load and apply stylesheets dynamically, with optional live reload

Both paths use the same selector syntax, property set, and value types.

---

## Selectors

### Selector Types

| Syntax | Kind | Example |
|--------|------|---------|
| `.name` | Class | `.button { ... }` |
| `#name` | ID | `#root { ... }` |
| `name` | Tag | `label { ... }` |

A widget can match all three, and they merge in that CSS order: tag first,
then classes left to right, then id. Names are matched case-insensitively.

What supplies each name depends on how the widget was created. From XML, the
tag is the element name and the id is its `id` attribute (see
[`xml_ui_system.md`](xml_ui_system.md#which-selectors-reach-a-widget)); in
hand-written Ada you choose them at the `Bind_*` call.

Comma-separated selector groups are supported and expanded per selector:

```css
.primary, .secondary {
  border-radius: 8px;
}
```

### Part Selectors

Part selectors target sub-elements of a widget using `::part` pseudo-element syntax:

| Part | Constant | Typical Usage |
|------|----------|---------------|
| *(none)* / `::main` | `Main_Part` | Widget body (default when no part specified) |
| `::label` | `Label_Part` | Auxiliary/display label region, and the overlay a `label=` attribute draws |
| `::text` | `Text_Part` | Text content in input controls |
| `::icon` | `Icon_Part` | Icon region |
| `::cursor` | `Cursor_Part` | Text cursor |
| `::selected` | `Selected_Part` | Selected item highlight |
| `::indicator` | `Indicator_Part` | Dropdown arrow, slider fill |
| `::scroll` | `Scroll_Part` | Scrollbar track, slider bar |
| `::knob` | `Knob_Part` | Scrollbar/slider thumb |
| `::items` | `Items_Part` | Items container |

Example:

```css
.combo::text {
  color: rgb(15, 23, 42);
  font-size: 14px;
}

.combo::indicator {
  color: rgb(71, 85, 105);
}
```

#### A slider's bar and knob

The widget's own content box — what is left after its padding and
border — is the press target and the height the knob is sized from.
`::scroll` is the bar drawn inside it: give it a height and it becomes a
band of that thickness, centred, with `::indicator` — the filled part —
matching it. Say nothing about `::scroll` and the bar fills the box.

Keeping the two apart is what lets a thin bar carry a round knob: the
knob takes its width from CSS and its height from the widget, so a 6px
bar in an 18px widget leaves an 18px circle and the full 18px still
takes the press.

```css
.volume          { height: 18px; }
.volume::scroll  { height: 6px; border-radius: 3px;
                   background-color: #e4e9f1; }
.volume::knob    { width: 18px; border-radius: 9px;
                   background-color: #3b82f6; }
```

Vertical sliders read `::scroll`'s width instead, and the knob takes its
height from CSS and its width from the widget.

### Property Inheritance Between Parts

Text and typography properties set on `Main_Part` (i.e., without a `::part` selector) automatically **inherit** to sub-parts (`::label`, `::icon`, etc.) when those sub-parts don't explicitly set the property. This matches CSS cascade semantics where text properties flow from parent to child.

**Inheritable properties:** `color`, `font-family`, `font-size`, `font-weight`, `font-style`, `text-align`, `vertical-align`, `text-decoration`, `text-overflow`, `text-wrap-mode`, `line-height`, `white-space`, `cursor`, `visibility`, `list-style-type`, `list-style-image`, `list-style-position`.

**Non-inheritable properties** (box-model, layout, visual): `background-color`, `background-image`, `border-*`, `outline-*`, `padding`, `margin`, sizing, `display`, `position`, `overflow`, `opacity`, `box-shadow`, `flex-*`, `grid-*`, `transition`, etc.

`visibility` travels two axes. It inherits to sub-parts through the part cascade above, like any other inheritable property. It also descends the *widget* tree: `Adi.Window` resolves each widget's effective value against its parent widget's at paint and focus time, so a descendant's `visibility: visible` overrides a hidden ancestor.

Example:

```css
/* font-size and color inherit to ::label and ::icon automatically */
.title { font-size: 24px; color: white; }

/* explicit ::label overrides the inherited color */
.title::label { color: yellow; }
```

The authoritative set of inheritable properties is `Inheritable_Properties` in `adi-css_styles.ads`, and `Inherit_From` reads it: a property changes side there and nowhere else.

---

## Pseudo-Classes

### State Mapping

| CSS Pseudo-Class | Ada State | Notes |
|-----------------|-----------|-------|
| `:hover`, `:hovered` | `State_Hovered` | |
| `:active`, `:pressed` | `State_Pressed` | |
| `:focus`, `:focused` | `State_Focused` | |
| `:disabled` | `State_Disabled` | Inherited — applies when widget or any ancestor is disabled |
| `:enabled` | `When_Not(State_Disabled)` | Inherited — false when widget or any ancestor is disabled |
| `:checked`, `:selected` | `State_Selected` | |
| `:not(...)` | Negation | Single pseudo-class inside |

### Inherited Disabled State

The `:disabled` pseudo-class is **inherited through the widget hierarchy**. When a parent widget is disabled, all of its descendants are effectively disabled — both for interaction (no clicks, keyboard, or focus) and for visual styling (`:disabled` CSS rules apply).

- `Is_Disabled(W)` walks from `W` up through `W.Parent`, `W.Parent.Parent`, etc., returning `True` if any ancestor has `State_Disabled` set.
- `Get_States(W)` returns the widget's own states with `State_Disabled` injected when any ancestor is disabled. This is the state set used for CSS style resolution, so `:disabled` rules apply automatically to children of disabled containers.
- `Set_Disabled(W, True/False)` sets the widget's own `State_Disabled` flag and marks all descendants dirty so their styles are recomputed.
- A child that has its own `State_Disabled` flag set remains disabled even when its parent is re-enabled.

```ada
--  Disable an entire form container and all its children
Set_Disabled (Form_Box.all);

--  Re-enable the container; children without their own disabled flag
--  become enabled again
Set_Disabled (Form_Box.all, False);
```

### Placement Rules

Pseudo-classes can appear **before** or **after** a part selector, with different scoping:

**Before `::part`** — Widget-scoped state (the whole widget must be in that state):

```css
.combo:hover::indicator { color: blue; }     /* widget hovered → style indicator */
.list:hover::scroll { opacity: 1; }          /* widget hovered → show scrollbar */
```

**After `::part`** — Part-scoped state (the specific part must be in that state):

```css
.list::scroll:hover { background-color: gray; }   /* scroll track hovered */
.list::knob:pressed { background-color: black; }   /* knob being dragged */
```

For `::main`, interactive pseudos remain widget-scoped regardless of position:

```css
.button::main:hover { ... }   /* equivalent to .button:hover */
```

---

## Widget Properties

`:hover` and its siblings describe what a pointer and a keyboard are
doing. Domain state is the other half — an alarm row at ok, warning or
critical, a field valid, invalid or pending, a link connected, degraded
or offline — and a stylesheet selects on it by name:

```css
.alarm                      { background-color: #141414; }
.alarm[severity="warning"]  { background-color: #c8a000; }
.alarm[severity="critical"] { background-color: #c80000; }
.alarm[severity="critical"]:hover { background-color: #ff0000; }
.alarm[link]                { border-width: 3px; }
.alarm:not([severity="critical"]) { outline-width: 2px; }
```

The grammar is equality, existence and negation. `[severity]` matches a
widget that names the property, whatever it is set to;
`[severity="critical"]` matches the value. CSS has no not-equal
attribute operator, so "anything but" is written `:not([severity="critical"])`
— which also holds of a widget that names the property not at all, as it
does in CSS. `:not([severity])` is the other way round: it holds only
while the property is unset. Ordering (`[level>3]`) and the substring
matchers (`~=`, `|=`, `^=`, `$=`, `*=`) are refused by both pipelines,
being string scans rather than a choice among a bounded set.

A bracket condition scores 1 in the cascade, so
`[severity="critical"]:hover` scores 2 — the CSS ranking. A rule
carrying one is a state rule rather than the base style, and takes its
place among the `:hover` rules the same selector already has.

### Declaring the vocabulary

An application declares each property from an enumeration of its own,
at library level, where elaboration registers the property and every
literal:

```ada
with Adi.Widget_Properties.Enumerated;
pragma Elaborate_All (Adi.Widget_Properties.Enumerated);

package App_Properties is
   type Severity_Level is (Ok, Warning, Critical);

   package Severity is new Adi.Widget_Properties.Enumerated
     (Name => "severity", Values => Severity_Level);
end App_Properties;
```

A literal's CSS name is its image folded to lower case with underscores
as hyphens, so `Half_Open` answers to `half-open`. The vocabulary is
derived from the enumeration rather than written out a second time, and
a value's index is its position in it, so nothing is registered per
value and nothing looks one up: `Severity.Value (Critical)` is a
position the compiler already knows.

The value type is the enumeration, so mixing two properties' values
fails to compile:

```ada
App_Properties.Severity.Set (Row, App_Properties.Critical);
App_Properties.Severity.Set (Row, App_Properties.Offline);  --  no
```

Declaration happens at elaboration and nowhere else. That bound is what
buys the rest: the registry is a fixed set of arrays and a count, it
allocates nothing, and it is read-only for the whole of the run.
`Max_Properties` is 64 and `Max_Values_Per_Property` is 256; an
instantiation past either is refused whole and reported through
`Adi.Log`, and its property then selects nothing.

#### Keeping the names out

A name is what a stylesheet read at run time resolves against, and
nothing else needs one — a generated sheet names the constants, and the
constants are indices. A property that no dynamic sheet will name says
so, and its name and its values' names stay out of the registry
entirely:

```ada
package Quiet is new Adi.Widget_Properties.Enumerated
  (Name => "quiet", Values => Quiet_State, Dynamic_Lookup => False);
```

`Quiet.Set` and the generated sheet go on working; a dynamic sheet
spelling `[quiet="yes"]` fails to install, since the registry has no
`quiet` to resolve against. The gate sits at the property and covers its
values with it. The default is `True`, which is the safe one.

### Setting one on a widget

```ada
App_Properties.Severity.Set (Row, App_Properties.Critical);
App_Properties.Severity.Clear (Row);

if App_Properties.Severity.Is_Set (Row) then
   case App_Properties.Severity.Get (Row, Default => App_Properties.Ok) is
      ...
end if;
```

These take a `Widget_Handle`, as the rest of the widget API does. A
change invalidates the widget's style the way `Set_State` does, and
where no rule on the widget names a property it reaches no further than
the version bump.

Underneath, `Adi.Widget_Properties` holds a dense index per property and
the name beside it that dynamic mode resolves against. A `Property` is
that index; a `Property_Value` is that index and a position in the
property's enumeration. `Adi.Widget.Set_Property`/`Clear_Property`/
`Get_Property`/`Has_Property` take them directly, which is what
`Find_Property` and `Find_Value` hand the runtime parser. An application
reaches the same thing through the generic instead, and gets a distinct
value type per property for doing so.

The whole assignment is interned to one index, which the widget carries
and the resolved-style memo keys on beside the states it already holds.
Two widgets at the same value therefore share the style they resolve to,
and a widget naming no property carries the empty assignment and reads
exactly as one did before there were any.

### The generated pipeline

`tools/css_to_ada.py` reads the bracket as text and emits the
instantiation and the literal the application declared, given the
package that holds them:

```bash
python3 tools/css_to_ada.py app.css out.ads \
    --package-name App_Styles --properties-package App_Properties
```

```ada
--  from  .alarm[severity="critical"]
When_Property (App_Properties.Severity.Value (App_Properties.Critical))

--  from  .alarm[link]
When_Property_Set (App_Properties.Link.Id)

--  from  .alarm:not([severity="critical"])
When_Not_Property (App_Properties.Severity.Value (App_Properties.Critical))
```

The literal is named on its own and the instantiation it is handed to
resolves which enumeration it belongs to, so `[power="on"]` and
`[state="on"]` reach the right one each without the CSS having to
disambiguate. Both halves of a condition must be spelled from letters,
digits, hyphens and underscores, since both become part of an Ada
identifier.

A name the application never declared is a compile error at the
generated sheet. Dynamic mode answers the same question through the
registry: a sheet naming a property or a value that is not declared
fails to install, `Get_Last_Error` says which name, and the last good
sheet stays on the widgets — the behaviour a sheet past the state-rule
cap already has.

`tools/xml_to_ada.py` takes the same `--properties-package` flag for an
inline `<style>` block.

---

## Supported Properties

### Box Model

| Property | Values | Example |
|----------|--------|---------|
| `width` | length, `auto`, `fit-content` | `width: 200px;` |
| `height` | length, `auto`, `fit-content` | `height: 40px;` |
| `min-width` | length | `min-width: 100px;` |
| `max-width` | length | `max-width: 50%;` |
| `min-height` | length | `min-height: 24px;` |
| `max-height` | length | `max-height: 240px;` |
| `padding` | 1–4 lengths | `padding: 12px 24px;` |
| `padding-top/right/bottom/left` | length | `padding-left: 16px;` |
| `margin` | 1–4 lengths or `auto` | `margin: 0 auto;` |
| `margin-top/right/bottom/left` | length or `auto` | `margin-left: auto;` |

`auto` is a margin value only. `padding: auto` and `border-width: auto` are
invalid and both pipelines drop them.

Writing these groups as Ada rules: the whole-group forms name every side,
an aggregate names the sides it lists and leaves the rest to the cascade.
Margin has its own setters, since it is the one group that takes `auto`.

```ada
Padding      => Set (CSS_Box (Px (12.0))),
Margin       => Set_Margin (CSS_Box (Px (6.0))),
Margin       => [Bottom => Set_Margin_Side (Px (6.0)), others => <>],
Margin       => Set_Margin (Zero_Margin, Auto_Margin,   --  margin: 0 auto
                            Zero_Margin, Auto_Margin),
Border_Color => [Top => Set_Edge_Color (C (Red)), others => <>],
Border_Style => [Top => Set_Edge_Style (Dashed), others => <>],
```

A `min-width` above a `max-width` wins, and likewise for the heights — CSS 2.1 [§10.4](https://www.w3.org/TR/CSS21/visudet.html#min-max-widths). Both bound the size an element is *used* at, so neither can be escaped by a declared `width` or by a `flex-basis`.

> **What block layout does with a child's size.** A block container stacks its children down the content area, one under the next. A child takes the `width` and `height` it declares; without a `width` it spans the content area less its own margins, and without a `height` it takes its intrinsic height — which for a child with no content is none, so it does not expand to fill the container. Percentages on either axis resolve against the container's content box.
>
> A child narrower than the content area stays where the content starts unless its side margins say otherwise. `margin: 0 auto` centres it, one auto side margin pushes it to the other edge — CSS 2.1 [§10.3.3](https://www.w3.org/TR/CSS21/visudet.html#blockwidth). Neither `gap` nor `justify-content` reaches block layout. Use `display: flex` for anything the stack cannot express, and `flex-grow` to divide what is left over.
>
> Auto margins are distributed in block layout only. A flex child's auto margin counts as zero: Flexbox §8.1 gives it a different meaning, and that is not implemented.

#### What a percentage size resolves against

A percentage `width` or `height` needs a containing block, which only the layout has. `Get_Preferred_Size` and `Measure_At_Width` therefore report a percentage-sized axis as if it were `auto` and measure the content instead; the container resolves the percentage when it places the child.

| Layout mode | Axis | Basis |
|-------------|------|-------|
| Block | `height` | the container's content height, whether the container's own height was declared or came from its content |
| Block | `width` | the container's content width, on the same terms |
| Flex | cross size (`height` in a row, `width` in a column) | the line's cross size, taken from the container's content box |
| Flex | main size (`width` in a row, `height` in a column) | the container's content box. `flex-basis: 50%` and a `width: 50%` under the default `flex-basis: auto` both give the same base, since `auto` means *use the main size property*. That base is where `flex-grow`/`flex-shrink` start from, so a growing item still ends up larger. |
| Grid | `width`, `height` | the cell |

A flex container whose own main size is still being decided — the question a percentage would resolve against — has nothing to take a fraction of. The item falls back to its content size there, which is what CSS does with an unresolvable percentage.

`height: 100%` on a block child fills the container's content box, and `height: 50%` takes half of it, on every layout pass; `width` behaves the same way across the other axis. Unlike CSS 2.1 §10.5, the basis does not have to be a *declared* height: a container sized by its own content, or by the window, is still a basis. The alternative — treating the percentage as `auto` unless the container declares a height — would leave `height: 100%` at `0` for the common case of a root panel that the window sizes, which is the case that most needs to work.

### Borders

| Property | Values | Example |
|----------|--------|---------|
| `border` | shorthand (width style color) | `border: 1px solid #ccc;` |
| `border-top/right/bottom/left` | side shorthand (width/style/color in any order) | `border-top: 2px dashed red;` |
| `border-width` | 1–4 lengths | `border-width: 1px;` |
| `border-top/right/bottom/left-width` | length | `border-left-width: 4px;` |
| `border-color` | color value | `border-color: rgb(200,200,200);` |
| `border-top/right/bottom/left-color` | color value | `border-left-color: red;` |
| `border-style` | `none`, `solid`, `dashed`, `dotted`, `double`, `groove`, `ridge`, `inset`, `outset`, `hidden` | `border-style: solid;` |
| `border-top/right/bottom/left-style` | same as `border-style` | `border-bottom-style: dotted;` |
| `border-radius` | 1–4 lengths | `border-radius: 8px;` |
| `border-top-left/top-right/bottom-right/bottom-left-radius` | single length/percent | `border-top-left-radius: 10px;` |

Runtime (`Adi.CSS_Parser`) and compile-time (`css_to_ada.py`) both support `border` shorthand and side/corner longhands with standard declaration order semantics (later declarations win).
For asymmetric corners, prefer `border-radius` shorthand when possible (for example, top-only rounding: `border-radius: 8px 8px 0px 0px;`) and use corner longhands only for targeted overrides.
Corner radius longhands currently accept a single value only (elliptical two-value corner syntax is not supported yet).

> **Border-radius resolution**: each corner length is resolved through `Adi.Layout_Util.Resolve_Border_Radius_Px`, which routes the value through `Length_To_Px`. That means `border-radius: 8px` honours the `Set_Px_Maps_To_Dip` convention and the active DIP scale exactly like every other length property — `8px` on a Retina display where `Set_Px_Maps_To_Dip` is on resolves to `16` physical pixels, the same way `width: 8px` would. (The plain `Adi.CSS_Styles.Get_Border_Radius_Px` returns raw `.Amount` values and bypasses unit handling — don't use it for rendering; it exists only for legacy callers.)

### Colors

| Property | Values | Example |
|----------|--------|---------|
| `color` | color value | `color: white;` |
| `background-color` | color value | `background-color: rgb(30, 41, 59);` |
| `opacity` | 0.0–1.0 | `opacity: 0.7;` |

### Typography

| Property | Values | Example |
|----------|--------|---------|
| `font-family` | comma-separated names | `font-family: "Open Sans", sans-serif;` |
| `font-size` | length | `font-size: 16px;` |
| `font-weight` | `100`–`900`, `thin`, `extra-light`, `light`, `normal`, `medium`, `semi-bold`, `bold`, `extra-bold`, `black` | `font-weight: 700;` |
| `font-style` | `normal`, `italic`, `oblique` | `font-style: italic;` |
| `text-align` | `left`, `right`, `center`, `justify`, `start`, `end` | `text-align: center;` |
| `vertical-align` | `baseline`, `top`, `middle`, `bottom`, `text-top`, `text-bottom` | `vertical-align: middle;` |

> **Label horizontal alignment**: `Adi.Widget.Label` honours `text-align` by shifting the whole text block within its label-part slot, so it only shows where the slot is wider than the text. A label sized by its own padding has no spare room and is unaffected; a label with a declared width has. `justify` renders as `left`, and `end` as `right` — there is no RTL support yet. Wrapped text takes a different route: it has a wrap width, which is a box SDL understands, so the item asks the font cache for a variant carrying that alignment and SDL positions each line within the wrap width. A block offset could not do that, since the lines need moving independently. The two paths never overlap — the offset is zero whenever the item wraps.

> **Label vertical alignment**: `Adi.Widget.Label` honours `vertical-align` for positioning text within the assigned label-part slot. When a label sits in a flex-row container that stretches its slot taller than the text — the common case for a fixed-height button (`height: 36px; padding: 7px 16px; font-size: 13px` leaves the label slot taller than a single line of text) — the default `baseline` / `top` keeps text at the top of the slot (historical behaviour), `middle` centres it (typical button styling), and `bottom` / `text-bottom` pins it to the bottom. Add `vertical-align: middle` to your button's `::label` rule if the text otherwise looks "high".
| `text-decoration` | `none`, `underline`, `overline`, `line-through` | `text-decoration: underline;` |
| `line-height` | `normal`, number, length | `line-height: 1.5;` |
| `white-space` | `normal`, `nowrap`, `pre`, `pre-wrap`, `pre-line` | `white-space: nowrap;` |
| `text-overflow` | `clip`, `ellipsis` | `text-overflow: ellipsis;` |
| `text-wrap-mode` | `wrap`, `nowrap` | `text-wrap-mode: wrap;` |

#### Wrapping never breaks a word

Lines break at whitespace only. A box narrower than the widest word does not stack that word into fragments — the word is drawn past the edge, and clipping is then whatever `overflow` says. Every path agrees on this: `Adi.Widget.Effective_Wrap_Width` floors the wrap width at the widest word, and measurement, layout's re-measure pass and the renderer all wrap through it, so a container reserves the room the text will actually occupy.

There is no `overflow-wrap` or `word-break` property yet, so the behaviour cannot be opted out of. It approximates CSS `overflow-wrap: normal` rather than implementing it: flooring the whole column at the widest word also lets *shorter* words share a line wider than the box really is. Exact behaviour requires whitespace-aware line breaking and those two properties.

### Layout & Display

| Property | Values | Example |
|----------|--------|---------|
| `display` | `none`, `block`, `inline`, `inline-block`, `flex`, `inline-flex`, `grid`, `inline-grid` | `display: flex;` |
| `position` | `static`, `relative`, `absolute`, `fixed`, `sticky` | `position: relative;` |
| `top` | `auto`, length (`px`, `%`, `dp`/`dip`, `em`, `rem`, `vw`, `vh`) | `top: 10px;` |
| `right` | `auto`, length | `right: 20%;` |
| `bottom` | `auto`, length | `bottom: 5dp;` |
| `left` | `auto`, length | `left: auto;` |
| `overflow` | `visible`, `hidden`, `scroll`, `auto` | `overflow: auto;` |
| `overflow-x` | `visible`, `hidden`, `scroll`, `auto` | `overflow-x: hidden;` |
| `overflow-y` | `visible`, `hidden`, `scroll`, `auto` | `overflow-y: auto;` |
| `visibility` | `visible`, `hidden`, `collapse` | `visibility: hidden;` |

`overflow` is treated as shorthand only: it sets both `overflow-x` and `overflow-y`.
Resolved styles store only axis values (`Overflow_X`, `Overflow_Y`), and normal CSS order/override rules apply.

#### Position behavior

`position: static` (default) — normal flow, inset properties are ignored.

`position: relative` — child stays in normal flow. After placement, a visual offset is applied: `x += left - right`, `y += top - bottom`. Flow space is unchanged.

`position: absolute` — child is removed from flow (excluded from flex/grid sizing and placement). The containing block is the direct parent's content box. Inset offsets position the child within that box. If both horizontal insets are set and width is not explicit, width is derived as `content_width - left - right`. Same for vertical. If only `right` (or `bottom`) is set with a known size, the child anchors from that edge.

`fixed` and `sticky` are parsed but have no layout effect (deferred).

Inset properties (`top`, `right`, `bottom`, `left`) default to `auto` (meaning "not set"). The `auto` keyword is supported and parsed explicitly. An inset set to `auto` has no positional effect; only `Fixed` insets (concrete lengths or percentages) participate in offset and sizing calculations.

### Visibility And Participation

Adi distinguishes hard-hide and soft-hide behavior:

| Mechanism | Layout | Paint | Hit/Focus | Notes |
|----------|--------|-------|-----------|-------|
| `Set_Flag(..., Visible, False)` | no | no | no | Imperative hard hide; subtree excluded |
| Main-part `display:none` | no | no | no | CSS hard hide; subtree excluded |
| `visibility:hidden` | yes | no | no | Soft hide; descendants may override with `visibility:visible` |
| `visibility:collapse` | yes | no | no | Alias of `hidden` |

Additional part behavior:

- `display:none` on a `::part` removes that part from rendering and from internal part layout (for widgets that have internal part layout, e.g. label/combo).
- `visibility:hidden` on a `::part` keeps its layout slot but suppresses rendering/interaction.

### Flexbox Container

| Property | Values | Example |
|----------|--------|---------|
| `flex-direction` | `row`, `row-reverse`, `column`, `column-reverse` | `flex-direction: column;` |
| `flex-wrap` | `nowrap`, `wrap`, `wrap-reverse` | `flex-wrap: wrap;` |
| `justify-content` | `flex-start`, `flex-end`, `center`, `space-between`, `space-around`, `space-evenly` | `justify-content: center;` |
| `align-items` | `flex-start`, `flex-end`, `center`, `baseline`, `stretch` | `align-items: stretch;` |
| `align-content` | `flex-start`, `flex-end`, `center`, `space-between`, `space-around`, `stretch` | `align-content: center;` |
| `gap` | one or two lengths (`row column`) | `gap: 12px;` / `gap: 4px 14px;` |
| `row-gap` / `column-gap` | length | `row-gap: 4px;` |

Both axes live in a single `Gap` value, which records *which* axes a rule named. Merging is therefore per axis, within a rule and across the cascade alike — a rule saying only `row-gap` leaves the column gap alone:

```css
.base    { gap: 10px; }        /* both axes */
.compact { row-gap: 4px; }     /* rows only */
/* class="base compact" → 4px between rows, 10px between columns */
```

Building rules in Ada follows the same shape: `Gap (L)` and `Gap (Row, Column)` name both axes, while `Gap_Row (L)` / `Gap_Column (L)` name one and leave the other for whatever the cascade already established.

### Flexbox Item

| Property | Values | Example |
|----------|--------|---------|
| `flex-grow` | number | `flex-grow: 1;` |
| `flex-shrink` | number | `flex-shrink: 0;` |
| `flex-basis` | `auto`, `content`, length | `flex-basis: 200px;` |
| `align-self` | `auto`, `flex-start`, `flex-end`, `center`, `baseline`, `stretch` | `align-self: center;` |
| `order` | integer | `order: -1;` |

`margin: auto` parses on a flex child but does nothing there: the side counts as zero. Flexbox [§8.1](https://www.w3.org/TR/css-flexbox-1/#auto-margins) has an auto margin absorb all free space *before* `justify-content` runs and suppress it entirely, which the distribution pass does not implement. Reach for `justify-content`, a `flex-grow: 1` spacer, or a nested flex box instead. Block layout does distribute auto margins — see the box-model section.

Two of those values are accepted but not yet acted on:

- **`baseline`** (on `align-items` and `align-self`) falls back to `flex-start`. Aligning to a shared baseline needs per-item text metrics the flex pass does not collect.
- **`order`** is parsed and resolved but never reorders anything; items lay out in document order.

### Grid

| Property | Values | Example |
|----------|--------|---------|
| `grid-template-columns` | track list or `repeat(N, size)` | `grid-template-columns: auto auto 1fr;` |
| `grid-template-rows` | column count or `repeat(N, ...)` | `grid-template-rows: repeat(2, 1fr);` |
| `grid-column` | start / span | `grid-column: 2;` |
| `grid-row` | start / span | `grid-row: 1 / span 2;` |

#### `grid-template-columns` track sizing

Column tracks can be specified as a space-separated list of sizing tokens, or via `repeat()`:

| Token | Meaning |
|-------|---------|
| `auto` | Column sizes to fit its content |
| `Xfr` | Column takes a fractional share of remaining space (e.g. `1fr`, `2fr`) |
| `Xpx` | Column has a fixed pixel width, following the `px` convention |
| `Xpix` | Column is exactly X renderer pixels |
| `repeat(N, size)` | Expand `size` token N times |

Mixed forms are supported — `repeat(3, auto) 1fr` is equivalent to `auto auto auto 1fr`.

Examples:

```css
/* Three content-sized columns then one stretching column */
grid-template-columns: auto auto auto 1fr;

/* Two equal stretching columns */
grid-template-columns: repeat(2, 1fr);

/* Fixed sidebar + content area */
grid-template-columns: 200px 1fr;

/* Uniform 3-column grid (legacy form, same as repeat(3,1fr)) */
grid-template-columns: 3;
```

**Sizing semantics:**
- `auto` columns are sized to the maximum preferred width of their single-span children; they expand for `min-width` constraints.
- `fr` columns receive a proportional share of the space left after all `auto` and `px` columns are sized. During content measurement (e.g. when the grid is inside a flex parent and sized by its content), `fr` columns contribute their children's intrinsic minimum width — not the full preferred width. This follows CSS `minmax(auto, Xfr)` semantics: the grid is wide enough to display `fr` content at its minimum, but `fr` columns remain shrinkable so text can wrap when the container is constrained.
- The column count used by item placement (`Grid_Columns`) is always kept in sync with the track list length.

**Ada static form** (generated by `css_to_ada.py` and usable directly in Ada):

```ada
Grid_Column_Tracks => (Count => 4,
                       Tracks => [1 => (Track_Auto, 0.0),
                                  2 => (Track_Auto, 0.0),
                                  3 => (Track_Auto, 0.0),
                                  4 => (Track_Fr,   1.0),
                                  others => <>])
```

### Outline

Outline is drawn outside the border box without affecting layout — ideal for focus indicators.

| Property | Values | Example |
|----------|--------|---------|
| `outline` | shorthand (width style color) | `outline: 2px solid rgb(208, 188, 255);` |
| `outline-width` | length | `outline-width: 3px;` |
| `outline-style` | `none`, `solid`, `dashed`, `dotted` | `outline-style: solid;` |
| `outline-color` | color value | `outline-color: rgb(100, 200, 50);` |
| `outline-offset` | length | `outline-offset: 2px;` |

Unlike `border`, outline does not shift surrounding content and respects `border-radius` for rounded widgets.

### Visual Effects

| Property | Values | Example |
|----------|--------|---------|
| `box-shadow` | offset-x offset-y blur spread color | `box-shadow: 0 4px 12px rgba(0,0,0,0.2);` |
| `cursor` | `auto`, `default`, `pointer`, `text`, `move`, `not-allowed`, `wait`, `crosshair`, `grab`, `grabbing`, `ns-resize`, `ew-resize`, `nesw-resize`, `nwse-resize` | `cursor: pointer;` |

### Background Images

| Property | Values | Example |
|----------|--------|---------|
| `background-image` | `none`, `url(...)`, `linear-gradient(...)` | `background-image: linear-gradient(to bottom, #fff, #000);` |

#### Linear gradients

`linear-gradient()` fills the widget background with a color gradient. The gradient
renders *over* `background-color`, so alpha gradients composite over a solid color.

```css
.card   { background-image: linear-gradient(to bottom, #eee, #aaa); }
.btn    { background-image: linear-gradient(to right, rgb(30,100,200), rgb(10,50,120)); }
.diag   { background-image: linear-gradient(45deg, red, blue); }
.multi  { background-image: linear-gradient(to bottom, red 0%, green 50%, blue 100%); }
```

**Supported syntax:**

| Feature | Supported | Not supported |
|---------|-----------|---------------|
| Direction keywords | `to top`, `to right`, `to bottom` (default), `to left`, `to top right`, `to bottom right`, `to bottom left`, `to top left` | — |
| Angle units | `deg`, `rad`, `grad`, `turn` | — |
| Stop colors | named, `#rrggbb`, `#rgb`, `rgb()`, `rgba()` | `hsl()`, `hwb()`, `oklch()` |
| Stop positions | `<n>%`; omit for auto-distribution | `px`, `em`, other length units |
| Max stops | 16 | — |
| Color hints | not supported (`red, 30%, blue` midpoint syntax) | — |
| `repeating-linear-gradient()` | not supported | — |
| `radial-gradient()` | not supported | — |

**Rounded-rect limitation:** 3+ stops on non-axis-aligned rounded rects may show
per-triangle color artifacts (fan triangulation is not geometrically exact for
multi-stop gradients).

#### URL images

Background images are resolved via `Adi.Assets.Get_Image` — the URI is looked up in the registered asset search paths. Register paths before widget creation:

```ada
Adi.Assets.Add_Path ("assets");
Adi.Assets.Add_Path ("assets/images", Scheme => "app");
```

Then use in CSS:

```css
.hero { background-image: url(hero.jpg); object-fit: cover; }
.icon-panel { background-image: url(app://panel-bg.png); }
```

Plain paths (e.g. `bg.jpg`) search directories registered with an empty scheme. Scheme URIs (e.g. `app://panel-bg.png`) search directories registered with that scheme.

Images are loaded as CPU surfaces and GPU textures are created lazily at render time — no renderer dependency at style/load time.

#### Sprite and crop URLs

`Get_Image` accepts query parameters in the URL to extract regions or symbols from larger source images:

| Syntax | Mode | Example |
|--------|------|---------|
| `file.svg?id=name` | SVG sprite — extract `<symbol id="name">` from the sprite sheet | `url(icons.svg?id=home)` |
| `file.png?x=N&y=N&w=N&h=N` | Raster crop — extract a pixel rectangle from the source | `url(tileset.png?x=0&y=32&w=16&h=16)` |
| `file.png?render=pixelated` | Texture scale mode — `pixelated`, `nearest`, or `linear` | `url(tile.png?render=pixelated)` |

Parameters can be combined: `url(tileset.png?x=0&y=0&w=16&h=16&render=pixelated)`.

SVG sprite images are tintable by default — CSS `color` applies as a tint. Raster crop coordinates are clamped to source image bounds. The source sprite sheet or image is cached and shared across all extractions from the same file.

### Image Sizing

| Property | Values | Example |
|----------|--------|---------|
| `object-fit` | `fill`, `contain`, `cover`, `none`, `scale-down` | `object-fit: cover;` |
| `object-position` | `center`, keyword pairs (`left top`, `top center`, ...), or 1-2 length/percent offsets | `object-position: center center;` |

`object-position` intentionally supports the common forms above; advanced mixed edge-offset forms are currently rejected.

#### Tintable images

Images loaded with `Tintable => True` (via `Load_SVG_Path`, `Load_SVG_From_String`, `SVG_Sprites.Get_Image`, or the `?id=` sprite URL syntax) are rendered white-on-transparent. The renderer automatically applies the resolved CSS `color` as a tint using SDL hardware color modulation (multiply). This lets standard CSS `color` — including `:hover` and class-based overrides — control icon color:

```css
.my-label::icon { color: #333; }
.my-label:hover::icon { color: #0088ff; }
```

Since `color` is an inheritable property, setting it on the widget makes `::icon` parts inherit it automatically:

```css
.toolbar-btn { color: #666; }
.toolbar-btn:hover { color: white; }
/* ::icon inherits the color */
```

### List Styling

| Property | Values | Example |
|----------|--------|---------|
| `list-style` | shorthand | `list-style: disc inside;` |
| `list-style-type` | `none`, `disc`, `circle`, `square`, `decimal`, custom string | `list-style-type: circle;` |
| `list-style-image` | `url(...)` | `list-style-image: url(icon.png);` |
| `list-style-position` | `outside`, `inside` | `list-style-position: inside;` |

### Transitions

| Property | Values | Example |
|----------|--------|---------|
| `transition` | property duration [easing] | `transition: background-color 200ms ease-out;` |

Transition syntax:

```css
transition: <property> <duration> [easing];
transition: background-color 200ms ease-out;
transition: all 300ms ease-in-out;
transition: color 150ms ease-out, background-color 150ms ease-out;
```

Animatable properties: `all`, `color`, `background-color`, `border-color`, `border-width`, `border-radius`, `padding`, `margin`, `opacity`, `box-shadow`, `font-size`.

Layout-affecting properties (`padding`, `margin`, `border-width`, `font-size`) trigger relayout during animation. Visual-only properties (`color`, `background-color`, `border-color`, `border-radius`, `opacity`, `box-shadow`) trigger repaint only, avoiding the cost of full relayout.

Easing functions: `linear`, `ease`, `ease-in`, `ease-out`, `ease-in-out`.

Duration formats: `100ms`, `0.3s`.

---

## Value Types

### Lengths

| Unit | Description |
|------|-------------|
| `px` | Physical pixels by default (and the default when no unit is given), but **logical when `Adi.Layout_Util.Set_Px_Maps_To_Dip` is enabled**, in which case it scales exactly like `dp`. |
| `pix` | **Always physical pixels**, 1:1 with the framebuffer. An Adi extension, not CSS. Ignores the display scale, the UI scale and the `px` → dip mapping, so `1pix` is one renderer pixel on every display and under every setting. A font size in `pix` still takes the accessibility text scale. |
| `dip` / `dp` | **Always** density-independent pixels. Multiplied by the current OS display scale and app-level UI scale, so `1dp` is one CSS-style "logical pixel" (≈ one pixel on a 1× display, two on a 2× Retina, etc.). |
| `em` | Relative to element font size |
| `rem` | Relative to the window root font size (default `16px`). Set programmatically via `Adi.Window.Set_Root_Font_Size(W, Length_Value)`, or drive it from CSS with `Adi.CSS_Source.Attach_Window(Source, W)` + `:root { font-size: ... }`. |
| `%` | Percentage of parent |
| `vw` | Viewport width percentage |
| `vh` | Viewport height percentage |

`dp`/`dip` lengths follow the active OS display scale and the current app-level UI scale. Font-related length conversion also applies the current text scale. Application code should normally set those user scales via `Adi.Window.Set_UI_Scale` and `Adi.Window.Set_Text_Scale`.

The root font size (for `rem`) is stored per-window as a `CSS_Styles.Length_Value` and re-evaluated every frame, so expressing it in `dip` units (e.g. `16dip`) keeps `rem`-based sizes correctly scaled across monitor changes. Use `Set_Root_Font_Size` to set it directly, or call `CSS_Source.Attach_Window` to have `:root { font-size }` in the stylesheet drive it automatically — including on hot-reload.

### Pixels and high-DPI displays

The Adi runtime exposes **physical pixels everywhere**: widget geometry, mouse coordinates, viewport size, the renderer's coordinate system. Windows are created with `SDL_WINDOW_HIGH_PIXEL_DENSITY` and the renderer runs with `SDL_LOGICAL_PRESENTATION_DISABLED`, so `1` render unit = `1` physical pixel — no logical-point↔pixel stretch step that would soften glyphs on Retina/HiDPI screens.

That makes the unit story simple:

- Use **`pix`** when you mean *exactly N renderer pixels* whatever else is configured: hairlines (`1pix` borders), pixel-snapped icon work. It is the only unit that survives `Set_Px_Maps_To_Dip`, so reach for it rather than `px` if the application enables that mapping — under it, `1px` is no longer one pixel.
- Use **`px`** for values that should follow whichever convention the application chose. With the mapping off it means device pixels; with it on it behaves as `dp`.
- Use **`dp` / `dip`** for everything that should look the same physical size on every display: padding, gaps, icon sizes, font sizes, control heights. On a 2× Retina display, `16dp` resolves to 32 pixels and looks the same physical size as `16dp` on a 1× display.
- Use **`rem`** to chain off a single density-aware root size. The standard pattern is:

  ```css
  :root {
    font-size: 18dp;
    --font-body: 1rem;
    --font-title: 1.33rem;
  }
  ```

  The root font size is `dp`, so it scales with display density, and every `rem`-based size inherits that scale automatically.

**Static-styles caveat.** When CSS is consumed via `tools/css_to_ada.py` and applied through generated `*_Styles` packages (rather than `Adi.CSS_Source.Set_CSS_File` at runtime), `:root { font-size }` is **not** auto-applied to the window — the runtime `CSS_Source` attach path is what wires that up. Until that gap is closed at the codegen level, examples that rely on `rem` and use static styles must call `Adi.Window.Set_Root_Font_Size (W, <Pkg>.Root_Font_Size)` themselves before the first frame. Generated packages expose `Has_Root_Font_Size` / `Root_Font_Size` for exactly this purpose.

### Why `px` is honest (≠ browser/Qt/GTK)

Browsers, Qt and GTK all redefine `px` to mean a *logical* pixel that the renderer scales by the display ratio. This works cleanly on Apple's 2× and 3× integer Retina scales — `1 logical px` always lands on a device-pixel boundary. It falls apart on **fractional** scales (Windows 125 % / 150 % / 175 %, mid-range Android densities, some Linux setups):

- A `1px` border rounds to 1 or 2 device pixels — neither is the intended hairline. Stack three and you get 4.5 → uneven edges depending on rounding.
- Snap-to-pixel rendering (charts, grids, alignment lines, icon strokes) becomes impossible without escape hatches, because every `px` silently shifts off the device-pixel grid. This is the "blurry borders on Windows @ 125 %" problem that Qt and browsers paper over with subpixel positioning and snap heuristics.

Adi's split makes the contract unambiguous per property: `border: 1pix;` is *one device pixel, snapped to the grid* on every display and under every scale setting; `padding: 16dp;` is *approximate physical size, OK with rounding*; `px` sits between them, following the application's `Set_Px_Maps_To_Dip` choice. No global mode switches, no per-display surprises. The cost is a muscle-memory mismatch for web/Qt refugees — `1px` looks hairline-thin on Retina until you reach for `dp` instead.

### Treating CSS `px` as logical pixels

The split above (physical `px` vs density-independent `dp`) is one valid design. The other is the web convention: `px` is a *logical* unit that the runtime scales by display density automatically, and the application never writes `dp` at all. Adi exposes that as a single per-app toggle in `Adi.Layout_Util`:

```ada
with Adi.Layout_Util;
...
begin
   App.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);   --  CSS px now behaves like dp
   ...
```

When the flag is on, `Length_To_Px` resolves every `px` value as `Amount * Active_DIP_Scale * Active_UI_Scale` — identical to how `dp` resolves. `1px` on a 2× Retina display becomes 2 device pixels; `1px` borders, paddings and font sizes all scale uniformly with the display.

The two designs are equally specific — pick one per app:

| Design | CSS spells it as | Mental model |
|---|---|---|
| Physical `px` + explicit `dp` | `border: 1px;` `padding: 16dp;` | Each property states the convention it wants; hairlines stay hairline on every display. `material_demo` and `font_example` use this style. |
| Logical `px` only (toggle on) | `border: 1px;` `padding: 16px;` | Browser/Qt-style; CSS reads naturally to web refugees; everything scales together. The other ~20 bundled examples use this style. |

The toggle is a process-global call — there is no per-widget or per-stylesheet switch — so the convention is chosen once at startup and applies to every `px` value the runtime resolves from then on. The visible consequence is that `1px` and `1dp` become equivalent: any CSS or Ada code that relies on the distinction (e.g. `font_example`'s side-by-side `Px(18)` "fixed pixels" vs `Dip(18)` "display-scale aware" samples) renders identically once the toggle is on, which is why `font_example` deliberately leaves it off.

`Adi.Layout_Util` also exposes `Pixels_As_Length (P : Pixel_Type) return Length_Value` for widgets that pre-resolve a length to its final pixel count and need to stash that value in a `Length_Value` field (e.g. an item's `Style_Override.Font_Size`) without it being scaled a second time when the rendering pipeline calls `Length_To_Px` again. The HTML view uses this for its measure→render handoff; new widgets following the same pattern should use it too.

### Colors

| Format | Example |
|--------|---------|
| Named | `red`, `aliceblue`, `transparent` (140+ SVG color names) |
| Hex | `#RGB`, `#RRGGBB`, `#RRGGBBAA` |
| RGB | `rgb(255, 128, 0)` |
| RGBA | `rgba(255, 128, 0, 0.5)` |

Special keywords: `transparent`, `inherit`, `currentcolor`.

### Text

Four properties name text: the `url()` path of `background-image` and
`list-style-image`, the quoted marker of `list-style-type`, and the
whole `font-family` fallback list. A style holds each as an index into
a store the library interns them in, so equal text is one entry however
many rules spell it.

A value carries up to `Adi.CSS_Styles.Max_CSS_Text_Length` characters,
4096. The generator and the runtime parser hold the same figure and
drop a declaration naming more, reporting it — the generator as an
`invalid-property-value` diagnostic, the parser through `Adi.Log`. Ada
code calling `Background_Image_URL`, `List_Image`, `List_String` or
`Set_Font_Family` past the limit gets the absent value back, with the
same report.

The selector name a binding is held under goes through the same store, so
the same limit applies to it. `Bind`, `Bind_Class` and
`Bind_Selector_Set` refuse a name past it and report through `Adi.Log`:
the binding would read back as the empty selector on every replay, which
would style the widget once and unstyle it at the next reload. One name
over the limit refuses a whole `Bind_Selector_Set`, since the three names
are one styling decision. `Apply` and its variants take the name itself
and remember nothing, so they are unaffected by the limit.

---

## Custom Properties

Adi supports a simplified CSS custom property model for DRY token authoring. Custom properties are resolved at parse time (in both the Python generator and the Ada runtime parser) before any rule processing occurs.

### `@property` — Defaults

Declare default values for custom properties:

```css
@property --primary { initial-value: #3b82f6; }
@property --radius  { initial-value: 8px; }
```

`@property` blocks are stripped from the CSS after collecting defaults. Only `initial-value` is recognized.

### `:root` — Overrides

Override defaults (or define new tokens) in a `:root` block:

```css
:root {
  --primary: #ef4444;
  --spacing: 16px;
  font-size: 18dp;
  color: #e5e7eb;
}
```

`:root` values override `@property` defaults. Normal (non-custom) properties inside `:root` are treated as **stylesheet root metadata**:

- they can be applied once to the app's root widget
- `font-size` also defines the `rem` base for the stylesheet

The `:root` block itself is still stripped and does not produce a normal selector in the tag/class/id rule tables.

### `var()` — Substitution

Reference tokens in any declaration value:

```css
.card {
  background-color: var(--primary);
  border-radius: var(--radius);
  padding: var(--spacing) var(--spacing);
}
```

Resolution rules:
- `var(--name)` — substitutes the value if defined; left as-is with an `unresolved-variable` diagnostic if undefined
- `var(--name, fallback)` — substitutes if defined; uses the fallback value otherwise
- Fallbacks may contain nested `var()` references: `var(--a, var(--b))`
- Recursive references are resolved iteratively (up to 10 passes)
- Cyclic references are bounded and left unresolved

### Scope Restrictions

Custom properties use a flat, root-scoped model (no per-selector inheritance):

- Custom property declarations (`--name: value`) are only meaningful inside `:root`
- Custom properties in non-`:root` selectors are stripped with a `non-root-custom-property-ignored` diagnostic
- `var()` resolves from the single root-scoped map only

### Ada Access

- Runtime (`Adi.CSS_Parser`, `Adi.CSS_Source`): custom properties are available by string name via `Has_Custom_Property` / `Get_Custom_Property`
- Generated CSS (`css_to_ada.py`): parseable root custom properties emit typed `Var_*` Ada accessors (for example lengths, colors, quoted strings as Ada `String`), and generated packages expose `Root_Metadata`

### Diagnostics

| Code | Meaning |
|------|---------|
| `unresolved-variable` | `var(--name)` with no fallback and no definition |
| `var-resolution-depth-exceeded` | `var()` still present after 10 resolution passes (cycle or deep nesting) |
| `non-root-custom-property-ignored` | `--name` declaration outside `:root` |

---

## Composing a Style in Ada

`Adi.Widget_Styles` offers a second way to write a style, beside the
`Style_Rules` aggregate the generator emits: a chain that names one
property at a time.

```ada
Primary : constant Widget_Style :=
   Style_Of
      .Background (RGB (37, 99, 235))
      .Padding    (CSS_Box (Px (12.0), Px (24.0)))
      .Radius     (Radius (Px (6.0)))
   .On_Hover
      .Background (RGB (29, 78, 216))
   .Build;

Set_Part_Style (W, Main_Part, Primary);
```

Each setter takes its own property's value type, so `Background (Px (14.0))`
is a compile error where `Background (RGB (37, 99, 235))` is not — more
checking than an aggregate gives, since `others => <>` has nothing to say
here.

Setters are named for their properties, with two exceptions: `color` is
spelled `.Text_Color` and `cursor` is spelled `.Cursor_Style`. Both plain
names are taken by a *type* elsewhere — `Adi.Core.Color`, and the `Cursor`
every `Ada.Containers` instantiation declares — and where a type and a
subprogram of one name are both use-visible, neither is, so the
application's own use of the name stops compiling. The chain itself is
immune either way, since a prefixed call resolves against the type's
primitive operations rather than through use-visibility; it is the
surrounding code that pays. `.Text_Color` also matches what the library
calls the field internally and sits beside `.Border_Color` and
`.Outline_Color`.

`Style_Of` opens a chain, `.On (Selector)` and the `.On_Hover`,
`.On_Press`, `.On_Focus`, `.On_Disabled`, `.On_Selected` and `.On_Normal`
shorthands move the active rule, `.On_Base` moves back to the base rule,
and `.Build` interns what the chain named and answers the same four-byte
`Widget_Style` the aggregate path answers.

The two paths agree exactly. Interning is canonical, so a style written
either way is one entry and one handle:

```ada
From ((Background_Color => Set_Bg (RGB (37, 99, 235)), others => <>)).Build
  =  Style_Of.Background (RGB (37, 99, 235)).Build
```

A selector the chain has already named is that rule again rather than a
second one, so `.On_Hover` twice fills one rule.

`gap` is the one property whose setter does not simply overwrite. One
field carries both axes, so `.Gap (Gap_Row (…))` overlays its own axis
and leaves the other as it was, while `.Gap (Gap (…))` names both and
replaces them — the same reading `Adi.CSS_Parser` gives `row-gap`,
`column-gap` and `gap`.

### Clearing, and deriving

A setter says "set" by existing, so clearing has a spelling of its own:

```ada
Style_Of (Primary) .Clear (Prop_Background_Color) .Build
```

`Clear` is the CSS cascade's "named, and holding no value", which stops a
rule earlier in the cascade showing through; it is not the same as never
naming the property.

`Style_Of (Existing)` opens a chain on a style already interned, which is
the composer's answer to `Base with delta Background_Color => …`:

```ada
Danger : constant Widget_Style :=
   Style_Of (Primary) .Background (RGB (200, 30, 30)) .Build;
```

The base's other properties stand, the state rules come through, and
`.On_Hover` on a derived chain reaches the rule the base already carries
rather than adding one beside it.

### What a chain costs

A chain step is a slot of eight bytes — the rule it names, the
`CSS_Property` that says how the value reads, and a four-byte value
reference — where the aggregate for the same rule materialises a whole
`Style_Rules`, 1,072 bytes on x86-64. A rule naming three properties, the
mean across the stylesheets in this repository, spends 24 bytes against
1,072.

The slots live in a fixed pool of `Max_Open_Chains` (8) buffers of
`Max_Chain_Slots` (64) slots each, so the composer itself is 24 bytes and
a chain step copies that rather than the slots. Ada evaluates an argument
before the call it belongs to, which is what the eight buffers are for: a
chain nested inside another holds a buffer beside it.

A chain is linear. Every value in it names one buffer, so branching off
an earlier step appends to the same chain rather than starting a second.

### When a chain does not finish

A chain ends in `.Build` or in `.Discard`, either of which returns its
buffer. One that ends in neither leaves its buffer held — and that needs
no mistake to happen, because Ada evaluates a setter's argument after
`Style_Of` has taken the buffer:

```ada
Style_Of.Background (RGB (R, G, B)).Build   --  R negative raises here
```

`Constraint_Error` from `RGB` arrives before any setter runs, and the
buffer is gone.

So a chain opening on a full pool **takes back the buffer held longest**
rather than doing without. A chain lives for one expression, so the
oldest is overwhelmingly one that was abandoned. `Acquire` raises that
buffer's serial, so the chain it was taken from reads as holding no
buffer rather than as sharing this one: its steps become no-ops, and its
`.Build` answers the style it opened on — the overrides it named did not
apply. A `Style_Of` chain answers `Empty_Widget_Style` that way, and a
`Style_Of (Primary)` chain answers `Primary`.

The answer is plausible rather than wrong, which is the awkward part: no
exception is raised and the style is a real one. Two things make it
visible. `Is_Live (C)` asks directly — false once `.Build` or `.Discard`
has returned the buffer, and false for a chain whose buffer was taken
back. And the reclaim is reported twice: once at the chain that did the
evicting, and once at the evicted chain's own `.Build`, which is the call
site that received the substituted answer.

Past `Max_Chain_Slots`, a step is dropped and the chain builds what fits.

All of it is reported through `Adi.Log`, which is a no-op outside a
development build, so the counters are the diagnosis that survives into a
shipped binary: `Open_Chains`, `Reclaimed_Chains` and
`Dropped_Chain_Slots`, carried in `perf_stats` under `style_chains`
alongside the pool's two capacities. Either counter above zero says a
chain somewhere is not finishing, or is naming more properties than a
buffer holds.

### What the chain spends

The slot write carries GNAT's `Local_Restrictions => (No_Secondary_Stack,
No_Heap_Allocations)`, as do the buffer mechanics — taking a buffer,
returning one, reclaiming the oldest. The compiler holds that rather than
a comment asserting it. Two things sit outside: reporting a dropped step
or a reclaimed buffer builds a message, which is what spends the
secondary stack, and interning a value the stores have not seen appends
to a vector. A chain whose values are already interned, and which drops
nothing, allocates nothing.

GNAT charges a call to its caller unless the callee declares the same
restriction, which is why the reporting is a subprogram of its own rather
than an `if` inside the slot write.

### Value references

A setter interns its argument into the store for that value's own type
and keeps a four-byte `Adi.CSS_Styles.Value_Ref`. `Intern` is overloaded
per value type, so the argument picks the store.

A value narrow enough sits in the reference itself and reaches no store:
an enumeration, a named colour, an `rgb()` triple in eight bits a
channel, a length or a flex factor whose magnitude is a whole number
below 65,536. Everything else — an alpha, a fraction, a negative, a
`CSS_Box_Value`, a `Border_Color_Value`, a `Box_Shadow_Value` — is an
index into a per-type store, where equal values share one entry, so
`RGBA (0, 0, 0, 0.25)` named in six rules is one. `Is_Stored` says which
a reference is, and `Interned_Values` and `Interned_Value_Bytes` report
what the stores hold.

### Which properties compose

`Adi.CSS_Styles.Composable_Properties` names the 34 properties the chain
carries, chosen by use: the 30 most named across the 32 stylesheets in
this repository, less `outline` — a shorthand owning no field — and
`background-image`, whose value is text or a gradient, plus the six that
complete a group already there. `Clear` on a property outside
that set is reported through `Adi.Log` and leaves the chain alone; there
is no setter for one, so the compiler answers first.

The aggregate path stays as it is, and the generator still emits it.

---

## Compile-Time Generation

### Invocation

```bash
python3 tools/css_to_ada.py input.css output.ads --package-name=My_Styles
python3 tools/css_to_ada.py input.css output.ads --package-name=My_Styles --strict
```

Incremental generation for all examples via `tools/generate_example_styles.sh`.

### Validation Modes

- **Default mode** (no `--strict`): unsupported properties, unsupported `::part` names, and invalid values produce warnings on `stderr`; generation continues.
- **Strict mode** (`--strict`): any warning-level diagnostic fails generation (exit code `1`) and no output file is written.

### Generated Code Structure

For each CSS selector, the generator produces three layers of constants:

**1. Style_Rules** — Individual style declarations per selector+state+part:

```ada
Button_Class_Base_Style : constant Style_Rules := (
   Display => Set (Inline_Flex),
   Background_Color => Set_Bg (RGB (59, 130, 246)),
   Border_Radius => Set (Radius (Px (6.0))),
   Padding => Set (CSS_Box (Px (12.0), Px (24.0))),
   Cursor => Set (Pointer),
   others => <>
);

Button_Class_Widget_Hovered_Style : constant Style_Rules := (
   Background_Color => Set_Bg (RGB (37, 99, 235)),
   others => <>
);
```

**2. Widget_Style** — Fluent builder combining base + state rules:

```ada
Button_Class_Widget : constant Widget_Style :=
  From (Button_Class_Base_Style)
  .On (When_State (State_Hovered), Button_Class_Widget_Hovered_Style)
  .On (When_State (State_Pressed), Button_Class_Widget_Pressed_Style)
  .Build;
```

A `Widget_Style` is a four-byte handle into a store the library keeps.
`.Build` interns what the chain named and answers the handle; interning
is canonical, so equal chains share one entry and comparing two handles
compares two styles. `Adi.Widget_Styles.Definition` reads the stored form
back as a `Style_Definition`, which is the record `.On` fills in: a base
rule set and up to `Adi.Widget_Styles.Max_Style_Rules` (16) state rules,
each naming its `Style_Rules` by handle too.

`Add_Rule`, and so `.On`, raises `Too_Many_Style_Rules` past the cap,
naming the state selector that did not fit; `tools/css_to_ada.py` refuses
to generate a longer chain, naming the CSS selector; the runtime parser
rejects the sheet and keeps the last good one; and a merge of two styles,
which has nowhere to report to, drops the rule and logs it.

**3. Part_Style_Array** — Bundle of all parts for a selector:

```ada
Button_Class_Part_Styles : constant Part_Style_Array := [
   Main_Part => (Style => Button_Class_Widget, Enabled => True),
   Label_Part => (Style => Button_Class_Label_Widget, Enabled => True),
   Icon_Part => (Style => Button_Class_Icon_Widget, Enabled => True),
   others => <>
];
```

### Naming Conventions

Generated constant names follow the pattern:

- `{Selector}_Class_{Part}_{State}_Style` — Style_Rules
- `{Selector}_Class_{Part}_Widget` — Widget_Style
- `{Selector}_Class_Part_Styles` — Part_Style_Array

For ID selectors, `_Class_` becomes `_Id_`; for tag selectors, `_Tag_`.

Repeated blocks for the same selector/state are merged with CSS ordering semantics (later declarations override earlier ones).

---

## Runtime CSS

### `Adi.CSS_Source` — High-Level API

`Adi.CSS_Source` unifies compile-time and runtime styling behind a single `Style_Source` object.

#### Modes

```ada
type Source_Mode is (Dynamic_Mode, Static_Mode);
```

- **Dynamic_Mode** — Load from files or strings, parse at runtime, optional live reload
- **Static_Mode** — Use precompiled `Part_Style_Array` constants from `css_to_ada.py`

#### Static Setup

```ada
Adi.CSS_Source.Set_Static_Entries (Source, [
   Adi.CSS_Source.Class_Entry ("button", Button_Class_Part_Styles),
   Adi.CSS_Source.Id_Entry ("root", Root_Id_Part_Styles),
   Adi.CSS_Source.Tag_Entry ("label", Label_Tag_Part_Styles)]);
```

Repeated entries for the same selector are merged in insertion order (later entries win).

Each package `css_to_ada.py` generates exposes a `Register_Selectors` procedure that installs everything its stylesheet defines, so a whole sheet goes in at once — and several sheets in the order they should cascade:

```ada
Adi.CSS_Source.Clear_Static_Entries (Source);
Base_Styles.Register_Selectors (Source);
Theme_Styles.Register_Selectors (Source);
```

Each selector is registered by its own helper procedure, so a sheet goes in in source order with one entry under construction at a time. `Add_Static_Entry` remains for registering one selector by hand.

If your stylesheet uses `:root` metadata, install it separately:

```ada
Adi.CSS_Source.Set_Static_Metadata (Source, My_Styles.Root_Metadata);
Adi.CSS_Source.Bind_Root_Metadata (Source, Root_Widget);
```

#### Dynamic Loading

A source carries an ordered set of sheets — files, watched by `Tick`, and
CSS text it holds. Later sheets cascade over earlier ones.

```ada
Adi.CSS_Source.Set_Dynamic_Sources
  (Source,
   [Adi.CSS_Source.CSS_File ("path/to/style.css"),
    Adi.CSS_Source.CSS_Text (Theme_Overrides)],
   Success);
```

Install or nothing: a file that is missing or unreadable — a directory, or
one this process may not open — or CSS that does not parse leaves the
sheets, mode and styling that were in force alone, with `Success` False
and `Get_Last_Error` saying why. `Empty_Dynamic_Sources` clears, and
unlike `Clear_Dynamic_Entries` it restyles the bound widgets at once.

```ada
Adi.CSS_Source.Add_Dynamic_File (Source, "path/to/style.css", Success);
Adi.CSS_Source.Add_Dynamic_String (Source, CSS_String, Success);
Adi.CSS_Source.Reload_Dynamic (Source, Success);
Adi.CSS_Source.Clear_Dynamic_Entries (Source);
```

`Add_Dynamic_*` append one sheet and reload the rest, so `Success` is the
whole set's verdict rather than that one sheet's, and building a set of N
this way costs N parses and N(N+1)/2 file reads against one parse and N
reads for `Set_Dynamic_Sources`. Reach for them only when adding to a set
you did not assemble.

Text sheets cannot go missing, which is why the XML generator compiles a
`<style>` block in as `CSS_Text` rather than writing a companion file
next to the generated Ada.

#### Mode Selection

```ada
Adi.CSS_Source.Set_Mode (Source, Dynamic_Mode, Success);
--  Falls back: if not Success, use Static_Mode
```

#### Binding Widgets

Binding attaches a widget to a selector. Styles are applied immediately and reapplied on reload.

```ada
--  Single class
Adi.CSS_Source.Bind_Class (Source, "button", Widget);

--  Multiple classes (space-separated, merged in order)
Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", Widget);

--  Other selector kinds
Adi.CSS_Source.Bind_Id (Source, "root", Widget);
Adi.CSS_Source.Bind_Tag (Source, "label", Widget);

--  Composite selector (CSS specificity: tag < class < id)
Adi.CSS_Source.Bind_Selector_Set (Source, Widget,
   Tag_Name   => "button",
   Class_Name => "primary",
   Id_Name    => "submit");
```

When multiple class names are passed to `Bind_Class`, styles are looked up for each class individually and merged left-to-right (later classes override earlier ones for shared properties). This mirrors HTML's `class="base accent"` behavior. `Bind_Selector_Set` accepts the same space-separated class list in `Class_Name`, so callers can pass a widget's class attribute without splitting it.

A widget carries one binding: binding it again replaces what it was bound
under, which is what a generated `Build` re-run over the same tree does.
Binding a fresh tree costs the same however many widgets are bound
already.
Destroying a widget takes its binding with it, and so does destroying a
widget above it — the source hears about every widget in a destroyed
subtree, not only the one `Destroy` was called on.

A reload restyles every widget still bound, each from its own binding,
in no particular order.

#### Releasing a Source

A `Style_Source` holds its parsed sheet and around a quarter of a
megabyte of metadata, on the heap, for as long as the process runs.
`Destroy` gives that back and stops the source being reached when a
widget is destroyed:

```ada
Adi.CSS_Source.Destroy (Source);   --  Adi.CSS_Parser.Destroy for a Stylesheet
```

A `Style_Source` and a `Stylesheet` are handles: copying one copies the
handle, not what it holds. `Adi.CSS_Source.Is_Valid` and
`Adi.CSS_Parser.Is_Valid` answer False for every copy once any of them is
destroyed, reads through a copy answer as they do for a source that holds
nothing, and destroying a copy as well does nothing. Using one again
builds a fresh one. A source that lives as long as the application need
not be destroyed at all.

#### Merging Part Styles

`Merge_Part_Styles` is available as a public function for combining style arrays outside the binding system:

```ada
Merged := Adi.CSS_Source.Merge_Part_Styles (Base_Styles, Override_Styles);
```

#### One-Off Application

```ada
Adi.CSS_Source.Apply_Class (Source, "button", Widget);
Adi.CSS_Source.Apply_Selector_Set (Source, Widget,
   Class_Name => "primary");
```

#### Live Reload

```ada
Adi.CSS_Source.Set_Auto_Reload (Source, True);

--  Call in your frame loop:
Adi.CSS_Source.Tick (Source, Reloaded, Success);
--  Reloaded = True if stylesheet changed and was reapplied
```

`Tick` checks file modification times and reloads + reapplies to all bound widgets when files change.

A sheet that fails to parse leaves the bound widgets styled from the last good one and reports through `Success`. `Tick` keeps watching the file, so saving a correction reloads and restyles from it.

#### Installing a Configuration As One Step

`Update_Scope` holds the bound widgets still while a configuration is assembled and publishes it once, when the scope ends:

```ada
declare
   Update : Adi.CSS_Source.Update_Scope (Source'Access);
begin
   Adi.CSS_Source.Clear_Static_Entries (Source);
   My_Styles.Register_Selectors (Source);
   Adi.CSS_Source.Set_Dynamic_Sources
     (Source, [Adi.CSS_Source.CSS_File ("app.css")], Loaded);
   Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
end;
```

Without it, each step publishes its own configuration and every bound widget is restyled for each. `Begin_Update`/`End_Update` are the same thing written by hand; prefer the scope, which publishes on every exit path including an exception. Generated `Build` procedures use the scope.

`Set_Dynamic_Sources` already installs its sheets as one step, so the scope earns its keep here by covering the static entries and the mode change in the same batch.

#### Error Handling

```ada
Error_Msg : constant String := Adi.CSS_Source.Get_Last_Error (Source);
```

Returns an empty string if no error.

### `Adi.CSS_Parser` — Low-Level API

Direct stylesheet loading and querying without the `Source` abstraction:

```ada
Sheet : Adi.CSS_Parser.Stylesheet;
Adi.CSS_Parser.Load_File (Sheet, "style.css", Success);
Adi.CSS_Parser.Load_String (Sheet, CSS_Content, Success);

if Adi.CSS_Parser.Has_Class (Sheet, "button") then
   Styles := Adi.CSS_Parser.Styles_For_Class (Sheet, "button");
end if;

Adi.CSS_Parser.Apply_Class (Sheet, "button", Widget);
Adi.CSS_Parser.Bind_Class (Sheet, "button", Widget);
Adi.CSS_Parser.Reload_If_Changed (Sheet, Reloaded, Success);
```

---

## Practical Guidance

### Flex Shrink for Structural Labels

Structural labels (titles, hints, panel headers) should set `flex-shrink: 0` to prevent text compression in constrained containers:

```css
.title { flex-shrink: 0; }
.hint { flex-shrink: 0; }
```

Interactive input rows should also use `flex-shrink: 0` when they need stable control height.

### Box Shadow Syntax

```css
box-shadow: 2px 4px 10px rgba(0, 0, 0, 0.25);           /* offset blur color */
box-shadow: 0 8px 16px 0 rgba(0, 0, 0, 0.15);           /* with spread */
box-shadow: none;                                          /* disable */
```

### Transition Syntax

When multiple transitions are comma-separated, the generator uses the first transition's duration and easing as the overall `Transition_Spec`, with the union of all listed properties:

```css
/* All three properties animate with 180ms ease-out */
transition: border-color 180ms ease-out,
            box-shadow 180ms ease-out,
            background-color 180ms ease-out;
```

### Interactive Part Styling Pattern

For widgets with interactive sub-parts (scrollbars, dropdown indicators), use part-scoped pseudos:

```css
.dropdown::scroll { background-color: rgba(148, 163, 184, 0.22); }
.dropdown::scroll:hover { background-color: rgba(148, 163, 184, 0.42); }
.dropdown::scroll:pressed { background-color: rgba(148, 163, 184, 0.58); }
.dropdown::knob { background-color: rgba(71, 85, 105, 0.85); }
.dropdown::knob:hover { background-color: rgba(51, 65, 85, 0.95); }
.dropdown::knob:pressed { background-color: rgba(30, 41, 59, 1.0); }
```

### Font Registration

Fonts must be registered before they can be referenced by CSS `font-family`. Use `Adi.Font` to load font files — TTF metadata (family name, weight, style) is auto-detected.

#### API Reference

| Function | Description |
|----------|-------------|
| `Load (Path)` | Load a font file. Auto-detects family name, weight, and style from TTF metadata. Multiple files from the same family auto-merge into one `Font_Handle` with variants. |
| `Load (Path, Name)` | Same as `Load`, but uses the provided name for registry lookup/insertion instead of the auto-detected family name. |
| `Load_Asset (Asset_Path)` | Resolve via `Adi.Assets` search path, then `Load`. |
| `Load_Asset (Asset_Path, Name)` | Resolve via `Adi.Assets`, then `Load` with explicit name. |
| `Register_Name (Name, Handle)` | Create a case-insensitive alias for an existing handle. |
| `Lookup (Name)` | Return the handle for a registered name, or `Null_Font`. Only checks the in-memory registry. |
| `Find (Name)` | Like `Lookup`, but on a miss also searches system font directories recursively. Loads all matching variants. Caches misses so repeated lookups for unknown names are cheap. |
| `Enable_System_Font_Search` | Switch the CSS `font-family` resolver to use `Find` instead of `Lookup`, so unregistered names trigger a system font search on first use. |

#### Loading Fonts

```ada
with Adi.Font;

--  Load from file path — auto-detects family, weight, style:
H : Font_Handle := Adi.Font.Load ("fonts/OpenSans-Regular.ttf");
H : Font_Handle := Adi.Font.Load ("fonts/OpenSans-Bold.ttf");      --  same handle, bold variant
H : Font_Handle := Adi.Font.Load ("fonts/OpenSans-Italic.ttf");    --  same handle, italic variant

--  Load with an explicit name (overrides auto-detected family name):
H : Font_Handle := Adi.Font.Load ("fonts/custom.ttf", Name => "My Font");

--  Load via the asset search path:
H : Font_Handle := Adi.Font.Load_Asset ("fonts/OpenSans-Regular.ttf");
H : Font_Handle := Adi.Font.Load_Asset ("fonts/custom.ttf", Name => "My Font");
```

> **Note:** `Load` may return an existing handle if the font file's family name matches a previously loaded font. This is intentional — it merges the file as a weight/style variant of the existing family. Use the `Name` parameter to force a distinct registry entry.

#### System Font Search

`Find` searches system font directories for a font by its TTF family name. It scans recursively:

- **Linux:** `/usr/share/fonts`, `/usr/local/share/fonts`, `/usr/share/fonts/truetype`
- **Windows:** `C:\Windows\Fonts`, `C:\WINNT\Fonts`

```ada
--  Search system fonts by family name:
H : Font_Handle := Adi.Font.Find ("Noto Sans");
H : Font_Handle := Adi.Font.Find ("DejaVu Sans");

--  Register a manual alias, then look up:
Adi.Font.Register_Name ("body-font", H);
H : Font_Handle := Adi.Font.Lookup ("body-font");
```

`Find` checks the name registry first, so already-loaded fonts are returned immediately. Names that were searched and not found are cached so that repeated misses do not trigger further filesystem scans.

#### CSS Usage

```css
.body-text { font-family: "Open Sans"; }
.heading   { font-family: "My Font", "Open Sans", sans-serif; }
```

By default, CSS `font-family` only resolves names that have been explicitly registered via `Load`, `Find`, or `Register_Name`. To allow CSS to also search system fonts for unregistered names, call `Enable_System_Font_Search` at startup:

```ada
Adi.Font.Enable_System_Font_Search;
--  Now font-family: "Noto Sans" in CSS will find and load the system font
--  on first use, without requiring an explicit Adi.Font.Find call.
```

Names are matched case-insensitively. Comma-separated lists are tried left-to-right; the first name that matches wins. If no name matches, the default font is used. In registry-only mode an unregistered name is skipped without a scan; after `Enable_System_Font_Search` it is searched for once, and the miss is cached so later lookups of the same name are cheap.

The generic families `sans-serif`, `serif` and `monospace` resolve in either mode, since they are names CSS defines rather than names of installed families. Each is tried against a per-platform candidate list — on Linux, DejaVu, Noto and Liberation — and answered by the first one present. Registering a face under the generic's own name overrides that. Resolution happens on first use and is then kept, so a generic the program never asks for is never scanned for.

---

## Limitations

- **No descendant/child combinators** — `.parent .child` and `.parent > .child` are not supported
- **No attribute selectors** — `[type="text"]` is not supported
- **No `@media` queries** — No responsive breakpoints
- **No multiple box-shadows** — Only one shadow per rule
- **Grid rows not track-sized** — `grid-template-rows` sets an explicit row count; per-row sizing tokens (`auto`, `fr`, `px`) are not yet supported for rows
- **No named grid lines** — `[line-name]` syntax is not supported
- **Max 16 tracks** — `grid-template-columns` track lists are capped at 16 entries; wider grids fall back to equal-column distribution
- **First transition wins** — Comma-separated transitions use the first entry's timing for all properties
- **No `!important`** — Specificity follows tag < class < id ordering only
- **Multi-class conflict resolution deviates from CSS spec** — When a widget has multiple classes (e.g. `class="foo bar"`), conflicts between rules of equal specificity are resolved by **class-attribute order** (last class wins), not by stylesheet declaration order as the CSS spec requires. This applies consistently to both dynamic mode (`Multi_Class_Styles` in `src/adi-css_source.adb`) and static/codegen mode (`xml_to_ada.py` builds nested `Merge_Part_Styles` calls left-to-right). Manual `Set_Part_Styles` calls are unaffected — they fully replace and don't merge. Workaround: put the base/shared class first and the specific/overriding class last in the `class` attribute. To fix properly: `Multi_Class_Styles` should merge all matching rules sorted by their stylesheet position before applying.

- **Fonts are keyed by their layout state** — `Sized_Font_Key` covers family, size, weight, style and decoration, plus the resolved line skip and wrap alignment. Both of the latter are font-level state in SDL, applying to every `TTF_Text` built from the font, so each combination is a separate instance with them set once at open and never mutated. Two widgets sharing a family and size at different `line-height` values get different instances rather than fighting over one. The cost is cardinality: alignment × distinct line skips, which is why the skip is stored as the exact integer SDL receives rather than a finer-grained pixel value.

- **Widgets install no styles** — a widget is created with an empty `Part_Style_Array`; appearance and layout behaviour come from CSS. `Html_View` scrolls only when the stylesheet says `overflow-y: auto`, and sizes to its document under `overflow-y: visible`. Technical invariants are code, not styles: the `Scrollable` / `Focusable` flags, the shared scrollbar's geometry fallbacks, and the HTML tag structure defaults.
