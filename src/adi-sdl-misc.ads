--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Interfaces.C.Strings;

package Adi.SDL.Misc is

   ---------------------------------------------------------------------------
   --  Functions
   ---------------------------------------------------------------------------

   function SDL_OpenURL
     (URL : Interfaces.C.Strings.chars_ptr) return C_bool
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_OpenURL";

end Adi.SDL.Misc;
