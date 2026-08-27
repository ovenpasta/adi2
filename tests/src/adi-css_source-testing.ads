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

   --  Concatenations handed to the parser, and files read to build them.
   --  A test that only looked at the resulting styles could not tell one
   --  parse of N sheets from N parses of a growing set.
   function Parse_Count return Count;
   function File_Read_Count return Count;

   procedure Reset_Counts;

end Adi.CSS_Source.Testing;
