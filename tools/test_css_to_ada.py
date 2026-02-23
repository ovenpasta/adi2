#!/usr/bin/env python3
"""
Test harness for css_to_ada.py

Tests CSS parsing, Ada code generation, property support, shorthand expansion,
selector parsing, and rule merging.

Usage: python tools/test_css_to_ada.py
"""

import sys
import os
import unittest

# Add tools directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from css_to_ada import (
    parse_length,
    parse_color,
    parse_selector,
    parse_box_values,
    parse_box_shadow,
    parse_transition,
    parse_css,
    parse_grid_track_count,
    parse_grid_placement,
    parse_list_style_shorthand,
    parse_css_quoted_string,
    parse_css_url_function,
    split_css_whitespace_tokens,
    group_rules_by_widget,
    generate_style_rules_ada,
    generate_ada_package,
    generate_length_ada,
    generate_color_ada,
    to_ada_identifier,
    box_lengths_to_four,
    merge_css_properties,
    set_css_property,
    WidgetState,
    ParsedLength,
    ParsedColor,
    OUTLINE_STYLE_MAP,
)


class TestParseLength(unittest.TestCase):
    def test_px(self):
        r = parse_length("10px")
        self.assertEqual(r.amount, 10.0)
        self.assertEqual(r.unit, "Px")

    def test_em(self):
        r = parse_length("1.5em")
        self.assertEqual(r.amount, 1.5)
        self.assertEqual(r.unit, "Em")

    def test_rem(self):
        r = parse_length("2rem")
        self.assertEqual(r.amount, 2.0)
        self.assertEqual(r.unit, "Root_Em")

    def test_percent(self):
        r = parse_length("50%")
        self.assertEqual(r.amount, 50.0)
        self.assertEqual(r.unit, "Pct")

    def test_dp(self):
        r = parse_length("7dp")
        self.assertEqual(r.amount, 7.0)
        self.assertEqual(r.unit, "Dip")

    def test_dip(self):
        r = parse_length("7dip")
        self.assertEqual(r.amount, 7.0)
        self.assertEqual(r.unit, "Dip")

    def test_vw(self):
        r = parse_length("100vw")
        self.assertEqual(r.amount, 100.0)
        self.assertEqual(r.unit, "Vw")

    def test_vh(self):
        r = parse_length("100vh")
        self.assertEqual(r.amount, 100.0)
        self.assertEqual(r.unit, "Vh")

    def test_zero(self):
        r = parse_length("0")
        self.assertEqual(r.amount, 0.0)
        self.assertEqual(r.unit, "Px")

    def test_negative(self):
        r = parse_length("-5px")
        self.assertEqual(r.amount, -5.0)

    def test_decimal(self):
        r = parse_length("0.5px")
        self.assertAlmostEqual(r.amount, 0.5)

    def test_no_unit_treated_as_px(self):
        r = parse_length("12")
        self.assertEqual(r.amount, 12.0)
        self.assertEqual(r.unit, "Px")

    def test_invalid(self):
        self.assertIsNone(parse_length("abc"))
        self.assertIsNone(parse_length(""))


class TestParseColor(unittest.TestCase):
    def test_named_white(self):
        c = parse_color("white")
        self.assertEqual(c.kind, "named")
        self.assertEqual(c.name, "White")

    def test_named_transparent(self):
        c = parse_color("transparent")
        self.assertEqual(c.kind, "named")
        self.assertEqual(c.name, "Transparent")

    def test_named_currentcolor(self):
        c = parse_color("currentcolor")
        self.assertEqual(c.kind, "named")
        self.assertEqual(c.name, "Current_Color")

    def test_hex3(self):
        c = parse_color("#f0a")
        self.assertEqual(c.kind, "rgb")
        self.assertEqual(c.r, 255)
        self.assertEqual(c.g, 0)
        self.assertEqual(c.b, 170)

    def test_hex6(self):
        c = parse_color("#445566")
        self.assertEqual(c.kind, "rgb")
        self.assertEqual(c.r, 68)
        self.assertEqual(c.g, 85)
        self.assertEqual(c.b, 102)

    def test_hex8(self):
        c = parse_color("#44556680")
        self.assertEqual(c.kind, "rgba")
        self.assertAlmostEqual(c.a, 128 / 255.0, places=2)

    def test_rgb(self):
        c = parse_color("rgb(10, 20, 30)")
        self.assertEqual(c.kind, "rgb")
        self.assertEqual(c.r, 10)
        self.assertEqual(c.g, 20)
        self.assertEqual(c.b, 30)

    def test_rgba(self):
        c = parse_color("rgba(10, 20, 30, 0.5)")
        self.assertEqual(c.kind, "rgba")
        self.assertEqual(c.r, 10)
        self.assertAlmostEqual(c.a, 0.5)

    def test_named_svg_color(self):
        c = parse_color("cornflowerblue")
        self.assertEqual(c.kind, "named")
        self.assertEqual(c.name, "Cornflower_Blue")

    def test_grey_alias(self):
        c = parse_color("grey")
        self.assertEqual(c.name, "Gray")

    def test_case_insensitive(self):
        c = parse_color("WHITE")
        self.assertEqual(c.name, "White")

    def test_invalid(self):
        self.assertIsNone(parse_color("notacolor"))
        self.assertIsNone(parse_color(""))


