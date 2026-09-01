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

package Text_Input_Example_Styles is

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
   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Stretch)
        .Justify_Content (Flex_Start)
        .Gap (Gap (Px (12.0)))
        .Background (RGB (20, 24, 31))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Stretch)
        .Justify_Content (Flex_Start)
        .Flex_Grow (1.0)
        .Gap (Gap (Px (12.0)))
        .Background (RGB (31, 41, 55))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (22.0))
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'hint'
   Hint_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (191, 219, 254))
        .Font_Size (Px (13.0))
        .Text_Wrap_Mode (TWM_Wrap)
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'echo-label'::label
   Echo_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (165, 243, 252))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'echo-label'
   Echo_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Echo_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'length-label'::label
   Length_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (147, 197, 253))
        .Font_Size (Px (12.0))
     .Build;

   --  Part styles bundle for class 'length-label'
   Length_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Length_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'input'
   Input_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (42.0)))
        .Flex_Shrink (0.0)
        .Cursor_Style (Cursor_Text)
        .Background (C (White))
        .Box_Shadow (No_Shadow)
        .Padding (CSS_Box (Px (10.0), Px (12.0), Px (10.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (191, 219, 254)))
        .Radius (Radius (Px (8.0)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0), RGBA (59, 130, 246, 0.35)))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
     .Build;

   --  Style for class 'input'::cursor
   Input_Class_Cursor_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (37, 99, 235))
     .Build;

   --  Style for class 'input'::selected
   Input_Class_Selected_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (191, 219, 254, 0.85))
     .Build;

   --  Style for class 'input'::text
   Input_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (15, 23, 42))
        .Font_Size (Px (14.0))
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'input'
   Input_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Input_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Input_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Input_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (180.0)))
        .Background (RGB (15, 23, 42))
        .Box_Shadow (Shadow (Px (0.0), Px (8.0), Px (24.0), Px (0.0), RGBA (2, 6, 23, 0.45)))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'context-menu'
   Context_Menu_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu-item'
   Context_Menu_Item_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (28.0)))
        .Background (RGBA (15, 23, 42, 0.0))
        .Padding (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (37, 99, 235, 0.35))
     .Build;

   --  Style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (219, 234, 254))
        .Font_Size (Px (13.0))
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

end Text_Input_Example_Styles;