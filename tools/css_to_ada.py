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

from css_spec import (
    SUPPORTED_PARTS,
    all_supported_properties,
    canonical_property_name,
    is_supported_property,
    property_validator,
)


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
    "silver": "Silver",
    "gray": "Gray",
    "white": "White",
    "maroon": "Maroon",
    "red": "Red",
    "purple": "Purple",
    "fuchsia": "Fuchsia",
    "green": "Green",
    "lime": "Lime",
    "olive": "Olive",
    "yellow": "Yellow",
    "navy": "Navy",
    "blue": "Blue",
    "teal": "Teal",
    "aqua": "Aqua",
    "aliceblue": "Alice_Blue",
    "antiquewhite": "Antique_White",
    "aquamarine": "Aqua_Marine",
    "azure": "Azure",
    "beige": "Beige",
    "bisque": "Bisque",
    "blanchedalmond": "Blanched_Almond",
    "blueviolet": "Blue_Violet",
    "brown": "Brown",
    "burlywood": "Burly_Wood",
    "cadetblue": "Cadet_Blue",
    "chartreuse": "Chartreuse",
    "chocolate": "Chocolate",
    "coral": "Coral",
    "cornflowerblue": "Cornflower_Blue",
    "cornsilk": "Corn_Silk",
    "crimson": "Crimson",
    "cyan": "Cyan",
    "darkblue": "Dark_Blue",
    "darkcyan": "Dark_Cyan",
    "darkgoldenrod": "Dark_Goldenrod",
    "darkgray": "Dark_Gray",
    "darkgreen": "Dark_Green",
    "darkgrey": "Dark_Gray",
    "darkkhaki": "Dark_Khaki",
    "darkmagenta": "Dark_Magenta",
    "darkolivegreen": "Dark_Olive_Green",
    "darkorange": "Dark_Orange",
    "darkorchid": "Dark_Orchid",
    "darkred": "Dark_Red",
    "darksalmon": "Dark_Salmon",
    "darkseagreen": "Dark_Sea_Green",
    "darkslateblue": "Dark_Slate_Blue",
    "darkslategray": "Dark_Slate_Gray",
    "darkslategrey": "Dark_Slate_Grey",
    "darkturquoise": "Dark_Turquoise",
    "darkviolet": "Dark_Violet",
    "deeppink": "Deep_Pink",
    "deepskyblue": "Deep_Sky_Blue",
    "dimgray": "Dim_Gray",
    "dimgrey": "Dim_Grey",
    "dodgerblue": "Dodger_Blue",
    "firebrick": "Fire_Brick",
    "floralwhite": "Floral_White",
    "forestgreen": "Forest_Green",
    "gainsboro": "Gainsboro",
    "ghostwhite": "Ghost_White",
    "gold": "Gold",
    "goldenrod": "Goldenrod",
    "greenyellow": "Green_Yellow",
    "grey": "Gray",
    "honeydew": "Honey_Dew",
    "hotpink": "Hot_Pink",
    "indianred": "Indian_Red",
    "indigo": "Indigo",
    "ivory": "Ivory",
    "khaki": "Khaki",
    "lavender": "Lavender",
    "lavenderblush": "Lavender_Blush",
    "lawngreen": "Lawn_Green",
    "lemonchiffon": "Lemon_Chiffon",
    "lightblue": "Light_Blue",
    "lightcoral": "Light_Coral",
    "lightcyan": "Light_Cyan",
    "lightgoldenrodyellow": "Light_Goldenrod_Yellow",
    "lightgray": "Light_Gray",
    "lightgreen": "Light_Green",
    "lightgrey": "Light_Gray",
    "lightpink": "Light_Pink",
    "lightsalmon": "Light_Salmon",
    "lightseagreen": "Light_Sea_Green",
    "lightskyblue": "Light_Sky_Blue",
    "lightslategray": "Light_Slate_Gray",
    "lightslategrey": "Light_Slate_Grey",
    "lightsteelblue": "Light_Steel_Blue",
    "lightyellow": "Light_Yellow",
    "limegreen": "Lime_Green",
    "linen": "Linen",
    "magenta": "Magenta",
    "mediumaquamarine": "Medium_Aqua_Marine",
    "mediumblue": "Medium_Blue",
    "mediumorchid": "Medium_Orchid",
    "mediumpurple": "Medium_Purple",
    "mediumseagreen": "Medium_Sea_Green",
    "mediumslateblue": "Medium_Slate_Blue",
    "mediumspringgreen": "Medium_Spring_Green",
    "mediumturquoise": "Medium_Turquoise",
    "mediumvioletred": "Medium_Violet_Red",
    "midnightblue": "Midnight_Blue",
    "mintcream": "Mint_Cream",
    "mistyrose": "Misty_Rose",
    "moccasin": "Moccasin",
    "navajowhite": "Navajo_White",
    "oldlace": "Old_Lace",
    "olivedrab": "Olive_Drab",
    "orange": "Orange",
    "orangered": "Orange_Red",
    "orchid": "Orchid",
    "palegoldenrod": "Pale_Goldenrod",
    "palegreen": "Pale_Green",
    "paleturquoise": "Pale_Turquoise",
    "palevioletred": "Pale_Violet_Red",
    "papayawhip": "Papaya_Whip",
    "peachpuff": "Peach_Puff",
    "peru": "Peru",
    "pink": "Pink",
    "plum": "Plum",
    "powderblue": "Powder_Blue",
    "rosybrown": "Rosy_Brown",
    "royalblue": "Royal_Blue",
    "saddlebrown": "Saddle_Brown",
    "salmon": "Salmon",
    "sandybrown": "Sandy_Brown",
    "seagreen": "Sea_Green",
    "seashell": "Sea_Shell",
    "sienna": "Sienna",
    "skyblue": "Sky_Blue",
    "slateblue": "Slate_Blue",
    "slategray": "Slate_Gray",
    "slategrey": "Slate_Grey",
    "snow": "Snow",
    "springgreen": "Spring_Green",
    "steelblue": "Steel_Blue",
    "tan": "Tan",
    "thistle": "Thistle",
    "tomato": "Tomato",
    "turquoise": "Turquoise",
    "violet": "Violet",
    "wheat": "Wheat",
    "whitesmoke": "White_Smoke",
    "yellowgreen": "Yellow_Green",
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
OUTLINE_STYLE_MAP = {
    "none": "Outline_None",
    "solid": "Outline_Solid",
    "dashed": "Outline_Dashed",
    "dotted": "Outline_Dotted",
}

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

# CSS list-style-type values to Ada
LIST_STYLE_TYPE_MAP = {
    "none": "List_Style_None",
    "disc": "List_Style_Disc",
    "circle": "List_Style_Circle",
    "square": "List_Style_Square",
    "decimal": "List_Style_Decimal",
}

