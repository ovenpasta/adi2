#!/usr/bin/env python3
"""
CSS to Ada Widget Style Generator

Converts CSS files to Ada code using the Adi.CSS_Styles and Adi.Widget_Styles packages.

Usage: python css_to_ada.py input.css output.ads [--package-name=My_Styles]
"""

import re
import sys
import argparse
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum


class WidgetState(Enum):
    NORMAL = "State_Normal"
    HOVERED = "State_Hovered"
    PRESSED = "State_Pressed"
    FOCUSED = "State_Focused"
    DISABLED = "State_Disabled"
    SELECTED = "State_Selected"


# CSS pseudo-class to Ada state mapping
PSEUDO_CLASS_MAP = {
    "hover": WidgetState.HOVERED,
    "hovered": WidgetState.HOVERED,
    "active": WidgetState.PRESSED,
    "pressed": WidgetState.PRESSED,
    "focus": WidgetState.FOCUSED,
    "focused": WidgetState.FOCUSED,
    "disabled": WidgetState.DISABLED,
    "enabled": None,  # Special handling: When_Not(State_Disabled)
    "checked": WidgetState.SELECTED,
    "selected": WidgetState.SELECTED,
}

# CSS color names to Ada Named_Color
NAMED_COLORS = {
    "black": "Black",
    "white": "White",
    "red": "Red",
    "green": "Green",
    "blue": "Blue",
    "yellow": "Yellow",
    "orange": "Orange",
    "purple": "Purple",
    "gray": "Gray",
    "grey": "Gray",
    "lightgray": "Light_Gray",
    "lightgrey": "Light_Gray",
    "darkgray": "Dark_Gray",
    "darkgrey": "Dark_Gray",
    "transparent": "Transparent",
    "inherit": "Inherit",
    "currentcolor": "Current_Color",
}

# CSS display values to Ada
DISPLAY_MAP = {
    "none": "Display_None",
    "block": "Block",
    "inline": "Inline",
    "inline-block": "Inline_Block",
    "flex": "Flex",
    "inline-flex": "Inline_Flex",
    "grid": "Grid",
    "inline-grid": "Inline_Grid",
}

# CSS position values to Ada
POSITION_MAP = {
    "static": "Static",
    "relative": "Relative",
    "absolute": "Absolute",
    "fixed": "Fixed",
    "sticky": "Sticky",
}

# CSS flex-direction values to Ada
FLEX_DIRECTION_MAP = {
    "row": "Row",
    "row-reverse": "Row_Reverse",
    "column": "Column",
    "column-reverse": "Column_Reverse",
}

# CSS flex-wrap values to Ada
FLEX_WRAP_MAP = {
    "nowrap": "No_Wrap",
    "wrap": "Wrap",
    "wrap-reverse": "Wrap_Reverse",
}

# CSS justify-content values to Ada
JUSTIFY_CONTENT_MAP = {
    "flex-start": "Flex_Start",
    "start": "Flex_Start",
    "flex-end": "Flex_End",
    "end": "Flex_End",
    "center": "Center",
    "space-between": "Space_Between",
    "space-around": "Space_Around",
    "space-evenly": "Space_Evenly",
}

# CSS align-items values to Ada
ALIGN_ITEMS_MAP = {
    "flex-start": "Flex_Start",
    "start": "Flex_Start",
    "flex-end": "Flex_End",
    "end": "Flex_End",
    "center": "Center",
    "baseline": "Baseline",
    "stretch": "Stretch",
}

# CSS align-self values to Ada
ALIGN_SELF_MAP = {
    "auto": "Auto",
    "flex-start": "Flex_Start",
    "start": "Flex_Start",
    "flex-end": "Flex_End",
    "end": "Flex_End",
    "center": "Center",
    "baseline": "Baseline",
    "stretch": "Stretch",
}

# CSS align-content values to Ada
ALIGN_CONTENT_MAP = {
    "flex-start": "Flex_Start",
    "start": "Flex_Start",
    "flex-end": "Flex_End",
    "end": "Flex_End",
    "center": "Center",
    "space-between": "Space_Between",
    "space-around": "Space_Around",
    "stretch": "Stretch",
}

# CSS border-style values to Ada
BORDER_STYLE_MAP = {
    "none": "None_Style",
    "hidden": "Hidden",
    "dotted": "Dotted",
    "dashed": "Dashed",
    "solid": "Solid",
    "double": "Double",
    "groove": "Groove",
    "ridge": "Ridge",
    "inset": "Inset",
    "outset": "Outset",
}

# CSS font-weight values to Ada
FONT_WEIGHT_MAP = {
    "100": "Weight_Thin",
    "thin": "Weight_Thin",
    "200": "Weight_Extra_Light",
    "extra-light": "Weight_Extra_Light",
    "ultralight": "Weight_Extra_Light",
    "300": "Weight_Light",
    "light": "Weight_Light",
    "400": "Weight_Normal",
    "normal": "Weight_Normal",
    "500": "Weight_Medium",
    "medium": "Weight_Medium",
    "600": "Weight_Semi_Bold",
    "semi-bold": "Weight_Semi_Bold",
    "semibold": "Weight_Semi_Bold",
    "700": "Weight_Bold",
    "bold": "Weight_Bold",
    "800": "Weight_Extra_Bold",
    "extra-bold": "Weight_Extra_Bold",
    "extrabold": "Weight_Extra_Bold",
    "900": "Weight_Black",
    "black": "Weight_Black",
}

# CSS font-style values to Ada
FONT_STYLE_MAP = {
    "normal": "Style_Normal",
    "italic": "Style_Italic",
    "oblique": "Style_Oblique",
}

# CSS text-align values to Ada
TEXT_ALIGN_MAP = {
    "left": "Text_Left",
    "right": "Text_Right",
    "center": "Text_Center",
    "justify": "Text_Justify",
    "start": "Text_Start",
    "end": "Text_End",
}

# CSS vertical-align values to Ada
VERTICAL_ALIGN_MAP = {
    "baseline": "VA_Baseline",
    "top": "VA_Top",
    "middle": "VA_Middle",
    "bottom": "VA_Bottom",
    "text-top": "VA_Text_Top",
    "text-bottom": "VA_Text_Bottom",
}

