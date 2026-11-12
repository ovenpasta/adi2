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

--  A rounded border whose sides differ in width, or that leaves a side
--  undrawn: antialiased curves, each side in its colour, and a side
--  without width or style giving its corners to its neighbours.

procedure Rounded_Uneven_Border_Test is

   Canvas_W : constant := 120;
   Canvas_H : constant := 80;

   --  Every case paints an 80x40 box at (20, 20)
   Box_X : constant := 20;
   Box_Y : constant := 20;
   Box_W : constant := 80;
   Box_H : constant := 40;

   type RGB_Pixel is record
      R, G, B : Natural;
   end record;

   Backdrop : constant RGB_Pixel := (40, 40, 60);
   Fill     : constant RGB_Pixel := (230, 230, 230);

   Top_C    : constant RGB_Pixel := (220, 30, 30);
   Right_C  : constant RGB_Pixel := (30, 200, 30);
   Bottom_C : constant RGB_Pixel := (30, 30, 220);
   Left_C   : constant RGB_Pixel := (220, 200, 30);

   Canvas   : SDL_Surface_Ptr;
   Renderer : SDL_Renderer_Ptr;

   function To_CSS (P : RGB_Pixel) return Color_Value is
     (RGB (P.R, P.G, P.B));

   Four_Colours : constant Border_Color_Value :=
     Border_Color (Top    => To_CSS (Top_C),
                   Right  => To_CSS (Right_C),
                   Bottom => To_CSS (Bottom_C),
                   Left   => To_CSS (Left_C));

   procedure Render_Box
     (Widths : Border_Width_Value;
      Styles : Border_Style_Value;
      Colors : Border_Color_Value;
      Corner   : Float;
      Filled   : Boolean := True;
      Gradient : Boolean := False)
   is
      --  Light top to bottom, in the fill's green range, so a rim of it
      --  outside the border reads as the fill's does
      Light : constant Gradient_Stop_Array :=
        [1      => Gradient_Stop_Auto (RGB (230, 230, 230)),
         2      => Gradient_Stop_Auto (RGB (200, 200, 200)),
         others => <>];
      Ctx    : Adi.Render.Render_Context;
      Box    : constant Box_Handle := Create_Handle;
      Unused : Adi.SDL.C_bool;
      Style  : constant Widget_Style :=
        From ((Background_Color =>
                 (if Filled then Set_Bg (To_CSS (Fill)) else Opt_Bg_Color.Unset),
               Border_Width     => Set (Widths),
               Border_Style     => Set (Styles),
               Border_Color     => Set (Colors),
               Border_Radius    => Set (Radius (Px (Corner))),
               Background_Image =>
                 (if Gradient
                  then Set_Bg_Image (Linear_Gradient (180.0, Light, 2))
                  else Opt_Bg_Image.Unset),
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
      Set_Geometry (+Box, (X      => Pixel_Type (Box_X),
                           Y      => Pixel_Type (Box_Y),
                           Width  => Pixel_Type (Box_W),
                           Height => Pixel_Type (Box_H)));
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

   function Near (P, Want : RGB_Pixel; Tolerance : Natural := 24)
     return Boolean
   is (abs (P.R - Want.R) <= Tolerance
       and then abs (P.G - Want.G) <= Tolerance
       and then abs (P.B - Want.B) <= Tolerance);

   Border : constant RGB_Pixel := (180, 40, 40);

   procedure Render_Uneven (Filled : Boolean; Gradient : Boolean := False) is
   begin
      Render_Box (Border_Width (Px (3.0), Px (3.0), Px (7.0), Px (3.0)),
                  Border_Style (Solid), Border_Color (To_CSS (Border)),
                  Corner => 20.0, Filled => Filled, Gradient => Gradient);
   end Render_Uneven;

   --  Unfilled, a hard-edged border leaves only backdrop and border
   --  colour; an antialiased one blends them along both its edges.
   procedure Test_Antialiased_Curve is
      Blends : Natural := 0;
   begin
      Section ("Sides of differing width: the curves are antialiased");
      Render_Uneven (Filled => False);
      for X in 18 .. 40 loop
         for Y in 18 .. 40 loop
            if not Near (Pixel (X, Y), Backdrop, 6)
              and then not Near (Pixel (X, Y), Border, 6)
            then
               Blends := Blends + 1;
            end if;
         end loop;
      end loop;
      Assert (Blends >= 20,
              "the top-left corner blends border into backdrop ("
              & Blends'Image & " pixels )");
   end Test_Antialiased_Curve;

   --  Pixels left of the solid border, on the rows of the left curves,
   --  that lean toward the light background: a rim of it outside the border
   function Rim_Pixels return Natural is
      Rim : Natural := 0;
   begin
      for Y in 20 .. 59 loop
         for X in 0 .. 40 loop
            exit when Near (Pixel (X, Y), Border, 24);
            if Pixel (X, Y).G > 70 then
               Rim := Rim + 1;
            end if;
         end loop;
      end loop;
      return Rim;
   end Rim_Pixels;

   --  The same from the right, on the rows of the right curves
   function Rim_Pixels_Right return Natural is
      Rim : Natural := 0;
   begin
      for Y in 20 .. 59 loop
         for X in reverse 80 .. Canvas_W - 1 loop
            exit when Near (Pixel (X, Y), Border, 24);
            if Pixel (X, Y).G > 70 then
               Rim := Rim + 1;
            end if;
         end loop;
      end loop;
      return Rim;
   end Rim_Pixels_Right;

   procedure Test_No_Fill_Rim is
   begin
      Section ("The background shows no rim outside the border");
      Render_Uneven (Filled => True);
      Assert (Rim_Pixels = 0, "no rim of background colour");
      Render_Uneven (Filled => False, Gradient => True);
      Assert (Rim_Pixels = 0, "no rim of gradient");

      --  The left side undrawn: the gradient keeps its own fringe there,
      --  and still none under the border on the right
      Render_Box (Border_Width (Px (3.0), Px (3.0), Px (7.0), Px (3.0)),
                  Border_Style (Solid, Solid, Solid, None_Style),
                  Border_Color (To_CSS (Border)),
                  Corner => 20.0, Filled => False, Gradient => True);
      Assert (Rim_Pixels_Right = 0,
              "no rim of gradient beside a side left undrawn");
   end Test_No_Fill_Rim;

   --  Radius 8 and a 10px left side: the inner top-left corner is sharp,
   --  at (30, 22), its curve flattened into the left side. The inner
   --  fringe still runs the whole of both inner edges and round the turn.
   procedure Test_Sharp_Inner_Corner is
      function Blend (P : RGB_Pixel) return Boolean is
        (P.R > Backdrop.R + 30 and then P.R < Border.R - 30);
   begin
      Section ("A sharp inner corner keeps its inner fringe");
      Render_Box (Border_Width (Px (2.0), Px (2.0), Px (2.0), Px (10.0)),
                  Border_Style (Solid), Border_Color (To_CSS (Border)),
                  Corner => 8.0, Filled => False);
      Assert (Blend (Pixel (40, 22)), "the inner top edge is antialiased");
      Assert (Blend (Pixel (32, 22)), "up to the corner");
      Assert (Blend (Pixel (30, 30)), "the inner left edge is antialiased");
      Assert (not Near (Pixel (30, 22), Backdrop, 6),
              "the corner pixel is covered");
   end Test_Sharp_Inner_Corner;

   --  Right border 70px on an 80px box: the inner corners have 5px of
   --  width left between them, and nothing is drawn past the box
   procedure Test_Border_Wider_Than_Box is
      Outside : Natural := 0;
   begin
      Section ("A side's border wider than the box stays inside it");
      Render_Box (Border_Width (Px (2.0), Px (70.0), Px (2.0), Px (3.0)),
                  Border_Style (Solid), Four_Colours, Corner => 20.0);
      for X in 0 .. Canvas_W - 1 loop
         for Y in 0 .. Canvas_H - 1 loop
            if (X <= Box_X - 2 or else X >= Box_X + Box_W + 1
                or else Y <= Box_Y - 2 or else Y >= Box_Y + Box_H + 1)
              and then not Near (Pixel (X, Y), Backdrop, 0)
            then
               Outside := Outside + 1;
            end if;
         end loop;
      end loop;
      Assert (Outside = 0,
              "nothing drawn past the box (" & Outside'Image & " pixels )");
      Assert (Near (Pixel (80, 40), Right_C), "the wide right side is drawn");
      Assert (Near (Pixel (60, 21), Top_C), "the top is drawn");

      --  Half transparent and unfilled: covered once, the border is one
      --  even blend over the backdrop, also beside the narrow inner rect
      --  (x 23 .. 29) where its inner corners have least room
      Render_Box (Border_Width (Px (2.0), Px (70.0), Px (2.0), Px (3.0)),
                  Border_Style (Solid),
                  Border_Color (RGBA (180, 40, 40, 0.5)),
                  Corner => 20.0, Filled => False);
      declare
         Once  : constant RGB_Pixel := (110, 40, 50);
         Uneven : Natural := 0;
      begin
         for X in 31 .. 39 loop
            for Y in 23 .. 35 loop
               if not Near (Pixel (X, Y), Once, 8) then
                  Uneven := Uneven + 1;
               end if;
            end loop;
         end loop;
         Assert (Uneven = 0,
                 "a translucent border is painted once ("
                 & Uneven'Image & " pixels off )");
      end;
   end Test_Border_Wider_Than_Box;

   procedure Test_Side_Styled_None is
   begin
      Section ("A side styled none on a uniform rounded border");
      Render_Box (Border_Width (Px (4.0)),
                  Border_Style (Solid, Solid, None_Style, Solid),
                  Four_Colours, Corner => 12.0);
      Assert (Near (Pixel (60, 58), Fill),
              "the bottom shows the fill, not its border colour");
      Assert (Near (Pixel (60, 21), Top_C), "the top keeps its colour");
      Assert (Near (Pixel (98, 40), Right_C), "the right keeps its colour");
      Assert (Near (Pixel (21, 40), Left_C), "the left keeps its colour");
   end Test_Side_Styled_None;

   procedure Test_Zero_Width_Side is
      Reddish : Boolean := False;
   begin
      Section ("A side without width gives its corners to its neighbours");
      Render_Box (Border_Width (Px (0.0), Px (0.0), Px (0.0), Px (6.0)),
                  Border_Style (Solid), Four_Colours, Corner => 12.0);
      --  The top-left corner, centred at (32, 32): its arc belongs to the
      --  left side, so no top colour anywhere in it
      for X in 20 .. 31 loop
         for Y in 20 .. 31 loop
            if Pixel (X, Y).R > 150 and then Pixel (X, Y).G < 100 then
               Reddish := True;
            end if;
         end loop;
      end loop;
      Assert (not Reddish, "the top's colour is nowhere in the corner");
      Assert (Near (Pixel (23, 30), Left_C),
              "the corner is drawn in the left's colour");
      Assert (Near (Pixel (22, 40), Left_C), "the left side is drawn");
   end Test_Zero_Width_Side;

   procedure Test_Edge_Colours is
   begin
      Section ("Sides of differing width keep their own colours");
      Render_Box (Border_Width (Px (2.0), Px (4.0), Px (8.0), Px (6.0)),
                  Border_Style (Solid), Four_Colours, Corner => 12.0);
      Assert (Near (Pixel (60, 20), Top_C), "top in its colour");
      Assert (Near (Pixel (97, 40), Right_C), "right in its colour");
      Assert (Near (Pixel (60, 56), Bottom_C), "bottom in its colour");
      Assert (Near (Pixel (22, 40), Left_C), "left in its colour");
   end Test_Edge_Colours;

begin
   Start_Suite ("Rounded Uneven Border Test");

   Canvas := SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                                SDL_PIXELFORMAT_RGBA32);
   Assert (Canvas /= null, "SDL should provide a surface");
   if Canvas /= null then
      Renderer := SDL_CreateSoftwareRenderer (Canvas);
      Assert (Renderer /= null, "SDL should provide a software renderer");
      if Renderer /= null then
         Test_Antialiased_Curve;
         Test_No_Fill_Rim;
         Test_Border_Wider_Than_Box;
         Test_Sharp_Inner_Corner;
         Test_Side_Styled_None;
         Test_Zero_Width_Side;
         Test_Edge_Colours;
         SDL_DestroyRenderer (Renderer);
      end if;
      SDL_DestroySurface (Canvas);
   end if;

   Finish;
end Rounded_Uneven_Border_Test;
