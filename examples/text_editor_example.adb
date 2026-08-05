pragma Ada_2022;

with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Adi.App;
with Adi.Layout_Util;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.MCP;
with Adi.OS;
with Adi.Window;              use Adi.Window;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;          use Adi.Widget.Box;
with Adi.Widget.Button;       use Adi.Widget.Button;
with Adi.Widget.Button.Switch; use Adi.Widget.Button.Switch;
with Adi.Widget.Label;        use Adi.Widget.Label;
with Adi.Widget.Text_Editor;  use Adi.Widget.Text_Editor;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Text_Editor_Example_Styles; use Text_Editor_Example_Styles;

procedure Text_Editor_Example is
   A : Adi.App.App;

   Sample_Text : constant String :=
     "-- Multiline Text Editor Demo" & ASCII.LF &
     "-- Use the Wrap switch to toggle word wrap, Read Only to lock editing." & ASCII.LF &
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
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("Text Editor Example", (800.0, 600.0));

      Root   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Title  : constant Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Multiline Text Editor");
      Controls : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Wrap_Status : constant Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Wrap: ON");
      Wrap_Switch : constant Adi.Widget.Button.Switch.Switch_Handle :=
        Adi.Widget.Button.Switch.Create_Handle (True);
      RO_Status : constant Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Read Only: OFF");
      RO_Switch : constant Adi.Widget.Button.Switch.Switch_Handle :=
        Adi.Widget.Button.Switch.Create_Handle (False);
      Open_Btn : constant Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Open File");
      Editor : constant Text_Editor_Handle :=
        Adi.Widget.Text_Editor.Create_Handle (Sample_Text);

      Wrap_On_Label_Widget : constant Widget_Style :=
        From (Editor_Class_Text_Base_Style).Build;
      Wrap_Off_Label_Widget : constant Widget_Style :=
        From
          (Merge
             (Editor_Class_Text_Base_Style,
              (White_Space    => Set (WS_Nowrap),
               Text_Wrap_Mode => Set (TWM_Nowrap),
               others => <>)))
        .Build;

      procedure Apply_Wrap (Active : Boolean) is
      begin
         if Active then
            Set_Part_Style (+Editor, Text_Part, Wrap_On_Label_Widget);
            Set_Text (Wrap_Status, "Wrap: ON");
         else
            Set_Part_Style (+Editor, Text_Part, Wrap_Off_Label_Widget);
            Set_Text (Wrap_Status, "Wrap: OFF");
         end if;
      end Apply_Wrap;

      procedure On_Wrap_Toggled
        (W      : Widget_Handle;
         Active : Boolean)
      is
         pragma Unreferenced (W);
      begin
         Apply_Wrap (Active);
      end On_Wrap_Toggled;

      procedure On_RO_Toggled
        (W      : Widget_Handle;
         Active : Boolean)
      is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Text_Editor.Set_Read_Only (Editor, Active);
         if Active then
            Set_Text (RO_Status, "Read Only: ON");
         else
            Set_Text (RO_Status, "Read Only: OFF");
         end if;
      end On_RO_Toggled;

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
            if Path'Length = 0 then
               return;
            end if;
            Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
            while not Ada.Text_IO.End_Of_File (File) loop
               if Length (Content) > 0 then
                  Append (Content, ASCII.LF);
               end if;
               Append (Content, Ada.Text_IO.Get_Line (File));
            end loop;
            Ada.Text_IO.Close (File);
            Adi.Widget.Text_Editor.Set_Text (Editor, To_String (Content));
         exception
            when others =>
               if Ada.Text_IO.Is_Open (File) then
                  Ada.Text_IO.Close (File);
               end if;
         end;
      end On_File_Selected;

      procedure On_Open_Click (Sender : Widget_Handle) is
         pragma Unreferenced (Sender);
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
      Set_Part_Styles (+Root, Root_Class_Part_Styles);
      Set_Part_Styles (+Title, Title_Class_Part_Styles);
      Set_Part_Styles (+Controls, Controls_Class_Part_Styles);
      Set_Part_Styles (+Wrap_Status, Wrap_Status_Class_Part_Styles);
      Adi.Widget.Button.Switch.Set_Part_Styles (Wrap_Switch, Wrap_Switch_Class_Part_Styles);
      Set_Part_Styles (+RO_Status, Ro_Status_Class_Part_Styles);
      Adi.Widget.Button.Switch.Set_Part_Styles (RO_Switch, Ro_Switch_Class_Part_Styles);
      Set_Part_Styles (+Editor, Editor_Class_Part_Styles);
      Connect_Clicked (Open_Btn, On_Open_Click'Unrestricted_Access);
      Adi.Widget.Button.Switch.Connect_Toggled (Wrap_Switch, On_Wrap_Toggled'Unrestricted_Access);
      Adi.Widget.Button.Switch.Connect_Toggled (RO_Switch, On_RO_Toggled'Unrestricted_Access);
      Set_Part_Styles (+Open_Btn, Open_Btn_Class_Part_Styles);
      Apply_Wrap (True);
      Set_Context_Menu_Part_Styles (Editor, Context_Menu_Class_Part_Styles);
      Set_Context_Menu_Item_Part_Styles (Editor, Context_Menu_Item_Class_Part_Styles);

      Add_Child (+Root, +Title);
      Add_Child (+Root, +Controls);
      Add_Child (+Controls, +Open_Btn);
      Add_Child (+Controls, +Wrap_Status);
      Add_Child (+Controls, +Wrap_Switch);
      Add_Child (+Controls, +RO_Status);
      Add_Child (+Controls, +RO_Switch);
      Add_Child (+Root, +Editor);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Text_Editor_Example;
