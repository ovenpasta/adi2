with Ada.Containers.Vectors;
with Adi.Core;              use Adi.Core;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Widget;            use Adi.Widget;

generic
   type Row_Widget is new Widget with private;
package Adi.Widget.List_Box is

   type Selection_Mode is
     (No_Selection, Single_Selection, Multi_Selection, Range_Selection);

   type List_Box_Widget is new Widget with private;
   type List_Box_Widget_Access is access all List_Box_Widget'Class;

   --  Typed handle
   type List_Box_Handle is private;
   Null_List_Box_Handle : constant List_Box_Handle;

   --  Construction
   function Create_Handle return List_Box_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : List_Box_Handle) return Widget_Handle;
   function Try_As_List_Box (H : Widget_Handle) return List_Box_Handle;
   function Is_Valid (H : List_Box_Handle) return Boolean;
   function "+" (H : List_Box_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : List_Box_Handle; Styles : Part_Style_Array);

   --  Row management (widget methods)
   procedure Clear_Rows (W : in out List_Box_Widget);
   function Row_Count (W : List_Box_Widget) return Natural;
   function Get_Row_Handle
     (W : List_Box_Widget; Index : Positive) return Widget_Handle;

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
     (W : Widget_Handle; Index : Positive; Clicks : Natural);
   type Item_Activated_Callback is access procedure
     (W : Widget_Handle; Index : Positive);
   type Selection_Changed_Callback is access procedure
     (W : Widget_Handle);

   package Item_Clicked_Signals is new Adi.Signal
     (Item_Clicked_Callback, null);
   package Item_Activated_Signals is new Adi.Signal
     (Item_Activated_Callback, null);
   package Selection_Changed_Signals is new Adi.Signal
     (Selection_Changed_Callback, null);

   procedure Connect_Item_Clicked
     (W : in out List_Box_Widget; CB : Item_Clicked_Callback);
   function Connect_Item_Clicked
     (W : in out List_Box_Widget; CB : Item_Clicked_Callback)
      return Item_Clicked_Signals.Connection_Id;
   procedure Disconnect_Item_Clicked
     (W : in out List_Box_Widget; Id : Item_Clicked_Signals.Connection_Id);

   procedure Connect_Item_Activated
     (W : in out List_Box_Widget; CB : Item_Activated_Callback);
   function Connect_Item_Activated
     (W : in out List_Box_Widget; CB : Item_Activated_Callback)
      return Item_Activated_Signals.Connection_Id;
   procedure Disconnect_Item_Activated
     (W : in out List_Box_Widget; Id : Item_Activated_Signals.Connection_Id);

   procedure Connect_Selection_Changed
     (W : in out List_Box_Widget; CB : Selection_Changed_Callback);
   function Connect_Selection_Changed
     (W : in out List_Box_Widget; CB : Selection_Changed_Callback)
      return Selection_Changed_Signals.Connection_Id;
   procedure Disconnect_Selection_Changed
     (W : in out List_Box_Widget;
      Id : Selection_Changed_Signals.Connection_Id);

   --  Handle methods
   procedure Append_Row (H : List_Box_Handle; Row : Adi.Widget.Widget_Handle);
   procedure Clear_Rows (H : List_Box_Handle);
   function  Row_Count (H : List_Box_Handle) return Natural;
   function  Get_Row_Handle
     (H : List_Box_Handle; Index : Positive) return Widget_Handle;
   procedure Set_Scroll_Offset (H : List_Box_Handle; Offset : Pixel_Type);
   function  Get_Scroll_Offset (H : List_Box_Handle) return Pixel_Type;
   function  Get_Content_Height (H : List_Box_Handle) return Pixel_Type;
   procedure Scroll_By (H : List_Box_Handle; Delta_Y : Pixel_Type);
   procedure Ensure_Row_Visible (H : List_Box_Handle; Index : Positive);
   procedure Set_Selection_Mode (H : List_Box_Handle; Mode : Selection_Mode);
   function  Get_Selection_Mode (H : List_Box_Handle) return Selection_Mode;
   procedure Clear_Selection (H : List_Box_Handle);
   procedure Select_Row (H : List_Box_Handle; Index : Positive);
   procedure Toggle_Row_Selected (H : List_Box_Handle; Index : Positive);
   function  Is_Row_Selected (H : List_Box_Handle; Index : Positive)
      return Boolean;
   function  Get_Selected_Count (H : List_Box_Handle) return Natural;
   procedure Set_Current_Row (H : List_Box_Handle; Index : Positive);
   function  Get_Current_Row (H : List_Box_Handle) return Natural;
   procedure Connect_Item_Clicked
     (H : List_Box_Handle; CB : Item_Clicked_Callback);
   function  Connect_Item_Clicked
     (H : List_Box_Handle; CB : Item_Clicked_Callback)
      return Item_Clicked_Signals.Connection_Id;
   procedure Disconnect_Item_Clicked
     (H : List_Box_Handle; Id : Item_Clicked_Signals.Connection_Id);
   procedure Connect_Item_Activated
     (H : List_Box_Handle; CB : Item_Activated_Callback);
   function  Connect_Item_Activated
     (H : List_Box_Handle; CB : Item_Activated_Callback)
      return Item_Activated_Signals.Connection_Id;
   procedure Disconnect_Item_Activated
     (H : List_Box_Handle; Id : Item_Activated_Signals.Connection_Id);
   procedure Connect_Selection_Changed
     (H : List_Box_Handle; CB : Selection_Changed_Callback);
   function  Connect_Selection_Changed
     (H : List_Box_Handle; CB : Selection_Changed_Callback)
      return Selection_Changed_Signals.Connection_Id;
   procedure Disconnect_Selection_Changed
     (H : List_Box_Handle; Id : Selection_Changed_Signals.Connection_Id);

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

   type Row_Widget_Access is access all Row_Widget'Class;

   package Row_Vectors is new Ada.Containers.Vectors (Positive, Row_Widget_Access);
   package Bool_Vectors is new Ada.Containers.Vectors (Positive, Boolean);
   package Height_Vectors is new Ada.Containers.Vectors (Positive, Pixel_Type);
   package Rect_Vectors is new Ada.Containers.Vectors (Positive, Rectangle);

   type List_Box_Widget is new Widget with record
      Rows           : Row_Vectors.Vector;
      Selected       : Bool_Vectors.Vector;
      Row_Heights    : Height_Vectors.Vector;
      Cell_Rects     : Rect_Vectors.Vector;
      Current_Row    : Natural := 0;
      Anchor_Row     : Natural := 0;
      Hovered_Row    : Natural := 0;
      Mode           : Selection_Mode := Single_Selection;
      Item_Clicked       : Item_Clicked_Signals.Signal;
      Item_Activated     : Item_Activated_Signals.Signal;
      Selection_Changed  : Selection_Changed_Signals.Signal;
   end record;

   type List_Box_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_List_Box_Handle : constant List_Box_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.List_Box;