# CSS text-decoration values to Ada
TEXT_DECORATION_MAP = {
    "none": "Decoration_None",
    "underline": "Decoration_Underline",
    "overline": "Decoration_Overline",
    "line-through": "Decoration_Line_Through",
}

# CSS white-space values to Ada
WHITE_SPACE_MAP = {
    "normal": "WS_Normal",
    "nowrap": "WS_Nowrap",
    "pre": "WS_Pre",
    "pre-wrap": "WS_Pre_Wrap",
    "pre-line": "WS_Pre_Line",
}

# CSS text-overflow values to Ada
TEXT_OVERFLOW_MAP = {
    "clip": "Overflow_Clip",
    "ellipsis": "Overflow_Ellipsis",
}

# CSS text-wrap-mode values to Ada
TEXT_WRAP_MODE_MAP = {
    "wrap": "TWM_Wrap",
    "nowrap": "TWM_Nowrap",
}

# CSS object-fit values to Ada
OBJECT_FIT_MAP = {
    "fill": "Fit_Fill",
    "contain": "Fit_Contain",
    "cover": "Fit_Cover",
    "none": "Fit_None",
    "scale-down": "Fit_Scale_Down",
}

# CSS overflow values to Ada
OVERFLOW_MAP = {
    "visible": "Overflow_Visible",
    "hidden": "Overflow_Hidden",
    "scroll": "Overflow_Scroll",
    "auto": "Overflow_Auto",
}

# CSS cursor values to Ada
CURSOR_MAP = {
    "auto": "Cursor_Auto",
    "default": "Cursor_Default",
    "pointer": "Cursor_Pointer",
    "text": "Cursor_Text",
    "move": "Cursor_Move",
    "not-allowed": "Cursor_Not_Allowed",
    "wait": "Cursor_Wait",
    "crosshair": "Cursor_Crosshair",
    "grab": "Cursor_Grab",
    "grabbing": "Cursor_Grabbing",
    "ns-resize": "Cursor_Resize_NS",
    "ew-resize": "Cursor_Resize_EW",
    "nesw-resize": "Cursor_Resize_NESW",
    "nwse-resize": "Cursor_Resize_NWSE",
}

# CSS visibility values to Ada
VISIBILITY_MAP = {
    "visible": "Visibility_Visible",
    "hidden": "Visibility_Hidden",
    "collapse": "Visibility_Collapse",
}

# CSS part selector to Ada Part_Kind mapping
PART_MAP = {
    "main": "Main_Part",
    "label": "Label_Part",
    "cursor": "Cursor_Part",
    "selected": "Selected_Part",
    "icon": "Icon_Part",
    "indicator": "Indicator_Part",
    "scroll": "Scroll_Part",
    "knob": "Knob_Part",
    "items": "Items_Part",
    "any": "Any_Part",
    "custom": "Custom_Part",
}


@dataclass
class ParsedLength:
    amount: float
    unit: str  # "Px", "Dip", "Em", "Root_Em", "Pct"


@dataclass
class ParsedColor:
    kind: str  # "named", "rgb", "rgba"
    name: Optional[str] = None
    r: Optional[int] = None
    g: Optional[int] = None
    b: Optional[int] = None
    a: Optional[float] = None


@dataclass
class ParsedSelector:
    name: str
    part_kind: str = "Main_Part"
    widget_states: list[WidgetState] = field(default_factory=list)
    widget_negated_states: list[WidgetState] = field(default_factory=list)
    part_states: list[WidgetState] = field(default_factory=list)
    part_negated_states: list[WidgetState] = field(default_factory=list)
    
    def get_unique_key(self) -> str:
        """Generate unique key for this selector's state combination"""
        parts = (
            sorted([f"Widget_{s.name}" for s in self.widget_states]) +
            sorted([f"Widget_Not_{s.name}" for s in self.widget_negated_states]) +
            sorted([f"Part_{s.name}" for s in self.part_states]) +
            sorted([f"Part_Not_{s.name}" for s in self.part_negated_states])
        )
        return "_".join(parts)


@dataclass
class ParsedRule:
    selector: ParsedSelector
    properties: dict[str, str]


@dataclass
class PartStyleGroup:
    """Rules for a single widget part"""
    part_kind: str
    base_rule: Optional[ParsedRule] = None
    state_rules: list[ParsedRule] = field(default_factory=list)


@dataclass
class WidgetStyleGroup:
    """Groups rules for the same widget, split by part"""
    name: str
    parts: dict[str, PartStyleGroup] = field(default_factory=dict)


def parse_length(value: str) -> Optional[ParsedLength]:
    """Parse a CSS length value like '10px', '1.5em', '50%'"""
    value = value.strip().lower()
    
    if value == "0":
        return ParsedLength(0.0, "Px")
    
    match = re.match(r'^(-?\d*\.?\d+)(px|em|rem|%|dip)?$', value)
    if not match:
        return None
    
    amount = float(match.group(1))
    unit_str = match.group(2) or "px"
    
    unit_map = {
        "px": "Px",
        "dip": "Dip",
        "em": "Em",
        "rem": "Root_Em",
        "%": "Pct",
    }
    
    unit = unit_map.get(unit_str, "Px")
    return ParsedLength(amount, unit)

def parse_grid_track_count(value: str) -> Optional[int]:
    """Parse grid-template-* into a simple track count."""
    value = value.strip().lower()
    if not value or value == "none":
        return None

    m = re.match(r'^repeat\(\s*(\d+)\s*,.*\)$', value)
    if m:
        n = int(m.group(1))
        return n if n > 0 else None

    if re.match(r'^\d+$', value):
        n = int(value)
        return n if n > 0 else None

    tokens = [t for t in re.split(r'\s+', value) if t and t != "/"]
    if tokens:
        return len(tokens)
    return None


def parse_grid_placement(value: str) -> tuple[Optional[int], Optional[int]]:
    """Parse grid-row / grid-column into (start, span)."""
    value = value.strip().lower()
    if not value or value == "auto":
        return (None, None)

    start: Optional[int] = None
    span: Optional[int] = None

    parts = [p.strip() for p in value.split("/", 1)]
    left = parts[0]
    right = parts[1] if len(parts) > 1 else None

    m_left_span = re.match(r'^span\s+(\d+)$', left)
    if m_left_span:
        span = int(m_left_span.group(1))
    elif re.match(r'^\d+$', left):
        start = int(left)

    if right:
        m_right_span = re.match(r'^span\s+(\d+)$', right)
        if m_right_span:
            span = int(m_right_span.group(1))
        elif re.match(r'^\d+$', right) and start is not None:
            end_line = int(right)
            if end_line > start:
                span = end_line - start

    if start is not None and start <= 0:
        start = None
    if span is not None and span <= 0:
        span = None
    return (start, span)


