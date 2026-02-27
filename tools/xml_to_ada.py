#!/usr/bin/env python3
"""
XML to Ada Widget Code Generator

Converts XML widget descriptions into Ada packages that construct widget trees,
apply styles, and wire up hierarchy.

Usage:
    python3 xml_to_ada.py input.xml --output-dir dir --package-name Name
"""

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
    disabled: bool = False
    looping: bool = False
    children: list["XmlWidget"] = field(default_factory=list)
    pages: list[XmlPage] = field(default_factory=list)
    items: list[str] = field(default_factory=list)


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


@dataclass
class XmlWindow:
    title: str
    width: float
    height: float
    root_widget: XmlWidget


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
    option_groups: list[XmlOptionGroup] = field(default_factory=list)
    css_links: list[CssLink] = field(default_factory=list)
    css_styles: list[str] = field(default_factory=list)
    component_packages: list[str] = field(default_factory=list)


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
            "access_type": "",
            "create": "",
            "generic": widget_elem.get("generic", "").lower() == "true",
            "children_mode": widget_elem.get("children-mode", "children"),
            "attributes": [],
        }
        for child in widget_elem:
            if child.tag == "package":
                info["package"] = child.text.strip()
            elif child.tag == "access-type":
                info["access_type"] = child.text.strip()
            elif child.tag == "create":
                info["create"] = child.text.strip()
            elif child.tag == "attribute":
                attr = {
                    "name": child.get("name"),
                    "type": child.get("type", "string"),
                    "create_param": child.get("create-param", "").lower() == "true",
                    "default": child.get("default"),
                    "setter": child.get("setter"),
                    "setter_style": child.get("setter-style"),
                    "meta": child.get("meta", "").lower() == "true",
                    "required": child.get("required", "").lower() == "true",
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

WIDGET_ACCESS_TYPES = {
    tag: f'{info["package"]}.{info["access_type"]}'
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


def widget_ada_type(widget: XmlWidget, generics_map: dict[str, XmlGeneric]) -> str:
    """Return the Ada access type for a widget."""
    tag_info = GRAMMAR[widget.tag]
    if tag_info["generic"]:
        return f"{widget.generic_name}.{tag_info['access_type']}"
    return f'{tag_info["package"]}.{tag_info["access_type"]}'


def widget_create_expr(
    widget: XmlWidget, generics_map: dict[str, XmlGeneric]
) -> str:
    """Return the Ada Create expression for a widget."""
    tag_info = GRAMMAR[widget.tag]
    template = tag_info["create"]

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
            value = value.replace('"', '""')
        elif attr["type"] == "bool":
            value = "True" if value else (attr["default"] or "False")
        subs[field_name] = value

    return template.format_map(subs)


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
            elif tag == "style":
                text = (elem.text or "").strip()
                if text:
                    app.css_styles.append(text)
            elif tag == "window":
                if app.window is not None or app.root_widget is not None:
                    raise ValueError(
                        "Only one <window> or root widget allowed"
                    )
                app.window = self._parse_window(elem)
            elif tag in WIDGET_TAGS:
                if app.root_widget is not None or app.window is not None:
                    raise ValueError(
                        "Only one <window> or root widget allowed"
                    )
                app.root_widget = self._parse_widget(elem)
            else:
                raise ValueError(
                    f"Unsupported element <{tag}> inside <adi>"
                )

        if app.root_widget is None and app.window is None:
            raise ValueError("No <window> or root widget element found")

        # Collect component package references from the widget tree
        root = get_root_widget(app)
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
            width=float(elem.get("width", "800")),
            height=float(elem.get("height", "600")),
            root_widget=self._parse_widget(widget_children[0]),
        )

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
        )

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


def get_root_widget(app: XmlApp) -> XmlWidget:
    """Return the root widget whether from a <window> or bare widget."""
    if app.window is not None:
        return app.window.root_widget
    return app.root_widget


def generate_spec(app: XmlApp, package_name: str) -> str:
    """Generate the .ads (spec) file."""
    generics_map = {g.name: g for g in app.generics}
    root = get_root_widget(app)
    all_widgets = collect_all_widgets(root)
    exported = [w for w in all_widgets if w.explicit_id]
    has_window = app.window is not None
    live_css = bool(any(link.href for link in app.css_links) or app.css_styles)

    # Compute with clauses — only packages referenced in the spec
    withs: set[str] = set()
    if has_window:
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
            "      function Build return Adi.Window.Window_Access;"
        )
    else:
        lines.append(
            "      function Build return Adi.Widget.Widget_Access;"
        )
    lines.append("")

    # Tick_Styles is always emitted so parent packages can recurse into
    # component instances without conditional API checks.
    lines.append("      procedure Tick_Styles (Reloaded : out Boolean;")
    lines.append("                             Success  : out Boolean);")
    lines.append("")

    # Set_CSS_File — only when dynamic <link> elements are present
    if live_css:
        lines.append(
            "      procedure Set_CSS_File (Path : String;"
            " Success : out Boolean);"
        )
        lines.append("")

    lines.append("   end Instance;")
    lines.append("")
    lines.append(f"end {package_name};")

    return "\n".join(lines) + "\n"


