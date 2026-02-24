--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.Window; use Adi.Window;
with Stack_Example_Styles; use Stack_Example_Styles;
with Stack_Example_Tabs_Styles; use Stack_Example_Tabs_Styles;

package body Stack_Example_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;
   Inline_CSS : constant String := ".page-title::main {" & ASCII.LF & "  display: inline-flex;" & ASCII.LF & "}" & ASCII.LF & "" & ASCII.LF & ".page-title::label {" & ASCII.LF & "  color: white;" & ASCII.LF & "  font-size: 24px;" & ASCII.LF & "  font-weight: 700;" & ASCII.LF & "}" & ASCII.LF & "" & ASCII.LF & ".page-desc::main {" & ASCII.LF & "  display: inline-flex;" & ASCII.LF & "}" & ASCII.LF & "" & ASCII.LF & ".page-desc::label {" & ASCII.LF & "  color: rgba(255, 255, 255, 0.7);" & ASCII.LF & "  font-size: 16px;" & ASCII.LF & "  font-weight: 400;" & ASCII.LF & "}" & ASCII.LF & "" & ASCII.LF & ".page-title {" & ASCII.LF & "  flex-shrink: 0;" & ASCII.LF & "}";

   --  Base style for class 'page-title'
   Page_Title_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'page-title'::label
   Page_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'page-desc'
   Page_Desc_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for class 'page-desc'::label
   Page_Desc_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGBA (255, 255, 255, 0.7)),
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Normal),
      others => <>
   );

   --  Complete widget style for class 'page-title'
   Page_Title_Class_Widget : constant Widget_Style :=
     From (Page_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'page-title'::label
   Page_Title_Class_Label_Widget : constant Widget_Style :=
     From (Page_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-title'
   Page_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Page_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-desc'
   Page_Desc_Class_Widget : constant Widget_Style :=
     From (Page_Desc_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'page-desc'::label
   Page_Desc_Class_Label_Widget : constant Widget_Style :=
     From (Page_Desc_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-desc'
   Page_Desc_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Desc_Class_Widget, Enabled => True),
      Label_Part => (Style => Page_Desc_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   use type My_Stack.Page_Changed_Callback;
   Tab_Options_Group : aliased Tab_Options.Option_Group;

   procedure On_Tab_Option_Wrapper (Value : Tab) is
   begin
      if On_Tab /= null then
         On_Tab (Value);
      end if;
   end On_Tab_Option_Wrapper;

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
      declare
         Component_Reloaded : Boolean := False;
         Component_Success  : Boolean := True;
      begin
         Red_Page.Tick_Styles (Component_Reloaded, Component_Success);
         Reloaded := Reloaded or Component_Reloaded;
         Success := Success and Component_Success;
      end;
      declare
         Component_Reloaded : Boolean := False;
         Component_Success  : Boolean := True;
      begin
         Green_Page.Tick_Styles (Component_Reloaded, Component_Success);
         Reloaded := Reloaded or Component_Reloaded;
         Success := Success and Component_Success;
      end;
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
        Adi.Window.Create_Window ("Stack Example", (600.0, 450.0));
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Blue Page");
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("This is the third page with a deep blue background.");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create;
      Tab_Bar := Adi.Widget.Box.Create;
      Btn_Red := Adi.Widget.Button.Create ("Red");
      Btn_Green := Adi.Widget.Button.Create ("Green");
      Btn_Blue := Adi.Widget.Button.Create ("Blue");
      Pages := My_Stack.Create;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tab-bar", Tab_Bar_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tab-left", Tab_Left_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tab-center", Tab_Center_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tab-right", Tab_Right_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("stack", Stack_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-blue", Page_Blue_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-title", Page_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-desc", Page_Desc_Class_Part_Styles));

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/stack_example.css", Loaded);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/stack_example_tabs.css", Loaded);
         Adi.CSS_Source.Add_Dynamic_String
           (Source, Inline_CSS, Loaded);
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
      Adi.CSS_Source.Bind_Class (Source, "tab-bar", Tab_Bar);
      Adi.CSS_Source.Bind_Class (Source, "tab-left", Btn_Red);
      Adi.CSS_Source.Bind_Class (Source, "tab-center", Btn_Green);
      Adi.CSS_Source.Bind_Class (Source, "tab-right", Btn_Blue);
      Adi.CSS_Source.Bind_Class (Source, "stack", Pages);
      Adi.CSS_Source.Bind_Class (Source, "page-blue", Box_1);
      Adi.CSS_Source.Bind_Class (Source, "page-title", Label_1);
      Adi.CSS_Source.Bind_Class (Source, "page-desc", Label_2);

      --  Build hierarchy
      Tab_Bar.Add_Child (Btn_Red);
      Tab_Bar.Add_Child (Btn_Green);
      Tab_Bar.Add_Child (Btn_Blue);
      Box_1.Add_Child (Label_1);
      Box_1.Add_Child (Label_2);
      Pages.Add_Page (Red, Red_Page.Build);
      Pages.Add_Page (Green, Green_Page.Build);
      Pages.Add_Page (Blue, Box_1);
      Root.Add_Child (Tab_Bar);
      Root.Add_Child (Pages);

      --  Wire option groups
      Tab_Options_Group.Set_Button (Red, Btn_Red);
      Tab_Options_Group.Set_Button (Green, Btn_Green);
      Tab_Options_Group.Set_Button (Blue, Btn_Blue);
      Tab_Options_Group.Set_On_Changed (On_Tab_Option_Wrapper'Unrestricted_Access);

      --  Auto-wire CSS live reload
      Adi.Window.Set_On_Tick (W.all, Tick_Styles_CB'Unrestricted_Access);

      W.Set_Root (Root);
      return W;
   end Build;

   end Instance;

end Stack_Example_UI;
