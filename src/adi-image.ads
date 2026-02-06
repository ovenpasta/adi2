with Adi.Core;       use Adi.Core;
with Adi.SDL.Render; use Adi.SDL.Render;

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

   ---------------------------------------------------------------------------
   -- Resource Management
   ---------------------------------------------------------------------------

   -- Destroy the image and free its texture
   procedure Destroy (Img : in out Image);

   -- Null/Empty image constant
   Null_Image : constant Image_Access := null;

private

   type Image is tagged record
      Texture : SDL_Texture_Ptr := null;
      Width   : Pixel_Type := 0.0;
      Height  : Pixel_Type := 0.0;
   end record;

end Adi.Image;
