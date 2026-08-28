pragma Ada_2022;

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

--  Every stop has to survive being drawn on a rounded box. The interior
--  ones are what is at risk: a tessellation coarser than the spacing
--  between stops interpolates straight past them, and the colour that
--  comes out is a blend of whichever vertices the shape happens to have.
--  A long thin bar is where that spacing is finest against the geometry.

procedure Gradient_Stops_Test is

   Canvas_W : constant := 240;
   Canvas_H : constant := 40;

   Bar_X : constant := 10.0;
   Bar_Y : constant := 10.0;
   Bar_W : constant := 200.0;
   Bar_H : constant := 20.0;

   --  Five stops, auto-distributed to 0, 1/4, 1/2, 3/4 and 1. The two at
   --  the quarters are the ones a centre fan cannot see.
   Stops : constant Gradient_Stop_Array :=
     [1      => Gradient_Stop_Auto (RGB (255, 0, 0)),
      2      => Gradient_Stop_Auto (RGB (0, 255, 0)),
      3      => Gradient_Stop_Auto (RGB (0, 0, 255)),
      4      => Gradient_Stop_Auto (RGB (0, 255, 0)),
      5      => Gradient_Stop_Auto (RGB (255, 0, 0)),
      others => <>];

   type Channels is record
      R, G, B : Natural := 0;
   end record;

   type Sample_Row is array (0 .. Canvas_W - 1) of Channels;

   --  A stop may sit outside 0 .. 1, and everything before the first
   --  one takes its colour. A bar whose stops both sit past its end is
   --  therefore filled with the first colour, not left unpainted.
   Far_Stops : constant Gradient_Stop_Array :=
     [1      => Gradient_Stop_At (RGB (255, 0, 0), 1.5),
      2      => Gradient_Stop_At (RGB (0, 0, 255), 2.0),
      others => <>];

   function Bar_Row (Radius : Float;
                     Which  : Gradient_Stop_Array := Stops;
                     Count  : Natural             := 5) return Sample_Row is
      Canvas : constant SDL_Surface_Ptr :=
        SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                           SDL_PIXELFORMAT_RGBA32);
      Renderer : SDL_Renderer_Ptr;
      Ctx      : Adi.Render.Render_Context;
      Bar      : constant Box_Handle := Create_Handle;
      Unused   : Adi.SDL.C_bool;
      Result   : Sample_Row := [others => <>];

      Style : constant Widget_Style :=
        From ((Background_Image =>
                 Set_Bg_Image (Linear_Gradient (90.0, Which, Count)),
               Border_Radius    => Set (Adi.CSS_Styles.Radius (Px (Radius))),
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

      Unused := SDL_SetRenderDrawColor (Renderer, 0, 0, 0, 255);
      Unused := SDL_RenderClear (Renderer);

      Adi.Render.Create (Ctx, Renderer);

      Set_Part_Styles
        (Bar, [Main_Part => (Style => Style, Enabled => True),
               others    => <>]);
      Set_Geometry (+Bar, (X => Bar_X, Y => Bar_Y,
                           Width => Bar_W, Height => Bar_H));
      Build_Items (+Bar);
      Render_Tree (+Bar, Ctx);
      Unused := SDL_RenderPresent (Renderer);

      for X in 0 .. Canvas_W - 1 loop
         declare
            PR, PG, PB, PA : aliased Uint8;
         begin
            if Boolean (SDL_ReadSurfacePixel
                          (Canvas, int (X), int (Bar_Y + Bar_H / 2.0),
                           PR'Access, PG'Access, PB'Access, PA'Access))
            then
               Result (X) := (R => Natural (PR),
                              G => Natural (PG),
                              B => Natural (PB));
            end if;
         end;
      end loop;

      Adi.Render.Destroy (Ctx);
      SDL_DestroyRenderer (Renderer);
      SDL_DestroySurface (Canvas);
      return Result;
   end Bar_Row;

   --  The pixel at a fraction along the bar.
   function At_Fraction (Row : Sample_Row; T : Float) return Channels is
     (Row (Natural (Bar_X + T * Bar_W)));

   Near : constant := 40;

   procedure Check_Stops (Row : Sample_Row; Shape : String) is
      Quarter       : constant Channels := At_Fraction (Row, 0.25);
      Middle        : constant Channels := At_Fraction (Row, 0.5);
      Three_Quarter : constant Channels := At_Fraction (Row, 0.75);
   begin
      Assert (Quarter.G > 255 - Near,
              Shape & ": the stop a quarter along is its own colour");
      Assert (Quarter.R < Near and then Quarter.B < Near,
              Shape & ": and carries nothing of its neighbours");

      Assert (Middle.B > 255 - Near,
              Shape & ": the middle stop survives");
      Assert (Middle.R < Near and then Middle.G < Near,
              Shape & ": and carries nothing of its neighbours");

      Assert (Three_Quarter.G > 255 - Near,
              Shape & ": the stop three quarters along is its own colour");
      Assert (Three_Quarter.R < Near and then Three_Quarter.B < Near,
              Shape & ": and carries nothing of its neighbours");
   end Check_Stops;

   procedure Test_Square_Bar is
   begin
      Section ("a square bar");
      Check_Stops (Bar_Row (0.0), "square");
   end Test_Square_Bar;

   procedure Test_Rounded_Bar is
   begin
      Section ("a rounded bar");
      Check_Stops (Bar_Row (10.0), "rounded");
   end Test_Rounded_Bar;

   --  Between two stops the colour is a blend of exactly those two, so an
   --  eighth along is half red and half green and nothing else.
   procedure Test_Between_Stops is
      Row   : constant Sample_Row := Bar_Row (10.0);
      Eighth : constant Channels := At_Fraction (Row, 0.125);
   begin
      Section ("between two stops");
      Assert (Eighth.R > 90 and then Eighth.R < 165,
              "half of the stop behind");
      Assert (Eighth.G > 90 and then Eighth.G < 165,
              "half of the stop ahead");
      Assert (Eighth.B < Near,
              "and none of the one after that");
   end Test_Between_Stops;

   --  A diagonal gradient is the case least like a sweep along one
   --  axis: the bands cut the shape at an angle and each corner falls
   --  in a different one.
   Box_N : constant := 140;
   Box_X : constant := 10.0;
   Box_Y : constant := 10.0;
   Box_S : constant := 120.0;

   type Spot is record
      X, Y : Natural;
   end record;

   --  The centre, and the points a quarter of the way along the
   --  gradient to either side of it.
   Spots : constant array (1 .. 3) of Spot :=
     [(40, 100), (70, 70), (100, 40)];

   type Triple is array (1 .. 3) of Channels;

   function Diagonal_Box return Triple is
      Canvas : constant SDL_Surface_Ptr :=
        SDL_CreateSurface (int (Box_N), int (Box_N),
                           SDL_PIXELFORMAT_RGBA32);
      Renderer : SDL_Renderer_Ptr;
      Ctx      : Adi.Render.Render_Context;
      Box      : constant Box_Handle := Create_Handle;
      Unused   : Adi.SDL.C_bool;
      Result   : Triple := [others => <>];

      Style : constant Widget_Style :=
        From ((Background_Image =>
                 Set_Bg_Image (Linear_Gradient (45.0, Stops, 5)),
               Border_Radius    =>
                 Set (Adi.CSS_Styles.Radius (Px (20.0))),
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

      Unused := SDL_SetRenderDrawColor (Renderer, 0, 0, 0, 255);
      Unused := SDL_RenderClear (Renderer);

      Adi.Render.Create (Ctx, Renderer);

      Set_Part_Styles
        (Box, [Main_Part => (Style => Style, Enabled => True),
               others    => <>]);
      Set_Geometry (+Box, (X => Box_X, Y => Box_Y,
                           Width => Box_S, Height => Box_S));
      Build_Items (+Box);
      Render_Tree (+Box, Ctx);
      Unused := SDL_RenderPresent (Renderer);

      for I in Spots'Range loop
         declare
            PR, PG, PB, PA : aliased Uint8;
         begin
            if Boolean (SDL_ReadSurfacePixel
                          (Canvas, int (Spots (I).X), int (Spots (I).Y),
                           PR'Access, PG'Access, PB'Access, PA'Access))
            then
               Result (I) := (R => Natural (PR),
                              G => Natural (PG),
                              B => Natural (PB));
            end if;
         end;
      end loop;

      Adi.Render.Destroy (Ctx);
      SDL_DestroyRenderer (Renderer);
      SDL_DestroySurface (Canvas);
      return Result;
   end Diagonal_Box;

   procedure Test_Diagonal_Bar is
      Read : constant Triple := Diagonal_Box;
   begin
      Section ("a gradient across a corner");

      Assert (Read (1).G > 255 - Near
              and then Read (1).R < Near and then Read (1).B < Near,
              "the stop a quarter along holds its colour");
      Assert (Read (2).B > 255 - Near
              and then Read (2).R < Near and then Read (2).G < Near,
              "and so does the middle one");
      Assert (Read (3).G > 255 - Near
              and then Read (3).R < Near and then Read (3).B < Near,
              "and the one three quarters along");
   end Test_Diagonal_Bar;

   procedure Test_Stops_Past_The_End is
      Row : constant Sample_Row := Bar_Row (10.0, Far_Stops, 2);
      Along : constant array (1 .. 5) of Float := [0.1, 0.3, 0.5, 0.7, 0.9];
   begin
      Section ("stops beyond the shape");

      for T of Along loop
         declare
            Px_At : constant Channels := At_Fraction (Row, T);
         begin
            Assert (Px_At.R > 255 - Near
                    and then Px_At.G < Near and then Px_At.B < Near,
                    "the whole bar takes the first stop's colour");
         end;
      end loop;
   end Test_Stops_Past_The_End;

begin
   Start_Suite ("Gradient Stops Test");

   Test_Square_Bar;
   Test_Rounded_Bar;
   Test_Between_Stops;
   Test_Diagonal_Bar;
   Test_Stops_Past_The_End;

   Finish;
end Gradient_Stops_Test;
