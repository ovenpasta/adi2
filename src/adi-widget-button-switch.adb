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
      return Result;
   end Create;

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
      --  Sensible default size when width/height are auto.
      return (Width => 52.0, Height => 30.0);
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
