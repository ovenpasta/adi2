pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.OS;
with Adi.SDL;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Text_Input; use Adi.Widget.Text_Input;
with Adi.Window;
with Adi.SDL.Events; use Adi.SDL.Events;
with Test_Support;

procedure Text_Input_Test is

   --  U+2022 BULLET as UTF-8 (E2 80 A2). Spelled out so the test source
   --  has no implicit dependency on the production Default_Password_Char.
   Bullet_UTF8 : constant String :=
     Character'Val (16#E2#)
       & Character'Val (16#80#)
       & Character'Val (16#A2#);

   procedure Test_Default_Password_State is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Default password state");
      Test_Support.Assert (not Is_Password_Mode (W),
              "password mode is False by default");
      Test_Support.Assert (Get_Password_Character (W) = Bullet_UTF8,
              "default password character is U+2022 BULLET");
   end Test_Default_Password_State;

   procedure Test_Toggle_Password_Mode is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Toggle password mode");
      Set_Password_Mode (W, True);
      Test_Support.Assert (Is_Password_Mode (W), "password mode is True after set");
      Set_Password_Mode (W, False);
      Test_Support.Assert (not Is_Password_Mode (W), "password mode is False after unset");
   end Test_Toggle_Password_Mode;

   procedure Test_Get_Text_Returns_Real_Text is
      W : constant Text_Input_Handle := Create_Handle ("secret123");
   begin
      Put_Line ("Test: Get_Text returns the real text in password mode");
      Set_Password_Mode (W, True);
      Test_Support.Assert (Get_Text (W) = "secret123",
              "Get_Text still returns the unmasked text");
   end Test_Get_Text_Returns_Real_Text;

   procedure Test_Set_Password_Character is
      W : constant Text_Input_Handle := Create_Handle ("");
   begin
      Put_Line ("Test: Set_Password_Character");
      Set_Password_Character (W, "*");
      Test_Support.Assert (Get_Password_Character (W) = "*",
              "password character is now '*'");
      --  Multi-byte UTF-8 codepoint round-trips as a String
      Set_Password_Character (W, Bullet_UTF8);
      Test_Support.Assert (Get_Password_Character (W) = Bullet_UTF8,
              "password character round-trips multi-byte UTF-8");
   end Test_Set_Password_Character;

   procedure Test_Set_Password_Character_Empty_Ignored is
      W : constant Text_Input_Handle := Create_Handle ("");
   begin
      Put_Line ("Test: Set_Password_Character empty is ignored");
      Set_Password_Character (W, "*");
      Set_Password_Character (W, "");
      Test_Support.Assert (Get_Password_Character (W) = "*",
              "empty argument leaves password character unchanged");
   end Test_Set_Password_Character_Empty_Ignored;

   procedure Test_Set_Password_Character_Multi_Codepoint_Rejected is
      W : constant Text_Input_Handle := Create_Handle ("");
   begin
      Put_Line ("Test: Set_Password_Character rejects multi-codepoint strings");
      Set_Password_Character (W, "*");
      Set_Password_Character (W, "**");
      Test_Support.Assert (Get_Password_Character (W) = "*",
              "two ASCII characters rejected");
      Set_Password_Character (W, "ab");
      Test_Support.Assert (Get_Password_Character (W) = "*",
              "two-letter string rejected");
      --  "a" + U+2022 BULLET: 4 bytes, 2 codepoints
      Set_Password_Character (W, "a" & Bullet_UTF8);
      Test_Support.Assert (Get_Password_Character (W) = "*",
              "ASCII + non-ASCII multi-codepoint rejected");
   end Test_Set_Password_Character_Multi_Codepoint_Rejected;

   procedure Test_Double_Click_Selects_All_In_Password_Mode is
      W : constant Text_Input_Handle := Create_Handle ("abc def");
   begin
      Put_Line ("Test: Double-click selects all in password mode");
      Set_Password_Mode (W, True);
      --  Word boundaries would leak where the space is. Confirm by
      --  double-clicking then typing a single char: the whole buffer
      --  must be replaced, not just a word.
      On_Mouse_Down (+W, 0.0, 0.0, Left_Button, 2);
      On_Mouse_Up (+W, 0.0, 0.0, Left_Button);
      On_Text_Input (+W, "Z");
      Test_Support.Assert (Get_Text (W) = "Z",
              "double-click + type replaces the whole buffer");
   end Test_Double_Click_Selects_All_In_Password_Mode;

   procedure Test_Cut_Suppressed_In_Password_Mode is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Ctrl+X is a no-op when password mode is on");
      Set_Password_Mode (W, True);
      --  Select all then attempt Cut
      On_Key_Down (+W, SDL_SCANCODE_A, SDL_KMOD_CTRL, False);
      On_Key_Down (+W, SDL_SCANCODE_X, SDL_KMOD_CTRL, False);
      Test_Support.Assert (Get_Text (W) = "hello",
              "buffer unchanged after Ctrl+X in password mode");
   end Test_Cut_Suppressed_In_Password_Mode;

   --  Runs before SDL is up, where the clipboard write is refused.
   procedure Test_Cut_Keeps_Text_When_Clipboard_Refuses is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Ctrl+X keeps the text when the clipboard refuses");
      Test_Support.Assert (not Adi.OS.Set_Clipboard_Text ("probe"),
              "the clipboard declines before the video subsystem is up,"
              & " and says so");

      On_Key_Down (+W, SDL_SCANCODE_A, SDL_KMOD_CTRL, False);
      On_Key_Down (+W, SDL_SCANCODE_X, SDL_KMOD_CTRL, False);
      Test_Support.Assert (Get_Text (W) = "hello",
              "Cut may delete only what it managed to copy: deleting"
              & " anyway loses the text with nothing to paste back");
   end Test_Cut_Keeps_Text_When_Clipboard_Refuses;

   procedure Start_SDL is
      Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO);
      Test_Support.Assert (Boolean (Ok),
              "SDL_Init should succeed with dummy driver");
   end Start_SDL;

   procedure Test_Cut_Works_When_Not_Password is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Ctrl+X still cuts when password mode is off");
      Test_Support.Assert (Adi.OS.Set_Clipboard_Text ("probe"),
              "the clipboard accepts text once the video subsystem is up");

      On_Key_Down (+W, SDL_SCANCODE_A, SDL_KMOD_CTRL, False);
      On_Key_Down (+W, SDL_SCANCODE_X, SDL_KMOD_CTRL, False);
      Test_Support.Assert (Get_Text (W) = "",
              "buffer cleared after Ctrl+X without password mode");
   end Test_Cut_Works_When_Not_Password;

   ---------------------------------------------------------------------------
   --  A Changed callback may destroy the input from the context-menu path
   --
   --  The dispatch that gets there runs on the menu popup, not on the
   --  input, so the input has to be pinned by the code that reaches into
   --  it.  The Changed subscriber array lives inside the input: a second
   --  subscriber queued behind the destroying one is reachable only
   --  while the input is still there.
   ---------------------------------------------------------------------------

   Doomed_Input   : Widget_Handle := Null_Handle;
   First_Menu_Ran : Boolean := False;
   Late_Menu_Ran  : Boolean := False;

   procedure Destroy_On_Menu_Change (W : Widget_Handle; Text : String) is
      pragma Unreferenced (Text);
      Target : Widget_Handle := W;
   begin
      First_Menu_Ran := True;
      Destroy (Target);
   end Destroy_On_Menu_Change;

   procedure Late_Menu_Change (W : Widget_Handle; Text : String) is
      pragma Unreferenced (W, Text);
   begin
      Late_Menu_Ran := True;
   end Late_Menu_Change;

   --  Depth-first search for the row label carrying Text, so the click
   --  below lands on a row the menu really laid out rather than on a
   --  guessed offset.
   function Find_Row (Root : Widget_Handle; Text : String) return Widget_Handle
   is
      Label_H : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Try_As_Label (Root);
   begin
      if Adi.Widget.Label.Is_Valid (Label_H)
        and then Adi.Widget.Label.Get_Text (Label_H) = Text
      then
         return Root;
      end if;

      for I in 1 .. Child_Count (Root) loop
         declare
            Found : constant Widget_Handle :=
              Find_Row (Get_Child_Handle (Root, I), Text);
         begin
            if Is_Valid (Found) then
               return Found;
            end if;
         end;
      end loop;
      return Null_Handle;
   end Find_Row;

   procedure Test_Menu_Command_Destroys_Own_Input is
      Win : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle
          ("Text Input Menu Test", (320.0, 240.0));
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      W    : constant Text_Input_Handle := Create_Handle ("");
      Kept : constant Widget_Handle := To_Widget_Handle (W);
      Undo_Row : Widget_Handle := Null_Handle;
      Popup    : Widget_Handle := Null_Handle;
      Shown    : Boolean;
   begin
      Put_Line ("Test: a context-menu command destroys its own text input");

      Add_Child (Adi.Widget.Box.To_Widget_Handle (Root), Kept);
      Adi.Window.Set_Root (Win, Adi.Widget.Box.To_Widget_Handle (Root));

      --  Give the buffer something for Undo to change.
      On_Text_Input (Kept, "abc");
      Test_Support.Assert (Get_Text (W) = "abc", "the buffer took the text");

      Doomed_Input   := Kept;
      First_Menu_Ran := False;
      Late_Menu_Ran  := False;
      Connect_Changed (W, Destroy_On_Menu_Change'Unrestricted_Access);
      Connect_Changed (W, Late_Menu_Change'Unrestricted_Access);

      Shown := Bubble_Context_Menu (Kept, 20.0, 20.0);
      Test_Support.Assert (Shown, "the input answered the context-menu request");

      for I in 1 .. Adi.Window.Overlay_Count (Win) loop
         Popup := Adi.Window.Get_Overlay_Handle (Win, I);
         Undo_Row := Find_Row (Popup, "Undo");
         exit when Is_Valid (Undo_Row);
      end loop;
      Test_Support.Assert (Is_Valid (Undo_Row),
              "the shown menu has an Undo row");

      declare
         G : constant Rectangle := Get_Geometry (Undo_Row);
      begin
         Test_Support.Assert (G.Height > 0.0, "the Undo row was laid out");
         On_Mouse_Down
           (Popup,
            X      => G.X + G.Width / 2.0,
            Y      => G.Y + G.Height / 2.0,
            Button => Left_Button,
            Clicks => 1);
      end;

      Test_Support.Assert (First_Menu_Ran, "the destroying callback ran");
      Test_Support.Assert (Late_Menu_Ran,
              "a Changed subscriber queued behind the destroying one"
              & " still runs");

      Pump_Widget_Store;
      Test_Support.Assert (not Is_Valid (Doomed_Input),
              "the text input is gone once the dispatch has unwound");
   end Test_Menu_Command_Destroys_Own_Input;

begin
   Test_Support.Start_Suite ("Text input test");
   New_Line;

   Test_Default_Password_State;
   Test_Toggle_Password_Mode;
   Test_Get_Text_Returns_Real_Text;
   Test_Set_Password_Character;
   Test_Set_Password_Character_Empty_Ignored;
   Test_Set_Password_Character_Multi_Codepoint_Rejected;
   Test_Double_Click_Selects_All_In_Password_Mode;
   Test_Cut_Suppressed_In_Password_Mode;
   Test_Cut_Keeps_Text_When_Clipboard_Refuses;

   --  Order matters: the case above needs a clipboard that refuses, this
   --  one needs a clipboard that works.
   Start_SDL;
   Test_Cut_Works_When_Not_Password;
   Test_Menu_Command_Destroys_Own_Input;

   New_Line;
   Test_Support.Finish;
end Text_Input_Test;
