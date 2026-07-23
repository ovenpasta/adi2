--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings.Unbounded;
with JSON.Types;
with JSON.Parsers;

package Adi.JSON is

   package Types   is new Standard.JSON.Types (Long_Integer, Long_Float);
   package Parsers  is new Standard.JSON.Parsers (Types);

   ---------------------------------------------------------------------------
   --  UTF-8 Safe String Escaping
   ---------------------------------------------------------------------------

   --  Escape a string for use in JSON. Only escapes ", \, and control
   --  characters (0x00-0x1F). All bytes >= 0x80 pass through verbatim,
   --  preserving valid UTF-8 sequences.
   function Escape_String (S : String) return String;

   ---------------------------------------------------------------------------
   --  Streaming JSON Writer
   ---------------------------------------------------------------------------

   type JSON_Writer is tagged limited private;

   --  Create a writer. Pretty => True emits indented, multi-line JSON.
   --  Pretty => False emits compact single-line JSON.
   function Create (Pretty : Boolean := False) return JSON_Writer;

   --  Structure
   procedure Start_Object (W : in out JSON_Writer);
   procedure End_Object   (W : in out JSON_Writer);
   procedure Start_Array  (W : in out JSON_Writer);
   procedure End_Array    (W : in out JSON_Writer);

   --  Key-value pairs (inside objects)
   procedure Key_Value (W : in out JSON_Writer; Key : String; Value : String);
   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : Long_Integer);
   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : Long_Float);
   procedure Key_Value
     (W : in out JSON_Writer; Key : String; Value : Boolean);
   procedure Key_Null  (W : in out JSON_Writer; Key : String);

   --  Write a key whose value will be a nested object or array
   --  (call Start_Object/Start_Array immediately after)
   procedure Key (W : in out JSON_Writer; K : String);

   --  Raw values (inside arrays or as root)
   procedure Write_Value (W : in out JSON_Writer; Value : String);
   procedure Write_Value (W : in out JSON_Writer; Value : Long_Integer);
   procedure Write_Value (W : in out JSON_Writer; Value : Long_Float);
   procedure Write_Value (W : in out JSON_Writer; Value : Boolean);
   procedure Write_Null  (W : in out JSON_Writer);

   --  Output
   function To_String (W : JSON_Writer) return String;

private

   Max_Depth : constant := 64;

   type Depth_Range is range 0 .. Max_Depth;

   --  Track whether current container has had at least one element written
   type Has_Element_Array is array (Depth_Range) of Boolean;

   --  Track whether we just wrote a key (suppress comma before value)
   type After_Key_Array is array (Depth_Range) of Boolean;

   type JSON_Writer is tagged limited record
      Buf         : Ada.Strings.Unbounded.Unbounded_String;
      Pretty      : Boolean := False;
      Depth       : Depth_Range := 0;
      Has_Element : Has_Element_Array := [others => False];
      After_Key   : After_Key_Array := [others => False];
   end record;

   --  Internal helpers
   procedure Maybe_Comma     (W : in out JSON_Writer);
   procedure Write_Indent    (W : in out JSON_Writer);
   procedure Write_Key       (W : in out JSON_Writer; K : String);
   procedure Write_Newline   (W : in out JSON_Writer);

end Adi.JSON;
