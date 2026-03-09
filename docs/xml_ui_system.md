# XML UI Declarative System

## Overview

The XML UI system lets you describe widget trees in XML and compile them into Ada 2022 packages. The toolchain consists of:

- **`tools/xml_to_ada.py`** — Code generator (XML → `.ads` + `.adb`)
- **`tools/widgets.xml`** — Widget grammar (tag definitions, attributes, access types)
- **`tools/generate_example_ui.sh`** — Incremental build script for example UIs

### Invocation

```bash
python3 tools/xml_to_ada.py input.xml \
  --output-dir examples/generated \
  --package-name My_UI
```

| Flag | Description |
|------|-------------|
| `input` (positional) | Input XML file |
| `--output-dir`, `-o` | Output directory (default `.`) |
| `--package-name`, `-p` | Ada package name (required) |
| `--grammar`, `-g` | Extra widget grammar XML to merge with built-in |

Produces `my_ui.ads` and `my_ui.adb` in the output directory.

---

## XML Document Structure

Every file has an `<adi>` root element. Inside it you place **declarations** and one of: a `<window>`, a `<dialog>`, or a bare root widget.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <!-- Declarations (order matters for dependencies) -->
  <link rel="stylesheet" href="styles.css"/>
  <style> .title { font-size: 24px; } </style>
  <enum name="Page" values="Home, Settings"/>
  <generic name="My_Stack" package="Adi.Widget.Stack" type-param="Page"/>
  <callback name="On_Page" type="My_Stack.Page_Changed_Callback"/>

  <!-- Window or bare widget tree -->
  <window title="My App" width="800" height="600">
    <box id="Root" class="root">
      ...
    </box>
  </window>

  <!-- Post-tree declarations -->
  <option-group generic="Nav" on-changed="On_Page">
    <option value="Home" button="Btn_Home"/>
  </option-group>
</adi>
```

### Top-Level Elements

| Element | Purpose |
|---------|---------|
| `<link>` | Reference external CSS stylesheet |
| `<style>` | Inline CSS rules (compiled to Ada constants) |
| `<enum>` | Declare an Ada enumeration type |
| `<generic>` | Instantiate a generic Ada package |
| `<callback>` | Declare a callback variable |
| `<window>` | Window container with title and size |
| `<dialog>` | Dialog container with title, message, buttons |
| `<option-group>` | Wire radio-button groups to enum callbacks |
| `<component>` | Compose a separate UI package (inside `<page>`) |

### `<window>`, `<dialog>`, and Bare Root Widget

With `<window>`, the `Build` function returns `Adi.Window.Window_Handle` and creates a window:

```xml
<window title="App" width="600" height="450">
  <box id="Root">...</box>
</window>
```

With `<dialog>`, the `Build` function returns `Adi.Widget.Dialog.Dialog_Handle`. The caller attaches it to a window:

```xml
<dialog title="Confirm" message="Are you sure?" buttons="yes-no">
  <!-- optional: 0 or 1 child widget → Set_Content -->
  <box class="custom-content">
    <label text="Extra details"/>
  </box>
</dialog>
```

| Attribute | Ada call | Accepted values | Default |
|-----------|----------|-----------------|---------|
| `title` | `Set_Title` | any string | omitted |
| `message` | `Set_Message` | any string | omitted |
| `buttons` | preset call | `ok`, `ok-cancel`, `yes-no`, `yes-no-cancel` | omitted |
| `default-button` | `Set_Default_Button` | non-negative integer (0 clears) | omitted |
| `dismiss-on-backdrop` | `Set_Dismiss_On_Backdrop` | `true`/`false` | omitted |
| `dismiss-on-escape` | `Set_Dismiss_On_Escape` | `true`/`false` | omitted |

A `<dialog>` can have 0 or 1 child widget. If present, it is passed to `Set_Content`. A dialog with no child relies on `title`/`message`/`buttons` only.

**Dialog without content:**

```xml
<adi>
  <dialog title="Alert" message="Something happened." buttons="ok"/>
</adi>
```

Generated `Build` returns `Dialog_Handle`:

```ada
function Build return Adi.Widget.Dialog.Dialog_Handle;
```

Without `<window>` or `<dialog>`, a single root widget sits directly under `<adi>` and `Build` returns `Widget_Handle`:

```xml
<adi>
  <box class="page-red">
    <label text="Red Page"/>
  </box>
