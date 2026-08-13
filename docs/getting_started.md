# Getting started

Build a small Adi2 application: a window with a button and a label that
counts presses. First with XML and CSS, then the same program written
directly in Ada.

You need Alire 2.x with a GNAT toolchain, SDL3 with SDL3_ttf and
SDL3_image installed, and Python 3 for the code generators.

## 1. Create the project

```bash
alr init --bin myapp
cd myapp
alr with adi2
```

Adi2's specs use Ada 2022 constructs and GNAT defaults to Ada 2012, so
every unit needs `pragma Ada_2022;` — the listings below have it. To set it
project-wide instead, add the switch in `myapp.gpr`:

```ada
   package Compiler is
      for Default_Switches ("Ada") use
        Myapp_Config.Ada_Compiler_Switches & ("-gnat2022");
   end Compiler;
```

Nothing else is needed. Adi2 is built with `-gnatX0` internally; you do not
inherit that.

## 2. Write the stylesheet

`css/main.css`. This is ordinary CSS; see [`css_styling.md`](css_styling.md)
for the supported properties and selectors.

```css
.root {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background-color: rgb(247, 248, 250);
}

button {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  padding: 10px 16px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.25);
  transition: box-shadow 150ms ease-out;
}

button:hover {
  box-shadow: 0 2px 10px rgba(22, 163, 74, 0.85);
}

.primary { background-color: rgb(37, 99, 235); }

.primary::label {
  color: rgb(255, 255, 255);
  font-weight: 600;
}

#Readout::label {
  color: rgb(40, 44, 52);
  font-size: 16px;
}
```

Three kinds of selector appear here, and they behave as on the web:

- `button` matches by element — every `<button>` in the interface.
- `.primary` matches by class — whatever carries `class="primary"`.
- `#Readout` matches by id — the single widget whose XML element has
  `id="Readout"`.

They merge in that order, so a class overrides the element rule and an id
overrides both. `::label` addresses a *part* of a widget rather than the
widget itself, and `:hover` a state; both are covered in
[`css_styling.md`](css_styling.md).

## 3. Describe the interface

`ui/main.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="css/main.css"/>

  <callback name="On_Press" type="Adi.Widget.Button.Click_Callback"/>

  <window title="My App" width="360px" height="200px">
    <box class="root">
      <button id="Press" text="Press me" class="primary" on-clicked="On_Press"/>
      <label id="Readout" text="clicked 0"/>
    </box>
  </window>
</adi>
```

`id` makes a widget reachable from Ada, and is also what `#Readout` in the
stylesheet selects. `<callback>` declares a hook you
assign before building. The available tags come from Adi2's widget grammar;
[`xml_ui_system.md`](xml_ui_system.md) documents the grammar, components,
and how to add tags for your own widgets.

## 4. Generate the Ada

`ADI2_TOOLS` points at the generators inside the crate. `alr exec` sets it
for the command it runs, so the expansion has to happen there rather than in
your own shell — hence `sh -c`:

```bash
mkdir -p src/generated
alr exec -- sh -c 'python3 "$ADI2_TOOLS/css_to_ada.py" \
  css/main.css src/generated/main_styles.ads --package-name=Main_Styles'
alr exec -- sh -c 'python3 "$ADI2_TOOLS/xml_to_ada.py" \
  ui/main.xml --output-dir src/generated --package-name Main_UI'
```

Four files land in `src/generated/`: each generator writes a spec and a
body. `main_styles.adb` holds the procedure that installs the stylesheet's
selectors, so both halves have to be on the source path.

Add the directory to `myapp.gpr`:

```ada
   for Source_Dirs use ("src/", "src/generated/", "config/");
```

Both must be rerun whenever the `.css` or `.xml` changes. To let `alr build`
do it, add two pre-build actions to your own `alire.toml` — the one in
`myapp/`, not Adi2's:

```toml
[[actions]]
type = "pre-build"
command = ["sh", "-c", "python3 \"$ADI2_TOOLS/css_to_ada.py\" css/main.css src/generated/main_styles.ads --package-name=Main_Styles"]

[[actions]]
type = "pre-build"
command = ["sh", "-c", "python3 \"$ADI2_TOOLS/xml_to_ada.py\" ui/main.xml --output-dir src/generated --package-name Main_UI"]
```

Actions run from the crate root with the Alire environment set, so
`$ADI2_TOOLS` resolves there as it does under `alr exec`. They run on every
build, and the generators overwrite their output unconditionally, so the
generated sources cannot go stale. Note that a failing action only warns;
the build then fails later when the missing source does not compile.

