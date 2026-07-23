--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

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

   type Option_Group is limited new Group_Handler with private;
   type Option_Group_Access is access all Option_Group;

   type Option_Changed_Callback is access procedure (Value : Option_Type);

   package Option_Changed_Signals is new Adi.Signal
     (Option_Changed_Callback, null);

   --  Associate a button with an option value.
   --  The button is made toggleable and linked to this group.
   procedure Set_Button (G : in out Option_Group;
                         O : Option_Type;
                         B : Button_Widget_Access);
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

   --  Group_Handler dispatch (called by Button.On_Click)
   overriding procedure On_Button_Clicked
     (G : in out Option_Group;
      W : Widget_Handle);

private

   type Button_Array is array (Option_Type) of Button_Widget_Access;

   type Option_Group is limited new Group_Handler with record
      Buttons     : Button_Array := [others => null];
      Selected    : Option_Type := Option_Type'First;
      Changed : Option_Changed_Signals.Signal;
      Initialized : Boolean := False;
   end record;

end Adi.Widget.Button.Options;
