pragma Ada_2022;
with Adi.App;
with Adi.Image;              use Adi.Image;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Button;       use Adi.Widget.Button;
with Adi.Widget.Combo_Box;    use Adi.Widget.Combo_Box;
with Adi.Widget.Context_Menu;
with Adi.Widget.Dialog;       use Adi.Widget.Dialog;
with Adi.Widget.Label;        use Adi.Widget.Label;
with Adi.Widget.Text_Input;   use Adi.Widget.Text_Input;
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

   --  Set package-level context menu styles (applies to all context menus)
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles (Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles (Context_Menu_Item_Class_Part_Styles);

   --  Set package-level dialog styles (applies to all dialogs)
   Set_Default_Panel_Style (Dialog_Panel_Class_Part_Styles);
   Set_Default_Title_Style (Dialog_Title_Class_Part_Styles);
   Set_Default_Message_Style (Dialog_Message_Class_Part_Styles);
   Set_Default_Button_Row_Style (Dialog_Btn_Row_Class_Part_Styles);
   Set_Default_Button_Style (Dialog_Btn_Class_Part_Styles);

   W := UI.Build;

   --  Set title icon
   declare
      Icon : constant Adi.Image.Image_Access :=
        Adi.Image.Load_SVG_Path
          (Renderer  => W.Get_Renderer,
           Path_Data => Dashboard_Path,
           Size      => (24.0, 24.0),
           Fill      => (R => 208, G => 188, B => 255, A => 255));
   begin
      if Icon /= null then
         UI.App_Title.Set_Icon (Icon);
      end if;
   end;

   --  Style combo dropdown overlay
   Set_Dropdown_Part_Styles (UI.Country_Combo.all, Combo_Dropdown_Class_Part_Styles);
   Set_Option_Row_Part_Styles (UI.Country_Combo.all, Combo_Option_Class_Part_Styles);

   --  Attach text input to window (context menu styles applied via defaults)
   Attach_Window (UI.Name_Input.all, W);

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

   A.Add_Window (W);
   A.Run;
end Material_Demo;
