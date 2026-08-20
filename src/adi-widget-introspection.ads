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

   --  A stale or null handle reads as an empty widget: Get_Info and
   --  Get_Text answer with empty fields, the lookups answer
   --  Null_Handle, and the searches answer an empty vector.

   --  Query: info for a single widget
   function Get_Info
     (H    : Widget_Handle;
      Path : String) return Widget_Info;

   --  Query: text content (dispatches by tag)
   function Get_Text (H : Widget_Handle) return String;

   --  Lookup: by unique ID (recursive tree walk)
   function Find_By_Id
     (Root : Widget_Handle;
      Id   : Natural) return Widget_Handle;

   --  Lookup: by tree path ("1.2.3")
   function Find_By_Path
     (Root : Widget_Handle;
      Path : String) return Widget_Handle;

   --  Lookup: the path string for a known widget (reverse lookup).
   --  Empty when Target is not in Root's subtree.
   function Find_Path
     (Root   : Widget_Handle;
      Target : Widget_Handle) return String;

   --  Search: by text (case-insensitive substring or exact)
   function Find_By_Text
     (Root  : Widget_Handle;
      Query : String;
      Exact : Boolean := False) return Match_Vectors.Vector;

   --  Search: by type name (case-insensitive substring)
   function Find_By_Type
     (Root      : Widget_Handle;
      Type_Name : String) return Match_Vectors.Vector;

end Adi.Widget.Introspection;
