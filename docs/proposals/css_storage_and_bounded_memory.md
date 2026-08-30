# CSS Storage, Bounded Memory and User Properties

Status: analysis / proposal.

Three questions that turn out to share one answer: the fixed-size style
records are what make the cache layers necessary, the registration frames
large, and an embedded target unreachable.

---

## 1   Summary

A `Part_Style_Array` occupies 239,808 bytes and carries about 118 bytes of
authored CSS. That ratio — one part in two thousand — is the whole of this
document. Interning, the global resolved-style memo and the per-widget
cache each exist to make that ratio affordable, and each succeeds at its
own layer while leaving the stored object the size it was.

The proposal has four parts, in the order they should land:

1. Correctness items that stand on their own.
2. Flatten the four style properties that carry a controlled type, which
   frees the whole chain from finalization.
3. Split authoring from storage: keep `Style_Rules` as the aggregate
   authors write, store a sparse form behind it.
4. Add user properties as CSS selectors, on reserved state bits.

---

## 2   What the storage costs

### 2.1   The size chain

| Type | file | `'Object_Size`/8 | `'Max_Size_In_SE` |
|---|---|---|---|
| `Style_Rules`, 66 components | `adi-css_styles.ads:1148` | 1,144 | 1,176 |
| `State_Rule` | `adi-widget_styles.ads:97` | 1,176 | 1,208 |
| `Widget_Style`, `Base` + 16 rules | `adi-widget_styles.ads:111` | 19,976 | 20,008 |
| `Part_Style_Array`, 12 `Part_Kind` | `adi-widget.ads:235` | 239,808 | 239,840 |
| `Stylesheet_Metadata` | `adi-css_parser.ads:15` | 239,832 | 239,864 |
| `Prepared_Style_Entry`, per interned style | `adi-widget.adb:334` | 20,048 | 20,080 |
| `Resolved_Style`, 66 components | `adi-css_styles.ads:1311` | 888 | 920 |

`Style_Rules` at 1,144 bytes for 66 CSS properties is proportionate to what
it holds: 83 `Optional` instances carrying 727 bytes of value payload under 267
bytes of discriminant and alignment, the 132-byte `Grid_Column_Tracks`, and
18 bytes of record padding. The size at the top of the chain comes from
multiplicity — ×17 for `State_Rule_Array (1 .. 16)`, then ×12 for
`Part_Kind`. `Style_Rules` payload is 97.4% of a `Widget_Style`, and a
`Part_Style_Array` holds 204 of them.

### 2.2   Occupancy

Across the 32 stylesheets in the repository — 1,059 rule blocks, 3,242
declarations:

| Axis | Provisioned | Mean used | Median | Max |
|---|---|---|---|---|
| Properties per rule | 66 | 3.15 | 2 | 15 |
| State rules per `Widget_Style` | 16 | 0.51 | 0 | 9 |
| Parts per selector | 12 | 1.39 | 1 | 6 |

34.6% of rule blocks set exactly one property; 57.4% set two or fewer.
80.5% of styled `(selector, part)` pairs carry zero state rules. Nine
`Style_Rules` components stay unexercised by the sheets measured.

Compounding the three axes:

```
Widget_Style      (1.51/17) x (3.15/66)              = 0.42%
Part_Style_Array  that x (1.39/12)                   = 0.049%
```

A 19,976-byte `Widget_Style` carries about 85 bytes of authored data.

### 2.3   Where the bytes are resident

- **Interning store.** Each entry is a `Prepared_Style_Entry` at 20,080
  bytes, heap-allocated at `adi-widget.adb:485`, retained for the life of
  the process. `demo_flex.css` alone holds 81 entries, 1.55 MB. All 30
  example sheets together hold 776 entries, 14.9 MB.
- **Per widget.** The widget record embeds 48 `Resolved_Style` values —
  12 in `Cached_Resolved` (`adi-widget.ads:936`), 12 in `Last_Target`,
  24 across `Transitions` — for 42,624 bytes held from construction, and
  each `Item` adds two more. At the 2.72 items per widget the widget-tree
  goldens carry, a 500-widget tree holds 23.7 MB. Section 4.4 takes it up.
- **Per source and per sheet.** `Style_Source_Impl` and `Stylesheet_Impl`
  each embed a `Stylesheet_Metadata` at 239,832 bytes.
- **Global memo.** Capacity is 32,768 entries of `Resolved_Style`, on the
  order of 25–30 MB at the cap, released wholesale when it is reached.

### 2.4   Stack

`Part_Style_Array` is the currency of the runtime styling path.
`Apply_To_Widget` (`adi-css_source.adb:318`) reaches `Combined_Styles`,
`Multi_Class_Styles`, `Selector_Styles`, `Merge_Part_Styles`,
`Adi.Widget.Expand` and `Root_Merged_Styles`, each of which declares or
returns one by value. Peak live stack at the deepest point is 1.4–1.7 MB
per widget styled.

Registration reaches the same figures. `tools/css_to_ada.py` emits one
`Register_Selectors_N` procedure per selector with `pragma No_Inline` so
that one 240 KB frame is live at a time; `Register_Selectors_23` in
`material_demo_styles.adb` builds 13 `Style_Builder` temporaries and one
`Part_Style_Array`, about 500 KB for a single selector. Hand-written
registration reaches it too: `examples/runtime_css_example.adb:90-149`
places 14 entry calls in one frame, about 3.4 MB.

`Part_Style_Builder` embeds a whole `Part_Style_Array` and returns one by
value per fluent step, so a five-step chain is 1.2 MB.

