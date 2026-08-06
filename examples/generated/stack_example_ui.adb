--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Stack_Example_Styles; use Stack_Example_Styles;
with Stack_Example_Tabs_Styles; use Stack_Example_Tabs_Styles;

package body Stack_Example_UI is

   package body Instance is
   use My_Stack;
   Source : aliased Adi.CSS_Source.Style_Source;

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
      Result := Merge_Metadata (Result, Stack_Example_Styles.Root_Metadata);
      Result := Merge_Metadata (Result, Stack_Example_Tabs_Styles.Root_Metadata);
      return Result;
   end Static_Root_Metadata;
   Tab_Options_Group : aliased Tab_Options.Option_Group;
   Tab_Options_Group_Conn : Tab_Options.Option_Changed_Signals.Connection_Id :=
     Tab_Options.Option_Changed_Signals.No_Connection;

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

   procedure Register_Tab_Bar_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tab-bar", Tab_Bar_Class_Part_Styles));
   end Register_Tab_Bar_Styles;

   procedure Register_Tab_Left_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tab-left", Tab_Left_Class_Part_Styles));
   end Register_Tab_Left_Styles;

   procedure Register_Tab_Center_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tab-center", Tab_Center_Class_Part_Styles));
   end Register_Tab_Center_Styles;

   procedure Register_Tab_Right_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tab-right", Tab_Right_Class_Part_Styles));
   end Register_Tab_Right_Styles;

   procedure Register_Stack_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("stack", Stack_Class_Part_Styles));
   end Register_Stack_Styles;

   procedure Register_Page_Blue_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("page-blue", Page_Blue_Class_Part_Styles));
   end Register_Page_Blue_Styles;

   procedure Register_Page_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("page-title", Page_Title_Class_Part_Styles));
   end Register_Page_Title_Styles;

   procedure Register_Page_Desc_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("page-desc", Page_Desc_Class_Part_Styles));
   end Register_Page_Desc_Styles;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Stack Example", Adi.Window.Extent (Px (411.0), Px (309.0)));
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Blue Page");
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("This is the third page with a deep blue background.");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;
      Tab_Bar := Adi.Widget.Box.Create_Handle;
      Btn_Red := Adi.Widget.Button.Create_Handle ("Red");
      Btn_Green := Adi.Widget.Button.Create_Handle ("Green");
      Btn_Blue := Adi.Widget.Button.Create_Handle ("Blue");
      Pages := My_Stack.Create_Handle;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Register_Root_Styles (Source);
      Register_Tab_Bar_Styles (Source);
      Register_Tab_Left_Styles (Source);
      Register_Tab_Center_Styles (Source);
      Register_Tab_Right_Styles (Source);
      Register_Stack_Styles (Source);
      Register_Page_Blue_Styles (Source);
      Register_Page_Title_Styles (Source);
      Register_Page_Desc_Styles (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/stack_example.css", Loaded);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/stack_example_tabs.css", Loaded);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/generated/stack_example_ui_inline.css", Loaded);
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
      Adi.CSS_Source.Bind_Class (Source, "tab-bar", +Tab_Bar);
      Adi.CSS_Source.Bind_Class (Source, "tab-left", +Btn_Red);
      Adi.CSS_Source.Bind_Class (Source, "tab-center", +Btn_Green);
      Adi.CSS_Source.Bind_Class (Source, "tab-right", +Btn_Blue);
      Adi.CSS_Source.Bind_Class (Source, "stack", +Pages);
      Adi.CSS_Source.Bind_Class (Source, "page-blue", +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "page-title", +Label_1);
      Adi.CSS_Source.Bind_Class (Source, "page-desc", +Label_2);

      --  Build hierarchy
      Adi.Widget.Add_Child (+Tab_Bar, +Btn_Red);
      Adi.Widget.Add_Child (+Tab_Bar, +Btn_Green);
      Adi.Widget.Add_Child (+Tab_Bar, +Btn_Blue);
      Adi.Widget.Add_Child (+Box_1, +Label_1);
      Adi.Widget.Add_Child (+Box_1, +Label_2);
      My_Stack.Add_Page (Pages, Red, Red_Page.Build);
      My_Stack.Add_Page (Pages, Green, Green_Page.Build);
      My_Stack.Add_Page (Pages, Blue, +Box_1);
      Adi.Widget.Add_Child (+Root, +Tab_Bar);
      Adi.Widget.Add_Child (+Root, +Pages);

      --  Wire option groups
      Tab_Options_Group.Set_Button (Red, Btn_Red);
      Tab_Options_Group.Set_Button (Green, Btn_Green);
      Tab_Options_Group.Set_Button (Blue, Btn_Blue);
      Tab_Options_Group.Disconnect_Changed (Tab_Options_Group_Conn);
      Tab_Options_Group_Conn := Tab_Options_Group.Connect_Changed (On_Tab_Option_Wrapper'Unrestricted_Access);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Stack_Example_UI;
