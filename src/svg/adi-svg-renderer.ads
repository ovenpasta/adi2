with Ada.Containers.Vectors;
with Adi.SVG.Parser;
with Adi.SDL; use Adi.SDL;
with Interfaces;

package Adi.SVG.Renderer is

   type Fill_Rule_Kind is (Non_Zero, Even_Odd);

   type Stroke_Line_Cap_Kind is (Butt_Cap, Round_Cap, Square_Cap);
   type Stroke_Line_Join_Kind is (Miter_Join, Round_Join, Bevel_Join);

   package Dash_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Float);

   function To_U8 (V : Integer) return Interfaces.Unsigned_8;

   function Pack_ARGB
     (A, R, G, B : Interfaces.Unsigned_8) return Uint32;

   procedure Unpack_ARGB
     (V : Uint32;
      A, R, G, B : out Interfaces.Unsigned_8);

   procedure Blend_Pixel
     (Pixels : in out Pixel_Buffer;
      Width  : Positive;
      Height : Positive;
      X      : Integer;
      Y      : Integer;
      Src    : Uint32);

   function Apply_Opacity (Color : Uint32; Opacity : Float) return Uint32;

   procedure Draw_Line
     (Pixels : in out Pixel_Buffer;
      Width  : Positive;
      Height : Positive;
      X1, Y1, X2, Y2 : Float;
      Stroke : Uint32;
      Stroke_Width : Float);

   procedure Fill_Contours
     (Pixels   : in out Pixel_Buffer;
      Width    : Positive;
      Height   : Positive;
      Contours : Adi.SVG.Parser.Contour_Vectors.Vector;
      Rule     : Fill_Rule_Kind;
      Fill     : Uint32);

   procedure Stroke_Contours
      (Pixels   : in out Pixel_Buffer;
       Width    : Positive;
       Height   : Positive;
       Contours : Adi.SVG.Parser.Contour_Vectors.Vector;
       Stroke   : Uint32;
       Stroke_Width : Float;
       Line_Cap     : Stroke_Line_Cap_Kind := Butt_Cap;
       Line_Join    : Stroke_Line_Join_Kind := Miter_Join;
       Miter_Limit  : Float := 4.0;
       Dash_Array   : Dash_Vectors.Vector := Dash_Vectors.Empty_Vector;
       Dash_Offset  : Float := 0.0);

   function Downsample
     (Source       : Pixel_Buffer_Access;
      Source_Width : Positive;
      Source_Height : Positive;
      Target_Width : Positive;
      Target_Height : Positive;
      Scale        : Positive) return Pixel_Buffer_Access;

end Adi.SVG.Renderer;
