--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Combo_Box_Example_Styles is

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
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (19, 26, 38)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>);

   --  Base style for class 'container'
   function Container_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (22.0), Px (22.0), Px (22.0), Px (22.0))),
      Border_Radius => Set (Radius (Px (10.0))),
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
      Color => Set (RGB (186, 204, 230)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'combo'
   function Combo_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (40.0))),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (248, 250, 252)),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (9.0), Px (10.0), Px (9.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'combo' when widget State_Hovered
   function Combo_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Color => Set (Border_Color (RGB (96, 165, 250))),
      others => <>);

   --  Style for class 'combo' when widget State_Focused
   function Combo_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (37, 99, 235, 0.3))),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>);

   --  Base style for class 'combo'::indicator
   function Combo_Class_Indicator_Base_Style return Style_Rules is
     (
      Color => Set (RGB (71, 85, 105)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Align => Set (Text_Center),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Color))),
      others => <>);

   --  Style for class 'combo'::indicator when widget State_Hovered
   function Combo_Class_Indicator_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (30, 64, 175)),
      others => <>);

   --  Style for class 'combo'::indicator when widget State_Focused
   function Combo_Class_Indicator_Widget_Focused_Style return Style_Rules is
     (
      Color => Set (RGB (30, 58, 138)),
      others => <>);

   --  Base style for class 'combo'::text
   function Combo_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'dropdown'
   function Dropdown_Class_Base_Style return Style_Rules is
     (
      Max_Height => Set (Size (Px (240.0))),
      Background_Color => Set_Bg (RGB (246, 248, 252)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 8, 23, 0.22))),
      Padding => Set (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (191, 201, 216))),
      Border_Radius => Set (Radius (Px (8.0))),
      Overflow_X => Set_Overflow_X (Overflow_Auto),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'dropdown'::knob
   function Dropdown_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.85)),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'dropdown'::knob when part State_Hovered
   function Dropdown_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (51, 65, 85, 0.95)),
      others => <>);

   --  Style for class 'dropdown'::knob when part State_Pressed
   function Dropdown_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (30, 41, 59, 1.0)),
      others => <>);

   --  Base style for class 'dropdown'::scroll
   function Dropdown_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.22)),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'dropdown'::scroll when part State_Hovered
   function Dropdown_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.42)),
      others => <>);

   --  Style for class 'dropdown'::scroll when part State_Pressed
   function Dropdown_Class_Scroll_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.58)),
      others => <>);

   --  Base style for class 'option-row'
   function Option_Row_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (C (White)),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (222, 229, 238))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'option-row' when widget State_Hovered
   function Option_Row_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (239, 246, 255)),
      Border_Color => Set (Border_Color (RGB (147, 197, 253))),
      others => <>);

   --  Style for class 'option-row' when widget State_Selected
   function Option_Row_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (29, 78, 216))),
      others => <>);

   --  Base style for class 'option-row'::label
   function Option_Row_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (14.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Color))),
      others => <>);

   --  Style for class 'option-row'::label when part State_Hovered
   function Option_Row_Class_Label_Part_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (15, 23, 42)),
      others => <>);

   --  Style for class 'option-row'::label when widget State_Selected
   function Option_Row_Class_Label_Widget_Selected_Style return Style_Rules is
     (
      Color => Set (C (White)),
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

   --  Complete widget style for class 'container'
   function Container_Class_Widget return Widget_Style is
     (From (Container_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'container'
   function Container_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'status'::label
   function Status_Class_Label_Widget return Widget_Style is
     (From (Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'status'
   function Status_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'combo'
   function Combo_Class_Widget return Widget_Style is
     (From (Combo_Class_Base_Style)
     .On (When_State (State_Hovered), Combo_Class_Widget_Hovered_Style)
     .On (When_State (State_Focused), Combo_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'combo'::indicator
   function Combo_Class_Indicator_Widget return Widget_Style is
     (From (Combo_Class_Indicator_Base_Style)
     .On (When_State (State_Hovered), Combo_Class_Indicator_Widget_Hovered_Style)
     .On (When_State (State_Focused), Combo_Class_Indicator_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'combo'::text
   function Combo_Class_Text_Widget return Widget_Style is
     (From (Combo_Class_Text_Base_Style)
     .Build);

   --  Part styles bundle for class 'combo'
   function Combo_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Combo_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Combo_Class_Indicator_Widget, Enabled => True),
      Text_Part => (Style => Combo_Class_Text_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dropdown'
   function Dropdown_Class_Widget return Widget_Style is
     (From (Dropdown_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'dropdown'::knob
   function Dropdown_Class_Knob_Widget return Widget_Style is
     (From (Dropdown_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Dropdown_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Dropdown_Class_Knob_Part_Pressed_Style)
     .Build);

   --  Complete widget style for class 'dropdown'::scroll
   function Dropdown_Class_Scroll_Widget return Widget_Style is
     (From (Dropdown_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Dropdown_Class_Scroll_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Dropdown_Class_Scroll_Part_Pressed_Style)
     .Build);

   --  Part styles bundle for class 'dropdown'
   function Dropdown_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dropdown_Class_Widget, Enabled => True),
      Knob_Part => (Style => Dropdown_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Dropdown_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'option-row'
   function Option_Row_Class_Widget return Widget_Style is
     (From (Option_Row_Class_Base_Style)
     .On (When_State (State_Hovered), Option_Row_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Option_Row_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'option-row'::label
   function Option_Row_Class_Label_Widget return Widget_Style is
     (From (Option_Row_Class_Label_Base_Style)
     .On (When_Part_State (State_Hovered), Option_Row_Class_Label_Part_Hovered_Style)
     .On (When_State (State_Selected), Option_Row_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'option-row'
   function Option_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Option_Row_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Row_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

end Combo_Box_Example_Styles;