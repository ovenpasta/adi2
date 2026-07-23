--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.Widget;
with Adi.Window;
with Ada.Strings.Unbounded;

package Adi.CSS_Source is

   pragma Elaborate_Body;

   type Source_Mode is (Dynamic_Mode, Static_Mode);

   type Static_Style_Entry is private;
   type Static_Style_Entry_Array is array (Positive range <>) of Static_Style_Entry;

   function Class_Entry (Name : String;
                         Styles : Adi.Widget.Part_Style_Array) return Static_Style_Entry;
   function Id_Entry (Name : String;
                      Styles : Adi.Widget.Part_Style_Array) return Static_Style_Entry;
   function Tag_Entry (Name : String;
                       Styles : Adi.Widget.Part_Style_Array) return Static_Style_Entry;

   type Style_Source is tagged private;

   procedure Set_Static_Entries (Source  : in out Style_Source;
                                 Entries : Static_Style_Entry_Array);

   procedure Set_Static_Metadata
     (Source   : in out Style_Source;
      Metadata : Adi.CSS_Parser.Stylesheet_Metadata);

   procedure Clear_Static_Entries (Source : in out Style_Source);
   procedure Add_Static_Entry (Source : in out Style_Source;
                               Entry_Value : Static_Style_Entry);

   procedure Add_Dynamic_File (Source  : in out Style_Source;
                               Path    : String;
                               Success : out Boolean);

   procedure Add_Dynamic_String (Source      : in out Style_Source;
                                 CSS_Content : String;
                                 Success     : out Boolean);

   procedure Clear_Dynamic_Entries (Source : in out Style_Source);

   procedure Reload_Dynamic (Source  : in out Style_Source;
                             Success : out Boolean);

   procedure Set_Auto_Reload (Source : in out Style_Source;
                              Enabled : Boolean);
   function Auto_Reload_Enabled (Source : Style_Source) return Boolean;

   procedure Set_Mode (Source  : in out Style_Source;
                       Mode    : Source_Mode;
                       Success : out Boolean);
   function Get_Mode (Source : Style_Source) return Source_Mode;

   procedure Tick (Source   : in out Style_Source;
                   Reloaded : out Boolean;
                   Success  : out Boolean);

   procedure Apply (Source : Style_Source;
                    Kind   : Adi.CSS_Parser.Selector_Kind;
                    Name   : String;
                    W      : in out Adi.Widget.Widget'Class);

   procedure Apply_Class (Source : Style_Source;
                          Name   : String;
                          W      : in out Adi.Widget.Widget'Class);
   procedure Apply_Id (Source : Style_Source;
                       Name   : String;
                       W      : in out Adi.Widget.Widget'Class);
   procedure Apply_Tag (Source : Style_Source;
                        Name   : String;
                        W      : in out Adi.Widget.Widget'Class);
   procedure Apply_Root_Metadata
     (Source : Style_Source;
      W      : in out Adi.Widget.Widget'Class);
   procedure Apply_Selector_Set (Source     : Style_Source;
                                 W          : in out Adi.Widget.Widget'Class;
                                 Tag_Name   : String := "";
                                 Class_Name : String := "";
                                 Id_Name    : String := "");

   procedure Bind (Source : in out Style_Source;
                   Kind   : Adi.CSS_Parser.Selector_Kind;
                   Name   : String;
                   W      : access Adi.Widget.Widget'Class);

   procedure Bind_Class (Source : in out Style_Source;
                         Name   : String;
                         W      : access Adi.Widget.Widget'Class);
   --  Name may contain space-separated class names (e.g. "btn btn-primary").
   --  When multiple classes are given, their styles are merged in order.

   procedure Bind_Id (Source : in out Style_Source;
                      Name   : String;
                      W      : access Adi.Widget.Widget'Class);
   procedure Bind_Tag (Source : in out Style_Source;
                       Name   : String;
                       W      : access Adi.Widget.Widget'Class);
   procedure Bind_Root_Metadata
     (Source : in out Style_Source;
      W      : access Adi.Widget.Widget'Class);

   --  Widget_Handle overloads (resolve handle then delegate to access-based)
   procedure Bind_Class (Source : in out Style_Source;
                         Name   : String;
                         W      : Adi.Widget.Widget_Handle);
   procedure Bind_Id (Source : in out Style_Source;
                      Name   : String;
                      W      : Adi.Widget.Widget_Handle);
   procedure Bind_Tag (Source : in out Style_Source;
                       Name   : String;
                       W      : Adi.Widget.Widget_Handle);
   procedure Bind_Root_Metadata
     (Source : in out Style_Source;
      W      : Adi.Widget.Widget_Handle);

   procedure Bind_Selector_Set (Source     : in out Style_Source;
                                W          : access Adi.Widget.Widget'Class;
                                Tag_Name   : String := "";
                                Class_Name : String := "";
                                Id_Name    : String := "");

   procedure Bind_Selector_Set (Source     : in out Style_Source;
                                W          : Adi.Widget.Widget_Handle;
                                Tag_Name   : String := "";
                                Class_Name : String := "";
                                Id_Name    : String := "");

   function Merge_Part_Styles (Base, Override : Adi.Widget.Part_Style_Array)
     return Adi.Widget.Part_Style_Array;

   --  Attach a window so that CSS metadata is applied to it automatically.
   --  Currently propagates: root font size (`:root { font-size: ... }`).
   --  Applied immediately and again on every CSS reload or static update.
   --  Properties absent from the CSS leave the window unchanged.
   procedure Attach_Window
     (Source : in out Style_Source;
      W      : Adi.Window.Window_Handle);

   function Get_Metadata
     (Source : Style_Source) return Adi.CSS_Parser.Stylesheet_Metadata;
   function Has_Custom_Property (Source : Style_Source; Name : String) return Boolean;
   function Get_Custom_Property (Source : Style_Source; Name : String) return String;

   function Get_Last_Error (Source : Style_Source) return String;

private

   type Static_Style_Entry is record
      Kind   : Adi.CSS_Parser.Selector_Kind := Adi.CSS_Parser.Class_Selector;
      Name   : Ada.Strings.Unbounded.Unbounded_String;
      Styles : Adi.Widget.Part_Style_Array := Adi.Widget.Empty_Part_Styles;
   end record;

   type Style_Source_Impl;
   type Style_Source_Impl_Access is access all Style_Source_Impl;

   type Style_Source is tagged record
      Impl : Style_Source_Impl_Access := null;
   end record;

end Adi.CSS_Source;
