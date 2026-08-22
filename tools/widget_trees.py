#!/usr/bin/env python3
"""Check every example's widget tree against a committed golden.

The tree an example lays out is the whole of what layout and styling
decided: every widget's type, geometry, text, state and structure. A
golden of it catches a change no unit test was written for -- a margin
that stopped cascading, a flex line that settles differently, a widget
that vanished -- across the twenty-seven examples at once.

Trees are read through the Adi MCP `widget_tree` command with the dummy
video driver, so this runs headless and needs no display. The dummy and
the real driver produce identical trees: geometry comes from layout and
font metrics, not from the windowing backend.

Two things are normalized away, and nothing else:

  * A tagged type declared inside a subprogram has no external tag, so
    GNAT reports `internal tag at 16#7ffd...#: name`. The address is the
    stack it happened to land on, so only the name is kept.
  * Coordinates are rounded to a thousandth of a pixel. That is far below
    anything a layout change can mean and above the last-bit drift a
    recompile can introduce.

  tools/widget_trees.py                  # build, then check every example
  tools/widget_trees.py demo_flex        # just these
  tools/widget_trees.py --update         # accept what the apps report now
  tools/widget_trees.py --no-build       # trust examples/bin as it stands
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import example_app as app

ROOT = app.ROOT
GOLDEN_DIR = ROOT / "tests" / "goldens" / "trees"

#  GNAT's stand-in external tag for a type declared inside a subprogram.
INTERNAL_TAG = re.compile(r"^internal tag at 16#[0-9A-Fa-f]+#: ")

#  Rounding coarse enough to absorb a recompile, fine enough that any
#  layout difference a person could see survives it.
PLACES = 3


def normalize(node):
    """Strip what varies between two runs of the same binary.

    The internal-tag rewrite is confined to the `type` field: a widget
    could legitimately display text that looks like one.
    """
    if isinstance(node, dict):
        return {k: (INTERNAL_TAG.sub("", v)
                    if k == "type" and isinstance(v, str) else normalize(v))
                for k, v in sorted(node.items())}
    if isinstance(node, list):
        return [normalize(v) for v in node]
    if isinstance(node, float):
        #  round() gives -0.0 for a small negative; that compares equal
        #  to 0.0 but writes differently, so settle it here.
        return round(node, PLACES) + 0.0
    return node


def read_tree(name: str, timeout: float) -> dict:
    """The whole reply bar its envelope: the window's tree and any overlay.

    Overlays are a sibling of `tree` rather than part of it, so keeping
    everything but the envelope is what makes an overlay that appears or
    vanishes visible here.
    """
    with app.running(name, timeout=timeout,
                     env_extra={"SDL_VIDEODRIVER": "dummy"}) as pid:
        reply = app.ask(pid, {"command": "widget_tree"})
        return normalize({k: v for k, v in reply.items()
                          if k not in ("status", "req_id")})


def flatten(node, path, out) -> None:
    """Every widget by path, each without its own children."""
    key = node.get("path") or path
    out[key] = {k: v for k, v in node.items() if k != "children"}
    for i, child in enumerate(node.get("children") or [], 1):
        flatten(child, f"{key}.{i}" if key else str(i), out)


def flatten_document(doc: dict) -> dict:
    """Every widget the reply describes: the window's, then each overlay's."""
    out: dict = {}
    if doc.get("tree"):
        flatten(doc["tree"], "", out)
    for i, overlay in enumerate(doc.get("overlays") or [], 1):
        flatten(overlay, f"overlay{i}", out)
    return out


#  Told apart from a field that is present and null.
ABSENT = object()


def differences(golden: dict, found: dict, limit: int = 25) -> list[str]:
    """What changed, as lines a person can act on."""
    was, now = flatten_document(golden), flatten_document(found)
    lines = []

    for path in sorted(set(was) - set(now)):
        lines.append(f"  gone     {path or '<root>'}  "
                     f"{was[path].get('type', '?')}")
    for path in sorted(set(now) - set(was)):
        lines.append(f"  new      {path or '<root>'}  "
                     f"{now[path].get('type', '?')}")

    for path in sorted(set(was) & set(now)):
        a, b = was[path], now[path]
        for field in sorted(set(a) | set(b)):
            old, new = a.get(field, ABSENT), b.get(field, ABSENT)
            if old is not new and old != new:
                lines.append(
                    f"  {field:<12} {path or '<root>'}  "
                    f"{'<absent>' if old is ABSENT else old} -> "
                    f"{'<absent>' if new is ABSENT else new}")

    if len(lines) > limit:
        rest = len(lines) - limit
        lines = lines[:limit] + [f"  ... and {rest} more"]
    return lines


def check(name: str, found: dict, golden_dir: Path, update: bool) -> bool:
    path = golden_dir / f"{name}.json"
    text = json.dumps(found, indent=1) + "\n"

    if update:
        path.write_text(text)
        print(f"WROTE {name}")
        return True

    if not path.is_file():
        print(f"MISSING {name}: no golden at {path.relative_to(ROOT)}; "
              f"run tools/widget_trees.py --update {name}")
        return False

    golden = json.loads(path.read_text())
    if golden == found:
        print(f"OK    {name}")
        return True

    print(f"DIFF  {name}")
    for line in differences(golden, found):
        print(line)
    return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("examples", nargs="*", help="default: every example")
    ap.add_argument("--update", action="store_true",
                    help="rewrite the goldens from what the apps report")
    ap.add_argument("--no-build", action="store_true",
                    help="use examples/bin as it stands; a stale binary "
                         "reports on the library it was linked against")
    ap.add_argument("--golden-dir", type=Path, default=GOLDEN_DIR)
    ap.add_argument("--timeout", type=float, default=10.0,
                    help="seconds to wait for an example to come up")
    args = ap.parse_args()

    wanted = args.examples or app.all_examples()
    ready, skipped = app.controllable(wanted)
    if skipped:
        print("skipped, no Adi.MCP.Initialize: " + ", ".join(skipped))
    if not ready:
        print("nothing to check")
        return 1

    if not args.no_build:
        app.build(*ready)

    args.golden_dir.mkdir(parents=True, exist_ok=True)

    failed = []
    for name in ready:
        try:
            found = read_tree(name, args.timeout)
        except Exception as exc:  # keep going; report at the end
            print(f"ERROR {name}: {exc}", file=sys.stderr)
            failed.append(name)
            continue
        if not check(name, found, args.golden_dir, args.update):
            failed.append(name)

    if failed:
        print(f"\n{len(failed)} of {len(ready)} differ: {', '.join(failed)}")
        return 1
    print(f"\n{len(ready)} example tree(s) match")
    return 0


if __name__ == "__main__":
    sys.exit(main())
