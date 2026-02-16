pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;

procedure Css_Source_Test is

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

   function Is_RGB_Color (Col : Color_Value; R, G, B : Natural) return Boolean is
   begin
      return Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B;
   end Is_RGB_Color;

   procedure Write_Text_File (Path : String; Content : String) is
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   end Write_Text_File;

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True), others => <>]);

begin
   Put_Line ("CSS source test");

   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      OK     : Boolean := False;

      Static_Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        Adi.CSS_Source.Tag_Entry (
          "button",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (40, 50, 60)),
            Opacity          => Set (0.2),
            others           => <>))),
        Adi.CSS_Source.Class_Entry (
          "primary",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (90, 100, 110)),
            Padding          => Set (CSS_Box (Px (6.0))),
            others           => <>))),
        Adi.CSS_Source.Id_Entry (
          "submit",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (140, 150, 160)),
            Border_Width     => Set (Border_Width (Px (3.0))),
            others           => <>)))
      ];
   begin
      Adi.CSS_Source.Set_Static_Entries (Source, Static_Entries);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "Set_Mode static should succeed");

      Adi.CSS_Source.Bind_Selector_Set (
        Source     => Source,
        W          => Box,
        Tag_Name   => "button",
        Class_Name => "primary",
        Id_Name    => "submit");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (Box.all, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 140, 150, 160),
                 "Static selector-set should prioritize id over class/tag");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 6.0,
                 "Static selector-set should keep class-only properties");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 3.0,
                 "Static selector-set should keep id-only properties");
         Assert (Float (R.Opacity) = 0.2,
                 "Static selector-set should keep tag-only properties");
      end;
   end;

   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      OK     : Boolean := False;

      Static_Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        Adi.CSS_Source.Tag_Entry (
          "li",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (10, 20, 30)),
            Padding          => Set (CSS_Box (Px (2.0))),
            others           => <>))),
        Adi.CSS_Source.Tag_Entry (
          "li",
          Main_Styles ((
            Padding      => Set (CSS_Box (Px (6.0))),
            Border_Width => Set (Border_Width (Px (1.0))),
            others       => <>))),
        Adi.CSS_Source.Tag_Entry (
          "li",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (70, 80, 90)),
            others           => <>)))
      ];
   begin
      Adi.CSS_Source.Set_Static_Entries (Source, Static_Entries);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "Set_Mode static should succeed with repeated selector entries");

      Adi.CSS_Source.Bind_Tag (Source, "li", Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (Box.all, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 70, 80, 90),
                 "Static mode should merge repeated tag entries and keep last override");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 6.0,
                 "Static mode should merge repeated tag entries and keep middle properties");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 1.0,
                 "Static mode should preserve properties introduced by any repeated entry");
      end;
   end;

   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      OK     : Boolean := False;
      Reloaded : Boolean := False;
      Tick_OK  : Boolean := False;
      Css_Path : constant String := "/tmp/adi_css_source_test.css";
      Css_V1   : constant String :=
        "button { background-color: rgb(40, 50, 60); opacity: 0.25; }" & ASCII.LF &
        ".primary { background-color: rgb(90, 100, 110); padding: 6px; }" & ASCII.LF &
        "#submit { background-color: rgb(140, 150, 160); border-width: 3px; }" & ASCII.LF;
      Css_V2   : constant String :=
        "button { background-color: rgb(10, 20, 30); opacity: 0.33; }" & ASCII.LF &
        ".primary { background-color: rgb(70, 80, 90); padding: 9px; }" & ASCII.LF &
        "#submit { background-color: rgb(200, 210, 220); border-width: 5px; }" & ASCII.LF;
   begin
      Write_Text_File (Css_Path, Css_V1);
      Adi.CSS_Source.Add_Dynamic_File (Source, Css_Path, OK);
      Assert (OK, "Add_Dynamic_File should succeed");

      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Set_Mode dynamic should succeed");

      Adi.CSS_Source.Bind_Selector_Set (
        Source     => Source,
        W          => Box,
        Tag_Name   => "button",
        Class_Name => "primary",
        Id_Name    => "submit");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (Box.all, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 140, 150, 160),
                 "Dynamic selector-set should prioritize id over class/tag");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 6.0,
                 "Dynamic selector-set should keep class-only properties");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 3.0,
                 "Dynamic selector-set should keep id-only properties");
      end;

      delay 1.1;
      Write_Text_File (Css_Path, Css_V2);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Tick should succeed after css file update");
      Assert (Reloaded, "Tick should report reload when css file changed");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (Box.all, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 200, 210, 220),
                 "Reloaded dynamic selector-set should keep id priority");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 9.0,
                 "Reloaded dynamic selector-set should update class-only properties");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 5.0,
                 "Reloaded dynamic selector-set should update id-only properties");
      end;
   end;

   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "css source test failed";
   end if;
end Css_Source_Test;
