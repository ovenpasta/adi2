--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
with Ada.Strings.Unbounded;

package Adi.Settings is

   ---------------------------------------------------------------------------
   --  Setting_Value - Managed Recursive Variant
   ---------------------------------------------------------------------------

   type Value_Kind is
     (Null_Kind, String_Kind, Integer_Kind, Float_Kind,
      Boolean_Kind, List_Kind, Map_Kind);

   type Setting_Value is private;

   function Kind (V : Setting_Value) return Value_Kind;

   --  Constructors
   function Null_Value   return Setting_Value;
   function To_Value (V : String)       return Setting_Value;
   function To_Value (V : Long_Integer) return Setting_Value;
   function To_Value (V : Long_Float)   return Setting_Value;
   function To_Value (V : Boolean)      return Setting_Value;
   function Empty_List   return Setting_Value;
   function Empty_Map    return Setting_Value;

   --  Scalar extractors (raise Constraint_Error if wrong kind)
   function As_String  (V : Setting_Value) return String;
   function As_Integer (V : Setting_Value) return Long_Integer;
   function As_Float   (V : Setting_Value) return Long_Float;
   function As_Boolean (V : Setting_Value) return Boolean;

   --  List operations (raise Constraint_Error if not List_Kind)
   procedure Append  (V : in out Setting_Value; Element : Setting_Value);
   function  Length  (V : Setting_Value) return Natural;
   function  Element (V : Setting_Value; Index : Positive) return Setting_Value;

   --  Map operations (raise Constraint_Error if not Map_Kind)
   procedure Insert   (V : in out Setting_Value;
                        Key : String; Element : Setting_Value);
   function  Contains (V : Setting_Value; Key : String) return Boolean;
   function  Get      (V : Setting_Value; Key : String) return Setting_Value;

   --  Map iteration: returns keys in sorted order.
   type Key_Array is
     array (Positive range <>) of Ada.Strings.Unbounded.Unbounded_String;
   function Keys (V : Setting_Value) return Key_Array;

   ---------------------------------------------------------------------------
   --  Backend Interface
   ---------------------------------------------------------------------------

   type Settings_Backend is abstract tagged limited null record;
   type Backend_Access is access all Settings_Backend'Class;

   --  Load settings from the given file path. Returns a Map_Kind value
   --  containing all settings, or Null_Value if the file does not exist
   --  or cannot be parsed.
   function Load
     (B : Settings_Backend; Path : String) return Setting_Value is abstract;

   --  Save settings to the given file path. Value is a Map_Kind value
   --  containing all settings.
   procedure Save
     (B    : Settings_Backend;
      Path : String;
      Data : Setting_Value) is abstract;

   ---------------------------------------------------------------------------
   --  Settings_Store
   ---------------------------------------------------------------------------

   type Settings_Store is tagged limited private;

   --  Initialize the store. When Backend is null, a default JSON backend
   --  is created and owned by the store. When non-null, the caller-provided
   --  backend must outlive the store.
   procedure Initialize
     (Store   : in out Settings_Store;
      Org     : String;
      App     : String;
      Backend : Backend_Access := null);

   --  Load settings from disk. Replaces any in-memory settings.
   procedure Load (Store : in out Settings_Store);

   --  Save current settings to disk.
   procedure Save (Store : in out Settings_Store);

   --  Typed getters with defaults.
   --  Keys use '.' as path separator for nested maps.
   --  Literal dots in key segments are escaped as '\.'.
   function Get_String
     (Store : Settings_Store; Key : String;
      Default : String := "") return String;

   function Get_Integer
     (Store : Settings_Store; Key : String;
      Default : Long_Integer := 0) return Long_Integer;

   function Get_Float
     (Store : Settings_Store; Key : String;
      Default : Long_Float := 0.0) return Long_Float;

   function Get_Boolean
     (Store : Settings_Store; Key : String;
      Default : Boolean := False) return Boolean;

   --  Raw value access. Returns Null_Value if key not found.
   function Get
     (Store : Settings_Store; Key : String) return Setting_Value;

   function Contains (Store : Settings_Store; Key : String) return Boolean;

   --  Typed setters. Auto-creates intermediate maps for dot-path keys.
   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : String);
   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Long_Integer);
   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Long_Float);
   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Boolean);
   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Setting_Value);

   --  Remove a key. Does nothing if key not found.
   procedure Remove (Store : in out Settings_Store; Key : String);

   --  Clear all settings.
   procedure Clear (Store : in out Settings_Store);

   --  Query
   function Is_Loaded  (Store : Settings_Store) return Boolean;
   function File_Path  (Store : Settings_Store) return String;

private

   --  Internal node type (recursive tree)
   type Node;
   type Node_Access is access Node;

   --  Controlled holder handles memory management. Setting_Value is
   --  non-tagged (plain record wrapping the holder) so it can be used
   --  in Settings_Backend abstract operations without conflicting
   --  tagged-type dispatch.
   type Value_Holder is new Ada.Finalization.Controlled with record
      Ptr : Node_Access := null;
   end record;

   overriding procedure Adjust   (H : in out Value_Holder);
   overriding procedure Finalize (H : in out Value_Holder);

   type Setting_Value is record
      H : Value_Holder;
   end record;

   type Settings_Store is
     new Ada.Finalization.Limited_Controlled with record
      Root         : Setting_Value;
      Path         : Ada.Strings.Unbounded.Unbounded_String;
      Backend      : Backend_Access := null;
      Owns_Backend : Boolean := False;
      Loaded       : Boolean := False;
   end record;

   overriding procedure Finalize (Store : in out Settings_Store);

end Adi.Settings;
