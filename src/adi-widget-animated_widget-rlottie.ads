with Adi.RLottie;    use Adi.RLottie;
with Adi.SDL.Render; use Adi.SDL.Render;

package Adi.Widget.Animated_Widget.RLottie is

   function Create
     (Animation : RLottie_Animation_Access) return Animated_Widget_Access;

   function Load_From_File
     (W        : in out Animated_Widget'Class;
      Renderer : SDL_Renderer_Ptr;
      Path     : String;
      Backend  : RLottie_Backend_Kind := Primitive_Backend) return Boolean;

   procedure Set_Animation
     (W         : in out Animated_Widget'Class;
      Animation : RLottie_Animation_Access);

   function Get_Animation
     (W : Animated_Widget) return RLottie_Animation_Access;

end Adi.Widget.Animated_Widget.RLottie;
