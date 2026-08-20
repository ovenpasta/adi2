--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.CSS_Source.Testing is

   --  Binding entries Reapply_Bindings has looked at since the last
   --  Reset, and of those, the ones it re-styled. Visits are the honest
   --  measure: an implementation that scans the whole vector to find
   --  what changed still costs what the scan costs.
   type Count is mod 2 ** 32;

   function Visit_Count return Count;
   function Reapply_Count return Count;
   procedure Reset_Counts;

end Adi.CSS_Source.Testing;
