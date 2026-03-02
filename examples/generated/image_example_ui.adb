--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
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

   function Build
      return Adi.Window.Window_Access is
      W : constant Adi.Window.Window_Access :=
        Adi.Window.Create_Window ("Image Example", (1100.0, 700.0));
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Image Widget Showcase");
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Demonstrating SVG path, SVG file, PNG, and JPG formats with all object-fit modes");
      Label_3 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Image Formats");
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_4 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("SVG Path");
      Box_3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_5 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("SVG (tiger.svg)");
      Box_4 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_6 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("PNG (happycat.png)");
      Box_5 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_7 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("JPG (bg.jpg)");
      Label_8 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Object-Fit Modes (happycat.png)");
      Box_6 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_7 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_9 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("fill");
      Box_8 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_10 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("contain");
      Box_9 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_11 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("cover");
      Box_10 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_12 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("none");
      Box_11 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_13 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("scale-down");
      Label_14 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Tintable Icons (hover to change color)");
      Box_12 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_13 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_15 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Default → Blue");
      Box_14 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_16 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Amber → Yellow");
      Box_15 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_17 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Green → Light");
      Box_16 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_18 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Red → Light");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create;
      Img_Svg_Path := Adi.Widget.Image.Create;
      Img_Svg := Adi.Widget.Image.Create;
      Img_Png := Adi.Widget.Image.Create;
      Img_Jpg := Adi.Widget.Image.Create;
      Fit_Fill := Adi.Widget.Image.Create;
      Fit_Contain := Adi.Widget.Image.Create;
      Fit_Cover := Adi.Widget.Image.Create;
      Fit_None := Adi.Widget.Image.Create;
      Fit_Scale_Down := Adi.Widget.Image.Create;
      Tint_Default := Adi.Widget.Image.Create;
      Tint_Warm := Adi.Widget.Image.Create;
      Tint_Success := Adi.Widget.Image.Create;
      Tint_Danger := Adi.Widget.Image.Create;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("title", Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("subtitle", Subtitle_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("section-title", Section_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("format-grid", Format_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card", Card_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("image", Image_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card-label", Card_Label_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("fit-grid", Fit_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("fit-fill", Fit_Fill_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("fit-contain", Fit_Contain_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("fit-cover", Fit_Cover_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("fit-none", Fit_None_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("fit-scale-down", Fit_Scale_Down_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-grid", Tint_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-card", Tint_Card_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-icon", Tint_Icon_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-default", Tint_Default_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-warm", Tint_Warm_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-success", Tint_Success_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-danger", Tint_Danger_Class_Part_Styles));

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
      Adi.CSS_Source.Bind_Class (Source, "root", Root);
      Adi.CSS_Source.Bind_Class (Source, "title", Label_1);
      Adi.CSS_Source.Bind_Class (Source, "subtitle", Label_2);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_3);
      Adi.CSS_Source.Bind_Class (Source, "format-grid", Box_1);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_2);
      Adi.CSS_Source.Bind_Class (Source, "image", Img_Svg_Path);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_4);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_3);
      Adi.CSS_Source.Bind_Class (Source, "image", Img_Svg);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_5);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_4);
      Adi.CSS_Source.Bind_Class (Source, "image", Img_Png);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_6);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_5);
      Adi.CSS_Source.Bind_Class (Source, "image", Img_Jpg);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_7);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_8);
      Adi.CSS_Source.Bind_Class (Source, "fit-grid", Box_6);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_7);
      Adi.CSS_Source.Bind_Class (Source, "image fit-fill", Fit_Fill);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_9);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_8);
      Adi.CSS_Source.Bind_Class (Source, "image fit-contain", Fit_Contain);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_10);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_9);
      Adi.CSS_Source.Bind_Class (Source, "image fit-cover", Fit_Cover);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_11);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_10);
      Adi.CSS_Source.Bind_Class (Source, "image fit-none", Fit_None);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_12);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_11);
      Adi.CSS_Source.Bind_Class (Source, "image fit-scale-down", Fit_Scale_Down);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_13);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_14);
      Adi.CSS_Source.Bind_Class (Source, "tint-grid", Box_12);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", Box_13);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-default", Tint_Default);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_15);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", Box_14);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-warm", Tint_Warm);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_16);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", Box_15);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-success", Tint_Success);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_17);
      Adi.CSS_Source.Bind_Class (Source, "tint-card", Box_16);
      Adi.CSS_Source.Bind_Class (Source, "image tint-icon tint-danger", Tint_Danger);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_18);

      --  Build hierarchy
      Box_2.Add_Child (Img_Svg_Path);
      Box_2.Add_Child (Label_4);
      Box_3.Add_Child (Img_Svg);
      Box_3.Add_Child (Label_5);
      Box_4.Add_Child (Img_Png);
      Box_4.Add_Child (Label_6);
      Box_5.Add_Child (Img_Jpg);
      Box_5.Add_Child (Label_7);
      Box_1.Add_Child (Box_2);
      Box_1.Add_Child (Box_3);
      Box_1.Add_Child (Box_4);
      Box_1.Add_Child (Box_5);
      Box_7.Add_Child (Fit_Fill);
      Box_7.Add_Child (Label_9);
      Box_8.Add_Child (Fit_Contain);
      Box_8.Add_Child (Label_10);
      Box_9.Add_Child (Fit_Cover);
      Box_9.Add_Child (Label_11);
      Box_10.Add_Child (Fit_None);
      Box_10.Add_Child (Label_12);
      Box_11.Add_Child (Fit_Scale_Down);
      Box_11.Add_Child (Label_13);
      Box_6.Add_Child (Box_7);
      Box_6.Add_Child (Box_8);
      Box_6.Add_Child (Box_9);
      Box_6.Add_Child (Box_10);
      Box_6.Add_Child (Box_11);
      Box_13.Add_Child (Tint_Default);
      Box_13.Add_Child (Label_15);
      Box_14.Add_Child (Tint_Warm);
      Box_14.Add_Child (Label_16);
      Box_15.Add_Child (Tint_Success);
      Box_15.Add_Child (Label_17);
      Box_16.Add_Child (Tint_Danger);
      Box_16.Add_Child (Label_18);
      Box_12.Add_Child (Box_13);
      Box_12.Add_Child (Box_14);
      Box_12.Add_Child (Box_15);
      Box_12.Add_Child (Box_16);
      Root.Add_Child (Label_1);
      Root.Add_Child (Label_2);
      Root.Add_Child (Label_3);
      Root.Add_Child (Box_1);
      Root.Add_Child (Label_8);
      Root.Add_Child (Box_6);
      Root.Add_Child (Label_14);
      Root.Add_Child (Box_12);

      --  Auto-wire CSS live reload
      Adi.Window.Set_On_Tick (W.all, Tick_Styles_CB'Unrestricted_Access);

      W.Set_Root (Root);
      return W;
   end Build;

   end Instance;

end Image_Example_UI;
