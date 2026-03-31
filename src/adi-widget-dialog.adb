with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.Events;        use Adi.SDL.Events;
with Adi.Widget.Button;     use Adi.Widget.Button;

package body Adi.Widget.Dialog is

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

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
      Btn   : Widget_Handle := Null_Handle;
      Owner : Widget_Handle := Null_Handle;
   end record;

   package Binding_Vectors is new Ada.Containers.Vectors (Positive, Dialog_Binding);

   Dialog_Bindings : Binding_Vectors.Vector;

   function Find_Owner_Handle
     (Btn : Widget_Handle) return Widget_Handle
   is
   begin
      for I in 1 .. Natural (Dialog_Bindings.Length) loop
         if Dialog_Bindings.Element (I).Btn = Btn then
            return Dialog_Bindings.Element (I).Owner;
         end if;
      end loop;
      return Null_Handle;
   end Find_Owner_Handle;

   procedure Register_Button_Binding
     (Btn   : Widget_Handle;
      Owner : Widget_Handle)
   is
   begin
      Dialog_Bindings.Append
        (Dialog_Binding'(Btn => Btn, Owner => Owner));
   end Register_Button_Binding;

   procedure Unregister_Bindings (Owner : Widget_Handle) is
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
      Btn : Widget_Handle) return Natural
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
            Owner_H : constant Widget_Handle :=
              Find_Owner_Handle (Get_Handle (W));
            Owner   : constant Widget_Access := Resolve_Handle (Owner_H);
         begin
            if Owner /= null then
               On_Key_Down (Owner.all, Scancode, Key_Mod, Repeat);
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
            BH : constant Widget_Handle := W.Buttons.Element (I).Widget;
         begin
            if BH /= Null_Handle then
               if I = W.Default_Button_Index then
                  Set_Part_Styles (BH, Primary_Styles);
               else
                  Set_Part_Styles (BH, Normal_Styles);
               end if;
            end if;
         end;
      end loop;
   end Apply_Button_Styles;

   ---------------------------------------------------------------------------
   --  On_Button_Clicked: shared click handler for dialog buttons
   ---------------------------------------------------------------------------

   procedure On_Button_Clicked (W : Widget_Handle) is
      Owner_H : Widget_Handle := Null_Handle;
      Index   : Natural;
      Text    : Unbounded_String;
   begin
      for I in 1 .. Natural (Dialog_Bindings.Length) loop
         if Dialog_Bindings.Element (I).Btn = W then
            Owner_H := Dialog_Bindings.Element (I).Owner;
            exit;
         end if;
      end loop;
      if Owner_H = Null_Handle then
         return;
      end if;

      declare
         Owner : constant Widget_Access := Resolve_Handle (Owner_H);
      begin
         if Owner = null then
            return;
         end if;

         Index := Find_Button_Index (Dialog_Widget (Owner.all), W);
         if Index > 0 then
            Text := Dialog_Widget (Owner.all).Buttons.Element (Index).Text;
         end if;

         declare
            Idx : constant Natural := Index;
            Txt : constant String := To_String (Text);
            procedure Call (CB : Dialog_Result_Callback) is
            begin CB (Owner_H, Idx, Txt); end Call;
            procedure Emit is new Result_Signals.For_Each (Call);
         begin
            Emit (Dialog_Widget (Owner.all).Result);
         end;
         if Dialog_Widget (Owner.all).Auto_Close_Flag then
            Hide (Dialog_Widget (Owner.all));
         end if;
      end;
   end On_Button_Clicked;

   ---------------------------------------------------------------------------
   --  Fire_Dismiss: report a dismiss (backdrop/escape) result
   ---------------------------------------------------------------------------

   procedure Fire_Dismiss (W : in out Dialog_Widget) is
      H : constant Widget_Handle := Get_Handle (W);
      procedure Call (CB : Dialog_Result_Callback) is
      begin CB (H, 0, ""); end Call;
      procedure Emit is new Result_Signals.For_Each (Call);
   begin
      if not W.Shown then
         return;  --  Already dismissed (guard against double-dispatch)
      end if;
      Emit (W.Result);
      Hide (W);
   end Fire_Dismiss;

   ---------------------------------------------------------------------------
   --  Create
   ---------------------------------------------------------------------------

   function Create_Handle return Dialog_Handle is
      Result : constant Dialog_Widget_Access := new Dialog_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Register_Widget (Widget_Access (Result));

      --  Content panel: flex column
      Result.Content_Panel := Adi.Widget.Box.Create_Handle;

      --  Title label
      Result.Title_Label := Adi.Widget.Label.Create_Handle ("");
      Add_Child (+Result.Content_Panel, +Result.Title_Label);

      --  Message label
      Result.Message_Label := Adi.Widget.Label.Create_Handle ("");
      Add_Child (+Result.Content_Panel, +Result.Message_Label);

      --  Button row: flex row
      Result.Button_Row := Adi.Widget.Box.Create_Handle;
      Add_Child (+Result.Content_Panel, +Result.Button_Row);

      --  Content panel must be part of the dialog tree so overlay rendering
      --  traverses and draws title/message/buttons above the backdrop.
      Add_Child (Get_Handle (Result.all), +Result.Content_Panel);

      --  Apply package-level default styles if set
      if not Default_Panel_Styles.Is_Empty then
         Set_Part_Styles (+Result.Content_Panel, Default_Panel_Styles.Element);
      end if;
      if not Default_Title_Styles.Is_Empty then
         Set_Part_Styles (+Result.Title_Label, Default_Title_Styles.Element);
      end if;
      if not Default_Message_Styles.Is_Empty then
         Set_Part_Styles (+Result.Message_Label, Default_Message_Styles.Element);
      end if;
      if not Default_Button_Row_Styles.Is_Empty then
         Set_Part_Styles (+Result.Button_Row, Default_Button_Row_Styles.Element);
      end if;
      if not Default_Button_Styles.Is_Empty then
         Result.Button_Styles := Default_Button_Styles.Element;
         Result.Has_Button_Styles := True;
      end if;

      return (Id => Get_Handle (Result.all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Dialog_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Dialog (H : Widget_Handle) return Dialog_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Dialog_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Dialog_Handle;
   end Try_As_Dialog;

   function Is_Valid (H : Dialog_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Dialog_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Dialog_Handle; Styles : Part_Style_Array)
   is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   ---------------------------------------------------------------------------
   --  Attach_Window
   ---------------------------------------------------------------------------

   ---------------------------------------------------------------------------
   --  Content setters
   ---------------------------------------------------------------------------

   procedure Set_Title (W : in out Dialog_Widget; Text : String) is
   begin
      if Adi.Widget.Label.Is_Valid (W.Title_Label) then
         Adi.Widget.Label.Set_Text (W.Title_Label, Text);
      end if;
      Mark_Dirty (W);
   end Set_Title;

   procedure Set_Message (W : in out Dialog_Widget; Text : String) is
   begin
      if W.Custom_Content /= Null_Handle then
         return;  --  Message label not in tree when custom content is set
      end if;
      if Adi.Widget.Label.Is_Valid (W.Message_Label) then
         Adi.Widget.Label.Set_Text (W.Message_Label, Text);
      end if;
      Mark_Dirty (W);
   end Set_Message;

   ---------------------------------------------------------------------------
   --  Icon
   ---------------------------------------------------------------------------

   procedure Set_Icon (W : in out Dialog_Widget; Icon : Image_Access) is
   begin
      if W.Custom_Content /= Null_Handle then
         return;  --  Message label not in tree when custom content is set
      end if;
      if Adi.Widget.Label.Is_Valid (W.Message_Label) then
         Adi.Widget.Label.Set_Icon (W.Message_Label, Icon);
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
      Had_Custom : constant Boolean :=
        W.Custom_Content /= Null_Handle;
   begin
      --  Remove previous custom content if any
      if W.Custom_Content /= Null_Handle then
         Remove_Child (+W.Content_Panel, W.Custom_Content);
         W.Custom_Content := Null_Handle;
      end if;

      if Content /= null then
         --  Remove message label from tree only if it is currently attached
         --  (i.e. we were not already in custom-content mode).
         if not Had_Custom
           and then Adi.Widget.Label.Is_Valid (W.Message_Label)
         then
            Remove_Child (+W.Content_Panel, +W.Message_Label);
         end if;
         --  Remove button row so we can re-add after content
         Remove_Child (+W.Content_Panel, +W.Button_Row);

         --  Detach from any existing parent before adopting
         declare
            Content_H : constant Widget_Handle := Get_Handle (Content.all);
            Parent_H  : constant Widget_Handle := Get_Parent_Handle (Content.all);
         begin
            if Parent_H /= Null_Handle then
               Remove_Child (Parent_H, Content_H);
            end if;

            W.Custom_Content := Content_H;
            if not Default_Content_Styles.Is_Empty then
               Set_Part_Styles (W.Custom_Content, Default_Content_Styles.Element);
            end if;
            Add_Child (+W.Content_Panel, W.Custom_Content);
         end;
         Add_Child (+W.Content_Panel, +W.Button_Row);
      else
         --  Restore message label only if we were in custom-content mode
         if Had_Custom
           and then Adi.Widget.Label.Is_Valid (W.Message_Label)
         then
            Remove_Child (+W.Content_Panel, +W.Button_Row);
            Add_Child (+W.Content_Panel, +W.Message_Label);
            Add_Child (+W.Content_Panel, +W.Button_Row);
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
      Btn_H : Widget_Handle;
   begin
      Set_Flag (Btn.all, Visible, True);
      Set_Flag (Btn.all, Clickable, True);
      Set_Flag (Btn.all, Focusable, True);
      Adi.Widget.Label.Set_Text
        (Adi.Widget.Label.Label_Widget (Btn.all), Text);
      Connect_Clicked (Btn.all, On_Button_Clicked'Access);
      Register_Widget (Widget_Access (Btn));
      Btn_H := Get_Handle (Btn.all);

      Register_Button_Binding (Btn_H, Get_Handle (W));
      Add_Child (+W.Button_Row, Btn_H);
      W.Buttons.Append
        (Button_Info'(Text   => To_Unbounded_String (Text),
                      Widget => Btn_H));

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
      Unregister_Bindings (Get_Handle (W));
      --  Destroy button widgets (detaches from parent and frees store slot)
      for Info of W.Buttons loop
         if Info.Widget /= Null_Handle then
            declare
               H : Widget_Handle := Info.Widget;
            begin
               Destroy (H);
            end;
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

   function Get_Button_Handle
     (W : Dialog_Widget; Index : Positive)
      return Adi.Widget.Button.Button_Handle
   is
   begin
      if Index > Natural (W.Buttons.Length) then
         return Adi.Widget.Button.Null_Button_Handle;
      end if;
      return Adi.Widget.Button.Try_As_Button (W.Buttons.Element (Index).Widget);
   end Get_Button_Handle;

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
      if W.Shown or else not Adi.Window.Is_Valid (W.Host_Window) then
         return;
      end if;

      declare
         Win_Size : constant Size_2D := Adi.Window.Get_Size (W.Host_Window);
      begin
         Set_Geometry (W, (0.0, 0.0, Win_Size.Width, Win_Size.Height));
      end;

      Adi.Window.Add_Overlay (W.Host_Window, Get_Handle (W));
      W.Shown := True;

      --  Auto-focus the default button now that the overlay is in the
      --  window tree.  Set_Focus only checks focus candidacy (visible,
      --  participates, focusable, not disabled) — layout is not required.
      if W.Default_Button_Index > 0
        and then W.Default_Button_Index <= Natural (W.Buttons.Length)
      then
         Adi.Window.Set_Focus
           (W.Host_Window,
            W.Buttons.Element (W.Default_Button_Index).Widget);
      end if;

      Mark_Dirty (W);
   end Show;

   procedure Hide (W : in out Dialog_Widget) is
   begin
      if not W.Shown or else not Adi.Window.Is_Valid (W.Host_Window) then
         return;
      end if;

      Adi.Window.Remove_Overlay (W.Host_Window, Get_Handle (W));
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

   procedure Set_Auto_Close
     (W : in out Dialog_Widget; Value : Boolean := True)
   is
   begin
      W.Auto_Close_Flag := Value;
   end Set_Auto_Close;

   ---------------------------------------------------------------------------
   --  Result callback
   ---------------------------------------------------------------------------

   procedure Connect_Result
     (W : in out Dialog_Widget; CB : Dialog_Result_Callback)
   is
   begin
      W.Result.Connect (CB);
   end Connect_Result;

   function Connect_Result
     (W : in out Dialog_Widget; CB : Dialog_Result_Callback)
      return Result_Signals.Connection_Id
   is
   begin
      return W.Result.Connect (CB);
   end Connect_Result;

   procedure Disconnect_Result
     (W : in out Dialog_Widget; Id : Result_Signals.Connection_Id)
   is
   begin
      W.Result.Disconnect (Id);
   end Disconnect_Result;

   ---------------------------------------------------------------------------
   --  Style injection
   ---------------------------------------------------------------------------

   procedure Set_Panel_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if Adi.Widget.Box.Is_Valid (W.Content_Panel) then
         Set_Part_Styles (+W.Content_Panel, S);
      end if;
   end Set_Panel_Style;

   procedure Set_Title_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if Adi.Widget.Label.Is_Valid (W.Title_Label) then
         Set_Part_Styles (+W.Title_Label, S);
      end if;
   end Set_Title_Style;

   procedure Set_Message_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if Adi.Widget.Label.Is_Valid (W.Message_Label) then
         Set_Part_Styles (+W.Message_Label, S);
      end if;
   end Set_Message_Style;

   procedure Set_Button_Row_Style
     (W : in out Dialog_Widget; S : Part_Style_Array)
   is
   begin
      if Adi.Widget.Box.Is_Valid (W.Button_Row) then
         Set_Part_Styles (+W.Button_Row, S);
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
      if W.Custom_Content /= Null_Handle then
         Set_Part_Styles (W.Custom_Content, S);
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
      if Adi.Widget.Box.Is_Valid (W.Content_Panel)
        and then Adi.Window.Is_Valid (W.Host_Window)
      then
         declare
            CP       : constant Widget_Handle := +W.Content_Panel;
            Win_Size : constant Size_2D := Adi.Window.Get_Size (W.Host_Window);
            Pref     : Size_2D;
            Needed_H : Pixel_Type;
            Panel_Style : constant Resolved_Style :=
              Get_Resolved_Part_Style (CP, Main_Part);
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
            Rebuild_All_Items (CP);
            Pref := Get_Preferred_Size (CP);

            --  First pass: place with full available height so wrapped
            --  message text can settle before final height is computed.
            Set_Geometry
              (CP,
               Clamp_And_Center
                 (Container => Viewport,
                  Preferred => (Pref.Width, Max_H),
                  Min_Size  => (Min_W, Min_H),
                  Max_Size  => (Max_W, Max_H)));
            Layout_Tree (CP);
            Rebuild_All_Items (CP);

            --  Recompute needed panel height from actual laid out child
            --  geometry (important for wrapped message labels).
            Needed_H := Pad.Top + Border.Top + Pad.Bottom + Border.Bottom;
            for I in 1 .. Child_Count (CP) loop
               declare
                  CH : constant Widget_Handle := Get_Child_Handle (CP, I);
                  CG : constant Rectangle := Get_Geometry (CH);
               begin
                  Needed_H := Pixel_Type'Max
                    (Needed_H,
                     (CG.Y + CG.Height) - Get_Geometry (CP).Y
                     + Pad.Bottom + Border.Bottom);
               end;
            end loop;

            Set_Geometry
              (CP,
               Clamp_And_Center
                 (Container => Viewport,
                  Preferred => (Pref.Width, Needed_H),
                  Min_Size  => (Min_W, Min_H),
                  Max_Size  => (Max_W, Max_H)));
            Layout_Tree (CP);
            Rebuild_All_Items (CP);

            --  Third pass (safety net): re-measure from the now-valid child
            --  geometries.  On the very first Show, children may not have had
            --  valid sizes during the first measurement, so the second-pass
            --  height can still be wrong.  Re-check and re-layout only when
            --  the measured height actually changed.
            declare
               Prev_H : constant Pixel_Type := Needed_H;
            begin
               Needed_H := Pad.Top + Border.Top + Pad.Bottom + Border.Bottom;
               for I in 1 .. Child_Count (CP) loop
                  declare
                     CH : constant Widget_Handle := Get_Child_Handle (CP, I);
                     CG : constant Rectangle := Get_Geometry (CH);
                  begin
                     Needed_H := Pixel_Type'Max
                       (Needed_H,
                        (CG.Y + CG.Height) - Get_Geometry (CP).Y
                        + Pad.Bottom + Border.Bottom);
                  end;
               end loop;

               if abs (Needed_H - Prev_H) > 1.0 then
                  Set_Geometry
                    (CP,
                     Clamp_And_Center
                       (Container => Viewport,
                        Preferred => (Pref.Width, Needed_H),
                        Min_Size  => (Min_W, Min_H),
                        Max_Size  => (Max_W, Max_H)));
                  Layout_Tree (CP);
                  Rebuild_All_Items (CP);
               end if;
            end;
         end;
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
      if Adi.Widget.Box.Is_Valid (W.Content_Panel) then
         declare
            Panel_G : constant Rectangle := Get_Geometry (+W.Content_Panel);
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

   overriding procedure On_Destroy (W : in out Dialog_Widget) is
   begin
      Unregister_Bindings (Get_Handle (W));
   end On_Destroy;

   ---------------------------------------------------------------------------
   --  Handle methods
   ---------------------------------------------------------------------------

   procedure Attach_Window
     (H : Dialog_Handle; Host : Adi.Window.Window_Handle)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Dialog_Widget (Ptr.all).Host_Window := Host;
      end if;
   end Attach_Window;

   procedure Set_Title (H : Dialog_Handle; Text : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Title (Dialog_Widget (Ptr.all), Text);
      end if;
   end Set_Title;

   procedure Set_Message (H : Dialog_Handle; Text : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Message (Dialog_Widget (Ptr.all), Text);
      end if;
   end Set_Message;

   procedure Set_Content (H : Dialog_Handle; Content : Widget_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         if Content = Null_Handle then
            Set_Content (Dialog_Widget (Ptr.all), null);
         else
            Set_Content (Dialog_Widget (Ptr.all), Resolve_Handle (Content));
         end if;
      end if;
   end Set_Content;

   procedure Set_Icon (H : Dialog_Handle; Icon : Image_Access) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Icon (Dialog_Widget (Ptr.all), Icon);
      end if;
   end Set_Icon;

   function Add_Button (H : Dialog_Handle; Text : String) return Positive is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Add_Button (Dialog_Widget (Ptr.all), Text);
      end if;
      return 1;
   end Add_Button;

   procedure Add_Button (H : Dialog_Handle; Text : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Add_Button (Dialog_Widget (Ptr.all), Text);
      end if;
   end Add_Button;

   procedure Clear_Buttons (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Clear_Buttons (Dialog_Widget (Ptr.all));
      end if;
   end Clear_Buttons;

   procedure Set_Default_Button (H : Dialog_Handle; Index : Natural) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Default_Button (Dialog_Widget (Ptr.all), Index);
      end if;
   end Set_Default_Button;

   function Get_Button_Handle
     (H : Dialog_Handle; Index : Positive)
      return Adi.Widget.Button.Button_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Button_Handle (Dialog_Widget (Ptr.all), Index);
      end if;
      return Adi.Widget.Button.Null_Button_Handle;
   end Get_Button_Handle;

   function Get_Content_Panel_Handle
     (H : Dialog_Handle) return Adi.Widget.Box.Box_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Dialog_Widget (Ptr.all).Content_Panel;
      end if;
      return Adi.Widget.Box.Null_Box_Handle;
   end Get_Content_Panel_Handle;

   function Get_Title_Handle
     (H : Dialog_Handle) return Adi.Widget.Label.Label_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Dialog_Widget (Ptr.all).Title_Label;
      end if;
      return Adi.Widget.Label.Null_Label_Handle;
   end Get_Title_Handle;

   function Get_Message_Handle
     (H : Dialog_Handle) return Adi.Widget.Label.Label_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Dialog_Widget (Ptr.all).Message_Label;
      end if;
      return Adi.Widget.Label.Null_Label_Handle;
   end Get_Message_Handle;

   function Get_Button_Row_Handle
     (H : Dialog_Handle) return Adi.Widget.Box.Box_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Dialog_Widget (Ptr.all).Button_Row;
      end if;
      return Adi.Widget.Box.Null_Box_Handle;
   end Get_Button_Row_Handle;

   procedure Set_OK_Button (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_OK_Button (Dialog_Widget (Ptr.all));
      end if;
   end Set_OK_Button;

   procedure Set_OK_Cancel (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_OK_Cancel (Dialog_Widget (Ptr.all));
      end if;
   end Set_OK_Cancel;

   procedure Set_Yes_No (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Yes_No (Dialog_Widget (Ptr.all));
      end if;
   end Set_Yes_No;

   procedure Set_Yes_No_Cancel (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Yes_No_Cancel (Dialog_Widget (Ptr.all));
      end if;
   end Set_Yes_No_Cancel;

   procedure Show (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Show (Dialog_Widget (Ptr.all));
      end if;
   end Show;

   procedure Hide (H : Dialog_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Hide (Dialog_Widget (Ptr.all));
      end if;
   end Hide;

   function Is_Shown (H : Dialog_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Shown (Dialog_Widget (Ptr.all));
      end if;
      return False;
   end Is_Shown;

   procedure Set_Dismiss_On_Backdrop
     (H : Dialog_Handle; Value : Boolean := True)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Dismiss_On_Backdrop (Dialog_Widget (Ptr.all), Value);
      end if;
   end Set_Dismiss_On_Backdrop;

   procedure Set_Dismiss_On_Escape
     (H : Dialog_Handle; Value : Boolean := True)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Dismiss_On_Escape (Dialog_Widget (Ptr.all), Value);
      end if;
   end Set_Dismiss_On_Escape;

   procedure Set_Auto_Close
     (H : Dialog_Handle; Value : Boolean := True)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Auto_Close (Dialog_Widget (Ptr.all), Value);
      end if;
   end Set_Auto_Close;

   procedure Connect_Result
     (H : Dialog_Handle; CB : Dialog_Result_Callback)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Result (Dialog_Widget (Ptr.all), CB);
      end if;
   end Connect_Result;

   function Connect_Result
     (H : Dialog_Handle; CB : Dialog_Result_Callback)
      return Result_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Result (Dialog_Widget (Ptr.all), CB);
      end if;
      return Result_Signals.No_Connection;
   end Connect_Result;

   procedure Disconnect_Result
     (H : Dialog_Handle; Id : Result_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Result (Dialog_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Result;

   procedure Set_Panel_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Panel_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Panel_Style;

   procedure Set_Title_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Title_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Title_Style;

   procedure Set_Message_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Message_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Message_Style;

   procedure Set_Button_Row_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Button_Row_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Button_Row_Style;

   procedure Set_Button_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Button_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Button_Style;

   procedure Set_Primary_Button_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Primary_Button_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Primary_Button_Style;

   procedure Set_Content_Style
     (H : Dialog_Handle; S : Part_Style_Array)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Content_Style (Dialog_Widget (Ptr.all), S);
      end if;
   end Set_Content_Style;

end Adi.Widget.Dialog;
