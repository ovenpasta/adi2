pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.Window;               use Adi.Window;
with Adi.Widget;               use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Overflow_Example_Styles;  use Overflow_Example_Styles;

procedure Overflow_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

   function New_Item (Styles : Part_Style_Array) return Adi.Widget.Box.Box_Handle is
      B : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
   begin
      Adi.Widget.Box.Set_Part_Styles (B, Styles);
      return B;
   end New_Item;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("Overflow Example", (980.0, 560.0));

      Root       : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title      : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Overflow Behavior: visible vs hidden");
      Hint       : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Row 1: block overflow. Row 2: horizontal text overflow. Row 3: wrapped text vertical overflow.");
      Panels_Row_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Panels_Row_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Panels_Row_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Visible_Panel : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Hidden_Panel  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Visible_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("overflow: visible");
      Hidden_Title  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("overflow: hidden");

      Visible_Clip : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Hidden_Clip  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Visible_Content : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Hidden_Content  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Text_Visible_Panel : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Text_Hidden_Panel  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Text_Visible_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("text overflow: visible");
      Text_Hidden_Title  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("text overflow: hidden");
      Text_Visible_Clip : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Text_Hidden_Clip  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Text_Visible_Content : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Text_Hidden_Content  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Wrap_Visible_Panel : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Wrap_Hidden_Panel  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Wrap_Visible_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("wrapped text vertical overflow: visible");
      Wrap_Hidden_Title  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("wrapped text vertical overflow: hidden");
      Wrap_Visible_Clip : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Wrap_Hidden_Clip  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Wrap_Visible_Content : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Wrap_Hidden_Content  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Visible_Long_Line : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("LONG TEXT: The quick brown fox jumps over the lazy dog while this line should overflow horizontally.");
      Hidden_Long_Line  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("LONG TEXT: The quick brown fox jumps over the lazy dog while this line should overflow horizontally.");

      Wrap_Line_Visible : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("WRAPPED TEXT: This is a single very long paragraph designed to wrap across many lines so the rendered text becomes taller than the clip container height. "
           & "When overflow is visible, the bottom lines should continue outside the panel boundary. "
           & "When overflow is hidden, those extra wrapped lines should be clipped and not visible. "
           & "This sentence continues with additional words to ensure enough vertical text overflow for clear comparison.");
      Wrap_Line_Hidden : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("WRAPPED TEXT: This is a single very long paragraph designed to wrap across many lines so the rendered text becomes taller than the clip container height. "
           & "When overflow is visible, the bottom lines should continue outside the panel boundary. "
           & "When overflow is hidden, those extra wrapped lines should be clipped and not visible. "
           & "This sentence continues with additional words to ensure enough vertical text overflow for clear comparison.");
   begin
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint, Hint_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Panels_Row_1, Panels_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Panels_Row_2, Panels_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Panels_Row_3, Panels_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Visible_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Hidden_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Visible_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hidden_Title, Panel_Title_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Visible_Clip, Clip_Visible_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Hidden_Clip, Clip_Hidden_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Visible_Content, Content_Stack_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Hidden_Content, Content_Stack_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Text_Visible_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Text_Hidden_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Text_Visible_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Text_Hidden_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Text_Visible_Clip, Clip_Visible_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Text_Hidden_Clip, Clip_Hidden_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Text_Visible_Content, Content_Stack_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Text_Hidden_Content, Content_Stack_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Wrap_Visible_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Wrap_Hidden_Panel, Panel_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Wrap_Visible_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Wrap_Hidden_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Wrap_Visible_Clip, Clip_Visible_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Wrap_Hidden_Clip, Clip_Hidden_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Wrap_Visible_Content, Content_Stack_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Wrap_Hidden_Content, Content_Stack_Class_Part_Styles);

      Adi.Widget.Label.Set_Part_Styles (Visible_Long_Line, Long_Line_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hidden_Long_Line, Long_Line_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Wrap_Line_Visible, Wrap_Line_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Wrap_Line_Hidden, Wrap_Line_Class_Part_Styles);

      --  Add intentionally oversized content to both containers.
      Add_Child (+Visible_Content, +New_Item (Item_A_Class_Part_Styles));
      Add_Child (+Visible_Content, +New_Item (Item_B_Class_Part_Styles));
      Add_Child (+Visible_Content, +New_Item (Item_C_Class_Part_Styles));
      Add_Child (+Visible_Content, +New_Item (Item_D_Class_Part_Styles));

      Add_Child (+Hidden_Content, +New_Item (Item_A_Class_Part_Styles));
      Add_Child (+Hidden_Content, +New_Item (Item_B_Class_Part_Styles));
      Add_Child (+Hidden_Content, +New_Item (Item_C_Class_Part_Styles));
      Add_Child (+Hidden_Content, +New_Item (Item_D_Class_Part_Styles));

      Add_Child (+Visible_Clip, +Visible_Content);
      Add_Child (+Hidden_Clip, +Hidden_Content);

      Add_Child (+Visible_Panel, +Visible_Title);
      Add_Child (+Visible_Panel, +Visible_Clip);
      Add_Child (+Hidden_Panel, +Hidden_Title);
      Add_Child (+Hidden_Panel, +Hidden_Clip);

      Add_Child (+Text_Visible_Content, +Visible_Long_Line);
      Add_Child (+Text_Hidden_Content, +Hidden_Long_Line);
      Add_Child (+Text_Visible_Clip, +Text_Visible_Content);
      Add_Child (+Text_Hidden_Clip, +Text_Hidden_Content);
      Add_Child (+Text_Visible_Panel, +Text_Visible_Title);
      Add_Child (+Text_Visible_Panel, +Text_Visible_Clip);
      Add_Child (+Text_Hidden_Panel, +Text_Hidden_Title);
      Add_Child (+Text_Hidden_Panel, +Text_Hidden_Clip);

      Add_Child (+Wrap_Visible_Content, +Wrap_Line_Visible);
      Add_Child (+Wrap_Hidden_Content, +Wrap_Line_Hidden);
      Add_Child (+Wrap_Visible_Clip, +Wrap_Visible_Content);
      Add_Child (+Wrap_Hidden_Clip, +Wrap_Hidden_Content);
      Add_Child (+Wrap_Visible_Panel, +Wrap_Visible_Title);
      Add_Child (+Wrap_Visible_Panel, +Wrap_Visible_Clip);
      Add_Child (+Wrap_Hidden_Panel, +Wrap_Hidden_Title);
      Add_Child (+Wrap_Hidden_Panel, +Wrap_Hidden_Clip);

      Add_Child (+Panels_Row_1, +Visible_Panel);
      Add_Child (+Panels_Row_1, +Hidden_Panel);
      Add_Child (+Panels_Row_2, +Text_Visible_Panel);
      Add_Child (+Panels_Row_2, +Text_Hidden_Panel);
      Add_Child (+Panels_Row_3, +Wrap_Visible_Panel);
      Add_Child (+Panels_Row_3, +Wrap_Hidden_Panel);

      Add_Child (+Root, +Title);
      Add_Child (+Root, +Hint);
      Add_Child (+Root, +Panels_Row_1);
      Add_Child (+Root, +Panels_Row_2);
      Add_Child (+Root, +Panels_Row_3);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Overflow_Example;