class TestParseSelector(unittest.TestCase):
    def test_class(self):
        s = parse_selector(".button")
        self.assertEqual(s.name, "button")
        self.assertEqual(s.selector_type, "class")
        self.assertEqual(s.part_kind, "Main_Part")

    def test_id(self):
        s = parse_selector("#submit")
        self.assertEqual(s.name, "submit")
        self.assertEqual(s.selector_type, "id")

    def test_tag(self):
        s = parse_selector("button")
        self.assertEqual(s.name, "button")
        self.assertEqual(s.selector_type, "tag")

    def test_class_with_hover(self):
        s = parse_selector(".btn:hover")
        self.assertEqual(s.name, "btn")
        self.assertIn(WidgetState.HOVERED, s.widget_states)

    def test_class_with_part(self):
        s = parse_selector(".btn::label")
        self.assertEqual(s.part_kind, "Label_Part")

    def test_pseudo_before_part(self):
        s = parse_selector(".btn:focus::main")
        self.assertIn(WidgetState.FOCUSED, s.widget_states)
        self.assertEqual(s.part_kind, "Main_Part")

    def test_pseudo_after_part_interactive(self):
        s = parse_selector(".btn::label:hover")
        self.assertEqual(s.part_kind, "Label_Part")
        self.assertIn(WidgetState.HOVERED, s.part_states)
        self.assertEqual(len(s.widget_states), 0)

    def test_pseudo_after_part_non_interactive(self):
        s = parse_selector(".btn::label:selected")
        self.assertEqual(s.part_kind, "Label_Part")
        self.assertIn(WidgetState.SELECTED, s.widget_states)
        self.assertEqual(len(s.part_states), 0)

    def test_not_pseudo(self):
        s = parse_selector(".card:not(:disabled)")
        self.assertIn(WidgetState.DISABLED, s.widget_negated_states)

    def test_enabled_pseudo(self):
        s = parse_selector(".card:enabled")
        self.assertIn(WidgetState.DISABLED, s.widget_negated_states)

    def test_multiple_pseudos(self):
        s = parse_selector(".sw:selected:focus::main")
        self.assertIn(WidgetState.SELECTED, s.widget_states)
        self.assertIn(WidgetState.FOCUSED, s.widget_states)

    def test_unknown_part_returns_none(self):
        self.assertIsNone(parse_selector(".btn::unknown"))

    def test_all_part_kinds(self):
        for css_name, ada_name in [
            ("main", "Main_Part"), ("label", "Label_Part"),
            ("cursor", "Cursor_Part"), ("selected", "Selected_Part"),
            ("icon", "Icon_Part"), ("indicator", "Indicator_Part"),
            ("scroll", "Scroll_Part"), ("knob", "Knob_Part"),
            ("items", "Items_Part"),
        ]:
            s = parse_selector(f".w::{css_name}")
            self.assertEqual(s.part_kind, ada_name, f"Part {css_name}")


class TestParseBoxValues(unittest.TestCase):
    def test_one(self):
        r = parse_box_values("10px")
        self.assertEqual(len(r), 1)

    def test_two(self):
        r = parse_box_values("4px 8px")
        self.assertEqual(len(r), 2)

    def test_four(self):
        r = parse_box_values("1px 2px 3px 4px")
        self.assertEqual(len(r), 4)

    def test_invalid(self):
        self.assertIsNone(parse_box_values("abc"))


class TestBoxLengthsToFour(unittest.TestCase):
    def test_one_expands(self):
        r = box_lengths_to_four([ParsedLength(5, "Px")])
        self.assertEqual(len(r), 4)
        self.assertTrue(all(x.amount == 5 for x in r))

    def test_two_expands(self):
        r = box_lengths_to_four([ParsedLength(1, "Px"), ParsedLength(2, "Px")])
        self.assertEqual(r[0].amount, 1)  # top
        self.assertEqual(r[1].amount, 2)  # right
        self.assertEqual(r[2].amount, 1)  # bottom
        self.assertEqual(r[3].amount, 2)  # left

    def test_three_expands(self):
        r = box_lengths_to_four([ParsedLength(1, "Px"), ParsedLength(2, "Px"), ParsedLength(3, "Px")])
        self.assertEqual(r[0].amount, 1)  # top
        self.assertEqual(r[1].amount, 2)  # right
        self.assertEqual(r[2].amount, 3)  # bottom
        self.assertEqual(r[3].amount, 2)  # left


