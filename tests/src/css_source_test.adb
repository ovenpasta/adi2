pragma Ada_2022;

with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
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

   --  A selector set carries the widget's whole `class` attribute, which
   --  may name several classes, so it splits the list the way Bind_Class
   --  does and merges them left to right between the tag and the id.
   declare
      Source : Adi.CSS_Source.Style_Source;
      Box    : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;
      Css    : constant String :=
        "button { background-color: rgb(10, 20, 30); opacity: 0.25; }"
        & ASCII.LF &
        ".base { background-color: rgb(40, 50, 60); padding: 6px; }"
        & ASCII.LF &
        ".accent { background-color: rgb(90, 100, 110); "
        & "border-width: 3px; }" & ASCII.LF &
        "#submit { margin: 4px; }" & ASCII.LF;
   begin
      Adi.CSS_Source.Add_Dynamic_String (Source, Css, OK);
      Assert (OK, "Multi-class selector set should load its CSS");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Multi-class selector set should enter dynamic mode");

      Adi.CSS_Source.Bind_Selector_Set (
        Source     => Source,
        W          => +Box,
        Tag_Name   => "button",
        Class_Name => "base accent",
        Id_Name    => "submit");

      declare
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Box, Main_Part);
      begin
         Assert (Is_RGB_Color (R.Background_Color, 90, 100, 110),
                 "Selector set should let the later class win over the "
                 & "earlier one and over the tag");
         Assert (R.Padding.Kind = Gap_Uniform
                   and then R.Padding.All_Sides.Amount = 6.0,
                 "Selector set should keep properties only the first "
                 & "class sets");
         Assert (R.Border_Width.Kind = Gap_Uniform
                   and then R.Border_Width.All_Edges.Amount = 3.0,
                 "Selector set should keep properties only the second "
                 & "class sets");
         Assert (Float (R.Opacity) = 0.25,
                 "Selector set should keep tag properties no class "
                 & "overrides");
         Assert ((for all E in Edge => R.Margin (E).Length.Amount = 4.0),
                 "Selector set should still apply the id after a class "
                 & "list");
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

   Section ("A configuration cascades in the order it was given");

   declare
      use Adi.CSS_Source;
      Path : constant String := "/tmp/adi_css_sources_order.css";
      Src  : Style_Source;
      W    : constant Box_Handle := Create_Handle;
      OK   : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Write_Text_File (Path, ".c { opacity: 0.25; }");

      Set_Dynamic_Sources
        (Src, [CSS_File (Path), CSS_Text (".c { opacity: 0.75; }")], OK);
      Assert (OK, "the configuration installs");
      Set_Mode (Src, Dynamic_Mode, OK);
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.75, "the later entry wins");

      Set_Dynamic_Sources
        (Src, [CSS_Text (".c { opacity: 0.75; }"), CSS_File (Path)], OK);
      Assert (OK, "and reversed it installs too");
      Assert (Opacity_Of = 0.25, "the later entry wins again");
   end;

   Section ("A configuration that will not install changes nothing");

   declare
      use Adi.CSS_Source;
      Good : constant String := "/tmp/adi_css_sources_good.css";
      Src  : Style_Source;
      W    : constant Box_Handle := Create_Handle;
      OK   : Boolean := False;

      function Opacity_Of (B : Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+B, Main_Part).Opacity));
   begin
      Write_Text_File (Good, ".c { opacity: 0.25; }");
      Set_Dynamic_Sources (Src, [CSS_File (Good)], OK);
      Set_Mode (Src, Dynamic_Mode, OK);
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of (W) = 0.25, "the widget takes the sheet's styles");

      Set_Dynamic_Sources
        (Src, [CSS_File (Good), CSS_File ("no/such/file.css")], OK);
      Assert (not OK, "a missing file fails");
      Assert (Get_Mode (Src) = Dynamic_Mode, "the mode is left alone");
      Assert (Opacity_Of (W) = 0.25, "and the widget keeps its styles");

      --  A widget bound now is styled from whatever the source holds, so
      --  this separates a sheet still loaded from pixels merely stale.
      declare
         Fresh : constant Box_Handle := Create_Handle;
      begin
         Bind_Selector_Set (Source => Src, W => +Fresh, Class_Name => "c");
         Assert (Opacity_Of (Fresh) = 0.25,
                 "and the sheet is still there for a new binding");
      end;

      --  The sheet surviving is half the contract; the entry list is the
      --  other half, and only a reload can see it.
      Reload_Dynamic (Src, OK);
      Assert (OK, "and the missing file was never added to the list");

      Set_Dynamic_Sources (Src, [CSS_File (Good), CSS_Text ("{{{")], OK);
      Assert (not OK, "CSS that will not parse fails");
      Assert (Opacity_Of (W) = 0.25, "and changes nothing either");

      declare
         Fresh : constant Box_Handle := Create_Handle;
      begin
         Bind_Selector_Set (Source => Src, W => +Fresh, Class_Name => "c");
         Assert (Opacity_Of (Fresh) = 0.25,
                 "the sheet surviving a bad parse is the loaded one");
      end;

      --  A directory exists and cannot be read.
      Set_Dynamic_Sources (Src, [CSS_File ("tests")], OK);
      Assert (not OK, "an unreadable path fails rather than raising");
      Assert (Opacity_Of (W) = 0.25, "and changes nothing");
   end;

   Section ("A sheet the parser gives up on leaves the last one standing");

   declare
      use Adi.CSS_Source;
      Src : Style_Source;
      W   : constant Box_Handle := Create_Handle;
      OK  : Boolean := False;

      --  Past Max_Style_Rules (16) distinct state selectors on one
      --  selector, which Build_Styles abandons part way through rather
      --  than rejecting up front.
      States : constant array (1 .. 20) of access constant String :=
        [new String'(":hover"),          new String'(":focus"),
         new String'(":disabled"),       new String'(":selected"),
         new String'(":pressed"),        new String'(":hover:focus"),
         new String'(":hover:disabled"), new String'(":hover:selected"),
         new String'(":hover:pressed"),  new String'(":focus:disabled"),
         new String'(":focus:selected"), new String'(":focus:pressed"),
         new String'(":disabled:selected"),
         new String'(":disabled:pressed"),
         new String'(":selected:pressed"),
         new String'(":hover:focus:disabled"),
         new String'(":hover:focus:selected"),
         new String'(":hover:focus:pressed"),
         new String'(":hover:disabled:selected"),
         new String'(":hover:disabled:pressed")];

      function Too_Many_States return String is
         use Ada.Strings.Unbounded;
         Result : Ada.Strings.Unbounded.Unbounded_String;
      begin
         for S of States loop
            Append (Result, ".c" & S.all & " { opacity: 0.1; }" & ASCII.LF);
         end loop;
         return To_String (Result);
      end Too_Many_States;

      function Opacity_Of (B : Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+B, Main_Part).Opacity));
   begin
      Set_Dynamic_Sources (Src, [CSS_Text (".c { opacity: 0.25; }")], OK);
      Set_Mode (Src, Dynamic_Mode, OK);
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of (W) = 0.25, "the widget takes the sheet's styles");

      Set_Dynamic_Sources (Src, [CSS_Text (Too_Many_States)], OK);
      if OK then
         --  The limit was not reached, so this section proves nothing;
         --  say so rather than pass quietly.
         Assert (False,
                 "expected the state-rule limit to reject the sheet");
      else
         Assert (Opacity_Of (W) = 0.25, "the widget keeps its styles");
         declare
            Fresh : constant Box_Handle := Create_Handle;
         begin
            Bind_Selector_Set (Source => Src, W => +Fresh, Class_Name => "c");
            Assert (Opacity_Of (Fresh) = 0.25,
                    "and the selectors of the good sheet are still there");
         end;
      end if;
   end;

   Section ("A reload that fails still says why");

   declare
      use Adi.CSS_Source;
      A        : constant String := "/tmp/adi_css_sources_err_a.css";
      B        : constant String := "/tmp/adi_css_sources_err_b.css";
      Src      : Style_Source;
      W        : constant Box_Handle := Create_Handle;
      OK       : Boolean := False;
      Reloaded : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Write_Text_File (A, ".c { opacity: 0.25; }");
      Write_Text_File (B, ".d { opacity: 0.5; }");
      Set_Dynamic_Sources (Src, [CSS_File (A), CSS_File (B)], OK);
      Set_Mode (Src, Dynamic_Mode, OK);
      Set_Auto_Reload (Src, True);
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the sheet's styles");

      --  B goes away, so Tick does not see it change -- but touching A
      --  triggers the reload that then cannot read B.
      Ada.Directories.Delete_File (B);
      delay 1.1;
      Write_Text_File (A, ".c { opacity: 0.9; }");

      Tick (Src, Reloaded, OK);
      Assert (not OK, "the reload fails");
      Assert (Get_Last_Error (Src) /= "",
              "and does not report an empty reason");
      Assert (Ada.Strings.Fixed.Index (Get_Last_Error (Src), B) > 0,
              "naming the sheet it could not read");
      Assert (Opacity_Of = 0.25,
              "and the configuration that worked is still in force");
   end;

   Section ("An empty configuration clears and restyles");

   declare
      use Adi.CSS_Source;
      Src : Style_Source;
      W   : constant Box_Handle := Create_Handle;
      OK  : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Set_Dynamic_Sources (Src, [CSS_Text (".c { opacity: 0.25; }")], OK);
      Assert (OK, "text alone installs without touching the disk");
      Set_Mode (Src, Dynamic_Mode, OK);
      Assert (OK, "and dynamic mode holds");
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the styles");

      Set_Dynamic_Sources (Src, Empty_Dynamic_Sources, OK);
      Assert (OK, "the empty configuration installs");
      Assert (Opacity_Of /= 0.25,
              "and takes the styles back without a further call");
   end;

   Section ("Repointing a configuration keeps its text entries");

   declare
      use Adi.CSS_Source;
      P1   : constant String := "/tmp/adi_css_sources_p1.css";
      P2   : constant String := "/tmp/adi_css_sources_p2.css";
      Text : constant String := ".t { opacity: 0.5; }";
      Src  : Style_Source;
      W    : constant Box_Handle := Create_Handle;
      T    : constant Box_Handle := Create_Handle;
      OK   : Boolean := False;

      function Opacity_Of (B : Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+B, Main_Part).Opacity));
   begin
      Write_Text_File (P1, ".c { opacity: 0.25; }");
      Write_Text_File (P2, ".c { opacity: 0.75; }");

      Set_Dynamic_Sources (Src, [CSS_File (P1), CSS_Text (Text)], OK);
      Set_Mode (Src, Dynamic_Mode, OK);
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Bind_Selector_Set (Source => Src, W => +T, Class_Name => "t");
      Assert (Opacity_Of (W) = 0.25 and then Opacity_Of (T) = 0.5,
              "both entries are in force");

      Set_Dynamic_Sources (Src, [CSS_File (P2), CSS_Text (Text)], OK);
      Assert (OK, "repointing the file installs");
      Assert (Opacity_Of (W) = 0.75, "the new file is in force");
      Assert (Opacity_Of (T) = 0.5, "and the text entry survived it");

      Set_Dynamic_Sources
        (Src, [CSS_File ("no/such/file.css"), CSS_Text (Text)], OK);
      Assert (not OK, "repointing at a missing file fails");
      Assert (Opacity_Of (W) = 0.75 and then Opacity_Of (T) = 0.5,
              "and leaves the whole configuration in force");
   end;

   Section ("Tick watches the file entries of a mixed configuration");

   declare
      use Adi.CSS_Source;
      Path     : constant String := "/tmp/adi_css_sources_tick.css";
      Text     : constant String := ".t { opacity: 0.5; }";
      Src      : Style_Source;
      W        : constant Box_Handle := Create_Handle;
      T        : constant Box_Handle := Create_Handle;
      OK       : Boolean := False;
      Reloaded : Boolean := False;

      function Opacity_Of (B : Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+B, Main_Part).Opacity));
   begin
      Write_Text_File (Path, ".c { opacity: 0.25; }");
      Set_Dynamic_Sources (Src, [CSS_File (Path), CSS_Text (Text)], OK);
      Set_Mode (Src, Dynamic_Mode, OK);
      Set_Auto_Reload (Src, True);
      Bind_Selector_Set (Source => Src, W => +W, Class_Name => "c");
      Bind_Selector_Set (Source => Src, W => +T, Class_Name => "t");

      delay 1.1;
      Write_Text_File (Path, ".c { opacity: 0.9; }");
      Tick (Src, Reloaded, OK);
      Assert (OK and then Reloaded, "the file entry is still watched");
      Assert (Opacity_Of (W) = 0.9, "and its new content is in force");
      Assert (Opacity_Of (T) = 0.5, "the text entry survived the reload");
   end;

   Finish;
end Css_Source_Test;
