# /// script
# requires-python = ">=3.10"
# # Capped below 2.0: mcp.server.fastmcp exists only on the 1.x line.
# dependencies = ["mcp>=1.0,<2"]
# ///
"""MCP server for inspecting and interacting with a running Adi GUI application.

Provides screenshot capture, widget tree inspection, widget info,
performance stats, text/type search, click/type interaction, focus management,
and CSS value inspection via file-based IPC.

Usage (via Claude Code MCP config):
    uv run tools/adi_mcp_server.py [--pid PID]
"""

import inspect
import json
import os
import sys
import tempfile
import threading
import time
import uuid
from pathlib import Path
from typing import Callable

try:
    from mcp.server.fastmcp import FastMCP
except ImportError:
    #  Serving MCP needs the package; reaching the same tools from a
    #  command line needs only the IPC helpers below, so absence is not
    #  fatal until someone actually asks for a server.
    FastMCP = None

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

POLL_INTERVAL = 0.1   # seconds between response checks
TIMEOUT = 5.0         # seconds before giving up
MCP_DIR_PARENT = Path(tempfile.gettempdir()) / "adi_mcp"
#  The application rewrites "ready" every few seconds. One that has
#  stopped being touched belongs to a process that is gone.
STALE_AFTER = 120.0

class _Unserved:
    """Registers tools when FastMCP is absent, and refuses to serve them."""

    def tool(self):
        return lambda fn: fn

    def run(self, *args, **kwargs):
        raise SystemExit(
            "serving MCP needs the 'mcp' package: install it, or query a "
            "running application with --cli")


mcp = FastMCP("adi") if FastMCP is not None else _Unserved()

#  Both surfaces read from one registry, so a tool is named once and is
#  reachable over MCP and from the command line alike.
CLI_TOOLS: dict[str, Callable[..., str]] = {}


def tool(fn: Callable[..., str]) -> Callable[..., str]:
    CLI_TOOLS[fn.__name__] = fn
    return mcp.tool()(fn)

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

def _is_fresh(ready_path: Path) -> bool:
    """Whether an app is still touching its "ready" file."""
    try:
        return time.time() - ready_path.stat().st_mtime <= STALE_AFTER
    except OSError:
        return False


def _pid_is_gone(pid: int) -> bool:
    """True only when the OS says the process is gone, False when it
    cannot be asked. On Windows os.kill terminates the target whatever
    signal it is given, so it is never asked there."""
    if os.name != "posix":
        return False
    try:
        os.kill(pid, 0)
        return False
    except ProcessLookupError:
        return True
    except (PermissionError, OSError):
        return False


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
        if _is_fresh(ready_path) and not _pid_is_gone(dir_pid):
            live.append(ready_path)
        else:
            _cleanup_stale_dir(ready_path.parent)

    if not live:
        raise RuntimeError(
            "No running Adi application found. "
            "Start your app with Adi.MCP.Initialize enabled."
        )

    if len(live) > 1:
        #  Picking the most recently modified one silently targets
        #  whichever app rendered last, which is not necessarily the one
        #  the caller meant. Make the ambiguity explicit instead.
        pids = sorted(int(p.parent.name) for p in live)
        raise RuntimeError(
            "Multiple running Adi applications found (PIDs: "
            + ", ".join(str(x) for x in pids)
            + "). Select one with --pid <PID>."
        )

    return live[0].parent


def send_command(cmd: dict, pid: int | None = None,
                 await_reply: bool = True) -> dict:
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

        if not await_reply:
            #  Nothing will answer once the app has torn its own IPC
            #  directory down, so do not wait for a reply that is racing
            #  the shutdown that the command asked for.
            return {"status": "ok", "req_id": req_id}

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

@tool
def screenshot() -> str:
    """Capture a screenshot of the running Adi application.

    Returns the absolute path to the saved PNG file.
    """
    result = send_command({"command": "screenshot"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "screenshot failed"))
    return result["path"]


@tool
def widget_tree() -> str:
    """Get the full widget tree of the running Adi application.

    Returns JSON describing every widget: type, path, bounds,
    states, flags, child_count, and nested children.
    """
    result = send_command({"command": "widget_tree"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "widget_tree failed"))
    return json.dumps(result.get("tree"), indent=2)


@tool
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


