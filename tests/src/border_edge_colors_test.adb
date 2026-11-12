pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Adi.Core;            use Adi.Core;
with Adi.CSS_Styles;      use Adi.CSS_Styles;
with Adi.Render;
with Adi.SDL;             use Adi.SDL;
with Adi.SDL.Render;      use Adi.SDL.Render;
with Adi.SDL.Surface;     use Adi.SDL.Surface;
with Adi.SDL.PixelFormat; use Adi.SDL.PixelFormat;
with Adi.Widget;          use Adi.Widget;
with Adi.Widget.Box;      use Adi.Widget.Box;
with Adi.Widget_Styles;   use Adi.Widget_Styles;
with Interfaces.C;        use Interfaces.C;
with Test_Support;        use Test_Support;

--  A rounded border of uniform width paints each edge, corner half and
--  AA fringe in that edge's own border-color.

procedure Border_Edge_Colors_Test is

   use Ada.Numerics.Elementary_Functions;

   Canvas_W : constant := 120;
   Canvas_H : constant := 120;

   --  An 80px box at (20, 20): a 4px border with 16px corners, so the
   --  border runs 20 .. 23 and 96 .. 99 and each corner arc is centred
   --  16px in from its corner.
   Box_X  : constant := 20;
   Box_Y  : constant := 20;
   Box_W  : constant := 80;
   Box_H  : constant := 80;
   Border_Px : constant := 4.0;
   Corner_Px : constant := 16.0;

   type RGB_Pixel is record
      R, G, B : Natural;
   end record;

   Top_C    : constant RGB_Pixel := (220, 30, 30);
   Right_C  : constant RGB_Pixel := (30, 200, 30);
   Bottom_C : constant RGB_Pixel := (30, 30, 220);
   Left_C   : constant RGB_Pixel := (220, 200, 30);

   Canvas   : SDL_Surface_Ptr;
   Renderer : SDL_Renderer_Ptr;
   Ctx      : Adi.Render.Render_Context;

   function To_CSS (P : RGB_Pixel) return Color_Value is
     (RGB (P.R, P.G, P.B));

   Backdrop : constant RGB_Pixel := (60, 60, 60);

   --  Clear the canvas to Backdrop and paint one box with the four edge
   --  colours over a white fill
   procedure Render_Box
     (X, Y, W, H : Natural;
      Border     : Float := Border_Px;
      Corner     : Float := Corner_Px;
      Opacity    : Float := 1.0)
   is
      Box    : constant Box_Handle := Create_Handle;
      Unused : Adi.SDL.C_bool;
      Style  : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (255, 255, 255)),
               Border_Width     => Set (Border_Width (Px (Border))),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Color     =>
                 Set (Border_Color (Top    => To_CSS (Top_C),
                                    Right  => To_CSS (Right_C),
                                    Bottom => To_CSS (Bottom_C),
                                    Left   => To_CSS (Left_C))),
               Border_Radius    => Set (Radius (Px (Corner))),
               Opacity          => Set (Opacity_Value (Opacity)),
               others           => <>)).Build;
   begin
      Unused := SDL_SetRenderDrawColor
        (Renderer, Uint8 (Backdrop.R), Uint8 (Backdrop.G),
         Uint8 (Backdrop.B), 255);
      Unused := SDL_RenderClear (Renderer);
      Adi.Render.Create (Ctx, Renderer);

      Set_Part_Styles
        (Box, [Main_Part => (Style => Style, Enabled => True),
               others    => <>]);
      Set_Geometry (+Box, (X      => Pixel_Type (X),
                           Y      => Pixel_Type (Y),
                           Width  => Pixel_Type (W),
                           Height => Pixel_Type (H)));
      Build_Items (+Box);
      Render_Tree (+Box, Ctx);
      Unused := SDL_RenderPresent (Renderer);
      Adi.Render.Destroy (Ctx);
   end Render_Box;

   function Pixel (X, Y : Natural) return RGB_Pixel is
      PR, PG, PB, PA : aliased Uint8;
   begin
      if Boolean (SDL_ReadSurfacePixel
                    (Canvas, int (X), int (Y),
                     PR'Access, PG'Access, PB'Access, PA'Access))
      then
         return (Natural (PR), Natural (PG), Natural (PB));
      end if;
      return (0, 0, 0);
   end Pixel;

   function Near (P, Want : RGB_Pixel) return Boolean is
     (abs (P.R - Want.R) <= 24
      and then abs (P.G - Want.G) <= 24
      and then abs (P.B - Want.B) <= 24);

   --  The pixel halfway through the border at Angle on the arc centred at
   --  (Cx, Cy). Angles run clockwise from +x, y pointing down.
   function Arc_Pixel (Cx, Cy : Float; Angle : Float) return RGB_Pixel is
      Mid : constant Float := Corner_Px - Border_Px / 2.0;
   begin
      return Pixel (Natural (Float'Floor (Cx + Mid * Cos (Angle))),
                    Natural (Float'Floor (Cy + Mid * Sin (Angle))));
   end Arc_Pixel;

   procedure Test_Edges is
   begin
      Section ("Edge midpoints");
      Assert (Near (Pixel (60, 21), Top_C), "top edge in its colour");
      Assert (Near (Pixel (98, 60), Right_C), "right edge in its colour");
      Assert (Near (Pixel (60, 98), Bottom_C), "bottom edge in its colour");
      Assert (Near (Pixel (21, 60), Left_C), "left edge in its colour");
   end Test_Edges;

   procedure Test_Corners is
      Pi : constant := Ada.Numerics.Pi;
      Q  : constant := Pi / 2.0;
      L  : constant Float := Float (Box_X) + Corner_Px;
      T  : constant Float := Float (Box_Y) + Corner_Px;
      R  : constant Float := Float (Box_X + Box_W) - Corner_Px;
      B  : constant Float := Float (Box_Y + Box_H) - Corner_Px;
   begin
      Section ("Corners split between their two edges");
      Assert (Near (Arc_Pixel (L, T, Pi + 0.2 * Q), Left_C),
              "top-left corner, left half");
      Assert (Near (Arc_Pixel (L, T, Pi + 0.8 * Q), Top_C),
              "top-left corner, top half");
      Assert (Near (Arc_Pixel (R, T, 3.0 * Q + 0.2 * Q), Top_C),
              "top-right corner, top half");
      Assert (Near (Arc_Pixel (R, T, 3.0 * Q + 0.8 * Q), Right_C),
              "top-right corner, right half");
      Assert (Near (Arc_Pixel (R, B, 0.2 * Q), Right_C),
              "bottom-right corner, right half");
      Assert (Near (Arc_Pixel (R, B, 0.8 * Q), Bottom_C),
              "bottom-right corner, bottom half");
      Assert (Near (Arc_Pixel (L, B, Q + 0.2 * Q), Bottom_C),
              "bottom-left corner, bottom half");
      Assert (Near (Arc_Pixel (L, B, Q + 0.8 * Q), Left_C),
              "bottom-left corner, left half");
   end Test_Corners;

   procedure Test_Fringes is
      Outer_Right  : constant RGB_Pixel := Pixel (100, 60);
      Outer_Bottom : constant RGB_Pixel := Pixel (60, 100);
      Inner_Right  : constant RGB_Pixel := Pixel (95, 60);
      Inner_Bottom : constant RGB_Pixel := Pixel (60, 95);
   begin
      Section ("AA fringes take their edge's colour");
      Assert (Outer_Right.G > Outer_Right.R + 40,
              "outer fringe of the right edge blends toward green");
      Assert (Outer_Bottom.B > Outer_Bottom.R + 40,
              "outer fringe of the bottom edge blends toward blue");
      Assert (Inner_Right.G > Inner_Right.R + 40,
              "inner fringe of the right edge blends toward green");
      Assert (Inner_Bottom.B > Inner_Bottom.R + 40,
              "inner fringe of the bottom edge blends toward blue");
   end Test_Fringes;

   --  Half opacity: each edge halfway between its colour and the backdrop
   procedure Test_Opacity is
      function Half (C : RGB_Pixel) return RGB_Pixel is
        ((C.R + Backdrop.R) / 2, (C.G + Backdrop.G) / 2,
         (C.B + Backdrop.B) / 2);
   begin
      Section ("Opacity fades each edge's own colour");
      Render_Box (Box_X, Box_Y, Box_W, Box_H, Opacity => 0.5);
      Assert (Near (Pixel (60, 21), Half (Top_C)), "top edge at half opacity");
      Assert (Near (Pixel (98, 60), Half (Right_C)),
              "right edge at half opacity");
      Assert (Near (Pixel (60, 98), Half (Bottom_C)),
              "bottom edge at half opacity");
      Assert (Near (Pixel (21, 60), Half (Left_C)),
              "left edge at half opacity");
   end Test_Opacity;

   --  A 20px box with a 24px border: no room inside, so the border is
   --  the whole box and nothing past it
   procedure Test_Border_Wider_Than_Box is
   begin
      Section ("A border wider than the box fills exactly the box");
      Render_Box (20, 20, 20, 20, Border => 24.0, Corner => 6.0);
      Assert (Pixel (30, 30) /= Backdrop, "the middle is painted");
      Assert (Pixel (23, 30) /= Backdrop, "near the left side is painted");
      Assert (Pixel (37, 30) /= Backdrop, "near the right side is painted");
      Assert (Pixel (30, 23) /= Backdrop, "near the top is painted");
      Assert (Pixel (30, 37) /= Backdrop, "near the bottom is painted");
      Assert (Pixel (42, 42) = Backdrop, "nothing past the bottom right");
      Assert (Pixel (43, 30) = Backdrop, "nothing past the right side");
      Assert (Pixel (30, 43) = Backdrop, "nothing past the bottom");
   end Test_Border_Wider_Than_Box;

begin
   Start_Suite ("Border Edge Colors Test");

   Canvas := SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                                SDL_PIXELFORMAT_RGBA32);
   Assert (Canvas /= null, "SDL should provide a surface");
   if Canvas /= null then
      Renderer := SDL_CreateSoftwareRenderer (Canvas);
      Assert (Renderer /= null, "SDL should provide a software renderer");
      if Renderer /= null then
         Render_Box (Box_X, Box_Y, Box_W, Box_H);
         Test_Edges;
         Test_Corners;
         Test_Fringes;
         Test_Opacity;
         Test_Border_Wider_Than_Box;
         SDL_DestroyRenderer (Renderer);
      end if;
      SDL_DestroySurface (Canvas);
   end if;

   Finish;
end Border_Edge_Colors_Test;
