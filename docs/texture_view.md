<!--
SPDX-FileCopyrightText: 2026 Aldo Nicolas Bruno
SPDX-License-Identifier: Apache-2.0
-->

# Texture view

`Adi.Widget.Texture_View` shows a surface the application drew itself —
with OpenGL, Direct3D, Vulkan, or a plain pixel buffer. Adi issues no
graphics-API call of its own and owns none of it. The application renders
on its own schedule, in its own task if it wants, names the surface it
finished, and the view blits it where the layout put the widget, under
the same clipping, z-order and opacity as any other widget.

That makes it the widget for anything Adi does not draw: a 3D viewport, a
video frame, an off-screen browser, a plotting library's output.

## Picking a renderer the texture can reach

A texture belongs to the API that made it, and SDL builds its renderer
with one API per platform: OpenGL is usual on Linux, Direct3D on Windows,
Metal on macOS. A GL texture cannot be handed to a D3D renderer.

Ask for a backend before the first window — SDL reads the hint when it
builds the renderer and ignores it afterwards — and then read back what
you were actually given rather than assuming:

```ada
Adi.Window.Prefer_Render_Driver ("opengl");   --  before any window
...
if Adi.Window.Render_Driver (W) /= Driver_Name (OpenGL) then
   --  The request was not granted. Fall back to Set_Pixels.
end if;
```

`Driver_Name (Backend)` gives the renderer name each backend answers to,
so the comparison does not hard-code a string.

This step does not apply to `Set_Pixels`, which works on every backend.

## Handing over a surface

### A texture you already own

`Set_Texture` adopts an existing GPU object. It comes in two shapes,
because the APIs name their objects differently:

```ada
--  OpenGL, GLES and Vulkan name a texture with an integer.
procedure Set_Texture (H       : Texture_View_Handle;
                       Backend : Backend_Kind;
                       Name    : Interfaces.Unsigned_64;
                       Width   : Natural;
                       Height  : Natural;
                       Format  : Texture_Format := RGBA;
                       Alpha   : Alpha_Kind := Straight;
                       Layout  : Interfaces.Unsigned_64 := 0)
  with Pre => Backend in OpenGL | OpenGLES2 | Vulkan;

--  Direct3D and the SDL GPU API hand over a pointer.
procedure Set_Texture (H       : Texture_View_Handle;
                       Backend : Backend_Kind;
                       Object  : System.Address;
                       Width   : Natural;
                       Height  : Natural;
                       Format  : Texture_Format := RGBA;
                       Alpha   : Alpha_Kind := Straight)
  with Pre => Backend in D3D11 | D3D12 | GPU;
```

`Layout` matters to Vulkan alone, where SDL needs to be told the image
layout it is being handed.

Metal is absent on purpose: SDL adopts a `CVPixelBufferRef` there rather
than a texture, which does not fit this shape.

### Pixels from the CPU

`Set_Pixels` copies a buffer into a texture the view owns and reuses. It
is the path that always works — no shared handle, no matching the
texture's API against the renderer's — and the only one where a backend
cannot adopt foreign objects at all.

```ada
procedure Set_Pixels (H      : Texture_View_Handle;
                      Data   : System.Address;
                      Width  : Natural;
                      Height : Natural;
                      Pitch  : Natural;
                      Format : Texture_Format := RGBA;
                      Alpha  : Alpha_Kind := Straight;
                      Region : Pixel_Region := Whole_Surface);
```

`Width` and `Height` describe the whole surface, whatever `Region` says.
`Region` names the part of it `Data` holds, and `Data` addresses that
part rather than the surface it belongs to: a producer sending a caret
sends the caret, and the rest of the surface keeps what it was last
given. A `Region` of no extent — `Whole_Surface` — stands for all of it.

Repainting only what changed is the point: a blinking caret is a few
hundred pixels, and the 4K surface holding it is thirty megabytes to
upload.

`Pitch` is the byte distance between rows of `Data`, which is not always
their width. The last row is read to its width and no further, so
`Pitch * (Rows - 1) + Columns * 4` bytes is enough — which is what a
producer with a tight last row allocates.

## Saying the contents changed

```ada
procedure Invalidate (H : Texture_View_Handle);
```

The view cannot notice on its own — the texture it holds is the same
object — and Adi composites only what it believes changed. A producer
redrawing every frame says so every frame, or the window keeps showing
the last frame it saw. `Set_Pixels` marks the region it wrote, so this is
for the shared-texture path.

## Releasing

```ada
procedure Clear_Texture (H : Texture_View_Handle);
```

The view falls back to its own background and border, and lets go of
every texture it made.

Letting go is also how an application says a handle is dead, and this is
the one rule worth reading twice. A view keeps the texture it wrapped a
handle in, keyed by everything it was told about it, so a producer
rotating a pool of shared textures does not pay a create and a destroy
every frame. A producer that frees a texture and is handed **the same
name or the same address back** for a new one — which both GL and the
D3D runtime do — would otherwise be given the wrapper for what used to be
there, and SDL would draw through a destroyed object. Call
`Clear_Texture` before you free.

## Format and alpha

```ada
type Texture_Format is (RGBA, BGRA, ARGB, ABGR);
type Alpha_Kind is (Straight, Premultiplied);
```

`Texture_Format` is byte order in memory, which is what a producer
actually knows about its own buffer. Naming it this way rather than by
packed word means the answer does not change with endianness: an
off-screen browser hands over BGRA whatever the machine.

`Alpha_Kind` says whether colour has already been scaled by its own
alpha. Compositing a premultiplied surface as if it were straight darkens
every antialiased edge, which reads as a coloured fringe on text.

## When nothing appears

```ada
function Last_Error (H : Texture_View_Handle) return String;
```

Empty once a texture has been shown. Otherwise it says why it could not
be: usually that the texture's API is not the one SDL built the renderer
with, and otherwise that an upload was refused. Neither draws anything on
its own, so this is the only account of it.

A description SDL refuses is not retried every frame — the view records
what failed, not when.

## In XML

The tag is `texture-view`, and the built-in grammar knows it, so a
generated UI needs no `--grammar` of its own:

```xml
<box class="frame">
  <texture-view id="View" class="gl"/>
</box>
```

It styles like any other widget. Backgrounds, borders and padding apply
around the blit; the blit itself is a plain rectangle, so a rounded
corner belongs on a parent box rather than on the view.

## Worked example

[`extras/opengl_demo`](../extras/opengl_demo) draws a spinning
tetrahedron with OpenGL into a texture it owns and shows it through a
texture view, with Adi widgets driving the rotation, size and colour.
It is a separate Alire crate, so the core library keeps no OpenGL
dependency.
