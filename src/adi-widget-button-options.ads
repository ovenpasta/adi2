--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
with Adi.Signal;

generic
   type Option_Type is (<>);
package Adi.Widget.Button.Options is

   ---------------------------------------------------------------------------
   --  Option Group - Radio-button style selection over a discrete type
   --
   --  Each option value maps to a Button_Widget. Clicking a button selects
   --  that option and deselects the previous one (radio behavior).
   --  Clicking the already-selected button is a no-op.
   ---------------------------------------------------------------------------

   --  Opaque: what a group is to its buttons is Adi.Widget.Button's own
   --  business.  A group hands every button it owns a pointer back to
   --  itself, so it is controlled, and finalization unlinks the buttons
   --  it still holds.
   type Option_Group is limited private;

   type Option_Changed_Callback is access procedure (Value : Option_Type);

   package Option_Changed_Signals is new Adi.Signal
     (Option_Changed_Callback, null);

   --  Associate a button with an option value.  The button is made
   --  toggleable and linked to this group.  Any button that held this
   --  option is unlinked, and a button moving in from another group is
   --  dropped from that one.
   procedure Set_Button (G : in out Option_Group;
                         O : Option_Type;
                         B : Button_Handle);

   --  Query / change selection
   function  Get_Selected (G : Option_Group) return Option_Type;
   procedure Set_Selected (G : in out Option_Group; O : Option_Type);

   --  Connect/disconnect selection change subscribers
   procedure Connect_Changed
     (G : in out Option_Group; CB : Option_Changed_Callback);
   function Connect_Changed
     (G : in out Option_Group; CB : Option_Changed_Callback)
      return Option_Changed_Signals.Connection_Id;
   procedure Disconnect_Changed
     (G : in out Option_Group; Id : Option_Changed_Signals.Connection_Id);

private

   type Button_Array is array (Option_Type) of Button_Handle;

   --  The tagged half: what a button dispatches to.  A wrapper rather
   --  than Option_Group itself, because a partial view has to name the
   --  interfaces its full view implements, and naming Group_Handler
   --  there would put the whole protocol back in the public API.
   type Group_Impl is
     limited new Ada.Finalization.Limited_Controlled
       and Group_Handler with record
      Buttons     : Button_Array := [others => Null_Button_Handle];
      Selected    : Option_Type := Option_Type'First;
      Changed     : Option_Changed_Signals.Signal;
      Initialized : Boolean := False;
   end record;

   overriding procedure Finalize (G : in out Group_Impl);

   --  Reached by dispatch from Button.On_Click, not by callers.
   overriding procedure On_Button_Clicked
     (G : in out Group_Impl;
      W : Widget_Handle);

   overriding procedure Forget_Button
     (G : in out Group_Impl;
      W : Widget_Handle);

   --  Controlled by composition: Impl finalizes with its enclosing group.
   type Option_Group is limited record
      Impl : Group_Impl;
   end record;

end Adi.Widget.Button.Options;
