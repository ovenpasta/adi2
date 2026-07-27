--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Signal is

   Initial_Capacity : constant := 4;

   procedure Grow (S : in out Signal) is
      New_Cap : constant Positive :=
        (if S.Slots = null then Initial_Capacity
         else S.Slots'Length * 2);
      New_Arr : constant Slot_Array_Access := new Slot_Array (1 .. New_Cap);
   begin
      if S.Slots /= null then
         New_Arr (1 .. S.Count) := S.Slots (1 .. S.Count);
         Free (S.Slots);
      end if;
      S.Slots := New_Arr;
   end Grow;

   -------------
   -- Connect --
   -------------

   function Connect
     (S  : in out Signal;
      CB : Callback_Type) return Connection_Id
   is
      Id : Connection_Id;
   begin
      if CB = Null_Callback then
         return No_Connection;
      end if;
      Id := S.Next_Id;
      S.Next_Id := S.Next_Id + 1;
      --  Always append — never reuse interior slots. This preserves the
      --  emit-during-modify invariant: For_Each snapshots Count at entry,
      --  so new connects land beyond the snapshot and won't fire.
      if S.Slots = null or else S.Count >= S.Slots'Length then
         Grow (S);
      end if;
      S.Count := S.Count + 1;
      S.Slots (S.Count) := Slot'(CB => CB, Id => Id, Active => True);
      return Id;
   end Connect;

   procedure Connect
     (S  : in out Signal;
      CB : Callback_Type)
   is
      Unused : constant Connection_Id := S.Connect (CB);
   begin
      null;
   end Connect;

   --------------------
   -- Connect_Unique --
   --------------------

   function Connect_Unique
     (S  : in out Signal;
      CB : Callback_Type) return Connection_Id
   is
   begin
      if CB = Null_Callback then
         return No_Connection;
      end if;
      --  Scan for an existing active slot with the same callback.
      for I in 1 .. S.Count loop
         if S.Slots (I).Active and then S.Slots (I).CB = CB then
            return S.Slots (I).Id;
         end if;
      end loop;
      --  Not found — delegate to regular Connect.
      return S.Connect (CB);
   end Connect_Unique;

   procedure Connect_Unique
     (S  : in out Signal;
      CB : Callback_Type)
   is
      Unused : constant Connection_Id := S.Connect_Unique (CB);
   begin
      null;
   end Connect_Unique;

   ----------------
   -- Disconnect --
   ----------------

   procedure Disconnect
     (S  : in out Signal;
      Id : Connection_Id)
   is
   begin
      if Id = No_Connection or else S.Slots = null then
         return;
      end if;
      for I in 1 .. S.Count loop
         if S.Slots (I).Active and then S.Slots (I).Id = Id then
            S.Slots (I) := Slot'(CB     => Null_Callback,
                                 Id     => No_Connection,
                                 Active => False);
            --  Compact trailing tombstones so Connect can reuse space.
            while S.Count > 0
              and then not S.Slots (S.Count).Active
            loop
               S.Count := S.Count - 1;
            end loop;
            return;
         end if;
      end loop;
   end Disconnect;

   --------------------
   -- Disconnect_All --
   --------------------

   procedure Disconnect_All (S : in out Signal) is
   begin
      --  Tombstone every slot instead of freeing the array: an
      --  in-progress For_Each (a callback may call Disconnect_All on
      --  the signal that is emitting) still dereferences its snapshot
      --  range and skips inactive slots. The array is reclaimed by
      --  Finalize.
      if S.Slots /= null then
         for I in 1 .. S.Count loop
            S.Slots (I) := Slot'(CB     => Null_Callback,
                                 Id     => No_Connection,
                                 Active => False);
         end loop;
      end if;
      S.Count := 0;
   end Disconnect_All;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (S : in out Signal) is
   begin
      if S.Slots /= null then
         Free (S.Slots);
      end if;
      S.Count := 0;
   end Finalize;

   ----------------------
   -- Subscriber_Count --
   ----------------------

   function Subscriber_Count (S : Signal) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. S.Count loop
         if S.Slots (I).Active then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Subscriber_Count;

   --------------
   -- For_Each --
   --------------

   procedure For_Each (S : Signal) is
      --  Snapshot length and the id watermark at entry. Disconnects set
      --  the tombstone immediately, and we re-check Active each
      --  iteration. The length snapshot alone is not enough to keep
      --  connects made during the emit from firing: a disconnect (or
      --  Disconnect_All) can shrink Count mid-emit, letting a new
      --  connection land inside the snapshotted range. Ids are
      --  monotonic and never reused, so skipping any slot whose id is
      --  at or above the entry watermark filters those out wherever
      --  they land.
      Len     : constant Natural := S.Count;
      Snap_Id : constant Connection_Id := S.Next_Id;
   begin
      for I in 1 .. Len loop
         if S.Slots (I).Active and then S.Slots (I).Id < Snap_Id then
            Visitor (S.Slots (I).CB);
         end if;
      end loop;
   end For_Each;

end Adi.Signal;
