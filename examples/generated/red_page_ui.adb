--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Stack_Example_Styles; use Stack_Example_Styles;

package body Red_Page_UI is

   package body Instance is
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
      return Adi.Widget.Widget_Access is
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Red Page");
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("This is the first page with a warm red background.");
   begin
      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-red", Page_Red_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-title", Page_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-desc", Page_Desc_Class_Part_Styles));

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/stack_example.css", Loaded);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/generated/red_page_ui_inline.css", Loaded);
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
      Adi.CSS_Source.Bind_Class (Source, "page-red", Box_1);
      Adi.CSS_Source.Bind_Class (Source, "page-title", Label_1);
      Adi.CSS_Source.Bind_Class (Source, "page-desc", Label_2);

      --  Build hierarchy
      Box_1.Add_Child (Label_1);
      Box_1.Add_Child (Label_2);

      return Adi.Widget.Widget_Access (Box_1);
   end Build;

   end Instance;

end Red_Page_UI;