def parse_color(value: str) -> Optional[ParsedColor]:
    """Parse a CSS color value"""
    value = value.strip().lower()
    
    # Named color
    if value in NAMED_COLORS:
        return ParsedColor(kind="named", name=NAMED_COLORS[value])
    
    # Hex color
    hex_match = re.match(r'^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$', value)
    if hex_match:
        hex_str = hex_match.group(1)
        if len(hex_str) == 3:
            r = int(hex_str[0] * 2, 16)
            g = int(hex_str[1] * 2, 16)
            b = int(hex_str[2] * 2, 16)
            return ParsedColor(kind="rgb", r=r, g=g, b=b)
        elif len(hex_str) == 6:
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            return ParsedColor(kind="rgb", r=r, g=g, b=b)
        elif len(hex_str) == 8:
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            a = int(hex_str[6:8], 16) / 255.0
            return ParsedColor(kind="rgba", r=r, g=g, b=b, a=a)
    
    # rgb() function
    rgb_match = re.match(r'^rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$', value)
    if rgb_match:
        return ParsedColor(
            kind="rgb",
            r=int(rgb_match.group(1)),
            g=int(rgb_match.group(2)),
            b=int(rgb_match.group(3))
        )
    
    # rgba() function
    rgba_match = re.match(
        r'^rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d*\.?\d+)\s*\)$', value
    )
    if rgba_match:
        return ParsedColor(
            kind="rgba",
            r=int(rgba_match.group(1)),
            g=int(rgba_match.group(2)),
            b=int(rgba_match.group(3)),
            a=float(rgba_match.group(4))
        )
    
    return None


PART_INTERACTION_PSEUDOS = {"hover", "hovered", "active", "pressed"}


def append_pseudo_state(
    pseudo_name: str,
    is_negated: bool,
    target_widget_states: list[WidgetState],
    target_widget_negated_states: list[WidgetState],
    target_part_states: list[WidgetState],
    target_part_negated_states: list[WidgetState],
    part_scope_enabled: bool,
) -> None:
    pseudo = pseudo_name.lower()
    if pseudo not in PSEUDO_CLASS_MAP:
        return

    state = PSEUDO_CLASS_MAP[pseudo]

    # :enabled is represented as not disabled.
    if state is None and pseudo == "enabled":
        state = WidgetState.DISABLED
        is_negated = not is_negated

    if state is None:
        return

    use_part_scope = part_scope_enabled and pseudo in PART_INTERACTION_PSEUDOS

    if use_part_scope:
        if is_negated:
            target_part_negated_states.append(state)
        else:
            target_part_states.append(state)
    else:
        if is_negated:
            target_widget_negated_states.append(state)
        else:
            target_widget_states.append(state)


def parse_pseudo_classes(
    pseudo_part: str,
    part_scope_enabled: bool,
    widget_states: list[WidgetState],
    widget_negated_states: list[WidgetState],
    part_states: list[WidgetState],
    part_negated_states: list[WidgetState],
) -> None:
    
    # Pattern to match :not(...) or :simple-pseudo
    pseudo_pattern = re.compile(r':not\s*\(\s*:?(\w+)\s*\)|:(\w+)')

    for match in pseudo_pattern.finditer(pseudo_part):
        if match.group(1):  # :not(...) matched
            append_pseudo_state(
                pseudo_name=match.group(1),
                is_negated=True,
                target_widget_states=widget_states,
                target_widget_negated_states=widget_negated_states,
                target_part_states=part_states,
                target_part_negated_states=part_negated_states,
                part_scope_enabled=part_scope_enabled,
            )
        elif match.group(2):  # :pseudo matched
            append_pseudo_state(
                pseudo_name=match.group(2),
                is_negated=False,
                target_widget_states=widget_states,
                target_widget_negated_states=widget_negated_states,
                target_part_states=part_states,
                target_part_negated_states=part_negated_states,
                part_scope_enabled=part_scope_enabled,
            )


def parse_selector(selector_str: str) -> Optional[ParsedSelector]:
    """Parse selectors like '.button:hover::label' and '.button::label:hover'."""
    selector_str = selector_str.strip()

    if selector_str.startswith('.') or selector_str.startswith('#'):
        selector_str = selector_str[1:]

    part_kind = "Main_Part"
    widget_pseudo_part = ""
    part_pseudo_part = ""
    part_scope_enabled = False

    if "::" in selector_str:
        left, right = selector_str.split("::", 1)
        left = left.strip()
        right = right.strip()

        left_first_colon = left.find(":")
        if left_first_colon == -1:
            name = left
        else:
            name = left[:left_first_colon].strip()
            widget_pseudo_part = left[left_first_colon:]

        right_first_colon = right.find(":")
        if right_first_colon == -1:
            part_name = right
        else:
            part_name = right[:right_first_colon]
            part_pseudo_part = right[right_first_colon:]

        part_key = part_name.strip().lower()
        if part_key not in PART_MAP:
            return None
        part_kind = PART_MAP[part_key]
        part_scope_enabled = part_kind != "Main_Part"
    else:
        first_colon = selector_str.find(":")
        if first_colon == -1:
            name = selector_str.strip()
        else:
            name = selector_str[:first_colon].strip()
            widget_pseudo_part = selector_str[first_colon:]

    if not name:
        return None

    widget_states: list[WidgetState] = []
    widget_negated_states: list[WidgetState] = []
    part_states: list[WidgetState] = []
    part_negated_states: list[WidgetState] = []

    # Pseudos before ::part are always widget-scoped.
    parse_pseudo_classes(
        pseudo_part=widget_pseudo_part,
        part_scope_enabled=False,
        widget_states=widget_states,
        widget_negated_states=widget_negated_states,
        part_states=part_states,
        part_negated_states=part_negated_states,
    )

    # Pseudos after ::part are part-scoped only for interactive states on non-main parts.
    parse_pseudo_classes(
        pseudo_part=part_pseudo_part,
        part_scope_enabled=part_scope_enabled,
        widget_states=widget_states,
        widget_negated_states=widget_negated_states,
        part_states=part_states,
        part_negated_states=part_negated_states,
    )

    return ParsedSelector(
        name=name,
        part_kind=part_kind,
        widget_states=widget_states,
        widget_negated_states=widget_negated_states,
        part_states=part_states,
        part_negated_states=part_negated_states,
    )


