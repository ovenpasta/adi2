pragma Ada_2022;

with Ada.Directories;
with Ada.Strings.Fixed;
with Adi.App;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Font;
with Adi.Layout_Util;      use Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;           use Adi.Window;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles;    use Adi.Widget_Styles;
with Font_Example_Styles;  use Font_Example_Styles;

procedure Font_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

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
                           Family : Font_Handle) return Adi.Widget.Label.Label_Handle
   is
      L : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle (Text);
   begin
      Adi.Widget.Label.Set_Part_Styles (L, Sample_Class_Part_Styles);
      Set_Part_Style (+L, Label_Part,
        Build_Label_Widget (Sample_Class_Label_Base_Style, Extra, Family));
      return L;
   end Create_Sample;

   function Create_Wrap_Sample (Text   : String;
                                Family : Font_Handle) return Adi.Widget.Label.Label_Handle
   is
      L : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle (Text);
   begin
      Adi.Widget.Label.Set_Part_Styles (L, Wrap_Sample_Class_Part_Styles);
      Set_Part_Style (+L, Label_Part,
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
      W : constant Window_Handle := Create_Window_Handle ("Font & Text Features", (980.0, 860.0));

      Root      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Container : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Font and Text Features");
      Hint  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Shows weight, italic/oblique, and text decorations.");

      Section_Weight : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Weights");
      Section_Style : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Styles");
      Section_Size : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Sizes");
      Section_Deco : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Decorations");
      Section_Wrap : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Wrapping");
      Section_DPI : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("DPI Units (px vs dip)");

      Body_Font : constant Font_Handle := Load_Font_With_Variants;

      Weight_Normal_Sample   : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("Weight 400 (normal)", Weight_Normal_Class_Label_Base_Style, Body_Font);
      Weight_Light_Sample    : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("Weight 300 (light)", Weight_Light_Class_Label_Base_Style, Body_Font);
      Weight_Medium_Sample   : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("Weight 500 (medium)", Weight_Medium_Class_Label_Base_Style, Body_Font);
      Weight_Semibold_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("Weight 600 (semibold)", Weight_Semibold_Class_Label_Base_Style, Body_Font);
      Weight_Bold_Sample     : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("Weight 700 (bold)", Weight_Bold_Class_Label_Base_Style, Body_Font);
      Weight_Black_Sample    : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("Weight 900 (black)", Weight_Black_Class_Label_Base_Style, Body_Font);

      Italic_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("font-style: italic", Style_Italic_Class_Label_Base_Style, Body_Font);
      Oblique_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("font-style: oblique", Style_Oblique_Class_Label_Base_Style, Body_Font);

      Size_Small_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("font-size: 12px (small)", Size_Small_Class_Label_Base_Style, Body_Font);
      Size_Base_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("font-size: 18px (base)", Size_Base_Class_Label_Base_Style, Body_Font);
      Size_Large_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("font-size: 28px (large)", Size_Large_Class_Label_Base_Style, Body_Font);

      Underline_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("text-decoration: underline", Decor_Underline_Class_Label_Base_Style, Body_Font);
      Strike_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("text-decoration: line-through", Decor_Strike_Class_Label_Base_Style, Body_Font);
      Overline_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("text-decoration: overline",
          Decor_Overline_Class_Label_Base_Style, Body_Font);

      Wrap_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Wrap_Sample
          ("This is a wrapping sample using the same font pipeline. "
           & "It should wrap naturally and keep typography style settings.",
           Body_Font);

      DPI_Intro : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample
          ("These two labels use numeric size 18 with different units.",
           (Font_Size => Set_Font (Px (14)), Color => Set (RGB (191, 219, 254)), others => <>),
           Body_Font);
      DPI_Status : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample ("", (Font_Size => Set_Font (Px (13)),
                            Color => Set (RGB (125, 211, 252)),
                            others => <>), Body_Font);
      DPI_PX_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample
          ("font-size: 18px (fixed pixels)",
           (Font_Size => Set_Font (Px (18)), others => <>),
           Body_Font);
      DPI_DIP_Sample : constant Adi.Widget.Label.Label_Handle :=
        Create_Sample
          ("font-size: 18dip (display-scale aware)",
           (Font_Size => Set_Font (Dip (18)),
            Color     => Set (RGB (147, 197, 253)),
            others    => <>),
           Body_Font);
   begin
      if Font_Example_Styles.Has_Root_Font_Size then
         Set_Root_Font_Size (W, Font_Example_Styles.Root_Font_Size);
      end if;

      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Container, Container_Class_Part_Styles);

      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint, Hint_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Section_Weight, Section_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Section_Style, Section_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Section_Size, Section_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Section_Deco, Section_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Section_Wrap, Section_Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Section_DPI, Section_Title_Class_Part_Styles);

      if Body_Font /= Null_Font then
         Set_Part_Style (+Title, Label_Part,
           Build_Label_Widget (Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Hint, Label_Part,
           Build_Label_Widget (Hint_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Section_Weight, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Section_Style, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Section_Size, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Section_Deco, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Section_Wrap, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
         Set_Part_Style (+Section_DPI, Label_Part,
           Build_Label_Widget (Section_Title_Class_Label_Base_Style, Empty_Style, Body_Font));
      end if;

      Add_Child (+Root, +Container);

      Add_Child (+Container, +Title);
      Add_Child (+Container, +Hint);

      Add_Child (+Container, +Section_Weight);
      Add_Child (+Container, +Weight_Normal_Sample);
      Add_Child (+Container, +Weight_Light_Sample);
      Add_Child (+Container, +Weight_Medium_Sample);
      Add_Child (+Container, +Weight_Semibold_Sample);
      Add_Child (+Container, +Weight_Bold_Sample);
      Add_Child (+Container, +Weight_Black_Sample);

      Add_Child (+Container, +Section_Style);
      Add_Child (+Container, +Italic_Sample);
      Add_Child (+Container, +Oblique_Sample);

      Add_Child (+Container, +Section_Size);
      Add_Child (+Container, +Size_Small_Sample);
      Add_Child (+Container, +Size_Base_Sample);
      Add_Child (+Container, +Size_Large_Sample);

      Add_Child (+Container, +Section_Deco);
      Add_Child (+Container, +Underline_Sample);
      Add_Child (+Container, +Strike_Sample);
      Add_Child (+Container, +Overline_Sample);

      Add_Child (+Container, +Section_Wrap);
      Add_Child (+Container, +Wrap_Sample);

      Add_Child (+Container, +Section_DPI);
      Add_Child (+Container, +DPI_Intro);
      Adi.Widget.Label.Set_Text
        (DPI_Status,
         "Current active DIP scale: "
         & Ada.Strings.Fixed.Trim
           (Float'Image (Float (Get_Active_DIP_Scale)), Ada.Strings.Both));
      Add_Child (+Container, +DPI_Status);
      Add_Child (+Container, +DPI_PX_Sample);
      Add_Child (+Container, +DPI_DIP_Sample);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Font_Example;
