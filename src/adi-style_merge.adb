--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package body Adi.Style_Merge is

   function Merge (Base, Override : Widget_Style) return Widget_Style is
      Result     : Widget_Style := Base;
      Rule_Index : Natural := 0;
      Added      : Boolean;
   begin
      Result.Base := Adi.CSS_Styles.Merge (Result.Base, Override.Base);

      for I in 1 .. Override.Rule_Count loop
         Rule_Index := 0;
         for J in 1 .. Result.Rule_Count loop
            if Result.Rules (J).Selector = Override.Rules (I).Selector then
               Rule_Index := J;
               exit;
            end if;
         end loop;

         if Rule_Index = 0 then
            Try_Add_Rule (Result, Override.Rules (I), Added);
         else
            Result.Rules (Rule_Index).Style :=
              Adi.CSS_Styles.Merge
                (Result.Rules (Rule_Index).Style, Override.Rules (I).Style);
         end if;
      end loop;

      return Result;
   end Merge;

   function Merge (Base, Override : Adi.Widget.Part_Style_Array)
     return Adi.Widget.Part_Style_Array
   is
      use Adi.Widget;
      Result : Part_Style_Array := Base;
   begin
      for P in Part_Kind loop
         if Override (P).Enabled then
            Result (P).Enabled := True;
            Result (P).Style := Merge (Result (P).Style, Override (P).Style);
         end if;
      end loop;
      return Result;
   end Merge;

end Adi.Style_Merge;
