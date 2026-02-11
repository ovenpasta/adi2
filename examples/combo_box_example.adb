pragma Ada_2022;

with Ada.Strings;                use Ada.Strings;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Adi.App;
with Adi.Window;                 use Adi.Window;
with Adi.Widget;                 use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Combo_Box;       use Adi.Widget.Combo_Box;
with Adi.Widget.Label;           use Adi.Widget.Label;
with Combo_Box_Example_Styles;   use Combo_Box_Example_Styles;

procedure Combo_Box_Example is
   A : Adi.App.App;

   Status_Label : Label_Widget_Access;

   procedure On_Combo_Changed
     (W     : Combo_Box_Widget_Access;
      Index : Natural;
      Text  : String)
   is
      pragma Unreferenced (W);
      Index_Text : constant String := Trim (Natural'Image (Index), Both);
   begin
      if Status_Label /= null then
         Set_Text
           (Status_Label.all,
            "Selected #" & Index_Text & ": " & Text);
      end if;
   end On_Combo_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access :=
        Create_Window ("Combo Box Overlay Example", (820.0, 520.0));

      Root       : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title      : constant Label_Widget_Access := Adi.Widget.Label.Create ("Combo Box (Overlay Popup)");
      Hint       : constant Label_Widget_Access := Adi.Widget.Label.Create
        ("Click to open. Popup is rendered in window overlay layer.");

      Color_Combo : constant Combo_Box_Widget_Access := Adi.Widget.Combo_Box.Create;
      City_Combo  : constant Combo_Box_Widget_Access := Adi.Widget.Combo_Box.Create;
   begin
      Status_Label := Adi.Widget.Label.Create ("Selected #1: Crimson");

      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Container.all, Container_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Status_Label.all, Status_Class_Part_Styles);

      Set_Part_Styles (Color_Combo.all, Combo_Class_Part_Styles);
      Set_Part_Styles (City_Combo.all, Combo_Class_Part_Styles);

      Attach_Window (Color_Combo.all, W);
      Attach_Window (City_Combo.all, W);

      Set_Dropdown_Part_Styles (Color_Combo.all, Dropdown_Class_Part_Styles);
      Set_Dropdown_Part_Styles (City_Combo.all, Dropdown_Class_Part_Styles);
      Set_Option_Row_Part_Styles (Color_Combo.all, Option_Row_Class_Part_Styles);
      Set_Option_Row_Part_Styles (City_Combo.all, Option_Row_Class_Part_Styles);

      Color_Combo.Set_On_Selection_Changed (On_Combo_Changed'Unrestricted_Access);
      City_Combo.Set_On_Selection_Changed (On_Combo_Changed'Unrestricted_Access);

      Add_Item (Color_Combo.all, "Crimson");
      Add_Item (Color_Combo.all, "Emerald");
      Add_Item (Color_Combo.all, "Cobalt");
      Add_Item (Color_Combo.all, "Amber");
      Add_Item (Color_Combo.all, "Slate");
      Set_Selected_Index (Color_Combo.all, 1);

      Add_Item (City_Combo.all, "New York");
      Add_Item (City_Combo.all, "San Francisco");
      Add_Item (City_Combo.all, "Austin");
      Add_Item (City_Combo.all, "Seattle");
      Add_Item (City_Combo.all, "Boston");
      Add_Item (City_Combo.all, "Chicago");
      Add_Item (City_Combo.all, "Denver");
      Add_Item (City_Combo.all, "Portland");
      Add_Item (City_Combo.all, "Los Angeles");
      Add_Item (City_Combo.all, "San Diego");
      Add_Item (City_Combo.all, "Las Vegas");
      Add_Item (City_Combo.all, "Phoenix");
      Add_Item (City_Combo.all, "Dallas");
      Add_Item (City_Combo.all, "Houston");
      Add_Item (City_Combo.all, "Atlanta");
      Add_Item (City_Combo.all, "Miami");
      Add_Item (City_Combo.all, "Nashville");
      Add_Item (City_Combo.all, "Philadelphia");
      Add_Item (City_Combo.all, "Washington, DC");
      Add_Item (City_Combo.all, "Minneapolis");
      Add_Item (City_Combo.all, "Detroit");
      Add_Item (City_Combo.all, "Toronto");
      Add_Item (City_Combo.all, "Vancouver");
      Add_Item (City_Combo.all, "Montreal");
      Set_Selected_Index (City_Combo.all, 2);

      Root.Add_Child (Container);
      Container.Add_Child (Title);
      Container.Add_Child (Hint);
      Container.Add_Child (Color_Combo);
      Container.Add_Child (City_Combo);
      Container.Add_Child (Status_Label);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Combo_Box_Example;
