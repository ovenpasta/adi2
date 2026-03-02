with Adi.Text_Buffer; use Adi.Text_Buffer;
with Adi.Widget;      use Adi.Widget;
with Adi.Widget.Context_Menu;

package body Adi.Widget.Text_Context_Menu is

   use type Adi.Widget.Context_Menu.Context_Menu_Access;
   use type Adi.Text_Buffer.Text_Buffer_Access;
   use type Adi.Window.Window_Access;

   Command_Bindings : Command_Binding_Vectors.Vector;
   Request_Bindings : Request_Binding_Vectors.Vector;

   function Find_Command_Binding
     (Menu : Adi.Widget.Context_Menu.Context_Menu_Access) return Natural
   is
   begin
      for I in 1 .. Natural (Command_Bindings.Length) loop
         if Command_Bindings.Element (I).Menu = Menu then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Command_Binding;

   function Find_Request_Binding
     (Target : Adi.Widget.Widget_Access) return Natural
   is
   begin
      for I in 1 .. Natural (Request_Bindings.Length) loop
         if Request_Bindings.Element (I).Target = Target then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Request_Binding;

   procedure On_Menu_Command
     (Menu  : Adi.Widget.Context_Menu.Context_Menu_Access;
      Index : Positive;
      Text  : String)
   is
      pragma Unreferenced (Text);
      Binding_Idx : constant Natural := Find_Command_Binding (Menu);
      Command     : Text_Menu_Command;
      Changed     : Boolean := False;
   begin
      if Binding_Idx = 0 then
         return;
      end if;

      case Index is
         when 1 => Command := Cmd_Undo;
         when 2 => Command := Cmd_Redo;
         when 3 => Command := Cmd_Cut;
         when 4 => Command := Cmd_Copy;
         when 5 => Command := Cmd_Paste;
         when 6 => Command := Cmd_Select_All;
         when others => return;
      end case;

      if Command_Bindings.Element (Binding_Idx).Buffer = null then
         return;
      end if;

      declare
         B : Adi.Text_Buffer.Text_Buffer_Access :=
           Command_Bindings.Element (Binding_Idx).Buffer;
         Single_Line : constant Boolean :=
           Command_Bindings.Element (Binding_Idx).Single_Line;
      begin
         case Command is
            when Cmd_Undo =>
               Changed := Undo (B.all);
            when Cmd_Redo =>
               Changed := Redo (B.all);
            when Cmd_Cut =>
               Changed := Cut_Selection_To_Clipboard (B.all);
            when Cmd_Copy =>
               Changed := Copy_Selection_To_Clipboard (B.all);
            when Cmd_Paste =>
               Changed := Paste_From_Clipboard (B.all, Single_Line);
            when Cmd_Select_All =>
               Select_All (B.all);
         end case;
      end;

      if Command_Bindings.Element (Binding_Idx).On_Applied /= null then
         Command_Bindings.Element (Binding_Idx).On_Applied
           (Menu, Command, Changed);
      end if;
   end On_Menu_Command;

   procedure On_Context_Request
     (W    : Adi.Widget.Widget_Access;
      X, Y : Pixel_Type)
   is
      Idx  : constant Natural := Find_Request_Binding (W);
      Host : Adi.Window.Window_Access;
   begin
      if Idx = 0 then
         return;
      end if;

      if Request_Bindings.Element (Idx).Menu /= null then
         Host := Adi.Window.Find_Host_Window (W);
         if Host /= null then
            Adi.Widget.Context_Menu.Attach_Window
              (Request_Bindings.Element (Idx).Menu.all, Host);
         end if;
         Adi.Widget.Context_Menu.Show_At
           (Request_Bindings.Element (Idx).Menu.all, X, Y);
      end if;
   end On_Context_Request;

   function Create_Default
     (Buffer      : Adi.Text_Buffer.Text_Buffer_Access;
      Host        : Adi.Window.Window_Access;
      Single_Line : Boolean := False;
      On_Applied  : Command_Applied_Callback := null)
      return Adi.Widget.Context_Menu.Context_Menu_Access
   is
      Menu : constant Adi.Widget.Context_Menu.Context_Menu_Access :=
        Adi.Widget.Context_Menu.Create;
   begin
      Adi.Widget.Context_Menu.Attach_Window (Menu.all, Host);
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Undo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Redo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Cut");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Copy");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Paste");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Select All");
      Adi.Widget.Context_Menu.Connect_Item_Selected
        (Menu.all, On_Menu_Command'Access);

      declare
         I : constant Natural := Find_Command_Binding (Menu);
      begin
         if I = 0 then
            Command_Bindings.Append
              (New_Item =>
                 Command_Binding'
                   (Menu        => Menu,
                    Buffer      => Buffer,
                    Single_Line => Single_Line,
                    On_Applied  => On_Applied));
         else
            Command_Bindings.Replace_Element
              (I,
               (Menu        => Menu,
                Buffer      => Buffer,
                Single_Line => Single_Line,
                On_Applied  => On_Applied));
         end if;
      end;

      return Menu;
   end Create_Default;

   procedure Bind_Widget_Request
     (Target : in out Adi.Widget.Widget'Class;
      Menu   : Adi.Widget.Context_Menu.Context_Menu_Access)
   is
      T_Access : constant Adi.Widget.Widget_Access := Target'Unchecked_Access;
      I        : constant Natural := Find_Request_Binding (T_Access);
      Conn     : Context_Menu_Signals.Connection_Id;
   begin
      if I /= 0 then
         --  Disconnect previous subscription before reconnecting.
         Disconnect_Context_Menu
           (Target, Request_Bindings.Element (I).Conn_Id);
      end if;
      Conn := Connect_Context_Menu (Target, On_Context_Request'Access);
      if I = 0 then
         Request_Bindings.Append
           (New_Item => Request_Binding'(Target  => T_Access,
                                         Menu    => Menu,
                                         Conn_Id => Conn));
      else
         Request_Bindings.Replace_Element
           (I, (Target  => T_Access,
                Menu    => Menu,
                Conn_Id => Conn));
      end if;
   end Bind_Widget_Request;

end Adi.Widget.Text_Context_Menu;
