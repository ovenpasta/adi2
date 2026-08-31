# CSS Storage, Bounded Memory and User Properties

Status: analysis / proposal.

Three questions that turn out to share one answer: the fixed-size style
records are what make the cache layers necessary, the registration frames
large, and an embedded target unreachable.

---

## 1   Summary

A `Part_Style_Array` occupies 221,952 bytes and carries about 118 bytes of
authored CSS. That ratio — one part in two thousand — is the whole of this
document. Interning, the global resolved-style memo and the per-widget
cache each exist to make that ratio affordable, and each succeeds at its
own layer while leaving the stored object the size it was.

The proposal has five parts, in the order they should land:

1. Correctness items that stand on their own.
2. Flatten the four style properties that carry a controlled type, which
   frees the whole chain from finalization.
3. Make every style a handle at the point it is stored or passed, which
   puts `Part_Style_Array` at 96 bytes under its own name.
4. Compose a rule property by property, which retires the aggregate that
   step leaves and frees the value representations it pins.
5. Add user properties as CSS selectors, on reserved state bits.

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
- **Per widget.** The widget record held 48 `Resolved_Style` values — 12
  in `Cached_Resolved`, 12 in `Last_Target`, 24 across `Transitions` —
  and each `Item` two more, for 40,968 bytes a widget and 23.0 MB across
  a 500-widget tree at the 2.72 items per widget the goldens carry.
  Section 4.4 replaces each of them with an 8-byte handle, which takes a
  widget to 1,136 bytes and that tree to 807 KB.
- **Per source and per sheet.** `Style_Source_Impl` and `Stylesheet_Impl`
  each embed a `Stylesheet_Metadata` at 239,832 bytes.
- **Global memo.** Capacity is 32,768 entries, each a key and a handle
  since 4.4, released wholesale when it is reached. The values those
  handles name are the resolved-style store's, capped at 16,384 entries
  and 13.8 MB.

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

### 2.5   Merge

`Merge` (`adi-css_styles.adb:663-762`) is a 97-line exhaustive aggregate, constructing a fresh 1,144-byte `Style_Rules` per call: 83
`Optional` merges, a `Gap` overlay and a 132-byte `Grid_Track_List` copy.
Cost is O(66) against a measured mean of 3.15 properties set. Because four
properties can hold an `Unbounded_String`, each returned temporary also
runs a deep `Adjust` and `Finalize`.

---

## 3   Authoring and storage

### 3.1   Authoring by composition

A style arrives one property at a time, through a setter that names the
property and takes its own value type:

```ada
Primary : constant Style :=
   Style_Of
      .Background (RGB (37, 99, 235))
      .Padding    (CSS_Box (Px (12.0), Px (24.0)))
      .Radius     (Radius (Px (6.0)))
   .On_Hover
      .Background (RGB (29, 78, 216))
   .Build;

Set_Part_Style (W, Main_Part, Primary);
```

`Background (Px (14.0))` is a compile error, so per-property checking holds
without a record, and more of it than an aggregate gives: `others => <>`
has nothing to say here. `Style_Of` opens a chain, `.On_Hover` and
`.On (Selector)` move the active rule, and `.Build` answers a `Style`.

`.Build` answers the four-byte `Widget_Style` §4.2 established, so a chain
carries what an author holds, passes and compares, and the interning behind
it stays the library's business rather than something an author writes.

Deriving one style from another is a chain that opens on an existing one:

```ada
Danger : constant Widget_Style :=
   Style_Of (Primary) .Background (RGB (200, 30, 30)) .Build;
```

which is the composer's answer to `Base with delta Background_Color => …`.
The two read alike and cost differently: a delta aggregate materialises all
1,072 bytes to change eight of them, where opening on a handle copies the
base's slots, applies the override and interns, at work proportional to the
properties named. It also survives `Style_Rules` leaving, which a delta
aggregate over that record depends on.

A part bundle composes the same way:

```ada
Card : constant Part_Styles :=
   Parts .Main  (Style_Of.Background (RGB (30, 41, 59)).Build)
         .Label (Style_Of.Color (C (White)).Build)
   .Build;

Set_Part_Styles (W, Card);
```

`tools/css_to_ada.py` emits exactly this, in place of the three-level nest
of functions — `Danger_Class_Base_Style` answering `Style_Rules`,
`Danger_Class_Widget` answering `Widget_Style`, `Danger_Class_Part_Styles`
answering `Part_Style_Array` — where each level answers a larger record than
the one below it.

### 3.2   The slot

A chain step carries a slot of eight bytes:

```ada
type Slot is record
   Rule : Rule_Index;      --  0 is the base rule
   Prop : CSS_Property;    --  says how Val reads
   Val  : Value_Ref;
end record;
```

`Prop` discriminates `Val`, and a slot is read only by something that knows
which property it holds, so a variant record has nothing to add. That is
what keeps the slot at eight bytes for every property: a variant would stand
as wide as `Grid_Track_List`, which measures 144 bytes.

