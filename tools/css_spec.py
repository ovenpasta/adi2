#!/usr/bin/env python3
"""
Shared compile-time CSS support spec for tools/css_to_ada.py.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class PropertySpec:
    canonical_name: str
    validator: str


SUPPORTED_PROPERTIES: dict[str, PropertySpec] = {
    # Colors and backgrounds
    "color": PropertySpec("color", "color"),
    "background-color": PropertySpec("background-color", "color"),
    "background": PropertySpec("background-color", "color"),
    "background-image": PropertySpec("background-image", "url-or-gradient-or-none"),
    # Box model
    "padding": PropertySpec("padding", "box-1-4-length"),
    "padding-top": PropertySpec("padding-top", "length"),
    "padding-right": PropertySpec("padding-right", "length"),
    "padding-bottom": PropertySpec("padding-bottom", "length"),
    "padding-left": PropertySpec("padding-left", "length"),
    # Margin is the only box-model group where `auto` is valid.
    "margin": PropertySpec("margin", "box-1-4-margin"),
    "margin-top": PropertySpec("margin-top", "margin-side"),
    "margin-right": PropertySpec("margin-right", "margin-side"),
    "margin-bottom": PropertySpec("margin-bottom", "margin-side"),
    "margin-left": PropertySpec("margin-left", "margin-side"),
    # Border
    "border": PropertySpec("border", "border-shorthand"),
    "border-top": PropertySpec("border-top", "border-shorthand"),
    "border-right": PropertySpec("border-right", "border-shorthand"),
    "border-bottom": PropertySpec("border-bottom", "border-shorthand"),
    "border-left": PropertySpec("border-left", "border-shorthand"),
    "border-width": PropertySpec("border-width", "box-1-4-length"),
    "border-top-width": PropertySpec("border-top-width", "length"),
    "border-right-width": PropertySpec("border-right-width", "length"),
    "border-bottom-width": PropertySpec("border-bottom-width", "length"),
    "border-left-width": PropertySpec("border-left-width", "length"),
    "border-color": PropertySpec("border-color", "color"),
    "border-top-color": PropertySpec("border-top-color", "color"),
    "border-right-color": PropertySpec("border-right-color", "color"),
    "border-bottom-color": PropertySpec("border-bottom-color", "color"),
    "border-left-color": PropertySpec("border-left-color", "color"),
    "border-style": PropertySpec("border-style", "border-style"),
    "border-top-style": PropertySpec("border-top-style", "border-style"),
    "border-right-style": PropertySpec("border-right-style", "border-style"),
    "border-bottom-style": PropertySpec("border-bottom-style", "border-style"),
    "border-left-style": PropertySpec("border-left-style", "border-style"),
    "border-radius": PropertySpec("border-radius", "box-1-4-length"),
    "border-top-left-radius": PropertySpec("border-top-left-radius", "length"),
    "border-top-right-radius": PropertySpec("border-top-right-radius", "length"),
    "border-bottom-right-radius": PropertySpec("border-bottom-right-radius", "length"),
    "border-bottom-left-radius": PropertySpec("border-bottom-left-radius", "length"),
    # Sizing
    "width": PropertySpec("width", "width"),
    "height": PropertySpec("height", "height"),
    "min-width": PropertySpec("min-width", "length"),
    "max-width": PropertySpec("max-width", "length"),
    "min-height": PropertySpec("min-height", "length"),
    "max-height": PropertySpec("max-height", "length"),
    # Typography and text flow
    "font-family": PropertySpec("font-family", "font-family"),
    "font-size": PropertySpec("font-size", "length"),
    "font-weight": PropertySpec("font-weight", "font-weight"),
    "font-style": PropertySpec("font-style", "font-style"),
    "text-align": PropertySpec("text-align", "text-align"),
    "vertical-align": PropertySpec("vertical-align", "vertical-align"),
    "text-decoration": PropertySpec("text-decoration", "text-decoration"),
    "white-space": PropertySpec("white-space", "white-space"),
    "text-overflow": PropertySpec("text-overflow", "text-overflow"),
    "text-wrap-mode": PropertySpec("text-wrap-mode", "text-wrap-mode"),
    "line-height": PropertySpec("line-height", "line-height"),
    # Image/list
    "object-fit": PropertySpec("object-fit", "object-fit"),
    "object-position": PropertySpec("object-position", "object-position"),
    "list-style": PropertySpec("list-style", "list-style-shorthand"),
    "list-style-type": PropertySpec("list-style-type", "list-style-type"),
    "list-style-image": PropertySpec("list-style-image", "url-or-none"),
    "list-style-position": PropertySpec("list-style-position", "list-style-position"),
    # Visibility and interaction
    "opacity": PropertySpec("opacity", "number"),
    "overflow": PropertySpec("overflow", "overflow"),
    "overflow-x": PropertySpec("overflow-x", "overflow"),
    "overflow-y": PropertySpec("overflow-y", "overflow"),
    "cursor": PropertySpec("cursor", "cursor"),
    "visibility": PropertySpec("visibility", "visibility"),
    # Layout
    "display": PropertySpec("display", "display"),
    "position": PropertySpec("position", "position"),
    "top": PropertySpec("top", "inset"),
    "right": PropertySpec("right", "inset"),
    "bottom": PropertySpec("bottom", "inset"),
    "left": PropertySpec("left", "inset"),
    "flex-direction": PropertySpec("flex-direction", "flex-direction"),
    "flex-wrap": PropertySpec("flex-wrap", "flex-wrap"),
    "justify-content": PropertySpec("justify-content", "justify-content"),
    "align-items": PropertySpec("align-items", "align-items"),
    "align-self": PropertySpec("align-self", "align-self"),
    "align-content": PropertySpec("align-content", "align-content"),
    "gap": PropertySpec("gap", "gap"),
    "row-gap": PropertySpec("row-gap", "length"),
    "column-gap": PropertySpec("column-gap", "length"),
    "flex-grow": PropertySpec("flex-grow", "number"),
    "flex-shrink": PropertySpec("flex-shrink", "number"),
    "flex-basis": PropertySpec("flex-basis", "flex-basis"),
    "order": PropertySpec("order", "int"),
    "grid-template-columns": PropertySpec("grid-template-columns", "grid-template-columns"),
    "grid-template-rows": PropertySpec("grid-template-rows", "grid-template-rows"),
    "grid-column": PropertySpec("grid-column", "grid-placement"),
    "grid-row": PropertySpec("grid-row", "grid-placement"),
    # Effects and outline
    "box-shadow": PropertySpec("box-shadow", "box-shadow"),
    "outline": PropertySpec("outline", "outline-shorthand"),
    "outline-width": PropertySpec("outline-width", "length"),
    "outline-color": PropertySpec("outline-color", "color"),
    "outline-style": PropertySpec("outline-style", "outline-style"),
    "outline-offset": PropertySpec("outline-offset", "length"),
    "transition": PropertySpec("transition", "transition"),
}


#  The CSS-wide keywords, which are valid on every property.  `revert`
#  is left out: Adi has one cascade origin, so it would be `initial`
#  under another name, and reading it would claim a cascade Adi has not
#  got.
CSS_WIDE_KEYWORDS = frozenset({"initial", "inherit", "unset"})


#  The colour vocabulary names `inherit` -- Adi.CSS_Styles' Default_Color
#  is that entry -- so a declaration whose grammar reads a colour reads
#  the keyword as one.  Adi.CSS_Parser draws the line at the same
#  declarations, through its Color_Reading table.
COLOR_READING_VALIDATORS = frozenset(
    {"color", "border-shorthand", "outline-shorthand"})


#  Adi.CSS_Styles.Inheritable_Properties by CSS name, and the one
#  shorthand standing over them: where `unset` means `inherit`.
INHERITED_PROPERTIES = frozenset({
    "color",
    "cursor",
    "font-family",
    "font-size",
    "font-style",
    "font-weight",
    "line-height",
    "list-style",
    "list-style-image",
    "list-style-position",
    "list-style-type",
    "text-align",
    "text-decoration",
    "text-overflow",
    "text-wrap-mode",
    "vertical-align",
    "visibility",
    "white-space",
})


SUPPORTED_PARTS: dict[str, str] = {
    "main": "Main_Part",
    "label": "Label_Part",
    "text": "Text_Part",
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


def canonical_property_name(name: str) -> str:
    spec = SUPPORTED_PROPERTIES.get(name.strip().lower())
    return spec.canonical_name if spec is not None else name.strip().lower()


def property_validator(name: str) -> Optional[str]:
    spec = SUPPORTED_PROPERTIES.get(name.strip().lower())
    return spec.validator if spec is not None else None


def is_supported_property(name: str) -> bool:
    return name.strip().lower() in SUPPORTED_PROPERTIES


def all_supported_properties() -> set[str]:
    return set(SUPPORTED_PROPERTIES.keys())


def is_supported_part(name: str) -> bool:
    return name.strip().lower() in SUPPORTED_PARTS


def part_kind(name: str) -> Optional[str]:
    return SUPPORTED_PARTS.get(name.strip().lower())


def all_supported_parts() -> set[str]:
    return set(SUPPORTED_PARTS.keys())


def css_wide_keyword(name: str, value: str) -> Optional[str]:
    """The CSS-wide keyword a declaration names, where its property's
    own grammar leaves the value to be read as one."""
    low = value.strip().lower()
    if low not in CSS_WIDE_KEYWORDS:
        return None
    if low == "inherit" and property_validator(name) in COLOR_READING_VALIDATORS:
        return None
    return low


def clears_to_initial(name: str, value: str) -> bool:
    """Whether the declaration takes its property to its initial value.

    `initial` says so outright, and `unset` says so for a property that
    does not inherit; `unset` on one that does is `inherit`, which Adi
    has no value for.
    """
    keyword = css_wide_keyword(name, value)
    if keyword == "initial":
        return True
    return (keyword == "unset"
            and canonical_property_name(name) not in INHERITED_PROPERTIES)
