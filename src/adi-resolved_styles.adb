--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Vectors;
with Adi.Slot_Pool.Refs;

package body Adi.Resolved_Styles is

   use Ada.Containers;

   ---------------------------------------------------------------------------
   --  Storage
   ---------------------------------------------------------------------------

   --  Entries sit in fixed blocks so that an address stays put as the
   --  store grows, and so that an eviction returns the blocks to the
   --  free pool instead of to the allocator.
   Block_Size : constant := 128;

   type Style_Block is array (1 .. Block_Size) of aliased Resolved_Style;
   type Style_Block_Access is access Style_Block;

   package Block_Vectors is new Ada.Containers.Vectors
     (Positive, Style_Block_Access);

   Blocks : Block_Vectors.Vector;

   --  Entries the store holds, which Scratch_Pool.Held does not name:
   --  see the rule against a use clause on the instantiation.
   Held : Natural := 0;

   Gen : Natural := 1;

   --  Where a scratch handle starts. The store cannot reach it.
   Scratch_Base : constant := 16#0100_0000#;

   pragma Compile_Time_Error
     (Scratch_Base <= 16_384,
      "the scratch range overlaps the store's own index range");

   --  Indexes grouped by hash, so interning probes a handful of
   --  candidates instead of the whole store.
   package Index_Vectors is new Ada.Containers.Vectors (Positive, Positive);

   function Same_Hash (H : Hash_Type) return Hash_Type is (H);

   package Index_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Hash_Type,
      Element_Type    => Index_Vectors.Vector,
      Hash            => Same_Hash,
      Equivalent_Keys => Ada.Containers."=",
      "="             => Index_Vectors."=");

   Index : Index_Maps.Map;

   --  The layout projection of each entry, as an index into this same
   --  store. Zero while the entry is being filled in.
   package Layout_Vectors is new Ada.Containers.Vectors (Positive, Natural);

   Layout_Index : Layout_Vectors.Vector;

   Default_Style : aliased constant Resolved_Style := (others => <>);

   --  The cells in place. A scratch handle is read and written where it
   --  sits, so neither costs a copy of the pair.
   package Scratch_Refs is new Scratch_Pool.Refs;

   function Cells_Of (S : Scratch_Slot) return Scratch_Refs.Const_Access is
     (Scratch_Refs.Ref (Scratch_Pool.Slot (S)));

   function Writable_Cells_Of (S : Scratch_Slot)
     return Scratch_Refs.Var_Access
   is (Scratch_Refs.Mutable (Scratch_Pool.Slot (S)));

   ---------------------------------------------------------------------------
   --  Hash
   ---------------------------------------------------------------------------

   --  A hash over a subset of the record: every component it reads is
   --  read the same way for equal values, which is all equality asks of
   --  it. Variant components are reached through their discriminant, so
   --  no indeterminate byte is ever touched. The steps themselves are
   --  Adi.CSS_Styles.Value_Hash's, shared with the rule-set store.

   use Adi.CSS_Styles.Value_Hash;

   function Hash (S : Resolved_Style) return Hash_Type is
      H : Hash_Type := 16#811C_9DC5#;
   begin
      H := Add (H, S.Color);
      H := Add (H, S.Background_Color);
      H := Mix (H, Background_Image_Kind'Pos (S.Background_Image.Kind));
      H := Add (H, S.Border_Radius);
      H := Add (H, S.Border_Width);
      H := Add (H, S.Border_Color);
      H := Add (H, S.Border_Style);
      H := Add (H, S.Outline_Width);
      H := Add (H, S.Outline_Color);
      H := Mix (H, Outline_Style_Kind'Pos (S.Outline_Style));
      H := Add (H, S.Outline_Offset);
      H := Add (H, S.Padding);
      for E in Edge loop
         H := Add (H, S.Margin (E));
      end loop;
      H := Add (H, S.Width);
      H := Add (H, S.Height);
      H := Add (H, S.Min_Width);
      H := Add (H, S.Max_Width);
      H := Add (H, S.Min_Height);
      H := Add (H, S.Max_Height);
      H := Mix (H, Hash_Type (S.Font_Family));
      H := Add (H, S.Font_Size);
      H := Mix (H, Font_Weight_Value'Pos (S.Font_Weight));
      H := Mix (H, Font_Style_Value'Pos (S.Font_Style));
      H := Mix (H, Text_Align_Value'Pos (S.Text_Align));
      H := Mix (H, Vertical_Align_Value'Pos (S.Vertical_Align));
      H := Mix (H, Text_Decoration_Value'Pos (S.Text_Decoration));
      H := Mix (H, List_Style_Type_Kind'Pos (S.List_Style_Type.Kind));
      H := Mix (H, List_Style_Image_Kind'Pos (S.List_Style_Image.Kind));
      H := Mix (H, List_Style_Position_Value'Pos (S.List_Style_Position));
      H := Mix (H, White_Space_Value'Pos (S.White_Space));
      H := Mix (H, Text_Overflow_Value'Pos (S.Text_Overflow));
      H := Mix (H, Text_Wrap_Mode_Value'Pos (S.Text_Wrap_Mode));
      H := Add (H, S.Line_Height);
      H := Mix (H, Display_Value'Pos (S.Display));
      H := Mix (H, Position_Value'Pos (S.Position));
      H := Add (H, S.Top);
      H := Add (H, S.Right);
      H := Add (H, S.Bottom);
      H := Add (H, S.Left);
      H := Mix (H, Overflow_Value'Pos (S.Overflow_X));
      H := Mix (H, Overflow_Value'Pos (S.Overflow_Y));
      H := Mix (H, Visibility_Value'Pos (S.Visibility));
      H := Mix (H, Num (Float (S.Opacity)));
      H := Mix (H, Cursor_Value'Pos (S.Cursor));
      H := Add (H, S.Box_Shadow);
      H := Mix (H, Object_Fit_Value'Pos (S.Object_Fit));
      H := Add (H, S.Object_Position);
      H := Mix (H, Flex_Direction_Value'Pos (S.Flex_Direction));
      H := Mix (H, Flex_Wrap_Value'Pos (S.Flex_Wrap));
      H := Mix (H, Justify_Content_Value'Pos (S.Justify_Content));
      H := Mix (H, Align_Items_Value'Pos (S.Align_Items));
      H := Mix (H, Align_Content_Value'Pos (S.Align_Content));
      H := Add (H, S.Gap);
      H := Mix (H, Hash_Type (S.Grid_Columns));
      H := Mix (H, Hash_Type (S.Grid_Rows));
      H := Mix (H, Hash_Type (S.Grid_Column_Tracks.Count));
      H := Mix (H, Align_Self_Value'Pos (S.Align_Self));
      H := Mix (H, Num (Float (S.Flex_Grow)));
      H := Mix (H, Num (Float (S.Flex_Shrink)));
      H := Add (H, S.Flex_Basis);
      H := Mix (H, Hash_Type (Integer (S.Order) mod 2 ** 24));
      H := Mix (H, Hash_Type (S.Grid_Column));
      H := Mix (H, Hash_Type (S.Grid_Row));
      H := Mix (H, Hash_Type (S.Grid_Column_Span));
      H := Mix (H, Hash_Type (S.Grid_Row_Span));
      H := Add (H, S.Transition);
      return H;
   end Hash;

   ---------------------------------------------------------------------------
   --  Cells
   ---------------------------------------------------------------------------

   function Block_Of (I : Positive) return Positive is
     (1 + (I - 1) / Block_Size);

   function Slot_Of (I : Positive) return Positive is
     (1 + (I - 1) mod Block_Size);

   function Cell (I : Positive) return not null access Resolved_Style is
     (Blocks.Element (Block_Of (I)) (Slot_Of (I))'Access);

   function Const_Cell (I : Positive) return not null Const_Style_Access is
     (Blocks.Element (Block_Of (I)) (Slot_Of (I))'Access);

   --  A scratch handle splits into the slot it names and which of the
   --  slot's two cells. The pool answers a slot released since, or
   --  handed out again since, as absent.
   function Scratch_Of (H : Resolved_Handle) return Scratch_Slot is
     (Named (Ordinal => 1 + (H.Index - Scratch_Base - 1) / 2,
             Serial  => H.Gen));

   function Which_Cell (H : Resolved_Handle) return Positive is
     (1 + (H.Index - Scratch_Base - 1) mod 2);

   function Ref (H : Resolved_Handle) return not null Const_Style_Access is
      use type Scratch_Refs.Const_Access;
   begin
      if H.Index = 0 then
         return Default_Style'Access;

      elsif H.Index > Scratch_Base then
         declare
            Cells : constant Scratch_Refs.Const_Access :=
              Cells_Of (Scratch_Of (H));
         begin
            if Cells = null then
               return Default_Style'Access;
            end if;
            return Cells (Which_Cell (H))'Access;
         end;

      elsif H.Gen = Gen and then H.Index <= Held then
         return Const_Cell (H.Index);

      else
         return Default_Style'Access;
      end if;
   end Ref;

   function Value (H : Resolved_Handle) return Resolved_Style is (Ref (H).all);

   function Is_Held (H : Resolved_Handle) return Boolean is
   begin
      if H.Index = 0 then
         return True;
      elsif H.Index > Scratch_Base then
         return Live (Scratch_Of (H));
      else
         return H.Gen = Gen and then H.Index <= Held;
      end if;
   end Is_Held;

   ---------------------------------------------------------------------------
   --  Interning
   ---------------------------------------------------------------------------

   function Layout_Projection (S : Resolved_Style) return Resolved_Style is
   begin
      return Result : Resolved_Style := Default_Style do
         for P in CSS_Property loop
            if Layout_Affecting_Properties (P) then
               Copy_Property (P, S, Result);
            end if;
         end loop;
      end return;
   end Layout_Projection;

   procedure Evict is
   begin
      Held := 0;
      Index.Clear;
      Layout_Index.Clear;
      Gen := Gen + 1;
   end Evict;

   function Probe (Key : Hash_Type; S : Resolved_Style) return Natural is
      Bucket : constant Index_Maps.Cursor := Index.Find (Key);
   begin
      if Index_Maps.Has_Element (Bucket) then
         for I of Index_Maps.Element (Bucket) loop
            if Const_Cell (I).all = S then
               return I;
            end if;
         end loop;
      end if;
      return 0;
   end Probe;

   procedure Record_Index (Key : Hash_Type; I : Positive) is
      Bucket : constant Index_Maps.Cursor := Index.Find (Key);
   begin
      if Index_Maps.Has_Element (Bucket) then
         Index.Reference (Bucket).Append (I);
      else
         declare
            Fresh : Index_Vectors.Vector;
         begin
            Fresh.Append (I);
            Index.Insert (Key, Fresh);
         end;
      end if;
   end Record_Index;

   --  Interning never clears. Collect is the one place a slot changes
   --  hands, so a handle stays good from the call that minted it until
   --  the next Collect, and the entry and the layout projection behind
   --  it can both be appended without a clear landing between them.
   function Intern (S : Resolved_Style) return Resolved_Handle is
   begin
      if S = Default_Style then
         return Default_Handle;
      end if;

      declare
         Key : constant Hash_Type := Hash (S);
         Hit : constant Natural := Probe (Key, S);
      begin
         if Hit /= 0 then
            return (Index => Hit, Gen => Gen);
         end if;

         Held := Held + 1;
         while Blocks.Length * Block_Size < Count_Type (Held) loop
            Blocks.Append (new Style_Block);
         end loop;

         declare
            Mine : constant Positive := Held;
         begin
            Cell (Mine).all := S;
            Layout_Index.Append (0);
            Record_Index (Key, Mine);

            Layout_Index.Replace_Element
              (Mine, Intern (Layout_Projection (S)).Index);

            return (Index => Mine, Gen => Gen);
         end;
      end;
   end Intern;

   procedure Collect is
   begin
      if Held >= Cap_Entries then
         Evict;
      end if;
   end Collect;

   function Layout_Of (H : Resolved_Handle) return Resolved_Handle is
   begin
      if H.Index = 0
        or else H.Index > Scratch_Base
        or else H.Gen /= Gen
        or else H.Index > Held
      then
         return Default_Handle;
      end if;
      declare
         Projection : constant Natural := Layout_Index.Element (H.Index);
      begin
         return (Index => Projection,
                 Gen   => (if Projection = 0 then 0 else Gen));
      end;
   end Layout_Of;

   ---------------------------------------------------------------------------
   --  Lifetime
   ---------------------------------------------------------------------------

   function Generation return Natural is (Gen);
   function Entry_Count return Natural is (Held);

   function Entry_Cap return Natural is (Cap_Entries);

   function Entry_Bytes return Natural is
     (Natural (Blocks.Length)
      * (Style_Block'Max_Size_In_Storage_Elements));

   ---------------------------------------------------------------------------
   --  Animation scratch
   ---------------------------------------------------------------------------

   function Acquire_Scratch return Scratch_Slot is (Acquire);

   procedure Release_Scratch (S : in out Scratch_Slot) is
   begin
      Release (S);
   end Release_Scratch;

   function Held_Scratch return Natural is (Scratch_Pool.Held);

   --  The two cells of a slot take consecutive indexes above
   --  Scratch_Base, and the slot's serial rides in Gen.
   function From_Cell (S : Scratch_Slot) return Resolved_Handle is
     (if Ordinal (S) /= 0
      then (Index => Scratch_Base + 2 * (Ordinal (S) - 1) + 1,
            Gen   => Serial (S))
      else Default_Handle);

   function Current_Cell (S : Scratch_Slot) return Resolved_Handle is
     (if Ordinal (S) /= 0
      then (Index => Scratch_Base + 2 * (Ordinal (S) - 1) + 2,
            Gen   => Serial (S))
      else Default_Handle);

   procedure Write (H : Resolved_Handle; S : Resolved_Style) is
      use type Scratch_Refs.Var_Access;
   begin
      if H.Index <= Scratch_Base then
         return;
      end if;

      declare
         Cells : constant Scratch_Refs.Var_Access :=
           Writable_Cells_Of (Scratch_Of (H));
      begin
         if Cells /= null then
            Cells (Which_Cell (H)) := S;
         end if;
      end;
   end Write;

end Adi.Resolved_Styles;