# CSS list-style-position values to Ada
LIST_STYLE_POSITION_MAP = {
    "outside": "List_Outside",
    "inside": "List_Inside",
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
    selector_type: str = "class"  # "class", "id", "tag"
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
class CssDiagnostic:
    code: str
    message: str
    selector: str = ""
    property_name: str = ""
    property_value: str = ""


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
    selector_type: str = "class"
    parts: dict[str, PartStyleGroup] = field(default_factory=dict)


def parse_length(value: str) -> Optional[ParsedLength]:
    """Parse a CSS length value like '10px', '1.5em', '50%'"""
    value = value.strip().lower()
    
    if value == "0":
        return ParsedLength(0.0, "Px")
    
    match = re.match(r'^(-?\d*\.?\d+)(px|em|rem|%|dip|dp|vw|vh)?$', value)
    if not match:
        return None
    
    amount = float(match.group(1))
    unit_str = match.group(2) or "px"
    
    unit_map = {
        "px": "Px",
        "dip": "Dip",
        "dp": "Dip",
        "em": "Em",
        "rem": "Root_Em",
        "%": "Pct",
        "vw": "Vw",
        "vh": "Vh",
    }
    
    unit = unit_map.get(unit_str, "Px")
    return ParsedLength(amount, unit)

MAX_GRID_TRACKS = 16


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


def _parse_one_track_token(token: str) -> Optional[tuple[str, float]]:
    """Parse a single size token into (kind, value).
    kind is 'auto', 'fr', or 'px'.  Returns None on unknown syntax."""
    t = token.strip().lower()
    if t == "auto":
        return ("auto", 0.0)
    if t.endswith("fr"):
        try:
            v = float(t[:-2])
            return ("fr", v) if v > 0.0 else None
        except ValueError:
            return None
    if t.endswith("px"):
        try:
            v = float(t[:-2])
            return ("px", v) if v >= 0.0 else None
        except ValueError:
            return None
    return None


def _tokenize_track_list(value: str) -> Optional[list[str]]:
    """Split a track-list value into tokens, respecting repeat(...) as one token."""
    tokens: list[str] = []
    i = 0
    while i < len(value):
        if value[i] in (" ", "\t"):
            i += 1
            continue
        start = i
        depth = 0
        while i < len(value):
            c = value[i]
            if c == "(":
                depth += 1
            elif c == ")":
                if depth > 0:
                    depth -= 1
                if depth == 0:
                    i += 1  # include ')'
                    break
            elif c in (" ", "\t") and depth == 0:
                break
            i += 1
        tok = value[start:i].strip()
        if tok:
            tokens.append(tok)
    return tokens if tokens else None


def parse_grid_track_list(value: str) -> Optional[list[tuple[str, float]]]:
    """Parse grid-template-columns into a list of (kind, value) specs.

    Rules:
    - Plain integer N  → N copies of ("fr", 1.0)  (legacy equal-column semantics)
    - repeat(N, size)  → N copies of the parsed size token
    - Space-separated  → one spec per token
    - Returns None when count > MAX_GRID_TRACKS or on parse error (caller falls
      back to parse_grid_track_count for a count-only Grid_Columns field).
    """
    v = value.strip().lower()
    if not v or v == "none":
        return None

    # Legacy: plain integer N → N equal fr(1.0) tracks
    if re.match(r'^\d+$', v):
        n = int(v)
        if n <= 0 or n > MAX_GRID_TRACKS:
            return None
        return [("fr", 1.0)] * n

    raw_tokens = _tokenize_track_list(v)
    if not raw_tokens:
        return None

    result: list[tuple[str, float]] = []
    for tok in raw_tokens:
        m = re.match(r'^repeat\(\s*(\d+)\s*,\s*(.*)\)$', tok)
        if m:
            rep_count = int(m.group(1))
            size_tok = m.group(2).strip()
            spec = _parse_one_track_token(size_tok)
            if spec is None or rep_count <= 0:
                return None
            result.extend([spec] * rep_count)
        else:
            spec = _parse_one_track_token(tok)
            if spec is None:
                return None
            result.append(spec)

    if not result or len(result) > MAX_GRID_TRACKS:
        return None
    return result


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


def parse_selector_with_diagnostics(
    selector_str: str,
) -> tuple[Optional[ParsedSelector], list[CssDiagnostic]]:
    """Parse selectors like '.button:hover::label' and '.button::label:hover'."""
    diagnostics: list[CssDiagnostic] = []
    selector_str = selector_str.strip()
    raw_selector = selector_str

    selector_type = "tag"
    if selector_str.startswith('.'):
        selector_type = "class"
        selector_str = selector_str[1:]
    elif selector_str.startswith('#'):
        selector_type = "id"
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
        if part_key not in SUPPORTED_PARTS:
            diagnostics.append(
                CssDiagnostic(
                    code="unsupported-part",
                    message=(
                        f"Unsupported part '{part_key}'. "
                        f"Supported: {', '.join(sorted(SUPPORTED_PARTS.keys()))}"
                    ),
                    selector=raw_selector,
                )
            )
            return None, diagnostics
        part_kind = SUPPORTED_PARTS[part_key]
        part_scope_enabled = part_kind != "Main_Part"
    else:
        first_colon = selector_str.find(":")
        if first_colon == -1:
            name = selector_str.strip()
        else:
            name = selector_str[:first_colon].strip()
            widget_pseudo_part = selector_str[first_colon:]

    if not name:
        return None, diagnostics

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
        selector_type=selector_type,
        part_kind=part_kind,
        widget_states=widget_states,
        widget_negated_states=widget_negated_states,
        part_states=part_states,
        part_negated_states=part_negated_states,
    ), diagnostics


def parse_selector(selector_str: str) -> Optional[ParsedSelector]:
    selector, _ = parse_selector_with_diagnostics(selector_str)
    return selector


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


@dataclass
class ParsedObjectPosition:
    kind: str  # "keyword" | "length"
    h_keyword: Optional[str] = None
    v_keyword: Optional[str] = None
    x_offset: Optional[ParsedLength] = None
    y_offset: Optional[ParsedLength] = None


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


OBJECT_POSITION_KEYWORD_MAP = {
    "left": "Pos_Left",
    "center": "Pos_Center",
    "right": "Pos_Right",
    "top": "Pos_Top",
    "bottom": "Pos_Bottom",
}

OBJECT_POSITION_HORIZONTAL = {"left", "center", "right"}
OBJECT_POSITION_VERTICAL = {"top", "center", "bottom"}


