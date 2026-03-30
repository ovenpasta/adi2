--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
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
      Root_Styles => Root_Part_Styles,
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

   --  Base style for class 'viewer-shell'
   function Viewer_Shell_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (330.0))),
      Background_Color => Set_Bg (RGB (20, 24, 36)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (102, 111, 144))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'viewer'
   function Viewer_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Grow => Set (1.0),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Min_Height => Set (Size (Px (280.0))),
      Background_Color => Set_Bg (RGB (8, 10, 18)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (72, 82, 112))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'viewer'::icon
   function Viewer_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      Object_Position => Set (Object_Position (Pos_Center, Pos_Center)),
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
      Width => Set (Size (Px (128.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
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

   --  Base style for class 'stop-button'
   function Stop_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (128.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Background_Color => Set_Bg (RGB (201, 102, 92)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (255, 189, 177))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'stop-button' when widget State_Hovered
   function Stop_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (216, 116, 106)),
      others => <>);

   --  Style for class 'stop-button' when widget State_Pressed
   function Stop_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (184, 88, 78)),
      others => <>);

   --  Base style for class 'stop-button'::label
   function Stop_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 250, 255)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'rew-button'
   function Rew_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (128.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Background_Color => Set_Bg (RGB (106, 134, 199)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (180, 203, 255))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'rew-button' when widget State_Hovered
   function Rew_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (122, 150, 215)),
      others => <>);

   --  Style for class 'rew-button' when widget State_Pressed
   function Rew_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (91, 118, 179)),
      others => <>);

   --  Base style for class 'rew-button'::label
   function Rew_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 250, 255)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'loop-button'
   function Loop_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (128.0))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.12, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Background_Color => Set_Bg (RGB (130, 108, 194)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (210, 189, 255))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'loop-button' when widget State_Hovered
   function Loop_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (148, 126, 212)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Pressed
   function Loop_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (113, 92, 176)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Selected
   function Loop_Button_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (90, 177, 122)),
      Border_Color => Set (Border_Color (RGB (176, 245, 202))),
      others => <>);

   --  Style for class 'loop-button' when widget State_Selected, widget State_Hovered
   function Loop_Button_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (104, 191, 136)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Selected, widget State_Pressed
   function Loop_Button_Class_Widget_Selected_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (76, 160, 108)),
      others => <>);

   --  Base style for class 'loop-button'::label
   function Loop_Button_Class_Label_Base_Style return Style_Rules is
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

   --  Complete widget style for class 'viewer-shell'
   function Viewer_Shell_Class_Widget return Widget_Style is
     (From (Viewer_Shell_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'viewer-shell'
   function Viewer_Shell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Viewer_Shell_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'viewer'
   function Viewer_Class_Widget return Widget_Style is
     (From (Viewer_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'viewer'::icon
   function Viewer_Class_Icon_Widget return Widget_Style is
     (From (Viewer_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'viewer'
   function Viewer_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Viewer_Class_Widget, Enabled => True),
      Icon_Part => (Style => Viewer_Class_Icon_Widget, Enabled => True),
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

   --  Complete widget style for class 'stop-button'
   function Stop_Button_Class_Widget return Widget_Style is
     (From (Stop_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Stop_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Stop_Button_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'stop-button'::label
   function Stop_Button_Class_Label_Widget return Widget_Style is
     (From (Stop_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'stop-button'
   function Stop_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Stop_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Stop_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'rew-button'
   function Rew_Button_Class_Widget return Widget_Style is
     (From (Rew_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Rew_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Rew_Button_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'rew-button'::label
   function Rew_Button_Class_Label_Widget return Widget_Style is
     (From (Rew_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'rew-button'
   function Rew_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Rew_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Rew_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'loop-button'
   function Loop_Button_Class_Widget return Widget_Style is
     (From (Loop_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Loop_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Loop_Button_Class_Widget_Pressed_Style)
     .On (When_State (State_Selected), Loop_Button_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Loop_Button_Class_Widget_Selected_Widget_Hovered_Style)
     .On (When_State (State_Selected) and When_State (State_Pressed), Loop_Button_Class_Widget_Selected_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'loop-button'::label
   function Loop_Button_Class_Label_Widget return Widget_Style is
     (From (Loop_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'loop-button'
   function Loop_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Loop_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Loop_Button_Class_Label_Widget, Enabled => True),
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

end RLottie_Example_Styles;