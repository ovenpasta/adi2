--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.CSS_Parser.Testing is

   function Selector_Entry_Bytes return Natural is
     (Adi.CSS_Parser.Selector_Entry_Bytes);

   function Live_Sheets return Natural is
     (Adi.CSS_Parser.Live_Impl_Count);

   function Live_Rule_Sheets return Natural is
     (Adi.CSS_Parser.Live_Rule_Sheets);

   function Bindings_Held (Sheet : Stylesheet) return Natural is
     (Adi.CSS_Parser.Binding_Count (Sheet));

   function Probe_Count return Count is (Count (Probed_Bindings));

   procedure Reset_Probes is
   begin
      Probed_Bindings := 0;
   end Reset_Probes;

   function Selector_Count (Sheet : Stylesheet) return Natural is
     (Adi.CSS_Parser.Selector_Count (Sheet));

   function Selector_Kind_At (Sheet : Stylesheet;
                              Index : Positive) return Selector_Kind is
     (Adi.CSS_Parser.Selector_Kind_At (Sheet, Index));

   function Selector_Name_At (Sheet : Stylesheet;
                              Index : Positive) return String is
     (Adi.CSS_Parser.Selector_Name_At (Sheet, Index));

   function Styles_For_Scanned
     (Sheet : Stylesheet;
      Kind  : Selector_Kind;
      Name  : String) return Adi.Widget.Part_Style_Array is
     (Adi.CSS_Parser.Styles_For_Scanned (Sheet, Kind, Name));

end Adi.CSS_Parser.Testing;
