--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Indefinite_Holders;
with Ada.Finalization;
with Ada.Strings.Unbounded;                use Ada.Strings.Unbounded;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Font;
with Adi.Image;             use Adi.Image;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.Events;        use Adi.SDL.Events;

package body Adi.Widget.Combo_Box is
   package Part_Style_Holders is new Ada.Containers.Indefinite_Holders
     (Part_Style_Array);

   Default_Dropdown_Styles : Part_Style_Holders.Holder;
   Default_Option_Row_Styles : Part_Style_Holders.Holder;

   type Dismiss_Layer_Widget is new Widget with null record;
   type Dismiss_Layer_Widget_Access is access all Dismiss_Layer_Widget'Class;

   overriding procedure Build_Items (W : in out Dismiss_Layer_Widget);
   overriding procedure Layout (W : in out Dismiss_Layer_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Dismiss_Layer_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);

   use type Popup_Lists.List_Box_Handle;
   use type Adi.Window.Window_Access;

   type Popup_Binding is record
      Popup_H    : Popup_Lists.List_Box_Handle := Popup_Lists.Null_List_Box_Handle;
      Dismiss    : Dismiss_Layer_Widget_Access := null;
      Popup_WH   : Widget_Handle := Null_Handle;
      Dismiss_WH : Widget_Handle := Null_Handle;
      Owner      : Combo_Box_Widget_Access := null;
   end record;

   package Popup_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Popup_Binding);

   Popup_Bindings : Popup_Binding_Vectors.Vector;

   --  Holds this package's subscription to Adi.Widget.Scroll_Changed;
   --  the object itself is declared at the end of the body.
   type Scroll_Subscription is new Ada.Finalization.Limited_Controlled with
      record
         Id : Adi.Widget.Scroll_Signals.Connection_Id :=
            Adi.Widget.Scroll_Signals.No_Connection;
      end record;

   overriding procedure Finalize (S : in out Scroll_Subscription);

   Default_Popup_Max_Height : constant Pixel_Type := 240.0;
   Default_Popup_Row_Height : constant Pixel_Type := 24.0;

   Arrow_Down_Path : constant String := "M4 8 L12 16 L20 8";
   Arrow_Up_Path   : constant String := "M4 16 L12 8 L20 16";
   Arrow_SVG_Size  : constant Size_2D := (24.0, 24.0);
   Arrow_White : constant Color_8 := (R => 255, G => 255, B => 255, A => 255);
   Arrow_Clear : constant Color_8 := (R => 0, G => 0, B => 0, A => 0);

   Default_Arrow_Down : Image_Handle := Adi.Image.Null_Image_Handle;
   Default_Arrow_Up   : Image_Handle := Adi.Image.Null_Image_Handle;

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
     (Popup_H : Popup_Lists.List_Box_Handle;
      Dismiss : Dismiss_Layer_Widget_Access;
      Owner   : Combo_Box_Widget_Access)
   is
      PH : constant Widget_Handle := +Popup_H;
      DH : constant Widget_Handle :=
        Get_Handle (Widget'Class (Dismiss.all));
   begin
      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Popup_H = Popup_H then
            Popup_Bindings.Replace_Element
              (I, (Popup_H    => Popup_H,
                   Dismiss    => Dismiss,
                   Popup_WH   => PH,
                   Dismiss_WH => DH,
                   Owner      => Owner));
            return;
         end if;
      end loop;
      Popup_Bindings.Append
        (Popup_Binding'(Popup_H    => Popup_H,
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
      Owner : constant Combo_Box_Widget_Access := Find_Owner (W'Unchecked_Access);
   begin
      if Button /= Left_Button or else Owner = null then
         return;
      end if;
      Close_Dropdown (Owner.all);
   end On_Mouse_Down;

   procedure Fire_Changed (W : in out Combo_Box_Widget) is
      H    : constant Widget_Handle := Get_Handle (W);
      Idx  : constant Natural := W.Selected;
      Text : constant String := Get_Selected_Text (W);
      procedure Call (CB : Selection_Changed_Callback) is
      begin CB (H, Idx, Text); end Call;
      procedure Emit is new Selection_Changed_Signals.For_Each (Call);
   begin
      Emit (W.Changed);
   end Fire_Changed;

   function Resolve_Popup_Row_Content_Height
     (W : Combo_Box_Widget) return Pixel_Type
   is
      Total : Pixel_Type := 0.0;
      PH    : constant Popup_Lists.List_Box_Handle := W.Popup;
      Count : constant Natural :=
        (if Popup_Lists.Is_Valid (PH) then Popup_Lists.Row_Count (PH) else 0);
      Row_H : Pixel_Type;
   begin
      if not Popup_Lists.Is_Valid (PH) then
         return 0.0;
      end if;

      for I in 1 .. Count loop
         declare
            Row_Hnd : constant Widget_Handle := Popup_Lists.Get_Row_Handle (PH, I);
            Pref : Size_2D;
         begin
            if not Is_Valid (Row_Hnd) then
               Row_H := Default_Popup_Row_Height;
            else
               declare
                  R : constant Widget_Ref := Borrow (Row_Hnd);
               begin
                  Pref := Get_Preferred_Size (R.Ptr.all);
               end;
               Row_H :=
                 (if Pref.Height > 0.0 then Pref.Height else Default_Popup_Row_Height);
            end if;
            Total := Total + Row_H;
         end;
      end loop;

      if Count > 1 then
         declare
            R : constant Widget_Ref := Borrow (+W.Popup);
            S : constant Resolved_Style :=
              Get_Resolved_Part_Style (R.Ptr.all, Main_Part);
         begin
            Total :=
              Total + Pixel_Type (Count - 1) * Get_Row_Gap (S.Gap);
         end;
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
      R : constant Widget_Ref := Borrow (+W.Popup);
      Popup_Style : constant Resolved_Style := Get_Resolved_Part_Style (R.Ptr.all, Main_Part);
      Content_H   : constant Pixel_Type := Resolve_Popup_Row_Content_Height (W);
      Max_H       : constant Pixel_Type := Resolve_Popup_Max_Height (Popup_Style, Win_Size.Height);
      Min_H       : constant Pixel_Type :=
        Pixel_Type'Min (Resolve_Popup_Min_Height (Popup_Style, Win_Size.Height), Max_H);
      Desired_H   : constant Pixel_Type :=
        Outer_Size ((0.0, Content_H), Popup_Style).Height;
   begin
      return Pixel_Type'Min (Max_H, Pixel_Type'Max (Min_H, Desired_H));
   end Resolve_Popup_Height;

   procedure Sync_Selected_From_Popup (W : in out Combo_Box_Widget) is
      Current : Natural;
   begin
      if not Popup_Lists.Is_Valid (W.Popup) then
         return;
      end if;

      Current := Popup_Lists.Get_Current_Row (W.Popup);
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
     (W      : Widget_Handle;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (Clicks);
      Owner : Combo_Box_Widget_Access := null;
   begin
      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Popup_WH = W then
            Owner := Popup_Bindings.Element (I).Owner;
            exit;
         end if;
      end loop;

      if Owner = null then
         return;
      end if;

      Set_Selected_Index (Owner.all, Natural (Index));
      Close_Dropdown (Owner.all);
   end On_Popup_Item_Clicked;

   function Create_Handle return Combo_Box_Handle is
      Result  : constant Combo_Box_Widget_Access := new Combo_Box_Widget;
      Dismiss : constant Dismiss_Layer_Widget_Access := new Dismiss_Layer_Widget;
      PH      : constant Popup_Lists.List_Box_Handle := Popup_Lists.Create_Handle;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);

      Result.Popup := PH;
      Popup_Lists.Set_Selection_Mode (PH, Popup_Lists.Single_Selection);
      Set_Flag (+PH, Focusable, False);
      Popup_Lists.Connect_Item_Clicked (PH, On_Popup_Item_Clicked'Access);

      if not Default_Dropdown_Styles.Is_Empty then
         Popup_Lists.Set_Part_Styles (PH, Default_Dropdown_Styles.Element);
      end if;

      Set_Flag (Dismiss.all, Visible, True);
      Set_Flag (Dismiss.all, Clickable, True);
      Set_Flag (Dismiss.all, Focusable, False);
      Register_Widget (Widget_Access (Dismiss));
      Register_Binding (PH, Dismiss, Result);

      Register_Widget (Widget_Access (Result));
      return (Id => Get_Handle (Result.all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Combo_Box_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Combo_Box (H : Widget_Handle) return Combo_Box_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Combo_Box_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Combo_Box_Handle;
   end Try_As_Combo_Box;

   function Is_Valid (H : Combo_Box_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Combo_Box_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Combo_Box_Handle; Styles : Part_Style_Array)
   is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   procedure Attach_Window
     (W    : in out Combo_Box_Widget;
      Host : Adi.Window.Window_Handle)
   is
   begin
      W.Host_Window := Host;
   end Attach_Window;

   procedure Add_Item (W    : in out Combo_Box_Widget;
                       Text : String;
                       Icon : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
                       Data : Item_Data_Access       := null)
   is
      Row_H : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle (Text);
   begin
      if W.Has_Option_Row_Styles then
         Adi.Widget.Label.Set_Part_Styles (Row_H, W.Option_Row_Styles);
      elsif not Default_Option_Row_Styles.Is_Empty then
         Adi.Widget.Label.Set_Part_Styles
           (Row_H, Default_Option_Row_Styles.Element);
      end if;

      if Icon /= Adi.Image.Null_Image_Handle then
         Adi.Widget.Label.Set_Icon (Row_H, Icon);
      end if;

      W.Options.Append (Combo_Item'(Text => To_Unbounded_String (Text),
                                   Icon => Icon,
                                   Data => Data));
      if Popup_Lists.Is_Valid (W.Popup) then
         Popup_Lists.Append_Row
           (W.Popup, Adi.Widget.Label.To_Widget_Handle (Row_H));
      end if;

      if W.Selected = 0 then
         W.Selected := 1;
         if Popup_Lists.Is_Valid (W.Popup) then
            Popup_Lists.Select_Row (W.Popup, 1);
         end if;
      end if;
      Mark_Dirty (W);
   end Add_Item;

   procedure Clear_Items (W : in out Combo_Box_Widget) is
   begin
      W.Options.Clear;
      W.Selected := 0;
      if Popup_Lists.Is_Valid (W.Popup) then
         Popup_Lists.Clear_Rows (W.Popup);
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
      if Popup_Lists.Is_Valid (W.Popup) then
         if New_Index = 0 then
            Popup_Lists.Clear_Selection (W.Popup);
         else
            Popup_Lists.Select_Row (W.Popup, Positive (New_Index));
         end if;
      end if;

      Mark_Dirty (W);
      Fire_Changed (W);
   end Set_Selected_Index;

   function Get_Selected_Index (W : Combo_Box_Widget) return Natural is
   begin
      return W.Selected;
   end Get_Selected_Index;

   function Get_Selected_Item (W : Combo_Box_Widget) return Combo_Item is
      Empty : constant Combo_Item := (others => <>);
   begin
      if W.Selected = 0 or else W.Selected > Natural (W.Options.Length) then
         return Empty;
      end if;
      return W.Options.Element (Positive (W.Selected));
   end Get_Selected_Item;

   function Get_Selected_Text (W : Combo_Box_Widget) return String is
   begin
      return To_String (Get_Selected_Item (W).Text);
   end Get_Selected_Text;

   function Get_Selected_Data (W : Combo_Box_Widget) return Item_Data_Access is
   begin
      return Get_Selected_Item (W).Data;
   end Get_Selected_Data;

   function Get_Item_Data (W     : Combo_Box_Widget;
                           Index : Positive) return Item_Data_Access is
   begin
      if Index > Natural (W.Options.Length) then
         return null;
      end if;
      return W.Options.Element (Index).Data;
   end Get_Item_Data;

   function Get_Item_Icon (W     : Combo_Box_Widget;
                           Index : Positive) return Adi.Image.Image_Handle is
   begin
      if Index > Natural (W.Options.Length) then
         return Adi.Image.Null_Image_Handle;
      end if;
      return W.Options.Element (Index).Icon;
   end Get_Item_Icon;

   procedure Connect_Selection_Changed
     (W  : in out Combo_Box_Widget;
      CB : Selection_Changed_Callback)
   is
   begin
      W.Changed.Connect (CB);
   end Connect_Selection_Changed;

   function Connect_Selection_Changed
     (W  : in out Combo_Box_Widget;
      CB : Selection_Changed_Callback)
      return Selection_Changed_Signals.Connection_Id
   is
   begin
      return W.Changed.Connect (CB);
   end Connect_Selection_Changed;

   procedure Disconnect_Selection_Changed
     (W  : in out Combo_Box_Widget;
      Id : Selection_Changed_Signals.Connection_Id)
   is
   begin
      W.Changed.Disconnect (Id);
   end Disconnect_Selection_Changed;

   procedure Set_Dropdown_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array)
   is
   begin
      if Popup_Lists.Is_Valid (W.Popup) then
         Popup_Lists.Set_Part_Styles (W.Popup, Styles);
      end if;
   end Set_Dropdown_Part_Styles;

   procedure Set_Option_Row_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array)
   is
   begin
      W.Option_Row_Styles := Styles;
      W.Has_Option_Row_Styles := True;

      if Popup_Lists.Is_Valid (W.Popup) then
         declare
            PH : constant Popup_Lists.List_Box_Handle := W.Popup;
         begin
            for I in 1 .. Popup_Lists.Row_Count (PH) loop
               declare
                  Row : constant Widget_Handle :=
                    Popup_Lists.Get_Row_Handle (PH, I);
               begin
                  if Is_Valid (Row) then
                     Set_Part_Styles (Row, W.Option_Row_Styles);
                  end if;
               end;
            end loop;
         end;
      end if;
   end Set_Option_Row_Part_Styles;

   procedure Set_Default_Dropdown_Styles (Styles : Part_Style_Array) is
   begin
      Default_Dropdown_Styles := Part_Style_Holders.To_Holder (Styles);
   end Set_Default_Dropdown_Styles;

   procedure Set_Default_Option_Row_Styles (Styles : Part_Style_Array) is
   begin
      Default_Option_Row_Styles := Part_Style_Holders.To_Holder (Styles);
   end Set_Default_Option_Row_Styles;

   procedure Set_Arrow_Image
     (W    : in out Combo_Box_Widget;
      Down : Image_Handle;
      Up   : Image_Handle := Adi.Image.Null_Image_Handle)
   is
   begin
      --  Whatever this widget drew for itself is not wanted now.
      Adi.Image.Release (W.Own_Arrow_Down);
      Adi.Image.Release (W.Own_Arrow_Up);
      W.Arrow_Down_Img := Down;
      W.Arrow_Up_Img := (if Up /= Adi.Image.Null_Image_Handle then Up else Down);
      Mark_Dirty (W);
   end Set_Arrow_Image;

   procedure Set_Default_Arrow_Image
     (Down : Image_Handle;
      Up   : Image_Handle := Adi.Image.Null_Image_Handle)
   is
   begin
      Default_Arrow_Down := Down;
      Default_Arrow_Up := (if Up /= Adi.Image.Null_Image_Handle then Up else Down);
   end Set_Default_Arrow_Image;

   procedure Ensure_Arrow_Images (W : in out Combo_Box_Widget) is
   begin
      if W.Arrow_Down_Img /= Adi.Image.Null_Image_Handle then
         return;
      end if;

      --  Use package-level defaults if set
      if Default_Arrow_Down /= Adi.Image.Null_Image_Handle then
         W.Arrow_Down_Img := Default_Arrow_Down;
         W.Arrow_Up_Img :=
           (if Default_Arrow_Up /= Adi.Image.Null_Image_Handle then Default_Arrow_Up
            else Default_Arrow_Down);
         return;
      end if;

      --  Built here for want of any supplied, so this widget owns them
      --  and releases them when it goes.
      W.Own_Arrow_Down := Load_SVG_Path
        (Path_Data    => Arrow_Down_Path,
         Size         => Arrow_SVG_Size,
         Fill         => Arrow_Clear,
         Stroke_Width => 2.5,
         Stroke       => Arrow_White,
         Tintable     => True);
      W.Own_Arrow_Up := Load_SVG_Path
        (Path_Data    => Arrow_Up_Path,
         Size         => Arrow_SVG_Size,
         Fill         => Arrow_Clear,
         Stroke_Width => 2.5,
         Stroke       => Arrow_White,
         Tintable     => True);
      W.Arrow_Down_Img := Adi.Image.To_Handle (W.Own_Arrow_Down);
      W.Arrow_Up_Img := Adi.Image.To_Handle (W.Own_Arrow_Up);
   end Ensure_Arrow_Images;

   procedure Ensure_Host_Window (W : in out Combo_Box_Widget) is
   begin
      W.Host_Window := Adi.Window.Find_Host_Window (Get_Handle (W));
   end Ensure_Host_Window;

   procedure Position_Popup (W : in out Combo_Box_Widget) is
      Anchor   : Rectangle;
      Win_Size : Size_2D;
      Popup_H  : Pixel_Type;
      X_Pos    : Pixel_Type;
      Y_Pos    : Pixel_Type;
   begin
      Ensure_Host_Window (W);
      if not Adi.Window.Is_Valid (W.Host_Window) or else not Popup_Lists.Is_Valid (W.Popup) then
         return;
      end if;

      --  The popup is a window overlay, so anchor it where the combo
      --  actually appears rather than where its unscrolled geometry says.
      Anchor := Adi.Window.Geometry_In_Window (Get_Handle (W));
      Win_Size := Adi.Window.Get_Size (W.Host_Window);
      Popup_H := Resolve_Popup_Height (W, Win_Size);

      X_Pos := Anchor.X;
      if X_Pos + Anchor.Width > Win_Size.Width then
         X_Pos := Pixel_Type'Max (0.0, Win_Size.Width - Anchor.Width);
      end if;

      declare
         Gap : constant Pixel_Type := 4.0;
      begin
         Y_Pos := Anchor.Y + Anchor.Height + Gap;
         if Y_Pos + Popup_H > Win_Size.Height
           and then Anchor.Y - Popup_H - Gap >= 0.0
         then
            Y_Pos := Anchor.Y - Popup_H - Gap;
         elsif Y_Pos + Popup_H > Win_Size.Height then
            Y_Pos := Pixel_Type'Max (0.0, Win_Size.Height - Popup_H);
         end if;
      end;

      declare
         R : constant Widget_Ref := Borrow (+W.Popup);
      begin
         Set_Geometry
           (R.Ptr.all,
            (X => X_Pos, Y => Y_Pos, Width => Anchor.Width, Height => Popup_H));
         Layout (R.Ptr.all);
      end;
   end Position_Popup;

   procedure Position_Dismiss_Layer (W : in out Combo_Box_Widget) is
      Win_Size : Size_2D;
      Dismiss  : Dismiss_Layer_Widget_Access := null;
   begin
      Ensure_Host_Window (W);
      if not Adi.Window.Is_Valid (W.Host_Window) then
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

      Win_Size := Adi.Window.Get_Size (W.Host_Window);
      Set_Geometry
        (Dismiss.all,
         (X => 0.0, Y => 0.0, Width => Win_Size.Width, Height => Win_Size.Height));
   end Position_Dismiss_Layer;

   procedure Open_Dropdown (W : in out Combo_Box_Widget) is
      Dismiss : Dismiss_Layer_Widget_Access := null;
   begin
      Ensure_Host_Window (W);
      if W.Open or else not Adi.Window.Is_Valid (W.Host_Window)
        or else not Popup_Lists.Is_Valid (W.Popup)
      then
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
         Popup_Lists.Select_Row (W.Popup, Positive (W.Selected));
         Popup_Lists.Ensure_Row_Visible (W.Popup, Positive (W.Selected));
      end if;

      if Dismiss /= null then
         Adi.Window.Add_Overlay (W.Host_Window, Get_Handle (Dismiss.all));
      end if;
      Adi.Window.Add_Overlay (W.Host_Window, +W.Popup);
      W.Open := True;
      if Dismiss /= null then
         Mark_Dirty (Dismiss.all);
      end if;
      Mark_Dirty (+W.Popup);
      Mark_Dirty (W);
   end Open_Dropdown;

   procedure Close_Dropdown (W : in out Combo_Box_Widget) is
      Dismiss : Dismiss_Layer_Widget_Access := null;
   begin
      if not W.Open or else not Adi.Window.Is_Valid (W.Host_Window)
        or else not Popup_Lists.Is_Valid (W.Popup)
      then
         return;
      end if;

      for I in 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Owner = W'Unchecked_Access then
            Dismiss := Popup_Bindings.Element (I).Dismiss;
            exit;
         end if;
      end loop;

      Adi.Window.Remove_Overlay (W.Host_Window, +W.Popup);
      if Dismiss /= null then
         Adi.Window.Remove_Overlay (W.Host_Window, Get_Handle (Dismiss.all));
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
      Ensure_Arrow_Images (W);

      if Item_Count (W) = 0 then
         Adi.Widget.Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Adi.Widget.Add_Item (W, Make_Text (Text_Part, W.Geometry, "", 1));
         Adi.Widget.Add_Item
           (W, Make_Image (Indicator_Part, W.Geometry, W.Arrow_Down_Img, 2));
         Adi.Widget.Add_Item
           (W, Make_Image (Icon_Part, W.Geometry, Adi.Image.Null_Image_Handle, 3));
      end if;

      --  Update panel geometry
      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      --  Update label text + geometry from Layout_Items
      declare
         Label_It : Item renames W.Items.Reference (Label_Idx).Element.all;
         Found : Boolean := False;
      begin
         Label_It.Text_Content :=
           To_Unbounded_String (Get_Selected_Text (W));
         Label_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Text_Part then
               Label_It.Geometry := L_Item.Geometry;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Label_It.Text_Content := Null_Unbounded_String;
         end if;
      end;

      --  Update indicator image + geometry from Layout_Items
      declare
         Ind_It : Item renames
           W.Items.Reference (Indicator_Idx).Element.all;
         Found : Boolean := False;
      begin
         Ind_It.Image_Source :=
           (if W.Open then W.Arrow_Up_Img else W.Arrow_Down_Img);
         Ind_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Indicator_Part then
               Ind_It.Geometry := L_Item.Geometry;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Ind_It.Image_Source := Adi.Image.Null_Image_Handle;
         end if;
      end;

      --  Update selected-item icon + geometry from Layout_Items
      declare
         Icon_It : Item renames W.Items.Reference (Icon_Idx).Element.all;
         Found   : Boolean := False;
      begin
         Icon_It.Image_Source := Get_Selected_Item (W).Icon;
         Icon_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Icon_Part then
               Icon_It.Geometry := L_Item.Geometry;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Icon_It.Image_Source := Adi.Image.Null_Image_Handle;
         end if;
      end;
   end Build_Items;

   overriding function Get_Content_Min_Size
     (W : Combo_Box_Widget) return Size_2D
   is
      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Text_Part);
      Ind_Style   : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Indicator_Part);
      Label_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Float (Font_Length_To_Px (Label_Style.Font_Size)),
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      --  The selected text is elided when there is no room, so width
      --  shrinks freely; height cannot go below one text row, and the
      --  drop-down indicator has to keep its box.
      Char_Size : constant Size_2D :=
        Adi.Font.Measure_Text (Attrs => Label_Attrs, Content => "M");
      Ind_H     : constant Pixel_Type :=
        (if Ind_Style.Display = Display_None then 0.0 else 16.0);
   begin
      return Outer_Size
        ((Char_Size.Width, Pixel_Type'Max (Char_Size.Height, Ind_H)),
         Main_Style);
   end Get_Content_Min_Size;

   overriding procedure Layout (W : in out Combo_Box_Widget) is
      Default_Icon_Size : constant Size_2D := (16.0, 16.0);
      Default_Indicator_Size : constant Size_2D := (16.0, 16.0);

      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Text_Part);
      Ind_Style   : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Indicator_Part);
      Icon_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Icon_Part);
      Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);

      Label_Text : constant String := Get_Selected_Text (W);
      Label_Visible : constant Boolean := Label_Style.Display /= Display_None;
      Indicator_Visible : constant Boolean := Ind_Style.Display /= Display_None;
      Sel_Icon    : constant Adi.Image.Image_Handle := Get_Selected_Item (W).Icon;
      Icon_Visible : constant Boolean :=
        Icon_Style.Display /= Display_None and then Sel_Icon /= Adi.Image.Null_Image_Handle;

      Label_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Float (Font_Length_To_Px (Label_Style.Font_Size)),
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Label_Size : Size_2D := (0.0, 0.0);

      --  Indicator uses image size instead of font measurement
      Indicator_Size : Size_2D := (0.0, 0.0);
   begin
      if Item_Count (W) < 4 then
         return;
      end if;

      if Label_Visible then
         Label_Size := Adi.Font.Measure_Text (Label_Attrs, Label_Text);
      end if;

      if Indicator_Visible then
         declare
            Img : constant Image_Handle :=
              (if W.Open then W.Arrow_Up_Img else W.Arrow_Down_Img);
            Width_Fixed  : constant Boolean := Ind_Style.Width.Kind = Fixed;
            Height_Fixed : constant Boolean := Ind_Style.Height.Kind = Fixed;
            Intrinsic    : Size_2D;
         begin
            if Is_Valid (Img) then
               Get_Size (Img, Intrinsic.Width, Intrinsic.Height);
            else
               Intrinsic := Default_Indicator_Size;
            end if;

            Indicator_Size := Intrinsic;

            if Width_Fixed then
               Indicator_Size.Width :=
                 Size_To_Px (Ind_Style.Width, W.Geometry.Width);
            end if;
            if Height_Fixed then
               Indicator_Size.Height :=
                 Size_To_Px (Ind_Style.Height, W.Geometry.Height);
            end if;

            if Width_Fixed and then not Height_Fixed
              and then Intrinsic.Width > 0.0
            then
               Indicator_Size.Height :=
                 Indicator_Size.Width * Intrinsic.Height / Intrinsic.Width;
            elsif Height_Fixed and then not Width_Fixed
              and then Intrinsic.Height > 0.0
            then
               Indicator_Size.Width :=
                 Indicator_Size.Height * Intrinsic.Width / Intrinsic.Height;
            end if;

            Indicator_Size.Width :=
              Pixel_Type'Max (0.0, Indicator_Size.Width);
            Indicator_Size.Height :=
              Pixel_Type'Max (0.0, Indicator_Size.Height);
         end;
      end if;

      --  Build layout items for flex positioning
      W.Layout_Items.Clear;

      if Icon_Visible then
         declare
            Intrinsic    : Size_2D;
            Icon_Size    : Size_2D;
            Width_Fixed  : constant Boolean := Icon_Style.Width.Kind = Fixed;
            Height_Fixed : constant Boolean := Icon_Style.Height.Kind = Fixed;
         begin
            if Is_Valid (Sel_Icon) then
               Get_Size (Sel_Icon, Intrinsic.Width, Intrinsic.Height);
            else
               Intrinsic := Default_Icon_Size;
            end if;

            Icon_Size := Intrinsic;

            if Width_Fixed then
               Icon_Size.Width :=
                 Size_To_Px (Icon_Style.Width, W.Geometry.Width);
            end if;
            if Height_Fixed then
               Icon_Size.Height :=
                 Size_To_Px (Icon_Style.Height, W.Geometry.Height);
            end if;

            if Width_Fixed and then not Height_Fixed
              and then Intrinsic.Width > 0.0
            then
               Icon_Size.Height :=
                 Icon_Size.Width * Intrinsic.Height / Intrinsic.Width;
            elsif Height_Fixed and then not Width_Fixed
              and then Intrinsic.Height > 0.0
            then
               Icon_Size.Width :=
                 Icon_Size.Height * Intrinsic.Width / Intrinsic.Height;
            end if;

            Icon_Size.Width  := Pixel_Type'Max (0.0, Icon_Size.Width);
            Icon_Size.Height := Pixel_Type'Max (0.0, Icon_Size.Height);

            W.Layout_Items.Append (Layout_Item'(
               Part           => Icon_Part,
               Min_Width      => Float (Icon_Size.Width),
               Min_Height     => Float (Icon_Size.Height),
               Max_Width      => Float (Icon_Size.Width),
               Max_Height     => Float (Icon_Size.Height),
               Content_Width  => Float (Icon_Size.Width),
               Content_Height => Float (Icon_Size.Height),
               Flex           => (Grow       => 0.0,
                                  Shrink     => 0.0,
                                  Basis      => Float (Icon_Size.Width),
                                  Align_Self => Icon_Style.Align_Self),
               Geometry       => <>,
               Index          => 3));
         end;
      end if;

      if Label_Visible then
         W.Layout_Items.Append (Layout_Item'(
            Part           => Text_Part,
            Min_Width      => 0.0,
            Min_Height     => Float (Label_Size.Height),
            Max_Width      => Float'Last,
            Max_Height     => Float'Last,
            Content_Width  => Float (Label_Size.Width),
            Content_Height => Float (Label_Size.Height),
            Flex           => (
               Grow       => 1.0,
               Shrink     => 0.0,
               Basis      => 0.0,
               Align_Self => Label_Style.Align_Self),
            Geometry       => <>,
            Index          => 1));
      end if;

      if Indicator_Visible then
         W.Layout_Items.Append (Layout_Item'(
            Part           => Indicator_Part,
            Min_Width      => Float (Indicator_Size.Width),
            Min_Height     => Float (Indicator_Size.Height),
            Max_Width      => Float (Indicator_Size.Width),
            Max_Height     => Float (Indicator_Size.Height),
            Content_Width  => Float (Indicator_Size.Width),
            Content_Height => Float (Indicator_Size.Height),
            Flex           => (
               Grow       => 0.0,
               Shrink     => 0.0,
               Basis      => Float (Indicator_Size.Width),
               Align_Self => Ind_Style.Align_Self),
            Geometry       => <>,
            Index          => 2));
      end if;

      Perform_Item_Flex_Layout (
         Container_Geom  => Content,
         Container_Style => Main_Style,
         Items           => W.Layout_Items);

      if W.Open and then Adi.Window.Is_Valid (W.Host_Window)
        and then Popup_Lists.Is_Valid (W.Popup)
      then
         Position_Dismiss_Layer (W);
         Position_Popup (W);
         Mark_Dirty (+W.Popup);
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
            elsif Popup_Lists.Is_Valid (W.Popup) then
               declare
                  R : constant Widget_Ref := Borrow (+W.Popup);
               begin
                  On_Key_Down
                    (R.Ptr.all, Scancode, Key_Mod, Repeat);
               end;
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

   overriding procedure On_Destroy (W : in out Combo_Box_Widget) is
   begin
      --  Close dropdown if open (removes overlays from window)
      if W.Open and then Adi.Window.Is_Valid (W.Host_Window) then
         Close_Dropdown (W);
      end if;

      --  Remove binding entry and destroy owned popup/dismiss widgets.
      --  Use stored Widget_Handles — raw access may be dangling if the
      --  overlay was already destroyed during window finalization.
      for I in reverse 1 .. Natural (Popup_Bindings.Length) loop
         if Popup_Bindings.Element (I).Owner = W'Unchecked_Access then
            declare
               Binding : Popup_Binding := Popup_Bindings.Element (I);
            begin
               if Is_Valid (Binding.Popup_WH) then
                  Destroy (Binding.Popup_WH);
               end if;

               if Is_Valid (Binding.Dismiss_WH) then
                  Destroy (Binding.Dismiss_WH);
               end if;
            end;
            Popup_Bindings.Delete (I);
            exit;
         end if;
      end loop;

      Adi.Image.Release (W.Own_Arrow_Down);
      Adi.Image.Release (W.Own_Arrow_Up);
   end On_Destroy;

   ---------------------------------------------------------------------------
   --  Handle methods
   ---------------------------------------------------------------------------

   procedure Add_Item (H    : Combo_Box_Handle;
                       Text : String;
                       Icon : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
                       Data : Item_Data_Access       := null)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Add_Item (Combo_Box_Widget (Ptr.all), Text, Icon, Data);
      end if;
   end Add_Item;

   procedure Clear_Items (H : Combo_Box_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Adi.Widget.Combo_Box.Clear_Items (Combo_Box_Widget (Ptr.all));
      end if;
   end Clear_Items;

   function Option_Count (H : Combo_Box_Handle) return Natural is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Option_Count (Combo_Box_Widget (Ptr.all));
      end if;
      return 0;
   end Option_Count;

   procedure Set_Selected_Index (H : Combo_Box_Handle; Index : Natural) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Selected_Index (Combo_Box_Widget (Ptr.all), Index);
      end if;
   end Set_Selected_Index;

   function Get_Selected_Index (H : Combo_Box_Handle) return Natural is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Selected_Index (Combo_Box_Widget (Ptr.all));
      end if;
      return 0;
   end Get_Selected_Index;

   function Get_Selected_Text (H : Combo_Box_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Selected_Text (Combo_Box_Widget (Ptr.all));
      end if;
      return "";
   end Get_Selected_Text;

   function Get_Selected_Data (H : Combo_Box_Handle) return Item_Data_Access is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Selected_Data (Combo_Box_Widget (Ptr.all));
      end if;
      return null;
   end Get_Selected_Data;

   function Get_Item_Data (H     : Combo_Box_Handle;
                           Index : Positive) return Item_Data_Access is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Item_Data (Combo_Box_Widget (Ptr.all), Index);
      end if;
      return null;
   end Get_Item_Data;

   function Get_Item_Icon (H     : Combo_Box_Handle;
                           Index : Positive) return Adi.Image.Image_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Item_Icon (Combo_Box_Widget (Ptr.all), Index);
      end if;
      return Adi.Image.Null_Image_Handle;
   end Get_Item_Icon;

   procedure Connect_Selection_Changed
     (H : Combo_Box_Handle; CB : Selection_Changed_Callback)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Selection_Changed (Combo_Box_Widget (Ptr.all), CB);
      end if;
   end Connect_Selection_Changed;

   function Connect_Selection_Changed
     (H : Combo_Box_Handle; CB : Selection_Changed_Callback)
      return Selection_Changed_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Selection_Changed (Combo_Box_Widget (Ptr.all), CB);
      end if;
      return Selection_Changed_Signals.No_Connection;
   end Connect_Selection_Changed;

   procedure Disconnect_Selection_Changed
     (H  : Combo_Box_Handle;
      Id : Selection_Changed_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Selection_Changed (Combo_Box_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Selection_Changed;

   procedure Set_Dropdown_Part_Styles
     (H : Combo_Box_Handle; Styles : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Dropdown_Part_Styles (Combo_Box_Widget (Ptr.all), Styles);
      end if;
   end Set_Dropdown_Part_Styles;

   procedure Set_Option_Row_Part_Styles
     (H : Combo_Box_Handle; Styles : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Option_Row_Part_Styles (Combo_Box_Widget (Ptr.all), Styles);
      end if;
   end Set_Option_Row_Part_Styles;

   procedure Set_Arrow_Image
     (H    : Combo_Box_Handle;
      Down : Adi.Image.Image_Handle;
      Up   : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Arrow_Image (Combo_Box_Widget (Ptr.all), Down, Up);
      end if;
   end Set_Arrow_Image;

   procedure Open_Dropdown (H : Combo_Box_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Open_Dropdown (Combo_Box_Widget (Ptr.all));
      end if;
   end Open_Dropdown;

   procedure Close_Dropdown (H : Combo_Box_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Close_Dropdown (Combo_Box_Widget (Ptr.all));
      end if;
   end Close_Dropdown;

   procedure Toggle_Dropdown (H : Combo_Box_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Toggle_Dropdown (Combo_Box_Widget (Ptr.all));
      end if;
   end Toggle_Dropdown;

   function Is_Open (H : Combo_Box_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Open (Combo_Box_Widget (Ptr.all));
      end if;
      return False;
   end Is_Open;

   --  Scrolling moves a combo without re-running layout, so an open
   --  dropdown would stay where it was. Only combos inside the widget
   --  that scrolled can have moved, so the rest are left alone.
   --  Walks the pointer chain rather than handles: a widget attached
   --  through the access-based Add_Child never entered the store and has
   --  no handle, and one of those in the middle of the chain must not
   --  hide the combos below it.
   function Is_Within
     (Node     : not null access Widget'Class;
      Ancestor : not null access Widget'Class) return Boolean
   is
      Cur : access Widget'Class := Node;
   begin
      while Cur /= null loop
         if Cur = Ancestor then
            return True;
         end if;
         Cur := Get_Parent (Cur.all);
      end loop;
      return False;
   end Is_Within;

   procedure Reposition_Open_Popups
     (Scrolled : not null access Widget'Class) is
   begin
      for I in 1 .. Natural (Popup_Bindings.Length) loop
         declare
            B : constant Popup_Binding := Popup_Bindings.Element (I);
         begin
            if B.Owner /= null
              and then B.Owner.Open
              and then Popup_Lists.Is_Valid (B.Owner.Popup)
              and then Is_Within
                         (Widget'Class (B.Owner.all)'Unchecked_Access,
                          Scrolled)
            then
               Position_Dismiss_Layer (Combo_Box_Widget (B.Owner.all));
               Position_Popup (Combo_Box_Widget (B.Owner.all));
               Mark_Dirty (+B.Owner.Popup);
            end if;
         end;
      end loop;
   end Reposition_Open_Popups;

   overriding procedure Finalize (S : in out Scroll_Subscription) is
   begin
      Adi.Widget.Disconnect_Scroll_Changed (S.Id);
      S.Id := Adi.Widget.Scroll_Signals.No_Connection;
   end Finalize;

   --  The callback reaches into Popup_Bindings, so the subscription must
   --  not outlive it. Declared after the vector, hence finalized — and
   --  disconnected — before it.
   Popup_Scroll_Sub : Scroll_Subscription :=
     (Ada.Finalization.Limited_Controlled with
      Id => Adi.Widget.Connect_Scroll_Changed
              (Reposition_Open_Popups'Access));
   pragma Unreferenced (Popup_Scroll_Sub);

end Adi.Widget.Combo_Box;
