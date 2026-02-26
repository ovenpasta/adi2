with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.Events;        use Adi.SDL.Events;
with Adi.Widget.Button;     use Adi.Widget.Button;

package body Adi.Widget.Dialog is

   Default_Panel_Styles      : Part_Style_Holders.Holder;
   Default_Title_Styles      : Part_Style_Holders.Holder;
   Default_Message_Styles    : Part_Style_Holders.Holder;
   Default_Button_Row_Styles : Part_Style_Holders.Holder;
   Default_Button_Styles         : Part_Style_Holders.Holder;
   Default_Primary_Button_Styles : Part_Style_Holders.Holder;
   Default_Content_Styles        : Part_Style_Holders.Holder;

   ---------------------------------------------------------------------------
   --  Internal: Dialog_Button_Widget extends Button to forward Escape
   ---------------------------------------------------------------------------

   type Dialog_Button_Widget is new Button_Widget with null record;
   type Dialog_Button_Widget_Access is access all Dialog_Button_Widget'Class;

   overriding procedure On_Key_Down
     (W        : in out Dialog_Button_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean);

   ---------------------------------------------------------------------------
   --  Bindings: map buttons back to owning dialog
   ---------------------------------------------------------------------------

   type Dialog_Binding is record
      Btn   : Widget_Access := null;
      Owner : Dialog_Widget_Access := null;
   end record;

   package Binding_Vectors is new Ada.Containers.Vectors (Positive, Dialog_Binding);

   Dialog_Bindings : Binding_Vectors.Vector;

   function Find_Owner_By_Button
     (Btn : Widget_Access) return Dialog_Widget_Access
   is
   begin
      for I in 1 .. Natural (Dialog_Bindings.Length) loop
         if Dialog_Bindings.Element (I).Btn = Btn then
            return Dialog_Bindings.Element (I).Owner;
         end if;
      end loop;
      return null;
   end Find_Owner_By_Button;

   procedure Register_Button_Binding
     (Btn   : Widget_Access;
      Owner : Dialog_Widget_Access)
   is
   begin
      Dialog_Bindings.Append
        (Dialog_Binding'(Btn => Btn, Owner => Owner));
   end Register_Button_Binding;

   procedure Unregister_Bindings (Owner : Dialog_Widget_Access) is
      I : Natural := 1;
   begin
      while I <= Natural (Dialog_Bindings.Length) loop
         if Dialog_Bindings.Element (I).Owner = Owner then
            Dialog_Bindings.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
   end Unregister_Bindings;

   function Find_Button_Index
     (W   : Dialog_Widget;
      Btn : Widget_Access) return Natural
   is
   begin
      for I in 1 .. Natural (W.Buttons.Length) loop
         if W.Buttons.Element (I).Widget = Btn then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Button_Index;

   ---------------------------------------------------------------------------
   --  Dialog_Button_Widget: forward Escape to parent dialog
   ---------------------------------------------------------------------------

   overriding procedure On_Key_Down
     (W        : in out Dialog_Button_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean)
   is
   begin
      if Scancode = SDL_SCANCODE_ESCAPE then
         declare
            Owner : constant Dialog_Widget_Access :=
              Find_Owner_By_Button (W'Unchecked_Access);
         begin
            if Owner /= null then
               On_Key_Down (Widget'Class (Owner.all), Scancode, Key_Mod, Repeat);
               return;
            end if;
         end;
      end if;
      --  Delegate Return/Space to parent Button_Widget
      On_Key_Down (Button_Widget (W), Scancode, Key_Mod, Repeat);
   end On_Key_Down;

   ---------------------------------------------------------------------------
   --  Apply_Button_Styles: apply normal or primary style to each button
   ---------------------------------------------------------------------------

   procedure Apply_Button_Styles (W : in out Dialog_Widget) is
      --  Resolve once: normal and primary styles for this dialog
      Normal_Styles : constant Part_Style_Array :=
        (if W.Has_Button_Styles then W.Button_Styles
         elsif not Default_Button_Styles.Is_Empty
         then Default_Button_Styles.Element
         else Empty_Part_Styles);
      Primary_Styles : constant Part_Style_Array :=
        (if W.Has_Primary_Button_Styles then W.Primary_Button_Styles
         elsif not Default_Primary_Button_Styles.Is_Empty
         then Default_Primary_Button_Styles.Element
         else Normal_Styles);
   begin
      for I in 1 .. Natural (W.Buttons.Length) loop
         declare
            Btn : constant Widget_Access := W.Buttons.Element (I).Widget;
         begin
            if Btn /= null then
               if I = W.Default_Button_Index then
                  Set_Part_Styles (Btn.all, Primary_Styles);
               else
                  Set_Part_Styles (Btn.all, Normal_Styles);
               end if;
            end if;
         end;
      end loop;
   end Apply_Button_Styles;

   ---------------------------------------------------------------------------
   --  On_Button_Clicked: shared click handler for dialog buttons
   ---------------------------------------------------------------------------

   procedure On_Button_Clicked (Btn : Button_Widget_Access) is
      Btn_Widget : constant Widget_Access := Widget_Access (Btn);
      Owner      : constant Dialog_Widget_Access := Find_Owner_By_Button (Btn_Widget);
      Index      : Natural;
      Text       : Unbounded_String;
   begin
      if Owner = null then
         return;
      end if;

      Index := Find_Button_Index (Dialog_Widget (Owner.all), Btn_Widget);
      if Index > 0 then
         Text := Owner.Buttons.Element (Index).Text;
      end if;

      if Owner.On_Result /= null then
         Owner.On_Result (Owner, Index, To_String (Text));
      end if;
      Hide (Owner.all);
   end On_Button_Clicked;

   ---------------------------------------------------------------------------
   --  Fire_Dismiss: report a dismiss (backdrop/escape) result
   ---------------------------------------------------------------------------

   procedure Fire_Dismiss (W : in out Dialog_Widget) is
      Self : constant Dialog_Widget_Access := W'Unchecked_Access;
   begin
      if not W.Shown then
         return;  --  Already dismissed (guard against double-dispatch)
      end if;
      if W.On_Result /= null then
         W.On_Result (Self, 0, "");
      end if;
      Hide (W);
   end Fire_Dismiss;

   ---------------------------------------------------------------------------
   --  Create
   ---------------------------------------------------------------------------

   use type Adi.Window.Window_Access;
   use type Adi.Widget.Box.Box_Widget_Access;
   use type Adi.Widget.Label.Label_Widget_Access;

   function Create return Dialog_Widget_Access is
      Result : constant Dialog_Widget_Access := new Dialog_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);

      --  Content panel: flex column
      Result.Content_Panel := Adi.Widget.Box.Create;

      --  Title label
      Result.Title_Label := Adi.Widget.Label.Create ("");
      Add_Child (Result.Content_Panel.all, Widget_Access (Result.Title_Label));

      --  Message label
      Result.Message_Label := Adi.Widget.Label.Create ("");
      Add_Child (Result.Content_Panel.all, Widget_Access (Result.Message_Label));

      --  Button row: flex row
      Result.Button_Row := Adi.Widget.Box.Create;
      Add_Child (Result.Content_Panel.all, Widget_Access (Result.Button_Row));

      --  Content panel must be part of the dialog tree so overlay rendering
      --  traverses and draws title/message/buttons above the backdrop.
      Add_Child (Result.all, Widget_Access (Result.Content_Panel));

      --  Apply package-level default styles if set
      if not Default_Panel_Styles.Is_Empty then
         Set_Part_Styles (Result.Content_Panel.all, Default_Panel_Styles.Element);
      end if;
      if not Default_Title_Styles.Is_Empty then
         Set_Part_Styles (Result.Title_Label.all, Default_Title_Styles.Element);
      end if;
      if not Default_Message_Styles.Is_Empty then
         Set_Part_Styles (Result.Message_Label.all, Default_Message_Styles.Element);
      end if;
      if not Default_Button_Row_Styles.Is_Empty then
         Set_Part_Styles (Result.Button_Row.all, Default_Button_Row_Styles.Element);
      end if;
      if not Default_Button_Styles.Is_Empty then
         Result.Button_Styles := Default_Button_Styles.Element;
         Result.Has_Button_Styles := True;
      end if;

      return Result;
   end Create;

   ---------------------------------------------------------------------------
   --  Attach_Window
   ---------------------------------------------------------------------------

   procedure Attach_Window
     (W    : in out Dialog_Widget;
      Host : Adi.Window.Window_Access)
   is
   begin
      W.Host_Window := Host;
   end Attach_Window;

   ---------------------------------------------------------------------------
   --  Content setters
   ---------------------------------------------------------------------------

   procedure Set_Title (W : in out Dialog_Widget; Text : String) is
   begin
      if W.Title_Label /= null then
         Adi.Widget.Label.Set_Text (W.Title_Label.all, Text);
      end if;
      Mark_Dirty (W);
   end Set_Title;

   procedure Set_Message (W : in out Dialog_Widget; Text : String) is
   begin
      if W.Custom_Content /= null then
         return;  --  Message label not in tree when custom content is set
      end if;
      if W.Message_Label /= null then
         Adi.Widget.Label.Set_Text (W.Message_Label.all, Text);
      end if;
      Mark_Dirty (W);
   end Set_Message;

   ---------------------------------------------------------------------------
   --  Icon
   ---------------------------------------------------------------------------

   procedure Set_Icon (W : in out Dialog_Widget; Icon : Image_Access) is
   begin
      if W.Custom_Content /= null then
         return;  --  Message label not in tree when custom content is set
      end if;
      if W.Message_Label /= null then
         Adi.Widget.Label.Set_Icon (W.Message_Label.all, Icon);
      end if;
      Mark_Dirty (W);
   end Set_Icon;

   ---------------------------------------------------------------------------
   --  Custom content
   ---------------------------------------------------------------------------

   procedure Set_Content
     (W       : in out Dialog_Widget;
      Content : access Widget'Class)
   is
      Had_Custom : constant Boolean := W.Custom_Content /= null;
   begin
      --  Remove previous custom content if any
      if W.Custom_Content /= null then
         Remove_Child (W.Content_Panel.all, W.Custom_Content);
         W.Custom_Content := null;
      end if;

      if Content /= null then
         --  Remove message label from tree only if it is currently attached
         --  (i.e. we were not already in custom-content mode).
         if not Had_Custom and then W.Message_Label /= null then
            Remove_Child (W.Content_Panel.all, Widget_Access (W.Message_Label));
         end if;
         --  Remove button row so we can re-add after content
         Remove_Child (W.Content_Panel.all, Widget_Access (W.Button_Row));

         --  Detach from any existing parent before adopting
         if Content.Parent /= null then
            Remove_Child (Content.Parent.all, Content);
         end if;

         W.Custom_Content := Content.all'Unchecked_Access;
         if not Default_Content_Styles.Is_Empty then
            Set_Part_Styles (W.Custom_Content.all, Default_Content_Styles.Element);
         end if;
         Add_Child (W.Content_Panel.all, W.Custom_Content);
         Add_Child (W.Content_Panel.all, Widget_Access (W.Button_Row));
      else
         --  Restore message label only if we were in custom-content mode
         if Had_Custom and then W.Message_Label /= null then
            Remove_Child (W.Content_Panel.all, Widget_Access (W.Button_Row));
            Add_Child (W.Content_Panel.all, Widget_Access (W.Message_Label));
            Add_Child (W.Content_Panel.all, Widget_Access (W.Button_Row));
         end if;
      end if;

      Mark_Dirty (W);
   end Set_Content;

   ---------------------------------------------------------------------------
   --  Button management
   ---------------------------------------------------------------------------

   function Add_Button
     (W : in out Dialog_Widget; Text : String) return Positive
   is
      Btn : constant Dialog_Button_Widget_Access := new Dialog_Button_Widget;
      Btn_As_Widget : constant Widget_Access := Widget_Access (Btn);
   begin
      Set_Flag (Btn.all, Visible, True);
      Set_Flag (Btn.all, Clickable, True);
      Set_Flag (Btn.all, Focusable, True);
      Adi.Widget.Label.Set_Text
        (Adi.Widget.Label.Label_Widget (Btn.all), Text);
      Set_On_Clicked (Btn.all, On_Button_Clicked'Access);

      Register_Button_Binding (Btn_As_Widget, W'Unchecked_Access);
      Add_Child (W.Button_Row.all, Widget_Access (Btn));
      W.Buttons.Append
        (Button_Info'(Text   => To_Unbounded_String (Text),
                      Widget => Btn_As_Widget));

      --  Apply normal or primary style to the newly added button
      Apply_Button_Styles (W);
      Mark_Dirty (W);
      return Positive (W.Buttons.Length);
   end Add_Button;

   procedure Add_Button (W : in out Dialog_Widget; Text : String) is
      Unused : constant Positive := Add_Button (W, Text);
   begin
      null;
   end Add_Button;

   procedure Clear_Buttons (W : in out Dialog_Widget) is
   begin
      Unregister_Bindings (W'Unchecked_Access);
      --  Remove button widgets from button row
      for Info of W.Buttons loop
         if Info.Widget /= null then
            Remove_Child (W.Button_Row.all, Info.Widget);
         end if;
      end loop;
      W.Buttons.Clear;
      W.Default_Button_Index := 0;
      Mark_Dirty (W);
   end Clear_Buttons;

   ---------------------------------------------------------------------------
   --  Set_Default_Button / Get_Button
   ---------------------------------------------------------------------------

   procedure Set_Default_Button (W : in out Dialog_Widget; Index : Natural) is
   begin
      W.Default_Button_Index := Index;
      Apply_Button_Styles (W);
   end Set_Default_Button;

   function Get_Button
     (W : Dialog_Widget; Index : Positive)
      return Adi.Widget.Button.Button_Widget_Access
   is
   begin
      if Index > Natural (W.Buttons.Length) then
         return null;
      end if;
      return Adi.Widget.Button.Button_Widget_Access (W.Buttons.Element (Index).Widget);
   end Get_Button;

   ---------------------------------------------------------------------------
   --  Presets
   ---------------------------------------------------------------------------

   procedure Set_OK_Button (W : in out Dialog_Widget) is
   begin
      Clear_Buttons (W);
      Add_Button (W, "OK");
      Set_Default_Button (W, 1);
   end Set_OK_Button;

   procedure Set_OK_Cancel (W : in out Dialog_Widget) is
   begin
      Clear_Buttons (W);
      Add_Button (W, "Cancel");
      Add_Button (W, "OK");
      Set_Default_Button (W, 2);
   end Set_OK_Cancel;

   procedure Set_Yes_No (W : in out Dialog_Widget) is
   begin
      Clear_Buttons (W);
      Add_Button (W, "No");
      Add_Button (W, "Yes");
      Set_Default_Button (W, 2);
   end Set_Yes_No;

   procedure Set_Yes_No_Cancel (W : in out Dialog_Widget) is
   begin
      Clear_Buttons (W);
      Add_Button (W, "Cancel");
      Add_Button (W, "No");
      Add_Button (W, "Yes");
      Set_Default_Button (W, 3);
   end Set_Yes_No_Cancel;

   ---------------------------------------------------------------------------
   --  Show / Hide
   ---------------------------------------------------------------------------

   procedure Show (W : in out Dialog_Widget) is
   begin
      if W.Shown or else W.Host_Window = null then
         return;
      end if;

      declare
         Win_Size : constant Size_2D := Adi.Window.Get_Size (W.Host_Window.all);
      begin
         Set_Geometry (W, (0.0, 0.0, Win_Size.Width, Win_Size.Height));
      end;

      Adi.Window.Add_Overlay (W.Host_Window.all, Widget_Access'(W'Unchecked_Access));
      W.Shown := True;

      --  Defer auto-focus to the first Build_Items pass so the overlay
      --  tree has been fully laid out before Set_Focus is called.
      if W.Default_Button_Index > 0
        and then W.Default_Button_Index <= Natural (W.Buttons.Length)
      then
         W.Pending_Focus := True;
      end if;

      Mark_Dirty (W);
   end Show;

   procedure Hide (W : in out Dialog_Widget) is
   begin
      if not W.Shown or else W.Host_Window = null then
         return;
      end if;

      Adi.Window.Remove_Overlay (W.Host_Window.all, Widget_Access'(W'Unchecked_Access));
      W.Shown := False;
      Mark_Dirty (W);
   end Hide;

   function Is_Shown (W : Dialog_Widget) return Boolean is
   begin
      return W.Shown;
   end Is_Shown;

   ---------------------------------------------------------------------------
   --  Dismiss policies
   ---------------------------------------------------------------------------

   procedure Set_Dismiss_On_Backdrop
     (W : in out Dialog_Widget; Value : Boolean := True)
   is
   begin
      W.Dismiss_On_Backdrop_Flag := Value;
   end Set_Dismiss_On_Backdrop;

   procedure Set_Dismiss_On_Escape
     (W : in out Dialog_Widget; Value : Boolean := True)
   is
   begin
      W.Dismiss_On_Escape_Flag := Value;
   end Set_Dismiss_On_Escape;

   ---------------------------------------------------------------------------
   --  Result callback
   ---------------------------------------------------------------------------

   procedure Set_On_Result
     (W  : in out Dialog_Widget;
      CB : Dialog_Result_Callback)
   is
   begin
      W.On_Result := CB;
   end Set_On_Result;

   ---------------------------------------------------------------------------
   --  Style injection
   ---------------------------------------------------------------------------

   procedure Set_Panel_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if W.Content_Panel /= null then
         Set_Part_Styles (W.Content_Panel.all, S);
      end if;
   end Set_Panel_Style;

   procedure Set_Title_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if W.Title_Label /= null then
         Set_Part_Styles (W.Title_Label.all, S);
      end if;
   end Set_Title_Style;

   procedure Set_Message_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if W.Message_Label /= null then
         Set_Part_Styles (W.Message_Label.all, S);
      end if;
   end Set_Message_Style;

   procedure Set_Button_Row_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if W.Button_Row /= null then
         Set_Part_Styles (W.Button_Row.all, S);
      end if;
   end Set_Button_Row_Style;

   procedure Set_Button_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      W.Button_Styles := S;
      W.Has_Button_Styles := True;
      Apply_Button_Styles (W);
   end Set_Button_Style;

   procedure Set_Primary_Button_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      W.Primary_Button_Styles := S;
      W.Has_Primary_Button_Styles := True;
      Apply_Button_Styles (W);
   end Set_Primary_Button_Style;

   procedure Set_Content_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if W.Custom_Content /= null then
         Set_Part_Styles (W.Custom_Content.all, S);
      end if;
   end Set_Content_Style;

   ---------------------------------------------------------------------------
   --  Package-level default style setters
   ---------------------------------------------------------------------------

   procedure Set_Default_Panel_Style (S : Part_Style_Array) is
   begin
      Default_Panel_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Panel_Style;

   procedure Set_Default_Title_Style (S : Part_Style_Array) is
   begin
      Default_Title_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Title_Style;

   procedure Set_Default_Message_Style (S : Part_Style_Array) is
   begin
      Default_Message_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Message_Style;

   procedure Set_Default_Button_Row_Style (S : Part_Style_Array) is
   begin
      Default_Button_Row_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Button_Row_Style;

   procedure Set_Default_Button_Style (S : Part_Style_Array) is
   begin
      Default_Button_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Button_Style;

   procedure Set_Default_Primary_Button_Style (S : Part_Style_Array) is
   begin
      Default_Primary_Button_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Primary_Button_Style;

   procedure Set_Default_Content_Style (S : Part_Style_Array) is
   begin
      Default_Content_Styles := Part_Style_Holders.To_Holder (S);
   end Set_Default_Content_Style;

   ---------------------------------------------------------------------------
   --  Build_Items: backdrop panel
   ---------------------------------------------------------------------------

   overriding procedure Build_Items (W : in out Dialog_Widget) is
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
      end if;

      --  Update backdrop to full widget geometry (= window size)
      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      --  Layout content panel within our bounds
      if W.Content_Panel /= null and then W.Host_Window /= null then
         declare
            Win_Size : constant Size_2D := Adi.Window.Get_Size (W.Host_Window.all);
            Pref     : Size_2D;
            Needed_H : Pixel_Type;
            Panel_Style : constant Resolved_Style :=
              Get_Resolved_Part_Style (W.Content_Panel.all, Main_Part);
            Pad      : constant Edge_Pixels := Get_Padding_Px (Panel_Style);
            Border   : constant Edge_Pixels := Get_Border_Width_Px (Panel_Style);
            Margin   : constant Edge_Pixels := Get_Margin_Px (Panel_Style);
            Viewport : constant Rectangle :=
              (Margin.Left, Margin.Top,
               Win_Size.Width  - Margin.Left - Margin.Right,
               Win_Size.Height - Margin.Top  - Margin.Bottom);
            Min_W    : Pixel_Type := 0.0;
            Max_W    : Pixel_Type := Viewport.Width;
            Min_H    : Pixel_Type := 0.0;
            Max_H    : Pixel_Type := Viewport.Height;
         begin
            --  Resize dialog to current window
            Set_Geometry (W, (0.0, 0.0, Win_Size.Width, Win_Size.Height));
            W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

            --  Resolve min/max width from panel style
            case Panel_Style.Min_Width.Kind is
               when Fixed =>
                  Min_W := Size_To_Px (Panel_Style.Min_Width, Win_Size.Width);
               when others => null;
            end case;
            case Panel_Style.Max_Width.Kind is
               when Fixed =>
                  Max_W := Pixel_Type'Min
                    (Max_W, Size_To_Px (Panel_Style.Max_Width, Win_Size.Width));
               when others => null;
            end case;

            --  Resolve min/max height from panel style
            case Panel_Style.Min_Height.Kind is
               when Fixed =>
                  Min_H := Size_To_Px (Panel_Style.Min_Height, Win_Size.Height);
               when others => null;
            end case;
            case Panel_Style.Max_Height.Kind is
               when Fixed =>
                  Max_H := Pixel_Type'Min
                    (Max_H, Size_To_Px (Panel_Style.Max_Height, Win_Size.Height));
               when others => null;
            end case;

            --  Measure content preferred size
            Rebuild_All_Items (W.Content_Panel.all);
            Pref := Get_Preferred_Size (W.Content_Panel.all);

            --  First pass: place with full available height so wrapped
            --  message text can settle before final height is computed.
            Set_Geometry
              (W.Content_Panel.all,
               Clamp_And_Center
                 (Container => Viewport,
                  Preferred => (Pref.Width, Max_H),
                  Min_Size  => (Min_W, Min_H),
                  Max_Size  => (Max_W, Max_H)));
            Layout_Tree (W.Content_Panel.all);
            Rebuild_All_Items (W.Content_Panel.all);

            --  Recompute needed panel height from actual laid out child
            --  geometry (important for wrapped message labels).
            Needed_H := Pad.Top + Border.Top + Pad.Bottom + Border.Bottom;
            for I in 1 .. Child_Count (W.Content_Panel.all) loop
               declare
                  Child : constant Widget_Access := Get_Child (W.Content_Panel.all, I);
               begin
                  if Child /= null then
                     declare
                        G : constant Rectangle := Get_Geometry (Child.all);
                    begin
                        Needed_H := Pixel_Type'Max
                          (Needed_H,
                           (G.Y + G.Height) - Get_Geometry (W.Content_Panel.all).Y
                           + Pad.Bottom + Border.Bottom);
                     end;
                  end if;
               end;
            end loop;

            Set_Geometry
              (W.Content_Panel.all,
               Clamp_And_Center
                 (Container => Viewport,
                  Preferred => (Pref.Width, Needed_H),
                  Min_Size  => (Min_W, Min_H),
                  Max_Size  => (Max_W, Max_H)));
            Layout_Tree (W.Content_Panel.all);
            Rebuild_All_Items (W.Content_Panel.all);
         end;
      end if;

      --  Apply deferred auto-focus now that the overlay tree is laid out
      if W.Pending_Focus then
         W.Pending_Focus := False;
         if W.Host_Window /= null
           and then W.Default_Button_Index > 0
           and then W.Default_Button_Index <= Natural (W.Buttons.Length)
         then
            Adi.Window.Set_Focus
              (W.Host_Window.all,
               W.Buttons.Element (W.Default_Button_Index).Widget);
         end if;
      end if;
   end Build_Items;

   ---------------------------------------------------------------------------
   --  Layout: no-op (handled in Build_Items since overlays bypass Layout_Tree)
   ---------------------------------------------------------------------------

   overriding procedure Layout (W : in out Dialog_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   ---------------------------------------------------------------------------
   --  On_Mouse_Down: dismiss on backdrop click
   ---------------------------------------------------------------------------

   overriding procedure On_Mouse_Down
     (W      : in out Dialog_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (Clicks);
   begin
      if Button /= Left_Button or else not W.Dismiss_On_Backdrop_Flag then
         return;
      end if;

      --  Check if click is outside the content panel
      if W.Content_Panel /= null then
         declare
            Panel_G : constant Rectangle := Get_Geometry (W.Content_Panel.all);
         begin
            if X < Panel_G.X or else X > Panel_G.X + Panel_G.Width
              or else Y < Panel_G.Y or else Y > Panel_G.Y + Panel_G.Height
            then
               Fire_Dismiss (W);
            end if;
         end;
      end if;
   end On_Mouse_Down;

   ---------------------------------------------------------------------------
   --  On_Key_Down: dismiss on Escape
   ---------------------------------------------------------------------------

   overriding procedure On_Key_Down
     (W        : in out Dialog_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean)
   is
      pragma Unreferenced (Key_Mod, Repeat);
   begin
      if Scancode = SDL_SCANCODE_ESCAPE and then W.Dismiss_On_Escape_Flag then
         Fire_Dismiss (W);
      end if;
   end On_Key_Down;

end Adi.Widget.Dialog;
