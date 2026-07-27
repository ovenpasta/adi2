pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;  use type Adi.Widget.Label.Label_Handle;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support;

procedure Style_Storage_Equivalence_Test is

   function Is_RGB_Color (Col : Color_Value; R, G, B : Natural) return Boolean is
   begin
      return Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B;
   end Is_RGB_Color;

   function Near (A, B : Float) return Boolean is
   begin
      return abs (A - B) <= 0.001;
   end Near;

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True), others => <>]);

   procedure Test_Any_Part_Fallback is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("any-fallback");
      Styles : Part_Style_Array := Empty_Part_Styles;
   begin
      Put_Line ("Test: Any_Part fallback and specific override");

      Styles (Any_Part) :=
        (Style => From ((Color => Set (RGB (10, 20, 30)), others => <>)).Build,
         Enabled => True);
      Set_Part_Styles (+W, Styles);

      declare
         Label_Resolved : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Label_Part);
         Main_Resolved  : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (Label_Resolved.Color, 10, 20, 30),
                 "Label_Part uses Any_Part fallback when part style is empty");
         Test_Support.Assert (Is_RGB_Color (Main_Resolved.Color, 10, 20, 30),
                 "Main_Part resolves to Any_Part style when only Any_Part is set");
      end;

      Styles (Label_Part) :=
        (Style => From ((Color => Set (RGB (50, 60, 70)), others => <>)).Build,
         Enabled => True);
      Set_Part_Styles (+W, Styles);

      declare
         Label_Resolved : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Label_Part);
         Main_Resolved  : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (Label_Resolved.Color, 50, 60, 70),
                 "Part-specific style overrides Any_Part fallback");
         Test_Support.Assert (Is_RGB_Color (Main_Resolved.Color, 10, 20, 30),
                 "Any_Part style still applies to Main_Part");
      end;
   end Test_Any_Part_Fallback;

   procedure Test_Enabled_Disabled_Parts is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("enabled-disabled");
      Styles : Part_Style_Array := Empty_Part_Styles;
      Main_WS : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (1, 2, 3)), others => <>)).Build;
      Label_WS : constant Widget_Style :=
        From ((Color => Set (RGB (4, 5, 6)), others => <>)).Build;
   begin
      Put_Line ("Test: enabled/disabled part storage parity");

      Styles (Main_Part) := (Style => Main_WS, Enabled => False);
      Styles (Label_Part) := (Style => Label_WS, Enabled => True);
      Set_Part_Styles (+W, Styles);

      declare
         Main_Resolved : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
         Label_Resolved : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Label_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (Main_Resolved.Background_Color, 1, 2, 3),
                 "Main_Part style resolves even when part is marked disabled");
         Test_Support.Assert (Is_RGB_Color (Label_Resolved.Color, 4, 5, 6),
                 "Enabled Label_Part style resolves correctly");
         Test_Support.Assert (Get_Part_Style (+W, Main_Part) = Main_WS,
                 "Get_Part_Style preserves stored style for disabled part");
         Test_Support.Assert (Get_Part_Style (+W, Label_Part) = Label_WS,
                 "Get_Part_Style preserves stored style for enabled part");
      end;
   end Test_Enabled_Disabled_Parts;

   procedure Test_Priority_And_Tie_Order is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("priority");
      Base_Style : constant Style_Rules :=
        (Color => Set (RGB (0, 0, 0)), others => <>);
      Equal_Prio_First : constant Style_Rules :=
        (Color => Set (RGB (200, 10, 10)), others => <>);
      Equal_Prio_Second : constant Style_Rules :=
        (Color => Set (RGB (10, 200, 10)), others => <>);
      Low_Prio : constant Style_Rules :=
        (Color => Set (RGB (10, 10, 200)), others => <>);
      High_Prio : constant Style_Rules :=
        (Color => Set (RGB (210, 210, 40)), others => <>);
   begin
      Put_Line ("Test: rule priority and tie ordering");

      Set_Part_Style
        (+W,
         Main_Part,
         From (Base_Style)
           .On (When_State (State_Hovered), Equal_Prio_First, Priority => 5)
           .On (When_State (State_Hovered), Equal_Prio_Second, Priority => 5)
           .Build);

      Set_State (+W, State_Hovered, True);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (R.Color, 10, 200, 10),
                 "Equal-priority rules keep source order (later rule wins)");
      end;

      Set_Part_Style
        (+W,
         Main_Part,
         From (Base_Style)
           .On (When_State (State_Hovered), Low_Prio, Priority => 1)
           .On (When_State (State_Hovered), High_Prio, Priority => 10)
           .Build);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Test_Support.Assert (Is_RGB_Color (R.Color, 210, 210, 40),
                 "Higher-priority rule overrides lower-priority rule");
      end;
   end Test_Priority_And_Tie_Order;

   procedure Test_Dynamic_Style_Churn is
      Source : Adi.CSS_Source.Style_Source;
      W      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      OK     : Boolean := False;
      Class_Only_OK    : Boolean := True;
      Class_Id_OK      : Boolean := True;
      Alt_Class_Id_OK  : Boolean := True;
      Tag_Opacity_OK   : Boolean := True;
      Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        Adi.CSS_Source.Tag_Entry (
          "button",
          Main_Styles ((Opacity => Set (0.25), others => <>))),
        Adi.CSS_Source.Class_Entry (
          "a",
          Main_Styles ((Background_Color => Set_Bg (RGB (20, 30, 40)),
                        Padding          => Set (CSS_Box (Px (4.0))),
                        others           => <>))),
        Adi.CSS_Source.Class_Entry (
          "b",
          Main_Styles ((Background_Color => Set_Bg (RGB (30, 40, 50)),
                        Border_Width     => Set (Border_Width (Px (2.0))),
                        others           => <>))),
        Adi.CSS_Source.Id_Entry (
          "x",
          Main_Styles ((Background_Color => Set_Bg (RGB (80, 90, 100)),
                        Border_Width     => Set (Border_Width (Px (1.0))),
                        others           => <>)))
      ];
   begin
      Put_Line ("Test: repeated style churn via selector rebinding");

      Adi.CSS_Source.Set_Static_Entries (Source, Entries);
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, OK);
      Test_Support.Assert (OK, "Static mode setup succeeds for churn test");

      for I in 1 .. 180 loop
         case I mod 3 is
            when 1 =>
               Adi.CSS_Source.Bind_Selector_Set
                 (Source,
                  +W,
                  Tag_Name   => "button",
                  Class_Name => "a",
                  Id_Name    => "");
            when 2 =>
               Adi.CSS_Source.Bind_Selector_Set
                 (Source,
                  +W,
                  Tag_Name   => "button",
                  Class_Name => "a",
                  Id_Name    => "x");
            when others =>
               Adi.CSS_Source.Bind_Selector_Set
                 (Source,
                  +W,
                  Tag_Name   => "button",
                  Class_Name => "b",
                  Id_Name    => "x");
         end case;

         declare
            R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
         begin
            case I mod 3 is
               when 1 =>
                  if not Is_RGB_Color (R.Background_Color, 20, 30, 40)
                    or else not (R.Padding.Kind = Gap_Uniform
                                 and then Near (R.Padding.All_Sides.Amount, 4.0))
                  then
                     Class_Only_OK := False;
                  end if;
               when 2 =>
                  if not Is_RGB_Color (R.Background_Color, 80, 90, 100)
                    or else not (R.Padding.Kind = Gap_Uniform
                                 and then Near (R.Padding.All_Sides.Amount, 4.0))
                  then
                     Class_Id_OK := False;
                  end if;
               when others =>
                  if not Is_RGB_Color (R.Background_Color, 80, 90, 100)
                    or else not (R.Border_Width.Kind = Gap_Uniform
                                 and then Near (R.Border_Width.All_Edges.Amount, 1.0))
                  then
                     Alt_Class_Id_OK := False;
                  end if;
            end case;

            if not Near (Float (R.Opacity), 0.25) then
               Tag_Opacity_OK := False;
            end if;
         end;
      end loop;

      Test_Support.Assert (Class_Only_OK,
              "Repeated class-only rebinding remains stable across churn");
      Test_Support.Assert (Class_Id_OK,
              "Repeated class+id rebinding remains stable across churn");
      Test_Support.Assert (Alt_Class_Id_OK,
              "Repeated alt-class+id rebinding remains stable across churn");
      Test_Support.Assert (Tag_Opacity_OK,
              "Tag-only properties remain stable across churn");
   end Test_Dynamic_Style_Churn;

begin
   Put_Line ("Style storage equivalence test");

   Test_Any_Part_Fallback;
   Test_Enabled_Disabled_Parts;
   Test_Priority_And_Tie_Order;
   Test_Dynamic_Style_Churn;

   Test_Support.Finish;
end Style_Storage_Equivalence_Test;
