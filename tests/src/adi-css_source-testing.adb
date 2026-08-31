--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.CSS_Source.Testing is

   function Visit_Count return Count is (Count (Visited_Bindings));

   function Reapply_Count return Count is (Count (Reapplied_Bindings));

   function Probe_Count return Count is (Count (Probed_Bindings));

   function Parse_Count return Count is (Count (Dynamic_Parses));

   function File_Read_Count return Count is (Count (Dynamic_Reads));

   function Static_Entry_Bytes return Natural is
     (Static_Style_Entry'Max_Size_In_Storage_Elements);

   function Bindings_Held (Source : Style_Source) return Natural is
     (Adi.CSS_Source.Binding_Count (Source));

   function Live_Sources return Natural is
     (Adi.CSS_Source.Live_Impl_Count);

   function Static_Styles_Indexed
     (Source : Style_Source;
      Kind   : Adi.CSS_Parser.Selector_Kind;
      Name   : String) return Adi.Widget.Part_Style_Array is
     (Adi.CSS_Source.Static_Styles_Indexed (Source, Kind, Name));

   function Static_Styles_Scanned
     (Source : Style_Source;
      Kind   : Adi.CSS_Parser.Selector_Kind;
      Name   : String) return Adi.Widget.Part_Style_Array is
     (Adi.CSS_Source.Static_Styles_Scanned (Source, Kind, Name));

   function Combined_Styles_Memoized
     (Source     : Style_Source;
      Tag_Name   : String;
      Class_Name : String;
      Id_Name    : String) return Adi.Widget.Part_Style_Array is
     (Adi.CSS_Source.Combined_Styles_Memoized
        (Source, Tag_Name, Class_Name, Id_Name));

   function Combined_Styles_Uncached
     (Source     : Style_Source;
      Tag_Name   : String;
      Class_Name : String;
      Id_Name    : String) return Adi.Widget.Part_Style_Array is
     (Adi.CSS_Source.Combined_Styles_Uncached
        (Source, Tag_Name, Class_Name, Id_Name));

   function Combined_Memo_Count (Source : Style_Source) return Natural is
     (Adi.CSS_Source.Combined_Memo_Count (Source));

   function Max_Combined_Memo return Natural is
     (Adi.CSS_Source.Max_Combined_Memo);

   procedure Reset_Counts is
   begin
      Visited_Bindings   := 0;
      Reapplied_Bindings := 0;
      Probed_Bindings    := 0;
      Dynamic_Parses     := 0;
      Dynamic_Reads      := 0;
   end Reset_Counts;

end Adi.CSS_Source.Testing;
