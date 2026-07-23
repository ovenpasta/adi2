# STORAGE_ERROR in material_demo — Investigation Report

## Symptom

Running `./examples/bin/material_demo` crashed immediately on startup:

```
raised STORAGE_ERROR : s-intman.adb:136 explicit raise
```

The program never opened a window. The error occurred during elaboration,
before any SDL calls.

## What STORAGE_ERROR Means in GNAT

GNAT maps `SIGSEGV` signals to `STORAGE_ERROR` via its interrupt manager
(`s-intman.adb`). The "explicit raise" text means GNAT's signal handler caught
a segmentation fault and re-raised it as an Ada exception. In practice this
almost always indicates **stack overflow** — the program ran out of stack space
and touched a guard page.

The default thread stack on Linux is 8 MB (`ulimit -s` reports 8192 KB).

## Diagnosis Steps

### 1. Confirm it is a stack issue

Increased the stack limit and re-ran:

```bash
ulimit -s 16384
./examples/bin/material_demo   # runs successfully
```

This confirmed the 8 MB default stack was insufficient.

### 2. Identify the stack-heavy functions

Rebuilt with GCC's `-fstack-usage` flag, which writes `.su` files reporting
the static stack size of every compiled function:

```bash
alr exec -- gprbuild -P examples/examples.gpr \
    -XEXAMPLE_KIND=material_demo -f -cargs -fstack-usage
```

Then sorted by stack size:

```bash
sort -t'	' -k2 -rn examples/obj/material_demo/material_demo_ui.su | head -5
```

Results:

| Function | Stack (bytes) |
|----------|--------------|
| `Build` (material_demo_ui.adb) | **7,464,384** (7.1 MB) |
| `Material_Demo_Styles` elaboration | **1,069,616** (1.0 MB) |

Together these exceeded the 8 MB stack limit.

### 3. Find the root cause in the generated code

The `Build` function in the generated `material_demo_ui.adb` contained a
single call to `Set_Static_Entries` passing a large array aggregate:

```ada
Adi.CSS_Source.Set_Static_Entries (Source, [
   Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles),
   Adi.CSS_Source.Class_Entry ("app-bar", App_Bar_Class_Part_Styles),
   ...  --  24 entries total
]);
```

Each `Static_Style_Entry` contains a `Part_Style_Array`, which holds a
`Widget_Style` per part kind. A single entry is roughly 300 KB. The 24-entry
aggregate was constructed entirely on the stack before being passed to the
procedure — totalling 7.1 MB.

The styles package elaboration added another 1 MB of package-level constants
being initialized on the stack during elaboration.

## Fix

Added an incremental API to `Adi.CSS_Source`:

```ada
procedure Clear_Static_Entries (Source : in out Style_Source);
procedure Add_Static_Entry (Source : in out Style_Source;
                            Entry_Value : Static_Style_Entry);
```

Updated the code generator (`tools/xml_to_ada.py`) to emit individual
`Add_Static_Entry` calls instead of one aggregate:

```ada
--  Before (7.1 MB on stack):
Adi.CSS_Source.Set_Static_Entries (Source, [
   Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles),
   Adi.CSS_Source.Class_Entry ("app-bar", App_Bar_Class_Part_Styles),
   ...]);

--  After (one entry at a time, ~300 KB peak):
Adi.CSS_Source.Clear_Static_Entries (Source);
Adi.CSS_Source.Add_Static_Entry (Source,
   Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
Adi.CSS_Source.Add_Static_Entry (Source,
   Adi.CSS_Source.Class_Entry ("app-bar", App_Bar_Class_Part_Styles));
...
```

Each call briefly places one entry on the stack and immediately appends it to
the internal vector, so peak stack usage dropped from 7.1 MB to ~300 KB.

## Regression test

`tests/src/css_source_test.adb` includes tests for `Clear_Static_Entries` and
`Add_Static_Entry` that verify incremental registration produces the same
style-merge results as the bulk `Set_Static_Entries` API.

## Follow-up: `css_parser_test` stack overflow (2026-02)

### Symptom

Running `./tests/bin/css_parser_test` with the default Linux stack (`ulimit -s`
reports `8192`) raised:

```
raised STORAGE_ERROR : s-intman.adb:136 explicit raise
```

### Root causes

Two contributors were identified:

1. **By-value style copies in parser apply/rebind paths** (`adi-css_parser.adb`)
   briefly copied `Part_Style_Array` values.
2. **Very large single test frame** in `tests/src/css_parser_test.adb`:
   many `Part_Style_Array` and `Resolved_Style` constants were declared in one
   giant `declare` block and stayed live together.

### Fixes applied

1. **Parser hardening** (`src/adi-css_parser.adb`)
   - `Reapply_Bindings` now does direct selector lookup + container reference
     instead of returning `Part_Style_Array` by value.
   - `Apply` now does direct indexed access + fallback instead of calling
     `Styles_For(...)` by value.

2. **Test frame reduction** (`tests/src/css_parser_test.adb`)
   - Split one monolithic `declare` block into multiple scoped blocks so large
     style/resolved objects are not all live at once.
   - Assertion coverage and pass criteria stayed unchanged.

