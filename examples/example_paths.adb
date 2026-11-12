--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Ada.Directories;
with Adi.Log;
with Adi.OS;

package body Example_Paths is
   procedure Initialize is
      use Ada.Directories;
   begin
      declare
         Base : constant String := Adi.OS.Base_Path;
      begin
         if Base /= "" and then Exists (Base & "../assets") then
            Set_Directory (Base & "..");
         elsif Base /= "" and then Exists (Base & "assets") then
            --  WebAssembly mounts the example resources beside the program.
            Set_Directory (Base);
         else
            Adi.Log.Warning
              ("[Example_Paths] Cannot locate example assets beside executable; "
               & "keeping current directory");
         end if;
      end;
   end Initialize;
end Example_Paths;
