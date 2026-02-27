--  SPDX-License-Identifier: Apache-2.0
--
--  Copyright (c) 2016 onox <denkpadje@gmail.com>
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.

with Ada.Characters.Latin_1;
with Ada.IO_Exceptions;
with Ada.Streams.Stream_IO;
with Ada.Unchecked_Conversion;

package body JSON.Streams is

   use type AS.Stream_Element_Offset;

   procedure Read_Character_From_Stream (Object : in out Stream; Item : out Character) is
      function Convert is new Ada.Unchecked_Conversion
        (Source => AS.Stream_Element, Target => Character);
   begin
      if Object.Index not in Object.Bytes'Range then
         raise Ada.IO_Exceptions.End_Error;
      end if;

      Item := Convert (Object.Bytes (Object.Index));
      Object.Index := Object.Index + 1;
   end Read_Character_From_Stream;

   function Has_Buffered_Character (Object : Stream) return Boolean
     is (Object.Next_Character /= Ada.Characters.Latin_1.NUL);

   procedure Read_Character (Object : in out Stream; Result : out Character) is
      Index : AS.Stream_Element_Offset;
   begin
      Object.Read_Character (Index, Result);
   end Read_Character;

   procedure Read_Character
     (Object : in out Stream;
      Index  : out AS.Stream_Element_Offset;
      Result : out Character)
   is
      C : Character;
   begin
      Index := Object.Index;
      if Object.Next_Character = Ada.Characters.Latin_1.NUL then
         Object.Read_Character_From_Stream (C);
      else
         C := Object.Next_Character;
         Object.Next_Character := Ada.Characters.Latin_1.NUL;
      end if;
      Result := C;
   end Read_Character;

   procedure Write_Character (Object : in out Stream; Next : Character) is
   begin
      Object.Next_Character := Next;
   end Write_Character;

   function Is_Equal_String
     (Object : Stream;
      Offset, Length : AS.Stream_Element_Offset;
      Value : String) return Boolean
   is
      subtype Constrained_String is String (1 .. Integer (Length));

      function Convert is new Ada.Unchecked_Conversion
        (Source => AS.Stream_Element_Array, Target => Constrained_String);
   begin
      return Value = Convert (Object.Bytes (Offset .. Offset + Length - 1));
   end Is_Equal_String;

   function Get_String
     (Object : Stream;
      Offset, Length : AS.Stream_Element_Offset) return String
   is
      subtype Constrained_String is String (1 .. Integer (Length));

      function Convert is new Ada.Unchecked_Conversion
        (Source => AS.Stream_Element_Array, Target => Constrained_String);
   begin
      return Convert (Object.Bytes (Offset .. Offset + Length - 1));
   end Get_String;

   function Create_Stream
     (Bytes : not null Stream_Element_Array_Access) return Stream is
   begin
      return (Bytes          => Bytes,
              Next_Character => Ada.Characters.Latin_1.NUL,
              Index          => Bytes'First);
   end Create_Stream;

   -----------------------------------------------------------------------------

   function From_File
     (File_Name : String) return Stream_Element_Array_Access
   is
      package IO renames AS.Stream_IO;

      File : IO.File_Type;
   begin
      IO.Open (File, IO.In_File, File_Name);

      begin
         declare
            subtype Byte_Array is AS.Stream_Element_Array
              (1 .. AS.Stream_Element_Offset (IO.Size (File)));
            Content : constant not null Stream_Element_Array_Access := new Byte_Array;
         begin
            Byte_Array'Read (IO.Stream (File), Content.all);
            IO.Close (File);
            return Content;
         end;
      exception
         when others =>
            IO.Close (File);
            raise;
      end;
   end From_File;

   function From_Text
     (Text : String) return Stream_Element_Array_Access
   is
      subtype Constrained_SEA is AS.Stream_Element_Array (1 .. Text'Length);

      function Convert is new Ada.Unchecked_Conversion
        (Source => String, Target => Constrained_SEA);

      Content : constant Stream_Element_Array_Access := new Constrained_SEA'(Convert (Text));
   begin
      return Content;
   end From_Text;

end JSON.Streams;
