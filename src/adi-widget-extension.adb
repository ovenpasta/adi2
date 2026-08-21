--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body Adi.Widget.Extension is

   procedure Free is
     new Ada.Unchecked_Deallocation (Widget'Class, Widget_Access);

   ----------------
   -- New_Widget --
   ----------------

   function New_Widget return Handle is
      --  A checked allocation, so a Custom_Widget declared deeper than
      --  the store is rejected rather than registered.
      P          : Widget_Access := new Custom_Widget;
      Registered : Boolean       := False;
      Id         : Widget_Stores.Object_Id;
   begin
      --  Before registration the widget is reachable only from here, so
      --  an exception can still release it.  Afterwards the store owns
      --  it and Destroy is the only way out.
      Set_Flag (P.all, Visible, True);
      Id := Widget_Stores.Register (P);
      Registered := True;
      P.Store_Index := Natural (Id.Index);
      P.Store_Gen   := Natural (Id.Gen);
      return (Id => Id);
   exception
      when others =>
         if not Registered then
            Free (P);
         end if;
         raise;
   end New_Widget;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (H : Handle) return Boolean
   is (Widget_Stores.Is_Valid (H.Id));

   ----------------------
   -- To_Widget_Handle --
   ----------------------

   function To_Widget_Handle (H : Handle) return Widget_Handle
   is (Id => H.Id);

   ---------
   -- "+" --
   ---------

   function "+" (H : Handle) return Widget_Handle
   is (To_Widget_Handle (H));

   ------------
   -- Try_As --
   ------------

   function Try_As (H : Widget_Handle) return Handle is
      P : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if P /= null and then P.all in Custom_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Handle;
   end Try_As;

   ------------
   -- Borrow --
   ------------

   function Borrow (H : Handle) return Ref is
      P : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if P = null then
         raise Constraint_Error
           with "Widget.Extension.Borrow: stale or null handle";
      end if;

      --  Validate before pinning: a rejected handle must leave the pin
      --  count where it found it.
      if P.all not in Custom_Widget'Class then
         raise Constraint_Error
           with "Widget.Extension.Borrow: handle designates another"
                & " widget type";
      end if;

      Widget_Stores.Pin (H.Id);
      return (Ada.Finalization.Limited_Controlled with
              Ptr => Custom_Widget'Class (P.all)'Access,
              Id  => H.Id);
   end Borrow;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (R : in out Ref) is
      use type Widget_Stores.Object_Id;
      Id : constant Widget_Stores.Object_Id := R.Id;
   begin
      if Id /= Widget_Stores.Null_Id then
         R.Id := Widget_Stores.Null_Id;
         Widget_Stores.Unpin (Id);
      end if;
   end Finalize;

end Adi.Widget.Extension;
