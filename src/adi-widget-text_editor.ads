with Adi.SDL.Events;
with Adi.Text_Buffer;

package Adi.Widget.Text_Editor is

   type Text_Editor_Widget is new Widget with private;
   type Text_Editor_Widget_Access is access all Text_Editor_Widget'Class;

   function Create (Text : String := "") return Text_Editor_Widget_Access;

   procedure Set_Text (W : in out Text_Editor_Widget; Text : String);
   function Get_Text (W : Text_Editor_Widget) return String;

   type Change_Callback is access procedure
     (W : Text_Editor_Widget_Access; Text : String);
   procedure Set_On_Changed (W : in out Text_Editor_Widget;
                             CB : Change_Callback);

   overriding procedure Build_Items (W : in out Text_Editor_Widget);
   overriding procedure Layout (W : in out Text_Editor_Widget);
   overriding function Measure_Content (W : Text_Editor_Widget) return Size_2D;

   overriding procedure On_Key_Down
     (W        : in out Text_Editor_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

   overriding procedure On_Text_Input
     (W : in out Text_Editor_Widget; Text : String);
   overriding procedure On_Focus_Gained (W : in out Text_Editor_Widget);
   overriding procedure On_Focus_Lost (W : in out Text_Editor_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Text_Editor_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Move
     (W    : in out Text_Editor_Widget;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (W      : in out Text_Editor_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button);
   overriding procedure On_Mouse_Wheel
     (W                : in out Text_Editor_Widget;
      Delta_X, Delta_Y : Pixel_Type);
   overriding procedure On_Tick
     (W  : in out Text_Editor_Widget;
      DT : Duration);

private
   Panel_Idx  : constant Positive := 1;

   type Text_Editor_Widget is new Widget with record
      Buffer              : Adi.Text_Buffer.Text_Buffer;
      On_Changed          : Change_Callback := null;
      Drag_Selecting      : Boolean := False;
      Pending_Word_Select : Boolean := False;
      Press_X             : Pixel_Type := 0.0;
      Press_Y             : Pixel_Type := 0.0;
      Line_Skip           : Pixel_Type := 0.0;
      Sel_Item_Count      : Natural := 0;
      Text_Item_Idx       : Positive := 2;
      Cursor_Item_Idx     : Positive := 3;
      Caret_Changed       : Boolean := False;
      Last_Caret          : Adi.Text_Buffer.Position := (Line => 1, Column => 0);
   end record;

end Adi.Widget.Text_Editor;
