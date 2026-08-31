--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

package body Widget_Property_Styles is

   procedure Register_Selectors_1
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("alarm", Alarm_Class_Part_Styles));
   end Register_Selectors_1;
   pragma No_Inline (Register_Selectors_1);

   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Register_Selectors_1 (S);
   end Register_Selectors;

end Widget_Property_Styles;
