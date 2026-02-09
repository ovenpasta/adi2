
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

package Adi.Core is
   pragma Elaborate_Body;
   type Pixel_Type is new Float;

   type Point is record
      X : Pixel_Type := 0.0;
      Y : Pixel_Type := 0.0;
   end record;

   type Mouse_Button is
     (Left_Button, Middle_Button, Right_Button, X1_Button, X2_Button);

   type Size_2D is record
      Width : Pixel_Type := 0.0;
      Height : Pixel_Type := 0.0;
   end record;

   type Rectangle is record
      X      : Pixel_Type := 0.0;
      Y      : Pixel_Type := 0.0;
      Width  : Pixel_Type := 0.0;
      Height : Pixel_Type := 0.0;
   end record;

   type Normalized is new Float range 0.0 .. 1.0;

   type Color is record
      R : Normalized := 0.0;
      G : Normalized := 0.0;
      B : Normalized := 0.0;
      A : Normalized := 1.0;
   end record;

   type Color_8 is record
      R : Unsigned_8 := 0;
      G : Unsigned_8 := 0;
      B : Unsigned_8 := 0;
      A : Unsigned_8 := 255;
   end record;

   function Color_R(C: Color) return Unsigned_8 is (Unsigned_8(C.R)*255);
   function Color_G(C: Color) return Unsigned_8 is (Unsigned_8(C.G)*255);
   function Color_B(C: Color) return Unsigned_8 is (Unsigned_8(C.B)*255);
   function Color_A(C: Color) return Unsigned_8 is (Unsigned_8(C.A)*255);
   function Normalize(C: Unsigned_8) return Normalized is (Normalized(Float(C)/255.0));
   function To_Unsigned_8(C: Normalized) return Unsigned_8 is (Unsigned_8(C*255.0));

   function To_Color(C: Color_8) return Color is ((Normalize(C.R),Normalize(C.G),Normalize(C.B),Normalize(C.A)));

    function Max (A, B : Size_2D) return Size_2D is
      ((Pixel_Type'Max(A.Width, B.Width), Pixel_Type'Max(A.Height, B.Height)));

   function Min (A, B : Size_2D) return Size_2D is
      ((Pixel_Type'Min(A.Width, B.Width), Pixel_Type'Min(A.Height, B.Height)));


end Adi.Core;
