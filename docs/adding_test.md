# Adding a New Test

This guide walks through creating and registering a new test program. The `image_widget_test` is used as a worked example.

## 1. Create the test source file

Create `tests/src/<name>.adb`. The test is a standalone Ada procedure (no framework required). Follow this pattern:

```ada
pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;

procedure Image_Widget_Test is
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   procedure Test_Something is
   begin
      Put_Line ("Test: description");
      Assert (1 + 1 = 2, "basic arithmetic works");
   end Test_Something;

begin
   Put_Line ("========================================");
   Put_Line ("   My Test Suite");
   Put_Line ("========================================");

   Test_Something;

   Put_Line ("Total:" & Test_Count'Image
             & "  Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Put_Line ("FAILED");
   else
      Put_Line ("All tests PASSED!");
   end if;
end Image_Widget_Test;
```

Key conventions:
- The procedure name must match the file name (e.g., `image_widget_test.adb` contains `procedure Image_Widget_Test`)
- Group related tests into inner procedures (`Test_*`)
- Print a summary with pass/fail counts at the end
- Use `Assert` for individual checks with descriptive messages
- For floating-point comparisons, use an epsilon-based `Assert_Close` helper

## 2. Register in `tests/tests.gpr`

Add the test name to the `Test_Kind` type:

```
type Test_Kind is
  (...,
   "image_widget_test");
```

## 3. Register in `tools/configure.sh`

Add the test name in two places:

1. The `Test_Kind` type in the generated `tests_build.gpr` template (inside the `Examples_Build` heredoc, around line 220):

   ```
         "svg_perf_test",
         "image_widget_test");
   ```

2. The `TEST_KINDS` array used by `build_all.sh` (around line 367):

   ```bash
   TEST_KINDS=(
     ...
     image_widget_test
   )
   ```

## 4. Build and run

```bash
# Build
alr exec -- gprbuild -P tests/tests.gpr -XTEST_KIND=image_widget_test

# Run
./tests/bin/image_widget_test
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
| Source | `tests/src/<name>.adb` | Test procedure |
| GPR | `tests/tests.gpr` | Name in `Test_Kind` |
| Configure | `tools/configure.sh` | Name in `Test_Kind` + `TEST_KINDS` |
