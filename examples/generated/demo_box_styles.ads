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

package Demo_Box_Styles is

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
        .Gap (Gap (Px (18.0)))
        .Background (RGB (24, 26, 33))
        .Padding (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.1)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.28)))
     .Build;

   --  Style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (94, 129, 172, 0.06))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (94, 129, 172, 0.16))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (236, 239, 244))
        .Font_Size (Px (22.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section'
   Section_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (6.0)))
        .Flex_Shrink (0.0)
        .Padding (Right, Px (14.0))
     .Build;

   --  Part styles bundle for class 'section'
   Section_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'caption'::label
   Caption_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (163, 190, 140))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'caption'
   Caption_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'note'::label
   Note_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (150, 158, 172))
        .Font_Size (Px (12.0))
     .Build;

   --  Part styles bundle for class 'note'
   Note_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Note_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cases'
   Cases_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Flex_Wrap (Wrap)
        .Gap (Gap (Px (12.0)))
        .Flex_Shrink (0.0)
     .Build;

   --  Part styles bundle for class 'cases'
   Cases_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cases_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'case'
   Case_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (4.0)))
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (1.0)
        .Min_Width (Size (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'case'
   Case_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Case_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'case-label'::label
   Case_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (150, 158, 172))
        .Font_Size (Px (11.0))
     .Build;

   --  Part styles bundle for class 'case-label'
   Case_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Case_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'stage'
   Stage_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (35, 38, 48))
        .Padding (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'stage'
   Stage_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Stage_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'swatch'
   Swatch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (52.0)))
        .Border_Style (Border_Style (Solid))
     .Build;

   --  Part styles bundle for class 'swatch'
   Swatch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Swatch_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'filled'
   Filled_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (94, 129, 172))
     .Build;

   --  Part styles bundle for class 'filled'
   Filled_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Filled_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bw-uniform'
   Bw_Uniform_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (46, 52, 64))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Color (Border_Color (RGB (136, 192, 208)))
     .Build;

   --  Part styles bundle for class 'bw-uniform'
   Bw_Uniform_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bw_Uniform_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bw-sides'
   Bw_Sides_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (46, 52, 64))
        .Border_Width (Border_Width (Px (1.0), Px (4.0), Px (8.0), Px (2.0)))
        .Border_Color (Border_Color (RGB (136, 192, 208)))
     .Build;

   --  Part styles bundle for class 'bw-sides'
   Bw_Sides_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bw_Sides_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bw-accent'
   Bw_Accent_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (46, 52, 64))
        .Border_Width (Border_Width (Px (0.0), Px (0.0), Px (0.0), Px (6.0)))
        .Border_Color (Border_Color (RGB (235, 203, 139)))
     .Build;

   --  Part styles bundle for class 'bw-accent'
   Bw_Accent_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bw_Accent_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'four-colours'
   Four_Colours_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (46, 52, 64))
        .Border_Width (Border_Width (Px (5.0)))
        .Border_Color (Border_Color (RGB (191, 97, 106), RGB (163, 190, 140), RGB (94, 129, 172), RGB (235, 203, 139)))
     .Build;

   --  Part styles bundle for class 'four-colours'
   Four_Colours_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Four_Colours_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'rounded'
   Rounded_Class_Widget : constant Widget_Style :=
     Style_Of
        .Radius (Radius (Px (16.0)))
     .Build;

   --  Part styles bundle for class 'rounded'
   Rounded_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Rounded_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'raised'
   Raised_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (76, 86, 106))
        .Border_Width (Border_Width (Px (3.0)))
        .Border_Color (Border_Color (RGB (216, 222, 233), RGB (15, 17, 22), RGB (15, 17, 22), RGB (216, 222, 233)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'raised'
   Raised_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Raised_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'sunken'
   Sunken_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (59, 66, 82))
        .Border_Width (Border_Width (Px (3.0)))
        .Border_Color (Border_Color (RGB (15, 17, 22), RGB (216, 222, 233), RGB (216, 222, 233), RGB (15, 17, 22)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'sunken'
   Sunken_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sunken_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'r-12'
   R_12_Class_Widget : constant Widget_Style :=
     Style_Of
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'r-12'
   R_12_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => R_12_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'r-alternate'
   R_Alternate_Class_Widget : constant Widget_Style :=
     Style_Of
        .Radius (Radius (Px (20.0), Px (4.0)))
     .Build;

   --  Part styles bundle for class 'r-alternate'
   R_Alternate_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => R_Alternate_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'r-top'
   R_Top_Class_Widget : constant Widget_Style :=
     Style_Of
        .Radius (Radius (Px (12.0), Px (12.0), Px (0.0), Px (0.0)))
     .Build;

   --  Part styles bundle for class 'r-top'
   R_Top_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => R_Top_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'r-pill'
   R_Pill_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (46, 52, 64))
        .Border_Width (Border_Width (Px (2.0), Px (2.0), Px (6.0), Px (2.0)))
        .Border_Color (Border_Color (RGB (180, 142, 173)))
        .Radius (Radius (Px (26.0)))
     .Build;

   --  Part styles bundle for class 'r-pill'
   R_Pill_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => R_Pill_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ol-plain'
   Ol_Plain_Class_Widget : constant Widget_Style :=
     Style_Of
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (235, 203, 139))
     .Build;

   --  Part styles bundle for class 'ol-plain'
   Ol_Plain_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ol_Plain_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ol-offset'
   Ol_Offset_Class_Widget : constant Widget_Style :=
     Style_Of
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (235, 203, 139))
        .Outline_Offset (Px (4.0))
     .Build;

   --  Part styles bundle for class 'ol-offset'
   Ol_Offset_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ol_Offset_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ol-rounded'
   Ol_Rounded_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (46, 52, 64))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (235, 203, 139))
        .Outline_Offset (Px (3.0))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Color (Border_Color (RGB (136, 192, 208)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'ol-rounded'
   Ol_Rounded_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ol_Rounded_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'sh-drop'
   Sh_Drop_Class_Widget : constant Widget_Style :=
     Style_Of
        .Box_Shadow (Shadow (Px (0.0), Px (4.0), Px (10.0), Px (0.0), RGBA (0, 0, 0, 0.6)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'sh-drop'
   Sh_Drop_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sh_Drop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'sh-hard'
   Sh_Hard_Class_Widget : constant Widget_Style :=
     Style_Of
        .Box_Shadow (Shadow (Px (6.0), Px (6.0), Px (0.0), Px (0.0), RGB (15, 17, 22)))
     .Build;

   --  Part styles bundle for class 'sh-hard'
   Sh_Hard_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sh_Hard_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'sh-glow'
   Sh_Glow_Class_Widget : constant Widget_Style :=
     Style_Of
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (12.0), Px (2.0), RGBA (136, 192, 208, 0.7)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'sh-glow'
   Sh_Glow_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sh_Glow_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bg-gradient'
   Bg_Gradient_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGB (94, 129, 172)), Gradient_Stop_Auto (RGB (180, 142, 173)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Width (Border_Width (Px (0.0)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'bg-gradient'
   Bg_Gradient_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bg_Gradient_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bg-over-colour'
   Bg_Over_Colour_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (163, 190, 140))
        .Background_Image (Linear_Gradient (180.0, [Gradient_Stop_Auto (RGBA (46, 52, 64, 0.0)), Gradient_Stop_Auto (RGBA (46, 52, 64, 0.9)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.35)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'bg-over-colour'
   Bg_Over_Colour_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bg_Over_Colour_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bg-faded'
   Bg_Faded_Class_Widget : constant Widget_Style :=
     Style_Of
        .Opacity (0.5)
     .Build;

   --  Part styles bundle for class 'bg-faded'
   Bg_Faded_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bg_Faded_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Demo_Box_Styles;