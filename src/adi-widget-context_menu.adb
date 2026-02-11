with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;         use Adi.CSS_Styles;
with Adi.Layout_Util;        use Adi.Layout_Util;
with Adi.Widget;             use Adi.Widget;

package body Adi.Widget.Context_Menu is

   Default_Row_Height : constant Pixel_Type := 24.0;

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

   type Menu_Binding is record
      Popup   : Popup_Lists.List_Box_Widget_Access := null;
      Dismiss : Dismiss_Layer_Widget_Access := null;
      Owner   : Context_Menu_Access := null;
   end record;

   package Menu_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Menu_Binding);

   Menu_Bindings : Menu_Binding_Vectors.Vector;

   function Find_Owner
     (Popup : Popup_Lists.List_Box_Widget_Access) return Context_Menu_Access
   is
   begin
      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Popup = Popup then
            return Menu_Bindings.Element (I).Owner;
         end if;
      end loop;
      return null;
   end Find_Owner;

   function Find_Owner
     (Dismiss : Dismiss_Layer_Widget_Access) return Context_Menu_Access
   is
   begin
      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Dismiss = Dismiss then
            return Menu_Bindings.Element (I).Owner;
         end if;
      end loop;
      return null;
   end Find_Owner;

   procedure Register_Binding
     (Popup   : Popup_Lists.List_Box_Widget_Access;
      Dismiss : Dismiss_Layer_Widget_Access;
      Owner   : Context_Menu_Access)
   is
   begin
      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Popup = Popup then
            Menu_Bindings.Replace_Element
              (I, (Popup => Popup, Dismiss => Dismiss, Owner => Owner));
            return;
         end if;
      end loop;

      Menu_Bindings.Append
        (Menu_Binding'(Popup => Popup, Dismiss => Dismiss, Owner => Owner));
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
      Owner : constant Context_Menu_Access := Find_Owner (W'Unchecked_Access);
   begin
      if Button /= Left_Button or else Owner = null then
         return;
      end if;
      Hide (Owner.all);
   end On_Mouse_Down;

   function Resolve_Content_Width (Menu : Context_Menu) return Pixel_Type is
      Row_W : Pixel_Type := 0.0;
   begin
      if Menu.Popup = null then
         return 0.0;
      end if;

      for I in 1 .. Popup_Lists.Row_Count (Menu.Popup.all) loop
         declare
            Row : constant Adi.Widget.Label.Label_Widget_Access :=
              Popup_Lists.Get_Row (Menu.Popup.all, I);
            Pref : Size_2D;
         begin
            if Row /= null then
               Pref := Get_Preferred_Size (Row.all);
               Row_W := Pixel_Type'Max (Row_W, Pref.Width);
            end if;
         end;
      end loop;

      return Row_W;
   end Resolve_Content_Width;

   function Resolve_Content_Height (Menu : Context_Menu) return Pixel_Type is
      Total : Pixel_Type := 0.0;
      Count : constant Natural :=
        (if Menu.Popup = null then 0 else Popup_Lists.Row_Count (Menu.Popup.all));
      Row_H : Pixel_Type;
   begin
      if Menu.Popup = null then
         return 0.0;
      end if;

      for I in 1 .. Count loop
         declare
            Row : constant Adi.Widget.Label.Label_Widget_Access :=
              Popup_Lists.Get_Row (Menu.Popup.all, I);
            Pref : Size_2D;
         begin
            if Row = null then
               Row_H := Default_Row_Height;
            else
               Pref := Get_Preferred_Size (Row.all);
               Row_H :=
                 (if Pref.Height > 0.0 then Pref.Height else Default_Row_Height);
            end if;
            Total := Total + Row_H;
         end;
      end loop;

      if Count > 1 then
         Total :=
           Total + Pixel_Type (Count - 1) * Popup_Lists.Get_Row_Gap (Menu.Popup.all);
      end if;

      return Total;
   end Resolve_Content_Height;

   procedure Position_Dismiss_Layer (Menu : in out Context_Menu) is
      Dismiss : Dismiss_Layer_Widget_Access := null;
      Win_Size : Size_2D;
   begin
      if Menu.Host_Window = null then
         return;
      end if;

      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Owner = Menu'Unchecked_Access then
            Dismiss := Menu_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      if Dismiss = null then
         return;
      end if;

      Win_Size := Adi.Window.Get_Size (Menu.Host_Window.all);
      Set_Geometry
        (Dismiss.all,
         (X => 0.0, Y => 0.0, Width => Win_Size.Width, Height => Win_Size.Height));
   end Position_Dismiss_Layer;

   procedure Position_Popup
     (Menu      : in out Context_Menu;
      X, Y      : Pixel_Type;
      Min_Width : Pixel_Type)
   is
      Win_Size : Size_2D;
      Popup_Style : Resolved_Style;
      Padding : Edge_Pixels;
      Border  : Edge_Pixels;
      Chrome_W : Pixel_Type;
      Chrome_H : Pixel_Type;
      Wd, Ht  : Pixel_Type;
      X_Pos, Y_Pos : Pixel_Type;
   begin
      if Menu.Host_Window = null or else Menu.Popup = null then
         return;
      end if;

      Win_Size := Adi.Window.Get_Size (Menu.Host_Window.all);
      Popup_Style := Get_Resolved_Part_Style (Menu.Popup.all, Main_Part);
      Padding := Get_Padding_Px (Popup_Style);
      Border := Get_Border_Width_Px (Popup_Style);
      Chrome_W := Padding.Left + Padding.Right + Border.Left + Border.Right;
      Chrome_H := Padding.Top + Padding.Bottom + Border.Top + Border.Bottom;

      Wd := Pixel_Type'Max (Min_Width, Resolve_Content_Width (Menu) + Chrome_W);
      Ht := Resolve_Content_Height (Menu) + Chrome_H;

      Wd := Pixel_Type'Min (Wd, Win_Size.Width);
      Ht := Pixel_Type'Min (Ht, Win_Size.Height);

      X_Pos := X;
      Y_Pos := Y;

      if X_Pos + Wd > Win_Size.Width then
         X_Pos := Pixel_Type'Max (0.0, Win_Size.Width - Wd);
      end if;

      if Y_Pos + Ht > Win_Size.Height then
         Y_Pos := Pixel_Type'Max (0.0, Win_Size.Height - Ht);
      end if;

      Set_Geometry
        (Menu.Popup.all,
         (X => X_Pos, Y => Y_Pos, Width => Wd, Height => Ht));
      Layout (Widget'Class (Menu.Popup.all));
   end Position_Popup;

   procedure On_Popup_Item_Clicked
     (W      : Popup_Lists.List_Box_Widget_Access;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (Clicks);
      Owner : constant Context_Menu_Access := Find_Owner (W);
      Label_Text : Unbounded_String := Null_Unbounded_String;
   begin
      if Owner = null then
         return;
      end if;

      if Index <= Natural (Owner.Items.Length) then
         Label_Text := Owner.Items.Element (Index);
      end if;

      Hide (Owner.all);
      if Owner.On_Selected /= null then
         Owner.On_Selected (Owner, Index, To_String (Label_Text));
      end if;
   end On_Popup_Item_Clicked;

   function Create return Context_Menu_Access is
      Result : constant Context_Menu_Access := new Context_Menu;
      Dismiss : constant Dismiss_Layer_Widget_Access := new Dismiss_Layer_Widget;
   begin
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
     (Menu : in out Context_Menu;
      Host : Adi.Window.Window_Access)
   is
   begin
      Menu.Host_Window := Host;
   end Attach_Window;

   procedure Add_Item
     (Menu : in out Context_Menu;
      Text : String)
   is
      Row : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create (Text);
   begin
      if Menu.Has_Row_Styles then
         Set_Part_Styles (Row.all, Menu.Row_Styles);
      end if;

      Menu.Items.Append (To_Unbounded_String (Text));
      if Menu.Popup /= null then
         Popup_Lists.Append_Row (Menu.Popup.all, Row);
      end if;
      Mark_Dirty (Menu.Popup.all);
   end Add_Item;

   procedure Clear_Items (Menu : in out Context_Menu) is
   begin
      Menu.Items.Clear;
      if Menu.Popup /= null then
         Popup_Lists.Clear_Rows (Menu.Popup.all);
      end if;
   end Clear_Items;

   function Item_Count (Menu : Context_Menu) return Natural is
   begin
      return Natural (Menu.Items.Length);
   end Item_Count;

   procedure Set_On_Item_Selected
     (Menu : in out Context_Menu;
      CB   : Item_Selected_Callback)
   is
   begin
      Menu.On_Selected := CB;
   end Set_On_Item_Selected;

   procedure Set_Menu_Part_Styles
     (Menu   : in out Context_Menu;
      Styles : Adi.Widget.Part_Style_Array)
   is
   begin
      if Menu.Popup /= null then
         Set_Part_Styles (Menu.Popup.all, Styles);
      end if;
   end Set_Menu_Part_Styles;

   procedure Set_Item_Part_Styles
     (Menu   : in out Context_Menu;
      Styles : Adi.Widget.Part_Style_Array)
   is
   begin
      Menu.Row_Styles := Styles;
      Menu.Has_Row_Styles := True;

      if Menu.Popup /= null then
         for I in 1 .. Popup_Lists.Row_Count (Menu.Popup.all) loop
            declare
               Row : constant Adi.Widget.Label.Label_Widget_Access :=
                 Popup_Lists.Get_Row (Menu.Popup.all, I);
            begin
               if Row /= null then
                  Set_Part_Styles (Row.all, Styles);
               end if;
            end;
         end loop;
      end if;
   end Set_Item_Part_Styles;

   procedure Show_At
     (Menu      : in out Context_Menu;
      X, Y      : Pixel_Type;
      Min_Width : Pixel_Type := 140.0)
   is
      Dismiss : Dismiss_Layer_Widget_Access := null;
   begin
      if Menu.Open
        or else Menu.Host_Window = null
        or else Menu.Popup = null
      then
         return;
      end if;

      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Owner = Menu'Unchecked_Access then
            Dismiss := Menu_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      if Dismiss = null then
         return;
      end if;

      Position_Dismiss_Layer (Menu);
      Position_Popup (Menu, X, Y, Min_Width);

      Adi.Window.Add_Overlay (Menu.Host_Window.all, Widget_Access (Dismiss));
      Adi.Window.Add_Overlay (Menu.Host_Window.all, Widget_Access (Menu.Popup));
      Menu.Open := True;
      Mark_Dirty (Dismiss.all);
      Mark_Dirty (Menu.Popup.all);
   end Show_At;

   procedure Hide (Menu : in out Context_Menu) is
      Dismiss : Dismiss_Layer_Widget_Access := null;
   begin
      if not Menu.Open or else Menu.Host_Window = null or else Menu.Popup = null then
         return;
      end if;

      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Owner = Menu'Unchecked_Access then
            Dismiss := Menu_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      Adi.Window.Remove_Overlay (Menu.Host_Window.all, Widget_Access (Menu.Popup));
      if Dismiss /= null then
         Adi.Window.Remove_Overlay (Menu.Host_Window.all, Widget_Access (Dismiss));
      end if;
      Menu.Open := False;
   end Hide;

   function Is_Shown (Menu : Context_Menu) return Boolean is
   begin
      return Menu.Open;
   end Is_Shown;

end Adi.Widget.Context_Menu;
