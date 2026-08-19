--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.RLottie.Testing is

   --  How many frames have been rasterised. Frames alone cannot show
   --  this: a frame drawn from a retained image looks exactly like one
   --  rasterised again for the occasion.
   function Rasterisations (H : Animation_Handle) return Natural;

   --  How many extents have been replaced and kept as image shells.
   function Retired_Set_Count (H : Animation_Handle) return Natural;

   --  Whether a frame of the drawable set exists yet. A set holds no
   --  frames until playback reaches them.
   function Frame_Is_Retained
     (H : Animation_Handle; Frame : Positive) return Boolean;

   --  Make the next rasterisation fail, once, for this animation.
   --  Allocation failure cannot be provoked honestly by exhausting
   --  memory, and the path it takes has to be exercised.
   procedure Fail_Next_Rasterisation (H : Animation_Handle);

   --  How far the playhead has travelled. The frame index cannot stand in
   --  for it: frames are coarse, and a timeline running at twice its
   --  speed reads as the right frame for half of every step.
   function Elapsed (H : Animation_Handle) return Duration;

   --  Whether the store still has a live slot for this handle. Distinct
   --  from Is_Valid, which also answers False for a handle whose slot is
   --  live but whose animation has been torn down -- so only this can
   --  tell a retired slot from an emptied record.
   function Handle_Is_Registered (H : Animation_Handle) return Boolean;

   --  Make the next load fail once, after the native model is owned but
   --  before it is registered, which is the only way to reach the
   --  cleanup-and-propagate path.
   procedure Fail_Next_Load;

   --  Drive the extent state machine without drawing a frame, so a test
   --  can let an extent settle.
   procedure Service (H : Animation_Handle);

end Adi.RLottie.Testing;
