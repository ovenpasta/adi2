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
    "background-image": PropertySpec("background-image", "url-or-none"),
    # Box model
    "padding": PropertySpec("padding", "box-1-4-length"),
    "padding-top": PropertySpec("padding-top", "length"),
    "padding-right": PropertySpec("padding-right", "length"),
    "padding-bottom": PropertySpec("padding-bottom", "length"),
    "padding-left": PropertySpec("padding-left", "length"),
    "margin": PropertySpec("margin", "box-1-4-length"),
    "margin-top": PropertySpec("margin-top", "length"),
    "margin-right": PropertySpec("margin-right", "length"),
    "margin-bottom": PropertySpec("margin-bottom", "length"),
    "margin-left": PropertySpec("margin-left", "length"),
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


SUPPORTED_PARTS: dict[str, str] = {
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
