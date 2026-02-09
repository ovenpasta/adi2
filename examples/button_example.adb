pragma Ada_2022;
with Ada.Text_IO;       use Ada.Text_IO;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Core;          use Adi.Core;
with Adi.Widget.Part_Styles; use Adi.Widget.Part_Styles;

procedure Button_Example is
   A : Adi.App.App;

   --  Style builder alias
   function Style return Style_Builder renames Adi.Widget_Styles.Create;

   --  CSS helpers
   function Px (V : Float) return Length_Value renames Adi.CSS_Styles.Px;
   function RGB (R, G, B : Natural) return Color_Value renames Adi.CSS_Styles.RGB;
   function RGBA (R, G, B : Natural; Alpha : Float) return Color_Value
     renames Adi.CSS_Styles.RGBA;
   function Set_Bg (V : Color_Value) return Opt_Bg_Color.Optional
     renames Adi.CSS_Styles.Set_Bg;
   function Radius (All_L : Length_Value) return Border_Radius_Value
     renames Adi.CSS_Styles.Radius;
   function Padding_Box (All_L : Length_Value) return CSS_Box_Value
     renames Adi.CSS_Styles.CSS_Box;
   function Padding_Box (V, H : Length_Value) return CSS_Box_Value
     renames Adi.CSS_Styles.CSS_Box;
   function Gap_Value (All_L : Length_Value) return Gap_Value
     renames Adi.CSS_Styles.Gap;

   --  Option group type
   type Align_Option is (Left, Center, Right);
   package Align_Options is new Adi.Widget.Button.Options (Align_Option);

   --  Callbacks
   procedure On_Simple_Click (Btn : Button_Widget_Access) is
   begin
      Put_Line ("Simple button clicked!");
   end On_Simple_Click;

   procedure On_Toggle (Btn : Button_Widget_Access; Active : Boolean) is
   begin
      Put_Line ("Toggle button: " & Active'Image);
   end On_Toggle;

   procedure On_Align_Changed (Value : Align_Option) is
   begin
      Put_Line ("Alignment changed to: " & Value'Image);
   end On_Align_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : Window_Access := Create_Window ("Button Example", (700.0, 500.0));

      --  Root container
      Root : Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      --  Main vertical container
      Container : Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      --  Section 1: Simple click buttons
      Section1 : Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Btn_Primary : Button_Widget_Access := Create ("Primary");
      Btn_Danger  : Button_Widget_Access := Create ("Delete");
      Btn_Outline : Button_Widget_Access := Create ("Cancel");

      --  Section 2: Toggle button
      Section2 : Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Btn_Toggle : Button_Widget_Access := Create ("Bold");

      --  Section 3: Option group
      Section3 : Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Btn_Left   : Button_Widget_Access := Create ("Left");
      Btn_Center : Button_Widget_Access := Create ("Center");
      Btn_Right  : Button_Widget_Access := Create ("Right");
      Align_Group : aliased Align_Options.Option_Group;

   begin
      --  === Configure callbacks ===

      --  Simple click buttons
      Btn_Primary.Set_On_Clicked (On_Simple_Click'Unrestricted_Access);
      Btn_Danger.Set_On_Clicked (On_Simple_Click'Unrestricted_Access);
      Btn_Outline.Set_On_Clicked (On_Simple_Click'Unrestricted_Access);

      --  Toggle button
      Btn_Toggle.Set_Toggleable;
      Btn_Toggle.Set_On_Toggled (On_Toggle'Unrestricted_Access);

      --  Option group
      Align_Group.Set_Button (Left, Btn_Left);
      Align_Group.Set_Button (Center, Btn_Center);
      Align_Group.Set_Button (Right, Btn_Right);
      Align_Group.Set_On_Changed (On_Align_Changed'Unrestricted_Access);

      --  === Styles ===

      --  Root: flex column, dark background, fills window
      Set_Part_Style (Root.all, Main_Part,
        Style.Base ((
          Display          => Set (Flex),
          Flex_Direction   => Set (Column),
          Background_Color => Set_Bg (RGB (30, 30, 36)),
          others           => <>)).Build);

      --  Main container: vertical flex, grows to fill root
      Set_Part_Style (Container.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Column),
          Flex_Grow      => Set (1.0),
          Gap            => Set (Gap_Value (Px (24.0))),
          Padding        => Set (Padding_Box (Px (30.0))),
          others         => <>)).Build);

      --  Section 1: horizontal row of buttons
      Set_Part_Style (Section1.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Row),
          Gap            => Set (Gap_Value (Px (12.0))),
          Align_Items    => Set (Adi.CSS_Styles.Center),
          others         => <>)).Build);

      --  Section 2: row
      Set_Part_Style (Section2.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Row),
          Gap            => Set (Gap_Value (Px (12.0))),
          Align_Items    => Set (Adi.CSS_Styles.Center),
          others         => <>)).Build);

      --  Section 3: row for option group
      Set_Part_Style (Section3.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Row),
          Gap            => Set (Gap_Value (Px (0.0))),
          Align_Items    => Set (Adi.CSS_Styles.Center),
          others         => <>)).Build);

      --  Primary button style (with smooth transition on hover)
      Set_Part_Style (Btn_Primary.all, Main_Part,
        Style.Base ((
          Display          => Set (Inline_Flex),
          Justify_Content  => Set (Adi.CSS_Styles.Center),
          Align_Items      => Set (Adi.CSS_Styles.Center),
          Background_Color => Set_Bg (RGB (59, 130, 246)),
          Border_Width     => Set (Border_Width (Px (0.0))),
          Border_Radius    => Set (Radius (Px (6.0))),
          Padding          => Set (Padding_Box (Px (12.0), Px (24.0))),
          Cursor           => Set (Cursor_Pointer),
          Transition       => Set ((Duration   => 0.15,
                                     Easing     => Ease_In_Out,
                                     Properties => Props (Prop_Background_Color))),
          others           => <>))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (37, 99, 235)),
          others           => <>))
        .On_Press ((
          Background_Color => Set_Bg (RGB (29, 58, 145)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_Primary.all, Label_Part,
        Style.Base ((
          Color          => Set (C (White)),
          Font_Size      => Set_Font (Px (14.0)),
          Font_Weight    => Set (Weight_Medium),
          Text_Align     => Set (Text_Center),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>)).Build);

      --  Danger button style
      Set_Part_Styles (Btn_Danger.all, Danger_Button_Style);

      --  Outline button style
      Set_Part_Styles (Btn_Outline.all, Secondary_Button_Style);

      --  Toggle button style (green when toggled/selected)
      Set_Part_Style (Btn_Toggle.all, Main_Part,
        Style.Base ((
          Display          => Set (Inline_Flex),
          Justify_Content  => Set (Adi.CSS_Styles.Center),
          Align_Items      => Set (Adi.CSS_Styles.Center),
          Background_Color => Set_Bg (RGB (75, 85, 99)),
          Border_Width     => Set (Border_Width (Px (2.0))),
          Border_Color     => Set (Border_Color (RGB (107, 114, 128))),
          Border_Style     => Set (Border_Style (Solid)),
          Border_Radius    => Set (Radius (Px (6.0))),
          Padding          => Set (Padding_Box (Px (10.0), Px (20.0))),
          Cursor           => Set (Cursor_Pointer),
          others           => <>))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (90, 100, 114)),
          others           => <>))
        .On_Press ((
          Background_Color => Set_Bg (RGB (55, 65, 81)),
          others           => <>))
        .On_Selected ((
          Background_Color => Set_Bg (RGB (22, 163, 74)),
          Border_Color     => Set (Border_Color (RGB (21, 128, 61))),
          others           => <>))
        .Build);

      Set_Part_Style (Btn_Toggle.all, Label_Part,
        Style.Base ((
          Color          => Set (C (White)),
          Font_Size      => Set_Font (Px (14.0)),
          Font_Weight    => Set (Weight_Medium),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>)).Build);

      --  Option group button styles (segmented control look)
      declare
         Option_Base : constant Style_Rules := (
           Display          => Set (Inline_Flex),
           Justify_Content  => Set (Adi.CSS_Styles.Center),
           Align_Items      => Set (Adi.CSS_Styles.Center),
           Background_Color => Set_Bg (RGB (55, 65, 81)),
           Border_Width     => Set (Border_Width (Px (1.0))),
           Border_Color     => Set (Border_Color (RGB (75, 85, 99))),
           Border_Style     => Set (Border_Style (Solid)),
           Padding          => Set (Padding_Box (Px (8.0), Px (16.0))),
           Cursor           => Set (Cursor_Pointer),
           others           => <>);

         Option_Hover : constant Style_Rules := (
           Background_Color => Set_Bg (RGB (75, 85, 99)),
           others           => <>);

         Option_Selected : constant Style_Rules := (
           Background_Color => Set_Bg (RGB (59, 130, 246)),
           Border_Color     => Set (Border_Color (RGB (37, 99, 235))),
           others           => <>);

         Label_Base : constant Style_Rules := (
           Color          => Set (C (White)),
           Font_Size      => Set_Font (Px (13.0)),
           Font_Weight    => Set (Weight_Medium),
           Text_Wrap_Mode => Set (TWM_Nowrap),
           others         => <>);

         --  Left button: rounded left corners only
         Left_Main : constant Widget_Style := Style
           .Base ((Option_Base with delta
             Border_Radius => Set (Radius (Px (6.0), Px (0.0), Px (0.0), Px (6.0)))))
           .On_Hover (Option_Hover)
           .On_Selected (Option_Selected)
           .Build;

         --  Center button: no rounding
         Center_Main : constant Widget_Style := Style
           .Base (Option_Base)
           .On_Hover (Option_Hover)
           .On_Selected (Option_Selected)
           .Build;

         --  Right button: rounded right corners only
         Right_Main : constant Widget_Style := Style
           .Base ((Option_Base with delta
             Border_Radius => Set (Radius (Px (0.0), Px (6.0), Px (6.0), Px (0.0)))))
           .On_Hover (Option_Hover)
           .On_Selected (Option_Selected)
           .Build;

         Opt_Label_Style : constant Widget_Style := Style
           .Base (Label_Base)
           .Build;
      begin
         Set_Part_Style (Btn_Left.all, Main_Part, Left_Main);
         Set_Part_Style (Btn_Left.all, Label_Part, Opt_Label_Style);

         Set_Part_Style (Btn_Center.all, Main_Part, Center_Main);
         Set_Part_Style (Btn_Center.all, Label_Part, Opt_Label_Style);

         Set_Part_Style (Btn_Right.all, Main_Part, Right_Main);
         Set_Part_Style (Btn_Right.all, Label_Part, Opt_Label_Style);
      end;

      --  === Build hierarchy ===
      Add_Child (Root.all, Widget_Access (Container));

      Add_Child (Container.all, Widget_Access (Section1));
      Add_Child (Section1.all, Widget_Access (Btn_Primary));
      Add_Child (Section1.all, Widget_Access (Btn_Danger));
      Add_Child (Section1.all, Widget_Access (Btn_Outline));

      Add_Child (Container.all, Widget_Access (Section2));
      Add_Child (Section2.all, Widget_Access (Btn_Toggle));

      Add_Child (Container.all, Widget_Access (Section3));
      Add_Child (Section3.all, Widget_Access (Btn_Left));
      Add_Child (Section3.all, Widget_Access (Btn_Center));
      Add_Child (Section3.all, Widget_Access (Btn_Right));

      --  Set root and run
      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Button_Example;
