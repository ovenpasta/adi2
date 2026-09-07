--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Image; use Adi.Image;

package Adi.SVG_Sprites is

   ---------------------------------------------------------------------------
   --  SVG Sprite Sheet
   --
   --  Loads SVG files containing <symbol> elements (e.g. FontAwesome icon
   --  sprite sheets) and provides on-demand extraction of individual symbols
   --  as Image objects.
   ---------------------------------------------------------------------------

   type Sprite_Sheet is tagged private;
   type Sprite_Sheet_Access is access all Sprite_Sheet'Class;

   ---------------------------------------------------------------------------
   --  Constructors
   ---------------------------------------------------------------------------

   --  Returns null on failure.
   function Load (Path : String) return Sprite_Sheet_Access;

   --  Returns null on failure.
   function Load_From_String (Source : String) return Sprite_Sheet_Access;

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Has_Symbol
     (Sheet : Sprite_Sheet;
      Id    : String) return Boolean;

   function Symbol_Count (Sheet : Sprite_Sheet) return Natural;

   ---------------------------------------------------------------------------
   --  Image extraction
   ---------------------------------------------------------------------------

   --  Fresh Image per call; owner holds nothing if Id is unknown, and Tintable renders white-on-transparent for CSS tinting.
   function Get_Image
     (Sheet    : Sprite_Sheet;
      Id       : String;
      Tintable : Boolean := False) return Image_Owner;

   ---------------------------------------------------------------------------
   --  Resource management
   ---------------------------------------------------------------------------

   procedure Destroy (Sheet : in out Sprite_Sheet);

private

   type Symbol_Entry;
   type Symbol_Entry_Access is access Symbol_Entry;

   --  Simple chained hash map (id string -> symbol data).
   type Bucket_Array is array (Natural range <>) of Symbol_Entry_Access;
   type Bucket_Array_Access is access Bucket_Array;

   type Sprite_Sheet is tagged record
      Buckets : Bucket_Array_Access := null;
      Count   : Natural := 0;
   end record;

end Adi.SVG_Sprites;
