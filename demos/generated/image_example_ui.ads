--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Box;
with Adi.Widget.Image;
with Adi.Window;

package Image_Example_UI is

   generic
   package Instance is

      Root : Adi.Widget.Box.Box_Handle;
      Img_Svg_Path : Adi.Widget.Image.Image_Handle;
      Img_Svg : Adi.Widget.Image.Image_Handle;
      Img_Png : Adi.Widget.Image.Image_Handle;
      Img_Jpg : Adi.Widget.Image.Image_Handle;
      Fit_Fill : Adi.Widget.Image.Image_Handle;
      Fit_Contain : Adi.Widget.Image.Image_Handle;
      Fit_Cover : Adi.Widget.Image.Image_Handle;
      Fit_None : Adi.Widget.Image.Image_Handle;
      Fit_Scale_Down : Adi.Widget.Image.Image_Handle;
      Tint_Default : Adi.Widget.Image.Image_Handle;
      Tint_Warm : Adi.Widget.Image.Image_Handle;
      Tint_Success : Adi.Widget.Image.Image_Handle;
      Tint_Danger : Adi.Widget.Image.Image_Handle;

      function Build return Adi.Window.Window_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Image_Example_UI;
