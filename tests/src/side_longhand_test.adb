pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Side_Cascade_Styles;
with Test_Support; use Test_Support;

procedure Side_Longhand_Test is

   --  Expand each resolved group to four values so an assertion names a
   --  side rather than a representation.

   function Sides_Of (B : CSS_Box_Value) return CSS_Box_Sides is
     (case B.Kind is
        when Gap_Uniform => [others => B.All_Sides],
        when Axis        => [Top | Bottom => B.Vertical,
                             Left | Right => B.Horizontal],
        when Per_Side    => B.Sides);

   function Edges_Of (B : Border_Width_Value) return Edge_Lengths is
     (case B.Kind is
        when Gap_Uniform => [others => B.All_Edges],
        when Per_Edge    => B.Edges);

   function Edges_Of (B : Border_Color_Value) return Edge_Colors is
     (case B.Kind is
        when Gap_Uniform => [others => B.All_Edges],
        when Per_Edge    => B.Edges);

   function Edges_Of (B : Border_Style_Value) return Edge_Styles is
     (case B.Kind is
        when Gap_Uniform => [others => B.All_Edges],
        when Per_Edge    => B.Edges);

   function Corners_Of (R : Border_Radius_Value) return Corner_Radii is
     (case R.Kind is
        when Gap_Uniform => [others => R.All_Corners],
        when Per_Corner  => R.Corners);

   function Image (L : Length_Value) return String is
     (L.Amount'Image & " " & L.Unit'Image);

   procedure Assert_Lengths
     (Actual     : CSS_Box_Sides;
      T, R, B, L : Float;
      Msg        : String)
   is
      Want : constant CSS_Box_Sides := [Px (T), Px (R), Px (B), Px (L)];
      OK   : constant Boolean := Actual = Want;
   begin
      Assert (OK, Msg);
      if not OK then
         Put_Line ("      want" & Image (Want (Top)) & " /" & Image (Want (Right))
                   & " /" & Image (Want (Bottom)) & " /" & Image (Want (Left)));
         Put_Line ("      got " & Image (Actual (Top)) & " /" & Image (Actual (Right))
                   & " /" & Image (Actual (Bottom)) & " /" & Image (Actual (Left)));
      end if;
   end Assert_Lengths;

   procedure Assert_Box (Actual : CSS_Box_Value; T, R, B, L : Float; Msg : String) is
   begin
      Assert_Lengths (Sides_Of (Actual), T, R, B, L, Msg);
   end Assert_Box;

   --  Every case here declares lengths, so an auto side is a failure
   --  rather than a zero: reading it as one would let an expected 0.0
   --  pass against a margin that had turned auto.
   procedure Assert_Margin
     (Actual : Margin_Sides; T, R, B, L : Float; Msg : String)
   is
   begin
      for E in Edge loop
         if Actual (E).Kind /= Fixed then
            Assert (False, Msg);
            Put_Line ("      " & E'Image & " resolved to auto");
            return;
         end if;
      end loop;
      Assert_Lengths
        ([for E in Edge => Actual (E).Length], T, R, B, L, Msg);
   end Assert_Margin;

   procedure Assert_Border_Width
     (Actual : Border_Width_Value; T, R, B, L : Float; Msg : String)
   is
      E : constant Edge_Lengths := Edges_Of (Actual);
   begin
      Assert_Lengths ([E (Top), E (Right), E (Bottom), E (Left)], T, R, B, L, Msg);
   end Assert_Border_Width;

   procedure Assert_Radius
     (Actual : Border_Radius_Value; TL, TR, BR, BL : Float; Msg : String)
   is
      C    : constant Corner_Radii := Corners_Of (Actual);
      Want : constant Corner_Radii := [Px (TL), Px (TR), Px (BR), Px (BL)];
      OK   : constant Boolean := C = Want;
   begin
      Assert (OK, Msg);
      if not OK then
         Put_Line ("      got " & Image (C (Top_Left)) & " /" & Image (C (Top_Right))
                   & " /" & Image (C (Bottom_Right)) & " /" & Image (C (Bottom_Left)));
      end if;
   end Assert_Radius;

   function Is_RGB (Col : Color_Value; R, G, B : Natural) return Boolean is
     (Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B);

   Sheet : Adi.CSS_Parser.Stylesheet;
   OK    : Boolean := False;

   --  Every case below spreads a group over two rules, which is the only
   --  place the defect showed: one rule naming a side used to discard the
   --  three the earlier rule set.
   CSS : constant String :=
     ".pad-a { padding: 12px; }" & ASCII.LF &
     ".pad-a { padding-top: 4px; }" & ASCII.LF &
     ".pad-b { padding-left: 9px; }" & ASCII.LF &
     ".pad-b { padding: 3px; }" & ASCII.LF &
     ".pad-c { padding: 12px; }" & ASCII.LF &
     ".pad-c:hover { padding-top: 4px; padding-right: 5px; }" & ASCII.LF &
     ".pad-d { padding-left: 7px; }" & ASCII.LF &
     ".pad-e { padding: 12px; }" & ASCII.LF &
     ".pad-e { padding-top: 0px; }" & ASCII.LF &
     ".mar-a { margin: 6px 8px; }" & ASCII.LF &
     ".mar-a { margin-bottom: 1px; }" & ASCII.LF &
     ".bw-a { border-width: 2px; }" & ASCII.LF &
     ".bw-a { border-left-width: 5px; }" & ASCII.LF &
     ".bc-a { border-color: rgb(17, 34, 51); }" & ASCII.LF &
     ".bc-a { border-top-color: rgb(68, 85, 102); }" & ASCII.LF &
     ".bs-a { border-style: solid; }" & ASCII.LF &
     ".bs-a { border-right-style: dashed; }" & ASCII.LF &
     ".br-a { border-radius: 8px; }" & ASCII.LF &
     ".br-a { border-bottom-left-radius: 2px; }" & ASCII.LF &
     ".bx-a { border: 1px solid rgb(1, 2, 3); }" & ASCII.LF &
     ".bx-a { border-top: 4px dashed rgb(10, 11, 12); }" & ASCII.LF;

   function Resolved (Class : String;
                      States : Widget_States := No_States) return Resolved_Style
   is
      Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, Class);
   begin
      return Compute_Resolved (Styles (Main_Part).Style, States, No_States);
   end Resolved;

   procedure Test_Parser_Cascade is
   begin
      Section ("runtime parser: side longhands cascade");

      Assert_Box (Resolved ("pad-a").Padding, 4.0, 12.0, 12.0, 12.0,
                  "padding-top in a later rule keeps the other three sides");
      Assert_Box (Resolved ("pad-b").Padding, 3.0, 3.0, 3.0, 3.0,
                  "a later shorthand names all four sides");
      Assert_Box (Resolved ("pad-c").Padding, 12.0, 12.0, 12.0, 12.0,
                  "an unmatched state rule leaves the base padding alone");
      Assert_Box (Resolved ("pad-c", Single_State (State_Hovered)).Padding,
                  4.0, 5.0, 12.0, 12.0,
                  "a state rule naming two sides keeps the base's other two");
      Assert_Box (Resolved ("pad-d").Padding, 0.0, 0.0, 0.0, 7.0,
                  "a side never named resolves to zero");
      --  A declared zero and a side left alone both resolve to zero, so
      --  only the set/unset distinction tells them apart in the cascade.
      Assert_Box (Resolved ("pad-e").Padding, 0.0, 12.0, 12.0, 12.0,
                  "a longhand declaring zero overrides an earlier side");

      Assert_Margin (Resolved ("mar-a").Margin, 6.0, 8.0, 1.0, 8.0,
                     "margin-bottom keeps the axis shorthand's other sides");

      Assert_Border_Width (Resolved ("bw-a").Border_Width, 2.0, 2.0, 2.0, 5.0,
                           "border-left-width keeps the other three widths");

      declare
         C : constant Edge_Colors := Edges_Of (Resolved ("bc-a").Border_Color);
      begin
         Assert (Is_RGB (C (Top), 68, 85, 102)
                   and then Is_RGB (C (Right), 17, 34, 51)
                   and then Is_RGB (C (Bottom), 17, 34, 51)
                   and then Is_RGB (C (Left), 17, 34, 51),
                 "border-top-color keeps the other three colours");
      end;

      declare
         S : constant Edge_Styles := Edges_Of (Resolved ("bs-a").Border_Style);
      begin
         Assert (S (Top) = Solid and then S (Right) = Dashed
                   and then S (Bottom) = Solid and then S (Left) = Solid,
                 "border-right-style keeps the other three styles");
      end;

      Assert_Radius (Resolved ("br-a").Border_Radius, 8.0, 8.0, 8.0, 2.0,
                     "one corner radius keeps the other three corners");

      declare
         R : constant Resolved_Style := Resolved ("bx-a");
         W : constant Edge_Lengths := Edges_Of (R.Border_Width);
         S : constant Edge_Styles  := Edges_Of (R.Border_Style);
         C : constant Edge_Colors  := Edges_Of (R.Border_Color);
      begin
         Assert (W (Top) = Px (4.0) and then W (Right) = Px (1.0)
                   and then W (Bottom) = Px (1.0) and then W (Left) = Px (1.0),
                 "border-top shorthand keeps the other three widths");
         Assert (S (Top) = Dashed and then S (Right) = Solid
                   and then S (Bottom) = Solid and then S (Left) = Solid,
                 "border-top shorthand keeps the other three styles");
         Assert (Is_RGB (C (Top), 10, 11, 12)
                   and then Is_RGB (C (Right), 1, 2, 3)
                   and then Is_RGB (C (Bottom), 1, 2, 3)
                   and then Is_RGB (C (Left), 1, 2, 3),
                 "border-top shorthand keeps the other three colours");
      end;
   end Test_Parser_Cascade;

   --  The modifier pattern: a base class plus a class that adjusts one
   --  edge. Two selectors, so the merge happens between whole rule sets.
   procedure Test_Class_Modifier is
      Source : Adi.CSS_Source.Style_Source;
      W      : constant Box_Handle := Create_Handle;
      Ok2    : Boolean := False;
      Sheet_Text : constant String :=
        ".card { padding: 12px; margin: 6px; }" & ASCII.LF &
        ".card-tight { padding-top: 4px; margin-left: 2px; }" & ASCII.LF;
   begin
      Section ("cross-selector cascade");

      Adi.CSS_Source.Add_Dynamic_String (Source, Sheet_Text, Ok2);
      Assert (Ok2, "modifier stylesheet should parse");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Ok2);
      Assert (Ok2, "modifier stylesheet should install");

      Adi.CSS_Source.Bind_Class (Source, "card card-tight", +W);

      declare
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert_Box (R.Padding, 4.0, 12.0, 12.0, 12.0,
                     "a modifier class adjusts one padding side only");
         Assert_Margin (R.Margin, 6.0, 6.0, 6.0, 2.0,
                        "a modifier class adjusts one margin side only");
      end;
   end Test_Class_Modifier;

   --  A more specific selector naming one side must not flatten the less
   --  specific one's other three.
   procedure Test_Specificity is
      Source : Adi.CSS_Source.Style_Source;
      W      : constant Box_Handle := Create_Handle;
      Ok2    : Boolean := False;
      Sheet_Text : constant String :=
        "box { padding: 20px; }" & ASCII.LF &
        ".spec { padding-right: 6px; }" & ASCII.LF &
        "#spec-id { padding-top: 1px; }" & ASCII.LF;
   begin
      Section ("specificity");

      Adi.CSS_Source.Add_Dynamic_String (Source, Sheet_Text, Ok2);
      Assert (Ok2, "specificity stylesheet should parse");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Ok2);
      Assert (Ok2, "specificity stylesheet should install");

      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +W,
         Tag_Name   => "box",
         Class_Name => "spec",
         Id_Name    => "spec-id");

      declare
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert_Box (R.Padding, 1.0, 6.0, 20.0, 20.0,
                     "tag, class and id each contribute the side they name");
      end;
   end Test_Specificity;

   --  tools/css_to_ada.py merges at build time and Adi.CSS_Parser at run
   --  time. A stylesheet that resolves differently depending on which
   --  loaded it is the failure this section exists to catch, so the two
   --  are driven from one file: tests/generated/side_cascade_styles.ads
   --  is generated from tests/css/side_cascade.css, which is also what
   --  the dynamic source reads.
   Corpus_Path : constant String := "tests/css/side_cascade.css";

   procedure Test_Pipeline_Agreement is
      Generated : Adi.CSS_Source.Style_Source;
      Parsed    : Adi.CSS_Source.Style_Source;
      Gen_W     : constant Box_Handle := Create_Handle;
      Par_W     : constant Box_Handle := Create_Handle;
      Ok2       : Boolean := False;

      procedure Bind (Source : in out Adi.CSS_Source.Style_Source;
                      W      : Box_Handle) is
      begin
         Adi.CSS_Source.Bind_Selector_Set
           (Source     => Source,
            W          => +W,
            Tag_Name   => "box",
            Class_Name => "tweak",
            Id_Name    => "pin");
      end Bind;

      procedure Compare (Label : String) is
         G : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Gen_W, Main_Part);
         P : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
      begin
         Assert (Sides_Of (G.Padding) = Sides_Of (P.Padding),
                 Label & ": padding agrees between the two pipelines");
         Assert (G.Margin = P.Margin,
                 Label & ": margin agrees between the two pipelines");
         Assert (Edges_Of (G.Border_Width) = Edges_Of (P.Border_Width),
                 Label & ": border-width agrees between the two pipelines");
         Assert (Edges_Of (G.Border_Color) = Edges_Of (P.Border_Color),
                 Label & ": border-color agrees between the two pipelines");
         Assert (Edges_Of (G.Border_Style) = Edges_Of (P.Border_Style),
                 Label & ": border-style agrees between the two pipelines");
         Assert (Corners_Of (G.Border_Radius) = Corners_Of (P.Border_Radius),
                 Label & ": border-radius agrees between the two pipelines");
      end Compare;

      --  Agreement alone would pass with both pipelines wrong the same
      --  way, so the cascade is spelled out here too.
      procedure Expect_Base is
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
         C : constant Edge_Colors := Edges_Of (R.Border_Color);
         S : constant Edge_Styles := Edges_Of (R.Border_Style);
      begin
         Assert_Box (R.Padding, 4.0, 3.0, 12.0, 12.0,
                     "tag, class and id each land on the side they name");
         Assert_Margin (R.Margin, 6.0, 8.0, 1.0, 8.0,
                        "the class adjusts the bottom margin only");
         Assert_Border_Width (R.Border_Width, 7.0, 2.0, 2.0, 5.0,
                              "border widths come from three selectors");
         Assert_Radius (R.Border_Radius, 8.0, 8.0, 8.0, 2.0,
                        "one corner comes from the class");
         Assert (Is_RGB (C (Top), 9, 9, 9)
                   and then Is_RGB (C (Right), 17, 34, 51)
                   and then Is_RGB (C (Bottom), 17, 34, 51)
                   and then Is_RGB (C (Left), 17, 34, 51),
                 "the id's border-top wins the top colour");
         Assert (S (Top) = Dotted and then S (Right) = Dashed
                   and then S (Bottom) = Solid and then S (Left) = Solid,
                 "border styles come from three selectors");
      end Expect_Base;

      procedure Expect_Hovered is
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
      begin
         Assert_Box (R.Padding, 4.0, 3.0, 15.0, 12.0,
                     "the hover rule adds a side without dropping the rest");
         Assert_Margin (R.Margin, 6.0, 8.0, 1.0, 9.0,
                        "the hover rule's margin side stacks on the base's");
      end Expect_Hovered;

   begin
      Section ("generated and parsed pipelines agree");

      Side_Cascade_Styles.Register_Selectors (Generated);
      Adi.CSS_Source.Set_Mode
        (Generated, Adi.CSS_Source.Static_Mode, Ok2);
      Assert (Ok2, "generated stylesheet should install");

      Adi.CSS_Source.Add_Dynamic_File (Parsed, Corpus_Path, Ok2);
      Assert (Ok2, "corpus file should be readable from the repository root");
      Adi.CSS_Source.Set_Mode (Parsed, Adi.CSS_Source.Dynamic_Mode, Ok2);
      Assert (Ok2, "parsed stylesheet should install");

      Bind (Generated, Gen_W);
      Bind (Parsed, Par_W);

      Compare ("base");
      Expect_Base;

      Set_Hovered (+Gen_W);
      Set_Hovered (+Par_W);

      Compare ("hover");
      Expect_Hovered;
   end Test_Pipeline_Agreement;

begin
   Start_Suite ("Side longhand cascade test");

   Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
   Assert (OK, "corpus stylesheet should parse");

   Test_Parser_Cascade;
   Test_Class_Modifier;
   Test_Specificity;
   Test_Pipeline_Agreement;

   Finish;
end Side_Longhand_Test;
