pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.OS;
with Adi.SDL;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Text_Input; use Adi.Widget.Text_Input;
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

   New_Line;
   Test_Support.Finish;
end Text_Input_Test;
