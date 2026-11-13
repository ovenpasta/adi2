--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;

--  SDL's 2D renderers. Adi.Build_Target.Render_Driver narrows the type to
--  the ones SDL builds for the platform; Adi.Window takes that subtype.
package Adi.Render_Drivers is

   --  Every renderer SDL 3.2 builds on a desktop platform. SDL's hint
   --  documentation also lists "opengles", which SDL 3 no longer has.
   type Render_Driver_Kind is
     (Direct3D,     --  Direct3D 9
      Direct3D11,
      Direct3D12,
      Metal,
      OpenGL,
      OpenGLES2,
      Vulkan,
      GPU,          --  SDL's GPU API, over Vulkan, Direct3D 12 or Metal
      Software);

   --  The name SDL's render-driver hint and SDL_GetRendererName use:
   --  the literal, lowercased
   function Name (Driver : Render_Driver_Kind) return String is
     (Ada.Characters.Handling.To_Lower (Driver'Image));

end Adi.Render_Drivers;
