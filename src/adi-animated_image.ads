--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with System.Storage_Elements;
with Ada.Containers.Vectors;
with Adi.Core;       use Adi.Core;
with Adi.Image;      use Adi.Image;

package Adi.Animated_Image is

   type Animated_Image is tagged private;
   type Animated_Image_Access is access all Animated_Image'Class;

   --  Load all frames from an animated image (e.g. GIF/WebP) using SDL_image.
   --  Frames are loaded as SDL_Surface (CPU memory); GPU textures are created
   --  lazily on first render via Adi.Image.Get_Texture(Renderer).
   --  Returns null on failure.
   function Load_From_File (Path : String) return Animated_Image_Access;

   --  Load all frames from in-memory animated image data (e.g. GIF).
   --  The memory is fully consumed; the caller retains ownership of the buffer.
   --  Returns null on failure.
   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count)
      return Animated_Image_Access;

   --  True when at least one valid frame is loaded.
   function Is_Valid (Anim : Animated_Image) return Boolean;

   --  Dimensions reported by SDL_image for the animation canvas.
   procedure Get_Size
     (Anim   : Animated_Image;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);

   function Get_Frame_Count (Anim : Animated_Image) return Natural;
   function Get_Current_Frame_Index (Anim : Animated_Image) return Natural;
   function Get_Current_Image (Anim : Animated_Image) return Image_Access;

   --  Playback controls.
   procedure Start (Anim : in out Animated_Image);
   procedure Stop (Anim : in out Animated_Image);
   function Is_Playing (Anim : Animated_Image) return Boolean;

   procedure Set_Looping (Anim : in out Animated_Image; Value : Boolean := True);
   function Is_Looping (Anim : Animated_Image) return Boolean;

   procedure Reset (Anim : in out Animated_Image);

   --  Advance playback by DT seconds.
   --  Returns True when the current frame changed.
   function Advance
     (Anim : in out Animated_Image;
      DT   : Duration) return Boolean;

   --  Frees frame textures owned by this animation.
   procedure Destroy (Anim : in out Animated_Image);

private

   type Frame_Info is record
      Image    : Image_Access := null;
      Delay_MS : Natural := 100;
   end record;

   package Frame_Vectors is new Ada.Containers.Vectors (Positive, Frame_Info);

   type Animated_Image is tagged record
      Frames         : Frame_Vectors.Vector;
      Width          : Pixel_Type := 0.0;
      Height         : Pixel_Type := 0.0;
      Current_Frame  : Natural := 1;
      Elapsed_MS     : Float := 0.0;
      Playing        : Boolean := True;
      Looping        : Boolean := True;
   end record;

end Adi.Animated_Image;
