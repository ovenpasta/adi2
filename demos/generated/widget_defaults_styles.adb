--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

package body Widget_Defaults_Styles is

   procedure Register_Selectors_1
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("button", Button_Class_Part_Styles));
   end Register_Selectors_1;
   pragma No_Inline (Register_Selectors_1);

   procedure Register_Selectors_2
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("text-input", Text_Input_Class_Part_Styles));
   end Register_Selectors_2;
   pragma No_Inline (Register_Selectors_2);

   procedure Register_Selectors_3
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("list-box", List_Box_Class_Part_Styles));
   end Register_Selectors_3;
   pragma No_Inline (Register_Selectors_3);

   procedure Register_Selectors_4
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("list-row", List_Row_Class_Part_Styles));
   end Register_Selectors_4;
   pragma No_Inline (Register_Selectors_4);

   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Register_Selectors_1 (S);
      Register_Selectors_2 (S);
      Register_Selectors_3 (S);
      Register_Selectors_4 (S);
   end Register_Selectors;

end Widget_Defaults_Styles;
