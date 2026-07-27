--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Core; use Adi.Core;
with Adi.SDL;  use Adi.SDL;
with System;

package Adi.SVG is

   type Document is tagged private;
   type Document_Access is access all Document'Class;

   type Pixel_Buffer is array (Natural range <>) of aliased Uint32;
   type Pixel_Buffer_Access is access all Pixel_Buffer;

   function Load_From_File (Path : String) return Document_Access;
   function Load_From_String (Source : String) return Document_Access;
   function Is_Valid (Doc : Document) return Boolean;

   procedure Get_Size
     (Doc    : Document;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);

   function Render_ARGB32
     (Doc    : Document;
      Width  : Positive;
      Height : Positive) return Pixel_Buffer_Access;

   procedure Destroy (Doc : in out Document);

   function Backend_Name return String;

private

   type String_Access is access all String;

   type Document is tagged record
      Valid  : Boolean := False;
      Width  : Pixel_Type := 0.0;
      Height : Pixel_Type := 0.0;
      Source : String_Access := null;
      Handle : System.Address := System.Null_Address;
   end record;

end Adi.SVG;
