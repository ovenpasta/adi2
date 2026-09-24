--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Hashed_Maps;

with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Numerics;
with Ada.Containers;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Log;
with Adi.Style_Merge;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Window_Bridge;
pragma Elaborate_All (Adi.Widget.Window_Bridge);
with Adi.Widget_Properties;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package body Adi.CSS_Parser is

   package Fix renames Ada.Strings.Fixed;
   package Char renames Ada.Characters.Handling;

   use type Ada.Calendar.Time;
   use type Ada.Containers.Count_Type;

   type Selector_Style is record
      Kind   : Selector_Kind := Class_Selector;
      Name   : Unbounded_String;
      Styles : Adi.Widget.Part_Style_Array := Adi.Widget.Empty_Part_Styles;
   end record;

   Empty_Selector_Style : constant Selector_Style :=
     (Kind   => Class_Selector,
      Name   => Null_Unbounded_String,
      Styles => Adi.Widget.Empty_Part_Styles);

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

   --  The selector name lives in the text store, so a binding holds an
   --  id and no controlled component.
   type Binding is record
      Kind   : Selector_Kind := Class_Selector;
      Name   : CSS_Text_Id := No_CSS_Text;
      Target : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
   end record;

   --  Probed_Bindings counts every stored key the map compares against,
   --  over every bind, every prune and every lookup, on every source or
   --  sheet alive in the process. A bucket's worth per operation while
   --  the lookup is a hash; every binding held were it ever a scan.
   function Same_Target (A, B : Adi.Widget.Widget_Handle) return Boolean is
   begin
      Probed_Bindings := Probed_Bindings + 1;
      return Adi.Widget."=" (A, B);
   end Same_Target;

   package Binding_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Adi.Widget.Widget_Handle,
      Element_Type    => Binding,
      Hash            => Adi.Widget.Hash,
      Equivalent_Keys => Same_Target);

   --  A walk over the bindings takes a copy first. Applying one styles
   --  a widget, and anything that destroys a widget re-enters
   --  Prune_Widget, which Excludes from the map and frees the very node
   --  a cursor would be standing in -- leaving the walk to read it.
   --  A cursor loop takes no tampering lock, so nothing reports that.
   --  One vector, capacity reserved once, and its own finalization
   --  releases it however the walk ends.
   package Binding_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Binding);

   function Snapshot (M : Binding_Maps.Map) return Binding_Vectors.Vector is
   begin
      return Result : Binding_Vectors.Vector do
         Result.Reserve_Capacity (M.Length);
         for B of M loop
            Result.Append (B);
         end loop;
      end return;
   end Snapshot;

   type Variable_Entry is record
      Name  : Unbounded_String;
      Value : Unbounded_String;
   end record;

   package Variable_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Variable_Entry);

   --  Where a selector sits in Selectors, by its lowered and trimmed
   --  name. One map per kind, so a lookup hashes the name as given
   --  rather than a name the kind was pasted onto.
   package Selector_Index_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Positive,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   type Selector_Index_Array is
     array (Selector_Kind) of Selector_Index_Maps.Map;

   type Stylesheet_Impl is new Sheet_Impl_Base with record
      Selectors      : Selector_Style_Vectors.Vector;
      Selector_Index : Selector_Index_Array;
      Root_Target    : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
      --  The binding in force for each widget: what Bind writes, what
      --  a root handover restyles from, and what a reload replays.
      Effective      : Binding_Maps.Map;
      Metadata       : Stylesheet_Metadata := (others => <>);
      Variables      : Variable_Vectors.Vector;
      Source_Path    : Unbounded_String;
      Last_Modified  : Ada.Calendar.Time :=
        Ada.Calendar.Time_Of (1901, 1, 1, 0.0);
      Last_Error     : Unbounded_String;
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
      Style : Rule_Slots;
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

   --  What a Rule_Sheet holds: the rules each selector's main part
   --  folds to, indexed by name exactly as a Stylesheet indexes its
   --  selectors.
   package Rules_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Rule_Slots);

   --  A rule set naming nothing, which is what a selector entry opens
   --  on.
   Empty_Slots : constant Rule_Slots := Slots_Of (Empty_Style);

   type Rule_Sheet_Data is record
      Rules         : Rules_Vectors.Vector;
      Index         : Selector_Index_Array;
      Has_Root_Size : Boolean := False;
      Root_Size     : Length_Value := Default_Font_Size;
      Last_Error    : Unbounded_String;
   end record;

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

   function Selector_Count (Sheet : Stylesheet) return Natural is
     (if Impl_Of (Sheet) = null then 0
      else Natural (Impl_Of (Sheet).Selectors.Length));

   --  As every other read of a sheet does, these answer for a sheet that
   --  holds nothing rather than reaching through a stale handle.
   function Selector_Kind_At (Sheet : Stylesheet;
                              Index : Positive) return Selector_Kind is
     (if Impl_Of (Sheet) = null then Tag_Selector
      else Impl_Of (Sheet).Selectors (Index).Kind);

   function Selector_Name_At (Sheet : Stylesheet;
                              Index : Positive) return String is
     (if Impl_Of (Sheet) = null then ""
      else To_String (Impl_Of (Sheet).Selectors (Index).Name));

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

   --  The sheet's side of the fold: which metadata it carries and which
   --  widget it holds as its root. Adi.Style_Merge carries the fold
   --  itself, which Adi.CSS_Source answers a binding with too.
   function Root_Merged_Styles
     (Impl   : Stylesheet_Impl;
      Target : Adi.Widget.Widget_Handle;
      Styles : Part_Style_Array) return Part_Style_Array
   is (Adi.Style_Merge.Root_Merged_Styles
         (Has_Root_Style => Impl.Metadata.Has_Root_Style,
          Root_Styles    => Impl.Metadata.Root_Styles,
          Root_Target    => Impl.Root_Target,
          Target         => Target,
          Styles         => Styles));

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
      Next   : Positive;

      function Is_Name_Char (C : Character) return Boolean is
        (C in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_' | '-'
         or else Character'Pos (C) >= 128);
   begin
      while I <= Content'Last loop
         Next := I + 1;
         if Content (I) = '/'
           and then Next <= Content'Last
           and then Content (Next) = '*'
         then
            Next := I + 2;
            while Next < Content'Last
              and then Content (Next .. Next + 1) /= "*/"
            loop
               Next := Next + 1;
            end loop;
            I := Next + 2;
         else
            if Content (I) in '"' | ''' then
               while Next <= Content'Last
                 and then Content (Next) not in
                            Content (I) | ASCII.LF | ASCII.CR | ASCII.FF
               loop
                  if Content (Next) /= '\' then
                     Next := Next + 1;
                  elsif Next + 2 <= Content'Last
                    and then Content (Next + 1 .. Next + 2)
                               = ASCII.CR & ASCII.LF
                  then
                     Next := Next + 3;
                  else
                     Next := Next + 2;
                  end if;
               end loop;
               if Next <= Content'Last and then Content (Next) = Content (I)
               then
                  Next := Next + 1;
               end if;
            elsif I + 3 <= Content'Last
              and then Lower (Content (I .. I + 3)) = "url("
              and then (I = Content'First
                        or else not Is_Name_Char (Content (I - 1)))
            then
               Next := I + 4;
               while Next <= Content'Last
                 and then Is_Whitespace (Content (Next))
               loop
                  Next := Next + 1;
               end loop;
               if Next <= Content'Last
                 and then Content (Next) not in '"' | ''' | ')'
               then
                  while Next <= Content'Last and then Content (Next) /= ')'
                  loop
                     Next := Next + (if Content (Next) = '\' then 2 else 1);
                  end loop;
                  Next := Next + 1;
               end if;
            elsif Content (I) = '\' then
               Next := I + 2;
            end if;
            Next := Positive'Min (Next, Content'Last + 1);
            Append (Result, Content (I .. Next - 1));
            I := Next;
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

   --  Parse a "grid-template-columns" or "grid-template-rows" value.
   --  Supports: plain integer N (→ N equal fr tracks), space-separated
   --  size tokens, repeat(N, size), and mixed "repeat(N, size) size...".
   --
   --  Count is how many tracks the value names, and stands whether or
   --  not their sizes fit: past Max_Grid_Tracks there is nowhere to put
   --  them, so List comes back empty and the count travels alone. That
   --  degradation is for a list this grammar reads. A token outside it
   --  returns False, which is the declaration the caller drops.
   function Parse_Grid_Tracks
     (Input : String;
      List  : out Grid_Track_List;
      Count : out Natural) return Boolean
   is
      V       : constant String  := Lower (Trimmed (Input));
      Num     : Float;
      N_Plain : Natural;

      --  Times comes from repeat(), which names as many tracks as it
      --  likes: the sizes stop at the array's end and the count runs
      --  on, saturating rather than raising on a pair of huge repeats.
      procedure Append (Spec : Grid_Track_Spec; Times : Positive := 1) is
         Room : constant Natural :=
           (if Count >= Max_Grid_Tracks then 0
            else Max_Grid_Tracks - Count);
      begin
         for K in 1 .. Natural'Min (Times, Room) loop
            List.Tracks (Count + K) := Spec;
         end loop;
         Count := (if Times > Natural'Last - Count then Natural'Last
                   else Count + Times);
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
         Append (Size_Spec, Rep_Count);
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
         Append (Spec);
         return True;
      end Process_Token;

      I     : Natural;
      Start : Natural;
      Depth : Natural;

   begin
      List := Default_Grid_Track_List;
      Count := 0;

      if Parse_Natural (V, N_Plain) and then N_Plain > 0 then
         Append ((Kind => Track_Fr, Value => 1.0), N_Plain);
      else
         I := V'First;
         while I <= V'Last loop
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
                     I := I + 1;
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
      end if;

      if Count = 0 then
         return False;
      end if;

      if Count <= Max_Grid_Tracks then
         List.Count := Count;
      else
         --  Over the cap the sizes are a partial list, which is worse
         --  than none: the count stands and the tracks are given up.
         List := Default_Grid_Track_List;
      end if;
      return True;
   end Parse_Grid_Tracks;

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

   --  <family-name>#. A quoted name is a string; an unquoted one is a
   --  sequence of CSS identifiers, so a word opening with a digit wants
   --  quoting -- CSS Fonts spells that example "Hawaii 5-0". An
   --  identifier opens with a letter, an underscore, a hyphen, or a
   --  code point past ASCII, which is what -apple-system and a name
   --  written in its own script both need. tools/css_to_ada.py holds
   --  this same grammar, or a declaration one pipeline kept would be
   --  one the other dropped.
   function Is_Font_Family_List (Input : String) return Boolean is

      --  CSS counts a form feed as white space, where the parser's own
      --  Is_Whitespace stops at the four this file reads elsewhere.
      function Is_CSS_Space (C : Character) return Boolean is
        (C in ' ' | ASCII.HT | ASCII.LF | ASCII.CR | ASCII.FF);

      function Ident_Start (C : Character) return Boolean is
        (C in 'a' .. 'z' | 'A' .. 'Z' | '_'
         or else Character'Pos (C) >= 128);

      function Ident_Char (C : Character) return Boolean is
        (Ident_Start (C) or else C in '0' .. '9' | '-');

      --  A leading hyphen opens an identifier when a second one or an
      --  opening character follows it.
      function Is_Ident (T : String) return Boolean is
        (T'Length > 0
         and then (Ident_Start (T (T'First))
                   or else (T (T'First) = '-'
                            and then T'Length > 1
                            and then (Ident_Start (T (T'First + 1))
                                      or else T (T'First + 1) = '-')))
         and then (for all C of T => Ident_Char (C)));

      function CSS_Trimmed (S : String) return String is
         First : Positive := S'First;
         Last  : Natural  := S'Last;
      begin
         while First <= Last and then Is_CSS_Space (S (First)) loop
            First := First + 1;
         end loop;
         while Last >= First and then Is_CSS_Space (S (Last)) loop
            Last := Last - 1;
         end loop;
         return (if First > Last then "" else S (First .. Last));
      end CSS_Trimmed;

      function Name_Is_Read (Name : String) return Boolean is
         N : constant String := CSS_Trimmed (Name);
      begin
         if N'Length = 0 then
            return False;
         end if;

         if N (N'First) in '"' | ''' then
            --  The quote stands at the ends and nowhere between them.
            return N'Length >= 2
              and then N (N'Last) = N (N'First)
              and then (for all I in N'First + 1 .. N'Last - 1 =>
                          N (I) /= N (N'First));
         end if;

         declare
            First : Natural := N'First;
         begin
            for I in N'Range loop
               if Is_CSS_Space (N (I)) then
                  if I > First
                    and then not Is_Ident (N (First .. I - 1))
                  then
                     return False;
                  end if;
                  First := I + 1;
               end if;
            end loop;
            return First <= N'Last and then Is_Ident (N (First .. N'Last));
         end;
      end Name_Is_Read;

      Quote    : Character := ' ';
      In_Quote : Boolean := False;
      First    : Natural := Input'First;
   begin
      for I in Input'Range loop
         if In_Quote then
            if Input (I) = Quote then
               In_Quote := False;
            end if;
         elsif Input (I) in '"' | ''' then
            In_Quote := True;
            Quote := Input (I);
         elsif Input (I) = ',' then
            if not Name_Is_Read (Input (First .. I - 1)) then
               return False;
            end if;
            First := I + 1;
         end if;
      end loop;

      return Name_Is_Read (Input (First .. Input'Last));
   end Is_Font_Family_List;

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
            else
               --  One token the grammar cannot read costs the
               --  declaration, which is where tools/css_to_ada.py stops.
               return False;
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

      if LV'Length <= Prefix'Length + 1 then
         return False;
      end if;
      if LV (LV'First .. LV'First + Prefix'Length - 1) /= Prefix then
         return False;
      end if;
      if V (V'Last) /= ')' then
         return False;
      end if;

      Split_Comma_Tokens (V (V'First + Prefix'Length .. V'Last - 1), Tokens);

      if Natural (Tokens.Length) < 2 then
         return False;
      end if;

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

      if Natural (Tokens.Length) - (Start - 1) < 2 then
         return False;
      end if;

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
      Out_Color  : out Color_Value;
      All_Read   : out Boolean)
   is
      Tokens : Token_Vectors.Vector;
      L      : Parsed_Length;
      S      : Border_Style_Kind;
      Col    : Color_Value;
   begin
      Has_Width := False;
      Has_Style := False;
      Has_Color := False;
      All_Read := True;
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
            else
               --  CSS drops a declaration over one token it cannot
               --  read, and tools/css_to_ada.py stops at the first.
               All_Read := False;
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
         --  A colour outside the two function forms is one token,
         --  and CSS puts it before or after the lengths. The others are
         --  the length list. tools/css_to_ada.py reads a named or hex
         --  colour wherever it stands, so the runtime reads one too.
         Col := RGBA (0, 0, 0, 0.25);
         declare
            Tokens : Token_Vectors.Vector;
            Found  : Color_Value;
            Where  : Natural := 0;
         begin
            Split_Whitespace_Tokens (V, Tokens);
            for J in Tokens.First_Index .. Tokens.Last_Index loop
               if Parse_Color (To_String (Tokens (J)), Found) then
                  Col := Found;
                  Where := J;
                  exit;
               end if;
            end loop;
            for J in Tokens.First_Index .. Tokens.Last_Index loop
               if J /= Where then
                  if Length (Len_Text) > 0 then
                     Append (Len_Text, " ");
                  end if;
                  Append (Len_Text, To_String (Tokens (J)));
               end if;
            end loop;
         end;
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

   --  [severity] and [severity="critical"], taken off the selector text
   --  ahead of the colon split, the way :not() is handled above. A name
   --  the application never declared is reported rather than resolved to
   --  a selector that matches nothing: tools/css_to_ada.py answers the
   --  same question as a compile error, and the two pipelines agree.
   function Take_Property_Conditions
     (Input      : String;
      Remainder  : out Unbounded_String;
      Conditions : out Adi.Widget_Properties.Property_Conditions;
      Out_Error  : out Unbounded_String) return Boolean
   is
      use Adi.Widget_Properties;
      I : Positive := Input'First;

      function Unquoted (Text : String) return String is
         V : constant String := Trimmed (Text);
      begin
         if V'Length >= 2
           and then (V (V'First) = '"' or else V (V'First) = ''')
           and then V (V'Last) = V (V'First)
         then
            return V (V'First + 1 .. V'Last - 1);
         end if;
         return V;
      end Unquoted;

      --  Both halves become an Ada identifier in the generated sheet, so
      --  both are held to what one can be spelled from. The generator
      --  holds the same shape, or a selector one pipeline accepted would
      --  be refused by the other.
      function Is_Name (Text : String) return Boolean is
        (Text'Length > 0
         and then Text (Text'First) in 'a' .. 'z' | 'A' .. 'Z'
         and then (for all C of Text =>
                     C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_'));

      function Is_Value (Text : String) return Boolean is
        (Text'Length > 0
         and then Text (Text'First) in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9'
         and then (for all C of Text =>
                     C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_'));

      function Take_One (Body_Text : String; Negated : Boolean)
        return Boolean
      is
         Eq : constant Natural := Fix.Index (Body_Text, "=");
      begin
         if Eq = 0 then
            declare
               Name : constant String := Trimmed (Body_Text);
               P    : Property;
            begin
               if not Is_Name (Name) then
                  Out_Error := To_Unbounded_String
                    ("'" & Name & "' is no widget property name");
                  return False;
               end if;

               P := Find_Property (Name);
               if P = No_Property then
                  Out_Error := To_Unbounded_String
                    ("Unknown widget property '" & Name & "'");
                  return False;
               end if;
               Conditions := Both
                 (Conditions,
                  (if Negated then Conditions_Excluding (P)
                   else Conditions_On (P)));
               return True;
            end;
         end if;

         --  ~=, |=, ^=, $=, *= match parts of a value, and < and >
         --  order it. The grammar here is equality and existence.
         if Eq > Body_Text'First
           and then Body_Text (Eq - 1) in '~' | '|' | '^' | '$' | '*'
                                        | '<' | '>' | '!'
         then
            Out_Error := To_Unbounded_String
              ("Unsupported attribute operator in '[" & Body_Text & "]'");
            return False;
         end if;

         declare
            Name : constant String := Trimmed (Body_Text (Body_Text'First .. Eq - 1));
            Text : constant String := Unquoted (Body_Text (Eq + 1 .. Body_Text'Last));
            P    : Property;
            V    : Property_Value;
         begin
            if not Is_Name (Name) then
               Out_Error := To_Unbounded_String
                 ("'" & Name & "' is no widget property name");
               return False;
            end if;

            if not Is_Value (Text) then
               Out_Error := To_Unbounded_String
                 ("'" & Text & "' is no widget property value");
               return False;
            end if;

            P := Find_Property (Name);
            if P = No_Property then
               Out_Error := To_Unbounded_String
                 ("Unknown widget property '" & Name & "'");
               return False;
            end if;

            V := Find_Value (P, Text);
            if V = No_Value then
               Out_Error := To_Unbounded_String
                 ("Unknown value '" & Text & "' for widget property '"
                  & Name & "'");
               return False;
            end if;

            Conditions := Both
              (Conditions,
               (if Negated then Conditions_Excluding (V)
                else Conditions_On (V)));
            return True;
         end;
      end Take_One;

      --  The end of a bracket group starting at Open, or 0 when it has
      --  none. A quoted ']' is part of the value rather than the close.
      function Bracket_End (Open : Positive) return Natural is
         J     : Natural := Open + 1;
         Quote : Character := ' ';
      begin
         while J <= Input'Last loop
            if Quote /= ' ' then
               if Input (J) = Quote then
                  Quote := ' ';
               end if;
            elsif Input (J) = '"' or else Input (J) = ''' then
               Quote := Input (J);
            elsif Input (J) = ']' then
               return J;
            end if;
            J := J + 1;
         end loop;
         return 0;
      end Bracket_End;

      --  Whether a :not( opens at I over a bracket group, which is the
      --  only shape a property condition takes inside it. Any other
      --  :not() is left for Parse_Pseudo_List.
      function Negation_At (I : Positive) return Boolean is
         J : Natural := I + 5;
      begin
         if I + 4 > Input'Last
           or else Lower (Input (I .. I + 4)) /= ":not("
         then
            return False;
         end if;

         while J <= Input'Last and then Input (J) = ' ' loop
            J := J + 1;
         end loop;
         return J <= Input'Last and then Input (J) = '[';
      end Negation_At;

   begin
      Remainder := Null_Unbounded_String;
      Conditions := No_Conditions;
      Out_Error := Null_Unbounded_String;

      while I <= Input'Last loop
         if Input (I) = '[' or else Negation_At (I) then
            declare
               Negated : constant Boolean := Input (I) /= '[';
               Open    : constant Positive :=
                 (if Negated
                  then Fix.Index (Input (I .. Input'Last), "[")
                  else I);
               Close   : constant Natural := Bracket_End (Open);
               Stop    : Natural := Close;
            begin
               if Close = 0 then
                  Out_Error := To_Unbounded_String
                    ("Unclosed attribute selector in '" & Input & "'");
                  return False;
               end if;

               if Negated then
                  Stop := Fix.Index (Input (Close .. Input'Last), ")");
                  if Stop = 0 then
                     Out_Error := To_Unbounded_String
                       ("Unclosed :not() in '" & Input & "'");
                     return False;
                  end if;
               end if;

               if Close = Open + 1
                 or else not Take_One (Input (Open + 1 .. Close - 1), Negated)
               then
                  if Length (Out_Error) = 0 then
                     Out_Error := To_Unbounded_String
                       ("Empty attribute selector in '" & Input & "'");
                  end if;
                  return False;
               end if;

               I := Stop + 1;
            end;
         else
            Append (Remainder, Input (I));
            I := I + 1;
         end if;
      end loop;

      return True;
   end Take_Property_Conditions;

   function Parse_Selector (Input     : String;
                            Out_Sel   : out Parsed_Selector;
                            Out_Error : out Unbounded_String) return Boolean is
      Conditions : Adi.Widget_Properties.Property_Conditions;
      Stripped   : Unbounded_String;
      Raw : Unbounded_String := To_Unbounded_String (Trimmed (Input));
      Base : Unbounded_String := Null_Unbounded_String;
      Part : Unbounded_String := Null_Unbounded_String;
      Widget_Pseudo : Unbounded_String := Null_Unbounded_String;
      Part_Pseudo : Unbounded_String := Null_Unbounded_String;
      Sep : Natural;
      Colon : Natural;
      Part_Scope : Boolean := False;
      use type Adi.Widget_Properties.Property_Conditions;

      --  A selector passed over costs its whole block, so it is
      --  reported the way an unsupported property is. Out_Error stays
      --  empty: it is for a selector that refuses the sheet, which is
      --  what a property condition the application never declared does.
      function Skip (Reason : String) return Boolean is
      begin
         Unsupported_Selectors := Unsupported_Selectors + 1;
         Adi.Log.Warning
           ("css: selector '" & Trimmed (Input) & "' " & Reason
            & "; the rule is dropped");
         return False;
      end Skip;
   begin
      Out_Sel := (others => <>);
      Out_Error := Null_Unbounded_String;

      if not Take_Property_Conditions
               (To_String (Raw), Stripped, Conditions, Out_Error)
      then
         return False;
      end if;

      Raw := To_Unbounded_String (Trimmed (To_String (Stripped)));
      Out_Sel.Selector.Properties := Conditions;
      --  A property condition makes the block a state rule, the way a
      --  pseudo-class does: it is one selection among the rules a
      --  widget carries rather than the style it starts from.
      Out_Sel.Has_State :=
        Conditions /= Adi.Widget_Properties.No_Conditions;

      if Length (Raw) = 0 then
         return Skip
           (if Conditions /= Adi.Widget_Properties.No_Conditions
            then "wants a name before its property condition"
            else "is empty");
      end if;

      declare
         R : constant String := To_String (Raw);
      begin
         if R (R'First) = '.' then
            if R'Length = 1 then
               return Skip ("wants a name after '.'");
            end if;
            Out_Sel.Kind := Class_Selector;
            Raw := To_Unbounded_String (R (R'First + 1 .. R'Last));
         elsif R (R'First) = '#' then
            if R'Length = 1 then
               return Skip ("wants a name after '#'");
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
         return Skip ("wants a name before '::'");
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
         return Skip ("wants a name before ':'");
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
            return Skip
              ("carries an unsupported part '"
               & Lower (Trimmed (To_String (Part))) & "'");
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

   --  Which of a property's values a longhand names: the edge or the
   --  corner at that literal's position, as Slot_Part numbers them.
   function Edge_Part (E : Edge) return Slot_Part is
     (Slot_Part (Edge'Pos (E)));

   function Corner_Part (K : Corner) return Slot_Part is
     (Slot_Part (Corner'Pos (K)));

   -------------------------------------------------
   --  The CSS-wide keywords
   -------------------------------------------------

   --  The colour vocabulary names `inherit` -- Default_Color is that
   --  entry -- so a declaration whose grammar reads a colour reads the
   --  keyword as one, and the CSS-wide arm answers for the rest.
   --  tools/css_to_ada.py draws the line at the same declarations,
   --  through the validators that call parse_color.
   Color_Reading : constant array (Decl_Name) of Boolean :=
     [D_Color | D_Background | D_Background_Color | D_Border_Color
      | D_Border_Top_Color | D_Border_Right_Color | D_Border_Bottom_Color
      | D_Border_Left_Color | D_Outline_Color
      | D_Border | D_Border_Top | D_Border_Right | D_Border_Bottom
      | D_Border_Left | D_Outline => True,
      others => False];

   --  One value a declaration name reaches: the property, and the part
   --  where the name is a longhand over a property whose values cascade
   --  separately.
   type Wide_Step is record
      Prop  : CSS_Property := CSS_Property'First;
      Part  : Slot_Part    := First_Part;
      Whole : Boolean      := True;
   end record;

   --  The widest are three: the border and outline shorthands, a
   --  border side, and list-style.
   Max_Wide_Steps : constant := 3;

   type Wide_Step_List is array (1 .. Max_Wide_Steps) of Wide_Step;

   type Wide_Target is record
      Count : Natural := 0;
      Steps : Wide_Step_List;
   end record;

   function Whole_Of (P : CSS_Property) return Wide_Target is
     ((Count => 1, Steps => [1 => (P, First_Part, True), others => <>]));

   function Whole_Of (P1, P2 : CSS_Property) return Wide_Target is
     ((Count => 2,
       Steps => [1 => (P1, First_Part, True),
                 2 => (P2, First_Part, True),
                 others => <>]));

   function Whole_Of (P1, P2, P3 : CSS_Property) return Wide_Target is
     ((Count => 3,
       Steps => [1 => (P1, First_Part, True),
                 2 => (P2, First_Part, True),
                 3 => (P3, First_Part, True)]));

   function Part_Of (P : CSS_Property; Part : Slot_Part) return Wide_Target is
     ((Count => 1, Steps => [1 => (P, Part, False), others => <>]));

   --  The three border groups at one edge, which is what a side
   --  shorthand covers.
   function Side_Of (E : Edge) return Wide_Target is
     ((Count => 3,
       Steps => [1 => (Prop_Border_Width, Edge_Part (E), False),
                 2 => (Prop_Border_Color, Edge_Part (E), False),
                 3 => (Prop_Border_Style, Edge_Part (E), False)]));

   --  What a declaration name reaches, which is what a CSS-wide keyword
   --  needs and the value dispatch below spells out a value at a time.
   --  A shorthand names every property it fills, whatever a particular
   --  value of it happens to mention. parser_slots_test holds this
   --  against the keys it reads off the CSS vocabulary.
   function Wide_Target_Of (K : Decl_Name) return Wide_Target is
     (case K is
        when Decl_Unknown => (Count => 0, Steps => [others => <>]),

        when D_Align_Content   => Whole_Of (Prop_Align_Content),
        when D_Align_Items     => Whole_Of (Prop_Align_Items),
        when D_Align_Self      => Whole_Of (Prop_Align_Self),
        when D_Background | D_Background_Color =>
           Whole_Of (Prop_Background_Color),
        when D_Background_Image => Whole_Of (Prop_Background_Image),

        when D_Border =>
           Whole_Of (Prop_Border_Width, Prop_Border_Color,
                     Prop_Border_Style),
        when D_Border_Top    => Side_Of (Top),
        when D_Border_Right  => Side_Of (Right),
        when D_Border_Bottom => Side_Of (Bottom),
        when D_Border_Left   => Side_Of (Left),

        when D_Border_Color  => Whole_Of (Prop_Border_Color),
        when D_Border_Top_Color =>
           Part_Of (Prop_Border_Color, Edge_Part (Top)),
        when D_Border_Right_Color =>
           Part_Of (Prop_Border_Color, Edge_Part (Right)),
        when D_Border_Bottom_Color =>
           Part_Of (Prop_Border_Color, Edge_Part (Bottom)),
        when D_Border_Left_Color =>
           Part_Of (Prop_Border_Color, Edge_Part (Left)),

        when D_Border_Style  => Whole_Of (Prop_Border_Style),
        when D_Border_Top_Style =>
           Part_Of (Prop_Border_Style, Edge_Part (Top)),
        when D_Border_Right_Style =>
           Part_Of (Prop_Border_Style, Edge_Part (Right)),
        when D_Border_Bottom_Style =>
           Part_Of (Prop_Border_Style, Edge_Part (Bottom)),
        when D_Border_Left_Style =>
           Part_Of (Prop_Border_Style, Edge_Part (Left)),

        when D_Border_Width  => Whole_Of (Prop_Border_Width),
        when D_Border_Top_Width =>
           Part_Of (Prop_Border_Width, Edge_Part (Top)),
        when D_Border_Right_Width =>
           Part_Of (Prop_Border_Width, Edge_Part (Right)),
        when D_Border_Bottom_Width =>
           Part_Of (Prop_Border_Width, Edge_Part (Bottom)),
        when D_Border_Left_Width =>
           Part_Of (Prop_Border_Width, Edge_Part (Left)),

        when D_Border_Radius => Whole_Of (Prop_Border_Radius),
        when D_Border_Top_Left_Radius =>
           Part_Of (Prop_Border_Radius, Corner_Part (Top_Left)),
        when D_Border_Top_Right_Radius =>
           Part_Of (Prop_Border_Radius, Corner_Part (Top_Right)),
        when D_Border_Bottom_Right_Radius =>
           Part_Of (Prop_Border_Radius, Corner_Part (Bottom_Right)),
        when D_Border_Bottom_Left_Radius =>
           Part_Of (Prop_Border_Radius, Corner_Part (Bottom_Left)),

        when D_Bottom          => Whole_Of (Prop_Bottom),
        when D_Box_Shadow      => Whole_Of (Prop_Box_Shadow),
        when D_Color           => Whole_Of (Prop_Color),
        when D_Column_Gap      => Part_Of (Prop_Gap, Gap_Column_Part),
        when D_Row_Gap         => Part_Of (Prop_Gap, Gap_Row_Part),
        when D_Gap             => Whole_Of (Prop_Gap),
        when D_Cursor          => Whole_Of (Prop_Cursor),
        when D_Display         => Whole_Of (Prop_Display),
        when D_Flex_Basis      => Whole_Of (Prop_Flex_Basis),
        when D_Flex_Direction  => Whole_Of (Prop_Flex_Direction),
        when D_Flex_Grow       => Whole_Of (Prop_Flex_Grow),
        when D_Flex_Shrink     => Whole_Of (Prop_Flex_Shrink),
        when D_Flex_Wrap       => Whole_Of (Prop_Flex_Wrap),
        when D_Font_Family     => Whole_Of (Prop_Font_Family),
        when D_Font_Size       => Whole_Of (Prop_Font_Size),
        when D_Font_Style      => Whole_Of (Prop_Font_Style),
        when D_Font_Weight     => Whole_Of (Prop_Font_Weight),
        when D_Grid_Column     =>
           Whole_Of (Prop_Grid_Column, Prop_Grid_Column_Span),
        when D_Grid_Row        =>
           Whole_Of (Prop_Grid_Row, Prop_Grid_Row_Span),
        when D_Grid_Template_Columns => Whole_Of (Prop_Grid_Columns),
        when D_Grid_Template_Rows    => Whole_Of (Prop_Grid_Rows),
        when D_Height          => Whole_Of (Prop_Height),
        when D_Justify_Content => Whole_Of (Prop_Justify_Content),
        when D_Left            => Whole_Of (Prop_Left),
        when D_Line_Height     => Whole_Of (Prop_Line_Height),
        when D_List_Style =>
           Whole_Of (Prop_List_Style_Type, Prop_List_Style_Image,
                     Prop_List_Style_Position),
        when D_List_Style_Image    => Whole_Of (Prop_List_Style_Image),
        when D_List_Style_Position => Whole_Of (Prop_List_Style_Position),
        when D_List_Style_Type     => Whole_Of (Prop_List_Style_Type),

        when D_Margin        => Whole_Of (Prop_Margin),
        when D_Margin_Top    => Part_Of (Prop_Margin, Edge_Part (Top)),
        when D_Margin_Right  => Part_Of (Prop_Margin, Edge_Part (Right)),
        when D_Margin_Bottom => Part_Of (Prop_Margin, Edge_Part (Bottom)),
        when D_Margin_Left   => Part_Of (Prop_Margin, Edge_Part (Left)),

        when D_Max_Height      => Whole_Of (Prop_Max_Height),
        when D_Max_Width       => Whole_Of (Prop_Max_Width),
        when D_Min_Height      => Whole_Of (Prop_Min_Height),
        when D_Min_Width       => Whole_Of (Prop_Min_Width),
        when D_Object_Fit      => Whole_Of (Prop_Object_Fit),
        when D_Object_Position => Whole_Of (Prop_Object_Position),
        when D_Opacity         => Whole_Of (Prop_Opacity),
        when D_Order           => Whole_Of (Prop_Order),

        when D_Outline =>
           Whole_Of (Prop_Outline_Width, Prop_Outline_Color,
                     Prop_Outline_Style),
        when D_Outline_Color  => Whole_Of (Prop_Outline_Color),
        when D_Outline_Offset => Whole_Of (Prop_Outline_Offset),
        when D_Outline_Style  => Whole_Of (Prop_Outline_Style),
        when D_Outline_Width  => Whole_Of (Prop_Outline_Width),

        when D_Overflow   => Whole_Of (Prop_Overflow),
        when D_Overflow_X => Whole_Of (Prop_Overflow_X),
        when D_Overflow_Y => Whole_Of (Prop_Overflow_Y),

        when D_Padding        => Whole_Of (Prop_Padding),
        when D_Padding_Top    => Part_Of (Prop_Padding, Edge_Part (Top)),
        when D_Padding_Right  => Part_Of (Prop_Padding, Edge_Part (Right)),
        when D_Padding_Bottom => Part_Of (Prop_Padding, Edge_Part (Bottom)),
        when D_Padding_Left   => Part_Of (Prop_Padding, Edge_Part (Left)),

        when D_Position        => Whole_Of (Prop_Position),
        when D_Right           => Whole_Of (Prop_Right),
        when D_Text_Align      => Whole_Of (Prop_Text_Align),
        when D_Text_Decoration => Whole_Of (Prop_Text_Decoration),
        when D_Text_Overflow   => Whole_Of (Prop_Text_Overflow),
        when D_Text_Wrap_Mode  => Whole_Of (Prop_Text_Wrap_Mode),
        when D_Top             => Whole_Of (Prop_Top),
        when D_Transition      => Whole_Of (Prop_Transition),
        when D_Vertical_Align  => Whole_Of (Prop_Vertical_Align),
        when D_Visibility      => Whole_Of (Prop_Visibility),
        when D_White_Space     => Whole_Of (Prop_White_Space),
        when D_Width           => Whole_Of (Prop_Width));

   --  Whether `unset` means `inherit` here, which it does for a
   --  property Inherit_From carries from a widget into its parts. A
   --  shorthand answers for the whole declaration, so one such property
   --  among the ones it fills is enough.
   function Inherits (T : Wide_Target) return Boolean is
     (for some I in 1 .. T.Count =>
        Inheritable_Properties (T.Steps (I).Prop));


   procedure Apply_Declaration (Slots    : in out Rule_Slots;
                                Selector : String;
                                Name     : String;
                                Value    : String) is
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
      Tracks : Grid_Track_List;
      Overflow_Val : Overflow_Value;
      Border_Side  : Border_Style_Kind;
      Has_Border_Width : Boolean := False;
      Has_Border_Style : Boolean := False;
      Has_Border_Color : Boolean := False;
      Border_All_Read  : Boolean := True;
      Border_Width_Val : Parsed_Length;
      Border_Color_Val : Color_Value;

      --  The declaration's value reaching the rule set: at the whole
      --  property, or at one of the parts a property whose values
      --  cascade separately carries.
      procedure Take (Prop : CSS_Property; R : Value_Ref);
      procedure Take (Prop : CSS_Property; Part : Slot_Part; R : Value_Ref);

      procedure Take (Prop : CSS_Property; R : Value_Ref) is
      begin
         Apply_Property (Slots, Prop, R);
      end Take;

      procedure Take (Prop : CSS_Property; Part : Slot_Part; R : Value_Ref) is
      begin
         Apply_Property (Slots, Prop, Part, R);
      end Take;

      --  Every branch below ends on this where its grammar rejects the
      --  text, which is what tools/css_to_ada.py answers with an
      --  invalid-property-value diagnostic. A branch reaches it once:
      --  the shorthands that fill several properties report the whole
      --  declaration rather than each part they could fill.
      procedure Bad_Value is
      begin
         Invalid_Declarations := Invalid_Declarations + 1;
         Adi.Log.Warning
           ("css: invalid value '" & V & "' for '" & P & "' in '"
            & Selector & "'; the declaration is dropped");
      end Bad_Value;

      --  A keyword whose value comes from outside the rule: `inherit`,
      --  and `unset` where the property inherits. The property is one
      --  the parser carries and the value is one it can hold none of,
      --  which is what Invalid_Declarations counts.
      procedure Wide_Refused is
      begin
         Invalid_Declarations := Invalid_Declarations + 1;
         Adi.Log.Warning
           ("css: '" & LV & "' for '" & P & "' in '" & Selector
            & "'; Adi carries a value from a widget into its parts and"
            & " no further, so the declaration is dropped and what the"
            & " cascade already gave the property stands");
      end Wide_Refused;
   begin
      --  Decl_Table is the whole vocabulary, and tools/css_to_ada.py
      --  answers a name outside it with an unsupported-property
      --  diagnostic. This is the runtime saying the same. The length
      --  test is for a declaration that starts at its colon, where the
      --  name to report is empty.
      if Key = Decl_Unknown then
         if P'Length > 0 then
            Unsupported_Declarations := Unsupported_Declarations + 1;
            Adi.Log.Warning
              ("css: unsupported property '" & P & "' in '" & Selector
               & "'; the declaration is dropped");
         end if;
         return;
      end if;

      --  The CSS-wide keywords answer for every property, so they are
      --  read here rather than in each branch below. `initial` is the
      --  property taken to cleared, which Optional_Values resolves to
      --  the initial value and Merge keeps against a less specific
      --  rule; `unset` is that outside Inheritable_Properties, and
      --  `inherit` within it. `revert` is left to the grammars: Adi has
      --  one cascade origin, so it would be `initial` under another
      --  name, and claiming it would claim a cascade Adi has not got.
      if LV = "initial" or else LV = "unset"
        or else (LV = "inherit" and then not Color_Reading (Key))
      then
         declare
            Target : constant Wide_Target := Wide_Target_Of (Key);
         begin
            if LV = "inherit"
              or else (LV = "unset" and then Inherits (Target))
            then
               Wide_Refused;
            else
               for I in 1 .. Target.Count loop
                  declare
                     Step : Wide_Step renames Target.Steps (I);
                  begin
                     if Step.Whole then
                        Clear_Property (Slots, Step.Prop);
                     else
                        Clear_Property (Slots, Step.Prop, Step.Part);
                     end if;
                  end;
               end loop;
            end if;
         end;
         return;
      end if;

      if Key = D_Color then
         if Parse_Color (V, CVal) then Take (Prop_Color, Intern (CVal)); else Bad_Value; end if;
      elsif Key = D_Background_Color or else Key = D_Background then
         if Parse_Color (V, CVal) then Take (Prop_Background_Color, Intern (CVal)); else Bad_Value; end if;
      elsif Key = D_Padding then
         if Parse_Box (V, Box) then Take (Prop_Padding, Intern (Box)); else Bad_Value; end if;
      elsif Key = D_Padding_Top then
         if Parse_Length (V, LVal) then
            Take (Prop_Padding, Edge_Part (Top), Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Padding_Right then
         if Parse_Length (V, LVal) then
            Take (Prop_Padding, Edge_Part (Right), Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Padding_Bottom then
         if Parse_Length (V, LVal) then
            Take (Prop_Padding, Edge_Part (Bottom), Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Padding_Left then
         if Parse_Length (V, LVal) then
            Take (Prop_Padding, Edge_Part (Left), Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Margin then
         declare
            Sides : Opt_Margin_Sides;
         begin
            if Parse_Margin_Shorthand (V, Sides) then
               --  The shorthand names all four sides, whichever count
               --  of values it was written with.
               for E in Edge loop
                  Take (Prop_Margin, Edge_Part (E), Intern (Sides (E).Value));
               end loop;
            else
               Bad_Value;
            end if;
         end;
      elsif Key = D_Margin_Top then
         if Lower (V) = "auto" then
            Take (Prop_Margin, Edge_Part (Top), Intern (Auto_Margin));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Margin, Edge_Part (Top),
                  Intern (Margin (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Margin_Right then
         if Lower (V) = "auto" then
            Take (Prop_Margin, Edge_Part (Right), Intern (Auto_Margin));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Margin, Edge_Part (Right),
                  Intern (Margin (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Margin_Bottom then
         if Lower (V) = "auto" then
            Take (Prop_Margin, Edge_Part (Bottom), Intern (Auto_Margin));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Margin, Edge_Part (Bottom),
                  Intern (Margin (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Margin_Left then
         if Lower (V) = "auto" then
            Take (Prop_Margin, Edge_Part (Left), Intern (Auto_Margin));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Margin, Edge_Part (Left),
                  Intern (Margin (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Width then
         if Parse_Border_Width (V, BW) then Take (Prop_Border_Width, Intern (BW)); else Bad_Value; end if;
      elsif Key = D_Border_Top_Width then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Width, Edge_Part (Top),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Right_Width then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Width, Edge_Part (Right),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Bottom_Width then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Width, Edge_Part (Bottom),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Left_Width then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Width, Edge_Part (Left),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Color then
         if Parse_Color (V, CVal) then Take (Prop_Border_Color, Intern (Border_Color (CVal))); else Bad_Value; end if;
      elsif Key = D_Border_Top_Color then
         if Parse_Color (V, CVal) then
            Take (Prop_Border_Color, Edge_Part (Top), Intern (CVal));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Right_Color then
         if Parse_Color (V, CVal) then
            Take (Prop_Border_Color, Edge_Part (Right), Intern (CVal));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Bottom_Color then
         if Parse_Color (V, CVal) then
            Take (Prop_Border_Color, Edge_Part (Bottom), Intern (CVal));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Left_Color then
         if Parse_Color (V, CVal) then
            Take (Prop_Border_Color, Edge_Part (Left), Intern (CVal));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Take (Prop_Border_Style, Intern (Border_Style (Border_Side)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Top_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Take (Prop_Border_Style, Edge_Part (Top), Intern (Border_Side));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Right_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Take (Prop_Border_Style, Edge_Part (Right), Intern (Border_Side));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Bottom_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Take (Prop_Border_Style, Edge_Part (Bottom), Intern (Border_Side));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Left_Style then
         if Parse_Border_Style_Value (V, Border_Side) then
            Take (Prop_Border_Style, Edge_Part (Left), Intern (Border_Side));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val,
           Border_All_Read);
         if Border_All_Read
           and then (Has_Border_Width or else Has_Border_Style
                     or else Has_Border_Color)
         then
            if Has_Border_Width then
               Take (Prop_Border_Width,
                     Intern (Border_Width (To_Length (Border_Width_Val))));
            end if;
            if Has_Border_Style then
               Take (Prop_Border_Style,
                     Intern (Border_Style (Border_Side)));
            end if;
            if Has_Border_Color then
               Take (Prop_Border_Color,
                     Intern (Border_Color (Border_Color_Val)));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Top then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val,
           Border_All_Read);
         if Border_All_Read
           and then (Has_Border_Width or else Has_Border_Style
                     or else Has_Border_Color)
         then
            if Has_Border_Width then
               Take (Prop_Border_Width, Edge_Part (Top),
                     Intern (To_Length (Border_Width_Val)));
            end if;
            if Has_Border_Style then
               Take (Prop_Border_Style, Edge_Part (Top),
                     Intern (Border_Side));
            end if;
            if Has_Border_Color then
               Take (Prop_Border_Color, Edge_Part (Top),
                     Intern (Border_Color_Val));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Right then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val,
           Border_All_Read);
         if Border_All_Read
           and then (Has_Border_Width or else Has_Border_Style
                     or else Has_Border_Color)
         then
            if Has_Border_Width then
               Take (Prop_Border_Width, Edge_Part (Right),
                     Intern (To_Length (Border_Width_Val)));
            end if;
            if Has_Border_Style then
               Take (Prop_Border_Style, Edge_Part (Right),
                     Intern (Border_Side));
            end if;
            if Has_Border_Color then
               Take (Prop_Border_Color, Edge_Part (Right),
                     Intern (Border_Color_Val));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Bottom then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val,
           Border_All_Read);
         if Border_All_Read
           and then (Has_Border_Width or else Has_Border_Style
                     or else Has_Border_Color)
         then
            if Has_Border_Width then
               Take (Prop_Border_Width, Edge_Part (Bottom),
                     Intern (To_Length (Border_Width_Val)));
            end if;
            if Has_Border_Style then
               Take (Prop_Border_Style, Edge_Part (Bottom),
                     Intern (Border_Side));
            end if;
            if Has_Border_Color then
               Take (Prop_Border_Color, Edge_Part (Bottom),
                     Intern (Border_Color_Val));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Left then
         Parse_Border_Shorthand_Components (
           V,
           Has_Border_Width,
           Border_Width_Val,
           Has_Border_Style,
           Border_Side,
           Has_Border_Color,
           Border_Color_Val,
           Border_All_Read);
         if Border_All_Read
           and then (Has_Border_Width or else Has_Border_Style
                     or else Has_Border_Color)
         then
            if Has_Border_Width then
               Take (Prop_Border_Width, Edge_Part (Left),
                     Intern (To_Length (Border_Width_Val)));
            end if;
            if Has_Border_Style then
               Take (Prop_Border_Style, Edge_Part (Left),
                     Intern (Border_Side));
            end if;
            if Has_Border_Color then
               Take (Prop_Border_Color, Edge_Part (Left),
                     Intern (Border_Color_Val));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Radius then
         if Parse_Border_Radius (V, BR) then Take (Prop_Border_Radius, Intern (BR)); else Bad_Value; end if;
      elsif Key = D_Border_Top_Left_Radius then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Radius, Corner_Part (Top_Left),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Top_Right_Radius then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Radius, Corner_Part (Top_Right),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Bottom_Right_Radius then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Radius, Corner_Part (Bottom_Right),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Border_Bottom_Left_Radius then
         if Parse_Length (V, LVal) then
            Take (Prop_Border_Radius, Corner_Part (Bottom_Left),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Width then
         if Parse_Size_Value (V, SVal) then Take (Prop_Width, Intern (SVal)); else Bad_Value; end if;
      elsif Key = D_Height then
         if Parse_Size_Value (V, SVal) then Take (Prop_Height, Intern (SVal)); else Bad_Value; end if;
      elsif Key = D_Min_Width then
         if Parse_Size_Value (V, SVal) then Take (Prop_Min_Width, Intern (SVal)); else Bad_Value; end if;
      elsif Key = D_Max_Width then
         if Parse_Size_Value (V, SVal) then Take (Prop_Max_Width, Intern (SVal)); else Bad_Value; end if;
      elsif Key = D_Min_Height then
         if Parse_Size_Value (V, SVal) then Take (Prop_Min_Height, Intern (SVal)); else Bad_Value; end if;
      elsif Key = D_Max_Height then
         if Parse_Size_Value (V, SVal) then Take (Prop_Max_Height, Intern (SVal)); else Bad_Value; end if;
      elsif Key = D_Font_Family then
         if not Fits_In_Style (V) then
            null;  --  Fits_In_Style reports the length in its own words.
         elsif Is_Font_Family_List (V) then
            declare
               Family : constant Opt_Font.Optional := Set_Font_Family (V);
            begin
               if Opt_Font.Is_Set (Family) then
                  Take (Prop_Font_Family, Intern (Family.Value));
               end if;
            end;
         else
            Bad_Value;
         end if;
      elsif Key = D_Font_Size then
         if Parse_Length (V, LVal) then Take (Prop_Font_Size, Intern (To_Length (LVal))); else Bad_Value; end if;
      elsif Key = D_Font_Weight then
         if LV = "100" or else LV = "thin" then Take (Prop_Font_Weight, Intern (Weight_Thin));
         elsif LV = "200" or else LV = "extra-light" or else LV = "ultralight" then Take (Prop_Font_Weight, Intern (Weight_Extra_Light));
         elsif LV = "300" or else LV = "light" then Take (Prop_Font_Weight, Intern (Weight_Light));
         elsif LV = "400" or else LV = "normal" then Take (Prop_Font_Weight, Intern (Weight_Normal));
         elsif LV = "500" or else LV = "medium" then Take (Prop_Font_Weight, Intern (Weight_Medium));
         elsif LV = "600" or else LV = "semi-bold" or else LV = "semibold" then Take (Prop_Font_Weight, Intern (Weight_Semi_Bold));
         elsif LV = "700" or else LV = "bold" then Take (Prop_Font_Weight, Intern (Weight_Bold));
         elsif LV = "800" or else LV = "extra-bold" or else LV = "extrabold" then Take (Prop_Font_Weight, Intern (Weight_Extra_Bold));
         elsif LV = "900" or else LV = "black" then Take (Prop_Font_Weight, Intern (Weight_Black));
         else
            Bad_Value;
         end if;
      elsif Key = D_Font_Style then
         if LV = "normal" then Take (Prop_Font_Style, Intern (Style_Normal));
         elsif LV = "italic" then Take (Prop_Font_Style, Intern (Style_Italic));
         elsif LV = "oblique" then Take (Prop_Font_Style, Intern (Style_Oblique));
         else
            Bad_Value;
         end if;
      elsif Key = D_Text_Decoration then
         if LV = "none" then Take (Prop_Text_Decoration, Intern (Decoration_None));
         elsif LV = "underline" then Take (Prop_Text_Decoration, Intern (Decoration_Underline));
         elsif LV = "overline" then Take (Prop_Text_Decoration, Intern (Decoration_Overline));
         elsif LV = "line-through" then Take (Prop_Text_Decoration, Intern (Decoration_Line_Through));
         else
            Bad_Value;
         end if;
      elsif Key = D_List_Style_Type then
         if Parse_List_Style_Type_Value (V, List_Type_Val) then
            Take (Prop_List_Style_Type, Intern (List_Type_Val));
         else
            Bad_Value;
         end if;
      elsif Key = D_Background_Image then
         if LV = "none" then
            Take (Prop_Background_Image, Intern (No_Background_Image));
         elsif Parse_Linear_Gradient (V, Grad_Val) then
            Take (Prop_Background_Image, Intern (Grad_Val));
         elsif Parse_URL_Function (V, URI_Text) then
            Take (Prop_Background_Image,
                  Intern (Background_Image_URL (To_String (URI_Text))));
         else
            Bad_Value;
         end if;
      elsif Key = D_List_Style_Image then
         if LV = "none" then
            Take (Prop_List_Style_Image, Intern (No_List_Image));
         elsif Parse_URL_Function (V, URI_Text) then
            Take (Prop_List_Style_Image,
                  Intern (List_Image (To_String (URI_Text))));
         else
            Bad_Value;
         end if;
      elsif Key = D_List_Style_Position then
         if Parse_List_Style_Position_Value (V, List_Position_Val) then
            Take (Prop_List_Style_Position, Intern (List_Position_Val));
         else
            Bad_Value;
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
               Take (Prop_List_Style_Type, Intern (List_Type_Val));
            end if;
            if List_Image_Set then
               Take (Prop_List_Style_Image, Intern (List_Image_Val));
            end if;
            if List_Position_Set then
               Take (Prop_List_Style_Position,
                     Intern (List_Position_Val));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_White_Space then
         if LV = "normal" then Take (Prop_White_Space, Intern (WS_Normal));
         elsif LV = "nowrap" then Take (Prop_White_Space, Intern (WS_Nowrap));
         elsif LV = "pre" then Take (Prop_White_Space, Intern (WS_Pre));
         elsif LV = "pre-wrap" then Take (Prop_White_Space, Intern (WS_Pre_Wrap));
         elsif LV = "pre-line" then Take (Prop_White_Space, Intern (WS_Pre_Line));
         else
            Bad_Value;
         end if;
      elsif Key = D_Text_Overflow then
         if LV = "clip" then Take (Prop_Text_Overflow, Intern (Overflow_Clip));
         elsif LV = "ellipsis" then Take (Prop_Text_Overflow, Intern (Overflow_Ellipsis));
         else
            Bad_Value;
         end if;
      elsif Key = D_Line_Height then
         if LV = "normal" then
            Take (Prop_Line_Height, Intern (Normal_Line_Height));
         elsif Parse_Number (V, F) then
            Take (Prop_Line_Height, Intern (Line_Height (F)));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Line_Height,
                  Intern (Line_Height (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Text_Align then
         if LV = "left" then Take (Prop_Text_Align, Intern (Text_Left));
         elsif LV = "right" then Take (Prop_Text_Align, Intern (Text_Right));
         elsif LV = "center" then Take (Prop_Text_Align, Intern (Text_Center));
         elsif LV = "justify" then Take (Prop_Text_Align, Intern (Text_Justify));
         elsif LV = "start" then Take (Prop_Text_Align, Intern (Text_Start));
         elsif LV = "end" then Take (Prop_Text_Align, Intern (Text_End));
         else
            Bad_Value;
         end if;
      elsif Key = D_Text_Wrap_Mode then
         if LV = "wrap" then Take (Prop_Text_Wrap_Mode, Intern (TWM_Wrap));
         elsif LV = "nowrap" then Take (Prop_Text_Wrap_Mode, Intern (TWM_Nowrap));
         else
            Bad_Value;
         end if;
      elsif Key = D_Vertical_Align then
         if LV = "baseline" then Take (Prop_Vertical_Align, Intern (VA_Baseline));
         elsif LV = "top" then Take (Prop_Vertical_Align, Intern (VA_Top));
         elsif LV = "middle" then Take (Prop_Vertical_Align, Intern (VA_Middle));
         elsif LV = "bottom" then Take (Prop_Vertical_Align, Intern (VA_Bottom));
         elsif LV = "text-top" then Take (Prop_Vertical_Align, Intern (VA_Text_Top));
         elsif LV = "text-bottom" then Take (Prop_Vertical_Align, Intern (VA_Text_Bottom));
         else
            Bad_Value;
         end if;
      elsif Key = D_Display then
         if LV = "none" then Take (Prop_Display, Intern (Display_Value'(Display_None)));
         elsif LV = "block" then Take (Prop_Display, Intern (Display_Value'(Block)));
         elsif LV = "inline" then Take (Prop_Display, Intern (Display_Value'(Inline)));
         elsif LV = "inline-block" then Take (Prop_Display, Intern (Display_Value'(Inline_Block)));
         elsif LV = "flex" then Take (Prop_Display, Intern (Display_Value'(Flex)));
         elsif LV = "inline-flex" then Take (Prop_Display, Intern (Display_Value'(Inline_Flex)));
         elsif LV = "grid" then Take (Prop_Display, Intern (Display_Value'(Grid)));
         elsif LV = "inline-grid" then Take (Prop_Display, Intern (Display_Value'(Inline_Grid)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Position then
         if LV = "static" then Take (Prop_Position, Intern (Position_Value'(Static)));
         elsif LV = "relative" then Take (Prop_Position, Intern (Position_Value'(Relative)));
         elsif LV = "absolute" then Take (Prop_Position, Intern (Position_Value'(Absolute)));
         elsif LV = "fixed" then Take (Prop_Position, Intern (Position_Value'(Fixed)));
         elsif LV = "sticky" then Take (Prop_Position, Intern (Position_Value'(Sticky)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Top then
         if LV = "auto" then
            Take (Prop_Top, Intern (Auto_Inset));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Top, Intern (Inset (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Right then
         if LV = "auto" then
            Take (Prop_Right, Intern (Auto_Inset));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Right, Intern (Inset (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Bottom then
         if LV = "auto" then
            Take (Prop_Bottom, Intern (Auto_Inset));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Bottom, Intern (Inset (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Left then
         if LV = "auto" then
            Take (Prop_Left, Intern (Auto_Inset));
         elsif Parse_Length (V, LVal) then
            Take (Prop_Left, Intern (Inset (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Overflow then
         if Parse_Overflow_Value (LV, Overflow_Val) then
            Take (Prop_Overflow, Intern (Overflow_Val));
         else
            Bad_Value;
         end if;
      elsif Key = D_Overflow_X then
         if Parse_Overflow_Value (LV, Overflow_Val) then
            Take (Prop_Overflow_X, Intern (Overflow_Val));
         else
            Bad_Value;
         end if;
      elsif Key = D_Overflow_Y then
         if Parse_Overflow_Value (LV, Overflow_Val) then
            Take (Prop_Overflow_Y, Intern (Overflow_Val));
         else
            Bad_Value;
         end if;
      --  Opacity's grammar is <number> with no range in it, so CSS Color
      --  4 is free to say an out-of-range value "is not invalid" and is
      --  clamped instead. It clamps at computed-value time and keeps the
      --  number as specified; Opacity_Value cannot hold one, so this
      --  clamps on the way in. Same computed result, and it only shows
      --  where the specified value is read back rather than used.
      elsif Key = D_Opacity then
         if Parse_Number (V, F) then
            Take (Prop_Opacity,
                  Intern (Opacity_Value
                            (Float'Max (0.0, Float'Min (1.0, F)))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Cursor then
         if LV = "auto" then Take (Prop_Cursor, Intern (Cursor_Auto));
         elsif LV = "default" then Take (Prop_Cursor, Intern (Cursor_Default));
         elsif LV = "pointer" then Take (Prop_Cursor, Intern (Cursor_Pointer));
         elsif LV = "text" then Take (Prop_Cursor, Intern (Cursor_Text));
         elsif LV = "move" then Take (Prop_Cursor, Intern (Cursor_Move));
         elsif LV = "not-allowed" then Take (Prop_Cursor, Intern (Cursor_Not_Allowed));
         elsif LV = "wait" then Take (Prop_Cursor, Intern (Cursor_Wait));
         elsif LV = "crosshair" then Take (Prop_Cursor, Intern (Cursor_Crosshair));
         elsif LV = "grab" then Take (Prop_Cursor, Intern (Cursor_Grab));
         elsif LV = "grabbing" then Take (Prop_Cursor, Intern (Cursor_Grabbing));
         else
            Bad_Value;
         end if;
      elsif Key = D_Visibility then
         if LV = "visible" then Take (Prop_Visibility, Intern (Visibility_Visible));
         elsif LV = "hidden" then Take (Prop_Visibility, Intern (Visibility_Hidden));
         elsif LV = "collapse" then Take (Prop_Visibility, Intern (Visibility_Collapse));
         else
            Bad_Value;
         end if;
      elsif Key = D_Object_Fit then
         if LV = "fill" then Take (Prop_Object_Fit, Intern (Fit_Fill));
         elsif LV = "contain" then Take (Prop_Object_Fit, Intern (Fit_Contain));
         elsif LV = "cover" then Take (Prop_Object_Fit, Intern (Fit_Cover));
         elsif LV = "none" then Take (Prop_Object_Fit, Intern (Fit_None));
         elsif LV = "scale-down" then Take (Prop_Object_Fit, Intern (Fit_Scale_Down));
         else
            Bad_Value;
         end if;
      elsif Key = D_Object_Position then
         if Parse_Object_Position_Value (V, Object_Pos_Val) then
            Take (Prop_Object_Position, Intern (Object_Pos_Val));
         else
            Bad_Value;
         end if;
      elsif Key = D_Flex_Direction then
         if LV = "row" then Take (Prop_Flex_Direction, Intern (Flex_Direction_Value'(Row)));
         elsif LV = "row-reverse" then Take (Prop_Flex_Direction, Intern (Flex_Direction_Value'(Row_Reverse)));
         elsif LV = "column" then Take (Prop_Flex_Direction, Intern (Flex_Direction_Value'(Column)));
         elsif LV = "column-reverse" then Take (Prop_Flex_Direction, Intern (Flex_Direction_Value'(Column_Reverse)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Flex_Wrap then
         if LV = "nowrap" then Take (Prop_Flex_Wrap, Intern (Flex_Wrap_Value'(No_Wrap)));
         elsif LV = "wrap" then Take (Prop_Flex_Wrap, Intern (Flex_Wrap_Value'(Wrap)));
         elsif LV = "wrap-reverse" then Take (Prop_Flex_Wrap, Intern (Flex_Wrap_Value'(Wrap_Reverse)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Justify_Content then
         if LV = "flex-start" or else LV = "start" then Take (Prop_Justify_Content, Intern (Justify_Content_Value'(Flex_Start)));
         elsif LV = "flex-end" or else LV = "end" then Take (Prop_Justify_Content, Intern (Justify_Content_Value'(Flex_End)));
         elsif LV = "center" then Take (Prop_Justify_Content, Intern (Justify_Content_Value'(Center)));
         elsif LV = "space-between" then Take (Prop_Justify_Content, Intern (Justify_Content_Value'(Space_Between)));
         elsif LV = "space-around" then Take (Prop_Justify_Content, Intern (Justify_Content_Value'(Space_Around)));
         elsif LV = "space-evenly" then Take (Prop_Justify_Content, Intern (Justify_Content_Value'(Space_Evenly)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Align_Items then
         if LV = "flex-start" or else LV = "start" then Take (Prop_Align_Items, Intern (Align_Items_Value'(Flex_Start)));
         elsif LV = "flex-end" or else LV = "end" then Take (Prop_Align_Items, Intern (Align_Items_Value'(Flex_End)));
         elsif LV = "center" then Take (Prop_Align_Items, Intern (Align_Items_Value'(Center)));
         elsif LV = "baseline" then Take (Prop_Align_Items, Intern (Align_Items_Value'(Baseline)));
         elsif LV = "stretch" then Take (Prop_Align_Items, Intern (Align_Items_Value'(Stretch)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Align_Self then
         if LV = "auto" then Take (Prop_Align_Self, Intern (Align_Self_Value'(Auto)));
         elsif LV = "flex-start" or else LV = "start" then Take (Prop_Align_Self, Intern (Align_Self_Value'(Flex_Start)));
         elsif LV = "flex-end" or else LV = "end" then Take (Prop_Align_Self, Intern (Align_Self_Value'(Flex_End)));
         elsif LV = "center" then Take (Prop_Align_Self, Intern (Align_Self_Value'(Center)));
         elsif LV = "baseline" then Take (Prop_Align_Self, Intern (Align_Self_Value'(Baseline)));
         elsif LV = "stretch" then Take (Prop_Align_Self, Intern (Align_Self_Value'(Stretch)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Align_Content then
         if LV = "flex-start" or else LV = "start" then Take (Prop_Align_Content, Intern (Align_Content_Value'(Flex_Start)));
         elsif LV = "flex-end" or else LV = "end" then Take (Prop_Align_Content, Intern (Align_Content_Value'(Flex_End)));
         elsif LV = "center" then Take (Prop_Align_Content, Intern (Align_Content_Value'(Center)));
         elsif LV = "space-between" then Take (Prop_Align_Content, Intern (Align_Content_Value'(Space_Between)));
         elsif LV = "space-around" then Take (Prop_Align_Content, Intern (Align_Content_Value'(Space_Around)));
         elsif LV = "stretch" then Take (Prop_Align_Content, Intern (Align_Content_Value'(Stretch)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Gap then
         if Parse_Length_List (V, Ls) then
            if Ls.Length = 1 then
               Take (Prop_Gap, Intern (Gap (To_Length (Ls (1)))));
            elsif Ls.Length >= 2 then
               Take (Prop_Gap,
                     Intern (Gap (To_Length (Ls (1)), To_Length (Ls (2)))));
            end if;
         else
            Bad_Value;
         end if;
      elsif Key = D_Row_Gap or else Key = D_Column_Gap then
         if Parse_Length (V, LVal) then
            --  An axis is a slot of its own, so a longhand leaves the
            --  other axis as it was -- unnamed here, or whatever a
            --  preceding shorthand in this rule set left.
            Take (Prop_Gap,
                  (if Key = D_Row_Gap then Gap_Row_Part else Gap_Column_Part),
                  Intern (To_Length (LVal)));
         else
            Bad_Value;
         end if;
      --  The flex factors carry their range in the grammar itself,
      --  <number [0,inf]>, and CSS Values 4 makes a value outside a
      --  bracketed range invalid rather than clamped. So a negative one
      --  is dropped, where an out-of-range opacity above is not.
      elsif Key = D_Flex_Grow then
         if Parse_Number (V, F) and then F >= 0.0 then
            Take (Prop_Flex_Grow, Intern (Flex_Grow_Value (F)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Flex_Shrink then
         if Parse_Number (V, F) and then F >= 0.0 then
            Take (Prop_Flex_Shrink, Intern (Flex_Shrink_Value (F)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Flex_Basis then
         if LV = "auto" then Take (Prop_Flex_Basis, Intern (Auto_Basis));
         elsif LV = "content" then Take (Prop_Flex_Basis, Intern (Content_Basis));
         elsif Parse_Length (V, LVal) then Take (Prop_Flex_Basis, Intern (Basis (To_Length (LVal))));
         else
            Bad_Value;
         end if;
      elsif Key = D_Order then
         if Parse_Integer (V, I) then Take (Prop_Order, Intern (Order_Value (I))); else Bad_Value; end if;
      elsif Key = D_Grid_Template_Columns then
         if LV = "none" then
            --  The property's initial value: this names no explicit
            --  track. CSS leaves the tracks to the implicit grid and
            --  grid-auto-columns, which Adi carries as a count of
            --  zero, the way Grid_Rows already carries auto. The
            --  list of no tracks is the cleared track key, so the
            --  declaration takes the tracks off an earlier rule
            --  rather than leaving them to it.
            Take (Prop_Grid_Columns, Tracks_Part,
                  Intern (Default_Grid_Track_List));
            Take (Prop_Grid_Columns, First_Part,
                  Intern (Grid_Columns_Value (0)));
         elsif Parse_Grid_Tracks (V, Tracks, N) then
            --  Past the cap the sizes are given up and the count is
            --  taken alone, leaving the tracks to a less specific rule.
            if Tracks.Count > 0 then
               Take (Prop_Grid_Columns, Tracks_Part, Intern (Tracks));
            end if;
            Take (Prop_Grid_Columns, First_Part,
                  Intern (Grid_Columns_Value (N)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Grid_Template_Rows then
         if LV = "none" then
            Take (Prop_Grid_Rows, Intern (Grid_Rows_Value (0)));
         elsif Parse_Grid_Tracks (V, Tracks, N) then
            --  Rows carry a count and no sizes, so the list the same
            --  grammar builds is read for its length alone.
            Take (Prop_Grid_Rows, Intern (Grid_Rows_Value (N)));
         else
            Bad_Value;
         end if;
      elsif Key = D_Grid_Column or else Key = D_Grid_Row then
         declare
            Slash_Pos   : Natural := 0;
            Start_Val   : Integer;
            Span_Val    : Natural;
            Is_Col      : constant Boolean := Key = D_Grid_Column;
            Got_Start   : Boolean := False;
            Start_Line  : Natural := 0;
            Took        : Boolean := False;
         begin
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
                        Take (Prop_Grid_Column,
                              Intern (Grid_Column_Value (Start_Val)));
                     else
                        Take (Prop_Grid_Row,
                              Intern (Grid_Row_Value (Start_Val)));
                     end if;
                     Took := True;
                  end if;
                  if Right'Length > 5
                    and then Right (Right'First .. Right'First + 3) = "span"
                    and then Is_Whitespace (Right (Right'First + 4))
                  then
                     if Parse_Natural (Right (Right'First + 5 .. Right'Last), Span_Val)
                       and then Span_Val > 0
                     then
                        if Is_Col then
                           Take (Prop_Grid_Column_Span,
                                 Intern (Grid_Column_Span_Value (Span_Val)));
                        else
                           Take (Prop_Grid_Row_Span,
                                 Intern (Grid_Row_Span_Value (Span_Val)));
                        end if;
                        Took := True;
                     end if;
                  elsif Got_Start and then Parse_Integer (Right, Start_Val) then
                     --  "start / end_line" -> span = end - start
                     if Start_Val > Integer (Start_Line) then
                        if Is_Col then
                           Take (Prop_Grid_Column_Span,
                                 Intern (Grid_Column_Span_Value
                                           (Start_Val
                                            - Integer (Start_Line))));
                        else
                           Take (Prop_Grid_Row_Span,
                                 Intern (Grid_Row_Span_Value
                                           (Start_Val
                                            - Integer (Start_Line))));
                        end if;
                        Took := True;
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
                        Take (Prop_Grid_Column_Span,
                              Intern (Grid_Column_Span_Value (Span_Val)));
                     else
                        Take (Prop_Grid_Row_Span,
                              Intern (Grid_Row_Span_Value (Span_Val)));
                     end if;
                     Took := True;
                  end if;
               elsif Parse_Integer (V, Start_Val) and then Start_Val > 0 then
                  if Is_Col then
                     Take (Prop_Grid_Column,
                           Intern (Grid_Column_Value (Start_Val)));
                  else
                     Take (Prop_Grid_Row,
                           Intern (Grid_Row_Value (Start_Val)));
                  end if;
                  Took := True;
               elsif LV = "auto" then
                  --  The initial value, which a rule states to override
                  --  one before it. It leaves both fields where the
                  --  cascade had them, and it is a value the grammar
                  --  reads.
                  Took := True;
               end if;
            end if;

            if not Took then
               Bad_Value;
            end if;
         end;
      elsif Key = D_Outline_Width then
         if Parse_Length (V, LVal) then Take (Prop_Outline_Width, Intern (To_Length (LVal))); else Bad_Value; end if;
      elsif Key = D_Outline_Color then
         if Parse_Color (V, CVal) then Take (Prop_Outline_Color, Intern (CVal)); else Bad_Value; end if;
      elsif Key = D_Outline_Style then
         if LV = "none" then Take (Prop_Outline_Style, Intern (Outline_None));
         elsif LV = "solid" then Take (Prop_Outline_Style, Intern (Outline_Solid));
         elsif LV = "dashed" then Take (Prop_Outline_Style, Intern (Outline_Dashed));
         elsif LV = "dotted" then Take (Prop_Outline_Style, Intern (Outline_Dotted));
         else
            Bad_Value;
         end if;
      elsif Key = D_Outline_Offset then
         if Parse_Length (V, LVal) then Take (Prop_Outline_Offset, Intern (To_Length (LVal))); else Bad_Value; end if;
      elsif Key = D_Outline then
         declare
            Tokens : Token_Vectors.Vector;
            Tok_L  : Parsed_Length;
            Tok_C  : Color_Value;
            --  Held here rather than written as they are read: one
            --  token the grammar cannot read costs the declaration, and
            --  tools/css_to_ada.py stops at the first such token.
            Style_Val : Outline_Style_Kind := Outline_None;
            Width_Val : Parsed_Length;
            Color_Val : Color_Value;
            Has_Style, Has_Width, Has_Color : Boolean := False;
            Read_All : Boolean := True;
         begin
            Split_Whitespace_Tokens (V, Tokens);
            for T of Tokens loop
               declare
                  Tok : constant String := To_String (T);
                  Tok_Low : constant String := Lower (Tok);
               begin
                  if Tok_Low = "none" then
                     Style_Val := Outline_None;
                     Has_Style := True;
                  elsif Tok_Low = "solid" then
                     Style_Val := Outline_Solid;
                     Has_Style := True;
                  elsif Tok_Low = "dashed" then
                     Style_Val := Outline_Dashed;
                     Has_Style := True;
                  elsif Tok_Low = "dotted" then
                     Style_Val := Outline_Dotted;
                     Has_Style := True;
                  elsif Parse_Color (Tok, Tok_C) then
                     Color_Val := Tok_C;
                     Has_Color := True;
                  elsif Parse_Length (Tok, Tok_L) then
                     Width_Val := Tok_L;
                     Has_Width := True;
                  else
                     Read_All := False;
                  end if;
               end;
            end loop;

            if Read_All
              and then (Has_Style or else Has_Width or else Has_Color)
            then
               if Has_Style then
                  Take (Prop_Outline_Style, Intern (Style_Val));
               end if;
               if Has_Width then
                  Take (Prop_Outline_Width,
                        Intern (To_Length (Width_Val)));
               end if;
               if Has_Color then
                  Take (Prop_Outline_Color, Intern (Color_Val));
               end if;
            else
               Bad_Value;
            end if;
         end;
      elsif Key = D_Box_Shadow then
         if Parse_Box_Shadow (V, Shadow_Val) then Take (Prop_Box_Shadow, Intern (Shadow_Val)); else Bad_Value; end if;
      elsif Key = D_Transition then
         declare
            T : Transition_Spec;
         begin
            if Parse_Transition (V, T) then
               Take (Prop_Transition, Intern (T));
            else
               Bad_Value;
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
   end Apply_Declaration;

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
      Result : Unbounded_String;
      I      : Positive := CSS'First;
   begin
      while I <= CSS'Last loop
         if I + 8 <= CSS'Last
           and then CSS (I .. I + 8) = "@property"
         then
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
                  Append (Result, CSS (I .. CSS'Last));
                  return To_String (Result);
               end if;
               Append (Result, CSS (I .. Open));
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

   --  Intern_Styles False answers the font size alone and leaves
   --  Root_Styles empty: a caller that never reads them has no reason to
   --  leave a rule set and a style in the stores for the process.
   procedure Build_Root_Metadata
     (Root_CSS      : String;
      Metadata      : in out Stylesheet_Metadata;
      Intern_Styles : Boolean)
   is
      Pos     : Positive := Root_CSS'First;
      Working : Adi.Widget.Part_Style_Array := Adi.Widget.Empty_Part_Styles;
      Root    : Style_Definition;
      --  The declarations land in one rule set and it is interned once,
      --  so the store holds the block rather than every prefix of it.
      Base    : Rule_Slots;
      Touched : Boolean := False;
   begin
      if Root_CSS'Length = 0 then
         return;
      end if;

      Working := Metadata.Root_Styles;
      Root := Definition (Working (Main_Part).Style);
      Base := Slots_Of (Root.Base);

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
                  Apply_Declaration (Base, ":root", Prop_Name, Prop_Value);
                  if Lower (Prop_Name) = "font-size" then
                     declare
                        Folded : constant Style_Rules := Rules_Of (Base);
                     begin
                        if Opt_Font_Size.Is_Set (Folded.Font_Size) then
                           Metadata.Has_Root_Font_Size := True;
                           Metadata.Root_Font_Size :=
                             Opt_Font_Size.Resolve (Folded.Font_Size);
                        end if;
                     end;
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

      if Touched and then Intern_Styles then
         Root.Base := Intern_Rules (Base);
         Working (Main_Part) := (Style => Intern (Root), Enabled => True);
         Metadata.Root_Styles := Working;
      elsif not Intern_Styles then
         --  Root_Styles is empty, so nothing may report that there are
         --  any. The font size stands on its own.
         Metadata.Has_Root_Style := False;
      end if;
   end Build_Root_Metadata;

   function Preprocess_Custom_Properties
     (CSS           : String;
      Vars          : out Variable_Vectors.Vector;
      Metadata      : out Stylesheet_Metadata;
      Intern_Styles : Boolean) return String
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
         Build_Root_Metadata (To_String (Root_CSS), Metadata, Intern_Styles);
         return Resolve_Var_References (Step4, Resolved);
      end;
   end Preprocess_Custom_Properties;

   function Parse_Rules
     (CSS          : String;
      Out_Rules    : out Parsed_Rule_Vectors.Vector;
      Out_Vars     : out Variable_Vectors.Vector;
      Out_Metadata : out Stylesheet_Metadata;
      Out_Error    : out Unbounded_String;
      Intern_Root  : Boolean := True) return Boolean
   is
      Clean : constant String :=
        Preprocess_Custom_Properties (CSS, Out_Vars, Out_Metadata, Intern_Root);
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
                  --  A block with nothing to select is lost whole, where
                  --  an empty segment beside other selectors leaves them
                  --  carrying it.
                  if Selector_Block'Length = 0 then
                     Unsupported_Selectors := Unsupported_Selectors + 1;
                     Adi.Log.Warning
                       ("css: a rule wants a selector; the rule is dropped");
                  end if;

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
                        Sel_Error : Unbounded_String;
                        Rule : Parsed_Rule := (others => <>);
                     begin
                        if Sel_Text'Length = 0 then
                           --  A stray comma, which the selectors beside
                           --  it carry the block for.
                           null;
                        elsif not Parse_Selector (Sel_Text, PS, Sel_Error) then
                           --  A selector the parser passes over is
                           --  reported and dropped; one that names a
                           --  property the application never declared
                           --  takes the sheet with it, so the last good
                           --  one stands.
                           if Length (Sel_Error) > 0 then
                              Out_Error := Sel_Error;
                              return False;
                           end if;
                        else
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
                                       Apply_Declaration (
                                          Rule.Style,
                                          Sel_Text,
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
      use Selector_Index_Maps;
      C : constant Cursor :=
        Impl.Selector_Index (Kind).Find (Lower (Trimmed (Name)));
   begin
      return (if Has_Element (C) then Element (C) else 0);
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
      Impl.Selector_Index (Kind).Insert
        (Key, Positive (Impl.Selectors.Last_Index));
      return Positive (Impl.Selectors.Last_Index);
   end Ensure_Selector;

   procedure Build_Styles (Impl : in out Stylesheet_Impl;
                           Rules : Parsed_Rule_Vectors.Vector;
                           Success : out Boolean) is
      Saved       : Selector_Style_Vectors.Vector;
      Saved_Index : Selector_Index_Array;

      --  What each selector has so far, published to Impl.Selectors when
      --  the whole build has succeeded. A failed build leaves the
      --  selectors it started with.
      Working : Part_Style_Vectors.Vector;
   begin
      Selector_Style_Vectors.Move (Target => Saved, Source => Impl.Selectors);
      for K in Selector_Kind loop
         Selector_Index_Maps.Move
           (Target => Saved_Index (K), Source => Impl.Selector_Index (K));
      end loop;
      Success := True;

      Build_Loop :
      for R of Rules loop
         declare
            Idx : constant Positive :=
              Ensure_Selector (Impl, Working, R.Sel.Kind, To_String (R.Sel.Name));
            C   : Part_Style_Array renames Working.Reference (Idx).Element.all;
            W   : Style_Definition := Definition (C (R.Sel.Part).Style);
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
                       ("selector '" & To_String (R.Sel.Name)
                        & "' already holds" & Max_Style_Rules'Image
                        & " state rules, no room for "
                        & Selector_Image (R.Sel.Selector));
                     Success := False;
                     exit Build_Loop;
                  end if;

                  Add_Rule (W, (Selector => R.Sel.Selector,
                                Style    => Intern_Rules (R.Style),
                                Priority => 0));
               else
                  W.Rules (Rule_Index).Style :=
                    Intern_Rules
                      (Merge (Slots_Of (W.Rules (Rule_Index).Style), R.Style));
               end if;
            else
               W.Base := Intern_Rules (Merge (Slots_Of (W.Base), R.Style));
            end if;

            C (R.Sel.Part) := (Style => Intern (W), Enabled => True);
         end;
      end loop Build_Loop;

      if Success then
         for I in 1 .. Natural (Impl.Selectors.Length) loop
            Impl.Selectors.Reference (I).Element.all.Styles :=
              Working.Constant_Reference (I).Element.all;
         end loop;
         Saved.Clear;
      else
         Selector_Style_Vectors.Move (Target => Impl.Selectors, Source => Saved);
         for K in Selector_Kind loop
            Selector_Index_Maps.Move
              (Target => Impl.Selector_Index (K), Source => Saved_Index (K));
         end loop;
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
           Find_Selector_Index (Impl, B.Kind, Text_Of (B.Name));
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
                  Root_Merged_Styles (Impl, B.Target, Sel.Styles));
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

      --  Each widget is styled from its own binding, so order across
      --  targets carries nothing and hash order serves.
      declare
         Held : constant Binding_Vectors.Vector := Snapshot (Impl.Effective);
      begin
         for B of Held loop
            Apply_Binding (Impl, B);
         end loop;
      end;
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

      return Impl_Of (Sheet).Selectors (Positive (Idx)).Styles;
   end Styles_For;

   function Styles_For_Scanned
     (Sheet : Stylesheet;
      Kind  : Selector_Kind;
      Name  : String) return Part_Style_Array
   is
      Key : constant String := Lower (Trimmed (Name));
   begin
      if Impl_Of (Sheet) = null then
         return Empty_Part_Styles;
      end if;

      for I in 1 .. Natural (Impl_Of (Sheet).Selectors.Length) loop
         if Impl_Of (Sheet).Selectors (I).Kind = Kind
           and then To_String (Impl_Of (Sheet).Selectors (I).Name) = Key
         then
            return Impl_Of (Sheet).Selectors (I).Styles;
         end if;
      end loop;

      return Empty_Part_Styles;
   end Styles_For_Scanned;

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
      --  A sheet that holds nothing -- never loaded, or destroyed --
      --  names no selector and no root, so it styles nothing.
      if Impl_Of (Sheet) = null then
         return;
      end if;

      Idx := Find_Selector_Index (Impl_Of (Sheet).all, Kind, Name);

      if Idx = 0 then
         Set_Part_Styles
           (W,
            Root_Merged_Styles
              (Impl_Of (Sheet).all, Adi.Widget.Get_Handle (W),
               Empty_Part_Styles));
      else
         declare
            Sel : Selector_Style renames
              Impl_Of (Sheet).Selectors.Constant_Reference (Positive (Idx)).Element.all;
         begin
            Set_Part_Styles
              (W,
               Root_Merged_Styles
                 (Impl_Of (Sheet).all, Adi.Widget.Get_Handle (W),
                  Sel.Styles));
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
      Id  : CSS_Text_Id;
   begin
      Ensure_Impl (Sheet);
      if W = null then
         return;
      end if;

      --  A binding holds its selector as an id, which is the limit this
      --  representation carries: past Max_CSS_Text_Length the store
      --  answers no id, and a binding under one would read back as the
      --  empty selector on every replay -- styling the widget once and
      --  unstyling it at the next reload. Applying such a name still
      --  works, since Apply takes the name itself.
      Id := Intern_Text (Key);
      if Key'Length > 0 and then Id = No_CSS_Text then
         Adi.Log.Error
           ("CSS selector name of" & Natural'Image (Key'Length)
            & " characters is past the" & Natural'Image (Max_CSS_Text_Length)
            & " a binding can hold, so nothing is bound under it: "
            & Key (Key'First .. Key'First + 39) & "...");
         return;
      end if;

      --  One binding per widget, the last one winning.
      Impl_Of (Sheet).Effective.Include
        (Adi.Widget.Get_Handle (W.all),
         Binding'(Kind   => Kind,
                  Name   => Id,
                  Target => Adi.Widget.Get_Handle (W.all)));
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

   ---------------------------------------------------------------------
   --  Rules, without interning
   ---------------------------------------------------------------------

   procedure Free_Data is new Ada.Unchecked_Deallocation
     (Rule_Sheet_Data, Rule_Sheet_Data_Ptr);

   Rule_Sheets_Held : Natural := 0;

   function Live_Rule_Sheets return Natural is (Rule_Sheets_Held);

   procedure Release (D : in out Rule_Sheet_Data_Ptr) is
   begin
      if D /= null then
         Free_Data (D);
         Rule_Sheets_Held := Rule_Sheets_Held - 1;
      end if;
   end Release;

   function Ensure_Rules (D    : in out Rule_Sheet_Data;
                          Kind : Selector_Kind;
                          Name : String) return Positive
   is
      use Selector_Index_Maps;
      Key : constant String := Lower (Trimmed (Name));
      C   : constant Cursor := D.Index (Kind).Find (Key);
   begin
      if Has_Element (C) then
         return Element (C);
      end if;

      D.Rules.Append (Empty_Slots);
      D.Index (Kind).Insert (Key, D.Rules.Last_Index);
      return D.Rules.Last_Index;
   end Ensure_Rules;

   procedure Load_Rules (Sheet       : in out Rule_Sheet;
                         CSS_Content : String;
                         Success     : out Boolean)
   is
      Parsed   : Parsed_Rule_Vectors.Vector;
      Vars     : Variable_Vectors.Vector;
      Metadata : Stylesheet_Metadata;
      Err      : Unbounded_String;
   begin
      if Sheet.Data = null then
         Sheet.Data := new Rule_Sheet_Data;
         Rule_Sheets_Held := Rule_Sheets_Held + 1;
      end if;

      --  Nothing is published until the whole parse has succeeded, so a
      --  sheet that fails to load holds what it held, as a Stylesheet
      --  does.
      if not Parse_Rules (CSS_Content, Parsed, Vars, Metadata, Err,
                          Intern_Root => False)
      then
         Sheet.Data.Last_Error := Err;
         Success := False;
         return;
      end if;

      Sheet.Data.Rules.Clear;
      for K in Selector_Kind loop
         Sheet.Data.Index (K).Clear;
      end loop;
      Sheet.Data.Last_Error := Null_Unbounded_String;
      Sheet.Data.Has_Root_Size := Metadata.Has_Root_Font_Size;
      Sheet.Data.Root_Size     := Metadata.Root_Font_Size;

      for R of Parsed loop
         declare
            Idx : constant Positive :=
              Ensure_Rules (Sheet.Data.all, R.Sel.Kind, To_String (R.Sel.Name));
         begin
            --  A part or a state names something no element of a
            --  document has, so the selector is held and the rule is
            --  not. Order is the order the rules were written in, which
            --  is what settles two declarations of one property.
            if R.Sel.Part = Main_Part and then not R.Sel.Has_State then
               declare
                  Folded : constant Rule_Slots :=
                    Merge (Sheet.Data.Rules (Idx), R.Style);
               begin
                  Sheet.Data.Rules.Replace_Element (Idx, Folded);
               end;
            end if;
         end;
      end loop;

      Success := True;
   end Load_Rules;

   overriding procedure Finalize (Sheet : in out Rule_Sheet) is
   begin
      Release (Sheet.Data);
   end Finalize;

   function Has (Sheet : Rule_Sheet;
                 Kind  : Selector_Kind;
                 Name  : String) return Boolean is
     (Sheet.Data /= null
      and then Sheet.Data.Index (Kind).Contains (Lower (Trimmed (Name))));

   function Base_Rules (Sheet : Rule_Sheet;
                        Kind  : Selector_Kind;
                        Name  : String) return Style_Rules is
   begin
      if Sheet.Data = null then
         return Empty_Style;
      end if;

      declare
         use Selector_Index_Maps;
         C : constant Cursor :=
           Sheet.Data.Index (Kind).Find (Lower (Trimmed (Name)));
      begin
         if not Has_Element (C) then
            return Empty_Style;
         end if;
         return Rules_Of (Sheet.Data.Rules (Element (C)));
      end;
   end Base_Rules;

   function Has_Root_Font_Size (Sheet : Rule_Sheet) return Boolean is
     (Sheet.Data /= null and then Sheet.Data.Has_Root_Size);

   function Root_Font_Size (Sheet : Rule_Sheet) return Length_Value is
     (if Sheet.Data = null then Default_Font_Size else Sheet.Data.Root_Size);

   function Last_Error (Sheet : Rule_Sheet) return String is
     (if Sheet.Data = null then "" else To_String (Sheet.Data.Last_Error));

begin
   Adi.Widget.Window_Bridge.Install_Destroy_Notice
     (On_Widget_Destroyed'Access);
end Adi.CSS_Parser;
