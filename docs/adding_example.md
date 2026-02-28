# Adding a New Example

This guide walks through registering a new example program in the Adi build system. The `image_example` is used as a worked example throughout.

## 1. Create the CSS file

Create `examples/css/<name>.css` with your stylesheet. Follow existing examples for conventions (dark themes, class selectors, part selectors like `::label` and `::icon`).

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

Available widget tags are defined in `tools/widgets.xml`: `box`, `label`, `button`, `switch`, `stack`, `text-input`, `text-editor`, `combo-box`, `image`, `animated-image`, `animated-widget`, `rlottie`, `html-view`, `list-box`.

Widgets with an `id` attribute become named fields accessible from Ada code (e.g., `UI.My_Image`).

## 3. Register in code generation scripts

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

Add a `generate_if_needed` call for the asset files:

```bash
generate_if_needed "My_Example_Bundle" "$ASSETS_DIR/icon.svg" "$ASSETS_DIR/image.png"
```

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
with Adi.Window; use Adi.Window;
with Image_Example_UI;

procedure Image_Example is
   A : Adi.App.App;
   package UI is new Image_Example_UI.Instance;
   W : Window_Access;
begin
   A.Init;
   A.Set_Target_FPS (60);
   W := UI.Build;

   -- Post-build setup (load images, wire callbacks, etc.)

   A.Add_Window (W);
   A.Run;
end Image_Example;
```

## 5. Register in `examples/examples.gpr`

Add the example name to the `Example_Kind` type on line 4:

```
type Example_Kind is (..., "image_example");
```

## 6. Register in `tools/configure.sh`

Add the example name in two places:

1. The `Example_Kind` type in the generated `examples_build.gpr` template (around line 266)
2. The `EXAMPLE_KINDS` array used by `build_all.sh` (around line 374)

## 7. Register in `alire.toml`

Add a post-build action at the end of the `[[actions]]` list:

```toml
[[actions]]
type = "post-build"
command = ["gprbuild", "-P", "examples/examples.gpr", "-XEXAMPLE_KIND=image_example"]
```

## 8. Build and run

```bash
# Build just this example
alr exec -- gprbuild -P examples/examples.gpr -XEXAMPLE_KIND=image_example

# Run it
./examples/bin/image_example
```

Or build everything with `alr build`, which runs all post-build actions including the new example.

## Checklist

| Step | File | What to add |
|------|------|-------------|
| CSS | `examples/css/<name>.css` | Stylesheet |
| XML (opt) | `examples/xml/<name>.xml` | UI definition |
| Ada main | `examples/<name>.adb` | Entry point |
| GPR | `examples/examples.gpr` | Name in `Example_Kind` |
| Configure | `tools/configure.sh` | Name in `Example_Kind` + `EXAMPLE_KINDS` |
| Alire | `alire.toml` | Post-build `[[actions]]` entry |
| CSS gen | `tools/generate_example_styles.sh` | `generate_if_needed` call |
| XML gen | `tools/generate_example_ui.sh` | `generate_if_needed` call (if XML) |
| Bundle gen | `tools/generate_example_bundles.sh` | `generate_if_needed` call (if bundling assets) |
