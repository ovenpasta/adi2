pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;  use Adi.Widget.Label;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Transition_Example_Styles; use Transition_Example_Styles;

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
   White_Label : constant Widget_Style := White_Label_Widget;

   --  Helper: section title label
   function Make_Title (Text : String) return Label_Widget_Access is
      L : constant Label_Widget_Access := Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Styles (L.all, Title_Part_Styles);
      return L;
   end Make_Title;

   --  Helper: description label under a button
   function Make_Desc (Text : String) return Label_Widget_Access is
      L : constant Label_Widget_Access := Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Styles (L.all, Desc_Part_Styles);
      return L;
   end Make_Desc;

   --  Common base style for demo buttons
   Demo_Base : constant Style_Rules := Demo_Base_Base_Style;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Transition Examples", (900.0, 700.0));

      --  Root container
      Root : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Scrollable content area
      Content : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      -----------------------------------------------------------------------
      --  Section 1: Easing Curves (all transition background-color)
      -----------------------------------------------------------------------
      Sec1      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Sec1_Row  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  One button per easing
      Btn_Linear   : constant Button_Widget_Access := Create ("Linear");
      Btn_EaseIn   : constant Button_Widget_Access := Create ("Ease In");
      Btn_EaseOut  : constant Button_Widget_Access := Create ("Ease Out");
      Btn_EaseIO   : constant Button_Widget_Access := Create ("Ease In Out");

      --  Description boxes
      Col_Linear  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_EaseIn  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_EaseOut : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_EaseIO  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      -----------------------------------------------------------------------
      --  Section 2: Individual Properties
      -----------------------------------------------------------------------
      Sec2      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Sec2_Row  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Btn_BgColor   : constant Button_Widget_Access := Create ("Background");
      Btn_Border    : constant Button_Widget_Access := Create ("Border Color");
      Btn_Radius    : constant Button_Widget_Access := Create ("Radius");
      Btn_Shadow    : constant Button_Widget_Access := Create ("Shadow");
      Btn_Opacity   : constant Button_Widget_Access := Create ("Opacity");

      Col_BgColor  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Border   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Radius   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Shadow   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Opacity  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      -----------------------------------------------------------------------
      --  Section 3: Combined Properties + Duration
      -----------------------------------------------------------------------
      Sec3      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Sec3_Row  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Btn_Multi    : constant Button_Widget_Access := Create ("Multi-Property");
      Btn_All      : constant Button_Widget_Access := Create ("All Properties");
      Btn_Fast     : constant Button_Widget_Access := Create ("Fast (50ms)");
      Btn_Slow     : constant Button_Widget_Access := Create ("Slow (800ms)");

      Col_Multi : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_All   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Fast  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Col_Slow  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

   begin
      --  === Root ===
      Set_Part_Styles (Root.all, Root_Part_Styles);

      --  === Content ===
      Set_Part_Styles (Content.all, Content_Part_Styles);

      --  =====================================================================
      --  Section 1: Easing Curves
      --  =====================================================================

      --  Section container
      Set_Part_Styles (Sec1.all, Section_Part_Styles);

      --  Row of buttons
      Set_Part_Styles (Sec1_Row.all, Section_Row_Part_Styles);

      --  Column containers for button+desc
      Set_Part_Styles (Col_Linear.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_EaseIn.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_EaseOut.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_EaseIO.all, Col_Style_Part_Styles);

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

      Set_Part_Styles (Sec2.all, Section_Part_Styles);

      Set_Part_Styles (Sec2_Row.all, Section_Row_Part_Styles);

      Set_Part_Styles (Col_BgColor.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_Border.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_Radius.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_Shadow.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_Opacity.all, Col_Style_Part_Styles);

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

      Set_Part_Styles (Sec3.all, Section_Part_Styles);

      Set_Part_Styles (Sec3_Row.all, Section_Row_Part_Styles);

      Set_Part_Styles (Col_Multi.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_All.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_Fast.all, Col_Style_Part_Styles);
      Set_Part_Styles (Col_Slow.all, Col_Style_Part_Styles);

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
          Padding          => Set (CSS_Box (Px (10.0), Px (28.0))),
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

      Root.Add_Child (Content);

      --  Section 1: Easing Curves
      Content.Add_Child (Sec1);
      Sec1.Add_Child (Make_Title ("EASING CURVES"));
      Sec1.Add_Child (Sec1_Row);

      Sec1_Row.Add_Child (Col_Linear);
      Col_Linear.Add_Child (Btn_Linear);
      Col_Linear.Add_Child (Make_Desc ("Constant speed"));

      Sec1_Row.Add_Child (Col_EaseIn);
      Col_EaseIn.Add_Child (Btn_EaseIn);
      Col_EaseIn.Add_Child (Make_Desc ("Slow start"));

      Sec1_Row.Add_Child (Col_EaseOut);
      Col_EaseOut.Add_Child (Btn_EaseOut);
      Col_EaseOut.Add_Child (Make_Desc ("Fast start"));

      Sec1_Row.Add_Child (Col_EaseIO);
      Col_EaseIO.Add_Child (Btn_EaseIO);
      Col_EaseIO.Add_Child (Make_Desc ("Smooth both"));

      --  Section 2: Individual Properties
      Content.Add_Child (Sec2);
      Sec2.Add_Child (Make_Title ("INDIVIDUAL PROPERTIES"));
      Sec2.Add_Child (Sec2_Row);

      Sec2_Row.Add_Child (Col_BgColor);
      Col_BgColor.Add_Child (Btn_BgColor);
      Col_BgColor.Add_Child (Make_Desc ("Prop_Background_Color"));

      Sec2_Row.Add_Child (Col_Border);
      Col_Border.Add_Child (Btn_Border);
      Col_Border.Add_Child (Make_Desc ("Prop_Border_Color"));

      Sec2_Row.Add_Child (Col_Radius);
      Col_Radius.Add_Child (Btn_Radius);
      Col_Radius.Add_Child (Make_Desc ("Prop_Border_Radius"));

      Sec2_Row.Add_Child (Col_Shadow);
      Col_Shadow.Add_Child (Btn_Shadow);
      Col_Shadow.Add_Child (Make_Desc ("Prop_Box_Shadow"));

      Sec2_Row.Add_Child (Col_Opacity);
      Col_Opacity.Add_Child (Btn_Opacity);
      Col_Opacity.Add_Child (Make_Desc ("Prop_Opacity"));

      --  Section 3: Combined + Duration
      Content.Add_Child (Sec3);
      Sec3.Add_Child (Make_Title ("COMBINED & DURATION"));
      Sec3.Add_Child (Sec3_Row);

      Sec3_Row.Add_Child (Col_Multi);
      Col_Multi.Add_Child (Btn_Multi);
      Col_Multi.Add_Child (Make_Desc ("bg + border + shadow"));

      Sec3_Row.Add_Child (Col_All);
      Col_All.Add_Child (Btn_All);
      Col_All.Add_Child (Make_Desc ("All_Properties"));

      Sec3_Row.Add_Child (Col_Fast);
      Col_Fast.Add_Child (Btn_Fast);
      Col_Fast.Add_Child (Make_Desc ("50ms linear"));

      Sec3_Row.Add_Child (Col_Slow);
      Col_Slow.Add_Child (Btn_Slow);
      Col_Slow.Add_Child (Make_Desc ("800ms ease-in-out"));

      --  Set root and run
      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Transition_Example;
