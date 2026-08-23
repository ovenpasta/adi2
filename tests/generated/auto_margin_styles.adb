--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

package body Auto_Margin_Styles is

   procedure Register_Selectors_1
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Tag_Entry ("box", Box_Tag_Part_Styles));
   end Register_Selectors_1;
   pragma No_Inline (Register_Selectors_1);

   procedure Register_Selectors_2
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("centred", Centred_Class_Part_Styles));
   end Register_Selectors_2;
   pragma No_Inline (Register_Selectors_2);

   procedure Register_Selectors_3
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("push-right", Push_Right_Class_Part_Styles));
   end Register_Selectors_3;
   pragma No_Inline (Register_Selectors_3);

   procedure Register_Selectors_4
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("push-left", Push_Left_Class_Part_Styles));
   end Register_Selectors_4;
   pragma No_Inline (Register_Selectors_4);

   procedure Register_Selectors_5
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("three", Three_Class_Part_Styles));
   end Register_Selectors_5;
   pragma No_Inline (Register_Selectors_5);

   procedure Register_Selectors_6
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("vertical-auto", Vertical_Auto_Class_Part_Styles));
   end Register_Selectors_6;
   pragma No_Inline (Register_Selectors_6);

   procedure Register_Selectors_7
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("tweak", Tweak_Class_Part_Styles));
   end Register_Selectors_7;
   pragma No_Inline (Register_Selectors_7);

   procedure Register_Selectors_8
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Id_Entry ("bad", Bad_Id_Part_Styles));
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

end Auto_Margin_Styles;
