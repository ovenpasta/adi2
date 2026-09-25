#!/usr/bin/env python3
"""
Test harness for css_to_ada.py

Tests CSS parsing, Ada code generation, property support, shorthand expansion,
selector parsing, and rule merging.

Usage: python tools/test_css_to_ada.py
"""

import sys
import os
import re
import subprocess
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import css_to_ada
from css_spec import (
    COLOR_READING_VALIDATORS,
    SUPPORTED_PARTS,
    all_supported_properties,
    canonical_property_name,
    property_validator,
)
from css_to_ada import (
    parse_length,
    parse_color,
    parse_selector,
    parse_box_values,
    parse_margin_box_values,
    validate_property_value,
    parse_box_shadow,
    parse_transition,
    parse_css,
    parse_css_with_diagnostics,
    parse_stylesheet_with_diagnostics,
    strip_comments,
    parse_grid_tracks,
    parse_grid_placement,
    MAX_GRID_TRACKS,
    parse_list_style_shorthand,
    parse_css_quoted_string,
    parse_css_url_function,
    parse_list_marker_string,
    css_text_fits,
    validate_property_value,
    MAX_CSS_TEXT_LENGTH,
    split_css_whitespace_tokens,
    split_css_comma_tokens,
    parse_linear_gradient,
    generate_gradient_ada,
    group_rules_by_widget,
    generate_style_chain_ada,
    generate_style_chain,
    ChainTooLong,
    MAX_CHAIN_SLOTS,
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
            ("text", "Text_Part"),
            ("cursor", "Cursor_Part"), ("selected", "Selected_Part"),
            ("icon", "Icon_Part"), ("indicator", "Indicator_Part"),
            ("scroll", "Scroll_Part"), ("knob", "Knob_Part"),
            ("items", "Items_Part"),
            ("any", "Any_Part"), ("custom", "Custom_Part"),
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


class TestParseGridTracks(unittest.TestCase):
    """The track grammar, the count it yields, and the cap on the sizes.

    Past MAX_GRID_TRACKS the sizes are dropped and only the count
    survives, so the boundary is walked at the cap and one past it. A
    token the grammar refuses is no track, so it adds to no count.
    """

    def test_repeat(self):
        self.assertEqual(parse_grid_tracks("repeat(3, 1fr)")[0], 3)

    def test_explicit_tracks(self):
        self.assertEqual(parse_grid_tracks("1fr 1fr 1fr")[0], 3)

    def test_none(self):
        self.assertIsNone(parse_grid_tracks("none"))

    def test_number(self):
        self.assertEqual(parse_grid_tracks("4")[0], 4)

    def test_a_token_outside_the_grammar_names_no_track(self):
        for value in ("red blue", "-1fr 1fr", "-50px 1fr", "1fr junk",
                      "repeat(3, garbage)", "repeat(x, 1fr)", "0",
                      "1fr /", "10 20"):
            self.assertIsNone(parse_grid_tracks(value), value)

    def test_repeats_add_up(self):
        #  Two repeats past the cap between them: the sizes go and the
        #  count is the sum, not the first repeat's.
        count, specs = parse_grid_tracks("repeat(10, 1fr) repeat(10, auto)")
        self.assertEqual(count, 20)
        self.assertIsNone(specs)

    def test_the_cap_matches_the_ada_constant(self):
        ads = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "src", "adi-css_styles.ads",
        )
        with open(ads, "r", encoding="utf-8") as f:
            source = f.read()
        match = re.search(
            r"Max_Grid_Tracks\s*:\s*constant\s*:=\s*(\d+)\s*;", source
        )
        self.assertIsNotNone(match, "Max_Grid_Tracks not found in " + ads)
        self.assertEqual(int(match.group(1)), MAX_GRID_TRACKS)

    def _sizes(self, n: int) -> str:
        #  Distinct widths, so keeping the list means keeping the sizes
        #  rather than merely counting them.
        return " ".join(f"{i}px" for i in range(1, n + 1))

    def test_at_the_cap_keeps_the_sizes(self):
        value = self._sizes(MAX_GRID_TRACKS)
        self.assertEqual(
            parse_grid_tracks(value)[1],
            [("px", float(i)) for i in range(1, MAX_GRID_TRACKS + 1)],
        )
        ada = "\n".join(
            generate_style_chain_ada({"grid-template-columns": value}))
        self.assertIn(f"Grid_Columns (Grid_Columns_Value ({MAX_GRID_TRACKS}))",
                      ada)
        self.assertIn(f"Grid_Columns ((Count => {MAX_GRID_TRACKS}, ", ada)
        self.assertIn(f"{MAX_GRID_TRACKS} => (Track_Px, "
                      f"{float(MAX_GRID_TRACKS)})", ada)

    def test_past_the_cap_falls_back_to_the_bare_count(self):
        over = MAX_GRID_TRACKS + 1
        value = self._sizes(over)
        count, specs = parse_grid_tracks(value)
        self.assertIsNone(specs)
        #  The count still parses, and is what the generator emits alone.
        self.assertEqual(count, over)
        ada = "\n".join(
            generate_style_chain_ada({"grid-template-columns": value}))
        self.assertIn(f"Grid_Columns (Grid_Columns_Value ({over}))", ada)
        self.assertNotIn("Count =>", ada)


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


class TestCssTextLimit(unittest.TestCase):
    """Both pipelines drop a declaration past MAX_CSS_TEXT_LENGTH."""

    def _at(self, n: int) -> str:
        return "a" * n

    def test_limit_boundary(self):
        self.assertTrue(css_text_fits(self._at(MAX_CSS_TEXT_LENGTH)))
        self.assertFalse(css_text_fits(self._at(MAX_CSS_TEXT_LENGTH + 1)))

    def test_url_at_limit(self):
        uri = self._at(MAX_CSS_TEXT_LENGTH)
        self.assertEqual(parse_css_url_function(f"url({uri})"), uri)

    def test_url_past_limit(self):
        uri = self._at(MAX_CSS_TEXT_LENGTH + 1)
        self.assertIsNone(parse_css_url_function(f"url({uri})"))

    def test_marker_past_limit(self):
        marker = self._at(MAX_CSS_TEXT_LENGTH + 1)
        self.assertEqual(parse_list_marker_string('"ok"'), "ok")
        self.assertIsNone(parse_list_marker_string(f'"{marker}"'))

    def test_validation_rejects_past_limit(self):
        over = self._at(MAX_CSS_TEXT_LENGTH + 1)
        self.assertFalse(
            validate_property_value("background-image", f"url({over})"))
        self.assertFalse(
            validate_property_value("list-style-image", f"url({over})"))
        self.assertFalse(
            validate_property_value("list-style-type", f'"{over}"'))
        self.assertFalse(validate_property_value("font-family", over))

    def test_validation_accepts_at_limit(self):
        at = self._at(MAX_CSS_TEXT_LENGTH)
        self.assertTrue(
            validate_property_value("background-image", f"url({at})"))
        self.assertTrue(
            validate_property_value("list-style-image", f"url({at})"))
        self.assertTrue(
            validate_property_value("list-style-type", f'"{at}"'))
        self.assertTrue(validate_property_value("font-family", at))

    def test_generation_drops_past_limit(self):
        over = self._at(MAX_CSS_TEXT_LENGTH + 1)
        for prop, value in (
            ("background-image", f"url({over})"),
            ("list-style-image", f"url({over})"),
            ("list-style-type", f'"{over}"'),
            ("font-family", over),
        ):
            ada = "\n".join(generate_style_chain_ada({prop: value}))
            self.assertNotIn(over, ada, prop)

    def test_the_limit_matches_the_ada_constant(self):
        ads = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "src", "adi-css_styles.ads",
        )
        with open(ads, "r", encoding="utf-8") as f:
            source = f.read()
        match = re.search(
            r"Max_CSS_Text_Length\s*:\s*constant\s*:=\s*(\d+)\s*;", source
        )
        self.assertIsNotNone(match, "Max_CSS_Text_Length not found in " + ads)
        self.assertEqual(int(match.group(1)), MAX_CSS_TEXT_LENGTH)


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

    def test_a_comment_between_names_keeps_them_apart(self):
        rules = parse_css(
            ".a { font-family: Open/**/Sans, serif; margin: 1px/**/2px; }"
            ".b { margin: 0/**/.5em; }")
        self.assertEqual(rules[0].properties["font-family"], "Open Sans, serif")
        self.assertEqual(rules[0].properties["margin"], "1px 2px")
        self.assertEqual(rules[1].properties["margin"], "0 .5em")

    def test_comment_markers_in_a_url_stay_in_the_path(self):
        rules = parse_css(
            '.a { background-image: url("img/a/*keep*/b.png"); }')
        ada = generate_ada_package(group_rules_by_widget(rules), "Test_Styles")
        self.assertIn('Background_Image_URL ("img/a/*keep*/b.png")', ada)

    def test_state_rule(self):
        rules = parse_css(".btn:hover { background-color: blue; }")
        self.assertEqual(len(rules), 1)
        self.assertIn(WidgetState.HOVERED, rules[0].selector.widget_states)

    def test_part_rule(self):
        rules = parse_css(".btn::label { color: white; }")
        self.assertEqual(len(rules), 1)
        self.assertEqual(rules[0].selector.part_kind, "Label_Part")

    def test_diagnostic_unknown_property(self):
        _rules, diags = parse_css_with_diagnostics(".x { totally-unknown: 7; }")
        self.assertTrue(any(d.code == "unsupported-property" for d in diags))

    def test_diagnostic_invalid_value(self):
        _rules, diags = parse_css_with_diagnostics(".x { color: notacolor; }")
        self.assertTrue(any(d.code == "invalid-property-value" for d in diags))

    def test_diagnostic_unknown_part(self):
        rules, diags = parse_css_with_diagnostics(".x::nope { color: red; }")
        self.assertEqual(len(rules), 0)
        self.assertTrue(any(d.code == "unsupported-part" for d in diags))

    def test_overflow_axis_properties_preserve_order(self):
        rules, diags = parse_css_with_diagnostics(
            ".x { overflow: hidden; overflow-y: auto; overflow-x: scroll; }"
        )
        self.assertEqual(len(diags), 0)
        self.assertEqual(len(rules), 1)
        self.assertIn("overflow", rules[0].properties)
        self.assertIn("overflow-x", rules[0].properties)
        self.assertIn("overflow-y", rules[0].properties)
        self.assertEqual(rules[0].properties["overflow"], "hidden")
        self.assertEqual(rules[0].properties["overflow-x"], "scroll")
        self.assertEqual(rules[0].properties["overflow-y"], "auto")

    def test_overflow_axis_properties_shorthand_last(self):
        rules, diags = parse_css_with_diagnostics(
            ".x { overflow-y: auto; overflow: hidden; }"
        )
        self.assertEqual(len(diags), 0)
        self.assertEqual(len(rules), 1)
        self.assertEqual(list(rules[0].properties.keys()), ["overflow-y", "overflow"])

    def test_border_longhands_are_in_spec(self):
        rules, diags = parse_css_with_diagnostics(
            ".x { border-top: 2px solid red; border-top-left-radius: 4px; }"
        )
        self.assertEqual(len(rules), 1)
        self.assertEqual(len(diags), 0)


