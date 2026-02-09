with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.SDL.Events;
with Adi.Text_Buffer;
with Adi.Widget;            use Adi.Widget;

package Adi.Widget.Text_Input is

   type Text_Input_Widget is new Widget with private;
   type Text_Input_Widget_Access is access all Text_Input_Widget'Class;

   function Create (Text : String := "") return Text_Input_Widget_Access;

   procedure Set_Text (W : in out Text_Input_Widget; Text : String);
   function Get_Text (W : Text_Input_Widget) return String;

   type Change_Callback is access procedure
     (W    : Text_Input_Widget_Access;
      Text : String);

   procedure Set_On_Changed (W : in out Text_Input_Widget; CB : Change_Callback);

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

private
   Panel_Idx     : constant Positive := 1;
   Selection_Idx : constant Positive := 2;
   Text_Idx      : constant Positive := 3;
   Cursor_Idx    : constant Positive := 4;

   type Text_Input_Widget is new Widget with record
      Buffer     : Adi.Text_Buffer.Text_Buffer;
      On_Changed : Change_Callback := null;
      Drag_Selecting : Boolean := False;
   end record;

end Adi.Widget.Text_Input;
