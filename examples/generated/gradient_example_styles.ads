--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Gradient_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   function Root_Part_Styles return Part_Style_Array is (Empty_Part_Styles);

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
      Background_Color => Set_Bg (RGB (15, 17, 26)),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'root'::knob
   function Root_Class_Knob_Base_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.1))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::knob when part State_Hovered
   function Root_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.28))),
      others => <>);

   --  Base style for class 'root'::scroll
   function Root_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.06)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::scroll when part State_Hovered
   function Root_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.16)),
      others => <>);

   --  Base style for class 'row'
   function Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (200, 210, 255)),
      Font_Size => Set_Font (Px (20.0)),
      others => <>);

   --  Base style for class 'grad-card'::label
   function Grad_Card_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (11.0)),
      Left => Set_Left (Inset (Px (8.0))),
      Top => Set_Top (Inset (Px (78.0))),
      others => <>);

   --  Base style for class 'grad-v'
   function Grad_V_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-h'
   function Grad_H_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (RGB (234, 179, 8)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-default'
   function Grad_Default_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (RGB (168, 85, 247)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-up'
   function Grad_Up_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (0.0, [Gradient_Stop_Auto (RGB (15, 23, 42)), Gradient_Stop_Auto (RGB (99, 102, 241)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-left'
   function Grad_Left_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (270.0, [Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-diag'
   function Grad_Diag_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (139, 92, 246)), Gradient_Stop_Auto (RGB (236, 72, 153)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-diag-tr'
   function Grad_Diag_Tr_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (45.0, [Gradient_Stop_Auto (RGB (14, 165, 233)), Gradient_Stop_Auto (RGB (99, 102, 241)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-diag-bl'
   function Grad_Diag_Bl_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (225.0, [Gradient_Stop_Auto (RGB (250, 204, 21)), Gradient_Stop_Auto (RGB (34, 197, 94)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-diag-rev'
   function Grad_Diag_Rev_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (315.0, [Gradient_Stop_Auto (RGB (244, 114, 182)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-45'
   function Grad_45_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (45.0, [Gradient_Stop_Auto (RGB (6, 182, 212)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-135'
   function Grad_135_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-turn'
   function Grad_Turn_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (6, 182, 212)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-rad'
   function Grad_Rad_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0002104591497, [Gradient_Stop_Auto (RGB (236, 72, 153)), Gradient_Stop_Auto (RGB (99, 102, 241)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-grad'
   function Grad_Grad_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-alpha'
   function Grad_Alpha_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Color => Set_Bg (RGB (220, 38, 38)),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (0, 0, 0, 0.0)), Gradient_Stop_Auto (RGBA (0, 0, 0, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grad-3stop'
   function Grad_3stop_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (RGB (234, 179, 8)), Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 3)),
      Border_Radius => Set (Radius (Px (0.0))),
      others => <>);

   --  Base style for class 'grad-pos'
   function Grad_Pos_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_At (RGB (59, 130, 246), 0.0), Gradient_Stop_At (RGB (139, 92, 246), 0.3), Gradient_Stop_At (RGB (236, 72, 153), 1.0), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 3)),
      Border_Radius => Set (Radius (Px (0.0))),
      others => <>);

   --  Base style for class 'grad-edge'
   function Grad_Edge_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_At (RGB (239, 68, 68), 0.2), Gradient_Stop_At (RGB (59, 130, 246), 0.8), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (0.0))),
      others => <>);

   --  Base style for class 'grad-16stop'
   function Grad_16stop_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_At (RGB (239, 68, 68), 0.0), Gradient_Stop_At (RGB (249, 115, 22), 0.06666699999999999), Gradient_Stop_At (RGB (245, 158, 11), 0.133333), Gradient_Stop_At (RGB (234, 179, 8), 0.2), Gradient_Stop_At (RGB (163, 230, 53), 0.266667), Gradient_Stop_At (RGB (34, 197, 94), 0.333333), Gradient_Stop_At (RGB (16, 185, 129), 0.4), Gradient_Stop_At (RGB (20, 184, 166), 0.466667), Gradient_Stop_At (RGB (6, 182, 212), 0.5333330000000001), Gradient_Stop_At (RGB (14, 165, 233), 0.6), Gradient_Stop_At (RGB (59, 130, 246), 0.666667), Gradient_Stop_At (RGB (99, 102, 241), 0.7333329999999999), Gradient_Stop_At (RGB (139, 92, 246), 0.8), Gradient_Stop_At (RGB (168, 85, 247), 0.8666670000000001), Gradient_Stop_At (RGB (217, 70, 239), 0.933333), Gradient_Stop_At (RGB (236, 72, 153), 1.0)], 16)),
      Border_Radius => Set (Radius (Px (0.0))),
      others => <>);

   --  Base style for class 'grad-pill'
   function Grad_Pill_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (245, 158, 11)), Gradient_Stop_Auto (RGB (239, 68, 68)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (50.0))),
      others => <>);

   --  Base style for class 'grad-pill'::label
   function Grad_Pill_Class_Label_Base_Style return Style_Rules is
     (
      Left => Set_Left (Inset (Px (32.0))),
      others => <>);

   --  Base style for class 'grad-border'
   function Grad_Border_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (100.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (135.0, [Gradient_Stop_Auto (RGB (16, 185, 129)), Gradient_Stop_Auto (RGB (59, 130, 246)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Width => Set (Border_Width (Px (4.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (200, 210, 255))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Complete widget style for class 'root'
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'root'::knob
   function Root_Class_Knob_Widget return Widget_Style is
     (From (Root_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Knob_Part_Hovered_Style)
     .Build);

   --  Complete widget style for class 'root'::scroll
   function Root_Class_Scroll_Widget return Widget_Style is
     (From (Root_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Scroll_Part_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'row'
   function Row_Class_Widget return Widget_Style is
     (From (Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'row'
   function Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-card'::label
   function Grad_Card_Class_Label_Widget return Widget_Style is
     (From (Grad_Card_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-card'
   function Grad_Card_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Grad_Card_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-v'
   function Grad_V_Class_Widget return Widget_Style is
     (From (Grad_V_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-v'
   function Grad_V_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_V_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-h'
   function Grad_H_Class_Widget return Widget_Style is
     (From (Grad_H_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-h'
   function Grad_H_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_H_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-default'
   function Grad_Default_Class_Widget return Widget_Style is
     (From (Grad_Default_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-default'
   function Grad_Default_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Default_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-up'
   function Grad_Up_Class_Widget return Widget_Style is
     (From (Grad_Up_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-up'
   function Grad_Up_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Up_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-left'
   function Grad_Left_Class_Widget return Widget_Style is
     (From (Grad_Left_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-left'
   function Grad_Left_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Left_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-diag'
   function Grad_Diag_Class_Widget return Widget_Style is
     (From (Grad_Diag_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-diag'
   function Grad_Diag_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Diag_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-diag-tr'
   function Grad_Diag_Tr_Class_Widget return Widget_Style is
     (From (Grad_Diag_Tr_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-diag-tr'
   function Grad_Diag_Tr_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Diag_Tr_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-diag-bl'
   function Grad_Diag_Bl_Class_Widget return Widget_Style is
     (From (Grad_Diag_Bl_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-diag-bl'
   function Grad_Diag_Bl_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Diag_Bl_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-diag-rev'
   function Grad_Diag_Rev_Class_Widget return Widget_Style is
     (From (Grad_Diag_Rev_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-diag-rev'
   function Grad_Diag_Rev_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Diag_Rev_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-45'
   function Grad_45_Class_Widget return Widget_Style is
     (From (Grad_45_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-45'
   function Grad_45_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_45_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-135'
   function Grad_135_Class_Widget return Widget_Style is
     (From (Grad_135_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-135'
   function Grad_135_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_135_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-turn'
   function Grad_Turn_Class_Widget return Widget_Style is
     (From (Grad_Turn_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-turn'
   function Grad_Turn_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Turn_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-rad'
   function Grad_Rad_Class_Widget return Widget_Style is
     (From (Grad_Rad_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-rad'
   function Grad_Rad_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Rad_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-grad'
   function Grad_Grad_Class_Widget return Widget_Style is
     (From (Grad_Grad_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-grad'
   function Grad_Grad_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Grad_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-alpha'
   function Grad_Alpha_Class_Widget return Widget_Style is
     (From (Grad_Alpha_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-alpha'
   function Grad_Alpha_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Alpha_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-3stop'
   function Grad_3stop_Class_Widget return Widget_Style is
     (From (Grad_3stop_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-3stop'
   function Grad_3stop_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_3stop_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-pos'
   function Grad_Pos_Class_Widget return Widget_Style is
     (From (Grad_Pos_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-pos'
   function Grad_Pos_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Pos_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-edge'
   function Grad_Edge_Class_Widget return Widget_Style is
     (From (Grad_Edge_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-edge'
   function Grad_Edge_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Edge_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-16stop'
   function Grad_16stop_Class_Widget return Widget_Style is
     (From (Grad_16stop_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-16stop'
   function Grad_16stop_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_16stop_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-pill'
   function Grad_Pill_Class_Widget return Widget_Style is
     (From (Grad_Pill_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'grad-pill'::label
   function Grad_Pill_Class_Label_Widget return Widget_Style is
     (From (Grad_Pill_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-pill'
   function Grad_Pill_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Pill_Class_Widget, Enabled => True),
      Label_Part => (Style => Grad_Pill_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grad-border'
   function Grad_Border_Class_Widget return Widget_Style is
     (From (Grad_Border_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grad-border'
   function Grad_Border_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grad_Border_Class_Widget, Enabled => True),
      others => <>
   ]);

end Gradient_Example_Styles;