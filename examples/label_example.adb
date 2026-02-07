pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Core;          use Adi.Core;
with Adi.Image;

procedure Label_Example is
   A : Adi.App.App;

   --  Style builder alias
   function Style return Style_Builder renames Adi.Widget_Styles.Create;

   --  CSS helpers with explicit names (avoid ambiguity)
   function Px (V : Float) return Length_Value renames Adi.CSS_Styles.Px;
   function RGB (R, G, B : Natural) return Color_Value renames Adi.CSS_Styles.RGB;
   function Set_Bg (V : Color_Value) return Opt_Bg_Color.Optional renames Adi.CSS_Styles.Set_Bg;
   function Radius (All_L : Length_Value) return Border_Radius_Value renames Adi.CSS_Styles.Radius;
   function Padding_Box (All_L : Length_Value) return CSS_Box_Value renames Adi.CSS_Styles.CSS_Box;
   function Gap_Value (All_L : Length_Value) return Gap_Value renames Adi.CSS_Styles.Gap;
   function Size_Val (L : Length_Value) return Size_Value renames Adi.CSS_Styles.Size;

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

      --  Style root (dark background)
      Set_Part_Style (Root.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (RGB (40, 44, 52)),
               others => <>))
            .Build);

      --  Style container (vertical flex layout for labels)
      Set_Part_Style (Container.all, Main_Part,
         Style
            .Base ((
               Display => Set (Flex),
               Flex_Direction => Set (Column),
               Gap => Set (Gap_Value (Px (20.0))),
               Padding => Set (Padding_Box (Px (20.0))),
               Background_Color => Set_Bg (RGB (60, 63, 70)),
               Border_Radius => Set (Radius (Px (8.0))),
               others => <>))
            .Build);

      --  Style Label 1 (Text only - blue)
      Set_Part_Style (Label1.all, Main_Part,
         Style
            .Base ((
               Display => Set (Flex),
               Align_Items => Set (Center),
               Padding => Set (Padding_Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (97, 175, 239)),
               Border_Radius => Set (Radius (Px (4.0))),
               others => <>))
            .Build);

      Set_Part_Style (Label1.all, Label_Part,
         Style
            .Base ((
               Color => Set (RGB (255, 255, 255)),
               Font_Size => Set_Font (Px (18.0)),
               others => <>))
            .Build);

      --  Style Label 2 (Icon only - green)
      Set_Part_Style (Label2.all, Main_Part,
         Style
            .Base ((
               Display => Set (Flex),
               Align_Items => Set (Center),
               Justify_Content => Set (Center),
               Padding => Set (Padding_Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (152, 195, 121)),
               Border_Radius => Set (Radius (Px (4.0))),
               others => <>))
            .Build);

      Set_Part_Style (Label2.all, Icon_Part,
         Style
            .Base ((
               Width => Set (Size_Val (Px (32.0))),
               Height => Set (Size_Val (Px (32.0))),
               others => <>))
            .Build);

      --  Style Label 3 (Icon + Text horizontal - purple)
      Set_Part_Style (Label3.all, Main_Part,
         Style
            .Base ((
               Display => Set (Flex),
               Flex_Direction => Set (Row),
               Align_Items => Set (Center),
               Gap => Set (Gap_Value (Px (8.0))),
               Padding => Set (Padding_Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (198, 120, 221)),
               Border_Radius => Set (Radius (Px (4.0))),
               others => <>))
            .Build);

      Set_Part_Style (Label3.all, Icon_Part,
         Style
            .Base ((
               Width => Set (Size_Val (Px (24.0))),
               Height => Set (Size_Val (Px (24.0))),
               others => <>))
            .Build);

      Set_Part_Style (Label3.all, Label_Part,
         Style
            .Base ((
               Color => Set (RGB (255, 255, 255)),
               Font_Size => Set_Font (Px (16.0)),
               others => <>))
            .Build);

      --  Style Label 4 (Icon + Text vertical - orange)
      Set_Part_Style (Label4.all, Main_Part,
         Style
            .Base ((
               Display => Set (Flex),
               Flex_Direction => Set (Column),
               Align_Items => Set (Center),
               Gap => Set (Gap_Value (Px (8.0))),
               Padding => Set (Padding_Box (Px (15.0))),
               Background_Color => Set_Bg (RGB (229, 192, 123)),
               Border_Radius => Set (Radius (Px (4.0))),
               others => <>))
            .Build);

      Set_Part_Style (Label4.all, Icon_Part,
         Style
            .Base ((
               Width => Set (Size_Val (Px (48.0))),
               Height => Set (Size_Val (Px (48.0))),
               others => <>))
            .Build);

      Set_Part_Style (Label4.all, Label_Part,
         Style
            .Base ((
               Color => Set (RGB (40, 44, 52)),
               Font_Size => Set_Font (Px (14.0)),
               others => <>))
            .Build);

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
