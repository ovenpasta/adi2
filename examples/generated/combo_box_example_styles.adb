--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

package body Combo_Box_Example_Styles is

   procedure Register_Selectors_1
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
   end Register_Selectors_1;
   pragma No_Inline (Register_Selectors_1);

   procedure Register_Selectors_2
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("container", Container_Class_Part_Styles));
   end Register_Selectors_2;
   pragma No_Inline (Register_Selectors_2);

   procedure Register_Selectors_3
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("title", Title_Class_Part_Styles));
   end Register_Selectors_3;
   pragma No_Inline (Register_Selectors_3);

   procedure Register_Selectors_4
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("hint", Hint_Class_Part_Styles));
   end Register_Selectors_4;
   pragma No_Inline (Register_Selectors_4);

   procedure Register_Selectors_5
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("status", Status_Class_Part_Styles));
   end Register_Selectors_5;
   pragma No_Inline (Register_Selectors_5);

   procedure Register_Selectors_6
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("combo", Combo_Class_Part_Styles));
   end Register_Selectors_6;
   pragma No_Inline (Register_Selectors_6);

   procedure Register_Selectors_7
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("dropdown", Dropdown_Class_Part_Styles));
   end Register_Selectors_7;
   pragma No_Inline (Register_Selectors_7);

   procedure Register_Selectors_8
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("option-row", Option_Row_Class_Part_Styles));
   end Register_Selectors_8;
   pragma No_Inline (Register_Selectors_8);

   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Register_Selectors_1 (S);
      Register_Selectors_2 (S);
      Register_Selectors_3 (S);
      Register_Selectors_4 (S);
      Register_Selectors_5 (S);
      Register_Selectors_6 (S);
      Register_Selectors_7 (S);
      Register_Selectors_8 (S);
   end Register_Selectors;

end Combo_Box_Example_Styles;