### 2.5   Merge

`Merge` (`adi-css_styles.adb:663-762`) is a 97-line exhaustive aggregate, constructing a fresh 1,144-byte `Style_Rules` per call: 83
`Optional` merges, a `Gap` overlay and a 132-byte `Grid_Track_List` copy.
Cost is O(66) against a measured mean of 3.15 properties set. Because four
properties can hold an `Unbounded_String`, each returned temporary also
runs a deep `Adjust` and `Finalize`.

---

## 3   Authoring and storage

### 3.1   The split

`Style_Rules` stays exactly as it is: a definite, by-copy record of 66
named components, built by aggregate. It becomes the type an author writes
and a caller hands over, held for the duration of a call. What is retained
is a sparse form — a count and an exactly-sized array of
`(CSS_Property, Value_Slot)`.

The retained set is three places, the sheet layer having moved to
`Interned_Part_Styles` already: `Prepared_Style_Entry.Style` in the style
store, `Stylesheet_Metadata.Root_Styles`, and
`Inline_Style_Cache_Entry.Rules`. Two of those are answered by sizing
alone, ahead of any `Value_Slot`:

| Structure | Provisioned | Sized to the sheet | Slot-sparse |
|---|---|---|---|
| `Prepared_Style_Entry`, no state rules | 18,560 | 1,088 | ~290 |
| `Stylesheet_Metadata`, per sheet and per source | 221,976 | 76 | 76 |

Sizing the rule array to its count is 94% of the store's figure for a
fraction of the change, so it lands first and `Value_Slot` is costed
against what remains.

The `~290` column is the mean, where an exactly-sized array carries a tail
and the record form stays flat. A slot is as wide as the widest value type
it admits: 144 bytes across the value types as they stand, 96 with
`Grid_Track_List` interned to an index, and 32 to 40 once §4.4's field
narrowings land. At 96 the crossover sits near ten set properties, past
which a rule spends more than the flat 1,072, and a rule naming all 66
reaches 6,864. The mean across the sheets is 3.15, which leaves the
distribution as the figure to measure — in `Is_Specified` counts rather
than `Is_Set`, since a property named and cleared occupies a slot and
carries its `State_Kind` there.

`Resolved_Style` stays fat and concrete. It is per-widget, short-lived and
memoised, and layout, rendering and the widget implementations read it by
name at every site that uses a style.

Two properties of the record form decide this. A container aggregate carries
one element type (RM 4.3.5(22/5)), so per-property static checking belongs to
the record alone: under a class-wide or variant element type,
`Color => Px (14.0)` compiles and resolves at run time. And the aggregate
spelling is load-bearing — around 1,400 construction sites, of which 321
across 21 files are hand-written, in `tests/src/`,
`examples/hello_raw_example.adb` and `examples/font_example.adb`, so only a
hand edit reaches them.

Alternatives considered:

- **A pool handle in each of the 66 components.** Global mutable state behind
  `Set` and `Merge`, which are expression functions across some 60 generic
  instantiations, re-interned on every evaluation of a generated style
  function.
- **A private container with a class-wide or a variant element type.** Both
  compile under `-gnat2022 -gnatX0`, and both exchange the per-property type
  check for a run-time discriminant check on the authoring path.
- **`Style_Builder`** (`adi-widget_styles.ads:160`) already offers
  per-property checked authoring through prefix notation, at one call per
  property.

### 3.2   Blast radius

`Style_Rules` is read by name at 591 sites, 573 of which are in
`adi-css_styles.adb` (the six field-by-field sweeps) and `adi-css_parser.adb`
(the text-to-field dispatch). Outside those two, 18 sites in 4 files, 13 of
them in one function in `adi-widget-html_view.adb`.

Field names measure one axis. `Adi.Widget.Html_View` also retains a
`Style_Rules` of its own — `Inline_Style_Cache_Entry.Rules`
(`adi-widget-html_view.ads:190`), held in a per-view vector — which step 2
reaches through the container rather than through a component name.

### 3.3   The descriptor table

Six sweeps name every property in turn:

| Sweep | file | Lines | Compile-checked |
|---|---|---|---|
| `Merge` | `adi-css_styles.adb:663` | 100 | aggregate |
| `Set_Properties` | `adi-css_styles.adb:768` | 107 | aggregate |
| `Inherit_From` | `adi-css_styles.adb:881` | 74 | aggregate |
| `Resolve` | `adi-css_styles.adb:1067` | 97 | aggregate |
| `Layout_Affecting_Diff` | `adi-widget.adb:996` | 48 | — |
| `Interpolate` snap list | `adi-animation.adb:236` | 29 | — |

Per-property behaviour belongs in a `case P is` over `CSS_Property` with
no `others`, and per-property classification in a `CSS_Property_Set`
constant. A case with no `others` is checked against an insertion and an
append both, where an array aggregate over the enumeration catches only
the insertion — a literal added past the last one leaves the aggregate
legal with its bounds stopping early — and needs
`pragma Compile_Time_Error` pinning `CSS_Property'Last` to get halfway
back. `Inherit_Property`, `Copy_Property`, `Property_Differs`,
`Layout_Affecting_Properties`, `Inheritable_Properties` and the
`Interpolate` snap set already carry that shape, and the pin is on
`CSS_Property'Last`.

