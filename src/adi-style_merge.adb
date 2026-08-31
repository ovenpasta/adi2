--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package body Adi.Style_Merge is

   function Merge (Base, Override : Widget_Style) return Widget_Style is
   begin
      --  One contributor answers with its own handle: folding a style
      --  onto the empty one reproduces it.
      if Base = Empty_Widget_Style then
         return Override;
      elsif Override = Empty_Widget_Style then
         return Base;
      end if;

      declare
         Result     : Style_Definition := Definition (Base);
         Extra      : constant Style_Definition := Definition (Override);
         Rule_Index : Natural;
         Added      : Boolean;
      begin
         Result.Base := Adi.CSS_Styles.Intern_Rules
           (Adi.CSS_Styles.Merge (Adi.CSS_Styles.Rules_Of (Result.Base),
                                  Adi.CSS_Styles.Rules_Of (Extra.Base)));

         for I in 1 .. Extra.Rule_Count loop
            Rule_Index := 0;
            for J in 1 .. Result.Rule_Count loop
               if Result.Rules (J).Selector = Extra.Rules (I).Selector then
                  Rule_Index := J;
                  exit;
               end if;
            end loop;

            if Rule_Index = 0 then
               Try_Add_Rule (Result, Extra.Rules (I), Added);
            else
               Result.Rules (Rule_Index).Style :=
                 Adi.CSS_Styles.Intern_Rules
                   (Adi.CSS_Styles.Merge
                      (Adi.CSS_Styles.Rules_Of
                         (Result.Rules (Rule_Index).Style),
                       Adi.CSS_Styles.Rules_Of (Extra.Rules (I).Style)));
            end if;
         end loop;

         return Intern (Result);
      end;
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
