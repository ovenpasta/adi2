pragma Ada_2022;

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

--  A rounded panel is drawn as a border ring, a fill inside it, and antialias
--  fringes. Both fringes used to be the border's colour, which is only enough
--  to smooth the edge when the border itself is opaque enough to stand between
--  the fill and whatever is behind it. A pale fill behind a nearly transparent
--  border therefore stepped straight from backdrop to fill in one pixel, and
--  the curve read as stairs -- the switch knob being the case that showed it.

procedure Panel_AA_Test is

   Canvas_W : constant := 120;
   Canvas_H : constant := 80;

   --  The backdrop the panel is composited onto, and its own fill: far
   --  apart, so an unblended edge is unmistakable.
   Back_G : constant := 70;
   Fill_L : constant := 250;

   --  The panel, and the two rows worth reading. Its corner radius is half
   --  its height, so the left boundary is vertical only at the exact middle;
   --  a row above that crosses the curve, which is where a missing blend
   --  shows as stairs rather than as one hard edge.
   Panel_X : constant := 30.0;
   Panel_Y : constant := 14.0;
   Panel_W : constant := 52.0;
   Panel_H : constant := 52.0;
   Tangent_Row : constant := 40;   --  vertical part of the boundary
   Curve_Row   : constant := 22;   --  diagonal part

   type Luma_Row is array (0 .. Canvas_W - 1) of Natural;

   type Row_List is array (Positive range <>) of Natural;
   Sample_Rows : constant Row_List := [Tangent_Row, Curve_Row];

   --  Render one rounded panel and return the green channel along a row.
   function Edge_Row (Border_Alpha : Float;
                      Sample_Y     : Natural;
                      Opacity      : Float := 1.0) return Luma_Row
   is
      Canvas : constant SDL_Surface_Ptr :=
        SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                           SDL_PIXELFORMAT_RGBA32);
      Renderer : SDL_Renderer_Ptr;
      Ctx      : Adi.Render.Render_Context;
      Panel    : constant Box_Handle := Create_Handle;
      Unused   : Adi.SDL.C_bool;
      Result   : Luma_Row := [others => 0];

      Style : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (Fill_L, Fill_L, Fill_L)),
               Border_Width     => Set (Border_Width (Px (1.0))),
               Border_Color     =>
                 Set (Border_Color (RGBA (15, 23, 42, Border_Alpha))),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Radius    => Set (Radius (Px (26.0))),
               Opacity          => Set (Opacity_Value (Opacity)),
               others           => <>)).Build;
   begin
      if Canvas = null then
         Assert (False, "SDL should provide a surface");
         return Result;
      end if;

      Renderer := SDL_CreateSoftwareRenderer (Canvas);
      if Renderer = null then
         Assert (False, "SDL should provide a software renderer");
         return Result;
      end if;

      Unused := SDL_SetRenderDrawColor (Renderer, 58, Back_G, 90, 255);
      Unused := SDL_RenderClear (Renderer);

      Adi.Render.Create (Ctx, Renderer);

      Set_Part_Styles
        (Panel, [Main_Part => (Style => Style, Enabled => True),
                 others    => <>]);
      Set_Geometry (+Panel, (X => Panel_X, Y => Panel_Y,
                             Width => Panel_W, Height => Panel_H));
      Build_Items (+Panel);
      Render_Tree (+Panel, Ctx);
      Unused := SDL_RenderPresent (Renderer);

      --  Read through SDL, so the surface's own layout is respected rather
      --  than assumed from a packed integer.
      for X in 0 .. Canvas_W - 1 loop
         declare
            PR, PG, PB, PA : aliased Uint8;
         begin
            if Boolean (SDL_ReadSurfacePixel
                          (Canvas, int (X), int (Sample_Y),
                           PR'Access, PG'Access, PB'Access, PA'Access))
            then
               Result (X) := Natural (PG);
            end if;
         end;
      end loop;

      Adi.Render.Destroy (Ctx);
      SDL_DestroyRenderer (Renderer);
      SDL_DestroySurface (Canvas);
      return Result;
   end Edge_Row;

   --  Biggest one-pixel step anywhere along the row. An edge blended over
   --  several pixels keeps this well below the full backdrop-to-fill range.
   function Worst_Step (Row : Luma_Row) return Natural is
      Worst : Natural := 0;
   begin
      for X in 1 .. Canvas_W - 1 loop
         Worst := Natural'Max (Worst, abs (Row (X) - Row (X - 1)));
      end loop;
      return Worst;
   end Worst_Step;

   --  Pixels that are neither backdrop nor fill: the blend itself.
   function Intermediate_Count (Row : Luma_Row) return Natural is
      Count : Natural := 0;
   begin
      for X in Luma_Row'Range loop
         if Row (X) > Back_G + 12 and then Row (X) < Fill_L - 12 then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Intermediate_Count;

   function Darkest (Row : Luma_Row) return Natural is
      Low : Natural := 255;
   begin
      for X in Luma_Row'Range loop
         Low := Natural'Min (Low, Row (X));
      end loop;
      return Low;
   end Darkest;

begin
   Start_Suite ("Panel AA test");

   --  The case the fix is for: a border too faint to blend anything. Read
   --  at the boundary's vertical part and again across the curve.
   for Sample_Y of Sample_Rows loop
      declare
         Profile : constant Luma_Row := Edge_Row (0.12, Sample_Y);
         Step    : constant Natural := Worst_Step (Profile);
      begin
         Assert (Intermediate_Count (Profile) >= 2,
                 "A pale fill behind a translucent border should blend into"
                 & " the backdrop over more than one pixel, at row"
                 & Natural'Image (Sample_Y));
         Assert (Step < (Fill_L - Back_G) * 3 / 4,
                 "No single pixel should carry most of the edge, at row"
                 & Natural'Image (Sample_Y) & ":" & Natural'Image (Step));
      end;
   end loop;

   --  The blend is weighted by what the border cannot supply, so an opaque
   --  border keeps its own pixel: fading the fill over it unconditionally
   --  would erase half of a one-pixel border. The border is rgb(15,23,42),
   --  so its pixel must still read close to that. The ring's outer fringe
   --  stays dark whatever happens to the border, so a bound loose enough to
   --  catch that pixel proves nothing -- this one lands on the border.
   declare
      Profile : constant Luma_Row := Edge_Row (1.0, Tangent_Row);
   begin
      Assert (Darkest (Profile) <= 35,
              "An opaque border should still render its own colour:"
              & Natural'Image (Darkest (Profile)));
   end;

   --  Opacity fades border and fill together, so it must not be mistaken
   --  for a border that cannot blend. At half opacity an opaque border is
   --  still opaque relative to the panel and keeps its pixel; weighting by
   --  the effective alpha rather than the declared one would paint the fill
   --  over it.
   declare
      Profile : constant Luma_Row := Edge_Row (1.0, Tangent_Row, 0.5);
   begin
      Assert (Darkest (Profile) <= 50,
              "A half-transparent panel's opaque border should keep its"
              & " pixel:" & Natural'Image (Darkest (Profile)));
   end;

   --  Outside is backdrop, the middle is fill.
   declare
      Profile : constant Luma_Row := Edge_Row (0.12, Tangent_Row);
   begin
      Assert (Profile (Canvas_W / 2) > Fill_L - 12,
              "The panel's middle should be its fill colour");
      Assert (Profile (0) < Back_G + 12
                and then Profile (Canvas_W - 1) < Back_G + 12,
              "Outside the panel should be the backdrop");
   end;

   Finish;
end Panel_AA_Test;