A `constant array (CSS_Property) of Property_Descriptor` would replace the
three sweeps still written as aggregates — `Merge`, `Set_Properties`,
`Resolve`. Each property carries a different `Optional` instance, so every
row needs subprograms of one profile over `Style_Rules`: some 396 of them
in place of three aggregates the compiler already checks. More code for
less checking, so the sweeps stay as they are.

Two shapes cover 55 of the 66: a scalar `Optional<T>`, and a per-side or
per-corner group folded element-wise.

Four carry behaviour a uniform shape does not:

| Property | Reason |
|---|---|
| `Gap` | axis-wise overlay, so a rule naming `row-gap` preserves an earlier `column-gap` |
| `Grid_Column_Tracks` | a bare `Grid_Track_List`, merged on `Count > 0` |
| `Font_Family` | resolves to a different type, `Font_Handle`, through `Font_Name_Resolver` |
| `Prop_Overflow` | a shorthand literal, carried by the `Overflow_X` and `Overflow_Y` axes |

`Visibility` is an ordinary inheritable property of the part cascade. It
travels a second axis in `Adi.Window.Resolve_Effective_Visibility`, which
folds a widget's effective value into its children at paint and focus time
from resolved values, so nothing in `Style_Rules` carries it.

`CSS_Property` already exists at `adi-css_styles.ads:1249`, 66 literals,
one per `Style_Rules` component apart from those two entries, and already
drives `Adi.Widget_Styles.Hash`.

### 3.4   Sizing to the sheet

`Max_Style_Rules` is 16 and `Part_Kind` has 12 values, both paid in full by
every style. Across the sheets measured a selector reaches 9 state rules and
6 parts, and the longest `.On` chain any generated sheet emits today is 6.
A generated sheet knows both figures exactly, and a sparse per-rule form
makes raising the rule cap affordable — which section 5 needs.

`Prepared_Style_Entry` carries its rules in an array sized by a
discriminant, so an entry costs the rules its style names: 1,088 bytes at
none, 2,184 at one, 18,560 at the cap. `Widget_Style` keeps its sixteen
slots, being what an author fills and a caller hands over.

`Widget_States` packs to one bit per state, which takes `State_Selector`
to 4 bytes and leaves it at 8 once section 5.1's ten literals arrive —
against 24 before, and 64 had the literals arrived unpacked. Every
selector operation reads a state by index, so the packing reaches
`Matches`, `Specificity` and the aggregates unchanged.

### 3.5   The parser

`Apply_Property` matches 98 property-name literals across 95 branches. A
`Decl_Name` enumeration with a sorted table and a binary search collapses
the name half to one lookup, and each branch tests a literal rather than
the text. The value grammars stay, since `font-weight` alone carries nine
sub-branches, and shorthand expansion stays as it is. The names pad to a
fixed width for the search, which leaves the order on the names
themselves: no name character sorts below a space, so `border` precedes
`border-top`.

The enumeration is where the parser can answer whether it recognises a
name at all. `tools/css_to_ada.py` reports an unsupported property and the
runtime parser passes over one silently, which is a divergence in
diagnostics rather than in resolution.

---

## 4   The bounded target

### 4.1   Flat style values

A controlled component anywhere under `Style_Rules` makes it a
needs-finalization type, and with it `Widget_Style`, `Part_Style`,
`Part_Style_Array` and `Resolved_Style`, so every style-typed object in
the library becomes controlled and a `Part_Style_Array` copy runs 816
discriminant checks against zero allocations. That is what keeps a style
value out of static storage, and four properties reach such a component
through the `Set` variant of `Optional`.

All four carry text, and one store answers all four.
`Adi.CSS_Styles.Intern_Text` gives each distinct string a `CSS_Text_Id`,
a 4-byte index the value holds in place of the string; `Text_Of` reads it
back. Interning is canonical, so equal text is one id and predefined
equality on the enclosing style stays exact — the property
`Linear_Gradient` already establishes for a gradient.

| Property | Component | Holds |
|---|---|---|
| `Font_Family` | `Name` | `CSS_Text_Id`, resolved through `Font_Name_Resolver` at `Resolve` time as before |
| `Background_Image` | `URI` | `CSS_Text_Id`; `Gradient` stays a `Linear_Gradient_Ref` |
| `List_Style_Image` | `URI` | `CSS_Text_Id` |
| `List_Style_Type` | `Marker` | `CSS_Text_Id` |

The font name goes to the text store rather than to
`Adi.Font.Name_Registry`. That registry is a map from a case-insensitive
name to a `Font_Handle`, populated by `Register_Name` alone: it carries no
stable index, it holds only names an application has registered, and a CSS
`font-family` value is a whole fallback list rather than one name.
`Font_Name_Resolver` exists because resolution is deferred, and the id
keeps it deferred.

`Linear_Gradient_Ref` stays a pointer. An access value is already flat, so
it is no part of the finalization question, and `Background_Image_Value`'s
payload width is set by `Adi.Image.Image_Handle` at 8 bytes either way, so
an index buys no bytes. What an index would buy is §4.2's `.rodata`
placement, which decides the emitted shape; it belongs with that step.

Text is bounded at `Max_CSS_Text_Length`, 4096 characters. Both pipelines
hold the same figure and drop a declaration naming more — `css_to_ada.py`
through `css_text_fits`, `Adi.CSS_Parser` through `Fits_In_Style` — so an
over-long value is reported rather than truncated, and neither pipeline
keeps what the other discards. A direct call to `Background_Image_URL`,
`List_Image`, `List_String` or `Set_Font_Family` past the limit answers
with the absent value and reports through `Adi.Log`. The store holds one
character blob and a span per distinct string, so it spends the characters
interned and the bound costs nothing until it is reached.