def parse_object_position(value: str) -> Optional[ParsedObjectPosition]:
    """Parse a subset of object-position values.

    Supported:
    - center
    - keyword pairs (left/right/center + top/bottom/center, any order)
    - one/two length or percent offsets
    Rejected:
    - mixed keyword + length forms
    - advanced edge-offset syntax
    """
    tokens = split_css_whitespace_tokens(value.strip().lower())
    if not tokens:
        return None

    def keyword_position(token: str) -> Optional[ParsedObjectPosition]:
        if token in OBJECT_POSITION_HORIZONTAL:
            return ParsedObjectPosition(
                kind="keyword",
                h_keyword=OBJECT_POSITION_KEYWORD_MAP[token],
                v_keyword="Pos_Center",
            )
        if token in OBJECT_POSITION_VERTICAL:
            return ParsedObjectPosition(
                kind="keyword",
                h_keyword="Pos_Center",
                v_keyword=OBJECT_POSITION_KEYWORD_MAP[token],
            )
        return None

    if len(tokens) == 1:
        kw = keyword_position(tokens[0])
        if kw is not None:
            return kw
        x = parse_length(tokens[0])
        if x is not None:
            return ParsedObjectPosition(
                kind="length",
                x_offset=x,
                y_offset=ParsedLength(50.0, "Pct"),
            )
        return None

    if len(tokens) == 2:
        x = parse_length(tokens[0])
        y = parse_length(tokens[1])
        if x is not None and y is not None:
            return ParsedObjectPosition(
                kind="length",
                x_offset=x,
                y_offset=y,
            )

        h_keyword = None
        v_keyword = None
        for token in tokens:
            if token in {"left", "right"}:
                if h_keyword is not None:
                    return None
                h_keyword = OBJECT_POSITION_KEYWORD_MAP[token]
            elif token in {"top", "bottom"}:
                if v_keyword is not None:
                    return None
                v_keyword = OBJECT_POSITION_KEYWORD_MAP[token]
            elif token == "center":
                if h_keyword is None:
                    h_keyword = "Pos_Center"
                elif v_keyword is None:
                    v_keyword = "Pos_Center"
                else:
                    return None
            else:
                return None

        if h_keyword is None:
            h_keyword = "Pos_Center"
        if v_keyword is None:
            v_keyword = "Pos_Center"
        return ParsedObjectPosition(
            kind="keyword",
            h_keyword=h_keyword,
            v_keyword=v_keyword,
        )

    return None


def ada_string_literal(value: str) -> str:
    """Generate an Ada string literal with escaped quotes."""
    return '"' + value.replace('"', '""') + '"'


def parse_css_quoted_string(value: str) -> Optional[str]:
    """Parse a single/double quoted CSS string token."""
    v = value.strip()
    if len(v) < 2:
        return None
    if (v[0] == '"' and v[-1] == '"') or (v[0] == "'" and v[-1] == "'"):
        return v[1:-1]
    return None


def parse_css_url_function(value: str) -> Optional[str]:
    """Parse url(...) and return unquoted URI content."""
    v = value.strip()
    if len(v) < 5:
        return None
    if not v.lower().startswith("url(") or not v.endswith(")"):
        return None
    inner = v[4:-1].strip()
    if not inner:
        return None
    quoted = parse_css_quoted_string(inner)
    return quoted if quoted is not None else inner


def split_css_whitespace_tokens(value: str) -> list[str]:
    """Split by whitespace outside quotes and parentheses."""
    tokens: list[str] = []
    current: list[str] = []
    quote: Optional[str] = None
    paren_depth = 0

    for ch in value:
        if quote is None:
            if ch in ('"', "'"):
                quote = ch
                current.append(ch)
            elif ch == '(':
                paren_depth += 1
                current.append(ch)
            elif ch == ')':
                if paren_depth > 0:
                    paren_depth -= 1
                current.append(ch)
            elif ch.isspace() and paren_depth == 0:
                if current:
                    tok = "".join(current).strip()
                    if tok:
                        tokens.append(tok)
                    current = []
            else:
                current.append(ch)
        else:
            current.append(ch)
            if ch == quote:
                quote = None

    if current:
        tok = "".join(current).strip()
        if tok:
            tokens.append(tok)

    return tokens


def parse_list_style_shorthand(value: str) -> dict[str, str]:
    """Parse list-style shorthand into type/image/position components."""
    result: dict[str, str] = {}

    for tok in split_css_whitespace_tokens(value):
        low = tok.lower()
        if low in LIST_STYLE_POSITION_MAP:
            result["position"] = low
            continue

        if low == "none":
            if "type" not in result and "image" not in result:
                result["type"] = "none"
                result["image"] = "none"
            elif "type" not in result:
                result["type"] = "none"
            elif "image" not in result:
                result["image"] = "none"
            continue

        if parse_css_url_function(tok) is not None:
            result["image"] = tok
            continue

        if low in LIST_STYLE_TYPE_MAP or parse_css_quoted_string(tok) is not None:
            result["type"] = tok

    return result


def parse_border_shorthand_components(
    value: str,
) -> tuple[Optional[ParsedLength], Optional[str], Optional[ParsedColor]]:
    """Parse a permissive border shorthand into (width, style, color)."""
    width: Optional[ParsedLength] = None
    style: Optional[str] = None
    color: Optional[ParsedColor] = None

    for tok in split_css_whitespace_tokens(value):
        low = tok.lower()
        if low in BORDER_STYLE_MAP:
            style = BORDER_STYLE_MAP[low]
            continue

        parsed_width = parse_length(tok)
        if parsed_width is not None:
            width = parsed_width
            continue

        parsed_color = parse_color(tok)
        if parsed_color is not None:
            color = parsed_color

    return width, style, color


def set_css_property(properties: dict[str, str], name: str, value: str) -> None:
    """Set/override a CSS property while preserving declaration order semantics."""
    # Python dict updates keep the original key position. For CSS cascade semantics
    # (especially shorthand/longhand interactions), move existing keys to the end
    # when overridden so later declarations are emitted later.
    if name in properties:
        del properties[name]
    properties[name] = value


def merge_css_properties(target: dict[str, str], source: dict[str, str]) -> None:
    """Merge properties into target, preserving source declaration order."""
    for prop_name, prop_value in source.items():
        set_css_property(target, prop_name, prop_value)


def _is_float(value: str) -> bool:
    try:
        float(value)
        return True
    except ValueError:
        return False


def _is_int(value: str) -> bool:
    try:
        int(value)
        return True
    except ValueError:
        return False


def _validate_border_or_outline_shorthand(
    value: str,
    style_map: dict[str, str],
) -> bool:
    tokens = split_css_whitespace_tokens(value)
    if not tokens:
        return False

    any_valid = False
    for token in tokens:
        if token.lower() in style_map:
            any_valid = True
            continue
        if parse_length(token) is not None:
            any_valid = True
            continue
        if parse_color(token) is not None:
            any_valid = True
            continue
        return False
    return any_valid


def _validate_list_style_shorthand(value: str) -> bool:
    tokens = split_css_whitespace_tokens(value)
    if not tokens:
        return False

    any_valid = False
    for token in tokens:
        low = token.lower()
        if low in LIST_STYLE_POSITION_MAP:
            any_valid = True
            continue
        if low == "none":
            any_valid = True
            continue
        if parse_css_url_function(token) is not None:
            any_valid = True
            continue
        if low in LIST_STYLE_TYPE_MAP or parse_css_quoted_string(token) is not None:
            any_valid = True
            continue
        return False
    return any_valid