## 5. Write the program

`src/myapp.adb`:

```ada
pragma Ada_2022;

with Adi.App;
with Adi.Core;   use Adi.Core;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Label;
with Adi.Window; use Adi.Window;

with Main_UI;

procedure Myapp is
   A : Adi.App.App;

   package UI is new Main_UI.Instance;

   Clicks : Natural := 0;

   procedure Handle_Press (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      Clicks := Clicks + 1;
      Adi.Widget.Label.Set_Text
        (UI.Readout, "clicked" & Natural'Image (Clicks));
   end Handle_Press;

begin
   A.Init;

   UI.On_Press := Handle_Press'Unrestricted_Access;

   declare
      W : constant Window_Handle := UI.Build;
   begin
      A.Add_Window (W);
      A.Run;
   end;
end Myapp;
```

```bash
alr build && ./bin/myapp
```

Three things about that callback.

**It uses `'Unrestricted_Access`, not `'Access`.** `Click_Callback` is a
named access-to-subprogram type declared at library level in
`Adi.Widget.Button`. `Handle_Press` is one accessibility level deeper, and
Ada rejects `'Access` there because it cannot prove the subprogram outlives
calls made through a library-level access value. `'Unrestricted_Access`
asserts you have checked that yourself. Here it holds: `Handle_Press` lives
as long as `Myapp`, which outlives the window. To avoid the assertion,
declare the callback in a package, where it is already at library level.

**Do not name it `On_Click`.** `Adi.Widget` exports that name, and under
`use Adi.Widget` a local procedure of the same name is ambiguous. GNAT
reports it as a missing argument in a call to your own procedure.

**The parameter is `Widget_Handle`**, not the button's typed handle:
`Click_Callback` is `access procedure (W : Widget_Handle)`.

## CSS without XML

The two generators are independent. You can keep the stylesheet and build
the widget tree in Ada, which suits a UI that is assembled at runtime while
its appearance stays in CSS.

`css_to_ada.py` turns each selector into a `Part_Style_Array` named after
it, hover variant and transition included: `.primary` becomes
`Primary_Class_Part_Styles`, `button` becomes `Button_Tag_Part_Styles`, and
`#Readout` becomes `Readout_Id_Part_Styles`. Apply them with
`Set_Part_Styles`. Only the CSS generator needs to run:

```bash
alr exec -- sh -c 'python3 "$ADI2_TOOLS/css_to_ada.py" \
  css/main.css src/generated/main_styles.ads --package-name=Main_Styles'
```

`src/myapp_css.adb`:

```ada
pragma Ada_2022;

with Adi.App;
with Adi.Core;       use Adi.Core;
with Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget;     use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Window;     use Adi.Window;

with Main_Styles; use Main_Styles;

procedure Myapp_Css is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Label.Label_Handle;

   Clicks  : Natural := 0;
   Readout : Adi.Widget.Label.Label_Handle;

   procedure Handle_Press (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      Clicks := Clicks + 1;
      Adi.Widget.Label.Set_Text
        (Readout, "clicked" & Natural'Image (Clicks));
   end Handle_Press;

begin
   A.Init;

   declare
      W : constant Window_Handle :=
        Create_Window_Handle
          ("My App", Adi.Window.Extent (Px (360.0), Px (200.0)));
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Press : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Press me");
   begin
      Readout := Adi.Widget.Label.Create_Handle ("clicked 0");

      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Press,
         Adi.CSS_Source.Merge_Part_Styles
           (Button_Tag_Part_Styles, Primary_Class_Part_Styles));
      Adi.Widget.Label.Set_Part_Styles (Readout, Readout_Id_Part_Styles);

      Adi.Widget.Button.Connect_Clicked
        (Press, Handle_Press'Unrestricted_Access);

      Add_Child (+Root, +Press);
      Add_Child (+Root, +Readout);

      Set_Root (W, +Root);
      A.Add_Window (W);
      A.Run;
   end;
end Myapp_Css;
```

Nothing here knows that `Press` is a `.primary` or a `button`; you name the
selectors yourself and merge them in CSS order, tag before class before id.
`Merge_Part_Styles` comes from `Adi.CSS_Source`.

### Adding live reload

As written, the styles are compiled in. To get the same edit-and-see
behaviour the XML path has, drive `Adi.CSS_Source` yourself: load the
stylesheet, bind each class to its widget, and tick the source once a
frame.

