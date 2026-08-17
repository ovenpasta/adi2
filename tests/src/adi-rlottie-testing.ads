--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.RLottie.Testing is

   --  How many rasterisations have been started. Frames alone cannot
   --  distinguish one build from several: a resize that rebuilt at every
   --  intermediate extent ends up drawing exactly what a single settled
   --  build would.
   function Build_Count (Anim : RLottie_Animation'Class) return Natural;

   --  Whether a worker is running now. At most one ever is, which is the
   --  property a rapid resize could otherwise break.
   function Build_In_Flight (Anim : RLottie_Animation'Class) return Boolean;

   --  The generation last handed to a worker.
   function Generation (Anim : RLottie_Animation'Class) return Natural;

   --  Whether the build in flight has been abandoned and will be reaped
   --  rather than published.
   function Build_Superseded (Anim : RLottie_Animation'Class) return Boolean;

   --  How far the playhead has travelled. The frame index cannot stand in
   --  for it: frames are coarse, and a timeline running at twice its speed
   --  reads as the right frame for half of every step.
   function Elapsed (Anim : RLottie_Animation'Class) return Duration;

   --  Drive the state machine without drawing a frame, so a test can let
   --  a build finish or an extent settle.
   procedure Service (Anim : in out RLottie_Animation'Class);

end Adi.RLottie.Testing;
