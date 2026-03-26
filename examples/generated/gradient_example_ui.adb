--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Window; use Adi.Window;
with Gradient_Example_Styles; use Gradient_Example_Styles;

package body Gradient_Example_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
      declare
         Local_Reloaded : Boolean := False;
         Local_Success  : Boolean := True;
      begin
         Adi.CSS_Source.Tick (Source, Local_Reloaded, Local_Success);
         Reloaded := Reloaded or Local_Reloaded;
         Success := Success and Local_Success;
      end;
   end Tick_Styles;

   procedure Tick_Styles_CB (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, Success : Boolean;
   begin
      Tick_Styles (Reloaded, Success);
   end Tick_Styles_CB;

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
      Mode_OK : Boolean;
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   procedure Register_Root_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("root", Root_Class_Part_Styles));
   end Register_Root_Styles;

   procedure Register_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("title", Title_Class_Part_Styles));
   end Register_Title_Styles;

   procedure Register_Row_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("row", Row_Class_Part_Styles));
   end Register_Row_Styles;

   procedure Register_Grad_V_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-v", Grad_V_Class_Part_Styles));
   end Register_Grad_V_Styles;

   procedure Register_Grad_Card_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-card", Grad_Card_Class_Part_Styles));
   end Register_Grad_Card_Styles;

   procedure Register_Grad_H_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-h", Grad_H_Class_Part_Styles));
   end Register_Grad_H_Styles;

   procedure Register_Grad_Default_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-default", Grad_Default_Class_Part_Styles));
   end Register_Grad_Default_Styles;

   procedure Register_Grad_Up_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-up", Grad_Up_Class_Part_Styles));
   end Register_Grad_Up_Styles;

   procedure Register_Grad_Left_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-left", Grad_Left_Class_Part_Styles));
   end Register_Grad_Left_Styles;

   procedure Register_Grad_Diag_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-diag", Grad_Diag_Class_Part_Styles));
   end Register_Grad_Diag_Styles;

   procedure Register_Grad_Diag_Tr_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-diag-tr", Grad_Diag_Tr_Class_Part_Styles));
   end Register_Grad_Diag_Tr_Styles;

   procedure Register_Grad_Diag_Bl_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-diag-bl", Grad_Diag_Bl_Class_Part_Styles));
   end Register_Grad_Diag_Bl_Styles;

   procedure Register_Grad_Diag_Rev_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-diag-rev", Grad_Diag_Rev_Class_Part_Styles));
   end Register_Grad_Diag_Rev_Styles;

   procedure Register_Grad_45_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-45", Grad_45_Class_Part_Styles));
   end Register_Grad_45_Styles;

   procedure Register_Grad_135_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-135", Grad_135_Class_Part_Styles));
   end Register_Grad_135_Styles;

   procedure Register_Grad_Turn_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-turn", Grad_Turn_Class_Part_Styles));
   end Register_Grad_Turn_Styles;

   procedure Register_Grad_Rad_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-rad", Grad_Rad_Class_Part_Styles));
   end Register_Grad_Rad_Styles;

   procedure Register_Grad_Grad_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-grad", Grad_Grad_Class_Part_Styles));
   end Register_Grad_Grad_Styles;

   procedure Register_Grad_Alpha_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-alpha", Grad_Alpha_Class_Part_Styles));
   end Register_Grad_Alpha_Styles;

   procedure Register_Grad_3stop_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-3stop", Grad_3stop_Class_Part_Styles));
   end Register_Grad_3stop_Styles;

   procedure Register_Grad_Pos_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-pos", Grad_Pos_Class_Part_Styles));
   end Register_Grad_Pos_Styles;

   procedure Register_Grad_Edge_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-edge", Grad_Edge_Class_Part_Styles));
   end Register_Grad_Edge_Styles;

   procedure Register_Grad_16stop_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-16stop", Grad_16stop_Class_Part_Styles));
   end Register_Grad_16stop_Styles;

   procedure Register_Grad_Pill_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-pill", Grad_Pill_Class_Part_Styles));
   end Register_Grad_Pill_Styles;

   procedure Register_Grad_Border_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grad-border", Grad_Border_Class_Part_Styles));
   end Register_Grad_Border_Styles;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Gradient Showcase", (960.0, 900.0));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Linear Gradient Showcase");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_22 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_23 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_24 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_25 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_26 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_27 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_28 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;

      --  Configure properties
      Adi.Widget.Set_Label (+Box_2, "to bottom");
      Adi.Widget.Set_Label (+Box_3, "to right");
      Adi.Widget.Set_Label (+Box_4, "default angle");
      Adi.Widget.Set_Label (+Box_6, "to top");
      Adi.Widget.Set_Label (+Box_7, "to left");
      Adi.Widget.Set_Label (+Box_8, "to bottom right");
      Adi.Widget.Set_Label (+Box_10, "to top right");
      Adi.Widget.Set_Label (+Box_11, "to bottom left");
      Adi.Widget.Set_Label (+Box_12, "to top left");
      Adi.Widget.Set_Label (+Box_14, "45deg");
      Adi.Widget.Set_Label (+Box_15, "135deg");
      Adi.Widget.Set_Label (+Box_16, "0.25turn");
      Adi.Widget.Set_Label (+Box_18, "1.5708rad");
      Adi.Widget.Set_Label (+Box_19, "150grad");
      Adi.Widget.Set_Label (+Box_20, "alpha over bg-color");
      Adi.Widget.Set_Label (+Box_22, "3 stops, auto (flat)");
      Adi.Widget.Set_Label (+Box_23, "0/30/100% stops");
      Adi.Widget.Set_Label (+Box_24, "20/80% edge bands");
      Adi.Widget.Set_Label (+Box_26, "16 stops (flat)");
      Adi.Widget.Set_Label (+Box_27, "pill radius 50px");
      Adi.Widget.Set_Label (+Box_28, "4px border");

      --  Set labels
      Adi.Widget.Set_Label (+Box_2, "to bottom");
      Adi.Widget.Set_Label (+Box_3, "to right");
      Adi.Widget.Set_Label (+Box_4, "default angle");
      Adi.Widget.Set_Label (+Box_6, "to top");
      Adi.Widget.Set_Label (+Box_7, "to left");
      Adi.Widget.Set_Label (+Box_8, "to bottom right");
      Adi.Widget.Set_Label (+Box_10, "to top right");
      Adi.Widget.Set_Label (+Box_11, "to bottom left");
      Adi.Widget.Set_Label (+Box_12, "to top left");
      Adi.Widget.Set_Label (+Box_14, "45deg");
      Adi.Widget.Set_Label (+Box_15, "135deg");
      Adi.Widget.Set_Label (+Box_16, "0.25turn");
      Adi.Widget.Set_Label (+Box_18, "1.5708rad");
      Adi.Widget.Set_Label (+Box_19, "150grad");
      Adi.Widget.Set_Label (+Box_20, "alpha over bg-color");
      Adi.Widget.Set_Label (+Box_22, "3 stops, auto (flat)");
      Adi.Widget.Set_Label (+Box_23, "0/30/100% stops");
      Adi.Widget.Set_Label (+Box_24, "20/80% edge bands");
      Adi.Widget.Set_Label (+Box_26, "16 stops (flat)");
      Adi.Widget.Set_Label (+Box_27, "pill radius 50px");
      Adi.Widget.Set_Label (+Box_28, "4px border");

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Register_Root_Styles (Source);
      Register_Title_Styles (Source);
      Register_Row_Styles (Source);
      Register_Grad_V_Styles (Source);
      Register_Grad_Card_Styles (Source);
      Register_Grad_H_Styles (Source);
      Register_Grad_Default_Styles (Source);
      Register_Grad_Up_Styles (Source);
      Register_Grad_Left_Styles (Source);
      Register_Grad_Diag_Styles (Source);
      Register_Grad_Diag_Tr_Styles (Source);
      Register_Grad_Diag_Bl_Styles (Source);
      Register_Grad_Diag_Rev_Styles (Source);
      Register_Grad_45_Styles (Source);
      Register_Grad_135_Styles (Source);
      Register_Grad_Turn_Styles (Source);
      Register_Grad_Rad_Styles (Source);
      Register_Grad_Grad_Styles (Source);
      Register_Grad_Alpha_Styles (Source);
      Register_Grad_3stop_Styles (Source);
      Register_Grad_Pos_Styles (Source);
      Register_Grad_Edge_Styles (Source);
      Register_Grad_16stop_Styles (Source);
      Register_Grad_Pill_Styles (Source);
      Register_Grad_Border_Styles (Source);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/gradient_example.css", Loaded);
         if Loaded then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         else
            Mode_OK := False;
         end if;
         if not Mode_OK then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         end if;
      end;

      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Class (Source, "root", +Root);
      Adi.CSS_Source.Bind_Class (Source, "title", +Label_1);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "grad-v grad-card", +Box_2);
      Adi.CSS_Source.Bind_Class (Source, "grad-h grad-card", +Box_3);
      Adi.CSS_Source.Bind_Class (Source, "grad-default grad-card", +Box_4);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_5);
      Adi.CSS_Source.Bind_Class (Source, "grad-up grad-card", +Box_6);
      Adi.CSS_Source.Bind_Class (Source, "grad-left grad-card", +Box_7);
      Adi.CSS_Source.Bind_Class (Source, "grad-diag grad-card", +Box_8);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_9);
      Adi.CSS_Source.Bind_Class (Source, "grad-diag-tr grad-card", +Box_10);
      Adi.CSS_Source.Bind_Class (Source, "grad-diag-bl grad-card", +Box_11);
      Adi.CSS_Source.Bind_Class (Source, "grad-diag-rev grad-card", +Box_12);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_13);
      Adi.CSS_Source.Bind_Class (Source, "grad-45 grad-card", +Box_14);
      Adi.CSS_Source.Bind_Class (Source, "grad-135 grad-card", +Box_15);
      Adi.CSS_Source.Bind_Class (Source, "grad-turn grad-card", +Box_16);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_17);
      Adi.CSS_Source.Bind_Class (Source, "grad-rad grad-card", +Box_18);
      Adi.CSS_Source.Bind_Class (Source, "grad-grad grad-card", +Box_19);
      Adi.CSS_Source.Bind_Class (Source, "grad-alpha grad-card", +Box_20);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_21);
      Adi.CSS_Source.Bind_Class (Source, "grad-3stop grad-card", +Box_22);
      Adi.CSS_Source.Bind_Class (Source, "grad-pos grad-card", +Box_23);
      Adi.CSS_Source.Bind_Class (Source, "grad-edge grad-card", +Box_24);
      Adi.CSS_Source.Bind_Class (Source, "row", +Box_25);
      Adi.CSS_Source.Bind_Class (Source, "grad-16stop grad-card", +Box_26);
      Adi.CSS_Source.Bind_Class (Source, "grad-card grad-pill", +Box_27);
      Adi.CSS_Source.Bind_Class (Source, "grad-border grad-card", +Box_28);

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_1, +Box_3);
      Adi.Widget.Add_Child (+Box_1, +Box_4);
      Adi.Widget.Add_Child (+Box_5, +Box_6);
      Adi.Widget.Add_Child (+Box_5, +Box_7);
      Adi.Widget.Add_Child (+Box_5, +Box_8);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_9, +Box_11);
      Adi.Widget.Add_Child (+Box_9, +Box_12);
      Adi.Widget.Add_Child (+Box_13, +Box_14);
      Adi.Widget.Add_Child (+Box_13, +Box_15);
      Adi.Widget.Add_Child (+Box_13, +Box_16);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_17, +Box_19);
      Adi.Widget.Add_Child (+Box_17, +Box_20);
      Adi.Widget.Add_Child (+Box_21, +Box_22);
      Adi.Widget.Add_Child (+Box_21, +Box_23);
      Adi.Widget.Add_Child (+Box_21, +Box_24);
      Adi.Widget.Add_Child (+Box_25, +Box_26);
      Adi.Widget.Add_Child (+Box_25, +Box_27);
      Adi.Widget.Add_Child (+Box_25, +Box_28);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Box_5);
      Adi.Widget.Add_Child (+Root, +Box_9);
      Adi.Widget.Add_Child (+Root, +Box_13);
      Adi.Widget.Add_Child (+Root, +Box_17);
      Adi.Widget.Add_Child (+Root, +Box_21);
      Adi.Widget.Add_Child (+Root, +Box_25);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Gradient_Example_UI;
