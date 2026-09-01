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

package Gradient_Example_Styles is

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
        .Background (RGB (15, 17, 26))
        .Gap (Gap (Px (12.0)))
        .Padding (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.1)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.28)))
     .Build;

   --  Style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (94, 129, 172, 0.06))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (94, 129, 172, 0.16))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'row'
   Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'row'
   Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (200, 210, 255))
        .Font_Size (Px (20.0))
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-card'::label
   Grad_Card_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (255, 255, 255))
        .Font_Size (Px (11.0))
        .Left (Inset (Px (8.0)))
        .Top (Inset (Px (78.0)))
     .Build;

   --  Part styles bundle for class 'grad-card'
   Grad_Card_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Grad_Card_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-v'
   Grad_V_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-v'
   Grad_V_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_V_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-h'
   Grad_H_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (RGB (234, 179, 8)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-h'
   Grad_H_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_H_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-default'
   Grad_Default_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (RGB (168, 85, 247)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-default'
   Grad_Default_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Default_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-up'
   Grad_Up_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (0.0, [Gradient_Stop_Auto (RGB (15, 23, 42)), Gradient_Stop_Auto (RGB (99, 102, 241)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-up'
   Grad_Up_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Up_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-left'
   Grad_Left_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (270.0, [Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-left'
   Grad_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Left_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-diag'
   Grad_Diag_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (139, 92, 246)), Gradient_Stop_Auto (RGB (236, 72, 153)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-diag'
   Grad_Diag_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Diag_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-diag-tr'
   Grad_Diag_Tr_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (45.0, [Gradient_Stop_Auto (RGB (14, 165, 233)), Gradient_Stop_Auto (RGB (99, 102, 241)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-diag-tr'
   Grad_Diag_Tr_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Diag_Tr_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-diag-bl'
   Grad_Diag_Bl_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (225.0, [Gradient_Stop_Auto (RGB (250, 204, 21)), Gradient_Stop_Auto (RGB (34, 197, 94)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-diag-bl'
   Grad_Diag_Bl_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Diag_Bl_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-diag-rev'
   Grad_Diag_Rev_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (315.0, [Gradient_Stop_Auto (RGB (244, 114, 182)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-diag-rev'
   Grad_Diag_Rev_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Diag_Rev_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-45'
   Grad_45_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (45.0, [Gradient_Stop_Auto (RGB (6, 182, 212)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-45'
   Grad_45_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_45_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-135'
   Grad_135_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-135'
   Grad_135_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_135_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-turn'
   Grad_Turn_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (6, 182, 212)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-turn'
   Grad_Turn_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Turn_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-rad'
   Grad_Rad_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0002104591497, [Gradient_Stop_Auto (RGB (236, 72, 153)), Gradient_Stop_Auto (RGB (99, 102, 241)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-rad'
   Grad_Rad_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Rad_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-grad'
   Grad_Grad_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-grad'
   Grad_Grad_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Grad_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-alpha'
   Grad_Alpha_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background (RGB (220, 38, 38))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (0, 0, 0, 0.0)), Gradient_Stop_Auto (RGBA (0, 0, 0, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'grad-alpha'
   Grad_Alpha_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Alpha_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-3stop'
   Grad_3stop_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (RGB (234, 179, 8)), Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 3))
        .Radius (Radius (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'grad-3stop'
   Grad_3stop_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_3stop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-pos'
   Grad_Pos_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_At (RGB (59, 130, 246), 0.0), Gradient_Stop_At (RGB (139, 92, 246), 0.3), Gradient_Stop_At (RGB (236, 72, 153), 1.0), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 3))
        .Radius (Radius (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'grad-pos'
   Grad_Pos_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Pos_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-edge'
   Grad_Edge_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_At (RGB (239, 68, 68), 0.2), Gradient_Stop_At (RGB (59, 130, 246), 0.8), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'grad-edge'
   Grad_Edge_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Edge_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-16stop'
   Grad_16stop_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_At (RGB (239, 68, 68), 0.0), Gradient_Stop_At (RGB (249, 115, 22), 0.06666699999999999), Gradient_Stop_At (RGB (245, 158, 11), 0.133333), Gradient_Stop_At (RGB (234, 179, 8), 0.2), Gradient_Stop_At (RGB (163, 230, 53), 0.266667), Gradient_Stop_At (RGB (34, 197, 94), 0.333333), Gradient_Stop_At (RGB (16, 185, 129), 0.4), Gradient_Stop_At (RGB (20, 184, 166), 0.466667), Gradient_Stop_At (RGB (6, 182, 212), 0.5333330000000001), Gradient_Stop_At (RGB (14, 165, 233), 0.6), Gradient_Stop_At (RGB (59, 130, 246), 0.666667), Gradient_Stop_At (RGB (99, 102, 241), 0.7333329999999999), Gradient_Stop_At (RGB (139, 92, 246), 0.8), Gradient_Stop_At (RGB (168, 85, 247), 0.8666670000000001), Gradient_Stop_At (RGB (217, 70, 239), 0.933333), Gradient_Stop_At (RGB (236, 72, 153), 1.0)], 16))
        .Radius (Radius (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'grad-16stop'
   Grad_16stop_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_16stop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-pill'
   Grad_Pill_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Radius (Radius (Px (50.0)))
     .Build;

   --  Style for class 'grad-pill'::label
   Grad_Pill_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Left (Inset (Px (32.0)))
     .Build;

   --  Part styles bundle for class 'grad-pill'
   Grad_Pill_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Pill_Class_Widget, Enabled => True),
      Label_Part => (Style => Grad_Pill_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grad-border'
   Grad_Border_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Height (Size (Px (100.0)))
        .Background_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Width (Border_Width (Px (4.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (200, 210, 255)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'grad-border'
   Grad_Border_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grad_Border_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Gradient_Example_Styles;