class TestParseBoxShadow(unittest.TestCase):
    def test_basic(self):
        s = parse_box_shadow("2px 4px 6px rgba(0, 0, 0, 0.3)")
        self.assertIsNotNone(s)
        self.assertEqual(s.offset_x.amount, 2.0)
        self.assertEqual(s.offset_y.amount, 4.0)
        self.assertEqual(s.blur_radius.amount, 6.0)
        self.assertEqual(s.color.kind, "rgba")

    def test_with_spread(self):
        s = parse_box_shadow("1px 2px 3px 4px #000000")
        self.assertIsNotNone(s)
        self.assertEqual(s.spread_radius.amount, 4.0)

    def test_none(self):
        self.assertIsNone(parse_box_shadow("none"))

    def test_minimal(self):
        s = parse_box_shadow("0px 0px")
        self.assertIsNotNone(s)
        self.assertEqual(s.blur_radius.amount, 0.0)


class TestParseTransition(unittest.TestCase):
    def test_ms(self):
        t = parse_transition("background-color 500ms ease")
        self.assertAlmostEqual(t.duration_seconds, 0.5)
        self.assertEqual(t.easing, "Ease_In_Out")
        self.assertEqual(t.property_set, "Props (Prop_Background_Color)")

    def test_seconds(self):
        t = parse_transition("opacity 1.25s linear")
        self.assertAlmostEqual(t.duration_seconds, 1.25)
        self.assertEqual(t.easing, "Linear")

    def test_all(self):
        t = parse_transition("all 0.3s ease-in-out")
        self.assertEqual(t.property_set, "All_Properties")

    def test_none(self):
        self.assertIsNone(parse_transition("none"))

    def test_no_duration(self):
        self.assertIsNone(parse_transition("background-color ease"))


class TestParseGridTrackCount(unittest.TestCase):
    def test_repeat(self):
        self.assertEqual(parse_grid_track_count("repeat(3, 1fr)"), 3)

    def test_explicit_tracks(self):
        self.assertEqual(parse_grid_track_count("1fr 1fr 1fr"), 3)

    def test_none(self):
        self.assertIsNone(parse_grid_track_count("none"))

    def test_number(self):
        self.assertEqual(parse_grid_track_count("4"), 4)


class TestParseGridPlacement(unittest.TestCase):
    def test_start(self):
        start, span = parse_grid_placement("2")
        self.assertEqual(start, 2)
        self.assertIsNone(span)

    def test_span(self):
        start, span = parse_grid_placement("span 3")
        self.assertIsNone(start)
        self.assertEqual(span, 3)

    def test_start_end(self):
        start, span = parse_grid_placement("1 / 4")
        self.assertEqual(start, 1)
        self.assertEqual(span, 3)

    def test_auto(self):
        start, span = parse_grid_placement("auto")
        self.assertIsNone(start)
        self.assertIsNone(span)


class TestListStyleShorthand(unittest.TestCase):
    def test_type_only(self):
        r = parse_list_style_shorthand("disc")
        self.assertEqual(r.get("type"), "disc")

    def test_none(self):
        r = parse_list_style_shorthand("none")
        self.assertEqual(r.get("type"), "none")
        self.assertEqual(r.get("image"), "none")

    def test_full(self):
        r = parse_list_style_shorthand("url(marker.svg) square outside")
        self.assertEqual(r.get("type"), "square")
        self.assertEqual(r.get("position"), "outside")
        self.assertIn("url(marker.svg)", r.get("image", ""))

    def test_quoted_marker(self):
        r = parse_list_style_shorthand('"-> "')
        self.assertEqual(r.get("type"), '"-> "')


class TestSplitCssWhitespaceTokens(unittest.TestCase):
    def test_simple(self):
        self.assertEqual(split_css_whitespace_tokens("2px solid red"), ["2px", "solid", "red"])

    def test_parens(self):
        tokens = split_css_whitespace_tokens("2px solid rgb(10, 20, 30)")
        self.assertEqual(len(tokens), 3)
        self.assertEqual(tokens[2], "rgb(10, 20, 30)")

    def test_quoted(self):
        tokens = split_css_whitespace_tokens('"hello world" test')
        self.assertEqual(len(tokens), 2)
        self.assertEqual(tokens[0], '"hello world"')


