--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Box;
with Adi.Widget.Image;
with Adi.Window;

package Image_Example_UI is

   generic
   package Instance is

      Root : Adi.Widget.Box.Box_Widget_Access;
      Img_Svg_Path : Adi.Widget.Image.Image_Widget_Access;
      Img_Svg : Adi.Widget.Image.Image_Widget_Access;
      Img_Png : Adi.Widget.Image.Image_Widget_Access;
      Img_Jpg : Adi.Widget.Image.Image_Widget_Access;
      Fit_Fill : Adi.Widget.Image.Image_Widget_Access;
      Fit_Contain : Adi.Widget.Image.Image_Widget_Access;
      Fit_Cover : Adi.Widget.Image.Image_Widget_Access;
      Fit_None : Adi.Widget.Image.Image_Widget_Access;
      Fit_Scale_Down : Adi.Widget.Image.Image_Widget_Access;
      Tint_Default : Adi.Widget.Image.Image_Widget_Access;
      Tint_Warm : Adi.Widget.Image.Image_Widget_Access;
      Tint_Success : Adi.Widget.Image.Image_Widget_Access;
      Tint_Danger : Adi.Widget.Image.Image_Widget_Access;

      function Build return Adi.Window.Window_Access;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Image_Example_UI;
