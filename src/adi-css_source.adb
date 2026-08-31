--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Indefinite_Hashed_Maps;

with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Log;
with Adi.Style_Merge;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Window_Bridge;
pragma Elaborate_All (Adi.Widget.Window_Bridge);
with Adi.Window;
with Ada.Exceptions;
use type Adi.Window.Window_Handle;

package body Adi.CSS_Source is

   package Char renames Ada.Characters.Handling;
   package Fix renames Ada.Strings.Fixed;
   use type Ada.Containers.Count_Type;
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

   --  Styles under a name: the static entries indexed by selector, and
   --  the combined fold indexed by the three names it reads. A
   --  Part_Style_Array is 96 bytes, so both are cheap to hold.
   package Part_Style_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Adi.Widget.Part_Style_Array,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   type Static_Index_Array is
     array (Adi.CSS_Parser.Selector_Kind) of Part_Style_Maps.Map;

   --  Distinct (tag, class list, id) triples one source answers for.
   --  At the cap the memo is dropped whole and fills again, which is
   --  what the resolved-style memo does at its own.
   Max_Combined_Memo_Entries : constant Ada.Containers.Count_Type := 4_096;

   --  The :root block a source carries. Its styles are handles, so
   --  keeping it and comparing it cost 96 bytes and a word compare.
   type Root_Fingerprint is record
      Has_Style     : Boolean := False;
      Styles        : Adi.Widget.Part_Style_Array := Adi.Widget.Empty_Part_Styles;
      Has_Font_Size : Boolean := False;
      Font_Size     : Length_Value := Default_Font_Size;
   end record;

   function Fingerprint (M : Adi.CSS_Parser.Stylesheet_Metadata)
     return Root_Fingerprint is
     ((Has_Style     => M.Has_Root_Style,
       Styles        => M.Root_Styles,
       Has_Font_Size => M.Has_Root_Font_Size,
       Font_Size     => M.Root_Font_Size));

   type Style_Source_Impl is new Source_Impl_Base with record
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
      Applied_Root     : Root_Fingerprint;
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
      Static_Root      : Root_Fingerprint;
      Static_Styles    : Entry_Vectors.Vector;

      --  The entries folded per selector, which is what Static_Mode
      --  answers a lookup from, and the fold of tag, classes and id
      --  Combined_Styles answers from in either mode.
      Static_Index     : Static_Index_Array;
      Combined_Memo    : Part_Style_Maps.Map;

      Bindings         : Binding_Vectors.Vector;
      Attached_Window  : Adi.Window.Window_Handle := Adi.Window.Null_Window_Handle;
   end record;

   type Style_Source_Impl_Ptr is access all Style_Source_Impl;

   --  What the source's handle names, or null once it is destroyed --
   --  which is what a copy of a destroyed source gets, in place of a
   --  pointer into freed memory.
   function Impl_Of (Source : Style_Source) return Style_Source_Impl_Ptr is
      P : constant Source_Impl_Access := Source_Stores.Get (Source.Id);
   begin
      if P = null then
         return null;
      end if;
      return Style_Source_Impl (P.all)'Unchecked_Access;
   end Impl_Of;

   procedure Prune_Widget (Impl : Style_Source_Impl_Ptr;
                           H    : Adi.Widget.Widget_Handle) is
   begin
      Impl.Effective.Exclude (H);

      for I in 1 .. Natural (Impl.Bindings.Length) loop
         if Impl.Bindings (I).Target = H then
            --  Order across targets carries nothing: Reapply_Bindings
            --  styles each widget from its own binding. Moving the last
            --  entry into the hole keeps a prune from sliding the tail.
            Impl.Bindings.Replace_Element (I, Impl.Bindings.Last_Element);
            Impl.Bindings.Delete_Last;
            exit;
         end if;
      end loop;

      if Impl.Root_Target = H then
         Impl.Root_Target := Adi.Widget.Null_Handle;
      end if;
   end Prune_Widget;

   procedure On_Widget_Destroyed (H : Adi.Widget.Widget_Handle) is
      procedure Prune_One (Id  : Source_Stores.Object_Id;
                           Obj : not null Source_Impl_Access) is
         pragma Unreferenced (Id);
      begin
         Prune_Widget (Style_Source_Impl (Obj.all)'Unchecked_Access, H);
      end Prune_One;

      procedure Prune_All is new Source_Stores.For_Each_Alive (Prune_One);
   begin
      Prune_All;
   end On_Widget_Destroyed;

   procedure Ensure_Impl (Source : in out Style_Source) is
   begin
      if Impl_Of (Source) = null then
         Source.Id := Source_Stores.Register (new Style_Source_Impl);
      end if;
   end Ensure_Impl;

   function Active_Metadata
     (Source : Style_Source) return Adi.CSS_Parser.Stylesheet_Metadata is
   begin
      if Impl_Of (Source) = null then
         return (others => <>);
      end if;

      if Impl_Of (Source).Mode = Dynamic_Mode and then Impl_Of (Source).Dynamic_Loaded then
         return Adi.CSS_Parser.Get_Metadata (Impl_Of (Source).Sheet);
      end if;

      return Impl_Of (Source).Static_Metadata;
   end Active_Metadata;

   procedure Apply_Root_Metadata_Impl
     (Source : Style_Source;
      W      : in out Adi.Widget.Widget'Class);

   --  Public, and every generated XML UI body calls it. The fold itself
   --  lives with Part_Style_Array, in Adi.Widget.
   function Merge_Part_Styles (Base, Override : Part_Style_Array)
     return Part_Style_Array
   is (Adi.Style_Merge.Merge (Base, Override));

   --  Fold one entry onto whatever the index holds for its name. Entries
   --  naming the same selector merge in registration order, which is the
   --  order the vector holds them in.
   procedure Index_Static_Entry (Impl : Style_Source_Impl_Ptr;
                                 E    : Static_Style_Entry)
   is
      use Part_Style_Maps;
      Key : constant String := To_String (E.Name);
      C   : constant Cursor := Impl.Static_Index (E.Kind).Find (Key);
   begin
      if Has_Element (C) then
         Impl.Static_Index (E.Kind).Replace_Element
           (C, Merge_Part_Styles (Element (C), E.Styles));
      else
         Impl.Static_Index (E.Kind).Insert
           (Key, Merge_Part_Styles (Empty_Part_Styles, E.Styles));
      end if;
   end Index_Static_Entry;

   procedure Rebuild_Static_Index (Impl : Style_Source_Impl_Ptr) is
   begin
      for K in Adi.CSS_Parser.Selector_Kind loop
         Impl.Static_Index (K).Clear;
      end loop;

      for I in 1 .. Natural (Impl.Static_Styles.Length) loop
         Index_Static_Entry (Impl, Impl.Static_Styles (I));
      end loop;
   end Rebuild_Static_Index;

   --  Combined_Styles reads the mode, the static entries and the loaded
   --  sheet, and nothing else. Every path that changes one of the three
   --  drops the memo.
   procedure Invalidate_Combined (Impl : Style_Source_Impl_Ptr) is
   begin
      if Impl /= null then
         Impl.Combined_Memo.Clear;
      end if;
   end Invalidate_Combined;

   function Selector_Styles (Source : Style_Source;
                             Kind   : Adi.CSS_Parser.Selector_Kind;
                             Name   : String) return Part_Style_Array is
      N : constant String := Normalize_Name (Name);
   begin
      if Impl_Of (Source) = null then
         return Empty_Part_Styles;
      end if;

      if Impl_Of (Source).Mode = Static_Mode then
         declare
            use Part_Style_Maps;
            C : constant Cursor :=
              Impl_Of (Source).Static_Index (Kind).Find (N);
         begin
            return (if Has_Element (C) then Element (C)
                    else Empty_Part_Styles);
         end;
      end if;

      if not Impl_Of (Source).Dynamic_Loaded then
         return Empty_Part_Styles;
      end if;

      return Adi.CSS_Parser.Styles_For (Impl_Of (Source).Sheet, Kind, Name);
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

   --  The three names in one string, self-delimiting whatever they
   --  hold: a flag per slot for whether the caller named it, then the
   --  lengths, then the text. A name the caller left out and one that
   --  normalizes to nothing are different questions, so the flags stay
   --  beside the text.
   function Memo_Key (Tag_Given, Class_Given, Id_Given : Boolean;
                      Tag_N, Class_N, Id_N : String) return String
   is ((if Tag_Given then "y" else "n")
       & (if Class_Given then "y" else "n")
       & (if Id_Given then "y" else "n")
       & Natural'Image (Tag_N'Length)
       & Natural'Image (Class_N'Length) & '|'
       & Tag_N & Class_N & Id_N);

   --  Tag first, then the classes in the order they are written, then
   --  the id. The names arrive normalized: Selector_Styles normalizes
   --  again, which changes nothing, and a lowered class list splits into
   --  the same tokens.
   function Combined_Fold (Source  : Style_Source;
                           Tag_N   : String;
                           Class_N : String;
                           Id_N    : String;
                           Has_Tag, Has_Class, Has_Id : Boolean)
     return Part_Style_Array
   is
      Result : Part_Style_Array := Empty_Part_Styles;
   begin
      if Has_Tag then
         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Tag_Selector, Tag_N));
      end if;

      --  Class_N is a space-separated list, the same as Bind_Class takes.
      if Has_Class then
         Result := Merge_Part_Styles (
           Result,
           Multi_Class_Styles (Source, Class_N));
      end if;

      if Has_Id then
         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Id_Selector, Id_N));
      end if;

      return Result;
   end Combined_Fold;

   function Combined_Styles (Source     : Style_Source;
                             Tag_Name   : String;
                             Class_Name : String;
                             Id_Name    : String) return Part_Style_Array is
      use Part_Style_Maps;
      Impl    : constant Style_Source_Impl_Ptr := Impl_Of (Source);
      Tag_N   : constant String := Normalize_Name (Tag_Name);
      Class_N : constant String := Normalize_Name (Class_Name);
      Id_N    : constant String := Normalize_Name (Id_Name);
   begin
      if Impl = null then
         return Empty_Part_Styles;
      end if;

      declare
         Key : constant String :=
           Memo_Key (Tag_Name /= "", Class_Name /= "", Id_Name /= "",
                     Tag_N, Class_N, Id_N);
         C   : constant Cursor := Impl.Combined_Memo.Find (Key);
      begin
         if Has_Element (C) then
            Adi.Widget.Note_Selector_Memo_Hit;
            return Element (C);
         end if;

         Adi.Widget.Note_Selector_Memo_Miss;

         declare
            Result : constant Part_Style_Array :=
              Combined_Fold (Source, Tag_N, Class_N, Id_N,
                             Tag_Name /= "", Class_Name /= "",
                             Id_Name /= "");
         begin
            if Impl.Combined_Memo.Length >= Max_Combined_Memo_Entries then
               Impl.Combined_Memo.Clear;
            end if;
            Impl.Combined_Memo.Include (Key, Result);
            return Result;
         end;
      end;
   end Combined_Styles;

   function Root_Merged_Styles
     (Source : Style_Source;
      Target : Adi.Widget.Widget_Handle;
      Styles : Part_Style_Array) return Part_Style_Array
   is
      Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
        Active_Metadata (Source);
   begin
      if Impl_Of (Source) /= null
        and then Adi.Widget.Is_Valid (Target)
        and then Impl_Of (Source).Root_Target = Target
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

   --  Through Combined_Styles, which folds the class list alone when it
   --  is given nothing else, so a multi-class binding shares the memo.
   procedure Apply_Multi_Classes (Source : Style_Source;
                                  Names  : String;
                                  W      : in out Adi.Widget.Widget'Class) is
   begin
      Set_Part_Styles
        (W,
         Root_Merged_Styles
           (Source,
            Adi.Widget.Get_Handle (W),
            Combined_Styles (Source, "", Names, "")));
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
   function Binding_Count (Source : Style_Source) return Natural is
     (if Impl_Of (Source) = null then 0
      else Natural (Impl_Of (Source).Bindings.Length));

   function Effective_Count (Source : Style_Source) return Natural is
     (if Impl_Of (Source) = null then 0
      else Natural (Impl_Of (Source).Effective.Length));

   function Live_Impl_Count return Natural is
      N : Natural := 0;

      procedure Count_One (Id  : Source_Stores.Object_Id;
                           Obj : not null Source_Impl_Access) is
         pragma Unreferenced (Id, Obj);
      begin
         N := N + 1;
      end Count_One;

      procedure Count_All is new Source_Stores.For_Each_Alive (Count_One);
   begin
      Count_All;
      return N;
   end Live_Impl_Count;

   function Is_Valid (Source : Style_Source) return Boolean is
     (Source_Stores.Is_Valid (Source.Id));

   procedure Destroy (Source : in out Style_Source) is
      Impl : constant Style_Source_Impl_Ptr := Impl_Of (Source);
   begin
      if Impl /= null then
         --  The dynamic sheet is the source's own; nothing else names it.
         Adi.CSS_Parser.Destroy (Impl.Sheet);
      end if;

      --  Nothing is pinned, so the store frees here rather than at a
      --  later Pump; a second call finds the handle stale and does
      --  nothing, as does a call on a copy.
      Source_Stores.Request_Destroy (Source.Id);
      Source.Id := Source_Stores.Null_Id;
   end Destroy;

   procedure Note_Binding
     (Source : in out Style_Source; B : Bound_Target) is
   begin
      Impl_Of (Source).Effective.Include (B.Target, B);
   end Note_Binding;

   --  One binding per widget, the last one winning, as Adi.CSS_Parser
   --  has always done. Bindings is the history a reload replays, and
   --  replaying an earlier binding of a widget only to overwrite it with
   --  the later one changes nothing -- while keeping both grows the
   --  vector every time a generated Build runs over the same tree.
   procedure Record_Binding
     (Source : in out Style_Source; B : Bound_Target) is
   begin
      for I in 1 .. Natural (Impl_Of (Source).Bindings.Length) loop
         if Impl_Of (Source).Bindings (I).Target = B.Target then
            Impl_Of (Source).Bindings.Replace_Element (I, B);
            Note_Binding (Source, B);
            return;
         end if;
      end loop;

      Impl_Of (Source).Bindings.Append (B);
      Note_Binding (Source, B);
   end Record_Binding;

   --  Restyle one widget from what it is currently bound under. Whether
   --  it is the root is answered by Root_Merged_Styles, so this both
   --  grants and withdraws the :root styles. A widget with no binding
   --  gets the :root styles alone, and only while it is the root: it has
   --  nothing else to restore.
   procedure Restyle (Source : in out Style_Source;
                      H      : Adi.Widget.Widget_Handle)
   is
      use Binding_Maps;
      C : constant Cursor := Impl_Of (Source).Effective.Find (H);
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
         if Impl_Of (Source).Root_Target = H then
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
      use type Entry_Vectors.Vector;
   begin
      return Impl_Of (Source).Applied_Valid
        and then Impl_Of (Source).Applied_Mode = Impl_Of (Source).Mode
        and then Impl_Of (Source).Applied_Root = Impl_Of (Source).Static_Root
        and then Impl_Of (Source).Applied_Statics = Impl_Of (Source).Static_Styles
        and then Impl_Of (Source).Applied_Text = Impl_Of (Source).Dynamic_Text
        and then Impl_Of (Source).Applied_Loaded = Impl_Of (Source).Dynamic_Loaded;
   end Same_As_Applied;

   procedure Note_Applied (Source : in out Style_Source) is
   begin
      Impl_Of (Source).Applied_Valid    := True;
      Impl_Of (Source).Applied_Mode     := Impl_Of (Source).Mode;
      Impl_Of (Source).Applied_Root     := Impl_Of (Source).Static_Root;
      Impl_Of (Source).Applied_Statics  := Impl_Of (Source).Static_Styles;
      Impl_Of (Source).Applied_Text     := Impl_Of (Source).Dynamic_Text;
      Impl_Of (Source).Applied_Loaded   := Impl_Of (Source).Dynamic_Loaded;
   end Note_Applied;

   procedure Reapply_Bindings (Source : in out Style_Source);

   --  Restyle every bound widget, but only when the configuration they
   --  were last styled from is not the one in force now. Handing a
   --  source the configuration it already has is what a generated Build
   --  does on every call, and must cost nothing.
   procedure Reapply_If_Changed (Source : in out Style_Source) is
   begin
      if Impl_Of (Source) = null
        or else Impl_Of (Source).Update_Depth > 0
        or else Same_As_Applied (Source)
      then
         return;
      end if;
      Reapply_Bindings (Source);
      Note_Applied (Source);
   end Reapply_If_Changed;

   procedure Reapply_Bindings (Source : in out Style_Source) is
   begin
      if Impl_Of (Source) = null then
         return;
      end if;

      if Adi.Widget.Is_Valid (Impl_Of (Source).Root_Target) then
         declare
            R : constant Adi.Widget.Widget_Ref :=
              Adi.Widget.Borrow (Impl_Of (Source).Root_Target);
         begin
            Apply_Root_Metadata_Impl (Source, R.Ptr.all);
         end;
      end if;

      for I in 1 .. Natural (Impl_Of (Source).Bindings.Length) loop
         declare
            B : constant Bound_Target := Impl_Of (Source).Bindings (I);
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
           and then Impl_Of (Source).Attached_Window /= Adi.Window.Null_Window_Handle
         then
            Adi.Window.Set_Root_Font_Size
              (Impl_Of (Source).Attached_Window, Meta.Root_Font_Size);
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
                        Impl_Of (Source).Last_Error :=
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
                        Impl_Of (Source).Last_Error :=
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
           (Impl_Of (Source).Sheet, To_String (Text), Load_OK);
         --  Dynamic_Mode answers out of the sheet, so a load drops what
         --  the memo folded out of the last one.
         Invalidate_Combined (Impl_Of (Source));
         if not Load_OK then
            Impl_Of (Source).Last_Error := To_Unbounded_String (
              Adi.CSS_Parser.Get_Last_Error (Impl_Of (Source).Sheet));
            Success := False;
            return;
         end if;
      end;

      Impl_Of (Source).Entries        := Fresh;
      Impl_Of (Source).Dynamic_Text   := Text;
      Impl_Of (Source).Dynamic_Loaded := True;
      Impl_Of (Source).Last_Error     := Null_Unbounded_String;
      Success := True;
   end Install_Entries;

   --  Record the modification times a failed reload saw. The entry list
   --  is unchanged -- this is what the source has looked at, not what it
   --  installed -- and without it Tick reads and parses the same broken
   --  file on every frame until someone fixes it.
   procedure Restamp (Source : in out Style_Source) is
   begin
      for I in 1 .. Natural (Impl_Of (Source).Entries.Length) loop
         declare
            E : constant Tracked_Entry := Impl_Of (Source).Entries (I);
         begin
            if E.Source_Entry.Kind = File_Entry then
               declare
                  Path : constant String := To_String (E.Source_Entry.Text);
               begin
                  Impl_Of (Source).Entries.Replace_Element (I,
                    Tracked_Entry'
                      (Source_Entry  => E.Source_Entry,
                       Last_Modified =>
                         Ada.Directories.Modification_Time (Path)));
               exception
                  --  Unstampable, so Tick keeps watching it -- which is
                  --  right for a sheet that is missing rather than broken.
                  when E : others =>
                     Adi.Log.Debug ("CSS stamp " & Path & ": "
                                    & Ada.Exceptions.Exception_Name (E));
               end;
            end if;
         end;
      end loop;
   end Restamp;

   procedure Reload_All_Dynamic (Source  : in out Style_Source;
                                 Success : out Boolean) is
   begin
      Install_Entries (Source, Impl_Of (Source).Entries, Success);
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
      Impl_Of (Source).Static_Styles.Clear;
      for E of Entries loop
         Impl_Of (Source).Static_Styles.Append (E);
      end loop;
      Rebuild_Static_Index (Impl_Of (Source));
      Invalidate_Combined (Impl_Of (Source));

      if Impl_Of (Source).Mode = Static_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Set_Static_Entries;

   procedure Set_Static_Metadata
     (Source   : in out Style_Source;
      Metadata : Adi.CSS_Parser.Stylesheet_Metadata) is
   begin
      Ensure_Impl (Source);

      Impl_Of (Source).Static_Metadata := Metadata;
      Impl_Of (Source).Static_Root     := Fingerprint (Metadata);
      if Impl_Of (Source).Mode = Static_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Set_Static_Metadata;

   procedure Begin_Update (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);
      Impl_Of (Source).Update_Depth := Impl_Of (Source).Update_Depth + 1;
   end Begin_Update;

   procedure End_Update (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);

      --  An End_Update with no batch open is ignored rather than raised
      --  on: the pair is public, callers pair it across their own
      --  control flow, and turning a spare call into an exception at the
      --  point of styling would take an application down for a mistake
      --  that costs nothing. Use Update_Scope to be sure of the pairing.
      if Impl_Of (Source).Update_Depth = 0 then
         return;
      end if;

      Impl_Of (Source).Update_Depth := Impl_Of (Source).Update_Depth - 1;
      if Impl_Of (Source).Update_Depth = 0 then
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
      Impl_Of (Source).Static_Styles.Clear;
      Rebuild_Static_Index (Impl_Of (Source));
      Invalidate_Combined (Impl_Of (Source));
   end Clear_Static_Entries;

   procedure Add_Static_Entry (Source : in out Style_Source;
                               Entry_Value : Static_Style_Entry) is
   begin
      Ensure_Impl (Source);
      Impl_Of (Source).Static_Styles.Append (Entry_Value);
      Index_Static_Entry (Impl_Of (Source), Entry_Value);
      Invalidate_Combined (Impl_Of (Source));
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
      Wanted : Dynamic_Entry_Vectors.Vector := Impl_Of (Source).Entries;
   begin
      Wanted.Append (Tracked_Entry'(Source_Entry  => Item,
                                    Last_Modified => Ada.Calendar.Clock));
      Install_Entries (Source, Wanted, Success);
      if Success and then Impl_Of (Source).Mode = Dynamic_Mode then
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
         if Impl_Of (Source).Mode = Dynamic_Mode then
            Reapply_If_Changed (Source);
         end if;
         return;
      end if;

      for E of Entries loop
         Wanted.Append (Tracked_Entry'(Source_Entry  => E,
                                       Last_Modified => Ada.Calendar.Clock));
      end loop;

      Install_Entries (Source, Wanted, Success);
      if Success and then Impl_Of (Source).Mode = Dynamic_Mode then
         Reapply_If_Changed (Source);
      end if;
   end Set_Dynamic_Sources;

   procedure Clear_Dynamic_Entries (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);
      Impl_Of (Source).Entries.Clear;
      Impl_Of (Source).Dynamic_Loaded := False;
      Invalidate_Combined (Impl_Of (Source));
      --  Nothing is loaded now, and saying so is what makes the next
      --  Set_Mode notice that the widgets are styled from a sheet this
      --  source no longer has.
      Impl_Of (Source).Dynamic_Text := Null_Unbounded_String;
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
      Impl_Of (Source).Auto_Reload := Enabled;
   end Set_Auto_Reload;

   function Auto_Reload_Enabled (Source : Style_Source) return Boolean is
   begin
      if Impl_Of (Source) = null then
         return True;
      end if;
      return Impl_Of (Source).Auto_Reload;
   end Auto_Reload_Enabled;

   procedure Set_Mode (Source  : in out Style_Source;
                       Mode    : Source_Mode;
                       Success : out Boolean)
   is
   begin
      Ensure_Impl (Source);
      Success := True;

      if Mode = Dynamic_Mode
        and then not Impl_Of (Source).Dynamic_Loaded
        and then not Impl_Of (Source).Entries.Is_Empty
      then
         Reload_All_Dynamic (Source, Success);
         if not Success then
            return;
         end if;
      end if;

      Impl_Of (Source).Mode := Mode;
      Invalidate_Combined (Impl_Of (Source));
      Reapply_If_Changed (Source);
   end Set_Mode;

   function Get_Mode (Source : Style_Source) return Source_Mode is
   begin
      if Impl_Of (Source) = null then
         return Dynamic_Mode;
      end if;
      return Impl_Of (Source).Mode;
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

      if Impl_Of (Source) = null then
         return;
      end if;

      --  Not gated on anything having loaded: a sheet that failed to
      --  parse is the case live reload exists for, and latching on it
      --  would stop watching the file the developer is about to fix.
      --  What makes ticking pointless is having no sheets to watch.
      if Impl_Of (Source).Mode /= Dynamic_Mode
        or else not Impl_Of (Source).Auto_Reload
        or else Impl_Of (Source).Entries.Is_Empty
      then
         return;
      end if;

      --  Check all file entries for modification time changes
      for I in 1 .. Natural (Impl_Of (Source).Entries.Length) loop
         declare
            E : constant Tracked_Entry := Impl_Of (Source).Entries (I);
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
                  when E : others =>
                     Adi.Log.Debug ("CSS watch: "
                                    & Ada.Exceptions.Exception_Name (E));
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
               & To_String (Impl_Of (Source).Last_Error));
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
      Record_Binding (Source, Bound_Target'(
        Kind          => Single_Binding,
        Selector_Kind => Kind,
        Name          => To_Unbounded_String (Normalize_Name (Name)),
        Tag_Name      => Null_Unbounded_String,
        Class_Name    => Null_Unbounded_String,
        Id_Name       => Null_Unbounded_String,
        Target        => Adi.Widget.Get_Handle (W.all)));
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
         Record_Binding (Source, Bound_Target'(
           Kind          => Multi_Class_Binding,
           Selector_Kind => Adi.CSS_Parser.Class_Selector,
           Name          => To_Unbounded_String (Name),
           Tag_Name      => Null_Unbounded_String,
           Class_Name    => Null_Unbounded_String,
           Id_Name       => Null_Unbounded_String,
           Target        => Adi.Widget.Get_Handle (W.all)));
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
           Impl_Of (Source).Root_Target;
         Next     : constant Adi.Widget.Widget_Handle :=
           Adi.Widget.Get_Handle (W.all);
      begin
         Impl_Of (Source).Root_Target := Next;

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
      Record_Binding (Source, Bound_Target'(
        Kind          => Selector_Set_Binding,
        Selector_Kind => Adi.CSS_Parser.Class_Selector,
        Name          => Null_Unbounded_String,
        Tag_Name      => To_Unbounded_String (Normalize_Name (Tag_Name)),
        Class_Name    => To_Unbounded_String (Normalize_Name (Class_Name)),
        Id_Name       => To_Unbounded_String (Normalize_Name (Id_Name)),
        Target        => Adi.Widget.Get_Handle (W.all)));
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
      Impl_Of (Source).Attached_Window := W;
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
      if Impl_Of (Source) = null then
         return False;
      end if;

      if Impl_Of (Source).Mode = Dynamic_Mode and then Impl_Of (Source).Dynamic_Loaded then
         return Adi.CSS_Parser.Has_Custom_Property (Impl_Of (Source).Sheet, Name);
      end if;

      return False;
   end Has_Custom_Property;

   function Get_Custom_Property (Source : Style_Source; Name : String) return String is
   begin
      if Impl_Of (Source) = null then
         return "";
      end if;

      if Impl_Of (Source).Mode = Dynamic_Mode and then Impl_Of (Source).Dynamic_Loaded then
         return Adi.CSS_Parser.Get_Custom_Property (Impl_Of (Source).Sheet, Name);
      end if;

      return "";
   end Get_Custom_Property;

   function Get_Last_Error (Source : Style_Source) return String is
   begin
      if Impl_Of (Source) = null then
         return "";
      end if;
      return To_String (Impl_Of (Source).Last_Error);
   end Get_Last_Error;

   function Static_Styles_Indexed
     (Source : Style_Source;
      Kind   : Adi.CSS_Parser.Selector_Kind;
      Name   : String) return Part_Style_Array
   is (Selector_Styles (Source, Kind, Name));

   function Static_Styles_Scanned
     (Source : Style_Source;
      Kind   : Adi.CSS_Parser.Selector_Kind;
      Name   : String) return Part_Style_Array
   is
      N      : constant String := Normalize_Name (Name);
      Result : Part_Style_Array := Empty_Part_Styles;
   begin
      if Impl_Of (Source) = null then
         return Empty_Part_Styles;
      end if;

      for I in 1 .. Natural (Impl_Of (Source).Static_Styles.Length) loop
         if Impl_Of (Source).Static_Styles (I).Kind = Kind
           and then To_String (Impl_Of (Source).Static_Styles (I).Name) = N
         then
            Result := Merge_Part_Styles
              (Result, Impl_Of (Source).Static_Styles (I).Styles);
         end if;
      end loop;

      return Result;
   end Static_Styles_Scanned;

   function Combined_Styles_Memoized
     (Source     : Style_Source;
      Tag_Name   : String;
      Class_Name : String;
      Id_Name    : String) return Part_Style_Array
   is (Combined_Styles (Source, Tag_Name, Class_Name, Id_Name));

   function Combined_Styles_Uncached
     (Source     : Style_Source;
      Tag_Name   : String;
      Class_Name : String;
      Id_Name    : String) return Part_Style_Array
   is (if Impl_Of (Source) = null then Empty_Part_Styles
       else Combined_Fold
              (Source,
               Normalize_Name (Tag_Name),
               Normalize_Name (Class_Name),
               Normalize_Name (Id_Name),
               Tag_Name /= "", Class_Name /= "", Id_Name /= ""));

   function Combined_Memo_Count (Source : Style_Source) return Natural is
     (if Impl_Of (Source) = null then 0
      else Natural (Impl_Of (Source).Combined_Memo.Length));

   function Max_Combined_Memo return Natural is
     (Natural (Max_Combined_Memo_Entries));

begin
   Adi.Widget.Window_Bridge.Install_Destroy_Notice
     (On_Widget_Destroyed'Access);
end Adi.CSS_Source;
