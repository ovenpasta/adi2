with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;         use Adi.CSS_Styles;
with Adi.Layout_Util;        use Adi.Layout_Util;
with Adi.Widget;             use Adi.Widget;

package body Adi.Widget.Context_Menu is

   ---------------------------------------------------------------------------
   --  Menu Handle Store operations (simple ones; Destroy is after bindings)
   ---------------------------------------------------------------------------

   function Is_Valid (H : Menu_Handle) return Boolean is
   begin
      return Menu_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function Resolve_Menu_Handle (H : Menu_Handle) return Context_Menu_Access is
   begin
      return Menu_Stores.Get (H.Id);
   end Resolve_Menu_Handle;

   function Get_Handle (M : Context_Menu) return Menu_Handle is
   begin
      return (Id => (Index => Menu_Stores.Slot_Index (M.Store_Index),
                     Gen   => Menu_Stores.Generation (M.Store_Gen)));
   end Get_Handle;

   procedure Pump_Menu_Store is
   begin
      Menu_Stores.Pump;
   end Pump_Menu_Store;

   procedure Register_Menu (Obj : not null Context_Menu_Access) is
      Id : constant Menu_Stores.Object_Id := Menu_Stores.Register (Obj);
   begin
      Obj.Store_Index := Natural (Id.Index);
      Obj.Store_Gen   := Natural (Id.Gen);
   end Register_Menu;

   ---------------------------------------------------------------------------

   Default_Row_Height : constant Pixel_Type := 24.0;

   --  Concrete subtype (Context_Menu is abstract for Handle_Store generic)
   type Context_Menu_Impl is new Context_Menu with null record;

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
      Popup       : Popup_Lists.List_Box_Widget_Access := null;
      Dismiss     : Dismiss_Layer_Widget_Access := null;
      Popup_WH    : Widget_Handle := Null_Handle;
      Dismiss_WH  : Widget_Handle := Null_Handle;
      Owner       : Context_Menu_Access := null;
   end record;

   package Menu_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Menu_Binding);

   Menu_Bindings : Menu_Binding_Vectors.Vector;

   function Popup_Handle
     (Popup : Popup_Lists.List_Box_Widget_Access)
      return Popup_Lists.List_Box_Handle
   is
   begin
      if Popup = null then
         return Popup_Lists.Null_List_Box_Handle;
      end if;
      return Popup_Lists.Try_As_List_Box (Get_Handle (Popup.all));
   end Popup_Handle;

   procedure Destroy (H : in out Menu_Handle) is
      Obj : constant Context_Menu_Access := Menu_Stores.Get (H.Id);
   begin
      if Obj = null then
         H.Id := Menu_Stores.Null_Id;
         return;
      end if;

      --  Hide (removes popup/dismiss overlays from window)
      if Obj.Open then
         Hide (Obj.all);
      end if;

      --  Destroy owned popup and dismiss widgets, then remove binding.
      --  Use stored Widget_Handles — raw access may be dangling if the
      --  overlay was already destroyed during window finalization.
      for I in reverse 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Owner = Obj then
            declare
               Binding : Menu_Binding := Menu_Bindings.Element (I);
            begin
               --  Destroy popup (registered List_Box widget)
               if Is_Valid (Binding.Popup_WH) then
                  Destroy (Binding.Popup_WH);
               end if;

               --  Destroy dismiss layer (registered widget)
               if Is_Valid (Binding.Dismiss_WH) then
                  Destroy (Binding.Dismiss_WH);
               end if;
            end;
            Menu_Bindings.Delete (I);
            exit;
         end if;
      end loop;

      Menu_Stores.Request_Destroy (H.Id);
      H.Id := Menu_Stores.Null_Id;
   end Destroy;

   Default_Menu_Styles : Part_Style_Holders.Holder;
   Default_Item_Styles : Part_Style_Holders.Holder;

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
      PH : constant Widget_Handle :=
        Get_Handle (Widget'Class (Popup.all));
      DH : constant Widget_Handle :=
        Get_Handle (Widget'Class (Dismiss.all));
   begin
      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Popup = Popup then
            Menu_Bindings.Replace_Element
              (I, (Popup      => Popup,
                   Dismiss    => Dismiss,
                   Popup_WH   => PH,
                   Dismiss_WH => DH,
                   Owner      => Owner));
            return;
         end if;
      end loop;

      Menu_Bindings.Append
        (Menu_Binding'(Popup      => Popup,
                       Dismiss    => Dismiss,
                       Popup_WH   => PH,
                       Dismiss_WH => DH,
                       Owner      => Owner));
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
      PH    : constant Popup_Lists.List_Box_Handle := Popup_Handle (Menu.Popup);
      Row_W : Pixel_Type := 0.0;
   begin
      if not Popup_Lists.Is_Valid (PH) then
         return 0.0;
      end if;

      for I in 1 .. Popup_Lists.Row_Count (PH) loop
         declare
            Row  : constant Widget_Handle := Popup_Lists.Get_Row_Handle (PH, I);
            Pref : Size_2D;
         begin
            if Is_Valid (Row) then
               declare
                  R : Widget_Ref := Borrow (Row);
               begin
                  Pref := Get_Preferred_Size (R.Ptr.all);
               end;
               Row_W := Pixel_Type'Max (Row_W, Pref.Width);
            end if;
         end;
      end loop;

      return Row_W;
   end Resolve_Content_Width;

   function Resolve_Content_Height (Menu : Context_Menu) return Pixel_Type is
      Total : Pixel_Type := 0.0;
      PH    : constant Popup_Lists.List_Box_Handle := Popup_Handle (Menu.Popup);
      Count : constant Natural :=
        (if Popup_Lists.Is_Valid (PH) then Popup_Lists.Row_Count (PH) else 0);
      Row_H : Pixel_Type;
   begin
      if not Popup_Lists.Is_Valid (PH) then
         return 0.0;
      end if;

      for I in 1 .. Count loop
         declare
            Row : constant Widget_Handle := Popup_Lists.Get_Row_Handle (PH, I);
            Pref : Size_2D;
         begin
            if not Is_Valid (Row) then
               Row_H := Default_Row_Height;
            else
               declare
                  R : Widget_Ref := Borrow (Row);
               begin
                  Pref := Get_Preferred_Size (R.Ptr.all);
               end;
               Row_H :=
                 (if Pref.Height > 0.0 then Pref.Height else Default_Row_Height);
            end if;
            Total := Total + Row_H;
         end;
      end loop;

      if Count > 1 then
         declare
            S : constant Resolved_Style :=
              Get_Resolved_Part_Style (Menu.Popup.all, Main_Part);
         begin
            Total :=
              Total + Pixel_Type (Count - 1) * Get_Row_Gap (S.Gap);
         end;
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
      Content_Outer : Size_2D;
      Wd, Ht  : Pixel_Type;
      X_Pos, Y_Pos : Pixel_Type;
   begin
      if Menu.Host_Window = null or else Menu.Popup = null then
         return;
      end if;

      Win_Size := Adi.Window.Get_Size (Menu.Host_Window.all);
      Popup_Style := Get_Resolved_Part_Style (Menu.Popup.all, Main_Part);
      Content_Outer := Outer_Size
        ((Resolve_Content_Width (Menu), Resolve_Content_Height (Menu)),
         Popup_Style);

      Wd := Pixel_Type'Max (Min_Width, Content_Outer.Width);
      Ht := Content_Outer.Height;

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
     (W      : Widget_Handle;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (Clicks);
      Owner : Context_Menu_Access := null;
      Label_Text : Unbounded_String := Null_Unbounded_String;
   begin
      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Popup_WH = W then
            Owner := Menu_Bindings.Element (I).Owner;
            exit;
         end if;
      end loop;

      if Owner = null then
         return;
      end if;

      if Index <= Natural (Owner.Disabled.Length)
        and then Owner.Disabled.Element (Index)
      then
         return;
      end if;

      if Index <= Natural (Owner.Items.Length) then
         Label_Text := Owner.Items.Element (Index);
      end if;

      Hide (Owner.all);
      declare
         Idx : constant Positive := Index;
         Txt : constant String := To_String (Label_Text);
         Owner_H : constant Menu_Handle := Get_Handle (Owner.all);
         procedure Call (CB : Item_Selected_Callback) is
         begin CB (Owner_H, Idx, Txt); end Call;
         procedure Emit is new Item_Selected_Signals.For_Each (Call);
      begin
         Emit (Owner.Item_Selected);
      end;
   end On_Popup_Item_Clicked;

   function Create return Context_Menu_Access is
      Result : constant Context_Menu_Access := new Context_Menu_Impl;
      Dismiss : constant Dismiss_Layer_Widget_Access := new Dismiss_Layer_Widget;
   begin
      Result.Popup := Popup_Lists.Create;
      Popup_Lists.Set_Selection_Mode
        (Result.Popup.all, Popup_Lists.Single_Selection);
      Set_Flag (Result.Popup.all, Focusable, False);
      Popup_Lists.Connect_Item_Clicked
        (Result.Popup.all, On_Popup_Item_Clicked'Access);

      Set_Flag (Dismiss.all, Visible, True);
      Set_Flag (Dismiss.all, Clickable, True);
      Set_Flag (Dismiss.all, Focusable, False);
      Register_Widget (Widget_Access (Dismiss));

      Register_Binding (Result.Popup, Dismiss, Result);

      if not Default_Menu_Styles.Is_Empty then
         Set_Part_Styles (Result.Popup.all, Default_Menu_Styles.Element);
      end if;

      Register_Menu (Result);
      return Result;
   end Create;

   function Create_Handle return Menu_Handle is
      M : constant Context_Menu_Access := Create;
   begin
      if M = null then
         return Null_Menu_Handle;
      end if;
      return Get_Handle (M.all);
   end Create_Handle;

   procedure Attach_Window
     (Menu : in out Context_Menu;
      Host : Adi.Window.Window_Access)
   is
   begin
      Menu.Host_Window := Host;
   end Attach_Window;

   procedure Attach_Window
     (Menu : in out Context_Menu;
      Host : Adi.Window.Window_Handle)
   is
   begin
      Attach_Window (Menu, Adi.Window.Resolve_Window_Handle (Host));
   end Attach_Window;

   procedure Add_Item
     (Menu : in out Context_Menu;
      Text : String)
   is
      Row : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create (Text);
   begin
      if not Menu.Row_Styles.Is_Empty then
         Set_Part_Styles (Row.all, Menu.Row_Styles.Element);
      elsif not Default_Item_Styles.Is_Empty then
         Set_Part_Styles (Row.all, Default_Item_Styles.Element);
      end if;

      Menu.Items.Append (To_Unbounded_String (Text));
      Menu.Disabled.Append (False);
      if Menu.Popup /= null then
         Popup_Lists.Append_Row
           (Popup_Handle (Menu.Popup),
            Get_Handle (Row.all));
      end if;
      Mark_Dirty (Menu.Popup.all);
   end Add_Item;

   procedure Clear_Items (Menu : in out Context_Menu) is
   begin
      Menu.Items.Clear;
      Menu.Disabled.Clear;
      if Menu.Popup /= null then
         Popup_Lists.Clear_Rows (Menu.Popup.all);
      end if;
   end Clear_Items;

   function Item_Count (Menu : Context_Menu) return Natural is
   begin
      return Natural (Menu.Items.Length);
   end Item_Count;

   procedure Set_Item_Disabled
     (Menu     : in out Context_Menu;
      Index    : Positive;
      Disabled : Boolean)
   is
   begin
      if Index > Natural (Menu.Disabled.Length) then
         return;
      end if;
      Menu.Disabled.Replace_Element (Index, Disabled);

      if Menu.Popup /= null
        and then Index <= Popup_Lists.Row_Count (Menu.Popup.all)
      then
         declare
            PH : constant Popup_Lists.List_Box_Handle := Popup_Handle (Menu.Popup);
            Row : constant Widget_Handle :=
              Popup_Lists.Get_Row_Handle (PH, Index);
         begin
            if Is_Valid (Row) then
               Set_Disabled (Row, Disabled);
            end if;
         end;
      end if;
   end Set_Item_Disabled;

   function Is_Item_Disabled
     (Menu  : Context_Menu;
      Index : Positive) return Boolean
   is
   begin
      if Index > Natural (Menu.Disabled.Length) then
         return False;
      end if;
      return Menu.Disabled.Element (Index);
   end Is_Item_Disabled;

   procedure Connect_Item_Selected
     (Menu : in out Context_Menu; CB : Item_Selected_Callback)
   is
   begin
      Menu.Item_Selected.Connect (CB);
   end Connect_Item_Selected;

   function Connect_Item_Selected
     (Menu : in out Context_Menu; CB : Item_Selected_Callback)
      return Item_Selected_Signals.Connection_Id
   is
   begin
      return Menu.Item_Selected.Connect (CB);
   end Connect_Item_Selected;

   procedure Disconnect_Item_Selected
     (Menu : in out Context_Menu;
      Id   : Item_Selected_Signals.Connection_Id)
   is
   begin
      Menu.Item_Selected.Disconnect (Id);
   end Disconnect_Item_Selected;

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
      Menu.Row_Styles := Part_Style_Holders.To_Holder (Styles);

      if Menu.Popup /= null then
         declare
            PH : constant Popup_Lists.List_Box_Handle := Popup_Handle (Menu.Popup);
         begin
            for I in 1 .. Popup_Lists.Row_Count (PH) loop
               declare
                  Row : constant Widget_Handle :=
                    Popup_Lists.Get_Row_Handle (PH, I);
               begin
                  if Is_Valid (Row) then
                     Set_Part_Styles (Row, Styles);
                  end if;
               end;
            end loop;
         end;
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

      Adi.Window.Add_Overlay (Menu.Host_Window.all, Get_Handle (Dismiss.all));
      Adi.Window.Add_Overlay (Menu.Host_Window.all, Get_Handle (Menu.Popup.all));
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

      Adi.Window.Remove_Overlay (Menu.Host_Window.all, Get_Handle (Menu.Popup.all));
      if Dismiss /= null then
         Adi.Window.Remove_Overlay (Menu.Host_Window.all, Get_Handle (Dismiss.all));
      end if;
      Menu.Open := False;
   end Hide;

   function Is_Shown (Menu : Context_Menu) return Boolean is
   begin
      return Menu.Open;
   end Is_Shown;

   procedure Set_Default_Menu_Styles (Styles : Adi.Widget.Part_Style_Array) is
   begin
      Default_Menu_Styles := Part_Style_Holders.To_Holder (Styles);
   end Set_Default_Menu_Styles;

   procedure Set_Default_Item_Styles (Styles : Adi.Widget.Part_Style_Array) is
   begin
      Default_Item_Styles := Part_Style_Holders.To_Holder (Styles);
   end Set_Default_Item_Styles;

   function Has_Default_Menu_Styles return Boolean is
   begin
      return not Default_Menu_Styles.Is_Empty;
   end Has_Default_Menu_Styles;

   function Has_Default_Item_Styles return Boolean is
   begin
      return not Default_Item_Styles.Is_Empty;
   end Has_Default_Item_Styles;

end Adi.Widget.Context_Menu;
