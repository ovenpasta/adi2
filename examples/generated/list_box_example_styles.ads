--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package List_Box_Example_Styles is

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
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (242, 245, 248)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      others => <>);

   --  Base style for class 'panels'
   function Panels_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (580.0))),
      others => <>);

   --  Base style for class 'controls-row'
   function Controls_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_Start),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (14.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (220, 226, 234))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'panel'
   function Panel_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Width => Set (Size (Px (476.0))),
      Height => Set (Size (Px (580.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (220, 226, 234))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'panel-title'
   function Panel_Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'panel-title'::label
   function Panel_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (41, 49, 64)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      White_Space => Set (WS_Nowrap),
      Text_Overflow => Set (Overflow_Clip),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (83, 97, 120)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Overflow => Set (Overflow_Clip),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'inertia-label'::label
   function Inertia_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (41, 49, 64)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      White_Space => Set (WS_Nowrap),
      Text_Overflow => Set (Overflow_Clip),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'debug-label'::label
   function Debug_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (41, 49, 64)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      White_Space => Set (WS_Nowrap),
      Text_Overflow => Set (Overflow_Clip),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'inertia-switch'
   function Inertia_Switch_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (56.0))),
      Height => Set (Size (Px (30.0))),
      Background_Color => Set_Bg (RGB (203, 213, 225)),
      Transition => Set ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Style for class 'inertia-switch' when widget State_Hovered
   function Inertia_Switch_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (191, 201, 216)),
      others => <>);

   --  Style for class 'inertia-switch' when widget State_Selected
   function Inertia_Switch_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>);

   --  Style for class 'inertia-switch' when widget State_Selected, widget State_Hovered
   function Inertia_Switch_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>);

   --  Base style for class 'inertia-switch'::knob
   function Inertia_Switch_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (C (White)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (203, 213, 225))),
      Border_Radius => Set (Radius (Px (13.0))),
      others => <>);

   --  Base style for class 'debug-switch'
   function Debug_Switch_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (56.0))),
      Height => Set (Size (Px (30.0))),
      Background_Color => Set_Bg (RGB (203, 213, 225)),
      Transition => Set ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Style for class 'debug-switch' when widget State_Hovered
   function Debug_Switch_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (191, 201, 216)),
      others => <>);

   --  Style for class 'debug-switch' when widget State_Selected
   function Debug_Switch_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (22, 163, 74)),
      Border_Color => Set (Border_Color (RGB (21, 128, 61))),
      others => <>);

   --  Style for class 'debug-switch' when widget State_Selected, widget State_Hovered
   function Debug_Switch_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (21, 128, 61)),
      others => <>);

   --  Base style for class 'debug-switch'::knob
   function Debug_Switch_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (C (White)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (203, 213, 225))),
      Border_Radius => Set (Radius (Px (13.0))),
      others => <>);

   --  Base style for class 'listbox'
   function Listbox_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (247, 249, 252)),
      Height => Set (Size (Px (500.0))),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (4.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (213, 221, 231))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'listbox'::knob
   function Listbox_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.78)),
      Transition => Set ((Duration => 0.26, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'listbox'::knob when part State_Hovered
   function Listbox_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.94)),
      others => <>);

   --  Style for class 'listbox'::knob when part State_Pressed
   function Listbox_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (71, 85, 105, 1.0)),
      others => <>);

   --  Base style for class 'listbox'::scroll
   function Listbox_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.22)),
      Transition => Set ((Duration => 0.26, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'listbox'::scroll when part State_Hovered
   function Listbox_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.38)),
      others => <>);

   --  Style for class 'listbox'::scroll when part State_Pressed
   function Listbox_Class_Scroll_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.52)),
      others => <>);

   --  Base style for class 'listbox-multi'
   function Listbox_Multi_Class_Base_Style return Style_Rules is
     (
      Gap => Set (Gap (Px (6.0))),
      others => <>);

   --  Base style for class 'listbox-grid'
   function Listbox_Grid_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      others => <>);

   --  Base style for class 'label-row'
   function Label_Row_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (10.0), Px (0.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (220, 228, 236))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'label-row' when widget State_Hovered
   function Label_Row_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (235, 241, 250)),
      Border_Color => Set (Border_Color (RGB (186, 200, 220))),
      others => <>);

   --  Style for class 'label-row' when widget State_Selected
   function Label_Row_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (62, 118, 210)),
      Border_Color => Set (Border_Color (RGB (48, 95, 171))),
      others => <>);

   --  Style for class 'label-row' when widget State_Selected, widget State_Hovered
   function Label_Row_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (52, 104, 192)),
      Border_Color => Set (Border_Color (RGB (40, 82, 152))),
      others => <>);

   --  Base style for class 'label-row'::label
   function Label_Row_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (43, 52, 67)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Style for class 'label-row'::label when widget State_Selected
   function Label_Row_Class_Label_Widget_Selected_Style return Style_Rules is
     (
      Color => Set (C (White)),
      others => <>);

   --  Base style for class 'card-row'
   function Card_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (63, 115, 176)),
      Height => Set (Size (Px (44.0))),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (10.0), Px (0.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (28, 33, 45))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'card-row' when widget State_Hovered
   function Card_Row_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (75, 132, 198)),
      Border_Color => Set (Border_Color (RGB (40, 48, 65))),
      others => <>);

   --  Style for class 'card-row' when widget State_Selected
   function Card_Row_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (244, 166, 77)),
      Border_Color => Set (Border_Color (RGB (190, 120, 35))),
      others => <>);

   --  Style for class 'card-row' when widget State_Selected, widget State_Hovered
   function Card_Row_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (248, 178, 100)),
      Border_Color => Set (Border_Color (RGB (205, 138, 52))),
      others => <>);

   --  Base style for class 'card-row-title'::label
   function Card_Row_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Base style for class 'grid-cell'
   function Grid_Cell_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Height => Set (Size (Px (50.0))),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (6.0), Px (12.0), Px (6.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (220, 228, 236))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'grid-cell' when widget State_Hovered
   function Grid_Cell_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (235, 241, 250)),
      Border_Color => Set (Border_Color (RGB (186, 200, 220))),
      others => <>);

   --  Style for class 'grid-cell' when widget State_Selected
   function Grid_Cell_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (62, 118, 210)),
      Border_Color => Set (Border_Color (RGB (48, 95, 171))),
      others => <>);

   --  Style for class 'grid-cell' when widget State_Selected, widget State_Hovered
   function Grid_Cell_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (52, 104, 192)),
      Border_Color => Set (Border_Color (RGB (40, 82, 152))),
      others => <>);

   --  Base style for class 'grid-cell'::label
   function Grid_Cell_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (43, 52, 67)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Style for class 'grid-cell'::label when widget State_Selected
   function Grid_Cell_Class_Label_Widget_Selected_Style return Style_Rules is
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

   --  Complete widget style for class 'controls-row'
   function Controls_Row_Class_Widget return Widget_Style is
     (From (Controls_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'controls-row'
   function Controls_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Controls_Row_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'inertia-label'::label
   function Inertia_Label_Class_Label_Widget return Widget_Style is
     (From (Inertia_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'inertia-label'
   function Inertia_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Inertia_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'debug-label'::label
   function Debug_Label_Class_Label_Widget return Widget_Style is
     (From (Debug_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'debug-label'
   function Debug_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Debug_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'inertia-switch'
   function Inertia_Switch_Class_Widget return Widget_Style is
     (From (Inertia_Switch_Class_Base_Style)
     .On (When_State (State_Hovered), Inertia_Switch_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Inertia_Switch_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Inertia_Switch_Class_Widget_Selected_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'inertia-switch'::knob
   function Inertia_Switch_Class_Knob_Widget return Widget_Style is
     (From (Inertia_Switch_Class_Knob_Base_Style)
     .Build);

   --  Part styles bundle for class 'inertia-switch'
   function Inertia_Switch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Inertia_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Inertia_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'debug-switch'
   function Debug_Switch_Class_Widget return Widget_Style is
     (From (Debug_Switch_Class_Base_Style)
     .On (When_State (State_Hovered), Debug_Switch_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Debug_Switch_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Debug_Switch_Class_Widget_Selected_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'debug-switch'::knob
   function Debug_Switch_Class_Knob_Widget return Widget_Style is
     (From (Debug_Switch_Class_Knob_Base_Style)
     .Build);

   --  Part styles bundle for class 'debug-switch'
   function Debug_Switch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Debug_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Debug_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'listbox'
   function Listbox_Class_Widget return Widget_Style is
     (From (Listbox_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'listbox'::knob
   function Listbox_Class_Knob_Widget return Widget_Style is
     (From (Listbox_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Listbox_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Listbox_Class_Knob_Part_Pressed_Style)
     .Build);

   --  Complete widget style for class 'listbox'::scroll
   function Listbox_Class_Scroll_Widget return Widget_Style is
     (From (Listbox_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Listbox_Class_Scroll_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Listbox_Class_Scroll_Part_Pressed_Style)
     .Build);

   --  Part styles bundle for class 'listbox'
   function Listbox_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Listbox_Class_Widget, Enabled => True),
      Knob_Part => (Style => Listbox_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Listbox_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'listbox-multi'
   function Listbox_Multi_Class_Widget return Widget_Style is
     (From (Listbox_Multi_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'listbox-multi'
   function Listbox_Multi_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Listbox_Multi_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'listbox-grid'
   function Listbox_Grid_Class_Widget return Widget_Style is
     (From (Listbox_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'listbox-grid'
   function Listbox_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Listbox_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'label-row'
   function Label_Row_Class_Widget return Widget_Style is
     (From (Label_Row_Class_Base_Style)
     .On (When_State (State_Hovered), Label_Row_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Label_Row_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Label_Row_Class_Widget_Selected_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'label-row'::label
   function Label_Row_Class_Label_Widget return Widget_Style is
     (From (Label_Row_Class_Label_Base_Style)
     .On (When_State (State_Selected), Label_Row_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'label-row'
   function Label_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label_Row_Class_Widget, Enabled => True),
      Label_Part => (Style => Label_Row_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-row'
   function Card_Row_Class_Widget return Widget_Style is
     (From (Card_Row_Class_Base_Style)
     .On (When_State (State_Hovered), Card_Row_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Card_Row_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Card_Row_Class_Widget_Selected_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'card-row'
   function Card_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-row-title'::label
   function Card_Row_Title_Class_Label_Widget return Widget_Style is
     (From (Card_Row_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-row-title'
   function Card_Row_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Card_Row_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grid-cell'
   function Grid_Cell_Class_Widget return Widget_Style is
     (From (Grid_Cell_Class_Base_Style)
     .On (When_State (State_Hovered), Grid_Cell_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Grid_Cell_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Grid_Cell_Class_Widget_Selected_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'grid-cell'::label
   function Grid_Cell_Class_Label_Widget return Widget_Style is
     (From (Grid_Cell_Class_Label_Base_Style)
     .On (When_State (State_Selected), Grid_Cell_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'grid-cell'
   function Grid_Cell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grid_Cell_Class_Widget, Enabled => True),
      Label_Part => (Style => Grid_Cell_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end List_Box_Example_Styles;