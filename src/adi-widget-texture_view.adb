--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;
with Interfaces.C.Strings;
with System.Storage_Elements;
with Adi.Clock;
with Adi.SDL;
with Adi.SDL.Pixelformat;
with Adi.SDL.Properties;
with Adi.SDL.Render;

package body Adi.Widget.Texture_View is

   use Adi.SDL.Render;
   use Adi.Texture_Cache;
   use type Adi.Clock.Time;
   use type System.Address;
   use type Interfaces.Unsigned_64;

   procedure Free is new Ada.Unchecked_Deallocation
     (Byte_Array, Byte_Array_Access);

   procedure Free is new Ada.Unchecked_Deallocation
     (Texture_Group'Class, Texture_Group_Access);

   --  Empty rather than an exception when SDL has no name for it: this
   --  is only ever used to explain a failure.
   function Renderer_Name (Renderer : SDL_Renderer_Ptr) return String is
      use Interfaces.C.Strings;
      Name : constant chars_ptr := SDL_GetRendererName (Renderer);
   begin
      return (if Name = Null_Ptr then "" else Value (Name));
   end Renderer_Name;

   function SDL_Reason return String is
      use Interfaces.C.Strings;
      Message : constant chars_ptr := Adi.SDL.SDL_GetError;
   begin
      return (if Message = Null_Ptr then "" else Value (Message));
   end SDL_Reason;

   function To_SDL_Format (F : Texture_Format)
     return Adi.SDL.Pixelformat.SDL_PixelFormat
   is (case F is
          when RGBA => Adi.SDL.Pixelformat.SDL_PIXELFORMAT_RGBA32,
          when BGRA => Adi.SDL.Pixelformat.SDL_PIXELFORMAT_BGRA32,
          when ARGB => Adi.SDL.Pixelformat.SDL_PIXELFORMAT_ARGB32,
          when ABGR => Adi.SDL.Pixelformat.SDL_PIXELFORMAT_ABGR32);

   function To_Blend_Mode (A : Alpha_Kind) return SDL_BlendMode
   is (case A is
          when Straight      => SDL_BLENDMODE_BLEND,
          when Premultiplied => SDL_BLENDMODE_BLEND_PREMULTIPLIED);

   function Is_Empty (R : Pixel_Region) return Boolean
   is (R.Width = 0 or else R.Height = 0);

   --  The smallest region holding both, which is what one upload can
   --  take. Two distant repaints therefore carry the gap between them;
   --  the alternative is an upload each, and SDL charges a call for
   --  every one.
   function Union (A, B : Pixel_Region) return Pixel_Region is
   begin
      if Is_Empty (A) then
         return B;
      elsif Is_Empty (B) then
         return A;
      end if;

      declare
         X0 : constant Natural := Natural'Min (A.X, B.X);
         Y0 : constant Natural := Natural'Min (A.Y, B.Y);
         X1 : constant Natural := Natural'Max (A.X + A.Width, B.X + B.Width);
         Y1 : constant Natural := Natural'Max (A.Y + A.Height, B.Y + B.Height);
      begin
         return (X => X0, Y => Y0, Width => X1 - X0, Height => Y1 - Y0);
      end;
   end Union;

   ---------------------------------------------------------------------------
   --  Construction
   ---------------------------------------------------------------------------

   function Create return Texture_View_Access is
      Result : constant Texture_View_Access := new Texture_View_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   function Create_Handle return Texture_View_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   function To_Widget_Handle (H : Texture_View_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Texture_View (H : Widget_Handle)
     return Texture_View_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Texture_View_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Texture_View_Handle;
   end Try_As_Texture_View;

   function Is_Valid (H : Texture_View_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   -----------------
   -- Driver_Name --
   -----------------

   function Driver_Name (Backend : Backend_Kind) return String is
     (case Backend is
         when OpenGL     => "opengl",
         when OpenGLES2  => "opengles2",
         when Vulkan     => "vulkan",
         when D3D11      => "direct3d11",
         when D3D12      => "direct3d12",
         when GPU        => "gpu");

   ---------------------------------------------------------------------------
   --  What the cache holds for a view
   ---------------------------------------------------------------------------

   --  Let go of every texture made for this view, in every cache it has
   --  drawn through. A released group refuses later stores, so the next
   --  texture starts a new one.
   procedure Drop_Textures (W : in out Texture_View_Widget) is
   begin
      if W.Textures /= null then
         Release (Texture_Group (W.Textures.all));
         Free (W.Textures);
      end if;
   end Drop_Textures;

   --  Everything SDL was told about the texture, rather than only which
   --  handle it was. A producer uploading new dimensions under an
   --  unchanged GL name -- which is what a browser does on every resize
   --  -- would otherwise be handed a wrapper still declaring the old
   --  ones.
   function Cache_Key (W : Texture_View_Widget) return Texture_Key is
      Formats  : constant Natural :=
        Texture_Format'Pos (Texture_Format'Last) + 1;
      Backends : constant Natural :=
        Backend_Kind'Pos (Backend_Kind'Last) + 1;
      Id       : constant Widget_Stores.Object_Id := Get_Handle (W).Id;
   begin
      return
        (Kind       => View_Texture,
         Source     =>
           (case W.Source is
               when By_Name    => Source_Id (W.Name),
               when By_Pointer =>
                 Source_Id (System.Storage_Elements.To_Integer (W.Object)),
               --  Uploaded pixels are named by nothing of the
               --  application's, and two views uploading through one
               --  renderer must not share what they upload into.
               when others     =>
                 Source_Id (Id.Index) * 2 ** 32 + Source_Id (Id.Gen)),
         --  Vulkan alone reads a layout, and its values fit.
         Generation => Generation_Id (W.Layout and 16#FFFF_FFFF#),
         Extent_A   => W.Width,
         Extent_B   => W.Height,
         --  A name, an address and a view's own identity are all just
         --  numbers, so what kind of thing this one is goes in as well.
         Variant    =>
           (Handle_Source'Pos (W.Source) * Backends
            + Backend_Kind'Pos (W.Backend)) * Formats
           + Texture_Format'Pos (W.Format));
   end Cache_Key;

   ---------------------------------------------------------------------------
   --  Setting the source
   ---------------------------------------------------------------------------

   procedure Set_Texture (H       : Texture_View_Handle;
                          Backend : Backend_Kind;
                          Name    : Interfaces.Unsigned_64;
                          Width   : Natural;
                          Height  : Natural;
                          Format  : Texture_Format := RGBA;
                          Alpha   : Alpha_Kind := Straight;
                          Layout  : Interfaces.Unsigned_64 := 0)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr = null then
         return;
      end if;

      declare
         W : Texture_View_Widget renames Texture_View_Widget (Ptr.all);
      begin
         W.Source  := By_Name;
         W.Backend := Backend;
         W.Name    := Name;
         W.Layout  := Layout;
         W.Format  := Format;
         W.Alpha   := Alpha;
         W.Width   := Width;
         W.Height  := Height;
         W.Failed  := False;
         Mark_Dirty (W);
      end;
   end Set_Texture;

   procedure Set_Texture (H       : Texture_View_Handle;
                          Backend : Backend_Kind;
                          Object  : System.Address;
                          Width   : Natural;
                          Height  : Natural;
                          Format  : Texture_Format := RGBA;
                          Alpha   : Alpha_Kind := Straight)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr = null then
         return;
      end if;

      declare
         W : Texture_View_Widget renames Texture_View_Widget (Ptr.all);
      begin
         W.Source  := By_Pointer;
         W.Backend := Backend;
         W.Object  := Object;
         W.Format  := Format;
         W.Alpha   := Alpha;
         W.Width   := Width;
         W.Height  := Height;
         W.Failed  := False;
         Mark_Dirty (W);
      end;
   end Set_Texture;

   ----------------
   -- Set_Pixels --
   ----------------

   procedure Set_Pixels (H      : Texture_View_Handle;
                         Data   : System.Address;
                         Width  : Natural;
                         Height : Natural;
                         Pitch  : Natural;
                         Format : Texture_Format := RGBA;
                         Alpha  : Alpha_Kind := Straight;
                         Region : Pixel_Region := Whole_Surface)
   is
      use System.Storage_Elements;

      Ptr  : constant Widget_Access := Widget_Stores.Get (H.Id);
      Area : constant Pixel_Region :=
        (if Is_Empty (Region) then (0, 0, Width, Height) else Region);
      Row  : constant Natural := Area.Width * 4;
   begin
      if Ptr = null or else Data = System.Null_Address then
         return;
      end if;

      declare
         W     : Texture_View_Widget renames Texture_View_Widget (Ptr.all);
         Bytes : constant Natural := Width * Height * 4;
         --  A surface of another shape is another surface: what was
         --  copied into the last one describes nothing in this one.
         Fresh : constant Boolean :=
           W.Pixels = null or else W.Width /= Width or else W.Height /= Height;
      begin
         if Fresh then
            Free (W.Pixels);
            --  Zeroed, so a producer repainting part of a surface it has
            --  not filled yet uploads black rather than whatever the
            --  allocator last held.
            W.Pixels := new Byte_Array'(0 .. Bytes - 1 => 0);
         end if;

         --  Row by row, because the rows are Pitch apart and only their
         --  pixels are ours to read: a producer that allocates a tight
         --  last row has nothing at Pitch * Height, and this never asks
         --  for it.
         for R in 0 .. Area.Height - 1 loop
            declare
               Src : constant Byte_Array (0 .. Row - 1)
                 with Import, Address => Data + Storage_Offset (R * Pitch);
               At_Row : constant Natural :=
                 ((Area.Y + R) * Width + Area.X) * 4;
            begin
               W.Pixels (At_Row .. At_Row + Row - 1) := Src;
            end;
         end loop;

         W.Source := By_Pixels;
         W.Format := Format;
         W.Alpha  := Alpha;
         W.Width  := Width;
         W.Height := Height;
         W.Pending :=
           (if Fresh then (0, 0, Width, Height)
            elsif W.Pixels_New then Union (W.Pending, Area)
            else Area);
         W.Pixels_New := True;
         W.Failed     := False;
         Mark_Dirty (W);
      end;
   end Set_Pixels;

   procedure Clear_Texture (H : Texture_View_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr = null then
         return;
      end if;

      declare
         W : Texture_View_Widget renames Texture_View_Widget (Ptr.all);
      begin
         W.Source := No_Handle;
         W.Failed := False;
         Drop_Textures (W);
         Mark_Dirty (W);
      end;
   end Clear_Texture;

   procedure Invalidate (H : Texture_View_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Mark_Dirty (Ptr.all);
      end if;
   end Invalidate;

   function Last_Error (H : Texture_View_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr = null then
         return "";
      end if;
      return To_String (Texture_View_Widget (Ptr.all).Error);
   end Last_Error;

   ---------------------------------------------------------------------------
   --  Wrapping a foreign handle
   ---------------------------------------------------------------------------

   --  Present the application's texture to SDL as one of its own. SDL
   --  reads the object but does not adopt it, so destroying the result
   --  later leaves the original alone.
   function Wrap (W        : Texture_View_Widget;
                  Renderer : SDL_Renderer_Ptr) return SDL_Texture_Ptr
   is
      use Adi.SDL.Properties;
      use Interfaces.C.Strings;

      Props  : constant SDL_PropertiesID := SDL_CreateProperties;
      Result : SDL_Texture_Ptr;

      procedure Put_Number (Key : String; Value : Adi.SDL.Sint64) is
         C       : chars_ptr := New_String (Key);
         Ignored : Adi.SDL.C_bool;
      begin
         Ignored := SDL_SetNumberProperty (Props, C, Value);
         Free (C);
      end Put_Number;

      procedure Put_Pointer (Key : String; Value : System.Address) is
         C       : chars_ptr := New_String (Key);
         Ignored : Adi.SDL.C_bool;
      begin
         Ignored := SDL_SetPointerProperty (Props, C, Value);
         Free (C);
      end Put_Pointer;

   begin
      if Props = Invalid_Properties then
         return null;
      end if;

      case W.Source is
         when No_Handle | By_Pixels =>
            SDL_DestroyProperties (Props);
            return null;

         when By_Name =>
            Put_Number
              ((case W.Backend is
                   when OpenGL    => Prop_Texture_Create_OpenGL_Texture_Number,
                   when OpenGLES2 =>
                     Prop_Texture_Create_OpenGLES2_Texture_Number,
                   when others    => Prop_Texture_Create_Vulkan_Texture_Number),
               Adi.SDL.Sint64 (W.Name));
            if W.Backend = Vulkan then
               Put_Number (Prop_Texture_Create_Vulkan_Layout_Number,
                           Adi.SDL.Sint64 (W.Layout));
            end if;

         when By_Pointer =>
            Put_Pointer
              ((case W.Backend is
                   when D3D11  => Prop_Texture_Create_D3D11_Texture_Pointer,
                   when D3D12  => Prop_Texture_Create_D3D12_Texture_Pointer,
                   when others => Prop_Texture_Create_GPU_Texture_Pointer),
               W.Object);
      end case;

      Put_Number (Prop_Texture_Create_Format_Number,
                  Adi.SDL.Sint64 (To_SDL_Format (W.Format)));
      Put_Number (Prop_Texture_Create_Access_Number,
                  Adi.SDL.Sint64
                    (SDL_TextureAccess'Pos (SDL_TEXTUREACCESS_STATIC)));
      Put_Number (Prop_Texture_Create_Width_Number,
                  Adi.SDL.Sint64 (W.Width));
      Put_Number (Prop_Texture_Create_Height_Number,
                  Adi.SDL.Sint64 (W.Height));

      Result := SDL_CreateTextureWithProperties (Renderer, Props);
      SDL_DestroyProperties (Props);
      return Result;
   end Wrap;

   ---------------------------------------------------------------------------
   --  Rendering
   ---------------------------------------------------------------------------

   --  Send what has changed to the texture. The copy is packed, so the
   --  surface's own width is the pitch whichever part of it goes.
   procedure Upload (W     : in out Texture_View_Widget;
                     Tex   : SDL_Texture_Ptr;
                     Whole : Boolean)
   is
      Area  : constant Pixel_Region :=
        (if Whole then (0, 0, W.Width, W.Height) else W.Pending);
      Rect  : aliased constant Adi.SDL.SDL_Rect :=
        (x => Interfaces.C.int (Area.X),
         y => Interfaces.C.int (Area.Y),
         w => Interfaces.C.int (Area.Width),
         h => Interfaces.C.int (Area.Height));
      Full  : constant Boolean :=
        Area.X = 0 and then Area.Y = 0
        and then Area.Width = W.Width and then Area.Height = W.Height;
      First : constant Natural := (Area.Y * W.Width + Area.X) * 4;
      Sent  : Adi.SDL.C_bool;
   begin
      if W.Pixels = null or else Is_Empty (Area) then
         return;
      end if;

      if Fail_Next_Upload then
         Fail_Next_Upload := False;
         Sent := Adi.SDL.C_bool (False);
      else
         Sent := SDL_UpdateTexture
           (Tex,
            (if Full then null else Rect'Access),
            W.Pixels (First)'Address,
            Interfaces.C.int (W.Width * 4));
      end if;

      --  A failed upload leaves the frame pending. Dropping it would
      --  show the frame before this one for as long as the producer sent
      --  nothing else, and say nothing about why.
      if Sent then
         W.Pixels_New := False;
         W.Error      := Null_Unbounded_String;
      else
         W.Error := To_Unbounded_String
           ("could not upload pixels: " & SDL_Reason);
      end if;
   end Upload;

   --  Make the texture the current description asks for and hand it to
   --  the cache. A wrapper is charged nothing: the memory behind it is
   --  the application's, and the cache holds it only to save remaking it
   --  next frame.
   function Build (W   : in out Texture_View_Widget;
                   Ctx : in out Render_Context;
                   Key : Texture_Key) return Texture_Handle
   is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Started  : constant Adi.Clock.Time := Adi.Clock.Now;
      Tex      : SDL_Texture_Ptr;
      Charge   : Texture_Charge;
   begin
      if W.Source = By_Pixels then
         Tex := SDL_CreateTexture
           (Renderer,
            To_SDL_Format (W.Format),
            SDL_TEXTUREACCESS_STREAMING,
            Interfaces.C.int (W.Width),
            Interfaces.C.int (W.Height));

         if Tex = null then
            W.Error := To_Unbounded_String
              ("could not create a streaming texture: " & SDL_Reason);
            return Null_Texture;
         end if;

         --  All of it, whatever is pending: this texture has held none
         --  of the surface yet.
         Upload (W, Tex, Whole => True);
         Charge := Byte_Count (W.Width) * Byte_Count (W.Height) * 4;
      else
         Tex := Wrap (W, Renderer);

         if Tex = null then
            --  Nearly always the backend: SDL refuses a texture from an
            --  API it did not build the renderer with, and the only
            --  other symptom is an empty widget.
            W.Failed     := True;
            W.Failed_Key := Key;
            W.Error      := To_Unbounded_String
              ("could not adopt a " & Driver_Name (W.Backend)
               & " texture; the renderer is " & Renderer_Name (Renderer));
            return Null_Texture;
         end if;

         W.Error := Null_Unbounded_String;
         Charge  := 0;
      end if;

      if W.Textures = null then
         W.Textures := new Texture_Group;
      end if;

      declare
         Held : constant Texture_Handle := Adi.Render.Store_Texture
           (Ctx, Key, Tex,
            Width      => W.Width,
            Height     => W.Height,
            Bytes      => Charge,
            Build_Time => Adi.Clock.Now - Started,
            Group      => W.Textures);
      begin
         --  Refused, so the cache took no ownership and this texture is
         --  still ours. Dropping it costs a frame and the next one tries
         --  again, which beats drawing through something nothing will
         --  destroy.
         if not Adi.Render.Is_Valid_Texture (Ctx, Held) then
            SDL_DestroyTexture (Tex);
         end if;
         return Held;
      end;
   end Build;

   --  The entry for what is set now, built if the cache does not have
   --  it. The borrow pins it for the length of the draw, so an eviction
   --  in between defers rather than frees underneath it.
   function Resolve (W   : in out Texture_View_Widget;
                     Ctx : in out Render_Context;
                     Key : Texture_Key) return Texture_Ref
   is
      Held : Texture_Handle := Adi.Render.Find_Texture (Ctx, Key);
   begin
      if not Adi.Render.Is_Valid_Texture (Ctx, Held) then
         --  A description SDL has already refused is not tried again
         --  every frame; what failed is what it names.
         if W.Failed and then W.Failed_Key = Key then
            return Null_Borrow;
         end if;
         Held := Build (W, Ctx, Key);
      end if;

      return Adi.Render.Borrow_Texture (Ctx, Held);
   end Resolve;

   procedure Draw (W        : Texture_View_Widget;
                   Renderer : SDL_Renderer_Ptr;
                   Tex      : SDL_Texture_Ptr;
                   Geom     : Rectangle)
   is
      Dst    : aliased constant Adi.SDL.SDL_FRect :=
        (x => Float (Geom.X),
         y => Float (Geom.Y),
         w => Float (Geom.Width),
         h => Float (Geom.Height));
      Fade   : constant Float :=
        Float (Get_Resolved_Part_Style (W, Main_Part).Opacity);
      --  Premultiplied colour carries its own alpha, so scaling the
      --  alpha alone leaves the colour above it: rgb <= a stops holding,
      --  and lowering opacity brightens the surface instead of fading
      --  it. Straight colour does not carry its alpha and is left as it
      --  is, which also untints a view that has changed modes.
      Tint   : constant Float :=
        (if W.Alpha = Premultiplied then Fade else 1.0);
      Unused : Adi.SDL.C_bool;
   begin
      Unused := SDL_SetTextureBlendMode (Tex, To_Blend_Mode (W.Alpha));
      Unused := SDL_SetTextureAlphaModFloat (Tex, Fade);
      Unused := SDL_SetTextureColorModFloat (Tex, Tint, Tint, Tint);
      Unused := SDL_RenderTexture (Renderer, Tex, null, Dst'Access);
   end Draw;

   overriding procedure Render_Content
     (W    : in out Texture_View_Widget;
      Ctx  : in out Render_Context;
      Area : Rectangle)
   is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
   begin
      --  Background, border and shadow from CSS; the texture goes over
      --  them.
      Render_Items (W, Ctx);

      if Renderer = null
        or else W.Source = No_Handle
        or else not Has_Visible_Area (Area)
      then
         return;
      end if;

      declare
         Key : constant Texture_Key := Cache_Key (W);
         Ref : constant Texture_Ref := Resolve (W, Ctx, Key);
      begin
         if Ref.Texture = null then
            return;
         end if;

         if W.Source = By_Pixels and then W.Pixels_New then
            Upload (W, Ref.Texture, Whole => False);
         end if;

         Draw (W, Renderer, Ref.Texture, Area);
      end;
   end Render_Content;

   overriding procedure On_Destroy (W : in out Texture_View_Widget) is
   begin
      Drop_Textures (W);
      Free (W.Pixels);
   end On_Destroy;

end Adi.Widget.Texture_View;
