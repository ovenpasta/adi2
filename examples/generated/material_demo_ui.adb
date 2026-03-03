--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.I18N; use Adi.I18N;
with Adi.Widget; use Adi.Widget;
with Adi.Window; use Adi.Window;
with Material_Demo_Styles; use Material_Demo_Styles;

package body Material_Demo_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;
   use type Page_Stack.Page_Changed_Callback;
   use type Adi.Widget.Button.Toggle_Callback;
   use type Adi.Widget.Button.Click_Callback;
   use type Adi.Widget.Button.Toggle_Callback;

   procedure On_Page_Option_Wrapper (Value : Page) is
   begin
      if On_Page /= null then
         On_Page (Value);
      end if;
   end On_Page_Option_Wrapper;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
      declare
         Local_Reloaded : Boolean := False;
         Local_Success  : Boolean := True;
      begin
         Adi.CSS_Source.Tick (Source, Local_Reloaded, Local_Success);
         Reloaded := Reloaded or Local_Reloaded;
         Success := Success and Local_Success;
      end;
   end Tick_Styles;

   procedure Tick_Styles_CB (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, Success : Boolean;
   begin
      Tick_Styles (Reloaded, Success);
   end Tick_Styles_CB;

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
      Mode_OK : Boolean;
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Window.Window_Access is
      W : constant Adi.Window.Window_Access :=
        Adi.Window.Create_Window ("Material Demo", (800.0, 600.0));
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Welcome"));
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("A Material Design 3 demo built with Adi."));
      Label_3 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Edit examples/css/material_demo.css to live-reload."));
      Button_1 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create (Adi.I18N.T ("Get Started"));
      Box_4 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_5 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_4 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Form Controls"));
      Label_5 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Country"));
      Box_6 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Button_2 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create (Adi.I18N.T ("Submit"));
      Button_3 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create (Adi.I18N.T ("Cancel"));
      Box_7 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_8 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_6 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Enabled vs Disabled"));
      Box_9 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_7 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("");
      Label_8 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Enabled"));
      Label_9 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Disabled"));
      Label_10 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Button"));
      Button_4 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create (Adi.I18N.T ("Click Me"));
      Button_5 : constant Adi.Widget.Button.Button_Widget_Access := Adi.Widget.Button.Create (Adi.I18N.T ("Click Me"));
      Label_11 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Text Input"));
      Label_12 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Switch"));
      Switch_1 : constant Adi.Widget.Button.Switch.Switch_Widget_Access := Adi.Widget.Button.Switch.Create (True);
      Switch_2 : constant Adi.Widget.Button.Switch.Switch_Widget_Access := Adi.Widget.Button.Switch.Create (True);
      Label_13 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Combo Box"));
      Label_14 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Slider"));
      Label_15 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Value Input"));
      Box_10 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_11 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_16 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Settings"));
      Box_12 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_17 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Dark Mode"));
      Box_13 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_18 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Notifications"));
      Switch_3 : constant Adi.Widget.Button.Switch.Switch_Widget_Access := Adi.Widget.Button.Switch.Create (True);
      Box_14 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_19 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Auto-save"));
      Switch_4 : constant Adi.Widget.Button.Switch.Switch_Widget_Access := Adi.Widget.Button.Switch.Create (True);
      Label_20 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Adi.I18N.T ("Lock UI"));
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create;
      App_Title := Adi.Widget.Label.Create (Adi.I18N.T ("Material Demo"));
      Nav_Bar := Adi.Widget.Box.Create;
      Btn_Home := Adi.Widget.Button.Create (Adi.I18N.T ("Home"));
      Btn_Forms := Adi.Widget.Button.Create (Adi.I18N.T ("Forms"));
      Btn_Settings := Adi.Widget.Button.Create (Adi.I18N.T ("Settings"));
      Btn_Controls := Adi.Widget.Button.Create (Adi.I18N.T ("Controls"));
      Pages := Page_Stack.Create;
      Name_Input := Adi.Widget.Text_Input.Create ("");
      Country_Combo := Adi.Widget.Combo_Box.Create;
      Enabled_Input := Adi.Widget.Text_Input.Create (Adi.I18N.T ("Editable"));
      Disabled_Input := Adi.Widget.Text_Input.Create (Adi.I18N.T ("Read-only"));
      Enabled_Combo := Adi.Widget.Combo_Box.Create;
      Disabled_Combo := Adi.Widget.Combo_Box.Create;
      Enabled_Slider := Float_Slider.Create (Min => 0.0, Max => 100.0, Value => 50.0);
      Disabled_Slider := Float_Slider.Create (Min => 0.0, Max => 100.0, Value => 75.0);
      Enabled_Value_Input := Float_Value_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
      Disabled_Value_Input := Int_Value_Input.Create (Min => 0, Max => 100, Value => 75);
      Dark_Switch := Adi.Widget.Button.Switch.Create (True);
      Lock_Bar := Adi.Widget.Box.Create;
      Lock_Switch := Adi.Widget.Button.Switch.Create (False);

      --  Configure properties
      Button_5.Set_Disabled;
      Disabled_Input.Set_Disabled;
      Switch_2.Set_Disabled;
      Disabled_Combo.Set_Disabled;
      Disabled_Slider.Set_Disabled;
      Disabled_Value_Input.Set_Disabled;

      --  Set labels
      Adi.Widget.Set_Label (Name_Input.all, Adi.I18N.T ("Name"));

      --  Wire callbacks
      if On_Get_Started /= null then
         Button_1.Connect_Clicked (On_Get_Started);
      end if;
      if On_Dark_Mode /= null then
         Dark_Switch.Connect_Toggled (On_Dark_Mode);
      end if;
      if On_Lock_UI /= null then
         Lock_Switch.Connect_Toggled (On_Lock_UI);
      end if;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("app-bar", App_Bar_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("app-title", App_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("nav-bar", Nav_Bar_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("nav-btn", Nav_Btn_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("pages", Pages_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page", Page_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card", Card_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("label-inline", Label_Inline_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card-title", Card_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card-body", Card_Body_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card-hint", Card_Hint_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("btn", Btn_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("btn-primary", Btn_Primary_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("text-field", Text_Field_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("field-label", Field_Label_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("combo", Combo_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("btn-row", Btn_Row_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("btn-secondary", Btn_Secondary_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("control-grid", Control_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("grid-header", Grid_Header_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("grid-label", Grid_Label_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("grid-cell", Grid_Cell_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("setting-switch", Setting_Switch_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("slider", Slider_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("num-field", Num_Field_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("setting-row", Setting_Row_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("setting-label", Setting_Label_Class_Part_Styles));

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
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", Btn_Controls);
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
      Adi.CSS_Source.Bind_Class (Source, "text-field", Name_Input);
      Adi.CSS_Source.Bind_Class (Source, "label-inline field-label", Label_5);
      Adi.CSS_Source.Bind_Class (Source, "combo", Country_Combo);
      Adi.CSS_Source.Bind_Class (Source, "btn-row", Box_6);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", Button_2);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-secondary", Button_3);
      Adi.CSS_Source.Bind_Class (Source, "page", Box_7);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_8);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", Label_6);
      Adi.CSS_Source.Bind_Class (Source, "control-grid", Box_9);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-header", Label_7);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-header", Label_8);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-header", Label_9);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", Label_10);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary grid-cell", Button_4);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary grid-cell", Button_5);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", Label_11);
      Adi.CSS_Source.Bind_Class (Source, "text-field grid-cell", Enabled_Input);
      Adi.CSS_Source.Bind_Class (Source, "text-field grid-cell", Disabled_Input);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", Label_12);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch grid-cell", Switch_1);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch grid-cell", Switch_2);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", Label_13);
      Adi.CSS_Source.Bind_Class (Source, "combo grid-cell", Enabled_Combo);
      Adi.CSS_Source.Bind_Class (Source, "combo grid-cell", Disabled_Combo);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", Label_14);
      Adi.CSS_Source.Bind_Class (Source, "slider grid-cell", Enabled_Slider);
      Adi.CSS_Source.Bind_Class (Source, "slider grid-cell", Disabled_Slider);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", Label_15);
      Adi.CSS_Source.Bind_Class (Source, "num-field grid-cell", Enabled_Value_Input);
      Adi.CSS_Source.Bind_Class (Source, "num-field grid-cell", Disabled_Value_Input);
      Adi.CSS_Source.Bind_Class (Source, "page", Box_10);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_11);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", Label_16);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", Box_12);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_17);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Dark_Switch);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", Box_13);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_18);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Switch_3);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", Box_14);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_19);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Switch_4);
      Adi.CSS_Source.Bind_Class (Source, "nav-bar setting-row", Lock_Bar);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", Label_20);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", Lock_Switch);

      --  Build hierarchy
      Box_1.Add_Child (App_Title);
      Nav_Bar.Add_Child (Btn_Home);
      Nav_Bar.Add_Child (Btn_Forms);
      Nav_Bar.Add_Child (Btn_Settings);
      Nav_Bar.Add_Child (Btn_Controls);
      Box_3.Add_Child (Label_1);
      Box_3.Add_Child (Label_2);
      Box_3.Add_Child (Label_3);
      Box_3.Add_Child (Button_1);
      Box_2.Add_Child (Box_3);
      Country_Combo.Add_Item (Adi.I18N.T ("United States"));
      Country_Combo.Add_Item (Adi.I18N.T ("United Kingdom"));
      Country_Combo.Add_Item (Adi.I18N.T ("Germany"));
      Country_Combo.Add_Item (Adi.I18N.T ("France"));
      Country_Combo.Add_Item (Adi.I18N.T ("Japan"));
      Box_6.Add_Child (Button_2);
      Box_6.Add_Child (Button_3);
      Box_5.Add_Child (Label_4);
      Box_5.Add_Child (Name_Input);
      Box_5.Add_Child (Label_5);
      Box_5.Add_Child (Country_Combo);
      Box_5.Add_Child (Box_6);
      Box_4.Add_Child (Box_5);
      Enabled_Combo.Add_Item (Adi.I18N.T ("Enabled"));
      Disabled_Combo.Add_Item (Adi.I18N.T ("Disabled"));
      Box_9.Add_Child (Label_7);
      Box_9.Add_Child (Label_8);
      Box_9.Add_Child (Label_9);
      Box_9.Add_Child (Label_10);
      Box_9.Add_Child (Button_4);
      Box_9.Add_Child (Button_5);
      Box_9.Add_Child (Label_11);
      Box_9.Add_Child (Enabled_Input);
      Box_9.Add_Child (Disabled_Input);
      Box_9.Add_Child (Label_12);
      Box_9.Add_Child (Switch_1);
      Box_9.Add_Child (Switch_2);
      Box_9.Add_Child (Label_13);
      Box_9.Add_Child (Enabled_Combo);
      Box_9.Add_Child (Disabled_Combo);
      Box_9.Add_Child (Label_14);
      Box_9.Add_Child (Enabled_Slider);
      Box_9.Add_Child (Disabled_Slider);
      Box_9.Add_Child (Label_15);
      Box_9.Add_Child (Enabled_Value_Input);
      Box_9.Add_Child (Disabled_Value_Input);
      Box_8.Add_Child (Label_6);
      Box_8.Add_Child (Box_9);
      Box_7.Add_Child (Box_8);
      Box_12.Add_Child (Label_17);
      Box_12.Add_Child (Dark_Switch);
      Box_13.Add_Child (Label_18);
      Box_13.Add_Child (Switch_3);
      Box_14.Add_Child (Label_19);
      Box_14.Add_Child (Switch_4);
      Box_11.Add_Child (Label_16);
      Box_11.Add_Child (Box_12);
      Box_11.Add_Child (Box_13);
      Box_11.Add_Child (Box_14);
      Box_10.Add_Child (Box_11);
      Pages.Add_Page (Home, Box_2);
      Pages.Add_Page (Forms, Box_4);
      Pages.Add_Page (Controls, Box_7);
      Pages.Add_Page (Settings, Box_10);
      Lock_Bar.Add_Child (Label_20);
      Lock_Bar.Add_Child (Lock_Switch);
      Root.Add_Child (Box_1);
      Root.Add_Child (Nav_Bar);
      Root.Add_Child (Pages);
      Root.Add_Child (Lock_Bar);

      --  Wire option groups
      Nav_Options_Group.Set_Button (Home, Btn_Home);
      Nav_Options_Group.Set_Button (Forms, Btn_Forms);
      Nav_Options_Group.Set_Button (Settings, Btn_Settings);
      Nav_Options_Group.Set_Button (Controls, Btn_Controls);
      Nav_Options_Group.Disconnect_Changed (Nav_Options_Group_Conn);
      Nav_Options_Group_Conn := Nav_Options_Group.Connect_Changed (On_Page_Option_Wrapper'Unrestricted_Access);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W.all, Tick_Styles_CB'Unrestricted_Access);

      W.Set_Root (Root);
      return W;
   end Build;

   end Instance;

end Material_Demo_UI;
