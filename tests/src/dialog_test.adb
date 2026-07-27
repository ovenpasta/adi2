pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;          use Ada.Text_IO;
with Adi.SDL;              use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Button;
with Adi.Widget.Dialog;    use Adi.Widget.Dialog;
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

begin
   Start_Suite ("Dialog Auto-Close Tests");
   Test_Auto_Close_Default;
   Test_Auto_Close_False;
   Test_Auto_Close_Re_Enable;

   Finish;
end Dialog_Test;
