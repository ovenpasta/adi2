pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;           use Ada.Text_IO;

with Adi.CSS_Parser;
with Adi.CSS_Parser.Testing;
with Adi.CSS_Source;
with Adi.CSS_Source.Testing;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Widget;            use Adi.Widget;
with Adi.Widget.Box;        use Adi.Widget.Box;
with Adi.Widget_Styles;     use Adi.Widget_Styles;
with Test_Properties;
pragma Unreferenced (Test_Properties);
with Test_Support;          use Test_Support;

--  The selector index and the (tag, classes, id) memo, each held to the
--  computation it stands in for. Agreement is the whole property: a
--  lookup answers what a scan of every selector answered, and a memo hit
--  answers what the fold answers when it is run again.
procedure Selector_Lookup_Test is

   package Char renames Ada.Characters.Handling;
   use type Adi.CSS_Parser.Selector_Kind;

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True),
       others    => <>]);

   function Bg (R, G, B : Natural) return Part_Style_Array is
     (Main_Styles ((Background_Color => Set_Bg (RGB (R, G, B)),
                    others           => <>)));

   function Is_RGB (Col : Color_Value; R, G, B : Natural) return Boolean is
     (Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B);

   --  Names no sheet in the repository declares, so the two lookups have
   --  to agree on absence as well as on presence.
   Absent : constant array (1 .. 5) of Unbounded_String :=
     [To_Unbounded_String ("zz-no-such-selector"),
      To_Unbounded_String ("zz-no-such-selector-2"),
      To_Unbounded_String (""),
      To_Unbounded_String ("   "),
      To_Unbounded_String ("Zz-Mixed-Case-Absent")];

   Sheets_Checked    : Natural := 0;
   Selectors_Checked : Natural := 0;

   --  tests/css/widget_property_static.css names a property declared
   --  with Dynamic_Lookup => False, which the runtime parser is meant to
   --  reject: it has no name to resolve. Every other sheet must parse,
   --  and one that stops parsing is a finding rather than a skip.
   function Runtime_Parseable (Path : String) return Boolean is
     (Ada.Directories.Simple_Name (Path) /= "widget_property_static.css");

   ------------------------------------------------------------------
   --  Part A: the selector index answers what the scan answered
   ------------------------------------------------------------------

   procedure Check_Sheet (Path : String) is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;

      procedure Both_Ways (Kind : Adi.CSS_Parser.Selector_Kind;
                           Name : String;
                           Note : String)
      is
         Indexed : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For (Sheet, Kind, Name);
         Scanned : constant Part_Style_Array :=
           Adi.CSS_Parser.Testing.Styles_For_Scanned (Sheet, Kind, Name);
      begin
         Assert (Indexed = Scanned,
                 Path & ": " & Note & " " & Kind'Image & " '" & Name
                 & "' answers the same either way");
      end Both_Ways;
   begin
      Adi.CSS_Parser.Load_File (Sheet, Path, OK);
      if not Runtime_Parseable (Path) then
         Assert (not OK,
                 Path & " names a property the runtime cannot resolve");
         Adi.CSS_Parser.Destroy (Sheet);
         return;
      end if;

      Assert (OK, Path & " should parse");
      if not OK then
         Put_Line ("      " & Adi.CSS_Parser.Get_Last_Error (Sheet));
         return;
      end if;

      Sheets_Checked := Sheets_Checked + 1;

      for I in 1 .. Adi.CSS_Parser.Testing.Selector_Count (Sheet) loop
         declare
            K : constant Adi.CSS_Parser.Selector_Kind :=
              Adi.CSS_Parser.Testing.Selector_Kind_At (Sheet, I);
            N : constant String :=
              Adi.CSS_Parser.Testing.Selector_Name_At (Sheet, I);
         begin
            Selectors_Checked := Selectors_Checked + 1;

            --  A selector the sheet names is found, and carries styles.
            Both_Ways (K, N, "declared");
            Assert (Adi.CSS_Parser.Styles_For (Sheet, K, N)
                      /= Empty_Part_Styles,
                    Path & ": " & K'Image & " '" & N & "' carries styles");

            --  Lookups normalize, so these reach the same entry.
            Both_Ways (K, Char.To_Upper (N), "upper-cased");
            Both_Ways (K, "  " & N & "  ", "padded");
            Assert (Adi.CSS_Parser.Styles_For (Sheet, K, Char.To_Upper (N))
                      = Adi.CSS_Parser.Styles_For (Sheet, K, N),
                    Path & ": case does not change what '" & N
                    & "' answers");

            --  A name is registered under one kind, and answers under
            --  that one alone unless the sheet declares it twice.
            for K2 in Adi.CSS_Parser.Selector_Kind loop
               Both_Ways (K2, N, "cross-kind");
            end loop;
         end;
      end loop;

      for A of Absent loop
         for K in Adi.CSS_Parser.Selector_Kind loop
            Both_Ways (K, To_String (A), "absent");
         end loop;
      end loop;

      --  The same sheet loaded again over the top: the index is rebuilt
      --  with the selectors, so a reload answers as a first load does.
      Adi.CSS_Parser.Load_File (Sheet, Path, OK);
      Assert (OK, Path & " should parse a second time");

      for I in 1 .. Adi.CSS_Parser.Testing.Selector_Count (Sheet) loop
         Both_Ways (Adi.CSS_Parser.Testing.Selector_Kind_At (Sheet, I),
                    Adi.CSS_Parser.Testing.Selector_Name_At (Sheet, I),
                    "after reload");
      end loop;

      --  Now the static side, over the same selector set: what the
      --  index answers against the fold over every registered entry.
      declare
         Src : Adi.CSS_Source.Style_Source;
         Ok2 : Boolean := False;

         procedure Static_Both_Ways (Kind : Adi.CSS_Parser.Selector_Kind;
                                     Name : String)
         is
            Indexed : constant Part_Style_Array :=
              Adi.CSS_Source.Testing.Static_Styles_Indexed (Src, Kind, Name);
            Scanned : constant Part_Style_Array :=
              Adi.CSS_Source.Testing.Static_Styles_Scanned (Src, Kind, Name);
         begin
            Assert (Indexed = Scanned,
                    Path & ": static " & Kind'Image & " '" & Name
                    & "' answers the same either way");
         end Static_Both_Ways;
      begin
         for I in 1 .. Adi.CSS_Parser.Testing.Selector_Count (Sheet) loop
            declare
               K : constant Adi.CSS_Parser.Selector_Kind :=
                 Adi.CSS_Parser.Testing.Selector_Kind_At (Sheet, I);
               N : constant String :=
                 Adi.CSS_Parser.Testing.Selector_Name_At (Sheet, I);
               S : constant Part_Style_Array :=
                 Adi.CSS_Parser.Styles_For (Sheet, K, N);
            begin
               case K is
                  when Adi.CSS_Parser.Tag_Selector =>
                     Adi.CSS_Source.Add_Static_Entry
                       (Src, Adi.CSS_Source.Tag_Entry (N, S));
                  when Adi.CSS_Parser.Class_Selector =>
                     Adi.CSS_Source.Add_Static_Entry
                       (Src, Adi.CSS_Source.Class_Entry (N, S));
                  when Adi.CSS_Parser.Id_Selector =>
                     Adi.CSS_Source.Add_Static_Entry
                       (Src, Adi.CSS_Source.Id_Entry (N, S));
               end case;
            end;
         end loop;

         Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok2);
         Assert (Ok2, Path & ": static mode should install");

         for I in 1 .. Adi.CSS_Parser.Testing.Selector_Count (Sheet) loop
            declare
               K : constant Adi.CSS_Parser.Selector_Kind :=
                 Adi.CSS_Parser.Testing.Selector_Kind_At (Sheet, I);
               N : constant String :=
                 Adi.CSS_Parser.Testing.Selector_Name_At (Sheet, I);
            begin
               for K2 in Adi.CSS_Parser.Selector_Kind loop
                  Static_Both_Ways (K2, N);
               end loop;
               Static_Both_Ways (K, Char.To_Upper (N));
               Static_Both_Ways (K, "  " & N & "  ");
            end;
         end loop;

         for A of Absent loop
            for K in Adi.CSS_Parser.Selector_Kind loop
               Static_Both_Ways (K, To_String (A));
            end loop;
         end loop;

         Adi.CSS_Source.Destroy (Src);
      end;

      Adi.CSS_Parser.Destroy (Sheet);
   end Check_Sheet;

   procedure Check_Directory (Dir : String) is
      use Ada.Directories;
      Search : Ada.Directories.Search_Type;
      Item   : Directory_Entry_Type;
   begin
      Assert (Exists (Dir), Dir & " should be readable from the repo root");
      if not Exists (Dir) then
         return;
      end if;

      Start_Search (Search, Dir, "*.css",
                    Filter => [Ordinary_File => True, others => False]);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Item);
         Check_Sheet (Full_Name (Item));
      end loop;
      End_Search (Search);
   end Check_Directory;

   procedure Test_Corpus_Agreement is
   begin
      Section ("selector lookup agrees with a scan, over every sheet");
      Check_Directory ("examples/css");
      Check_Directory ("tests/css");
      Assert (Sheets_Checked >= 30,
              "the corpus should cover every sheet in the repository");
      Assert (Selectors_Checked > 300,
              "the corpus should cover a few hundred selectors");
      Put_Line ("      " & Sheets_Checked'Image & " sheets,"
                & Selectors_Checked'Image & " selectors");
   end Test_Corpus_Agreement;

   ------------------------------------------------------------------
   --  Part A: entries naming one selector twice still fold in order
   ------------------------------------------------------------------

   procedure Test_Repeated_Static_Entries is
      Src : Adi.CSS_Source.Style_Source;
      OK  : Boolean := False;
   begin
      Section ("repeated static entries fold in registration order");

      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry ("row", Bg (10, 20, 30)));
      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry
                ("row",
                 Main_Styles ((Padding => Set (CSS_Box (Px (4.0))),
                               others  => <>))));
      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry ("row", Bg (40, 50, 60)));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "static mode should install");

      Assert (Adi.CSS_Source.Testing.Static_Styles_Indexed
                (Src, Adi.CSS_Parser.Class_Selector, "row")
              = Adi.CSS_Source.Testing.Static_Styles_Scanned
                  (Src, Adi.CSS_Parser.Class_Selector, "row"),
              "three entries under one name fold to the same array");

      declare
         W : constant Box_Handle := Create_Handle;
      begin
         Adi.CSS_Source.Bind_Class (Src, "row", +W);
         declare
            R : constant Resolved_Style :=
              Get_Resolved_Part_Style (+W, Main_Part);
         begin
            Assert (Is_RGB (R.Background_Color, 40, 50, 60),
                    "the last entry registered wins the colour");
            Assert (R.Padding.Kind = Gap_Uniform
                      and then R.Padding.All_Sides.Amount = 4.0,
                    "an entry setting only padding keeps it");
         end;
         declare
            H : Widget_Handle := +W;
         begin
            Destroy (H);
         end;
      end;

      Adi.CSS_Source.Destroy (Src);
   end Test_Repeated_Static_Entries;

   ------------------------------------------------------------------
   --  Part B: a memo hit equals a fresh fold
   ------------------------------------------------------------------

   Triples : constant array (1 .. 9, 1 .. 3) of Unbounded_String :=
     [1 => [To_Unbounded_String ("box"),
            To_Unbounded_String (""),
            To_Unbounded_String ("")],
      2 => [To_Unbounded_String (""),
            To_Unbounded_String ("row"),
            To_Unbounded_String ("")],
      3 => [To_Unbounded_String (""),
            To_Unbounded_String (""),
            To_Unbounded_String ("pin")],
      4 => [To_Unbounded_String ("box"),
            To_Unbounded_String ("row"),
            To_Unbounded_String ("pin")],
      5 => [To_Unbounded_String ("box"),
            To_Unbounded_String ("row wide"),
            To_Unbounded_String ("")],
      6 => [To_Unbounded_String (""),
            To_Unbounded_String ("wide row"),
            To_Unbounded_String ("")],
      7 => [To_Unbounded_String ("BOX"),
            To_Unbounded_String ("Row Wide"),
            To_Unbounded_String ("PIN")],
      8 => [To_Unbounded_String ("label"),
            To_Unbounded_String ("absent-class"),
            To_Unbounded_String ("absent-id")],
      9 => [To_Unbounded_String (""),
            To_Unbounded_String (""),
            To_Unbounded_String ("")]];

   Memo_CSS : constant String :=
     "box { padding: 2px; }" & ASCII.LF
     & ".row { background-color: rgb(10, 20, 30); margin: 1px; }" & ASCII.LF
     & ".wide { padding: 9px; }" & ASCII.LF
     & "#pin { background-color: rgb(70, 80, 90); }" & ASCII.LF
     & "label { color: rgb(1, 2, 3); }" & ASCII.LF;

   procedure Check_Triples (Src : in out Adi.CSS_Source.Style_Source;
                            Note : String) is
   begin
      for I in Triples'Range (1) loop
         declare
            T : constant String := To_String (Triples (I, 1));
            C : constant String := To_String (Triples (I, 2));
            D : constant String := To_String (Triples (I, 3));

            Fresh : constant Part_Style_Array :=
              Adi.CSS_Source.Testing.Combined_Styles_Uncached (Src, T, C, D);
            Miss  : constant Part_Style_Array :=
              Adi.CSS_Source.Testing.Combined_Styles_Memoized (Src, T, C, D);
            Hit   : constant Part_Style_Array :=
              Adi.CSS_Source.Testing.Combined_Styles_Memoized (Src, T, C, D);
         begin
            Assert (Miss = Fresh,
                    Note & ": triple" & I'Image
                    & " on a miss equals a fresh fold");
            Assert (Hit = Fresh,
                    Note & ": triple" & I'Image
                    & " on a hit equals a fresh fold");
         end;
      end loop;
   end Check_Triples;

   procedure Test_Memo_Agrees is
      Dyn : Adi.CSS_Source.Style_Source;
      Sta : Adi.CSS_Source.Style_Source;
      OK  : Boolean := False;

      Hits_Before   : Natural;
      Misses_Before : Natural;
   begin
      Section ("a memo hit answers what the fold answers");

      Adi.CSS_Source.Add_Dynamic_String (Dyn, Memo_CSS, OK);
      Assert (OK, "the memo corpus should parse");
      Adi.CSS_Source.Set_Mode (Dyn, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "dynamic mode should install");

      Reset_Perf_Counters;
      Hits_Before   := Get_Perf_Selector_Memo_Hits;
      Misses_Before := Get_Perf_Selector_Memo_Misses;

      Check_Triples (Dyn, "dynamic");

      Assert (Get_Perf_Selector_Memo_Misses > Misses_Before,
              "the first fold of each triple counts as a miss");
      Assert (Get_Perf_Selector_Memo_Hits > Hits_Before,
              "the second fold of each triple counts as a hit");
      Assert (Adi.CSS_Source.Testing.Combined_Memo_Count (Dyn) > 0,
              "the memo holds what it answered");

      --  The same triples against the same rules registered statically.
      Adi.CSS_Source.Add_Static_Entry
        (Sta, Adi.CSS_Source.Tag_Entry
                ("box", Main_Styles ((Padding => Set (CSS_Box (Px (2.0))),
                                      others  => <>))));
      Adi.CSS_Source.Add_Static_Entry
        (Sta, Adi.CSS_Source.Class_Entry ("row", Bg (10, 20, 30)));
      Adi.CSS_Source.Add_Static_Entry
        (Sta, Adi.CSS_Source.Class_Entry
                ("wide", Main_Styles ((Padding => Set (CSS_Box (Px (9.0))),
                                       others  => <>))));
      Adi.CSS_Source.Add_Static_Entry
        (Sta, Adi.CSS_Source.Id_Entry ("pin", Bg (70, 80, 90)));
      Adi.CSS_Source.Set_Mode (Sta, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "static mode should install");

      Check_Triples (Sta, "static");

      Adi.CSS_Source.Destroy (Dyn);
      Adi.CSS_Source.Destroy (Sta);
   end Test_Memo_Agrees;

   ------------------------------------------------------------------
   --  Part B: what the memo is dropped for
   ------------------------------------------------------------------

   Red_CSS : constant String :=
     ".row { background-color: rgb(200, 0, 0); }" & ASCII.LF;
   Green_CSS : constant String :=
     ".row { background-color: rgb(0, 200, 0); }" & ASCII.LF;

   function Row_Color (Src : in out Adi.CSS_Source.Style_Source)
     return Color_Value
   is
      W : constant Box_Handle := Create_Handle;
   begin
      return Result : Color_Value do
         Adi.CSS_Source.Bind_Selector_Set
           (Src, +W, Tag_Name => "", Class_Name => "row", Id_Name => "");
         Result := Get_Resolved_Part_Style (+W, Main_Part).Background_Color;
         declare
            H : Widget_Handle := +W;
         begin
            Destroy (H);
         end;
      end return;
   end Row_Color;

   procedure Test_Reload_Invalidates is
      Src   : Adi.CSS_Source.Style_Source;
      First : constant Box_Handle := Create_Handle;
      OK    : Boolean := False;
   begin
      Section ("a reload drops what the memo folded from the old sheet");

      Adi.CSS_Source.Set_Dynamic_Sources
        (Src, [1 => Adi.CSS_Source.CSS_Text (Red_CSS)], OK);
      Assert (OK, "the first sheet should install");
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "dynamic mode should install");

      Adi.CSS_Source.Bind_Selector_Set
        (Src, +First, Tag_Name => "", Class_Name => "row", Id_Name => "");
      Assert (Is_RGB (Get_Resolved_Part_Style (+First, Main_Part)
                        .Background_Color, 200, 0, 0),
              "a widget bound before the reload starts on the old rule");

      Adi.CSS_Source.Set_Dynamic_Sources
        (Src, [1 => Adi.CSS_Source.CSS_Text (Green_CSS)], OK);
      Assert (OK, "the second sheet should install");

      Assert (Is_RGB (Get_Resolved_Part_Style (+First, Main_Part)
                        .Background_Color, 0, 200, 0),
              "the widget bound before the reload resolves to the new rule");
      Assert (Is_RGB (Row_Color (Src), 0, 200, 0),
              "a widget bound after the reload gets the new rule");

      declare
         H : Widget_Handle := +First;
      begin
         Destroy (H);
      end;
      Adi.CSS_Source.Destroy (Src);
   end Test_Reload_Invalidates;

   procedure Test_Static_Changes_Invalidate is
      Src : Adi.CSS_Source.Style_Source;
      OK  : Boolean := False;
   begin
      Section ("registering, clearing and replacing entries drop the memo");

      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry ("row", Bg (200, 0, 0)));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "static mode should install");
      Assert (Is_RGB (Row_Color (Src), 200, 0, 0),
              "the registered entry answers");

      --  Add_Static_Entry: another entry under the same name folds on.
      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry ("row", Bg (0, 200, 0)));
      Assert (Is_RGB (Row_Color (Src), 0, 200, 0),
              "a later entry under the same name is seen at once");

      --  Clear_Static_Entries: nothing answers.
      Adi.CSS_Source.Clear_Static_Entries (Src);
      Assert (Row_Color (Src).Kind /= RGB
                or else not Is_RGB (Row_Color (Src), 0, 200, 0),
              "a cleared registry answers nothing for the name");

      --  Set_Static_Entries: a fresh set replaces what was there.
      Adi.CSS_Source.Set_Static_Entries
        (Src, [1 => Adi.CSS_Source.Class_Entry ("row", Bg (0, 0, 200))]);
      Assert (Is_RGB (Row_Color (Src), 0, 0, 200),
              "a replaced registry answers from the new entries");

      Adi.CSS_Source.Destroy (Src);
   end Test_Static_Changes_Invalidate;

   procedure Test_Mode_Switch_Invalidates is
      Src : Adi.CSS_Source.Style_Source;
      OK  : Boolean := False;
   begin
      Section ("switching mode changes which sheet answers");

      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry ("row", Bg (200, 0, 0)));
      Adi.CSS_Source.Add_Dynamic_String (Src, Green_CSS, OK);
      Assert (OK, "the dynamic sheet should install");

      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "static mode should install");
      Assert (Is_RGB (Row_Color (Src), 200, 0, 0),
              "static mode answers from the registered entries");

      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "dynamic mode should install");
      Assert (Is_RGB (Row_Color (Src), 0, 200, 0),
              "dynamic mode answers from the loaded sheet");

      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "static mode should install again");
      Assert (Is_RGB (Row_Color (Src), 200, 0, 0),
              "switching back answers from the registered entries again");

      Adi.CSS_Source.Clear_Dynamic_Entries (Src);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "dynamic mode with nothing loaded should install");
      Assert (not Is_RGB (Row_Color (Src), 0, 200, 0),
              "a cleared dynamic configuration answers nothing");

      Adi.CSS_Source.Destroy (Src);
   end Test_Mode_Switch_Invalidates;

   ------------------------------------------------------------------
   --  Part B: what bounds the memo
   ------------------------------------------------------------------

   procedure Test_Memo_Is_Bounded is
      Src     : Adi.CSS_Source.Style_Source;
      OK      : Boolean := False;
      Cap     : constant Natural :=
        Adi.CSS_Source.Testing.Max_Combined_Memo;
      Dropped : Boolean := False;
   begin
      Section ("the memo is dropped whole at its cap");

      Adi.CSS_Source.Add_Static_Entry
        (Src, Adi.CSS_Source.Class_Entry ("row", Bg (10, 20, 30)));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "static mode should install");

      for I in 1 .. Cap + 5 loop
         declare
            Ignored : constant Part_Style_Array :=
              Adi.CSS_Source.Testing.Combined_Styles_Memoized
                (Src, "", "row", "id-" & I'Image);
         begin
            pragma Unreferenced (Ignored);
            Assert (Adi.CSS_Source.Testing.Combined_Memo_Count (Src) <= Cap,
                    "the memo never holds more than its cap");
            if Adi.CSS_Source.Testing.Combined_Memo_Count (Src) < I then
               Dropped := True;
            end if;
         end;
      end loop;

      Assert (Dropped, "crossing the cap drops the memo whole");

      --  What it answers is unchanged by the drop.
      Assert (Adi.CSS_Source.Testing.Combined_Styles_Memoized
                (Src, "", "row", "")
              = Adi.CSS_Source.Testing.Combined_Styles_Uncached
                  (Src, "", "row", ""),
              "a refilled memo answers what the fold answers");

      Adi.CSS_Source.Destroy (Src);
   end Test_Memo_Is_Bounded;

begin
   Start_Suite ("Selector lookup and combined-style memo test");

   Test_Corpus_Agreement;
   Test_Repeated_Static_Entries;
   Test_Memo_Agrees;
   Test_Reload_Invalidates;
   Test_Static_Changes_Invalidate;
   Test_Mode_Switch_Invalidates;
   Test_Memo_Is_Bounded;

   Finish;
end Selector_Lookup_Test;
