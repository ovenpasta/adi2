# Adding a New Example

This guide walks through registering a new example program in the Adi build system. The `image_example` is used as a worked example throughout.

## 1. Create the CSS file

Create `examples/css/<name>.css` with your stylesheet. Follow existing examples for conventions (dark themes, class selectors, part selectors like `::label` and `::icon`).

### Pick a pixel convention

Adi supports two equally valid CSS unit conventions; both are present in the bundled examples. Pick one per example and stick with it:

- **Physical `px` + explicit `dp`** (used by `material_demo`, `font_example`). `border: 1px` is one device pixel on every display; everything that should scale uses `dp`, `dip`, or `rem`. Hairlines stay hairline on Retina, fractional Windows scales etc. Your `.adb` does not touch `Adi.Layout_Util`.
- **Logical `px` everywhere** (used by `label_example` and most other bundled examples). All sizes are written in `px`; the app opts the runtime into web-style scaling by calling `Adi.Layout_Util.Set_Px_Maps_To_Dip (True)` right after `App.Init`. CSS reads naturally to readers coming from the web, and every length scales together.

See `docs/css_styling.md` "Treating CSS `px` as logical pixels" for the trade-off. Don't mix within one example — the contrast between `1px` and `1dp` only exists when the toggle is off.

## 2. Create the XML UI file (optional)

If using the XML UI system, create `examples/xml/<name>.xml`. The root element is `<adi>`, containing a `<link>` to the CSS file and a `<window>` with widget children:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="examples/css/image_example.css"/>
  <window title="Image Example" width="1100" height="700">
    <box id="Root" class="root">
      <label text="Hello" class="title"/>
      <image id="My_Image" class="image"/>
    </box>
  </window>
</adi>
```

Available widget tags are defined in `tools/widgets.xml`: `box`, `label`, `button`, `switch`, `stack`, `text-input`, `text-editor`, `combo-box`, `image`, `animated-image`, `animated-widget`, `rlottie`, `html-view`, `list-box`, `slider`, `integer-slider`, `value-input`, `integer-value-input`.

Widgets with an `id` attribute become named handle fields accessible from Ada code (e.g., `UI.My_Image`).

## 3. Register in the code generation scripts

An example that ships CSS must be listed in `tools/generate_example_styles.sh`,
and one that ships XML in `tools/generate_example_ui.sh`. Without the entry the
generated package is never written and the example does not compile.

### `tools/generate_example_styles.sh`

Add a `generate_if_needed` call for the CSS file:

```bash
generate_if_needed "$CSS_DIR/image_example.css" "$OUT_DIR/image_example_styles.ads" "Image_Example_Styles"
```

### `tools/generate_example_ui.sh` (if using XML)

Add a `generate_if_needed` call for the XML file:

```bash
generate_if_needed "$XML_DIR/image_example.xml" "Image_Example_UI"
```

### `tools/generate_example_bundles.sh` (if bundling assets)

This script has no `generate_if_needed` helper: it carries one hand-written
staleness check and one `binary_to_ada.py` invocation. Copy that block, giving
the new bundle its own `OUT_FILE`, asset list and `--package-name`.

### `tools/generate_example_translations.sh` (if translated)

Nothing to add per example. The script picks up every `examples/i18n/*.po`
and emits the single `I18N_Example_Translations` package; a new example reuses
it by adding its strings to the existing `.po` files.

### Run the generators

```bash
python3 tools/css_to_ada.py examples/css/image_example.css examples/generated/image_example_styles.ads --package-name Image_Example_Styles
python3 tools/xml_to_ada.py examples/xml/image_example.xml --output-dir examples/generated --package-name Image_Example_UI
```

For asset bundling:
```bash
python3 tools/binary_to_ada.py --output-dir examples/generated/ --package-name My_Example_Bundle --base-dir examples/assets/ examples/assets/icon.svg
```

The generated files go in `examples/generated/`.

## 4. Create the Ada main

Create `examples/<name>.adb`. For XML-based examples, the pattern is:

```ada
pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;            --  only if using the logical-px convention
with Adi.Window; use Adi.Window;
with Image_Example_UI;

procedure Image_Example is
   A : Adi.App.App;
   package UI is new Image_Example_UI.Instance;
   W : Window_Handle;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);  --  drop this line for the
                                               --  physical-px convention
   A.Set_Target_FPS (60);
   W := UI.Build;

   -- After UI.Build: load images, wire callbacks, etc.

   A.Add_Window (W);
   A.Run;
end Image_Example;
```

## 5. Register in `examples/examples.gpr`

Add the example name to the `Example_Kind` type on line 4:

```
type Example_Kind is (..., "image_example");
```

This is the list `-XEXAMPLE_KIND` is checked against, so an unlisted name
cannot be built at all.

## 6. Register in `tools/build_examples.sh`

Add the example name to the `ALL_EXAMPLES` array:

```bash
ALL_EXAMPLES=(
  ...
  image_example
)
```

The array is what a bare `tools/build_examples.sh` iterates over. Naming the
example on the command line builds it either way; only the no-argument run
needs the entry.

## 7. Register in `tools/configure.sh`

`configure.sh` writes a standalone build tree that does not read
`examples/examples.gpr`, so the name has to be added in both of its own lists.

### `Example_Kind` in the generated `examples_build.gpr`

The heredoc at `type Example_Kind is`:

```
      "image_example",
```

### `EXAMPLE_KINDS` in the generated `build_all.sh`

The array at `EXAMPLE_KINDS=(`:

```bash
  image_example
```

## 8. Build and run

```bash
# Build just this example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=image_example

# Run it
./examples/bin/image_example
```

Or build every example with `tools/build_examples.sh`.

## Checklist

Six registration sites, plus the sources themselves. Miss any of the six and
the example either fails to build or is silently skipped.

| Step | File | What to add |
|------|------|-------------|
| CSS | `examples/css/<name>.css` | Stylesheet |
| XML (opt) | `examples/xml/<name>.xml` | UI definition |
| Ada main | `examples/<name>.adb` | Entry point |
| Registration 1 | `examples/examples.gpr` | Name in `Example_Kind` |
| Registration 2 | `tools/build_examples.sh` | Name in `ALL_EXAMPLES` |
| Registration 3 | `tools/configure.sh` | Name in the generated `Example_Kind` |
| Registration 4 | `tools/configure.sh` | Name in `EXAMPLE_KINDS` |
| Registration 5 | `tools/generate_example_styles.sh` | `generate_if_needed` call |
| Registration 6 | `tools/generate_example_ui.sh` | `generate_if_needed` call (if XML) |
| Bundle gen | `tools/generate_example_bundles.sh` | A copy of the existing generate block (if bundling assets) |
