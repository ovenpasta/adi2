with Ada.Characters.Latin_1;

package body Adi.Text_Buffer is

   function Is_UTF8_Continuation_Byte (C : Character) return Boolean is
      V : constant Natural := Character'Pos (C);
   begin
      return V in 16#80# .. 16#BF#;
   end Is_UTF8_Continuation_Byte;

   function Normalize_UTF8_Column (S : String; Col : Natural) return Natural is
      C : Natural := Natural'Min (Col, S'Length);
   begin
      while C > 0
        and then Integer (C) < S'Length
        and then Is_UTF8_Continuation_Byte (S (Integer (C + 1)))
      loop
         C := C - 1;
      end loop;
      return C;
   end Normalize_UTF8_Column;

   function Prev_UTF8_Column (S : String; Col : Natural) return Natural is
      C : Natural := Normalize_UTF8_Column (S, Col);
   begin
      if C = 0 then
         return 0;
      end if;

      C := C - 1;
      while C > 0
        and then Is_UTF8_Continuation_Byte (S (Integer (C + 1)))
      loop
         C := C - 1;
      end loop;
      return C;
   end Prev_UTF8_Column;

   function Next_UTF8_Column (S : String; Col : Natural) return Natural is
      C : Natural := Normalize_UTF8_Column (S, Col);
   begin
      if C >= S'Length then
         return S'Length;
      end if;

      C := C + 1;
      while C < S'Length
        and then Is_UTF8_Continuation_Byte (S (Integer (C + 1)))
      loop
         C := C + 1;
      end loop;
      return C;
   end Next_UTF8_Column;

   function Clamp_Column (S : String; Col : Natural) return Natural is
   begin
      return Natural'Min (Col, S'Length);
   end Clamp_Column;

   procedure Ensure_Not_Empty (B : in out Text_Buffer) is
   begin
      if B.Lines.Is_Empty then
         B.Lines.Append (To_Unbounded_String (""));
         B.Caret := (Line => 1, Column => 0);
         B.Selection := (others => <>);
      end if;
   end Ensure_Not_Empty;

   function To_Pos (B : Text_Buffer; P : Position) return Position is
      Result : Position := P;
      Last   : Positive;
   begin
      if B.Lines.Is_Empty then
         return (Line => 1, Column => 0);
      end if;

      Last := Positive (B.Lines.Last_Index);
      if Result.Line > Last then
         Result.Line := Last;
      elsif Result.Line < 1 then
         Result.Line := 1;
      end if;

      declare
         Line_S : constant String := To_String (B.Lines.Element (Result.Line));
      begin
         Result.Column := Normalize_UTF8_Column
           (Line_S, Clamp_Column (Line_S, Result.Column));
      end;
      return Result;
   end To_Pos;

   function "<" (L, R : Position) return Boolean is
   begin
      return L.Line < R.Line or else (L.Line = R.Line and then L.Column < R.Column);
   end "<";

   procedure Get_Selection_Bounds
     (B : Text_Buffer;
      A : out Position;
      Z : out Position)
   is
   begin
      if not B.Selection.Active or else B.Selection.Anchor = B.Caret then
         A := B.Caret;
         Z := B.Caret;
         return;
      end if;

      if B.Selection.Anchor < B.Caret then
         A := B.Selection.Anchor;
         Z := B.Caret;
      else
         A := B.Caret;
         Z := B.Selection.Anchor;
      end if;
   end Get_Selection_Bounds;

   procedure Delete_Selection (B : in out Text_Buffer) is
      A, Z      : Position;
      Prefix    : Unbounded_String;
      Suffix    : Unbounded_String;
   begin
      if not Has_Selection (B) then
         return;
      end if;

      Get_Selection_Bounds (B, A, Z);

      if A.Line = Z.Line then
         declare
            S : constant String := To_String (B.Lines.Element (A.Line));
            L : constant Natural := S'Length;
            Left_Part  : constant String := (if A.Column = 0 then "" else S (1 .. Integer (A.Column)));
            Right_Part : constant String := (if Z.Column >= L then "" else S (Integer (Z.Column + 1) .. S'Last));
         begin
            B.Lines.Replace_Element (A.Line, To_Unbounded_String (Left_Part & Right_Part));
         end;
      else
         declare
            First_Str : constant String := To_String (B.Lines.Element (A.Line));
            Last_Str  : constant String := To_String (B.Lines.Element (Z.Line));
         begin
            Prefix := To_Unbounded_String
              ((if A.Column = 0 then "" else First_Str (1 .. Integer (A.Column))));
            Suffix := To_Unbounded_String
              ((if Z.Column >= Last_Str'Length then ""
                else Last_Str (Integer (Z.Column + 1) .. Last_Str'Last)));
         end;

         B.Lines.Replace_Element (A.Line, Prefix & Suffix);
         for I in reverse A.Line + 1 .. Z.Line loop
            B.Lines.Delete (I);
         end loop;
      end if;

      B.Caret := A;
      B.Selection := (others => <>);
      Ensure_Not_Empty (B);
   end Delete_Selection;

   procedure Set_Selection_Mode (B : in out Text_Buffer; Extend : Boolean) is
   begin
      if Extend then
         if not B.Selection.Active then
            B.Selection.Active := True;
            B.Selection.Anchor := B.Caret;
         end if;
      else
         B.Selection := (others => <>);
      end if;
   end Set_Selection_Mode;

   procedure Clear (B : in out Text_Buffer) is
   begin
      B.Lines.Clear;
      B.Lines.Append (To_Unbounded_String (""));
      B.Caret := (Line => 1, Column => 0);
      B.Selection := (others => <>);
   end Clear;

   procedure Set_Text (B : in out Text_Buffer; Text : String) is
      Start : Positive := Text'First;
   begin
      B.Lines.Clear;

      if Text'Length = 0 then
         B.Lines.Append (To_Unbounded_String (""));
      else
         for I in Text'Range loop
            if Text (I) = Ada.Characters.Latin_1.LF then
               B.Lines.Append (To_Unbounded_String (Text (Start .. I - 1)));
               Start := I + 1;
            end if;
         end loop;
         B.Lines.Append (To_Unbounded_String (Text (Start .. Text'Last)));
      end if;

      B.Caret := (Line => Positive (B.Lines.Last_Index),
                  Column => To_String (B.Lines.Last_Element)'Length);
      B.Selection := (others => <>);
   end Set_Text;

   function Get_Text (B : Text_Buffer) return String is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if B.Lines.Is_Empty then
         return "";
      end if;

      for I in B.Lines.First_Index .. B.Lines.Last_Index loop
         if I > B.Lines.First_Index then
            Result := Result & Ada.Characters.Latin_1.LF;
         end if;
         Result := Result & B.Lines.Element (I);
      end loop;
      return To_String (Result);
   end Get_Text;

   function Get_Line_Count (B : Text_Buffer) return Natural is
   begin
      return Natural (B.Lines.Length);
   end Get_Line_Count;

   function Get_Line (B : Text_Buffer; Line : Positive) return String is
   begin
      if B.Lines.Is_Empty or else Line > B.Lines.Last_Index then
         return "";
      end if;
      return To_String (B.Lines.Element (Line));
   end Get_Line;

   function Get_Caret (B : Text_Buffer) return Position is
   begin
      return B.Caret;
   end Get_Caret;

   procedure Set_Caret
     (B                : in out Text_Buffer;
      P                : Position;
      Extend_Selection : Boolean := False)
   is
   begin
      Ensure_Not_Empty (B);
      if Extend_Selection then
         if not B.Selection.Active then
            B.Selection.Active := True;
            B.Selection.Anchor := B.Caret;
         end if;
      else
         B.Selection := (others => <>);
      end if;
      B.Caret := To_Pos (B, P);
   end Set_Caret;

   function Has_Selection (B : Text_Buffer) return Boolean is
   begin
      return B.Selection.Active and then B.Selection.Anchor /= B.Caret;
   end Has_Selection;

   procedure Get_Selection_Range
     (B      : Text_Buffer;
      Start  : out Position;
      Stop   : out Position;
      Active : out Boolean)
   is
   begin
      if B.Lines.Is_Empty then
         Start := (Line => 1, Column => 0);
         Stop := Start;
         Active := False;
         return;
      end if;

      if Has_Selection (B) then
         Get_Selection_Bounds (B, Start, Stop);
         Active := True;
      else
         Start := B.Caret;
         Stop := B.Caret;
         Active := False;
      end if;
   end Get_Selection_Range;

   procedure Clear_Selection (B : in out Text_Buffer) is
   begin
      B.Selection := (others => <>);
   end Clear_Selection;

   procedure Select_All (B : in out Text_Buffer) is
      Last_Line : Positive;
      Last_Col  : Natural;
   begin
      Ensure_Not_Empty (B);
      Last_Line := Positive (B.Lines.Last_Index);
      Last_Col := To_String (B.Lines.Element (Last_Line))'Length;
      B.Selection.Active := True;
      B.Selection.Anchor := (Line => 1, Column => 0);
      B.Caret := (Line => Last_Line, Column => Last_Col);
   end Select_All;

   procedure Insert_Text (B : in out Text_Buffer; Text : String) is
      Cur       : Position;
      Start     : Positive;
      Part      : Unbounded_String;
      First_New : Boolean := True;
      Insert_At : Positive;
      Last_Part : Unbounded_String := Null_Unbounded_String;
      New_Lines : Natural := 0;
   begin
      Ensure_Not_Empty (B);
      if Text'Length = 0 then
         return;
      end if;

      if Has_Selection (B) then
         Delete_Selection (B);
      end if;

      Cur := B.Caret;
      declare
         Line_Text : constant String := To_String (B.Lines.Element (Cur.Line));
         Prefix    : constant String :=
           (if Cur.Column = 0 then "" else Line_Text (1 .. Integer (Cur.Column)));
         Suffix    : constant String :=
           (if Cur.Column >= Line_Text'Length then ""
            else Line_Text (Integer (Cur.Column + 1) .. Line_Text'Last));
      begin
         if not (for some C of Text => C = Ada.Characters.Latin_1.LF) then
            B.Lines.Replace_Element
              (Cur.Line, To_Unbounded_String (Prefix & Text & Suffix));
            B.Caret := (Line => Cur.Line, Column => Cur.Column + Text'Length);
            return;
         end if;

         Start := Text'First;
         Insert_At := Cur.Line;
         for I in Text'Range loop
            if Text (I) = Ada.Characters.Latin_1.LF then
               Part := To_Unbounded_String (Text (Start .. I - 1));
               if First_New then
                  B.Lines.Replace_Element
                    (Cur.Line, To_Unbounded_String (Prefix) & Part);
                  First_New := False;
               else
                  B.Lines.Insert (Insert_At + 1, Part);
                  Insert_At := Insert_At + 1;
               end if;
               New_Lines := New_Lines + 1;
               Start := I + 1;
               Last_Part := Null_Unbounded_String;
            end if;
         end loop;

         Last_Part := To_Unbounded_String (Text (Start .. Text'Last));
         if New_Lines = 0 then
            B.Lines.Replace_Element
              (Cur.Line, To_Unbounded_String (Prefix) & Last_Part & To_Unbounded_String (Suffix));
            B.Caret := (Line => Cur.Line, Column => Cur.Column + Text'Length);
         else
            B.Lines.Insert (Insert_At + 1, Last_Part & To_Unbounded_String (Suffix));
            B.Caret := (Line => Cur.Line + New_Lines, Column => Length (Last_Part));
         end if;
      end;
   end Insert_Text;

   procedure Delete_Backward (B : in out Text_Buffer) is
      Cur : Position;
   begin
      Ensure_Not_Empty (B);

      if Has_Selection (B) then
         Delete_Selection (B);
         return;
      end if;

      Cur := B.Caret;
      if Cur.Column > 0 then
         declare
            Line_Text : constant String := To_String (B.Lines.Element (Cur.Line));
            Prev_Col  : constant Natural := Prev_UTF8_Column (Line_Text, Cur.Column);
            Left_Part  : constant String :=
              (if Prev_Col = 0 then "" else Line_Text (1 .. Integer (Prev_Col)));
            Right_Part : constant String :=
              (if Cur.Column >= Line_Text'Length then "" else Line_Text (Integer (Cur.Column + 1) .. Line_Text'Last));
         begin
            B.Lines.Replace_Element (Cur.Line, To_Unbounded_String (Left_Part & Right_Part));
            B.Caret.Column := Prev_Col;
         end;
      elsif Cur.Line > 1 then
         declare
            Prev_Text : constant String := To_String (B.Lines.Element (Cur.Line - 1));
            Line_Text : constant String := To_String (B.Lines.Element (Cur.Line));
         begin
            B.Lines.Replace_Element
              (Cur.Line - 1, To_Unbounded_String (Prev_Text & Line_Text));
            B.Lines.Delete (Cur.Line);
            B.Caret := (Line => Cur.Line - 1, Column => Prev_Text'Length);
         end;
      end if;
   end Delete_Backward;

   procedure Delete_Forward (B : in out Text_Buffer) is
      Cur : Position;
   begin
      Ensure_Not_Empty (B);

      if Has_Selection (B) then
         Delete_Selection (B);
         return;
      end if;

      Cur := B.Caret;
      declare
         Line_Text : constant String := To_String (B.Lines.Element (Cur.Line));
      begin
         if Cur.Column < Line_Text'Length then
         declare
            Next_Col : constant Natural := Next_UTF8_Column (Line_Text, Cur.Column);
            Left_Part  : constant String :=
              (if Cur.Column = 0 then "" else Line_Text (1 .. Integer (Cur.Column)));
            Right_Part : constant String :=
              (if Next_Col >= Line_Text'Length then ""
               else Line_Text (Integer (Next_Col + 1) .. Line_Text'Last));
         begin
            B.Lines.Replace_Element (Cur.Line, To_Unbounded_String (Left_Part & Right_Part));
         end;
         elsif Cur.Line < B.Lines.Last_Index then
            declare
               Next_Text : constant String := To_String (B.Lines.Element (Cur.Line + 1));
            begin
               B.Lines.Replace_Element
                 (Cur.Line, To_Unbounded_String (Line_Text & Next_Text));
               B.Lines.Delete (Cur.Line + 1);
            end;
         end if;
      end;
   end Delete_Forward;

   procedure Move_Left (B : in out Text_Buffer; Extend_Selection : Boolean := False) is
      A, Z : Position;
   begin
      Ensure_Not_Empty (B);

      if Has_Selection (B) and then not Extend_Selection then
         Get_Selection_Bounds (B, A, Z);
         B.Caret := A;
         B.Selection := (others => <>);
         return;
      end if;

      Set_Selection_Mode (B, Extend_Selection);
      if B.Caret.Column > 0 then
         declare
            Line_Text : constant String := To_String (B.Lines.Element (B.Caret.Line));
         begin
            B.Caret.Column := Prev_UTF8_Column (Line_Text, B.Caret.Column);
         end;
      elsif B.Caret.Line > 1 then
         B.Caret.Line := B.Caret.Line - 1;
         B.Caret.Column := To_String (B.Lines.Element (B.Caret.Line))'Length;
      end if;
   end Move_Left;

   procedure Move_Right (B : in out Text_Buffer; Extend_Selection : Boolean := False) is
      A, Z : Position;
   begin
      Ensure_Not_Empty (B);

      if Has_Selection (B) and then not Extend_Selection then
         Get_Selection_Bounds (B, A, Z);
         B.Caret := Z;
         B.Selection := (others => <>);
         return;
      end if;

      Set_Selection_Mode (B, Extend_Selection);
      declare
         Line_Text : constant String := To_String (B.Lines.Element (B.Caret.Line));
      begin
         if B.Caret.Column < Line_Text'Length then
            B.Caret.Column := Next_UTF8_Column (Line_Text, B.Caret.Column);
         elsif B.Caret.Line < B.Lines.Last_Index then
            B.Caret.Line := B.Caret.Line + 1;
            B.Caret.Column := 0;
         end if;
      end;
   end Move_Right;

   procedure Move_Home (B : in out Text_Buffer; Extend_Selection : Boolean := False) is
   begin
      Ensure_Not_Empty (B);
      Set_Selection_Mode (B, Extend_Selection);
      B.Caret.Column := 0;
   end Move_Home;

   procedure Move_End (B : in out Text_Buffer; Extend_Selection : Boolean := False) is
   begin
      Ensure_Not_Empty (B);
      Set_Selection_Mode (B, Extend_Selection);
      B.Caret.Column := To_String (B.Lines.Element (B.Caret.Line))'Length;
   end Move_End;

   procedure Move_Up (B : in out Text_Buffer; Extend_Selection : Boolean := False) is
   begin
      Ensure_Not_Empty (B);
      Set_Selection_Mode (B, Extend_Selection);
      if B.Caret.Line > 1 then
         B.Caret.Line := B.Caret.Line - 1;
         B.Caret.Column := Natural'Min
           (B.Caret.Column, To_String (B.Lines.Element (B.Caret.Line))'Length);
      end if;
   end Move_Up;

   procedure Move_Down (B : in out Text_Buffer; Extend_Selection : Boolean := False) is
   begin
      Ensure_Not_Empty (B);
      Set_Selection_Mode (B, Extend_Selection);
      if B.Caret.Line < B.Lines.Last_Index then
         B.Caret.Line := B.Caret.Line + 1;
         B.Caret.Column := Natural'Min
           (B.Caret.Column, To_String (B.Lines.Element (B.Caret.Line))'Length);
      end if;
   end Move_Down;

end Adi.Text_Buffer;
