pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Text_Buffer; use Adi.Text_Buffer;

procedure Text_Buffer_Test is

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

   procedure Assert_Text (B : Text_Buffer; Expected : String; Msg : String) is
   begin
      Assert (Get_Text (B) = Expected,
              Msg & " (got=""" & Get_Text (B) & """)");
   end Assert_Text;

   procedure Assert_Caret
     (B      : Text_Buffer;
      Line   : Positive;
      Column : Natural;
      Msg    : String)
   is
      C : constant Position := Get_Caret (B);
   begin
      Assert (C.Line = Line and then C.Column = Column,
              Msg & " (got line=" & C.Line'Image & " col=" & C.Column'Image & ")");
   end Assert_Caret;

   procedure Test_Basic_Undo_Redo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: basic undo/redo");
      Clear (B);
      Insert_Text (B, "abc");
      Assert_Text (B, "abc", "insert text");
      Assert_Caret (B, 1, 3, "caret after insert");

      Assert (Undo (B), "undo should succeed");
      Assert_Text (B, "", "undo returns empty text");
      Assert_Caret (B, 1, 0, "caret restored by undo");

      Assert (Redo (B), "redo should succeed");
      Assert_Text (B, "abc", "redo restores inserted text");
      Assert_Caret (B, 1, 3, "caret restored by redo");
      New_Line;
   end Test_Basic_Undo_Redo;

   procedure Test_Redo_Invalidated_By_New_Edit is
      B : Text_Buffer;
   begin
      Put_Line ("Test: redo invalidated by new edit");
      Clear (B);
      Insert_Text (B, "abc");
      Assert (Undo (B), "undo should succeed before branching");
      Insert_Text (B, "x");
      Assert_Text (B, "x", "new edit applied after undo");
      Assert (not Can_Redo (B), "redo stack cleared by new edit");
      Assert (not Redo (B), "redo should fail after branching");
      New_Line;
   end Test_Redo_Invalidated_By_New_Edit;

   procedure Test_Selection_Replace_Undo_Redo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: selection replace undo/redo");
      Set_Text (B, "hello world");
      Set_Caret (B, (Line => 1, Column => 6));
      Set_Caret (B, (Line => 1, Column => 11), Extend_Selection => True);
      Assert (Has_Selection (B), "selection should be active");
      Assert (Get_Selected_Text (B) = "world", "selected text should be world");

      Insert_Text (B, "Ada");
      Assert_Text (B, "hello Ada", "selection replaced by insert");
      Assert (not Has_Selection (B), "selection cleared after replacement");

      Assert (Undo (B), "undo replacement");
      Assert_Text (B, "hello world", "undo restores original text");
      Assert (Has_Selection (B), "undo restores selection");
      Assert (Get_Selected_Text (B) = "world", "undo restores selected text");

      Assert (Redo (B), "redo replacement");
      Assert_Text (B, "hello Ada", "redo re-applies replacement");
      New_Line;
   end Test_Selection_Replace_Undo_Redo;

   procedure Test_Collapsed_Selection_Does_Not_Overwrite is
      B : Text_Buffer;
   begin
      Put_Line ("Test: collapsed selection does not overwrite on type");

      Clear (B);
      Set_Caret (B, (Line => 1, Column => 0), Extend_Selection => True);
      Assert (not Has_Selection (B), "collapsed selection should not be active");

      Insert_Text (B, "a");
      Assert_Text (B, "a", "first char inserted");
      Assert (not Has_Selection (B), "no selection after first char");

      Insert_Text (B, "b");
      Assert_Text (B, "ab", "second char appends (no overwrite)");
      Assert (not Has_Selection (B), "no selection after second char");

      Set_Caret (B, (Line => 1, Column => 1));
      Set_Caret (B, (Line => 1, Column => 1), Extend_Selection => True);
      Delete_Backward (B);
      Assert_Text (B, "b", "backspace edits without creating selection");
      Assert (not Has_Selection (B), "backspace should leave no selection");
      New_Line;
   end Test_Collapsed_Selection_Does_Not_Overwrite;

   procedure Test_Line_Merge_Backspace_Undo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: line merge by backspace");
      Set_Text (B, "abc" & ASCII.LF & "def");
      Set_Caret (B, (Line => 2, Column => 0));
      Delete_Backward (B);
      Assert_Text (B, "abcdef", "backspace at line start merges lines");
      Assert_Caret (B, 1, 3, "caret after merge");

      Assert (Undo (B), "undo merge");
      Assert_Text (B, "abc" & ASCII.LF & "def", "undo restores line break");
      Assert_Caret (B, 2, 0, "undo restores caret");
      New_Line;
   end Test_Line_Merge_Backspace_Undo;

   procedure Test_Line_Merge_Delete_Undo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: line merge by delete");
      Set_Text (B, "abc" & ASCII.LF & "def");
      Set_Caret (B, (Line => 1, Column => 3));
      Delete_Forward (B);
      Assert_Text (B, "abcdef", "delete at line end merges next line");
      Assert_Caret (B, 1, 3, "caret stays at merge point");

      Assert (Undo (B), "undo delete merge");
      Assert_Text (B, "abc" & ASCII.LF & "def", "undo restores split lines");
      Assert_Caret (B, 1, 3, "undo restores caret");
      New_Line;
   end Test_Line_Merge_Delete_Undo;

   procedure Test_Multiline_Insert_Undo_Redo is
      B : Text_Buffer;
   begin
      Put_Line ("Test: multiline insert undo/redo");
      Clear (B);
      Insert_Text (B, "a" & ASCII.LF & "b" & ASCII.LF);
      Assert (Get_Line_Count (B) = 3, "multiline insert should create 3 lines");
      Assert_Text (B, "a" & ASCII.LF & "b" & ASCII.LF, "text with trailing LF preserved");
      Assert_Caret (B, 3, 0, "caret at start of trailing empty line");

      Assert (Undo (B), "undo multiline insert");
      Assert_Text (B, "", "undo restores empty buffer");

      Assert (Redo (B), "redo multiline insert");
      Assert_Text (B, "a" & ASCII.LF & "b" & ASCII.LF, "redo restores multiline text");
      New_Line;
   end Test_Multiline_Insert_Undo_Redo;

   procedure Test_Movement_Does_Not_Create_History is
      B : Text_Buffer;
   begin
      Put_Line ("Test: movement does not create history entries");
      Clear (B);
      Set_Text (B, "abc");
      Move_Left (B);
      Move_Left (B);
      Assert_Caret (B, 1, 1, "caret moved left");
      Assert (Undo (B), "undo after movement should succeed");
      Assert_Text (B, "", "undo should revert Set_Text, not movement");
      New_Line;
   end Test_Movement_Does_Not_Create_History;

   procedure Test_UTF8_Boundary_Delete_Undo is
      B : Text_Buffer;
      E_Acute : constant String :=
        "A" & Character'Val (16#C3#) & Character'Val (16#A9#) & "B";
   begin
      Put_Line ("Test: UTF-8 boundary deletion and undo");

      Set_Text (B, E_Acute);
      Set_Caret (B, (Line => 1, Column => 3));
      Delete_Backward (B);
      Assert_Text (B, "AB", "backspace should delete full multi-byte char");
      Assert_Caret (B, 1, 1, "caret moves to char boundary");
      Assert (Undo (B), "undo UTF-8 backspace");
      Assert_Text (B, E_Acute, "undo restores UTF-8 text");

      Set_Caret (B, (Line => 1, Column => 1));
      Delete_Forward (B);
      Assert_Text (B, "AB", "delete-forward should delete full multi-byte char");
      Assert_Caret (B, 1, 1, "caret remains before deleted char");
      Assert (Undo (B), "undo UTF-8 delete-forward");
      Assert_Text (B, E_Acute, "undo restores UTF-8 text again");
      New_Line;
   end Test_UTF8_Boundary_Delete_Undo;

   procedure Test_History_Depth_Cap is
      B          : Text_Buffer;
      Undo_Count : Natural := 0;
   begin
      Put_Line ("Test: history depth cap");
      Clear (B);
      for I in 1 .. 205 loop
         Insert_Text (B, "x");
      end loop;
      Assert (Get_Text (B)'Length = 205, "all inserts applied");

      while Undo (B) loop
         Undo_Count := Undo_Count + 1;
      end loop;

      Assert (Undo_Count = 200, "undo count should be capped to 200 entries");
      Assert (Get_Text (B)'Length = 5, "oldest 5 edits should be beyond history cap");
      Assert (not Undo (B), "no further undo after stack exhausted");
      New_Line;
   end Test_History_Depth_Cap;

begin
   Put_Line ("Text buffer undo/redo test");
   Put_Line ("");

   Test_Basic_Undo_Redo;
   Test_Redo_Invalidated_By_New_Edit;
   Test_Selection_Replace_Undo_Redo;
   Test_Collapsed_Selection_Does_Not_Overwrite;
   Test_Line_Merge_Backspace_Undo;
   Test_Line_Merge_Delete_Undo;
   Test_Multiline_Insert_Undo_Redo;
   Test_Movement_Does_Not_Create_History;
   Test_UTF8_Boundary_Delete_Undo;
   Test_History_Depth_Cap;

   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "text buffer test failed";
   end if;
end Text_Buffer_Test;
