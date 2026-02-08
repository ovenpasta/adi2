with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget.Label;
with Adi.Image;

procedure Widget_Demo is
   A : Adi.App.App;

   --  Aliases to avoid ambiguity with Adi.CSS_Styles.Box
   function Style return Style_Builder renames Adi.Widget_Styles.Create;
   function Gap_Value (All_L : Length_Value) return Adi.CSS_Styles.Gap_Value renames Adi.CSS_Styles.Gap;
   function Size_Val (L : Length_Value) return Size_Value renames Adi.CSS_Styles.Size;

   use type Adi.Image.Image_Access;

begin
   A.Init;

   declare
      W : Adi.Window.Window_Access := Adi.Window.Create_Window ("Widget Demo", (800.0, 600.0));

      --  Root container (dark background, flex column)
      Root_Box : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Top row: two cards side by side
      Top_Row : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Card-style box (will have a background image)
      Card_Box : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Card 2 with orange border
      Card_Box_2 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Small colored box inside card 2
      Inner_Box : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Bottom row: button, hover box, label box
      Bottom_Row : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Button-style box
      Button_Box : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Hover-demo box
      Hover_Box : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Label container box
      Label_Box : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Text label
      Title_Label : Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Hello Adi Framework!");

      --  Background image
      Bg : Adi.Image.Image_Access;
      Bg_Style : Opt_Bg_Image.Optional;

   begin
      --  Try to load a background image
      Bg := W.Load_Image ("examples/bg.jpg");
      if Bg /= null then
         Bg_Style := Set_Bg_Image (Background_Image (Bg));
      end if;

      --  Style the root container (dark bg, flex column, fills window)
      Set_Part_Style (Root_Box.all, Main_Part,
         Style
            .Base ((
               Display          => Set (Flex),
               --Background_Image => (if Bg /= null
               --                     then Set_Bg_Image (Background_Image (Bg))
               --                     else Opt_Bg_Image.Unset),

               Flex_Direction   => Set (Column),
               Gap              => Set (Gap_Value (Px (20.0))),
               Padding          => Set (CSS_Box (Px (20.0))),
               Background_Color => Set_Bg (RGB (125, 125, 125)),
               others           => <>))
            .Build);

      --  Style top row (flex row)
      Set_Part_Style (Top_Row.all, Main_Part,
         Style
            .Base ((
               Display          => Set (Flex),
               Flex_Direction   => Set (Row),
               Gap              => Set (Gap_Value (Px (20.0))),
               Align_Items      => Set (Stretch),
               Background_Color => Set_Bg (RGB (255, 255, 255)),
               Padding          => Set (CSS_Box (Px (20.0))),
               Flex_Grow        => Set (1.0),
               others           => <>))
            .Build);

      --  Style the card box (white with rounded corners, border, shadow, and background image)
      Set_Part_Style (Card_Box.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (C (Adi.CSS_Styles.White)),
               Border_Width     => Set (Border_Width (Px (2.0))),
               Border_Color     => Set (Border_Color (RGB (200, 200, 200))),
               Border_Style     => Set (Border_Style (Adi.CSS_Styles.Solid)),
               Border_Radius    => Set (Radius (Px (4.0), Px (16.0), Px (32.0), Px (8.0))),
               Padding          => Set (CSS_Box (Px (20.0))),
               Flex_Grow        => Set (1.0),
               Box_Shadow       => Set (Shadow (Px (0), Px (4), Px (12), Px (0),
                                               RGBA (0, 0, 0, 0.5))),
               Margin          => Set (CSS_Box (Px (20.0))),
               others           => <>))
            .Build);

      --  Style card box 2 (orange tint, flex column, shadow)
      Set_Part_Style (Card_Box_2.all, Main_Part,
         Style
            .Base ((
               Display          => Set (Flex),
               Flex_Direction   => Set (Column),
               Gap              => Set (Gap_Value (Px (10.0))),
               Background_Color => Set_Bg (RGB (255, 247, 237)),
               Border_Width     => Set (Border_Width (Px (3.0))),
               Border_Color     => Set (Border_Color (RGB (251, 146, 60))),
               Border_Style     => Set (Border_Style (Adi.CSS_Styles.Solid)),
               Border_Radius    => Set (Radius (Px (16.0))),
               Padding          => Set (CSS_Box (Px (24.0))),
               Flex_Grow        => Set (1.0),
               Box_Shadow       => Set (Shadow (Px (0), Px (4), Px (4), Px (0),
                                               RGBA (0, 0, 0, 0.25))),
               others           => <>))
            .Build);

      --  Style inner box (solid orange, fixed size)
      Set_Part_Style (Inner_Box.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (RGB (251, 146, 60)),
               Border_Radius    => Set (Radius (Px (8.0))),
               Width            => Set (Size_Val (Px (100.0))),
               Height           => Set (Size_Val (Px (100.0))),
               others           => <>))
            .Build);

      --  Style bottom row (flex row)
      Set_Part_Style (Bottom_Row.all, Main_Part,
         Style
            .Base ((
               Display          => Set (Flex),
               Flex_Direction   => Set (Row),
               Gap              => Set (Gap_Value (Px (20.0))),
               Align_Items      => Set (Stretch),
               others           => <>))
            .Build);

      --  Style the button box (blue, with hover/press states)
      Set_Part_Style (Button_Box.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (RGB (59, 130, 246)),
               Border_Radius    => Set (Radius (Px (8.0))),
               Border_Width     => Set (Border_Width (Px (0.0))),
               Padding          => Set (CSS_Box (Px (12.0), Px (24.0))),
               Min_Width        => Set (Size_Val (Px (150.0))),
               Min_Height       => Set (Size_Val (Px (50.0))),
               others           => <>))
            .On_Hover ((
               Background_Color => Set_Bg (RGB (37, 99, 235)),
               others           => <>))
            .On_Press ((
               Background_Color => Set_Bg (RGB (255, 255, 255)),
               others           => <>))
            .Build);

      --  Style hover demo box (green, with hover state)
      Set_Part_Style (Hover_Box.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (RGB (0, 255, 0)),
               Border_Radius    => Set (Radius (Px (10.0))),
               Border_Width     => Set (Border_Width (Px (2.0))),
               Border_Color     => Set (Border_Color (RGB (22, 163, 74))),
               Border_Style     => Set (Border_Style (Adi.CSS_Styles.Solid)),
               Flex_Grow        => Set (1.0),
               Min_Height       => Set (Size_Val (Px (80.0))),
               others           => <>))
            .On_Hover ((
               Background_Color => Set_Bg (RGB (255, 0, 0)),
               Border_Color     => Set (Border_Color (RGB (21, 128, 61))),
               others           => <>))
            .Build);

      --  Style the label box
      Set_Part_Style (Label_Box.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (RGB (255, 255, 255)),
               Background_Image => Bg_Style,
               Object_Fit       => Set (Fit_Contain),
               Border_Radius    => Set (Radius (Px (6.0))),
               Border_Width     => Set (Border_Width (Px (1.0))),
               Border_Color     => Set (Border_Color (RGB (200, 200, 200))),
               Border_Style     => Set (Border_Style (Adi.CSS_Styles.Solid)),
               Flex_Grow        => Set (1.0),
               Min_Height       => Set (Size_Val (Px (50.0))),
               others           => <>))
            .Build);

      --  Style the title label (main part)
      Set_Part_Style (Title_Label.all, Main_Part,
         Style
            .Base ((
               Background_Color => Set_Bg (RGB (240, 240, 250)),
               Border_Radius    => Set (Radius (Px (4.0))),
               Padding          => Set (CSS_Box (Px (8.0))),
               others           => <>))
            .Build);

      --  Style the title label text
      Set_Part_Style (Title_Label.all, Label_Part,
         Style
            .Base ((
               Color          => Set (RGB (30, 30, 30)),
               Font_Size      => Set_Font (Px (18.0)),
               Text_Align     => Set (Text_Center),
               Vertical_Align => Set (VA_Middle),
               others         => <>))
            .Build);

      --  Build widget hierarchy
      Add_Child (Card_Box_2.all, Widget_Access (Inner_Box));

      Add_Child (Top_Row.all, Widget_Access (Card_Box));
      Add_Child (Top_Row.all, Widget_Access (Card_Box_2));

      Add_Child (Bottom_Row.all, Widget_Access (Button_Box));
      Add_Child (Bottom_Row.all, Widget_Access (Hover_Box));
      Add_Child (Bottom_Row.all, Widget_Access (Label_Box));

      Add_Child (Root_Box.all, Widget_Access (Top_Row));
      Add_Child (Root_Box.all, Widget_Access (Bottom_Row));
      Add_Child (Root_Box.all, Widget_Access (Title_Label));

      --  Make widgets clickable so they respond to hover/press
      Set_Flag (Button_Box.all, Clickable, True);
      Set_Flag (Hover_Box.all, Clickable, True);
      Set_Flag (Card_Box.all, Clickable, True);
      Set_Flag (Card_Box_2.all, Clickable, True);
      Set_Flag (Inner_Box.all, Clickable, True);

      --  Set root widget for the window
      Set_Root (W.all, Widget_Access (Root_Box));

      --  Add window to app and run
      A.Add_Window (W);
      A.Run;
   end;
end Widget_Demo;
