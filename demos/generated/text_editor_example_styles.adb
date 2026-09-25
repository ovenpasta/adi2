--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

package body Text_Editor_Example_Styles is

   procedure Register_Selectors_1
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
   end Register_Selectors_1;
   pragma No_Inline (Register_Selectors_1);

   procedure Register_Selectors_2
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("title", Title_Class_Part_Styles));
   end Register_Selectors_2;
   pragma No_Inline (Register_Selectors_2);

   procedure Register_Selectors_3
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("controls", Controls_Class_Part_Styles));
   end Register_Selectors_3;
   pragma No_Inline (Register_Selectors_3);

   procedure Register_Selectors_4
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("open-btn", Open_Btn_Class_Part_Styles));
   end Register_Selectors_4;
   pragma No_Inline (Register_Selectors_4);

   procedure Register_Selectors_5
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("wrap-status", Wrap_Status_Class_Part_Styles));
   end Register_Selectors_5;
   pragma No_Inline (Register_Selectors_5);

   procedure Register_Selectors_6
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("ro-status", Ro_Status_Class_Part_Styles));
   end Register_Selectors_6;
   pragma No_Inline (Register_Selectors_6);

   procedure Register_Selectors_7
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("wrap-switch", Wrap_Switch_Class_Part_Styles));
   end Register_Selectors_7;
   pragma No_Inline (Register_Selectors_7);

   procedure Register_Selectors_8
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("ro-switch", Ro_Switch_Class_Part_Styles));
   end Register_Selectors_8;
   pragma No_Inline (Register_Selectors_8);

   procedure Register_Selectors_9
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("editor", Editor_Class_Part_Styles));
   end Register_Selectors_9;
   pragma No_Inline (Register_Selectors_9);

   procedure Register_Selectors_10
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("context-menu", Context_Menu_Class_Part_Styles));
   end Register_Selectors_10;
   pragma No_Inline (Register_Selectors_10);

   procedure Register_Selectors_11
     (S : in out Adi.CSS_Source.Style_Source) is
   begin
      Adi.CSS_Source.Add_Static_Entry (S, Adi.CSS_Source.Class_Entry ("context-menu-item", Context_Menu_Item_Class_Part_Styles));
   end Register_Selectors_11;
   pragma No_Inline (Register_Selectors_11);

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
      Register_Selectors_9 (S);
      Register_Selectors_10 (S);
      Register_Selectors_11 (S);
   end Register_Selectors;

end Text_Editor_Example_Styles;
