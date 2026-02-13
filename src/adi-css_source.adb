pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Vectors;
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

   type Binding_Kind is (Single_Binding, Selector_Set_Binding);

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

   type Style_Source_Impl is record
      Mode          : Source_Mode := Dynamic_Mode;
      Auto_Reload   : Boolean := True;
      Dynamic_Path  : Unbounded_String;
      Dynamic_Loaded : Boolean := False;
      Sheet         : Adi.CSS_Parser.Stylesheet;
      Last_Error    : Unbounded_String;
      Static_Styles : Entry_Vectors.Vector;
      Bindings      : Binding_Vectors.Vector;
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
               if B.Kind = Single_Binding then
                  Apply_To_Widget (
                    Source,
                    B.Selector_Kind,
                    To_String (B.Name),
                    B.Target.all);
               else
                  Apply_Selector_Set_To_Widget (
                    Source,
                    B.Target.all,
                    To_String (B.Tag_Name),
                    To_String (B.Class_Name),
                    To_String (B.Id_Name));
               end if;
            end if;
         end;
      end loop;
   end Reapply_Bindings;

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

   procedure Set_Dynamic_File (Source  : in out Style_Source;
                               Path    : String;
                               Success : out Boolean) is
   begin
      Ensure_Impl (Source);
      Source.Impl.Dynamic_Path := To_Unbounded_String (Path);
      Adi.CSS_Parser.Load_File (Source.Impl.Sheet, Path, Success);
      Source.Impl.Dynamic_Loaded := Success;

      if Success then
         Source.Impl.Last_Error := Null_Unbounded_String;
         if Source.Impl.Mode = Dynamic_Mode then
            Reapply_Bindings (Source);
         end if;
      else
         Source.Impl.Last_Error := To_Unbounded_String (
           Adi.CSS_Parser.Get_Last_Error (Source.Impl.Sheet));
      end if;
   end Set_Dynamic_File;

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
      Loaded_OK : Boolean := True;
   begin
      Ensure_Impl (Source);
      Success := True;

      if Mode = Dynamic_Mode
        and then not Source.Impl.Dynamic_Loaded
        and then Length (Source.Impl.Dynamic_Path) > 0
      then
         Adi.CSS_Parser.Load_File (
           Source.Impl.Sheet,
           To_String (Source.Impl.Dynamic_Path),
           Loaded_OK);
         Source.Impl.Dynamic_Loaded := Loaded_OK;
         if Loaded_OK then
            Source.Impl.Last_Error := Null_Unbounded_String;
         else
            Source.Impl.Last_Error := To_Unbounded_String (
              Adi.CSS_Parser.Get_Last_Error (Source.Impl.Sheet));
            Success := False;
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

      Adi.CSS_Parser.Reload_If_Changed (
        Source.Impl.Sheet,
        Reloaded,
        Success);

      if not Success then
         Source.Impl.Last_Error := To_Unbounded_String (
           Adi.CSS_Parser.Get_Last_Error (Source.Impl.Sheet));
         return;
      end if;

      Source.Impl.Last_Error := Null_Unbounded_String;
      if Reloaded then
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

   procedure Bind_Class (Source : in out Style_Source;
                         Name   : String;
                         W      : access Adi.Widget.Widget'Class) is
   begin
      Bind (Source, Adi.CSS_Parser.Class_Selector, Name, W);
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

   function Get_Dynamic_Path (Source : Style_Source) return String is
   begin
      if Source.Impl = null then
         return "";
      end if;
      return To_String (Source.Impl.Dynamic_Path);
   end Get_Dynamic_Path;

end Adi.CSS_Source;
