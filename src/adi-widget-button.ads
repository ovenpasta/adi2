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
   type Button_Widget_Access is access all Button_Widget'Class;

   --  Construction
   function Create (Text : String := "") return Button_Widget_Access;

   --  Callback types
   type Click_Callback is access procedure (Btn : Button_Widget_Access);
   type Toggle_Callback is access procedure
     (Btn : Button_Widget_Access; Active : Boolean);

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

   ---------------------------------------------------------------------------
   --  Group Handler Interface
   --
   --  Used by Option_Group to coordinate radio-button behavior.
   --  When a button has a Group link, toggle handling is delegated to the
   --  group instead of being done locally.
   ---------------------------------------------------------------------------

   type Group_Handler is limited interface;
   type Group_Handler_Access is access all Group_Handler'Class;

   procedure On_Button_Clicked
     (H   : in out Group_Handler;
      Btn : Button_Widget_Access) is abstract;

   --  Link/unlink a button to a group
   procedure Set_Group (W : in out Button_Widget;
                        G : Group_Handler_Access);

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

   type Button_Widget is new Label_Widget with record
      Toggleable : Boolean := False;
      Clicked    : Click_Signals.Signal;
      Toggled    : Toggle_Signals.Signal;
      Group      : Group_Handler_Access := null;
   end record;

end Adi.Widget.Button;
