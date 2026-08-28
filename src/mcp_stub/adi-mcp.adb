--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.Build_Target;

package body Adi.MCP is

   function Default_Base_Dir return String is
      use Adi.Build_Target;
      use Ada.Environment_Variables;
   begin
      case Platform is
         when Windows =>
            if Exists ("TEMP") then
               return Value ("TEMP") & "\\adi_mcp";
            elsif Exists ("TMP") then
               return Value ("TMP") & "\\adi_mcp";
            end if;
            return "C:\\Windows\\Temp\\adi_mcp";
         when others =>
            return "/tmp/adi_mcp";
      end case;
   end Default_Base_Dir;

   procedure Initialize
     (Win      : Adi.Window.Window_Handle;
      Base_Dir : String := Default_Base_Dir)
   is
      pragma Unreferenced (Win, Base_Dir);
   begin
      null;
   end Initialize;

   procedure Finalize is
   begin
      null;
   end Finalize;

   function Is_Active return Boolean is
   begin
      return False;
   end Is_Active;

end Adi.MCP;