class TestStripComments(unittest.TestCase):
    """The cases css_parser_test puts to Adi.CSS_Parser.Strip_Comments."""

    def check(self, css, expected):
        self.assertEqual(strip_comments(css), expected, repr(css))

    def test_comments_go(self):
        self.check("a /* c */ b", "a  b")
        self.check("/* a */ /* b */c", " c")
        self.check("/*/ still */x", "x")

    def test_a_comment_between_names_leaves_a_space(self):
        self.check("1px/**/2px", "1px 2px")
        self.check("Open/* a */Sans", "Open Sans")
        self.check("a/**//* b */c", "a c")
        self.check("a/**/\\31", "a \\31")
        self.check("\u00e9/**/\u00e9", "\u00e9 \u00e9")
        self.check("a/**/url(x/*k*/)", "a url(x/*k*/)")
        self.check("1px/**/-2px", "1px -2px")
        self.check("a_/**/_b", "a_ _b")
        self.check("0/**/.5em", "0 .5em")
        self.check("1px/**/+2px", "1px +2px")
        self.check("1px/**/+.5px", "1px +.5px")

    def test_a_comment_elsewhere_leaves_nothing(self):
        self.check(".a/**/.b/**/:hover", ".a.b:hover")
        self.check("a/**/ /**/b", "a b")
        self.check('a/**/"s"', 'a"s"')
        self.check("/**/a/**/", "a")
        self.check("a/**/+b", "a+b")
        self.check("a/**/+.", "a+.")
        self.check("a/**/.", "a.")

    def test_unterminated_comment_runs_to_the_end(self):
        self.check("a /* open", "a ")
        self.check("a /* open *", "a ")

    def test_strings_keep_comment_markers(self):
        self.check('"a/*b*/c" /* d */', '"a/*b*/c" ')
        self.check("'a/*b*/c' /* d */", "'a/*b*/c' ")
        self.check('"x\\"/*y*/" z', '"x\\"/*y*/" z')

    def test_a_newline_ends_an_unterminated_string(self):
        for newline in ("\n", "\r", "\f"):
            self.check(f'"open{newline}/* c */ ok', f'"open{newline} ok')

    def test_an_escaped_newline_continues_a_string(self):
        for newline in ("\n", "\r\n"):
            self.check(f'"a\\{newline}/*k*/" /* c */',
                       f'"a\\{newline}/*k*/" ')

    def test_unquoted_url_keeps_comment_markers(self):
        self.check("url(img/a/*k*/b.png) /* c */", "url(img/a/*k*/b.png) ")
        self.check("URL( a/*k*/b ) /* c */", "URL( a/*k*/b ) ")
        self.check("url(\\)/*k*/) /* c */", "url(\\)/*k*/) ")

    def test_quoted_url_is_a_string(self):
        self.check('url( "a/*k*/b" ) /* c */', 'url( "a/*k*/b" ) ')
        self.check('url("a)/*k*/") /* c */', 'url("a)/*k*/") ')

    def test_only_url_is_a_url(self):
        self.check("myurl(a/*c*/b)", "myurl(a b)")

    def test_escape_is_not_a_comment_start(self):
        self.check("\\/* x", "\\/* x")


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
        return "\n".join(generate_style_chain_ada(props))

    # -- Color properties --

    def test_color(self):
        ada = self._gen({"color": "red"})
        self.assertIn("Text_Color (C (Red))", ada)

    def test_background_color_rgb(self):
        ada = self._gen({"background-color": "rgb(10, 20, 30)"})
        self.assertIn("Background (RGB (10, 20, 30))", ada)

    def test_background_color_rgba(self):
        ada = self._gen({"background-color": "rgba(10, 20, 30, 0.5)"})
        self.assertIn("RGBA (10, 20, 30, 0.5)", ada)

    def test_background_color_hex(self):
        ada = self._gen({"background-color": "#ff0000"})
        self.assertIn("RGB (255, 0, 0)", ada)

    # -- Box model --

    def test_padding_uniform(self):
        ada = self._gen({"padding": "4px"})
        self.assertIn("Padding (", ada)

    def test_padding_two_value(self):
        ada = self._gen({"padding": "4px 8px"})
        self.assertIn("Padding (", ada)

    def test_padding_four_value(self):
        ada = self._gen({"padding": "1px 2px 3px 4px"})
        self.assertIn("Padding (", ada)

    def test_padding_longhand_override(self):
        ada = self._gen({"padding": "10px", "padding-left": "20px"})
        self.assertIn("Px (20.0)", ada)

    def test_margin(self):
        ada = self._gen({"margin": "5px"})
        self.assertIn("Margin (", ada)

    def test_margin_longhand(self):
        ada = self._gen({"margin": "5px", "margin-top": "9px"})
        self.assertIn("Px (9.0)", ada)

    # -- Border --

    def test_border_width(self):
        ada = self._gen({"border-width": "2px"})
        self.assertIn("Border_Width (Border_Width (Px (2.0)))", ada)

    def test_border_color(self):
        ada = self._gen({"border-color": "red"})
        self.assertIn("Border_Color (Border_Color (C (Red)))", ada)

    def test_border_style(self):
        ada = self._gen({"border-style": "solid"})
        self.assertIn("Border_Style (Border_Style (Solid))", ada)

    def test_border_radius(self):
        ada = self._gen({"border-radius": "8px"})
        self.assertIn("Radius (Radius (Px (8.0)))", ada)

    def test_border_shorthand(self):
        ada = self._gen({"border": "2px solid red"})
        self.assertIn("Border_Width (", ada)
        self.assertIn("Border_Style (", ada)
        self.assertIn("Border_Color (", ada)

    def test_border_side_longhands(self):
        ada = self._gen(
            {
                "border-top-width": "2px",
                "border-left-color": "red",
                "border-bottom-style": "dotted",
            }
        )
        self.assertIn("Border_Width (Top, Px (2.0))", ada)
        self.assertIn("Border_Style (Bottom, Dotted)", ada)
        self.assertIn("Border_Color (Left, C (Red))", ada)

    def test_border_side_shorthand_updates_only_one_side(self):
        ada = self._gen({"border": "1px solid #333", "border-top": "2px dashed red"})
        self.assertIn(
            "Border_Width (Border_Width (Px (2.0), Px (1.0), Px (1.0), Px (1.0)))",
            ada,
        )
        self.assertIn(
            "Border_Style (Border_Style (Dashed, Solid, Solid, Solid))",
            ada,
        )
        self.assertIn(
            "Border_Color (Border_Color (C (Red), RGB (51, 51, 51), RGB (51, 51, 51), RGB (51, 51, 51)))",
            ada,
        )

    def test_border_shorthand_then_side_longhand_override(self):
        ada = self._gen({"border": "1px solid #333", "border-left-width": "4px"})
        self.assertIn(
            "Border_Width (Border_Width (Px (1.0), Px (1.0), Px (1.0), Px (4.0)))",
            ada,
        )

    def test_border_side_longhand_then_shorthand_override(self):
        ada = self._gen({"border-left-width": "4px", "border": "1px solid #333"})
        self.assertIn("Border_Width (Border_Width (Px (1.0)))", ada)
        self.assertNotIn("Px (4.0)", ada)

    def test_border_radius_corner_longhand(self):
        ada = self._gen({"border-radius": "4px", "border-top-left-radius": "9px"})
        self.assertIn(
            "Radius (Radius (Px (9.0), Px (4.0), Px (4.0), Px (4.0)))",
            ada,
        )

    def test_border_radius_shorthand_overrides_corner_longhand(self):
        ada = self._gen({"border-top-left-radius": "9px", "border-radius": "4px"})
        self.assertIn("Radius (Radius (Px (4.0)))", ada)
        self.assertNotIn("Px (9.0)", ada)

    # -- Sizing --

    def test_width(self):
        ada = self._gen({"width": "120px"})
        self.assertIn("Width (Size (Px (120.0)))", ada)

    def test_width_auto(self):
        ada = self._gen({"width": "auto"})
        self.assertIn("Width (Auto_Size)", ada)

    def test_width_min_content(self):
        ada = self._gen({"width": "min-content"})
        self.assertIn("Width (Min_Content_Size)", ada)

    def test_width_max_content(self):
        ada = self._gen({"width": "max-content"})
        self.assertIn("Width (Max_Content_Size)", ada)

    def test_width_fit_content(self):
        ada = self._gen({"width": "fit-content"})
        self.assertIn("Width (Fit_Content_Size)", ada)

    def test_height(self):
        ada = self._gen({"height": "50px"})
        self.assertIn("Height (Size (Px (50.0)))", ada)

    def test_min_width(self):
        ada = self._gen({"min-width": "100px"})
        self.assertIn("Min_Width (", ada)

    def test_max_width(self):
        ada = self._gen({"max-width": "500px"})
        self.assertIn("Max_Width (", ada)

    def test_min_height(self):
        ada = self._gen({"min-height": "40px"})
        self.assertIn("Min_Height (", ada)

    def test_max_height(self):
        ada = self._gen({"max-height": "300px"})
        self.assertIn("Max_Height (", ada)

    # -- Typography --

    def test_font_size(self):
        ada = self._gen({"font-size": "14px"})
        self.assertIn("Font_Size (Px (14.0))", ada)

    def test_font_weight_number(self):
        ada = self._gen({"font-weight": "700"})
        self.assertIn("Font_Weight (Weight_Bold)", ada)

    def test_font_weight_keyword(self):
        ada = self._gen({"font-weight": "bold"})
        self.assertIn("Font_Weight (Weight_Bold)", ada)

    def test_font_style(self):
        ada = self._gen({"font-style": "italic"})
        self.assertIn("Font_Style (Style_Italic)", ada)

    def test_text_align(self):
        ada = self._gen({"text-align": "center"})
        self.assertIn("Text_Align (Text_Center)", ada)

    def test_text_wrap_mode(self):
        ada = self._gen({"text-wrap-mode": "nowrap"})
        self.assertIn("Text_Wrap_Mode (TWM_Nowrap)", ada)

    def test_vertical_align(self):
        ada = self._gen({"vertical-align": "middle"})
        self.assertIn("Vertical_Align (VA_Middle)", ada)

    def test_text_decoration(self):
        ada = self._gen({"text-decoration": "underline"})
        self.assertIn("Text_Decoration (Decoration_Underline)", ada)

    def test_white_space(self):
        ada = self._gen({"white-space": "nowrap"})
        self.assertIn("White_Space (WS_Nowrap)", ada)

    def test_text_overflow(self):
        ada = self._gen({"text-overflow": "ellipsis"})
        self.assertIn("Text_Overflow (Overflow_Ellipsis)", ada)

    def test_line_height_number(self):
        ada = self._gen({"line-height": "1.5"})
        self.assertIn("Line_Height (Line_Height (1.5))", ada)

    def test_line_height_normal(self):
        ada = self._gen({"line-height": "normal"})
        self.assertIn("Line_Height (Normal_Line_Height)", ada)

    # -- Layout --

    def test_display(self):
        for css, ada_val in [("flex", "Flex"), ("grid", "Grid"),
                             ("none", "Display_None"), ("block", "Block"),
                             ("inline-flex", "Inline_Flex")]:
            ada = self._gen({"display": css})
            self.assertIn(f"Display ({ada_val})", ada, f"display: {css}")

    def test_position(self):
        ada = self._gen({"position": "absolute"})
        self.assertIn("Position_Mode (Absolute)", ada)

    def test_overflow(self):
        ada = self._gen({"overflow": "hidden"})
        self.assertIn("Overflow_X (Overflow_Hidden)", ada)
        self.assertIn("Overflow_Y (Overflow_Hidden)", ada)

    def test_overflow_x(self):
        ada = self._gen({"overflow-x": "auto"})
        self.assertIn("Overflow_X (Overflow_Auto)", ada)
        self.assertNotIn("Overflow_Y =>", ada)

    def test_overflow_y(self):
        ada = self._gen({"overflow-y": "scroll"})
        self.assertIn("Overflow_Y (Overflow_Scroll)", ada)
        self.assertNotIn("Overflow_X =>", ada)

    def test_overflow_shorthand_then_longhand(self):
        ada = self._gen({"overflow": "hidden", "overflow-y": "auto"})
        self.assertIn("Overflow_X (Overflow_Hidden)", ada)
        self.assertIn("Overflow_Y (Overflow_Auto)", ada)

    def test_overflow_longhand_then_shorthand(self):
        ada = self._gen({"overflow-y": "auto", "overflow": "hidden"})
        self.assertIn("Overflow_X (Overflow_Hidden)", ada)
        self.assertIn("Overflow_Y (Overflow_Hidden)", ada)

    def test_visibility(self):
        ada = self._gen({"visibility": "hidden"})
        self.assertIn("Visibility (Visibility_Hidden)", ada)

    # -- Flexbox --

    def test_flex_direction(self):
        ada = self._gen({"flex-direction": "column"})
        self.assertIn("Flex_Direction (Column)", ada)

    def test_flex_wrap(self):
        ada = self._gen({"flex-wrap": "wrap"})
        self.assertIn("Flex_Wrap (Wrap)", ada)

    def test_justify_content(self):
        ada = self._gen({"justify-content": "space-between"})
        self.assertIn("Justify_Content (Space_Between)", ada)

    def test_align_items(self):
        ada = self._gen({"align-items": "center"})
        self.assertIn("Align_Items (Center)", ada)

    def test_align_self(self):
        ada = self._gen({"align-self": "stretch"})
        self.assertIn("Align_Self (Stretch)", ada)

    def test_align_content(self):
        ada = self._gen({"align-content": "space-around"})
        self.assertIn("Align_Content (Space_Around)", ada)

    def test_gap_uniform(self):
        ada = self._gen({"gap": "10px"})
        self.assertIn("Gap (Gap (Px (10.0)))", ada)

    def test_gap_two_value(self):
        ada = self._gen({"gap": "5px 10px"})
        self.assertIn("Gap (Gap (Px (5.0), Px (10.0)))", ada)

    def test_row_gap_alone_names_only_the_row_axis(self):
        #  Gap_Row leaves the column axis unnamed so the cascade keeps it.
        ada = self._gen({"row-gap": "4px"})
        self.assertIn("Gap (Gap_Row (Px (4.0)))", ada)

    def test_column_gap_alone_names_only_the_column_axis(self):
        ada = self._gen({"column-gap": "14px"})
        self.assertIn("Gap (Gap_Column (Px (14.0)))", ada)

    def test_row_and_column_gap_combine_into_one_field(self):
        ada = self._gen({"row-gap": "4px", "column-gap": "14px"})
        self.assertIn("Gap (Gap (Px (4.0), Px (14.0)))", ada)
        #  One step carries both axes.
        self.assertEqual(1, len(ada.splitlines()))

    def test_row_gap_overrides_the_shorthand_it_follows(self):
        ada = self._gen({"gap": "10px", "row-gap": "4px"})
        self.assertIn("Gap (Gap (Px (4.0), Px (10.0)))", ada)
        self.assertEqual(1, len(ada.splitlines()))

    def test_flex_grow(self):
        ada = self._gen({"flex-grow": "2"})
        self.assertIn("Flex_Grow (2.0)", ada)

    def test_negative_flex_factors_are_dropped(self):
        # Invalid per CSS, and Flex_Grow_Value/Flex_Shrink_Value start at
        # zero, so emitting one produces Ada the compiler rejects.
        ada = self._gen({"flex-grow": "-1", "flex-shrink": "-2"})
        self.assertNotIn("Flex_Grow", ada)
        self.assertNotIn("Flex_Shrink", ada)

    def test_out_of_range_opacity_is_clamped(self):
        # Opacity is defined over every number and clamped to 0 .. 1,
        # which is also the range Opacity_Value can hold.
        self.assertIn("Opacity (1.0)", self._gen({"opacity": "2"}))
        self.assertIn("Opacity (0.0)", self._gen({"opacity": "-0.5"}))

    def test_flex_shrink(self):
        ada = self._gen({"flex-shrink": "0"})
        self.assertIn("Flex_Shrink (0.0)", ada)

    def test_flex_basis(self):
        ada = self._gen({"flex-basis": "100px"})
        self.assertIn("Flex_Basis (Basis (Px (100.0)))", ada)

    def test_flex_basis_auto(self):
        ada = self._gen({"flex-basis": "auto"})
        self.assertIn("Flex_Basis (Auto_Basis)", ada)

    def test_order(self):
        ada = self._gen({"order": "3"})
        self.assertIn("Order (3)", ada)

    # -- Grid --

    def test_grid_template_columns(self):
        ada = self._gen({"grid-template-columns": "repeat(3, 1fr)"})
        self.assertIn("Grid_Columns (Grid_Columns_Value (3))", ada)
        # Grid_Column_Tracks should carry three fr(1.0) specs
        self.assertIn("Grid_Columns ((Count =>", ada)
        self.assertIn("Count => 3", ada)
        self.assertIn("1 => (Track_Fr, 1.0)", ada)
        self.assertIn("3 => (Track_Fr, 1.0)", ada)

    def test_grid_template_columns_mixed(self):
        ada = self._gen({"grid-template-columns": "auto auto 1fr"})
        self.assertIn("Grid_Columns (Grid_Columns_Value (3))", ada)
        self.assertIn("Grid_Columns ((Count =>", ada)
        self.assertIn("Count => 3", ada)
        self.assertIn("1 => (Track_Auto, 0.0)", ada)
        self.assertIn("2 => (Track_Auto, 0.0)", ada)
        self.assertIn("3 => (Track_Fr, 1.0)", ada)

    def test_grid_template_columns_repeat_mixed(self):
        ada = self._gen({"grid-template-columns": "repeat(2, auto) 1fr"})
        self.assertIn("Grid_Columns (Grid_Columns_Value (3))", ada)
        self.assertIn("Count => 3", ada)
        self.assertIn("1 => (Track_Auto, 0.0)", ada)
        self.assertIn("2 => (Track_Auto, 0.0)", ada)
        self.assertIn("3 => (Track_Fr, 1.0)", ada)

    # A negative size names no track, so the value is one the property
    # can hold none of and the whole declaration goes: neither the list
    # nor a count of the tokens reaches the chain. Adi.CSS_Parser
    # answers the same value with Bad_Value.
    def test_grid_template_columns_negative_fr_rejected(self):
        self.assertFalse(
            validate_property_value("grid-template-columns", "-1fr 1fr"))
        self.assertNotIn(
            "Grid_Columns", self._gen({"grid-template-columns": "-1fr 1fr"}))

    def test_grid_template_columns_negative_px_rejected(self):
        self.assertFalse(
            validate_property_value("grid-template-columns", "-50px 1fr"))
        self.assertNotIn(
            "Grid_Columns", self._gen({"grid-template-columns": "-50px 1fr"}))

    def test_grid_template_columns_none(self):
        #  `none` names both of grid-template-columns' values: a count
        #  of zero, and the list of no tracks that clears the track key
        #  so a rule ahead of it cannot show through. Adi.CSS_Parser
        #  writes the same pair, and tests/src/grid_tracks_test.adb
        #  drives the two over one corpus.
        ada = self._gen({"grid-template-columns": "none"})
        self.assertIn("Grid_Columns (Grid_Columns_Value (0))", ada)
        self.assertIn("Grid_Columns (Default_Grid_Track_List)", ada)
        self.assertNotIn("Count =>", ada)

    def test_grid_template_rows(self):
        ada = self._gen({"grid-template-rows": "1fr 1fr"})
        self.assertIn("Grid_Rows (Grid_Rows_Value (2))", ada)

    def test_grid_template_rows_none(self):
        #  Rows carry a count and no list, so none is that one value at
        #  zero.
        ada = self._gen({"grid-template-rows": "none"})
        self.assertIn("Grid_Rows (Grid_Rows_Value (0))", ada)

    def test_grid_column(self):
        ada = self._gen({"grid-column": "1 / 3"})
        self.assertIn("Grid_Column (Grid_Column_Value (1))", ada)
        self.assertIn("Grid_Column_Span (Grid_Column_Span_Value (2))", ada)

    def test_grid_row(self):
        ada = self._gen({"grid-row": "span 2"})
        self.assertIn("Grid_Row_Span (Grid_Row_Span_Value (2))", ada)

    # -- Visual --

    def test_opacity(self):
        ada = self._gen({"opacity": "0.75"})
        self.assertIn("Opacity (0.75)", ada)

    def test_cursor(self):
        ada = self._gen({"cursor": "pointer"})
        self.assertIn("Cursor_Style (Cursor_Pointer)", ada)

    def test_object_fit(self):
        ada = self._gen({"object-fit": "cover"})
        self.assertIn("Object_Fit (Fit_Cover)", ada)

    def test_object_position_keywords(self):
        ada = self._gen({"object-position": "center center"})
        self.assertIn(
            "Object_Position (Object_Position (Pos_Center, Pos_Center))",
            ada,
        )

    def test_object_position_lengths(self):
        ada = self._gen({"object-position": "10px 20px"})
        self.assertIn(
            "Object_Position (Object_Position (Px (10.0), Px (20.0)))",
            ada,
        )

    def test_box_shadow(self):
        ada = self._gen({"box-shadow": "2px 4px 6px rgba(0, 0, 0, 0.3)"})
        self.assertIn("Box_Shadow (Shadow (", ada)

    def test_box_shadow_none(self):
        ada = self._gen({"box-shadow": "none"})
        self.assertIn("Box_Shadow (No_Shadow)", ada)

    # -- Transition --

    def test_transition(self):
        ada = self._gen({"transition": "background-color 0.3s ease-in-out"})
        self.assertIn("Transition (", ada)
        self.assertIn("Prop_Background_Color", ada)
        self.assertIn("Ease_In_Out", ada)

    # -- Outline --

    def test_outline_width(self):
        ada = self._gen({"outline-width": "3px"})
        self.assertIn("Outline_Width (Px (3.0))", ada)

    def test_outline_color(self):
        ada = self._gen({"outline-color": "rgb(100, 200, 50)"})
        self.assertIn("Outline_Color (RGB (100, 200, 50))", ada)

    def test_outline_style(self):
        for css_val, ada_val in OUTLINE_STYLE_MAP.items():
            ada = self._gen({"outline-style": css_val})
            self.assertIn(f"Outline_Style ({ada_val})", ada, f"outline-style: {css_val}")

    def test_outline_offset(self):
        ada = self._gen({"outline-offset": "2px"})
        self.assertIn("Outline_Offset (Px (2.0))", ada)

    def test_outline_shorthand(self):
        ada = self._gen({"outline": "2px solid rgb(208, 188, 255)"})
        self.assertIn("Outline_Width (Px (2.0))", ada)
        self.assertIn("Outline_Style (Outline_Solid)", ada)
        self.assertIn("Outline_Color (RGB (208, 188, 255))", ada)

    def test_outline_shorthand_named_color(self):
        ada = self._gen({"outline": "1px dashed red"})
        self.assertIn("Outline_Width (Px (1.0))", ada)
        self.assertIn("Outline_Style (Outline_Dashed)", ada)
        self.assertIn("Outline_Color (C (Red))", ada)

    def test_outline_none(self):
        ada = self._gen({"outline": "none"})
        self.assertIn("Outline_Style (Outline_None)", ada)

    # -- List style --

    def test_list_style_type(self):
        ada = self._gen({"list-style-type": "disc"})
        self.assertIn("List_Style_Type (List_Style_Type_Value'(Kind => List_Style_Disc))", ada)

    def test_list_style_image(self):
        ada = self._gen({"list-style-image": "url(marker.svg)"})
        self.assertIn('List_Style_Image (List_Image ("marker.svg"))', ada)

    def test_list_style_position(self):
        ada = self._gen({"list-style-position": "inside"})
        self.assertIn("List_Style_Position (List_Inside)", ada)

    def test_list_style_shorthand(self):
        ada = self._gen({"list-style": "square outside"})
        self.assertIn("List_Style_Type (List_Style_Type_Value'(Kind => List_Style_Square))", ada)
        self.assertIn("List_Style_Position (List_Outside)", ada)

    # -- Font family --

    def test_font_family_single(self):
        ada = self._gen({"font-family": '"MyFont"'})
        self.assertIn('Font_Family ("""MyFont""")', ada)

    def test_font_family_unquoted(self):
        ada = self._gen({"font-family": "sans-serif"})
        self.assertIn('Font_Family ("sans-serif")', ada)

    def test_font_family_comma_list(self):
        ada = self._gen({"font-family": '"A", "B"'})
        self.assertIn('Font_Family ("""A"", ""B""")', ada)


