--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Button.Options is

   --  The group as the buttons see it.  Group_Handler_Access is declared
   --  in the parent, so the local access attribute reaches it through an
   --  intermediate class-wide view.
   function Self (G : in out Group_Impl) return Group_Handler_Access is
      View : constant access Group_Handler'Class :=
        Group_Handler'Class (G)'Unchecked_Access;
   begin
      return Group_Handler_Access (View);
   end Self;

   --  Null when the handle no longer resolves, so a button destroyed
   --  before its group drops out of every path below.
   function Live (B : Button_Handle) return Button_Widget_Access is
   begin
      if not Widget_Stores.Is_Valid (B.Id) then
         return null;
      end if;
      return Button_Widget_Access (Widget_Stores.Get (B.Id));
   end Live;

   --  What every group operation goes through.  A live handle is not
   --  enough: a group must not drive a button that points at another
   --  group.  Set_Button publishes the new link before telling the group
   --  the button is leaving, so between those two steps -- and for good
   --  if Forget_Button propagates -- the old group holds an entry for a
   --  button that is no longer its own.  Asking the link here makes that
   --  entry inert, which is why the window is safe to have.
   function Owned (G : in out Group_Impl; B : Button_Handle)
      return Button_Widget_Access
   is
      Btn : constant Button_Widget_Access := Live (B);
   begin
      if Btn = null or else Group_Of (Btn.all) /= Self (G) then
         return null;
      end if;
      return Btn;
   end Owned;

   --  Clear a button's group link, but only while it still points at
   --  this group.  A button that has since joined another group keeps
   --  the newer link: otherwise finalizing the group it left would sever
   --  a binding that is in use.
   procedure Unlink (G : in out Group_Impl; B : Button_Handle) is
      Btn : constant Button_Widget_Access := Owned (G, B);
   begin
      if Btn /= null then
         Set_Group (Btn.all, null);
      end if;
   end Unlink;

   ----------------
   -- Set_Button --
   ----------------

   procedure Set_Button (G : in out Group_Impl;
                         O : Option_Type;
                         B : Button_Handle)
   is
      Btn : constant Button_Widget_Access := Live (B);
   begin
      if Btn = null then
         raise Constraint_Error with "Set_Button: stale or null handle";
      end if;

      --  Whatever held this option loses it.
      if G.Buttons (O) /= B then
         Unlink (G, G.Buttons (O));
      end if;

      --  One button answers for one option within a group.
      for Other in Option_Type loop
         if Other /= O and then G.Buttons (Other) = B then
            G.Buttons (Other) := Null_Button_Handle;
         end if;
      end loop;

      declare
         Prev : constant Group_Handler_Access := Group_Of (Btn.all);
      begin
         --  Publish the membership and the link first: Forget_Button is
         --  told about a button the new group already owns.  If it
         --  raises, the old group keeps a stale entry, which no
         --  operation acts on because the link no longer names it.
         G.Buttons (O) := B;
         Set_Toggleable (Btn.all, True);
         Set_Group (Btn.all, Self (G));

         if Prev /= null and then Prev /= Self (G) then
            Forget_Button (Prev.all, Get_Handle (Btn.all));
         end if;
      end;

      --  Set initial toggle state
      if G.Initialized then
         Set_Toggled (Btn.all, O = G.Selected);
      else
         --  First button added initializes the group
         G.Selected := O;
         G.Initialized := True;
         Set_Toggled (Btn.all, True);
      end if;
   end Set_Button;

   -------------------
   -- Forget_Button --
   -------------------

   overriding procedure Forget_Button
     (G : in out Group_Impl;
      W : Widget_Handle)
   is
   begin
      for O in Option_Type loop
         if Is_Valid (G.Buttons (O))
           and then To_Widget_Handle (G.Buttons (O)) = W
         then
            G.Buttons (O) := Null_Button_Handle;
         end if;
      end loop;
   end Forget_Button;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (G : in out Group_Impl) is
   begin
      for O in Option_Type loop
         Unlink (G, G.Buttons (O));
         G.Buttons (O) := Null_Button_Handle;
      end loop;
   end Finalize;

   ------------------
   -- Get_Selected --
   ------------------

   function Get_Selected (G : Group_Impl) return Option_Type is
   begin
      return G.Selected;
   end Get_Selected;

   ------------------
   -- Set_Selected --
   ------------------

   procedure Set_Selected (G : in out Group_Impl; O : Option_Type) is
      Old_Btn : constant Button_Widget_Access :=
        Owned (G, G.Buttons (G.Selected));
      New_Btn : Button_Widget_Access;
   begin
      if G.Selected = O then
         return;
      end if;

      if Old_Btn /= null then
         Set_Toggled (Old_Btn.all, False);
      end if;

      G.Selected := O;
      New_Btn := Owned (G, G.Buttons (O));
      if New_Btn /= null then
         Set_Toggled (New_Btn.all, True);
      end if;

      declare
         procedure Call (CB : Option_Changed_Callback) is
         begin CB (O); end Call;
         procedure Emit is new Option_Changed_Signals.For_Each (Call);
      begin
         Emit (G.Changed);
      end;
   end Set_Selected;

   ---------------------
   -- Connect_Changed --
   ---------------------

   procedure Connect_Changed (G : in out Group_Impl;
                              CB : Option_Changed_Callback) is
   begin
      G.Changed.Connect (CB);
   end Connect_Changed;

   function Connect_Changed (G : in out Group_Impl;
                             CB : Option_Changed_Callback)
      return Option_Changed_Signals.Connection_Id is
   begin
      return G.Changed.Connect (CB);
   end Connect_Changed;

   procedure Disconnect_Changed
     (G : in out Group_Impl; Id : Option_Changed_Signals.Connection_Id) is
   begin
      G.Changed.Disconnect (Id);
   end Disconnect_Changed;

   -----------------------
   -- On_Button_Clicked --
   -----------------------

   overriding procedure On_Button_Clicked
     (G : in out Group_Impl;
      W : Widget_Handle)
   is
   begin
      if not Adi.Widget.Is_Valid (W) then
         return;
      end if;

      --  Find which option this button corresponds to
      for O in Option_Type loop
         if Is_Valid (G.Buttons (O))
           and then To_Widget_Handle (G.Buttons (O)) = W
         then
            declare
               Btn : constant Button_Widget_Access := Owned (G, G.Buttons (O));
            begin
               if Btn = null then
                  return;
               end if;

               --  Already selected? No-op (radio behavior)
               if O = G.Selected then
                  --  Keep it toggled: the click may have flipped it
                  Set_Toggled (Btn.all, True);
                  return;
               end if;

               declare
                  Old_Btn : constant Button_Widget_Access :=
                    Owned (G, G.Buttons (G.Selected));
               begin
                  if Old_Btn /= null then
                     Set_Toggled (Old_Btn.all, False);
                  end if;
               end;

               G.Selected := O;
               Set_Toggled (Btn.all, True);
            end;

            declare
               procedure Call (CB : Option_Changed_Callback) is
               begin CB (O); end Call;
               procedure Emit is new Option_Changed_Signals.For_Each (Call);
            begin
               Emit (G.Changed);
            end;

            return;
         end if;
      end loop;
   end On_Button_Clicked;

   ---------------------------------------------------------------------------
   --  Public operations, on the wrapper
   ---------------------------------------------------------------------------

   procedure Set_Button (G : in out Option_Group;
                         O : Option_Type;
                         B : Button_Handle) is
   begin
      Set_Button (G.Impl, O, B);
   end Set_Button;

   function Get_Selected (G : Option_Group) return Option_Type
   is (Get_Selected (G.Impl));

   procedure Set_Selected (G : in out Option_Group; O : Option_Type) is
   begin
      Set_Selected (G.Impl, O);
   end Set_Selected;

   procedure Connect_Changed (G : in out Option_Group;
                              CB : Option_Changed_Callback) is
   begin
      Connect_Changed (G.Impl, CB);
   end Connect_Changed;

   function Connect_Changed (G : in out Option_Group;
                             CB : Option_Changed_Callback)
      return Option_Changed_Signals.Connection_Id
   is (Connect_Changed (G.Impl, CB));

   procedure Disconnect_Changed
     (G : in out Option_Group; Id : Option_Changed_Signals.Connection_Id) is
   begin
      Disconnect_Changed (G.Impl, Id);
   end Disconnect_Changed;

end Adi.Widget.Button.Options;
