pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Core; use Adi.Core;
with Adi.CSS_Parser;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Font;
with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support;

procedure Css_Parser_Test is

   function Nearly_Equal (A, B : Float; Eps : Float := 0.0001) return Boolean is
   begin
      return abs (A - B) <= Eps;
   end Nearly_Equal;

   function Is_RGB_Color (Col : Color_Value; R, G, B : Natural) return Boolean is
   begin
      return Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B;
   end Is_RGB_Color;

   function Is_RGBA_Color (Col : Color_Value; R, G, B : Natural; A : Float) return Boolean is
   begin
      return Col.Kind = RGBA
        and then Col.RA = R
        and then Col.GA = G
        and then Col.BA = B
        and then Nearly_Equal (Col.Alpha, A, 0.01);
   end Is_RGBA_Color;

   function Is_Named_Color (Col : Color_Value; Name : Named_Color) return Boolean is
   begin
      return Col.Kind = Named and then Col.Name = Name;
   end Is_Named_Color;

   procedure Write_Text_File (Path : String; Content : String) is
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   end Write_Text_File;

   Sheet : Adi.CSS_Parser.Stylesheet;
   OK    : Boolean := False;

   CSS : constant String :=
     "/* base + comma selector */" & ASCII.LF &
     ".card, .panel {" & ASCII.LF &
     "  background-color: rgba(16,34,51,0.8);" & ASCII.LF &
     "  color: white;" & ASCII.LF &
     "  padding: 4px 8px;" & ASCII.LF &
     "  margin: 1px 2px 3px 4px;" & ASCII.LF &
     "  border-width: 1px 2px;" & ASCII.LF &
     "  border-style: solid;" & ASCII.LF &
     "  border-color: #445566;" & ASCII.LF &
     "  border-radius: 3px 6px;" & ASCII.LF &
     "  width: 120px;" & ASCII.LF &
     "  min-height: 40px;" & ASCII.LF &
     "  font-size: 13px;" & ASCII.LF &
     "  font-weight: 700;" & ASCII.LF &
     "  font-style: italic;" & ASCII.LF &
     "  text-align: center;" & ASCII.LF &
     "  text-wrap-mode: nowrap;" & ASCII.LF &
     "  display: flex;" & ASCII.LF &
     "  position: relative;" & ASCII.LF &
     "  overflow: hidden;" & ASCII.LF &
     "  opacity: 0.75;" & ASCII.LF &
     "  cursor: pointer;" & ASCII.LF &
     "  flex-direction: column;" & ASCII.LF &
     "  justify-content: center;" & ASCII.LF &
     "  align-items: flex-end;" & ASCII.LF &
     "  gap: 5px 9px;" & ASCII.LF &
     "  flex-grow: 2;" & ASCII.LF &
     "  flex-shrink: 3;" & ASCII.LF &
     "  flex-basis: 11px;" & ASCII.LF &
     "  order: 7;" & ASCII.LF &
     "  box-shadow: 2px 4px 6px rgba(10,20,30,0.4);" & ASCII.LF &
     "  transition: background-color 500ms ease;" & ASCII.LF &
     "}" & ASCII.LF &
     ".card:hover { background-color: rgb(1, 2, 3); }" & ASCII.LF &
     ".card:focus { border-color: rgb(9, 9, 9); }" & ASCII.LF &
     ".card:selected { background-color: rgb(7, 8, 9); }" & ASCII.LF &
     ".card:enabled { color: rgb(3, 4, 5); }" & ASCII.LF &
     ".card:not(:disabled) { border-width: 4px; }" & ASCII.LF &
     ".card::main:hover { opacity: 0.5; }" & ASCII.LF &
     ".card::label { color: rgb(50, 60, 70); }" & ASCII.LF &
     ".card::label:hover { color: rgb(220, 38, 38); }" & ASCII.LF &
     ".card::label:pressed { color: rgb(0, 0, 255); }" & ASCII.LF &
     ".card::label:focus { color: rgb(88, 77, 66); }" & ASCII.LF &
     "#submit { background-color: rgb(12, 34, 56); }" & ASCII.LF &
     "button { color: rgb(9, 8, 7); }" & ASCII.LF &
      ".seconds { transition: opacity 1.25s linear; }" & ASCII.LF &
      ".sides { padding: 1px 2px 3px 4px; padding-left: 11px; margin: 5px; margin-top: 9px; }" & ASCII.LF &
      ".dpunit { padding: 7dp; }" & ASCII.LF &
      ".pixunit { padding: 3pix; border-width: 1pix; " &
      "grid-template-columns: 40pix 1fr; }" & ASCII.LF &
       ".listprobe { list-style: url(app://marker.svg) square outside; }" & ASCII.LF &
       ".listprobe2 { list-style: ""-> ""; }" & ASCII.LF &
       ".listprobe3 { list-style-type: disc; list-style-image: none; list-style-position: inside; }" & ASCII.LF &
       ".listprobe4 { list-style: none; }" & ASCII.LF &
       ".svgnamed { color: cornflowerblue; background-color: lightgoldenrodyellow; border-color: darkslategray; }" & ASCII.LF &
       ".svgalias { color: grey; }" & ASCII.LF &
       ".svgaqua { color: aqua; }" & ASCII.LF &
       ".svgcyan { color: cyan; }" & ASCII.LF &
       "li, ul, p { color: red; }" & ASCII.LF &
       "li, ul, p { padding: 2px; }" & ASCII.LF &
       ".outline-long { outline-width: 3px; outline-style: solid; outline-color: rgb(100, 200, 50); outline-offset: 4px; }" & ASCII.LF &
       ".outline-short { outline: 2px solid rgb(208, 188, 255); }" & ASCII.LF &
       ".outline-offset { outline: 1px dashed red; outline-offset: 5px; }" & ASCII.LF &
       ".outline-none { outline: none; }" & ASCII.LF &
       --  Missing property coverage
       ".sizing { height: 200px; min-width: 50px; max-width: 400px; max-height: 300px; }" & ASCII.LF &
       ".textprops { text-decoration: underline; white-space: pre-wrap; text-overflow: ellipsis; line-height: 1.5; vertical-align: middle; }" & ASCII.LF &
       ".misc { visibility: hidden; object-fit: cover; object-position: center center; }" & ASCII.LF &
       ".misccollapse { visibility: collapse; }" & ASCII.LF &
       ".misc2 { object-position: 10px 20px; }" & ASCII.LF &
       ".overflowy { overflow-y: auto; }" & ASCII.LF &
       ".overflowx { overflow-x: hidden; }" & ASCII.LF &
       ".overflowmix { overflow: hidden; overflow-y: auto; }" & ASCII.LF &
       ".overflowmix2 { overflow-y: auto; overflow: hidden; }" & ASCII.LF &
       ".flexextra { flex-wrap: wrap; align-self: stretch; align-content: space-between; }" & ASCII.LF &
       ".gridcontainer { display: grid; grid-template-columns: repeat(3, 1fr); grid-template-rows: 1fr 1fr; gap: 10px; }" & ASCII.LF &
       ".gridmixed { display: grid; grid-template-columns: auto auto 1fr; }" & ASCII.LF &
       ".gridgaps { display: grid; row-gap: 4px; column-gap: 14px; }" & ASCII.LF &
       ".gridgapover { display: grid; gap: 10px; row-gap: 4px; }" & ASCII.LF &
       --  Same class twice: the second block cascades onto the first.
       ".gapcas1 { gap: 10px; }" & ASCII.LF &
       ".gapcas1 { row-gap: 4px; }" & ASCII.LF &
       ".gapcas2 { row-gap: 4px; }" & ASCII.LF &
       ".gapcas2 { column-gap: 14px; }" & ASCII.LF &
       ".gapcas3 { row-gap: 4px; column-gap: 14px; }" & ASCII.LF &
       ".gapcas3 { gap: 7px; }" & ASCII.LF &
       ".gapcas4 { row-gap: 4px; gap: 10px; }" & ASCII.LF &
       ".griditem { grid-column: 1 / 3; grid-row: span 2; }" & ASCII.LF &
       ".shadowtest { box-shadow: none; }" & ASCII.LF &
       ".pad1 { padding: 5px; }" & ASCII.LF &
       ".margin3 { margin: 1px 2px 3px; }" & ASCII.LF &
       ".displayvals { display: inline-flex; }" & ASCII.LF &
       ".linepx { line-height: 20px; }" & ASCII.LF &
       ".linenormal { line-height: normal; }" & ASCII.LF &
       ".widthauto { width: auto; }" & ASCII.LF &
       ".basisauto { flex-basis: auto; }" & ASCII.LF &
       ".basiscontent { flex-basis: content; }" & ASCII.LF &
       ".borderlong { border-top-width: 2px; border-left-color: red; border-bottom-style: dotted; border-top-left-radius: 9px; }" & ASCII.LF &
       ".borderside { border: 1px solid #333; border-top: 2px dashed red; }" & ASCII.LF &
       ".borderorder1 { border: 1px solid #333; border-left-width: 4px; }" & ASCII.LF &
       ".borderorder2 { border-left-width: 4px; border: 1px solid #333; }" & ASCII.LF &
       ".borderradiusorder { border-radius: 4px; border-top-left-radius: 9px; }" & ASCII.LF &
       ".borderradiusorder2 { border-top-left-radius: 9px; border-radius: 4px; }" & ASCII.LF &
       ".pressed-pseudo { background-color: rgb(11, 22, 33); }" & ASCII.LF &
       ".pressed-pseudo:active { background-color: rgb(44, 55, 66); }" & ASCII.LF &
       ".insets { position: absolute; top: 10px; right: 20%; bottom: 5dp; left: 3dip; }" & ASCII.LF &
       ".insetauto { top: auto; left: 8px; }" & ASCII.LF &
       ".textpart::text { color: rgb(100, 200, 50); font-size: 18px; }" & ASCII.LF &
       ".gradbot  { background-image: linear-gradient(to bottom, #fff, #000); }" & ASCII.LF &
       ".gradright { background-image: linear-gradient(to right, rgb(255,0,0), rgb(0,0,255)); }" & ASCII.LF &
       ".grad45   { background-image: linear-gradient(45deg, red, blue); }" & ASCII.LF &
       ".graddef  { background-image: linear-gradient(red, blue); }" & ASCII.LF &
       ".grad3    { background-image: linear-gradient(to bottom, red 0%, green 50%, blue 100%); }" & ASCII.LF &
       ".gradbad  { background-image: linear-gradient(to bottom, red); }" & ASCII.LF;

   --  ===== Custom Properties (@property, :root, var()) =====
   --  Placed in a nested procedure so its large Part_Style_Array/Resolved_Style
   --  locals live in a separate frame instead of the main procedure frame.
   procedure Test_Var_Resolution is
   begin
      --  @property default with var() reference
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           "@property --primary { initial-value: red; } "
           & ".btn { color: var(--primary); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "@property+var() CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "btn");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Red),
                    "var(--primary) should resolve to red from @property default");
         end;
      end;

      --  :root overrides @property default
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           "@property --c { initial-value: red; } "
           & ":root { --c: blue; } "
           & ".x { color: var(--c); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, ":root override CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Blue),
                    "var(--c) should resolve to blue from :root override");
         end;
      end;

      --  var() with fallback when variable is missing
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ".x { color: var(--missing, green); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "var() fallback CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Green),
                    "var(--missing, green) should use fallback green");
         end;
      end;

      --  Multiple var() in one value
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ":root { --x: 4px; --y: 8px; } "
           & ".x { padding: var(--x) var(--y); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "multiple var() CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Padding.Kind = Axis,
                    "padding from two var() should be Axis kind");
            Test_Support.Assert (R.Padding.Vertical.Amount = 4.0
                    and then R.Padding.Vertical.Unit = Px,
                    "padding vertical from var(--x) should be 4px");
            Test_Support.Assert (R.Padding.Horizontal.Amount = 8.0
                    and then R.Padding.Horizontal.Unit = Px,
                    "padding horizontal from var(--y) should be 8px");
         end;
      end;

      --  :root block should not leak as a parsed rule
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ":root { --c: red; } .x { color: var(--c); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, ":root no-leak CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Red),
                    ":root var should resolve and .x should get color red");
         end;
      end;

      --  Runtime access to :root metadata and resolved custom properties
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ":root { color: red; font-size: 20dp; --accent: blue; } "
           & ".x { color: var(--accent); }";
         Meta      : Adi.CSS_Parser.Stylesheet_Metadata;
         Saved_Root : constant Pixel_Type := Get_Active_Root_Font_Size;
      begin
         Set_Active_Root_Font_Size (37.0);
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, ":root metadata CSS should parse");
         Test_Support.Assert (Adi.CSS_Parser.Has_Custom_Property (Var_Sheet, "--accent"),
                 "Has_Custom_Property should report :root custom property");
         Test_Support.Assert (Adi.CSS_Parser.Get_Custom_Property (Var_Sheet, "--accent") = "blue",
                 "Get_Custom_Property should return resolved value");

         Meta := Adi.CSS_Parser.Get_Metadata (Var_Sheet);
         Test_Support.Assert (Meta.Has_Root_Style,
                 "Get_Metadata should report :root style presence");
         Test_Support.Assert (Meta.Has_Root_Font_Size,
                 "Get_Metadata should report :root font-size");
         Test_Support.Assert (Meta.Root_Font_Size.Unit = Dip
                 and then Nearly_Equal (Meta.Root_Font_Size.Amount, 20.0),
                 "Get_Metadata should store :root font-size");

         declare
            Root_Resolved : constant Resolved_Style :=
              Compute_Resolved
                (Meta.Root_Styles (Main_Part).Style,
                 No_States,
                 No_States);
         begin
            Test_Support.Assert (Root_Resolved.Color = (Kind => Named, Name => Red),
                    "Get_Metadata should keep :root style properties");
         end;
         Test_Support.Assert (Get_Active_Root_Font_Size = 37.0,
                 "Load_String should not mutate active root font size");
         Set_Active_Root_Font_Size (Saved_Root);
      end;

      --  Non-root custom property should be stripped
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ".x { --local: red; color: blue; }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "non-root custom prop CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Blue),
                    "non-root custom prop stripped, color should be blue");
         end;
      end;

      --  Unresolved var() with no fallback should parse and not crash
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ".x { color: var(--undefined); background-color: green; }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "unresolved var() CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Color = (Kind => Named, Name => Green),
                    "unresolved var() should not prevent other properties");
         end;
      end;

      --  Recursive var() resolution (--a references --b)
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ":root { --a: var(--b); --b: green; } "
           & ".x { color: var(--a); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "recursive var() CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Green),
                    "var(--a) -> var(--b) -> green should resolve to green");
         end;
      end;

      --  Nested var() in fallback
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ":root { --b: blue; } "
           & ".x { color: var(--a, var(--b)); }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "nested var() fallback CSS should parse");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Color = (Kind => Named, Name => Blue),
                    "var(--a, var(--b)) should fallback to blue");
         end;
      end;

      --  Cyclic var() should not crash
      declare
         Var_Sheet : Adi.CSS_Parser.Stylesheet;
         Var_OK    : Boolean;
         Var_CSS   : constant String :=
           ":root { --a: var(--b); --b: var(--a); } "
           & ".x { color: var(--a); background-color: red; }";
      begin
         Adi.CSS_Parser.Load_String (Var_Sheet, Var_CSS, Var_OK);
         Test_Support.Assert (Var_OK, "cyclic var() CSS should parse without crash");
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Var_Sheet, "x");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Color = (Kind => Named, Name => Red),
                    "non-cyclic property should still resolve");
         end;
      end;
   end Test_Var_Resolution;

   -----------------------------------------------------------------
   --  Font-family tests (require SDL_ttf initialization)
   --  Nested procedure to keep Part_Style_Array locals off the main frame.
   -----------------------------------------------------------------
   procedure Test_Font_Family is
      use Adi.SDL;
      Sdl_OK : C_bool;
      Ttf_OK : C_bool;
      SDL_Ready : Boolean := False;
   begin
      Put_Line ("");
      Put_Line ("Font-family tests:");

      Sdl_OK := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      if Boolean (Sdl_OK) then
         Ttf_OK := Adi.SDL.TTF.TTF_Init;
         SDL_Ready := Boolean (Ttf_OK);
      end if;

      if not SDL_Ready then
         Put_Line ("  [SKIP] SDL/TTF init failed - skipping font-family tests");
      else
         --  Load three variants of Open Sans
         declare
            H1 : constant Font_Handle :=
              Adi.Font.Load ("vendor/open-sans/static/OpenSans-Regular.ttf");
            H2 : constant Font_Handle :=
              Adi.Font.Load ("vendor/open-sans/static/OpenSans-Bold.ttf");
            H3 : constant Font_Handle :=
              Adi.Font.Load ("vendor/open-sans/static/OpenSans-Italic.ttf");
         begin
            Test_Support.Assert (H1 /= Null_Font,
                    "Load Regular should return valid handle");
            Test_Support.Assert (H2 = H1,
                    "Load Bold should return same handle (same family)");
            Test_Support.Assert (H3 = H1,
                    "Load Italic should return same handle (same family)");

            --  Lookup by name
            Test_Support.Assert (Adi.Font.Lookup ("Open Sans") = H1,
                    "Lookup 'Open Sans' should find handle");
            Test_Support.Assert (Adi.Font.Lookup ("open sans") = H1,
                    "Lookup case-insensitive should find handle");
            Test_Support.Assert (Adi.Font.Lookup ("Unknown Font") = Null_Font,
                    "Lookup unknown should return Null_Font");

            --  Register custom name
            Adi.Font.Register_Name ("My Alias", H1);
            Test_Support.Assert (Adi.Font.Lookup ("my alias") = H1,
                    "Register_Name + Lookup should work");
         end;

         --  Load with explicit name override
         declare
            H4 : constant Font_Handle :=
              Adi.Font.Load ("vendor/open-sans/static/OpenSans-Medium.ttf",
                             "Custom Name");
         begin
            Test_Support.Assert (H4 /= Null_Font,
                    "Load with Name should return valid handle");
            Test_Support.Assert (Adi.Font.Lookup ("custom name") = H4,
                    "Load(Path,Name) should register under provided name");
         end;

         --  CSS font-family parsing and resolution
         declare
            CSS2 : constant String :=
              ".fontfam { font-family: ""Open Sans""; }" & ASCII.LF &
              ".fontfam_fallback { font-family: ""Unknown"", ""Open Sans""; }" & ASCII.LF &
              ".fontfam_unknown { font-family: ""NoSuchFont""; }" & ASCII.LF &
              ".fontfam_case { font-family: ""open sans""; }" & ASCII.LF;
            Sheet2 : Adi.CSS_Parser.Stylesheet;
            OK2    : Boolean := False;
         begin
            Adi.CSS_Parser.Load_String (Sheet2, CSS2, OK2);
            Test_Support.Assert (OK2, "font-family CSS should parse");

            if OK2 then
               declare
                  FF_Styles : constant Part_Style_Array :=
                    Adi.CSS_Parser.Styles_For_Class (Sheet2, "fontfam");
                  FF_R : constant Resolved_Style :=
                    Compute_Resolved (FF_Styles (Main_Part).Style,
                                      No_States, No_States);
                  Expected : constant Font_Handle := Adi.Font.Lookup ("Open Sans");
               begin
                  Test_Support.Assert (FF_R.Font_Family = Expected,
                          "font-family: 'Open Sans' should resolve to correct handle");
               end;

               declare
                  FB_Styles : constant Part_Style_Array :=
                    Adi.CSS_Parser.Styles_For_Class (Sheet2, "fontfam_fallback");
                  FB_R : constant Resolved_Style :=
                    Compute_Resolved (FB_Styles (Main_Part).Style,
                                      No_States, No_States);
                  Expected : constant Font_Handle := Adi.Font.Lookup ("Open Sans");
               begin
                  Test_Support.Assert (FB_R.Font_Family = Expected,
                          "font-family comma fallback should resolve to Open Sans");
               end;

               declare
                  UK_Styles : constant Part_Style_Array :=
                    Adi.CSS_Parser.Styles_For_Class (Sheet2, "fontfam_unknown");
                  UK_R : constant Resolved_Style :=
                    Compute_Resolved (UK_Styles (Main_Part).Style,
                                      No_States, No_States);
               begin
                  Test_Support.Assert (UK_R.Font_Family = Null_Font,
                          "font-family unknown should resolve to Null_Font");
               end;

               declare
                  CI_Styles : constant Part_Style_Array :=
                    Adi.CSS_Parser.Styles_For_Class (Sheet2, "fontfam_case");
                  CI_R : constant Resolved_Style :=
                    Compute_Resolved (CI_Styles (Main_Part).Style,
                                      No_States, No_States);
                  Expected : constant Font_Handle := Adi.Font.Lookup ("Open Sans");
               begin
                  Test_Support.Assert (CI_R.Font_Family = Expected,
                          "font-family case-insensitive should resolve correctly");
               end;
            end if;
         end;

         --  By_Handle path: existing Set(Font_Handle) should still work
         declare
            H : constant Font_Handle := Adi.Font.Lookup ("Open Sans");
            Rules : Style_Rules := (Font_Family => Set (H), others => <>);
            R     : constant Resolved_Style := Resolve (Rules);
         begin
            Test_Support.Assert (R.Font_Family = H,
                    "Set(Font_Handle) should resolve to same handle");
         end;

         --  Find: already-loaded font returns cached handle (no scan needed)
         declare
            H : constant Font_Handle := Adi.Font.Find ("Open Sans");
            Expected : constant Font_Handle := Adi.Font.Lookup ("Open Sans");
         begin
            Test_Support.Assert (H = Expected,
                    "Find for already-loaded font should return cached handle");
         end;

         --  Find: unknown font returns Null_Font
         Test_Support.Assert (Adi.Font.Find ("ZZZNoSuchFont999") = Null_Font,
                 "Find for non-existent font should return Null_Font");

         --  Find: negative cache prevents repeated scans (second call fast)
         Test_Support.Assert (Adi.Font.Find ("ZZZNoSuchFont999") = Null_Font,
                 "Find for cached miss should return Null_Font without rescan");

         --  Enable_System_Font_Search: CSS should resolve system fonts
         Adi.Font.Enable_System_Font_Search;

         declare
            CSS3 : constant String :=
              ".sysfont { font-family: ""Open Sans""; }" & ASCII.LF &
              ".sysfont_miss { font-family: ""ZZZNoSuchFont999""; }" & ASCII.LF;
            Sheet3 : Adi.CSS_Parser.Stylesheet;
            OK3    : Boolean := False;
         begin
            Adi.CSS_Parser.Load_String (Sheet3, CSS3, OK3);
            Test_Support.Assert (OK3, "system font CSS should parse");

            if OK3 then
               --  Already-loaded font still resolves via Find
               declare
                  S : constant Part_Style_Array :=
                    Adi.CSS_Parser.Styles_For_Class (Sheet3, "sysfont");
                  R : constant Resolved_Style :=
                    Compute_Resolved (S (Main_Part).Style, No_States, No_States);
                  Expected : constant Font_Handle :=
                    Adi.Font.Lookup ("Open Sans");
               begin
                  Test_Support.Assert (R.Font_Family = Expected,
                          "Enable_System_Font_Search: loaded font resolves via CSS");
               end;

               --  Unknown font still returns default (negative cache hit)
               declare
                  S : constant Part_Style_Array :=
                    Adi.CSS_Parser.Styles_For_Class (Sheet3, "sysfont_miss");
                  R : constant Resolved_Style :=
                    Compute_Resolved (S (Main_Part).Style, No_States, No_States);
               begin
                  Test_Support.Assert (R.Font_Family = Null_Font,
                          "Enable_System_Font_Search: cached miss returns Null_Font");
               end;
            end if;
         end;
      end if;
   end Test_Font_Family;

   --  -----------------------------------------------------------------------
   --  Linear gradient parsing
   --  Nested procedure to keep Part_Style_Array locals off the main frame.
   --  -----------------------------------------------------------------------
   procedure Test_Gradients is
      Grad_Sheet : Adi.CSS_Parser.Stylesheet;
      Grad_OK    : Boolean := False;
      Grad_CSS   : constant String :=
         ".gradbot   { background-image: linear-gradient(to bottom, #fff, #000); }" & ASCII.LF &
         ".gradright  { background-image: linear-gradient(to right, rgb(255,0,0), rgb(0,0,255)); }" & ASCII.LF &
         ".grad45    { background-image: linear-gradient(45deg, red, blue); }" & ASCII.LF &
         ".graddef   { background-image: linear-gradient(red, blue); }" & ASCII.LF &
         ".grad3     { background-image: linear-gradient(to bottom, red 0%, green 50%, blue 100%); }" & ASCII.LF &
         ".gradbad   { background-image: linear-gradient(to bottom, red); }" & ASCII.LF &
         ".gradbogus { background-image: linear-gradient(red, bogus, blue); }" & ASCII.LF &
         ".grad1turn  { background-image: linear-gradient(1turn, red, blue); }" & ASCII.LF &
         ".grad_rad   { background-image: linear-gradient(1.5708rad, red, blue); }" & ASCII.LF &
         ".grad100g   { background-image: linear-gradient(100grad, red, blue); }" & ASCII.LF &
         ".grad200g   { background-image: linear-gradient(200grad, red, blue); }" & ASCII.LF &
         --  Multi-line gradient values (as produced by CSS autoformatters)
         ".gradml_dir { background-image: linear-gradient(" & ASCII.LF &
         "    to right," & ASCII.LF &
         "    rgb(245, 158, 11)," & ASCII.LF &
         "    rgb(239, 68, 68)" & ASCII.LF &
         "); }" & ASCII.LF &
         ".gradml_deg { background-image: linear-gradient(" & ASCII.LF &
         "    45deg," & ASCII.LF &
         "    red," & ASCII.LF &
         "    blue" & ASCII.LF &
         "); }" & ASCII.LF &
         ".gradml_def { background-image: linear-gradient(" & ASCII.LF &
         "    red," & ASCII.LF &
         "    blue" & ASCII.LF &
         "); }" & ASCII.LF;
   begin
      Adi.CSS_Parser.Load_String (Grad_Sheet, Grad_CSS, Grad_OK);
      Test_Support.Assert (Grad_OK, "gradient CSS should parse without errors");

      if Grad_OK then
         --  to bottom → angle 180
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradbot");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "to bottom: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 180.0),
                    "to bottom: angle = 180.0");
            Test_Support.Assert (R.Background_Image.Gradient.all.Stop_Count = 2,
                    "to bottom: 2 stops");
         end;

         --  to right → angle 90, inner commas in rgb() handled
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradright");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "to right: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 90.0),
                    "to right: angle = 90.0");
            Test_Support.Assert (R.Background_Image.Gradient.all.Stop_Count = 2,
                    "to right: 2 stops");
         end;

         --  45deg
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "grad45");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "45deg: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 45.0),
                    "45deg: angle = 45.0");
         end;

         --  No direction token → default angle 180
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "graddef");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "default angle: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 180.0),
                    "default angle: angle = 180.0");
         end;

         --  3-stop with explicit positions
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "grad3");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
            G : Linear_Gradient_Value renames R.Background_Image.Gradient.all;
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "3-stop: kind = Linear_Gradient_Image");
            Test_Support.Assert (G.Stop_Count = 3, "3-stop: 3 stops");
            Test_Support.Assert (G.Stops (1).Has_Pos
                    and then Nearly_Equal (G.Stops (1).Position, 0.0),
                    "3-stop: stop 1 position = 0.0");
            Test_Support.Assert (G.Stops (2).Has_Pos
                    and then Nearly_Equal (G.Stops (2).Position, 0.5),
                    "3-stop: stop 2 position = 0.5");
            Test_Support.Assert (G.Stops (3).Has_Pos
                    and then Nearly_Equal (G.Stops (3).Position, 1.0),
                    "3-stop: stop 3 position = 1.0");
         end;

         --  Too few stops → stays No_Image (no gradient)
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradbad");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = No_Image,
                    "too-few-stops: stays No_Image");
         end;

         --  Malformed middle stop → whole gradient rejected, stays No_Image
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradbogus");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = No_Image,
                    "malformed-stop: whole gradient rejected, stays No_Image");
         end;

         --  1turn → angle 360
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "grad1turn");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "1turn: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 360.0),
                    "1turn: angle = 360.0");
            Test_Support.Assert (R.Background_Image.Gradient.all.Stop_Count = 2,
                    "1turn: 2 stops");
         end;

         --  1.5708rad ≈ 90° (π/2)
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "grad_rad");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "1.5708rad: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 90.0,
                                  Eps => 0.01),
                    "1.5708rad: angle ~= 90.0");
         end;

         --  100grad = 90°
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "grad100g");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "100grad: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 90.0),
                    "100grad: angle = 90.0");
         end;

         --  200grad = 180°  (key regression: must not mis-parse as "rad")
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "grad200g");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "200grad: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 180.0),
                    "200grad: angle = 180.0 (not mis-parsed as rad)");
         end;

         --  Multi-line: direction keyword on its own line
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradml_dir");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "multiline to right: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 90.0),
                    "multiline to right: angle = 90.0");
            Test_Support.Assert (R.Background_Image.Gradient.all.Stop_Count = 2,
                    "multiline to right: 2 stops");
         end;

         --  Multi-line: deg angle on its own line
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradml_deg");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "multiline 45deg: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 45.0),
                    "multiline 45deg: angle = 45.0");
         end;

         --  Multi-line: no direction token (implicit default)
         declare
            S : constant Part_Style_Array :=
              Adi.CSS_Parser.Styles_For_Class (Grad_Sheet, "gradml_def");
            R : constant Resolved_Style :=
              Compute_Resolved (S (Main_Part).Style, No_States, No_States);
         begin
            Test_Support.Assert (R.Background_Image.Kind = Linear_Gradient_Image,
                    "multiline default: kind = Linear_Gradient_Image");
            Test_Support.Assert (Nearly_Equal (R.Background_Image.Gradient.all.Angle, 180.0),
                    "multiline default: angle = 180.0");
            Test_Support.Assert (R.Background_Image.Gradient.all.Stop_Count = 2,
                    "multiline default: 2 stops");
         end;
      end if;
   end Test_Gradients;

   procedure Test_Card is
      Styles      : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "card");
      Main_Normal : constant Resolved_Style :=
        Compute_Resolved (Styles (Main_Part).Style, No_States, No_States);
      Main_Hover  : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Hovered => True],
         No_States);
      Main_Focus  : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Focused => True],
         No_States);
      Main_Selected : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Selected => True],
         No_States);
      Main_Disabled : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Disabled => True],
         No_States);
      Label_Base : constant Resolved_Style :=
        Compute_Resolved (Styles (Label_Part).Style, No_States, No_States);
      Label_Part_Hover : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         No_States,
         [No_States with delta State_Hovered => True]);
      Label_Part_Press : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         No_States,
         [No_States with delta State_Pressed => True]);
      Label_Widget_Focus : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         [No_States with delta State_Focused => True],
         No_States);
      Label_Widget_Hover : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         [No_States with delta State_Hovered => True],
         No_States);
   begin
      Test_Support.Assert (Is_RGBA_Color (Main_Normal.Background_Color, 16, 34, 51, 0.8),
              "RGBA background-color should parse");
      Test_Support.Assert (Is_RGB_Color (Main_Normal.Color, 3, 4, 5),
              "Color should reflect :enabled override on normal state");
      Test_Support.Assert (Main_Normal.Padding.Kind = Axis
              and then Main_Normal.Padding.Vertical.Amount = 4.0
              and then Main_Normal.Padding.Horizontal.Amount = 8.0,
              "Padding 2-value shorthand should parse");
      Test_Support.Assert (Main_Normal.Margin.Kind = Per_Side
              and then Main_Normal.Margin.Sides (Top).Amount = 1.0
              and then Main_Normal.Margin.Sides (Right).Amount = 2.0
              and then Main_Normal.Margin.Sides (Bottom).Amount = 3.0
              and then Main_Normal.Margin.Sides (Left).Amount = 4.0,
              "Margin 4-value shorthand should parse");
      Test_Support.Assert (Main_Normal.Border_Width.Kind = Gap_Uniform
              and then Main_Normal.Border_Width.All_Edges.Amount = 4.0,
              "Normal state should reflect :not(:disabled) border-width override");
      Test_Support.Assert (Main_Normal.Border_Style.Kind = Gap_Uniform
              and then Main_Normal.Border_Style.All_Edges = Solid,
              "Border-style should parse");
      Test_Support.Assert (Main_Normal.Border_Color.Kind = Gap_Uniform
              and then Is_RGB_Color (Main_Normal.Border_Color.All_Edges, 68, 85, 102),
              "Border-color hex should parse");
      Test_Support.Assert (Main_Normal.Border_Radius.Kind = Per_Corner
              and then Main_Normal.Border_Radius.Corners (Top_Left).Amount = 3.0
              and then Main_Normal.Border_Radius.Corners (Top_Right).Amount = 6.0,
              "Border-radius 2-value shorthand should parse");
      Test_Support.Assert (Main_Normal.Width.Kind = Fixed and then Main_Normal.Width.Size.Amount = 120.0,
              "Width should parse fixed size");
      Test_Support.Assert (Main_Normal.Min_Height.Kind = Fixed and then Main_Normal.Min_Height.Size.Amount = 40.0,
              "Min-height should parse fixed size");
      Test_Support.Assert (Main_Normal.Font_Size.Amount = 13.0 and then Main_Normal.Font_Size.Unit = Px,
              "Font-size should parse");
      Test_Support.Assert (Main_Normal.Font_Weight = Weight_Bold,
              "Font-weight 700 should parse to Weight_Bold");
      Test_Support.Assert (Main_Normal.Font_Style = Style_Italic,
              "Font-style italic should parse");
      Test_Support.Assert (Main_Normal.Text_Align = Text_Center,
              "Text-align center should parse");
      Test_Support.Assert (Main_Normal.Text_Wrap_Mode = TWM_Nowrap,
              "Text-wrap-mode nowrap should parse");
      Test_Support.Assert (Main_Normal.Display = Flex and then Main_Normal.Position = Relative,
              "Display and position should parse");
      Test_Support.Assert (Main_Normal.Overflow_X = Overflow_Hidden
              and then Main_Normal.Overflow_Y = Overflow_Hidden,
              "Overflow hidden should parse");
      Test_Support.Assert (Nearly_Equal (Float (Main_Normal.Opacity), 0.75),
              "Opacity should parse");
      Test_Support.Assert (Main_Normal.Cursor = Cursor_Pointer,
              "Cursor pointer should parse");
      Test_Support.Assert (Main_Normal.Flex_Direction = Column
              and then Main_Normal.Justify_Content = Center
              and then Main_Normal.Align_Items = Flex_End,
              "Flex container properties should parse");
      Test_Support.Assert (Main_Normal.Gap.Kind = Gap_Separate
              and then Main_Normal.Gap.Row_Gap.Amount = 5.0
              and then Main_Normal.Gap.Column_Gap.Amount = 9.0,
              "Gap 2-value should parse to separate row/column gaps");
      Test_Support.Assert (Nearly_Equal (Float (Main_Normal.Flex_Grow), 2.0)
              and then Nearly_Equal (Float (Main_Normal.Flex_Shrink), 3.0)
              and then Main_Normal.Flex_Basis.Kind = Fixed
              and then Main_Normal.Flex_Basis.Size.Amount = 11.0
              and then Main_Normal.Order = 7,
              "Flex item properties should parse");
      Test_Support.Assert (Main_Normal.Box_Shadow.Offset_X.Amount = 2.0
              and then Main_Normal.Box_Shadow.Offset_Y.Amount = 4.0
              and then Main_Normal.Box_Shadow.Blur_Radius.Amount = 6.0
              and then Is_RGBA_Color (Main_Normal.Box_Shadow.Color, 10, 20, 30, 0.4),
              "Box-shadow should parse lengths and rgba color");
      Test_Support.Assert (Nearly_Equal (Main_Normal.Transition.Duration, 0.5)
              and then Main_Normal.Transition.Easing = Ease_In_Out
              and then Main_Normal.Transition.Properties (Prop_Background_Color)
              and then not Main_Normal.Transition.Properties (Prop_Color),
              "Transition should parse ms duration, easing, and property filter");
      Test_Support.Assert (Is_RGB_Color (Main_Hover.Background_Color, 1, 2, 3),
              "Widget hover should apply .card:hover");
      Test_Support.Assert (Nearly_Equal (Float (Main_Hover.Opacity), 0.5),
              "Widget hover should apply .card::main:hover override");
      Test_Support.Assert (Main_Disabled.Border_Width.Kind = Per_Edge
              and then Main_Disabled.Border_Width.Edges (Top).Amount = 1.0,
              "Disabled state should not match :not(:disabled) or :enabled rules");
      Test_Support.Assert (Is_Named_Color (Main_Disabled.Color, White),
              "Disabled state should keep base color when :enabled rule does not match");
      Test_Support.Assert (Main_Focus.Border_Color.Kind = Gap_Uniform
              and then Is_RGB_Color (Main_Focus.Border_Color.All_Edges, 9, 9, 9),
              "Focus state should apply .card:focus");
      Test_Support.Assert (Is_RGB_Color (Main_Selected.Background_Color, 7, 8, 9),
              "Selected state should apply .card:selected");
      Test_Support.Assert (Is_RGB_Color (Main_Normal.Color, 3, 4, 5),
              "Enabled and not-disabled rules should affect normal state");
      Test_Support.Assert (Is_RGB_Color (Label_Base.Color, 50, 60, 70),
              "Label base style should parse");
      Test_Support.Assert (Is_RGB_Color (Label_Part_Hover.Color, 220, 38, 38),
              "Label part hover should be part-scoped");
      Test_Support.Assert (Is_RGB_Color (Label_Part_Press.Color, 0, 0, 255),
              "Label part pressed should be part-scoped");
      Test_Support.Assert (Is_RGB_Color (Label_Widget_Focus.Color, 88, 77, 66),
              "Label focus pseudo should be widget-scoped");
      Test_Support.Assert (Is_RGB_Color (Label_Widget_Hover.Color, 50, 60, 70),
              "Label widget hover should keep base color (not part hover)");
   end Test_Card;

   procedure Test_Panel_Submit_Tag is
      Panel_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "panel");
      Submit_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Id (Sheet, "submit");
      Tag_Styles    : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Tag (Sheet, "button");
      Panel_Main  : constant Resolved_Style :=
        Compute_Resolved (Panel_Styles (Main_Part).Style, No_States, No_States);
      Submit_Main : constant Resolved_Style :=
        Compute_Resolved (Submit_Styles (Main_Part).Style, No_States, No_States);
      Tag_Main    : constant Resolved_Style :=
        Compute_Resolved (Tag_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Is_RGBA_Color (Panel_Main.Background_Color, 16, 34, 51, 0.8),
              "Comma selector should duplicate base styles to .panel");
      Test_Support.Assert (Is_RGB_Color (Submit_Main.Background_Color, 12, 34, 56),
              "#id selector should map to id-style lookup");
      Test_Support.Assert (Is_RGB_Color (Tag_Main.Color, 9, 8, 7),
              "Tag selector should map to tag-style lookup");
   end Test_Panel_Submit_Tag;

   procedure Test_Seconds_Sides_UL is
      Seconds_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "seconds");
      Sides_Styles   : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "sides");
      UL_Styles      : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Tag (Sheet, "ul");
      Seconds_Main : constant Resolved_Style :=
        Compute_Resolved (Seconds_Styles (Main_Part).Style, No_States, No_States);
      Sides_Main   : constant Resolved_Style :=
        Compute_Resolved (Sides_Styles (Main_Part).Style, No_States, No_States);
      UL_Main      : constant Resolved_Style :=
        Compute_Resolved (UL_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Is_Named_Color (UL_Main.Color, Red),
              "Grouped tag selector should apply base declarations");
      Test_Support.Assert (UL_Main.Padding.Kind = Gap_Uniform
              and then UL_Main.Padding.All_Sides.Amount = 2.0,
              "Repeated grouped tag selector blocks should merge declarations");
      Test_Support.Assert (Nearly_Equal (Seconds_Main.Transition.Duration, 1.25)
              and then Seconds_Main.Transition.Easing = Linear
              and then Seconds_Main.Transition.Properties (Prop_Opacity)
              and then not Seconds_Main.Transition.Properties (Prop_Background_Color),
              "Transition should parse seconds duration and linear easing");
      Test_Support.Assert (Sides_Main.Padding.Kind = Per_Side
              and then Sides_Main.Padding.Sides (Top).Amount = 1.0
              and then Sides_Main.Padding.Sides (Right).Amount = 2.0
              and then Sides_Main.Padding.Sides (Bottom).Amount = 3.0
              and then Sides_Main.Padding.Sides (Left).Amount = 11.0,
              "Padding side longhands should override shorthand per side");
      Test_Support.Assert (Sides_Main.Margin.Kind = Per_Side
              and then Sides_Main.Margin.Sides (Top).Amount = 9.0
              and then Sides_Main.Margin.Sides (Right).Amount = 5.0
              and then Sides_Main.Margin.Sides (Bottom).Amount = 5.0
              and then Sides_Main.Margin.Sides (Left).Amount = 5.0,
              "Margin side longhands should override shorthand per side");
   end Test_Seconds_Sides_UL;

   procedure Test_Listprobe is
      Listprobe_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe");
      Listprobe2_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe2");
      Listprobe_Main  : constant Resolved_Style :=
        Compute_Resolved (Listprobe_Styles (Main_Part).Style, No_States, No_States);
      Listprobe2_Main : constant Resolved_Style :=
        Compute_Resolved (Listprobe2_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Listprobe_Main.List_Style_Type.Kind = List_Style_Square,
              "list-style shorthand should parse list-style-type keyword");
      Test_Support.Assert (Listprobe_Main.List_Style_Image.Kind = List_Image_URL
              and then To_String (Listprobe_Main.List_Style_Image.URI) = "app://marker.svg",
              "list-style shorthand should parse list-style-image url");
      Test_Support.Assert (Listprobe_Main.List_Style_Position = List_Outside,
              "list-style shorthand should parse list-style-position keyword");
      Test_Support.Assert (Listprobe2_Main.List_Style_Type.Kind = List_Style_Custom_String
              and then To_String (Listprobe2_Main.List_Style_Type.Marker) = "-> ",
              "list-style shorthand should parse quoted custom marker text");
   end Test_Listprobe;

   procedure Test_Listprobe_Longhands is
      Listprobe3_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe3");
      Listprobe4_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe4");
      Listprobe3_Main : constant Resolved_Style :=
        Compute_Resolved (Listprobe3_Styles (Main_Part).Style, No_States, No_States);
      Listprobe4_Main : constant Resolved_Style :=
        Compute_Resolved (Listprobe4_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Listprobe3_Main.List_Style_Type.Kind = List_Style_Disc
              and then Listprobe3_Main.List_Style_Image.Kind = List_Image_None
              and then Listprobe3_Main.List_Style_Position = List_Inside,
              "list-style longhands should parse and resolve");
      Test_Support.Assert (Listprobe4_Main.List_Style_Type.Kind = List_Style_None
              and then Listprobe4_Main.List_Style_Image.Kind = List_Image_None,
              "list-style none shorthand should disable both type and image");
   end Test_Listprobe_Longhands;

   procedure Test_Svg_Colors is
      SvgNamed_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "svgnamed");
      SvgAlias_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "svgalias");
      SvgNamed_Main : constant Resolved_Style :=
        Compute_Resolved (SvgNamed_Styles (Main_Part).Style, No_States, No_States);
      SvgAlias_Main : constant Resolved_Style :=
        Compute_Resolved (SvgAlias_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Is_Named_Color (SvgNamed_Main.Color, Cornflower_Blue),
              "SVG named colors should parse to Named_Color enum values");
      Test_Support.Assert (Is_Named_Color (SvgNamed_Main.Background_Color, Light_Goldenrod_Yellow),
              "SVG named colors should parse for background-color");
      Test_Support.Assert (SvgNamed_Main.Border_Color.Kind = Gap_Uniform
              and then Is_Named_Color (SvgNamed_Main.Border_Color.All_Edges, Dark_Slate_Gray),
              "SVG named colors should parse for border-color");
      Test_Support.Assert (Is_Named_Color (SvgAlias_Main.Color, Gray),
              "grey alias should map to Gray enum");
   end Test_Svg_Colors;

   procedure Test_Svg_Aqua_Cyan is
      SvgAqua_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "svgaqua");
      SvgCyan_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "svgcyan");
      SvgAqua_Main : constant Resolved_Style :=
        Compute_Resolved (SvgAqua_Styles (Main_Part).Style, No_States, No_States);
      SvgCyan_Main : constant Resolved_Style :=
        Compute_Resolved (SvgCyan_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Is_Named_Color (SvgAqua_Main.Color, Aqua),
              "aqua keyword should parse");
      Test_Support.Assert (Is_Named_Color (SvgCyan_Main.Color, Cyan),
              "cyan keyword should parse");
   end Test_Svg_Aqua_Cyan;

   --  pix is an Adi unit, and must not be swallowed by the px branch
   --  that shares its last two characters.
   procedure Test_Pix_Unit is
      Pix_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "pixunit");
      Pix_Main   : constant Resolved_Style :=
        Compute_Resolved (Pix_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert
        (Pix_Main.Padding.Kind = Gap_Uniform
           and then Pix_Main.Padding.All_Sides.Unit = Pix
           and then Pix_Main.Padding.All_Sides.Amount = 3.0,
         "a pix length parses as Pix, not Px");
      Test_Support.Assert
        (Pix_Main.Border_Width.All_Edges.Unit = Pix
           and then Pix_Main.Border_Width.All_Edges.Amount = 1.0,
         "1pix is the hairline border width");
      Test_Support.Assert
        (Pix_Main.Grid_Column_Tracks.Count = 2
           and then Pix_Main.Grid_Column_Tracks.Tracks (1).Kind = Track_Pix
           and then Pix_Main.Grid_Column_Tracks.Tracks (1).Value = 40.0
           and then Pix_Main.Grid_Column_Tracks.Tracks (2).Kind = Track_Fr,
         "a pix grid track parses as its own kind");
   end Test_Pix_Unit;

   procedure Test_Missing_DP is
      Missing_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For (Sheet, "missing");
      DP_Styles      : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "dpunit");
      Missing_Main : constant Resolved_Style :=
        Compute_Resolved (Missing_Styles (Main_Part).Style, No_States, No_States);
      DP_Main      : constant Resolved_Style :=
        Compute_Resolved (DP_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (DP_Main.Padding.Kind = Gap_Uniform
              and then DP_Main.Padding.All_Sides.Unit = Dip
              and then DP_Main.Padding.All_Sides.Amount = 7.0,
              "dp length unit should parse as Dip");
      Test_Support.Assert (Missing_Main.Background_Color.Kind = Named
              and then Missing_Main.Background_Color.Name = Transparent,
              "Unknown class should return default/empty styles");
   end Test_Missing_DP;

   procedure Test_Outline is
      Outline_Long_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-long");
      Outline_Short_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-short");
      Outline_Long_Main  : constant Resolved_Style :=
        Compute_Resolved (Outline_Long_Styles (Main_Part).Style, No_States, No_States);
      Outline_Short_Main : constant Resolved_Style :=
        Compute_Resolved (Outline_Short_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Outline_Long_Main.Outline_Width.Amount = 3.0
              and then Outline_Long_Main.Outline_Width.Unit = Px,
              "outline-width longhand should parse");
      Test_Support.Assert (Outline_Long_Main.Outline_Style = Outline_Solid,
              "outline-style longhand should parse");
      Test_Support.Assert (Is_RGB_Color (Outline_Long_Main.Outline_Color, 100, 200, 50),
              "outline-color longhand should parse");
      Test_Support.Assert (Outline_Long_Main.Outline_Offset.Amount = 4.0
              and then Outline_Long_Main.Outline_Offset.Unit = Px,
              "outline-offset longhand should parse");
      Test_Support.Assert (Outline_Short_Main.Outline_Width.Amount = 2.0
              and then Outline_Short_Main.Outline_Width.Unit = Px,
              "outline shorthand should parse width");
      Test_Support.Assert (Outline_Short_Main.Outline_Style = Outline_Solid,
              "outline shorthand should parse style");
      Test_Support.Assert (Is_RGB_Color (Outline_Short_Main.Outline_Color, 208, 188, 255),
              "outline shorthand should parse rgb color");
   end Test_Outline;

   procedure Test_Outline_Offset_None is
      Outline_Offset_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-offset");
      Outline_None_Styles   : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-none");
      Outline_Offset_Main : constant Resolved_Style :=
        Compute_Resolved (Outline_Offset_Styles (Main_Part).Style, No_States, No_States);
      Outline_None_Main   : constant Resolved_Style :=
        Compute_Resolved (Outline_None_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Outline_Offset_Main.Outline_Width.Amount = 1.0,
              "outline shorthand width should parse for dashed test");
      Test_Support.Assert (Outline_Offset_Main.Outline_Style = Outline_Dashed,
              "outline shorthand should parse dashed style");
      Test_Support.Assert (Is_Named_Color (Outline_Offset_Main.Outline_Color, Red),
              "outline shorthand should parse named color");
      Test_Support.Assert (Outline_Offset_Main.Outline_Offset.Amount = 5.0,
              "outline-offset longhand should override after shorthand");
      Test_Support.Assert (Outline_None_Main.Outline_Style = Outline_None,
              "outline none shorthand should set style to none");
   end Test_Outline_Offset_None;

   procedure Test_Sizing is
      Sizing_Styles    : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "sizing");
      Textprops_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "textprops");
      Sizing_Main    : constant Resolved_Style :=
        Compute_Resolved (Sizing_Styles (Main_Part).Style, No_States, No_States);
      Textprops_Main : constant Resolved_Style :=
        Compute_Resolved (Textprops_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Sizing_Main.Height.Kind = Fixed and then Sizing_Main.Height.Size.Amount = 200.0,
              "height should parse");
      Test_Support.Assert (Sizing_Main.Min_Width.Kind = Fixed and then Sizing_Main.Min_Width.Size.Amount = 50.0,
              "min-width should parse");
      Test_Support.Assert (Sizing_Main.Max_Width.Kind = Fixed and then Sizing_Main.Max_Width.Size.Amount = 400.0,
              "max-width should parse");
      Test_Support.Assert (Sizing_Main.Max_Height.Kind = Fixed and then Sizing_Main.Max_Height.Size.Amount = 300.0,
              "max-height should parse");
      Test_Support.Assert (Textprops_Main.Text_Decoration = Decoration_Underline,
              "text-decoration underline should parse");
      Test_Support.Assert (Textprops_Main.White_Space = WS_Pre_Wrap,
              "white-space pre-wrap should parse");
      Test_Support.Assert (Textprops_Main.Text_Overflow = Overflow_Ellipsis,
              "text-overflow ellipsis should parse");
      Test_Support.Assert (Textprops_Main.Line_Height.Kind = LH_Number
              and then Nearly_Equal (Textprops_Main.Line_Height.Multiplier, 1.5),
              "line-height unitless multiplier should parse");
      Test_Support.Assert (Textprops_Main.Vertical_Align = VA_Middle,
              "vertical-align middle should parse");
   end Test_Sizing;

   procedure Test_Misc is
      Misc_Styles         : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "misc");
      MiscCollapse_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "misccollapse");
      Misc2_Styles        : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "misc2");
      Misc_Main         : constant Resolved_Style :=
        Compute_Resolved (Misc_Styles (Main_Part).Style, No_States, No_States);
      MiscCollapse_Main : constant Resolved_Style :=
        Compute_Resolved (MiscCollapse_Styles (Main_Part).Style, No_States, No_States);
      Misc2_Main        : constant Resolved_Style :=
        Compute_Resolved (Misc2_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Misc_Main.Visibility = Visibility_Hidden,
              "visibility hidden should parse");
      Test_Support.Assert (MiscCollapse_Main.Visibility = Visibility_Collapse,
              "visibility collapse should parse");
      Test_Support.Assert (Misc_Main.Object_Fit = Fit_Cover,
              "object-fit cover should parse");
      Test_Support.Assert (Misc_Main.Object_Position.Kind = Keyword_Pos
              and then Misc_Main.Object_Position.H_Keyword = Pos_Center
              and then Misc_Main.Object_Position.V_Keyword = Pos_Center,
              "object-position center center should parse");
      Test_Support.Assert (Misc2_Main.Object_Position.Kind = Length_Pos
              and then Misc2_Main.Object_Position.X_Offset.Amount = 10.0
              and then Misc2_Main.Object_Position.Y_Offset.Amount = 20.0,
              "object-position length pair should parse");
   end Test_Misc;

   procedure Test_Overflow is
      OverflowY_Styles    : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowy");
      OverflowX_Styles    : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowx");
      OverflowMix_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowmix");
      OverflowMix2_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowmix2");
      OverflowY_Main    : constant Resolved_Style :=
        Compute_Resolved (OverflowY_Styles (Main_Part).Style, No_States, No_States);
      OverflowX_Main    : constant Resolved_Style :=
        Compute_Resolved (OverflowX_Styles (Main_Part).Style, No_States, No_States);
      OverflowMix_Main  : constant Resolved_Style :=
        Compute_Resolved (OverflowMix_Styles (Main_Part).Style, No_States, No_States);
      OverflowMix2_Main : constant Resolved_Style :=
        Compute_Resolved (OverflowMix2_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (OverflowY_Main.Overflow_Y = Overflow_Auto
              and then OverflowY_Main.Overflow_X = Overflow_Visible,
              "overflow-y auto should apply vertical overflow only");
      Test_Support.Assert (OverflowX_Main.Overflow_X = Overflow_Hidden
              and then OverflowX_Main.Overflow_Y = Overflow_Visible,
              "overflow-x hidden should apply horizontal overflow only");
      Test_Support.Assert (OverflowMix_Main.Overflow_X = Overflow_Hidden
              and then OverflowMix_Main.Overflow_Y = Overflow_Auto,
              "overflow shorthand + overflow-y should resolve with longhand override");
      Test_Support.Assert (OverflowMix2_Main.Overflow_X = Overflow_Hidden
              and then OverflowMix2_Main.Overflow_Y = Overflow_Hidden,
              "overflow-y + overflow shorthand should resolve with shorthand override");
   end Test_Overflow;

   procedure Test_Flex_Grid is
      Flexextra_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "flexextra");
      Gridcon_Styles   : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gridcontainer");
      Gridmixed_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gridmixed");
      Griditem_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "griditem");
      Gridgaps_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gridgaps");
      Gridgapover_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gridgapover");
      Gapcas1_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gapcas1");
      Gapcas2_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gapcas2");
      Gapcas3_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gapcas3");
      Gapcas4_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "gapcas4");
      Flexextra_Main : constant Resolved_Style :=
        Compute_Resolved (Flexextra_Styles (Main_Part).Style, No_States, No_States);
      Gridcon_Main   : constant Resolved_Style :=
        Compute_Resolved (Gridcon_Styles (Main_Part).Style, No_States, No_States);
      Gridmixed_Main : constant Resolved_Style :=
        Compute_Resolved (Gridmixed_Styles (Main_Part).Style, No_States, No_States);
      Griditem_Main  : constant Resolved_Style :=
        Compute_Resolved (Griditem_Styles (Main_Part).Style, No_States, No_States);
      Gridgaps_Main  : constant Resolved_Style :=
        Compute_Resolved (Gridgaps_Styles (Main_Part).Style, No_States, No_States);
      Gridgapover_Main : constant Resolved_Style :=
        Compute_Resolved (Gridgapover_Styles (Main_Part).Style, No_States, No_States);
      Gapcas1_Main : constant Resolved_Style :=
        Compute_Resolved (Gapcas1_Styles (Main_Part).Style, No_States, No_States);
      Gapcas2_Main : constant Resolved_Style :=
        Compute_Resolved (Gapcas2_Styles (Main_Part).Style, No_States, No_States);
      Gapcas3_Main : constant Resolved_Style :=
        Compute_Resolved (Gapcas3_Styles (Main_Part).Style, No_States, No_States);
      Gapcas4_Main : constant Resolved_Style :=
        Compute_Resolved (Gapcas4_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Flexextra_Main.Flex_Wrap = Wrap,
              "flex-wrap wrap should parse");
      Test_Support.Assert (Flexextra_Main.Align_Self = Stretch,
              "align-self stretch should parse");
      Test_Support.Assert (Flexextra_Main.Align_Content = Space_Between,
              "align-content space-between should parse");
      Test_Support.Assert (Gridcon_Main.Display = Grid,
              "display grid should parse");
      Test_Support.Assert (Gridcon_Main.Grid_Columns = 3,
              "grid-template-columns repeat(3) should parse to 3");
      Test_Support.Assert (Gridcon_Main.Grid_Column_Tracks.Count = 3,
              "grid-template-columns repeat(3,1fr) track count should be 3");
      Test_Support.Assert (Gridcon_Main.Grid_Column_Tracks.Tracks (1).Kind = Track_Fr,
              "grid-template-columns repeat(3,1fr) track 1 kind should be Track_Fr");
      Test_Support.Assert (abs (Gridcon_Main.Grid_Column_Tracks.Tracks (1).Value - 1.0) < 0.001,
              "grid-template-columns repeat(3,1fr) track 1 value should be 1.0");
      Test_Support.Assert (Gridcon_Main.Grid_Column_Tracks.Tracks (3).Kind = Track_Fr,
              "grid-template-columns repeat(3,1fr) track 3 kind should be Track_Fr");
      Test_Support.Assert (Gridcon_Main.Grid_Rows = 2,
              "grid-template-rows should parse track count");
      Test_Support.Assert (Gridcon_Main.Gap.Kind = Gap_Uniform
              and then Gridcon_Main.Gap.All_Gap.Amount = 10.0,
              "gap 1-value should parse to uniform gap");
      Test_Support.Assert (Gridmixed_Main.Grid_Column_Tracks.Count = 3,
              "grid-template-columns auto auto 1fr track count should be 3");
      Test_Support.Assert (Gridmixed_Main.Grid_Column_Tracks.Tracks (1).Kind = Track_Auto,
              "grid-template-columns auto auto 1fr track 1 should be Track_Auto");
      Test_Support.Assert (Gridmixed_Main.Grid_Column_Tracks.Tracks (2).Kind = Track_Auto,
              "grid-template-columns auto auto 1fr track 2 should be Track_Auto");
      Test_Support.Assert (Gridmixed_Main.Grid_Column_Tracks.Tracks (3).Kind = Track_Fr,
              "grid-template-columns auto auto 1fr track 3 should be Track_Fr");
      Test_Support.Assert (abs (Gridmixed_Main.Grid_Column_Tracks.Tracks (3).Value - 1.0) < 0.001,
              "grid-template-columns auto auto 1fr track 3 fr value should be 1.0");
      Test_Support.Assert (Griditem_Main.Grid_Column = 1,
              "grid-column start should parse");
      Test_Support.Assert (Griditem_Main.Grid_Column_Span = 2,
              "grid-column span should parse from start/end shorthand");
      Test_Support.Assert (Griditem_Main.Grid_Row_Span = 2,
              "grid-row span should parse");

      --  The longhands write the two halves of one Gap value, so each has
      --  to keep what the other set.
      Test_Support.Assert (Gridgaps_Main.Gap.Kind = Gap_Separate
              and then Gridgaps_Main.Gap.Row_Gap.Amount = 4.0
              and then Gridgaps_Main.Gap.Column_Gap.Amount = 14.0,
              "row-gap and column-gap should parse into one separate gap");
      Test_Support.Assert (Gridgapover_Main.Gap.Kind = Gap_Separate
              and then Gridgapover_Main.Gap.Row_Gap.Amount = 4.0
              and then Gridgapover_Main.Gap.Column_Gap.Amount = 10.0,
              "row-gap should override only the row half of a preceding gap");

      --  The two axes are one property internally, so the cascade has to
      --  merge them per axis: a rule that names only one axis must not
      --  discard what an earlier matching rule said about the other.
      Test_Support.Assert (Get_Row_Gap (Gapcas1_Main.Gap) = 4.0
              and then Get_Column_Gap (Gapcas1_Main.Gap) = 10.0,
              "a later row-gap keeps the column gap of an earlier shorthand");
      Test_Support.Assert (Get_Row_Gap (Gapcas2_Main.Gap) = 4.0
              and then Get_Column_Gap (Gapcas2_Main.Gap) = 14.0,
              "row-gap and column-gap from separate rules combine");
      Test_Support.Assert (Get_Row_Gap (Gapcas3_Main.Gap) = 7.0
              and then Get_Column_Gap (Gapcas3_Main.Gap) = 7.0,
              "a later shorthand replaces both earlier longhands");
      Test_Support.Assert (Get_Row_Gap (Gapcas4_Main.Gap) = 10.0
              and then Get_Column_Gap (Gapcas4_Main.Gap) = 10.0,
              "a shorthand after a longhand in one rule wins on both axes");
   end Test_Flex_Grid;

   procedure Test_Shadow_Spacing is
      Shadow_Styles   : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "shadowtest");
      Pad1_Styles     : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "pad1");
      Margin3_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "margin3");
      Dispvals_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "displayvals");
      Shadow_Main   : constant Resolved_Style :=
        Compute_Resolved (Shadow_Styles (Main_Part).Style, No_States, No_States);
      Pad1_Main     : constant Resolved_Style :=
        Compute_Resolved (Pad1_Styles (Main_Part).Style, No_States, No_States);
      Margin3_Main  : constant Resolved_Style :=
        Compute_Resolved (Margin3_Styles (Main_Part).Style, No_States, No_States);
      Dispvals_Main : constant Resolved_Style :=
        Compute_Resolved (Dispvals_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Shadow_Main.Box_Shadow.Blur_Radius.Amount = 0.0
              and then Shadow_Main.Box_Shadow.Offset_X.Amount = 0.0,
              "box-shadow none should resolve to zero shadow");
      Test_Support.Assert (Pad1_Main.Padding.Kind = Gap_Uniform
              and then Pad1_Main.Padding.All_Sides.Amount = 5.0,
              "padding 1-value should parse as uniform");
      Test_Support.Assert (Margin3_Main.Margin.Kind = Per_Side
              and then Margin3_Main.Margin.Sides (Top).Amount = 1.0
              and then Margin3_Main.Margin.Sides (Right).Amount = 2.0
              and then Margin3_Main.Margin.Sides (Bottom).Amount = 3.0
              and then Margin3_Main.Margin.Sides (Left).Amount = 2.0,
              "margin 3-value shorthand should parse (left = right)");
      Test_Support.Assert (Dispvals_Main.Display = Inline_Flex,
              "display inline-flex should parse");
   end Test_Shadow_Spacing;

   procedure Test_Line_Height is
      Linepx_Styles     : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "linepx");
      Linenormal_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "linenormal");
      Linepx_Main     : constant Resolved_Style :=
        Compute_Resolved (Linepx_Styles (Main_Part).Style, No_States, No_States);
      Linenormal_Main : constant Resolved_Style :=
        Compute_Resolved (Linenormal_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Linepx_Main.Line_Height.Kind = LH_Length
              and then Linepx_Main.Line_Height.Height.Amount = 20.0,
              "line-height with px unit should parse");
      Test_Support.Assert (Linenormal_Main.Line_Height.Kind = LH_Normal,
              "line-height normal should parse");
   end Test_Line_Height;

   procedure Test_Width_Basis is
      Widthauto_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "widthauto");
      Basisauto_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "basisauto");
      Basiscont_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "basiscontent");
      Widthauto_Main : constant Resolved_Style :=
        Compute_Resolved (Widthauto_Styles (Main_Part).Style, No_States, No_States);
      Basisauto_Main : constant Resolved_Style :=
        Compute_Resolved (Basisauto_Styles (Main_Part).Style, No_States, No_States);
      Basiscont_Main : constant Resolved_Style :=
        Compute_Resolved (Basiscont_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Widthauto_Main.Width.Kind = Auto,
              "width auto should parse");
      Test_Support.Assert (Basisauto_Main.Flex_Basis.Kind = Auto,
              "flex-basis auto should parse");
      Test_Support.Assert (Basiscont_Main.Flex_Basis.Kind = Content,
              "flex-basis content should parse");
   end Test_Width_Basis;

   procedure Test_Border_Longhand is
      BorderLong_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "borderlong");
      BorderSide_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "borderside");
      BorderLong_Main : constant Resolved_Style :=
        Compute_Resolved (BorderLong_Styles (Main_Part).Style, No_States, No_States);
      BorderSide_Main : constant Resolved_Style :=
        Compute_Resolved (BorderSide_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (BorderLong_Main.Border_Width.Kind = Per_Edge
              and then BorderLong_Main.Border_Width.Edges (Top).Amount = 2.0
              and then BorderLong_Main.Border_Width.Edges (Right).Amount = 0.0
              and then BorderLong_Main.Border_Width.Edges (Bottom).Amount = 0.0
              and then BorderLong_Main.Border_Width.Edges (Left).Amount = 0.0,
              "border-*-width longhands should set only the target edge");
      Test_Support.Assert (BorderLong_Main.Border_Style.Kind = Per_Edge
              and then BorderLong_Main.Border_Style.Edges (Bottom) = Dotted
              and then BorderLong_Main.Border_Style.Edges (Top) = None_Style,
              "border-*-style longhands should set only the target edge");
      Test_Support.Assert (BorderLong_Main.Border_Color.Kind = Per_Edge
              and then Is_Named_Color (BorderLong_Main.Border_Color.Edges (Left), Red)
              and then Is_Named_Color (BorderLong_Main.Border_Color.Edges (Top), Current_Color),
              "border-*-color longhands should set only the target edge");
      Test_Support.Assert (BorderLong_Main.Border_Radius.Kind = Per_Corner
              and then BorderLong_Main.Border_Radius.Corners (Top_Left).Amount = 9.0
              and then BorderLong_Main.Border_Radius.Corners (Top_Right).Amount = 0.0,
              "border-*-radius longhands should set only the target corner");
      Test_Support.Assert (BorderSide_Main.Border_Width.Kind = Per_Edge
              and then BorderSide_Main.Border_Width.Edges (Top).Amount = 2.0
              and then BorderSide_Main.Border_Width.Edges (Right).Amount = 1.0
              and then BorderSide_Main.Border_Width.Edges (Bottom).Amount = 1.0
              and then BorderSide_Main.Border_Width.Edges (Left).Amount = 1.0,
              "border shorthand + border-top shorthand should merge width by side");
      Test_Support.Assert (BorderSide_Main.Border_Style.Kind = Per_Edge
              and then BorderSide_Main.Border_Style.Edges (Top) = Dashed
              and then BorderSide_Main.Border_Style.Edges (Right) = Solid
              and then BorderSide_Main.Border_Style.Edges (Bottom) = Solid
              and then BorderSide_Main.Border_Style.Edges (Left) = Solid,
              "border shorthand + border-top shorthand should merge style by side");
      Test_Support.Assert (BorderSide_Main.Border_Color.Kind = Per_Edge
              and then Is_Named_Color (BorderSide_Main.Border_Color.Edges (Top), Red)
              and then Is_RGB_Color (BorderSide_Main.Border_Color.Edges (Right), 51, 51, 51)
              and then Is_RGB_Color (BorderSide_Main.Border_Color.Edges (Bottom), 51, 51, 51)
              and then Is_RGB_Color (BorderSide_Main.Border_Color.Edges (Left), 51, 51, 51),
              "border shorthand + border-top shorthand should merge color by side");
   end Test_Border_Longhand;

   procedure Test_Border_Order is
      BorderOrder1_Styles       : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "borderorder1");
      BorderOrder2_Styles       : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "borderorder2");
      BorderRadiusOrder_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "borderradiusorder");
      BorderRadiusOrder2_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "borderradiusorder2");
      BorderOrder1_Main       : constant Resolved_Style :=
        Compute_Resolved (BorderOrder1_Styles (Main_Part).Style, No_States, No_States);
      BorderOrder2_Main       : constant Resolved_Style :=
        Compute_Resolved (BorderOrder2_Styles (Main_Part).Style, No_States, No_States);
      BorderRadiusOrder_Main  : constant Resolved_Style :=
        Compute_Resolved (BorderRadiusOrder_Styles (Main_Part).Style, No_States, No_States);
      BorderRadiusOrder2_Main : constant Resolved_Style :=
        Compute_Resolved (BorderRadiusOrder2_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (BorderOrder1_Main.Border_Width.Kind = Per_Edge
              and then BorderOrder1_Main.Border_Width.Edges (Top).Amount = 1.0
              and then BorderOrder1_Main.Border_Width.Edges (Right).Amount = 1.0
              and then BorderOrder1_Main.Border_Width.Edges (Bottom).Amount = 1.0
              and then BorderOrder1_Main.Border_Width.Edges (Left).Amount = 4.0,
              "border then border-left-width should keep longhand override");
      Test_Support.Assert (BorderOrder2_Main.Border_Width.Kind = Gap_Uniform
              and then BorderOrder2_Main.Border_Width.All_Edges.Amount = 1.0,
              "border-left-width then border should let shorthand override later");
      Test_Support.Assert (BorderRadiusOrder_Main.Border_Radius.Kind = Per_Corner
              and then BorderRadiusOrder_Main.Border_Radius.Corners (Top_Left).Amount = 9.0
              and then BorderRadiusOrder_Main.Border_Radius.Corners (Top_Right).Amount = 4.0
              and then BorderRadiusOrder_Main.Border_Radius.Corners (Bottom_Right).Amount = 4.0
              and then BorderRadiusOrder_Main.Border_Radius.Corners (Bottom_Left).Amount = 4.0,
              "border-radius then border-top-left-radius should keep longhand corner override");
      Test_Support.Assert (BorderRadiusOrder2_Main.Border_Radius.Kind = Gap_Uniform
              and then BorderRadiusOrder2_Main.Border_Radius.All_Corners.Amount = 4.0,
              "border-top-left-radius then border-radius should let shorthand override later");
   end Test_Border_Order;

   procedure Test_Pressed_Pseudo is
      Pressed_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "pressed-pseudo");
      Pressed_Normal : constant Resolved_Style :=
        Compute_Resolved (Pressed_Styles (Main_Part).Style, No_States, No_States);
      Pressed_Active : constant Resolved_Style := Compute_Resolved (
         Pressed_Styles (Main_Part).Style,
         [No_States with delta State_Pressed => True],
         No_States);
   begin
      Test_Support.Assert (Is_RGB_Color (Pressed_Normal.Background_Color, 11, 22, 33),
              ":active pseudo base should parse");
      Test_Support.Assert (Is_RGB_Color (Pressed_Active.Background_Color, 44, 55, 66),
              ":active pseudo should map to pressed state");
   end Test_Pressed_Pseudo;

   procedure Test_Reload is
      use Adi.Widget.Box;
      Reload_Sheet : Adi.CSS_Parser.Stylesheet;
      Reloaded     : Boolean := False;
      Reload_OK    : Boolean := False;
      Css_Path     : constant String := "/tmp/adi_css_parser_test.css";
      Box          : Box_Handle;
      V1           : constant String :=
        ".reloadable { background-color: rgb(10, 20, 30); }" & ASCII.LF;
      V2           : constant String :=
        ".reloadable { background-color: rgb(40, 50, 60); border-width: 3px; }" & ASCII.LF;
   begin
      Write_Text_File (Css_Path, V1);
      Adi.CSS_Parser.Load_File (Reload_Sheet, Css_Path, Reload_OK);
      Test_Support.Assert (Reload_OK, "Load_File should succeed for valid CSS file");
      Test_Support.Assert (Adi.CSS_Parser.Get_Source_Path (Reload_Sheet) = Css_Path,
              "Get_Source_Path should track file path");

      Box := Create_Handle;
      Adi.CSS_Parser.Bind_Class (Reload_Sheet, "reloadable", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (R.Background_Color, 10, 20, 30),
                 "Bind_Class should apply current stylesheet styles");
      end;

      delay 1.1;
      Write_Text_File (Css_Path, V2);
      Adi.CSS_Parser.Reload_If_Changed (Reload_Sheet, Reloaded, Reload_OK);
      Test_Support.Assert (Reload_OK, "Reload_If_Changed should succeed");
      Test_Support.Assert (Reloaded, "Reload_If_Changed should detect modified file");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (R.Background_Color, 40, 50, 60),
                 "Reload should reapply new background color to bound widget");
         Test_Support.Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 3.0,
                 "Reload should reapply new border width to bound widget");
      end;

      Adi.CSS_Parser.Reload_If_Changed (Reload_Sheet, Reloaded, Reload_OK);
      Test_Support.Assert (Reload_OK and then not Reloaded,
              "Reload_If_Changed should report no reload when file unchanged");
   end Test_Reload;

   procedure Test_Error_Handling is
      Bad_Sheet      : Adi.CSS_Parser.Stylesheet;
      Bad_OK         : Boolean := False;
      Dummy_Reloaded : Boolean := False;
      Dummy_Success  : Boolean := False;
   begin
      Adi.CSS_Parser.Load_String (Bad_Sheet, ".oops { color: red; ", Bad_OK);
      Test_Support.Assert (not Bad_OK, "Load_String should fail on unclosed CSS block");
      Test_Support.Assert (Adi.CSS_Parser.Get_Last_Error (Bad_Sheet) /= "",
              "Parser error text should be populated after malformed CSS");

      Adi.CSS_Parser.Load_String
        (Bad_Sheet,
         ".ok { color: rgb(1,2,3); transition: background-color nope ease; } .ok::unknown-part { color: red; } .ok { nonsense-prop: 5; }",
         Bad_OK);
      Test_Support.Assert (Bad_OK,
              "Load_String should tolerate unknown part selectors/properties when valid rules exist");
      Test_Support.Assert (Adi.CSS_Parser.Get_Last_Error (Bad_Sheet) = "",
              "Last error should be cleared after a successful parse");
      Test_Support.Assert (Adi.CSS_Parser.Has_Class (Bad_Sheet, "ok"),
              "Valid selector should still be available after mixed-validity CSS");

      declare
         OK_Styles : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Bad_Sheet, "ok");
         OK_Main   : constant Resolved_Style :=
           Compute_Resolved (OK_Styles (Main_Part).Style, No_States, No_States);
      begin
         Test_Support.Assert (Is_RGB_Color (OK_Main.Color, 1, 2, 3),
                 "Valid declaration should apply even when other declarations are unsupported");
         Test_Support.Assert (Nearly_Equal (OK_Main.Transition.Duration, 0.0),
                 "Invalid transition value should be ignored without affecting valid declarations");
      end;

      Adi.CSS_Parser.Load_File (Bad_Sheet, "/tmp/this_file_should_not_exist_adi_css.css", Bad_OK);
      Test_Support.Assert (not Bad_OK, "Load_File should fail for missing CSS file");
      Test_Support.Assert (Adi.CSS_Parser.Get_Last_Error (Bad_Sheet) /= "",
              "Load_File missing-path failure should provide error text");

      Adi.CSS_Parser.Reload_If_Changed (Bad_Sheet, Dummy_Reloaded, Dummy_Success);
      Test_Support.Assert (Dummy_Success and then not Dummy_Reloaded,
              "Reload_If_Changed should no-op when no source file was successfully loaded");
   end Test_Error_Handling;

   procedure Test_Insets is
      Inset_Styles : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "insets");
      Auto_Styles  : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "insetauto");
      Inset_Main : constant Resolved_Style :=
        Compute_Resolved (Inset_Styles (Main_Part).Style, No_States, No_States);
      Auto_Main  : constant Resolved_Style :=
        Compute_Resolved (Auto_Styles (Main_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Inset_Main.Position = Absolute,
              "Inset test: position should be absolute");
      Test_Support.Assert (Inset_Main.Top.Kind = Fixed
              and then Inset_Main.Top.Length.Amount = 10.0
              and then Inset_Main.Top.Length.Unit = Px,
              "top: 10px should parse");
      Test_Support.Assert (Inset_Main.Right.Kind = Fixed
              and then Inset_Main.Right.Length.Amount = 20.0
              and then Inset_Main.Right.Length.Unit = Pct,
              "right: 20% should parse");
      Test_Support.Assert (Inset_Main.Bottom.Kind = Fixed
              and then Inset_Main.Bottom.Length.Amount = 5.0
              and then Inset_Main.Bottom.Length.Unit = Dip,
              "bottom: 5dp should parse as Dip");
      Test_Support.Assert (Inset_Main.Left.Kind = Fixed
              and then Inset_Main.Left.Length.Amount = 3.0
              and then Inset_Main.Left.Length.Unit = Dip,
              "left: 3dip should parse as Dip");
      Test_Support.Assert (Auto_Main.Top.Kind = Auto,
              "top: auto should parse as Auto");
      Test_Support.Assert (Auto_Main.Left.Kind = Fixed
              and then Auto_Main.Left.Length.Amount = 8.0
              and then Auto_Main.Left.Length.Unit = Px,
              "left: 8px should parse when top: auto");
   end Test_Insets;

   procedure Test_Text_Part is
      Text_Styles   : constant Part_Style_Array :=
        Adi.CSS_Parser.Styles_For_Class (Sheet, "textpart");
      Text_Resolved : constant Resolved_Style :=
        Compute_Resolved (Text_Styles (Text_Part).Style, No_States, No_States);
   begin
      Test_Support.Assert (Text_Styles (Text_Part).Enabled,
              "::text part should be enabled for .textpart");
      Test_Support.Assert (Text_Resolved.Color = (Kind => RGB, R => 100, G => 200, B => 50),
              "::text part color should parse");
      Test_Support.Assert (Text_Resolved.Font_Size.Amount = 18.0,
              "::text part font-size should parse");
   end Test_Text_Part;

begin
   Test_Support.Start_Suite ("CSS parser test");

   Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
   Test_Support.Assert (OK, "Load_String should parse CSS content");
   if not OK then
      Put_Line ("Parser error: " & Adi.CSS_Parser.Get_Last_Error (Sheet));
      return;
   end if;

   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "card"), "Has_Class should find '.card'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "panel"), "Has_Class should include comma selector '.panel'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Id (Sheet, "submit"), "Has_Id should parse '#submit' key");
   Test_Support.Assert (Adi.CSS_Parser.Has_Tag (Sheet, "button"), "Has_Tag should parse bare tag selector");
   Test_Support.Assert (Adi.CSS_Parser.Has (Sheet, Adi.CSS_Parser.Class_Selector, "card"),
           "Has(kind,name) should find class selector");
   Test_Support.Assert (Adi.CSS_Parser.Has (Sheet, Adi.CSS_Parser.Id_Selector, "submit"),
           "Has(kind,name) should find id selector");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "dpunit"), "Has_Class should parse '.dpunit'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Tag (Sheet, "li"), "Has_Tag should parse grouped tag selector 'li'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Tag (Sheet, "ul"), "Has_Tag should parse grouped tag selector 'ul'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Tag (Sheet, "p"), "Has_Tag should parse grouped tag selector 'p'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe"), "Has_Class should parse '.listprobe'");
    Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe2"), "Has_Class should parse '.listprobe2'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe3"), "Has_Class should parse '.listprobe3'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe4"), "Has_Class should parse '.listprobe4'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgnamed"), "Has_Class should parse '.svgnamed'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgalias"), "Has_Class should parse '.svgalias'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgaqua"), "Has_Class should parse '.svgaqua'");
   Test_Support.Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgcyan"), "Has_Class should parse '.svgcyan'");
   Test_Support.Assert (not Adi.CSS_Parser.Has_Class (Sheet, "missing"), "Has_Class should be false for unknown class");
   Test_Support.Assert (not Adi.CSS_Parser.Has_Id (Sheet, "card"), "Has_Id should not match class selector");

   Test_Card;
   Test_Panel_Submit_Tag;
   Test_Seconds_Sides_UL;
   Test_Listprobe;
   Test_Listprobe_Longhands;
   Test_Svg_Colors;
   Test_Svg_Aqua_Cyan;
   Test_Missing_DP;
   Test_Pix_Unit;

   Test_Outline;
   Test_Outline_Offset_None;
   Test_Sizing;
   Test_Misc;
   Test_Overflow;
   Test_Flex_Grid;
   Test_Shadow_Spacing;
   Test_Line_Height;
   Test_Width_Basis;
   Test_Border_Longhand;
   Test_Border_Order;
   Test_Pressed_Pseudo;


   Test_Reload;

   Test_Error_Handling;

   Test_Insets;

   Test_Text_Part;

   Test_Var_Resolution;

   Test_Font_Family;

   Test_Gradients;

   Test_Support.Finish;
end Css_Parser_Test;
