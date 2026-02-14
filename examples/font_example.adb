pragma Ada_2022;

with Ada.Directories;
with Ada.Strings.Fixed;
with Adi.App;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Font;
with Adi.Layout_Util;      use Adi.Layout_Util;
with Adi.Window;           use Adi.Window;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles;    use Adi.Widget_Styles;
with Font_Example_Styles;  use Font_Example_Styles;

procedure Font_Example is
   A : Adi.App.App;

   function Build_Label_Widget (Base, Extra : Style_Rules;
                                Family      : Font_Handle) return Widget_Style
   is
      Rules : Style_Rules := Merge (Base, Extra);
   begin
      if Family /= Null_Font then
         Rules := Merge (Rules, (Font_Family => Set (Family), others => <>));
      end if;
      return From (Rules).Build;
   end Build_Label_Widget;

   function Create_Sample (Text   : String;
                           Extra  : Style_Rules;
                           Family : Font_Handle) return Adi.Widget.Label.Label_Widget_Access
   is
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Styles (L.all, Sample_Class_Part_Styles);
      Set_Part_Style (L.all, Label_Part,
        Build_Label_Widget (Sample_Class_Label_Base_Style, Extra, Family));
      return L;
   end Create_Sample;

   function Create_Wrap_Sample (Text   : String;
                                Family : Font_Handle) return Adi.Widget.Label.Label_Widget_Access
   is
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Styles (L.all, Wrap_Sample_Class_Part_Styles);
      Set_Part_Style (L.all, Label_Part,
        Build_Label_Widget (Wrap_Sample_Class_Label_Base_Style, Empty_Style, Family));
      return L;
   end Create_Wrap_Sample;

   function Load_Font_With_Variants return Font_Handle is
      use Ada.Directories;

      Base_Regular : constant String := "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
      Base_Bold    : constant String := "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf";
      Base_Italic  : constant String := "/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf";
      Base_BI      : constant String := "/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf";
      F            : Font_Handle := Null_Font;
   begin
      if not Exists (Base_Regular) then
         return Null_Font;
      end if;

      F := Adi.Font.Load (Base_Regular);

      if Exists (Base_Bold) then
         Adi.Font.Register_Variant (F, Weight_Semi_Bold, Style_Normal, Base_Bold);
         Adi.Font.Register_Variant (F, Weight_Bold, Style_Normal, Base_Bold);
         Adi.Font.Register_Variant (F, Weight_Extra_Bold, Style_Normal, Base_Bold);
         Adi.Font.Register_Variant (F, Weight_Black, Style_Normal, Base_Bold);
      end if;

      if Exists (Base_Italic) then
         Adi.Font.Register_Variant (F, Weight_Normal, Style_Italic, Base_Italic);
         Adi.Font.Register_Variant (F, Weight_Normal, Style_Oblique, Base_Italic);
         Adi.Font.Register_Variant (F, Weight_Medium, Style_Italic, Base_Italic);
         Adi.Font.Register_Variant (F, Weight_Medium, Style_Oblique, Base_Italic);
      end if;

      if Exists (Base_BI) then
         Adi.Font.Register_Variant (F, Weight_Semi_Bold, Style_Italic, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Semi_Bold, Style_Oblique, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Bold, Style_Italic, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Bold, Style_Oblique, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Extra_Bold, Style_Italic, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Extra_Bold, Style_Oblique, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Black, Style_Italic, Base_BI);
         Adi.Font.Register_Variant (F, Weight_Black, Style_Oblique, Base_BI);
      end if;

      return F;
   end Load_Font_With_Variants;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Font & Text Features", (980.0, 860.0));

      Root      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Font and Text Features");
      Hint  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Shows weight, italic/oblique, and text decorations.");

      Section_Weight : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Weights");
      Section_Style : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Styles");
      Section_Size : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Sizes");
      Section_Deco : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Decorations");
      Section_Wrap : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Wrapping");
      Section_DPI : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("DPI Units (px vs dip)");

      Body_Font : constant Font_Handle := Load_Font_With_Variants;

      Weight_Normal_Sample   : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("Weight 400 (normal)", Weight_Normal_Class_Label_Base_Style, Body_Font);
      Weight_Light_Sample    : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("Weight 300 (light)", Weight_Light_Class_Label_Base_Style, Body_Font);
      Weight_Medium_Sample   : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("Weight 500 (medium)", Weight_Medium_Class_Label_Base_Style, Body_Font);
      Weight_Semibold_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("Weight 600 (semibold)", Weight_Semibold_Class_Label_Base_Style, Body_Font);
      Weight_Bold_Sample     : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("Weight 700 (bold)", Weight_Bold_Class_Label_Base_Style, Body_Font);
      Weight_Black_Sample    : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("Weight 900 (black)", Weight_Black_Class_Label_Base_Style, Body_Font);

      Italic_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("font-style: italic", Style_Italic_Class_Label_Base_Style, Body_Font);
      Oblique_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("font-style: oblique", Style_Oblique_Class_Label_Base_Style, Body_Font);

      Size_Small_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("font-size: 12px (small)", Size_Small_Class_Label_Base_Style, Body_Font);
      Size_Base_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("font-size: 18px (base)", Size_Base_Class_Label_Base_Style, Body_Font);
      Size_Large_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("font-size: 28px (large)", Size_Large_Class_Label_Base_Style, Body_Font);

      Underline_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("text-decoration: underline", Decor_Underline_Class_Label_Base_Style, Body_Font);
      Strike_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("text-decoration: line-through", Decor_Strike_Class_Label_Base_Style, Body_Font);
      Overline_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("text-decoration: overline",
          Decor_Overline_Class_Label_Base_Style, Body_Font);

      Wrap_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Wrap_Sample
          ("This is a wrapping sample using the same font pipeline. "
           & "It should wrap naturally and keep typography style settings.",
           Body_Font);

      DPI_Intro : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample
          ("These two labels use numeric size 18 with different units.",
           (Font_Size => Set_Font (Px (14)), Color => Set (RGB (191, 219, 254)), others => <>),
           Body_Font);
      DPI_Status : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample ("", (Font_Size => Set_Font (Px (13)),
                            Color => Set (RGB (125, 211, 252)),
                            others => <>), Body_Font);
      DPI_PX_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample
          ("font-size: 18px (fixed pixels)",
           (Font_Size => Set_Font (Px (18)), others => <>),
           Body_Font);
      DPI_DIP_Sample : constant Adi.Widget.Label.Label_Widget_Access :=
        Create_Sample
          ("font-size: 18dip (display-scale aware)",
           (Font_Size => Set_Font (Dip (18)),
            Color     => Set (RGB (147, 197, 253)),
            others    => <>),
           Body_Font);
   begin
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Container.all, Container_Class_Part_Styles);

      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Section_Weight.all, Section_Title_Class_Part_Styles);
      Set_Part_Styles (Section_Style.all, Section_Title_Class_Part_Styles);
      Set_Part_Styles (Section_Size.all, Section_Title_Class_Part_Styles);
      Set_Part_Styles (Section_Deco.all, Section_Title_Class_Part_Styles);
      Set_Part_Styles (Section_Wrap.all, Section_Title_Class_Part_Styles);
      Set_Part_Styles (Section_DPI.all, Section_Title_Class_Part_Styles);

      if Body_Font /= Null_Font then
         Set_Part_Style (Title.all, Label_Part,
           Build_Label_Widget (Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Hint.all, Label_Part,
           Build_Label_Widget (Hint_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Section_Weight.all, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Section_Style.all, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Section_Size.all, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Section_Deco.all, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Section_Wrap.all, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (Section_DPI.all, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
      end if;

      Root.Add_Child (Container);

      Container.Add_Child (Title);
      Container.Add_Child (Hint);

      Container.Add_Child (Section_Weight);
      Container.Add_Child (Weight_Normal_Sample);
      Container.Add_Child (Weight_Light_Sample);
      Container.Add_Child (Weight_Medium_Sample);
      Container.Add_Child (Weight_Semibold_Sample);
      Container.Add_Child (Weight_Bold_Sample);
      Container.Add_Child (Weight_Black_Sample);

      Container.Add_Child (Section_Style);
      Container.Add_Child (Italic_Sample);
      Container.Add_Child (Oblique_Sample);

      Container.Add_Child (Section_Size);
      Container.Add_Child (Size_Small_Sample);
      Container.Add_Child (Size_Base_Sample);
      Container.Add_Child (Size_Large_Sample);

      Container.Add_Child (Section_Deco);
      Container.Add_Child (Underline_Sample);
      Container.Add_Child (Strike_Sample);
      Container.Add_Child (Overline_Sample);

      Container.Add_Child (Section_Wrap);
      Container.Add_Child (Wrap_Sample);

      Container.Add_Child (Section_DPI);
      Container.Add_Child (DPI_Intro);
      Adi.Widget.Label.Set_Text
        (DPI_Status.all,
         "Current active DIP scale: "
         & Ada.Strings.Fixed.Trim
           (Float'Image (Float (Get_Active_DIP_Scale)), Ada.Strings.Both));
      Container.Add_Child (DPI_Status);
      Container.Add_Child (DPI_PX_Sample);
      Container.Add_Child (DPI_DIP_Sample);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Font_Example;
