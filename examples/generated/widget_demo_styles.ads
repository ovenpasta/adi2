--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Widget_Demo_Styles is

   --  Base style for class 'root-box'
   function Root_Box_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (20.0))),
      Background_Color => Set_Bg (RGB (125, 125, 125)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      others => <>);

   --  Base style for class 'top-row'
   function Top_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (20.0))),
      Align_Items => Set (Stretch),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      others => <>);

   --  Base style for class 'card-box'
   function Card_Box_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (C (White)),
      Flex_Grow => Set (1.0),
      Box_Shadow => Set (Shadow (Px (0.0), Px (4.0), Px (12.0), Px (0.0), RGBA (0, 0, 0, 0.5))),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Margin => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Border_Width => Set (Border_Width (Px (2.0), Px (2.0), Px (2.0), Px (8.0))),
      Border_Style => Set (Border_Style (Solid, Solid, Dashed, Solid)),
      Border_Color => Set (Border_Color (RGB (59, 130, 246), RGB (200, 200, 200), RGB (200, 200, 200), RGB (200, 200, 200))),
      Border_Radius => Set (Radius (Px (20.0), Px (16.0), Px (2.0), Px (8.0))),
      others => <>);

   --  Base style for class 'card-box-2'
   function Card_Box_2_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGB (255, 247, 237)),
      Flex_Grow => Set (1.0),
      Box_Shadow => Set (Shadow (Px (0.0), Px (4.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.25))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (8.0), Px (4.0), Px (6.0), Px (10.0))),
      Border_Style => Set (Border_Style (Double, Dashed, Solid, Solid)),
      Border_Color => Set (Border_Color (RGB (234, 88, 12), RGB (249, 115, 22), RGB (251, 191, 36), RGB (194, 65, 12))),
      Border_Radius => Set (Radius (Px (16.0), Px (28.0), Px (16.0), Px (4.0))),
      others => <>);

   --  Base style for class 'inner-box'
   function Inner_Box_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (251, 146, 60)),
      Width => Set (Size (Px (100.0))),
      Height => Set (Size (Px (100.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'bottom-row'
   function Bottom_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (20.0))),
      Align_Items => Set (Stretch),
      others => <>);

   --  Base style for class 'button-box'
   function Button_Box_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Min_Width => Set (Size (Px (150.0))),
      Min_Height => Set (Size (Px (50.0))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (0.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'button-box' when widget State_Hovered
   function Button_Box_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>);

   --  Style for class 'button-box' when widget State_Pressed
   function Button_Box_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      others => <>);

   --  Base style for class 'hover-box'
   function Hover_Box_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (0, 255, 0)),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (80.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (22, 163, 74))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Style for class 'hover-box' when widget State_Hovered
   function Hover_Box_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 0, 0)),
      Border_Width => Set (Border_Width (Px (6.0), Px (0.0), Px (0.0), Px (0.0))),
      Border_Color => Set (Border_Color (RGB (21, 128, 61), RGB (5, 150, 105), RGB (21, 128, 61), RGB (21, 128, 61))),
      others => <>);

   --  Base style for class 'label-box'
   function Label_Box_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Background_Image => Set_Bg_Image (Background_Image_URL ("bg.jpg")),
      Object_Fit => Set (Fit_Contain),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (50.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (200, 200, 200))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'title-label'
   function Title_Label_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (240, 240, 250)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'title-label'::label
   function Title_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (30, 30, 30)),
      Font_Size => Set_Font (Px (18.0)),
      Text_Align => Set (Text_Center),
      Vertical_Align => Set (VA_Middle),
      others => <>);

   --  Complete widget style for class 'root-box'
   function Root_Box_Class_Widget return Widget_Style is
     (From (Root_Box_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'root-box'
   function Root_Box_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Box_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'top-row'
   function Top_Row_Class_Widget return Widget_Style is
     (From (Top_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'top-row'
   function Top_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Top_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-box'
   function Card_Box_Class_Widget return Widget_Style is
     (From (Card_Box_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-box'
   function Card_Box_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Box_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-box-2'
   function Card_Box_2_Class_Widget return Widget_Style is
     (From (Card_Box_2_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-box-2'
   function Card_Box_2_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Box_2_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'inner-box'
   function Inner_Box_Class_Widget return Widget_Style is
     (From (Inner_Box_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'inner-box'
   function Inner_Box_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Inner_Box_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'bottom-row'
   function Bottom_Row_Class_Widget return Widget_Style is
     (From (Bottom_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'bottom-row'
   function Bottom_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Bottom_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'button-box'
   function Button_Box_Class_Widget return Widget_Style is
     (From (Button_Box_Class_Base_Style)
     .On (When_State (State_Hovered), Button_Box_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Button_Box_Class_Widget_Pressed_Style)
     .Build);

   --  Part styles bundle for class 'button-box'
   function Button_Box_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Button_Box_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'hover-box'
   function Hover_Box_Class_Widget return Widget_Style is
     (From (Hover_Box_Class_Base_Style)
     .On (When_State (State_Hovered), Hover_Box_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'hover-box'
   function Hover_Box_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Hover_Box_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'label-box'
   function Label_Box_Class_Widget return Widget_Style is
     (From (Label_Box_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'label-box'
   function Label_Box_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label_Box_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title-label'
   function Title_Label_Class_Widget return Widget_Style is
     (From (Title_Label_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'title-label'::label
   function Title_Label_Class_Label_Widget return Widget_Style is
     (From (Title_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title-label'
   function Title_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Title_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

end Widget_Demo_Styles;