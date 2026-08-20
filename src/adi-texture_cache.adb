--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Ordered_Maps;
with Ada.Unchecked_Deallocation;
with Adi.SDL.Render; use Adi.SDL.Render;

package body Adi.Texture_Cache is

   use type Ada.Containers.Count_Type;
   use type Adi.Clock.Time_Span;

   function "<" (L, R : Texture_Key) return Boolean is
   begin
      if L.Kind /= R.Kind then
         return L.Kind < R.Kind;
      elsif L.Source /= R.Source then
         return L.Source < R.Source;
      elsif L.Generation /= R.Generation then
         return L.Generation < R.Generation;
      elsif L.Extent_A /= R.Extent_A then
         return L.Extent_A < R.Extent_A;
      elsif L.Extent_B /= R.Extent_B then
         return L.Extent_B < R.Extent_B;
      end if;
      return L.Variant < R.Variant;
   end "<";

   --  A slot outlives the entry occupying it: eviction bumps the
   --  generation so handles issued for the old occupant stop matching,
   --  and the index goes back on the free list for the next one.
   type Slot is record
      Region    : aliased Texture_Region;
      Gen       : Slot_Generation := 1;
      Occupied  : Boolean := False;
      Pins      : Natural := 0;
      --  Evicted while borrowed: unfindable already, destroyed when the
      --  last borrow ends, and still charged until then.
      Retiring  : Boolean := False;
      Key       : Texture_Key;
      Group     : Group_Id := No_Group;
      Bytes     : Byte_Count := 0;
      Micros    : Priority := 1;
      Hits      : Natural := 1;
      Last_Used : Frame_Serial := 0;
      Standing  : Priority := 0;
   end record;

   type Slot_Access is access Slot;
   procedure Free_Slot is new Ada.Unchecked_Deallocation (Slot, Slot_Access);

   --  The table of pointers may be reallocated as it grows; the slots it
   --  points at are not, so a region borrowed from one keeps its address.
   package Slot_Vectors is new Ada.Containers.Vectors
     (Index_Type => Slot_Index, Element_Type => Slot_Access);

   package Index_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Slot_Index);

   package Key_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Texture_Key, Element_Type => Slot_Index);

   type Cache_Data is record
      Slots   : Slot_Vectors.Vector;
      Free    : Index_Vectors.Vector;
      By_Key  : Key_Maps.Map;
      Bytes   : Byte_Count := 0;
      Limit   : Byte_Count := 0;
      Frame   : Frame_Serial := 0;
      Serial  : Cache_Serial := 0;
      --  Holders of this block, and whether the cache itself has gone. A
      --  holder is a live borrow or a group that has stored here; the
      --  block is freed by whichever finishes last. A group thus keeps a
      --  dead renderer's block alive until released -- more than it
      --  needs, but not yet worth a second structure to avoid.
      Refs        : Natural := 0;
      Owner_Gone  : Boolean := False;
      --  The floor: the standing of whatever was evicted last. An entry
      --  touched afterwards is measured from here, so it competes with
      --  what has been used since rather than with its own history.
      Floor   : Priority := 0;
      Stats   : Kind_Stats_Array := [others => <>];
      Peak    : Byte_Count := 0;
   end record;

   procedure Free_Data is new Ada.Unchecked_Deallocation
     (Cache_Data, Cache_Data_Access);

   Next_Serial : Cache_Serial := 0;

   --  Practically non-repeating: modular, so values do recur in
   --  principle, but not at 2**64 in any run that finishes.
   Next_Group : Group_Id := No_Group;

   function New_Group_Id return Group_Id is
   begin
      Next_Group := Next_Group + 1;
      if Next_Group = No_Group then
         Next_Group := 1;
      end if;
      return Next_Group;
   end New_Group_Id;

   function Is_Open (G : Texture_Group) return Boolean is (G.Open);

   --  Free the block and every slot it allocated. Called by whichever
   --  holder finishes last -- the cache itself, a borrow, or a group that
   --  had stored here.
   procedure Discard (D : in out Cache_Data_Access) is
   begin
      for I in D.Slots.First_Index .. D.Slots.Last_Index loop
         declare
            S : Slot_Access := D.Slots (I);
         begin
            Free_Slot (S);
         end;
      end loop;
      Free_Data (D);
   end Discard;

   procedure Ensure (C : in out Cache) is
   begin
      if C.Owner.Data = null then
         C.Owner.Data := new Cache_Data;
         --  Slot 0 is the null sentinel and never occupied.
         C.Owner.Data.Slots.Append (new Slot);
         Next_Serial := Next_Serial + 1;
         C.Owner.Data.Serial := Next_Serial;
      end if;
   end Ensure;

   --  Microseconds of rebuilding this entry's use has saved, per byte it
   --  holds. Scaled so a ratio below one survives integer division.
   function Earned (S : Slot) return Priority is
      Saved : constant Priority :=
        Priority (S.Hits) * S.Micros * Ratio_Scale;
   begin
      if S.Bytes = 0 then
         return Saved;
      end if;
      return Saved / Priority (S.Bytes);
   end Earned;

   function Standing_Of (Floor : Priority; S : Slot) return Priority is
      Gain : constant Priority := Earned (S);
   begin
      if Gain > Priority'Last - Floor then
         return Priority'Last;
      end if;
      return Floor + Gain;
   end Standing_Of;

   --  Bring every standing down by the floor and reset it. The ordering
   --  between entries is unchanged, but the headroom is recovered: left to
   --  climb, the floor eventually pins every standing at Priority'Last,
   --  where cost and frequency stop separating anything and the policy
   --  quietly degrades to recency.
   procedure Renormalize (D : Cache_Data_Access) is
      Floor : constant Priority := D.Floor;
   begin
      for I in D.Slots.First_Index .. D.Slots.Last_Index loop
         declare
            S : constant Slot_Access := D.Slots (I);
         begin
            if S.Occupied then
               S.Standing := (if S.Standing > Floor then S.Standing - Floor
                              else 0);
            end if;
         end;
      end loop;
      D.Floor := 0;
   end Renormalize;

   --  Why an entry stopped being findable. Only Pressure reflects on the
   --  budget; the rest are the program's own doing.
   type Retire_Cause is
     (Pressure, Headroom, Replaced, Cleared, Discarded, Group_Released);

   --  Recomputed rather than tracked incrementally: an entry retired while
   --  borrowed still holds its bytes, so a decrement at retirement would
   --  disagree with what the budget is actually working against.
   procedure Note_Residency (D : Cache_Data_Access; K : Texture_Kind) is
      S : Kind_Stats renames D.Stats (K);
   begin
      if S.Bytes > S.Peak_Bytes then
         S.Peak_Bytes := S.Bytes;
      end if;
      if S.Count > S.Peak_Count then
         S.Peak_Count := S.Count;
      end if;
      if D.Bytes > D.Peak then
         D.Peak := D.Bytes;
      end if;
   end Note_Residency;

   --  Release the SDL texture and return the slot to the free list. Only
   --  called once nothing is borrowing it.
   procedure Release_Slot (D : Cache_Data_Access; Index : Slot_Index) is
      S : constant Slot_Access := D.Slots (Index);
   begin
      SDL_DestroyTexture (S.Region.Texture);
      D.Bytes := D.Bytes - S.Bytes;
      D.Stats (S.Key.Kind).Bytes := D.Stats (S.Key.Kind).Bytes - S.Bytes;
      S.all := (Gen      => S.Gen + 1,
                Occupied => False,
                others   => <>);
      D.Free.Append (Index);
   end Release_Slot;

   --  Stop an entry being found, and free it if nothing holds it. Its
   --  bytes stay charged while a borrow does, because they cannot be
   --  reused until that ends.
   procedure Retire
     (D : Cache_Data_Access; Index : Slot_Index; Why : Retire_Cause)
   is
      S : constant Slot_Access := D.Slots (Index);
   begin
      if D.By_Key.Contains (S.Key) then
         D.By_Key.Delete (S.Key);
         D.Stats (S.Key.Kind).Count := D.Stats (S.Key.Kind).Count - 1;
      end if;

      case Why is
         when Pressure  =>
            D.Stats (S.Key.Kind).Pressure := D.Stats (S.Key.Kind).Pressure + 1;
         when Headroom  =>
            D.Stats (S.Key.Kind).Headroom := D.Stats (S.Key.Kind).Headroom + 1;
         when Replaced  =>
            D.Stats (S.Key.Kind).Replaced := D.Stats (S.Key.Kind).Replaced + 1;
         when Cleared   =>
            D.Stats (S.Key.Kind).Cleared := D.Stats (S.Key.Kind).Cleared + 1;
         when Discarded =>
            D.Stats (S.Key.Kind).Discarded :=
              D.Stats (S.Key.Kind).Discarded + 1;
         when Group_Released =>
            D.Stats (S.Key.Kind).Released :=
              D.Stats (S.Key.Kind).Released + 1;
      end case;

      if S.Pins = 0 then
         Release_Slot (D, Index);
      else
         S.Retiring := True;
      end if;
   end Retire;

   --  An entry the scene is not using. Borrowed entries are in use by
   --  definition; so is anything drawn this frame or last, since the frame
   --  advances before the scene is traversed and a texture drawn in the
   --  previous frame is about to be asked for again.
   --
   --  The distance is modular, so the serial wrapping does not turn a
   --  just-used entry into an ancient one.
   function Is_Idle (D : Cache_Data_Access; S : Slot) return Boolean is
     (S.Pins = 0 and then D.Frame - S.Last_Used > 1);

   --  What the budget is measured against: entries the cache is holding
   --  on speculation, rather than ones the scene needs.
   function Idle_Bytes (D : Cache_Data_Access) return Byte_Count is
      Total : Byte_Count := 0;
   begin
      for Pos in D.By_Key.Iterate loop
         declare
            S : constant Slot_Access := D.Slots (Key_Maps.Element (Pos));
         begin
            if Is_Idle (D, S.all) then
               Total := Total + S.Bytes;
            end if;
         end;
      end loop;
      return Total;
   end Idle_Bytes;

   --  Drop the idle entry standing lowest and raise the floor to what it
   --  stood at. Scanning is affordable: it runs only when idle residency
   --  is over budget, beside the drawing that put it there, and a trim
   --  that needs several passes is one that has several entries to drop.
   procedure Evict_One
     (D       : Cache_Data_Access;
      Why     : Retire_Cause;
      Evicted : out Boolean;
      Freed   : out Byte_Count)
   is
      Victim : Slot_Index := No_Slot;
      Lowest : Priority := Priority'Last;
      Idlest : Frame_Serial := 0;
      Now    : constant Frame_Serial := D.Frame;
   begin
      Evicted := False;
      Freed   := 0;

      for Pos in D.By_Key.Iterate loop
         declare
            Index : constant Slot_Index := Key_Maps.Element (Pos);
            S     : constant Slot_Access := D.Slots (Index);
            Idle  : constant Frame_Serial := Now - S.Last_Used;
         begin
            if Is_Idle (D, S.all)
              and then (Victim = No_Slot
                        or else S.Standing < Lowest
                        or else (S.Standing = Lowest and then Idle > Idlest))
            then
               Victim := Index;
               Lowest := S.Standing;
               Idlest := Idle;
            end if;
         end;
      end loop;

      if Victim /= No_Slot then
         D.Floor := Lowest;
         Freed := D.Slots (Victim).Bytes;
         Retire (D, Victim, Why);
         Evicted := True;

         if D.Floor > Priority'Last / 2 then
            Renormalize (D);
         end if;
      end if;
   end Evict_One;

   --  Evict idle entries until idle residency is at or below Ceiling, or
   --  until nothing idle remains. Active entries are never candidates: the
   --  scene needs them, and taking one would only rebuild it next frame.
   procedure Trim_Idle (D : Cache_Data_Access; Ceiling : Byte_Count) is
      Idle    : Byte_Count := Idle_Bytes (D);
      Evicted : Boolean;
      Freed   : Byte_Count;
   begin
      while Idle > Ceiling loop
         Evict_One (D, Pressure, Evicted, Freed);
         exit when not Evicted;
         Idle := (if Freed > Idle then 0 else Idle - Freed);
      end loop;
   end Trim_Idle;

   --  Free enough for an incoming charge to be added without the total
   --  leaving what Byte_Count can hold. This is arithmetic headroom, not
   --  budget enforcement: an arriving texture is by definition active, and
   --  the budget does not apply to those.
   procedure Make_Headroom
     (D : Cache_Data_Access; Incoming : Texture_Charge)
   is
      Evicted : Boolean;
      Freed   : Byte_Count;
   begin
      while D.Bytes > Byte_Count'Last - Incoming loop
         Evict_One (D, Headroom, Evicted, Freed);
         exit when not Evicted;
      end loop;
   end Make_Headroom;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (C : Cache; H : Texture_Handle) return Boolean is
      D : constant Cache_Data_Access := C.Owner.Data;
   begin
      if D = null
        or else H.Slot = No_Slot
        or else H.Owner /= D.Serial
        or else H.Slot > D.Slots.Last_Index
      then
         return False;
      end if;

      declare
         S : constant Slot_Access := D.Slots (H.Slot);
      begin
         return S.Occupied and then not S.Retiring and then S.Gen = H.Gen;
      end;
   end Is_Valid;

   ------------
   -- Borrow --
   ------------

   function Null_Borrow return Texture_Ref is
   begin
      return (Ada.Finalization.Limited_Controlled with
              Region => Null_Region'Access,
              Data   => null,
              Slot   => No_Slot);
   end Null_Borrow;


   function Borrow (C : in out Cache; H : Texture_Handle) return Texture_Ref
   is
      D : constant Cache_Data_Access := C.Owner.Data;
   begin
      if not Is_Valid (C, H) then
         return Null_Borrow;
      end if;

      declare
         S : constant Slot_Access := D.Slots (H.Slot);
      begin
         S.Pins := S.Pins + 1;
         --  Drawing it is what using it means, so the count and the frame
         --  move here rather than in Find: a consumer that keeps a handle
         --  and borrows every frame would otherwise look untouched.
         if S.Hits < Hit_Ceiling then
            S.Hits := S.Hits + 1;
         end if;
         S.Last_Used := D.Frame;
         S.Standing := Standing_Of (D.Floor, S.all);

         D.Refs := D.Refs + 1;

         return (Ada.Finalization.Limited_Controlled with
                 Region => S.Region'Access,
                 Data   => D,
                 Slot   => H.Slot);
      end;
   end Borrow;

   overriding procedure Finalize (R : in out Texture_Ref) is
   begin
      if R.Data = null or else R.Slot = No_Slot then
         return;
      end if;

      declare
         D : Cache_Data_Access := R.Data;
         S : constant Slot_Access := D.Slots (R.Slot);
      begin
         if S.Pins > 0 then
            S.Pins := S.Pins - 1;
         end if;

         --  The eviction that happened while this borrow was open is only
         --  now able to complete.
         if S.Pins = 0 and then S.Retiring then
            Release_Slot (D, R.Slot);
         end if;

         R.Data := null;
         R.Slot := No_Slot;

         D.Refs := D.Refs - 1;

         --  Whichever of the cache and its last borrow finishes second
         --  frees the block, so a borrow can outlive the cache without
         --  reading freed memory.
         if D.Owner_Gone and then D.Refs = 0 then
            Discard (D);
         end if;
      end;
   end Finalize;

   ----------------
   -- Set_Budget --
   ----------------

   procedure Set_Budget (C : in out Cache; Bytes : Byte_Count) is
   begin
      Ensure (C);
      declare
         D : constant Cache_Data_Access := C.Owner.Data;
      begin
         D.Limit := Bytes;
         --  A budget describes what is retained now, not merely what the
         --  next store may add, so lowering it takes effect at once. It
         --  reaches only what is idle: an entry the scene is drawing is
         --  not the cache's to give back.
         Trim_Idle (D, Bytes);
      end;
   end Set_Budget;

   procedure Release (G : in out Texture_Group) is
      Doomed : Index_Vectors.Vector;
   begin
      --  Closed first, so no later store can join. Being closed is not
      --  the same as being finished: what remains to do is whatever
      --  caches are still registered, which is what makes a partial
      --  release retryable rather than lost.
      G.Open := False;

      while not G.Owners.Is_Empty loop
         declare
            D : Cache_Data_Access := G.Owners.Last_Element;
         begin
            if not D.Owner_Gone and then G.Id /= No_Group then
               --  Collected before retiring: retiring mutates the key map
               --  that would otherwise be under iteration.
               Doomed.Clear;
               for Pos in D.By_Key.Iterate loop
                  declare
                     Index : constant Slot_Index := Key_Maps.Element (Pos);
                  begin
                     if D.Slots (Index).Group = G.Id then
                        Doomed.Append (Index);
                     end if;
                  end;
               end loop;

               for I of Doomed loop
                  Retire (D, I, Group_Released);
               end loop;
            end if;

            --  Dropped only now that its members are gone. Anything that
            --  raised above leaves this cache registered, so a later
            --  release -- or finalization -- picks it up again instead of
            --  leaving its textures findable under a released group.
            G.Owners.Delete_Last;

            --  A registered group holds a reference by construction, so
            --  zero here is not a state to tolerate: it would mean the
            --  block could already have been freed, and everything above
            --  read it.
            pragma Assert (D.Refs > 0);
            D.Refs := D.Refs - 1;
            if D.Refs = 0 and then D.Owner_Gone then
               Discard (D);
            end if;
         end;
      end loop;
   end Release;

   overriding procedure Finalize (G : in out Texture_Group) is
   begin
      --  Closed but not empty is a release that did not finish; it is
      --  retried here rather than abandoned.
      if G.Open or else not G.Owners.Is_Empty then
         Release (G);
      end if;
   end Finalize;

   function Budget (C : Cache) return Byte_Count is
     (if C.Owner.Data = null then 0 else C.Owner.Data.Limit);

   -------------------
   -- Advance_Frame --
   -------------------

   procedure Advance_Frame (C : in out Cache; Frames : Positive := 1) is
      D : constant Cache_Data_Access := C.Owner.Data;
   begin
      if D /= null then
         --  The frame moves first, so what was drawn two frames ago
         --  becomes idle and is judged on this pass.
         D.Frame := D.Frame + Frame_Serial (Frames);
         Trim_Idle (D, D.Limit);
      end if;
   end Advance_Frame;

   function Frames (C : Cache) return Frame_Count is
     (if C.Owner.Data = null then 0 else C.Owner.Data.Frame);


   ----------
   -- Find --
   ----------

   function Find (C : Cache; Key : Texture_Key) return Texture_Handle
   is
      D : constant Cache_Data_Access := C.Owner.Data;
   begin
      if D = null then
         return Null_Texture;
      end if;

      declare
         Pos : constant Key_Maps.Cursor := D.By_Key.Find (Key);
      begin
         --  D is reached through an access, so counting a lookup does not
         --  need Find to take the cache in out: what changes is the block
         --  it points at, not the cache object.
         if Key_Maps.Has_Element (Pos) = False then
            D.Stats (Key.Kind).Misses := D.Stats (Key.Kind).Misses + 1;
            return Null_Texture;
         end if;

         D.Stats (Key.Kind).Hits := D.Stats (Key.Kind).Hits + 1;

         declare
            Index : constant Slot_Index := Key_Maps.Element (Pos);
            S     : constant Slot_Access := D.Slots (Index);
         begin
            --  Resolving is not using: the hit is counted when the entry
            --  is actually borrowed to be drawn.
            return (Owner => D.Serial, Slot => Index, Gen => S.Gen);
         end;
      end;
   end Find;

   -----------
   -- Store --
   -----------

   function Store
     (C          : in out Cache;
      Key        : Texture_Key;
      Texture    : SDL_Texture_Ptr;
      Width      : Natural;
      Height     : Natural;
      Bytes      : Texture_Charge;
      Build_Time : Adi.Clock.Time_Span;
      Group      : access Texture_Group'Class := null)
      return Texture_Handle
   is
      Raw    : constant Duration := Adi.Clock.To_Duration (Build_Time);
      Micros : constant Priority :=
        Priority'Max (1, Priority'Min (Micros_Ceiling,
                                       Priority (Raw * 1_000_000.0)));
      Index  : Slot_Index;
      Fresh  : Slot;
      D      : Cache_Data_Access;
   begin
      Ensure (C);
      D := C.Owner.Data;

      if Texture = null then
         return Null_Texture;
      end if;

      --  A released group is finished with, so a texture arriving for it
      --  is refused outright: joining no group would leave it resident
      --  past the decision that released its siblings, and displacing an
      --  entry on the way would be worse still. The caller keeps it.
      if Group /= null and then not Group.Is_Open then
         D.Stats (Key.Kind).Refused := D.Stats (Key.Kind).Refused + 1;
         return Null_Texture;
      end if;

      --  Replacing an entry retires the one it displaces.
      declare
         Pos : constant Key_Maps.Cursor := D.By_Key.Find (Key);
      begin
         if Key_Maps.Has_Element (Pos) then
            Retire (D, Key_Maps.Element (Pos), Replaced);
         end if;
      end;

      --  Only enough for the arithmetic to hold. A texture being stored is
      --  one the caller is about to draw, so the budget does not decide
      --  whether it may be resident; the budget trims what is idle, once a
      --  frame.
      Make_Headroom (D, Bytes);

      --  Entries in use cannot be taken, so headroom may not have been
      --  found. Refuse rather than form a total the type cannot hold: the
      --  insert would otherwise raise after the slot and key were already
      --  in place, leaving the accounting wrong.
      if D.Bytes > Byte_Count'Last - Bytes then
         D.Stats (Key.Kind).Refused := D.Stats (Key.Kind).Refused + 1;
         return Null_Texture;
      end if;

      --  Registered only now, with every refusal behind us: a group that
      --  registered and then failed to store would hold a cache it owns
      --  nothing in.
      if Group /= null then
         if Group.Id = No_Group then
            Group.Id := New_Group_Id;
         end if;
         declare
            Known : Boolean := False;
         begin
            for O of Group.Owners loop
               if O = D then
                  Known := True;
               end if;
            end loop;
            if not Known then
               Group.Owners.Append (D);
               D.Refs := D.Refs + 1;
            end if;
         end;
      end if;

      if D.Free.Is_Empty then
         D.Slots.Append (new Slot);
         Index := D.Slots.Last_Index;
      else
         Index := D.Free.Last_Element;
         D.Free.Delete_Last;
      end if;

      Fresh := D.Slots (Index).all;
      Fresh.Region := (Texture => Texture, X => 0, Y => 0,
                       Width => Width, Height => Height);
      Fresh.Occupied := True;
      Fresh.Retiring := False;
      Fresh.Pins := 0;
      Fresh.Key := Key;
      Fresh.Group := (if Group /= null and then Group.Open
                      then Group.Id else No_Group);
      Fresh.Bytes := Bytes;
      Fresh.Micros := Micros;
      Fresh.Hits := 1;
      Fresh.Last_Used := D.Frame;
      Fresh.Standing := 0;
      Fresh.Standing := Standing_Of (D.Floor, Fresh);

      D.Slots (Index).all := Fresh;
      D.By_Key.Insert (Key, Index);
      D.Bytes := D.Bytes + Bytes;

      declare
         S : Kind_Stats renames D.Stats (Key.Kind);
      begin
         S.Bytes := S.Bytes + Bytes;
         S.Count := S.Count + 1;
         S.Stores := S.Stores + 1;
         S.Build_Time := S.Build_Time + Build_Time;
      end;
      Note_Residency (D, Key.Kind);

      return (Owner => D.Serial, Slot => Index, Gen => Fresh.Gen);
   end Store;

   -----------
   -- Clear --
   -----------

   procedure Clear (C : in out Cache) is
      D : constant Cache_Data_Access := C.Owner.Data;
   begin
      if D = null then
         return;
      end if;

      while not D.By_Key.Is_Empty loop
         Retire (D, D.By_Key.First_Element, Cleared);
      end loop;
      D.Floor := 0;
   end Clear;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (O : in out Cache_Owner) is
      D : Cache_Data_Access := O.Data;
   begin
      if D = null then
         return;
      end if;
      O.Data := null;

      --  Retire everything findable first, so nothing can still be looked
      --  up while the textures are going.
      while not D.By_Key.Is_Empty loop
         Retire (D, D.By_Key.First_Element, Discarded);
      end loop;

      --  The renderer is going, so every texture goes with it, borrowed or
      --  not: leaving one alive would outlast the renderer that owns it.
      --  A borrow still open is left pointing at a null texture, which it
      --  can see, rather than at a freed one, which it cannot.
      for I in D.Slots.First_Index .. D.Slots.Last_Index loop
         if D.Slots (I).Occupied then
            SDL_DestroyTexture (D.Slots (I).Region.Texture);
            D.Slots (I).Region.Texture := null;
         end if;
      end loop;

      D.Owner_Gone := True;

      --  The bookkeeping outlives the cache when a borrow is still open;
      --  that borrow frees it.
      if D.Refs = 0 then
         Discard (D);
      end if;
   end Finalize;

   function Bytes_Used (C : Cache) return Byte_Count is
     (if C.Owner.Data = null then 0 else C.Owner.Data.Bytes);

   --  The partitions are computed here rather than tracked as entries
   --  change: an entry becomes idle because a frame passed, which is not
   --  an event anything could have counted. Scanning uses the same Is_Idle
   --  the eviction does, so the figures cannot describe a different cache
   --  from the one being trimmed.
   function Statistics (C : Cache) return Kind_Stats_Array is
      D : constant Cache_Data_Access := C.Owner.Data;
   begin
      if D = null then
         return [others => <>];
      end if;

      return Result : Kind_Stats_Array := D.Stats do
         for I in D.Slots.First_Index .. D.Slots.Last_Index loop
            declare
               S : constant Slot_Access := D.Slots (I);
               R : Kind_Stats renames Result (S.Key.Kind);
            begin
               if S.Occupied then
                  if S.Retiring then
                     R.Retired_Bytes := R.Retired_Bytes + S.Bytes;
                     R.Retired_Count := R.Retired_Count + 1;
                  elsif Is_Idle (D, S.all) then
                     R.Idle_Bytes := R.Idle_Bytes + S.Bytes;
                     R.Idle_Count := R.Idle_Count + 1;
                  else
                     R.Active_Bytes := R.Active_Bytes + S.Bytes;
                     R.Active_Count := R.Active_Count + 1;
                  end if;
               end if;
            end;
         end loop;
      end return;
   end Statistics;

   function Idle_Bytes_Used (C : Cache) return Byte_Count is
     (if C.Owner.Data = null then 0 else Idle_Bytes (C.Owner.Data));

   function Peak_Bytes_Used (C : Cache) return Byte_Count is
     (if C.Owner.Data = null then 0 else C.Owner.Data.Peak);

   function Count (C : Cache) return Natural is
     (if C.Owner.Data = null then 0
      else Natural (C.Owner.Data.By_Key.Length));

end Adi.Texture_Cache;
