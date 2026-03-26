--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Window; use Adi.Window;
with Image_Example_Styles; use Image_Example_Styles;

package body Image_Example_UI is

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

   procedure Register_Subtitle_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("subtitle", Subtitle_Class_Part_Styles));
   end Register_Subtitle_Styles;

   procedure Register_Section_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("section-title", Section_Title_Class_Part_Styles));
   end Register_Section_Title_Styles;

   procedure Register_Format_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("format-grid", Format_Grid_Class_Part_Styles));
   end Register_Format_Grid_Styles;

   procedure Register_Card_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card", Card_Class_Part_Styles));
   end Register_Card_Styles;

   procedure Register_Image_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("image", Image_Class_Part_Styles));
   end Register_Image_Styles;

   procedure Register_Card_Label_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card-label", Card_Label_Class_Part_Styles));
   end Register_Card_Label_Styles;

   procedure Register_Fit_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("fit-grid", Fit_Grid_Class_Part_Styles));
   end Register_Fit_Grid_Styles;

   procedure Register_Fit_Fill_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("fit-fill", Fit_Fill_Class_Part_Styles));
   end Register_Fit_Fill_Styles;

   procedure Register_Fit_Contain_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("fit-contain", Fit_Contain_Class_Part_Styles));
   end Register_Fit_Contain_Styles;

   procedure Register_Fit_Cover_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("fit-cover", Fit_Cover_Class_Part_Styles));
   end Register_Fit_Cover_Styles;

   procedure Register_Fit_None_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("fit-none", Fit_None_Class_Part_Styles));
   end Register_Fit_None_Styles;

   procedure Register_Fit_Scale_Down_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("fit-scale-down", Fit_Scale_Down_Class_Part_Styles));
   end Register_Fit_Scale_Down_Styles;

   procedure Register_Tint_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-grid", Tint_Grid_Class_Part_Styles));
   end Register_Tint_Grid_Styles;

   procedure Register_Tint_Card_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-card", Tint_Card_Class_Part_Styles));
   end Register_Tint_Card_Styles;

   procedure Register_Tint_Icon_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-icon", Tint_Icon_Class_Part_Styles));
   end Register_Tint_Icon_Styles;

   procedure Register_Tint_Default_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-default", Tint_Default_Class_Part_Styles));
   end Register_Tint_Default_Styles;

   procedure Register_Tint_Warm_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-warm", Tint_Warm_Class_Part_Styles));
   end Register_Tint_Warm_Styles;

   procedure Register_Tint_Success_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-success", Tint_Success_Class_Part_Styles));
   end Register_Tint_Success_Styles;

   procedure Register_Tint_Danger_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-danger", Tint_Danger_Class_Part_Styles));
   end Register_Tint_Danger_Styles;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Image Example", (1100.0, 700.0));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Image Widget Showcase");
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Demonstrating SVG path, SVG file, PNG, and JPG formats with all object-fit modes");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Image Formats");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("SVG Path");
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("SVG (tiger.svg)");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("PNG (happycat.png)");
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("JPG (bg.jpg)");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Object-Fit Modes (happycat.png)");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("fill");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("contain");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("cover");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("none");
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("scale-down");
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Tintable Icons (hover to change color)");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Default → Blue");
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Amber → Yellow");
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Green → Light");
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Red → Light");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;
      Img_Svg_Path := Adi.Widget.Image.Create_Handle;
      Img_Svg := Adi.Widget.Image.Create_Handle;
      Img_Png := Adi.Widget.Image.Create_Handle;
      Img_Jpg := Adi.Widget.Image.Create_Handle;
      Fit_Fill := Adi.Widget.Image.Create_Handle;
      Fit_Contain := Adi.Widget.Image.Create_Handle;
      Fit_Cover := Adi.Widget.Image.Create_Handle;
      Fit_None := Adi.Widget.Image.Create_Handle;
      Fit_Scale_Down := Adi.Widget.Image.Create_Handle;
      Tint_Default := Adi.Widget.Image.Create_Handle;
      Tint_Warm := Adi.Widget.Image.Create_Handle;
      Tint_Success := Adi.Widget.Image.Create_Handle;
      Tint_Danger := Adi.Widget.Image.Create_Handle;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Register_Root_Styles (Source);
      Register_Title_Styles (Source);
      Register_Subtitle_Styles (Source);
      Register_Section_Title_Styles (Source);
      Register_Format_Grid_Styles (Source);
      Register_Card_Styles (Source);
      Register_Image_Styles (Source);
      Register_Card_Label_Styles (Source);
      Register_Fit_Grid_Styles (Source);
      Register_Fit_Fill_Styles (Source);
      Register_Fit_Contain_Styles (Source);
      Register_Fit_Cover_Styles (Source);
      Register_Fit_None_Styles (Source);
      Register_Fit_Scale_Down_Styles (Source);
      Register_Tint_Grid_Styles (Source);
      Register_Tint_Card_Styles (Source);
      Register_Tint_Icon_Styles (Source);
      Register_Tint_Default_Styles (Source);
      Register_Tint_Warm_Styles (Source);
      Register_Tint_Success_Styles (Source);
      Register_Tint_Danger_Styles (Source);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/image_example.css", Loaded);
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
      Adi.CSS_Source.Bind_Class (Source, "subtitle", +Label_2);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_3);
      Adi.CSS_Source.Bind_Class (Source, "format-grid", +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_2);
      Adi.CSS_Source.Bind_Class (Source, "image", +Img_Svg_Path);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_4);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_3);
      Adi.CSS_Source.Bind_Class (Source, "image", +Img_Svg);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_5);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_4);
      Adi.CSS_Source.Bind_Class (Source, "image", +Img_Png);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_6);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_5);
      Adi.CSS_Source.Bind_Class (Source, "image", +Img_Jpg);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_7);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_8);
      Adi.CSS_Source.Bind_Class (Source, "fit-grid", +Box_6);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_7);
      Adi.CSS_Source.Bind_Class (Source, "image fit-fill", +Fit_Fill);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_9);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_8);
      Adi.CSS_Source.Bind_Class (Source, "image fit-contain", +Fit_Contain);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_10);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_9);
      Adi.CSS_Source.Bind_Class (Source, "image fit-cover", +Fit_Cover);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_11);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_10);
      Adi.CSS_Source.Bind_Class (Source, "image fit-none", +Fit_None);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_12);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_11);
      Adi.CSS_Source.Bind_Class (Source, "image fit-scale-down", +Fit_Scale_Down);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_13);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_14);
      Adi.CSS_Source.Bind_Class (Source, "tint-grid", +Box_12);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", +Box_13);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-default", +Tint_Default);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_15);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", +Box_14);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-warm", +Tint_Warm);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_16);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", +Box_15);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-success", +Tint_Success);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_17);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", +Box_16);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-danger", +Tint_Danger);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_18);

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_2, +Img_Svg_Path);
      Adi.Widget.Add_Child (+Box_2, +Label_4);
      Adi.Widget.Add_Child (+Box_3, +Img_Svg);
      Adi.Widget.Add_Child (+Box_3, +Label_5);
      Adi.Widget.Add_Child (+Box_4, +Img_Png);
      Adi.Widget.Add_Child (+Box_4, +Label_6);
      Adi.Widget.Add_Child (+Box_5, +Img_Jpg);
      Adi.Widget.Add_Child (+Box_5, +Label_7);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_1, +Box_3);
      Adi.Widget.Add_Child (+Box_1, +Box_4);
      Adi.Widget.Add_Child (+Box_1, +Box_5);
      Adi.Widget.Add_Child (+Box_7, +Fit_Fill);
      Adi.Widget.Add_Child (+Box_7, +Label_9);
      Adi.Widget.Add_Child (+Box_8, +Fit_Contain);
      Adi.Widget.Add_Child (+Box_8, +Label_10);
      Adi.Widget.Add_Child (+Box_9, +Fit_Cover);
      Adi.Widget.Add_Child (+Box_9, +Label_11);
      Adi.Widget.Add_Child (+Box_10, +Fit_None);
      Adi.Widget.Add_Child (+Box_10, +Label_12);
      Adi.Widget.Add_Child (+Box_11, +Fit_Scale_Down);
      Adi.Widget.Add_Child (+Box_11, +Label_13);
      Adi.Widget.Add_Child (+Box_6, +Box_7);
      Adi.Widget.Add_Child (+Box_6, +Box_8);
      Adi.Widget.Add_Child (+Box_6, +Box_9);
      Adi.Widget.Add_Child (+Box_6, +Box_10);
      Adi.Widget.Add_Child (+Box_6, +Box_11);
      Adi.Widget.Add_Child (+Box_13, +Tint_Default);
      Adi.Widget.Add_Child (+Box_13, +Label_15);
      Adi.Widget.Add_Child (+Box_14, +Tint_Warm);
      Adi.Widget.Add_Child (+Box_14, +Label_16);
      Adi.Widget.Add_Child (+Box_15, +Tint_Success);
      Adi.Widget.Add_Child (+Box_15, +Label_17);
      Adi.Widget.Add_Child (+Box_16, +Tint_Danger);
      Adi.Widget.Add_Child (+Box_16, +Label_18);
      Adi.Widget.Add_Child (+Box_12, +Box_13);
      Adi.Widget.Add_Child (+Box_12, +Box_14);
      Adi.Widget.Add_Child (+Box_12, +Box_15);
      Adi.Widget.Add_Child (+Box_12, +Box_16);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Label_2);
      Adi.Widget.Add_Child (+Root, +Label_3);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Label_8);
      Adi.Widget.Add_Child (+Root, +Box_6);
      Adi.Widget.Add_Child (+Root, +Label_14);
      Adi.Widget.Add_Child (+Root, +Box_12);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Image_Example_UI;
