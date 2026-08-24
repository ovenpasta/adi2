"""Run an example under MCP control: build it, start it, talk to it, stop it.

Shared by the gallery capture and the widget-tree goldens, which differ
only in what they ask the running app for.
"""

from __future__ import annotations

import contextlib
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BIN_DIR = ROOT / "examples" / "bin"
SRC_DIR = ROOT / "examples"

#  In-tree, so every machine measures the same glyphs. Also what the wasm
#  build embeds, which keeps the browser on the same numbers.
GOLDEN_FONT = ROOT / "vendor" / "open-sans" / "static" / "OpenSans-Regular.ttf"

# The MCP server declares its tools with FastMCP, which is only present
# under `uv run`. Its IPC helpers do not need it, so stand it in rather
# than keeping a second copy of the request protocol in this file.
sys.path.insert(0, str(ROOT / "tools"))
try:
    import adi_mcp_server as ipc
except ModuleNotFoundError:
    from unittest.mock import MagicMock

    _fastmcp = MagicMock()
    _fastmcp.FastMCP = lambda *a, **k: MagicMock()
    sys.modules.setdefault("mcp", MagicMock())
    sys.modules.setdefault("mcp.server", MagicMock())
    sys.modules["mcp.server.fastmcp"] = _fastmcp
    import adi_mcp_server as ipc


def has_mcp(name: str) -> bool:
    source = SRC_DIR / f"{name}.adb"
    return source.is_file() and "Adi.MCP.Initialize" in source.read_text()


def controllable(names: list[str]) -> tuple[list[str], list[str]]:
    """Split into those that answer MCP and those that cannot."""
    ready, skipped = [], []
    for name in sorted(names):
        (ready if has_mcp(name) else skipped).append(name)
    return ready, skipped


def all_examples() -> list[str]:
    """Every example the build script knows about.

    One list, kept where the build already keeps it. The array ends at a
    parenthesis in the first column, so a comment holding one does not
    cut the list short.
    """
    script = (ROOT / "tools" / "build_examples.sh").read_text()
    body = script.split("ALL_EXAMPLES=(", 1)[1].split("\n)", 1)[0]
    names = []
    for line in body.splitlines():
        name = line.split("#", 1)[0].strip()
        if name:
            names.append(name)
    return sorted(names)


def build(*names: str) -> None:
    subprocess.run(
        [str(ROOT / "tools" / "build_examples.sh"), *names],
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


@contextlib.contextmanager
def running(name: str, timeout: float = 5.0, settle: float = 0.3,
            env_extra: dict[str, str] | None = None):
    """Start one example and yield its pid once it answers.

    Only ever one at a time: the caller addresses this pid, so a second
    instance of the same example cannot be mistaken for it.
    """
    binary = BIN_DIR / name
    if not binary.is_file():
        raise RuntimeError(f"{binary} not built")

    #  Set for the child only: pinning these process-wide would change any
    #  app the caller happens to run afterwards. Pin the scale at 2 rather
    #  than 1 so widget tree goldens and gallery captures exercise the
    #  DIP-scaled path and a hardcoded-pixel regression cannot slip past a
    #  machine that happens to run at 1x. Pin the font because the system
    #  fallback is whatever the platform ships, which left the geometry of
    #  every text-bearing widget at the mercy of the machine that wrote it.
    env = os.environ | {
        "ADI_DISPLAY_SCALE_OVERRIDE": "2",
        "ADI_FALLBACK_FONT": str(GOLDEN_FONT),
    } | (env_extra or {})
    app = subprocess.Popen(
        [str(binary)], cwd=ROOT, env=env,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    try:
        wait_for_ready(app.pid, timeout)
        time.sleep(settle)
        yield app.pid
    finally:
        shutdown(app)


def ask(pid: int, command: dict, note: str = "") -> dict:
    """Send one command and insist it succeeded.

    `note` says which step asked, for callers running several against one
    app where the command name alone would not say which failed.
    """
    reply = ipc.send_command(command, pid)
    if reply.get("status") != "ok":
        raise RuntimeError(
            f"{note + ': ' if note else ''}{command['command']}: "
            f"{reply.get('error', 'no reason given')}")
    return reply
