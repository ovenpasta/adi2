# Adding a New CSS Property

This guide walks through every file that needs to change when adding a new CSS property to Adi. The `outline` property (added as a group of four longhands plus one shorthand) is used as the running example throughout.

---

## Overview

A CSS property flows through the system in six layers:

```
CSS text
  --> Runtime parser   (adi-css_parser.adb)          -- parses at runtime
  --> Build-time gen   (tools/css_to_ada.py)          -- compiles to Ada constants
  --> Style types      (adi-css_styles.ads/adb)       -- stored in Style_Rules / Resolved_Style
  --> Rendering        (adi-widget.adb)               -- drawn on screen
  --> Tests            (tests/src/css_parser_test.adb, tools/test_css_to_ada.py)
  --> Documentation    (docs/css_styling.md)
```

Each layer has a specific role. Skip rendering if the property only affects layout (which is handled separately), or skip layout if the property is purely visual like `outline`.

---

## Step 1 — Style Types (`src/adi-css_styles.ads`)

This file defines the Ada types that hold CSS values. Four things need adding:

### 1a. Value type (if new)

If the property uses an enumeration or compound type that doesn't already exist, define it near the related types. For outline, we added a new enum after the border types:

```ada
type Outline_Style_Kind is (Outline_None, Outline_Solid, Outline_Dashed, Outline_Dotted);
```

If the property reuses an existing type (e.g. `Length_Value`, `Color_Value`), skip this.

### 1b. Default constant

Every property needs a default that matches the CSS initial value:

```ada
Default_Outline_Width  : constant Length_Value := Zero_Length;
Default_Outline_Color  : constant Color_Value := C (Current_Color);
Default_Outline_Style  : constant Outline_Style_Kind := Outline_None;
Default_Outline_Offset : constant Length_Value := Zero_Length;
```

### 1c. Optional wrapper package

`Style_Rules` fields are optional (unset / cleared / set) so the cascade can distinguish "not specified" from "explicitly set to the default". Instantiate `Optional_Values` for each field:

```ada
package Opt_Outline_Width  is new Optional_Values (Length_Value, Default_Outline_Width);
package Opt_Outline_Color  is new Optional_Values (Color_Value, Default_Outline_Color);
package Opt_Outline_Style  is new Optional_Values (Outline_Style_Kind, Default_Outline_Style);
package Opt_Outline_Offset is new Optional_Values (Length_Value, Default_Outline_Offset);
```

Add these near the existing `Opt_*` packages (around line 900).

### 1d. Fields in `Style_Rules` and `Resolved_Style`

Add the optional fields to `Style_Rules`:

```ada
Outline_Width  : Opt_Outline_Width.Optional  := Opt_Outline_Width.Unset;
Outline_Color  : Opt_Outline_Color.Optional  := Opt_Outline_Color.Unset;
Outline_Style  : Opt_Outline_Style.Optional  := Opt_Outline_Style.Unset;
Outline_Offset : Opt_Outline_Offset.Optional := Opt_Outline_Offset.Unset;
```

Add the concrete fields to `Resolved_Style`:

```ada
Outline_Width  : Length_Value := Default_Outline_Width;
Outline_Color  : Color_Value := Default_Outline_Color;
Outline_Style  : Outline_Style_Kind := Default_Outline_Style;
Outline_Offset : Length_Value := Default_Outline_Offset;
```

### 1e. Setter functions

Add convenience setter functions (used by the parser and code generator). If the type is unique enough for overload resolution, use `Set`; otherwise use a prefixed name:

```ada
function Set_Outline_Width (V : Length_Value) return Opt_Outline_Width.Optional
   renames Opt_Outline_Width.Val;
function Set_Outline_Color (V : Color_Value) return Opt_Outline_Color.Optional
   renames Opt_Outline_Color.Val;
function Set (V : Outline_Style_Kind) return Opt_Outline_Style.Optional
   renames Opt_Outline_Style.Val;
function Set_Outline_Offset (V : Length_Value) return Opt_Outline_Offset.Optional
   renames Opt_Outline_Offset.Val;
```