Each setter interns into the store for its own value type and keeps the
reference:

```ada
function Background (C : Composer; V : Color_Value) return Composer is
  (C.Count + 1, C.Active,
   C.Items & Slot'(C.Active, Prop_Background_Color, Intern (V)));
```

`Intern` is overloaded per value type, so the compiler picks the store from
the argument. A value narrow enough — an enumeration, a packed RGBA — sits
in the four bytes directly and reaches no store, which leaves indirection
for the values that earn it: `Grid_Track_List` at 132 bytes and
`Border_Color` at 96 answer with an index. Equal values across a sheet share
one entry, so `RGB (220, 38, 38)` in six rules is one.

The composer itself is a pool index, so a chain step copies four bytes and
the slots stay where they are gathered:

```ada
type Composer is tagged record
   Where  : Adi.Slot_Pool.Slot;
   Active : Rule_Index;
end record;
```

§4.6 holds the pool. Accumulating by value instead — an indefinite
`Composer (Count)` sized to what it holds — reads well and costs on every
step: N(N+1)/2 slot copies for an N-step chain, and an intermediate on the
secondary stack per step, where §4.5 wants none on this layer. The index
carries neither.

`.Build` reads the slots the chain gathered, answers a `Style` sized to
them, and releases the slot.

### 3.3   Sunsetting the aggregate path

The composer becomes the authoring path, and the `Style_Rules` aggregate
leaves with the constructors feeding it. It carries `pragma Obsolescent` when
the composer lands, and goes before 1.0, which the crate at 0.9.0 with no tag
reaches on its own schedule. `Set_Part_Style` and `Set_Part_Styles` keep their
spellings, since §4.2 leaves them carrying handles.

Two things pay for that. An aggregate materialises 1,072 bytes for the 3.15
properties a rule names, where a chain carries eight bytes per property named.
And while the aggregate surface stands public, a consumer writing
`Border_Color => Set (…)` pins the value representations, so §4.4's narrowings
reach a public surface every time: `Border_Color` at 96 bytes, `Margin` at 64,
`Grid_Column_Tracks` at 132. Closing the door leaves the value layer free to
move behind it.

`pragma Obsolescent` warns under `-gnatwa`, which `adi.gpr:71` and
`config/adi_config.gpr:18` set already, and it holds its peace inside the
unit that declares the entity — measured both ways. So `Merge`, `Resolve`
and `Prepared_Style_Entry.Base` keep naming `Style_Rules` in quiet, while a
consumer reading it gets the warning and the message it carries.

`Style_Rules` itself leaves with them. It stands today as what `Merge`,
`Resolve` and `Prepared_Style_Entry.Base` are written over, and that holds
while those three are field-by-field sweeps — 573 of the 591 sites that read
the type by name. §3.5's descriptor table turns each of them into a loop over
slots: merge is a linear merge of two property-sorted slot lists at 3.15
entries a side where it compares 66 fields, resolve walks the rules' slots in
cascade order, and inheritance becomes a column. Past that the record has no
remaining job, so it goes rather than turning internal.

That settles §6's `Inheritable_Properties` item along the way. The policy is
stated in two hand-written places today, which is what lets them disagree over
`Visibility`; a table column states it once.

`Resolved_Style` stays fat and concrete: it is the read path, 66 values that
layout, rendering and the widget implementations reach by name, and §4.4
holds one of each behind a handle already.

Static placement leaves with them. A generated constant is interned on the
way in, so `.rodata` holds a form the runtime copies out of once and reads
through a handle thereafter — the placement pays for what interning already
answers.

The `Optional` distinction between unset and cleared is what a chain
restates: a setter says "set" by existing, so clearing wants a spelling of
its own, as `.Clear (Prop_Background_Color)`. `Is_Specified` counts, rather
than `Is_Set` counts, are what size a rule.

### 3.4   Blast radius

`Style_Rules` is read by name at 591 sites, 573 of which are in
`adi-css_styles.adb` (the six field-by-field sweeps) and `adi-css_parser.adb`
(the text-to-field dispatch). Outside those two, 18 sites in 4 files, 13 of
them in one function in `adi-widget-html_view.adb`.

Field names measure one axis. `Adi.Widget.Html_View` also retains a
`Style_Rules` of its own — `Inline_Style_Cache_Entry.Rules`
(`adi-widget-html_view.ads:190`), held in a per-view vector — which step 2
reaches through the container rather than through a component name.

### 3.5   The descriptor table

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

### 3.6   Sizing to the sheet

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
to 4 bytes, against 24 before. Every selector operation reads a state by
index, so the packing reaches `Matches`, `Specificity` and the
aggregates unchanged. Section 5 adds a 2-byte condition index and leaves
it at 6.

### 3.7   The parser

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
an index buys no bytes. What an index would buy is the emitted shape a
`.rodata` constant takes, and §3.3 settles that: a constant is interned on
the way in, so the placement answers what a handle answers.

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

