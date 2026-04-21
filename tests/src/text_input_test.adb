pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Text_Input; use Adi.Widget.Text_Input;
with Adi.SDL.Events; use Adi.SDL.Events;

procedure Text_Input_Test is

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;

   --  U+2022 BULLET as UTF-8 (E2 80 A2). Spelled out so the test source
   --  has no implicit dependency on the production Default_Password_Char.
   Bullet_UTF8 : constant String :=
     Character'Val (16#E2#)
       & Character'Val (16#80#)
       & Character'Val (16#A2#);

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      Test_Count := Test_Count + 1;
      if Cond then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Msg);
      else
         Put_Line ("  [FAIL] " & Msg);
      end if;
   end Assert;

   procedure Test_Default_Password_State is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Default password state");
      Assert (not Is_Password_Mode (W),
              "password mode is False by default");
      Assert (Get_Password_Character (W) = Bullet_UTF8,
              "default password character is U+2022 BULLET");
   end Test_Default_Password_State;

   procedure Test_Toggle_Password_Mode is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Toggle password mode");
      Set_Password_Mode (W, True);
      Assert (Is_Password_Mode (W), "password mode is True after set");
      Set_Password_Mode (W, False);
      Assert (not Is_Password_Mode (W), "password mode is False after unset");
   end Test_Toggle_Password_Mode;

   procedure Test_Get_Text_Returns_Real_Text is
      W : constant Text_Input_Handle := Create_Handle ("secret123");
   begin
      Put_Line ("Test: Get_Text returns the real text in password mode");
      Set_Password_Mode (W, True);
      Assert (Get_Text (W) = "secret123",
              "Get_Text still returns the unmasked text");
   end Test_Get_Text_Returns_Real_Text;

   procedure Test_Set_Password_Character is
      W : constant Text_Input_Handle := Create_Handle ("");
   begin
      Put_Line ("Test: Set_Password_Character");
      Set_Password_Character (W, "*");
      Assert (Get_Password_Character (W) = "*",
              "password character is now '*'");
      --  Multi-byte UTF-8 codepoint round-trips as a String
      Set_Password_Character (W, Bullet_UTF8);
      Assert (Get_Password_Character (W) = Bullet_UTF8,
              "password character round-trips multi-byte UTF-8");
   end Test_Set_Password_Character;

   procedure Test_Set_Password_Character_Empty_Ignored is
      W : constant Text_Input_Handle := Create_Handle ("");
   begin
      Put_Line ("Test: Set_Password_Character empty is ignored");
      Set_Password_Character (W, "*");
      Set_Password_Character (W, "");
      Assert (Get_Password_Character (W) = "*",
              "empty argument leaves password character unchanged");
   end Test_Set_Password_Character_Empty_Ignored;

   procedure Test_Set_Password_Character_Multi_Codepoint_Rejected is
      W : constant Text_Input_Handle := Create_Handle ("");
   begin
      Put_Line ("Test: Set_Password_Character rejects multi-codepoint strings");
      Set_Password_Character (W, "*");
      Set_Password_Character (W, "**");
      Assert (Get_Password_Character (W) = "*",
              "two ASCII characters rejected");
      Set_Password_Character (W, "ab");
      Assert (Get_Password_Character (W) = "*",
              "two-letter string rejected");
      --  "a" + U+2022 BULLET: 4 bytes, 2 codepoints
      Set_Password_Character (W, "a" & Bullet_UTF8);
      Assert (Get_Password_Character (W) = "*",
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
      Assert (Get_Text (W) = "Z",
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
      Assert (Get_Text (W) = "hello",
              "buffer unchanged after Ctrl+X in password mode");
   end Test_Cut_Suppressed_In_Password_Mode;

   procedure Test_Cut_Works_When_Not_Password is
      W : constant Text_Input_Handle := Create_Handle ("hello");
   begin
      Put_Line ("Test: Ctrl+X still cuts when password mode is off");
      --  Sanity check: without password mode, Ctrl+A then Ctrl+X
      --  empties the buffer (clipboard write may be a no-op without
      --  SDL init, but the buffer-side delete still runs).
      On_Key_Down (+W, SDL_SCANCODE_A, SDL_KMOD_CTRL, False);
      On_Key_Down (+W, SDL_SCANCODE_X, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W) = "",
              "buffer cleared after Ctrl+X without password mode");
   end Test_Cut_Works_When_Not_Password;

begin
   Put_Line ("Text input test");
   New_Line;

   Test_Default_Password_State;
   Test_Toggle_Password_Mode;
   Test_Get_Text_Returns_Real_Text;
   Test_Set_Password_Character;
   Test_Set_Password_Character_Empty_Ignored;
   Test_Set_Password_Character_Multi_Codepoint_Rejected;
   Test_Double_Click_Selects_All_In_Password_Mode;
   Test_Cut_Suppressed_In_Password_Mode;
   Test_Cut_Works_When_Not_Password;

   New_Line;
   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image
             & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "text input test failed";
   end if;
end Text_Input_Test;
