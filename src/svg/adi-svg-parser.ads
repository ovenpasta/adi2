--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Ada.Containers.Vectors;

package Adi.SVG.Parser is

   type Matrix is record
      A, B, C, D, E, F : Float;
   end record;

   function Identity_Matrix return Matrix;
   function Multiply_Matrix (Left, Right : Matrix) return Matrix;
   procedure Map_Point
     (M : Matrix;
      X : Float;
      Y : Float;
      Out_X : out Float;
      Out_Y : out Float);
   function Matrix_Scale (M : Matrix) return Float;
   function Clamp01 (V : Float) return Float;

   function Is_WS (C : Character) return Boolean;

   function Parse_Number (S : String; Default : Float := 0.0) return Float;
   function Parse_Length
     (S         : String;
      Axis_Size : Float;
      Default   : Float := 0.0) return Float;

   function Find_Tag_End
     (Source : String;
      Open_Pos : Positive) return Natural;

   function Attribute_Value (Tag : String; Name : String) return String;
   function Tag_Name (Tag : String) return String;
   function Is_Closing_Tag (Tag : String) return Boolean;
   function Is_Self_Closing_Tag (Tag : String) return Boolean;
   function Is_Container_Name (Name : String) return Boolean;

   type Point is record
      X : Float := 0.0;
      Y : Float := 0.0;
   end record;

   package Point_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Point);

   type Contour is record
      Points : Point_Vectors.Vector;
      Closed : Boolean := False;
   end record;

   package Contour_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Contour);

   function Parse_Transform (Value : String) return Matrix;

   function Build_Path_Contours
     (D : String;
      M : Matrix) return Contour_Vectors.Vector;

end Adi.SVG.Parser;
