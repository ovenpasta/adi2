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
      W : Window_Access := Create_Window ("Text Input Example", (760.0, 420.0));

      Root      : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title     : Label_Widget_Access := Adi.Widget.Label.Create ("Text Input Widget Demo");
      Hint      : Label_Widget_Access := Adi.Widget.Label.Create
        ("Click the field below and type. Use arrows/Home/End/Backspace/Delete.");
      Input     : Text_Input_Widget_Access := Adi.Widget.Text_Input.Create ("Hello Adi");
      Input_2   : Text_Input_Widget_Access := Adi.Widget.Text_Input.Create ("Second field");
   begin
      Echo_Label := Adi.Widget.Label.Create ("You typed: Hello Adi");
      Length_Label := Adi.Widget.Label.Create ("Length: 9");

      Set_On_Changed (Input.all, On_Input_Changed'Unrestricted_Access);

      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Container.all, Container_Part_Styles);
      Set_Part_Styles (Title.all, Title_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Part_Styles);
      Set_Part_Styles (Echo_Label.all, Echo_Label_Part_Styles);
      Set_Part_Styles (Length_Label.all, Length_Label_Part_Styles);

      Set_Part_Styles (Input.all, Input_Part_Styles);
      Set_Part_Styles (Input_2.all, Input_Part_Styles);

      Add_Child (Root.all, Widget_Access (Container));
      Add_Child (Container.all, Widget_Access (Title));
      Add_Child (Container.all, Widget_Access (Hint));
      Add_Child (Container.all, Widget_Access (Input));
      Add_Child (Container.all, Widget_Access (Input_2));
      Add_Child (Container.all, Widget_Access (Echo_Label));
      Add_Child (Container.all, Widget_Access (Length_Label));

      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Text_Input_Example;
