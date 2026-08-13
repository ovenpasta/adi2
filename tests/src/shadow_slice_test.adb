pragma Ada_2022;

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with System;
with Adi.SDL;             use Adi.SDL;
with Adi.SDL.Render;      use Adi.SDL.Render;
with Adi.SDL.Surface;     use Adi.SDL.Surface;
with Adi.SDL.PixelFormat; use Adi.SDL.PixelFormat;
with Adi.Shadow;
with Interfaces.C;        use Interfaces.C;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with Test_Support;        use Test_Support;

--  Renders shadows through SDL's real nine-grid into a software surface and
--  reads the result back. The mask pins in shadow_test say the texture is
--  right; these say the corrected centre survives slicing, and that a short
--  widget keeps a taller one's sideways blur reach -- which is what a plain
--  stretched blit would break, since it would scale the blur per axis.
--
--  Not covered here: the dark seam a fractional slice border produces by
--  drawing the shared line from both quads. SDL's software renderer does
--  not reproduce it, so an assertion on it would pass either way and read
--  as coverage it does not provide. Slice_Border is pinned arithmetically
--  below instead.

procedure Shadow_Slice_Test is

   Canvas_W : constant := 420;
   Canvas_H : constant := 300;

   subtype Row is Natural range 0 .. Canvas_H - 1;
   subtype Col is Natural range 0 .. Canvas_W - 1;

   --  Half a megabyte each, so they live on the heap rather than being
   --  copied out of every call.
   type Grey_Plane is array (Row, Col) of Natural;
   type Grey_Plane_Ptr is access Grey_Plane;
   procedure Free is new Ada.Unchecked_Deallocation
     (Grey_Plane, Grey_Plane_Ptr);

   --  Draw one shadow onto a white canvas and return its darkness per pixel,
   --  0 for untouched white and 255 for fully black.
   function Render_Shadow
     (Blur, Radius : Natural;
      X, Y, W, H   : Float) return Grey_Plane_Ptr
   is
      Geom : constant Adi.Shadow.Geometry :=
        Adi.Shadow.Geometry_For (Blur, Radius);
      Mask : constant Adi.Shadow.Coverage :=
        Adi.Shadow.Build_Mask (Blur, Radius);
      Size : constant Natural := Geom.Tex_Size;

      Canvas   : constant access SDL_Surface :=
        SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                           SDL_PIXELFORMAT_RGBA32);
      Tex_Surf : constant access SDL_Surface :=
        SDL_CreateSurface (int (Size), int (Size), SDL_PIXELFORMAT_RGBA32);

      Renderer : SDL_Renderer_Ptr;
      Texture  : SDL_Texture_Ptr;
      Unused   : Adi.SDL.C_bool;
      Result   : constant Grey_Plane_Ptr :=
        new Grey_Plane'[others => [others => 0]];

      Dst : aliased SDL_FRect := (x => X, y => Y, w => W, h => H);
   begin
      if Canvas = null or else Tex_Surf = null then
         Assert (False, "SDL should provide surfaces for the slice test");
         return Result;
      end if;

      --  White, opaque shadow texture whose alpha is the mask.
      declare
         Pitch : constant Natural := Natural (Tex_Surf.pitch) / 4;
         --  Constrained, so the access is a thin pointer that may be
         --  overlaid on the surface's own memory.
         subtype Texel_Index is Natural range 0 .. Pitch * Size - 1;
         type Texel_Buffer is array (Texel_Index) of aliased Uint32
           with Convention => C;
         type Texel_Buffer_Ptr is access all Texel_Buffer;
         function To_Texels is new Ada.Unchecked_Conversion
           (System.Address, Texel_Buffer_Ptr);
         Pixels : constant Texel_Buffer_Ptr := To_Texels (Tex_Surf.pixels);
      begin
         for Ty in 0 .. Size - 1 loop
            for Tx in 0 .. Size - 1 loop
               declare
                  A : constant Uint32 :=
                    Uint32 (Float'Min (1.0, Float'Max (0.0,
                      Mask (Ty * Size + Tx))) * 255.0);
               begin
                  Pixels (Ty * Pitch + Tx) :=
                    16#00FF_FFFF# + A * 16777216;
               end;
            end loop;
         end loop;
      end;

      Renderer := SDL_CreateSoftwareRenderer (Canvas);
      if Renderer = null then
         Assert (False, "SDL should provide a software renderer");
         return Result;
      end if;

      Unused := SDL_SetRenderDrawColor (Renderer, 255, 255, 255, 255);
      Unused := SDL_RenderClear (Renderer);

      Texture := SDL_CreateTextureFromSurface (Renderer, Tex_Surf);
      Unused := SDL_SetTextureBlendMode (Texture, SDL_BLENDMODE_BLEND);
      Unused := SDL_SetTextureColorMod (Texture, 0, 0, 0);
      Unused := SDL_SetTextureAlphaMod (Texture, 255);

      Unused := SDL_RenderTexture9Grid
        (Renderer      => Renderer,
         Texture       => Texture,
         Srcrect       => null,
         Left_Width    => Adi.Shadow.Slice_Border (Geom, Dst.w),
         Right_Width   => Adi.Shadow.Slice_Border (Geom, Dst.w),
         Top_Height    => Adi.Shadow.Slice_Border (Geom, Dst.h),
         Bottom_Height => Adi.Shadow.Slice_Border (Geom, Dst.h),
         Scale         => 1.0,
         Dstrect       => Dst'Access);
      Unused := SDL_RenderPresent (Renderer);

      declare
         Pitch : constant Natural := Natural (Canvas.pitch) / 4;
         subtype Canvas_Index is Natural range 0 .. Pitch * Canvas_H - 1;
         type Canvas_Buffer is array (Canvas_Index) of aliased Uint32
           with Convention => C;
         type Canvas_Buffer_Ptr is access all Canvas_Buffer;
         function To_Canvas is new Ada.Unchecked_Conversion
           (System.Address, Canvas_Buffer_Ptr);
         Pixels : constant Canvas_Buffer_Ptr := To_Canvas (Canvas.pixels);
      begin
         for Cy in Row loop
            for Cx in Col loop
               Result (Cy, Cx) :=
                 255 - Natural (Pixels (Cy * Pitch + Cx) rem 256);
            end loop;
         end loop;
      end;

      SDL_DestroyTexture (Texture);
      SDL_DestroyRenderer (Renderer);
      SDL_DestroySurface (Tex_Surf);
      SDL_DestroySurface (Canvas);
      return Result;
   end Render_Shadow;

   --  How far the blur reaches sideways from the shadow's edge: the count of
   --  columns between fully clear and fully dark along a row.
   function Horizontal_Reach (G : Grey_Plane; Cy : Row) return Natural is
      Count : Natural := 0;
   begin
      for Cx in Col loop
         if G (Cy, Cx) > 4 and then G (Cy, Cx) < 251 then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Horizontal_Reach;

begin
   Start_Suite ("Shadow slice test");

   --  The corrected centre survives slicing, not just mask generation.
   declare
      G : Grey_Plane_Ptr := Render_Shadow (8, 8, 20.0, 20.0, 370.0, 220.0);
   begin
      Assert (G (130, 200) >= 254,
              "Blur 8 should stay opaque at the centre once sliced");
      Free (G);
   end;

   --  Corners keep their size, so the blur reaches the same distance
   --  sideways whether the widget is short or tall. This is what a plain
   --  stretched blit would break.
   declare
      Short_G : Grey_Plane_Ptr := Render_Shadow (8, 8, 20.0, 20.0, 370.0, 87.0);
      Tall_G  : Grey_Plane_Ptr := Render_Shadow (8, 8, 20.0, 20.0, 370.0, 220.0);
      Short_Reach : constant Natural := Horizontal_Reach (Short_G.all, 63);
      Tall_Reach  : constant Natural := Horizontal_Reach (Tall_G.all, 130);
   begin
      Assert (Short_Reach > 0, "Blur should reach sideways at all");
      Assert (Short_Reach = Tall_Reach,
              "Short widget should keep the taller one's horizontal blur"
              & " reach:" & Natural'Image (Short_Reach) & " vs"
              & Natural'Image (Tall_Reach));
      Free (Short_G);
      Free (Tall_G);
   end;

   --  The case that produced the seam: 87 pixels of room, a 48-pixel
   --  border on offer, and 43 taken so the two sides leave a pixel between
   --  them instead of meeting on one.
   declare
      Geom : constant Adi.Shadow.Geometry := Adi.Shadow.Geometry_For (8, 8);
   begin
      Assert (Geom.Grid_Border = 48, "Blur 8 radius 8 should slice at 48");
      Assert (Adi.Shadow.Slice_Border (Geom, 87.0) = 43.0,
              "87 pixels of room should yield a 43-pixel border");
      Assert (Adi.Shadow.Slice_Border (Geom, 220.0) = 48.0,
              "Room enough should yield the full border");
   end;

   --  The border never grows past the room available, whatever is asked.
   for Extent in 1 .. 240 loop
      declare
         Geom : constant Adi.Shadow.Geometry :=
           Adi.Shadow.Geometry_For (8, 8);
         B    : constant Float :=
           Adi.Shadow.Slice_Border (Geom, Float (Extent));
      begin
         Assert (2.0 * B < Float (Extent),
                 "Two borders must leave a middle at extent"
                 & Natural'Image (Extent));
         Assert (B = Float'Floor (B), "Border should be whole pixels");
      end;
   end loop;

   Finish;
end Shadow_Slice_Test;
