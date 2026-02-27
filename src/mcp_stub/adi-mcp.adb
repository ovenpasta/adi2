pragma Ada_2022;

package body Adi.MCP is

   procedure Initialize
     (Win      : not null access Adi.Window.Window'Class;
      Base_Dir : String := ".adi_mcp")
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
