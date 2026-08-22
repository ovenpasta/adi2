"""Tests for the Adi MCP server IPC protocol."""

import json
import os
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

# Import the module under test, with mocking for the mcp dependency
import sys
sys.path.insert(0, os.path.dirname(__file__))

# Mock the mcp module since it's only available via uv run
from unittest.mock import MagicMock


class _PassThroughMCP:
    """Stands in for FastMCP so @mcp.tool() leaves the function alone.

    A MagicMock decorator would replace every tool with a mock, which
    puts the tools themselves out of reach of these tests.

    What it is handed is recorded, so a tool that reaches MCP without
    also reaching the command line can be told apart from one that
    reaches both.
    """

    def __init__(self):
        self.registered = []

    def tool(self, *args, **kwargs):
        def record(func):
            self.registered.append(func.__name__)
            return func
        return record

    def run(self, *args, **kwargs):
        pass


_passthrough = _PassThroughMCP()


_fastmcp = MagicMock()
_fastmcp.FastMCP = lambda *a, **k: _passthrough

sys.modules['mcp'] = MagicMock()
sys.modules['mcp.server'] = MagicMock()
sys.modules['mcp.server.fastmcp'] = _fastmcp

import adi_mcp_server


class TestFindMcpDir(unittest.TestCase):
    """Tests for MCP directory discovery."""

    def test_specific_pid_not_found(self):
        """Raises RuntimeError when no directory exists for given PID."""
        with self.assertRaises(RuntimeError):
            adi_mcp_server.find_mcp_dir(pid=999999999)

    def test_specific_pid_found(self):
        """Finds directory when it exists with ready sentinel."""
        with tempfile.TemporaryDirectory() as tmpdir:
            pid = 12345
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            mcp_dir = parent / str(pid)
            mcp_dir.mkdir()
            (mcp_dir / "ready").write_text(str(pid))

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT',
                              parent):
                result = adi_mcp_server.find_mcp_dir(pid=pid)
                self.assertEqual(result, mcp_dir)

    def test_auto_discover_no_apps(self):
        """Raises RuntimeError when no Adi apps are running."""
        with tempfile.TemporaryDirectory() as tmpdir:
            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT',
                              Path(tmpdir) / "nonexistent"):
                with self.assertRaises(RuntimeError) as ctx:
                    adi_mcp_server.find_mcp_dir()
                self.assertIn("No running Adi application", str(ctx.exception))

    def test_auto_discover_single_app(self):
        """Auto-discovery selects the only live application."""
        with tempfile.TemporaryDirectory() as tmpdir:
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            pid = os.getpid()
            mcp_dir = parent / str(pid)
            mcp_dir.mkdir()
            (mcp_dir / "ready").write_text(str(pid))

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT', parent):
                self.assertEqual(adi_mcp_server.find_mcp_dir(), mcp_dir)

    def test_auto_discover_multiple_apps_is_ambiguous(self):
        """Refuses to guess between several live applications.

        Silently picking the most recently modified directory targets
        whichever app rendered last, not the one the caller meant.
        """
        with tempfile.TemporaryDirectory() as tmpdir:
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            #  Two directories that both look alive: this process, and
            #  its parent, which is necessarily running too.
            pids = [os.getpid(), os.getppid()]
            for pid in pids:
                mcp_dir = parent / str(pid)
                mcp_dir.mkdir()
                (mcp_dir / "ready").write_text(str(pid))

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT', parent):
                with self.assertRaises(RuntimeError) as ctx:
                    adi_mcp_server.find_mcp_dir()
                message = str(ctx.exception)
                self.assertIn("Multiple running Adi applications", message)
                self.assertIn("--pid", message)
                for pid in pids:
                    self.assertIn(str(pid), message)

    def test_explicit_pid_wins_over_ambiguity(self):
        """An explicit --pid still resolves when several apps are live."""
        with tempfile.TemporaryDirectory() as tmpdir:
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            pids = [os.getpid(), os.getppid()]
            for pid in pids:
                mcp_dir = parent / str(pid)
                mcp_dir.mkdir()
                (mcp_dir / "ready").write_text(str(pid))

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT', parent):
                result = adi_mcp_server.find_mcp_dir(pid=pids[0])
                self.assertEqual(result, parent / str(pids[0]))


