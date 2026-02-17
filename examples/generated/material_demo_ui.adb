--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Window; use Adi.Window;
with Material_Demo_Styles; use Material_Demo_Styles;

package body Material_Demo_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;
   use type Page_Stack.Page_Changed_Callback;
   use type Adi.Widget.Button.Toggle_Callback;
   Nav_Options_Group : aliased Nav_Options.Option_Group;

   procedure On_Page_Option_Wrapper (Value : Page) is
   begin
      if On_Page /= null then
         On_Page (Value);
      end if;
   end On_Page_Option_Wrapper;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Adi.CSS_Source.Tick (Source, Reloaded, Success);
   end Tick_Styles;

   procedure Tick_Styles_CB (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, Success : Boolean;
   begin
      Tick_Styles (Reloaded, Success);
   end Tick_Styles_CB;

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Reload_Dynamic (Source, Success);
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Window.Window_Access is
      W : constant Adi.Window.Window_Access :=
        Adi.Window.Create_Window ("Material Demo", (800.0, 600.0));
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Welcome");
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("A Material Design 3 demo built with Adi.");
      Label_3 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Edit examples/css/material_demo.css to live-reload.");
      Button_1 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create ("Get Started");
      Box_4 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_5 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_4 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Form Controls");
      Label_5 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Name");
      Label_6 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Country");
      Box_6 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Button_2 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create ("Submit");
      Button_3 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create ("Cancel");
      Box_7 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_8 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_7 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Settings");
      Box_9 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_8 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Dark Mode");
      Box_10 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_9 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Notifications");
      Switch_1 : constant Adi.Widget.Button.Switch.Switch_Widget_Access := Adi.Widget.Button.Switch.Create (True);
      Box_11 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_10 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Auto-save");
      Switch_2 : constant Adi.Widget.Button.Switch.Switch_Widget_Access := Adi.Widget.Button.Switch.Create (True);
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create;
      App_Title := Adi.Widget.Label.Create ("Material Demo");
      Nav_Bar := Adi.Widget.Box.Create;
      Btn_Home := Adi.Widget.Button.Create ("Home");
      Btn_Forms := Adi.Widget.Button.Create ("Forms");
      Btn_Settings := Adi.Widget.Button.Create ("Settings");
      Pages := Page_Stack.Create;
      Name_Input := Adi.Widget.Text_Input.Create ("");
      Country_Combo := Adi.Widget.Combo_Box.Create;
      Dark_Switch := Adi.Widget.Button.Switch.Create (True);

      --  Wire callbacks
      if On_Dark_Mode /= null then
         Dark_Switch.Set_On_Toggled (On_Dark_Mode);
      end if;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Set_Static_Entries (Source, [
         Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("app-bar", App_Bar_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("app-title", App_Title_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("nav-bar", Nav_Bar_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("nav-btn", Nav_Btn_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("pages", Pages_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("page", Page_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("card", Card_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("label-inline", Label_Inline_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("card-title", Card_Title_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("card-body", Card_Body_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("card-hint", Card_Hint_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("btn", Btn_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("btn-primary", Btn_Primary_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("field-label", Field_Label_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("text-field", Text_Field_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("combo", Combo_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("btn-row", Btn_Row_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("btn-secondary", Btn_Secondary_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("setting-row", Setting_Row_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("setting-label", Setting_Label_Class_Part_Styles),
         Adi.CSS_Source.Class_Entry ("setting-switch", Setting_Switch_Class_Part_Styles)]);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/material_demo.css", Loaded);
         if Loaded then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         else
            Mode_OK := False;
         end if;
         if not Mode_OK then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         end if;
      end;

      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Class (Source, "root", Root);
      Adi.CSS_Source.Bind_Class (Source, "app-bar", Box_1);
      Adi.CSS_Source.Bind_Class (Source, "app-title", App_Title);
      Adi.CSS_Source.Bind_Class (Source, "nav-bar", Nav_Bar);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", Btn_Home);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", Btn_Forms);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", Btn_Settings);
      Adi.CSS_Source.Bind_Class (Source, "pages", Pages);
      Adi.CSS_Source.Bind_Class (Source, "page", Box_2);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_3);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", Label_1);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-body", Label_2);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-hint", Label_3);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", Button_1);
      Adi.CSS_Source.Bind_Class (Source, "page", Box_4);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_5);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", Label_4);
      Adi.CSS_Source.Bind_Class (Source, "label-inline field-label", Label_5);
      Adi.CSS_Source.Bind_Class (Source, "text-field", Name_Input);
      Adi.CSS_Source.Bind_Class (Source, "label-inline field-label", Label_6);
      Adi.CSS_Source.Bind_Class (Source, "combo", Country_Combo);
      Adi.CSS_Source.Bind_Class (Source, "btn-row", Box_6);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", Button_2);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-secondary", Button_3);
      Adi.CSS_Source.Bind_Class (Source, "page", Box_7);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_8);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", Label_7);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", Box_9);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_8);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Dark_Switch);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", Box_10);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_9);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Switch_1);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", Box_11);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_10);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Switch_2);

      --  Build hierarchy
      Box_1.Add_Child (App_Title);
      Nav_Bar.Add_Child (Btn_Home);
      Nav_Bar.Add_Child (Btn_Forms);
      Nav_Bar.Add_Child (Btn_Settings);
      Box_3.Add_Child (Label_1);
      Box_3.Add_Child (Label_2);
      Box_3.Add_Child (Label_3);
      Box_3.Add_Child (Button_1);
      Box_2.Add_Child (Box_3);
      Country_Combo.Add_Item ("United States");
      Country_Combo.Add_Item ("United Kingdom");
      Country_Combo.Add_Item ("Germany");
      Country_Combo.Add_Item ("France");
      Country_Combo.Add_Item ("Japan");
      Box_6.Add_Child (Button_2);
      Box_6.Add_Child (Button_3);
      Box_5.Add_Child (Label_4);
      Box_5.Add_Child (Label_5);
      Box_5.Add_Child (Name_Input);
      Box_5.Add_Child (Label_6);
      Box_5.Add_Child (Country_Combo);
      Box_5.Add_Child (Box_6);
      Box_4.Add_Child (Box_5);
      Box_9.Add_Child (Label_8);
      Box_9.Add_Child (Dark_Switch);
      Box_10.Add_Child (Label_9);
      Box_10.Add_Child (Switch_1);
      Box_11.Add_Child (Label_10);
      Box_11.Add_Child (Switch_2);
      Box_8.Add_Child (Label_7);
      Box_8.Add_Child (Box_9);
      Box_8.Add_Child (Box_10);
      Box_8.Add_Child (Box_11);
      Box_7.Add_Child (Box_8);
      Pages.Add_Page (Home, Box_2);
      Pages.Add_Page (Forms, Box_4);
      Pages.Add_Page (Settings, Box_7);
      Root.Add_Child (Box_1);
      Root.Add_Child (Nav_Bar);
      Root.Add_Child (Pages);

      --  Attach combo boxes to window
      Adi.Widget.Combo_Box.Attach_Window (Country_Combo.all, W);

      --  Wire option groups
      Nav_Options_Group.Set_Button (Home, Btn_Home);
      Nav_Options_Group.Set_Button (Forms, Btn_Forms);
      Nav_Options_Group.Set_Button (Settings, Btn_Settings);
      Nav_Options_Group.Set_On_Changed (On_Page_Option_Wrapper'Unrestricted_Access);

      --  Auto-wire CSS live reload
      Adi.Window.Set_On_Tick (W.all, Tick_Styles_CB'Unrestricted_Access);

      W.Set_Root (Root);
      return W;
   end Build;

   end Instance;

end Material_Demo_UI;
