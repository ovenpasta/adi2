--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Runtime_Css_Properties;

--  The constants below intern as this package elaborates, so the
--  stores behind Intern_Rules and Build are wanted first.
pragma Elaborate_All (Adi.Widget_Styles);

package Runtime_Css_Example_Styles is

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
        .Gap (Gap (Px (12.0)))
        .Background (RGB (8, 12, 24))
        .Padding (CSS_Box (Px (15.0), Px (15.0), Px (15.0), Px (15.0)))
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
        .Gap (Gap (Px (18.0)))
        .Background (RGBA (30, 41, 59, 0.55))
        .Box_Shadow (Shadow (Px (0.0), Px (10.0), Px (30.0), Px (0.0), RGBA (15, 23, 42, 0.45)))
        .Padding (CSS_Box (Px (18.0), Px (20.0), Px (18.0), Px (20.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (148, 163, 184, 0.35)))
        .Radius (Radius (Px (18.0)))
     .Build;

   --  Part styles bundle for class 'header'
   Header_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'content'
   Content_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (40.0)))
     .Build;

   --  Part styles bundle for class 'content'
   Content_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Content_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-left'
   Card_Left_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Gap (Gap (Px (10.0)))
        .Background (RGBA (15, 23, 42, 0.9))
        .Box_Shadow (Shadow (Px (0.0), Px (12.0), Px (28.0), Px (0.0), RGBA (2, 6, 23, 0.5)))
        .Transition ((Duration => 0.5, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (59, 130, 246, 0.35)))
        .Radius (Radius (Px (16.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (30, 58, 110, 0.92))
        .Box_Shadow (Shadow (Px (0.0), Px (16.0), Px (36.0), Px (0.0), RGBA (15, 23, 42, 0.75)))
        .Border_Color (Border_Color (RGBA (96, 165, 250, 0.9)))
     --  [severity="ok"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Ok)))
        .Background (RGBA (6, 78, 59, 0.92))
        .Border_Color (Border_Color (RGBA (34, 197, 94, 0.9)))
     --  [severity="warning"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Warning)))
        .Background (RGBA (87, 66, 6, 0.92))
        .Border_Color (Border_Color (RGBA (234, 179, 8, 0.9)))
     --  [severity="critical"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Critical)))
        .Background (RGBA (94, 12, 12, 0.92))
        .Border_Color (Border_Color (RGBA (239, 68, 68, 0.9)))
     --  :not([severity])
     .On (When_Not_Property_Set (Runtime_Css_Properties.Severity.Id))
        .Border_Style (Border_Style (Dashed))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Part styles bundle for class 'card-left'
   Card_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Left_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-right'
   Card_Right_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Gap (Gap (Px (10.0)))
        .Background (RGBA (30, 41, 59, 0.9))
        .Box_Shadow (Shadow (Px (0.0), Px (12.0), Px (28.0), Px (0.0), RGBA (2, 6, 23, 0.5)))
        .Transition ((Duration => 0.5, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (45, 212, 191, 0.35)))
        .Radius (Radius (Px (16.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (22, 78, 99, 0.92))
        .Box_Shadow (Shadow (Px (0.0), Px (16.0), Px (36.0), Px (0.0), RGBA (15, 23, 42, 0.75)))
        .Border_Color (Border_Color (RGBA (45, 212, 191, 0.9)))
     --  [severity="ok"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Ok)))
        .Background (RGBA (6, 78, 59, 0.92))
        .Border_Color (Border_Color (RGBA (34, 197, 94, 0.9)))
     --  [severity="warning"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Warning)))
        .Background (RGBA (87, 66, 6, 0.92))
        .Border_Color (Border_Color (RGBA (234, 179, 8, 0.9)))
     --  [severity="critical"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Critical)))
        .Background (RGBA (94, 12, 12, 0.92))
        .Border_Color (Border_Color (RGBA (239, 68, 68, 0.9)))
     --  :not([severity])
     .On (When_Not_Property_Set (Runtime_Css_Properties.Severity.Id))
        .Border_Style (Border_Style (Dashed))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Part styles bundle for class 'card-right'
   Card_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Right_Class_Widget, Enabled => True),
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
        .Font_Size (Px (34.0))
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
        .Font_Size (Px (16.0))
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'badge'
   Badge_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Align_Items (Center)
        .Justify_Content (Center)
        .Width (Size (Px (84.0)))
        .Background (RGBA (34, 197, 94, 0.18))
        .Padding (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0)))
        .Margin (CSS_Box (Px (8.0), Px (0.0), Px (0.0), Px (0.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (74, 222, 128, 0.6)))
        .Radius (Radius (Px (999.0)))
     .Build;

   --  Style for class 'badge'::label
   Badge_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (134, 239, 172))
        .Font_Size (Px (12.0))
        .Font_Weight (Weight_Bold)
        .Text_Align (Text_Center)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'badge'
   Badge_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Badge_Class_Widget, Enabled => True),
      Label_Part => (Style => Badge_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'mode-button'
   Mode_Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Align_Items (Center)
        .Justify_Content (Center)
        .Width (Size (Px (220.0)))
        .Background (RGBA (30, 64, 175, 0.35))
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (28.0)))
        .Margin (CSS_Box (Px (20.0), Px (0.0), Px (0.0), Px (0.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (96, 165, 250, 0.7)))
        .Radius (Radius (Px (10.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (30, 64, 175, 0.55))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGBA (30, 64, 175, 0.7))
     .Build;

   --  Style for class 'mode-button'::label
   Mode_Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (219, 234, 254))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'mode-button'
   Mode_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Mode_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Mode_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for tag 'button'
   Button_Tag_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.22, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
     .Build;

   --  Part styles bundle for tag 'button'
   Button_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Button_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Style for id 'mode-switch'
   Mode_Switch_Id_Widget : constant Widget_Style :=
     Style_Of
        .Border_Color (Border_Color (RGBA (147, 197, 253, 0.95)))
     .Build;

   --  Part styles bundle for id 'mode-switch'
   Mode_Switch_Id_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Mode_Switch_Id_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-title'
   Card_Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'card-title'::label
   Card_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (226, 232, 240))
        .Font_Size (Px (22.0))
        .Font_Weight (Weight_Bold)
     --  [severity="critical"]
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Critical)))
        .Text_Color (RGB (254, 202, 202))
     .Build;

   --  Part styles bundle for class 'card-title'
   Card_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-body'::label
   Card_Body_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
        .Font_Size (Px (10.0))
        .Line_Height (Line_Height (1.4))
     .Build;

   --  Part styles bundle for class 'card-body'
   Card_Body_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Card_Body_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (15, 23, 42, 0.75))
        .Padding (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (28.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (71, 85, 105, 0.8)))
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

end Runtime_Css_Example_Styles;