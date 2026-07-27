--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Real_Time;

package body Adi.Clock is

   use type Ada.Real_Time.Time;

   Epoch : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;

   ---------
   -- Now --
   ---------

   function Now return Time is
   begin
      return Time (Ada.Real_Time.To_Duration (Ada.Real_Time.Clock - Epoch));
   end Now;

   -----------------
   -- Sleep_Until --
   -----------------

   procedure Sleep_Until (T : Time) is
   begin
      delay until Epoch + Ada.Real_Time.To_Time_Span (Duration (T));
   end Sleep_Until;

end Adi.Clock;
