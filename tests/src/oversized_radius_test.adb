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

--  A border-radius past half the box's shorter side paints exactly as
--  that half: the pill idiom `border-radius: 9999px`.

procedure Oversized_Radius_Test is

   Canvas_W : constant := 120;
   Canvas_H : constant := 80;

   --  An 80x40 box at (20, 20): half its height is 20px
   Box_X : constant := 20.0;
   Box_Y : constant := 20.0;
   Box_W : constant := 80.0;
   Box_H : constant := 40.0;
   Half  : constant := 20.0;

   type Pixel_RGBA is record
      R, G, B, A : Uint8;
   end record;

   type Image is array (0 .. Canvas_W - 1, 0 .. Canvas_H - 1) of Pixel_RGBA;

   Canvas   : SDL_Surface_Ptr;
   Renderer : SDL_Renderer_Ptr;

   --  Uniform: a 3px border all round, the one-ring path. Otherwise the
   --  bottom is 7px, the path that strokes each side and corner apart.
   function Render (Corner : Float; Uniform : Boolean) return Image is
      Ctx    : Adi.Render.Render_Context;
      Box    : constant Box_Handle := Create_Handle;
      Unused : Adi.SDL.C_bool;
      Widths : constant Border_Width_Value :=
        (if Uniform then Border_Width (Px (3.0))
         else Border_Width (Px (3.0), Px (3.0), Px (7.0), Px (3.0)));
      Style  : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (230, 230, 230)),
               Border_Width     => Set (Widths),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Color     => Set (Border_Color (RGB (180, 40, 40))),
               Border_Radius    => Set (Radius (Px (Corner))),
               others           => <>)).Build;
      Result : Image;
   begin
      Unused := SDL_SetRenderDrawColor (Renderer, 40, 40, 60, 255);
      Unused := SDL_RenderClear (Renderer);
      Adi.Render.Create (Ctx, Renderer);
      Set_Part_Styles
        (Box, [Main_Part => (Style => Style, Enabled => True),
               others    => <>]);
      Set_Geometry (+Box, (X => Box_X, Y => Box_Y,
                           Width => Box_W, Height => Box_H));
      Build_Items (+Box);
      Render_Tree (+Box, Ctx);
      Unused := SDL_RenderPresent (Renderer);
      Adi.Render.Destroy (Ctx);

      for X in 0 .. Canvas_W - 1 loop
         for Y in 0 .. Canvas_H - 1 loop
            declare
               PR, PG, PB, PA : aliased Uint8 := 0;
            begin
               Unused := SDL_ReadSurfacePixel
                 (Canvas, int (X), int (Y),
                  PR'Access, PG'Access, PB'Access, PA'Access);
               Result (X, Y) := (PR, PG, PB, PA);
            end;
         end loop;
      end loop;
      return Result;
   end Render;

   procedure Test (Uniform : Boolean; Name : String) is
      Pill : constant Image := Render (9999.0, Uniform);
      Exact : constant Image := Render (Half, Uniform);
   begin
      Section (Name);
      Assert (Pill = Exact,
              "9999px paints as half the shorter side");
   end Test;

begin
   Start_Suite ("Oversized Radius Test");

   Canvas := SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                                SDL_PIXELFORMAT_RGBA32);
   Assert (Canvas /= null, "SDL should provide a surface");
   if Canvas /= null then
      Renderer := SDL_CreateSoftwareRenderer (Canvas);
      Assert (Renderer /= null, "SDL should provide a software renderer");
      if Renderer /= null then
         Test (Uniform => True, Name => "Uniform border, one ring");
         Test (Uniform => False, Name => "Uneven border, sides apart");
         SDL_DestroyRenderer (Renderer);
      end if;
      SDL_DestroySurface (Canvas);
   end if;

   Finish;
end Oversized_Radius_Test;
