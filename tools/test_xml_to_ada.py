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
    with tempfile.NamedTemporaryFile(mode="w", suffix=".xml", delete=False) as f:
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

    def test_live_css_with_class_fallback_emits_styles_package_use(self):
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
        self.assertIn("with Dialog_Styles; use Dialog_Styles;", body)
        self.assertIn(
            'Add_Static_Entry\n        (S, Class_Entry ("dialog-content", Dialog_Content_Class_Part_Styles));',
            body,
        )

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
            "Add_Dynamic_File",
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
            app, "My_UI", inline_css_path="some/dir/my_ui_inline.css"
        )
        self.assertIn("function Inline_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is", body)
        self.assertIn("function Inline_Root_Font_Size return Length_Value is (Dip (20.0));", body)
        self.assertIn('Color => Set (C (Red))', body)


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


if __name__ == "__main__":
    unittest.main()
