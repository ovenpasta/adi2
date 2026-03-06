pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Image;
with Label_Example_Styles; use Label_Example_Styles;

procedure Label_Example is
   A : Adi.App.App;

   use type Adi.Image.Image_Access;
   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

begin
   A.Init;

   declare
      W : constant Window_Handle := Create_Window_Handle ("Label Example", (600.0, 500.0));

      --  Root container
      Root : constant Adi.Widget.Box.Box_Handle :=
         Adi.Widget.Box.Create_Handle (0.0, 0.0, 600.0, 500.0);

      --  Container for labels
      Container : constant Adi.Widget.Box.Box_Handle :=
         Adi.Widget.Box.Create_Handle;

      --  Label 1: Text only
      Label1 : constant Adi.Widget.Label.Label_Handle :=
         Adi.Widget.Label.Create_Handle ("Hello World!");

      --  Label 2: Icon only
      Label2 : constant Adi.Widget.Label.Label_Handle :=
         Adi.Widget.Label.Create_Handle;

      --  Label 3: Icon + Text (horizontal)
      Label3 : constant Adi.Widget.Label.Label_Handle :=
         Adi.Widget.Label.Create_Handle ("Save Document");

      --  Label 4: Icon + Text (vertical)
      Label4 : constant Adi.Widget.Label.Label_Handle :=
         Adi.Widget.Label.Create_Handle ("Settings");

      --  Load an icon
      Icon : Adi.Image.Image_Access;
      Save_Path : constant String :=
        "M5 3 H19 V21 H5 Z "
        & "M8 3 V9 H16 V3 "
        & "M9 14 H15 V19 H9 Z";

   begin
      --  Build an icon from an inline SVG path.
      Icon :=
        Adi.Image.Load_SVG_Path
          (Path_Data    => Save_Path,
           Size         => (24.0, 24.0),
           Fill         => (R => 242, G => 248, B => 255, A => 255),
           Stroke_Width => 1.5,
           Stroke       => (R => 26, G => 54, B => 79, A => 255));

      --  If icon loaded, set it on labels 2, 3, and 4
      if Icon /= null then
         Adi.Widget.Label.Set_Icon (Label2, Icon);
         Adi.Widget.Label.Set_Icon (Label3, Icon);
         Adi.Widget.Label.Set_Icon (Label4, Icon);
      end if;

      --  Set geometries
      Set_Geometry (Borrow (+Container).Ptr.all, (50.0, 50.0, 500.0, 400.0));

      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Container, Container_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label1, Label1_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label2, Label2_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label3, Label3_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label4, Label4_Class_Part_Styles);

      --  Build widget hierarchy
      Add_Child (+Root, +Container);
      Add_Child (+Container, +Label1);
      Add_Child (+Container, +Label2);
      Add_Child (+Container, +Label3);
      Add_Child (+Container, +Label4);

      --  Set root and run
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Label_Example;