Note: `Set` works for `Outline_Style_Kind` because the type is unique. `Length_Value` and `Color_Value` are shared by many properties, so they need prefixed names (`Set_Outline_Width`, `Set_Outline_Color`) to avoid ambiguity.

---

## Step 2 — Merge & Resolve (`src/adi-css_styles.adb`)

### 2a. Merge

In the `Merge` function, add one line per field. `Merge` combines two `Style_Rules` (base + override) following CSS cascade rules:

```ada
Outline_Width  => Opt_Outline_Width.Merge (Base.Outline_Width, Override.Outline_Width),
Outline_Color  => Opt_Outline_Color.Merge (Base.Outline_Color, Override.Outline_Color),
Outline_Style  => Opt_Outline_Style.Merge (Base.Outline_Style, Override.Outline_Style),
Outline_Offset => Opt_Outline_Offset.Merge (Base.Outline_Offset, Override.Outline_Offset),
```

### 2b. Resolve

In the `Resolve` function, add one line per field. `Resolve` converts optional `Style_Rules` to concrete `Resolved_Style`:

```ada
Outline_Width  => Opt_Outline_Width.Resolve (S.Outline_Width),
Outline_Color  => Opt_Outline_Color.Resolve (S.Outline_Color),
Outline_Style  => Opt_Outline_Style.Resolve (S.Outline_Style),
Outline_Offset => Opt_Outline_Offset.Resolve (S.Outline_Offset),
```

---

## Step 3 — Runtime CSS Parser (`src/adi-css_parser.adb`)

In the `Apply_Property` procedure, add branches for each CSS property name. This is a large `if/elsif` chain matching on the property name string.

### Longhands

```ada
elsif P = "outline-width" then
   if Parse_Length (V, LVal) then
      Rules.Outline_Width := Set_Outline_Width (To_Length (LVal));
   end if;
elsif P = "outline-color" then
   if Parse_Color (V, CVal) then
      Rules.Outline_Color := Set_Outline_Color (CVal);
   end if;
elsif P = "outline-style" then
   if LV = "none" then Rules.Outline_Style := Set (Outline_None);
   elsif LV = "solid" then Rules.Outline_Style := Set (Outline_Solid);
   elsif LV = "dashed" then Rules.Outline_Style := Set (Outline_Dashed);
   elsif LV = "dotted" then Rules.Outline_Style := Set (Outline_Dotted);
   end if;
elsif P = "outline-offset" then
   if Parse_Length (V, LVal) then
      Rules.Outline_Offset := Set_Outline_Offset (To_Length (LVal));
   end if;
```

### Shorthand

Shorthands split the value into tokens and detect each component by type. Use `Split_Whitespace_Tokens` (not plain `Split`) to correctly handle `rgb(...)` with spaces inside parentheses:

```ada
elsif P = "outline" then
   declare
      Tokens : Token_Vectors.Vector;
      Tok_L  : Parsed_Length;
      Tok_C  : Color_Value;
   begin
      Split_Whitespace_Tokens (V, Tokens);
      for T of Tokens loop
         declare
            Tok     : constant String := To_String (T);
            Tok_Low : constant String := Lower (Tok);
         begin
            if Tok_Low = "none" then
               Rules.Outline_Style := Set (Outline_None);
            elsif Tok_Low = "solid" then
               Rules.Outline_Style := Set (Outline_Solid);
            elsif Tok_Low = "dashed" then
               Rules.Outline_Style := Set (Outline_Dashed);
            elsif Tok_Low = "dotted" then
               Rules.Outline_Style := Set (Outline_Dotted);
            elsif Parse_Color (Tok, Tok_C) then
               Rules.Outline_Color := Set_Outline_Color (Tok_C);
            elsif Parse_Length (Tok, Tok_L) then
               Rules.Outline_Width := Set_Outline_Width (To_Length (Tok_L));
            end if;
         end;
      end loop;
   end;
```

### Available parser helpers

The parser provides these helpers for value parsing:

| Helper | Returns | Parses |
|--------|---------|--------|
| `Parse_Length (V, LVal)` | `Boolean` | Any CSS length (`10px`, `1.5em`, `50%`) |
| `Parse_Color (V, CVal)` | `Boolean` | Named, hex, `rgb()`, `rgba()` |
| `Parse_Number (V, F)` | `Boolean` | Bare float |
| `Parse_Integer (V, I)` | `Boolean` | Bare integer |
| `Parse_Natural (V, N)` | `Boolean` | Non-negative integer |
| `Parse_Length_List (V, Ls)` | `Boolean` | 1-4 whitespace-separated lengths |
| `Split_Whitespace_Tokens (V, Toks)` | (proc) | Splits respecting parens/quotes |

The property name is in `P` (original case), the value string in `V`, and `LV` is the lowercased value.

---

## Step 4 — Build-Time Code Generator (`tools/css_to_ada.py`)

The Python script `css_to_ada.py` compiles CSS to Ada constants at build time. It needs parallel changes to the runtime parser.

### 4a. Update compile-time CSS spec (`tools/css_spec.py`)

Add the property to `SUPPORTED_PROPERTIES` in `tools/css_spec.py`:

- Choose a canonical property name (`canonical_name`)
- Add aliases when needed (canonicalize only true aliases; keep distinct longhands like `overflow-x` / `overflow-y` as separate canonical properties)
- Set the value validator key (`validator`)

If this step is skipped, `css_to_ada.py` will treat the property as out-of-spec and emit warnings (or fail in `--strict` mode).

### 4b. Enum map (if applicable)

Add a mapping dict for enumeration values:

```python
OUTLINE_STYLE_MAP = {
    "none": "Outline_None",
    "solid": "Outline_Solid",
    "dashed": "Outline_Dashed",
    "dotted": "Outline_Dotted",
}
```

### 4c. Property generation in `generate_style_rules_ada()`

Add `elif` branches in the property loop. The function builds Ada `Style_Rules` field assignments:

```python
# Longhands
elif prop == "outline-width":
    length = parse_length(value)
    if length:
        ada_field = f"Outline_Width => Set_Outline_Width ({generate_length_ada(length)})"

elif prop == "outline-color":
    color = parse_color(value)
    if color:
        ada_field = f"Outline_Color => Set_Outline_Color ({generate_color_ada(color)})"

elif prop == "outline-style":
    if value.lower() in OUTLINE_STYLE_MAP:
        ada_field = f"Outline_Style => Set ({OUTLINE_STYLE_MAP[value.lower()]})"

elif prop == "outline-offset":
    length = parse_length(value)
    if length:
        ada_field = f"Outline_Offset => Set_Outline_Offset ({generate_length_ada(length)})"

# Shorthand
elif prop == "outline":
    parts = split_css_whitespace_tokens(value)
    for part in parts:
        if part.lower() in OUTLINE_STYLE_MAP:
            fields.append(f"{indent}Outline_Style => Set ({OUTLINE_STYLE_MAP[part.lower()]})")
            continue
        color = parse_color(part)
        if color:
            fields.append(f"{indent}Outline_Color => Set_Outline_Color ({generate_color_ada(color)})")
            continue
        length = parse_length(part)
        if length:
            fields.append(f"{indent}Outline_Width => Set_Outline_Width ({generate_length_ada(length)})")
    continue  # Skip ada_field since we appended directly
```

Key points:
- For longhands, set `ada_field` and let the loop append it.
- For shorthands that expand to multiple fields, append to `fields` directly and use `continue` to skip the single-field append.
- Use `split_css_whitespace_tokens()` (not `.split()`) for shorthands that may contain `rgb(...)` values.
- If a shorthand expands to longhands (like `overflow`), keep storage in the longhand fields only (`Overflow_X`/`Overflow_Y`) rather than adding a redundant shorthand field.

---

## Step 5 — Rendering (`src/adi-widget.adb`)

If the property has a visual effect, add rendering code. For outline, this goes in `Render_Panel` after the border/background rendering.

The outline is drawn outside the border box, expanding outward by `offset + width`:

- Compute pixel values from the resolved style
- Check if outline should be drawn (`Outline_Style /= Outline_None` and width > 0)
- Build outer and inner rectangles by expanding the geometry rect outward
- For rounded widgets: use `Render_Rounded_Border_Ring` + `Render_AA_Fringe`
- For non-rounded widgets: draw 4 SDL rect fills (top/right/bottom/left edges)

If your property affects **layout** rather than rendering (e.g. a new sizing mode), modify the layout engine instead.

If your property is **style-only with no rendering** (e.g. `cursor`), you may only need to read it from `Resolved_Style` at the appropriate point.

---

## Step 6 — Tests

### 6a. Runtime parser test (`tests/src/css_parser_test.adb`)

Add CSS strings to the test input, resolve the styles, and assert the values:

```ada
--  In the CSS constant string:
".outline-long { outline-width: 3px; outline-style: solid; "
& "outline-color: rgb(100, 200, 50); outline-offset: 4px; }" & ASCII.LF &
".outline-short { outline: 2px solid rgb(208, 188, 255); }" & ASCII.LF &

--  Resolve:
Outline_Long_Styles : constant Part_Style_Array :=
   Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-long");
Outline_Long_Main : constant Resolved_Style :=
   Compute_Resolved (Outline_Long_Styles (Main_Part).Style, No_States, No_States);

--  Assert:
Assert (Outline_Long_Main.Outline_Width.Amount = 3.0
        and then Outline_Long_Main.Outline_Width.Unit = Px,
        "outline-width longhand should parse");
Assert (Outline_Long_Main.Outline_Style = Outline_Solid,
        "outline-style longhand should parse");
```

Test all longhands, the shorthand, longhand-after-shorthand override, and the `none` keyword.

Build and run: `alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=css_parser_test && ./tests/bin/css_parser_test`

### 6b. Code generator test (`tools/test_css_to_ada.py`)

Add Python unit tests that call `generate_style_rules_ada()` with the new properties and assert the output contains the expected Ada fragments:

```python
def test_outline_shorthand(self):
    ada = self._gen({"outline": "2px solid rgb(208, 188, 255)"})
    self.assertIn("Outline_Width => Set_Outline_Width (Px (2.0))", ada)
    self.assertIn("Outline_Style => Set (Outline_Solid)", ada)
    self.assertIn("Outline_Color => Set_Outline_Color (RGB (208, 188, 255))", ada)
```

Run: `python3 tools/test_css_to_ada.py`

---

## Step 7 — Documentation

Update `docs/css_styling.md` to add the new property to the appropriate table in the "Supported Properties" section.

---

## Checklist

When adding a new CSS property, touch these files:

| # | File | What to add |
|---|------|-------------|
| 1 | `src/adi-css_styles.ads` | Value type, defaults, `Opt_*` package, `Style_Rules` field, `Resolved_Style` field, `Set` function |
| 2 | `src/adi-css_styles.adb` | `Merge` line, `Resolve` line |
| 3 | `src/adi-css_parser.adb` | `elsif P = "..."` branch in `Apply_Property` |
| 4 | `tools/css_spec.py` + `tools/css_to_ada.py` | Spec entry (`SUPPORTED_PROPERTIES`) + enum map/`elif prop == "..."` generation |
| 5 | `src/adi-widget.adb` | Rendering code (if visual), or layout code (if layout-affecting) |
| 6 | `tests/src/css_parser_test.adb` | CSS test input + assertions |
| 7 | `tools/test_css_to_ada.py` | Python unit tests for code generation |
| 8 | `docs/css_styling.md` | Property table entry |

### Common pitfalls

- **Use `Split_Whitespace_Tokens` for shorthands**, not `.split()` / plain whitespace splitting. Values like `rgb(10, 20, 30)` contain spaces inside parentheses.
- **`Set` function name collisions**: If the value type is shared (like `Length_Value`), use a prefixed name (`Set_Outline_Width`) instead of overloading `Set`, which would be ambiguous.
- **Rebuild generated styles** after changing `css_to_ada.py`: run `tools/generate_example_styles.sh`.
- **Both parsers must agree**: The runtime parser and the Python generator must produce equivalent `Style_Rules` fields for the same CSS input. If one supports a property, the other must too.
