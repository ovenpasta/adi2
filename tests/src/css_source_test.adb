pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.SDL; use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support; use Test_Support;

procedure Css_Source_Test is

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
   Start_Suite ("CSS source test");

   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
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
        W          => +Box,
        Tag_Name   => "button",
        Class_Name => "primary",
        Id_Name    => "submit");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
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
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;
      Css    : constant String :=
        ":root { color: red; font-size: 20dp; --accent: blue; }" & ASCII.LF &
        ".x { background-color: var(--accent); }" & ASCII.LF;
   begin
      Adi.CSS_Source.Add_Dynamic_String (Source, Css, OK);
      Assert (OK, "Add_Dynamic_String with :root metadata should succeed");

      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Set_Mode dynamic should succeed with :root metadata");

      Assert (Adi.CSS_Source.Has_Custom_Property (Source, "--accent"),
              "CSS_Source should expose resolved custom properties");
      Assert (Adi.CSS_Source.Get_Custom_Property (Source, "--accent") = "blue",
              "CSS_Source custom property lookup should return resolved value");
      Assert (Adi.CSS_Source.Get_Metadata (Source).Has_Root_Font_Size,
              "CSS_Source metadata should expose :root font-size");

      Adi.CSS_Source.Bind_Root_Metadata (Source, +Box);
      Adi.CSS_Source.Bind_Class (Source, "x", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (R.Color = (Kind => Named, Name => Red),
                 "Bind_Root_Metadata should preserve :root styles on root widget");
         Assert (R.Background_Color = (Kind => Named, Name => Blue),
                 "Root widget should also receive normal bound selector styles");
      end;
   end;

   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
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

      Adi.CSS_Source.Bind_Tag (Source, "li", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
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
      Box    : constant Box_Handle := Create_Handle;
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
        W          => +Box,
        Tag_Name   => "button",
        Class_Name => "primary",
        Id_Name    => "submit");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
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
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 200, 210, 220),
                 "Reloaded dynamic selector-set should keep id priority");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 9.0,
                 "Reloaded dynamic selector-set should update class-only properties");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 5.0,
                 "Reloaded dynamic selector-set should update id-only properties");
      end;
   end;

   --  ── Bind_Class tests (multi-class) ──────────────────────────────────

   --  Static mode: Bind_Class merges two class entries
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;

      Static_Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        Adi.CSS_Source.Class_Entry (
          "base",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (10, 20, 30)),
            Padding          => Set (CSS_Box (Px (4.0))),
            others           => <>))),
        Adi.CSS_Source.Class_Entry (
          "accent",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (100, 110, 120)),
            Border_Width     => Set (Border_Width (Px (2.0))),
            others           => <>)))
      ];
   begin
      Adi.CSS_Source.Set_Static_Entries (Source, Static_Entries);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "Bind_Class static Set_Mode should succeed");

      Adi.CSS_Source.Bind_Class (Source, "base accent", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 100, 110, 120),
                 "Bind_Class static should use later class override for bg");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 4.0,
                 "Bind_Class static should keep first class padding");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 2.0,
                 "Bind_Class static should keep second class border-width");
      end;
   end;

   --  Static mode: Bind_Class with single class works same as Bind_Class
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;

      Static_Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        1 => Adi.CSS_Source.Class_Entry (
          "solo",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (55, 66, 77)),
            others           => <>)))
      ];
   begin
      Adi.CSS_Source.Set_Static_Entries (Source, Static_Entries);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);

      Adi.CSS_Source.Bind_Class (Source, "solo", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 55, 66, 77),
                 "Bind_Class static single class should apply bg");
      end;
   end;

   --  Static mode: Bind_Class with three classes merges in order
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;

      Static_Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        Adi.CSS_Source.Class_Entry (
          "layer1",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (10, 10, 10)),
            Padding          => Set (CSS_Box (Px (2.0))),
            Opacity          => Set (0.1),
            others           => <>))),
        Adi.CSS_Source.Class_Entry (
          "layer2",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (20, 20, 20)),
            Border_Width     => Set (Border_Width (Px (1.0))),
            others           => <>))),
        Adi.CSS_Source.Class_Entry (
          "layer3",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (30, 30, 30)),
            others           => <>)))
      ];
   begin
      Adi.CSS_Source.Set_Static_Entries (Source, Static_Entries);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);

      Adi.CSS_Source.Bind_Class (Source, "layer1 layer2 layer3", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 30, 30, 30),
                 "Bind_Class three classes should use last override for bg");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 2.0,
                 "Bind_Class three classes should keep first-only padding");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 1.0,
                 "Bind_Class three classes should keep middle border-width");
         Assert (Float (R.Opacity) = 0.1,
                 "Bind_Class three classes should keep first-only opacity");
      end;
   end;

   --  Dynamic mode: Bind_Class merges from parsed CSS
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;

      Css : constant String :=
        ".base { background-color: rgb(10, 20, 30); padding: 5px; }" & ASCII.LF &
        ".accent { background-color: rgb(100, 110, 120); border-width: 3px; }" & ASCII.LF;
   begin
      Adi.CSS_Source.Add_Dynamic_String (Source, Css, OK);
      Assert (OK, "Bind_Class dynamic Add_Dynamic_String should succeed");

      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Bind_Class dynamic Set_Mode should succeed");

      Adi.CSS_Source.Bind_Class (Source, "base accent", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 100, 110, 120),
                 "Bind_Class dynamic should use later class override for bg");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 5.0,
                 "Bind_Class dynamic should keep first class padding");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 3.0,
                 "Bind_Class dynamic should keep second class border-width");
      end;
   end;

   --  Dynamic mode: Bind_Class reapplied after reload
   declare
      Source   : Adi.CSS_Source.Style_Source;
      Box      : constant Box_Handle := Create_Handle;
      OK       : Boolean := False;
      Reloaded : Boolean := False;
      Tick_OK  : Boolean := False;
      Css_Path : constant String := "/tmp/adi_css_multiclass_test.css";
      Css_V1   : constant String :=
        ".base { background-color: rgb(10, 20, 30); padding: 4px; }" & ASCII.LF &
        ".accent { background-color: rgb(100, 110, 120); border-width: 2px; }" & ASCII.LF;
      Css_V2   : constant String :=
        ".base { background-color: rgb(50, 60, 70); padding: 8px; }" & ASCII.LF &
        ".accent { background-color: rgb(200, 210, 220); border-width: 5px; }" & ASCII.LF;
   begin
      Write_Text_File (Css_Path, Css_V1);
      Adi.CSS_Source.Add_Dynamic_File (Source, Css_Path, OK);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);

      Adi.CSS_Source.Bind_Class (Source, "base accent", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 100, 110, 120),
                 "Bind_Class reload initial bg should be accent");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 4.0,
                 "Bind_Class reload initial padding should be base");
      end;

      delay 1.1;
      Write_Text_File (Css_Path, Css_V2);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Bind_Class reload Tick should succeed");
      Assert (Reloaded, "Bind_Class reload Tick should detect change");

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 200, 210, 220),
                 "Bind_Class reload should update bg to new accent");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 8.0,
                 "Bind_Class reload should update padding to new base");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 5.0,
                 "Bind_Class reload should update border-width to new accent");
      end;
   end;

   --  Add_Static_Entry: incremental registration avoids stack-blowing aggregates
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;
   begin
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source,
        Adi.CSS_Source.Class_Entry ("alpha",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (11, 22, 33)),
            Padding          => Set (CSS_Box (Px (5.0))),
            others           => <>))));
      Adi.CSS_Source.Add_Static_Entry (Source,
        Adi.CSS_Source.Class_Entry ("beta",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (44, 55, 66)),
            Border_Width     => Set (Border_Width (Px (4.0))),
            others           => <>))));
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "Add_Static_Entry Set_Mode static should succeed");

      Adi.CSS_Source.Bind_Class (Source, "alpha beta", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 44, 55, 66),
                 "Add_Static_Entry should apply later class bg override");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 5.0,
                 "Add_Static_Entry should keep first class padding");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 4.0,
                 "Add_Static_Entry should keep second class border-width");
      end;
   end;

   --  Clear_Static_Entries should remove previously added entries
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;
   begin
      Adi.CSS_Source.Add_Static_Entry (Source,
        Adi.CSS_Source.Class_Entry ("old",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (99, 99, 99)),
            others           => <>))));
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source,
        Adi.CSS_Source.Class_Entry ("fresh",
          Main_Styles ((
            Background_Color => Set_Bg (RGB (77, 88, 99)),
            others           => <>))));
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "Clear + Add_Static_Entry Set_Mode should succeed");

      Adi.CSS_Source.Bind_Class (Source, "fresh", +Box);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 77, 88, 99),
                 "Clear_Static_Entries should discard old entries");
      end;
   end;

   --  Merge_Part_Styles public function
   declare
      Box : constant Box_Handle := Create_Handle;
      A : constant Part_Style_Array := Main_Styles ((
        Background_Color => Set_Bg (RGB (1, 2, 3)),
        Padding          => Set (CSS_Box (Px (10.0))),
        others           => <>));
      B : constant Part_Style_Array := Main_Styles ((
        Background_Color => Set_Bg (RGB (4, 5, 6)),
        Border_Width     => Set (Border_Width (Px (7.0))),
        others           => <>));
      M : constant Part_Style_Array := Adi.CSS_Source.Merge_Part_Styles (A, B);
   begin
      Set_Part_Styles (Box, M);
      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 4, 5, 6),
                 "Merge_Part_Styles should use override bg");
         Assert (R.Padding.Kind = Gap_Uniform and then R.Padding.All_Sides.Amount = 10.0,
                 "Merge_Part_Styles should keep base padding");
         Assert (R.Border_Width.Kind = Gap_Uniform and then R.Border_Width.All_Edges.Amount = 7.0,
                 "Merge_Part_Styles should keep override border-width");
      end;
   end;

   --  Dynamic mode: font-size live reload updates intrinsic preferred width.
   declare
      Source    : Adi.CSS_Source.Style_Source;
      Lbl       : constant Label_Handle :=
        Create_Handle ("Live reload width probe");
      Sdl_OK    : Adi.SDL.C_bool;
      Ttf_OK    : Adi.SDL.C_bool;
      OK        : Boolean := False;
      Reloaded  : Boolean := False;
      Tick_OK   : Boolean := False;
      Width_V1  : Pixel_Type := 0.0;
      Width_V2  : Pixel_Type := 0.0;
      Css_Path  : constant String := "/tmp/adi_css_source_font_reload.css";
      Css_V1    : constant String :=
        ".probe { font-size: 12px; }" & ASCII.LF;
      Css_V2    : constant String :=
        ".probe { font-size: 28px; }" & ASCII.LF;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Sdl_OK := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Assert (Boolean (Sdl_OK), "SDL_Init should succeed for font-size reload test");
      Ttf_OK := Adi.SDL.TTF.TTF_Init;
      Assert (Boolean (Ttf_OK), "TTF_Init should succeed for font-size reload test");

      Write_Text_File (Css_Path, Css_V1);
      Adi.CSS_Source.Add_Dynamic_File (Source, Css_Path, OK);
      Assert (OK, "Add_Dynamic_File should succeed for font-size reload test");

      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Set_Mode dynamic should succeed for font-size reload test");

      Adi.CSS_Source.Bind_Class (Source, "probe", +Lbl);
      Width_V1 := Get_Preferred_Size (+Lbl).Width;
      Assert (Width_V1 > 0.0, "Baseline preferred width should be > 0");

      delay 1.1;
      Write_Text_File (Css_Path, Css_V2);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Tick should succeed after font-size css update");
      Assert (Reloaded, "Tick should report reload for font-size css update");

      Width_V2 := Get_Preferred_Size (+Lbl).Width;
      Assert (Width_V2 > Width_V1,
              "Preferred width should increase after larger font-size reload");
   end;

   Finish;
end Css_Source_Test;
