--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package Adi.Widget.Button.Switch is

   ---------------------------------------------------------------------------
   --  Switch Widget
   --
   --  Derives from Button_Widget to reuse click/toggle callbacks and keyboard
   --  activation semantics, but renders as a track + knob switch.
   ---------------------------------------------------------------------------

   type Switch_Widget is new Adi.Widget.Button.Button_Widget with private;

   --  Typed handle
   type Switch_Handle is private;
   Null_Switch_Handle : constant Switch_Handle;

   --  Construction
   function Create_Handle (Checked : Boolean := False) return Switch_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Switch_Handle) return Widget_Handle;
   function Try_As_Switch (H : Widget_Handle) return Switch_Handle;
   function Is_Valid (H : Switch_Handle) return Boolean;
   function "+" (H : Switch_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Switch_Handle; Styles : Part_Style_Array);

   --  Widget methods
   procedure Set_Checked (W : in out Switch_Widget; Value : Boolean);
   function  Is_Checked (W : Switch_Widget) return Boolean;

   --  Handle methods (own)
   procedure Set_Checked (H : Switch_Handle; Value : Boolean);
   function  Is_Checked (H : Switch_Handle) return Boolean;

   --  Handle methods (forwarded Button)
   procedure Connect_Clicked (H : Switch_Handle; CB : Click_Callback);
   function  Connect_Clicked (H : Switch_Handle; CB : Click_Callback)
     return Click_Signals.Connection_Id;
   procedure Disconnect_Clicked
     (H : Switch_Handle; Id : Click_Signals.Connection_Id);
   procedure Connect_Toggled (H : Switch_Handle; CB : Toggle_Callback);
   function  Connect_Toggled (H : Switch_Handle; CB : Toggle_Callback)
     return Toggle_Signals.Connection_Id;
   procedure Disconnect_Toggled
     (H : Switch_Handle; Id : Toggle_Signals.Connection_Id);
   procedure Set_Toggleable (H : Switch_Handle; Value : Boolean := True);
   function  Is_Toggleable  (H : Switch_Handle) return Boolean;
   function  Is_Toggled     (H : Switch_Handle) return Boolean;
   procedure Set_Toggled    (H : Switch_Handle; Value : Boolean);

   overriding procedure Build_Items (W : in out Switch_Widget);
   overriding procedure Layout (W : in out Switch_Widget);
   overriding function Measure_Content (W : Switch_Widget) return Size_2D;

private

   type Switch_Widget is new Adi.Widget.Button.Button_Widget with null record;

   type Switch_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Switch_Handle : constant Switch_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Switch_Widget_Access is access all Switch_Widget'Class;

end Adi.Widget.Button.Switch;
