with Adi.App;
with Adi.Assets;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;    use Adi.Widget.Box;
with Adi.Widget.Label;  use Adi.Widget.Label;
with Widget_Demo_Styles; use Widget_Demo_Styles;

procedure Widget_Demo is
   A : Adi.App.App;
begin
   A.Init;

   --  Register asset search path so CSS url(bg.jpg) resolves
   Adi.Assets.Add_Path ("examples/assets");

   declare
      W : constant Adi.Window.Window_Handle := Adi.Window.Create_Window_Handle ("Widget Demo", (800.0, 600.0));

      Root_Box   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Top_Row    : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Card_Box   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Card_Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Inner_Box  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Bottom_Row : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_Box : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Hover_Box  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_Box  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Title_Label : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Hello Adi Framework!");
   begin
      Adi.Widget.Box.Set_Part_Styles (Root_Box, Root_Box_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Top_Row, Top_Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Card_Box, Card_Box_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Card_Box_2, Card_Box_2_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Inner_Box, Inner_Box_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Bottom_Row, Bottom_Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Button_Box, Button_Box_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Hover_Box, Hover_Box_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Label_Box, Label_Box_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title_Label, Title_Label_Class_Part_Styles);

      Add_Child (+Card_Box_2, +Inner_Box);

      Add_Child (+Top_Row, +Card_Box);
      Add_Child (+Top_Row, +Card_Box_2);

      Add_Child (+Bottom_Row, +Button_Box);
      Add_Child (+Bottom_Row, +Hover_Box);
      Add_Child (+Bottom_Row, +Label_Box);

      Add_Child (+Root_Box, +Top_Row);
      Add_Child (+Root_Box, +Bottom_Row);
      Add_Child (+Root_Box, +Title_Label);

      Set_Flag (+Button_Box, Clickable, True);
      Set_Flag (+Hover_Box, Clickable, True);
      Set_Flag (+Card_Box, Clickable, True);
      Set_Flag (+Card_Box_2, Clickable, True);
      Set_Flag (+Inner_Box, Clickable, True);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root_Box));
      Set_Enforce_Layout_Min_Size (W, True);
      A.Add_Window (W);
      A.Run;
   end;
end Widget_Demo;
