with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core;         use Adi.Core;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Layout_Util;  use Adi.Layout_Util;
with Adi.Widget_Styles; use Adi.Widget_Styles;

procedure Main is

   -------------------------------------------------
   -- Test tracking
   -------------------------------------------------
   
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   -------------------------------------------------
   -- Assertion helpers
   -------------------------------------------------

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   function Colors_Equal (A, B : Color_Value) return Boolean is
   begin
      if A.Kind /= B.Kind then
         return False;
      end if;
      case A.Kind is
         when Named =>
            return A.Name = B.Name;
         when RGB =>
            return A.R = B.R and A.G = B.G and A.B = B.B;
         when RGBA =>
            return A.RA = B.RA and A.GA = B.GA and A.BA = B.BA and A.Alpha = B.Alpha;
      end case;
   end Colors_Equal;

   function Is_Named_Color (Col : Color_Value; Name : Named_Color) return Boolean is
   begin
      return Col.Kind = Named and then Col.Name = Name;
   end Is_Named_Color;

   function Is_RGB_Color (Col : Color_Value; R, G, B : Natural) return Boolean is
   begin
      return Col.Kind = RGB and then Col.R = R and then Col.G = G and then Col.B = B;
   end Is_RGB_Color;

   function Length_Equal (A, B : Length_Value) return Boolean is
   begin
      return A.Amount = B.Amount and A.Unit = B.Unit;
   end Length_Equal;

   function Border_Width_Uniform (BW : Border_Width_Value; Expected : Length_Value) return Boolean is
   begin
      return BW.Kind = Gap_Uniform and then Length_Equal (BW.All_Edges, Expected);
   end Border_Width_Uniform;

   function Border_Color_Uniform_Named (BC : Border_Color_Value; Name : Named_Color) return Boolean is
   begin
      return BC.Kind = Gap_Uniform and then Is_Named_Color (BC.All_Edges, Name);
   end Border_Color_Uniform_Named;

   -------------------------------------------------
   -- Helper procedures for printing
   -------------------------------------------------
   
   procedure Print_Color (Name : String; Col : Color_Value) is
   begin
      Put (Name & ": ");
      case Col.Kind is
         when Named =>
            Put_Line (Col.Name'Image);
         when RGB =>
            Put_Line ("RGB(" & Col.R'Image & "," & Col.G'Image & "," & Col.B'Image & ")");
         when RGBA =>
            Put_Line ("RGBA(" & Col.RA'Image & "," & Col.GA'Image & "," & Col.BA'Image & "," & Col.Alpha'Image & ")");
      end case;
   end Print_Color;

   procedure Print_Length (L : Length_Value) is
   begin
      Put (L.Amount'Image & " " & L.Unit'Image);
   end Print_Length;

   procedure Print_Border_Width (Name : String; BW : Border_Width_Value) is
   begin
      Put (Name & ": ");
      case BW.Kind is
         when Gap_Uniform =>
            Print_Length (BW.All_Edges);
            New_Line;
         when Per_Edge =>
            Put ("T="); Print_Length (BW.Edges (Top));
            Put (" R="); Print_Length (BW.Edges (Right));
            Put (" B="); Print_Length (BW.Edges (Bottom));
            Put (" L="); Print_Length (BW.Edges (Left));
            New_Line;
      end case;
   end Print_Border_Width;

   procedure Print_Box (Name : String; B : CSS_Box_Value) is
   begin
      Put (Name & ": ");
      case B.Kind is
         when Gap_Uniform =>
            Print_Length (B.All_Sides);
            New_Line;
         when Axis =>
            Put ("V="); Print_Length (B.Vertical);
            Put (" H="); Print_Length (B.Horizontal);
            New_Line;
         when Per_Side =>
            Put ("T="); Print_Length (B.Sides (Top));
            Put (" R="); Print_Length (B.Sides (Right));
            Put (" B="); Print_Length (B.Sides (Bottom));
            Put (" L="); Print_Length (B.Sides (Left));
            New_Line;
      end case;
   end Print_Box;

   procedure Print_States (S : Widget_States) is
   begin
      Put ("  Active states: [");
      for St in Widget_State loop
         if S (St) then
            Put (" " & St'Image);
         end if;
      end loop;
      Put_Line (" ]");
   end Print_States;

   procedure Print_Resolved (Name : String; R : Resolved_Style) is
   begin
      Put_Line ("  --- " & Name & " ---");
      Print_Color ("    Background", R.Background_Color);
      Print_Color ("    Color", R.Color);
      Print_Border_Width ("    Border_Width", R.Border_Width);
      Print_Color ("    Border_Color", 
         (case R.Border_Color.Kind is
            when Gap_Uniform => R.Border_Color.All_Edges,
            when Per_Edge => R.Border_Color.Edges (Top)));
      Put_Line ("    Display: " & R.Display'Image);
   end Print_Resolved;

   -------------------------------------------------
   -- Widget Style Definitions
   -------------------------------------------------

   My_Button : constant Widget_Style :=
     Create
     .Base ((
        Display          => Set (Inline_Flex),
        Justify_Content  => Set (Center),
        Align_Items      => Set (Center),
        Background_Color => Set_Bg (C (Blue)),
        Color            => Set (C (White)),
        Padding          => Set (CSS_Box (Dip (12), Dip (24))),
        Border_Radius    => Set (Radius (Dip (6))),
        Border_Width     => Set (Border_Width (Dip (0))),
        Border_Color     => Set (Border_Color (C (Blue))),
        others           => <>
     ))
     .On_Hover ((Background_Color => Set_Bg (RGB (0, 100, 255)), others => <>))
     .On_Press ((Background_Color => Set_Bg (RGB (0, 50, 200)), others => <>))
     .On_Focus ((Border_Color => Set (Border_Color (C (Yellow))),
                 Border_Width => Set (Border_Width (Dip (2))),
                 others => <>))
     .On_Disabled ((Background_Color => Set_Bg (C (Gray)),
                    Color => Set (C (Dark_Gray)),
                    others => <>))
     .On_Hover_And_Focus ((Background_Color => Set_Bg (RGB (50, 150, 255)), others => <>))
     .On_Hover_Not_Disabled ((Background_Color => Set_Bg (RGB (0, 120, 255)), others => <>))
     .Build;

   Card_Widget : constant Widget_Style :=
     From (Card_Style)
     .On_Hover ((Border_Color => Set (Border_Color (C (Blue))), others => <>))
     .On_Selected ((Background_Color => Set_Bg (RGB (240, 248, 255)),
                    Border_Color => Set (Border_Color (C (Blue))),
                    Border_Width => Set (Border_Width (Dip (2))),
                    others => <>))
     .Build;

   Complex_Widget : constant Widget_Style :=
     Create
     .Base ((Background_Color => Set_Bg (C (White)),
             Border_Width => Set (Border_Width (Dip (1))),
             Border_Color => Set (Border_Color (C (Light_Gray))),
             others => <>))
     .On (When_State (State_Hovered) and When_Not (State_Disabled),
          (Background_Color => Set_Bg (C (Light_Gray)), others => <>))
     .On (When_State (State_Selected) and When_State (State_Focused),
          (Border_Color => Set (Border_Color (C (Blue))),
           Border_Width => Set (Border_Width (Dip (3))),
           others => <>),
          Priority => 100)
     .Build;

   Typography_Widget : constant Widget_Style :=
     Create
     .Base ((Font_Weight => Set (Weight_Semi_Bold),
             Font_Style => Set (Style_Italic),
             Text_Decoration => Set (Decoration_Underline),
             others => <>))
     .Build;

   -------------------------------------------------
   -- Test procedures
   -------------------------------------------------

   procedure Test_Button_Normal is
      R : constant Resolved_Style := Compute_Resolved (My_Button, (others => False));
   begin
      Put_Line ("Test: Button Normal");
      Print_Resolved ("Button Normal", R);
      
      Assert (Is_Named_Color (R.Background_Color, Blue),
              "Background should be Blue");
      Assert (Is_Named_Color (R.Color, White),
              "Text color should be White");
      Assert (R.Display = Inline_Flex,
              "Display should be Inline_Flex");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (0)),
              "Border width should be 0 Dip");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Blue),
              "Border color should be Blue");
      New_Line;
   end Test_Button_Normal;

   procedure Test_Button_Hovered is
      R : constant Resolved_Style := Compute_Resolved (
         My_Button, 
         (State_Hovered => True, others => False));
   begin
      Put_Line ("Test: Button Hovered");
      Print_Resolved ("Button Hovered", R);
      
      --  On_Hover_Not_Disabled has higher specificity (2) than On_Hover (1)
      --  so it should win with RGB (0, 120, 255)
      Assert (Is_RGB_Color (R.Background_Color, 0, 120, 255),
              "Background should be RGB(0,120,255) from On_Hover_Not_Disabled");
      Assert (Is_Named_Color (R.Color, White),
              "Text color should remain White");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (0)),
              "Border width should remain 0 Dip");
      New_Line;
   end Test_Button_Hovered;

   procedure Test_Button_Pressed is
      R : constant Resolved_Style := Compute_Resolved (
         My_Button, 
         (State_Pressed => True, others => False));
   begin
      Put_Line ("Test: Button Pressed");
      Print_Resolved ("Button Pressed", R);
      
      Assert (Is_RGB_Color (R.Background_Color, 0, 50, 200),
              "Background should be RGB(0,50,200)");
      Assert (Is_Named_Color (R.Color, White),
              "Text color should remain White");
      New_Line;
   end Test_Button_Pressed;

   procedure Test_Button_Focused is
      R : constant Resolved_Style := Compute_Resolved (
         My_Button, 
         (State_Focused => True, others => False));
   begin
      Put_Line ("Test: Button Focused");
      Print_Resolved ("Button Focused", R);
      
      Assert (Is_Named_Color (R.Background_Color, Blue),
              "Background should remain Blue (focus doesn't change it)");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (2)),
              "Border width should be 2 Dip");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Yellow),
              "Border color should be Yellow");
      New_Line;
   end Test_Button_Focused;

   procedure Test_Button_Hovered_And_Focused is
      R : constant Resolved_Style := Compute_Resolved (
         My_Button, 
         (State_Hovered => True, State_Focused => True, others => False));
   begin
      Put_Line ("Test: Button Hovered + Focused");
      Print_Resolved ("Button Hovered+Focused", R);
      
      --  On_Hover_And_Focus has specificity 2
      --  On_Hover_Not_Disabled also has specificity 2
      --  On_Focus has specificity 1
      --  Rules with same specificity: last one wins
      --  Order: On_Hover(1), On_Focus(1), On_Hover_And_Focus(2), On_Hover_Not_Disabled(2)
      --  After sorting by priority: On_Hover, On_Focus, On_Hover_And_Focus, On_Hover_Not_Disabled
      --  So On_Hover_Not_Disabled wins for background
      Assert (Is_RGB_Color (R.Background_Color, 0, 120, 255),
              "Background should be RGB(0,120,255) from On_Hover_Not_Disabled (last with spec 2)");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (2)),
              "Border width should be 2 Dip from On_Focus");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Yellow),
              "Border color should be Yellow from On_Focus");
      New_Line;
   end Test_Button_Hovered_And_Focused;

   procedure Test_Button_Disabled is
      R : constant Resolved_Style := Compute_Resolved (
         My_Button, 
         (State_Disabled => True, others => False));
   begin
      Put_Line ("Test: Button Disabled");
      Print_Resolved ("Button Disabled", R);
      
      Assert (Is_Named_Color (R.Background_Color, Gray),
              "Background should be Gray");
      Assert (Is_Named_Color (R.Color, Dark_Gray),
              "Text color should be Dark_Gray");
      New_Line;
   end Test_Button_Disabled;

   procedure Test_Button_Hovered_And_Disabled is
      R : constant Resolved_Style := Compute_Resolved (
         My_Button, 
         (State_Hovered => True, State_Disabled => True, others => False));
   begin
      Put_Line ("Test: Button Hovered + Disabled");
      Print_Resolved ("Button Hovered+Disabled", R);
      
      --  On_Hover matches (specificity 1)
      --  On_Disabled matches (specificity 1)
      --  On_Hover_Not_Disabled does NOT match (disabled is true, but selector requires not disabled)
      --  On_Hover_And_Focus does NOT match (focused is false)
      --  So: On_Hover and On_Disabled both match
      --  On_Disabled comes after On_Hover in rule list, so it wins
      Assert (Is_Named_Color (R.Background_Color, Gray),
              "Background should be Gray (disabled overrides hover)");
      Assert (Is_Named_Color (R.Color, Dark_Gray),
              "Text color should be Dark_Gray");
      New_Line;
   end Test_Button_Hovered_And_Disabled;

   procedure Test_Card_Normal is
      R : constant Resolved_Style := Compute_Resolved (Card_Widget, (others => False));
   begin
      Put_Line ("Test: Card Normal");
      Print_Resolved ("Card Normal", R);
      
      Assert (Is_Named_Color (R.Background_Color, White),
              "Background should be White");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Light_Gray),
              "Border color should be Light_Gray");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (1)),
              "Border width should be 1 Dip");
      New_Line;
   end Test_Card_Normal;

   procedure Test_Card_Hovered is
      R : constant Resolved_Style := Compute_Resolved (
         Card_Widget, 
         (State_Hovered => True, others => False));
   begin
      Put_Line ("Test: Card Hovered");
      Print_Resolved ("Card Hovered", R);
      
      Assert (Is_Named_Color (R.Background_Color, White),
              "Background should remain White");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Blue),
              "Border color should be Blue");
      New_Line;
   end Test_Card_Hovered;

   procedure Test_Card_Selected is
      R : constant Resolved_Style := Compute_Resolved (
         Card_Widget, 
         (State_Selected => True, others => False));
   begin
      Put_Line ("Test: Card Selected");
      Print_Resolved ("Card Selected", R);
      
      Assert (Is_RGB_Color (R.Background_Color, 240, 248, 255),
              "Background should be RGB(240,248,255)");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Blue),
              "Border color should be Blue");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (2)),
              "Border width should be 2 Dip");
      New_Line;
   end Test_Card_Selected;

   procedure Test_Complex_Normal is
      R : constant Resolved_Style := Compute_Resolved (Complex_Widget, (others => False));
   begin
      Put_Line ("Test: Complex Normal");
      Print_Resolved ("Complex Normal", R);
      
      Assert (Is_Named_Color (R.Background_Color, White),
              "Background should be White");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Light_Gray),
              "Border color should be Light_Gray");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (1)),
              "Border width should be 1 Dip");
      New_Line;
   end Test_Complex_Normal;

   procedure Test_Complex_Hovered is
      R : constant Resolved_Style := Compute_Resolved (
         Complex_Widget, 
         (State_Hovered => True, others => False));
   begin
      Put_Line ("Test: Complex Hovered");
      Print_Resolved ("Complex Hovered", R);
      
      --  When_State(Hovered) and When_Not(Disabled) matches
      Assert (Is_Named_Color (R.Background_Color, Light_Gray),
              "Background should be Light_Gray");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Light_Gray),
              "Border color should remain Light_Gray");
      New_Line;
   end Test_Complex_Hovered;

   procedure Test_Complex_Hovered_And_Disabled is
      R : constant Resolved_Style := Compute_Resolved (
         Complex_Widget, 
         (State_Hovered => True, State_Disabled => True, others => False));
   begin
      Put_Line ("Test: Complex Hovered + Disabled");
      Print_Resolved ("Complex Hovered+Disabled", R);
      
      --  When_State(Hovered) and When_Not(Disabled) does NOT match
      --  So background stays White from base
      Assert (Is_Named_Color (R.Background_Color, White),
              "Background should be White (hover rule doesn't apply when disabled)");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Light_Gray),
              "Border color should remain Light_Gray");
      New_Line;
   end Test_Complex_Hovered_And_Disabled;

   procedure Test_Complex_Selected_And_Focused is
      R : constant Resolved_Style := Compute_Resolved (
         Complex_Widget, 
         (State_Selected => True, State_Focused => True, others => False));
   begin
      Put_Line ("Test: Complex Selected + Focused (high priority)");
      Print_Resolved ("Complex Selected+Focused", R);
      
      --  When_State(Selected) and When_State(Focused) matches with Priority => 100
      Assert (Is_Named_Color (R.Background_Color, White),
              "Background should remain White");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Blue),
              "Border color should be Blue");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (3)),
              "Border width should be 3 Dip");
      New_Line;
   end Test_Complex_Selected_And_Focused;

   procedure Test_Complex_All_States is
      R : constant Resolved_Style := Compute_Resolved (
         Complex_Widget, 
         (State_Hovered => True, State_Selected => True, State_Focused => True, others => False));
   begin
      Put_Line ("Test: Complex Hovered + Selected + Focused");
      Print_Resolved ("Complex All States", R);
      
      --  Both rules match:
      --  1. When_State(Hovered) and When_Not(Disabled) - specificity 2, priority 0
      --  2. When_State(Selected) and When_State(Focused) - specificity 2, priority 100
      --  Rule 2 has higher explicit priority, so it wins for border
      --  Rule 1 sets background to Light_Gray
      Assert (Is_Named_Color (R.Background_Color, Light_Gray),
              "Background should be Light_Gray from hover rule");
      Assert (Border_Color_Uniform_Named (R.Border_Color, Blue),
              "Border color should be Blue (high priority rule)");
      Assert (Border_Width_Uniform (R.Border_Width, Dip (3)),
              "Border width should be 3 Dip (high priority rule)");
      New_Line;
   end Test_Complex_All_States;

   procedure Test_Typography_Resolve is
      R : constant Resolved_Style := Compute_Resolved (Typography_Widget, (others => False));
   begin
      Put_Line ("Test: Typography Resolve");
      Assert (R.Font_Weight = Weight_Semi_Bold,
              "Font weight should resolve to Weight_Semi_Bold");
      Assert (R.Font_Style = Style_Italic,
              "Font style should resolve to Style_Italic");
      Assert (R.Text_Decoration = Decoration_Underline,
              "Text decoration should resolve to Decoration_Underline");
      New_Line;
   end Test_Typography_Resolve;

   procedure Test_DIP_Scaling is
      Saved : constant Pixel_Type := Get_Active_DIP_Scale;
      V_Px  : Float;
      V_Dip : Float;
   begin
      Put_Line ("Test: DIP Scaling");
      Set_Active_DIP_Scale (2.0);
      V_Px := Float (Length_To_Px (Px (10)));
      V_Dip := Float (Length_To_Px (Dip (10)));
      Set_Active_DIP_Scale (Saved);

      Assert (V_Px = 10.0, "Px should be unchanged by active DIP scale");
      Assert (V_Dip = 20.0, "Dip should scale with active DIP scale");
      New_Line;
   end Test_DIP_Scaling;

   procedure Test_Root_Em_Scaling is
      Saved : constant Pixel_Type := Get_Active_Root_Font_Size;
      V_Rem : Float;
   begin
      Put_Line ("Test: Root Em Scaling");
      Set_Active_Root_Font_Size (20.0);
      V_Rem := Float (Length_To_Px (Root_Em (2)));
      Set_Active_Root_Font_Size (Saved);

      Assert (V_Rem = 40.0, "Root_Em should use active root font size");
      New_Line;
   end Test_Root_Em_Scaling;

