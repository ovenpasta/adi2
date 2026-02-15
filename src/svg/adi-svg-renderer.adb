with Ada.Containers;
with Ada.Containers.Generic_Array_Sort;
with Ada.Numerics.Elementary_Functions;
with Adi.SVG.Constants;

package body Adi.SVG.Renderer is

   package Math renames Ada.Numerics.Elementary_Functions;

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;
   use type Ada.Containers.Count_Type;

   function To_U8 (V : Integer) return Interfaces.Unsigned_8 is
   begin
      if V < 0 then
         return 0;
      elsif V > 255 then
         return 255;
      else
         return Interfaces.Unsigned_8 (V);
      end if;
   end To_U8;

   function Pack_ARGB
     (A, R, G, B : Interfaces.Unsigned_8) return Uint32
   is
   begin
      return Uint32
        (Interfaces.Shift_Left (Interfaces.Unsigned_32 (A), 24)
         or Interfaces.Shift_Left (Interfaces.Unsigned_32 (R), 16)
         or Interfaces.Shift_Left (Interfaces.Unsigned_32 (G), 8)
         or Interfaces.Unsigned_32 (B));
   end Pack_ARGB;

   procedure Unpack_ARGB
     (V : Uint32;
      A, R, G, B : out Interfaces.Unsigned_8)
   is
      U : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (V);
   begin
      A := Interfaces.Unsigned_8 (Interfaces.Shift_Right (U, 24) and 16#FF#);
      R := Interfaces.Unsigned_8 (Interfaces.Shift_Right (U, 16) and 16#FF#);
      G := Interfaces.Unsigned_8 (Interfaces.Shift_Right (U, 8) and 16#FF#);
      B := Interfaces.Unsigned_8 (U and 16#FF#);
   end Unpack_ARGB;

   procedure Blend_Pixel
      (Pixels : in out Pixel_Buffer;
       Width  : Positive;
      Height : Positive;
      X      : Integer;
      Y      : Integer;
      Src    : Uint32)
   is
      pragma Unreferenced (Height);

      Idx : Natural;
      SA, SR, SG, SB : Interfaces.Unsigned_8;
      DA, DR, DG, DB : Interfaces.Unsigned_8;
      Out_A, Out_R, Out_G, Out_B : Integer;
      A : Integer;
      DU : Interfaces.Unsigned_32;
   begin
      if X < 0 or else Y < 0 or else X >= Width or else Y >= Height then
         return;
      end if;

      Idx := Natural (Y) * Width + Natural (X);
      Unpack_ARGB (Src, SA, SR, SG, SB);
      if SA = 0 then
         return;
      elsif SA = 255 then
         Pixels (Idx) := Src;
         return;
      end if;

       DU := Interfaces.Unsigned_32 (Pixels (Idx));
       if Interfaces.Shift_Right (DU, 24) = 0 then
          Pixels (Idx) := Src;
          return;
       end if;

      Unpack_ARGB (Pixels (Idx), DA, DR, DG, DB);
      A := Integer (SA);
      Out_A := A + (Integer (DA) * (255 - A) + 127) / 255;
      Out_R := (Integer (SR) * A + Integer (DR) * (255 - A) + 127) / 255;
      Out_G := (Integer (SG) * A + Integer (DG) * (255 - A) + 127) / 255;
      Out_B := (Integer (SB) * A + Integer (DB) * (255 - A) + 127) / 255;

      Pixels (Idx) := Pack_ARGB
        (To_U8 (Out_A), To_U8 (Out_R), To_U8 (Out_G), To_U8 (Out_B));
   end Blend_Pixel;

   function Apply_Opacity (Color : Uint32; Opacity : Float) return Uint32 is
      A, R, G, B : Interfaces.Unsigned_8;
      Out_A      : Integer;
      O          : Float := Opacity;
   begin
      if O < 0.0 then
         O := 0.0;
      elsif O > 1.0 then
         O := 1.0;
      end if;

      Unpack_ARGB (Color, A, R, G, B);
      Out_A := Integer (Float (A) * O);
      return Pack_ARGB (To_U8 (Out_A), R, G, B);
   end Apply_Opacity;

   procedure Draw_Line
     (Pixels : in out Pixel_Buffer;
      Width  : Positive;
      Height : Positive;
      X1, Y1, X2, Y2 : Float;
      Stroke : Uint32;
      Stroke_Width : Float)
   is
      DX : constant Float := X2 - X1;
      DY : constant Float := Y2 - Y1;
      Steps : constant Integer := Integer (Float'Max (abs DX, abs DY));
      Half : constant Integer := Integer (Float'Max (0.0, Stroke_Width * 0.5));

      function Round_To_Int (V : Float) return Integer is
      begin
         if V >= 0.0 then
            return Integer (Float'Floor (V + 0.5));
         else
            return Integer (Float'Ceiling (V - 0.5));
         end if;
      end Round_To_Int;
   begin
      if Steps <= 0 then
         Blend_Pixel (Pixels, Width, Height, Integer (X1), Integer (Y1), Stroke);
         return;
      end if;

      for I in 0 .. Steps loop
         declare
            T : constant Float := Float (I) / Float (Steps);
            PX : constant Integer := Round_To_Int (X1 + DX * T);
            PY : constant Integer := Round_To_Int (Y1 + DY * T);
         begin
            for OY in -Half .. Half loop
               for OX in -Half .. Half loop
                  Blend_Pixel (Pixels, Width, Height, PX + OX, PY + OY, Stroke);
               end loop;
            end loop;
         end;
      end loop;
   end Draw_Line;

   procedure Fill_Contours
     (Pixels   : in out Pixel_Buffer;
      Width    : Positive;
      Height   : Positive;
      Contours : Adi.SVG.Parser.Contour_Vectors.Vector;
      Rule     : Fill_Rule_Kind;
      Fill     : Uint32)
   is
      type Intersection is record
         X : Float;
         W : Integer;
      end record;

      type Intersection_Array is array (Positive range <>) of Intersection;

      function "<" (L, R : Intersection) return Boolean is (L.X < R.X);

      procedure Sort_Intersections is new Ada.Containers.Generic_Array_Sort
        (Index_Type   => Positive,
         Element_Type => Intersection,
         Array_Type   => Intersection_Array,
         "<"          => "<");

      Min_Y : Float := 0.0;
      Max_Y : Float := 0.0;
      Have_Bounds : Boolean := False;
      Edge_Capacity : Natural := 0;
   begin
      for C of Contours loop
         if Natural (C.Points.Length) >= 3 then
            Edge_Capacity := Edge_Capacity + Natural (C.Points.Length);
            for P of C.Points loop
               if not Have_Bounds then
                  Min_Y := P.Y;
                  Max_Y := P.Y;
                  Have_Bounds := True;
               else
                  Min_Y := Float'Min (Min_Y, P.Y);
                  Max_Y := Float'Max (Max_Y, P.Y);
               end if;
            end loop;
         end if;
      end loop;

      if not Have_Bounds or else Edge_Capacity = 0 then
         return;
      end if;

      declare
         Inter : Intersection_Array (1 .. Positive (Edge_Capacity));
         Fill_A : Interfaces.Unsigned_8;
         Dummy_R, Dummy_G, Dummy_B : Interfaces.Unsigned_8;

         procedure Fill_Span (Scan : Integer; X1, X2 : Float) is
            From_X : Integer;
            To_X   : Integer;
            L      : Integer;
            R      : Integer;
            Base   : Natural;
          begin
            if X2 <= X1 then
               return;
            end if;

            if Scan < 0 or else Scan >= Height then
               return;
            end if;

            From_X := Integer (Float'Floor (X1));
            To_X := Integer (Float'Ceiling (X2)) - 1;

            if Fill_A = 255 then
               L := Integer'Max (0, From_X);
               R := Integer'Min (Width - 1, To_X);
               if L > R then
                  return;
               end if;

               Base := Natural (Scan) * Width;
               for X in L .. R loop
                  Pixels (Base + Natural (X)) := Fill;
               end loop;
            else
               for X in From_X .. To_X loop
                  Blend_Pixel (Pixels, Width, Height, X, Scan, Fill);
               end loop;
            end if;
          end Fill_Span;
      begin
         Unpack_ARGB (Fill, Fill_A, Dummy_R, Dummy_G, Dummy_B);

         for Scan in Integer (Float'Floor (Min_Y)) .. Integer (Float'Ceiling (Max_Y)) - 1 loop
            declare
               Y : constant Float := Float (Scan) + 0.5;
               N : Natural := 0;
            begin
               for C of Contours loop
                  declare
                     Count : constant Natural := Natural (C.Points.Length);
                  begin
                     if Count >= 3 then
                        for I in 1 .. Count loop
                           declare
                              J : constant Positive := (if I = Count then 1 else I + 1);
                              P1 : constant Adi.SVG.Parser.Point := C.Points.Element (Positive (I));
                              P2 : constant Adi.SVG.Parser.Point := C.Points.Element (J);
                              Y1 : constant Float := P1.Y;
                              Y2 : constant Float := P2.Y;
                           begin
                              if (Y1 <= Y and then Y2 > Y) or else (Y2 <= Y and then Y1 > Y) then
                                 N := N + 1;
                                 Inter (N).X := P1.X + (Y - Y1) * (P2.X - P1.X) / (Y2 - Y1);
                                 Inter (N).W := (if Y2 > Y1 then 1 else -1);
                              end if;
                           end;
                        end loop;
                     end if;
                  end;
               end loop;

               if N >= 2 then
                  Sort_Intersections (Inter (1 .. Positive (N)));

                  if Rule = Even_Odd then
                     declare
                        K : Natural := 1;
                     begin
                        while K + 1 <= N loop
                           Fill_Span (Scan, Inter (K).X, Inter (K + 1).X);
                           K := K + 2;
                        end loop;
                     end;
                  else
                     declare
                        Winding : Integer := 0;
                     begin
                        for I in 1 .. N - 1 loop
                           Winding := Winding + Inter (I).W;
                           if Winding /= 0 then
                              Fill_Span (Scan, Inter (I).X, Inter (I + 1).X);
                           end if;
                        end loop;
                     end;
                  end if;
               end if;
            end;
         end loop;
      end;
   end Fill_Contours;

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
       Dash_Offset  : Float := 0.0)
   is
      procedure Draw_Filled_Circle
        (CX, CY : Float;
         Radius : Float)
      is
         R : constant Integer := Integer (Float'Ceiling (Float'Max (0.0, Radius)));
         RSQ : constant Float := Radius * Radius;
      begin
         if Radius <= 0.0 then
            return;
         end if;

         for Y in Integer (Float'Floor (CY)) - R .. Integer (Float'Floor (CY)) + R loop
            for X in Integer (Float'Floor (CX)) - R .. Integer (Float'Floor (CX)) + R loop
               declare
                  DX : constant Float := (Float (X) + 0.5) - CX;
                  DY : constant Float := (Float (Y) + 0.5) - CY;
               begin
                  if DX * DX + DY * DY <= RSQ then
                     Blend_Pixel (Pixels, Width, Height, X, Y, Stroke);
                  end if;
               end;
            end loop;
         end loop;
      end Draw_Filled_Circle;

      procedure Fill_Triangle
        (X1, Y1, X2, Y2, X3, Y3 : Float)
      is
         Min_X : constant Integer :=
           Integer (Float'Floor (Float'Min (X1, Float'Min (X2, X3))));
         Max_X : constant Integer :=
           Integer (Float'Ceiling (Float'Max (X1, Float'Max (X2, X3))));
         Min_Y : constant Integer :=
           Integer (Float'Floor (Float'Min (Y1, Float'Min (Y2, Y3))));
         Max_Y : constant Integer :=
           Integer (Float'Ceiling (Float'Max (Y1, Float'Max (Y2, Y3))));
      begin
         if abs ((X2 - X1) * (Y3 - Y1) - (Y2 - Y1) * (X3 - X1))
           <= Adi.SVG.Constants.Point_Epsilon
         then
            return;
         end if;

         for Y in Min_Y .. Max_Y loop
            for X in Min_X .. Max_X loop
               declare
                  PX : constant Float := Float (X) + 0.5;
                  PY : constant Float := Float (Y) + 0.5;
                  W1 : constant Float := (X2 - X1) * (PY - Y1) - (Y2 - Y1) * (PX - X1);
                  W2 : constant Float := (X3 - X2) * (PY - Y2) - (Y3 - Y2) * (PX - X2);
                  W3 : constant Float := (X1 - X3) * (PY - Y3) - (Y1 - Y3) * (PX - X3);
               begin
                  if (W1 >= 0.0 and then W2 >= 0.0 and then W3 >= 0.0)
                    or else (W1 <= 0.0 and then W2 <= 0.0 and then W3 <= 0.0)
                  then
                     Blend_Pixel (Pixels, Width, Height, X, Y, Stroke);
                  end if;
               end;
            end loop;
         end loop;
      end Fill_Triangle;

      type Vector_2D is record
         X : Float := 0.0;
         Y : Float := 0.0;
      end record;

      function Normalize (V : Vector_2D) return Vector_2D is
         L : constant Float := Math.Sqrt (V.X * V.X + V.Y * V.Y);
      begin
         if L <= Adi.SVG.Constants.Point_Epsilon then
            return (X => 0.0, Y => 0.0);
         else
            return (X => V.X / L, Y => V.Y / L);
         end if;
      end Normalize;

      function Left_Normal (V : Vector_2D) return Vector_2D is
        (X => -V.Y, Y => V.X);

      function Right_Normal (V : Vector_2D) return Vector_2D is
        (X => V.Y, Y => -V.X);

      function Cross (A, B : Vector_2D) return Float is
        (A.X * B.Y - A.Y * B.X);

      procedure Draw_Stroke_Segment
        (X1, Y1, X2, Y2 : Float;
         Start_Cap      : Stroke_Line_Cap_Kind;
         End_Cap        : Stroke_Line_Cap_Kind)
      is
         DX   : constant Float := X2 - X1;
         DY   : constant Float := Y2 - Y1;
         Len  : constant Float := Math.Sqrt (DX * DX + DY * DY);
         Half : constant Float := Float'Max (0.0, Stroke_Width * 0.5);
         SX1  : Float := X1;
         SY1  : Float := Y1;
         SX2  : Float := X2;
         SY2  : Float := Y2;
         UX   : Float := 0.0;
         UY   : Float := 0.0;
         Trim : Float := 0.0;
      begin
          if Len > 1.0E-6 then
             UX := DX / Len;
             UY := DY / Len;

             Trim := Float'Min (Half, Len * 0.5);
             SX1 := SX1 + UX * Trim;
             SY1 := SY1 + UY * Trim;
             SX2 := SX2 - UX * Trim;
             SY2 := SY2 - UY * Trim;

             if Start_Cap = Square_Cap then
                SX1 := SX1 - UX * Half;
                SY1 := SY1 - UY * Half;
             end if;
             if End_Cap = Square_Cap then
               SX2 := SX2 + UX * Half;
               SY2 := SY2 + UY * Half;
            end if;
         end if;

         Draw_Line (Pixels, Width, Height, SX1, SY1, SX2, SY2, Stroke, Stroke_Width);

         if Start_Cap = Round_Cap then
            Draw_Filled_Circle (X1, Y1, Half);
         end if;
         if End_Cap = Round_Cap then
            Draw_Filled_Circle (X2, Y2, Half);
         end if;
      end Draw_Stroke_Segment;

      procedure Add_Joins
        (C : Adi.SVG.Parser.Contour)
      is
          Half  : constant Float := Float'Max (0.0, Stroke_Width * 0.5);
          Count : constant Natural := Natural (C.Points.Length);

          procedure Draw_Join
            (Prev_P, Curr_P, Next_P : Adi.SVG.Parser.Point)
          is
             In_V  : constant Vector_2D :=
               Normalize ((X => Curr_P.X - Prev_P.X, Y => Curr_P.Y - Prev_P.Y));
             Out_V : constant Vector_2D :=
               Normalize ((X => Next_P.X - Curr_P.X, Y => Next_P.Y - Curr_P.Y));
             Turn  : constant Float := Cross (In_V, Out_V);

             N0, N1 : Vector_2D;
             O0X, O0Y : Float;
             O1X, O1Y : Float;

             Limit_Ratio : constant Float := Float'Max (1.0, Miter_Limit);
          begin
             if (abs In_V.X <= Adi.SVG.Constants.Point_Epsilon
                   and then abs In_V.Y <= Adi.SVG.Constants.Point_Epsilon)
               or else
                (abs Out_V.X <= Adi.SVG.Constants.Point_Epsilon
                   and then abs Out_V.Y <= Adi.SVG.Constants.Point_Epsilon)
             then
                return;
             end if;

             if Line_Join = Round_Join then
                Draw_Filled_Circle (Curr_P.X, Curr_P.Y, Half);
                return;
             end if;

             if abs Turn <= Adi.SVG.Constants.Point_Epsilon then
                return;
             end if;

             if Turn > 0.0 then
                N0 := Left_Normal (In_V);
                N1 := Left_Normal (Out_V);
             else
                N0 := Right_Normal (In_V);
                N1 := Right_Normal (Out_V);
             end if;

             O0X := Curr_P.X + N0.X * Half;
             O0Y := Curr_P.Y + N0.Y * Half;
             O1X := Curr_P.X + N1.X * Half;
             O1Y := Curr_P.Y + N1.Y * Half;

             if Line_Join = Bevel_Join then
                Fill_Triangle (O0X, O0Y, Curr_P.X, Curr_P.Y, O1X, O1Y);
             else
                declare
                   Den : constant Float := Cross (In_V, Out_V);
                begin
                   if abs Den <= Adi.SVG.Constants.Point_Epsilon then
                      Fill_Triangle (O0X, O0Y, Curr_P.X, Curr_P.Y, O1X, O1Y);
                   else
                      declare
                         DX : constant Float := O1X - O0X;
                         DY : constant Float := O1Y - O0Y;
                         T  : constant Float := (DX * Out_V.Y - DY * Out_V.X) / Den;
                         MX : constant Float := O0X + T * In_V.X;
                         MY : constant Float := O0Y + T * In_V.Y;
                         Miter_Len : constant Float :=
                           Math.Sqrt
                             ((MX - Curr_P.X) * (MX - Curr_P.X)
                              + (MY - Curr_P.Y) * (MY - Curr_P.Y));
                      begin
                         if Half > Adi.SVG.Constants.Point_Epsilon
                           and then Miter_Len / Half <= Limit_Ratio
                         then
                            Fill_Triangle (O0X, O0Y, MX, MY, O1X, O1Y);
                         else
                            Fill_Triangle (O0X, O0Y, Curr_P.X, Curr_P.Y, O1X, O1Y);
                         end if;
                      end;
                   end if;
                end;
             end if;
          end Draw_Join;
      begin
          if Half <= 0.0 or else Count = 0 then
             return;
          end if;

          if C.Closed and then Count >= 2 then
             for I in 1 .. Count loop
                declare
                   Prev_I : constant Positive :=
                     (if I = 1 then Positive (Count) else Positive (I - 1));
                   Next_I : constant Positive :=
                     (if I = Count then 1 else Positive (I + 1));
                begin
                   Draw_Join
                     (C.Points.Element (Prev_I),
                      C.Points.Element (Positive (I)),
                      C.Points.Element (Next_I));
                end;
             end loop;

          elsif Count >= 3 then
             for I in 2 .. Count - 1 loop
                Draw_Join
                  (C.Points.Element (Positive (I - 1)),
                   C.Points.Element (Positive (I)),
                   C.Points.Element (Positive (I + 1)));
             end loop;
          end if;
      end Add_Joins;

      package Local_Dash_Vectors renames Dash_Vectors;

      function Normalized_Dashes return Local_Dash_Vectors.Vector is
         Out_Dashes : Local_Dash_Vectors.Vector;
      begin
         for D of Dash_Array loop
            if D > 0.0 then
               Out_Dashes.Append (D);
            end if;
         end loop;

         if Out_Dashes.Length = 0 then
            return Out_Dashes;
         end if;

         if Out_Dashes.Length mod 2 = 1 then
            declare
               N : constant Natural := Natural (Out_Dashes.Length);
            begin
               for I in 1 .. N loop
                  Out_Dashes.Append (Out_Dashes.Element (Positive (I)));
               end loop;
            end;
         end if;

         return Out_Dashes;
      end Normalized_Dashes;

      Dashes : constant Local_Dash_Vectors.Vector := Normalized_Dashes;
      Use_Dash : constant Boolean := Dashes.Length > 0;
   begin
      if Stroke_Width <= 0.0 then
         return;
      end if;

      for C of Contours loop
         declare
            Count : constant Natural := Natural (C.Points.Length);

            procedure Draw_Dashed_Contour is
               Total_Dash : Float := 0.0;
               Dash_Idx   : Positive := 1;
               Dash_Left  : Float := 0.0;
               Drawing_On : Boolean := True;

               procedure Advance_Dash is
               begin
                  Dash_Idx := (if Dash_Idx = Positive (Dashes.Length) then 1 else Dash_Idx + 1);
                  Dash_Left := Dashes.Element (Dash_Idx);
                  Drawing_On := not Drawing_On;
               end Advance_Dash;

               procedure Draw_Dashed_Segment (P1, P2 : Adi.SVG.Parser.Point) is
                  DX  : constant Float := P2.X - P1.X;
                  DY  : constant Float := P2.Y - P1.Y;
                  Len : constant Float := Math.Sqrt (DX * DX + DY * DY);
                  Pos : Float := 0.0;
               begin
                  if Len <= 1.0E-6 then
                     return;
                  end if;

                  while Pos < Len - 1.0E-6 loop
                     if Dash_Left <= 1.0E-6 then
                        Advance_Dash;
                     end if;

                     declare
                        Step : constant Float := Float'Min (Dash_Left, Len - Pos);
                        T1   : constant Float := Pos / Len;
                        T2   : constant Float := (Pos + Step) / Len;
                        X1   : constant Float := P1.X + DX * T1;
                        Y1   : constant Float := P1.Y + DY * T1;
                        X2   : constant Float := P1.X + DX * T2;
                        Y2   : constant Float := P1.Y + DY * T2;
                     begin
                        if Drawing_On and then Step > 0.0 then
                           Draw_Stroke_Segment
                             (X1,
                              Y1,
                              X2,
                              Y2,
                              Start_Cap => Line_Cap,
                              End_Cap   => Line_Cap);
                        end if;

                        Pos := Pos + Step;
                        Dash_Left := Dash_Left - Step;
                     end;
                  end loop;
               end Draw_Dashed_Segment;

               Phase : Float := Dash_Offset;
            begin
               for D of Dashes loop
                  Total_Dash := Total_Dash + D;
               end loop;

               if Total_Dash <= 1.0E-6 then
                  return;
               end if;

               Phase := Phase - Float'Floor (Phase / Total_Dash) * Total_Dash;
               if Phase < 0.0 then
                  Phase := Phase + Total_Dash;
               end if;

               Dash_Idx := 1;
               Dash_Left := Dashes.Element (Dash_Idx);
               Drawing_On := True;

               while Phase > 1.0E-6 loop
                  if Phase >= Dash_Left then
                     Phase := Phase - Dash_Left;
                     Advance_Dash;
                  else
                     Dash_Left := Dash_Left - Phase;
                     Phase := 0.0;
                  end if;
               end loop;

               if Count >= 2 then
                  for I in 1 .. Count - 1 loop
                     Draw_Dashed_Segment
                       (C.Points.Element (Positive (I)),
                        C.Points.Element (Positive (I + 1)));
                  end loop;

                  if C.Closed then
                     Draw_Dashed_Segment
                       (C.Points.Element (Positive (Count)),
                        C.Points.Element (1));
                  end if;
               end if;
            end Draw_Dashed_Contour;

            procedure Draw_Solid_Contour is
            begin
               if Count < 2 then
                  return;
               end if;

               for I in 1 .. Count - 1 loop
                  declare
                     P1 : constant Adi.SVG.Parser.Point := C.Points.Element (Positive (I));
                     P2 : constant Adi.SVG.Parser.Point := C.Points.Element (Positive (I + 1));
                     Start_Cap : Stroke_Line_Cap_Kind := Butt_Cap;
                     End_Cap   : Stroke_Line_Cap_Kind := Butt_Cap;
                  begin
                     if not C.Closed then
                        if I = 1 then
                           Start_Cap := Line_Cap;
                        end if;
                        if I = Count - 1 then
                           End_Cap := Line_Cap;
                        end if;
                     end if;

                     Draw_Stroke_Segment
                       (P1.X,
                        P1.Y,
                        P2.X,
                        P2.Y,
                        Start_Cap,
                        End_Cap);
                  end;
               end loop;

               if C.Closed then
                  declare
                     P1 : constant Adi.SVG.Parser.Point := C.Points.Element (Positive (Count));
                     P2 : constant Adi.SVG.Parser.Point := C.Points.Element (1);
                  begin
                     Draw_Stroke_Segment (P1.X, P1.Y, P2.X, P2.Y, Butt_Cap, Butt_Cap);
                  end;
               end if;

                Add_Joins (C);
             end Draw_Solid_Contour;
         begin
            if Count >= 2 then
               if Use_Dash then
                  Draw_Dashed_Contour;
               else
                  Draw_Solid_Contour;
               end if;
            end if;
         end;
      end loop;
   end Stroke_Contours;

   function Downsample
     (Source       : Pixel_Buffer_Access;
      Source_Width : Positive;
      Source_Height : Positive;
      Target_Width : Positive;
      Target_Height : Positive;
      Scale        : Positive) return Pixel_Buffer_Access
   is
      pragma Unreferenced (Source_Height);
      Out_Pixels : Pixel_Buffer_Access := new Pixel_Buffer (0 .. Target_Width * Target_Height - 1);
      Samples    : constant Integer := Scale * Scale;
   begin
      for Y in 0 .. Target_Height - 1 loop
         for X in 0 .. Target_Width - 1 loop
            declare
               Sum_A  : Integer := 0;
               Sum_PR : Integer := 0;
               Sum_PG : Integer := 0;
               Sum_PB : Integer := 0;
            begin
               for SY in 0 .. Scale - 1 loop
                  for SX in 0 .. Scale - 1 loop
                     declare
                        Src_X : constant Integer := X * Scale + SX;
                        Src_Y : constant Integer := Y * Scale + SY;
                        Src_Idx : constant Natural := Natural (Src_Y * Source_Width + Src_X);
                        A, R, G, B : Interfaces.Unsigned_8;
                     begin
                        Unpack_ARGB (Source (Src_Idx), A, R, G, B);
                        declare
                           AI : constant Integer := Integer (A);
                        begin
                           Sum_A := Sum_A + AI;
                           Sum_PR := Sum_PR + Integer (R) * AI;
                           Sum_PG := Sum_PG + Integer (G) * AI;
                           Sum_PB := Sum_PB + Integer (B) * AI;
                        end;
                     end;
                  end loop;
               end loop;

               declare
                  Out_A : constant Integer := (Sum_A + Samples / 2) / Samples;
                  Out_R : Integer := 0;
                  Out_G : Integer := 0;
                  Out_B : Integer := 0;
               begin
                  if Sum_A > 0 then
                     Out_R := (Sum_PR + Sum_A / 2) / Sum_A;
                     Out_G := (Sum_PG + Sum_A / 2) / Sum_A;
                     Out_B := (Sum_PB + Sum_A / 2) / Sum_A;
                  end if;

                  Out_Pixels (Natural (Y * Target_Width + X)) :=
                    Pack_ARGB
                      (To_U8 (Out_A),
                       To_U8 (Out_R),
                       To_U8 (Out_G),
                       To_U8 (Out_B));
               end;
            end;
         end loop;
      end loop;

      return Out_Pixels;
   end Downsample;

end Adi.SVG.Renderer;
