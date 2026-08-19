--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.SDL.Surface;

package body Adi.RLottie.Testing is

   use type Adi.SDL.Surface.SDL_Surface_Ptr;

   function A (H : Animation_Handle) return RLottie_Animation_Access
   is (if Animation_Stores.Is_Valid (H.Id)
       then Animation_Stores.Get (H.Id)
       else null);

   function Rasterisations (H : Animation_Handle) return Natural
   is (if A (H) = null then 0 else A (H).Rasterisations);

   function Retired_Set_Count (H : Animation_Handle) return Natural
   is (if A (H) = null then 0 else A (H).Retired_Count);

   --  A frame of the drawable set exists: playback reached it and it was
   --  kept.
   function Frame_Is_Retained
     (H : Animation_Handle; Frame : Positive) return Boolean
   is (A (H) /= null
       and then A (H).Active /= null
       and then A (H).Active.Images /= null
       and then Frame <= A (H).Active.Images'Last
       and then Adi.Image.Is_Owned (A (H).Active.Images (Frame)));

   procedure Fail_Next_Rasterisation (H : Animation_Handle) is
      P : constant RLottie_Animation_Access := A (H);
   begin
      if P /= null then
         P.Fail_Next_Raster := True;
      end if;
   end Fail_Next_Rasterisation;

   function Elapsed (H : Animation_Handle) return Duration
   is (if A (H) = null then 0.0 else Duration (A (H).Elapsed_S));

   procedure Fail_Next_Load is
   begin
      Fail_After_Model := True;
   end Fail_Next_Load;

   function Handle_Is_Registered (H : Animation_Handle) return Boolean
   is (Animation_Stores.Is_Valid (H.Id));

   procedure Service (H : Animation_Handle) is
      P : constant RLottie_Animation_Access := A (H);
   begin
      if P /= null then
         Service_Pending (P.all);
      end if;
   end Service;

end Adi.RLottie.Testing;
