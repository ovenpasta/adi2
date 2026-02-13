# Adi Examples

This directory contains example programs demonstrating how to use the Adi GUI library.

## Building Examples

### Build all examples (via post-build action)
```bash
alr build
```
`alr build` also runs incremental example CSS generation before compiling examples.

### Build a specific example
```bash
gprbuild -P examples.gpr -XEXAMPLE_KIND=label_example
```

## Running Examples

Examples are built to `examples/bin/`:
```bash
./bin/label_example
```

## Available Examples

### label_example
Demonstrates label widget styling and icon usage.

### combo_box_example
Demonstrates overlay-based combo box dropdowns with styled option rows.

### overflow_example
Compares `overflow: visible` and `overflow: hidden` clipping behavior.

### grid_example
Demonstrates CSS grid layout (`display: grid`) with template rows/columns, gaps, and item spans.

### animated_image_example
Demonstrates `Adi.Widget.Animated_Image` playback controls (`Start`, `Stop`, `Reset`, looping) using `examples/assets/animhorse.gif`.

### html_view_example
Demonstrates `Adi.Widget.Html_View` with HTML loaded from assets, styles provided by embedded `<style>` and linked stylesheet resources, hyperlink callbacks, and custom image asset loading.

### Example Assets
- `examples/assets/bg.jpg` (widget demo background)
- `examples/assets/animhorse.gif` (animated image demo)
- `examples/assets/happycat.png` (label example icon)
- `examples/assets/lottie_sample.json` (rlottie demo animation)
- `examples/assets/html_view_example.html` (HTML view demo content)

### Shared Widget Defaults
`css/widget_defaults.css` defines reusable baseline styles for common widgets (`.button`, `.text-input`, `.list-box`, `.list-row`) and is generated as `generated/widget_defaults_styles.ads` for reuse across examples.

## Adding New Examples

1. Create your example file: `my_example.adb`
2. Update `examples.gpr`:
   - Add to the `Example_Kind` type: `type Example_Kind is ("label_example", "my_example");`
3. Update `alire.toml`:
   - Add a post-build action:
     ```toml
     [[actions]]
     type = "post-build"
     command = ["gprbuild", "-P", "examples/examples.gpr", "-XEXAMPLE_KIND=my_example"]
     ```