With the four flat, assignment is a `memcpy` and the chain leaves
finalization behind. Measured on x86-64 Linux, against §2.1:

| Type | Before | After |
|---|---|---|
| `Background_Image_Value` | 24 | 16 |
| `Font_Family_Value`, `List_Style_Type_Value`, `List_Style_Image_Value` | 24 each | 8 each |
| `Style_Rules` | 1,144 | 1,072 |
| `State_Rule` | 1,176 | 1,104 |
| `Widget_Style` | 19,976 | 18,752 |
| `Part_Style_Array` | 239,808 | 225,120 |
| `Stylesheet_Metadata` | 239,832 | 225,144 |
| `Prepared_Style_Entry` | 20,048 | 18,824 |
| `Resolved_Style` | 888 | 840 |

`'Max_Size_In_Storage_Elements` now equals `'Object_Size`/8 for every row,
where each stood 32 bytes above it: that difference was the finalization
header. `tests/src/style_flat_values_test.adb` reads the figures and
asserts `'Finalization_Size = 0` along the chain, GNAT answering that
attribute with zero exactly for a type needing no finalization.

Equality stays structural. `Optional` carries `when Undefined | None => null`,
so an unset component holds indeterminate bytes in its value area, as do the
variant value types beneath it, and predefined `"="` is correct precisely
because it compares the active variant. Byte equality, a byte digest in place
of the `Set_Properties`-keyed hash, and `.rodata` placement each rest on
defining those bytes — normalising every variant record to a fixed inactive
value, which is separable work behind this step.

### 4.2   The static path

`Static_Mode` resolves entirely from the static branch of `Selector_Styles`
(`adi-css_source.adb:193`), and `Tick` returns at `:937` for every mode
besides `Dynamic_Mode`. On a cache hit the per-frame path is allocation-free
for every sheet in the repository. A test should hold that.

Startup is where the work is, and each item there is the runtime
rediscovering something `tools/css_to_ada.py` already knew. With flat
values, the generator can emit the stored form directly:

```ada
Primary_Values : aliased constant Value_Pool :=
  [1 => (Color,     (Kind => Col, Col => RGB (37, 99, 235))),
   2 => (Color,     (Kind => Col, Col => RGB (29, 78, 216))),
   3 => (Font_Size, (Kind => Len, Len => Px (14.0)))];

Primary_Rules : aliased constant Sparse_Rule_Array :=
  [1 => (Selector => Any_State,                  First => 1, Last => 1),
   2 => (Selector => When_State (State_Hovered), First => 2, Last => 2)];
```

Byte size known at link time, held in `.rodata`, reached through a handle
range reserved beside the store slots that `Entry_From_Handle` already
discriminates. `Class_Entry` gains an overload taking
`access constant Sparse_Part_Array`.

The 240 KB frame goes with it for a regenerated sheet, once the generator
emits `aliased constant` objects in place of the `*_Part_Styles` functions —
those functions are public and hand-written code calls them by name, so that
is a generated-surface change. The by-value entry points serve hand-written
registration and keep their frame, and `Part_Style_Builder`
(`adi-widget-part_styles.ads:113`) embeds a whole array per fluent step.
Both want a pass of their own.

`Stylesheet_Metadata.Root_Styles` (`adi-css_parser.ads:17`) is the
remaining fixed cost at 239,832 bytes per source and per sheet, on the path
`Root_Merged_Styles` copies by value. It is public and generated code
constructs it, so changing it means regenerating downstream stylesheets —
which this step already requires.

### 4.3   Lifetime

| Structure | Growth | Bound |
|---|---|---|
| `Style_Store`, `Style_Index` | append per distinct style ever interned | `Style_Handle'Last` |
| `Bindings`, `Effective`, in both `CSS_Source` and `CSS_Parser` | one entry per widget ever bound | — |
| `Style_Source_Impl`, `Stylesheet_Impl` | one per source or sheet ever created | — |
| `Gradient_Store` | one per distinct gradient value ever constructed | — |
| `Text_Chars`, `Text_Spans` | one span, and its characters, per distinct CSS text ever interned | `Max_CSS_Text_Length` per entry |
| `Global_Resolved_Cache` | 32,768 entries, released whole at the cap | entries, rather than bytes |

`Object_Id` is generational, so a recycled widget slot presents a fresh key
to `Effective`: those two maps track every widget ever bound.
`Adi.CSS_Source.Bind` appends per call (`adi-css_source.adb:1051`) where
`Adi.CSS_Parser` dedupes (`:3914`), so a generated `Build` re-run per row
grows the vector against a stable widget set, and dedupe there comes first.

Pruning on destroy returns a vector slot and a map entry per source and per
sheet a widget was bound to, with the impl blocks following a source's own
release,
behind two pieces of groundwork. `Destroy_Notice_Slot`
(`adi-widget.ads:1008`) holds a single subscriber and its bridge raises
`Program_Error` on a second install (`adi-widget-window_bridge.adb:8`), so it
becomes a list. And `Destroy` signals for the handle it is given ahead of
recursing, where `Destroy_Subtree` frees children through its own recursion, past the
notification step, so descendants
want a signal of their own.

A notice fires once for the widget, so a pruner reaches every live source and
sheet through an enumeration of them. `Adi.Handle_Store.For_Each_Alive`
answers that out of the store the objects already sit in, which keeps it in
step with what is alive rather than beside it.