def validate_property_value(property_name: str, value: str) -> bool:
    validator = property_validator(property_name)
    if validator is None:
        return False

    low = value.strip().lower()

    if validator == "color":
        return parse_color(value) is not None
    if validator == "url-or-none":
        return low == "none" or parse_css_url_function(value) is not None
    if validator == "length":
        return parse_length(value) is not None
    if validator == "inset":
        return low == "auto" or parse_length(value) is not None
    if validator == "box-1-4-length":
        lengths = parse_box_values(value)
        return lengths is not None and 1 <= len(lengths) <= 4
    if validator == "border-style":
        return low in BORDER_STYLE_MAP
    if validator == "border-shorthand":
        return _validate_border_or_outline_shorthand(value, BORDER_STYLE_MAP)
    if validator == "width":
        return low in {"auto", "min-content", "max-content", "fit-content"} or parse_length(value) is not None
    if validator == "height":
        return low == "auto" or parse_length(value) is not None
    if validator == "font-weight":
        return low in FONT_WEIGHT_MAP
    if validator == "font-style":
        return low in FONT_STYLE_MAP
    if validator == "text-align":
        return low in TEXT_ALIGN_MAP
    if validator == "vertical-align":
        return low in VERTICAL_ALIGN_MAP
    if validator == "text-decoration":
        return low in TEXT_DECORATION_MAP
    if validator == "white-space":
        return low in WHITE_SPACE_MAP
    if validator == "text-overflow":
        return low in TEXT_OVERFLOW_MAP
    if validator == "text-wrap-mode":
        return low in TEXT_WRAP_MODE_MAP
    if validator == "line-height":
        return (
            low == "normal"
            or _is_float(value)
            or parse_length(value) is not None
        )
    if validator == "object-fit":
        return low in OBJECT_FIT_MAP
    if validator == "object-position":
        return parse_object_position(value) is not None
    if validator == "list-style-type":
        return low in LIST_STYLE_TYPE_MAP or parse_css_quoted_string(value) is not None
    if validator == "list-style-position":
        return low in LIST_STYLE_POSITION_MAP
    if validator == "list-style-shorthand":
        return _validate_list_style_shorthand(value)
    if validator == "number":
        return _is_float(value)
    if validator == "int":
        return _is_int(value)
    if validator == "overflow":
        return low in OVERFLOW_MAP
    if validator == "cursor":
        return low in CURSOR_MAP
    if validator == "visibility":
        return low in VISIBILITY_MAP
    if validator == "display":
        return low in DISPLAY_MAP
    if validator == "position":
        return low in POSITION_MAP
    if validator == "flex-direction":
        return low in FLEX_DIRECTION_MAP
    if validator == "flex-wrap":
        return low in FLEX_WRAP_MAP
    if validator == "justify-content":
        return low in JUSTIFY_CONTENT_MAP
    if validator == "align-items":
        return low in ALIGN_ITEMS_MAP
    if validator == "align-self":
        return low in ALIGN_SELF_MAP
    if validator == "align-content":
        return low in ALIGN_CONTENT_MAP
    if validator == "gap":
        lengths = parse_box_values(value)
        return lengths is not None and len(lengths) >= 1
    if validator == "flex-basis":
        return low in {"auto", "content"} or parse_length(value) is not None
    if validator == "grid-template-columns":
        return (
            parse_grid_track_list(value) is not None
            or parse_grid_track_count(value) is not None
        )
    if validator == "grid-template-rows":
        return parse_grid_track_count(value) is not None
    if validator == "grid-placement":
        if low == "auto":
            return True
        start, span = parse_grid_placement(value)
        return start is not None or span is not None
    if validator == "box-shadow":
        return low == "none" or parse_box_shadow(value) is not None
    if validator == "outline-style":
        return low in OUTLINE_STYLE_MAP
    if validator == "outline-shorthand":
        return _validate_border_or_outline_shorthand(value, OUTLINE_STYLE_MAP)
    if validator == "transition":
        return low == "none" or parse_transition(value) is not None
    return False


def parse_css_with_diagnostics(css_content: str) -> tuple[list[ParsedRule], list[CssDiagnostic]]:
    """Parse CSS content into rules and diagnostics."""
    rules: list[ParsedRule] = []
    diagnostics: list[CssDiagnostic] = []

    # Remove comments
    css_content = re.sub(r'/\*.*?\*/', '', css_content, flags=re.DOTALL)

    # Find all rules
    rule_pattern = re.compile(r'([^{}]+)\{([^{}]*)\}', re.DOTALL)

    for match in rule_pattern.finditer(css_content):
        selector_str = match.group(1).strip()
        properties_str = match.group(2).strip()

        # Handle multiple selectors separated by comma
        for single_selector in selector_str.split(','):
            selector_text = single_selector.strip()
            selector, selector_diagnostics = parse_selector_with_diagnostics(selector_text)
            diagnostics.extend(selector_diagnostics)
            if selector is None:
                continue

            # Parse properties
            properties: dict[str, str] = {}
            for prop_match in re.finditer(r'([\w-]+)\s*:\s*([^;]+);?', properties_str):
                raw_name = prop_match.group(1).strip().lower()
                prop_value = prop_match.group(2).strip()

                if not is_supported_property(raw_name):
                    diagnostics.append(
                        CssDiagnostic(
                            code="unsupported-property",
                            message=f"Unsupported property '{raw_name}'",
                            selector=selector_text,
                            property_name=raw_name,
                            property_value=prop_value,
                        )
                    )
                    set_css_property(properties, raw_name, prop_value)
                    continue

                canonical_name = canonical_property_name(raw_name)
                set_css_property(properties, canonical_name, prop_value)

                if not validate_property_value(raw_name, prop_value):
                    diagnostics.append(
                        CssDiagnostic(
                            code="invalid-property-value",
                            message=f"Invalid value for '{raw_name}'",
                            selector=selector_text,
                            property_name=raw_name,
                            property_value=prop_value,
                        )
                    )

            rules.append(ParsedRule(selector=selector, properties=properties))

    return rules, diagnostics


def parse_css(css_content: str) -> list[ParsedRule]:
    """Compatibility wrapper: parse CSS content into rules only."""
    rules, _ = parse_css_with_diagnostics(css_content)
    return rules


def group_rules_by_widget(rules: list[ParsedRule]) -> dict[str, WidgetStyleGroup]:
    """Group rules by selector type + widget name"""
    groups: dict[str, WidgetStyleGroup] = {}
    
    for rule in rules:
        name = rule.selector.name
        selector_type = rule.selector.selector_type
        part_kind = rule.selector.part_kind
        key = f"{selector_type}:{name}"
        
        if key not in groups:
            groups[key] = WidgetStyleGroup(name=name, selector_type=selector_type)
        
        group = groups[key]
        if part_kind not in group.parts:
            group.parts[part_kind] = PartStyleGroup(part_kind=part_kind)
        part_group = group.parts[part_kind]
        
        # If no states, it's the base rule
        if (not rule.selector.widget_states and
            not rule.selector.widget_negated_states and
            not rule.selector.part_states and
            not rule.selector.part_negated_states):
            if part_group.base_rule is None:
                part_group.base_rule = rule
            else:
                merge_css_properties(part_group.base_rule.properties, rule.properties)
        else:
            state_key = rule.selector.get_unique_key()
            existing_rule = next(
                (
                    existing
                    for existing in part_group.state_rules
                    if existing.selector.get_unique_key() == state_key
                ),
                None,
            )

            if existing_rule is None:
                part_group.state_rules.append(rule)
            else:
                merge_css_properties(existing_rule.properties, rule.properties)

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
        alpha = color.a if color.a is not None else 1.0
        return f"RGBA ({color.r}, {color.g}, {color.b}, {format_float(alpha)})"
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


