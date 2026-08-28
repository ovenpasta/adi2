--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with Interfaces;
with Ada.Strings.Unbounded;
with Adi.Texture_Cache;

--  A widget that shows a texture the application drew on the GPU.
--
--  Adi issues no graphics-API call of its own and owns nothing: the
--  application renders on its own schedule -- in its own task if it
--  wants -- names the texture it finished, and the view blits it where
--  the layout put the widget, under the same clipping, z-order and
--  opacity as any other widget.
--
--  The texture must come from the API SDL built the renderer with, which
--  is not the same everywhere: OpenGL is usual on Linux, Direct3D on
--  Windows and Metal on macOS. Ask for one with
--  Adi.Window.Prefer_Render_Driver and read back
--  Adi.Window.Render_Driver rather than assuming it was granted.
package Adi.Widget.Texture_View is

   type Texture_View_Widget is new Widget with private;
   type Texture_View_Handle is private;

   Null_Texture_View_Handle : constant Texture_View_Handle;

   function Create_Handle return Texture_View_Handle;
   function Is_Valid (H : Texture_View_Handle) return Boolean;
   function To_Widget_Handle (H : Texture_View_Handle) return Widget_Handle;
   function "+" (H : Texture_View_Handle) return Widget_Handle
     renames To_Widget_Handle;
   function Try_As_Texture_View (H : Widget_Handle)
     return Texture_View_Handle;

   --  Metal is absent on purpose: SDL adopts a CVPixelBufferRef there
   --  rather than a texture, so it does not fit this shape.
   type Backend_Kind is (OpenGL, OpenGLES2, Vulkan, D3D11, D3D12, GPU);

   --  The renderer name each backend answers to, for comparing against
   --  Adi.Window.Render_Driver.
   function Driver_Name (Backend : Backend_Kind) return String;

   --  Byte order in memory, which is what a producer actually knows
   --  about its own buffer. Named this way rather than by packed word so
   --  the answer does not change with endianness: an off-screen browser
   --  hands over BGRA whatever the machine.
   type Texture_Format is (RGBA, BGRA, ARGB, ABGR);

   --  Whether colour has already been scaled by its own alpha.
   --  Compositing a premultiplied surface as if it were straight darkens
   --  every antialiased edge, which reads as a coloured fringe on text.
   type Alpha_Kind is (Straight, Premultiplied);

   --  OpenGL, GLES and Vulkan name a texture with an integer. Layout
   --  applies to Vulkan alone, where SDL needs to know the image layout
   --  it is being handed.
   procedure Set_Texture (H       : Texture_View_Handle;
                          Backend : Backend_Kind;
                          Name    : Interfaces.Unsigned_64;
                          Width   : Natural;
                          Height  : Natural;
                          Format  : Texture_Format := RGBA;
                          Alpha   : Alpha_Kind := Straight;
                          Layout  : Interfaces.Unsigned_64 := 0)
     with Pre => Backend in OpenGL | OpenGLES2 | Vulkan;

   --  Direct3D and the SDL GPU API hand over a pointer instead.
   procedure Set_Texture (H       : Texture_View_Handle;
                          Backend : Backend_Kind;
                          Object  : System.Address;
                          Width   : Natural;
                          Height  : Natural;
                          Format  : Texture_Format := RGBA;
                          Alpha   : Alpha_Kind := Straight)
     with Pre => Backend in D3D11 | D3D12 | GPU;

   --  A rectangle of the surface, in pixels. A producer repaints what
   --  changed rather than everything: a caret blinking in a document is
   --  a few hundred pixels, and the 4K surface holding it is thirty
   --  megabytes to upload.
   type Pixel_Region is record
      X, Y          : Natural := 0;
      Width, Height : Natural := 0;
   end record;

   --  A region of no extent stands for the whole surface.
   Whole_Surface : constant Pixel_Region := (others => 0);

   --  Pixels from the CPU, copied into a texture the view owns and
   --  reuses. The path that always works: no shared handle, no matching
   --  of the texture's API against the renderer's, and the only one
   --  available where a backend cannot adopt foreign objects at all.
   --
   --  Width and Height describe the whole surface, whatever Region says.
   --  Region names the part of it Data holds, and Data addresses that
   --  part rather than the surface it belongs to: a producer sending a
   --  caret sends the caret. The rest of the surface keeps what it was
   --  last given.
   --
   --  Pitch is the byte distance between the rows of Data, which is not
   --  always their width. The last row is read to its width and no
   --  further, so a buffer holding Pitch * (Rows - 1) + Columns * 4
   --  bytes is enough -- which is what a producer with a tight last row
   --  allocates.
   procedure Set_Pixels (H      : Texture_View_Handle;
                         Data   : System.Address;
                         Width  : Natural;
                         Height : Natural;
                         Pitch  : Natural;
                         Format : Texture_Format := RGBA;
                         Alpha  : Alpha_Kind := Straight;
                         Region : Pixel_Region := Whole_Surface)
     with Pre => Width > 0 and then Height > 0
                 and then Region.X + Region.Width <= Width
                 and then Region.Y + Region.Height <= Height
                 and then Pitch >= 4 * (if Region.Width = 0
                                        then Width else Region.Width);

   --  Show nothing but the widget's own background and border, and let
   --  go of every texture this view has made.
   --
   --  Letting go is also how an application says a handle is dead. A
   --  view keeps the texture it wrapped a handle in, keyed by everything
   --  it was told about it, so that a producer rotating a pool of shared
   --  textures does not pay a create and a destroy every frame. A
   --  producer that frees a texture and is handed the same name or the
   --  same address back for a new one -- which both GL and the D3D
   --  runtime do -- would otherwise be given the wrapper for what used
   --  to be there, and SDL would draw through a destroyed object.
   procedure Clear_Texture (H : Texture_View_Handle);

   --  The contents changed. The view cannot notice on its own -- the
   --  texture it was given is the same one -- and Adi composites only
   --  what it believes changed, so a producer redrawing every frame says
   --  so every frame or the window keeps showing the last one it saw.
   procedure Invalidate (H : Texture_View_Handle);

   --  Empty once a texture has been shown. Otherwise why it could not
   --  be: usually that the texture's API is not the one SDL built the
   --  renderer with, and otherwise that an upload was refused. Either
   --  draws nothing on its own, so this is the only account of it.
   function Last_Error (H : Texture_View_Handle) return String;

