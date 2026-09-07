--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Clock;

--  A playhead several viewers sample. While paused, keep sampling and
--  discard each result, or Reanchor delivers the whole gap in one leap on
--  resume.
package Adi.Playback_Clock is

   type Sample_Kind is
     (Anchored,   --  First sample since the clock was anchored. No time to
                  --  charge, but the caller may still have a frame to
                  --  settle at time zero.
      Elapsed,    --  Time passed; the anchor has moved to this instant.
      Ignored);   --  The same instant again, or one before the anchor.
                  --  The anchor has not moved.

   type Sample_Result (Kind : Sample_Kind := Ignored) is record
      case Kind is
         when Elapsed =>
            Span : Duration;
         when others =>
            null;
      end case;
   end record;

   type Clock_State is private;

   function Sample
     (State   : in out Clock_State;
      At_Time : Adi.Clock.Time) return Sample_Result;

   --  Next Sample returns Anchored rather than charging for the elapsed gap.
   procedure Reanchor (State : in out Clock_State);

   function Is_Anchored (State : Clock_State) return Boolean;

private

   type Clock_State is record
      Last     : Adi.Clock.Time := Adi.Clock.Zero;
      Anchored : Boolean := False;
   end record;

end Adi.Playback_Clock;
