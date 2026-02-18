pragma Ada_2022;

with Adi.Widget.Value_Input_Impl;

generic
   type Value_Type is digits <>;
package Adi.Widget.Value_Input is

   ---------------------------------------------------------------------------
   --  Value Input Widget (floating-point)
   --
   --  Thin wrapper over Value_Input_Impl that resolves the formal functions
   --  for a floating-point type.
   --
   --  Usage:
   --    package My_Input is new Adi.Widget.Value_Input (Float);
   --    V : My_Input.Value_Input_Widget_Access :=
   --      My_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
   ---------------------------------------------------------------------------

   function Conv_To_Float (V : Value_Type) return Float is (Float (V));
   function Conv_From_Float (F : Float) return Value_Type is (Value_Type (F));
   function Conv_Image (V : Value_Type) return String;
   function Conv_Parse (S : String) return Value_Type is (Value_Type'Value (S));

   package Impl is new Value_Input_Impl
     (Value_Type    => Value_Type,
      Zero          => 0.0,
      To_Float      => Conv_To_Float,
      From_Float    => Conv_From_Float,
      Image         => Conv_Image,
      Parse         => Conv_Parse,
      Allow_Decimal => True);

   subtype Value_Input_Widget is Impl.Value_Input_Widget;
   subtype Value_Input_Widget_Access is Impl.Value_Input_Widget_Access;
   subtype Value_Changed_Callback is Impl.Value_Changed_Callback;

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type := 0.0) return Value_Input_Widget_Access
     renames Impl.Create;

   procedure Set_Value (W : in out Value_Input_Widget; V : Value_Type)
     renames Impl.Set_Value;
   function  Get_Value (W : Value_Input_Widget) return Value_Type
     renames Impl.Get_Value;

   procedure Set_Range (W : in out Value_Input_Widget; Min, Max : Value_Type)
     renames Impl.Set_Range;
   function  Get_Min (W : Value_Input_Widget) return Value_Type
     renames Impl.Get_Min;
   function  Get_Max (W : Value_Input_Widget) return Value_Type
     renames Impl.Get_Max;

   procedure Set_Step (W : in out Value_Input_Widget; S : Value_Type)
     renames Impl.Set_Step;
   function  Get_Step (W : Value_Input_Widget) return Value_Type
     renames Impl.Get_Step;

   procedure Set_On_Value_Changed (W  : in out Value_Input_Widget;
                                    CB : Value_Changed_Callback)
     renames Impl.Set_On_Value_Changed;

end Adi.Widget.Value_Input;
