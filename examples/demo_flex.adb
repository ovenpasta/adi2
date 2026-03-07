--  file: demo_flex.adb
--  Flex Layout Demo - Tests various flex configurations
with Adi.Log;
with Ada.Exceptions; use Ada.Exceptions;
with GNAT.Traceback.Symbolic;

with Adi.App;
with Adi.Window;use Adi.Window;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Core;
with Demo_Flex_Styles; use Demo_Flex_Styles;
use Adi;

procedure Demo_Flex is
   use Adi.Core;
   use Adi.Widget_Styles;
   use type Adi.Widget.Box.Box_Handle;
   subtype Box_Handle is Adi.Widget.Box.Box_Handle;

   App    : Adi.App.App;
   Window : Adi.Window.Window_Handle;

   -------------------------------------------------
   -- Helper: Create a colored box with label
   -------------------------------------------------
   function Create_Box (
      Color : Color_Value;
      W, H  : Pixel_Type := 0.0;  -- 0 = auto/flex
      Grow  : Float := 0.0;
      Shrink : Float := 1.0) return Box_Handle
   is
      B : constant Box_Handle := Adi.Widget.Box.Create_Handle;
      Style : Widget_Style;
   begin
      Style := Adi.Widget_Styles.Create
         .Base ((Box_Base_Class_Base_Style with delta
            Background_Color => Set_Bg (Color),
            Width            => (if W > 0.0 then Set (Size (Px (Float (W)))) else Opt_Size.Unset),
            Height           => (if H > 0.0 then Set (Size (Px (Float (H)))) else Opt_Size.Unset),
            Flex_Grow        => Set (Flex_Grow_Value (Grow)),
            Flex_Shrink      => Set (Flex_Shrink_Value (Shrink))))
         .Build;

      Adi.Widget.Set_Part_Style (Widget_Handle'(+B), Main_Part, Style);
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
      Bg_Color  : Color_Value := C (Light_Gray)) return Box_Handle
   is
      Container : constant Box_Handle := Adi.Widget.Box.Create_Handle;
      Style : Widget_Style;
   begin
      Style := Adi.Widget_Styles.Create
         .Base ((Flex_Container_Class_Base_Style with delta
            Flex_Direction   => Set (Direction),
            Justify_Content  => Set (Justify),
            Align_Items      => Set (Align),
            Gap              => Set (Gap (Px (Gap_Px))),
            Padding          => Set (CSS_Styles.CSS_Box (Px (Padding_Px))),
            Background_Color => Set_Bg (Bg_Color)))
         .Build;

      Adi.Widget.Set_Part_Style (Widget_Handle'(+Container), Main_Part, Style);
      return Container;
   end Create_Flex_Container;

   -------------------------------------------------
   -- Demo 1: Horizontal Row with Fixed Sizes
   -------------------------------------------------
   function Demo_Row_Fixed return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Center,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 1: Row with fixed size boxes");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 60.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 80.0, H => 60.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 50.0, H => 50.0));
      return Container;
   end Demo_Row_Fixed;

   -------------------------------------------------
   -- Demo 2: Horizontal Row with Flex Grow
   -------------------------------------------------
   function Demo_Row_Grow return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 2: Row with flex-grow (1:2:1 ratio)");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), H => 50.0, Grow => 1.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), H => 50.0, Grow => 2.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), H => 50.0, Grow => 1.0));
      return Container;
   end Demo_Row_Grow;

   -------------------------------------------------
   -- Demo 3: Column Layout
   -------------------------------------------------
   function Demo_Column return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Column,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 8.0);
   begin
      Adi.Log.Info ("Demo 3: Column layout with stretch");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Orange), H => 30.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Purple), H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Yellow), H => 35.0));
      return Container;
   end Demo_Column;

   -------------------------------------------------
   -- Demo 4: Space Between
   -------------------------------------------------
   function Demo_Space_Between return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Between,
         Align     => Center,
         Gap_Px    => 0.0);  -- Gap not used with space-between
   begin
      Adi.Log.Info ("Demo 4: Space-between distribution");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 50.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 50.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 50.0, H => 40.0));
      return Container;
   end Demo_Space_Between;

   -------------------------------------------------
   -- Demo 5: Space Around
   -------------------------------------------------
   function Demo_Space_Around return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Around,
         Align     => Center,
         Gap_Px    => 0.0);
   begin
      Adi.Log.Info ("Demo 5: Space-around distribution");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 40.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 40.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 40.0, H => 40.0));
      return Container;
   end Demo_Space_Around;

   -------------------------------------------------
   -- Demo 6: Space Evenly
   -------------------------------------------------
   function Demo_Space_Evenly return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Evenly,
         Align     => Center,
         Gap_Px    => 0.0);
   begin
      Adi.Log.Info ("Demo 6: Space-evenly distribution");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Orange), W => 40.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Purple), W => 40.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Yellow), W => 40.0, H => 40.0));
      return Container;
   end Demo_Space_Evenly;

   -------------------------------------------------
   -- Demo 7: Cross-Axis Alignment (Flex Start)
   -------------------------------------------------
   function Demo_Align_Start return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Flex_Start,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 7: Align-items: flex-start");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 50.0, H => 30.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 50.0, H => 50.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 50.0, H => 40.0));
      return Container;
   end Demo_Align_Start;

   -------------------------------------------------
   -- Demo 8: Cross-Axis Alignment (Flex End)
   -------------------------------------------------
   function Demo_Align_End return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Flex_End,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 8: Align-items: flex-end");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 50.0, H => 30.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 50.0, H => 50.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 50.0, H => 40.0));
      return Container;
   end Demo_Align_End;

   -------------------------------------------------
   -- Demo 9: Cross-Axis Alignment (Center)
   -------------------------------------------------
   function Demo_Align_Center return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Center,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 9: Align-items: center");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 50.0, H => 30.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 50.0, H => 60.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 50.0, H => 45.0));
      return Container;
   end Demo_Align_Center;

   -------------------------------------------------
   -- Demo 10: Reversed Row
   -------------------------------------------------
   function Demo_Row_Reverse return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row_Reverse,
         Justify   => Flex_Start,
         Align     => Center,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 10: Row-reverse (RGB should appear as BGR)");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 60.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 60.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 60.0, H => 40.0));
      return Container;
   end Demo_Row_Reverse;

   -------------------------------------------------
   -- Demo 11: Column Reverse
   -------------------------------------------------
   function Demo_Column_Reverse return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Column_Reverse,
         Justify   => Flex_Start,
         Align     => Adi.CSS_Styles.Center,
         Gap_Px    => 8.0);
   begin
      Adi.Log.Info ("Demo 11: Column-reverse");
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Red), W => 80.0, H => 25.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Green), W => 80.0, H => 25.0));
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Blue), W => 80.0, H => 25.0));
      return Container;
   end Demo_Column_Reverse;

   -------------------------------------------------
   -- Demo 12: Nested Flex Containers
   -------------------------------------------------
   function Demo_Nested return Box_Handle is
      Outer : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Space_Between,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (White));

      Left_Column : constant Box_Handle := Create_Flex_Container (
         Direction => Column,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 5.0,
         Bg_Color  => RGB (240, 240, 255));

      Right_Column : constant Box_Handle := Create_Flex_Container (
         Direction => Column,
         Justify   => Space_Between,
         Align     => Adi.CSS_Styles.Center,
         Gap_Px    => 5.0,
         Bg_Color  => RGB (255, 240, 240));
   begin
      Adi.Log.Info ("Demo 12: Nested flex containers");

      --  Left column children
      Adi.Widget.Box.Add_Child (Left_Column, +Create_Box (C (Blue), H => 30.0));
      Adi.Widget.Box.Add_Child (Left_Column, +Create_Box (C (Blue), H => 30.0));
      Adi.Widget.Box.Add_Child (Left_Column, +Create_Box (C (Blue), H => 30.0));

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
               Padding          => Set (CSS_Styles.CSS_Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (240, 240, 255)),
               Border_Width     => Set (Border_Width (Px (2))),
               Border_Color     => Set (Border_Color (C (Gray))),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Radius    => Set (Radius (Px (8))),
               Flex_Grow        => Set (1.0),
               others           => <>))
            .Build;
         Adi.Widget.Set_Part_Style (Widget_Handle'(+Left_Column), Main_Part, Left_Style);
      end;

      --  Right column children
      Adi.Widget.Box.Add_Child (Right_Column, +Create_Box (C (Red), W => 40.0, H => 40.0));
      Adi.Widget.Box.Add_Child (Right_Column, +Create_Box (C (Red), W => 50.0, H => 50.0));
      Adi.Widget.Box.Add_Child (Right_Column, +Create_Box (C (Red), W => 45.0, H => 45.0));

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
               Padding          => Set (CSS_Styles.CSS_Box (Px (10.0))),
               Background_Color => Set_Bg (RGB (255, 240, 240)),
               Border_Width     => Set (Border_Width (Px (2))),
               Border_Color     => Set (Border_Color (C (Gray))),
               Border_Style     => Set (Border_Style (Solid)),
               Border_Radius    => Set (Radius (Px (8))),
               Flex_Grow        => Set (1.0),
               others           => <>))
            .Build;
         Adi.Widget.Set_Part_Style (Widget_Handle'(+Right_Column), Main_Part, Right_Style);
      end;

      Adi.Widget.Box.Add_Child (Outer, +Left_Column);
      Adi.Widget.Box.Add_Child (Outer, +Right_Column);

      return Outer;
   end Demo_Nested;

   -------------------------------------------------
   -- Demo 13: Mixed Fixed and Flexible
   -------------------------------------------------
   function Demo_Mixed return Box_Handle is
      Container : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 10.0);
   begin
      Adi.Log.Info ("Demo 13: Fixed sidebar + flexible content");
      --  Fixed left sidebar
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Gray), W => 80.0, H => 60.0, Grow => 0.0));
      --  Flexible main content
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (White), Grow => 1.0));
      --  Fixed right sidebar
      Adi.Widget.Box.Add_Child (Container, +Create_Box (C (Gray), W => 60.0, H => 60.0, Grow => 0.0));
      return Container;
   end Demo_Mixed;

   -------------------------------------------------
   -- Main Layout: Vertical stack of all demos
   -------------------------------------------------
   function Create_Main_Layout return Box_Handle is
      Main : constant Box_Handle := Create_Flex_Container (
         Direction  => Column,
         Justify    => Flex_Start,
         Align      => Stretch,
         Gap_Px     => 15.0,
         Padding_Px => 20.0,
         Bg_Color   => RGB (245, 245, 245));

      --  Row 1: First 3 demos side by side
      Row1 : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 2: Next 3 demos
      Row2 : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 3: Align demos
      Row3 : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 4: Reverse demos
      Row4 : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Row 5: Nested and mixed
      Row5 : constant Box_Handle := Create_Flex_Container (
         Direction => Row,
         Justify   => Flex_Start,
         Align     => Stretch,
         Gap_Px    => 15.0,
         Bg_Color  => C (Transparent));

      --  Helper to set flex grow on row containers
      procedure Set_Row_Flex (R : Box_Handle) is
      begin
         Adi.Widget.Set_Part_Style (Widget_Handle'(+R), Main_Part, Row_Base_Class_Widget);
      end Set_Row_Flex;

      --  Helper to make demo containers equal width
      procedure Set_Demo_Flex (D : Box_Handle) is
         Old_Style : constant Widget_Style := Get_Part_Style (+D, Main_Part);
         New_Base : Style_Rules := Compute_Style (Old_Style, No_States);
      begin
         New_Base.Flex_Grow := Set (1.0);
         New_Base.Min_Width := Set (Size (Px (150.0)));
         New_Base.Min_Height := Set (Size (Px (100.0)));
         Set_Part_Style (+D, Main_Part,
            Adi.Widget_Styles.Create.Base (New_Base).Build);
      end Set_Demo_Flex;

      D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13 : Box_Handle;
   begin
      Adi.Log.Info ("Creating flex layout demos...");
      Adi.Log.Info ("================================");

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
      Adi.Widget.Box.Add_Child (Row1, +D1);
      Adi.Widget.Box.Add_Child (Row1, +D2);
      Adi.Widget.Box.Add_Child (Row1, +D3);

      --  Assemble Row 2
      Adi.Widget.Box.Add_Child (Row2, +D4);
      Adi.Widget.Box.Add_Child (Row2, +D5);
      Adi.Widget.Box.Add_Child (Row2, +D6);

      --  Assemble Row 3
      Adi.Widget.Box.Add_Child (Row3, +D7);
      Adi.Widget.Box.Add_Child (Row3, +D8);
      Adi.Widget.Box.Add_Child (Row3, +D9);

      --  Assemble Row 4
      Adi.Widget.Box.Add_Child (Row4, +D10);
      Adi.Widget.Box.Add_Child (Row4, +D11);

      --  Assemble Row 5
      Adi.Widget.Box.Add_Child (Row5, +D12);
      Adi.Widget.Box.Add_Child (Row5, +D13);

      --  Main layout
      Adi.Widget.Box.Add_Child (Main, +Row1);
      Adi.Widget.Box.Add_Child (Main, +Row2);
      Adi.Widget.Box.Add_Child (Main, +Row3);
      Adi.Widget.Box.Add_Child (Main, +Row4);
      Adi.Widget.Box.Add_Child (Main, +Row5);

      Adi.Log.Info ("================================");
      Adi.Log.Info ("Demo layout created. Resize window to test responsive behavior.");

      return Main;
   end Create_Main_Layout;

   Root : Box_Handle;

begin
   Adi.Log.Info ("Flex Layout Demo");
   Adi.Log.Info ("================");
   Adi.Log.Info ("");

   --  Initialize
   App.Init;

   --  Create window
   Window := Adi.Window.Create_Window_Handle ("Flex Layout Demo", (800.0, 700.0));

   --  Create demo layout
   Root := Create_Main_Layout;

   --  Set root geometry to window size
   Set_Geometry (+Root, (0.0, 0.0, 800.0, 700.0));

   --  Set as window root
   Adi.Window.Set_Root (Window, Widget_Handle'(+Root));

   --  Add window to app
   App.Add_Window (Window);

   Adi.Log.Info ("");
   Adi.Log.Info ("Running... Close window to exit.");

   --  Run event loop
   App.Run;

   Adi.Log.Info ("Demo finished.");

exception
   when E : others =>
      Adi.Log.Info ("Error occurred!");
      Adi.Log.Info ("Exception: " & Exception_Name (E));
      Adi.Log.Info ("Message: " & Exception_Message (E));
      Adi.Log.Info ("Traceback:");
      Adi.Log.Info (GNAT.Traceback.Symbolic.Symbolic_Traceback (E));
      raise;
end Demo_Flex;
