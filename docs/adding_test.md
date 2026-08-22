# Adding a New Test

This guide walks through creating and registering a new test program.

## 1. Create the test source file

Create `tests/src/<name>.adb`. The test is a standalone Ada procedure that uses the shared `Test_Support` package (in `tests/src/`) for assertions and reporting. Follow this pattern:

```ada
pragma Ada_2022;

with Test_Support; use Test_Support;

procedure My_Feature_Test is

   procedure Test_Something is
   begin
      Section ("basic arithmetic");
      Assert (1 + 1 = 2, "basic arithmetic works");
   end Test_Something;

begin
   Start_Suite ("My Feature Test");

   Test_Something;

   Finish;
end My_Feature_Test;
```

`Test_Support` provides:

- `Start_Suite (Name)` — prints the suite header
- `Section (Name)` — prints a `-- Name --` marker between test groups
- `Assert (Condition, Message)` — counts the check; failures print `[FAIL] Message`, passes are silent
- `Finish` — prints the pass/fail summary and sets a failing process exit status if any check failed. Call it as the last statement of the main procedure.
- `Failures` — number of failed checks so far, for the rare test that needs to branch on it

Key conventions:
- The procedure name must match the file name (e.g., `my_feature_test.adb` contains `procedure My_Feature_Test`)
- Group related tests into inner procedures (`Test_*`)
- Use descriptive `Assert` messages — on failure they are the only clue in the output
- For floating-point comparisons, use an epsilon-based local helper that delegates to `Assert`
- Always end with `Finish` — a test that never calls it cannot fail the process

## 2. Register in `tests/tests.gpr`

Add the test name to the `Test_Kind` type:

```
type Test_Kind is
  (...,
   "my_feature_test");
```

That is the only registration needed: `tools/configure.sh` and `tools/run_tests.sh` derive their test lists from `tests/tests.gpr` automatically, so they cannot drift from the declared `Test_Kind` set. Optionally add a run line to the test list in `CLAUDE.md`.

## 3. Build and run

```bash
# Build and run every test
alr exec -- tools/run_tests.sh

# Or build and run just this one
alr exec -- gprbuild -j0 -P tests/tests.gpr -XTEST_KIND=my_feature_test
./tests/bin/my_feature_test
```

## Tips

- Tests link against the Adi library, so all `Adi.*` packages are available
- No SDL window or renderer is needed for unit tests — most widget APIs work without one
- To test with images, use `Adi.Image.Load_SVG_Path` with a `null` renderer (creates a valid in-memory SVG image)
- To set widget geometry for `Build_Items` testing, use the public `Set_Geometry` procedure
- Use `Item_Count`, `Get_Item`, and `Get_Preferred_Size` to inspect widget state through public API
- To set CSS styles on a widget part, use `Set_Part_Style` with a `Widget_Style` built via `From(rules).Build`

## Checklist

| Step | File | What to add |
|------|------|-------------|
| Source | `tests/src/<name>.adb` | Test procedure using `Test_Support` |
| GPR | `tests/tests.gpr` | Name in `Test_Kind` |
| Docs (optional) | `CLAUDE.md` | Run line in the test list |

## The example widget-tree goldens

A unit test pins what someone thought to write down. The goldens in
`tests/goldens/trees/` pin everything else: for each of the examples,
the whole widget tree it lays out — every type, position, size, text,
state and parent — as the running application reports it over MCP.

```bash
tools/widget_trees.py                 # check every example
tools/widget_trees.py demo_flex       # just these
tools/widget_trees.py --update        # accept what the apps report now
```

They run under SDL's dummy video driver, so no display is needed; the
dummy and the real driver report the same tree, because geometry comes
from layout and font metrics rather than the windowing backend. The tool
rebuilds the examples first, since an example links `libAdi.a`
statically and a stale binary would report on the library it was built
against rather than the one you changed.

A diff names the widget and the field:

```
DIFF  button_example
  w            1.1.1  102.0 -> 96.0
  text         1.1.2  Delete -> Remove
  gone         1.1.3  adi.widget.button.button_widget
```

Read every line before running `--update`. A golden is a record of what
the library does, so a change to one is a claim that the new geometry is
the correct geometry — and the diff is the only place that claim gets
examined. Changes to layout, styling or an example's own XML or CSS will
legitimately move these numbers; anything else moving is the finding.