class TestSideLonghandCascade(unittest.TestCase):
    """A rule naming a subset of the sides must emit only those sides, so
    the Ada cascade keeps whatever an earlier rule set for the rest."""

    def _gen(self, props: dict[str, str]) -> str:
        return "\n".join(generate_style_chain_ada(props))

    def test_padding_one_side(self):
        ada = self._gen({"padding-top": "4px"})
        self.assertIn("Padding (Top, Px (4.0))", ada)

    def test_padding_two_sides(self):
        ada = self._gen({"padding-top": "4px", "padding-left": "2px"})
        self.assertIn("Padding (Top, Px (4.0))\nPadding (Left, Px (2.0))", ada)

    def test_padding_shorthand_names_every_side(self):
        ada = self._gen({"padding": "12px"})
        self.assertIn(
            "Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))",
            ada,
        )

    def test_shorthand_then_longhand(self):
        ada = self._gen({"padding": "12px", "padding-top": "4px"})
        self.assertIn(
            "Padding (CSS_Box (Px (4.0), Px (12.0), Px (12.0), Px (12.0)))",
            ada,
        )

    def test_longhand_then_shorthand(self):
        ada = self._gen({"padding-left": "9px", "padding": "3px"})
        self.assertIn(
            "Padding (CSS_Box (Px (3.0), Px (3.0), Px (3.0), Px (3.0)))",
            ada,
        )

    def test_margin_one_side(self):
        ada = self._gen({"margin-bottom": "1px"})
        self.assertIn("Margin (Bottom, Margin (Px (1.0)))", ada)

    def test_border_width_one_side(self):
        ada = self._gen({"border-left-width": "5px"})
        self.assertIn("Border_Width (Left, Px (5.0))", ada)

    def test_border_color_one_side(self):
        ada = self._gen({"border-top-color": "rgb(68, 85, 102)"})
        self.assertIn("Border_Color (Top, RGB (68, 85, 102))", ada)

    def test_border_style_one_side(self):
        ada = self._gen({"border-right-style": "dashed"})
        self.assertIn("Border_Style (Right, Dashed)", ada)

    def test_border_radius_one_corner(self):
        ada = self._gen({"border-bottom-left-radius": "2px"})
        self.assertIn("Radius (Bottom_Left, Px (2.0))", ada)

    def test_border_side_shorthand(self):
        ada = self._gen({"border-top": "4px dashed rgb(10, 11, 12)"})
        self.assertIn("Border_Width (Top, Px (4.0))", ada)
        self.assertIn("Border_Style (Top, Dashed)", ada)
        self.assertIn("Border_Color (Top, RGB (10, 11, 12))", ada)

    def test_border_shorthand_names_every_side(self):
        ada = self._gen({"border": "1px solid rgb(1, 2, 3)"})
        self.assertIn("Border_Width (Border_Width (Px (1.0)))", ada)
        self.assertIn("Border_Style (Border_Style (Solid))", ada)
        self.assertIn("Border_Color (Border_Color (RGB (1, 2, 3)))", ada)

    def test_border_shorthand_then_side_shorthand(self):
        ada = self._gen(
            {"border": "1px solid rgb(1, 2, 3)", "border-top": "4px dashed"}
        )
        self.assertIn(
            "Border_Width (Border_Width (Px (4.0), Px (1.0), Px (1.0), Px (1.0)))",
            ada,
        )
        self.assertIn(
            "Border_Style (Border_Style (Dashed, Solid, Solid, Solid))", ada
        )
        self.assertIn("Border_Color (Border_Color (RGB (1, 2, 3)))", ada)