### 4.2   Handles all the way down

`Static_Mode` resolves entirely from the static branch of `Selector_Styles`
(`adi-css_source.adb:193`), and `Tick` returns at `:937` for every mode
besides `Dynamic_Mode`. On a cache hit the per-frame path is allocation-free
for every sheet in the repository. A test should hold that.

The bytes are in what that path carries by value. Measured with `-gnatR2`
against the tree as it stands, beside the width each type takes once the one
below it is a handle:

| Type | Now | Interned |
|------|-----|----------|
| `Part_Style_Array` | 221,952 | 96 |
| `Part_Style` | 18,496 | 8 |
| `Widget_Style` | 18,488 | 4 |
| `State_Rule` | 1,088 | 16 |
| `Style_Rules` | 1,072 | 1,072 |

`Widget_Style` becomes private and four bytes wide, naming an entry in the
store `Intern_Style` (`adi-widget.adb:541`) keeps already. The authoring
record it holds today takes a name of its own, `Style_Definition`, and
`Definition` answers one from a handle. `From (…) .On (…) .Build` reads as it
reads now, where `.Build` interns and answers the handle, so a call site keeps
its text and carries four bytes. `Style_Builder` holds a definition, which
puts it at 268 bytes where it stands at 18,496, and that is the width `.On`
copies per step (`adi-widget_styles.adb:305`).

`Style_Rules` interns one level down, so a `State_Rule` is a selector, a rules
handle and a priority at 16 bytes, and the sixteen-slot array inside a
definition is 256.

`Part_Style.Style` follows its type, which puts `Part_Style_Array` at 96 bytes
under its own name. `Set_Part_Styles`, `Merge_Part_Styles` and
`Selector_Styles` keep their signatures, and the 20 widget packages
re-exporting `Set_Part_Styles` keep the one declaration each has.
`Interned_Part_Styles`, `Intern` and `Expand` (`adi-widget.ads:245-250`) fold
into it: the eight `Expand` calls in `adi-css_source.adb` and
`adi-css_parser.adb` recover the array, and the array is what a handle names.
`Stylesheet_Metadata.Root_Styles` holds a `Part_Style_Array` directly at that
width.

§2.4 measures the effect. `Apply_To_Widget` (`adi-css_source.adb:318`) reaches
six subprograms declaring or returning a `Part_Style_Array` by value, for a
peak of 1.4–1.7 MB per widget styled; at 96 bytes the whole chain is
kilobytes. `Register_Selectors_23` in `material_demo_styles.adb` builds 13
`Style_Builder` temporaries and one array, about 500 KB, which the same
figures put under 4 KB, and `pragma No_Inline` becomes a choice rather than a
requirement.

What stays fat is `Style_Rules` at 1,072 bytes, live as a construction
transient at each `(Display => Set (…), others => <>)` aggregate, one at a
time. Section 3.2's eight-byte slot takes that, and section 3.1's composer
answers a handle straight from a chain, which is the same shape one level up.

Three things move with the type. `Add_Rule` (`adi-widget_styles.ads:188,194`)
is the one in-place mutation of a style in the library, and it takes a
`Style_Definition`; `adi-css_parser.adb:4051` accumulates into one and interns
at the end. `Adi.Style_Merge.Merge` expands, folds and re-interns, for the
parts carrying two contributors, where `Selector_Styles` answers handles
straight through on a single match. Tests reading `.Base` and `.Rule_Count`
(`style_interning_test.adb:276-282`, `style_rule_cap_test.adb:144-157`) read
them from `Definition (…)`.

Elaboration order is the hazard: a generated styles package interning at
elaboration wants `Adi.Widget`'s store elaborated first, so `pragma
Elaborate_All` and a test holding that a styles unit elaborating ahead of any
window answers a live handle.

`tools/css_to_ada.py` emits `Part_Style_Array` constants where it emits
expression functions today, and `tools/xml_to_ada.py` follows. Both are a
generated-surface change, and consumers regenerate.

### 4.3   Lifetime

| Structure | Growth | Bound |
|---|---|---|
| `Style_Store`, `Style_Index` | append per distinct style ever interned | `Style_Handle'Last` |
| `Bindings`, `Effective`, in both `CSS_Source` and `CSS_Parser` | one entry per widget ever bound, holding four `Unbounded_String` each (§4.3.1) | — |
| `Style_Source_Impl`, `Stylesheet_Impl` | one per source or sheet ever created | — |
| `Gradient_Store` | one per distinct gradient value ever constructed | — |
| `Text_Chars`, `Text_Spans` | one span, and its characters, per distinct CSS text ever interned | `Max_CSS_Text_Length` per entry |
| `Global_Resolved_Cache` | 32,768 entries, released whole at the cap | entries, rather than bytes |
| `Adi.Resolved_Styles`, the store 4.4 adds | append per distinct resolved style | 16,384 entries, released whole, generation raised |

