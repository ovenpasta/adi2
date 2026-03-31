pragma Ada_2022;
with Ada.Command_Line;
with Ada.Text_IO;
with Adi.App;
with Adi.Core;
with Adi.I18N;
with Adi.Image;              use Adi.Image;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;          use Adi.Widget.Box;
with Adi.Widget.Combo_Box;    use Adi.Widget.Combo_Box;
with Adi.Widget.Context_Menu;
with Adi.Widget.Dialog;       use Adi.Widget.Dialog;
with Adi.Widget.Label;
with Adi.Window;
with I18N_Example_Translations;
with Material_Demo_Light_Styles;
with Material_Demo_Styles;   use Material_Demo_Styles;
with Material_Quit_Dialog_UI;
with Material_Demo_UI;       use Material_Demo_UI;
with Material_Welcome_Dialog_UI;

procedure Material_Demo is
   A : Adi.App.App;
   package UI is new Material_Demo_UI.Instance;
   package Welcome_UI is new Material_Welcome_Dialog_UI.Instance;
   package Quit_UI is new Material_Quit_Dialog_UI.Instance;
   W : Adi.Window.Window_Handle;

   Welcome_Dialog : Adi.Widget.Dialog.Dialog_Handle;
   Quit_Dialog    : Adi.Widget.Dialog.Dialog_Handle;
   Quit_Confirmed : Boolean := False;

   procedure On_Page (Value : Page) is
   begin
      Page_Stack.Set_Active (UI.Pages, Value);
   end On_Page;

   procedure On_Dark_Mode (W : Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
      UI_OK, Welcome_OK, Quit_OK : Boolean;
      CSS_Path : constant String :=
        (if Active
         then "examples/css/material_demo.css"
         else "examples/css/material_demo_light.css");
   begin
      UI.Set_CSS_File (CSS_Path, UI_OK);
      Welcome_UI.Set_CSS_File (CSS_Path, Welcome_OK);
      Quit_UI.Set_CSS_File (CSS_Path, Quit_OK);
      Adi.Widget.Label.Set_Text
        (UI.App_Title,
         (if Active
          then Material_Demo_Styles.Var_App_Title
          else Material_Demo_Light_Styles.Var_App_Title));
   end On_Dark_Mode;

   procedure On_Get_Started (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      if not Is_Shown (Welcome_Dialog) then
         Show (Welcome_Dialog);
      end if;
   end On_Get_Started;

   procedure On_Lock_UI (W : Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
   begin
      Set_Disabled (Page_Stack."+" (UI.Pages), Active);
   end On_Lock_UI;

   procedure On_UI_Scale
     (W     : Widget_Handle;
      Value : Float)
   is
      pragma Unreferenced (W);
   begin
      Adi.Layout_Util.Set_Active_UI_Scale
        (Adi.Core.Pixel_Type (Value / 100.0));
      Mark_Dirty (+UI.Root);
   end On_UI_Scale;

   procedure On_Text_Scale
     (W     : Widget_Handle;
      Value : Float)
   is
      pragma Unreferenced (W);
   begin
      Adi.Layout_Util.Set_Active_Text_Scale
        (Adi.Core.Pixel_Type (Value / 100.0));
      Mark_Dirty (+UI.Root);
   end On_Text_Scale;

   procedure On_Welcome_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W, Button_Index, Button_Text);
   begin
      --  Navigate to the Forms page after dismissing (syncs nav buttons too)
      UI.Nav_Options_Group.Set_Selected (Forms);
   end On_Welcome_Result;

   Yes_Button_Index : Positive := Positive'Last;

   procedure On_Quit_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W, Button_Text);
   begin
      if Button_Index = Yes_Button_Index then
         Quit_Confirmed := True;
         Adi.App.Request_Quit;
      end if;
   end On_Quit_Result;

   procedure On_Close_Request
     (Win   : Adi.Window.Window_Handle;
      Allow : in out Boolean)
   is
      pragma Unreferenced (Win);
   begin
      if Quit_Confirmed then
         Allow := True;
      else
         Allow := False;
         if not Is_Shown (Quit_Dialog) then
            Show (Quit_Dialog);
         end if;
      end if;
   end On_Close_Request;

   --  Material Symbols "dashboard" icon (24×24 viewBox)
   Dashboard_Path : constant String :=
     "M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z";

begin
   --  Register translations and parse --lang argument
   I18N_Example_Translations.Register_All;
   declare
      use Ada.Command_Line;
      use Ada.Text_IO;
   begin
      for I in 1 .. Argument_Count loop
         if Argument (I) = "--lang" and then I < Argument_Count then
            Adi.I18N.Set_Language (Argument (I + 1));
         end if;
      end loop;
      Put_Line ("[i18n] Usage: material_demo --lang fr|de");
      Put_Line ("[i18n] Language: " & Adi.I18N.Get_Language);
   end;

   A.Init;
   A.Set_Target_FPS (60);
   UI.On_Page := On_Page'Unrestricted_Access;
   UI.On_Dark_Mode := On_Dark_Mode'Unrestricted_Access;
   UI.On_Get_Started := On_Get_Started'Unrestricted_Access;
   UI.On_Lock_UI := On_Lock_UI'Unrestricted_Access;
   UI.On_UI_Scale := On_UI_Scale'Unrestricted_Access;
   UI.On_Text_Scale := On_Text_Scale'Unrestricted_Access;

   --  Set package-level context menu styles (applies to all context menus)
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles (Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles (Context_Menu_Item_Class_Part_Styles);

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
         Adi.Widget.Label.Set_Icon (UI.App_Title, Icon);
      end if;
   end;

   Adi.Widget.Label.Set_Text (UI.App_Title, Var_App_Title);

   --  Create welcome dialog
   Welcome_Dialog := Welcome_UI.Build;
   Welcome_UI.Attach_Window (Welcome_Dialog, W);
   Set_Title (Welcome_Dialog, Var_Welcome_Title);
   Set_Message (Welcome_Dialog, Var_Welcome_Message);
   Connect_Result (Welcome_Dialog, On_Welcome_Result'Unrestricted_Access);

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
         Set_Icon (Welcome_Dialog, Welcome_Icon);
      end if;
   end;

   --  Create quit confirmation dialog
   Quit_Dialog := Quit_UI.Build;
   Quit_UI.Attach_Window (Quit_Dialog, W);
   Set_Title (Quit_Dialog, Var_Quit_Title);
   Set_Message (Quit_Dialog, Var_Quit_Message);
   Yes_Button_Index := 2;
   Connect_Result (Quit_Dialog, On_Quit_Result'Unrestricted_Access);

   --  Intercept window close / app quit
   Adi.Window.Connect_Close_Request
     (W, On_Close_Request'Unrestricted_Access);

   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Material_Demo;
