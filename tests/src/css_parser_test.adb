pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
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
     ".sides { padding: 1px 2px 3px 4px; padding-left: 11px; margin: 5px; margin-top: 9px; }" & ASCII.LF;

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
   Assert (not Adi.CSS_Parser.Has_Class (Sheet, "missing"), "Has_Class should be false for unknown class");
   Assert (not Adi.CSS_Parser.Has_Id (Sheet, "card"), "Has_Id should not match class selector");

   declare
      Styles         : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "card");
      Panel_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "panel");
      Submit_Styles  : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Id (Sheet, "submit");
      Tag_Styles     : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Tag (Sheet, "button");
      Seconds_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "seconds");
      Sides_Styles   : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Class (Sheet, "sides");
      Missing_Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For (Sheet, "missing");

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
      Missing_Main : constant Resolved_Style := Compute_Resolved (Missing_Styles (Main_Part).Style, No_States, No_States);
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
      Assert (Main_Normal.Overflow = Overflow_Hidden,
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
      Assert (Missing_Main.Background_Color.Kind = Named
              and then Missing_Main.Background_Color.Name = Transparent,
              "Unknown class should return default/empty styles");
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