@tool
def perf_stats() -> str:
    """Get performance stats from the running Adi application.

    Returns frame number, FPS, and timing breakdowns (render, layout,
    draw, present) in microseconds, the per-frame counters, plus a
    texture_cache object holding the renderer's byte budget, current and
    peak residency, and a breakdown per producer (shadow, raster, svg,
    view).

    The counters cover the whole frame, drawing included: style_hits,
    style_memo_hits and style_computes partition style_resolves between
    the per-widget cache, the global memo and the cascade, and
    layout_calls, layout_skips, pref_calls and pref_hits report the
    layout and measurement work. selector_memo_hits and
    selector_memo_misses count a layer above them: the styles
    Adi.CSS_Source folds for a (tag, classes, id) triple, touched only
    where something binds or applies.

    The budget bounds idle residency, not the scene: read idle_bytes
    against it, not bytes. Each producer reports how its residency
    divides now (active/idle/retired), plus hits, misses, stores,
    pressure_evictions, headroom_evictions, crowded_evictions and
    cumulative build_us.

    A style_stores object reports what the style stores hold:
    rule_sets, styles, resolved, text, gradients and widget_properties,
    each with a count and a bytes, plus resolved_cap and
    resolved_generation. Only the resolved store evicts — read its count
    against resolved_cap and watch resolved_generation for a clear. The
    rest hold what they have for the life of the process, so a count
    that keeps climbing across a steady scene names the store something
    is feeding.
    """
    result = send_command({"command": "perf_stats"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "perf_stats failed"))
    # Return all fields except status/req_id
    stats = {k: v for k, v in result.items() if k not in ("status", "req_id")}
    return json.dumps(stats, indent=2)


@tool
def set_texture_budget(bytes: int) -> str:
    """Set the window's idle texture budget, in bytes. Development only.

    The budget bounds textures the cache retains for reuse, not those the
    scene is drawing, so applying it after startup does not disturb an
    active working set. Check that idle_bytes is zero before relying on a
    measurement taken across a change of budget.
    """
    result = send_command(
        {"command": "set_texture_budget", "bytes": int(bytes)}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "set_texture_budget failed"))
    return json.dumps({"budget": result.get("budget")}, indent=2)


# ---------------------------------------------------------------------------
# MCP Tools — Search
# ---------------------------------------------------------------------------

@tool
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


@tool
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

@tool
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


@tool
def scroll(dy: int = 0, dx: int = 0, id: int = 0, path: str = "",
           x: int = -1, y: int = -1) -> str:
    """Scroll by simulating mouse wheel notches.

    A wheel event goes to whichever scrollable widget is under the pointer,
    so aim it one of three ways: at a widget (id or path), at a point
    (x and y), or leave all of them out to use the middle of the window.

    Args:
        dy: Vertical notches. Positive scrolls up, negative scrolls down.
        dx: Horizontal notches.
        id: Unique widget ID to aim at (takes precedence over path).
        path: Dot-separated 1-based child indices (e.g. "1.2.3").
        x: Pointer X to aim at; used only when no id or path is given.
        y: Pointer Y to aim at; used only when no id or path is given.

    Returns the point the wheel was delivered to and the deltas applied.
    """
    if dx == 0 and dy == 0:
        raise ValueError("scroll requires a non-zero dx or dy")
    if (x >= 0) != (y >= 0):
        raise ValueError("scroll needs both x and y, or neither")

    result = send_command(
        {"command": "scroll", "dy": dy, "dx": dx,
         "id": id, "path": path, "x": x, "y": y},
        _target_pid,
    )
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "scroll failed"))
    return json.dumps(
        {k: result.get(k) for k in ("x", "y", "dx", "dy")}, indent=2
    )


@tool
def quit_app() -> str:
    """Ask the application to exit.

    Takes the ordinary quit path, so the app finalizes as it would on a
    window close. A window with a close handler may refuse, in which case
    the app keeps running and the caller has to fall back to a signal.

    Nothing is awaited: the app removes its IPC directory as it exits, so
    the reply would be racing its own shutdown.
    """
    send_command({"command": "quit"}, _target_pid, await_reply=False)
    return "requested"


@tool
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


@tool
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


@tool
def get_focus() -> str:
    """Get the currently focused widget.

    Returns JSON with widget info, or null if no widget has focus.
    """
    result = send_command({"command": "get_focus"}, _target_pid)
    if result.get("status") != "ok":
        raise RuntimeError(result.get("error", "get_focus failed"))
    return json.dumps(result.get("widget"), indent=2)


@tool
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


@tool
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
# Command line
# ---------------------------------------------------------------------------

KEY_SYNTAX = (
    "Special keys use brace syntax: {Return} {Escape} {Backspace} {Tab} "
    "{Space} {Delete} {Home} {End} {PageUp} {PageDown} {Left} {Right} "
    "{Up} {Down}. A bare name such as Tab is typed as literal text."
)