`Style_Source` and `Stylesheet` hold their impl through that same store. A
handle copies safely, `Request_Destroy` answers a repeat call as a no-op,
and `Get` yields null for a stale id, so a copy taken before a release stays
answerable through `Is_Valid`.

The memo wants a byte budget and an eviction rank in place of
clear-at-capacity; `Adi.Texture_Cache` holds that pattern already.

### 4.4   Resolved styles

All 66 components of a `Resolved_Style` hold a concrete value, so the
levers here are copy count and field width. A widget record embeds 48 —
12 in `Cached_Resolved` (`adi-widget.ads:936`), 12 in `Last_Target`
(`:968`), 24 in `Transitions`, which carries a `From_Style`/`Target_Style`
pair per part (`adi-animation.ads:25-26`) — as components with defaults,
so 42,624 bytes are resident from construction for every widget alive.
An `Item` adds `Computed_Style` and `Style_Override` (`adi-widget.ads:155`,
`:161`) and follows `Build_Items`. Across the 27 widget-tree goldens,
1,357 widgets carry 3,692 items:

| Widget | Items | `Resolved_Style` | Bytes |
|---|---|---|---|
| `list_box`, rows being child widgets | 1 | 50 | 44,400 |
| `box`, `image`, `switch` | 2 | 52 | 46,176 |
| `label`, `button` | 3 | 54 | 47,952 |
| `slider`, `combo_box`, `text_input` | 4 | 56 | 49,728 |
| `text_editor`, bounded by the viewport | 15 | 78 | 69,264 |
| `html_view`, bounded by the paint band | 96 | 240 | 213,120 |
| mean over the goldens | 2.72 | 53.4 | 47,455 |

Each row gives the count the goldens record most often for that type; a
widget carrying `Label_Text` adds two more through `Build_Label_Overlay`.

At the mean a 500-widget tree holds 23.7 MB, 21.3 MB of it in the records.

Widgets already share the inputs and the work:

| Layer | Shared across widgets |
|---|---|
| `Prepared_Style_Entry`, the interned rules | one entry per distinct style (`adi-widget.adb:479`) |
| the global memo, the cascade result | one entry per distinct key |
| `Cached_Resolved`, the stored answer | one copy per widget |

The third row carries the 21.3 MB: 500 widgets resolving to identical values
hold 500 identical records.

`Resolve` runs on the memo miss path alone, and interning the result rests on
the structural equality the record already carries. The memo becomes a store
of distinct values with stable handles, and every site above holds a 4-byte
handle into it:

| Structure | Today | Interned |
|---|---|---|
| `Cached_Resolved` and `Last_Target` | 21,312 | 96 |
| `Transitions` | 21,312 | 288 |
| One item | 1,776 | 8 |
| 500-widget tree at 2.72 items | 23.7 MB | 203 KB |

`Get_Resolved_Part_Style` keeps its profile and returns the store entry
by value, so the 868 sites that read a `Resolved_Style` component by name
stay as written, and the `Last_Target`
comparison (`adi-widget.adb:1858`) becomes a handle compare that
canonical interning makes exact. At 48 bytes an `array (Part_Kind)` of
handles is cheaper than any scheme sized to the 1.39 parts a selector
names, so the twelve slots stay and the read path keeps its direct index.

`Layout_Affecting_Diff` reads the properties a layout consumes. With the
store in place each entry carries a second handle, interned from those
properties alone, and the comparison becomes one equality:

```ada
function Layout_Affecting_Diff (A, B : Resolved_Handle) return Boolean
  is (Layout_Of (A) /= Layout_Of (B));
```

Interning is canonical, so equal handles mean equal layout inputs exactly. A
digest over the same properties trades that for a collision reporting a
layout change as none, which surfaces as stale geometry and leaves little to
debug. The projection is computed once on the miss path beside `Resolve`, and
20 of the 66 properties stay outside it, so the layout store holds far fewer
entries than the style store.

An interpolated style is minted per frame and belongs in scratch.
`Apply_Styles_To_Items` (`adi-widget.adb:1871`) is the one activation
point, `Tick_Animations` (`:8194`) the one completion, `Advance`
(`adi-animation.adb:276`) the one mutator, and each reader copies its
result out, so a slot lives exactly the span where `Active` holds. A
fixed pool of pairs sized at build time is the ceiling: 64 pairs is
113,664 bytes for 64 parts animating at once, against 10.7 MB of
embedded pairs across a 500-widget tree. A start that finds the pool full
assigns the target directly, the path a part with `Duration = 0.0` takes.

Field width is the third lever and the smallest:

| Component | Bytes | Becomes |
|---|---|---|
| `Grid_Column_Tracks` | 132 | index into a track store, 4 |
| `Border_Color` | 84 | four packed edge colours, 20 |
| `Box_Shadow` | 52 | packed colour, 36 |
| `Margin` | 48 | `auto` as a `CSS_Unit`, 32 |
| `Padding`, `Border_Radius`, `Border_Width` | 36 | the per-side form throughout, 32 |
| `List_Style_Type`, `List_Style_Image` | 24 | 4.1's ids, 8 |
| `Background_Image` | 24 | 16 at 4.1, and 8 behind a narrower `Image_Handle` |
| `Color`, `Background_Color`, `Outline_Color` | 20 | packed RGBA, 4 |
| six `Size_Value`, four `Inset_Value` | 12 | the kind folded into `CSS_Unit`, 8 |

