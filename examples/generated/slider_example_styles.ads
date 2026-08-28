--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Slider_Example_Styles is

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

   --  Base style for class 'heading'
   function Heading_Class_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'heading'::label
   function Heading_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      others => <>);

   --  Base style for class 'label'
   function Label_Class_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Px (14.0)),
      Min_Width => Set (Size (Px (100.0))),
      others => <>);

   --  Base style for class 'label'::label
   function Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (186, 194, 222)),
      others => <>);

   --  Base style for class 'value-label'
   function Value_Label_Class_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Px (14.0)),
      Min_Width => Set (Size (Px (60.0))),
      others => <>);

   --  Base style for class 'value-label'::label
   function Value_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (166, 227, 161)),
      others => <>);

   --  Base style for class 'slider'
   function Slider_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (300.0))),
      Height => Set (Size (Px (20.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Style for class 'slider' when widget State_Focused
   function Slider_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (137, 180, 250)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'slider' when widget State_Hovered
   function Slider_Class_Widget_Hovered_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0), RGBA (137, 180, 250, 0.3))),
      others => <>);

   --  Base style for class 'slider'::indicator
   function Slider_Class_Indicator_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (137, 180, 250)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'slider'::knob
   function Slider_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (20.0))),
      Background_Color => Set_Bg (RGB (205, 214, 244)),
      Border_Radius => Set (Radius (Pct (50.0))),
      others => <>);

   --  Style for class 'slider'::knob when part State_Hovered
   function Slider_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (245, 224, 220)),
      others => <>);

   --  Style for class 'slider'::knob when part State_Pressed
   function Slider_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (137, 180, 250)),
      others => <>);

   --  Base style for class 'slider-vertical'
   function Slider_Vertical_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (20.0))),
      Height => Set (Size (Px (150.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'slider-vertical'::indicator
   function Slider_Vertical_Class_Indicator_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (243, 139, 168)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'slider-vertical'::knob
   function Slider_Vertical_Class_Knob_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (20.0))),
      Background_Color => Set_Bg (RGB (205, 214, 244)),
      Border_Radius => Set (Radius (Pct (50.0))),
      others => <>);

   --  Base style for class 'value-input'
   function Value_Input_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (80.0))),
      Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Font_Size => Set_Font (Px (14.0)),
      Padding => Set (CSS_Box (Px (2.0), Px (6.0), Px (2.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (88, 91, 112))),
      Border_Radius => Set (Radius (Px (4.0))),
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

   --  Base style for class 'slider-gradient'
   function Slider_Gradient_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (300.0))),
      Height => Set (Size (Px (24.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Style for class 'slider-gradient' when widget State_Hovered
   function Slider_Gradient_Class_Widget_Hovered_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0), RGBA (243, 139, 168, 0.3))),
      others => <>);

   --  Base style for class 'slider-gradient'::indicator
   function Slider_Gradient_Class_Indicator_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      others => <>);

   --  Base style for class 'slider-gradient'::knob
   function Slider_Gradient_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (22.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (255, 255, 255)), Gradient_Stop_Auto (RGB (147, 153, 178)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (30, 30, 46))),
      Border_Radius => Set (Radius (Pct (50.0))),
      others => <>);

   --  Style for class 'slider-gradient'::knob when part State_Hovered
   function Slider_Gradient_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (255, 255, 255)), Gradient_Stop_Auto (RGB (245, 224, 220)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      others => <>);

   --  Style for class 'slider-gradient'::knob when part State_Pressed
   function Slider_Gradient_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGB (245, 224, 220)), Gradient_Stop_Auto (RGB (243, 139, 168)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      others => <>);

   --  Base style for class 'slider-gradient'::scroll
   function Slider_Gradient_Class_Scroll_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (6.0))),
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (30, 30, 46)), Gradient_Stop_Auto (RGB (243, 139, 168)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Radius => Set (Radius (Px (3.0))),
      others => <>);

   --  Base style for class 'slider-square'
   function Slider_Square_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (300.0))),
      Height => Set (Size (Px (24.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Style for class 'slider-square' when widget State_Hovered
   function Slider_Square_Class_Widget_Hovered_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0), RGBA (166, 227, 161, 0.3))),
      others => <>);

   --  Base style for class 'slider-square'::indicator
   function Slider_Square_Class_Indicator_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (166, 227, 161)),
      others => <>);

   --  Base style for class 'slider-square'::knob
   function Slider_Square_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (12.0))),
      Background_Color => Set_Bg (RGB (205, 214, 244)),
      Border_Radius => Set (Radius (Px (2.0))),
      others => <>);

   --  Style for class 'slider-square'::knob when part State_Hovered
   function Slider_Square_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (245, 224, 220)),
      others => <>);

   --  Style for class 'slider-square'::knob when part State_Pressed
   function Slider_Square_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (166, 227, 161)),
      others => <>);

   --  Base style for class 'slider-square'::scroll
   function Slider_Square_Class_Scroll_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (6.0))),
      Background_Color => Set_Bg (RGB (49, 50, 68)),
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
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section'
   function Section_Class_Widget return Widget_Style is
     (From (Section_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'section'
   function Section_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'heading'
   function Heading_Class_Widget return Widget_Style is
     (From (Heading_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'heading'::label
   function Heading_Class_Label_Widget return Widget_Style is
     (From (Heading_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'heading'
   function Heading_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Heading_Class_Widget, Enabled => True),
      Label_Part => (Style => Heading_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'label'
   function Label_Class_Widget return Widget_Style is
     (From (Label_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'label'::label
   function Label_Class_Label_Widget return Widget_Style is
     (From (Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'label'
   function Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'value-label'
   function Value_Label_Class_Widget return Widget_Style is
     (From (Value_Label_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'value-label'::label
   function Value_Label_Class_Label_Widget return Widget_Style is
     (From (Value_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'value-label'
   function Value_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Value_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Value_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'slider'
   function Slider_Class_Widget return Widget_Style is
     (From (Slider_Class_Base_Style)
     .On (When_State (State_Focused), Slider_Class_Widget_Focused_Style)
     .On (When_State (State_Hovered), Slider_Class_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'slider'::indicator
   function Slider_Class_Indicator_Widget return Widget_Style is
     (From (Slider_Class_Indicator_Base_Style)
     .Build);

   --  Complete widget style for class 'slider'::knob
   function Slider_Class_Knob_Widget return Widget_Style is
     (From (Slider_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Slider_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Slider_Class_Knob_Part_Pressed_Style)
     .Build);

   --  Part styles bundle for class 'slider'
   function Slider_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Slider_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Slider_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Slider_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'slider-vertical'
   function Slider_Vertical_Class_Widget return Widget_Style is
     (From (Slider_Vertical_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'slider-vertical'::indicator
   function Slider_Vertical_Class_Indicator_Widget return Widget_Style is
     (From (Slider_Vertical_Class_Indicator_Base_Style)
     .Build);

   --  Complete widget style for class 'slider-vertical'::knob
   function Slider_Vertical_Class_Knob_Widget return Widget_Style is
     (From (Slider_Vertical_Class_Knob_Base_Style)
     .Build);

   --  Part styles bundle for class 'slider-vertical'
   function Slider_Vertical_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Slider_Vertical_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Slider_Vertical_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Slider_Vertical_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'value-input'
   function Value_Input_Class_Widget return Widget_Style is
     (From (Value_Input_Class_Base_Style)
     .On (When_State (State_Focused), Value_Input_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'value-input'::cursor
   function Value_Input_Class_Cursor_Widget return Widget_Style is
     (From (Value_Input_Class_Cursor_Base_Style)
     .Build);

   --  Complete widget style for class 'value-input'::selected
   function Value_Input_Class_Selected_Widget return Widget_Style is
     (From (Value_Input_Class_Selected_Base_Style)
     .Build);

   --  Complete widget style for class 'value-input'::text
   function Value_Input_Class_Text_Widget return Widget_Style is
     (From (Value_Input_Class_Text_Base_Style)
     .Build);

   --  Part styles bundle for class 'value-input'
   function Value_Input_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Value_Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Value_Input_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Value_Input_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Value_Input_Class_Text_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'slider-gradient'
   function Slider_Gradient_Class_Widget return Widget_Style is
     (From (Slider_Gradient_Class_Base_Style)
     .On (When_State (State_Hovered), Slider_Gradient_Class_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'slider-gradient'::indicator
   function Slider_Gradient_Class_Indicator_Widget return Widget_Style is
     (From (Slider_Gradient_Class_Indicator_Base_Style)
     .Build);

   --  Complete widget style for class 'slider-gradient'::knob
   function Slider_Gradient_Class_Knob_Widget return Widget_Style is
     (From (Slider_Gradient_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Slider_Gradient_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Slider_Gradient_Class_Knob_Part_Pressed_Style)
     .Build);

   --  Complete widget style for class 'slider-gradient'::scroll
   function Slider_Gradient_Class_Scroll_Widget return Widget_Style is
     (From (Slider_Gradient_Class_Scroll_Base_Style)
     .Build);

   --  Part styles bundle for class 'slider-gradient'
   function Slider_Gradient_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Slider_Gradient_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Slider_Gradient_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Slider_Gradient_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Slider_Gradient_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'slider-square'
   function Slider_Square_Class_Widget return Widget_Style is
     (From (Slider_Square_Class_Base_Style)
     .On (When_State (State_Hovered), Slider_Square_Class_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'slider-square'::indicator
   function Slider_Square_Class_Indicator_Widget return Widget_Style is
     (From (Slider_Square_Class_Indicator_Base_Style)
     .Build);

   --  Complete widget style for class 'slider-square'::knob
   function Slider_Square_Class_Knob_Widget return Widget_Style is
     (From (Slider_Square_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Slider_Square_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Slider_Square_Class_Knob_Part_Pressed_Style)
     .Build);

   --  Complete widget style for class 'slider-square'::scroll
   function Slider_Square_Class_Scroll_Widget return Widget_Style is
     (From (Slider_Square_Class_Scroll_Base_Style)
     .Build);

   --  Part styles bundle for class 'slider-square'
   function Slider_Square_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Slider_Square_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Slider_Square_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Slider_Square_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Slider_Square_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'context-menu'
   function Context_Menu_Class_Widget return Widget_Style is
     (From (Context_Menu_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'context-menu'
   function Context_Menu_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'context-menu-item'
   function Context_Menu_Item_Class_Widget return Widget_Style is
     (From (Context_Menu_Item_Class_Base_Style)
     .On (When_State (State_Hovered), Context_Menu_Item_Class_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'context-menu-item'::label
   function Context_Menu_Item_Class_Label_Widget return Widget_Style is
     (From (Context_Menu_Item_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'context-menu-item'
   function Context_Menu_Item_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Slider_Example_Styles;