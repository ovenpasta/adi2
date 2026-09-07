with Ada.Environment_Variables;
with Ada.Text_IO;          use Ada.Text_IO;
with Adi.SDL;
with Adi.SDL.PixelFormat;  use Adi.SDL.PixelFormat;
with Adi.SDL.Render;       use Adi.SDL.Render;
with Adi.SDL.Surface;      use Adi.SDL.Surface;
with Adi.SDL.TTF;      use Adi.SDL.TTF;
with Adi.SDL.TTF.TextEngine; use Adi.SDL.TTF.TextEngine;
with Interfaces.C.Strings;
with Interfaces.C;      use Interfaces.C;
with Adi.Build_Target;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Core;
with Adi.Font;
with Adi.Font.Testing;
with Adi.Render;
with Adi.Widget;
with Adi.Widget.Label;
with Test_Support;

procedure Font_Test is
   Sdl_OK   : Adi.SDL.C_bool;
   Ttf_OK   : Adi.SDL.C_bool;

   use type Adi.Font.Byte_Count;
   use type Adi.Font.Event_Count;

   Probe_Path : constant String :=
     "vendor/open-sans/static/OpenSans-Regular.ttf";

   --  A key of its own per Skip, so a section can open as many faces as
   --  it needs without colliding with another's.
   function Face (Family : Font_Handle;
                  Skip   : Natural;
                  Size   : Float := 16.0) return TTF_Font_Access is
     (Adi.Font.Get_TTF_Font
        (Adi.Font.Make_Attributes
           (Family     => Family,
            Size       => Size,
            Weight     => Weight_Normal,
            Style      => Style_Normal,
            Decoration => Decoration_None,
            Line_Skip  => Skip)));

   --  Idle faces age out over two frames, so a sweep is two of them.
   procedure Sweep is
   begin
      Adi.Font.Advance_Frame;
      Adi.Font.Advance_Frame;
   end Sweep;

   --  Everything unpinned, gone, so a section starts from a known count.
   procedure Drain is
   begin
      Adi.Font.Set_Face_Budget (0);
      Sweep;
   end Drain;

   --  The thirteen names CSS Fonts 4 §2.1.1 defines, in its own order.
   type Family_Name_Ref is access constant String;
   type Family_Name_List is array (Positive range <>) of Family_Name_Ref;

   CSS_Generics : constant Family_Name_List :=
     [new String'("serif"),
      new String'("sans-serif"),
      new String'("monospace"),
      new String'("cursive"),
      new String'("fantasy"),
      new String'("system-ui"),
      new String'("ui-serif"),
      new String'("ui-sans-serif"),
      new String'("ui-monospace"),
      new String'("ui-rounded"),
      new String'("math"),
      new String'("emoji"),
      new String'("fangsong")];

   --  A name no system carries, so what happens to it says which path
   --  the resolver took.
   Unknown_Family : constant String := "Nothing Is Installed Under This";

   function Resolved_Family (Family : String) return Font_Handle is
      Rules : Style_Rules;
   begin
      Rules.Font_Family := Set_Font_Family (Family);
      return Resolve (Rules).Font_Family;
   end Resolved_Family;

   procedure Check (Name : String; H : Font_Handle; Expect_Found : Boolean) is
   begin
      Test_Support.Assert
        ((H /= Null_Font) = Expect_Found,
         "Find (" & Name & ") -> handle"
         & Font_Handle'Image (H)
         & (if Expect_Found then " (expected non-zero)"
                            else " (expected zero)"));
   end Check;

begin
   Sdl_OK := Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO);
   if not Boolean (Sdl_OK) then
      Test_Support.Assert (False, "SDL_Init failed");
      Test_Support.Finish;
      return;
   end if;
   Ttf_OK := Adi.SDL.TTF.TTF_Init;
   if not Boolean (Ttf_OK) then
      Test_Support.Assert (False, "TTF_Init failed");
      Test_Support.Finish;
      return;
   end if;

   ---------------------------------------------------------------------
   --  Pinned fallback
   ---------------------------------------------------------------------

   --  First, because the fallback is resolved once and cached: any check
   --  below that reaches for it would settle the answer this one asks for.
   Test_Support.Section ("ADI_FALLBACK_FONT overrides the platform search");
   declare
      Pinned : constant String :=
        "vendor/open-sans/static/OpenSans-Regular.ttf";
      Sample : constant String := "Hello World!";
      Size   : constant Float := 16.0;
      use type Adi.Core.Size_2D;
      use type Adi.Core.Pixel_Type;
   begin
      Ada.Environment_Variables.Set ("ADI_FALLBACK_FONT", Pinned);
      declare
         --  Measured rather than compared by path: the metrics are what
         --  a caller of the pin is buying, and a platform face that
         --  happened to measure alike would be no problem.
         Explicit : constant Font_Handle := Adi.Font.Load (Pinned);
         Fell_Back : constant Adi.Core.Size_2D :=
           Adi.Font.Measure_Text (Null_Font, Sample, Size);
         Asked_For : constant Adi.Core.Size_2D :=
           Adi.Font.Measure_Text (Explicit, Sample, Size);
      begin
         Put_Line ("  fallback " & Fell_Back.Width'Image
                   & " x" & Fell_Back.Height'Image
                   & "   pinned " & Asked_For.Width'Image
                   & " x" & Asked_For.Height'Image);
         --  Asserted before the comparison: a path this test failed to find would let both sides fall through to the platform fallback and agree, passing without proving anything.
         Test_Support.Assert
           (Explicit /= Null_Font,
            "the pinned file loads, relative to the repository root");
         Test_Support.Assert
           (Asked_For.Width > 0.0 and then Asked_For.Height > 0.0,
            "the pinned file measures text");
         Test_Support.Assert
           (Fell_Back = Asked_For,
            "text with no font measures as the pinned file, rather than "
            & "as whichever face the platform ships");
      end;
   end;

   ---------------------------------------------------------------------
   --  CSS generic families
   ---------------------------------------------------------------------

   Test_Support.Section ("generic families resolve without being installed");
   declare
      use type Font_Handle;

      function Via_CSS (Family : String) return Font_Handle is
         Rules : Style_Rules;
      begin
         Rules.Font_Family := Set_Font_Family (Family);
         return Resolve (Rules).Font_Family;
      end Via_CSS;

      --  Named rather than searched for, and deliberately one the
      --  platform list also names: it is installed, so failing to
      --  resolve it says something about the mode rather than about
      --  the machine.
      Installed_Family : constant String :=
        (case Adi.Build_Target.Platform is
            when Adi.Build_Target.Linux   => "DejaVu Sans Mono",
            when Adi.Build_Target.macOS   => "Menlo",
            when Adi.Build_Target.Windows => "Consolas");

      --  Asked first, and it matters: resolving a generic loads its
      --  candidate and registers it under its family name, after which
      --  this would resolve for the wrong reason.
      Installed_By_Name : constant Font_Handle := Via_CSS (Installed_Family);

      Mono  : constant Font_Handle := Via_CSS ("monospace");
      Sans  : constant Font_Handle := Via_CSS ("sans-serif");
      Serif : constant Font_Handle := Via_CSS ("serif");
   begin
      --  Runs before Enable_System_Font_Search, and this is what says so:
      --  an ordinary family that is installed does not resolve yet, so a
      --  generic that does cannot be resolving as an ordinary name.
      Test_Support.Assert
        (Installed_By_Name = Null_Font,
         "an installed family does not resolve in registry-only mode");
      Test_Support.Assert
        (Mono /= Null_Font,
         "monospace resolves to a face with arbitrary family lookup"
         & " still closed");
      Test_Support.Assert
        (Sans /= Null_Font and then Serif /= Null_Font,
         "and so do sans-serif and serif");
      Test_Support.Assert
        (Mono /= Sans,
         "monospace is not merely the default face under another name");

      --  Asking again must not scan again. Nothing observable counts
      --  scans, so this stands on the second answer being the first.
      Test_Support.Assert
        (Via_CSS ("monospace") = Mono,
         "asking again gives the same face rather than a second one"
         & " loaded from the same file");

      Test_Support.Assert
        (Via_CSS ("MonoSpace") = Mono,
         "and the name is matched case-insensitively");
   end;

   Test_Support.Section ("the UI generics reach a face of their own kind");
   declare
      Sys_UI   : constant Font_Handle := Resolved_Family ("system-ui");
      UI_Sans  : constant Font_Handle := Resolved_Family ("ui-sans-serif");
      UI_Serif : constant Font_Handle := Resolved_Family ("ui-serif");
      UI_Mono  : constant Font_Handle := Resolved_Family ("ui-monospace");
      Rounded  : constant Font_Handle := Resolved_Family ("ui-rounded");
      Mono     : constant Font_Handle := Resolved_Family ("monospace");
   begin
      Test_Support.Assert
        (Sys_UI /= Null_Font and then UI_Sans /= Null_Font
           and then UI_Serif /= Null_Font and then Rounded /= Null_Font,
         "the UI generics resolve with arbitrary family lookup still"
         & " closed, the way the CSS 2.1 three do");
      Test_Support.Assert
        (UI_Mono = Mono,
         "ui-monospace reaches the platform's monospace face");
      Test_Support.Assert
        (UI_Sans /= Mono,
         "and ui-sans-serif reaches a different one, so the kind the"
         & " name asks for is what answers");
      Test_Support.Assert
        (Resolved_Family ("UI-MonoSpace") = UI_Mono,
         "the new names are matched case-insensitively too");
   end;

   Test_Support.Section
     ("registry-only mode leaves the font directories alone");
   declare
      Ignored : Font_Handle;
   begin
      for Name of CSS_Generics loop
         Ignored := Resolved_Family (Name.all);
         Test_Support.Assert
           (not Adi.Font.Testing.Searched_As_Family (Name.all),
            Name.all & " is answered from its own candidate table");
      end loop;

      Ignored := Resolved_Family (Unknown_Family);
      Test_Support.Assert
        (Ignored = Null_Font
           and then not Adi.Font.Testing.Searched_As_Family (Unknown_Family),
         "and an ordinary name the registry has never heard of is"
         & " skipped rather than searched for");
   end;

   Test_Support.Section ("a registered face wins over the platform list");
   declare
      use type Font_Handle;

      function Via_CSS (Family : String) return Font_Handle is
         Rules : Style_Rules;
      begin
         Rules.Font_Family := Set_Font_Family (Family);
         return Resolve (Rules).Font_Family;
      end Via_CSS;

      Before : constant Font_Handle := Via_CSS ("monospace");
      Chosen : constant Font_Handle :=
        Adi.Font.Load ("vendor/open-sans/static/OpenSans-Regular.ttf",
                       "the chosen mono");
   begin
      if Chosen = Null_Font then
         Test_Support.Assert (False, "the fixture font loads");
      else
         Adi.Font.Register_Name ("monospace", Chosen);
         Test_Support.Assert
           (Via_CSS ("monospace") = Chosen
              and then Via_CSS ("monospace") /= Before,
            "An application that registers a face for the generic gets"
            & " that face: the platform list is what answers when nobody"
            & " has said otherwise");
      end if;
   end;

   Test_Support.Section ("an unknown family still falls through a list");
   declare
      use type Font_Handle;
      Rules : Style_Rules;
   begin
      Rules.Font_Family := Set_Font_Family ("No Such Face, monospace");
      Test_Support.Assert
        (Resolve (Rules).Font_Family /= Null_Font,
         "a comma list skips what it cannot find and lands on the"
         & " generic behind it");
   end;


   Adi.Font.Enable_System_Font_Search;

   Test_Support.Section
     ("a generic is never searched for as a family of that name");
   declare
      Ignored : Font_Handle;
   begin
      --  A section above binds a face to "monospace", and a bound name
      --  answers ahead of the generic tables, which would leave that
      --  one iteration reporting on the registry instead. Every name is
      --  put back to unbound so each reaches the resolver's full
      --  length.
      for Name of CSS_Generics loop
         Adi.Font.Testing.Forget_Name (Name.all);
      end loop;

      --  With the search open, a name the resolver leaves unplaced walks every font directory for a family that lives only in the stylesheet.
      for Name of CSS_Generics loop
         Ignored := Resolved_Family (Name.all);
         Test_Support.Assert
           (not Adi.Font.Testing.Searched_As_Family (Name.all),
            Name.all & " resolves through the generic tables, leaving"
            & " the font directories alone");
      end loop;

      Ignored := Resolved_Family ("UI-Rounded");
      Test_Support.Assert
        (not Adi.Font.Testing.Searched_As_Family ("UI-Rounded"),
         "which the case of the name makes no difference to");

      --  Which of the thirteen the running machine has a face for is
      --  its own business, so this is reported rather than asserted.
      for Name of CSS_Generics loop
         Put_Line
           ("  " & Name.all & " -> "
            & Font_Handle'Image (Resolved_Family (Name.all)));
      end loop;

      --  The other half of the reading: an ordinary name does take the
      --  walk, so the assertions above stand on the path taken rather
      --  than on a probe that answers False to everything.
      Ignored := Resolved_Family (Unknown_Family);
      Test_Support.Assert
        (Ignored = Null_Font
           and then Adi.Font.Testing.Searched_As_Family (Unknown_Family),
         "an ordinary name the system has not got is searched for once"
         & " and remembered as a miss");
   end;

   Test_Support.Section ("a face registered under a generic's own name wins");
   declare
      Chosen : constant Font_Handle :=
        Adi.Font.Load ("vendor/open-sans/static/OpenSans-Regular.ttf",
                       "the chosen generic");
   begin
      if Chosen = Null_Font then
         Test_Support.Assert (False, "the fixture font loads");
      else
         for Name of CSS_Generics loop
            Adi.Font.Register_Name (Name.all, Chosen);
            Test_Support.Assert
              (Resolved_Family (Name.all) = Chosen,
               "an application that names a face for " & Name.all
               & " gets that face");
         end loop;
      end if;
   end;

   case Adi.Build_Target.Platform is
      when Adi.Build_Target.macOS =>
         Put_Line ("Test: macOS system fonts");
         Check ("Helvetica", Adi.Font.Find ("Helvetica"),      True);
         Check ("Menlo",     Adi.Font.Find ("Menlo"),          True);
         Check ("Arial",     Adi.Font.Find ("Arial"),          True);
      when Adi.Build_Target.Linux =>
         Put_Line ("Test: Linux system fonts");
         --  DejaVu / Noto are standard on Debian/Fedora/Arch; if neither is
         --  installed (minimal CI image) skip rather than fail.
         declare
            DJ : constant Font_Handle := Adi.Font.Find ("DejaVu Sans");
            NS : constant Font_Handle := Adi.Font.Find ("Noto Sans");
         begin
            if DJ = Null_Font and NS = Null_Font then
               Put_Line ("  [SKIP] no DejaVu Sans or Noto Sans installed");
            else
               Check ("DejaVu Sans or Noto Sans",
                      (if DJ /= Null_Font then DJ else NS), True);
            end if;
         end;
      when Adi.Build_Target.Windows =>
         Put_Line ("Test: Windows system fonts");
         Check ("Segoe UI",  Adi.Font.Find ("Segoe UI"),       True);
         Check ("Arial",     Adi.Font.Find ("Arial"),          True);
   end case;

   Put_Line ("Test: missing font");
   Check ("ThisDoesNotExist",
          Adi.Font.Find ("ThisDoesNotExist"), False);

   --  Wrapped measurement reports the text's own width, not the width it
   --  was allowed to use. A label that returns its wrap width as its
   --  preferred width claims the whole slot it was given, and the slot
   --  then keeps it that wide on the next pass.
   Put_Line ("Test: wrapped measurement does not report the wrap width");
   declare
      use type Adi.Core.Pixel_Type;
      DJ    : constant Font_Handle := Adi.Font.Find ("DejaVu Sans");
      NS    : constant Font_Handle := Adi.Font.Find ("Noto Sans");
      Fam   : constant Font_Handle := (if DJ /= Null_Font then DJ else NS);
      Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Fam,
           Size       => 16.0,
           Weight     => Weight_Normal,
           Style      => Style_Normal,
           Decoration => Decoration_None);
      Word  : constant String := "Submit";
      Flat  : constant Adi.Core.Size_2D :=
        Adi.Font.Measure_Text (Attrs => Attrs, Content => Word);
      Roomy : constant Adi.Core.Size_2D :=
        Adi.Font.Measure_Text_Wrapped
          (Attrs => Attrs, Content => Word, Wrap_Width => 1000.0);
   begin
      if Fam = Null_Font then
         Put_Line ("  [SKIP] no measurable system font");
      else
         Put_Line ("  flat.w=" & Adi.Core.Pixel_Type'Image (Flat.Width)
                   & " wrapped-at-1000.w="
                   & Adi.Core.Pixel_Type'Image (Roomy.Width));
         Test_Support.Assert
           (Roomy.Width <= Flat.Width + 1.0,
            "a word measured with a 1000px wrap width is not 1000px wide");
      end if;
   end;

   New_Line;

   --  A percentage line-height resolves against the font size, which is
   --  what adi-font.ads has always promised. Resolving it against the
   --  font's own line skip made the answer move with whichever face was
   --  loaded, so this needs a real font: with none, the natural skip
   --  falls back to the font size and both readings agree by accident.
   Put_Line ("=== line-height resolves against the font size ===");
   declare
      use Adi.Core;
      use type Adi.SDL.TTF.TTF_Font_Access;

      DJ  : constant Font_Handle := Adi.Font.Find ("DejaVu Sans");
      NS  : constant Font_Handle := Adi.Font.Find ("Noto Sans");
      Fam : constant Font_Handle := (if DJ /= Null_Font then DJ else NS);
      F   : constant Adi.SDL.TTF.TTF_Font_Access :=
        (if Fam = Null_Font then null
         else Adi.Font.Get_TTF_Font
                (Adi.Font.Make_Attributes
                   (Family     => Fam,
                    Size       => 20.0,
                    Weight     => Weight_Normal,
                    Style      => Style_Normal,
                    Decoration => Decoration_None)));
   begin
      if F = null then
         Put_Line ("  [SKIP] no measurable system font");
      else
         declare
            Natural_Skip : constant Pixel_Type :=
              Adi.Font.Natural_Line_Skip_Px (F);
            Half_Again   : constant Pixel_Type :=
              Adi.Font.Resolve_Line_Skip_Px
                (Line_Height (Pct (150.0)), 20.0, F);
            Doubled      : constant Pixel_Type :=
              Adi.Font.Resolve_Line_Skip_Px (Line_Height (2.0), 20.0, F);
            Untouched    : constant Pixel_Type :=
              Adi.Font.Resolve_Line_Skip_Px (Normal_Line_Height, 20.0, F);
         begin
            Put_Line ("  natural=" & Pixel_Type'Image (Natural_Skip)
                      & "  @150% =" & Pixel_Type'Image (Half_Again)
                      & "  @2.0 =" & Pixel_Type'Image (Doubled));

            Test_Support.Assert
              (abs (Natural_Skip - 20.0) > 0.001,
               "the face's own spacing differs from its size, so the two "
               & "readings of a percentage cannot coincide");
            Test_Support.Assert
              (abs (Half_Again - 30.0) < 0.001,
               "150% of a 20px font is a 30px line skip, measured against "
               & "the size rather than the face");
            Test_Support.Assert
              (abs (Doubled - 40.0) < 0.001,
               "a plain multiplier measures against the font size too");
            Test_Support.Assert
              (abs (Untouched - Natural_Skip) < 0.001,
               "`normal` is still the face's own spacing");
         end;
      end if;
   end;

   New_Line;

   --  Two widgets sharing a family and size but wanting different line heights or wrap alignments must get different font instances.
   Put_Line ("=== layout state makes distinct font instances ===");
   declare
      use Adi.Core;
      use type Adi.SDL.TTF.TTF_Font_Access;

      DJ  : constant Font_Handle := Adi.Font.Find ("DejaVu Sans");
      NS  : constant Font_Handle := Adi.Font.Find ("Noto Sans");
      Fam : constant Font_Handle := (if DJ /= Null_Font then DJ else NS);

      function Variant (Skip  : Natural;
                        Align : Adi.Font.Wrap_Alignment :=
                                  Adi.Font.Wrap_Left)
                        return Adi.SDL.TTF.TTF_Font_Access
      is
        (if Fam = Null_Font then null
         else Adi.Font.Get_TTF_Font
                (Adi.Font.Make_Attributes
                   (Family     => Fam,
                    Size       => 20.0,
                    Weight     => Weight_Normal,
                    Style      => Style_Normal,
                    Decoration => Decoration_None,
                    Line_Skip  => Skip,
                    Wrap_Align => Align)));

      Tight   : constant Adi.SDL.TTF.TTF_Font_Access := Variant (26);
      Loose   : constant Adi.SDL.TTF.TTF_Font_Access := Variant (40);
      Centred : constant Adi.SDL.TTF.TTF_Font_Access :=
        Variant (26, Adi.Font.Wrap_Center);
   begin
      if Fam = Null_Font then
         Put_Line ("  [SKIP] no system font to open variants of");
      elsif Tight = null or else Loose = null or else Centred = null then
         --  Not a skip: the family resolved, so every variant of it must have an instance, or the getters below hit a null font.
         Test_Support.Assert
           (False, "a resolvable family opens every layout variant");
      else
         Test_Support.Assert
           (Tight /= Loose,
            "two line heights are two instances, not one that gets reset");
         Test_Support.Assert
           (Tight /= Centred,
            "wrap alignment separates instances the same way");

         --  Distinct keys are only half of it: the instance must also carry the state its key promises.
         Put_Line
           ("  applied skip: tight="
            & Interfaces.C.int'Image (TTF_GetFontLineSkip (Tight))
            & " loose=" & Interfaces.C.int'Image (TTF_GetFontLineSkip (Loose))
            & "  centred align="
            & TTF_HorizontalAlignment'Image
                (TTF_GetFontWrapAlignment (Centred)));

         Test_Support.Assert
           (TTF_GetFontLineSkip (Tight) = 26,
            "the tight variant is opened carrying its own line skip");
         Test_Support.Assert
           (TTF_GetFontLineSkip (Loose) = 40,
            "and the loose one carries its own, at the same time");
         Test_Support.Assert
           (TTF_GetFontWrapAlignment (Centred)
              = TTF_HORIZONTAL_ALIGN_CENTER,
            "the centred variant is opened already aligned");
         Test_Support.Assert
           (TTF_GetFontWrapAlignment (Tight) = TTF_HORIZONTAL_ALIGN_LEFT,
            "and its left-aligned sibling is untouched by that");

         Test_Support.Assert
           (abs (Adi.Font.Natural_Line_Skip_Px (Tight)
                   - Adi.Font.Natural_Line_Skip_Px (Loose)) < 0.001,
            "an opened override does not become the face's natural spacing");

         --  Each call must keep returning its own instance, never the other's, when alternated.
         for Round in 1 .. 3 loop
            Test_Support.Assert
              (Variant (26) = Tight and then Variant (40) = Loose,
               "instances stay put when the two are used alternately, round"
               & Integer'Image (Round));
         end loop;

         --  Line_Skip_Override is what feeds these keys from CSS.
         Test_Support.Assert
           (Adi.Font.Line_Skip_Override (Line_Height (Pct (150.0)), 20.0) = 30,
            "a percentage line-height becomes the integer SDL is given");
         Test_Support.Assert
           (Adi.Font.Line_Skip_Override (Normal_Line_Height, 20.0) = 0,
            "`normal` asks for no override, leaving the font's own spacing");
      end if;
   end;

   New_Line;

   --  What Label asks the cache for. Text that does not wrap gives SDL no
   --  box to align within, so it always takes the left variant and is
   --  positioned by Label instead.
   Put_Line ("=== text-align maps to a wrap alignment ===");
   declare
      use Adi.Font;
   begin
      Test_Support.Assert
        (Wrap_Alignment_For (Text_Center, Wraps => True) = Wrap_Center
           and then Wrap_Alignment_For (Text_Right, Wraps => True)
                      = Wrap_Right
           and then Wrap_Alignment_For (Text_Left, Wraps => True)
                      = Wrap_Left,
         "wrapping text carries its own alignment");
      Test_Support.Assert
        (Wrap_Alignment_For (Text_End, Wraps => True) = Wrap_Right
           and then Wrap_Alignment_For (Text_Start, Wraps => True)
                      = Wrap_Left,
         "start and end read as left and right, there being no RTL");
      Test_Support.Assert
        (Wrap_Alignment_For (Text_Justify, Wraps => True) = Wrap_Left,
         "justify is not implemented and reads as left");
      Test_Support.Assert
        (Wrap_Alignment_For (Text_Center, Wraps => False) = Wrap_Left
           and then Wrap_Alignment_For (Text_Right, Wraps => False)
                      = Wrap_Left,
         "text that does not wrap never asks for an aligned variant");
   end;
   New_Line;

   --  The wrapped half of text-align is SDL's: it positions each line
   --  within the wrap width, which an offset applied to the whole block
   --  cannot do. Read the line rectangles back rather than trusting that
   --  asking for the aligned font was enough.
   Put_Line ("=== SDL aligns wrapped lines within the wrap width ===");
   declare
      use type Adi.SDL.TTF.TTF_Font_Access;

      DJ  : constant Font_Handle := Adi.Font.Find ("DejaVu Sans");
      NS  : constant Font_Handle := Adi.Font.Find ("Noto Sans");
      Fam : constant Font_Handle := (if DJ /= Null_Font then DJ else NS);

      Wrap_At : constant := 200;
      Phrase  : constant String := "wrapping onto several separate lines";

      Engine : TTF_TextEngine_Access;

      --  x of the last line, relative to the text origin. The last line
      --  is the short one, so it is where alignment shows.
      function Last_Line_X (Align : Adi.Font.Wrap_Alignment) return int is
         F : constant Adi.SDL.TTF.TTF_Font_Access :=
           Adi.Font.Get_TTF_Font
             (Adi.Font.Make_Attributes
                (Family     => Fam,
                 Size       => 16.0,
                 Weight     => Weight_Normal,
                 Style      => Style_Normal,
                 Decoration => Decoration_None,
                 Wrap_Align => Align));
         C_Text : Interfaces.C.Strings.chars_ptr :=
           Interfaces.C.Strings.New_String (Phrase);
         T   : TTF_Text_Access;
         Sub : aliased TTF_SubString;
         Ok  : Adi.SDL.C_bool;
         Result : int := -1;
         Line   : int := 0;
      begin
         Test_Support.Assert
           (F /= null, "the aligned font variant opens");
         if F = null then
            Interfaces.C.Strings.Free (C_Text);
            return -1;
         end if;

         T := TTF_CreateText (Engine, F, C_Text, Phrase'Length);
         Interfaces.C.Strings.Free (C_Text);
         Test_Support.Assert (T /= null, "SDL lays the phrase out");
         if T = null then
            return -1;
         end if;

         Ok := TTF_SetTextWrapWidth (T, Wrap_At);
         Test_Support.Assert
           (Boolean (Ok), "SDL accepts the wrap width");
         --  Walk to the final line. Asking for a line past the end does
         --  not fail: SDL clamps and hands back the end-of-text marker
         --  sitting on the last line, so stop when the line it reports is
         --  no longer the one asked for.
         for Probe in 0 .. 31 loop
            Ok := TTF_GetTextSubStringForLine (T, int (Probe), Sub'Access);
            exit when not Boolean (Ok)
              or else Sub.line_index /= int (Probe);
            Result := Sub.rect.x;
            Line := int (Probe) + 1;
         end loop;
         TTF_DestroyText (T);
         Test_Support.Assert
           (Line > 1,
            "the phrase wraps onto more than one line, so the last one is "
            & "short enough for alignment to move it");
         return Result;
      end Last_Line_X;
   begin
      Engine := TTF_CreateSurfaceTextEngine;
      if Fam = Null_Font then
         Put_Line ("  [SKIP] no system font");
         if Engine /= null then
            TTF_DestroySurfaceTextEngine (Engine);
         end if;
      elsif Engine = null then
         --  A font exists, so this is a real failure rather than an
         --  environment without the means to run the check.
         Test_Support.Assert (False, "the surface text engine is available");
      else
         declare
            Left_X   : constant int := Last_Line_X (Adi.Font.Wrap_Left);
            Centre_X : constant int := Last_Line_X (Adi.Font.Wrap_Center);
            Right_X  : constant int := Last_Line_X (Adi.Font.Wrap_Right);
         begin
            Put_Line ("  last line x: left=" & int'Image (Left_X)
                      & " centre=" & int'Image (Centre_X)
                      & " right=" & int'Image (Right_X));

            Test_Support.Assert
              (Left_X = 0,
               "a left-aligned line starts at the text origin");
            Test_Support.Assert
              (Centre_X > Left_X and then Right_X > Centre_X,
               "centring indents the short line, and right indents it "
               & "further");
            Test_Support.Assert
              (abs (Right_X - 2 * Centre_X) <= 2,
               "the centred line sits at half the right-aligned offset");
         end;
         TTF_DestroySurfaceTextEngine (Engine);
      end if;
   end;

   ---------------------------------------------------------------------
   --  The fallback a later Set_Default_Font names
   ---------------------------------------------------------------------

   Test_Support.Section ("Set_Default_Font reaches text already drawn");
   declare
      Sample : constant String := "Hello World!";
      --  A size the sections above leave alone, so what this measures
      --  is opened here rather than served from an earlier key.
      Size   : constant Float := 17.0;
      Plain  : constant Font_Handle :=
        Adi.Font.Load ("vendor/open-sans/static/OpenSans-Regular.ttf");
      Narrow : constant Font_Handle :=
        Adi.Font.Load ("vendor/open-sans/static/OpenSans_Condensed-Bold.ttf");
      use type Adi.Core.Size_2D;
      use type Adi.Core.Pixel_Type;
   begin
      if Plain = Null_Font or else Narrow = Null_Font then
         Test_Support.Assert (False, "both faces load");
      else
         declare
            Plain_Own  : constant Adi.Core.Size_2D :=
              Adi.Font.Measure_Text (Plain, Sample, Size);
            Narrow_Own : constant Adi.Core.Size_2D :=
              Adi.Font.Measure_Text (Narrow, Sample, Size);
         begin
            --  Asserted first: two faces that measured alike would let
            --  every comparison below pass on nothing.
            Test_Support.Assert
              (Plain_Own.Width /= Narrow_Own.Width,
               "the two faces measure apart, so a comparison can tell "
               & "them apart");

            Adi.Font.Set_Default_Font (Plain);
            declare
               First : constant Adi.Core.Size_2D :=
                 Adi.Font.Measure_Text (Null_Font, Sample, Size);
            begin
               Test_Support.Assert
                 (First.Width = Plain_Own.Width,
                  "text with no family of its own measures as the "
                  & "default font");

               Adi.Font.Set_Default_Font (Narrow);
               declare
                  Second : constant Adi.Core.Size_2D :=
                    Adi.Font.Measure_Text (Null_Font, Sample, Size);
               begin
                  Put_Line ("  plain" & Plain_Own.Width'Image
                            & "  narrow" & Narrow_Own.Width'Image
                            & "  after the change" & Second.Width'Image);
                  Test_Support.Assert
                    (Second.Width = Narrow_Own.Width,
                     "and follows the default font to the next one");
               end;
            end;
         end;
      end if;
   end;

   ---------------------------------------------------------------------
   --  What an unrelated font load costs the fallback's cached instance
   ---------------------------------------------------------------------

   Test_Support.Section ("a font load leaves the fallback's instance alone");
   declare
      Sample : constant String := "Hello World!";
      --  A size no section above reaches for.
      Size   : constant Float := 19.0;
      Held   : Natural;
      Ignore : Font_Handle;
      use type Adi.Core.Size_2D;
   begin
      declare
         Warm : constant Adi.Core.Size_2D :=
           Adi.Font.Measure_Text (Null_Font, Sample, Size);
         pragma Unreferenced (Warm);
      begin
         Held := Adi.Font.Testing.Sized_Fonts_Held;
      end;

      --  Registering any face moves the environment generation, whether
      --  or not the fallback names it. A key built from that counter
      --  would open a second instance of the face already in hand, and
      --  nothing releases the first.
      Ignore := Adi.Font.Load
        ("vendor/open-sans/static/OpenSans-Medium.ttf");

      declare
         Again : constant Adi.Core.Size_2D :=
           Adi.Font.Measure_Text (Null_Font, Sample, Size);
         pragma Unreferenced (Again);
      begin
         Put_Line ("  held before" & Natural'Image (Held)
                   & "  after" & Natural'Image
                     (Adi.Font.Testing.Sized_Fonts_Held));
         Test_Support.Assert
           (Adi.Font.Testing.Sized_Fonts_Held = Held,
            "the instance already open is the one used again");
      end;
   end;

   ---------------------------------------------------------------------
   --  The sized-face budget
   ---------------------------------------------------------------------

   Test_Support.Section ("a face the frame still has is never closed");
   declare
      Probe : constant Font_Handle := Adi.Font.Load (Probe_Path);
      Before : Natural;
      F      : TTF_Font_Access;
   begin
      Drain;
      Before := Adi.Font.Testing.Sized_Fonts_Held;
      Put_Line ("  held after draining at a zero budget:"
                & Natural'Image (Before));
      Test_Support.Assert
        (Before = 0,
         "a zero budget takes every face nothing holds");

      F := Face (Probe, 7001);
      Test_Support.Assert
        (F /= null and then Adi.Font.Testing.Sized_Fonts_Held = 1,
         "a face opens under a zero budget rather than being refused");

      Adi.Font.Advance_Frame;
      Test_Support.Assert
        (Adi.Font.Testing.Resident (F),
         "a face handed out in the previous frame stays, budget or no "
         & "budget");

      Adi.Font.Advance_Frame;
      Test_Support.Assert
        (not Adi.Font.Testing.Resident (F)
           and then Adi.Font.Testing.Sized_Fonts_Held = 0,
         "and goes once two frames have passed over it");
   end;

   Test_Support.Section ("lowering the budget trims idle faces at once");
   declare
      Probe  : constant Font_Handle := Adi.Font.Load (Probe_Path);
      Charge : Adi.Font.Byte_Count;
      Opened : array (1 .. 5) of TTF_Font_Access;
   begin
      Drain;
      Adi.Font.Set_Face_Budget (Adi.Font.Default_Face_Budget);

      --  Opened back to back, so all five carry the same frame and the
      --  order they were opened in is the only thing separating them.
      for I in Opened'Range loop
         Opened (I) := Face (Probe, 7100 + I);
      end loop;
      Test_Support.Assert
        (Adi.Font.Testing.Sized_Fonts_Held = 5,
         "five keys open five faces");
      Test_Support.Assert
        ((for all I in Opened'Range =>
            Adi.Font.Testing.Last_Used (Opened (I))
              = Adi.Font.Testing.Last_Used (Opened (1))),
         "and share a frame, so the eviction order rests on the tie-break "
         & "alone");

      Charge := Adi.Font.Face_Bytes_Used / 5;
      Sweep;
      Test_Support.Assert
        (Adi.Font.Idle_Face_Bytes = 5 * Charge
           and then Adi.Font.Testing.Sized_Fonts_Held = 5,
         "under a budget above them they age into idle and stay");

      --  No frame advances here: the trim is the budget's own doing.
      Adi.Font.Set_Face_Budget (2 * Charge);
      Put_Line ("  held after the budget dropped to two:"
                & Natural'Image (Adi.Font.Testing.Sized_Fonts_Held));
      Test_Support.Assert
        (Adi.Font.Testing.Sized_Fonts_Held = 2,
         "lowering the budget closes what will not fit, without waiting "
         & "for a frame");
      Test_Support.Assert
        (Adi.Font.Idle_Face_Bytes = 2 * Charge,
         "and stops at the figure it was given");
      Test_Support.Assert
        (Adi.Font.Testing.Resident (Opened (4))
           and then Adi.Font.Testing.Resident (Opened (5)),
         "the two opened last are the two it keeps");
      Test_Support.Assert
        ((for all I in 1 .. 3 =>
            not Adi.Font.Testing.Resident (Opened (I))),
         "and the three opened before them are the ones it closed");
   end;

   Test_Support.Section ("pressure takes the least recently used face");
   declare
      Probe   : constant Font_Handle := Adi.Font.Load (Probe_Path);
      Charge  : Adi.Font.Byte_Count;
      A, B, C : TTF_Font_Access;
   begin
      Drain;
      Adi.Font.Set_Face_Budget (Adi.Font.Default_Face_Budget);

      A := Face (Probe, 7201);
      Adi.Font.Advance_Frame;
      B := Face (Probe, 7202);
      Adi.Font.Advance_Frame;
      C := Face (Probe, 7203);
      Adi.Font.Advance_Frame;

      Charge := Adi.Font.Face_Bytes_Used / 3;
      Test_Support.Assert
        (Adi.Font.Testing.Last_Used (A) < Adi.Font.Testing.Last_Used (B)
           and then Adi.Font.Testing.Last_Used (B)
                      < Adi.Font.Testing.Last_Used (C),
         "the three faces carry the frames they were opened in");

      --  Two of the three are idle; room for one closes the older.
      Adi.Font.Set_Face_Budget (Charge);
      Test_Support.Assert
        (not Adi.Font.Testing.Resident (A),
         "the face used longest ago goes first");
      Test_Support.Assert
        (Adi.Font.Testing.Resident (B) and then Adi.Font.Testing.Resident (C),
         "and the two used since it stay");
   end;

   Test_Support.Section ("a pinned face outlasts every sweep");
   declare
      Probe : constant Font_Handle := Adi.Font.Load (Probe_Path);
      Kept  : TTF_Font_Access;
      Loose : TTF_Font_Access;
   begin
      Drain;
      Kept  := Face (Probe, 7301);
      Loose := Face (Probe, 7302);
      Adi.Font.Pin_Face (Kept);
      Test_Support.Assert
        (Adi.Font.Testing.Pins (Kept) = 1
           and then Adi.Font.Testing.Pins (Loose) = 0,
         "a pin lands on the face it names and no other");

      Sweep;
      Sweep;
      Test_Support.Assert
        (Adi.Font.Testing.Resident (Kept),
         "a pinned face survives a zero budget");
      Test_Support.Assert
        (not Adi.Font.Testing.Resident (Loose)
           and then Adi.Font.Testing.Sized_Fonts_Held = 1,
         "and the unpinned one beside it does not");

      Adi.Font.Unpin_Face (Kept);
      Test_Support.Assert
        (Adi.Font.Testing.Pins (Kept) = 0
           and then Adi.Font.Testing.Resident (Kept),
         "dropping the pin leaves the face standing until a sweep");
      Sweep;
      Test_Support.Assert
        (Adi.Font.Testing.Sized_Fonts_Held = 0,
         "which then takes it");
   end;

   Test_Support.Section ("a face reopened after eviction measures the same");
   declare
      Probe  : constant Font_Handle := Adi.Font.Load (Probe_Path);
      Sample : constant String := "Hello World!";
      Attrs  : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Probe,
           Size       => 23.0,
           Weight     => Weight_Normal,
           Style      => Style_Normal,
           Decoration => Decoration_None,
           Line_Skip  => 7401);
      use type Adi.Core.Size_2D;
      use type Adi.Core.Pixel_Type;
      First  : Adi.Core.Size_2D;
      Again  : Adi.Core.Size_2D;
      Evicts : Adi.Font.Event_Count;
   begin
      Drain;
      First  := Adi.Font.Measure_Text (Attrs, Sample);
      Evicts := Adi.Font.Face_Evictions;
      Sweep;
      Test_Support.Assert
        (Adi.Font.Testing.Sized_Fonts_Held = 0
           and then Adi.Font.Face_Evictions > Evicts,
         "the face that measured the first time is closed");

      Again := Adi.Font.Measure_Text (Attrs, Sample);
      Put_Line ("  first" & First.Width'Image & " x" & First.Height'Image
                & "   reopened" & Again.Width'Image
                & " x" & Again.Height'Image);
      Test_Support.Assert
        (First.Width > 0.0 and then First.Height > 0.0,
         "the measurement says something to compare");
      Test_Support.Assert
        (First = Again,
         "and a reopened face measures identically");
   end;

   Test_Support.Section ("a closed face takes its line skip with it");
   declare
      Probe : constant Font_Handle := Adi.Font.Load (Probe_Path);
      Small : TTF_Font_Access;
      Large : TTF_Font_Access;
      use type Adi.Core.Pixel_Type;
      Small_Skip : Adi.Core.Pixel_Type;
      Large_Skip : Adi.Core.Pixel_Type;
   begin
      Drain;
      Small := Face (Probe, 0, 12.0);
      Small_Skip := Adi.Font.Natural_Line_Skip_Px (Small);
      Test_Support.Assert
        (Adi.Font.Testing.Line_Skip_Cached (Small),
         "querying a face's own spacing records it against the pointer");

      Sweep;
      Test_Support.Assert
        (not Adi.Font.Testing.Line_Skip_Cached (Small),
         "closing the face drops that record in the same step");

      --  An address the allocator hands back is where a record left
      --  behind would be read as the new face's own spacing.
      Large := Face (Probe, 0, 48.0);
      Large_Skip := Adi.Font.Natural_Line_Skip_Px (Large);
      Put_Line ("  12 px skip" & Small_Skip'Image
                & "   48 px skip" & Large_Skip'Image
                & "   same address "
                & Boolean'Image (Small = Large));
      Test_Support.Assert
        (Large_Skip > Small_Skip,
         "and the face opened next reports its own spacing");
   end;

   Test_Support.Section ("a face behind a live text object is not evicted");
   declare
      Canvas   : SDL_Surface_Ptr;
      Renderer : SDL_Renderer_Ptr;
      Ctx      : Adi.Render.Render_Context;
      L        : Adi.Widget.Label.Label_Handle;
      H        : Adi.Widget.Widget_Handle;
      Drawn    : TTF_Font_Access := null;
   begin
      Canvas := SDL_CreateSurface (64, 64, SDL_PIXELFORMAT_RGBA32);
      Renderer := (if Canvas = null then null
                   else SDL_CreateSoftwareRenderer (Canvas));
      if Renderer = null then
         Test_Support.Assert (False, "SDL provides a software renderer");
      else
         Drain;
         Adi.Font.Set_Face_Budget (Adi.Font.Default_Face_Budget);
         Adi.Render.Create (Ctx, Renderer);

         L := Adi.Widget.Label.Create_Handle ("Pinned");
         H := Adi.Widget.Label.To_Widget_Handle (L);
         Adi.Widget.Set_Geometry (H, (0.0, 0.0, 200.0, 40.0));
         Adi.Widget.Layout_Tree (H);
         Adi.Widget.Update (H);
         Adi.Widget.Render_Tree (H, Ctx);

         for It of Adi.Widget.Get_Items_For_Part
                     (H, Adi.Widget.Label_Part)
         loop
            if It.Cached_Font /= null then
               Drawn := It.Cached_Font;
            end if;
         end loop;

         Put_Line ("  label items:"
                   & Natural'Image (Adi.Widget.Item_Count (H))
                   & "  faces held:"
                   & Natural'Image (Adi.Font.Testing.Sized_Fonts_Held));
         Test_Support.Assert
           (Drawn /= null,
            "the label drew its text through a face of the cache");
         Test_Support.Assert
           (Adi.Font.Testing.Pins (Drawn) = 1,
            "and the item holding the text object pins it");

         Adi.Font.Set_Face_Budget (0);
         Sweep;
         Sweep;
         Put_Line ("  held under a zero budget with one label up:"
                   & Natural'Image (Adi.Font.Testing.Sized_Fonts_Held));
         Test_Support.Assert
           (Adi.Font.Testing.Resident (Drawn),
            "pressure spares the face a live text object was built from");

         Adi.Widget.Destroy (H);
         Test_Support.Assert
           (Adi.Font.Testing.Pins (Drawn) = 0,
            "destroying the widget releases the pin its items held");
         Sweep;
         Test_Support.Assert
           (not Adi.Font.Testing.Resident (Drawn),
            "and the face goes on the sweep after that");

         Adi.Render.Destroy (Ctx);
         SDL_DestroyRenderer (Renderer);
         SDL_DestroySurface (Canvas);
      end if;
      Adi.Font.Set_Face_Budget (Adi.Font.Default_Face_Budget);
   end;

   Test_Support.Finish;
end Font_Test;
