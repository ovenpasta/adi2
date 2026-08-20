# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=1.0"]
# ///
"""MCP server wrapping the Ada Language Server (ALS).

Provides goto-definition, find-references, and document-symbols tools
for Ada codebases via LSP.

Usage (via Claude Code MCP config):
    uv run tools/als_mcp_server.py
"""

import asyncio
import json
import os
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ALS_BIN = os.environ.get(
    "ALS_BIN",
    "ada_language_server"
    )


PROJECT_ROOT = os.environ.get("ALS_PROJECT_ROOT", "/src/ada/adi2")
GPR_FILE = os.environ.get("ALS_GPR_FILE", "adi.gpr")

# ---------------------------------------------------------------------------
# LSP client – minimal, just enough for the operations we need
# ---------------------------------------------------------------------------


class ALSClient:
    """Async LSP JSON-RPC client driving an ALS subprocess."""

    def __init__(self) -> None:
        self._proc: asyncio.subprocess.Process | None = None
        self._req_id = 0
        self._pending: dict[int, asyncio.Future] = {}
        self._reader_task: asyncio.Task | None = None
        self._initialized = False
        self._lock = asyncio.Lock()

    # -- lifecycle -----------------------------------------------------------

    async def ensure_started(self) -> None:
        async with self._lock:
            if self._initialized:
                return
            await self._start()

    async def _start(self) -> None:
        self._proc = await asyncio.create_subprocess_exec(
            ALS_BIN,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )
        self._reader_task = asyncio.create_task(self._read_loop())

        root_uri = Path(PROJECT_ROOT).as_uri()
        await self._request(
            "initialize",
            {
                "processId": os.getpid(),
                "rootUri": root_uri,
                "capabilities": {},
                "initializationOptions": {
                    "projectFile": GPR_FILE,
                },
            },
        )
        await self._notify("initialized", {})
        self._initialized = True

    async def shutdown(self) -> None:
        if self._proc and self._proc.returncode is None:
            try:
                await self._request("shutdown", None)
                await self._notify("exit", None)
            except Exception:
                pass
            self._proc.kill()

    # -- JSON-RPC transport --------------------------------------------------

    async def _send(self, msg: dict) -> None:
        body = json.dumps(msg)
        header = f"Content-Length: {len(body)}\r\n\r\n"
        assert self._proc and self._proc.stdin
        self._proc.stdin.write(header.encode() + body.encode())
        await self._proc.stdin.drain()

    async def _read_loop(self) -> None:
        assert self._proc and self._proc.stdout
        reader = self._proc.stdout
        try:
            while True:
                # Read headers
                content_length = 0
                while True:
                    line = await reader.readline()
                    if not line:
                        return
                    line_str = line.decode("utf-8").strip()
                    if not line_str:
                        break
                    if line_str.lower().startswith("content-length:"):
                        content_length = int(line_str.split(":")[1].strip())

                if content_length == 0:
                    continue

                body = await reader.readexactly(content_length)
                msg = json.loads(body)

                # Dispatch responses
                if "id" in msg and msg["id"] in self._pending:
                    fut = self._pending.pop(msg["id"])
                    if "error" in msg:
                        fut.set_exception(
                            RuntimeError(json.dumps(msg["error"]))
                        )
                    else:
                        fut.set_result(msg.get("result"))
                # Notifications/requests from server – ignore
        except (asyncio.IncompleteReadError, ConnectionError):
            pass

    async def _request(self, method: str, params) -> dict | list | None:
        self._req_id += 1
        rid = self._req_id
        msg = {"jsonrpc": "2.0", "id": rid, "method": method, "params": params}
        fut: asyncio.Future = asyncio.get_event_loop().create_future()
        self._pending[rid] = fut
        await self._send(msg)
        return await asyncio.wait_for(fut, timeout=30)

    async def _notify(self, method: str, params) -> None:
        msg = {"jsonrpc": "2.0", "method": method, "params": params}
        await self._send(msg)

    # -- helpers -------------------------------------------------------------

    def _text_doc_pos(self, file: str, line: int, col: int) -> dict:
        uri = Path(file).resolve().as_uri()
        return {
            "textDocument": {"uri": uri},
            "position": {"line": line - 1, "character": col - 1},
        }

    def _format_locations(self, result) -> str:
        if result is None:
            return "No results."
        if isinstance(result, dict):
            result = [result]
        lines = []
        for loc in result:
            if "targetUri" in loc:
                # LocationLink
                uri = loc["targetUri"]
                r = loc["targetRange"]
            elif "uri" in loc:
                uri = loc["uri"]
                r = loc["range"]
            else:
                continue
            path = uri.replace("file://", "")
            sl = r["start"]["line"] + 1
            sc = r["start"]["character"] + 1
            lines.append(f"{path}:{sl}:{sc}")
        return "\n".join(lines) if lines else "No results."

    # -- public LSP operations -----------------------------------------------

    async def goto_definition(self, file: str, line: int, col: int) -> str:
        await self.ensure_started()
        result = await self._request(
            "textDocument/definition",
            self._text_doc_pos(file, line, col),
        )
        return self._format_locations(result)

    async def find_references(
        self, file: str, line: int, col: int, include_decl: bool = True
    ) -> str:
        await self.ensure_started()
        params = self._text_doc_pos(file, line, col)
        params["context"] = {"includeDeclaration": include_decl}
        result = await self._request("textDocument/references", params)
        return self._format_locations(result)

    async def document_symbols(self, file: str) -> str:
        await self.ensure_started()
        uri = Path(file).resolve().as_uri()
        result = await self._request(
            "textDocument/documentSymbol",
            {"textDocument": {"uri": uri}},
        )
        if not result:
            return "No symbols found."

        lines = []

        def _walk(symbols, indent=0):
            for sym in symbols:
                name = sym.get("name", "?")
                kind = _SYMBOL_KINDS.get(sym.get("kind", 0), "?")
                r = sym.get("selectionRange") or sym.get("range", {})
                sl = r.get("start", {}).get("line", 0) + 1
                prefix = "  " * indent
                lines.append(f"{prefix}{kind} {name} (line {sl})")
                if "children" in sym:
                    _walk(sym["children"], indent + 1)

        _walk(result)
        return "\n".join(lines)

    async def hover(self, file: str, line: int, col: int) -> str:
        await self.ensure_started()
        result = await self._request(
            "textDocument/hover",
            self._text_doc_pos(file, line, col),
        )
        if not result:
            return "No hover info."
        contents = result.get("contents", "")
        if isinstance(contents, dict):
            return contents.get("value", str(contents))
        if isinstance(contents, list):
            return "\n".join(
                c.get("value", str(c)) if isinstance(c, dict) else str(c)
                for c in contents
            )
        return str(contents)


