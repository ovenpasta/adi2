with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Log;
with Adi.SDL;       use Adi.SDL;
with Adi.SDL.Image; use Adi.SDL.Image;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
with Adi.SVG;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
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

   function Build_SVG_Image
      (Doc : Adi.SVG.Document_Access) return Image_Access
   is
      Img     : Image_Access;
      SW, SH  : Pixel_Type := 0.0;
   begin
      if Doc = null or else not Adi.SVG.Is_Valid (Doc.all) then
         return null;
      end if;

      Adi.SVG.Get_Size (Doc.all, SW, SH);
      Img := new Image'(
         Kind     => SVG_Image,
         Texture  => null,
         Width    => SW,
         Height   => SH,
         SVG      => Doc,
         Cache    => <>,
         Tintable => False
      );
      return Img;
   end Build_SVG_Image;

   function Escape_XML_Attr (S : String) return String is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      for C of S loop
         case C is
            when '&' =>
               Append (Result, "&amp;");
            when '<' =>
               Append (Result, "&lt;");
            when '>' =>
               Append (Result, "&gt;");
            when '"' =>
               Append (Result, "&quot;");
            when ''' =>
               Append (Result, "&apos;");
            when others =>
               Append (Result, C);
         end case;
      end loop;

      return To_String (Result);
   end Escape_XML_Attr;

   function Trim_Int (V : Integer) return String is
   begin
      return Ada.Strings.Fixed.Trim (Integer'Image (V), Ada.Strings.Both);
   end Trim_Int;

   function Opacity_String (Alpha_Byte : Natural) return String is
      Scaled : constant Natural := (Alpha_Byte * 1000 + 127) / 255;
      S      : constant String := Trim_Int (Integer (Scaled));
   begin
      if Alpha_Byte = 0 then
         return "0";
      elsif Alpha_Byte >= 255 then
         return "1";
      elsif Scaled >= 1000 then
         return "1";
      elsif Scaled < 10 then
         return "0.00" & S;
      elsif Scaled < 100 then
         return "0.0" & S;
      else
         return "0." & S;
      end if;
   end Opacity_String;

   function Decimal_String (V : Pixel_Type) return String is
      use type Pixel_Type;
      Scaled : Integer := Integer (Float'Rounding (Float (V * 1000.0)));
      Int_Part : Integer;
      Frac : Integer;
      Frac_Text : String (1 .. 3);
      Last : Natural := 3;
   begin
      if Scaled < 0 then
         Scaled := 0;
      end if;

      Int_Part := Scaled / 1000;
      Frac := Scaled mod 1000;
      if Frac = 0 then
         return Trim_Int (Int_Part);
      end if;

      Frac_Text (1) := Character'Val (Character'Pos ('0') + (Frac / 100));
      Frac_Text (2) := Character'Val (Character'Pos ('0') + ((Frac / 10) mod 10));
      Frac_Text (3) := Character'Val (Character'Pos ('0') + (Frac mod 10));

      while Last > 1 and then Frac_Text (Last) = '0' loop
         Last := Last - 1;
      end loop;

      return Trim_Int (Int_Part) & "." & Frac_Text (1 .. Last);
   end Decimal_String;

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
   begin
      if Is_SVG_Path (Path) then
         Doc := Adi.SVG.Load_From_File (Path);
         if Doc = null or else not Adi.SVG.Is_Valid (Doc.all) then
            Adi.Log.Error ("Failed to load SVG image: " & Path);
            return null;
         end if;

         return Build_SVG_Image (Doc);
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
         Kind     => Raster_Image,
         Texture  => Texture,
         Width    => Pixel_Type (W),
         Height   => Pixel_Type (H),
         SVG      => null,
         Cache    => <>,
         Tintable => False
      );

      return Img;
   end Load_From_File;

   function Load_SVG_From_String
      (Renderer : SDL_Renderer_Ptr;
       Source   : String;
       Tintable : Boolean := False) return Image_Access
   is
      pragma Unreferenced (Renderer);
      Doc    : Adi.SVG.Document_Access := null;
      Result : Image_Access;
   begin
      Doc := Adi.SVG.Load_From_String (Source);
      if Doc = null or else not Adi.SVG.Is_Valid (Doc.all) then
         Adi.Log.Error ("Failed to load SVG image from source string");
         return null;
      end if;

      Result := Build_SVG_Image (Doc);
      if Result /= null and then Tintable then
         Result.Tintable := True;
      end if;
      return Result;
   end Load_SVG_From_String;

   function Load_SVG_Path
      (Renderer  : SDL_Renderer_Ptr;
       Path_Data : String;
       Size      : Size_2D;
       Fill      : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Stroke_Width : Pixel_Type := 0.0;
       Stroke    : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Tintable  : Boolean := False) return Image_Access
   is
      pragma Unreferenced (Renderer);
      Width_Px  : constant Positive :=
        Positive (Integer'Max (1, Integer (Float'Ceiling (Float (Size.Width)))));
      Height_Px : constant Positive :=
        Positive (Integer'Max (1, Integer (Float'Ceiling (Float (Size.Height)))));
      Width_Text  : constant String := Trim_Int (Width_Px);
      Height_Text : constant String := Trim_Int (Height_Px);
      Fill_A_Byte : constant Natural := Natural (Fill.A);
      Stroke_A_Byte : constant Natural := Natural (Stroke.A);
      Stroke_Width_Text : constant String := Decimal_String (Pixel_Type'Max (0.0, Stroke_Width));
      Safe_Path : constant String := Escape_XML_Attr (Path_Data);
      Fill_Text : Unbounded_String := Null_Unbounded_String;
      Fill_Opacity_Text : Unbounded_String := Null_Unbounded_String;
      Stroke_Text : Unbounded_String := Null_Unbounded_String;
      Stroke_Opacity_Text : Unbounded_String := Null_Unbounded_String;
      G_Attrs : Unbounded_String := Null_Unbounded_String;
      Source  : Unbounded_String := Null_Unbounded_String;
   begin
      if Path_Data'Length = 0 then
         return null;
      end if;

      Fill_Text :=
        To_Unbounded_String
          ("rgb("
           & Trim_Int (Integer (Fill.R)) & ","
           & Trim_Int (Integer (Fill.G)) & ","
           & Trim_Int (Integer (Fill.B)) & ")");
      Fill_Opacity_Text := To_Unbounded_String (Opacity_String (Fill_A_Byte));
      Stroke_Text :=
        To_Unbounded_String
          ("rgb("
           & Trim_Int (Integer (Stroke.R)) & ","
           & Trim_Int (Integer (Stroke.G)) & ","
           & Trim_Int (Integer (Stroke.B)) & ")");
      Stroke_Opacity_Text := To_Unbounded_String (Opacity_String (Stroke_A_Byte));

      G_Attrs :=
        To_Unbounded_String
          ("fill=""" & Escape_XML_Attr (To_String (Fill_Text)) & """"
           & " stroke=""" & Escape_XML_Attr (To_String (Stroke_Text)) & """"
           & " stroke-width=""" & Stroke_Width_Text & """");
      if Fill_A_Byte < 255 then
         Append
           (G_Attrs,
            " fill-opacity=""" & To_String (Fill_Opacity_Text) & """");
      end if;
      if Stroke_A_Byte < 255 then
         Append
           (G_Attrs,
            " stroke-opacity=""" & To_String (Stroke_Opacity_Text) & """");
      end if;

      Source :=
        To_Unbounded_String
          ("<svg xmlns=""http://www.w3.org/2000/svg"" width=""" & Width_Text
           & """ height=""" & Height_Text
           & """ viewBox=""0 0 " & Width_Text & " " & Height_Text & """>"
           & "<g " & To_String (G_Attrs) & "><path d=""" & Safe_Path & """/></g>"
           & "</svg>");

      return Load_SVG_From_String
        (Renderer => Renderer,
         Source   => To_String (Source),
         Tintable => Tintable);
   end Load_SVG_Path;

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
         Kind     => Raster_Image,
         Texture  => Texture,
         Width    => Pixel_Type (W),
         Height   => Pixel_Type (H),
         SVG      => null,
         Cache    => <>,
         Tintable => False
      );

      return Img;
   end Create_From_Texture;

   ---------------------------------------------------------------------------
   -- Create_Empty
   ---------------------------------------------------------------------------

   function Create_Empty return Image_Access is
   begin
      return new Image'(
         Kind     => Raster_Image,
         Texture  => null,
         Width    => 0.0,
         Height   => 0.0,
         SVG      => null,
         Cache    => <>,
         Tintable => False
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

   function Is_Tintable (Img : Image) return Boolean is
   begin
      return Img.Tintable;
   end Is_Tintable;

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
