with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Log;
with Adi.SDL;       use Adi.SDL;
with Adi.SDL.Image; use Adi.SDL.Image;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
with Adi.SVG;
with Ada.Characters.Handling;
with Ada.Unchecked_Deallocation;

package body Adi.Image is

   use type Adi.SVG.Document_Access;
   use type Adi.SVG.Pixel_Buffer_Access;

   procedure Free_SVG_Document is
     new Ada.Unchecked_Deallocation
       (Adi.SVG.Document'Class, Adi.SVG.Document_Access);

   procedure Free_Pixels is
     new Ada.Unchecked_Deallocation
       (Adi.SVG.Pixel_Buffer, Adi.SVG.Pixel_Buffer_Access);

   function Is_SVG_Path (Path : String) return Boolean is
      use Ada.Characters.Handling;
   begin
      if Path'Length < 4 then
         return False;
      end if;

      return To_Lower (Path (Path'Last - 3 .. Path'Last)) = ".svg";
   end Is_SVG_Path;

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
      Doc     : Adi.SVG.Document_Access;
      SW, SH  : Pixel_Type := 0.0;
   begin
      if Is_SVG_Path (Path) then
         Doc := Adi.SVG.Load_From_File (Path);
         if Doc = null or else not Adi.SVG.Is_Valid (Doc.all) then
            Adi.Log.Error ("Failed to load SVG image: " & Path);
            return null;
         end if;

         Adi.SVG.Get_Size (Doc.all, SW, SH);
         Img := new Image'(
            Kind    => SVG_Image,
            Texture => null,
            Width   => SW,
            Height  => SH,
            SVG     => Doc,
            Cache   => <>
         );
         return Img;
      end if;

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
         Kind    => Raster_Image,
         Texture => Texture,
         Width   => Pixel_Type (W),
         Height  => Pixel_Type (H),
         SVG     => null,
         Cache   => <>
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
         Kind    => Raster_Image,
         Texture => Texture,
         Width   => Pixel_Type (W),
         Height  => Pixel_Type (H),
         SVG     => null,
         Cache   => <>
      );

      return Img;
   end Create_From_Texture;

   ---------------------------------------------------------------------------
   -- Create_Empty
   ---------------------------------------------------------------------------

   function Create_Empty return Image_Access is
   begin
      return new Image'(
         Kind    => Raster_Image,
         Texture => null,
         Width   => 0.0,
         Height  => 0.0,
         SVG     => null,
         Cache   => <>
      );
   end Create_Empty;

   ---------------------------------------------------------------------------
   -- Is_Valid
   ---------------------------------------------------------------------------

   function Is_Valid (Img : Image) return Boolean is
   begin
      if Img.Kind = SVG_Image then
         return Img.SVG /= null and then Adi.SVG.Is_Valid (Img.SVG.all);
      end if;
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
   -- Get_Texture_For_Size
   ---------------------------------------------------------------------------

   function Get_Texture_For_Size
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr;
      Width    : Pixel_Type;
      Height   : Pixel_Type) return SDL_Texture_Ptr
   is
      Target_W : constant Positive := Positive (Integer'Max (1, Integer (Float'Ceiling (Float (Width)))));
      Target_H : constant Positive := Positive (Integer'Max (1, Integer (Float'Ceiling (Float (Height)))));
      Pixels   : Adi.SVG.Pixel_Buffer_Access := null;
      Texture  : SDL_Texture_Ptr;
      Success  : Adi.SDL.C_bool;
   begin
      if Img.Kind = Raster_Image then
         return Img.Texture;
      end if;

      if Img.SVG = null or else not Adi.SVG.Is_Valid (Img.SVG.all) then
         return null;
      end if;

      for Cache_Item of Img.Cache loop
         if Cache_Item.Width_Px = Target_W and then Cache_Item.Height_Px = Target_H then
            return Cache_Item.Texture;
         end if;
      end loop;

      if Renderer = null then
         return null;
      end if;

      Pixels := Adi.SVG.Render_ARGB32 (Img.SVG.all, Target_W, Target_H);
      if Pixels = null then
         return null;
      end if;

      Texture := SDL_CreateTexture
        (Renderer    => Renderer,
         Format      => SDL_PIXELFORMAT_ARGB8888,
         Access_Mode => SDL_TEXTUREACCESS_STATIC,
         W           => int (Target_W),
         H           => int (Target_H));
      if Texture = null then
         Free_Pixels (Pixels);
         return null;
      end if;

      Success := SDL_UpdateTexture
        (Texture => Texture,
         Rect    => null,
         Pixels  => Pixels.all'Address,
         Pitch   => int (Target_W * 4));
      Free_Pixels (Pixels);

      if not Success then
         SDL_DestroyTexture (Texture);
         return null;
      end if;

      Img.Cache.Append
        (New_Item => Cached_Texture'
           (Width_Px  => Target_W,
            Height_Px => Target_H,
            Texture   => Texture));
      return Texture;
   end Get_Texture_For_Size;

   ---------------------------------------------------------------------------
   -- Destroy
   ---------------------------------------------------------------------------

   procedure Destroy (Img : in out Image) is
   begin
      if Img.Texture /= null then
         SDL_DestroyTexture (Img.Texture);
         Img.Texture := null;
      end if;

      for Cache_Item of Img.Cache loop
         if Cache_Item.Texture /= null then
            SDL_DestroyTexture (Cache_Item.Texture);
         end if;
      end loop;
      Img.Cache.Clear;

      if Img.SVG /= null then
         Adi.SVG.Destroy (Img.SVG.all);
         Free_SVG_Document (Img.SVG);
      end if;

      Img.Width   := 0.0;
      Img.Height  := 0.0;
   end Destroy;

end Adi.Image;