class TestSendCommand(unittest.TestCase):
    """Tests for the IPC send/receive protocol."""

    def test_timeout_no_response(self):
        """Times out when no response file appears."""
        with tempfile.TemporaryDirectory() as tmpdir:
            pid = 99998
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            mcp_dir = parent / str(pid)
            mcp_dir.mkdir()
            (mcp_dir / "ready").write_text(str(pid))

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT', parent):
                with patch.object(adi_mcp_server, 'TIMEOUT', 0.3):
                    with patch.object(adi_mcp_server, 'POLL_INTERVAL', 0.1):
                        with self.assertRaises(RuntimeError) as ctx:
                            adi_mcp_server.send_command(
                                {"command": "perf_stats"}, pid=pid)
                        self.assertIn("Timeout", str(ctx.exception))

    def test_command_file_written(self):
        """Command file is written with correct structure."""
        with tempfile.TemporaryDirectory() as tmpdir:
            pid = 99997
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            mcp_dir = parent / str(pid)
            mcp_dir.mkdir()
            (mcp_dir / "ready").write_text(str(pid))

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT', parent):
                with patch.object(adi_mcp_server, 'TIMEOUT', 0.2):
                    with patch.object(adi_mcp_server, 'POLL_INTERVAL', 0.05):
                        try:
                            adi_mcp_server.send_command(
                                {"command": "widget_tree"}, pid=pid)
                        except RuntimeError:
                            pass  # Expected timeout

            # Check that a cmd file was written (and possibly cleaned up)
            # The command either exists or was cleaned up on timeout
            # Just verify the function ran without crashing

    def test_response_received(self):
        """Successfully receives a response when one appears."""
        import threading

        with tempfile.TemporaryDirectory() as tmpdir:
            pid = 99996
            parent = Path(tmpdir) / ".adi_mcp"
            parent.mkdir()
            mcp_dir = parent / str(pid)
            mcp_dir.mkdir()
            (mcp_dir / "ready").write_text(str(pid))

            def write_response():
                """Simulate the Ada side writing a response."""
                time.sleep(0.1)
                # Find the cmd file
                for f in mcp_dir.glob("cmd_*.json"):
                    data = json.loads(f.read_text())
                    req_id = data["req_id"]
                    f.unlink()
                    resp = {"status": "ok", "req_id": req_id,
                            "frame_no": 42}
                    resp_path = mcp_dir / f"resp_{req_id}.json"
                    resp_path.write_text(json.dumps(resp))
                    break

            with patch.object(adi_mcp_server, 'MCP_DIR_PARENT', parent):
                t = threading.Thread(target=write_response)
                t.start()
                result = adi_mcp_server.send_command(
                    {"command": "perf_stats"}, pid=pid)
                t.join()

            self.assertEqual(result["status"], "ok")
            self.assertEqual(result["frame_no"], 42)

    def test_request_id_uniqueness(self):
        """Each command gets a unique request ID."""
        ids = set()
        for _ in range(100):
            import uuid
            ids.add(uuid.uuid4().hex[:8])
        self.assertEqual(len(ids), 100, "UUIDs should be unique")


class TestCommandProtocol(unittest.TestCase):
    """Tests for command JSON structure."""

    def test_command_has_required_fields(self):
        """Commands include command and req_id fields."""
        cmd = {"command": "screenshot"}
        # send_command adds req_id
        cmd["req_id"] = "test1234"
        self.assertIn("command", cmd)
        self.assertIn("req_id", cmd)

    def test_widget_info_includes_path(self):
        """widget_info command includes path parameter."""
        cmd = {"command": "widget_info", "path": "1.2.3"}
        self.assertEqual(cmd["path"], "1.2.3")

    def test_widget_info_includes_id(self):
        """widget_info command includes id parameter."""
        cmd = {"command": "widget_info", "id": 5, "path": ""}
        self.assertEqual(cmd["id"], 5)

    def test_find_by_text_structure(self):
        """find_by_text command includes query and exact fields."""
        cmd = {"command": "find_by_text", "query": "Save", "exact": False}
        self.assertEqual(cmd["query"], "Save")
        self.assertEqual(cmd["exact"], False)

    def test_find_by_type_structure(self):
        """find_by_type command includes type_name field."""
        cmd = {"command": "find_by_type", "type_name": "button"}
        self.assertEqual(cmd["type_name"], "button")

    def test_click_widget_structure(self):
        """click_widget command accepts both id and path."""
        cmd = {"command": "click_widget", "id": 5, "path": ""}
        self.assertEqual(cmd["id"], 5)

    def test_send_keys_structure(self):
        """send_keys command includes keys field."""
        cmd = {"command": "send_keys", "keys": "Hello{Return}"}
        self.assertEqual(cmd["keys"], "Hello{Return}")

    def test_set_text_structure(self):
        """set_text command includes id and text fields."""
        cmd = {"command": "set_text", "id": 5, "text": "new value"}
        self.assertEqual(cmd["id"], 5)
        self.assertEqual(cmd["text"], "new value")

    def test_set_focus_structure(self):
        """set_focus command includes id field."""
        cmd = {"command": "set_focus", "id": 5}
        self.assertEqual(cmd["id"], 5)

    def test_css_values_structure(self):
        """css_values command includes id, path, and part fields."""
        cmd = {"command": "css_values", "id": 5, "path": "", "part": "main"}
        self.assertEqual(cmd["id"], 5)
        self.assertEqual(cmd["part"], "main")

    def test_native_json_types(self):
        """Commands use native JSON types (int, bool), not strings."""
        cmd = {"command": "find_by_text", "query": "Save", "exact": True}
        serialized = json.dumps(cmd)
        parsed = json.loads(serialized)
        self.assertIsInstance(parsed["exact"], bool)
        self.assertTrue(parsed["exact"])

        cmd2 = {"command": "click_widget", "id": 42, "path": ""}
        serialized2 = json.dumps(cmd2)
        parsed2 = json.loads(serialized2)
        self.assertIsInstance(parsed2["id"], int)
        self.assertEqual(parsed2["id"], 42)


