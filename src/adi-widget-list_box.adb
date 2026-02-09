with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.SDL.Events;  use Adi.SDL.Events;
with Ada.Numerics.Elementary_Functions;

package body Adi.Widget.List_Box is

   Default_Row_Height : constant Pixel_Type := 24.0;
   Wheel_Step_Px      : constant Pixel_Type := 36.0;
   Wheel_Impulse_Px_S : constant Pixel_Type := 820.0;
   Max_Scroll_Speed   : constant Pixel_Type := 2200.0;
   Velocity_Epsilon   : constant Pixel_Type := 10.0;
   Momentum_Friction  : constant Float := 7.0;
   Launch_Threshold   : constant Pixel_Type := 620.0;
   Drag_Velocity_Scale : constant Pixel_Type := 55.0;

   type Scrollbar_Metrics is record
      Width       : Pixel_Type := 10.0;
      Before_Gap  : Pixel_Type := 6.0;
      Inset_Top   : Pixel_Type := 2.0;
      Inset_Right : Pixel_Type := 2.0;
      Inset_Bot   : Pixel_Type := 2.0;
      Knob_Width  : Pixel_Type := 10.0;
      Min_Knob_H  : Pixel_Type := 24.0;
   end record;

   function Clamp (Value, Lo, Hi : Pixel_Type) return Pixel_Type is
   begin
      if Value < Lo then
         return Lo;
      elsif Value > Hi then
         return Hi;
      else
         return Value;
      end if;
   end Clamp;

   function Clamp (Value, Lo, Hi : Integer) return Integer is
   begin
      if Value < Lo then
         return Lo;
      elsif Value > Hi then
         return Hi;
      else
         return Value;
      end if;
   end Clamp;

   function Is_Mod_Active (Mods : SDL_Keymod; Mask : SDL_Keymod) return Boolean is
   begin
      return (Mods and Mask) /= 0;
   end Is_Mod_Active;

   procedure Fire_Selection_Changed (W : in out List_Box_Widget) is
      Self : constant List_Box_Widget_Access := W'Unchecked_Access;
   begin
      if W.On_Select /= null then
         W.On_Select (Self);
      end if;
   end Fire_Selection_Changed;

   procedure Sync_Row_Selection_State (W : in out List_Box_Widget) is
   begin
      for I in 1 .. Natural (W.Rows.Length) loop
         declare
            Row : constant Row_Widget_Access := W.Rows.Element (I);
         begin
            if Row /= null then
               Set_Selected (Row.all, W.Selected.Element (I));
            end if;
         end;
      end loop;
   end Sync_Row_Selection_State;

   function Main_Content_Box (W : List_Box_Widget) return Rectangle is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      return Content_Box (W.Geometry, Style);
   end Main_Content_Box;

   function Max_Scroll_Offset (W : List_Box_Widget) return Pixel_Type is
      Content : constant Rectangle := Main_Content_Box (W);
   begin
      return Pixel_Type'Max (0.0, W.Content_Height - Content.Height);
   end Max_Scroll_Offset;

   function Point_In_Rect (R : Rectangle; X, Y : Pixel_Type) return Boolean is
   begin
      return X >= R.X and then X <= R.X + R.Width
        and then Y >= R.Y and then Y <= R.Y + R.Height;
   end Point_In_Rect;

   procedure Compute_Scrollbar_Geometry
     (W        : List_Box_Widget;
      Metrics  : Scrollbar_Metrics;
      Visible  : out Boolean;
      Track    : out Rectangle;
      Knob     : out Rectangle)
   is
      Content    : constant Rectangle := Main_Content_Box (W);
      Max_Offset : constant Pixel_Type := Max_Scroll_Offset (W);
      Ratio      : Float;
      Knob_H     : Pixel_Type;
      Knob_Y     : Pixel_Type;
   begin
      Visible := W.Content_Height > Content.Height and then Content.Height > 0.0;
      Track := (0.0, 0.0, 0.0, 0.0);
      Knob := (0.0, 0.0, 0.0, 0.0);

      if not Visible then
         return;
      end if;

      Track :=
        (X      => Content.X + Content.Width - Metrics.Width - Metrics.Inset_Right,
         Y      => Content.Y + Metrics.Inset_Top,
         Width  => Metrics.Width,
         Height => Pixel_Type'Max
           (0.0, Content.Height - Metrics.Inset_Top - Metrics.Inset_Bot));

      Ratio := Float'Min (1.0, Float (Content.Height / W.Content_Height));
      Knob_H := Pixel_Type'Max (Metrics.Min_Knob_H, Track.Height * Pixel_Type (Ratio));

      if Max_Offset > 0.0 and then Track.Height > Knob_H then
         Knob_Y := Track.Y + (W.Scroll_Offset / Max_Offset) * (Track.Height - Knob_H);
      else
         Knob_Y := Track.Y;
      end if;

      Knob :=
        (X      => Track.X + (Track.Width - Pixel_Type'Min (Track.Width, Metrics.Knob_Width)) / 2.0,
         Y      => Knob_Y,
         Width  => Pixel_Type'Min (Track.Width, Metrics.Knob_Width),
         Height => Pixel_Type'Min (Track.Height, Knob_H));
   end Compute_Scrollbar_Geometry;

   function Resolve_Scrollbar_Metrics (W : List_Box_Widget) return Scrollbar_Metrics is
      Content : constant Rectangle := Main_Content_Box (W);
      Scroll_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Scroll_Part);
      Knob_Style   : constant Resolved_Style := Get_Resolved_Part_Style (W, Knob_Part);
      Scroll_Margin : constant Edge_Pixels := Get_Margin_Px (Scroll_Style);
      Scroll_Padding : constant Edge_Pixels := Get_Padding_Px (Scroll_Style);
      Result : Scrollbar_Metrics;
      W_Px : Pixel_Type;
      Knob_W_Px : Pixel_Type;
      Min_H_Px : Pixel_Type;
   begin
      W_Px := Size_To_Px (Scroll_Style.Width, Container_Size => Content.Width);
      if W_Px <= 0.0 then
         W_Px := Size_To_Px (Knob_Style.Width, Container_Size => Content.Width);
      end if;
      if W_Px > 0.0 then
         Result.Width := W_Px;
      end if;

      Result.Before_Gap :=
        Pixel_Type'Max (0.0, Scroll_Margin.Left + Scroll_Padding.Left);
      Result.Inset_Top :=
        Pixel_Type'Max (0.0, Scroll_Margin.Top + Scroll_Padding.Top);
      Result.Inset_Right :=
        Pixel_Type'Max (0.0, Scroll_Margin.Right + Scroll_Padding.Right);
      Result.Inset_Bot :=
        Pixel_Type'Max (0.0, Scroll_Margin.Bottom + Scroll_Padding.Bottom);

      Knob_W_Px := Size_To_Px (Knob_Style.Width, Container_Size => Result.Width);
      if Knob_W_Px > 0.0 then
         Result.Knob_Width := Knob_W_Px;
      else
         Result.Knob_Width := Result.Width;
      end if;

      Min_H_Px := Size_To_Px (Knob_Style.Min_Height, Container_Size => Content.Height);
      if Min_H_Px <= 0.0 then
         Min_H_Px := Size_To_Px (Knob_Style.Height, Container_Size => Content.Height);
      end if;
      if Min_H_Px > 0.0 then
         Result.Min_Knob_H := Min_H_Px;
      end if;

      return Result;
   end Resolve_Scrollbar_Metrics;

   procedure Clamp_Scroll (W : in out List_Box_Widget) is
   begin
      W.Scroll_Offset := Clamp (W.Scroll_Offset, 0.0, Max_Scroll_Offset (W));
   end Clamp_Scroll;

   function Row_Index_At_Y (W : List_Box_Widget; Y : Pixel_Type) return Natural is
      Content : constant Rectangle := Main_Content_Box (W);
      Cursor  : Pixel_Type := 0.0;
      Local_Y : Pixel_Type;
   begin
      if Y < Content.Y or else Y > Content.Y + Content.Height then
         return 0;
      end if;

      Local_Y := Y - Content.Y + W.Scroll_Offset;

      for I in 1 .. Natural (W.Rows.Length) loop
         declare
            H : constant Pixel_Type := W.Row_Heights.Element (I);
         begin
            if Local_Y >= Cursor and then Local_Y <= Cursor + H then
               return I;
            end if;
            Cursor := Cursor + H + W.Row_Gap;
         end;
      end loop;

      return 0;
   end Row_Index_At_Y;

   procedure Select_Only (W : in out List_Box_Widget; Index : Positive) is
      Changed : Boolean := False;
   begin
      for I in 1 .. Natural (W.Selected.Length) loop
         declare
            New_Value : constant Boolean := I = Index;
         begin
            if W.Selected.Element (I) /= New_Value then
               W.Selected.Replace_Element (I, New_Value);
               Changed := True;
            end if;
         end;
      end loop;

      if Changed then
         Sync_Row_Selection_State (W);
         Fire_Selection_Changed (W);
      end if;
   end Select_Only;

   procedure Select_Range
     (W          : in out List_Box_Widget;
      Start_Row  : Positive;
      End_Row    : Positive;
      Clear_First : Boolean := True)
   is
      Lo : constant Positive := Positive'Min (Start_Row, End_Row);
      Hi : constant Positive := Positive'Max (Start_Row, End_Row);
      Changed : Boolean := False;
   begin
      for I in 1 .. Natural (W.Selected.Length) loop
         declare
            In_Range : constant Boolean := I >= Lo and then I <= Hi;
            New_Value : constant Boolean :=
              (if Clear_First then In_Range else W.Selected.Element (I) or else In_Range);
         begin
            if W.Selected.Element (I) /= New_Value then
               W.Selected.Replace_Element (I, New_Value);
               Changed := True;
            end if;
         end;
      end loop;

      if Changed then
         Sync_Row_Selection_State (W);
         Fire_Selection_Changed (W);
      end if;
   end Select_Range;

   procedure Move_Current
     (W            : in out List_Box_Widget;
      Step         : Integer;
      Shift_Select : Boolean;
      Ctrl_Move    : Boolean)
   is
      Count : constant Natural := Natural (W.Rows.Length);
      Old_Current : Natural := W.Current_Row;
      Base : Integer;
      New_Row : Positive;
   begin
      if Count = 0 then
         return;
      end if;

      if Old_Current = 0 then
         Old_Current := 1;
      end if;

      Base := Clamp (Integer (Old_Current) + Step, 1, Integer (Count));
      New_Row := Positive (Base);
      W.Current_Row := Natural (New_Row);

      if W.Mode = No_Selection then
         Ensure_Row_Visible (W, New_Row);
         Mark_Dirty (W);
         return;
      end if;

      case W.Mode is
         when No_Selection =>
            null;

         when Single_Selection =>
            Select_Only (W, New_Row);
            W.Anchor_Row := Natural (New_Row);

         when Multi_Selection =>
            if Shift_Select then
               if W.Anchor_Row = 0 then
                  W.Anchor_Row := Old_Current;
               end if;
               Select_Range (W, Positive (W.Anchor_Row), New_Row);
            elsif Ctrl_Move then
               null;
            else
               Select_Only (W, New_Row);
               W.Anchor_Row := Natural (New_Row);
            end if;

         when Range_Selection =>
            if Shift_Select then
               if W.Anchor_Row = 0 then
                  W.Anchor_Row := Old_Current;
               end if;
               Select_Range
                 (W,
                  Start_Row   => Positive (W.Anchor_Row),
                  End_Row     => New_Row,
                  Clear_First => True);
            else
               Select_Only (W, New_Row);
               W.Anchor_Row := Natural (New_Row);
            end if;
      end case;

      Ensure_Row_Visible (W, New_Row);
      Mark_Dirty (W);
   end Move_Current;

   function Create return List_Box_Widget_Access is
      Result : constant List_Box_Widget_Access := new List_Box_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);
      Set_Flag (Result.all, Scrollable, True);
      return Result;
   end Create;

   procedure Append_Row (W : in out List_Box_Widget; Row : Row_Widget_Access) is
   begin
      if Row = null then
         return;
      end if;

      Add_Child (W, Widget_Access (Row));
      W.Rows.Append (Row);
      W.Selected.Append (False);
      W.Row_Heights.Append (Default_Row_Height);

      if W.Current_Row = 0 then
         W.Current_Row := 1;
         W.Anchor_Row := 1;
      end if;

      Mark_Dirty (W);
   end Append_Row;

   procedure Clear_Rows (W : in out List_Box_Widget) is
   begin
      for I in reverse 1 .. Natural (W.Rows.Length) loop
         declare
            Row : constant Row_Widget_Access := W.Rows.Element (I);
         begin
            if Row /= null then
               Remove_Child (W, Widget_Access (Row));
            end if;
         end;
      end loop;

      W.Rows.Clear;
      W.Selected.Clear;
      W.Row_Heights.Clear;
      W.Content_Height := 0.0;
      W.Scroll_Offset := 0.0;
      W.Current_Row := 0;
      W.Anchor_Row := 0;
      Mark_Dirty (W);
      Fire_Selection_Changed (W);
   end Clear_Rows;

   function Row_Count (W : List_Box_Widget) return Natural is
   begin
      return Natural (W.Rows.Length);
   end Row_Count;

   function Get_Row (W : List_Box_Widget; Index : Positive) return Row_Widget_Access is
   begin
      if Index <= Natural (W.Rows.Length) then
         return W.Rows.Element (Index);
      end if;
      return null;
   end Get_Row;

   procedure Set_Row_Gap (W : in out List_Box_Widget; Gap : Pixel_Type) is
   begin
      W.Row_Gap := Pixel_Type'Max (0.0, Gap);
      Mark_Dirty (W);
   end Set_Row_Gap;

   function Get_Row_Gap (W : List_Box_Widget) return Pixel_Type is
   begin
      return W.Row_Gap;
   end Get_Row_Gap;

   procedure Set_Scroll_Offset (W : in out List_Box_Widget; Offset : Pixel_Type) is
   begin
      W.Scroll_Offset := Offset;
      Clamp_Scroll (W);
      Mark_Dirty (W);
   end Set_Scroll_Offset;

   function Get_Scroll_Offset (W : List_Box_Widget) return Pixel_Type is
   begin
      return W.Scroll_Offset;
   end Get_Scroll_Offset;

   function Get_Content_Height (W : List_Box_Widget) return Pixel_Type is
   begin
      return W.Content_Height;
   end Get_Content_Height;

   procedure Scroll_By (W : in out List_Box_Widget; Delta_Y : Pixel_Type) is
   begin
      Set_Scroll_Offset (W, W.Scroll_Offset + Delta_Y);
   end Scroll_By;

   procedure Ensure_Row_Visible (W : in out List_Box_Widget; Index : Positive) is
      Content : constant Rectangle := Main_Content_Box (W);
      Cursor  : Pixel_Type := 0.0;
      H       : Pixel_Type;
      Row_Top : Pixel_Type;
      Row_Bot : Pixel_Type;
   begin
      if Index > Natural (W.Rows.Length) then
         return;
      end if;

      for I in 1 .. Index - 1 loop
         Cursor := Cursor + W.Row_Heights.Element (I) + W.Row_Gap;
      end loop;

      H := W.Row_Heights.Element (Index);
      Row_Top := Cursor;
      Row_Bot := Cursor + H;

      if Row_Top < W.Scroll_Offset then
         W.Scroll_Offset := Row_Top;
      elsif Row_Bot > W.Scroll_Offset + Content.Height then
         W.Scroll_Offset := Row_Bot - Content.Height;
      end if;

      Clamp_Scroll (W);
      Mark_Dirty (W);
   end Ensure_Row_Visible;

   procedure Set_Selection_Mode (W : in out List_Box_Widget; Mode : Selection_Mode) is
   begin
      if W.Mode = Mode then
         return;
      end if;

      W.Mode := Mode;
      if Mode = No_Selection then
         Clear_Selection (W);
      elsif
        (Mode = Single_Selection or else Mode = Range_Selection)
        and then W.Current_Row > 0
      then
         Select_Only (W, Positive (W.Current_Row));
      end if;
      Mark_Dirty (W);
   end Set_Selection_Mode;

   function Get_Selection_Mode (W : List_Box_Widget) return Selection_Mode is
   begin
      return W.Mode;
   end Get_Selection_Mode;

   procedure Clear_Selection (W : in out List_Box_Widget) is
      Changed : Boolean := False;
   begin
      for I in 1 .. Natural (W.Selected.Length) loop
         if W.Selected.Element (I) then
            W.Selected.Replace_Element (I, False);
            Changed := True;
         end if;
      end loop;

      if Changed then
         Sync_Row_Selection_State (W);
         Fire_Selection_Changed (W);
      end if;
   end Clear_Selection;

   procedure Select_Row (W : in out List_Box_Widget; Index : Positive) is
   begin
      if Index > Natural (W.Rows.Length) then
         return;
      end if;

      W.Current_Row := Natural (Index);
      W.Anchor_Row := Natural (Index);

      case W.Mode is
         when No_Selection =>
            null;
         when Single_Selection =>
            Select_Only (W, Index);
         when Multi_Selection =>
            if not W.Selected.Element (Index) then
               W.Selected.Replace_Element (Index, True);
               Sync_Row_Selection_State (W);
               Fire_Selection_Changed (W);
            end if;
         when Range_Selection =>
            Select_Only (W, Index);
      end case;

      Ensure_Row_Visible (W, Index);
      Mark_Dirty (W);
   end Select_Row;

   procedure Toggle_Row_Selected (W : in out List_Box_Widget; Index : Positive) is
   begin
      if W.Mode /= Multi_Selection or else Index > Natural (W.Rows.Length) then
         return;
      end if;

      W.Selected.Replace_Element (Index, not W.Selected.Element (Index));
      W.Current_Row := Natural (Index);
      W.Anchor_Row := Natural (Index);
      Sync_Row_Selection_State (W);
      Fire_Selection_Changed (W);
      Ensure_Row_Visible (W, Index);
      Mark_Dirty (W);
   end Toggle_Row_Selected;

   function Is_Row_Selected (W : List_Box_Widget; Index : Positive) return Boolean is
   begin
      if Index <= Natural (W.Selected.Length) then
         return W.Selected.Element (Index);
      end if;
      return False;
   end Is_Row_Selected;

   function Get_Selected_Count (W : List_Box_Widget) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (W.Selected.Length) loop
         if W.Selected.Element (I) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Get_Selected_Count;

   procedure Set_Current_Row (W : in out List_Box_Widget; Index : Positive) is
   begin
      if Index > Natural (W.Rows.Length) then
         return;
      end if;

      W.Current_Row := Natural (Index);
      Ensure_Row_Visible (W, Index);
      Mark_Dirty (W);
   end Set_Current_Row;

   function Get_Current_Row (W : List_Box_Widget) return Natural is
   begin
      return W.Current_Row;
   end Get_Current_Row;

   procedure Set_On_Item_Clicked
     (W  : in out List_Box_Widget;
      CB : Item_Clicked_Callback) is
   begin
      W.On_Item_Click := CB;
   end Set_On_Item_Clicked;

   procedure Set_On_Item_Activated
     (W  : in out List_Box_Widget;
      CB : Item_Activated_Callback) is
   begin
      W.On_Item_Act := CB;
   end Set_On_Item_Activated;

   procedure Set_On_Selection_Changed
     (W  : in out List_Box_Widget;
      CB : Selection_Changed_Callback) is
   begin
      W.On_Select := CB;
   end Set_On_Selection_Changed;

   overriding procedure Build_Items (W : in out List_Box_Widget) is
      Scroll_Geom : constant Rectangle := (0.0, 0.0, 0.0, 0.0);
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Add_Item (W, Make_Panel (Scroll_Part, Scroll_Geom, 1));
         Add_Item (W, Make_Panel (Knob_Part, Scroll_Geom, 2));
      end if;
      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
   end Build_Items;

   overriding procedure Layout (W : in out List_Box_Widget) is
      Content : constant Rectangle := Main_Content_Box (W);
      Height_Sum : Pixel_Type := 0.0;
      Row_H : Pixel_Type;
      Cursor_Y : Pixel_Type;
      Overflow : Boolean := False;
      Rows_Width : Pixel_Type := Content.Width;
      Track : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Knob  : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Show_Scroll : Boolean;
      Metrics : Scrollbar_Metrics;
   begin
      if Natural (W.Row_Heights.Length) /= Natural (W.Rows.Length) then
         W.Row_Heights.Clear;
         for I in 1 .. Natural (W.Rows.Length) loop
            W.Row_Heights.Append (Default_Row_Height);
         end loop;
      end if;

      --  First pass: measure rows and compute full content height.
      for I in 1 .. Natural (W.Rows.Length) loop
         declare
            Row : constant Row_Widget_Access := W.Rows.Element (I);
            Pref : Size_2D;
         begin
            if Row = null then
               Row_H := Default_Row_Height;
            else
               Pref := Get_Preferred_Size (Row.all);
               Row_H := (if Pref.Height > 0.0 then Pref.Height else Default_Row_Height);
            end if;

            W.Row_Heights.Replace_Element (I, Row_H);
            Height_Sum := Height_Sum + Row_H;
            if I < Natural (W.Rows.Length) then
               Height_Sum := Height_Sum + W.Row_Gap;
            end if;
         end;
      end loop;

      W.Content_Height := Height_Sum;
      Clamp_Scroll (W);
      Metrics := Resolve_Scrollbar_Metrics (W);

      Overflow := W.Content_Height > Content.Height;
      if Overflow then
         Rows_Width :=
           Pixel_Type'Max
             (0.0,
              Content.Width - (Metrics.Width + Metrics.Inset_Right + Metrics.Before_Gap));
      end if;

      --  Second pass: place rows using final viewport width.
      Cursor_Y := Content.Y - W.Scroll_Offset;
      for I in 1 .. Natural (W.Rows.Length) loop
         declare
            Row : constant Row_Widget_Access := W.Rows.Element (I);
         begin
            Row_H := W.Row_Heights.Element (I);
            if Row /= null then
               Set_Geometry
                 (Row.all,
                  (X      => Content.X,
                   Y      => Cursor_Y,
                   Width  => Rows_Width,
                   Height => Row_H));
               Layout (Row.all);
            end if;
            Cursor_Y := Cursor_Y + Row_H + W.Row_Gap;
         end;
      end loop;

      --  Scrollbar track + knob use dedicated parts.
      Compute_Scrollbar_Geometry (W, Metrics, Show_Scroll, Track, Knob);

      if Item_Count (W) >= 3 then
         W.Items.Reference (2).Geometry := Track;
         W.Items.Reference (3).Geometry := Knob;
      end if;
   end Layout;

   overriding procedure On_Mouse_Down
     (W      : in out List_Box_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      Self : constant List_Box_Widget_Access := W'Unchecked_Access;
      Index : Natural;
      Prev_Current : constant Natural := W.Current_Row;
      Mods  : constant SDL_Keymod := SDL_GetModState;
      Shift : constant Boolean := Is_Mod_Active (Mods, SDL_KMOD_SHIFT);
      Ctrl  : constant Boolean := Is_Mod_Active (Mods, SDL_KMOD_CTRL);
      Show_Scroll : Boolean;
      Track       : Rectangle;
      Knob        : Rectangle;
      Content     : constant Rectangle := Main_Content_Box (W);
      Metrics     : constant Scrollbar_Metrics := Resolve_Scrollbar_Metrics (W);
   begin
      if Button /= Left_Button then
         return;
      end if;

      W.Scroll_Dragging := False;
      Compute_Scrollbar_Geometry (W, Metrics, Show_Scroll, Track, Knob);

      if Show_Scroll and then Point_In_Rect (Track, X, Y) then
         if Point_In_Rect (Knob, X, Y) then
            W.Scroll_Dragging := True;
            W.Scroll_Drag_Offset := Y - Knob.Y;
            W.Last_Drag_Offset := W.Scroll_Offset;
            W.Scroll_Velocity := 0.0;
         elsif Y < Knob.Y then
            Scroll_By (W, -Content.Height * 0.9);
         else
            Scroll_By (W, Content.Height * 0.9);
         end if;
         Mark_Dirty (W);
         return;
      end if;

      Index := Row_Index_At_Y (W, Y);
      if Index = 0 then
         if W.Mode /= No_Selection then
            Clear_Selection (W);
         end if;
         return;
      end if;

      W.Current_Row := Index;

      case W.Mode is
         when No_Selection =>
            null;

         when Single_Selection =>
            Select_Only (W, Positive (Index));
            W.Anchor_Row := Index;

         when Multi_Selection =>
            if Shift then
               if W.Anchor_Row = 0 then
                  if Prev_Current > 0 then
                     W.Anchor_Row := Prev_Current;
                  else
                     W.Anchor_Row := Index;
                  end if;
               end if;

               Select_Range
                 (W,
                  Start_Row   => Positive (W.Anchor_Row),
                  End_Row     => Positive (Index),
                  Clear_First => not Ctrl);
            elsif Ctrl then
               Toggle_Row_Selected (W, Positive (Index));
            else
               Select_Only (W, Positive (Index));
               W.Anchor_Row := Index;
            end if;

         when Range_Selection =>
            if Shift then
               if W.Anchor_Row = 0 then
                  if Prev_Current > 0 then
                     W.Anchor_Row := Prev_Current;
                  else
                     W.Anchor_Row := Index;
                  end if;
               end if;

               Select_Range
                 (W,
                  Start_Row   => Positive (W.Anchor_Row),
                  End_Row     => Positive (Index),
                  Clear_First => True);
            else
               Select_Only (W, Positive (Index));
               W.Anchor_Row := Index;
            end if;
      end case;

      Ensure_Row_Visible (W, Positive (Index));

      if W.On_Item_Click /= null then
         W.On_Item_Click (Self, Positive (Index), Clicks);
      end if;
      if Clicks >= 2 and then W.On_Item_Act /= null then
         W.On_Item_Act (Self, Positive (Index));
      end if;

      Mark_Dirty (W);
   end On_Mouse_Down;

   overriding procedure On_Mouse_Wheel
     (W                : in out List_Box_Widget;
      Delta_X, Delta_Y : Pixel_Type)
   is
      pragma Unreferenced (Delta_X);
   begin
      if Delta_Y = 0.0 then
         return;
      end if;

      Set_Scroll_Offset (W, W.Scroll_Offset - (Delta_Y * Wheel_Step_Px));
      W.Scroll_Velocity :=
        Clamp (W.Scroll_Velocity - (Delta_Y * Wheel_Impulse_Px_S),
               -Max_Scroll_Speed,
               Max_Scroll_Speed);
   end On_Mouse_Wheel;

   overriding procedure On_Mouse_Move
     (W    : in out List_Box_Widget;
      X, Y : Pixel_Type)
   is
      pragma Unreferenced (X);
      Show_Scroll : Boolean;
      Track       : Rectangle;
      Knob        : Rectangle;
      Travel      : Pixel_Type;
      Top_Y       : Pixel_Type;
      Max_Offset  : Pixel_Type;
      Ratio       : Pixel_Type;
      Prev_Offset : Pixel_Type;
      Metrics     : constant Scrollbar_Metrics := Resolve_Scrollbar_Metrics (W);
   begin
      if not W.Scroll_Dragging then
         return;
      end if;

      Compute_Scrollbar_Geometry (W, Metrics, Show_Scroll, Track, Knob);
      if not Show_Scroll then
         W.Scroll_Dragging := False;
         return;
      end if;

      Travel := Pixel_Type'Max (0.0, Track.Height - Knob.Height);
      if Travel <= 0.0 then
         Set_Scroll_Offset (W, 0.0);
         return;
      end if;

      Top_Y := Clamp (Y - W.Scroll_Drag_Offset, Track.Y, Track.Y + Travel);
      Ratio := (Top_Y - Track.Y) / Travel;
      Max_Offset := Max_Scroll_Offset (W);
      Prev_Offset := W.Scroll_Offset;
      Set_Scroll_Offset (W, Ratio * Max_Offset);
      W.Scroll_Velocity :=
        Clamp ((W.Scroll_Offset - Prev_Offset) * Drag_Velocity_Scale,
               -Max_Scroll_Speed,
               Max_Scroll_Speed);
   end On_Mouse_Move;

   overriding procedure On_Mouse_Up
     (W      : in out List_Box_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button)
   is
      pragma Unreferenced (X, Y);
   begin
      if Button = Left_Button and then W.Scroll_Dragging then
         W.Scroll_Dragging := False;
         Mark_Dirty (W);
      end if;
   end On_Mouse_Up;

   overriding procedure On_Tick
     (W  : in out List_Box_Widget;
      DT : Duration)
   is
      use Ada.Numerics.Elementary_Functions;
      DT_Float : constant Float := Float (DT);
      Max_Offset : constant Pixel_Type := Max_Scroll_Offset (W);
      Old_Offset : Pixel_Type;
      Fast : Boolean;
   begin
      if not W.Scroll_Dragging and then abs W.Scroll_Velocity > Velocity_Epsilon then
         Old_Offset := W.Scroll_Offset;
         Set_Scroll_Offset (W, W.Scroll_Offset + W.Scroll_Velocity * Pixel_Type (DT_Float));

         --  Stop momentum when clamped against bounds.
         if (W.Scroll_Offset = 0.0 and then W.Scroll_Velocity < 0.0)
           or else (W.Scroll_Offset = Max_Offset and then W.Scroll_Velocity > 0.0)
         then
            W.Scroll_Velocity := 0.0;
         else
            W.Scroll_Velocity :=
              W.Scroll_Velocity * Pixel_Type (Exp (-Momentum_Friction * DT_Float));
         end if;

         if abs W.Scroll_Velocity < Velocity_Epsilon
           or else W.Scroll_Offset = Old_Offset
         then
            W.Scroll_Velocity := 0.0;
         end if;
      end if;

      Fast := W.Scroll_Dragging or else abs W.Scroll_Velocity >= Launch_Threshold;
      Set_Part_State (W, Scroll_Part, State_Pressed, Fast);
      Set_Part_State (W, Knob_Part, State_Pressed, Fast);
   end On_Tick;

   overriding procedure On_Key_Down
     (W        : in out List_Box_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean)
   is
      pragma Unreferenced (Repeat);
      Shift : constant Boolean := Is_Mod_Active (Key_Mod, SDL_KMOD_SHIFT);
      Ctrl  : constant Boolean := Is_Mod_Active (Key_Mod, SDL_KMOD_CTRL);
      Count : constant Natural := Natural (W.Rows.Length);
      Content : constant Rectangle := Main_Content_Box (W);
      Avg_Row_H : Pixel_Type :=
        (if Count > 0 then W.Content_Height / Pixel_Type (Count) else Default_Row_Height);
      Page_Rows : Integer :=
        Integer'Max (1, Integer (Float (Content.Height / Pixel_Type'Max (1.0, Avg_Row_H))));
   begin
      if Count = 0 then
         return;
      end if;

      case Scancode is
         when SDL_SCANCODE_UP =>
            Move_Current (W, -1, Shift, Ctrl);
         when SDL_SCANCODE_DOWN =>
            Move_Current (W, 1, Shift, Ctrl);
         when SDL_SCANCODE_PAGEUP =>
            Move_Current (W, -Page_Rows, Shift, Ctrl);
         when SDL_SCANCODE_PAGEDOWN =>
            Move_Current (W, Page_Rows, Shift, Ctrl);
         when SDL_SCANCODE_HOME =>
            Move_Current (W, -Integer (Count), Shift, Ctrl);
         when SDL_SCANCODE_END =>
            Move_Current (W, Integer (Count), Shift, Ctrl);
         when others =>
            null;
      end case;
   end On_Key_Down;

end Adi.Widget.List_Box;
