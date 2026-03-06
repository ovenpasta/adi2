pragma Ada_2022;

with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

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
      Target       : Widget_Access := null;
   end record;

   package Entry_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Static_Style_Entry);

   package Binding_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Bound_Target);

   --  Dynamic entry: either a file path or an inline CSS string
   type Dynamic_Entry_Kind is (File_Entry, String_Entry);

   type Dynamic_Entry (Kind : Dynamic_Entry_Kind := File_Entry) is record
      case Kind is
         when File_Entry =>
            Path          : Unbounded_String;
            Last_Modified : Ada.Calendar.Time;
         when String_Entry =>
            Content       : Unbounded_String;
      end case;
   end record;

   package Dynamic_Entry_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Dynamic_Entry);

   type Style_Source_Impl is record
      Mode           : Source_Mode := Dynamic_Mode;
      Auto_Reload    : Boolean := True;
      Entries        : Dynamic_Entry_Vectors.Vector;
      Dynamic_Loaded : Boolean := False;
      Sheet          : Adi.CSS_Parser.Stylesheet;
      Last_Error     : Unbounded_String;
      Static_Styles  : Entry_Vectors.Vector;
      Bindings       : Binding_Vectors.Vector;
   end record;

   procedure Ensure_Impl (Source : in out Style_Source) is
   begin
      if Source.Impl = null then
         Source.Impl := new Style_Source_Impl;
      end if;
   end Ensure_Impl;

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

      if Class_Name /= "" then
         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Class_Selector, Class_Name));
      end if;

      if Id_Name /= "" then
         Result := Merge_Part_Styles (
           Result,
           Selector_Styles (Source, Adi.CSS_Parser.Id_Selector, Id_Name));
      end if;

      return Result;
   end Combined_Styles;

   procedure Apply_To_Widget (Source : Style_Source;
                              Kind   : Adi.CSS_Parser.Selector_Kind;
                              Name   : String;
                              W      : in out Adi.Widget.Widget'Class) is
   begin
      Set_Part_Styles (W, Selector_Styles (Source, Kind, Name));
   end Apply_To_Widget;

   procedure Apply_Selector_Set_To_Widget (Source     : Style_Source;
                                           W          : in out Adi.Widget.Widget'Class;
                                           Tag_Name   : String;
                                           Class_Name : String;
                                           Id_Name    : String) is
   begin
      Set_Part_Styles (W, Combined_Styles (Source, Tag_Name, Class_Name, Id_Name));
   end Apply_Selector_Set_To_Widget;

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

   procedure Apply_Multi_Classes (Source : Style_Source;
                                  Names  : String;
                                  W      : in out Adi.Widget.Widget'Class) is
   begin
      Set_Part_Styles (W, Multi_Class_Styles (Source, Names));
   end Apply_Multi_Classes;

   procedure Reapply_Bindings (Source : in out Style_Source) is
   begin
      if Source.Impl = null then
         return;
      end if;

      for I in 1 .. Natural (Source.Impl.Bindings.Length) loop
         declare
            B : constant Bound_Target := Source.Impl.Bindings (I);
         begin
            if B.Target /= null then
               case B.Kind is
                  when Single_Binding =>
                     Apply_To_Widget (
                       Source,
                       B.Selector_Kind,
                       To_String (B.Name),
                       B.Target.all);
                  when Multi_Class_Binding =>
                     Apply_Multi_Classes (
                       Source,
                       To_String (B.Name),
                       B.Target.all);
                  when Selector_Set_Binding =>
                     Apply_Selector_Set_To_Widget (
                       Source,
                       B.Target.all,
                       To_String (B.Tag_Name),
                       To_String (B.Class_Name),
                       To_String (B.Id_Name));
               end case;
            end if;
         end;
      end loop;
   end Reapply_Bindings;

   function Read_File (Path : String) return String is
      use Ada.Directories;
      File_Size : constant Natural := Natural (Size (Path));
   begin
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

   --  Concatenate all dynamic entries and reload the stylesheet
   procedure Reload_All_Dynamic (Source  : in out Style_Source;
                                 Success : out Boolean) is
      Combined : Unbounded_String;
   begin
      Success := True;

      for I in 1 .. Natural (Source.Impl.Entries.Length) loop
         declare
            E : constant Dynamic_Entry := Source.Impl.Entries (I);
         begin
            case E.Kind is
               when File_Entry =>
                  declare
                     Path : constant String := To_String (E.Path);
                  begin
                     if Ada.Directories.Exists (Path) then
                        declare
                           Mod_Time : constant Ada.Calendar.Time :=
                             Ada.Directories.Modification_Time (Path);
                        begin
                           Source.Impl.Entries.Replace_Element (I,
                             Dynamic_Entry'(Kind          => File_Entry,
                                            Path          => E.Path,
                                            Last_Modified => Mod_Time));
                        end;
                        Append (Combined, Read_File (Path));
                        Append (Combined, ASCII.LF);
                     else
                        Source.Impl.Last_Error :=
                          To_Unbounded_String ("File not found: " & Path);
                        Success := False;
                        return;
                     end if;
                  end;
               when String_Entry =>
                  Append (Combined, E.Content);
                  Append (Combined, ASCII.LF);
            end case;
         end;
      end loop;

      declare
         Load_OK : Boolean := False;
      begin
         Adi.CSS_Parser.Load_String (
           Source.Impl.Sheet,
           To_String (Combined),
           Load_OK);
         Source.Impl.Dynamic_Loaded := Load_OK;
         if Load_OK then
            Source.Impl.Last_Error := Null_Unbounded_String;
         else
            Source.Impl.Last_Error := To_Unbounded_String (
              Adi.CSS_Parser.Get_Last_Error (Source.Impl.Sheet));
            Success := False;
         end if;
      end;
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
         Reapply_Bindings (Source);
      end if;
   end Set_Static_Entries;

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

   procedure Add_Dynamic_File (Source  : in out Style_Source;
                               Path    : String;
                               Success : out Boolean) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Entries.Append (
        Dynamic_Entry'(Kind          => File_Entry,
                       Path          => To_Unbounded_String (Path),
                       Last_Modified => Ada.Calendar.Clock));

      Reload_All_Dynamic (Source, Success);
      if Success and then Source.Impl.Mode = Dynamic_Mode then
         Reapply_Bindings (Source);
      end if;
   end Add_Dynamic_File;

   procedure Add_Dynamic_String (Source      : in out Style_Source;
                                 CSS_Content : String;
                                 Success     : out Boolean) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Entries.Append (
        Dynamic_Entry'(Kind    => String_Entry,
                       Content => To_Unbounded_String (CSS_Content)));

      Reload_All_Dynamic (Source, Success);
      if Success and then Source.Impl.Mode = Dynamic_Mode then
         Reapply_Bindings (Source);
      end if;
   end Add_Dynamic_String;

   procedure Clear_Dynamic_Entries (Source : in out Style_Source) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Entries.Clear;
      Source.Impl.Dynamic_Loaded := False;
   end Clear_Dynamic_Entries;

   procedure Reload_Dynamic (Source  : in out Style_Source;
                             Success : out Boolean) is
   begin
      Ensure_Impl (Source);
      Reload_All_Dynamic (Source, Success);
      if Success then
         Reapply_Bindings (Source);
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
                       Success : out Boolean) is
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
      Reapply_Bindings (Source);
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
   begin
      Reloaded := False;
      Success := True;

      if Source.Impl = null then
         return;
      end if;

      if Source.Impl.Mode /= Dynamic_Mode
        or else not Source.Impl.Auto_Reload
        or else not Source.Impl.Dynamic_Loaded
      then
         return;
      end if;

      --  Check all file entries for modification time changes
      for I in 1 .. Natural (Source.Impl.Entries.Length) loop
         declare
            E : constant Dynamic_Entry := Source.Impl.Entries (I);
         begin
            if E.Kind = File_Entry then
               declare
                  Path : constant String := To_String (E.Path);
               begin
                  if Ada.Directories.Exists (Path) then
                     declare
                        use type Ada.Calendar.Time;
                        Mod_Time : constant Ada.Calendar.Time :=
                          Ada.Directories.Modification_Time (Path);
                     begin
                        if Mod_Time /= E.Last_Modified then
                           Any_Changed := True;
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;

      if Any_Changed then
         Reload_All_Dynamic (Source, Success);
         if not Success then
            Source.Impl.Last_Error := To_Unbounded_String (
              Adi.CSS_Parser.Get_Last_Error (Source.Impl.Sheet));
            return;
         end if;
         Reloaded := True;
         Reapply_Bindings (Source);
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
        Target        => W.all'Unchecked_Access));

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
           Target        => W.all'Unchecked_Access));

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
        Target        => W.all'Unchecked_Access));

      Apply_Selector_Set_To_Widget (Source, W.all, Tag_Name, Class_Name, Id_Name);
   end Bind_Selector_Set;

   function Get_Last_Error (Source : Style_Source) return String is
   begin
      if Source.Impl = null then
         return "";
      end if;
      return To_String (Source.Impl.Last_Error);
   end Get_Last_Error;

end Adi.CSS_Source;
