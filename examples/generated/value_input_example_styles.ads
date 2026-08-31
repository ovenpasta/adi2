--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

--  The constants below intern as this package elaborates, so the
--  stores behind Intern_Rules and Build are wanted first.
pragma Elaborate_All (Adi.Widget_Styles);

package Value_Input_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   Root_Part_Styles : constant Part_Style_Array := Empty_Part_Styles;

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Root_Part_Styles,
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);
   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (20.0))),
      Background_Color => Set_Bg (RGB (30, 30, 46)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>);

   --  Base style for class 'section'
   function Section_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      others => <>);

   --  Base style for class 'row'
   function Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'heading'::label
   function Heading_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'label'
   function Label_Class_Base_Style return Style_Rules is
     (
      Min_Width => Set (Size (Px (120.0))),
      others => <>);

   --  Base style for class 'label'::label
   function Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (186, 194, 222)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'label-narrow'
   function Label_Narrow_Class_Base_Style return Style_Rules is
     (
      Min_Width => Set (Size (Px (24.0))),
      others => <>);

   --  Base style for class 'label-narrow'::label
   function Label_Narrow_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (186, 194, 222)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'value-label'::label
   function Value_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (166, 227, 161)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'value-input'
   function Value_Input_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (120.0))),
      Height => Set (Size (Px (30.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Font_Size => Set_Font (Px (14.0)),
      Padding => Set (CSS_Box (Px (4.0), Px (8.0), Px (4.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (88, 91, 112))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'value-input' when widget State_Focused
   function Value_Input_Class_Widget_Focused_Style return Style_Rules is
     (
      Border_Color => Set (Border_Color (RGB (137, 180, 250))),
      others => <>);

   --  Base style for class 'value-input'::cursor
   function Value_Input_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (137, 180, 250)),
      others => <>);

   --  Base style for class 'value-input'::selected
   function Value_Input_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.25)),
      others => <>);

   --  Base style for class 'value-input'::text
   function Value_Input_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      others => <>);

   --  Base style for class 'int-input'
   function Int_Input_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (100.0))),
      Height => Set (Size (Px (30.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Font_Size => Set_Font (Px (14.0)),
      Padding => Set (CSS_Box (Px (4.0), Px (8.0), Px (4.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (88, 91, 112))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'int-input' when widget State_Focused
   function Int_Input_Class_Widget_Focused_Style return Style_Rules is
     (
      Border_Color => Set (Border_Color (RGB (243, 139, 168))),
      others => <>);

   --  Base style for class 'int-input'::cursor
   function Int_Input_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (243, 139, 168)),
      others => <>);

   --  Base style for class 'int-input'::selected
   function Int_Input_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (243, 139, 168, 0.25)),
      others => <>);

   --  Base style for class 'int-input'::text
   function Int_Input_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      others => <>);

   --  Base style for class 'wide-input'
   function Wide_Input_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (180.0))),
      Height => Set (Size (Px (30.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Font_Size => Set_Font (Px (14.0)),
      Padding => Set (CSS_Box (Px (4.0), Px (8.0), Px (4.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (88, 91, 112))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'wide-input' when widget State_Focused
   function Wide_Input_Class_Widget_Focused_Style return Style_Rules is
     (
      Border_Color => Set (Border_Color (RGB (166, 227, 161))),
      others => <>);

   --  Base style for class 'wide-input'::cursor
   function Wide_Input_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (166, 227, 161)),
      others => <>);

   --  Base style for class 'wide-input'::selected
   function Wide_Input_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (166, 227, 161, 0.25)),
      others => <>);

   --  Base style for class 'wide-input'::text
   function Wide_Input_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      others => <>);

   --  Base style for class 'context-menu'
   function Context_Menu_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (180.0))),
      Background_Color => Set_Bg (RGB (30, 30, 46)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (24.0), Px (0.0), RGBA (0, 0, 0, 0.45))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (88, 91, 112))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'context-menu-item'
   function Context_Menu_Item_Class_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'context-menu-item' when widget State_Hovered
   function Context_Menu_Item_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.15)),
      others => <>);

   --  Base style for class 'context-menu-item'::label
   function Context_Menu_Item_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'section'
   Section_Class_Widget : constant Widget_Style :=
     From (Section_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'section'
   Section_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'row'
   Row_Class_Widget : constant Widget_Style :=
     From (Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'row'
   Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'heading'::label
   Heading_Class_Label_Widget : constant Widget_Style :=
     From (Heading_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'heading'
   Heading_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Heading_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'label'
   Label_Class_Widget : constant Widget_Style :=
     From (Label_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'label'::label
   Label_Class_Label_Widget : constant Widget_Style :=
     From (Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'label'
   Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'label-narrow'
   Label_Narrow_Class_Widget : constant Widget_Style :=
     From (Label_Narrow_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'label-narrow'::label
   Label_Narrow_Class_Label_Widget : constant Widget_Style :=
     From (Label_Narrow_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'label-narrow'
   Label_Narrow_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label_Narrow_Class_Widget, Enabled => True),
      Label_Part => (Style => Label_Narrow_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'value-label'::label
   Value_Label_Class_Label_Widget : constant Widget_Style :=
     From (Value_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'value-label'
   Value_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Value_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'value-input'
   Value_Input_Class_Widget : constant Widget_Style :=
     From (Value_Input_Class_Base_Style)
     .On (When_State (State_Focused), Value_Input_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'value-input'::cursor
   Value_Input_Class_Cursor_Widget : constant Widget_Style :=
     From (Value_Input_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'value-input'::selected
   Value_Input_Class_Selected_Widget : constant Widget_Style :=
     From (Value_Input_Class_Selected_Base_Style)
     .Build;

   --  Complete widget style for class 'value-input'::text
   Value_Input_Class_Text_Widget : constant Widget_Style :=
     From (Value_Input_Class_Text_Base_Style)
     .Build;

   --  Part styles bundle for class 'value-input'
   Value_Input_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Value_Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Value_Input_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Value_Input_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Value_Input_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'int-input'
   Int_Input_Class_Widget : constant Widget_Style :=
     From (Int_Input_Class_Base_Style)
     .On (When_State (State_Focused), Int_Input_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'int-input'::cursor
   Int_Input_Class_Cursor_Widget : constant Widget_Style :=
     From (Int_Input_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'int-input'::selected
   Int_Input_Class_Selected_Widget : constant Widget_Style :=
     From (Int_Input_Class_Selected_Base_Style)
     .Build;

   --  Complete widget style for class 'int-input'::text
   Int_Input_Class_Text_Widget : constant Widget_Style :=
     From (Int_Input_Class_Text_Base_Style)
     .Build;

   --  Part styles bundle for class 'int-input'
   Int_Input_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Int_Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Int_Input_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Int_Input_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Int_Input_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'wide-input'
   Wide_Input_Class_Widget : constant Widget_Style :=
     From (Wide_Input_Class_Base_Style)
     .On (When_State (State_Focused), Wide_Input_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'wide-input'::cursor
   Wide_Input_Class_Cursor_Widget : constant Widget_Style :=
     From (Wide_Input_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'wide-input'::selected
   Wide_Input_Class_Selected_Widget : constant Widget_Style :=
     From (Wide_Input_Class_Selected_Base_Style)
     .Build;

   --  Complete widget style for class 'wide-input'::text
   Wide_Input_Class_Text_Widget : constant Widget_Style :=
     From (Wide_Input_Class_Text_Base_Style)
     .Build;

   --  Part styles bundle for class 'wide-input'
   Wide_Input_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wide_Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Wide_Input_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Wide_Input_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Wide_Input_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     From (Context_Menu_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'context-menu'
   Context_Menu_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'context-menu-item'
   Context_Menu_Item_Class_Widget : constant Widget_Style :=
     From (Context_Menu_Item_Class_Base_Style)
     .On (When_State (State_Hovered), Context_Menu_Item_Class_Widget_Hovered_Style)
     .Build;

   --  Complete widget style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Widget : constant Widget_Style :=
     From (Context_Menu_Item_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'context-menu-item'
   Context_Menu_Item_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Value_Input_Example_Styles;