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

   --  Stored keys the binding map has compared against since the last
   --  Reset, over every source alive. A handful per operation is what
   --  says the lookup is a hash; one per binding held is the scan
   --  coming back, and zero is the scan written outside the map.
   function Probe_Count return Count;

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

   --  Source impls allocated and not yet destroyed.
   function Live_Sources return Natural;

   --  Two answers to one question, for the test that holds one to the
   --  other: what Static_Mode reads out of its index, and the fold over
   --  every registered entry.
   function Static_Styles_Indexed
     (Source : Style_Source;
      Kind   : Adi.CSS_Parser.Selector_Kind;
      Name   : String) return Adi.Widget.Part_Style_Array;
   function Static_Styles_Scanned
     (Source : Style_Source;
      Kind   : Adi.CSS_Parser.Selector_Kind;
      Name   : String) return Adi.Widget.Part_Style_Array;

   --  The tag/classes/id fold through the memo, and past it. A memo hit
   --  has to equal a fresh fold.
   function Combined_Styles_Memoized
     (Source     : Style_Source;
      Tag_Name   : String;
      Class_Name : String;
      Id_Name    : String) return Adi.Widget.Part_Style_Array;
   function Combined_Styles_Uncached
     (Source     : Style_Source;
      Tag_Name   : String;
      Class_Name : String;
      Id_Name    : String) return Adi.Widget.Part_Style_Array;

   --  Triples the memo holds, and the cap it is dropped whole at.
   function Combined_Memo_Count (Source : Style_Source) return Natural;
   function Max_Combined_Memo return Natural;

   procedure Reset_Counts;

end Adi.CSS_Source.Testing;
