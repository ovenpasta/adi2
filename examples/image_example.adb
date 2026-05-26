pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.Core;
with Adi.Image;        use Adi.Image;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Window;       use Adi.Window;
with Image_Example_UI;

procedure Image_Example is
   A : Adi.App.App;
   package UI is new Image_Example_UI.Instance;
   W : Window_Handle;

   --  Material Symbols "star" 24x24 path
   Star_Path : constant String :=
     "M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 "
     & "9.19 8.63 2 9.24l5.46 4.73L5.82 21z";

   --  SVG icon paths for tintable demos (24x24 viewbox)
   Heart_Path : constant String :=
     "M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 "
     & "2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09"
     & "C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5"
     & "c0 3.78-3.4 6.86-8.55 11.54L12 21.35z";

   Bolt_Path : constant String :=
     "M7 2v11h3v9l7-12h-4l4-8z";

   Shield_Path : constant String :=
     "M12 1L3 5v6c0 5.55 3.84 10.74 9 12 "
     & "5.16-1.26 9-6.45 9-12V5l-9-4z";

   Bell_Path : constant String :=
     "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5"
     & "c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5"
     & "s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1"
     & "h16v-1l-2-2z";
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);
   W := UI.Build;

   --  Load SVG path image
   declare
      Svg_Path_Img : constant Adi.Image.Image_Access :=
        Adi.Image.Load_SVG_Path
          (Path_Data => Star_Path,
           Size      => (Width => 128.0, Height => 128.0),
           Fill      => (R => 255, G => 200, B => 0, A => 255));
   begin
      if Svg_Path_Img /= null then
         Set_Image (UI.Img_Svg_Path, Svg_Path_Img);
      end if;
   end;

   --  Load SVG file
   declare
      Svg_Img : constant Adi.Image.Image_Access :=
        Adi.Image.Load_From_File ("examples/assets/tiger.svg");
   begin
      if Svg_Img /= null then
         Set_Image (UI.Img_Svg, Svg_Img);
      end if;
   end;

   --  Load PNG file
   declare
      Png_Img : constant Adi.Image.Image_Access :=
        Adi.Image.Load_From_File ("examples/assets/happycat.png");
   begin
      if Png_Img /= null then
         Set_Image (UI.Img_Png, Png_Img);
      end if;
   end;

   --  Load JPG file
   declare
      Jpg_Img : constant Adi.Image.Image_Access :=
        Adi.Image.Load_From_File ("examples/assets/bg.jpg");
   begin
      if Jpg_Img /= null then
         Set_Image (UI.Img_Jpg, Jpg_Img);
      end if;
   end;

   --  Load happycat.png for all object-fit mode demos
   declare
      Cat : constant Adi.Image.Image_Access :=
        Adi.Image.Load_From_File ("examples/assets/happycat.png");
   begin
      if Cat /= null then
         Set_Image (UI.Fit_Fill, Cat);
         Set_Image (UI.Fit_Contain, Cat);
         Set_Image (UI.Fit_Cover, Cat);
         Set_Image (UI.Fit_None, Cat);
         Set_Image (UI.Fit_Scale_Down, Cat);
      end if;
   end;

   --  Load tintable SVG path icons (white on transparent, tinted by CSS color)
   declare
      Icon_Size : constant Adi.Core.Size_2D := (24.0, 24.0);
      White     : constant Adi.Core.Color_8 := (255, 255, 255, 255);

      Heart : constant Image_Access := Load_SVG_Path
        (Heart_Path, Icon_Size,
         Fill => White, Tintable => True);
      Bolt : constant Image_Access := Load_SVG_Path
        (Bolt_Path, Icon_Size,
         Fill => White, Tintable => True);
      Shield : constant Image_Access := Load_SVG_Path
        (Shield_Path, Icon_Size,
         Fill => White, Tintable => True);
      Bell_Img : constant Image_Access := Load_SVG_Path
        (Bell_Path, Icon_Size,
         Fill => White, Tintable => True);
   begin
      if Heart /= null then
         Set_Image (UI.Tint_Default, Heart);
      end if;
      if Bolt /= null then
         Set_Image (UI.Tint_Warm, Bolt);
      end if;
      if Shield /= null then
         Set_Image (UI.Tint_Success, Shield);
      end if;
      if Bell_Img /= null then
         Set_Image (UI.Tint_Danger, Bell_Img);
      end if;
   end;

   A.Add_Window (W);
   A.Run;
end Image_Example;
