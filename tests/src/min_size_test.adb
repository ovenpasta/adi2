pragma Ada_2022;

with Ada.Text_IO;
with Adi.App;
with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;

procedure Min_Size_Test is
   A : Adi.App.App;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Name : String; Cond : Boolean) is
   begin
      if Cond then
         Ada.Text_IO.Put_Line ("  [PASS] " & Name);
         Pass_Count := Pass_Count + 1;
      else
         Ada.Text_IO.Put_Line ("  [FAIL] " & Name);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   A.Init;

   Ada.Text_IO.Put_Line ("=== Min Size Dispatching Test ===");
   Ada.Text_IO.New_Line;

   --  Test 1: Label Get_Min_Size dispatches with CSS min-width
   declare
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Hello");

      Min_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (300.0))),
         others => <>
      );
      Min_WS : constant Widget_Style := From (Min_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Min_WS, Enabled => True),
         others => <>
      ];

      Min_Before : Size_2D;
      Min_After  : Size_2D;
   begin
      Min_Before := Get_Min_Size (Widget'Class (L.all));
      Ada.Text_IO.Put_Line ("  Before CSS: min_w=" &
        Pixel_Type'Image (Min_Before.Width));
      Check ("Label min-width without CSS is intrinsic text width",
             Min_Before.Width > 0.0);

      Set_Part_Styles (L.all, Parts);
      Min_After := Get_Min_Size (Widget'Class (L.all));
      Ada.Text_IO.Put_Line ("  After CSS 300px: min_w=" &
        Pixel_Type'Image (Min_After.Width));
      Check ("Label min-width with CSS 300 is >= 300",
             Min_After.Width >= 300.0);
   end;

   Ada.Text_IO.New_Line;

   --  Test 2: Flex layout respects label's Get_Min_Size
   declare
      Row : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Hi");

      Row_Style : constant Style_Rules := (
         Display        => Set (Flex),
         Flex_Direction => Set (Adi.CSS_Styles.Row),
         others => <>
      );
      Row_WS : constant Widget_Style := From (Row_Style).Build;
      Row_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Row_WS, Enabled => True),
         others => <>
      ];

      Label_Min_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (200.0))),
         others => <>
      );
      Label_WS : constant Widget_Style := From (Label_Min_Style).Build;
      Label_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Label_WS, Enabled => True),
         others => <>
      ];
   begin
      Set_Part_Styles (Row.all, Row_Parts);
      Set_Part_Styles (L.all, Label_Parts);
      Add_Child (Row.all, L);

      --  Give the row a geometry (simulating window allocation)
      Set_Geometry (Widget'Class (Row.all), (X => 0.0, Y => 0.0,
                              Width => 500.0, Height => 40.0));

      --  Run layout
      Layout (Widget'Class (Row.all));

      --  Check label geometry
      declare
         Geom : constant Rectangle := Get_Geometry (Widget'Class (L.all));
      begin
         Ada.Text_IO.Put_Line ("  Label geometry: w=" &
           Pixel_Type'Image (Geom.Width) &
           " h=" & Pixel_Type'Image (Geom.Height));
         Check ("Label width in flex >= 200 (CSS min-width)",
                Geom.Width >= 200.0);
      end;
   end;

   Ada.Text_IO.New_Line;

   --  Test 3: Get_Preferred_Size vs Get_Min_Size interaction
   declare
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Short");

      Min_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (400.0))),
         others => <>
      );
      Min_WS : constant Widget_Style := From (Min_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Min_WS, Enabled => True),
         others => <>
      ];

      Pref : Size_2D;
      Min  : Size_2D;
   begin
      Set_Part_Styles (L.all, Parts);
      Pref := Get_Preferred_Size (Widget'Class (L.all));
      Min  := Get_Min_Size (Widget'Class (L.all));
      Ada.Text_IO.Put_Line ("  Pref_w=" & Pixel_Type'Image (Pref.Width) &
        "  Min_w=" & Pixel_Type'Image (Min.Width));
      Check ("Get_Min_Size >= 400 with CSS min-width 400",
             Min.Width >= 400.0);
      Check ("Get_Min_Size > Get_Preferred_Size when CSS min > text width",
             Min.Width > Pref.Width);
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("Summary: " & Natural'Image (Pass_Count) & "/"
     & Natural'Image (Pass_Count + Fail_Count) & " passing");

   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("FAILURES DETECTED");
   end if;
end Min_Size_Test;
