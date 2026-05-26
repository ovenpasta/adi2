pragma Ada_2022;

with Ada.Strings;                use Ada.Strings;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Adi.App;
with Adi.Layout_Util;
with Adi.Core;                   use Adi.Core;
with Adi.Image;                  use Adi.Image;
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
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
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
      Icon_Combo  : constant Combo_Box_Handle := Adi.Widget.Combo_Box.Create_Handle;
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

      Set_Part_Styles (Icon_Combo, Combo_Class_Part_Styles);
      Set_Dropdown_Part_Styles (Icon_Combo, Dropdown_Class_Part_Styles);
      Set_Option_Row_Part_Styles (Icon_Combo, Option_Row_Class_Part_Styles);

      Connect_Selection_Changed (Color_Combo, On_Combo_Changed'Unrestricted_Access);
      Connect_Selection_Changed (City_Combo, On_Combo_Changed'Unrestricted_Access);
      Connect_Selection_Changed (Icon_Combo, On_Combo_Changed'Unrestricted_Access);

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

      declare
         Icon_Blue  : constant Color_8 := (R => 100, G => 181, B => 246, A => 255);
         Home_Icon  : constant Image_Access :=
           Load_SVG_Path ("M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z",
                          (24.0, 24.0), Icon_Blue);
         Star_Icon  : constant Image_Access :=
           Load_SVG_Path
             ("M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 "
              & "9.19 8.63 2 9.24l5.46 4.73L5.82 21z",
              (24.0, 24.0), Icon_Blue);
         Gear_Icon  : constant Image_Access :=
           Load_SVG_Path
             ("M12 15.5A3.5 3.5 0 018.5 12 3.5 3.5 0 0112 8.5 "
              & "3.5 3.5 0 0115.5 12 3.5 3.5 0 0112 15.5m7.43-2.92c.04-.36.07-.72.07-1.08 "
              & "0-.36-.03-.73-.07-1.08l2.33-1.82c.21-.16.27-.46.13-.7l-2.21-3.82 "
              & "c-.14-.24-.43-.32-.67-.24l-2.75 1.1c-.57-.44-1.18-.8-1.86-1.07L14.1 1.8 "
              & "c-.04-.28-.28-.48-.56-.48h-4.42c-.28 0-.52.2-.56.48l-.42 2.93 "
              & "c-.68.27-1.3.63-1.86 1.07L3.54 6.7c-.24-.08-.53 0-.67.24L.66 10.76 "
              & "c-.14.24-.08.54.13.7l2.33 1.82c-.04.35-.07.71-.07 1.08s.03.73.07 1.08 "
              & "l-2.33 1.82c-.21.16-.27.46-.13.7l2.21 3.82c.14.24.43.32.67.24l2.75-1.1 "
              & "c.57.44 1.18.8 1.86 1.07l.42 2.93c.04.28.28.48.56.48h4.42 "
              & "c.28 0 .52-.2.56-.48l.42-2.93c.68-.27 1.3-.63 1.86-1.07l2.75 1.1 "
              & "c.24.08.53 0 .67-.24l2.21-3.82c.14-.24.08-.54-.13-.7l-2.33-1.82z",
              (24.0, 24.0), Icon_Blue);
         Search_Icon : constant Image_Access :=
           Load_SVG_Path
             ("M15.5 14h-.79l-.28-.27A6.47 6.47 0 0016 9.5 "
              & "6.5 6.5 0 109.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99 "
              & "L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 "
              & "14 7.01 14 9.5 11.99 14 9.5 14z",
              (24.0, 24.0), Icon_Blue);
      begin
         Add_Item (Icon_Combo, "Home",      Home_Icon);
         Add_Item (Icon_Combo, "Favorites", Star_Icon);
         Add_Item (Icon_Combo, "Settings",  Gear_Icon);
         Add_Item (Icon_Combo, "Search",    Search_Icon);
      end;

      Adi.Widget.Add_Child (+Root, +Container);
      Adi.Widget.Add_Child (+Container, +Title);
      Adi.Widget.Add_Child (+Container, +Hint);
      Adi.Widget.Add_Child (+Container, +Color_Combo);
      Adi.Widget.Add_Child (+Container, +City_Combo);
      Adi.Widget.Add_Child (+Container, +Icon_Combo);
      Adi.Widget.Add_Child (+Container, +Status_Label);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Combo_Box_Example;