</adi>
```

---

## Supported Widgets

All 18 widget tags defined in `tools/widgets.xml`:

| Tag | Package | Children | Generic | Key Attributes |
|-----|---------|----------|---------|----------------|
| `box` | `Adi.Widget.Box` | children | no | — |
| `label` | `Adi.Widget.Label` | children | no | `text`, `icon` |
| `button` | `Adi.Widget.Button` | children | no | `text`, `toggleable`, `on-clicked`, `on-toggled` |
| `switch` | `Adi.Widget.Button.Switch` | children | no | `checked`, `on-toggled` |
| `stack` | `Adi.Widget.Stack` | pages | yes | `generic`, `on-changed` |
| `text-input` | `Adi.Widget.Text_Input` | children | no | `text`, `label`, `min-visible-chars`, `disabled`, `on-changed` |
| `text-editor` | `Adi.Widget.Text_Editor` | children | no | `text`, `disabled`, `read-only`, `on-changed` |
| `combo-box` | `Adi.Widget.Combo_Box` | items | no | `on-selection-changed` |
| `animated-image` | `Adi.Widget.Animated_Image` | children | no | `looping` |
| `animated-widget` | `Adi.Widget.Animated_Widget` | children | no | `looping` |
| `rlottie` | `Adi.Widget.RLottie` | children | no | `looping` |
| `image` | `Adi.Widget.Image` | children | no | `src` |
| `html-view` | `Adi.Widget.Html_View` | children | no | — |
| `list-box` | `Adi.Widget.List_Box` | rows | yes | `generic`, `on-item-clicked`, `on-item-activated`, `on-selection-changed` |
| `slider` | `Adi.Widget.Slider` | — | yes | `generic`, `min`, `max`, `value`, `on-changed` |
| `integer-slider` | `Adi.Widget.Integer_Slider` | — | yes | `generic`, `min`, `max`, `value`, `on-changed` |
| `value-input` | `Adi.Widget.Value_Input` | — | yes | `generic`, `min`, `max`, `value`, `on-value-changed` |
| `integer-value-input` | `Adi.Widget.Integer_Value_Input` | — | yes | `generic`, `min`, `max`, `value`, `on-value-changed` |

### Children Modes

- **children** — `Add_Child` calls (default for most widgets)
- **pages** — `<page key="EnumValue">` children, wired via `Add_Page(key, widget)`
- **items** — `<item text="..."/>` children, wired via `Add_Item(text)`
- **rows** — Direct widget children, wired via `Append_Row(widget)`

---

## Attributes Reference

### Common Attributes

All widgets support:

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | string | Widget identifier. Exported in spec if explicit; auto-generated as `{Tag}_{N}` if omitted |
| `class` | string | Space-separated CSS class names (e.g. `"btn btn-primary"`). Styles are merged left-to-right |

### Per-Widget Attributes

| Attribute | Widgets | Type | Description |
|-----------|---------|------|-------------|
| `text` | label, button, text-input, text-editor | string | Text content (used in Create call) |
| `label` | text-input | string | Floating label text, positioned by `::label` part CSS (`top`, `left`, `padding`) |
| `toggleable` | button | bool | Makes the button toggleable (flag setter, no argument) |
| `checked` | switch | bool | Initial checked state (default `False`) |
| `looping` | animated-image, animated-widget, rlottie | bool | Enable animation looping (flag setter) |
| `min-visible-chars` | text-input | int | Minimum visible character width before scrolling (calls `Set_Min_Visible_Chars`) |
| `disabled` | button, switch, text-input, text-editor, combo-box, slider, integer-slider, value-input, integer-value-input | bool | Disables the widget (flag setter) |
| `read-only` | text-editor | bool | Makes the editor read-only (flag setter) |
| `icon` | label, button | image | Icon image (calls `Set_Icon` with `Adi.Assets.Get_Image`) |
| `src` | image | image | Image source (calls `Set_Image` with `Adi.Assets.Get_Image`) |
| `generic` | stack, list-box, slider, integer-slider, value-input, integer-value-input | string | Name of generic instantiation (meta; not emitted as Ada) |

### Attribute Types

- **string** — Quoted text. If `create-param="true"`, substituted into the Create call
- **bool** — `"true"` or `"false"`. If `setter-style="flag"`, the setter is called with no arguments when true. If `setter-target="base"`, the call is routed to `Adi.Widget` (base class) with a `+` handle conversion instead of the widget's own package
- **image** — Asset URL string. Emits `Adi.Assets.Get_Image ("url")` and adds `with Adi.Assets;` to the body. Supports sprite query syntax (e.g. `icons.svg?id=home`). Query parameters may use `;` as separator to avoid XML escaping (e.g. `sheet.png?x=0;y=32;w=16;h=16`); `&amp;` also works
- **int** — Integer value. Passed directly to the setter (e.g. `Set_Min_Visible_Chars (W, 30)`)
- **callback** — References a `<callback>` name. Wired with null-guard: `if Cb /= null then W.Set_On_X (Cb); end if;`

---

## Event Handlers

### Declaring Callbacks

```xml
<callback name="On_Click" type="Adi.Widget.Button.Click_Callback"/>
<callback name="On_Tab" type="My_Stack.Page_Changed_Callback"/>
```

Generates a variable in the `Instance` generic package:

```ada
On_Click : Adi.Widget.Button.Click_Callback := null;
```

### Per-Widget Callback Attributes

| Attribute | Widget(s) | Callback Type |
|-----------|-----------|---------------|
| `on-clicked` | button | Click_Callback |
| `on-toggled` | button, switch | Toggle_Callback |
| `on-changed` | stack | Page_Changed_Callback |
| `on-changed` | text-input, text-editor | Change_Callback `(W : Widget_Handle; Text : String)` |
| `on-changed` | slider, integer-slider | Change_Callback `(W : Widget_Handle; Value : Value_Type)` |
| `on-selection-changed` | combo-box, list-box | Selection_Changed_Callback |
| `on-value-changed` | value-input, integer-value-input | Value_Changed_Callback `(W : Widget_Handle; Value : Value_Type)` |
| `on-item-clicked` | list-box | Item_Clicked_Callback |
| `on-item-activated` | list-box | Item_Activated_Callback |

### Usage

```xml
<button id="Save" text="Save" on-clicked="On_Save"/>
<switch id="Dark" checked="true" on-toggled="On_Dark_Mode"/>
```

Generated wiring (in `Build`):

```ada
if On_Save /= null then
   Save.Set_On_Clicked (On_Save);
