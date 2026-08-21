pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Text_IO;             use Ada.Text_IO;
with Adi.Core;                use Adi.Core;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.SDL;                 use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Combo_Box;
with Adi.Widget.Context_Menu;
with Adi.Widget.Dialog;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Adi.Window;
with Test_Support;            use Test_Support;

--  A widget that outlives the teardown of the reference the window held
--  to it must not keep the hover or pressed highlight that reference
--  stood for: the window has forgotten it, so no later event can take
--  the highlight away.
procedure Hover_Teardown_Test is

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Combo_Box.Combo_Box_Handle;

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok     : Adi.SDL.C_bool;
      Ttf_Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok    := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init should succeed with dummy driver");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready  := Boolean (Ttf_Ok);
         Assert (Ready, "TTF_Init should succeed");
      end if;
   end Ensure_SDL_Initialized;

   type Point is record
      X, Y : Pixel_Type;
   end record;

   function Centre (Target : Widget_Handle) return Point is
      G : constant Rectangle := Adi.Window.Geometry_In_Window (Target);
   begin
      return (X => G.X + G.Width / 2.0, Y => G.Y + G.Height / 2.0);
   end Centre;

   procedure Hover_Centre
     (Win    : Adi.Window.Window_Handle;
      Target : Widget_Handle)
   is
      P : constant Point := Centre (Target);
   begin
      Adi.Window.On_Mouse_Move (Win, P.X, P.Y);
   end Hover_Centre;

   --  Which widget a press lands on is the hit test's business, so ask
   --  the subtree rather than naming a widget the test does not own.
   function Any_In_Subtree_Has
     (Root : Widget_Handle;
      S    : Widget_State) return Boolean is
   begin
      if not Adi.Widget.Is_Valid (Root) then
         return False;
      end if;
      if Has_State (Root, S) then
         return True;
      end if;
      for I in 1 .. Child_Count (Root) loop
         if Any_In_Subtree_Has (Get_Child_Handle (Root, I), S) then
            return True;
         end if;
      end loop;
      return False;
   end Any_In_Subtree_Has;

   Panel_Rules : constant Style_Rules :=
     (Display        => Set (Flex),
      Flex_Direction => Set (Adi.CSS_Styles.Column),
      Height         => Set (Size (Px (80.0))),
      Min_Height     => Set (Size (Px (80.0))),
      others         => <>);
   Leaf_Rules : constant Style_Rules :=
     (Height     => Set (Size (Px (40.0))),
      Min_Height => Set (Size (Px (40.0))),
      others     => <>);

   --  A dialog carries no styling of its own; without one the content
   --  panel stacks its children as blocks and pushes the button row past
   --  the window edge, out of the pointer's reach.
   Content_Panel_Rules : constant Style_Rules :=
     (Display        => Set (Flex),
      Flex_Direction => Set (Adi.CSS_Styles.Column),
      others         => <>);

   ---------------------------------------------------------------------------
   --  Dialog: an overlay shown, hovered, hidden and shown again
   ---------------------------------------------------------------------------

   procedure Test_Dialog_Overlay is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      D     : Adi.Widget.Dialog.Dialog_Handle;
      Btn   : Widget_Handle;
      P     : Point;
   begin
      Section ("dialog overlay");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Win := Adi.Window.Create_Window_Handle ("Hover Dialog", (320.0, 240.0));
      D   := Adi.Widget.Dialog.Create_Handle;
      Adi.Widget.Dialog.Attach_Window (D, Win);
      Set_Part_Style (+Adi.Widget.Dialog.Get_Content_Panel_Handle (D),
                      Main_Part, From (Content_Panel_Rules).Build);
      Adi.Widget.Dialog.Add_Button (D, "OK");
      Adi.Widget.Dialog.Set_Auto_Close (D, False);

      Adi.Widget.Dialog.Show (D);
      Adi.Window.Render (Win);

      Btn := Adi.Widget.Button."+" (Adi.Widget.Dialog.Get_Button_Handle (D, 1));
      Assert (Adi.Widget.Is_Valid (Btn), "the dialog has a button to probe");

      Hover_Centre (Win, Btn);
      Assert (Has_State (Btn, State_Hovered),
              "the dialog button is hovered while the pointer is over it");

      Adi.Widget.Dialog.Hide (D);
      Assert (not Has_State (Btn, State_Hovered),
              "the dialog button drops its hover when the dialog is hidden");
      Assert (not Has_State (Adi.Widget.Dialog.To_Widget_Handle (D),
                             State_Hovered),
              "the dialog root drops its hover when the dialog is hidden");

      --  The same dialog object, shown again: nothing is hovered until
      --  the pointer says so.
      Adi.Widget.Dialog.Show (D);
      Adi.Window.Render (Win);
      Assert (not Has_State (Btn, State_Hovered),
              "a re-shown dialog does not open with a stuck highlight");

      --  Pressed is the same story, and it is torn down in two parts.
      Hover_Centre (Win, Btn);
      P := Centre (Btn);
      Adi.Window.On_Mouse_Down (Win, P.X, P.Y, Adi.Core.Left_Button);
      Assert (Has_State (Btn, State_Pressed),
              "the dialog button is pressed while the button is held");

      Adi.Widget.Dialog.Hide (D);
      Assert (not Has_State (Btn, State_Pressed),
              "the dialog button drops its pressed state when the dialog"
              & " is hidden mid-press");

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Dialog_Overlay;

   ---------------------------------------------------------------------------
   --  Combo box dropdown: the same overlay path, no dialog involved
   ---------------------------------------------------------------------------

   procedure Test_Combo_Box_Dropdown is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Combo : constant Adi.Widget.Combo_Box.Combo_Box_Handle :=
        Adi.Widget.Combo_Box.Create_Handle;
      Popup : Widget_Handle;
      P     : Point;
   begin
      Section ("combo box dropdown");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Panel_Rules).Build);
      Adi.Widget.Combo_Box.Add_Item (Combo, "One");
      Adi.Widget.Combo_Box.Add_Item (Combo, "Two");
      Add_Child (+Root, +Combo);

      Win := Adi.Window.Create_Window_Handle ("Hover Combo", (300.0, 250.0));
      Adi.Window.Set_Root (Win, +Root);
      Adi.Window.Render (Win);

      Adi.Widget.Combo_Box.Open_Dropdown (Combo);
      Adi.Window.Render (Win);

      --  The popup goes on above the dismiss layer, so it is the last
      --  overlay.
      Popup := Adi.Window.Get_Overlay_Handle
        (Win, Adi.Window.Overlay_Count (Win));
      Assert (Adi.Widget.Is_Valid (Popup), "the open dropdown has a popup");

      --  An overlay is a standalone root: that is what lets hover
      --  teardown clear the whole chain instead of handing it to a
      --  surviving parent.
      Assert (not Adi.Widget.Is_Valid (Get_Parent_Handle (Popup)),
              "the dropdown popup is a standalone root");

      Hover_Centre (Win, Popup);
      Assert (Has_State (Popup, State_Hovered),
              "the dropdown popup is hovered while the pointer is over it");

      Adi.Widget.Combo_Box.Close_Dropdown (Combo);
      Assert (not Has_State (Popup, State_Hovered),
              "the dropdown popup drops its hover when the dropdown closes");

      --  Picking a row closes the dropdown from inside the press
      --  dispatch, so the overlay goes away before the release arrives.
      Adi.Widget.Combo_Box.Open_Dropdown (Combo);
      Adi.Window.Render (Win);
      Popup := Adi.Window.Get_Overlay_Handle
        (Win, Adi.Window.Overlay_Count (Win));

      Hover_Centre (Win, Popup);
      P := Centre (Popup);
      Adi.Window.On_Mouse_Down (Win, P.X, P.Y, Adi.Core.Left_Button);
      Assert (Adi.Window.Overlay_Count (Win) = 0,
              "picking a row closes the dropdown");
      Assert (not Any_In_Subtree_Has (Popup, State_Pressed),
              "the dropdown drops its pressed state when the press that"
              & " closed it returns");
      Assert (not Has_State (Popup, State_Hovered),
              "the dropdown drops its hover when the press that closed it"
              & " returns");

      Adi.Window.On_Mouse_Up (Win, P.X, P.Y, Adi.Core.Left_Button);
      Assert (not Any_In_Subtree_Has (Popup, State_Pressed),
              "the release after the dropdown closed leaves it unpressed");

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Combo_Box_Dropdown;

   ---------------------------------------------------------------------------
   --  Context menu: a popup plus a dismiss layer, both removed on Hide
   ---------------------------------------------------------------------------

   procedure Test_Context_Menu is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Menu  : Adi.Widget.Context_Menu.Menu_Handle;
      Popup : Widget_Handle;
   begin
      Section ("context menu");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Panel_Rules).Build);

      Win := Adi.Window.Create_Window_Handle ("Hover Menu", (300.0, 250.0));
      Adi.Window.Set_Root (Win, +Root);
      Adi.Window.Render (Win);

      Menu := Adi.Widget.Context_Menu.Create_Handle;
      Adi.Widget.Context_Menu.Attach_Window (Menu, Win);
      Adi.Widget.Context_Menu.Add_Item (Menu, "Cut");
      Adi.Widget.Context_Menu.Add_Item (Menu, "Copy");

      Adi.Widget.Context_Menu.Show_At (Menu, 20.0, 20.0);
      Adi.Window.Render (Win);

      Popup := Adi.Window.Get_Overlay_Handle
        (Win, Adi.Window.Overlay_Count (Win));
      Assert (Adi.Widget.Is_Valid (Popup), "the open menu has a popup");

      Hover_Centre (Win, Popup);
      Assert (Has_State (Popup, State_Hovered),
              "the menu popup is hovered while the pointer is over it");

      Adi.Widget.Context_Menu.Hide (Menu);
      Assert (not Has_State (Popup, State_Hovered),
              "the menu popup drops its hover when the menu is hidden");

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Context_Menu;

   ---------------------------------------------------------------------------
   --  Clear_Overlays: the wholesale form of Remove_Overlay
   ---------------------------------------------------------------------------

   procedure Test_Clear_Overlays is
      Ready   : Boolean := False;
      Win     : Adi.Window.Window_Handle;
      Root    : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Overlay : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Overlay");
      OH      : Widget_Handle;
      P       : Point;
   begin
      Section ("Clear_Overlays");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Panel_Rules).Build);

      Win := Adi.Window.Create_Window_Handle
        ("Clear Overlays", (300.0, 250.0));
      Adi.Window.Set_Root (Win, +Root);

      OH := +Overlay;
      Set_Geometry (OH, (40.0, 40.0, 120.0, 30.0));
      Adi.Window.Add_Overlay (Win, OH);
      Adi.Window.Render (Win);

      Hover_Centre (Win, OH);
      Assert (Has_State (OH, State_Hovered),
              "the overlay is hovered while the pointer is over it");

      P := Centre (OH);
      Adi.Window.On_Mouse_Down (Win, P.X, P.Y, Adi.Core.Left_Button);
      Assert (Has_State (OH, State_Pressed),
              "the overlay is pressed while the button is held");

      Adi.Window.Clear_Overlays (Win);
      Assert (not Has_State (OH, State_Hovered),
              "the overlay drops its hover when the overlays are cleared");
      Assert (not Has_State (OH, State_Pressed),
              "the overlay drops its pressed state when the overlays are"
              & " cleared mid-press");

      Adi.Window.Destroy (Win);
      Adi.Widget.Destroy (OH);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Clear_Overlays;

   ---------------------------------------------------------------------------
   --  Clear_Widget_Refs_In_Subtree, the public entry point: the subtree
   --  loses its hover, the ancestors the pointer is still over keep
   --  theirs -- and can still lose it when the pointer leaves.
   ---------------------------------------------------------------------------

   procedure Test_Subtree_Refs_Cleared is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Panel : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Leaf  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Other : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Btn   : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Press");
      P     : Point;
   begin
      Section ("Clear_Widget_Refs_In_Subtree");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Panel_Rules).Build);
      Set_Part_Style (+Panel, Main_Part, From (Panel_Rules).Build);
      Set_Part_Style (+Leaf, Main_Part, From (Leaf_Rules).Build);
      Set_Part_Style (+Other, Main_Part, From (Panel_Rules).Build);

      Add_Child (+Panel, +Leaf);
      Add_Child (+Root, +Panel);
      Add_Child (+Other, +Btn);
      Add_Child (+Root, +Other);

      Win := Adi.Window.Create_Window_Handle ("Subtree Refs", (300.0, 250.0));
      Adi.Window.Set_Root (Win, +Root);
      Adi.Window.Render (Win);

      Hover_Centre (Win, +Leaf);
      Assert (Has_State (+Leaf, State_Hovered), "the leaf is hovered");
      Assert (Has_State (+Panel, State_Hovered),
              "the leaf's parent is hovered with it");

      declare
         R : constant Adi.Window.Window_Ref := Adi.Window.Borrow (Win);
      begin
         Adi.Window.Clear_Widget_Refs_In_Subtree (R.Ptr.all, +Leaf);
      end;

      Assert (not Has_State (+Leaf, State_Hovered),
              "the cleared subtree drops its hover");
      Assert (Has_State (+Panel, State_Hovered),
              "an ancestor outside the cleared subtree keeps the hover the"
              & " pointer still gives it");

      --  And that ancestor is still the window's hovered widget, so it
      --  un-hovers when the pointer moves off it.
      P := Centre (+Other);
      Adi.Window.On_Mouse_Move (Win, P.X, P.Y);
      Assert (not Has_State (+Panel, State_Hovered),
              "the ancestor un-hovers once the pointer leaves it");
      Assert (Has_State (+Other, State_Hovered),
              "the widget the pointer moved to is hovered");

      --  Pressed goes the same way, on a widget that survives the clear.
      Hover_Centre (Win, +Btn);
      P := Centre (+Btn);
      Adi.Window.On_Mouse_Down (Win, P.X, P.Y, Adi.Core.Left_Button);
      Assert (Has_State (+Btn, State_Pressed),
              "the button is pressed while the button is held");

      declare
         R : constant Adi.Window.Window_Ref := Adi.Window.Borrow (Win);
      begin
         Adi.Window.Clear_Widget_Refs_In_Subtree
           (R.Ptr.all, +Btn);
      end;

      Assert (not Has_State (+Btn, State_Pressed),
              "a surviving widget drops its pressed state with the reference");
      Assert (Has_State (+Other, State_Hovered),
              "the button's parent takes over the hover");

      --  The release that follows must not revive what was let go.
      Adi.Window.On_Mouse_Up (Win, P.X, P.Y, Adi.Core.Left_Button);
      Assert (not Has_State (+Btn, State_Pressed),
              "the release leaves the button unpressed");

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Subtree_Refs_Cleared;

   ---------------------------------------------------------------------------
   --  Same shape, reached the way applications reach it: destroying a
   --  hovered widget.
   ---------------------------------------------------------------------------

   procedure Test_Destroy_Hovered_Widget is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Panel : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Leaf  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Other : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Doomed : Widget_Handle;
      P      : Point;
   begin
      Section ("destroying a hovered widget");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Panel_Rules).Build);
      Set_Part_Style (+Panel, Main_Part, From (Panel_Rules).Build);
      Set_Part_Style (+Leaf, Main_Part, From (Leaf_Rules).Build);
      Set_Part_Style (+Other, Main_Part, From (Panel_Rules).Build);

      Add_Child (+Panel, +Leaf);
      Add_Child (+Root, +Panel);
      Add_Child (+Root, +Other);

      Win := Adi.Window.Create_Window_Handle ("Destroy Hovered", (300.0, 250.0));
      Adi.Window.Set_Root (Win, +Root);
      Adi.Window.Render (Win);

      Hover_Centre (Win, +Leaf);
      Assert (Has_State (+Leaf, State_Hovered), "the leaf is hovered");

      Doomed := +Leaf;
      Adi.Widget.Destroy (Doomed);
      Adi.Widget.Pump_Widget_Store;

      Assert (Has_State (+Panel, State_Hovered),
              "the surviving parent keeps the hover the pointer still"
              & " gives it");

      P := Centre (+Other);
      Adi.Window.On_Mouse_Move (Win, P.X, P.Y);
      Assert (not Has_State (+Panel, State_Hovered),
              "the surviving parent un-hovers once the pointer leaves it");

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Destroy_Hovered_Widget;

begin
   Start_Suite ("Hover / Pressed Teardown Tests");

   Test_Dialog_Overlay;
   Test_Combo_Box_Dropdown;
   Test_Context_Menu;
   Test_Clear_Overlays;
   Test_Subtree_Refs_Cleared;
   Test_Destroy_Hovered_Widget;

   Finish;
end Hover_Teardown_Test;
