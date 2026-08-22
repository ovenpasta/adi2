# Adi Examples

This directory contains example programs demonstrating how to use the Adi GUI library.

## Building Examples

### Build all examples
```bash
tools/build_examples.sh
```
`tools/build_examples.sh` regenerates example CSS, XML, bundles and translations
before compiling. `alr build` builds the library only.

### Build a specific example
```bash
tools/build_examples.sh label_example
```

Or, when the generated sources are already current:
```bash
gprbuild -P examples.gpr -XEXAMPLE_KIND=label_example
```

## Running Examples

Examples are built to `examples/bin/`:
```bash
./bin/label_example
```

## XML or Ada

Some examples declare their tree in `xml/`, others build it in Ada. This
is intentional.

XML for static layout. Ada for what XML cannot express: callbacks,
generic instantiation, content built at runtime, and resources whose
owner must outlive the widgets drawing them.

Both reach the same API. A new example goes wherever its subject is
clearer.

## Available Examples

Everything `tools/build_examples.sh` builds.

### hello_example
The smallest complete app: an XML window with a label and a button, styled from
one stylesheet.

### hello_raw_example
The same UI written by hand — handle constructors and `Style_Rules` aggregates
wired through `Set_Part_Style`, with no generated code.

### label_example
Label styling and icon usage: icon-plus-text arrangements driven by the
`::main` flex style, with `::label` and `::icon` styled separately.

### button_example
Buttons, toggle buttons and switches, with hover, pressed and disabled states.

### transition_example
CSS `transition`: each easing curve, individual animatable properties, several
named properties at once, and the same transition at different durations.

### text_input_example
Single-line `Adi.Widget.Text_Input`: inline labels, and a masked password field
whose cut/copy are disabled.

### text_editor_example
Multi-line `Adi.Widget.Text_Editor`: selection, read-only toggle, and clipboard
through `Adi.OS`.

### demo_flex
Flex layout reference: `flex-direction`, `justify-content`, `align-items`,
wrapping and gaps, each with a worked panel.

### demo_block
Block layout reference: what a box does when no rule declares `display`, why a
child's declared width is not read, and where a declared height is.

### stack_example
`Adi.Widget.Stack` paging between XML-defined pages, each with its own
stylesheet.

### list_box_example
Generic `Adi.Widget.List_Box` with selection and activation callbacks, restyled
live through `Adi.CSS_Source`.

### combo_box_example
Overlay-based combo box dropdowns with styled option rows.

### overflow_example
Compares `overflow: visible` and `overflow: hidden` clipping behavior.

### grid_example
CSS grid layout (`display: grid`) with template rows/columns, gaps, and item
spans.

### dialog_example
`Adi.Widget.Dialog`: alert, confirm, a custom dialog, and one defined in XML,
each reporting which button dismissed it.

### font_example
Font weights, italic and oblique styles, sizes, text decorations and wrapping,
with families registered through `Adi.Font`.

### runtime_css_example
`Adi.CSS_Source` in `Dynamic_Mode`: edit `examples/css/runtime_css_example.css`
while the app is open and the window restyles.

### animated_image_example
`Adi.Animated_Image` playback controls (`Start`, `Stop`, `Reset`, looping) using
`examples/assets/animhorse.gif`.

### rlottie_example
`Adi.RLottie` with eight Animated Noto Emoji in a grid, each its own animation,
drawn at a fixed 72x72 with shared transport controls.

### html_view_example
`Adi.Widget.Html_View` with HTML loaded from assets, styles provided by embedded
`<style>` and linked stylesheet resources, hyperlink callbacks, and custom image
asset loading.

### material_demo
A Material-styled application: paged navigation, combo box, context menu,
dialogs, UI scaling, and a dark/light switch that swaps the whole stylesheet at
runtime. Translated through `Adi.I18N`.

### image_example
`Adi.Widget.Image` fed by SVG paths built at runtime, laid out with every
`object-fit` and `object-position` combination.

### slider_example
The `Adi.Widget.Slider` and `Adi.Widget.Integer_Slider` generics alongside their
value inputs, with a context menu.

### value_input_example
The `Adi.Widget.Value_Input` and `Adi.Widget.Integer_Value_Input` generics:
typed numeric entry clamped to a min/max range.

### assets_example
`Adi.Assets` in `Bundle_Mode`: SVG sprite lookup by `?id=`, raster cropping by
`?x=;y=;w=;h=`, and a font loaded from the same bundle.

### gradient_example
`linear-gradient` backgrounds: angles, colour stops and explicit stop positions.

### svg_example
`Adi.SVG` rasterising a document again at every window size, rather than
scaling one raster.

### Example Assets
- `examples/assets/bg.jpg` (widget demo background)
- `examples/assets/animhorse.gif` (animated image demo)
- `examples/assets/happycat.png` (label example icon)
- `examples/assets/noto_*.json` (eight Animated Noto Emoji, rlottie demo)
- `examples/assets/html_view_example.html` (HTML view demo content)

Third-party terms, where known, are recorded in [`assets/NOTICE.md`](assets/NOTICE.md).

### Shared Widget Defaults
`css/widget_defaults.css` defines reusable baseline styles for common widgets (`.button`, `.text-input`, `.list-box`, `.list-row`) and is generated as `generated/widget_defaults_styles.ads` for reuse across examples.

## Adding New Examples

An example has to be registered in six places, or it either fails to build or
is silently skipped:

1. `examples/examples.gpr` — name in the `Example_Kind` type
2. `tools/build_examples.sh` — name in `ALL_EXAMPLES`
3. `tools/configure.sh` — name in the generated `examples_build.gpr` `Example_Kind`
4. `tools/configure.sh` — name in `EXAMPLE_KINDS`
5. `tools/generate_example_styles.sh` — `generate_if_needed` call for the CSS
6. `tools/generate_example_ui.sh` — `generate_if_needed` call for the XML, if any

Full walkthrough in [`../docs/adding_example.md`](../docs/adding_example.md).
