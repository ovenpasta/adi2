--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

--  Monotonic program clock used for frame timing and perf stopwatches.
--
--  This is the single seam between the library and the platform clock.
--  The names mirror Ada.Real_Time (Time, Microseconds, To_Duration; the
--  clock function is Now, since an unqualified Clock would denote this
--  package). The native body is a thin
--  wrapper over Ada.Real_Time; WASM builds substitute a body over SDL
--  ticks, because Ada.Real_Time is not part of the WebAssembly runtime
--  and the browser owns frame cadence (see wasm/PORT_REPORT.md).

pragma Ada_2022;

package Adi.Clock is
   pragma Elaborate_Body;

   type Time is private;       --  monotonic instant since program start
   type Time_Span is private;  --  difference between two instants

   Zero : constant Time;

   function Now return Time;

   function "-" (Later, Earlier : Time) return Time_Span;
   function "+" (T : Time; S : Time_Span) return Time;

   --  Accumulating spans, for totals over many measured intervals.
   function "+" (L, R : Time_Span) return Time_Span;
   Zero_Span : constant Time_Span;

   function Microseconds (US : Integer) return Time_Span;
   function To_Duration (S : Time_Span) return Duration;

   --  Block until instant T. Native: delay until. WASM: no-op — the
   --  browser drives frame cadence via requestAnimationFrame.
   procedure Sleep_Until (T : Time);

private

   --  Seconds since the program-start epoch. Duration representation
   --  keeps Ada.Real_Time's nanosecond granularity without overflow.
   type Time is new Duration;
   type Time_Span is new Duration;

   Zero : constant Time := 0.0;

   function "-" (Later, Earlier : Time) return Time_Span is
     (Time_Span (Duration (Later) - Duration (Earlier)));

   function "+" (T : Time; S : Time_Span) return Time is
     (Time (Duration (T) + Duration (S)));

   function "+" (L, R : Time_Span) return Time_Span is
     (Time_Span (Duration (L) + Duration (R)));

   Zero_Span : constant Time_Span := 0.0;

   function Microseconds (US : Integer) return Time_Span is
     (Time_Span (Duration (US) / 1_000_000));

   function To_Duration (S : Time_Span) return Duration is
     (Duration (S));

end Adi.Clock;