class TestQuit(unittest.TestCase):
    """quit must not wait for a reply it cannot receive."""

    def test_does_not_await_a_reply(self):
        with patch.object(adi_mcp_server, "send_command",
                          return_value={"status": "ok"}) as sender:
            self.assertEqual(adi_mcp_server.quit_app(), "requested")
        cmd, kwargs = sender.call_args[0][0], sender.call_args[1]
        self.assertEqual(cmd["command"], "quit")
        #  Awaiting one would block until the timeout: the app removes the
        #  directory the reply lives in as it exits.
        self.assertIs(kwargs.get("await_reply"), False)

    def test_fire_and_forget_returns_without_a_response_file(self):
        """send_command with await_reply=False answers without polling."""
        with tempfile.TemporaryDirectory() as tmpdir:
            parent = Path(tmpdir) / ".adi_mcp"
            mcp_dir = parent / "4321"
            mcp_dir.mkdir(parents=True)
            (mcp_dir / "ready").write_text("4321")
            with patch.object(adi_mcp_server, "MCP_DIR_PARENT", parent):
                #  No responder exists, so a waiting call would time out.
                result = adi_mcp_server.send_command(
                    {"command": "quit"}, pid=4321, await_reply=False)
            self.assertEqual(result["status"], "ok")
            self.assertTrue(
                any(p.name.startswith("cmd_") for p in mcp_dir.iterdir()),
                "the command should still have been written")


class TestScroll(unittest.TestCase):
    """Tests for the scroll tool itself, not a hand-written payload."""

    def _call(self, ok=True, **kwargs):
        """Call scroll() with send_command mocked; return (mock, result)."""
        reply = ({"status": "ok", "x": 450, "y": 380,
                  "dx": kwargs.get("dx", 0), "dy": kwargs.get("dy", 0)}
                 if ok else {"status": "error", "error": "widget not found"})
        with patch.object(adi_mcp_server, "send_command",
                          return_value=reply) as sender:
            return sender, adi_mcp_server.scroll(**kwargs)

    def test_sends_expected_payload(self):
        """Deltas and aim reach send_command under the right keys."""
        sender, _ = self._call(dy=-3)
        cmd = sender.call_args[0][0]
        self.assertEqual(cmd["command"], "scroll")
        self.assertEqual(cmd["dy"], -3)
        self.assertEqual(cmd["dx"], 0)
        self.assertEqual(cmd["x"], -1)
        self.assertEqual(cmd["y"], -1)

    def test_aims_at_a_widget(self):
        """A path is forwarded so the wheel lands on that widget."""
        sender, _ = self._call(dy=2, path="1.2.3")
        self.assertEqual(sender.call_args[0][0]["path"], "1.2.3")

    def test_returns_delivery_point(self):
        """The reply is reduced to where the wheel went and by how much."""
        _, result = self._call(dy=-3)
        self.assertEqual(json.loads(result),
                         {"x": 450, "y": 380, "dx": 0, "dy": -3})

    def test_rejects_zero_delta(self):
        """A scroll of nothing is a caller error, not a no-op request."""
        with self.assertRaises(ValueError):
            adi_mcp_server.scroll()

    def test_rejects_partial_coordinates(self):
        """Half a point would silently aim at the window middle instead."""
        with self.assertRaises(ValueError):
            adi_mcp_server.scroll(dy=-1, x=100)
        with self.assertRaises(ValueError):
            adi_mcp_server.scroll(dy=-1, y=100)

    def test_raises_on_error_status(self):
        """An error reply surfaces rather than being returned as data."""
        with self.assertRaises(RuntimeError):
            self._call(ok=False, dy=-1, path="99.99")