class TestCssUrlAndString(unittest.TestCase):
    def test_quoted_string(self):
        self.assertEqual(parse_css_quoted_string('"hello"'), "hello")
        self.assertEqual(parse_css_quoted_string("'world'"), "world")
        self.assertIsNone(parse_css_quoted_string("nope"))

    def test_url(self):
        self.assertEqual(parse_css_url_function("url(test.svg)"), "test.svg")
        self.assertEqual(parse_css_url_function('url("test.svg")'), "test.svg")
        self.assertIsNone(parse_css_url_function("noturl"))


class TestToAdaIdentifier(unittest.TestCase):
    def test_hyphen(self):
        self.assertEqual(to_ada_identifier("nav-btn"), "Nav_Btn")

    def test_single(self):
        self.assertEqual(to_ada_identifier("card"), "Card")

    def test_multiple(self):
        self.assertEqual(to_ada_identifier("app-bar-title"), "App_Bar_Title")


class TestMergeProperties(unittest.TestCase):
    def test_basic_merge(self):
        target = {"color": "red", "padding": "4px"}
        source = {"color": "blue", "margin": "8px"}
        merge_css_properties(target, source)
        self.assertEqual(target["color"], "blue")
        self.assertEqual(target["padding"], "4px")
        self.assertEqual(target["margin"], "8px")

    def test_order_preserved(self):
        target = {"a": "1", "b": "2"}
        source = {"a": "3"}
        merge_css_properties(target, source)
        # 'a' should be moved to end when overridden
        keys = list(target.keys())
        self.assertEqual(keys, ["b", "a"])
        self.assertEqual(target["a"], "3")

    def test_set_css_property_move_to_end(self):
        props = {"x": "1", "y": "2", "z": "3"}
        set_css_property(props, "x", "99")
        keys = list(props.keys())
        self.assertEqual(keys[-1], "x")
        self.assertEqual(props["x"], "99")


class TestParseCss(unittest.TestCase):
    def test_basic_rule(self):
        rules = parse_css(".card { color: red; padding: 4px; }")
        self.assertEqual(len(rules), 1)
        self.assertEqual(rules[0].selector.name, "card")
        self.assertEqual(rules[0].properties["color"], "red")
        self.assertEqual(rules[0].properties["padding"], "4px")

    def test_comma_selector(self):
        rules = parse_css(".a, .b { color: red; }")
        self.assertEqual(len(rules), 2)
        self.assertEqual(rules[0].selector.name, "a")
        self.assertEqual(rules[1].selector.name, "b")

    def test_comments_removed(self):
        rules = parse_css("/* comment */ .x { color: red; }")
        self.assertEqual(len(rules), 1)

    def test_state_rule(self):
        rules = parse_css(".btn:hover { background-color: blue; }")
        self.assertEqual(len(rules), 1)
        self.assertIn(WidgetState.HOVERED, rules[0].selector.widget_states)

    def test_part_rule(self):
        rules = parse_css(".btn::label { color: white; }")
        self.assertEqual(len(rules), 1)
        self.assertEqual(rules[0].selector.part_kind, "Label_Part")


class TestGroupRules(unittest.TestCase):
    def test_merges_base_rules(self):
        rules = parse_css(
            ".card { color: red; } .card { padding: 4px; }"
        )
        groups = group_rules_by_widget(rules)
        key = "class:card"
        self.assertIn(key, groups)
        main = groups[key].parts["Main_Part"]
        self.assertIn("color", main.base_rule.properties)
        self.assertIn("padding", main.base_rule.properties)

    def test_merges_state_rules(self):
        rules = parse_css(
            ".card:hover { color: red; } .card:hover { padding: 4px; }"
        )
        groups = group_rules_by_widget(rules)
        main = groups["class:card"].parts["Main_Part"]
        self.assertEqual(len(main.state_rules), 1)
        self.assertIn("color", main.state_rules[0].properties)
        self.assertIn("padding", main.state_rules[0].properties)

    def test_separate_parts(self):
        rules = parse_css(
            ".btn::main { padding: 4px; } .btn::label { color: red; }"
        )
        groups = group_rules_by_widget(rules)
        self.assertIn("Main_Part", groups["class:btn"].parts)
        self.assertIn("Label_Part", groups["class:btn"].parts)

    def test_override_on_merge(self):
        rules = parse_css(
            ".card { color: red; } .card { color: blue; }"
        )
        groups = group_rules_by_widget(rules)
        main = groups["class:card"].parts["Main_Part"]
        self.assertEqual(main.base_rule.properties["color"], "blue")


