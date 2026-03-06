pragma Ada_2022;

with Adi.Window;

package Adi.MCP is

   --  Initialize the MCP command processor for a window.
   --  Creates <Base_Dir>/<PID>/ with a "ready" sentinel file.
   --  Registers callbacks that poll for commands each frame.
   --  Base_Dir defaults to "/tmp/adi_mcp" (well-known absolute location).
   procedure Initialize
     (Win      : not null access Adi.Window.Window'Class;
      Base_Dir : String := "/tmp/adi_mcp");
   procedure Initialize
     (Win      : Adi.Window.Window_Handle;
      Base_Dir : String := "/tmp/adi_mcp");

   --  Shut down and clean up the MCP directory.
   procedure Finalize;

   --  Whether MCP has been initialized and is active.
   function Is_Active return Boolean;

end Adi.MCP;
