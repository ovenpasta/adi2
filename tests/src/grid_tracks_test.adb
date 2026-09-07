pragma Ada_2022;

with Ada.Text_IO;       use Ada.Text_IO;
with Adi.CSS_Source;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;    use Adi.Widget.Box;
with Grid_Tracks_Styles;
with Test_Support;      use Test_Support;

--  `none` is the initial value of grid-template-columns, and the track
--  list it names has to travel the cascade as a value rather than as an
--  absence: a rule naming it over a rule naming three tracks leaves the
--  grid with none. The count beside the list says the same thing, so
--  every case below reads both.
--
--  grid-template-rows carries a count alone, which is the same cascade
--  through one ordinary optional, and is checked here beside the pair.

procedure Grid_Tracks_Test is

   function Image (T : Grid_Track_Spec) return String is
     (T.Kind'Image & T.Value'Image);

   procedure Put_Tracks (L : Grid_Track_List) is
   begin
      Put ("      got" & L.Count'Image & " tracks:");
      for I in 1 .. L.Count loop
         Put (" " & Image (L.Tracks (I)));
      end loop;
      New_Line;
   end Put_Tracks;

   --  The count and the list are two values of one property, so a case
   --  that moved one and not the other is a failure however the other
   --  reads. Every expectation below names both.
   procedure Assert_Columns
     (R : Resolved_Style; Count : Natural; Msg : String)
   is
      OK : constant Boolean :=
        Natural (R.Grid_Columns) = Count
        and then R.Grid_Column_Tracks.Count = Count;
   begin
      Assert (OK, Msg);
      if not OK then
         Put_Line ("      want" & Count'Image & " columns and as many"
                   & " tracks");
         Put_Line ("      got " & R.Grid_Columns'Image & " columns");
         Put_Tracks (R.Grid_Column_Tracks);
      end if;
   end Assert_Columns;

   procedure Assert_Track
     (R     : Resolved_Style;
      I     : Positive;
      Kind  : Grid_Track_Kind;
      Value : Float;
      Msg   : String)
   is
      OK : constant Boolean :=
        R.Grid_Column_Tracks.Count >= I
        and then R.Grid_Column_Tracks.Tracks (I).Kind = Kind
        and then abs (R.Grid_Column_Tracks.Tracks (I).Value - Value) < 0.001;
   begin
      Assert (OK, Msg);
      if not OK then
         Put_Line ("      want track" & I'Image & " as "
                   & Kind'Image & Value'Image);
         Put_Tracks (R.Grid_Column_Tracks);
      end if;
   end Assert_Track;

   procedure Assert_Rows (R : Resolved_Style; Count : Natural; Msg : String) is
      OK : constant Boolean := Natural (R.Grid_Rows) = Count;
   begin
      Assert (OK, Msg);
      if not OK then
         Put_Line ("      want" & Count'Image & " rows, got"
                   & R.Grid_Rows'Image);
      end if;
   end Assert_Rows;

   ---------------------------------------------------------------------
   --  The cascade between selectors
   ---------------------------------------------------------------------

   --  Two class selectors of equal specificity, merged in the order the
   --  widget names them, which is the modifier pattern: a base class
   --  laying out a grid and a class taking the template off it.
   procedure Test_Cross_Selector_Cascade is
      Source : Adi.CSS_Source.Style_Source;
      Ok     : Boolean := False;

      Sheet_Text : constant String :=
        ".grid { grid-template-columns: 1fr 2fr 1fr; }" & ASCII.LF &
        ".plain { grid-template-columns: none; }" & ASCII.LF &
        ".narrow { grid-template-columns: 60px 40px; }" & ASCII.LF;

      function Bound (Classes : String) return Resolved_Style is
         W : constant Box_Handle := Create_Handle;
      begin
         Adi.CSS_Source.Bind_Class (Source, Classes, +W);
         return Get_Resolved_Part_Style (+W, Main_Part);
      end Bound;
   begin
      Section ("none across selectors");

      Adi.CSS_Source.Add_Dynamic_String (Source, Sheet_Text, Ok);
      Assert (Ok, "the cascade stylesheet parses");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the cascade stylesheet installs");

      Assert_Columns (Bound ("grid"), 3,
                      "a track list names its tracks");

      Assert_Columns (Bound ("grid plain"), 0,
                      "and a later rule naming none takes them away");

      Assert_Columns (Bound ("plain grid"), 3,
                      "a track list after none names them again");

      declare
         R : constant Resolved_Style := Bound ("plain narrow");
      begin
         Assert_Columns (R, 2, "none in the base leaves the override's"
                         & " track list standing");
         Assert_Track (R, 1, Track_Px, 60.0, "with the first track it named");
         Assert_Track (R, 2, Track_Px, 40.0, "and the second");
      end;

      Assert_Columns (Bound ("plain"), 0,
                      "none with nothing before it leaves no track");
   end Test_Cross_Selector_Cascade;

   --  The same three orders inside one rule, where the last declaration
   --  wins outright.
   procedure Test_Within_One_Rule is
      Source : Adi.CSS_Source.Style_Source;
      Ok     : Boolean := False;

      Sheet_Text : constant String :=
        ".last-wins { grid-template-columns: 1fr 2fr;"
        & " grid-template-columns: none; }" & ASCII.LF
        & ".list-after-none { grid-template-columns: none;"
        & " grid-template-columns: 60px 40px; }" & ASCII.LF;

      function Bound (Classes : String) return Resolved_Style is
         W : constant Box_Handle := Create_Handle;
      begin
         Adi.CSS_Source.Bind_Class (Source, Classes, +W);
         return Get_Resolved_Part_Style (+W, Main_Part);
      end Bound;
   begin
      Section ("none beside a track list in one rule");

      Adi.CSS_Source.Add_Dynamic_String (Source, Sheet_Text, Ok);
      Assert (Ok, "the one-rule stylesheet parses");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the one-rule stylesheet installs");

      Assert_Columns (Bound ("last-wins"), 0,
                      "none after a track list in the same rule wins");

      declare
         R : constant Resolved_Style := Bound ("list-after-none");
      begin
         Assert_Columns (R, 2, "and a track list after none wins");
         Assert_Track (R, 1, Track_Px, 60.0, "with the tracks it named");
         Assert_Track (R, 2, Track_Px, 40.0, "both of them");
      end;
   end Test_Within_One_Rule;

   --  grid-template-rows carries a count and no list, so its none is one
   --  optional taking the value zero. The cascade reads the same.
   procedure Test_Rows is
      Source : Adi.CSS_Source.Style_Source;
      Ok     : Boolean := False;

      Sheet_Text : constant String :=
        ".rows { grid-template-rows: 3; }" & ASCII.LF &
        ".no-rows { grid-template-rows: none; }" & ASCII.LF;

      function Bound (Classes : String) return Resolved_Style is
         W : constant Box_Handle := Create_Handle;
      begin
         Adi.CSS_Source.Bind_Class (Source, Classes, +W);
         return Get_Resolved_Part_Style (+W, Main_Part);
      end Bound;
   begin
      Section ("grid-template-rows: none");

      Adi.CSS_Source.Add_Dynamic_String (Source, Sheet_Text, Ok);
      Assert (Ok, "the rows stylesheet parses");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the rows stylesheet installs");

      Assert_Rows (Bound ("rows"), 3, "a row count names its rows");
      Assert_Rows (Bound ("rows no-rows"), 0,
                   "and a later rule naming none takes them away");
      Assert_Rows (Bound ("no-rows rows"), 3,
                   "a row count after none names them again");
      Assert_Rows (Bound ("no-rows"), 0,
                   "none with nothing before it leaves no row");
   end Test_Rows;

   ---------------------------------------------------------------------
   --  The two pipelines over one corpus
   ---------------------------------------------------------------------

   --  tools/css_to_ada.py compiles at build time and Adi.CSS_Parser reads at run time, so the two are driven from one file: tests/generated/grid_tracks_styles.ads is generated from tests/css/grid_tracks.css.
   Corpus_Path : constant String := "tests/css/grid_tracks.css";

   procedure Test_Pipeline_Agreement is
      Generated : Adi.CSS_Source.Style_Source;
      Parsed    : Adi.CSS_Source.Style_Source;
      Ok        : Boolean := False;

      function Bound (Source     : in out Adi.CSS_Source.Style_Source;
                      Tag_Name   : String := "";
                      Class_Name : String := "";
                      Id_Name    : String := "") return Resolved_Style
      is
         W : constant Box_Handle := Create_Handle;
      begin
         Adi.CSS_Source.Bind_Selector_Set
           (Source     => Source,
            W          => +W,
            Tag_Name   => Tag_Name,
            Class_Name => Class_Name,
            Id_Name    => Id_Name);
         return Get_Resolved_Part_Style (+W, Main_Part);
      end Bound;

      --  Agreement alone would pass with both pipelines wrong the same
      --  way, so each case is spelled out as well as compared.
      procedure Case_Of (Label      : String;
                         Columns    : Natural;
                         Tag_Name   : String := "";
                         Class_Name : String := "";
                         Id_Name    : String := "")
      is
         G : constant Resolved_Style :=
           Bound (Generated, Tag_Name, Class_Name, Id_Name);
         P : constant Resolved_Style :=
           Bound (Parsed, Tag_Name, Class_Name, Id_Name);
      begin
         Assert_Columns (G, Columns, Label & ": the generated sheet");
         Assert_Columns (P, Columns, Label & ": the parsed sheet");
         Assert (G.Grid_Column_Tracks = P.Grid_Column_Tracks,
                 Label & ": the track lists agree between the pipelines");
         Assert (G.Grid_Columns = P.Grid_Columns,
                 Label & ": the column counts agree between the pipelines");
         Assert (G.Grid_Rows = P.Grid_Rows,
                 Label & ": the row counts agree between the pipelines");
      end Case_Of;
   begin
      Section ("generated and parsed pipelines agree");

      Grid_Tracks_Styles.Register_Selectors (Generated);
      Adi.CSS_Source.Set_Mode (Generated, Adi.CSS_Source.Static_Mode, Ok);
      Assert (Ok, "the generated stylesheet installs");

      Adi.CSS_Source.Add_Dynamic_File (Parsed, Corpus_Path, Ok);
      Assert (Ok, "the corpus file is readable from the repository root");
      Adi.CSS_Source.Set_Mode (Parsed, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the parsed stylesheet installs");

      Case_Of ("the tag alone", 3, Tag_Name => "box");
      Case_Of ("a class naming none over it", 0,
               Tag_Name => "box", Class_Name => "plain");
      Case_Of ("a class naming a list over none", 2,
               Tag_Name => "box", Class_Name => "plain wide");
      Case_Of ("a class naming none over a list", 0,
               Tag_Name => "box", Class_Name => "wide plain");
      Case_Of ("an id naming none over a class", 0,
               Tag_Name => "box", Class_Name => "wide", Id_Name => "pin");
      Case_Of ("none last in one rule", 0, Class_Name => "last-wins");
      Case_Of ("a list last in one rule", 2, Class_Name => "list-after-none");

      --  A refused track list is no value at all, so the class carries
      --  nothing and the tag's tracks stand. A pipeline counting the
      --  tokens instead would answer two columns here.
      Case_Of ("a class naming a token neither reads", 3,
               Tag_Name => "box", Class_Name => "bad-tracks");

      declare
         Rows : constant Resolved_Style :=
           Bound (Parsed, Tag_Name => "box", Class_Name => "plain");
         Gen  : constant Resolved_Style :=
           Bound (Generated, Tag_Name => "box", Class_Name => "plain");
      begin
         Assert_Rows (Rows, 0, "the class takes the rows off the tag too");
         Assert_Rows (Gen, 0, "in the generated sheet as well");
      end;

      declare
         Rows : constant Resolved_Style :=
           Bound (Parsed, Tag_Name => "box", Class_Name => "bad-tracks");
         Gen  : constant Resolved_Style :=
           Bound (Generated, Tag_Name => "box", Class_Name => "bad-tracks");
      begin
         Assert_Rows (Rows, 3, "a refused row count leaves the tag's rows");
         Assert_Rows (Gen, 3, "in the generated sheet as well");
      end;
   end Test_Pipeline_Agreement;

begin
   Start_Suite ("Grid track cascade test");

   Test_Cross_Selector_Cascade;
   Test_Within_One_Rule;
   Test_Rows;
   Test_Pipeline_Agreement;

   Finish;
end Grid_Tracks_Test;
