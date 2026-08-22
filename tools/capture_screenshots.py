#!/usr/bin/env python3
"""Regenerate the gallery captures in examples/screenshots/.

Every capture comes from the app's own renderer through the Adi MCP
`screenshot` command, so the result is the exact declared render size with
no window manager decoration. That makes a capture reproducible on any
desktop, which a window-grabbing tool is not.

Captures run with ADI_DISPLAY_SCALE_OVERRIDE=1 so the scale, geometry
and image dimensions do not depend on the monitor of whoever regenerated
them. Pixel density is untouched, so a high-density device still yields
the same framebuffer from fewer window coordinates. This is not
byte-identical output: fonts and rendering backends still differ between
machines.

An example can only be captured if it calls Adi.MCP.Initialize; the rest
are reported and skipped rather than silently omitted.

  tools/capture_screenshots.py                 # every capturable example
  tools/capture_screenshots.py grid_example    # just these
  tools/capture_screenshots.py --out-dir /tmp/shots   # leave the gallery alone
  tools/capture_screenshots.py --no-build
"""

from __future__ import annotations

import argparse
import shutil
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import example_app as app

ROOT = app.ROOT
SRC_DIR = app.SRC_DIR
DEST_DIR = ROOT / "examples" / "screenshots"


@dataclass
class Shot:
    """One image: where it lands, and how to get the app to show it."""

    name: str
    #  Wheel notches applied before capturing. Negative scrolls down. A
    #  step larger than the document clamps at the end, which is steadier
    #  than counting notches: a notch is 36px plus scroll inertia.
    scroll: int = 0
    #  Exact text of a widget to click first, to reach a tab or a dialog.
    click: str = ""


@dataclass
class Example:
    shots: list[Shot] = field(default_factory=list)
    #  Seconds to let the first frame settle before the first capture.
    settle: float = 0.3


#  Examples whose gallery entry is more than a single screen. Anything not
#  listed gets one capture under its own name.
MULTI_SHOT: dict[str, Example] = {
    #  Five screens of reference; the shots step through it so no
    #  section falls between two of them. The last step overruns the
    #  document and clamps at the end.
    "demo_flex": Example(
        shots=[Shot("demo_flex"),
               Shot("demo_flex_2", scroll=-6),
               Shot("demo_flex_3", scroll=-6),
               Shot("demo_flex_4", scroll=-6),
               Shot("demo_flex_5", scroll=-40)]
    ),
    "demo_block": Example(
        shots=[Shot("demo_block"), Shot("demo_block_2", scroll=-40)]
    ),
    "grid_example": Example(
        shots=[Shot("grid_example"), Shot("grid_example_2", scroll=-40)]
    ),
    "font_example": Example(
        shots=[Shot("font_example"), Shot("font_example_2", scroll=-40)]
    ),
    #  One tab holds only a few controls, so the gallery walks them.
    "material_demo": Example(
        shots=[Shot("material_demo"),
               Shot("material_demo_2", click="Forms"),
               Shot("material_demo_3", click="Settings"),
               Shot("material_demo_4", click="Controls")]
    ),
    #  Preview and Source are the two halves of the widget.
    "html_view_example": Example(
        shots=[Shot("html_view_example"),
               Shot("html_view_example_2", click="Source")]
    ),
    #  The buttons alone say nothing about what the example is for.
    "dialog_example": Example(
        shots=[Shot("dialog_example"),
               Shot("dialog_example_2", click="Show Confirm")]
    ),
}


def gallery_examples() -> list[str]:
    """Examples that already have a committed capture."""
    seen = set()
    for png in DEST_DIR.glob("*.png"):
        #  demo_flex_2.png belongs to demo_flex.
        stem = png.stem
        base = stem.rsplit("_", 1)[0] if stem.rsplit("_", 1)[-1].isdigit() else stem
        if (SRC_DIR / f"{base}.adb").is_file():
            seen.add(base)
    return sorted(seen)


def capture(name: str, spec: Example, out_dir: Path, timeout: float) -> list[str]:
    written = []
    with app.running(name, timeout=timeout, settle=spec.settle) as pid:
        for shot in spec.shots:
            if shot.click:
                found = app.ask(
                    pid, {"command": "find_by_text", "query": shot.click,
                          "exact": True}, shot.name)
                matches = found.get("matches") or []
                if not matches:
                    raise RuntimeError(
                        f"{shot.name}: nothing labelled {shot.click!r} to click")
                app.ask(pid, {"command": "click_widget", "id": 0,
                              "path": matches[0]["path"]}, shot.name)
                time.sleep(0.5)
            if shot.scroll:
                # An app that rejects the command would otherwise be
                # captured unscrolled, quietly duplicating the previous
                # shot -- which is what happens with --no-build against a
                # binary predating the scroll command.
                app.ask(pid, {"command": "scroll", "dy": shot.scroll,
                              "dx": 0, "id": 0, "path": "", "x": -1, "y": -1},
                        shot.name)
                #  Let the scroll inertia settle before capturing.
                time.sleep(0.8)
            reply = app.ask(pid, {"command": "screenshot"}, shot.name)
            dest = out_dir / f"{shot.name}.png"
            shutil.copyfile(reply["path"], dest)
            written.append(dest.name)
    return written


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("examples", nargs="*", help="default: every capturable one")
    ap.add_argument("--out-dir", type=Path, default=DEST_DIR)
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--timeout", type=float, default=5.0,
                    help="seconds to wait for an example to come up")
    args = ap.parse_args()

    wanted = args.examples or gallery_examples()
    ready, skipped = app.controllable(wanted)

    if skipped:
        print("skipped, no Adi.MCP.Initialize: " + ", ".join(skipped))
    if not ready:
        print("nothing to capture")
        return 1

    args.out_dir.mkdir(parents=True, exist_ok=True)

    failures = []
    for name in ready:
        spec = MULTI_SHOT.get(name, Example(shots=[Shot(name)]))
        try:
            if not args.no_build:
                app.build(name)
            written = capture(name, spec, args.out_dir, args.timeout)
            print(f"{name}: {', '.join(written)}")
        except Exception as exc:  # keep going; report at the end
            failures.append(name)
            print(f"{name}: FAILED ({exc})", file=sys.stderr)

    if failures:
        print(f"\n{len(failures)} failed: {', '.join(failures)}", file=sys.stderr)
        return 1
    print(f"\n{len(ready)} example(s) captured into {args.out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