def box_lengths_to_four(lengths: list[ParsedLength]) -> list[ParsedLength]:
    """Expand 1-4 CSS box shorthand lengths to [top, right, bottom, left]."""
    if len(lengths) == 1:
        return [lengths[0], lengths[0], lengths[0], lengths[0]]
    if len(lengths) == 2:
        return [lengths[0], lengths[1], lengths[0], lengths[1]]
    if len(lengths) == 3:
        return [lengths[0], lengths[1], lengths[2], lengths[1]]
    if len(lengths) >= 4:
        return [lengths[0], lengths[1], lengths[2], lengths[3]]
    z = ParsedLength(0.0, "Px")
    return [z, z, z, z]


def generate_box_from_four_ada(sides: list[ParsedLength]) -> str:
    """Generate CSS_Box Ada expression from [top, right, bottom, left]."""
    return (
        f"CSS_Box ({generate_length_ada(sides[0])}, "
        f"{generate_length_ada(sides[1])}, "
        f"{generate_length_ada(sides[2])}, "
        f"{generate_length_ada(sides[3])})"
    )


def four_sides_to_box_lengths(sides: list[ParsedLength]) -> list[ParsedLength]:
    """Compress [top, right, bottom, left] to shortest 1-4 shorthand form."""
    top, right, bottom, left = sides
    if top == right == bottom == left:
        return [top]
    if top == bottom and right == left:
        return [top, right]
    if right == left:
        return [top, right, bottom]
    return [top, right, bottom, left]


def generate_border_style_from_four_ada(styles: list[str]) -> str:
    if styles[0] == styles[1] == styles[2] == styles[3]:
        return f"Border_Style ({styles[0]})"
    return (
        f"Border_Style ({styles[0]}, "
        f"{styles[1]}, "
        f"{styles[2]}, "
        f"{styles[3]})"
    )


def generate_border_color_from_four_ada(colors: list[ParsedColor]) -> str:
    top = generate_color_ada(colors[0])
    right = generate_color_ada(colors[1])
    bottom = generate_color_ada(colors[2])
    left = generate_color_ada(colors[3])
    if top == right == bottom == left:
        return f"Border_Color ({top})"
    return f"Border_Color ({top}, {right}, {bottom}, {left})"


def generate_border_width_ada(lengths: list[ParsedLength]) -> str:
    """Generate Ada code for border-width"""
    if len(lengths) == 1:
        return f"Border_Width ({generate_length_ada(lengths[0])})"
    elif len(lengths) == 2:
        return f"Border_Width ({generate_length_ada(lengths[0])}, {generate_length_ada(lengths[1])})"
    elif len(lengths) == 3:
        return (
            f"Border_Width ({generate_length_ada(lengths[0])}, "
            f"{generate_length_ada(lengths[1])}, "
            f"{generate_length_ada(lengths[2])}, "
            f"{generate_length_ada(lengths[1])})"
        )
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
    elif len(lengths) == 3:
        return (
            f"Radius ({generate_length_ada(lengths[0])}, "
            f"{generate_length_ada(lengths[1])}, "
            f"{generate_length_ada(lengths[2])}, "
            f"{generate_length_ada(lengths[1])})"
        )
    elif len(lengths) >= 4:
        return (f"Radius ({generate_length_ada(lengths[0])}, "
                f"{generate_length_ada(lengths[1])}, "
                f"{generate_length_ada(lengths[2])}, "
                f"{generate_length_ada(lengths[3])})")
    return "Radius (Zero_Length)"


GENERATED_PROPERTY_NAMES = {
    "color",
    "background-color",
    "background-image",
    "padding",
    "padding-top",
    "padding-right",
    "padding-bottom",
    "padding-left",
    "margin",
    "margin-top",
    "margin-right",
    "margin-bottom",
    "margin-left",
    "border-top",
    "border-right",
    "border-bottom",
    "border-left",
    "border-width",
    "border-top-width",
    "border-right-width",
    "border-bottom-width",
    "border-left-width",
    "border-color",
    "border-top-color",
    "border-right-color",
    "border-bottom-color",
    "border-left-color",
    "border-style",
    "border-top-style",
    "border-right-style",
    "border-bottom-style",
    "border-left-style",
    "border",
    "border-radius",
    "border-top-left-radius",
    "border-top-right-radius",
    "border-bottom-right-radius",
    "border-bottom-left-radius",
    "width",
    "height",
    "min-width",
    "max-width",
    "min-height",
    "max-height",
    "font-size",
    "font-weight",
    "font-style",
    "text-align",
    "vertical-align",
    "text-decoration",
    "list-style-type",
    "list-style-image",
    "list-style-position",
    "list-style",
    "white-space",
    "text-overflow",
    "text-wrap-mode",
    "line-height",
    "object-fit",
    "object-position",
    "opacity",
    "overflow",
    "overflow-x",
    "overflow-y",
    "cursor",
    "visibility",
    "display",
    "position",
    "top",
    "right",
    "bottom",
    "left",
    "flex-direction",
    "flex-wrap",
    "justify-content",
    "align-items",
    "align-self",
    "align-content",
    "gap",
    "row-gap",
    "column-gap",
    "flex-grow",
    "flex-shrink",
    "flex-basis",
    "order",
    "grid-template-columns",
    "grid-template-rows",
    "grid-column",
    "grid-row",
    "box-shadow",
    "outline-width",
    "outline-color",
    "outline-style",
    "outline-offset",
    "outline",
    "transition",
}


def assert_property_spec_consistency() -> None:
    canonical_in_spec = {canonical_property_name(p) for p in all_supported_properties()}
    missing_in_generator = canonical_in_spec - GENERATED_PROPERTY_NAMES
    missing_in_spec = GENERATED_PROPERTY_NAMES - canonical_in_spec
    if missing_in_generator or missing_in_spec:
        errors: list[str] = []
        if missing_in_generator:
            errors.append(
                "spec-only properties: " + ", ".join(sorted(missing_in_generator))
            )
        if missing_in_spec:
            errors.append(
                "generator-only properties: " + ", ".join(sorted(missing_in_spec))
            )
        raise RuntimeError("CSS spec mismatch: " + "; ".join(errors))


