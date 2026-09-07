--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
with Adi.Handle_Store;

--  An Owner keeps the object and is the only thing that can end it; a
--  Handle names it without keeping it. Releasing the last Owner reclaims
--  the object and retires its slot, so every Handle goes stale at once.
--  Owners are counted between themselves; a Handle never counts. Owners,
--  and the release they perform on leaving scope, belong to the render
--  thread: nothing here locks.
generic
   type Object_Type is abstract tagged limited private;
   type Object_Access is access all Object_Type'Class;

   --  Empty the object of what it holds. Called once, in one of two
   --  places, and told apart by whether the object ever reached the
   --  store:
   --
   --    * On the last release. The object has a slot, and that slot is
   --      retired afterwards -- including when this raises, since the
   --      owner that would have tried again is already spent. The
   --      exception reaches whoever released.
   --
   --    * On an object Register could not hand over. There is no slot to
   --      retire and no owner to return, so this is only a courtesy
   --      before the storage goes. A failure here is discarded rather
   --      than replacing the one that stopped registration.
   with procedure Reclaim (Obj : in out Object_Type'Class);
package Adi.Owned_Handle_Store is

   ---------------------------------------------------------------------------
   --  Weak reference
   ---------------------------------------------------------------------------

   type Handle is private;
   Null_Handle : constant Handle;

   --  Whether the object is still there. False for a handle that never
   --  named one, and for one whose owners have all gone.
   function Is_Valid (H : Handle) return Boolean;

   --  The object, or null when the handle names nothing. Callers answer
   --  a null with whatever an absent object means to them rather than
   --  raising.
   function Resolve (H : Handle) return Object_Access;

   ---------------------------------------------------------------------------
   --  Strong reference
   ---------------------------------------------------------------------------

   type Owner is new Ada.Finalization.Controlled with private;

   --  Take ownership of a freshly allocated object. The store takes the
   --  record; this owner is the first, and until it is released the
   --  object stays.
   function Register (Obj : not null Object_Access) return Owner;

   --  A view that does not own. Copy it freely.
   function View (O : Owner) return Handle;

   --  The object, or null for an owner of nothing.
   function Resolve (O : Owner) return Object_Access;

   function Is_Owned (O : Owner) return Boolean;

   --  Give up this owner's share. The last one out reclaims the object
   --  and retires its slot. Leaves O owning nothing; releasing that
   --  again is no work.
   --
   --  Call this to end an object at a chosen moment. Removing an owner
   --  from a container is not that moment: when a container finalises
   --  the values it drops is its own affair, and the standard says
   --  nothing about it, so an owner held in one is released before it
   --  is removed rather than by removing it.
   procedure Release (O : in out Owner);

private

   package Stores is new Adi.Handle_Store (Object_Type, Object_Access);

   type Handle is record
      Id : Stores.Object_Id := Stores.Null_Id;
   end record;

   Null_Handle : constant Handle := (Id => Stores.Null_Id);

   --  Shared between an object's owners, so that a copy taken through a
   --  container's assignment is counted like any other.
   type Control_Block is record
      Id     : Stores.Object_Id := Stores.Null_Id;
      Strong : Natural := 0;
   end record;

   type Control_Access is access Control_Block;

   type Owner is new Ada.Finalization.Controlled with record
      Ctrl : Control_Access := null;
   end record;

   overriding procedure Adjust (O : in out Owner);
   overriding procedure Finalize (O : in out Owner);

end Adi.Owned_Handle_Store;