`Object_Id` is generational, so a recycled widget slot presents a fresh key
to `Effective`: those two maps track every widget ever bound.
`Adi.CSS_Source.Bind` appends per call (`adi-css_source.adb:1051`) where
`Adi.CSS_Parser` dedupes (`:3914`), so a generated `Build` re-run per row
grows the vector against a stable widget set, and dedupe there comes first.

### 4.3.1   What a binding retains

`Bound_Target` (`adi-css_source.adb:37-45`) holds four `Unbounded_String`
components — `Name`, `Tag_Name`, `Class_Name` and `Id_Name` — beside the
handle it targets, and `Bind_Class` fills one with
`To_Unbounded_String (Name)` (`:1164`). So the selector names a widget was
bound under are held per widget rather than per distinct name: 500 widgets
carrying `.row` hold 500 copies of it, in four controlled components apiece,
which is the shape §4.1 took off `Style_Rules` one layer down.

`Record_Binding` (`:448`) runs with the mode unread, so `Static_Mode`
retains the history a reload replays alongside `Dynamic_Mode`, where a
reload is what the mode forecloses. It also scans the whole vector per call
(`:451-457`), so binding N widgets costs N².

Three things follow, in the order they pay: dedupe by name, which the
parser side does already; the names interned, where §4.1's text store is
the worked example; and the history kept for the mode that replays it.
A `Style_Source` in `Static_Mode` then holds a handle and a target per
binding, and the strings live once each.

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
levers here are copy count and field width. A widget record embedded 48 —
12 in `Cached_Resolved`, 12 in `Last_Target`, 24 in `Transitions`, which
carried a start/target pair per part — as components with defaults, so
40,512 of a widget's 40,968 bytes were resident from construction for
every widget alive. An `Item` added `Computed_Style` and `Style_Override`
and follows `Build_Items`. Across the 27 widget-tree goldens, 1,357
widgets carry 3,692 items, at 840 bytes a `Resolved_Style` after 4.1:

| Widget | Items | `Resolved_Style` | Bytes |
|---|---|---|---|
| `list_box`, rows being child widgets | 1 | 50 | 42,000 |
| `box`, `image`, `switch` | 2 | 52 | 43,680 |
| `label`, `button` | 3 | 54 | 45,360 |
| `slider`, `combo_box`, `text_input` | 4 | 56 | 47,040 |
| `text_editor`, bounded by the viewport | 15 | 78 | 65,520 |
| `html_view`, bounded by the paint band | 96 | 240 | 201,600 |
| mean over the goldens | 2.72 | 53.4 | 44,856 |

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

A handle is 8 bytes: an index and the store generation it was minted in,
which is what tells a holder that the entry behind it is gone. Measured:

| Structure | By value | Interned |
|---|---|---|
| `Cached_Resolved` and `Last_Target` | 20,160 | 192 |
| `Transitions` | 20,352 | 480 |
| An item's two style components | 1,680 | 16 |
| A whole `Item` | 1,848 | 176 |
| A whole `Widget` | 40,968 | 1,136 |
| 500-widget tree at 2.72 items | 23.0 MB | 807 KB |

`Get_Resolved_Part_Style` keeps its profile and returns the store entry
by value, so the 868 sites that read a `Resolved_Style` component by name
stay as written, and the `Last_Target` comparison is a handle compare
that canonical interning makes exact. At 96 bytes an `array (Part_Kind)`
of handles is cheaper than any scheme sized to the 1.39 parts a selector
names, so the twelve slots stay and the read path keeps its direct index.
`Get_Resolved_Part_Handle` answers the same question as a handle, for the
caller that stores or compares the answer.

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
debug. The projection is the layout properties copied onto the defaults,
which is itself a `Resolved_Style` and interns into the same store, so a
call takes up to two entries. Both land, because interning never clears;
a clear between them would leave the first handle naming an entry the
store had already let go. 20 of the 66 properties stay outside the
projection, so the layout entries are a fraction of the style entries.

An interpolated style is minted per frame and belongs in scratch.
`Apply_Styles_To_Items` is the one activation point, `Tick_Animations`
the one completion, `Advance` the one mutator, and a slot lives exactly
the span where `Active` holds. A fixed pool of pairs sized at build time
is the ceiling: 64 pairs is 107,520 bytes for 64 parts animating at once,
against 10.1 MB of embedded pairs across a 500-widget tree. A start that
finds the pool full assigns the target directly, the path a part with
`Duration = 0.0` takes.

The pair is the start point and this frame's value. The target is always
a cascade result, so it is already in the store and the transition names
it by handle; the start point is the previous target on a fresh start and
the interpolated value on a restart, which is why it needs a cell of its
own. An item holds the handle of the current cell while the transition
runs, and a slot serial rides in that handle, so a handle into a released
slot reads as the default style rather than as the next animation's.
`Destroy_Subtree` returns the slot of a widget destroyed mid-transition.

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