begin
   Put_Line ("========================================");
   Put_Line ("   Widget Style System Tests");
   Put_Line ("========================================");
   New_Line;

   --  Button tests
   Put_Line ("*** BUTTON TESTS ***");
   New_Line;
   Test_Button_Normal;
   Test_Button_Hovered;
   Test_Button_Pressed;
   Test_Button_Focused;
   Test_Button_Hovered_And_Focused;
   Test_Button_Disabled;
   Test_Button_Hovered_And_Disabled;

   --  Card tests
   Put_Line ("*** CARD TESTS ***");
   New_Line;
   Test_Card_Normal;
   Test_Card_Hovered;
   Test_Card_Selected;

   --  Complex widget tests
   Put_Line ("*** COMPLEX WIDGET TESTS ***");
   New_Line;
   Test_Complex_Normal;
   Test_Complex_Hovered;
   Test_Complex_Hovered_And_Disabled;
   Test_Complex_Selected_And_Focused;
   Test_Complex_All_States;

   --  Typography style-field tests
   Put_Line ("*** TYPOGRAPHY TESTS ***");
   New_Line;
   Test_Typography_Resolve;

   Put_Line ("*** DIP SCALING TESTS ***");
   New_Line;
   Test_DIP_Scaling;
   Test_Root_Em_Scaling;

   --  Summary
   Put_Line ("========================================");
   Put_Line ("   Test Summary");
   Put_Line ("========================================");
   Put_Line ("Total tests:" & Test_Count'Image);
   Put_Line ("Passed:     " & Pass_Count'Image);
   Put_Line ("Failed:     " & Fail_Count'Image);
   New_Line;
   
   if Fail_Count = 0 then
      Put_Line ("All tests PASSED!");
   else
      Put_Line ("Some tests FAILED!");
   end if;
   Put_Line ("========================================");

end Main;
