pragma Ada_2022;
with Ada.Text_IO;    use Ada.Text_IO;
with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.Window;     use Adi.Window;
with Test_Support;

procedure Window_Extent_Test is
   Usable : constant Size_2D := (1920.0, 1080.0);

   procedure Show (Name : String; R : Resolved_Extent) is
   begin
      Put_Line ("  " & Name & ": coords="
                & Integer'Image (Integer (R.Coords.Width)) & "x"
                & Integer'Image (Integer (R.Coords.Height))
                & "  pixels=" & Integer'Image (Integer (R.Pixels.Width))
                & "x" & Integer'Image (Integer (R.Pixels.Height)));
   end Show;

   function R (E : Window_Extent; Scale, Density : Pixel_Type;
               Mapped : Boolean := True) return Resolved_Extent
   is (Resolve_Extent (E, Scale, Density, Usable, Mapped));

   Six_Hundred : constant Window_Extent := Extent (Dip (600), Dip (400));
   Exact       : constant Window_Extent := Extent (Pix (600), Pix (400));
   Mapped_Px   : constant Window_Extent := Extent (Px (600), Px (400));
   Half        : constant Window_Extent := Extent (Pct (50), Pct (50));
begin
   Test_Support.Start_Suite ("Window_Extent_Test");
   New_Line;

   --  A dp extent is the same framebuffer everywhere at a given display
   --  scale; only the coordinates SDL is handed differ, by the density.
   Put_Line ("=== 600x400dp across platform models ===");
   declare
      Plain   : constant Resolved_Extent := R (Six_Hundred, 1.0, 1.0);
      X11     : constant Resolved_Extent := R (Six_Hundred, 1.5, 1.0);
      Wayland : constant Resolved_Extent := R (Six_Hundred, 1.5, 1.5);
      Retina  : constant Resolved_Extent := R (Six_Hundred, 2.0, 2.0);
   begin
      Show ("scale 1.0 density 1.0", Plain);
      Show ("scale 1.5 density 1.0", X11);
      Show ("scale 1.5 density 1.5", Wayland);
      Show ("scale 2.0 density 2.0", Retina);

      Test_Support.Assert
        (abs (Plain.Pixels.Width - 600.0) < 0.001,
         "at scale 1 a 600dp window is 600 pixels");
      Test_Support.Assert
        (abs (X11.Pixels.Width - 900.0) < 0.001
           and then abs (X11.Coords.Width - 900.0) < 0.001,
         "on X11 the display scale grows both, density being 1");
      Test_Support.Assert
        (abs (Wayland.Pixels.Width - 900.0) < 0.001
           and then abs (Wayland.Coords.Width - 600.0) < 0.001,
         "on Wayland the same 900 pixels are asked for as 600 coordinates");
      Test_Support.Assert
        (abs (Wayland.Pixels.Width - X11.Pixels.Width) < 0.001,
         "so the framebuffer matches across platform models");
      Test_Support.Assert
        (abs (Retina.Pixels.Width - 1200.0) < 0.001
           and then abs (Retina.Coords.Width - 600.0) < 0.001,
         "and a 2x retina window is 1200 pixels from 600 coordinates");
   end;

   New_Line;
   Put_Line ("=== pix is exact, px follows the mapping ===");
   declare
      P  : constant Resolved_Extent := R (Exact, 1.5, 1.5);
      M  : constant Resolved_Extent := R (Mapped_Px, 1.5, 1.0);
      U  : constant Resolved_Extent := R (Mapped_Px, 1.5, 1.0, Mapped => False);
      H  : constant Resolved_Extent := R (Half, 1.5, 1.0);
   begin
      Show ("600pix @1.5/1.5", P);
      Show ("600px mapped    ", M);
      Show ("600px unmapped  ", U);
      Show ("50% of 1920     ", H);

      Test_Support.Assert
        (abs (P.Pixels.Width - 600.0) < 0.001
           and then abs (P.Coords.Width - 400.0) < 0.001,
         "pix asks for exactly 600 pixels, whatever the density");
      Test_Support.Assert
        (abs (M.Pixels.Width - 900.0) < 0.001,
         "px scales when the app maps px to dip");
      Test_Support.Assert
        (abs (U.Pixels.Width - 600.0) < 0.001,
         "and stays put when it does not");
      Test_Support.Assert
        (abs (H.Coords.Width - 960.0) < 0.001,
         "a percentage is a share of the usable bounds, in coordinates");
   end;

   New_Line;
   Put_Line ("=== units that cannot describe a window ===");
   declare
      function Rejects (L : Length_Value) return Boolean is
         Ignored : Window_Extent;
      begin
         Ignored := Extent (L, Dip (400));
         return False;
      exception
         when Constraint_Error => return True;
      end Rejects;
   begin
      Test_Support.Assert
        (Rejects (Em (10)) and then Rejects (Root_Em (10)),
         "em and rem are refused: there is no font context here");
      Test_Support.Assert
        (Rejects (Vw (50)) and then Rejects (Vh (50)),
         "vw and vh are refused: they would resolve against the viewport "
         & "being defined");
      Test_Support.Assert
        (not Rejects (Pix (600)) and then not Rejects (Pct (50)),
         "pix and % are accepted");
   end;

   New_Line;
   Put_Line ("=== UI scale stays out of it; a lost density falls back ===");
   declare
      Dp   : constant Window_Extent := Extent (Dip (600), Dip (400));
      Mapd : constant Window_Extent := Extent (Px (600), Px (400));
      Exct : constant Window_Extent := Extent (Pix (600), Pix (400));
      Zoomed_Dp, Zoomed_Px, No_Density : Resolved_Extent;
   begin
      --  Set the process-wide UI scale first: a window that grew with it
      --  would cancel the zoom it is meant to apply inside the viewport,
      --  and the scale is normally set well after the window exists.
      Adi.Layout_Util.Set_Active_UI_Scale (1.25);
      Zoomed_Dp := Resolve_Extent (Dp, 1.5, 1.0, Usable, True);
      Zoomed_Px := Resolve_Extent (Mapd, 1.5, 1.0, Usable, True);
      No_Density := Resolve_Extent (Exct, 1.5, 0.0, Usable, True);
      Adi.Layout_Util.Set_Active_UI_Scale (1.0);

      Show ("600dp @1.5, UI 1.25", Zoomed_Dp);
      Show ("600px @1.5, UI 1.25", Zoomed_Px);
      Show ("600pix, density 0  ", No_Density);

      --  600 * 1.5, with the UI scale deliberately absent.
      Test_Support.Assert
        (abs (Zoomed_Dp.Pixels.Width - 900.0) < 0.001,
         "dp takes the display scale and not the UI scale");
      Test_Support.Assert
        (abs (Zoomed_Px.Pixels.Width - 900.0) < 0.001,
         "and mapped px is likewise independent of UI scaling");
      Test_Support.Assert
        (abs (No_Density.Pixels.Width - 600.0) < 0.001
           and then abs (No_Density.Coords.Width - 600.0) < 0.001,
         "a density SDL could not report falls back to parity, not to a "
         & "window thousands of pixels wide");
   end;

   New_Line;
   Put_Line ("=== sizes SDL would reject ===");
   declare
      function Rejects (W, H : Length_Value) return Boolean is
         Ignored : Window_Extent;
      begin
         Ignored := Extent (W, H);
         return False;
      exception
         when Constraint_Error => return True;
      end Rejects;
   begin
      Test_Support.Assert
        (Rejects (Pix (0), Pix (400)) and then Rejects (Pix (600), Pix (0)),
         "a zero extent is refused on either axis");
      Test_Support.Assert
        (Rejects (Dip (-1), Dip (400)),
         "and so is a negative one");
   end;

   New_Line;

   --  The resolver being right proves nothing about the window that gets
   --  made: the bootstrap is created at 100x100 and resized, so a window
   --  that never picks up its extent still looks fine to every test
   --  above.
   Put_Line ("=== a created window reports its requested extent ===");
   declare
      A : Adi.App.App;
   begin
      A.Init;
      declare
         W : Window_Handle :=
           Create_Window_Handle ("Extent", Extent (Pix (640), Pix (480)));
         Got : constant Size_2D := Get_Size (W);
      begin
         Put_Line ("  asked 640x480pix, got"
                   & Integer'Image (Integer (Got.Width)) & "x"
                   & Integer'Image (Integer (Got.Height)));
         Test_Support.Assert
           (abs (Got.Width - 100.0) > 0.5
              and then abs (Got.Height - 100.0) > 0.5,
            "the window is not still the 100x100 bootstrap");
         --  A window manager may constrain a request, so this asserts the
         --  extent was applied, not that it was granted exactly.
         Test_Support.Assert
           (abs (Got.Width - 640.0) < 2.0
              and then abs (Got.Height - 480.0) < 2.0,
            "and reports the pixel extent it was asked for");
         Destroy (W);
      end;
   end;

   New_Line;
   Test_Support.Finish;
end Window_Extent_Test;