840 becomes about 470. The colour rows ask for a distinct
resolved-colour type, so that `Color_Value` keeps its `Named` arm for the
cascade and converts in `Resolve`, and they touch the 41 sites that read
a colour out of a `Resolved_Style`. Interning already takes the 23.0 MB
to 807 KB, so the narrowings pay in the store's own bound, behind it.

The store carries a generation, raised on eviction. Three holders
compute on demand and re-resolve through the path `Cached_Font_Gen`
establishes, keeping the generation beside their handles: the per-widget
cache, the animation targets, and the memo, whose element is now a handle
and whose own clear therefore costs nothing.

A fourth kind of holder does not compute on demand, and a per-holder gate
cannot reach it. An `Item` caches its style by copy, and
`Apply_Styles_To_Items` is the only thing that writes a live handle back;
`Update` reaches that through `Is_Dirty`, while rendering walks every
child unconditionally and reads the handle with nothing behind it. A
widget that has gone clean is therefore asked nothing until something
dirties it again, and draws the default style -- transparent, black,
borderless -- in the meantime. Enumerating holders is the wrong shape of
answer for a process-wide event: `Update` compares the generation once
per tree and marks the whole subtree dirty on a difference, descending
whether a widget is dirty or not.

Eviction belongs at a point the frame chooses rather than inside
`Intern`, for the reason `Adi.Texture_Cache` reclaims at a frame
boundary. `Collect` is that point and the one place the store clears;
`Adi.Widget.Update` calls it ahead of the comparison, so the clear lands
before the frame's layout and its draw, and a handle minted in a frame
lasts the whole of it. The count stands above the cap by what one frame
interned past it. The store's cap is what bounds the resident
bytes: 16,384 entries at 840 is 13.8 MB, against the 27.5 MB the
32,768-entry memo could reach holding values. 4.3's byte budget and
eviction rank then apply to the single place a `Resolved_Style` lives:
4 MB holds 4,700 entries at 840 and 8,500 at 470, and all 30 example
sheets together intern 776 part styles.

`Resolved_Style` cannot be hashed as bytes, for the reason 4.1 gives for
`Style_Rules`: its variant components hold indeterminate bytes in the
arms that are not active. The hash reads a subset of the record and
reaches every variant component through its discriminant, which is all
equality asks of it; a component it skips costs a bucket probe.

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

### 4.6   A pool for transient slots

`Adi.Resolved_Styles` holds the styles a transition mints per frame in a
fixed pool, and the shape it uses knows about styles in one component:

```ada
type Scratch_Entry is record
   Cells  : Scratch_Cells;     --  the payload
   In_Use : Boolean := False;
   Serial : Natural := 0;      --  raised each time the slot is handed out
end record;
```

`Acquire_Scratch` (`adi-resolved_styles.adb:477`) scans for a free slot and
raises its serial; `Release_Scratch` (`:490`) matches index, occupancy and
serial before freeing; `Live_Scratch` (`:296`) answers the slot a reference
names, or zero. A reference into a released slot therefore reads as the
default rather than as the next occupant, which is what the serial buys.

None of that is about styles:

```ada
generic
   type Payload is private;
   Capacity : Positive;
package Adi.Slot_Pool is
   type Slot is private;
   No_Slot : constant Slot;          --  what a full pool answers

   function Acquire return Slot;
   procedure Release (S : in out Slot);
   function Live (S : Slot) return Boolean;
   function Held return Natural;

   function Get (S : Slot) return Payload;
   procedure Set (S : Slot; P : Payload);
end Adi.Slot_Pool;
```

Two callers: the animation scratch at `Payload => Scratch_Cells` and 64
slots, and §3.1's composer at the pending buffer and 8, where Ada evaluates
an argument before its call and so holds one outer chain and one inner at a
time.

Two things stay with their callers. `Resolved_Styles` encodes a slot into
`Resolved_Handle` through the range above `Scratch_Base`, which is its own
arithmetic. And `Ref` hands back an `access constant` into a cell, carrying
the lifetime rule `adi-resolved_styles.ads:28-33` states, so the generic
answers by value and each caller decides whether it wants an accessor and
owns the rule that comes with one.

`Adi.Handle_Store` is a different animal despite also carrying a
generation: it is heap-backed and refcounted, with `Adjust`, `Finalize` and
four `Unchecked_Deallocation` instances. Bounded-static and
dynamic-controlled stay two packages.

A fixed array, with no container, no heap, no finalization and no secondary
stack, is what §4.5's restrictions ask for, and
`docs/proposals/spark_verification.md` records `Adi.Resolved_Styles`' body
holding 25 SPARK legality errors, all of them containers and `'Access`.
Lifting the pool out takes it clear of both, which makes it the cheapest
proof target after `Adi.Layout_Util`.

### 4.7   Finding a selector

§4.2 removed the allocation on the apply path, which leaves two costs
underneath it, both on the lookup rather than on the value.

