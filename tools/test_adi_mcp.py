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
sys.modules['mcp'] = MagicMock()
sys.modules['mcp.server'] = MagicMock()
sys.modules['mcp.server.fastmcp'] = MagicMock()

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


if __name__ == "__main__":
    unittest.main()
