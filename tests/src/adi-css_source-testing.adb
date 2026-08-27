--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.CSS_Source.Testing is

   function Visit_Count return Count is (Count (Visited_Bindings));

   function Reapply_Count return Count is (Count (Reapplied_Bindings));

   function Parse_Count return Count is (Count (Dynamic_Parses));

   function File_Read_Count return Count is (Count (Dynamic_Reads));

   procedure Reset_Counts is
   begin
      Visited_Bindings   := 0;
      Reapplied_Bindings := 0;
      Dynamic_Parses     := 0;
      Dynamic_Reads      := 0;
   end Reset_Counts;

end Adi.CSS_Source.Testing;
