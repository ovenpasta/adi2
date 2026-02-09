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
          ("Left container is overflow: visible (spills out). Right is overflow: hidden (clipped).");
      Panels     : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

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
   begin
      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Title.all, Title_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Part_Styles);
      Set_Part_Styles (Panels.all, Panels_Part_Styles);

      Set_Part_Styles (Visible_Panel.all, Panel_Part_Styles);
      Set_Part_Styles (Hidden_Panel.all, Panel_Part_Styles);
      Set_Part_Styles (Visible_Title.all, Panel_Title_Part_Styles);
      Set_Part_Styles (Hidden_Title.all, Panel_Title_Part_Styles);

      Set_Part_Styles (Visible_Clip.all, Clip_Visible_Part_Styles);
      Set_Part_Styles (Hidden_Clip.all, Clip_Hidden_Part_Styles);
      Set_Part_Styles (Visible_Content.all, Content_Stack_Part_Styles);
      Set_Part_Styles (Hidden_Content.all, Content_Stack_Part_Styles);

      --  Add intentionally oversized content to both containers.
      Add_Child (Visible_Content.all, Widget_Access (New_Item (Item_A_Part_Styles)));
      Add_Child (Visible_Content.all, Widget_Access (New_Item (Item_B_Part_Styles)));
      Add_Child (Visible_Content.all, Widget_Access (New_Item (Item_C_Part_Styles)));
      Add_Child (Visible_Content.all, Widget_Access (New_Item (Item_D_Part_Styles)));

      Add_Child (Hidden_Content.all, Widget_Access (New_Item (Item_A_Part_Styles)));
      Add_Child (Hidden_Content.all, Widget_Access (New_Item (Item_B_Part_Styles)));
      Add_Child (Hidden_Content.all, Widget_Access (New_Item (Item_C_Part_Styles)));
      Add_Child (Hidden_Content.all, Widget_Access (New_Item (Item_D_Part_Styles)));

      Add_Child (Visible_Clip.all, Widget_Access (Visible_Content));
      Add_Child (Hidden_Clip.all, Widget_Access (Hidden_Content));

      Add_Child (Visible_Panel.all, Widget_Access (Visible_Title));
      Add_Child (Visible_Panel.all, Widget_Access (Visible_Clip));
      Add_Child (Hidden_Panel.all, Widget_Access (Hidden_Title));
      Add_Child (Hidden_Panel.all, Widget_Access (Hidden_Clip));

      Add_Child (Panels.all, Widget_Access (Visible_Panel));
      Add_Child (Panels.all, Widget_Access (Hidden_Panel));

      Add_Child (Root.all, Widget_Access (Title));
      Add_Child (Root.all, Widget_Access (Hint));
      Add_Child (Root.all, Widget_Access (Panels));

      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Overflow_Example;