class TestGenerateStyleRulesAda(unittest.TestCase):
    """Test Ada code generation for all supported CSS properties."""

    def _gen(self, props: dict[str, str]) -> str:
        return "\n".join(generate_style_rules_ada(props))

    # -- Color properties --

    def test_color(self):
        ada = self._gen({"color": "red"})
        self.assertIn("Color => Set (C (Red))", ada)

    def test_background_color_rgb(self):
        ada = self._gen({"background-color": "rgb(10, 20, 30)"})
        self.assertIn("Background_Color => Set_Bg (RGB (10, 20, 30))", ada)

    def test_background_color_rgba(self):
        ada = self._gen({"background-color": "rgba(10, 20, 30, 0.5)"})
        self.assertIn("RGBA (10, 20, 30, 0.5)", ada)

    def test_background_color_hex(self):
        ada = self._gen({"background-color": "#ff0000"})
        self.assertIn("RGB (255, 0, 0)", ada)

    # -- Box model --

    def test_padding_uniform(self):
        ada = self._gen({"padding": "4px"})
        self.assertIn("Padding => Set (", ada)

    def test_padding_two_value(self):
        ada = self._gen({"padding": "4px 8px"})
        self.assertIn("Padding => Set (", ada)

    def test_padding_four_value(self):
        ada = self._gen({"padding": "1px 2px 3px 4px"})
        self.assertIn("Padding => Set (", ada)

    def test_padding_longhand_override(self):
        ada = self._gen({"padding": "10px", "padding-left": "20px"})
        self.assertIn("Px (20.0)", ada)

    def test_margin(self):
        ada = self._gen({"margin": "5px"})
        self.assertIn("Margin => Set (", ada)

    def test_margin_longhand(self):
        ada = self._gen({"margin": "5px", "margin-top": "9px"})
        self.assertIn("Px (9.0)", ada)

    # -- Border --

    def test_border_width(self):
        ada = self._gen({"border-width": "2px"})
        self.assertIn("Border_Width => Set (Border_Width (Px (2.0)))", ada)

    def test_border_color(self):
        ada = self._gen({"border-color": "red"})
        self.assertIn("Border_Color => Set (Border_Color (C (Red)))", ada)

    def test_border_style(self):
        ada = self._gen({"border-style": "solid"})
        self.assertIn("Border_Style => Set (Border_Style (Solid))", ada)

    def test_border_radius(self):
        ada = self._gen({"border-radius": "8px"})
        self.assertIn("Border_Radius => Set (Radius (Px (8.0)))", ada)

    def test_border_shorthand(self):
        ada = self._gen({"border": "2px solid red"})
        self.assertIn("Border_Width =>", ada)
        self.assertIn("Border_Style =>", ada)
        self.assertIn("Border_Color =>", ada)

    # -- Sizing --

    def test_width(self):
        ada = self._gen({"width": "120px"})
        self.assertIn("Width => Set (Size (Px (120.0)))", ada)

    def test_width_auto(self):
        ada = self._gen({"width": "auto"})
        self.assertIn("Width => Set (Auto_Size)", ada)

    def test_width_min_content(self):
        ada = self._gen({"width": "min-content"})
        self.assertIn("Width => Set (Min_Content_Size)", ada)

    def test_width_max_content(self):
        ada = self._gen({"width": "max-content"})
        self.assertIn("Width => Set (Max_Content_Size)", ada)

    def test_width_fit_content(self):
        ada = self._gen({"width": "fit-content"})
        self.assertIn("Width => Set (Fit_Content_Size)", ada)

    def test_height(self):
        ada = self._gen({"height": "50px"})
        self.assertIn("Height => Set (Size (Px (50.0)))", ada)

    def test_min_width(self):
        ada = self._gen({"min-width": "100px"})
        self.assertIn("Min_Width =>", ada)

    def test_max_width(self):
        ada = self._gen({"max-width": "500px"})
        self.assertIn("Max_Width =>", ada)

    def test_min_height(self):
        ada = self._gen({"min-height": "40px"})
        self.assertIn("Min_Height =>", ada)

    def test_max_height(self):
        ada = self._gen({"max-height": "300px"})
        self.assertIn("Max_Height =>", ada)

    # -- Typography --

    def test_font_size(self):
        ada = self._gen({"font-size": "14px"})
        self.assertIn("Font_Size => Set_Font (Px (14.0))", ada)

    def test_font_weight_number(self):
        ada = self._gen({"font-weight": "700"})
        self.assertIn("Font_Weight => Set (Weight_Bold)", ada)

    def test_font_weight_keyword(self):
        ada = self._gen({"font-weight": "bold"})
        self.assertIn("Font_Weight => Set (Weight_Bold)", ada)

    def test_font_style(self):
        ada = self._gen({"font-style": "italic"})
        self.assertIn("Font_Style => Set (Style_Italic)", ada)

    def test_text_align(self):
        ada = self._gen({"text-align": "center"})
        self.assertIn("Text_Align => Set (Text_Center)", ada)

    def test_text_wrap_mode(self):
        ada = self._gen({"text-wrap-mode": "nowrap"})
        self.assertIn("Text_Wrap_Mode => Set (TWM_Nowrap)", ada)

    def test_vertical_align(self):
        ada = self._gen({"vertical-align": "middle"})
        self.assertIn("Vertical_Align => Set (VA_Middle)", ada)

    def test_text_decoration(self):
        ada = self._gen({"text-decoration": "underline"})
        self.assertIn("Text_Decoration => Set (Decoration_Underline)", ada)

    def test_white_space(self):
        ada = self._gen({"white-space": "nowrap"})
        self.assertIn("White_Space => Set (WS_Nowrap)", ada)

    def test_text_overflow(self):
        ada = self._gen({"text-overflow": "ellipsis"})
        self.assertIn("Text_Overflow => Set (Overflow_Ellipsis)", ada)

    def test_line_height_number(self):
        ada = self._gen({"line-height": "1.5"})
        self.assertIn("Line_Height => Set (Line_Height (1.5))", ada)

    def test_line_height_normal(self):
        ada = self._gen({"line-height": "normal"})
        self.assertIn("Line_Height => Set (Normal_Line_Height)", ada)

    # -- Layout --

    def test_display(self):
        for css, ada_val in [("flex", "Flex"), ("grid", "Grid"),
                             ("none", "Display_None"), ("block", "Block"),
                             ("inline-flex", "Inline_Flex")]:
            ada = self._gen({"display": css})
            self.assertIn(f"Display => Set ({ada_val})", ada, f"display: {css}")

    def test_position(self):
        ada = self._gen({"position": "absolute"})
        self.assertIn("Position => Set (Absolute)", ada)

    def test_overflow(self):
        ada = self._gen({"overflow": "hidden"})
        self.assertIn("Overflow => Set (Overflow_Hidden)", ada)

    def test_visibility(self):
        ada = self._gen({"visibility": "hidden"})
        self.assertIn("Visibility => Set (Visibility_Hidden)", ada)

    # -- Flexbox --

    def test_flex_direction(self):
        ada = self._gen({"flex-direction": "column"})
        self.assertIn("Flex_Direction => Set (Column)", ada)

    def test_flex_wrap(self):
        ada = self._gen({"flex-wrap": "wrap"})
        self.assertIn("Flex_Wrap => Set (Wrap)", ada)

    def test_justify_content(self):
        ada = self._gen({"justify-content": "space-between"})
        self.assertIn("Justify_Content => Set (Space_Between)", ada)

    def test_align_items(self):
        ada = self._gen({"align-items": "center"})
        self.assertIn("Align_Items => Set (Center)", ada)

    def test_align_self(self):
        ada = self._gen({"align-self": "stretch"})
        self.assertIn("Align_Self => Set (Stretch)", ada)

    def test_align_content(self):
        ada = self._gen({"align-content": "space-around"})
        self.assertIn("Align_Content => Set (Space_Around)", ada)

    def test_gap_uniform(self):
        ada = self._gen({"gap": "10px"})
        self.assertIn("Gap => Set (Gap (Px (10.0)))", ada)

    def test_gap_two_value(self):
        ada = self._gen({"gap": "5px 10px"})
        self.assertIn("Gap => Set (Gap (Px (5.0), Px (10.0)))", ada)

    def test_flex_grow(self):
        ada = self._gen({"flex-grow": "2"})
        self.assertIn("Flex_Grow => Set (2.0)", ada)

    def test_flex_shrink(self):
        ada = self._gen({"flex-shrink": "0"})
        self.assertIn("Flex_Shrink => Set (0.0)", ada)

    def test_flex_basis(self):
        ada = self._gen({"flex-basis": "100px"})
        self.assertIn("Flex_Basis => Set (Basis (Px (100.0)))", ada)

    def test_flex_basis_auto(self):
        ada = self._gen({"flex-basis": "auto"})
        self.assertIn("Flex_Basis => Set (Auto_Basis)", ada)

    def test_order(self):
        ada = self._gen({"order": "3"})
        self.assertIn("Order => Set (3)", ada)

    # -- Grid --

    def test_grid_template_columns(self):
        ada = self._gen({"grid-template-columns": "repeat(3, 1fr)"})
        self.assertIn("Grid_Columns => Set (Grid_Columns_Value (3))", ada)
        # Grid_Column_Tracks should carry three fr(1.0) specs
        self.assertIn("Grid_Column_Tracks =>", ada)
        self.assertIn("Count => 3", ada)
        self.assertIn("1 => (Track_Fr, 1.0)", ada)
        self.assertIn("3 => (Track_Fr, 1.0)", ada)

    def test_grid_template_columns_mixed(self):
        ada = self._gen({"grid-template-columns": "auto auto 1fr"})
        self.assertIn("Grid_Columns => Set (Grid_Columns_Value (3))", ada)
        self.assertIn("Grid_Column_Tracks =>", ada)
        self.assertIn("Count => 3", ada)
        self.assertIn("1 => (Track_Auto, 0.0)", ada)
        self.assertIn("2 => (Track_Auto, 0.0)", ada)
        self.assertIn("3 => (Track_Fr, 1.0)", ada)

    def test_grid_template_columns_repeat_mixed(self):
        ada = self._gen({"grid-template-columns": "repeat(2, auto) 1fr"})
        self.assertIn("Grid_Columns => Set (Grid_Columns_Value (3))", ada)
        self.assertIn("Count => 3", ada)
        self.assertIn("1 => (Track_Auto, 0.0)", ada)
        self.assertIn("2 => (Track_Auto, 0.0)", ada)
        self.assertIn("3 => (Track_Fr, 1.0)", ada)

    def test_grid_template_columns_negative_fr_rejected(self):
        # Negative fr values should produce no Grid_Column_Tracks
        ada = self._gen({"grid-template-columns": "-1fr 1fr"})
        self.assertNotIn("Grid_Column_Tracks =>", ada)

    def test_grid_template_columns_negative_px_rejected(self):
        ada = self._gen({"grid-template-columns": "-50px 1fr"})
        self.assertNotIn("Grid_Column_Tracks =>", ada)

    def test_grid_template_rows(self):
        ada = self._gen({"grid-template-rows": "1fr 1fr"})
        self.assertIn("Grid_Rows => Set (Grid_Rows_Value (2))", ada)

    def test_grid_column(self):
        ada = self._gen({"grid-column": "1 / 3"})
        self.assertIn("Grid_Column => Set (Grid_Column_Value (1))", ada)
        self.assertIn("Grid_Column_Span => Set (Grid_Column_Span_Value (2))", ada)

    def test_grid_row(self):
        ada = self._gen({"grid-row": "span 2"})
        self.assertIn("Grid_Row_Span => Set (Grid_Row_Span_Value (2))", ada)

    # -- Visual --

    def test_opacity(self):
        ada = self._gen({"opacity": "0.75"})
        self.assertIn("Opacity => Set (0.75)", ada)

    def test_cursor(self):
        ada = self._gen({"cursor": "pointer"})
        self.assertIn("Cursor => Set (Cursor_Pointer)", ada)

    def test_object_fit(self):
        ada = self._gen({"object-fit": "cover"})
        self.assertIn("Object_Fit => Set (Fit_Cover)", ada)

    def test_box_shadow(self):
        ada = self._gen({"box-shadow": "2px 4px 6px rgba(0, 0, 0, 0.3)"})
        self.assertIn("Box_Shadow => Set (Shadow (", ada)

    def test_box_shadow_none(self):
        ada = self._gen({"box-shadow": "none"})
        self.assertIn("Box_Shadow => Set (No_Shadow)", ada)

    # -- Transition --

    def test_transition(self):
        ada = self._gen({"transition": "background-color 0.3s ease-in-out"})
        self.assertIn("Transition => Set (", ada)
        self.assertIn("Prop_Background_Color", ada)
        self.assertIn("Ease_In_Out", ada)

    # -- Outline --

    def test_outline_width(self):
        ada = self._gen({"outline-width": "3px"})
        self.assertIn("Outline_Width => Set_Outline_Width (Px (3.0))", ada)

    def test_outline_color(self):
        ada = self._gen({"outline-color": "rgb(100, 200, 50)"})
        self.assertIn("Outline_Color => Set_Outline_Color (RGB (100, 200, 50))", ada)

    def test_outline_style(self):
        for css_val, ada_val in OUTLINE_STYLE_MAP.items():
            ada = self._gen({"outline-style": css_val})
            self.assertIn(f"Outline_Style => Set ({ada_val})", ada, f"outline-style: {css_val}")

    def test_outline_offset(self):
        ada = self._gen({"outline-offset": "2px"})
        self.assertIn("Outline_Offset => Set_Outline_Offset (Px (2.0))", ada)

    def test_outline_shorthand(self):
        ada = self._gen({"outline": "2px solid rgb(208, 188, 255)"})
        self.assertIn("Outline_Width => Set_Outline_Width (Px (2.0))", ada)
        self.assertIn("Outline_Style => Set (Outline_Solid)", ada)
        self.assertIn("Outline_Color => Set_Outline_Color (RGB (208, 188, 255))", ada)

    def test_outline_shorthand_named_color(self):
        ada = self._gen({"outline": "1px dashed red"})
        self.assertIn("Outline_Width => Set_Outline_Width (Px (1.0))", ada)
        self.assertIn("Outline_Style => Set (Outline_Dashed)", ada)
        self.assertIn("Outline_Color => Set_Outline_Color (C (Red))", ada)

    def test_outline_none(self):
        ada = self._gen({"outline": "none"})
        self.assertIn("Outline_Style => Set (Outline_None)", ada)

    # -- List style --

    def test_list_style_type(self):
        ada = self._gen({"list-style-type": "disc"})
        self.assertIn("List_Style_Type => Set ((Kind => List_Style_Disc))", ada)

    def test_list_style_image(self):
        ada = self._gen({"list-style-image": "url(marker.svg)"})
        self.assertIn('List_Style_Image => Set (List_Image ("marker.svg"))', ada)

    def test_list_style_position(self):
        ada = self._gen({"list-style-position": "inside"})
        self.assertIn("List_Style_Position => Set (List_Inside)", ada)

    def test_list_style_shorthand(self):
        ada = self._gen({"list-style": "square outside"})
        self.assertIn("List_Style_Type => Set ((Kind => List_Style_Square))", ada)
        self.assertIn("List_Style_Position => Set (List_Outside)", ada)


