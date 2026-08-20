--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.JSON;
with Adi.Render;
with Adi.Window;

package Adi.MCP is

   --  Initialize the MCP command processor for a window.
   --  Creates <Base_Dir>/<PID>/ with a "ready" sentinel file.
   --  Registers callbacks that poll for commands each frame.
   --  Base_Dir defaults to "/tmp/adi_mcp" (well-known absolute location).
   procedure Initialize
     (Win      : Adi.Window.Window_Handle;
      Base_Dir : String := "/tmp/adi_mcp");

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

end Adi.MCP;
