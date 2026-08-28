#!/usr/bin/env bash
#  Regenerate the demo's Ada from its XML and CSS. Run from the crate
#  root, which is what the <link href> in the XML is relative to.
set -euo pipefail

ADI=${ADI_ROOT:-../..}
OUT=generated

mkdir -p "$OUT"

python3 "$ADI/tools/css_to_ada.py" \
    css/gl_demo.css "$OUT/gl_demo_styles.ads" \
    --package-name=GL_Demo_Styles

#  No --grammar: texture-view is a core widget, so the built-in grammar
#  already knows the tag.
python3 "$ADI/tools/xml_to_ada.py" \
    xml/gl_demo.xml \
    --output-dir "$OUT" \
    --package-name GL_Demo_UI

echo "gl_demo: codegen up to date"
