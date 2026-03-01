# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=1.0"]
# ///
"""MCP server for inspecting and interacting with a running Adi GUI application.

Provides screenshot capture, widget tree inspection, widget info,
performance stats, text/type search, click/type interaction, focus management,
and CSS value inspection via file-based IPC.

Usage (via Claude Code MCP config):
    uv run tools/adi_mcp_server.py [--pid PID]
"""

import json
import os
import threading
import time
import uuid
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

POLL_INTERVAL = 0.1   # seconds between response checks
TIMEOUT = 5.0         # seconds before giving up
MCP_DIR_PARENT = Path("/tmp/adi_mcp")

mcp = FastMCP("adi")

# Per-PID locks to enforce single-flight requests
_pid_locks: dict[int, threading.Lock] = {}
_pid_locks_guard = threading.Lock()


def _get_pid_lock(pid: int) -> threading.Lock:
    """Get or create a lock for a specific PID."""
    with _pid_locks_guard:
        if pid not in _pid_locks:
            _pid_locks[pid] = threading.Lock()
        return _pid_locks[pid]


# ---------------------------------------------------------------------------
# IPC Helpers
# ---------------------------------------------------------------------------

def _is_pid_alive(pid: int) -> bool:
    """Check whether a process with the given PID is running."""
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        # Process exists but we don't have permission to signal it
        return True


def _cleanup_stale_dir(d: Path) -> None:
    """Remove a stale MCP session directory."""
    import shutil
    try:
        shutil.rmtree(d)
    except OSError:
        pass


def find_mcp_dir(pid: int | None = None) -> Path:
    """Find the Adi MCP directory. If pid given, use it directly."""
    parent = Path(MCP_DIR_PARENT)
    if pid is not None:
        d = parent / str(pid)
        if d.exists() and (d / "ready").exists():
            return d
        raise RuntimeError(f"No Adi MCP directory for PID {pid}")

    # Auto-discover: find any <parent>/*/ready
    if not parent.exists():
        raise RuntimeError(
            "No running Adi application found. "
            "Start your app with Adi.MCP.Initialize enabled."
        )
    candidates = sorted(parent.glob("*/ready"))
    if not candidates:
        raise RuntimeError(
            "No running Adi application found. "
            "Start your app with Adi.MCP.Initialize enabled."
        )

    # Filter by PID liveness — directory name is the PID
    live = []
    for ready_path in candidates:
        try:
            dir_pid = int(ready_path.parent.name)
        except ValueError:
            continue
        if _is_pid_alive(dir_pid):
            live.append(ready_path)
        else:
            _cleanup_stale_dir(ready_path.parent)

    if not live:
        raise RuntimeError(
            "No running Adi application found. "
            "Start your app with Adi.MCP.Initialize enabled."
        )
    # Use the most recently modified one
    live.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return live[0].parent


def send_command(cmd: dict, pid: int | None = None) -> dict:
    """Send a command and wait for the response.

    Enforces single-flight per PID: concurrent calls to the same app
    are serialized via a per-PID lock.
    """
    mcp_dir = find_mcp_dir(pid)

    # Resolve actual PID from directory name for lock keying
    actual_pid = pid if pid is not None else int(mcp_dir.name)
    lock = _get_pid_lock(actual_pid)

    with lock:
        req_id = uuid.uuid4().hex[:8]
        cmd["req_id"] = req_id

        cmd_path = mcp_dir / f"cmd_{req_id}.json"
        tmp_path = mcp_dir / f"cmd_{req_id}.json.tmp"
        resp_path = mcp_dir / f"resp_{req_id}.json"

        # Atomic write: write to .tmp, rename to final
        tmp_path.write_text(json.dumps(cmd))
        tmp_path.rename(cmd_path)

        # Poll for response
        deadline = time.monotonic() + TIMEOUT
        while time.monotonic() < deadline:
            if resp_path.exists():
                try:
                    data = json.loads(resp_path.read_text())
                    resp_path.unlink(missing_ok=True)
                    return data
                except (json.JSONDecodeError, OSError):
                    pass  # File might be partially written, retry
            time.sleep(POLL_INTERVAL)

        # Cleanup stale command file
        cmd_path.unlink(missing_ok=True)
        raise RuntimeError(f"Timeout waiting for response (req_id={req_id})")


# Global PID override (set via CLI arg)
_target_pid: int | None = None

# ---------------------------------------------------------------------------
# MCP Tools — Inspection
# ---------------------------------------------------------------------------

@mcp.tool()
def screenshot() -> str:
    """Capture a screenshot of the running Adi application.

    Returns the absolute path to the saved PNG file.
    """
    result = send_command({"command": "screenshot"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "screenshot failed"))
    return result["path"]


@mcp.tool()
def widget_tree() -> str:
    """Get the full widget tree of the running Adi application.

    Returns JSON describing every widget: type, path, bounds,
    states, flags, child_count, and nested children.
    """
    result = send_command({"command": "widget_tree"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "widget_tree failed"))
    return json.dumps(result.get("tree"), indent=2)


@mcp.tool()
def widget_info(id: int = 0, path: str = "") -> str:
    """Get detailed info for a specific widget by its tree path.

    Args:
        id: Unique widget ID (takes precedence over path if non-zero).
        path: Dot-separated 1-based child indices (e.g. "1.2.3").
              Empty string for the root widget.

    Returns JSON with type, bounds, all states, all flags, items count.
    """
    result = send_command(
        {"command": "widget_info", "id": id, "path": path}, _target_pid
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "widget_info failed"))
    return json.dumps(result.get("widget"), indent=2)


