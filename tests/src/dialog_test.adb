pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;          use Ada.Text_IO;
with Adi.Core;             use Adi.Core;
with Adi.SDL;              use Adi.SDL;
with Adi.SDL.Events;
with Adi.SDL.TTF;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Dialog;    use Adi.Widget.Dialog;
with Adi.Widget.Label;
with Adi.Window;           use Adi.Window;
with Test_Support;         use Test_Support;

procedure Dialog_Test is

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

   ---------------------------------------------------------------------------
   --  Shared result-tracking state
   ---------------------------------------------------------------------------

   Last_Button_Index : Natural  := 0;
   Last_Button_Text  : String (1 .. 64) := [others => ' '];
   Last_Button_Len   : Natural  := 0;
   Result_Call_Count : Natural  := 0;

   procedure On_Result
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W);
      Len : constant Natural :=
        Natural'Min (Button_Text'Length, Last_Button_Text'Last);
   begin
      Result_Call_Count := Result_Call_Count + 1;
      Last_Button_Index := Button_Index;
      Last_Button_Len   := Len;
      Last_Button_Text (1 .. Len) :=
        Button_Text (Button_Text'First .. Button_Text'First + Len - 1);
   end On_Result;

   procedure Reset_Result is
   begin
      Last_Button_Index := 0;
      Last_Button_Len   := 0;
      Result_Call_Count := 0;
   end Reset_Result;

   ---------------------------------------------------------------------------
   --  Test 1: default auto-close — button click hides dialog
   ---------------------------------------------------------------------------

   procedure Test_Auto_Close_Default is
      Win : Window_Handle;
      D   : Dialog_Handle;
      Btn : Widget_Handle;
      Ready : Boolean := False;
   begin
      Section ("Auto-close default (True)");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Win := Create_Window_Handle ("Dialog Test", (320.0, 240.0));
      D   := Create_Handle;
      Attach_Window (D, Win);
      Add_Button (D, "OK");
      Connect_Result (D, On_Result'Unrestricted_Access);
      Reset_Result;

      Show (D);
      Assert (Is_Shown (D), "dialog is shown after Show");

      Btn := Adi.Widget.Button."+" (Get_Button_Handle (D, 1));
      On_Click (Btn);

      Assert (Result_Call_Count = 1, "result callback fired once");
      Assert (Last_Button_Index = 1, "button index is 1");
      Assert (Last_Button_Text (1 .. Last_Button_Len) = "OK",
              "button text is OK");
      Assert (not Is_Shown (D), "dialog is hidden after button click (auto-close)");
   end Test_Auto_Close_Default;

   ---------------------------------------------------------------------------
   --  Test 2: auto-close disabled — dialog stays open after button click
   ---------------------------------------------------------------------------

   procedure Test_Auto_Close_False is
      Win : Window_Handle;
      D   : Dialog_Handle;
      Btn : Widget_Handle;
      Ready : Boolean := False;
   begin
      Section ("Auto-close False");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Win := Create_Window_Handle ("Dialog Test 2", (320.0, 240.0));
      D   := Create_Handle;
      Attach_Window (D, Win);
      Set_Auto_Close (D, False);
      Add_Button (D, "Submit");
      Connect_Result (D, On_Result'Unrestricted_Access);
      Reset_Result;

      Show (D);
      Assert (Is_Shown (D), "dialog is shown after Show");

      Btn := Adi.Widget.Button."+" (Get_Button_Handle (D, 1));
      On_Click (Btn);

      Assert (Result_Call_Count = 1, "result callback fired once");
      Assert (Last_Button_Index = 1, "button index is 1");
      Assert (Is_Shown (D),
              "dialog remains visible after button click (auto-close=False)");

      --  App explicitly closes the dialog
      Hide (D);
      Assert (not Is_Shown (D), "dialog is hidden after explicit Hide");
   end Test_Auto_Close_False;

   ---------------------------------------------------------------------------
   --  Test 3: re-enabling auto-close restores default behaviour
   ---------------------------------------------------------------------------

   procedure Test_Auto_Close_Re_Enable is
      Win : Window_Handle;
      D   : Dialog_Handle;
      Btn : Widget_Handle;
      Ready : Boolean := False;
   begin
      Section ("Auto-close re-enabled");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Win := Create_Window_Handle ("Dialog Test 3", (320.0, 240.0));
      D   := Create_Handle;
      Attach_Window (D, Win);
      Set_Auto_Close (D, False);
      Set_Auto_Close (D, True);   --  re-enable
      Add_Button (D, "Yes");
      Connect_Result (D, On_Result'Unrestricted_Access);
      Reset_Result;

      Show (D);
      Assert (Is_Shown (D), "dialog is shown after Show");

      Btn := Adi.Widget.Button."+" (Get_Button_Handle (D, 1));
      On_Click (Btn);

      Assert (Result_Call_Count = 1, "result callback fired once");
      Assert (not Is_Shown (D),
              "dialog hidden after re-enabling auto-close");
   end Test_Auto_Close_Re_Enable;

   ---------------------------------------------------------------------------
   --  Test 4: Escape on a dialog button, with a result callback that
   --  destroys the dialog
   --
   --  The window's dispatch pins the button it delivered the key to, not
   --  the dialog the button forwards Escape to.  The Result subscriber
   --  array lives inside the dialog, so a second subscriber queued
   --  behind the destroying one is reachable only while the dialog is
   --  still there.
   ---------------------------------------------------------------------------

   Doomed_Dialog  : Widget_Handle := Adi.Widget.Null_Handle;
   First_Esc_Ran  : Boolean := False;
   Late_Esc_Ran   : Boolean := False;

   procedure Destroy_On_Dismiss
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (Button_Index, Button_Text);
      Target : Widget_Handle := W;
   begin
      First_Esc_Ran := True;
      Adi.Widget.Destroy (Target);
   end Destroy_On_Dismiss;

   procedure Late_Dismiss
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String)
   is
      pragma Unreferenced (W, Button_Index, Button_Text);
   begin
      Late_Esc_Ran := True;
   end Late_Dismiss;

   procedure Test_Escape_On_Button_Destroys_Dialog is
      Win : Window_Handle;
      D   : Dialog_Handle;
      Btn : Widget_Handle;
      Ready : Boolean := False;
   begin
      Section ("Escape forwarded from a dialog button destroys the dialog");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Win := Create_Window_Handle ("Dialog Test 4", (320.0, 240.0));
      D   := Create_Handle;
      Attach_Window (D, Win);
      Set_Dismiss_On_Escape (D, True);
      Add_Button (D, "Cancel");
      Connect_Result (D, Destroy_On_Dismiss'Unrestricted_Access);
      Connect_Result (D, Late_Dismiss'Unrestricted_Access);

      Show (D);
      Assert (Is_Shown (D), "dialog is shown after Show");

      Doomed_Dialog := To_Widget_Handle (D);
      First_Esc_Ran := False;
      Late_Esc_Ran  := False;

      Btn := Adi.Widget.Button."+" (Get_Button_Handle (D, 1));
      Adi.Widget.On_Key_Down
        (Btn, Adi.SDL.Events.SDL_SCANCODE_ESCAPE, 0, False);

      Assert (First_Esc_Ran, "the destroying result callback ran");
      Assert (Late_Esc_Ran,
              "a Result subscriber queued behind the destroying one"
              & " still runs");

      Put_Line ("  PROBE overlays before pump"
                & Natural'Image (Overlay_Count (Win)));
      Adi.Widget.Pump_Widget_Store;
      Put_Line ("  PROBE overlays after pump"
                & Natural'Image (Overlay_Count (Win)));
      Assert (not Adi.Widget.Is_Valid (Doomed_Dialog),
              "the dialog is gone once the dispatch has unwound");
   end Test_Escape_On_Button_Destroys_Dialog;

   ---------------------------------------------------------------------------
   --  Test 5: an unstyled dialog lays its content out within its bounds
   --
   --  The title and message labels stay attached with empty text, so the
   --  panel's layout has to give them no room for the button row to
   --  remain reachable.
   ---------------------------------------------------------------------------

   procedure Test_Unstyled_Content_Fits_Bounds is
      Win   : Window_Handle;
      D     : Dialog_Handle;
      Ready : Boolean := False;
   begin
      Section ("Unstyled dialog keeps its content inside its bounds");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Win := Create_Window_Handle ("Dialog Test 5", (320.0, 240.0));
      D   := Create_Handle;
      Attach_Window (D, Win);
      Add_Button (D, "OK");

      Show (D);
      Adi.Widget.Rebuild_All_Items (+D);

      declare
         Dlg_G : constant Rectangle := Get_Geometry (+D);
         Row_G : constant Rectangle :=
           Get_Geometry (Adi.Widget.Box."+" (Get_Button_Row_Handle (D)));
         Ttl_G : constant Rectangle :=
           Get_Geometry (Adi.Widget.Label."+" (Get_Title_Handle (D)));
         Msg_G : constant Rectangle :=
           Get_Geometry (Adi.Widget.Label."+" (Get_Message_Handle (D)));
      begin
         Put_Line ("  PROBE dialog" & Dlg_G.Y'Image & Dlg_G.Height'Image
                   & "  title" & Ttl_G.Y'Image & Ttl_G.Height'Image
                   & "  message" & Msg_G.Y'Image & Msg_G.Height'Image
                   & "  row" & Row_G.Y'Image & Row_G.Height'Image);

         Assert (Ttl_G.Height = 0.0,
                 "an untitled dialog's title label takes no height");
         Assert (Msg_G.Height = 0.0,
                 "a message-less dialog's message label takes no height");

         Assert (Row_G.Y >= Dlg_G.Y,
                 "the button row starts inside the dialog");
         Assert (Row_G.Y + Row_G.Height <= Dlg_G.Y + Dlg_G.Height,
                 "the button row ends inside the dialog");
      end;

      Hide (D);
   end Test_Unstyled_Content_Fits_Bounds;

begin
   Start_Suite ("Dialog Auto-Close Tests");
   Test_Auto_Close_Default;
   Test_Auto_Close_False;
   Test_Auto_Close_Re_Enable;
   Test_Escape_On_Button_Destroys_Dialog;
   Test_Unstyled_Content_Fits_Bounds;

   Finish;
end Dialog_Test;