#  A tool's parameters become its arguments, so only the shapes named
#  here can be spelled on a command line. Anything else is a mistake in
#  the tool rather than in the caller's line, and says so at build time.
ARGUMENT_TYPES = {int: int, str: str, float: float}


def _add_tool_arguments(sub_parser, fn) -> None:
    """Give a subparser one argument per parameter of the tool it runs."""
    import argparse

    for name, param in inspect.signature(fn).parameters.items():
        kind = (param.annotation
                if param.annotation is not inspect.Parameter.empty else str)
        required = param.default is inspect.Parameter.empty

        if kind is bool:
            if required:
                raise TypeError(
                    f"{fn.__name__}: a bool parameter needs a default, "
                    f"since {name} would otherwise take a string")
            #  A flag that only ever turns something on cannot turn off a
            #  default that is already True.
            action = ("store_true" if param.default is False
                      else argparse.BooleanOptionalAction)
            sub_parser.add_argument(f"--{name}", action=action,
                                    default=param.default)
            continue

        if kind not in ARGUMENT_TYPES:
            raise TypeError(
                f"{fn.__name__}: parameter {name} is annotated {kind!r}, "
                f"which has no command line spelling")

        if required:
            sub_parser.add_argument(name, type=ARGUMENT_TYPES[kind])
        else:
            sub_parser.add_argument(f"--{name}", type=ARGUMENT_TYPES[kind],
                                    default=param.default,
                                    metavar=name.upper())


def _build_cli_parser():
    import argparse

    parser = argparse.ArgumentParser(
        prog="adi_mcp_server.py --cli",
        description="Run one introspection tool against a running Adi "
                    "application and print the result.",
        epilog=KEY_SYNTAX)
    #  A tool is free to have its own pid or dir parameter: the subparser
    #  shares one namespace with this one, so these are kept out of its way.
    parser.add_argument("--pid", type=int, default=None, dest="_target",
                        help="Target Adi application PID. Required when more "
                             "than one application is running.")
    parser.add_argument("--dir", type=str, default=None, dest="_base_dir",
                        help="MCP IPC base directory (default: /tmp/adi_mcp)")
    sub = parser.add_subparsers(dest="_tool", required=True, metavar="TOOL")

    for name, fn in sorted(CLI_TOOLS.items()):
        summary = (fn.__doc__ or "").strip().splitlines()
        sub_parser = sub.add_parser(
            name,
            help=summary[0] if summary else None,
            description=fn.__doc__,
            epilog=KEY_SYNTAX if name == "send_keys" else None,
            formatter_class=argparse.RawDescriptionHelpFormatter)
        _add_tool_arguments(sub_parser, fn)

    return parser


def _strip_cli_flag(argv: list[str]) -> list[str]:
    """Drop the --cli that selected this mode, leaving the tool's own line.

    Only the first is dropped: a later one is a value the tool asked for,
    and removing it would silently change what the caller typed.
    """
    rest = list(argv)
    del rest[rest.index("--cli")]
    return rest


def _run_cli(argv: list[str]) -> int:
    global MCP_DIR_PARENT, _target_pid

    args = _build_cli_parser().parse_args(argv)
    _target_pid = args._target
    if args._base_dir is not None:
        MCP_DIR_PARENT = Path(args._base_dir)

    fn = CLI_TOOLS[args._tool]
    kwargs = {name: getattr(args, name)
              for name in inspect.signature(fn).parameters}
    try:
        #  Only the application's own failures are answers to the query;
        #  anything else is a defect here and should surface as one.
        result = fn(**kwargs)
    except (RuntimeError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(result)
    return 0


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def _main() -> None:
    global MCP_DIR_PARENT, _target_pid

    import argparse

    #  --cli takes the rest of the line as a tool invocation, which
    #  subparsers own; the server's own options are parsed only without it.
    if "--cli" in sys.argv[1:]:
        sys.exit(_run_cli(_strip_cli_flag(sys.argv[1:])))

    parser = argparse.ArgumentParser(description="Adi MCP Server")
    parser.add_argument("--pid", type=int, default=None,
                        help="Target Adi application PID")
    parser.add_argument("--dir", type=str, default=None,
                        help="MCP IPC base directory (default: /tmp/adi_mcp)")
    parser.add_argument("--cli", action="store_true",
                        help="Run a single tool from the command line "
                             "instead of serving MCP over stdio")
    args = parser.parse_args()
    _target_pid = args.pid
    if args.dir is not None:
        MCP_DIR_PARENT = Path(args.dir)

    mcp.run()


if __name__ == "__main__":
    _main()