888 becomes about 516, of which rows one and six carry 176 and are 4.1's
own work plus one store. The colour rows ask for a distinct
resolved-colour type, so that `Color_Value` keeps its `Named` arm for the
cascade and converts in `Resolve`, and they touch the 41 sites that read
a colour out of a `Resolved_Style`. Interning already takes the 23.7 MB
to 203 KB, so the narrowings pay in the store's own bound, behind it.

The store carries a generation, bumped on eviction, and every holder
re-resolves through the path `Cached_Font_Gen` establishes
(`adi-widget.adb:1576`). 4.3's byte budget and eviction rank then apply
to the single place a `Resolved_Style` lives: 4 MB holds 4,500 entries at
888 bytes and 8,200 at 490, where the 32,768-entry cap stands at 29.1 MB
and all 30 example sheets together intern 776 part styles.

---

### 4.5   Restricted profiles

After 4.1 and 4.3, the value layer — `Adi.CSS_Styles`,
`Adi.Widget_Styles`, `Compute_Style_Prepared` — can carry
`No_Implicit_Heap_Allocations`, `No_Secondary_Stack` and `No_Finalization`.
`pragma Restrictions` is a configuration pragma and applies to a whole
partition, so a per-unit set arrives through `-gnatec=` on those units or
through GNAT's `Local_Restrictions` aspect. `No_Exception_Propagation`
governs code generation partition-wide and belongs to an application's own
choice rather than to a subset of library units. `Widget'Class` in the
styling API dispatches, which `No_Dispatch` forbids.

---

## 5   User properties as selectors

`.alarm[severity="critical"] { color: red }`, with the application
selecting the value, and the property name reaching the release binary as
an enumeration rather than a string.

### 5.1   Reserved state bits

`Widget_State` (`adi-widget_styles.ads:14`) holds 6 literals and
`Packed_State_Bits` (`adi-widget.adb:328`) is `Unsigned_16`, so the cache
key already reserves 16 bits and spends 6. Reserving
`State_User_1 .. State_User_10` fills the word, and a generated stylesheet
maps onto those slots, the enumeration being fixed in the library it
compiles against.

Each distinct `(property, value)` pair becomes one bit. `Resolved_Cache_Key`
(`adi-widget.adb:356`) already holds three `Packed_State_Bits`, so it keeps
its shape and its comparison cost.

Two pieces of the present code meet their limit at sixteen, and both belong
to step 0. `Hash_Resolved_Cache_Key` (`adi-widget.adb:539`) shifts inside
`Unsigned_16` ahead of widening, so the ten new bits are precisely the ones
it sheds, collapsing every value of a main-part property into one bucket of
a 32,768-entry memo. And `Pack_States` (`:526`) shifts by
`Widget_State'Pos`, where a seventeenth literal yields zero and aliases onto
`State_Normal`, which `Equivalent_Keys => "="` then reads as one state set.
Sixteen is the ceiling, and it wants a static assertion holding it there.

`Widget_States` is `array (Widget_State) of Boolean` at one byte per
component, and a widget holds 27 of them (`adi-widget.ads:918-919, 939,
942, 961`). Packing it while adding the ten bits:

| | Today, 6 states | 16 states, packed |
|---|---|---|
| `Widget_States` | 6 B | 2 B |
| Per widget, 27× | 162 B | 54 B |
| `State_Selector` | 24 B | 8 B |

The literals and the packing carry that table between them. Turning
`State_Selector` into four `Packed_State_Bits` is a larger change costed on
its own: `Matches` (`adi-widget_styles.ads:77`) takes `Widget_States`
arrays, so the word form arrives by packing inside `Matches` — 32 bit tests
per rule per resolve, above today's six-iteration loop — or by a profile
change reaching some 50 test sites, or by making `Widget_States` modular and
rewriting 41 index sites. `Specificity` (`adi-widget_styles.adb:74`) is the
one function GNAT-LLVM rejected on the WASM port
(`wasm/PORT_REPORT.md:337`), so a population count there wants care.

### 5.2   Setting a value

Selecting a value flips two bits — clearing the old, setting the new.
`Widget_State_Style_Effect` (`adi-widget.adb:1045`) identifies a single
changed state and gates the part scan on it, so the feature wants
`Set_State_Group (W, Group, Value)` performing one masked write, and the
gate generalised from a literal to a changed mask intersected with
`Widget_State_Mask`. That generalisation stands on its own for the six
existing states, and section 5.1 rests on it: the gate reads the first
differing bit, so a rule keyed on the newly set bit is reached only where
the cleared bit carries one too. The two land together.

`Set_State` (`adi-widget.adb:1180`) already carries the right
invalidation: `Bump_Style_Version` clears the per-widget cache, and the
memo is keyed on the bits themselves, so a different value is a different
key. Property bits stay outside the ancestor walk that propagates
`State_Disabled`.

### 5.3   The vocabulary

One declaration point, read by both pipelines:

```css
@widget-property severity { normal, warning, critical }
```

The generator emits the enumeration, the bit assignment and a setter:

```ada
type Severity_Value is (Sev_Unset, Normal, Warning, Critical);

procedure Set_Severity (W : in out Widget'Class; V : Severity_Value) is
  (Adi.Widget.Set_State_Group (W, Severity_Group, Severity_Bits (V)));

--  the application writes:
--     Alarm_Styles.Set_Severity (Btn, Alarm_Styles.Critical);
```

Ten bits is a whole-program resource, and `examples/generated/` already
carries a theme pair in `material_demo_styles` and
`material_demo_light_styles`; per-sheet vocabularies would allocate bits
independently and hand the application two incompatible types for one
property. A declaration in the CSS also gives dynamic mode the vocabulary
for free — the runtime parser assigns bits by declaration order, the same
algorithm the generator ran, from text it already holds.

