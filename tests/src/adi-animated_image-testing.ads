--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Animated_Image.Testing is

   --  Whether the store still has a live slot for this handle. Distinct
   --  from Is_Valid, which also answers False for a handle whose slot is
   --  live but whose animation has been torn down -- so only this can
   --  tell a retired slot from an emptied record.
   function Handle_Is_Registered (H : Animation_Handle) return Boolean;

   --  How long the current frame is shown for. A test comparing against
   --  wall time needs it to know whether its own timing was usable.
   function Current_Frame_Delay_MS (H : Animation_Handle) return Natural;

   --  How far into the current frame playback stands.
   function Elapsed_MS (H : Animation_Handle) return Float;

end Adi.Animated_Image.Testing;
