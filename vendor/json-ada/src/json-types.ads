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

private with Ada.Containers.Vectors;
private with Ada.Containers.Indefinite_Vectors;

with Ada.Iterator_Interfaces;

with JSON.Streams;

generic
   type Integer_Type is range <>;
   type Float_Type is digits <>;

   Maximum_Number_Length : Positive := 30;
package JSON.Types is
   pragma Preelaborate;

   Maximum_String_Length_Numbers : constant Positive := Maximum_Number_Length;

   -----------------------------------------------------------------------------
   --                             Memory allocator                            --
   -----------------------------------------------------------------------------

   type Memory_Allocator
     (Maximum_Depth : Positive) is private;

   type Memory_Allocator_Ptr is not null access all Memory_Allocator;

   -----------------------------------------------------------------------------

   type Value_Kind is
     (Array_Kind,
      Object_Kind,
      String_Kind,
      Integer_Kind,
      Float_Kind,
      Boolean_Kind,
      Null_Kind);

   type JSON_Value (Kind : Value_Kind) is tagged private
     with Constant_Indexing => Constant_Reference,
          Default_Iterator  => Iterate,
          Iterator_Element  => JSON_Value;

   function Image (Object : JSON_Value) return String;

   --  Value will raise an Invalid_Type_Error exception if
   --  the JSON value is of the wrong kind
   function Value (Object : JSON_Value) return String;
   function Value (Object : JSON_Value) return Integer_Type;
   function Value (Object : JSON_Value) return Float_Type;
   function Value (Object : JSON_Value) return Boolean;

   function Length (Object : JSON_Value) return Natural;
   --  Object must be a JSON array or object

   function Contains (Object : JSON_Value; Key : String) return Boolean;
   --  Return True if the JSON object contains a key-value pair for
   --  the given key
   --
   --  This function has a time complexity of O(n).
   --
   --  Object must be a JSON object.

   function Get (Object : JSON_Value; Index : Positive) return JSON_Value;
   --  Return the JSON value at the given index in the JSON array
   --
   --  Object must be a JSON array.

   function Get (Object : JSON_Value; Key : String) return JSON_Value;
   --  Return the JSON value for the given key in the JSON object
   --
   --  This function has a time complexity of O(n).
   --
   --  Object must be a JSON object.

   Invalid_Type_Error : exception;

   -----------------------------------------------------------------------------

   procedure Append (Object : in out JSON_Value; Value : JSON_Value)
     with Pre => Object.Kind = Array_Kind;
   --  Internal procedure

   procedure Insert
     (Object : in out JSON_Value;
      Key    : JSON_Value;
      Value  : JSON_Value;
      Check_Duplicate_Keys : Boolean)
   with Pre => Object.Kind = Object_Kind and Key.Kind = String_Kind;
   --  Internal procedure

   -----------------------------------------------------------------------------
   --                                 Helpers                                 --
   -----------------------------------------------------------------------------

   function Get_Array_Or_Empty
     (Object : JSON_Value; Key : String) return JSON_Value
   with Inline;

   function Get_Object_Or_Empty
     (Object : JSON_Value; Key : String) return JSON_Value
   with Inline;

   function Get
     (Object  : JSON_Value;
      Key     : String;
      Default : Integer_Type) return JSON_Value
   with Inline;

   function Get
     (Object  : JSON_Value;
      Key     : String;
      Default : Float_Type) return JSON_Value
   with Inline;

   function Get
     (Object  : JSON_Value;
      Key     : String;
      Default : Boolean) return JSON_Value
   with Inline;

   -----------------------------------------------------------------------------
   --                              Constructors                               --
   -----------------------------------------------------------------------------

   function Create_String
     (Stream : Streams.Stream_Ptr;
      Offset, Length : Streams.AS.Stream_Element_Offset) return JSON_Value;

   function Create_Integer (Value : Integer_Type) return JSON_Value;

   function Create_Float (Value : Float_Type) return JSON_Value;

   function Create_Boolean (Value : Boolean) return JSON_Value;

   function Create_Null return JSON_Value;

   function Create_Array
     (Allocator : Memory_Allocator_Ptr;
      Depth     : Positive) return JSON_Value;

   function Create_Object
     (Allocator : Memory_Allocator_Ptr;
      Depth     : Positive) return JSON_Value;

   -----------------------------------------------------------------------------
   --                                Iterating                                --
   -----------------------------------------------------------------------------

   function Constant_Reference (Object : JSON_Value; Index : Positive)
     return JSON_Value;
   --  For Ada 2012 indexing syntax

   function Constant_Reference (Object : JSON_Value; Key : String)
     return JSON_Value;
   --  For Ada 2012 indexing syntax

   type Cursor (<>) is private;

   function Constant_Reference (Object : aliased JSON_Value; Position : Cursor)
     return JSON_Value;

   function Has_Element (Position : Cursor) return Boolean;

   package Value_Iterator_Interfaces is
     new Ada.Iterator_Interfaces (Cursor, Has_Element);

   function Iterate (Object : JSON_Value)
     return Value_Iterator_Interfaces.Forward_Iterator'Class;

private

   subtype Array_Offset is Natural;

   type JSON_Value (Kind : Value_Kind) is tagged record
      case Kind is
         when Array_Kind | Object_Kind =>
            Allocator : Memory_Allocator_Ptr;
            Depth  : Positive;
            Offset : Array_Offset;
            Length : Natural;
         when String_Kind =>
            Stream : Streams.Stream_Ptr;
            String_Offset, String_Length : Streams.AS.Stream_Element_Offset;
         when Integer_Kind =>
            Integer_Value : Integer_Type;
         when Float_Kind =>
            Float_Value : Float_Type;
         when Boolean_Kind =>
            Boolean_Value : Boolean;
         when Null_Kind =>
            null;
      end case;
   end record;

   -----------------------------------------------------------------------------
   --                                Iterating                                --
   -----------------------------------------------------------------------------

   subtype Iterator_Kind is Value_Kind range Array_Kind .. Object_Kind;

   type Cursor (Kind : Iterator_Kind) is record
      Data  : JSON_Value (Kind => Kind);
      Index : Natural;
   end record;

   type Iterator (Kind : Iterator_Kind) is limited
     new Value_Iterator_Interfaces.Forward_Iterator with
   record
      Data : JSON_Value (Kind => Kind);
   end record;

   overriding function First (Object : Iterator) return Cursor;

   overriding function Next
     (Object   : Iterator;
      Position : Cursor) return Cursor;

   -----------------------------------------------------------------------------
   --                             Memory allocator                            --
   -----------------------------------------------------------------------------

   type Array_Value (Kind : Value_Kind := Null_Kind) is record
      Value : JSON_Value (Kind => Kind);
   end record;

   type Key_Value_Pair (Kind : Value_Kind := Null_Kind) is record
      Key     : JSON_Value (Kind => String_Kind);
      Element : JSON_Value (Kind => Kind);
   end record;

   package Array_Vectors  is new Ada.Containers.Vectors (Positive, Array_Value);
   package Object_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Key_Value_Pair);

   type Array_Level_Array  is array (Positive range <>) of Array_Vectors.Vector;
   type Object_Level_Array is array (Positive range <>) of Object_Vectors.Vector;

   type Memory_Allocator
     (Maximum_Depth : Positive) is
   record
      Array_Levels  : Array_Level_Array  (1 .. Maximum_Depth);
      Object_Levels : Object_Level_Array (1 .. Maximum_Depth);
   end record;

end JSON.Types;
