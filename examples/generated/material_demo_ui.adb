--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Switch; use Adi.Widget.Button.Switch;
with Adi.Widget.Combo_Box; use Adi.Widget.Combo_Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Widget.Text_Input; use Adi.Widget.Text_Input;
with Material_Demo_Styles; use Material_Demo_Styles;

package body Material_Demo_UI is

   package body Instance is
   use Float_Slider;
   use Float_Value_Input;
   use Int_Value_Input;
   use Page_Stack;
   Source : aliased Adi.CSS_Source.Style_Source;

   function Merge_Metadata
     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)
      return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;
   begin
      if Override.Has_Root_Style then
         if Result.Has_Root_Style then
            Result.Root_Styles :=
              Merge_Part_Styles (Result.Root_Styles, Override.Root_Styles);
         else
            Result.Root_Styles := Override.Root_Styles;
            Result.Has_Root_Style := True;
         end if;
      end if;
      if Override.Has_Root_Font_Size then
         Result.Has_Root_Font_Size := True;
         Result.Root_Font_Size := Override.Root_Font_Size;
      end if;
      return Result;
   end Merge_Metadata;

   function Static_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := (others => <>);
   begin
      Result := Merge_Metadata (Result, Material_Demo_Styles.Root_Metadata);
      return Result;
   end Static_Root_Metadata;
   use type Float_Slider.Value_Changed_Callback;

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

   procedure Register_Root_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("root", Root_Class_Part_Styles));
   end Register_Root_Styles;

   procedure Register_App_Bar_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("app-bar", App_Bar_Class_Part_Styles));
   end Register_App_Bar_Styles;

   procedure Register_App_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("app-title", App_Title_Class_Part_Styles));
   end Register_App_Title_Styles;

   procedure Register_Nav_Bar_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("nav-bar", Nav_Bar_Class_Part_Styles));
   end Register_Nav_Bar_Styles;

   procedure Register_Nav_Btn_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("nav-btn", Nav_Btn_Class_Part_Styles));
   end Register_Nav_Btn_Styles;

   procedure Register_Pages_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("pages", Pages_Class_Part_Styles));
   end Register_Pages_Styles;

   procedure Register_Page_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("page", Page_Class_Part_Styles));
   end Register_Page_Styles;

   procedure Register_Card_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card", Card_Class_Part_Styles));
   end Register_Card_Styles;

   procedure Register_Label_Inline_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("label-inline", Label_Inline_Class_Part_Styles));
   end Register_Label_Inline_Styles;

   procedure Register_Card_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card-title", Card_Title_Class_Part_Styles));
   end Register_Card_Title_Styles;

   procedure Register_Card_Body_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card-body", Card_Body_Class_Part_Styles));
   end Register_Card_Body_Styles;

   procedure Register_Card_Hint_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card-hint", Card_Hint_Class_Part_Styles));
   end Register_Card_Hint_Styles;

   procedure Register_Btn_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("btn", Btn_Class_Part_Styles));
   end Register_Btn_Styles;

   procedure Register_Btn_Primary_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("btn-primary", Btn_Primary_Class_Part_Styles));
   end Register_Btn_Primary_Styles;

   procedure Register_Text_Field_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("text-field", Text_Field_Class_Part_Styles));
   end Register_Text_Field_Styles;

   procedure Register_Field_Label_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("field-label", Field_Label_Class_Part_Styles));
   end Register_Field_Label_Styles;

   procedure Register_Combo_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("combo", Combo_Class_Part_Styles));
   end Register_Combo_Styles;

   procedure Register_Btn_Row_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("btn-row", Btn_Row_Class_Part_Styles));
   end Register_Btn_Row_Styles;

   procedure Register_Btn_Secondary_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("btn-secondary", Btn_Secondary_Class_Part_Styles));
   end Register_Btn_Secondary_Styles;

   procedure Register_Control_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("control-grid", Control_Grid_Class_Part_Styles));
   end Register_Control_Grid_Styles;

   procedure Register_Grid_Header_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grid-header", Grid_Header_Class_Part_Styles));
   end Register_Grid_Header_Styles;

   procedure Register_Grid_Label_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grid-label", Grid_Label_Class_Part_Styles));
   end Register_Grid_Label_Styles;

   procedure Register_Grid_Cell_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grid-cell", Grid_Cell_Class_Part_Styles));
   end Register_Grid_Cell_Styles;

   procedure Register_Setting_Switch_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("setting-switch", Setting_Switch_Class_Part_Styles));
   end Register_Setting_Switch_Styles;

   procedure Register_Slider_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("slider", Slider_Class_Part_Styles));
   end Register_Slider_Styles;

   procedure Register_Grid_Slider_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grid-slider", Grid_Slider_Class_Part_Styles));
   end Register_Grid_Slider_Styles;

   procedure Register_Num_Field_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("num-field", Num_Field_Class_Part_Styles));
   end Register_Num_Field_Styles;

   procedure Register_Setting_Row_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("setting-row", Setting_Row_Class_Part_Styles));
   end Register_Setting_Row_Styles;

   procedure Register_Setting_Label_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("setting-label", Setting_Label_Class_Part_Styles));
   end Register_Setting_Label_Styles;

   procedure Register_Lock_Bar_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("lock-bar", Lock_Bar_Class_Part_Styles));
   end Register_Lock_Bar_Styles;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Material Demo", (800.0, 600.0));
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Welcome");
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A Material Design 3 demo built with Adi.");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Edit examples/css/material_demo.css to live-reload.");
      Button_1 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Get Started");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Form Controls");
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Country");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_2 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Submit");
      Button_3 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Cancel");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Enabled vs Disabled");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Enabled");
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Disabled");
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Button");
      Button_4 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Click Me");
      Button_5 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Click Me");
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Text Input");
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Switch");
      Switch_1 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Switch_2 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Combo Box");
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Slider");
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Value Input");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Settings");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Dark Mode");
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("UI Scale");
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Text Scale");
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Notifications");
      Switch_3 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Auto-save");
      Switch_4 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Label_22 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Lock UI");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;
      App_Title := Adi.Widget.Label.Create_Handle ("Material Demo");
      Nav_Bar := Adi.Widget.Box.Create_Handle;
      Btn_Home := Adi.Widget.Button.Create_Handle ("Home");
      Btn_Forms := Adi.Widget.Button.Create_Handle ("Forms");
      Btn_Settings := Adi.Widget.Button.Create_Handle ("Settings");
      Btn_Controls := Adi.Widget.Button.Create_Handle ("Controls");
      Pages := Page_Stack.Create_Handle;
      Name_Input := Adi.Widget.Text_Input.Create_Handle ("", "Name");
      Country_Combo := Adi.Widget.Combo_Box.Create_Handle;
      Enabled_Input := Adi.Widget.Text_Input.Create_Handle ("Editable", "");
      Disabled_Input := Adi.Widget.Text_Input.Create_Handle ("Read-only", "");
      Enabled_Combo := Adi.Widget.Combo_Box.Create_Handle;
      Disabled_Combo := Adi.Widget.Combo_Box.Create_Handle;
      Enabled_Slider := Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 50.0);
      Disabled_Slider := Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 75.0);
      Enabled_Value_Input := Float_Value_Input.Create_Handle (Min => 0.0, Max => 100.0, Value => 50.0);
      Disabled_Value_Input := Int_Value_Input.Create_Handle (Min => 0, Max => 100, Value => 75);
      Dark_Switch := Adi.Widget.Button.Switch.Create_Handle (True);
      UI_Scale_Slider := Float_Slider.Create_Handle (Min => 80.0, Max => 160.0, Value => 100.0);
      Text_Scale_Slider := Float_Slider.Create_Handle (Min => 80.0, Max => 160.0, Value => 100.0);
      Lock_Bar := Adi.Widget.Box.Create_Handle;
      Lock_Switch := Adi.Widget.Button.Switch.Create_Handle (False);

      --  Configure properties
      Adi.Widget.Set_Disabled (+Button_5);
      Adi.Widget.Set_Disabled (+Disabled_Input);
      Adi.Widget.Set_Disabled (+Switch_2);
      Adi.Widget.Set_Disabled (+Disabled_Combo);
      Adi.Widget.Set_Disabled (+Disabled_Slider);
      Adi.Widget.Set_Disabled (+Disabled_Value_Input);

      --  Set labels
      Adi.Widget.Set_Label (+Name_Input, "Name");

      --  Wire callbacks
      if On_Get_Started /= null then
         Adi.Widget.Button.Connect_Clicked (Button_1, On_Get_Started);
      end if;
      if On_Dark_Mode /= null then
         Adi.Widget.Button.Switch.Connect_Toggled (Dark_Switch, On_Dark_Mode);
      end if;
      if On_UI_Scale /= null then
         Float_Slider.Connect_Changed (UI_Scale_Slider, On_UI_Scale);
      end if;
      if On_Text_Scale /= null then
         Float_Slider.Connect_Changed (Text_Scale_Slider, On_Text_Scale);
      end if;
      if On_Lock_UI /= null then
         Adi.Widget.Button.Switch.Connect_Toggled (Lock_Switch, On_Lock_UI);
      end if;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Register_Root_Styles (Source);
      Register_App_Bar_Styles (Source);
      Register_App_Title_Styles (Source);
      Register_Nav_Bar_Styles (Source);
      Register_Nav_Btn_Styles (Source);
      Register_Pages_Styles (Source);
      Register_Page_Styles (Source);
      Register_Card_Styles (Source);
      Register_Label_Inline_Styles (Source);
      Register_Card_Title_Styles (Source);
      Register_Card_Body_Styles (Source);
      Register_Card_Hint_Styles (Source);
      Register_Btn_Styles (Source);
      Register_Btn_Primary_Styles (Source);
      Register_Text_Field_Styles (Source);
      Register_Field_Label_Styles (Source);
      Register_Combo_Styles (Source);
      Register_Btn_Row_Styles (Source);
      Register_Btn_Secondary_Styles (Source);
      Register_Control_Grid_Styles (Source);
      Register_Grid_Header_Styles (Source);
      Register_Grid_Label_Styles (Source);
      Register_Grid_Cell_Styles (Source);
      Register_Setting_Switch_Styles (Source);
      Register_Slider_Styles (Source);
      Register_Grid_Slider_Styles (Source);
      Register_Num_Field_Styles (Source);
      Register_Setting_Row_Styles (Source);
      Register_Setting_Label_Styles (Source);
      Register_Lock_Bar_Styles (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

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

      Adi.CSS_Source.Attach_Window (Source, W);
      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);
      Adi.CSS_Source.Bind_Class (Source, "root", +Root);
      Adi.CSS_Source.Bind_Class (Source, "app-bar", +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "app-title", +App_Title);
      Adi.CSS_Source.Bind_Class (Source, "nav-bar", +Nav_Bar);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", +Btn_Home);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", +Btn_Forms);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", +Btn_Settings);
      Adi.CSS_Source.Bind_Class (Source, "nav-btn", +Btn_Controls);
      Adi.CSS_Source.Bind_Class (Source, "pages", +Pages);
      Adi.CSS_Source.Bind_Class (Source, "page", +Box_2);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_3);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", +Label_1);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-body", +Label_2);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-hint", +Label_3);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", +Button_1);
      Adi.CSS_Source.Bind_Class (Source, "page", +Box_4);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_5);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", +Label_4);
      Adi.CSS_Source.Bind_Class (Source, "text-field", +Name_Input);
      Adi.CSS_Source.Bind_Class (Source, "label-inline field-label", +Label_5);
      Adi.CSS_Source.Bind_Class (Source, "combo", +Country_Combo);
      Adi.CSS_Source.Bind_Class (Source, "btn-row", +Box_6);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", +Button_2);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-secondary", +Button_3);
      Adi.CSS_Source.Bind_Class (Source, "page", +Box_7);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_8);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", +Label_6);
      Adi.CSS_Source.Bind_Class (Source, "control-grid", +Box_9);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-header", +Label_7);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-header", +Label_8);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-header", +Label_9);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", +Label_10);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary grid-cell", +Button_4);
      Adi.CSS_Source.Bind_Class (Source, "btn btn-primary grid-cell", +Button_5);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", +Label_11);
      Adi.CSS_Source.Bind_Class (Source, "text-field grid-cell", +Enabled_Input);
      Adi.CSS_Source.Bind_Class (Source, "text-field grid-cell", +Disabled_Input);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", +Label_12);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch grid-cell", +Switch_1);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch grid-cell", +Switch_2);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", +Label_13);
      Adi.CSS_Source.Bind_Class (Source, "combo grid-cell", +Enabled_Combo);
      Adi.CSS_Source.Bind_Class (Source, "combo grid-cell", +Disabled_Combo);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", +Label_14);
      Adi.CSS_Source.Bind_Class (Source, "slider grid-cell grid-slider", +Enabled_Slider);
      Adi.CSS_Source.Bind_Class (Source, "slider grid-cell grid-slider", +Disabled_Slider);
      Adi.CSS_Source.Bind_Class (Source, "label-inline grid-label", +Label_15);
      Adi.CSS_Source.Bind_Class (Source, "num-field grid-cell", +Enabled_Value_Input);
      Adi.CSS_Source.Bind_Class (Source, "num-field grid-cell", +Disabled_Value_Input);
      Adi.CSS_Source.Bind_Class (Source, "page", +Box_10);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_11);
      Adi.CSS_Source.Bind_Class (Source, "label-inline card-title", +Label_16);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", +Box_12);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", +Label_17);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", +Dark_Switch);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", +Box_13);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", +Label_18);
      Adi.CSS_Source.Bind_Class (Source, "slider", +UI_Scale_Slider);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", +Box_14);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", +Label_19);
      Adi.CSS_Source.Bind_Class (Source, "slider", +Text_Scale_Slider);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", +Box_15);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", +Label_20);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", +Switch_3);
      Adi.CSS_Source.Bind_Class (Source, "setting-row", +Box_16);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", +Label_21);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", +Switch_4);
      Adi.CSS_Source.Bind_Class (Source, "nav-bar setting-row lock-bar", +Lock_Bar);
      Adi.CSS_Source.Bind_Class (Source, "label-inline setting-label", +Label_22);
      Adi.CSS_Source.Bind_Class (Source, "setting-switch", +Lock_Switch);

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_1, +App_Title);
      Adi.Widget.Add_Child (+Nav_Bar, +Btn_Home);
      Adi.Widget.Add_Child (+Nav_Bar, +Btn_Forms);
      Adi.Widget.Add_Child (+Nav_Bar, +Btn_Settings);
      Adi.Widget.Add_Child (+Nav_Bar, +Btn_Controls);
      Adi.Widget.Add_Child (+Box_3, +Label_1);
      Adi.Widget.Add_Child (+Box_3, +Label_2);
      Adi.Widget.Add_Child (+Box_3, +Label_3);
      Adi.Widget.Add_Child (+Box_3, +Button_1);
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, "United States");
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, "United Kingdom");
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, "Germany");
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, "France");
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, "Japan");
      Adi.Widget.Add_Child (+Box_6, +Button_2);
      Adi.Widget.Add_Child (+Box_6, +Button_3);
      Adi.Widget.Add_Child (+Box_5, +Label_4);
      Adi.Widget.Add_Child (+Box_5, +Name_Input);
      Adi.Widget.Add_Child (+Box_5, +Label_5);
      Adi.Widget.Add_Child (+Box_5, +Country_Combo);
      Adi.Widget.Add_Child (+Box_5, +Box_6);
      Adi.Widget.Add_Child (+Box_4, +Box_5);
      Adi.Widget.Combo_Box.Add_Item (Enabled_Combo, "Enabled");
      Adi.Widget.Combo_Box.Add_Item (Disabled_Combo, "Disabled");
      Adi.Widget.Add_Child (+Box_9, +Label_7);
      Adi.Widget.Add_Child (+Box_9, +Label_8);
      Adi.Widget.Add_Child (+Box_9, +Label_9);
      Adi.Widget.Add_Child (+Box_9, +Label_10);
      Adi.Widget.Add_Child (+Box_9, +Button_4);
      Adi.Widget.Add_Child (+Box_9, +Button_5);
      Adi.Widget.Add_Child (+Box_9, +Label_11);
      Adi.Widget.Add_Child (+Box_9, +Enabled_Input);
      Adi.Widget.Add_Child (+Box_9, +Disabled_Input);
      Adi.Widget.Add_Child (+Box_9, +Label_12);
      Adi.Widget.Add_Child (+Box_9, +Switch_1);
      Adi.Widget.Add_Child (+Box_9, +Switch_2);
      Adi.Widget.Add_Child (+Box_9, +Label_13);
      Adi.Widget.Add_Child (+Box_9, +Enabled_Combo);
      Adi.Widget.Add_Child (+Box_9, +Disabled_Combo);
      Adi.Widget.Add_Child (+Box_9, +Label_14);
      Adi.Widget.Add_Child (+Box_9, +Enabled_Slider);
      Adi.Widget.Add_Child (+Box_9, +Disabled_Slider);
      Adi.Widget.Add_Child (+Box_9, +Label_15);
      Adi.Widget.Add_Child (+Box_9, +Enabled_Value_Input);
      Adi.Widget.Add_Child (+Box_9, +Disabled_Value_Input);
      Adi.Widget.Add_Child (+Box_8, +Label_6);
      Adi.Widget.Add_Child (+Box_8, +Box_9);
      Adi.Widget.Add_Child (+Box_7, +Box_8);
      Adi.Widget.Add_Child (+Box_12, +Label_17);
      Adi.Widget.Add_Child (+Box_12, +Dark_Switch);
      Adi.Widget.Add_Child (+Box_13, +Label_18);
      Adi.Widget.Add_Child (+Box_13, +UI_Scale_Slider);
      Adi.Widget.Add_Child (+Box_14, +Label_19);
      Adi.Widget.Add_Child (+Box_14, +Text_Scale_Slider);
      Adi.Widget.Add_Child (+Box_15, +Label_20);
      Adi.Widget.Add_Child (+Box_15, +Switch_3);
      Adi.Widget.Add_Child (+Box_16, +Label_21);
      Adi.Widget.Add_Child (+Box_16, +Switch_4);
      Adi.Widget.Add_Child (+Box_11, +Label_16);
      Adi.Widget.Add_Child (+Box_11, +Box_12);
      Adi.Widget.Add_Child (+Box_11, +Box_13);
      Adi.Widget.Add_Child (+Box_11, +Box_14);
      Adi.Widget.Add_Child (+Box_11, +Box_15);
      Adi.Widget.Add_Child (+Box_11, +Box_16);
      Adi.Widget.Add_Child (+Box_10, +Box_11);
      Page_Stack.Add_Page (Pages, Home, +Box_2);
      Page_Stack.Add_Page (Pages, Forms, +Box_4);
      Page_Stack.Add_Page (Pages, Controls, +Box_7);
      Page_Stack.Add_Page (Pages, Settings, +Box_10);
      Adi.Widget.Add_Child (+Lock_Bar, +Label_22);
      Adi.Widget.Add_Child (+Lock_Bar, +Lock_Switch);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Nav_Bar);
      Adi.Widget.Add_Child (+Root, +Pages);
      Adi.Widget.Add_Child (+Root, +Lock_Bar);

      --  Wire option groups
      Nav_Options_Group.Set_Button (Home, Btn_Home);
      Nav_Options_Group.Set_Button (Forms, Btn_Forms);
      Nav_Options_Group.Set_Button (Settings, Btn_Settings);
      Nav_Options_Group.Set_Button (Controls, Btn_Controls);
      Nav_Options_Group.Disconnect_Changed (Nav_Options_Group_Conn);
      Nav_Options_Group_Conn := Nav_Options_Group.Connect_Changed (On_Page_Option_Wrapper'Unrestricted_Access);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Material_Demo_UI;
