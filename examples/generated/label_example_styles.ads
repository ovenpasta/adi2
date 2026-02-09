--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Label_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (40, 44, 52)),
      others => <>
   );

   --  Base style for container
   Container_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (20.0))),
      Padding => Set (CSS_Box (Px (20.0))),
      Background_Color => Set_Bg (RGB (60, 63, 70)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for label1
   Label1_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (10.0))),
      Background_Color => Set_Bg (RGB (97, 175, 239)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>
   );

   --  Base style for label1::label
   Label1_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (18.0)),
      others => <>
   );

   --  Base style for label2
   Label2_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Padding => Set (CSS_Box (Px (10.0))),
      Background_Color => Set_Bg (RGB (152, 195, 121)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>
   );

   --  Base style for label2::icon
   Label2_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (32.0))),
      Height => Set (Size (Px (32.0))),
      others => <>
   );

   --  Base style for label3
   Label3_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (10.0))),
      Background_Color => Set_Bg (RGB (198, 120, 221)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>
   );

   --  Base style for label3::icon
   Label3_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      others => <>
   );

   --  Base style for label3::label
   Label3_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (16.0)),
      others => <>
   );

   --  Base style for label4
   Label4_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (15.0))),
      Background_Color => Set_Bg (RGB (229, 192, 123)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>
   );

   --  Base style for label4::icon
   Label4_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (48.0))),
      Height => Set (Size (Px (48.0))),
      others => <>
   );

   --  Base style for label4::label
   Label4_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (40, 44, 52)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Complete widget style for root
   Root_Widget : constant Widget_Style :=
     From (Root_Base_Style)
     .Build;

   --  Part styles bundle for root
   Root_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Widget, Enabled => True),
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

   --  Complete widget style for label1
   Label1_Widget : constant Widget_Style :=
     From (Label1_Base_Style)
     .Build;

   --  Complete widget style for label1::label
   Label1_Label_Widget : constant Widget_Style :=
     From (Label1_Label_Base_Style)
     .Build;

   --  Part styles bundle for label1
   Label1_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label1_Widget, Enabled => True),
      Label_Part => (Style => Label1_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for label2
   Label2_Widget : constant Widget_Style :=
     From (Label2_Base_Style)
     .Build;

   --  Complete widget style for label2::icon
   Label2_Icon_Widget : constant Widget_Style :=
     From (Label2_Icon_Base_Style)
     .Build;

   --  Part styles bundle for label2
   Label2_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label2_Widget, Enabled => True),
      Icon_Part => (Style => Label2_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for label3
   Label3_Widget : constant Widget_Style :=
     From (Label3_Base_Style)
     .Build;

   --  Complete widget style for label3::icon
   Label3_Icon_Widget : constant Widget_Style :=
     From (Label3_Icon_Base_Style)
     .Build;

   --  Complete widget style for label3::label
   Label3_Label_Widget : constant Widget_Style :=
     From (Label3_Label_Base_Style)
     .Build;

   --  Part styles bundle for label3
   Label3_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label3_Widget, Enabled => True),
      Icon_Part => (Style => Label3_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label3_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for label4
   Label4_Widget : constant Widget_Style :=
     From (Label4_Base_Style)
     .Build;

   --  Complete widget style for label4::icon
   Label4_Icon_Widget : constant Widget_Style :=
     From (Label4_Icon_Base_Style)
     .Build;

   --  Complete widget style for label4::label
   Label4_Label_Widget : constant Widget_Style :=
     From (Label4_Label_Base_Style)
     .Build;

   --  Part styles bundle for label4
   Label4_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label4_Widget, Enabled => True),
      Icon_Part => (Style => Label4_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label4_Label_Widget, Enabled => True),
      others => <>
   ];

end Label_Example_Styles;