pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Parser;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;

procedure Css_Parser_Test is

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      Test_Count := Test_Count + 1;
      if Cond then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Msg);
      else
         Put_Line ("  [FAIL] " & Msg);
      end if;
   end Assert;

   function Nearly_Equal (A, B : Float; Eps : Float := 0.0001) return Boolean is
   begin
      return abs (A - B) <= Eps;
   end Nearly_Equal;

   function Is_RGB_Color (Col : Color_Value; R, G, B : Natural) return Boolean is
   begin
      return Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B;
   end Is_RGB_Color;

   function Is_RGBA_Color (Col : Color_Value; R, G, B : Natural; A : Float) return Boolean is
   begin
      return Col.Kind = RGBA
        and then Col.RA = R
        and then Col.GA = G
        and then Col.BA = B
        and then Nearly_Equal (Col.Alpha, A, 0.01);
   end Is_RGBA_Color;

   function Is_Named_Color (Col : Color_Value; Name : Named_Color) return Boolean is
   begin
      return Col.Kind = Named and then Col.Name = Name;
   end Is_Named_Color;

   procedure Write_Text_File (Path : String; Content : String) is
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   end Write_Text_File;

   Sheet : Adi.CSS_Parser.Stylesheet;
   OK    : Boolean := False;

   CSS : constant String :=
     "/* base + comma selector */" & ASCII.LF &
     ".card, .panel {" & ASCII.LF &
     "  background-color: rgba(16,34,51,0.8);" & ASCII.LF &
     "  color: white;" & ASCII.LF &
     "  padding: 4px 8px;" & ASCII.LF &
     "  margin: 1px 2px 3px 4px;" & ASCII.LF &
     "  border-width: 1px 2px;" & ASCII.LF &
     "  border-style: solid;" & ASCII.LF &
     "  border-color: #445566;" & ASCII.LF &
     "  border-radius: 3px 6px;" & ASCII.LF &
     "  width: 120px;" & ASCII.LF &
     "  min-height: 40px;" & ASCII.LF &
     "  font-size: 13px;" & ASCII.LF &
     "  font-weight: 700;" & ASCII.LF &
     "  font-style: italic;" & ASCII.LF &
     "  text-align: center;" & ASCII.LF &
     "  text-wrap-mode: nowrap;" & ASCII.LF &
     "  display: flex;" & ASCII.LF &
     "  position: relative;" & ASCII.LF &
     "  overflow: hidden;" & ASCII.LF &
     "  opacity: 0.75;" & ASCII.LF &
     "  cursor: pointer;" & ASCII.LF &
     "  flex-direction: column;" & ASCII.LF &
     "  justify-content: center;" & ASCII.LF &
     "  align-items: flex-end;" & ASCII.LF &
     "  gap: 5px 9px;" & ASCII.LF &
     "  flex-grow: 2;" & ASCII.LF &
     "  flex-shrink: 3;" & ASCII.LF &
     "  flex-basis: 11px;" & ASCII.LF &
     "  order: 7;" & ASCII.LF &
     "  box-shadow: 2px 4px 6px rgba(10,20,30,0.4);" & ASCII.LF &
     "  transition: background-color 500ms ease;" & ASCII.LF &
     "}" & ASCII.LF &
     ".card:hover { background-color: rgb(1, 2, 3); }" & ASCII.LF &
     ".card:focus { border-color: rgb(9, 9, 9); }" & ASCII.LF &
     ".card:selected { background-color: rgb(7, 8, 9); }" & ASCII.LF &
     ".card:enabled { color: rgb(3, 4, 5); }" & ASCII.LF &
     ".card:not(:disabled) { border-width: 4px; }" & ASCII.LF &
     ".card::main:hover { opacity: 0.5; }" & ASCII.LF &
     ".card::label { color: rgb(50, 60, 70); }" & ASCII.LF &
     ".card::label:hover { color: rgb(220, 38, 38); }" & ASCII.LF &
     ".card::label:pressed { color: rgb(0, 0, 255); }" & ASCII.LF &
     ".card::label:focus { color: rgb(88, 77, 66); }" & ASCII.LF &
     "#submit { background-color: rgb(12, 34, 56); }" & ASCII.LF &
     "button { color: rgb(9, 8, 7); }" & ASCII.LF &
      ".seconds { transition: opacity 1.25s linear; }" & ASCII.LF &
      ".sides { padding: 1px 2px 3px 4px; padding-left: 11px; margin: 5px; margin-top: 9px; }" & ASCII.LF &
      ".dpunit { padding: 7dp; }" & ASCII.LF &
       ".listprobe { list-style: url(app://marker.svg) square outside; }" & ASCII.LF &
       ".listprobe2 { list-style: ""-> ""; }" & ASCII.LF &
       ".listprobe3 { list-style-type: disc; list-style-image: none; list-style-position: inside; }" & ASCII.LF &
       ".listprobe4 { list-style: none; }" & ASCII.LF &
       ".svgnamed { color: cornflowerblue; background-color: lightgoldenrodyellow; border-color: darkslategray; }" & ASCII.LF &
       ".svgalias { color: grey; }" & ASCII.LF &
       ".svgaqua { color: aqua; }" & ASCII.LF &
       ".svgcyan { color: cyan; }" & ASCII.LF &
       "li, ul, p { color: red; }" & ASCII.LF &
       "li, ul, p { padding: 2px; }" & ASCII.LF &
       ".outline-long { outline-width: 3px; outline-style: solid; outline-color: rgb(100, 200, 50); outline-offset: 4px; }" & ASCII.LF &
       ".outline-short { outline: 2px solid rgb(208, 188, 255); }" & ASCII.LF &
       ".outline-offset { outline: 1px dashed red; outline-offset: 5px; }" & ASCII.LF &
       ".outline-none { outline: none; }" & ASCII.LF &
       --  Missing property coverage
       ".sizing { height: 200px; min-width: 50px; max-width: 400px; max-height: 300px; }" & ASCII.LF &
       ".textprops { text-decoration: underline; white-space: pre-wrap; text-overflow: ellipsis; line-height: 1.5; vertical-align: middle; }" & ASCII.LF &
       ".misc { visibility: hidden; object-fit: cover; object-position: center center; }" & ASCII.LF &
       ".misc2 { object-position: 10px 20px; }" & ASCII.LF &
       ".overflowy { overflow-y: auto; }" & ASCII.LF &
       ".overflowx { overflow-x: hidden; }" & ASCII.LF &
       ".overflowmix { overflow: hidden; overflow-y: auto; }" & ASCII.LF &
       ".overflowmix2 { overflow-y: auto; overflow: hidden; }" & ASCII.LF &
       ".flexextra { flex-wrap: wrap; align-self: stretch; align-content: space-between; }" & ASCII.LF &
       ".gridcontainer { display: grid; grid-template-columns: repeat(3, 1fr); grid-template-rows: 1fr 1fr; gap: 10px; }" & ASCII.LF &
       ".gridmixed { display: grid; grid-template-columns: auto auto 1fr; }" & ASCII.LF &
       ".griditem { grid-column: 1 / 3; grid-row: span 2; }" & ASCII.LF &
       ".shadowtest { box-shadow: none; }" & ASCII.LF &
       ".pad1 { padding: 5px; }" & ASCII.LF &
       ".margin3 { margin: 1px 2px 3px; }" & ASCII.LF &
       ".displayvals { display: inline-flex; }" & ASCII.LF &
       ".linepx { line-height: 20px; }" & ASCII.LF &
       ".linenormal { line-height: normal; }" & ASCII.LF &
       ".widthauto { width: auto; }" & ASCII.LF &
       ".basisauto { flex-basis: auto; }" & ASCII.LF &
       ".basiscontent { flex-basis: content; }" & ASCII.LF &
       ".pressed-pseudo { background-color: rgb(11, 22, 33); }" & ASCII.LF &
       ".pressed-pseudo:active { background-color: rgb(44, 55, 66); }" & ASCII.LF;