end if;
```

The caller sets the callback before or after calling `Build`:

```ada
package UI is new My_App_UI.Instance;
...
UI.On_Save := Handle_Save'Access;
W := UI.Build;
```

---

## CSS Integration

### `<link>` — External Stylesheets

```xml
<link rel="stylesheet" href="examples/css/stack_example.css"/>
<link rel="stylesheet" href="examples/css/tabs.css" styles="Custom_Tab_Styles"/>
```

| Attribute | Description |
|-----------|-------------|
| `rel` | Must be `"stylesheet"` |
| `href` | Path to CSS file (relative to working directory). Optional when `styles` is given. |
| `styles` | Optional explicit Ada styles package name. Derived from filename if omitted. Required when `href` is omitted. |

**With `href`** — dynamic link: generates a `with` for the compiled styles package, `Add_Dynamic_File` in `Build`, and precompiled static fallback entries.

**Without `href`** (styles-only link) — compile-time-only import: generates a `with` for the named styles package and uses `Set_Part_Styles` directly in `Build`. No `CSS_Source` machinery is involved. Use this when you have a precompiled Ada styles package but no runtime CSS live-reload.

```xml
<!-- styles-only: compile-time import, no dynamic CSS loading -->
<link rel="stylesheet" styles="My_Styles"/>
```

### `<style>` — Inline CSS

```xml
<style>
.title::label {
  color: white;
  font-size: 24px;
}
</style>
```

Inline CSS is:
- Compiled to Ada `Style_Rules` constants at code-generation time
- Extracted to a companion `.css` file (e.g., `red_page_ui_inline.css`) for live-reload
- Loaded via `Add_Dynamic_File` in `Build`, so edits to the companion file are detected automatically

### Dual-Mode CSS (Static Fallback + Dynamic Live Reload)

The generated `Build` function implements a dual-mode strategy:

1. Register all precompiled styles via `Set_Static_Entries`
2. Attempt to load dynamic CSS files (including companion files for inline `<style>` blocks)
3. If dynamic loading succeeds, set `Dynamic_Mode`
4. If it fails, fall back to `Static_Mode`
5. Bind every widget with a `class` attribute via `Bind_Class` (space-separated names are merged automatically)

When a `<window>` is present, `Tick_Styles_CB` is auto-wired to `Set_On_Tick` whenever the package has local live CSS or nested `<component>` instances. This ensures live reload also reaches component packages declared in separate XML files.

The generated package also exposes:
- `Tick_Styles` — Always available; ticks local CSS source (if any) and all nested component instances
- `Set_CSS_File` — Replace the dynamic CSS source at runtime; switches to `Dynamic_Mode` and enables auto-reload (only emitted when live CSS links/styles are present)

---

## Generic Widgets

Stack and ListBox are Ada generics parameterized by an enum type.

### Step 1: Declare the Enum

```xml
<enum name="Tab" values="Red, Green, Blue"/>
```

Generates: `type Tab is (Red, Green, Blue);`

### Step 2: Instantiate the Generic

```xml
<generic name="My_Stack" package="Adi.Widget.Stack" type-param="Tab"/>
```

Generates: `package My_Stack is new Adi.Widget.Stack (Tab);`

For option groups (radio-button sets):

```xml
<generic name="Tab_Options" package="Adi.Widget.Button.Options" type-param="Tab"/>
```

### Step 3: Use in Widget Tree

```xml
<stack id="Pages" generic="My_Stack" class="stack">
  <page key="Red">
    <box class="page-red">...</box>
  </page>
  <page key="Green">
    <component package="Green_Page_UI"/>
  </page>
