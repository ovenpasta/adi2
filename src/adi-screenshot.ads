--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.SDL.Render; use Adi.SDL.Render;

package Adi.Screenshot is

   --  Captures the renderer to a PNG file at Path; raises Program_Error on failure.
   procedure Capture
     (Renderer : SDL_Renderer_Ptr;
      Path     : String);

end Adi.Screenshot;
