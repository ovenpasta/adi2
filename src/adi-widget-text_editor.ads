--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Adi.SDL.Events;
with Adi.Signal;
with Adi.Text_Layout;
with Adi.Text_Buffer;
with Adi.Widget.Context_Menu;
with Adi.Window;

package Adi.Widget.Text_Editor is

   type Text_Editor_Widget is new Widget with private;
   type Text_Editor_Widget_Access is access all Text_Editor_Widget'Class;

   --  Typed handle
   type Text_Editor_Handle is private;
   Null_Text_Editor_Handle : constant Text_Editor_Handle;

   --  Construction
   function Create (Text : String := "") return Text_Editor_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle (Text : String := "") return Text_Editor_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Text_Editor_Handle) return Widget_Handle;
   function Try_As_Text_Editor (H : Widget_Handle) return Text_Editor_Handle;
   function Is_Valid (H : Text_Editor_Handle) return Boolean;
   function "+" (H : Text_Editor_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Text_Editor_Handle; Styles : Part_Style_Array);

   --  Widget methods
   procedure Set_Text (W : in out Text_Editor_Widget; Text : String);
   function Get_Text (W : Text_Editor_Widget) return String;
   procedure Append_Text (W : in out Text_Editor_Widget; Text : String);
   procedure Scroll_To_End (W : in out Text_Editor_Widget);

   procedure Set_Read_Only (W : in out Text_Editor_Widget; Value : Boolean := True);
   function  Is_Read_Only  (W : Text_Editor_Widget) return Boolean;

   procedure Set_Context_Menu_Part_Styles
     (W      : in out Text_Editor_Widget;
      Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (W      : in out Text_Editor_Widget;
      Styles : Part_Style_Array);

   type Change_Callback is access procedure
     (W : Widget_Handle; Text : String);

   package Change_Signals is new Adi.Signal (Change_Callback, null);

   procedure Connect_Changed
     (W : in out Text_Editor_Widget; CB : Change_Callback);
   function Connect_Changed
     (W : in out Text_Editor_Widget; CB : Change_Callback)
      return Change_Signals.Connection_Id;
   procedure Disconnect_Changed
     (W : in out Text_Editor_Widget; Id : Change_Signals.Connection_Id);

   --  Handle methods
   procedure Set_Text (H : Text_Editor_Handle; Text : String);
   function  Get_Text (H : Text_Editor_Handle) return String;
   procedure Append_Text (H : Text_Editor_Handle; Text : String);
   procedure Scroll_To_End (H : Text_Editor_Handle);
   procedure Set_Read_Only (H : Text_Editor_Handle; Value : Boolean := True);
   function  Is_Read_Only  (H : Text_Editor_Handle) return Boolean;
   procedure Set_Context_Menu_Part_Styles
     (H : Text_Editor_Handle; Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (H : Text_Editor_Handle; Styles : Part_Style_Array);
   procedure Connect_Changed
     (H : Text_Editor_Handle; CB : Change_Callback);
   function  Connect_Changed
     (H : Text_Editor_Handle; CB : Change_Callback)
      return Change_Signals.Connection_Id;
   procedure Disconnect_Changed
     (H : Text_Editor_Handle; Id : Change_Signals.Connection_Id);

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
   overriding procedure On_Destroy (W : in out Text_Editor_Widget);

private
   --  Internal eager host binding. Public callers rely on lazy host
   --  resolution when the context menu is invoked.
   procedure Attach_Window
     (W    : in out Text_Editor_Widget;
      Host : Adi.Window.Window_Access);

   Panel_Idx  : constant Positive := 1;

   type Text_Editor_Widget is new Widget with record
      Buffer              : aliased Adi.Text_Buffer.Text_Buffer;
      Changed             : Change_Signals.Signal;
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
      Context_Menu        : Adi.Widget.Context_Menu.Menu_Handle :=
        Adi.Widget.Context_Menu.Null_Menu_Handle;
      Context_Menu_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Menu_Styles : Boolean := False;
      Context_Item_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Item_Styles : Boolean := False;
      Read_Only             : Boolean := False;
      Scroll_To_End_Pending : Boolean := False;
   end record;

   type Text_Editor_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Text_Editor_Handle : constant Text_Editor_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Text_Editor;
