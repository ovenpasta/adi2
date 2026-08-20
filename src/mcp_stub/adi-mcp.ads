--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Window;

package Adi.MCP is

   --  Stub: MCP support excluded from this build profile.
   --  All operations are no-ops.

   procedure Initialize
     (Win      : Adi.Window.Window_Handle;
      Base_Dir : String := "/tmp/adi_mcp");
   procedure Finalize;
   function Is_Active return Boolean;

end Adi.MCP;
