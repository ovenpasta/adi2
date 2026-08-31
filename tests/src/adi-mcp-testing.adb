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

   procedure Write_Frame_Stats
     (W     : in out Adi.JSON.JSON_Writer;
      Stats : Adi.Window.Frame_Stats) is
   begin
      Adi.MCP.Write_Frame_Stats (W, Stats);
   end Write_Frame_Stats;

   procedure Write_Style_Stores (W : in out Adi.JSON.JSON_Writer) is
   begin
      Adi.MCP.Write_Style_Stores (W);
   end Write_Style_Stores;

end Adi.MCP.Testing;
