pragma Ada_2022;

with Adi.App;
with Adi.Image;  use Adi.Image;
with Adi.Window; use Adi.Window;
with Image_Example_UI;

procedure Image_Example is
   A : Adi.App.App;
   package UI is new Image_Example_UI.Instance;
   W : Window_Access;

   --  Material Symbols "star" 24x24 path
   Star_Path : constant String :=
     "M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 "
     & "9.19 8.63 2 9.24l5.46 4.73L5.82 21z";
begin
   A.Init;
   A.Set_Target_FPS (60);
   W := UI.Build;

   --  Load SVG path image
   declare
      Svg_Path_Img : constant Adi.Image.Image_Access :=
        Adi.Image.Load_SVG_Path
          (Renderer  => W.Get_Renderer,
           Path_Data => Star_Path,
           Size      => (Width => 128.0, Height => 128.0),
           Fill      => (R => 255, G => 200, B => 0, A => 255));
   begin
      if Svg_Path_Img /= null then
         UI.Img_Svg_Path.Set_Image (Svg_Path_Img);
      end if;
   end;

   --  Load SVG file
   declare
      Svg_Img : constant Adi.Image.Image_Access :=
        W.Load_Image ("examples/assets/tiger.svg");
   begin
      if Svg_Img /= null then
         UI.Img_Svg.Set_Image (Svg_Img);
      end if;
   end;

   --  Load PNG file
   declare
      Png_Img : constant Adi.Image.Image_Access :=
        W.Load_Image ("examples/assets/happycat.png");
   begin
      if Png_Img /= null then
         UI.Img_Png.Set_Image (Png_Img);
      end if;
   end;

   --  Load JPG file
   declare
      Jpg_Img : constant Adi.Image.Image_Access :=
        W.Load_Image ("examples/assets/bg.jpg");
   begin
      if Jpg_Img /= null then
         UI.Img_Jpg.Set_Image (Jpg_Img);
      end if;
   end;

   --  Load happycat.png for all object-fit mode demos
   declare
      Cat : constant Adi.Image.Image_Access :=
        W.Load_Image ("examples/assets/happycat.png");
   begin
      if Cat /= null then
         UI.Fit_Fill.Set_Image (Cat);
         UI.Fit_Contain.Set_Image (Cat);
         UI.Fit_Cover.Set_Image (Cat);
         UI.Fit_None.Set_Image (Cat);
         UI.Fit_Scale_Down.Set_Image (Cat);
      end if;
   end;

   A.Add_Window (W);
   A.Run;
end Image_Example;
