--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with System.Storage_Elements;
with Adi.Core;       use Adi.Core;
with Adi.Owned_Handle_Store;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SVG;
with Adi.Render;
with Adi.Texture_Cache;

package Adi.Image is

   ---------------------------------------------------------------------------
   -- Image Resource
   --
   -- Image data loaded from files or memory. Raster images are loaded as
   -- SDL_Surface (CPU memory) and GPU textures are created lazily per
   -- renderer on first use. SVG images store the parsed document and
   -- rasterize on demand.
   --
   -- An image is reached only through a handle. Whoever created it owns
   -- it -- the application, the asset cache, an animation -- and everyone
   -- else views it. The last owner releasing it stales every copy of the
   -- handle at once, so a viewer that outlives the owner reads a stale
   -- handle rather than a freed image, and every operation here answers
   -- a stale handle with the same default it gives a null one.
   ---------------------------------------------------------------------------

   --  A view. Copy it freely: it names an image without keeping it, and
   --  goes stale the moment the last owner lets go.
   --  Render-thread confined. The owner counts and the store's slots are
   --  plain variables with nothing guarding them, and loading and
   --  reclaiming reach SDL and the SVG backend, so constructing,
   --  releasing and drawing all happen on one thread. That includes the
   --  release an owner performs on its way out of scope.
   --
   --  Releasing does not reach the renderers: an image's textures belong
   --  to the cache that built them and stay until budget pressure or the
   --  context's destruction takes them. What clears them early is an
   --  owner releasing the texture group they were made under, which is
   --  the animations' business rather than this package's.
   type Image_Handle is private;
   Null_Image_Handle : constant Image_Handle;

   --  The right to end an image, and the thing that keeps it. Whoever
   --  loads an image gets one, and must outlive the widgets drawing it.
   --  Copying an owner shares the right; the last one to go ends the
   --  image and stales every view of it.
   type Image_Owner is private;

   --  An owner of nothing: what a failed load yields, and what a holder
   --  starts out with.
   Null_Image_Owner : constant Image_Owner;

   -- Texture scaling mode applied when the image is rendered at a size
   -- different from its native resolution.
   type Image_Scale_Mode is (
      Scale_Linear,    -- Bilinear filtering (smooth, default)
      Scale_Nearest,   -- Nearest-neighbor (sharp, no interpolation)
      Scale_Pixelart   -- Nearest-neighbor with integer snap (SDL 3.3+)
   );

   ---------------------------------------------------------------------------
   -- Constructors
   --
   -- Each returns an owner. A failed load yields one that owns nothing,
   -- which Is_Owned reports.
   ---------------------------------------------------------------------------

   -- Load an image from a file path.
   -- Raster images are loaded as SDL_Surface (no renderer required).
   -- SVG images are parsed into a document for later rasterization.
   function Load_From_File (Path : String) return Image_Owner;

   -- Load a raster image from in-memory data.
   -- Data must point to a valid image file buffer (PNG, JPEG, etc.).
   -- The memory is fully consumed (copied into an SDL_Surface); the caller
   -- retains ownership of the buffer and may free it after this call.
   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count) return Image_Owner;

   -- Load an SVG image from an SVG source string.
   -- When Tintable is True, the returned image is marked as tintable
   -- so that rendering applies CSS color as a tint via SDL color modulation.
   function Load_SVG_From_String
      (Source   : String;
       Tintable : Boolean := False) return Image_Owner;

   -- Build and load an SVG from a single path command string.
   -- When Tintable is True, the returned image is marked as tintable.
   function Load_SVG_Path
      (Path_Data : String;
       Size      : Size_2D;
       Fill      : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Stroke_Width : Pixel_Type := 0.0;
       Stroke    : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Tintable  : Boolean := False) return Image_Owner;

   -- Create an image from an existing SDL surface (CPU memory).
   -- The image adopts the surface only once it owns one: on a null
   -- surface, on a failure, and if this propagates, the surface is still
   -- the caller's and theirs alone to destroy.
   --
   -- Group names a lifetime this image's textures share with others --
   -- an animation's frames, which stop being wanted together. The image
   -- does not own it: the group belongs to whatever produced the frames,
   -- and must outlive every image that names it.
   function Create_From_Surface
      (Surface : SDL_Surface_Ptr;
       Group   : Adi.Texture_Cache.Texture_Group_Access := null)
       return Image_Owner;

   -- Create an empty image: a live handle holding no picture.
   function Create_Empty return Image_Owner;

   ---------------------------------------------------------------------------
   -- Queries
   --
   -- A null or stale handle is not an error to any of these. Each answers
   -- with the same default it would give an image holding nothing.
   ---------------------------------------------------------------------------

   -- True when the handle names a live image that has something to
   -- draw from: a surface, or an SVG document. Textures are made from
   -- those on demand and do not enter into it.
   function Is_Valid (H : Image_Handle) return Boolean;

   -- True when the image was loaded as tintable (white-on-transparent).
   -- Tintable images are recolored by CSS color via SDL color modulation.
   function Is_Tintable (H : Image_Handle) return Boolean;

   -- Image dimensions. Both are 0.0 for a handle that names nothing.
   procedure Get_Size
      (H      : Image_Handle;
       Width  : out Pixel_Type;
       Height : out Pixel_Type);

   -- The underlying SDL surface (CPU memory).
   -- Returns null for SVG images and for a handle naming nothing.
   --
   -- Borrowed, and only for as long as the image lives: it belongs to
   -- the image, the last release destroys it, and a pointer kept past
   -- that names freed storage. Read it and let it go.
   function Get_Surface (H : Image_Handle) return SDL_Surface_Ptr;

   -- Mark the image as tintable (white-on-transparent, recolored by CSS
   -- color via SDL color modulation).
   procedure Set_Tintable (H : Image_Handle; Value : Boolean := True);

   -- The texture scaling mode for this image.
   function Get_Scale_Mode (H : Image_Handle) return Image_Scale_Mode;

   -- Set the texture scaling mode. The mode identifies a texture rather
   -- than being applied to one, so a lease taken after this finds or
   -- builds a texture made for it; textures built for the old mode stay
   -- cached under their own key until the budget reclaims them.
   procedure Set_Scale_Mode
     (H    : Image_Handle;
      Mode : Image_Scale_Mode);

   -- Take out a lease on a texture for this image at the requested size,
   -- rasterizing or uploading one if none is held yet.
   --
   -- The texture is reachable only through the returned reference and only
   -- for as long as it lives. Read it inside the draw and let it go: an
   -- image's textures are evictable, and a pointer kept past the lease
   -- would outlive what it names. Hold one lease per draw, not per frame.
   --
   -- A null texture in the reference means none could be produced -- a
   -- handle naming nothing, an unrasterizable SVG, a null renderer, an
   -- upload that failed. Callers check the reference rather than the
   -- return of a getter.
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
     (H      : Image_Handle;
      Ctx    : in out Adi.Render.Render_Context;
      Width  : Pixel_Type;
      Height : Pixel_Type) return Adi.Texture_Cache.Texture_Ref;

   ---------------------------------------------------------------------------
   -- Ownership
   ---------------------------------------------------------------------------

   -- A view of the owned image, for handing to whatever draws it.
   function To_Handle (O : Image_Owner) return Image_Handle;

   -- Whether this owner holds an image. False after a failed load, and
   -- after Release.
   function Is_Owned (O : Image_Owner) return Boolean;

   -- Give up this owner's share. The last one out frees the image's
   -- surface and SVG data and retires its slot, so every view of it goes
   -- stale in that moment -- which is what lets an owner end an image
   -- while widgets still hold handles to it.
   --
   -- Textures the image has been leased are not touched: they belong to
   -- the cache of whichever context built them, and stay resident until
   -- budget pressure or that context's destruction reclaims them.
   --
   -- An owner also releases when it goes out of scope. One held in a
   -- container is released before it is removed: when a container
   -- finalises what it drops is unspecified.
   procedure Release (O : in out Image_Owner);