class TestAutoMargins(unittest.TestCase):
    """`auto` is valid for margin and for nothing else in the box model.

    The emitted Ada has to match what Adi.CSS_Parser builds at run time, or
    a stylesheet lays out differently depending on which pipeline read it.
    """

    def _gen(self, props: dict[str, str]) -> str:
        return "\n".join(generate_style_chain_ada(props))

    def test_centring_shorthand(self):
        ada = self._gen({"margin": "0 auto"})
        self.assertIn(
            "Margin (Top, Margin (Px (0.0)))\n"
            "Margin (Right, Auto_Margin)\n"
            "Margin (Bottom, Margin (Px (0.0)))\n"
            "Margin (Left, Auto_Margin)",
            ada,
        )

    def test_all_sides_auto(self):
        ada = self._gen({"margin": "auto"})
        self.assertEqual(ada.count(", Auto_Margin)"), 4)

    def test_three_value_shorthand(self):
        # top / horizontal / bottom -- the middle token names both sides.
        ada = self._gen({"margin": "5px auto 12px"})
        self.assertIn("Margin (Top, Margin (Px (5.0)))", ada)
        self.assertIn("Margin (Right, Auto_Margin)", ada)
        self.assertIn("Margin (Bottom, Margin (Px (12.0)))", ada)
        self.assertIn("Margin (Left, Auto_Margin)", ada)

    def test_auto_longhand_names_only_its_side(self):
        ada = self._gen({"margin-left": "auto"})
        self.assertIn("Margin (Left, Auto_Margin)", ada)
        self.assertEqual(1, ada.count("Margin ("))

    def test_auto_longhand_over_shorthand(self):
        ada = self._gen({"margin": "6px", "margin-right": "auto"})
        self.assertIn("Margin (Right, Auto_Margin)", ada)
        self.assertIn("Margin (Top, Margin (Px (6.0)))", ada)

    def test_length_longhand_over_auto_shorthand(self):
        ada = self._gen({"margin": "auto", "margin-top": "9px"})
        self.assertIn("Margin (Top, Margin (Px (9.0)))", ada)
        self.assertEqual(ada.count(", Auto_Margin)"), 3)

    def test_all_length_shorthand_stays_compact(self):
        # No auto anywhere: keep emitting the CSS_Box form.
        ada = self._gen({"margin": "4px"})
        self.assertIn(
            "Margin (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0)))",
            ada,
        )

    def test_padding_auto_is_dropped(self):
        self.assertNotIn("Padding", self._gen({"padding": "auto"}))

    def test_padding_side_auto_is_dropped(self):
        self.assertNotIn("Padding", self._gen({"padding-left": "auto"}))

    def test_border_width_auto_is_dropped(self):
        self.assertNotIn("Border_Width", self._gen({"border-width": "auto"}))

    def test_invalid_auto_leaves_valid_siblings_alone(self):
        ada = self._gen({"padding": "auto", "padding-top": "3px"})
        self.assertIn("Padding (Top, Px (3.0))", ada)


class TestAutoMarginValidation(unittest.TestCase):
    """The spec validator gates which properties accept `auto`."""

    def test_margin_accepts_auto(self):
        for value in ("auto", "0 auto", "5px auto 12px", "auto auto auto auto"):
            self.assertTrue(
                validate_property_value("margin", value), f"margin: {value}"
            )

    def test_margin_longhands_accept_auto(self):
        for prop in ("margin-top", "margin-right", "margin-bottom", "margin-left"):
            self.assertTrue(validate_property_value(prop, "auto"), prop)

    def test_padding_rejects_auto(self):
        self.assertFalse(validate_property_value("padding", "auto"))
        self.assertFalse(validate_property_value("padding", "0 auto"))
        for prop in (
            "padding-top",
            "padding-right",
            "padding-bottom",
            "padding-left",
        ):
            self.assertFalse(validate_property_value(prop, "auto"), prop)

    def test_border_width_rejects_auto(self):
        self.assertFalse(validate_property_value("border-width", "auto"))
        for prop in (
            "border-top-width",
            "border-right-width",
            "border-bottom-width",
            "border-left-width",
        ):
            self.assertFalse(validate_property_value(prop, "auto"), prop)

    def test_margin_still_rejects_nonsense(self):
        for value in ("banana", "5zz", "0 banana"):
            self.assertFalse(
                validate_property_value("margin", value), f"margin: {value}"
            )


class TestTransitionLists(unittest.TestCase):
    """Comma-separated transitions: first entry times, properties union."""

    def parse(self, value):
        return css_to_ada.parse_transition(value)

    def test_three_properties_all_animate(self):
        t = self.parse("background-color 300ms ease-in-out,"
                       " border-color 300ms ease-in-out,"
                       " box-shadow 300ms ease-in-out")
        self.assertEqual(
            t.property_set,
            "Props (Prop_Background_Color) + Props (Prop_Border_Color)"
            " + Props (Prop_Box_Shadow)")
        self.assertAlmostEqual(t.duration_seconds, 0.3)
        self.assertEqual(t.easing, "Ease_In_Out")

    def test_later_entry_timing_is_ignored(self):
        t = self.parse("border-color 180ms ease-out, box-shadow 500ms linear")
        self.assertAlmostEqual(t.duration_seconds, 0.18)
        self.assertEqual(t.easing, "Ease_Out")
        self.assertEqual(
            t.property_set,
            "Props (Prop_Border_Color) + Props (Prop_Box_Shadow)")

    def test_all_wins_over_named_entries(self):
        t = self.parse("box-shadow 200ms, all 400ms")
        self.assertEqual(t.property_set, "All_Properties")

    def test_duplicate_property_stays_single(self):
        t = self.parse("box-shadow 200ms, box-shadow 200ms")
        self.assertEqual(t.property_set, "Props (Prop_Box_Shadow)")

    def test_single_property_is_unchanged(self):
        t = self.parse("background-color 150ms ease-out")
        self.assertAlmostEqual(t.duration_seconds, 0.15)
        self.assertEqual(t.easing, "Ease_Out")
        self.assertEqual(t.property_set, "Props (Prop_Background_Color)")

    def test_entry_naming_no_property_means_all(self):
        self.assertEqual(self.parse("300ms").property_set, "All_Properties")

    def test_commas_inside_a_timing_function_are_not_entries(self):
        #  cubic-bezier and steps carry their own commas; splitting on those
        #  would read each argument as another transition and widen the
        #  property set to everything.
        t = self.parse("opacity 1s cubic-bezier(0,0,1,1)")
        self.assertEqual(t.property_set, "Props (Prop_Opacity)")
        self.assertAlmostEqual(t.duration_seconds, 1.0)
        t = self.parse("opacity 300ms steps(4, end)")
        self.assertEqual(t.property_set, "Props (Prop_Opacity)")

    def test_background_is_an_alias_for_background_color(self):
        #  The runtime parser accepts it, so the generator must too or the
        #  same sheet resolves differently in static and dynamic mode.
        self.assertEqual(self.parse("background 200ms").property_set,
                         "Props (Prop_Background_Color)")
        self.assertEqual(
            self.parse("border-color 200ms, background 200ms").property_set,
            "Props (Prop_Border_Color) + Props (Prop_Background_Color)")

    def test_empty_entries_are_rejected(self):
        #  The splitter discards empty entries, so these would otherwise be
        #  silently normalised rather than refused.
        for bad in (", opacity 1s", "opacity 1s,",
                    "opacity 1s,,box-shadow 1s"):
            with self.subTest(bad):
                self.assertIsNone(self.parse(bad))

    def test_property_ending_in_s_is_not_read_as_a_duration(self):
        #  border-radius ends in `s`, so a suffix check alone parses
        #  "border-radiu" as a number, fails, and drops the declaration --
        #  which the runtime parser does not do.
        t = self.parse("border-radius 300ms ease-in-out")
        self.assertIsNotNone(t)
        self.assertEqual(t.property_set, "Props (Prop_Border_Radius)")
        self.assertAlmostEqual(t.duration_seconds, 0.3)

    def test_no_duration_in_first_entry_is_rejected(self):
        self.assertIsNone(self.parse("border-color, box-shadow 200ms"))
        self.assertIsNone(self.parse("none"))


class TestChainLength(unittest.TestCase):
    """A chain names at most Max_Chain_Slots properties over all its rules."""

    def _chain(self, count):
        steps = [f"Order ({i})" for i in range(count)]
        return generate_style_chain([(None, None, steps)], "   ", "class 'x'")

    def test_at_the_cap_renders(self):
        lines = self._chain(MAX_CHAIN_SLOTS)
        self.assertEqual(lines[0], "     Style_Of")
        self.assertEqual(lines[-1], "     .Build;")

    def test_past_the_cap_is_refused(self):
        with self.assertRaises(ChainTooLong) as caught:
            self._chain(MAX_CHAIN_SLOTS + 1)
        self.assertIn("class 'x'", str(caught.exception))

    def test_state_rules_count_toward_the_cap(self):
        half = MAX_CHAIN_SLOTS // 2 + 1
        with self.assertRaises(ChainTooLong):
            generate_style_chain(
                [(None, None, [f"Order ({i})" for i in range(half)]),
                 ("widget State_Hovered", "When_State (State_Hovered)",
                  [f"Order ({i})" for i in range(half)])],
                "   ", "class 'y'")

    def test_the_cap_matches_the_ada_constant(self):
        ads = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "src", "adi-widget_styles.ads",
        )
        with open(ads, "r", encoding="utf-8") as f:
            source = f.read()
        match = re.search(
            r"Max_Chain_Slots\s*:\s*constant\s*:=\s*(\d+)\s*;", source
        )
        self.assertIsNotNone(match, "Max_Chain_Slots not found in " + ads)
        self.assertEqual(int(match.group(1)), MAX_CHAIN_SLOTS)


class TestGenerateAdaPackage(unittest.TestCase):
    """Integration test: full CSS -> Ada package generation."""

    def test_basic_package(self):
        rules = parse_css(".card { background-color: rgb(10, 20, 30); padding: 8px; }")
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Test_Styles")
        self.assertIn("package Test_Styles is", ada)
        self.assertIn("end Test_Styles;", ada)
        self.assertIn("Card_Class_Widget", ada)
        self.assertIn("Card_Class_Widget", ada)
        self.assertIn("Card_Class_Part_Styles", ada)
        self.assertIn("RGB (10, 20, 30)", ada)

    def test_styles_are_constants_interned_at_elaboration(self):
        #  A Widget_Style is a handle and a Part_Style_Array twelve of
        #  them, so both are library-level constants and the sheet is
        #  interned once, as the package elaborates.
        rules = parse_css(".card { background-color: rgb(10, 20, 30); }")
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Test_Styles")
        self.assertIn("pragma Elaborate_All (Adi.Widget_Styles);", ada)
        self.assertIn("   Card_Class_Widget : constant Widget_Style :=", ada)
        self.assertIn(
            "   Card_Class_Part_Styles : constant Part_Style_Array :=", ada)
        self.assertNotIn("return Widget_Style is", ada)
        self.assertNotIn("return Part_Style_Array is", ada)

    def test_parent_package_renames_the_constants(self):
        rules = parse_css(".card { color: white; }")
        groups = group_rules_by_widget(rules)
        ada = css_to_ada.generate_parent_package(
            groups,
            "Parent_Styles",
            ["Child_Styles"],
            {key: "Child_Styles" for key in groups},
        )
        self.assertIn(
            "   Card_Class_Widget : Widget_Style"
            " renames Child_Styles.Card_Class_Widget;",
            ada,
        )
        self.assertIn(
            "   Card_Class_Part_Styles : Part_Style_Array"
            " renames Child_Styles.Card_Class_Part_Styles;",
            ada,
        )

    def test_state_styles(self):
        css = ".btn { color: white; } .btn:hover { color: red; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Btn_Styles")
        self.assertIn("Btn_Class_Widget", ada)
        self.assertIn(".On (When_State (State_Hovered))", ada)

    def test_part_styles(self):
        css = ".w::main { padding: 4px; } .w::label { color: white; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "W_Styles")
        self.assertIn("W_Class_Widget", ada)
        self.assertIn("W_Class_Label_Widget", ada)
        self.assertIn("Label_Part =>", ada)

    def test_id_selector(self):
        css = "#submit { color: blue; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Id_Styles")
        self.assertIn("Submit_Id_Widget", ada)

    def test_tag_selector(self):
        css = "button { color: green; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Tag_Styles")
        self.assertIn("Button_Tag_Widget", ada)

    def test_package_declares_a_registration_procedure(self):
        groups = group_rules_by_widget(parse_css("button { color: green; }"))
        ada = generate_ada_package(groups, "M_Styles")
        self.assertIn(
            "   procedure Register_Selectors\n"
            "     (S : in out Adi.CSS_Source.Style_Source);",
            ada,
        )

    def test_registration_body_lists_every_kind_in_source_order(self):
        css = (
            "button { color: green; } "
            ".card { color: white; } "
            "#submit { color: blue; }"
        )
        groups = group_rules_by_widget(parse_css(css))
        body = "\n".join(css_to_ada.generate_selector_registration_body(groups))
        for i, entry in enumerate(
            [
                'Adi.CSS_Source.Tag_Entry ("button", Button_Tag_Part_Styles)',
                'Adi.CSS_Source.Class_Entry ("card", Card_Class_Part_Styles)',
                'Adi.CSS_Source.Id_Entry ("submit", Submit_Id_Part_Styles)',
            ],
            start=1,
        ):
            self.assertIn(
                f"   procedure Register_Selectors_{i}\n"
                "     (S : in out Adi.CSS_Source.Style_Source) is\n"
                "   begin\n"
                f"      Adi.CSS_Source.Add_Static_Entry (S, {entry});\n"
                f"   end Register_Selectors_{i};\n"
                f"   pragma No_Inline (Register_Selectors_{i});",
                body,
            )
        self.assertIn(
            "   begin\n"
            "      Register_Selectors_1 (S);\n"
            "      Register_Selectors_2 (S);\n"
            "      Register_Selectors_3 (S);\n"
            "   end Register_Selectors;",
            body,
        )

    def test_only_one_entry_is_ever_live_in_a_frame(self):
        #  A Static_Style_Entry embeds a whole Part_Style_Array (hundreds of
        #  KB) and GNAT gives every one visible in a frame its own slot —
        #  aggregate elements, case alternatives and successive statements
        #  alike. A stylesheet's worth in one frame overflows the 8 MB stack
        #  before the first entry is registered, so each gets its own
        #  procedure and the aggregator only calls them.
        css = " ".join(f".c{i} {{ color: white; }}" for i in range(65))
        groups = group_rules_by_widget(parse_css(css))
        body = "\n".join(css_to_ada.generate_selector_registration_body(groups))
        self.assertEqual(body.count("Add_Static_Entry"), 65)
        for chunk in body.split("procedure Register_Selectors_")[1:]:
            self.assertEqual(chunk.count("Add_Static_Entry"), 1)
        self.assertNotIn("Static_Style_Entry_Array", body)
        #  Optimisation must not merge the frames back together.
        self.assertEqual(body.count("pragma No_Inline"), 65)

    def test_registration_survives_a_sheet_with_no_selectors(self):
        groups = group_rules_by_widget(parse_css(":root { font-size: 16px; }"))
        body = "\n".join(css_to_ada.generate_selector_registration_body(groups))
        self.assertIn(
            "   procedure Register_Selectors\n"
            "     (S : in out Adi.CSS_Source.Style_Source) is\n"
            "      pragma Unreferenced (S);\n"
            "   begin\n"
            "      null;\n"
            "   end Register_Selectors;",
            body,
        )

    def test_outline_in_package(self):
        css = ".focus { outline: 2px solid rgb(208, 188, 255); outline-offset: 2px; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "Outline_Styles")
        self.assertIn("Outline_Width (", ada)
        self.assertIn("Outline_Style (Outline_Solid)", ada)
        self.assertIn("Outline_Color (", ada)
        self.assertIn("Outline_Offset (", ada)

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
        self.assertIn("Padding (", ada)

    def test_overflow_y_in_package(self):
        css = ".card { overflow-y: auto; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "OverflowY_Styles")
        self.assertIn("Overflow_Y (Overflow_Auto)", ada)
        self.assertNotIn("Overflow => Set (Overflow_Auto)", ada)

    def test_object_position_in_package(self):
        css = ".img::icon { object-position: center center; }"
        rules = parse_css(css)
        groups = group_rules_by_widget(rules)
        ada = generate_ada_package(groups, "ObjectPos_Styles")
        self.assertIn(
            "Object_Position (Object_Position (Pos_Center, Pos_Center))",
            ada,
        )


