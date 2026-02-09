with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Image;
with Widget_Demo_Styles; use Widget_Demo_Styles;

procedure Widget_Demo is
   A : Adi.App.App;
   use type Adi.Image.Image_Access;
begin
   A.Init;

   declare
      W : constant Adi.Window.Window_Access := Adi.Window.Create_Window ("Widget Demo", (800.0, 600.0));

      Root_Box   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Top_Row    : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Card_Box   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Card_Box_2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Inner_Box  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Bottom_Row : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Button_Box : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Hover_Box  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_Box  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Title_Label : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Hello Adi Framework!");
      Bg : Adi.Image.Image_Access;
      Bg_Style : Opt_Bg_Image.Optional;
   begin
      Bg := W.Load_Image ("examples/bg.jpg");
      if Bg /= null then
         Bg_Style := Set_Bg_Image (Background_Image (Bg));
      else
         Bg_Style := Opt_Bg_Image.Unset;
      end if;

      Set_Part_Styles (Root_Box.all, Root_Box_Part_Styles);
      Set_Part_Styles (Top_Row.all, Top_Row_Part_Styles);
      Set_Part_Styles (Card_Box.all, Card_Box_Part_Styles);
      Set_Part_Styles (Card_Box_2.all, Card_Box_2_Part_Styles);
      Set_Part_Styles (Inner_Box.all, Inner_Box_Part_Styles);
      Set_Part_Styles (Bottom_Row.all, Bottom_Row_Part_Styles);
      Set_Part_Styles (Button_Box.all, Button_Box_Part_Styles);
      Set_Part_Styles (Hover_Box.all, Hover_Box_Part_Styles);
      Set_Part_Style (Label_Box.all, Main_Part,
        Create.Base ((Label_Box_Base_Style with delta
          Background_Image => Bg_Style))
        .Build);
      Set_Part_Styles (Title_Label.all, Title_Label_Part_Styles);

      Add_Child (Card_Box_2.all, Widget_Access (Inner_Box));

      Add_Child (Top_Row.all, Widget_Access (Card_Box));
      Add_Child (Top_Row.all, Widget_Access (Card_Box_2));

      Add_Child (Bottom_Row.all, Widget_Access (Button_Box));
      Add_Child (Bottom_Row.all, Widget_Access (Hover_Box));
      Add_Child (Bottom_Row.all, Widget_Access (Label_Box));

      Add_Child (Root_Box.all, Widget_Access (Top_Row));
      Add_Child (Root_Box.all, Widget_Access (Bottom_Row));
      Add_Child (Root_Box.all, Widget_Access (Title_Label));

      Set_Flag (Button_Box.all, Clickable, True);
      Set_Flag (Hover_Box.all, Clickable, True);
      Set_Flag (Card_Box.all, Clickable, True);
      Set_Flag (Card_Box_2.all, Clickable, True);
      Set_Flag (Inner_Box.all, Clickable, True);

      Set_Root (W.all, Widget_Access (Root_Box));
      Set_Enforce_Layout_Min_Size (W.all, True);
      A.Add_Window (W);
      A.Run;
   end;
end Widget_Demo;