`Find_Selector_Index` (`adi-css_parser.adb:3983-3996`) walks every selector in
the sheet and converts an `Unbounded_String` with `To_String` per candidate
before comparing:

```ada
for I in 1 .. Natural (Impl.Selectors.Length) loop
   if Impl.Selectors (I).Kind = Kind
     and then To_String (Impl.Selectors (I).Name) = Key
```

The `Static_Mode` branch of `Selector_Styles` (`adi-css_source.adb:218-228`)
has the same shape over `Static_Styles`, so a release build pays a version of
it too. A lookup keyed on `(Kind, lowered name)` answers both, and
`Adi.CSS_Styles`' text store already holds a form of the key.

`Combined_Styles` (`adi-css_source.adb:266-292`) folds `Selector_Styles` over
the tag, each class in the class list, and the id, through
`Multi_Class_Styles` (`:238-264`). Every bound widget computes it afresh, so a
list of rows sharing a class computes one answer once per row.

Memoising it on the same inputs is what §4.2 makes affordable: an entry is a
`Part_Style_Array`, at 96 bytes where it stood at 221,952, so a memo over
every distinct `(tag, classes, id)` an application uses is kilobytes. Before
§4.2 the same memo over a few hundred triples ran to tens of megabytes, which
is why the recomputation stands.

Three things travel with it. Invalidation reaches every path that changes what
the fold answers — `Load_File`, `Load_String` and the `Dynamic_Mode` reload
`Tick` drives, each followed by `Reapply_Bindings` (`:537-601`). The bound
follows §4.3's treatment of the other stores. And the hit and miss counts
surface beside the existing cache counters, which §6 records as the
precondition for measuring any of this.

The measurement that sizes both: an apply against a sheet of M selectors for N
widgets, in selector comparisons and in wall time, before and after.

---

## 5   Runtime state from the application

`.alarm` restyled to `.alarm.critical` while it runs, and
`.alarm[severity="critical"]` selecting on a value the application sets,
with the property name reaching the release binary as a constant rather
than as a string.

### 5.1   What the interaction states leave out

`:hover`, `:pressed`, `:focus`, `:disabled` and `:checked` describe what a
pointer and a keyboard are doing. Domain state is the other half: an alarm
row at ok, warning or critical; a field valid, invalid or pending; a link
connected, degraded or offline; a row read or unread. Each changes while
the application runs and each belongs in the stylesheet.

Class bindings run one way. `Bind_Class` (`adi-css_source.ads:154`) and its
siblings attach a widget to the selectors that name it, and the tree holds
no counterpart that detaches or replaces one. A row moving from ok to
critical therefore reaches `Set_Part_Style` and carries its appearance in
Ada, or is destroyed and rebuilt.

Two features answer this, and the first is a fraction of the second.

### 5.2   Classes a widget can change, and why they are not the answer

`Set_Class`, `Add_Class` and `Remove_Class` reach every use above through
the machinery that already parses, binds and cascades `.critical`: the
binding tables — `Bindings` and `Effective` in both `CSS_Source` and
`CSS_Parser` — gain a removal beside the append §4.3 records, and a
widget whose class set changes clears its cache the way
`Bump_Style_Version` does for a state. It is a fraction of the work
below, and it was considered first for that reason.

It was set aside because it makes the wrong thing mutable. A class
change alters a widget's *rule set*: `Bindings` grows past what §4.3
already flags, the merge order of several classes becomes a function of
when each was added, and a live reload has to replay a history of
mutations rather than a configuration. Properties leave the rule set
fixed at bind time and vary only the *selection among* rules — the
invariant `:hover` already has, and the one the memo, the cache key and
the resolved-style store were each built around. For a bounded-memory
target that is the stronger property, so the vocabulary below is what
landed.

What a class leaves open besides is exclusivity — `.critical` and
`.warning` sit on one widget as readily as either alone — and a value a
style can read.

### 5.3   A vocabulary interned at elaboration

An application declares each property from an enumeration of its own, at
library level, where elaboration assigns each name a dense index:

```ada
type Severity_Level is (Ok, Warning, Critical);

package Severity is new Adi.Widget_Properties.Enumerated
  (Name => "severity", Values => Severity_Level);
```

The value type is the enumeration itself, so a value of one property
handed to another fails to compile, where one `Property_Value` across
every property compiles and selects nothing. And a value's index is its
position in the enumeration, so nothing is registered per value: the
whole of registration is a property taking the next index, and the bound
check lands at the instantiation, where `Values'Range` is known, and
refuses the property whole rather than value by value.

The untyped registry stays underneath, because dynamic mode only ever
has a name: `Find_Property` and `Find_Value` are what the runtime parser
resolves a bracket against, and the generic is a typed facade over them
rather than a replacement.

The registry therefore holds a dense index per property, the name beside
it that dynamic text resolves against, and nothing per value at all.
`Dynamic_Lookup => False` on a property drops even that name, and its
values' names with it, leaving the property reachable through the
constants a generated sheet emits — which is the embedded case, and
which nothing else needs, a generated sheet naming indices rather than
text. `Max_Properties` and `Max_Values_Per_Property` size the registry
as constants, so it is one set of arrays and a count.

