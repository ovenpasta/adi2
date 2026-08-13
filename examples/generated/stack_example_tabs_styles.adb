--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

package body Stack_Example_Tabs_Styles is

   procedure Register_Selectors_1
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("tab-left", Tab_Left_Class_Part_Styles));
   end Register_Selectors_1;
   pragma No_Inline (Register_Selectors_1);

   procedure Register_Selectors_2
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("tab-center", Tab_Center_Class_Part_Styles));
   end Register_Selectors_2;
   pragma No_Inline (Register_Selectors_2);

   procedure Register_Selectors_3
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("tab-right", Tab_Right_Class_Part_Styles));
   end Register_Selectors_3;
   pragma No_Inline (Register_Selectors_3);

   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Register_Selectors_1 (S);
      Register_Selectors_2 (S);
      Register_Selectors_3 (S);
   end Register_Selectors;

end Stack_Example_Tabs_Styles;
