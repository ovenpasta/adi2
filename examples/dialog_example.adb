pragma Ada_2022;

with Adi.App;
with Adi.Image;                 use Adi.Image;
with Adi.Window;                use Adi.Window;
with Adi.Widget;                use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;          use Adi.Widget.Label;
with Adi.Widget.Button;         use Adi.Widget.Button;
with Adi.Widget.Dialog;         use Adi.Widget.Dialog;
with Dialog_Example_Styles;     use Dialog_Example_Styles;

procedure Dialog_Example is
   A : Adi.App.App;

   Status_Label : Label_Widget_Access;

   Alert_Dialog   : Dialog_Widget_Access;
   Confirm_Dialog : Dialog_Widget_Access;
   Custom_Dialog  : Dialog_Widget_Access;

   procedure On_Alert_Result
     (Dlg          : Dialog_Widget_Access;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (Dlg);
   begin
      if Status_Label /= null then
         if Button_Index = 0 then
            Set_Text (Status_Label.all, "Alert dismissed");
         else
            Set_Text (Status_Label.all,
                      "Alert: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Alert_Result;

   procedure On_Confirm_Result
     (Dlg          : Dialog_Widget_Access;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (Dlg);
   begin
      if Status_Label /= null then
         if Button_Index = 0 then
            Set_Text (Status_Label.all, "Confirm dismissed");
         else
            Set_Text (Status_Label.all,
                      "Confirm: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Confirm_Result;

   procedure On_Show_Alert (Btn : Button_Widget_Access) is
      pragma Unreferenced (Btn);
   begin
      if not Is_Shown (Alert_Dialog.all) then
         Show (Alert_Dialog.all);
      end if;
   end On_Show_Alert;

   procedure On_Show_Confirm (Btn : Button_Widget_Access) is
      pragma Unreferenced (Btn);
   begin
      if not Is_Shown (Confirm_Dialog.all) then
         Show (Confirm_Dialog.all);
      end if;
   end On_Show_Confirm;

   procedure On_Custom_Result
     (Dlg          : Dialog_Widget_Access;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (Dlg);
   begin
      if Status_Label /= null then
         if Button_Index = 0 then
            Set_Text (Status_Label.all, "Custom dismissed");
         else
            Set_Text (Status_Label.all,
                      "Custom: clicked """ & Button_Text & """");
         end if;
      end if;
   end On_Custom_Result;

   procedure On_Show_Custom (Btn : Button_Widget_Access) is
      pragma Unreferenced (Btn);
   begin
      if not Is_Shown (Custom_Dialog.all) then
         Show (Custom_Dialog.all);
      end if;
   end On_Show_Custom;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access :=
        Create_Window ("Dialog Example", (700.0, 500.0));

      Root      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title     : constant Label_Widget_Access :=
        Adi.Widget.Label.Create ("Dialog / Alert Widget");
      Hint      : constant Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Click a button to open a modal dialog. "
           & "Click the backdrop or press Escape to dismiss.");

      Alert_Btn   : constant Button_Widget_Access :=
        Adi.Widget.Button.Create ("Show Alert");
      Confirm_Btn : constant Button_Widget_Access :=
        Adi.Widget.Button.Create ("Show Confirm");
      Custom_Btn  : constant Button_Widget_Access :=
        Adi.Widget.Button.Create ("Show Custom");
   begin
      Status_Label := Adi.Widget.Label.Create ("(no dialog opened yet)");

      --  Page styles
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Container.all, Container_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Status_Label.all, Status_Class_Part_Styles);
      Set_Part_Styles (Alert_Btn.all, Btn_Primary_Class_Part_Styles);
      Set_Part_Styles (Confirm_Btn.all, Btn_Primary_Class_Part_Styles);
      Set_Part_Styles (Custom_Btn.all, Btn_Primary_Class_Part_Styles);

      --  Button callbacks
      Set_On_Clicked (Alert_Btn.all, On_Show_Alert'Unrestricted_Access);
      Set_On_Clicked (Confirm_Btn.all, On_Show_Confirm'Unrestricted_Access);
      Set_On_Clicked (Custom_Btn.all, On_Show_Custom'Unrestricted_Access);

      --  Build page
      Root.Add_Child (Container);
      Container.Add_Child (Title);
      Container.Add_Child (Hint);
      Container.Add_Child (Alert_Btn);
      Container.Add_Child (Confirm_Btn);
      Container.Add_Child (Custom_Btn);
      Container.Add_Child (Status_Label);

      --  Set package-level default styles for all dialogs
      Set_Default_Panel_Style (Panel_Class_Part_Styles);
      Set_Default_Title_Style (Dialog_Title_Class_Part_Styles);
      Set_Default_Message_Style (Dialog_Message_Class_Part_Styles);
      Set_Default_Button_Row_Style (Button_Row_Class_Part_Styles);
      Set_Default_Button_Style (Dialog_Btn_Class_Part_Styles);
      Set_Default_Primary_Button_Style (Dialog_Btn_Primary_Class_Part_Styles);

      --  Create alert dialog
      Alert_Dialog := Adi.Widget.Dialog.Create;
      Attach_Window (Alert_Dialog.all, W);
      Set_Part_Styles (Alert_Dialog.all, Backdrop_Class_Part_Styles);
      Set_Title (Alert_Dialog.all, "Information");
      Set_Message (Alert_Dialog.all,
                   "This is a simple alert dialog with a single OK button. "
                   & "You can dismiss it by clicking OK, the backdrop, or pressing Escape.");
      Set_OK_Button (Alert_Dialog.all);
      Set_On_Result (Alert_Dialog.all, On_Alert_Result'Unrestricted_Access);

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
            Set_Icon (Alert_Dialog.all, Info_Icon);
         end if;
      end;

      --  Create confirm dialog
      Confirm_Dialog := Adi.Widget.Dialog.Create;
      Attach_Window (Confirm_Dialog.all, W);
      Set_Part_Styles (Confirm_Dialog.all, Backdrop_Class_Part_Styles);
      Set_Title (Confirm_Dialog.all, "Confirm Action");
      Set_Message (Confirm_Dialog.all,
                   "Are you sure you want to proceed? "
                   & "This action cannot be undone.");
      Set_Yes_No_Cancel (Confirm_Dialog.all);
      Set_On_Result (Confirm_Dialog.all, On_Confirm_Result'Unrestricted_Access);

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
            Set_Icon (Confirm_Dialog.all, Warn_Icon);
         end if;
      end;

      --  Create custom content dialog
      Custom_Dialog := Adi.Widget.Dialog.Create;
      Attach_Window (Custom_Dialog.all, W);
      Set_Part_Styles (Custom_Dialog.all, Backdrop_Class_Part_Styles);
      Set_Title (Custom_Dialog.all, "Custom Content");
      Set_OK_Cancel (Custom_Dialog.all);
      Set_On_Result (Custom_Dialog.all, On_Custom_Result'Unrestricted_Access);

      --  Build custom content: a box with two labels
      declare
         Content_Box : constant Adi.Widget.Box.Box_Widget_Access :=
           Adi.Widget.Box.Create;
         Detail_1 : constant Label_Widget_Access :=
           Adi.Widget.Label.Create ("Name: John Doe");
         Detail_2 : constant Label_Widget_Access :=
           Adi.Widget.Label.Create ("Email: john@example.com");
         Detail_3 : constant Label_Widget_Access :=
           Adi.Widget.Label.Create ("Role: Administrator");
      begin
         Set_Part_Styles (Content_Box.all, Custom_Content_Class_Part_Styles);
         Set_Part_Styles (Detail_1.all, Detail_Label_Class_Part_Styles);
         Set_Part_Styles (Detail_2.all, Detail_Label_Class_Part_Styles);
         Set_Part_Styles (Detail_3.all, Detail_Label_Class_Part_Styles);
         Content_Box.Add_Child (Detail_1);
         Content_Box.Add_Child (Detail_2);
         Content_Box.Add_Child (Detail_3);
         Set_Content (Custom_Dialog.all, Content_Box);
      end;

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Dialog_Example;
