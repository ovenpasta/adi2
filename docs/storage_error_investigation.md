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
     thread's stack. Fix: split into smaller packages, or initialize lazily.

4. **If increasing the stack is acceptable** — add a linker flag:
   ```
   for Default_Switches ("Ada") use ("-Wl,-z,stacksize=16777216");
   ```
   This sets the stack to 16 MB. This is a workaround, not a fix — prefer
   reducing actual stack usage.
