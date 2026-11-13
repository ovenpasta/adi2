--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.SDL;                  use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;               use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Combo_Box;
with Adi.Widget.Context_Menu;
with Adi.Widget.Dialog;
with Adi.Window;               use Adi.Window;
with Test_Support;             use Test_Support;

--  A context menu, a combo box's dropdown and a dialog are open while
--  they are overlays of their window. Overlays the window drops by other
--  means (Clear_Overlays, Remove_Overlay) leave them closed, and they
--  open again.
procedure Overlay_Reopen_Test is

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Combo_Box.Combo_Box_Handle;

   Win  : Window_Handle;
   Root : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

   procedure Test_Context_Menu is
      package CM renames Adi.Widget.Context_Menu;
      Menu : CM.Menu_Handle := CM.Create_Handle;
   begin
      Section ("context menu");
      CM.Attach_Window (Menu, Win);
      CM.Add_Item (Menu, "Copy");

      CM.Show_At (Menu, 20.0, 20.0);
      Assert (CM.Is_Shown (Menu), "shown");
      Clear_Overlays (Win);
      Assert (not CM.Is_Shown (Menu), "closed once the overlays are cleared");
      CM.Show_At (Menu, 20.0, 20.0);
      Assert (CM.Is_Shown (Menu), "and shows again");

      --  Only the popup removed: hiding also takes away the layer that
      --  dismisses it, which would otherwise swallow every click
      Remove_Overlay (Win, Get_Overlay_Handle (Win, Overlay_Count (Win)));
      Assert (not CM.Is_Shown (Menu), "closed once its popup is removed");
      CM.Hide (Menu);
      Assert (Overlay_Count (Win) = 0, "hiding leaves no overlay behind");

      CM.Show_At (Menu, 20.0, 20.0);
      CM.Hide (Menu);
      Assert (not CM.Is_Shown (Menu) and then Overlay_Count (Win) = 0,
              "shown and hidden as usual");
      CM.Destroy (Menu);
   end Test_Context_Menu;

   procedure Test_Combo_Box is
      package CB renames Adi.Widget.Combo_Box;
      Combo : constant CB.Combo_Box_Handle := CB.Create_Handle;
   begin
      Section ("combo box");
      CB.Add_Item (Combo, "One");
      CB.Add_Item (Combo, "Two");
      Add_Child (+Root, +Combo);
      Render (Win);

      CB.Open_Dropdown (Combo);
      Assert (CB.Is_Open (Combo), "open");
      Clear_Overlays (Win);
      Assert (not CB.Is_Open (Combo), "closed once the overlays are cleared");
      CB.Open_Dropdown (Combo);
      Assert (CB.Is_Open (Combo), "and opens again");
      CB.Close_Dropdown (Combo);
      Assert (not CB.Is_Open (Combo) and then Overlay_Count (Win) = 0,
              "closed as usual");
   end Test_Combo_Box;

   procedure Test_Dialog is
      package DL renames Adi.Widget.Dialog;
      D : constant DL.Dialog_Handle := DL.Create_Handle;
   begin
      Section ("dialog");
      DL.Attach_Window (D, Win);
      DL.Add_Button (D, "OK");

      DL.Show (D);
      Assert (DL.Is_Shown (D), "shown");
      Clear_Overlays (Win);
      Assert (not DL.Is_Shown (D), "hidden once the overlays are cleared");
      DL.Show (D);
      Assert (DL.Is_Shown (D), "and shows again");
      DL.Hide (D);
      Assert (not DL.Is_Shown (D) and then Overlay_Count (Win) = 0,
              "hidden as usual");
   end Test_Dialog;

begin
   Start_Suite ("Overlay Reopen Test");

   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   if not Boolean (SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS))
     or else not Boolean (Adi.SDL.TTF.TTF_Init)
   then
      Assert (False, "SDL and SDL_ttf initialise");
      Finish;
      return;
   end if;

   Win := Create_Window_Handle ("Overlays", (320.0, 240.0));
   Set_Root (Win, +Root);
   Render (Win);

   Test_Context_Menu;
   Test_Combo_Box;
   Test_Dialog;

   Destroy (Win);
   Finish;
end Overlay_Reopen_Test;
