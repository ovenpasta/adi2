--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with System.Storage_Elements;
with Ada.Containers.Vectors;
with Adi.Core;       use Adi.Core;
with Adi.Clock;
with Adi.Handle_Store;
with Adi.Image;      use Adi.Image;
with Adi.Playback_Clock;
with Adi.Texture_Cache;

--  Every operation runs on the render thread and none is safe against
--  another running beside it. A handle is resolved within one call
--  rather than held, which keeps a destroy from cutting the ground out
--  from under a call in progress -- but only because the destroy cannot
--  be concurrent. Nothing pins a slot.
package Adi.Animated_Image is

   --  What callers hold. Generational, so every copy goes stale together
   --  when the animation is destroyed, and a slot reused by a later
   --  animation does not revive them.
   --
   type Animation_Handle is private;
   Null_Animation_Handle : constant Animation_Handle;

   --  Load all frames from an animated image (e.g. GIF/WebP) using
   --  SDL_image. Frames are loaded as SDL_Surface (CPU memory); GPU
   --  textures are created lazily on first render via
   --  Adi.Image.Acquire_Texture.
   --  A file that cannot be read or decoded is answered with a null
   --  handle. Anything else -- exhaustion, or a defect -- propagates,
   --  having reclaimed whatever had been built.
   function Load_From_File (Path : String) return Animation_Handle;

   --  Load all frames from in-memory animated image data (e.g. GIF).
   --  The memory is fully consumed; the caller retains ownership of the
   --  buffer. A null handle on failure, as above.
   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count)
      return Animation_Handle;

   --  True when at least one valid frame is loaded.
   function Is_Valid (H : Animation_Handle) return Boolean;

   --  Dimensions reported by SDL_image for the animation canvas.
   procedure Get_Size
     (H      : Animation_Handle;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);

   function Get_Frame_Count (H : Animation_Handle) return Natural;
   function Get_Current_Frame_Index
     (H : Animation_Handle) return Natural;

   --  A view of the frame to draw now, naming nothing when there is
   --  none. The animation owns its frames, so a copy kept past Destroy
   --  goes stale with them and draws nothing.
   function Get_Current_Image (H : Animation_Handle) return Image_Handle;

   --  Playback controls.
   procedure Start (H : Animation_Handle);
   procedure Stop (H : Animation_Handle);
   function Is_Playing (H : Animation_Handle) return Boolean;

   procedure Set_Looping
     (H : Animation_Handle; Value : Boolean := True);
   function Is_Looping (H : Animation_Handle) return Boolean;

   procedure Reset (H : Animation_Handle);

   --  Advance playback by DT seconds.
   --  Returns True when the current frame changed.
   function Advance
     (H : Animation_Handle; DT : Duration) return Boolean;

   --  Advance to an instant rather than by a span. Several widgets may
   --  draw one animation, and each stepping it by its own delta would
   --  run the single playhead at a multiple of its speed. Sampling means
   --  every viewer contributes only the time that passed.
   --
   --  Returns True when a new frame becomes visible, which is true for
   --  at most one viewer per step -- so a viewer cannot use it to decide
   --  whether to redraw. It compares the image it last drew instead.
   function Advance_At
     (H      : Animation_Handle;
      Sample : Adi.Clock.Time) return Boolean;

   --  Destroy the animation and reclaim it. Every copy of the handle
   --  goes stale together. Sets H to null; a null or stale handle is no
   --  work at all.
   --
   --  The frames go with it, so a render item still naming one is left
   --  with a stale handle and draws nothing. Widgets need not be
   --  detached first.
   --
   --  Call it on the render thread: it releases the texture group these
   --  frames belong to, which reaches into every renderer that drew
   --  them, and those caches belong to that thread.
   procedure Destroy (H : in out Animation_Handle);

private

   type Animated_Image;

   type Frame_Info is record
      Image    : Image_Owner := Null_Image_Owner;
      Delay_MS : Natural := 100;
   end record;

   package Frame_Vectors is new Ada.Containers.Vectors (Positive, Frame_Info);

   --  Limited: an animation owns its frames and the group their textures
   --  belong to. Callers work through handles; this is for the body and
   --  the children.
   type Animated_Image is tagged limited record
      Frames         : Frame_Vectors.Vector;
      Width          : Pixel_Type := 0.0;
      Height         : Pixel_Type := 0.0;
      Current_Frame  : Natural := 1;
      Elapsed_MS     : Float := 0.0;
      Playing        : Boolean := True;
      Looping        : Boolean := True;

      --  Every texture made from these frames, so destroying the
      --  animation takes them out of each renderer that drew them rather
      --  than leaving them to be evicted under pressure later.
      Group          : aliased Adi.Texture_Cache.Texture_Group;

      --  Where the sampled clock stands. Re-anchored whenever the
      --  timeline moves by any means other than sampling.
      Clock          : Adi.Playback_Clock.Clock_State;
   end record;

   --  The object-level operations. Callers use the handle versions;
   --  these are what those resolve to.
   function Is_Valid (Anim : Animated_Image) return Boolean;
   procedure Get_Size
     (Anim   : Animated_Image;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);
   function Get_Frame_Count (Anim : Animated_Image) return Natural;
   function Get_Current_Frame_Index (Anim : Animated_Image) return Natural;
   function Get_Current_Image (Anim : Animated_Image) return Image_Handle;
   procedure Start (Anim : in out Animated_Image);
   procedure Stop (Anim : in out Animated_Image);
   function Is_Playing (Anim : Animated_Image) return Boolean;
   procedure Set_Looping
     (Anim : in out Animated_Image; Value : Boolean := True);
   function Is_Looping (Anim : Animated_Image) return Boolean;
   procedure Reset (Anim : in out Animated_Image);
   function Advance
     (Anim : in out Animated_Image; DT : Duration) return Boolean;
   function Advance_At
     (Anim   : in out Animated_Image;
      Sample : Adi.Clock.Time) return Boolean;
   procedure Destroy (Anim : in out Animated_Image);

   type Animated_Image_Access is access all Animated_Image'Class;

   package Animation_Stores is new Adi.Handle_Store
     (Object_Type   => Animated_Image,
      Object_Access => Animated_Image_Access);

   type Animation_Handle is record
      Id : Animation_Stores.Object_Id := Animation_Stores.Null_Id;
   end record;
   Null_Animation_Handle : constant Animation_Handle :=
     (Id => Animation_Stores.Null_Id);

end Adi.Animated_Image;
