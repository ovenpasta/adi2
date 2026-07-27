--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Vectors;

package Adi.Widget.Introspection is

   --  Flat widget descriptor for MCP serialization
   type Widget_Info is record
      Id          : Natural;
      Tag_Name    : Unbounded_String;
      Path        : Unbounded_String;
      Text        : Unbounded_String;
      Geometry    : Rectangle;
      States      : Widget_States;
      Flags       : Widget_Flags;
      Child_Count : Natural;
      Items_Count : Natural;
   end record;

   --  Compact match result for search operations
   type Widget_Match is record
      Id       : Natural;
      Path     : Unbounded_String;
      Tag_Name : Unbounded_String;
      Text     : Unbounded_String;
   end record;

   package Match_Vectors is new Ada.Containers.Vectors
     (Positive, Widget_Match);

   --  Query: get info for a single widget
   function Get_Info
     (W    : not null access Widget'Class;
      Path : String) return Widget_Info;

   --  Query: extract text content (dispatches by tag)
   function Get_Text (W : not null access Widget'Class) return String;

   --  Lookup: find widget by unique ID (recursive tree walk)
   function Find_By_Id
     (Root : not null Widget_Access;
      Id   : Natural) return Widget_Access;

   --  Lookup: find widget by tree path ("1.2.3")
   function Find_By_Path
     (Root : not null Widget_Access;
      Path : String) return Widget_Access;

   --  Lookup: find path string for a known widget (reverse lookup)
   function Find_Path
     (Root   : not null Widget_Access;
      Target : not null Widget_Access) return String;

   --  Search: find widgets by text (case-insensitive substring or exact)
   function Find_By_Text
     (Root  : not null Widget_Access;
      Query : String;
      Exact : Boolean := False) return Match_Vectors.Vector;

   --  Search: find widgets by type name (case-insensitive substring)
   function Find_By_Type
     (Root      : not null Widget_Access;
      Type_Name : String) return Match_Vectors.Vector;

end Adi.Widget.Introspection;
