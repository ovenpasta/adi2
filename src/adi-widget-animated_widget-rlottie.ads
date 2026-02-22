with Adi.RLottie; use Adi.RLottie;

package Adi.Widget.Animated_Widget.RLottie is

   function Create
     (Animation : RLottie_Animation_Access) return Animated_Widget_Access;

   function Load_From_File
     (W    : in out Animated_Widget'Class;
      Path : String) return Boolean;

   procedure Set_Animation
     (W         : in out Animated_Widget'Class;
      Animation : RLottie_Animation_Access);

   function Get_Animation
     (W : Animated_Widget) return RLottie_Animation_Access;

end Adi.Widget.Animated_Widget.RLottie;
