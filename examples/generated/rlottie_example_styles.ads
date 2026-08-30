--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package RLottie_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   function Root_Part_Styles return Part_Style_Array is (Empty_Part_Styles);

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Adi.Widget.Intern (Root_Part_Styles),
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);
   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (14.0))),
      Background_Color => Set_Bg (RGB (36, 41, 62)),
      Padding => Set (CSS_Box (Px (20.0), Px (24.0), Px (20.0), Px (24.0))),
      others => <>);

   --  Base style for class 'header'
   function Header_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (4.0))),
      Background_Color => Set_Bg (RGB (90, 98, 132)),
      Padding => Set (CSS_Box (Px (12.0), Px (14.0), Px (12.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (164, 171, 196))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (239, 244, 255)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      others => <>);

   --  Base style for class 'subtitle'
   function Subtitle_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'subtitle'::label
   function Subtitle_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (214, 220, 236)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Base style for class 'deck'
   function Deck_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (62, 69, 102)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (170, 177, 205))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'grid'
   function Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Px, 90.0), 2 => (Track_Px, 90.0), 3 => (Track_Px, 90.0), 4 => (Track_Px, 90.0), others => <>]),
      Gap => Set (Gap (Px (10.0))),
      Align_Self => Set (Center),
      Background_Color => Set_Bg (RGB (20, 24, 36)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (102, 111, 144))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'cell'
   function Cell_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (6.0))),
      Background_Color => Set_Bg (RGB (8, 10, 18)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (72, 82, 112))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'emoji'
   function Emoji_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (72.0))),
      Height => Set (Size (Px (72.0))),
      Flex_Grow => Set (0.0),
      Flex_Shrink => Set (0.0),
      Align_Self => Set (Center),
      Padding => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Base style for class 'caption'::label
   function Caption_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (186, 195, 220)),
      Font_Size => Set_Font (Px (11.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'transport'
   function Transport_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (58, 66, 96)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (154, 162, 192))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'play-button'
   function Play_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (112.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Background_Color => Set_Bg (RGB (106, 186, 92)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (198, 247, 180))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'play-button' when widget State_Hovered
   function Play_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (122, 204, 108)),
      others => <>);

   --  Style for class 'play-button' when widget State_Pressed
   function Play_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (92, 166, 78)),
      others => <>);

   --  Base style for class 'play-button'::label
   function Play_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 250, 255)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'pause-button'
   function Pause_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (112.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Background_Color => Set_Bg (RGB (201, 102, 92)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (255, 189, 177))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'pause-button' when widget State_Hovered
   function Pause_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (216, 116, 106)),
      others => <>);

   --  Style for class 'pause-button' when widget State_Pressed
   function Pause_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (184, 88, 78)),
      others => <>);

   --  Base style for class 'pause-button'::label
   function Pause_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 250, 255)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'reset-button'
   function Reset_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (112.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Background_Color => Set_Bg (RGB (106, 134, 199)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (180, 203, 255))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'reset-button' when widget State_Hovered
   function Reset_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (122, 150, 215)),
      others => <>);

   --  Style for class 'reset-button' when widget State_Pressed
   function Reset_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (91, 118, 179)),
      others => <>);

   --  Base style for class 'reset-button'::label
   function Reset_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 250, 255)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'speed-button'
   function Speed_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (112.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Background_Color => Set_Bg (RGB (130, 108, 194)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (210, 189, 255))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'speed-button' when widget State_Hovered
   function Speed_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (148, 126, 212)),
      others => <>);

   --  Style for class 'speed-button' when widget State_Pressed
   function Speed_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (113, 92, 176)),
      others => <>);

   --  Base style for class 'speed-button'::label
   function Speed_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 250, 255)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'status'
   function Status_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (15, 22, 16)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (89, 161, 96))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (135, 233, 125)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Bold),
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

   --  Complete widget style for class 'header'
   function Header_Class_Widget return Widget_Style is
     (From (Header_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'header'
   function Header_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'
   function Title_Class_Widget return Widget_Style is
     (From (Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'subtitle'
   function Subtitle_Class_Widget return Widget_Style is
     (From (Subtitle_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'subtitle'::label
   function Subtitle_Class_Label_Widget return Widget_Style is
     (From (Subtitle_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'subtitle'
   function Subtitle_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'deck'
   function Deck_Class_Widget return Widget_Style is
     (From (Deck_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'deck'
   function Deck_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Deck_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grid'
   function Grid_Class_Widget return Widget_Style is
     (From (Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grid'
   function Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'cell'
   function Cell_Class_Widget return Widget_Style is
     (From (Cell_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'cell'
   function Cell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Cell_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'emoji'
   function Emoji_Class_Widget return Widget_Style is
     (From (Emoji_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'emoji'
   function Emoji_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Emoji_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'caption'::label
   function Caption_Class_Label_Widget return Widget_Style is
     (From (Caption_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'caption'
   function Caption_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'transport'
   function Transport_Class_Widget return Widget_Style is
     (From (Transport_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'transport'
   function Transport_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Transport_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'play-button'
   function Play_Button_Class_Widget return Widget_Style is
     (From (Play_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Play_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Play_Button_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'play-button'::label
   function Play_Button_Class_Label_Widget return Widget_Style is
     (From (Play_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'play-button'
   function Play_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Play_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Play_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'pause-button'
   function Pause_Button_Class_Widget return Widget_Style is
     (From (Pause_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Pause_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Pause_Button_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'pause-button'::label
   function Pause_Button_Class_Label_Widget return Widget_Style is
     (From (Pause_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'pause-button'
   function Pause_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Pause_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Pause_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'reset-button'
   function Reset_Button_Class_Widget return Widget_Style is
     (From (Reset_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Reset_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Reset_Button_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'reset-button'::label
   function Reset_Button_Class_Label_Widget return Widget_Style is
     (From (Reset_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'reset-button'
   function Reset_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Reset_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Reset_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'speed-button'
   function Speed_Button_Class_Widget return Widget_Style is
     (From (Speed_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Speed_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Speed_Button_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'speed-button'::label
   function Speed_Button_Class_Label_Widget return Widget_Style is
     (From (Speed_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'speed-button'
   function Speed_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Speed_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Speed_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'status'
   function Status_Class_Widget return Widget_Style is
     (From (Status_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'status'::label
   function Status_Class_Label_Widget return Widget_Style is
     (From (Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'status'
   function Status_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end RLottie_Example_Styles;