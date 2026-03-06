with Ada.Containers.Vectors;
with Adi.Text_Buffer;
with Adi.Widget;
with Adi.Widget.Context_Menu;
with Adi.Window;

package Adi.Widget.Text_Context_Menu is

   type Text_Menu_Command is
     (Cmd_Undo,
      Cmd_Redo,
      Cmd_Cut,
      Cmd_Copy,
      Cmd_Paste,
      Cmd_Select_All);

   type Command_Applied_Callback is access procedure
     (Menu         : Adi.Widget.Context_Menu.Menu_Handle;
      Command      : Text_Menu_Command;
      Changed_Text : Boolean);

   type Read_Only_Query is access function
     (Menu : Adi.Widget.Context_Menu.Menu_Handle) return Boolean;

   function Create_Default
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Access;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null)
      return Adi.Widget.Context_Menu.Context_Menu_Access
     with Obsolescent => "Use Create_Default_Handle";
   function Create_Default
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Handle;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null)
      return Adi.Widget.Context_Menu.Context_Menu_Access
     with Obsolescent => "Use Create_Default_Handle";
   function Create_Default_Handle
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Access;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null)
      return Adi.Widget.Context_Menu.Menu_Handle
     with Obsolescent => "Use Create_Default_Handle with Window_Handle";
   function Create_Default_Handle
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Handle;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null)
      return Adi.Widget.Context_Menu.Menu_Handle;

   procedure Bind_Widget_Request
     (Target : in out Adi.Widget.Widget'Class;
      Menu   : Adi.Widget.Context_Menu.Context_Menu_Access)
     with Obsolescent => "Use Bind_Widget_Request with handles";
   procedure Bind_Widget_Request
     (Target : Adi.Widget.Widget_Handle;
      Menu   : Adi.Widget.Context_Menu.Menu_Handle);

   --  Remove binding entries for a given menu (call before destroying it).
   procedure Unbind_Menu
     (Menu : Adi.Widget.Context_Menu.Context_Menu_Access)
     with Obsolescent => "Use Unbind_Menu with Menu_Handle";
   procedure Unbind_Menu
     (Menu : Adi.Widget.Context_Menu.Menu_Handle);

private
   type Command_Binding is record
      Menu         : Adi.Widget.Context_Menu.Menu_Handle;
      Buffer       : Adi.Text_Buffer.Text_Buffer_Access := null;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null;
   end record;

   package Command_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Command_Binding);

   type Request_Binding is record
      Target  : Adi.Widget.Widget_Handle;
      Menu    : Adi.Widget.Context_Menu.Context_Menu_Access := null;
      Conn_Id : Adi.Widget.Context_Menu_Signals.Connection_Id :=
        Adi.Widget.Context_Menu_Signals.No_Connection;
   end record;

   package Request_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Request_Binding);

end Adi.Widget.Text_Context_Menu;
