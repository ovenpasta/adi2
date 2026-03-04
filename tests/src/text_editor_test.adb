pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Text_Buffer; use Adi.Text_Buffer;
with Adi.Widget.Text_Editor; use Adi.Widget.Text_Editor;
with Adi.Widget.Context_Menu;
with Adi.SDL.Events; use Adi.SDL.Events;

procedure Text_Editor_Test is

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;

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

   ---------------------------------------------------------------------------
   --  Buffer-level: Append_Text
   ---------------------------------------------------------------------------

   procedure Test_Append_Text_Basic is
      B : Text_Buffer;
   begin
      Put_Line ("Test: Append_Text basic");
      Clear (B);
      Insert_Text (B, "Hello");
      --  Move caret to beginning so we can verify it stays there
      Move_To_Start (B);
      declare
         V_Before : constant Natural := Content_Version (B);
         C_Before : constant Position := Get_Caret (B);
      begin
         Append_Text (B, " World");
         Assert (Get_Text (B) = "Hello World",
                 "content is 'Hello World'");
         Assert (Get_Caret (B) = C_Before,
                 "caret unchanged after append");
         Assert (Content_Version (B) > V_Before,
                 "content version incremented");
      end;
      New_Line;
   end Test_Append_Text_Basic;

   procedure Test_Append_Text_With_Newlines is
      B : Text_Buffer;
      LF : constant Character := Character'Val (10);
   begin
      Put_Line ("Test: Append_Text with newlines");
      Clear (B);
      Insert_Text (B, "line1");
      Move_To_Start (B);
      Append_Text (B, LF & "line2" & LF & "line3");
      Assert (Get_Line_Count (B) = 3, "3 lines after append");
      Assert (Get_Line (B, 1) = "line1", "line 1 correct");
      Assert (Get_Line (B, 2) = "line2", "line 2 correct");
      Assert (Get_Line (B, 3) = "line3", "line 3 correct");
      Assert (Get_Caret (B) = (Line => 1, Column => 0),
              "caret still at start");
      New_Line;
   end Test_Append_Text_With_Newlines;

   procedure Test_Append_Text_Preserves_Selection is
      B : Text_Buffer;
   begin
      Put_Line ("Test: Append_Text preserves selection");
      Clear (B);
      Insert_Text (B, "ABCDEF");
      --  Select "BCD" (caret at col 1, extend to col 4)
      Set_Caret (B, (Line => 1, Column => 1));
      Set_Caret (B, (Line => 1, Column => 4), Extend_Selection => True);
      Assert (Has_Selection (B), "selection active before append");
      Assert (Get_Selected_Text (B) = "BCD", "selected text is BCD");

      Append_Text (B, "GHI");
      Assert (Has_Selection (B), "selection still active after append");
      Assert (Get_Selected_Text (B) = "BCD",
              "selected text unchanged after append");
      Assert (Get_Text (B) = "ABCDEFGHI", "full text correct");
      New_Line;
   end Test_Append_Text_Preserves_Selection;

   procedure Test_Append_Text_Is_Undoable is
      B : Text_Buffer;
   begin
      Put_Line ("Test: Append_Text is undoable");
      Clear (B);
      Insert_Text (B, "base");
      --  Clear undo from Insert_Text by accepting it
      declare
         Dummy : Boolean;
      begin
         --  Undo the insert
         Dummy := Undo (B);
         --  Redo it back
         Dummy := Redo (B);
      end;

      Append_Text (B, " extra");
      Assert (Get_Text (B) = "base extra", "text after append");
      Assert (Can_Undo (B), "can undo after append");

      declare
         Dummy : Boolean;
      begin
         Dummy := Undo (B);
      end;
      Assert (Get_Text (B) = "base", "undo restores pre-append text");
      New_Line;
   end Test_Append_Text_Is_Undoable;

   procedure Test_Append_Text_No_Undo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: Append_Text with Record_Undo => False");
      --  Fresh buffer (no Clear — Clear records undo)
      Append_Text (B, "base", Record_Undo => False);
      Append_Text (B, " log", Record_Undo => False);
      Assert (Get_Text (B) = "base log", "text after no-undo append");
      Assert (not Can_Undo (B),
              "no undo after append with Record_Undo => False");
      New_Line;
   end Test_Append_Text_No_Undo;

   procedure Test_Append_No_Undo_Clears_Redo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: Append_Text no-undo clears stale redo");
      --  Set up: insert text, then undo so redo is available
      Insert_Text (B, "hello");
      Assert (Can_Undo (B), "can undo after insert");
      declare
         Dummy : Boolean;
      begin
         Dummy := Undo (B);
      end;
      Assert (Get_Text (B) = "", "text empty after undo");
      Assert (Can_Redo (B), "redo available after undo");

      --  Redo to restore, then undo again to get redo back
      declare
         Dummy : Boolean;
      begin
         Dummy := Redo (B);
      end;
      Assert (Get_Text (B) = "hello", "text restored after redo");
      declare
         Dummy : Boolean;
      begin
         Dummy := Undo (B);
      end;
      Assert (Can_Redo (B), "redo available before append");

      --  Append with Record_Undo => False — must invalidate stale redo
      Append_Text (B, " world", Record_Undo => False);
      Assert (Get_Text (B) = " world", "appended to empty buffer");
      Assert (not Can_Redo (B),
              "redo cleared after no-undo append");
      New_Line;
   end Test_Append_No_Undo_Clears_Redo;

   ---------------------------------------------------------------------------
   --  Widget-level: Read-only mode
   ---------------------------------------------------------------------------

   procedure Test_Read_Only_Default is
      W : constant Text_Editor_Widget_Access := Create ("test");
   begin
      Put_Line ("Test: Read-only default");
      Assert (not Is_Read_Only (W.all), "read-only is false by default");
      Set_Read_Only (W.all, True);
      Assert (Is_Read_Only (W.all), "read-only is true after set");
      Set_Read_Only (W.all, False);
      Assert (not Is_Read_Only (W.all), "read-only is false after unset");
      New_Line;
   end Test_Read_Only_Default;

   procedure Test_Read_Only_Blocks_Text_Input is
      W : constant Text_Editor_Widget_Access := Create ("hello");
   begin
      Put_Line ("Test: Read-only blocks On_Text_Input");
      Set_Read_Only (W.all, True);
      On_Text_Input (W.all, "xyz");
      Assert (Get_Text (W.all) = "hello",
              "text unchanged after On_Text_Input in read-only");
      New_Line;
   end Test_Read_Only_Blocks_Text_Input;

   procedure Test_Read_Only_Blocks_Editing_Keys is
      W : constant Text_Editor_Widget_Access := Create ("hello");
   begin
      Put_Line ("Test: Read-only blocks editing keys");
      Set_Read_Only (W.all, True);

      --  Backspace
      On_Key_Down (W.all, SDL_SCANCODE_BACKSPACE, 0, False);
      Assert (Get_Text (W.all) = "hello", "backspace blocked");

      --  Delete
      On_Key_Down (W.all, SDL_SCANCODE_DELETE, 0, False);
      Assert (Get_Text (W.all) = "hello", "delete blocked");

      --  Return
      On_Key_Down (W.all, SDL_SCANCODE_RETURN, 0, False);
      Assert (Get_Text (W.all) = "hello", "return blocked");

      --  Tab
      On_Key_Down (W.all, SDL_SCANCODE_TAB, 0, False);
      Assert (Get_Text (W.all) = "hello", "tab blocked");

      --  Ctrl+V (paste) — may be a no-op if clipboard is empty, but
      --  should not modify text regardless
      On_Key_Down (W.all, SDL_SCANCODE_V, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W.all) = "hello", "ctrl+v blocked");

      --  Ctrl+Z (undo)
      On_Key_Down (W.all, SDL_SCANCODE_Z, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W.all) = "hello", "ctrl+z blocked");

      --  Ctrl+Y (redo)
      On_Key_Down (W.all, SDL_SCANCODE_Y, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W.all) = "hello", "ctrl+y blocked");

      --  Ctrl+X (cut)
      On_Key_Down (W.all, SDL_SCANCODE_X, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W.all) = "hello", "ctrl+x blocked");
      New_Line;
   end Test_Read_Only_Blocks_Editing_Keys;

   procedure Test_Read_Only_Allows_Navigation is
      W : constant Text_Editor_Widget_Access := Create ("hello");
   begin
      Put_Line ("Test: Read-only allows navigation");
      Set_Read_Only (W.all, True);

      --  Caret starts at end of "hello" (line 1, col 5)
      --  Press Home to go to start
      On_Key_Down (W.all, SDL_SCANCODE_HOME, 0, False);
      --  The buffer's caret should be at the beginning now
      --  We can't directly access W.Buffer from here, so check via
      --  Ctrl+A (select all) + verify it doesn't crash
      On_Key_Down (W.all, SDL_SCANCODE_A, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W.all) = "hello",
              "navigation + select all works in read-only");

      --  Ctrl+C (copy) should not crash or modify
      On_Key_Down (W.all, SDL_SCANCODE_C, SDL_KMOD_CTRL, False);
      Assert (Get_Text (W.all) = "hello",
              "ctrl+c works in read-only");
      New_Line;
   end Test_Read_Only_Allows_Navigation;

   ---------------------------------------------------------------------------
   --  Context menu: disabled items
   ---------------------------------------------------------------------------

   procedure Test_Context_Menu_Disabled_State is
      Menu : constant Adi.Widget.Context_Menu.Context_Menu_Access :=
        Adi.Widget.Context_Menu.Create;
   begin
      Put_Line ("Test: Context_Menu disabled state");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Undo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Redo");
      Adi.Widget.Context_Menu.Add_Item (Menu.all, "Copy");

      Assert (not Adi.Widget.Context_Menu.Is_Item_Disabled (Menu.all, 1),
              "item 1 enabled by default");
      Assert (not Adi.Widget.Context_Menu.Is_Item_Disabled (Menu.all, 2),
              "item 2 enabled by default");

      Adi.Widget.Context_Menu.Set_Item_Disabled (Menu.all, 1, True);
      Assert (Adi.Widget.Context_Menu.Is_Item_Disabled (Menu.all, 1),
              "item 1 disabled after set");
      Assert (not Adi.Widget.Context_Menu.Is_Item_Disabled (Menu.all, 2),
              "item 2 still enabled");

      Adi.Widget.Context_Menu.Set_Item_Disabled (Menu.all, 1, False);
      Assert (not Adi.Widget.Context_Menu.Is_Item_Disabled (Menu.all, 1),
              "item 1 re-enabled");
      New_Line;
   end Test_Context_Menu_Disabled_State;

begin
   Put_Line ("Text editor test");
   Put_Line ("");

   Test_Append_Text_Basic;
   Test_Append_Text_With_Newlines;
   Test_Append_Text_Preserves_Selection;
   Test_Append_Text_Is_Undoable;
   Test_Append_Text_No_Undo;
   Test_Append_No_Undo_Clears_Redo;
   Test_Read_Only_Default;
   Test_Read_Only_Blocks_Text_Input;
   Test_Read_Only_Blocks_Editing_Keys;
   Test_Read_Only_Allows_Navigation;
   Test_Context_Menu_Disabled_State;

   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "text editor test failed";
   end if;
end Text_Editor_Test;
