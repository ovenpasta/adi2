--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Animated_Image;
with Adi.RLottie; use Adi.RLottie;

package Adi.Widget.Animated_Widget.RLottie is

   --  Construction
   function Create_Handle
     (Animation : Adi.RLottie.Animation_Handle) return Animated_Widget_Handle;

   procedure Set_Animation
     (W         : in out Animated_Widget'Class;
      Animation : Adi.RLottie.Animation_Handle);
   procedure Set_Animation
     (H         : Animated_Widget_Handle;
      Animation : Adi.RLottie.Animation_Handle);

   function Get_Animation
     (W : Animated_Widget) return Adi.RLottie.Animation_Handle;
   function Get_Animation
     (H : Animated_Widget_Handle) return Adi.RLottie.Animation_Handle;

end Adi.Widget.Animated_Widget.RLottie;
