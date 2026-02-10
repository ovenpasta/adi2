with Ada.Containers.Vectors;
with Adi.Core;              use Adi.Core;
with Adi.SDL.Events;
with Adi.Widget;            use Adi.Widget;

generic
   type Row_Widget is new Widget with private;
   type Row_Widget_Access is access all Row_Widget'Class;
package Adi.Widget.List_Box is

   type Selection_Mode is
     (No_Selection, Single_Selection, Multi_Selection, Range_Selection);

   type List_Box_Widget is new Widget with private;
   type List_Box_Widget_Access is access all List_Box_Widget'Class;


   function Create return List_Box_Widget_Access;

   procedure Append_Row (W : in out List_Box_Widget; Row : Row_Widget_Access);
   procedure Clear_Rows (W : in out List_Box_Widget);
   function Row_Count (W : List_Box_Widget) return Natural;
   function Get_Row (W : List_Box_Widget; Index : Positive) return Row_Widget_Access;

   procedure Set_Row_Gap (W : in out List_Box_Widget; Gap : Pixel_Type);
   function Get_Row_Gap (W : List_Box_Widget) return Pixel_Type;

   procedure Set_Scroll_Offset (W : in out List_Box_Widget; Offset : Pixel_Type);
   function Get_Scroll_Offset (W : List_Box_Widget) return Pixel_Type;
   function Get_Content_Height (W : List_Box_Widget) return Pixel_Type;
   procedure Scroll_By (W : in out List_Box_Widget; Delta_Y : Pixel_Type);
   procedure Ensure_Row_Visible (W : in out List_Box_Widget; Index : Positive);

   procedure Set_Selection_Mode (W : in out List_Box_Widget; Mode : Selection_Mode);
   function Get_Selection_Mode (W : List_Box_Widget) return Selection_Mode;
   procedure Clear_Selection (W : in out List_Box_Widget);
   procedure Select_Row (W : in out List_Box_Widget; Index : Positive);
   procedure Toggle_Row_Selected (W : in out List_Box_Widget; Index : Positive);
   function Is_Row_Selected (W : List_Box_Widget; Index : Positive) return Boolean;
   function Get_Selected_Count (W : List_Box_Widget) return Natural;

   procedure Set_Current_Row (W : in out List_Box_Widget; Index : Positive);
   function Get_Current_Row (W : List_Box_Widget) return Natural;

   type Item_Clicked_Callback is access procedure
     (W : List_Box_Widget_Access; Index : Positive; Clicks : Natural);
   type Item_Activated_Callback is access procedure
     (W : List_Box_Widget_Access; Index : Positive);
   type Selection_Changed_Callback is access procedure
     (W : List_Box_Widget_Access);

   procedure Set_On_Item_Clicked
     (W  : in out List_Box_Widget;
      CB : Item_Clicked_Callback);
   procedure Set_On_Item_Activated
     (W  : in out List_Box_Widget;
      CB : Item_Activated_Callback);
   procedure Set_On_Selection_Changed
     (W  : in out List_Box_Widget;
      CB : Selection_Changed_Callback);

   overriding procedure Build_Items (W : in out List_Box_Widget);
   overriding procedure Layout (W : in out List_Box_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out List_Box_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Wheel
     (W                : in out List_Box_Widget;
      Delta_X, Delta_Y : Pixel_Type);
   overriding procedure On_Mouse_Move
     (W    : in out List_Box_Widget;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (W      : in out List_Box_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);
   overriding procedure On_Tick
     (W  : in out List_Box_Widget;
      DT : Duration);
   overriding procedure On_Key_Down
     (W        : in out List_Box_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

private

   Panel_Idx : constant Positive := 1;

   package Row_Vectors is new Ada.Containers.Vectors (Positive, Row_Widget_Access);
   package Bool_Vectors is new Ada.Containers.Vectors (Positive, Boolean);
   package Height_Vectors is new Ada.Containers.Vectors (Positive, Pixel_Type);

   type List_Box_Widget is new Widget with record
      Rows           : Row_Vectors.Vector;
      Selected       : Bool_Vectors.Vector;
      Row_Heights    : Height_Vectors.Vector;
      Row_Gap        : Pixel_Type := 0.0;
      Scroll_Offset  : Pixel_Type := 0.0;
      Content_Height : Pixel_Type := 0.0;
      Current_Row    : Natural := 0;
      Anchor_Row     : Natural := 0;
      Mode           : Selection_Mode := Single_Selection;
      Scroll_Dragging     : Boolean := False;
      Scroll_Drag_Offset  : Pixel_Type := 0.0;
      Scroll_Velocity     : Pixel_Type := 0.0;
      Last_Drag_Offset    : Pixel_Type := 0.0;
      On_Item_Click  : Item_Clicked_Callback := null;
      On_Item_Act    : Item_Activated_Callback := null;
      On_Select      : Selection_Changed_Callback := null;
   end record;

end Adi.Widget.List_Box;
