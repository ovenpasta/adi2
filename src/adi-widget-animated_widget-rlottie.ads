--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.RLottie; use Adi.RLottie;

package Adi.Widget.Animated_Widget.RLottie is

   function Create
     (Animation : RLottie_Animation_Access) return Animated_Widget_Access;

   function Load_From_File
     (W    : in out Animated_Widget'Class;
      Path : String) return Boolean;
   function Load_From_File
     (H    : Animated_Widget_Handle;
      Path : String) return Boolean;

   procedure Set_Animation
     (W         : in out Animated_Widget'Class;
      Animation : RLottie_Animation_Access);
   procedure Set_Animation
     (H         : Animated_Widget_Handle;
      Animation : RLottie_Animation_Access);

   function Get_Animation
     (W : Animated_Widget) return RLottie_Animation_Access;
   function Get_Animation
     (H : Animated_Widget_Handle) return RLottie_Animation_Access;

end Adi.Widget.Animated_Widget.RLottie;
