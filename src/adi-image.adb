with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Log;
with Adi.SDL;       use Adi.SDL;
with Adi.SDL.Image; use Adi.SDL.Image;

package body Adi.Image is

   ---------------------------------------------------------------------------
   -- Load_From_File
   ---------------------------------------------------------------------------

   function Load_From_File
      (Renderer : SDL_Renderer_Ptr;
       Path     : String) return Image_Access
   is
      use Interfaces.C.Strings;

      C_Path  : chars_ptr;
      Texture : SDL_Texture_Ptr;
      Img     : Image_Access;
      W, H    : aliased Float;
      Success : Adi.SDL.C_bool;
   begin
      if Renderer = null then
         Adi.Log.Error ("Cannot load image, renderer is null");
         return null;
      end if;

      -- Convert Ada string to C string
      C_Path := New_String (Path);

      -- Load the image using SDL_image
      Texture := IMG_LoadTexture (Renderer, C_Path);
      Free (C_Path);

      if Texture = null then
         Adi.Log.Error ("Failed to load image: " & Path);
         return null;
      end if;

      -- Get texture dimensions
      Success := SDL_GetTextureSize (Texture, W'Access, H'Access);
      if not Success then
         Adi.Log.Warning ("Could not get texture size for: " & Path);
         W := 0.0;
         H := 0.0;
      end if;

      -- Create the image object
      Img := new Image'(
         Texture => Texture,
         Width   => Pixel_Type (W),
         Height  => Pixel_Type (H)
      );

      return Img;
   end Load_From_File;

   ---------------------------------------------------------------------------
   -- Create_From_Texture
   ---------------------------------------------------------------------------

   function Create_From_Texture
      (Texture : SDL_Texture_Ptr) return Image_Access
   is
      Img     : Image_Access;
      W, H    : aliased Float;
      Success : Adi.SDL.C_bool;
   begin
      if Texture = null then
         return null;
      end if;

      -- Get texture dimensions
      Success := SDL_GetTextureSize (Texture, W'Access, H'Access);
      if not Success then
         W := 0.0;
         H := 0.0;
      end if;

      -- Create the image object
      Img := new Image'(
         Texture => Texture,
         Width   => Pixel_Type (W),
         Height  => Pixel_Type (H)
      );

      return Img;
   end Create_From_Texture;

   ---------------------------------------------------------------------------
   -- Create_Empty
   ---------------------------------------------------------------------------

   function Create_Empty return Image_Access is
   begin
      return new Image'(
         Texture => null,
         Width   => 0.0,
         Height  => 0.0
      );
   end Create_Empty;

   ---------------------------------------------------------------------------
   -- Is_Valid
   ---------------------------------------------------------------------------

   function Is_Valid (Img : Image) return Boolean is
   begin
      return Img.Texture /= null;
   end Is_Valid;

   ---------------------------------------------------------------------------
   -- Get_Size
   ---------------------------------------------------------------------------

   procedure Get_Size
      (Img    : Image;
       Width  : out Pixel_Type;
       Height : out Pixel_Type)
   is
   begin
      Width  := Img.Width;
      Height := Img.Height;
   end Get_Size;

   ---------------------------------------------------------------------------
   -- Get_Texture
   ---------------------------------------------------------------------------

   function Get_Texture (Img : Image) return SDL_Texture_Ptr is
   begin
      return Img.Texture;
   end Get_Texture;

   ---------------------------------------------------------------------------
   -- Destroy
   ---------------------------------------------------------------------------

   procedure Destroy (Img : in out Image) is
   begin
      if Img.Texture /= null then
         SDL_DestroyTexture (Img.Texture);
         Img.Texture := null;
         Img.Width   := 0.0;
         Img.Height  := 0.0;
      end if;
   end Destroy;

end Adi.Image;
