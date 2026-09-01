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

package Dialog_Example_Styles is

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
        .Align_Items (Stretch)
        .Justify_Content (Flex_Start)
        .Gap (Gap (Px (12.0)))
        .Background (RGB (19, 26, 38))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Stretch)
        .Justify_Content (Flex_Start)
        .Gap (Gap (Px (16.0)))
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (22.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'hint'
   Hint_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (186, 204, 230))
        .Font_Size (Px (13.0))
        .Text_Wrap_Mode (TWM_Wrap)
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (147, 197, 253))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'btn-primary'
   Btn_Primary_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (40.0)))
        .Background (RGB (37, 99, 235))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (9.0), Px (16.0), Px (9.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (29, 78, 216)))
        .Radius (Radius (Px (8.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (29, 78, 216))
        .Border_Color (Border_Color (RGB (30, 64, 175)))
     .Build;

   --  Style for class 'btn-primary'::label
   Btn_Primary_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Align (Text_Center)
        .Vertical_Align (VA_Middle)
        .White_Space (WS_Nowrap)
     .Build;

   --  Part styles bundle for class 'btn-primary'
   Btn_Primary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'backdrop'
   Backdrop_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (0, 0, 0, 0.45))
     .Build;

   --  Part styles bundle for class 'backdrop'
   Backdrop_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Backdrop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel'
   Panel_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Stretch)
        .Gap (Gap (Px (16.0)))
        .Min_Width (Size (Px (260.0)))
        .Max_Width (Size (Px (380.0)))
        .Background (RGB (255, 255, 255))
        .Box_Shadow (Shadow (Px (0.0), Px (16.0), Px (48.0), Px (0.0), RGBA (0, 0, 0, 0.3)))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'panel'
   Panel_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-message'
   Dialog_Message_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Direction (Row)
        .Align_Items (Flex_Start)
        .Gap (Gap (Px (12.0)))
     .Build;

   --  Style for class 'dialog-message'::icon
   Dialog_Message_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (32.0)))
        .Height (Size (Px (32.0)))
     .Build;

   --  Style for class 'dialog-message'::label
   Dialog_Message_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (71, 85, 105))
        .Font_Size (Px (14.0))
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
     .Build;

   --  Style for class 'dialog-title'::label
   Dialog_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (15, 23, 42))
        .Font_Size (Px (18.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'dialog-title'
   Dialog_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'button-row'
   Button_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Justify_Content (Flex_End)
        .Align_Items (Center)
        .Gap (Gap (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'button-row'
   Button_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Button_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-btn'
   Dialog_Btn_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (36.0)))
        .Background (RGB (241, 245, 249))
        .Transition ((Duration => 0.12, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (7.0), Px (16.0), Px (7.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (203, 213, 225)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (226, 232, 240))
        .Border_Color (Border_Color (RGB (148, 163, 184)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (203, 213, 225))
        .Border_Color (Border_Color (RGB (100, 116, 139)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (59, 130, 246, 0.3)))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
     .Build;

   --  Style for class 'dialog-btn'::label
   Dialog_Btn_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (30, 41, 59))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Medium)
        .Text_Align (Text_Center)
        .Vertical_Align (VA_Middle)
        .White_Space (WS_Nowrap)
     .Build;

   --  Part styles bundle for class 'dialog-btn'
   Dialog_Btn_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dialog-btn-primary'
   Dialog_Btn_Primary_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (36.0)))
        .Background (RGB (37, 99, 235))
        .Transition ((Duration => 0.12, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (7.0), Px (16.0), Px (7.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (29, 78, 216)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (29, 78, 216))
        .Border_Color (Border_Color (RGB (30, 64, 175)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (59, 130, 246, 0.3)))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
     .Build;

   --  Style for class 'dialog-btn-primary'::label
   Dialog_Btn_Primary_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Align (Text_Center)
        .Vertical_Align (VA_Middle)
        .White_Space (WS_Nowrap)
     .Build;

   --  Part styles bundle for class 'dialog-btn-primary'
   Dialog_Btn_Primary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dialog_Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'custom-content'
   Custom_Content_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (248, 250, 252))
        .Padding (CSS_Box (Px (12.0), Px (16.0), Px (12.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (226, 232, 240)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'custom-content'
   Custom_Content_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Custom_Content_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'detail-label'::label
   Detail_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (51, 65, 85))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'detail-label'
   Detail_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Detail_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Dialog_Example_Styles;