--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Hashed_Maps;

with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Log;
with Adi.Widget; use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.Window;
use type Adi.Window.Window_Handle;

package body Adi.CSS_Source is

   package Char renames Ada.Characters.Handling;
   package Fix renames Ada.Strings.Fixed;
   use type Adi.CSS_Parser.Selector_Kind;

   function Normalize_Name (Name : String) return String is
     (Char.To_Lower (Fix.Trim (Name, Ada.Strings.Both)));

   type Binding_Kind is (Single_Binding, Multi_Class_Binding, Selector_Set_Binding);

   type Bound_Target is record
      Kind         : Binding_Kind := Single_Binding;
      Selector_Kind : Adi.CSS_Parser.Selector_Kind := Adi.CSS_Parser.Class_Selector;
      Name         : Unbounded_String;
      Tag_Name     : Unbounded_String;
      Class_Name   : Unbounded_String;
      Id_Name      : Unbounded_String;
      Target       : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
   end record;

   package Entry_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Static_Style_Entry);

   package Binding_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Bound_Target);

   --  Last_Modified is what Tick compares against.
   type Tracked_Entry is record
      Source_Entry  : Dynamic_Source_Entry;
      Last_Modified : Ada.Calendar.Time := Ada.Calendar.Clock;
   end record;

   package Dynamic_Entry_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Tracked_Entry);

   package Binding_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Adi.Widget.Widget_Handle,
      Element_Type    => Bound_Target,
      Hash            => Adi.Widget.Hash,
      Equivalent_Keys => Adi.Widget."=");

   type Style_Source_Impl is record
      Mode             : Source_Mode := Dynamic_Mode;
      Auto_Reload      : Boolean := True;
      Entries          : Dynamic_Entry_Vectors.Vector;
      Dynamic_Loaded   : Boolean := False;
      Sheet            : Adi.CSS_Parser.Stylesheet;
      Root_Target      : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
      --  The binding in force for each target, so handing the root role
      --  over can restyle the widget losing it and the one taking it
      --  without searching. Bindings keeps the history a reload replays;
      --  this keeps what is currently true of each widget.
      Effective        : Binding_Maps.Map;

      --  The text the dynamic sheet was last built from, and the whole
      --  configuration as it stood when the bound widgets were last
      --  restyled. Comparing against these is what tells a source that
      --  has been reconfigured from one that has been handed the same
      --  configuration again -- which is what a generated Build does on
      --  every call, once per row of a list.
      Dynamic_Text     : Unbounded_String;
      Applied_Valid    : Boolean := False;
      Applied_Mode     : Source_Mode := Dynamic_Mode;
      Applied_Metadata : Adi.CSS_Parser.Stylesheet_Metadata :=
        (others => <>);
      Applied_Statics  : Entry_Vectors.Vector;
      Applied_Text     : Unbounded_String;
      --  Whether a sheet was loaded at all when that styling was done.
      --  The text alone cannot say: a load that fails leaves the text of
      --  the last good one in place, so a source that styled from
      --  nothing and one that styled from that sheet read alike.
      Applied_Loaded   : Boolean := False;

      --  Depth of Begin_Update/End_Update nesting. Above zero, the
      --  configuration is still being assembled and nothing is published.
      Update_Depth     : Natural := 0;
      Last_Error       : Unbounded_String;
      Static_Metadata  : Adi.CSS_Parser.Stylesheet_Metadata := (others => <>);
      Static_Styles    : Entry_Vectors.Vector;
      Bindings         : Binding_Vectors.Vector;
      Attached_Window  : Adi.Window.Window_Handle := Adi.Window.Null_Window_Handle;
   end record;

   procedure Ensure_Impl (Source : in out Style_Source) is
   begin
      if Source.Impl = null then
         Source.Impl := new Style_Source_Impl;
      end if;
   end Ensure_Impl;

   function Active_Metadata
     (Source : Style_Source) return Adi.CSS_Parser.Stylesheet_Metadata is
   begin
      if Source.Impl = null then
         return (others => <>);
      end if;

      if Source.Impl.Mode = Dynamic_Mode and then Source.Impl.Dynamic_Loaded then
         return Adi.CSS_Parser.Get_Metadata (Source.Impl.Sheet);
      end if;

      return Source.Impl.Static_Metadata;
   end Active_Metadata;

   procedure Apply_Root_Metadata_Impl
     (Source : Style_Source;
      W      : in out Adi.Widget.Widget'Class);

   function Merge_Widget_Style (Base, Override : Widget_Style) return Widget_Style is
      Result : Widget_Style := Base;
      Rule_Index : Natural := 0;
   begin
      Result.Base := Merge (Result.Base, Override.Base);

      for I in 1 .. Override.Rule_Count loop
         Rule_Index := 0;
         for J in 1 .. Result.Rule_Count loop
            if Result.Rules (J).Selector = Override.Rules (I).Selector then
               Rule_Index := J;
               exit;
            end if;
         end loop;

         if Rule_Index = 0 then
            if Result.Rule_Count < Max_Style_Rules then
               Add_Rule (Result, Override.Rules (I));
            end if;
         else
            Result.Rules (Rule_Index).Style :=
              Merge (Result.Rules (Rule_Index).Style, Override.Rules (I).Style);
         end if;
      end loop;

      return Result;
   end Merge_Widget_Style;

   function Merge_Part_Styles (Base, Override : Part_Style_Array) return Part_Style_Array is
      Result : Part_Style_Array := Base;
   begin
      for P in Part_Kind loop
         if Override (P).Enabled then
            Result (P).Enabled := True;
            Result (P).Style := Merge_Widget_Style (Result (P).Style, Override (P).Style);
         end if;
      end loop;
      return Result;
   end Merge_Part_Styles;

   function Selector_Styles (Source : Style_Source;
                             Kind   : Adi.CSS_Parser.Selector_Kind;
                             Name   : String) return Part_Style_Array is
      N : constant String := Normalize_Name (Name);
      Result : Part_Style_Array := Empty_Part_Styles;
   begin
      if Source.Impl = null then
         return Empty_Part_Styles;
      end if;

      if Source.Impl.Mode = Static_Mode then
         for I in 1 .. Natural (Source.Impl.Static_Styles.Length) loop
            if Source.Impl.Static_Styles (I).Kind = Kind
              and then To_String (Source.Impl.Static_Styles (I).Name) = N
            then
               Result := Merge_Part_Styles (
                 Result,
                 Source.Impl.Static_Styles (I).Styles);
            end if;
         end loop;

         return Result;
      end if;

      if not Source.Impl.Dynamic_Loaded then
         return Empty_Part_Styles;
      end if;

      return Adi.CSS_Parser.Styles_For (Source.Impl.Sheet, Kind, Name);
   end Selector_Styles;

   function Multi_Class_Styles (Source : Style_Source;
                                Names  : String) return Part_Style_Array is
      Result : Part_Style_Array := Empty_Part_Styles;
      First  : Positive := Names'First;
      Last   : Natural;
   begin
      while First <= Names'Last loop
         --  Skip leading spaces
         while First <= Names'Last and then Names (First) = ' ' loop
            First := First + 1;
         end loop;
         exit when First > Names'Last;

         --  Find end of token
         Last := First;
         while Last < Names'Last and then Names (Last + 1) /= ' ' loop
            Last := Last + 1;
         end loop;

         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Class_Selector,
                            Names (First .. Last)));
         First := Last + 1;
      end loop;
      return Result;
   end Multi_Class_Styles;

   function Combined_Styles (Source     : Style_Source;
                             Tag_Name   : String;
                             Class_Name : String;
                             Id_Name    : String) return Part_Style_Array is
      Result : Part_Style_Array := Empty_Part_Styles;
   begin
      if Tag_Name /= "" then
         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Tag_Selector, Tag_Name));
      end if;

      --  Class_Name is a space-separated list, the same as Bind_Class takes.
      if Class_Name /= "" then
         Result := Merge_Part_Styles (
           Result,
           Multi_Class_Styles (Source, Class_Name));
      end if;

      if Id_Name /= "" then
         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Id_Selector, Id_Name));
      end if;

      return Result;
   end Combined_Styles;

   function Root_Merged_Styles
     (Source : Style_Source;
      Target : Adi.Widget.Widget_Handle;
      Styles : Part_Style_Array) return Part_Style_Array
   is
      Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
        Active_Metadata (Source);
   begin
      if Source.Impl /= null
        and then Adi.Widget.Is_Valid (Target)
        and then Source.Impl.Root_Target = Target
        and then Metadata.Has_Root_Style
      then
         return Merge_Part_Styles (Metadata.Root_Styles, Styles);
      end if;

      return Styles;
   end Root_Merged_Styles;

   procedure Apply_To_Widget (Source : Style_Source;
                              Kind   : Adi.CSS_Parser.Selector_Kind;
                              Name   : String;
                              W      : in out Adi.Widget.Widget'Class) is
   begin
      Set_Part_Styles
        (W,
         Root_Merged_Styles
           (Source,
            Adi.Widget.Get_Handle (W),
            Selector_Styles (Source, Kind, Name)));
   end Apply_To_Widget;

   procedure Apply_Selector_Set_To_Widget (Source     : Style_Source;
                                           W          : in out Adi.Widget.Widget'Class;
                                           Tag_Name   : String;
                                           Class_Name : String;
                                           Id_Name    : String) is
   begin
      Set_Part_Styles
        (W,
         Root_Merged_Styles
           (Source,
            Adi.Widget.Get_Handle (W),
            Combined_Styles (Source, Tag_Name, Class_Name, Id_Name)));
   end Apply_Selector_Set_To_Widget;

   procedure Apply_Root_Metadata_Impl
     (Source : Style_Source;
      W      : in out Adi.Widget.Widget'Class) is
      Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
        Active_Metadata (Source);
   begin
      if Metadata.Has_Root_Style then
         Set_Part_Styles (W, Metadata.Root_Styles);
      end if;
   end Apply_Root_Metadata_Impl;

   procedure Apply_Multi_Classes (Source : Style_Source;
                                  Names  : String;
                                  W      : in out Adi.Widget.Widget'Class) is
   begin
      Set_Part_Styles
        (W,
         Root_Merged_Styles
           (Source,
            Adi.Widget.Get_Handle (W),
            Multi_Class_Styles (Source, Names)));
   end Apply_Multi_Classes;

   --  Apply one binding to its widget. Root_Merged_Styles folds in the
   --  :root styles when the target is the current root, so this is also
   --  how a widget sheds them once it is root no longer.
   procedure Apply_Binding (Source : in out Style_Source; B : Bound_Target) is
   begin
      if not Adi.Widget.Is_Valid (B.Target) then
         return;
      end if;

      declare
         R : constant Adi.Widget.Widget_Ref := Adi.Widget.Borrow (B.Target);
      begin
         case B.Kind is
            when Single_Binding =>
               Apply_To_Widget
                 (Source, B.Selector_Kind, To_String (B.Name), R.Ptr.all);
            when Multi_Class_Binding =>
               Apply_Multi_Classes (Source, To_String (B.Name), R.Ptr.all);
            when Selector_Set_Binding =>
               Apply_Selector_Set_To_Widget
                 (Source, R.Ptr.all,
                  To_String (B.Tag_Name),
                  To_String (B.Class_Name),
                  To_String (B.Id_Name));
         end case;
      end;
   end Apply_Binding;

   --  Record what is now in force for this widget.
   procedure Note_Binding
     (Source : in out Style_Source; B : Bound_Target) is
   begin
      Source.Impl.Effective.Include (B.Target, B);
   end Note_Binding;

   --  Restyle one widget from what it is currently bound under. Whether
   --  it is the root is answered by Root_Merged_Styles, so this both
   --  grants and withdraws the :root styles. A widget with no binding
   --  gets the :root styles alone, and only while it is the root: it has
   --  nothing else to restore.
   procedure Restyle (Source : in out Style_Source;
                      H      : Adi.Widget.Widget_Handle)
   is
      use Binding_Maps;
      C : constant Cursor := Source.Impl.Effective.Find (H);
   begin
      if not Adi.Widget.Is_Valid (H) then
         return;
      end if;

      if Has_Element (C) then
         Apply_Binding (Source, Element (C));
         return;
      end if;

      --  Nothing bound: the widget has only what this stylesheet put on
      --  it, which is the :root styles and only while it is the root.
      --  Handing the role away takes them back rather than leaving the
      --  widget styled as a root it no longer is.
      declare
         R : constant Adi.Widget.Widget_Ref := Adi.Widget.Borrow (H);
      begin
         if Source.Impl.Root_Target = H then
            Apply_Root_Metadata_Impl (Source, R.Ptr.all);
         else
            Set_Part_Styles (R.Ptr.all, Empty_Part_Styles);
         end if;
      end;
   end Restyle;

   --  What the bound widgets were last styled from. Static mode reads
   --  the registered entries and the metadata; dynamic mode reads the
   --  sheet, and the text it was built from stands for it.
   function Same_As_Applied (Source : Style_Source) return Boolean is
      use type Adi.CSS_Parser.Stylesheet_Metadata;
      use type Entry_Vectors.Vector;
   begin
      return Source.Impl.Applied_Valid
        and then Source.Impl.Applied_Mode = Source.Impl.Mode
        and then Source.Impl.Applied_Metadata = Source.Impl.Static_Metadata
        and then Source.Impl.Applied_Statics = Source.Impl.Static_Styles
        and then Source.Impl.Applied_Text = Source.Impl.Dynamic_Text
        and then Source.Impl.Applied_Loaded = Source.Impl.Dynamic_Loaded;
   end Same_As_Applied;

   procedure Note_Applied (Source : in out Style_Source) is
   begin
      Source.Impl.Applied_Valid    := True;
      Source.Impl.Applied_Mode     := Source.Impl.Mode;
      Source.Impl.Applied_Metadata := Source.Impl.Static_Metadata;
      Source.Impl.Applied_Statics  := Source.Impl.Static_Styles;
      Source.Impl.Applied_Text     := Source.Impl.Dynamic_Text;
      Source.Impl.Applied_Loaded   := Source.Impl.Dynamic_Loaded;
   end Note_Applied;

   procedure Reapply_Bindings (Source : in out Style_Source);

   --  Restyle every bound widget, but only when the configuration they
   --  were last styled from is not the one in force now. Handing a
   --  source the configuration it already has is what a generated Build
   --  does on every call, and must cost nothing.
   procedure Reapply_If_Changed (Source : in out Style_Source) is
   begin
      if Source.Impl = null
        or else Source.Impl.Update_Depth > 0
        or else Same_As_Applied (Source)
      then
         return;
      end if;
      Reapply_Bindings (Source);
      Note_Applied (Source);
   end Reapply_If_Changed;

   procedure Reapply_Bindings (Source : in out Style_Source) is
   begin
      if Source.Impl = null then
         return;
      end if;

      if Adi.Widget.Is_Valid (Source.Impl.Root_Target) then
         declare
            R : constant Adi.Widget.Widget_Ref :=
              Adi.Widget.Borrow (Source.Impl.Root_Target);
         begin
            Apply_Root_Metadata_Impl (Source, R.Ptr.all);
         end;
      end if;

      for I in 1 .. Natural (Source.Impl.Bindings.Length) loop
         declare
            B : constant Bound_Target := Source.Impl.Bindings (I);
         begin
            Visited_Bindings := Visited_Bindings + 1;
            if Adi.Widget.Is_Valid (B.Target) then
               declare
                  R : constant Adi.Widget.Widget_Ref :=
                    Adi.Widget.Borrow (B.Target);
               begin
                  Reapplied_Bindings := Reapplied_Bindings + 1;
                  case B.Kind is
                     when Single_Binding =>
                        Apply_To_Widget (
                          Source,
                          B.Selector_Kind,
                          To_String (B.Name),
                          R.Ptr.all);
                     when Multi_Class_Binding =>
                        Apply_Multi_Classes (
                          Source,
                          To_String (B.Name),
                          R.Ptr.all);
                     when Selector_Set_Binding =>
                        Apply_Selector_Set_To_Widget (
                          Source,
                          R.Ptr.all,
                          To_String (B.Tag_Name),
                          To_String (B.Class_Name),
                          To_String (B.Id_Name));
                  end case;
               end;
            end if;
         end;
      end loop;

      --  Apply :root { font-size } to the bound window, if any.
      --  No else: when the CSS has no root font-size we leave the window alone.
      declare
         Meta : constant Adi.CSS_Parser.Stylesheet_Metadata :=
           Active_Metadata (Source);
      begin
         if Meta.Has_Root_Font_Size
           and then Source.Impl.Attached_Window /= Adi.Window.Null_Window_Handle
         then
            Adi.Window.Set_Root_Font_Size
              (Source.Impl.Attached_Window, Meta.Root_Font_Size);
         end if;
      end;
   end Reapply_Bindings;

   function Read_File (Path : String) return String is
      use Ada.Directories;
      File_Size : constant Natural := Natural (Size (Path));
   begin
      Dynamic_Reads := Dynamic_Reads + 1;
      if File_Size = 0 then
         return "";
      end if;
      declare
         subtype Content_String is String (1 .. File_Size);
         F : Ada.Streams.Stream_IO.File_Type;
         S : Ada.Streams.Stream_IO.Stream_Access;
         Result : Content_String;
      begin
         Ada.Streams.Stream_IO.Open (F, Ada.Streams.Stream_IO.In_File, Path);
         S := Ada.Streams.Stream_IO.Stream (F);
         Content_String'Read (S, Result);
         Ada.Streams.Stream_IO.Close (F);
         return Result;
      end;
   end Read_File;

   --  Stamps each file entry with the modification time this read saw.
   --  Touches nothing else on Impl bar Last_Error, which is what lets a
   --  failed install leave the configuration in force alone.
   function Read_Entries
     (Source : in out Style_Source;
      Wanted : Dynamic_Entry_Vectors.Vector;
      Loaded : out Dynamic_Entry_Vectors.Vector;
      Text   : out Unbounded_String) return Boolean is
   begin
      Loaded := Wanted;
      Text := Null_Unbounded_String;

      for I in 1 .. Natural (Loaded.Length) loop
         declare
            E : constant Tracked_Entry := Loaded (I);
         begin
            case E.Source_Entry.Kind is
               when File_Entry =>
                  declare
                     Path : constant String := To_String (E.Source_Entry.Text);
                  begin
                     if Ada.Directories.Exists (Path) then
                        Loaded.Replace_Element (I,
                          Tracked_Entry'
                            (Source_Entry  => E.Source_Entry,
                             Last_Modified =>
                               Ada.Directories.Modification_Time (Path)));
                        Append (Text, Read_File (Path));
                        Append (Text, ASCII.LF);
                     else
                        Source.Impl.Last_Error :=
                          To_Unbounded_String ("File not found: " & Path);
                        return False;
                     end if;
                  exception
                     --  A path that exists and cannot be read: a
                     --  directory, a file this process may not open, one
                     --  too large to hold. Reported like any other load
                     --  failure, because a caller reading Success cannot
                     --  be expected to handle an exception from the
                     --  middle of the configuration it is installing.
                     when others =>
                        Source.Impl.Last_Error :=
                          To_Unbounded_String ("Cannot read file: " & Path);
                        return False;
                  end;
               when String_Entry =>
                  Append (Text, E.Source_Entry.Text);
                  Append (Text, ASCII.LF);
            end case;
         end;
      end loop;

      return True;
   end Read_Entries;

   --  Read, parse, and only then commit: every failure path returns with
   --  Entries, Dynamic_Text, Dynamic_Loaded and the sheet as they were.
   procedure Install_Entries (Source  : in out Style_Source;
                              Wanted  : Dynamic_Entry_Vectors.Vector;
                              Success : out Boolean) is
      Fresh : Dynamic_Entry_Vectors.Vector;
      Text  : Unbounded_String;
   begin
      if not Read_Entries (Source, Wanted, Fresh, Text) then
         Success := False;
         return;
      end if;

      declare
         Load_OK : Boolean := False;
      begin
         Dynamic_Parses := Dynamic_Parses + 1;
         Adi.CSS_Parser.Load_String
           (Source.Impl.Sheet, To_String (Text), Load_OK);
         if not Load_OK then
            Source.Impl.Last_Error := To_Unbounded_String (
              Adi.CSS_Parser.Get_Last_Error (Source.Impl.Sheet));
            Success := False;
            return;
         end if;
      end;

      Source.Impl.Entries        := Fresh;
      Source.Impl.Dynamic_Text   := Text;
      Source.Impl.Dynamic_Loaded := True;
      Source.Impl.Last_Error     := Null_Unbounded_String;
      Success := True;
   end Install_Entries;

   --  Record the modification times a failed reload saw. The entry list
   --  is unchanged -- this is what the source has looked at, not what it
   --  installed -- and without it Tick reads and parses the same broken
   --  file on every frame until someone fixes it.
   procedure Restamp (Source : in out Style_Source) is
   begin
      for I in 1 .. Natural (Source.Impl.Entries.Length) loop
         declare
            E : constant Tracked_Entry := Source.Impl.Entries (I);
         begin
            if E.Source_Entry.Kind = File_Entry then
               declare
                  Path : constant String := To_String (E.Source_Entry.Text);
               begin
                  Source.Impl.Entries.Replace_Element (I,
                    Tracked_Entry'
                      (Source_Entry  => E.Source_Entry,
                       Last_Modified =>
                         Ada.Directories.Modification_Time (Path)));
               exception
                  --  Unstampable, so Tick keeps watching it -- which is
                  --  right for a sheet that is missing rather than broken.
                  when others => null;
               end;
            end if;
         end;
      end loop;
   end Restamp;

   procedure Reload_All_Dynamic (Source  : in out Style_Source;
                                 Success : out Boolean) is
   begin
      Install_Entries (Source, Source.Impl.Entries, Success);
      if not Success then
         Restamp (Source);
      end if;
   end Reload_All_Dynamic;

   function Class_Entry (Name : String;
                         Styles : Adi.Widget.Part_Style_Array) return Static_Style_Entry is
   begin
      return (
        Kind => Adi.CSS_Parser.Class_Selector,
        Name => To_Unbounded_String (Normalize_Name (Name)),
        Styles => Styles);
   end Class_Entry;

   function Id_Entry (Name : String;
                      Styles : Adi.Widget.Part_Style_Array) return Static_Style_Entry is
   begin
      return (
        Kind => Adi.CSS_Parser.Id_Selector,
        Name => To_Unbounded_String (Normalize_Name (Name)),
        Styles => Styles);
   end Id_Entry;

   function Tag_Entry (Name : String;
                       Styles : Adi.Widget.Part_Style_Array) return Static_Style_Entry is
   begin
      return (
        Kind => Adi.CSS_Parser.Tag_Selector,
        Name => To_Unbounded_String (Normalize_Name (Name)),
        Styles => Styles);
   end Tag_Entry;

   procedure Set_Static_Entries (Source  : in out Style_Source;
                                 Entries : Static_Style_Entry_Array) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Static_Styles.Clear;
      for E of Entries loop
         Source.Impl.Static_Styles.Append (E);
      end loop;

      if Source.Impl.Mode = Static_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Set_Static_Entries;

   procedure Set_Static_Metadata
     (Source   : in out Style_Source;
      Metadata : Adi.CSS_Parser.Stylesheet_Metadata) is
   begin
      Ensure_Impl (Source);

      Source.Impl.Static_Metadata := Metadata;
      if Source.Impl.Mode = Static_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Set_Static_Metadata;

   procedure Begin_Update (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Update_Depth := Source.Impl.Update_Depth + 1;
   end Begin_Update;

   procedure End_Update (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);

      --  An End_Update with no batch open is ignored rather than raised
      --  on: the pair is public, callers pair it across their own
      --  control flow, and turning a spare call into an exception at the
      --  point of styling would take an application down for a mistake
      --  that costs nothing. Use Update_Scope to be sure of the pairing.
      if Source.Impl.Update_Depth = 0 then
         return;
      end if;

      Source.Impl.Update_Depth := Source.Impl.Update_Depth - 1;
      if Source.Impl.Update_Depth = 0 then
         Reapply_If_Changed (Source);
      end if;
   end End_Update;

   overriding procedure Initialize (Scope : in out Update_Scope) is
   begin
      Begin_Update (Scope.Source.all);
   end Initialize;

   overriding procedure Finalize (Scope : in out Update_Scope) is
   begin
      End_Update (Scope.Source.all);
   end Finalize;

   procedure Clear_Static_Entries (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Static_Styles.Clear;
   end Clear_Static_Entries;

   procedure Add_Static_Entry (Source : in out Style_Source;
                               Entry_Value : Static_Style_Entry) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Static_Styles.Append (Entry_Value);
   end Add_Static_Entry;

   function CSS_File (Path : String) return Dynamic_Source_Entry is
     ((Kind => File_Entry, Text => To_Unbounded_String (Path)));

   function CSS_Text (Content : String) return Dynamic_Source_Entry is
     ((Kind => String_Entry, Text => To_Unbounded_String (Content)));

   --  Install_Entries commits nothing on failure, so a sheet that cannot
   --  be read is not appended either.
   procedure Append_And_Install (Source  : in out Style_Source;
                                 Item    : Dynamic_Source_Entry;
                                 Success : out Boolean) is
      Wanted : Dynamic_Entry_Vectors.Vector := Source.Impl.Entries;
   begin
      Wanted.Append (Tracked_Entry'(Source_Entry  => Item,
                                    Last_Modified => Ada.Calendar.Clock));
      Install_Entries (Source, Wanted, Success);
      if Success and then Source.Impl.Mode = Dynamic_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Append_And_Install;

   procedure Add_Dynamic_File (Source  : in out Style_Source;
                               Path    : String;
                               Success : out Boolean) is
   begin
      Ensure_Impl (Source);
      Append_And_Install (Source, CSS_File (Path), Success);
   end Add_Dynamic_File;

   procedure Add_Dynamic_String (Source      : in out Style_Source;
                                 CSS_Content : String;
                                 Success     : out Boolean) is
   begin
      Ensure_Impl (Source);
      Append_And_Install (Source, CSS_Text (CSS_Content), Success);
   end Add_Dynamic_String;

   procedure Set_Dynamic_Sources
     (Source  : in out Style_Source;
      Entries : Dynamic_Source_Entry_Array;
      Success : out Boolean)
   is
      Wanted : Dynamic_Entry_Vectors.Vector;
   begin
      Ensure_Impl (Source);

      if Entries'Length = 0 then
         Clear_Dynamic_Entries (Source);
         Success := True;
         --  Publishing in Static_Mode would restyle for a change the
         --  widgets cannot see.
         if Source.Impl.Mode = Dynamic_Mode then
            Reapply_If_Changed (Source);
         end if;
         return;
      end if;

      for E of Entries loop
         Wanted.Append (Tracked_Entry'(Source_Entry  => E,
                                       Last_Modified => Ada.Calendar.Clock));
      end loop;

      Install_Entries (Source, Wanted, Success);
      if Success and then Source.Impl.Mode = Dynamic_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Set_Dynamic_Sources;

   procedure Clear_Dynamic_Entries (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Entries.Clear;
      Source.Impl.Dynamic_Loaded := False;
      --  Nothing is loaded now, and saying so is what makes the next
      --  Set_Mode notice that the widgets are styled from a sheet this
      --  source no longer has.
      Source.Impl.Dynamic_Text := Null_Unbounded_String;
   end Clear_Dynamic_Entries;

   procedure Reload_Dynamic (Source  : in out Style_Source;
                             Success : out Boolean) is
   begin
      Ensure_Impl (Source);
      Reload_All_Dynamic (Source, Success);
      if Success then
         Reapply_If_Changed (Source);
      end if;
   end Reload_Dynamic;

   procedure Set_Auto_Reload (Source : in out Style_Source;
                              Enabled : Boolean) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Auto_Reload := Enabled;
   end Set_Auto_Reload;

   function Auto_Reload_Enabled (Source : Style_Source) return Boolean is
   begin
      if Source.Impl = null then
         return True;
      end if;
      return Source.Impl.Auto_Reload;
   end Auto_Reload_Enabled;

   procedure Set_Mode (Source  : in out Style_Source;
                       Mode    : Source_Mode;
                       Success : out Boolean)
   is
   begin
      Ensure_Impl (Source);
      Success := True;

      if Mode = Dynamic_Mode
        and then not Source.Impl.Dynamic_Loaded
        and then not Source.Impl.Entries.Is_Empty
      then
         Reload_All_Dynamic (Source, Success);
         if not Success then
            return;
         end if;
      end if;

      Source.Impl.Mode := Mode;
      Reapply_If_Changed (Source);
   end Set_Mode;

   function Get_Mode (Source : Style_Source) return Source_Mode is
   begin
      if Source.Impl = null then
         return Dynamic_Mode;
      end if;
      return Source.Impl.Mode;
   end Get_Mode;

   procedure Tick (Source   : in out Style_Source;
                   Reloaded : out Boolean;
                   Success  : out Boolean) is
      Any_Changed : Boolean := False;
      --  The sheet that triggered the reload, so the log names it: a
      --  developer watching several has no other way to tell which.
      Changed     : Unbounded_String;
   begin
      Reloaded := False;
      Success := True;

      if Source.Impl = null then
         return;
      end if;

      --  Not gated on anything having loaded: a sheet that failed to
      --  parse is the case live reload exists for, and latching on it
      --  would stop watching the file the developer is about to fix.
      --  What makes ticking pointless is having no sheets to watch.
      if Source.Impl.Mode /= Dynamic_Mode
        or else not Source.Impl.Auto_Reload
        or else Source.Impl.Entries.Is_Empty
      then
         return;
      end if;

      --  Check all file entries for modification time changes
      for I in 1 .. Natural (Source.Impl.Entries.Length) loop
         declare
            E : constant Tracked_Entry := Source.Impl.Entries (I);
         begin
            if E.Source_Entry.Kind = File_Entry then
               declare
                  use type Ada.Calendar.Time;
                  Path : constant String := To_String (E.Source_Entry.Text);
               begin
                  --  One call rather than Exists-then-stat: a missing or
                  --  unreadable file raises here just as Exists reports
                  --  it absent, and asking twice leaves a window where
                  --  the answer changes between them. The inner block is
                  --  needed because a handler does not cover its own
                  --  declarative part.
                  declare
                     Mod_Time : constant Ada.Calendar.Time :=
                       Ada.Directories.Modification_Time (Path);
                  begin
                     if Mod_Time /= E.Last_Modified then
                        if not Any_Changed then
                           Changed := E.Source_Entry.Text;
                        end if;
                        Any_Changed := True;
                     end if;
                  end;
               exception
                  --  Nothing to compare against, and a reload would fail
                  --  on it anyway.
                  when others => null;
               end;
            end if;
         end;
      end loop;

      if Any_Changed then
         Reload_All_Dynamic (Source, Success);
         if not Success then
            --  The widgets keep the last good sheet, so nothing on screen
            --  says the edit was rejected. Restamp means this is one line
            --  per save rather than one per frame.
            Adi.Log.Error
              ("CSS " & To_String (Changed) & ": "
               & To_String (Source.Impl.Last_Error));
            return;
         end if;
         Reloaded := True;
         Adi.Log.Info ("CSS reloaded " & To_String (Changed));
         Reapply_If_Changed (Source);
      end if;
   end Tick;

   procedure Apply (Source : Style_Source;
                    Kind   : Adi.CSS_Parser.Selector_Kind;
                    Name   : String;
                    W      : in out Adi.Widget.Widget'Class) is
   begin
      Apply_To_Widget (Source, Kind, Name, W);
   end Apply;

   procedure Apply_Class (Source : Style_Source;
                          Name   : String;
                          W      : in out Adi.Widget.Widget'Class) is
   begin
      Apply (Source, Adi.CSS_Parser.Class_Selector, Name, W);
   end Apply_Class;

   procedure Apply_Id (Source : Style_Source;
                       Name   : String;
                       W      : in out Adi.Widget.Widget'Class) is
   begin
      Apply (Source, Adi.CSS_Parser.Id_Selector, Name, W);
   end Apply_Id;

   procedure Apply_Tag (Source : Style_Source;
                        Name   : String;
                        W      : in out Adi.Widget.Widget'Class) is
   begin
      Apply (Source, Adi.CSS_Parser.Tag_Selector, Name, W);
   end Apply_Tag;

   procedure Apply_Root_Metadata
     (Source : Style_Source;
      W      : in out Adi.Widget.Widget'Class) is
   begin
      Apply_Root_Metadata_Impl (Source, W);
   end Apply_Root_Metadata;

   procedure Apply_Selector_Set (Source     : Style_Source;
                                 W          : in out Adi.Widget.Widget'Class;
                                 Tag_Name   : String := "";
                                 Class_Name : String := "";
                                 Id_Name    : String := "") is
   begin
      Apply_Selector_Set_To_Widget (Source, W, Tag_Name, Class_Name, Id_Name);
   end Apply_Selector_Set;

   procedure Bind (Source : in out Style_Source;
                   Kind   : Adi.CSS_Parser.Selector_Kind;
                   Name   : String;
                   W      : access Adi.Widget.Widget'Class) is
   begin
      if W = null then
         return;
      end if;

      Ensure_Impl (Source);
      Source.Impl.Bindings.Append (Bound_Target'(
        Kind          => Single_Binding,
        Selector_Kind => Kind,
        Name          => To_Unbounded_String (Normalize_Name (Name)),
        Tag_Name      => Null_Unbounded_String,
        Class_Name    => Null_Unbounded_String,
        Id_Name       => Null_Unbounded_String,
        Target        => Adi.Widget.Get_Handle (W.all)));

      Note_Binding (Source, Source.Impl.Bindings.Last_Element);
      Apply_To_Widget (Source, Kind, Name, W.all);
   end Bind;

   function Has_Space (S : String) return Boolean is
   begin
      for C of S loop
         if C = ' ' then
            return True;
         end if;
      end loop;
      return False;
   end Has_Space;

   procedure Bind_Class (Source : in out Style_Source;
                         Name   : String;
                         W      : access Adi.Widget.Widget'Class) is
   begin
      if Has_Space (Name) then
         if W = null then
            return;
         end if;

         Ensure_Impl (Source);
         Source.Impl.Bindings.Append (Bound_Target'(
           Kind          => Multi_Class_Binding,
           Selector_Kind => Adi.CSS_Parser.Class_Selector,
           Name          => To_Unbounded_String (Name),
           Tag_Name      => Null_Unbounded_String,
           Class_Name    => Null_Unbounded_String,
           Id_Name       => Null_Unbounded_String,
           Target        => Adi.Widget.Get_Handle (W.all)));

         Note_Binding (Source, Source.Impl.Bindings.Last_Element);
         Apply_Multi_Classes (Source, Name, W.all);
      else
         Bind (Source, Adi.CSS_Parser.Class_Selector, Name, W);
      end if;
   end Bind_Class;

   procedure Bind_Id (Source : in out Style_Source;
                      Name   : String;
                      W      : access Adi.Widget.Widget'Class) is
   begin
      Bind (Source, Adi.CSS_Parser.Id_Selector, Name, W);
   end Bind_Id;

   procedure Bind_Tag (Source : in out Style_Source;
                       Name   : String;
                       W      : access Adi.Widget.Widget'Class) is
   begin
      Bind (Source, Adi.CSS_Parser.Tag_Selector, Name, W);
   end Bind_Tag;

   procedure Bind_Root_Metadata
     (Source : in out Style_Source;
      W      : access Adi.Widget.Widget'Class) is
   begin
      Ensure_Impl (Source);
      if W = null then
         return;
      end if;

      declare
         Prev     : constant Adi.Widget.Widget_Handle :=
           Source.Impl.Root_Target;
         Next     : constant Adi.Widget.Widget_Handle :=
           Adi.Widget.Get_Handle (W.all);
      begin
         Source.Impl.Root_Target := Next;

         --  Only the widget that is the root target has :root merged
         --  into its styles, so handing the role over changes the styles
         --  of the widget losing it and the one taking it, and of no
         --  other binding. Each is restyled from its own binding, so
         --  neither loses the selectors it was bound under.
         if Prev /= Next then
            Restyle (Source, Prev);
         end if;
         Restyle (Source, Next);
      end;
   end Bind_Root_Metadata;

   procedure Bind_Class (Source : in out Style_Source;
                         Name   : String;
                         W      : Adi.Widget.Widget_Handle)
   is
   begin
      declare
         R : Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
      begin
         Bind_Class (Source, Name, R.Ptr);
      end;
   exception
      when Constraint_Error =>
         null;
   end Bind_Class;

   procedure Bind_Id (Source : in out Style_Source;
                      Name   : String;
                      W      : Adi.Widget.Widget_Handle)
   is
   begin
      declare
         R : Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
      begin
         Bind_Id (Source, Name, R.Ptr);
      end;
   exception
      when Constraint_Error =>
         null;
   end Bind_Id;

   procedure Bind_Tag (Source : in out Style_Source;
                       Name   : String;
                       W      : Adi.Widget.Widget_Handle)
   is
   begin
      declare
         R : Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
      begin
         Bind_Tag (Source, Name, R.Ptr);
      end;
   exception
      when Constraint_Error =>
         null;
   end Bind_Tag;

   procedure Bind_Root_Metadata
     (Source : in out Style_Source;
      W      : Adi.Widget.Widget_Handle)
   is
   begin
      declare
         R : Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
      begin
         Bind_Root_Metadata (Source, R.Ptr);
      end;
   exception
      when Constraint_Error =>
         null;
   end Bind_Root_Metadata;

   procedure Bind_Selector_Set (Source     : in out Style_Source;
                                W          : access Adi.Widget.Widget'Class;
                                Tag_Name   : String := "";
                                Class_Name : String := "";
                                Id_Name    : String := "") is
   begin
      if W = null then
         return;
      end if;

      Ensure_Impl (Source);
      Source.Impl.Bindings.Append (Bound_Target'(
        Kind          => Selector_Set_Binding,
        Selector_Kind => Adi.CSS_Parser.Class_Selector,
        Name          => Null_Unbounded_String,
        Tag_Name      => To_Unbounded_String (Normalize_Name (Tag_Name)),
        Class_Name    => To_Unbounded_String (Normalize_Name (Class_Name)),
        Id_Name       => To_Unbounded_String (Normalize_Name (Id_Name)),
        Target        => Adi.Widget.Get_Handle (W.all)));

      Note_Binding (Source, Source.Impl.Bindings.Last_Element);
      Apply_Selector_Set_To_Widget
        (Source, W.all, Tag_Name, Class_Name, Id_Name);
   end Bind_Selector_Set;

   procedure Bind_Selector_Set (Source     : in out Style_Source;
                                W          : Adi.Widget.Widget_Handle;
                                Tag_Name   : String := "";
                                Class_Name : String := "";
                                Id_Name    : String := "")
   is
   begin
      declare
         R : Adi.Widget.Widget_Ref := Adi.Widget.Borrow (W);
      begin
         Bind_Selector_Set
           (Source     => Source,
            W          => R.Ptr,
            Tag_Name   => Tag_Name,
            Class_Name => Class_Name,
            Id_Name    => Id_Name);
      end;
   exception
      when Constraint_Error =>
         null;
   end Bind_Selector_Set;

   procedure Attach_Window
     (Source : in out Style_Source;
      W      : Adi.Window.Window_Handle)
   is
      Meta : Adi.CSS_Parser.Stylesheet_Metadata;
   begin
      Ensure_Impl (Source);
      Source.Impl.Attached_Window := W;
      Meta := Active_Metadata (Source);
      if Meta.Has_Root_Font_Size then
         Adi.Window.Set_Root_Font_Size (W, Meta.Root_Font_Size);
      end if;
   end Attach_Window;

   function Get_Metadata
     (Source : Style_Source) return Adi.CSS_Parser.Stylesheet_Metadata is
   begin
      return Active_Metadata (Source);
   end Get_Metadata;

   function Has_Custom_Property (Source : Style_Source; Name : String) return Boolean is
   begin
      if Source.Impl = null then
         return False;
      end if;

      if Source.Impl.Mode = Dynamic_Mode and then Source.Impl.Dynamic_Loaded then
         return Adi.CSS_Parser.Has_Custom_Property (Source.Impl.Sheet, Name);
      end if;

      return False;
   end Has_Custom_Property;

   function Get_Custom_Property (Source : Style_Source; Name : String) return String is
   begin
      if Source.Impl = null then
         return "";
      end if;

      if Source.Impl.Mode = Dynamic_Mode and then Source.Impl.Dynamic_Loaded then
         return Adi.CSS_Parser.Get_Custom_Property (Source.Impl.Sheet, Name);
      end if;

      return "";
   end Get_Custom_Property;

   function Get_Last_Error (Source : Style_Source) return String is
   begin
      if Source.Impl = null then
         return "";
      end if;
      return To_String (Source.Impl.Last_Error);
   end Get_Last_Error;

end Adi.CSS_Source;