@mcp.tool()
def perf_stats() -> str:
    """Get performance stats from the running Adi application.

    Returns frame number, FPS, and timing breakdowns (render, layout,
    draw, present) in microseconds.
    """
    result = send_command({"command": "perf_stats"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "perf_stats failed"))
    # Return all fields except status/req_id
    stats = {k: v for k, v in result.items() if k not in ("status", "req_id")}
    return json.dumps(stats, indent=2)


# ---------------------------------------------------------------------------
# MCP Tools — Search
# ---------------------------------------------------------------------------

@mcp.tool()
def find_by_text(query: str, exact: bool = False) -> str:
    """Find widgets by their text content (case-insensitive).

    Args:
        query: Text to search for.
        exact: If True, match entire text exactly. If False, substring match.

    Returns JSON array of matching widgets with id, path, type, and text.
    """
    result = send_command(
        {"command": "find_by_text", "query": query, "exact": exact},
        _target_pid,
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "find_by_text failed"))
    return json.dumps(
        {"count": result.get("count", 0), "matches": result.get("matches", [])},
        indent=2,
    )


@mcp.tool()
def find_by_type(type_name: str) -> str:
    """Find widgets by type name (case-insensitive substring match).

    Args:
        type_name: Type name to search for (e.g. "button", "label", "text_input").

    Returns JSON array of matching widgets with id, path, type, and text.
    """
    result = send_command(
        {"command": "find_by_type", "type_name": type_name}, _target_pid
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "find_by_type failed"))
    return json.dumps(
        {"count": result.get("count", 0), "matches": result.get("matches", [])},
        indent=2,
    )


# ---------------------------------------------------------------------------
# MCP Tools — Interaction
# ---------------------------------------------------------------------------

@mcp.tool()
def click_widget(id: int = 0, path: str = "") -> str:
    """Click a widget by simulating mouse down+up at its center.

    Args:
        id: Unique widget ID (takes precedence over path if non-zero).
        path: Dot-separated 1-based child indices (e.g. "1.2.3").

    Fires the full event chain synchronously within the frame.
    """
    result = send_command(
        {"command": "click_widget", "id": id, "path": path}, _target_pid
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "click_widget failed"))
    return json.dumps(
        {"id": result.get("id"), "path": result.get("path")}, indent=2
    )


@mcp.tool()
def send_keys(keys: str) -> str:
    """Send keystrokes to the focused widget.

    Regular characters are sent as text input. Special keys use {Name} syntax:
    {Return}, {Escape}, {Backspace}, {Tab}, {Space}, {Delete},
    {Home}, {End}, {PageUp}, {PageDown}, {Right}, {Left}, {Down}, {Up}.

    Example: "Hello{Return}" types "Hello" then presses Enter.
    """
    result = send_command({"command": "send_keys", "keys": keys}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "send_keys failed"))
    return "ok"


@mcp.tool()
def set_text(id: int, text: str) -> str:
    """Set widget text directly (model mutation, not input simulation).

    Args:
        id: Unique widget ID.
        text: New text content.

    Works with Label, Text_Input, and Text_Editor widgets.
    For user-like typing, use send_keys instead.
    """
    result = send_command(
        {"command": "set_text", "id": id, "text": text}, _target_pid
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "set_text failed"))
    return json.dumps({"id": result.get("id")}, indent=2)


@mcp.tool()
def get_focus() -> str:
    """Get the currently focused widget.

    Returns JSON with widget info, or null if no widget has focus.
    """
    result = send_command({"command": "get_focus"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "get_focus failed"))
    return json.dumps(result.get("widget"), indent=2)


@mcp.tool()
def set_focus(id: int) -> str:
    """Set keyboard focus to a widget.

    Args:
        id: Unique widget ID.
    """
    result = send_command(
        {"command": "set_focus", "id": id}, _target_pid
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "set_focus failed"))
    return json.dumps({"id": result.get("id")}, indent=2)


@mcp.tool()
def css_values(id: int = 0, path: str = "", part: str = "main") -> str:
    """Get resolved CSS values for a widget part.

    Args:
        id: Unique widget ID (takes precedence over path if non-zero).
        path: Dot-separated 1-based child indices (e.g. "1.2.3").
        part: Widget part name: main, label, icon, text, cursor, selected,
              indicator, scroll, knob, items.

    Returns JSON object with all resolved CSS property values.
    """
    result = send_command(
        {"command": "css_values", "id": id, "path": path, "part": part},
        _target_pid,
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "css_values failed"))
    return json.dumps(result.get("values"), indent=2)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def _main() -> None:
    global MCP_DIR_PARENT, _target_pid

    import argparse

    parser = argparse.ArgumentParser(description="Adi MCP Server")
    parser.add_argument("--pid", type=int, default=None,
                        help="Target Adi application PID")
    parser.add_argument("--dir", type=str, default=None,
                        help="MCP IPC base directory (default: /tmp/adi_mcp)")
    args = parser.parse_args()
    _target_pid = args.pid
    if args.dir is not None:
        MCP_DIR_PARENT = Path(args.dir)

    mcp.run()


if __name__ == "__main__":
    _main()
