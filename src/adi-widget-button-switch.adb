--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Button.Switch is

   Panel_Idx : constant Positive := 1;
   Knob_Idx  : constant Positive := 2;

   procedure Update_Switch_Items (W : in out Switch_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Knob_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Knob_Part);
      Widget_Geom : constant Rectangle := Get_Geometry (W);
      Content    : constant Rectangle := Content_Box (Widget_Geom, Main_Style);
      Margin     : constant Edge_Pixels := Get_Margin_Px (Knob_Style);

      Track_Item : Item;
      Knob_Item  : Item;

      Available_H : constant Pixel_Type :=
        Pixel_Type'Max (0.0, Content.Height - Margin.Top - Margin.Bottom);
      Available_W : constant Pixel_Type :=
        Pixel_Type'Max (0.0, Content.Width - Margin.Left - Margin.Right);

      Knob_H : Pixel_Type :=
        (if Knob_Style.Height.Kind = Fixed
         then Size_To_Px (Knob_Style.Height, Container_Size => Content.Height)
         else Available_H);
      Knob_W : Pixel_Type :=
        (if Knob_Style.Width.Kind = Fixed
         then Size_To_Px (Knob_Style.Width, Container_Size => Content.Width)
         else Knob_H);

      Knob_X : Pixel_Type;
      Knob_Y : Pixel_Type;
   begin
      if Item_Count (W) < 2 then
         return;
      end if;

      Knob_H := Pixel_Type'Max (0.0, Pixel_Type'Min (Knob_H, Available_H));
      Knob_W := Pixel_Type'Max (0.0, Pixel_Type'Min (Knob_W, Available_W));

      Knob_Y := Content.Y + Margin.Top + (Available_H - Knob_H) / 2.0;

      if Is_Checked (W) then
         Knob_X := Content.X + Content.Width - Margin.Right - Knob_W;
      else
         Knob_X := Content.X + Margin.Left;
      end if;

      Track_Item := Get_Item (W, Panel_Idx);
      Track_Item.Geometry := Widget_Geom;
      Update_Item (W, Panel_Idx, Track_Item);

      Knob_Item := Get_Item (W, Knob_Idx);
      Knob_Item.Geometry := (
        X      => Knob_X,
        Y      => Knob_Y,
        Width  => Knob_W,
        Height => Knob_H);
      Update_Item (W, Knob_Idx, Knob_Item);
   end Update_Switch_Items;

   ------------
   -- Create --
   ------------

   function Create (Checked : Boolean := False) return Switch_Widget_Access is
      Result : constant Switch_Widget_Access := new Switch_Widget;
   begin
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);
      Set_Flag (Result.all, Visible, True);
      Set_Toggleable (Result.all, True);
      Set_Checked (Result.all, Checked);
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle (Checked : Boolean := False) return Switch_Handle is
   begin
      return (Id => Get_Handle (Create (Checked).all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Switch_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Switch (H : Widget_Handle) return Switch_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Switch_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Switch_Handle;
   end Try_As_Switch;

   function Is_Valid (H : Switch_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Switch_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : Switch_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   procedure Set_Checked (H : Switch_Handle; Value : Boolean) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Checked (Switch_Widget (Ptr.all), Value);
      end if;
   end Set_Checked;

   function Is_Checked (H : Switch_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Checked (Switch_Widget (Ptr.all));
      end if;
      return False;
   end Is_Checked;

   procedure Connect_Clicked (H : Switch_Handle; CB : Click_Callback) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Clicked (Button_Widget (Ptr.all), CB);
      end if;
   end Connect_Clicked;

   function Connect_Clicked (H : Switch_Handle; CB : Click_Callback)
     return Click_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Clicked (Button_Widget (Ptr.all), CB);
      end if;
      return Click_Signals.No_Connection;
   end Connect_Clicked;

   procedure Disconnect_Clicked
     (H : Switch_Handle; Id : Click_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Clicked (Button_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Clicked;

   procedure Connect_Toggled (H : Switch_Handle; CB : Toggle_Callback) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Toggled (Button_Widget (Ptr.all), CB);
      end if;
   end Connect_Toggled;

   function Connect_Toggled (H : Switch_Handle; CB : Toggle_Callback)
     return Toggle_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Toggled (Button_Widget (Ptr.all), CB);
      end if;
      return Toggle_Signals.No_Connection;
   end Connect_Toggled;

   procedure Disconnect_Toggled
     (H : Switch_Handle; Id : Toggle_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Toggled (Button_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Toggled;

   procedure Set_Toggleable (H : Switch_Handle; Value : Boolean := True) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Toggleable (Button_Widget (Ptr.all), Value);
      end if;
   end Set_Toggleable;

   function Is_Toggleable (H : Switch_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Toggleable (Button_Widget (Ptr.all));
      end if;
      return False;
   end Is_Toggleable;

   function Is_Toggled (H : Switch_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Toggled (Button_Widget (Ptr.all));
      end if;
      return False;
   end Is_Toggled;

   procedure Set_Toggled (H : Switch_Handle; Value : Boolean) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Toggled (Button_Widget (Ptr.all), Value);
      end if;
   end Set_Toggled;

   -----------------
   -- Set_Checked --
   -----------------

   procedure Set_Checked (W : in out Switch_Widget; Value : Boolean) is
   begin
      Set_Toggled (W, Value);
   end Set_Checked;

   ----------------
   -- Is_Checked --
   ----------------

   function Is_Checked (W : Switch_Widget) return Boolean is
   begin
      return Is_Toggled (W);
   end Is_Checked;

   -----------------
   -- Measure_Content --
   -----------------

   overriding function Measure_Content (W : Switch_Widget) return Size_2D is
      pragma Unreferenced (W);
   begin
      --  A switch has no inherent content size — no text, no image, just
      --  a pill and a knob whose dimensions are pure design decisions.
      --  Following Adi's "no style in widget code" principle, return zero
      --  and require the CSS class to set width/height on the switch and
      --  ::knob.  The widget renders nothing if the class is incomplete;
      --  that's the intended loud failure mode for the missing rule.
      return (0.0, 0.0);
   end Measure_Content;

   -----------------
   -- Build_Items --
   -----------------

   overriding procedure Build_Items (W : in out Switch_Widget) is
   begin
      if Item_Count (W) = 0 then
         declare
            G : constant Rectangle := Get_Geometry (W);
         begin
            Add_Item (W, Make_Panel (Main_Part, G, 0));
            Add_Item (W, Make_Panel (Knob_Part, G, 1));
         end;
      end if;

      Update_Switch_Items (W);
   end Build_Items;

   ------------
   -- Layout --
   ------------

   overriding procedure Layout (W : in out Switch_Widget) is
   begin
      Update_Switch_Items (W);
   end Layout;

end Adi.Widget.Button.Switch;
