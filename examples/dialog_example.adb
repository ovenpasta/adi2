pragma Ada_2022;

with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.Image;                 use Adi.Image;
with Adi.MCP;
with Adi.Window;                use Adi.Window;
with Adi.Widget;                use Adi.Widget;
with Adi.Widget.Box;            use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;          use Adi.Widget.Label;
with Adi.Widget.Button;         use Adi.Widget.Button;
with Adi.Widget.Dialog;         use Adi.Widget.Dialog;
with Dialog_Example_Styles;     use Dialog_Example_Styles;
with Delete_Dialog_UI;

procedure Dialog_Example is
   A : Adi.App.App;

   Status_Label : Label_Handle;

   Alert_Dialog   : Dialog_Handle;
   Confirm_Dialog : Dialog_Handle;
   Custom_Dialog  : Dialog_Handle;
   Delete_Dialog  : Dialog_Handle;

   procedure On_Alert_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W);
   begin
      if Is_Valid (Status_Label) then
         if Button_Index = 0 then
            Set_Text (Status_Label, "Alert dismissed");
         else
            Set_Text (Status_Label,
                      "Alert: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Alert_Result;

   procedure On_Confirm_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W);
   begin
      if Is_Valid (Status_Label) then
         if Button_Index = 0 then
            Set_Text (Status_Label, "Confirm dismissed");
         else
            Set_Text (Status_Label,
                      "Confirm: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Confirm_Result;

   procedure On_Show_Alert (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      if not Is_Shown (Alert_Dialog) then
         Show (Alert_Dialog);
      end if;
   end On_Show_Alert;

   procedure On_Show_Confirm (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      if not Is_Shown (Confirm_Dialog) then
         Show (Confirm_Dialog);
      end if;
   end On_Show_Confirm;

   procedure On_Custom_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W);
   begin
      if Is_Valid (Status_Label) then
         if Button_Index = 0 then
            Set_Text (Status_Label, "Custom dismissed");
         else
            Set_Text (Status_Label,
                      "Custom: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Custom_Result;

   procedure On_Show_Custom (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      if not Is_Shown (Custom_Dialog) then
         Show (Custom_Dialog);
      end if;
   end On_Show_Custom;

   procedure On_Delete_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W);
   begin
      if Is_Valid (Status_Label) then
         if Button_Index = 0 then
            Set_Text (Status_Label, "Delete dismissed");
         else
            Set_Text (Status_Label,
                      "Delete: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Delete_Result;

   procedure On_Show_Delete (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      if not Is_Shown (Delete_Dialog) then
         Show (Delete_Dialog);
      end if;
   end On_Show_Delete;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("Dialog Example", Adi.Window.Extent (Px (480.0), Px (343.0)));

      Root      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Container : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title     : constant Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Dialog / Alert Widget");
      Hint      : constant Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Click a button to open a modal dialog. "
           & "Click the backdrop or press Escape to dismiss.");

      Alert_Btn   : constant Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Show Alert");
      Confirm_Btn : constant Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Show Confirm");
      Custom_Btn  : constant Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Show Custom");
      Delete_Btn  : constant Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Show Delete (XML)");
   begin
      Status_Label := Adi.Widget.Label.Create_Handle ("(no dialog opened yet)");

      --  Page styles
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Container, Container_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint, Hint_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Status_Label, Status_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Alert_Btn, Btn_Primary_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Confirm_Btn, Btn_Primary_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Custom_Btn, Btn_Primary_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Delete_Btn, Btn_Primary_Class_Part_Styles);

      --  Button callbacks
      Adi.Widget.Button.Connect_Clicked (Alert_Btn, On_Show_Alert'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked (Confirm_Btn, On_Show_Confirm'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked (Custom_Btn, On_Show_Custom'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked (Delete_Btn, On_Show_Delete'Unrestricted_Access);

      --  Build page
      Adi.Widget.Box.Add_Child (Root, +Container);
      Adi.Widget.Box.Add_Child (Container, +Title);
      Adi.Widget.Box.Add_Child (Container, +Hint);
      Adi.Widget.Box.Add_Child (Container, +Alert_Btn);
      Adi.Widget.Box.Add_Child (Container, +Confirm_Btn);
      Adi.Widget.Box.Add_Child (Container, +Custom_Btn);
      Adi.Widget.Box.Add_Child (Container, +Delete_Btn);
      Adi.Widget.Box.Add_Child (Container, +Status_Label);

      --  Set package-level default styles for all dialogs
      Set_Default_Panel_Style (Panel_Class_Part_Styles);
      Set_Default_Title_Style (Dialog_Title_Class_Part_Styles);
      Set_Default_Message_Style (Dialog_Message_Class_Part_Styles);
      Set_Default_Button_Row_Style (Button_Row_Class_Part_Styles);
      Set_Default_Button_Style (Dialog_Btn_Class_Part_Styles);
      Set_Default_Primary_Button_Style (Dialog_Btn_Primary_Class_Part_Styles);

      --  Create alert dialog
      Alert_Dialog := Adi.Widget.Dialog.Create_Handle;
      Attach_Window (Alert_Dialog, W);
      Adi.Widget.Dialog.Set_Part_Styles (Alert_Dialog, Backdrop_Class_Part_Styles);
      Set_Title (Alert_Dialog, "Information");
      Set_Message (Alert_Dialog,
                   "This is a simple alert dialog with a single OK button. "
                   & "You can dismiss it by clicking OK, the backdrop, or pressing Escape.");
      Set_OK_Button (Alert_Dialog);
      Connect_Result (Alert_Dialog, On_Alert_Result'Unrestricted_Access);

      --  Set info icon on alert dialog (Material Symbols "info" 24×24)
      declare
         Info_Icon : constant Adi.Image.Image_Access :=
           Adi.Image.Load_SVG_Path
             (Path_Data =>
                "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 "
                & "10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z",
              Size      => (24.0, 24.0),
              Fill      => (R => 37, G => 99, B => 235, A => 255));
      begin
         if Info_Icon /= null then
            Set_Icon (Alert_Dialog, Info_Icon);
         end if;
      end;

      --  Create confirm dialog
      Confirm_Dialog := Adi.Widget.Dialog.Create_Handle;
      Attach_Window (Confirm_Dialog, W);
      Adi.Widget.Dialog.Set_Part_Styles (Confirm_Dialog, Backdrop_Class_Part_Styles);
      Set_Title (Confirm_Dialog, "Confirm Action");
      Set_Message (Confirm_Dialog,
                   "Are you sure you want to proceed? "
                   & "This action cannot be undone.");
      Set_Yes_No_Cancel (Confirm_Dialog);
      Connect_Result (Confirm_Dialog, On_Confirm_Result'Unrestricted_Access);

      --  Set warning icon on confirm dialog (Material Symbols "warning" 24×24)
      declare
         Warn_Icon : constant Adi.Image.Image_Access :=
           Adi.Image.Load_SVG_Path
             (Path_Data =>
                "M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z",
              Size      => (24.0, 24.0),
              Fill      => (R => 234, G => 179, B => 8, A => 255));
      begin
         if Warn_Icon /= null then
            Set_Icon (Confirm_Dialog, Warn_Icon);
         end if;
      end;

      --  Create custom content dialog
      Custom_Dialog := Adi.Widget.Dialog.Create_Handle;
      Attach_Window (Custom_Dialog, W);
      Adi.Widget.Dialog.Set_Part_Styles (Custom_Dialog, Backdrop_Class_Part_Styles);
      Set_Title (Custom_Dialog, "Custom Content");
      Set_OK_Cancel (Custom_Dialog);
      Connect_Result (Custom_Dialog, On_Custom_Result'Unrestricted_Access);

      --  Build custom content: a box with two labels
      declare
         Content_Box : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         Detail_1 : constant Label_Handle :=
           Adi.Widget.Label.Create_Handle ("Name: John Doe");
         Detail_2 : constant Label_Handle :=
           Adi.Widget.Label.Create_Handle ("Email: john@example.com");
         Detail_3 : constant Label_Handle :=
           Adi.Widget.Label.Create_Handle ("Role: Administrator");
      begin
         Adi.Widget.Box.Set_Part_Styles (Content_Box, Custom_Content_Class_Part_Styles);
         Adi.Widget.Label.Set_Part_Styles (Detail_1, Detail_Label_Class_Part_Styles);
         Adi.Widget.Label.Set_Part_Styles (Detail_2, Detail_Label_Class_Part_Styles);
         Adi.Widget.Label.Set_Part_Styles (Detail_3, Detail_Label_Class_Part_Styles);
         Adi.Widget.Box.Add_Child (Content_Box, +Detail_1);
         Adi.Widget.Box.Add_Child (Content_Box, +Detail_2);
         Adi.Widget.Box.Add_Child (Content_Box, +Detail_3);
         Set_Content (Custom_Dialog, +Content_Box);
      end;

      --  Create delete dialog from XML-generated package
      declare
         package Delete_UI is new Delete_Dialog_UI.Instance;
      begin
         Delete_Dialog := Delete_UI.Build;
         Attach_Window (Delete_Dialog, W);
         Adi.Widget.Dialog.Set_Part_Styles (Delete_Dialog, Backdrop_Class_Part_Styles);
         Connect_Result (Delete_Dialog, On_Delete_Result'Unrestricted_Access);
      end;

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Dialog_Example;
