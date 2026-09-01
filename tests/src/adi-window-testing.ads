--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Window.Testing is

   type Frame_Close_Callback is access procedure;

   --  Run once per drawn frame, after the window has taken the counter
   --  fields of Frame_Stats and before the frame's counters reset. A
   --  callback there reads Get_Frame_Stats and Adi.Widget's counters at
   --  the one instant they hold the same numbers, which is what holds
   --  each of those fields to the counter it is fed from. Frame_No, the
   --  layout count and the update, layout and draw times stand there
   --  too; Render_Us and Present_Us are computed past it and still read
   --  the frame before. Null takes the callback back off.
   procedure At_Frame_Close (Callback : Frame_Close_Callback);

end Adi.Window.Testing;
