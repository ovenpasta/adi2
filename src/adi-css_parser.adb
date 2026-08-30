--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Hashed_Maps;

with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Numerics;
with Ada.Containers;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Log;
with Adi.Style_Merge;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Window_Bridge;
pragma Elaborate_All (Adi.Widget.Window_Bridge);
with Adi.Widget_Styles; use Adi.Widget_Styles;

package body Adi.CSS_Parser is

   package Fix renames Ada.Strings.Fixed;
   package Char renames Ada.Characters.Handling;

   use type Ada.Calendar.Time;
   use type Ada.Containers.Count_Type;

   type Selector_Style is record
      Kind   : Selector_Kind := Class_Selector;
      Name   : Unbounded_String;
      Styles : Adi.Widget.Interned_Part_Styles :=
        Adi.Widget.Empty_Interned_Part_Styles;
   end record;

   Empty_Selector_Style : constant Selector_Style :=
     (Kind   => Class_Selector,
      Name   => Null_Unbounded_String,
      Styles => Adi.Widget.Empty_Interned_Part_Styles);

   --  The styles a build has under construction, one entry per selector
   --  and in step with Stylesheet_Impl.Selectors.
   package Part_Style_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Part_Style_Array);

   function Selector_Entry_Bytes return Natural is
     (Selector_Style'Max_Size_In_Storage_Elements);

   package Selector_Style_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Selector_Style);

   type Binding is record
      Kind       : Selector_Kind := Class_Selector;
      Name       : Unbounded_String;
      Target     : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
   end record;

   package Binding_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Adi.Widget.Widget_Handle,
      Element_Type    => Binding,
      Hash            => Adi.Widget.Hash,
      Equivalent_Keys => Adi.Widget."=");

   package Binding_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Binding);

   type Variable_Entry is record
      Name  : Unbounded_String;
      Value : Unbounded_String;
   end record;

   package Variable_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Variable_Entry);

   type Stylesheet_Impl is new Sheet_Impl_Base with record
      Selectors     : Selector_Style_Vectors.Vector;
      Bindings      : Binding_Vectors.Vector;
      Root_Target   : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
      --  The binding in force for each target, so handing the root role
      --  over restyles the widget losing it and the one taking it
      --  without searching.
      Effective        : Binding_Maps.Map;
      Metadata      : Stylesheet_Metadata := (others => <>);
      Variables     : Variable_Vectors.Vector;
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

   type Stylesheet_Impl_Ptr is access all Stylesheet_Impl;

   --  What the sheet's handle names, or null once it is destroyed --
   --  which is what a copy of a destroyed sheet gets, in place of a
   --  pointer into freed memory.
   function Impl_Of (Sheet : Stylesheet) return Stylesheet_Impl_Ptr is
      P : constant Sheet_Impl_Access := Sheet_Stores.Get (Sheet.Id);
   begin
      if P = null then
         return null;
      end if;
      return Stylesheet_Impl (P.all)'Unchecked_Access;
   end Impl_Of;

   procedure Prune_Widget (Impl : Stylesheet_Impl_Ptr;
                           H    : Adi.Widget.Widget_Handle) is
   begin
      Impl.Effective.Exclude (H);

      for I in 1 .. Natural (Impl.Bindings.Length) loop
         if Impl.Bindings (I).Target = H then
            --  Order across targets carries nothing: Reapply_Bindings
            --  styles each widget from its own binding.
            Impl.Bindings.Replace_Element (I, Impl.Bindings.Last_Element);
            Impl.Bindings.Delete_Last;
            exit;
         end if;
      end loop;

      if Impl.Root_Target = H then
         Impl.Root_Target := Adi.Widget.Null_Handle;
      end if;
   end Prune_Widget;

   procedure On_Widget_Destroyed (H : Adi.Widget.Widget_Handle) is
      procedure Prune_One (Id  : Sheet_Stores.Object_Id;
                           Obj : not null Sheet_Impl_Access) is
         pragma Unreferenced (Id);
      begin
         Prune_Widget (Stylesheet_Impl (Obj.all)'Unchecked_Access, H);
      end Prune_One;

      procedure Prune_All is new Sheet_Stores.For_Each_Alive (Prune_One);
   begin
      Prune_All;
   end On_Widget_Destroyed;

   function Binding_Count (Sheet : Stylesheet) return Natural is
     (if Impl_Of (Sheet) = null then 0
      else Natural (Impl_Of (Sheet).Bindings.Length));

   function Effective_Count (Sheet : Stylesheet) return Natural is
     (if Impl_Of (Sheet) = null then 0
      else Natural (Impl_Of (Sheet).Effective.Length));

   function Live_Impl_Count return Natural is
      N : Natural := 0;

      procedure Count_One (Id  : Sheet_Stores.Object_Id;
                           Obj : not null Sheet_Impl_Access) is
         pragma Unreferenced (Id, Obj);
      begin
         N := N + 1;
      end Count_One;

      procedure Count_All is new Sheet_Stores.For_Each_Alive (Count_One);
   begin
      Count_All;
      return N;
   end Live_Impl_Count;

   function Is_Valid (Sheet : Stylesheet) return Boolean is
     (Sheet_Stores.Is_Valid (Sheet.Id));

   procedure Destroy (Sheet : in out Stylesheet) is
   begin
      --  Nothing is pinned, so the store frees here rather than at a
      --  later Pump; a second call finds the handle stale and does
      --  nothing, as does a call on a copy.
      Sheet_Stores.Request_Destroy (Sheet.Id);
      Sheet.Id := Sheet_Stores.Null_Id;
   end Destroy;

   procedure Ensure_Impl (Sheet : in out Stylesheet) is
   begin
      if Impl_Of (Sheet) = null then
         Sheet.Id := Sheet_Stores.Register (new Stylesheet_Impl);
      end if;
   end Ensure_Impl;

   procedure Apply_Metadata_To_Widget
     (Metadata : Stylesheet_Metadata;
      W        : in out Adi.Widget.Widget'Class) is
   begin
      if Metadata.Has_Root_Style then
         Set_Part_Styles (W, Metadata.Root_Styles);
      end if;
   end Apply_Metadata_To_Widget;

   function Root_Merged_Styles
     (Impl   : Stylesheet_Impl;
      Target : Adi.Widget.Widget_Handle;
      Styles : Part_Style_Array) return Part_Style_Array
   is
   begin
      if Adi.Widget.Is_Valid (Target)
        and then Impl.Root_Target = Target
        and then Impl.Metadata.Has_Root_Style
      then
         return Adi.Style_Merge.Merge
           (Adi.Widget.Expand (Impl.Metadata.Root_Styles), Styles);
      end if;

      return Styles;
   end Root_Merged_Styles;

   function Lower (S : String) return String is (Char.To_Lower (S));

   function Trimmed (S : String) return String is
      First : Positive := S'First;
      Last  : Natural  := S'Last;
   begin
      while First <= Last
        and then (S (First) = ' '  or else S (First) = ASCII.HT
                  or else S (First) = ASCII.LF or else S (First) = ASCII.CR)
      loop
         First := First + 1;
      end loop;
      while Last >= First
        and then (S (Last) = ' '  or else S (Last) = ASCII.HT
                  or else S (Last) = ASCII.LF or else S (Last) = ASCII.CR)
      loop
         Last := Last - 1;
      end loop;
      return (if First > Last then "" else S (First .. Last));
   end Trimmed;

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
         elsif T'Length > 3 and then T (T'Last - 2 .. T'Last) = "pix" then
            if Parse_Number (T (T'First .. T'Last - 3), Num) and then Num >= 0.0 then
               Spec := (Track_Pix, Num);
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
      elsif Ends_With (V, "pix") then
         Number := To_Unbounded_String (V (V'First .. V'Last - 3));
         L.Unit := Pix;
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

   --  A declaration naming more text than a style value carries is
   --  dropped, and reported.
   function Fits_In_Style (Text : String) return Boolean is
   begin
      if Text'Length <= Max_CSS_Text_Length then
         return True;
      end if;

      Adi.Log.Warning
        ("css: a text value of" & Natural'Image (Text'Length)
         & " characters exceeds the" & Natural'Image (Max_CSS_Text_Length)
         & " a style carries; the declaration is dropped");
      return False;
   end Fits_In_Style;

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

      return Length (Out_URI) > 0
        and then Fits_In_Style (To_String (Out_URI));
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
         if not Fits_In_Style (To_String (S)) then
            return False;
         end if;
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

   --  Split on commas at paren-depth 0 (so rgb(r,g,b) is not split).
   procedure Split_Comma_Tokens
     (Input      : String;
      Out_Tokens : in out Token_Vectors.Vector)
   is
      I           : Integer := Input'First;
      Token_Start : Integer := Input'First;
      Paren_Depth : Natural := 0;
   begin
      Out_Tokens.Clear;

      while I <= Input'Last loop
         if Input (I) = '(' then
            Paren_Depth := Paren_Depth + 1;
         elsif Input (I) = ')' then
            if Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            end if;
         elsif Input (I) = ',' and then Paren_Depth = 0 then
            declare
               Tok : constant String := Trimmed (Input (Token_Start .. I - 1));
            begin
               if Tok'Length > 0 then
                  Out_Tokens.Append (To_Unbounded_String (Tok));
               end if;
            end;
            Token_Start := I + 1;
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
   end Split_Comma_Tokens;

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

   function To_Length (L : Parsed_Length) return Length_Value;

   function Parse_Object_Position_Value
     (Input    : String;
      Out_Pos  : out Object_Position_Value) return Boolean
   is
      Tokens : Token_Vectors.Vector;
      H      : Object_Position_Keyword := Pos_Center;
      V      : Object_Position_Keyword := Pos_Center;
      Has_H  : Boolean := False;
      Has_V  : Boolean := False;
      LX, LY : Parsed_Length;
   begin
      Out_Pos := Default_Object_Position;
      Split_Whitespace_Tokens (Input, Tokens);

      if Tokens.Length = 0 then
         return False;
      end if;

      if Tokens.Length = 1 then
         declare
            Tok1 : constant String := Lower (Trimmed (To_String (Tokens (1))));
         begin
            if Tok1 = "left" then
               Out_Pos := Object_Position (Pos_Left, Pos_Center);
               return True;
            elsif Tok1 = "right" then
               Out_Pos := Object_Position (Pos_Right, Pos_Center);
               return True;
            elsif Tok1 = "top" then
               Out_Pos := Object_Position (Pos_Center, Pos_Top);
               return True;
            elsif Tok1 = "bottom" then
               Out_Pos := Object_Position (Pos_Center, Pos_Bottom);
               return True;
            elsif Tok1 = "center" then
               Out_Pos := Object_Position (Pos_Center, Pos_Center);
               return True;
            elsif Parse_Length (Tok1, LX) then
               Out_Pos := Object_Position (To_Length (LX), Pct (50.0));
               return True;
            end if;
         end;
         return False;
      end if;

      if Tokens.Length /= 2 then
         return False;
      end if;

      declare
         Tok1 : constant String := Lower (Trimmed (To_String (Tokens (1))));
         Tok2 : constant String := Lower (Trimmed (To_String (Tokens (2))));
      begin
         if Parse_Length (Tok1, LX) and then Parse_Length (Tok2, LY) then
            Out_Pos := Object_Position (To_Length (LX), To_Length (LY));
            return True;
         end if;
      end;

      for Tok of Tokens loop
         declare
            T : constant String := Lower (Trimmed (To_String (Tok)));
         begin
            if T = "left" then
               if Has_H then
                  return False;
               end if;
               H := Pos_Left;
               Has_H := True;
            elsif T = "right" then
               if Has_H then
                  return False;
               end if;
               H := Pos_Right;
               Has_H := True;
            elsif T = "top" then
               if Has_V then
                  return False;
               end if;
               V := Pos_Top;
               Has_V := True;
            elsif T = "bottom" then
               if Has_V then
                  return False;
               end if;
               V := Pos_Bottom;
               Has_V := True;
            elsif T = "center" then
               if not Has_H then
                  H := Pos_Center;
                  Has_H := True;
               elsif not Has_V then
                  V := Pos_Center;
                  Has_V := True;
               else
                  return False;
               end if;
            else
               return False;
            end if;
         end;
      end loop;

      Out_Pos := Object_Position (H, V);
      return True;
   end Parse_Object_Position_Value;

   function To_Length (L : Parsed_Length) return Length_Value is
   begin
      case L.Unit is
         when Px      => return Px (L.Amount);
         when Pix     => return Pix (L.Amount);
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

   --  Parse a CSS linear-gradient() function value.
   --  Returns True and sets Out_Val on success; returns False on any error.
   function Parse_Linear_Gradient
     (Input   : String;
      Out_Val : out Background_Image_Value) return Boolean
   is
      V      : constant String := Trimmed (Input);
      LV     : constant String := Lower (V);
      Prefix : constant String := "linear-gradient(";
      Tokens : Token_Vectors.Vector;
      Angle  : Float := 180.0;
      Start  : Positive;
      Stop_Count : Natural := 0;
      Stops  : Gradient_Stop_Array;
      Color_Val : Color_Value;
      F      : Float;
   begin
      Out_Val := (Kind => No_Image);

      --  Verify prefix and suffix
      if LV'Length <= Prefix'Length + 1 then
         return False;
      end if;
      if LV (LV'First .. LV'First + Prefix'Length - 1) /= Prefix then
         return False;
      end if;
      if V (V'Last) /= ')' then
         return False;
      end if;

      --  Extract inner content and split on commas
      Split_Comma_Tokens (V (V'First + Prefix'Length .. V'Last - 1), Tokens);

      if Natural (Tokens.Length) < 2 then
         return False;
      end if;

      --  Try to parse first token as direction or angle
      Start := 1;
      declare
         First_Tok : constant String := To_String (Tokens (1));
         FTL       : constant String := Lower (First_Tok);
      begin
         if FTL = "to top" then
            Angle := 0.0;   Start := 2;
         elsif FTL = "to right" then
            Angle := 90.0;  Start := 2;
         elsif FTL = "to bottom" then
            Angle := 180.0; Start := 2;
         elsif FTL = "to left" then
            Angle := 270.0; Start := 2;
         elsif FTL = "to top right" or else FTL = "to right top" then
            Angle := 45.0;  Start := 2;
         elsif FTL = "to bottom right" or else FTL = "to right bottom" then
            Angle := 135.0; Start := 2;
         elsif FTL = "to bottom left" or else FTL = "to left bottom" then
            Angle := 225.0; Start := 2;
         elsif FTL = "to top left" or else FTL = "to left top" then
            Angle := 315.0; Start := 2;
         elsif FTL'Length >= 4
           and then FTL (FTL'Last - 2 .. FTL'Last) = "deg"
         then
            if Parse_Number
              (First_Tok (First_Tok'First .. First_Tok'Last - 3), F)
            then
               Angle := F;
               Start := 2;
            end if;
         elsif FTL'Length >= 5
           and then FTL (FTL'Last - 3 .. FTL'Last) = "grad"
         then
            if Parse_Number
              (First_Tok (First_Tok'First .. First_Tok'Last - 4), F)
            then
               Angle := F * 360.0 / 400.0;
               Start := 2;
            end if;
         elsif FTL'Length >= 4
           and then FTL (FTL'Last - 2 .. FTL'Last) = "rad"
         then
            if Parse_Number
              (First_Tok (First_Tok'First .. First_Tok'Last - 3), F)
            then
               Angle := F * 180.0 / Ada.Numerics.Pi;
               Start := 2;
            end if;
         elsif FTL'Length >= 5
           and then FTL (FTL'Last - 3 .. FTL'Last) = "turn"
         then
            if Parse_Number
              (First_Tok (First_Tok'First .. First_Tok'Last - 4), F)
            then
               Angle := F * 360.0;
               Start := 2;
            end if;
         end if;
         --  Otherwise Start stays 1 (first token treated as a color stop)
      end;

      --  Need at least 2 stop tokens
      if Natural (Tokens.Length) - (Start - 1) < 2 then
         return False;
      end if;

      --  Parse stop tokens
      for I in Start .. Natural (Tokens.Last_Index) loop
         exit when Stop_Count >= Max_Gradient_Stops;
         declare
            Tok        : constant String := To_String (Tokens (I));
            Last_Space : Integer         := 0;
         begin
            --  Find last space to detect optional position suffix
            for J in reverse Tok'Range loop
               if Tok (J) = ' ' then
                  Last_Space := J;
                  exit;
               end if;
            end loop;

            Stop_Count := Stop_Count + 1;
            if Last_Space > 0 then
               declare
                  Color_Part : constant String :=
                     Tok (Tok'First .. Last_Space - 1);
                  Pos_Part   : constant String :=
                     Tok (Last_Space + 1 .. Tok'Last);
               begin
                  if Pos_Part'Length >= 2
                    and then Pos_Part (Pos_Part'Last) = '%'
                    and then Parse_Number
                      (Pos_Part (Pos_Part'First .. Pos_Part'Last - 1), F)
                    and then Parse_Color (Color_Part, Color_Val)
                  then
                     Stops (Stop_Count) :=
                        Gradient_Stop_At (Color_Val, F / 100.0);
                  elsif Parse_Color (Tok, Color_Val) then
                     Stops (Stop_Count) := Gradient_Stop_Auto (Color_Val);
                  else
                     return False;
                  end if;
               end;
            elsif Parse_Color (Tok, Color_Val) then
               Stops (Stop_Count) := Gradient_Stop_Auto (Color_Val);
            else
               return False;
            end if;
         end;
      end loop;

      if Stop_Count < 2 then
         return False;
      end if;

      Out_Val := Linear_Gradient (Angle, Stops, Stop_Count);
      return True;
   end Parse_Linear_Gradient;

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

   --  Parse a margin shorthand value: 1-4 tokens, each a length or "auto".
   --  Out_Sides is set to the four sides [Top, Right, Bottom, Left].
   --  Returns False only if the value is entirely unparseable (e.g. empty or
   --  a token that is neither a length nor "auto").
   function Parse_Margin_Shorthand
     (Input    :     String;
      Out_Sides : out Opt_Margin_Sides) return Boolean
   is
      type Margin_Token_Kind is (Length_Token, Auto_Token);
      type Margin_Token is record
         Kind   : Margin_Token_Kind := Length_Token;
         Length : Parsed_Length;
      end record;

      Tokens : array (1 .. 4) of Margin_Token;
      Count  : Natural := 0;
      I      : Positive := Input'First;

      function Next_Token (T : out Margin_Token) return Boolean is
         J : Natural;
         V : Unbounded_String;
         L : Parsed_Length;
      begin
         while I <= Input'Last and then Is_Whitespace (Input (I)) loop
            I := I + 1;
         end loop;
         if I > Input'Last then
            return False;
         end if;
         J := I;
         while J <= Input'Last and then not Is_Whitespace (Input (J)) loop
            J := J + 1;
         end loop;
         V := To_Unbounded_String (Lower (Input (I .. J - 1)));
         I := J + 1;
         if V = "auto" then
            T := (Kind => Auto_Token, Length => <>);
            return True;
         elsif Parse_Length (To_String (V), L) then
            T := (Kind => Length_Token, Length => L);
            return True;
         end if;
         return False;
      end Next_Token;

      function To_MV (T : Margin_Token) return Margin_Value is
        (if T.Kind = Auto_Token then Auto_Margin else Margin (To_Length (T.Length)));

      Tok : Margin_Token;
   begin
      while Count < 4 loop
         if not Next_Token (Tok) then
            exit;
         end if;
         Count := Count + 1;
         Tokens (Count) := Tok;
      end loop;

      if Count = 0 then
         return False;
      end if;

      --  Expand shorthand the same way CSS does.
      case Count is
         when 1 =>
            Out_Sides := [others => Opt_Margin.Val (To_MV (Tokens (1)))];
         when 2 =>
            Out_Sides := [Top | Bottom => Opt_Margin.Val (To_MV (Tokens (1))),
                          Left | Right => Opt_Margin.Val (To_MV (Tokens (2)))];
         when 3 =>
            Out_Sides := [Top    => Opt_Margin.Val (To_MV (Tokens (1))),
                          Right  => Opt_Margin.Val (To_MV (Tokens (2))),
                          Bottom => Opt_Margin.Val (To_MV (Tokens (3))),
                          Left   => Opt_Margin.Val (To_MV (Tokens (2)))];
         when others =>
            Out_Sides := [Top    => Opt_Margin.Val (To_MV (Tokens (1))),
                          Right  => Opt_Margin.Val (To_MV (Tokens (2))),
                          Bottom => Opt_Margin.Val (To_MV (Tokens (3))),
                          Left   => Opt_Margin.Val (To_MV (Tokens (4)))];
      end case;

      return True;
   end Parse_Margin_Shorthand;

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

   function Parse_Border_Style_Value
     (Input : String; Out_Style : out Border_Style_Kind) return Boolean
   is
      V : constant String := Lower (Trimmed (Input));
   begin
      if V = "none" then
         Out_Style := None_Style;
      elsif V = "hidden" then
         Out_Style := Hidden;
      elsif V = "dotted" then
         Out_Style := Dotted;
      elsif V = "dashed" then
         Out_Style := Dashed;
      elsif V = "solid" then
         Out_Style := Solid;
      elsif V = "double" then
         Out_Style := Double;
      elsif V = "groove" then
         Out_Style := Groove;
      elsif V = "ridge" then
         Out_Style := Ridge;
      elsif V = "inset" then
         Out_Style := Inset;
      elsif V = "outset" then
         Out_Style := Outset;
      else
         return False;
      end if;

      return True;
   end Parse_Border_Style_Value;

   procedure Parse_Border_Shorthand_Components
     (Input      : String;
      Has_Width  : out Boolean;
      Out_Width  : out Parsed_Length;
      Has_Style  : out Boolean;
      Out_Style  : out Border_Style_Kind;
      Has_Color  : out Boolean;
      Out_Color  : out Color_Value)
   is
      Tokens : Token_Vectors.Vector;
      L      : Parsed_Length;
      S      : Border_Style_Kind;
      Col    : Color_Value;
   begin
      Has_Width := False;
      Has_Style := False;
      Has_Color := False;
      Out_Width := (others => <>);
      Out_Style := None_Style;
      Out_Color := C (Current_Color);

      Split_Whitespace_Tokens (Input, Tokens);
      for T of Tokens loop
         declare
            Tok : constant String := To_String (T);
         begin
            if Parse_Length (Tok, L) then
               Has_Width := True;
               Out_Width := L;
            elsif Parse_Border_Style_Value (Tok, S) then
               Has_Style := True;
               Out_Style := S;
            elsif Parse_Color (Tok, Col) then
               Has_Color := True;
               Out_Color := Col;
            end if;
         end;
      end loop;
   end Parse_Border_Shorthand_Components;

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

   --  A comma-separated transition list gives every entry its own timing,
   --  which Transition_Spec cannot hold: it carries one duration and one
   --  easing for the whole set. The first entry supplies those and the
   --  properties are unioned, so listing several still animates all of them.
   function Parse_Transition (Input : String; Out_Transition : out Transition_Spec) return Boolean is
      V : constant String := Lower (Trimmed (Input));

      Duration : Float := 0.0;
      Duration_Set : Boolean := False;
      Easing : Easing_Kind := Ease_In_Out;
      Properties : Property_Set := No_Properties;

      Is_First : Boolean := True;

      --  Read one entry, folding its property into the running union and,
      --  for the first entry only, taking the timing.
      procedure Take_Entry (Text : String) is
         Pos        : Positive := Text'First;
         Named      : Boolean := False;
         Entry_Props : Property_Set := All_Properties;
         Tmp_Duration : Float;
         Tmp_Easing   : Easing_Kind;
         Tmp_Props    : Property_Set;
      begin
         while Pos <= Text'Last loop
            while Pos <= Text'Last and then Is_Whitespace (Text (Pos)) loop
               Pos := Pos + 1;
            end loop;
            exit when Pos > Text'Last;

            declare
               Token_End : Natural := Pos;
            begin
               while Token_End <= Text'Last
                 and then not Is_Whitespace (Text (Token_End))
               loop
                  Token_End := Token_End + 1;
               end loop;

               declare
                  Token : constant String := Text (Pos .. Token_End - 1);
               begin
                  if Parse_Transition_Duration (Token, Tmp_Duration) then
                     if Is_First then
                        Duration := Tmp_Duration;
                        Duration_Set := True;
                     end if;
                  elsif Parse_Transition_Easing (Token, Tmp_Easing) then
                     if Is_First then
                        Easing := Tmp_Easing;
                     end if;
                  elsif Parse_Transition_Property (Token, Tmp_Props) then
                     Entry_Props := Tmp_Props;
                     Named := True;
                  end if;
               end;

               Pos := Token_End + 1;
            end;
         end loop;

         --  An entry naming no property means every property, as in CSS.
         if Named or else Text'Length > 0 then
            Properties := Properties + Entry_Props;
         end if;
         Is_First := False;
      end Take_Entry;

   begin
      if V = "none" then
         Out_Transition := No_Transition;
         return True;
      end if;

      if V'Length = 0 then
         return False;
      end if;

      --  Split at paren depth 0, or a timing function's own commas would
      --  each look like another entry. The splitter drops empty entries, so
      --  count the separators too: a leading, trailing or doubled comma
      --  would otherwise pass unnoticed.
      declare
         Entries : Token_Vectors.Vector;
         Depth   : Natural := 0;
         Commas  : Natural := 0;
      begin
         for C of V loop
            if C = '(' then
               Depth := Depth + 1;
            elsif C = ')' then
               Depth := Natural'Max (0, Depth - 1);
            elsif C = ',' and then Depth = 0 then
               Commas := Commas + 1;
            end if;
         end loop;

         Split_Comma_Tokens (V, Entries);
         if Natural (Entries.Length) /= Commas + 1 then
            return False;
         end if;

         for E of Entries loop
            Take_Entry (Trimmed (To_String (E)));
         end loop;
      end;

      --  Only the first entry's duration counts, so a list whose first
      --  entry has no duration is as invalid as a bare one.
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
      elsif V = "text" then P := Text_Part;
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

   function Parse_Overflow_Value
     (Input     : String;
      Out_Value : out Overflow_Value) return Boolean
   is
      V : constant String := Lower (Trimmed (Input));
   begin
      if V = "visible" then
         Out_Value := Overflow_Visible;
      elsif V = "hidden" then
         Out_Value := Overflow_Hidden;
      elsif V = "scroll" then
         Out_Value := Overflow_Scroll;
      elsif V = "auto" then
         Out_Value := Overflow_Auto;
      else
         return False;
      end if;

      return True;
   end Parse_Overflow_Value;

   procedure Set_Overflow_Shorthand
     (Rules : in out Style_Rules;
      Value : Overflow_Value)
   is
   begin
      Rules.Overflow_X := Set_Overflow_X (Value);
      Rules.Overflow_Y := Set_Overflow_Y (Value);
   end Set_Overflow_Shorthand;

   --  Declaration names Apply_Property recognises. The chain below
   --  tests one of these rather than the name text.
   type Decl_Name is
     (Decl_Unknown,
      D_Align_Content,
      D_Align_Items,
      D_Align_Self,
      D_Background,
      D_Background_Color,
      D_Background_Image,
      D_Border,
      D_Border_Bottom,
      D_Border_Bottom_Color,
      D_Border_Bottom_Left_Radius,
      D_Border_Bottom_Right_Radius,
      D_Border_Bottom_Style,
      D_Border_Bottom_Width,
      D_Border_Color,
      D_Border_Left,
      D_Border_Left_Color,
      D_Border_Left_Style,
      D_Border_Left_Width,
      D_Border_Radius,
      D_Border_Right,
      D_Border_Right_Color,
      D_Border_Right_Style,
      D_Border_Right_Width,
      D_Border_Style,
      D_Border_Top,
      D_Border_Top_Color,
      D_Border_Top_Left_Radius,
      D_Border_Top_Right_Radius,
      D_Border_Top_Style,
      D_Border_Top_Width,
      D_Border_Width,
      D_Bottom,
      D_Box_Shadow,
      D_Color,
      D_Column_Gap,
      D_Cursor,
      D_Display,
      D_Flex_Basis,
      D_Flex_Direction,
      D_Flex_Grow,
      D_Flex_Shrink,
      D_Flex_Wrap,
      D_Font_Family,
      D_Font_Size,
      D_Font_Style,
      D_Font_Weight,
      D_Gap,
      D_Grid_Column,
      D_Grid_Row,
      D_Grid_Template_Columns,
      D_Grid_Template_Rows,
      D_Height,
      D_Justify_Content,
      D_Left,
      D_Line_Height,
      D_List_Style,
      D_List_Style_Image,
      D_List_Style_Position,
      D_List_Style_Type,
      D_Margin,
      D_Margin_Bottom,
      D_Margin_Left,
      D_Margin_Right,
      D_Margin_Top,
      D_Max_Height,
      D_Max_Width,
      D_Min_Height,
      D_Min_Width,
      D_Object_Fit,
      D_Object_Position,
      D_Opacity,
      D_Order,
      D_Outline,
      D_Outline_Color,
      D_Outline_Offset,
      D_Outline_Style,
      D_Outline_Width,
      D_Overflow,
      D_Overflow_X,
      D_Overflow_Y,
      D_Padding,
      D_Padding_Bottom,
      D_Padding_Left,
      D_Padding_Right,
      D_Padding_Top,
      D_Position,
      D_Right,
      D_Row_Gap,
      D_Text_Align,
      D_Text_Decoration,
      D_Text_Overflow,
      D_Text_Wrap_Mode,
      D_Top,
      D_Transition,
      D_Vertical_Align,
      D_Visibility,
      D_White_Space,
      D_Width);

   Max_Decl_Name : constant := 26;
   subtype Decl_Key is String (1 .. Max_Decl_Name);

   type Decl_Row is record
      Name : Decl_Key;
      Id   : Decl_Name;
   end record;

   --  Ordered by Name, which a space pad leaves as the order on the
   --  names themselves: no name character sorts below a space.
   Decl_Table : constant array (Positive range <>) of Decl_Row :=
     [
      ("align-content             ", D_Align_Content),
      ("align-items               ", D_Align_Items),
      ("align-self                ", D_Align_Self),
      ("background                ", D_Background),
      ("background-color          ", D_Background_Color),
      ("background-image          ", D_Background_Image),
      ("border                    ", D_Border),
      ("border-bottom             ", D_Border_Bottom),
      ("border-bottom-color       ", D_Border_Bottom_Color),
      ("border-bottom-left-radius ", D_Border_Bottom_Left_Radius),
      ("border-bottom-right-radius", D_Border_Bottom_Right_Radius),
      ("border-bottom-style       ", D_Border_Bottom_Style),
      ("border-bottom-width       ", D_Border_Bottom_Width),
      ("border-color              ", D_Border_Color),
      ("border-left               ", D_Border_Left),
      ("border-left-color         ", D_Border_Left_Color),
      ("border-left-style         ", D_Border_Left_Style),
      ("border-left-width         ", D_Border_Left_Width),
      ("border-radius             ", D_Border_Radius),
      ("border-right              ", D_Border_Right),
      ("border-right-color        ", D_Border_Right_Color),
      ("border-right-style        ", D_Border_Right_Style),
      ("border-right-width        ", D_Border_Right_Width),
      ("border-style              ", D_Border_Style),
      ("border-top                ", D_Border_Top),
      ("border-top-color          ", D_Border_Top_Color),
      ("border-top-left-radius    ", D_Border_Top_Left_Radius),
      ("border-top-right-radius   ", D_Border_Top_Right_Radius),
      ("border-top-style          ", D_Border_Top_Style),
      ("border-top-width          ", D_Border_Top_Width),
      ("border-width              ", D_Border_Width),
      ("bottom                    ", D_Bottom),
      ("box-shadow                ", D_Box_Shadow),
      ("color                     ", D_Color),
      ("column-gap                ", D_Column_Gap),
      ("cursor                    ", D_Cursor),
      ("display                   ", D_Display),
      ("flex-basis                ", D_Flex_Basis),
      ("flex-direction            ", D_Flex_Direction),
      ("flex-grow                 ", D_Flex_Grow),
      ("flex-shrink               ", D_Flex_Shrink),
      ("flex-wrap                 ", D_Flex_Wrap),
      ("font-family               ", D_Font_Family),
      ("font-size                 ", D_Font_Size),
      ("font-style                ", D_Font_Style),
      ("font-weight               ", D_Font_Weight),
      ("gap                       ", D_Gap),
      ("grid-column               ", D_Grid_Column),
      ("grid-row                  ", D_Grid_Row),
      ("grid-template-columns     ", D_Grid_Template_Columns),
      ("grid-template-rows        ", D_Grid_Template_Rows),
      ("height                    ", D_Height),
      ("justify-content           ", D_Justify_Content),
      ("left                      ", D_Left),
      ("line-height               ", D_Line_Height),
      ("list-style                ", D_List_Style),
      ("list-style-image          ", D_List_Style_Image),
      ("list-style-position       ", D_List_Style_Position),
      ("list-style-type           ", D_List_Style_Type),
      ("margin                    ", D_Margin),
      ("margin-bottom             ", D_Margin_Bottom),
      ("margin-left               ", D_Margin_Left),
      ("margin-right              ", D_Margin_Right),
      ("margin-top                ", D_Margin_Top),
      ("max-height                ", D_Max_Height),
      ("max-width                 ", D_Max_Width),
      ("min-height                ", D_Min_Height),
      ("min-width                 ", D_Min_Width),
      ("object-fit                ", D_Object_Fit),
      ("object-position           ", D_Object_Position),
      ("opacity                   ", D_Opacity),
      ("order                     ", D_Order),
      ("outline                   ", D_Outline),
      ("outline-color             ", D_Outline_Color),
      ("outline-offset            ", D_Outline_Offset),
      ("outline-style             ", D_Outline_Style),
      ("outline-width             ", D_Outline_Width),
      ("overflow                  ", D_Overflow),
      ("overflow-x                ", D_Overflow_X),
      ("overflow-y                ", D_Overflow_Y),
      ("padding                   ", D_Padding),
      ("padding-bottom            ", D_Padding_Bottom),
      ("padding-left              ", D_Padding_Left),
      ("padding-right             ", D_Padding_Right),
      ("padding-top               ", D_Padding_Top),
      ("position                  ", D_Position),
      ("right                     ", D_Right),
      ("row-gap                   ", D_Row_Gap),
      ("text-align                ", D_Text_Align),
      ("text-decoration           ", D_Text_Decoration),
      ("text-overflow             ", D_Text_Overflow),
      ("text-wrap-mode            ", D_Text_Wrap_Mode),
      ("top                       ", D_Top),
      ("transition                ", D_Transition),
      ("vertical-align            ", D_Vertical_Align),
      ("visibility                ", D_Visibility),
      ("white-space               ", D_White_Space),
      ("width                     ", D_Width)
     ];

   function Decl_Of (Name : String) return Decl_Name is
      Lo : Natural := Decl_Table'First;
      Hi : Natural := Decl_Table'Last;
   begin
      if Name'Length = 0 or else Name'Length > Max_Decl_Name then
         return Decl_Unknown;
      end if;

      declare
         K : Decl_Key := [others => ' '];
      begin
         K (1 .. Name'Length) := Name;

         while Lo <= Hi loop
            declare
               Mid : constant Positive := (Lo + Hi) / 2;
            begin
               if Decl_Table (Mid).Name = K then
                  return Decl_Table (Mid).Id;
               elsif Decl_Table (Mid).Name < K then
                  Lo := Mid + 1;
               else
                  Hi := Mid - 1;
               end if;
            end;
         end loop;
      end;

      return Decl_Unknown;
   end Decl_Of;
   procedure Apply_Property (Rules : in out Style_Rules;
                             Name  : String;
                             Value : String) is
      P : constant String := Lower (Trimmed (Name));
      Key : constant Decl_Name := Decl_Of (P);
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
      Grad_Val : Background_Image_Value;
      Object_Pos_Val : Object_Position_Value;
      Ls : Length_Vectors.Vector;
      F : Float;
      I : Integer;
      N : Natural;
      Overflow_Val : Overflow_Value;
      Border_Side  : Border_Style_Kind;
      Has_Border_Width : Boolean := False;
      Has_Border_Style : Boolean := False;
      Has_Border_Color : Boolean := False;
      Border_Width_Val : Parsed_Length;
      Border_Color_Val : Color_Value;
   begin
      if Key = D_Color then
         if Parse_Color (V, CVal) then Rules.Color := Set (CVal); end if;
      elsif Key = D_Background_Color or else Key = D_Background then
         if Parse_Color (V, CVal) then Rules.Background_Color := Set_Bg (CVal); end if;
      elsif Key = D_Padding then
         if Parse_Box (V, Box) then Rules.Padding := Set (Box); end if;
      elsif Key = D_Padding_Top then
         if Parse_Length (V, LVal) then
            Rules.Padding (Top) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Padding_Right then
         if Parse_Length (V, LVal) then
            Rules.Padding (Right) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Padding_Bottom then
         if Parse_Length (V, LVal) then
            Rules.Padding (Bottom) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Padding_Left then
         if Parse_Length (V, LVal) then
            Rules.Padding (Left) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Margin then
         declare
            Sides : Opt_Margin_Sides;
         begin
            if Parse_Margin_Shorthand (V, Sides) then
               Rules.Margin := Sides;
            end if;
         end;
      elsif Key = D_Margin_Top then
         if Lower (V) = "auto" then
            Rules.Margin (Top) := Opt_Margin.Val (Auto_Margin);
         elsif Parse_Length (V, LVal) then
            Rules.Margin (Top) := Opt_Margin.Val (Margin (To_Length (LVal)));
         end if;
      elsif Key = D_Margin_Right then
         if Lower (V) = "auto" then
            Rules.Margin (Right) := Opt_Margin.Val (Auto_Margin);
         elsif Parse_Length (V, LVal) then
            Rules.Margin (Right) := Opt_Margin.Val (Margin (To_Length (LVal)));
         end if;
      elsif Key = D_Margin_Bottom then
         if Lower (V) = "auto" then
            Rules.Margin (Bottom) := Opt_Margin.Val (Auto_Margin);
         elsif Parse_Length (V, LVal) then
            Rules.Margin (Bottom) := Opt_Margin.Val (Margin (To_Length (LVal)));
         end if;
      elsif Key = D_Margin_Left then
         if Lower (V) = "auto" then
            Rules.Margin (Left) := Opt_Margin.Val (Auto_Margin);
         elsif Parse_Length (V, LVal) then
            Rules.Margin (Left) := Opt_Margin.Val (Margin (To_Length (LVal)));
         end if;
      elsif Key = D_Border_Width then
         if Parse_Border_Width (V, BW) then Rules.Border_Width := Set (BW); end if;
      elsif Key = D_Border_Top_Width then
         if Parse_Length (V, LVal) then
            Rules.Border_Width (Top) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Right_Width then
         if Parse_Length (V, LVal) then
            Rules.Border_Width (Right) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Bottom_Width then
         if Parse_Length (V, LVal) then
            Rules.Border_Width (Bottom) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Left_Width then
         if Parse_Length (V, LVal) then
            Rules.Border_Width (Left) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Color then
         if Parse_Color (V, CVal) then Rules.Border_Color := Set (Border_Color (CVal)); end if;
      elsif Key = D_Border_Top_Color then
         if Parse_Color (V, CVal) then
            Rules.Border_Color (Top) := Set_Edge_Color (CVal);
         end if;
      elsif Key = D_Border_Right_Color then
         if Parse_Color (V, CVal) then
            Rules.Border_Color (Right) := Set_Edge_Color (CVal);
         end if;
      elsif Key = D_Border_Bottom_Color then
         if Parse_Color (V, CVal) then
            Rules.Border_Color (Bottom) := Set_Edge_Color (CVal);
         end if;
      elsif Key = D_Border_Left_Color then
         if Parse_Color (V, CVal) then
            Rules.Border_Color (Left) := Set_Edge_Color (CVal);
         end if;
      elsif Key = D_Border_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Rules.Border_Style := Set (Border_Style (Border_Side));
         end if;
      elsif Key = D_Border_Top_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Rules.Border_Style (Top) := Set_Edge_Style (Border_Side);
         end if;
      elsif Key = D_Border_Right_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Rules.Border_Style (Right) := Set_Edge_Style (Border_Side);
         end if;
      elsif Key = D_Border_Bottom_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Rules.Border_Style (Bottom) := Set_Edge_Style (Border_Side);
         end if;
      elsif Key = D_Border_Left_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Rules.Border_Style (Left) := Set_Edge_Style (Border_Side);
         end if;
      elsif Key = D_Border then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val);
         if Has_Border_Width then
            Rules.Border_Width := Set (Border_Width (To_Length (Border_Width_Val)));
         end if;
         if Has_Border_Style then
            Rules.Border_Style := Set (Border_Style (Border_Side));
         end if;
         if Has_Border_Color then
            Rules.Border_Color := Set (Border_Color (Border_Color_Val));
         end if;
      elsif Key = D_Border_Top then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val);
         if Has_Border_Width then
            Rules.Border_Width (Top) := Set (To_Length (Border_Width_Val));
         end if;
         if Has_Border_Style then
            Rules.Border_Style (Top) := Set_Edge_Style (Border_Side);
         end if;
         if Has_Border_Color then
            Rules.Border_Color (Top) := Set_Edge_Color (Border_Color_Val);
         end if;
      elsif Key = D_Border_Right then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val);
         if Has_Border_Width then
            Rules.Border_Width (Right) := Set (To_Length (Border_Width_Val));
         end if;
         if Has_Border_Style then
            Rules.Border_Style (Right) := Set_Edge_Style (Border_Side);
         end if;
         if Has_Border_Color then
            Rules.Border_Color (Right) := Set_Edge_Color (Border_Color_Val);
         end if;
      elsif Key = D_Border_Bottom then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val);
         if Has_Border_Width then
            Rules.Border_Width (Bottom) := Set (To_Length (Border_Width_Val));
         end if;
         if Has_Border_Style then
            Rules.Border_Style (Bottom) := Set_Edge_Style (Border_Side);
         end if;
         if Has_Border_Color then
            Rules.Border_Color (Bottom) := Set_Edge_Color (Border_Color_Val);
         end if;
      elsif Key = D_Border_Left then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val);
         if Has_Border_Width then
            Rules.Border_Width (Left) := Set (To_Length (Border_Width_Val));
         end if;
         if Has_Border_Style then
            Rules.Border_Style (Left) := Set_Edge_Style (Border_Side);
         end if;
         if Has_Border_Color then
            Rules.Border_Color (Left) := Set_Edge_Color (Border_Color_Val);
         end if;
      elsif Key = D_Border_Radius then
         if Parse_Border_Radius (V, BR) then Rules.Border_Radius := Set (BR); end if;
      elsif Key = D_Border_Top_Left_Radius then
         if Parse_Length (V, LVal) then
            Rules.Border_Radius (Top_Left) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Top_Right_Radius then
         if Parse_Length (V, LVal) then
            Rules.Border_Radius (Top_Right) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Bottom_Right_Radius then
         if Parse_Length (V, LVal) then
            Rules.Border_Radius (Bottom_Right) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Border_Bottom_Left_Radius then
         if Parse_Length (V, LVal) then
            Rules.Border_Radius (Bottom_Left) := Set (To_Length (LVal));
         end if;
      elsif Key = D_Width then
         if Parse_Size_Value (V, SVal) then Rules.Width := Set (SVal); end if;
      elsif Key = D_Height then
         if Parse_Size_Value (V, SVal) then Rules.Height := Set (SVal); end if;
      elsif Key = D_Min_Width then
         if Parse_Size_Value (V, SVal) then Rules.Min_Width := Set (SVal); end if;
      elsif Key = D_Max_Width then
         if Parse_Size_Value (V, SVal) then Rules.Max_Width := Set (SVal); end if;
      elsif Key = D_Min_Height then
         if Parse_Size_Value (V, SVal) then Rules.Min_Height := Set (SVal); end if;
      elsif Key = D_Max_Height then
         if Parse_Size_Value (V, SVal) then Rules.Max_Height := Set (SVal); end if;
      elsif Key = D_Font_Family then
         if Fits_In_Style (V) then
            Rules.Font_Family := Set_Font_Family (V);
         end if;
      elsif Key = D_Font_Size then
         if Parse_Length (V, LVal) then Rules.Font_Size := Set_Font (To_Length (LVal)); end if;
      elsif Key = D_Font_Weight then
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
      elsif Key = D_Font_Style then
         if LV = "normal" then Rules.Font_Style := Set (Style_Normal);
         elsif LV = "italic" then Rules.Font_Style := Set (Style_Italic);
         elsif LV = "oblique" then Rules.Font_Style := Set (Style_Oblique);
         end if;
      elsif Key = D_Text_Decoration then
         if LV = "none" then Rules.Text_Decoration := Set (Decoration_None);
         elsif LV = "underline" then Rules.Text_Decoration := Set (Decoration_Underline);
         elsif LV = "overline" then Rules.Text_Decoration := Set (Decoration_Overline);
         elsif LV = "line-through" then Rules.Text_Decoration := Set (Decoration_Line_Through);
         end if;
      elsif Key = D_List_Style_Type then
         if Parse_List_Style_Type_Value (V, List_Type_Val) then
            Rules.List_Style_Type := Set (List_Type_Val);
         end if;
      elsif Key = D_Background_Image then
         if LV = "none" then
            Rules.Background_Image := Set_Bg_Image (No_Background_Image);
         elsif Parse_Linear_Gradient (V, Grad_Val) then
            Rules.Background_Image := Set_Bg_Image (Grad_Val);
         elsif Parse_URL_Function (V, URI_Text) then
            Rules.Background_Image := Set_Bg_Image
              (Background_Image_URL (To_String (URI_Text)));
         end if;
      elsif Key = D_List_Style_Image then
         if LV = "none" then
            Rules.List_Style_Image := Set (No_List_Image);
         elsif Parse_URL_Function (V, URI_Text) then
            Rules.List_Style_Image := Set (List_Image (To_String (URI_Text)));
         end if;
      elsif Key = D_List_Style_Position then
         if Parse_List_Style_Position_Value (V, List_Position_Val) then
            Rules.List_Style_Position := Set (List_Position_Val);
         end if;
      elsif Key = D_List_Style then
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
      elsif Key = D_White_Space then
         if LV = "normal" then Rules.White_Space := Set (WS_Normal);
         elsif LV = "nowrap" then Rules.White_Space := Set (WS_Nowrap);
         elsif LV = "pre" then Rules.White_Space := Set (WS_Pre);
         elsif LV = "pre-wrap" then Rules.White_Space := Set (WS_Pre_Wrap);
         elsif LV = "pre-line" then Rules.White_Space := Set (WS_Pre_Line);
         end if;
      elsif Key = D_Text_Overflow then
         if LV = "clip" then Rules.Text_Overflow := Set (Overflow_Clip);
         elsif LV = "ellipsis" then Rules.Text_Overflow := Set (Overflow_Ellipsis);
         end if;
      elsif Key = D_Line_Height then
         if LV = "normal" then
            Rules.Line_Height := Set (Normal_Line_Height);
         elsif Parse_Number (V, F) then
            Rules.Line_Height := Set (Line_Height (F));
         elsif Parse_Length (V, LVal) then
            Rules.Line_Height := Set (Line_Height (To_Length (LVal)));
         end if;
      elsif Key = D_Text_Align then
         if LV = "left" then Rules.Text_Align := Set (Text_Left);
         elsif LV = "right" then Rules.Text_Align := Set (Text_Right);
         elsif LV = "center" then Rules.Text_Align := Set (Text_Center);
         elsif LV = "justify" then Rules.Text_Align := Set (Text_Justify);
         elsif LV = "start" then Rules.Text_Align := Set (Text_Start);
         elsif LV = "end" then Rules.Text_Align := Set (Text_End);
         end if;
      elsif Key = D_Text_Wrap_Mode then
         if LV = "wrap" then Rules.Text_Wrap_Mode := Set (TWM_Wrap);
         elsif LV = "nowrap" then Rules.Text_Wrap_Mode := Set (TWM_Nowrap);
         end if;
      elsif Key = D_Vertical_Align then
         if LV = "baseline" then Rules.Vertical_Align := Set (VA_Baseline);
         elsif LV = "top" then Rules.Vertical_Align := Set (VA_Top);
         elsif LV = "middle" then Rules.Vertical_Align := Set (VA_Middle);
         elsif LV = "bottom" then Rules.Vertical_Align := Set (VA_Bottom);
         elsif LV = "text-top" then Rules.Vertical_Align := Set (VA_Text_Top);
         elsif LV = "text-bottom" then Rules.Vertical_Align := Set (VA_Text_Bottom);
         end if;
      elsif Key = D_Display then
         if LV = "none" then Rules.Display := Set (Display_None);
         elsif LV = "block" then Rules.Display := Set (Block);
         elsif LV = "inline" then Rules.Display := Set (Inline);
         elsif LV = "inline-block" then Rules.Display := Set (Inline_Block);
         elsif LV = "flex" then Rules.Display := Set (Flex);
         elsif LV = "inline-flex" then Rules.Display := Set (Inline_Flex);
         elsif LV = "grid" then Rules.Display := Set (Grid);
         elsif LV = "inline-grid" then Rules.Display := Set (Inline_Grid);
         end if;
      elsif Key = D_Position then
         if LV = "static" then Rules.Position := Set (Static);
         elsif LV = "relative" then Rules.Position := Set (Relative);
         elsif LV = "absolute" then Rules.Position := Set (Absolute);
         elsif LV = "fixed" then Rules.Position := Set (Fixed);
         elsif LV = "sticky" then Rules.Position := Set (Sticky);
         end if;
      elsif Key = D_Top then
         if LV = "auto" then
            Rules.Top := Set_Top (Auto_Inset);
         elsif Parse_Length (V, LVal) then
            Rules.Top := Set_Top (Inset (To_Length (LVal)));
         end if;
      elsif Key = D_Right then
         if LV = "auto" then
            Rules.Right := Set_Right (Auto_Inset);
         elsif Parse_Length (V, LVal) then
            Rules.Right := Set_Right (Inset (To_Length (LVal)));
         end if;
      elsif Key = D_Bottom then
         if LV = "auto" then
            Rules.Bottom := Set_Bottom (Auto_Inset);
         elsif Parse_Length (V, LVal) then
            Rules.Bottom := Set_Bottom (Inset (To_Length (LVal)));
         end if;
      elsif Key = D_Left then
         if LV = "auto" then
            Rules.Left := Set_Left (Auto_Inset);
         elsif Parse_Length (V, LVal) then
            Rules.Left := Set_Left (Inset (To_Length (LVal)));
         end if;
      elsif Key = D_Overflow then
         if Parse_Overflow_Value (LV, Overflow_Val) then
            Set_Overflow_Shorthand (Rules, Overflow_Val);
         end if;
      elsif Key = D_Overflow_X then
         if Parse_Overflow_Value (LV, Overflow_Val) then
            Rules.Overflow_X := Set_Overflow_X (Overflow_Val);
         end if;
      elsif Key = D_Overflow_Y then
         if Parse_Overflow_Value (LV, Overflow_Val) then
            Rules.Overflow_Y := Set_Overflow_Y (Overflow_Val);
         end if;
      --  Opacity's grammar is <number> with no range in it, so CSS Color
      --  4 is free to say an out-of-range value "is not invalid" and is
      --  clamped instead. It clamps at computed-value time and keeps the
      --  number as specified; Opacity_Value cannot hold one, so this
      --  clamps on the way in. Same computed result, and it only shows
      --  where the specified value is read back rather than used.
      elsif Key = D_Opacity then
         if Parse_Number (V, F) then
            Rules.Opacity :=
              Set (Opacity_Value (Float'Max (0.0, Float'Min (1.0, F))));
         end if;
      elsif Key = D_Cursor then
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
      elsif Key = D_Visibility then
         if LV = "visible" then Rules.Visibility := Set (Visibility_Visible);
         elsif LV = "hidden" then Rules.Visibility := Set (Visibility_Hidden);
         elsif LV = "collapse" then Rules.Visibility := Set (Visibility_Collapse);
         end if;
      elsif Key = D_Object_Fit then
         if LV = "fill" then Rules.Object_Fit := Set (Fit_Fill);
         elsif LV = "contain" then Rules.Object_Fit := Set (Fit_Contain);
         elsif LV = "cover" then Rules.Object_Fit := Set (Fit_Cover);
         elsif LV = "none" then Rules.Object_Fit := Set (Fit_None);
         elsif LV = "scale-down" then Rules.Object_Fit := Set (Fit_Scale_Down);
         end if;
      elsif Key = D_Object_Position then
         if Parse_Object_Position_Value (V, Object_Pos_Val) then
            Rules.Object_Position := Set (Object_Pos_Val);
         end if;
      elsif Key = D_Flex_Direction then
         if LV = "row" then Rules.Flex_Direction := Set (Row);
         elsif LV = "row-reverse" then Rules.Flex_Direction := Set (Row_Reverse);
         elsif LV = "column" then Rules.Flex_Direction := Set (Column);
         elsif LV = "column-reverse" then Rules.Flex_Direction := Set (Column_Reverse);
         end if;
      elsif Key = D_Flex_Wrap then
         if LV = "nowrap" then Rules.Flex_Wrap := Set (No_Wrap);
         elsif LV = "wrap" then Rules.Flex_Wrap := Set (Wrap);
         elsif LV = "wrap-reverse" then Rules.Flex_Wrap := Set (Wrap_Reverse);
         end if;
      elsif Key = D_Justify_Content then
         if LV = "flex-start" or else LV = "start" then Rules.Justify_Content := Set (Flex_Start);
         elsif LV = "flex-end" or else LV = "end" then Rules.Justify_Content := Set (Flex_End);
         elsif LV = "center" then Rules.Justify_Content := Set (Center);
         elsif LV = "space-between" then Rules.Justify_Content := Set (Space_Between);
         elsif LV = "space-around" then Rules.Justify_Content := Set (Space_Around);
         elsif LV = "space-evenly" then Rules.Justify_Content := Set (Space_Evenly);
         end if;
      elsif Key = D_Align_Items then
         if LV = "flex-start" or else LV = "start" then Rules.Align_Items := Set (Flex_Start);
         elsif LV = "flex-end" or else LV = "end" then Rules.Align_Items := Set (Flex_End);
         elsif LV = "center" then Rules.Align_Items := Set (Center);
         elsif LV = "baseline" then Rules.Align_Items := Set (Baseline);
         elsif LV = "stretch" then Rules.Align_Items := Set (Stretch);
         end if;
      elsif Key = D_Align_Self then
         if LV = "auto" then Rules.Align_Self := Set (Align_Self_Value'(Auto));
         elsif LV = "flex-start" or else LV = "start" then Rules.Align_Self := Set (Align_Self_Value'(Flex_Start));
         elsif LV = "flex-end" or else LV = "end" then Rules.Align_Self := Set (Align_Self_Value'(Flex_End));
         elsif LV = "center" then Rules.Align_Self := Set (Align_Self_Value'(Center));
         elsif LV = "baseline" then Rules.Align_Self := Set (Align_Self_Value'(Baseline));
         elsif LV = "stretch" then Rules.Align_Self := Set (Align_Self_Value'(Stretch));
         end if;
      elsif Key = D_Align_Content then
         if LV = "flex-start" or else LV = "start" then Rules.Align_Content := Set (Align_Content_Value'(Flex_Start));
         elsif LV = "flex-end" or else LV = "end" then Rules.Align_Content := Set (Align_Content_Value'(Flex_End));
         elsif LV = "center" then Rules.Align_Content := Set (Align_Content_Value'(Center));
         elsif LV = "space-between" then Rules.Align_Content := Set (Align_Content_Value'(Space_Between));
         elsif LV = "space-around" then Rules.Align_Content := Set (Align_Content_Value'(Space_Around));
         elsif LV = "stretch" then Rules.Align_Content := Set (Align_Content_Value'(Stretch));
         end if;
      elsif Key = D_Gap then
         if Parse_Length_List (V, Ls) then
            if Ls.Length = 1 then Rules.Gap := Set (Gap (To_Length (Ls (1))));
            elsif Ls.Length >= 2 then Rules.Gap := Set (Gap (To_Length (Ls (1)), To_Length (Ls (2))));
            end if;
         end if;
      elsif Key = D_Row_Gap or else Key = D_Column_Gap then
         if Parse_Length (V, LVal) then
            declare
               --  One field carries both axes, so a longhand overlays its
               --  own axis and leaves the other as it was — unnamed here,
               --  or whatever a preceding shorthand in this rule set.
               Axis : constant Gap_Value :=
                 (if Key = D_Row_Gap then Gap_Row (To_Length (LVal))
                  else Gap_Column (To_Length (LVal)));
            begin
               if Opt_Gap.Is_Set (Rules.Gap) then
                  Rules.Gap := Set (Overlay (Rules.Gap.Value, Axis));
               else
                  Rules.Gap := Set (Axis);
               end if;
            end;
         end if;
      --  The flex factors carry their range in the grammar itself,
      --  <number [0,inf]>, and CSS Values 4 makes a value outside a
      --  bracketed range invalid rather than clamped. So a negative one
      --  is dropped, where an out-of-range opacity above is not.
      elsif Key = D_Flex_Grow then
         if Parse_Number (V, F) and then F >= 0.0 then
            Rules.Flex_Grow := Set (Flex_Grow_Value (F));
         end if;
      elsif Key = D_Flex_Shrink then
         if Parse_Number (V, F) and then F >= 0.0 then
            Rules.Flex_Shrink := Set (Flex_Shrink_Value (F));
         end if;
      elsif Key = D_Flex_Basis then
         if LV = "auto" then Rules.Flex_Basis := Set (Auto_Basis);
         elsif LV = "content" then Rules.Flex_Basis := Set (Content_Basis);
         elsif Parse_Length (V, LVal) then Rules.Flex_Basis := Set (Basis (To_Length (LVal)));
         end if;
      elsif Key = D_Order then
         if Parse_Integer (V, I) then Rules.Order := Set (Order_Value (I)); end if;
      elsif Key = D_Grid_Template_Columns then
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
      elsif Key = D_Grid_Template_Rows then
         if Parse_Grid_Track_Count (V, N) then
            Rules.Grid_Rows := Set (Grid_Rows_Value (N));
         end if;
      elsif Key = D_Grid_Column or else Key = D_Grid_Row then
         declare
            Slash_Pos   : Natural := 0;
            Start_Val   : Integer;
            Span_Val    : Natural;
            Is_Col      : constant Boolean := Key = D_Grid_Column;
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
      elsif Key = D_Outline_Width then
         if Parse_Length (V, LVal) then Rules.Outline_Width := Set_Outline_Width (To_Length (LVal)); end if;
      elsif Key = D_Outline_Color then
         if Parse_Color (V, CVal) then Rules.Outline_Color := Set_Outline_Color (CVal); end if;
      elsif Key = D_Outline_Style then
         if LV = "none" then Rules.Outline_Style := Set (Outline_None);
         elsif LV = "solid" then Rules.Outline_Style := Set (Outline_Solid);
         elsif LV = "dashed" then Rules.Outline_Style := Set (Outline_Dashed);
         elsif LV = "dotted" then Rules.Outline_Style := Set (Outline_Dotted);
         end if;
      elsif Key = D_Outline_Offset then
         if Parse_Length (V, LVal) then Rules.Outline_Offset := Set_Outline_Offset (To_Length (LVal)); end if;
      elsif Key = D_Outline then
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
      elsif Key = D_Box_Shadow then
         if Parse_Box_Shadow (V, Shadow_Val) then Rules.Box_Shadow := Set (Shadow_Val); end if;
      elsif Key = D_Transition then
         declare
            T : Transition_Spec;
         begin
            if Parse_Transition (V, T) then
               Rules.Transition := Set (T);
            end if;
         end;
      end if;

   --  A declaration carrying a value its property cannot hold is one
   --  declaration to drop, not a sheet to refuse. Parse_Rules guards the
   --  whole parse in one handler, so without this a single such value
   --  costs every rule in the file and the caller is told only that the
   --  sheet failed. The ranges that are known are checked above, where
   --  the value can be dropped knowingly and the rest of the declaration
   --  still applied; this stands behind them for the next property added
   --  without one.
   --
   --  Constraint_Error alone, because that is what a value outside its
   --  type raises. Anything else -- storage exhausted, a bug in a parse
   --  helper -- is not a property of the stylesheet and is left to
   --  travel.
   exception
      when Constraint_Error =>
         null;
   end Apply_Property;

   ---------------------------------------------------------------------------
   --  Custom Property Preprocessing (var(), :root, @property)
   ---------------------------------------------------------------------------

   function Var_Lookup
     (Vars : Variable_Vectors.Vector;
      Name : String) return String
   is
   begin
      for I in 1 .. Natural (Vars.Length) loop
         if To_String (Vars.Element (I).Name) = Name then
            return To_String (Vars.Element (I).Value);
         end if;
      end loop;
      return "";
   end Var_Lookup;

   function Has_Variable
     (Vars : Variable_Vectors.Vector;
      Name : String) return Boolean
   is
   begin
      for I in 1 .. Natural (Vars.Length) loop
         if To_String (Vars.Element (I).Name) = Name then
            return True;
         end if;
      end loop;
      return False;
   end Has_Variable;

   procedure Set_Variable
     (Vars  : in out Variable_Vectors.Vector;
      Name  : String;
      Value : String)
   is
   begin
      for I in 1 .. Natural (Vars.Length) loop
         if To_String (Vars.Element (I).Name) = Name then
            Vars.Replace_Element (I,
              (Name  => To_Unbounded_String (Name),
               Value => To_Unbounded_String (Value)));
            return;
         end if;
      end loop;
      Vars.Append
        (Variable_Entry'(Name  => To_Unbounded_String (Name),
                         Value => To_Unbounded_String (Value)));
   end Set_Variable;

   function Find_Var_End (CSS : String; Start : Positive) return Natural is
      --  Find closing ')' of var(...) starting after 'var('.
      Depth : Natural := 1;
      I     : Positive := Start;
   begin
      while I <= CSS'Last loop
         if CSS (I) = '(' then
            Depth := Depth + 1;
         elsif CSS (I) = ')' then
            Depth := Depth - 1;
            if Depth = 0 then
               return I;
            end if;
         end if;
         I := I + 1;
      end loop;
      return 0;
   end Find_Var_End;

   function Resolve_Var_References
     (CSS  : String;
      Vars : Variable_Vectors.Vector) return String
   is
      Max_Depth : constant := 10;
      Current   : Unbounded_String := To_Unbounded_String (CSS);
   begin
      for Iteration in 1 .. Max_Depth loop
         declare
            Input   : constant String := To_String (Current);
            Output  : Unbounded_String;
            I       : Positive := Input'First;
            Changed : Boolean := False;
         begin
            while I <= Input'Last loop
               if I + 3 <= Input'Last
                 and then Input (I .. I + 3) = "var("
                 and then (I = Input'First
                           or else (not Char.Is_Alphanumeric (Input (I - 1))
                                    and then Input (I - 1) /= '_'
                                    and then Input (I - 1) /= '-'))
               then
                  declare
                     End_Pos : constant Natural := Find_Var_End (Input, I + 4);
                  begin
                     if End_Pos = 0 then
                        Append (Output, Input (I .. Input'Last));
                        I := Input'Last + 1;
                     else
                        declare
                           Inner     : constant String := Input (I + 4 .. End_Pos - 1);
                           Comma_Pos : Natural := 0;
                           Depth     : Natural := 0;
                        begin
                           for J in Inner'Range loop
                              if Inner (J) = '(' then
                                 Depth := Depth + 1;
                              elsif Inner (J) = ')' then
                                 Depth := Depth - 1;
                              elsif Inner (J) = ',' and then Depth = 0 then
                                 Comma_Pos := J;
                                 exit;
                              end if;
                           end loop;

                           declare
                              Var_Name : constant String :=
                                (if Comma_Pos > 0
                                 then Trimmed (Inner (Inner'First .. Comma_Pos - 1))
                                 else Trimmed (Inner));
                              Fallback : constant String :=
                                (if Comma_Pos > 0
                                 then Trimmed (Inner (Comma_Pos + 1 .. Inner'Last))
                                 else "");
                           begin
                              if Has_Variable (Vars, Var_Name) then
                                 Append (Output, Var_Lookup (Vars, Var_Name));
                                 Changed := True;
                              elsif Comma_Pos > 0 then
                                 Append (Output, Fallback);
                                 Changed := True;
                              else
                                 Append (Output, Input (I .. End_Pos));
                              end if;
                           end;
                        end;
                        I := End_Pos + 1;
                     end if;
                  end;
               else
                  Append (Output, Input (I));
                  I := I + 1;
               end if;
            end loop;

            Current := Output;
            exit when not Changed;
         end;
      end loop;
      return To_String (Current);
   end Resolve_Var_References;

   function Resolve_Variable_Map
     (Vars : Variable_Vectors.Vector) return Variable_Vectors.Vector
   is
      Result : Variable_Vectors.Vector := Vars;
   begin
      for I in 1 .. Natural (Result.Length) loop
         Result.Replace_Element
           (I,
            (Name  => Result.Element (I).Name,
             Value => To_Unbounded_String
               (Resolve_Var_References (To_String (Result.Element (I).Value), Vars))));
      end loop;
      return Result;
   end Resolve_Variable_Map;

   function Extract_At_Property_Blocks (CSS : String) return String is
      --  Remove @property --name { ... } blocks, extracting initial-value
      --  into Variables. Returns cleaned CSS.
      Result : Unbounded_String;
      I      : Positive := CSS'First;
   begin
      while I <= CSS'Last loop
         --  Look for "@property"
         if I + 8 <= CSS'Last
           and then CSS (I .. I + 8) = "@property"
         then
            --  Skip to opening brace
            declare
               Open  : Natural := 0;
               Close : Natural := 0;
            begin
               for J in I + 9 .. CSS'Last loop
                  if CSS (J) = '{' then
                     Open := J;
                     exit;
                  end if;
               end loop;
               if Open > 0 then
                  for J in Open + 1 .. CSS'Last loop
                     if CSS (J) = '}' then
                        Close := J;
                        exit;
                     end if;
                  end loop;
               end if;
               if Close > 0 then
                  I := Close + 1;
               else
                  Append (Result, CSS (I));
                  I := I + 1;
               end if;
            end;
         else
            Append (Result, CSS (I));
            I := I + 1;
         end if;
      end loop;
      return To_String (Result);
   end Extract_At_Property_Blocks;

   procedure Collect_At_Property_Defaults
     (CSS  : String;
      Vars : in out Variable_Vectors.Vector)
   is
      I : Positive := CSS'First;
   begin
      while I <= CSS'Last loop
         if I + 8 <= CSS'Last
           and then CSS (I .. I + 8) = "@property"
         then
            declare
               Open  : Natural := 0;
               Close : Natural := 0;
               Name_Start : Natural := 0;
               Name_End   : Natural := 0;
            begin
               --  Find variable name (--xxx)
               for J in I + 9 .. CSS'Last loop
                  if not Is_Whitespace (CSS (J)) then
                     Name_Start := J;
                     exit;
                  end if;
               end loop;
               if Name_Start > 0 then
                  for J in Name_Start .. CSS'Last loop
                     if Is_Whitespace (CSS (J)) or else CSS (J) = '{' then
                        Name_End := J - 1;
                        exit;
                     end if;
                  end loop;
               end if;
               --  Find block
               for J in I + 9 .. CSS'Last loop
                  if CSS (J) = '{' then
                     Open := J;
                     exit;
                  end if;
               end loop;
               if Open > 0 then
                  for J in Open + 1 .. CSS'Last loop
                     if CSS (J) = '}' then
                        Close := J;
                        exit;
                     end if;
                  end loop;
               end if;
               if Close > 0 and then Name_Start > 0 and then Name_End >= Name_Start then
                  declare
                     Var_Name : constant String := CSS (Name_Start .. Name_End);
                     Body_Str : constant String := CSS (Open + 1 .. Close - 1);
                     IV_Key   : constant String := "initial-value";
                     Lowered  : constant String := Lower (Body_Str);
                     IV_Pos   : constant Natural := Fix.Index (Lowered, IV_Key);
                     --  IV_Pos is relative to Lowered'First; convert to
                     --  Body_Str's index space in case bounds differ.
                     IV_Abs   : constant Natural :=
                       (if IV_Pos > 0
                        then Body_Str'First + (IV_Pos - Lowered'First)
                        else 0);
                  begin
                     if IV_Abs > 0 then
                        declare
                           Colon : Natural := 0;
                           Semi  : Natural := 0;
                        begin
                           for J in IV_Abs + IV_Key'Length .. Body_Str'Last loop
                              if Body_Str (J) = ':' then
                                 Colon := J;
                                 exit;
                              end if;
                           end loop;
                           if Colon > 0 then
                              Semi := Fix.Index (Body_Str, ";", From => Colon + 1);
                              if Semi = 0 then
                                 Semi := Body_Str'Last + 1;
                              end if;
                              Set_Variable (Vars, Var_Name,
                                Trimmed (Body_Str (Colon + 1 .. Semi - 1)));
                           end if;
                        end;
                     end if;
                  end;
                  I := Close + 1;
               else
                  I := I + 1;
               end if;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Collect_At_Property_Defaults;

   function Extract_Root_Block
     (CSS  : String;
      Vars : in out Variable_Vectors.Vector;
      Root_Declarations : in out Unbounded_String) return String
   is
      --  Find :root { ... } blocks, extract custom properties into Vars,
      --  collect normal declarations for later metadata parsing, and remove
      --  the blocks from CSS.
      Result : Unbounded_String;
      I      : Positive := CSS'First;
   begin
      while I <= CSS'Last loop
         if I + 4 <= CSS'Last
           and then CSS (I .. I + 4) = ":root"
         then
            --  Find the block
            declare
               Open  : Natural := 0;
               Close : Natural := 0;
            begin
               for J in I + 5 .. CSS'Last loop
                  if CSS (J) = '{' then
                     Open := J;
                     exit;
                  end if;
               end loop;
               if Open > 0 then
                  for J in Open + 1 .. CSS'Last loop
                     if CSS (J) = '}' then
                        Close := J;
                        exit;
                     end if;
                  end loop;
               end if;
               if Close > 0 then
                  --  Parse declarations inside the block
                  declare
                     Body_Str : constant String := CSS (Open + 1 .. Close - 1);
                     Decl_Pos : Positive := Body_Str'First;
                  begin
                     while Decl_Pos <= Body_Str'Last loop
                        while Decl_Pos <= Body_Str'Last
                          and then (Is_Whitespace (Body_Str (Decl_Pos))
                                    or else Body_Str (Decl_Pos) = ';')
                        loop
                           Decl_Pos := Decl_Pos + 1;
                        end loop;
                        exit when Decl_Pos > Body_Str'Last;

                        declare
                           Decl_End : constant Natural :=
                             Fix.Index (Body_Str, ";", From => Decl_Pos);
                           Decl : constant String :=
                             (if Decl_End = 0
                              then Trimmed (Body_Str (Decl_Pos .. Body_Str'Last))
                              else Trimmed (Body_Str (Decl_Pos .. Decl_End - 1)));
                           Sep : constant Natural := Fix.Index (Decl, ":");
                        begin
                           if Sep > 0 then
                              declare
                                 Prop_Name  : constant String :=
                                   Trimmed (Decl (Decl'First .. Sep - 1));
                                 Prop_Value : constant String :=
                                   Trimmed (Decl (Sep + 1 .. Decl'Last));
                              begin
                                 if Prop_Name'Length >= 2
                                   and then Prop_Name (Prop_Name'First .. Prop_Name'First + 1) = "--"
                                 then
                                    Set_Variable (Vars, Prop_Name, Prop_Value);
                                 else
                                    Append (Root_Declarations, Prop_Name);
                                    Append (Root_Declarations, ": ");
                                    Append (Root_Declarations, Prop_Value);
                                    Append (Root_Declarations, ";");
                                    Append (Root_Declarations, ASCII.LF);
                                 end if;
                              end;
                           end if;

                           if Decl_End = 0 then
                              Decl_Pos := Body_Str'Last + 1;
                           else
                              Decl_Pos := Decl_End + 1;
                           end if;
                        end;
                     end loop;
                  end;
                  --  Skip past the :root block
                  I := Close + 1;
               else
                  Append (Result, CSS (I));
                  I := I + 1;
               end if;
            end;
         else
            Append (Result, CSS (I));
            I := I + 1;
         end if;
      end loop;
      return To_String (Result);
   end Extract_Root_Block;

   function Strip_Non_Root_Custom_Properties (CSS : String) return String is
      --  Remove --name: value declarations from normal (non-:root) blocks.
      Result : Unbounded_String;
      I      : Positive := CSS'First;
   begin
      while I <= CSS'Last loop
         declare
            Open : constant Natural := Fix.Index (CSS, "{", From => I);
         begin
            exit when Open = 0;
            declare
               Close : constant Natural := Fix.Index (CSS, "}", From => Open + 1);
            begin
               if Close = 0 then
                  --  Unclosed block, copy rest
                  Append (Result, CSS (I .. CSS'Last));
                  return To_String (Result);
               end if;
               --  Copy selector
               Append (Result, CSS (I .. Open));
               --  Process body: copy declarations, skip --* ones
               declare
                  Body_Str : constant String := CSS (Open + 1 .. Close - 1);
                  Decl_Pos : Positive := Body_Str'First;
               begin
                  while Decl_Pos <= Body_Str'Last loop
                     while Decl_Pos <= Body_Str'Last
                       and then (Is_Whitespace (Body_Str (Decl_Pos))
                                 or else Body_Str (Decl_Pos) = ';')
                     loop
                        Append (Result, Body_Str (Decl_Pos));
                        Decl_Pos := Decl_Pos + 1;
                     end loop;
                     exit when Decl_Pos > Body_Str'Last;

                     declare
                        Decl_End : constant Natural :=
                          Fix.Index (Body_Str, ";", From => Decl_Pos);
                        Decl_Str : constant String :=
                          (if Decl_End = 0
                           then Body_Str (Decl_Pos .. Body_Str'Last)
                           else Body_Str (Decl_Pos .. Decl_End));
                        Name_End : Natural := 0;
                     begin
                        --  Find the property name part (before ':')
                        for J in Decl_Str'Range loop
                           if Decl_Str (J) = ':' then
                              Name_End := J - 1;
                              exit;
                           end if;
                        end loop;
                        declare
                           Is_Custom : Boolean := False;
                        begin
                           if Name_End > 0 then
                              declare
                                 Prop_Name : constant String :=
                                   Trimmed (Decl_Str (Decl_Str'First .. Name_End));
                              begin
                                 Is_Custom := Prop_Name'Length >= 2
                                   and then Prop_Name
                                     (Prop_Name'First .. Prop_Name'First + 1) = "--";
                              end;
                           end if;
                           if not Is_Custom then
                              Append (Result, Decl_Str);
                           end if;
                        end;

                        if Decl_End = 0 then
                           Decl_Pos := Body_Str'Last + 1;
                        else
                           Decl_Pos := Decl_End + 1;
                        end if;
                     end;
                  end loop;
               end;
               Append (Result, '}');
               I := Close + 1;
            end;
         end;
      end loop;
      return To_String (Result);
   end Strip_Non_Root_Custom_Properties;

   procedure Build_Root_Metadata
     (Root_CSS  : String;
      Metadata  : in out Stylesheet_Metadata)
   is
      Pos     : Positive := Root_CSS'First;
      Working : Adi.Widget.Part_Style_Array := Adi.Widget.Empty_Part_Styles;
      Touched : Boolean := False;
   begin
      if Root_CSS'Length = 0 then
         return;
      end if;

      Working := Adi.Widget.Expand (Metadata.Root_Styles);

      while Pos <= Root_CSS'Last loop
         while Pos <= Root_CSS'Last
           and then (Is_Whitespace (Root_CSS (Pos))
                     or else Root_CSS (Pos) = ';')
         loop
            Pos := Pos + 1;
         end loop;
         exit when Pos > Root_CSS'Last;

         declare
            Decl_End : constant Natural := Fix.Index (Root_CSS, ";", From => Pos);
            Decl     : constant String :=
              (if Decl_End = 0
               then Trimmed (Root_CSS (Pos .. Root_CSS'Last))
               else Trimmed (Root_CSS (Pos .. Decl_End - 1)));
            Sep      : constant Natural := Fix.Index (Decl, ":");
         begin
            if Sep > 0 then
               declare
                  Prop_Name  : constant String :=
                    Trimmed (Decl (Decl'First .. Sep - 1));
                  Prop_Value : constant String :=
                    Trimmed (Decl (Sep + 1 .. Decl'Last));
               begin
                  Metadata.Has_Root_Style := True;
                  Touched := True;
                  Working (Main_Part).Enabled := True;
                  Apply_Property
                    (Working (Main_Part).Style.Base, Prop_Name, Prop_Value);
                  if Lower (Prop_Name) = "font-size"
                    and then Opt_Font_Size.Is_Set
                      (Working (Main_Part).Style.Base.Font_Size)
                  then
                     Metadata.Has_Root_Font_Size := True;
                     Metadata.Root_Font_Size :=
                       Opt_Font_Size.Resolve
                         (Working (Main_Part).Style.Base.Font_Size);
                  end if;
               end;
            end if;

            if Decl_End = 0 then
               Pos := Root_CSS'Last + 1;
            else
               Pos := Decl_End + 1;
            end if;
         end;
      end loop;

      if Touched then
         Metadata.Root_Styles := Adi.Widget.Intern (Working);
      end if;
   end Build_Root_Metadata;

   function Preprocess_Custom_Properties
     (CSS       : String;
      Vars      : out Variable_Vectors.Vector;
      Metadata  : out Stylesheet_Metadata) return String
   is
      Step1      : constant String := Strip_Comments (CSS);
      Root_Decls : Unbounded_String;
      Resolved   : Variable_Vectors.Vector;
      Root_CSS   : Unbounded_String;
   begin
      Vars.Clear;
      Metadata := (others => <>);

      Collect_At_Property_Defaults (Step1, Vars);
      declare
         Step2 : constant String := Extract_At_Property_Blocks (Step1);
         Step3 : constant String := Extract_Root_Block (Step2, Vars, Root_Decls);
         Step4 : constant String := Strip_Non_Root_Custom_Properties (Step3);
      begin
         Resolved := Resolve_Variable_Map (Vars);
         Vars := Resolved;
         Root_CSS := To_Unbounded_String
           (Resolve_Var_References (To_String (Root_Decls), Resolved));
         Build_Root_Metadata (To_String (Root_CSS), Metadata);
         return Resolve_Var_References (Step4, Resolved);
      end;
   end Preprocess_Custom_Properties;

   function Parse_Rules
     (CSS          : String;
      Out_Rules    : out Parsed_Rule_Vectors.Vector;
      Out_Vars     : out Variable_Vectors.Vector;
      Out_Metadata : out Stylesheet_Metadata;
      Out_Error    : out Unbounded_String) return Boolean
   is
      Clean : constant String :=
        Preprocess_Custom_Properties (CSS, Out_Vars, Out_Metadata);
      Pos : Natural := (if Clean'Length = 0 then 0 else Clean'First);
   begin
      Out_Rules.Clear;
      Out_Error := Null_Unbounded_String;

      if Clean'Length = 0 then
         return True;
      end if;

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

   function Ensure_Selector (Impl    : in out Stylesheet_Impl;
                             Working : in out Part_Style_Vectors.Vector;
                             Kind    : Selector_Kind;
                             Name    : String) return Positive is
      Key : constant String := Lower (Trimmed (Name));
      Idx : constant Natural := Find_Selector_Index (Impl, Kind, Key);
   begin
      if Idx > 0 then
         return Positive (Idx);
      end if;

      Impl.Selectors.Append (New_Item => Empty_Selector_Style);
      Working.Append (New_Item => Empty_Part_Styles);
      declare
         Sel : Selector_Style renames
           Impl.Selectors.Reference (Impl.Selectors.Last_Index).Element.all;
      begin
         Sel.Kind := Kind;
         Sel.Name := To_Unbounded_String (Key);
      end;
      return Positive (Impl.Selectors.Last_Index);
   end Ensure_Selector;

   procedure Build_Styles (Impl : in out Stylesheet_Impl;
                           Rules : Parsed_Rule_Vectors.Vector;
                           Success : out Boolean) is
      Saved : Selector_Style_Vectors.Vector;

      --  Each selector is interned once, when its rules are all in.
      --  Interning every intermediate instead would leave the store
      --  holding every partial rule set the build passed through, and
      --  the store does not evict.
      Working : Part_Style_Vectors.Vector;
   begin
      Selector_Style_Vectors.Move (Target => Saved, Source => Impl.Selectors);
      Success := True;

      Build_Loop :
      for R of Rules loop
         declare
            Idx : constant Positive :=
              Ensure_Selector (Impl, Working, R.Sel.Kind, To_String (R.Sel.Name));
            C   : Part_Style_Array renames Working.Reference (Idx).Element.all;
            W   : Widget_Style := C (R.Sel.Part).Style;
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
                     exit Build_Loop;
                  end if;

                  Add_Rule (W, (Selector => R.Sel.Selector, Style => R.Style, Priority => 0));
               else
                  W.Rules (Rule_Index).Style := Merge (W.Rules (Rule_Index).Style, R.Style);
               end if;
            else
               W.Base := Merge (W.Base, R.Style);
            end if;

            C (R.Sel.Part) := (Style => W, Enabled => True);
         end;
      end loop Build_Loop;

      if Success then
         for I in 1 .. Natural (Impl.Selectors.Length) loop
            Impl.Selectors.Reference (I).Element.all.Styles :=
              Adi.Widget.Intern
                (Working.Constant_Reference (I).Element.all);
         end loop;
         Saved.Clear;
      else
         Selector_Style_Vectors.Move (Target => Impl.Selectors, Source => Saved);
      end if;
   end Build_Styles;

   --  Apply one binding to its widget. Root_Merged_Styles folds in the
   --  :root styles when the target is the current root, so this is also
   --  how a widget sheds them once it is root no longer.
   procedure Apply_Binding (Impl : in out Stylesheet_Impl; B : Binding) is
   begin
      if not Adi.Widget.Is_Valid (B.Target) then
         return;
      end if;

      declare
         Idx : constant Natural :=
           Find_Selector_Index (Impl, B.Kind, To_String (B.Name));
         R   : constant Adi.Widget.Widget_Ref :=
           Adi.Widget.Borrow (B.Target);
      begin
         if Idx = 0 then
            Set_Part_Styles
              (R.Ptr.all,
               Root_Merged_Styles (Impl, B.Target, Empty_Part_Styles));
         else
            declare
               Sel : Selector_Style renames
                 Impl.Selectors.Reference (Positive (Idx)).Element.all;
            begin
               Set_Part_Styles
                 (R.Ptr.all,
                  Root_Merged_Styles
                    (Impl, B.Target, Adi.Widget.Expand (Sel.Styles)));
            end;
         end if;
      end;
   end Apply_Binding;

   --  Restyle one widget from what it is currently bound under.
   --  Root_Merged_Styles answers whether it is the root, so this both
   --  grants and withdraws the :root styles.
   procedure Restyle (Impl : in out Stylesheet_Impl;
                      H    : Adi.Widget.Widget_Handle)
   is
      use Binding_Maps;
      C : constant Cursor := Impl.Effective.Find (H);
   begin
      if not Adi.Widget.Is_Valid (H) then
         return;
      end if;

      if Has_Element (C) then
         Apply_Binding (Impl, Element (C));
         return;
      end if;

      --  Nothing bound: the widget has only what this stylesheet put on
      --  it, which is the :root styles and only while it is the root.
      --  Handing the role away takes them back rather than leaving the
      --  widget styled as a root it no longer is.
      declare
         R : constant Adi.Widget.Widget_Ref := Adi.Widget.Borrow (H);
      begin
         if Impl.Root_Target = H then
            Apply_Metadata_To_Widget (Impl.Metadata, R.Ptr.all);
         else
            Set_Part_Styles (R.Ptr.all, Empty_Part_Styles);
         end if;
      end;
   end Restyle;

   procedure Reapply_Bindings (Impl : in out Stylesheet_Impl) is
   begin
      if Adi.Widget.Is_Valid (Impl.Root_Target) then
         declare
            R : constant Adi.Widget.Widget_Ref :=
              Adi.Widget.Borrow (Impl.Root_Target);
         begin
            Apply_Metadata_To_Widget (Impl.Metadata, R.Ptr.all);
         end;
      end if;

      for B of Impl.Bindings loop
         if Adi.Widget.Is_Valid (B.Target) then
            declare
               Idx : constant Natural := Find_Selector_Index (Impl, B.Kind, To_String (B.Name));
               R   : constant Adi.Widget.Widget_Ref :=
                 Adi.Widget.Borrow (B.Target);
            begin
               if Idx = 0 then
                  Set_Part_Styles
                    (R.Ptr.all,
                     Root_Merged_Styles (Impl, B.Target, Empty_Part_Styles));
               else
                  declare
                     Sel : Selector_Style renames
                       Impl.Selectors.Reference (Positive (Idx)).Element.all;
                  begin
                     Set_Part_Styles
                       (R.Ptr.all,
                        Root_Merged_Styles
                          (Impl, B.Target, Adi.Widget.Expand (Sel.Styles)));
                  end;
               end if;
            end;
         end if;
      end loop;
   end Reapply_Bindings;

   procedure Load_String (Sheet       : in out Stylesheet;
                          CSS_Content : String;
                          Success     : out Boolean) is
      Rules    : Parsed_Rule_Vectors.Vector;
      Vars     : Variable_Vectors.Vector;
      Metadata : Stylesheet_Metadata;
      Err      : Unbounded_String;
   begin
      Ensure_Impl (Sheet);

      if not Parse_Rules (CSS_Content, Rules, Vars, Metadata, Err) then
         Impl_Of (Sheet).Last_Error := Err;
         Success := False;
         return;
      end if;

      Build_Styles (Impl_Of (Sheet).all, Rules, Success);
      if Success then
         Impl_Of (Sheet).Metadata := Metadata;
         Impl_Of (Sheet).Variables := Vars;
         Impl_Of (Sheet).Last_Error := Null_Unbounded_String;
         Reapply_Bindings (Impl_Of (Sheet).all);
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
         Impl_Of (Sheet).Last_Error := To_Unbounded_String ("CSS file not found: " & Path);
         Success := False;
         return;
      end if;

      Impl_Of (Sheet).Source_Path := To_Unbounded_String (Path);

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
         Impl_Of (Sheet).Last_Modified := Ada.Directories.Modification_Time (Path);
      end if;
   exception
      when E : others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Impl_Of (Sheet).Last_Error := To_Unbounded_String
           ("Failed to load CSS file: " & Ada.Exceptions.Exception_Message (E));
         Success := False;
   end Load_File;

   procedure Reload_If_Changed (Sheet    : in out Stylesheet;
                                Reloaded : out Boolean;
                                Success  : out Boolean) is
      Path : constant String := To_String (Impl_Of (Sheet).Source_Path);
      Mod_Time : Ada.Calendar.Time;
   begin
      Ensure_Impl (Sheet);
      Reloaded := False;
      Success := True;

      if Path = "" then
         return;
      end if;

      if not Ada.Directories.Exists (Path) then
         Impl_Of (Sheet).Last_Error := To_Unbounded_String ("CSS file not found: " & Path);
         Success := False;
         return;
      end if;

      Mod_Time := Ada.Directories.Modification_Time (Path);
      if Mod_Time > Impl_Of (Sheet).Last_Modified then
         Load_File (Sheet, Path, Success);
         Reloaded := Success;
      end if;
   end Reload_If_Changed;

   function Has (Sheet : Stylesheet;
                 Kind : Selector_Kind;
                 Name : String) return Boolean is
   begin
      if Impl_Of (Sheet) = null then
         return False;
      end if;
      return Find_Selector_Index (Impl_Of (Sheet).all, Kind, Name) > 0;
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
      if Impl_Of (Sheet) = null then
         return Empty_Part_Styles;
      end if;

      Idx := Find_Selector_Index (Impl_Of (Sheet).all, Kind, Name);
      if Idx = 0 then
         return Empty_Part_Styles;
      end if;

      return Adi.Widget.Expand (Impl_Of (Sheet).Selectors (Positive (Idx)).Styles);
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

   function Get_Metadata (Sheet : Stylesheet) return Stylesheet_Metadata is
   begin
      if Impl_Of (Sheet) = null then
         return (others => <>);
      end if;
      return Impl_Of (Sheet).Metadata;
   end Get_Metadata;

   function Has_Custom_Property (Sheet : Stylesheet; Name : String) return Boolean is
   begin
      if Impl_Of (Sheet) = null then
         return False;
      end if;
      return Has_Variable (Impl_Of (Sheet).Variables, Trimmed (Name));
   end Has_Custom_Property;

   function Get_Custom_Property (Sheet : Stylesheet; Name : String) return String is
   begin
      if Impl_Of (Sheet) = null then
         return "";
      end if;
      return Var_Lookup (Impl_Of (Sheet).Variables, Trimmed (Name));
   end Get_Custom_Property;

   procedure Apply_Root_Metadata
     (Sheet : Stylesheet;
      W     : in out Adi.Widget.Widget'Class) is
   begin
      if Impl_Of (Sheet) = null then
         return;
      end if;
      Apply_Metadata_To_Widget (Impl_Of (Sheet).Metadata, W);
   end Apply_Root_Metadata;

   procedure Bind_Root_Metadata
     (Sheet : in out Stylesheet;
      W     : access Adi.Widget.Widget'Class) is
   begin
      Ensure_Impl (Sheet);
      if W = null then
         return;
      end if;

      declare
         Prev     : constant Adi.Widget.Widget_Handle :=
           Impl_Of (Sheet).Root_Target;
         Next     : constant Adi.Widget.Widget_Handle :=
           Adi.Widget.Get_Handle (W.all);
      begin
         Impl_Of (Sheet).Root_Target := Next;

         --  Only the root target has :root merged into its styles, so
         --  handing the role over changes the widget losing it and the
         --  one taking it, and no other binding. Each is restyled from
         --  its own binding, so neither loses its selectors.
         if Prev /= Next then
            Restyle (Impl_Of (Sheet).all, Prev);
         end if;
         Restyle (Impl_Of (Sheet).all, Next);
      end;
   end Bind_Root_Metadata;

   procedure Bind_Root_Metadata
     (Sheet : in out Stylesheet;
      W     : Widget_Handle) is
   begin
      if Adi.Widget.Is_Valid (W) then
         declare
            R : constant Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
         begin
            Bind_Root_Metadata (Sheet, R.Ptr);
         end;
      end if;
   end Bind_Root_Metadata;

   procedure Apply (Sheet : Stylesheet;
                    Kind  : Selector_Kind;
                    Name  : String;
                    W     : in out Adi.Widget.Widget'Class) is
      Idx : Natural := 0;
   begin
      if Impl_Of (Sheet) /= null then
         Idx := Find_Selector_Index (Impl_Of (Sheet).all, Kind, Name);
      end if;

      if Idx = 0 then
         Set_Part_Styles
           (W,
            Root_Merged_Styles (Impl_Of (Sheet).all, Adi.Widget.Get_Handle (W), Empty_Part_Styles));
      else
         declare
            Sel : Selector_Style renames
              Impl_Of (Sheet).Selectors.Constant_Reference (Positive (Idx)).Element.all;
         begin
            Set_Part_Styles
              (W,
               Root_Merged_Styles (Impl_Of (Sheet).all, Adi.Widget.Get_Handle (W),
                                   Adi.Widget.Expand (Sel.Styles)));
         end;
      end if;
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

      for I in 1 .. Natural (Impl_Of (Sheet).Bindings.Length) loop
         if Impl_Of (Sheet).Bindings (I).Target = Adi.Widget.Get_Handle (W.all) then
            Impl_Of (Sheet).Bindings.Replace_Element
              (I, (Kind   => Kind,
                   Name   => To_Unbounded_String (Key),
                   Target => Adi.Widget.Get_Handle (W.all)));
            Impl_Of (Sheet).Effective.Include
              (Adi.Widget.Get_Handle (W.all), Impl_Of (Sheet).Bindings (I));
            Apply (Sheet, Kind, Key, W.all);
            return;
         end if;
      end loop;

      Impl_Of (Sheet).Bindings.Append
        (New_Item => Binding'
           (Kind   => Kind,
            Name   => To_Unbounded_String (Key),
            Target => Adi.Widget.Get_Handle (W.all)));
      Impl_Of (Sheet).Effective.Include
        (Adi.Widget.Get_Handle (W.all), Impl_Of (Sheet).Bindings.Last_Element);
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

   procedure Bind (Sheet : in out Stylesheet;
                   Kind  : Selector_Kind;
                   Name  : String;
                   W     : Widget_Handle) is
   begin
      if Adi.Widget.Is_Valid (W) then
         declare
            R : constant Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
         begin
            Bind (Sheet, Kind, Name, R.Ptr);
         end;
      end if;
   end Bind;

   procedure Bind_Class (Sheet      : in out Stylesheet;
                         Class_Name : String;
                         W          : Widget_Handle) is
   begin
      Bind (Sheet, Class_Selector, Class_Name, W);
   end Bind_Class;

   procedure Bind_Id (Sheet   : in out Stylesheet;
                      Id_Name : String;
                      W       : Widget_Handle) is
   begin
      Bind (Sheet, Id_Selector, Id_Name, W);
   end Bind_Id;

   procedure Bind_Tag (Sheet    : in out Stylesheet;
                       Tag_Name : String;
                       W        : Widget_Handle) is
   begin
      Bind (Sheet, Tag_Selector, Tag_Name, W);
   end Bind_Tag;

   function Get_Last_Error (Sheet : Stylesheet) return String is
   begin
      if Impl_Of (Sheet) = null then
         return "";
      end if;
      return To_String (Impl_Of (Sheet).Last_Error);
   end Get_Last_Error;

   function Get_Source_Path (Sheet : Stylesheet) return String is
   begin
      if Impl_Of (Sheet) = null then
         return "";
      end if;
      return To_String (Impl_Of (Sheet).Source_Path);
   end Get_Source_Path;

begin
   Adi.Widget.Window_Bridge.Install_Destroy_Notice
     (On_Widget_Destroyed'Access);
end Adi.CSS_Parser;
