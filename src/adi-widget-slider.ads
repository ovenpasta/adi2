pragma Ada_2022;

with Adi.Widget.Slider_Impl;

generic
   type Value_Type is digits <>;
package Adi.Widget.Slider is

   ---------------------------------------------------------------------------
   --  Slider Widget (floating-point)
   --
   --  Thin wrapper over Slider_Impl that resolves the formal functions
   --  for a floating-point type.
   --
   --  Usage:
   --    package My_Slider is new Adi.Widget.Slider (Float);
   --    S : My_Slider.Slider_Widget_Access :=
   --      My_Slider.Create (Min => 0.0, Max => 100.0, Value => 50.0);
   ---------------------------------------------------------------------------

   function Conv_To_Float (V : Value_Type) return Float is (Float (V));
   function Conv_From_Float (F : Float) return Value_Type is (Value_Type (F));

   package Impl is new Slider_Impl
     (Value_Type => Value_Type,
      Zero       => 0.0,
      To_Float   => Conv_To_Float,
      From_Float => Conv_From_Float);

   subtype Orientation is Impl.Orientation;
   Horizontal : Orientation renames Impl.Horizontal;
   Vertical   : Orientation renames Impl.Vertical;

   subtype Slider_Widget is Impl.Slider_Widget;
   subtype Slider_Widget_Access is Impl.Slider_Widget_Access;
   subtype Value_Changed_Callback is Impl.Value_Changed_Callback;

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type := 0.0) return Slider_Widget_Access
     renames Impl.Create;

   procedure Set_Value (W : in out Slider_Widget; V : Value_Type)
     renames Impl.Set_Value;
   function  Get_Value (W : Slider_Widget) return Value_Type
     renames Impl.Get_Value;

   procedure Set_Range (W : in out Slider_Widget; Min, Max : Value_Type)
     renames Impl.Set_Range;
   function  Get_Min (W : Slider_Widget) return Value_Type
     renames Impl.Get_Min;
   function  Get_Max (W : Slider_Widget) return Value_Type
     renames Impl.Get_Max;

   procedure Set_Step (W : in out Slider_Widget; S : Value_Type)
     renames Impl.Set_Step;
   function  Get_Step (W : Slider_Widget) return Value_Type
     renames Impl.Get_Step;

   procedure Set_Orientation (W : in out Slider_Widget; Dir : Orientation)
     renames Impl.Set_Orientation;
   function  Get_Orientation (W : Slider_Widget) return Orientation
     renames Impl.Get_Orientation;

   subtype Value_Changed_Connection_Id is
     Impl.Value_Changed_Signals.Connection_Id;

   procedure Connect_Changed (W  : in out Slider_Widget;
                               CB : Value_Changed_Callback)
     renames Impl.Connect_Changed;
   function Connect_Changed (W  : in out Slider_Widget;
                              CB : Value_Changed_Callback)
     return Value_Changed_Connection_Id
     renames Impl.Connect_Changed;
   procedure Disconnect_Changed (W  : in out Slider_Widget;
                                  Id : Value_Changed_Connection_Id)
     renames Impl.Disconnect_Changed;

end Adi.Widget.Slider;
