pragma Ada_2022;

with Ada.Strings;                use Ada.Strings;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Adi.App;
with Adi.Window;                 use Adi.Window;
with Adi.Widget;                 use Adi.Widget;
with Adi.Widget.Box;             use Adi.Widget.Box;
with Adi.Widget.Combo_Box;       use Adi.Widget.Combo_Box;
with Adi.Widget.Label;           use Adi.Widget.Label;
with Combo_Box_Example_Styles;   use Combo_Box_Example_Styles;

procedure Combo_Box_Example is
   A : Adi.App.App;

   Status_Label : Label_Handle;

   procedure On_Combo_Changed
     (W     : Widget_Handle;
      Index : Natural;
      Text  : String)
   is
      pragma Unreferenced (W);
      Index_Text : constant String := Trim (Natural'Image (Index), Both);
   begin
      if Is_Valid (Status_Label) then
         Set_Text
           (Status_Label,
            "Selected #" & Index_Text & ": " & Text);
      end if;
   end On_Combo_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("Combo Box Overlay Example", (820.0, 520.0));

      Root       : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Container  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title      : constant Label_Handle := Adi.Widget.Label.Create_Handle ("Combo Box (Overlay Popup)");
      Hint       : constant Label_Handle := Adi.Widget.Label.Create_Handle
        ("Click to open. Popup is rendered in window overlay layer.");

      Color_Combo : constant Combo_Box_Handle := Adi.Widget.Combo_Box.Create_Handle;
      City_Combo  : constant Combo_Box_Handle := Adi.Widget.Combo_Box.Create_Handle;
   begin
      Status_Label := Adi.Widget.Label.Create_Handle ("Selected #1: Crimson");

      Set_Part_Styles (Root, Root_Class_Part_Styles);
      Set_Part_Styles (Container, Container_Class_Part_Styles);
      Set_Part_Styles (Title, Title_Class_Part_Styles);
      Set_Part_Styles (Hint, Hint_Class_Part_Styles);
      Set_Part_Styles (Status_Label, Status_Class_Part_Styles);

      Set_Part_Styles (Color_Combo, Combo_Class_Part_Styles);
      Set_Part_Styles (City_Combo, Combo_Class_Part_Styles);

      Set_Dropdown_Part_Styles (Color_Combo, Dropdown_Class_Part_Styles);
      Set_Dropdown_Part_Styles (City_Combo, Dropdown_Class_Part_Styles);
      Set_Option_Row_Part_Styles (Color_Combo, Option_Row_Class_Part_Styles);
      Set_Option_Row_Part_Styles (City_Combo, Option_Row_Class_Part_Styles);

      Connect_Selection_Changed (Color_Combo, On_Combo_Changed'Unrestricted_Access);
      Connect_Selection_Changed (City_Combo, On_Combo_Changed'Unrestricted_Access);

      Add_Item (Color_Combo, "Crimson");
      Add_Item (Color_Combo, "Emerald");
      Add_Item (Color_Combo, "Cobalt");
      Add_Item (Color_Combo, "Amber");
      Add_Item (Color_Combo, "Slate");
      Set_Selected_Index (Color_Combo, 1);

      Add_Item (City_Combo, "New York");
      Add_Item (City_Combo, "San Francisco");
      Add_Item (City_Combo, "Austin");
      Add_Item (City_Combo, "Seattle");
      Add_Item (City_Combo, "Boston");
      Add_Item (City_Combo, "Chicago");
      Add_Item (City_Combo, "Denver");
      Add_Item (City_Combo, "Portland");
      Add_Item (City_Combo, "Los Angeles");
      Add_Item (City_Combo, "San Diego");
      Add_Item (City_Combo, "Las Vegas");
      Add_Item (City_Combo, "Phoenix");
      Add_Item (City_Combo, "Dallas");
      Add_Item (City_Combo, "Houston");
      Add_Item (City_Combo, "Atlanta");
      Add_Item (City_Combo, "Miami");
      Add_Item (City_Combo, "Nashville");
      Add_Item (City_Combo, "Philadelphia");
      Add_Item (City_Combo, "Washington, DC");
      Add_Item (City_Combo, "Minneapolis");
      Add_Item (City_Combo, "Detroit");
      Add_Item (City_Combo, "Toronto");
      Add_Item (City_Combo, "Vancouver");
      Add_Item (City_Combo, "Montreal");
      Set_Selected_Index (City_Combo, 2);

      Adi.Widget.Add_Child (+Root, +Container);
      Adi.Widget.Add_Child (+Container, +Title);
      Adi.Widget.Add_Child (+Container, +Hint);
      Adi.Widget.Add_Child (+Container, +Color_Combo);
      Adi.Widget.Add_Child (+Container, +City_Combo);
      Adi.Widget.Add_Child (+Container, +Status_Label);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Combo_Box_Example;
