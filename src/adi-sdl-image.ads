--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C.Strings;
with System;
with Adi.SDL;         use Adi.SDL;
with Adi.SDL.IO;      use Adi.SDL.IO;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SDL.Render;  use Adi.SDL.Render;

package Adi.SDL.Image is

   -- Version constants
   SDL_IMAGE_MAJOR_VERSION : constant := 3;
   SDL_IMAGE_MINOR_VERSION : constant := 2;
   SDL_IMAGE_MICRO_VERSION : constant := 4;

   ----------------------------------------------------------------------------
   -- Initialization and Version
   ----------------------------------------------------------------------------

   function IMG_Version return int
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_Version";

   ----------------------------------------------------------------------------
   -- Loading Images
   ----------------------------------------------------------------------------

   -- Load an image from a file path
   function IMG_Load
      (file : Interfaces.C.Strings.chars_ptr) return SDL_Surface_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_Load";

   -- Load an image directly as a texture for a renderer
   function IMG_LoadTexture
      (renderer : SDL_Renderer_Ptr;
       file     : Interfaces.C.Strings.chars_ptr) return SDL_Texture_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_LoadTexture";

   -- Load an image from an IO stream
   function IMG_Load_IO
      (Src     : SDL_IOStream_Ptr;
       Closeio : C_bool) return SDL_Surface_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_Load_IO";

   ----------------------------------------------------------------------------
   -- Format Detection
   ----------------------------------------------------------------------------

   -- These functions are provided but require SDL_IOStream
   -- Uncomment if needed in the future

   -- function IMG_isPNG (src : SDL_IOStream_Access) return C_bool
   --    with Import        => True,
   --         Convention    => C,
   --         External_Name => "IMG_isPNG";

   -- function IMG_isJPG (src : SDL_IOStream_Access) return C_bool
   --    with Import        => True,
   --         Convention    => C,
   --         External_Name => "IMG_isJPG";

   -- function IMG_isBMP (src : SDL_IOStream_Access) return C_bool
   --    with Import        => True,
   --         Convention    => C,
   --         External_Name => "IMG_isBMP";

   -- function IMG_isGIF (src : SDL_IOStream_Access) return C_bool
   --    with Import        => True,
   --         Convention    => C,
   --         External_Name => "IMG_isGIF";

   -- function IMG_isWEBP (src : SDL_IOStream_Access) return C_bool
   --    with Import        => True,
   --         Convention    => C,
   --         External_Name => "IMG_isWEBP";

   -- function IMG_isSVG (src : SDL_IOStream_Access) return C_bool
   --    with Import        => True,
   --         Convention    => C,
   --         External_Name => "IMG_isSVG";

   ----------------------------------------------------------------------------
   -- Saving Images
   ----------------------------------------------------------------------------

   function IMG_SavePNG
      (surface : SDL_Surface_Ptr;
       file    : Interfaces.C.Strings.chars_ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_SavePNG";

   function IMG_SaveJPG
      (surface : SDL_Surface_Ptr;
       file    : Interfaces.C.Strings.chars_ptr;
       quality : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_SaveJPG";

   function IMG_SaveAVIF
      (surface : SDL_Surface_Ptr;
       file    : Interfaces.C.Strings.chars_ptr;
       quality : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_SaveAVIF";

   ----------------------------------------------------------------------------
   -- Animation Support
   ----------------------------------------------------------------------------

   type IMG_Animation is record
      w      : aliased int;
      h      : aliased int;
      count  : aliased int;
      frames : System.Address;  -- Array of SDL_Surface pointers
      delays : access int;       -- Array of frame delays in ms
   end record with Convention => C_Pass_By_Copy;

   type IMG_Animation_Access is access all IMG_Animation;

   function IMG_LoadAnimation
      (file : Interfaces.C.Strings.chars_ptr) return IMG_Animation_Access
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_LoadAnimation";

   function IMG_LoadAnimation_IO
      (Src     : SDL_IOStream_Ptr;
       Closeio : C_bool) return IMG_Animation_Access
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_LoadAnimation_IO";

   procedure IMG_FreeAnimation
      (anim : IMG_Animation_Access)
      with Import        => True,
           Convention    => C,
           External_Name => "IMG_FreeAnimation";

end Adi.SDL.Image;
