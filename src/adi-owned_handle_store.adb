--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body Adi.Owned_Handle_Store is

   procedure Free_Control is
     new Ada.Unchecked_Deallocation (Control_Block, Control_Access);

   procedure Free_Object is
     new Ada.Unchecked_Deallocation (Object_Type'Class, Object_Access);

   ---------------------------------------------------------------------------
   --  Weak reference
   ---------------------------------------------------------------------------

   function Is_Valid (H : Handle) return Boolean
   is (Stores.Is_Valid (H.Id));

   --  The store is strict: asking it for a retired id raises rather than
   --  answering, so validity is established before the ask.
   function Resolve (H : Handle) return Object_Access
   is (if Stores.Is_Valid (H.Id) then Stores.Get (H.Id) else null);

   ---------------------------------------------------------------------------
   --  Strong reference
   ---------------------------------------------------------------------------

   function Register (Obj : not null Object_Access) return Owner is
      Ctrl  : Control_Access := null;
      Owned : Object_Access := Obj;
   begin
      --  Allocated here rather than above, so that a failure has this
      --  handler to reach: until the store takes the object, nothing
      --  else is in a position to end it.
      Ctrl := new Control_Block;
      Ctrl.Id := Stores.Register (Owned);
      Owned := null;
      Ctrl.Strong := 1;
      return (Ada.Finalization.Controlled with Ctrl => Ctrl);
   exception
      when others =>
         if Owned /= null then
            --  Emptying the object is a courtesy on the way out; the
            --  storage has to go either way, and a failure here is not
            --  the answer to whether Register worked.
            begin
               Reclaim (Owned.all);
            exception
               when others =>
                  null;
            end;
            Free_Object (Owned);
         end if;
         Free_Control (Ctrl);
         raise;
   end Register;

   function View (O : Owner) return Handle
   is (if O.Ctrl = null then Null_Handle else (Id => O.Ctrl.Id));

   function Resolve (O : Owner) return Object_Access
   is (if O.Ctrl = null then null else Resolve (Handle'(Id => O.Ctrl.Id)));

   function Is_Owned (O : Owner) return Boolean
   is (O.Ctrl /= null and then Stores.Is_Valid (O.Ctrl.Id));

   procedure Release (O : in out Owner) is
   begin
      Finalize (O);
   end Release;

   ---------------------------------------------------------------------------
   --  Controlled operations
   ---------------------------------------------------------------------------

   overriding procedure Adjust (O : in out Owner) is
   begin
      if O.Ctrl /= null then
         O.Ctrl.Strong := O.Ctrl.Strong + 1;
      end if;
   end Adjust;

   overriding procedure Finalize (O : in out Owner) is
      Ctrl : Control_Access := O.Ctrl;
      Obj  : Object_Access;
   begin
      --  Detached first, so that a second finalisation of the same owner
      --  -- which the language permits -- finds nothing to give up.
      O.Ctrl := null;

      if Ctrl = null then
         return;
      end if;

      Ctrl.Strong := Ctrl.Strong - 1;
      if Ctrl.Strong > 0 then
         return;
      end if;

      --  Last one out. Empty the object before the store reclaims the
      --  record: once the slot is retired the store may reuse it, and
      --  whatever the object held would have nobody left to release it.
      Obj := Resolve (Handle'(Id => Ctrl.Id));
      if Obj /= null then
         --  Whatever Reclaim makes of the object, this owner is already
         --  spent: leaving the slot live would strand it with nobody
         --  left to retire it, and every view of it would go on
         --  resolving to a half-emptied object.
         begin
            Reclaim (Obj.all);
         exception
            when others =>
               Stores.Request_Destroy (Ctrl.Id);
               Free_Control (Ctrl);
               raise;
         end;
         Stores.Request_Destroy (Ctrl.Id);
      end if;

      Free_Control (Ctrl);
   end Finalize;

end Adi.Owned_Handle_Store;