def parse_box_values(value: str) -> Optional[list[ParsedLength]]:
    """Parse 1-4 length values for margin/padding"""
    parts = value.split()
    lengths = []

    for part in parts:
        length = parse_length(part)
        if length is None:
            return None
        lengths.append(length)

    if len(lengths) == 0:
        return None

    return lengths


@dataclass
class ParsedBoxShadow:
    offset_x: ParsedLength
    offset_y: ParsedLength
    blur_radius: ParsedLength
    spread_radius: ParsedLength
    color: ParsedColor


@dataclass
class ParsedTransition:
    duration_seconds: float
    easing: str
    property_set: str


def parse_box_shadow(value: str) -> Optional[ParsedBoxShadow]:
    """Parse CSS box-shadow value like '2px 4px 10px rgba(0,0,0,0.25)'"""
    value = value.strip().lower()

    if value == "none":
        return None

    # Extract color first (can be at start or end)
    color = None
    color_patterns = [
        (r'rgba?\s*\([^)]+\)', 'func'),
        (r'#[0-9a-f]{3,8}', 'hex'),
    ]

    for pattern, kind in color_patterns:
        match = re.search(pattern, value)
        if match:
            color_str = match.group(0)
            color = parse_color(color_str)
            value = value.replace(color_str, '').strip()
            break

    # Check for named color
    if not color:
        for name in NAMED_COLORS.keys():
            if name in value.split():
                color = parse_color(name)
                value = value.replace(name, '').strip()
                break

    # Parse lengths: offset-x offset-y [blur-radius] [spread-radius]
    parts = value.split()
    lengths = []

    for part in parts:
        length = parse_length(part)
        if length:
            lengths.append(length)

    if len(lengths) < 2:
        return None

    offset_x = lengths[0]
    offset_y = lengths[1]
    blur_radius = lengths[2] if len(lengths) > 2 else ParsedLength(0.0, "Px")
    spread_radius = lengths[3] if len(lengths) > 3 else ParsedLength(0.0, "Px")

    if not color:
        color = ParsedColor(kind="rgba", r=0, g=0, b=0, a=0.25)

    return ParsedBoxShadow(
        offset_x=offset_x,
        offset_y=offset_y,
        blur_radius=blur_radius,
        spread_radius=spread_radius,
        color=color
    )


TRANSITION_EASING_MAP = {
    "linear": "Linear",
    "ease-in": "Ease_In",
    "ease-out": "Ease_Out",
    "ease-in-out": "Ease_In_Out",
    "ease": "Ease_In_Out",
}

TRANSITION_PROPERTY_MAP = {
    "all": "All_Properties",
    "color": "Props (Prop_Color)",
    "background-color": "Props (Prop_Background_Color)",
    "border-color": "Props (Prop_Border_Color)",
    "border-width": "Props (Prop_Border_Width)",
    "border-radius": "Props (Prop_Border_Radius)",
    "padding": "Props (Prop_Padding)",
    "margin": "Props (Prop_Margin)",
    "opacity": "Props (Prop_Opacity)",
    "box-shadow": "Props (Prop_Box_Shadow)",
    "font-size": "Props (Prop_Font_Size)",
}


def parse_transition(value: str) -> Optional[ParsedTransition]:
    """Parse a simple CSS transition: <property> <duration> [easing]"""
    value = value.strip().lower()
    if not value or value == "none":
        return None

    # Keep first transition when comma-separated values are provided.
    first = value.split(",", 1)[0].strip()
    tokens = re.split(r"\s+", first)
    if not tokens:
        return None

    property_name = "all"
    duration_seconds = None
    easing = "Ease_In_Out"

    for token in tokens:
        if token.endswith("ms"):
            try:
                duration_seconds = float(token[:-2]) / 1000.0
            except ValueError:
                return None
        elif token.endswith("s"):
            try:
                duration_seconds = float(token[:-1])
            except ValueError:
                return None
        elif token in TRANSITION_EASING_MAP:
            easing = TRANSITION_EASING_MAP[token]
        elif token in TRANSITION_PROPERTY_MAP:
            property_name = token

    if duration_seconds is None:
        return None

    return ParsedTransition(
        duration_seconds=duration_seconds,
        easing=easing,
        property_set=TRANSITION_PROPERTY_MAP.get(property_name, "All_Properties"),
    )


def parse_css(css_content: str) -> list[ParsedRule]:
    """Parse CSS content into rules"""
    rules = []
    
    # Remove comments
    css_content = re.sub(r'/\*.*?\*/', '', css_content, flags=re.DOTALL)
    
    # Find all rules
    rule_pattern = re.compile(r'([^{}]+)\{([^{}]*)\}', re.DOTALL)
    
    for match in rule_pattern.finditer(css_content):
        selector_str = match.group(1).strip()
        properties_str = match.group(2).strip()
        
        # Handle multiple selectors separated by comma
        for single_selector in selector_str.split(','):
            selector = parse_selector(single_selector.strip())
            if selector is None:
                continue
            
            # Parse properties
            properties = {}
            for prop_match in re.finditer(r'([\w-]+)\s*:\s*([^;]+);?', properties_str):
                prop_name = prop_match.group(1).strip().lower()
                prop_value = prop_match.group(2).strip()
                properties[prop_name] = prop_value
            
            if properties:
                rules.append(ParsedRule(selector=selector, properties=properties))
    
    return rules


def group_rules_by_widget(rules: list[ParsedRule]) -> dict[str, WidgetStyleGroup]:
    """Group rules by widget name"""
    groups: dict[str, WidgetStyleGroup] = {}
    
    for rule in rules:
        name = rule.selector.name
        part_kind = rule.selector.part_kind
        
        if name not in groups:
            groups[name] = WidgetStyleGroup(name=name)
        
        group = groups[name]
        if part_kind not in group.parts:
            group.parts[part_kind] = PartStyleGroup(part_kind=part_kind)
        part_group = group.parts[part_kind]
        
        # If no states, it's the base rule
        if (not rule.selector.widget_states and
            not rule.selector.widget_negated_states and
            not rule.selector.part_states and
            not rule.selector.part_negated_states):
            part_group.base_rule = rule
        else:
            part_group.state_rules.append(rule)
    
    return groups


