pragma Ada_2022;
with Adi.App;
with Adi.Image;              use Adi.Image;
with Adi.MCP;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Button;       use Adi.Widget.Button;
with Adi.Widget.Combo_Box;    use Adi.Widget.Combo_Box;
with Adi.Widget.Context_Menu;
with Adi.Widget.Dialog;       use Adi.Widget.Dialog;
with Adi.Widget.Label;        use Adi.Widget.Label;
with Adi.Window;
with Material_Demo_Styles;   use Material_Demo_Styles;
with Material_Demo_UI;       use Material_Demo_UI;

procedure Material_Demo is
   A : Adi.App.App;
   package UI is new Material_Demo_UI.Instance;
   W : Adi.Window.Window_Access;

   Welcome_Dialog : Dialog_Widget_Access;

   procedure On_Page (Value : Page) is
   begin
      UI.Pages.Set_Active (Value);
   end On_Page;

   procedure On_Dark_Mode (Btn : Button_Widget_Access; Active : Boolean) is
      pragma Unreferenced (Btn);
      OK : Boolean;
   begin
      UI.Set_CSS_File ((if Active
                        then "examples/css/material_demo.css"
                        else "examples/css/material_demo_light.css"), OK);
   end On_Dark_Mode;

   procedure On_Get_Started (Btn : Button_Widget_Access) is
      pragma Unreferenced (Btn);
   begin
      if not Is_Shown (Welcome_Dialog.all) then
         Show (Welcome_Dialog.all);
      end if;
   end On_Get_Started;

   procedure On_Lock_UI (Btn : Button_Widget_Access; Active : Boolean) is
      pragma Unreferenced (Btn);
   begin
      Set_Disabled (UI.Pages.all, Active);
   end On_Lock_UI;

   procedure On_Welcome_Result
     (Dlg          : Dialog_Widget_Access;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (Dlg, Button_Index, Button_Text);
   begin
      --  Navigate to the Forms page after dismissing (syncs nav buttons too)
      UI.Nav_Options_Group.Set_Selected (Forms);
   end On_Welcome_Result;

   --  Material Symbols "dashboard" icon (24×24 viewBox)
   Dashboard_Path : constant String :=
     "M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z";

begin
   A.Init;
   A.Set_Target_FPS (60);
   UI.On_Page := On_Page'Unrestricted_Access;
   UI.On_Dark_Mode := On_Dark_Mode'Unrestricted_Access;
   UI.On_Get_Started := On_Get_Started'Unrestricted_Access;
   UI.On_Lock_UI := On_Lock_UI'Unrestricted_Access;

   --  Set package-level context menu styles (applies to all context menus)
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles (Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles (Context_Menu_Item_Class_Part_Styles);

   --  Set package-level dialog styles (applies to all dialogs)
   Set_Default_Panel_Style (Dialog_Panel_Class_Part_Styles);
   Set_Default_Title_Style (Dialog_Title_Class_Part_Styles);
   Set_Default_Message_Style (Dialog_Message_Class_Part_Styles);
   Set_Default_Button_Row_Style (Dialog_Btn_Row_Class_Part_Styles);
   Set_Default_Button_Style (Dialog_Btn_Class_Part_Styles);

   --  Set package-level combo box styles (applies to all combo boxes)
   Set_Default_Dropdown_Styles (Combo_Dropdown_Class_Part_Styles);
   Set_Default_Option_Row_Styles (Combo_Option_Class_Part_Styles);

   W := UI.Build;

   --  Enable MCP introspection (development builds only)
   Adi.MCP.Initialize (W);

   --  Set title icon
   declare
      Icon : constant Adi.Image.Image_Access :=
        Adi.Image.Load_SVG_Path
          (Path_Data => Dashboard_Path,
           Size      => (24.0, 24.0),
           Fill      => (R => 208, G => 188, B => 255, A => 255));
   begin
      if Icon /= null then
         UI.App_Title.Set_Icon (Icon);
      end if;
   end;

   --  Create welcome dialog (inherits default dialog styles)
   Welcome_Dialog := Adi.Widget.Dialog.Create;
   Attach_Window (Welcome_Dialog.all, W);
   Set_Part_Styles (Welcome_Dialog.all, Dialog_Backdrop_Class_Part_Styles);
   Set_Title (Welcome_Dialog.all, "Welcome!");
   Set_Message (Welcome_Dialog.all,
                "Thanks for trying the Material Demo. " &
                "Click OK to explore the Forms page, " &
                "or dismiss to stay on Home.");
   Set_OK_Button (Welcome_Dialog.all);
   Set_On_Result (Welcome_Dialog.all, On_Welcome_Result'Unrestricted_Access);

   --  Set welcome icon (Material Symbols "waving_hand" 24×24)
   declare
      Welcome_Icon : constant Adi.Image.Image_Access :=
        Adi.Image.Load_SVG_Path
          (Path_Data =>
             "M7.03 4.95L3.49 8.49c-3.32 3.32-3.32 8.7 0 12.02s8.7 3.32 "
             & "12.02 0l6.01-6.01a2.517 2.517 0 00-.39-3.86l.71-.71c.39-.39.39-1.02 "
             & "0-1.41a.9959.9959 0 00-1.41 0l-2.12 2.12a1.492 1.492 0 00-1.78.21 "
             & "1.492 1.492 0 00-.21 1.78l-2.12 2.12c-.39.39-1.02.39-1.41 "
             & "0s-.39-1.02 0-1.41l4.24-4.24c.39-.39.39-1.02 0-1.41s-1.02-.39-1.41 "
             & "0L11.38 12a1.492 1.492 0 00-1.78.21c-.58.58-.58 1.52 0 "
             & "2.12l-1.41 1.41c-.39.39-1.02.39-1.41 0s-.39-1.02 0-1.41l4.24-4.24 "
             & "1.41-1.41c.39-.39.39-1.02 0-1.41s-1.02-.39-1.41 0l-1.41 1.41a1.492 "
             & "1.492 0 00-1.78.21c-.58.58-.58 1.52 0 2.12L5.62 12.7c-.39.39-1.02.39-1.41 "
             & "0s-.39-1.02 0-1.41l3.54-3.54c.39-.39.39-1.02 0-1.41a.9846.9846 0 00-1.38.02 "
             & "1.49 1.49 0 00-.34-.41z",
           Size      => (24.0, 24.0),
           Fill      => (R => 208, G => 188, B => 255, A => 255));
   begin
      if Welcome_Icon /= null then
         Set_Icon (Welcome_Dialog.all, Welcome_Icon);
      end if;
   end;

   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Material_Demo;
