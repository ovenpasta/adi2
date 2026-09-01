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

package List_Box_Example_Styles is

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
        .Background (RGB (242, 245, 248))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panels'
   Panels_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (12.0)))
        .Flex_Grow (1.0)
     .Build;

   --  Part styles bundle for class 'panels'
   Panels_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panels_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panels-row'
   Panels_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (12.0)))
        .Flex_Grow (1.0)
        .Flex_Basis (Basis (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'panels-row'
   Panels_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panels_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'controls-row'
   Controls_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Justify_Content (Flex_Start)
        .Align_Items (Center)
        .Gap (Gap (Px (14.0)))
        .Background (RGB (255, 255, 255))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (220, 226, 234)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'controls-row'
   Controls_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Controls_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel'
   Panel_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Flex_Basis (Basis (Px (0.0)))
        .Min_Width (Size (Px (240.0)))
        .Gap (Gap (Px (8.0)))
        .Background (RGB (255, 255, 255))
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (220, 226, 234)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'panel'
   Panel_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel-title'
   Panel_Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'panel-title'::label
   Panel_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (41, 49, 64))
        .Font_Size (Px (18.0))
        .Font_Weight (Weight_Bold)
        .White_Space (WS_Nowrap)
        .Text_Overflow (Overflow_Clip)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'panel-title'
   Panel_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panel_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Panel_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (83, 97, 120))
        .Font_Size (Px (13.0))
        .Text_Overflow (Overflow_Clip)
        .Text_Wrap_Mode (TWM_Wrap)
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'inertia-label'::label
   Inertia_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (41, 49, 64))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Semi_Bold)
        .White_Space (WS_Nowrap)
        .Text_Overflow (Overflow_Clip)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'inertia-label'
   Inertia_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Inertia_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'debug-label'::label
   Debug_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (41, 49, 64))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Semi_Bold)
        .White_Space (WS_Nowrap)
        .Text_Overflow (Overflow_Clip)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'debug-label'
   Debug_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Debug_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'inertia-switch'
   Inertia_Switch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (56.0)))
        .Height (Size (Px (30.0)))
        .Background (RGB (203, 213, 225))
        .Transition ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (148, 163, 184)))
        .Radius (Radius (Px (16.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (191, 201, 216))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (37, 99, 235))
     .Build;

   --  Style for class 'inertia-switch'::knob
   Inertia_Switch_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (24.0)))
        .Height (Size (Px (24.0)))
        .Background (C (White))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (203, 213, 225)))
        .Radius (Radius (Px (13.0)))
     .Build;

   --  Part styles bundle for class 'inertia-switch'
   Inertia_Switch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Inertia_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Inertia_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'debug-switch'
   Debug_Switch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (56.0)))
        .Height (Size (Px (30.0)))
        .Background (RGB (203, 213, 225))
        .Transition ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (148, 163, 184)))
        .Radius (Radius (Px (16.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (191, 201, 216))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (22, 163, 74))
        .Border_Color (Border_Color (RGB (21, 128, 61)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (21, 128, 61))
     .Build;

   --  Style for class 'debug-switch'::knob
   Debug_Switch_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (24.0)))
        .Height (Size (Px (24.0)))
        .Background (C (White))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (203, 213, 225)))
        .Radius (Radius (Px (13.0)))
     .Build;

   --  Part styles bundle for class 'debug-switch'
   Debug_Switch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Debug_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Debug_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'listbox'
   Listbox_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (247, 249, 252))
        .Min_Height (Size (Px (140.0)))
        .Flex_Grow (1.0)
        .Flex_Basis (Basis (Px (0.0)))
        .Gap (Gap (Px (4.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (213, 221, 231)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'listbox'::knob
   Listbox_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Min_Height (Size (Px (24.0)))
        .Background (RGBA (71, 85, 105, 0.78))
        .Transition ((Duration => 0.26, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (6.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (71, 85, 105, 0.94))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (71, 85, 105, 1.0))
     .Build;

   --  Style for class 'listbox'::scroll
   Listbox_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (148, 163, 184, 0.22))
        .Transition ((Duration => 0.26, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0)))
        .Radius (Radius (Px (6.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (148, 163, 184, 0.38))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (148, 163, 184, 0.52))
     .Build;

   --  Part styles bundle for class 'listbox'
   Listbox_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Listbox_Class_Widget, Enabled => True),
      Knob_Part => (Style => Listbox_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Listbox_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'listbox-multi'
   Listbox_Multi_Class_Widget : constant Widget_Style :=
     Style_Of
        .Gap (Gap (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'listbox-multi'
   Listbox_Multi_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Listbox_Multi_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'listbox-grid'
   Listbox_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'listbox-grid'
   Listbox_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Listbox_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'label-row'
   Label_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (255, 255, 255))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Margin (CSS_Box (Px (0.0), Px (10.0), Px (0.0), Px (0.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (220, 228, 236)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (235, 241, 250))
        .Border_Color (Border_Color (RGB (186, 200, 220)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (62, 118, 210))
        .Border_Color (Border_Color (RGB (48, 95, 171)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (52, 104, 192))
        .Border_Color (Border_Color (RGB (40, 82, 152)))
     .Build;

   --  Style for class 'label-row'::label
   Label_Row_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (43, 52, 67))
        .Font_Size (Px (14.0))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (C (White))
     .Build;

   --  Part styles bundle for class 'label-row'
   Label_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label_Row_Class_Widget, Enabled => True),
      Label_Part => (Style => Label_Row_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-row'
   Card_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (63, 115, 176))
        .Height (Size (Px (44.0)))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Margin (CSS_Box (Px (0.0), Px (10.0), Px (0.0), Px (0.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (28, 33, 45)))
        .Radius (Radius (Px (8.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 132, 198))
        .Border_Color (Border_Color (RGB (40, 48, 65)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (244, 166, 77))
        .Border_Color (Border_Color (RGB (190, 120, 35)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (248, 178, 100))
        .Border_Color (Border_Color (RGB (205, 138, 52)))
     .Build;

   --  Part styles bundle for class 'card-row'
   Card_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-row-title'::label
   Card_Row_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (13.0))
     .Build;

   --  Part styles bundle for class 'card-row-title'
   Card_Row_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Card_Row_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grid-cell'
   Grid_Cell_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (255, 255, 255))
        .Height (Size (Px (50.0)))
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color)))
        .Padding (CSS_Box (Px (12.0), Px (6.0), Px (12.0), Px (6.0)))
        .Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (0.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (220, 228, 236)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (235, 241, 250))
        .Border_Color (Border_Color (RGB (186, 200, 220)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (62, 118, 210))
        .Border_Color (Border_Color (RGB (48, 95, 171)))
     --  widget State_Selected, widget State_Hovered
     .On (When_State (State_Selected) and When_State (State_Hovered))
        .Background (RGB (52, 104, 192))
        .Border_Color (Border_Color (RGB (40, 82, 152)))
     .Build;

   --  Style for class 'grid-cell'::label
   Grid_Cell_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (43, 52, 67))
        .Font_Size (Px (13.0))
        .Text_Align (Text_Center)
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (C (White))
     .Build;

   --  Part styles bundle for class 'grid-cell'
   Grid_Cell_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grid_Cell_Class_Widget, Enabled => True),
      Label_Part => (Style => Grid_Cell_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end List_Box_Example_Styles;