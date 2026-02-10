--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Label_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (40, 44, 52)),
      others => <>
   );

   --  Base style for class 'container'
   Container_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (20.0))),
      Background_Color => Set_Bg (RGB (60, 63, 70)),
      Border_Radius => Set (Radius (Px (8.0))),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      others => <>
   );

   --  Base style for class 'label1'
   Label1_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (97, 175, 239)),
      Border_Radius => Set (Radius (Px (4.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      others => <>
   );

   --  Base style for class 'label1'::label
   Label1_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (18.0)),
      others => <>
   );

   --  Base style for class 'label2'
   Label2_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Background_Color => Set_Bg (RGB (152, 195, 121)),
      Border_Radius => Set (Radius (Px (4.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      others => <>
   );

   --  Base style for class 'label2'::icon
   Label2_Class_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (32.0))),
      Height => Set (Size (Px (32.0))),
      others => <>
   );

   --  Base style for class 'label3'
   Label3_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (198, 120, 221)),
      Border_Radius => Set (Radius (Px (4.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      others => <>
   );

   --  Base style for class 'label3'::icon
   Label3_Class_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      others => <>
   );

   --  Base style for class 'label3'::label
   Label3_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (16.0)),
      others => <>
   );

   --  Base style for class 'label4'
   Label4_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (229, 192, 123)),
      Border_Radius => Set (Radius (Px (4.0))),
      Padding => Set (CSS_Box (Px (15.0), Px (15.0), Px (15.0), Px (15.0))),
      others => <>
   );

   --  Base style for class 'label4'::icon
   Label4_Class_Icon_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (48.0))),
      Height => Set (Size (Px (48.0))),
      others => <>
   );

   --  Base style for class 'label4'::label
   Label4_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (40, 44, 52)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     From (Container_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'label1'
   Label1_Class_Widget : constant Widget_Style :=
     From (Label1_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'label1'::label
   Label1_Class_Label_Widget : constant Widget_Style :=
     From (Label1_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'label1'
   Label1_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label1_Class_Widget, Enabled => True),
      Label_Part => (Style => Label1_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'label2'
   Label2_Class_Widget : constant Widget_Style :=
     From (Label2_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'label2'::icon
   Label2_Class_Icon_Widget : constant Widget_Style :=
     From (Label2_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'label2'
   Label2_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label2_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label2_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'label3'
   Label3_Class_Widget : constant Widget_Style :=
     From (Label3_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'label3'::icon
   Label3_Class_Icon_Widget : constant Widget_Style :=
     From (Label3_Class_Icon_Base_Style)
     .Build;

   --  Complete widget style for class 'label3'::label
   Label3_Class_Label_Widget : constant Widget_Style :=
     From (Label3_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'label3'
   Label3_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label3_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label3_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label3_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'label4'
   Label4_Class_Widget : constant Widget_Style :=
     From (Label4_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'label4'::icon
   Label4_Class_Icon_Widget : constant Widget_Style :=
     From (Label4_Class_Icon_Base_Style)
     .Build;

   --  Complete widget style for class 'label4'::label
   Label4_Class_Label_Widget : constant Widget_Style :=
     From (Label4_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'label4'
   Label4_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label4_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label4_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label4_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Label_Example_Styles;