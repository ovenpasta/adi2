--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Clock;
with Adi.Log;
with Adi.SDL;       use Adi.SDL;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.IO;    use Adi.SDL.IO;
with Adi.SDL.Image; use Adi.SDL.Image;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
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

   --  Identity handed to the texture cache. A counter rather than the
   --  image's address: addresses are reused after a free, and an entry
   --  from a dead image would then be found by a live one.
   Next_Source : Adi.Texture_Cache.Source_Id := 0;

   function New_Source return Adi.Texture_Cache.Source_Id is
      use type Adi.Texture_Cache.Source_Id;
   begin
      Next_Source := Next_Source + 1;
      return Next_Source;
   end New_Source;

   --  The image behind a handle, or null when the handle names nothing.
   function Resolve (H : Image_Handle) return Image_Access
   is (Image_Stores.Resolve (H.Ref));

   --  Hand a freshly built image to the store, which takes it and hands
   --  back the first owner. A null image is no image: the caller gets an
   --  owner of nothing rather than an exception.
   function Publish (Img : Image_Access) return Image_Owner is
   begin
      if Img = null then
         return (Ref => <>);
      end if;

      return (Ref => Image_Stores.Register (Img));
   end Publish;

   --  Scale mode is texture state, so a texture built for one mode cannot
   --  serve another: it participates in the key rather than being applied
   --  to whatever the cache happens to hold.
   function Mode_Variant (Mode : Image_Scale_Mode) return Natural is
     (Image_Scale_Mode'Pos (Mode));

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
      Owned   : Adi.SVG.Document_Access := Doc;
   begin
      --  The document is this subprogram's from here, on every path out:
      --  callers hand it over and do not look at it again.
      if Doc = null then
         return null;
      end if;

      if not Adi.SVG.Is_Valid (Doc.all) then
         Adi.SVG.Destroy (Owned.all);
         Free_SVG_Document (Owned);
         return null;
      end if;

      Adi.SVG.Get_Size (Doc.all, SW, SH);

      --  The document is this subprogram's until the record holds it.
      --  Nothing else knows about it yet, so a failure here is the only
      --  chance to end it.
      begin
         Img := new Image'(
            Kind     => SVG_Image,
            Surface  => null,
            Width    => SW,
            Height   => SH,
            SVG      => Doc,
            Source   => New_Source,
            Group    => null,
            Tintable => False,
            Scaling  => Scale_Linear
         );
      exception
         when others =>
            Adi.SVG.Destroy (Owned.all);
            Free_SVG_Document (Owned);
            raise;
      end;
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

   function New_From_File (Path : String) return Image_Access
   is
      use Interfaces.C.Strings;

      C_Path  : chars_ptr;
      Surf    : SDL_Surface_Ptr;
      Img     : Image_Access;
      Doc     : Adi.SVG.Document_Access;
   begin
      if Is_SVG_Path (Path) then
         Doc := Adi.SVG.Load_From_File (Path);
         if Doc = null then
            Adi.Log.Error ("Failed to load SVG image: " & Path);
            return null;
         end if;

         --  Build_SVG_Image takes the document, including the case where
         --  it turns out to hold nothing.
         return Result : constant Image_Access := Build_SVG_Image (Doc) do
            if Result = null then
               Adi.Log.Error ("Failed to load SVG image: " & Path);
            end if;
         end return;
      end if;

      C_Path := New_String (Path);
      Surf := IMG_Load (C_Path);
      Free (C_Path);

      if Surf = null then
         Adi.Log.Error ("Failed to load image: " & Path);
         return null;
      end if;

      --  The surface is this subprogram's until the record holds it.
      begin
         Img := new Image'(
            Kind     => Raster_Image,
            Surface  => Surf,
            Width    => Pixel_Type (Float (Surf.w)),
            Height   => Pixel_Type (Float (Surf.h)),
            SVG      => null,
            Source   => New_Source,
            Group    => null,
            Tintable => False,
            Scaling  => Scale_Linear
         );
      exception
         when others =>
            SDL_DestroySurface (Surf);
            raise;
      end;

      return Img;
   end New_From_File;

   function New_From_Memory
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

      --  The surface is this subprogram's until the record holds it.
      begin
         Img := new Image'(
            Kind     => Raster_Image,
            Surface  => Surf,
            Width    => Pixel_Type (Float (Surf.w)),
            Height   => Pixel_Type (Float (Surf.h)),
            SVG      => null,
            Source   => New_Source,
            Group    => null,
            Tintable => False,
            Scaling  => Scale_Linear
         );
      exception
         when others =>
            SDL_DestroySurface (Surf);
            raise;
      end;

      return Img;
   end New_From_Memory;

   function New_SVG_From_String
      (Source   : String;
       Tintable : Boolean := False) return Image_Access
   is
      Doc    : Adi.SVG.Document_Access := null;
      Result : Image_Access;
   begin
      Doc := Adi.SVG.Load_From_String (Source);
      if Doc = null then
         Adi.Log.Error ("Failed to load SVG image from source string");
         return null;
      end if;

      Result := Build_SVG_Image (Doc);
      if Result = null then
         Adi.Log.Error ("Failed to load SVG image from source string");
      end if;
      if Result /= null and then Tintable then
         Result.Tintable := True;
      end if;
      return Result;
   end New_SVG_From_String;

   function New_SVG_Path
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

      return New_SVG_From_String
        (Source   => To_String (Source),
         Tintable => Tintable);
   end New_SVG_Path;

   ---------------------------------------------------------------------------
   -- Create_From_Surface
   ---------------------------------------------------------------------------

   --  Without the surface: it is attached once the store holds the
   --  record, so that every path that fails before then leaves the
   --  surface with the caller and no path can free it twice.
   function New_Surfaceless
      (Group : Adi.Texture_Cache.Texture_Group_Access := null)
       return Image_Access
   is (new Image'(
         Kind     => Raster_Image,
         Surface  => null,
         Width    => 0.0,
         Height   => 0.0,
         SVG      => null,
         Source   => New_Source,
         Group    => Group,
         Tintable => False,
         Scaling  => Scale_Linear));

   ---------------------------------------------------------------------------
   -- Create_Empty
   ---------------------------------------------------------------------------

   function New_Empty return Image_Access is
      Img : Image_Access;
   begin
      Img := new Image'(
         Kind     => Raster_Image,
         Surface  => null,
         Width    => 0.0,
         Height   => 0.0,
         SVG      => null,
         Source   => New_Source,
         Group    => null,
         Tintable => False,
         Scaling  => Scale_Linear
      );
      return Img;
   end New_Empty;

   ---------------------------------------------------------------------------
   -- Is_Valid
   ---------------------------------------------------------------------------

   function Is_Valid (Img : Image'Class) return Boolean is
   begin
      if Img.Kind = SVG_Image then
         return Img.SVG /= null and then Adi.SVG.Is_Valid (Img.SVG.all);
      end if;
      return Img.Surface /= null or else Img.SVG /= null;
   end Is_Valid;

   function Is_Tintable (Img : Image'Class) return Boolean is
   begin
      return Img.Tintable;
   end Is_Tintable;

   function Get_Surface (Img : Image'Class) return SDL_Surface_Ptr is
   begin
      return Img.Surface;
   end Get_Surface;

   procedure Set_Tintable (Img : in out Image'Class; Value : Boolean := True) is
   begin
      Img.Tintable := Value;
   end Set_Tintable;

   function To_SDL
     (Mode : Image_Scale_Mode) return Adi.SDL.Render.SDL_ScaleMode
   is
   begin
      case Mode is
         when Scale_Linear   => return SDL_SCALEMODE_LINEAR;
         when Scale_Nearest  => return SDL_SCALEMODE_NEAREST;
         when Scale_Pixelart => return SDL_SCALEMODE_PIXELART;
      end case;
   end To_SDL;

   function Get_Scale_Mode (Img : Image'Class) return Image_Scale_Mode is
   begin
      return Img.Scaling;
   end Get_Scale_Mode;

   procedure Set_Scale_Mode
     (Img  : in out Image'Class;
      Mode : Image_Scale_Mode)
   is
   begin
      --  Nothing to update in place: the mode is part of a texture's key,
      --  so a lease taken after this finds or builds one made for it.
      Img.Scaling := Mode;
   end Set_Scale_Mode;

   ---------------------------------------------------------------------------
   -- Get_Size
   ---------------------------------------------------------------------------

   procedure Get_Size
      (Img    : Image'Class;
       Width  : out Pixel_Type;
       Height : out Pixel_Type)
   is
   begin
      Width  := Img.Width;
      Height := Img.Height;
   end Get_Size;

   ---------------------------------------------------------------------------
   -- Acquire_Texture
   ---------------------------------------------------------------------------

   --  Uploads the image's surface. Raster textures do not vary with the
   --  requested size, so only the scale mode distinguishes them.
   function Raster_Key (Img : Image'Class) return Adi.Texture_Cache.Texture_Key
   is ((Kind     => Adi.Texture_Cache.Raster_Texture,
        Source   => Img.Source,
        Variant  => Mode_Variant (Img.Scaling),
        others   => <>));

   function SVG_Key
     (Img : Image'Class; W, H : Positive) return Adi.Texture_Cache.Texture_Key
   is ((Kind     => Adi.Texture_Cache.SVG_Texture,
        Source   => Img.Source,
        Extent_A => W,
        Extent_B => H,
        Variant  => Mode_Variant (Img.Scaling),
        others   => <>));

   function Build_Raster
     (Img : Image'Class; Renderer : SDL_Renderer_Ptr) return SDL_Texture_Ptr
   is
      Texture : SDL_Texture_Ptr;
   begin
      Texture := SDL_CreateTextureFromSurface (Renderer, Img.Surface);
      if Texture = null then
         return null;
      end if;
      declare
         --  Advisory: a texture that refuses a blend or scale mode still
         --  draws, just without them.
         Blend_Ok : constant Adi.SDL.C_bool :=
           SDL_SetTextureBlendMode (Texture, SDL_BLENDMODE_BLEND);
         Scale_Ok : constant Adi.SDL.C_bool :=
           SDL_SetTextureScaleMode (Texture, To_SDL (Img.Scaling));
         pragma Unreferenced (Blend_Ok, Scale_Ok);
      begin
         return Texture;
      end;
   end Build_Raster;

   function Build_SVG
     (Img      : Image'Class;
      Renderer : SDL_Renderer_Ptr;
      W, H     : Positive) return SDL_Texture_Ptr
   is
      Pixels  : Adi.SVG.Pixel_Buffer_Access := null;
      Texture : SDL_Texture_Ptr;
      Success : Adi.SDL.C_bool;
   begin
      Pixels := Adi.SVG.Render_ARGB32 (Img.SVG.all, W, H);
      if Pixels = null then
         return null;
      end if;

      Texture := SDL_CreateTexture
        (Renderer    => Renderer,
         Format      => SDL_PIXELFORMAT_ARGB8888,
         Access_Mode => SDL_TEXTUREACCESS_STATIC,
         W           => int (W),
         H           => int (H));
      if Texture = null then
         Free_Pixels (Pixels);
         return null;
      end if;

      Success := SDL_UpdateTexture
        (Texture => Texture,
         Rect    => null,
         Pixels  => Pixels.all'Address,
         Pitch   => int (W * 4));
      Free_Pixels (Pixels);

      if not Success then
         SDL_DestroyTexture (Texture);
         return null;
      end if;

      --  Scale mode only. The raster path sets a blend mode; this one
      --  never has, and changing that here would alter how transparent
      --  SVGs composite under a migration that is meant to move where
      --  textures live and nothing else.
      Success := SDL_SetTextureScaleMode (Texture, To_SDL (Img.Scaling));
      return Texture;
   end Build_SVG;

   function Acquire_Texture
     (Img    : in out Image'Class;
      Ctx    : in out Adi.Render.Render_Context;
      Width  : Pixel_Type;
      Height : Pixel_Type) return Adi.Texture_Cache.Texture_Ref
   is
      use type Adi.Texture_Cache.Byte_Count;
      use type Adi.Clock.Time;

      Renderer : constant SDL_Renderer_Ptr := Adi.Render.Get_Renderer (Ctx);
      Is_SVG   : constant Boolean :=
        Img.Kind = SVG_Image
        and then Img.SVG /= null
        and then Adi.SVG.Is_Valid (Img.SVG.all);

      Target_W : constant Positive :=
        Positive (Integer'Max (1, Integer (Float'Ceiling (Float (Width)))));
      Target_H : constant Positive :=
        Positive (Integer'Max (1, Integer (Float'Ceiling (Float (Height)))));

      Key : constant Adi.Texture_Cache.Texture_Key :=
        (if Is_SVG then SVG_Key (Img, Target_W, Target_H)
         else Raster_Key (Img));

      Handle : Adi.Texture_Cache.Texture_Handle;
   begin
      if Renderer = null then
         return Adi.Texture_Cache.Null_Borrow;
      end if;

      if not Is_SVG
        and then (Img.Kind /= Raster_Image or else Img.Surface = null)
      then
         return Adi.Texture_Cache.Null_Borrow;
      end if;

      Handle := Adi.Render.Find_Texture (Ctx, Key);

      if not Adi.Render.Is_Valid_Texture (Ctx, Handle) then
         declare
            --  The whole path is measured, because the whole path is what
            --  an eviction makes the caller repeat: rasterising an SVG at
            --  this size, or uploading the surface, then configuring the
            --  result.
            Started : constant Adi.Clock.Time := Adi.Clock.Now;
            Built   : constant SDL_Texture_Ptr :=
              (if Is_SVG then Build_SVG (Img, Renderer, Target_W, Target_H)
               else Build_Raster (Img, Renderer));
            Took    : constant Adi.Clock.Time_Span := Adi.Clock.Now - Started;

            W : constant Positive :=
              (if Is_SVG then Target_W
               else Positive (Integer'Max (1, Integer (Img.Surface.w))));
            H : constant Positive :=
              (if Is_SVG then Target_H
               else Positive (Integer'Max (1, Integer (Img.Surface.h))));
         begin
            if Built = null then
               return Adi.Texture_Cache.Null_Borrow;
            end if;

            Handle := Adi.Render.Store_Texture
              (Ctx, Key, Built,
               Width      => W,
               Height     => H,
               Bytes      => Adi.Texture_Cache.Texture_Charge
                               (Adi.Texture_Cache.Byte_Count (W)
                                * Adi.Texture_Cache.Byte_Count (H) * 4),
               Build_Time => Took,
               Group      => Img.Group);

            --  Refused, so the cache took no ownership. There is nothing
            --  to lease and nobody else to free it.
            if not Adi.Render.Is_Valid_Texture (Ctx, Handle) then
               SDL_DestroyTexture (Built);
               return Adi.Texture_Cache.Null_Borrow;
            end if;
         end;
      end if;

      return Adi.Render.Borrow_Texture (Ctx, Handle);
   end Acquire_Texture;

   ---------------------------------------------------------------------------
   -- Handle operations
   --
   -- Each answers a handle that names nothing with the default an image
   -- holding nothing would give, so a viewer outliving an owner reads a
   -- blank rather than raising.
   ---------------------------------------------------------------------------

   function Load_From_File (Path : String) return Image_Owner
   is (Publish (New_From_File (Path)));

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count) return Image_Owner
   is (Publish (New_From_Memory (Data, Length)));

   function Load_SVG_From_String
     (Source   : String;
      Tintable : Boolean := False) return Image_Owner
   is (Publish (New_SVG_From_String (Source, Tintable)));

   function Load_SVG_Path
     (Path_Data : String;
      Size      : Size_2D;
      Fill      : Color_8 := (R => 0, G => 0, B => 0, A => 255);
      Stroke_Width : Pixel_Type := 0.0;
      Stroke    : Color_8 := (R => 0, G => 0, B => 0, A => 255);
      Tintable  : Boolean := False) return Image_Owner
   is (Publish (New_SVG_Path (Path_Data, Size, Fill, Stroke_Width,
                              Stroke, Tintable)));

   function Create_From_Surface
     (Surface : SDL_Surface_Ptr;
      Group   : Adi.Texture_Cache.Texture_Group_Access := null)
      return Image_Owner
   is
      Owner : Image_Owner;
      Img   : Image_Access;
   begin
      if Surface = null then
         return Null_Image_Owner;
      end if;

      --  Registered empty first. Anything that goes wrong up to here
      --  reclaims an image holding no surface, so the caller still has
      --  theirs and is the only one who can free it.
      Owner := Publish (New_Surfaceless (Group));
      Img := Resolve (To_Handle (Owner));
      if Img = null then
         return Null_Image_Owner;
      end if;

      Img.Surface := Surface;
      Img.Width := Pixel_Type (Float (Surface.w));
      Img.Height := Pixel_Type (Float (Surface.h));
      return Owner;
   end Create_From_Surface;

   function Create_Empty return Image_Owner
   is (Publish (New_Empty));

   function Is_Valid (H : Image_Handle) return Boolean is
      Img : constant Image_Access := Resolve (H);
   begin
      return Img /= null and then Is_Valid (Img.all);
   end Is_Valid;

   function Is_Tintable (H : Image_Handle) return Boolean is
      Img : constant Image_Access := Resolve (H);
   begin
      return Img /= null and then Is_Tintable (Img.all);
   end Is_Tintable;

   procedure Get_Size
     (H      : Image_Handle;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
      Img : constant Image_Access := Resolve (H);
   begin
      if Img = null then
         Width  := 0.0;
         Height := 0.0;
         return;
      end if;

      Get_Size (Img.all, Width, Height);
   end Get_Size;

   function Get_Surface (H : Image_Handle) return SDL_Surface_Ptr is
      Img : constant Image_Access := Resolve (H);
   begin
      return (if Img = null then null else Get_Surface (Img.all));
   end Get_Surface;

   procedure Set_Tintable (H : Image_Handle; Value : Boolean := True) is
      Img : constant Image_Access := Resolve (H);
   begin
      if Img /= null then
         Set_Tintable (Img.all, Value);
      end if;
   end Set_Tintable;

   function Get_Scale_Mode (H : Image_Handle) return Image_Scale_Mode is
      Img : constant Image_Access := Resolve (H);
   begin
      return (if Img = null then Scale_Linear else Get_Scale_Mode (Img.all));
   end Get_Scale_Mode;

   procedure Set_Scale_Mode
     (H    : Image_Handle;
      Mode : Image_Scale_Mode)
   is
      Img : constant Image_Access := Resolve (H);
   begin
      if Img /= null then
         Set_Scale_Mode (Img.all, Mode);
      end if;
   end Set_Scale_Mode;

   function Acquire_Texture
     (H      : Image_Handle;
      Ctx    : in out Adi.Render.Render_Context;
      Width  : Pixel_Type;
      Height : Pixel_Type) return Adi.Texture_Cache.Texture_Ref
   is
      Img : constant Image_Access := Resolve (H);
   begin
      if Img = null then
         return Adi.Texture_Cache.Null_Borrow;
      end if;

      return Acquire_Texture (Img.all, Ctx, Width, Height);
   end Acquire_Texture;

   function To_Handle (O : Image_Owner) return Image_Handle
   is (Ref => Image_Stores.View (O.Ref));

   function Is_Owned (O : Image_Owner) return Boolean
   is (Image_Stores.Is_Owned (O.Ref));

   procedure Release (O : in out Image_Owner) is
   begin
      Image_Stores.Release (O.Ref);
   end Release;

   ---------------------------------------------------------------------------
   -- Reclaim_Image
   ---------------------------------------------------------------------------

   procedure Reclaim_Image (Img : in out Image'Class) is
   begin
      if Img.Surface /= null then
         SDL_DestroySurface (Img.Surface);
         Img.Surface := null;
      end if;

      if Img.SVG /= null then
         Adi.SVG.Destroy (Img.SVG.all);
         Free_SVG_Document (Img.SVG);
      end if;

      Img.Width   := 0.0;
      Img.Height  := 0.0;
   end Reclaim_Image;

end Adi.Image;
