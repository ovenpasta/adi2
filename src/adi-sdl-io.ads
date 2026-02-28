with System;
with Interfaces.C; use Interfaces.C;
with Adi.SDL;      use Adi.SDL;

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
