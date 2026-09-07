--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0



pragma Ada_2022;

with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;

package Adi.SDL.Surface is 

   SDL_SURFACE_PREALLOCATED : constant := 16#00000001#;
   SDL_SURFACE_LOCK_NEEDED : constant := 16#00000002#;
   SDL_SURFACE_LOCKED : constant := 16#00000004#;
   SDL_SURFACE_SIMD_ALIGNED : constant := 16#00000008#;

   SDL_PROP_SURFACE_SDR_WHITE_POINT_FLOAT : aliased constant String := "SDL.surface.SDR_white_point" & ASCII.NUL;
   SDL_PROP_SURFACE_HDR_HEADROOM_FLOAT : aliased constant String := "SDL.surface.HDR_headroom" & ASCII.NUL;
   SDL_PROP_SURFACE_TONEMAP_OPERATOR_STRING : aliased constant String := "SDL.surface.tonemap" & ASCII.NUL;
   SDL_PROP_SURFACE_HOTSPOT_X_NUMBER : aliased constant String := "SDL.surface.hotspot.x" & ASCII.NUL;
   SDL_PROP_SURFACE_HOTSPOT_Y_NUMBER : aliased constant String := "SDL.surface.hotspot.y" & ASCII.NUL;

  --  Simple DirectMedia Layer
  --  Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>
  --  This software is provided 'as-is', without any express or implied
  --  warranty.  In no event will the authors be held liable for any damages
  --  arising from the use of this software.
  --  Permission is granted to anyone to use this software for any purpose,
  --  including commercial applications, and to alter it and redistribute it
  --  freely, subject to the following restrictions:
  --  1. The origin of this software must not be misrepresented; you must not
  --     claim that you wrote the original software. If you use this software
  --     in a product, an acknowledgment in the product documentation would be
  --     appreciated but is not required.
  --  2. Altered source versions must be plainly marked as such, and must not be
  --     misrepresented as being the original software.
  --  3. This notice may not be removed or altered from any source distribution.
  -- 

   subtype SDL_SurfaceFlags is Uint32;

   subtype SDL_ScaleMode is int;
   SDL_ScaleMode_SDL_SCALEMODE_INVALID : constant SDL_ScaleMode := -1;
   SDL_ScaleMode_SDL_SCALEMODE_NEAREST : constant SDL_ScaleMode := 0;
   SDL_ScaleMode_SDL_SCALEMODE_LINEAR : constant SDL_ScaleMode := 1;

   type SDL_FlipMode is 
     (SDL_FLIP_NONE,
      SDL_FLIP_HORIZONTAL,
      SDL_FLIP_VERTICAL)
   with Convention => C;

  --  Pixel data is arranged in rows (top row first); pitch is the row stride in bytes, with trailing padding bytes of undefined content. YUV-format surfaces store planes contiguously with no padding between them; MJPG-format surfaces store compressed JPEG data directly in pixels, with pitch giving its length.

  --  Read-only.
   type SDL_Surface is record
      flags : aliased SDL_SurfaceFlags;
      format : aliased SDL_PixelFormat;
      w : aliased int;
      h : aliased int;
      pitch : aliased int;
      pixels : System.Address;
      refcount : aliased int;
      reserved : System.Address;
   end record
   with Convention => C_Pass_By_Copy;

   type SDL_Surface_Ptr is access all SDL_Surface;
   subtype SDL_Surface_Access is SDL_Surface_Ptr;


   function SDL_CreateSurface
     (width : int;
      height : int;
      format : SDL_PixelFormat) return access SDL_Surface
   with Import => True, 
        Convention => C, 
        External_Name => "SDL_CreateSurface";

   function SDL_DuplicateSurface
     (Surface : access SDL_Surface) return access SDL_Surface
      with Import => True,
           Convention => C,
           External_Name => "SDL_DuplicateSurface";

   procedure SDL_DestroySurface (Surface : access SDL_Surface)
      with Import => True,
           Convention => C,
           External_Name => "SDL_DestroySurface";

   function SDL_BlitSurface
     (src     : SDL_Surface_Ptr;
      srcrect : access constant SDL_Rect;
      dst     : SDL_Surface_Ptr;
      dstrect : access constant SDL_Rect) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_BlitSurface";

   --  One pixel as RGBA, whatever the surface's own format is.
   function SDL_ReadSurfacePixel
     (Surface    : SDL_Surface_Ptr;
      X, Y       : int;
      R, G, B, A : access Uint8) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_ReadSurfacePixel";

end Adi.SDL.Surface;