### Measured result

After fixes and rebuilding with `-fstack-usage`:

| Item | Before | After |
|------|--------|-------|
| `Css_Parser_Test` stack usage | 8,345,520 bytes | 5,045,104 bytes |
| `adi.css_parser.reapply_bindings` | 193,136 bytes | 256 bytes |
| `adi.css_parser.apply` | 192,944 bytes | 96 bytes |

Estimated margin on default 8 MB stack after fixes:

- `8,388,608 - 5,045,104 = 3,343,504` bytes (~3.26 MB)

`./tests/bin/css_parser_test` now passes at default `ulimit -s 8192` with
`156/156` tests passing.

## Follow-up: css_to_ada.py elaboration stack overflow (2026-03)

### Symptom

Applications using CSS files with many classes (e.g. `material_demo` with
38 selectors → 312+ style objects) crashed on startup with `STORAGE_ERROR`
even after the previous fixes, when built with `Static_Mode`.

`ulimit -s 16384` made them run — confirming stack overflow during
elaboration of the generated `*_styles.ads` package.

### Root cause

`css_to_ada.py` emitted every `Style_Rules`, `Widget_Style`, and
`Part_Style_Array` as a package-level constant:

```ada
Root_Class_Base_Style : constant Style_Rules := (
   Background_Color => ...,
   others => <>);
Root_Class_Style : constant Widget_Style :=
   From (Root_Class_Base_Style).Build;
Root_Class_Part_Styles : constant Part_Style_Array := [
   Main_Part => (Style => Root_Class_Style, Enabled => True),
   others => <>];
```

GNAT initialises all package-level constants in a single `___elabs`
procedure that runs at program startup on the main thread's stack. With
300+ large record and array constants the procedure overflowed 8 MB.

### First attempt: auto-split into child packages

The generator was extended with a `--split-constants N` option
(default 50): when the constant count exceeded the threshold the output
was split across standalone child packages (`My_Styles_Part_1`,
`My_Styles_Part_2`, …) each bounded by the threshold, with the parent
re-exporting every name via subprogram renames.

This reduced the elaboration cost *per package* but did not eliminate it.
The implementation also ran into Ada validity constraints:
`constant` is not permitted in object renaming declarations (RM 8.5.1),
and a parent package cannot `with` its own child packages, requiring
standalone (underscore-separated) names instead of dot-notation children.
The approach was abandoned.

### Fix: expression functions

Converted every generated constant to an **expression function**:

```ada
function Root_Class_Base_Style return Style_Rules is
  (Background_Color => ...,
   others => <>);
function Root_Class_Style return Widget_Style is
  (From (Root_Class_Base_Style).Build);
function Root_Class_Part_Styles return Part_Style_Array is
  ([Main_Part => (Style => Root_Class_Style, Enabled => True),
    others => <>]);
```

Expression functions are called on demand; GNAT generates no
initialisation procedure for them. The elaboration footprint of the
generated package drops to zero regardless of how many selectors the CSS
file contains. The split machinery was removed entirely.

The change was made entirely in `tools/css_to_ada.py` —
`generate_ada_package` now emits `function … return T is (expr);` instead
of `… : constant T := …;`. No changes to the runtime library were needed.

## Diagnosing Future STORAGE_ERROR Issues

If a program crashes with `STORAGE_ERROR : s-intman.adb:... explicit raise`:

1. **Confirm it is stack overflow** — run with `ulimit -s 16384` (or higher).
   If the crash goes away, it is a stack size problem.

2. **Find the offending function** — rebuild with `-fstack-usage`:
   ```bash
   alr exec -- gprbuild -P <project>.gpr -f -cargs -fstack-usage
   sort -t'	' -k2 -rn <obj_dir>/*.su | head -10
   ```
   Look for functions using more than ~1 MB of stack.

3. **Common causes in Ada/GNAT**:
   - **Large array aggregates passed by value** — the entire aggregate is
     built on the caller's stack before the call. Fix: pass elements one at a
     time, or use a package-level constant so the data lives in static storage.
   - **Large local variables** — arrays or records declared inside a procedure.
     Fix: allocate on the heap (`new`), or move to package level.
   - **Deep or infinite recursion** — recursive tree walks on deep hierarchies.
     Fix: convert to an iterative loop with an explicit stack.
   - **Package elaboration** — large constant aggregates in package specs are
     initialized during elaboration. The elaboration code runs on the main
     thread's stack. Fix: convert constants to **expression functions**
     (`function F return T is (expr);`) — expression functions have zero
     elaboration footprint; GNAT generates no initialisation procedure for
     them. Splitting into smaller packages reduces the footprint per package
     but does not eliminate it.

4. **If increasing the stack is acceptable** — add a linker flag:
   ```
   for Default_Switches ("Ada") use ("-Wl,-z,stacksize=16777216");
   ```
   This sets the stack to 16 MB. This is a workaround, not a fix — prefer
   reducing actual stack usage.
