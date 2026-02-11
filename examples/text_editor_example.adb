pragma Ada_2022;

with Adi.App;
with Adi.Window;              use Adi.Window;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;        use Adi.Widget.Label;
with Adi.Widget.Text_Editor;  use Adi.Widget.Text_Editor;
with Text_Editor_Example_Styles; use Text_Editor_Example_Styles;

procedure Text_Editor_Example is
   A : Adi.App.App;

   Sample_Text : constant String :=
     "-- Multiline Text Editor Demo" & ASCII.LF &
     "-- Try editing this content to explore every feature." & ASCII.LF &
     "" & ASCII.LF &
     "with Ada.Text_IO; use Ada.Text_IO;" & ASCII.LF &
     "with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;" & ASCII.LF &
     "" & ASCII.LF &
     "procedure Hello is" & ASCII.LF &
     "   type Item is record" & ASCII.LF &
     "      Id   : Positive;" & ASCII.LF &
     "      Name : String (1 .. 8);" & ASCII.LF &
     "   end record;" & ASCII.LF &
     "" & ASCII.LF &
     "   Items : constant array (1 .. 5) of Item := (" & ASCII.LF &
     "      (Id => 1, Name => ""Alpha   "")," & ASCII.LF &
     "      (Id => 2, Name => ""Beta    "")," & ASCII.LF &
     "      (Id => 3, Name => ""Gamma   "")," & ASCII.LF &
     "      (Id => 4, Name => ""Delta   "")," & ASCII.LF &
     "      (Id => 5, Name => ""Epsilon ""));" & ASCII.LF &
     "begin" & ASCII.LF &
     "   Put_Line (""Hello, world!"");" & ASCII.LF &
     "" & ASCII.LF &
     "   for I in Items'Range loop" & ASCII.LF &
     "      Put_Line (""  Item"" & Integer'Image (Items (I).Id) & "": "" & Items (I).Name);" & ASCII.LF &
     "   end loop;" & ASCII.LF &
     "" & ASCII.LF &
     "   declare" & ASCII.LF &
     "      X : constant Integer := 42;" & ASCII.LF &
     "      Y : constant Integer := X * 2;" & ASCII.LF &
     "      Z : constant Integer := Y - 7;" & ASCII.LF &
     "   begin" & ASCII.LF &
     "      Put_Line (""X="" & Integer'Image (X));" & ASCII.LF &
     "      Put_Line (""Y="" & Integer'Image (Y));" & ASCII.LF &
     "      Put_Line (""Z="" & Integer'Image (Z));" & ASCII.LF &
     "   end;" & ASCII.LF &
     "" & ASCII.LF &
     "   -- UTF-8 test line: cafe, naive, resume, jalapeno, facade" & ASCII.LF &
     "   -- Add/replace text here and test caret movement on multibyte chars." & ASCII.LF &
     "" & ASCII.LF &
     "   -- Keyboard shortcuts:" & ASCII.LF &
     "   --   Navigation: arrows, Home/End, Ctrl+Home/End, Page Up/Down" & ASCII.LF &
     "   --   Selection : Shift+arrows, Ctrl+A, mouse drag" & ASCII.LF &
     "   --   Clipboard : Ctrl+C, Ctrl+X, Ctrl+V (multiline paste)" & ASCII.LF &
     "   --   History   : Ctrl+Z, Ctrl+Y, Ctrl+Shift+Z" & ASCII.LF &
     "   --   Insert    : Enter for newline, Tab inserts spaces" & ASCII.LF &
     "   --   Context   : Right-click for Undo/Redo/Cut/Copy/Paste/Select All" & ASCII.LF &
     "" & ASCII.LF &
     "   -- Mouse interactions:" & ASCII.LF &
     "   --   Single click: place caret" & ASCII.LF &
     "   --   Double click: select word" & ASCII.LF &
     "   --   Triple click: select line" & ASCII.LF &
     "   --   Wheel/scrollbar: vertical scrolling" & ASCII.LF &
     "" & ASCII.LF &
     "end Hello;" & ASCII.LF &
     "" & ASCII.LF &
     "-- Extra filler lines for scrolling and page navigation tests" & ASCII.LF &
     "Line 01: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 02: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 03: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 04: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 05: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 06: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 07: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 08: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 09: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 10: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 11: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 12: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 13: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 14: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 15: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 16: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 17: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 18: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 19: quick brown fox jumps over the lazy dog." & ASCII.LF &
     "Line 20: quick brown fox jumps over the lazy dog.";

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access :=
        Create_Window ("Text Editor Example", (800.0, 600.0));

      Root   : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Title  : constant Label_Widget_Access :=
        Adi.Widget.Label.Create ("Multiline Text Editor");
      Editor : constant Text_Editor_Widget_Access :=
        Adi.Widget.Text_Editor.Create (Sample_Text);
   begin
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Editor.all, Editor_Class_Part_Styles);
      Attach_Window (Editor.all, W);
      Set_Context_Menu_Part_Styles (Editor.all, Context_Menu_Class_Part_Styles);
      Set_Context_Menu_Item_Part_Styles (Editor.all, Context_Menu_Item_Class_Part_Styles);

      Root.Add_Child (Title);
      Root.Add_Child (Editor);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Text_Editor_Example;
