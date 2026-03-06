pragma Ada_2022;

with Ada.Strings;            use Ada.Strings;
with Ada.Strings.Fixed;      use Ada.Strings.Fixed;
with Adi.App;
with Adi.Window;             use Adi.Window;
with Adi.Widget;             use Adi.Widget;
with Adi.Widget.Box;         use Adi.Widget.Box;
with Adi.Widget.Label;       use Adi.Widget.Label;
with Adi.Widget.Text_Input;  use Adi.Widget.Text_Input;
with Text_Input_Example_Styles; use Text_Input_Example_Styles;

procedure Text_Input_Example is
   A : Adi.App.App;

   Echo_Label   : Label_Handle;
   Length_Label  : Label_Handle;

   procedure On_Input_Changed
     (W    : Widget_Handle;
      Text : String)
   is
      pragma Unreferenced (W);
      Len_Text : constant String := Trim (Natural'Image (Text'Length), Ada.Strings.Both);
   begin
      if Is_Valid (Echo_Label) then
         Set_Text (Echo_Label, "You typed: " & Text);
      end if;

      if Is_Valid (Length_Label) then
         Set_Text (Length_Label, "Length: " & Len_Text);
      end if;
   end On_Input_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle := Create_Window_Handle ("Text Input Example", (760.0, 420.0));

      Root      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Container : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title     : constant Label_Handle := Create_Handle ("Text Input Widget Demo");
      Hint      : constant Label_Handle := Create_Handle
        ("Click the field below and type. Use arrows/Home/End/Backspace/Delete.");
      Input     : constant Text_Input_Handle := Adi.Widget.Text_Input.Create_Handle ("Hello Adi");
      Input_2   : constant Text_Input_Handle := Adi.Widget.Text_Input.Create_Handle ("Second field");
   begin
      Echo_Label := Create_Handle ("You typed: Hello Adi");
      Length_Label := Create_Handle ("Length: 9");

      Connect_Changed (Input, On_Input_Changed'Unrestricted_Access);

      Set_Part_Styles (Root, Root_Class_Part_Styles);
      Set_Part_Styles (Container, Container_Class_Part_Styles);
      Set_Part_Styles (Title, Title_Class_Part_Styles);
      Set_Part_Styles (Hint, Hint_Class_Part_Styles);
      Set_Part_Styles (Echo_Label, Echo_Label_Class_Part_Styles);
      Set_Part_Styles (Length_Label, Length_Label_Class_Part_Styles);

      Set_Part_Styles (Input, Input_Class_Part_Styles);
      Set_Part_Styles (Input_2, Input_Class_Part_Styles);
      Set_Context_Menu_Part_Styles (Input, Context_Menu_Class_Part_Styles);
      Set_Context_Menu_Item_Part_Styles (Input, Context_Menu_Item_Class_Part_Styles);
      Set_Context_Menu_Part_Styles (Input_2, Context_Menu_Class_Part_Styles);
      Set_Context_Menu_Item_Part_Styles (Input_2, Context_Menu_Item_Class_Part_Styles);

      Add_Child (Root, +Container);
      Add_Child (Container, +Title);
      Add_Child (Container, +Hint);
      Add_Child (Container, +Input);
      Add_Child (Container, +Input_2);
      Add_Child (Container, +Echo_Label);
      Add_Child (Container, +Length_Label);

      Adi.Window.Set_Root (W, +Root);
      A.Add_Window (W);
      A.Run;
   end;
end Text_Input_Example;