</stack>
```

Each `<page>` must have a `key` matching an enum value and contain exactly one child (a widget or a `<component>`).

### ListBox Example

```xml
<enum name="Row_Id" values="R1, R2, R3"/>
<generic name="My_List" package="Adi.Widget.List_Box" type-param="Row_Id"/>

<list-box id="Items" generic="My_List" on-item-clicked="On_Item">
  <box class="row">...</box>
  <box class="row">...</box>
  <box class="row">...</box>
</list-box>
```

---

## Components

A `<component>` embeds a separately-generated UI package as a child widget. This enables reuse and modular composition.

### Defining a Component

Create a separate XML file with a bare root widget (no `<window>`):

```xml
<!-- red_page.xml -->
<adi>
  <link rel="stylesheet" href="examples/css/stack_example.css"/>
  <box class="page-red">
    <label text="Red Page" class="page-title"/>
  </box>
</adi>
```

Generate: `python3 xml_to_ada.py red_page.xml -o generated -p Red_Page_UI`

### Using a Component

```xml
<stack id="Pages" generic="My_Stack">
  <page key="Red">
    <component package="Red_Page_UI"/>
  </page>
</stack>
```

Generated code:

```ada
--  In spec (Instance):
package Red_Page is new Red_Page_UI.Instance;

--  In Build:
Pages.Add_Page (Red, Red_Page.Build);
```

---

## Option Groups

Option groups wire mutually-exclusive button sets to an enum callback, giving radio-button behavior.

```xml
<generic name="Tab_Options" package="Adi.Widget.Button.Options" type-param="Tab"/>
<callback name="On_Tab" type="My_Stack.Page_Changed_Callback"/>

<option-group generic="Tab_Options" on-changed="On_Tab">
  <option value="Red"   button="Btn_Red"/>
  <option value="Green" button="Btn_Green"/>
  <option value="Blue"  button="Btn_Blue"/>
</option-group>
```

| Attribute | Description |
|-----------|-------------|
| `generic` | Name of the `Button.Options` generic instantiation |
| `on-changed` | Callback variable name to invoke on selection change |
| `id` | *(optional)* When set, the `Option_Group` variable is exported in the `Instance` spec so callers can use `Set_Selected` programmatically |

Each `<option>` maps an enum `value` to a `button` by its `id`.

### Exported vs Internal Groups

By default the `Option_Group` variable is declared in the package body (internal). Adding an `id` attribute exports it to the `Instance` spec:

```xml
<!-- Internal (body-only, default) -->
<option-group generic="Tab_Options" on-changed="On_Tab">

<!-- Exported (visible in Instance spec) -->
<option-group id="Nav" generic="Tab_Options" on-changed="On_Tab">
```

Use an exported group when you need to call `Set_Selected` from outside the generated package (e.g. programmatic navigation that must also update button visuals):

```ada
--  Switches both the stack page AND the nav button selection:
UI.Tab_Options_Group.Set_Selected (Forms);
```

Generated code:

```ada
--  In Instance spec (when id is set) or package body (when id is omitted):
Tab_Options_Group : aliased Tab_Options.Option_Group;

procedure On_Tab_Option_Wrapper (Value : Tab) is
begin
   if On_Tab /= null then
      On_Tab (Value);
   end if;
end On_Tab_Option_Wrapper;

