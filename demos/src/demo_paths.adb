--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Ada.Directories;
with Adi.OS;

package body Demo_Paths is
   procedure Initialize is
      use Ada.Directories;
   begin
      if Exists ("demos/assets") then
         return;
      elsif Exists ("../demos/assets") then
         Set_Directory ("..");
      else
         declare
            Base : constant String := Adi.OS.Base_Path;
         begin
            if Base /= "" and then Exists (Base & "../../demos/assets") then
               Set_Directory (Base & "../..");
            end if;
         end;
      end if;
   end Initialize;
end Demo_Paths;
