--  file: demo_flex.adb
--  Flex Layout Demo - Tests various flex configurations
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with GNAT.Traceback.Symbolic;

with Adi.App;
with Adi.Window;use Adi.Window;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Core;
use Adi;

procedure Demo_Flex is
   use Adi.Core;
   use Adi.CSS_Styles;
   use Adi.Widget_Styles;
    use type Adi.Widget.Widget;
   subtype Box_Widget_Access is Adi.Widget.Box.Box_Widget_Access;

   App    : Adi.App.App;
   Window : Adi.Window.Window_Access;

   -------------------------------------------------
   -- Helper: Create a colored box with label
   -------------------------------------------------
   function Create_Box (
      Color : Color_Value;
      W, H  : Pixel_Type := 0.0;  -- 0 = auto/flex
      Grow  : Float := 0.0;
      Shrink : Float := 1.0) return Box_Widget_Access
   is
      B : constant Box_Widget_Access := Adi.Widget.Box.Create;
      Style : Widget_Style;
   begin
      Style := Adi.Widget_Styles.Create
         .Base ((
            Background_Color => Set_Bg (Color),
            Border_Width     => Set (Border_Width (Px (1))),
            Border_Color     => Set (Border_Color (C (Dark_Gray))),
            Border_Style     => Set (Border_Style (Solid)),
            Border_Radius    => Set (Radius (Px (4.0))),
            Width            => (if W > 0.0 then Set (Size (Px (Float(W)))) else Opt_Size.Unset),
            Height           => (if H > 0.0 then Set (Size (Px (Float(H)))) else Opt_Size.Unset),
            Flex_Grow        => Set (Flex_Grow_Value (Grow)),
            Flex_Shrink      => Set (Flex_Shrink_Value (Shrink)),
            Min_Width        => Set (Size (Px (20.0))),
            Min_Height       => Set (Size (Px (20.0))),
            others           => <>))
         .Build;

      Set_Part_Style (B.all, Main_Part, Style);
      return B;
   end Create_Box;

   -------------------------------------------------
   -- Helper: Create a flex container
   -------------------------------------------------
   function Create_Flex_Container (
      Direction : Flex_Direction_Value := Row;
      Justify   : Justify_Content_Value := Flex_Start;
      Align     : Align_Items_Value := Stretch;
      Gap_Px    : Float := 8.0;
      Padding_Px : Float := 10.0;
      Bg_Color  : Color_Value := C (Light_Gray)) return Box_Widget_Access
   is
      Container : constant Box_Widget_Access := Adi.Widget.Box.Create;
      Style : Widget_Style;
   begin
      Style := Adi.Widget_Styles.Create
         .Base ((
            Display          => Set (Flex),
            Flex_Direction   => Set (Direction),
            Justify_Content  => Set (Justify),
            Align_Items      => Set (Align),
            Gap              => Set (Gap (Px (Gap_Px))),
            Padding          => Set (CSS_Styles.Box (Px (Padding_Px))),
            Background_Color => Set_Bg (Bg_Color),
            Border_Width     => Set (Border_Width (Px (2.0))),
            Border_Color     => Set (Border_Color (C (Gray))),
            Border_Style     => Set (Border_Style (Solid)),
            Border_Radius    => Set (Radius (Px (8.0))),
            others           => <>))
         .Build;

      Set_Part_Style (Container.all, Main_Part, Style);
      return Container;
   end Create_Flex_Container;

   -------------------------------------------------
   -- Demo 1: Horizontal Row with Fixed Sizes
   -------------------------------------------------
   function Demo_Row_Fixed return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Center,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 1: Row with fixed size boxes");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 60.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 80.0, H => 60.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 50.0, H => 50.0)));
      return Container;
   end Demo_Row_Fixed;

   -------------------------------------------------
   -- Demo 2: Horizontal Row with Flex Grow
   -------------------------------------------------
   function Demo_Row_Grow return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 2: Row with flex-grow (1:2:1 ratio)");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), H => 50.0, Grow => 1.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), H => 50.0, Grow => 2.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), H => 50.0, Grow => 1.0)));
      return Container;
   end Demo_Row_Grow;

   -------------------------------------------------
   -- Demo 3: Column Layout
   -------------------------------------------------
   function Demo_Column return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Column,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 8.0);
   begin
      Put_Line ("Demo 3: Column layout with stretch");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Orange), H => 30.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Purple), H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Yellow), H => 35.0)));
      return Container;
   end Demo_Column;

   -------------------------------------------------
   -- Demo 4: Space Between
   -------------------------------------------------
   function Demo_Space_Between return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Between,
         Align     => Center,
         Gap_Px    => 0.0);  -- Gap not used with space-between
   begin
      Put_Line ("Demo 4: Space-between distribution");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 50.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 50.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 50.0, H => 40.0)));
      return Container;
   end Demo_Space_Between;

   -------------------------------------------------
   -- Demo 5: Space Around
   -------------------------------------------------
   function Demo_Space_Around return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Around,
         Align     => Center,
         Gap_Px    => 0.0);
   begin
      Put_Line ("Demo 5: Space-around distribution");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 40.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 40.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 40.0, H => 40.0)));
      return Container;
   end Demo_Space_Around;

   -------------------------------------------------
   -- Demo 6: Space Evenly
   -------------------------------------------------
   function Demo_Space_Evenly return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Evenly,
         Align     => Center,
         Gap_Px    => 0.0);
   begin
      Put_Line ("Demo 6: Space-evenly distribution");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Orange), W => 40.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Purple), W => 40.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Yellow), W => 40.0, H => 40.0)));
      return Container;
   end Demo_Space_Evenly;

   -------------------------------------------------
   -- Demo 7: Cross-Axis Alignment (Flex Start)
   -------------------------------------------------
   function Demo_Align_Start return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Flex_Start,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 7: Align-items: flex-start");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 50.0, H => 30.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 50.0, H => 50.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 50.0, H => 40.0)));
      return Container;
   end Demo_Align_Start;

   -------------------------------------------------
   -- Demo 8: Cross-Axis Alignment (Flex End)
   -------------------------------------------------
   function Demo_Align_End return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Flex_End,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 8: Align-items: flex-end");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 50.0, H => 30.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 50.0, H => 50.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 50.0, H => 40.0)));
      return Container;
   end Demo_Align_End;

   -------------------------------------------------
   -- Demo 9: Cross-Axis Alignment (Center)
   -------------------------------------------------
   function Demo_Align_Center return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Center,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 9: Align-items: center");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 50.0, H => 30.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 50.0, H => 60.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 50.0, H => 45.0)));
      return Container;
   end Demo_Align_Center;

   -------------------------------------------------
   -- Demo 10: Reversed Row
   -------------------------------------------------
   function Demo_Row_Reverse return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row_Reverse,
         Justify   => Flex_Start,
         Align     => Center,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 10: Row-reverse (RGB should appear as BGR)");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 60.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 60.0, H => 40.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 60.0, H => 40.0)));
      return Container;
   end Demo_Row_Reverse;

   -------------------------------------------------
   -- Demo 11: Column Reverse
   -------------------------------------------------
   function Demo_Column_Reverse return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Column_Reverse,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Center,
         Gap_Px    => 8.0);
   begin
      Put_Line ("Demo 11: Column-reverse");
      Add_Child (Container.all, Widget_Access (Create_Box (C (Red), W => 80.0, H => 25.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Green), W => 80.0, H => 25.0)));
      Add_Child (Container.all, Widget_Access (Create_Box (C (Blue), W => 80.0, H => 25.0)));
      return Container;
   end Demo_Column_Reverse;

   -------------------------------------------------
   -- Demo 12: Nested Flex Containers
   -------------------------------------------------
   function Demo_Nested return Box_Widget_Access is
      Outer : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Between,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (White));

      Left_Column : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Column,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 5.0,
         Bg_Color  => RGB (240, 240, 255));

      Right_Column : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Column,
         Justify   => Space_Between,
         Align     => Adi.CSS_Styles.Center,
         Gap_Px    => 5.0,
         Bg_Color  => RGB (255, 240, 240));
   begin
      Put_Line ("Demo 12: Nested flex containers");

      --  Left column children
      Add_Child (Left_Column.all, Widget_Access (Create_Box (C (Blue), H => 30.0)));
      Add_Child (Left_Column.all, Widget_Access (Create_Box (C (Blue), H => 30.0)));
      Add_Child (Left_Column.all, Widget_Access (Create_Box (C (Blue), H => 30.0)));

      --  Make left column grow
      declare
         Left_Style : Widget_Style;
      begin
         Left_Style := Adi.Widget_Styles.Create
            .Base ((
               Display          => Set (Flex),
               Flex_Direction   => Set (Column),
               Justify_Content  => Set (Flex_Start),
               Align_Items      => Set (Stretch),
               Gap              => Set (Gap (Px (5.0))),
               Padding          => Set (CSS_Styles.Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (240, 240, 255)),
               Border_Width     => Set (Border_Width (Px (2))),
               Border_Color     => Set (Border_Color (C (Gray))),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Radius    => Set (Radius (Px (8))),
               Flex_Grow        => Set (1.0),
               others           => <>))
            .Build;
         Set_Part_Style (Left_Column.all, Main_Part, Left_Style);
      end;

      --  Right column children
      Add_Child (Right_Column.all, Widget_Access (Create_Box (C (Red), W => 40.0, H => 40.0)));
      Add_Child (Right_Column.all, Widget_Access (Create_Box (C (Red), W => 50.0, H => 50.0)));
      Add_Child (Right_Column.all, Widget_Access (Create_Box (C (Red), W => 45.0, H => 45.0)));

      --  Make right column grow
      declare
         Right_Style : Widget_Style;
      begin
         Right_Style := Adi.Widget_Styles.Create
            .Base ((
               Display          => Set (Flex),
               Flex_Direction   => Set (Column),
               Justify_Content  => Set (Space_Between),
               Align_Items      => Set (Adi.CSS_Styles.Center),
               Gap              => Set (Gap (Px (5.0))),
               Padding          => Set (CSS_Styles.Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (255, 240, 240)),
               Border_Width     => Set (Border_Width (Px (2))),
               Border_Color     => Set (Border_Color (C (Gray))),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Radius    => Set (Radius (Px (8))),
               Flex_Grow        => Set (1.0),
               others           => <>))
            .Build;
         Set_Part_Style (Right_Column.all, Main_Part, Right_Style);
      end;

      Add_Child (Outer.all, Widget_Access (Left_Column));
      Add_Child (Outer.all, Widget_Access (Right_Column));

      return Outer;
   end Demo_Nested;

   -------------------------------------------------
   -- Demo 13: Mixed Fixed and Flexible
   -------------------------------------------------
   function Demo_Mixed return Box_Widget_Access is
      Container : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 10.0);
   begin
      Put_Line ("Demo 13: Fixed sidebar + flexible content");
      --  Fixed left sidebar
      Add_Child (Container.all, Widget_Access (Create_Box (C (Gray), W => 80.0, H => 60.0, Grow => 0.0)));
      --  Flexible main content
      Add_Child (Container.all, Widget_Access (Create_Box (C (White), Grow => 1.0)));
      --  Fixed right sidebar
      Add_Child (Container.all, Widget_Access (Create_Box (C (Gray), W => 60.0, H => 60.0, Grow => 0.0)));
      return Container;
   end Demo_Mixed;

   -------------------------------------------------
   -- Main Layout: Vertical stack of all demos
   -------------------------------------------------
   function Create_Main_Layout return Box_Widget_Access is
      Main : constant Box_Widget_Access := Create_Flex_Container (
         Direction  => Column,
         Justify    => Flex_Start,
         Align      => Stretch,
         Gap_Px     => 15.0,
         Padding_Px => 20.0,
         Bg_Color   => RGB (245, 245, 245));

      --  Row 1: First 3 demos side by side
      Row1 : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 2: Next 3 demos
      Row2 : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 3: Align demos
      Row3 : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 4: Reverse demos
      Row4 : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 5: Nested and mixed
      Row5 : constant Box_Widget_Access := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Helper to set flex grow on row containers
      procedure Set_Row_Flex (R : Box_Widget_Access) is
         Style : Widget_Style;
      begin
         Style := Adi.Widget_Styles.Create
            .Base ((
               Display          => Set (Flex),
               Flex_Direction   => Set (Row),
               Justify_Content  => Set (Flex_Start),
               Align_Items      => Set (Stretch),
               Gap              => Set (Gap (Px (15.0))),
               Background_Color => Set_Bg (C (Transparent)),
               Flex_Grow        => Set (0.0),  -- Rows don't grow
               others           => <>))
            .Build;
         Set_Part_Style (R.all, Main_Part, Style);
      end Set_Row_Flex;

      --  Helper to make demo containers equal width
    procedure Set_Demo_Flex (D : Box_Widget_Access) is
       Old_Style : constant Widget_Style := Get_Part_Style (D.all, Main_Part);
       New_Base : Style_Rules := Compute_Style (Old_Style, No_States);
    begin
       New_Base.Flex_Grow := Set (1.0);
       New_Base.Min_Width := Set (Size (Px (150.0)));
       New_Base.Min_Height := Set (Size (Px (100.0)));  -- Changed from Height
       Set_Part_Style (D.all, Main_Part,
          Adi.Widget_Styles.Create.Base (New_Base).Build);
    end Set_Demo_Flex;

      D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13 : Box_Widget_Access;
   begin
      Put_Line ("Creating flex layout demos...");
      Put_Line ("================================");

      --  Create all demos
      D1 := Demo_Row_Fixed;
      D2 := Demo_Row_Grow;
      D3 := Demo_Column;
      D4 := Demo_Space_Between;
      D5 := Demo_Space_Around;
      D6 := Demo_Space_Evenly;
      D7 := Demo_Align_Start;
      D8 := Demo_Align_End;
      D9 := Demo_Align_Center;
      D10 := Demo_Row_Reverse;
      D11 := Demo_Column_Reverse;
      D12 := Demo_Nested;
      D13 := Demo_Mixed;

      --  Set flex properties on demos
      Set_Demo_Flex (D1);
      Set_Demo_Flex (D2);
      Set_Demo_Flex (D3);
      Set_Demo_Flex (D4);
      Set_Demo_Flex (D5);
      Set_Demo_Flex (D6);
      Set_Demo_Flex (D7);
      Set_Demo_Flex (D8);
      Set_Demo_Flex (D9);
      Set_Demo_Flex (D10);
      Set_Demo_Flex (D11);
      Set_Demo_Flex (D12);
      Set_Demo_Flex (D13);

      --  Set row properties
      Set_Row_Flex (Row1);
      Set_Row_Flex (Row2);
      Set_Row_Flex (Row3);
      Set_Row_Flex (Row4);
      Set_Row_Flex (Row5);

      --  Assemble Row 1
      Add_Child (Row1.all, Widget_Access (D1));
      Add_Child (Row1.all, Widget_Access (D2));
      Add_Child (Row1.all, Widget_Access (D3));

      --  Assemble Row 2
      Add_Child (Row2.all, Widget_Access (D4));
      Add_Child (Row2.all, Widget_Access (D5));
      Add_Child (Row2.all, Widget_Access (D6));

      --  Assemble Row 3
      Add_Child (Row3.all, Widget_Access (D7));
      Add_Child (Row3.all, Widget_Access (D8));
      Add_Child (Row3.all, Widget_Access (D9));

      --  Assemble Row 4
      Add_Child (Row4.all, Widget_Access (D10));
      Add_Child (Row4.all, Widget_Access (D11));

      --  Assemble Row 5
      Add_Child (Row5.all, Widget_Access (D12));
      Add_Child (Row5.all, Widget_Access (D13));

      --  Main layout
      Add_Child (Main.all, Widget_Access (Row1));
      Add_Child (Main.all, Widget_Access (Row2));
      Add_Child (Main.all, Widget_Access (Row3));
      Add_Child (Main.all, Widget_Access (Row4));
      Add_Child (Main.all, Widget_Access (Row5));

      Put_Line ("================================");
      Put_Line ("Demo layout created. Resize window to test responsive behavior.");

      return Main;
   end Create_Main_Layout;

   Root : Box_Widget_Access;

begin
   Put_Line ("Flex Layout Demo");
   Put_Line ("================");
   Put_Line ("");

   --  Initialize
   App.Init;

   --  Create window
   Window := Adi.Window.Create_Window ("Flex Layout Demo", (800.0, 700.0));

   --  Create demo layout
   Root := Create_Main_Layout;

   --  Set root geometry to window size
   Set_Geometry (Root.all, (0.0, 0.0, 800.0, 700.0));

   --  Build and layout
   --Build_Items (Root.all);
   --Widget.Layout (Root.all);

   --  Set as window root (need to add this to Window)
   --  For now, we manually update
--   Window.Root := Widget_Access (Root);
   Set_Root (Window.all, Widget_Access (Root));

   --  Add window to app
   App.Add_Window (Window);

   Put_Line ("");
   Put_Line ("Running... Close window to exit.");

   --  Run event loop
   App.Run;

   Put_Line ("Demo finished.");

exception
   when E : others =>
      Put_Line ("Error occurred!");
      Put_Line ("Exception: " & Exception_Name (E));
      Put_Line ("Message: " & Exception_Message (E));
      Put_Line ("Traceback:");
      Put_Line (GNAT.Traceback.Symbolic.Symbolic_Traceback (E));
      raise;
end Demo_Flex;