def to_ada_identifier(name: str) -> str:
    """Convert CSS name to valid Ada identifier"""
    # Replace hyphens with underscores
    name = name.replace('-', '_')
    # Capitalize first letter of each word
    parts = name.split('_')
    return '_'.join(part.capitalize() for part in parts)


def format_float(value: float) -> str:
    """Format float for Ada"""
    if value == int(value):
        return f"{int(value)}.0"
    return str(value)


def generate_length_ada(length: ParsedLength) -> str:
    """Generate Ada code for a length value"""
    return f"{length.unit} ({format_float(length.amount)})"


def generate_color_ada(color: ParsedColor) -> str:
    """Generate Ada code for a color value"""
    if color.kind == "named":
        return f"C ({color.name})"
    elif color.kind == "rgb":
        return f"RGB ({color.r}, {color.g}, {color.b})"
    elif color.kind == "rgba":
        return f"RGBA ({color.r}, {color.g}, {color.b}, {format_float(color.a)})"
    return "C (Black)"


def generate_box_ada(lengths: list[ParsedLength]) -> str:
    """Generate Ada code for box values (padding/margin)"""
    if len(lengths) == 1:
        return f"CSS_Box ({generate_length_ada(lengths[0])})"
    elif len(lengths) == 2:
        return f"CSS_Box ({generate_length_ada(lengths[0])}, {generate_length_ada(lengths[1])})"
    elif len(lengths) == 4:
        return (f"CSS_Box ({generate_length_ada(lengths[0])}, "
                f"{generate_length_ada(lengths[1])}, "
                f"{generate_length_ada(lengths[2])}, "
                f"{generate_length_ada(lengths[3])})")
    elif len(lengths) == 3:
        # top, horizontal, bottom
        return (f"CSS_Box ({generate_length_ada(lengths[0])}, "
                f"{generate_length_ada(lengths[1])}, "
                f"{generate_length_ada(lengths[2])}, "
                f"{generate_length_ada(lengths[1])})")
    return "CSS_Box (Zero_Length)"


def generate_border_width_ada(lengths: list[ParsedLength]) -> str:
    """Generate Ada code for border-width"""
    if len(lengths) == 1:
        return f"Border_Width ({generate_length_ada(lengths[0])})"
    elif len(lengths) == 2:
        return f"Border_Width ({generate_length_ada(lengths[0])}, {generate_length_ada(lengths[1])})"
    elif len(lengths) >= 4:
        return (f"Border_Width ({generate_length_ada(lengths[0])}, "
                f"{generate_length_ada(lengths[1])}, "
                f"{generate_length_ada(lengths[2])}, "
                f"{generate_length_ada(lengths[3])})")
    return "Border_Width (Zero_Length)"


def generate_border_radius_ada(lengths: list[ParsedLength]) -> str:
    """Generate Ada code for border-radius"""
    if len(lengths) == 1:
        return f"Radius ({generate_length_ada(lengths[0])})"
    elif len(lengths) == 2:
        return f"Radius ({generate_length_ada(lengths[0])}, {generate_length_ada(lengths[1])})"
    elif len(lengths) >= 4:
        return (f"Radius ({generate_length_ada(lengths[0])}, "
                f"{generate_length_ada(lengths[1])}, "
                f"{generate_length_ada(lengths[2])}, "
                f"{generate_length_ada(lengths[3])})")
    return "Radius (Zero_Length)"


