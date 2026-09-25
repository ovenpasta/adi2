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

package Animated_Image_Example_Styles is

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
        .Gap (Gap (Px (14.0)))
        .Background (RGB (14, 18, 28))
        .Padding (CSS_Box (Px (20.0), Px (24.0), Px (20.0), Px (24.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'header'
   Header_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (6.0)))
        .Background (RGBA (30, 41, 59, 0.55))
        .Box_Shadow (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 6, 23, 0.5)))
        .Padding (CSS_Box (Px (14.0), Px (18.0), Px (14.0), Px (18.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (148, 163, 184, 0.35)))
        .Radius (Radius (Px (14.0)))
     .Build;

   --  Part styles bundle for class 'header'
   Header_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (241, 245, 249))
        .Font_Size (Px (30.0))
        .Font_Weight (Weight_Extra_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'viewer-frame'
   Viewer_Frame_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Background (RGBA (15, 23, 42, 0.85))
        .Box_Shadow (Shadow (Px (0.0), Px (16.0), Px (36.0), Px (0.0), RGBA (2, 6, 23, 0.58)))
        .Padding (CSS_Box (Px (18.0), Px (18.0), Px (18.0), Px (18.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (59, 130, 246, 0.35)))
        .Radius (Radius (Px (18.0)))
     .Build;

   --  Part styles bundle for class 'viewer-frame'
   Viewer_Frame_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Viewer_Frame_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'viewer'
   Viewer_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (340.0)))
        .Background (RGBA (2, 6, 23, 0.7))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (148, 163, 184, 0.25)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Style for class 'viewer'::icon
   Viewer_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
        .Object_Position (Object_Position (Pos_Center, Pos_Center))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'viewer'
   Viewer_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Viewer_Class_Widget, Enabled => True),
      Icon_Part => (Style => Viewer_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'controls'
   Controls_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Justify_Content (Center)
        .Gap (Gap (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'controls'
   Controls_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Controls_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'action-button'
   Action_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (136.0)))
        .Background (RGB (30, 64, 175))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.18, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
        .Radius (Radius (Px (10.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (37, 99, 235))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (29, 78, 216))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (147, 197, 253, 0.42)))
     .Build;

   --  Style for class 'action-button'::label
   Action_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (239, 246, 255))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'action-button'
   Action_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Action_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Action_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'loop-button'
   Loop_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (136.0)))
        .Background (RGB (220, 38, 38))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.18, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (239, 68, 68)))
        .Radius (Radius (Px (10.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (239, 68, 68))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (185, 28, 28))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (22, 163, 74))
        .Border_Color (Border_Color (RGB (34, 197, 94)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (21, 128, 61))
     --  widget State_Selected, widget State_Pressed
     .On (When_State (State_Selected) and When_State (State_Pressed))
        .Background (RGB (20, 110, 55))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (134, 239, 172, 0.4)))
     .Build;

   --  Style for class 'loop-button'::label
   Loop_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (240, 253, 244))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'loop-button'
   Loop_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Loop_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Loop_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (15, 23, 42, 0.76))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0)))
        .Margin (Top, Margin (Px (4.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (71, 85, 105, 0.85)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (125, 211, 252))
        .Font_Size (Px (13.0))
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Animated_Image_Example_Styles;