def generate_style_rules_ada(properties: dict[str, str], indent: str = "      ") -> list[str]:
    """Generate Ada Style_Rules record fields from CSS properties"""
    fields = []
    padding_sides = None
    margin_sides = None
    border_width_sides = None
    border_style_sides = None
    border_color_sides = None
    border_radius_corners = None
    list_style_type = None
    list_style_image = None
    list_style_position = None
    overflow_x = None
    overflow_y = None
    edge_index = {"top": 0, "right": 1, "bottom": 2, "left": 3}
    corner_index = {
        "top-left": 0,
        "top-right": 1,
        "bottom-right": 2,
        "bottom-left": 3,
    }

    def ensure_padding_sides():
        nonlocal padding_sides
        if padding_sides is None:
            z = ParsedLength(0.0, "Px")
            padding_sides = [z, z, z, z]
        return padding_sides

    def ensure_margin_sides():
        nonlocal margin_sides
        if margin_sides is None:
            z = ParsedLength(0.0, "Px")
            margin_sides = [z, z, z, z]
        return margin_sides

    def ensure_border_width_sides():
        nonlocal border_width_sides
        if border_width_sides is None:
            z = ParsedLength(0.0, "Px")
            border_width_sides = [z, z, z, z]
        return border_width_sides

    def ensure_border_style_sides():
        nonlocal border_style_sides
        if border_style_sides is None:
            border_style_sides = ["None_Style", "None_Style", "None_Style", "None_Style"]
        return border_style_sides

    def ensure_border_color_sides():
        nonlocal border_color_sides
        if border_color_sides is None:
            c = ParsedColor(kind="named", name="Current_Color")
            border_color_sides = [c, c, c, c]
        return border_color_sides

    def ensure_border_radius_corners():
        nonlocal border_radius_corners
        if border_radius_corners is None:
            z = ParsedLength(0.0, "Px")
            border_radius_corners = [z, z, z, z]
        return border_radius_corners
    
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

        # Background image
        elif prop == "background-image":
            low = value.lower()
            if low == "none":
                ada_field = "Background_Image => Set_Bg_Image (No_Background_Image)"
            else:
                uri = parse_css_url_function(value)
                if uri is not None:
                    ada_field = f"Background_Image => Set_Bg_Image (Background_Image_URL ({ada_string_literal(uri)}))"

        # Padding
        elif prop == "padding":
            lengths = parse_box_values(value)
            if lengths:
                padding_sides = box_lengths_to_four(lengths)
        
        elif prop == "padding-top":
            length = parse_length(value)
            if length:
                ensure_padding_sides()[0] = length
        elif prop == "padding-right":
            length = parse_length(value)
            if length:
                ensure_padding_sides()[1] = length
        elif prop == "padding-bottom":
            length = parse_length(value)
            if length:
                ensure_padding_sides()[2] = length
        elif prop == "padding-left":
            length = parse_length(value)
            if length:
                ensure_padding_sides()[3] = length
        
        # Margin
        elif prop == "margin":
            lengths = parse_box_values(value)
            if lengths:
                margin_sides = box_lengths_to_four(lengths)
        elif prop == "margin-top":
            length = parse_length(value)
            if length:
                ensure_margin_sides()[0] = length
        elif prop == "margin-right":
            length = parse_length(value)
            if length:
                ensure_margin_sides()[1] = length
        elif prop == "margin-bottom":
            length = parse_length(value)
            if length:
                ensure_margin_sides()[2] = length
        elif prop == "margin-left":
            length = parse_length(value)
            if length:
                ensure_margin_sides()[3] = length
        
        # Border width
        elif prop == "border-width":
            lengths = parse_box_values(value)
            if lengths:
                border_width_sides = box_lengths_to_four(lengths)

        elif prop in ("border-top-width", "border-right-width", "border-bottom-width", "border-left-width"):
            length = parse_length(value)
            if length:
                side_name = prop[len("border-") : -len("-width")]
                ensure_border_width_sides()[edge_index[side_name]] = length
        
        # Border color
        elif prop == "border-color":
            color = parse_color(value)
            if color:
                border_color_sides = [color, color, color, color]

        elif prop in ("border-top-color", "border-right-color", "border-bottom-color", "border-left-color"):
            color = parse_color(value)
            if color:
                side_name = prop[len("border-") : -len("-color")]
                ensure_border_color_sides()[edge_index[side_name]] = color
        
        # Border style
        elif prop == "border-style":
            if value.lower() in BORDER_STYLE_MAP:
                style = BORDER_STYLE_MAP[value.lower()]
                border_style_sides = [style, style, style, style]

        elif prop in ("border-top-style", "border-right-style", "border-bottom-style", "border-left-style"):
            low = value.lower()
            if low in BORDER_STYLE_MAP:
                side_name = prop[len("border-") : -len("-style")]
                ensure_border_style_sides()[edge_index[side_name]] = BORDER_STYLE_MAP[low]
        
        # Border (shorthand)
        elif prop == "border":
            width, style, color = parse_border_shorthand_components(value)
            if width is not None:
                border_width_sides = [width, width, width, width]
            if style is not None:
                border_style_sides = [style, style, style, style]
            if color is not None:
                border_color_sides = [color, color, color, color]

        elif prop in ("border-top", "border-right", "border-bottom", "border-left"):
            width, style, color = parse_border_shorthand_components(value)
            side_name = prop[len("border-") :]
            idx = edge_index[side_name]
            if width is not None:
                ensure_border_width_sides()[idx] = width
            if style is not None:
                ensure_border_style_sides()[idx] = style
            if color is not None:
                ensure_border_color_sides()[idx] = color
        
        # Border radius
        elif prop == "border-radius":
            lengths = parse_box_values(value)
            if lengths:
                border_radius_corners = box_lengths_to_four(lengths)

        elif prop in (
            "border-top-left-radius",
            "border-top-right-radius",
            "border-bottom-right-radius",
            "border-bottom-left-radius",
        ):
            length = parse_length(value)
            if length:
                corner_name = prop[len("border-") : -len("-radius")]
                ensure_border_radius_corners()[corner_index[corner_name]] = length
        
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

        # List style longhands/shorthand
        elif prop == "list-style-type":
            low = value.lower()
            if low in LIST_STYLE_TYPE_MAP:
                list_style_type = f"(Kind => {LIST_STYLE_TYPE_MAP[low]})"
            else:
                marker = parse_css_quoted_string(value)
                if marker is not None:
                    list_style_type = f"List_String ({ada_string_literal(marker)})"

        elif prop == "list-style-image":
            low = value.lower()
            if low == "none":
                list_style_image = "No_List_Image"
            else:
                uri = parse_css_url_function(value)
                if uri is not None:
                    list_style_image = f"List_Image ({ada_string_literal(uri)})"

        elif prop == "list-style-position":
            low = value.lower()
            if low in LIST_STYLE_POSITION_MAP:
                list_style_position = LIST_STYLE_POSITION_MAP[low]

        elif prop == "list-style":
            parts = parse_list_style_shorthand(value)
            type_part = parts.get("type")
            if type_part is not None:
                low = type_part.lower()
                if low in LIST_STYLE_TYPE_MAP:
                    list_style_type = f"(Kind => {LIST_STYLE_TYPE_MAP[low]})"
                else:
                    marker = parse_css_quoted_string(type_part)
                    if marker is not None:
                        list_style_type = f"List_String ({ada_string_literal(marker)})"

            image_part = parts.get("image")
            if image_part is not None:
                if image_part.lower() == "none":
                    list_style_image = "No_List_Image"
                else:
                    uri = parse_css_url_function(image_part)
                    if uri is not None:
                        list_style_image = f"List_Image ({ada_string_literal(uri)})"

            pos_part = parts.get("position")
            if pos_part is not None and pos_part in LIST_STYLE_POSITION_MAP:
                list_style_position = LIST_STYLE_POSITION_MAP[pos_part]

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

        # Object position
        elif prop == "object-position":
            pos = parse_object_position(value)
            if pos:
                if pos.kind == "keyword":
                    ada_field = (
                        "Object_Position => Set "
                        f"(Object_Position ({pos.h_keyword}, {pos.v_keyword}))"
                    )
                else:
                    ada_field = (
                        "Object_Position => Set "
                        f"(Object_Position ({generate_length_ada(pos.x_offset)}, "
                        f"{generate_length_ada(pos.y_offset)}))"
                    )

        # Opacity
        elif prop == "opacity":
            try:
                val = float(value)
                ada_field = f"Opacity => Set ({format_float(val)})"
            except ValueError:
                pass

        # Overflow shorthand/longhands.
        # There is no standalone Overflow field in Style_Rules: shorthand writes both axes.
        elif prop == "overflow":
            overflow_val = OVERFLOW_MAP.get(value.lower())
            if overflow_val is not None:
                overflow_x = overflow_val
                overflow_y = overflow_val
            continue

        elif prop == "overflow-x":
            overflow_val = OVERFLOW_MAP.get(value.lower())
            if overflow_val is not None:
                overflow_x = overflow_val
            continue

        elif prop == "overflow-y":
            overflow_val = OVERFLOW_MAP.get(value.lower())
            if overflow_val is not None:
                overflow_y = overflow_val
            continue

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

        # Inset offsets (top/right/bottom/left)
        elif prop == "top":
            if value.lower() == "auto":
                ada_field = "Top => Set_Top (Auto_Inset)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Top => Set_Top (Inset ({generate_length_ada(length)}))"
        elif prop == "right":
            if value.lower() == "auto":
                ada_field = "Right => Set_Right (Auto_Inset)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Right => Set_Right (Inset ({generate_length_ada(length)}))"
        elif prop == "bottom":
            if value.lower() == "auto":
                ada_field = "Bottom => Set_Bottom (Auto_Inset)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Bottom => Set_Bottom (Inset ({generate_length_ada(length)}))"
        elif prop == "left":
            if value.lower() == "auto":
                ada_field = "Left => Set_Left (Auto_Inset)"
            else:
                length = parse_length(value)
                if length:
                    ada_field = f"Left => Set_Left (Inset ({generate_length_ada(length)}))"

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
            track_list = parse_grid_track_list(value)
            if track_list is not None:
                n = len(track_list)
                track_entries = []
                for idx, (kind, val) in enumerate(track_list, 1):
                    if kind == "auto":
                        track_entries.append(f"{idx} => (Track_Auto, 0.0)")
                    elif kind == "fr":
                        track_entries.append(
                            f"{idx} => (Track_Fr, {format_float(val)})")
                    else:  # px
                        track_entries.append(
                            f"{idx} => (Track_Px, {format_float(val)})")
                tracks_str = ", ".join(track_entries) + ", others => <>"
                fields.append(
                    f"{indent}Grid_Columns => Set (Grid_Columns_Value ({n}))")
                fields.append(
                    f"{indent}Grid_Column_Tracks => "
                    f"(Count => {n}, Tracks => [{tracks_str}])")
                continue
            else:
                count = parse_grid_track_count(value)
                if count is not None:
                    ada_field = (
                        f"Grid_Columns => Set (Grid_Columns_Value ({count}))")

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

        # Outline
        elif prop == "outline-width":
            length = parse_length(value)
            if length:
                ada_field = f"Outline_Width => Set_Outline_Width ({generate_length_ada(length)})"

        elif prop == "outline-color":
            color = parse_color(value)
            if color:
                ada_field = f"Outline_Color => Set_Outline_Color ({generate_color_ada(color)})"

        elif prop == "outline-style":
            if value.lower() in OUTLINE_STYLE_MAP:
                ada_field = f"Outline_Style => Set ({OUTLINE_STYLE_MAP[value.lower()]})"

        elif prop == "outline-offset":
            length = parse_length(value)
            if length:
                ada_field = f"Outline_Offset => Set_Outline_Offset ({generate_length_ada(length)})"

        elif prop == "outline":
            parts = split_css_whitespace_tokens(value)
            for part in parts:
                if part.lower() in OUTLINE_STYLE_MAP:
                    fields.append(f"{indent}Outline_Style => Set ({OUTLINE_STYLE_MAP[part.lower()]})")
                    continue
                color = parse_color(part)
                if color:
                    fields.append(f"{indent}Outline_Color => Set_Outline_Color ({generate_color_ada(color)})")
                    continue
                length = parse_length(part)
                if length:
                    fields.append(f"{indent}Outline_Width => Set_Outline_Width ({generate_length_ada(length)})")
            continue  # Skip adding ada_field since we handled it

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

    if padding_sides is not None:
        fields.append(f"{indent}Padding => Set ({generate_box_from_four_ada(padding_sides)})")
    if margin_sides is not None:
        fields.append(f"{indent}Margin => Set ({generate_box_from_four_ada(margin_sides)})")
    if border_width_sides is not None:
        widths = four_sides_to_box_lengths(border_width_sides)
        fields.append(f"{indent}Border_Width => Set ({generate_border_width_ada(widths)})")
    if border_style_sides is not None:
        fields.append(
            f"{indent}Border_Style => Set ({generate_border_style_from_four_ada(border_style_sides)})"
        )
    if border_color_sides is not None:
        fields.append(
            f"{indent}Border_Color => Set ({generate_border_color_from_four_ada(border_color_sides)})"
        )
    if border_radius_corners is not None:
        radii = four_sides_to_box_lengths(border_radius_corners)
        fields.append(f"{indent}Border_Radius => Set ({generate_border_radius_ada(radii)})")
    if list_style_type is not None:
        fields.append(f"{indent}List_Style_Type => Set ({list_style_type})")
    if list_style_image is not None:
        fields.append(f"{indent}List_Style_Image => Set ({list_style_image})")
    if list_style_position is not None:
        fields.append(f"{indent}List_Style_Position => Set ({list_style_position})")
    if overflow_x is not None:
        fields.append(f"{indent}Overflow_X => Set_Overflow_X ({overflow_x})")
    if overflow_y is not None:
        fields.append(f"{indent}Overflow_Y => Set_Overflow_Y ({overflow_y})")

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


