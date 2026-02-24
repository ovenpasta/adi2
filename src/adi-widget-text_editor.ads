with Adi.SDL.Events;
with Adi.Text_Layout;
with Adi.Text_Buffer;
with Adi.Widget.Context_Menu;
with Adi.Window;

package Adi.Widget.Text_Editor is

   type Text_Editor_Widget is new Widget with private;
   type Text_Editor_Widget_Access is access all Text_Editor_Widget'Class;

   function Create (Text : String := "") return Text_Editor_Widget_Access;

   procedure Set_Text (W : in out Text_Editor_Widget; Text : String);
   function Get_Text (W : Text_Editor_Widget) return String;
   procedure Set_Context_Menu_Part_Styles
     (W      : in out Text_Editor_Widget;
      Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (W      : in out Text_Editor_Widget;
      Styles : Part_Style_Array);

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
   --  Internal eager host binding. Public callers rely on lazy host
   --  resolution when the context menu is invoked.
   procedure Attach_Window
     (W    : in out Text_Editor_Widget;
      Host : Adi.Window.Window_Access);

   Panel_Idx  : constant Positive := 1;

   type Text_Editor_Widget is new Widget with record
      Buffer              : aliased Adi.Text_Buffer.Text_Buffer;
      On_Changed          : Change_Callback := null;
      Drag_Selecting      : Boolean := False;
      Pending_Word_Select : Boolean := False;
      Press_X             : Pixel_Type := 0.0;
      Press_Y             : Pixel_Type := 0.0;
      Layout              : Adi.Text_Layout.Text_Layout;
      Line_Skip           : Pixel_Type := 0.0;
      Sel_Item_Count      : Natural := 0;
      Row_Item_Count      : Natural := 0;
      First_Row_Item_Idx  : Positive := 2;
      Cursor_Item_Idx     : Positive := 3;
      Preferred_Caret_X   : Pixel_Type := 0.0;
      Has_Preferred_X     : Boolean := False;
      Last_Caret          : Adi.Text_Buffer.Position := (Line => 1, Column => 0);
      Context_Menu        : Adi.Widget.Context_Menu.Context_Menu_Access := null;
      Context_Menu_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Menu_Styles : Boolean := False;
      Context_Item_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Item_Styles : Boolean := False;
   end record;

end Adi.Widget.Text_Editor;
