--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.MCP.Testing is

   procedure Write_Texture_Cache
     (W     : in out Adi.JSON.JSON_Writer;
      Stats : Adi.Render.Texture_Stats) is
   begin
      Adi.MCP.Write_Texture_Cache (W, Stats);
   end Write_Texture_Cache;

end Adi.MCP.Testing;
