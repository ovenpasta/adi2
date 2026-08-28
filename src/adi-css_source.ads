--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
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

   --  Install a configuration as one step. Between Begin_Update and the
   --  matching End_Update the bound widgets are left alone, and End_Update
   --  restyles them once if the configuration ended up different from the
   --  one they were last styled from. Without it, installing three
   --  stylesheets publishes three configurations, and every widget bound
   --  to the source is restyled for each -- which is what a component
   --  built once per row of a list would pay, per row.
   --
   --  Calls nest; only the outermost End_Update publishes.
   procedure Begin_Update (Source : in out Style_Source);
   procedure End_Update (Source : in out Style_Source);

   --  The scoped form, and the one to prefer. It opens the batch on
   --  declaration and publishes on the way out by every path, including
   --  an exception: a pair written by hand around a step that raises
   --  never reaches its End_Update, and a source left mid-batch stops
   --  restyling for the rest of the run without saying so.
   type Update_Scope (Source : not null access Style_Source) is
     limited new Ada.Finalization.Limited_Controlled with private;

   procedure Clear_Static_Entries (Source : in out Style_Source);
   procedure Add_Static_Entry (Source : in out Style_Source;
                               Entry_Value : Static_Style_Entry);

   --  One sheet: a file, read at install time and watched by Tick, or
   --  CSS text the source carries. Text cannot go missing, so a
   --  configuration made only of it always installs.
   type Dynamic_Source_Entry is private;
   type Dynamic_Source_Entry_Array is
     array (Positive range <>) of Dynamic_Source_Entry;

   Empty_Dynamic_Sources : constant Dynamic_Source_Entry_Array;

   function CSS_File (Path : String) return Dynamic_Source_Entry;
   function CSS_Text (Content : String) return Dynamic_Source_Entry;

   --  Replace the dynamic configuration: read in order, concatenated,
   --  parsed once.
   --
   --  Install or nothing -- on a file that is missing or cannot be read
   --  (a directory, one this process may not open) or a parse error, the
   --  source keeps the entries, sheet, mode and styling it had, Success
   --  is False and Get_Last_Error says why.
   --
   --  An empty array clears, and succeeds: a source with no sheets has
   --  nothing loaded rather than an empty sheet loaded. It also restyles
   --  the bound widgets, which Clear_Dynamic_Entries does not.
   procedure Set_Dynamic_Sources
     (Source  : in out Style_Source;
      Entries : Dynamic_Source_Entry_Array;
      Success : out Boolean);

   --  Append one sheet and reload all of them. Install or nothing, so a
   --  sheet that cannot be read is not appended.
   --
   --  Success is the whole configuration's verdict, not this file's.
   --  Installing N sheets this way costs N parses and N(N+1)/2 file
   --  reads; Set_Dynamic_Sources costs one parse and N reads.
   procedure Add_Dynamic_File (Source  : in out Style_Source;
                               Path    : String;
                               Success : out Boolean);

   --  As Add_Dynamic_File, with the CSS given directly. The text cannot
   --  fail, but Success still covers every other entry.
   procedure Add_Dynamic_String (Source      : in out Style_Source;
                                 CSS_Content : String;
                                 Success     : out Boolean);

   --  Drop every sheet, leaving the bound widgets styled until something
   --  restyles them.
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

   --  Bind a widget to every selector that names it, merged tag first,
   --  then classes, then id. An empty argument means the widget is not
   --  selectable that way; Class_Name may list several classes separated
   --  by spaces, as Bind_Class does.
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

   --  Binding entries Reapply_Bindings has looked at, and of those, the
   --  ones it re-styled. Visits are what a test must watch: a fix that
   --  still walks the whole vector to find the two entries that changed
   --  would leave the cost quadratic while applying almost nothing.
   --  Read through Adi.CSS_Source.Testing.
   --
   --  Modular, so instrumentation that runs for the life of the process
   --  wraps rather than raising.
   type Binding_Counter is mod 2 ** 32;
   Visited_Bindings   : Binding_Counter := 0;
   Reapplied_Bindings : Binding_Counter := 0;

   --  Concatenations handed to the parser, and files read to build them.
   --  Installing N sheets one call at a time costs N parses and N(N+1)/2
   --  reads; a test that only looked at the resulting styles could not
   --  tell that from one parse and N reads.
   Dynamic_Parses : Binding_Counter := 0;
   Dynamic_Reads  : Binding_Counter := 0;

   type Static_Style_Entry is record
      Kind   : Adi.CSS_Parser.Selector_Kind := Adi.CSS_Parser.Class_Selector;
      Name   : Ada.Strings.Unbounded.Unbounded_String;
      Styles : Adi.Widget.Interned_Part_Styles :=
        Adi.Widget.Empty_Interned_Part_Styles;
   end record;

   type Dynamic_Entry_Kind is (File_Entry, String_Entry);

   --  Text is the path for a file entry and the CSS for a text one.
   --  Flattened rather than discriminated: a variant would make the
   --  array component indefinite.
   type Dynamic_Source_Entry is record
      Kind : Dynamic_Entry_Kind := File_Entry;
      Text : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   Empty_Dynamic_Sources : constant Dynamic_Source_Entry_Array :=
     [1 .. 0 => (Kind => File_Entry, Text => <>)];

   type Style_Source_Impl;
   type Style_Source_Impl_Access is access all Style_Source_Impl;

   type Style_Source is tagged record
      Impl : Style_Source_Impl_Access := null;
   end record;

   type Update_Scope (Source : not null access Style_Source) is
     limited new Ada.Finalization.Limited_Controlled with null record;
   overriding procedure Initialize (Scope : in out Update_Scope);
   overriding procedure Finalize (Scope : in out Update_Scope);

end Adi.CSS_Source;
