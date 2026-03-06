pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Button;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Transition_Example_Styles; use Transition_Example_Styles;

use type Adi.Widget.Box.Box_Handle;
use type Adi.Widget.Label.Label_Handle;
use type Adi.Widget.Button.Button_Handle;

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
   White_Label : constant Widget_Style := White_Label_Class_Widget;

   --  Helper: section title label
   function Make_Title (Text : String) return Adi.Widget.Label.Label_Handle is
      L : constant Adi.Widget.Label.Label_Handle :=
            Adi.Widget.Label.Create_Handle (Text);
   begin
      Adi.Widget.Label.Set_Part_Styles (L, Title_Class_Part_Styles);
      return L;
   end Make_Title;

   --  Helper: description label under a button
   function Make_Desc (Text : String) return Adi.Widget.Label.Label_Handle is
      L : constant Adi.Widget.Label.Label_Handle :=
            Adi.Widget.Label.Create_Handle (Text);
   begin
      Adi.Widget.Label.Set_Part_Styles (L, Desc_Class_Part_Styles);
      return L;
   end Make_Desc;

   --  Common base style for demo buttons
   Demo_Base : constant Style_Rules := Demo_Base_Class_Base_Style;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle := Create_Window_Handle ("Transition Examples", (900.0, 700.0));

      --  Root container
      Root : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      --  Scrollable content area
      Content : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      -----------------------------------------------------------------------
      --  Section 1: Easing Curves (all transition background-color)
      -----------------------------------------------------------------------
      Sec1      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Sec1_Row  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      --  One button per easing
      Btn_Linear   : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Linear");
      Btn_EaseIn   : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Ease In");
      Btn_EaseOut  : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Ease Out");
      Btn_EaseIO   : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Ease In Out");

      --  Description boxes
      Col_Linear  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_EaseIn  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_EaseOut : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_EaseIO  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      -----------------------------------------------------------------------
      --  Section 2: Individual Properties
      -----------------------------------------------------------------------
      Sec2      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Sec2_Row  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Btn_BgColor   : constant Adi.Widget.Button.Button_Handle :=
                        Adi.Widget.Button.Create_Handle ("Background");
      Btn_Border    : constant Adi.Widget.Button.Button_Handle :=
                        Adi.Widget.Button.Create_Handle ("Border Color");
      Btn_Radius    : constant Adi.Widget.Button.Button_Handle :=
                        Adi.Widget.Button.Create_Handle ("Radius");
      Btn_Shadow    : constant Adi.Widget.Button.Button_Handle :=
                        Adi.Widget.Button.Create_Handle ("Shadow");
      Btn_Opacity   : constant Adi.Widget.Button.Button_Handle :=
                        Adi.Widget.Button.Create_Handle ("Opacity");

      Col_BgColor  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_Border   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_Radius   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_Shadow   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_Opacity  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      -----------------------------------------------------------------------
      --  Section 3: Combined Properties + Duration
      -----------------------------------------------------------------------
      Sec3      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Sec3_Row  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Btn_Multi    : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Multi-Property");
      Btn_All      : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("All Properties");
      Btn_Fast     : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Fast (50ms)");
      Btn_Slow     : constant Adi.Widget.Button.Button_Handle :=
                       Adi.Widget.Button.Create_Handle ("Slow (800ms)");

      Col_Multi : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_All   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_Fast  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Col_Slow  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

   begin
      --  === Root ===
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);

      --  === Content ===
      Adi.Widget.Box.Set_Part_Styles (Content, Content_Class_Part_Styles);

      --  =====================================================================
      --  Section 1: Easing Curves
      --  =====================================================================

      --  Section container
      Adi.Widget.Box.Set_Part_Styles (Sec1, Section_Class_Part_Styles);

      --  Row of buttons
      Adi.Widget.Box.Set_Part_Styles (Sec1_Row, Section_Row_Class_Part_Styles);

      --  Column containers for button+desc
      Adi.Widget.Box.Set_Part_Styles (Col_Linear, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_EaseIn, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_EaseOut, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_EaseIO, Col_Style_Class_Part_Styles);

      --  Linear: constant speed, no acceleration
      Set_Part_Style (Widget_Handle'(+Btn_Linear), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_Linear), Label_Part, White_Label);

      --  Ease In: slow start, fast end
      Set_Part_Style (Widget_Handle'(+Btn_EaseIn), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_EaseIn), Label_Part, White_Label);

      --  Ease Out: fast start, slow end
      Set_Part_Style (Widget_Handle'(+Btn_EaseOut), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_EaseOut), Label_Part, White_Label);

      --  Ease In Out: slow start & end, fast middle
      Set_Part_Style (Widget_Handle'(+Btn_EaseIO), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_EaseIO), Label_Part, White_Label);

      --  =====================================================================
      --  Section 2: Individual Properties
      --  =====================================================================

      Adi.Widget.Box.Set_Part_Styles (Sec2, Section_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Sec2_Row, Section_Row_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Col_BgColor, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_Border, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_Radius, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_Shadow, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_Opacity, Col_Style_Class_Part_Styles);

      --  Background color only
      Set_Part_Style (Widget_Handle'(+Btn_BgColor), Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.25,
                              Easing     => Ease_In_Out,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (59, 130, 246)),
          others           => <>))
        .Build);
      Set_Part_Style (Widget_Handle'(+Btn_BgColor), Label_Part, White_Label);

      --  Border color only
      Set_Part_Style (Widget_Handle'(+Btn_Border), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_Border), Label_Part, White_Label);

      --  Border radius
      Set_Part_Style (Widget_Handle'(+Btn_Radius), Main_Part,
        Style.Base ((Demo_Base with delta
          Border_Radius => Set (Radius (Px (6.0))),
          Transition    => Set ((Duration   => 0.3,
                                 Easing     => Ease_In_Out,
                                 Properties => Props (Prop_Border_Radius)))))
        .On_Hover ((
          Border_Radius => Set (Radius (Px (20.0))),
          others        => <>))
        .Build);
      Set_Part_Style (Widget_Handle'(+Btn_Radius), Label_Part, White_Label);

      --  Box shadow
      Set_Part_Style (Widget_Handle'(+Btn_Shadow), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_Shadow), Label_Part, White_Label);

      --  Opacity
      Set_Part_Style (Widget_Handle'(+Btn_Opacity), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_Opacity), Label_Part, White_Label);

      --  =====================================================================
      --  Section 3: Combined + Duration Variants
      --  =====================================================================

      Adi.Widget.Box.Set_Part_Styles (Sec3, Section_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Sec3_Row, Section_Row_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Col_Multi, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_All, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_Fast, Col_Style_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Col_Slow, Col_Style_Class_Part_Styles);

      --  Multiple specific properties: bg + border + shadow
      Set_Part_Style (Widget_Handle'(+Btn_Multi), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_Multi), Label_Part, White_Label);

      --  All properties (default)
      Set_Part_Style (Widget_Handle'(+Btn_All), Main_Part,
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
      Set_Part_Style (Widget_Handle'(+Btn_All), Label_Part, White_Label);

      --  Fast (50ms)
      Set_Part_Style (Widget_Handle'(+Btn_Fast), Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.05,
                              Easing     => Linear,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (16, 185, 129)),
          others           => <>))
        .Build);
      Set_Part_Style (Widget_Handle'(+Btn_Fast), Label_Part, White_Label);

      --  Slow (800ms)
      Set_Part_Style (Widget_Handle'(+Btn_Slow), Main_Part,
        Style.Base ((Demo_Base with delta
          Transition => Set ((Duration   => 0.8,
                              Easing     => Ease_In_Out,
                              Properties => Props (Prop_Background_Color)))))
        .On_Hover ((
          Background_Color => Set_Bg (RGB (236, 72, 153)),
          others           => <>))
        .Build);
      Set_Part_Style (Widget_Handle'(+Btn_Slow), Label_Part, White_Label);

      --  =====================================================================
      --  Build Hierarchy
      --  =====================================================================

      Add_Child (+Root, +Content);

      --  Section 1: Easing Curves
      Add_Child (+Content, +Sec1);
      Add_Child (+Sec1, +Make_Title ("EASING CURVES"));
      Add_Child (+Sec1, +Sec1_Row);

      Add_Child (+Sec1_Row, +Col_Linear);
      Add_Child (+Col_Linear, +Btn_Linear);
      Add_Child (+Col_Linear, +Make_Desc ("Constant speed"));

      Add_Child (+Sec1_Row, +Col_EaseIn);
      Add_Child (+Col_EaseIn, +Btn_EaseIn);
      Add_Child (+Col_EaseIn, +Make_Desc ("Slow start"));

      Add_Child (+Sec1_Row, +Col_EaseOut);
      Add_Child (+Col_EaseOut, +Btn_EaseOut);
      Add_Child (+Col_EaseOut, +Make_Desc ("Fast start"));

      Add_Child (+Sec1_Row, +Col_EaseIO);
      Add_Child (+Col_EaseIO, +Btn_EaseIO);
      Add_Child (+Col_EaseIO, +Make_Desc ("Smooth both"));

      --  Section 2: Individual Properties
      Add_Child (+Content, +Sec2);
      Add_Child (+Sec2, +Make_Title ("INDIVIDUAL PROPERTIES"));
      Add_Child (+Sec2, +Sec2_Row);

      Add_Child (+Sec2_Row, +Col_BgColor);
      Add_Child (+Col_BgColor, +Btn_BgColor);
      Add_Child (+Col_BgColor, +Make_Desc ("Prop_Background_Color"));

      Add_Child (+Sec2_Row, +Col_Border);
      Add_Child (+Col_Border, +Btn_Border);
      Add_Child (+Col_Border, +Make_Desc ("Prop_Border_Color"));

      Add_Child (+Sec2_Row, +Col_Radius);
      Add_Child (+Col_Radius, +Btn_Radius);
      Add_Child (+Col_Radius, +Make_Desc ("Prop_Border_Radius"));

      Add_Child (+Sec2_Row, +Col_Shadow);
      Add_Child (+Col_Shadow, +Btn_Shadow);
      Add_Child (+Col_Shadow, +Make_Desc ("Prop_Box_Shadow"));

      Add_Child (+Sec2_Row, +Col_Opacity);
      Add_Child (+Col_Opacity, +Btn_Opacity);
      Add_Child (+Col_Opacity, +Make_Desc ("Prop_Opacity"));

      --  Section 3: Combined + Duration
      Add_Child (+Content, +Sec3);
      Add_Child (+Sec3, +Make_Title ("COMBINED & DURATION"));
      Add_Child (+Sec3, +Sec3_Row);

      Add_Child (+Sec3_Row, +Col_Multi);
      Add_Child (+Col_Multi, +Btn_Multi);
      Add_Child (+Col_Multi, +Make_Desc ("bg + border + shadow"));

      Add_Child (+Sec3_Row, +Col_All);
      Add_Child (+Col_All, +Btn_All);
      Add_Child (+Col_All, +Make_Desc ("All_Properties"));

      Add_Child (+Sec3_Row, +Col_Fast);
      Add_Child (+Col_Fast, +Btn_Fast);
      Add_Child (+Col_Fast, +Make_Desc ("50ms linear"));

      Add_Child (+Sec3_Row, +Col_Slow);
      Add_Child (+Col_Slow, +Btn_Slow);
      Add_Child (+Col_Slow, +Make_Desc ("800ms ease-in-out"));

      --  Set root and run
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Transition_Example;
