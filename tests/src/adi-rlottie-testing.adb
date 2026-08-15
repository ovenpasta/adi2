--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.RLottie.Testing is

   function Build_Count (Anim : RLottie_Animation'Class) return Natural
   is (Anim.Build_Count);

   function Build_In_Flight (Anim : RLottie_Animation'Class) return Boolean
   is (Anim.Worker /= null);

   function Generation (Anim : RLottie_Animation'Class) return Natural
   is (Anim.Generation);

   function Build_Superseded (Anim : RLottie_Animation'Class) return Boolean
   is (Anim.Build_Superseded);

   procedure Service (Anim : in out RLottie_Animation'Class) is
   begin
      Service_Pending (Anim);
   end Service;

end Adi.RLottie.Testing;
