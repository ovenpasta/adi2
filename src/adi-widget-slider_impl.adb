--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Layout_Util;  use Adi.Layout_Util;
with Adi.SDL.Events;   use Adi.SDL.Events;

package body Adi.Widget.Slider_Impl is

   Panel_Idx     : constant Positive := 1;
   Track_Idx     : constant Positive := 2;
   Indicator_Idx : constant Positive := 3;
   Knob_Idx      : constant Positive := 4;

   ---------------------------------------------------------------------------
   --  Internal helpers
   ---------------------------------------------------------------------------

   function Clamp (V, Lo, Hi : Value_Type) return Value_Type is
   begin
      if V < Lo then
         return Lo;
      elsif Hi < V then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

   function Snap_To_Step (V, Min_V, Step_V : Value_Type) return Value_Type is
      Offset_F : Float;
      Step_F   : constant Float := To_Float (Step_V);
   begin
      if Step_F <= 0.0 then
         return V;
      end if;
      Offset_F := To_Float (V - Min_V);
      Offset_F := Float'Rounding (Offset_F / Step_F) * Step_F;
      return Min_V + From_Float (Offset_F);
   end Snap_To_Step;

   function Ratio (W : Slider_Widget) return Float is
      Range_F : constant Float := To_Float (W.Max_Value - W.Min_Value);
   begin
      if Range_F <= 0.0 then
         return 0.0;
      end if;
      return Float'Max (0.0,
        Float'Min (1.0,
          To_Float (W.Value - W.Min_Value) / Range_F));
   end Ratio;

   procedure Fire_Changed (W : in out Slider_Widget) is
      H   : constant Widget_Handle := Get_Handle (W);
      Val : constant Value_Type := W.Value;
      procedure Call (CB : Value_Changed_Callback) is
      begin CB (H, Val); end Call;
      procedure Emit is new Value_Changed_Signals.For_Each (Call);
   begin
      Emit (W.Changed);
   end Fire_Changed;

   --  Convert a pixel position along the track to a value.
   procedure Set_Value_From_Position
     (W   : in out Slider_Widget;
      Pos : Pixel_Type)
   is
      Main_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Knob_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Knob_Part);
      Content    : constant Rectangle :=
        Content_Box (Get_Geometry (W), Main_Style);
      Knob_Size  : Pixel_Type;
      Usable     : Pixel_Type;
      R          : Float;
      Range_F    : constant Float :=
        To_Float (W.Max_Value - W.Min_Value);
      New_Val    : Value_Type;
      Old_Val    : constant Value_Type := W.Value;
   begin
      if W.Dir = Horizontal then
         Knob_Size :=
           (if Knob_Style.Width.Kind = Fixed
            then Size_To_Px (Knob_Style.Width, Container_Size => Content.Width)
            else Content.Height);
         Usable := Content.Width - Knob_Size;
         if Usable <= 0.0 then
            return;
         end if;
         R := Float ((Pos - Content.X - Knob_Size / 2.0) / Usable);
      else
         Knob_Size :=
           (if Knob_Style.Height.Kind = Fixed
            then Size_To_Px (Knob_Style.Height, Container_Size => Content.Height)
            else Content.Width);
         Usable := Content.Height - Knob_Size;
         if Usable <= 0.0 then
            return;
         end if;
         R := Float ((Pos - Content.Y - Knob_Size / 2.0) / Usable);
      end if;

      R := Float'Max (0.0, Float'Min (1.0, R));
      New_Val := W.Min_Value + From_Float (R * Range_F);
      New_Val := Snap_To_Step (New_Val, W.Min_Value, W.Step);
      New_Val := Clamp (New_Val, W.Min_Value, W.Max_Value);
      W.Value := New_Val;

      if To_Float (New_Val) /= To_Float (Old_Val) then
         Mark_Dirty (W);
         Fire_Changed (W);
      end if;
   end Set_Value_From_Position;

   procedure Update_Slider_Items (W : in out Slider_Widget) is
      Main_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Track_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Scroll_Part);
      Knob_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Knob_Part);
      Widget_Geom : constant Rectangle := Get_Geometry (W);
      Content     : constant Rectangle :=
        Content_Box (Widget_Geom, Main_Style);
      R           : constant Float := Ratio (W);

      Panel_Item : Item;
      Track_Item : Item;
      Fill_Item  : Item;
      Knob_Item  : Item;
   begin
      if Item_Count (W) < Knob_Idx then
         return;
      end if;

      Panel_Item := Get_Item (W, Panel_Idx);
      Panel_Item.Geometry := Widget_Geom;
      Update_Item (W, Panel_Idx, Panel_Item);

      if W.Dir = Horizontal then
         declare
            --  The bar is as thick as ::scroll asks and sits centred
            --  in the widget. Without a height it fills the box.
            Band_H : constant Pixel_Type :=
              (if Track_Style.Height.Kind = Fixed
               then Pixel_Type'Min
                      (Content.Height,
                       Size_To_Px (Track_Style.Height,
                                   Container_Size => Content.Height))
               else Content.Height);
            Band_Y : constant Pixel_Type :=
              Content.Y + (Content.Height - Band_H) / 2.0;

            --  The knob spans the widget, not the bar, so a bar thinner
            --  than the knob leaves the knob round and the whole widget
            --  height still takes the press.
            Knob_H : Pixel_Type := Content.Height;
            Knob_W : Pixel_Type :=
              (if Knob_Style.Width.Kind = Fixed
               then Size_To_Px (Knob_Style.Width, Container_Size => Content.Width)
               else Knob_H);
            Usable : constant Pixel_Type :=
              Pixel_Type'Max (0.0, Content.Width - Knob_W);
            Knob_X : constant Pixel_Type :=
              Content.X + Pixel_Type (R) * Usable;
            Knob_Y : constant Pixel_Type := Content.Y;
            --  Extend fill to knob's right edge so the indicator's
            --  right border-radius curves under the knob (no gap).
            Fill_W : constant Pixel_Type :=
              Knob_X + Knob_W - Content.X;
         begin
            Knob_W := Pixel_Type'Max (0.0, Knob_W);
            Knob_H := Pixel_Type'Max (0.0, Knob_H);

            Track_Item := Get_Item (W, Track_Idx);
            Track_Item.Geometry := (
              X      => Content.X,
              Y      => Band_Y,
              Width  => Content.Width,
              Height => Band_H);
            Update_Item (W, Track_Idx, Track_Item);

            Fill_Item := Get_Item (W, Indicator_Idx);
            Fill_Item.Geometry := (
              X      => Content.X,
              Y      => Band_Y,
              Width  => Pixel_Type'Max (0.0, Fill_W),
              Height => Band_H);
            Update_Item (W, Indicator_Idx, Fill_Item);

            Knob_Item := Get_Item (W, Knob_Idx);
            Knob_Item.Geometry := (
              X      => Knob_X,
              Y      => Knob_Y,
              Width  => Knob_W,
              Height => Knob_H);
            Update_Item (W, Knob_Idx, Knob_Item);
         end;
      else
         declare
            Band_W : constant Pixel_Type :=
              (if Track_Style.Width.Kind = Fixed
               then Pixel_Type'Min
                      (Content.Width,
                       Size_To_Px (Track_Style.Width,
                                   Container_Size => Content.Width))
               else Content.Width);
            Band_X : constant Pixel_Type :=
              Content.X + (Content.Width - Band_W) / 2.0;

            Knob_W : Pixel_Type := Content.Width;
            Knob_H : Pixel_Type :=
              (if Knob_Style.Height.Kind = Fixed
               then Size_To_Px (Knob_Style.Height, Container_Size => Content.Height)
               else Knob_W);
            Usable : constant Pixel_Type :=
              Pixel_Type'Max (0.0, Content.Height - Knob_H);
            Knob_Y : constant Pixel_Type :=
              Content.Y + Pixel_Type (R) * Usable;
            Knob_X : constant Pixel_Type := Content.X;
            Fill_H : constant Pixel_Type :=
              Knob_Y + Knob_H - Content.Y;
         begin
            Knob_W := Pixel_Type'Max (0.0, Knob_W);
            Knob_H := Pixel_Type'Max (0.0, Knob_H);

            Track_Item := Get_Item (W, Track_Idx);
            Track_Item.Geometry := (
              X      => Band_X,
              Y      => Content.Y,
              Width  => Band_W,
              Height => Content.Height);
            Update_Item (W, Track_Idx, Track_Item);

            Fill_Item := Get_Item (W, Indicator_Idx);
            Fill_Item.Geometry := (
              X      => Band_X,
              Y      => Content.Y,
              Width  => Band_W,
              Height => Pixel_Type'Max (0.0, Fill_H));
            Update_Item (W, Indicator_Idx, Fill_Item);

            Knob_Item := Get_Item (W, Knob_Idx);
            Knob_Item.Geometry := (
              X      => Knob_X,
              Y      => Knob_Y,
              Width  => Knob_W,
              Height => Knob_H);
            Update_Item (W, Knob_Idx, Knob_Item);
         end;
      end if;
   end Update_Slider_Items;

   ---------------------------------------------------------------------------
   --  Public API
   ---------------------------------------------------------------------------

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Slider_Widget_Access
   is
      Result : constant Slider_Widget_Access := new Slider_Widget;
   begin
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);
      Set_Flag (Result.all, Visible, True);
      Result.Min_Value := Min;
      Result.Max_Value := Max;
      Result.Value := Clamp (Value, Min, Max);
      declare
         P : constant access Widget'Class := Result.all'Unchecked_Access;
      begin
         Register_Widget (Widget_Access (P));
      end;
      return Result;
   end Create;

   function Create_Handle
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Slider_Handle
   is
   begin
      return (Id => Get_Handle (Create (Min, Max, Value).all).Id);
   end Create_Handle;

   function To_Widget_Handle (H : Slider_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Slider (H : Widget_Handle) return Slider_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Slider_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Slider_Handle;
   end Try_As_Slider;

   function Is_Valid (H : Slider_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   procedure Set_Value (W : in out Slider_Widget; V : Value_Type) is
      Clamped : constant Value_Type := Clamp (V, W.Min_Value, W.Max_Value);
   begin
      if To_Float (Clamped) /= To_Float (W.Value) then
         W.Value := Clamped;
         Mark_Dirty (W);
      end if;
   end Set_Value;

   function Get_Value (W : Slider_Widget) return Value_Type is
   begin
      return W.Value;
   end Get_Value;

   procedure Set_Range (W : in out Slider_Widget; Min, Max : Value_Type) is
   begin
      W.Min_Value := Min;
      W.Max_Value := Max;
      W.Value := Clamp (W.Value, Min, Max);
      Mark_Dirty (W);
   end Set_Range;

   function Get_Min (W : Slider_Widget) return Value_Type is
   begin
      return W.Min_Value;
   end Get_Min;

   function Get_Max (W : Slider_Widget) return Value_Type is
   begin
      return W.Max_Value;
   end Get_Max;

   procedure Set_Step (W : in out Slider_Widget; S : Value_Type) is
   begin
      W.Step := S;
   end Set_Step;

   function Get_Step (W : Slider_Widget) return Value_Type is
   begin
      return W.Step;
   end Get_Step;

   procedure Set_Orientation (W : in out Slider_Widget; Dir : Orientation) is
   begin
      W.Dir := Dir;
      Mark_Dirty (W);
   end Set_Orientation;

   function Get_Orientation (W : Slider_Widget) return Orientation is
   begin
      return W.Dir;
   end Get_Orientation;

   procedure Connect_Changed (W  : in out Slider_Widget;
                              CB : Value_Changed_Callback) is
   begin
      W.Changed.Connect (CB);
   end Connect_Changed;

   function Connect_Changed (W  : in out Slider_Widget;
                             CB : Value_Changed_Callback)
      return Value_Changed_Signals.Connection_Id is
   begin
      return W.Changed.Connect (CB);
   end Connect_Changed;

   procedure Disconnect_Changed
     (W : in out Slider_Widget; Id : Value_Changed_Signals.Connection_Id) is
   begin
      W.Changed.Disconnect (Id);
   end Disconnect_Changed;

   ---------------------------------------------------------------------------
   --  Typed handle method overloads
   ---------------------------------------------------------------------------

   procedure Set_Value (H : Slider_Handle; V : Value_Type) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Value (Slider_Widget (Ptr.all), V);
      end if;
   end Set_Value;

   function Get_Value (H : Slider_Handle) return Value_Type is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Value (Slider_Widget (Ptr.all));
      end if;
      return Zero;
   end Get_Value;

   procedure Connect_Changed (H : Slider_Handle; CB : Value_Changed_Callback) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Changed (Slider_Widget (Ptr.all), CB);
      end if;
   end Connect_Changed;

   function Connect_Changed (H : Slider_Handle; CB : Value_Changed_Callback)
     return Value_Changed_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Changed (Slider_Widget (Ptr.all), CB);
      end if;
      return Value_Changed_Signals.No_Connection;
   end Connect_Changed;

   procedure Disconnect_Changed
     (H : Slider_Handle; Id : Value_Changed_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Changed (Slider_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Changed;

   procedure Set_Step (H : Slider_Handle; S : Value_Type) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Step (Slider_Widget (Ptr.all), S);
      end if;
   end Set_Step;

   function Get_Step (H : Slider_Handle) return Value_Type is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Step (Slider_Widget (Ptr.all));
      end if;
      return Zero;
   end Get_Step;

   procedure Set_Range (H : Slider_Handle; Min, Max : Value_Type) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Range (Slider_Widget (Ptr.all), Min, Max);
      end if;
   end Set_Range;

   function Get_Min (H : Slider_Handle) return Value_Type is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Min (Slider_Widget (Ptr.all));
      end if;
      return Zero;
   end Get_Min;

   function Get_Max (H : Slider_Handle) return Value_Type is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Max (Slider_Widget (Ptr.all));
      end if;
      return Zero;
   end Get_Max;

   procedure Set_Orientation (H : Slider_Handle; Dir : Orientation) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Orientation (Slider_Widget (Ptr.all), Dir);
      end if;
   end Set_Orientation;

   function Get_Orientation (H : Slider_Handle) return Orientation is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Orientation (Slider_Widget (Ptr.all));
      end if;
      return Horizontal;
   end Get_Orientation;

   function "+" (H : Slider_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Slider_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   ---------------------------------------------------------------------------
   --  Widget overrides
   ---------------------------------------------------------------------------

   overriding function Measure_Content (W : Slider_Widget) return Size_2D is
      pragma Unreferenced (W);
   begin
      return (Width => 200.0, Height => 24.0);
   end Measure_Content;

   overriding procedure Build_Items (W : in out Slider_Widget) is
   begin
      if Item_Count (W) = 0 then
         declare
            G : constant Rectangle := Get_Geometry (W);
         begin
            Add_Item (W, Make_Panel (Main_Part, G, 0));
            Add_Item (W, Make_Panel (Scroll_Part, G, 1));
            Add_Item (W, Make_Panel (Indicator_Part, G, 2));
            Add_Item (W, Make_Panel (Knob_Part, G, 3));
         end;
      end if;

      Update_Slider_Items (W);
   end Build_Items;

   overriding procedure Layout (W : in out Slider_Widget) is
   begin
      Update_Slider_Items (W);
   end Layout;

   overriding procedure On_Mouse_Down
     (W      : in out Slider_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (Clicks);
   begin
      if Button /= Left_Button or else Is_Disabled (W) then
         return;
      end if;

      W.Dragging := True;

      --  Check if click is on knob; if so, record offset for smooth drag.
      if Item_Count (W) >= Knob_Idx then
         declare
            Knob_Geom : constant Rectangle := Get_Item (W, Knob_Idx).Geometry;
         begin
            if W.Dir = Horizontal then
               if X >= Knob_Geom.X
                 and then X <= Knob_Geom.X + Knob_Geom.Width
               then
                  W.Drag_Offset := X - (Knob_Geom.X + Knob_Geom.Width / 2.0);
                  return;
               end if;
            else
               if Y >= Knob_Geom.Y
                 and then Y <= Knob_Geom.Y + Knob_Geom.Height
               then
                  W.Drag_Offset := Y - (Knob_Geom.Y + Knob_Geom.Height / 2.0);
                  return;
               end if;
            end if;
         end;
      end if;

      --  Click on track: jump to position
      W.Drag_Offset := 0.0;
      if W.Dir = Horizontal then
         Set_Value_From_Position (W, X);
      else
         Set_Value_From_Position (W, Y);
      end if;
   end On_Mouse_Down;

   overriding procedure On_Mouse_Move
     (W    : in out Slider_Widget;
      X, Y : Pixel_Type)
   is
   begin
      if not W.Dragging then
         return;
      end if;

      if W.Dir = Horizontal then
         Set_Value_From_Position (W, X - W.Drag_Offset);
      else
         Set_Value_From_Position (W, Y - W.Drag_Offset);
      end if;
   end On_Mouse_Move;

   overriding procedure On_Mouse_Up
     (W      : in out Slider_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button)
   is
      pragma Unreferenced (X, Y);
   begin
      if Button = Left_Button then
         W.Dragging := False;
      end if;
   end On_Mouse_Up;

   overriding procedure On_Mouse_Wheel
     (W                : in out Slider_Widget;
      Delta_X, Delta_Y : Pixel_Type)
   is
      pragma Unreferenced (Delta_X);
      Step_F : constant Float := To_Float (W.Step);
      Inc    : Value_Type;
      Range_F : constant Float :=
        To_Float (W.Max_Value - W.Min_Value);
   begin
      if Is_Disabled (W) then
         return;
      end if;
      if Step_F > 0.0 then
         Inc := W.Step;
      elsif Range_F > 0.0 then
         Inc := From_Float (Range_F / 100.0);
      else
         return;
      end if;

      if Delta_Y > 0.0 then
         Set_Value (W, Clamp (W.Value + Inc, W.Min_Value, W.Max_Value));
      elsif Delta_Y < 0.0 then
         Set_Value (W, Clamp (W.Value - Inc, W.Min_Value, W.Max_Value));
      end if;

      Fire_Changed (W);
   end On_Mouse_Wheel;

   overriding procedure On_Key_Down
     (W        : in out Slider_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
      pragma Unreferenced (Key_Mod, Repeat);
      Step_F  : constant Float := To_Float (W.Step);
      Range_F : constant Float :=
        To_Float (W.Max_Value - W.Min_Value);
      Inc     : Value_Type;
   begin
      if Is_Disabled (W) then
         return;
      end if;
      if Step_F > 0.0 then
         Inc := W.Step;
      elsif Range_F > 0.0 then
         Inc := From_Float (Range_F / 100.0);
      else
         return;
      end if;

      case Scancode is
         when SDL_SCANCODE_RIGHT | SDL_SCANCODE_UP =>
            Set_Value (W, Clamp (W.Value + Inc, W.Min_Value, W.Max_Value));
            Fire_Changed (W);

         when SDL_SCANCODE_LEFT | SDL_SCANCODE_DOWN =>
            Set_Value (W, Clamp (W.Value - Inc, W.Min_Value, W.Max_Value));
            Fire_Changed (W);

         when SDL_SCANCODE_HOME =>
            Set_Value (W, W.Min_Value);
            Fire_Changed (W);

         when SDL_SCANCODE_END =>
            Set_Value (W, W.Max_Value);
            Fire_Changed (W);

         when others =>
            null;
      end case;
   end On_Key_Down;

end Adi.Widget.Slider_Impl;