_SYMBOL_KINDS = {
    1: "File",
    2: "Module",
    3: "Namespace",
    4: "Package",
    5: "Class",
    6: "Method",
    7: "Property",
    8: "Field",
    9: "Constructor",
    10: "Enum",
    11: "Interface",
    12: "Function",
    13: "Variable",
    14: "Constant",
    15: "String",
    16: "Number",
    17: "Boolean",
    18: "Array",
    19: "Object",
    20: "Key",
    21: "Null",
    22: "EnumMember",
    23: "Struct",
    24: "Event",
    25: "Operator",
    26: "TypeParameter",
}

# ---------------------------------------------------------------------------
# MCP server
# ---------------------------------------------------------------------------

mcp = FastMCP("Ada Language Server", log_level="WARNING")
_client = ALSClient()


@mcp.tool()
async def goto_definition(file: str, line: int, column: int) -> str:
    """Go to the definition of the symbol at the given location.

    Args:
        file: Absolute path to the Ada source file.
        line: Line number (1-based).
        column: Column number (1-based).
    """
    return await _client.goto_definition(file, line, column)


@mcp.tool()
async def find_references(file: str, line: int, column: int) -> str:
    """Find all references to the symbol at the given location.

    Args:
        file: Absolute path to the Ada source file.
        line: Line number (1-based).
        column: Column number (1-based).
    """
    return await _client.find_references(file, line, column)


@mcp.tool()
async def document_symbols(file: str) -> str:
    """List all symbols (packages, types, subprograms, etc.) in an Ada file.

    Args:
        file: Absolute path to the Ada source file.
    """
    return await _client.document_symbols(file)


@mcp.tool()
async def hover(file: str, line: int, column: int) -> str:
    """Get type/signature information for the symbol at the given location.

    Args:
        file: Absolute path to the Ada source file.
        line: Line number (1-based).
        column: Column number (1-based).
    """
    return await _client.hover(file, line, column)


if __name__ == "__main__":
    mcp.run(transport="stdio")
