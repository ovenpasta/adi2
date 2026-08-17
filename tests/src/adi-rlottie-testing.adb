--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.SDL.Surface;

package body Adi.RLottie.Testing is

   use type Adi.SDL.Surface.SDL_Surface_Ptr;

   function Rasterisations (Anim : RLottie_Animation'Class) return Natural
   is (Anim.Rasterisations);

   function Retired_Set_Count (Anim : RLottie_Animation'Class) return Natural
   is (Anim.Retired_Count);

   function Frame_Is_Retained
     (Anim : RLottie_Animation'Class; Frame : Positive) return Boolean
   is (Anim.Active /= null
       and then Anim.Active.Images /= null
       and then Frame <= Anim.Active.Images'Last
       and then Anim.Active.Images (Frame) /= null);

   function Retired_Frame_Is_Shell
     (Anim : RLottie_Animation'Class; Frame : Positive) return Boolean
   is (Anim.Retired /= null
       and then Anim.Retired.Images /= null
       and then Frame <= Anim.Retired.Images'Last
       and then Anim.Retired.Images (Frame) /= null
       and then Adi.Image.Get_Surface (Anim.Retired.Images (Frame).all)
                  = null);

   procedure Fail_Next_Rasterisation (Anim : in out RLottie_Animation'Class) is
   begin
      Anim.Fail_Next_Raster := True;
   end Fail_Next_Rasterisation;

   function Elapsed (Anim : RLottie_Animation'Class) return Duration
   is (Duration (Anim.Elapsed_S));

   procedure Service (Anim : in out RLottie_Animation'Class) is
   begin
      Service_Pending (Anim);
   end Service;

end Adi.RLottie.Testing;
