--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.CSS_Parser.Testing is

   --  What one parsed selector costs to hold. A sheet keeps one per
   --  selector it names, and every source that loads the same CSS keeps
   --  a sheet of its own.
   function Selector_Entry_Bytes return Natural;

   --  Sheet impls allocated and not yet destroyed.
   function Live_Sheets return Natural;

   --  Rule sheets holding rules and not yet finalized. A Rule_Sheet is
   --  an ordinary object, so what this counts is holders that are still
   --  in scope rather than entries in a store.
   function Live_Rule_Sheets return Natural;

   --  Bindings a sheet holds: one per widget bound, which a destroyed
   --  widget must leave.
   function Bindings_Held (Sheet : Stylesheet) return Natural;

   --  Stored keys the binding map has compared against since the last
   --  Reset_Probes, over every sheet alive.
   type Count is mod 2 ** 32;
   function Probe_Count return Count;
   procedure Reset_Probes;

   --  The selectors a sheet names, so a differential test can walk all
   --  of them, and the scan the selector index replaced.
   function Selector_Count (Sheet : Stylesheet) return Natural;
   function Selector_Kind_At (Sheet : Stylesheet;
                              Index : Positive) return Selector_Kind;
   function Selector_Name_At (Sheet : Stylesheet;
                              Index : Positive) return String;
   function Styles_For_Scanned
     (Sheet : Stylesheet;
      Kind  : Selector_Kind;
      Name  : String) return Adi.Widget.Part_Style_Array;

end Adi.CSS_Parser.Testing;
