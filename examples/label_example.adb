pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Core;          use Adi.Core;
with Adi.Image;
with Label_Example_Styles; use Label_Example_Styles;

procedure Label_Example is
   A : Adi.App.App;

   use type Adi.Image.Image_Access;

begin
   A.Init;

   declare
      W : Window_Access := Create_Window ("Label Example", (600.0, 500.0));

      --  Root container
      Root : Adi.Widget.Box.Box_Widget_Access :=
         Adi.Widget.Box.Create (0.0, 0.0, 600.0, 500.0);

      --  Container for labels
      Container : Adi.Widget.Box.Box_Widget_Access :=
         Adi.Widget.Box.Create;

      --  Label 1: Text only
      Label1 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Hello World!");

      --  Label 2: Icon only
      Label2 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create;

      --  Label 3: Icon + Text (horizontal)
      Label3 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Save Document");

      --  Label 4: Icon + Text (vertical)
      Label4 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Settings");

      --  Load an icon
      Icon : Adi.Image.Image_Access;

   begin
      --  Try to load an icon
      Icon := W.Load_Image ("/usr/share/pixmaps/calculator.png");

      --  If icon loaded, set it on labels 2, 3, and 4
      if Icon /= null then
         Label2.Set_Icon (Icon);
         Label3.Set_Icon (Icon);
         Label4.Set_Icon (Icon);
      end if;

      --  Set geometries
      Set_Geometry (Container.all, (50.0, 50.0, 500.0, 400.0));

      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Container.all, Container_Part_Styles);
      Set_Part_Styles (Label1.all, Label1_Part_Styles);
      Set_Part_Styles (Label2.all, Label2_Part_Styles);
      Set_Part_Styles (Label3.all, Label3_Part_Styles);
      Set_Part_Styles (Label4.all, Label4_Part_Styles);

      --  Build widget hierarchy
      Add_Child (Root.all, Widget_Access (Container));
      Add_Child (Container.all, Widget_Access (Label1));
      Add_Child (Container.all, Widget_Access (Label2));
      Add_Child (Container.all, Widget_Access (Label3));
      Add_Child (Container.all, Widget_Access (Label4));

      --  Set root and run
      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Label_Example;
