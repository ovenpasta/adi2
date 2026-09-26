# Adding a New Example

This guide walks through registering a new example program in the Adi build system. The `image_example` is used as a worked example throughout.

## 1. Create the CSS file

Create `demos/css/<name>.css` with your stylesheet. Follow existing examples for conventions (dark themes, class selectors, part selectors like `::label` and `::icon`).

### Pick a pixel convention

Adi supports two equally valid CSS unit conventions; both are present in the bundled examples. Pick one per example and stick with it:

- **Physical `px` + explicit `dp`** (used by `material_demo`, `font_example`). `border: 1px` is one device pixel on every display; everything that should scale uses `dp`, `dip`, or `rem`. Hairlines stay hairline on Retina, fractional Windows scales etc. Your `.adb` does not touch `Adi.Layout_Util`.
- **Logical `px` everywhere** (used by `label_example` and most other bundled examples). All sizes are written in `px`; the app opts the runtime into web-style scaling by calling `Adi.Layout_Util.Set_Px_Maps_To_Dip (True)` right after `App.Init`. CSS reads naturally to readers coming from the web, and every length scales together.

See `docs/css_styling.md` "Treating CSS `px` as logical pixels" for the trade-off. Don't mix within one example — the contrast between `1px` and `1dp` only exists when the toggle is off.

## 2. Create the XML UI file (optional)

If using the XML UI system, create `demos/xml/<name>.xml`. The root element is `<adi>`, containing a `<link>` to the CSS file and a `<window>` with widget children:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="demos/css/image_example.css"/>
  <window title="Image Example" width="1100" height="700">
    <box id="Root" class="root">
      <label text="Hello" class="title"/>
      <image id="My_Image" class="image"/>
    </box>
  </window>
</adi>
```

Available widget tags are defined in `tools/widgets.xml`: `box`, `label`, `button`, `switch`, `stack`, `text-input`, `text-editor`, `combo-box`, `image`, `animated-image`, `animated-widget`, `rlottie`, `html-view`, `texture-view`, `list-box`, `slider`, `integer-slider`, `value-input`, `integer-value-input`.

Widgets with an `id` attribute become named handle fields accessible from Ada code (e.g., `UI.My_Image`).

## 3. Register in the code generation scripts

An example that ships CSS must be listed in `tools/generate_demo_styles.sh`,
and one that ships XML in `tools/generate_demo_ui.sh`; the entry is what
writes the generated package the example compiles against.

### `tools/generate_demo_styles.sh`

Add a `generate_if_needed` call for the CSS file:

```bash
generate_if_needed "$CSS_DIR/image_example.css" "$OUT_DIR/image_example_styles.ads" "Image_Example_Styles"
```

### `tools/generate_demo_ui.sh` (if using XML)

Add a `generate_if_needed` call for the XML file:

```bash
generate_if_needed "$XML_DIR/image_example.xml" "Image_Example_UI"
```

### `tools/generate_demo_bundles.sh` (if bundling assets)

This script has no `generate_if_needed` helper: it carries one hand-written
staleness check and one `binary_to_ada.py` invocation. Copy that block, giving
the new bundle its own `OUT_FILE`, asset list and `--package-name`.

### `tools/generate_demo_translations.sh` (if translated)

Nothing to add per example. The script picks up every `demos/i18n/*.po`
and emits the single `I18N_Example_Translations` package; a new example reuses
it by adding its strings to the existing `.po` files.

### Run the generators

```bash
python3 tools/css_to_ada.py demos/css/image_example.css demos/generated/image_example_styles.ads --package-name Image_Example_Styles
python3 tools/xml_to_ada.py demos/xml/image_example.xml --output-dir demos/generated --package-name Image_Example_UI
```

For asset bundling:
```bash
python3 tools/binary_to_ada.py --output-dir demos/generated/ --package-name My_Example_Bundle --base-dir demos/assets/ demos/assets/icon.svg
```

The generated files go in `demos/generated/`.

## 4. Create the Ada main

Create `demos/src/<name>.adb`. For XML-based examples, the pattern is:

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

## 5. Register in `demos/demos.gpr`

Add `"image_example.adb"` to the project's `Main` list.

## 6. Register in `demos/alire.toml`

Add `"image_example"` to `executables`, so `alr run image_example` can select it.
`tools/build_demos.sh` builds the Alire crate and needs no separate list.
Call `Demo_Paths.Initialize` at the start of the main procedure so resources
resolve from both the demos crate and the repository root.

## 7. Register in `tools/configure.sh`

`configure.sh` writes a standalone build tree that does not read
`demos/demos.gpr`, so the name has to be added in both of its own lists.

### `Demo_Kind` in the generated `demos_build.gpr`

The heredoc at `type Demo_Kind is`:

```
      "image_example",
```

### `DEMO_KINDS` in the generated `build_all.sh`

The array at `DEMO_KINDS=(`:

```bash
  image_example
```

## 8. Build and run

```bash
# Build just this example
tools/build_demos.sh image_example

# Run it
./demos/bin/image_example
```

Or build every example with `tools/build_demos.sh`.

## Checklist

Six registration sites, plus the sources themselves.

| Step | File | What to add |
|------|------|-------------|
| CSS | `demos/css/<name>.css` | Stylesheet |
| XML (opt) | `demos/xml/<name>.xml` | UI definition |
| Ada main | `demos/src/<name>.adb` | Entry point |
| Registration 1 | `demos/demos.gpr` | Filename in `Main` |
| Registration 2 | `demos/alire.toml` | Name in `executables` |
| Registration 3 | `tools/configure.sh` | Name in the generated `Demo_Kind` |
| Registration 4 | `tools/configure.sh` | Name in `DEMO_KINDS` |
| Registration 5 | `tools/generate_demo_styles.sh` | `generate_if_needed` call |
| Registration 6 | `tools/generate_demo_ui.sh` | `generate_if_needed` call (if XML) |
| Bundle gen | `tools/generate_demo_bundles.sh` | A copy of the existing generate block (if bundling assets) |
