with Ada.Characters.Handling;

package body Adi.CSS_Styles is

   package Char renames Ada.Characters.Handling;

   -------------------------------------------------
   -- Get_Border_Radius_Px
   -------------------------------------------------

   function Get_Border_Radius_Px (R : Border_Radius_Value) return Corner_Pixels is
   begin
      case R.Kind is
         when Gap_Uniform =>
            declare
               V : constant Float := R.All_Corners.Amount;
            begin
               return (V, V, V, V);
            end;
         when Per_Corner =>
            return (
               Top_Left     => R.Corners (Top_Left).Amount,
               Top_Right    => R.Corners (Top_Right).Amount,
               Bottom_Right => R.Corners (Bottom_Right).Amount,
               Bottom_Left  => R.Corners (Bottom_Left).Amount);
      end case;
   end Get_Border_Radius_Px;

   type RGB_Entry is record
      R, G, B : Natural;
   end record;

   Named_Color_RGB : constant array (Named_Color) of RGB_Entry :=
     (
      Black => (R => 0, G => 0, B => 0),
      White => (R => 255, G => 255, B => 255),
      Red => (R => 255, G => 0, B => 0),
      Green => (R => 0, G => 128, B => 0),
      Blue => (R => 0, G => 0, B => 255),
      Yellow => (R => 255, G => 255, B => 0),
      Orange => (R => 255, G => 165, B => 0),
      Purple => (R => 128, G => 0, B => 128),
      Gray => (R => 128, G => 128, B => 128),
      Light_Gray => (R => 211, G => 211, B => 211),
      Dark_Gray => (R => 169, G => 169, B => 169),
      Silver => (R => 192, G => 192, B => 192),
      Maroon => (R => 128, G => 0, B => 0),
      Fuchsia => (R => 255, G => 0, B => 255),
      Lime => (R => 0, G => 255, B => 0),
      Olive => (R => 128, G => 128, B => 0),
      Navy => (R => 0, G => 0, B => 128),
      Teal => (R => 0, G => 128, B => 128),
      Aqua => (R => 0, G => 255, B => 255),
      Alice_Blue => (R => 240, G => 248, B => 255),
      Antique_White => (R => 250, G => 235, B => 215),
      Aqua_Marine => (R => 127, G => 255, B => 212),
      Azure => (R => 240, G => 255, B => 255),
      Beige => (R => 245, G => 245, B => 220),
      Bisque => (R => 255, G => 228, B => 196),
      Blanched_Almond => (R => 255, G => 235, B => 205),
      Blue_Violet => (R => 138, G => 43, B => 226),
      Brown => (R => 165, G => 42, B => 42),
      Burly_Wood => (R => 222, G => 184, B => 135),
      Cadet_Blue => (R => 95, G => 158, B => 160),
      Chartreuse => (R => 127, G => 255, B => 0),
      Chocolate => (R => 210, G => 105, B => 30),
      Coral => (R => 255, G => 127, B => 80),
      Cornflower_Blue => (R => 100, G => 149, B => 237),
      Corn_Silk => (R => 255, G => 248, B => 220),
      Crimson => (R => 220, G => 20, B => 60),
      Cyan => (R => 0, G => 255, B => 255),
      Dark_Blue => (R => 0, G => 0, B => 139),
      Dark_Cyan => (R => 0, G => 139, B => 139),
      Dark_Goldenrod => (R => 184, G => 134, B => 11),
      Dark_Green => (R => 0, G => 100, B => 0),
      Dark_Khaki => (R => 189, G => 183, B => 107),
      Dark_Magenta => (R => 139, G => 0, B => 139),
      Dark_Olive_Green => (R => 85, G => 107, B => 47),
      Dark_Orange => (R => 255, G => 140, B => 0),
      Dark_Orchid => (R => 153, G => 50, B => 204),
      Dark_Red => (R => 139, G => 0, B => 0),
      Dark_Salmon => (R => 233, G => 150, B => 122),
      Dark_Sea_Green => (R => 143, G => 188, B => 143),
      Dark_Slate_Blue => (R => 72, G => 61, B => 139),
      Dark_Slate_Gray => (R => 47, G => 79, B => 79),
      Dark_Slate_Grey => (R => 47, G => 79, B => 79),
      Dark_Turquoise => (R => 0, G => 206, B => 209),
      Dark_Violet => (R => 148, G => 0, B => 211),
      Deep_Pink => (R => 255, G => 20, B => 147),
      Deep_Sky_Blue => (R => 0, G => 191, B => 255),
      Dim_Gray => (R => 105, G => 105, B => 105),
      Dim_Grey => (R => 105, G => 105, B => 105),
      Dodger_Blue => (R => 30, G => 144, B => 255),
      Fire_Brick => (R => 178, G => 34, B => 34),
      Floral_White => (R => 255, G => 250, B => 240),
      Forest_Green => (R => 34, G => 139, B => 34),
      Gainsboro => (R => 220, G => 220, B => 220),
      Ghost_White => (R => 248, G => 248, B => 255),
      Gold => (R => 255, G => 215, B => 0),
      Goldenrod => (R => 218, G => 165, B => 32),
      Green_Yellow => (R => 173, G => 255, B => 47),
      Honey_Dew => (R => 240, G => 255, B => 240),
      Hot_Pink => (R => 255, G => 105, B => 180),
      Indian_Red => (R => 205, G => 92, B => 92),
      Indigo => (R => 75, G => 0, B => 130),
      Ivory => (R => 255, G => 255, B => 240),
      Khaki => (R => 240, G => 230, B => 140),
      Lavender => (R => 230, G => 230, B => 250),
      Lavender_Blush => (R => 255, G => 240, B => 245),
      Lawn_Green => (R => 124, G => 252, B => 0),
      Lemon_Chiffon => (R => 255, G => 250, B => 205),
      Light_Blue => (R => 173, G => 216, B => 230),
      Light_Coral => (R => 240, G => 128, B => 128),
      Light_Cyan => (R => 224, G => 255, B => 255),
      Light_Goldenrod_Yellow => (R => 250, G => 250, B => 210),
      Light_Green => (R => 144, G => 238, B => 144),
      Light_Pink => (R => 255, G => 182, B => 193),
      Light_Salmon => (R => 255, G => 160, B => 122),
      Light_Sea_Green => (R => 32, G => 178, B => 170),
      Light_Sky_Blue => (R => 135, G => 206, B => 250),
      Light_Slate_Gray => (R => 119, G => 136, B => 153),
      Light_Slate_Grey => (R => 119, G => 136, B => 153),
      Light_Steel_Blue => (R => 176, G => 196, B => 222),
      Light_Yellow => (R => 255, G => 255, B => 224),
      Lime_Green => (R => 50, G => 205, B => 50),
      Linen => (R => 250, G => 240, B => 230),
      Magenta => (R => 255, G => 0, B => 255),
      Medium_Aqua_Marine => (R => 102, G => 205, B => 170),
      Medium_Blue => (R => 0, G => 0, B => 205),
      Medium_Orchid => (R => 186, G => 85, B => 211),
      Medium_Purple => (R => 147, G => 112, B => 219),
      Medium_Sea_Green => (R => 60, G => 179, B => 113),
      Medium_Slate_Blue => (R => 123, G => 104, B => 238),
      Medium_Spring_Green => (R => 0, G => 250, B => 154),
      Medium_Turquoise => (R => 72, G => 209, B => 204),
      Medium_Violet_Red => (R => 199, G => 21, B => 133),
      Midnight_Blue => (R => 25, G => 25, B => 112),
      Mint_Cream => (R => 245, G => 255, B => 250),
      Misty_Rose => (R => 255, G => 228, B => 225),
      Moccasin => (R => 255, G => 228, B => 181),
      Navajo_White => (R => 255, G => 222, B => 173),
      Old_Lace => (R => 253, G => 245, B => 230),
      Olive_Drab => (R => 107, G => 142, B => 35),
      Orange_Red => (R => 255, G => 69, B => 0),
      Orchid => (R => 218, G => 112, B => 214),
      Pale_Goldenrod => (R => 238, G => 232, B => 170),
      Pale_Green => (R => 152, G => 251, B => 152),
      Pale_Turquoise => (R => 175, G => 238, B => 238),
      Pale_Violet_Red => (R => 219, G => 112, B => 147),
      Papaya_Whip => (R => 255, G => 239, B => 213),
      Peach_Puff => (R => 255, G => 218, B => 185),
      Peru => (R => 205, G => 133, B => 63),
      Pink => (R => 255, G => 192, B => 203),
      Plum => (R => 221, G => 160, B => 221),
      Powder_Blue => (R => 176, G => 224, B => 230),
      Rosy_Brown => (R => 188, G => 143, B => 143),
      Royal_Blue => (R => 65, G => 105, B => 225),
      Saddle_Brown => (R => 139, G => 69, B => 19),
      Salmon => (R => 250, G => 128, B => 114),
      Sandy_Brown => (R => 244, G => 164, B => 96),
      Sea_Green => (R => 46, G => 139, B => 87),
      Sea_Shell => (R => 255, G => 245, B => 238),
      Sienna => (R => 160, G => 82, B => 45),
      Sky_Blue => (R => 135, G => 206, B => 235),
      Slate_Blue => (R => 106, G => 90, B => 205),
      Slate_Gray => (R => 112, G => 128, B => 144),
      Slate_Grey => (R => 112, G => 128, B => 144),
      Snow => (R => 255, G => 250, B => 250),
      Spring_Green => (R => 0, G => 255, B => 127),
      Steel_Blue => (R => 70, G => 130, B => 180),
      Tan => (R => 210, G => 180, B => 140),
      Thistle => (R => 216, G => 191, B => 216),
      Tomato => (R => 255, G => 99, B => 71),
      Turquoise => (R => 64, G => 224, B => 208),
      Violet => (R => 238, G => 130, B => 238),
      Wheat => (R => 245, G => 222, B => 179),
      White_Smoke => (R => 245, G => 245, B => 245),
      Yellow_Green => (R => 154, G => 205, B => 50),
      Transparent => (R => 0, G => 0, B => 0),
      Inherit => (R => 0, G => 0, B => 0),
      Current_Color => (R => 0, G => 0, B => 0)
     );

   type Name_Entry is record
      Name  : access constant String;
      Value : Named_Color;
   end record;

   Named_Color_Name_Map : constant array (Positive range <>) of Name_Entry :=
     (
      (Name => new String'("black"), Value => Black),
      (Name => new String'("silver"), Value => Silver),
      (Name => new String'("gray"), Value => Gray),
      (Name => new String'("white"), Value => White),
      (Name => new String'("maroon"), Value => Maroon),
      (Name => new String'("red"), Value => Red),
      (Name => new String'("purple"), Value => Purple),
      (Name => new String'("fuchsia"), Value => Fuchsia),
      (Name => new String'("green"), Value => Green),
      (Name => new String'("lime"), Value => Lime),
      (Name => new String'("olive"), Value => Olive),
      (Name => new String'("yellow"), Value => Yellow),
      (Name => new String'("navy"), Value => Navy),
      (Name => new String'("blue"), Value => Blue),
      (Name => new String'("teal"), Value => Teal),
      (Name => new String'("aqua"), Value => Aqua),
      (Name => new String'("aliceblue"), Value => Alice_Blue),
      (Name => new String'("antiquewhite"), Value => Antique_White),
      (Name => new String'("aquamarine"), Value => Aqua_Marine),
      (Name => new String'("azure"), Value => Azure),
      (Name => new String'("beige"), Value => Beige),
      (Name => new String'("bisque"), Value => Bisque),
      (Name => new String'("blanchedalmond"), Value => Blanched_Almond),
      (Name => new String'("blueviolet"), Value => Blue_Violet),
      (Name => new String'("brown"), Value => Brown),
      (Name => new String'("burlywood"), Value => Burly_Wood),
      (Name => new String'("cadetblue"), Value => Cadet_Blue),
      (Name => new String'("chartreuse"), Value => Chartreuse),
      (Name => new String'("chocolate"), Value => Chocolate),
      (Name => new String'("coral"), Value => Coral),
      (Name => new String'("cornflowerblue"), Value => Cornflower_Blue),
      (Name => new String'("cornsilk"), Value => Corn_Silk),
      (Name => new String'("crimson"), Value => Crimson),
      (Name => new String'("cyan"), Value => Cyan),
      (Name => new String'("darkblue"), Value => Dark_Blue),
      (Name => new String'("darkcyan"), Value => Dark_Cyan),
      (Name => new String'("darkgoldenrod"), Value => Dark_Goldenrod),
      (Name => new String'("darkgray"), Value => Dark_Gray),
      (Name => new String'("darkgreen"), Value => Dark_Green),
      (Name => new String'("darkgrey"), Value => Dark_Gray),
      (Name => new String'("darkkhaki"), Value => Dark_Khaki),
      (Name => new String'("darkmagenta"), Value => Dark_Magenta),
      (Name => new String'("darkolivegreen"), Value => Dark_Olive_Green),
      (Name => new String'("darkorange"), Value => Dark_Orange),
      (Name => new String'("darkorchid"), Value => Dark_Orchid),
      (Name => new String'("darkred"), Value => Dark_Red),
      (Name => new String'("darksalmon"), Value => Dark_Salmon),
      (Name => new String'("darkseagreen"), Value => Dark_Sea_Green),
      (Name => new String'("darkslateblue"), Value => Dark_Slate_Blue),
      (Name => new String'("darkslategray"), Value => Dark_Slate_Gray),
      (Name => new String'("darkslategrey"), Value => Dark_Slate_Grey),
      (Name => new String'("darkturquoise"), Value => Dark_Turquoise),
      (Name => new String'("darkviolet"), Value => Dark_Violet),
      (Name => new String'("deeppink"), Value => Deep_Pink),
      (Name => new String'("deepskyblue"), Value => Deep_Sky_Blue),
      (Name => new String'("dimgray"), Value => Dim_Gray),
      (Name => new String'("dimgrey"), Value => Dim_Grey),
      (Name => new String'("dodgerblue"), Value => Dodger_Blue),
      (Name => new String'("firebrick"), Value => Fire_Brick),
      (Name => new String'("floralwhite"), Value => Floral_White),
      (Name => new String'("forestgreen"), Value => Forest_Green),
      (Name => new String'("gainsboro"), Value => Gainsboro),
      (Name => new String'("ghostwhite"), Value => Ghost_White),
      (Name => new String'("gold"), Value => Gold),
      (Name => new String'("goldenrod"), Value => Goldenrod),
      (Name => new String'("greenyellow"), Value => Green_Yellow),
      (Name => new String'("grey"), Value => Gray),
      (Name => new String'("honeydew"), Value => Honey_Dew),
      (Name => new String'("hotpink"), Value => Hot_Pink),
      (Name => new String'("indianred"), Value => Indian_Red),
      (Name => new String'("indigo"), Value => Indigo),
      (Name => new String'("ivory"), Value => Ivory),
      (Name => new String'("khaki"), Value => Khaki),
      (Name => new String'("lavender"), Value => Lavender),
      (Name => new String'("lavenderblush"), Value => Lavender_Blush),
      (Name => new String'("lawngreen"), Value => Lawn_Green),
      (Name => new String'("lemonchiffon"), Value => Lemon_Chiffon),
      (Name => new String'("lightblue"), Value => Light_Blue),
      (Name => new String'("lightcoral"), Value => Light_Coral),
      (Name => new String'("lightcyan"), Value => Light_Cyan),
      (Name => new String'("lightgoldenrodyellow"), Value => Light_Goldenrod_Yellow),
      (Name => new String'("lightgray"), Value => Light_Gray),
      (Name => new String'("lightgreen"), Value => Light_Green),
      (Name => new String'("lightgrey"), Value => Light_Gray),
      (Name => new String'("lightpink"), Value => Light_Pink),
      (Name => new String'("lightsalmon"), Value => Light_Salmon),
      (Name => new String'("lightseagreen"), Value => Light_Sea_Green),
      (Name => new String'("lightskyblue"), Value => Light_Sky_Blue),
      (Name => new String'("lightslategray"), Value => Light_Slate_Gray),
      (Name => new String'("lightslategrey"), Value => Light_Slate_Grey),
      (Name => new String'("lightsteelblue"), Value => Light_Steel_Blue),
      (Name => new String'("lightyellow"), Value => Light_Yellow),
      (Name => new String'("limegreen"), Value => Lime_Green),
      (Name => new String'("linen"), Value => Linen),
      (Name => new String'("magenta"), Value => Magenta),
      (Name => new String'("mediumaquamarine"), Value => Medium_Aqua_Marine),
      (Name => new String'("mediumblue"), Value => Medium_Blue),
      (Name => new String'("mediumorchid"), Value => Medium_Orchid),
      (Name => new String'("mediumpurple"), Value => Medium_Purple),
      (Name => new String'("mediumseagreen"), Value => Medium_Sea_Green),
      (Name => new String'("mediumslateblue"), Value => Medium_Slate_Blue),
      (Name => new String'("mediumspringgreen"), Value => Medium_Spring_Green),
      (Name => new String'("mediumturquoise"), Value => Medium_Turquoise),
      (Name => new String'("mediumvioletred"), Value => Medium_Violet_Red),
      (Name => new String'("midnightblue"), Value => Midnight_Blue),
      (Name => new String'("mintcream"), Value => Mint_Cream),
      (Name => new String'("mistyrose"), Value => Misty_Rose),
      (Name => new String'("moccasin"), Value => Moccasin),
      (Name => new String'("navajowhite"), Value => Navajo_White),
      (Name => new String'("oldlace"), Value => Old_Lace),
      (Name => new String'("olivedrab"), Value => Olive_Drab),
      (Name => new String'("orange"), Value => Orange),
      (Name => new String'("orangered"), Value => Orange_Red),
      (Name => new String'("orchid"), Value => Orchid),
      (Name => new String'("palegoldenrod"), Value => Pale_Goldenrod),
      (Name => new String'("palegreen"), Value => Pale_Green),
      (Name => new String'("paleturquoise"), Value => Pale_Turquoise),
      (Name => new String'("palevioletred"), Value => Pale_Violet_Red),
      (Name => new String'("papayawhip"), Value => Papaya_Whip),
      (Name => new String'("peachpuff"), Value => Peach_Puff),
      (Name => new String'("peru"), Value => Peru),
      (Name => new String'("pink"), Value => Pink),
      (Name => new String'("plum"), Value => Plum),
      (Name => new String'("powderblue"), Value => Powder_Blue),
      (Name => new String'("rosybrown"), Value => Rosy_Brown),
      (Name => new String'("royalblue"), Value => Royal_Blue),
      (Name => new String'("saddlebrown"), Value => Saddle_Brown),
      (Name => new String'("salmon"), Value => Salmon),
      (Name => new String'("sandybrown"), Value => Sandy_Brown),
      (Name => new String'("seagreen"), Value => Sea_Green),
      (Name => new String'("seashell"), Value => Sea_Shell),
      (Name => new String'("sienna"), Value => Sienna),
      (Name => new String'("skyblue"), Value => Sky_Blue),
      (Name => new String'("slateblue"), Value => Slate_Blue),
      (Name => new String'("slategray"), Value => Slate_Gray),
      (Name => new String'("slategrey"), Value => Slate_Grey),
      (Name => new String'("snow"), Value => Snow),
      (Name => new String'("springgreen"), Value => Spring_Green),
      (Name => new String'("steelblue"), Value => Steel_Blue),
      (Name => new String'("tan"), Value => Tan),
      (Name => new String'("thistle"), Value => Thistle),
      (Name => new String'("tomato"), Value => Tomato),
      (Name => new String'("turquoise"), Value => Turquoise),
      (Name => new String'("violet"), Value => Violet),
      (Name => new String'("wheat"), Value => Wheat),
      (Name => new String'("whitesmoke"), Value => White_Smoke),
      (Name => new String'("yellowgreen"), Value => Yellow_Green),
      (Name => new String'("transparent"), Value => Transparent),
      (Name => new String'("inherit"), Value => Inherit),
      (Name => new String'("currentcolor"), Value => Current_Color)
     );

   function Is_Whitespace (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Lower_Trimmed (Input : String) return String is
      First : Natural;
      Last  : Natural;
   begin
      if Input'Length = 0 then
         return "";
      end if;

      First := Input'First;
      Last := Input'Last;

      while First <= Input'Last and then Is_Whitespace (Input (First)) loop
         First := First + 1;
      end loop;

      while Last >= First and then Is_Whitespace (Input (Last)) loop
         Last := Last - 1;
      end loop;

      if First > Last then
         return "";
      end if;

      declare
         Result : String (1 .. Last - First + 1);
      begin
         for I in Result'Range loop
            Result (I) := Char.To_Lower (Input (First + I - 1));
         end loop;
         return Result;
      end;
   end Lower_Trimmed;

   function Parse_Named_Color
     (Name  : String;
      Value : out Named_Color) return Boolean
   is
      Key : constant String := Lower_Trimmed (Name);
   begin
      if Key'Length = 0 then
         return False;
      end if;

      for Name_Item of Named_Color_Name_Map loop
         if Key = Name_Item.Name.all then
            Value := Name_Item.Value;
            return True;
         end if;
      end loop;

      return False;
   end Parse_Named_Color;

   -------------------------------------------------
   -- Merge: Combine two Style_Rules (Override wins for set values)
   -------------------------------------------------

   function Merge (Base, Override : Style_Rules) return Style_Rules is
   begin
      return (
         -- Colors
         Color            => Opt_Text_Color.Merge (Base.Color, Override.Color),
         Background_Color => Opt_Bg_Color.Merge (Base.Background_Color, Override.Background_Color),
         Background_Image => Opt_Bg_Image.Merge (Base.Background_Image, Override.Background_Image),

         -- Border
         Border_Radius    => Opt_Radius.Merge (Base.Border_Radius, Override.Border_Radius),
         Border_Width     => Opt_Border_Width.Merge (Base.Border_Width, Override.Border_Width),
         Border_Color     => Opt_Border_Color.Merge (Base.Border_Color, Override.Border_Color),
         Border_Style     => Opt_Border_Style.Merge (Base.Border_Style, Override.Border_Style),

         -- Outline
         Outline_Width    => Opt_Outline_Width.Merge (Base.Outline_Width, Override.Outline_Width),
         Outline_Color    => Opt_Outline_Color.Merge (Base.Outline_Color, Override.Outline_Color),
         Outline_Style    => Opt_Outline_Style.Merge (Base.Outline_Style, Override.Outline_Style),
         Outline_Offset   => Opt_Outline_Offset.Merge (Base.Outline_Offset, Override.Outline_Offset),

         -- Spacing
         Padding          => Opt_Box.Merge (Base.Padding, Override.Padding),
         Margin           => Opt_Box.Merge (Base.Margin, Override.Margin),

         -- Sizing
         Width            => Opt_Size.Merge (Base.Width, Override.Width),
         Height           => Opt_Size.Merge (Base.Height, Override.Height),
         Min_Width        => Opt_Size.Merge (Base.Min_Width, Override.Min_Width),
         Max_Width        => Opt_Size.Merge (Base.Max_Width, Override.Max_Width),
         Min_Height       => Opt_Size.Merge (Base.Min_Height, Override.Min_Height),
         Max_Height       => Opt_Size.Merge (Base.Max_Height, Override.Max_Height),

         -- Typography
         Font_Size        => Opt_Font_Size.Merge (Base.Font_Size, Override.Font_Size),
         Font_Family      => Opt_Font.Merge (Base.Font_Family, Override.Font_Family),
         Font_Weight      => Opt_Font_Weight.Merge (Base.Font_Weight, Override.Font_Weight),
         Font_Style       => Opt_Font_Style.Merge (Base.Font_Style, Override.Font_Style),
         Text_Decoration  => Opt_Text_Decoration.Merge (Base.Text_Decoration, Override.Text_Decoration),
         List_Style_Type  => Opt_List_Style_Type.Merge (Base.List_Style_Type, Override.List_Style_Type),
         List_Style_Image => Opt_List_Style_Image.Merge (Base.List_Style_Image, Override.List_Style_Image),
         List_Style_Position => Opt_List_Style_Position.Merge (Base.List_Style_Position, Override.List_Style_Position),
         White_Space      => Opt_White_Space.Merge (Base.White_Space, Override.White_Space),
         Text_Overflow    => Opt_Text_Overflow.Merge (Base.Text_Overflow, Override.Text_Overflow),
         Text_Wrap_Mode   => Opt_Text_Wrap_Mode.Merge (Base.Text_Wrap_Mode, Override.Text_Wrap_Mode),
         Line_Height      => Opt_Line_Height.Merge (Base.Line_Height, Override.Line_Height),

         Text_Align       => Opt_Text_Align.Merge (Base.Text_Align, Override.Text_Align),
         Vertical_Align   => Opt_Vertical_Align.Merge (Base.Vertical_Align, Override.Vertical_Align),

         -- Layout
         Display          => Opt_Display.Merge (Base.Display, Override.Display),
         Position         => Opt_Position.Merge (Base.Position, Override.Position),
         Overflow         => Opt_Overflow.Merge (Base.Overflow, Override.Overflow),
         Visibility       => Opt_Visibility.Merge (Base.Visibility, Override.Visibility),

         -- Visual
         Opacity          => Opt_Opacity.Merge (Base.Opacity, Override.Opacity),
         Cursor           => Opt_Cursor.Merge (Base.Cursor, Override.Cursor),
         Box_Shadow       => Opt_Box_Shadow.Merge (Base.Box_Shadow, Override.Box_Shadow),

         -- Object/Image
         Object_Fit       => Opt_Object_Fit.Merge (Base.Object_Fit, Override.Object_Fit),
         Object_Position  => Opt_Object_Pos.Merge (Base.Object_Position, Override.Object_Position),

         -- Flexbox Container
         Flex_Direction   => Opt_Flex_Dir.Merge (Base.Flex_Direction, Override.Flex_Direction),
         Flex_Wrap        => Opt_Flex_Wrap.Merge (Base.Flex_Wrap, Override.Flex_Wrap),
         Justify_Content  => Opt_Justify.Merge (Base.Justify_Content, Override.Justify_Content),
         Align_Items      => Opt_Align_Items.Merge (Base.Align_Items, Override.Align_Items),
         Align_Content    => Opt_Align_Content.Merge (Base.Align_Content, Override.Align_Content),
         Gap              => Opt_Gap.Merge (Base.Gap, Override.Gap),
         Grid_Columns     => Opt_Grid_Cols.Merge (Base.Grid_Columns, Override.Grid_Columns),
         Grid_Rows        => Opt_Grid_Rows.Merge (Base.Grid_Rows, Override.Grid_Rows),

         -- Flexbox Item
         Align_Self       => Opt_Align_Self.Merge (Base.Align_Self, Override.Align_Self),
         Flex_Grow        => Opt_Flex_Grow.Merge (Base.Flex_Grow, Override.Flex_Grow),
         Flex_Shrink      => Opt_Flex_Shrink.Merge (Base.Flex_Shrink, Override.Flex_Shrink),
         Flex_Basis       => Opt_Flex_Basis.Merge (Base.Flex_Basis, Override.Flex_Basis),
         Order            => Opt_Order.Merge (Base.Order, Override.Order),
         Grid_Column      => Opt_Grid_Column.Merge (Base.Grid_Column, Override.Grid_Column),
         Grid_Row         => Opt_Grid_Row.Merge (Base.Grid_Row, Override.Grid_Row),
         Grid_Column_Span => Opt_Grid_Col_Span.Merge (Base.Grid_Column_Span, Override.Grid_Column_Span),
         Grid_Row_Span    => Opt_Grid_Row_Span.Merge (Base.Grid_Row_Span, Override.Grid_Row_Span),

         -- Animation
         Transition       => Opt_Transition.Merge (Base.Transition, Override.Transition)
      );
   end Merge;

   -------------------------------------------------
   -- Resolve: Convert Style_Rules to Resolved_Style
   -------------------------------------------------

   function Resolve (S : Style_Rules) return Resolved_Style is
   begin
      return (
         -- Colors
         Color            => Opt_Text_Color.Resolve (S.Color),
         Background_Color => Opt_Bg_Color.Resolve (S.Background_Color),
         Background_Image => Opt_Bg_Image.Resolve (S.Background_Image),

         -- Border
         Border_Radius    => Opt_Radius.Resolve (S.Border_Radius),
         Border_Width     => Opt_Border_Width.Resolve (S.Border_Width),
         Border_Color     => Opt_Border_Color.Resolve (S.Border_Color),
         Border_Style     => Opt_Border_Style.Resolve (S.Border_Style),

         -- Outline
         Outline_Width    => Opt_Outline_Width.Resolve (S.Outline_Width),
         Outline_Color    => Opt_Outline_Color.Resolve (S.Outline_Color),
         Outline_Style    => Opt_Outline_Style.Resolve (S.Outline_Style),
         Outline_Offset   => Opt_Outline_Offset.Resolve (S.Outline_Offset),

         -- Spacing
         Padding          => Opt_Box.Resolve (S.Padding),
         Margin           => Opt_Box.Resolve (S.Margin),

         -- Sizing
         Width            => Opt_Size.Resolve (S.Width),
         Height           => Opt_Size.Resolve (S.Height),
         Min_Width        => Opt_Size.Resolve (S.Min_Width),
         Max_Width        => Opt_Size.Resolve (S.Max_Width),
         Min_Height       => Opt_Size.Resolve (S.Min_Height),
         Max_Height       => Opt_Size.Resolve (S.Max_Height),

         -- Typography
         Font_Size        => Opt_Font_Size.Resolve (S.Font_Size),
         Font_Family      => Opt_Font.Resolve (S.Font_Family),
         Font_Weight      => Opt_Font_Weight.Resolve (S.Font_Weight),
         Font_Style       => Opt_Font_Style.Resolve (S.Font_Style),
         Text_Decoration  => Opt_Text_Decoration.Resolve (S.Text_Decoration),
         List_Style_Type  => Opt_List_Style_Type.Resolve (S.List_Style_Type),
         List_Style_Image => Opt_List_Style_Image.Resolve (S.List_Style_Image),
         List_Style_Position => Opt_List_Style_Position.Resolve (S.List_Style_Position),
         White_Space      => Opt_White_Space.Resolve (S.White_Space),
         Text_Overflow    => Opt_Text_Overflow.Resolve (S.Text_Overflow),
         Text_Wrap_Mode   => Opt_Text_Wrap_Mode.Resolve (S.Text_Wrap_Mode),
         Line_Height      => Opt_Line_Height.Resolve (S.Line_Height),

         Text_Align       => Opt_Text_Align.Resolve (S.Text_Align),
         Vertical_Align   => Opt_Vertical_Align.Resolve (S.Vertical_Align),

         -- Layout
         Display          => Opt_Display.Resolve (S.Display),
         Position         => Opt_Position.Resolve (S.Position),
         Overflow         => Opt_Overflow.Resolve (S.Overflow),
         Visibility       => Opt_Visibility.Resolve (S.Visibility),

         -- Visual
         Opacity          => Opt_Opacity.Resolve (S.Opacity),
         Cursor           => Opt_Cursor.Resolve (S.Cursor),
         Box_Shadow       => Opt_Box_Shadow.Resolve (S.Box_Shadow),

         -- Object/Image
         Object_Fit       => Opt_Object_Fit.Resolve (S.Object_Fit),
         Object_Position  => Opt_Object_Pos.Resolve (S.Object_Position),

         -- Flexbox Container
         Flex_Direction   => Opt_Flex_Dir.Resolve (S.Flex_Direction),
         Flex_Wrap        => Opt_Flex_Wrap.Resolve (S.Flex_Wrap),
         Justify_Content  => Opt_Justify.Resolve (S.Justify_Content),
         Align_Items      => Opt_Align_Items.Resolve (S.Align_Items),
         Align_Content    => Opt_Align_Content.Resolve (S.Align_Content),
         Gap              => Opt_Gap.Resolve (S.Gap),
         Grid_Columns     => Opt_Grid_Cols.Resolve (S.Grid_Columns),
         Grid_Rows        => Opt_Grid_Rows.Resolve (S.Grid_Rows),

         -- Flexbox Item
         Align_Self       => Opt_Align_Self.Resolve (S.Align_Self),
         Flex_Grow        => Opt_Flex_Grow.Resolve (S.Flex_Grow),
         Flex_Shrink      => Opt_Flex_Shrink.Resolve (S.Flex_Shrink),
         Flex_Basis       => Opt_Flex_Basis.Resolve (S.Flex_Basis),
         Order            => Opt_Order.Resolve (S.Order),
         Grid_Column      => Opt_Grid_Column.Resolve (S.Grid_Column),
         Grid_Row         => Opt_Grid_Row.Resolve (S.Grid_Row),
         Grid_Column_Span => Opt_Grid_Col_Span.Resolve (S.Grid_Column_Span),
         Grid_Row_Span    => Opt_Grid_Row_Span.Resolve (S.Grid_Row_Span),

         -- Animation
         Transition       => Opt_Transition.Resolve (S.Transition)
      );
   end Resolve;

   -------------------------------------------------
   -- Normalize_Color
   -------------------------------------------------

   procedure Normalize_Color (C : Color_Value;
                              R, G, B : out Natural;
                              A : out Float) is
   begin
      case C.Kind is
         when Named =>
            R := Named_Color_RGB (C.Name).R;
            G := Named_Color_RGB (C.Name).G;
            B := Named_Color_RGB (C.Name).B;
            A := (if C.Name = Transparent then 0.0 else 1.0);
         when RGB =>
            R := C.R; G := C.G; B := C.B; A := 1.0;
         when RGBA =>
            R := C.RA; G := C.GA; B := C.BA; A := C.Alpha;
      end case;
   end Normalize_Color;

end Adi.CSS_Styles;
