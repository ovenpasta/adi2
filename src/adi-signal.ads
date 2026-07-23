--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

generic
   type Callback_Type is private;
   Null_Callback : Callback_Type;
package Adi.Signal is

   ---------------------------------------------------------------------------
   --  Multi-subscriber signal
   --
   --  A signal holds a list of callbacks. Connect adds subscribers,
   --  Disconnect removes by ID. For_Each iterates active subscribers
   --  (widgets instantiate it with a local visitor that captures emit args).
   --
   --  Connection_Id is a monotonic counter — never reused, never invalidated
   --  by other connect/disconnect operations. Tombstone-based: disconnect
   --  marks a slot inactive; For_Each skips it. Disconnect compacts
   --  trailing tombstones to reclaim space for future connects.
   --  Connecting a null callback is a no-op (returns No_Connection).
   --
   --  Emit-during-modify safety: For_Each snapshots Length at entry.
   --  Connects during emit append beyond snapshot range (fire next emit).
   --  Disconnects during emit tombstone immediately (skipped by iteration).
   ---------------------------------------------------------------------------

   type Signal is tagged limited private;

   type Connection_Id is private;
   No_Connection : constant Connection_Id;

   --  Subscribe a handler. Returns an ID for later disconnection.
   function Connect
     (S  : in out Signal;
      CB : Callback_Type) return Connection_Id;

   --  Subscribe without caring about the ID.
   procedure Connect
     (S  : in out Signal;
      CB : Callback_Type);

   --  Subscribe only if CB is not already connected. Returns the existing
   --  ID when a duplicate is found, or a new ID when freshly connected.
   function Connect_Unique
     (S  : in out Signal;
      CB : Callback_Type) return Connection_Id;

   --  Subscribe only if CB is not already connected (procedure form).
   procedure Connect_Unique
     (S  : in out Signal;
      CB : Callback_Type);

   --  Remove a subscription by ID. Safe to call with No_Connection
   --  or an already-disconnected ID (no-op in both cases).
   procedure Disconnect
     (S  : in out Signal;
      Id : Connection_Id);

   --  Remove all subscriptions.
   procedure Disconnect_All (S : in out Signal);

   --  Number of active (non-tombstone) subscribers.
   function Subscriber_Count (S : Signal) return Natural;

   --  Iterate active subscribers. Each emit site instantiates this with
   --  a local Visitor that captures the emit arguments and calls each CB.
   generic
      with procedure Visitor (CB : Callback_Type);
   procedure For_Each (S : Signal);

private

   type Connection_Id is new Natural;
   No_Connection : constant Connection_Id := 0;

   type Slot is record
      CB     : Callback_Type := Null_Callback;
      Id     : Connection_Id := No_Connection;
      Active : Boolean := False;
   end record;

   --  Plain array storage — no Ada container tampering checks, so
   --  connect/disconnect during For_Each iteration is safe.
   type Slot_Array is array (Positive range <>) of Slot;
   type Slot_Array_Access is access Slot_Array;

   procedure Free is new Ada.Unchecked_Deallocation
     (Slot_Array, Slot_Array_Access);

   type Signal is tagged limited record
      Slots   : Slot_Array_Access := null;
      Count   : Natural := 0;     --  High-water slot index
      Next_Id : Connection_Id := 1;
   end record;

end Adi.Signal;
