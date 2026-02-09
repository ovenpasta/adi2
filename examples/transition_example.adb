pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;  use Adi.Widget.Label;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Core;          use Adi.Core;

--  Demonstrates the different transition capabilities:
--    1. Background color transitions with each easing curve
--    2. Border properties (color, width, radius)
--    3. Box shadow transition
--    4. Opacity fade
--    5. Multiple targeted properties
--    6. All-properties transition

procedure Transition_Example is
   A : Adi.App.App;

   function Style return Style_Builder renames Adi.Widget_Styles.Create;
   function Px (V : Float) return Length_Value renames Adi.CSS_Styles.Px;
   function RGB (R, G, B : Natural) return Color_Value renames Adi.CSS_Styles.RGB;
   function RGBA (R, G, B : Natural; Alpha : Float) return Color_Value
     renames Adi.CSS_Styles.RGBA;
   function Set_Bg (V : Color_Value) return Opt_Bg_Color.Optional
     renames Adi.CSS_Styles.Set_Bg;
   function Radius (All_L : Length_Value) return Border_Radius_Value
     renames Adi.CSS_Styles.Radius;
   function Radius (TL, TR, BR, BL : Length_Value) return Border_Radius_Value
     renames Adi.CSS_Styles.Radius;
   function Pad (All_L : Length_Value) return CSS_Box_Value
     renames Adi.CSS_Styles.CSS_Box;
   function Pad (V, H : Length_Value) return CSS_Box_Value
     renames Adi.CSS_Styles.CSS_Box;
   function G (All_L : Length_Value) return Gap_Value
     renames Adi.CSS_Styles.Gap;

   --  Shared label style
   White_Label : constant Widget_Style := Style.Base ((
      Color          => Set (C (White)),
      Font_Size      => Set_Font (Px (13.0)),
      Font_Weight    => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others         => <>)).Build;

   Dark_Label : constant Widget_Style := Style.Base ((
      Color          => Set (RGB (200, 200, 210)),
      Font_Size      => Set_Font (Px (11.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others         => <>)).Build;

   --  Helper: section title label
   function Make_Title (Text : String) return Label_Widget_Access is
      L : constant Label_Widget_Access := Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Style (L.all, Main_Part, Style.Base ((
         Padding => Set (Pad (Px (0.0), Px (4.0))),
         others  => <>)).Build);
      Set_Part_Style (L.all, Label_Part, Style.Base ((
         Color       => Set (RGB (160, 170, 190)),
         Font_Size   => Set_Font (Px (12.0)),
         Font_Weight => Set (Weight_Semi_Bold),
         Text_Wrap_Mode => Set (TWM_Nowrap),
         others      => <>)).Build);
      return L;
   end Make_Title;

   --  Helper: description label under a button
   function Make_Desc (Text : String) return Label_Widget_Access is
      L : constant Label_Widget_Access := Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Style (L.all, Main_Part, Style.Base ((
         Padding => Set (Pad (Px (2.0), Px (4.0))),
         others  => <>)).Build);
      Set_Part_Style (L.all, Label_Part, Style.Base ((
         Color       => Set (RGB (120, 130, 150)),
         Font_Size   => Set_Font (Px (10.0)),
         Text_Wrap_Mode => Set (TWM_Nowrap),
         others      => <>)).Build);
      return L;
   end Make_Desc;

   --  Common base style for demo buttons
   Demo_Base : constant Style_Rules := (
      Display          => Set (Inline_Flex),
      Justify_Content  => Set (Adi.CSS_Styles.Center),
      Align_Items      => Set (Adi.CSS_Styles.Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width     => Set (Border_Width (Px (2.0))),
      Border_Color     => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style     => Set (Border_Style (Solid)),
      Border_Radius    => Set (Radius (Px (6.0))),
      Padding          => Set (Pad (Px (10.0), Px (20.0))),
      Cursor           => Set (Cursor_Pointer),
      others           => <>);

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : Window_Access := Create_Window ("Transition Examples", (900.0, 700.0));

      --  Root container
      Root : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Scrollable content area
      Content : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      -----------------------------------------------------------------------
      --  Section 1: Easing Curves (all transition background-color)
      -----------------------------------------------------------------------
      Sec1      : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Sec1_Row  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  One button per easing
      Btn_Linear   : Button_Widget_Access := Create ("Linear");
      Btn_EaseIn   : Button_Widget_Access := Create ("Ease In");
      Btn_EaseOut  : Button_Widget_Access := Create ("Ease Out");
      Btn_EaseIO   : Button_Widget_Access := Create ("Ease In Out");

      --  Description boxes
      Col_Linear  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_EaseIn  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_EaseOut : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_EaseIO  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      -----------------------------------------------------------------------
      --  Section 2: Individual Properties
      -----------------------------------------------------------------------
      Sec2      : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Sec2_Row  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Btn_BgColor   : Button_Widget_Access := Create ("Background");
      Btn_Border    : Button_Widget_Access := Create ("Border Color");
      Btn_Radius    : Button_Widget_Access := Create ("Radius");
      Btn_Shadow    : Button_Widget_Access := Create ("Shadow");
      Btn_Opacity   : Button_Widget_Access := Create ("Opacity");

      Col_BgColor  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Border   : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Radius   : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Shadow   : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Opacity  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      -----------------------------------------------------------------------
      --  Section 3: Combined Properties + Duration
      -----------------------------------------------------------------------
      Sec3      : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Sec3_Row  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Btn_Multi    : Button_Widget_Access := Create ("Multi-Property");
      Btn_All      : Button_Widget_Access := Create ("All Properties");
      Btn_Fast     : Button_Widget_Access := Create ("Fast (50ms)");
      Btn_Slow     : Button_Widget_Access := Create ("Slow (800ms)");

      Col_Multi : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_All   : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Fast  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Slow  : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Column flex style for button+desc groupings
      Col_Style : constant Widget_Style := Style.Base ((
         Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Align_Items    => Set (Adi.CSS_Styles.Center),
         others         => <>)).Build;

   begin
      --  === Root ===
      Set_Part_Style (Root.all, Main_Part,
        Style.Base ((
          Display          => Set (Flex),
          Flex_Direction   => Set (Column),
          Background_Color => Set_Bg (RGB (24, 24, 30)),
          others           => <>)).Build);

      --  === Content ===
      Set_Part_Style (Content.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Column),
          Flex_Grow      => Set (1.0),
          Gap            => Set (G (Px (28.0))),
          Padding        => Set (Pad (Px (28.0), Px (32.0))),
          others         => <>)).Build);

      --  =====================================================================
      --  Section 1: Easing Curves
      --  =====================================================================

      --  Section container
      Set_Part_Style (Sec1.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Column),
          Gap            => Set (G (Px (10.0))),
          others         => <>)).Build);

      --  Row of buttons
      Set_Part_Style (Sec1_Row.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Row),
          Gap            => Set (G (Px (16.0))),
          Align_Items    => Set (Flex_Start),
          others         => <>)).Build);

      --  Column containers for button+desc
      Set_Part_Style (Col_Linear.all, Main_Part, Col_Style);
      Set_Part_Style (Col_EaseIn.all, Main_Part, Col_Style);
      Set_Part_Style (Col_EaseOut.all, Main_Part, Col_Style);
      Set_Part_Style (Col_EaseIO.all, Main_Part, Col_Style);

      --  Linear: constant speed, no acceleration
      Set_Part_Style (Btn_Linear.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.3,
                              Easing     => Linear,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (59, 130, 246)),
          others           => <>))
        .On_Press ((
          Background_Color => Set_Bg (RGB (37, 99, 235)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_Linear.all, Label_Part, White_Label);

      --  Ease In: slow start, fast end
      Set_Part_Style (Btn_EaseIn.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.3,
                              Easing     => Ease_In,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (168, 85, 247)),
          others           => <>))
        .On_Press ((
          Background_Color => Set_Bg (RGB (126, 34, 206)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_EaseIn.all, Label_Part, White_Label);

      --  Ease Out: fast start, slow end
      Set_Part_Style (Btn_EaseOut.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.3,
                              Easing     => Ease_Out,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (34, 197, 94)),
          others           => <>))
        .On_Press ((
          Background_Color => Set_Bg (RGB (22, 163, 74)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_EaseOut.all, Label_Part, White_Label);

      --  Ease In Out: slow start & end, fast middle
      Set_Part_Style (Btn_EaseIO.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.3,
                              Easing     => Ease_In_Out,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (245, 158, 11)),
          others           => <>))
        .On_Press ((
          Background_Color => Set_Bg (RGB (217, 119, 6)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_EaseIO.all, Label_Part, White_Label);

      --  =====================================================================
      --  Section 2: Individual Properties
      --  =====================================================================

      Set_Part_Style (Sec2.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Column),
          Gap            => Set (G (Px (10.0))),
          others         => <>)).Build);

      Set_Part_Style (Sec2_Row.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Row),
          Gap            => Set (G (Px (16.0))),
          Align_Items    => Set (Flex_Start),
          others         => <>)).Build);

      Set_Part_Style (Col_BgColor.all, Main_Part, Col_Style);
      Set_Part_Style (Col_Border.all, Main_Part, Col_Style);
      Set_Part_Style (Col_Radius.all, Main_Part, Col_Style);
      Set_Part_Style (Col_Shadow.all, Main_Part, Col_Style);
      Set_Part_Style (Col_Opacity.all, Main_Part, Col_Style);

      --  Background color only
      Set_Part_Style (Btn_BgColor.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.25,
                              Easing     => Ease_In_Out,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (59, 130, 246)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_BgColor.all, Label_Part, White_Label);

      --  Border color only
      Set_Part_Style (Btn_Border.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Border_Width => Set (Border_Width (Px (2.0))),
          Border_Color => Set (Border_Color (RGB (75, 85, 99))),
          Transition   => Set ((Duration   => 0.3,
                                Easing     => Ease_In_Out,
                                Properties => Props (Prop_Border_Color)))))
        .On_Hover ((
          Border_Color => Set (Border_Color (RGB (251, 191, 36))),
          others       => <>))
        .Build);
      Set_Part_Style (Btn_Border.all, Label_Part, White_Label);

      --  Border radius
      Set_Part_Style (Btn_Radius.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Border_Radius => Set (Radius (Px (6.0))),
          Transition    => Set ((Duration   => 0.3,
                                 Easing     => Ease_In_Out,
                                 Properties => Props (Prop_Border_Radius)))))
        .On_Hover ((
          Border_Radius => Set (Radius (Px (20.0))),
          others        => <>))
        .Build);
      Set_Part_Style (Btn_Radius.all, Label_Part, White_Label);

      --  Box shadow
      Set_Part_Style (Btn_Shadow.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Box_Shadow => Set (No_Shadow),
          Transition => Set ((Duration   => 0.3,
                              Easing     => Ease_Out,
                              Properties => Props (Prop_Box_Shadow)))))
        .On_Hover ((
          Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (4.0),
                                     RGBA (100, 255, 100, 1.0))),
          others     => <>))
        .Build);
      Set_Part_Style (Btn_Shadow.all, Label_Part, White_Label);

      --  Opacity
      Set_Part_Style (Btn_Opacity.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Background_Color => Set_Bg (RGB (239, 68, 68)),
          Opacity    => Set (1.0),
          Transition => Set ((Duration   => 0.25,
                              Easing     => Ease_In_Out,
                              Properties => Props (Prop_Opacity)))))
        .On_Hover ((
          Opacity => Set (0.5),
          others  => <>))
        .Build);
      Set_Part_Style (Btn_Opacity.all, Label_Part, White_Label);

      --  =====================================================================
      --  Section 3: Combined + Duration Variants
      --  =====================================================================

      Set_Part_Style (Sec3.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Column),
          Gap            => Set (G (Px (10.0))),
          others         => <>)).Build);

      Set_Part_Style (Sec3_Row.all, Main_Part,
        Style.Base ((
          Display        => Set (Flex),
          Flex_Direction => Set (Row),
          Gap            => Set (G (Px (16.0))),
          Align_Items    => Set (Flex_Start),
          others         => <>)).Build);

      Set_Part_Style (Col_Multi.all, Main_Part, Col_Style);
      Set_Part_Style (Col_All.all, Main_Part, Col_Style);
      Set_Part_Style (Col_Fast.all, Main_Part, Col_Style);
      Set_Part_Style (Col_Slow.all, Main_Part, Col_Style);

      --  Multiple specific properties: bg + border + shadow
      Set_Part_Style (Btn_Multi.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.3,
                              Easing     => Ease_In_Out,
                              Properties =>
                                 Props (Prop_Background_Color)
                               + Props (Prop_Border_Color)
                               + Props (Prop_Box_Shadow)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (79, 70, 229)),
          Border_Color     => Set (Border_Color (RGB (129, 140, 248))),
          Box_Shadow       => Set (Shadow (Px (0.0), Px (4.0), Px (12.0), Px (0.0),
                                           RGBA (79, 70, 229, 0.4))),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_Multi.all, Label_Part, White_Label);

      --  All properties (default)
      Set_Part_Style (Btn_All.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Box_Shadow => Set (No_Shadow),
          Transition => Set ((Duration   => 0.3,
                              Easing     => Ease_In_Out,
                              Properties => All_Properties))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (6, 182, 212)),
          Border_Color     => Set (Border_Color (RGB (34, 211, 238))),
          Border_Radius    => Set (Radius (Px (16.0))),
          Padding          => Set (Pad (Px (10.0), Px (28.0))),
          Box_Shadow       => Set (Shadow (Px (0.0), Px (4.0), Px (14.0), Px (0.0),
                                           RGBA (6, 182, 212, 0.4))),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_All.all, Label_Part, White_Label);

      --  Fast (50ms)
      Set_Part_Style (Btn_Fast.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.05,
                              Easing     => Linear,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (16, 185, 129)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_Fast.all, Label_Part, White_Label);

      --  Slow (800ms)
      Set_Part_Style (Btn_Slow.all, Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.8,
                              Easing     => Ease_In_Out,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (236, 72, 153)),
          others           => <>))
        .Build);
      Set_Part_Style (Btn_Slow.all, Label_Part, White_Label);

      --  =====================================================================
      --  Build Hierarchy
      --  =====================================================================

      Add_Child (Root.all, Widget_Access (Content));

      --  Section 1: Easing Curves
      Add_Child (Content.all, Widget_Access (Sec1));
      Add_Child (Sec1.all, Widget_Access (Make_Title ("EASING CURVES")));
      Add_Child (Sec1.all, Widget_Access (Sec1_Row));

      Add_Child (Sec1_Row.all, Widget_Access (Col_Linear));
      Add_Child (Col_Linear.all, Widget_Access (Btn_Linear));
      Add_Child (Col_Linear.all, Widget_Access (Make_Desc ("Constant speed")));

      Add_Child (Sec1_Row.all, Widget_Access (Col_EaseIn));
      Add_Child (Col_EaseIn.all, Widget_Access (Btn_EaseIn));
      Add_Child (Col_EaseIn.all, Widget_Access (Make_Desc ("Slow start")));

      Add_Child (Sec1_Row.all, Widget_Access (Col_EaseOut));
      Add_Child (Col_EaseOut.all, Widget_Access (Btn_EaseOut));
      Add_Child (Col_EaseOut.all, Widget_Access (Make_Desc ("Fast start")));

      Add_Child (Sec1_Row.all, Widget_Access (Col_EaseIO));
      Add_Child (Col_EaseIO.all, Widget_Access (Btn_EaseIO));
      Add_Child (Col_EaseIO.all, Widget_Access (Make_Desc ("Smooth both")));

      --  Section 2: Individual Properties
      Add_Child (Content.all, Widget_Access (Sec2));
      Add_Child (Sec2.all, Widget_Access (Make_Title ("INDIVIDUAL PROPERTIES")));
      Add_Child (Sec2.all, Widget_Access (Sec2_Row));

      Add_Child (Sec2_Row.all, Widget_Access (Col_BgColor));
      Add_Child (Col_BgColor.all, Widget_Access (Btn_BgColor));
      Add_Child (Col_BgColor.all, Widget_Access (Make_Desc ("Prop_Background_Color")));

      Add_Child (Sec2_Row.all, Widget_Access (Col_Border));
      Add_Child (Col_Border.all, Widget_Access (Btn_Border));
      Add_Child (Col_Border.all, Widget_Access (Make_Desc ("Prop_Border_Color")));

      Add_Child (Sec2_Row.all, Widget_Access (Col_Radius));
      Add_Child (Col_Radius.all, Widget_Access (Btn_Radius));
      Add_Child (Col_Radius.all, Widget_Access (Make_Desc ("Prop_Border_Radius")));

      Add_Child (Sec2_Row.all, Widget_Access (Col_Shadow));
      Add_Child (Col_Shadow.all, Widget_Access (Btn_Shadow));
      Add_Child (Col_Shadow.all, Widget_Access (Make_Desc ("Prop_Box_Shadow")));

      Add_Child (Sec2_Row.all, Widget_Access (Col_Opacity));
      Add_Child (Col_Opacity.all, Widget_Access (Btn_Opacity));
      Add_Child (Col_Opacity.all, Widget_Access (Make_Desc ("Prop_Opacity")));

      --  Section 3: Combined + Duration
      Add_Child (Content.all, Widget_Access (Sec3));
      Add_Child (Sec3.all, Widget_Access (Make_Title ("COMBINED & DURATION")));
      Add_Child (Sec3.all, Widget_Access (Sec3_Row));

      Add_Child (Sec3_Row.all, Widget_Access (Col_Multi));
      Add_Child (Col_Multi.all, Widget_Access (Btn_Multi));
      Add_Child (Col_Multi.all, Widget_Access (Make_Desc ("bg + border + shadow")));

      Add_Child (Sec3_Row.all, Widget_Access (Col_All));
      Add_Child (Col_All.all, Widget_Access (Btn_All));
      Add_Child (Col_All.all, Widget_Access (Make_Desc ("All_Properties")));

      Add_Child (Sec3_Row.all, Widget_Access (Col_Fast));
      Add_Child (Col_Fast.all, Widget_Access (Btn_Fast));
      Add_Child (Col_Fast.all, Widget_Access (Make_Desc ("50ms linear")));

      Add_Child (Sec3_Row.all, Widget_Access (Col_Slow));
      Add_Child (Col_Slow.all, Widget_Access (Btn_Slow));
      Add_Child (Col_Slow.all, Widget_Access (Make_Desc ("800ms ease-in-out")));

      --  Set root and run
      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Transition_Example;
