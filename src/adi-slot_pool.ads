--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  A fixed pool of payload slots, for values that live exactly the span
--  a caller holds them and belong in no store. The whole of it is one
--  array and a count: no heap, no container, no finalization and no
--  secondary stack, which is what a restricted profile asks for. An
--  instantiation carries Local_Restrictions => (No_Secondary_Stack,
--  No_Heap_Allocations) where the payload's components carry no
--  defaults, GNAT charging a payload's default-initialization procedure
--  against both; tests/src/slot_pool_test.adb instantiates under them.
--
--  A Slot names one slot and one hand-out of it. Release and a fresh
--  Acquire give the same slot a new serial, so the earlier name reads
--  as absent rather than as the new holder's value -- which is why a
--  Slot is not a plain array index.
generic
   type Payload is private;
   Capacity : Positive;
package Adi.Slot_Pool is

   subtype Slot_Index is Positive range 1 .. Capacity;
   subtype Slot_Count is Natural range 0 .. Capacity;

   type Slot is private;

   --  What a full pool answers, and what a released Slot becomes.
   No_Slot : constant Slot;

   --  No_Slot when every slot is taken. The caller then does without,
   --  as a transition that finds the pool full assigns its target
   --  outright.
   function Acquire return Slot;

   --  Returns the slot to the pool and takes S to No_Slot. A Slot the
   --  pool no longer holds under that name leaves the pool alone.
   procedure Release (S : in out Slot);

   --  Whether the pool still holds the slot S names, at the hand-out S
   --  was taken at.
   function Live (S : Slot) return Boolean;

   function Held return Slot_Count;

   --  The payload of a live slot. Constraint_Error for a slot the pool
   --  no longer holds: the pool keeps no value of its own to answer an
   --  absent slot with, so Live is what a caller asks first.
   function Get (S : Slot) return Payload;
   procedure Set (S : Slot; P : Payload);

   ---------------------------------------------------------------------------
   --  Encoding a slot into a name of one's own
   ---------------------------------------------------------------------------

   --  A Slot is the pair Named takes back. A caller carrying a slot
   --  inside a handle of its own reads the two out, packs them as it
   --  likes, and asks Named for the Slot again on the way back.
   function Ordinal (S : Slot) return Slot_Count;
   function Serial (S : Slot) return Natural;

   --  No_Slot when Ordinal names no slot of this pool, so a caller
   --  decoding an arbitrary name needs no range guard of its own.
   --
   --  The range is the whole of what Named checks. Reconstructing a pair
   --  the caller itself took from Ordinal and Serial is what it is for;
   --  a pair from anywhere else names whatever holds that ordinal now,
   --  and passes Live and reaches the payload for read and write with no
   --  Acquire behind it.
   function Named (Ordinal : Natural; Serial : Natural) return Slot;

private

   type Slot is record
      Ordinal : Slot_Count := 0;
      Serial  : Natural := 0;
   end record;

   No_Slot : constant Slot := (Ordinal => 0, Serial => 0);

   --  Serial rises each time the slot is handed out, and is what tells
   --  a Slot value naming an earlier hand-out from the current one. It
   --  is a Natural, so it never wraps onto a live hand-out: past
   --  Natural'Last Acquire raises Constraint_Error, which asks 2**31
   --  hand-outs of one slot.
   type Slot_Entry is record
      Item   : aliased Payload;
      In_Use : Boolean := False;
      Serial : Natural := 0;
   end record;

   --  Held in the private part rather than in the body, so that
   --  Adi.Slot_Pool.Refs reaches the payload in place.
   type Slot_Entries is array (Slot_Index) of Slot_Entry;

   Entries : Slot_Entries;
   Taken   : Slot_Count := 0;

end Adi.Slot_Pool;