def generate_style_rules_ada(properties: dict[str, str], indent: str = "      ") -> list[str]:
    """Generate Ada Style_Rules record fields from CSS properties"""
    fields = []
    
    for prop, value in properties.items():
        ada_field = None
        
        # Color
        if prop == "color":
            color = parse_color(value)
            if color:
                ada_field = f"Color => Set ({generate_color_ada(color)})"
        
        # Background color
        elif prop in ("background-color", "background"):
            color = parse_color(value)
            if color:
                ada_field = f"Background_Color => Set_Bg ({generate_color_ada(color)})"
        
        # Padding
        elif prop == "padding":
            lengths = parse_box_values(value)
            if lengths:
                ada_field = f"Padding => Set ({generate_box_ada(lengths)})"
        
        # Margin
        elif prop == "margin":
            lengths = parse_box_values(value)
            if lengths:
                ada_field = f"Margin => Set ({generate_box_ada(lengths)})"
        
        # Border width
        elif prop == "border-width":
            lengths = parse_box_values(value)
            if lengths:
                ada_field = f"Border_Width => Set ({generate_border_width_ada(lengths)})"
        
        # Border color
        elif prop == "border-color":
            color = parse_color(value)
            if color:
                ada_field = f"Border_Color => Set (Border_Color ({generate_color_ada(color)}))"
        
        # Border style
        elif prop == "border-style":
            if value.lower() in BORDER_STYLE_MAP:
                ada_field = f"Border_Style => Set (Border_Style ({BORDER_STYLE_MAP[value.lower()]}))"
        
        # Border (shorthand)
        elif prop == "border":
            parts = value.split()
            for part in parts:
                length = parse_length(part)
                if length:
                    fields.append(f"{indent}Border_Width => Set (Border_Width ({generate_length_ada(length)}))")
                    continue
                if part.lower() in BORDER_STYLE_MAP:
                    fields.append(f"{indent}Border_Style => Set (Border_Style ({BORDER_STYLE_MAP[part.lower()]}))")
                    continue
                color = parse_color(part)
                if color:
                    fields.append(f"{indent}Border_Color => Set (Border_Color ({generate_color_ada(color)}))")
            continue  # Skip adding ada_field since we handled it
        
        # Border radius
        elif prop == "border-radius":
            lengths = parse_box_values(value)
            if lengths:
                ada_field = f"Border_Radius => Set ({generate_border_radius_ada(lengths)})"
        
        # Width
        elif prop == "width":
            if value.lower() == "auto":
                ada_field = "Width => Set (Auto_Size)"
            elif value.lower() == "min-content":
                ada_field = "Width => Set (Min_Content_Size)"
            elif value.lower() == "max-content":
                ada_field = "Width => Set (Max_Content_Size)"
            elif value.lower() == "fit-content":
                ada_field = "Width => Set (Fit_Content_Size)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Width => Set (Size ({generate_length_ada(length)}))"
        
        # Height
        elif prop == "height":
            if value.lower() == "auto":
                ada_field = "Height => Set (Auto_Size)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Height => Set (Size ({generate_length_ada(length)}))"
        
        # Min/Max width/height
        elif prop == "min-width":
            length = parse_length(value)
            if length:
                ada_field = f"Min_Width => Set (Size ({generate_length_ada(length)}))"
        
        elif prop == "max-width":
            length = parse_length(value)
            if length:
                ada_field = f"Max_Width => Set (Size ({generate_length_ada(length)}))"
        
        elif prop == "min-height":
            length = parse_length(value)
            if length:
                ada_field = f"Min_Height => Set (Size ({generate_length_ada(length)}))"
        
        elif prop == "max-height":
            length = parse_length(value)
            if length:
                ada_field = f"Max_Height => Set (Size ({generate_length_ada(length)}))"
        
        # Font size
        elif prop == "font-size":
            length = parse_length(value)
            if length:
                ada_field = f"Font_Size => Set_Font ({generate_length_ada(length)})"

        # Font weight
        elif prop == "font-weight":
            if value.lower() in FONT_WEIGHT_MAP:
                ada_field = f"Font_Weight => Set ({FONT_WEIGHT_MAP[value.lower()]})"

        # Font style
        elif prop == "font-style":
            if value.lower() in FONT_STYLE_MAP:
                ada_field = f"Font_Style => Set ({FONT_STYLE_MAP[value.lower()]})"

        # Text align
        elif prop == "text-align":
            if value.lower() in TEXT_ALIGN_MAP:
                ada_field = f"Text_Align => Set ({TEXT_ALIGN_MAP[value.lower()]})"

        # Vertical align
        elif prop == "vertical-align":
            if value.lower() in VERTICAL_ALIGN_MAP:
                ada_field = f"Vertical_Align => Set ({VERTICAL_ALIGN_MAP[value.lower()]})"

        # Text decoration
        elif prop == "text-decoration":
            if value.lower() in TEXT_DECORATION_MAP:
                ada_field = f"Text_Decoration => Set ({TEXT_DECORATION_MAP[value.lower()]})"

        # White space
        elif prop == "white-space":
            if value.lower() in WHITE_SPACE_MAP:
                ada_field = f"White_Space => Set ({WHITE_SPACE_MAP[value.lower()]})"

        # Text overflow
        elif prop == "text-overflow":
            if value.lower() in TEXT_OVERFLOW_MAP:
                ada_field = f"Text_Overflow => Set ({TEXT_OVERFLOW_MAP[value.lower()]})"

        # Text wrap mode
        elif prop == "text-wrap-mode":
            if value.lower() in TEXT_WRAP_MODE_MAP:
                ada_field = f"Text_Wrap_Mode => Set ({TEXT_WRAP_MODE_MAP[value.lower()]})"

        # Line height
        elif prop == "line-height":
            if value.lower() == "normal":
                ada_field = "Line_Height => Set (Normal_Line_Height)"
            else:
                # Try as a unitless number (multiplier)
                try:
                    mult = float(value)
                    if value.replace('.', '', 1).replace('-', '', 1).isdigit():
                        ada_field = f"Line_Height => Set (Line_Height ({format_float(mult)}))"
                    else:
                        raise ValueError
                except ValueError:
                    # Try as a length
                    length = parse_length(value)
                    if length:
                        ada_field = f"Line_Height => Set (Line_Height ({generate_length_ada(length)}))"

        # Object fit
        elif prop == "object-fit":
            if value.lower() in OBJECT_FIT_MAP:
                ada_field = f"Object_Fit => Set ({OBJECT_FIT_MAP[value.lower()]})"

        # Opacity
        elif prop == "opacity":
            try:
                val = float(value)
                ada_field = f"Opacity => Set ({format_float(val)})"
            except ValueError:
                pass

        # Overflow
        elif prop == "overflow":
            if value.lower() in OVERFLOW_MAP:
                ada_field = f"Overflow => Set ({OVERFLOW_MAP[value.lower()]})"

        # Cursor
        elif prop == "cursor":
            if value.lower() in CURSOR_MAP:
                ada_field = f"Cursor => Set ({CURSOR_MAP[value.lower()]})"

        # Visibility
        elif prop == "visibility":
            if value.lower() in VISIBILITY_MAP:
                ada_field = f"Visibility => Set ({VISIBILITY_MAP[value.lower()]})"

        # Display
        elif prop == "display":
            if value.lower() in DISPLAY_MAP:
                ada_field = f"Display => Set ({DISPLAY_MAP[value.lower()]})"
        
        # Position
        elif prop == "position":
            if value.lower() in POSITION_MAP:
                ada_field = f"Position => Set ({POSITION_MAP[value.lower()]})"
        
        # Flex direction
        elif prop == "flex-direction":
            if value.lower() in FLEX_DIRECTION_MAP:
                ada_field = f"Flex_Direction => Set ({FLEX_DIRECTION_MAP[value.lower()]})"
        
        # Flex wrap
        elif prop == "flex-wrap":
            if value.lower() in FLEX_WRAP_MAP:
                ada_field = f"Flex_Wrap => Set ({FLEX_WRAP_MAP[value.lower()]})"
        
        # Justify content
        elif prop == "justify-content":
            if value.lower() in JUSTIFY_CONTENT_MAP:
                ada_field = f"Justify_Content => Set ({JUSTIFY_CONTENT_MAP[value.lower()]})"
        
        # Align items
        elif prop == "align-items":
            if value.lower() in ALIGN_ITEMS_MAP:
                ada_field = f"Align_Items => Set ({ALIGN_ITEMS_MAP[value.lower()]})"
        
        # Align self
        elif prop == "align-self":
            if value.lower() in ALIGN_SELF_MAP:
                ada_field = f"Align_Self => Set ({ALIGN_SELF_MAP[value.lower()]})"
        
        # Align content
        elif prop == "align-content":
            if value.lower() in ALIGN_CONTENT_MAP:
                ada_field = f"Align_Content => Set ({ALIGN_CONTENT_MAP[value.lower()]})"
        
        # Gap (shorthand and individual)
        elif prop in ("gap", "row-gap", "column-gap"):
            if prop == "gap":
                lengths = parse_box_values(value)
                if lengths:
                    if len(lengths) == 1:
                        ada_field = f"Gap => Set (Gap ({generate_length_ada(lengths[0])}))"
                    elif len(lengths) >= 2:
                        ada_field = f"Gap => Set (Gap ({generate_length_ada(lengths[0])}, {generate_length_ada(lengths[1])}))"
            else:
                length = parse_length(value)
                if length:
                    # row-gap and column-gap map to the two-value Gap form
                    ada_field = f"Gap => Set (Gap ({generate_length_ada(length)}))"
        
        # Flex grow
        elif prop == "flex-grow":
            try:
                val = float(value)
                ada_field = f"Flex_Grow => Set ({format_float(val)})"
            except ValueError:
                pass
        
        # Flex shrink
        elif prop == "flex-shrink":
            try:
                val = float(value)
                ada_field = f"Flex_Shrink => Set ({format_float(val)})"
            except ValueError:
                pass
        
        # Flex basis
        elif prop == "flex-basis":
            if value.lower() == "auto":
                ada_field = "Flex_Basis => Set (Auto_Basis)"
            elif value.lower() == "content":
                ada_field = "Flex_Basis => Set (Content_Basis)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Flex_Basis => Set (Basis ({generate_length_ada(length)}))"
        
        # Order
        elif prop == "order":
            try:
                val = int(value)
                ada_field = f"Order => Set ({val})"
            except ValueError:
                pass

        # Grid container
        elif prop == "grid-template-columns":
            tracks = parse_grid_track_count(value)
            if tracks is not None:
                ada_field = f"Grid_Columns => Set (Grid_Columns_Value ({tracks}))"

        elif prop == "grid-template-rows":
            tracks = parse_grid_track_count(value)
            if tracks is not None:
                ada_field = f"Grid_Rows => Set (Grid_Rows_Value ({tracks}))"

        # Grid item placement
        elif prop == "grid-column":
            start, span = parse_grid_placement(value)
            if start is not None:
                fields.append(f"{indent}Grid_Column => Set (Grid_Column_Value ({start}))")
            if span is not None:
                fields.append(f"{indent}Grid_Column_Span => Set (Grid_Column_Span_Value ({span}))")
            continue

        elif prop == "grid-row":
            start, span = parse_grid_placement(value)
            if start is not None:
                fields.append(f"{indent}Grid_Row => Set (Grid_Row_Value ({start}))")
            if span is not None:
                fields.append(f"{indent}Grid_Row_Span => Set (Grid_Row_Span_Value ({span}))")
            continue

        # Box shadow
        elif prop == "box-shadow":
            if value.lower() == "none":
                ada_field = "Box_Shadow => Set (No_Shadow)"
            else:
                shadow = parse_box_shadow(value)
                if shadow:
                    ada_field = (f"Box_Shadow => Set (Shadow ("
                                f"{generate_length_ada(shadow.offset_x)}, "
                                f"{generate_length_ada(shadow.offset_y)}, "
                                f"{generate_length_ada(shadow.blur_radius)}, "
                                f"{generate_length_ada(shadow.spread_radius)}, "
                                f"{generate_color_ada(shadow.color)}))")

        # Transition
        elif prop == "transition":
            transition = parse_transition(value)
            if transition:
                ada_field = (
                    f"Transition => Set ((Duration => {format_float(transition.duration_seconds)}, "
                    f"Easing => {transition.easing}, "
                    f"Properties => {transition.property_set}))"
                )

        if ada_field:
            fields.append(f"{indent}{ada_field}")
    
    return fields


