pragma Ada_2022;

with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package body Adi.CSS_Parser is

   package Fix renames Ada.Strings.Fixed;
   package Char renames Ada.Characters.Handling;

   use type Ada.Calendar.Time;
   use type Ada.Containers.Count_Type;

   type Selector_Style is record
      Kind   : Selector_Kind := Class_Selector;
      Name   : Unbounded_String;
      Styles : Part_Style_Array := Empty_Part_Styles;
   end record;

   package Selector_Style_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Selector_Style);

   type Binding is record
      Kind       : Selector_Kind := Class_Selector;
      Name       : Unbounded_String;
      Target     : Widget_Access := null;
   end record;

   package Binding_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Binding);

   type Stylesheet_Impl is record
      Selectors     : Selector_Style_Vectors.Vector;
      Bindings      : Binding_Vectors.Vector;
      Source_Path   : Unbounded_String;
      Last_Modified : Ada.Calendar.Time := Ada.Calendar.Time_Of (1901, 1, 1, 0.0);
      Last_Error    : Unbounded_String;
   end record;

   type Parsed_Selector is record
      Kind       : Selector_Kind := Class_Selector;
      Name       : Unbounded_String;
      Part       : Part_Kind := Main_Part;
      Selector   : State_Selector := Any_State;
      Has_State  : Boolean := False;
   end record;

   type Parsed_Rule is record
      Sel   : Parsed_Selector;
      Style : Style_Rules := Empty_Style;
   end record;

   package Parsed_Rule_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Parsed_Rule);

   type Parsed_Length is record
      Amount : Float := 0.0;
      Unit   : CSS_Unit := Px;
   end record;

   package Length_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Parsed_Length);

   package Token_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Unbounded_String);

   procedure Ensure_Impl (Sheet : in out Stylesheet) is
   begin
      if Sheet.Impl = null then
         Sheet.Impl := new Stylesheet_Impl;
      end if;
   end Ensure_Impl;

   function Lower (S : String) return String is (Char.To_Lower (S));

   function Trimmed (S : String) return String is
     (Fix.Trim (S, Ada.Strings.Both));

   function Ends_With (S, Suffix : String) return Boolean is
   begin
      if Suffix'Length = 0 then
         return True;
      end if;

      if S'Length < Suffix'Length then
         return False;
      end if;

      return S (S'Last - Suffix'Length + 1 .. S'Last) = Suffix;
   end Ends_With;

   function Is_Whitespace (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Strip_Comments (Content : String) return String is
      Result : Unbounded_String;
      I      : Positive := Content'First;
   begin
      while I <= Content'Last loop
         if I < Content'Last
           and then Content (I) = '/'
           and then Content (I + 1) = '*'
         then
            I := I + 2;
            while I < Content'Last loop
               exit when Content (I) = '*' and then Content (I + 1) = '/';
               I := I + 1;
            end loop;
            if I < Content'Last then
               I := I + 2;
            end if;
         else
            Append (Result, Content (I));
            I := I + 1;
         end if;
      end loop;

      return To_String (Result);
   end Strip_Comments;

   function Parse_Number (S : String; Value : out Float) return Boolean is
   begin
      Value := Float'Value (Trimmed (S));
      return True;
   exception
      when others =>
         return False;
   end Parse_Number;

   function Parse_Integer (S : String; Value : out Integer) return Boolean is
   begin
      Value := Integer'Value (Trimmed (S));
      return True;
   exception
      when others =>
         return False;
   end Parse_Integer;

   function Parse_Natural (S : String; Value : out Natural) return Boolean is
      I : Integer;
   begin
      if not Parse_Integer (S, I) or else I < 0 then
         return False;
      end if;

      Value := Natural (I);
      return True;
   end Parse_Natural;

   function Parse_Grid_Track_Count
     (Input : String; Count : out Natural) return Boolean
   is
      V : constant String := Lower (Trimmed (Input));
      Paren : Natural;
      Comma : Natural;
   begin
      --  "repeat(N, ...)" form
      if V'Length > 7
        and then V (V'First .. V'First + 6) = "repeat("
        and then V (V'Last) = ')'
      then
         Paren := V'First + 6;  --  index of '('
         Comma := 0;
         for J in Paren + 1 .. V'Last - 1 loop
            if V (J) = ',' then
               Comma := J;
               exit;
            end if;
         end loop;
         if Comma > 0 then
            return Parse_Natural (V (Paren + 1 .. Comma - 1), Count)
              and then Count > 0;
         end if;
         return False;
      end if;
      --  Plain integer form
      if Parse_Natural (V, Count) and then Count > 0 then
         return True;
      end if;
      --  Space-separated track list (e.g. "1fr 1fr 1fr"): count tokens
      declare
         N_Tokens : Natural := 0;
         In_Token : Boolean := False;
      begin
         for J in V'Range loop
            if V (J) = ' ' or else V (J) = ASCII.HT then
               In_Token := False;
            elsif not In_Token then
               In_Token := True;
               N_Tokens := N_Tokens + 1;
            end if;
         end loop;
         if N_Tokens > 0 then
            Count := N_Tokens;
            return True;
         end if;
      end;
      return False;
   end Parse_Grid_Track_Count;

   --  Parse "grid-template-columns" value into a Grid_Track_List.
   --  Supports: plain integer N (→ N equal fr tracks), space-separated
   --  size tokens, repeat(N, size), and mixed "repeat(N, size) size...".
   --  Returns False on unknown tokens or when token count exceeds Max_Grid_Tracks;
   --  callers fall back to Grid_Columns count-only in that case.
   function Parse_Grid_Track_List
     (Input : String; List : out Grid_Track_List) return Boolean
   is
      V       : constant String  := Lower (Trimmed (Input));
      Count   : Natural          := 0;
      Num     : Float;
      N_Plain : Natural;

      function Append (Spec : Grid_Track_Spec) return Boolean is
      begin
         if Count >= Max_Grid_Tracks then
            return False;
         end if;
         Count := Count + 1;
         List.Tracks (Count) := Spec;
         return True;
      end Append;

      function Token_To_Spec
        (T : String; Spec : out Grid_Track_Spec) return Boolean is
      begin
         if T = "auto" then
            Spec := (Track_Auto, 0.0);
            return True;
         elsif T'Length > 2 and then T (T'Last - 1 .. T'Last) = "fr" then
            if Parse_Number (T (T'First .. T'Last - 2), Num) and then Num > 0.0 then
               Spec := (Track_Fr, Num);
               return True;
            end if;
         elsif T'Length > 2 and then T (T'Last - 1 .. T'Last) = "px" then
            if Parse_Number (T (T'First .. T'Last - 2), Num) and then Num >= 0.0 then
               Spec := (Track_Px, Num);
               return True;
            end if;
         end if;
         return False;
      end Token_To_Spec;

      function Process_Repeat (T : String) return Boolean is
         --  T is the full "repeat(...)" token
         Comma     : Natural := 0;
         Rep_Count : Natural;
         Size_Spec : Grid_Track_Spec;
      begin
         for J in T'First + 7 .. T'Last - 1 loop
            if T (J) = ',' then
               Comma := J;
               exit;
            end if;
         end loop;
         if Comma = 0 then
            return False;
         end if;
         if not Parse_Natural (Trimmed (T (T'First + 7 .. Comma - 1)), Rep_Count)
           or else Rep_Count = 0
         then
            return False;
         end if;
         if not Token_To_Spec (Trimmed (T (Comma + 1 .. T'Last - 1)), Size_Spec) then
            return False;
         end if;
         for I in 1 .. Rep_Count loop
            if not Append (Size_Spec) then
               return False;
            end if;
         end loop;
         return True;
      end Process_Repeat;

      function Process_Token (T : String) return Boolean is
         Spec : Grid_Track_Spec;
      begin
         if T'Length > 7
           and then T (T'First .. T'First + 6) = "repeat("
           and then T (T'Last) = ')'
         then
            return Process_Repeat (T);
         end if;
         if not Token_To_Spec (T, Spec) then
            return False;
         end if;
         return Append (Spec);
      end Process_Token;

      I     : Natural;
      Start : Natural;
      Depth : Natural;

   begin
      List := Default_Grid_Track_List;

      --  Legacy: plain integer N → N equal fr(1.0) tracks
      if Parse_Natural (V, N_Plain) and then N_Plain > 0 then
         if N_Plain > Max_Grid_Tracks then
            return False;
         end if;
         List.Count := N_Plain;
         for K in 1 .. N_Plain loop
            List.Tracks (K) := (Kind => Track_Fr, Value => 1.0);
         end loop;
         return True;
      end if;

      --  Token-level parsing
      I := V'First;
      while I <= V'Last loop
         --  Skip whitespace
         while I <= V'Last
           and then (V (I) = ' ' or else V (I) = ASCII.HT)
         loop
            I := I + 1;
         end loop;
         exit when I > V'Last;

         Start := I;
         Depth := 0;
         --  Scan to end of token, respecting parentheses for repeat(...)
         while I <= V'Last loop
            if V (I) = '(' then
               Depth := Depth + 1;
            elsif V (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
               if Depth = 0 then
                  I := I + 1;  --  advance past ')'
                  exit;
               end if;
            elsif (V (I) = ' ' or else V (I) = ASCII.HT) and then Depth = 0 then
               exit;
            end if;
            I := I + 1;
         end loop;

         if I > Start and then not Process_Token (V (Start .. I - 1)) then
            return False;
         end if;
      end loop;

      if Count = 0 then
         return False;
      end if;
      List.Count := Count;
      return True;
   end Parse_Grid_Track_List;

   function Parse_Length (Input : String; L : out Parsed_Length) return Boolean is
      V : constant String := Lower (Trimmed (Input));
      Number : Unbounded_String := To_Unbounded_String (V);
   begin
      if V = "0" then
         L := (Amount => 0.0, Unit => Px);
         return True;
      elsif Ends_With (V, "dp") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 2));
         L.Unit := Dip;
      elsif Ends_With (V, "dip") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 3));
         L.Unit := Dip;
      elsif Ends_With (V, "px") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 2));
         L.Unit := Px;
      elsif Ends_With (V, "rem") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 3));
         L.Unit := Root_Em;
      elsif Ends_With (V, "em") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 2));
         L.Unit := Em;
      elsif Ends_With (V, "%") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 1));
         L.Unit := Pct;
      elsif Ends_With (V, "vw") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 2));
         L.Unit := Vw;
      elsif Ends_With (V, "vh") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 2));
         L.Unit := Vh;
      else
         L.Unit := Px;
      end if;

      return Parse_Number (To_String (Number), L.Amount);
   end Parse_Length;

   function Parse_Quoted_String
     (Input    : String;
      Out_Text : out Unbounded_String) return Boolean
   is
      V : constant String := Trimmed (Input);
   begin
      Out_Text := Null_Unbounded_String;

      if V'Length < 2 then
         return False;
      end if;

      if not
        ((V (V'First) = '"' and then V (V'Last) = '"')
         or else
         (V (V'First) = ''' and then V (V'Last) = '''))
      then
         return False;
      end if;

      if V'Length = 2 then
         Out_Text := Null_Unbounded_String;
      else
         Out_Text := To_Unbounded_String (V (V'First + 1 .. V'Last - 1));
      end if;

      return True;
   end Parse_Quoted_String;

   function Parse_URL_Function
     (Input   : String;
      Out_URI : out Unbounded_String) return Boolean
   is
      V : constant String := Trimmed (Input);
   begin
      Out_URI := Null_Unbounded_String;

      if V'Length < 5 then
         return False;
      end if;

      if Lower (V (V'First .. V'First + 3)) /= "url(" or else V (V'Last) /= ')' then
         return False;
      end if;

      if V'Length = 5 then
         return False;
      end if;

      declare
         Inner : constant String := Trimmed (V (V'First + 4 .. V'Last - 1));
      begin
         if Inner'Length = 0 then
            return False;
         end if;

         if Inner'Length >= 2
           and then
             ((Inner (Inner'First) = '"' and then Inner (Inner'Last) = '"')
              or else
              (Inner (Inner'First) = ''' and then Inner (Inner'Last) = '''))
         then
            if Inner'Length = 2 then
               Out_URI := Null_Unbounded_String;
            else
               Out_URI := To_Unbounded_String (Inner (Inner'First + 1 .. Inner'Last - 1));
            end if;
         else
            Out_URI := To_Unbounded_String (Inner);
         end if;
      end;

      return Length (Out_URI) > 0;
   end Parse_URL_Function;

   function Parse_List_Style_Type_Value
     (Input    : String;
      Out_Type : out List_Style_Type_Value) return Boolean
   is
      V : constant String := Lower (Trimmed (Input));
      S : Unbounded_String;
   begin
      if V = "none" then
         Out_Type := (Kind => List_Style_None);
         return True;
      elsif V = "disc" then
         Out_Type := (Kind => List_Style_Disc);
         return True;
      elsif V = "circle" then
         Out_Type := (Kind => List_Style_Circle);
         return True;
      elsif V = "square" then
         Out_Type := (Kind => List_Style_Square);
         return True;
      elsif V = "decimal" then
         Out_Type := (Kind => List_Style_Decimal);
         return True;
      elsif Parse_Quoted_String (Trimmed (Input), S) then
         Out_Type := List_String (To_String (S));
         return True;
      end if;

      return False;
   end Parse_List_Style_Type_Value;

   function Parse_List_Style_Position_Value
     (Input        : String;
      Out_Position : out List_Style_Position_Value) return Boolean
   is
      V : constant String := Lower (Trimmed (Input));
   begin
      if V = "outside" then
         Out_Position := List_Outside;
         return True;
      elsif V = "inside" then
         Out_Position := List_Inside;
         return True;
      end if;

      return False;
   end Parse_List_Style_Position_Value;

   procedure Split_Whitespace_Tokens
     (Input      : String;
      Out_Tokens : in out Token_Vectors.Vector)
   is
      I           : Integer := Input'First;
      Token_Start : Integer := Input'First;
      In_Quote    : Character := ASCII.NUL;
      Paren_Depth : Natural := 0;
   begin
      Out_Tokens.Clear;

      while I <= Input'Last loop
         if In_Quote = ASCII.NUL then
            if Input (I) = '"' or else Input (I) = ''' then
               In_Quote := Input (I);
            elsif Input (I) = '(' then
               Paren_Depth := Paren_Depth + 1;
            elsif Input (I) = ')' then
               if Paren_Depth > 0 then
                  Paren_Depth := Paren_Depth - 1;
               end if;
            elsif Is_Whitespace (Input (I)) and then Paren_Depth = 0 then
               if I > Token_Start then
                  declare
                     Tok : constant String := Trimmed (Input (Token_Start .. I - 1));
                  begin
                     if Tok'Length > 0 then
                        Out_Tokens.Append (To_Unbounded_String (Tok));
                     end if;
                  end;
               end if;
               Token_Start := I + 1;
            end if;
         elsif Input (I) = In_Quote then
            In_Quote := ASCII.NUL;
         end if;

         I := I + 1;
      end loop;

      if Token_Start <= Input'Last then
         declare
            Tok : constant String := Trimmed (Input (Token_Start .. Input'Last));
         begin
            if Tok'Length > 0 then
               Out_Tokens.Append (To_Unbounded_String (Tok));
            end if;
         end;
      end if;
   end Split_Whitespace_Tokens;

   function Parse_List_Style_Shorthand
     (Input        : String;
      Out_Type     : out List_Style_Type_Value;
      Out_Image    : out List_Style_Image_Value;
      Out_Position : out List_Style_Position_Value;
      Has_Type     : out Boolean;
      Has_Image    : out Boolean;
      Has_Position : out Boolean) return Boolean
   is
      Tokens : Token_Vectors.Vector;
   begin
      Has_Type := False;
      Has_Image := False;
      Has_Position := False;

      Out_Type := Default_List_Style_Type;
      Out_Image := No_List_Image;
      Out_Position := Default_List_Style_Position;

      Split_Whitespace_Tokens (Input, Tokens);

      for T of Tokens loop
         declare
            Tok     : constant String := To_String (T);
            Tok_Low : constant String := Lower (Tok);
            URI     : Unbounded_String;
            Typ     : List_Style_Type_Value;
            Pos     : List_Style_Position_Value;
         begin
            if Parse_List_Style_Position_Value (Tok, Pos) then
               Out_Position := Pos;
               Has_Position := True;
            elsif Tok_Low = "none" then
               if not Has_Type and then not Has_Image then
                  Out_Type := (Kind => List_Style_None);
                  Out_Image := No_List_Image;
                  Has_Type := True;
                  Has_Image := True;
               elsif not Has_Type then
                  Out_Type := (Kind => List_Style_None);
                  Has_Type := True;
               elsif not Has_Image then
                  Out_Image := No_List_Image;
                  Has_Image := True;
               end if;
            elsif Parse_URL_Function (Tok, URI) then
               Out_Image := List_Image (To_String (URI));
               Has_Image := True;
            elsif Parse_List_Style_Type_Value (Tok, Typ) then
               Out_Type := Typ;
               Has_Type := True;
            end if;
         end;
      end loop;

      return Has_Type or else Has_Image or else Has_Position;
   end Parse_List_Style_Shorthand;

   function To_Length (L : Parsed_Length) return Length_Value is
   begin
      case L.Unit is
         when Px      => return Px (L.Amount);
         when Dip     => return Dip (L.Amount);
         when Em      => return Em (L.Amount);
         when Root_Em => return Root_Em (L.Amount);
         when Pct     => return Pct (L.Amount);
         when Vw      => return Vw (L.Amount);
         when Vh      => return Vh (L.Amount);
      end case;
   end To_Length;

   function Hex_Digit (C : Character) return Integer is
   begin
      if C in '0' .. '9' then
         return Character'Pos (C) - Character'Pos ('0');
      elsif C in 'a' .. 'f' then
         return 10 + Character'Pos (C) - Character'Pos ('a');
      elsif C in 'A' .. 'F' then
         return 10 + Character'Pos (C) - Character'Pos ('A');
      else
         return -1;
      end if;
   end Hex_Digit;

   function Parse_Hex_Byte (S : String; Value : out Natural) return Boolean is
      H1, H2 : Integer;
   begin
      if S'Length /= 2 then
         return False;
      end if;

      H1 := Hex_Digit (S (S'First));
      H2 := Hex_Digit (S (S'First + 1));
      if H1 < 0 or else H2 < 0 then
         return False;
      end if;

      Value := Natural (H1 * 16 + H2);
      return True;
   end Parse_Hex_Byte;

   function Parse_Color (Input : String; Out_Color : out Color_Value) return Boolean is
      V : constant String := Lower (Trimmed (Input));
      R, G, B : Natural := 0;
      A : Float := 1.0;
      Open_Idx : Natural;
      Close_Idx : Natural;

      function Parse_RGB_Args (Args : String;
                               Has_Alpha : Boolean;
                               Out_R, Out_G, Out_B : out Natural;
                               Out_A : out Float) return Boolean is
         P1, P2, P3 : Natural;
      begin
         P1 := Fix.Index (Args, ",");
         if P1 = 0 then
            return False;
         end if;

         P2 := Fix.Index (Args, ",", From => P1 + 1);
         if P2 = 0 then
            return False;
         end if;

         if not Parse_Natural (Args (Args'First .. P1 - 1), Out_R)
           or else not Parse_Natural (Args (P1 + 1 .. P2 - 1), Out_G)
         then
            return False;
         end if;

         if Has_Alpha then
            P3 := Fix.Index (Args, ",", From => P2 + 1);
            if P3 = 0 then
               return False;
            end if;

            if not Parse_Natural (Args (P2 + 1 .. P3 - 1), Out_B)
              or else not Parse_Number (Args (P3 + 1 .. Args'Last), Out_A)
            then
               return False;
            end if;
         else
            if not Parse_Natural (Args (P2 + 1 .. Args'Last), Out_B) then
               return False;
            end if;
            Out_A := 1.0;
         end if;

         return True;
      end Parse_RGB_Args;

   begin
      declare
         Parsed_Name : Named_Color;
      begin
         if Parse_Named_Color (V, Parsed_Name) then
            Out_Color := C (Parsed_Name);
            return True;
         end if;
      end;

      if V'Length = 4 and then V (V'First) = '#' then
         declare
            R1 : constant Integer := Hex_Digit (V (V'First + 1));
            G1 : constant Integer := Hex_Digit (V (V'First + 2));
            B1 : constant Integer := Hex_Digit (V (V'First + 3));
         begin
            if R1 < 0 or else G1 < 0 or else B1 < 0 then
               return False;
            end if;
            Out_Color := RGB (Natural (R1 * 17), Natural (G1 * 17), Natural (B1 * 17));
            return True;
         end;
      end if;

      if V'Length = 7 and then V (V'First) = '#' then
         if Parse_Hex_Byte (V (V'First + 1 .. V'First + 2), R)
           and then Parse_Hex_Byte (V (V'First + 3 .. V'First + 4), G)
           and then Parse_Hex_Byte (V (V'First + 5 .. V'First + 6), B)
         then
            Out_Color := RGB (R, G, B);
            return True;
         end if;
      end if;

      if V'Length = 9 and then V (V'First) = '#' then
         declare
            Ab : Natural := 255;
         begin
            if Parse_Hex_Byte (V (V'First + 1 .. V'First + 2), R)
              and then Parse_Hex_Byte (V (V'First + 3 .. V'First + 4), G)
              and then Parse_Hex_Byte (V (V'First + 5 .. V'First + 6), B)
              and then Parse_Hex_Byte (V (V'First + 7 .. V'First + 8), Ab)
            then
               Out_Color := RGBA (R, G, B, Float (Ab) / 255.0);
               return True;
            end if;
         end;
      end if;

      if Fix.Index (V, "rgb(") = 1 then
         Open_Idx := Fix.Index (V, "(");
         Close_Idx := Fix.Index (V, ")", From => Open_Idx + 1);
         if Open_Idx > 0 and then Close_Idx > Open_Idx then
            if Parse_RGB_Args (Trimmed (V (Open_Idx + 1 .. Close_Idx - 1)), False, R, G, B, A) then
               Out_Color := RGB (R, G, B);
               return True;
            end if;
         end if;
      elsif Fix.Index (V, "rgba(") = 1 then
         Open_Idx := Fix.Index (V, "(");
         Close_Idx := Fix.Index (V, ")", From => Open_Idx + 1);
         if Open_Idx > 0 and then Close_Idx > Open_Idx then
            if Parse_RGB_Args (Trimmed (V (Open_Idx + 1 .. Close_Idx - 1)), True, R, G, B, A) then
               Out_Color := RGBA (R, G, B, A);
               return True;
            end if;
         end if;
      end if;

      return False;
   end Parse_Color;

   function Parse_Length_List (Input : String; Out_List : out Length_Vectors.Vector) return Boolean is
      I : Positive := Input'First;
   begin
      Out_List.Clear;
      while I <= Input'Last loop
         while I <= Input'Last and then Is_Whitespace (Input (I)) loop
            I := I + 1;
         end loop;
         exit when I > Input'Last;

         declare
            J : Natural := I;
            L : Parsed_Length;
         begin
            while J <= Input'Last and then not Is_Whitespace (Input (J)) loop
               J := J + 1;
            end loop;

            if not Parse_Length (Input (I .. J - 1), L) then
               return False;
            end if;

            Out_List.Append (L);
            I := J + 1;
         end;
      end loop;

      return Out_List.Length > 0;
   end Parse_Length_List;

   function Parse_Box (Input : String; Out_Box : out CSS_Box_Value) return Boolean is
      L : Length_Vectors.Vector;
   begin
      if not Parse_Length_List (Input, L) then
         return False;
      end if;

      case Natural (L.Length) is
         when 1 => Out_Box := CSS_Box (To_Length (L (1)));
         when 2 => Out_Box := CSS_Box (To_Length (L (1)), To_Length (L (2)));
         when 3 => Out_Box := CSS_Box (To_Length (L (1)), To_Length (L (2)), To_Length (L (3)), To_Length (L (2)));
         when others => Out_Box := CSS_Box (To_Length (L (1)), To_Length (L (2)), To_Length (L (3)), To_Length (L (4)));
      end case;

      return True;
   end Parse_Box;

   function Parse_Border_Width (Input : String; Out_Width : out Border_Width_Value) return Boolean is
      L : Length_Vectors.Vector;
   begin
      if not Parse_Length_List (Input, L) then
         return False;
      end if;

      case Natural (L.Length) is
         when 1 => Out_Width := Border_Width (To_Length (L (1)));
         when 2 => Out_Width := Border_Width (To_Length (L (1)), To_Length (L (2)));
         when 3 => Out_Width := Border_Width (To_Length (L (1)), To_Length (L (2)), To_Length (L (3)), To_Length (L (2)));
         when others => Out_Width := Border_Width (To_Length (L (1)), To_Length (L (2)), To_Length (L (3)), To_Length (L (4)));
      end case;

      return True;
   end Parse_Border_Width;

   function Parse_Border_Radius (Input : String; Out_Radius : out Border_Radius_Value) return Boolean is
      L : Length_Vectors.Vector;
   begin
      if not Parse_Length_List (Input, L) then
         return False;
      end if;

      case Natural (L.Length) is
         when 1 => Out_Radius := Radius (To_Length (L (1)));
         when 2 => Out_Radius := Radius (To_Length (L (1)), To_Length (L (2)));
         when 3 => Out_Radius := Radius (To_Length (L (1)), To_Length (L (2)), To_Length (L (3)), To_Length (L (2)));
         when others => Out_Radius := Radius (To_Length (L (1)), To_Length (L (2)), To_Length (L (3)), To_Length (L (4)));
      end case;

      return True;
   end Parse_Border_Radius;

   function Parse_Size_Value (Input : String; Out_Size : out Size_Value) return Boolean is
      V : constant String := Lower (Trimmed (Input));
      L : Parsed_Length;
   begin
      if V = "auto" then Out_Size := Auto_Size; return True; end if;
      if V = "min-content" then Out_Size := Min_Content_Size; return True; end if;
      if V = "max-content" then Out_Size := Max_Content_Size; return True; end if;
      if V = "fit-content" then Out_Size := Fit_Content_Size; return True; end if;
      if Parse_Length (V, L) then Out_Size := Size (To_Length (L)); return True; end if;
      return False;
   end Parse_Size_Value;

   function Box_To_Sides (B : CSS_Box_Value) return CSS_Box_Sides is
   begin
      case B.Kind is
         when Gap_Uniform =>
            return [others => B.All_Sides];
         when Axis =>
            return (
              Top => B.Vertical,
              Right => B.Horizontal,
              Bottom => B.Vertical,
              Left => B.Horizontal);
         when Per_Side =>
            return B.Sides;
      end case;
   end Box_To_Sides;

   function Set_Box_Side (B : CSS_Box_Value;
                          Side : Edge;
                          Value : Length_Value) return CSS_Box_Value is
      Sides : CSS_Box_Sides := Box_To_Sides (B);
   begin
      Sides (Side) := Value;
      return CSS_Box (Sides (Top), Sides (Right), Sides (Bottom), Sides (Left));
   end Set_Box_Side;

   function Parse_Box_Shadow (Input : String; Out_Shadow : out Box_Shadow_Value) return Boolean is
      V : constant String := Lower (Trimmed (Input));
      Color_Start : Natural := 0;
      Color_End   : Natural := 0;
      Col : Color_Value;
      Len_Text : Unbounded_String;
      Lens : Length_Vectors.Vector;
   begin
      if V = "none" then
         Out_Shadow := No_Shadow;
         return True;
      end if;

      if Fix.Index (V, "rgba(") > 0 then
         Color_Start := Fix.Index (V, "rgba(");
         Color_End := Fix.Index (V, ")", From => Color_Start + 5);
      elsif Fix.Index (V, "rgb(") > 0 then
         Color_Start := Fix.Index (V, "rgb(");
         Color_End := Fix.Index (V, ")", From => Color_Start + 4);
      end if;

      if Color_Start > 0 and then Color_End >= Color_Start then
         if not Parse_Color (V (Color_Start .. Color_End), Col) then
            return False;
         end if;

         if Color_Start > V'First then
            Append (Len_Text, Trimmed (V (V'First .. Color_Start - 1)));
         end if;
         if Color_End < V'Last then
            if Length (Len_Text) > 0 then
               Append (Len_Text, " ");
            end if;
            Append (Len_Text, Trimmed (V (Color_End + 1 .. V'Last)));
         end if;
      else
         Col := RGBA (0, 0, 0, 0.25);
         Append (Len_Text, V);
      end if;

      if not Parse_Length_List (Trimmed (To_String (Len_Text)), Lens)
        or else Natural (Lens.Length) < 2
      then
         return False;
      end if;

      Out_Shadow := Shadow (
         Offset_X => To_Length (Lens (1)),
         Offset_Y => To_Length (Lens (2)),
         Blur     => (if Lens.Length > 2 then To_Length (Lens (3)) else Px (0.0)),
         Spread   => (if Lens.Length > 3 then To_Length (Lens (4)) else Px (0.0)),
         Color    => Col);

      return True;
   end Parse_Box_Shadow;

   function Parse_Transition_Duration (Input : String; Seconds : out Float) return Boolean is
      V : constant String := Lower (Trimmed (Input));
      N : Float;
   begin
      if V = "0" then
         Seconds := 0.0;
         return True;
      elsif Ends_With (V, "ms") and then V'Length > 2 then
         if Parse_Number (V (V'First .. V'Last - 2), N) then
            Seconds := N / 1000.0;
            return True;
         end if;
      elsif Ends_With (V, "s") and then V'Length > 1 then
         if Parse_Number (V (V'First .. V'Last - 1), N) then
            Seconds := N;
            return True;
         end if;
      end if;

      return False;
   end Parse_Transition_Duration;

   function Parse_Transition_Easing (Input : String; Easing : out Easing_Kind) return Boolean is
      V : constant String := Lower (Trimmed (Input));
   begin
      if V = "linear" then
         Easing := Linear;
      elsif V = "ease-in" then
         Easing := Ease_In;
      elsif V = "ease-out" then
         Easing := Ease_Out;
      elsif V = "ease-in-out" or else V = "ease" then
         Easing := Ease_In_Out;
      else
         return False;
      end if;

      return True;
   end Parse_Transition_Easing;

   function Parse_Transition_Property (Input : String; Properties : out Property_Set) return Boolean is
      V : constant String := Lower (Trimmed (Input));
   begin
      if V = "all" then
         Properties := All_Properties;
      elsif V = "color" then
         Properties := Props (Prop_Color);
      elsif V = "background-color" or else V = "background" then
         Properties := Props (Prop_Background_Color);
      elsif V = "border-color" then
         Properties := Props (Prop_Border_Color);
      elsif V = "border-width" then
         Properties := Props (Prop_Border_Width);
      elsif V = "border-radius" then
         Properties := Props (Prop_Border_Radius);
      elsif V = "padding" then
         Properties := Props (Prop_Padding);
      elsif V = "margin" then
         Properties := Props (Prop_Margin);
      elsif V = "opacity" then
         Properties := Props (Prop_Opacity);
      elsif V = "box-shadow" then
         Properties := Props (Prop_Box_Shadow);
      elsif V = "font-size" then
         Properties := Props (Prop_Font_Size);
      elsif V = "none" then
         Properties := No_Properties;
      else
         return False;
      end if;

      return True;
   end Parse_Transition_Property;

   function Parse_Transition (Input : String; Out_Transition : out Transition_Spec) return Boolean is
      V : constant String := Lower (Trimmed (Input));
      First_End : constant Natural := Fix.Index (V, ",");
      First : constant String :=
        (if First_End = 0 then V else Trimmed (V (V'First .. First_End - 1)));

      Pos : Positive;
      Duration : Float := 0.0;
      Duration_Set : Boolean := False;
      Easing : Easing_Kind := Ease_In_Out;
      Properties : Property_Set := All_Properties;
      Tmp_Duration : Float;
      Tmp_Easing : Easing_Kind;
      Tmp_Props : Property_Set;
   begin
      if V = "none" then
         Out_Transition := No_Transition;
         return True;
      end if;

      if First'Length = 0 then
         return False;
      end if;

      Pos := First'First;
      while Pos <= First'Last loop
         while Pos <= First'Last and then Is_Whitespace (First (Pos)) loop
            Pos := Pos + 1;
         end loop;
         exit when Pos > First'Last;

         declare
            Token_End : Natural := Pos;
         begin
            while Token_End <= First'Last and then not Is_Whitespace (First (Token_End)) loop
               Token_End := Token_End + 1;
            end loop;

            declare
               Token : constant String := First (Pos .. Token_End - 1);
            begin
               if Parse_Transition_Duration (Token, Tmp_Duration) then
                  Duration := Tmp_Duration;
                  Duration_Set := True;
               elsif Parse_Transition_Easing (Token, Tmp_Easing) then
                  Easing := Tmp_Easing;
               elsif Parse_Transition_Property (Token, Tmp_Props) then
                  Properties := Tmp_Props;
               end if;
            end;

            Pos := Token_End + 1;
         end;
      end loop;

      if not Duration_Set then
         return False;
      end if;

      Out_Transition := (Duration => Duration, Easing => Easing, Properties => Properties);
      return True;
   end Parse_Transition;

   function Parse_Part (Input : String; P : out Part_Kind) return Boolean is
      V : constant String := Lower (Trimmed (Input));
   begin
      if V = "main" then P := Main_Part;
      elsif V = "label" then P := Label_Part;
      elsif V = "cursor" then P := Cursor_Part;
      elsif V = "selected" then P := Selected_Part;
      elsif V = "icon" then P := Icon_Part;
      elsif V = "indicator" then P := Indicator_Part;
      elsif V = "scroll" then P := Scroll_Part;
      elsif V = "knob" then P := Knob_Part;
      elsif V = "items" then P := Items_Part;
      elsif V = "any" then P := Any_Part;
      elsif V = "custom" then P := Custom_Part;
      else
         return False;
      end if;

      return True;
   end Parse_Part;

   procedure Apply_Pseudo (Pseudo_Name : String;
                           Negated     : Boolean;
                           Part_Scope  : Boolean;
                           Selector    : in out State_Selector;
                           Has_State   : in out Boolean) is
      N : constant String := Lower (Trimmed (Pseudo_Name));
      S : Widget_State;
      Use_Part : Boolean := False;
   begin
      if N = "hover" or else N = "hovered" then
         S := State_Hovered;
         Use_Part := Part_Scope;
      elsif N = "active" or else N = "pressed" then
         S := State_Pressed;
         Use_Part := Part_Scope;
      elsif N = "focus" or else N = "focused" then
         S := State_Focused;
      elsif N = "disabled" then
         S := State_Disabled;
      elsif N = "enabled" then
         S := State_Disabled;
         if Part_Scope then
            if Negated then
               Selector.Part_Required (S) := True;
            else
               Selector.Part_Excluded (S) := True;
            end if;
         else
            if Negated then
               Selector.Widget_Required (S) := True;
            else
               Selector.Widget_Excluded (S) := True;
            end if;
         end if;
         Has_State := True;
         return;
      elsif N = "checked" or else N = "selected" then
         S := State_Selected;
      else
         return;
      end if;

      if Use_Part then
         if Negated then
            Selector.Part_Excluded (S) := True;
         else
            Selector.Part_Required (S) := True;
         end if;
      else
         if Negated then
            Selector.Widget_Excluded (S) := True;
         else
            Selector.Widget_Required (S) := True;
         end if;
      end if;

      Has_State := True;
   end Apply_Pseudo;

   procedure Parse_Pseudo_List (Input      : String;
                                Part_Scope : Boolean;
                                Selector   : in out State_Selector;
                                Has_State  : in out Boolean) is
      I : Positive := Input'First;
   begin
      while I <= Input'Last loop
         if Input (I) /= ':' then
            I := I + 1;
         elsif I + 4 <= Input'Last and then Lower (Input (I .. I + 4)) = ":not(" then
            declare
               J : Natural := I + 5;
            begin
               while J <= Input'Last and then Input (J) /= ')' loop
                  J := J + 1;
               end loop;

               if J <= Input'Last and then J > I + 5 then
                  declare
                     Inner : constant String := Trimmed (Input (I + 5 .. J - 1));
                     Name  : constant String := (if Inner'Length > 0 and then Inner (Inner'First) = ':'
                                                 then Inner (Inner'First + 1 .. Inner'Last)
                                                 else Inner);
                  begin
                     Apply_Pseudo (Name, True, Part_Scope, Selector, Has_State);
                  end;
               end if;

               I := (if J < Input'Last then J + 1 else Input'Last + 1);
            end;
         else
            declare
               J : Natural := I + 1;
            begin
               while J <= Input'Last and then
                 (Input (J) in 'a' .. 'z'
                  or else Input (J) in 'A' .. 'Z'
                  or else Input (J) in '0' .. '9'
                  or else Input (J) = '-')
               loop
                  J := J + 1;
               end loop;

               if J > I + 1 then
                  Apply_Pseudo (Input (I + 1 .. J - 1), False, Part_Scope, Selector, Has_State);
               end if;

               I := J;
            end;
         end if;
      end loop;
   end Parse_Pseudo_List;

   function Parse_Selector (Input : String; Out_Sel : out Parsed_Selector) return Boolean is
      Raw : Unbounded_String := To_Unbounded_String (Trimmed (Input));
      Base : Unbounded_String := Null_Unbounded_String;
      Part : Unbounded_String := Null_Unbounded_String;
      Widget_Pseudo : Unbounded_String := Null_Unbounded_String;
      Part_Pseudo : Unbounded_String := Null_Unbounded_String;
      Sep : Natural;
      Colon : Natural;
      Part_Scope : Boolean := False;
   begin
      Out_Sel := (others => <>);

      if Length (Raw) = 0 then
         return False;
      end if;

      declare
         R : constant String := To_String (Raw);
      begin
         if R (R'First) = '.' then
            if R'Length = 1 then
               return False;
            end if;
            Out_Sel.Kind := Class_Selector;
            Raw := To_Unbounded_String (R (R'First + 1 .. R'Last));
         elsif R (R'First) = '#' then
            if R'Length = 1 then
               return False;
            end if;
            Out_Sel.Kind := Id_Selector;
            Raw := To_Unbounded_String (R (R'First + 1 .. R'Last));
         else
            Out_Sel.Kind := Tag_Selector;
         end if;
      end;

      declare
         R : constant String := To_String (Raw);
      begin
         Sep := Fix.Index (R, "::");
         if Sep > 0 then
            Base := To_Unbounded_String (Trimmed (R (R'First .. Sep - 1)));
            Part := To_Unbounded_String (Trimmed (R (Sep + 2 .. R'Last)));
         else
            Base := Raw;
         end if;
      end;

      if To_String (Base) = "" then
         return False;
      end if;

      Colon := Fix.Index (To_String (Base), ":");
      if Colon > 0 then
         declare
            B : constant String := To_String (Base);
         begin
            Widget_Pseudo := To_Unbounded_String (B (Colon .. B'Last));
            Base := To_Unbounded_String (Trimmed (B (B'First .. Colon - 1)));
         end;
      end if;

      if To_String (Base) = "" then
         return False;
      end if;

      Out_Sel.Name := To_Unbounded_String (Lower (To_String (Base)));
      Out_Sel.Part := Main_Part;

      if To_String (Part) /= "" then
         Colon := Fix.Index (To_String (Part), ":");
         if Colon > 0 then
            declare
               P : constant String := To_String (Part);
            begin
               Part_Pseudo := To_Unbounded_String (P (Colon .. P'Last));
               Part := To_Unbounded_String (Trimmed (P (P'First .. Colon - 1)));
            end;
         end if;

         if not Parse_Part (To_String (Part), Out_Sel.Part) then
            return False;
         end if;

         Part_Scope := Out_Sel.Part /= Main_Part;
      end if;

      if To_String (Widget_Pseudo) /= "" then
         Parse_Pseudo_List (To_String (Widget_Pseudo), False, Out_Sel.Selector, Out_Sel.Has_State);
      end if;

      if To_String (Part_Pseudo) /= "" then
         Parse_Pseudo_List (To_String (Part_Pseudo), Part_Scope, Out_Sel.Selector, Out_Sel.Has_State);
      end if;

      return True;
   end Parse_Selector;

   procedure Apply_Property (Rules : in out Style_Rules;
                             Name  : String;
                             Value : String) is
      P : constant String := Lower (Trimmed (Name));
      V : constant String := Trimmed (Value);
      LV : constant String := Lower (V);
      CVal : Color_Value;
      LVal : Parsed_Length;
      Box  : CSS_Box_Value;
      BW   : Border_Width_Value;
      BR   : Border_Radius_Value;
      SVal : Size_Value;
      Shadow_Val : Box_Shadow_Value;
      List_Type_Val : List_Style_Type_Value;
      List_Image_Val : List_Style_Image_Value;
      List_Position_Val : List_Style_Position_Value;
      List_Type_Set : Boolean := False;
      List_Image_Set : Boolean := False;
      List_Position_Set : Boolean := False;
      URI_Text : Unbounded_String;
      Ls : Length_Vectors.Vector;
      F : Float;
      I : Integer;
      N : Natural;
   begin
      if P = "color" then
         if Parse_Color (V, CVal) then Rules.Color := Set (CVal); end if;
      elsif P = "background-color" or else P = "background" then
         if Parse_Color (V, CVal) then Rules.Background_Color := Set_Bg (CVal); end if;
      elsif P = "padding" then
         if Parse_Box (V, Box) then Rules.Padding := Set (Box); end if;
      elsif P = "padding-top" then
         if Parse_Length (V, LVal) then
            Rules.Padding := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Padding)
                 then Opt_Box.Resolve (Rules.Padding)
                 else Default_CSS_Box),
                Top,
                To_Length (LVal)));
         end if;
      elsif P = "padding-right" then
         if Parse_Length (V, LVal) then
            Rules.Padding := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Padding)
                 then Opt_Box.Resolve (Rules.Padding)
                 else Default_CSS_Box),
                Right,
                To_Length (LVal)));
         end if;
      elsif P = "padding-bottom" then
         if Parse_Length (V, LVal) then
            Rules.Padding := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Padding)
                 then Opt_Box.Resolve (Rules.Padding)
                 else Default_CSS_Box),
                Bottom,
                To_Length (LVal)));
         end if;
      elsif P = "padding-left" then
         if Parse_Length (V, LVal) then
            Rules.Padding := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Padding)
                 then Opt_Box.Resolve (Rules.Padding)
                 else Default_CSS_Box),
                Left,
                To_Length (LVal)));
         end if;
      elsif P = "margin" then
         if Parse_Box (V, Box) then Rules.Margin := Set (Box); end if;
      elsif P = "margin-top" then
         if Parse_Length (V, LVal) then
            Rules.Margin := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Margin)
                 then Opt_Box.Resolve (Rules.Margin)
                 else Default_CSS_Box),
                Top,
                To_Length (LVal)));
         end if;
      elsif P = "margin-right" then
         if Parse_Length (V, LVal) then
            Rules.Margin := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Margin)
                 then Opt_Box.Resolve (Rules.Margin)
                 else Default_CSS_Box),
                Right,
                To_Length (LVal)));
         end if;
      elsif P = "margin-bottom" then
         if Parse_Length (V, LVal) then
            Rules.Margin := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Margin)
                 then Opt_Box.Resolve (Rules.Margin)
                 else Default_CSS_Box),
                Bottom,
                To_Length (LVal)));
         end if;
      elsif P = "margin-left" then
         if Parse_Length (V, LVal) then
            Rules.Margin := Set (
              Set_Box_Side (
                (if Opt_Box.Is_Set (Rules.Margin)
                 then Opt_Box.Resolve (Rules.Margin)
                 else Default_CSS_Box),
                Left,
                To_Length (LVal)));
         end if;
      elsif P = "border-width" then
         if Parse_Border_Width (V, BW) then Rules.Border_Width := Set (BW); end if;
      elsif P = "border-color" then
         if Parse_Color (V, CVal) then Rules.Border_Color := Set (Border_Color (CVal)); end if;
      elsif P = "border-style" then
         if LV = "none" then Rules.Border_Style := Set (Border_Style (None_Style));
         elsif LV = "hidden" then Rules.Border_Style := Set (Border_Style (Hidden));
         elsif LV = "dotted" then Rules.Border_Style := Set (Border_Style (Dotted));
         elsif LV = "dashed" then Rules.Border_Style := Set (Border_Style (Dashed));
         elsif LV = "solid" then Rules.Border_Style := Set (Border_Style (Solid));
         elsif LV = "double" then Rules.Border_Style := Set (Border_Style (Double));
         elsif LV = "groove" then Rules.Border_Style := Set (Border_Style (Groove));
         elsif LV = "ridge" then Rules.Border_Style := Set (Border_Style (Ridge));
         elsif LV = "inset" then Rules.Border_Style := Set (Border_Style (Inset));
         elsif LV = "outset" then Rules.Border_Style := Set (Border_Style (Outset));
         end if;
      elsif P = "border-radius" then
         if Parse_Border_Radius (V, BR) then Rules.Border_Radius := Set (BR); end if;
      elsif P = "width" then
         if Parse_Size_Value (V, SVal) then Rules.Width := Set (SVal); end if;
      elsif P = "height" then
         if Parse_Size_Value (V, SVal) then Rules.Height := Set (SVal); end if;
      elsif P = "min-width" then
         if Parse_Size_Value (V, SVal) then Rules.Min_Width := Set (SVal); end if;
      elsif P = "max-width" then
         if Parse_Size_Value (V, SVal) then Rules.Max_Width := Set (SVal); end if;
      elsif P = "min-height" then
         if Parse_Size_Value (V, SVal) then Rules.Min_Height := Set (SVal); end if;
      elsif P = "max-height" then
         if Parse_Size_Value (V, SVal) then Rules.Max_Height := Set (SVal); end if;
      elsif P = "font-size" then
         if Parse_Length (V, LVal) then Rules.Font_Size := Set_Font (To_Length (LVal)); end if;
      elsif P = "font-weight" then
         if LV = "100" or else LV = "thin" then Rules.Font_Weight := Set (Weight_Thin);
         elsif LV = "200" or else LV = "extra-light" or else LV = "ultralight" then Rules.Font_Weight := Set (Weight_Extra_Light);
         elsif LV = "300" or else LV = "light" then Rules.Font_Weight := Set (Weight_Light);
         elsif LV = "400" or else LV = "normal" then Rules.Font_Weight := Set (Weight_Normal);
         elsif LV = "500" or else LV = "medium" then Rules.Font_Weight := Set (Weight_Medium);
         elsif LV = "600" or else LV = "semi-bold" or else LV = "semibold" then Rules.Font_Weight := Set (Weight_Semi_Bold);
         elsif LV = "700" or else LV = "bold" then Rules.Font_Weight := Set (Weight_Bold);
         elsif LV = "800" or else LV = "extra-bold" or else LV = "extrabold" then Rules.Font_Weight := Set (Weight_Extra_Bold);
         elsif LV = "900" or else LV = "black" then Rules.Font_Weight := Set (Weight_Black);
         end if;
      elsif P = "font-style" then
         if LV = "normal" then Rules.Font_Style := Set (Style_Normal);
         elsif LV = "italic" then Rules.Font_Style := Set (Style_Italic);
         elsif LV = "oblique" then Rules.Font_Style := Set (Style_Oblique);
         end if;
      elsif P = "text-decoration" then
         if LV = "none" then Rules.Text_Decoration := Set (Decoration_None);
         elsif LV = "underline" then Rules.Text_Decoration := Set (Decoration_Underline);
         elsif LV = "overline" then Rules.Text_Decoration := Set (Decoration_Overline);
         elsif LV = "line-through" then Rules.Text_Decoration := Set (Decoration_Line_Through);
         end if;
      elsif P = "list-style-type" then
         if Parse_List_Style_Type_Value (V, List_Type_Val) then
            Rules.List_Style_Type := Set (List_Type_Val);
         end if;
      elsif P = "background-image" then
         if LV = "none" then
            Rules.Background_Image := Set_Bg_Image (No_Background_Image);
         elsif Parse_URL_Function (V, URI_Text) then
            Rules.Background_Image := Set_Bg_Image
              (Background_Image_URL (To_String (URI_Text)));
         end if;
      elsif P = "list-style-image" then
         if LV = "none" then
            Rules.List_Style_Image := Set (No_List_Image);
         elsif Parse_URL_Function (V, URI_Text) then
            Rules.List_Style_Image := Set (List_Image (To_String (URI_Text)));
         end if;
      elsif P = "list-style-position" then
         if Parse_List_Style_Position_Value (V, List_Position_Val) then
            Rules.List_Style_Position := Set (List_Position_Val);
         end if;
      elsif P = "list-style" then
         if Parse_List_Style_Shorthand
           (V,
            List_Type_Val,
            List_Image_Val,
            List_Position_Val,
            List_Type_Set,
            List_Image_Set,
            List_Position_Set)
         then
            if List_Type_Set then
               Rules.List_Style_Type := Set (List_Type_Val);
            end if;
            if List_Image_Set then
               Rules.List_Style_Image := Set (List_Image_Val);
            end if;
            if List_Position_Set then
               Rules.List_Style_Position := Set (List_Position_Val);
            end if;
         end if;
      elsif P = "white-space" then
         if LV = "normal" then Rules.White_Space := Set (WS_Normal);
         elsif LV = "nowrap" then Rules.White_Space := Set (WS_Nowrap);
         elsif LV = "pre" then Rules.White_Space := Set (WS_Pre);
         elsif LV = "pre-wrap" then Rules.White_Space := Set (WS_Pre_Wrap);
         elsif LV = "pre-line" then Rules.White_Space := Set (WS_Pre_Line);
         end if;
      elsif P = "text-overflow" then
         if LV = "clip" then Rules.Text_Overflow := Set (Overflow_Clip);
         elsif LV = "ellipsis" then Rules.Text_Overflow := Set (Overflow_Ellipsis);
         end if;
      elsif P = "line-height" then
         if LV = "normal" then
            Rules.Line_Height := Set (Normal_Line_Height);
         elsif Parse_Number (V, F) then
            Rules.Line_Height := Set (Line_Height (F));
         elsif Parse_Length (V, LVal) then
            Rules.Line_Height := Set (Line_Height (To_Length (LVal)));
         end if;
      elsif P = "text-align" then
         if LV = "left" then Rules.Text_Align := Set (Text_Left);
         elsif LV = "right" then Rules.Text_Align := Set (Text_Right);
         elsif LV = "center" then Rules.Text_Align := Set (Text_Center);
         elsif LV = "justify" then Rules.Text_Align := Set (Text_Justify);
         elsif LV = "start" then Rules.Text_Align := Set (Text_Start);
         elsif LV = "end" then Rules.Text_Align := Set (Text_End);
         end if;
      elsif P = "text-wrap-mode" then
         if LV = "wrap" then Rules.Text_Wrap_Mode := Set (TWM_Wrap);
         elsif LV = "nowrap" then Rules.Text_Wrap_Mode := Set (TWM_Nowrap);
         end if;
      elsif P = "vertical-align" then
         if LV = "baseline" then Rules.Vertical_Align := Set (VA_Baseline);
         elsif LV = "top" then Rules.Vertical_Align := Set (VA_Top);
         elsif LV = "middle" then Rules.Vertical_Align := Set (VA_Middle);
         elsif LV = "bottom" then Rules.Vertical_Align := Set (VA_Bottom);
         elsif LV = "text-top" then Rules.Vertical_Align := Set (VA_Text_Top);
         elsif LV = "text-bottom" then Rules.Vertical_Align := Set (VA_Text_Bottom);
         end if;
      elsif P = "display" then
         if LV = "none" then Rules.Display := Set (Display_None);
         elsif LV = "block" then Rules.Display := Set (Block);
         elsif LV = "inline" then Rules.Display := Set (Inline);
         elsif LV = "inline-block" then Rules.Display := Set (Inline_Block);
         elsif LV = "flex" then Rules.Display := Set (Flex);
         elsif LV = "inline-flex" then Rules.Display := Set (Inline_Flex);
         elsif LV = "grid" then Rules.Display := Set (Grid);
         elsif LV = "inline-grid" then Rules.Display := Set (Inline_Grid);
         end if;
      elsif P = "position" then
         if LV = "static" then Rules.Position := Set (Static);
         elsif LV = "relative" then Rules.Position := Set (Relative);
         elsif LV = "absolute" then Rules.Position := Set (Absolute);
         elsif LV = "fixed" then Rules.Position := Set (Fixed);
         elsif LV = "sticky" then Rules.Position := Set (Sticky);
         end if;
      elsif P = "overflow" then
         if LV = "visible" then Rules.Overflow := Set (Overflow_Visible);
         elsif LV = "hidden" then Rules.Overflow := Set (Overflow_Hidden);
         elsif LV = "scroll" then Rules.Overflow := Set (Overflow_Scroll);
         elsif LV = "auto" then Rules.Overflow := Set (Overflow_Auto);
         end if;
      elsif P = "opacity" then
         if Parse_Number (V, F) then Rules.Opacity := Set (Opacity_Value (F)); end if;
      elsif P = "cursor" then
         if LV = "auto" then Rules.Cursor := Set (Cursor_Auto);
         elsif LV = "default" then Rules.Cursor := Set (Cursor_Default);
         elsif LV = "pointer" then Rules.Cursor := Set (Cursor_Pointer);
         elsif LV = "text" then Rules.Cursor := Set (Cursor_Text);
         elsif LV = "move" then Rules.Cursor := Set (Cursor_Move);
         elsif LV = "not-allowed" then Rules.Cursor := Set (Cursor_Not_Allowed);
         elsif LV = "wait" then Rules.Cursor := Set (Cursor_Wait);
         elsif LV = "crosshair" then Rules.Cursor := Set (Cursor_Crosshair);
         elsif LV = "grab" then Rules.Cursor := Set (Cursor_Grab);
         elsif LV = "grabbing" then Rules.Cursor := Set (Cursor_Grabbing);
         end if;
      elsif P = "visibility" then
         if LV = "visible" then Rules.Visibility := Set (Visibility_Visible);
         elsif LV = "hidden" then Rules.Visibility := Set (Visibility_Hidden);
         elsif LV = "collapse" then Rules.Visibility := Set (Visibility_Collapse);
         end if;
      elsif P = "object-fit" then
         if LV = "fill" then Rules.Object_Fit := Set (Fit_Fill);
         elsif LV = "contain" then Rules.Object_Fit := Set (Fit_Contain);
         elsif LV = "cover" then Rules.Object_Fit := Set (Fit_Cover);
         elsif LV = "none" then Rules.Object_Fit := Set (Fit_None);
         elsif LV = "scale-down" then Rules.Object_Fit := Set (Fit_Scale_Down);
         end if;
      elsif P = "flex-direction" then
         if LV = "row" then Rules.Flex_Direction := Set (Row);
         elsif LV = "row-reverse" then Rules.Flex_Direction := Set (Row_Reverse);
         elsif LV = "column" then Rules.Flex_Direction := Set (Column);
         elsif LV = "column-reverse" then Rules.Flex_Direction := Set (Column_Reverse);
         end if;
      elsif P = "flex-wrap" then
         if LV = "nowrap" then Rules.Flex_Wrap := Set (No_Wrap);
         elsif LV = "wrap" then Rules.Flex_Wrap := Set (Wrap);
         elsif LV = "wrap-reverse" then Rules.Flex_Wrap := Set (Wrap_Reverse);
         end if;
      elsif P = "justify-content" then
         if LV = "flex-start" or else LV = "start" then Rules.Justify_Content := Set (Flex_Start);
         elsif LV = "flex-end" or else LV = "end" then Rules.Justify_Content := Set (Flex_End);
         elsif LV = "center" then Rules.Justify_Content := Set (Center);
         elsif LV = "space-between" then Rules.Justify_Content := Set (Space_Between);
         elsif LV = "space-around" then Rules.Justify_Content := Set (Space_Around);
         elsif LV = "space-evenly" then Rules.Justify_Content := Set (Space_Evenly);
         end if;
      elsif P = "align-items" then
         if LV = "flex-start" or else LV = "start" then Rules.Align_Items := Set (Flex_Start);
         elsif LV = "flex-end" or else LV = "end" then Rules.Align_Items := Set (Flex_End);
         elsif LV = "center" then Rules.Align_Items := Set (Center);
         elsif LV = "baseline" then Rules.Align_Items := Set (Baseline);
         elsif LV = "stretch" then Rules.Align_Items := Set (Stretch);
         end if;
      elsif P = "align-self" then
         if LV = "auto" then Rules.Align_Self := Set (Align_Self_Value'(Auto));
         elsif LV = "flex-start" or else LV = "start" then Rules.Align_Self := Set (Align_Self_Value'(Flex_Start));
         elsif LV = "flex-end" or else LV = "end" then Rules.Align_Self := Set (Align_Self_Value'(Flex_End));
         elsif LV = "center" then Rules.Align_Self := Set (Align_Self_Value'(Center));
         elsif LV = "baseline" then Rules.Align_Self := Set (Align_Self_Value'(Baseline));
         elsif LV = "stretch" then Rules.Align_Self := Set (Align_Self_Value'(Stretch));
         end if;
      elsif P = "align-content" then
         if LV = "flex-start" or else LV = "start" then Rules.Align_Content := Set (Align_Content_Value'(Flex_Start));
         elsif LV = "flex-end" or else LV = "end" then Rules.Align_Content := Set (Align_Content_Value'(Flex_End));
         elsif LV = "center" then Rules.Align_Content := Set (Align_Content_Value'(Center));
         elsif LV = "space-between" then Rules.Align_Content := Set (Align_Content_Value'(Space_Between));
         elsif LV = "space-around" then Rules.Align_Content := Set (Align_Content_Value'(Space_Around));
         elsif LV = "stretch" then Rules.Align_Content := Set (Align_Content_Value'(Stretch));
         end if;
      elsif P = "gap" then
         if Parse_Length_List (V, Ls) then
            if Ls.Length = 1 then Rules.Gap := Set (Gap (To_Length (Ls (1))));
            elsif Ls.Length >= 2 then Rules.Gap := Set (Gap (To_Length (Ls (1)), To_Length (Ls (2))));
            end if;
         end if;
      elsif P = "flex-grow" then
         if Parse_Number (V, F) then Rules.Flex_Grow := Set (Flex_Grow_Value (F)); end if;
      elsif P = "flex-shrink" then
         if Parse_Number (V, F) then Rules.Flex_Shrink := Set (Flex_Shrink_Value (F)); end if;
      elsif P = "flex-basis" then
         if LV = "auto" then Rules.Flex_Basis := Set (Auto_Basis);
         elsif LV = "content" then Rules.Flex_Basis := Set (Content_Basis);
         elsif Parse_Length (V, LVal) then Rules.Flex_Basis := Set (Basis (To_Length (LVal)));
         end if;
      elsif P = "order" then
         if Parse_Integer (V, I) then Rules.Order := Set (Order_Value (I)); end if;
      elsif P = "grid-template-columns" then
         declare
            TL : Grid_Track_List;
         begin
            if Parse_Grid_Track_List (V, TL) then
               Rules.Grid_Column_Tracks := TL;
               Rules.Grid_Columns := Set (Grid_Columns_Value (TL.Count));
            elsif Parse_Grid_Track_Count (V, N) then
               --  Fallback: token count > Max_Grid_Tracks; keep count only
               Rules.Grid_Columns := Set (Grid_Columns_Value (N));
            end if;
         end;
      elsif P = "grid-template-rows" then
         if Parse_Grid_Track_Count (V, N) then
            Rules.Grid_Rows := Set (Grid_Rows_Value (N));
         end if;
      elsif P = "grid-column" or else P = "grid-row" then
         declare
            Slash_Pos   : Natural := 0;
            Start_Val   : Integer;
            Span_Val    : Natural;
            Is_Col      : constant Boolean := P = "grid-column";
            Got_Start   : Boolean := False;
            Start_Line  : Natural := 0;
         begin
            --  Find slash separator
            for J in V'Range loop
               if V (J) = '/' then
                  Slash_Pos := J;
                  exit;
               end if;
            end loop;
            if Slash_Pos > 0 then
               --  "start / end" or "start / span N"
               declare
                  Left  : constant String := Trimmed (V (V'First .. Slash_Pos - 1));
                  Right : constant String := Lower (Trimmed (V (Slash_Pos + 1 .. V'Last)));
               begin
                  if Parse_Integer (Left, Start_Val) and then Start_Val > 0 then
                     Got_Start := True;
                     Start_Line := Natural (Start_Val);
                     if Is_Col then
                        Rules.Grid_Column := Set (Grid_Column_Value (Start_Val));
                     else
                        Rules.Grid_Row := Set (Grid_Row_Value (Start_Val));
                     end if;
                  end if;
                  if Right'Length > 5
                    and then Right (Right'First .. Right'First + 3) = "span"
                    and then Is_Whitespace (Right (Right'First + 4))
                  then
                     if Parse_Natural (Right (Right'First + 5 .. Right'Last), Span_Val)
                       and then Span_Val > 0
                     then
                        if Is_Col then
                           Rules.Grid_Column_Span := Set (Grid_Column_Span_Value (Span_Val));
                        else
                           Rules.Grid_Row_Span := Set (Grid_Row_Span_Value (Span_Val));
                        end if;
                     end if;
                  elsif Got_Start and then Parse_Integer (Right, Start_Val) then
                     --  "start / end_line" -> span = end - start
                     if Start_Val > Integer (Start_Line) then
                        if Is_Col then
                           Rules.Grid_Column_Span := Set (Grid_Column_Span_Value (Start_Val - Integer (Start_Line)));
                        else
                           Rules.Grid_Row_Span := Set (Grid_Row_Span_Value (Start_Val - Integer (Start_Line)));
                        end if;
                     end if;
                  end if;
               end;
            else
               --  No slash: "N" or "span N"
               if LV'Length > 5
                 and then LV (LV'First .. LV'First + 3) = "span"
                 and then Is_Whitespace (LV (LV'First + 4))
               then
                  if Parse_Natural (LV (LV'First + 5 .. LV'Last), Span_Val)
                    and then Span_Val > 0
                  then
                     if Is_Col then
                        Rules.Grid_Column_Span := Set (Grid_Column_Span_Value (Span_Val));
                     else
                        Rules.Grid_Row_Span := Set (Grid_Row_Span_Value (Span_Val));
                     end if;
                  end if;
               elsif Parse_Integer (V, Start_Val) and then Start_Val > 0 then
                  if Is_Col then
                     Rules.Grid_Column := Set (Grid_Column_Value (Start_Val));
                  else
                     Rules.Grid_Row := Set (Grid_Row_Value (Start_Val));
                  end if;
               end if;
            end if;
         end;
      elsif P = "outline-width" then
         if Parse_Length (V, LVal) then Rules.Outline_Width := Set_Outline_Width (To_Length (LVal)); end if;
      elsif P = "outline-color" then
         if Parse_Color (V, CVal) then Rules.Outline_Color := Set_Outline_Color (CVal); end if;
      elsif P = "outline-style" then
         if LV = "none" then Rules.Outline_Style := Set (Outline_None);
         elsif LV = "solid" then Rules.Outline_Style := Set (Outline_Solid);
         elsif LV = "dashed" then Rules.Outline_Style := Set (Outline_Dashed);
         elsif LV = "dotted" then Rules.Outline_Style := Set (Outline_Dotted);
         end if;
      elsif P = "outline-offset" then
         if Parse_Length (V, LVal) then Rules.Outline_Offset := Set_Outline_Offset (To_Length (LVal)); end if;
      elsif P = "outline" then
         declare
            Tokens : Token_Vectors.Vector;
            Tok_L  : Parsed_Length;
            Tok_C  : Color_Value;
         begin
            Split_Whitespace_Tokens (V, Tokens);
            for T of Tokens loop
               declare
                  Tok : constant String := To_String (T);
                  Tok_Low : constant String := Lower (Tok);
               begin
                  if Tok_Low = "none" then
                     Rules.Outline_Style := Set (Outline_None);
                  elsif Tok_Low = "solid" then
                     Rules.Outline_Style := Set (Outline_Solid);
                  elsif Tok_Low = "dashed" then
                     Rules.Outline_Style := Set (Outline_Dashed);
                  elsif Tok_Low = "dotted" then
                     Rules.Outline_Style := Set (Outline_Dotted);
                  elsif Parse_Color (Tok, Tok_C) then
                     Rules.Outline_Color := Set_Outline_Color (Tok_C);
                  elsif Parse_Length (Tok, Tok_L) then
                     Rules.Outline_Width := Set_Outline_Width (To_Length (Tok_L));
                  end if;
               end;
            end loop;
         end;
      elsif P = "box-shadow" then
         if Parse_Box_Shadow (V, Shadow_Val) then Rules.Box_Shadow := Set (Shadow_Val); end if;
      elsif P = "transition" then
         declare
            T : Transition_Spec;
         begin
            if Parse_Transition (V, T) then
               Rules.Transition := Set (T);
            end if;
         end;
      end if;
   end Apply_Property;

   function Parse_Rules (CSS : String;
                         Out_Rules : out Parsed_Rule_Vectors.Vector;
                         Out_Error : out Unbounded_String) return Boolean is
      Clean : constant String := Strip_Comments (CSS);
      Pos : Positive := Clean'First;
   begin
      Out_Rules.Clear;
      Out_Error := Null_Unbounded_String;

      while Pos <= Clean'Last loop
         while Pos <= Clean'Last and then Is_Whitespace (Clean (Pos)) loop
            Pos := Pos + 1;
         end loop;
         exit when Pos > Clean'Last;

         declare
            Open_Brace : constant Natural := Fix.Index (Clean, "{", From => Pos);
         begin
            exit when Open_Brace = 0;

            declare
               Selector_Block : constant String := Trimmed (Clean (Pos .. Open_Brace - 1));
               Close_Brace    : constant Natural := Fix.Index (Clean, "}", From => Open_Brace + 1);
            begin
               if Close_Brace = 0 then
                  Out_Error := To_Unbounded_String ("Unclosed CSS block");
                  return False;
               end if;

               declare
                  Props_Block : constant String := Trimmed (Clean (Open_Brace + 1 .. Close_Brace - 1));
                  Sel_Pos : Positive := Selector_Block'First;
               begin
                  while Sel_Pos <= Selector_Block'Last loop
                     while Sel_Pos <= Selector_Block'Last and then Is_Whitespace (Selector_Block (Sel_Pos)) loop
                        Sel_Pos := Sel_Pos + 1;
                     end loop;
                     exit when Sel_Pos > Selector_Block'Last;

                     declare
                        Comma : constant Natural := Fix.Index (Selector_Block, ",", From => Sel_Pos);
                        Sel_Text : constant String :=
                          (if Comma = 0
                           then Trimmed (Selector_Block (Sel_Pos .. Selector_Block'Last))
                           else Trimmed (Selector_Block (Sel_Pos .. Comma - 1)));
                        PS : Parsed_Selector;
                        Rule : Parsed_Rule := (others => <>);
                     begin
                        if Parse_Selector (Sel_Text, PS) then
                           Rule.Sel := PS;

                           declare
                              Decl_Pos : Positive := Props_Block'First;
                           begin
                              while Decl_Pos <= Props_Block'Last loop
                                 while Decl_Pos <= Props_Block'Last and then
                                   (Is_Whitespace (Props_Block (Decl_Pos)) or else Props_Block (Decl_Pos) = ';')
                                 loop
                                    Decl_Pos := Decl_Pos + 1;
                                 end loop;
                                 exit when Decl_Pos > Props_Block'Last;

                                 declare
                                    Decl_End : constant Natural := Fix.Index (Props_Block, ";", From => Decl_Pos);
                                    Decl : constant String :=
                                      (if Decl_End = 0
                                       then Trimmed (Props_Block (Decl_Pos .. Props_Block'Last))
                                       else Trimmed (Props_Block (Decl_Pos .. Decl_End - 1)));
                                    Sep : constant Natural := Fix.Index (Decl, ":");
                                 begin
                                    if Sep > 0 then
                                       Apply_Property (
                                          Rule.Style,
                                          Trimmed (Decl (Decl'First .. Sep - 1)),
                                          Trimmed (Decl (Sep + 1 .. Decl'Last)));
                                    end if;

                                    if Decl_End = 0 then
                                       Decl_Pos := Props_Block'Last + 1;
                                    else
                                       Decl_Pos := Decl_End + 1;
                                    end if;
                                 end;
                              end loop;
                           end;

                           Out_Rules.Append (Rule);
                        end if;

                        if Comma = 0 then
                           Sel_Pos := Selector_Block'Last + 1;
                        else
                           Sel_Pos := Comma + 1;
                        end if;
                     end;
                  end loop;
               end;

               Pos := Close_Brace + 1;
            end;
         end;
      end loop;

      return True;
   exception
      when E : others =>
         Out_Error := To_Unbounded_String ("Parse error: " & Ada.Exceptions.Exception_Message (E));
         return False;
   end Parse_Rules;

   function Find_Selector_Index (Impl : Stylesheet_Impl;
                                 Kind : Selector_Kind;
                                 Name : String) return Natural is
      Key : constant String := Lower (Trimmed (Name));
   begin
      for I in 1 .. Natural (Impl.Selectors.Length) loop
         if Impl.Selectors (I).Kind = Kind
           and then To_String (Impl.Selectors (I).Name) = Key
         then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Selector_Index;

   function Ensure_Selector (Impl : in out Stylesheet_Impl;
                             Kind : Selector_Kind;
                             Name : String) return Positive is
      Key : constant String := Lower (Trimmed (Name));
      Idx : constant Natural := Find_Selector_Index (Impl, Kind, Key);
   begin
      if Idx > 0 then
         return Positive (Idx);
      end if;

      Impl.Selectors.Append (New_Item => Selector_Style'
                               (Kind => Kind,
                                Name => To_Unbounded_String (Key),
                                Styles => Empty_Part_Styles));
      return Positive (Impl.Selectors.Last_Index);
   end Ensure_Selector;

   procedure Build_Styles (Impl : in out Stylesheet_Impl;
                           Rules : Parsed_Rule_Vectors.Vector;
                           Success : out Boolean) is
   begin
      Impl.Selectors.Clear;

      for R of Rules loop
         declare
            Idx : constant Positive := Ensure_Selector (Impl, R.Sel.Kind, To_String (R.Sel.Name));
            C   : Selector_Style := Impl.Selectors (Idx);
            W   : Widget_Style := C.Styles (R.Sel.Part).Style;
            Rule_Index : Natural := 0;
         begin
            if R.Sel.Has_State then
               for I in 1 .. W.Rule_Count loop
                  if W.Rules (I).Selector = R.Sel.Selector then
                     Rule_Index := I;
                     exit;
                  end if;
               end loop;

               if Rule_Index = 0 then
                  if W.Rule_Count >= Max_Style_Rules then
                     Impl.Last_Error := To_Unbounded_String
                       ("Too many state rules for selector '" & To_String (R.Sel.Name) & "'");
                     Success := False;
                     return;
                  end if;

                  Add_Rule (W, (Selector => R.Sel.Selector, Style => R.Style, Priority => 0));
               else
                  W.Rules (Rule_Index).Style := Merge (W.Rules (Rule_Index).Style, R.Style);
               end if;
            else
               W.Base := Merge (W.Base, R.Style);
            end if;

            C.Styles (R.Sel.Part) := (Style => W, Enabled => True);
            Impl.Selectors.Replace_Element (Idx, C);
         end;
      end loop;

      Success := True;
   end Build_Styles;

   procedure Reapply_Bindings (Impl : in out Stylesheet_Impl) is
      function Get_Styles (Kind : Selector_Kind;
                           Name : String) return Part_Style_Array is
         Idx : constant Natural := Find_Selector_Index (Impl, Kind, Name);
      begin
         if Idx = 0 then
            return Empty_Part_Styles;
         end if;
         return Impl.Selectors (Positive (Idx)).Styles;
      end Get_Styles;
   begin
      for B of Impl.Bindings loop
         if B.Target /= null then
            Set_Part_Styles (B.Target.all, Get_Styles (B.Kind, To_String (B.Name)));
         end if;
      end loop;
   end Reapply_Bindings;

   procedure Load_String (Sheet       : in out Stylesheet;
                          CSS_Content : String;
                          Success     : out Boolean) is
      Rules : Parsed_Rule_Vectors.Vector;
      Err : Unbounded_String;
   begin
      Ensure_Impl (Sheet);

      if not Parse_Rules (CSS_Content, Rules, Err) then
         Sheet.Impl.Last_Error := Err;
         Success := False;
         return;
      end if;

      Build_Styles (Sheet.Impl.all, Rules, Success);
      if Success then
         Sheet.Impl.Last_Error := Null_Unbounded_String;
         Reapply_Bindings (Sheet.Impl.all);
      end if;
   end Load_String;

   procedure Load_File (Sheet   : in out Stylesheet;
                        Path    : String;
                        Success : out Boolean) is
      File : Ada.Text_IO.File_Type;
      Buf  : Unbounded_String;
   begin
      Ensure_Impl (Sheet);

      if not Ada.Directories.Exists (Path) then
         Sheet.Impl.Last_Error := To_Unbounded_String ("CSS file not found: " & Path);
         Success := False;
         return;
      end if;

      Sheet.Impl.Source_Path := To_Unbounded_String (Path);

      Ada.Text_IO.Open (File => File,
                        Mode => Ada.Text_IO.In_File,
                        Name => Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Buf, Ada.Text_IO.Get_Line (File));
         Append (Buf, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);

      Load_String (Sheet, To_String (Buf), Success);
      if Success then
         Sheet.Impl.Last_Modified := Ada.Directories.Modification_Time (Path);
      end if;
   exception
      when E : others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Sheet.Impl.Last_Error := To_Unbounded_String
           ("Failed to load CSS file: " & Ada.Exceptions.Exception_Message (E));
         Success := False;
   end Load_File;

   procedure Reload_If_Changed (Sheet    : in out Stylesheet;
                                Reloaded : out Boolean;
                                Success  : out Boolean) is
      Path : constant String := To_String (Sheet.Impl.Source_Path);
      Mod_Time : Ada.Calendar.Time;
   begin
      Ensure_Impl (Sheet);
      Reloaded := False;
      Success := True;

      if Path = "" then
         return;
      end if;

      if not Ada.Directories.Exists (Path) then
         Sheet.Impl.Last_Error := To_Unbounded_String ("CSS file not found: " & Path);
         Success := False;
         return;
      end if;

      Mod_Time := Ada.Directories.Modification_Time (Path);
      if Mod_Time > Sheet.Impl.Last_Modified then
         Load_File (Sheet, Path, Success);
         Reloaded := Success;
      end if;
   end Reload_If_Changed;

   function Has (Sheet : Stylesheet;
                 Kind : Selector_Kind;
                 Name : String) return Boolean is
   begin
      if Sheet.Impl = null then
         return False;
      end if;
      return Find_Selector_Index (Sheet.Impl.all, Kind, Name) > 0;
   end Has;

   function Has_Class (Sheet : Stylesheet; Class_Name : String) return Boolean is
   begin
      return Has (Sheet, Class_Selector, Class_Name);
   end Has_Class;

   function Has_Id (Sheet : Stylesheet; Id_Name : String) return Boolean is
   begin
      return Has (Sheet, Id_Selector, Id_Name);
   end Has_Id;

   function Has_Tag (Sheet : Stylesheet; Tag_Name : String) return Boolean is
   begin
      return Has (Sheet, Tag_Selector, Tag_Name);
   end Has_Tag;

   function Styles_For (Sheet : Stylesheet;
                        Kind  : Selector_Kind;
                        Name  : String) return Part_Style_Array is
      Idx : Natural := 0;
   begin
      if Sheet.Impl = null then
         return Empty_Part_Styles;
      end if;

      Idx := Find_Selector_Index (Sheet.Impl.all, Kind, Name);
      if Idx = 0 then
         return Empty_Part_Styles;
      end if;

      return Sheet.Impl.Selectors (Positive (Idx)).Styles;
   end Styles_For;

   function Styles_For_Class (Sheet : Stylesheet;
                              Class_Name : String) return Part_Style_Array is
   begin
      return Styles_For (Sheet, Class_Selector, Class_Name);
   end Styles_For_Class;

   function Styles_For_Id (Sheet : Stylesheet;
                           Id_Name : String) return Part_Style_Array is
   begin
      return Styles_For (Sheet, Id_Selector, Id_Name);
   end Styles_For_Id;

   function Styles_For_Tag (Sheet : Stylesheet;
                            Tag_Name : String) return Part_Style_Array is
   begin
      return Styles_For (Sheet, Tag_Selector, Tag_Name);
   end Styles_For_Tag;

   function Styles_For (Sheet : Stylesheet;
                        Class_Name : String) return Part_Style_Array is
   begin
      return Styles_For_Class (Sheet, Class_Name);
   end Styles_For;

   procedure Apply (Sheet : Stylesheet;
                    Kind  : Selector_Kind;
                    Name  : String;
                    W     : in out Adi.Widget.Widget'Class) is
   begin
      Set_Part_Styles (W, Styles_For (Sheet, Kind, Name));
   end Apply;

   procedure Apply_Class (Sheet      : Stylesheet;
                          Class_Name : String;
                          W          : in out Adi.Widget.Widget'Class) is
   begin
      Apply (Sheet, Class_Selector, Class_Name, W);
   end Apply_Class;

   procedure Apply_Id (Sheet   : Stylesheet;
                       Id_Name : String;
                       W       : in out Adi.Widget.Widget'Class) is
   begin
      Apply (Sheet, Id_Selector, Id_Name, W);
   end Apply_Id;

   procedure Apply_Tag (Sheet   : Stylesheet;
                        Tag_Name : String;
                        W        : in out Adi.Widget.Widget'Class) is
   begin
      Apply (Sheet, Tag_Selector, Tag_Name, W);
   end Apply_Tag;

   procedure Bind (Sheet : in out Stylesheet;
                   Kind  : Selector_Kind;
                   Name  : String;
                   W     : access Adi.Widget.Widget'Class) is
      Key : constant String := Lower (Trimmed (Name));
   begin
      Ensure_Impl (Sheet);
      if W = null then
         return;
      end if;

      for I in 1 .. Natural (Sheet.Impl.Bindings.Length) loop
         if Sheet.Impl.Bindings (I).Target = W.all'Unchecked_Access then
            Sheet.Impl.Bindings.Replace_Element
              (I, (Kind   => Kind,
                   Name   => To_Unbounded_String (Key),
                   Target => W.all'Unchecked_Access));
            Apply (Sheet, Kind, Key, W.all);
            return;
         end if;
      end loop;

      Sheet.Impl.Bindings.Append
        (New_Item => Binding'
           (Kind   => Kind,
            Name   => To_Unbounded_String (Key),
            Target => W.all'Unchecked_Access));
      Apply (Sheet, Kind, Key, W.all);
   end Bind;

   procedure Bind_Class (Sheet      : in out Stylesheet;
                         Class_Name : String;
                         W          : access Adi.Widget.Widget'Class) is
   begin
      Bind (Sheet, Class_Selector, Class_Name, W);
   end Bind_Class;

   procedure Bind_Id (Sheet   : in out Stylesheet;
                      Id_Name : String;
                      W       : access Adi.Widget.Widget'Class) is
   begin
      Bind (Sheet, Id_Selector, Id_Name, W);
   end Bind_Id;

   procedure Bind_Tag (Sheet   : in out Stylesheet;
                       Tag_Name : String;
                       W        : access Adi.Widget.Widget'Class) is
   begin
      Bind (Sheet, Tag_Selector, Tag_Name, W);
   end Bind_Tag;

   function Get_Last_Error (Sheet : Stylesheet) return String is
   begin
      if Sheet.Impl = null then
         return "";
      end if;
      return To_String (Sheet.Impl.Last_Error);
   end Get_Last_Error;

   function Get_Source_Path (Sheet : Stylesheet) return String is
   begin
      if Sheet.Impl = null then
         return "";
      end if;
      return To_String (Sheet.Impl.Source_Path);
   end Get_Source_Path;

end Adi.CSS_Parser;
