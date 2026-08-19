--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Playback_Clock is

   function Sample
     (State   : in out Clock_State;
      At_Time : Adi.Clock.Time) return Sample_Result
   is
      use type Adi.Clock.Time;
      Step : Duration;
   begin
      if not State.Anchored then
         State.Last := At_Time;
         State.Anchored := True;
         return (Kind => Anchored);
      end if;

      Step := Adi.Clock.To_Duration (At_Time - State.Last);

      --  Not merely nothing to charge: moving the anchor backwards would
      --  make the next sample charge for the interval twice.
      if Step <= 0.0 then
         return (Kind => Ignored);
      end if;

      State.Last := At_Time;
      return (Kind => Elapsed, Span => Step);
   end Sample;

   procedure Reanchor (State : in out Clock_State) is
   begin
      State.Anchored := False;
   end Reanchor;

   function Is_Anchored (State : Clock_State) return Boolean
   is (State.Anchored);

end Adi.Playback_Clock;
