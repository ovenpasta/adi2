with Ada.Environment_Variables;
with Ada.Text_IO;          use Ada.Text_IO;
with Adi.SDL;
with Adi.SDL.TTF;      use Adi.SDL.TTF;
with Adi.SDL.TTF.TextEngine; use Adi.SDL.TTF.TextEngine;
with Interfaces.C.Strings;
with Interfaces.C;      use Interfaces.C;
with Adi.Build_Target;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Core;
with Adi.Font;
with Test_Support;

procedure Font_Test is
   Sdl_OK   : Adi.SDL.C_bool;
   Ttf_OK   : Adi.SDL.C_bool;

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
         --  Asserted before the comparison, because a path this test
         --  failed to find would make both sides measure through the
         --  platform fallback, agree, and read as a pass -- the exact
         --  outcome the section exists to rule out.
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

   --  Two widgets sharing a family and size but wanting different line
   --  heights or wrap alignments must get different font instances.
   --  Sharing one meant whichever rendered last left its line skip on the
   --  font and silently re-laid the other's text.
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
         --  Not a skip: the family resolved, so every variant of it owes
         --  us an instance. Failing here also keeps the getters below
         --  away from a null font.
         Test_Support.Assert
           (False, "a resolvable family opens every layout variant");
      else
         Test_Support.Assert
           (Tight /= Loose,
            "two line heights are two instances, not one that gets reset");
         Test_Support.Assert
           (Tight /= Centred,
            "wrap alignment separates instances the same way");

         --  Distinct keys are only half of it: the instance must also
         --  carry the state its key promises. Deleting both setters would
         --  leave every assertion above passing.
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

         --  Alternating use is the case that used to corrupt: each call
         --  must keep returning its own instance, never the other's.
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

   Test_Support.Finish;
end Font_Test;
