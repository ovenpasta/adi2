pragma Ada_2022;

with Adi.App;
with Adi.Window;               use Adi.Window;
with Adi.Widget;               use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Overflow_Example_Styles;  use Overflow_Example_Styles;

procedure Overflow_Example is
   A : Adi.App.App;

   function New_Item (Styles : Part_Style_Array) return Adi.Widget.Box.Box_Widget_Access is
      B : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
   begin
      Set_Part_Styles (B.all, Styles);
      return B;
   end New_Item;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access :=
        Create_Window ("Overflow Example", (980.0, 560.0));

      Root       : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title      : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Overflow Behavior: visible vs hidden");
      Hint       : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Row 1: block overflow. Row 2: horizontal text overflow. Row 3: wrapped text vertical overflow.");
      Panels_Row_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Panels_Row_2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Panels_Row_3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Visible_Panel : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Hidden_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Visible_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("overflow: visible");
      Hidden_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("overflow: hidden");

      Visible_Clip : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Hidden_Clip  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Visible_Content : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Hidden_Content  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Text_Visible_Panel : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Text_Hidden_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Text_Visible_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("text overflow: visible");
      Text_Hidden_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("text overflow: hidden");
      Text_Visible_Clip : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Text_Hidden_Clip  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Text_Visible_Content : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Text_Hidden_Content  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Wrap_Visible_Panel : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Wrap_Hidden_Panel  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Wrap_Visible_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("wrapped text vertical overflow: visible");
      Wrap_Hidden_Title  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("wrapped text vertical overflow: hidden");
      Wrap_Visible_Clip : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Wrap_Hidden_Clip  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Wrap_Visible_Content : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Wrap_Hidden_Content  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Visible_Long_Line : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("LONG TEXT: The quick brown fox jumps over the lazy dog while this line should overflow horizontally.");
      Hidden_Long_Line  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("LONG TEXT: The quick brown fox jumps over the lazy dog while this line should overflow horizontally.");

      Wrap_Line_Visible : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("WRAPPED TEXT: This is a single very long paragraph designed to wrap across many lines so the rendered text becomes taller than the clip container height. "
           & "When overflow is visible, the bottom lines should continue outside the panel boundary. "
           & "When overflow is hidden, those extra wrapped lines should be clipped and not visible. "
           & "This sentence continues with additional words to ensure enough vertical text overflow for clear comparison.");
      Wrap_Line_Hidden : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("WRAPPED TEXT: This is a single very long paragraph designed to wrap across many lines so the rendered text becomes taller than the clip container height. "
           & "When overflow is visible, the bottom lines should continue outside the panel boundary. "
           & "When overflow is hidden, those extra wrapped lines should be clipped and not visible. "
           & "This sentence continues with additional words to ensure enough vertical text overflow for clear comparison.");
   begin
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Panels_Row_1.all, Panels_Class_Part_Styles);
      Set_Part_Styles (Panels_Row_2.all, Panels_Class_Part_Styles);
      Set_Part_Styles (Panels_Row_3.all, Panels_Class_Part_Styles);

      Set_Part_Styles (Visible_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Hidden_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Visible_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Hidden_Title.all, Panel_Title_Class_Part_Styles);

      Set_Part_Styles (Visible_Clip.all, Clip_Visible_Class_Part_Styles);
      Set_Part_Styles (Hidden_Clip.all, Clip_Hidden_Class_Part_Styles);
      Set_Part_Styles (Visible_Content.all, Content_Stack_Class_Part_Styles);
      Set_Part_Styles (Hidden_Content.all, Content_Stack_Class_Part_Styles);

      Set_Part_Styles (Text_Visible_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Text_Hidden_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Text_Visible_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Text_Hidden_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Text_Visible_Clip.all, Clip_Visible_Class_Part_Styles);
      Set_Part_Styles (Text_Hidden_Clip.all, Clip_Hidden_Class_Part_Styles);
      Set_Part_Styles (Text_Visible_Content.all, Content_Stack_Class_Part_Styles);
      Set_Part_Styles (Text_Hidden_Content.all, Content_Stack_Class_Part_Styles);

      Set_Part_Styles (Wrap_Visible_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Wrap_Hidden_Panel.all, Panel_Class_Part_Styles);
      Set_Part_Styles (Wrap_Visible_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Wrap_Hidden_Title.all, Panel_Title_Class_Part_Styles);
      Set_Part_Styles (Wrap_Visible_Clip.all, Clip_Visible_Class_Part_Styles);
      Set_Part_Styles (Wrap_Hidden_Clip.all, Clip_Hidden_Class_Part_Styles);
      Set_Part_Styles (Wrap_Visible_Content.all, Content_Stack_Class_Part_Styles);
      Set_Part_Styles (Wrap_Hidden_Content.all, Content_Stack_Class_Part_Styles);

      Set_Part_Styles (Visible_Long_Line.all, Long_Line_Class_Part_Styles);
      Set_Part_Styles (Hidden_Long_Line.all, Long_Line_Class_Part_Styles);
      Set_Part_Styles (Wrap_Line_Visible.all, Wrap_Line_Class_Part_Styles);
      Set_Part_Styles (Wrap_Line_Hidden.all, Wrap_Line_Class_Part_Styles);

      --  Add intentionally oversized content to both containers.
      Visible_Content.Add_Child (New_Item (Item_A_Class_Part_Styles));
      Visible_Content.Add_Child (New_Item (Item_B_Class_Part_Styles));
      Visible_Content.Add_Child (New_Item (Item_C_Class_Part_Styles));
      Visible_Content.Add_Child (New_Item (Item_D_Class_Part_Styles));

      Hidden_Content.Add_Child (New_Item (Item_A_Class_Part_Styles));
      Hidden_Content.Add_Child (New_Item (Item_B_Class_Part_Styles));
      Hidden_Content.Add_Child (New_Item (Item_C_Class_Part_Styles));
      Hidden_Content.Add_Child (New_Item (Item_D_Class_Part_Styles));

      Visible_Clip.Add_Child (Visible_Content);
      Hidden_Clip.Add_Child (Hidden_Content);

      Visible_Panel.Add_Child (Visible_Title);
      Visible_Panel.Add_Child (Visible_Clip);
      Hidden_Panel.Add_Child (Hidden_Title);
      Hidden_Panel.Add_Child (Hidden_Clip);

      Text_Visible_Content.Add_Child (Visible_Long_Line);
      Text_Hidden_Content.Add_Child (Hidden_Long_Line);
      Text_Visible_Clip.Add_Child (Text_Visible_Content);
      Text_Hidden_Clip.Add_Child (Text_Hidden_Content);
      Text_Visible_Panel.Add_Child (Text_Visible_Title);
      Text_Visible_Panel.Add_Child (Text_Visible_Clip);
      Text_Hidden_Panel.Add_Child (Text_Hidden_Title);
      Text_Hidden_Panel.Add_Child (Text_Hidden_Clip);

      Wrap_Visible_Content.Add_Child (Wrap_Line_Visible);
      Wrap_Hidden_Content.Add_Child (Wrap_Line_Hidden);
      Wrap_Visible_Clip.Add_Child (Wrap_Visible_Content);
      Wrap_Hidden_Clip.Add_Child (Wrap_Hidden_Content);
      Wrap_Visible_Panel.Add_Child (Wrap_Visible_Title);
      Wrap_Visible_Panel.Add_Child (Wrap_Visible_Clip);
      Wrap_Hidden_Panel.Add_Child (Wrap_Hidden_Title);
      Wrap_Hidden_Panel.Add_Child (Wrap_Hidden_Clip);

      Panels_Row_1.Add_Child (Visible_Panel);
      Panels_Row_1.Add_Child (Hidden_Panel);
      Panels_Row_2.Add_Child (Text_Visible_Panel);
      Panels_Row_2.Add_Child (Text_Hidden_Panel);
      Panels_Row_3.Add_Child (Wrap_Visible_Panel);
      Panels_Row_3.Add_Child (Wrap_Hidden_Panel);

      Root.Add_Child (Title);
      Root.Add_Child (Hint);
      Root.Add_Child (Panels_Row_1);
      Root.Add_Child (Panels_Row_2);
      Root.Add_Child (Panels_Row_3);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Overflow_Example;
