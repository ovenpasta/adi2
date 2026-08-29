--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Style_Merge;

package body Adi.Style_Merge_Testing is

   function Merge (Base, Override : Adi.Widget.Part_Style_Array)
     return Adi.Widget.Part_Style_Array
   is (Adi.Style_Merge.Merge (Base, Override));

end Adi.Style_Merge_Testing;