A generated fingerprint over the ordered declaration list lets the runtime
parser hold its last good sheet when a reloaded file reorders or renames a
property, in the shape `adi-css_parser.adb:3487` already uses. One 32-bit
constant.

Both selector parsers need `[attr="value"]`, with `:not()` as the model in
each — `tools/css_to_ada.py:867-971` and `adi-css_parser.adb:1879-1975`,
each taking the bracket stage ahead of its colon split. `Specificity`
counts set condition bits, so an attribute condition scores 1 and
`[severity=critical]:hover` scores 2, which is the CSS ranking already.

### 5.4   Derived values

Restricted to an enumerable domain, a value derived from a widget property
*is* a state bit selecting among pre-resolved styles: `[severity="critical"]
{ width: 200px }` caches exactly as `:hover` does, and N mutually exclusive
values contribute N+1 key states. This is section 5.1 exactly.

An open domain — `width: attr(progress)` over an arbitrary integer — puts
that value in the memo key. A widget animating one mints a key per frame,
reaches the 32,768 cap and releases every other widget's entry with it.
Custom properties already cover the per-sheet case by textual substitution
in `Resolve_Var_References` (`adi-css_parser.adb:2787`), ahead of any
`Style_Rules`.

---

## 6   Correctness items

**The rule cap has three behaviours across four sites.** Past the sixteenth
rule the runtime parser reports and rolls the sheet back
(`adi-css_parser.adb:3488`), the static merge discards the rule
(`adi-css_source.adb:169`, and again at `adi-css_parser.adb:159`), and the
generated path raises `Constraint_Error` from the index check
(`adi-widget_styles.adb:109`). `-gnata` belongs to the validation profile
alone (`adi.gpr:66-73`), so `Add_Rule`'s precondition is live there while
release and development builds surface the bare index check — and generated
`.On` chains reach it two ways: `tools/css_to_ada.py` emits expression
functions, so the raise arrives at the first call inside `Register_Selectors`,
and `tools/xml_to_ada.py` emits library-level constants, which places it at
elaboration.
`tools/css_to_ada.py` emits chains of arbitrary length; the longest any
sheet produces today is 6. Section 5 makes the count the binding axis, so
this settles first.

**`Layout_Affecting_Diff` names 47 of the 66 fields**, which is 46 of the 66
`CSS_Property` literals — 20 stay outside it, the 19 below plus the
`Prop_Overflow` shorthand, which owns a field nowhere. The chain sits
at `adi-widget.adb:996`, and the compiler accepts it written complete or
partial. The other 19 reach layout by a different path
today: `Border_Style` through raw width, `Visibility` through the fold of
collapse onto hidden, both alignments through `Build_Items` behind
`Diff_Render_Only`, `Object_Fit` through the draw path. Resolving correctly
and reaching layout are two facts, and a `CSS_Property_Set` line is what
establishes the second for the next property added, declaratively. The
`Interpolate` snap list (`adi-animation.adb:236`, 26 fields)
runs straight-line over the target style, where a field earns a smooth
transition by appearing and renders as a hard cut at T=0 otherwise.

**The style cache counters report a memo hit as a miss.**
`Perf_Style_Resolves` increments unconditionally at `adi-widget.adb:1563`
while `Perf_Style_Hits` covers the per-widget array alone and the memo
branch (`:1602`) increments neither. They surface on the debug overlay as
`S:<hits>/<resolves>` (`adi-window.adb:1105`). Counting the two layers
separately is a precondition for measuring any of this work.

**`Hash_Resolved_Cache_Key`** (`adi-widget.adb:539`) shifts within
`Unsigned_16` ahead of widening, so `Main_Part_States` starts shedding bits
at the ninth state and `Part_States` at the thirteenth. `Equivalent_Keys`
compares the whole key, which bounds the cost at bucket collisions. `:542`
computes `Natural (K.Part_Handle) * 16#9E37#` in `Natural`, holding the
handle below about 53,020.

**Parallel merge helpers.** `Merge_Widget_Style` and `Merge_Part_Styles`
(`adi-css_source.adb:153-191`) have counterparts under other names in
`adi-css_parser.adb:143-186`, and `Root_Merged_Styles` exists in both
(`adi-css_source.adb:280`, `adi-css_parser.adb:188`) over different
parameter types. `Adi.CSS_Source.Merge_Part_Styles` is public and every
generated XML UI body calls it, so it keeps its name and place;
`Part_Style_Array` lives in `Adi.Widget`, which is where a shared copy
belongs.

**Test-only cascade.** `Adi.Widget_Styles.Compute_Style` and
`Compute_Resolved` (`adi-widget_styles.adb:128-194`) are reached from
`tests/` alone, where the runtime uses `Compute_Style_Prepared`. Their
exchange sort (`:155-167`) is unstable where `Prepare_Style`
(`adi-widget.adb:398`) breaks ties on source order, so on equal priorities
the two pick opposite winners — and the suite exercises
`Compute_Style`/`Compute_Resolved`, where the runtime takes
`Compute_Style_Prepared`.

**`Inheritable_Properties`** (`adi-css_styles.ads:1292`) states inheritance
policy on its own, where `Inherit_From` implements it separately, and the two
disagree over `Visibility`,
which `adi-css_styles.adb:930` merges from the parent inside the block
headed as passing the child through. Section 3.3 settles which is
authoritative.

