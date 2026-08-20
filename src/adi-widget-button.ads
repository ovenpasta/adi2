--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Signal;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.SDL.Events;

package Adi.Widget.Button is

   ---------------------------------------------------------------------------
   --  Button Widget - Clickable button with optional toggle behavior
   --
   --  Inherits from Label_Widget: text, icon, panel items, flex layout.
   --  Adds click/toggle callbacks and group coordination.
   ---------------------------------------------------------------------------

   type Button_Widget is new Label_Widget with private;

   --  Typed handle
   type Button_Handle is private;
   Null_Button_Handle : constant Button_Handle;

   --  Construction
   function Create_Handle (Text : String := "") return Button_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Button_Handle) return Widget_Handle;
   function Try_As_Button (H : Widget_Handle) return Button_Handle;
   function Is_Valid (H : Button_Handle) return Boolean;

   --  Callback types
   type Click_Callback is access procedure (W : Widget_Handle);
   type Toggle_Callback is access procedure
     (W : Widget_Handle; Active : Boolean);

   --  Signal packages
   package Click_Signals is new Adi.Signal (Click_Callback, null);
   package Toggle_Signals is new Adi.Signal (Toggle_Callback, null);

   --  Connect/disconnect click subscribers
   procedure Connect_Clicked
     (W : in out Button_Widget; CB : Click_Callback);
   function Connect_Clicked
     (W : in out Button_Widget; CB : Click_Callback)
      return Click_Signals.Connection_Id;
   procedure Disconnect_Clicked
     (W : in out Button_Widget; Id : Click_Signals.Connection_Id);

   --  Connect/disconnect toggle subscribers
   procedure Connect_Toggled
     (W : in out Button_Widget; CB : Toggle_Callback);
   function Connect_Toggled
     (W : in out Button_Widget; CB : Toggle_Callback)
      return Toggle_Signals.Connection_Id;
   procedure Disconnect_Toggled
     (W : in out Button_Widget; Id : Toggle_Signals.Connection_Id);

   --  Toggle mode
   procedure Set_Toggleable (W : in out Button_Widget;
                             Value : Boolean := True);
   function  Is_Toggleable  (W : Button_Widget) return Boolean;
   function  Is_Toggled     (W : Button_Widget) return Boolean;
   procedure Set_Toggled    (W : in out Button_Widget; Value : Boolean);

   --  Typed handle methods
   procedure Connect_Clicked (H : Button_Handle; CB : Click_Callback);
   function  Connect_Clicked (H : Button_Handle; CB : Click_Callback)
     return Click_Signals.Connection_Id;
   procedure Disconnect_Clicked
     (H : Button_Handle; Id : Click_Signals.Connection_Id);
   procedure Connect_Toggled (H : Button_Handle; CB : Toggle_Callback);
   function  Connect_Toggled (H : Button_Handle; CB : Toggle_Callback)
     return Toggle_Signals.Connection_Id;
   procedure Disconnect_Toggled
     (H : Button_Handle; Id : Toggle_Signals.Connection_Id);
   procedure Set_Toggleable (H : Button_Handle; Value : Boolean := True);
   function  Is_Toggleable  (H : Button_Handle) return Boolean;
   function  Is_Toggled     (H : Button_Handle) return Boolean;
   procedure Set_Toggled    (H : Button_Handle; Value : Boolean);
   procedure Set_Text (H : Button_Handle; Text : String);
   function  Get_Text (H : Button_Handle) return String;
   procedure Set_Icon (H : Button_Handle; Icon : Image_Handle);
   function "+" (H : Button_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Button_Handle; Styles : Part_Style_Array);

   --  Click handler (dispatched from base Widget.On_Click)
   overriding procedure On_Click (W : in out Button_Widget);
   overriding procedure On_Key_Down
     (W        : in out Button_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);
   overriding procedure On_Key_Up
     (W        : in out Button_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

private

   ---------------------------------------------------------------------------
   --  Group Handler Interface
   --
   --  How a group of buttons coordinates radio behaviour: a button with a
   --  group link delegates toggle handling to it instead of toggling
   --  itself.  Private, because a group hands every button a pointer back
   --  to itself and nothing here can enforce that the group outlives
   --  them.  Adi.Widget.Button.Options is the supported group, and its
   --  finalization unlinks the buttons it still owns.
   ---------------------------------------------------------------------------

   type Group_Handler is limited interface;
   type Group_Handler_Access is access all Group_Handler'Class;

   procedure On_Button_Clicked
     (H : in out Group_Handler;
      W : Widget_Handle) is abstract;

   --  Called on the group a button is leaving, so it can drop its own
   --  record of the membership.  It must not touch the button's group
   --  link: by the time this runs, the new group owns it.
   procedure Forget_Button
     (H : in out Group_Handler;
      W : Widget_Handle) is null;

   --  Link/unlink a button to a group
   procedure Set_Group (W : in out Button_Widget;
                        G : Group_Handler_Access);

   --  The group this button belongs to, or null.  A group compares this
   --  against itself before acting on a button, so that a button rebound
   --  elsewhere is left alone.
   function Group_Of (W : Button_Widget) return Group_Handler_Access;

   type Button_Widget is new Label_Widget with record
      Toggleable : Boolean := False;
      Clicked    : Click_Signals.Signal;
      Toggled    : Toggle_Signals.Signal;
      Group      : Group_Handler_Access := null;
   end record;

   type Button_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Button_Handle : constant Button_Handle := (Id => Widget_Stores.Null_Id);

   type Button_Widget_Access is access all Button_Widget'Class;

end Adi.Widget.Button;