class TestGenerateLengthAndColor(unittest.TestCase):
    def test_length(self):
        self.assertEqual(generate_length_ada(ParsedLength(10.0, "Px")), "Px (10.0)")
        self.assertEqual(generate_length_ada(ParsedLength(1.5, "Em")), "Em (1.5)")

    def test_pix_grid_track_end_to_end(self):
        """A pix track survives into the generated package.

        pix is the one Adi unit no browser reads, so a grammar that
        missed it would leave the track list unspecified and the
        declaration dropped.
        """
        self.assertEqual(
            parse_grid_tracks("40pix 1fr")[1], [("pix", 40.0), ("fr", 1.0)])
        self.assertEqual(
            parse_grid_tracks("repeat(2, 8pix)")[1],
            [("pix", 8.0), ("pix", 8.0)])

        rules = parse_css(".g { grid-template-columns: 40pix 1fr; }")
        ada = generate_ada_package(group_rules_by_widget(rules),
                                   "Pix_Grid_Styles")
        self.assertIn("Track_Pix, 40.0", ada)
        self.assertIn("Track_Fr, 1.0", ada)
        self.assertIn("Grid_Columns_Value (2)", ada)

    def test_pix_unit(self):
        """pix parses as its own unit and is not mistaken for px."""
        self.assertEqual(parse_length("40pix"), ParsedLength(40.0, "Pix"))
        self.assertEqual(parse_length("40px"), ParsedLength(40.0, "Px"))
        self.assertEqual(
            generate_length_ada(ParsedLength(1.0, "Pix")), "Pix (1.0)")

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


class TestStateRuleLimit(unittest.TestCase):
    """A selector may carry Max_Style_Rules state rules and no more."""

    STATES = [
        ":hover", ":focus", ":disabled", ":selected", ":pressed",
        ":hover:focus", ":hover:disabled", ":hover:selected",
        ":hover:pressed", ":focus:disabled", ":focus:selected",
        ":focus:pressed", ":disabled:selected", ":disabled:pressed",
        ":selected:pressed", ":hover:focus:disabled",
        ":hover:focus:selected",
    ]

    def _css(self, count: int, selector: str = ".c") -> str:
        return "\n".join(
            f"{selector}{state} {{ opacity: 0.1; }}"
            for state in self.STATES[:count]
        )

    def test_at_the_cap_is_accepted(self):
        groups = group_rules_by_widget(
            parse_css(self._css(css_to_ada.MAX_STYLE_RULES))
        )
        part = groups["class:c"].parts["Main_Part"]
        self.assertEqual(len(part.state_rules), css_to_ada.MAX_STYLE_RULES)

    def test_past_the_cap_is_refused(self):
        with self.assertRaises(css_to_ada.StyleRuleLimitError) as cm:
            group_rules_by_widget(
                parse_css(self._css(css_to_ada.MAX_STYLE_RULES + 1))
            )
        message = str(cm.exception)
        self.assertIn("class 'c'", message)
        self.assertIn(str(css_to_ada.MAX_STYLE_RULES + 1), message)

    def test_the_cap_names_the_part(self):
        with self.assertRaises(css_to_ada.StyleRuleLimitError) as cm:
            group_rules_by_widget(
                parse_css(self._css(css_to_ada.MAX_STYLE_RULES + 1,
                                    ".c::label"))
            )
        self.assertIn("class 'c'::label", str(cm.exception))

    def test_the_cap_matches_the_ada_constant(self):
        ads = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "src", "adi-widget_styles.ads",
        )
        with open(ads, "r", encoding="utf-8") as f:
            source = f.read()
        match = re.search(
            r"Max_Style_Rules\s*:\s*constant\s*:=\s*(\d+)\s*;", source
        )
        self.assertIsNotNone(match, "Max_Style_Rules not found in " + ads)
        self.assertEqual(int(match.group(1)), css_to_ada.MAX_STYLE_RULES)

    def test_cli_fails_naming_the_selector(self):
        tools_dir = os.path.dirname(os.path.abspath(__file__))
        script = os.path.join(tools_dir, "css_to_ada.py")
        with tempfile.TemporaryDirectory() as td:
            input_path = os.path.join(td, "in.css")
            output_path = os.path.join(td, "out.ads")
            with open(input_path, "w", encoding="utf-8") as f:
                f.write(self._css(css_to_ada.MAX_STYLE_RULES + 1))
            proc = subprocess.run(
                [sys.executable, script, input_path, output_path,
                 "--package-name", "Tmp_Styles"],
                capture_output=True, text=True,
            )
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("class 'c'", proc.stderr)
            self.assertFalse(os.path.exists(output_path))