Elaboration is the window in which it is written, and read-only afterwards
is what §4.5's `No_Implicit_Heap_Allocations`, `No_Secondary_Stack` and
`No_Finalization` want, along with SPARK's `Abstract_State` and
`Initializes`. Registration at any later point trades all four for a
registry that grows, and belongs to a mode of its own.

### 5.4   The generated binding

`tools/css_to_ada.py` reads `[severity="critical"]` as text and emits the
constants the application declared, given the package that holds them
through `--properties-package`:

```ada
--  from  .alarm[severity="critical"] { color: red }
When_Property (App_Properties.Severity.Value (App_Properties.Critical))

--  from  .alarm[link]
When_Property_Set (App_Properties.Link.Id)

--  from  .alarm:not([severity="critical"])
When_Not_Property (App_Properties.Severity.Value (App_Properties.Critical))
```

The literal is named on its own, and the instantiation it is handed to
resolves which enumeration it belongs to, so `[power="on"]` and
`[state="on"]` reach the right one each. A flat constant per value would
collide there — both would name `App_Properties.On`, one of them
silently wrong — and naming the property beside the value instead leaves
a pair the generator can emit mismatched.

A name the application never declared is then a compile error at the
generated sheet, where a string comparison would answer as a selector
that matches nothing. Dynamic mode answers the same question through the
registry, which the parser reads while it builds the selector: an
undeclared property or value stops the sheet and leaves the last good one
standing, the shape the state-rule cap already uses at
`adi-css_parser.adb:3805`. A property declared without `Dynamic_Lookup`
is undeclared as far as that lookup is concerned, which is what makes
the gate a gate.

A fingerprint over the declaration list buys nothing on top of that, and
is dropped. It answered a design that assigned bits by declaration
order, where a reordered sheet aliased onto the wrong bit; importing the
constants makes order irrelevant, since the reference resolves to
whatever index elaboration gave. Registration is elaboration-only
besides, so the vocabulary a reloaded file resolves against is the one
the partition started with, and a file that renames a property names one
the registry does not carry.

Both halves of a condition are held to what an Ada identifier can be
spelled from — a letter, then letters, digits, hyphens and underscores —
in both pipelines, since both halves become part of one in the generated
sheet.

### 5.5   Where a value lives

A widget carries the properties it sets as pairs of indices. Interning is
canonical, so the whole assignment is one index into a shared store of
sorted pair sets, and the widget holds two bytes rather than a list.
`Resolved_Cache_Key` (`adi-widget.adb:380`) gains it as a component
beside the three `Packed_State_Bits` it already holds: fixed width,
hashable, and exact on equality because interning is canonical. The
vocabulary is then bounded by `Max_Properties` and the key by
nothing at all.

A selector's conditions are the same shape — a sorted set of
(property, ordinal, has-value, negated) tuples — so one store answers
both, and `Matches` is a walk of two small sorted arrays. `State_Selector` carries the condition index, which is what keeps
predefined equality on a selector exact and lets `Merge` go on comparing
selectors by value.

`Widget_State` keeps its six literals and the packed array §3 gave it, so
the states an interaction drives keep the bit tests and the six-iteration
`Matches` loop they have now. A widget naming no property carries the
default handle and reads exactly as it does today.

Setting a value clears the widget's cache the way `Set_State`
(`adi-widget.adb`) already does through `Bump_Style_Version`, and the memo
distinguishes values because the index is part of the key. A prepared
style records whether any of its rules names a property, so a widget
whose stylesheet reads none pays the version bump and nothing else.

### 5.6   Derived values

Over an enumerable domain, a value derived from a property *is* a
selection among pre-resolved styles: `[severity="critical"] { width: 200px }`
caches as `:hover` does, and N mutually exclusive values contribute N+1
keys. §5.5 covers it.

An open domain — `width: attr(progress)` over an arbitrary integer — puts
the value in the memo key, where a widget animating one mints a key per
frame and fills the store. Custom properties cover the per-sheet case by
textual substitution in `Resolve_Var_References`
(`adi-css_parser.adb:2787`), ahead of any `Style_Rules`.

The grammar is equality, existence and negation:
`[severity="critical"]`, `[severity]`, and `:not(...)` around either.
CSS has no not-equal attribute operator, so negation is the only way to
write a rule for every value but one, which is what a default beside a
set of values is. A condition therefore carries a negated flag rather
than a second set, which leaves `State_Selector` where it was and
`Both`/`Common` unchanged; a negated equality holds of a widget that
names the property not at all, as `:not()` does in CSS.

Ordering — `[level>3]` — needs the value indices to carry their order.
§5.3's enumeration gives them one, elaboration assigning indices in
`Values'Range` order, so the question is a grammar and a comparison
rather than a representation. It waits for a use.

