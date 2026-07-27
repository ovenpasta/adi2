--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.SDL;
with Adi.SDL.TTF;      use Adi.SDL.TTF;
with Ada.Containers;   use type Ada.Containers.Count_Type;
with Interfaces.C;     use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;

package body Adi.Text_Layout is

   use Adi.Core;
   use Adi.CSS_Styles;
   use Adi.Text_Buffer;

   function Is_UTF8_Continuation_Byte (C : Character) return Boolean is
      V : constant Natural := Character'Pos (C);
   begin
      return V in 16#80# .. 16#BF#;
   end Is_UTF8_Continuation_Byte;

   function Normalize_Column (Line : String; Col : Natural) return Natural is
      C : Natural := Natural'Min (Col, Line'Length);
   begin
      while C > 0
        and then Integer (C) < Line'Length
        and then Is_UTF8_Continuation_Byte (Line (Integer (C + 1)))
      loop
         C := C - 1;
      end loop;
      return C;
   end Normalize_Column;

   function Next_Column (Line : String; Col : Natural) return Natural is
      C : Natural := Normalize_Column (Line, Col);
   begin
      if C >= Line'Length then
         return Line'Length;
      end if;
      C := C + 1;
      while C < Line'Length
        and then Is_UTF8_Continuation_Byte (Line (Integer (C + 1)))
      loop
         C := C + 1;
      end loop;
      return C;
   end Next_Column;

   function Make_Font_Attrs
     (Label_Style : Resolved_Style) return Adi.Font.Font_Attributes
   is
   begin
      return Adi.Font.Make_Attributes
        (Family     => Label_Style.Font_Family,
         Size       => Float (Font_Length_To_Px (Label_Style.Font_Size)),
         Weight     => Label_Style.Font_Weight,
         Style      => Label_Style.Font_Style,
         Decoration => Label_Style.Text_Decoration);
   end Make_Font_Attrs;

   function Clamp_Row_Index (L : Text_Layout; Row_Index : Positive) return Positive
   is
      Cnt : constant Natural := Natural (L.Rows.Length);
   begin
      if Cnt = 0 then
         return 1;
      end if;
      return Positive (Natural'Min (Natural (Row_Index), Cnt));
   end Clamp_Row_Index;

   function Range_Width
     (Label_Style : Resolved_Style;
      Line        : String;
      Start_Col   : Natural;
      End_Col     : Natural) return Pixel_Type
   is
      Safe_Start : constant Natural := Normalize_Column (Line, Start_Col);
      Safe_End   : constant Natural :=
        Normalize_Column (Line, Natural'Max (Safe_Start, End_Col));
      Segment    : constant String :=
        (if Safe_End <= Safe_Start then ""
         else Line (Line'First + Integer (Safe_Start)
                    .. Line'First + Integer (Safe_End) - 1));
      Font_Attrs : constant Adi.Font.Font_Attributes := Make_Font_Attrs (Label_Style);
      Font       : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      C_Text     : chars_ptr;
      W, H       : aliased int;
      Ok         : Adi.SDL.C_bool;
   begin
      if Segment'Length = 0 or else Font = null then
         return 0.0;
      end if;

      C_Text := New_String (Segment);
      Ok := TTF_GetStringSize
        (Font, C_Text, size_t (Segment'Length), W'Access, H'Access);
      Free (C_Text);

      if not Boolean (Ok) then
         return 0.0;
      end if;
      return Pixel_Type (W);
   end Range_Width;

   function Column_At_X_In_Range
     (Label_Style : Resolved_Style;
      Line        : String;
      Start_Col   : Natural;
      End_Col     : Natural;
      X_From_Row  : Pixel_Type) return Natural
   is
      Safe_Start : constant Natural := Normalize_Column (Line, Start_Col);
      Safe_End   : constant Natural :=
        Normalize_Column (Line, Natural'Max (Safe_Start, End_Col));
      Segment    : constant String :=
        (if Safe_End <= Safe_Start then ""
         else Line (Line'First + Integer (Safe_Start)
                    .. Line'First + Integer (Safe_End) - 1));
      Font_Attrs : constant Adi.Font.Font_Attributes := Make_Font_Attrs (Label_Style);
      Font       : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      Max_Width  : constant int :=
        int (Integer (Pixel_Type'Max (0.0, X_From_Row)));
      C_Text      : chars_ptr;
      Measured_W  : aliased int := 0;
      Measured_L  : aliased size_t := 0;
      Ok          : Adi.SDL.C_bool;
   begin
      if Segment'Length = 0 or else Font = null then
         return Safe_Start;
      end if;

      if Max_Width <= 0 then
         return Safe_Start;
      end if;

      C_Text := New_String (Segment);
      Ok := TTF_MeasureString
        (Font            => Font,
         Text            => C_Text,
         Length          => size_t (Segment'Length),
         Max_Width       => Max_Width,
         Measured_Width  => Measured_W'Access,
         Measured_Length => Measured_L'Access);
      Free (C_Text);

      if not Boolean (Ok) then
         return Safe_Start;
      end if;

      return Normalize_Column (Line, Safe_Start + Natural (Measured_L));
   end Column_At_X_In_Range;

   function Wrap_Enabled (Label_Style : Resolved_Style) return Boolean is
   begin
      return Label_Style.White_Space /= WS_Nowrap
        and then Label_Style.Text_Wrap_Mode /= TWM_Nowrap;
   end Wrap_Enabled;

   procedure Rebuild
     (L              : in out Text_Layout;
      B              : Adi.Text_Buffer.Text_Buffer;
      Label_Style    : Resolved_Style;
      Viewport_Width : Pixel_Type)
   is
      Line_Count : constant Natural := Get_Line_Count (B);
      Can_Wrap   : constant Boolean :=
        Wrap_Enabled (Label_Style) and then Viewport_Width > 1.0;
      Font_Attrs : constant Adi.Font.Font_Attributes := Make_Font_Attrs (Label_Style);
      Font       : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      Max_Width  : constant int := int (Integer (Pixel_Type'Max (1.0, Viewport_Width)));
      C_Text      : chars_ptr;
      Measured_W  : aliased int := 0;
      Measured_L  : aliased size_t := 0;
      Ok          : Adi.SDL.C_bool;
      Line_Len    : Natural;
      Start_Col   : Natural;
      End_Col     : Natural;
   begin
      declare
         Version : constant Natural := Content_Version (B);
      begin
         if Version = L.Cached_Version
           and then Adi.Font."=" (Font_Attrs, L.Cached_Font)
           and then Can_Wrap = L.Cached_Wrap
           and then (not Can_Wrap or else Viewport_Width = L.Cached_Width)
         then
            return;
         end if;
         L.Cached_Version := Version;
         L.Cached_Width   := Viewport_Width;
         L.Cached_Font    := Font_Attrs;
         L.Cached_Wrap    := Can_Wrap;
      end;

      L.Rows.Clear;

      if Line_Count = 0 then
         L.Rows.Append
           (Visual_Row'(Buffer_Line => 1, Start_Column => 0, End_Column => 0));
         return;
      end if;

      for I in 1 .. Line_Count loop
         declare
            Line_Text : constant String := Get_Line (B, I);
         begin
            Line_Len := Line_Text'Length;

            if Line_Len = 0 then
               L.Rows.Append
                 (Visual_Row'(Buffer_Line => I, Start_Column => 0, End_Column => 0));
            elsif not Can_Wrap or else Font = null then
               L.Rows.Append
                 (Visual_Row'
                    (Buffer_Line => I, Start_Column => 0, End_Column => Line_Len));
            else
               Start_Col := 0;
               while Start_Col < Line_Len loop
                  C_Text :=
                    New_String
                      (Line_Text (Line_Text'First + Integer (Start_Col)
                                  .. Line_Text'Last));
                  Ok := TTF_MeasureString
                    (Font            => Font,
                     Text            => C_Text,
                     Length          => size_t (Line_Len - Start_Col),
                     Max_Width       => Max_Width,
                     Measured_Width  => Measured_W'Access,
                     Measured_Length => Measured_L'Access);
                  Free (C_Text);

                  if Boolean (Ok) and then Natural (Measured_L) > 0 then
                     End_Col := Normalize_Column
                       (Line_Text, Start_Col + Natural (Measured_L));
                  else
                     End_Col := Next_Column (Line_Text, Start_Col);
                  end if;

                  if End_Col <= Start_Col then
                     End_Col := Next_Column (Line_Text, Start_Col);
                  end if;
                  if End_Col <= Start_Col then
                     End_Col := Line_Len;
                  end if;

                  L.Rows.Append
                    (Visual_Row'
                       (Buffer_Line  => I,
                        Start_Column => Start_Col,
                        End_Column   => Natural'Min (End_Col, Line_Len)));
                  Start_Col := End_Col;
               end loop;
            end if;
         end;
      end loop;

      if L.Rows.Length = 0 then
         L.Rows.Append
           (Visual_Row'(Buffer_Line => 1, Start_Column => 0, End_Column => 0));
      end if;
   end Rebuild;

   function Row_Count (L : Text_Layout) return Natural is
   begin
      return Natural (L.Rows.Length);
   end Row_Count;

   function Row_At (L : Text_Layout; Index : Positive) return Visual_Row is
   begin
      if L.Rows.Length = 0 then
         return (Buffer_Line => 1, Start_Column => 0, End_Column => 0);
      end if;
      return L.Rows.Element (Clamp_Row_Index (L, Index));
   end Row_At;

   function Row_Index_For_Position
     (L : Text_Layout;
      B : Adi.Text_Buffer.Text_Buffer;
      P : Position) return Positive
   is
      Safe_Line : constant Positive :=
        Positive'Min (P.Line, Positive (Natural'Max (1, Get_Line_Count (B))));
      Line_Text : constant String := Get_Line (B, Safe_Line);
      Line_Last : constant Natural := Line_Text'Length;
      Safe_Col  : constant Natural :=
        Normalize_Column (Line_Text, Natural'Min (P.Column, Line_Last));
      Last_For_Line : Positive := 1;
   begin
      if L.Rows.Length = 0 then
         return 1;
      end if;

      for I in 1 .. Natural (L.Rows.Length) loop
         declare
            R : constant Visual_Row := L.Rows.Element (I);
         begin
            if R.Buffer_Line = Safe_Line then
               Last_For_Line := I;
               if Safe_Col < R.End_Column then
                  return I;
               end if;
               if Safe_Col = R.End_Column and then R.End_Column = Line_Last then
                  return I;
               end if;
            end if;
         end;
      end loop;

      return Last_For_Line;
   end Row_Index_For_Position;

   function Position_At_Row_X
     (L           : Text_Layout;
      B           : Adi.Text_Buffer.Text_Buffer;
      Label_Style : Resolved_Style;
      Row_Index   : Positive;
      X_From_Row  : Pixel_Type) return Position
   is
      R        : constant Visual_Row := Row_At (L, Row_Index);
      Line     : constant String := Get_Line (B, R.Buffer_Line);
      Column   : constant Natural :=
        Column_At_X_In_Range
          (Label_Style, Line, R.Start_Column, R.End_Column, X_From_Row);
   begin
      return (Line => R.Buffer_Line, Column => Column);
   end Position_At_Row_X;

   function Position_At_Point
     (L               : Text_Layout;
      B               : Adi.Text_Buffer.Text_Buffer;
      Label_Style     : Resolved_Style;
      Content_X       : Pixel_Type;
      X, Y            : Pixel_Type;
      Scroll_Offset_Y : Pixel_Type;
      Line_Skip       : Pixel_Type) return Position
   is
      Local_Y : constant Pixel_Type := Y + Scroll_Offset_Y;
      Row_I   : Integer;
      Row_Idx : Positive;
      Row_X   : constant Pixel_Type := Pixel_Type'Max (0.0, X - Content_X);
   begin
      if L.Rows.Length = 0 or else Line_Skip <= 0.0 then
         return Get_Caret (B);
      end if;

      Row_I := Integer (Float'Floor (Float (Local_Y / Line_Skip))) + 1;
      Row_I := Integer'Max
        (1, Integer'Min (Row_I, Integer (Natural (L.Rows.Length))));
      Row_Idx := Positive (Row_I);

      return Position_At_Row_X (L, B, Label_Style, Row_Idx, Row_X);
   end Position_At_Point;

   function X_Offset_For_Column
     (L           : Text_Layout;
      B           : Adi.Text_Buffer.Text_Buffer;
      Label_Style : Resolved_Style;
      Row_Index   : Positive;
      Column      : Natural) return Pixel_Type
   is
      R        : constant Visual_Row := Row_At (L, Row_Index);
      Line     : constant String := Get_Line (B, R.Buffer_Line);
      Safe_Col : constant Natural := Normalize_Column (Line, Column);
      End_Col  : constant Natural := Natural'Min (Safe_Col, R.End_Column);
   begin
      if End_Col <= R.Start_Column then
         return 0.0;
      end if;

      return Range_Width
        (Label_Style => Label_Style,
         Line        => Line,
         Start_Col   => R.Start_Column,
         End_Col     => End_Col);
   end X_Offset_For_Column;

   function Row_Text
     (L        : Text_Layout;
      B        : Adi.Text_Buffer.Text_Buffer;
      Row      : Visual_Row) return String
   is
      pragma Unreferenced (L);
      Line : constant String := Get_Line (B, Row.Buffer_Line);
      S    : constant Natural := Normalize_Column (Line, Row.Start_Column);
      E    : constant Natural := Normalize_Column (Line, Row.End_Column);
   begin
      if E <= S then
         return "";
      end if;

      return Line (Line'First + Integer (S) .. Line'First + Integer (E) - 1);
   end Row_Text;

end Adi.Text_Layout;
