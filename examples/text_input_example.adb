pragma Ada_2022;

with Ada.Strings;            use Ada.Strings;
with Ada.Strings.Fixed;      use Ada.Strings.Fixed;
with Adi.App;
with Adi.Window;             use Adi.Window;
with Adi.Widget;             use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;       use Adi.Widget.Label;
with Adi.Widget.Text_Input;  use Adi.Widget.Text_Input;
with Text_Input_Example_Styles; use Text_Input_Example_Styles;

procedure Text_Input_Example is
   A : Adi.App.App;

   Echo_Label   : Label_Widget_Access;
   Length_Label : Label_Widget_Access;

   procedure On_Input_Changed
     (W    : Text_Input_Widget_Access;
      Text : String)
   is
      pragma Unreferenced (W);
      Len_Text : constant String := Trim (Natural'Image (Text'Length), Ada.Strings.Both);
   begin
      if Echo_Label /= null then
         Set_Text (Echo_Label.all, "You typed: " & Text);
      end if;

      if Length_Label /= null then
         Set_Text (Length_Label.all, "Length: " & Len_Text);
      end if;
   end On_Input_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Text Input Example", (760.0, 420.0));

      Root      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title     : constant Label_Widget_Access := Adi.Widget.Label.Create ("Text Input Widget Demo");
      Hint      : constant Label_Widget_Access := Adi.Widget.Label.Create
        ("Click the field below and type. Use arrows/Home/End/Backspace/Delete.");
      Input     : constant Text_Input_Widget_Access := Adi.Widget.Text_Input.Create ("Hello Adi");
      Input_2   : constant Text_Input_Widget_Access := Adi.Widget.Text_Input.Create ("Second field");
   begin
      Echo_Label := Adi.Widget.Label.Create ("You typed: Hello Adi");
      Length_Label := Adi.Widget.Label.Create ("Length: 9");

      Input.Set_On_Changed (On_Input_Changed'Unrestricted_Access);

      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Container.all, Container_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Echo_Label.all, Echo_Label_Class_Part_Styles);
      Set_Part_Styles (Length_Label.all, Length_Label_Class_Part_Styles);

      Set_Part_Styles (Input.all, Input_Class_Part_Styles);
      Set_Part_Styles (Input_2.all, Input_Class_Part_Styles);

      Root.Add_Child (Container);
      Container.Add_Child (Title);
      Container.Add_Child (Hint);
      Container.Add_Child (Input);
      Container.Add_Child (Input_2);
      Container.Add_Child (Echo_Label);
      Container.Add_Child (Length_Label);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Text_Input_Example;
