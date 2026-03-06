pragma Ada_2022;

with Adi.Window;

package Adi.MCP is

   --  Stub: MCP support excluded from this build profile.
   --  All operations are no-ops.

   procedure Initialize
     (Win      : not null access Adi.Window.Window'Class;
      Base_Dir : String := "/tmp/adi_mcp")
     with Obsolescent => "Use Initialize (Win : Window_Handle)";
   procedure Initialize
     (Win      : Adi.Window.Window_Handle;
      Base_Dir : String := "/tmp/adi_mcp");
   procedure Finalize;
   function Is_Active return Boolean;

end Adi.MCP;
