# Side Longhands and Auto Margins

Two related gaps in the box-model properties, both found while closing the
conformance gaps in block and flex layout. Neither is implemented. The
first should be done before the second, for the reason given at the end.

## Side longhands do not cascade

There is no `margin-left` property. There is one `margin`, holding all
four sides:

```ada
--  src/adi-css_styles.ads
type CSS_Box_Sides is array (Edge) of Length_Value;
```

The longhands are a spelling that writes into it. Both pipelines do that
correctly *within* a rule — `ensure_margin_sides()`
(`tools/css_to_ada.py:2546`) and `Set_Box_Side` in `src/adi-css_parser.adb`
— so `margin-left: 48px` on its own produces a complete four-side box with
three zeros.

The cascade then merges whole optional values
(`src/adi-css_styles.ads:29`):

```ada
function Merge (Base, Override : Optional) return Optional is
   (if Override.State = Undefined then Base else Override);
```

An `Opt_Box` that is `Set` replaces the base outright. So a rule setting
one side discards the other three:

```css
.bar    { margin-bottom: 6px; }
.indent { margin-left: 48px; }   /* margin-bottom is now 0 */
```

By the time the cascade runs there are no longhands left to merge — only a
complete box that overwrites. In CSS the four sides are four independent
properties and `.indent` would touch only the left one.

### Affected

Every group held as a single optional with side longhands writing into it:

- `margin-top/right/bottom/left`
- `padding-top/right/bottom/left` (shares `Opt_Box` with margin)
- `border-top/right/bottom/left-width`
- `border-top/right/bottom/left-color`
- `border-top/right/bottom/left-style`
- the corner radii

### Why it matters

This breaks composition, which is how stylesheets are written. A base
class plus a modifier that adjusts one edge is an everyday pattern:

```css
.card        { padding: 12px; }
.card--tight { padding-top: 4px; }   /* loses left, right, bottom */
```

It is worse than a property that is ignored. An ignored declaration does
nothing and is eventually noticed; this one *honours* what was asked and
destroys three neighbouring values while doing it. The result reads as the
author's own mistake, so the stylesheet gets blamed before the library.

### Shape of a fix

Two routes:

**Per-side optionals.** Replace `Opt_Box` with four independent optionals
per group, merged individually. Closest to CSS, and the cascade then falls
out. Costs a wider change: the resolved style grows, and every reader —
`Get_Padding_Px`, `Get_Margin_Px` (17 call sites across
`src/adi-layout_util.adb`, `src/adi-widget-box.adb`, `src/adi-widget.adb`,
`src/adi-widget-dialog.adb`, `src/adi-widget-button-switch.adb`),
`Get_Border_Width_Px` — reassembles a box from four values.

**Track which sides a rule set.** Keep the box, add a per-side "was
declared" mask, and merge side by side under that mask. Smaller change,
keeps the readers untouched, but adds a parallel structure the cascade has
to carry and that every future box-valued property must remember to
maintain.

The first is the honest one. The second is cheaper and could be staged
first if the reader churn is unwelcome.

Both pipelines need the same change — `tools/css_to_ada.py` emits the
merged box at build time, `src/adi-css_parser.adb` at runtime — and they
must agree, or a stylesheet will lay out differently depending on which
path loaded it.

## `margin: auto`

Not supported. `docs/css_styling.md` records `margin` as "1–4 lengths (no
`auto`)".

### Why the type has to change

`margin` is `CSS_Box_Sides`, an array of `Length_Value`, and
`Length_Value` has no `auto`. It cannot gain one: it is shared with border
widths, font sizes, gaps and every other length, all of which would have
to learn to reject a value that is meaningless for them. `CSS_Box_Value`
cannot carry it either, because `padding` shares that type and
`padding: auto` is invalid CSS.

The clean route is a distinct `Margin_Value`, modelled on the
`Inset_Value` this codebase already has for `top`/`right`/`bottom`/`left`
(`src/adi-css_styles.ads:483-489`):

```ada
type Inset_Kind is (Fixed, Auto);

type Inset_Value (Kind : Inset_Kind := Auto) is record
   case Kind is
      when Fixed => Length : Length_Value := Zero_Length;
      when Auto  => null;
   end case;
end record;
```

That precedent means the shape is already idiomatic here. The work is
splitting margin out of `Opt_Box`, teaching both parsers, and updating the
readers — mechanical, tedious, low risk.

### Then it stages

**1. Block horizontal centring** (CSS 2.1 §10.3.3). Small, and the common
case: `margin: 0 auto`. With a declared `width`, two auto margins split
the leftover evenly and one auto margin takes all of it; with `width:
auto` the margins collapse to zero. This lands in `Block_Child_Width`
(`src/adi-widget-box.adb`), which already computes the room and the used
width, so the leftover is one subtraction away. Measurement must treat
auto as zero — an auto margin absorbs spare room and never demands any.
Vertical auto margins are zero in block flow by spec, so they are free.

**2. Flex** (Flexbox §8.1). The awkward one. Main-axis auto margins absorb
**all** positive free space *before* `justify-content` runs and suppress
it entirely; cross-axis auto margins do the same to `align-self`.
`Flex_Child_Info` carries `Margin : Edge_Pixels` already resolved to
numbers, so it needs per-side auto flags and a free-space pass ahead of
justification. It interacts with the distribution loop, which is easy to
get subtly wrong.

**3. Grid cells and absolute centring** (§10.3.7). Smaller than flex, same
shape.

Shipping the type change plus stage 1, and documenting that auto margins
are ignored in flex and grid until stage 2, is a day rather than a week
and removes a caveat that currently appears in three places.

## Order

Do the longhand cascade first. The `margin: auto` type change is most of
that job's cost, and doing it against the current single-box
representation means doing it again once the box is split per side.
