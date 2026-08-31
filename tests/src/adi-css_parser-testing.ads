--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.CSS_Parser.Testing is

   --  What one parsed selector costs to hold. A sheet keeps one per
   --  selector it names, and every source that loads the same CSS keeps
   --  a sheet of its own.
   function Selector_Entry_Bytes return Natural;

   --  Bindings a sheet holds, and the widgets it holds a current one
   --  for. A destroyed widget must leave both.
   --  Sheet impls allocated and not yet destroyed.
   function Live_Sheets return Natural;

   function Bindings_Held (Sheet : Stylesheet) return Natural;
   function Effective_Held (Sheet : Stylesheet) return Natural;

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
