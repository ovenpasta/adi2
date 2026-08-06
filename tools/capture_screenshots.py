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
import os
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BIN_DIR = ROOT / "examples" / "bin"
SRC_DIR = ROOT / "examples"
DEST_DIR = ROOT / "examples" / "screenshots"

# The MCP server declares its tools with FastMCP, which is only present
# under `uv run`. Its IPC helpers do not need it, so stand it in rather
# than keeping a second copy of the request protocol in this file.
sys.path.insert(0, str(ROOT / "tools"))
try:
    import adi_mcp_server as ipc
except ModuleNotFoundError:
    from unittest.mock import MagicMock

    fastmcp = MagicMock()
    fastmcp.FastMCP = lambda *a, **k: MagicMock()
    sys.modules.setdefault("mcp", MagicMock())
    sys.modules.setdefault("mcp.server", MagicMock())
    sys.modules["mcp.server.fastmcp"] = fastmcp
    import adi_mcp_server as ipc


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
    "demo_flex": Example(
        shots=[Shot("demo_flex"), Shot("demo_flex_2", scroll=-40)]
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


def has_mcp(name: str) -> bool:
    source = SRC_DIR / f"{name}.adb"
    return source.is_file() and "Adi.MCP.Initialize" in source.read_text()


def capturable(names: list[str]) -> tuple[list[str], list[str]]:
    ready, skipped = [], []
    for name in sorted(names):
        (ready if has_mcp(name) else skipped).append(name)
    return ready, skipped


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


def build(name: str) -> None:
    subprocess.run(
        [str(ROOT / "tools" / "build_examples.sh"), name],
        cwd=ROOT, check=True, stdout=subprocess.DEVNULL,
    )


def wait_for_ready(pid: int, timeout: float) -> Path:
    """Wait for this pid's own IPC directory, never another instance's."""
    deadline = time.monotonic() + timeout
    mcp_dir = Path("/tmp/adi_mcp") / str(pid)
    while time.monotonic() < deadline:
        if (mcp_dir / "ready").is_file():
            return mcp_dir
        time.sleep(0.1)
    raise RuntimeError(f"{pid} never reported ready")


def capture(name: str, spec: Example, out_dir: Path, timeout: float) -> list[str]:
    binary = BIN_DIR / name
    if not binary.is_file():
        raise RuntimeError(f"{binary} not built")

    written = []
    #  Set for the child only: pinning the scale process-wide would
    #  change any app the caller happens to run afterwards.
    env = os.environ | {"ADI_DISPLAY_SCALE_OVERRIDE": "1"}
    app = subprocess.Popen(
        [str(binary)], cwd=ROOT, env=env,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    try:
        wait_for_ready(app.pid, timeout)
        time.sleep(spec.settle)
        for shot in spec.shots:
            if shot.click:
                found = ipc.send_command(
                    {"command": "find_by_text", "query": shot.click,
                     "exact": True},
                    app.pid,
                )
                matches = found.get("matches") or []
                if not matches:
                    raise RuntimeError(
                        f"{shot.name}: nothing labelled {shot.click!r} to click")
                reply = ipc.send_command(
                    {"command": "click_widget", "id": 0,
                     "path": matches[0]["path"]},
                    app.pid,
                )
                if reply.get("status") != "ok":
                    raise RuntimeError(
                        f"{shot.name}: click failed: "
                        f"{reply.get('error', 'unknown error')}")
                time.sleep(0.5)
            if shot.scroll:
                # An app that rejects the command would otherwise be
                # captured unscrolled, quietly duplicating the previous
                # shot -- which is what happens with --no-build against a
                # binary predating the scroll command.
                reply = ipc.send_command(
                    {"command": "scroll", "dy": shot.scroll,
                     "dx": 0, "id": 0, "path": "", "x": -1, "y": -1},
                    app.pid,
                )
                if reply.get("status") != "ok":
                    raise RuntimeError(
                        f"{shot.name}: scroll failed: "
                        f"{reply.get('error', 'unknown error')}")
                #  Let the scroll inertia settle before capturing.
                time.sleep(0.8)
            reply = ipc.send_command({"command": "screenshot"}, app.pid)
            if reply.get("status") != "ok":
                raise RuntimeError(reply.get("error", "screenshot failed"))
            dest = out_dir / f"{shot.name}.png"
            shutil.copyfile(reply["path"], dest)
            written.append(dest.name)
    finally:
        shutdown(app)
    return written


def shutdown(app: subprocess.Popen, grace: float = 2.0) -> None:
    """Ask the app to quit; kill it only if it will not.

    A window whose close handler refuses the request stays up, and an app
    that never came up cannot answer at all, so the signal remains the
    backstop. SIGTERM is not tried: an SDL event loop does not act on it.
    """
    ipc_dir = ipc.MCP_DIR_PARENT / str(app.pid)
    try:
        ipc.send_command({"command": "quit"}, app.pid, await_reply=False)
        rc = app.wait(timeout=grace)
        #  A crash also ends the process, so a clean shutdown has to be
        #  told apart from one: zero status, and the app removed its own
        #  IPC directory on the way out.
        if rc == 0 and not ipc_dir.exists():
            return
        print(f"warning: {app.pid} exited rc={rc}, "
              f"ipc dir {'left behind' if ipc_dir.exists() else 'gone'}",
              file=sys.stderr)
    except Exception:
        pass
    app.kill()
    app.wait()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("examples", nargs="*", help="default: every capturable one")
    ap.add_argument("--out-dir", type=Path, default=DEST_DIR)
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--timeout", type=float, default=5.0,
                    help="seconds to wait for an example to come up")
    args = ap.parse_args()

    wanted = args.examples or gallery_examples()
    ready, skipped = capturable(wanted)

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
                build(name)
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
