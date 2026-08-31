# Adi MCP Runtime Introspection

This guide explains how to inspect and interact with a running Adi app from MCP using screenshot, widget introspection, search, interaction, and CSS inspection tools.

## Overview

Adi exposes a development-only MCP bridge:

- Ada side: `Adi.MCP` (`src/mcp/`) polls command files and writes JSON responses.
- Python side: `tools/adi_mcp_server.py` exposes MCP tools and handles file IPC.
- IPC directory: `adi_mcp/<PID>/` inside the system temp directory —
  `TMPDIR`, else `TEMP`, else `TMP`, else `/tmp` (`C:\Windows\Temp` on
  Windows). Both sides resolve it the same way, so neither normally
  needs telling where it is.

Release and validation builds use `src/mcp_stub/` (no-op implementation).

## Prerequisites

- Build profile must be `development`.
- The target app must call `Adi.MCP.Initialize`.
- MCP server config must point at `tools/adi_mcp_server.py`.

## App Integration

In the app:

```ada
with Adi.MCP;
...
Adi.MCP.Initialize (W);
```

Optional explicit base directory:

```ada
Adi.MCP.Initialize (W, Base_Dir => "/run/user/1000/my_app_mcp");
```

Recommended on shutdown:

```ada
Adi.MCP.Finalize;
```

## MCP Server Configuration

The repository ships no MCP client configuration; wiring the server into a client is a per-developer choice. A client that wants it should run:

```bash
uv run ./tools/adi_mcp_server.py
```

Optional:

- `--pid <pid>` to target a specific running app.
- `--dir <path>` if you intentionally override the IPC base directory.

`tools/als_mcp_server.py` serves the Ada Language Server the same way, taking the project root from `ALS_PROJECT_ROOT` or the repository the script sits in.

Both scripts declare `mcp>=1.0,<2`: `mcp.server.fastmcp` exists only on the 1.x line.

## Command Line

`--cli` runs one tool and prints its result instead of serving MCP over stdio. Every tool below is available as a subcommand of the same name:

```bash
python3 tools/adi_mcp_server.py --cli perf_stats
python3 tools/adi_mcp_server.py --cli screenshot
python3 tools/adi_mcp_server.py --cli find_by_text "Save" --exact
python3 tools/adi_mcp_server.py --cli send_keys "{Tab}{Return}"
```

`--cli --help` lists the tools; `--cli <tool> --help` documents one. Arguments follow each tool's signature: required parameters are positional, optional ones are flags.

`--pid` and `--dir` work here too, and both belong before the tool name — everything after it is the tool's own line. `--pid` is required whenever more than one app is running: auto-discovery refuses to guess and lists the candidates. The exit status is non-zero when a query fails, and the error goes to stderr.

Only serving MCP needs the `mcp` package; `--cli` reaches the application through the same file IPC and runs without it.

## Available MCP Tools

### Inspection

| Tool | Description |
|------|-------------|
| `screenshot()` | Capture PNG screenshot, returns file path |
| `widget_tree()` | Full widget hierarchy as JSON (type, id, path, text, bounds, states, flags, children, overlays) |
| `widget_info(id, path)` | Detailed info for one widget (by ID or path) |
| `perf_stats()` | Frame timing and FPS, the per-frame counters — `style_hits`, `style_memo_hits` and `style_computes` partition `style_resolves` between the per-widget cache, the global memo and the cascade, alongside `layout_calls`, `layout_skips`, `pref_calls`, `pref_hits`, and `selector_memo_hits`/`selector_memo_misses` for the layer above them, where `Adi.CSS_Source` folds the styles a (tag, classes, id) triple names, all covering the whole frame, drawing included — plus a `texture_cache` object: budget, total/idle/peak bytes, and per-producer (`shadow`, `raster`, `svg`, `view`) active/idle/retired residency, hits, misses, stores, `pressure_evictions`, `headroom_evictions`, `crowded_evictions` (borrowed entries past the count that bounds them), `released` (dropped with their group) and `build_us`. The budget bounds idle residency, so read `idle_bytes` against it |
| `set_texture_budget(bytes)` | Set the window's idle texture budget and return the new value. The budget bounds what the cache retains for reuse, not what the scene is drawing, so applying it after startup does not disturb an active working set. Check that `idle_bytes` is zero before relying on a measurement taken across a change of budget |

### Search

| Tool | Description |
|------|-------------|
| `find_by_text(query, exact)` | Find widgets by text content (case-insensitive substring or exact match) |
| `find_by_type(type_name)` | Find widgets by type name (case-insensitive substring match) |

### Interaction

| Tool | Description |
|------|-------------|
| `click_widget(id, path)` | Simulate mouse click at widget center |
| `scroll(dy, dx, id, path, x, y)` | Simulate mouse wheel notches. Positive `dy` scrolls up, negative down |
| `quit_app()` | Ask the app to exit through its ordinary quit path; a close handler may refuse |
| `send_keys(keys)` | Send keystrokes to focused widget. Regular chars as text, special keys via `{Name}` syntax |
| `set_text(id, text)` | Set widget text directly (model mutation, not input simulation) |
| `get_focus()` | Get currently focused widget info |
| `set_focus(id)` | Set keyboard focus to a widget |

### CSS Inspection

| Tool | Description |
|------|-------------|
| `css_values(id, path, part)` | Get resolved CSS property values for a widget part |

## Widget Identification

All tools that target a widget accept both `id` (integer) and `path` (string):

