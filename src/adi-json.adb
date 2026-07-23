--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Adi.JSON is

   ---------------------------------------------------------------------------
   --  Escape_String
   ---------------------------------------------------------------------------

   function Escape_String (S : String) return String is
      Result : Unbounded_String;
      Hex    : constant String := "0123456789abcdef";
   begin
      for C of S loop
         case C is
            when '"'       => Append (Result, "\""");
            when '\'       => Append (Result, "\\");
            when ASCII.BS  => Append (Result, "\b");
            when ASCII.HT  => Append (Result, "\t");
            when ASCII.LF  => Append (Result, "\n");
            when ASCII.FF  => Append (Result, "\f");
            when ASCII.CR  => Append (Result, "\r");
            when others =>
               if Character'Pos (C) < 32 then
                  --  Control character: emit \u00XX
                  declare
                     Hi : constant Natural := Character'Pos (C) / 16;
                     Lo : constant Natural := Character'Pos (C) mod 16;
                  begin
                     Append (Result, "\u00");
                     Append (Result, Hex (Hex'First + Hi));
                     Append (Result, Hex (Hex'First + Lo));
                  end;
               else
                  --  All other bytes including >= 128 (UTF-8 continuation
                  --  and leading bytes) pass through verbatim.
                  Append (Result, C);
               end if;
         end case;
      end loop;
      return To_String (Result);
   end Escape_String;

   ---------------------------------------------------------------------------
   --  JSON_Writer - Creation
   ---------------------------------------------------------------------------

   function Create (Pretty : Boolean := False) return JSON_Writer is
   begin
      return (Buf         => Null_Unbounded_String,
              Pretty      => Pretty,
              Depth       => 0,
              Has_Element => [others => False],
              After_Key   => [others => False]);
   end Create;

   ---------------------------------------------------------------------------
   --  Internal Helpers
   ---------------------------------------------------------------------------

   procedure Write_Newline (W : in out JSON_Writer) is
   begin
      if W.Pretty then
         Append (W.Buf, ASCII.LF);
      end if;
   end Write_Newline;

   procedure Write_Indent (W : in out JSON_Writer) is
   begin
      if W.Pretty and then W.Depth > 0 then
         Append (W.Buf,
           String'(1 .. Natural (W.Depth) * 2 => ' '));
      end if;
   end Write_Indent;

   procedure Maybe_Comma (W : in out JSON_Writer) is
   begin
      --  After a Key call, the value follows immediately - no comma.
      if W.After_Key (W.Depth) then
         W.After_Key (W.Depth) := False;
         return;
      end if;

      if W.Has_Element (W.Depth) then
         Append (W.Buf, ",");
         Write_Newline (W);
      end if;
   end Maybe_Comma;

   procedure Write_Key (W : in out JSON_Writer; K : String) is
   begin
      Maybe_Comma (W);
      Write_Indent (W);
      Append (W.Buf, """" & Escape_String (K) & """:");
      if W.Pretty then
         Append (W.Buf, " ");
      end if;
      W.Has_Element (W.Depth) := True;
   end Write_Key;

   ---------------------------------------------------------------------------
   --  Structure
   ---------------------------------------------------------------------------

   procedure Start_Object (W : in out JSON_Writer) is
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, "{");
      W.Has_Element (W.Depth) := True;
      W.Depth := W.Depth + 1;
      W.Has_Element (W.Depth) := False;
      W.After_Key (W.Depth) := False;
      Write_Newline (W);
   end Start_Object;

   procedure End_Object (W : in out JSON_Writer) is
   begin
      W.Depth := W.Depth - 1;
      if W.Has_Element (W.Depth + 1) then
         Write_Newline (W);
         Write_Indent (W);
      end if;
      Append (W.Buf, "}");
   end End_Object;

   procedure Start_Array (W : in out JSON_Writer) is
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, "[");
      W.Has_Element (W.Depth) := True;
      W.Depth := W.Depth + 1;
      W.Has_Element (W.Depth) := False;
      W.After_Key (W.Depth) := False;
      Write_Newline (W);
   end Start_Array;

   procedure End_Array (W : in out JSON_Writer) is
   begin
      W.Depth := W.Depth - 1;
      if W.Has_Element (W.Depth + 1) then
         Write_Newline (W);
         Write_Indent (W);
      end if;
      Append (W.Buf, "]");
   end End_Array;

   ---------------------------------------------------------------------------
   --  Key (for nested objects/arrays)
   ---------------------------------------------------------------------------

   procedure Key (W : in out JSON_Writer; K : String) is
   begin
      Write_Key (W, K);
      --  Signal that the next Start_Object/Start_Array/Write_* should
      --  not emit a comma or indent (the key already did that).
      W.After_Key (W.Depth) := True;
      --  Undo the Has_Element set by Write_Key -- we set it only once
      --  the actual value is written (Start_Object/Array will set it).
   end Key;

   ---------------------------------------------------------------------------
   --  Key-Value Pairs
   ---------------------------------------------------------------------------

   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : String) is
   begin
      Write_Key (W, Key);
      Append (W.Buf, """" & Escape_String (Value) & """");
   end Key_Value;

   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : Long_Integer)
   is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Long_Integer'Image (Value), Ada.Strings.Left);
   begin
      Write_Key (W, Key);
      Append (W.Buf, Img);
   end Key_Value;

   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : Long_Float)
   is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Long_Float'Image (Value), Ada.Strings.Left);
   begin
      Write_Key (W, Key);
      Append (W.Buf, Img);
   end Key_Value;

   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : Boolean) is
   begin
      Write_Key (W, Key);
      Append (W.Buf, (if Value then "true" else "false"));
   end Key_Value;

   procedure Key_Null (W : in out JSON_Writer; Key : String) is
   begin
      Write_Key (W, Key);
      Append (W.Buf, "null");
   end Key_Null;

   ---------------------------------------------------------------------------
   --  Raw Values
   ---------------------------------------------------------------------------

   procedure Write_Value (W : in out JSON_Writer; Value : String) is
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, """" & Escape_String (Value) & """");
      W.Has_Element (W.Depth) := True;
   end Write_Value;

   procedure Write_Value (W : in out JSON_Writer; Value : Long_Integer) is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Long_Integer'Image (Value), Ada.Strings.Left);
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, Img);
      W.Has_Element (W.Depth) := True;
   end Write_Value;

   procedure Write_Value (W : in out JSON_Writer; Value : Long_Float) is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Long_Float'Image (Value), Ada.Strings.Left);
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, Img);
      W.Has_Element (W.Depth) := True;
   end Write_Value;

   procedure Write_Value (W : in out JSON_Writer; Value : Boolean) is
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, (if Value then "true" else "false"));
      W.Has_Element (W.Depth) := True;
   end Write_Value;

   procedure Write_Null (W : in out JSON_Writer) is
   begin
      if not W.After_Key (W.Depth) then
         Maybe_Comma (W);
         Write_Indent (W);
      else
         W.After_Key (W.Depth) := False;
      end if;
      Append (W.Buf, "null");
      W.Has_Element (W.Depth) := True;
   end Write_Null;

   ---------------------------------------------------------------------------
   --  Output
   ---------------------------------------------------------------------------

   function To_String (W : JSON_Writer) return String is
   begin
      return Ada.Strings.Unbounded.To_String (W.Buf);
   end To_String;

end Adi.JSON;
