pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

with Adi.OS;
with Adi.Settings.JSON_Backend;

package body Adi.Settings is

   ---------------------------------------------------------------------------
   --  Node Type (recursive tree)
   ---------------------------------------------------------------------------

   package Node_Vectors is new Ada.Containers.Vectors
     (Positive, Node_Access);

   package Node_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (String, Node_Access);

   type Node (Kind : Value_Kind := Null_Kind) is record
      case Kind is
         when Null_Kind    => null;
         when String_Kind  => Str_Val  : Unbounded_String;
         when Integer_Kind => Int_Val  : Long_Integer;
         when Float_Kind   => Flt_Val  : Long_Float;
         when Boolean_Kind => Bool_Val : Boolean;
         when List_Kind    => List     : Node_Vectors.Vector;
         when Map_Kind     => Map      : Node_Maps.Map;
      end case;
   end record;

   procedure Free_Node is new Ada.Unchecked_Deallocation
     (Node, Node_Access);

   procedure Free_Backend is new Ada.Unchecked_Deallocation
     (Settings_Backend'Class, Backend_Access);

   --  Forward declarations
   procedure Deep_Free  (N : in out Node_Access);
   function  Deep_Clone (N : Node_Access) return Node_Access;

   ---------------------------------------------------------------------------
   --  Deep_Free - Recursively deallocate a node tree
   ---------------------------------------------------------------------------

   procedure Deep_Free (N : in out Node_Access) is
   begin
      if N = null then return; end if;

      case N.Kind is
         when List_Kind =>
            for I in 1 .. Natural (N.List.Length) loop
               declare
                  Child : Node_Access := N.List (I);
               begin
                  Deep_Free (Child);
               end;
            end loop;
            N.List.Clear;
         when Map_Kind =>
            declare
               use Node_Maps;
               C : Cursor := N.Map.First;
            begin
               while Has_Element (C) loop
                  declare
                     Child : Node_Access := Node_Maps.Element (C);
                  begin
                     Deep_Free (Child);
                  end;
                  Next (C);
               end loop;
            end;
            N.Map.Clear;
         when others => null;
      end case;

      Free_Node (N);
   end Deep_Free;

   ---------------------------------------------------------------------------
   --  Deep_Clone - Recursively copy a node tree
   ---------------------------------------------------------------------------

   function Deep_Clone (N : Node_Access) return Node_Access is
   begin
      if N = null then return null; end if;

      case N.Kind is
         when Null_Kind =>
            return new Node'(Kind => Null_Kind);
         when String_Kind =>
            return new Node'(Kind => String_Kind, Str_Val => N.Str_Val);
         when Integer_Kind =>
            return new Node'(Kind => Integer_Kind, Int_Val => N.Int_Val);
         when Float_Kind =>
            return new Node'(Kind => Float_Kind, Flt_Val => N.Flt_Val);
         when Boolean_Kind =>
            return new Node'(Kind => Boolean_Kind, Bool_Val => N.Bool_Val);
         when List_Kind =>
            declare
               Result : constant Node_Access :=
                 new Node'(Kind => List_Kind, List => <>);
            begin
               for I in 1 .. Natural (N.List.Length) loop
                  Result.List.Append (Deep_Clone (N.List (I)));
               end loop;
               return Result;
            end;
         when Map_Kind =>
            declare
               use Node_Maps;
               Result : constant Node_Access :=
                 new Node'(Kind => Map_Kind, Map => <>);
               C : Cursor := N.Map.First;
            begin
               while Has_Element (C) loop
                  Result.Map.Insert (Key (C), Deep_Clone (Node_Maps.Element (C)));
                  Next (C);
               end loop;
               return Result;
            end;
      end case;
   end Deep_Clone;

   ---------------------------------------------------------------------------
   --  Controlled Operations (Value_Holder)
   ---------------------------------------------------------------------------

   overriding procedure Adjust (H : in out Value_Holder) is
   begin
      H.Ptr := Deep_Clone (H.Ptr);
   end Adjust;

   overriding procedure Finalize (H : in out Value_Holder) is
   begin
      Deep_Free (H.Ptr);
   end Finalize;

   ---------------------------------------------------------------------------
   --  Setting_Value - Queries
   ---------------------------------------------------------------------------

   function Kind (V : Setting_Value) return Value_Kind is
   begin
      if V.H.Ptr = null then return Null_Kind; end if;
      return V.H.Ptr.Kind;
   end Kind;

   ---------------------------------------------------------------------------
   --  Setting_Value - Constructors
   ---------------------------------------------------------------------------

   function Null_Value return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with Ptr => null));
   end Null_Value;

   function To_Value (V : String) return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with
              Ptr => new Node'(Kind    => String_Kind,
                               Str_Val => To_Unbounded_String (V))));
   end To_Value;

   function To_Value (V : Long_Integer) return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with
              Ptr => new Node'(Kind => Integer_Kind, Int_Val => V)));
   end To_Value;

   function To_Value (V : Long_Float) return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with
              Ptr => new Node'(Kind => Float_Kind, Flt_Val => V)));
   end To_Value;

   function To_Value (V : Boolean) return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with
              Ptr => new Node'(Kind => Boolean_Kind, Bool_Val => V)));
   end To_Value;

   function Empty_List return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with
              Ptr => new Node'(Kind => List_Kind, List => <>)));
   end Empty_List;

   function Empty_Map return Setting_Value is
   begin
      return (H => (Ada.Finalization.Controlled with
              Ptr => new Node'(Kind => Map_Kind, Map => <>)));
   end Empty_Map;

   ---------------------------------------------------------------------------
   --  Setting_Value - Scalar Extractors
   ---------------------------------------------------------------------------

   function As_String (V : Setting_Value) return String is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= String_Kind then
         raise Constraint_Error with "Setting_Value is not a string";
      end if;
      return To_String (V.H.Ptr.Str_Val);
   end As_String;

   function As_Integer (V : Setting_Value) return Long_Integer is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Integer_Kind then
         raise Constraint_Error with "Setting_Value is not an integer";
      end if;
      return V.H.Ptr.Int_Val;
   end As_Integer;

   function As_Float (V : Setting_Value) return Long_Float is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Float_Kind then
         raise Constraint_Error with "Setting_Value is not a float";
      end if;
      return V.H.Ptr.Flt_Val;
   end As_Float;

   function As_Boolean (V : Setting_Value) return Boolean is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Boolean_Kind then
         raise Constraint_Error with "Setting_Value is not a boolean";
      end if;
      return V.H.Ptr.Bool_Val;
   end As_Boolean;

   ---------------------------------------------------------------------------
   --  Setting_Value - List Operations
   ---------------------------------------------------------------------------

   procedure Append (V : in out Setting_Value; Element : Setting_Value) is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= List_Kind then
         raise Constraint_Error with "Setting_Value is not a list";
      end if;
      V.H.Ptr.List.Append (Deep_Clone (Element.H.Ptr));
   end Append;

   function Length (V : Setting_Value) return Natural is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= List_Kind then
         raise Constraint_Error with "Setting_Value is not a list";
      end if;
      return Natural (V.H.Ptr.List.Length);
   end Length;

   function Element (V : Setting_Value; Index : Positive) return Setting_Value
   is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= List_Kind then
         raise Constraint_Error with "Setting_Value is not a list";
      end if;
      return (H => (Ada.Finalization.Controlled with
              Ptr => Deep_Clone (V.H.Ptr.List (Index))));
   end Element;

   ---------------------------------------------------------------------------
   --  Setting_Value - Map Operations
   ---------------------------------------------------------------------------

   procedure Insert
     (V : in out Setting_Value; Key : String; Element : Setting_Value) is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Map_Kind then
         raise Constraint_Error with "Setting_Value is not a map";
      end if;
      declare
         use Node_Maps;
         C : constant Cursor := V.H.Ptr.Map.Find (Key);
      begin
         if Has_Element (C) then
            declare
               Old : Node_Access := Node_Maps.Element (C);
            begin
               Deep_Free (Old);
            end;
            V.H.Ptr.Map.Replace (Key, Deep_Clone (Element.H.Ptr));
         else
            V.H.Ptr.Map.Insert (Key, Deep_Clone (Element.H.Ptr));
         end if;
      end;
   end Insert;

   function Contains (V : Setting_Value; Key : String) return Boolean is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Map_Kind then
         return False;
      end if;
      return V.H.Ptr.Map.Contains (Key);
   end Contains;

   function Get (V : Setting_Value; Key : String) return Setting_Value is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Map_Kind then
         return Null_Value;
      end if;
      if not V.H.Ptr.Map.Contains (Key) then
         return Null_Value;
      end if;
      return (H => (Ada.Finalization.Controlled with
              Ptr => Deep_Clone (V.H.Ptr.Map (Key))));
   end Get;

   function Keys (V : Setting_Value) return Key_Array is
   begin
      if V.H.Ptr = null or else V.H.Ptr.Kind /= Map_Kind then
         raise Constraint_Error with "Setting_Value is not a map";
      end if;

      declare
         use Node_Maps;
         Count  : constant Natural := Natural (V.H.Ptr.Map.Length);
         Result : Key_Array (1 .. Count);
         C      : Cursor := V.H.Ptr.Map.First;
         I      : Positive := 1;
      begin
         while Has_Element (C) loop
            Result (I) := To_Unbounded_String (Key (C));
            I := I + 1;
            Next (C);
         end loop;
         return Result;
      end;
   end Keys;

   ---------------------------------------------------------------------------
   --  Dot-Path Parsing
   ---------------------------------------------------------------------------

   type Segment_Array is array (Positive range <>) of Unbounded_String;

   function Split_Path (Key : String) return Segment_Array is
      Count : Natural := 1;
      I     : Positive := Key'First;
   begin
      --  First pass: count segments
      while I <= Key'Last loop
         if Key (I) = '\' and then I < Key'Last
           and then Key (I + 1) = '.'
         then
            I := I + 2;
         elsif Key (I) = '.' then
            Count := Count + 1;
            I := I + 1;
         else
            I := I + 1;
         end if;
      end loop;

      --  Second pass: extract segments
      declare
         Result : Segment_Array (1 .. Count);
         Seg    : Natural := 1;
         Buf    : Unbounded_String;
      begin
         I := Key'First;
         while I <= Key'Last loop
            if Key (I) = '\' and then I < Key'Last
              and then Key (I + 1) = '.'
            then
               Ada.Strings.Unbounded.Append (Buf, '.');
               I := I + 2;
            elsif Key (I) = '.' then
               Result (Seg) := Buf;
               Buf := Null_Unbounded_String;
               Seg := Seg + 1;
               I := I + 1;
            else
               Ada.Strings.Unbounded.Append (Buf, Key (I));
               I := I + 1;
            end if;
         end loop;
         Result (Seg) := Buf;
         return Result;
      end;
   end Split_Path;

   function Resolve_Parent
     (Root                : in out Setting_Value;
      Segments            : Segment_Array;
      Create_Intermediate : Boolean) return Node_Access
   is
      Current : Node_Access;
   begin
      if Root.H.Ptr = null or else Root.H.Ptr.Kind /= Map_Kind then
         if Create_Intermediate then
            declare
               Old : Node_Access := Root.H.Ptr;
            begin
               Deep_Free (Old);
            end;
            Root.H.Ptr := new Node'(Kind => Map_Kind, Map => <>);
         else
            return null;
         end if;
      end if;

      Current := Root.H.Ptr;

      for S in Segments'First .. Segments'Last - 1 loop
         declare
            Seg : constant String := To_String (Segments (S));
         begin
            if Current.Kind /= Map_Kind then
               return null;
            end if;

            if Current.Map.Contains (Seg) then
               declare
                  Child : constant Node_Access := Current.Map (Seg);
               begin
                  if Child = null or else Child.Kind /= Map_Kind then
                     if Create_Intermediate then
                        declare
                           Old : Node_Access := Current.Map (Seg);
                        begin
                           Deep_Free (Old);
                        end;
                        declare
                           New_Map : constant Node_Access :=
                             new Node'(Kind => Map_Kind, Map => <>);
                        begin
                           Current.Map.Replace (Seg, New_Map);
                           Current := New_Map;
                        end;
                     else
                        return null;
                     end if;
                  else
                     Current := Child;
                  end if;
               end;
            elsif Create_Intermediate then
               declare
                  New_Map : constant Node_Access :=
                    new Node'(Kind => Map_Kind, Map => <>);
               begin
                  Current.Map.Insert (Seg, New_Map);
                  Current := New_Map;
               end;
            else
               return null;
            end if;
         end;
      end loop;

      return Current;
   end Resolve_Parent;

   ---------------------------------------------------------------------------
   --  Settings_Store - Setup
   ---------------------------------------------------------------------------

   procedure Initialize
     (Store   : in out Settings_Store;
      Org     : String;
      App     : String;
      Backend : Backend_Access := null)
   is
      Dir : constant String := Adi.OS.Pref_Path (Org, App);
   begin
      --  Free previously owned backend if re-initializing
      if Store.Owns_Backend and then Store.Backend /= null then
         Free_Backend (Store.Backend);
      end if;

      Store.Path := To_Unbounded_String (Dir & "settings.json");

      if Backend = null then
         Store.Backend :=
           new Adi.Settings.JSON_Backend.JSON_Settings_Backend;
         Store.Owns_Backend := True;
      else
         Store.Backend := Backend;
         Store.Owns_Backend := False;
      end if;

      Store.Root := Empty_Map;
      Store.Loaded := False;
   end Initialize;

   ---------------------------------------------------------------------------
   --  Settings_Store - Persistence
   ---------------------------------------------------------------------------

   procedure Load (Store : in out Settings_Store) is
   begin
      if Store.Backend = null then
         raise Program_Error with
           "Settings_Store: not initialized. Call Initialize first.";
      end if;
      Store.Root := Store.Backend.Load (To_String (Store.Path));
      if Kind (Store.Root) /= Map_Kind then
         Store.Root := Empty_Map;
      end if;
      Store.Loaded := True;
   end Load;

   procedure Save (Store : in out Settings_Store) is
   begin
      if Store.Backend = null then
         raise Program_Error with
           "Settings_Store: not initialized. Call Initialize first.";
      end if;
      Store.Backend.Save (To_String (Store.Path), Store.Root);
   end Save;

   ---------------------------------------------------------------------------
   --  Settings_Store - Getters
   ---------------------------------------------------------------------------

   function Get
     (Store : Settings_Store; Key : String) return Setting_Value
   is
      Segs : constant Segment_Array := Split_Path (Key);
   begin
      if Segs'Length = 0 then return Null_Value; end if;

      declare
         Current : Node_Access := Store.Root.H.Ptr;
      begin
         if Current = null or else Current.Kind /= Map_Kind then
            return Null_Value;
         end if;

         for S in Segs'First .. Segs'Last - 1 loop
            declare
               Seg : constant String := To_String (Segs (S));
            begin
               if Current.Kind /= Map_Kind
                 or else not Current.Map.Contains (Seg)
               then
                  return Null_Value;
               end if;
               Current := Current.Map (Seg);
               if Current = null then return Null_Value; end if;
            end;
         end loop;

         declare
            Leaf_Key : constant String := To_String (Segs (Segs'Last));
         begin
            if Current.Kind /= Map_Kind
              or else not Current.Map.Contains (Leaf_Key)
            then
               return Null_Value;
            end if;
            return (H => (Ada.Finalization.Controlled with
                    Ptr => Deep_Clone (Current.Map (Leaf_Key))));
         end;
      end;
   end Get;

   function Contains (Store : Settings_Store; Key : String) return Boolean is
      Segs : constant Segment_Array := Split_Path (Key);
   begin
      if Segs'Length = 0 then return False; end if;

      declare
         Current : Node_Access := Store.Root.H.Ptr;
      begin
         if Current = null or else Current.Kind /= Map_Kind then
            return False;
         end if;

         for S in Segs'First .. Segs'Last - 1 loop
            declare
               Seg : constant String := To_String (Segs (S));
            begin
               if Current.Kind /= Map_Kind
                 or else not Current.Map.Contains (Seg)
               then
                  return False;
               end if;
               Current := Current.Map (Seg);
               if Current = null then return False; end if;
            end;
         end loop;

         return Current.Kind = Map_Kind
           and then Current.Map.Contains
                      (To_String (Segs (Segs'Last)));
      end;
   end Contains;

   function Get_String
     (Store : Settings_Store; Key : String;
      Default : String := "") return String
   is
      V : constant Setting_Value := Store.Get (Key);
   begin
      if Kind (V) = String_Kind then
         return As_String (V);
      else
         return Default;
      end if;
   end Get_String;

   function Get_Integer
     (Store : Settings_Store; Key : String;
      Default : Long_Integer := 0) return Long_Integer
   is
      V : constant Setting_Value := Store.Get (Key);
   begin
      if Kind (V) = Integer_Kind then
         return As_Integer (V);
      else
         return Default;
      end if;
   end Get_Integer;

   function Get_Float
     (Store : Settings_Store; Key : String;
      Default : Long_Float := 0.0) return Long_Float
   is
      V : constant Setting_Value := Store.Get (Key);
   begin
      if Kind (V) = Float_Kind then
         return As_Float (V);
      else
         return Default;
      end if;
   end Get_Float;

   function Get_Boolean
     (Store : Settings_Store; Key : String;
      Default : Boolean := False) return Boolean
   is
      V : constant Setting_Value := Store.Get (Key);
   begin
      if Kind (V) = Boolean_Kind then
         return As_Boolean (V);
      else
         return Default;
      end if;
   end Get_Boolean;

   ---------------------------------------------------------------------------
   --  Settings_Store - Setters
   ---------------------------------------------------------------------------

   procedure Set_Internal
     (Store : in out Settings_Store; Key : String; N : Node_Access)
   is
      Segs : constant Segment_Array := Split_Path (Key);
   begin
      if Segs'Length = 0 then
         declare
            Tmp : Node_Access := N;
         begin
            Deep_Free (Tmp);
         end;
         return;
      end if;

      declare
         Parent : constant Node_Access :=
           Resolve_Parent (Store.Root, Segs, Create_Intermediate => True);
         Leaf_Key : constant String := To_String (Segs (Segs'Last));
      begin
         if Parent = null or else Parent.Kind /= Map_Kind then
            declare
               Tmp : Node_Access := N;
            begin
               Deep_Free (Tmp);
            end;
            return;
         end if;

         if Parent.Map.Contains (Leaf_Key) then
            declare
               Old : Node_Access := Parent.Map (Leaf_Key);
            begin
               Deep_Free (Old);
            end;
            Parent.Map.Replace (Leaf_Key, N);
         else
            Parent.Map.Insert (Leaf_Key, N);
         end if;
      end;
   end Set_Internal;

   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : String) is
   begin
      Set_Internal (Store, Key,
        new Node'(Kind => String_Kind,
                  Str_Val => To_Unbounded_String (Value)));
   end Set;

   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Long_Integer) is
   begin
      Set_Internal (Store, Key,
        new Node'(Kind => Integer_Kind, Int_Val => Value));
   end Set;

   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Long_Float) is
   begin
      Set_Internal (Store, Key,
        new Node'(Kind => Float_Kind, Flt_Val => Value));
   end Set;

   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Boolean) is
   begin
      Set_Internal (Store, Key,
        new Node'(Kind => Boolean_Kind, Bool_Val => Value));
   end Set;

   procedure Set (Store : in out Settings_Store;
                  Key : String; Value : Setting_Value) is
   begin
      Set_Internal (Store, Key, Deep_Clone (Value.H.Ptr));
   end Set;

   ---------------------------------------------------------------------------
   --  Settings_Store - Remove / Clear
   ---------------------------------------------------------------------------

   procedure Remove (Store : in out Settings_Store; Key : String) is
      Segs : constant Segment_Array := Split_Path (Key);
   begin
      if Segs'Length = 0 then return; end if;

      declare
         Current : Node_Access := Store.Root.H.Ptr;
      begin
         if Current = null or else Current.Kind /= Map_Kind then
            return;
         end if;

         for S in Segs'First .. Segs'Last - 1 loop
            declare
               Seg : constant String := To_String (Segs (S));
            begin
               if Current.Kind /= Map_Kind
                 or else not Current.Map.Contains (Seg)
               then
                  return;
               end if;
               Current := Current.Map (Seg);
               if Current = null then return; end if;
            end;
         end loop;

         declare
            Leaf_Key : constant String := To_String (Segs (Segs'Last));
         begin
            if Current.Kind = Map_Kind
              and then Current.Map.Contains (Leaf_Key)
            then
               declare
                  Old : Node_Access := Current.Map (Leaf_Key);
               begin
                  Deep_Free (Old);
               end;
               Current.Map.Delete (Leaf_Key);
            end if;
         end;
      end;
   end Remove;

   procedure Clear (Store : in out Settings_Store) is
   begin
      Store.Root := Empty_Map;
   end Clear;

   ---------------------------------------------------------------------------
   --  Settings_Store - Query
   ---------------------------------------------------------------------------

   function Is_Loaded (Store : Settings_Store) return Boolean is
   begin
      return Store.Loaded;
   end Is_Loaded;

   function File_Path (Store : Settings_Store) return String is
   begin
      return To_String (Store.Path);
   end File_Path;

   ---------------------------------------------------------------------------
   --  Settings_Store - Finalize (free owned backend)
   ---------------------------------------------------------------------------

   overriding procedure Finalize (Store : in out Settings_Store) is
   begin
      if Store.Owns_Backend and then Store.Backend /= null then
         Free_Backend (Store.Backend);
      end if;
   end Finalize;

end Adi.Settings;