def ada_string_literal(s: str) -> str:
    """Escape a string for use as an Ada string literal.

    Handles embedded newlines by splitting into concatenated lines
    with ASCII.LF between them.
    """
    lines = s.split("\n")
    parts = []
    for i, line in enumerate(lines):
        escaped = line.replace('"', '""')
        parts.append(f'"{escaped}"')
        if i < len(lines) - 1:
            parts.append("ASCII.LF")
    return " & ".join(parts)


def generate_body(app: XmlApp, package_name: str) -> str:
    """Generate the .adb (body) file."""
    generics_map = {g.name: g for g in app.generics}
    root = get_root_widget(app)
    all_widgets = collect_all_widgets(root)
    exported = [w for w in all_widgets if w.explicit_id]
    internal = [w for w in all_widgets if not w.explicit_id]
    has_window = app.window is not None
    live_css = bool(any(link.href for link in app.css_links) or app.css_styles)

    # Compute spec-level withs so we know what the body inherits
    spec_withs: set[str] = set()
    if has_window:
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

    # Compile inline <style> CSS to Ada constants
    inline_groups: dict = {}
    inline_classes: set[str] = set()
    if app.css_styles:
        combined_inline = "\n".join(app.css_styles)
        inline_rules = css_to_ada.parse_css(combined_inline)
        if inline_rules:
            inline_groups = css_to_ada.group_rules_by_widget(inline_rules)
            for key, grp in inline_groups.items():
                if grp.selector_type == "class":
                    inline_classes.add(grp.name)

    # Body needs Adi.Widget (for Set_Part_Styles, Add_Child, Widget_Access)
    # + any widget packages not already in the spec.
    # Always include Adi.Widget even if in spec — need `use` clause.
    # Check if any widget uses multiple CSS classes (needs Merge_Part_Styles)
    has_multi_class = any(
        len(w.css_classes) > 1 for w in all_widgets
    )

    body_withs: list[str] = ["Adi.Widget"]
    if live_css or has_multi_class:
        body_withs.append("Adi.CSS_Source")
    if has_window and live_css:
        body_withs.append("Adi.Window")
    if inline_groups:
        body_withs.append("Adi.CSS_Styles")
        body_withs.append("Adi.Widget_Styles")
    for w in internal:
        if w.tag in WIDGET_PACKAGES:
            pkg = WIDGET_PACKAGES[w.tag]
            if pkg not in spec_withs and pkg not in body_withs:
                body_withs.append(pkg)

    lines = [
        "--  Auto-generated from XML",
        "--  Do not edit manually",
        "",
        "pragma Ada_2022;",
        "",
    ]

    for bw in sorted(body_withs):
        lines.append(f"with {bw}; use {bw};")

    # Import styles packages derived from <link> elements
    link_pkgs = list(dict.fromkeys(link.styles_pkg for link in app.css_links))
    for pkg in sorted(link_pkgs):
        lines.append(f"with {pkg}; use {pkg};")

    lines.append("")
    lines.append(f"package body {package_name} is")
    lines.append("")
    lines.append("   package body Instance is")

    # Package-level state for live CSS mode
    if live_css:
        lines.append("   Source : aliased Adi.CSS_Source.Style_Source;")
        # Inline CSS constant for dynamic loading
        if app.css_styles:
            combined = "\n".join(app.css_styles)
            lines.append(
                f"   Inline_CSS : constant String := {ada_string_literal(combined)};"
            )
        # Compiled inline style declarations (for static fallback)
        if inline_groups:
            lines.append("")
            decl_lines = css_to_ada.generate_style_declarations(
                inline_groups, indent="   ")
            lines.extend(decl_lines)

    # use type declarations for callback access types (needed for /= null)
    for cb in app.callbacks:
        lines.append(f"   use type {cb.cb_type};")

    # Package-level option group variables (only those without id, others are in spec)
    for og in app.option_groups:
        if not og.id:
            group_var = f"{og.generic_name}_Group"
            lines.append(
                f"   {group_var} : aliased {og.generic_name}.Option_Group;"
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

    if has_window and (live_css or app.component_packages):
        lines.append("")
        lines.append("   procedure Tick_Styles_CB (DT : Duration) is")
        lines.append("      pragma Unreferenced (DT);")
        lines.append("      Reloaded, Success : Boolean;")
        lines.append("   begin")
        lines.append("      Tick_Styles (Reloaded, Success);")
        lines.append("   end Tick_Styles_CB;")

    # Set_CSS_File — clear + reload dynamic entries
    if live_css:
        lines.append("")
        lines.append("   procedure Set_CSS_File (Path : String;"
                     " Success : out Boolean) is")
        lines.append("   begin")
        lines.append("      Adi.CSS_Source.Clear_Dynamic_Entries (Source);")
        lines.append(
            "      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);")
        lines.append("      if Success then")
        lines.append(
            "         Adi.CSS_Source.Reload_Dynamic (Source, Success);")
        lines.append("      end if;")
        lines.append("   end Set_CSS_File;")

    lines.append("")

    # Build procedure/function — clean signature
    if has_window:
        lines.append("   function Build")
        lines.append("      return Adi.Window.Window_Access is")
        win = app.window
        title = win.title.replace('"', '""')
        lines.append(
            f'      W : constant Adi.Window.Window_Access :='
        )
        lines.append(
            f'        Adi.Window.Create_Window ("{title}",'
            f" ({win.width}, {win.height}));"
        )
    else:
        lines.append("   function Build")
        lines.append("      return Adi.Widget.Widget_Access is")

    # Local declarations for internal widgets
    for w in internal:
        ada_type = widget_ada_type(w, generics_map)
        create = widget_create_expr(w, generics_map)
        lines.append(f"      {w.wid} : constant {ada_type} := {create};")

    lines.append("   begin")

    # Create exported widgets
    if exported:
        lines.append("      --  Create widgets")
        for w in exported:
            create = widget_create_expr(w, generics_map)
            lines.append(f"      {w.wid} := {create};")
        lines.append("")

    # Configure properties (non-callback setters, grammar-driven)
    config_lines = []
    for w in all_widgets:
        if w.tag not in GRAMMAR:
            continue
        for attr in GRAMMAR[w.tag]["attributes"]:
            if not attr["setter"] or attr["type"] == "callback":
                continue
            field_name = _attr_to_field(attr["name"])
            value = getattr(w, field_name, None)
            if value:
                if attr["setter_style"] == "flag":
                    config_lines.append(f"      {w.wid}.{attr['setter']};")
                elif attr["type"] == "string":
                    escaped = str(value).replace('"', '""')
                    config_lines.append(
                        f'      {w.wid}.{attr["setter"]} ("{escaped}");'
                    )
                else:
                    config_lines.append(
                        f"      {w.wid}.{attr['setter']} ({value});"
                    )
    if config_lines:
        lines.append("      --  Configure properties")
        lines.extend(config_lines)
        lines.append("")

    # Universal label attribute (any widget can have a floating label)
    label_lines = []
    for w in all_widgets:
        if w.label:
            escaped = w.label.replace('"', '""')
            label_lines.append(
                f'      Adi.Widget.Set_Label ({w.wid}.all, "{escaped}");'
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
        for attr in GRAMMAR[w.tag]["attributes"]:
            if not attr["setter"] or attr["type"] != "callback":
                continue
            field_name = _attr_to_field(attr["name"])
            value = getattr(w, field_name, "")
            if value:
                cb_lines.append(f"      if {value} /= null then")
                cb_lines.append(
                    f"         {w.wid}.{attr['setter']} ({value});"
                )
                cb_lines.append("      end if;")
    if cb_lines:
        lines.append("      --  Wire callbacks")
        lines.extend(cb_lines)
        lines.append("")

    # Apply styles — codegen-time mode selection
    # Build list of widgets with CSS classes:
    # Each entry: (wid, css_classes_list, class_names_str)
    styled_widgets = []
    for w in all_widgets:
        if w.css_classes:
            styled_widgets.append((w.wid, w.css_classes))

    if styled_widgets:
        if live_css:
            # CSS_Source mode — decided at codegen time
            # Deduplicate static entries by individual class name
            seen_classes: set[str] = set()
            unique_entries: list[tuple[str, str]] = []
            for _, cls_list in styled_widgets:
                for cls in cls_list:
                    if cls not in seen_classes:
                        seen_classes.add(cls)
                        style_const = (
                            f"{to_ada_identifier(cls)}_Class_Part_Styles"
                        )
                        unique_entries.append((cls, style_const))

            if unique_entries:
                lines.append(
                    "      --  Register precompiled styles as static fallback"
                )
                lines.append(
                    "      Adi.CSS_Source.Clear_Static_Entries (Source);"
                )
                for css_class, style_const in unique_entries:
                    lines.append(
                        f"      Adi.CSS_Source.Add_Static_Entry"
                        f" (Source, Adi.CSS_Source.Class_Entry"
                        f' ("{css_class}", {style_const}));'
                    )
                lines.append("")
            lines.append("      --  Load dynamic CSS and choose mode")
            lines.append("      declare")
            lines.append("         Loaded, Mode_OK : Boolean;")
            lines.append("      begin")

            has_link = bool(any(link.href for link in app.css_links))
            has_style = bool(app.css_styles)

            # Emit Add_Dynamic_File for each <link> that has an actual file path
            for link in app.css_links:
                if link.href:
                    lines.append(
                        "         Adi.CSS_Source.Add_Dynamic_File"
                    )
                    lines.append(
                        f'           (Source, "{link.href}", Loaded);'
                    )

            # Emit Add_Dynamic_String for inline <style>
            if has_style:
                lines.append(
                    "         Adi.CSS_Source.Add_Dynamic_String"
                )
                lines.append(
                    "           (Source, Inline_CSS, Loaded);"
                )

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
            lines.append(
                "      --  Bind every widget that has a CSS class"
            )
            for wid, cls_list in styled_widgets:
                names_str = " ".join(cls_list)
                lines.append(
                    f"      Adi.CSS_Source.Bind_Class"
                    f' (Source, "{names_str}", {wid});'
                )
            lines.append("")
        else:
            # Static mode — direct Set_Part_Styles calls
            lines.append("      --  Apply precompiled styles")
            for wid, cls_list in styled_widgets:
                if len(cls_list) == 1:
                    style_const = (
                        f"{to_ada_identifier(cls_list[0])}_Class_Part_Styles"
                    )
                    lines.append(
                        f"      Set_Part_Styles ({wid}.all, {style_const});"
                    )
                else:
                    # Merge multiple class styles
                    consts = [
                        f"{to_ada_identifier(c)}_Class_Part_Styles"
                        for c in cls_list
                    ]
                    # Build nested Merge_Part_Styles calls
                    expr = consts[0]
                    for c in consts[1:]:
                        expr = f"Adi.CSS_Source.Merge_Part_Styles ({expr}, {c})"
                    lines.append(
                        f"      Set_Part_Styles ({wid}.all, {expr});"
                    )
            lines.append("")

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
        if children_mode == "pages":
            for page in widget.pages:
                if page.component is not None:
                    inst_name = component_instance_name(
                        page.component.package_name
                    )
                    hierarchy_lines.append(
                        f"      {widget.wid}.Add_Page"
                        f" ({page.key}, {inst_name}.Build);"
                    )
                else:
                    hierarchy_lines.append(
                        f"      {widget.wid}.Add_Page ({page.key}, {page.child.wid});"
                    )
        elif children_mode == "items":
            for item_text in widget.items:
                escaped = item_text.replace('"', '""')
                hierarchy_lines.append(
                    f'      {widget.wid}.Add_Item ("{escaped}");'
                )
        if children_mode == "rows":
            for child in widget.children:
                hierarchy_lines.append(
                    f"      {widget.wid}.Append_Row ({child.wid});"
                )
        elif children_mode not in ("pages", "items"):
            for child in widget.children:
                hierarchy_lines.append(
                    f"      {widget.wid}.Add_Child ({child.wid});"
                )

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
                f"      {group_var}.Set_Button ({opt.value}, {opt.button_id});"
            )
        if og.on_changed:
            wrapper = f"{og.on_changed}_Option_Wrapper"
            og_lines.append(
                f"      {group_var}.Set_On_Changed ({wrapper}'Unrestricted_Access);"
            )
    if og_lines:
        lines.append("      --  Wire option groups")
        lines.extend(og_lines)
        lines.append("")

    # Auto-wire CSS reload via Set_On_Tick
    if has_window and (live_css or app.component_packages):
        lines.append("      --  Auto-wire CSS live reload")
        lines.append(
            "      Adi.Window.Set_On_Tick"
            " (W.all, Tick_Styles_CB'Unrestricted_Access);"
        )
        lines.append("")

    # Set root / return
    if has_window:
        lines.append(f"      W.Set_Root ({root.wid});")
        lines.append("      return W;")
        lines.append("   end Build;")
    else:
        lines.append(
            f"      return Adi.Widget.Widget_Access ({root.wid});"
        )
        lines.append("   end Build;")
    lines.append("")

    lines.append("   end Instance;")
    lines.append("")
    lines.append(f"end {package_name};")

    return "\n".join(lines) + "\n"


# ── Main ──────────────────────────────────────────────────────────────────────


def main():
    global GRAMMAR, WIDGET_TAGS, WIDGET_PACKAGES, WIDGET_ACCESS_TYPES

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
        WIDGET_ACCESS_TYPES = {
            tag: f'{info["package"]}.{info["access_type"]}'
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

    spec_code = generate_spec(app, args.package_name)
    body_code = generate_body(app, args.package_name)

    with open(spec_path, "w") as f:
        f.write(spec_code)
    print(f"Generated {spec_path}")

    with open(body_path, "w") as f:
        f.write(body_code)
    print(f"Generated {body_path}")


if __name__ == "__main__":
    main()
