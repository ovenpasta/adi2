# Side Longhands and Auto Margins

Two related gaps in the box-model properties, both found while closing the
conformance gaps in block and flex layout. The side longhands are done, and
so is `margin: auto` for block layout. Flex and grid are still open.

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

## `margin: auto` — done for block layout

### The type

`Length_Value` could not gain an `auto`: it is shared with border widths,
font sizes and gaps, none of which have a meaning for it. `CSS_Box_Value`
could not carry it either, since `padding` shares that type and
`padding: auto` is invalid CSS. So margin got its own element type,
modelled on the `Inset_Value` already used for the insets:

```ada
type Margin_Kind is (Fixed, Auto);

type Margin_Value (Kind : Margin_Kind := Fixed) is record
   case Kind is
      when Fixed => Length : Length_Value := Zero_Length;
      when Auto  => null;
   end case;
end record;
```

`Style_Rules.Margin` is `Opt_Margin_Sides`, an array of
`Opt_Margin.Optional`, so the per-side cascade works exactly as it does
for padding. `Resolved_Style.Margin` is `Margin_Sides` — four
`Margin_Value`, auto preserved rather than flattened to zero, because
layout has to tell "auto" from "0px" to distribute anything. That is the
one place this differs from the other groups, which fold back into a
single narrowest-shape value.

`Get_Margin_Px` reports auto as zero, which is what every measurement
path wants: an auto margin absorbs spare room and never demands any. Only
block placement looks at the kinds.

The default is `Fixed`/`Zero_Length`, not `Auto` — an unset margin is zero,
and `Inset_Value` defaulting to `Auto` is about insets meaning "not set".

### The distribution

`Block_Child_Left_Margin` (`src/adi-widget-box.adb`) implements CSS 2.1
§10.3.3 for block-level non-replaced boxes in normal flow: both margins
auto splits the leftover evenly, one auto takes all of it, and neither
auto returns the declared left margin so an over-constrained box lets its
right margin absorb the error (left-to-right). `width: auto` needs no
special case — `Block_Child_Width` has already filled the room, leaving
nothing to distribute. Vertical autos are zero by §10.6.3, which falls out
of `Get_Margin_Px` reporting them as zero.

### Still open

**Flex** (Flexbox §8.1). Main-axis auto margins absorb **all** positive
free space *before* `justify-content` runs and suppress it entirely;
cross-axis auto margins do the same to `align-self`. `Flex_Child_Info`
carries `Margin : Edge_Pixels`, already numbers, and the main-axis totals
are pre-summed globally, so this needs per-side auto flags and a
free-space pass ahead of justification. A flex child's auto margin
currently counts as zero.

**Grid cells and absolute centring** (§10.3.7). Smaller than flex, same
shape.

## Order

The longhand cascade went first, and the ground it cleared is what made
the rest cheap: margin was already four independent optionals, so
`margin: auto` was a change of element type rather than a second split.
