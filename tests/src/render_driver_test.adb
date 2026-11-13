--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.Build_Target;  use Adi.Build_Target;
with Adi.Render_Drivers; use Adi.Render_Drivers;
with Adi.SDL;           use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Window;
with Test_Support;      use Test_Support;

--  Prefer_Render_Driver under SDL's dummy video driver, which can build
--  the software renderer and nothing else
procedure Render_Driver_Test is

   --  The renderer a window created now gets
   function Driver_Of_New_Window return String is
      W : Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Render Driver Probe", (200.0, 100.0));
   begin
      return Name : constant String := Adi.Window.Render_Driver (W) do
         Adi.Window.Destroy (W);
      end return;
   end Driver_Of_New_Window;

   procedure Test_Names is
   begin
      Section ("SDL's names");
      Assert (Name (Direct3D) = "direct3d", "Direct3D");
      Assert (Name (Direct3D11) = "direct3d11", "Direct3D11");
      Assert (Name (Direct3D12) = "direct3d12", "Direct3D12");
      Assert (Name (Metal) = "metal", "Metal");
      Assert (Name (OpenGL) = "opengl", "OpenGL");
      Assert (Name (OpenGLES2) = "opengles2", "OpenGLES2");
      Assert (Name (Vulkan) = "vulkan", "Vulkan");
      Assert (Name (GPU) = "gpu", "GPU");
      Assert (Name (Software) = "software", "Software");
   end Test_Names;

   procedure Test_Platform_Drivers is
      --  Platform is static, so on any one platform some of these
      --  conditions are known at compile time
      pragma Warnings (Off, "condition is always*");
      function Allowed (D : Render_Driver_Kind) return Boolean is
        (D in Adi.Build_Target.Render_Driver);
   begin
      Section ("drivers this platform admits");
      Assert (Allowed (OpenGL) and then Allowed (OpenGLES2)
                and then Allowed (Vulkan) and then Allowed (GPU)
                and then Allowed (Software),
              "the portable drivers are admitted everywhere");
      Assert (Allowed (Metal) = (Platform = macOS),
              "Metal only on macOS");
      Assert (Allowed (Direct3D) = (Platform = Windows)
                and then Allowed (Direct3D11) = (Platform = Windows)
                and then Allowed (Direct3D12) = (Platform = Windows),
              "Direct3D only on Windows");
   end Test_Platform_Drivers;

   procedure Test_Preferences is
   begin
      Section ("preferences");

      Adi.Window.Prefer_Render_Driver (Software);
      Assert (Driver_Of_New_Window = "software",
              "a driver that can be built is used");

      Adi.Window.Prefer_Render_Driver ([OpenGL, Software]);
      Assert (Driver_Of_New_Window = "software",
              "the first of a list that can be built is used");

      Adi.Window.Prefer_Render_Driver (OpenGL);
      Assert (Driver_Of_New_Window = "software",
              "a driver that cannot be built falls back to SDL's default");
      Assert (Driver_Of_New_Window = "software",
              "after a fallback the next window has SDL's default");

      Adi.Window.Prefer_Render_Driver ([Vulkan, OpenGL]);
      Assert (Driver_Of_New_Window = "software",
              "so does a list of which none can be built");
   end Test_Preferences;

begin
   Start_Suite ("Render Driver Test");

   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   if not Boolean (SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS))
     or else not Boolean (Adi.SDL.TTF.TTF_Init)
   then
      Assert (False, "SDL and SDL_ttf initialise");
      Finish;
      return;
   end if;

   Test_Names;
   Test_Platform_Drivers;
   Test_Preferences;

   Finish;
end Render_Driver_Test;
