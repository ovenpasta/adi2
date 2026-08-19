--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Animated_Image.Testing is

   function A (H : Animation_Handle) return Animated_Image_Access
   is (if Animation_Stores.Is_Valid (H.Id)
       then Animation_Stores.Get (H.Id)
       else null);

   function Handle_Is_Registered (H : Animation_Handle) return Boolean
   is (Animation_Stores.Is_Valid (H.Id));

   function Current_Frame_Delay_MS (H : Animation_Handle) return Natural is
      P : constant Animated_Image_Access := A (H);
   begin
      if P = null
        or else P.Current_Frame not in 1 .. Natural (P.Frames.Length)
      then
         return 0;
      end if;
      return P.Frames.Element (Positive (P.Current_Frame)).Delay_MS;
   end Current_Frame_Delay_MS;

   function Elapsed_MS (H : Animation_Handle) return Float
   is (if A (H) = null then 0.0 else A (H).Elapsed_MS);

end Adi.Animated_Image.Testing;
