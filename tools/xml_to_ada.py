#!/usr/bin/env python3
"""
XML to Ada Widget Code Generator

Converts XML widget descriptions into Ada packages that construct widget trees,
apply styles, and wire up hierarchy.

Usage:
    python3 xml_to_ada.py input.xml --output-dir dir --package-name Name
"""

from __future__ import annotations

import re
import xml.etree.ElementTree as ET
import argparse
import sys
import os
from dataclasses import dataclass, field
from typing import Optional

# Import css_to_ada for compiling inline <style> to Ada constants
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import css_to_ada


# ── Data Model ────────────────────────────────────────────────────────────────


@dataclass
class XmlEnum:
    name: str
    values: list[str]


@dataclass
class XmlGeneric:
    name: str
    package: str
    type_param: str


@dataclass
class XmlCallback:
    name: str
    cb_type: str


@dataclass
class XmlComponent:
    package_name: str


@dataclass
class XmlPage:
    key: str
    child: Optional["XmlWidget"] = None
    component: Optional[XmlComponent] = None


@dataclass
class XmlWidget:
    tag: str
    wid: str
    explicit_id: bool
    css_classes: list[str] = field(default_factory=list)
    label: str = ""
    text: str = ""
    generic_name: str = ""
    toggleable: bool = False
    checked: bool = False
    on_clicked: str = ""
    on_toggled: str = ""
    on_changed: str = ""
    on_selection_changed: str = ""
    on_item_clicked: str = ""
    on_item_activated: str = ""
    min_visible_chars: str = ""
    disabled: bool = False
    looping: bool = False
    icon: str = ""
    src: str = ""
    children: list["XmlWidget"] = field(default_factory=list)
    pages: list[XmlPage] = field(default_factory=list)
    items: list[str] = field(default_factory=list)
    i18n_disabled: bool = False
    i18n_contexts: dict[str, str] = field(default_factory=dict)


@dataclass
class XmlOption:
    value: str
    button_id: str


@dataclass
class XmlOptionGroup:
    generic_name: str
    on_changed: str
    id: str = ""
    options: list[XmlOption] = field(default_factory=list)



#  Units a window size may carry. Unitless means px, matching CSS, which
#  also means it follows Set_Px_Maps_To_Dip like every other length.
#  em/rem and vw/vh are refused: there is no font context when a window
#  is created, and vw/vh would resolve against the viewport being defined.
WINDOW_UNITS = {
    "": "Px",
    "px": "Px",
    "pix": "Pix",
    "dp": "Dip",
    "dip": "Dip",
    "%": "Pct",
}


def parse_window_length(value: str) -> WindowLength:
    """Split a window attribute into (amount, Ada length constructor)."""
    text = str(value).strip().lower()
    match = re.match(r"^(-?\d*\.?\d+)\s*([a-z%]*)$", text)
    if not match:
        raise ValueError(f"window size {value!r} is not a number with a unit")
    unit = match.group(2)
    if unit not in WINDOW_UNITS:
        why = {
            "em": "em and rem need a font context, which does not exist "
                  "when a window is created",
            "rem": "em and rem need a font context, which does not exist "
                   "when a window is created",
            "vw": "vw and vh resolve against the viewport, which is what a "
                  "window size defines",
            "vh": "vw and vh resolve against the viewport, which is what a "
                  "window size defines",
        }.get(unit, f"{unit!r} is not a length unit")
        raise ValueError(
            f"window size {value!r} cannot describe a window: {why}. "
            f"Use one of px, pix, dp, dip or %")
    amount = float(match.group(1))
    if amount <= 0.0:
        raise ValueError(f"window size {value!r} must be positive")
    return amount, WINDOW_UNITS[unit]

#  An amount paired with the Ada length constructor its unit maps to,
#  e.g. (617.0, "Dip").
WindowLength = tuple[float, str]


@dataclass
class XmlWindow:
    title: str
    width: WindowLength
    height: WindowLength
    root_widget: XmlWidget
    maximized: bool = False


@dataclass
class XmlDialog:
    title: str = ""
    message: str = ""
    buttons: str = ""          # "ok", "ok-cancel", "yes-no", "yes-no-cancel"
    default_button: Optional[int] = None
    dismiss_on_backdrop: Optional[bool] = None
    dismiss_on_escape: Optional[bool] = None
    content_widget: Optional[XmlWidget] = None
    css_classes: list[str] = field(default_factory=list)
    panel_classes: list[str] = field(default_factory=list)
    title_classes: list[str] = field(default_factory=list)
    message_classes: list[str] = field(default_factory=list)
    button_row_classes: list[str] = field(default_factory=list)
    button_classes: list[str] = field(default_factory=list)
    primary_button_classes: list[str] = field(default_factory=list)


DIALOG_BUTTON_PRESETS = {
    "ok": "Set_OK_Button",
    "ok-cancel": "Set_OK_Cancel",
    "yes-no": "Set_Yes_No",
    "yes-no-cancel": "Set_Yes_No_Cancel",
}

DIALOG_DEFAULT_BUTTON_INDEX = {
    "ok": 1,
    "ok-cancel": 2,
    "yes-no": 2,
    "yes-no-cancel": 3,
}

DIALOG_BUTTON_COUNT = {
    "ok": 1,
    "ok-cancel": 2,
    "yes-no": 2,
    "yes-no-cancel": 3,
}


def get_dialog_default_button_index(dialog: Optional[XmlDialog]) -> int:
    if dialog is None:
        return 0
    if dialog.default_button is not None:
        return dialog.default_button
    if dialog.buttons:
        return DIALOG_DEFAULT_BUTTON_INDEX.get(dialog.buttons, 0)
    return 0


def get_dialog_button_count(dialog: Optional[XmlDialog]) -> int:
    if dialog is None or not dialog.buttons:
        return 0
    return DIALOG_BUTTON_COUNT.get(dialog.buttons, 0)


@dataclass
class CssLink:
    href: str
    styles_pkg: str


@dataclass
class XmlApp:
    enums: list[XmlEnum] = field(default_factory=list)
    generics: list[XmlGeneric] = field(default_factory=list)
    callbacks: list[XmlCallback] = field(default_factory=list)
    root_widget: Optional[XmlWidget] = None
    window: Optional[XmlWindow] = None
    dialog: Optional[XmlDialog] = None
    option_groups: list[XmlOptionGroup] = field(default_factory=list)
    css_links: list[CssLink] = field(default_factory=list)
    css_styles: list[str] = field(default_factory=list)
    component_packages: list[str] = field(default_factory=list)
    i18n_context: str = ""


# ── Widget Grammar ───────────────────────────────────────────────────────────


def load_widget_grammar(path):
    """Load widget definitions from a widgets.xml grammar file."""
    tree = ET.parse(path)
    root = tree.getroot()
    grammar = {}
    for widget_elem in root:
        if widget_elem.tag != "widget":
            continue
        tag = widget_elem.get("tag")
        info = {
            "package": "",
            "handle_type": "",
            "create_handle": "",
            "generic": widget_elem.get("generic", "").lower() == "true",
            "children_mode": widget_elem.get("children-mode", "children"),
            "attributes": [],
        }
        for child in widget_elem:
            if child.tag == "package":
                info["package"] = child.text.strip()
            elif child.tag == "handle-type":
                info["handle_type"] = child.text.strip()
            elif child.tag == "create-handle":
                info["create_handle"] = child.text.strip()
            elif child.tag == "attribute":
                attr = {
                    "name": child.get("name"),
                    "type": child.get("type", "string"),
                    "create_param": child.get("create-param", "").lower() == "true",
                    "default": child.get("default"),
                    "setter": child.get("setter"),
                    "setter_style": child.get("setter-style"),
                    "setter_target": child.get("setter-target"),
                    "meta": child.get("meta", "").lower() == "true",
                    "required": child.get("required", "").lower() == "true",
                    "translatable": child.get("translatable", "").lower() == "true",
                }
                info["attributes"].append(attr)
        grammar[tag] = info
    return grammar


