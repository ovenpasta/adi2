pragma Ada_2022;

with Adi.Widget.Value_Input_Impl;

generic
   type Value_Type is range <>;
package Adi.Widget.Integer_Value_Input is

   ---------------------------------------------------------------------------
   --  Integer Value Input Widget
   --
   --  Thin wrapper over Value_Input_Impl that resolves the formal functions
   --  for an integer type.
   --
   --  Usage:
   --    package My_Input is new Adi.Widget.Integer_Value_Input (Natural);
   --    V : My_Input.Value_Input_Widget_Access :=
   --      My_Input.Create (Min => 0, Max => 255, Value => 128);
   ---------------------------------------------------------------------------

   function Conv_To_Float (V : Value_Type) return Float is (Float (V));
   function Conv_From_Float (F : Float) return Value_Type is
     (Value_Type (Float'Rounding (F)));
   function Conv_Image (V : Value_Type) return String;
   function Conv_Parse (S : String) return Value_Type is (Value_Type'Value (S));

   package Impl is new Value_Input_Impl
     (Value_Type    => Value_Type,
      Zero          => 0,
      To_Float      => Conv_To_Float,
      From_Float    => Conv_From_Float,
      Image         => Conv_Image,
      Parse         => Conv_Parse,
      Allow_Decimal => False);

   subtype Value_Input_Widget is Impl.Value_Input_Widget;
   subtype Value_Input_Widget_Access is Impl.Value_Input_Widget_Access;
   subtype Value_Changed_Callback is Impl.Value_Changed_Callback;
   subtype Value_Input_Handle is Impl.Value_Input_Handle;
   Null_Value_Input_Handle : Impl.Value_Input_Handle
     renames Impl.Null_Value_Input_Handle;

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type := 0) return Value_Input_Widget_Access
     renames Impl.Create;
   function Create_Handle
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type := 0) return Value_Input_Handle
     renames Impl.Create_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Value_Input_Handle) return Widget_Handle
     renames Impl.To_Widget_Handle;
   function Try_As_Value_Input (H : Widget_Handle) return Value_Input_Handle
     renames Impl.Try_As_Value_Input;
   function Is_Valid (H : Value_Input_Handle) return Boolean
     renames Impl.Is_Valid;
   function "+" (H : Value_Input_Handle) return Widget_Handle
     renames Impl."+";
   procedure Set_Part_Styles (H : Value_Input_Handle; Styles : Part_Style_Array)
     renames Impl.Set_Part_Styles;

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

   subtype Value_Changed_Connection_Id is
     Impl.Value_Changed_Signals.Connection_Id;

   procedure Connect_Value_Changed (W  : in out Value_Input_Widget;
                                     CB : Value_Changed_Callback)
     renames Impl.Connect_Value_Changed;
   function Connect_Value_Changed (W  : in out Value_Input_Widget;
                                    CB : Value_Changed_Callback)
     return Value_Changed_Connection_Id
     renames Impl.Connect_Value_Changed;
   procedure Disconnect_Value_Changed (W  : in out Value_Input_Widget;
                                        Id : Value_Changed_Connection_Id)
     renames Impl.Disconnect_Value_Changed;

   --  Typed handle method overloads
   procedure Set_Value (H : Value_Input_Handle; V : Value_Type)
     renames Impl.Set_Value;
   function  Get_Value (H : Value_Input_Handle) return Value_Type
     renames Impl.Get_Value;
   procedure Set_Step (H : Value_Input_Handle; S : Value_Type)
     renames Impl.Set_Step;
   function  Get_Step (H : Value_Input_Handle) return Value_Type
     renames Impl.Get_Step;
   procedure Set_Range (H : Value_Input_Handle; Min, Max : Value_Type)
     renames Impl.Set_Range;
   function  Get_Min (H : Value_Input_Handle) return Value_Type
     renames Impl.Get_Min;
   function  Get_Max (H : Value_Input_Handle) return Value_Type
     renames Impl.Get_Max;
   procedure Connect_Value_Changed (H  : Value_Input_Handle;
                                     CB : Value_Changed_Callback)
     renames Impl.Connect_Value_Changed;
   function  Connect_Value_Changed (H  : Value_Input_Handle;
                                     CB : Value_Changed_Callback)
     return Value_Changed_Connection_Id
     renames Impl.Connect_Value_Changed;
   procedure Disconnect_Value_Changed (H  : Value_Input_Handle;
                                        Id : Value_Changed_Connection_Id)
     renames Impl.Disconnect_Value_Changed;

end Adi.Widget.Integer_Value_Input;
