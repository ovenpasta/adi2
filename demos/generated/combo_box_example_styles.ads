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

package Combo_Box_Example_Styles is

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
        .Gap (Gap (Px (12.0)))
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (22.0), Px (22.0), Px (22.0), Px (22.0)))
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
        .Flex_Shrink (0.0)
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
        .Flex_Shrink (0.0)
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

   --  Style for class 'combo'
   Combo_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (40.0)))
        .Align_Items (Center)
        .Background (RGB (248, 250, 252))
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Border_Color) + Props (Prop_Box_Shadow) + Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (9.0), Px (10.0), Px (9.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (148, 163, 184)))
        .Radius (Radius (Px (8.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (255, 255, 255))
        .Border_Color (Border_Color (RGB (96, 165, 250)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (37, 99, 235, 0.3)))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     .Build;

   --  Style for class 'combo'::indicator
   Combo_Class_Indicator_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (71, 85, 105))
        .Font_Size (Px (13.0))
        .Text_Align (Text_Center)
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (30, 64, 175))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Text_Color (RGB (30, 58, 138))
     .Build;

   --  Style for class 'combo'::text
   Combo_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (15, 23, 42))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'combo'
   Combo_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Combo_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Combo_Class_Indicator_Widget, Enabled => True),
      Text_Part => (Style => Combo_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dropdown'
   Dropdown_Class_Widget : constant Widget_Style :=
     Style_Of
        .Max_Height (Size (Px (240.0)))
        .Background (RGB (246, 248, 252))
        .Box_Shadow (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 8, 23, 0.22)))
        .Padding (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (191, 201, 216)))
        .Radius (Radius (Px (8.0)))
        .Overflow_X (Overflow_Auto)
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'dropdown'::knob
   Dropdown_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Min_Height (Size (Px (24.0)))
        .Background (RGBA (71, 85, 105, 0.85))
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (6.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (51, 65, 85, 0.95))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (30, 41, 59, 1.0))
     .Build;

   --  Style for class 'dropdown'::scroll
   Dropdown_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (148, 163, 184, 0.22))
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0)))
        .Radius (Radius (Px (6.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (148, 163, 184, 0.42))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (148, 163, 184, 0.58))
     .Build;

   --  Part styles bundle for class 'dropdown'
   Dropdown_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dropdown_Class_Widget, Enabled => True),
      Knob_Part => (Style => Dropdown_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Dropdown_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'option-row'
   Option_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (C (White))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Margin (CSS_Box (Px (2.0), Px (0.0), Px (2.0), Px (0.0)))
        .Border_Width (Border_Width (Px (0.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (222, 229, 238)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (239, 246, 255))
        .Border_Color (Border_Color (RGB (147, 197, 253)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (29, 78, 216)))
     .Build;

   --  Style for class 'option-row'::label
   Option_Row_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (30, 41, 59))
        .Font_Size (Px (14.0))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Color)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Text_Color (RGB (15, 23, 42))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (C (White))
     .Build;

   --  Part styles bundle for class 'option-row'
   Option_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Option_Row_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Row_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Combo_Box_Example_Styles;