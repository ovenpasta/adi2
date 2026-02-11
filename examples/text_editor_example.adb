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
     "" & ASCII.LF &
     "with Ada.Text_IO; use Ada.Text_IO;" & ASCII.LF &
     "" & ASCII.LF &
     "procedure Hello is" & ASCII.LF &
     "begin" & ASCII.LF &
     "   Put_Line (""Hello, world!"");" & ASCII.LF &
     "" & ASCII.LF &
     "   for I in 1 .. 10 loop" & ASCII.LF &
     "      Put_Line (""  Item"" & Integer'Image (I));" & ASCII.LF &
     "   end loop;" & ASCII.LF &
     "" & ASCII.LF &
     "   -- More lines to demonstrate scrolling" & ASCII.LF &
     "   declare" & ASCII.LF &
     "      X : constant Integer := 42;" & ASCII.LF &
     "      Y : constant Integer := X * 2;" & ASCII.LF &
     "   begin" & ASCII.LF &
     "      Put_Line (Integer'Image (Y));" & ASCII.LF &
     "   end;" & ASCII.LF &
     "" & ASCII.LF &
     "   -- Navigation:" & ASCII.LF &
     "   --   Arrow keys, Home/End, Page Up/Down" & ASCII.LF &
     "   --   Ctrl+Home/End for start/end of buffer" & ASCII.LF &
     "   --   Shift+arrows for selection" & ASCII.LF &
     "   --   Double-click for word select" & ASCII.LF &
     "   --   Triple-click for line select" & ASCII.LF &
     "   --   Mouse wheel for scrolling" & ASCII.LF &
     "end Hello;";

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

      Root.Add_Child (Title);
      Root.Add_Child (Editor);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Text_Editor_Example;
