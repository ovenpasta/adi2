# Side Longhands and Auto Margins

Two related gaps in the box-model properties, both found while closing the
conformance gaps in block and flex layout. The first is implemented; the
second is not, and had to wait for it, for the reason given at the end.

## Side longhands cascade — done

Each of `margin`, `padding`, `border-width`, `border-color`,
`border-style` and the corner radii used to be one optional over a
four-sided value, so a rule naming one side replaced all four and a base
class plus a modifier that adjusts one edge — the everyday pattern — lost
the other three.

Fixed with **per-side optionals**. `Opt_Box` and the three per-group
border optionals are gone; `Style_Rules` holds `Opt_Edge_Lengths`,
`Opt_Edge_Colors`, `Opt_Edge_Styles` and `Opt_Corner_Lengths`, arrays of
optionals indexed by `Edge` or `Corner`, and `Merge` runs element by
element. `Resolve` folds each group back into the single concrete value
`Resolved_Style` carries, in its narrowest shape, so `Get_Padding_Px`,
`Get_Margin_Px`, `Get_Border_Width_Px` and their 17 call sites did not
have to change — the reader churn this proposal expected never arrived.

The alternative considered and rejected was a per-side "was declared"
mask over the existing box: cheaper, but a parallel structure the cascade
has to carry and every future box-valued property has to remember to
maintain.

Both pipelines changed together — `tools/css_to_ada.py` merges at build
time, `src/adi-css_parser.adb` at run time — or a stylesheet would lay
out differently depending on which path loaded it.
`tests/src/side_longhand_test.adb` installs
`tests/generated/side_cascade_styles.ads` and parses the
`tests/css/side_cascade.css` it was generated from, and requires the two
to resolve identically. `docs/css_styling.md` states the rule.

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
giving `Style_Rules.Margin` its own element type — `Opt_Length` no longer
serves, since padding and the border widths share it — teaching both
parsers, and updating the readers: mechanical, tedious, low risk.

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

The longhand cascade went first, and the ground it cleared is what makes
the rest cheap: margin is already four independent optionals, so
`margin: auto` is a change of element type rather than a second split.
