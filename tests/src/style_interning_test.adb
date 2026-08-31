pragma Ada_2022;

with Test_Support;      use Test_Support;
with Adi.CSS_Parser;
with Adi.CSS_Parser.Testing;
with Adi.CSS_Source;
with Adi.CSS_Source.Testing;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;  use Adi.Widget.Box;
with Adi.Widget.Testing;
with Adi.Widget_Styles; use Adi.Widget_Styles;

--  Styles registered on a Style_Source are interned: the source keeps
--  handles, and the styles themselves are stored once for the process.
--  An application that builds one source per generated UI package
--  registers the same table from every one of them, so what must not
--  scale with the number of sources is either the size of an entry or
--  the number of stored styles.
procedure Style_Interning_Test is

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True),
       others    => <>]);

   function Interned_Styles return Natural
     renames Adi.Widget.Testing.Interned_Styles;

   --  Built by a function, not held in a constant: the point is that
   --  each source constructs its own equal copies, as generated code
   --  does, rather than sharing one table.
   function Table return Adi.CSS_Source.Static_Style_Entry_Array is
     ([Adi.CSS_Source.Class_Entry
         ("panel",
          Main_Styles ((Background_Color => Set_Bg (RGB (17, 23, 31)),
                        Padding          => Set (CSS_Box (Px (8.0), Px (8.0),
                                                          Px (8.0), Px (8.0))),
                        others           => <>))),
       Adi.CSS_Source.Class_Entry
         ("title",
          Main_Styles ((Color     => Set (C (White)),
                        Font_Size => Set_Font (Px (18.0)),
                        others    => <>))),
       Adi.CSS_Source.Id_Entry
         ("root",
          Main_Styles ((Display => Set (Flex), others => <>)))]);

   procedure Test_Entry_Is_Small is
   begin
      Section ("size of a registered selector");
      Assert (Adi.CSS_Source.Testing.Static_Entry_Bytes <= 256,
              "a registered selector costs at most 256 bytes");
   end Test_Entry_Is_Small;

   procedure Test_Same_Table_From_Many_Sources is
      Sources     : array (1 .. 8) of Adi.CSS_Source.Style_Source;
      Before      : constant Natural := Interned_Styles;
      After_First : Natural;
   begin
      Section ("the same table registered from many sources");

      Adi.CSS_Source.Set_Static_Entries (Sources (1), Table);
      After_First := Interned_Styles;

      for I in 2 .. Sources'Last loop
         Adi.CSS_Source.Set_Static_Entries (Sources (I), Table);
      end loop;

      Assert (After_First > Before,
              "registering a table stores the styles it names");
      Assert (Interned_Styles = After_First,
              "registering an equal table again stores nothing further");

      --  Counting the store only says nothing new was added. A source
      --  that resolved a selector to the wrong stored style would leave
      --  the count flat and style every widget bound through it wrongly.
      declare
         First : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         Last  : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         OK    : Boolean;
      begin
         Adi.CSS_Source.Set_Mode
           (Sources (Sources'First), Adi.CSS_Source.Static_Mode, OK);
         Assert (OK, "a source takes its static table");
         Adi.CSS_Source.Set_Mode
           (Sources (Sources'Last), Adi.CSS_Source.Static_Mode, OK);
         Assert (OK, "and so does the last of them");

         Adi.CSS_Source.Bind_Class
           (Sources (Sources'First), "panel", Widget_Handle'(+First));
         Adi.CSS_Source.Bind_Class
           (Sources (Sources'Last), "panel", Widget_Handle'(+Last));

         Assert (Get_Part_Style (+First, Main_Part) =
                   Get_Part_Style (+Last, Main_Part),
                 "and every source resolves the selector alike");
         Assert (Opt_Bg_Color.Is_Set
                   (Rules_Of (Definition (Get_Part_Style (+Last, Main_Part))
                                .Base).Background_Color),
                 "to the style the table actually named");
      end;
   end Test_Same_Table_From_Many_Sources;

   --  A style is a wall of discriminated records holding strings and an
   --  access value. Two equal ones built by separate calls share no
   --  bytes, so anything that keys on their bytes stores each of them.
   procedure Test_Equal_Styles_Carrying_A_String is
      function Named return Part_Style_Array is
        (Main_Styles ((Font_Family => Set_Font_Family ("DejaVu Sans"),
                       others      => <>)));

      First  : constant Part_Style_Array := Named;
      Middle : constant Natural          := Interned_Styles;
      Second : constant Part_Style_Array := Named;
   begin
      Section ("equal styles built twice");
      Assert (First = Second,
              "two equal styles carrying a string intern alike");
      Assert (Interned_Styles = Middle,
              "and the second stores nothing further");
   end Test_Equal_Styles_Carrying_A_String;

   procedure Test_Round_Trip is
      Original : Part_Style_Array := Empty_Part_Styles;
   begin
      Section ("intern and read back");

      Original (Main_Part) :=
        (Style   => From ((Color            => Set (C (White)),
                           Background_Color => Set_Bg (RGB (9, 9, 9)),
                           others           => <>))
                      .On (When_State (State_Hovered),
                           (Color  => Set (RGB (1, 2, 3)), others => <>))
                      .On (When_Part_State (State_Disabled),
                           (Opacity => Set (0.5), others => <>))
                      .Build,
         Enabled => True);

      --  A part that carries a style and is switched off is not the same
      --  as a part with no style: Merge_Part_Styles skips the first and
      --  would fold in the second.
      Original (Label_Part) :=
        (Style   => From ((Color => Set (RGB (7, 7, 7)), others => <>)).Build,
         Enabled => False);

      declare
         D : constant Style_Definition :=
           Definition (Original (Main_Part).Style);
      begin
         Assert (Intern (D) = Original (Main_Part).Style,
                 "a definition read back interns to the handle it came from");
         Assert (D.Rule_Count = 2, "both state rules survive the store");
         Assert (Opt_Text_Color.Resolve (Rules_Of (D.Base).Color) = C (White),
                 "and so does the base rule set");
      end;

      Assert (not Original (Label_Part).Enabled,
              "a part switched off stays switched off");
   end Test_Round_Trip;

   --  Interning compares styles with Same_Style rather than predefined
   --  equality. The two must agree on everything the library can build.
   procedure Test_Same_Style_Agrees_With_Equality is
      Base : constant Style_Rules :=
        (Color => Set (C (White)), others => <>);

      Styles : constant array (1 .. 7) of Widget_Style :=
        [1 => Empty_Widget_Style,
         2 => From (Base).Build,
         3 => From ((Color => Set (C (Black)), others => <>)).Build,
         4 => From (Base).On (When_State (State_Hovered),
                              (Opacity => Set (0.5), others => <>)).Build,
         5 => From (Base).On (When_State (State_Pressed),
                              (Opacity => Set (0.5), others => <>)).Build,
         6 => From (Base).On (When_State (State_Hovered),
                              (Opacity => Set (0.25), others => <>)).Build,
         7 => From (Base).On (When_State (State_Hovered),
                              (Opacity => Set (0.5), others => <>))
                         .On (When_Part_State (State_Focused),
                              (Opacity => Set (1.0), others => <>)).Build];
   begin
      Section ("Same_Style against predefined equality");

      for I in Styles'Range loop
         for J in Styles'Range loop
            Assert (Same_Style (Definition (Styles (I)),
                                Definition (Styles (J))) =
                      (Styles (I) = Styles (J)),
                    "styles" & I'Image & J'Image & " agree");
         end loop;
      end loop;

      Assert (Same_Style (Definition (From (Base).Build),
                          Definition (From (Base).Build)),
              "two styles built alike are the same style");
   end Test_Same_Style_Agrees_With_Equality;

   --  A stylesheet keeps one entry per selector it names, and every
   --  source loading the same CSS parses it into a sheet of its own.
   Sheet_CSS : constant String :=
     ".panel { background-color: #11171f; padding: 8px; }" & ASCII.LF &
     ".panel:hover { background-color: #222; }" & ASCII.LF &
     ".title { color: white; font-size: 18px; }" & ASCII.LF &
     ".title::label { color: #cccccc; }" & ASCII.LF &
     "#root { display: flex; }" & ASCII.LF &
     "button { padding: 4px; }" & ASCII.LF;

   procedure Test_Parsed_Entry_Is_Small is
   begin
      Section ("size of a parsed selector");
      Assert (Adi.CSS_Parser.Testing.Selector_Entry_Bytes <= 256,
              "a parsed selector costs at most 256 bytes");
   end Test_Parsed_Entry_Is_Small;

   procedure Test_Same_CSS_In_Many_Sheets is
      Sheets      : array (1 .. 8) of Adi.CSS_Parser.Stylesheet;
      OK          : Boolean;
      Before      : constant Natural := Interned_Styles;
      After_First : Natural;
   begin
      Section ("the same CSS parsed into many sheets");

      Adi.CSS_Parser.Load_String (Sheets (1), Sheet_CSS, OK);
      Assert (OK, "the sheet parses");
      After_First := Interned_Styles;

      for I in 2 .. Sheets'Last loop
         Adi.CSS_Parser.Load_String (Sheets (I), Sheet_CSS, OK);
         Assert (OK, "every further sheet parses");
      end loop;

      Assert (After_First > Before,
              "parsing a sheet stores the styles it names");
      Assert (Interned_Styles = After_First,
              "parsing the same CSS again stores nothing further");

      for I in 2 .. Sheets'Last loop
         Assert (Adi.CSS_Parser.Styles_For_Class (Sheets (I), "panel") =
                   Adi.CSS_Parser.Styles_For_Class (Sheets (1), "panel"),
                 "and every sheet reports the same styles");
      end loop;
   end Test_Same_CSS_In_Many_Sheets;

   --  A sheet naming no selector at all: only :root, or nothing.
   procedure Test_Sheet_Without_Selectors is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean;
   begin
      Section ("a sheet with no selectors");

      Adi.CSS_Parser.Load_String (Sheet, "", OK);
      Assert (OK, "empty CSS parses");

      Adi.CSS_Parser.Load_String (Sheet, ":root { font-size: 15px; }", OK);
      Assert (OK, "a sheet of nothing but :root parses");
      Assert (Adi.CSS_Parser.Get_Metadata (Sheet).Has_Root_Font_Size,
              "and its root metadata survives");
      Assert (Adi.CSS_Parser.Styles_For_Class (Sheet, "absent") =
                Empty_Part_Styles,
              "a selector it does not name has no styles");
   end Test_Sheet_Without_Selectors;

   --  Rules for one selector arrive scattered through the sheet and are
   --  merged as they come, so a build that interned each rule as it
   --  landed would report only the last.
   procedure Test_Rules_Merge_Before_Interning is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean;
   begin
      Section ("rules merged across the sheet");

      Adi.CSS_Parser.Load_String
        (Sheet,
         ".a { color: white; }" & ASCII.LF &
         ".b { color: black; }" & ASCII.LF &
         ".a { font-size: 20px; }" & ASCII.LF &
         ".a:hover { color: #010203; }" & ASCII.LF &
         ".a::label { color: #040506; }" & ASCII.LF,
         OK);
      Assert (OK, "the sheet parses");

      declare
         A : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, "a");
      begin
         Assert (Opt_Text_Color.Is_Set
                   (Rules_Of (Definition (A (Main_Part).Style).Base).Color),
                 "the first rule survives a later one");
         Assert (Opt_Font_Size.Is_Set
                   (Rules_Of (Definition (A (Main_Part).Style).Base).Font_Size),
                 "the later rule is folded into the same entry");
         Assert (Definition (A (Main_Part).Style).Rule_Count = 1,
                 "a state rule lands on the same entry");
         Assert (Opt_Text_Color.Is_Set
                   (Rules_Of (Definition (A (Label_Part).Style).Base).Color),
                 "and a part rule lands on the part");
      end;
   end Test_Rules_Merge_Before_Interning;

   --  A gradient is held by pointer, and a pointer is what equality on
   --  the enclosing style compares, so a style carrying one is equal to
   --  its own copy only if equal gradients are one pointer.
   procedure Test_Gradients_Are_Shared is
      function Fade (To : Color_Value) return Part_Style_Array is
        (Main_Styles
           ((Background_Image => Set_Bg_Image
               (Linear_Gradient
                  (90.0,
                   [1      => Gradient_Stop_Auto (C (Black)),
                    2      => Gradient_Stop_Auto (To),
                    others => <>],
                   2)),
             others => <>)));

      Before : constant Natural          := Interned_Styles;
      First  : constant Part_Style_Array := Fade (C (White));
      Middle : constant Natural          := Interned_Styles;
      Second : constant Part_Style_Array := Fade (C (White));
      --  Read here rather than below: .Build interns, so a gradient
      --  built further down for a different colour moves the count.
      After  : constant Natural          := Interned_Styles;
   begin
      Section ("styles carrying a gradient");
      Assert (Middle > Before, "a gradient style is stored");
      Assert (Fade (C (White)) = Fade (C (White)),
              "equal gradients make equal styles");
      Assert (Fade (C (White)) /= Fade (RGB (1, 2, 3)),
              "different gradients make different styles");
      Assert (First = Second,
              "two equal gradients built separately intern alike");
      Assert (After = Middle,
              "and the second stores nothing further");
      Assert (First = Fade (C (White)),
              "a gradient survives interning");
   end Test_Gradients_Are_Shared;

begin
   Start_Suite ("Style Interning Test");

   Test_Entry_Is_Small;
   Test_Same_Table_From_Many_Sources;
   Test_Equal_Styles_Carrying_A_String;
   Test_Round_Trip;
   Test_Same_Style_Agrees_With_Equality;
   Test_Parsed_Entry_Is_Small;
   Test_Same_CSS_In_Many_Sheets;
   Test_Sheet_Without_Selectors;
   Test_Rules_Merge_Before_Interning;
   Test_Gradients_Are_Shared;

   Finish;
end Style_Interning_Test;