- **ID**: Unique integer assigned at widget creation. Stable across frames. Takes precedence if non-zero.
- **Path**: Dot-separated 1-based child indices (e.g. `"1.2.3"`). Discoverable from `widget_tree`.
- **Overlay path**: `"overlayN:subpath"` syntax targets overlay widgets (e.g. `"overlay1:1.2"`). Plain paths also fall back to overlays if not found in root.

Lookup scans the root widget tree and all overlays. `click_widget` requires an explicit `id` or `path` — omitting both returns an error rather than clicking root.

`scroll` is aimed rather than targeted: a wheel event goes to whichever scrollable widget sits under the pointer, so it takes a widget (`id`/`path`), an explicit point (`x`/`y`), or neither, in which case it uses the middle of the window. It requires a non-zero `dx` or `dy`. Use it to reach parts of a window that are out of view — a scroll container that is not keyboard-focusable cannot be moved with `send_keys`.

## send_keys Syntax

Regular characters are sent as text input. Special keys use `{Name}` notation:

| Token | Key |
|-------|-----|
| `{Return}` / `{Enter}` | Enter |
| `{Escape}` / `{Esc}` | Escape |
| `{Backspace}` | Backspace |
| `{Tab}` | Tab |
| `{Space}` | Space |
| `{Delete}` / `{Del}` | Delete |
| `{Home}` | Home |
| `{End}` | End |
| `{PageUp}` | Page Up |
| `{PageDown}` | Page Down |
| `{Right}`, `{Left}`, `{Down}`, `{Up}` | Arrow keys |
| `{F1}` … `{F12}` | Function keys |

Tokens are case-insensitive.

Example: `"Hello{Return}"` types "Hello" then presses Enter.
Example: `"{F1}"` triggers the app's F1 handler (e.g. a help dialog).

## CSS Parts

The `css_values` tool accepts a `part` parameter:

| Part | Description |
|------|-------------|
| `main` | Primary widget area (default) |
| `label` | Label/text display region |
| `icon` | Icon/image area |
| `text` | Text content in editable inputs |
| `cursor` | Text cursor |
| `selected` | Selected item highlight |
| `indicator` | Checkbox/radio/toggle indicator |
| `scroll` | Scrollbar track |
| `knob` | Scrollbar thumb |
| `items` | Container for list/menu items |

## Architecture

### Ada Side

- `Adi.Widget.Introspection` (`src/adi-widget-introspection.ads/adb`): Reusable introspection package providing `Get_Info`, `Get_Text`, `Find_By_Id`, `Find_By_Path`, `Find_Path`, `Find_By_Text`, `Find_By_Type`.
- `Adi.MCP` (`src/mcp/adi-mcp.adb`): Thin JSON/IPC layer that delegates to Introspection for data extraction, handles command routing, and manages CSS value serialization.
- Each widget has a unique `Widget_Id` (monotonically increasing, assigned at creation via `Allocate_Widget_Id`).

### Overlay Support

Tree walks and search operations cover overlays automatically. The MCP layer calls introspection functions once for the root tree, then once per overlay, merging results. `widget_tree` includes an `"overlays"` array alongside `"tree"`.

## IPC Protocol

Per-process session directory:

```text
/tmp/adi_mcp/<PID>/
```

Files:

- command: `cmd_<req_id>.json`
- response: `resp_<req_id>.json`
- screenshot: `screenshot_<req_id>.png`
- readiness sentinel: `ready`

Flow:

1. Python writes `cmd_<req_id>.json.tmp`, renames to `cmd_<req_id>.json`.
2. Ada consumes one command, executes it, writes `resp_<req_id>.json`.
3. Python polls for that exact response file and returns parsed data.

The Python client enforces single-flight per PID (one in-flight command per app).

The same protocol from a shell, without the Python bridge. The app's own
PID names its directory, so this touches no session but the one it
starts:

```bash
./examples/bin/html_view_example >/tmp/app.log 2>&1 &
APP=$!
trap 'kill "$APP" 2>/dev/null' EXIT     # the app goes, however this ends
D=/tmp/adi_mcp/$APP

# Wait for either the sentinel or the app's death, not for the sentinel
# alone: an app that fails to start never writes one.
await() {
  for _ in $(seq 40); do
    [ -f "$1" ] && return 0
    kill -0 "$APP" 2>/dev/null || { echo "app exited, see /tmp/app.log" >&2; return 1; }
    sleep 0.5
  done
  echo "timed out waiting for $1" >&2
  return 1
}

await "$D/ready" || exit 1

REQ="shell_$$"
printf '{"command":"screenshot"}' > "$D/cmd_$REQ.json.tmp"
mv "$D/cmd_$REQ.json.tmp" "$D/cmd_$REQ.json"
await "$D/resp_$REQ.json" || exit 1
cat "$D/resp_$REQ.json"
```

`req_id` is any string unique within the app. Other commands take their
arguments as further fields of the same object.

## Troubleshooting

- `No running Adi application found`:
  Confirm the app called `Adi.MCP.Initialize` and is running in development profile.
- `Multiple running Adi applications found (PIDs: ...)`:
  Auto-discovery does not guess between live applications, because the
  most recently active one is not necessarily the one you mean. Re-run
  targeting a specific process with `--pid <PID>`, or leave one running:
  `pgrep -af examples/bin/` lists them. Discovery removes the session
  directory of an application that has stopped rewriting its `ready`
  file, and on POSIX also one whose PID the OS reports as gone, so a
  killed app stops counting on its own. Clearing one by hand means
  `rm -rf /tmp/adi_mcp/<PID>` for that PID — never the parent, which is
  shared between applications and users.
- Timeouts:
  Check that the app is still alive and rendering frames.
- Mismatched directories:
  Ensure Ada `Base_Dir` and Python `--dir` match exactly.
