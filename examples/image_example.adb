pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.Core;
with Adi.Image;        use Adi.Image;
with Adi.MCP;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Window;       use Adi.Window;
with Image_Example_UI;

procedure Image_Example is
   A : Adi.App.App;
   package UI is new Image_Example_UI.Instance;
   W : Window_Handle;

   --  Material Icons "star" 24x24 path
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
     "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5"
     & "c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5"
     & "s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16"
     & "v-1l-2-2z";

   Icon_Size : constant Adi.Core.Size_2D := (24.0, 24.0);
   White     : constant Adi.Core.Color_8 := (255, 255, 255, 255);

   --  The widgets below draw through handles, which keep nothing. These
   --  owners are what hold the images, so they are declared out here and
   --  live as long as the application does. Loading needs SDL up, so the
   --  loads themselves happen after A.Init rather than here.
   Svg_Path_Img, Svg_Img, Png_Img, Jpg_Img, Cat : Adi.Image.Image_Owner;
   Heart, Bolt, Shield, Bell_Img                : Adi.Image.Image_Owner;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);
   W := UI.Build;

   --  Load SVG path image
   Svg_Path_Img := Adi.Image.Load_SVG_Path
          (Path_Data => Star_Path,
           Size      => (Width => 128.0, Height => 128.0),
           Fill      => (R => 255, G => 200, B => 0, A => 255));
   if Adi.Image.Is_Owned (Svg_Path_Img) then
      Set_Image (UI.Img_Svg_Path, Adi.Image.To_Handle (Svg_Path_Img));
   end if;

   --  Load SVG file
   Svg_Img := Adi.Image.Load_From_File ("examples/assets/tiger.svg");
   if Adi.Image.Is_Owned (Svg_Img) then
      Set_Image (UI.Img_Svg, Adi.Image.To_Handle (Svg_Img));
   end if;

   --  Load PNG file
   Png_Img := Adi.Image.Load_From_File ("examples/assets/happycat.png");
   if Adi.Image.Is_Owned (Png_Img) then
      Set_Image (UI.Img_Png, Adi.Image.To_Handle (Png_Img));
   end if;

   --  Load JPG file
   Jpg_Img := Adi.Image.Load_From_File ("examples/assets/bg.jpg");
   if Adi.Image.Is_Owned (Jpg_Img) then
      Set_Image (UI.Img_Jpg, Adi.Image.To_Handle (Jpg_Img));
   end if;

   --  Load happycat.png for all object-fit mode demos
   Cat := Adi.Image.Load_From_File ("examples/assets/happycat.png");
   if Adi.Image.Is_Owned (Cat) then
      Set_Image (UI.Fit_Fill, Adi.Image.To_Handle (Cat));
      Set_Image (UI.Fit_Contain, Adi.Image.To_Handle (Cat));
      Set_Image (UI.Fit_Cover, Adi.Image.To_Handle (Cat));
      Set_Image (UI.Fit_None, Adi.Image.To_Handle (Cat));
      Set_Image (UI.Fit_Scale_Down, Adi.Image.To_Handle (Cat));
   end if;

   --  Load tintable SVG path icons (white on transparent, tinted by CSS color)
   Heart := Load_SVG_Path
        (Heart_Path, Icon_Size,
         Fill => White, Tintable => True);
   Bolt := Load_SVG_Path
        (Bolt_Path, Icon_Size,
         Fill => White, Tintable => True);
   Shield := Load_SVG_Path
        (Shield_Path, Icon_Size,
         Fill => White, Tintable => True);
   Bell_Img := Load_SVG_Path
        (Bell_Path, Icon_Size,
         Fill => White, Tintable => True);
   if Adi.Image.Is_Owned (Heart) then
      Set_Image (UI.Tint_Default, Adi.Image.To_Handle (Heart));
   end if;
   if Adi.Image.Is_Owned (Bolt) then
      Set_Image (UI.Tint_Warm, Adi.Image.To_Handle (Bolt));
   end if;
   if Adi.Image.Is_Owned (Shield) then
      Set_Image (UI.Tint_Success, Adi.Image.To_Handle (Shield));
   end if;
   if Adi.Image.Is_Owned (Bell_Img) then
      Set_Image (UI.Tint_Danger, Adi.Image.To_Handle (Bell_Img));
   end if;

   Adi.MCP.Initialize (W);

   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Image_Example;
