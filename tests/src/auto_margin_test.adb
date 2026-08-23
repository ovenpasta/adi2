pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core;          use Adi.Core;
with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Auto_Margin_Styles;
with Test_Support;      use Test_Support;

procedure Auto_Margin_Test is

   Eps : constant Pixel_Type := 0.01;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Message : String) is
   begin
      Assert (abs (Actual - Expected) <= Eps,
              Message & " (got" & Actual'Image
              & ", expected" & Expected'Image & ")");
   end Assert_Close;

   function Is_Auto (M : Margin_Value) return Boolean is (M.Kind = Auto);

   function Fixed_Px (M : Margin_Value) return Float is
     (if M.Kind = Fixed then M.Length.Amount else Float'First);

   ---------------------------------------------------------------------------
   --  Parsing: `auto` reaches Resolved_Style as auto, per side, and
   --  survives the cascade the same way a length does.
   ---------------------------------------------------------------------------

   procedure Test_Parser_Accepts_Auto is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;

      CSS : constant String :=
        ".a { margin: 0 auto; }" & ASCII.LF &
        ".b { margin-left: auto; }" & ASCII.LF &
        ".c { margin: 5px auto 12px; }" & ASCII.LF &
        ".d { margin: auto; }" & ASCII.LF &
        ".e { margin: 1px 2px 3px 4px; }" & ASCII.LF &
        --  A length rule then an auto longhand: the auto must win on the
        --  side it names and leave the other three as lengths.
        ".f { margin: 6px; }" & ASCII.LF &
        ".f { margin-right: auto; }" & ASCII.LF &
        --  And the reverse: a length longhand over an auto shorthand.
        ".g { margin: auto; }" & ASCII.LF &
        ".g { margin-top: 9px; }" & ASCII.LF;

      function Resolved (Class : String) return Resolved_Style is
         Styles : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, Class);
      begin
         return Compute_Resolved
           (Styles (Main_Part).Style, No_States, No_States);
      end Resolved;
   begin
      Section ("the runtime parser accepts auto in margins");

      Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
      Assert (OK, "auto-margin stylesheet should parse");

      declare
         M : constant Margin_Sides := Resolved ("a").Margin;
      begin
         Assert (not Is_Auto (M (Top)) and then Fixed_Px (M (Top)) = 0.0,
                 "margin: 0 auto leaves the top a zero length");
         Assert (Is_Auto (M (Right)), "margin: 0 auto makes the right auto");
         Assert (not Is_Auto (M (Bottom)) and then Fixed_Px (M (Bottom)) = 0.0,
                 "margin: 0 auto leaves the bottom a zero length");
         Assert (Is_Auto (M (Left)), "margin: 0 auto makes the left auto");
      end;

      declare
         M : constant Margin_Sides := Resolved ("b").Margin;
      begin
         Assert (Is_Auto (M (Left)), "margin-left: auto sets the left auto");
         Assert (not Is_Auto (M (Right)),
                 "and leaves the right a length");
      end;

      declare
         M : constant Margin_Sides := Resolved ("c").Margin;
      begin
         Assert (Fixed_Px (M (Top)) = 5.0,
                 "the three-value form takes its top from the first token");
         Assert (Is_Auto (M (Right)) and then Is_Auto (M (Left)),
                 "the three-value form's middle token names both sides");
         Assert (Fixed_Px (M (Bottom)) = 12.0,
                 "the three-value form takes its bottom from the third token");
      end;

      declare
         M : constant Margin_Sides := Resolved ("d").Margin;
      begin
         Assert ((for all E in Edge => Is_Auto (M (E))),
                 "margin: auto makes all four sides auto");
      end;

      declare
         M : constant Margin_Sides := Resolved ("e").Margin;
      begin
         Assert (Fixed_Px (M (Top)) = 1.0 and then Fixed_Px (M (Right)) = 2.0
                   and then Fixed_Px (M (Bottom)) = 3.0
                   and then Fixed_Px (M (Left)) = 4.0,
                 "a four-length margin still resolves side by side");
      end;

      declare
         M : constant Margin_Sides := Resolved ("f").Margin;
      begin
         Assert (Is_Auto (M (Right)),
                 "an auto longhand overrides an earlier length on that side");
         Assert (Fixed_Px (M (Top)) = 6.0 and then Fixed_Px (M (Left)) = 6.0
                   and then Fixed_Px (M (Bottom)) = 6.0,
                 "and leaves the other three sides at the shorthand's length");
      end;

      declare
         M : constant Margin_Sides := Resolved ("g").Margin;
      begin
         Assert (not Is_Auto (M (Top)) and then Fixed_Px (M (Top)) = 9.0,
                 "a length longhand overrides an earlier auto on that side");
         Assert (Is_Auto (M (Right)) and then Is_Auto (M (Bottom))
                   and then Is_Auto (M (Left)),
                 "and leaves the other three sides auto");
      end;
   end Test_Parser_Accepts_Auto;

   ---------------------------------------------------------------------------
   --  CSS requires an invalid declaration to be dropped. `auto` is not a
   --  padding or border-width value, so those declarations must vanish
   --  rather than resolve to anything.
   ---------------------------------------------------------------------------

   procedure Test_Auto_Is_Rejected_Off_Margins is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;

      CSS : constant String :=
        ".p { padding: 8px; padding: auto; }" & ASCII.LF &
        ".q { border-width: 3px; border-width: auto; }" & ASCII.LF &
        ".r { padding-left: auto; padding-top: 2px; }" & ASCII.LF;

      function Resolved (Class : String) return Resolved_Style is
         Styles : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, Class);
      begin
         return Compute_Resolved
           (Styles (Main_Part).Style, No_States, No_States);
      end Resolved;

      function Pad_Sides (B : CSS_Box_Value) return CSS_Box_Sides is
        (case B.Kind is
           when Gap_Uniform => [others => B.All_Sides],
           when Axis        => [Top | Bottom => B.Vertical,
                                Left | Right => B.Horizontal],
           when Per_Side    => B.Sides);

      function Bw_Edges (B : Border_Width_Value) return Edge_Lengths is
        (case B.Kind is
           when Gap_Uniform => [others => B.All_Edges],
           when Per_Edge    => B.Edges);
   begin
      Section ("auto is invalid for padding and border-width");

      Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
      Assert (OK, "stylesheet with invalid autos should still parse");

      declare
         S : constant CSS_Box_Sides := Pad_Sides (Resolved ("p").Padding);
      begin
         Assert ((for all E in Edge => S (E) = Px (8.0)),
                 "padding: auto is dropped, leaving the earlier padding");
      end;

      declare
         E : constant Edge_Lengths := Bw_Edges (Resolved ("q").Border_Width);
      begin
         Assert ((for all Side in Edge => E (Side) = Px (3.0)),
                 "border-width: auto is dropped, leaving the earlier width");
      end;

      declare
         S : constant CSS_Box_Sides := Pad_Sides (Resolved ("r").Padding);
      begin
         Assert (S (Left) = Px (0.0),
                 "padding-left: auto is dropped rather than accepted");
         Assert (S (Top) = Px (2.0),
                 "a valid longhand beside it still applies");
      end;
   end Test_Auto_Is_Rejected_Off_Margins;

   ---------------------------------------------------------------------------
   --  CSS 2.1 10.3.3, block-level non-replaced elements in normal flow.
   ---------------------------------------------------------------------------

   procedure Test_Both_Auto_Centres is
      Box_W : constant Pixel_Type := 200.0;
      Kid_W : constant Pixel_Type := 120.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Kid_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Auto_Margin,
                               Zero_Margin, Auto_Margin),
         others => <>);
   begin
      Section ("two auto margins centre a block child");

      Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, Kid);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Kid).Width, Kid_W,
                    "the child keeps its declared width");
      Assert_Close (Get_Geometry (Kid).X, (Box_W - Kid_W) / 2.0,
                    "and the leftover splits evenly on both sides");
   end Test_Both_Auto_Centres;

   --  An odd leftover halves to a fraction. Layout is in floating-point
   --  pixels throughout, so the child sits on the true centre rather than
   --  being snapped to a whole pixel.
   procedure Test_Odd_Leftover_Is_Not_Snapped is
      Box_W : constant Pixel_Type := 200.0;
      Kid_W : constant Pixel_Type := 125.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Kid_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Auto_Margin,
                               Zero_Margin, Auto_Margin),
         others => <>);
   begin
      Section ("centring an odd leftover keeps the fraction");

      Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, Kid);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      --  (200 - 125) / 2 = 37.5
      Assert_Close (Get_Geometry (Kid).X, 37.5,
                    "the child centres on the half pixel");
   end Test_Odd_Leftover_Is_Not_Snapped;

   procedure Test_One_Auto_Absorbs_The_Leftover is
      Box_W : constant Pixel_Type := 200.0;
      Kid_W : constant Pixel_Type := 120.0;
      Fixed : constant Pixel_Type := 10.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Right_Aligned : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Left_Aligned : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      --  margin-left: auto pushes the box to the right edge.
      Right_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Zero_Margin,
                               Zero_Margin, Auto_Margin),
         others => <>);
      --  margin-right: auto leaves it at the left edge, past its own
      --  declared left margin.
      Left_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Auto_Margin,
                               Zero_Margin, Margin (Px (Float (Fixed)))),
         others => <>);
   begin
      Section ("one auto margin takes all the leftover");

      Set_Part_Style (Right_Aligned, Main_Part, From (Right_Rules).Build);
      Set_Part_Style (Left_Aligned, Main_Part, From (Left_Rules).Build);
      Add_Child (Box, Right_Aligned);
      Add_Child (Box, Left_Aligned);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Right_Aligned).X, Box_W - Kid_W,
                    "margin-left: auto pushes the child to the right edge");
      Assert_Close (Get_Geometry (Left_Aligned).X, Fixed,
                    "margin-right: auto leaves the child at its left margin");
   end Test_One_Auto_Absorbs_The_Leftover;

   procedure Test_Auto_Width_Collapses_Auto_Margins is
      Box_W : constant Pixel_Type := 200.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      --  No width: CSS 2.1 makes the auto margins zero and the width
      --  fills the containing block.
      Kid_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Auto_Margin,
                               Zero_Margin, Auto_Margin),
         others => <>);
   begin
      Section ("auto margins collapse under an auto width");

      Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, Kid);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Kid).Width, Box_W,
                    "the child fills the containing block");
      Assert_Close (Get_Geometry (Kid).X, 0.0,
                    "and the auto margins contribute nothing");
   end Test_Auto_Width_Collapses_Auto_Margins;

   procedure Test_Over_Constrained_Adjusts_The_Right_Margin is
      Box_W  : constant Pixel_Type := 200.0;
      Kid_W  : constant Pixel_Type := 120.0;
      Left_M : constant Pixel_Type := 10.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      --  10 + 120 + 100 = 230, wider than the 200 container: for a
      --  left-to-right box the right margin is the one that gives.
      Kid_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Margin (Px (100.0)),
                               Zero_Margin, Margin (Px (Float (Left_M)))),
         others => <>);
   begin
      Section ("an over-constrained block child keeps its left margin");

      Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, Kid);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Kid).Width, Kid_W,
                    "the declared width survives");
      Assert_Close (Get_Geometry (Kid).X, Left_M,
                    "and the left margin holds, the right one absorbing"
                    & " the mismatch");
   end Test_Over_Constrained_Adjusts_The_Right_Margin;

   ---------------------------------------------------------------------------
   --  CSS 2.1 10.6.3: for a block box in normal flow, a vertical auto
   --  margin computes to zero. It must not centre and must not shift the
   --  stack.
   ---------------------------------------------------------------------------

   procedure Test_Vertical_Autos_Are_Zero is
      Box_H : constant Pixel_Type := 300.0;
      Kid_H : constant Pixel_Type := 20.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      First : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Second : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Kid_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (Float (Kid_H)))),
         Margin => Set_Margin (Auto_Margin, Zero_Margin,
                               Auto_Margin, Zero_Margin),
         others => <>);
   begin
      Section ("vertical auto margins are zero in block flow");

      Set_Part_Style (First, Main_Part, From (Kid_Rules).Build);
      Set_Part_Style (Second, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, First);
      Add_Child (Box, Second);
      Set_Geometry (Box, (0.0, 0.0, 200.0, Box_H));
      Layout (Box);

      Assert_Close (Get_Geometry (First).Y, 0.0,
                    "the first child sits at the content origin");
      Assert_Close (Get_Geometry (Second).Y, Kid_H,
                    "and the second follows it with no gap");
   end Test_Vertical_Autos_Are_Zero;

   ---------------------------------------------------------------------------
   --  Centring must survive the container's padding: the leftover is
   --  measured against the content box, not the border box.
   ---------------------------------------------------------------------------

   procedure Test_Centring_Respects_Padding is
      Pad     : constant Pixel_Type := 10.0;
      Box_W   : constant Pixel_Type := 200.0;
      Content : constant Pixel_Type := Box_W - 2.0 * Pad;
      Kid_W   : constant Pixel_Type := 100.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Box_Rules : constant Style_Rules :=
        (Padding => Set (CSS_Box (Px (Float (Pad)))), others => <>);
      Kid_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (Zero_Margin, Auto_Margin,
                               Zero_Margin, Auto_Margin),
         others => <>);
   begin
      Section ("centring measures against the content box");

      Set_Part_Style (Box, Main_Part, From (Box_Rules).Build);
      Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, Kid);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Kid).X, Pad + (Content - Kid_W) / 2.0,
                    "the child centres within the padded content box");
   end Test_Centring_Respects_Padding;

   ---------------------------------------------------------------------------
   --  Flex is out of scope for auto-margin distribution. What matters
   --  here is that a flex child carrying one does something sane rather
   --  than crashing or laying out absurdly: auto counts as zero.
   ---------------------------------------------------------------------------

   procedure Test_Flex_Treats_Auto_As_Zero is
      Box_W : constant Pixel_Type := 200.0;
      Kid_W : constant Pixel_Type := 60.0;

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Row_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Row),
         others         => <>);
      Kid_Rules : constant Style_Rules :=
        (Width       => Set (Size (Px (Float (Kid_W)))),
         Height      => Set (Size (Px (20.0))),
         Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.0),
         Margin      => Set_Margin (Zero_Margin, Auto_Margin,
                                    Zero_Margin, Auto_Margin),
         others      => <>);
   begin
      Section ("a flex child with an auto margin treats it as zero");

      Set_Part_Style (Box, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
      Add_Child (Box, Kid);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Kid).Width, Kid_W,
                    "the flex child keeps its basis width");
      Assert_Close (Get_Geometry (Kid).X, 0.0,
                    "and stays at flex-start rather than centring");
   end Test_Flex_Treats_Auto_As_Zero;

   ---------------------------------------------------------------------------
   --  tools/css_to_ada.py merges at build time and Adi.CSS_Parser at run
   --  time. A stylesheet whose margins resolve differently depending on
   --  which loaded it is the failure this section exists to catch.
   ---------------------------------------------------------------------------

   Corpus_Path : constant String := "tests/css/auto_margin.css";

   procedure Test_Pipeline_Agreement is
      Generated : Adi.CSS_Source.Style_Source;
      Parsed    : Adi.CSS_Source.Style_Source;
      Gen_W     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Par_W     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      OK        : Boolean := False;

      procedure Bind (Source : in out Adi.CSS_Source.Style_Source;
                      W      : Adi.Widget.Box.Box_Handle) is
      begin
         Adi.CSS_Source.Bind_Selector_Set
           (Source     => Source,
            W          => Adi.Widget.Box."+" (W),
            Tag_Name   => "box",
            Class_Name => "centred",
            Id_Name    => "bad");
      end Bind;

      function Gen_Style return Resolved_Style is
        (Get_Resolved_Part_Style (Adi.Widget.Box."+" (Gen_W), Main_Part));
      function Par_Style return Resolved_Style is
        (Get_Resolved_Part_Style (Adi.Widget.Box."+" (Par_W), Main_Part));

      procedure Compare_Margins (Label : String) is
         G : constant Margin_Sides := Gen_Style.Margin;
         P : constant Margin_Sides := Par_Style.Margin;
      begin
         Assert (G = P, Label & ": margins agree between the two pipelines");
         if G /= P then
            for E in Edge loop
               Put_Line ("      " & E'Image
                         & " generated=" & G (E).Kind'Image
                         & " parsed=" & P (E).Kind'Image);
            end loop;
         end if;
      end Compare_Margins;

      --  Agreement alone would pass with both pipelines wrong the same
      --  way, so what they should say is spelled out too.
      procedure Expect_Centred is
         M : constant Margin_Sides := Par_Style.Margin;
      begin
         Assert (Is_Auto (M (Left)) and then Is_Auto (M (Right)),
                 "the class's `margin: 0 auto` reaches both side margins");
         Assert (not Is_Auto (M (Top)) and then Fixed_Px (M (Top)) = 0.0,
                 "and its zero reaches the top");
      end Expect_Centred;

      --  The id in the corpus declares `padding: auto` and
      --  `border-width: auto` beside one valid longhand each.
      procedure Expect_Invalid_Dropped is
         S : constant Resolved_Style := Par_Style;

         function Pad_Sides (B : CSS_Box_Value) return CSS_Box_Sides is
           (case B.Kind is
              when Gap_Uniform => [others => B.All_Sides],
              when Axis        => [Top | Bottom => B.Vertical,
                                   Left | Right => B.Horizontal],
              when Per_Side    => B.Sides);

         function Bw_Edges (B : Border_Width_Value) return Edge_Lengths is
           (case B.Kind is
              when Gap_Uniform => [others => B.All_Edges],
              when Per_Edge    => B.Edges);

         P : constant CSS_Box_Sides := Pad_Sides (S.Padding);
         B : constant Edge_Lengths  := Bw_Edges (S.Border_Width);
      begin
         Assert (P (Top) = Px (3.0),
                 "the id's valid padding longhand applies");
         Assert (P (Right) = Px (0.0) and then P (Bottom) = Px (0.0)
                   and then P (Left) = Px (0.0),
                 "and `padding: auto` beside it contributed nothing");
         Assert (B (Left) = Px (6.0),
                 "the id's valid border-width longhand applies");
         Assert (B (Top) = Px (0.0),
                 "and `border-width: auto` beside it contributed nothing");
      end Expect_Invalid_Dropped;

   begin
      Section ("generated and parsed pipelines agree on auto margins");

      Auto_Margin_Styles.Register_Selectors (Generated);
      Adi.CSS_Source.Set_Mode (Generated, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "generated stylesheet should install");

      Adi.CSS_Source.Add_Dynamic_File (Parsed, Corpus_Path, OK);
      Assert (OK, "corpus file should be readable from the repository root");
      Adi.CSS_Source.Set_Mode (Parsed, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "parsed stylesheet should install");

      Bind (Generated, Gen_W);
      Bind (Parsed, Par_W);

      Compare_Margins ("base");
      Expect_Centred;
      Expect_Invalid_Dropped;

      Set_Hovered (Adi.Widget.Box."+" (Gen_W));
      Set_Hovered (Adi.Widget.Box."+" (Par_W));
      Compare_Margins ("hover");
   end Test_Pipeline_Agreement;

begin
   Start_Suite ("Auto Margin Test");

   Test_Parser_Accepts_Auto;
   Test_Auto_Is_Rejected_Off_Margins;
   Test_Both_Auto_Centres;
   Test_Odd_Leftover_Is_Not_Snapped;
   Test_One_Auto_Absorbs_The_Leftover;
   Test_Auto_Width_Collapses_Auto_Margins;
   Test_Over_Constrained_Adjusts_The_Right_Margin;
   Test_Vertical_Autos_Are_Zero;
   Test_Centring_Respects_Padding;
   Test_Flex_Treats_Auto_As_Zero;
   Test_Pipeline_Agreement;

   Finish;
end Auto_Margin_Test;
