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

package RLottie_Example_Styles is

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
        .Background (RGB (36, 41, 62))
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
        .Gap (Gap (Px (4.0)))
        .Background (RGB (90, 98, 132))
        .Padding (CSS_Box (Px (12.0), Px (14.0), Px (12.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (164, 171, 196)))
        .Radius (Radius (Px (8.0)))
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
        .Text_Color (RGB (239, 244, 255))
        .Font_Size (Px (24.0))
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
        .Text_Color (RGB (214, 220, 236))
        .Font_Size (Px (13.0))
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'deck'
   Deck_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Gap (Gap (Px (12.0)))
        .Background (RGB (62, 69, 102))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (170, 177, 205)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'deck'
   Deck_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Deck_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grid'
   Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (4))
        .Grid_Columns ((Count => 4, Tracks => [1 => (Track_Px, 90.0), 2 => (Track_Px, 90.0), 3 => (Track_Px, 90.0), 4 => (Track_Px, 90.0), others => <>]))
        .Gap (Gap (Px (10.0)))
        .Align_Self (Center)
        .Background (RGB (20, 24, 36))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (102, 111, 144)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'grid'
   Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cell'
   Cell_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Center)
        .Gap (Gap (Px (6.0)))
        .Background (RGB (8, 10, 18))
        .Padding (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (72, 82, 112)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Part styles bundle for class 'cell'
   Cell_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cell_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'emoji'
   Emoji_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (72.0)))
        .Height (Size (Px (72.0)))
        .Flex_Grow (0.0)
        .Flex_Shrink (0.0)
        .Align_Self (Center)
        .Padding (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (0.0)))
     .Build;

   --  Part styles bundle for class 'emoji'
   Emoji_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Emoji_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'caption'::label
   Caption_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (186, 195, 220))
        .Font_Size (Px (11.0))
        .Font_Weight (Weight_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'caption'
   Caption_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'transport'
   Transport_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (58, 66, 96))
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (154, 162, 192)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'transport'
   Transport_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Transport_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'play-button'
   Play_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (112.0)))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Background (RGB (106, 186, 92))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (198, 247, 180)))
        .Radius (Radius (Px (4.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (122, 204, 108))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (92, 166, 78))
     .Build;

   --  Style for class 'play-button'::label
   Play_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (248, 250, 255))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Extra_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'play-button'
   Play_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Play_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Play_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'pause-button'
   Pause_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (112.0)))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Background (RGB (201, 102, 92))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (255, 189, 177)))
        .Radius (Radius (Px (4.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (216, 116, 106))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (184, 88, 78))
     .Build;

   --  Style for class 'pause-button'::label
   Pause_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (248, 250, 255))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Extra_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'pause-button'
   Pause_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pause_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Pause_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'reset-button'
   Reset_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (112.0)))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Background (RGB (106, 134, 199))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (180, 203, 255)))
        .Radius (Radius (Px (4.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (122, 150, 215))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (91, 118, 179))
     .Build;

   --  Style for class 'reset-button'::label
   Reset_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (248, 250, 255))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Extra_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'reset-button'
   Reset_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Reset_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Reset_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'speed-button'
   Speed_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (112.0)))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Background (RGB (130, 108, 194))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (210, 189, 255)))
        .Radius (Radius (Px (4.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (148, 126, 212))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (113, 92, 176))
     .Build;

   --  Style for class 'speed-button'::label
   Speed_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (248, 250, 255))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Extra_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'speed-button'
   Speed_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Speed_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Speed_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (15, 22, 16))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (89, 161, 96)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (135, 233, 125))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Bold)
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

end RLottie_Example_Styles;