def _load_builtin_grammar():
    """Load the built-in widgets.xml from the same directory as this script."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(script_dir, "widgets.xml")
    return load_widget_grammar(path)


# Load grammar and derive constants used throughout the script
GRAMMAR = _load_builtin_grammar()

WIDGET_TAGS = set(GRAMMAR.keys())

WIDGET_PACKAGES = {
    tag: info["package"]
    for tag, info in GRAMMAR.items()
    if not info["generic"]
}

# ── Helpers ───────────────────────────────────────────────────────────────────


def _attr_to_field(attr_name: str) -> str:
    """Map a grammar attribute name to an XmlWidget field name."""
    if attr_name == "generic":
        return "generic_name"
    return attr_name.replace("-", "_")


def to_ada_identifier(name: str) -> str:
    """Convert CSS/XML name like 'section-row' to Ada identifier 'Section_Row'."""
    name = name.replace("-", "_")
    parts = name.split("_")
    return "_".join(part.capitalize() for part in parts)


def parse_class_list(value: str) -> list[str]:
    return [part for part in value.split() if part]



def class_style_expr(classes: list[str]) -> str:
    if len(classes) == 1:
        return f"{to_ada_identifier(classes[0])}_Class_Part_Styles"
    consts = [f"{to_ada_identifier(c)}_Class_Part_Styles" for c in classes]
    expr = consts[0]
    for const in consts[1:]:
        expr = f"Merge_Part_Styles ({expr}, {const})"
    return expr


def widget_ada_type(widget: XmlWidget, generics_map: dict[str, XmlGeneric]) -> str:
    """Return the Ada handle type for a widget."""
    tag_info = GRAMMAR[widget.tag]
    if tag_info["generic"]:
        return f'{widget.generic_name}.{tag_info["handle_type"]}'
    return f'{tag_info["package"]}.{tag_info["handle_type"]}'


def _i18n_wrap(value: str, context: str) -> str:
    """Wrap a string value with Adi.I18N.T(), including optional context."""
    escaped = value.replace('"', '""')
    if context:
        ctx_escaped = context.replace('"', '""')
        return f'Adi.I18N.T ("{ctx_escaped}", "{escaped}")'
    return f'Adi.I18N.T ("{escaped}")'


def widget_create_expr(
    widget: XmlWidget, generics_map: dict[str, XmlGeneric],
    i18n: bool = False, i18n_context: str = ""
) -> str:
    """Return the Ada Create_Handle expression for a widget."""
    tag_info = GRAMMAR[widget.tag]
    template = tag_info["create_handle"]

    # Determine if i18n wrapping applies to this widget
    use_i18n = i18n and not widget.i18n_disabled

    # Collect which fields need i18n wrapping (so we can post-process template)
    i18n_fields: set[str] = set()

    # Build substitution map with all possible placeholders
    subs = {
        "package": tag_info["package"],
        "generic_name": widget.generic_name,
    }

    for attr in tag_info["attributes"]:
        if not attr["create_param"]:
            continue
        field_name = _attr_to_field(attr["name"])
        value = getattr(widget, field_name, "")
        if attr["type"] == "string":
            if use_i18n and attr.get("translatable") and value:
                i18n_fields.add(field_name)
                # Store raw value; template post-processing will handle wrapping
                subs[field_name] = value.replace('"', '""')
            else:
                subs[field_name] = value.replace('"', '""')
        elif attr["type"] == "bool":
            subs[field_name] = "True" if value else (attr["default"] or "False")
        else:
            subs[field_name] = value

    result = template.format_map(subs)

    # Post-process: replace "{value}" with T("value") for i18n fields
    if i18n_fields:
        for field_name in i18n_fields:
            escaped_val = subs[field_name]
            raw_val = getattr(widget, field_name, "")
            ctx = widget.i18n_contexts.get(
                field_name.replace("_", "-"), i18n_context)
            # Also check the original attr name form
            for attr in tag_info["attributes"]:
                if _attr_to_field(attr["name"]) == field_name:
                    ctx = widget.i18n_contexts.get(attr["name"], i18n_context)
                    break
            wrapped = _i18n_wrap(raw_val, ctx)
            result = result.replace(f'"{escaped_val}"', wrapped)

    return result


def component_instance_name(package_name: str) -> str:
    """Derive an instance name from a component package name.

    Strips _UI/_Ui suffix, or appends _Inst if no such suffix.
    """
    for suffix in ("_UI", "_Ui"):
        if package_name.endswith(suffix):
            return package_name[: -len(suffix)]
    return package_name + "_Inst"


def collect_all_widgets(widget: XmlWidget) -> list[XmlWidget]:
    """Collect all widgets in depth-first pre-order."""
    result = [widget]
    for child in widget.children:
        result.extend(collect_all_widgets(child))
    for page in widget.pages:
        if page.child is not None:
            result.extend(collect_all_widgets(page.child))
        # Skip component pages — no inline widgets to collect
    return result


# ── Parse Phase ───────────────────────────────────────────────────────────────


class Parser:
    def __init__(self):
        self.tag_counters: dict[str, int] = {}
        self.all_ids: set[str] = set()

    def next_auto_id(self, tag: str) -> str:
        count = self.tag_counters.get(tag, 0) + 1
        self.tag_counters[tag] = count
        tag_name = to_ada_identifier(tag)
        wid = f"{tag_name}_{count}"
        while wid in self.all_ids:
            count += 1
            self.tag_counters[tag] = count
            wid = f"{tag_name}_{count}"
        return wid

    def parse(self, xml_file: str) -> XmlApp:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        if root.tag != "adi":
            raise ValueError(f"Root element must be 'adi', got '{root.tag}'")

        app = XmlApp()

        for elem in root:
            tag = elem.tag
            if tag == "enum":
                app.enums.append(self._parse_enum(elem))
            elif tag == "generic":
                app.generics.append(self._parse_generic(elem))
            elif tag == "callback":
                app.callbacks.append(self._parse_callback(elem))
            elif tag == "option-group":
                app.option_groups.append(self._parse_option_group(elem))
            elif tag == "link":
                rel = elem.get("rel", "")
                if rel == "stylesheet":
                    href = elem.get("href", "")
                    explicit = elem.get("styles", "")
                    if href:
                        styles_pkg = (
                            explicit
                            if explicit
                            else to_ada_identifier(
                                os.path.splitext(os.path.basename(href))[0]
                            ) + "_Styles"
                        )
                        app.css_links.append(CssLink(href=href, styles_pkg=styles_pkg))
                    elif explicit:
                        # styles-only link: compile-time Ada import, no runtime CSS file
                        app.css_links.append(CssLink(href="", styles_pkg=explicit))
            elif tag == "i18n":
                ctx = elem.get("context", "")
                if ctx:
                    app.i18n_context = ctx
            elif tag == "style":
                text = (elem.text or "").strip()
                if text:
                    app.css_styles.append(text)
            elif tag == "window":
                if app.window is not None or app.root_widget is not None or app.dialog is not None:
                    raise ValueError(
                        "Only one <window>, <dialog>, or root widget allowed"
                    )
                app.window = self._parse_window(elem)
            elif tag == "dialog":
                if app.dialog is not None or app.window is not None or app.root_widget is not None:
                    raise ValueError(
                        "Only one <window>, <dialog>, or root widget allowed"
                    )
                app.dialog = self._parse_dialog(elem)
            elif tag in WIDGET_TAGS:
                if app.root_widget is not None or app.window is not None or app.dialog is not None:
                    raise ValueError(
                        "Only one <window>, <dialog>, or root widget allowed"
                    )
                app.root_widget = self._parse_widget(elem)
            else:
                raise ValueError(
                    f"Unsupported element <{tag}> inside <adi>"
                )

        if app.root_widget is None and app.window is None and app.dialog is None:
            raise ValueError("No <window>, <dialog>, or root widget element found")

        # Collect component package references from the widget tree
        root = get_root_widget(app)
        if root is not None:
            self._collect_components(root, app)

        return app

    def _collect_components(self, widget: XmlWidget, app: XmlApp):
        """Walk widget tree and collect component package names."""
        for page in widget.pages:
            if page.component is not None:
                pkg = page.component.package_name
                if pkg not in app.component_packages:
                    app.component_packages.append(pkg)
            elif page.child is not None:
                self._collect_components(page.child, app)
        for child in widget.children:
            self._collect_components(child, app)

    def _parse_enum(self, elem) -> XmlEnum:
        name = elem.get("name")
        values = [v.strip() for v in elem.get("values", "").split(",")]
        return XmlEnum(name=name, values=values)

    def _parse_generic(self, elem) -> XmlGeneric:
        return XmlGeneric(
            name=elem.get("name"),
            package=elem.get("package"),
            type_param=elem.get("type-param"),
        )

    def _parse_callback(self, elem) -> XmlCallback:
        return XmlCallback(
            name=elem.get("name"),
            cb_type=elem.get("type"),
        )

    def _parse_option_group(self, elem) -> XmlOptionGroup:
        options = []
        for child in elem:
            if child.tag == "option":
                options.append(
                    XmlOption(
                        value=child.get("value"),
                        button_id=child.get("button"),
                    )
                )
        return XmlOptionGroup(
            generic_name=elem.get("generic"),
            on_changed=elem.get("on-changed", ""),
            id=elem.get("id", ""),
            options=options,
        )

    def _parse_window(self, elem) -> XmlWindow:
        for child in elem:
            if child.tag not in WIDGET_TAGS:
                raise ValueError(
                    f"Unsupported element <{child.tag}> inside <window>"
                )
        widget_children = [c for c in elem if c.tag in WIDGET_TAGS]
        if len(widget_children) != 1:
            raise ValueError(
                "<window> must have exactly one root widget child"
            )
        return XmlWindow(
            title=elem.get("title", "App"),
            width=parse_window_length(elem.get("width", "800")),
            height=parse_window_length(elem.get("height", "600")),
            root_widget=self._parse_widget(widget_children[0]),
            maximized=elem.get("maximized", "false").lower() == "true",
        )

    def _parse_dialog(self, elem) -> XmlDialog:
        dialog = XmlDialog()

        # Parse attributes
        if "title" in elem.attrib:
            dialog.title = elem.get("title")
        if "message" in elem.attrib:
            dialog.message = elem.get("message")
        if "buttons" in elem.attrib:
            buttons = elem.get("buttons")
            if buttons not in DIALOG_BUTTON_PRESETS:
                raise ValueError(
                    f"Invalid buttons value '{buttons}'. "
                    f"Must be one of: {', '.join(DIALOG_BUTTON_PRESETS.keys())}"
                )
            dialog.buttons = buttons
        if "default-button" in elem.attrib:
            try:
                val = int(elem.get("default-button"))
                if val < 0:
                    raise ValueError("default-button must be a non-negative integer")
                dialog.default_button = val
            except ValueError as e:
                if "non-negative integer" in str(e):
                    raise
                raise ValueError(
                    f"Invalid default-button value '{elem.get('default-button')}'. "
                    "Must be a non-negative integer (0 clears the default)"
                )
        if "dismiss-on-backdrop" in elem.attrib:
            val = elem.get("dismiss-on-backdrop")
            if val not in ("true", "false"):
                raise ValueError(
                    f"Invalid dismiss-on-backdrop value '{val}'. "
                    "Must be 'true' or 'false'"
                )
            dialog.dismiss_on_backdrop = val == "true"
        if "dismiss-on-escape" in elem.attrib:
            val = elem.get("dismiss-on-escape")
            if val not in ("true", "false"):
                raise ValueError(
                    f"Invalid dismiss-on-escape value '{val}'. "
                    "Must be 'true' or 'false'"
                )
            dialog.dismiss_on_escape = val == "true"
        if "class" in elem.attrib:
            dialog.css_classes = parse_class_list(elem.get("class", ""))
        if "panel-class" in elem.attrib:
            dialog.panel_classes = parse_class_list(elem.get("panel-class", ""))
        if "title-class" in elem.attrib:
            dialog.title_classes = parse_class_list(elem.get("title-class", ""))
        if "message-class" in elem.attrib:
            dialog.message_classes = parse_class_list(elem.get("message-class", ""))
        if "button-row-class" in elem.attrib:
            dialog.button_row_classes = parse_class_list(elem.get("button-row-class", ""))
        if "button-class" in elem.attrib:
            dialog.button_classes = parse_class_list(elem.get("button-class", ""))
        if "primary-button-class" in elem.attrib:
            dialog.primary_button_classes = parse_class_list(elem.get("primary-button-class", ""))

        # Parse child widgets (at most 1)
        widget_children = [c for c in elem if c.tag in WIDGET_TAGS]
        non_widget_children = [c for c in elem if c.tag not in WIDGET_TAGS]
        if non_widget_children:
            bad_tag = non_widget_children[0].tag
            raise ValueError(
                f"Unsupported element <{bad_tag}> inside <dialog>"
            )
        if len(widget_children) > 1:
            raise ValueError(
                "<dialog> must have at most one child widget"
            )
        if widget_children:
            dialog.content_widget = self._parse_widget(widget_children[0])

        return dialog

    def _parse_widget(self, elem) -> XmlWidget:
        tag = elem.tag
        has_explicit_id = "id" in elem.attrib

        if has_explicit_id:
            wid = elem.get("id")
            if wid in self.all_ids:
                raise ValueError(f"Duplicate widget id: {wid}")
        else:
            wid = self.next_auto_id(tag)

        self.all_ids.add(wid)

        # Common attributes (not in grammar)
        widget = XmlWidget(
            tag=tag,
            wid=wid,
            explicit_id=has_explicit_id,
            css_classes=elem.get("class", "").split() if elem.get("class", "") else [],
            label=elem.get("label", ""),
            i18n_disabled=elem.get("i18n", "").lower() == "false",
        )

        # Per-property i18n context: {property}-i18n-context="ctx"
        for attr_name, attr_value in elem.attrib.items():
            if attr_name.endswith("-i18n-context"):
                prop_name = attr_name[:-len("-i18n-context")]
                widget.i18n_contexts[prop_name] = attr_value

        # Grammar-driven attributes
        if tag in GRAMMAR:
            for attr in GRAMMAR[tag]["attributes"]:
                field_name = _attr_to_field(attr["name"])
                if attr["type"] == "bool":
                    value = elem.get(attr["name"], "").lower() == "true"
                else:
                    value = elem.get(attr["name"], "")
                setattr(widget, field_name, value)

        for child_elem in elem:
            if child_elem.tag == "page":
                key = child_elem.get("key")
                page_widgets = [
                    c for c in child_elem if c.tag in WIDGET_TAGS
                ]
                page_components = [
                    c for c in child_elem if c.tag == "component"
                ]
                if len(page_widgets) == 1 and len(page_components) == 0:
                    widget.pages.append(
                        XmlPage(
                            key=key,
                            child=self._parse_widget(page_widgets[0]),
                        )
                    )
                elif len(page_components) == 1 and len(page_widgets) == 0:
                    pkg = page_components[0].get("package")
                    if not pkg:
                        raise ValueError(
                            f"<component> in <page key='{key}'>"
                            " must have a 'package' attribute"
                        )
                    widget.pages.append(
                        XmlPage(
                            key=key,
                            component=XmlComponent(package_name=pkg),
                        )
                    )
                else:
                    raise ValueError(
                        f"<page key='{key}'> must have exactly one"
                        " child widget or one <component>"
                    )
            elif child_elem.tag == "item":
                item_text = child_elem.get("text", "")
                widget.items.append(item_text)
            elif child_elem.tag in WIDGET_TAGS:
                widget.children.append(self._parse_widget(child_elem))
            else:
                raise ValueError(
                    f"Unsupported element <{child_elem.tag}>"
                    f" inside <{tag}>"
                )

        return widget


# ── Generate Phase ────────────────────────────────────────────────────────────


def get_root_widget(app: XmlApp) -> Optional[XmlWidget]:
    """Return the root widget from a <window>, <dialog>, or bare widget.

    Returns None for a dialog with no content widget.
    """
    if app.window is not None:
        return app.window.root_widget
    if app.dialog is not None:
        return app.dialog.content_widget  # may be None
    return app.root_widget


def generate_spec(app: XmlApp, package_name: str,
                  no_live_css: bool = False) -> str:
    """Generate the .ads (spec) file.

    When `no_live_css` is True, CSS_Source dynamic loading is disabled
    regardless of `<link>`/`<style>` presence, forcing static-only
    codegen (direct Set_Part_Styles calls, no Add_Dynamic_File).
    """
    generics_map = {g.name: g for g in app.generics}
    root = get_root_widget(app)
    all_widgets = collect_all_widgets(root) if root else []
    exported = [w for w in all_widgets if w.explicit_id]
    has_window = app.window is not None
    has_dialog = app.dialog is not None
    live_css = (
        not no_live_css
        and bool(any(link.href for link in app.css_links) or app.css_styles)
    )
    #  One argument cannot stand in for several sheets without silently
    #  dropping all but one, so a package with more than one <link> gets
    #  Set_CSS_Sheets, which takes the set.
    multi_link = len([l for l in app.css_links if l.href]) > 1

    # Compute with clauses — only packages referenced in the spec
    withs: set[str] = set()
    if live_css and multi_link:
        #  Set_CSS_Sheets names Dynamic_Source_Entry_Array in its profile.
        withs.add("Adi.CSS_Source")
    if has_window:
        withs.add("Adi.Window")
    elif has_dialog:
        withs.add("Adi.Widget.Dialog")
        # `Instance.Attach_Window` is always emitted when the app is a
        # dialog (regardless of CSS mode), so its `Window_Handle`
        # parameter type always needs Adi.Window in scope.
        withs.add("Adi.Window")
    else:
        withs.add("Adi.Widget")
    for w in exported:
        if w.tag in WIDGET_PACKAGES:
            withs.add(WIDGET_PACKAGES[w.tag])
    for gen in app.generics:
        withs.add(gen.package)
    for comp_pkg in app.component_packages:
        withs.add(comp_pkg)
    # Callback types declared in the spec need their defining package withed
    # too (unless the prefix is a local generic alias like "Page_Stack").
    generic_alias_names = {gen.name for gen in app.generics}
    for cb in app.callbacks:
        if "." in cb.cb_type:
            prefix = cb.cb_type.rsplit(".", 1)[0]
            if prefix not in generic_alias_names:
                withs.add(prefix)

    lines = [
        "--  Auto-generated from XML",
        "--  Do not edit manually",
        "",
        "pragma Ada_2022;",
        "",
    ]

    for w in sorted(withs):
        lines.append(f"with {w};")
    lines.append("")

    lines.append(f"package {package_name} is")
    lines.append("")

    # Enum types
    for enum in app.enums:
        vals = ", ".join(enum.values)
        lines.append(f"   type {enum.name} is ({vals});")
    if app.enums:
        lines.append("")

    # Generic instantiations
    for gen in app.generics:
        lines.append(
            f"   package {gen.name} is new {gen.package} ({gen.type_param});"
        )
    if app.generics:
        lines.append("")

    # Nested generic package for multi-instance support
    lines.append("   generic")
    lines.append("   package Instance is")
    lines.append("")

    # Callback variables (inside Instance)
    for cb in app.callbacks:
        lines.append(f"      {cb.name} : {cb.cb_type} := null;")
    if app.callbacks:
        lines.append("")

    # Exported widget variables (inside Instance)
    for w in exported:
        ada_type = widget_ada_type(w, generics_map)
        lines.append(f"      {w.wid} : {ada_type};")
    if exported:
        lines.append("")

    # Exported option group variables (inside Instance)
    exported_ogs = [og for og in app.option_groups if og.id]
    for og in exported_ogs:
        group_var = f"{og.generic_name}_Group"
        lines.append(
            f"      {group_var} : aliased {og.generic_name}.Option_Group;"
        )
        if og.on_changed:
            conn_var = f"{og.generic_name}_Group_Conn"
            lines.append(
                f"      {conn_var} : {og.generic_name}"
                f".Option_Changed_Signals.Connection_Id :="
            )
            lines.append(
                f"        {og.generic_name}"
                f".Option_Changed_Signals.No_Connection;"
            )
    if exported_ogs:
        lines.append("")

    # Component nested instances (inside Instance)
    for comp_pkg in app.component_packages:
        inst_name = component_instance_name(comp_pkg)
        lines.append(
            f"      package {inst_name} is new {comp_pkg}.Instance;"
        )
    if app.component_packages:
        lines.append("")

    # Build — clean signature, no CSS_File parameter
    if has_window:
        lines.append(
            "      function Build return Adi.Window.Window_Handle;"
        )
    elif has_dialog:
        lines.append(
            "      function Build return Adi.Widget.Dialog.Dialog_Handle;"
        )
    else:
        lines.append(
            "      function Build return Adi.Widget.Widget_Handle;"
        )
    lines.append("")

    # Tick_Styles is always emitted so parent packages can recurse into
    # component instances without conditional API checks.
    lines.append("      procedure Tick_Styles (Reloaded : out Boolean;")
    lines.append("                             Success  : out Boolean);")
    lines.append("")

    if has_dialog:
        # Always declare Attach_Window for dialog apps so callers have a
        # stable API regardless of CSS mode. When live-CSS is off and the
        # app has no component packages, the body is just a pass-through
        # to Adi.Widget.Dialog.Attach_Window — but the wrapper must still
        # exist so downstream code that calls `Xyz_Dlg.Attach_Window`
        # keeps compiling under --no-live-css.
        lines.append(
            "      procedure Attach_Window"
            " (D : Adi.Widget.Dialog.Dialog_Handle;"
            " Host : Adi.Window.Window_Handle);"
        )
        lines.append("")

    # Set_CSS_File — only when dynamic <link> elements are present
    if live_css and multi_link:
        lines.append(
            "      --  This package declares more than one <link> sheet, so"
        )
        lines.append(
            "      --  naming one of them would replace them all. Any"
        )
        lines.append(
            "      --  <style> rules keep their place after these."
        )
        lines.append(
            "      procedure Set_CSS_Sheets"
        )
        lines.append(
            "        (Sheets  : Adi.CSS_Source.Dynamic_Source_Entry_Array;"
        )
        lines.append(
            "         Success : out Boolean);"
        )
        lines.append("")
    elif live_css:
        lines.append(
            "      procedure Set_CSS_File (Path : String;"
            " Success : out Boolean);"
        )
        lines.append("")

    lines.append("   end Instance;")
    lines.append("")
    lines.append(f"end {package_name};")

    return "\n".join(lines) + "\n"


def dynamic_sources_call(app, indent: str, result: str) -> list[str]:
    """Install every <link> sheet, then the <style> text, in one call.

    Build may run more than once against one Source -- a list that builds
    a row at a time does -- so this replaces the configuration rather than
    piling up behind it, and parses the sheets once between them.
    """
    sheets = [
        f'Adi.CSS_Source.CSS_File ("{link.href}")'
        for link in app.css_links if link.href
    ]
    if app.css_styles:
        sheets.append("Adi.CSS_Source.CSS_Text (Inline_CSS)")
    if not sheets:
        return []

    out = [f"{indent}Adi.CSS_Source.Set_Dynamic_Sources",
           f"{indent}  (Source,"]
    for i, s in enumerate(sheets):
        opener = "[" if i == 0 else " "
        closer = "]," if i == len(sheets) - 1 else ","
        out.append(f"{indent}   {opener}{s}{closer}")
    out.append(f"{indent}   {result});")
    return out


def inline_css_constant(css: str, indent: str = "   ") -> list[str]:
    """Emit the <style> text as an Ada String constant, one CSS line each.

    Non-ASCII stays as raw UTF-8 bytes, which is what the parser wants;
    the body's Wide_Character_Encoding pragma is what stops -gnatW8
    collapsing them.
    """
    segments = css.split("\n")
    if segments and segments[-1] == "":
        segments.pop()
    if not segments:
        return [f'{indent}Inline_CSS : constant String := "";']

    out = [f"{indent}Inline_CSS : constant String :="]
    for i, seg in enumerate(segments):
        escaped = seg.replace('"', '""')
        tail = ";" if i == len(segments) - 1 else " &"
        out.append(f'{indent}  "{escaped}" & ASCII.LF{tail}')
    return out


def generate_body(app: XmlApp, package_name: str,
                   i18n: bool = False,
                   no_live_css: bool = False) -> str:
    """Generate the .adb (body) file.

    When `no_live_css` is True, CSS_Source dynamic loading is disabled
    regardless of `<link>`/`<style>` presence, forcing static-only
    codegen (direct Set_Part_Styles calls, no Add_Dynamic_File).
    """
    generics_map = {g.name: g for g in app.generics}
    root = get_root_widget(app)
    all_widgets = collect_all_widgets(root) if root else []
    exported = [w for w in all_widgets if w.explicit_id]
    internal = [w for w in all_widgets if not w.explicit_id]
    has_window = app.window is not None
    has_dialog = app.dialog is not None
    live_css = (
        not no_live_css
        and bool(any(link.href for link in app.css_links) or app.css_styles)
    )
    #  One argument cannot stand in for several sheets without silently
    #  dropping all but one, so a package with more than one <link> gets
    #  Set_CSS_Sheets, which takes the set.
    multi_link = len([l for l in app.css_links if l.href]) > 1
    dialog_default_button = get_dialog_default_button_index(app.dialog)
    dialog_button_count = get_dialog_button_count(app.dialog)

    # Compute spec-level withs so we know what the body inherits
    spec_withs: set[str] = set()
    if has_window:
        spec_withs.add("Adi.Window")
    elif has_dialog:
        spec_withs.add("Adi.Widget.Dialog")
        # Mirrors the spec: `Instance.Attach_Window` is always emitted
        # when the app is a dialog, so Adi.Window is always inherited.
        spec_withs.add("Adi.Window")
    else:
        spec_withs.add("Adi.Widget")
    for w in exported:
        if w.tag in WIDGET_PACKAGES:
            spec_withs.add(WIDGET_PACKAGES[w.tag])
    for gen in app.generics:
        spec_withs.add(gen.package)
    for comp_pkg in app.component_packages:
        spec_withs.add(comp_pkg)
    # Callback types declared in the spec need their defining package withed
    # too (unless the prefix is a local generic alias like "Page_Stack").
    generic_alias_names = {gen.name for gen in app.generics}
    for cb in app.callbacks:
        if "." in cb.cb_type:
            prefix = cb.cb_type.rsplit(".", 1)[0]
            if prefix not in generic_alias_names:
                spec_withs.add(prefix)

    # Compile inline <style> CSS to Ada constants
    inline_stylesheet: Optional[css_to_ada.ParsedStylesheet] = None
    inline_groups: dict = {}
    inline_classes: set[str] = set()
    if app.css_styles:
        combined_inline = "\n".join(app.css_styles)
        inline_stylesheet, _inline_diags = (
            css_to_ada.parse_stylesheet_with_diagnostics(combined_inline)
        )
        inline_rules = inline_stylesheet.rules
        if inline_rules:
            inline_groups = css_to_ada.group_rules_by_widget(inline_rules)
            for key, grp in inline_groups.items():
                if grp.selector_type == "class":
                    inline_classes.add(grp.name)

    # Import styles packages derived from <link> elements
    link_pkgs = list(dict.fromkeys(link.styles_pkg for link in app.css_links))

    #  Selector manifests, in the order the sheets are loaded: links first,
    #  then the inline <style>, matching the Add_Dynamic_File sequence below
    #  so the static fallback cascades the way the live sheets do.
    #  From the links, not the deduplicated with-list: a sheet listed twice
    #  registers twice, which is how the later copy wins as CSS says it
    #  should. link_pkgs stays deduplicated for the context clauses.
    selector_sources = [
        f"{link.styles_pkg}.Register_Selectors" for link in app.css_links
    ]
    if inline_groups:
        selector_sources.append("Register_Inline_Selectors")

    #  Both modes resolve widgets through a Style_Source now; only the
    #  static one skips loading anything from disk. Root metadata and a
    #  dynamic file each reach the source without naming a selector, so a
    #  sheet carrying nothing but `:root` still needs one declared.
    uses_css_source = bool(
        selector_sources
        or live_css
        or link_pkgs
        or (inline_stylesheet and inline_stylesheet.root_properties)
    )
    has_dialog_class_targets = bool(
        app.dialog
        and (
            app.dialog.css_classes
            or app.dialog.panel_classes
            or app.dialog.title_classes
            or app.dialog.message_classes
            or app.dialog.button_row_classes
            or app.dialog.button_classes
            or app.dialog.primary_button_classes
        )
    )
    has_dialog_button_style_targets = bool(
        app.dialog
        and (
            app.dialog.button_classes
            or app.dialog.primary_button_classes
        )
    )
    #  Widgets reach their styles through the selector manifests, which are
    #  named qualified. Only the dialog parts still name style constants
    #  directly, so they alone decide whether the packages need a use clause.
    needs_link_pkg_use = bool(
        link_pkgs
        and (has_dialog_class_targets or has_dialog_button_style_targets)
    )
    has_root_metadata = bool(
        link_pkgs or (inline_stylesheet and inline_stylesheet.root_properties)
    )
    # Body needs Adi.Widget (for Set_Part_Styles, Add_Child, Widget_Access)
    # + any widget packages not already in the spec.
    # Always include Adi.Widget even if in spec — need `use` clause.
    # A dialog part listing several classes merges their bundles inline,
    # which needs Merge_Part_Styles in scope.
    has_multi_class = any(
        len(classes) > 1 for _name, classes in (
            [
                ("dialog", app.dialog.css_classes),
                ("panel", app.dialog.panel_classes),
                ("title", app.dialog.title_classes),
                ("message", app.dialog.message_classes),
                ("button_row", app.dialog.button_row_classes),
                ("button", app.dialog.button_classes),
                ("primary_button", app.dialog.primary_button_classes),
            ] if app.dialog is not None else []
        )
    )

    body_withs: list[str] = ["Adi.Widget"]
    if live_css or has_multi_class or app.css_links or uses_css_source:
        body_withs.append("Adi.CSS_Source")
    if has_root_metadata:
        body_withs.append("Adi.CSS_Parser")
    if has_window and live_css:
        body_withs.append("Adi.Window")
    if has_window:
        #  Window extents are written with the CSS length constructors.
        body_withs.append("Adi.CSS_Styles")
    if has_dialog:
        body_withs.append("Adi.Widget.Dialog")
        body_withs.append("Adi.Widget.Box")
        body_withs.append("Adi.Widget.Label")
        #  Binding a dialog button widens a Button_Handle, which needs
        #  the package's "+" in scope. A dialog that styles no button
        #  never names one.
        if app.dialog is not None and (
            app.dialog.button_classes or app.dialog.primary_button_classes
        ):
            body_withs.append("Adi.Widget.Button")
        if live_css or app.component_packages:
            body_withs.append("Adi.Window")
    if inline_groups or (inline_stylesheet and inline_stylesheet.root_properties):
        body_withs.append("Adi.CSS_Styles")
        body_withs.append("Adi.Widget_Styles")
    # Include ALL widget packages in body (need "use" for "+" operator visibility)
    for w in all_widgets:
        if w.tag in WIDGET_PACKAGES:
            pkg = WIDGET_PACKAGES[w.tag]
            if pkg not in body_withs:
                body_withs.append(pkg)
    # Check if any widget uses image-type attributes
    for w in all_widgets:
        if w.tag in GRAMMAR:
            for attr in GRAMMAR[w.tag]["attributes"]:
                if attr["type"] == "image":
                    field_name = _attr_to_field(attr["name"])
                    if getattr(w, field_name, ""):
                        body_withs.append("Adi.Assets")
                        break
            else:
                continue
            break
    if i18n:
        body_withs.append("Adi.I18N")

    lines = [
        "--  Auto-generated from XML",
        "--  Do not edit manually",
        "",
        #  <style> text and text= attributes are raw UTF-8 bytes, which is
        #  what the parser and the renderer consume. A project-wide
        #  -gnatW8 would collapse each non-ASCII character to one Latin-1
        #  byte; this keeps them verbatim, and is a no-op without it.
        "pragma Wide_Character_Encoding (Brackets);",
        "pragma Ada_2022;",
        "",
    ]

    # Collect generic instance names for use-inside-body (not context clauses)
    generic_uses: list[str] = []
    for w in all_widgets:
        if w.generic_name and w.generic_name not in generic_uses:
            generic_uses.append(w.generic_name)

    plain_with_only = {
        "Adi.Assets",
        "Adi.CSS_Parser",
        "Adi.I18N",
        "Adi.Widget.Dialog",
        "Adi.Window",
    }
    for bw in sorted(set(body_withs)):
        if bw in plain_with_only and bw in spec_withs:
            continue
        if bw in plain_with_only:
            lines.append(f"with {bw};")
        else:
            lines.append(f"with {bw}; use {bw};")

    for pkg in sorted(link_pkgs):
        if needs_link_pkg_use:
            lines.append(f"with {pkg}; use {pkg};")
        else:
            lines.append(f"with {pkg};")

    lines.append("")
    lines.append(f"package body {package_name} is")
    lines.append("")
    lines.append("   package body Instance is")

    # Use clauses for generic instances (not library-level, must be inside body)
    for gu in sorted(generic_uses):
        lines.append(f"   use {gu};")

    # Package-level state for live CSS mode
    if uses_css_source:
        lines.append("   Source : aliased Adi.CSS_Source.Style_Source;")
    if live_css:
        if app.css_styles:
            lines.append("")
            lines.append("   --  The <style> block as text. Dynamic_Mode")
            lines.append("   --  styles from the parsed sheet and never")
            lines.append("   --  from the static entries below, so the")
            lines.append("   --  rules need a place in the cascade.")
            lines.append("   --  --no-live-css builds omit this.")
            lines.extend(
                inline_css_constant("\n".join(app.css_styles) + "\n"))
        # Compiled inline style declarations (for static fallback)
        if inline_groups:
            lines.append("")
            decl_lines = css_to_ada.generate_style_declarations(
                inline_groups, indent="   ")
            lines.extend(decl_lines)
            lines.extend(
                css_to_ada.generate_selector_registration_body(
                    inline_groups, prefix="Register_Inline_Selectors")
            )
    elif inline_groups:
        lines.append("")
        decl_lines = css_to_ada.generate_style_declarations(
            inline_groups, indent="   ")
        lines.extend(decl_lines)
        lines.extend(
            css_to_ada.generate_selector_registration_body(
                inline_groups, prefix="Register_Inline_Selectors")
        )

    if has_dialog and (live_css or app.component_packages):
        lines.append(
            "   Live_CSS_Host : Adi.Window.Window_Handle :="
            " Adi.Window.Null_Window_Handle;"
        )

    if inline_stylesheet and inline_stylesheet.root_properties:
        root_props = inline_stylesheet.root_properties
        root_font = root_props.get("font-size")
        parsed_root_font = (
            css_to_ada.parse_length(root_font) if root_font else None
        )
        lines.append("")
        if parsed_root_font is not None:
            lines.append("   function Inline_Has_Root_Font_Size return Boolean is (True);")
            lines.append(
                f"   function Inline_Root_Font_Size return Length_Value is ({css_to_ada.generate_length_ada(parsed_root_font)});"
            )
        else:
            lines.append("   function Inline_Has_Root_Font_Size return Boolean is (False);")
            lines.append("   function Inline_Root_Font_Size return Length_Value is (Default_Font_Size);")

        fields = css_to_ada.generate_style_rules_ada(root_props, indent="      ")
        lines.append("")
        lines.append("   function Inline_Root_Base_Style return Style_Rules is")
        lines.append("     (")
        if fields:
            lines.append(",\n".join(fields) + ",")
        lines.append("      others => <>);")
        lines.append("")
        lines.append("   function Inline_Has_Root_Styles return Boolean is (True);")
        lines.append("   function Inline_Root_Part_Styles return Part_Style_Array is")
        lines.append("     ([")
        lines.append("      Main_Part => (Style => From (Inline_Root_Base_Style).Build, Enabled => True),")
        lines.append("      others => <>")
        lines.append("   ]);")
        lines.append("")
        lines.append("   function Inline_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is")
        lines.append("     (")
        lines.append("      Has_Root_Style => Inline_Has_Root_Styles,")
        lines.append("      Root_Styles => Inline_Root_Part_Styles,")
        lines.append("      Has_Root_Font_Size => Inline_Has_Root_Font_Size,")
        lines.append("      Root_Font_Size => Inline_Root_Font_Size);")

    if link_pkgs or (inline_stylesheet and inline_stylesheet.root_properties):
        lines.append("")
        lines.append("   function Merge_Metadata")
        lines.append("     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)")
        lines.append("      return Adi.CSS_Parser.Stylesheet_Metadata is")
        lines.append("      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;")
        lines.append("   begin")
        lines.append("      if Override.Has_Root_Style then")
        lines.append("         if Result.Has_Root_Style then")
        lines.append("            Result.Root_Styles :=")
        lines.append("              Merge_Part_Styles (Result.Root_Styles, Override.Root_Styles);")
        lines.append("         else")
        lines.append("            Result.Root_Styles := Override.Root_Styles;")
        lines.append("            Result.Has_Root_Style := True;")
        lines.append("         end if;")
        lines.append("      end if;")
        lines.append("      if Override.Has_Root_Font_Size then")
        lines.append("         Result.Has_Root_Font_Size := True;")
        lines.append("         Result.Root_Font_Size := Override.Root_Font_Size;")
        lines.append("      end if;")
        lines.append("      return Result;")
        lines.append("   end Merge_Metadata;")
        lines.append("")
        lines.append("   function Static_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is")
        lines.append("      Result : Adi.CSS_Parser.Stylesheet_Metadata := (others => <>);")
        lines.append("   begin")
        for link in app.css_links:
            lines.append(
                f"      Result := Merge_Metadata (Result, {link.styles_pkg}.Root_Metadata);"
            )
        if inline_stylesheet and inline_stylesheet.root_properties:
            lines.append(
                "      Result := Merge_Metadata (Result, Inline_Root_Metadata);"
            )
        lines.append("      return Result;")
        lines.append("   end Static_Root_Metadata;")

    #  Packages this body already brings in with a use clause. A callback
    #  type declared in one of them needs nothing more; anything else has
    #  no visible "/=" for the null test below.
    used_pkgs = {bw for bw in set(body_withs) if bw not in plain_with_only}
    if needs_link_pkg_use:
        used_pkgs |= set(link_pkgs)
    used_pkgs |= set(generic_uses)

    callback_use_types: set[str] = set()
    for cb in app.callbacks:
        if cb.cb_type.endswith("Value_Changed_Callback"):
            callback_use_types.add(cb.cb_type)
        elif "." in cb.cb_type and cb.cb_type.rsplit(".", 1)[0] not in used_pkgs:
            #  A widget whose callback type lives in an ancestor package
            #  rather than its own: a switch is Adi.Widget.Button.Switch
            #  but its Toggle_Callback is Adi.Widget.Button's.
            callback_use_types.add(cb.cb_type)
    for cb_type in sorted(callback_use_types):
        lines.append(f"   use type {cb_type};")
    if has_dialog and (live_css or app.component_packages):
        lines.append("   use type Adi.Window.Window_Handle;")

    # Package-level option group variables (only those without id, others are in spec)
    for og in app.option_groups:
        if not og.id:
            group_var = f"{og.generic_name}_Group"
            lines.append(
                f"   {group_var} : aliased {og.generic_name}.Option_Group;"
            )
        if og.on_changed and not og.id:
            conn_var = f"{og.generic_name}_Group_Conn"
            lines.append(
                f"   {conn_var} : {og.generic_name}"
                f".Option_Changed_Signals.Connection_Id :="
            )
            lines.append(
                f"     {og.generic_name}"
                f".Option_Changed_Signals.No_Connection;"
            )

    # Wrapper procedures for option group callbacks
    for og in app.option_groups:
        if og.on_changed:
            gen = generics_map[og.generic_name]
            wrapper = f"{og.on_changed}_Option_Wrapper"
            lines.append("")
            lines.append(
                f"   procedure {wrapper} (Value : {gen.type_param}) is"
            )
            lines.append("   begin")
            lines.append(f"      if {og.on_changed} /= null then")
            lines.append(f"         {og.on_changed} (Value);")
            lines.append("      end if;")
            lines.append(f"   end {wrapper};")

    # Tick_Styles + Tick_Styles_CB — must precede Build so the
    # 'Unrestricted_Access reference inside Build resolves.
    lines.append("")
    lines.append("   procedure Tick_Styles (Reloaded : out Boolean;")
    lines.append("                          Success  : out Boolean) is")
    lines.append("   begin")
    lines.append("      Reloaded := False;")
    lines.append("      Success := True;")

    if live_css:
        lines.append("      declare")
        lines.append("         Local_Reloaded : Boolean := False;")
        lines.append("         Local_Success  : Boolean := True;")
        lines.append("      begin")
        lines.append("         Adi.CSS_Source.Tick (Source, Local_Reloaded, Local_Success);")
        lines.append("         Reloaded := Reloaded or Local_Reloaded;")
        lines.append("         Success := Success and Local_Success;")
        lines.append("      end;")

    for comp_pkg in app.component_packages:
        inst_name = component_instance_name(comp_pkg)
        lines.append("      declare")
        lines.append("         Component_Reloaded : Boolean := False;")
        lines.append("         Component_Success  : Boolean := True;")
        lines.append("      begin")
        lines.append(
            f"         {inst_name}.Tick_Styles (Component_Reloaded, Component_Success);"
        )
        lines.append("         Reloaded := Reloaded or Component_Reloaded;")
        lines.append("         Success := Success and Component_Success;")
        lines.append("      end;")

    lines.append("   end Tick_Styles;")

    if (has_window or has_dialog) and (live_css or app.component_packages):
        lines.append("")
        lines.append("   procedure Tick_Styles_CB (DT : Duration) is")
        lines.append("      pragma Unreferenced (DT);")
        lines.append("      Reloaded, Success : Boolean;")
        lines.append("   begin")
        lines.append("      Tick_Styles (Reloaded, Success);")
        lines.append("   end Tick_Styles_CB;")

    if has_dialog:
        lines.append("")
        lines.append(
            "   procedure Attach_Window"
            " (D : Adi.Widget.Dialog.Dialog_Handle;"
            " Host : Adi.Window.Window_Handle) is"
        )
        lines.append("   begin")
        lines.append("      Adi.Widget.Dialog.Attach_Window (D, Host);")
        if live_css or app.component_packages:
            #  Tick-hook is only meaningful when CSS_Source live-reload or
            #  child component instances exist. Otherwise the body is a
            #  pass-through wrapper.
            lines.append("      if Live_CSS_Host /= Host then")
            lines.append(
                "         Adi.Window.Connect_Tick"
                " (Host, Tick_Styles_CB'Unrestricted_Access);"
            )
            lines.append("         Live_CSS_Host := Host;")
            lines.append("      end if;")
        lines.append("   end Attach_Window;")

    # Set_CSS_File / Set_CSS_Sheets — install a configuration and enable
    # live reload. The <style> sheet keeps its cascade position last.
    if live_css:
        entries = ["         Adi.CSS_Source.CSS_File (Path)"]
        if app.css_styles:
            entries.append("         Adi.CSS_Source.CSS_Text (Inline_CSS)")

        lines.append("")
        if multi_link:
            lines.append("   procedure Set_CSS_Sheets")
            lines.append("     (Sheets  : Adi.CSS_Source"
                         ".Dynamic_Source_Entry_Array;")
            lines.append("      Success : out Boolean) is")
        else:
            lines.append("   procedure Set_CSS_File (Path : String;"
                         " Success : out Boolean) is")
        lines.append("      Mode_OK : Boolean;")
        lines.append("   begin")
        lines.append("      Adi.CSS_Source.Set_Dynamic_Sources")
        if multi_link:
            tail = (" & [Adi.CSS_Source.CSS_Text (Inline_CSS)]"
                    if app.css_styles else "")
            lines.append(f"        (Source, Sheets{tail}, Success);")
        elif len(entries) == 1:
            lines.append(f"        (Source, [{entries[0].strip()}], Success);")
        else:
            lines.append("        (Source,")
            for i, e in enumerate(entries):
                opener = "[" if i == 0 else " "
                closer = "]," if i == len(entries) - 1 else ","
                lines.append(f"        {opener}{e.strip()}{closer}")
            lines.append("         Success);")
        lines.append("      if Success then")
        lines.append(
            "         Adi.CSS_Source.Set_Mode")
        lines.append(
            "           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);")
        lines.append(
            "         Adi.CSS_Source.Set_Auto_Reload (Source, True);")
        lines.append(
            "         Success := Mode_OK;")
        lines.append("      end if;")
        lines.append(
            "   end " + ("Set_CSS_Sheets" if multi_link else "Set_CSS_File")
            + ";")

    lines.append("")

    # Private helper procedures — one per style-registration call — accumulated
    # during the style-walking section below and spliced into lines here so that
    # each Add_Static_Entry / Set_Part_Styles call gets its own stack frame.
    # GNAT at -O0 cannot reuse temporaries across separate procedure calls, so
    # the 169 KB Part_Style_Array temporary is released before the next call.
    helper_procs: list[str] = []
    build_start_idx = len(lines)

    # Build procedure/function — clean signature
    if has_window:
        lines.append("   function Build")
        lines.append("      return Adi.Window.Window_Handle is")
        win = app.window
        title = win.title.replace('"', '""')
        lines.append(
            f'      W : constant Adi.Window.Window_Handle :='
        )
        maximized_arg = ", Maximized => True" if win.maximized else ""
        w_amount, w_unit = win.width
        h_amount, h_unit = win.height
        lines.append(
            f'        Adi.Window.Create_Window_Handle ("{title}",'
            f" Adi.Window.Extent"
            f" ({w_unit} ({w_amount}), {h_unit} ({h_amount}))"
            f"{maximized_arg});"
        )
    elif has_dialog:
        lines.append("   function Build")
        lines.append("      return Adi.Widget.Dialog.Dialog_Handle is")
        lines.append(
            "      D : constant Adi.Widget.Dialog.Dialog_Handle :="
        )
        lines.append("        Adi.Widget.Dialog.Create_Handle;")
    else:
        lines.append("   function Build")
        lines.append("      return Adi.Widget.Widget_Handle is")

    # Local declarations for internal widgets
    for w in internal:
        ada_type = widget_ada_type(w, generics_map)
        create = widget_create_expr(w, generics_map,
                                     i18n=i18n, i18n_context=app.i18n_context)
        lines.append(f"      {w.wid} : constant {ada_type} := {create};")

    lines.append("   begin")

    # Create exported widgets
    if exported:
        lines.append("      --  Create widgets")
        for w in exported:
            create = widget_create_expr(w, generics_map,
                                         i18n=i18n, i18n_context=app.i18n_context)
            lines.append(f"      {w.wid} := {create};")
        lines.append("")

    # Configure properties (non-callback setters, grammar-driven)
    config_lines = []
    for w in all_widgets:
        if w.tag not in GRAMMAR:
            continue
        use_i18n = i18n and not w.i18n_disabled
        tag_info = GRAMMAR[w.tag]
        pkg = w.generic_name if tag_info["generic"] else tag_info["package"]
        for attr in tag_info["attributes"]:
            if not attr["setter"] or attr["type"] == "callback":
                continue
            field_name = _attr_to_field(attr["name"])
            value = getattr(w, field_name, None)
            if value:
                setter = attr["setter"]
                is_base = attr.get("setter_target") == "base"
                call_pkg = "Adi.Widget" if is_base else pkg
                call_wid = f"+{w.wid}" if is_base else w.wid
                if attr["setter_style"] == "flag":
                    config_lines.append(
                        f"      {call_pkg}.{setter} ({call_wid});"
                    )
                elif attr["type"] == "image":
                    escaped = str(value).replace('"', '""')
                    config_lines.append(
                        f'      {call_pkg}.{setter}'
                        f' ({call_wid}, Adi.Assets.Get_Image ("{escaped}"));'
                    )
                elif attr["type"] == "string":
                    if use_i18n and attr.get("translatable") and value:
                        ctx = w.i18n_contexts.get(attr["name"], app.i18n_context)
                        wrapped = _i18n_wrap(str(value), ctx)
                        config_lines.append(
                            f'      {call_pkg}.{setter} ({call_wid}, {wrapped});'
                        )
                    else:
                        escaped = str(value).replace('"', '""')
                        config_lines.append(
                            f'      {call_pkg}.{setter} ({call_wid}, "{escaped}");'
                        )
                else:
                    config_lines.append(
                        f"      {call_pkg}.{setter} ({call_wid}, {value});"
                    )
    if config_lines:
        lines.append("      --  Configure properties")
        lines.extend(config_lines)
        lines.append("")

    # Universal label attribute (any widget can have a floating label)
    label_lines = []
    for w in all_widgets:
        if w.label:
            use_i18n = i18n and not w.i18n_disabled
            if use_i18n:
                ctx = w.i18n_contexts.get("label", app.i18n_context)
                wrapped = _i18n_wrap(w.label, ctx)
                label_lines.append(
                    f'      Adi.Widget.Set_Label (+{w.wid}, {wrapped});'
                )
            else:
                escaped = w.label.replace('"', '""')
                label_lines.append(
                    f'      Adi.Widget.Set_Label (+{w.wid}, "{escaped}");'
                )
    if label_lines:
        lines.append("      --  Set labels")
        lines.extend(label_lines)
        lines.append("")

    # Wire direct widget callbacks (grammar-driven)
    cb_lines = []
    for w in all_widgets:
        if w.tag not in GRAMMAR:
            continue
        tag_info = GRAMMAR[w.tag]
        pkg = w.generic_name if tag_info["generic"] else tag_info["package"]
        for attr in tag_info["attributes"]:
            if not attr["setter"] or attr["type"] != "callback":
                continue
            field_name = _attr_to_field(attr["name"])
            value = getattr(w, field_name, "")
            if value:
                cb_lines.append(f"      if {value} /= null then")
                cb_lines.append(
                    f"         {pkg}.{attr['setter']} ({w.wid}, {value});"
                )
                cb_lines.append("      end if;")
    if cb_lines:
        lines.append("      --  Wire callbacks")
        lines.extend(cb_lines)
        lines.append("")

    # Apply styles — codegen-time mode selection
    #
    # Every widget goes under the selectors that name it. What a stylesheet
    # may select is fixed by the XML, not by the rules that happen to exist
    # when the generator runs, so live reload can introduce a tag or id rule
    # later and have it land. Names nothing defines resolve to empty styles
    # and merge as no-ops.
    # Each entry: (wid, css_classes_list, tag_selector, id_selector)
    bound_widgets: list[tuple[str, list[str], str, str]] = [
        (w.wid, w.css_classes, w.tag, w.wid if w.explicit_id else "")
        for w in all_widgets
    ]
    dialog_style_targets: list[tuple[str, list[str]]] = []
    if app.dialog is not None:
        dialog_defs = [
            ("dialog", app.dialog.css_classes),
            ("dialog_panel", app.dialog.panel_classes),
            ("dialog_title", app.dialog.title_classes),
            ("dialog_message", app.dialog.message_classes),
            ("dialog_button_row", app.dialog.button_row_classes),
            ("dialog_button", app.dialog.button_classes),
            ("dialog_primary_button", app.dialog.primary_button_classes),
        ]
        dialog_style_targets = [
            (name, classes) for name, classes in dialog_defs if classes
        ]

    if uses_css_source and (bound_widgets or dialog_style_targets):
        # `dialog_style_targets` carries the dialog's own backdrop/panel/title/
        # etc. classes. They must register Add_Static_Entry for the
        # Static_Mode fallback even when the dialog has no styled child
        # widgets — otherwise dynamic CSS load failures (e.g. a release
        # build that doesn't ship the .css file at the expected path) leave
        # those Bind_Class calls resolving to Empty_Part_Styles.
        if live_css:
            # CSS_Source mode — decided at codegen time
            #
            # Each stylesheet package carries its own selector manifest, so
            # register them whole, qualified, and in link order. Nothing here
            # needs to know which selectors a sheet defines, which is what
            # lets a styles-only <link> work and what makes two sheets that
            # both define `button` merge in file order instead of colliding
            # on one use-visible name.
            # One scope over the whole install: the static fallback and
            # the dynamic sheets are one configuration, and the scope
            # publishes it on the way out however the block ends. A
            # hand-written Begin/End pair around this would be skipped by
            # anything that raises in the middle, leaving the source
            # unable to restyle for the rest of the run.
            lines.append(
                "      --  Install the stylesheets as one batch:"
                " precompiled"
            )
            lines.append(
                "      --  styles as static fallback, then dynamic CSS"
                " and the mode"
            )
            lines.append("      declare")
            lines.append(
                "         Update : Adi.CSS_Source.Update_Scope"
                " (Source'Access);"
            )
            lines.append("         pragma Unreferenced (Update);")
            lines.append("         Loaded, Mode_OK : Boolean;")
            lines.append("      begin")
            if selector_sources or has_root_metadata:
                lines.append(
                    "         Adi.CSS_Source.Clear_Static_Entries (Source);"
                )
                for source in selector_sources:
                    lines.append(f"         {source} (Source);")
                if has_root_metadata:
                    lines.append(
                        "         Adi.CSS_Source.Set_Static_Metadata"
                        " (Source, Static_Root_Metadata);"
                    )
                lines.append("")
            has_link = bool(any(link.href for link in app.css_links))
            has_style = bool(app.css_styles)

            lines.extend(dynamic_sources_call(app, "         ", "Loaded"))

            if not has_link and not has_style:
                lines.append("         Loaded := False;")

            lines.append("         if Loaded then")
            lines.append(
                "            Adi.CSS_Source.Set_Mode"
            )
            lines.append(
                "              (Source, Adi.CSS_Source.Dynamic_Mode,"
                " Mode_OK);"
            )
            lines.append("         else")
            lines.append("            Mode_OK := False;")
            lines.append("         end if;")
            lines.append("         if not Mode_OK then")
            lines.append(
                "            Adi.CSS_Source.Set_Mode"
            )
            lines.append(
                "              (Source, Adi.CSS_Source.Static_Mode,"
                " Mode_OK);"
            )
            lines.append("         end if;")
            lines.append("      end;")
            lines.append("")
            if has_window:
                lines.append(
                    "      Adi.CSS_Source.Attach_Window (Source, W);"
                )
            lines.append(
                "      --  Bind every widget under the selectors naming it"
            )
            if root is not None and not has_dialog:
                lines.append(
                    f"      Adi.CSS_Source.Bind_Root_Metadata (Source, +{root.wid});"
                )
            for wid, cls_list, tag_sel, id_sel in bound_widgets:
                names_str = " ".join(cls_list)
                lines.append("      Adi.CSS_Source.Bind_Selector_Set")
                args = ["(Source     => Source,", f" W          => +{wid},"]
                if tag_sel:
                    args.append(f' Tag_Name   => "{tag_sel}",')
                if names_str:
                    args.append(f' Class_Name => "{names_str}",')
                if id_sel:
                    args.append(f' Id_Name    => "{id_sel}",')
                args[-1] = args[-1][:-1] + ");"
                for arg in args:
                    lines.append(f"        {arg}")
            lines.append("")
        else:
            #  Static mode — the same manifests and the same per-widget
            #  selector sets as live mode, resolved once through a source
            #  pinned to Static_Mode. Naming the selectors rather than the
            #  Ada constants is what keeps a styles-only <link> working and
            #  what lets two sheets defining the same selector merge in link
            #  order instead of colliding on one use-visible name. Nothing
            #  is loaded from disk, which is the point of --no-live-css.
            lines.append("      --  Apply precompiled styles")
            lines.append("      Adi.CSS_Source.Clear_Static_Entries (Source);")
            for source in selector_sources:
                lines.append(f"      {source} (Source);")
            if has_root_metadata:
                lines.append(
                    "      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);"
                )
            lines.append("      declare")
            lines.append("         Mode_OK : Boolean;")
            lines.append("      begin")
            lines.append(
                "         Adi.CSS_Source.Set_Mode"
            )
            lines.append(
                "           (Source, Adi.CSS_Source.Static_Mode, Mode_OK);"
            )
            lines.append("      end;")
            if has_window:
                lines.append(
                    "      Adi.CSS_Source.Attach_Window (Source, W);"
                )
            if root is not None and not has_dialog:
                lines.append(
                    f"      Adi.CSS_Source.Bind_Root_Metadata (Source, +{root.wid});"
                )
            for wid, cls_list, tag_sel, id_sel in bound_widgets:
                names_str = " ".join(cls_list)
                lines.append("      Adi.CSS_Source.Bind_Selector_Set")
                args = ["(Source     => Source,", f" W          => +{wid},"]
                if tag_sel:
                    args.append(f' Tag_Name   => "{tag_sel}",')
                if names_str:
                    args.append(f' Class_Name => "{names_str}",')
                if id_sel:
                    args.append(f' Id_Name    => "{id_sel}",')
                args[-1] = args[-1][:-1] + ");"
                for arg in args:
                    lines.append(f"        {arg}")
            lines.append("")
    elif (root is not None or has_dialog) and (live_css or link_pkgs or (inline_stylesheet and inline_stylesheet.root_properties)):
        if live_css:
            lines.append(
                "      --  Register root metadata and load dynamic CSS as"
                " one batch"
            )
            lines.append("      declare")
            lines.append(
                "         Update : Adi.CSS_Source.Update_Scope"
                " (Source'Access);"
            )
            lines.append("         pragma Unreferenced (Update);")
            lines.append("         Loaded, Mode_OK : Boolean;")
            lines.append("      begin")
            lines.append(
                "         Adi.CSS_Source.Clear_Static_Entries (Source);"
            )
            if link_pkgs or (inline_stylesheet and inline_stylesheet.root_properties):
                lines.append(
                    "         Adi.CSS_Source.Set_Static_Metadata"
                    " (Source, Static_Root_Metadata);"
                )
            has_link = bool(any(link.href for link in app.css_links))
            has_style = bool(app.css_styles)
            lines.extend(dynamic_sources_call(app, "         ", "Loaded"))
            if not has_link and not has_style:
                lines.append("         Loaded := False;")
            lines.append("         if Loaded then")
            lines.append(
                "            Adi.CSS_Source.Set_Mode"
            )
            lines.append(
                "              (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);"
            )
            lines.append("         else")
            lines.append("            Mode_OK := False;")
            lines.append("         end if;")
            lines.append("         if not Mode_OK then")
            lines.append(
                "            Adi.CSS_Source.Set_Mode"
            )
            lines.append(
                "              (Source, Adi.CSS_Source.Static_Mode, Mode_OK);"
            )
            lines.append("         end if;")
            lines.append("      end;")
            if has_window:
                lines.append(
                    "      Adi.CSS_Source.Attach_Window (Source, W);"
                )
            if root is not None and not has_dialog:
                lines.append(
                    f"      Adi.CSS_Source.Bind_Root_Metadata (Source, +{root.wid});"
                )
            lines.append("")
        else:
            lines.append("      --  Apply static root metadata")
            if has_window:
                lines.append(
                    "      Adi.CSS_Source.Attach_Window (Source, W);"
                )
            lines.append("      declare")
            lines.append("         Root_Meta : constant Adi.CSS_Parser.Stylesheet_Metadata :=")
            lines.append("           Static_Root_Metadata;")
            lines.append("      begin")
            if root is not None and not has_dialog:
                lines.append("         if Root_Meta.Has_Root_Style then")
                lines.append(
                    f"            Set_Part_Styles (+{root.wid}, Root_Meta.Root_Styles);"
                )
                lines.append("         end if;")
            else:
                lines.append("         null;")
            lines.append("      end;")
            lines.append("")

    # Splice style helper procedures before the Build function so each call
    # gets its own stack frame, preventing N × 169 KB stack accumulation.
    if helper_procs:
        lines[build_start_idx:build_start_idx] = helper_procs

    # Build hierarchy (bottom-up: children first, then parent wiring)
    hierarchy_lines: list[str] = []

    def emit_hierarchy(widget: XmlWidget):
        # Recurse into children first
        for child in widget.children:
            emit_hierarchy(child)
        for page in widget.pages:
            if page.child is not None:
                emit_hierarchy(page.child)
        # Then wire this widget's children/pages
        children_mode = GRAMMAR.get(widget.tag, {}).get(
            "children_mode", "children"
        )
        tag_info = GRAMMAR.get(widget.tag, {})
        pkg = widget.generic_name if tag_info.get("generic") else tag_info.get("package", "")
        if children_mode == "pages":
            for page in widget.pages:
                if page.component is not None:
                    inst_name = component_instance_name(
                        page.component.package_name
                    )
                    hierarchy_lines.append(
                        f"      {pkg}.Add_Page"
                        f" ({widget.wid}, {page.key}, {inst_name}.Build);"
                    )
                else:
                    hierarchy_lines.append(
                        f"      {pkg}.Add_Page"
                        f" ({widget.wid}, {page.key}, +{page.child.wid});"
                    )
        elif children_mode == "items":
            for item_text in widget.items:
                use_i18n = i18n and not widget.i18n_disabled
                if use_i18n and item_text:
                    wrapped = _i18n_wrap(item_text, app.i18n_context)
                    hierarchy_lines.append(
                        f'      {pkg}.Add_Item ({widget.wid}, {wrapped});'
                    )
                else:
                    escaped = item_text.replace('"', '""')
                    hierarchy_lines.append(
                        f'      {pkg}.Add_Item ({widget.wid}, "{escaped}");'
                    )
        if children_mode == "rows":
            for child in widget.children:
                hierarchy_lines.append(
                    f"      {pkg}.Append_Row ({widget.wid}, +{child.wid});"
                )
        elif children_mode not in ("pages", "items"):
            for child in widget.children:
                hierarchy_lines.append(
                    f"      Adi.Widget.Add_Child (+{widget.wid}, +{child.wid});"
                )

    if root is not None:
        emit_hierarchy(root)
    if hierarchy_lines:
        lines.append("      --  Build hierarchy")
        lines.extend(hierarchy_lines)
        lines.append("")

    # Wire option groups
    og_lines = []
    for og in app.option_groups:
        group_var = f"{og.generic_name}_Group"
        for opt in og.options:
            og_lines.append(
                f"      {og.generic_name}.Set_Button ({group_var},"
                f" {opt.value}, {opt.button_id});"
            )
        if og.on_changed:
            wrapper = f"{og.on_changed}_Option_Wrapper"
            conn_var = f"{og.generic_name}_Group_Conn"
            og_lines.append(
                f"      {og.generic_name}.Disconnect_Changed"
                f" ({group_var}, {conn_var});"
            )
            og_lines.append(
                f"      {conn_var} := {og.generic_name}.Connect_Changed"
                f" ({group_var}, {wrapper}'Unrestricted_Access);"
            )
    if og_lines:
        lines.append("      --  Wire option groups")
        lines.extend(og_lines)
        lines.append("")

    # Auto-wire CSS reload via Set_On_Tick
    if has_window and (live_css or app.component_packages):
        lines.append("      --  Auto-wire CSS live reload")
        lines.append(
            "      Adi.Window.Connect_Tick"
            " (W, Tick_Styles_CB'Unrestricted_Access);"
        )
        lines.append("")

    # Set root / return
    if has_window:
        lines.append(f"      Adi.Window.Set_Root (W, +{root.wid});")
        lines.append("      return W;")
        lines.append("   end Build;")
    elif has_dialog:
        dlg = app.dialog
        lines.append("      --  Configure dialog")
        if dlg.title:
            escaped = dlg.title.replace('"', '""')
            lines.append(f'      Adi.Widget.Dialog.Set_Title (D, "{escaped}");')
        if dlg.message:
            escaped = dlg.message.replace('"', '""')
            lines.append(f'      Adi.Widget.Dialog.Set_Message (D, "{escaped}");')
        if dlg.buttons:
            lines.append(
                f"      Adi.Widget.Dialog.{DIALOG_BUTTON_PRESETS[dlg.buttons]} (D);"
            )
        if dlg.default_button is not None:
            lines.append(
                f"      Adi.Widget.Dialog.Set_Default_Button (D, {dlg.default_button});"
            )
        if dlg.dismiss_on_backdrop is not None:
            val = "True" if dlg.dismiss_on_backdrop else "False"
            lines.append(
                f"      Adi.Widget.Dialog.Set_Dismiss_On_Backdrop (D, {val});"
            )
        if dlg.dismiss_on_escape is not None:
            val = "True" if dlg.dismiss_on_escape else "False"
            lines.append(
                f"      Adi.Widget.Dialog.Set_Dismiss_On_Escape (D, {val});"
            )
        if dlg.content_widget is not None:
            lines.append(
                f"      Adi.Widget.Dialog.Set_Content (D, +{dlg.content_widget.wid});"
            )
        if not live_css and (link_pkgs or (inline_stylesheet and inline_stylesheet.root_properties)):
            lines.append("      declare")
            lines.append("         Root_Meta : constant Adi.CSS_Parser.Stylesheet_Metadata :=")
            lines.append("           Static_Root_Metadata;")
            lines.append("      begin")
            lines.append("         if Root_Meta.Has_Root_Style then")
            lines.append(
                "            Adi.Widget.Dialog.Set_Panel_Style"
                " (D, Root_Meta.Root_Styles);"
            )
            lines.append("         end if;")
            lines.append("      end;")
        if not live_css:
            if dlg.css_classes:
                lines.append(
                    "      Adi.Widget.Dialog.Set_Part_Styles"
                    f" (D, {class_style_expr(dlg.css_classes)});"
                )
            if dlg.panel_classes:
                lines.append(
                    "      Adi.Widget.Dialog.Set_Panel_Style"
                    f" (D, {class_style_expr(dlg.panel_classes)});"
                )
            if dlg.title_classes:
                lines.append(
                    "      Adi.Widget.Dialog.Set_Title_Style"
                    f" (D, {class_style_expr(dlg.title_classes)});"
                )
            if dlg.message_classes:
                lines.append(
                    "      Adi.Widget.Dialog.Set_Message_Style"
                    f" (D, {class_style_expr(dlg.message_classes)});"
                )
            if dlg.button_row_classes:
                lines.append(
                    "      Adi.Widget.Dialog.Set_Button_Row_Style"
                    f" (D, {class_style_expr(dlg.button_row_classes)});"
                )
        if dlg.button_classes:
            lines.append(
                "      Adi.Widget.Dialog.Set_Button_Style"
                f" (D, {class_style_expr(dlg.button_classes)});"
            )
        if dlg.primary_button_classes:
            lines.append(
                "      Adi.Widget.Dialog.Set_Primary_Button_Style"
                f" (D, {class_style_expr(dlg.primary_button_classes)});"
            )
        if live_css:
            lines.append("      --  Bind dialog live CSS")
            lines.append(
                "      Adi.CSS_Source.Bind_Root_Metadata"
                " (Source, +Adi.Widget.Dialog.Get_Content_Panel_Handle (D));"
            )
            if dlg.css_classes:
                lines.append(
                    "      Adi.CSS_Source.Bind_Class"
                    f' (Source, "{" ".join(dlg.css_classes)}",'
                    " Adi.Widget.Dialog.To_Widget_Handle (D));"
                )
            if dlg.panel_classes:
                lines.append(
                    "      Adi.CSS_Source.Bind_Class"
                    f' (Source, "{" ".join(dlg.panel_classes)}",'
                    " +Adi.Widget.Dialog.Get_Content_Panel_Handle (D));"
                )
            if dlg.title_classes:
                lines.append(
                    "      Adi.CSS_Source.Bind_Class"
                    f' (Source, "{" ".join(dlg.title_classes)}",'
                    " +Adi.Widget.Dialog.Get_Title_Handle (D));"
                )
            if dlg.message_classes:
                lines.append(
                    "      Adi.CSS_Source.Bind_Class"
                    f' (Source, "{" ".join(dlg.message_classes)}",'
                    " +Adi.Widget.Dialog.Get_Message_Handle (D));"
                )
            if dlg.button_row_classes:
                lines.append(
                    "      Adi.CSS_Source.Bind_Class"
                    f' (Source, "{" ".join(dlg.button_row_classes)}",'
                    " +Adi.Widget.Dialog.Get_Button_Row_Handle (D));"
                )
            if dlg.button_classes or dlg.primary_button_classes:
                for button_index in range(1, dialog_button_count + 1):
                    button_classes = list(dlg.button_classes)
                    if button_index == dialog_default_button:
                        button_classes.extend(dlg.primary_button_classes)
                    if button_classes:
                        lines.append(
                            "      Adi.CSS_Source.Bind_Class"
                            f' (Source, "{" ".join(button_classes)}",'
                            f" +Adi.Widget.Dialog.Get_Button_Handle (D, {button_index}));"
                        )
        lines.append("      return D;")
        lines.append("   end Build;")
    else:
        lines.append(
            f"      return +{root.wid};"
        )
        lines.append("   end Build;")
    lines.append("")

    lines.append("   end Instance;")
    lines.append("")
    lines.append(f"end {package_name};")

    return "\n".join(lines) + "\n"


# ── Main ──────────────────────────────────────────────────────────────────────


def main():
    global GRAMMAR, WIDGET_TAGS, WIDGET_PACKAGES

    parser = argparse.ArgumentParser(
        description="Convert XML widget descriptions to Ada packages"
    )
    parser.add_argument("input", help="Input XML file")
    parser.add_argument(
        "--output-dir", "-o", default=".", help="Output directory"
    )
    parser.add_argument(
        "--package-name", "-p", required=True, help="Ada package name"
    )
    parser.add_argument(
        "--grammar", "-g", default=None,
        help="Extra widget grammar XML file (merged with built-in)"
    )
    parser.add_argument(
        "--i18n", action="store_true", default=False,
        help="Wrap translatable strings with Adi.I18N.T() calls"
    )
    parser.add_argument(
        "--no-live-css", action="store_true", default=False,
        help=(
            "Disable CSS live-reload: emit static-only codegen even when "
            "<link> or <style> are present (no Add_Dynamic_File, no "
            "Dynamic_Mode). Use for release builds that must not touch "
            "the filesystem at startup."
        ),
    )

    args = parser.parse_args()

    # Merge extra grammar if provided
    if args.grammar:
        extra = load_widget_grammar(args.grammar)
        GRAMMAR.update(extra)
        WIDGET_TAGS = set(GRAMMAR.keys())
        WIDGET_PACKAGES = {
            tag: info["package"]
            for tag, info in GRAMMAR.items()
            if not info["generic"]
        }

    p = Parser()
    try:
        app = p.parse(args.input)
    except (ET.ParseError, ValueError) as e:
        print(f"Error parsing XML: {e}", file=sys.stderr)
        sys.exit(1)

    os.makedirs(args.output_dir, exist_ok=True)

    file_base = args.package_name.lower()
    spec_path = os.path.join(args.output_dir, f"{file_base}.ads")
    body_path = os.path.join(args.output_dir, f"{file_base}.adb")

    spec_code = generate_spec(app, args.package_name,
                              no_live_css=args.no_live_css)
    body_code = generate_body(app, args.package_name,
                              i18n=args.i18n,
                              no_live_css=args.no_live_css)

    with open(spec_path, "w") as f:
        f.write(spec_code)
    print(f"Generated {spec_path}")

    with open(body_path, "w") as f:
        f.write(body_code)
    print(f"Generated {body_path}")


if __name__ == "__main__":
    main()
