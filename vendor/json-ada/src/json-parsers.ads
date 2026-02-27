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

private with Ada.Finalization;

with JSON.Types;
with JSON.Streams;

generic
   with package Types is new JSON.Types (<>);

   Default_Maximum_Depth : Positive := 10;

   Check_Duplicate_Keys  : Boolean  := False;
   --  If enabled, raise a Constraint_Error when an object contains
   --  duplicate keys. Parsing a JSON text will be slower if enabled.
package JSON.Parsers with SPARK_Mode => On is
   pragma Preelaborate;

   type Parser (<>) is tagged limited private;

   function Create
     (Pointer       : not null JSON.Streams.Stream_Element_Array_Access;
      Maximum_Depth : Positive := Default_Maximum_Depth) return Parser;

   function Create
     (Text          : String;
      Maximum_Depth : Positive := Default_Maximum_Depth) return Parser;

   function Create_From_File
     (File_Name     : String;
      Maximum_Depth : Positive := Default_Maximum_Depth) return Parser;

   function Parse (Object : in out Parser) return Types.JSON_Value
     with SPARK_Mode => Off;

   Parse_Error : exception;

private

   type Parser (Maximum_Depth : Positive)
     is limited new Ada.Finalization.Limited_Controlled with
   record
      Stream      : aliased Streams.Stream;
      Allocator   : aliased Types.Memory_Allocator (Maximum_Depth);
      Pointer     : Streams.Stream_Element_Array_Access;
      Own_Pointer : Boolean;
   end record;

   overriding
   procedure Finalize (Object : in out Parser);

end JSON.Parsers;
