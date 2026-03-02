with Ada.Containers.Indefinite_Holders;
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

   Arrow_Down_Path : constant String := "M4 6 L12 14 L20 6";
   Arrow_Up_Path   : constant String := "M4 14 L12 6 L20 14";
   Arrow_SVG_Size  : constant Size_2D := (24.0, 24.0);
   Arrow_White : constant Color_8 := (R => 255, G => 255, B => 255, A => 255);
   Arrow_Clear : constant Color_8 := (R => 0, G => 0, B => 0, A => 0);

   Default_Arrow_Down : Image_Access := null;
   Default_Arrow_Up   : Image_Access := null;

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
      Idx  : constant Natural := W.Selected;
      Text : constant String := Get_Selected_Text (W);
      procedure Call (CB : Selection_Changed_Callback) is
      begin CB (Self, Idx, Text); end Call;
      procedure Emit is new Selection_Changed_Signals.For_Each (Call);
   begin
      Emit (W.Changed);
   end Fire_Changed;

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
         declare
            S : constant Resolved_Style :=
              Get_Resolved_Part_Style (W.Popup.all, Main_Part);
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
      Popup_Style : constant Resolved_Style := Get_Resolved_Part_Style (W.Popup.all, Main_Part);
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
      Popup_Lists.Connect_Item_Clicked
        (Result.Popup.all, On_Popup_Item_Clicked'Access);

      if not Default_Dropdown_Styles.Is_Empty then
         Set_Part_Styles (Result.Popup.all, Default_Dropdown_Styles.Element);
      end if;

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
      elsif not Default_Option_Row_Styles.Is_Empty then
         Set_Part_Styles (Row.all, Default_Option_Row_Styles.Element);
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
      if W.Popup /= null then
         Set_Part_Styles (W.Popup.all, Styles);
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
      Down : Image_Access;
      Up   : Image_Access := null)
   is
   begin
      W.Arrow_Down_Img := Down;
      W.Arrow_Up_Img := (if Up /= null then Up else Down);
      Mark_Dirty (W);
   end Set_Arrow_Image;

   procedure Set_Default_Arrow_Image
     (Down : Image_Access;
      Up   : Image_Access := null)
   is
   begin
      Default_Arrow_Down := Down;
      Default_Arrow_Up := (if Up /= null then Up else Down);
   end Set_Default_Arrow_Image;

   procedure Ensure_Arrow_Images (W : in out Combo_Box_Widget) is
   begin
      if W.Arrow_Down_Img /= null then
         return;
      end if;

      --  Use package-level defaults if set
      if Default_Arrow_Down /= null then
         W.Arrow_Down_Img := Default_Arrow_Down;
         W.Arrow_Up_Img :=
           (if Default_Arrow_Up /= null then Default_Arrow_Up
            else Default_Arrow_Down);
         return;
      end if;

      --  Create built-in SVG chevrons
      W.Arrow_Down_Img := Load_SVG_Path
        (Path_Data    => Arrow_Down_Path,
         Size         => Arrow_SVG_Size,
         Fill         => Arrow_Clear,
         Stroke_Width => 2.5,
         Stroke       => Arrow_White,
         Tintable     => True);
      W.Arrow_Up_Img := Load_SVG_Path
        (Path_Data    => Arrow_Up_Path,
         Size         => Arrow_SVG_Size,
         Fill         => Arrow_Clear,
         Stroke_Width => 2.5,
         Stroke       => Arrow_White,
         Tintable     => True);
   end Ensure_Arrow_Images;

   procedure Ensure_Host_Window (W : in out Combo_Box_Widget) is
   begin
      W.Host_Window := Adi.Window.Find_Host_Window (W'Unchecked_Access);
   end Ensure_Host_Window;

   procedure Position_Popup (W : in out Combo_Box_Widget) is
      Anchor   : Rectangle;
      Win_Size : Size_2D;
      Popup_H  : Pixel_Type;
      X_Pos    : Pixel_Type;
      Y_Pos    : Pixel_Type;
   begin
      Ensure_Host_Window (W);
      if W.Host_Window = null or else W.Popup = null then
         return;
      end if;

      Anchor := Get_Geometry (W);
      Win_Size := Adi.Window.Get_Size (W.Host_Window.all);
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

      Set_Geometry
        (W.Popup.all,
         (X => X_Pos, Y => Y_Pos, Width => Anchor.Width, Height => Popup_H));
      Layout (Widget'Class (W.Popup.all));
   end Position_Popup;

   procedure Position_Dismiss_Layer (W : in out Combo_Box_Widget) is
      Win_Size : Size_2D;
      Dismiss  : Dismiss_Layer_Widget_Access := null;
   begin
      Ensure_Host_Window (W);
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
      Ensure_Host_Window (W);
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
      Ensure_Arrow_Images (W);

      if Item_Count (W) = 0 then
         Adi.Widget.Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Adi.Widget.Add_Item (W, Make_Text (Text_Part, W.Geometry, "", 1));
         Adi.Widget.Add_Item
           (W, Make_Image (Indicator_Part, W.Geometry, W.Arrow_Down_Img, 2));
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
            Ind_It.Image_Source := null;
         end if;
      end;
   end Build_Items;

   overriding procedure Layout (W : in out Combo_Box_Widget) is
      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Text_Part);
      Ind_Style   : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Indicator_Part);
      Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);

      Label_Text : constant String := Get_Selected_Text (W);
      Label_Visible : constant Boolean := Label_Style.Display /= Display_None;
      Indicator_Visible : constant Boolean := Ind_Style.Display /= Display_None;

      Label_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Float (Length_To_Px (Label_Style.Font_Size)),
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Label_Size : Size_2D := (0.0, 0.0);

      --  Indicator uses image size instead of font measurement
      Ind_Img_W : Pixel_Type := 0.0;
      Ind_Img_H : Pixel_Type := 0.0;
      Ind_W     : Pixel_Type := 0.0;
   begin
      if Item_Count (W) < 3 then
         return;
      end if;

      if Label_Visible then
         Label_Size := Adi.Font.Measure_Text (Label_Attrs, Label_Text);
      end if;

      if Indicator_Visible then
         --  Get indicator image dimensions
         declare
            Img : constant Image_Access :=
              (if W.Open then W.Arrow_Up_Img else W.Arrow_Down_Img);
         begin
            if Img /= null and then Is_Valid (Img.all) then
               Get_Size (Img.all, Ind_Img_W, Ind_Img_H);
            end if;
         end;
         Ind_W := Pixel_Type'Max (Ind_Img_W, 16.0);
      end if;

      --  Build layout items for flex positioning
      W.Layout_Items.Clear;

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
            Min_Width      => Float (Ind_W),
            Min_Height     => Float (Ind_Img_H),
            Max_Width      => Float (Ind_W),
            Max_Height     => Float'Last,
            Content_Width  => Float (Ind_W),
            Content_Height => Float (Ind_Img_H),
            Flex           => (
               Grow       => 0.0,
               Shrink     => 0.0,
               Basis      => Float (Ind_W),
               Align_Self => Ind_Style.Align_Self),
            Geometry       => <>,
            Index          => 2));
      end if;

      Perform_Item_Flex_Layout (
         Container_Geom  => Content,
         Container_Style => Main_Style,
         Items           => W.Layout_Items);

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
