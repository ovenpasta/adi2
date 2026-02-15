with Adi.Core;       use Adi.Core;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SVG;
with Ada.Containers.Vectors;

package Adi.Image is

   ---------------------------------------------------------------------------
   -- Image Resource Type
   --
   -- Encapsulates an SDL texture that can be loaded from files or memory
   -- and used with widgets for rendering.
   ---------------------------------------------------------------------------

   type Image is tagged private;
   type Image_Access is access all Image'Class;

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   -- Load an image from a file path
   -- Returns null on failure
   function Load_From_File
      (Renderer : SDL_Renderer_Ptr;
       Path     : String) return Image_Access;

   -- Load an SVG image from an SVG source string.
   -- Returns null on failure
   function Load_SVG_From_String
      (Renderer : SDL_Renderer_Ptr;
       Source   : String) return Image_Access;

   -- Build and load an SVG from a single path command string.
   -- Returns null on failure
   function Load_SVG_Path
      (Renderer  : SDL_Renderer_Ptr;
       Path_Data : String;
       Size      : Size_2D;
       Fill      : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Stroke_Width : Pixel_Type := 0.0;
       Stroke    : Color_8 := (R => 0, G => 0, B => 0, A => 255)) return Image_Access;

   -- Create an image from an existing SDL texture
   -- The Image takes ownership of the texture
   function Create_From_Texture
      (Texture : SDL_Texture_Ptr) return Image_Access;

   -- Create an empty/null image
   function Create_Empty return Image_Access;

   ---------------------------------------------------------------------------
   -- Queries
   ---------------------------------------------------------------------------

   -- Check if the image has valid texture data
   function Is_Valid (Img : Image) return Boolean;

   -- Get image dimensions
   procedure Get_Size
      (Img    : Image;
       Width  : out Pixel_Type;
       Height : out Pixel_Type);

   -- Get the underlying SDL texture (for rendering)
   function Get_Texture (Img : Image) return SDL_Texture_Ptr;

   -- Get a texture rendered for a specific size.
   -- For raster images this returns the base texture.
   -- For SVG images this lazily rasterizes and caches per size.
   function Get_Texture_For_Size
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr;
      Width    : Pixel_Type;
      Height   : Pixel_Type) return SDL_Texture_Ptr;

   ---------------------------------------------------------------------------
   -- Resource Management
   ---------------------------------------------------------------------------

   -- Destroy the image and free its texture
   procedure Destroy (Img : in out Image);

   -- Null/Empty image constant
   Null_Image : constant Image_Access := null;

private

   type Image_Kind is (Raster_Image, SVG_Image);

   type Cached_Texture is record
      Width_Px  : Positive;
      Height_Px : Positive;
      Texture   : SDL_Texture_Ptr := null;
   end record;

   package Cached_Texture_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cached_Texture);

   type Image is tagged record
      Kind    : Image_Kind := Raster_Image;
      Texture : SDL_Texture_Ptr := null;
      Width   : Pixel_Type := 0.0;
      Height  : Pixel_Type := 0.0;
      SVG     : Adi.SVG.Document_Access := null;
      Cache   : Cached_Texture_Vectors.Vector;
   end record;

end Adi.Image;