def selector_label(selector_type: str) -> str:
    if selector_type == "id":
        return "Id"
    if selector_type == "tag":
        return "Tag"
    return "Class"


def style_name_prefix(ada_name: str, selector_type: str, part_kind: str) -> str:
    """Name prefix for generated style constants."""
    base = f"{ada_name}_{selector_label(selector_type)}"
    return base if part_kind == "Main_Part" else f"{base}_{part_label(part_kind)}"


def widget_style_const_name(ada_name: str, selector_type: str, part_kind: str) -> str:
    """Generated Widget_Style constant name for this widget part."""
    prefix = style_name_prefix(ada_name, selector_type, part_kind)
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


def generate_style_declarations(groups: dict[str, WidgetStyleGroup],
                                indent: str = "   ") -> list[str]:
    """Generate Ada style constant declarations without package wrapper.

    Returns a list of Ada source lines declaring Style_Rules constants,
    Widget_Style constants, and Part_Style_Array bundles for each selector
    group.  Suitable for embedding inside another package body.
    """
    lines: list[str] = []
    generated_names: set[str] = set()

    for _group_key, group in groups.items():
        widget_name = group.name
        ada_name = to_ada_identifier(widget_name)
        part_items = sorted(
            group.parts.items(),
            key=lambda kv: (0 if kv[0] == "Main_Part" else 1, kv[0])
        )

        for part_kind, part_group in part_items:
            part_suffix = "" if part_kind == "Main_Part" else f"::{part_label(part_kind).lower()}"
            name_prefix = style_name_prefix(ada_name, group.selector_type, part_kind)

            if part_group.base_rule:
                var_name = f"{name_prefix}_Base_Style"
                generated_names.add(var_name)
                fields = generate_style_rules_ada(part_group.base_rule.properties,
                                                  indent=indent + "   ")

                lines.append(f"{indent}--  Base style for {group.selector_type} '{widget_name}'{part_suffix}")
                lines.append(f"{indent}{var_name} : constant Style_Rules := (")
                if fields:
                    lines.append(",\n".join(fields) + ",")
                lines.append(f"{indent}   others => <>")
                lines.append(f"{indent});")
                lines.append("")

            for rule in part_group.state_rules:
                var_name = generate_variable_name(name_prefix, rule.selector)
                original_var_name = var_name
                counter = 2
                while var_name in generated_names:
                    var_name = f"{original_var_name}_{counter}"
                    counter += 1
                generated_names.add(var_name)
                rule._var_name = var_name  # type: ignore

                fields = generate_style_rules_ada(rule.properties,
                                                  indent=indent + "   ")
                state_desc = generate_state_description(rule.selector)

                lines.append(f"{indent}--  Style for {group.selector_type} '{widget_name}'{part_suffix} when {state_desc}")
                lines.append(f"{indent}{var_name} : constant Style_Rules := (")
                if fields:
                    lines.append(",\n".join(fields) + ",")
                lines.append(f"{indent}   others => <>")
                lines.append(f"{indent});")
                lines.append("")

    # Widget_Style constants
    for _group_key, group in groups.items():
        widget_name = group.name
        sel_label = selector_label(group.selector_type)
        ada_name = to_ada_identifier(widget_name)
        part_items = sorted(
            group.parts.items(),
            key=lambda kv: (0 if kv[0] == "Main_Part" else 1, kv[0])
        )

        for part_kind, part_group in part_items:
            part_suffix = "" if part_kind == "Main_Part" else f"::{part_label(part_kind).lower()}"
            name_prefix = style_name_prefix(ada_name, group.selector_type, part_kind)
            ws_name = widget_style_const_name(ada_name, group.selector_type, part_kind)

            lines.append(f"{indent}--  Complete widget style for {group.selector_type} '{widget_name}'{part_suffix}")
            lines.append(f"{indent}{ws_name} : constant Widget_Style :=")

            if part_group.base_rule:
                lines.append(f"{indent}  From ({name_prefix}_Base_Style)")
            else:
                lines.append(f"{indent}  Create")

            for rule in part_group.state_rules:
                var_name = rule._var_name  # type: ignore
                selector_ada = generate_selector_ada(rule.selector)
                lines.append(f"{indent}  .On ({selector_ada}, {var_name})")

            lines.append(f"{indent}  .Build;")
            lines.append("")

        # Part_Style_Array bundle
        lines.append(f"{indent}--  Part styles bundle for {group.selector_type} '{widget_name}'")
        lines.append(f"{indent}{ada_name}_{sel_label}_Part_Styles : constant Part_Style_Array := [")
        for part_kind, _part_group in part_items:
            sn = widget_style_const_name(ada_name, group.selector_type, part_kind)
            lines.append(
                f"{indent}   {part_kind} => (Style => {sn}, Enabled => True),"
            )
        lines.append(f"{indent}   others => <>")
        lines.append(f"{indent}];")
        lines.append("")

    return lines


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
    
    for _group_key, group in groups.items():
        widget_name = group.name
        ada_name = to_ada_identifier(widget_name)
        part_items = sorted(
            group.parts.items(),
            key=lambda kv: (0 if kv[0] == "Main_Part" else 1, kv[0])
        )

        for part_kind, part_group in part_items:
            part_suffix = "" if part_kind == "Main_Part" else f"::{part_label(part_kind).lower()}"
            name_prefix = style_name_prefix(ada_name, group.selector_type, part_kind)

            if part_group.base_rule:
                var_name = f"{name_prefix}_Base_Style"
                generated_names.add(var_name)
                fields = generate_style_rules_ada(part_group.base_rule.properties)

                lines.append(f"   --  Base style for {group.selector_type} '{widget_name}'{part_suffix}")
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

                lines.append(f"   --  Style for {group.selector_type} '{widget_name}'{part_suffix} when {state_desc}")
                lines.append(f"   {var_name} : constant Style_Rules := (")
                if fields:
                    lines.append(",\n".join(fields) + ",")
                lines.append(f"      others => <>")
                lines.append(f"   );")
                lines.append(f"")
    
    # Generate combined Widget_Style using fluent builder
    for _group_key, group in groups.items():
        widget_name = group.name
        sel_label = selector_label(group.selector_type)
        ada_name = to_ada_identifier(widget_name)
        part_items = sorted(
            group.parts.items(),
            key=lambda kv: (0 if kv[0] == "Main_Part" else 1, kv[0])
        )

        for part_kind, part_group in part_items:
            part_suffix = "" if part_kind == "Main_Part" else f"::{part_label(part_kind).lower()}"
            name_prefix = style_name_prefix(ada_name, group.selector_type, part_kind)
            widget_style_name = widget_style_const_name(ada_name, group.selector_type, part_kind)

            lines.append(f"   --  Complete widget style for {group.selector_type} '{widget_name}'{part_suffix}")
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
        lines.append(f"   --  Part styles bundle for {group.selector_type} '{widget_name}'")
        lines.append(f"   {ada_name}_{sel_label}_Part_Styles : constant Part_Style_Array := [")
        for part_kind, _part_group in part_items:
            style_name = widget_style_const_name(ada_name, group.selector_type, part_kind)
            lines.append(
                f"      {part_kind} => (Style => {style_name}, Enabled => True),"
            )
        lines.append(f"      others => <>")
        lines.append(f"   ];")
        lines.append(f"")
    
    lines.append(f"end {package_name};")
    
    return "\n".join(lines)


