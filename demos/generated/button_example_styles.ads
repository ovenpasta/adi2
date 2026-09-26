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

package Button_Example_Styles is

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
        .Background (RGB (30, 30, 36))
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
        .Flex_Grow (1.0)
        .Gap (Gap (Px (24.0)))
        .Padding (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0)))
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section-row'
   Section_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (12.0)))
        .Align_Items (Center)
     .Build;

   --  Part styles bundle for class 'section-row'
   Section_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section-row-2'
   Section_Row_2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
     .Build;

   --  Part styles bundle for class 'section-row-2'
   Section_Row_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Row_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'primary'
   Primary_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (59, 130, 246))
        .Cursor_Style (Cursor_Pointer)
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (59, 130, 246, 0.5)))
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0)))
        .Border_Width (Border_Width (Px (0.0)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (37, 99, 235))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (3.0), RGBA (96, 165, 250, 0.7)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (29, 58, 145))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (4.0), Px (1.0), RGBA (37, 99, 235, 0.6)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGBA (191, 219, 254, 0.9))
        .Outline_Offset (Px (2.0))
     .Build;

   --  Style for class 'primary'::label
   Primary_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Align (Text_Center)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'primary'
   Primary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'danger'
   Danger_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (220, 38, 38))
        .Cursor_Style (Cursor_Pointer)
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (220, 38, 38, 0.5)))
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0)))
        .Border_Width (Border_Width (Px (0.0)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (185, 28, 28))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (3.0), RGBA (248, 113, 113, 0.7)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (153, 27, 27))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (4.0), Px (1.0), RGBA (185, 28, 28, 0.6)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGBA (254, 202, 202, 0.9))
        .Outline_Offset (Px (2.0))
     .Build;

   --  Style for class 'danger'::label
   Danger_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'danger'
   Danger_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Danger_Class_Widget, Enabled => True),
      Label_Part => (Style => Danger_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'outline'
   Outline_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGBA (0, 0, 0, 0.0))
        .Cursor_Style (Cursor_Pointer)
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (148, 163, 184, 0.35)))
        .Transition ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Padding (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (148, 163, 184)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (148, 163, 184, 0.15))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (3.0), RGBA (203, 213, 225, 0.55)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGBA (148, 163, 184, 0.25))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (4.0), Px (1.0), RGBA (148, 163, 184, 0.45)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGBA (147, 197, 253, 0.6))
        .Outline_Offset (Px (2.0))
        .Border_Color (Border_Color (RGB (96, 165, 250)))
     .Build;

   --  Style for class 'outline'::label
   Outline_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (226, 232, 240))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'outline'
   Outline_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Outline_Class_Widget, Enabled => True),
      Label_Part => (Style => Outline_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'toggle'
   Toggle_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (75, 85, 99))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0)))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (107, 114, 128)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (90, 100, 114))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (55, 65, 81))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (22, 163, 74))
        .Border_Color (Border_Color (RGB (21, 128, 61)))
     --  widget State_Selected, widget State_Pressed
     .On (When_State (State_Selected) and When_State (State_Pressed))
        .Background (RGB (21, 128, 61))
        .Border_Color (Border_Color (RGB (20, 110, 55)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGBA (96, 165, 250, 0.55))
        .Outline_Offset (Px (2.0))
        .Border_Color (Border_Color (RGB (147, 197, 253)))
     .Build;

   --  Style for class 'toggle'::label
   Toggle_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'toggle'
   Toggle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Toggle_Class_Widget, Enabled => True),
      Label_Part => (Style => Toggle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'switch'
   Switch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (56.0)))
        .Height (Size (Px (32.0)))
        .Background (RGB (71, 85, 105))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (148, 163, 184, 0.4)))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.28, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color) + Props (Prop_Box_Shadow)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (148, 163, 184, 0.55)))
        .Radius (Radius (Px (16.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (100, 116, 139))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (3.0), RGBA (203, 213, 225, 0.65)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (51, 65, 85))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (6.0), Px (2.0), RGBA (148, 163, 184, 0.55)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (16, 185, 129))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (12.0), Px (4.0), RGBA (52, 211, 153, 0.55)))
        .Border_Color (Border_Color (RGB (5, 150, 105)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (5, 150, 105))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (14.0), Px (5.0), RGBA (110, 231, 183, 0.7)))
        .Border_Color (Border_Color (RGB (4, 120, 87)))
     --  widget State_Selected, widget State_Pressed
     .On (When_State (State_Selected) and When_State (State_Pressed))
        .Background (RGB (4, 120, 87))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (52, 211, 153, 0.5)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGBA (134, 239, 172, 0.6))
        .Outline_Offset (Px (2.0))
     .Build;

   --  Style for class 'switch'::knob
   Switch_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (26.0)))
        .Height (Size (Px (26.0)))
        .Background (RGB (248, 250, 252))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (6.0), Px (1.0), RGBA (15, 23, 42, 0.22)))
        .Transition ((Duration => 0.26, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow)))
        .Margin (CSS_Box (Px (0.0), Px (2.0), Px (0.0), Px (2.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (15, 23, 42, 0.12)))
        .Radius (Radius (Px (13.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGB (255, 255, 255))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (15, 23, 42, 0.28)))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGB (241, 245, 249))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (4.0), Px (1.0), RGBA (15, 23, 42, 0.18)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (240, 253, 244))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (5, 150, 105, 0.3)))
     .Build;

   --  Part styles bundle for class 'switch'
   Switch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'option-left'
   Option_Left_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (8.0), Px (16.0), Px (8.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
        .Radius (Radius (Px (6.0), Px (0.0), Px (0.0), Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 85, 99))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Border_Color (Border_Color (RGB (147, 197, 253)))
     .Build;

   --  Style for class 'option-left'::label
   Option_Left_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'option-left'
   Option_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Option_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'option-center'
   Option_Center_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (8.0), Px (16.0), Px (8.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 85, 99))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Border_Color (Border_Color (RGB (147, 197, 253)))
     .Build;

   --  Style for class 'option-center'::label
   Option_Center_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'option-center'
   Option_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Option_Center_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Center_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'option-right'
   Option_Right_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (8.0), Px (16.0), Px (8.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
        .Radius (Radius (Px (0.0), Px (6.0), Px (6.0), Px (0.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 85, 99))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Border_Color (Border_Color (RGB (147, 197, 253)))
     .Build;

   --  Style for class 'option-right'::label
   Option_Right_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'option-right'
   Option_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Option_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Button_Example_Styles;