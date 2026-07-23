--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Ada.Characters.Handling;
with Ada.Numerics.Elementary_Functions;
with Ada.Strings.Fixed;
with Adi.SVG.Constants;

package body Adi.SVG.Parser is

   package Ch renames Ada.Characters.Handling;
   package Fix renames Ada.Strings.Fixed;
   package Math renames Ada.Numerics.Elementary_Functions;

   function Identity_Matrix return Matrix is
     ((A => 1.0, B => 0.0, C => 0.0, D => 1.0, E => 0.0, F => 0.0));

   function Multiply_Matrix (Left, Right : Matrix) return Matrix is
   begin
      return
        (A => Left.A * Right.A + Left.C * Right.B,
         B => Left.B * Right.A + Left.D * Right.B,
         C => Left.A * Right.C + Left.C * Right.D,
         D => Left.B * Right.C + Left.D * Right.D,
         E => Left.A * Right.E + Left.C * Right.F + Left.E,
         F => Left.B * Right.E + Left.D * Right.F + Left.F);
   end Multiply_Matrix;

   procedure Map_Point
     (M : Matrix;
      X : Float;
      Y : Float;
      Out_X : out Float;
      Out_Y : out Float)
   is
   begin
      Out_X := M.A * X + M.C * Y + M.E;
      Out_Y := M.B * X + M.D * Y + M.F;
   end Map_Point;

   function Matrix_Scale (M : Matrix) return Float is
      SX : constant Float := Math.Sqrt (M.A * M.A + M.B * M.B);
      SY : constant Float := Math.Sqrt (M.C * M.C + M.D * M.D);
   begin
      if SX <= 0.0 and then SY <= 0.0 then
         return 1.0;
      elsif SX <= 0.0 then
         return SY;
      elsif SY <= 0.0 then
         return SX;
      else
         return Math.Sqrt (SX * SX + SY * SY) / Constants.Sqrt_2;
      end if;
   end Matrix_Scale;

   function Clamp01 (V : Float) return Float is
   begin
      if V < 0.0 then
         return 0.0;
      elsif V > 1.0 then
         return 1.0;
      else
         return V;
      end if;
   end Clamp01;

   function Is_WS (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Parse_Number (S : String; Default : Float := 0.0) return Float is
   begin
      return Float'Value (Fix.Trim (S, Ada.Strings.Both));
   exception
      when others =>
         return Default;
   end Parse_Number;

   function Parse_Length
     (S         : String;
      Axis_Size : Float;
      Default   : Float := 0.0) return Float
   is
      T : constant String := Fix.Trim (S, Ada.Strings.Both);
   begin
      if T'Length = 0 then
         return Default;
      elsif T (T'Last) = '%' then
         return Parse_Number (T (T'First .. T'Last - 1), Default) * Axis_Size / 100.0;
      elsif T'Length > 2 and then Ch.To_Lower (T (T'Last - 1 .. T'Last)) = "px" then
         return Parse_Number (T (T'First .. T'Last - 2), Default);
      elsif T'Length > 2 and then Ch.To_Lower (T (T'Last - 1 .. T'Last)) = "pc" then
         return Parse_Number (T (T'First .. T'Last - 2), Default) * Constants.Default_DPI / 6.0;
      elsif T'Length > 2 and then Ch.To_Lower (T (T'Last - 1 .. T'Last)) = "pt" then
         return Parse_Number (T (T'First .. T'Last - 2), Default) * Constants.Default_DPI / 72.0;
      elsif T'Length > 2 and then Ch.To_Lower (T (T'Last - 1 .. T'Last)) = "in" then
         return Parse_Number (T (T'First .. T'Last - 2), Default) * Constants.Default_DPI;
      elsif T'Length > 2 and then Ch.To_Lower (T (T'Last - 1 .. T'Last)) = "cm" then
         return Parse_Number (T (T'First .. T'Last - 2), Default) * Constants.Default_DPI / 2.54;
      elsif T'Length > 2 and then Ch.To_Lower (T (T'Last - 1 .. T'Last)) = "mm" then
         return Parse_Number (T (T'First .. T'Last - 2), Default) * Constants.Default_DPI / 25.4;
      else
         return Parse_Number (T, Default);
      end if;
   end Parse_Length;

   function Find_Tag_End
     (Source : String;
      Open_Pos : Positive) return Natural
   is
      I        : Positive := Open_Pos;
      In_Quote : Character := ASCII.NUL;
   begin
      while I <= Source'Last loop
         if In_Quote = ASCII.NUL then
            if Source (I) = '"' or else Source (I) = ''' then
               In_Quote := Source (I);
            elsif Source (I) = '>' then
               return I;
            end if;
         elsif Source (I) = In_Quote then
            In_Quote := ASCII.NUL;
         end if;

         I := I + 1;
      end loop;

      return 0;
   end Find_Tag_End;

   function Attribute_Value (Tag : String; Name : String) return String is
      N : constant String := Ch.To_Lower (Name);
      I : Integer := Tag'First;
   begin
      while I <= Tag'Last loop
         while I <= Tag'Last and then Is_WS (Tag (I)) loop
            I := I + 1;
         end loop;
         exit when I > Tag'Last;

         declare
            K_Start : constant Integer := I;
         begin
            while I <= Tag'Last and then not Is_WS (Tag (I)) and then Tag (I) /= '=' loop
               I := I + 1;
            end loop;

            if I <= Tag'Last and then Tag (I) = '=' then
               declare
                  K : constant String := Ch.To_Lower (Tag (K_Start .. I - 1));
               begin
                  I := I + 1;
                  while I <= Tag'Last and then Is_WS (Tag (I)) loop
                     I := I + 1;
                  end loop;
                  if I > Tag'Last then
                     exit;
                  end if;

                  if Tag (I) = '"' or else Tag (I) = ''' then
                     declare
                        Q : constant Character := Tag (I);
                        V_Start : Integer;
                     begin
                        I := I + 1;
                        V_Start := I;
                        while I <= Tag'Last and then Tag (I) /= Q loop
                           I := I + 1;
                        end loop;
                        if I <= Tag'Last and then K = N then
                           return Tag (V_Start .. I - 1);
                        end if;
                        I := I + 1;
                     end;
                  else
                     declare
                        V_Start : constant Integer := I;
                     begin
                        while I <= Tag'Last and then not Is_WS (Tag (I)) loop
                           I := I + 1;
                        end loop;
                        if K = N then
                           return Tag (V_Start .. I - 1);
                        end if;
                     end;
                  end if;
               end;
            else
               while I <= Tag'Last and then not Is_WS (Tag (I)) loop
                  I := I + 1;
               end loop;
            end if;
         end;
      end loop;

      return "";
   end Attribute_Value;

   function Tag_Name (Tag : String) return String is
      T : constant String := Fix.Trim (Tag, Ada.Strings.Both);
      I : Integer := T'First;
      J : Integer;
   begin
      if T'Length = 0 then
         return "";
      end if;

      if T (I) = '/' then
         I := I + 1;
      end if;

      J := I;
      while J <= T'Last and then not Is_WS (T (J)) and then T (J) /= '/' loop
         J := J + 1;
      end loop;

      if J <= I then
         return "";
      end if;

      return Ch.To_Lower (T (I .. J - 1));
   end Tag_Name;

   function Is_Closing_Tag (Tag : String) return Boolean is
      T : constant String := Fix.Trim (Tag, Ada.Strings.Both);
   begin
      return T'Length > 0 and then T (T'First) = '/';
   end Is_Closing_Tag;

   function Is_Self_Closing_Tag (Tag : String) return Boolean is
      T : constant String := Fix.Trim (Tag, Ada.Strings.Both);
   begin
      return T'Length > 0 and then T (T'Last) = '/';
   end Is_Self_Closing_Tag;

   function Is_Container_Name (Name : String) return Boolean is
   begin
      return Name = "svg"
        or else Name = "g"
        or else Name = "symbol"
        or else Name = "defs";
   end Is_Container_Name;

   procedure Skip_Separators
     (S            : String;
      Pos          : in out Integer;
      Allow_Comma  : Boolean := True)
   is
   begin
      while Pos <= S'Last loop
         exit when not Is_WS (S (Pos)) and then (not Allow_Comma or else S (Pos) /= ',');
         Pos := Pos + 1;
      end loop;
   end Skip_Separators;

   function Has_Number (S : String; Pos : Integer) return Boolean is
      P : Integer := Pos;
   begin
      Skip_Separators (S, P, Allow_Comma => True);
      if P > S'Last then
         return False;
      end if;

      return S (P) in '+' | '-' | '.' | '0' .. '9';
   end Has_Number;

   function Read_Number
     (S   : String;
      Pos : in out Integer;
      V   : out Float) return Boolean
   is
      Start : Integer;
      P     : Integer := Pos;
      Saw_Digit : Boolean := False;
   begin
      Skip_Separators (S, P, Allow_Comma => True);
      if P > S'Last then
         return False;
      end if;

      Start := P;
      if S (P) = '+' or else S (P) = '-' then
         P := P + 1;
      end if;

      while P <= S'Last and then S (P) in '0' .. '9' loop
         Saw_Digit := True;
         P := P + 1;
      end loop;

      if P <= S'Last and then S (P) = '.' then
         P := P + 1;
         while P <= S'Last and then S (P) in '0' .. '9' loop
            Saw_Digit := True;
            P := P + 1;
         end loop;
      end if;

      if not Saw_Digit then
         return False;
      end if;

      if P <= S'Last and then (S (P) = 'e' or else S (P) = 'E') then
         declare
            E_Pos : Integer := P + 1;
            E_Dig : Boolean := False;
         begin
            if E_Pos <= S'Last and then (S (E_Pos) = '+' or else S (E_Pos) = '-') then
               E_Pos := E_Pos + 1;
            end if;

            while E_Pos <= S'Last and then S (E_Pos) in '0' .. '9' loop
               E_Dig := True;
               E_Pos := E_Pos + 1;
            end loop;

            if E_Dig then
               P := E_Pos;
            end if;
         end;
      end if;

      begin
         V := Float'Value (S (Start .. P - 1));
      exception
         when others =>
            return False;
      end;

      Pos := P;
      return True;
   end Read_Number;

   function Parse_Transform (Value : String) return Matrix is
      T   : constant String := Fix.Trim (Value, Ada.Strings.Both);
      Pos : Integer := T'First;
      Out_M : Matrix := Identity_Matrix;
   begin
      while Pos <= T'Last loop
         Skip_Separators (T, Pos, Allow_Comma => False);
         exit when Pos > T'Last;

         declare
            Name_Start : constant Integer := Pos;
            Name_End   : Integer := Pos;
         begin
            while Name_End <= T'Last and then T (Name_End) in 'a' .. 'z' | 'A' .. 'Z' loop
               Name_End := Name_End + 1;
            end loop;

            exit when Name_End <= Name_Start;

            declare
               Name : constant String := Ch.To_Lower (T (Name_Start .. Name_End - 1));
               Op   : Matrix := Identity_Matrix;
            begin
               Pos := Name_End;
               Skip_Separators (T, Pos, Allow_Comma => False);
               if Pos > T'Last or else T (Pos) /= '(' then
                  exit;
               end if;
               Pos := Pos + 1;

               if Name = "matrix" then
                  declare
                     A, B, C, D, E, F : Float := 0.0;
                  begin
                     if Read_Number (T, Pos, A)
                       and then Read_Number (T, Pos, B)
                       and then Read_Number (T, Pos, C)
                       and then Read_Number (T, Pos, D)
                       and then Read_Number (T, Pos, E)
                       and then Read_Number (T, Pos, F)
                     then
                        Op := (A => A, B => B, C => C, D => D, E => E, F => F);
                     end if;
                  end;

               elsif Name = "translate" then
                  declare
                     TX : Float := 0.0;
                     TY : Float := 0.0;
                  begin
                     if Read_Number (T, Pos, TX) then
                        if not Read_Number (T, Pos, TY) then
                           TY := 0.0;
                        end if;
                        Op := (A => 1.0, B => 0.0, C => 0.0, D => 1.0, E => TX, F => TY);
                     end if;
                  end;

               elsif Name = "scale" then
                  declare
                     SX : Float := 1.0;
                     SY : Float := 1.0;
                  begin
                     if Read_Number (T, Pos, SX) then
                        if not Read_Number (T, Pos, SY) then
                           SY := SX;
                        end if;
                        Op := (A => SX, B => 0.0, C => 0.0, D => SY, E => 0.0, F => 0.0);
                     end if;
                  end;

               elsif Name = "rotate" then
                  declare
                     Angle_Deg : Float := 0.0;
                     Cx : Float := 0.0;
                     Cy : Float := 0.0;
                     Has_Center : Boolean := False;
                     A : Float;
                     Cos_A : Float;
                     Sin_A : Float;
                     Rm : Matrix;
                     T1 : Matrix;
                     T2 : Matrix;
                  begin
                     if Read_Number (T, Pos, Angle_Deg) then
                        if Read_Number (T, Pos, Cx) and then Read_Number (T, Pos, Cy) then
                           Has_Center := True;
                        end if;

                        A := Angle_Deg * Constants.Degrees_To_Radians;
                        Cos_A := Math.Cos (A);
                        Sin_A := Math.Sin (A);
                        Rm := (A => Cos_A, B => Sin_A, C => -Sin_A, D => Cos_A, E => 0.0, F => 0.0);

                        if Has_Center then
                           T1 := (A => 1.0, B => 0.0, C => 0.0, D => 1.0, E => Cx, F => Cy);
                           T2 := (A => 1.0, B => 0.0, C => 0.0, D => 1.0, E => -Cx, F => -Cy);
                           Op := Multiply_Matrix (Multiply_Matrix (T1, Rm), T2);
                        else
                           Op := Rm;
                        end if;
                     end if;
                  end;

               elsif Name = "skewx" then
                  declare
                     Angle_Deg : Float := 0.0;
                     S : Float;
                  begin
                     if Read_Number (T, Pos, Angle_Deg) then
                        S := Math.Tan (Angle_Deg * Constants.Degrees_To_Radians);
                        Op := (A => 1.0, B => 0.0, C => S, D => 1.0, E => 0.0, F => 0.0);
                     end if;
                  end;

               elsif Name = "skewy" then
                  declare
                     Angle_Deg : Float := 0.0;
                     S : Float;
                  begin
                     if Read_Number (T, Pos, Angle_Deg) then
                        S := Math.Tan (Angle_Deg * Constants.Degrees_To_Radians);
                        Op := (A => 1.0, B => S, C => 0.0, D => 1.0, E => 0.0, F => 0.0);
                     end if;
                  end;
               end if;

               while Pos <= T'Last and then T (Pos) /= ')' loop
                  Pos := Pos + 1;
               end loop;
               if Pos <= T'Last and then T (Pos) = ')' then
                  Pos := Pos + 1;
               end if;

               Out_M := Multiply_Matrix (Out_M, Op);
            end;
         end;
      end loop;

      return Out_M;
   end Parse_Transform;

   function Build_Path_Contours
     (D : String;
      M : Matrix) return Contour_Vectors.Vector
   is
      use type Ada.Containers.Count_Type;

      Contours : Contour_Vectors.Vector;
      Pos : Integer := D'First;
      Cmd : Character := ASCII.NUL;

      Current : Contour;
      CX, CY  : Float := 0.0;
      SX0, SY0 : Float := 0.0;
      Has_Subpath : Boolean := False;

      Prev_C2_X, Prev_C2_Y : Float := 0.0;
      Prev_Q_X, Prev_Q_Y   : Float := 0.0;
      Has_Prev_Cubic : Boolean := False;
      Has_Prev_Quad  : Boolean := False;

      procedure Add_Transformed_Point
        (C : in out Contour;
         X : Float;
         Y : Float)
      is
         TX, TY : Float;
      begin
         Map_Point (M, X, Y, TX, TY);

         if C.Points.Length > 0 then
            declare
               Last_P : constant Point := C.Points.Last_Element;
            begin
               if abs (Last_P.X - TX) < Constants.Point_Epsilon
                 and then abs (Last_P.Y - TY) < Constants.Point_Epsilon
               then
                  return;
               end if;
            end;
         end if;

         C.Points.Append (Point'(X => TX, Y => TY));
      end Add_Transformed_Point;

      procedure Flush_Current (Closed : Boolean := False) is
      begin
         if Current.Points.Length > 0 then
            Current.Closed := Closed;
            Contours.Append (Current);
            Current.Points.Clear;
            Current.Closed := False;
         end if;
      end Flush_Current;

      procedure Start_Subpath (X, Y : Float) is
      begin
         if Has_Subpath then
            Flush_Current;
         end if;
         Has_Subpath := True;
         CX := X;
         CY := Y;
         SX0 := X;
         SY0 := Y;
         Add_Transformed_Point (Current, X, Y);
      end Start_Subpath;

      procedure Line_To (X, Y : Float) is
      begin
         if not Has_Subpath then
            Start_Subpath (X, Y);
         else
            Add_Transformed_Point (Current, X, Y);
            CX := X;
            CY := Y;
         end if;
      end Line_To;

      procedure Add_Device_Point
        (C : in out Contour;
         X : Float;
         Y : Float)
      is
      begin
         if C.Points.Length > 0 then
            declare
               Last_P : constant Point := C.Points.Last_Element;
            begin
               if abs (Last_P.X - X) < Constants.Point_Epsilon
                 and then abs (Last_P.Y - Y) < Constants.Point_Epsilon
               then
                  return;
               end if;
            end;
         end if;

         C.Points.Append (Point'(X => X, Y => Y));
      end Add_Device_Point;

      procedure Cubic_To
        (X1, Y1, X2, Y2, X3, Y3 : Float)
      is
         type Cubic_Device is record
            X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Float;
         end record;

         procedure Split_Cubic
           (B      : Cubic_Device;
            First  : out Cubic_Device;
            Second : out Cubic_Device)
         is
            CX : constant Float := (B.X2 + B.X3) * 0.5;
            CY : constant Float := (B.Y2 + B.Y3) * 0.5;
         begin
            First.X1 := B.X1;
            First.Y1 := B.Y1;
            First.X2 := (B.X1 + B.X2) * 0.5;
            First.Y2 := (B.Y1 + B.Y2) * 0.5;
            First.X3 := (First.X2 + CX) * 0.5;
            First.Y3 := (First.Y2 + CY) * 0.5;

            Second.X4 := B.X4;
            Second.Y4 := B.Y4;
            Second.X3 := (B.X3 + B.X4) * 0.5;
            Second.Y3 := (B.Y3 + B.Y4) * 0.5;
            Second.X2 := (Second.X3 + CX) * 0.5;
            Second.Y2 := (Second.Y3 + CY) * 0.5;

            First.X4 := (First.X3 + Second.X2) * 0.5;
            First.Y4 := (First.Y3 + Second.Y2) * 0.5;
            Second.X1 := First.X4;
            Second.Y1 := First.Y4;
         end Split_Cubic;

         procedure Emit_Cubic_Device
           (B     : Cubic_Device;
            Depth : Natural := 0)
         is
            X4X1 : constant Float := B.X4 - B.X1;
            Y4Y1 : constant Float := B.Y4 - B.Y1;
            Max_Depth_Reached : constant Boolean :=
              Depth >= Natural (Constants.Flatten_Max_Depth) - 1;
            L : Float;
            D : Float;
         begin
            L := abs X4X1 + abs Y4Y1;
            if L > 1.0 then
               D :=
                 abs (X4X1 * (B.Y1 - B.Y2) - Y4Y1 * (B.X1 - B.X2))
                 + abs (X4X1 * (B.Y1 - B.Y3) - Y4Y1 * (B.X1 - B.X3));
            else
               D :=
                 abs (B.X1 - B.X2)
                 + abs (B.Y1 - B.Y2)
                 + abs (B.X1 - B.X3)
                 + abs (B.Y1 - B.Y3);
               L := 1.0;
            end if;

            if Max_Depth_Reached
              or else D < Constants.Flatten_Flatness_Threshold * L
            then
               Add_Device_Point (Current, B.X4, B.Y4);
            else
               declare
                  First  : Cubic_Device;
                  Second : Cubic_Device;
               begin
                  Split_Cubic (B, First, Second);
                  Emit_Cubic_Device (First, Depth + 1);
                  Emit_Cubic_Device (Second, Depth + 1);
               end;
            end if;
         end Emit_Cubic_Device;

         X0D, Y0D : Float;
         X1D, Y1D : Float;
         X2D, Y2D : Float;
         X3D, Y3D : Float;
      begin
         if not Has_Subpath then
            Start_Subpath (CX, CY);
         end if;

         Map_Point (M, CX, CY, X0D, Y0D);
         Map_Point (M, X1, Y1, X1D, Y1D);
         Map_Point (M, X2, Y2, X2D, Y2D);
         Map_Point (M, X3, Y3, X3D, Y3D);

         Emit_Cubic_Device
           ((X1 => X0D,
             Y1 => Y0D,
             X2 => X1D,
             Y2 => Y1D,
             X3 => X2D,
             Y3 => Y2D,
             X4 => X3D,
             Y4 => Y3D));

         CX := X3;
         CY := Y3;
      end Cubic_To;

      procedure Quad_To
        (QX, QY, X2, Y2 : Float)
      is
         C1X : Float;
         C1Y : Float;
         C2X : Float;
         C2Y : Float;
      begin
         C1X := (2.0 * QX + CX) / 3.0;
         C1Y := (2.0 * QY + CY) / 3.0;
         C2X := (2.0 * QX + X2) / 3.0;
         C2Y := (2.0 * QY + Y2) / 3.0;

         Cubic_To (C1X, C1Y, C2X, C2Y, X2, Y2);
      end Quad_To;

      procedure Arc_To
        (RX, RY      : Float;
         Rot_Deg     : Float;
         Large_Arc   : Boolean;
         Sweep       : Boolean;
         X2, Y2      : Float)
      is
         Rx_Adj : Float := abs RX;
         Ry_Adj : Float := abs RY;
         Phi    : constant Float := Rot_Deg * Constants.Degrees_To_Radians;
         Cos_P  : constant Float := Math.Cos (Phi);
         Sin_P  : constant Float := Math.Sin (Phi);

         DX2 : constant Float := (CX - X2) * 0.5;
         DY2 : constant Float := (CY - Y2) * 0.5;

         X1P : Float;
         Y1P : Float;
         Lambda : Float;
         Scale  : Float;

         CXP, CYP : Float;
         CXC, CYC : Float;
         Num, Den, Coef : Float;

         Ux, Uy, Vx, Vy : Float;
         Theta1, Delta_Theta : Float;
         Segs : Positive;

         function Vector_Angle
           (UX, UY, VX, VY : Float) return Float
         is
            Dot : constant Float := UX * VX + UY * VY;
            Len : constant Float := Math.Sqrt ((UX * UX + UY * UY) * (VX * VX + VY * VY));
            Cross : constant Float := UX * VY - UY * VX;
            A : Float;

            function Clamp_Signed_Unit (V : Float) return Float is
            begin
               if V < -1.0 then
                  return -1.0;
               elsif V > 1.0 then
                  return 1.0;
               else
                  return V;
               end if;
            end Clamp_Signed_Unit;
         begin
            if Len <= 0.0 then
               return 0.0;
            end if;

            A := Math.Arccos (Clamp_Signed_Unit (Dot / Len));
            if Cross < 0.0 then
               return -A;
            end if;
            return A;
         end Vector_Angle;
      begin
         if Rx_Adj <= 0.0 or else Ry_Adj <= 0.0
           or else (abs (X2 - CX) < 1.0E-6 and then abs (Y2 - CY) < 1.0E-6)
         then
            Line_To (X2, Y2);
            return;
         end if;

         X1P := Cos_P * DX2 + Sin_P * DY2;
         Y1P := -Sin_P * DX2 + Cos_P * DY2;

         Lambda := (X1P * X1P) / (Rx_Adj * Rx_Adj) + (Y1P * Y1P) / (Ry_Adj * Ry_Adj);
         if Lambda > 1.0 then
            Scale := Math.Sqrt (Lambda);
            Rx_Adj := Rx_Adj * Scale;
            Ry_Adj := Ry_Adj * Scale;
         end if;

         Num := Rx_Adj * Rx_Adj * Ry_Adj * Ry_Adj
           - Rx_Adj * Rx_Adj * Y1P * Y1P
           - Ry_Adj * Ry_Adj * X1P * X1P;
         Den := Rx_Adj * Rx_Adj * Y1P * Y1P
           + Ry_Adj * Ry_Adj * X1P * X1P;

         if Den <= 0.0 then
            Coef := 0.0;
         else
            Coef := Math.Sqrt (Float'Max (0.0, Num / Den));
         end if;

         if Large_Arc = Sweep then
            Coef := -Coef;
         end if;

         CXP := Coef * (Rx_Adj * Y1P / Ry_Adj);
         CYP := Coef * (-Ry_Adj * X1P / Rx_Adj);

         CXC := Cos_P * CXP - Sin_P * CYP + (CX + X2) * 0.5;
         CYC := Sin_P * CXP + Cos_P * CYP + (CY + Y2) * 0.5;

         Ux := (X1P - CXP) / Rx_Adj;
         Uy := (Y1P - CYP) / Ry_Adj;
         Vx := (-X1P - CXP) / Rx_Adj;
         Vy := (-Y1P - CYP) / Ry_Adj;

         Theta1 := Vector_Angle (1.0, 0.0, Ux, Uy);
         Delta_Theta := Vector_Angle (Ux, Uy, Vx, Vy);

         if (not Sweep) and then Delta_Theta > 0.0 then
            Delta_Theta := Delta_Theta - Constants.Full_Circle_Radians;
         elsif Sweep and then Delta_Theta < 0.0 then
            Delta_Theta := Delta_Theta + Constants.Full_Circle_Radians;
         end if;

         Segs := Positive
           (Integer'Max
              (1,
               Integer (Float'Ceiling (abs Delta_Theta / Constants.Arc_Max_Step_Radians))));

         for I in 1 .. Segs loop
            declare
               T : constant Float := Theta1 + Delta_Theta * Float (I) / Float (Segs);
               Cos_T : constant Float := Math.Cos (T);
               Sin_T : constant Float := Math.Sin (T);
               PX : constant Float := Cos_P * Rx_Adj * Cos_T - Sin_P * Ry_Adj * Sin_T + CXC;
               PY : constant Float := Sin_P * Rx_Adj * Cos_T + Cos_P * Ry_Adj * Sin_T + CYC;
            begin
               Add_Transformed_Point (Current, PX, PY);
            end;
         end loop;

         CX := X2;
         CY := Y2;
      end Arc_To;
   begin
      while Pos <= D'Last loop
         Skip_Separators (D, Pos, Allow_Comma => True);
         exit when Pos > D'Last;

         if D (Pos) in 'A' .. 'Z' or else D (Pos) in 'a' .. 'z' then
            Cmd := D (Pos);
            Pos := Pos + 1;
         elsif Cmd = ASCII.NUL then
            exit;
         end if;

         case Cmd is
            when 'M' | 'm' =>
               declare
                  X, Y : Float;
                  Rel  : constant Boolean := Cmd = 'm';
               begin
                  if not Read_Number (D, Pos, X) or else not Read_Number (D, Pos, Y) then
                     exit;
                  end if;

                  if Rel then
                     X := CX + X;
                     Y := CY + Y;
                  end if;
                  Start_Subpath (X, Y);
                  Has_Prev_Cubic := False;
                  Has_Prev_Quad := False;

                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X);
                     exit when not Read_Number (D, Pos, Y);
                     if Rel then
                        X := CX + X;
                        Y := CY + Y;
                     end if;
                     Line_To (X, Y);
                  end loop;

                  Cmd := (if Rel then 'l' else 'L');
               end;

            when 'L' | 'l' =>
               declare
                  X, Y : Float;
                  Rel  : constant Boolean := Cmd = 'l';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X);
                     exit when not Read_Number (D, Pos, Y);
                     if Rel then
                        X := CX + X;
                        Y := CY + Y;
                     end if;
                     Line_To (X, Y);
                  end loop;
                  Has_Prev_Cubic := False;
                  Has_Prev_Quad := False;
               end;

            when 'H' | 'h' =>
               declare
                  X   : Float;
                  Rel : constant Boolean := Cmd = 'h';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X);
                     if Rel then
                        X := CX + X;
                     end if;
                     Line_To (X, CY);
                  end loop;
                  Has_Prev_Cubic := False;
                  Has_Prev_Quad := False;
               end;

            when 'V' | 'v' =>
               declare
                  Y   : Float;
                  Rel : constant Boolean := Cmd = 'v';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, Y);
                     if Rel then
                        Y := CY + Y;
                     end if;
                     Line_To (CX, Y);
                  end loop;
                  Has_Prev_Cubic := False;
                  Has_Prev_Quad := False;
               end;

            when 'C' | 'c' =>
               declare
                  X1, Y1, X2, Y2, X3, Y3 : Float;
                  Rel : constant Boolean := Cmd = 'c';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X1);
                     exit when not Read_Number (D, Pos, Y1);
                     exit when not Read_Number (D, Pos, X2);
                     exit when not Read_Number (D, Pos, Y2);
                     exit when not Read_Number (D, Pos, X3);
                     exit when not Read_Number (D, Pos, Y3);

                     if Rel then
                        X1 := CX + X1;
                        Y1 := CY + Y1;
                        X2 := CX + X2;
                        Y2 := CY + Y2;
                        X3 := CX + X3;
                        Y3 := CY + Y3;
                     end if;

                     Cubic_To (X1, Y1, X2, Y2, X3, Y3);
                     Prev_C2_X := X2;
                     Prev_C2_Y := Y2;
                     Has_Prev_Cubic := True;
                     Has_Prev_Quad := False;
                  end loop;
               end;

            when 'S' | 's' =>
               declare
                  X2, Y2, X3, Y3 : Float;
                  X1, Y1 : Float;
                  Rel : constant Boolean := Cmd = 's';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X2);
                     exit when not Read_Number (D, Pos, Y2);
                     exit when not Read_Number (D, Pos, X3);
                     exit when not Read_Number (D, Pos, Y3);

                     if Has_Prev_Cubic then
                        X1 := 2.0 * CX - Prev_C2_X;
                        Y1 := 2.0 * CY - Prev_C2_Y;
                     else
                        X1 := CX;
                        Y1 := CY;
                     end if;

                     if Rel then
                        X2 := CX + X2;
                        Y2 := CY + Y2;
                        X3 := CX + X3;
                        Y3 := CY + Y3;
                     end if;

                     Cubic_To (X1, Y1, X2, Y2, X3, Y3);
                     Prev_C2_X := X2;
                     Prev_C2_Y := Y2;
                     Has_Prev_Cubic := True;
                     Has_Prev_Quad := False;
                  end loop;
               end;

            when 'Q' | 'q' =>
               declare
                  X1, Y1, X2, Y2 : Float;
                  Rel : constant Boolean := Cmd = 'q';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X1);
                     exit when not Read_Number (D, Pos, Y1);
                     exit when not Read_Number (D, Pos, X2);
                     exit when not Read_Number (D, Pos, Y2);

                     if Rel then
                        X1 := CX + X1;
                        Y1 := CY + Y1;
                        X2 := CX + X2;
                        Y2 := CY + Y2;
                     end if;

                     Quad_To (X1, Y1, X2, Y2);
                     Prev_Q_X := X1;
                     Prev_Q_Y := Y1;
                     Has_Prev_Quad := True;
                     Has_Prev_Cubic := False;
                  end loop;
               end;

            when 'T' | 't' =>
               declare
                  X2, Y2 : Float;
                  X1, Y1 : Float;
                  Rel : constant Boolean := Cmd = 't';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, X2);
                     exit when not Read_Number (D, Pos, Y2);

                     if Has_Prev_Quad then
                        X1 := 2.0 * CX - Prev_Q_X;
                        Y1 := 2.0 * CY - Prev_Q_Y;
                     else
                        X1 := CX;
                        Y1 := CY;
                     end if;

                     if Rel then
                        X2 := CX + X2;
                        Y2 := CY + Y2;
                     end if;

                     Quad_To (X1, Y1, X2, Y2);
                     Prev_Q_X := X1;
                     Prev_Q_Y := Y1;
                     Has_Prev_Quad := True;
                     Has_Prev_Cubic := False;
                  end loop;
               end;

            when 'A' | 'a' =>
               declare
                  RX, RY, Rot, Large_Flag, Sweep_Flag, X, Y : Float;
                  Rel : constant Boolean := Cmd = 'a';
               begin
                  while Has_Number (D, Pos) loop
                     exit when not Read_Number (D, Pos, RX);
                     exit when not Read_Number (D, Pos, RY);
                     exit when not Read_Number (D, Pos, Rot);
                     exit when not Read_Number (D, Pos, Large_Flag);
                     exit when not Read_Number (D, Pos, Sweep_Flag);
                     exit when not Read_Number (D, Pos, X);
                     exit when not Read_Number (D, Pos, Y);

                     if Rel then
                        X := CX + X;
                        Y := CY + Y;
                     end if;

                     Arc_To
                       (RX => RX,
                        RY => RY,
                        Rot_Deg => Rot,
                        Large_Arc => abs Large_Flag > 0.5,
                        Sweep => abs Sweep_Flag > 0.5,
                        X2 => X,
                        Y2 => Y);
                  end loop;
                  Has_Prev_Cubic := False;
                  Has_Prev_Quad := False;
               end;

            when 'Z' | 'z' =>
               if Has_Subpath then
                  CX := SX0;
                  CY := SY0;
                  Flush_Current (Closed => True);
                  Has_Subpath := False;
               end if;
               Has_Prev_Cubic := False;
               Has_Prev_Quad := False;

            when others =>
               null;
         end case;
      end loop;

      if Current.Points.Length > 0 then
         Flush_Current;
      end if;

      return Contours;
   end Build_Path_Contours;

end Adi.SVG.Parser;
