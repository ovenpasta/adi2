--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with System.Storage_Elements;
with Adi.Core;       use Adi.Core;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SVG;
with Adi.Render;
with Adi.Texture_Cache;

package Adi.Image is

   ---------------------------------------------------------------------------
   -- Image Resource Type
   --
   -- Encapsulates image data that can be loaded from files or memory.
   -- Raster images are loaded as SDL_Surface (CPU memory) and GPU textures
   -- are created lazily per renderer on first use.  SVG images store the
   -- parsed document and rasterize on demand.
   ---------------------------------------------------------------------------

   type Image is tagged private;
   type Image_Access is access all Image'Class;

   -- Texture scaling mode applied when the image is rendered at a size
   -- different from its native resolution.
   type Image_Scale_Mode is (
      Scale_Linear,    -- Bilinear filtering (smooth, default)
      Scale_Nearest,   -- Nearest-neighbor (sharp, no interpolation)
      Scale_Pixelart   -- Nearest-neighbor with integer snap (SDL 3.3+)
   );

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   -- Load an image from a file path.
   -- Raster images are loaded as SDL_Surface (no renderer required).
   -- SVG images are parsed into a document for later rasterization.
   -- Returns null on failure.
   function Load_From_File (Path : String) return Image_Access;

   -- Load a raster image from in-memory data.
   -- Data must point to a valid image file buffer (PNG, JPEG, etc.).
   -- The memory is fully consumed (copied into an SDL_Surface); the caller
   -- retains ownership of the buffer and may free it after this call.
   -- Returns null on failure.
   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count) return Image_Access;

   -- Load an SVG image from an SVG source string.
   -- Returns null on failure.
   -- When Tintable is True, the returned image is marked as tintable
   -- so that rendering applies CSS color as a tint via SDL color modulation.
   function Load_SVG_From_String
      (Source   : String;
       Tintable : Boolean := False) return Image_Access;

   -- Build and load an SVG from a single path command string.
   -- Returns null on failure.
   -- When Tintable is True, the returned image is marked as tintable.
   function Load_SVG_Path
      (Path_Data : String;
       Size      : Size_2D;
       Fill      : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Stroke_Width : Pixel_Type := 0.0;
       Stroke    : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Tintable  : Boolean := False) return Image_Access;

   -- Create an image from an existing SDL surface (CPU memory).
   -- The Image takes ownership of the surface; texture created lazily.
   function Create_From_Surface
      (Surface : SDL_Surface_Ptr) return Image_Access;

   -- Create an empty/null image
   function Create_Empty return Image_Access;

   ---------------------------------------------------------------------------
   -- Queries
   ---------------------------------------------------------------------------

   -- Check if the image has valid data (surface, texture, or SVG document)
   function Is_Valid (Img : Image) return Boolean;

   -- Check if the image was loaded as tintable (white-on-transparent).
   -- Tintable images are recolored by CSS color via SDL color modulation.
   function Is_Tintable (Img : Image) return Boolean;

   -- Get image dimensions
   procedure Get_Size
      (Img    : Image;
       Width  : out Pixel_Type;
       Height : out Pixel_Type);

   -- Get the underlying SDL surface (CPU memory).
   -- Returns null for SVG images.
   function Get_Surface (Img : Image) return SDL_Surface_Ptr;

   -- Mark the image as tintable (white-on-transparent, recolored by CSS
   -- color via SDL color modulation).
   procedure Set_Tintable (Img : in out Image; Value : Boolean := True);

   -- Get the texture scaling mode for this image.
   function Get_Scale_Mode (Img : Image) return Image_Scale_Mode;

   -- Set the texture scaling mode. The mode identifies a texture rather
   -- than being applied to one, so a lease taken after this finds or
   -- builds a texture made for it; textures built for the old mode stay
   -- cached under their own key until the budget reclaims them.
   procedure Set_Scale_Mode
     (Img  : in out Image;
      Mode : Image_Scale_Mode);

   -- Take out a lease on a texture for this image at the requested size,
   -- rasterizing or uploading one if none is held yet.
   --
   -- The texture is reachable only through the returned reference and only
   -- for as long as it lives. Read it inside the draw and let it go: an
   -- image's textures are evictable, and a pointer kept past the lease
   -- would outlive what it names. Hold one lease per draw, not per frame.
   --
   -- A null texture in the reference means none could be produced -- an
   -- unrasterizable SVG, a null renderer, an upload that failed. Callers
   -- check the reference rather than the return of a getter.
   --
   -- A lease pins: the entry it names cannot be evicted while it lives,
   -- and an eviction decided during the draw takes effect once it ends.
   --
   -- It outlives the image with its texture intact, since the texture
   -- belongs to the renderer's cache rather than to the image. It may
   -- outlive the context too, but not intact: a context goes because its
   -- renderer is going, so the texture goes with it and the lease is left
   -- readable with a null texture. Keeping a lease no longer than the
   -- draw it belongs to avoids the question.
   --
   -- Raster images ignore the size and yield their uploaded surface; only
   -- SVG rasterizes per size. Residency is the renderer's byte budget, not
   -- a per-image count, so a widget tracking a window resize competes for
   -- room against everything else being drawn rather than against seven
   -- other rasters of itself.
   function Acquire_Texture
     (Img    : in out Image'Class;
      Ctx    : in out Adi.Render.Render_Context;
      Width  : Pixel_Type;
      Height : Pixel_Type) return Adi.Texture_Cache.Texture_Ref;

   ---------------------------------------------------------------------------
   -- Resource Management
   ---------------------------------------------------------------------------

   -- Free the image's surface and SVG data. Textures it has been leased
   -- are not touched: they belong to the cache of whichever context built
   -- them, and stay resident until budget pressure or that context's
   -- destruction reclaims them.
   procedure Destroy (Img : in out Image);

   -- Destroy image internals and deallocate the Image_Access object.
   -- Sets Img to null.  Safe to call with null.
   procedure Free (Img : in out Image_Access);

   -- Null/Empty image constant
   Null_Image : constant Image_Access := null;

private

   type Image_Kind is (Raster_Image, SVG_Image);

   type Image is tagged record
      Kind     : Image_Kind := Raster_Image;
      Surface  : SDL_Surface_Ptr := null;
      Width    : Pixel_Type := 0.0;
      Height   : Pixel_Type := 0.0;
      SVG      : Adi.SVG.Document_Access := null;
      --  Identifies this image's textures in whatever cache holds them,
      --  so two images cannot collide and one image's entries are found
      --  again across renderers.
      Source   : Adi.Texture_Cache.Source_Id := 0;
      Tintable : Boolean := False;
      Scaling  : Image_Scale_Mode := Scale_Linear;
   end record;

end Adi.Image;
