# Adi MCP Runtime Introspection

This guide explains how to inspect and interact with a running Adi app from MCP using screenshot, widget introspection, search, interaction, and CSS inspection tools.

## Overview

Adi exposes a development-only MCP bridge:

- Ada side: `Adi.MCP` (`src/mcp/`) polls command files and writes JSON responses.
- Python side: `tools/adi_mcp_server.py` exposes MCP tools and handles file IPC.
- IPC directory: `/tmp/adi_mcp/<PID>/`

Release/validation builds use `src/mcp_stub/` (no-op implementation).

## Prerequisites

- Build profile must be `development`.
- The target app must call `Adi.MCP.Initialize`.
- MCP server config must point at `tools/adi_mcp_server.py` and the same base directory (`/tmp/adi_mcp`).

## App Integration

In the app:

```ada
with Adi.MCP;
...
Adi.MCP.Initialize (W);
```

Optional explicit base directory:

```ada
Adi.MCP.Initialize (W, Base_Dir => "/tmp/adi_mcp");
```

Recommended on shutdown:

```ada
Adi.MCP.Finalize;
```

## MCP Server Configuration

`/.mcp.json` and `/.codex/config.toml` should run:

```bash
uv run ./tools/adi_mcp_server.py --dir /tmp/adi_mcp
```

Optional:

- `--pid <pid>` to target a specific running app.
- `--dir <path>` if you intentionally override the IPC base directory.

## Available MCP Tools

### Inspection

| Tool | Description |
|------|-------------|
| `screenshot()` | Capture PNG screenshot, returns file path |
| `widget_tree()` | Full widget hierarchy as JSON (type, id, path, text, bounds, states, flags, children, overlays) |
| `widget_info(id, path)` | Detailed info for one widget (by ID or path) |
| `perf_stats()` | Frame timing counters and FPS |

### Search

| Tool | Description |
|------|-------------|
| `find_by_text(query, exact)` | Find widgets by text content (case-insensitive substring or exact match) |
| `find_by_type(type_name)` | Find widgets by type name (case-insensitive substring match) |

### Interaction

| Tool | Description |
|------|-------------|
| `click_widget(id, path)` | Simulate mouse click at widget center |
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

## Troubleshooting

- `No running Adi application found`:
  Confirm the app called `Adi.MCP.Initialize` and is running in development profile.
- Timeouts:
  Check that the app is still alive and rendering frames.
- Mismatched directories:
  Ensure Ada `Base_Dir` and Python `--dir` match exactly.