Add to the declarations:

```ada
   Styles : aliased Adi.CSS_Source.Style_Source;

   procedure Tick_Styles (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, OK : Boolean;
   begin
      Adi.CSS_Source.Tick (Styles, Reloaded, OK);
   end Tick_Styles;
```

and, after the widgets exist but before `A.Run`:

```ada
      declare
         Loaded, OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File (Styles, "css/main.css", Loaded);
         if Loaded then
            Adi.CSS_Source.Set_Mode (Styles, Adi.CSS_Source.Dynamic_Mode, OK);
            Adi.CSS_Source.Set_Auto_Reload (Styles, True);
         end if;
      end;

      Adi.CSS_Source.Attach_Window (Styles, W);
      Adi.CSS_Source.Bind_Root_Metadata (Styles, +Root);
      Adi.CSS_Source.Bind_Class (Styles, "root", +Root);
      Adi.CSS_Source.Bind_Selector_Set
        (Styles, +Press, Tag_Name => "button", Class_Name => "primary");
      Adi.CSS_Source.Bind_Selector_Set
        (Styles, +Readout, Id_Name => "Readout");
      Adi.Window.Connect_Tick (W, Tick_Styles'Unrestricted_Access);
```

Run it, edit a colour in `css/main.css`, save, and the window restyles
without a rebuild.

`Add_Dynamic_File` reports whether the file was found, so a missing
stylesheet leaves the compiled-in rules in place rather than an unstyled
window — which is what makes the same binary work when shipped without the
`.css` beside it. The `Bind_*` calls replace the `Set_Part_Styles` ones
above: binding keeps the association, so each reload restyles the widget
again. `Bind_Selector_Set` merges the kinds it is given in CSS order, and
`Bind_Class` is shorthand for the class-only case.

This is the wiring the XML generator emits for you; the full API is in
[`css_styling.md`](css_styling.md).

## The same program without any generator

Style rules can also be written directly, with no Python step at all. Save
this as `src/myapp_raw.adb`, list your mains in `myapp.gpr` with
`for Main use ("myapp.adb", "myapp_css.adb", "myapp_raw.adb");`, then run
`./bin/myapp_raw`.

```ada
pragma Ada_2022;

with Adi.App;
with Adi.Core;          use Adi.Core;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.Window;        use Adi.Window;

procedure Myapp_Raw is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Label.Label_Handle;

   Clicks  : Natural := 0;
   Readout : Adi.Widget.Label.Label_Handle;

   procedure Handle_Press (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      Clicks := Clicks + 1;
      Adi.Widget.Label.Set_Text
        (Readout, "clicked" & Natural'Image (Clicks));
   end Handle_Press;

begin
   A.Init;

   declare
      W : constant Window_Handle :=
        Create_Window_Handle
          ("My App", Adi.Window.Extent (Px (360.0), Px (200.0)));
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Press : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Press me");
   begin
      Readout := Adi.Widget.Label.Create_Handle ("clicked 0");

      Adi.Widget.Box.Set_Part_Styles
        (Root,
         [Main_Part =>
            (Style => From ((Display          => Set (Flex),
                             Flex_Direction   => Set (Column),
                             Gap              => Set (Gap (Px (12.0))),
                             Padding          => Set (CSS_Box (Px (16.0))),
                             Background_Color => Set_Bg (RGB (24, 26, 33)),
                             others           => <>)).Build,
             Enabled => True),
          others => <>]);

      Adi.Widget.Button.Set_Part_Styles
        (Press,
         [Main_Part =>
            (Style =>
               With_Transition
                 (On (From ((Display          => Set (Inline_Flex),
                             Justify_Content  => Set (Center),
                             Align_Items      => Set (Center),
                             Padding          => Set (CSS_Box (Px (10.0),
                                                               Px (16.0))),
                             Border_Radius    => Set (Radius (Px (8.0))),
                             Background_Color => Set_Bg (RGB (37, 99, 235)),
                             others           => <>)),
                     Sel_Hovered,
                     (Background_Color => Set_Bg (RGB (29, 78, 216)),
                      others           => <>)),
                  Duration => 0.15,
                  Easing   => Ease_Out).Build,
             Enabled => True),
          Label_Part =>
            (Style => From ((Color       => Set (RGB (255, 255, 255)),
                             Font_Weight => Set (Weight_Semi_Bold),
                             others      => <>)).Build,
             Enabled => True),
          others => <>]);

      Adi.Widget.Label.Set_Part_Styles
        (Readout,
         [Label_Part =>
            (Style => From ((Color     => Set (RGB (220, 225, 240)),
                             Font_Size => Set_Font (Px (16.0)),
                             others    => <>)).Build,
             Enabled => True),
          others => <>]);

      Adi.Widget.Button.Connect_Clicked
        (Press, Handle_Press'Unrestricted_Access);

      Add_Child (+Root, +Press);
      Add_Child (+Root, +Readout);

      Set_Root (W, +Root);
      A.Add_Window (W);
      A.Run;
   end;
end Myapp_Raw;
```

