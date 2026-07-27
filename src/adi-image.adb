--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with System;
with Adi.Log;
with Adi.SDL;       use Adi.SDL;
with Adi.SDL.IO;    use Adi.SDL.IO;
with Adi.SDL.Image; use Adi.SDL.Image;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
with Adi.SVG;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

package body Adi.Image is

   use type System.Address;
   use type Adi.SVG.Document_Access;
   use type Adi.SVG.Pixel_Buffer_Access;

   procedure Free_SVG_Document is
     new Ada.Unchecked_Deallocation
       (Adi.SVG.Document'Class, Adi.SVG.Document_Access);

   procedure Free_Pixels is
     new Ada.Unchecked_Deallocation
       (Adi.SVG.Pixel_Buffer, Adi.SVG.Pixel_Buffer_Access);

   procedure Free_Image is
     new Ada.Unchecked_Deallocation
       (Image'Class, Image_Access);

   ---------------------------------------------------------------------------
   --  Live image registry — tracks all allocated Image_Access values so
   --  Release_All_Textures_For_Renderer can iterate every image globally.
   ---------------------------------------------------------------------------

   package Image_Ptr_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Image_Access);

   Live_Images : Image_Ptr_Vectors.Vector;

   procedure Register (Img : Image_Access) is
   begin
      if Img /= null then
         Live_Images.Append (Img);
      end if;
   end Register;

   procedure Unregister (Img : Image_Access) is
   begin
      for I in 1 .. Natural (Live_Images.Length) loop
         if Live_Images (I) = Img then
            Live_Images.Delete (I);
            return;
         end if;
      end loop;
   end Unregister;

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
         Surface  => null,
         Texture  => null,
         Width    => SW,
         Height   => SH,
         SVG      => Doc,
         Cache    => <>,
         Tintable => False,
         Scaling  => Scale_Linear
      );
      Register (Img);
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

   function Load_From_File (Path : String) return Image_Access
   is
      use Interfaces.C.Strings;

      C_Path  : chars_ptr;
      Surf    : SDL_Surface_Ptr;
      Img     : Image_Access;
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

      C_Path := New_String (Path);
      Surf := IMG_Load (C_Path);
      Free (C_Path);

      if Surf = null then
         Adi.Log.Error ("Failed to load image: " & Path);
         return null;
      end if;

      Img := new Image'(
         Kind     => Raster_Image,
         Surface  => Surf,
         Texture  => null,
         Width    => Pixel_Type (Float (Surf.w)),
         Height   => Pixel_Type (Float (Surf.h)),
         SVG      => null,
         Cache    => <>,
         Tintable => False,
         Scaling  => Scale_Linear
      );

      Register (Img);
      return Img;
   end Load_From_File;

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count) return Image_Access
   is
      use System.Storage_Elements;
      Stream : SDL_IOStream_Ptr;
      Surf   : SDL_Surface_Ptr;
      Img    : Image_Access;
   begin
      if Data = System.Null_Address or else Length = 0 then
         return null;
      end if;

      Stream := SDL_IOFromConstMem (Data, size_t (Length));
      if Stream = null then
         Adi.Log.Error ("Failed to create IO stream from memory");
         return null;
      end if;

      --  closeio=True: SDL frees the IO stream struct (not the backing memory)
      Surf := IMG_Load_IO (Stream, True);
      if Surf = null then
         Adi.Log.Error ("Failed to load image from memory");
         return null;
      end if;

      Img := new Image'(
         Kind     => Raster_Image,
         Surface  => Surf,
         Texture  => null,
         Width    => Pixel_Type (Float (Surf.w)),
         Height   => Pixel_Type (Float (Surf.h)),
         SVG      => null,
         Cache    => <>,
         Tintable => False,
         Scaling  => Scale_Linear
      );

      Register (Img);
      return Img;
   end Load_From_Memory;

   function Load_SVG_From_String
      (Source   : String;
       Tintable : Boolean := False) return Image_Access
   is
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
      (Path_Data : String;
       Size      : Size_2D;
       Fill      : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Stroke_Width : Pixel_Type := 0.0;
       Stroke    : Color_8 := (R => 0, G => 0, B => 0, A => 255);
       Tintable  : Boolean := False) return Image_Access
   is
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
        (Source   => To_String (Source),
         Tintable => Tintable);
   end Load_SVG_Path;

   ---------------------------------------------------------------------------
   -- Create_From_Surface
   ---------------------------------------------------------------------------

   function Create_From_Surface
      (Surface : SDL_Surface_Ptr) return Image_Access
   is
      Img : Image_Access;
   begin
      if Surface = null then
         return null;
      end if;

      Img := new Image'(
         Kind     => Raster_Image,
         Surface  => Surface,
         Texture  => null,
         Width    => Pixel_Type (Float (Surface.w)),
         Height   => Pixel_Type (Float (Surface.h)),
         SVG      => null,
         Cache    => <>,
         Tintable => False,
         Scaling  => Scale_Linear
      );

      Register (Img);
      return Img;
   end Create_From_Surface;

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
         Surface  => null,
         Texture  => Texture,
         Width    => Pixel_Type (W),
         Height   => Pixel_Type (H),
         SVG      => null,
         Cache    => <>,
         Tintable => False,
         Scaling  => Scale_Linear
      );

      Register (Img);
      return Img;
   end Create_From_Texture;

   ---------------------------------------------------------------------------
   -- Create_Empty
   ---------------------------------------------------------------------------

   function Create_Empty return Image_Access is
      Img : Image_Access;
   begin
      Img := new Image'(
         Kind     => Raster_Image,
         Surface  => null,
         Texture  => null,
         Width    => 0.0,
         Height   => 0.0,
         SVG      => null,
         Cache    => <>,
         Tintable => False,
         Scaling  => Scale_Linear
      );
      Register (Img);
      return Img;
   end Create_Empty;

   ---------------------------------------------------------------------------
   -- Is_Valid
   ---------------------------------------------------------------------------

   function Is_Valid (Img : Image) return Boolean is
   begin
      if Img.Kind = SVG_Image then
         return Img.SVG /= null and then Adi.SVG.Is_Valid (Img.SVG.all);
      end if;
      return Img.Surface /= null or else Img.Texture /= null;
   end Is_Valid;

   function Is_Tintable (Img : Image) return Boolean is
   begin
      return Img.Tintable;
   end Is_Tintable;

   function Get_Surface (Img : Image) return SDL_Surface_Ptr is
   begin
      return Img.Surface;
   end Get_Surface;

   procedure Set_Tintable (Img : in out Image; Value : Boolean := True) is
   begin
      Img.Tintable := Value;
   end Set_Tintable;

   function To_SDL
     (Mode : Image_Scale_Mode) return Adi.SDL.Render.SDL_ScaleMode
   is
      use Adi.SDL.Render;
   begin
      case Mode is
         when Scale_Linear   => return SDL_SCALEMODE_LINEAR;
         when Scale_Nearest  => return SDL_SCALEMODE_NEAREST;
         when Scale_Pixelart => return SDL_SCALEMODE_PIXELART;
      end case;
   end To_SDL;

   function Get_Scale_Mode (Img : Image) return Image_Scale_Mode is
   begin
      return Img.Scaling;
   end Get_Scale_Mode;

   procedure Set_Scale_Mode
     (Img  : in out Image;
      Mode : Image_Scale_Mode)
   is
      pragma Warnings (Off, "variable * is assigned but never read");
      Success : Adi.SDL.C_bool;
      pragma Warnings (On, "variable * is assigned but never read");
   begin
      Img.Scaling := Mode;
      --  Update existing cached textures
      for Cache_Item of Img.Cache loop
         if Cache_Item.Texture /= null then
            Success := SDL_SetTextureScaleMode
              (Cache_Item.Texture, To_SDL (Mode));
         end if;
      end loop;
      if Img.Texture /= null then
         Success := SDL_SetTextureScaleMode (Img.Texture, To_SDL (Mode));
      end if;
   end Set_Scale_Mode;

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
   -- Get_Texture (parameterless — backward compat)
   ---------------------------------------------------------------------------

   function Get_Texture (Img : Image) return SDL_Texture_Ptr is
   begin
      --  Direct texture (Create_From_Texture path)
      if Img.Texture /= null then
         return Img.Texture;
      end if;

      --  Return first cached texture if any
      if not Img.Cache.Is_Empty then
         return Img.Cache.First_Element.Texture;
      end if;

      return null;
   end Get_Texture;

   ---------------------------------------------------------------------------
   -- Get_Texture (with Renderer — lazy creation)
   ---------------------------------------------------------------------------

   function Get_Texture
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr) return SDL_Texture_Ptr
   is
      Texture : SDL_Texture_Ptr;
      Success : Adi.SDL.C_bool;
   begin
      --  Direct texture (Create_From_Texture path)
      if Img.Texture /= null then
         return Img.Texture;
      end if;

      if Renderer = null then
         return null;
      end if;

      --  For raster images with a surface, create texture lazily per renderer
      if Img.Kind = Raster_Image and then Img.Surface /= null then
         --  Check cache for this renderer
         for Cache_Item of Img.Cache loop
            if Cache_Item.Renderer = Renderer then
               return Cache_Item.Texture;
            end if;
         end loop;

         --  Create texture from surface
         Texture := SDL_CreateTextureFromSurface (Renderer, Img.Surface);
         if Texture = null then
            return null;
         end if;

         Success := SDL_SetTextureBlendMode (Texture, SDL_BLENDMODE_BLEND);
         Success := SDL_SetTextureScaleMode (Texture, To_SDL (Img.Scaling));
         pragma Unreferenced (Success);

         Img.Cache.Append
           (Cached_Texture'
              (Renderer  => Renderer,
               Width_Px  => Positive (Integer'Max (1, Integer (Img.Surface.w))),
               Height_Px => Positive (Integer'Max (1, Integer (Img.Surface.h))),
               Texture   => Texture));
         return Texture;
      end if;

      --  For SVG without specific size, return null (use Get_Texture_For_Size)
      return null;
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
         return Get_Texture (Img, Renderer);
      end if;

      if Img.SVG = null or else not Adi.SVG.Is_Valid (Img.SVG.all) then
         return null;
      end if;

      --  Check cache by (renderer, width, height)
      for Cache_Item of Img.Cache loop
         if Cache_Item.Renderer = Renderer
           and then Cache_Item.Width_Px = Target_W
           and then Cache_Item.Height_Px = Target_H
         then
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

      Success := SDL_SetTextureScaleMode (Texture, To_SDL (Img.Scaling));
      pragma Unreferenced (Success);

      Img.Cache.Append
        (New_Item => Cached_Texture'
           (Renderer  => Renderer,
            Width_Px  => Target_W,
            Height_Px => Target_H,
            Texture   => Texture));
      return Texture;
   end Get_Texture_For_Size;

   ---------------------------------------------------------------------------
   -- Destroy
   ---------------------------------------------------------------------------

   procedure Destroy (Img : in out Image) is
   begin
      if Img.Surface /= null then
         SDL_DestroySurface (Img.Surface);
         Img.Surface := null;
      end if;

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

   ---------------------------------------------------------------------------
   -- Release_Textures_For_Renderer
   ---------------------------------------------------------------------------

   procedure Release_Textures_For_Renderer
     (Img      : in out Image'Class;
      Renderer : SDL_Renderer_Ptr)
   is
      I : Natural := 1;
   begin
      if Renderer = null then
         return;
      end if;

      while I <= Natural (Img.Cache.Length) loop
         if Img.Cache (I).Renderer = Renderer then
            if Img.Cache (I).Texture /= null then
               SDL_DestroyTexture (Img.Cache (I).Texture);
            end if;
            Img.Cache.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
   end Release_Textures_For_Renderer;

   ---------------------------------------------------------------------------
   -- Release_All_Textures_For_Renderer
   ---------------------------------------------------------------------------

   procedure Release_All_Textures_For_Renderer
     (Renderer : SDL_Renderer_Ptr)
   is
   begin
      if Renderer = null then
         return;
      end if;

      for Img of Live_Images loop
         if Img /= null then
            Release_Textures_For_Renderer (Img.all, Renderer);
         end if;
      end loop;
   end Release_All_Textures_For_Renderer;

   ---------------------------------------------------------------------------
   -- Free
   ---------------------------------------------------------------------------

   procedure Free (Img : in out Image_Access) is
   begin
      if Img = null then
         return;
      end if;

      Unregister (Img);
      Destroy (Img.all);
      Free_Image (Img);
   end Free;

end Adi.Image;
