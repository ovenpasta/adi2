--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Widget.Slider_Impl;

generic
   type Value_Type is range <>;
package Adi.Widget.Integer_Slider is

   ---------------------------------------------------------------------------
   --  Integer Slider Widget
   --
   --  Thin wrapper over Slider_Impl that resolves the formal functions
   --  for an integer type.
   --
   --  Usage:
   --    package My_Slider is new Adi.Widget.Integer_Slider (Natural);
   --    S : My_Slider.Slider_Widget_Access :=
   --      My_Slider.Create (Min => 0, Max => 255, Value => 128);
   ---------------------------------------------------------------------------

   function Conv_To_Float (V : Value_Type) return Float is (Float (V));
   function Conv_From_Float (F : Float) return Value_Type is
     (Value_Type (Float'Rounding (F)));

   package Impl is new Slider_Impl
     (Value_Type => Value_Type,
      Zero       => 0,
      To_Float   => Conv_To_Float,
      From_Float => Conv_From_Float);

   subtype Orientation is Impl.Orientation;
   Horizontal : Orientation renames Impl.Horizontal;
   Vertical   : Orientation renames Impl.Vertical;

   subtype Slider_Widget is Impl.Slider_Widget;
   subtype Slider_Widget_Access is Impl.Slider_Widget_Access;
   subtype Value_Changed_Callback is Impl.Value_Changed_Callback;
   subtype Slider_Handle is Impl.Slider_Handle;
   Null_Slider_Handle : Impl.Slider_Handle renames Impl.Null_Slider_Handle;

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type := 0) return Slider_Widget_Access
     renames Impl.Create;
   pragma Obsolescent (Create, "Use Create_Handle");
   function Create_Handle
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type := 0) return Slider_Handle
     renames Impl.Create_Handle;

   function To_Widget_Handle (H : Slider_Handle) return Widget_Handle
     renames Impl.To_Widget_Handle;
   function Try_As_Slider (H : Widget_Handle) return Slider_Handle
     renames Impl.Try_As_Slider;
   function Is_Valid (H : Slider_Handle) return Boolean
     renames Impl.Is_Valid;

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

   --  Typed handle method overloads
   procedure Set_Value (H : Slider_Handle; V : Value_Type)
     renames Impl.Set_Value;
   function  Get_Value (H : Slider_Handle) return Value_Type
     renames Impl.Get_Value;
   procedure Set_Step (H : Slider_Handle; S : Value_Type)
     renames Impl.Set_Step;
   function  Get_Step (H : Slider_Handle) return Value_Type
     renames Impl.Get_Step;
   procedure Set_Range (H : Slider_Handle; Min, Max : Value_Type)
     renames Impl.Set_Range;
   function  Get_Min (H : Slider_Handle) return Value_Type
     renames Impl.Get_Min;
   function  Get_Max (H : Slider_Handle) return Value_Type
     renames Impl.Get_Max;
   procedure Set_Orientation (H : Slider_Handle; Dir : Orientation)
     renames Impl.Set_Orientation;
   function  Get_Orientation (H : Slider_Handle) return Orientation
     renames Impl.Get_Orientation;
   procedure Connect_Changed (H  : Slider_Handle;
                               CB : Value_Changed_Callback)
     renames Impl.Connect_Changed;
   function  Connect_Changed (H  : Slider_Handle;
                               CB : Value_Changed_Callback)
     return Value_Changed_Connection_Id
     renames Impl.Connect_Changed;
   procedure Disconnect_Changed (H  : Slider_Handle;
                                  Id : Value_Changed_Connection_Id)
     renames Impl.Disconnect_Changed;
   function "+" (H : Slider_Handle) return Widget_Handle
     renames Impl."+";
   procedure Set_Part_Styles (H : Slider_Handle; Styles : Part_Style_Array)
     renames Impl.Set_Part_Styles;

end Adi.Widget.Integer_Slider;