private

   type Handle_Source is (No_Handle, By_Name, By_Pointer, By_Pixels);

   --  Set by Adi.Widget.Texture_View.Testing to fail one upload. SDL
   --  refuses no well-formed one, and what a refusal leaves behind --
   --  the frame still pending, the reason reported -- is the part worth
   --  pinning.
   Fail_Next_Upload : Boolean := False;

   type Byte_Array is
     array (Natural range <>) of Interfaces.Unsigned_8;
   type Byte_Array_Access is access Byte_Array;

   type Texture_View_Widget is new Widget with record
      Source  : Handle_Source := No_Handle;
      Backend : Backend_Kind := OpenGL;
      Format  : Texture_Format := RGBA;
      Alpha   : Alpha_Kind := Straight;
      Name    : Interfaces.Unsigned_64 := 0;
      Layout  : Interfaces.Unsigned_64 := 0;
      Object  : System.Address := System.Null_Address;
      Width   : Natural := 0;
      Height  : Natural := 0;

      --  Textures made for this view, in every renderer's cache it has
      --  drawn through. They share a lifetime because they all describe
      --  the same handle: releasing the group is what Clear_Texture and
      --  destruction each amount to.
      Textures : Adi.Texture_Cache.Texture_Group_Access := null;

      --  Set_Pixels copies rather than keeping the caller's pointer: the
      --  renderer is only in hand during Render_Content, and a paint
      --  buffer is rarely still alive by then. Packed at Width * 4
      --  whatever the source pitch was, so an upload can name a
      --  sub-rectangle of it and SDL can read the rows from here.
      Pixels     : Byte_Array_Access := null;
      Pixels_New : Boolean := False;
      --  What has changed since the last upload: the union of the
      --  regions given, since several paints may reach the renderer as
      --  one frame.
      Pending    : Pixel_Region := Whole_Surface;

      --  The description SDL refused to adopt, so an impossible one is
      --  not attempted again every frame. What failed is what it names,
      --  not when it was asked.
      Failed     : Boolean := False;
      Failed_Key : Adi.Texture_Cache.Texture_Key;

      Error   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   overriding procedure Build_Items (W : in out Texture_View_Widget) is null;
   overriding procedure Layout (W : in out Texture_View_Widget) is null;

   overriding procedure Render_Content
     (W    : in out Texture_View_Widget;
      Ctx  : in out Render_Context;
      Area : Rectangle);

   overriding procedure On_Destroy (W : in out Texture_View_Widget);

   type Texture_View_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;

   Null_Texture_View_Handle : constant Texture_View_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Texture_View_Access is access all Texture_View_Widget'Class;

end Adi.Widget.Texture_View;