--  In Build:
Tab_Options_Group.Set_Button (Red, Btn_Red);
Tab_Options_Group.Set_Button (Green, Btn_Green);
Tab_Options_Group.Set_Button (Blue, Btn_Blue);
Tab_Options_Group.Set_On_Changed (On_Tab_Option_Wrapper'Unrestricted_Access);
```

---

## Generated Code Structure

### Spec (`.ads`)

```ada
pragma Ada_2022;
with Adi.Widget.Box;
with Adi.Widget.Stack;
with Adi.Window;
with Red_Page_UI;

package Stack_Example_UI is

   --  Enum types
   type Tab is (Red, Green, Blue);

   --  Generic instantiations (library-level)
   package My_Stack is new Adi.Widget.Stack (Tab);
   package Tab_Options is new Adi.Widget.Button.Options (Tab);

   --  Nestable generic instance
   generic
   package Instance is

      --  Callback variables (settable before Build)
      On_Tab : My_Stack.Page_Changed_Callback := null;

      --  Exported widgets (only those with explicit id="...")
      Root  : Adi.Widget.Box.Box_Handle;
      Pages : My_Stack.Stack_Handle;

      --  Component instances
      package Red_Page is new Red_Page_UI.Instance;

      --  Entry point
      function Build return Adi.Window.Window_Handle;

      --  CSS live-reload support
      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);
      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Stack_Example_UI;
```

Key points:
- Enums and generics are at package level (not inside Instance)
- Instance is a generic package so it can be instantiated multiple times
- Only widgets with explicit `id` appear in the spec
- Auto-generated IDs (e.g., `Box_1`, `Label_2`) are local to `Build`

### Body (`.adb`)

The body contains:

1. **CSS source and style constants** — `Style_Source`, precompiled `Style_Rules` constants for inline `<style>` blocks
2. **Option group variables and wrappers** — Group records and callback wrapper procedures
3. **Tick/Set_CSS_File procedures** — CSS reload support
4. **`Build` function** — Creates all widgets, registers static CSS entries, loads dynamic CSS, binds classes, builds the widget hierarchy, wires option groups, and attaches tick callback

---

## Validation

The parser rejects unsupported elements with a clear error message. Any element not listed in the grammar (`tools/widgets.xml`) or the known declaration tags (`enum`, `generic`, `callback`, `link`, `style`, `window`, `dialog`, `option-group`, `page`, `item`, `component`) causes a parse failure:

```
Error parsing XML: Unsupported element <foobar> inside <adi>
Error parsing XML: Unsupported element <unknown> inside <box>
Error parsing XML: Unsupported element <bad-tag> inside <window>
```

This applies at every level: top-level children of `<adi>`, children of `<window>`, and children of any widget element.

---

## I18N Integration

Pass `--i18n` to wrap translatable string attributes with `Adi.I18N.T()` calls:

```bash
python3 tools/xml_to_ada.py input.xml --output-dir out/ --package-name My_UI --i18n
```

| Flag | Description |
|------|-------------|
| `--i18n` | Enable translation wrapping for `translatable="true"` attributes |

Without `--i18n`, all strings are plain Ada literals (no `Adi.I18N` dependency).

### Which strings are wrapped

The widget grammar (`tools/widgets.xml`) marks certain attributes as
`translatable="true"` — user-visible text like `text` on labels/buttons and
`label` on text inputs. Non-translatable attributes (CSS classes, enum values,
image paths, numeric fields) are never wrapped.

### Context directives

| Directive | Scope | Example |
|-----------|-------|---------|
| `<i18n context="..."/>` | File-level default context | `<i18n context="home-screen"/>` |
| `{attr}-i18n-context="..."` | Per-attribute context (overrides file-level) | `text-i18n-context="menu"` |
| `i18n="false"` | Suppress wrapping for one widget | `<label text="Debug" i18n="false"/>` |

```xml
<adi>
  <i18n context="home-screen"/>
  <window title="App">
    <label text="Welcome"/>                          <!-- T("home-screen", "Welcome") -->
    <button text="Open" text-i18n-context="menu"/>   <!-- T("menu", "Open") -->
    <label text="Debug" i18n="false"/>               <!-- plain "Debug" -->
  </window>
</adi>
```

See `docs/i18n.md` for the full i18n workflow (`.po` files, registration,
plural forms, locale fallback).

---

## Limitations

- **No dynamic widget removal** — The tree is built once in `Build`; no runtime add/remove
- **No conditional rendering** — All widgets are always created
- **No nested generics** — Generic widgets cannot contain other generic widgets directly
- **No inline event handlers** — Callbacks must be declared with `<callback>` and referenced by name
- **Single root widget per `<window>`** — Exactly one child element under `<window>`
- **Single content widget per `<dialog>`** — At most one child element under `<dialog>`
- **Page children** — Each `<page>` must contain exactly one widget or one `<component>`
