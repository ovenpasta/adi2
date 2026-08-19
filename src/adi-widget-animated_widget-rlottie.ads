--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.RLottie; use Adi.RLottie;

package Adi.Widget.Animated_Widget.RLottie is

   function Create
     (Animation : Animation_Handle) return Animated_Widget_Access;

   procedure Set_Animation
     (W         : in out Animated_Widget'Class;
      Animation : Animation_Handle);
   procedure Set_Animation
     (H         : Animated_Widget_Handle;
      Animation : Animation_Handle);

   function Get_Animation
     (W : Animated_Widget) return Animation_Handle;
   function Get_Animation
     (H : Animated_Widget_Handle) return Animation_Handle;

end Adi.Widget.Animated_Widget.RLottie;
