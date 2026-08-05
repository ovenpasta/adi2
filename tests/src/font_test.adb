with Ada.Text_IO;          use Ada.Text_IO;
with Adi.SDL;
with Adi.SDL.TTF;      use Adi.SDL.TTF;
with Interfaces.C;      use type Interfaces.C.int;
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

   Test_Support.Finish;
end Font_Test;
