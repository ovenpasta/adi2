pragma Ada_2022;

with Ada.Finalization;

generic
   type Object_Type is abstract tagged limited private;
   type Object_Access is access all Object_Type'Class;
package Adi.Handle_Store is

   ---------------------------------------------------------------------------
   --  Generational ID
   ---------------------------------------------------------------------------

   type Generation is new Natural;
   type Slot_Index is new Natural;  --  0 is reserved (Null sentinel)

   type Object_Id is record
      Index : Slot_Index := 0;
      Gen   : Generation := 0;
   end record;

   Null_Id : constant Object_Id := (Index => 0, Gen => 0);

   ---------------------------------------------------------------------------
   --  Store operations (operate on the package-level global store)
   ---------------------------------------------------------------------------

   --  True when Id refers to a live, non-null slot whose generation matches.
   function Is_Valid (Id : Object_Id) return Boolean;

   --  Register a freshly allocated object.  Returns a new Id.
   function Register (Obj : not null Object_Access) return Object_Id;

   --  Retrieve the raw pointer.  Returns null for invalid / stale Ids.
   function Get (Id : Object_Id) return Object_Access;

   --  Mark for destruction.  If the slot is currently pinned the actual free
   --  is deferred until the last Unpin.
   procedure Request_Destroy (Id : Object_Id);

   --  Drain deferred destroys — call once per frame.
   procedure Pump;

   --  Strict-mode policy: when True (default), Get raises Program_Error
   --  for non-null Ids that fail validation (stale, out-of-range).
   --  Null_Id always returns null silently regardless of this setting.
   procedure Set_Strict (Value : Boolean);
   function  Is_Strict return Boolean;

   --  Reference-count style pinning (used by Object_Ref).
   procedure Pin   (Id : Object_Id);
   procedure Unpin (Id : Object_Id);

   ---------------------------------------------------------------------------
   --  Scoped borrow  (Implicit_Dereference)
   ---------------------------------------------------------------------------

   type Object_Ref (Ptr : access Object_Type'Class) is
     limited new Ada.Finalization.Limited_Controlled with private
     with Implicit_Dereference => Ptr;

   --  Pin the object for the lifetime of the returned Ref.
   --  Raises Constraint_Error when Id is Null_Id or stale.
   function Borrow (Id : Object_Id) return Object_Ref;

   ---------------------------------------------------------------------------
   --  Bulk iteration (e.g. window teardown host-nulling)
   ---------------------------------------------------------------------------

   generic
      with procedure Process (Id : Object_Id; Obj : not null Object_Access);
   procedure For_Each_Alive;

private

   type Object_Ref (Ptr : access Object_Type'Class) is
     limited new Ada.Finalization.Limited_Controlled with record
      Id : Object_Id := Null_Id;
   end record;

   overriding procedure Finalize (R : in out Object_Ref);

end Adi.Handle_Store;
