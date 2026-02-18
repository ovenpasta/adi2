pragma Ada_2022;

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

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Value_Input_Widget_Access;

   procedure Set_Value (W : in out Value_Input_Widget; V : Value_Type);
   function  Get_Value (W : Value_Input_Widget) return Value_Type;

   procedure Set_Range (W : in out Value_Input_Widget; Min, Max : Value_Type);
   function  Get_Min   (W : Value_Input_Widget) return Value_Type;
   function  Get_Max   (W : Value_Input_Widget) return Value_Type;

   procedure Set_Step (W : in out Value_Input_Widget; S : Value_Type);
   function  Get_Step (W : Value_Input_Widget) return Value_Type;

   type Value_Changed_Callback is access procedure
     (W : Value_Input_Widget_Access; Value : Value_Type);
   procedure Set_On_Value_Changed (W  : in out Value_Input_Widget;
                                    CB : Value_Changed_Callback);

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
      On_Val_Changed : Value_Changed_Callback := null;
   end record;

end Adi.Widget.Value_Input_Impl;
