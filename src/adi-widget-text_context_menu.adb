with Adi.Text_Buffer; use Adi.Text_Buffer;
with Adi.Widget;      use Adi.Widget;
with Adi.Widget.Context_Menu;

package body Adi.Widget.Text_Context_Menu is

   use type Adi.Widget.Context_Menu.Context_Menu_Access;
   use type Adi.Widget.Context_Menu.Menu_Handle;
   use type Adi.Text_Buffer.Text_Buffer_Access;
   use type Adi.Window.Window_Access;
   use type Context_Menu_Signals.Connection_Id;

   Command_Bindings : Command_Binding_Vectors.Vector;
   Request_Bindings : Request_Binding_Vectors.Vector;

   function Find_Command_Binding
     (Menu : Adi.Widget.Context_Menu.Menu_Handle) return Natural
   is
      use type Adi.Widget.Context_Menu.Menu_Handle;
   begin
      for I in 1 .. Natural (Command_Bindings.Length) loop
         if Command_Bindings.Element (I).Menu = Menu then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Command_Binding;

   function Find_Request_Binding
     (Target : Adi.Widget.Widget_Handle) return Natural
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
     (Menu  : Adi.Widget.Context_Menu.Menu_Handle;
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

      if Command_Bindings.Element (Binding_Idx).Is_Read_Only /= null
        and then Command_Bindings.Element (Binding_Idx).Is_Read_Only (Menu)
      then
         case Command is
            when Cmd_Undo | Cmd_Redo | Cmd_Cut | Cmd_Paste => return;
            when others => null;
         end case;
      end if;

      if Command_Bindings.Element (Binding_Idx).Is_Password /= null
        and then Command_Bindings.Element (Binding_Idx).Is_Password (Menu)
      then
         case Command is
            when Cmd_Cut | Cmd_Copy => return;
            when others => null;
         end case;
      end if;

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
     (W    : Adi.Widget.Widget_Handle;
      X, Y : Pixel_Type)
   is
      Idx  : constant Natural := Find_Request_Binding (W);
      Host : Adi.Window.Window_Access;
   begin
      if Idx = 0 then
         return;
      end if;

      if Adi.Widget.Context_Menu.Is_Valid (Request_Bindings.Element (Idx).Menu) then
         Host := Adi.Window.Find_Host_Window (W);
         if Host /= null then
            Adi.Widget.Context_Menu.Attach_Window
              (Request_Bindings.Element (Idx).Menu,
               Adi.Window.Get_Handle (Host.all));
         end if;

         declare
            M_H     : constant Adi.Widget.Context_Menu.Menu_Handle :=
              Request_Bindings.Element (Idx).Menu;
            Cmd_Idx : constant Natural := Find_Command_Binding (M_H);
            RO      : Boolean := False;
            Pwd     : Boolean := False;
         begin
            if Cmd_Idx /= 0
              and then Command_Bindings.Element (Cmd_Idx).Is_Read_Only /= null
            then
               RO := Command_Bindings.Element (Cmd_Idx).Is_Read_Only (M_H);
            end if;

            if Cmd_Idx /= 0
              and then Command_Bindings.Element (Cmd_Idx).Is_Password /= null
            then
               Pwd := Command_Bindings.Element (Cmd_Idx).Is_Password (M_H);
            end if;

            --  Undo(1), Redo(2): disabled when read-only
            --  Cut(3): disabled when read-only or password
            --  Copy(4): disabled when password
            --  Paste(5): disabled when read-only
            --  Select All(6): always enabled
            Adi.Widget.Context_Menu.Set_Item_Disabled (M_H, 1, RO);
            Adi.Widget.Context_Menu.Set_Item_Disabled (M_H, 2, RO);
            Adi.Widget.Context_Menu.Set_Item_Disabled (M_H, 3, RO or Pwd);
            Adi.Widget.Context_Menu.Set_Item_Disabled (M_H, 4, Pwd);
            Adi.Widget.Context_Menu.Set_Item_Disabled (M_H, 5, RO);
            Adi.Widget.Context_Menu.Set_Item_Disabled (M_H, 6, False);
         end;

         Adi.Widget.Context_Menu.Show_At
           (Request_Bindings.Element (Idx).Menu, X, Y);
      end if;
   end On_Context_Request;

   function Create_Default
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Access;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null;
      Is_Password  : Password_Query  := null)
      return Adi.Widget.Context_Menu.Context_Menu_Access
   is
      Menu : constant Adi.Widget.Context_Menu.Context_Menu_Access :=
        Adi.Widget.Context_Menu.Create;
      Menu_H : constant Adi.Widget.Context_Menu.Menu_Handle :=
        Adi.Widget.Context_Menu.Get_Handle (Menu.all);
   begin
      if Host /= null then
         Adi.Widget.Context_Menu.Attach_Window
           (Menu.all, Adi.Window.Get_Handle (Host.all));
      end if;
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Undo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Redo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Cut");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Copy");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Paste");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Select All");
      Adi.Widget.Context_Menu.Connect_Item_Selected
        (Menu.all, On_Menu_Command'Access);

      declare
         I : constant Natural := Find_Command_Binding (Menu_H);
      begin
         if I = 0 then
            Command_Bindings.Append
              (New_Item =>
                 Command_Binding'
                   (Menu         => Menu_H,
                    Buffer       => Buffer,
                    Single_Line  => Single_Line,
                    On_Applied   => On_Applied,
                    Is_Read_Only => Is_Read_Only,
                    Is_Password  => Is_Password));
         else
            Command_Bindings.Replace_Element
              (I,
               (Menu         => Menu_H,
                Buffer       => Buffer,
                Single_Line  => Single_Line,
                On_Applied   => On_Applied,
                Is_Read_Only => Is_Read_Only,
                Is_Password  => Is_Password));
         end if;
      end;

      return Menu;
   end Create_Default;

   function Create_Default
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Handle;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null;
      Is_Password  : Password_Query  := null)
      return Adi.Widget.Context_Menu.Context_Menu_Access
   is
      Menu : constant Adi.Widget.Context_Menu.Context_Menu_Access :=
        Adi.Widget.Context_Menu.Create;
      Menu_H : constant Adi.Widget.Context_Menu.Menu_Handle :=
        Adi.Widget.Context_Menu.Get_Handle (Menu.all);
   begin
      if Adi.Window.Is_Valid (Host) then
         Adi.Widget.Context_Menu.Attach_Window (Menu_H, Host);
      end if;
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Undo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Redo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Cut");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Copy");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Paste");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Select All");
      Adi.Widget.Context_Menu.Connect_Item_Selected
        (Menu_H, On_Menu_Command'Access);

      declare
         I : constant Natural := Find_Command_Binding (Menu_H);
      begin
         if I = 0 then
            Command_Bindings.Append
              (New_Item =>
                 Command_Binding'
                   (Menu         => Menu_H,
                    Buffer       => Buffer,
                    Single_Line  => Single_Line,
                    On_Applied   => On_Applied,
                    Is_Read_Only => Is_Read_Only,
                    Is_Password  => Is_Password));
         else
            Command_Bindings.Replace_Element
              (I,
               (Menu         => Menu_H,
                Buffer       => Buffer,
                Single_Line  => Single_Line,
                On_Applied   => On_Applied,
                Is_Read_Only => Is_Read_Only,
                Is_Password  => Is_Password));
         end if;
      end;

      return Menu;
   end Create_Default;

   function Create_Default_Handle
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Access;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null;
      Is_Password  : Password_Query  := null)
      return Adi.Widget.Context_Menu.Menu_Handle
   is
      M : constant Adi.Widget.Context_Menu.Context_Menu_Access :=
        Create_Default
          (Buffer       => Buffer,
           Host         => Host,
           Single_Line  => Single_Line,
           On_Applied   => On_Applied,
           Is_Read_Only => Is_Read_Only,
           Is_Password  => Is_Password);
   begin
      if M = null then
         return Adi.Widget.Context_Menu.Null_Menu_Handle;
      end if;
      return Adi.Widget.Context_Menu.Get_Handle (M.all);
   end Create_Default_Handle;

   function Create_Default_Handle
     (Buffer       : Adi.Text_Buffer.Text_Buffer_Access;
      Host         : Adi.Window.Window_Handle;
      Single_Line  : Boolean := False;
      On_Applied   : Command_Applied_Callback := null;
      Is_Read_Only : Read_Only_Query := null;
      Is_Password  : Password_Query  := null)
      return Adi.Widget.Context_Menu.Menu_Handle
   is
      M : constant Adi.Widget.Context_Menu.Context_Menu_Access :=
        Create_Default
          (Buffer       => Buffer,
           Host         => Host,
           Single_Line  => Single_Line,
           On_Applied   => On_Applied,
           Is_Read_Only => Is_Read_Only,
           Is_Password  => Is_Password);
   begin
      if M = null then
         return Adi.Widget.Context_Menu.Null_Menu_Handle;
      end if;
      return Adi.Widget.Context_Menu.Get_Handle (M.all);
   end Create_Default_Handle;

   procedure Bind_Widget_Request
     (Target : in out Adi.Widget.Widget'Class;
      Menu   : Adi.Widget.Context_Menu.Context_Menu_Access)
   is
      Menu_H   : Adi.Widget.Context_Menu.Menu_Handle :=
        Adi.Widget.Context_Menu.Null_Menu_Handle;
      T_Handle : constant Adi.Widget.Widget_Handle := Get_Handle (Target);
      I        : constant Natural := Find_Request_Binding (T_Handle);
      Conn     : Context_Menu_Signals.Connection_Id;
   begin
      if Menu = null then
         return;
      end if;

      Menu_H := Adi.Widget.Context_Menu.Get_Handle (Menu.all);

      if I /= 0 then
         --  Disconnect previous subscription before reconnecting.
         Disconnect_Context_Menu
           (Target, Request_Bindings.Element (I).Conn_Id);
      end if;
      Conn := Connect_Context_Menu (Target, On_Context_Request'Access);
      if I = 0 then
         Request_Bindings.Append
           (New_Item => Request_Binding'(Target  => T_Handle,
                                         Menu    => Menu_H,
                                         Conn_Id => Conn));
      else
         Request_Bindings.Replace_Element
           (I, (Target  => T_Handle,
                Menu    => Menu_H,
                Conn_Id => Conn));
      end if;
   end Bind_Widget_Request;

   procedure Bind_Widget_Request
     (Target : Adi.Widget.Widget_Handle;
      Menu   : Adi.Widget.Context_Menu.Menu_Handle)
   is
   begin
      if not Is_Valid (Target)
        or else not Adi.Widget.Context_Menu.Is_Valid (Menu)
      then
         return;
      end if;

      begin
         declare
            R : Widget_Ref := Borrow (Target);
            T_Handle : constant Adi.Widget.Widget_Handle := Get_Handle (R.Ptr.all);
            I        : constant Natural := Find_Request_Binding (T_Handle);
            Conn     : Context_Menu_Signals.Connection_Id;
         begin
            if I /= 0 then
               Disconnect_Context_Menu
                 (R.Ptr.all, Request_Bindings.Element (I).Conn_Id);
            end if;

            Conn := Connect_Context_Menu (R.Ptr.all, On_Context_Request'Access);
            if I = 0 then
               Request_Bindings.Append
                 (New_Item => Request_Binding'(Target  => T_Handle,
                                               Menu    => Menu,
                                               Conn_Id => Conn));
            else
               Request_Bindings.Replace_Element
                 (I, (Target  => T_Handle,
                      Menu    => Menu,
                      Conn_Id => Conn));
            end if;
         end;
      exception
         when Constraint_Error =>
            null;
      end;
   end Bind_Widget_Request;

   procedure Unbind_Menu
     (Menu : Adi.Widget.Context_Menu.Context_Menu_Access)
   is
   begin
      if Menu /= null then
         Unbind_Menu (Adi.Widget.Context_Menu.Get_Handle (Menu.all));
      end if;
   end Unbind_Menu;

   procedure Unbind_Menu
     (Menu : Adi.Widget.Context_Menu.Menu_Handle)
   is
   begin
      if not Adi.Widget.Context_Menu.Is_Valid (Menu) then
         return;
      end if;

      --  Remove command binding for this menu
      declare
         I : constant Natural := Find_Command_Binding (Menu);
      begin
         if I /= 0 then
            Command_Bindings.Delete (I);
         end if;
      end;

      --  Remove request binding(s) that reference this menu,
      --  disconnecting signal subscriptions first.
      declare
         I : Natural := 1;
      begin
         while I <= Natural (Request_Bindings.Length) loop
            if Request_Bindings.Element (I).Menu = Menu then
               declare
                  B : constant Request_Binding := Request_Bindings.Element (I);
               begin
                  if Is_Valid (B.Target)
                    and then B.Conn_Id /= Context_Menu_Signals.No_Connection
                  then
                     declare
                        R : Widget_Ref := Borrow (B.Target);
                     begin
                        Disconnect_Context_Menu (R.Ptr.all, B.Conn_Id);
                     end;
                  end if;
               exception
                  when Constraint_Error =>
                     null;
               end;
               Request_Bindings.Delete (I);
            else
               I := I + 1;
            end if;
         end loop;
      end;
   end Unbind_Menu;

end Adi.Widget.Text_Context_Menu;