def generate_selector_ada(selector: ParsedSelector) -> str:
    """Generate Ada selector expression"""
    parts = []
    
    for state in selector.widget_states:
        parts.append(f"When_State ({state.value})")
    
    for state in selector.widget_negated_states:
        parts.append(f"When_Not ({state.value})")

    for state in selector.part_states:
        parts.append(f"When_Part_State ({state.value})")

    for state in selector.part_negated_states:
        parts.append(f"When_Part_Not ({state.value})")
    
    if not parts:
        return "Any_State"
    
    return " and ".join(parts)


def generate_state_description(selector: ParsedSelector) -> str:
    """Generate human-readable description of states"""
    parts = []
    
    for state in selector.widget_states:
        parts.append(f"widget {state.value}")
    
    for state in selector.widget_negated_states:
        parts.append(f"widget not {state.value}")

    for state in selector.part_states:
        parts.append(f"part {state.value}")

    for state in selector.part_negated_states:
        parts.append(f"part not {state.value}")
    
    return ", ".join(parts) if parts else "base"


def part_label(part_kind: str) -> str:
    """Convert Part_Kind name to a compact label, e.g. Label_Part -> Label."""
    if part_kind.endswith("_Part"):
        return part_kind[:-5]
    return part_kind


def style_name_prefix(ada_name: str, part_kind: str) -> str:
    """Name prefix for generated style constants."""
    return ada_name if part_kind == "Main_Part" else f"{ada_name}_{part_label(part_kind)}"


def widget_style_const_name(ada_name: str, part_kind: str) -> str:
    """Generated Widget_Style constant name for this widget part."""
    prefix = style_name_prefix(ada_name, part_kind)
    return f"{prefix}_Widget"


def generate_variable_name(name_prefix: str, selector: ParsedSelector) -> str:
    """Generate unique variable name for a state rule"""
    if (not selector.widget_states and
        not selector.widget_negated_states and
        not selector.part_states and
        not selector.part_negated_states):
        return f"{name_prefix}_Base_Style"
    
    parts = []
    
    for state in selector.widget_states:
        state_name = state.value.replace("State_", "")
        parts.append(f"Widget_{state_name}")
    
    for state in selector.widget_negated_states:
        state_name = state.value.replace("State_", "")
        parts.append(f"Widget_Not_{state_name}")

    for state in selector.part_states:
        state_name = state.value.replace("State_", "")
        parts.append(f"Part_{state_name}")

    for state in selector.part_negated_states:
        state_name = state.value.replace("State_", "")
        parts.append(f"Part_Not_{state_name}")
    
    suffix = "_".join(parts)
    return f"{name_prefix}_{suffix}_Style"