All three programs are equivalent, hover included. The builder maps onto the
CSS directly: `From` is the resting rule, `On (…, Sel_Hovered, …)` is
`:hover`, `With_Transition` is `transition`. Two names are easy to guess
wrong — a window's root is set with `Set_Root`, and a button's click signal
is `Connect_Clicked`.

Hand-written rules produce the same `Style_Rules` values the CSS generator
emits, so the two mix: generate a stylesheet and override individual rules
in Ada.

`hello_example` and `hello_raw_example` in this repository are the same
pairing, slightly larger.

## Styles at runtime

By default the generated `Build` looks for the stylesheet at the path from
the XML — here `css/main.css`, relative to the working directory. If it
finds the file, styling switches to `Dynamic_Mode` with auto-reload and
editing the CSS restyles the running window. If not, the rules compiled
into `Main_Styles` are used.

Convenient in development, but it means a `css/main.css` sitting beside a
shipped binary gets picked up. To compile the styles in and drop the
runtime probe:

```bash
alr exec -- sh -c 'python3 "$ADI2_TOOLS/xml_to_ada.py" \
  ui/main.xml --output-dir src/generated --package-name Main_UI --no-live-css'
```

[`css_styling.md`](css_styling.md) covers both modes and the API behind
them.

## Looking inside the running window

While developing it is useful to ask the program what it is actually
showing, rather than inferring it from a screenshot. Add two calls around
`A.Run`:

```ada
with Adi.MCP;
...
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
```

That opens a small file-based channel under `/tmp/adi_mcp/<pid>/`. The
server in `$ADI2_TOOLS/adi_mcp_server.py` speaks it, and can be pointed at
by any MCP client:

```bash
uv run "$ADI2_TOOLS/adi_mcp_server.py" --dir /tmp/adi_mcp
```

It answers questions about the live window: `widget_tree` for the hierarchy
with each widget's bounds and states, `widget_info` for one of them,
`css_values` for the style a widget actually resolved to, `find_by_text` to
locate one, and `screenshot`, `click_widget` and `scroll` to drive it.

`css_values` shows the final value resolved for each property. It confirms
whether the widget ended up with the expected style; it does not report
selector provenance, so an unexpected value still requires checking
selector binding and cascade order.

Release builds link a stub, so these calls cost nothing there and can be
left in. [`mcp.md`](mcp.md) has the details.

## Lifecycle and ownership

`A.Init` starts SDL and the font stack. `A.Add_Window` hands the window to
the application. `A.Run` drives the event loop until the last window
closes, and destroys that window before returning — which is why neither
program cleans up after itself.

If your program can end without reaching `Run`, destroy the window with
`Adi.Window.Destroy`. Leaving the declarative region will not do it: a
`Window_Handle` is a plain record, not a controlled object.

`Widget_Handle` is a generational id, not a pointer or a reference count.
Copying one does not keep a widget alive. The window owns its tree, so
destroying the window destroys those widgets and handles to them go stale —
stale rather than dangling, so operations on them fail cleanly. Use
`Adi.Widget.Borrow` when you need a real pointer for the length of a scope.
[`handle_ownership.md`](handle_ownership.md) has the rules.

One hazard worth knowing before the program grows: a `Window` declared in a
package that also declares widget types can be finalized in an order that
breaks cleanup. See [`finalization_ordering.md`](finalization_ordering.md).

## Next

- [`css_styling.md`](css_styling.md) — properties, selectors, parts, runtime API
- [`xml_ui_system.md`](xml_ui_system.md) — widget grammar, components, custom tags
- [`architecture.md`](architecture.md) — how layout, styling and rendering fit together
- [`static_assets.md`](static_assets.md) — bundling fonts and images into the binary
- [`mcp.md`](mcp.md) — driving a running application from an editor or a test
- [`gallery.md`](gallery.md) — every example, with screenshots
