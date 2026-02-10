--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Font_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Overflow => Set (Overflow_Auto),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (20.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      others => <>
   );

   --  Base style for root::knob
   Root_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (226, 232, 240, 0.8)),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for root::knob when part State_Hovered
   Root_Knob_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (241, 245, 249, 0.94)),
      others => <>
   );

   --  Style for root::knob when part State_Pressed
   Root_Knob_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (248, 250, 252, 1.0)),
      others => <>
   );

   --  Base style for root::scroll
   Root_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (8.0))),
      Padding => Set (CSS_Box (Px (2.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.24)),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for root::scroll when part State_Hovered
   Root_Scroll_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.42)),
      others => <>
   );

   --  Style for root::scroll when part State_Pressed
   Root_Scroll_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.62)),
      others => <>
   );

   --  Base style for container
   Container_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (10.0))),
      Padding => Set (CSS_Box (Px (16.0))),
      Background_Color => Set_Bg (RGB (31, 41, 55)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for title::label
   Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for hint::label
   Hint_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (191, 219, 254)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Base style for section_title::label
   Section_Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for sample
   Sample_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (15, 23, 42)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for sample::label
   Sample_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Px (18.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for weight_normal::label
   Weight_Normal_Label_Base_Style : constant Style_Rules := (
      Font_Weight => Set (Weight_Normal),
      others => <>
   );

   --  Base style for weight_light::label
   Weight_Light_Label_Base_Style : constant Style_Rules := (
      Font_Weight => Set (Weight_Light),
      others => <>
   );

   --  Base style for weight_medium::label
   Weight_Medium_Label_Base_Style : constant Style_Rules := (
      Font_Weight => Set (Weight_Medium),
      others => <>
   );

   --  Base style for weight_semibold::label
   Weight_Semibold_Label_Base_Style : constant Style_Rules := (
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for weight_bold::label
   Weight_Bold_Label_Base_Style : constant Style_Rules := (
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for weight_black::label
   Weight_Black_Label_Base_Style : constant Style_Rules := (
      Font_Weight => Set (Weight_Black),
      others => <>
   );

   --  Base style for style_italic::label
   Style_Italic_Label_Base_Style : constant Style_Rules := (
      Font_Style => Set (Style_Italic),
      others => <>
   );

   --  Base style for style_oblique::label
   Style_Oblique_Label_Base_Style : constant Style_Rules := (
      Font_Style => Set (Style_Oblique),
      others => <>
   );

   --  Base style for size_small::label
   Size_Small_Label_Base_Style : constant Style_Rules := (
      Font_Size => Set_Font (Px (12.0)),
      others => <>
   );

   --  Base style for size_base::label
   Size_Base_Label_Base_Style : constant Style_Rules := (
      Font_Size => Set_Font (Px (18.0)),
      others => <>
   );

   --  Base style for size_large::label
   Size_Large_Label_Base_Style : constant Style_Rules := (
      Font_Size => Set_Font (Px (28.0)),
      others => <>
   );

   --  Base style for decor_underline::label
   Decor_Underline_Label_Base_Style : constant Style_Rules := (
      Text_Decoration => Set (Decoration_Underline),
      others => <>
   );

   --  Base style for decor_strike::label
   Decor_Strike_Label_Base_Style : constant Style_Rules := (
      Text_Decoration => Set (Decoration_Line_Through),
      others => <>
   );

   --  Base style for decor_overline::label
   Decor_Overline_Label_Base_Style : constant Style_Rules := (
      Text_Decoration => Set (Decoration_Overline),
      others => <>
   );

   --  Base style for wrap_sample
   Wrap_Sample_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (100, 116, 139))),
      Border_Radius => Set (Radius (Px (8.0))),
      Min_Height => Set (Size (Px (56.0))),
      others => <>
   );

   --  Base style for wrap_sample::label
   Wrap_Sample_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (219, 234, 254)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Complete widget style for root
   Root_Widget : constant Widget_Style :=
     From (Root_Base_Style)
     .Build;

   --  Complete widget style for root::knob
   Root_Knob_Widget : constant Widget_Style :=
     From (Root_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Root_Knob_Part_Pressed_Style)
     .Build;

   --  Complete widget style for root::scroll
   Root_Scroll_Widget : constant Widget_Style :=
     From (Root_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Scroll_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Root_Scroll_Part_Pressed_Style)
     .Build;

   --  Part styles bundle for root
   Root_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Widget, Enabled => True),
      Knob_Part => (Style => Root_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for container
   Container_Widget : constant Widget_Style :=
     From (Container_Base_Style)
     .Build;

   --  Part styles bundle for container
   Container_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Container_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for title::label
   Title_Label_Widget : constant Widget_Style :=
     From (Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for title
   Title_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Title_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for hint::label
   Hint_Label_Widget : constant Widget_Style :=
     From (Hint_Label_Base_Style)
     .Build;

   --  Part styles bundle for hint
   Hint_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Hint_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for section_title::label
   Section_Title_Label_Widget : constant Widget_Style :=
     From (Section_Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for section_title
   Section_Title_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Section_Title_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for sample
   Sample_Widget : constant Widget_Style :=
     From (Sample_Base_Style)
     .Build;

   --  Complete widget style for sample::label
   Sample_Label_Widget : constant Widget_Style :=
     From (Sample_Label_Base_Style)
     .Build;

   --  Part styles bundle for sample
   Sample_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Sample_Widget, Enabled => True),
      Label_Part => (Style => Sample_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for weight_normal::label
   Weight_Normal_Label_Widget : constant Widget_Style :=
     From (Weight_Normal_Label_Base_Style)
     .Build;

   --  Part styles bundle for weight_normal
   Weight_Normal_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Weight_Normal_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for weight_light::label
   Weight_Light_Label_Widget : constant Widget_Style :=
     From (Weight_Light_Label_Base_Style)
     .Build;

   --  Part styles bundle for weight_light
   Weight_Light_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Weight_Light_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for weight_medium::label
   Weight_Medium_Label_Widget : constant Widget_Style :=
     From (Weight_Medium_Label_Base_Style)
     .Build;

   --  Part styles bundle for weight_medium
   Weight_Medium_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Weight_Medium_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for weight_semibold::label
   Weight_Semibold_Label_Widget : constant Widget_Style :=
     From (Weight_Semibold_Label_Base_Style)
     .Build;

   --  Part styles bundle for weight_semibold
   Weight_Semibold_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Weight_Semibold_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for weight_bold::label
   Weight_Bold_Label_Widget : constant Widget_Style :=
     From (Weight_Bold_Label_Base_Style)
     .Build;

   --  Part styles bundle for weight_bold
   Weight_Bold_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Weight_Bold_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for weight_black::label
   Weight_Black_Label_Widget : constant Widget_Style :=
     From (Weight_Black_Label_Base_Style)
     .Build;

   --  Part styles bundle for weight_black
   Weight_Black_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Weight_Black_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for style_italic::label
   Style_Italic_Label_Widget : constant Widget_Style :=
     From (Style_Italic_Label_Base_Style)
     .Build;

   --  Part styles bundle for style_italic
   Style_Italic_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Style_Italic_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for style_oblique::label
   Style_Oblique_Label_Widget : constant Widget_Style :=
     From (Style_Oblique_Label_Base_Style)
     .Build;

   --  Part styles bundle for style_oblique
   Style_Oblique_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Style_Oblique_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for size_small::label
   Size_Small_Label_Widget : constant Widget_Style :=
     From (Size_Small_Label_Base_Style)
     .Build;

   --  Part styles bundle for size_small
   Size_Small_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Size_Small_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for size_base::label
   Size_Base_Label_Widget : constant Widget_Style :=
     From (Size_Base_Label_Base_Style)
     .Build;

   --  Part styles bundle for size_base
   Size_Base_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Size_Base_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for size_large::label
   Size_Large_Label_Widget : constant Widget_Style :=
     From (Size_Large_Label_Base_Style)
     .Build;

   --  Part styles bundle for size_large
   Size_Large_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Size_Large_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for decor_underline::label
   Decor_Underline_Label_Widget : constant Widget_Style :=
     From (Decor_Underline_Label_Base_Style)
     .Build;

   --  Part styles bundle for decor_underline
   Decor_Underline_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Decor_Underline_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for decor_strike::label
   Decor_Strike_Label_Widget : constant Widget_Style :=
     From (Decor_Strike_Label_Base_Style)
     .Build;

   --  Part styles bundle for decor_strike
   Decor_Strike_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Decor_Strike_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for decor_overline::label
   Decor_Overline_Label_Widget : constant Widget_Style :=
     From (Decor_Overline_Label_Base_Style)
     .Build;

   --  Part styles bundle for decor_overline
   Decor_Overline_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Decor_Overline_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for wrap_sample
   Wrap_Sample_Widget : constant Widget_Style :=
     From (Wrap_Sample_Base_Style)
     .Build;

   --  Complete widget style for wrap_sample::label
   Wrap_Sample_Label_Widget : constant Widget_Style :=
     From (Wrap_Sample_Label_Base_Style)
     .Build;

   --  Part styles bundle for wrap_sample
   Wrap_Sample_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Wrap_Sample_Widget, Enabled => True),
      Label_Part => (Style => Wrap_Sample_Label_Widget, Enabled => True),
      others => <>
   ];

end Font_Example_Styles;