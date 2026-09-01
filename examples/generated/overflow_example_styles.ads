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

package Overflow_Example_Styles is

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
        .Padding (CSS_Box (Px (18.0), Px (18.0), Px (18.0), Px (18.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
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
        .Font_Weight (Weight_Bold)
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
        .Text_Color (RGB (189, 205, 230))
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

   --  Style for class 'panels'
   Panels_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (18.0)))
        .Align_Items (Stretch)
        .Flex_Grow (1.0)
     .Build;

   --  Part styles bundle for class 'panels'
   Panels_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panels_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel'
   Panel_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (10.0)))
        .Flex_Grow (1.0)
        .Background (RGB (31, 41, 55))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'panel'
   Panel_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel-title'
   Panel_Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'panel-title'::label
   Panel_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (224, 231, 255))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'panel-title'
   Panel_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panel_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Panel_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'clip-visible'
   Clip_Visible_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Height (Size (Px (120.0)))
        .Gap (Gap (Px (8.0)))
        .Background (RGBA (96, 165, 250, 0.16))
        .Text_Wrap_Mode (TWM_Nowrap)
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (96, 165, 250)))
        .Radius (Radius (Px (8.0)))
        .Overflow_X (Overflow_Visible)
        .Overflow_Y (Overflow_Visible)
     .Build;

   --  Part styles bundle for class 'clip-visible'
   Clip_Visible_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Clip_Visible_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'clip-hidden'
   Clip_Hidden_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Height (Size (Px (120.0)))
        .Gap (Gap (Px (8.0)))
        .Background (RGBA (74, 222, 128, 0.16))
        .Text_Wrap_Mode (TWM_Nowrap)
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (74, 222, 128)))
        .Radius (Radius (Px (8.0)))
        .Overflow_X (Overflow_Hidden)
        .Overflow_Y (Overflow_Hidden)
     .Build;

   --  Part styles bundle for class 'clip-hidden'
   Clip_Hidden_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Clip_Hidden_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'content-stack'
   Content_Stack_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'content-stack'
   Content_Stack_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Content_Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'long-line'
   Long_Line_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (430.0)))
        .Background (RGBA (15, 23, 42, 0.45))
        .Padding (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (148, 163, 184)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Style for class 'long-line'::label
   Long_Line_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (241, 245, 249))
        .Font_Size (Px (12.0))
        .White_Space (WS_Nowrap)
     .Build;

   --  Part styles bundle for class 'long-line'
   Long_Line_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Long_Line_Class_Widget, Enabled => True),
      Label_Part => (Style => Long_Line_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wrap-line'
   Wrap_Line_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Pct (100.0)))
        .Background (RGBA (15, 23, 42, 0.3))
        .Padding (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (100, 116, 139)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Style for class 'wrap-line'::label
   Wrap_Line_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (241, 245, 249))
        .Font_Size (Px (12.0))
        .Text_Wrap_Mode (TWM_Wrap)
        .White_Space (WS_Normal)
     .Build;

   --  Part styles bundle for class 'wrap-line'
   Wrap_Line_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wrap_Line_Class_Widget, Enabled => True),
      Label_Part => (Style => Wrap_Line_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'item-a'
   Item_A_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (56.0)))
        .Flex_Shrink (0.0)
        .Background (RGB (239, 68, 68))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'item-a'
   Item_A_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Item_A_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'item-b'
   Item_B_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (56.0)))
        .Flex_Shrink (0.0)
        .Background (RGB (245, 158, 11))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'item-b'
   Item_B_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Item_B_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'item-c'
   Item_C_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (56.0)))
        .Flex_Shrink (0.0)
        .Background (RGB (59, 130, 246))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'item-c'
   Item_C_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Item_C_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'item-d'
   Item_D_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (56.0)))
        .Flex_Shrink (0.0)
        .Background (RGB (16, 185, 129))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'item-d'
   Item_D_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Item_D_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Overflow_Example_Styles;