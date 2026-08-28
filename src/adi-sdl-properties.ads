--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C.Strings;
with System;

--  SDL's property groups. These are string-keyed bags SDL uses where a
--  call takes too many optional arguments to be a signature, most of them
--  backend-specific. Adi needs them for one thing: handing SDL a texture
--  object the application already created on the GPU.
package Adi.SDL.Properties is

   type SDL_PropertiesID is new Uint32;

   Invalid_Properties : constant SDL_PropertiesID := 0;

   function SDL_CreateProperties return SDL_PropertiesID
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateProperties";

   procedure SDL_DestroyProperties (Props : SDL_PropertiesID)
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_DestroyProperties";

   function SDL_SetNumberProperty
      (Props : SDL_PropertiesID;
       Name  : Interfaces.C.Strings.chars_ptr;
       Value : Sint64) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetNumberProperty";

   function SDL_GetNumberProperty
      (Props         : SDL_PropertiesID;
       Name          : Interfaces.C.Strings.chars_ptr;
       Default_Value : Sint64) return Sint64
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetNumberProperty";

   function SDL_SetPointerProperty
      (Props : SDL_PropertiesID;
       Name  : Interfaces.C.Strings.chars_ptr;
       Value : System.Address) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetPointerProperty";

   ---------------------------------------------------------------------------
   --  Property names
   ---------------------------------------------------------------------------

   --  Set on a group passed to SDL_CreateTextureWithProperties: adopt a
   --  texture the caller already made instead of allocating one. SDL
   --  reads the object but does not take it over -- SDL_DestroyTexture
   --  leaves it alive, so releasing it stays the caller's job.
   --
   --  Which key applies depends on the API the renderer was built with,
   --  and the handle is a number for GL, GLES and Vulkan but a pointer
   --  for Direct3D and the GPU API. Metal is deliberately absent: its
   --  property takes a CVPixelBufferRef rather than a texture, so it
   --  does not fit the same shape.
   Prop_Texture_Create_OpenGL_Texture_Number : constant String :=
     "SDL.texture.create.opengl.texture";
   Prop_Texture_Create_OpenGLES2_Texture_Number : constant String :=
     "SDL.texture.create.opengles2.texture";
   Prop_Texture_Create_Vulkan_Texture_Number : constant String :=
     "SDL.texture.create.vulkan.texture";
   Prop_Texture_Create_Vulkan_Layout_Number : constant String :=
     "SDL.texture.create.vulkan.layout";
   Prop_Texture_Create_D3D11_Texture_Pointer : constant String :=
     "SDL.texture.create.d3d11.texture";
   Prop_Texture_Create_D3D12_Texture_Pointer : constant String :=
     "SDL.texture.create.d3d12.texture";
   Prop_Texture_Create_GPU_Texture_Pointer : constant String :=
     "SDL.texture.create.gpu.texture";

   Prop_Texture_Create_Format_Number : constant String :=
     "SDL.texture.create.format";
   Prop_Texture_Create_Access_Number : constant String :=
     "SDL.texture.create.access";
   Prop_Texture_Create_Width_Number  : constant String :=
     "SDL.texture.create.width";
   Prop_Texture_Create_Height_Number : constant String :=
     "SDL.texture.create.height";

   --  Read back from an SDL-allocated texture, for the opposite direction:
   --  drawing into SDL's own texture with GL rather than handing SDL one.
   Prop_Texture_OpenGL_Texture_Number : constant String :=
     "SDL.texture.opengl.texture";

end Adi.SDL.Properties;
