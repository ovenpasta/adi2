# Adi Demos

This Alire crate builds 27 demos against the local Adi library, pinned to `..`.
Install Alire, a GNAT toolchain with Ada 2022 support, Bash and Python 3. Alire
resolves the SDL dependencies declared by Adi; see [build requirements](../docs/build.md).

## Build and run

From the repository root:

```bash
cd demos
alr build -- -j0
alr run hello_example
alr run material_demo
```

`alr build` compiles all mains in `demos.gpr` into `bin/`. Its pre-build action
regenerates CSS, XML, asset bundles and translations when their inputs change.
Running `alr build` at the repository root builds only the library.

To build just one demo, pass its Ada filename to gprbuild through Alire:

```bash
alr build -- -j0 label_example.adb
alr run --skip-build label_example
```

For MCP introspection and library logging, build Adi in development mode too:

```bash
alr build --profiles=adi2=development -- -j0
```

From the repository root, `tools/build_demos.sh [name ...]` provides the same
Alire build with the library in development mode. With no names, it builds all demos.
Do not run builds concurrently: the demos share library and object files.

Executables can also be launched directly as `./bin/label_example` from this
directory or `./demos/bin/label_example` from the repository root. Each demo
initializes its working directory to resolve `demos/assets/` and `demos/css/`,
including live stylesheet reloads. Keep these resource directories in the checkout.

## XML or Ada

Some demos declare their widget tree in `xml/`; others build it in `src/`.
XML describes static layout. Ada handles callbacks, generic instantiations,
runtime content and resource ownership. Generated Ada sources live in `generated/`.

## Available demos

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
Block layout reference: what a box does when no rule declares `display`, how a
child's declared width and height are read, and what a percentage resolves
against.

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
`Adi.CSS_Source` in `Dynamic_Mode`: edit `demos/css/runtime_css_example.css`
while the app is open and the window restyles.

### animated_image_example
`Adi.Animated_Image` playback controls (`Start`, `Stop`, `Reset`, looping) using
`demos/assets/animhorse.gif`.

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

## Assets and shared styles

`assets/` contains images, SVGs, fonts, HTML and the Animated Noto Emoji used by
the demos. Third-party terms are recorded in [assets/NOTICE.md](assets/NOTICE.md).
`css/widget_defaults.css` provides shared baseline styles, generated as
`generated/widget_defaults_styles.ads`.

## Add a demo

1. Create `src/<name>.adb` and call `Demo_Paths.Initialize` before loading resources.
2. Add `"<name>.adb"` to `Main` in `demos.gpr` and `"<name>"` to `executables` in `alire.toml`.
3. Register CSS/XML inputs in `../tools/generate_demo_styles.sh` and
   `../tools/generate_demo_ui.sh`, as applicable. Bundles and translations have
   corresponding `generate_demo_*` scripts.
4. If supporting the standalone configure build, add the name to both demo lists
   in `../tools/configure.sh`.
5. Run `alr build -- -j0 <name>.adb`, then `alr run --skip-build <name>`.

See [the full walkthrough](../docs/adding_example.md).
