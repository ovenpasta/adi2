pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Adi.CSS_Parser;          use Adi.CSS_Parser;
with Adi.CSS_Parser.Testing;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Test_Properties;
with Test_Support;            use Test_Support;

--  Withed for its elaboration: it declares the widget properties
--  tests/css/widget_property.css selects on, so that sheet parses here
--  as it does in the application that owns the vocabulary.
pragma Unreferenced (Test_Properties);

--  Adi.CSS_Parser builds a Rule_Slots as it reads a declaration, where
--  it once filled a Style_Rules field by field. What holds the two the
--  same answer is that a parsed list is a Slots_Of image: converting it
--  to the record and back answers the list it started from, entry for
--  entry and in order. That is checked here over every stylesheet in
--  the repository, and then over the shapes a corpus reaches rarely --
--  a property declared twice, a rule filling the slot list, and the
--  four properties whose slots are irregular.
--
--  A round trip is a self-consistency check, so it stands beside a
--  second one that is not: every declaration name the parser reads is
--  written out below with the keys it must name -- the property CSS
--  gives the name, at the part the name picks out. That table is read
--  off the CSS vocabulary rather than off the parser, so a declaration
--  landing on the wrong property, on the wrong edge, or over more of a
--  property than its name covers fails here whether or not it round
--  trips. css_parser_test holds the values; this holds the keys.

