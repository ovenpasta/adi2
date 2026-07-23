--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

package Adi.SVG.Constants is

   Default_DPI            : constant Float := 96.0;
   Default_SVG_Width      : constant Float := 300.0;
   Default_SVG_Height     : constant Float := 150.0;

   Pi_Radians             : constant Float := 3.14159265358979323846;
   Full_Circle_Radians    : constant Float := 6.2831853071795864769;
   Degrees_To_Radians     : constant Float := Pi_Radians / 180.0;
   Sqrt_2                 : constant Float := 1.4142135623730950488;

   Default_AA_Scale       : constant Positive := 1;
   Arc_Max_Step_Radians   : constant Float := Pi_Radians / 8.0;

   Flatten_Flatness_Threshold : constant Float := 0.25;
   Flatten_Max_Depth          : constant Positive := 32;

   Cubic_Segment_Count    : constant Positive := 16;
   Quadratic_Segment_Count : constant Positive := 12;
   Circle_Segment_Count   : constant Positive := 48;
   Max_Scanline_Intersections : constant Positive := 2048;

   Point_Epsilon          : constant Float := 0.001;

end Adi.SVG.Constants;
