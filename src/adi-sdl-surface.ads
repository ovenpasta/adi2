--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0



with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;

package Adi.SDL.Surface is 

   SDL_SURFACE_PREALLOCATED : constant := 16#00000001#;  --  /usr/include/SDL3/SDL_surface.h:66
   SDL_SURFACE_LOCK_NEEDED : constant := 16#00000002#;  --  /usr/include/SDL3/SDL_surface.h:67
   SDL_SURFACE_LOCKED : constant := 16#00000004#;  --  /usr/include/SDL3/SDL_surface.h:68
   SDL_SURFACE_SIMD_ALIGNED : constant := 16#00000008#;  --  /usr/include/SDL3/SDL_surface.h:69
   --  arg-macro: function SDL_MUSTLOCK (S)
   --    return ((S).flags and SDL_SURFACE_LOCK_NEEDED) = SDL_SURFACE_LOCK_NEEDED;

   SDL_PROP_SURFACE_SDR_WHITE_POINT_FLOAT : aliased constant String := "SDL.surface.SDR_white_point" & ASCII.NUL;  --  /usr/include/SDL3/SDL_surface.h:249
   SDL_PROP_SURFACE_HDR_HEADROOM_FLOAT : aliased constant String := "SDL.surface.HDR_headroom" & ASCII.NUL;  --  /usr/include/SDL3/SDL_surface.h:250
   SDL_PROP_SURFACE_TONEMAP_OPERATOR_STRING : aliased constant String := "SDL.surface.tonemap" & ASCII.NUL;  --  /usr/include/SDL3/SDL_surface.h:251
   SDL_PROP_SURFACE_HOTSPOT_X_NUMBER : aliased constant String := "SDL.surface.hotspot.x" & ASCII.NUL;  --  /usr/include/SDL3/SDL_surface.h:252
   SDL_PROP_SURFACE_HOTSPOT_Y_NUMBER : aliased constant String := "SDL.surface.hotspot.y" & ASCII.NUL;  --  /usr/include/SDL3/SDL_surface.h:253

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

  --*
  -- * # CategorySurface
  -- *
  -- * SDL surfaces are buffers of pixels in system RAM. These are useful for
  -- * passing around and manipulating images that are not stored in GPU memory.
  -- *
  -- * SDL_Surface makes serious efforts to manage images in various formats, and
  -- * provides a reasonable toolbox for transforming the data, including copying
  -- * between surfaces, filling rectangles in the image data, etc.
  -- *
  -- * There is also a simple .bmp loader, SDL_LoadBMP(). SDL itself does not
  -- * provide loaders for various other file formats, but there are several
  -- * excellent external libraries that do, including its own satellite library,
  -- * SDL_image:
  -- *
  -- * https://github.com/libsdl-org/SDL_image
  --  

  -- Set up for C function definitions, even when using C++  
  --*
  -- * The flags on an SDL_Surface.
  -- *
  -- * These are generally considered read-only.
  -- *
  -- * \since This datatype is available since SDL 3.2.0.
  --  

   subtype SDL_SurfaceFlags is Uint32;  -- /usr/include/SDL3/SDL_surface.h:64

  --*
  -- * Evaluates to true if the surface needs to be locked before access.
  -- *
  -- * \since This macro is available since SDL 3.2.0.
  --  

  --*
  -- * The scaling mode.
  -- *
  -- * \since This enum is available since SDL 3.2.0.
  --  

   subtype SDL_ScaleMode is int;
   SDL_ScaleMode_SDL_SCALEMODE_INVALID : constant SDL_ScaleMode := -1;
   SDL_ScaleMode_SDL_SCALEMODE_NEAREST : constant SDL_ScaleMode := 0;
   SDL_ScaleMode_SDL_SCALEMODE_LINEAR : constant SDL_ScaleMode := 1;  -- /usr/include/SDL3/SDL_surface.h:83

  --*< nearest pixel sampling  
  --*< linear filtering  
  --*
  -- * The flip mode.
  -- *
  -- * \since This enum is available since SDL 3.2.0.
  --  

   type SDL_FlipMode is 
     (SDL_FLIP_NONE,
      SDL_FLIP_HORIZONTAL,
      SDL_FLIP_VERTICAL)
   with Convention => C;  -- /usr/include/SDL3/SDL_surface.h:95

  --*< Do not flip  
  --*< flip horizontally  
  --*< flip vertically  
  --*
  -- * A collection of pixels used in software blitting.
  -- *
  -- * Pixels are arranged in memory in rows, with the top row first. Each row
  -- * occupies an amount of memory given by the pitch (sometimes known as the row
  -- * stride in non-SDL APIs).
  -- *
  -- * Within each row, pixels are arranged from left to right until the width is
  -- * reached. Each pixel occupies a number of bits appropriate for its format,
  -- * with most formats representing each pixel as one or more whole bytes (in
  -- * some indexed formats, instead multiple pixels are packed into each byte),
  -- * and a byte order given by the format. After encoding all pixels, any
  -- * remaining bytes to reach the pitch are used as padding to reach a desired
  -- * alignment, and have undefined contents.
  -- *
  -- * When a surface holds YUV format data, the planes are assumed to be
  -- * contiguous without padding between them, e.g. a 32x32 surface in NV12
  -- * format with a pitch of 32 would consist of 32x32 bytes of Y plane followed
  -- * by 32x16 bytes of UV plane.
  -- *
  -- * When a surface holds MJPG format data, pixels points at the compressed JPEG
  -- * image and pitch is the length of that data.
  -- *
  -- * \since This struct is available since SDL 3.2.0.
  -- *
  -- * \sa SDL_CreateSurface
  -- * \sa SDL_DestroySurface
  --  

  --*< The flags of the surface, read-only  
   type SDL_Surface is record
      flags : aliased SDL_SurfaceFlags;  -- /usr/include/SDL3/SDL_surface.h:134
      format : aliased SDL_PixelFormat;  -- /usr/include/SDL3/SDL_surface.h:135
      w : aliased int;  -- /usr/include/SDL3/SDL_surface.h:136
      h : aliased int;  -- /usr/include/SDL3/SDL_surface.h:137
      pitch : aliased int;  -- /usr/include/SDL3/SDL_surface.h:138
      pixels : System.Address;  -- /usr/include/SDL3/SDL_surface.h:139
      refcount : aliased int;  -- /usr/include/SDL3/SDL_surface.h:141
      reserved : System.Address;  -- /usr/include/SDL3/SDL_surface.h:143
   end record
   with Convention => C_Pass_By_Copy;  -- /usr/include/SDL3/SDL_surface.h:132

   type SDL_Surface_Ptr is access all SDL_Surface;
   subtype SDL_Surface_Access is SDL_Surface_Ptr;


   function SDL_CreateSurface
     (width : int;
      height : int;
      format : SDL_PixelFormat) return access SDL_Surface  -- /usr/include/SDL3/SDL_surface.h:167
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

end Adi.SDL.Surface;