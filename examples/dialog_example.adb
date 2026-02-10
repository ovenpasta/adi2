pragma Ada_2022;

with Adi.App;
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
   begin
      Status_Label := Adi.Widget.Label.Create ("(no dialog opened yet)");

      --  Page styles
      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Container.all, Container_Part_Styles);
      Set_Part_Styles (Title.all, Title_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Part_Styles);
      Set_Part_Styles (Status_Label.all, Status_Part_Styles);
      Set_Part_Styles (Alert_Btn.all, Btn_Primary_Part_Styles);
      Set_Part_Styles (Confirm_Btn.all, Btn_Primary_Part_Styles);

      --  Button callbacks
      Set_On_Clicked (Alert_Btn.all, On_Show_Alert'Unrestricted_Access);
      Set_On_Clicked (Confirm_Btn.all, On_Show_Confirm'Unrestricted_Access);

      --  Build page
      Root.Add_Child (Container);
      Container.Add_Child (Title);
      Container.Add_Child (Hint);
      Container.Add_Child (Alert_Btn);
      Container.Add_Child (Confirm_Btn);
      Container.Add_Child (Status_Label);

      --  Create alert dialog
      Alert_Dialog := Adi.Widget.Dialog.Create;
      Attach_Window (Alert_Dialog.all, W);
      Set_Part_Styles (Alert_Dialog.all, Backdrop_Part_Styles);
      Set_Panel_Style (Alert_Dialog.all, Panel_Part_Styles);
      Set_Title_Style (Alert_Dialog.all, Dialog_Title_Part_Styles);
      Set_Message_Style (Alert_Dialog.all, Dialog_Message_Part_Styles);
      Set_Button_Row_Style (Alert_Dialog.all, Button_Row_Part_Styles);
      Set_Button_Style (Alert_Dialog.all, Dialog_Btn_Part_Styles);
      Set_Title (Alert_Dialog.all, "Information");
      Set_Message (Alert_Dialog.all,
                   "This is a simple alert dialog with a single OK button. "
                   & "You can dismiss it by clicking OK, the backdrop, or pressing Escape.");
      Set_OK_Button (Alert_Dialog.all);
      Set_On_Result (Alert_Dialog.all, On_Alert_Result'Unrestricted_Access);

      --  Create confirm dialog
      Confirm_Dialog := Adi.Widget.Dialog.Create;
      Attach_Window (Confirm_Dialog.all, W);
      Set_Part_Styles (Confirm_Dialog.all, Backdrop_Part_Styles);
      Set_Panel_Style (Confirm_Dialog.all, Panel_Part_Styles);
      Set_Title_Style (Confirm_Dialog.all, Dialog_Title_Part_Styles);
      Set_Message_Style (Confirm_Dialog.all, Dialog_Message_Part_Styles);
      Set_Button_Row_Style (Confirm_Dialog.all, Button_Row_Part_Styles);
      Set_Button_Style (Confirm_Dialog.all, Dialog_Btn_Part_Styles);
      Set_Title (Confirm_Dialog.all, "Confirm Action");
      Set_Message (Confirm_Dialog.all,
                   "Are you sure you want to proceed? "
                   & "This action cannot be undone.");
      Set_Yes_No_Cancel (Confirm_Dialog.all);
      Set_On_Result (Confirm_Dialog.all, On_Confirm_Result'Unrestricted_Access);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Dialog_Example;
