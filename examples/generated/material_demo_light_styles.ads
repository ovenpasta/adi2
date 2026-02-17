--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Material_Demo_Light_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (255, 251, 254)),
      others => <>
   );

   --  Base style for class 'app-bar'
   App_Bar_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Flex_Shrink => Set (0.0),
      Background_Color => Set_Bg (RGB (255, 251, 254)),
      Padding => Set (CSS_Box (Px (16.0), Px (24.0), Px (16.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'app-title'
   App_Title_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (10.0))),
      others => <>
   );

   --  Base style for class 'app-title'::icon
   App_Title_Class_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (28.0))),
      Height => Set (Size (Px (28.0))),
      others => <>
   );

   --  Base style for class 'app-title'::label
   App_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'nav-bar'
   Nav_Bar_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (4.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Padding => Set (CSS_Box (Px (4.0), Px (16.0), Px (4.0), Px (16.0))),
      others => <>
   );

   --  Base style for class 'nav-btn'
   Nav_Btn_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Border_Radius => Set (Radius (Px (20.0))),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      others => <>
   );

   --  Style for class 'nav-btn' when widget State_Hovered
   Nav_Btn_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      others => <>
   );

   --  Style for class 'nav-btn' when widget State_Focused
   Nav_Btn_Class_Widget_Focused_Style : constant Style_Rules := (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>
   );

   --  Style for class 'nav-btn' when widget State_Selected
   Nav_Btn_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      others => <>
   );

   --  Base style for class 'nav-btn'::label
   Nav_Btn_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Color))),
      others => <>
   );

   --  Style for class 'nav-btn'::label when widget State_Hovered
   Nav_Btn_Class_Label_Widget_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (103, 80, 164)),
      others => <>
   );

   --  Style for class 'nav-btn'::label when widget State_Selected
   Nav_Btn_Class_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (RGB (103, 80, 164)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'pages'
   Pages_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      others => <>
   );

   --  Base style for class 'page'
   Page_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (16.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      others => <>
   );

   --  Base style for class 'card'
   Card_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Radius => Set (Radius (Px (16.0))),
      Gap => Set (Gap (Px (12.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Transition => Set ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'card-title'
   Card_Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for class 'card-title'::label
   Card_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (20.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for class 'card-body'
   Card_Body_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for class 'card-body'::label
   Card_Body_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Normal),
      others => <>
   );

   --  Base style for class 'card-hint'
   Card_Hint_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for class 'card-hint'::label
   Card_Hint_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGBA (73, 69, 79, 0.6)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Normal),
      others => <>
   );

   --  Base style for class 'control-grid'
   Control_Grid_Class_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Gap => Set (Gap (Px (12.0), Px (16.0))),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (4.0), Px (0.0), Px (4.0), Px (0.0))),
      others => <>
   );

   --  Base style for class 'grid-header'::label
   Grid_Header_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGBA (73, 69, 79, 0.6)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for class 'grid-label'::label
   Grid_Label_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      others => <>
   );

   --  Base style for class 'grid-cell'
   Grid_Cell_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Align_Self => Set (Center),
      others => <>
   );

   --  Base style for class 'btn-primary'
   Btn_Primary_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Border_Radius => Set (Radius (Px (20.0))),
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Cursor => Set (Cursor_Pointer),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (3.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      others => <>
   );

   --  Style for class 'btn-primary' when widget State_Hovered
   Btn_Primary_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (122, 100, 180)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (2.0), Px (6.0), Px (0.0), RGBA (0, 0, 0, 0.2))),
      others => <>
   );

   --  Style for class 'btn-primary' when widget State_Pressed
   Btn_Primary_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (85, 64, 140)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (2.0), Px (0.0), RGBA (0, 0, 0, 0.1))),
      others => <>
   );

   --  Style for class 'btn-primary' when widget State_Focused
   Btn_Primary_Class_Widget_Focused_Style : constant Style_Rules := (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (28, 27, 31)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>
   );

   --  Style for class 'btn-primary' when widget State_Disabled
   Btn_Primary_Class_Widget_Disabled_Style : constant Style_Rules := (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>
   );

   --  Base style for class 'btn-primary'::label
   Btn_Primary_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'btn-secondary'
   Btn_Secondary_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Border_Radius => Set (Radius (Px (20.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      others => <>
   );

   --  Style for class 'btn-secondary' when widget State_Hovered
   Btn_Secondary_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.12))),
      others => <>
   );

   --  Style for class 'btn-secondary' when widget State_Pressed
   Btn_Secondary_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.16)),
      Box_Shadow => Set (No_Shadow),
      others => <>
   );

   --  Style for class 'btn-secondary' when widget State_Focused
   Btn_Secondary_Class_Widget_Focused_Style : constant Style_Rules := (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>
   );

   --  Style for class 'btn-secondary' when widget State_Disabled
   Btn_Secondary_Class_Widget_Disabled_Style : constant Style_Rules := (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>
   );

   --  Base style for class 'btn-secondary'::label
   Btn_Secondary_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (103, 80, 164)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'btn-row'
   Btn_Row_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>
   );

   --  Base style for class 'field-label'
   Field_Label_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      Padding => Set (CSS_Box (Px (4.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>
   );

   --  Base style for class 'field-label'::label
   Field_Label_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Medium),
      others => <>
   );

   --  Base style for class 'text-field'
   Text_Field_Class_Base_Style : constant Style_Rules := (
      Border_Radius => Set (Radius (Px (8.0))),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Border_Width => Set (Border_Width (Px (0.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Cursor => Set (Cursor_Text),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (16.0), Px (12.0), Px (16.0))),
      others => <>
   );

   --  Style for class 'text-field' when widget State_Focused
   Text_Field_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>
   );

   --  Style for class 'text-field' when widget State_Disabled
   Text_Field_Class_Widget_Disabled_Style : constant Style_Rules := (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>
   );

   --  Base style for class 'text-field'::cursor
   Text_Field_Class_Cursor_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Width => Set (Size (Px (2.0))),
      others => <>
   );

   --  Base style for class 'text-field'::label
   Text_Field_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'text-field'::selected
   Text_Field_Class_Selected_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.3)),
      others => <>
   );

   --  Base style for class 'combo'
   Combo_Class_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (44.0))),
      Align_Items => Set (Center),
      Border_Radius => Set (Radius (Px (8.0))),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Border_Width => Set (Border_Width (Px (0.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (9.0), Px (16.0), Px (9.0), Px (16.0))),
      others => <>
   );

   --  Style for class 'combo' when widget State_Hovered
   Combo_Class_Widget_Hovered_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (0.0), RGBA (103, 80, 164, 0.12))),
      others => <>
   );

   --  Style for class 'combo' when widget State_Focused
   Combo_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Width => Set (Border_Width (Px (0.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (0.0), RGBA (103, 80, 164, 0.4))),
      others => <>
   );

   --  Style for class 'combo' when widget State_Disabled
   Combo_Class_Widget_Disabled_Style : constant Style_Rules := (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>
   );

   --  Base style for class 'combo'::indicator
   Combo_Class_Indicator_Base_Style : constant Style_Rules := (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>
   );

   --  Base style for class 'combo'::label
   Combo_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'setting-row'
   Setting_Row_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Justify_Content => Set (Space_Between),
      Padding => Set (CSS_Box (Px (8.0), Px (0.0), Px (8.0), Px (0.0))),
      others => <>
   );

   --  Base style for class 'setting-label'
   Setting_Label_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Flex_Grow => Set (1.0),
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for class 'setting-label'::label
   Setting_Label_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Normal),
      others => <>
   );

   --  Base style for class 'setting-switch'
   Setting_Switch_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      Width => Set (Size (Px (52.0))),
      Height => Set (Size (Px (32.0))),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (16.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for class 'setting-switch' when widget State_Selected
   Setting_Switch_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      others => <>
   );

   --  Style for class 'setting-switch' when widget State_Focused
   Setting_Switch_Class_Widget_Focused_Style : constant Style_Rules := (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>
   );

   --  Style for class 'setting-switch' when widget State_Selected, widget State_Focused
   Setting_Switch_Class_Widget_Selected_Widget_Focused_Style : constant Style_Rules := (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>
   );

   --  Style for class 'setting-switch' when widget State_Disabled
   Setting_Switch_Class_Widget_Disabled_Style : constant Style_Rules := (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>
   );

   --  Base style for class 'setting-switch'::knob
   Setting_Switch_Class_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGB (121, 116, 126)),
      Border_Radius => Set (Radius (Px (12.0))),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Margin))),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (0.0), Px (2.0))),
      others => <>
   );

   --  Style for class 'setting-switch'::knob when widget State_Selected
   Setting_Switch_Class_Knob_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (0.0), Px (22.0))),
      others => <>
   );

   --  Base style for class 'combo-dropdown'
   Combo_Dropdown_Class_Base_Style : constant Style_Rules := (
      Max_Height => Set (Size (Px (240.0))),
      Overflow => Set (Overflow_Auto),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (12.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (20.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Padding => Set (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0))),
      others => <>
   );

   --  Base style for class 'combo-option'
   Combo_Option_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Border_Radius => Set (Radius (Px (8.0))),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (14.0), Px (10.0), Px (14.0))),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (2.0), Px (0.0))),
      others => <>
   );

   --  Style for class 'combo-option' when widget State_Hovered
   Combo_Option_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      others => <>
   );

   --  Style for class 'combo-option' when widget State_Selected
   Combo_Option_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      others => <>
   );

   --  Base style for class 'combo-option'::label
   Combo_Option_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Style for class 'combo-option'::label when widget State_Selected
   Combo_Option_Class_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (RGB (103, 80, 164)),
      others => <>
   );

   --  Base style for class 'dialog-backdrop'
   Dialog_Backdrop_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.32)),
      others => <>
   );

   --  Base style for class 'dialog-panel'
   Dialog_Panel_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (16.0))),
      Min_Width => Set (Size (Px (320.0))),
      Max_Width => Set (Size (Px (460.0))),
      Background_Color => Set_Bg (RGB (238, 232, 244)),
      Border_Radius => Set (Radius (Px (28.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (32.0), Px (0.0), RGBA (0, 0, 0, 0.18))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'dialog-message'
   Dialog_Message_Class_Base_Style : constant Style_Rules := (
      Flex_Direction => Set (Row),
      Align_Items => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      others => <>
   );

   --  Base style for class 'dialog-message'::icon
   Dialog_Message_Class_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (32.0))),
      Height => Set (Size (Px (32.0))),
      others => <>
   );

   --  Base style for class 'dialog-message'::label
   Dialog_Message_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for class 'dialog-title'
   Dialog_Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'dialog-title'::label
   Dialog_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for class 'dialog-btn-row'
   Dialog_Btn_Row_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_End),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>
   );

   --  Base style for class 'dialog-btn'
   Dialog_Btn_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Border_Radius => Set (Radius (Px (20.0))),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (24.0), Px (10.0), Px (24.0))),
      others => <>
   );

   --  Style for class 'dialog-btn' when widget State_Hovered
   Dialog_Btn_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      others => <>
   );

   --  Style for class 'dialog-btn' when widget State_Pressed
   Dialog_Btn_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.12)),
      others => <>
   );

   --  Style for class 'dialog-btn' when widget State_Focused
   Dialog_Btn_Class_Widget_Focused_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.12)),
      others => <>
   );

   --  Base style for class 'dialog-btn'::label
   Dialog_Btn_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (103, 80, 164)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'context-menu'
   Context_Menu_Class_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (180.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (8.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (24.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      others => <>
   );

   --  Base style for class 'context-menu-item'
   Context_Menu_Item_Class_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      others => <>
   );

   --  Style for class 'context-menu-item' when widget State_Hovered
   Context_Menu_Item_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.12)),
      others => <>
   );

   --  Base style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'app-bar'
   App_Bar_Class_Widget : constant Widget_Style :=
     From (App_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'app-bar'
   App_Bar_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => App_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'app-title'
   App_Title_Class_Widget : constant Widget_Style :=
     From (App_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'app-title'::icon
   App_Title_Class_Icon_Widget : constant Widget_Style :=
     From (App_Title_Class_Icon_Base_Style)
     .Build;

   --  Complete widget style for class 'app-title'::label
   App_Title_Class_Label_Widget : constant Widget_Style :=
     From (App_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'app-title'
   App_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => App_Title_Class_Widget, Enabled => True),
      Icon_Part => (Style => App_Title_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => App_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'nav-bar'
   Nav_Bar_Class_Widget : constant Widget_Style :=
     From (Nav_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'nav-bar'
   Nav_Bar_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Nav_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'nav-btn'
   Nav_Btn_Class_Widget : constant Widget_Style :=
     From (Nav_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Nav_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Focused), Nav_Btn_Class_Widget_Focused_Style)
     .On (When_State (State_Selected), Nav_Btn_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'nav-btn'::label
   Nav_Btn_Class_Label_Widget : constant Widget_Style :=
     From (Nav_Btn_Class_Label_Base_Style)
     .On (When_State (State_Hovered), Nav_Btn_Class_Label_Widget_Hovered_Style)
     .On (When_State (State_Selected), Nav_Btn_Class_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for class 'nav-btn'
   Nav_Btn_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Nav_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Nav_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'pages'
   Pages_Class_Widget : constant Widget_Style :=
     From (Pages_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'pages'
   Pages_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Pages_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page'
   Page_Class_Widget : constant Widget_Style :=
     From (Page_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page'
   Page_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card'
   Card_Class_Widget : constant Widget_Style :=
     From (Card_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'card'
   Card_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-title'
   Card_Title_Class_Widget : constant Widget_Style :=
     From (Card_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'card-title'::label
   Card_Title_Class_Label_Widget : constant Widget_Style :=
     From (Card_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'card-title'
   Card_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-body'
   Card_Body_Class_Widget : constant Widget_Style :=
     From (Card_Body_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'card-body'::label
   Card_Body_Class_Label_Widget : constant Widget_Style :=
     From (Card_Body_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'card-body'
   Card_Body_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Body_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Body_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-hint'
   Card_Hint_Class_Widget : constant Widget_Style :=
     From (Card_Hint_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'card-hint'::label
   Card_Hint_Class_Label_Widget : constant Widget_Style :=
     From (Card_Hint_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'card-hint'
   Card_Hint_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'control-grid'
   Control_Grid_Class_Widget : constant Widget_Style :=
     From (Control_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'control-grid'
   Control_Grid_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Control_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'grid-header'::label
   Grid_Header_Class_Label_Widget : constant Widget_Style :=
     From (Grid_Header_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'grid-header'
   Grid_Header_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Grid_Header_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'grid-label'::label
   Grid_Label_Class_Label_Widget : constant Widget_Style :=
     From (Grid_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'grid-label'
   Grid_Label_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Grid_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'grid-cell'
   Grid_Cell_Class_Widget : constant Widget_Style :=
     From (Grid_Cell_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'grid-cell'
   Grid_Cell_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Grid_Cell_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'btn-primary'
   Btn_Primary_Class_Widget : constant Widget_Style :=
     From (Btn_Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Btn_Primary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Primary_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Btn_Primary_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Btn_Primary_Class_Widget_Disabled_Style)
     .Build;

   --  Complete widget style for class 'btn-primary'::label
   Btn_Primary_Class_Label_Widget : constant Widget_Style :=
     From (Btn_Primary_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'btn-primary'
   Btn_Primary_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'btn-secondary'
   Btn_Secondary_Class_Widget : constant Widget_Style :=
     From (Btn_Secondary_Class_Base_Style)
     .On (When_State (State_Hovered), Btn_Secondary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Secondary_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Btn_Secondary_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Btn_Secondary_Class_Widget_Disabled_Style)
     .Build;

   --  Complete widget style for class 'btn-secondary'::label
   Btn_Secondary_Class_Label_Widget : constant Widget_Style :=
     From (Btn_Secondary_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'btn-secondary'
   Btn_Secondary_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Btn_Secondary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Secondary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'btn-row'
   Btn_Row_Class_Widget : constant Widget_Style :=
     From (Btn_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'btn-row'
   Btn_Row_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Btn_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'field-label'
   Field_Label_Class_Widget : constant Widget_Style :=
     From (Field_Label_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'field-label'::label
   Field_Label_Class_Label_Widget : constant Widget_Style :=
     From (Field_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'field-label'
   Field_Label_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Field_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Field_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'text-field'
   Text_Field_Class_Widget : constant Widget_Style :=
     From (Text_Field_Class_Base_Style)
     .On (When_State (State_Focused), Text_Field_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Text_Field_Class_Widget_Disabled_Style)
     .Build;

   --  Complete widget style for class 'text-field'::cursor
   Text_Field_Class_Cursor_Widget : constant Widget_Style :=
     From (Text_Field_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'text-field'::label
   Text_Field_Class_Label_Widget : constant Widget_Style :=
     From (Text_Field_Class_Label_Base_Style)
     .Build;

   --  Complete widget style for class 'text-field'::selected
   Text_Field_Class_Selected_Widget : constant Widget_Style :=
     From (Text_Field_Class_Selected_Base_Style)
     .Build;

   --  Part styles bundle for class 'text-field'
   Text_Field_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Text_Field_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Text_Field_Class_Cursor_Widget, Enabled => True),
      Label_Part => (Style => Text_Field_Class_Label_Widget, Enabled => True),
      Selected_Part => (Style => Text_Field_Class_Selected_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'combo'
   Combo_Class_Widget : constant Widget_Style :=
     From (Combo_Class_Base_Style)
     .On (When_State (State_Hovered), Combo_Class_Widget_Hovered_Style)
     .On (When_State (State_Focused), Combo_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Combo_Class_Widget_Disabled_Style)
     .Build;

   --  Complete widget style for class 'combo'::indicator
   Combo_Class_Indicator_Widget : constant Widget_Style :=
     From (Combo_Class_Indicator_Base_Style)
     .Build;

   --  Complete widget style for class 'combo'::label
   Combo_Class_Label_Widget : constant Widget_Style :=
     From (Combo_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'combo'
   Combo_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Combo_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Combo_Class_Indicator_Widget, Enabled => True),
      Label_Part => (Style => Combo_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'setting-row'
   Setting_Row_Class_Widget : constant Widget_Style :=
     From (Setting_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'setting-row'
   Setting_Row_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Setting_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'setting-label'
   Setting_Label_Class_Widget : constant Widget_Style :=
     From (Setting_Label_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'setting-label'::label
   Setting_Label_Class_Label_Widget : constant Widget_Style :=
     From (Setting_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'setting-label'
   Setting_Label_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Setting_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Setting_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'setting-switch'
   Setting_Switch_Class_Widget : constant Widget_Style :=
     From (Setting_Switch_Class_Base_Style)
     .On (When_State (State_Selected), Setting_Switch_Class_Widget_Selected_Style)
     .On (When_State (State_Focused), Setting_Switch_Class_Widget_Focused_Style)
     .On (When_State (State_Selected) and When_State (State_Focused), Setting_Switch_Class_Widget_Selected_Widget_Focused_Style)
     .On (When_State (State_Disabled), Setting_Switch_Class_Widget_Disabled_Style)
     .Build;

   --  Complete widget style for class 'setting-switch'::knob
   Setting_Switch_Class_Knob_Widget : constant Widget_Style :=
     From (Setting_Switch_Class_Knob_Base_Style)
     .On (When_State (State_Selected), Setting_Switch_Class_Knob_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for class 'setting-switch'
   Setting_Switch_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Setting_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Setting_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'combo-dropdown'
   Combo_Dropdown_Class_Widget : constant Widget_Style :=
     From (Combo_Dropdown_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'combo-dropdown'
   Combo_Dropdown_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Combo_Dropdown_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'combo-option'
   Combo_Option_Class_Widget : constant Widget_Style :=
     From (Combo_Option_Class_Base_Style)
     .On (When_State (State_Hovered), Combo_Option_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Combo_Option_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'combo-option'::label
   Combo_Option_Class_Label_Widget : constant Widget_Style :=
     From (Combo_Option_Class_Label_Base_Style)
     .On (When_State (State_Selected), Combo_Option_Class_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for class 'combo-option'
   Combo_Option_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Combo_Option_Class_Widget, Enabled => True),
      Label_Part => (Style => Combo_Option_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-backdrop'
   Dialog_Backdrop_Class_Widget : constant Widget_Style :=
     From (Dialog_Backdrop_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-backdrop'
   Dialog_Backdrop_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Backdrop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-panel'
   Dialog_Panel_Class_Widget : constant Widget_Style :=
     From (Dialog_Panel_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-panel'
   Dialog_Panel_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-message'
   Dialog_Message_Class_Widget : constant Widget_Style :=
     From (Dialog_Message_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'dialog-message'::icon
   Dialog_Message_Class_Icon_Widget : constant Widget_Style :=
     From (Dialog_Message_Class_Icon_Base_Style)
     .Build;

   --  Complete widget style for class 'dialog-message'::label
   Dialog_Message_Class_Label_Widget : constant Widget_Style :=
     From (Dialog_Message_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-message'
   Dialog_Message_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Message_Class_Widget, Enabled => True),
      Icon_Part => (Style => Dialog_Message_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Message_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-title'
   Dialog_Title_Class_Widget : constant Widget_Style :=
     From (Dialog_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'dialog-title'::label
   Dialog_Title_Class_Label_Widget : constant Widget_Style :=
     From (Dialog_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-title'
   Dialog_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-btn-row'
   Dialog_Btn_Row_Class_Widget : constant Widget_Style :=
     From (Dialog_Btn_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-btn-row'
   Dialog_Btn_Row_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Btn_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-btn'
   Dialog_Btn_Class_Widget : constant Widget_Style :=
     From (Dialog_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Dialog_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Dialog_Btn_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Dialog_Btn_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'dialog-btn'::label
   Dialog_Btn_Class_Label_Widget : constant Widget_Style :=
     From (Dialog_Btn_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-btn'
   Dialog_Btn_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     From (Context_Menu_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'context-menu'
   Context_Menu_Class_Part_Styles : constant Part_Style_Array := [
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
   Context_Menu_Item_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Material_Demo_Light_Styles;