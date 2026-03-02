pragma Ada_2022;
with Adi.Log;
with Adi.App;
with Adi.Window;             use Adi.Window;
with Adi.Widget;             use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;      use Adi.Widget.Button;
with Adi.Widget.Button.Switch;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.CSS_Source;
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
   Main_Window   : Window_Access;

   procedure On_Label_Click
     (W      : Label_List.List_Box_Widget_Access;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Single_Status.Set_Text
        ("Label list: clicked " & Index'Image & " (" & Clicks'Image & "x)");
      Adi.Log.Info ("Label list click: row" & Index'Image & ", clicks=" & Clicks'Image);
   end On_Label_Click;

   procedure On_Label_Activate
     (W     : Label_List.List_Box_Widget_Access;
      Index : Positive)
   is
      pragma Unreferenced (W);
   begin
      Single_Status.Set_Text ("Label list: activated row" & Index'Image);
      Adi.Log.Info ("Label list activated row" & Index'Image);
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
      Adi.Log.Info ("Box list activated row" & Index'Image);
   end On_Box_Activate;

   procedure On_Box_Selection_Changed (W : Box_List.List_Box_Widget_Access) is
   begin
      Multi_Status.Set_Text
        ("Box list: selected " & W.Get_Selected_Count'Image & " row(s)");
   end On_Box_Selection_Changed;

   Grid_Status : Adi.Widget.Label.Label_Widget_Access;

   procedure On_Grid_Click
     (W      : Label_List.List_Box_Widget_Access;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Grid_Status.Set_Text
        ("Grid: clicked " & Index'Image & " (" & Clicks'Image & "x)");
   end On_Grid_Click;

   procedure On_Grid_Selection_Changed (W : Label_List.List_Box_Widget_Access) is
   begin
      Grid_Status.Set_Text
        ("Grid: selected " & W.Get_Selected_Count'Image & " cell(s)");
   end On_Grid_Selection_Changed;

   procedure On_Inertia_Toggled (Btn : Button_Widget_Access; Active : Boolean) is
      pragma Unreferenced (Btn);
   begin
      Set_Scroll_Inertia_Enabled (Active);
      if Active then
         Adi.Log.Info ("Scroll inertia enabled");
      else
         Adi.Log.Info ("Scroll inertia disabled");
      end if;
   end On_Inertia_Toggled;

   procedure On_Debug_Overlay_Toggled
     (Btn : Button_Widget_Access;
      Active : Boolean)
   is
      pragma Unreferenced (Btn);
   begin
      Set_Debug_Layout_Overlay_Enabled (Active);
      if Active then
         Adi.Log.Info ("Layout debug overlay enabled");
      else
         Adi.Log.Info ("Layout debug overlay disabled");
      end if;
   end On_Debug_Overlay_Toggled;

   procedure On_Debug_Stats_Toggled
     (Btn : Button_Widget_Access;
      Active : Boolean)
   is
      pragma Unreferenced (Btn);
   begin
      Main_Window.Set_Debug_Stats (Active);
   end On_Debug_Stats_Toggled;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("List Box Example", (1980.0, 640.0));

      Root : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Controls_Row : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Panels : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      No_Panel     : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Single_Panel : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Multi_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Range_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Grid_Panel   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      No_Title     : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("No Selection");
      Inertia_Switch_Label : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Scroll inertia");
      Inertia_Switch : constant Adi.Widget.Button.Switch.Switch_Widget_Access :=
        Adi.Widget.Button.Switch.Create (False);
      Debug_Overlay_Label : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Layout debug");
      Debug_Overlay_Switch : constant Adi.Widget.Button.Switch.Switch_Widget_Access :=
        Adi.Widget.Button.Switch.Create (False);
      Debug_Stats_Label : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Debug stats");
      Debug_Stats_Switch : constant Adi.Widget.Button.Switch.Switch_Widget_Access :=
        Adi.Widget.Button.Switch.Create (True);
      Single_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Single Selection");
      Multi_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Multi Selection");
      Range_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Range Selection");
      Grid_Title   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Grid Layout");

      No_Listbox     : constant Label_List.List_Box_Widget_Access := Label_List.Create;
      Single_Listbox : constant Label_List.List_Box_Widget_Access := Label_List.Create;
      Multi_Listbox  : constant Box_List.List_Box_Widget_Access := Box_List.Create;
      Range_Listbox  : constant Label_List.List_Box_Widget_Access := Label_List.Create;
      Grid_Listbox   : constant Label_List.List_Box_Widget_Access := Label_List.Create;

      No_Status    : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create
        ("Click rows: focus/activate works, selection stays off");
      Range_Status : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create
        ("Shift+click/Shift+arrows selects contiguous ranges");
   begin
      Single_Status := Adi.Widget.Label.Create
        ("Label list: click, double-click, arrows, page up/down, mouse wheel");
      Multi_Status := Adi.Widget.Label.Create
        ("Box list: multi-select toggle, wheel scroll, keyboard navigation");
      Grid_Status := Adi.Widget.Label.Create
        ("Grid: 3 columns, arrow keys navigate, click to select");
      Main_Window := W;
      Set_Scroll_Inertia_Enabled (False);
      Set_Debug_Layout_Overlay_Enabled (False);
      W.Set_Debug_Stats (True);

      Inertia_Switch.Connect_Toggled (On_Inertia_Toggled'Unrestricted_Access);
      Debug_Overlay_Switch.Connect_Toggled
        (On_Debug_Overlay_Toggled'Unrestricted_Access);
      Debug_Stats_Switch.Connect_Toggled
        (On_Debug_Stats_Toggled'Unrestricted_Access);

      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Controls_Row.all, Controls_Row_Class_Part_Styles);
      Set_Part_Styles (Panels.all, Panels_Class_Part_Styles);
      Set_Part_Styles (No_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Single_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Multi_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Range_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Grid_Panel.all, Panel_Class_Part_Styles);

      Set_Part_Styles (No_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Inertia_Switch_Label.all, Inertia_Label_Class_Part_Styles);
      Set_Part_Styles (Inertia_Switch.all, Inertia_Switch_Class_Part_Styles);
      Set_Part_Styles (Debug_Overlay_Label.all, Debug_Label_Class_Part_Styles);
      Set_Part_Styles (Debug_Overlay_Switch.all, Debug_Switch_Class_Part_Styles);
      Set_Part_Styles (Debug_Stats_Label.all, Debug_Label_Class_Part_Styles);
      Set_Part_Styles (Debug_Stats_Switch.all, Debug_Switch_Class_Part_Styles);
      Set_Part_Styles (Single_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Multi_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Range_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Grid_Title.all, Panel_Title_Class_Part_Styles);

      Set_Part_Styles (No_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Single_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Multi_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Range_Status.all, Status_Class_Part_Styles);
      Set_Part_Styles (Grid_Status.all, Status_Class_Part_Styles);

      Set_Part_Styles (No_Listbox.all, Listbox_Class_Part_Styles);
      Set_Part_Styles (Single_Listbox.all, Listbox_Class_Part_Styles);
      Set_Part_Styles (Multi_Listbox.all, Adi.CSS_Source.Merge_Part_Styles
        (Listbox_Class_Part_Styles, Listbox_Multi_Class_Part_Styles));
      Set_Part_Styles (Range_Listbox.all, Listbox_Class_Part_Styles);
      Set_Part_Styles (Grid_Listbox.all, Adi.CSS_Source.Merge_Part_Styles
        (Listbox_Class_Part_Styles, Listbox_Grid_Class_Part_Styles));

      No_Listbox.Set_Selection_Mode (Label_List.No_Selection);
      Single_Listbox.Set_Selection_Mode (Label_List.Single_Selection);
      Multi_Listbox.Set_Selection_Mode (Box_List.Multi_Selection);
      Range_Listbox.Set_Selection_Mode (Label_List.Range_Selection);
      Grid_Listbox.Set_Selection_Mode (Label_List.Single_Selection);

      Single_Listbox.Connect_Item_Clicked (On_Label_Click'Unrestricted_Access);
      Single_Listbox.Connect_Item_Activated (On_Label_Activate'Unrestricted_Access);
      Single_Listbox.Connect_Selection_Changed
        (On_Label_Selection_Changed'Unrestricted_Access);

      Multi_Listbox.Connect_Item_Clicked (On_Box_Click'Unrestricted_Access);
      Multi_Listbox.Connect_Item_Activated (On_Box_Activate'Unrestricted_Access);
      Multi_Listbox.Connect_Selection_Changed
        (On_Box_Selection_Changed'Unrestricted_Access);

      Grid_Listbox.Connect_Item_Clicked (On_Grid_Click'Unrestricted_Access);
      Grid_Listbox.Connect_Selection_Changed
        (On_Grid_Selection_Changed'Unrestricted_Access);

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

      --  Fill grid list
      for I in 1 .. 64 loop
         declare
            Cell : constant Adi.Widget.Label.Label_Widget_Access :=
              Adi.Widget.Label.Create ("Cell" & I'Image);
         begin
            Set_Part_Styles (Cell.all, Grid_Cell_Class_Part_Styles);
            Grid_Listbox.Append_Row (Cell);
         end;
      end loop;

      --  Assemble hierarchy
      Controls_Row.Add_Child (Inertia_Switch_Label);
      Controls_Row.Add_Child (Inertia_Switch);
      Controls_Row.Add_Child (Debug_Overlay_Label);
      Controls_Row.Add_Child (Debug_Overlay_Switch);
      Controls_Row.Add_Child (Debug_Stats_Label);
      Controls_Row.Add_Child (Debug_Stats_Switch);

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

      Grid_Panel.Add_Child (Grid_Title);
      Grid_Panel.Add_Child (Grid_Status);
      Grid_Panel.Add_Child (Grid_Listbox);

      Panels.Add_Child (No_Panel);
      Panels.Add_Child (Single_Panel);
      Panels.Add_Child (Multi_Panel);
      Panels.Add_Child (Range_Panel);
      Panels.Add_Child (Grid_Panel);
      Root.Add_Child (Controls_Row);
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
