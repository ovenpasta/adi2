with Adi.Render_Drivers; use Adi.Render_Drivers;

package Adi.Build_Target is
   type Platform_Kind is (Linux, macOS, Windows);
   Platform : constant Platform_Kind := Linux;

   --  The renderers SDL builds for this platform. Naming another is a
   --  compile-time warning, and an Assertion_Error with assertions on.
   subtype Render_Driver is Render_Driver_Kind
     with Static_Predicate =>
       Render_Driver in OpenGL | OpenGLES2 | Vulkan | GPU | Software;
end Adi.Build_Target;
