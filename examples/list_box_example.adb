pragma Ada_2022;
with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Log;
with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;             use Adi.Window;
with Adi.Widget;             use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button.Switch;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.CSS_Source;
with List_Box_Example_Styles; use List_Box_Example_Styles;

procedure List_Box_Example is
   A : Adi.App.App;

   package Label_List is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget);

   package Box_List is new Adi.Widget.List_Box
     (Adi.Widget.Box.Box_Widget);

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Widget.Button.Switch.Switch_Handle;
   use type Label_List.List_Box_Handle;
   use type Box_List.List_Box_Handle;

   Single_Status : Adi.Widget.Label.Label_Handle;
   Multi_Status  : Adi.Widget.Label.Label_Handle;
   Main_Window   : Window_Handle;

   procedure On_Label_Click
     (W      : Widget_Handle;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Single_Status,
         "Label list: clicked " & Index'Image & " (" & Clicks'Image & "x)");
      Adi.Log.Info ("Label list click: row" & Index'Image & ", clicks=" & Clicks'Image);
   end On_Label_Click;

   procedure On_Label_Activate
     (W     : Widget_Handle;
      Index : Positive)
   is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Single_Status, "Label list: activated row" & Index'Image);
      Adi.Log.Info ("Label list activated row" & Index'Image);
   end On_Label_Activate;

   procedure On_Label_Selection_Changed (W : Widget_Handle) is
      H : constant Label_List.List_Box_Handle := Label_List.Try_As_List_Box (W);
   begin
      Adi.Widget.Label.Set_Text
        (Single_Status,
         "Label list: selected " &
         Label_List.Get_Selected_Count (H)'Image &
         " row(s)");
   end On_Label_Selection_Changed;

   procedure On_Box_Click
     (W      : Widget_Handle;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Multi_Status,
         "Box list: clicked " & Index'Image & " (" & Clicks'Image & "x)");
   end On_Box_Click;

   procedure On_Box_Activate
     (W     : Widget_Handle;
      Index : Positive)
   is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Multi_Status, "Box list: activated row" & Index'Image);
      Adi.Log.Info ("Box list activated row" & Index'Image);
   end On_Box_Activate;

   procedure On_Box_Selection_Changed (W : Widget_Handle) is
      H : constant Box_List.List_Box_Handle := Box_List.Try_As_List_Box (W);
   begin
      Adi.Widget.Label.Set_Text
        (Multi_Status,
         "Box list: selected " &
         Box_List.Get_Selected_Count (H)'Image &
         " row(s)");
   end On_Box_Selection_Changed;

   Grid_Status : Adi.Widget.Label.Label_Handle;

   procedure On_Grid_Click
     (W      : Widget_Handle;
      Index  : Positive;
      Clicks : Natural)
   is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Grid_Status,
         "Grid: clicked " & Index'Image & " (" & Clicks'Image & "x)");
   end On_Grid_Click;

   procedure On_Grid_Selection_Changed (W : Widget_Handle) is
      H : constant Label_List.List_Box_Handle := Label_List.Try_As_List_Box (W);
   begin
      Adi.Widget.Label.Set_Text
        (Grid_Status,
         "Grid: selected " &
         Label_List.Get_Selected_Count (H)'Image &
         " cell(s)");
   end On_Grid_Selection_Changed;

   procedure On_Inertia_Toggled (W : Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
   begin
      Set_Scroll_Inertia_Enabled (Active);
      if Active then
         Adi.Log.Info ("Scroll inertia enabled");
      else
         Adi.Log.Info ("Scroll inertia disabled");
      end if;
   end On_Inertia_Toggled;

   procedure On_Debug_Overlay_Toggled
     (W      : Widget_Handle;
      Active : Boolean)
   is
      pragma Unreferenced (W);
   begin
      Set_Debug_Layout_Overlay_Enabled (Active);
      if Active then
         Adi.Log.Info ("Layout debug overlay enabled");
      else
         Adi.Log.Info ("Layout debug overlay disabled");
      end if;
   end On_Debug_Overlay_Toggled;

   procedure On_Debug_Stats_Toggled
     (W      : Widget_Handle;
      Active : Boolean)
   is
      pragma Unreferenced (W);
   begin
      Adi.Window.Set_Debug_Stats (Main_Window, Active);
   end On_Debug_Stats_Toggled;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle := Create_Window_Handle ("List Box Example", Adi.Window.Extent (Px (1358.0), Px (439.0)));

      Root         : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Controls_Row : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Panels       : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      No_Panel     : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Single_Panel : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Multi_Panel  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Range_Panel  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Grid_Panel   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      No_Title     : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("No Selection");
      Inertia_Switch_Label : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Scroll inertia");
      Inertia_Switch : constant Adi.Widget.Button.Switch.Switch_Handle :=
        Adi.Widget.Button.Switch.Create_Handle (False);
      Debug_Overlay_Label : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Layout debug");
      Debug_Overlay_Switch : constant Adi.Widget.Button.Switch.Switch_Handle :=
        Adi.Widget.Button.Switch.Create_Handle (False);
      Debug_Stats_Label : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Debug stats");
      Debug_Stats_Switch : constant Adi.Widget.Button.Switch.Switch_Handle :=
        Adi.Widget.Button.Switch.Create_Handle (True);
      Single_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Single Selection");
      Multi_Title  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Multi Selection");
      Range_Title  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Range Selection");
      Grid_Title   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Grid Layout");

      No_Listbox     : constant Label_List.List_Box_Handle := Label_List.Create_Handle;
      Single_Listbox : constant Label_List.List_Box_Handle := Label_List.Create_Handle;
      Multi_Listbox  : constant Box_List.List_Box_Handle   := Box_List.Create_Handle;
      Range_Listbox  : constant Label_List.List_Box_Handle := Label_List.Create_Handle;
      Grid_Listbox   : constant Label_List.List_Box_Handle := Label_List.Create_Handle;

      No_Status    : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Click rows: focus/activate works, selection stays off");
      Range_Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Shift+click/Shift+arrows selects contiguous ranges");
   begin
      Single_Status := Adi.Widget.Label.Create_Handle
        ("Label list: click, double-click, arrows, page up/down, mouse wheel");
      Multi_Status := Adi.Widget.Label.Create_Handle
        ("Box list: multi-select toggle, wheel scroll, keyboard navigation");
      Grid_Status := Adi.Widget.Label.Create_Handle
        ("Grid: 3 columns, arrow keys navigate, click to select");
      Main_Window := W;
      Set_Scroll_Inertia_Enabled (False);
      Set_Debug_Layout_Overlay_Enabled (False);
      Adi.Window.Set_Debug_Stats (W, True);

      Adi.Widget.Button.Switch.Connect_Toggled
        (Inertia_Switch, On_Inertia_Toggled'Unrestricted_Access);
      Adi.Widget.Button.Switch.Connect_Toggled
        (Debug_Overlay_Switch, On_Debug_Overlay_Toggled'Unrestricted_Access);
      Adi.Widget.Button.Switch.Connect_Toggled
        (Debug_Stats_Switch, On_Debug_Stats_Toggled'Unrestricted_Access);

      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Controls_Row, Controls_Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Panels, Panels_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (No_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Single_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Multi_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Range_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Grid_Panel, Panel_Class_Part_Styles);

      Adi.Widget.Label.Set_Part_Styles (No_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Inertia_Switch_Label, Inertia_Label_Class_Part_Styles);
      Adi.Widget.Button.Switch.Set_Part_Styles
        (Inertia_Switch, Inertia_Switch_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Debug_Overlay_Label, Debug_Label_Class_Part_Styles);
      Adi.Widget.Button.Switch.Set_Part_Styles
        (Debug_Overlay_Switch, Debug_Switch_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Debug_Stats_Label, Debug_Label_Class_Part_Styles);
      Adi.Widget.Button.Switch.Set_Part_Styles
        (Debug_Stats_Switch, Debug_Switch_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Single_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Multi_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Range_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Grid_Title, Panel_Title_Class_Part_Styles);

      Adi.Widget.Label.Set_Part_Styles (No_Status, Status_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Single_Status, Status_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Multi_Status, Status_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Range_Status, Status_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Grid_Status, Status_Class_Part_Styles);

      Label_List.Set_Part_Styles (No_Listbox, Listbox_Class_Part_Styles);
      Label_List.Set_Part_Styles (Single_Listbox, Listbox_Class_Part_Styles);
      Box_List.Set_Part_Styles (Multi_Listbox, Adi.CSS_Source.Merge_Part_Styles
        (Listbox_Class_Part_Styles, Listbox_Multi_Class_Part_Styles));
      Label_List.Set_Part_Styles (Range_Listbox, Listbox_Class_Part_Styles);
      Label_List.Set_Part_Styles (Grid_Listbox, Adi.CSS_Source.Merge_Part_Styles
        (Listbox_Class_Part_Styles, Listbox_Grid_Class_Part_Styles));

      Label_List.Set_Selection_Mode (No_Listbox, Label_List.No_Selection);
      Label_List.Set_Selection_Mode (Single_Listbox, Label_List.Single_Selection);
      Box_List.Set_Selection_Mode (Multi_Listbox, Box_List.Multi_Selection);
      Label_List.Set_Selection_Mode (Range_Listbox, Label_List.Range_Selection);
      Label_List.Set_Selection_Mode (Grid_Listbox, Label_List.Single_Selection);

      Label_List.Connect_Item_Clicked
        (Single_Listbox, On_Label_Click'Unrestricted_Access);
      Label_List.Connect_Item_Activated
        (Single_Listbox, On_Label_Activate'Unrestricted_Access);
      Label_List.Connect_Selection_Changed
        (Single_Listbox, On_Label_Selection_Changed'Unrestricted_Access);

      Box_List.Connect_Item_Clicked
        (Multi_Listbox, On_Box_Click'Unrestricted_Access);
      Box_List.Connect_Item_Activated
        (Multi_Listbox, On_Box_Activate'Unrestricted_Access);
      Box_List.Connect_Selection_Changed
        (Multi_Listbox, On_Box_Selection_Changed'Unrestricted_Access);

      Label_List.Connect_Item_Clicked
        (Grid_Listbox, On_Grid_Click'Unrestricted_Access);
      Label_List.Connect_Selection_Changed
        (Grid_Listbox, On_Grid_Selection_Changed'Unrestricted_Access);

      --  Fill no/single/range label lists
      for I in 1 .. 40 loop
         declare
            Row       : constant Adi.Widget.Label.Label_Handle :=
              Adi.Widget.Label.Create_Handle ("Label row" & I'Image);
            Row_No    : constant Adi.Widget.Label.Label_Handle :=
              Adi.Widget.Label.Create_Handle ("Label row" & I'Image);
            Row_Range : constant Adi.Widget.Label.Label_Handle :=
              Adi.Widget.Label.Create_Handle ("Label row" & I'Image);
         begin
            Adi.Widget.Label.Set_Part_Styles (Row, Label_Row_Class_Part_Styles);
            Adi.Widget.Label.Set_Part_Styles (Row_No, Label_Row_Class_Part_Styles);
            Adi.Widget.Label.Set_Part_Styles (Row_Range, Label_Row_Class_Part_Styles);

            Label_List.Append_Row (Single_Listbox, +Row);
            Label_List.Append_Row (No_Listbox, +Row_No);
            Label_List.Append_Row (Range_Listbox, +Row_Range);
         end;
      end loop;

      --  Fill box list with more complex row widgets
      for I in 1 .. 35 loop
         declare
            Row   : constant Adi.Widget.Box.Box_Handle :=
              Adi.Widget.Box.Create_Handle;
            Title : constant Adi.Widget.Label.Label_Handle :=
              Adi.Widget.Label.Create_Handle
                ("Card row" & I'Image & "  (double-click to activate)");
         begin
            Adi.Widget.Box.Set_Part_Styles (Row, Card_Row_Class_Part_Styles);
            Adi.Widget.Label.Set_Part_Styles (Title, Card_Row_Title_Class_Part_Styles);

            Add_Child (+Row, +Title);
            Box_List.Append_Row (Multi_Listbox, +Row);
         end;
      end loop;

      --  Fill grid list
      for I in 1 .. 64 loop
         declare
            Cell : constant Adi.Widget.Label.Label_Handle :=
              Adi.Widget.Label.Create_Handle ("Cell" & I'Image);
         begin
            Adi.Widget.Label.Set_Part_Styles (Cell, Grid_Cell_Class_Part_Styles);
            Label_List.Append_Row (Grid_Listbox, +Cell);
         end;
      end loop;

      --  Assemble hierarchy
      Add_Child (+Controls_Row, +Inertia_Switch_Label);
      Add_Child (+Controls_Row, +Inertia_Switch);
      Add_Child (+Controls_Row, +Debug_Overlay_Label);
      Add_Child (+Controls_Row, +Debug_Overlay_Switch);
      Add_Child (+Controls_Row, +Debug_Stats_Label);
      Add_Child (+Controls_Row, +Debug_Stats_Switch);

      Add_Child (+No_Panel, +No_Title);
      Add_Child (+No_Panel, +No_Status);
      Add_Child (+No_Panel, +No_Listbox);

      Add_Child (+Single_Panel, +Single_Title);
      Add_Child (+Single_Panel, +Single_Status);
      Add_Child (+Single_Panel, +Single_Listbox);

      Add_Child (+Multi_Panel, +Multi_Title);
      Add_Child (+Multi_Panel, +Multi_Status);
      Add_Child (+Multi_Panel, +Multi_Listbox);

      Add_Child (+Range_Panel, +Range_Title);
      Add_Child (+Range_Panel, +Range_Status);
      Add_Child (+Range_Panel, +Range_Listbox);

      Add_Child (+Grid_Panel, +Grid_Title);
      Add_Child (+Grid_Panel, +Grid_Status);
      Add_Child (+Grid_Panel, +Grid_Listbox);

      Add_Child (+Panels, +No_Panel);
      Add_Child (+Panels, +Single_Panel);
      Add_Child (+Panels, +Multi_Panel);
      Add_Child (+Panels, +Range_Panel);
      Add_Child (+Panels, +Grid_Panel);
      Add_Child (+Root, +Controls_Row);
      Add_Child (+Root, +Panels);

      --  Initial selection
      Label_List.Select_Row (Single_Listbox, 2);
      Box_List.Toggle_Row_Selected (Multi_Listbox, 1);
      Box_List.Toggle_Row_Selected (Multi_Listbox, 3);
      Label_List.Select_Row (Range_Listbox, 4);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end List_Box_Example;
