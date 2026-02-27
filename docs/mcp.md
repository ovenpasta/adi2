# Adi MCP Runtime Introspection

This guide explains how to inspect a running Adi app from MCP using screenshot and widget introspection tools.

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

- `screenshot()`:
  Returns a PNG path in the app session directory.
- `widget_tree()`:
  Returns full widget hierarchy (type, path, geometry, states, flags, children).
- `widget_info(path)`:
  Returns detailed info for one widget path (for example `1.2.3`).
- `perf_stats()`:
  Returns frame timing counters and FPS fields.

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

