pragma Ada_2022;

with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Adi.App;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.OS;
with Adi.Window;              use Adi.Window;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;       use Adi.Widget.Button;
with Adi.Widget.Button.Switch;
with Adi.Widget.Label;        use Adi.Widget.Label;
with Adi.Widget.Text_Editor;  use Adi.Widget.Text_Editor;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Text_Editor_Example_Styles; use Text_Editor_Example_Styles;

procedure Text_Editor_Example is
   A : Adi.App.App;

   Sample_Text : constant String :=
     "-- Multiline Text Editor Demo" & ASCII.LF &
     "-- Use the Wrap switch above to toggle wrapped rows on/off." & ASCII.LF &
     "" & ASCII.LF &
     "Paragraph 1:" & ASCII.LF &
     "This paragraph is intentionally long and includes enough words to wrap across multiple visual rows when wrap is enabled, letting you test caret movement with Up and Down, selection highlighting across wrapped segments, and smooth scrolling behavior." & ASCII.LF &
     "" & ASCII.LF &
     "Paragraph 2:" & ASCII.LF &
     "When wrap is disabled this same paragraph should stay as a single logical line, forcing horizontal overflow so you can validate that navigation still works as expected and that vertical movement follows logical lines rather than visual rows." & ASCII.LF &
     "" & ASCII.LF &
     "Long single token (no spaces):" & ASCII.LF &
     "WrapToggleStressToken_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789_abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789_abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789_end" & ASCII.LF &
     "" & ASCII.LF &
     "Pseudo-code block:" & ASCII.LF &
     "for Line in 1 .. 4 loop" & ASCII.LF &
     "   Put_Line (""This line is intentionally expanded to cover a very wide width and force wrapping behavior in the visual row model."");" & ASCII.LF &
     "end loop;" & ASCII.LF &
     "" & ASCII.LF &
     "Paragraph 3 (editing checklist): place caret with mouse, drag selection over multiple wrapped rows, double-click a word, triple-click a line, then toggle wrap and verify caret/selection mapping still feels correct." & ASCII.LF &
     "" & ASCII.LF &
     "UTF-8 sample: cafe naive resume jalapeno facade; replace text around multibyte characters and verify delete/backspace boundaries." & ASCII.LF &
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
      Controls : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Wrap_Status : constant Label_Widget_Access :=
        Adi.Widget.Label.Create ("Wrap: ON");
      Wrap_Switch : constant Adi.Widget.Button.Switch.Switch_Widget_Access :=
        Adi.Widget.Button.Switch.Create (True);
      Open_Btn : constant Button_Widget_Access :=
        Adi.Widget.Button.Create ("Open File");
      Editor : constant Text_Editor_Widget_Access :=
        Adi.Widget.Text_Editor.Create (Sample_Text);

      Wrap_On_Label_Widget : constant Widget_Style :=
        From (Editor_Class_Label_Base_Style).Build;
      Wrap_Off_Label_Widget : constant Widget_Style :=
        From
          (Merge
             (Editor_Class_Label_Base_Style,
              (White_Space    => Set (WS_Nowrap),
               Text_Wrap_Mode => Set (TWM_Nowrap),
               others => <>)))
        .Build;

      procedure Apply_Wrap (Active : Boolean) is
      begin
         if Active then
            Set_Part_Style (Editor.all, Label_Part, Wrap_On_Label_Widget);
            Set_Text (Wrap_Status.all, "Wrap: ON");
         else
            Set_Part_Style (Editor.all, Label_Part, Wrap_Off_Label_Widget);
            Set_Text (Wrap_Status.all, "Wrap: OFF");
         end if;
      end Apply_Wrap;

      procedure On_Wrap_Toggled
        (Btn    : Button_Widget_Access;
         Active : Boolean)
      is
         pragma Unreferenced (Btn);
      begin
         Apply_Wrap (Active);
      end On_Wrap_Toggled;

      procedure On_File_Selected (Files : Adi.OS.String_Array) is
      begin
         if Files'Length = 0 then
            return;
         end if;
         declare
            Path : constant String := To_String (Files (Files'First));
            File : Ada.Text_IO.File_Type;
            Content : Unbounded_String;
         begin
            Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
            while not Ada.Text_IO.End_Of_File (File) loop
               if Length (Content) > 0 then
                  Append (Content, ASCII.LF);
               end if;
               Append (Content, Ada.Text_IO.Get_Line (File));
            end loop;
            Ada.Text_IO.Close (File);
            Set_Text (Editor.all, To_String (Content));
         end;
      end On_File_Selected;

      procedure On_Open_Click (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
         Txt_Filter : constant Adi.OS.File_Filter_Array :=
           [1 => (Name    => To_Unbounded_String ("Text files"),
                  Pattern => To_Unbounded_String ("txt"))];
      begin
         Adi.OS.Show_Open_File_Dialog
           (Callback => On_File_Selected'Unrestricted_Access,
            Window   => W,
            Filters  => Txt_Filter);
      end On_Open_Click;
   begin
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Controls.all, Controls_Class_Part_Styles);
      Set_Part_Styles (Wrap_Status.all, Wrap_Status_Class_Part_Styles);
      Set_Part_Styles (Wrap_Switch.all, Wrap_Switch_Class_Part_Styles);
      Set_Part_Styles (Editor.all, Editor_Class_Part_Styles);
      Set_Part_Styles (Open_Btn.all, Open_Btn_Class_Part_Styles);
      Open_Btn.Set_On_Clicked (On_Open_Click'Unrestricted_Access);
      Wrap_Switch.Set_On_Toggled (On_Wrap_Toggled'Unrestricted_Access);
      Apply_Wrap (True);
      Set_Context_Menu_Part_Styles (Editor.all, Context_Menu_Class_Part_Styles);
      Set_Context_Menu_Item_Part_Styles (Editor.all, Context_Menu_Item_Class_Part_Styles);

      Root.Add_Child (Title);
      Root.Add_Child (Controls);
      Controls.Add_Child (Open_Btn);
      Controls.Add_Child (Wrap_Status);
      Controls.Add_Child (Wrap_Switch);
      Root.Add_Child (Editor);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Text_Editor_Example;