class TestGenerateAdaPackage(unittest.TestCase):
    """Integration test: full CSS -> Ada package generation."""

    def test_basic_package(self):
        rules = parse_css(".card { background-color: rgb(10, 20, 30); padding: 8px; }")
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Test_Styles")
        self.assertIn("package Test_Styles is", ada)
        self.assertIn("end Test_Styles;", ada)
        self.assertIn("Card_Class_Base_Style", ada)
        self.assertIn("Card_Class_Widget", ada)
        self.assertIn("Card_Class_Part_Styles", ada)
        self.assertIn("RGB (10, 20, 30)", ada)

    def test_state_styles(self):
        css = ".btn { color: white; } .btn:hover { color: red; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Btn_Styles")
        self.assertIn("Btn_Class_Base_Style", ada)
        self.assertIn("Widget_Hovered", ada)
        self.assertIn("When_State (State_Hovered)", ada)

    def test_part_styles(self):
        css = ".w::main { padding: 4px; } .w::label { color: white; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "W_Styles")
        self.assertIn("W_Class_Base_Style", ada)
        self.assertIn("W_Class_Label_Base_Style", ada)
        self.assertIn("Label_Part =>", ada)

    def test_id_selector(self):
        css = "#submit { color: blue; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Id_Styles")
        self.assertIn("Submit_Id_Base_Style", ada)

    def test_tag_selector(self):
        css = "button { color: green; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Tag_Styles")
        self.assertIn("Button_Tag_Base_Style", ada)

    def test_outline_in_package(self):
        css = ".focus { outline: 2px solid rgb(208, 188, 255); outline-offset: 2px; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Outline_Styles")
        self.assertIn("Outline_Width => Set_Outline_Width", ada)
        self.assertIn("Outline_Style => Set (Outline_Solid)", ada)
        self.assertIn("Outline_Color => Set_Outline_Color", ada)
        self.assertIn("Outline_Offset => Set_Outline_Offset", ada)

    def test_comma_selector_creates_separate_groups(self):
        css = ".a, .b { color: red; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        self.assertIn("class:a", groups)
        self.assertIn("class:b", groups)

    def test_merging_base_rules(self):
        css = ".card { color: red; } .card { padding: 4px; color: blue; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Merge_Styles")
        # Should have blue (overridden), not red
        self.assertIn("C (Blue)", ada)
        # Should also have padding
        self.assertIn("Padding => Set (", ada)


class TestGenerateLengthAndColor(unittest.TestCase):
    def test_length(self):
        self.assertEqual(generate_length_ada(ParsedLength(10.0, "Px")), "Px (10.0)")
        self.assertEqual(generate_length_ada(ParsedLength(1.5, "Em")), "Em (1.5)")

    def test_color_named(self):
        self.assertEqual(generate_color_ada(ParsedColor(kind="named", name="Red")), "C (Red)")

    def test_color_rgb(self):
        self.assertEqual(
            generate_color_ada(ParsedColor(kind="rgb", r=10, g=20, b=30)),
            "RGB (10, 20, 30)"
        )

    def test_color_rgba(self):
        self.assertEqual(
            generate_color_ada(ParsedColor(kind="rgba", r=10, g=20, b=30, a=0.5)),
            "RGBA (10, 20, 30, 0.5)"
        )


if __name__ == "__main__":
    unittest.main()
