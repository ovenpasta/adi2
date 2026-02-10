with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.Events;        use Adi.SDL.Events;

package body Adi.Widget.Combo_Box is
   type Dismiss_Layer_Widget is new Widget with null record;
   type Dismiss_Layer_Widget_Access is access all Dismiss_Layer_Widget'Class;

   overriding procedure Build_Items (W : in out Dismiss_Layer_Widget);
   overriding procedure Layout (W : in out Dismiss_Layer_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Dismiss_Layer_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);

   use type Popup_Lists.List_Box_Widget_Access;
   use type Adi.Window.Window_Access;
   use type Adi.Widget.Label.Label_Widget_Access;

   type Popup_Binding is record
      Popup : Popup_Lists.List_Box_Widget_Access := null;
      Dismiss : Dismiss_Layer_Widget_Access := null;
      Owner : Combo_Box_Widget_Access := null;
   end record;

   package Popup_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Popup_Binding);

   Popup_Bindings : Popup_Binding_Vectors.Vector;
   Default_Popup_Max_Height : constant Pixel_Type := 240.0;
   Default_Popup_Row_Height : constant Pixel_Type := 24.0;

   function Find_Owner
     (Popup : Popup_Lists.List_Box_Widget_Access) return Combo_Box_Widget_Access
   is
   begin
      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Popup = Popup then
            return Popup_Bindings.Element (I).Owner;
         end if;
      end loop;
      return null;
   end Find_Owner;

   function Find_Owner
     (Dismiss : Dismiss_Layer_Widget_Access) return Combo_Box_Widget_Access
   is
   begin
      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Dismiss = Dismiss then
            return Popup_Bindings.Element (I).Owner;
         end if;
      end loop;
      return null;
   end Find_Owner;

   procedure Register_Binding
     (Popup : Popup_Lists.List_Box_Widget_Access;
      Dismiss : Dismiss_Layer_Widget_Access;
      Owner : Combo_Box_Widget_Access)
   is
   begin
      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Popup = Popup then
            Popup_Bindings.Replace_Element
              (I, (Popup => Popup, Dismiss => Dismiss, Owner => Owner));
            return;
         end if;
      end loop;
      Popup_Bindings.Append
        (New_Item =>
           Popup_Binding'(Popup => Popup, Dismiss => Dismiss, Owner => Owner));
   end Register_Binding;

   overriding procedure Build_Items (W : in out Dismiss_Layer_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Build_Items;

   overriding procedure Layout (W : in out Dismiss_Layer_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   overriding procedure On_Mouse_Down
     (W      : in out Dismiss_Layer_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (X, Y, Clicks);
      Owner : constant Combo_Box_Widget_Access := Find_Owner (W'Unchecked_Access);
   begin
      if Button /= Left_Button or else Owner = null then
         return;
      end if;
      Close_Dropdown (Owner.all);
   end On_Mouse_Down;

   procedure Fire_Changed (W : in out Combo_Box_Widget) is
      Self : constant Combo_Box_Widget_Access := W'Unchecked_Access;
   begin
      if W.On_Changed /= null then
         W.On_Changed (Self, W.Selected, Get_Selected_Text (W));
      end if;
   end Fire_Changed;

   procedure Sync_Popup_Row_Gap_From_Style (W : in out Combo_Box_Widget) is
      Popup_Style : Resolved_Style;
      Gap_Px      : Pixel_Type;
   begin
      if W.Popup = null then
         return;
      end if;

      Popup_Style := Get_Resolved_Part_Style (W.Popup.all, Main_Part);
      Gap_Px := Get_Row_Gap (Popup_Style.Gap);
      Popup_Lists.Set_Row_Gap (W.Popup.all, Gap_Px);
   end Sync_Popup_Row_Gap_From_Style;

   function Resolve_Popup_Row_Content_Height
     (W : Combo_Box_Widget) return Pixel_Type
   is
      Total : Pixel_Type := 0.0;
      Count : constant Natural := (if W.Popup = null then 0 else Popup_Lists.Row_Count (W.Popup.all));
      Row_H : Pixel_Type;
   begin
      if W.Popup = null then
         return 0.0;
      end if;

      for I in 1 .. Count loop
         declare
            Row  : constant Adi.Widget.Label.Label_Widget_Access :=
              Popup_Lists.Get_Row (W.Popup.all, I);
            Pref : Size_2D;
         begin
            if Row = null then
               Row_H := Default_Popup_Row_Height;
            else
               Pref := Get_Preferred_Size (Row.all);
               Row_H :=
                 (if Pref.Height > 0.0 then Pref.Height else Default_Popup_Row_Height);
            end if;
            Total := Total + Row_H;
         end;
      end loop;

      if Count > 1 then
         Total :=
           Total + Pixel_Type (Count - 1) * Popup_Lists.Get_Row_Gap (W.Popup.all);
      end if;
      return Total;
   end Resolve_Popup_Row_Content_Height;

   function Resolve_Popup_Max_Height
     (Style            : Resolved_Style;
      Container_Height : Pixel_Type) return Pixel_Type
   is
      Max_H : Pixel_Type;
   begin
      case Style.Max_Height.Kind is
         when Fixed =>
            Max_H := Size_To_Px (Style.Max_Height, Container_Height);
         when others =>
            Max_H := Default_Popup_Max_Height;
      end case;

      if Max_H <= 0.0 then
         Max_H := Container_Height;
      end if;
      return Pixel_Type'Min (Container_Height, Pixel_Type'Max (0.0, Max_H));
   end Resolve_Popup_Max_Height;

   function Resolve_Popup_Min_Height
     (Style            : Resolved_Style;
      Container_Height : Pixel_Type) return Pixel_Type
   is
      Min_H : Pixel_Type := 0.0;
   begin
      case Style.Min_Height.Kind is
         when Fixed =>
            Min_H := Size_To_Px (Style.Min_Height, Container_Height);
         when others =>
            null;
      end case;
      return Pixel_Type'Max (0.0, Min_H);
   end Resolve_Popup_Min_Height;

   function Resolve_Popup_Height
     (W        : Combo_Box_Widget;
      Win_Size : Size_2D) return Pixel_Type
   is
      Popup_Style : constant Resolved_Style := Get_Resolved_Part_Style (W.Popup.all, Main_Part);
      Padding     : constant Edge_Pixels := Get_Padding_Px (Popup_Style);
      Border      : constant Edge_Pixels := Get_Border_Width_Px (Popup_Style);
      Chrome_H    : constant Pixel_Type :=
        Padding.Top + Padding.Bottom + Border.Top + Border.Bottom;
      Content_H   : constant Pixel_Type := Resolve_Popup_Row_Content_Height (W);
      Max_H       : constant Pixel_Type := Resolve_Popup_Max_Height (Popup_Style, Win_Size.Height);
      Min_H       : constant Pixel_Type :=
        Pixel_Type'Min (Resolve_Popup_Min_Height (Popup_Style, Win_Size.Height), Max_H);
      Desired_H   : constant Pixel_Type := Content_H + Chrome_H;
   begin
      return Pixel_Type'Min (Max_H, Pixel_Type'Max (Min_H, Desired_H));
   end Resolve_Popup_Height;

   procedure Sync_Selected_From_Popup (W : in out Combo_Box_Widget) is
      Current : Natural;
   begin
      if W.Popup = null then
         return;
      end if;

      Current := Popup_Lists.Get_Current_Row (W.Popup.all);
      if Current > Natural (W.Options.Length) then
         Current := 0;
      end if;

      if W.Selected /= Current then
         W.Selected := Current;
         Fire_Changed (W);
      end if;
      Mark_Dirty (W);
   end Sync_Selected_From_Popup;

   procedure On_Popup_Item_Clicked
     (Lbx    : Popup_Lists.List_Box_Widget_Access;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (Clicks);
      Owner : constant Combo_Box_Widget_Access := Find_Owner (Lbx);
   begin
      if Owner = null then
         return;
      end if;

      Set_Selected_Index (Owner.all, Natural (Index));
      Close_Dropdown (Owner.all);
   end On_Popup_Item_Clicked;

   function Create return Combo_Box_Widget_Access is
      Result : constant Combo_Box_Widget_Access := new Combo_Box_Widget;
      Dismiss : constant Dismiss_Layer_Widget_Access := new Dismiss_Layer_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);

      Result.Popup := Popup_Lists.Create;
      Popup_Lists.Set_Selection_Mode
        (Result.Popup.all, Popup_Lists.Single_Selection);
      Set_Flag (Result.Popup.all, Focusable, False);
      Popup_Lists.Set_On_Item_Clicked
        (Result.Popup.all, On_Popup_Item_Clicked'Access);
      Set_Flag (Dismiss.all, Visible, True);
      Set_Flag (Dismiss.all, Clickable, True);
      Set_Flag (Dismiss.all, Focusable, False);
      Register_Binding (Result.Popup, Dismiss, Result);

      return Result;
   end Create;

   procedure Attach_Window
     (W    : in out Combo_Box_Widget;
      Host : Adi.Window.Window_Access)
   is
   begin
      W.Host_Window := Host;
   end Attach_Window;

   procedure Add_Item (W : in out Combo_Box_Widget; Text : String) is
      Row : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create (Text);
   begin
      if W.Has_Option_Row_Styles then
         Set_Part_Styles (Row.all, W.Option_Row_Styles);
      end if;

      W.Options.Append (To_Unbounded_String (Text));
      if W.Popup /= null then
         Popup_Lists.Append_Row (W.Popup.all, Row);
      end if;

      if W.Selected = 0 then
         W.Selected := 1;
         if W.Popup /= null then
            Popup_Lists.Select_Row (W.Popup.all, 1);
         end if;
      end if;
      Mark_Dirty (W);
   end Add_Item;

   procedure Clear_Items (W : in out Combo_Box_Widget) is
   begin
      W.Options.Clear;
      W.Selected := 0;
      if W.Popup /= null then
         Popup_Lists.Clear_Rows (W.Popup.all);
      end if;
      Mark_Dirty (W);
   end Clear_Items;

   function Option_Count (W : Combo_Box_Widget) return Natural is
   begin
      return Natural (W.Options.Length);
   end Option_Count;

   procedure Set_Selected_Index (W : in out Combo_Box_Widget; Index : Natural) is
      New_Index : Natural := Index;
   begin
      if New_Index > Natural (W.Options.Length) then
         New_Index := 0;
      end if;

      if W.Selected = New_Index then
         return;
      end if;

      W.Selected := New_Index;
      if W.Popup /= null then
         if New_Index = 0 then
            Popup_Lists.Clear_Selection (W.Popup.all);
         else
            Popup_Lists.Select_Row (W.Popup.all, Positive (New_Index));
         end if;
      end if;

      Mark_Dirty (W);
      Fire_Changed (W);
   end Set_Selected_Index;

   function Get_Selected_Index (W : Combo_Box_Widget) return Natural is
   begin
      return W.Selected;
   end Get_Selected_Index;

   function Get_Selected_Text (W : Combo_Box_Widget) return String is
   begin
      if W.Selected = 0 or else W.Selected > Natural (W.Options.Length) then
         return "";
      end if;
      return To_String (W.Options.Element (Positive (W.Selected)));
   end Get_Selected_Text;

   procedure Set_On_Selection_Changed
     (W  : in out Combo_Box_Widget;
      CB : Selection_Changed_Callback)
   is
   begin
      W.On_Changed := CB;
   end Set_On_Selection_Changed;

   procedure Set_Dropdown_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array)
   is
   begin
      if W.Popup /= null then
         Set_Part_Styles (W.Popup.all, Styles);
         Sync_Popup_Row_Gap_From_Style (W);
      end if;
   end Set_Dropdown_Part_Styles;

   procedure Set_Option_Row_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array)
   is
   begin
      W.Option_Row_Styles := Styles;
      W.Has_Option_Row_Styles := True;

      if W.Popup /= null then
         for I in 1 .. Popup_Lists.Row_Count (W.Popup.all) loop
            declare
               Row : constant Adi.Widget.Label.Label_Widget_Access :=
                 Popup_Lists.Get_Row (W.Popup.all, I);
            begin
               if Row /= null then
                  Set_Part_Styles (Row.all, W.Option_Row_Styles);
               end if;
            end;
         end loop;
      end if;
   end Set_Option_Row_Part_Styles;

   procedure Position_Popup (W : in out Combo_Box_Widget) is
      Anchor   : Rectangle;
      Win_Size : Size_2D;
      Popup_H  : Pixel_Type;
      X_Pos    : Pixel_Type;
      Y_Pos    : Pixel_Type;
   begin
      if W.Host_Window = null or else W.Popup = null then
         return;
      end if;

      Anchor := Get_Geometry (W);
      Win_Size := Adi.Window.Get_Size (W.Host_Window.all);
      Sync_Popup_Row_Gap_From_Style (W);
      Popup_H := Resolve_Popup_Height (W, Win_Size);

      X_Pos := Anchor.X;
      if X_Pos + Anchor.Width > Win_Size.Width then
         X_Pos := Pixel_Type'Max (0.0, Win_Size.Width - Anchor.Width);
      end if;

      Y_Pos := Anchor.Y + Anchor.Height;
      if Y_Pos + Popup_H > Win_Size.Height and then Anchor.Y - Popup_H >= 0.0 then
         Y_Pos := Anchor.Y - Popup_H;
      elsif Y_Pos + Popup_H > Win_Size.Height then
         Y_Pos := Pixel_Type'Max (0.0, Win_Size.Height - Popup_H);
      end if;

      Set_Geometry
        (W.Popup.all,
         (X => X_Pos, Y => Y_Pos, Width => Anchor.Width, Height => Popup_H));
      Layout (Widget'Class (W.Popup.all));
   end Position_Popup;

   procedure Position_Dismiss_Layer (W : in out Combo_Box_Widget) is
      Win_Size : Size_2D;
      Dismiss  : Dismiss_Layer_Widget_Access := null;
   begin
      if W.Host_Window = null then
         return;
      end if;

      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Owner = W'Unchecked_Access then
            Dismiss := Popup_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      if Dismiss = null then
         return;
      end if;

      Win_Size := Adi.Window.Get_Size (W.Host_Window.all);
      Set_Geometry
        (Dismiss.all,
         (X => 0.0, Y => 0.0, Width => Win_Size.Width, Height => Win_Size.Height));
   end Position_Dismiss_Layer;

   procedure Open_Dropdown (W : in out Combo_Box_Widget) is
      Dismiss : Dismiss_Layer_Widget_Access := null;
   begin
      if W.Open or else W.Host_Window = null or else W.Popup = null then
         return;
      end if;

      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Owner = W'Unchecked_Access then
            Dismiss := Popup_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      Position_Dismiss_Layer (W);
      Position_Popup (W);

      if W.Selected > 0 then
         Popup_Lists.Select_Row (W.Popup.all, Positive (W.Selected));
         Popup_Lists.Ensure_Row_Visible (W.Popup.all, Positive (W.Selected));
      end if;

      if Dismiss /= null then
         Adi.Window.Add_Overlay (W.Host_Window.all, Widget_Access (Dismiss));
      end if;
      Adi.Window.Add_Overlay (W.Host_Window.all, Widget_Access (W.Popup));
      W.Open := True;
      if Dismiss /= null then
         Mark_Dirty (Dismiss.all);
      end if;
      Mark_Dirty (W.Popup.all);
      Mark_Dirty (W);
   end Open_Dropdown;

   procedure Close_Dropdown (W : in out Combo_Box_Widget) is
      Dismiss : Dismiss_Layer_Widget_Access := null;
   begin
      if not W.Open or else W.Host_Window = null or else W.Popup = null then
         return;
      end if;

      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Owner = W'Unchecked_Access then
            Dismiss := Popup_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      Adi.Window.Remove_Overlay (W.Host_Window.all, Widget_Access (W.Popup));
      if Dismiss /= null then
         Adi.Window.Remove_Overlay (W.Host_Window.all, Widget_Access (Dismiss));
      end if;
      W.Open := False;
      Mark_Dirty (W);
   end Close_Dropdown;

   procedure Toggle_Dropdown (W : in out Combo_Box_Widget) is
   begin
      if W.Open then
         Close_Dropdown (W);
      else
         Open_Dropdown (W);
      end if;
   end Toggle_Dropdown;

   function Is_Open (W : Combo_Box_Widget) return Boolean is
   begin
      return W.Open;
   end Is_Open;

   overriding procedure Build_Items (W : in out Combo_Box_Widget) is
   begin
      if Item_Count (W) = 0 then
         Adi.Widget.Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Adi.Widget.Add_Item (W, Make_Text (Label_Part, W.Geometry, "", 1));
         Adi.Widget.Add_Item (W, Make_Text (Indicator_Part, W.Geometry, "v", 2));
      end if;

      declare
         Panel_It : Item renames W.Items.Reference (Panel_Idx).Element.all;
         Label_It : Item renames W.Items.Reference (Label_Idx).Element.all;
         Ind_It   : Item renames W.Items.Reference (Indicator_Idx).Element.all;
      begin
         Panel_It.Geometry := W.Geometry;
         Label_It.Text_Content := To_Unbounded_String (Get_Selected_Text (W));
         Ind_It.Text_Content := To_Unbounded_String ((if W.Open then "^" else "v"));
      end;
   end Build_Items;

   overriding procedure Layout (W : in out Combo_Box_Widget) is
      Main_Style   : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content      : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Indicator_W  : constant Pixel_Type := Pixel_Type'Min (24.0, Content.Width / 3.0);
   begin
      if Item_Count (W) < 3 then
         return;
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
      W.Items.Reference (Label_Idx).Geometry :=
        (X      => Content.X + 6.0,
         Y      => Content.Y,
         Width  => Pixel_Type'Max (0.0, Content.Width - Indicator_W - 6.0),
         Height => Content.Height);
      W.Items.Reference (Indicator_Idx).Geometry :=
        (X      => Content.X + Content.Width - Indicator_W,
         Y      => Content.Y,
         Width  => Indicator_W,
         Height => Content.Height);

      if W.Open and then W.Host_Window /= null and then W.Popup /= null then
         Position_Dismiss_Layer (W);
         Position_Popup (W);
         Mark_Dirty (W.Popup.all);
      end if;
   end Layout;

   overriding procedure On_Mouse_Down
     (W      : in out Combo_Box_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (X, Y, Clicks);
   begin
      if Button = Left_Button then
         Toggle_Dropdown (W);
      end if;
   end On_Mouse_Down;

   overriding procedure On_Key_Down
     (W        : in out Combo_Box_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean)
   is
   begin
      case Scancode is
         when SDL_SCANCODE_DOWN | SDL_SCANCODE_UP =>
            if not W.Open then
               Open_Dropdown (W);
            elsif W.Popup /= null then
               On_Key_Down
                 (Widget'Class (W.Popup.all), Scancode, Key_Mod, Repeat);
               Sync_Selected_From_Popup (W);
            end if;
         when SDL_SCANCODE_RETURN =>
            Toggle_Dropdown (W);
         when SDL_SCANCODE_ESCAPE =>
            Close_Dropdown (W);
         when others =>
            null;
      end case;
   end On_Key_Down;

   overriding procedure On_Focus_Lost (W : in out Combo_Box_Widget) is
   begin
      null;
   end On_Focus_Lost;

end Adi.Widget.Combo_Box;