procedure Parser_Slots_Test is

   Corpus_Dirs : constant array (1 .. 2) of Unbounded_String :=
     [To_Unbounded_String ("examples/css"),
      To_Unbounded_String ("tests/css")];

   --  A gap axis, wherever Overlay left the value: a pair equal on
   --  both axes collapses to the uniform arm.
   function Row_Of (G : Gap_Value) return Float is
     (if G.Kind = Gap_Uniform then G.All_Gap.Amount else G.Row_Gap.Amount);
   function Col_Of (G : Gap_Value) return Float is
     (if G.Kind = Gap_Uniform then G.All_Gap.Amount else G.Column_Gap.Amount);

   Sheets_Read : Natural := 0;
   Lists_Read  : Natural := 0;

   --  A parsed list against the same list taken through the record.
   --  Rules_Of writes each slot into the field it names and Slots_Of
   --  reads the fields back in property order, so the two agree exactly
   --  where the parser wrote what Slots_Of would have written.
   procedure Check_Canonical (L : Rule_Slots; Where : String) is
   begin
      Lists_Read := Lists_Read + 1;
      Assert (Slots_Of (Rules_Of (L)) = L,
              Where & ": the slots the parser built are the slots"
              & " Slots_Of builds from the rule set they name");
      Assert (Slot_Count (L) <= Max_Rule_Slots,
              Where & ": the list stays inside Max_Rule_Slots, at"
              & Natural'Image (Slot_Count (L)));
   end Check_Canonical;

   --  A sheet selecting on a property declared with Dynamic_Lookup
   --  => False: no name of it reaches the registry, so a sheet read at
   --  run time is refused for naming it and the generated form is what
   --  carries it. widget_property_test holds that refusal.
   Withheld : constant String := "widget_property_static.css";

   procedure Check_Sheet (Path : String) is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;
   begin
      Adi.CSS_Parser.Load_File (Sheet, Path, OK);
      Assert (OK, Path & " parses");
      if not OK then
         return;
      end if;

      Sheets_Read := Sheets_Read + 1;

      for I in 1 .. Adi.CSS_Parser.Testing.Selector_Count (Sheet) loop
         declare
            Kind : constant Selector_Kind :=
              Adi.CSS_Parser.Testing.Selector_Kind_At (Sheet, I);
            Name : constant String :=
              Adi.CSS_Parser.Testing.Selector_Name_At (Sheet, I);
            PS   : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For (Sheet, Kind, Name);
         begin
            for Part in Part_Kind loop
               declare
                  D : constant Style_Definition := Definition (PS (Part).Style);
                  Where : constant String :=
                    Path & " " & Name & " " & Part'Image;
               begin
                  Check_Canonical (Slots_Of (D.Base), Where & " base");
                  for R in 1 .. D.Rule_Count loop
                     Check_Canonical (Slots_Of (D.Rules (R).Style),
                                      Where & " rule" & R'Image);
                  end loop;
               end;
            end loop;
         end;
      end loop;

      Adi.CSS_Parser.Destroy (Sheet);
   end Check_Sheet;

   procedure Test_The_Corpus is
      use Ada.Directories;
      Search : Search_Type;
      Item   : Directory_Entry_Type;
   begin
      Section ("every stylesheet in the repository");

      for D of Corpus_Dirs loop
         Assert (Exists (To_String (D)),
                 To_String (D) & " is where the test is run from");
         Start_Search (Search, To_String (D), "*.css",
                       [Ordinary_File => True, others => False]);
         while More_Entries (Search) loop
            Get_Next_Entry (Search, Item);
            if Simple_Name (Item) /= Withheld then
               Check_Sheet (Full_Name (Item));
            end if;
         end loop;
         End_Search (Search);
      end loop;

      Ada.Text_IO.Put_Line
        ("  sheets read:" & Natural'Image (Sheets_Read)
         & ", rule sets checked:" & Natural'Image (Lists_Read));

      Assert (Sheets_Read >= 30,
              "the corpus is the sheets the repository carries, not"
              & Natural'Image (Sheets_Read));
      Assert (Lists_Read >= 1_000,
              "and every rule set in them is read, not"
              & Natural'Image (Lists_Read));
   end Test_The_Corpus;

   ---------------------------------------------------------------------

   --  A sheet loaded from text, so a case the corpus reaches rarely can
   --  be written out in CSS.
   function Slots_For (CSS : String; Class : String) return Rule_Slots is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;
   begin
      Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
      Assert (OK, "the sheet under test parses");
      declare
         PS : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, Class);
         L  : constant Rule_Slots :=
           Slots_Of (Definition (PS (Main_Part).Style).Base);
      begin
         Adi.CSS_Parser.Destroy (Sheet);
         return L;
      end;
   end Slots_For;

   function Rules_For (CSS : String; Class : String) return Style_Rules is
     (Rules_Of (Slots_For (CSS, Class)));

   procedure Test_A_Property_Declared_Twice is
      L : constant Rule_Slots :=
        Slots_For (".dup { color: red; color: blue; padding: 1px;"
                   & " color: green; }", "dup");
      R : constant Style_Rules := Rules_Of (L);
   begin
      Section ("a property declared twice keeps one slot");

      Assert (Slot_Count (L) = 5,
              "colour once and padding's four edges, not"
              & Natural'Image (Slot_Count (L)));
      Assert (Opt_Text_Color.Is_Set (R.Color)
                and then R.Color.Value.Kind = Named
                and then R.Color.Value.Name = Green,
              "and the last declaration is the one that stands");
      Check_Canonical (L, "a property declared twice");
   end Test_A_Property_Declared_Twice;

   --  Every key a rule set can carry, written twice over, so the list
   --  fills exactly and the repeats replace rather than append. A
   --  parser appending per declaration overflows Slot_Array here.
   Whole_Vocabulary : constant String :=
     ".every {"
     & " color: #010203; background-color: #040506;"
     & " background-image: url(bg.png);"
     & " border-top-left-radius: 1px; border-top-right-radius: 2px;"
     & " border-bottom-right-radius: 3px; border-bottom-left-radius: 4px;"
     & " border-top-width: 1px; border-right-width: 2px;"
     & " border-bottom-width: 3px; border-left-width: 4px;"
     & " border-top-color: red; border-right-color: green;"
     & " border-bottom-color: blue; border-left-color: black;"
     & " border-top-style: solid; border-right-style: dashed;"
     & " border-bottom-style: dotted; border-left-style: solid;"
     & " outline-width: 1px; outline-color: red; outline-style: solid;"
     & " outline-offset: 2px;"
     & " padding-top: 1px; padding-right: 2px;"
     & " padding-bottom: 3px; padding-left: 4px;"
     & " margin-top: 1px; margin-right: auto;"
     & " margin-bottom: 3px; margin-left: 4px;"
     & " width: 10px; height: 11px;"
     & " min-width: 1px; max-width: 100px;"
     & " min-height: 2px; max-height: 200px;"
     & " font-family: sans-serif; font-size: 12px; font-weight: bold;"
     & " font-style: italic; text-align: center; vertical-align: middle;"
     & " text-decoration: underline; list-style-type: disc;"
     & " list-style-image: url(m.png); list-style-position: inside;"
     & " white-space: pre; text-overflow: ellipsis;"
     & " text-wrap-mode: nowrap; line-height: 1.5;"
     & " display: flex; position: absolute;"
     & " overflow-x: auto; overflow-y: scroll; visibility: hidden;"
     & " top: 1px; right: 2px; bottom: 3px; left: 4px;"
     & " opacity: 0.5; cursor: pointer;"
     & " box-shadow: 1px 2px 3px 4px red;"
     & " object-fit: cover; object-position: left top;"
     & " flex-direction: column; flex-wrap: wrap;"
     & " justify-content: center; align-items: center;"
     & " align-content: center;"
     & " row-gap: 1px; column-gap: 2px;"
     & " grid-template-columns: 1fr 2fr; grid-template-rows: 3;"
     & " align-self: center; flex-grow: 1; flex-shrink: 2;"
     & " flex-basis: 10px; order: 3;"
     & " grid-column: 2 / span 2; grid-row: 3 / span 3;"
     & " transition: 0.2s;";

   procedure Test_A_Rule_Filling_The_List is
      Once  : constant Rule_Slots := Slots_For (Whole_Vocabulary & " }",
                                                "every");
      Twice : constant Rule_Slots :=
        Slots_For (Whole_Vocabulary & Whole_Vocabulary (11 .. Whole_Vocabulary'Last)
                   & " }", "every");
   begin
      Section ("a rule naming the whole vocabulary fills the list");

      Assert (Slot_Count (Once) = Max_Rule_Slots,
              "every key a rule set carries is named, not"
              & Natural'Image (Slot_Count (Once)) & " of"
              & Natural'Image (Max_Rule_Slots));
      Assert (Slot_Count (Twice) = Slot_Count (Once),
              "and naming them all a second time replaces rather than"
              & " appends, at" & Natural'Image (Slot_Count (Twice)));
      Assert (Twice = Once, "to the same list");
      Check_Canonical (Once, "the whole vocabulary");
   end Test_A_Rule_Filling_The_List;

   --  §3.5's four: gap's two axis keys, the track list beside the
   --  column count, the overflow shorthand a rule set holds as its two
   --  axes, and font-family resolving at Resolve time.
   procedure Test_The_Irregular_Shapes is
      Axes : constant Rule_Slots :=
        Slots_For (".g { column-gap: 4px; row-gap: 8px; }", "g");
      Axes_R : constant Style_Rules := Rules_Of (Axes);

      Over_Axis : constant Style_Rules :=
        Rules_For (".g2 { gap: 10px; row-gap: 2px; }", "g2");

      Tracks : constant Rule_Slots :=
        Slots_For (".t { grid-template-columns: 1fr 2fr 3fr; }", "t");
      Dropped : constant Rule_Slots :=
        Slots_For (".t2 { grid-template-columns: 1fr 2fr;"
                   & " grid-template-columns: none; }", "t2");

      Flow : constant Rule_Slots :=
        Slots_For (".o { overflow: hidden; }", "o");
      Flow_R : constant Style_Rules := Rules_Of (Flow);

      Family : constant Rule_Slots :=
        Slots_For (".f { font-family: ""Adi Sans"", sans-serif; }", "f");
   begin
      Section ("the four properties whose slots are irregular");

      Assert (Slot_Count (Axes) = 2, "gap carries a slot per axis, not"
              & Natural'Image (Slot_Count (Axes)));
      Assert (Opt_Gap.Is_Set (Axes_R.Gap)
                and then Row_Of (Axes_R.Gap.Value) = 8.0
                and then Col_Of (Axes_R.Gap.Value) = 4.0,
              "each axis holding the longhand that named it");
      Assert (Opt_Gap.Is_Set (Over_Axis.Gap)
                and then Row_Of (Over_Axis.Gap.Value) = 2.0
                and then Col_Of (Over_Axis.Gap.Value) = 10.0,
              "and a longhand after a shorthand taking one axis of it");

      Assert (Slot_Count (Tracks) = 2,
              "grid-template-columns carries the track list beside its"
              & " count, not" & Natural'Image (Slot_Count (Tracks)));
      Assert (Opt_Grid_Tracks.Resolve
                (Rules_Of (Tracks).Grid_Column_Tracks).Count = 3,
              "with the tracks the value named");
      Assert (Slot_Count (Dropped) = 2,
              "and `none` names the track list beside the count rather"
              & " than leaving it to the cascade, at"
              & Natural'Image (Slot_Count (Dropped)));
      Assert (Opt_Grid_Tracks.Resolve
                (Rules_Of (Dropped).Grid_Column_Tracks).Count = 0,
              "with no track list beside it");

      Assert (Slot_Count (Flow) = 2,
              "the overflow shorthand is held as its two axes, not"
              & Natural'Image (Slot_Count (Flow)));
      Assert (Set_Properties (Flow) (Prop_Overflow_X)
                and then Set_Properties (Flow) (Prop_Overflow_Y)
                and then not Set_Properties (Flow) (Prop_Overflow),
              "and the shorthand itself names no slot");
      Assert (Opt_Overflow.Is_Set (Flow_R.Overflow_X)
                and then Flow_R.Overflow_X.Value = Overflow_Hidden
                and then Flow_R.Overflow_Y.Value = Overflow_Hidden,
              "both axes carrying the value the shorthand named");

      Assert (Slot_Count (Family) = 1,
              "font-family carries one slot, not"
              & Natural'Image (Slot_Count (Family)));
      Assert (Rules_Of (Family).Font_Family.Value.Kind = By_Name,
              "carrying the list by name, for Resolve to answer with a"
              & " font");

      Check_Canonical (Axes, "gap by axis");
      Check_Canonical (Tracks, "a track list");
      Check_Canonical (Dropped, "a track list dropped");
      Check_Canonical (Flow, "the overflow shorthand");
      Check_Canonical (Family, "a font-family list");
   end Test_The_Irregular_Shapes;

   procedure Test_Order_Holds is
      --  Written last property first, and a side longhand between two
      --  shorthands, so nothing about the source order helps.
      L : constant Rule_Slots :=
        Slots_For (".ord { transition: 0.3s; grid-row-span: 2;"
                   & " border-left-width: 5px; order: 1; gap: 3px;"
                   & " color: red; border-width: 1px;"
                   & " border-top-width: 9px; display: block; }", "ord");
      R : constant Style_Rules := Rules_Of (L);
   begin
      Section ("a list stays ordered whatever order a rule is written in");

      Check_Canonical (L, "declarations out of order");
      Assert (Opt_Length.Is_Set (R.Border_Width (Top))
                and then R.Border_Width (Top).Value.Amount = 9.0,
              "the edge a longhand after the shorthand names stands");
      Assert (Opt_Length.Is_Set (R.Border_Width (Left))
                and then R.Border_Width (Left).Value.Amount = 1.0,
              "and the shorthand takes the edge a longhand ahead of it"
              & " named");
   end Test_Order_Holds;


   ---------------------------------------------------------------------

   --  A key as the table writes it: the property without its Prop_
   --  prefix, lowered, and the part it names.
   function Key_Image (P : CSS_Property; Part : Slot_Part) return String is
      Img : constant String := P'Image;
   begin
      return Ada.Characters.Handling.To_Lower
               (Img (Img'First + 5 .. Img'Last))
        & "/" & Ada.Strings.Fixed.Trim (Part'Image, Ada.Strings.Both);
   end Key_Image;

   function Keys_Of (L : Rule_Slots) return String is
      Out_Text : Unbounded_String;
   begin
      for I in 1 .. Slot_Count (L) loop
         if I > 1 then
            Append (Out_Text, ' ');
         end if;
         Append (Out_Text,
                 Key_Image (Slot_Property (L, I), Slot_Part_Of (L, I)));
      end loop;
      return To_String (Out_Text);
   end Keys_Of;

   type Row is record
      Decl : Unbounded_String;
      Keys : Unbounded_String;
   end record;

   function D (Decl, Keys : String) return Row is
     (To_Unbounded_String (Decl), To_Unbounded_String (Keys));

   --  Edges run Top, Right, Bottom, Left and corners Top_Left,
   --  Top_Right, Bottom_Right, Bottom_Left, which is what the part
   --  numbers below count. A key list is in the order a rule set holds
   --  it: by property, then by part.
   Vocabulary : constant array (Positive range <>) of Row :=
     [D ("align-content: center", "align_content/0"),
      D ("align-items: center", "align_items/0"),
      D ("align-self: center", "align_self/0"),
      D ("background: #010203", "background_color/0"),
      D ("background-color: #010203", "background_color/0"),
      D ("background-image: url(bg.png)", "background_image/0"),
      D ("border: 1px solid red",
         "border_width/0 border_width/1 border_width/2 border_width/3"
         & " border_color/0 border_color/1 border_color/2 border_color/3"
         & " border_style/0 border_style/1 border_style/2 border_style/3"),
      D ("border-bottom: 1px solid red",
         "border_width/2 border_color/2 border_style/2"),
      D ("border-bottom-color: red", "border_color/2"),
      D ("border-bottom-left-radius: 1px", "border_radius/3"),
      D ("border-bottom-right-radius: 1px", "border_radius/2"),
      D ("border-bottom-style: solid", "border_style/2"),
      D ("border-bottom-width: 1px", "border_width/2"),
      D ("border-color: red",
         "border_color/0 border_color/1 border_color/2 border_color/3"),
      D ("border-left: 1px solid red",
         "border_width/3 border_color/3 border_style/3"),
      D ("border-left-color: red", "border_color/3"),
      D ("border-left-style: solid", "border_style/3"),
      D ("border-left-width: 1px", "border_width/3"),
      D ("border-radius: 1px",
         "border_radius/0 border_radius/1 border_radius/2 border_radius/3"),
      D ("border-right: 1px solid red",
         "border_width/1 border_color/1 border_style/1"),
      D ("border-right-color: red", "border_color/1"),
      D ("border-right-style: solid", "border_style/1"),
      D ("border-right-width: 1px", "border_width/1"),
      D ("border-style: solid",
         "border_style/0 border_style/1 border_style/2 border_style/3"),
      D ("border-top: 1px solid red",
         "border_width/0 border_color/0 border_style/0"),
      D ("border-top-color: red", "border_color/0"),
      D ("border-top-left-radius: 1px", "border_radius/0"),
      D ("border-top-right-radius: 1px", "border_radius/1"),
      D ("border-top-style: solid", "border_style/0"),
      D ("border-top-width: 1px", "border_width/0"),
      D ("border-width: 1px",
         "border_width/0 border_width/1 border_width/2 border_width/3"),
      D ("bottom: 1px", "bottom/0"),
      D ("box-shadow: 1px 2px 3px 4px red", "box_shadow/0"),
      D ("color: red", "color/0"),
      D ("column-gap: 1px", "gap/1"),
      D ("cursor: pointer", "cursor/0"),
      D ("display: flex", "display/0"),
      D ("flex-basis: 10px", "flex_basis/0"),
      D ("flex-direction: column", "flex_direction/0"),
      D ("flex-grow: 1", "flex_grow/0"),
      D ("flex-shrink: 1", "flex_shrink/0"),
      D ("flex-wrap: wrap", "flex_wrap/0"),
      D ("font-family: sans-serif", "font_family/0"),
      D ("font-size: 12px", "font_size/0"),
      D ("font-style: italic", "font_style/0"),
      D ("font-weight: bold", "font_weight/0"),
      D ("gap: 1px", "gap/0 gap/1"),
      D ("grid-column: 2 / span 3", "grid_column/0 grid_column_span/0"),
      D ("grid-row: 2 / span 3", "grid_row/0 grid_row_span/0"),
      D ("grid-template-columns: 1fr 2fr",
         "grid_columns/0 grid_columns/1"),
      D ("grid-template-rows: 3", "grid_rows/0"),
      D ("height: 10px", "height/0"),
      D ("justify-content: center", "justify_content/0"),
      D ("left: 1px", "left/0"),
      D ("line-height: 1.5", "line_height/0"),
      D ("list-style: disc inside",
         "list_style_type/0 list_style_position/0"),
      D ("list-style-image: url(m.png)", "list_style_image/0"),
      D ("list-style-position: inside", "list_style_position/0"),
      D ("list-style-type: disc", "list_style_type/0"),
      D ("margin: 1px", "margin/0 margin/1 margin/2 margin/3"),
      D ("margin-bottom: 1px", "margin/2"),
      D ("margin-left: 1px", "margin/3"),
      D ("margin-right: 1px", "margin/1"),
      D ("margin-top: 1px", "margin/0"),
      D ("max-height: 10px", "max_height/0"),
      D ("max-width: 10px", "max_width/0"),
      D ("min-height: 10px", "min_height/0"),
      D ("min-width: 10px", "min_width/0"),
      D ("object-fit: cover", "object_fit/0"),
      D ("object-position: left top", "object_position/0"),
      D ("opacity: 0.5", "opacity/0"),
      D ("order: 2", "order/0"),
      D ("outline: 1px solid red",
         "outline_width/0 outline_color/0 outline_style/0"),
      D ("outline-color: red", "outline_color/0"),
      D ("outline-offset: 1px", "outline_offset/0"),
      D ("outline-style: solid", "outline_style/0"),
      D ("outline-width: 1px", "outline_width/0"),
      D ("overflow: hidden", "overflow_x/0 overflow_y/0"),
      D ("overflow-x: hidden", "overflow_x/0"),
      D ("overflow-y: hidden", "overflow_y/0"),
      D ("padding: 1px", "padding/0 padding/1 padding/2 padding/3"),
      D ("padding-bottom: 1px", "padding/2"),
      D ("padding-left: 1px", "padding/3"),
      D ("padding-right: 1px", "padding/1"),
      D ("padding-top: 1px", "padding/0"),
      D ("position: absolute", "position/0"),
      D ("right: 1px", "right/0"),
      D ("row-gap: 1px", "gap/0"),
      D ("text-align: center", "text_align/0"),
      D ("text-decoration: underline", "text_decoration/0"),
      D ("text-overflow: ellipsis", "text_overflow/0"),
      D ("text-wrap-mode: nowrap", "text_wrap_mode/0"),
      D ("top: 1px", "top/0"),
      D ("transition: 0.2s", "transition/0"),
      D ("vertical-align: middle", "vertical_align/0"),
      D ("visibility: hidden", "visibility/0"),
      D ("white-space: pre", "white_space/0"),
      D ("width: 10px", "width/0")];

   procedure Test_Every_Declaration_Names_Its_Keys is
   begin
      Section ("each declaration names the keys its name means");

      Assert (Vocabulary'Length = 98,
              "the table covers the parser's whole vocabulary, not"
              & Natural'Image (Vocabulary'Length) & " of 98");

      for E of Vocabulary loop
         declare
            Decl : constant String := To_String (E.Decl);
            L    : constant Rule_Slots :=
              Slots_For (".k { " & Decl & "; }", "k");
         begin
            Assert (Keys_Of (L) = To_String (E.Keys),
                    "'" & Decl & "' names [" & To_String (E.Keys)
                    & "], answering [" & Keys_Of (L) & "]");
         end;
      end loop;
   end Test_Every_Declaration_Names_Its_Keys;

   --  A declaration whose value names every part it covers replaces
   --  what it names and leaves the rest of the rule set alone. Run
   --  against a rule already holding every key, a longhand written as
   --  though it were a shorthand loses that property's other parts
   --  here, where naming its own key correctly would still pass above.
   procedure Test_A_Declaration_Loses_No_Key is
      Base_Keys : constant String :=
        Keys_Of (Slots_For (Whole_Vocabulary & " }", "every"));
   begin
      Section ("a declaration with a complete value drops no key");

      for E of Vocabulary loop
         declare
            Decl : constant String := To_String (E.Decl);
            L    : constant Rule_Slots :=
              Slots_For (Whole_Vocabulary & " " & Decl & "; }", "every");
         begin
            Assert (Keys_Of (L) = Base_Keys,
                    "'" & Decl & "' after a rule naming every key leaves"
                    & " every key");
            Assert (Slot_Count (L) = Max_Rule_Slots,
                    "'" & Decl & "' leaves the list at Max_Rule_Slots, not"
                    & Natural'Image (Slot_Count (L)));
         end;
      end loop;
   end Test_A_Declaration_Loses_No_Key;

   --  Put raises rather than indexing past Slot_Array when a key
   --  arrives at a full list. That it never can is the other half:
   --  every key the parser writes is one a rule set naming every
   --  property already holds, so nothing the parser reads reaches an
   --  eighty-sixth.
   procedure Test_The_Parsers_Keys_Are_Inside_The_Bound is
      Full : constant Rule_Slots :=
        Slots_For (Whole_Vocabulary & " }", "every");
      Base_Keys : constant String := Keys_Of (Full);

      function Holds (Key : String) return Boolean is
        (Ada.Strings.Fixed.Index (Base_Keys & " ", Key & " ") > 0);
   begin
      Section ("every key the parser writes is inside Max_Rule_Slots");

      Assert (Slot_Count (Full) = Max_Rule_Slots,
              "a rule naming every property fills the list exactly");

      for E of Vocabulary loop
         declare
            Keys : constant String := To_String (E.Keys);
            From : Positive := Keys'First;
         begin
            for I in Keys'Range loop
               if Keys (I) = ' ' or else I = Keys'Last then
                  declare
                     Last : constant Natural :=
                       (if Keys (I) = ' ' then I - 1 else I);
                  begin
                     Assert (Holds (Keys (From .. Last)),
                             "'" & To_String (E.Decl) & "' names "
                             & Keys (From .. Last)
                             & ", which a full rule set already holds");
                     From := I + 1;
                  end;
               end if;
            end loop;
         end;
      end loop;
   end Test_The_Parsers_Keys_Are_Inside_The_Bound;

begin
   Start_Suite ("Parser Slots Test");

   Test_The_Corpus;
   Test_A_Property_Declared_Twice;
   Test_A_Rule_Filling_The_List;
   Test_The_Irregular_Shapes;
   Test_Order_Holds;
   Test_Every_Declaration_Names_Its_Keys;
   Test_A_Declaration_Loses_No_Key;
   Test_The_Parsers_Keys_Are_Inside_The_Bound;

   Finish;
end Parser_Slots_Test;