**`Widget_State_Style_Effect` resolves outside the memo.**
`adi-widget.adb:1045-1069` calls `Compute_Style_Prepared` and `Resolve`
directly for the old states and again for the new, per part carrying a rule on
the changed state, then compares two `Resolved_Style` values structurally
ahead of `Layout_Affecting_Diff`, and reaches sub-parts by a route that
leaves `Inherit_From` out, so a `::label` diff reads a style apart from the
one `Get_Resolved_Part_Style` answers with. Both resolves carry the memo's key
shape already. Routing them through it gives the path a cache — a state a widget
just left is a strong candidate for the one it enters next — and brings it
inside the counters, which it sits outside today, so the most expensive style
operation in the library goes unmeasured.

**`Frame_Stats` captures ahead of the draw.** The snapshot at
`adi-window.adb:1247` follows the layout pass, where the reset at `:1197`
reads as covering a whole frame. On a nine-widget tree the draw stage adds 63
resolve calls to 764, all per-widget hits.

**Coverage.** `layout_perf_test` asserts exact cache counts on a two-widget
tree. Throughput, merge cost, memo hit rate and store growth want figures a
rewrite can be measured against. Step 2 wants one more: a differential test
over generated `Style_Rules` pairs requiring the descriptor table to agree
with the aggregates it replaces, in the shape
`tests/src/side_longhand_test.adb` already uses for two-implementation
agreement. The table moves per-property behaviour from checked code into
data, and that test is what keeps it honest.

---

## 7   Sequence

**Step 0 — correctness.** Section 6, §4.3's binding pruning and `Impl`
release, and §5.2's changed-mask gate with the `Pack_States` ceiling, which
are step 4's gate and stand on their own. §4.3's byte budget for the memo
travels with §4.4 in step 2. The
counters land first, since every later step is measured against them. Two
items here — the `CSS_Property_Set` for `Layout_Affecting_Diff`, and the
`Visibility` question — are settled by §3.3, so either they wait for step 2
or §3.3's table arrives early.

Step 0 splits in two: the contained fixes land first, then the merge
helpers, §4.3's lifetime work and the memo routing, which reach public API and
widget teardown.

**Step 1 — flat values.** Section 4.1. Four properties, and the whole
chain leaves finalization behind.

**Step 2 — sparse storage.** Sections 3.1 to 3.5, behind an unchanged
authoring API. Arrays sized to the sheet. Section 4.4's resolved-style store
rides with it, on structural equality. §5.1's `State_Selector` shape settles
before this, since `State_Rule` is what the sparse form stores.

**Step 3 — static tables.** Section 4.2, with `Stylesheet_Metadata` in the
same regeneration.

**Step 4 — user properties.** Section 5, on step 0's rule cap, hash widening
and `Pack_States` ceiling, and on step 2's per-rule size.

**Step 5 — restricted profiles.** Section 4.5, on the flat values of step 1
and the lifetime work of step 0.

Steps 0 and 1 are independent of the rest and independently useful.

---

## 8   Open questions

**Downstream compatibility.** `Style_Rules`, `Widget_Style`,
`Part_Style_Array`, `Stylesheet_Metadata`, `Merge_Part_Styles` and the three
entry constructors are public and appear in generated code. Steps 2 to 4
change the generated shape, so a consumer upgrades generator and library in
lockstep. The crate wants a versioning statement saying so.

**Two-pipeline agreement.** `tools/css_to_ada.py` and `src/adi-css_parser.adb`
resolve the same CSS and every step touches both. §5.3 adds a third encoding
in the bit assignment and its fingerprint. `tests/src/side_longhand_test.adb`
holds the pattern: install the generated sheet, parse the CSS it came from,
require identical resolution.

**32-bit and WebAssembly.** Every figure here is x86-64. `Style_Handle`
ranges, `access constant` placement and `Unsigned_16` packing each behave
differently on a 32-bit build, and the WASM port carries one recorded
frontend divergence in `Specificity`.

**Concurrency.** `docs/style_storage_optimization.md` records single-threaded
style mutation as an assumption. §4.2's reserved handle range, §4.3's
eviction rank and §5.2's masked write each sit inside it.

**A shared store for styles.** `Adi.Handle_Store` backs `Widget`, `Window`,
`Image`, `Animated_Image`, `RLottie` and `Context_Menu`, where styles keep
their own vector and index (`adi-widget.adb:353, 388`) under
`Style_Handle is new Natural` (`adi-widget.ads:877`). The contracts diverge:
a handle store gives each registration a distinct identity, with a generation
for recognising a released one, where interning answers with one handle for
equal values and holds them for the life of the process. The narrower
question stays open — §4.4's store evicts, so it wants liveness, and whether
that arrives as `Handle_Store`'s per-object generation or as the store-wide
counter `Cached_Font_Gen` models is a choice to make there.

The same split places `Style_Source` and `Stylesheet` inside the store, as
§4.3 has them: they carry identity and a lifetime, which is what a generation
is for, and `For_Each_Alive` gives §4.3's pruning its reach.

**Sharing the part arrays.** Past §4.4, two widgets carrying the same style
in the same states hold identical twelve-handle arrays, and interning the
array under its own handle takes a widget from 96 bytes to 8 — 44 KB across a
500-widget tree, behind the 21.1 MB §4.4 already returns. The cost is a
second indirection on every read, where `Get_Resolved_Part_Style` is reached
25 times in `adi-widget-box.adb` alone, and a probe on every state change.
Measured and set aside.
