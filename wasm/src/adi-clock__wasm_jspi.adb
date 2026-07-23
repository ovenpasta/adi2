--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

--  WebAssembly (JSPI) body of Adi.Clock: like adi-clock__wasm.adb, but
--  Sleep_Until really suspends via emscripten_sleep, which under
--  -sJSPI parks the whole wasm stack and yields to the browser event
--  loop. This lets the native blocking Adi.App.Run drive frames while
--  main's stack (and every example local / nested callback frame)
--  stays alive. Requires linking with -sJSPI -sJSPI_EXPORTS=main.

with Interfaces;

package body Adi.Clock is

   use type Interfaces.Unsigned_64;

   function SDL_GetTicksNS return Interfaces.Unsigned_64
     with Import => True, Convention => C,
          External_Name => "SDL_GetTicksNS";

   procedure Emscripten_Sleep (MS : Interfaces.Unsigned_32)
     with Import => True, Convention => C,
          External_Name => "emscripten_sleep";

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
      Remaining : constant Duration := To_Duration (T - Now);
      MS        : Interfaces.Unsigned_32 := 0;
   begin
      if Remaining > 0.0 then
         MS := Interfaces.Unsigned_32 (Remaining * 1_000);
      end if;
      --  Always yield, even for 0 ms: the browser event loop must run
      --  between frames or the tab freezes and no input arrives.
      Emscripten_Sleep (MS);
   end Sleep_Until;

end Adi.Clock;
