pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Adi.Core;
with Adi.Image;
with Adi.SDL;
with Adi.SVG;
with Interfaces;
with Test_Support;

procedure Svg_Test is
   use type Adi.Core.Pixel_Type;
   use type Adi.Image.Image_Access;
   use type Adi.SVG.Document_Access;
   use type Adi.SVG.Pixel_Buffer_Access;

   Backend : constant String := Adi.SVG.Backend_Name;
   Is_Ada_Backend : constant Boolean := Backend = "ada";

   function Effective_AA_Scale return Positive is
      package Env renames Ada.Environment_Variables;
      S : constant String := Env.Value ("ADI_SVG_AA_SCALE", "");
   begin
      if S'Length > 0 then
         begin
            declare
               V : constant Integer := Integer'Value (S);
            begin
               if V >= 1 and then V <= 8 then
                  return Positive (V);
               end if;
            end;
         exception
            when others =>
               null;
         end;
      end if;

      return 1;
   end Effective_AA_Scale;

   Strict_AA_Expected : constant Boolean :=
     (if Is_Ada_Backend then Effective_AA_Scale > 1 else True);

   procedure Free_Pixels is
     new Ada.Unchecked_Deallocation (Adi.SVG.Pixel_Buffer, Adi.SVG.Pixel_Buffer_Access);
   procedure Free_Document is
     new Ada.Unchecked_Deallocation (Adi.SVG.Document'Class, Adi.SVG.Document_Access);

   procedure Assert (Cond : Boolean; Msg : String)
     renames Test_Support.Assert;

   procedure Assert_If_Ada (Cond : Boolean; Msg : String) is
   begin
      if Is_Ada_Backend then
         Assert (Cond, Msg);
      else
         Assert (True, Msg & " (skipped for backend=" & Backend & ")");
      end if;
   end Assert_If_Ada;

   procedure Assert_If_Strict_AA (Cond : Boolean; Msg : String) is
   begin
      if Strict_AA_Expected then
         Assert (Cond, Msg);
      else
         Assert (True, Msg & " (skipped: strict AA disabled)");
      end if;
   end Assert_If_Strict_AA;

   function Nearly_Equal
     (L, R : Adi.Core.Pixel_Type;
      Eps  : Adi.Core.Pixel_Type := 0.5) return Boolean
   is
      D : constant Adi.Core.Pixel_Type := (if L > R then L - R else R - L);
   begin
      return D <= Eps;
   end Nearly_Equal;

   function Alpha_Of (P : Adi.SDL.Uint32) return Natural is
      use type Interfaces.Unsigned_32;
      U : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (P);
   begin
      return Natural (Interfaces.Shift_Right (U, 24) and 16#FF#);
   end Alpha_Of;

   function Red_Of (P : Adi.SDL.Uint32) return Natural is
      use type Interfaces.Unsigned_32;
      U : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (P);
   begin
      return Natural (Interfaces.Shift_Right (U, 16) and 16#FF#);
   end Red_Of;

   function Green_Of (P : Adi.SDL.Uint32) return Natural is
      use type Interfaces.Unsigned_32;
      U : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (P);
   begin
      return Natural (Interfaces.Shift_Right (U, 8) and 16#FF#);
   end Green_Of;

   function Blue_Of (P : Adi.SDL.Uint32) return Natural is
      use type Interfaces.Unsigned_32;
      U : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (P);
   begin
      return Natural (U and 16#FF#);
   end Blue_Of;

   function Brightness (P : Adi.SDL.Uint32) return Natural is
   begin
      return Red_Of (P) + Green_Of (P) + Blue_Of (P);
   end Brightness;

   function Pixel_At
     (Px    : Adi.SVG.Pixel_Buffer_Access;
      Width : Positive;
      X     : Natural;
      Y     : Natural) return Adi.SDL.Uint32
   is
   begin
      return Px (Y * Width + X);
   end Pixel_At;

   procedure Release
     (Doc : in out Adi.SVG.Document_Access;
      Px  : in out Adi.SVG.Pixel_Buffer_Access)
   is
   begin
      if Px /= null then
         Free_Pixels (Px);
      end if;

      if Doc /= null then
         Adi.SVG.Destroy (Doc.all);
         Free_Document (Doc);
      end if;
   end Release;

   --  Adi.Image.Free also drops the image from the registry that
   --  Release_All_Textures_For_Renderer walks.
   procedure Release_Image (Img : in out Adi.Image.Image_Access)
     renames Adi.Image.Free;

   procedure Test_Document_Size_And_Validity is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      W   : Adi.Core.Pixel_Type := 0.0;
      H   : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: document size and validity");

      Doc := Adi.SVG.Load_From_File ("tests/assets/does_not_exist.svg");
      Assert
        (Doc /= null and then not Adi.SVG.Is_Valid (Doc.all),
         "missing SVG yields invalid document");
      if Doc /= null then
         Free_Document (Doc);
      end if;

      Doc := Adi.SVG.Load_From_File ("tests/assets/size_viewbox.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "viewBox-only SVG loads");
      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Adi.SVG.Get_Size (Doc.all, W, H);
         Assert (Nearly_Equal (W, 320.0, 0.2), "viewBox width resolves to document width");
         Assert (Nearly_Equal (H, 160.0, 0.2), "viewBox height resolves to document height");
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/transform_units.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "unit-sized SVG loads");
      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Adi.SVG.Get_Size (Doc.all, W, H);
         Assert (Nearly_Equal (W, 192.0, 0.2), "width in inches resolves at 96 DPI");
         Assert (Nearly_Equal (H, 96.0, 0.2), "height in inches resolves at 96 DPI");
      end if;
      Release (Doc, Px);

      New_Line;
   end Test_Document_Size_And_Validity;

   procedure Test_Image_Integration is
      Img : Adi.Image.Image_Access := null;
      W   : Adi.Core.Pixel_Type := 0.0;
      H   : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: image API integration");

      Img := Adi.Image.Load_From_File
        (Path => "tests/assets/size_viewbox.svg");

      Assert (Img /= null, "Adi.Image returns image handle for SVG with null renderer");
      if Img /= null then
         Assert (Adi.Image.Is_Valid (Img.all), "Adi.Image marks SVG image as valid");
         Adi.Image.Get_Size (Img.all, W, H);
         Assert (Nearly_Equal (W, 320.0, 0.2), "Adi.Image exposes SVG width");
         Assert (Nearly_Equal (H, 160.0, 0.2), "Adi.Image exposes SVG height");
      end if;

      Release_Image (Img);

      New_Line;
   end Test_Image_Integration;

   procedure Test_Load_From_String_And_Path is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      Img : Adi.Image.Image_Access := null;
      W   : Adi.Core.Pixel_Type := 0.0;
      H   : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: SVG load from string and path helpers");

      Doc := Adi.SVG.Load_From_String
        ("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 10'>" &
         "<rect width='20' height='10' fill='tomato'/></svg>");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "Load_From_String returns valid SVG document");
      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Adi.SVG.Get_Size (Doc.all, W, H);
         Assert (Nearly_Equal (W, 20.0, 0.2), "Load_From_String preserves viewBox width");
         Assert (Nearly_Equal (H, 10.0, 0.2), "Load_From_String preserves viewBox height");

         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 20, Height => 10);
         Assert (Px /= null, "Load_From_String document renders");
      end if;
      Release (Doc, Px);

      Img := Adi.Image.Load_SVG_Path
        (Path_Data => "M4 4 L20 4 L20 20 L4 20 Z",
         Size      => (Width => 24.0, Height => 24.0),
         Fill      => (R => 255, G => 99, B => 71, A => 255));
      Assert (Img /= null, "Load_SVG_Path returns image");
      if Img /= null then
         Assert (Adi.Image.Is_Valid (Img.all), "Load_SVG_Path image is valid");
         Adi.Image.Get_Size (Img.all, W, H);
         Assert (Nearly_Equal (W, 24.0, 0.2), "Load_SVG_Path image width matches requested size");
         Assert (Nearly_Equal (H, 24.0, 0.2), "Load_SVG_Path image height matches requested size");
      end if;
      Release_Image (Img);

      New_Line;
   end Test_Load_From_String_And_Path;

   procedure Test_Color_Forms is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      P1, P2, P3 : Adi.SDL.Uint32 := 0;
   begin
      Put_Line ("Test: color parsing forms");

      Doc := Adi.SVG.Load_From_File ("tests/assets/color_forms.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "color forms SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 40);
         Assert (Px /= null, "color forms SVG renders");

         if Px /= null then
            P1 := Pixel_At (Px, Width => 120, X => 20, Y => 20);
            P2 := Pixel_At (Px, Width => 120, X => 60, Y => 20);
            P3 := Pixel_At (Px, Width => 120, X => 100, Y => 20);

            Assert (Red_Of (P1) > Green_Of (P1) and then Red_Of (P1) > Blue_Of (P1),
                    "hex color produces red-dominant region");
            Assert
              (Green_Of (P2) > Red_Of (P2) and then Green_Of (P2) > Blue_Of (P2),
               "rgb() color produces green-dominant region");
            Assert (Blue_Of (P3) > Red_Of (P3), "named color produces blue-biased region");
         end if;
      end if;

      Release (Doc, Px);

      New_Line;
   end Test_Color_Forms;

   procedure Test_Path_Commands_And_AA is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      Solid : Natural := 0;
      AA    : Natural := 0;
   begin
      Put_Line ("Test: path command coverage and AA");

      Doc := Adi.SVG.Load_From_File ("tests/assets/path_commands.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "path command SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 80);
         Assert (Px /= null, "path command SVG renders");

         if Px /= null then
            for I in Px'Range loop
               declare
                  A : constant Natural := Alpha_Of (Px (I));
               begin
                  if A > 0 then
                     Solid := Solid + 1;
                     if A < 255 then
                        AA := AA + 1;
                     end if;
                  end if;
               end;
            end loop;

            Assert (Solid > 800, "path command SVG produces non-empty raster output");
            Assert_If_Strict_AA
              (AA > 0,
               "path command SVG output includes anti-aliased pixels");
         end if;
      end if;

      Release (Doc, Px);

      New_Line;
   end Test_Path_Commands_And_AA;

   procedure Test_Gradient_Fills is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      TL, TR, DL, DR, RC, RE : Adi.SDL.Uint32 := 0;
   begin
      Put_Line ("Test: gradient fill features");

      Doc := Adi.SVG.Load_From_File ("tests/assets/gradient_features.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "gradient feature SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 80);
         Assert (Px /= null, "gradient feature SVG renders");

         if Px /= null then
            TL := Pixel_At (Px, Width => 120, X => 10, Y => 10);
            TR := Pixel_At (Px, Width => 120, X => 110, Y => 10);
            DL := Pixel_At (Px, Width => 120, X => 10, Y => 30);
            DR := Pixel_At (Px, Width => 120, X => 110, Y => 30);
            RC := Pixel_At (Px, Width => 120, X => 60, Y => 60);
            RE := Pixel_At (Px, Width => 120, X => 60, Y => 44);

            Assert (Red_Of (TL) > Blue_Of (TL), "linear gradient start is red-biased");
            Assert (Blue_Of (TR) > Red_Of (TR), "linear gradient end is blue-biased");
            Assert (Red_Of (DL) > Blue_Of (DL), "href-derived gradient inherits start color");
            Assert (Blue_Of (DR) > Red_Of (DR), "href-derived gradient inherits end color");
            Assert (Brightness (RC) > Brightness (RE),
                    "radial gradient center is brighter than outer sample");
         end if;
      end if;

      Release (Doc, Px);

      New_Line;
   end Test_Gradient_Fills;

   procedure Test_Paint_URL_Fallback_Syntax is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      TL, TR, SL, SR, FB : Adi.SDL.Uint32 := 0;
   begin
      Put_Line ("Test: url() paint with fallback syntax");

      Doc := Adi.SVG.Load_From_File ("tests/assets/paint_url_fallback.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "url fallback SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 50);
         Assert (Px /= null, "url fallback SVG renders");

         if Px /= null then
            TL := Pixel_At (Px, Width => 120, X => 10, Y => 8);
            TR := Pixel_At (Px, Width => 120, X => 110, Y => 8);
            SL := Pixel_At (Px, Width => 120, X => 10, Y => 25);
            SR := Pixel_At (Px, Width => 120, X => 110, Y => 25);
            FB := Pixel_At (Px, Width => 120, X => 10, Y => 40);

            Assert (Red_Of (TL) > Blue_Of (TL), "fill url() with fallback keeps gradient at start");
            Assert (Blue_Of (TR) > Red_Of (TR), "fill url() with fallback keeps gradient at end");
            Assert (Red_Of (SL) > Blue_Of (SL), "stroke url() with fallback keeps gradient at start");
            Assert (Blue_Of (SR) > Red_Of (SR), "stroke url() with fallback keeps gradient at end");
            Assert (Green_Of (FB) > Red_Of (FB) and then Green_Of (FB) > Blue_Of (FB),
                    "missing url() paint uses fallback color");
         end if;
      end if;

      Release (Doc, Px);

      New_Line;
   end Test_Paint_URL_Fallback_Syntax;

   procedure Test_Stroke_Styles is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      Butt_Cap, Round_Cap, Square_Cap : Natural := 0;
      Miter_Area, Limited_Area : Natural := 0;
   begin
      Put_Line ("Test: stroke cap/join/miter features");

      Doc := Adi.SVG.Load_From_File ("tests/assets/stroke_styles.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "stroke styles SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 100);
         Assert (Px /= null, "stroke styles SVG renders");

         if Px /= null then
            Butt_Cap := Alpha_Of (Pixel_At (Px, Width => 120, X => 20, Y => 10));
            Round_Cap := Alpha_Of (Pixel_At (Px, Width => 120, X => 60, Y => 10));
            Square_Cap := Alpha_Of (Pixel_At (Px, Width => 120, X => 100, Y => 10));

            Assert (Round_Cap > Butt_Cap, "round cap extends beyond line endpoint");
            Assert (Square_Cap > Butt_Cap, "square cap extends beyond line endpoint");

            for Y in 24 .. 56 loop
               for X in 32 .. 52 loop
                  if Alpha_Of (Pixel_At (Px, Width => 120, X => X, Y => Y)) > 0 then
                     Miter_Area := Miter_Area + 1;
                  end if;
               end loop;

               for X in 82 .. 102 loop
                  if Alpha_Of (Pixel_At (Px, Width => 120, X => X, Y => Y)) > 0 then
                     Limited_Area := Limited_Area + 1;
                  end if;
               end loop;
            end loop;

            Assert
              (Miter_Area /= Limited_Area,
               "miterlimit affects join tip extent");
         end if;
      end if;

      Release (Doc, Px);

      New_Line;
   end Test_Stroke_Styles;

   procedure Test_Stroke_Gradient_Dash_And_Dash_Offset is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      L, R : Adi.SDL.Uint32 := 0;
      On_P, Gap_P, Off_A, Off_B : Natural := 0;
   begin
      Put_Line ("Test: stroke gradient, dash, and dash-offset");

      Doc := Adi.SVG.Load_From_File ("tests/assets/stroke_gradient.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "stroke-gradient SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 40);
         Assert (Px /= null, "stroke-gradient SVG renders");

         if Px /= null then
            L := Pixel_At (Px, Width => 120, X => 20, Y => 20);
            R := Pixel_At (Px, Width => 120, X => 100, Y => 20);
            Assert (Red_Of (L) > Blue_Of (L), "gradient stroke left sample is red-biased");
            Assert (Blue_Of (R) > Red_Of (R), "gradient stroke right sample is blue-biased");
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/stroke_dash.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "dash SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 50);
         Assert (Px /= null, "dash SVG renders");

         if Px /= null then
            On_P := Alpha_Of (Pixel_At (Px, Width => 120, X => 20, Y => 15));
            Gap_P := Alpha_Of (Pixel_At (Px, Width => 120, X => 50, Y => 15));
            Off_A := Alpha_Of (Pixel_At (Px, Width => 120, X => 12, Y => 35));
            Off_B := Alpha_Of (Pixel_At (Px, Width => 120, X => 30, Y => 35));

            Assert (On_P > Gap_P, "dash array creates lower-alpha gap than dash segment");
            Assert_If_Ada
              (Off_B > Off_A,
               "dash-offset shifts visible dash phase along stroke");
         end if;
      end if;
      Release (Doc, Px);

      New_Line;
   end Test_Stroke_Gradient_Dash_And_Dash_Offset;

   procedure Test_Visibility_Fill_Rule_Opacity_And_Defs is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      A_Display, A_Visibility, A_Ring, A_Hole : Natural := 0;
      A_Fill_Half, A_Opacity_Quarter, A_Stroke_Half : Natural := 0;
   begin
      Put_Line ("Test: display/visibility/fill-rule/opacity/defs");

      Doc := Adi.SVG.Load_From_File ("tests/assets/visibility_defs_fillrule_opacity.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "visibility/fill-rule SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 80);
         Assert (Px /= null, "visibility/fill-rule SVG renders");

         if Px /= null then
            A_Display := Alpha_Of (Pixel_At (Px, Width => 120, X => 10, Y => 10));
            A_Visibility := Alpha_Of (Pixel_At (Px, Width => 120, X => 50, Y => 15));
            A_Ring := Alpha_Of (Pixel_At (Px, Width => 120, X => 75, Y => 10));
            A_Hole := Alpha_Of (Pixel_At (Px, Width => 120, X => 90, Y => 20));
            A_Fill_Half := Alpha_Of (Pixel_At (Px, Width => 120, X => 15, Y => 55));
            A_Opacity_Quarter := Alpha_Of (Pixel_At (Px, Width => 120, X => 35, Y => 55));
            A_Stroke_Half := Alpha_Of (Pixel_At (Px, Width => 120, X => 90, Y => 55));

            Assert (A_Display = 0, "display:none element is not rendered");
            Assert (A_Visibility = 0, "visibility:hidden element is not rendered");
            Assert (A_Ring > 0, "evenodd outer ring area is painted");
            Assert (A_Hole = 0, "evenodd inner hole remains transparent");
            Assert (A_Fill_Half > A_Opacity_Quarter,
                    "fill-opacity and opacity are applied independently");
            Assert (A_Stroke_Half > 0 and then A_Stroke_Half < 255,
                    "stroke-opacity produces partial-alpha stroke");
         end if;
      end if;

      Release (Doc, Px);

      New_Line;
   end Test_Visibility_Fill_Rule_Opacity_And_Defs;

   procedure Test_Use_Symbol_And_Cycle_Safety is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      A_Origin, A_Use, A_Cycle, A_Valid : Natural := 0;
   begin
      Put_Line ("Test: use/symbol and cycle safety");

      Doc := Adi.SVG.Load_From_File ("tests/assets/use_symbol.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "use/symbol SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 48, Height => 48);
         Assert (Px /= null, "use/symbol SVG renders");

         if Px /= null then
            A_Origin := Alpha_Of (Pixel_At (Px, Width => 48, X => 8, Y => 8));
            A_Use := Alpha_Of (Pixel_At (Px, Width => 48, X => 32, Y => 32));
            Assert (A_Origin = 0, "symbol definitions are hidden unless referenced via use");
            Assert (A_Use > 0, "use renders symbol content at translated position");
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/use_cycle.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "use-cycle SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 80, Height => 40);
         Assert (Px /= null, "use-cycle SVG renders without recursion failure");

         if Px /= null then
            A_Cycle := Alpha_Of (Pixel_At (Px, Width => 80, X => 8, Y => 8));
            A_Valid := Alpha_Of (Pixel_At (Px, Width => 80, X => 48, Y => 20));
            Assert (A_Cycle = 0, "cyclic use references are skipped safely");
            Assert (A_Valid > 0, "non-cyclic use reference still renders normally");
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/use_symbol_viewbox.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "use/symbol viewBox SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 60);
         Assert (Px /= null, "use/symbol viewBox SVG renders");

         if Px /= null then
            declare
               A_First_In  : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 20, Y => 20));
               A_First_Out : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 35, Y => 20));
               A_Second_In : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 70, Y => 20));
               A_Second_Out : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 55, Y => 20));
            begin
               Assert_If_Ada
                 (A_First_In > 0 and then A_First_Out = 0,
                  "symbol use width/height scales first instance bounds");
               Assert_If_Ada
                 (A_Second_In > 0 and then A_Second_Out = 0,
                  "symbol use width/height scales second instance with preserved aspect ratio");
            end;
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/use_symbol_preserve.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "use/symbol preserveAspectRatio SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 120, Height => 40);
         Assert (Px /= null, "use/symbol preserveAspectRatio SVG renders");

         if Px /= null then
            declare
               A_Meet_Top   : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 20, Y => 12));
               A_Meet_Mid   : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 20, Y => 20));
               A_None_Top   : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 55, Y => 12));
               A_Use_None_Top : constant Natural := Alpha_Of (Pixel_At (Px, Width => 120, X => 90, Y => 12));
            begin
               Assert_If_Ada
                 (A_Meet_Top = 0 and then A_Meet_Mid > 0,
                  "default preserveAspectRatio meet letterboxes vertically");
               Assert (A_None_Top > 0,
                       "symbol preserveAspectRatio none stretches to full use viewport");
               Assert (A_Use_None_Top > 0,
                       "use-level preserveAspectRatio overrides symbol default");
            end;
         end if;
      end if;
      Release (Doc, Px);

      New_Line;
   end Test_Use_Symbol_And_Cycle_Safety;

   procedure Test_Transforms_And_Units is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
      P_Red, P_Black, P_Empty : Adi.SDL.Uint32 := 0;
   begin
      Put_Line ("Test: transform and length units");

      Doc := Adi.SVG.Load_From_File ("tests/assets/transform_units.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "transform/units SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 192, Height => 96);
         Assert (Px /= null, "transform/units SVG renders");

         if Px /= null then
            P_Red := Pixel_At (Px, Width => 192, X => 10, Y => 10);
            P_Black := Pixel_At (Px, Width => 192, X => 140, Y => 20);
            P_Empty := Pixel_At (Px, Width => 192, X => 70, Y => 20);

            Assert (Red_Of (P_Red) > Green_Of (P_Red) and then Red_Of (P_Red) > Blue_Of (P_Red),
                    "mm-sized shape resolves and renders in red");
            Assert
              (Alpha_Of (P_Black) > 0
               and then Red_Of (P_Black) < 32
               and then Green_Of (P_Black) < 32
               and then Blue_Of (P_Black) < 32,
               "translated rectangle renders in expected transformed area");
            Assert (Alpha_Of (P_Empty) = 0, "gap between primitives remains transparent");
         end if;
      end if;
      Release (Doc, Px);

      New_Line;
   end Test_Transforms_And_Units;

   procedure Test_Root_ViewBox_Preserve_Aspect is
      Doc : Adi.SVG.Document_Access := null;
      Px  : Adi.SVG.Pixel_Buffer_Access := null;
   begin
      Put_Line ("Test: root viewBox preserveAspectRatio");

      Doc := Adi.SVG.Load_From_File ("tests/assets/root_meet.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "root meet SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 40, Height => 40);
         Assert (Px /= null, "root meet SVG renders");

         if Px /= null then
            declare
               A_Top : constant Natural := Alpha_Of (Pixel_At (Px, Width => 40, X => 20, Y => 8));
               A_Mid : constant Natural := Alpha_Of (Pixel_At (Px, Width => 40, X => 20, Y => 20));
            begin
               Assert_If_Ada
                 (A_Top = 0 and then A_Mid > 0,
                  "default root preserveAspectRatio meet letterboxes in taller viewport");
            end;
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/root_none.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "root none SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 40, Height => 40);
         Assert (Px /= null, "root none SVG renders");

         if Px /= null then
            declare
               A_Top : constant Natural := Alpha_Of (Pixel_At (Px, Width => 40, X => 20, Y => 8));
            begin
               Assert (A_Top > 0,
                       "root preserveAspectRatio none stretches to fill taller viewport");
            end;
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/root_slice.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "root slice SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 40, Height => 40);
         Assert (Px /= null, "root slice SVG renders");

         if Px /= null then
            declare
               Corner : constant Adi.SDL.Uint32 := Pixel_At (Px, Width => 40, X => 2, Y => 2);
               Center : constant Adi.SDL.Uint32 := Pixel_At (Px, Width => 40, X => 20, Y => 20);
               Side   : constant Adi.SDL.Uint32 := Pixel_At (Px, Width => 40, X => 8, Y => 20);
            begin
               Assert (Alpha_Of (Corner) > 0,
                       "root preserveAspectRatio slice covers viewport corners");
               Assert
                 (Red_Of (Center) > 200 and then Green_Of (Center) > 200 and then Blue_Of (Center) > 200,
                  "root slice keeps center stripe aligned and visible");
               Assert (Blue_Of (Side) > Red_Of (Side),
                       "root slice keeps non-stripe side area blue");
            end;
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/root_align_min.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "root xMin align SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 60, Height => 20);
         Assert (Px /= null, "root xMin align SVG renders");

         if Px /= null then
            declare
               A_Left  : constant Natural := Alpha_Of (Pixel_At (Px, Width => 60, X => 5, Y => 10));
               A_Right : constant Natural := Alpha_Of (Pixel_At (Px, Width => 60, X => 55, Y => 10));
            begin
               Assert_If_Ada
                 (A_Left > 0 and then A_Right = 0,
                  "root xMin alignment anchors meet result to left side");
            end;
         end if;
      end if;
      Release (Doc, Px);

      Doc := Adi.SVG.Load_From_File ("tests/assets/root_align_max.svg");
      Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), "root xMax align SVG loads");

      if Doc /= null and then Adi.SVG.Is_Valid (Doc.all) then
         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 60, Height => 20);
         Assert (Px /= null, "root xMax align SVG renders");

         if Px /= null then
            declare
               A_Left  : constant Natural := Alpha_Of (Pixel_At (Px, Width => 60, X => 5, Y => 10));
               A_Right : constant Natural := Alpha_Of (Pixel_At (Px, Width => 60, X => 55, Y => 10));
            begin
               Assert_If_Ada
                 (A_Left = 0 and then A_Right > 0,
                  "root xMax alignment anchors meet result to right side");
            end;
         end if;
      end if;
      Release (Doc, Px);

      New_Line;
   end Test_Root_ViewBox_Preserve_Aspect;

   procedure Test_Complex_SVG_Rendering is
      procedure Probe
        (Path          : String;
         Label         : String;
         Need_Pixels   : Natural;
         Need_AA_Edges : Boolean;
         Need_Colorful : Natural := 0)
      is
         Doc   : Adi.SVG.Document_Access := Adi.SVG.Load_From_File (Path);
         Px    : Adi.SVG.Pixel_Buffer_Access := null;
         Solid : Natural := 0;
         AA    : Natural := 0;
         Colorful : Natural := 0;
      begin
         Assert (Doc /= null and then Adi.SVG.Is_Valid (Doc.all), Label & " SVG loads");
         if Doc = null or else not Adi.SVG.Is_Valid (Doc.all) then
            return;
         end if;

         Px := Adi.SVG.Render_ARGB32 (Doc.all, Width => 256, Height => 256);
         Assert (Px /= null, Label & " renders to pixel buffer");

         if Px /= null then
            for I in Px'Range loop
               declare
                  A : constant Natural := Alpha_Of (Px (I));
               begin
                  if A > 0 then
                     Solid := Solid + 1;
                     if A < 255 then
                        AA := AA + 1;
                     end if;

                     if abs (Integer (Red_Of (Px (I))) - Integer (Green_Of (Px (I)))) > 6
                       or else abs (Integer (Green_Of (Px (I))) - Integer (Blue_Of (Px (I)))) > 6
                       or else abs (Integer (Red_Of (Px (I))) - Integer (Blue_Of (Px (I)))) > 6
                     then
                        Colorful := Colorful + 1;
                     end if;
                  end if;
               end;
            end loop;

            Assert (Solid >= Need_Pixels, Label & " draws non-empty output");
            if Need_AA_Edges then
               Assert_If_Strict_AA (AA > 0, Label & " has anti-aliased edge pixels");
            end if;

            if Need_Colorful > 0 then
               Assert (Colorful >= Need_Colorful, Label & " keeps rich gradient/color detail");
            end if;
         end if;

         Release (Doc, Px);
      end Probe;
   begin
      Put_Line ("Test: complex SVG rendering and AA");

      Probe
        (Path => "tests/assets/cat.svg",
         Label => "cat",
         Need_Pixels => 2_000,
         Need_AA_Edges => True);

      Probe
        (Path => "tests/assets/tiger.svg",
         Label => "tiger",
         Need_Pixels => 8_000,
         Need_AA_Edges => True);

      Probe
        (Path => "tests/assets/camera.svg",
         Label => "camera",
         Need_Pixels => 10_000,
         Need_AA_Edges => True,
         Need_Colorful => 500);

      New_Line;
   end Test_Complex_SVG_Rendering;

begin
   Put_Line ("SVG renderer test backend=" & Adi.SVG.Backend_Name);
   Put_Line ("");

   Test_Document_Size_And_Validity;
   Test_Image_Integration;
   Test_Load_From_String_And_Path;
   Test_Color_Forms;
   Test_Path_Commands_And_AA;
   Test_Gradient_Fills;
   Test_Paint_URL_Fallback_Syntax;
   Test_Stroke_Styles;
   Test_Stroke_Gradient_Dash_And_Dash_Offset;
   Test_Visibility_Fill_Rule_Opacity_And_Defs;
   Test_Use_Symbol_And_Cycle_Safety;
   Test_Transforms_And_Units;
   Test_Root_ViewBox_Preserve_Aspect;
   Test_Complex_SVG_Rendering;

   Test_Support.Finish;
end Svg_Test;
