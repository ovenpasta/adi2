--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Clock;

--  Turning instants into elapsed time, for a playhead several viewers
--  may sample. Each of them ticking with its own delta would advance one
--  timeline once per viewer; sampling a shared clock instead means each
--  contributes only the time that actually passed, and the second viewer
--  of a tick contributes nothing.
--
--  A duration alone cannot say what happened: zero reads the same for a
--  first anchor, a repeated instant and a sample from before the anchor,
--  and those want opposite responses. So the result says which.
--
--  What this does not know: speed, frames, or whether anything is
--  playing. Scaling the span and choosing a frame belong to the caller,
--  as does pausing -- sample first so the paused span is consumed rather
--  than delivered in one leap on resume, then drop it while paused.
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

   --  Read the clock at an instant and say what that means.
   function Sample
     (State   : in out Clock_State;
      At_Time : Adi.Clock.Time) return Sample_Result;

   --  Forget where the clock stood. The next sample anchors instead of
   --  charging for the gap, which is what stops a resume, a reset or a
   --  step taken by hand from delivering everything since the last
   --  sample at once.
   procedure Reanchor (State : in out Clock_State);

   --  Whether the clock stands anywhere yet.
   function Is_Anchored (State : Clock_State) return Boolean;

private

   type Clock_State is record
      Last     : Adi.Clock.Time := Adi.Clock.Zero;
      Anchored : Boolean := False;
   end record;

end Adi.Playback_Clock;
