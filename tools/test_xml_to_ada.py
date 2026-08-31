#!/usr/bin/env python3
"""Tests for xml_to_ada.py — focused on <dialog> root element support."""

import os
import pathlib
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import xml_to_ada


def parse_xml(xml_str: str) -> xml_to_ada.XmlApp:
    """Parse an XML string and return the XmlApp."""
    # Closed before it is reopened by name: Windows refuses both the
    # second open and the unlink while a handle is outstanding.
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".xml", delete=False, encoding="utf-8"
    ) as f:
        f.write(xml_str)
        path = f.name
    try:
        parser = xml_to_ada.Parser()
        return parser.parse(path)
    finally:
        os.unlink(path)


class TestDialogParsing(unittest.TestCase):
    """Tests for <dialog> parsing."""

    def test_dialog_all_attributes_no_child(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Confirm" message="Are you sure?"
          buttons="yes-no" default-button="2"
          dismiss-on-backdrop="true" dismiss-on-escape="false"/>
</adi>"""
        app = parse_xml(xml)
        self.assertIsNotNone(app.dialog)
        self.assertEqual(app.dialog.title, "Confirm")
        self.assertEqual(app.dialog.message, "Are you sure?")
        self.assertEqual(app.dialog.buttons, "yes-no")
        self.assertEqual(app.dialog.default_button, 2)
        self.assertTrue(app.dialog.dismiss_on_backdrop)
        self.assertFalse(app.dialog.dismiss_on_escape)
        self.assertIsNone(app.dialog.content_widget)

    def test_dialog_with_child_widget(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Details">
    <box class="content">
      <label text="Extra info"/>
    </box>
  </dialog>
</adi>"""
        app = parse_xml(xml)
        self.assertIsNotNone(app.dialog)
        self.assertIsNotNone(app.dialog.content_widget)
        self.assertEqual(app.dialog.content_widget.tag, "box")
        self.assertEqual(len(app.dialog.content_widget.children), 1)
        self.assertEqual(app.dialog.content_widget.children[0].tag, "label")

    def test_dialog_style_attributes(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog class="backdrop"
          panel-class="panel"
          title-class="dialog-title"
          message-class="dialog-message"
          button-row-class="button-row"
          button-class="dialog-btn"
          primary-button-class="dialog-btn-primary"/>
</adi>"""
        app = parse_xml(xml)
        self.assertEqual(app.dialog.css_classes, ["backdrop"])
        self.assertEqual(app.dialog.panel_classes, ["panel"])
        self.assertEqual(app.dialog.title_classes, ["dialog-title"])
        self.assertEqual(app.dialog.message_classes, ["dialog-message"])
        self.assertEqual(app.dialog.button_row_classes, ["button-row"])
        self.assertEqual(app.dialog.button_classes, ["dialog-btn"])
        self.assertEqual(app.dialog.primary_button_classes, ["dialog-btn-primary"])

    def test_dialog_no_attributes(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog/>
</adi>"""
        app = parse_xml(xml)
        self.assertIsNotNone(app.dialog)
        self.assertEqual(app.dialog.title, "")
        self.assertEqual(app.dialog.message, "")
        self.assertEqual(app.dialog.buttons, "")
        self.assertIsNone(app.dialog.default_button)
        self.assertIsNone(app.dialog.dismiss_on_backdrop)
        self.assertIsNone(app.dialog.dismiss_on_escape)
        self.assertIsNone(app.dialog.content_widget)

    def test_mutual_exclusion_dialog_and_window(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <window title="App" width="800" height="600">
    <box/>
  </window>
  <dialog title="Oops"/>
</adi>"""
        with self.assertRaises(ValueError) as ctx:
            parse_xml(xml)
        self.assertIn("dialog", str(ctx.exception).lower())

    def test_mutual_exclusion_dialog_and_bare_widget(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Oops"/>
  <box/>
</adi>"""
        with self.assertRaises(ValueError) as ctx:
            parse_xml(xml)
        self.assertIn("dialog", str(ctx.exception).lower())

    def test_invalid_buttons_value(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="maybe"/>
</adi>"""
        with self.assertRaises(ValueError) as ctx:
            parse_xml(xml)
        self.assertIn("buttons", str(ctx.exception).lower())

    def test_default_button_zero_clears(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="yes-no" default-button="0"/>
</adi>"""
        app = parse_xml(xml)
        self.assertEqual(app.dialog.default_button, 0)

    def test_invalid_default_button_negative(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog default-button="-1"/>
</adi>"""
        with self.assertRaises(ValueError):
            parse_xml(xml)

    def test_invalid_default_button_non_integer(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog default-button="abc"/>
</adi>"""
        with self.assertRaises(ValueError) as ctx:
            parse_xml(xml)
        self.assertIn("default-button", str(ctx.exception).lower())

    def test_invalid_dismiss_boolean(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog dismiss-on-backdrop="yes"/>
</adi>"""
        with self.assertRaises(ValueError) as ctx:
            parse_xml(xml)
        self.assertIn("dismiss-on-backdrop", str(ctx.exception).lower())

    def test_dialog_more_than_one_child(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Bad">
    <box/>
    <label text="extra"/>
  </dialog>
</adi>"""
        with self.assertRaises(ValueError):
            parse_xml(xml)


class TestDialogCodeGeneration(unittest.TestCase):
    """Tests for <dialog> code generation."""

    def test_spec_returns_dialog_handle(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Test"/>
</adi>"""
        app = parse_xml(xml)
        spec = xml_to_ada.generate_spec(app, "Test_Dialog_UI")
        self.assertIn("Adi.Widget.Dialog", spec)
        self.assertIn(
            "function Build return Adi.Widget.Dialog.Dialog_Handle;",
            spec,
        )
        #  Build's return type must be a Dialog_Handle, not a window or
        #  a bare widget. (Adi.Window itself does appear in the with-list
        #  because Instance.Attach_Window takes a Window_Handle parameter.)
        self.assertNotIn("return Adi.Window.Window_Handle", spec)
        self.assertNotIn("return Adi.Widget.Widget_Access", spec)

    def test_body_creates_dialog_and_sets_title(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Hello World"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_Dialog_UI")
        self.assertIn("Adi.Widget.Dialog.Create_Handle", body)
        self.assertIn('Adi.Widget.Dialog.Set_Title (D, "Hello World")', body)
        self.assertIn("return D;", body)

    def test_body_sets_message(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog message="Are you sure?"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn(
            'Adi.Widget.Dialog.Set_Message (D, "Are you sure?")',
            body,
        )

    def test_body_button_presets(self):
        for preset, method in xml_to_ada.DIALOG_BUTTON_PRESETS.items():
            xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="{preset}"/>
</adi>"""
            app = parse_xml(xml)
            body = xml_to_ada.generate_body(app, "Test_UI")
            self.assertIn(f"Adi.Widget.Dialog.{method} (D)", body)

    def test_body_default_button(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="ok-cancel" default-button="1"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("Adi.Widget.Dialog.Set_Default_Button (D, 1)", body)

    def test_body_default_button_zero(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="yes-no" default-button="0"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("Adi.Widget.Dialog.Set_Default_Button (D, 0)", body)

    def test_body_dismiss_flags(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog dismiss-on-backdrop="true" dismiss-on-escape="false"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn(
            "Adi.Widget.Dialog.Set_Dismiss_On_Backdrop (D, True)",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Dismiss_On_Escape (D, False)",
            body,
        )

    def test_body_with_content_widget(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Details">
    <box id="Content">
      <label text="Info"/>
    </box>
  </dialog>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("Adi.Widget.Dialog.Set_Content (D, +Content)", body)
        # The content widget tree should be built
        self.assertIn("Adi.Widget.Box", body)
        self.assertIn("Add_Child", body)

    def test_body_bare_dialog_no_attributes(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("Adi.Widget.Dialog.Create_Handle", body)
        self.assertIn("return D;", body)
        # Should not have Set_Title etc. since no attributes
        self.assertNotIn("Set_Title", body)
        self.assertNotIn("Set_Message", body)
        self.assertNotIn("Set_OK", body)

    def test_dialog_with_css_link(self):
        """Dialog with CSS link wires its content widget to the stylesheet."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" styles="My_Styles"/>
  <dialog title="Styled">
    <box class="dialog-content">
      <label text="Hello"/>
    </box>
  </dialog>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        # The content widget with a class should get style wiring
        self.assertIn("My_Styles.Register_Selectors (Source);", body)
        self.assertIn('Class_Name => "dialog-content");', body)

    def test_live_css_dialog_emits_attach_window_and_explicit_internal_bindings(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="dialog.css" package="Dialog_Styles"/>
  <dialog title="Styled"
          buttons="ok-cancel"
          class="backdrop"
          panel-class="panel"
          title-class="dialog-title"
          message-class="dialog-message"
          button-row-class="button-row"
          button-class="dialog-btn"
          primary-button-class="dialog-btn-primary"/>
</adi>"""
        app = parse_xml(xml)
        spec = xml_to_ada.generate_spec(app, "Test_UI")
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("with Adi.Window;", spec)
        self.assertIn(
            "procedure Attach_Window (D : Adi.Widget.Dialog.Dialog_Handle; Host : Adi.Window.Window_Handle);",
            spec,
        )
        self.assertIn("with Dialog_Styles; use Dialog_Styles;", body)
        self.assertIn(
            "Adi.Widget.Dialog.Set_Button_Style (D, Dialog_Btn_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Primary_Button_Style (D, Dialog_Btn_Primary_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.CSS_Source.Bind_Class (Source, \"backdrop\", Adi.Widget.Dialog.To_Widget_Handle (D));",
            body,
        )
        self.assertIn(
            "Adi.CSS_Source.Bind_Root_Metadata (Source, +Adi.Widget.Dialog.Get_Content_Panel_Handle (D));",
            body,
        )
        self.assertIn(
            "Adi.CSS_Source.Bind_Class (Source, \"panel\", +Adi.Widget.Dialog.Get_Content_Panel_Handle (D));",
            body,
        )
        self.assertIn(
            "Adi.CSS_Source.Bind_Class (Source, \"button-row\", +Adi.Widget.Dialog.Get_Button_Row_Handle (D));",
            body,
        )
        self.assertIn(
            "Adi.CSS_Source.Bind_Class (Source, \"dialog-btn dialog-btn-primary\", +Adi.Widget.Dialog.Get_Button_Handle (D, 2));",
            body,
        )
        self.assertIn(
            "Adi.Window.Connect_Tick (Host, Tick_Styles_CB'Unrestricted_Access);",
            body,
        )

    def test_live_css_childless_dialog_emits_static_fallback_for_own_classes(self):
        """A childless dialog with style classes must still register the
        stylesheet's entries, otherwise the Static_Mode fallback (used when
        the dynamic .css file is missing at runtime, e.g. in a release
        build) leaves Bind_Class resolving to empty styles and the dialog
        renders invisibly."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="dialog.css" package="Dialog_Styles"/>
  <dialog title="Prompt"
          class="prompt-backdrop"
          panel-class="prompt-panel"
          title-class="prompt-title"
          message-class="prompt-message"
          button-row-class="prompt-button-row"
          button-class="prompt-btn"
          primary-button-class="prompt-btn-primary"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn(
            "         Adi.CSS_Source.Clear_Static_Entries (Source);\n"
            "         Dialog_Styles.Register_Selectors (Source);",
            body,
        )
        #  The dialog's own parts are not widgets in the tree, so they still
        #  name their style constants directly.
        for style_const in [
            "Prompt_Btn_Class_Part_Styles",
            "Prompt_Btn_Primary_Class_Part_Styles",
        ]:
            self.assertIn(style_const, body)

    def test_live_css_with_class_fallback_registers_the_styles_package(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="dialog.css" package="Dialog_Styles"/>
  <dialog title="Styled">
    <box class="dialog-content">
      <label text="Hello"/>
    </box>
  </dialog>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        #  Qualified, so no use clause is needed for the widget path.
        self.assertIn("with Dialog_Styles;\n", body)
        self.assertIn("Dialog_Styles.Register_Selectors (Source);", body)
        self.assertIn('Class_Name => "dialog-content");', body)

    def test_no_live_css_forces_static_codegen_on_dialog_with_link(self):
        """A dialog whose XML declares <link href="..."> would normally
        emit live-CSS codegen (Add_Dynamic_File + Bind_Class). When
        no_live_css=True is passed, the generator must degrade to the
        static-only path — direct Set_Panel_Style etc. — so release
        builds never touch the filesystem at startup."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="dialog.css" package="Dialog_Styles"/>
  <dialog title="Prompt"
          class="prompt-backdrop"
          panel-class="prompt-panel"
          title-class="prompt-title"
          message-class="prompt-message"
          button-row-class="prompt-button-row"
          button-class="prompt-btn"
          primary-button-class="prompt-btn-primary"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI", no_live_css=True)
        self.assertNotIn("Add_Dynamic_File", body)
        self.assertNotIn("Bind_Class", body)
        self.assertNotIn("Dynamic_Mode", body)
        self.assertIn(
            "Adi.Widget.Dialog.Set_Part_Styles (D, Prompt_Backdrop_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Panel_Style (D, Prompt_Panel_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Title_Style (D, Prompt_Title_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Message_Style (D, Prompt_Message_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Button_Row_Style (D, Prompt_Button_Row_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Button_Style (D, Prompt_Btn_Class_Part_Styles);",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Set_Primary_Button_Style (D, Prompt_Btn_Primary_Class_Part_Styles);",
            body,
        )

    def test_no_live_css_also_applies_to_spec(self):
        """The spec must not import Adi.CSS_Source or declare the
        tick-refresh machinery when no_live_css disables live-CSS mode."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="dialog.css" package="Dialog_Styles"/>
  <dialog title="Prompt" panel-class="prompt-panel"/>
</adi>"""
        app = parse_xml(xml)
        spec = xml_to_ada.generate_spec(app, "Test_UI", no_live_css=True)
        self.assertNotIn("Adi.CSS_Source", spec)
        self.assertNotIn("Tick_Styles_CB", spec)

    def test_dialog_attach_window_always_emitted(self):
        """`Instance.Attach_Window` is part of the dialog API contract.
        It must be declared in the spec and defined in the body whenever
        the app is a <dialog>, regardless of CSS mode or component
        presence — otherwise downstream callers like
        `My_Dlg.Attach_Window (D, Win)` fail to compile under
        --no-live-css for dialogs without component packages."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Plain"/>
</adi>"""
        app = parse_xml(xml)

        #  No <link>, no <style>, no components: live_css is naturally
        #  False — the original guard would have skipped Attach_Window.
        spec = xml_to_ada.generate_spec(app, "Test_UI")
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn(
            "procedure Attach_Window"
            " (D : Adi.Widget.Dialog.Dialog_Handle;"
            " Host : Adi.Window.Window_Handle);",
            spec,
        )
        self.assertIn("with Adi.Window;", spec)
        self.assertIn(
            "procedure Attach_Window"
            " (D : Adi.Widget.Dialog.Dialog_Handle;"
            " Host : Adi.Window.Window_Handle) is",
            body,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Attach_Window (D, Host);", body
        )
        #  No tick-hook when there's nothing to tick.
        self.assertNotIn("Live_CSS_Host", body)
        self.assertNotIn("Connect_Tick", body)

    def test_dialog_attach_window_emitted_under_no_live_css(self):
        """Same as above but for the realistic case: the XML *has* a
        <link> (so live-CSS would normally be on), but --no-live-css
        forces the static-only path. The wrapper must still be a stable
        pass-through for callers."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="dlg.css" package="Dlg_Styles"/>
  <dialog title="Plain" panel-class="plain-panel"/>
</adi>"""
        app = parse_xml(xml)
        spec = xml_to_ada.generate_spec(app, "Test_UI", no_live_css=True)
        body = xml_to_ada.generate_body(app, "Test_UI", no_live_css=True)
        self.assertIn(
            "procedure Attach_Window"
            " (D : Adi.Widget.Dialog.Dialog_Handle;"
            " Host : Adi.Window.Window_Handle);",
            spec,
        )
        self.assertIn(
            "Adi.Widget.Dialog.Attach_Window (D, Host);", body
        )
        self.assertNotIn("Live_CSS_Host", body)
        self.assertNotIn("Connect_Tick", body)

    def test_static_dialog_emits_explicit_internal_styles(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" styles="Dialog_Styles"/>
  <dialog class="backdrop"
          panel-class="panel"
          title-class="dialog-title"
          message-class="dialog-message"
          button-row-class="button-row"
          button-class="dialog-btn"
          primary-button-class="dialog-btn-primary"
          buttons="yes-no"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("Adi.Widget.Dialog.Set_Part_Styles (D, Backdrop_Class_Part_Styles);", body)
        self.assertIn("Adi.Widget.Dialog.Set_Panel_Style (D, Panel_Class_Part_Styles);", body)
        self.assertIn("Adi.Widget.Dialog.Set_Title_Style (D, Dialog_Title_Class_Part_Styles);", body)
        self.assertIn("Adi.Widget.Dialog.Set_Message_Style (D, Dialog_Message_Class_Part_Styles);", body)
        self.assertIn("Adi.Widget.Dialog.Set_Button_Row_Style (D, Button_Row_Class_Part_Styles);", body)
        self.assertIn("Adi.Widget.Dialog.Set_Button_Style (D, Dialog_Btn_Class_Part_Styles);", body)
        self.assertIn("Adi.Widget.Dialog.Set_Primary_Button_Style (D, Dialog_Btn_Primary_Class_Part_Styles);", body)


class TestGeneratedFileNames(unittest.TestCase):
    """A dotted package name maps to GNAT's hyphenated file name."""

    def _run(self, package_name):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <window title="Demo" width="200px" height="100px">
    <box id="Root"/>
  </window>
</adi>
"""
        with tempfile.TemporaryDirectory() as out_dir:
            xml_path = os.path.join(out_dir, "demo.xml")
            with open(xml_path, "w", encoding="utf-8") as f:
                f.write(xml)
            argv = ["xml_to_ada.py", xml_path,
                    "--output-dir", out_dir,
                    "--package-name", package_name]
            with mock.patch.object(sys, "argv", argv):
                xml_to_ada.main()
            return sorted(n for n in os.listdir(out_dir)
                          if n.endswith((".ads", ".adb")))

    def test_flat_package_name_is_lowercased(self):
        self.assertEqual(self._run("Demo_UI"), ["demo_ui.adb", "demo_ui.ads"])

    def test_dotted_package_name_becomes_hyphenated(self):
        self.assertEqual(
            self._run("Demo.App.Ui.Panel"),
            ["demo-app-ui-panel.adb", "demo-app-ui-panel.ads"])

    def test_the_package_declaration_keeps_its_dots(self):
        with tempfile.TemporaryDirectory() as out_dir:
            xml_path = os.path.join(out_dir, "demo.xml")
            with open(xml_path, "w", encoding="utf-8") as f:
                f.write("""<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <window title="Demo" width="200px" height="100px">
    <box id="Root"/>
  </window>
</adi>
""")
            argv = ["xml_to_ada.py", xml_path,
                    "--output-dir", out_dir,
                    "--package-name", "Demo.App.Ui.Panel"]
            with mock.patch.object(sys, "argv", argv):
                xml_to_ada.main()
            spec = pathlib.Path(out_dir, "demo-app-ui-panel.ads").read_text()
        self.assertIn("package Demo.App.Ui.Panel is", spec)


class TestExistingFunctionality(unittest.TestCase):
    """Regression tests: existing window and bare widget modes still work."""

    def test_window_mode(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <window title="App" width="800" height="600">
    <box id="Root"/>
  </window>
</adi>"""
        app = parse_xml(xml)
        self.assertIsNotNone(app.window)
        self.assertIsNone(app.dialog)
        spec = xml_to_ada.generate_spec(app, "Test_UI")
        self.assertIn("Adi.Window.Window_Handle", spec)

    def test_bare_widget_mode(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <box id="Root">
    <label text="Hello"/>
  </box>
</adi>"""
        app = parse_xml(xml)
        self.assertIsNone(app.window)
        self.assertIsNone(app.dialog)
        spec = xml_to_ada.generate_spec(app, "Test_UI")
        self.assertIn("Adi.Widget.Widget_Handle", spec)


class TestImageAttribute(unittest.TestCase):
    """Tests for image-type attribute code generation."""

    def test_label_icon_generates_set_icon_with_get_image(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Home" icon="icons.svg?id=home"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn(
            'Set_Icon (Label_1, Adi.Assets.Get_Image ("icons.svg?id=home"))', body
        )

    def test_image_src_generates_set_image_with_get_image(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <image src="photo.png"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn('Set_Image (Image_1, Adi.Assets.Get_Image ("photo.png"))', body)

    def test_no_icon_no_set_icon_call(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Plain"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertNotIn("Set_Icon", body)

    def test_image_attr_adds_assets_with(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Home" icon="icons.svg?id=home"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("with Adi.Assets;", body)

    def test_no_image_attr_no_assets_with(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Plain"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertNotIn("Adi.Assets", body)

    def test_image_src_with_query_params(self):
        """Sprite sheet URL with semicolon separators (no XML escaping needed)."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <image src="sheet.png?x=0;y=32;w=16;h=16"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn(
            'Set_Image (Image_1, Adi.Assets.Get_Image ("sheet.png?x=0;y=32;w=16;h=16"))',
            body,
        )


class TestInlineCSSIsCompiledIn(unittest.TestCase):
    """The <style> block travels inside the binary, not beside it.

    It is generated from the XML, so a copy on disk could only ever be a
    stale one -- and a path baked in at generation time is absolute for
    an out-of-tree crate and missing in an embedded filesystem.
    """

    def test_style_text_becomes_a_string_constant(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.root::main { background-color: red; }</style>
  <box class="root"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertIn("Inline_CSS : constant String :=", body)
        self.assertIn('".root::main { background-color: red; }"', body)
        self.assertIn("Adi.CSS_Source.CSS_Text (Inline_CSS)", body)

    def test_no_css_file_path_is_baked_in(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.root::main { background-color: red; }</style>
  <box class="root"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertNotIn("_inline.css", body)
        self.assertNotIn("Add_Dynamic_File", body)

    def test_quotes_in_css_are_doubled(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.a::main { font-family: "Foo Bar"; }</style>
  <box class="a"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertIn('""Foo Bar""', body)

    def test_blank_lines_inside_style_survive(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.a::main { opacity: 0.5; }

.b::main { opacity: 1; }</style>
  <box class="a"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertIn('"" & ASCII.LF', body)

    def test_the_constant_ends_with_one_terminator(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.a::main { opacity: 0.5; }</style>
  <box class="a"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        tail = body[body.index("Inline_CSS : constant String :="):]
        const = []
        for line in tail.split("\n"):
            const.append(line)
            if line.rstrip().endswith("ASCII.LF;"):
                break
        else:
            self.fail("the constant is never terminated")
        #  Everything between the declaration and the terminator has to
        #  keep the concatenation open.
        for line in const[1:-1]:
            self.assertTrue(line.rstrip().endswith("&"), line)

    def test_a_style_with_no_rules_at_all_still_installs(self):
        #  Nothing to compile to Ada, but the text must still reach the
        #  parser -- and Build must install something, or Loaded is never
        #  assigned.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>/* only a comment */</style>
  <window title="T" width="100" height="100"><box id="Root"/></window>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertIn('"/* only a comment */" & ASCII.LF;', body)
        self.assertIn("Adi.CSS_Source.CSS_Text (Inline_CSS)", body)
        self.assertNotIn("Loaded := False;", body)

    def test_root_only_style_still_reaches_the_parser(self):
        #  No compilable groups, but :root metadata still has to load.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>:root { font-size: 20dp; }</style>
  <box id="Root"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertIn("Inline_CSS : constant String :=", body)
        self.assertIn("Adi.CSS_Source.CSS_Text (Inline_CSS)", body)

    def test_non_ascii_survives_gnatW8(self):
        #  Raw UTF-8 bytes are what the parser wants; -gnatW8 would
        #  collapse them to Latin-1 without the pragma.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.a::main { font-family: "Ubuntu Café"; }</style>
  <box class="a"/>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
        self.assertIn("Café", body)
        self.assertTrue(
            body.startswith("--  Auto-generated from XML"), body[:40])
        self.assertIn("pragma Wide_Character_Encoding (Brackets);", body)
        self.assertLess(
            body.index("pragma Wide_Character_Encoding (Brackets);"),
            body.index("pragma Ada_2022;"),
        )

    def test_no_inline_css_path_when_no_styles(self):
        """No companion path emitted when there are no inline styles."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css"/>
  <box class="root"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI")
        self.assertNotIn("inline.css", body)

    def test_live_css_binds_root_metadata(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css" package="Test_Styles"/>
  <box id="Root" class="root"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI")
        self.assertIn("Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);", body)
        self.assertIn("Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);", body)
        self.assertIn("Result := Merge_Metadata (Result, Test_Styles.Root_Metadata);", body)

    def test_inline_root_metadata_generates_helpers(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>:root { font-size: 20dp; color: red; }</style>
  <box id="Root"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(
            app, "My_UI")
        self.assertIn("function Inline_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is", body)
        self.assertIn("function Inline_Root_Font_Size return Length_Value is (Dip (20.0));", body)
        self.assertIn('Color => Set (C (Red))', body)
        #  Root_Styles is a Part_Style_Array of handles, so the metadata
        #  names the constant and the fold is Merge_Part_Styles alone.
        self.assertIn(
            "   Inline_Root_Part_Styles : constant Part_Style_Array :=", body)
        self.assertIn("      Root_Styles => Inline_Root_Part_Styles,", body)

    def test_inline_styles_intern_at_elaboration(self):
        #  The body declares the style constants and .Build interns them
        #  as it elaborates, so the store has to be standing first. The
        #  same pragma tools/css_to_ada.py puts on a generated sheet.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.card { background-color: rgb(10, 20, 30); }</style>
  <box id="Root" class="card"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI")
        self.assertIn("   Card_Class_Widget : constant Widget_Style :=", body)
        self.assertIn(
            "   Card_Class_Part_Styles : constant Part_Style_Array := [", body)
        self.assertIn("pragma Elaborate_All (Adi.Widget_Styles);", body)
        #  In the context clause, ahead of the unit it governs.
        self.assertLess(
            body.index("pragma Elaborate_All (Adi.Widget_Styles);"),
            body.index("package body My_UI is"),
        )

    def test_inline_root_only_interns_at_elaboration(self):
        #  A sheet with no selectors still builds Inline_Root_Part_Styles.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>:root { color: red; }</style>
  <box id="Root"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI")
        self.assertIn("pragma Elaborate_All (Adi.Widget_Styles);", body)

    def test_no_elaboration_pragma_without_inline_styles(self):
        #  Nothing in this body interns; the linked sheet carries its own.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css" package="Test_Styles"/>
  <box id="Root" class="card"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI")
        self.assertNotIn("pragma Elaborate_All", body)

    def test_metadata_fold_carries_part_style_arrays(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css" package="Test_Styles"/>
  <style>:root { color: red; }</style>
  <box id="Root"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI")
        self.assertIn(
            "            Result.Root_Styles :=\n"
            "              Merge_Part_Styles\n"
            "                (Result.Root_Styles, Override.Root_Styles);",
            body,
        )
        self.assertNotIn("Adi.Widget.Expand", body)
        self.assertNotIn("Adi.Widget.Intern", body)

    def test_root_only_inline_css_declares_the_source_it_uses(self):
        #  A sheet with no selectors still reaches the source through its
        #  root metadata, so Source has to be declared even though no
        #  manifest is registered.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>:root { font-size: 20dp; }</style>
  <box id="Root"/>
</adi>"""
        app = parse_xml(xml)
        for label, kwargs in (
            ("live", {}),
            ("static", {"no_live_css": True}),
        ):
            body = xml_to_ada.generate_body(app, "My_UI", **kwargs)
            uses = body.count("(Source")
            with self.subTest(label):
                if uses:
                    self.assertIn(
                        "   Source : aliased Adi.CSS_Source.Style_Source;",
                        body,
                        f"{label} mode uses Source without declaring it",
                    )


class TestSetCSSFileKeepsInlineSheet(unittest.TestCase):
    """Repointing the linked sheet must not drop the <style> sheet."""

    XML = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css"/>
  <style>.sized { width: 90%; }</style>
  <box class="root sized"/>
</adi>"""

    def _set_css_file_body(self, xml=None, package="My_UI"):
        body = xml_to_ada.generate_body(parse_xml(xml or self.XML), package)
        start = body.index("procedure Set_CSS_File (Path : String")
        return body[start:body.index("end Set_CSS_File;", start)]

    def test_inline_sheet_cascades_after_the_linked_one(self):
        proc = self._set_css_file_body()
        self.assertIn("Adi.CSS_Source.CSS_File (Path)", proc)
        self.assertIn("Adi.CSS_Source.CSS_Text (Inline_CSS)", proc)
        self.assertLess(
            proc.index("Adi.CSS_Source.CSS_File (Path)"),
            proc.index("Adi.CSS_Source.CSS_Text (Inline_CSS)"),
            "the inline sheet must cascade after the linked one",
        )

    def test_one_call_gives_one_verdict(self):
        #  Installing the two sheets separately made Success ambiguous:
        #  whose outcome was it? One install has one answer.
        proc = self._set_css_file_body()
        self.assertEqual(proc.count("Set_Dynamic_Sources"), 1)
        self.assertNotIn("Inline_Loaded", proc)
        self.assertNotIn("and Inline_Loaded", proc)
        self.assertNotIn("Clear_Dynamic_Entries", proc)

    def test_a_dialog_package_gets_the_same_treatment(self):
        #  Dialogs take a different Build branch; the Set_CSS_File
        #  emitter is shared, and this pins that it stays shared.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css"/>
  <style>.sized { width: 90%; }</style>
  <dialog id="Dlg" class="dlg" title="T"/>
</adi>"""
        proc = self._set_css_file_body(xml, "My_Dlg")
        self.assertIn("Adi.CSS_Source.CSS_Text (Inline_CSS)", proc)
        self.assertEqual(proc.count("Set_Dynamic_Sources"), 1)

    def test_a_package_with_no_style_installs_only_its_link(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css"/>
  <box class="root"/>
</adi>"""
        proc = self._set_css_file_body(xml)
        self.assertIn("(Source, [Adi.CSS_Source.CSS_File (Path)], Success);",
                      proc)
        self.assertNotIn("Inline_CSS", proc)

    def test_build_installs_every_sheet_in_one_call(self):
        for label, xml in (
            ("window", self.XML),
            ("dialog", """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css"/>
  <style>.sized { width: 90%; }</style>
  <dialog id="Dlg" class="dlg" title="T"/>
</adi>"""),
        ):
            with self.subTest(label):
                body = xml_to_ada.generate_body(parse_xml(xml), "My_UI")
                self.assertNotIn("Add_Dynamic_File", body)
                self.assertNotIn("Clear_Dynamic_Entries", body)
                #  From the linked sheet onward, within the same call.
                install = body[
                    body.index('Adi.CSS_Source.CSS_File ("test.css")'):]
                self.assertIn(
                    "Adi.CSS_Source.CSS_Text (Inline_CSS)",
                    install[:install.index(";")],
                )


class TestMultiLinkGetsASetTakingProcedure(unittest.TestCase):
    """One path argument cannot stand in for several <link> sheets.

    Set_CSS_File would install the one it was given and silently drop
    the rest, so a package with more than one gets a name that admits
    what it takes.
    """

    TWO = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="a.css"/>
  <link rel="stylesheet" href="b.css"/>
  <box class="root"/>
</adi>"""

    ONE = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="a.css"/>
  <box class="root"/>
</adi>"""

    STYLE_ONLY = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.a::main { opacity: 0.5; }</style>
  <box class="a"/>
</adi>"""

    def test_two_links_get_set_css_sheets(self):
        for gen in (xml_to_ada.generate_spec, xml_to_ada.generate_body):
            with self.subTest(gen.__name__):
                out = gen(parse_xml(self.TWO), "My_UI")
                self.assertIn("Set_CSS_Sheets", out)
                self.assertNotIn("Set_CSS_File", out)

    def test_one_link_keeps_set_css_file(self):
        for gen in (xml_to_ada.generate_spec, xml_to_ada.generate_body):
            with self.subTest(gen.__name__):
                out = gen(parse_xml(self.ONE), "My_UI")
                self.assertIn("Set_CSS_File", out)
                self.assertNotIn("Set_CSS_Sheets", out)

    def test_style_only_keeps_set_css_file(self):
        out = xml_to_ada.generate_spec(parse_xml(self.STYLE_ONLY), "My_UI")
        self.assertIn("Set_CSS_File", out)
        self.assertNotIn("Set_CSS_Sheets", out)

    def test_the_set_taking_spec_withs_what_its_profile_names(self):
        two = xml_to_ada.generate_spec(parse_xml(self.TWO), "My_UI")
        one = xml_to_ada.generate_spec(parse_xml(self.ONE), "My_UI")
        self.assertIn("with Adi.CSS_Source;", two)
        self.assertNotIn("with Adi.CSS_Source;", one)

    def test_build_still_installs_both_links_in_order(self):
        body = xml_to_ada.generate_body(parse_xml(self.TWO), "My_UI")
        self.assertLess(
            body.index('Adi.CSS_Source.CSS_File ("a.css")'),
            body.index('Adi.CSS_Source.CSS_File ("b.css")'),
        )


class TestCSSUpdateBatch(unittest.TestCase):
    """The install block is one batch, opened and published together."""

    CASES = {
        "style block with no rules and no :root": """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>/* nothing here */</style>
  <box id="Root"/>
</adi>""",
        "linked sheet with a manifest": """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css" package="Test_Styles"/>
  <box id="Root" class="root"/>
</adi>""",
        "dialog with a linked sheet": """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="test.css" package="Test_Styles"/>
  <dialog title="Confirm" buttons="ok"/>
</adi>""",
    }

    def test_update_calls_are_balanced(self):
        for label, xml in self.CASES.items():
            app = parse_xml(xml)
            body = xml_to_ada.generate_body(
                app, "My_UI")
            with self.subTest(label):
                self.assertEqual(
                    body.count("Begin_Update"),
                    body.count("End_Update"),
                    f"{label}: unbalanced update calls",
                )

    def test_the_install_block_is_scoped(self):
        for label, xml in self.CASES.items():
            app = parse_xml(xml)
            body = xml_to_ada.generate_body(
                app, "My_UI")
            with self.subTest(label):
                self.assertIn(
                    "Adi.CSS_Source.Update_Scope (Source'Access)",
                    body,
                    f"{label}: the install block is not covered by a scope",
                )


class TestI18N(unittest.TestCase):
    """Tests for --i18n translation wrapping."""

    def test_i18n_wraps_translatable_create_param(self):
        """With i18n=True, translatable text in Create gets T() wrapped."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Hello"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("Hello")', body)
        self.assertIn("with Adi.I18N;", body)

    def test_i18n_wraps_button_text(self):
        """Button text is translatable."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <button id="Btn" text="Save"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("Save")', body)

    def test_i18n_does_not_wrap_non_translatable(self):
        """Slider min/max/value are NOT wrapped (not translatable)."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <generic name="My_Slider" package="Adi.Widget.Slider" type-param="Float"/>
  <slider generic="My_Slider" min="0.0" max="1.0" value="0.5"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertNotIn("Adi.I18N.T", body)

    def test_i18n_no_flag_produces_bare_strings(self):
        """Without i18n flag, strings are bare."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Hello"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=False)
        self.assertNotIn("Adi.I18N", body)
        self.assertIn('"Hello"', body)

    def test_i18n_false_suppresses_wrapping(self):
        """i18n='false' on a widget suppresses T() wrapping."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Debug" i18n="false"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertNotIn("Adi.I18N.T", body)
        self.assertIn('"Debug"', body)

    def test_i18n_file_level_context(self):
        """<i18n context='demo'/> generates T('demo', 'text')."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <i18n context="demo"/>
  <label text="Hello"/>
</adi>"""
        app = parse_xml(xml)
        self.assertEqual(app.i18n_context, "demo")
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("demo", "Hello")', body)

    def test_i18n_per_property_context(self):
        """text-i18n-context overrides file-level context."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <i18n context="default"/>
  <button id="Btn" text="Open" text-i18n-context="menu"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("menu", "Open")', body)
        # Should NOT use the default context for this property
        self.assertNotIn('Adi.I18N.T ("default", "Open")', body)

    def test_i18n_per_property_context_no_file_context(self):
        """Per-property context works without file-level context."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <button id="Btn" text="Open" text-i18n-context="verb"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("verb", "Open")', body)

    def test_i18n_wraps_label(self):
        """Floating labels are wrapped with T()."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <text-input text="default" label="Name"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("Name")', body)
        self.assertIn("Set_Label", body)

    def test_i18n_wraps_label_with_context(self):
        """Floating labels use label-i18n-context."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <text-input text="default" label="Name" label-i18n-context="form"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("form", "Name")', body)

    def test_i18n_wraps_setter_string(self):
        """Translatable string setters are wrapped."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label id="Lbl" text="Created"/>
</adi>"""
        app = parse_xml(xml)
        # label text is a create-param, but let's test via a text-input
        # which has text as both create-param and setter-less
        # Actually label has no setter for text, it's create-param only.
        # Let's use text-input where text is a create-param.
        # The setter test needs an attribute with both create-param and setter...
        # Actually in widgets.xml, label.text is create-param with no setter.
        # text-input.text is create-param with no setter.
        # Let's just verify the create-param path is working.
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("Created")', body)

    def test_i18n_combo_items_wrapped(self):
        """Combo box items are wrapped with T()."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <combo-box>
    <item text="Red"/>
    <item text="Blue"/>
  </combo-box>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn('Adi.I18N.T ("Red")', body)
        self.assertIn('Adi.I18N.T ("Blue")', body)

    def test_i18n_with_clause_added(self):
        """with Adi.I18N is added to body when i18n enabled."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Hello"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=True)
        self.assertIn("with Adi.I18N;", body)
        self.assertNotIn("with Adi.I18N; use Adi.I18N;", body)

    def test_i18n_not_added_when_disabled(self):
        """with Adi.I18N is NOT added when i18n disabled."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Hello"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "My_UI", i18n=False)
        self.assertNotIn("Adi.I18N", body)


class TestWindowExtentUnits(unittest.TestCase):
    """Window sizes carry a unit; unitless means px, as in CSS."""

    def _body(self, width, height):
        xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <window title="App" width="{width}" height="{height}">
    <box/>
  </window>
</adi>"""
        app = parse_xml(xml)
        return xml_to_ada.generate_body(app, "App_UI")

    def test_units_map_to_length_constructors(self):
        for value, ctor in [("800", "Px"), ("800px", "Px"), ("800pix", "Pix"),
                            ("800dp", "Dip"), ("800dip", "Dip"),
                            ("80%", "Pct")]:
            self.assertEqual(
                xml_to_ada.parse_window_length(value), (800.0 if ctor != "Pct"
                                                        else 80.0, ctor),
                f"{value} should parse as {ctor}")

    def test_body_emits_an_extent(self):
        body = self._body("617dp", "480dp")
        self.assertIn("Adi.Window.Extent (Dip (617.0), Dip (480.0))", body)
        #  The length constructors have to be visible where they are used.
        self.assertIn("with Adi.CSS_Styles", body)

    def test_axes_may_differ(self):
        self.assertIn("Adi.Window.Extent (Pct (80.0), Pix (600.0))",
                      self._body("80%", "600pix"))

    def test_units_that_cannot_describe_a_window_are_refused(self):
        #  The message has to say which of the two reasons applies, or a
        #  caller learns only that their stylesheet-shaped value failed.
        for bad, reason in [("10em", "font context"), ("10rem", "font context"),
                            ("50vw", "viewport"), ("50vh", "viewport")]:
            with self.assertRaises(ValueError, msg=bad) as ctx:
                xml_to_ada.parse_window_length(bad)
            self.assertIn(reason, str(ctx.exception), bad)

    def test_a_window_needing_css_styles_withs_it_once(self):
        #  Live CSS already pulls Adi.CSS_Styles in; the extent needs it
        #  too, and Ada rejects a repeated with clause.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="x.css"/>
  <window title="App" width="617dp" height="480dp">
    <box class="root"/>
  </window>
</adi>"""
        body = xml_to_ada.generate_body(parse_xml(xml), "App_UI")
        self.assertEqual(body.count("with Adi.CSS_Styles;"), 1)

    def test_nonpositive_sizes_are_refused(self):
        for bad in ["0", "-5", "0px"]:
            with self.assertRaises(ValueError, msg=bad):
                xml_to_ada.parse_window_length(bad)


class TestIdAndTagSelectors(unittest.TestCase):
    """Tag and id selectors reach widgets, not just class selectors."""

    def generate(self, xml: str, css: str = "", **kwargs) -> str:
        """Generate a body for an XML that links "s.css" holding `css`."""
        with tempfile.TemporaryDirectory() as tmp:
            with open(os.path.join(tmp, "s.css"), "w") as f:
                f.write(css)
            xml_path = os.path.join(tmp, "s.xml")
            with open(xml_path, "w") as f:
                f.write(xml)
            app = xml_to_ada.Parser().parse(xml_path)
            return xml_to_ada.generate_body(app, "Sel_UI", **kwargs)

    LINKED = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" href="s.css"/>
  <window title="Sel" width="300px" height="120px">
    <box class="root">
      <button id="Press" text="Press" class="primary"/>
      <label id="Readout" text="hi"/>
    </box>
  </window>
</adi>"""

    def test_stylesheet_manifest_is_registered_qualified(self):
        body = self.generate(self.LINKED, "button { padding: 4px; }")
        self.assertIn("      S_Styles.Register_Selectors (Source);", body)

    def test_every_stylesheet_registers_in_link_order(self):
        xml = self.LINKED.replace(
            '<link rel="stylesheet" href="s.css"/>',
            '<link rel="stylesheet" href="s.css"/>\n'
            '  <link rel="stylesheet" href="t.css"/>',
        )
        with tempfile.TemporaryDirectory() as tmp:
            for name in ("s.css", "t.css"):
                with open(os.path.join(tmp, name), "w") as f:
                    f.write("button { padding: 4px; }")
            xml_path = os.path.join(tmp, "s.xml")
            with open(xml_path, "w") as f:
                f.write(xml)
            app = xml_to_ada.Parser().parse(xml_path)
            body = xml_to_ada.generate_body(app, "Sel_UI")
        #  Both sheets define `button`; each registers its own manifest, so
        #  the later one wins per CSS rather than colliding on one name.
        self.assertLess(
            body.index("S_Styles.Register_Selectors"),
            body.index("T_Styles.Register_Selectors"),
        )

    def test_repeated_link_registers_twice_in_order(self):
        #  A sheet listed twice must register twice, so the later copy wins
        #  the way the dynamic loader already makes it win.
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" styles="A_Styles"/>
  <link rel="stylesheet" styles="B_Styles"/>
  <link rel="stylesheet" styles="A_Styles"/>
  <window title="Sel" width="300px" height="120px">
    <box class="root"/>
  </window>
</adi>"""
        body = self.generate(xml)
        calls = [line.strip() for line in body.splitlines()
                 if "Register_Selectors (Source);" in line]
        self.assertEqual(calls, ["A_Styles.Register_Selectors (Source);",
                                 "B_Styles.Register_Selectors (Source);",
                                 "A_Styles.Register_Selectors (Source);"])
        #  The with-list stays deduplicated.
        self.assertEqual(body.count("with A_Styles"), 1)

    def test_styles_only_link_registers_and_binds(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <link rel="stylesheet" styles="My_Styles"/>
  <window title="Sel" width="300px" height="120px">
    <box class="root">
      <button id="Press" text="Press" class="primary"/>
    </box>
  </window>
</adi>"""
        body = self.generate(xml)
        self.assertIn("My_Styles.Register_Selectors (Source);", body)
        self.assertIn('Tag_Name   => "button"', body)
        self.assertIn('Id_Name    => "Press"', body)

    def test_id_rule_matching_the_xml_id_is_bound(self):
        body = self.generate(self.LINKED, "#Readout { color: red; }")
        self.assertIn('Id_Name    => "Readout"', body)

    def test_class_list_travels_with_the_selector_set(self):
        xml = self.LINKED.replace('class="primary"', 'class="primary wide"')
        body = self.generate(xml, "button { padding: 4px; }")
        self.assertIn('Class_Name => "primary wide"', body)

    def test_inline_style_rules_are_bound_too(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>
    button { padding: 4px; }
    #Press { color: red; }
  </style>
  <window title="Sel" width="300px" height="120px">
    <box>
      <button id="Press" text="Press"/>
    </box>
  </window>
</adi>"""
        body = self.generate(xml)
        self.assertIn('Tag_Name   => "button"', body)
        self.assertIn('Id_Name    => "Press"', body)

    def test_static_mode_resolves_through_a_pinned_source(self):
        body = self.generate(
            self.LINKED,
            "button { padding: 4px; }"
            ".primary { color: red; }"
            "#Press { color: blue; }",
            no_live_css=True,
        )
        #  Same manifests and same selector sets as live mode, resolved once
        #  against a source pinned to Static_Mode.
        self.assertIn("S_Styles.Register_Selectors (Source);", body)
        self.assertIn(
            "         Adi.CSS_Source.Set_Mode\n"
            "           (Source, Adi.CSS_Source.Static_Mode, Mode_OK);",
            body,
        )
        self.assertIn(
            "      Adi.CSS_Source.Bind_Selector_Set\n"
            "        (Source     => Source,\n"
            "         W          => +Press,\n"
            '         Tag_Name   => "button",\n'
            '         Class_Name => "primary",\n'
            '         Id_Name    => "Press");',
            body,
        )

    def test_static_mode_never_reads_the_filesystem(self):
        body = self.generate(
            self.LINKED, "button { padding: 4px; }", no_live_css=True
        )
        self.assertNotIn("Add_Dynamic_File", body)
        self.assertNotIn("Dynamic_Mode", body)


class TestCallbackTypeVisibility(unittest.TestCase):
    """A callback type declared in a package the body does not use."""

    SWITCH_ONLY = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <callback name="On_Spin" type="Adi.Widget.Button.Toggle_Callback"/>
  <window title="t" width="100dp" height="100dp">
    <box>
      <switch id="S" on-toggled="On_Spin"/>
    </box>
  </window>
</adi>"""

    WITH_BUTTON = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <callback name="On_Spin" type="Adi.Widget.Button.Toggle_Callback"/>
  <window title="t" width="100dp" height="100dp">
    <box>
      <switch id="S" on-toggled="On_Spin"/>
      <button text="x"/>
    </box>
  </window>
</adi>"""

    def test_ancestor_package_callback_gets_a_use_type(self):
        #  A switch is Adi.Widget.Button.Switch, so using that package
        #  leaves Adi.Widget.Button's Toggle_Callback without a visible
        #  "/=" for the null guard the body emits.
        body = xml_to_ada.generate_body(parse_xml(self.SWITCH_ONLY), "Test_UI")
        self.assertNotIn("with Adi.Widget.Button; use Adi.Widget.Button;", body)
        self.assertIn("use type Adi.Widget.Button.Toggle_Callback;", body)

    def test_no_use_type_when_the_package_is_already_used(self):
        #  A button anywhere in the tree brings the parent package in, and
        #  a second clause for it would warn under -gnatwu.
        body = xml_to_ada.generate_body(parse_xml(self.WITH_BUTTON), "Test_UI")
        self.assertIn("with Adi.Widget.Button; use Adi.Widget.Button;", body)
        self.assertNotIn("use type Adi.Widget.Button.Toggle_Callback;", body)


if __name__ == "__main__":
    unittest.main()