begin
   Put_Line ("CSS parser test");

   Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
   Assert (OK, "Load_String should parse CSS content");
   if not OK then
      Put_Line ("Parser error: " & Adi.CSS_Parser.Get_Last_Error (Sheet));
      return;
   end if;

   Assert (Adi.CSS_Parser.Has_Class (Sheet, "card"), "Has_Class should find '.card'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "panel"), "Has_Class should include comma selector '.panel'");
   Assert (Adi.CSS_Parser.Has_Id (Sheet, "submit"), "Has_Id should parse '#submit' key");
   Assert (Adi.CSS_Parser.Has_Tag (Sheet, "button"), "Has_Tag should parse bare tag selector");
   Assert (Adi.CSS_Parser.Has (Sheet, Adi.CSS_Parser.Class_Selector, "card"),
           "Has(kind,name) should find class selector");
   Assert (Adi.CSS_Parser.Has (Sheet, Adi.CSS_Parser.Id_Selector, "submit"),
           "Has(kind,name) should find id selector");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "dpunit"), "Has_Class should parse '.dpunit'");
   Assert (Adi.CSS_Parser.Has_Tag (Sheet, "li"), "Has_Tag should parse grouped tag selector 'li'");
   Assert (Adi.CSS_Parser.Has_Tag (Sheet, "ul"), "Has_Tag should parse grouped tag selector 'ul'");
   Assert (Adi.CSS_Parser.Has_Tag (Sheet, "p"), "Has_Tag should parse grouped tag selector 'p'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe"), "Has_Class should parse '.listprobe'");
    Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe2"), "Has_Class should parse '.listprobe2'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe3"), "Has_Class should parse '.listprobe3'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "listprobe4"), "Has_Class should parse '.listprobe4'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgnamed"), "Has_Class should parse '.svgnamed'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgalias"), "Has_Class should parse '.svgalias'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgaqua"), "Has_Class should parse '.svgaqua'");
   Assert (Adi.CSS_Parser.Has_Class (Sheet, "svgcyan"), "Has_Class should parse '.svgcyan'");
   Assert (not Adi.CSS_Parser.Has_Class (Sheet, "missing"), "Has_Class should be false for unknown class");
   Assert (not Adi.CSS_Parser.Has_Id (Sheet, "card"), "Has_Id should not match class selector");

   declare
      Styles         : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "card");
      Panel_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "panel");
      Submit_Styles  : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Id (Sheet, "submit");
      Tag_Styles     : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Tag (Sheet, "button");
      Seconds_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "seconds");
      Sides_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "sides");
      UL_Styles      : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Tag (Sheet, "ul");
      Listprobe_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe");
      Listprobe2_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe2");
      Listprobe3_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe3");
      Listprobe4_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "listprobe4");
      SvgNamed_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "svgnamed");
      SvgAlias_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "svgalias");
      SvgAqua_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "svgaqua");
      SvgCyan_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "svgcyan");
      Missing_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For (Sheet, "missing");
      DP_Styles      : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "dpunit");

      Main_Normal : constant Resolved_Style := Compute_Resolved (Styles (Main_Part).Style, No_States, No_States);
      Main_Hover  : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Hovered => True],
         No_States);
      Main_Focus  : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Focused => True],
         No_States);
      Main_Selected : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Selected => True],
         No_States);
      Main_Disabled : constant Resolved_Style := Compute_Resolved (
         Styles (Main_Part).Style,
         [No_States with delta State_Disabled => True],
         No_States);

      Label_Base : constant Resolved_Style := Compute_Resolved (Styles (Label_Part).Style, No_States, No_States);
      Label_Part_Hover : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         No_States,
         [No_States with delta State_Hovered => True]);
      Label_Part_Press : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         No_States,
         [No_States with delta State_Pressed => True]);
      Label_Widget_Focus : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         [No_States with delta State_Focused => True],
         No_States);
      Label_Widget_Hover : constant Resolved_Style := Compute_Resolved (
         Styles (Label_Part).Style,
         [No_States with delta State_Hovered => True],
         No_States);

      Panel_Main : constant Resolved_Style := Compute_Resolved (Panel_Styles (Main_Part).Style, No_States, No_States);
      Submit_Main : constant Resolved_Style := Compute_Resolved (Submit_Styles (Main_Part).Style, No_States, No_States);
      Tag_Main : constant Resolved_Style := Compute_Resolved (Tag_Styles (Main_Part).Style, No_States, No_States);
      Seconds_Main : constant Resolved_Style := Compute_Resolved (Seconds_Styles (Main_Part).Style, No_States, No_States);
      Sides_Main : constant Resolved_Style := Compute_Resolved (Sides_Styles (Main_Part).Style, No_States, No_States);
      UL_Main    : constant Resolved_Style := Compute_Resolved (UL_Styles (Main_Part).Style, No_States, No_States);
      Listprobe_Main : constant Resolved_Style := Compute_Resolved (Listprobe_Styles (Main_Part).Style, No_States, No_States);
      Listprobe2_Main : constant Resolved_Style := Compute_Resolved (Listprobe2_Styles (Main_Part).Style, No_States, No_States);
      Listprobe3_Main : constant Resolved_Style := Compute_Resolved (Listprobe3_Styles (Main_Part).Style, No_States, No_States);
      Listprobe4_Main : constant Resolved_Style := Compute_Resolved (Listprobe4_Styles (Main_Part).Style, No_States, No_States);
      SvgNamed_Main : constant Resolved_Style := Compute_Resolved (SvgNamed_Styles (Main_Part).Style, No_States, No_States);
      SvgAlias_Main : constant Resolved_Style := Compute_Resolved (SvgAlias_Styles (Main_Part).Style, No_States, No_States);
      SvgAqua_Main : constant Resolved_Style := Compute_Resolved (SvgAqua_Styles (Main_Part).Style, No_States, No_States);
      SvgCyan_Main : constant Resolved_Style := Compute_Resolved (SvgCyan_Styles (Main_Part).Style, No_States, No_States);
      Missing_Main : constant Resolved_Style := Compute_Resolved (Missing_Styles (Main_Part).Style, No_States, No_States);
      DP_Main      : constant Resolved_Style := Compute_Resolved (DP_Styles (Main_Part).Style, No_States, No_States);
   begin
      Assert (Is_RGBA_Color (Main_Normal.Background_Color, 16, 34, 51, 0.8),
              "RGBA background-color should parse");
      Assert (Is_RGB_Color (Main_Normal.Color, 3, 4, 5),
              "Color should reflect :enabled override on normal state");

      Assert (Main_Normal.Padding.Kind = Axis
              and then Main_Normal.Padding.Vertical.Amount = 4.0
              and then Main_Normal.Padding.Horizontal.Amount = 8.0,
              "Padding 2-value shorthand should parse");
      Assert (Main_Normal.Margin.Kind = Per_Side
              and then Main_Normal.Margin.Sides (Top).Amount = 1.0
              and then Main_Normal.Margin.Sides (Right).Amount = 2.0
              and then Main_Normal.Margin.Sides (Bottom).Amount = 3.0
              and then Main_Normal.Margin.Sides (Left).Amount = 4.0,
              "Margin 4-value shorthand should parse");

      Assert (Main_Normal.Border_Width.Kind = Gap_Uniform
              and then Main_Normal.Border_Width.All_Edges.Amount = 4.0,
              "Normal state should reflect :not(:disabled) border-width override");
      Assert (Main_Normal.Border_Style.Kind = Gap_Uniform
              and then Main_Normal.Border_Style.All_Edges = Solid,
              "Border-style should parse");
      Assert (Main_Normal.Border_Color.Kind = Gap_Uniform
              and then Is_RGB_Color (Main_Normal.Border_Color.All_Edges, 68, 85, 102),
              "Border-color hex should parse");
      Assert (Main_Normal.Border_Radius.Kind = Per_Corner
              and then Main_Normal.Border_Radius.Corners (Top_Left).Amount = 3.0
              and then Main_Normal.Border_Radius.Corners (Top_Right).Amount = 6.0,
              "Border-radius 2-value shorthand should parse");

      Assert (Main_Normal.Width.Kind = Fixed and then Main_Normal.Width.Size.Amount = 120.0,
              "Width should parse fixed size");
      Assert (Main_Normal.Min_Height.Kind = Fixed and then Main_Normal.Min_Height.Size.Amount = 40.0,
              "Min-height should parse fixed size");
      Assert (Main_Normal.Font_Size.Amount = 13.0 and then Main_Normal.Font_Size.Unit = Px,
              "Font-size should parse");
      Assert (DP_Main.Padding.Kind = Gap_Uniform
              and then DP_Main.Padding.All_Sides.Unit = Dip
              and then DP_Main.Padding.All_Sides.Amount = 7.0,
              "dp length unit should parse as Dip");
      Assert (Main_Normal.Font_Weight = Weight_Bold,
              "Font-weight 700 should parse to Weight_Bold");
      Assert (Main_Normal.Font_Style = Style_Italic,
              "Font-style italic should parse");
      Assert (Main_Normal.Text_Align = Text_Center,
              "Text-align center should parse");
      Assert (Main_Normal.Text_Wrap_Mode = TWM_Nowrap,
              "Text-wrap-mode nowrap should parse");

      Assert (Main_Normal.Display = Flex and then Main_Normal.Position = Relative,
              "Display and position should parse");
      Assert (Main_Normal.Overflow_X = Overflow_Hidden
              and then Main_Normal.Overflow_Y = Overflow_Hidden,
              "Overflow hidden should parse");
      Assert (Nearly_Equal (Float (Main_Normal.Opacity), 0.75),
              "Opacity should parse");
      Assert (Main_Normal.Cursor = Cursor_Pointer,
              "Cursor pointer should parse");

      Assert (Main_Normal.Flex_Direction = Column
              and then Main_Normal.Justify_Content = Center
              and then Main_Normal.Align_Items = Flex_End,
              "Flex container properties should parse");
      Assert (Main_Normal.Gap.Kind = Gap_Separate
              and then Main_Normal.Gap.Row_Gap.Amount = 5.0
              and then Main_Normal.Gap.Column_Gap.Amount = 9.0,
              "Gap 2-value should parse to separate row/column gaps");
      Assert (Nearly_Equal (Float (Main_Normal.Flex_Grow), 2.0)
              and then Nearly_Equal (Float (Main_Normal.Flex_Shrink), 3.0)
              and then Main_Normal.Flex_Basis.Kind = Fixed
              and then Main_Normal.Flex_Basis.Size.Amount = 11.0
              and then Main_Normal.Order = 7,
              "Flex item properties should parse");

      Assert (Main_Normal.Box_Shadow.Offset_X.Amount = 2.0
              and then Main_Normal.Box_Shadow.Offset_Y.Amount = 4.0
              and then Main_Normal.Box_Shadow.Blur_Radius.Amount = 6.0
              and then Is_RGBA_Color (Main_Normal.Box_Shadow.Color, 10, 20, 30, 0.4),
              "Box-shadow should parse lengths and rgba color");
      Assert (Nearly_Equal (Main_Normal.Transition.Duration, 0.5)
              and then Main_Normal.Transition.Easing = Ease_In_Out
              and then Main_Normal.Transition.Properties (Prop_Background_Color)
              and then not Main_Normal.Transition.Properties (Prop_Color),
              "Transition should parse ms duration, easing, and property filter");

      Assert (Is_RGB_Color (Main_Hover.Background_Color, 1, 2, 3),
              "Widget hover should apply .card:hover");
      Assert (Nearly_Equal (Float (Main_Hover.Opacity), 0.5),
              "Widget hover should apply .card::main:hover override");
      Assert (Main_Disabled.Border_Width.Kind = Per_Edge
              and then Main_Disabled.Border_Width.Edges (Top).Amount = 1.0,
              "Disabled state should not match :not(:disabled) or :enabled rules");
      Assert (Is_Named_Color (Main_Disabled.Color, White),
              "Disabled state should keep base color when :enabled rule does not match");
      Assert (Main_Focus.Border_Color.Kind = Gap_Uniform
              and then Is_RGB_Color (Main_Focus.Border_Color.All_Edges, 9, 9, 9),
              "Focus state should apply .card:focus");
      Assert (Is_RGB_Color (Main_Selected.Background_Color, 7, 8, 9),
              "Selected state should apply .card:selected");
      Assert (Is_RGB_Color (Main_Normal.Color, 3, 4, 5),
              "Enabled and not-disabled rules should affect normal state");

      Assert (Is_RGB_Color (Label_Base.Color, 50, 60, 70),
              "Label base style should parse");
      Assert (Is_RGB_Color (Label_Part_Hover.Color, 220, 38, 38),
              "Label part hover should be part-scoped");
      Assert (Is_RGB_Color (Label_Part_Press.Color, 0, 0, 255),
              "Label part pressed should be part-scoped");
      Assert (Is_RGB_Color (Label_Widget_Focus.Color, 88, 77, 66),
              "Label focus pseudo should be widget-scoped");
      Assert (Is_RGB_Color (Label_Widget_Hover.Color, 50, 60, 70),
              "Label widget hover should keep base color (not part hover)");

      Assert (Is_RGBA_Color (Panel_Main.Background_Color, 16, 34, 51, 0.8),
              "Comma selector should duplicate base styles to .panel");
      Assert (Is_RGB_Color (Submit_Main.Background_Color, 12, 34, 56),
              "#id selector should map to id-style lookup");
      Assert (Is_RGB_Color (Tag_Main.Color, 9, 8, 7),
              "Tag selector should map to tag-style lookup");
      Assert (Is_Named_Color (UL_Main.Color, Red),
              "Grouped tag selector should apply base declarations");
      Assert (UL_Main.Padding.Kind = Gap_Uniform
              and then UL_Main.Padding.All_Sides.Amount = 2.0,
              "Repeated grouped tag selector blocks should merge declarations");
      Assert (Nearly_Equal (Seconds_Main.Transition.Duration, 1.25)
              and then Seconds_Main.Transition.Easing = Linear
              and then Seconds_Main.Transition.Properties (Prop_Opacity)
              and then not Seconds_Main.Transition.Properties (Prop_Background_Color),
              "Transition should parse seconds duration and linear easing");
      Assert (Sides_Main.Padding.Kind = Per_Side
              and then Sides_Main.Padding.Sides (Top).Amount = 1.0
              and then Sides_Main.Padding.Sides (Right).Amount = 2.0
              and then Sides_Main.Padding.Sides (Bottom).Amount = 3.0
              and then Sides_Main.Padding.Sides (Left).Amount = 11.0,
              "Padding side longhands should override shorthand per side");
      Assert (Sides_Main.Margin.Kind = Per_Side
              and then Sides_Main.Margin.Sides (Top).Amount = 9.0
              and then Sides_Main.Margin.Sides (Right).Amount = 5.0
              and then Sides_Main.Margin.Sides (Bottom).Amount = 5.0
              and then Sides_Main.Margin.Sides (Left).Amount = 5.0,
              "Margin side longhands should override shorthand per side");
      Assert (Listprobe_Main.List_Style_Type.Kind = List_Style_Square,
              "list-style shorthand should parse list-style-type keyword");
      Assert (Listprobe_Main.List_Style_Image.Kind = List_Image_URL
              and then To_String (Listprobe_Main.List_Style_Image.URI) = "app://marker.svg",
              "list-style shorthand should parse list-style-image url");
      Assert (Listprobe_Main.List_Style_Position = List_Outside,
              "list-style shorthand should parse list-style-position keyword");
      Assert (Listprobe2_Main.List_Style_Type.Kind = List_Style_Custom_String
              and then To_String (Listprobe2_Main.List_Style_Type.Marker) = "-> ",
              "list-style shorthand should parse quoted custom marker text");
      Assert (Listprobe3_Main.List_Style_Type.Kind = List_Style_Disc
              and then Listprobe3_Main.List_Style_Image.Kind = List_Image_None
              and then Listprobe3_Main.List_Style_Position = List_Inside,
              "list-style longhands should parse and resolve");
      Assert (Listprobe4_Main.List_Style_Type.Kind = List_Style_None
              and then Listprobe4_Main.List_Style_Image.Kind = List_Image_None,
              "list-style none shorthand should disable both type and image");
      Assert (Is_Named_Color (SvgNamed_Main.Color, Cornflower_Blue),
              "SVG named colors should parse to Named_Color enum values");
      Assert (Is_Named_Color (SvgNamed_Main.Background_Color, Light_Goldenrod_Yellow),
              "SVG named colors should parse for background-color");
      Assert (SvgNamed_Main.Border_Color.Kind = Gap_Uniform
              and then Is_Named_Color (SvgNamed_Main.Border_Color.All_Edges, Dark_Slate_Gray),
              "SVG named colors should parse for border-color");
      Assert (Is_Named_Color (SvgAlias_Main.Color, Gray),
              "grey alias should map to Gray enum");
      Assert (Is_Named_Color (SvgAqua_Main.Color, Aqua),
              "aqua keyword should parse");
      Assert (Is_Named_Color (SvgCyan_Main.Color, Cyan),
              "cyan keyword should parse");
      Assert (Missing_Main.Background_Color.Kind = Named
              and then Missing_Main.Background_Color.Name = Transparent,
              "Unknown class should return default/empty styles");

   end;

   declare
      Outline_Long_Styles  : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-long");
      Outline_Short_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-short");
      Outline_Offset_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-offset");
      Outline_None_Styles  : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "outline-none");
      Sizing_Styles      : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "sizing");
      Textprops_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "textprops");
      Misc_Styles        : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "misc");
      Misc2_Styles       : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "misc2");
      OverflowY_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowy");
      OverflowX_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowx");
      OverflowMix_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowmix");
      OverflowMix2_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "overflowmix2");
      Flexextra_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "flexextra");
      Gridcon_Styles     : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "gridcontainer");
      Gridmixed_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "gridmixed");
      Griditem_Styles    : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "griditem");
      Shadow_Styles      : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "shadowtest");
      Pad1_Styles        : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "pad1");
      Margin3_Styles     : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "margin3");
      Dispvals_Styles    : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "displayvals");
      Linepx_Styles      : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "linepx");
      Linenormal_Styles  : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "linenormal");
      Widthauto_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "widthauto");
      Basisauto_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "basisauto");
      Basiscont_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "basiscontent");
      Pressed_Styles     : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "pressed-pseudo");

      Outline_Long_Main  : constant Resolved_Style := Compute_Resolved (Outline_Long_Styles (Main_Part).Style, No_States, No_States);
      Outline_Short_Main : constant Resolved_Style := Compute_Resolved (Outline_Short_Styles (Main_Part).Style, No_States, No_States);
      Outline_Offset_Main : constant Resolved_Style := Compute_Resolved (Outline_Offset_Styles (Main_Part).Style, No_States, No_States);
      Outline_None_Main  : constant Resolved_Style := Compute_Resolved (Outline_None_Styles (Main_Part).Style, No_States, No_States);
      Sizing_Main      : constant Resolved_Style := Compute_Resolved (Sizing_Styles (Main_Part).Style, No_States, No_States);
      Textprops_Main   : constant Resolved_Style := Compute_Resolved (Textprops_Styles (Main_Part).Style, No_States, No_States);
      Misc_Main        : constant Resolved_Style := Compute_Resolved (Misc_Styles (Main_Part).Style, No_States, No_States);
      Misc2_Main       : constant Resolved_Style := Compute_Resolved (Misc2_Styles (Main_Part).Style, No_States, No_States);
      OverflowY_Main   : constant Resolved_Style := Compute_Resolved (OverflowY_Styles (Main_Part).Style, No_States, No_States);
      OverflowX_Main   : constant Resolved_Style := Compute_Resolved (OverflowX_Styles (Main_Part).Style, No_States, No_States);
      OverflowMix_Main : constant Resolved_Style := Compute_Resolved (OverflowMix_Styles (Main_Part).Style, No_States, No_States);
      OverflowMix2_Main : constant Resolved_Style := Compute_Resolved (OverflowMix2_Styles (Main_Part).Style, No_States, No_States);
      Flexextra_Main   : constant Resolved_Style := Compute_Resolved (Flexextra_Styles (Main_Part).Style, No_States, No_States);
      Gridcon_Main     : constant Resolved_Style := Compute_Resolved (Gridcon_Styles (Main_Part).Style, No_States, No_States);
      Gridmixed_Main   : constant Resolved_Style := Compute_Resolved (Gridmixed_Styles (Main_Part).Style, No_States, No_States);
      Griditem_Main    : constant Resolved_Style := Compute_Resolved (Griditem_Styles (Main_Part).Style, No_States, No_States);
      Shadow_Main      : constant Resolved_Style := Compute_Resolved (Shadow_Styles (Main_Part).Style, No_States, No_States);
      Pad1_Main        : constant Resolved_Style := Compute_Resolved (Pad1_Styles (Main_Part).Style, No_States, No_States);
      Margin3_Main     : constant Resolved_Style := Compute_Resolved (Margin3_Styles (Main_Part).Style, No_States, No_States);
      Dispvals_Main    : constant Resolved_Style := Compute_Resolved (Dispvals_Styles (Main_Part).Style, No_States, No_States);
      Linepx_Main      : constant Resolved_Style := Compute_Resolved (Linepx_Styles (Main_Part).Style, No_States, No_States);
      Linenormal_Main  : constant Resolved_Style := Compute_Resolved (Linenormal_Styles (Main_Part).Style, No_States, No_States);
      Widthauto_Main   : constant Resolved_Style := Compute_Resolved (Widthauto_Styles (Main_Part).Style, No_States, No_States);
      Basisauto_Main   : constant Resolved_Style := Compute_Resolved (Basisauto_Styles (Main_Part).Style, No_States, No_States);
      Basiscont_Main   : constant Resolved_Style := Compute_Resolved (Basiscont_Styles (Main_Part).Style, No_States, No_States);
      Pressed_Normal   : constant Resolved_Style := Compute_Resolved (Pressed_Styles (Main_Part).Style, No_States, No_States);
      Pressed_Active   : constant Resolved_Style := Compute_Resolved (
         Pressed_Styles (Main_Part).Style,
         [No_States with delta State_Pressed => True],
         No_States);
   begin

      --  Outline longhand tests
      Assert (Outline_Long_Main.Outline_Width.Amount = 3.0
              and then Outline_Long_Main.Outline_Width.Unit = Px,
              "outline-width longhand should parse");
      Assert (Outline_Long_Main.Outline_Style = Outline_Solid,
              "outline-style longhand should parse");
      Assert (Is_RGB_Color (Outline_Long_Main.Outline_Color, 100, 200, 50),
              "outline-color longhand should parse");
      Assert (Outline_Long_Main.Outline_Offset.Amount = 4.0
              and then Outline_Long_Main.Outline_Offset.Unit = Px,
              "outline-offset longhand should parse");

      --  Outline shorthand tests
      Assert (Outline_Short_Main.Outline_Width.Amount = 2.0
              and then Outline_Short_Main.Outline_Width.Unit = Px,
              "outline shorthand should parse width");
      Assert (Outline_Short_Main.Outline_Style = Outline_Solid,
              "outline shorthand should parse style");
      Assert (Is_RGB_Color (Outline_Short_Main.Outline_Color, 208, 188, 255),
              "outline shorthand should parse rgb color");

      --  Outline shorthand + longhand override
      Assert (Outline_Offset_Main.Outline_Width.Amount = 1.0,
              "outline shorthand width should parse for dashed test");
      Assert (Outline_Offset_Main.Outline_Style = Outline_Dashed,
              "outline shorthand should parse dashed style");
      Assert (Is_Named_Color (Outline_Offset_Main.Outline_Color, Red),
              "outline shorthand should parse named color");
      Assert (Outline_Offset_Main.Outline_Offset.Amount = 5.0,
              "outline-offset longhand should override after shorthand");

      --  Outline none
      Assert (Outline_None_Main.Outline_Style = Outline_None,
              "outline none shorthand should set style to none");

      --  Sizing properties
      Assert (Sizing_Main.Height.Kind = Fixed and then Sizing_Main.Height.Size.Amount = 200.0,
              "height should parse");
      Assert (Sizing_Main.Min_Width.Kind = Fixed and then Sizing_Main.Min_Width.Size.Amount = 50.0,
              "min-width should parse");
      Assert (Sizing_Main.Max_Width.Kind = Fixed and then Sizing_Main.Max_Width.Size.Amount = 400.0,
              "max-width should parse");
      Assert (Sizing_Main.Max_Height.Kind = Fixed and then Sizing_Main.Max_Height.Size.Amount = 300.0,
              "max-height should parse");

      --  Text properties
      Assert (Textprops_Main.Text_Decoration = Decoration_Underline,
              "text-decoration underline should parse");
      Assert (Textprops_Main.White_Space = WS_Pre_Wrap,
              "white-space pre-wrap should parse");
      Assert (Textprops_Main.Text_Overflow = Overflow_Ellipsis,
              "text-overflow ellipsis should parse");
      Assert (Textprops_Main.Line_Height.Kind = LH_Number
              and then Nearly_Equal (Textprops_Main.Line_Height.Multiplier, 1.5),
              "line-height unitless multiplier should parse");
      Assert (Textprops_Main.Vertical_Align = VA_Middle,
              "vertical-align middle should parse");

      --  Misc properties
      Assert (Misc_Main.Visibility = Visibility_Hidden,
              "visibility hidden should parse");
      Assert (Misc_Main.Object_Fit = Fit_Cover,
              "object-fit cover should parse");
      Assert (Misc_Main.Object_Position.Kind = Keyword_Pos
              and then Misc_Main.Object_Position.H_Keyword = Pos_Center
              and then Misc_Main.Object_Position.V_Keyword = Pos_Center,
              "object-position center center should parse");
      Assert (Misc2_Main.Object_Position.Kind = Length_Pos
              and then Misc2_Main.Object_Position.X_Offset.Amount = 10.0
              and then Misc2_Main.Object_Position.Y_Offset.Amount = 20.0,
              "object-position length pair should parse");
      Assert (OverflowY_Main.Overflow_Y = Overflow_Auto
              and then OverflowY_Main.Overflow_X = Overflow_Visible,
              "overflow-y auto should apply vertical overflow only");
      Assert (OverflowX_Main.Overflow_X = Overflow_Hidden
              and then OverflowX_Main.Overflow_Y = Overflow_Visible,
              "overflow-x hidden should apply horizontal overflow only");
      Assert (OverflowMix_Main.Overflow_X = Overflow_Hidden
              and then OverflowMix_Main.Overflow_Y = Overflow_Auto,
              "overflow shorthand + overflow-y should resolve with longhand override");
      Assert (OverflowMix2_Main.Overflow_X = Overflow_Hidden
              and then OverflowMix2_Main.Overflow_Y = Overflow_Hidden,
              "overflow-y + overflow shorthand should resolve with shorthand override");

      --  Flex extra
      Assert (Flexextra_Main.Flex_Wrap = Wrap,
              "flex-wrap wrap should parse");
      Assert (Flexextra_Main.Align_Self = Stretch,
              "align-self stretch should parse");
      Assert (Flexextra_Main.Align_Content = Space_Between,
              "align-content space-between should parse");

      --  Grid container
      Assert (Gridcon_Main.Display = Grid,
              "display grid should parse");
      Assert (Gridcon_Main.Grid_Columns = 3,
              "grid-template-columns repeat(3) should parse to 3");
      Assert (Gridcon_Main.Grid_Column_Tracks.Count = 3,
              "grid-template-columns repeat(3,1fr) track count should be 3");
      Assert (Gridcon_Main.Grid_Column_Tracks.Tracks (1).Kind = Track_Fr,
              "grid-template-columns repeat(3,1fr) track 1 kind should be Track_Fr");
      Assert (abs (Gridcon_Main.Grid_Column_Tracks.Tracks (1).Value - 1.0) < 0.001,
              "grid-template-columns repeat(3,1fr) track 1 value should be 1.0");
      Assert (Gridcon_Main.Grid_Column_Tracks.Tracks (3).Kind = Track_Fr,
              "grid-template-columns repeat(3,1fr) track 3 kind should be Track_Fr");
      Assert (Gridcon_Main.Grid_Rows = 2,
              "grid-template-rows should parse track count");
      Assert (Gridcon_Main.Gap.Kind = Gap_Uniform
              and then Gridcon_Main.Gap.All_Gap.Amount = 10.0,
              "gap 1-value should parse to uniform gap");

      --  Grid mixed tracks (auto auto 1fr)
      Assert (Gridmixed_Main.Grid_Column_Tracks.Count = 3,
              "grid-template-columns auto auto 1fr track count should be 3");
      Assert (Gridmixed_Main.Grid_Column_Tracks.Tracks (1).Kind = Track_Auto,
              "grid-template-columns auto auto 1fr track 1 should be Track_Auto");
      Assert (Gridmixed_Main.Grid_Column_Tracks.Tracks (2).Kind = Track_Auto,
              "grid-template-columns auto auto 1fr track 2 should be Track_Auto");
      Assert (Gridmixed_Main.Grid_Column_Tracks.Tracks (3).Kind = Track_Fr,
              "grid-template-columns auto auto 1fr track 3 should be Track_Fr");
      Assert (abs (Gridmixed_Main.Grid_Column_Tracks.Tracks (3).Value - 1.0) < 0.001,
              "grid-template-columns auto auto 1fr track 3 fr value should be 1.0");

      --  Grid item
      Assert (Griditem_Main.Grid_Column = 1,
              "grid-column start should parse");
      Assert (Griditem_Main.Grid_Column_Span = 2,
              "grid-column span should parse from start/end shorthand");
      Assert (Griditem_Main.Grid_Row_Span = 2,
              "grid-row span should parse");

      --  Box shadow none
      Assert (Shadow_Main.Box_Shadow.Blur_Radius.Amount = 0.0
              and then Shadow_Main.Box_Shadow.Offset_X.Amount = 0.0,
              "box-shadow none should resolve to zero shadow");

      --  Padding 1-value uniform
      Assert (Pad1_Main.Padding.Kind = Gap_Uniform
              and then Pad1_Main.Padding.All_Sides.Amount = 5.0,
              "padding 1-value should parse as uniform");

      --  Margin 3-value
      Assert (Margin3_Main.Margin.Kind = Per_Side
              and then Margin3_Main.Margin.Sides (Top).Amount = 1.0
              and then Margin3_Main.Margin.Sides (Right).Amount = 2.0
              and then Margin3_Main.Margin.Sides (Bottom).Amount = 3.0
              and then Margin3_Main.Margin.Sides (Left).Amount = 2.0,
              "margin 3-value shorthand should parse (left = right)");

      --  Display inline-flex
      Assert (Dispvals_Main.Display = Inline_Flex,
              "display inline-flex should parse");

      --  Line height variants
      Assert (Linepx_Main.Line_Height.Kind = LH_Length
              and then Linepx_Main.Line_Height.Height.Amount = 20.0,
              "line-height with px unit should parse");
      Assert (Linenormal_Main.Line_Height.Kind = LH_Normal,
              "line-height normal should parse");

      --  Width auto
      Assert (Widthauto_Main.Width.Kind = Auto,
              "width auto should parse");

      --  Flex basis auto/content
      Assert (Basisauto_Main.Flex_Basis.Kind = Auto,
              "flex-basis auto should parse");
      Assert (Basiscont_Main.Flex_Basis.Kind = Content,
              "flex-basis content should parse");

      --  :active pseudo = pressed state
      Assert (Is_RGB_Color (Pressed_Normal.Background_Color, 11, 22, 33),
              ":active pseudo base should parse");
      Assert (Is_RGB_Color (Pressed_Active.Background_Color, 44, 55, 66),
              ":active pseudo should map to pressed state");
   end;

   declare
      Reload_Sheet : Adi.CSS_Parser.Stylesheet;
      Reloaded : Boolean := False;
      Reload_OK : Boolean := False;
      Css_Path : constant String := "/tmp/adi_css_parser_test.css";
      Box : Adi.Widget.Box.Box_Widget_Access;
      V1 : constant String :=
        ".reloadable { background-color: rgb(10, 20, 30); }" & ASCII.LF;
      V2 : constant String :=
        ".reloadable { background-color: rgb(40, 50, 60); border-width: 3px; }" & ASCII.LF;
   begin
      Write_Text_File (Css_Path, V1);
      Adi.CSS_Parser.Load_File (Reload_Sheet, Css_Path, Reload_OK);
      Assert (Reload_OK, "Load_File should succeed for valid CSS file");
      Assert (Adi.CSS_Parser.Get_Source_Path (Reload_Sheet) = Css_Path,
              "Get_Source_Path should track file path");

      Box := Adi.Widget.Box.Create;
      Adi.CSS_Parser.Bind_Class (Reload_Sheet, "reloadable", Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (Box.all, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 10, 20, 30),
                 "Bind_Class should apply current stylesheet styles");
      end;

      delay 1.1;
      Write_Text_File (Css_Path, V2);
      Adi.CSS_Parser.Reload_If_Changed (Reload_Sheet, Reloaded, Reload_OK);
      Assert (Reload_OK, "Reload_If_Changed should succeed");
      Assert (Reloaded, "Reload_If_Changed should detect modified file");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (Box.all, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 40, 50, 60),
                 "Reload should reapply new background color to bound widget");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 3.0,
                 "Reload should reapply new border width to bound widget");
      end;

      Adi.CSS_Parser.Reload_If_Changed (Reload_Sheet, Reloaded, Reload_OK);
      Assert (Reload_OK and then not Reloaded,
              "Reload_If_Changed should report no reload when file unchanged");
   end;

   declare
      Bad_Sheet : Adi.CSS_Parser.Stylesheet;
      Bad_OK : Boolean := False;
      Dummy_Reloaded : Boolean := False;
      Dummy_Success : Boolean := False;
   begin
      Adi.CSS_Parser.Load_String (Bad_Sheet, ".oops { color: red; ", Bad_OK);
      Assert (not Bad_OK, "Load_String should fail on unclosed CSS block");
      Assert (Adi.CSS_Parser.Get_Last_Error (Bad_Sheet) /= "",
              "Parser error text should be populated after malformed CSS");

      Adi.CSS_Parser.Load_String
        (Bad_Sheet,
         ".ok { color: rgb(1,2,3); transition: background-color nope ease; } .ok::unknown-part { color: red; } .ok { nonsense-prop: 5; }",
         Bad_OK);
      Assert (Bad_OK,
              "Load_String should tolerate unknown part selectors/properties when valid rules exist");
      Assert (Adi.CSS_Parser.Get_Last_Error (Bad_Sheet) = "",
              "Last error should be cleared after a successful parse");
      Assert (Adi.CSS_Parser.Has_Class (Bad_Sheet, "ok"),
              "Valid selector should still be available after mixed-validity CSS");

      declare
         OK_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Bad_Sheet, "ok");
         OK_Main : constant Resolved_Style := Compute_Resolved (OK_Styles (Main_Part).Style, No_States, No_States);
      begin
         Assert (Is_RGB_Color (OK_Main.Color, 1, 2, 3),
                 "Valid declaration should apply even when other declarations are unsupported");
         Assert (Nearly_Equal (OK_Main.Transition.Duration, 0.0),
                 "Invalid transition value should be ignored without affecting valid declarations");
      end;

      Adi.CSS_Parser.Load_File (Bad_Sheet, "/tmp/this_file_should_not_exist_adi_css.css", Bad_OK);
      Assert (not Bad_OK, "Load_File should fail for missing CSS file");
      Assert (Adi.CSS_Parser.Get_Last_Error (Bad_Sheet) /= "",
              "Load_File missing-path failure should provide error text");

      Adi.CSS_Parser.Reload_If_Changed (Bad_Sheet, Dummy_Reloaded, Dummy_Success);
      Assert (Dummy_Success and then not Dummy_Reloaded,
              "Reload_If_Changed should no-op when no source file was successfully loaded");
   end;

   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "css parser test failed";
   end if;
end Css_Parser_Test;
