pragma Ada_2022;

with Ada.Strings;                use Ada.Strings;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.Core;                   use Adi.Core;
with Adi.Image;                  use Adi.Image;
with Adi.MCP;
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
        Create_Window_Handle ("Combo Box Overlay Example", Adi.Window.Extent (Px (562.0), Px (357.0)));

      Root       : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Container  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title      : constant Label_Handle := Adi.Widget.Label.Create_Handle ("Combo Box (Overlay Popup)");
      Hint       : constant Label_Handle := Adi.Widget.Label.Create_Handle
        ("Click to open. Popup is rendered in window overlay layer.");

      Color_Combo : constant Combo_Box_Handle := Adi.Widget.Combo_Box.Create_Handle;
      City_Combo  : constant Combo_Box_Handle := Adi.Widget.Combo_Box.Create_Handle;
      Icon_Combo  : constant Combo_Box_Handle := Adi.Widget.Combo_Box.Create_Handle;

      --  Owners: the combo box draws through handles, which keep
      --  nothing, so these must outlive the run below.
      Icon_Blue  : constant Color_8 := (R => 100, G => 181, B => 246, A => 255);
      Home_Icon  : constant Image_Owner :=
        Load_SVG_Path ("M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z",
                       (24.0, 24.0), Icon_Blue);
      Star_Icon  : constant Image_Owner :=
        Load_SVG_Path
          ("M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 "
           & "9.19 8.63 2 9.24l5.46 4.73L5.82 21z",
           (24.0, 24.0), Icon_Blue);
      Gear_Icon  : constant Image_Owner :=
        Load_SVG_Path
          ("M19.14,12.94c0.04-0.3,0.06-0.61,0.06-0.94"
           & "c0-0.32-0.02-0.64-0.07-0.94l2.03-1.58"
           & "c0.18-0.14,0.23-0.41,0.12-0.61 l-1.92-3.32"
           & "c-0.12-0.22-0.37-0.29-0.59-0.22l-2.39,0.96"
           & "c-0.5-0.38-1.03-0.7-1.62-0.94L14.4,2.81"
           & "c-0.04-0.24-0.24-0.41-0.48-0.41 h-3.84"
           & "c-0.24,0-0.43,0.17-0.47,0.41L9.25,5.35"
           & "C8.66,5.59,8.12,5.92,7.63,6.29L5.24,5.33"
           & "c-0.22-0.08-0.47,0-0.59,0.22L2.74,8.87 "
           & "C2.62,9.08,2.66,9.34,2.86,9.48l2.03,1.58"
           & "C4.84,11.36,4.8,11.69,4.8,12s0.02,0.64,0.07,0.94l-2.03,1.58 "
           & "c-0.18,0.14-0.23,0.41-0.12,0.61l1.92,3.32"
           & "c0.12,0.22,0.37,0.29,0.59,0.22l2.39-0.96"
           & "c0.5,0.38,1.03,0.7,1.62,0.94l0.36,2.54 "
           & "c0.05,0.24,0.24,0.41,0.48,0.41h3.84"
           & "c0.24,0,0.44-0.17,0.47-0.41l0.36-2.54"
           & "c0.59-0.24,1.13-0.56,1.62-0.94l2.39,0.96 "
           & "c0.22,0.08,0.47,0,0.59-0.22l1.92-3.32"
           & "c0.12-0.22,0.07-0.47-0.12-0.61L19.14,12.94z M12,15.6"
           & "c-1.98,0-3.6-1.62-3.6-3.6 s1.62-3.6,3.6-3.6s3.6,1.62,3.6,3.6"
           & "S13.98,15.6,12,15.6z",
           (24.0, 24.0), Icon_Blue);
      Search_Icon : constant Image_Owner :=
        Load_SVG_Path
          ("M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 "
           & "13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16"
           & "c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19"
           & "l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5"
           & "S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z",
           (24.0, 24.0), Icon_Blue);
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

      Add_Item (Icon_Combo, "Home",      Adi.Image.To_Handle (Home_Icon));
      Add_Item (Icon_Combo, "Favorites", Adi.Image.To_Handle (Star_Icon));
      Add_Item (Icon_Combo, "Settings",  Adi.Image.To_Handle (Gear_Icon));
      Add_Item (Icon_Combo, "Search",    Adi.Image.To_Handle (Search_Icon));

      Adi.Widget.Add_Child (+Root, +Container);
      Adi.Widget.Add_Child (+Container, +Title);
      Adi.Widget.Add_Child (+Container, +Hint);
      Adi.Widget.Add_Child (+Container, +Color_Combo);
      Adi.Widget.Add_Child (+Container, +City_Combo);
      Adi.Widget.Add_Child (+Container, +Icon_Combo);
      Adi.Widget.Add_Child (+Container, +Status_Label);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Combo_Box_Example;
