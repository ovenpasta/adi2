--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Overflow_Example_Styles is

   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (20, 24, 31)),
      Padding => Set (CSS_Box (Px (18.0), Px (18.0), Px (18.0), Px (18.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'hint'
   function Hint_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'hint'::label
   function Hint_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (189, 205, 230)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'panels'
   function Panels_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (18.0))),
      Align_Items => Set (Stretch),
      Flex_Grow => Set (1.0),
      others => <>);

   --  Base style for class 'panel'
   function Panel_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (10.0))),
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGB (31, 41, 55)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'panel-title'
   function Panel_Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'panel-title'::label
   function Panel_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (224, 231, 255)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'clip-visible'
   function Clip_Visible_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Height => Set (Size (Px (120.0))),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGBA (96, 165, 250, 0.16)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (96, 165, 250))),
      Border_Radius => Set (Radius (Px (8.0))),
      Overflow_X => Set_Overflow_X (Overflow_Visible),
      Overflow_Y => Set_Overflow_Y (Overflow_Visible),
      others => <>);

   --  Base style for class 'clip-hidden'
   function Clip_Hidden_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Height => Set (Size (Px (120.0))),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGBA (74, 222, 128, 0.16)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (74, 222, 128))),
      Border_Radius => Set (Radius (Px (8.0))),
      Overflow_X => Set_Overflow_X (Overflow_Hidden),
      Overflow_Y => Set_Overflow_Y (Overflow_Hidden),
      others => <>);

   --  Base style for class 'content-stack'
   function Content_Stack_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      others => <>);

   --  Base style for class 'long-line'
   function Long_Line_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (430.0))),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.45)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'long-line'::label
   function Long_Line_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (12.0)),
      White_Space => Set (WS_Nowrap),
      others => <>);

   --  Base style for class 'wrap-line'
   function Wrap_Line_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Pct (100.0))),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.3)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (100, 116, 139))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'wrap-line'::label
   function Wrap_Line_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (12.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      White_Space => Set (WS_Normal),
      others => <>);

   --  Base style for class 'item-a'
   function Item_A_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (56.0))),
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'item-b'
   function Item_B_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (56.0))),
      Background_Color => Set_Bg (RGB (245, 158, 11)),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'item-c'
   function Item_C_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (56.0))),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'item-d'
   function Item_D_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (56.0))),
      Background_Color => Set_Bg (RGB (16, 185, 129)),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Complete widget style for class 'root'
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'
   function Title_Class_Widget return Widget_Style is
     (From (Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'hint'
   function Hint_Class_Widget return Widget_Style is
     (From (Hint_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'hint'::label
   function Hint_Class_Label_Widget return Widget_Style is
     (From (Hint_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'hint'
   function Hint_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'panels'
   function Panels_Class_Widget return Widget_Style is
     (From (Panels_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'panels'
   function Panels_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Panels_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'panel'
   function Panel_Class_Widget return Widget_Style is
     (From (Panel_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'panel'
   function Panel_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'panel-title'
   function Panel_Title_Class_Widget return Widget_Style is
     (From (Panel_Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'panel-title'::label
   function Panel_Title_Class_Label_Widget return Widget_Style is
     (From (Panel_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'panel-title'
   function Panel_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Panel_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Panel_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'clip-visible'
   function Clip_Visible_Class_Widget return Widget_Style is
     (From (Clip_Visible_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'clip-visible'
   function Clip_Visible_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Clip_Visible_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'clip-hidden'
   function Clip_Hidden_Class_Widget return Widget_Style is
     (From (Clip_Hidden_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'clip-hidden'
   function Clip_Hidden_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Clip_Hidden_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'content-stack'
   function Content_Stack_Class_Widget return Widget_Style is
     (From (Content_Stack_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'content-stack'
   function Content_Stack_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Content_Stack_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'long-line'
   function Long_Line_Class_Widget return Widget_Style is
     (From (Long_Line_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'long-line'::label
   function Long_Line_Class_Label_Widget return Widget_Style is
     (From (Long_Line_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'long-line'
   function Long_Line_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Long_Line_Class_Widget, Enabled => True),
      Label_Part => (Style => Long_Line_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'wrap-line'
   function Wrap_Line_Class_Widget return Widget_Style is
     (From (Wrap_Line_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'wrap-line'::label
   function Wrap_Line_Class_Label_Widget return Widget_Style is
     (From (Wrap_Line_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'wrap-line'
   function Wrap_Line_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Wrap_Line_Class_Widget, Enabled => True),
      Label_Part => (Style => Wrap_Line_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'item-a'
   function Item_A_Class_Widget return Widget_Style is
     (From (Item_A_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'item-a'
   function Item_A_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Item_A_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'item-b'
   function Item_B_Class_Widget return Widget_Style is
     (From (Item_B_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'item-b'
   function Item_B_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Item_B_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'item-c'
   function Item_C_Class_Widget return Widget_Style is
     (From (Item_C_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'item-c'
   function Item_C_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Item_C_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'item-d'
   function Item_D_Class_Widget return Widget_Style is
     (From (Item_D_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'item-d'
   function Item_D_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Item_D_Class_Widget, Enabled => True),
      others => <>
   ]);

end Overflow_Example_Styles;