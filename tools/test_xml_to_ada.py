#!/usr/bin/env python3
"""Tests for xml_to_ada.py — focused on <dialog> root element support."""

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import xml_to_ada


def parse_xml(xml_str: str) -> xml_to_ada.XmlApp:
    """Parse an XML string and return the XmlApp."""
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".xml", delete=False
    ) as f:
        f.write(xml_str)
        f.flush()
        try:
            parser = xml_to_ada.Parser()
            return parser.parse(f.name)
        finally:
            os.unlink(f.name)


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

    def test_spec_returns_dialog_widget_access(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Test"/>
</adi>"""
        app = parse_xml(xml)
        spec = xml_to_ada.generate_spec(app, "Test_Dialog_UI")
        self.assertIn("Adi.Widget.Dialog", spec)
        self.assertIn(
            "function Build return Adi.Widget.Dialog.Dialog_Widget_Access;",
            spec,
        )
        # Should NOT have Adi.Window or bare Adi.Widget return
        self.assertNotIn("Adi.Window", spec)
        self.assertNotIn("return Adi.Widget.Widget_Access", spec)

    def test_body_creates_dialog_and_sets_title(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog title="Hello World"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_Dialog_UI")
        self.assertIn("Adi.Widget.Dialog.Create", body)
        self.assertIn('D.Set_Title ("Hello World")', body)
        self.assertIn("return D;", body)

    def test_body_sets_message(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog message="Are you sure?"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn('D.Set_Message ("Are you sure?")', body)

    def test_body_button_presets(self):
        for preset, method in xml_to_ada.DIALOG_BUTTON_PRESETS.items():
            xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="{preset}"/>
</adi>"""
            app = parse_xml(xml)
            body = xml_to_ada.generate_body(app, "Test_UI")
            self.assertIn(f"D.{method}", body)

    def test_body_default_button(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="ok-cancel" default-button="1"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("D.Set_Default_Button (1)", body)

    def test_body_default_button_zero(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog buttons="yes-no" default-button="0"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("D.Set_Default_Button (0)", body)

    def test_body_dismiss_flags(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <dialog dismiss-on-backdrop="true" dismiss-on-escape="false"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn("D.Set_Dismiss_On_Backdrop (True)", body)
        self.assertIn("D.Set_Dismiss_On_Escape (False)", body)

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
        self.assertIn("D.Set_Content (Content)", body)
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
        self.assertIn("Adi.Widget.Dialog.Create", body)
        self.assertIn("return D;", body)
        # Should not have Set_Title etc. since no attributes
        self.assertNotIn("Set_Title", body)
        self.assertNotIn("Set_Message", body)
        self.assertNotIn("Set_OK", body)

    def test_dialog_with_css_link(self):
        """Dialog with CSS link generates Bind_Class on content widget."""
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
        self.assertIn("Dialog_Content_Class_Part_Styles", body)


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
        self.assertIn("Adi.Window.Window_Access", spec)

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
        self.assertIn("Adi.Widget.Widget_Access", spec)


class TestImageAttribute(unittest.TestCase):
    """Tests for image-type attribute code generation."""

    def test_label_icon_generates_set_icon_with_get_image(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <label text="Home" icon="icons.svg?id=home"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn('Set_Icon (Adi.Assets.Get_Image ("icons.svg?id=home"))', body)

    def test_image_src_generates_set_image_with_get_image(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <image src="photo.png"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(app, "Test_UI")
        self.assertIn('Set_Image (Adi.Assets.Get_Image ("photo.png"))', body)

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
            'Set_Image (Adi.Assets.Get_Image ("sheet.png?x=0;y=32;w=16;h=16"))',
            body,
        )


class TestInlineCSSCompanionPath(unittest.TestCase):
    """Tests for inline <style> companion CSS file path generation."""

    def test_inline_css_path_uses_output_dir(self):
        """Companion CSS path is derived from output_dir, not CWD."""
        xml = """<?xml version="1.0" encoding="UTF-8"?>
<adi>
  <style>.root::main { background-color: red; }</style>
  <box class="root"/>
</adi>"""
        app = parse_xml(xml)
        body = xml_to_ada.generate_body(
            app, "My_UI", inline_css_path="some/dir/my_ui_inline.css"
        )
        self.assertIn(
            'Add_Dynamic_File',
            body,
        )
        self.assertIn(
            '"some/dir/my_ui_inline.css"',
            body,
        )
        self.assertNotIn("Add_Dynamic_String", body)
        self.assertNotIn("Inline_CSS", body)

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


if __name__ == "__main__":
    unittest.main()