private

   type Image_Kind is (Raster_Image, SVG_Image);

   --  Limited: the surface, the SVG document, the identity its textures
   --  are cached under and the group it draws its lifetime from all name
   --  one allocation, and none of them survive being copied.
   type Image is tagged limited record
      Kind     : Image_Kind := Raster_Image;
      Surface  : SDL_Surface_Ptr := null;
      Width    : Pixel_Type := 0.0;
      Height   : Pixel_Type := 0.0;
      SVG      : Adi.SVG.Document_Access := null;
      --  Identifies this image's textures in whatever cache holds them,
      --  so two images cannot collide and one image's entries are found
      --  again across renderers.
      Source   : Adi.Texture_Cache.Source_Id := 0;
      --  Not owned: whatever produced this image owns the group, and
      --  outlives it.
      Group    : Adi.Texture_Cache.Texture_Group_Access := null;
      Tintable : Boolean := False;
      Scaling  : Image_Scale_Mode := Scale_Linear;
   end record;

   type Image_Access is access all Image'Class;

   --  Empties the image; the store reclaims the record itself.
   procedure Reclaim_Image (Img : in out Image'Class);

   package Image_Stores is new Adi.Owned_Handle_Store
     (Image, Image_Access, Reclaim_Image);

   type Image_Handle is record
      Ref : Image_Stores.Handle := Image_Stores.Null_Handle;
   end record;

   --  A record rather than a derivation, so the visible type stays
   --  untagged. The controlled component adjusts and finalises with it,
   --  so an owner inside a record or a container is counted like any
   --  other.
   type Image_Owner is record
      Ref : Image_Stores.Owner;
   end record;

   Null_Image_Owner : constant Image_Owner := (Ref => <>);

   Null_Image_Handle : constant Image_Handle :=
     (Ref => Image_Stores.Null_Handle);

end Adi.Image;
