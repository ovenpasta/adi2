with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Text_Buffer;
with Adi.Widget.Context_Menu;
with Adi.Widget;            use Adi.Widget;
with Adi.Window;

package Adi.Widget.Text_Input is

   type Text_Input_Widget is new Widget with private;
   type Text_Input_Widget_Access is access all Text_Input_Widget'Class;

   --  Typed handle
   type Text_Input_Handle is private;
   Null_Text_Input_Handle : constant Text_Input_Handle;

   --  Construction
   function Create (Text : String := "";
                    Label : String := "") return Text_Input_Widget_Access;
   function Create_Handle (Text : String := "";
                           Label : String := "") return Text_Input_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Text_Input_Handle) return Widget_Handle;
   function Try_As_Text_Input (H : Widget_Handle) return Text_Input_Handle;
   function Is_Valid (H : Text_Input_Handle) return Boolean;
   function "+" (H : Text_Input_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Text_Input_Handle; Styles : Part_Style_Array);

   --  Widget methods
   procedure Set_Text (W : in out Text_Input_Widget; Text : String);
   function Get_Text (W : Text_Input_Widget) return String;

   procedure Set_Context_Menu_Part_Styles
     (W      : in out Text_Input_Widget;
      Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (W      : in out Text_Input_Widget;
      Styles : Part_Style_Array);

   type Change_Callback is access procedure
     (W : Widget_Handle; Text : String);

   package Change_Signals is new Adi.Signal (Change_Callback, null);

   procedure Connect_Changed
     (W : in out Text_Input_Widget; CB : Change_Callback);
   function Connect_Changed
     (W : in out Text_Input_Widget; CB : Change_Callback)
      return Change_Signals.Connection_Id;
   procedure Disconnect_Changed
     (W : in out Text_Input_Widget; Id : Change_Signals.Connection_Id);

   --  Handle methods
   procedure Set_Text (H : Text_Input_Handle; Text : String);
   function  Get_Text (H : Text_Input_Handle) return String;
   procedure Set_Context_Menu_Part_Styles
     (H : Text_Input_Handle; Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (H : Text_Input_Handle; Styles : Part_Style_Array);
   procedure Connect_Changed
     (H : Text_Input_Handle; CB : Change_Callback);
   function  Connect_Changed
     (H : Text_Input_Handle; CB : Change_Callback)
      return Change_Signals.Connection_Id;
   procedure Disconnect_Changed
     (H : Text_Input_Handle; Id : Change_Signals.Connection_Id);

   overriding procedure Build_Items (W : in out Text_Input_Widget);
   overriding procedure Layout (W : in out Text_Input_Widget);
   overriding function Measure_Content (W : Text_Input_Widget) return Size_2D;

   overriding procedure On_Key_Down
     (W        : in out Text_Input_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

   overriding procedure On_Text_Input (W : in out Text_Input_Widget; Text : String);
   overriding procedure On_Focus_Gained (W : in out Text_Input_Widget);
   overriding procedure On_Focus_Lost (W : in out Text_Input_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Text_Input_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Move
     (W    : in out Text_Input_Widget;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (W      : in out Text_Input_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button);
   overriding procedure On_Destroy (W : in out Text_Input_Widget);

private
   --  Internal eager host binding. Public callers rely on lazy host
   --  resolution when the context menu is invoked.
   procedure Attach_Window
     (W    : in out Text_Input_Widget;
      Host : Adi.Window.Window_Access);

   Panel_Idx     : constant Positive := 1;
   Selection_Idx : constant Positive := 2;
   Text_Idx      : constant Positive := 3;
   Cursor_Idx    : constant Positive := 4;

   type Text_Input_Widget is new Widget with record
      Buffer     : aliased Adi.Text_Buffer.Text_Buffer;
      Changed : Change_Signals.Signal;
      Drag_Selecting : Boolean := False;
      Pending_Word_Select : Boolean := False;
      Press_X : Pixel_Type := 0.0;
      Press_Y : Pixel_Type := 0.0;
      Horizontal_Scroll : Pixel_Type := 0.0;
      Context_Menu : Adi.Widget.Context_Menu.Context_Menu_Access := null;
      Context_Menu_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Menu_Styles : Boolean := False;
      Context_Item_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Item_Styles : Boolean := False;
   end record;

   type Text_Input_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Text_Input_Handle : constant Text_Input_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Text_Input;
