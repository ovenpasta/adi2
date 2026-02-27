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

with Ada.Streams;

package JSON.Streams with SPARK_Mode => On is
   pragma Preelaborate;

   pragma Elaborate_Body;

   package AS renames Ada.Streams;

   type Stream is tagged private;

   type Stream_Ptr is not null access all Streams.Stream;

   function Has_Buffered_Character (Object : Stream) return Boolean;

   procedure Read_Character (Object : in out Stream; Result : out Character)
     with Post => not Object.Has_Buffered_Character;

   procedure Read_Character
     (Object : in out Stream;
      Index  : out AS.Stream_Element_Offset;
      Result : out Character)
   with Post => not Object.Has_Buffered_Character;
   --  Writes the offset of the read character to Index. This is needed
   --  for string tokens.

   procedure Write_Character (Object : in out Stream; Next : Character)
     with Pre => not Object.Has_Buffered_Character;

   function Is_Equal_String
     (Object : Stream;
      Offset, Length : AS.Stream_Element_Offset;
      Value : String) return Boolean;

   function Get_String
     (Object : Stream;
      Offset, Length : AS.Stream_Element_Offset) return String;

   type Stream_Element_Array_Access is access all AS.Stream_Element_Array;

   function Create_Stream
     (Bytes : not null Stream_Element_Array_Access) return Stream;

   -----------------------------------------------------------------------------

   function From_File
     (File_Name : String) return Stream_Element_Array_Access;

   function From_Text
     (Text : String) return Stream_Element_Array_Access;

private

   type Stream is tagged record
      Bytes : not null Stream_Element_Array_Access;
      Next_Character : Character;
      Index : AS.Stream_Element_Offset;
   end record;

end JSON.Streams;