`Specificity` counts set conditions, so a property condition scores 1 and
`[severity="critical"]:hover` scores 2, which is the CSS ranking already.
Both selector parsers take the bracket stage ahead of their colon split.
`:not()` is more than the model there: a `:not(` opening over a bracket
is taken by that same stage, since leaving it to the colon split would
strip the bracket out of the negation it belongs to. Every other
`:not()` passes through to the pseudo-class pass unchanged.

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
release, and the changed-mask gate with the `Pack_States` ceiling, which
are step 4's gate and stand on their own. §4.3's byte budget for the memo
travels with §4.4 in step 2. The
counters land first, since every later step is measured against them. Two
items here — the `CSS_Property_Set` for `Layout_Affecting_Diff`, and the
`Visibility` question — are settled by §3.5, so either they wait for step 2
or §3.5's table arrives early.

Step 0 splits in two: the contained fixes land first, then the merge
helpers, §4.3's lifetime work and the memo routing, which reach public API and
widget teardown.

**Step 1 — flat values.** Section 4.1. Four properties, and the whole
chain leaves finalization behind.

**Step 2 — handles all the way down.** Section 4.2: `Widget_Style` and
`Style_Rules` become four-byte handles, which puts `Part_Style_Array` at 96
bytes under its own name and folds `Interned_Part_Styles`, `Intern` and
`Expand` into it. The public spellings hold, so what changes is the width
each carries. It stands on what §4.4 landed and on nothing in §3, and it
leaves §3 one fat type to take: `Style_Rules` at its construction site.

**Step 2a — finding a selector.** Section 4.7: the keyed lookup and the
`Combined_Styles` memo. It follows step 2 twice over — step 2 is what makes
the lookup the dominant term on the apply path, and what puts a memo entry at
96 bytes. It stands on nothing in §3.

**Step 3 — composition.** Section 4.6's pool lands first, taking the
animation scratch with it, since it stands alone and both users want it.
Then sections 3.1 to 3.3: the composer, the eight-byte slot, and `Intern`
overloaded per value type. `tools/css_to_ada.py` emits
chains, and the `Style_Rules` aggregate takes `pragma Obsolescent` on the way
to leaving before 1.0, which is what frees the value representations it
pins. Sections 3.4 to 3.7 follow
it — the sweeps, the sizing and the parser table — and §4.4's field-width
narrowings, which the slot leaves as an optimisation of each value store
rather than a prerequisite. The `State_Selector` shape settles before the
rule form does.

**Step 4 — user properties.** Sections 5.3 to 5.6, on step 0's rule cap and
hash widening, on step 2's per-rule size, and on §4.4's interning for the
key component §5.5 adds. §5.2's runtime classes were considered ahead of
it and set aside there.

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
resolve the same CSS and every step touches both. §5.4 adds a third
encoding in the vocabulary, where the generated side names constants and
the parsed side resolves text against the registry.
`tests/src/side_longhand_test.adb` holds the pattern: install the
generated sheet, parse the CSS it came from, require identical
resolution. `tests/src/widget_property_test.adb` follows it for §5.

**32-bit and WebAssembly.** Every figure here is x86-64. `Style_Handle`
ranges, `access constant` placement and `Unsigned_16` packing each behave
differently on a 32-bit build, and the WASM port carries one recorded
frontend divergence in `Specificity`.

**Concurrency.** `docs/style_storage_optimization.md` records single-threaded
style mutation as an assumption. §4.2's interning at elaboration, §4.3's
eviction rank and §5.5's interned assignment each sit inside it.

**A key generated at elaboration, rather than an enumeration.** §3.2 keys a
slot on `CSS_Property`, a closed enumeration the compiler checks a `case` over.
A registry handing out a dense index at elaboration — the shape
`Adi.Widget_Properties` already ships for §5's vocabulary — would key the same
slot and open the set, so a widget outside the library declares a property of
its own. What it spends is the exhaustive check: §6's `Layout_Affecting_Diff`
names 47 of 66 fields, and the fix there is a `CSS_Property_Set` the compiler
holds complete. CSS's own answer to open extension is the custom property, so
a third mechanism beside the two is the alternative to choosing between them.

**A sparse resolved style.** §4.4 stores one `Resolved_Style` per distinct
resolution, at 840 bytes measured, capped at 16,384 entries and 13.8 MB. Every
one of the 66 carries a value after the cascade, and a handful of them differ
from the defaults a table would answer, so a bitmap over the differences would
hold an entry in about a tenth of that. What it spends is the read path, where
layout and rendering reach a value by name at a fixed offset and a sparse form
answers through a test, a popcount and a dependent load.

The trade turns on a figure nothing reports: how many distinct resolutions a
real tree produces. Below a few hundred the store is 25 KB and the dense form
is free; near the cap, sparse entries multiply the headroom that eviction rank
is currently spending. `perf_stats` reports texture residency and says nothing
of resolved-store occupancy, so the instrument comes first.

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
