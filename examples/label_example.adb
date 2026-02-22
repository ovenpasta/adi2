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

begin
   A.Init;

   declare
      W : constant Window_Access := Create_Window ("Label Example", (600.0, 500.0));

      --  Root container
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
         Adi.Widget.Box.Create (0.0, 0.0, 600.0, 500.0);

      --  Container for labels
      Container : constant Adi.Widget.Box.Box_Widget_Access :=
         Adi.Widget.Box.Create;

      --  Label 1: Text only
      Label1 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Hello World!");

      --  Label 2: Icon only
      Label2 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create;

      --  Label 3: Icon + Text (horizontal)
      Label3 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Save Document");

      --  Label 4: Icon + Text (vertical)
      Label4 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Settings");

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
         Label2.Set_Icon (Icon);
         Label3.Set_Icon (Icon);
         Label4.Set_Icon (Icon);
      end if;

      --  Set geometries
      Set_Geometry (Container.all, (50.0, 50.0, 500.0, 400.0));

      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Container.all, Container_Class_Part_Styles);
      Set_Part_Styles (Label1.all, Label1_Class_Part_Styles);
      Set_Part_Styles (Label2.all, Label2_Class_Part_Styles);
      Set_Part_Styles (Label3.all, Label3_Class_Part_Styles);
      Set_Part_Styles (Label4.all, Label4_Class_Part_Styles);

      --  Build widget hierarchy
      Root.Add_Child (Container);
      Container.Add_Child (Label1);
      Container.Add_Child (Label2);
      Container.Add_Child (Label3);
      Container.Add_Child (Label4);

      --  Set root and run
      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Label_Example;
