pragma Ada_2022;

with Adi.Signal;
with Adi.Widget.Text_Input; use Adi.Widget.Text_Input;
with Adi.SDL.Events;

generic
   type Value_Type is private;
   Zero : Value_Type;
   with function "+" (L, R : Value_Type) return Value_Type is <>;
   with function "-" (L, R : Value_Type) return Value_Type is <>;
   with function "<" (L, R : Value_Type) return Boolean is <>;
   with function "<=" (L, R : Value_Type) return Boolean is <>;
   with function To_Float (V : Value_Type) return Float;
   with function From_Float (F : Float) return Value_Type;
   with function Image (V : Value_Type) return String;
   with function Parse (S : String) return Value_Type;
   Allow_Decimal : Boolean := True;
package Adi.Widget.Value_Input_Impl is

   ---------------------------------------------------------------------------
   --  Value Input Widget - Numeric text field with filtering and clamping
   --
   --  Derives from Text_Input_Widget. Filters keyboard input to only
   --  accept numeric characters. Parses and clamps on focus loss.
   --
   --  Core generic that holds ALL implementation logic.
   --  Thin wrappers instantiate this with appropriate formals.
   ---------------------------------------------------------------------------

   type Value_Input_Widget is new Text_Input_Widget with private;
   type Value_Input_Widget_Access is access all Value_Input_Widget;

   --  Typed handle
   type Value_Input_Handle is private;
   Null_Value_Input_Handle : constant Value_Input_Handle;

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Value_Input_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Value_Input_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Value_Input_Handle) return Widget_Handle;
   function Try_As_Value_Input (H : Widget_Handle) return Value_Input_Handle;
   function Is_Valid (H : Value_Input_Handle) return Boolean;
   function "+" (H : Value_Input_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Value_Input_Handle; Styles : Part_Style_Array);

   procedure Set_Value (W : in out Value_Input_Widget; V : Value_Type);
   function  Get_Value (W : Value_Input_Widget) return Value_Type;

   procedure Set_Range (W : in out Value_Input_Widget; Min, Max : Value_Type);
   function  Get_Min   (W : Value_Input_Widget) return Value_Type;
   function  Get_Max   (W : Value_Input_Widget) return Value_Type;

   procedure Set_Step (W : in out Value_Input_Widget; S : Value_Type);
   function  Get_Step (W : Value_Input_Widget) return Value_Type;

   type Value_Changed_Callback is access procedure
     (W : Widget_Handle; Value : Value_Type);

   package Value_Changed_Signals is new Adi.Signal
     (Value_Changed_Callback, null);

   procedure Connect_Value_Changed
     (W : in out Value_Input_Widget; CB : Value_Changed_Callback);
   function Connect_Value_Changed
     (W : in out Value_Input_Widget; CB : Value_Changed_Callback)
      return Value_Changed_Signals.Connection_Id;
   procedure Disconnect_Value_Changed
     (W : in out Value_Input_Widget;
      Id : Value_Changed_Signals.Connection_Id);

   --  Typed handle method overloads
   procedure Set_Value (H : Value_Input_Handle; V : Value_Type);
   function  Get_Value (H : Value_Input_Handle) return Value_Type;
   procedure Set_Step (H : Value_Input_Handle; S : Value_Type);
   function  Get_Step (H : Value_Input_Handle) return Value_Type;
   procedure Set_Range (H : Value_Input_Handle; Min, Max : Value_Type);
   function  Get_Min (H : Value_Input_Handle) return Value_Type;
   function  Get_Max (H : Value_Input_Handle) return Value_Type;
   procedure Connect_Value_Changed
     (H : Value_Input_Handle; CB : Value_Changed_Callback);
   function  Connect_Value_Changed
     (H : Value_Input_Handle; CB : Value_Changed_Callback)
      return Value_Changed_Signals.Connection_Id;
   procedure Disconnect_Value_Changed
     (H : Value_Input_Handle; Id : Value_Changed_Signals.Connection_Id);

   overriding procedure On_Text_Input
     (W : in out Value_Input_Widget; Text : String);
   overriding procedure On_Key_Down
     (W        : in out Value_Input_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);
   overriding procedure On_Focus_Lost
     (W : in out Value_Input_Widget);
   overriding procedure On_Mouse_Wheel
     (W                : in out Value_Input_Widget;
      Delta_X, Delta_Y : Pixel_Type);

private

   type Value_Input_Widget is new Text_Input_Widget with record
      Num_Value      : Value_Type := Zero;
      Min_Value      : Value_Type := Zero;
      Max_Value      : Value_Type := Zero;
      Step           : Value_Type := Zero;
      Updating_Text  : Boolean := False;
      Value_Changed : Value_Changed_Signals.Signal;
   end record;

   type Value_Input_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Value_Input_Handle : constant Value_Input_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Value_Input_Impl;
