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

package Material_Demo_Styles is

   function Has_Root_Font_Size return Boolean is (True);
   function Root_Font_Size return Length_Value is (Dip (16.0));

   function Has_Root_Styles return Boolean is (True);
   Root_Style : constant Widget_Style :=
     Style_Of
        .Font_Size (Dip (16.0))
     .Build;

   Root_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Style, Enabled => True),
      others => <>
   ];

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Root_Part_Styles,
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);

   function Var_Space_1 return Length_Value is (Dip (4.0));
   function Var_Space_2 return Length_Value is (Dip (8.0));
   function Var_Space_3 return Length_Value is (Dip (12.0));
   function Var_Space_4 return Length_Value is (Dip (16.0));
   function Var_Space_5 return Length_Value is (Dip (20.0));
   function Var_Space_6 return Length_Value is (Dip (24.0));
   function Var_Space_7 return Length_Value is (Dip (28.0));
   function Var_Radius_Sm return Length_Value is (Dip (8.0));
   function Var_Radius_Md return Length_Value is (Dip (12.0));
   function Var_Radius_Lg return Length_Value is (Dip (16.0));
   function Var_Radius_Xl return Length_Value is (Dip (20.0));
   function Var_Radius_Dialog return Length_Value is (Dip (28.0));
   function Var_Radius_Pill return Length_Value is (Dip (999.0));
   function Var_Icon_Size return Length_Value is (Dip (28.0));
   function Var_Dialog_Icon_Size return Length_Value is (Dip (32.0));
   function Var_Control_Height return Length_Value is (Dip (44.0));
   function Var_Switch_Width return Length_Value is (Dip (52.0));
   function Var_Switch_Height return Length_Value is (Dip (32.0));
   function Var_Switch_Knob_Size return Length_Value is (Dip (24.0));
   function Var_Slider_Width return Length_Value is (Dip (200.0));
   function Var_Slider_Height return Length_Value is (Dip (20.0));
   function Var_Slider_Knob_Size return Length_Value is (Dip (20.0));
   function Var_Dialog_Min_Width return Length_Value is (Dip (320.0));
   function Var_Dialog_Max_Width return Length_Value is (Dip (460.0));
   function Var_Dropdown_Max_Height return Length_Value is (Vh (40.0));
   function Var_Font_Caption return Length_Value is (Root_Em (0.75));
   function Var_Font_Body return Length_Value is (Root_Em (0.875));
   function Var_Font_Setting return Length_Value is (Root_Em (1.0));
   function Var_Font_Title return Length_Value is (Root_Em (1.25));
   function Var_Font_Dialog_Title return Length_Value is (Root_Em (1.5));
   function Var_Font_App_Title return Length_Value is (Root_Em (1.375));
   function Var_App_Title return String is ("Material Demo (Dark)");
   function Var_Welcome_Title return String is ("Welcome!");
   function Var_Welcome_Message return String is ("Thanks for trying the Material Demo. Click OK to explore the Forms page, or dismiss to stay on Home.");
   function Var_Quit_Title return String is ("Quit?");
   function Var_Quit_Message return String is ("Are you sure you want to quit the Material Demo?");

   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (28, 27, 31))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'app-bar'
   App_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Flex_Shrink (0.0)
        .Background (RGB (28, 27, 31))
        .Padding (CSS_Box (Dip (16.0), Dip (24.0), Dip (16.0), Dip (24.0)))
     .Build;

   --  Part styles bundle for class 'app-bar'
   App_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => App_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'app-title'
   App_Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Gap (Gap (Dip (10.0)))
     .Build;

   --  Style for class 'app-title'::icon
   App_Title_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (28.0)))
        .Height (Size (Dip (28.0)))
     .Build;

   --  Style for class 'app-title'::label
   App_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (1.375))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'app-title'
   App_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => App_Title_Class_Widget, Enabled => True),
      Icon_Part => (Style => App_Title_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => App_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'nav-bar'
   Nav_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Gap (Gap (Dip (4.0)))
        .Background (RGB (43, 41, 48))
        .Padding (CSS_Box (Dip (4.0), Dip (16.0), Dip (4.0), Dip (16.0)))
     .Build;

   --  Part styles bundle for class 'nav-bar'
   Nav_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nav_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'lock-bar'
   Lock_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Padding (CSS_Box (Dip (8.0), Dip (20.0), Dip (8.0), Dip (20.0)))
     .Build;

   --  Part styles bundle for class 'lock-bar'
   Lock_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Lock_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'nav-btn'
   Nav_Btn_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGBA (0, 0, 0, 0.0))
        .Transition ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Dip (12.0), Dip (24.0), Dip (12.0), Dip (24.0)))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (208, 188, 255, 0.08))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (208, 188, 255))
        .Outline_Offset (Dip (2.0))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (74, 68, 88))
     .Build;

   --  Style for class 'nav-btn'::label
   Nav_Btn_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (202, 196, 208))
        .Font_Size (Root_Em (0.875))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Transition ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (208, 188, 255))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (RGB (208, 188, 255))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'nav-btn'
   Nav_Btn_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nav_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Nav_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'pages'
   Pages_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Padding (CSS_Box (Vh (2.0), Vw (2.5), Vh (2.0), Vw (2.5)))
     .Build;

   --  Part styles bundle for class 'pages'
   Pages_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pages_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'page'
   Page_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Dip (16.0)))
        .Padding (CSS_Box (Dip (8.0), Dip (8.0), Dip (8.0), Dip (8.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Part styles bundle for class 'page'
   Page_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'label-inline'
   Label_Inline_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
        .Display (Inline_Flex)
     .Build;

   --  Part styles bundle for class 'label-inline'
   Label_Inline_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label_Inline_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card'
   Card_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (43, 41, 48))
        .Gap (Gap (Dip (12.0)))
        .Box_Shadow (Shadow (Dip (0.0), Dip (2.0), Dip (8.0), Dip (0.0), RGBA (0, 0, 0, 0.3)))
        .Transition ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Dip (24.0), Dip (24.0), Dip (24.0), Dip (24.0)))
        .Radius (Radius (Dip (16.0)))
     .Build;

   --  Part styles bundle for class 'card'
   Card_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-title'::label
   Card_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (1.25))
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'card-title'
   Card_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Card_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-body'::label
   Card_Body_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (202, 196, 208))
        .Font_Size (Root_Em (0.875))
        .Font_Weight (Weight_Normal)
     .Build;

   --  Part styles bundle for class 'card-body'
   Card_Body_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Card_Body_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-hint'::label
   Card_Hint_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGBA (202, 196, 208, 0.6))
        .Font_Size (Root_Em (0.75))
        .Font_Weight (Weight_Normal)
     .Build;

   --  Part styles bundle for class 'card-hint'
   Card_Hint_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Card_Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'control-grid'
   Control_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Dip (12.0), Dip (16.0)))
        .Align_Items (Center)
        .Padding (CSS_Box (Dip (4.0), Dip (0.0), Dip (4.0), Dip (0.0)))
     .Build;

   --  Part styles bundle for class 'control-grid'
   Control_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Control_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grid-header'::label
   Grid_Header_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGBA (202, 196, 208, 0.6))
        .Font_Size (Root_Em (0.75))
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'grid-header'
   Grid_Header_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Grid_Header_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grid-label'
   Grid_Label_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Self (Center)
     .Build;

   --  Style for class 'grid-label'::label
   Grid_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (202, 196, 208))
        .Font_Size (Root_Em (0.875))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'grid-label'
   Grid_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grid_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Grid_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grid-cell'
   Grid_Cell_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
        .Align_Self (Center)
     .Build;

   --  Part styles bundle for class 'grid-cell'
   Grid_Cell_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grid_Cell_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'btn'
   Btn_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Height (Size (Dip (44.0)))
        .Min_Height (Size (Dip (44.0)))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Dip (0.0), Dip (24.0), Dip (0.0), Dip (24.0)))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
        .Cursor_Style (Cursor_Default)
     .Build;

   --  Style for class 'btn'::label
   Btn_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Size (Root_Em (0.875))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'btn'
   Btn_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'btn-primary'
   Btn_Primary_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (208, 188, 255))
        .Box_Shadow (Shadow (Dip (0.0), Dip (1.0), Dip (3.0), Dip (0.0), RGBA (0, 0, 0, 0.3)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (220, 204, 255))
        .Box_Shadow (Shadow (Dip (0.0), Dip (2.0), Dip (6.0), Dip (0.0), RGBA (0, 0, 0, 0.35)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (190, 168, 240))
        .Box_Shadow (Shadow (Dip (0.0), Dip (0.0), Dip (2.0), Dip (0.0), RGBA (0, 0, 0, 0.2)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (255, 255, 255))
        .Outline_Offset (Dip (2.0))
     .Build;

   --  Style for class 'btn-primary'::label
   Btn_Primary_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (56, 30, 114))
     .Build;

   --  Part styles bundle for class 'btn-primary'
   Btn_Primary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'btn-secondary'
   Btn_Secondary_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (0, 0, 0, 0.0))
        .Border_Color (Border_Color (RGB (147, 143, 153)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (208, 188, 255, 0.08))
        .Box_Shadow (Shadow (Dip (0.0), Dip (1.0), Dip (4.0), Dip (0.0), RGBA (0, 0, 0, 0.25)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGBA (208, 188, 255, 0.16))
        .Box_Shadow (No_Shadow)
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (208, 188, 255))
        .Outline_Offset (Dip (2.0))
     .Build;

   --  Style for class 'btn-secondary'::label
   Btn_Secondary_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (208, 188, 255))
     .Build;

   --  Part styles bundle for class 'btn-secondary'
   Btn_Secondary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Btn_Secondary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Secondary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'btn-row'
   Btn_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Dip (12.0)))
        .Padding (CSS_Box (Dip (8.0), Dip (0.0), Dip (0.0), Dip (0.0)))
     .Build;

   --  Part styles bundle for class 'btn-row'
   Btn_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Btn_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'field-label'
   Field_Label_Class_Widget : constant Widget_Style :=
     Style_Of
        .Padding (CSS_Box (Dip (4.0), Dip (0.0), Dip (0.0), Dip (0.0)))
     .Build;

   --  Style for class 'field-label'::label
   Field_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (202, 196, 208))
        .Font_Size (Root_Em (0.75))
        .Font_Weight (Weight_Medium)
     .Build;

   --  Part styles bundle for class 'field-label'
   Field_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Field_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Field_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'text-field'
   Text_Field_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Dip (44.0)))
        .Background (RGBA (0, 0, 0, 0.0))
        .Cursor_Style (Cursor_Text)
        .Transition ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color)))
        .Padding (CSS_Box (Dip (0.0), Dip (16.0), Dip (0.0), Dip (16.0)))
        .Border_Width (Border_Width (Dip (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (147, 143, 153)))
        .Radius (Radius (Dip (8.0)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Border_Color (Border_Color (RGB (208, 188, 255)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
        .Cursor_Style (Cursor_Default)
     .Build;

   --  Style for class 'text-field'::cursor
   Text_Field_Class_Cursor_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (208, 188, 255))
        .Width (Size (Dip (2.0)))
     .Build;

   --  Style for class 'text-field'::label
   Text_Field_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (147, 143, 153))
        .Font_Size (Root_Em (0.75))
        .Font_Weight (Weight_Medium)
        .Background (RGB (43, 41, 48))
        .Text_Wrap_Mode (TWM_Nowrap)
        .Top (Inset (Dip (-8.0)))
        .Left (Inset (Dip (12.0)))
        .Padding (CSS_Box (Dip (0.0), Dip (4.0), Dip (0.0), Dip (4.0)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Text_Color (RGB (208, 188, 255))
     .Build;

   --  Style for class 'text-field'::selected
   Text_Field_Class_Selected_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (208, 188, 255, 0.3))
     .Build;

   --  Style for class 'text-field'::text
   Text_Field_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (0.875))
     .Build;

   --  Part styles bundle for class 'text-field'
   Text_Field_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Text_Field_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Text_Field_Class_Cursor_Widget, Enabled => True),
      Label_Part => (Style => Text_Field_Class_Label_Widget, Enabled => True),
      Selected_Part => (Style => Text_Field_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Text_Field_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'combo'
   Combo_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Dip (44.0)))
        .Align_Items (Center)
        .Background (RGB (54, 52, 59))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Dip (9.0), Dip (16.0), Dip (9.0), Dip (16.0)))
        .Border_Width (Border_Width (Dip (0.0), Dip (0.0), Dip (2.0), Dip (0.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (147, 143, 153)))
        .Radius (Radius (Dip (8.0), Dip (8.0), Dip (0.0), Dip (0.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Box_Shadow (Shadow (Dip (0.0), Dip (0.0), Dip (8.0), Dip (0.0), RGBA (208, 188, 255, 0.15)))
        .Border_Color (Border_Color (RGB (208, 188, 255)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Dip (0.0), Dip (0.0), Dip (10.0), Dip (0.0), RGBA (208, 188, 255, 0.5)))
        .Border_Width (Border_Width (Dip (0.0), Dip (0.0), Dip (2.0), Dip (0.0)))
        .Border_Color (Border_Color (RGB (208, 188, 255)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
        .Cursor_Style (Cursor_Default)
     .Build;

   --  Style for class 'combo'::indicator
   Combo_Class_Indicator_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (202, 196, 208))
        .Font_Size (Root_Em (0.75))
     .Build;

   --  Style for class 'combo'::text
   Combo_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (0.875))
     .Build;

   --  Part styles bundle for class 'combo'
   Combo_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Combo_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Combo_Class_Indicator_Widget, Enabled => True),
      Text_Part => (Style => Combo_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'setting-row'
   Setting_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Justify_Content (Space_Between)
        .Padding (CSS_Box (Dip (8.0), Dip (0.0), Dip (8.0), Dip (0.0)))
     .Build;

   --  Part styles bundle for class 'setting-row'
   Setting_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Setting_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'setting-label'
   Setting_Label_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'setting-label'::label
   Setting_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (1.0))
        .Font_Weight (Weight_Normal)
        .White_Space (WS_Nowrap)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'setting-label'
   Setting_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Setting_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Setting_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'setting-switch'
   Setting_Switch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
        .Width (Size (Dip (52.0)))
        .Height (Size (Dip (32.0)))
        .Background (RGB (73, 69, 79))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Border_Width (Border_Width (Dip (2.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (147, 143, 153)))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (208, 188, 255))
        .Border_Color (Border_Color (RGB (208, 188, 255)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (208, 188, 255))
        .Outline_Offset (Dip (2.0))
     --  widget State_Selected, widget State_Focused
     .On (When_State (State_Selected) and When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (208, 188, 255))
        .Outline_Offset (Dip (2.0))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
        .Cursor_Style (Cursor_Default)
     .Build;

   --  Style for class 'setting-switch'::knob
   Setting_Switch_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (24.0)))
        .Height (Size (Dip (24.0)))
        .Background (RGB (147, 143, 153))
        .Transition ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Margin) + Props (Prop_Background_Color)))
        .Margin (CSS_Box (Dip (2.0), Dip (2.0), Dip (2.0), Dip (2.0)))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (56, 30, 114))
        .Margin (CSS_Box (Dip (2.0), Dip (2.0), Dip (2.0), Dip (22.0)))
     .Build;

   --  Part styles bundle for class 'setting-switch'
   Setting_Switch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Setting_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Setting_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'combo-dropdown'
   Combo_Dropdown_Class_Widget : constant Widget_Style :=
     Style_Of
        .Max_Height (Size (Vh (40.0)))
        .Background (RGB (54, 52, 60))
        .Box_Shadow (Shadow (Dip (0.0), Dip (8.0), Dip (20.0), Dip (0.0), RGBA (0, 0, 0, 0.4)))
        .Padding (CSS_Box (Dip (4.0), Dip (4.0), Dip (4.0), Dip (4.0)))
        .Border_Width (Border_Width (Dip (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (73, 69, 79)))
        .Radius (Radius (Dip (12.0)))
        .Overflow_X (Overflow_Auto)
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Part styles bundle for class 'combo-dropdown'
   Combo_Dropdown_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Combo_Dropdown_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'combo-option'
   Combo_Option_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (0, 0, 0, 0.0))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Dip (10.0), Dip (14.0), Dip (10.0), Dip (14.0)))
        .Margin (CSS_Box (Dip (2.0), Dip (0.0), Dip (2.0), Dip (0.0)))
        .Radius (Radius (Dip (8.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (208, 188, 255, 0.08))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (74, 68, 88))
     .Build;

   --  Style for class 'combo-option'::label
   Combo_Option_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (0.875))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (RGB (208, 188, 255))
     .Build;

   --  Part styles bundle for class 'combo-option'
   Combo_Option_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Combo_Option_Class_Widget, Enabled => True),
      Label_Part => (Style => Combo_Option_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-backdrop'
   Dialog_Backdrop_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (0, 0, 0, 0.5))
     .Build;

   --  Part styles bundle for class 'dialog-backdrop'
   Dialog_Backdrop_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Backdrop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-panel'
   Dialog_Panel_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Dip (16.0)))
        .Min_Width (Size (Dip (320.0)))
        .Max_Width (Size (Dip (460.0)))
        .Background (RGB (48, 45, 56))
        .Box_Shadow (Shadow (Dip (0.0), Dip (8.0), Dip (32.0), Dip (0.0), RGBA (0, 0, 0, 0.5)))
        .Padding (CSS_Box (Dip (24.0), Dip (24.0), Dip (24.0), Dip (24.0)))
        .Radius (Radius (Dip (28.0)))
     .Build;

   --  Part styles bundle for class 'dialog-panel'
   Dialog_Panel_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-message'
   Dialog_Message_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Direction (Row)
        .Align_Items (Flex_Start)
        .Gap (Gap (Dip (12.0)))
     .Build;

   --  Style for class 'dialog-message'::icon
   Dialog_Message_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (32.0)))
        .Height (Size (Dip (32.0)))
     .Build;

   --  Style for class 'dialog-message'::label
   Dialog_Message_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (202, 196, 208))
        .Font_Size (Root_Em (0.875))
        .Text_Wrap_Mode (TWM_Wrap)
     .Build;

   --  Part styles bundle for class 'dialog-message'
   Dialog_Message_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Message_Class_Widget, Enabled => True),
      Icon_Part => (Style => Dialog_Message_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Message_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-title'
   Dialog_Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'dialog-title'::label
   Dialog_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (1.5))
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'dialog-title'
   Dialog_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-btn-row'
   Dialog_Btn_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Justify_Content (Flex_End)
        .Gap (Gap (Dip (8.0)))
        .Padding (CSS_Box (Dip (8.0), Dip (0.0), Dip (0.0), Dip (0.0)))
     .Build;

   --  Part styles bundle for class 'dialog-btn-row'
   Dialog_Btn_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Btn_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-btn'
   Dialog_Btn_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Height (Size (Dip (44.0)))
        .Background (RGBA (0, 0, 0, 0.0))
        .Transition ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Dip (0.0), Dip (24.0), Dip (0.0), Dip (24.0)))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (208, 188, 255, 0.08))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGBA (208, 188, 255, 0.12))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Background (RGBA (208, 188, 255, 0.12))
     .Build;

   --  Style for class 'dialog-btn'::label
   Dialog_Btn_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (208, 188, 255))
        .Font_Size (Root_Em (0.875))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'dialog-btn'
   Dialog_Btn_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grid-slider'
   Grid_Slider_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Pct (100.0)))
     .Build;

   --  Part styles bundle for class 'grid-slider'
   Grid_Slider_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grid_Slider_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'slider'
   Slider_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (200.0)))
        .Height (Size (Dip (20.0)))
        .Background (RGB (73, 69, 79))
        .Transition ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (208, 188, 255))
        .Outline_Offset (Dip (2.0))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
     .Build;

   --  Style for class 'slider'::indicator
   Slider_Class_Indicator_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (208, 188, 255))
        .Radius (Radius (Dip (999.0)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
     .Build;

   --  Style for class 'slider'::knob
   Slider_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (20.0)))
        .Background (RGB (230, 225, 229))
        .Transition ((Duration => 0.15, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Pct (50.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGB (208, 188, 255))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGB (208, 188, 255))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
     .Build;

   --  Part styles bundle for class 'slider'
   Slider_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Slider_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Slider_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Slider_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'num-field'
   Num_Field_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (100.0)))
        .Background (RGB (54, 52, 59))
        .Cursor_Style (Cursor_Text)
        .Transition ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color)))
        .Padding (CSS_Box (Dip (10.0), Dip (12.0), Dip (10.0), Dip (12.0)))
        .Border_Width (Border_Width (Dip (0.0), Dip (0.0), Dip (2.0), Dip (0.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (147, 143, 153)))
        .Radius (Radius (Dip (8.0), Dip (8.0), Dip (0.0), Dip (0.0)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Dip (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (208, 188, 255))
        .Outline_Offset (Dip (2.0))
        .Border_Color (Border_Color (RGB (208, 188, 255)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.5)
        .Cursor_Style (Cursor_Default)
     .Build;

   --  Style for class 'num-field'::cursor
   Num_Field_Class_Cursor_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (208, 188, 255))
        .Width (Size (Dip (2.0)))
     .Build;

   --  Style for class 'num-field'::selected
   Num_Field_Class_Selected_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (208, 188, 255, 0.3))
     .Build;

   --  Style for class 'num-field'::text
   Num_Field_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Root_Em (0.875))
     .Build;

   --  Part styles bundle for class 'num-field'
   Num_Field_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Num_Field_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Num_Field_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Num_Field_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Num_Field_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Dip (180.0)))
        .Background (RGB (54, 52, 60))
        .Box_Shadow (Shadow (Dip (0.0), Dip (8.0), Dip (24.0), Dip (0.0), RGBA (0, 0, 0, 0.45)))
        .Padding (CSS_Box (Dip (6.0), Dip (6.0), Dip (6.0), Dip (6.0)))
        .Border_Width (Border_Width (Dip (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (73, 69, 79)))
        .Radius (Radius (Dip (8.0)))
     .Build;

   --  Part styles bundle for class 'context-menu'
   Context_Menu_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu-item'
   Context_Menu_Item_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Dip (28.0)))
        .Background (RGBA (0, 0, 0, 0.0))
        .Padding (CSS_Box (Dip (6.0), Dip (10.0), Dip (6.0), Dip (10.0)))
        .Radius (Radius (Dip (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (208, 188, 255, 0.15))
     .Build;

   --  Style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (230, 225, 229))
        .Font_Size (Dip (13.0))
     .Build;

   --  Part styles bundle for class 'context-menu-item'
   Context_Menu_Item_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Material_Demo_Styles;