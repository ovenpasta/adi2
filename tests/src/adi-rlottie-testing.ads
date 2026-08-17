--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.RLottie.Testing is

   --  How many frames have been rasterised. Frames alone cannot show
   --  this: a frame drawn from a retained image looks exactly like one
   --  rasterised again for the occasion.
   function Rasterisations (Anim : RLottie_Animation'Class) return Natural;

   --  How many extents have been replaced and kept as image shells.
   function Retired_Set_Count (Anim : RLottie_Animation'Class) return Natural;

   --  Whether a frame of the drawable set exists yet. A set holds no
   --  frames until playback reaches them.
   function Frame_Is_Retained
     (Anim : RLottie_Animation'Class; Frame : Positive) return Boolean;

   --  Whether the newest retired set still holds a record for this
   --  frame, emptied of its pixels. A widget in a window that has not
   --  ticked since a replacement still points at one of these, so it has
   --  to be an empty image rather than freed storage.
   function Retired_Frame_Is_Shell
     (Anim : RLottie_Animation'Class; Frame : Positive) return Boolean;

   --  Make the next rasterisation fail, once, for this animation.
   --  Allocation failure cannot be provoked honestly by exhausting
   --  memory, and the path it takes has to be exercised.
   procedure Fail_Next_Rasterisation (Anim : in out RLottie_Animation'Class);

   --  How far the playhead has travelled. The frame index cannot stand in
   --  for it: frames are coarse, and a timeline running at twice its
   --  speed reads as the right frame for half of every step.
   function Elapsed (Anim : RLottie_Animation'Class) return Duration;

   --  Drive the extent state machine without drawing a frame, so a test
   --  can let an extent settle.
   procedure Service (Anim : in out RLottie_Animation'Class);

end Adi.RLottie.Testing;
