pragma Ada_2022;

with Adi.Core;         use Adi.Core;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Layout_Util;  use Adi.Layout_Util;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget.Box;   use Adi.Widget.Box;
with CSS_Wide_Keywords_Styles;
with Test_Support;     use Test_Support;

--  The CSS-wide keywords through both pipelines. tools/css_to_ada.py
--  merges at build time and Adi.CSS_Parser at run time, so the two are
--  driven from one file: tests/generated/css_wide_keywords_styles.ads
--  is generated from tests/css/css_wide_keywords.css, which is also
--  what the dynamic source reads.
--
--  What the sheet is written to show is that `initial` is a value in
--  the cascade rather than an absence: the tag rule sets every property
--  the class rule clears, so a pipeline that dropped the declaration
--  instead of clearing the property would answer with the tag's value
--  and fail here.
procedure CSS_Wide_Test is

   Corpus_Path : constant String := "tests/css/css_wide_keywords.css";

   function Nearly (A, B : Float) return Boolean is
     (abs (A - B) <= 0.0001);

   Generated : Adi.CSS_Source.Style_Source;
   Parsed    : Adi.CSS_Source.Style_Source;
   Gen_W     : constant Box_Handle := Create_Handle;
   Par_W     : constant Box_Handle := Create_Handle;
   OK        : Boolean := False;

   procedure Bind (Source : in out Adi.CSS_Source.Style_Source;
                   W      : Box_Handle) is
   begin
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +W,
         Tag_Name   => "box",
         Class_Name => "wide",
         Id_Name    => "pin");
   end Bind;

   procedure Test_Both_Pipelines_Agree is
      G : constant Resolved_Style :=
        Get_Resolved_Part_Style (+Gen_W, Main_Part);
      P : constant Resolved_Style :=
        Get_Resolved_Part_Style (+Par_W, Main_Part);
   begin
      Section ("the generated and the parsed sheet answer alike");

      Assert (G.Color = P.Color, "colour agrees");
      Assert (G.Font_Size = P.Font_Size, "font-size agrees");
      Assert (G.Display = P.Display, "display agrees");
      Assert (G.Opacity = P.Opacity, "opacity agrees");
      Assert (G.White_Space = P.White_Space, "white-space agrees");
      Assert (G.Overflow_X = P.Overflow_X and then G.Overflow_Y = P.Overflow_Y,
              "both overflow axes agree");
      Assert (G.Outline_Width = P.Outline_Width
                and then G.Outline_Color = P.Outline_Color
                and then G.Outline_Style = P.Outline_Style,
              "the outline shorthand's three properties agree");
      Assert (G.Grid_Columns = P.Grid_Columns
                and then G.Grid_Column_Tracks = P.Grid_Column_Tracks,
              "the grid column count and track list agree");
      Assert (Get_Padding_Px (G) = Get_Padding_Px (P), "padding agrees");
      Assert (Get_Margin_Px (G) = Get_Margin_Px (P), "margin agrees");
      Assert (Get_Border_Width_Px (G) = Get_Border_Width_Px (P),
              "border-width agrees");
      Assert (Get_Border_Radius_Px (G.Border_Radius)
                = Get_Border_Radius_Px (P.Border_Radius),
              "border-radius agrees");
      Assert (Get_Row_Gap (G.Gap) = Get_Row_Gap (P.Gap)
                and then Get_Column_Gap (G.Gap) = Get_Column_Gap (P.Gap),
              "both gap axes agree");
      Assert (G.List_Style_Type = P.List_Style_Type
                and then G.List_Style_Image = P.List_Style_Image
                and then G.List_Style_Position = P.List_Style_Position,
              "the list-style shorthand's three properties agree");
   end Test_Both_Pipelines_Agree;

   --  Agreement alone would pass with both pipelines wrong the same
   --  way, so the cascade is spelled out too.
   procedure Test_The_Cascade is
      R   : constant Resolved_Style :=
        Get_Resolved_Part_Style (+Par_W, Main_Part);
      Pad : constant Edge_Pixels := Get_Padding_Px (R);
      Mar : constant Edge_Pixels := Get_Margin_Px (R);
      BW  : constant Edge_Pixels := Get_Border_Width_Px (R);
      Rad : constant Corner_Pixels := Get_Border_Radius_Px (R.Border_Radius);
   begin
      Section ("what each keyword leaves the widget with");

      Assert (R.Color = Default_Color,
              "color: initial takes the colour off the tag rule");
      Assert (R.Font_Size = Default_Font_Size, "and font-size off it");
      Assert (R.Display = Default_Display, "and display off it");
      Assert (Nearly (Float (R.Opacity), Float (Default_Opacity)),
              "opacity: unset does the same, the property not inheriting");
      Assert (R.Overflow_X = Default_Overflow
                and then R.Overflow_Y = Default_Overflow,
              "overflow: initial reaches both axes");
      Assert (R.Outline_Width = Default_Outline_Width
                and then R.Outline_Color = Default_Outline_Color
                and then R.Outline_Style = Default_Outline_Style,
              "and a shorthand every property it fills");
      Assert (R.Grid_Column_Tracks.Count = 0,
              "grid-template-columns: initial clears the track list");
      Assert (R.Grid_Columns = Default_Grid_Columns,
              "and takes the count to the property's default");

      Assert (Nearly (Float (Pad.Top), 0.0)
                and then Nearly (Float (Pad.Left), 9.0),
              "padding-top: initial clears its edge and leaves the rest");
      Assert (Nearly (Float (Pad.Right), 9.0),
              "padding-right: inherit is dropped, so the tag's edge stands");
      Assert (Nearly (Float (Mar.Left), 0.0)
                and then Nearly (Float (Mar.Right), 8.0),
              "margin-left: initial clears its side alone");
      Assert (Nearly (Float (BW.Top), 0.0)
                and then Nearly (Float (BW.Left), 7.0),
              "border-top-width: initial clears its edge alone");
      Assert (Nearly (Rad.Top_Left, 0.0)
                and then Nearly (Rad.Bottom_Right, 5.0),
              "border-top-left-radius: initial clears its corner alone");
      Assert (Nearly (Float (Get_Row_Gap (R.Gap)), 0.0)
                and then Nearly (Float (Get_Column_Gap (R.Gap)), 11.0),
              "row-gap: initial leaves the column gap the tag rule set");

      Assert (R.List_Style_Type = Default_List_Style_Type
                and then R.List_Style_Position = Default_List_Style_Position,
              "list-style: initial clears every property it fills");
      Assert (R.White_Space = WS_Pre,
              "white-space: unset is inherit here, so it is dropped and the"
              & " tag's value stands");
      Assert (R.Min_Width.Kind = Fixed
                and then Nearly (R.Min_Width.Size.Amount, 40.0),
              "and the declaration beside the two refused ones applies");
   end Test_The_Cascade;

begin
   Start_Suite ("CSS-wide keyword test");

   CSS_Wide_Keywords_Styles.Register_Selectors (Generated);
   Adi.CSS_Source.Set_Mode (Generated, Adi.CSS_Source.Static_Mode, OK);
   Assert (OK, "the generated stylesheet installs");

   Adi.CSS_Source.Add_Dynamic_File (Parsed, Corpus_Path, OK);
   Assert (OK, "the corpus file is readable from the repository root");
   Adi.CSS_Source.Set_Mode (Parsed, Adi.CSS_Source.Dynamic_Mode, OK);
   Assert (OK, "the parsed stylesheet installs");

   Bind (Generated, Gen_W);
   Bind (Parsed, Par_W);

   Test_Both_Pipelines_Agree;
   Test_The_Cascade;

   Finish;
end CSS_Wide_Test;
