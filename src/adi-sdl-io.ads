--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;

package Adi.SDL.IO is

   ---------------------------------------------------------------------------
   --  Opaque Types
   ---------------------------------------------------------------------------

   type SDL_IOStream is limited null record;
   type SDL_IOStream_Ptr is access all SDL_IOStream;

   ---------------------------------------------------------------------------
   --  IO Stream from constant memory
   ---------------------------------------------------------------------------

   function SDL_IOFromConstMem
     (Mem  : System.Address;
      Size : size_t) return SDL_IOStream_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_IOFromConstMem";

   ---------------------------------------------------------------------------
   --  Close an IO stream
   ---------------------------------------------------------------------------

   function SDL_CloseIO
     (Context : SDL_IOStream_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CloseIO";

end Adi.SDL.IO;
