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

   --  What one registered selector costs to hold. The entries are
   --  copied per source and again into Applied_Statics, so this is the
   --  figure an application pays several times over.
   function Static_Entry_Bytes return Natural;

   --  Bindings a source holds: one per widget bound, however often the
   --  application binds it.
   function Bindings_Held (Source : Style_Source) return Natural;

   --  Widgets the source holds a current binding for.
   function Effective_Held (Source : Style_Source) return Natural;

   --  Source impls allocated and not yet destroyed.
   function Live_Sources return Natural;

   procedure Reset_Counts;

end Adi.CSS_Source.Testing;
