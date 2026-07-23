--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

--  WebAssembly body of Adi.Clock: Ada.Real_Time is not part of the WASM
--  runtime, so Now reads SDL's monotonic nanosecond clock instead, and
--  Sleep_Until is a no-op — the browser drives frame cadence through
--  requestAnimationFrame (SDL main callbacks).

with Interfaces;

package body Adi.Clock is

   use type Interfaces.Unsigned_64;

   function SDL_GetTicksNS return Interfaces.Unsigned_64
     with Import => True, Convention => C,
          External_Name => "SDL_GetTicksNS";

   ---------
   -- Now --
   ---------

   function Now return Time is
      NS      : constant Interfaces.Unsigned_64 := SDL_GetTicksNS;
      --  Split so neither part overflows Duration (whole nanoseconds
      --  converted directly would exceed Duration'Last within seconds).
      Seconds : constant Long_Long_Integer :=
        Long_Long_Integer (NS / 1_000_000_000);
      Frac_NS : constant Long_Long_Integer :=
        Long_Long_Integer (NS mod 1_000_000_000);
   begin
      return Time (Duration (Seconds) + Duration (Frac_NS) / 1_000_000_000);
   end Now;

   -----------------
   -- Sleep_Until --
   -----------------

   procedure Sleep_Until (T : Time) is
      pragma Unreferenced (T);
   begin
      null;
   end Sleep_Until;

end Adi.Clock;
