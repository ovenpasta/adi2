--  Auto-generated from XML
--  Do not edit manually

pragma Wide_Character_Encoding (Brackets);
pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.I18N;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Switch; use Adi.Widget.Button.Switch;
with Adi.Widget.Combo_Box; use Adi.Widget.Combo_Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Widget.Text_Input; use Adi.Widget.Text_Input;
with Material_Demo_Styles;

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
              Merge_Part_Styles
                (Result.Root_Styles, Override.Root_Styles);
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
   use type Float_Value_Input.Value_Changed_Callback;

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
      Adi.CSS_Source.Set_Dynamic_Sources
        (Source, [Adi.CSS_Source.CSS_File (Path)], Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Material Demo", Adi.Window.Extent (Dip (617.0), Dip (592.0)));
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Welcome"));
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("A Material Design 3 demo built with Adi."));
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Edit examples/css/material_demo.css to live-reload."));
      Button_1 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Get Started"));
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Form Controls"));
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Country"));
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_2 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Submit"));
      Button_3 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Cancel"));
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Enabled vs Disabled"));
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Enabled"));
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Disabled"));
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Button"));
      Button_4 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Click Me"));
      Button_5 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Click Me"));
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Text Input"));
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Switch"));
      Switch_1 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Switch_2 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Combo Box"));
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Slider"));
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Value Input"));
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Settings"));
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Dark Mode"));
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("UI Scale"));
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Text Scale"));
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Notifications"));
      Switch_3 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Auto-save"));
      Switch_4 : constant Adi.Widget.Button.Switch.Switch_Handle := Adi.Widget.Button.Switch.Create_Handle (True);
      Label_22 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Lock UI"));
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;
      App_Title := Adi.Widget.Label.Create_Handle (Adi.I18N.T ("Material Demo"));
      Nav_Bar := Adi.Widget.Box.Create_Handle;
      Btn_Home := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Home"));
      Btn_Forms := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Forms"));
      Btn_Settings := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Settings"));
      Btn_Controls := Adi.Widget.Button.Create_Handle (Adi.I18N.T ("Controls"));
      Pages := Page_Stack.Create_Handle;
      Name_Input := Adi.Widget.Text_Input.Create_Handle ("", "Name");
      Country_Combo := Adi.Widget.Combo_Box.Create_Handle;
      Enabled_Input := Adi.Widget.Text_Input.Create_Handle (Adi.I18N.T ("Editable"), "");
      Disabled_Input := Adi.Widget.Text_Input.Create_Handle (Adi.I18N.T ("Read-only"), "");
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
      Adi.Widget.Set_Label (+Name_Input, Adi.I18N.T ("Name"));

      --  Wire callbacks
      if On_Get_Started /= null then
         Adi.Widget.Button.Connect_Clicked (Button_1, On_Get_Started);
      end if;
      if On_Control_Slider /= null then
         Float_Slider.Connect_Changed (Enabled_Slider, On_Control_Slider);
      end if;
      if On_Control_Value /= null then
         Float_Value_Input.Connect_Value_Changed (Enabled_Value_Input, On_Control_Value);
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

      --  Install the stylesheets as one batch: precompiled
      --  styles as static fallback, then dynamic CSS and the mode
      declare
         Update : Adi.CSS_Source.Update_Scope (Source'Access);
         pragma Unreferenced (Update);
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Material_Demo_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Set_Dynamic_Sources
           (Source,
            [Adi.CSS_Source.CSS_File ("examples/css/material_demo.css")],
            Loaded);
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
      --  Bind every widget under the selectors naming it
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Root,
         Tag_Name   => "box",
         Class_Name => "root",
         Id_Name    => "Root");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_1,
         Tag_Name   => "box",
         Class_Name => "app-bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +App_Title,
         Tag_Name   => "label",
         Class_Name => "app-title",
         Id_Name    => "App_Title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Nav_Bar,
         Tag_Name   => "box",
         Class_Name => "nav-bar",
         Id_Name    => "Nav_Bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Btn_Home,
         Tag_Name   => "button",
         Class_Name => "nav-btn",
         Id_Name    => "Btn_Home");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Btn_Forms,
         Tag_Name   => "button",
         Class_Name => "nav-btn",
         Id_Name    => "Btn_Forms");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Btn_Settings,
         Tag_Name   => "button",
         Class_Name => "nav-btn",
         Id_Name    => "Btn_Settings");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Btn_Controls,
         Tag_Name   => "button",
         Class_Name => "nav-btn",
         Id_Name    => "Btn_Controls");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Pages,
         Tag_Name   => "stack",
         Class_Name => "pages",
         Id_Name    => "Pages");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "page");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_1,
         Tag_Name   => "label",
         Class_Name => "label-inline card-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "label-inline card-body");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "label-inline card-hint");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_1,
         Tag_Name   => "button",
         Class_Name => "btn btn-primary");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "page");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "label-inline card-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Name_Input,
         Tag_Name   => "text-input",
         Class_Name => "text-field",
         Id_Name    => "Name_Input");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "label-inline field-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Country_Combo,
         Tag_Name   => "combo-box",
         Class_Name => "combo",
         Id_Name    => "Country_Combo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "btn-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_2,
         Tag_Name   => "button",
         Class_Name => "btn btn-primary");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_3,
         Tag_Name   => "button",
         Class_Name => "btn btn-secondary");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "page");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "label-inline card-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "control-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-header");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-header");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-header");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_4,
         Tag_Name   => "button",
         Class_Name => "btn btn-primary grid-cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_5,
         Tag_Name   => "button",
         Class_Name => "btn btn-primary grid-cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Enabled_Input,
         Tag_Name   => "text-input",
         Class_Name => "text-field grid-cell",
         Id_Name    => "Enabled_Input");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Disabled_Input,
         Tag_Name   => "text-input",
         Class_Name => "text-field grid-cell",
         Id_Name    => "Disabled_Input");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Switch_1,
         Tag_Name   => "switch",
         Class_Name => "setting-switch grid-cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Switch_2,
         Tag_Name   => "switch",
         Class_Name => "setting-switch grid-cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Enabled_Combo,
         Tag_Name   => "combo-box",
         Class_Name => "combo grid-cell",
         Id_Name    => "Enabled_Combo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Disabled_Combo,
         Tag_Name   => "combo-box",
         Class_Name => "combo grid-cell",
         Id_Name    => "Disabled_Combo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Enabled_Slider,
         Tag_Name   => "slider",
         Class_Name => "slider grid-cell grid-slider",
         Id_Name    => "Enabled_Slider");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Disabled_Slider,
         Tag_Name   => "slider",
         Class_Name => "slider grid-cell grid-slider",
         Id_Name    => "Disabled_Slider");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "label-inline grid-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Enabled_Value_Input,
         Tag_Name   => "value-input",
         Class_Name => "num-field grid-cell",
         Id_Name    => "Enabled_Value_Input");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Disabled_Value_Input,
         Tag_Name   => "integer-value-input",
         Class_Name => "num-field grid-cell",
         Id_Name    => "Disabled_Value_Input");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "page");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "label-inline card-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "setting-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "label-inline setting-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Dark_Switch,
         Tag_Name   => "switch",
         Class_Name => "setting-switch",
         Id_Name    => "Dark_Switch");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "setting-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "label-inline setting-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +UI_Scale_Slider,
         Tag_Name   => "slider",
         Class_Name => "slider",
         Id_Name    => "UI_Scale_Slider");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "setting-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_19,
         Tag_Name   => "label",
         Class_Name => "label-inline setting-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Text_Scale_Slider,
         Tag_Name   => "slider",
         Class_Name => "slider",
         Id_Name    => "Text_Scale_Slider");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "setting-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_20,
         Tag_Name   => "label",
         Class_Name => "label-inline setting-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Switch_3,
         Tag_Name   => "switch",
         Class_Name => "setting-switch");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "setting-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_21,
         Tag_Name   => "label",
         Class_Name => "label-inline setting-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Switch_4,
         Tag_Name   => "switch",
         Class_Name => "setting-switch");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Lock_Bar,
         Tag_Name   => "box",
         Class_Name => "nav-bar setting-row lock-bar",
         Id_Name    => "Lock_Bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_22,
         Tag_Name   => "label",
         Class_Name => "label-inline setting-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Lock_Switch,
         Tag_Name   => "switch",
         Class_Name => "setting-switch",
         Id_Name    => "Lock_Switch");

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
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, Adi.I18N.T ("United States"));
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, Adi.I18N.T ("United Kingdom"));
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, Adi.I18N.T ("Germany"));
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, Adi.I18N.T ("France"));
      Adi.Widget.Combo_Box.Add_Item (Country_Combo, Adi.I18N.T ("Japan"));
      Adi.Widget.Add_Child (+Box_6, +Button_2);
      Adi.Widget.Add_Child (+Box_6, +Button_3);
      Adi.Widget.Add_Child (+Box_5, +Label_4);
      Adi.Widget.Add_Child (+Box_5, +Name_Input);
      Adi.Widget.Add_Child (+Box_5, +Label_5);
      Adi.Widget.Add_Child (+Box_5, +Country_Combo);
      Adi.Widget.Add_Child (+Box_5, +Box_6);
      Adi.Widget.Add_Child (+Box_4, +Box_5);
      Adi.Widget.Combo_Box.Add_Item (Enabled_Combo, Adi.I18N.T ("Enabled"));
      Adi.Widget.Combo_Box.Add_Item (Disabled_Combo, Adi.I18N.T ("Disabled"));
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
      Nav_Options.Set_Button (Nav_Options_Group, Home, Btn_Home);
      Nav_Options.Set_Button (Nav_Options_Group, Forms, Btn_Forms);
      Nav_Options.Set_Button (Nav_Options_Group, Settings, Btn_Settings);
      Nav_Options.Set_Button (Nav_Options_Group, Controls, Btn_Controls);
      Nav_Options.Disconnect_Changed (Nav_Options_Group, Nav_Options_Group_Conn);
      Nav_Options_Group_Conn := Nav_Options.Connect_Changed (Nav_Options_Group, On_Page_Option_Wrapper'Unrestricted_Access);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Material_Demo_UI;
