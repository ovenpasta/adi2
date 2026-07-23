--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Signal;

generic
   type Value_Type is private;
   Zero : Value_Type;
   with function "+" (L, R : Value_Type) return Value_Type is <>;
   with function "-" (L, R : Value_Type) return Value_Type is <>;
   with function "<" (L, R : Value_Type) return Boolean is <>;
   with function To_Float (V : Value_Type) return Float;
   with function From_Float (F : Float) return Value_Type;
package Adi.Widget.Slider_Impl is

   ---------------------------------------------------------------------------
   --  Slider Widget - Draggable track + knob control
   --
   --  Core generic that holds ALL implementation logic.
   --  Thin wrappers (Adi.Widget.Slider, Adi.Widget.Integer_Slider)
   --  instantiate this with appropriate formals and re-export the API.
   --
   --  Items:
   --    1  Main_Part       - Container / track background
   --    2  Indicator_Part  - Filled portion (progress)
   --    3  Knob_Part       - Draggable handle
   ---------------------------------------------------------------------------

   type Orientation is (Horizontal, Vertical);

   type Slider_Widget is new Widget with private;
   type Slider_Widget_Access is access all Slider_Widget;

   --  Typed handle
   type Slider_Handle is private;
   Null_Slider_Handle : constant Slider_Handle;

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Slider_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Slider_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Slider_Handle) return Widget_Handle;
   function Try_As_Slider (H : Widget_Handle) return Slider_Handle;
   function Is_Valid (H : Slider_Handle) return Boolean;

   procedure Set_Value (W : in out Slider_Widget; V : Value_Type);
   function  Get_Value (W : Slider_Widget) return Value_Type;

   procedure Set_Range (W : in out Slider_Widget; Min, Max : Value_Type);
   function  Get_Min   (W : Slider_Widget) return Value_Type;
   function  Get_Max   (W : Slider_Widget) return Value_Type;

   procedure Set_Step (W : in out Slider_Widget; S : Value_Type);
   function  Get_Step (W : Slider_Widget) return Value_Type;

   procedure Set_Orientation (W : in out Slider_Widget; Dir : Orientation);
   function  Get_Orientation (W : Slider_Widget) return Orientation;

   type Value_Changed_Callback is access procedure
     (W : Widget_Handle; Value : Value_Type);

   package Value_Changed_Signals is new Adi.Signal
     (Value_Changed_Callback, null);

   procedure Connect_Changed
     (W : in out Slider_Widget; CB : Value_Changed_Callback);
   function Connect_Changed
     (W : in out Slider_Widget; CB : Value_Changed_Callback)
      return Value_Changed_Signals.Connection_Id;
   procedure Disconnect_Changed
     (W : in out Slider_Widget; Id : Value_Changed_Signals.Connection_Id);

   --  Typed handle methods
   procedure Set_Value (H : Slider_Handle; V : Value_Type);
   function  Get_Value (H : Slider_Handle) return Value_Type;
   procedure Set_Step (H : Slider_Handle; S : Value_Type);
   function  Get_Step (H : Slider_Handle) return Value_Type;
   procedure Set_Range (H : Slider_Handle; Min, Max : Value_Type);
   function  Get_Min (H : Slider_Handle) return Value_Type;
   function  Get_Max (H : Slider_Handle) return Value_Type;
   procedure Set_Orientation (H : Slider_Handle; Dir : Orientation);
   function  Get_Orientation (H : Slider_Handle) return Orientation;
   procedure Connect_Changed (H : Slider_Handle; CB : Value_Changed_Callback);
   function  Connect_Changed (H : Slider_Handle; CB : Value_Changed_Callback)
     return Value_Changed_Signals.Connection_Id;
   procedure Disconnect_Changed
     (H : Slider_Handle; Id : Value_Changed_Signals.Connection_Id);
   function "+" (H : Slider_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Slider_Handle; Styles : Part_Style_Array);

   overriding procedure Build_Items (W : in out Slider_Widget);
   overriding procedure Layout (W : in out Slider_Widget);
   overriding function Measure_Content (W : Slider_Widget) return Size_2D;

   overriding procedure On_Mouse_Down
     (W      : in out Slider_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Move
     (W    : in out Slider_Widget;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (W      : in out Slider_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button);
   overriding procedure On_Mouse_Wheel
     (W                : in out Slider_Widget;
      Delta_X, Delta_Y : Pixel_Type);
   overriding procedure On_Key_Down
     (W        : in out Slider_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

private

   type Slider_Widget is new Widget with record
      Value     : Value_Type := Zero;
      Min_Value : Value_Type := Zero;
      Max_Value : Value_Type := Zero;
      Step      : Value_Type := Zero;
      Dir       : Orientation := Horizontal;
      Dragging  : Boolean := False;
      Drag_Offset : Pixel_Type := 0.0;
      Changed : Value_Changed_Signals.Signal;
   end record;

   type Slider_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Slider_Handle : constant Slider_Handle := (Id => Widget_Stores.Null_Id);

end Adi.Widget.Slider_Impl;