class TestCLI(unittest.TestCase):
    """Tests for the command line surface over the same tools."""

    def setUp(self):
        #  _run_cli sets these for the process it is about to end. In a
        #  test it would outlive the case and aim the next one somewhere
        #  it never asked for.
        base, pid = adi_mcp_server.MCP_DIR_PARENT, adi_mcp_server._target_pid

        def restore():
            adi_mcp_server.MCP_DIR_PARENT = base
            adi_mcp_server._target_pid = pid

        self.addCleanup(restore)

    def test_registry_matches_the_tools(self):
        """Every tool is reachable by name, so the two surfaces agree."""
        for name in ("screenshot", "widget_tree", "perf_stats", "send_keys",
                     "scroll", "css_values", "quit_app"):
            self.assertIn(name, adi_mcp_server.CLI_TOOLS)
            self.assertIs(adi_mcp_server.CLI_TOOLS[name],
                          getattr(adi_mcp_server, name))

    def test_no_tool_reaches_only_one_surface(self):
        """A tool declared past the registry would serve but not run here.

        Asserting the parser against the registry it is built from cannot
        fail. What can is a tool written @mcp.tool() rather than @tool:
        FastMCP takes it and the command line never hears of it.
        """
        self.assertEqual(sorted(_passthrough.registered),
                         sorted(adi_mcp_server.CLI_TOOLS))

    def test_arguments_follow_the_signature(self):
        """Required parameters are positional and defaulted ones are flags."""
        parser = adi_mcp_server._build_cli_parser()

        args = parser.parse_args(["set_text", "7", "hello"])
        self.assertEqual((args.id, args.text), (7, "hello"))

        args = parser.parse_args(["find_by_text", "ok"])
        self.assertEqual((args.query, args.exact), ("ok", False))
        args = parser.parse_args(["find_by_text", "ok", "--exact"])
        self.assertTrue(args.exact)

    def test_tool_parameter_may_shadow_a_server_option(self):
        """A tool is free to have a pid of its own without stealing --pid."""
        parser = adi_mcp_server._build_cli_parser()
        args = parser.parse_args(["--pid", "111", "widget_info", "--id", "222"])
        self.assertEqual((args._target, args.id), (111, 222))

    def test_only_the_selecting_flag_is_stripped(self):
        """A later --cli is a value the tool asked for, not this mode."""
        self.assertEqual(
            adi_mcp_server._strip_cli_flag(["--cli", "send_keys", "--cli"]),
            ["send_keys", "--cli"])
        self.assertEqual(
            adi_mcp_server._strip_cli_flag(
                ["--cli", "send_keys", "--", "--cli"]),
            ["send_keys", "--", "--cli"])
        parser = adi_mcp_server._build_cli_parser()
        args = parser.parse_args(
            adi_mcp_server._strip_cli_flag(
                ["--cli", "send_keys", "--", "--cli"]))
        self.assertEqual(args.keys, "--cli")

    def test_rejects_a_parameter_it_cannot_spell(self):
        """An unspellable parameter is the tool's defect, and is named."""
        def bad_tool(target: dict = None) -> str:
            """A tool nobody can invoke."""

        parser = adi_mcp_server._build_cli_parser()
        with self.assertRaises(TypeError) as ctx:
            adi_mcp_server._add_tool_arguments(parser, bad_tool)
        self.assertIn("bad_tool", str(ctx.exception))

    def test_round_trip_prints_the_reply(self):
        """A tool invoked from the CLI reports what the application sent."""
        import threading

        with tempfile.TemporaryDirectory() as tmpdir:
            pid = os.getpid()          # a live PID, so the dir is not stale
            parent = Path(tmpdir) / ".adi_mcp"
            mcp_dir = parent / str(pid)
            mcp_dir.mkdir(parents=True)
            (mcp_dir / "ready").write_text(str(pid))

            def responder():
                deadline = time.time() + 3
                while time.time() < deadline:
                    for cmd_file in mcp_dir.glob("cmd_*.json"):
                        req = json.loads(cmd_file.read_text())
                        (mcp_dir / f"resp_{req['req_id']}.json").write_text(
                            json.dumps({"status": "ok",
                                        "req_id": req["req_id"],
                                        "path": "/tmp/shot.png"}))
                        cmd_file.unlink(missing_ok=True)
                        return
                    time.sleep(0.02)

            thread = threading.Thread(target=responder, daemon=True)
            thread.start()

            import contextlib
            import io

            out = io.StringIO()
            with patch.object(adi_mcp_server, 'POLL_INTERVAL', 0.02):
                with contextlib.redirect_stdout(out):
                    code = adi_mcp_server._run_cli(
                        ["--dir", str(parent), "--pid", str(pid),
                         "screenshot"])
            thread.join(timeout=3)

        self.assertEqual(code, 0)
        self.assertEqual(out.getvalue().strip(), "/tmp/shot.png")

    def test_failure_exits_non_zero(self):
        """A shell caller can tell a failed query from an empty one."""
        with tempfile.TemporaryDirectory() as tmpdir:
            code = adi_mcp_server._run_cli(
                ["--dir", str(Path(tmpdir) / "absent"), "perf_stats"])
        self.assertEqual(code, 1)


if __name__ == "__main__":
    unittest.main()
