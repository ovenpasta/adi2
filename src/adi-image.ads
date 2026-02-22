with Adi.Core;       use Adi.Core;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SVG;
with Ada.Containers.Vectors;

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

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   -- Load an image from a file path.
   -- Raster images are loaded as SDL_Surface (no renderer required).
   -- SVG images are parsed into a document for later rasterization.
   -- Returns null on failure.
   function Load_From_File (Path : String) return Image_Access;

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

   -- Create an image from an existing SDL texture
   -- The Image takes ownership of the texture
   function Create_From_Texture
      (Texture : SDL_Texture_Ptr) return Image_Access;

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

   -- Get the underlying SDL texture (for rendering).
   -- For surface-based images, returns the first cached texture or null.
   -- Prefer Get_Texture with Renderer parameter for lazy creation.
   function Get_Texture (Img : Image) return SDL_Texture_Ptr;

   -- Get or lazily create a texture for the given renderer.
   -- For raster images with a surface, creates the texture on first call
   -- per renderer and caches it.  For direct-texture images, returns the
   -- stored texture.
   function Get_Texture
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr) return SDL_Texture_Ptr;

   -- Get a texture rendered for a specific size.
   -- For raster images this returns the base texture for the renderer.
   -- For SVG images this lazily rasterizes and caches per (renderer, size).
   function Get_Texture_For_Size
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr;
      Width    : Pixel_Type;
      Height   : Pixel_Type) return SDL_Texture_Ptr;

   ---------------------------------------------------------------------------
   -- Resource Management
   ---------------------------------------------------------------------------

   -- Destroy the image and free its surface, textures, and SVG data
   procedure Destroy (Img : in out Image);

   -- Remove and destroy all cached textures for a specific renderer.
   -- Call this before destroying a renderer to prevent stale texture handles.
   procedure Release_Textures_For_Renderer
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr);

   -- Evict all cached GPU textures for the given renderer from every
   -- live image (registered via constructors).  Call before destroying
   -- a renderer (e.g. in Window finalization) to prevent stale handles.
   procedure Release_All_Textures_For_Renderer
     (Renderer : SDL_Renderer_Ptr);

   -- Destroy image internals and deallocate the Image_Access object.
   -- Sets Img to null.  Safe to call with null.
   procedure Free (Img : in out Image_Access);

   -- Null/Empty image constant
   Null_Image : constant Image_Access := null;

private

   type Image_Kind is (Raster_Image, SVG_Image);

   type Cached_Texture is record
      Renderer  : SDL_Renderer_Ptr := null;
      Width_Px  : Positive;
      Height_Px : Positive;
      Texture   : SDL_Texture_Ptr := null;
   end record;

   package Cached_Texture_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cached_Texture);

   type Image is tagged record
      Kind     : Image_Kind := Raster_Image;
      Surface  : SDL_Surface_Ptr := null;
      Texture  : SDL_Texture_Ptr := null;
      Width    : Pixel_Type := 0.0;
      Height   : Pixel_Type := 0.0;
      SVG      : Adi.SVG.Document_Access := null;
      Cache    : Cached_Texture_Vectors.Vector;
      Tintable : Boolean := False;
   end record;

end Adi.Image;