def generate_ada_package(groups: dict[str, WidgetStyleGroup], package_name: str) -> str:
    """Generate complete Ada package"""
    lines = [
        f"--  Auto-generated from CSS",
        f"--  Do not edit manually",
        f"",
        f"pragma Ada_2022;",
        f"",
        f"with Adi.CSS_Styles;   use Adi.CSS_Styles;",
        f"with Adi.Widget;       use Adi.Widget;",
        f"with Adi.Widget_Styles; use Adi.Widget_Styles;",
        f"",
        f"package {package_name} is",
        f"",
    ]
    
    # Track generated variable names to avoid duplicates
    generated_names: set[str] = set()
    
    for widget_name, group in groups.items():
        ada_name = to_ada_identifier(widget_name)
        part_items = sorted(
            group.parts.items(),
            key=lambda kv: (0 if kv[0] == "Main_Part" else 1, kv[0])
        )

        for part_kind, part_group in part_items:
            part_suffix = "" if part_kind == "Main_Part" else f"::{part_label(part_kind).lower()}"
            name_prefix = style_name_prefix(ada_name, part_kind)

            if part_group.base_rule:
                var_name = f"{name_prefix}_Base_Style"
                generated_names.add(var_name)
                fields = generate_style_rules_ada(part_group.base_rule.properties)

                lines.append(f"   --  Base style for {widget_name}{part_suffix}")
                lines.append(f"   {var_name} : constant Style_Rules := (")
                if fields:
                    lines.append(",\n".join(fields) + ",")
                lines.append(f"      others => <>")
                lines.append(f"   );")
                lines.append(f"")

            for rule in part_group.state_rules:
                var_name = generate_variable_name(name_prefix, rule.selector)
                original_var_name = var_name
                counter = 2
                while var_name in generated_names:
                    var_name = f"{original_var_name}_{counter}"
                    counter += 1
                generated_names.add(var_name)
                rule._var_name = var_name  # type: ignore

                fields = generate_style_rules_ada(rule.properties)
                state_desc = generate_state_description(rule.selector)

                lines.append(f"   --  Style for {widget_name}{part_suffix} when {state_desc}")
                lines.append(f"   {var_name} : constant Style_Rules := (")
                if fields:
                    lines.append(",\n".join(fields) + ",")
                lines.append(f"      others => <>")
                lines.append(f"   );")
                lines.append(f"")
    
    # Generate combined Widget_Style using fluent builder
    for widget_name, group in groups.items():
        ada_name = to_ada_identifier(widget_name)
        part_items = sorted(
            group.parts.items(),
            key=lambda kv: (0 if kv[0] == "Main_Part" else 1, kv[0])
        )

        for part_kind, part_group in part_items:
            part_suffix = "" if part_kind == "Main_Part" else f"::{part_label(part_kind).lower()}"
            name_prefix = style_name_prefix(ada_name, part_kind)
            widget_style_name = widget_style_const_name(ada_name, part_kind)

            lines.append(f"   --  Complete widget style for {widget_name}{part_suffix}")
            lines.append(f"   {widget_style_name} : constant Widget_Style :=")

            if part_group.base_rule:
                lines.append(f"     From ({name_prefix}_Base_Style)")
            else:
                lines.append(f"     Create")

            for rule in part_group.state_rules:
                var_name = rule._var_name  # type: ignore
                selector_ada = generate_selector_ada(rule.selector)
                lines.append(f"     .On ({selector_ada}, {var_name})")

            lines.append(f"     .Build;")
            lines.append(f"")

        # Bundle all known parts for one-call Set_Part_Styles.
        lines.append(f"   --  Part styles bundle for {widget_name}")
        lines.append(f"   {ada_name}_Part_Styles : constant Part_Style_Array := [")
        for part_kind, _part_group in part_items:
            style_name = widget_style_const_name(ada_name, part_kind)
            lines.append(
                f"      {part_kind} => (Style => {style_name}, Enabled => True),"
            )
        lines.append(f"      others => <>")
        lines.append(f"   ];")
        lines.append(f"")
    
    lines.append(f"end {package_name};")
    
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Convert CSS to Ada Widget Styles"
    )
    parser.add_argument("input", help="Input CSS file")
    parser.add_argument("output", help="Output Ada file")
    parser.add_argument(
        "--package-name", "-p",
        default="Generated_Styles",
        help="Ada package name (default: Generated_Styles)"
    )
    
    args = parser.parse_args()
    
    # Read CSS
    try:
        with open(args.input, 'r') as f:
            css_content = f.read()
    except IOError as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Parse
    rules = parse_css(css_content)
    if not rules:
        print("No rules found in CSS file", file=sys.stderr)
        sys.exit(1)
    
    print(f"Parsed {len(rules)} CSS rules")
    
    # Group by widget
    groups = group_rules_by_widget(rules)
    print(f"Found {len(groups)} widgets: {', '.join(groups.keys())}")
    
    # Debug: print parsed selectors
    for widget_name, group in groups.items():
        print(f"  {widget_name}:")
        for part_kind, part_group in sorted(group.parts.items()):
            part_desc = "main" if part_kind == "Main_Part" else part_kind
            if part_group.base_rule:
                print(f"    {part_desc} base: {len(part_group.base_rule.properties)} properties")
            for rule in part_group.state_rules:
                print(
                    f"    {part_desc} widget_states={[s.value for s in rule.selector.widget_states]}, "
                    f"widget_negated={[s.value for s in rule.selector.widget_negated_states]}, "
                    f"part_states={[s.value for s in rule.selector.part_states]}, "
                    f"part_negated={[s.value for s in rule.selector.part_negated_states]}"
                )
    
    # Generate Ada
    ada_code = generate_ada_package(groups, args.package_name)
    
    # Write output
    try:
        with open(args.output, 'w') as f:
            f.write(ada_code)
    except IOError as e:
        print(f"Error writing output file: {e}", file=sys.stderr)
        sys.exit(1)
    
    print(f"Generated {args.output}")


if __name__ == "__main__":
    main()
