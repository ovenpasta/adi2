--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Material_Demo_Light_Styles is

   function Has_Root_Font_Size return Boolean is (True);
   function Root_Font_Size return Length_Value is (Dip (16.0));

   function Root_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Dip (16.0)),
      others => <>);

   function Has_Root_Styles return Boolean is (True);
   function Root_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => From (Root_Base_Style).Build, Enabled => True),
      others => <>
   ]);

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Root_Part_Styles,
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);

   function Var_App_Title return String is ("Material Demo (Light)");
   function Var_Welcome_Title return String is ("Welcome!");
   function Var_Welcome_Message return String is ("Thanks for trying the Material Demo. Click OK to explore the Forms page, or dismiss to stay on Home.");
   function Var_Quit_Title return String is ("Quit?");
   function Var_Quit_Message return String is ("Are you sure you want to quit the Material Demo?");

   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (255, 251, 254)),
      others => <>);

   --  Base style for class 'app-bar'
   function App_Bar_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Flex_Shrink => Set (0.0),
      Background_Color => Set_Bg (RGB (255, 251, 254)),
      Padding => Set (CSS_Box (Px (16.0), Px (24.0), Px (16.0), Px (24.0))),
      others => <>);

   --  Base style for class 'app-title'
   function App_Title_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (10.0))),
      others => <>);

   --  Base style for class 'app-title'::icon
   function App_Title_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (28.0))),
      Height => Set (Size (Px (28.0))),
      others => <>);

   --  Base style for class 'app-title'::label
   function App_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Root_Em (1.375)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'nav-bar'
   function Nav_Bar_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (4.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Padding => Set (CSS_Box (Px (4.0), Px (16.0), Px (4.0), Px (16.0))),
      others => <>);

   --  Base style for class 'nav-btn'
   function Nav_Btn_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (20.0))),
      others => <>);

   --  Style for class 'nav-btn' when widget State_Hovered
   function Nav_Btn_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      others => <>);

   --  Style for class 'nav-btn' when widget State_Focused
   function Nav_Btn_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'nav-btn' when widget State_Selected
   function Nav_Btn_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      others => <>);

   --  Base style for class 'nav-btn'::label
   function Nav_Btn_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Root_Em (0.875)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Color))),
      others => <>);

   --  Style for class 'nav-btn'::label when widget State_Hovered
   function Nav_Btn_Class_Label_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (103, 80, 164)),
      others => <>);

   --  Style for class 'nav-btn'::label when widget State_Selected
   function Nav_Btn_Class_Label_Widget_Selected_Style return Style_Rules is
     (
      Color => Set (RGB (103, 80, 164)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'pages'
   function Pages_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      others => <>);

   --  Base style for class 'page'
   function Page_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (16.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      others => <>);

   --  Base style for class 'card'
   function Card_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Gap => Set (Gap (Px (12.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Transition => Set ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Base style for class 'card-title'
   function Card_Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>);

   --  Base style for class 'card-title'::label
   function Card_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Root_Em (1.25)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'card-body'
   function Card_Body_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>);

   --  Base style for class 'card-body'::label
   function Card_Body_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Root_Em (0.875)),
      Font_Weight => Set (Weight_Normal),
      others => <>);

   --  Base style for class 'card-hint'
   function Card_Hint_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>);

   --  Base style for class 'card-hint'::label
   function Card_Hint_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGBA (73, 69, 79, 0.6)),
      Font_Size => Set_Font (Root_Em (0.75)),
      Font_Weight => Set (Weight_Normal),
      others => <>);

   --  Base style for class 'control-grid'
   function Control_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (12.0), Px (16.0))),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (4.0), Px (0.0), Px (4.0), Px (0.0))),
      others => <>);

   --  Base style for class 'grid-header'::label
   function Grid_Header_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGBA (73, 69, 79, 0.6)),
      Font_Size => Set_Font (Root_Em (0.75)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'grid-label'::label
   function Grid_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Root_Em (0.875)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'grid-cell'
   function Grid_Cell_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Align_Self => Set (Center),
      others => <>);

   --  Base style for class 'btn-primary'
   function Btn_Primary_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Cursor => Set (Cursor_Pointer),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (3.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (20.0))),
      others => <>);

   --  Style for class 'btn-primary' when widget State_Hovered
   function Btn_Primary_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (122, 100, 180)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (2.0), Px (6.0), Px (0.0), RGBA (0, 0, 0, 0.2))),
      others => <>);

   --  Style for class 'btn-primary' when widget State_Pressed
   function Btn_Primary_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (85, 64, 140)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (2.0), Px (0.0), RGBA (0, 0, 0, 0.1))),
      others => <>);

   --  Style for class 'btn-primary' when widget State_Focused
   function Btn_Primary_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (28, 27, 31)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'btn-primary' when widget State_Disabled
   function Btn_Primary_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>);

   --  Base style for class 'btn-primary'::label
   function Btn_Primary_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Root_Em (0.875)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'btn-secondary'
   function Btn_Secondary_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (20.0))),
      others => <>);

   --  Style for class 'btn-secondary' when widget State_Hovered
   function Btn_Secondary_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.12))),
      others => <>);

   --  Style for class 'btn-secondary' when widget State_Pressed
   function Btn_Secondary_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.16)),
      Box_Shadow => Set (No_Shadow),
      others => <>);

   --  Style for class 'btn-secondary' when widget State_Focused
   function Btn_Secondary_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'btn-secondary' when widget State_Disabled
   function Btn_Secondary_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>);

   --  Base style for class 'btn-secondary'::label
   function Btn_Secondary_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (103, 80, 164)),
      Font_Size => Set_Font (Root_Em (0.875)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'btn-row'
   function Btn_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Base style for class 'field-label'
   function Field_Label_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      Padding => Set (CSS_Box (Px (4.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Base style for class 'field-label'::label
   function Field_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Medium),
      others => <>);

   --  Base style for class 'text-field'
   function Text_Field_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Cursor => Set (Cursor_Text),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (12.0), Px (16.0), Px (12.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'text-field' when widget State_Focused
   function Text_Field_Class_Widget_Focused_Style return Style_Rules is
     (
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      others => <>);

   --  Style for class 'text-field' when widget State_Disabled
   function Text_Field_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>);

   --  Base style for class 'text-field'::cursor
   function Text_Field_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Width => Set (Size (Px (2.0))),
      others => <>);

   --  Base style for class 'text-field'::label
   function Text_Field_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Medium),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Top => Set_Top (Inset (Px (-8.0))),
      Left => Set_Left (Inset (Px (12.0))),
      Padding => Set (CSS_Box (Px (0.0), Px (4.0), Px (0.0), Px (4.0))),
      others => <>);

   --  Style for class 'text-field'::label when widget State_Focused
   function Text_Field_Class_Label_Widget_Focused_Style return Style_Rules is
     (
      Color => Set (RGB (103, 80, 164)),
      others => <>);

   --  Base style for class 'text-field'::selected
   function Text_Field_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.3)),
      others => <>);

   --  Base style for class 'text-field'::text
   function Text_Field_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'combo'
   function Combo_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (44.0))),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (9.0), Px (16.0), Px (9.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (0.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (8.0), Px (8.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Style for class 'combo' when widget State_Hovered
   function Combo_Class_Widget_Hovered_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (0.0), RGBA (103, 80, 164, 0.12))),
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      others => <>);

   --  Style for class 'combo' when widget State_Focused
   function Combo_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (0.0), RGBA (103, 80, 164, 0.4))),
      Border_Width => Set (Border_Width (Px (0.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      others => <>);

   --  Style for class 'combo' when widget State_Disabled
   function Combo_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>);

   --  Base style for class 'combo'::indicator
   function Combo_Class_Indicator_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>);

   --  Base style for class 'combo'::text
   function Combo_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'setting-row'
   function Setting_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Justify_Content => Set (Space_Between),
      Padding => Set (CSS_Box (Px (8.0), Px (0.0), Px (8.0), Px (0.0))),
      others => <>);

   --  Base style for class 'setting-label'
   function Setting_Label_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Display => Set (Inline_Flex),
      others => <>);

   --  Base style for class 'setting-label'::label
   function Setting_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Normal),
      others => <>);

   --  Base style for class 'setting-switch'
   function Setting_Switch_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Width => Set (Size (Px (52.0))),
      Height => Set (Size (Px (32.0))),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Style for class 'setting-switch' when widget State_Selected
   function Setting_Switch_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      others => <>);

   --  Style for class 'setting-switch' when widget State_Focused
   function Setting_Switch_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'setting-switch' when widget State_Selected, widget State_Focused
   function Setting_Switch_Class_Widget_Selected_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'setting-switch' when widget State_Disabled
   function Setting_Switch_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>);

   --  Base style for class 'setting-switch'::knob
   function Setting_Switch_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGB (121, 116, 126)),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Margin))),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (0.0), Px (2.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Style for class 'setting-switch'::knob when widget State_Selected
   function Setting_Switch_Class_Knob_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (0.0), Px (22.0))),
      others => <>);

   --  Base style for class 'combo-dropdown'
   function Combo_Dropdown_Class_Base_Style return Style_Rules is
     (
      Max_Height => Set (Size (Px (240.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (20.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Padding => Set (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (12.0))),
      Overflow_X => Set_Overflow_X (Overflow_Auto),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'combo-option'
   function Combo_Option_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (14.0), Px (10.0), Px (14.0))),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'combo-option' when widget State_Hovered
   function Combo_Option_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      others => <>);

   --  Style for class 'combo-option' when widget State_Selected
   function Combo_Option_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      others => <>);

   --  Base style for class 'combo-option'::label
   function Combo_Option_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Style for class 'combo-option'::label when widget State_Selected
   function Combo_Option_Class_Label_Widget_Selected_Style return Style_Rules is
     (
      Color => Set (RGB (103, 80, 164)),
      others => <>);

   --  Base style for class 'dialog-backdrop'
   function Dialog_Backdrop_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.32)),
      others => <>);

   --  Base style for class 'dialog-panel'
   function Dialog_Panel_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (16.0))),
      Min_Width => Set (Size (Px (320.0))),
      Max_Width => Set (Size (Px (460.0))),
      Background_Color => Set_Bg (RGB (238, 232, 244)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (32.0), Px (0.0), RGBA (0, 0, 0, 0.18))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (28.0))),
      others => <>);

   --  Base style for class 'dialog-message'
   function Dialog_Message_Class_Base_Style return Style_Rules is
     (
      Flex_Direction => Set (Row),
      Align_Items => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'dialog-message'::icon
   function Dialog_Message_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (32.0))),
      Height => Set (Size (Px (32.0))),
      others => <>);

   --  Base style for class 'dialog-message'::label
   function Dialog_Message_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (73, 69, 79)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'dialog-title'
   function Dialog_Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'dialog-title'::label
   function Dialog_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'dialog-btn-row'
   function Dialog_Btn_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_End),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Base style for class 'dialog-btn'
   function Dialog_Btn_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (24.0), Px (10.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (20.0))),
      others => <>);

   --  Style for class 'dialog-btn' when widget State_Hovered
   function Dialog_Btn_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.08)),
      others => <>);

   --  Style for class 'dialog-btn' when widget State_Pressed
   function Dialog_Btn_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.12)),
      others => <>);

   --  Style for class 'dialog-btn' when widget State_Focused
   function Dialog_Btn_Class_Widget_Focused_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.12)),
      others => <>);

   --  Base style for class 'dialog-btn'::label
   function Dialog_Btn_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (103, 80, 164)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'slider'
   function Slider_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (200.0))),
      Height => Set (Size (Px (20.0))),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Style for class 'slider' when widget State_Focused
   function Slider_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      others => <>);

   --  Style for class 'slider' when widget State_Disabled
   function Slider_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      others => <>);

   --  Base style for class 'slider'::indicator
   function Slider_Class_Indicator_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'slider'::knob
   function Slider_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (20.0))),
      Background_Color => Set_Bg (RGB (73, 69, 79)),
      Transition => Set ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Pct (50.0))),
      others => <>);

   --  Style for class 'slider'::knob when part State_Hovered
   function Slider_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      others => <>);

   --  Style for class 'slider'::knob when part State_Pressed
   function Slider_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      others => <>);

   --  Base style for class 'num-field'
   function Num_Field_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (100.0))),
      Background_Color => Set_Bg (RGB (231, 224, 236)),
      Cursor => Set (Cursor_Text),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (12.0), Px (10.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (0.0), Px (0.0), Px (2.0), Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
      Border_Radius => Set (Radius (Px (8.0), Px (8.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Style for class 'num-field' when widget State_Focused
   function Num_Field_Class_Widget_Focused_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      Outline_Style => Set (Outline_Solid),
      Outline_Color => Set_Outline_Color (RGB (103, 80, 164)),
      Outline_Offset => Set_Outline_Offset (Px (2.0)),
      Border_Color => Set (Border_Color (RGB (103, 80, 164))),
      others => <>);

   --  Style for class 'num-field' when widget State_Disabled
   function Num_Field_Class_Widget_Disabled_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      Cursor => Set (Cursor_Default),
      others => <>);

   --  Base style for class 'num-field'::cursor
   function Num_Field_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (103, 80, 164)),
      Width => Set (Size (Px (2.0))),
      others => <>);

   --  Base style for class 'num-field'::selected
   function Num_Field_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.3)),
      others => <>);

   --  Base style for class 'num-field'::text
   function Num_Field_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'context-menu'
   function Context_Menu_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (180.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (24.0), Px (0.0), RGBA (0, 0, 0, 0.15))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (121, 116, 126))),
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
      Background_Color => Set_Bg (RGBA (103, 80, 164, 0.12)),
      others => <>);

   --  Base style for class 'context-menu-item'::label
   function Context_Menu_Item_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (28, 27, 31)),
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

   --  Complete widget style for class 'app-bar'
   function App_Bar_Class_Widget return Widget_Style is
     (From (App_Bar_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'app-bar'
   function App_Bar_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => App_Bar_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'app-title'
   function App_Title_Class_Widget return Widget_Style is
     (From (App_Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'app-title'::icon
   function App_Title_Class_Icon_Widget return Widget_Style is
     (From (App_Title_Class_Icon_Base_Style)
     .Build);

   --  Complete widget style for class 'app-title'::label
   function App_Title_Class_Label_Widget return Widget_Style is
     (From (App_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'app-title'
   function App_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => App_Title_Class_Widget, Enabled => True),
      Icon_Part => (Style => App_Title_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => App_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'nav-bar'
   function Nav_Bar_Class_Widget return Widget_Style is
     (From (Nav_Bar_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'nav-bar'
   function Nav_Bar_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Nav_Bar_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'nav-btn'
   function Nav_Btn_Class_Widget return Widget_Style is
     (From (Nav_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Nav_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Focused), Nav_Btn_Class_Widget_Focused_Style)
     .On (When_State (State_Selected), Nav_Btn_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'nav-btn'::label
   function Nav_Btn_Class_Label_Widget return Widget_Style is
     (From (Nav_Btn_Class_Label_Base_Style)
     .On (When_State (State_Hovered), Nav_Btn_Class_Label_Widget_Hovered_Style)
     .On (When_State (State_Selected), Nav_Btn_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'nav-btn'
   function Nav_Btn_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Nav_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Nav_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'pages'
   function Pages_Class_Widget return Widget_Style is
     (From (Pages_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'pages'
   function Pages_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Pages_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'page'
   function Page_Class_Widget return Widget_Style is
     (From (Page_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'page'
   function Page_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Page_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card'
   function Card_Class_Widget return Widget_Style is
     (From (Card_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'card'
   function Card_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-title'
   function Card_Title_Class_Widget return Widget_Style is
     (From (Card_Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'card-title'::label
   function Card_Title_Class_Label_Widget return Widget_Style is
     (From (Card_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-title'
   function Card_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-body'
   function Card_Body_Class_Widget return Widget_Style is
     (From (Card_Body_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'card-body'::label
   function Card_Body_Class_Label_Widget return Widget_Style is
     (From (Card_Body_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-body'
   function Card_Body_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Body_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Body_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-hint'
   function Card_Hint_Class_Widget return Widget_Style is
     (From (Card_Hint_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'card-hint'::label
   function Card_Hint_Class_Label_Widget return Widget_Style is
     (From (Card_Hint_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-hint'
   function Card_Hint_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'control-grid'
   function Control_Grid_Class_Widget return Widget_Style is
     (From (Control_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'control-grid'
   function Control_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Control_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grid-header'::label
   function Grid_Header_Class_Label_Widget return Widget_Style is
     (From (Grid_Header_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'grid-header'
   function Grid_Header_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Grid_Header_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grid-label'::label
   function Grid_Label_Class_Label_Widget return Widget_Style is
     (From (Grid_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'grid-label'
   function Grid_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Grid_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grid-cell'
   function Grid_Cell_Class_Widget return Widget_Style is
     (From (Grid_Cell_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grid-cell'
   function Grid_Cell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grid_Cell_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'btn-primary'
   function Btn_Primary_Class_Widget return Widget_Style is
     (From (Btn_Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Btn_Primary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Primary_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Btn_Primary_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Btn_Primary_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'btn-primary'::label
   function Btn_Primary_Class_Label_Widget return Widget_Style is
     (From (Btn_Primary_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'btn-primary'
   function Btn_Primary_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'btn-secondary'
   function Btn_Secondary_Class_Widget return Widget_Style is
     (From (Btn_Secondary_Class_Base_Style)
     .On (When_State (State_Hovered), Btn_Secondary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Secondary_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Btn_Secondary_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Btn_Secondary_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'btn-secondary'::label
   function Btn_Secondary_Class_Label_Widget return Widget_Style is
     (From (Btn_Secondary_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'btn-secondary'
   function Btn_Secondary_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Btn_Secondary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Secondary_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'btn-row'
   function Btn_Row_Class_Widget return Widget_Style is
     (From (Btn_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'btn-row'
   function Btn_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Btn_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'field-label'
   function Field_Label_Class_Widget return Widget_Style is
     (From (Field_Label_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'field-label'::label
   function Field_Label_Class_Label_Widget return Widget_Style is
     (From (Field_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'field-label'
   function Field_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Field_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Field_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'text-field'
   function Text_Field_Class_Widget return Widget_Style is
     (From (Text_Field_Class_Base_Style)
     .On (When_State (State_Focused), Text_Field_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Text_Field_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'text-field'::cursor
   function Text_Field_Class_Cursor_Widget return Widget_Style is
     (From (Text_Field_Class_Cursor_Base_Style)
     .Build);

   --  Complete widget style for class 'text-field'::label
   function Text_Field_Class_Label_Widget return Widget_Style is
     (From (Text_Field_Class_Label_Base_Style)
     .On (When_State (State_Focused), Text_Field_Class_Label_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'text-field'::selected
   function Text_Field_Class_Selected_Widget return Widget_Style is
     (From (Text_Field_Class_Selected_Base_Style)
     .Build);

   --  Complete widget style for class 'text-field'::text
   function Text_Field_Class_Text_Widget return Widget_Style is
     (From (Text_Field_Class_Text_Base_Style)
     .Build);

   --  Part styles bundle for class 'text-field'
   function Text_Field_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Text_Field_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Text_Field_Class_Cursor_Widget, Enabled => True),
      Label_Part => (Style => Text_Field_Class_Label_Widget, Enabled => True),
      Selected_Part => (Style => Text_Field_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Text_Field_Class_Text_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'combo'
   function Combo_Class_Widget return Widget_Style is
     (From (Combo_Class_Base_Style)
     .On (When_State (State_Hovered), Combo_Class_Widget_Hovered_Style)
     .On (When_State (State_Focused), Combo_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Combo_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'combo'::indicator
   function Combo_Class_Indicator_Widget return Widget_Style is
     (From (Combo_Class_Indicator_Base_Style)
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

   --  Complete widget style for class 'setting-row'
   function Setting_Row_Class_Widget return Widget_Style is
     (From (Setting_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'setting-row'
   function Setting_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Setting_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'setting-label'
   function Setting_Label_Class_Widget return Widget_Style is
     (From (Setting_Label_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'setting-label'::label
   function Setting_Label_Class_Label_Widget return Widget_Style is
     (From (Setting_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'setting-label'
   function Setting_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Setting_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Setting_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'setting-switch'
   function Setting_Switch_Class_Widget return Widget_Style is
     (From (Setting_Switch_Class_Base_Style)
     .On (When_State (State_Selected), Setting_Switch_Class_Widget_Selected_Style)
     .On (When_State (State_Focused), Setting_Switch_Class_Widget_Focused_Style)
     .On (When_State (State_Selected) and When_State (State_Focused), Setting_Switch_Class_Widget_Selected_Widget_Focused_Style)
     .On (When_State (State_Disabled), Setting_Switch_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'setting-switch'::knob
   function Setting_Switch_Class_Knob_Widget return Widget_Style is
     (From (Setting_Switch_Class_Knob_Base_Style)
     .On (When_State (State_Selected), Setting_Switch_Class_Knob_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'setting-switch'
   function Setting_Switch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Setting_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Setting_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'combo-dropdown'
   function Combo_Dropdown_Class_Widget return Widget_Style is
     (From (Combo_Dropdown_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'combo-dropdown'
   function Combo_Dropdown_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Combo_Dropdown_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'combo-option'
   function Combo_Option_Class_Widget return Widget_Style is
     (From (Combo_Option_Class_Base_Style)
     .On (When_State (State_Hovered), Combo_Option_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Combo_Option_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'combo-option'::label
   function Combo_Option_Class_Label_Widget return Widget_Style is
     (From (Combo_Option_Class_Label_Base_Style)
     .On (When_State (State_Selected), Combo_Option_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'combo-option'
   function Combo_Option_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Combo_Option_Class_Widget, Enabled => True),
      Label_Part => (Style => Combo_Option_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-backdrop'
   function Dialog_Backdrop_Class_Widget return Widget_Style is
     (From (Dialog_Backdrop_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-backdrop'
   function Dialog_Backdrop_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Backdrop_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-panel'
   function Dialog_Panel_Class_Widget return Widget_Style is
     (From (Dialog_Panel_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-panel'
   function Dialog_Panel_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Panel_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-message'
   function Dialog_Message_Class_Widget return Widget_Style is
     (From (Dialog_Message_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'dialog-message'::icon
   function Dialog_Message_Class_Icon_Widget return Widget_Style is
     (From (Dialog_Message_Class_Icon_Base_Style)
     .Build);

   --  Complete widget style for class 'dialog-message'::label
   function Dialog_Message_Class_Label_Widget return Widget_Style is
     (From (Dialog_Message_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-message'
   function Dialog_Message_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Message_Class_Widget, Enabled => True),
      Icon_Part => (Style => Dialog_Message_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Message_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-title'
   function Dialog_Title_Class_Widget return Widget_Style is
     (From (Dialog_Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'dialog-title'::label
   function Dialog_Title_Class_Label_Widget return Widget_Style is
     (From (Dialog_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-title'
   function Dialog_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-btn-row'
   function Dialog_Btn_Row_Class_Widget return Widget_Style is
     (From (Dialog_Btn_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-btn-row'
   function Dialog_Btn_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Btn_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-btn'
   function Dialog_Btn_Class_Widget return Widget_Style is
     (From (Dialog_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Dialog_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Dialog_Btn_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Dialog_Btn_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'dialog-btn'::label
   function Dialog_Btn_Class_Label_Widget return Widget_Style is
     (From (Dialog_Btn_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-btn'
   function Dialog_Btn_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'slider'
   function Slider_Class_Widget return Widget_Style is
     (From (Slider_Class_Base_Style)
     .On (When_State (State_Focused), Slider_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Slider_Class_Widget_Disabled_Style)
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

   --  Complete widget style for class 'num-field'
   function Num_Field_Class_Widget return Widget_Style is
     (From (Num_Field_Class_Base_Style)
     .On (When_State (State_Focused), Num_Field_Class_Widget_Focused_Style)
     .On (When_State (State_Disabled), Num_Field_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'num-field'::cursor
   function Num_Field_Class_Cursor_Widget return Widget_Style is
     (From (Num_Field_Class_Cursor_Base_Style)
     .Build);

   --  Complete widget style for class 'num-field'::selected
   function Num_Field_Class_Selected_Widget return Widget_Style is
     (From (Num_Field_Class_Selected_Base_Style)
     .Build);

   --  Complete widget style for class 'num-field'::text
   function Num_Field_Class_Text_Widget return Widget_Style is
     (From (Num_Field_Class_Text_Base_Style)
     .Build);

   --  Part styles bundle for class 'num-field'
   function Num_Field_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Num_Field_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Num_Field_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Num_Field_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Num_Field_Class_Text_Widget, Enabled => True),
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

end Material_Demo_Light_Styles;