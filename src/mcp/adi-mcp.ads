--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.JSON;
with Adi.Render;
with Adi.Window;

package Adi.MCP is

   --  /tmp/adi_mcp, or %TEMP%\adi_mcp on Windows.
   function Default_Base_Dir return String;

   --  Initialize the MCP command processor for a window.
   --  Creates <Base_Dir>/<PID>/ with a "ready" sentinel file, which is
   --  rewritten as the application runs: a directory whose "ready" has
   --  stopped being touched belongs to a process that is gone.
   --  Registers callbacks that poll for commands each frame.
   procedure Initialize
     (Win      : Adi.Window.Window_Handle;
      Base_Dir : String := Default_Base_Dir);

   --  Shut down and clean up the MCP directory.
   procedure Finalize;

   --  Whether MCP has been initialized and is active.
   function Is_Active return Boolean;



private

   --  The texture-cache section of perf_stats. Reachable from the testing
   --  child so its schema can be asserted without a running application:
   --  a renamed or dropped field would otherwise only show up against a
   --  live process. Writes one object; the caller supplies the key.
   procedure Write_Texture_Cache
     (W     : in out Adi.JSON.JSON_Writer;
      Stats : Adi.Render.Texture_Stats);

   --  The frame timings and per-frame counters of perf_stats, written as
   --  keys into an object the caller has opened. Reachable from the
   --  testing child for the same reason.
   procedure Write_Frame_Stats
     (W     : in out Adi.JSON.JSON_Writer;
      Stats : Adi.Window.Frame_Stats);

end Adi.MCP;
