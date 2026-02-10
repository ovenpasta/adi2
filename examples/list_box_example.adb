pragma Ada_2022;
with Ada.Text_IO;            use Ada.Text_IO;
with Adi.App;
with Adi.Window;             use Adi.Window;
with Adi.Widget;             use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with List_Box_Example_Styles; use List_Box_Example_Styles;

procedure List_Box_Example is
   A : Adi.App.App;

   package Label_List is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget,
      Adi.Widget.Label.Label_Widget_Access);

   package Box_List is new Adi.Widget.List_Box
     (Adi.Widget.Box.Box_Widget,
      Adi.Widget.Box.Box_Widget_Access);

   Single_Status : Adi.Widget.Label.Label_Widget_Access;
   Multi_Status  : Adi.Widget.Label.Label_Widget_Access;

   procedure On_Label_Click
     (W      : Label_List.List_Box_Widget_Access;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Single_Status.Set_Text
        ("Label list: clicked " & Index'Image & " (" & Clicks'Image & "x)");
      Put_Line ("Label list click: row" & Index'Image & ", clicks=" & Clicks'Image);
   end On_Label_Click;

   procedure On_Label_Activate
     (W     : Label_List.List_Box_Widget_Access;
      Index : Positive)
   is
      pragma Unreferenced (W);
   begin
      Single_Status.Set_Text ("Label list: activated row" & Index'Image);
      Put_Line ("Label list activated row" & Index'Image);
   end On_Label_Activate;

   procedure On_Label_Selection_Changed (W : Label_List.List_Box_Widget_Access) is
   begin
      Single_Status.Set_Text
        ("Label list: selected " & W.Get_Selected_Count'Image & " row(s)");
   end On_Label_Selection_Changed;

   procedure On_Box_Click
     (W      : Box_List.List_Box_Widget_Access;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Multi_Status.Set_Text
        ("Box list: clicked " & Index'Image & " (" & Clicks'Image & "x)");
   end On_Box_Click;

   procedure On_Box_Activate
     (W     : Box_List.List_Box_Widget_Access;
      Index : Positive)
   is
      pragma Unreferenced (W);
   begin
      Multi_Status.Set_Text ("Box list: activated row" & Index'Image);
      Put_Line ("Box list activated row" & Index'Image);
   end On_Box_Activate;

   procedure On_Box_Selection_Changed (W : Box_List.List_Box_Widget_Access) is
   begin
      Multi_Status.Set_Text
        ("Box list: selected " & W.Get_Selected_Count'Image & " row(s)");
   end On_Box_Selection_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("List Box Example", (1980.0, 640.0));

      Root : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Panels : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      No_Panel     : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Single_Panel : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Multi_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Range_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      No_Title     : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("No Selection");
      Single_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Single Selection");
      Multi_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Multi Selection");
      Range_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Range Selection");

      No_Listbox     : constant Label_List.List_Box_Widget_Access := Label_List.Create;
      Single_Listbox : constant Label_List.List_Box_Widget_Access := Label_List.Create;
      Multi_Listbox  : constant Box_List.List_Box_Widget_Access := Box_List.Create;
      Range_Listbox  : constant Label_List.List_Box_Widget_Access := Label_List.Create;

      No_Status    : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create
        ("Click rows: focus/activate works, selection stays off");
      Range_Status : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create
        ("Shift+click/Shift+arrows selects contiguous ranges");
   begin
      Single_Status := Adi.Widget.Label.Create
        ("Label list: click, double-click, arrows, page up/down, mouse wheel");
      Multi_Status := Adi.Widget.Label.Create
        ("Box list: multi-select toggle, wheel scroll, keyboard navigation");

      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Panels.all, Panels_Class_Part_Styles);
      Set_Part_Styles (No_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Single_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Multi_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Range_Panel.all, Panel_Class_Part_Styles);

      Set_Part_Styles (No_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Single_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Multi_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Range_Title.all, Panel_Title_Class_Part_Styles);

      Set_Part_Styles (No_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Single_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Multi_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Range_Status.all, Status_Class_Part_Styles);

      Set_Part_Styles (No_Listbox.all, Listbox_Class_Part_Styles);
      Set_Part_Styles (Single_Listbox.all, Listbox_Class_Part_Styles);
      Set_Part_Styles (Multi_Listbox.all, Listbox_Class_Part_Styles);
      Set_Part_Styles (Range_Listbox.all, Listbox_Class_Part_Styles);

      No_Listbox.Set_Row_Gap (4.0);
      Single_Listbox.Set_Row_Gap (4.0);
      Multi_Listbox.Set_Row_Gap (6.0);
      Range_Listbox.Set_Row_Gap (4.0);

      No_Listbox.Set_Selection_Mode (Label_List.No_Selection);
      Single_Listbox.Set_Selection_Mode (Label_List.Single_Selection);
      Multi_Listbox.Set_Selection_Mode (Box_List.Multi_Selection);
      Range_Listbox.Set_Selection_Mode (Label_List.Range_Selection);

      Single_Listbox.Set_On_Item_Clicked (On_Label_Click'Unrestricted_Access);
      Single_Listbox.Set_On_Item_Activated (On_Label_Activate'Unrestricted_Access);
      Single_Listbox.Set_On_Selection_Changed
        (On_Label_Selection_Changed'Unrestricted_Access);

      Multi_Listbox.Set_On_Item_Clicked (On_Box_Click'Unrestricted_Access);
      Multi_Listbox.Set_On_Item_Activated (On_Box_Activate'Unrestricted_Access);
      Multi_Listbox.Set_On_Selection_Changed
        (On_Box_Selection_Changed'Unrestricted_Access);

      --  Fill no/single/range label lists
      for I in 1 .. 40 loop
         declare
            Row : constant Adi.Widget.Label.Label_Widget_Access :=
              Adi.Widget.Label.Create ("Label row" & I'Image);
            Row_No : constant Adi.Widget.Label.Label_Widget_Access :=
              Adi.Widget.Label.Create ("Label row" & I'Image);
            Row_Range : constant Adi.Widget.Label.Label_Widget_Access :=
              Adi.Widget.Label.Create ("Label row" & I'Image);
         begin
            Set_Part_Styles (Row.all, Label_Row_Class_Part_Styles);
            Set_Part_Styles (Row_No.all, Label_Row_Class_Part_Styles);
            Set_Part_Styles (Row_Range.all, Label_Row_Class_Part_Styles);

            Single_Listbox.Append_Row (Row);
            No_Listbox.Append_Row (Row_No);
            Range_Listbox.Append_Row (Row_Range);
         end;
      end loop;

      --  Fill box list with more complex row widgets
      for I in 1 .. 35 loop
         declare
            Row : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
            Title : constant Adi.Widget.Label.Label_Widget_Access :=
              Adi.Widget.Label.Create ("Card row" & I'Image & "  (double-click to activate)");
         begin
            Set_Part_Styles (Row.all, Card_Row_Class_Part_Styles);
            Set_Part_Styles (Title.all, Card_Row_Title_Class_Part_Styles);

            Row.Add_Child (Title);
            Multi_Listbox.Append_Row (Row);
         end;
      end loop;

      --  Assemble hierarchy
      No_Panel.Add_Child (No_Title);
      No_Panel.Add_Child (No_Status);
      No_Panel.Add_Child (No_Listbox);

      Single_Panel.Add_Child (Single_Title);
      Single_Panel.Add_Child (Single_Status);
      Single_Panel.Add_Child (Single_Listbox);

      Multi_Panel.Add_Child (Multi_Title);
      Multi_Panel.Add_Child (Multi_Status);
      Multi_Panel.Add_Child (Multi_Listbox);

      Range_Panel.Add_Child (Range_Title);
      Range_Panel.Add_Child (Range_Status);
      Range_Panel.Add_Child (Range_Listbox);

      Panels.Add_Child (No_Panel);
      Panels.Add_Child (Single_Panel);
      Panels.Add_Child (Multi_Panel);
      Panels.Add_Child (Range_Panel);
      Root.Add_Child (Panels);

      --  Initial selection
      Single_Listbox.Select_Row (2);
      Multi_Listbox.Toggle_Row_Selected (1);
      Multi_Listbox.Toggle_Row_Selected (3);
      Range_Listbox.Select_Row (4);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end List_Box_Example;
