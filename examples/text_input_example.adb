pragma Ada_2022;

with Ada.Strings;            use Ada.Strings;
with Ada.Strings.Fixed;      use Ada.Strings.Fixed;
with Adi.App;
with Adi.Window;             use Adi.Window;
with Adi.Widget;             use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;       use Adi.Widget.Label;
with Adi.Widget.Text_Input;  use Adi.Widget.Text_Input;
with Adi.Widget_Styles;      use Adi.Widget_Styles;
with Adi.CSS_Styles;         use Adi.CSS_Styles;

procedure Text_Input_Example is
   A : Adi.App.App;

   function Style return Style_Builder renames Adi.Widget_Styles.Create;
   function Px (V : Float) return Length_Value renames Adi.CSS_Styles.Px;
   function RGB (R, G, B : Natural) return Color_Value renames Adi.CSS_Styles.RGB;
   function Set_Bg (V : Color_Value) return Opt_Bg_Color.Optional
     renames Adi.CSS_Styles.Set_Bg;
   function Radius (All_L : Length_Value) return Border_Radius_Value
     renames Adi.CSS_Styles.Radius;
   function Pad (All_L : Length_Value) return CSS_Box_Value
     renames Adi.CSS_Styles.CSS_Box;
   function Pad (V, H : Length_Value) return CSS_Box_Value
     renames Adi.CSS_Styles.CSS_Box;
   function G (All_L : Length_Value) return Gap_Value
     renames Adi.CSS_Styles.Gap;

   Echo_Label   : Label_Widget_Access;
   Length_Label : Label_Widget_Access;

   procedure On_Input_Changed
     (W    : Text_Input_Widget_Access;
      Text : String)
   is
      pragma Unreferenced (W);
      Len_Text : constant String := Trim (Natural'Image (Text'Length), Ada.Strings.Both);
   begin
      if Echo_Label /= null then
         Set_Text (Echo_Label.all, "You typed: " & Text);
      end if;

      if Length_Label /= null then
         Set_Text (Length_Label.all, "Length: " & Len_Text);
      end if;
   end On_Input_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : Window_Access := Create_Window ("Text Input Example", (760.0, 420.0));

      Root      : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title     : Label_Widget_Access := Adi.Widget.Label.Create ("Text Input Widget Demo");
      Hint      : Label_Widget_Access := Adi.Widget.Label.Create
        ("Click the field below and type. Use arrows/Home/End/Backspace/Delete.");
      Input     : Text_Input_Widget_Access := Adi.Widget.Text_Input.Create ("Hello Adi");
      Input_2   : Text_Input_Widget_Access := Adi.Widget.Text_Input.Create ("Second field");
   begin
      Echo_Label := Adi.Widget.Label.Create ("You typed: Hello Adi");
      Length_Label := Adi.Widget.Label.Create ("Length: 9");

      Set_On_Changed (Input.all, On_Input_Changed'Unrestricted_Access);

      Set_Part_Style (Root.all, Main_Part,
        Style.Base ((
          Display          => Set (Flex),
          Flex_Direction   => Set (Column),
          Align_Items      => Set (Stretch),
          Justify_Content  => Set (Flex_Start),
          Padding          => Set (Pad (Px (24.0))),
          Gap              => Set (G (Px (12.0))),
          Background_Color => Set_Bg (RGB (20, 24, 31)),
          others           => <>)).Build);

      Set_Part_Style (Container.all, Main_Part,
        Style.Base ((
          Display          => Set (Flex),
          Flex_Direction   => Set (Column),
          Align_Items      => Set (Stretch),
          Justify_Content  => Set (Flex_Start),
          Flex_Grow        => Set (1.0),
          Gap              => Set (G (Px (12.0))),
          Padding          => Set (Pad (Px (24.0))),
          Background_Color => Set_Bg (RGB (31, 41, 55)),
          Border_Radius    => Set (Radius (Px (10.0))),
          others           => <>)).Build);

      Set_Part_Style (Title.all, Label_Part,
        Style.Base ((
          Color       => Set (C (White)),
          Font_Size   => Set_Font (Px (22.0)),
          Font_Weight => Set (Weight_Semi_Bold),
          others      => <>)).Build);

      Set_Part_Style (Hint.all, Label_Part,
        Style.Base ((
          Color          => Set (RGB (191, 219, 254)),
          Font_Size      => Set_Font (Px (13.0)),
          Text_Wrap_Mode => Set (TWM_Wrap),
          others         => <>)).Build);

      Set_Part_Style (Echo_Label.all, Label_Part,
        Style.Base ((
          Color     => Set (RGB (165, 243, 252)),
          Font_Size => Set_Font (Px (14.0)),
          others    => <>)).Build);

      Set_Part_Style (Length_Label.all, Label_Part,
        Style.Base ((
          Color     => Set (RGB (147, 197, 253)),
          Font_Size => Set_Font (Px (12.0)),
          others    => <>)).Build);

      Set_Part_Style (Input.all, Main_Part,
        Style.Base ((
          Height           => Set (Size (Px (42.0))),
          Padding          => Set (Pad (Px (10.0), Px (12.0))),
          Cursor           => Set (Cursor_Text),
          Background_Color => Set_Bg (C (White)),
          Border_Width     => Set (Border_Width (Px (1.0))),
          Border_Color     => Set (Border_Color (RGB (191, 219, 254))),
          Border_Style     => Set (Border_Style (Solid)),
          Border_Radius    => Set (Radius (Px (8.0))),
          Box_Shadow       => Set (No_Shadow),
          Transition       => Set ((Duration   => 0.12,
                                    Easing     => Ease_In_Out,
                                    Properties => Props (Prop_Border_Color)
                                       + Props (Prop_Box_Shadow))),
          others           => <>))
          .On_Focus ((
             Border_Color => Set (Border_Color (RGB (59, 130, 246))),
             Box_Shadow   => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0),
                                         RGBA (59, 130, 246, 0.35))),
             others       => <>))
          .Build);

      Set_Part_Style (Input.all, Label_Part,
        Style.Base ((
          Color          => Set (RGB (15, 23, 42)),
          Font_Size      => Set_Font (Px (14.0)),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>)).Build);

      Set_Part_Style (Input.all, Cursor_Part,
        Style.Base ((
          Background_Color => Set_Bg (RGB (37, 99, 235)),
          others           => <>)).Build);

      Set_Part_Style (Input.all, Selected_Part,
        Style.Base ((
          Background_Color => Set_Bg (RGBA (191, 219, 254, 0.85)),
          others           => <>)).Build);

      Set_Part_Style (Input_2.all, Main_Part,
        Style.Base ((
          Height           => Set (Size (Px (42.0))),
          Padding          => Set (Pad (Px (10.0), Px (12.0))),
          Cursor           => Set (Cursor_Text),
          Background_Color => Set_Bg (C (White)),
          Border_Width     => Set (Border_Width (Px (1.0))),
          Border_Color     => Set (Border_Color (RGB (191, 219, 254))),
          Border_Style     => Set (Border_Style (Solid)),
          Border_Radius    => Set (Radius (Px (8.0))),
          Box_Shadow       => Set (No_Shadow),
          Transition       => Set ((Duration   => 0.12,
                                    Easing     => Ease_In_Out,
                                    Properties => Props (Prop_Border_Color)
                                       + Props (Prop_Box_Shadow))),
          others           => <>))
          .On_Focus ((
             Border_Color => Set (Border_Color (RGB (59, 130, 246))),
             Box_Shadow   => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0),
                                         RGBA (59, 130, 246, 0.35))),
             others       => <>))
          .Build);

      Set_Part_Style (Input_2.all, Label_Part,
        Style.Base ((
          Color          => Set (RGB (15, 23, 42)),
          Font_Size      => Set_Font (Px (14.0)),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>)).Build);

      Set_Part_Style (Input_2.all, Cursor_Part,
        Style.Base ((
          Background_Color => Set_Bg (RGB (37, 99, 235)),
          others           => <>)).Build);

      Set_Part_Style (Input_2.all, Selected_Part,
        Style.Base ((
          Background_Color => Set_Bg (RGBA (191, 219, 254, 0.85)),
          others           => <>)).Build);

      Add_Child (Root.all, Widget_Access (Container));
      Add_Child (Container.all, Widget_Access (Title));
      Add_Child (Container.all, Widget_Access (Hint));
      Add_Child (Container.all, Widget_Access (Input));
      Add_Child (Container.all, Widget_Access (Input_2));
      Add_Child (Container.all, Widget_Access (Echo_Label));
      Add_Child (Container.all, Widget_Access (Length_Label));

      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Text_Input_Example;