def format_diagnostic(diag: CssDiagnostic) -> str:
    pieces = [diag.code]
    if diag.selector:
        pieces.append(f"selector='{diag.selector}'")
    if diag.property_name:
        pieces.append(f"property='{diag.property_name}'")
    if diag.property_value:
        pieces.append(f"value='{diag.property_value}'")
    return f"{diag.message} ({', '.join(pieces)})"


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
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail if CSS contains unsupported selectors/properties or invalid values",
    )
    
    args = parser.parse_args()

    try:
        assert_property_spec_consistency()
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Read CSS
    try:
        with open(args.input, 'r') as f:
            css_content = f.read()
    except IOError as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Parse
    rules, diagnostics = parse_css_with_diagnostics(css_content)
    for diag in diagnostics:
        print(f"warning: {format_diagnostic(diag)}", file=sys.stderr)

    if args.strict and diagnostics:
        print(
            f"Strict mode failed: {len(diagnostics)} CSS diagnostics found",
            file=sys.stderr,
        )
        sys.exit(1)

    if not rules:
        print("No rules found in CSS file", file=sys.stderr)
        sys.exit(1)
    
    print(f"Parsed {len(rules)} CSS rules")
    
    # Group by widget
    groups = group_rules_by_widget(rules)
    print(
        f"Found {len(groups)} selectors: "
        + ", ".join([f"{g.selector_type}:{g.name}" for g in groups.values()])
    )
    
    # Debug: print parsed selectors
    for _group_key, group in groups.items():
        widget_name = group.name
        print(f"  {group.selector_type}:{widget_name}:")
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