class TestCliStrictMode(unittest.TestCase):
    def _run(self, css: str, *extra_args: str):
        tools_dir = os.path.dirname(os.path.abspath(__file__))
        script = os.path.join(tools_dir, "css_to_ada.py")
        with tempfile.TemporaryDirectory() as td:
            input_path = os.path.join(td, "in.css")
            output_path = os.path.join(td, "out.ads")
            with open(input_path, "w", encoding="utf-8") as f:
                f.write(css)
            cmd = [
                sys.executable,
                script,
                input_path,
                output_path,
                "--package-name",
                "Tmp_Styles",
                *extra_args,
            ]
            proc = subprocess.run(cmd, capture_output=True, text=True)
            output_exists = os.path.exists(output_path)
            output_text = ""
            if output_exists:
                with open(output_path, "r", encoding="utf-8") as f:
                    output_text = f.read()
            return proc, output_exists, output_text

    def test_non_strict_warns_and_generates(self):
        proc, output_exists, _ = self._run(".x { unknown-prop: 1; color: red; }")
        self.assertEqual(proc.returncode, 0)
        self.assertIn("warning:", proc.stderr)
        self.assertTrue(output_exists)

    def test_strict_fails_without_output_on_unknown_property(self):
        proc, output_exists, _ = self._run(
            ".x { unknown-prop: 1; color: red; }",
            "--strict",
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("warning:", proc.stderr)
        self.assertFalse(output_exists)

    def test_strict_fails_on_invalid_value(self):
        proc, output_exists, _ = self._run(
            ".x { color: notacolor; }",
            "--strict",
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("invalid-property-value", proc.stderr)
        self.assertFalse(output_exists)

    def test_strict_fails_on_unknown_part(self):
        proc, output_exists, _ = self._run(
            ".x::unknown { color: red; }",
            "--strict",
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("unsupported-part", proc.stderr)
        self.assertFalse(output_exists)

    def test_strict_passes_on_valid_css(self):
        proc, output_exists, output_text = self._run(
            ".x { color: red; overflow-y: auto; }",
            "--strict",
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stderr.strip(), "")
        self.assertTrue(output_exists)
        self.assertIn("Overflow_Y (Overflow_Auto)", output_text)

    def test_strict_passes_font_family_quoted(self):
        proc, output_exists, output_text = self._run(
            '.x { font-family: "Open Sans"; }',
            "--strict",
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stderr.strip(), "")
        self.assertTrue(output_exists)
        self.assertIn("Font_Family (", output_text)

    def test_strict_passes_font_family_comma_list(self):
        proc, output_exists, _ = self._run(
            '.x { font-family: "My Font", sans-serif; }',
            "--strict",
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue(output_exists)

    def test_strict_passes_font_family_unquoted(self):
        proc, output_exists, _ = self._run(
            ".x { font-family: monospace; }",
            "--strict",
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue(output_exists)

    def test_strict_fails_font_family_empty(self):
        proc, output_exists, _ = self._run(
            ".x { font-family: ; }",
            "--strict",
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertFalse(output_exists)

    def test_strict_fails_font_family_leading_digit(self):
        proc, output_exists, _ = self._run(
            ".x { font-family: 123abc; }",
            "--strict",
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertFalse(output_exists)


class TestCustomProperties(unittest.TestCase):
    """Tests for @property, :root, var() preprocessing."""

    def test_at_property_default(self):
        css = '@property --c { initial-value: red; } .x { color: var(--c); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(len(rules), 1)
        self.assertEqual(rules[0].properties.get("color"), "red")

    def test_root_overrides_at_property(self):
        css = (
            '@property --c { initial-value: red; } '
            ':root { --c: blue; } '
            '.x { color: var(--c); }'
        )
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "blue")

    def test_var_with_fallback(self):
        css = '.x { color: var(--missing, green); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "green")

    def test_var_no_fallback_unresolved(self):
        css = '.x { color: var(--missing); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "var(--missing)")
        codes = [d.code for d in diags]
        self.assertIn("unresolved-variable", codes)

    def test_nested_fallback_parens(self):
        css = ':root { --c: #ff0000; } .x { color: var(--c, rgb(0, 0, 0)); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "#ff0000")

    def test_fallback_with_function(self):
        css = '.x { color: var(--missing, rgb(10, 20, 30)); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "rgb(10, 20, 30)")

    def test_nested_var_in_fallback(self):
        css = ':root { --b: blue; } .x { color: var(--a, var(--b)); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "blue")

    def test_recursive_var(self):
        css = ':root { --a: var(--b); --b: green; } .x { color: var(--a); }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "green")

    def test_cyclic_var_bounded(self):
        css = ':root { --a: var(--b); --b: var(--a); } .x { color: var(--a); }'
        rules, diags = parse_css_with_diagnostics(css)
        # Should not crash; either resolve or leave unresolved with diagnostic
        self.assertEqual(len(rules), 1)

    def test_root_normal_props_become_metadata(self):
        css = ':root { color: red; --c: blue; } .x { color: var(--c); }'
        stylesheet, diags = parse_stylesheet_with_diagnostics(css)
        self.assertEqual(stylesheet.rules[0].properties.get("color"), "blue")
        self.assertEqual(stylesheet.root_properties.get("color"), "red")
        codes = [d.code for d in diags]
        self.assertNotIn("root-normal-property-ignored", codes)

    def test_non_root_custom_prop_ignored(self):
        css = '.x { --local: red; color: blue; }'
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("color"), "blue")
        codes = [d.code for d in diags]
        self.assertIn("non-root-custom-property-ignored", codes)

    def test_multiple_var_in_one_decl(self):
        css = (
            ':root { --x: 4px; --y: 8px; } '
            '.x { padding: var(--x) var(--y); }'
        )
        rules, diags = parse_css_with_diagnostics(css)
        self.assertEqual(rules[0].properties.get("padding"), "4px 8px")

    def test_no_root_selector_leak(self):
        """Ensure :root does not appear as a parsed selector."""
        css = ':root { --c: red; } .x { color: var(--c); }'
        rules, diags = parse_css_with_diagnostics(css)
        selectors = [r.selector.name for r in rules]
        self.assertNotIn("root", selectors)
        self.assertNotIn(":root", selectors)

    def test_at_property_block_removed(self):
        """@property blocks should not produce rules."""
        css = '@property --c { initial-value: red; } .x { color: var(--c); }'
        rules, diags = parse_css_with_diagnostics(css)
        selectors = [r.selector.name for r in rules]
        self.assertEqual(selectors, ["x"])

    def test_generate_root_metadata_and_typed_vars(self):
        css = (
            ':root { font-size: 20dp; color: red; --spacing: 12dp; --accent: blue; } '
            '.x { padding: var(--spacing); color: var(--accent); }'
        )
        stylesheet, diags = parse_stylesheet_with_diagnostics(css)
        groups = group_rules_by_widget(stylesheet.rules)
        ada = generate_ada_package(stylesheet, groups, "Generated_Styles")
        self.assertEqual(diags, [])
        self.assertIn("function Has_Root_Font_Size return Boolean is (True);", ada)
        self.assertIn("function Root_Font_Size return Length_Value is (Dip (20.0));", ada)
        self.assertIn(
            "Root_Part_Styles : constant Part_Style_Array :=", ada)
        self.assertIn("      Root_Styles => Root_Part_Styles,", ada)
        self.assertIn("function Var_Spacing return Length_Value is (Dip (12.0));", ada)
        self.assertIn("function Var_Accent return Color_Value is (C (Blue));", ada)

    def test_generate_string_var_accessor(self):
        css = ':root { --title: "Preferences"; } .x { color: red; }'
        stylesheet, diags = parse_stylesheet_with_diagnostics(css)
        groups = group_rules_by_widget(stylesheet.rules)
        ada = generate_ada_package(stylesheet, groups, "Generated_Styles")
        self.assertEqual(diags, [])
        self.assertIn('function Var_Title return String is ("Preferences");', ada)


class TestParseLinearGradient(unittest.TestCase):
    """Test linear-gradient() parsing and Ada code generation."""

    def test_to_bottom_two_stops(self):
        g = parse_linear_gradient("linear-gradient(to bottom, #fff, #000)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 180.0)
        self.assertEqual(len(g.stops), 2)

    def test_to_right_rgb_stops(self):
        g = parse_linear_gradient(
            "linear-gradient(to right, rgb(255,0,0), rgb(0,0,255))")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 90.0)
        self.assertEqual(len(g.stops), 2)

    def test_angle_deg(self):
        g = parse_linear_gradient("linear-gradient(45deg, red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 45.0)

    def test_default_angle(self):
        g = parse_linear_gradient("linear-gradient(red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 180.0)
        self.assertEqual(len(g.stops), 2)

    def test_three_stops_with_positions(self):
        g = parse_linear_gradient(
            "linear-gradient(to bottom, red 0%, green 50%, blue 100%)")
        self.assertIsNotNone(g)
        self.assertEqual(len(g.stops), 3)
        self.assertAlmostEqual(g.stops[0].position, 0.0)
        self.assertAlmostEqual(g.stops[1].position, 0.5)
        self.assertAlmostEqual(g.stops[2].position, 1.0)

    def test_too_few_stops_returns_none(self):
        g = parse_linear_gradient("linear-gradient(to bottom, red)")
        self.assertIsNone(g)

    def test_not_a_gradient(self):
        self.assertIsNone(parse_linear_gradient("url(foo.png)"))
        self.assertIsNone(parse_linear_gradient("none"))
        self.assertIsNone(parse_linear_gradient(""))

    # --- Multiline (autoformatter) variants ---

    def test_multiline_direction(self):
        g = parse_linear_gradient(
            "linear-gradient(\n        to right,\n        rgb(245, 158, 11),\n        rgb(239, 68, 68)\n    )")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 90.0)
        self.assertEqual(len(g.stops), 2)

    def test_multiline_deg_angle(self):
        g = parse_linear_gradient(
            "linear-gradient(\n        45deg,\n        red,\n        blue\n    )")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 45.0)

    def test_multiline_three_stops_with_positions(self):
        g = parse_linear_gradient(
            "linear-gradient(\n        to right,\n        rgb(59, 130, 246) 0%,\n        rgb(139, 92, 246) 30%,\n        rgb(236, 72, 153) 100%\n    )")
        self.assertIsNotNone(g)
        self.assertEqual(len(g.stops), 3)
        self.assertAlmostEqual(g.stops[0].position, 0.0)
        self.assertAlmostEqual(g.stops[1].position, 0.3)
        self.assertAlmostEqual(g.stops[2].position, 1.0)

    def test_multiline_via_full_css_parse(self):
        """End-to-end: full CSS rule with a multiline gradient value."""
        css = (
            ".pill {\n"
            "    background-image: linear-gradient(\n"
            "        to right,\n"
            "        rgb(245, 158, 11),\n"
            "        rgb(239, 68, 68)\n"
            "    );\n"
            "}\n"
        )
        rules = parse_css(css)
        self.assertEqual(len(rules), 1)
        bg = rules[0].properties.get("background-image", "")
        g = parse_linear_gradient(bg)
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 90.0)
        self.assertEqual(len(g.stops), 2)

    def test_angle_turn(self):
        g = parse_linear_gradient("linear-gradient(1turn, red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 360.0)
        self.assertEqual(len(g.stops), 2)

    def test_angle_half_turn(self):
        g = parse_linear_gradient("linear-gradient(0.5turn, red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 180.0)

    def test_angle_rad(self):
        import math
        g = parse_linear_gradient("linear-gradient(1.5708rad, red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 90.0, places=1)

    def test_angle_grad_100(self):
        g = parse_linear_gradient("linear-gradient(100grad, red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 90.0)

    def test_angle_grad_200_not_rad(self):
        # 200grad = 180°; must not be mis-parsed as "rad" (which would give ~11460°)
        g = parse_linear_gradient("linear-gradient(200grad, red, blue)")
        self.assertIsNotNone(g)
        self.assertAlmostEqual(g.angle, 180.0)


class TestGenerateGradientAda(unittest.TestCase):
    """Test Ada code generation for linear-gradient()."""

    def _gen(self, css_value: str) -> str:
        return "\n".join(generate_style_chain_ada({"background-image": css_value}))

    def test_to_bottom_angle_in_ada(self):
        ada = self._gen("linear-gradient(to bottom, white, black)")
        self.assertIn("180.0", ada)
        self.assertIn("Linear_Gradient", ada)
        self.assertIn("Background_Image (", ada)

    def test_to_right_angle_in_ada(self):
        ada = self._gen("linear-gradient(to right, red, blue)")
        self.assertIn("90.0", ada)

    def test_45deg_angle_in_ada(self):
        ada = self._gen("linear-gradient(45deg, red, blue)")
        self.assertIn("45.0", ada)

    def test_named_colors_in_ada(self):
        ada = self._gen("linear-gradient(to bottom, red, blue)")
        self.assertIn("C (Red)", ada)
        self.assertIn("C (Blue)", ada)

    def test_positioned_stops_in_ada(self):
        ada = self._gen(
            "linear-gradient(to bottom, red 0%, green 50%, blue 100%)")
        self.assertIn("Gradient_Stop_At", ada)
        self.assertIn("0.0", ada)
        self.assertIn("0.5", ada)
        self.assertIn("1.0", ada)

    def test_auto_stops_in_ada(self):
        ada = self._gen("linear-gradient(to bottom, red, blue)")
        self.assertIn("Gradient_Stop_Auto", ada)

    def test_1turn_in_ada(self):
        ada = self._gen("linear-gradient(1turn, red, blue)")
        self.assertIn("360.0", ada)

    def test_half_turn_in_ada(self):
        ada = self._gen("linear-gradient(0.5turn, red, blue)")
        self.assertIn("180.0", ada)

    def test_100grad_in_ada(self):
        ada = self._gen("linear-gradient(100grad, red, blue)")
        self.assertIn("90.0", ada)

    def test_200grad_in_ada(self):
        # 200grad = 180°; must not be mis-parsed as "rad"
        ada = self._gen("linear-gradient(200grad, red, blue)")
        self.assertIn("180.0", ada)

    def test_rad_in_ada(self):
        ada = self._gen("linear-gradient(1.5708rad, red, blue)")
        # π/2 rad ≈ 90°; check the value rounds to 90.0 in Ada output
        self.assertIn("90.0", ada)


class TestWidgetPropertySelectors(unittest.TestCase):
    """[severity] and [severity="critical"], and the constants they emit."""

    def _selector(self, text):
        sel, diags = css_to_ada.parse_selector_with_diagnostics(text)
        return sel, diags

    def test_equality_condition(self):
        sel, diags = self._selector('.alarm[severity="critical"]')
        self.assertEqual(diags, [])
        self.assertEqual(sel.name, "alarm")
        self.assertEqual(sel.selector_type, "class")
        self.assertEqual(len(sel.property_conditions), 1)
        self.assertEqual(sel.property_conditions[0].name, "severity")
        self.assertEqual(sel.property_conditions[0].value, "critical")
        self.assertFalse(sel.property_conditions[0].negated)

    def test_existence_condition(self):
        sel, _ = self._selector(".alarm[severity]")
        self.assertEqual(len(sel.property_conditions), 1)
        self.assertIsNone(sel.property_conditions[0].value)

    def test_negated_equality(self):
        sel, diags = self._selector('.alarm:not([severity="critical"])')
        self.assertEqual(diags, [])
        self.assertEqual(sel.name, "alarm")
        self.assertEqual(len(sel.property_conditions), 1)
        self.assertTrue(sel.property_conditions[0].negated)
        self.assertEqual(sel.property_conditions[0].value, "critical")
        #  The bracket goes with the :not(), so no empty pseudo is left
        #  behind for parse_pseudo_classes to read.
        self.assertEqual(sel.widget_states, [])
        self.assertEqual(sel.widget_negated_states, [])

    def test_negated_existence(self):
        sel, _ = self._selector(".alarm:not([link])")
        self.assertEqual(len(sel.property_conditions), 1)
        self.assertTrue(sel.property_conditions[0].negated)
        self.assertIsNone(sel.property_conditions[0].value)

    def test_a_state_not_is_left_alone(self):
        sel, _ = self._selector(".alarm:not(:hover)")
        self.assertEqual(sel.property_conditions, [])
        self.assertEqual(
            [s.value for s in sel.widget_negated_states], ["State_Hovered"]
        )

    def test_a_negation_beside_a_state(self):
        sel, _ = self._selector('.alarm:hover:not([severity="critical"])')
        self.assertEqual(
            [s.value for s in sel.widget_states], ["State_Hovered"]
        )
        self.assertTrue(sel.property_conditions[0].negated)

    def test_unquoted_and_single_quoted_values(self):
        for text in (".a[severity=critical]", ".a[severity='critical']"):
            sel, _ = self._selector(text)
            self.assertEqual(sel.property_conditions[0].value, "critical")

    def test_case_is_folded(self):
        sel, _ = self._selector('.a[Severity="CRITICAL"]')
        self.assertEqual(sel.property_conditions[0].name, "severity")
        self.assertEqual(sel.property_conditions[0].value, "critical")

    def test_brackets_come_off_before_the_colon_split(self):
        sel, _ = self._selector('.alarm[severity="critical"]:hover::label')
        self.assertEqual(sel.name, "alarm")
        self.assertEqual(sel.part_kind, "Label_Part")
        self.assertEqual(
            [s.value for s in sel.widget_states], ["State_Hovered"]
        )
        self.assertEqual(len(sel.property_conditions), 1)

    def test_conditions_after_a_pseudo_class(self):
        sel, _ = self._selector('.alarm:hover[severity="critical"]')
        self.assertEqual(sel.name, "alarm")
        self.assertEqual(
            [s.value for s in sel.widget_states], ["State_Hovered"]
        )
        self.assertEqual(len(sel.property_conditions), 1)

    def test_two_conditions(self):
        sel, _ = self._selector('.a[link="degraded"][severity="critical"]')
        self.assertEqual(len(sel.property_conditions), 2)

    def test_ordering_operator_is_refused(self):
        sel, diags = self._selector(".a[level>3]")
        self.assertIsNone(sel)
        self.assertEqual([d.code for d in diags], ["attribute-syntax"])

    def test_substring_operators_are_refused(self):
        for text in (".a[x~=y]", ".a[x|=y]", ".a[x^=y]", ".a[x$=y]",
                     ".a[x*=y]", ".a[x!=y]"):
            sel, diags = self._selector(text)
            self.assertIsNone(sel, text)
            self.assertEqual([d.code for d in diags], ["attribute-syntax"])

    def test_unclosed_bracket_is_refused(self):
        sel, diags = self._selector('.a[severity="critical"')
        self.assertIsNone(sel)
        self.assertEqual([d.code for d in diags], ["attribute-syntax"])

    def test_unclosed_negation_is_refused(self):
        sel, diags = self._selector('.a:not([severity="critical"]')
        self.assertIsNone(sel)
        self.assertEqual([d.code for d in diags], ["attribute-syntax"])

    def test_empty_bracket_is_refused(self):
        sel, diags = self._selector(".a[]")
        self.assertIsNone(sel)
        self.assertEqual([d.code for d in diags], ["attribute-syntax"])

    def test_a_condition_makes_the_rule_a_state_rule(self):
        rules = parse_css(
            ".a { color: red; }\n"
            '.a[severity="critical"] { color: blue; }\n'
        )
        groups = group_rules_by_widget(rules)
        part = groups["class:a"].parts["Main_Part"]
        self.assertIsNotNone(part.base_rule)
        self.assertEqual(len(part.state_rules), 1)

    def test_distinct_values_are_distinct_rules(self):
        rules = parse_css(
            '.a[severity="ok"] { color: red; }\n'
            '.a[severity="critical"] { color: blue; }\n'
        )
        groups = group_rules_by_widget(rules)
        self.assertEqual(
            len(groups["class:a"].parts["Main_Part"].state_rules), 2
        )

    def test_a_condition_and_its_negation_are_distinct_rules(self):
        rules = parse_css(
            '.a[severity="ok"] { color: red; }\n'
            '.a:not([severity="ok"]) { color: blue; }\n'
        )
        groups = group_rules_by_widget(rules)
        self.assertEqual(
            len(groups["class:a"].parts["Main_Part"].state_rules), 2
        )

    def _generate(self, css, properties_package="App_Properties"):
        stylesheet, _ = parse_stylesheet_with_diagnostics(css)
        groups = group_rules_by_widget(stylesheet.rules)
        return generate_ada_package(
            stylesheet, groups, "Gen", properties_package
        )

    def test_equality_emits_the_instantiation_and_the_literal(self):
        ada = self._generate('.a[severity="critical"] { color: red; }')
        self.assertIn(
            "When_Property (App_Properties.Severity.Value "
            "(App_Properties.Critical))",
            ada,
        )
        self.assertIn("with App_Properties;", ada)

    def test_existence_emits_the_property_id(self):
        ada = self._generate(".a[severity] { color: red; }")
        self.assertIn("When_Property_Set (App_Properties.Severity.Id)", ada)

    def test_negation_emits_the_negated_call(self):
        ada = self._generate('.a:not([severity="critical"]) { color: red; }')
        self.assertIn(
            "When_Not_Property (App_Properties.Severity.Value "
            "(App_Properties.Critical))",
            ada,
        )

    def test_negated_existence_emits_the_negated_call(self):
        ada = self._generate(".a:not([severity]) { color: red; }")
        self.assertIn(
            "When_Not_Property_Set (App_Properties.Severity.Id)", ada
        )

    def test_two_properties_may_share_a_value_name(self):
        #  The literal is named alone; the instantiation it is handed to
        #  is what resolves which enumeration it belongs to.
        ada = self._generate(
            '.a[power="on"] { color: red; }\n.b[state="on"] { color: blue; }'
        )
        self.assertIn("App_Properties.Power.Value (App_Properties.On)", ada)
        self.assertIn("App_Properties.State.Value (App_Properties.On)", ada)

    def test_a_hyphenated_name_becomes_an_ada_identifier(self):
        ada = self._generate('.a[link-state="half-open"] { color: red; }')
        self.assertIn(
            "App_Properties.Link_State.Value (App_Properties.Half_Open)", ada
        )

    def test_a_sheet_without_conditions_withs_no_properties_package(self):
        ada = self._generate(".a { color: red; }")
        self.assertNotIn("with App_Properties;", ada)

    def test_a_condition_needs_a_properties_package(self):
        with self.assertRaises(css_to_ada.PropertyPackageMissing):
            self._generate(
                '.a[severity="critical"] { color: red; }',
                properties_package=None,
            )


class TestRuntimeParserVocabulary(unittest.TestCase):
    """Decl_Table in src/adi-css_parser.adb, against css_spec."""

    @staticmethod
    def _table():
        adb = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "src", "adi-css_parser.adb",
        )
        with open(adb, "r", encoding="utf-8") as f:
            source = f.read()
        table = re.findall(r'\("([a-z-]+) *", *(D_\w+)\)', source)
        assert table, "Decl_Table not found in " + adb
        return table

    def test_the_parser_carries_what_the_generator_supports(self):
        # Both pipelines resolve the same CSS, so both must name the
        # same properties for a sheet to mean one thing.
        names = [name for name, _ in self._table()]
        self.assertEqual(sorted(names), sorted(all_supported_properties()))

    def test_the_table_is_sorted(self):
        # Decl_Of is a binary search over names padded with spaces, and
        # no name character sorts below a space, so the padded order is
        # the plain one. An entry out of place costs the names it hides.
        names = [name for name, _ in self._table()]
        self.assertEqual(names, sorted(names))

    def test_each_literal_spells_its_name(self):
        for name, literal in self._table():
            expected = "D_" + "_".join(
                word.capitalize() for word in name.split("-"))
            self.assertEqual(literal, expected)

    def test_the_parser_carries_the_same_parts(self):
        # Parse_Part answers a ::part name, and a name it refuses costs
        # the whole rule. SUPPORTED_PARTS is the generator's half.
        adb = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "src", "adi-css_parser.adb",
        )
        with open(adb, "r", encoding="utf-8") as f:
            source = f.read()
        start = source.index("function Parse_Part")
        body = source[start:source.index("end Parse_Part;", start)]
        parts = dict(re.findall(r'V = "([a-z]+)" then P := (\w+);', body))
        self.assertEqual(parts, SUPPORTED_PARTS)


class TestMalformedSelectorDiagnostic(unittest.TestCase):
    """A selector with nothing to name it, reported rather than dropped."""

    @staticmethod
    def _codes(css):
        _, diagnostics = parse_stylesheet_with_diagnostics(css)
        return [d.code for d in diagnostics]

    def test_a_readable_selector_reports_nothing(self):
        self.assertEqual(self._codes(".a { color: red; }"), [])

    def test_a_bare_class_marker_is_reported(self):
        self.assertEqual(self._codes(". { color: red; }"),
                         ["malformed-selector"])

    def test_a_bare_id_marker_is_reported(self):
        self.assertEqual(self._codes("# { color: red; }"),
                         ["malformed-selector"])

    def test_a_part_with_no_widget_is_reported(self):
        self.assertEqual(self._codes("::label { color: red; }"),
                         ["malformed-selector"])

    def test_a_pseudo_class_alone_is_reported(self):
        self.assertEqual(self._codes(":hover { color: red; }"),
                         ["malformed-selector"])

    def test_an_unsupported_part_keeps_its_own_code(self):
        self.assertEqual(self._codes(".a::bogus { color: red; }"),
                         ["unsupported-part"])

    def test_a_pseudo_class_leaves_the_part_to_answer_for(self):
        self.assertEqual(self._codes(".a::bogus:hover { color: red; }"),
                         ["unsupported-part"])

    def test_a_stray_comma_costs_nothing(self):
        # The selectors beside it carry the block, so nothing is lost.
        # Adi.CSS_Parser draws the same line; see
        # Test_Skipped_Selector_Is_Reported.
        for css in [".a, { color: red; }",
                    ", .a { color: red; }",
                    ".a,, .b { color: red; }"]:
            self.assertEqual(self._codes(css), [], css)

    def test_a_block_with_nothing_to_select_is_reported(self):
        self.assertEqual(self._codes("   { color: red; }"),
                         ["malformed-selector"])

    def test_a_trailing_comma_keeps_its_rule(self):
        stylesheet, _ = parse_stylesheet_with_diagnostics(
            ".a, { color: red; }")
        self.assertEqual([r.selector.name for r in stylesheet.rules], ["a"])

    def test_the_rule_beside_it_still_generates(self):
        stylesheet, diagnostics = parse_stylesheet_with_diagnostics(
            ".good { color: red; } . { color: blue; }")
        self.assertEqual([d.code for d in diagnostics],
                         ["malformed-selector"])
        self.assertEqual([r.selector.name for r in stylesheet.rules], ["good"])


class TestGridTemplateNone(unittest.TestCase):
    """none names no explicit track, which is a count of zero."""

    def test_none_is_a_value_both_pipelines_read(self):
        for prop in ("grid-template-columns", "grid-template-rows"):
            self.assertTrue(validate_property_value(prop, "none"), prop)

    def test_none_generates_a_zero_count(self):
        self.assertIn(
            "Grid_Columns (Grid_Columns_Value (0))",
            "\n".join(generate_style_chain_ada(
                {"grid-template-columns": "none"})))
        self.assertIn(
            "Grid_Rows (Grid_Rows_Value (0))",
            "\n".join(generate_style_chain_ada(
                {"grid-template-rows": "none"})))

    def test_a_repeat_with_no_count_stays_rejected(self):
        # The whitespace fallback would otherwise read it as two tracks,
        # where Adi.CSS_Parser stops on the repeat( form itself.
        for prop in ("grid-template-columns", "grid-template-rows"):
            self.assertFalse(
                validate_property_value(prop, "repeat(x, 1fr)"), prop)


class TestGridTemplateInvalidTracks(unittest.TestCase):
    """A value naming a token the grammar refuses is dropped whole.

    Counting the tokens instead would turn `red blue` into two columns.
    The count-only form is for a list this grammar reads and cannot
    store, which is the cap and nothing else.
    tests/src/css_parser_test.adb drives the same table through
    Adi.CSS_Parser, which reports each of these as an invalid value.
    """

    DROPPED = [
        "red blue",
        "-1fr 1fr",
        "-50px 1fr",
        "1fr junk",
        "auto solid",
        "repeat(3, garbage)",
        "repeat(2, red)",
        "repeat(3, -1fr)",
        "0",
        "10 20",
    ]

    READ = {
        "1fr 1fr 1fr": 3,
        "repeat(3, 1fr)": 3,
        "120px 1fr": 2,
        "auto 1fr": 2,
        "40pix 1fr": 2,
        "repeat(2, auto) 1fr": 3,
        "3": 3,
    }

    def test_a_refused_token_costs_the_declaration(self):
        for prop in ("grid-template-columns", "grid-template-rows"):
            for value in self.DROPPED:
                self.assertFalse(
                    validate_property_value(prop, value),
                    f"{prop}: {value}")

    def test_a_refused_token_reaches_no_chain(self):
        for value in self.DROPPED:
            self.assertNotIn(
                "Grid_Columns",
                "\n".join(generate_style_chain_ada(
                    {"grid-template-columns": value})),
                value)
            self.assertNotIn(
                "Grid_Rows",
                "\n".join(generate_style_chain_ada(
                    {"grid-template-rows": value})),
                value)

    def test_the_lists_it_reads_still_count(self):
        for value, count in self.READ.items():
            self.assertTrue(
                validate_property_value("grid-template-columns", value),
                value)
            self.assertIn(
                f"Grid_Columns (Grid_Columns_Value ({count}))",
                "\n".join(generate_style_chain_ada(
                    {"grid-template-columns": value})),
                value)
            self.assertIn(
                f"Grid_Rows (Grid_Rows_Value ({count}))",
                "\n".join(generate_style_chain_ada(
                    {"grid-template-rows": value})),
                value)

    def test_past_the_cap_a_read_list_still_counts(self):
        #  The one case the count-only form exists for: every token is a
        #  track, and there are more of them than the array holds.
        over = MAX_GRID_TRACKS + 1
        value = " ".join(f"{i}px" for i in range(1, over + 1))
        for prop in ("grid-template-columns", "grid-template-rows"):
            self.assertTrue(validate_property_value(prop, value), prop)
        self.assertIn(
            f"Grid_Columns (Grid_Columns_Value ({over}))",
            "\n".join(generate_style_chain_ada(
                {"grid-template-columns": value})))
        self.assertIn(
            f"Grid_Rows (Grid_Rows_Value ({over}))",
            "\n".join(generate_style_chain_ada(
                {"grid-template-rows": value})))

    def test_past_the_cap_one_refused_token_still_drops_it(self):
        #  The cap is not a way past the grammar: a list too long to
        #  store is still read token by token.
        over = MAX_GRID_TRACKS + 1
        value = " ".join(f"{i}px" for i in range(1, over)) + " red"
        for prop in ("grid-template-columns", "grid-template-rows"):
            self.assertFalse(validate_property_value(prop, value), prop)


class TestFontFamilyGrammar(unittest.TestCase):
    """The family lists both pipelines read, and the ones both refuse.

    tests/src/css_parser_test.adb drives this same table through
    Adi.CSS_Parser; a name one side reads and the other refuses is a
    declaration a compiled sheet carries and a parsed one drops.
    """

    READ = [
        "sans-serif",
        "Arial",
        "Arial, sans-serif",
        '"Helvetica Neue", Arial, sans-serif',
        "'Comic Sans MS'",
        "Open Sans",
        #  The thirteen generic families, which Adi.Font resolves
        #  against a per-platform candidate list.
        "serif",
        "monospace",
        "cursive",
        "fantasy",
        "system-ui",
        "ui-serif",
        "ui-sans-serif",
        "ui-monospace",
        "ui-rounded",
        "math",
        "emoji",
        "fangsong",
        "-apple-system",
        "--custom",
        "--3",
        "_",
    ]

    REFUSED = [
        "123bogus",
        "Arial,, sans-serif",
        "Arial,",
        ",Arial",
        "$$$",
        '"unterminated',
        "Arial!",
        "Hawaii 5-0",
        '"Foo"Bar"',
        "-",
        "-1abc",
    ]

    #  Bytes rather than literals, so these stand outside the table the
    #  Ada side is pinned against; css_parser_test.adb drives the same
    #  four through Adi.CSS_Parser.
    BEYOND_ASCII = [
        "Caf\u00e9 Regular",
        "\u5fae Regular",
        "Arial,\fsans-serif",
        "\u00a0Arial",
        "-\u00a0-",
    ]

    #  str.split() would break on these and read two names; CSS counts
    #  them as characters of one.
    REFUSED_BEYOND_ASCII = [
        "foo\u000bbar",
        "foo\u001cbar",
    ]

    def test_the_lists_beyond_ascii(self):
        for value in self.BEYOND_ASCII:
            self.assertTrue(
                validate_property_value("font-family", value), repr(value))

    def test_the_separators_css_leaves_out(self):
        for value in self.REFUSED_BEYOND_ASCII:
            self.assertFalse(
                validate_property_value("font-family", value), repr(value))

    def test_the_lists_it_reads(self):
        for value in self.READ:
            self.assertTrue(
                validate_property_value("font-family", value), value)

    def test_the_lists_it_refuses(self):
        for value in self.REFUSED:
            self.assertFalse(
                validate_property_value("font-family", value), value)

    def test_the_ada_table_holds_the_same_names(self):
        adb = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "tests", "src", "css_parser_test.adb",
        )
        with open(adb, "r", encoding="utf-8") as f:
            source = f.read()
        start = source.index("procedure Test_Font_Family_Grammar")
        body = source[start:source.index("end Test_Font_Family_Grammar;", start)]

        def names(after):
            chunk = body[body.index(after):]
            chunk = chunk[:chunk.index("];")]
            return [m.replace('""', '"')
                    for m in re.findall(r'new String\'\("(.*?)"\)', chunk)]

        self.assertEqual(names("Read : constant"), self.READ)
        self.assertEqual(names("Refused : constant"), self.REFUSED)


class TestCSSWideKeywords(unittest.TestCase):
    """`initial`, `unset` and `inherit`, and what each comes to.

    tests/src/css_parser_test.adb drives the same declarations through
    Adi.CSS_Parser. The parity here is not between two fixtures: the
    last three tests read Wide_Target_Of and Color_Reading out of
    src/adi-css_parser.adb and hold them against what this generator
    actually emits, so a wrong arm on either side fails.
    """

    #  A declaration that comes to the property's initial value, and the
    #  composer steps it emits.
    CLEARS = {
        "color: initial": ["Clear (Prop_Color)"],
        "font-size: initial": ["Clear (Prop_Font_Size)"],
        "display: initial": ["Clear (Prop_Display)"],
        "opacity: initial": ["Clear (Prop_Opacity)"],
        "grid-template-columns: initial": ["Clear (Prop_Grid_Columns)"],
        "overflow: initial": ["Clear (Prop_Overflow)"],
        "outline: initial": ["Clear (Prop_Outline_Width)",
                             "Clear (Prop_Outline_Color)",
                             "Clear (Prop_Outline_Style)"],
        "padding-top: initial": ["Clear (Prop_Padding, Top)"],
        "border-top-width: initial": ["Clear (Prop_Border_Width, Top)"],
        "border-top-left-radius: initial":
            ["Clear (Prop_Border_Radius, Top_Left)"],
        "margin-left: initial": ["Clear (Prop_Margin, Left)"],
        "row-gap: initial": ["Clear (Prop_Gap, Gap_Row_Part)"],
        "padding: initial": ["Clear (Prop_Padding)"],
        "border-width: initial": ["Clear (Prop_Border_Width)"],
        "gap: initial": ["Clear (Prop_Gap)"],
        "list-style: initial": ["Clear (Prop_List_Style_Type)",
                                "Clear (Prop_List_Style_Image)",
                                "Clear (Prop_List_Style_Position)"],
        "padding: unset": ["Clear (Prop_Padding)"],
        "display: unset": ["Clear (Prop_Display)"],
        "overflow: unset": ["Clear (Prop_Overflow)"],
    }

    #  `inherit`, and `unset` where the property inherits from a widget
    #  into its parts: reported and dropped.
    REFUSED = [
        "color: unset",
        "font-size: inherit",
        "white-space: unset",
        "padding: inherit",
    ]

    #  `inherit` is a Named_Color as well, and the colour grammar reads
    #  it, so the CSS-wide arm stands aside wherever a declaration's
    #  value can be a colour. Adi.CSS_Parser's Color_Reading is that
    #  set, and test_the_colour_carve_out_matches_the_parser reads it.
    COLOUR_INHERIT = [
        "color",
        "background",
        "background-color",
        "border-color",
        "border-top-color",
        "border-right-color",
        "border-bottom-color",
        "border-left-color",
        "outline-color",
        "border",
        "border-top",
        "border-right",
        "border-bottom",
        "border-left",
        "outline",
    ]

    @staticmethod
    def split(declaration):
        name, _, value = declaration.partition(":")
        return name.strip(), value.strip()

    @staticmethod
    def parser_source():
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        with open(os.path.join(root, "src", "adi-css_parser.adb"),
                  "r", encoding="utf-8") as f:
            return f.read()

    @staticmethod
    def css_name(decl_literal):
        """The CSS name a Decl_Name literal stands for."""
        return decl_literal[len("D_"):].lower().replace("_", "-")

    @staticmethod
    def declaration_window(source, name):
        """The text of one declaration in an Ada package body.

        Runs from its first line to the next subprogram or object at the
        same indent, with comment lines dropped.
        """
        start = source.index(name)
        rest = source[start:]
        following = re.search(r"\n   (?:function|procedure|type|[A-Z]\w* +:)",
                              rest[1:])
        window = rest[:following.start() + 1] if following else rest
        return "\n".join(line for line in window.splitlines()
                          if not line.lstrip().startswith("--"))

    def ada_wide_targets(self):
        """Wide_Target_Of as {css name: {(property, part or None)}}."""
        window = self.declaration_window(self.parser_source(),
                                         "function Wide_Target_Of")
        targets = {}
        for chunk in re.split(r"\bwhen\b", window)[1:]:
            names_part, _, value = chunk.partition("=>")
            literals = re.findall(r"D_\w+", names_part)
            if not literals:
                continue

            keys = set()
            whole = re.search(r"Whole_Of\s*\(([^)]*)\)", value)
            part = re.search(
                r"Part_Of\s*\(\s*(Prop_\w+)\s*,\s*"
                r"(?:(?:Edge_Part|Corner_Part)\s*\(\s*(\w+)\s*\)|(\w+))\s*\)",
                value)
            side = re.search(r"Side_Of\s*\(\s*(\w+)\s*\)", value)
            if whole:
                keys = {(prop.strip(), None)
                        for prop in whole.group(1).split(",")}
            elif part:
                keys = {(part.group(1), part.group(2) or part.group(3))}
            elif side:
                edge = side.group(1)
                keys = {("Prop_Border_Width", edge),
                        ("Prop_Border_Color", edge),
                        ("Prop_Border_Style", edge)}
            else:
                continue

            for literal in literals:
                targets[self.css_name(literal)] = frozenset(keys)
        return targets

    def ada_colour_reading(self):
        """Color_Reading as the set of CSS names it names True."""
        window = self.declaration_window(self.parser_source(),
                                         "Color_Reading : constant")
        aggregate = window[window.index("["):window.index("=> True")]
        return {self.css_name(literal)
                for literal in re.findall(r"D_\w+", aggregate)}

    @staticmethod
    def generated_clear_keys(name):
        """The (property, part or None) keys `<name>: initial` emits."""
        steps = generate_style_chain_ada(
            {canonical_property_name(name): "initial"})
        keys = set()
        for step in steps:
            match = re.fullmatch(r"Clear \((Prop_\w+)(?:, (\w+))?\)", step)
            if match is None:
                raise AssertionError(f"{name}: initial emitted {step!r}")
            keys.add((match.group(1), match.group(2)))
        return frozenset(keys)

    def test_the_declarations_that_clear(self):
        for declaration, steps in self.CLEARS.items():
            name, value = self.split(declaration)
            self.assertTrue(
                validate_property_value(name, value), declaration)
            self.assertEqual(
                generate_style_chain_ada({name: value}), steps, declaration)

    def test_initial_reaches_every_property(self):
        for name in all_supported_properties():
            self.assertTrue(
                validate_property_value(name, "initial"), name)
            self.assertTrue(self.generated_clear_keys(name), name)

    def test_the_declarations_it_refuses(self):
        for declaration in self.REFUSED:
            name, value = self.split(declaration)
            self.assertFalse(
                validate_property_value(name, value), declaration)
            self.assertEqual(
                generate_style_chain_ada({name: value}), [], declaration)

    def test_inherit_as_a_colour_stands(self):
        for name in self.COLOUR_INHERIT:
            self.assertTrue(
                validate_property_value(name, "inherit"), name)
            steps = generate_style_chain_ada({name: "inherit"})
            self.assertTrue(
                any("Inherit" in step for step in steps), name)

    def test_revert_is_left_to_the_grammars(self):
        #  Adi has one cascade origin, so `revert` would be `initial`
        #  under another name; reading it would claim a cascade Adi has
        #  not got.  This is also where `initial` stood before it was
        #  read as a keyword.
        for name in ("color", "padding", "font-size", "display"):
            self.assertFalse(validate_property_value(name, "revert"), name)
            self.assertEqual(
                generate_style_chain_ada({name: "revert"}), [], name)

    def test_a_clear_takes_only_the_part_it_names(self):
        self.assertEqual(
            generate_style_chain_ada({"padding": "4px",
                                      "padding-top": "initial"}),
            ["Clear (Prop_Padding, Top)",
             "Padding (Right, Px (4.0))",
             "Padding (Bottom, Px (4.0))",
             "Padding (Left, Px (4.0))"])
        self.assertEqual(
            generate_style_chain_ada({"gap": "10px", "row-gap": "initial"}),
            ["Clear (Prop_Gap, Gap_Row_Part)",
             "Gap (Gap_Column (Px (10.0)))"])
        #  A shorthand after a longhand takes the side back.
        self.assertEqual(
            generate_style_chain_ada({"padding-top": "initial",
                                      "padding": "4px"}),
            ["Padding (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0)))"])

    def test_the_parser_arms_cover_the_whole_vocabulary(self):
        self.assertEqual(set(self.ada_wide_targets()),
                         all_supported_properties())

    def test_every_arm_and_the_generator_name_the_same_keys(self):
        """Wide_Target_Of against the steps this generator emits.

        Both sides are read rather than restated: the arms come out of
        src/adi-css_parser.adb and the keys out of
        generate_style_chain_ada, so `padding-top` landing on the wrong
        edge fails here whichever pipeline moved it.
        """
        targets = self.ada_wide_targets()
        self.assertEqual(len(targets), 98)
        for name, keys in sorted(targets.items()):
            self.assertEqual(self.generated_clear_keys(name), keys, name)

    def test_the_colour_carve_out_matches_the_parser(self):
        """Color_Reading against the validators that read a colour."""
        by_validator = {
            name for name in all_supported_properties()
            if property_validator(name) in COLOR_READING_VALIDATORS}
        self.assertEqual(self.ada_colour_reading(), by_validator)
        self.assertEqual(set(self.COLOUR_INHERIT), by_validator)

    def test_the_ada_suite_drives_the_same_declarations(self):
        """The two behavioural suites exercise the same cases.

        This one is a fixture against a fixture -- the parity that
        matters is the two tests above -- but a case added on one side
        and forgotten on the other is worth catching.
        """
        adb = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "tests", "src", "css_parser_test.adb",
        )
        with open(adb, "r", encoding="utf-8") as f:
            source = f.read()
        start = source.index("procedure Test_CSS_Wide_Keywords")
        body = source[start:source.index("end Test_CSS_Wide_Keywords;", start)]

        chunk = body[re.search(r"Wide_CSS *: constant String :=",
                               body).start():]
        chunk = chunk[:chunk.index('";') + 1]
        css = "".join(re.findall(r'"([^"]*)"', chunk))
        found = {"clears": [], "refused": []}
        for name, block in re.findall(r"\.([a-z-]+) \{([^}]*)\}", css):
            if name in ("initial", "part", "whole", "unset"):
                found["clears"].extend(
                    d.strip() for d in block.split(";") if d.strip())
            elif name == "refused":
                found["refused"].extend(
                    d.strip() for d in block.split(";") if d.strip())

        self.assertEqual(sorted(found["clears"]), sorted(self.CLEARS))
        self.assertEqual(sorted(found["refused"]), sorted(self.REFUSED))

        names = re.findall(r'new String\'\("([a-z-]+)"\)', body)
        self.assertEqual(names, self.COLOUR_INHERIT)


if __name__ == "__main__":
    unittest.main()
