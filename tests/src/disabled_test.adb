pragma Ada_2022;
with Ada.Text_IO;        use Ada.Text_IO;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget_Styles;  use Adi.Widget_Styles;
with Adi.CSS_Styles;     use Adi.CSS_Styles;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Widget.Text_Input;

procedure Disabled_Test is

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

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

   function Normalize_Visibility (V : Visibility_Value) return Visibility_Value is
   begin
      if V = Visibility_Collapse then
         return Visibility_Hidden;
      end if;
      return V;
   end Normalize_Visibility;

   function Widget_Participates (W : Widget_Access) return Boolean is
   begin
      if W = null then
         return False;
      end if;
      declare
         Main_Style : constant Resolved_Style :=
           Get_Resolved_Part_Style (W.all, Main_Part);
      begin
         return Has_Flag (W.all, Visible)
        and then Main_Style.Display /= Display_None;
      end;
   end Widget_Participates;

   function Main_Visibility_Explicit (W : Widget_Access) return Boolean is
   begin
      if W = null then
         return False;
      end if;
      declare
         Rules : constant Style_Rules := Get_Part_Style_Rules (W.all, Main_Part);
      begin
         return Opt_Visibility.Is_Set (Rules.Visibility);
      end;
   end Main_Visibility_Explicit;

   function Effective_Visibility_Of (W : Widget_Access) return Visibility_Value is
      Parent : access Widget'Class;
      Main_Style : Resolved_Style;
   begin
      if W = null then
         return Visibility_Hidden;
      end if;
      Main_Style := Get_Resolved_Part_Style (W.all, Main_Part);
      Parent := Get_Parent (W.all);

      if Parent = null then
         return (if Main_Visibility_Explicit (W)
                 then Normalize_Visibility (Main_Style.Visibility)
                 else Visibility_Visible);
      end if;

      if Main_Visibility_Explicit (W) then
         return Normalize_Visibility (Main_Style.Visibility);
      end if;
      return Effective_Visibility_Of (Parent.all'Unchecked_Access);
   end Effective_Visibility_Of;

   --  Mirror the Is_Focus_Candidate logic from adi-window.adb
   function Is_Focus_Candidate (W : Widget_Access) return Boolean is
   begin
      return W /= null
        and then Widget_Participates (W)
        and then Effective_Visibility_Of (W) = Visibility_Visible
        and then Has_Flag (W.all, Focusable)
        and then not Is_Disabled (W.all);
   end Is_Focus_Candidate;

   -----------------------------------------------
   --  Test: Set_Disabled / Is_Disabled basics
   -----------------------------------------------
   procedure Test_Disabled_Default is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Widget is enabled by default");
      Assert (not Is_Disabled (B.all),
              "New button should not be disabled");
      Assert (not Has_State (B.all, State_Disabled),
              "Has_State(State_Disabled) should be False");
   end Test_Disabled_Default;

   procedure Test_Set_Disabled_True is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Set_Disabled makes widget disabled");
      B.Set_Disabled;
      Assert (Is_Disabled (B.all),
              "Is_Disabled should be True after Set_Disabled");
      Assert (Has_State (B.all, State_Disabled),
              "Has_State(State_Disabled) should agree with Is_Disabled");
   end Test_Set_Disabled_True;

   procedure Test_Set_Disabled_False is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Set_Disabled(False) re-enables widget");
      B.Set_Disabled;
      Assert (Is_Disabled (B.all), "Should be disabled first");
      B.Set_Disabled (False);
      Assert (not Is_Disabled (B.all),
              "Is_Disabled should be False after Set_Disabled(False)");
   end Test_Set_Disabled_False;

   -----------------------------------------------
   --  Test: Is_Focus_Candidate with disabled
   -----------------------------------------------
   procedure Test_Focus_Candidate_Enabled_Button is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Enabled button is a focus candidate");
      Assert (Is_Focus_Candidate (Widget_Access (B)),
              "Enabled, visible, focusable button should be a focus candidate");
   end Test_Focus_Candidate_Enabled_Button;

   procedure Test_Focus_Candidate_Disabled_Button is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Disabled button is not a focus candidate");
      B.Set_Disabled;
      Assert (not Is_Focus_Candidate (Widget_Access (B)),
              "Disabled button should not be a focus candidate");
   end Test_Focus_Candidate_Disabled_Button;

   procedure Test_Focus_Candidate_Reenabled_Button is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Re-enabled button is a focus candidate again");
      B.Set_Disabled;
      B.Set_Disabled (False);
      Assert (Is_Focus_Candidate (Widget_Access (B)),
              "Re-enabled button should be a focus candidate");
   end Test_Focus_Candidate_Reenabled_Button;

   procedure Test_Focus_Candidate_Non_Focusable is
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Hello");
   begin
      Put_Line ("Test: Non-focusable widget is not a focus candidate");
      Assert (not Is_Focus_Candidate (Widget_Access (L)),
              "Label (non-focusable) should not be a focus candidate");
   end Test_Focus_Candidate_Non_Focusable;

   procedure Test_Focus_Candidate_Null is
   begin
      Put_Line ("Test: Null widget is not a focus candidate");
      Assert (not Is_Focus_Candidate (null),
              "Null should not be a focus candidate");
   end Test_Focus_Candidate_Null;

   -----------------------------------------------
   --  Test: Disabled on text input
   -----------------------------------------------
   procedure Test_Disabled_Text_Input is
      T : constant Adi.Widget.Text_Input.Text_Input_Widget_Access :=
        Adi.Widget.Text_Input.Create ("Hello");
   begin
      Put_Line ("Test: Text input disabled state");
      Assert (Is_Focus_Candidate (Widget_Access (T)),
              "Enabled text input should be a focus candidate");
      T.Set_Disabled;
      Assert (Is_Disabled (T.all),
              "Text input should be disabled after Set_Disabled");
      Assert (not Is_Focus_Candidate (Widget_Access (T)),
              "Disabled text input should not be a focus candidate");
   end Test_Disabled_Text_Input;

   -----------------------------------------------
   --  Test: Disabled does not affect other states
   -----------------------------------------------
   procedure Test_Disabled_Preserves_Other_States is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Disabled does not clear other states");
      Set_Focused (B.all);
      Set_Selected (B.all);
      B.Set_Disabled;
      Assert (Has_State (B.all, State_Focused),
              "Focused state should be preserved when disabled");
      Assert (Has_State (B.all, State_Selected),
              "Selected state should be preserved when disabled");
      Assert (Is_Disabled (B.all),
              "Disabled state should also be set");
   end Test_Disabled_Preserves_Other_States;

   -----------------------------------------------
   --  Test: Disabled with visibility
   -----------------------------------------------
   procedure Test_Disabled_Invisible_Not_Candidate is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
   begin
      Put_Line ("Test: Invisible widget is not a focus candidate even if enabled");
      Set_Flag (B.all, Visible, False);
      Assert (not Is_Focus_Candidate (Widget_Access (B)),
              "Invisible widget should not be a focus candidate");
   end Test_Disabled_Invisible_Not_Candidate;

   procedure Test_Display_None_Not_Candidate is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
      Hidden_Style : constant Style_Rules := (Display => Set (Display_None), others => <>);
      Hidden_WS : constant Widget_Style := From (Hidden_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Hidden_WS, Enabled => True),
         others => <>];
   begin
      Put_Line ("Test: display:none widget is not a focus candidate");
      Set_Part_Styles (B.all, Parts);
      Assert (not Is_Focus_Candidate (Widget_Access (B)),
              "display:none widget should not be a focus candidate");
   end Test_Display_None_Not_Candidate;

   procedure Test_Visibility_Hidden_Not_Candidate is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
      Hidden_Style : constant Style_Rules := (Visibility => Set (Visibility_Hidden), others => <>);
      Hidden_WS : constant Widget_Style := From (Hidden_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Hidden_WS, Enabled => True),
         others => <>];
   begin
      Put_Line ("Test: visibility:hidden widget is not a focus candidate");
      Set_Part_Styles (B.all, Parts);
      Assert (not Is_Focus_Candidate (Widget_Access (B)),
              "visibility:hidden widget should not be a focus candidate");
   end Test_Visibility_Hidden_Not_Candidate;

   procedure Test_Visibility_Collapse_Not_Candidate is
      B : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("OK");
      Collapse_Style : constant Style_Rules := (Visibility => Set (Visibility_Collapse), others => <>);
      Collapse_WS : constant Widget_Style := From (Collapse_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Collapse_WS, Enabled => True),
         others => <>];
   begin
      Put_Line ("Test: visibility:collapse aliases hidden for focus candidate checks");
      Set_Part_Styles (B.all, Parts);
      Assert (not Is_Focus_Candidate (Widget_Access (B)),
              "visibility:collapse widget should not be a focus candidate");
   end Test_Visibility_Collapse_Not_Candidate;

   procedure Test_Visibility_Override_Is_Candidate is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
      Parent_Style : constant Style_Rules := (Visibility => Set (Visibility_Hidden), others => <>);
      Parent_WS : constant Widget_Style := From (Parent_Style).Build;
      Parent_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Parent_WS, Enabled => True),
         others => <>];
      Child_Style : constant Style_Rules := (Visibility => Set (Visibility_Visible), others => <>);
      Child_WS : constant Widget_Style := From (Child_Style).Build;
      Child_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Child_WS, Enabled => True),
         others => <>];
   begin
      Put_Line ("Test: visibility:visible child overrides hidden parent");
      Add_Child (Parent.all, Child);
      Set_Part_Styles (Parent.all, Parent_Parts);
      Set_Part_Styles (Child.all, Child_Parts);
      Assert (Is_Focus_Candidate (Widget_Access (Child)),
              "Child with visibility:visible should remain focus candidate");
   end Test_Visibility_Override_Is_Candidate;

   -----------------------------------------------
   --  Test: Recursive (inherited) disabled
   -----------------------------------------------
   procedure Test_Parent_Disabled_Child_Is_Disabled is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child  : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
   begin
      Put_Line ("Test: Parent disabled -> child Is_Disabled returns True");
      Add_Child (Parent.all, Child);
      Set_Disabled (Parent.all);
      Assert (Is_Disabled (Child.all),
              "Child should be disabled when parent is disabled");
   end Test_Parent_Disabled_Child_Is_Disabled;

   procedure Test_Parent_Disabled_Child_Get_States is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child  : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
      States : Widget_States;
   begin
      Put_Line ("Test: Parent disabled -> child Get_States includes State_Disabled");
      Add_Child (Parent.all, Child);
      Set_Disabled (Parent.all);
      States := Get_States (Child.all);
      Assert (States (State_Disabled),
              "Child Get_States should include State_Disabled");
   end Test_Parent_Disabled_Child_Get_States;

   procedure Test_Parent_Reenabled_Child_Enabled is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child  : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
   begin
      Put_Line ("Test: Parent disabled then enabled -> child Is_Disabled returns False");
      Add_Child (Parent.all, Child);
      Set_Disabled (Parent.all);
      Assert (Is_Disabled (Child.all), "Child should be disabled");
      Set_Disabled (Parent.all, False);
      Assert (not Is_Disabled (Child.all),
              "Child should be enabled after parent re-enabled");
   end Test_Parent_Reenabled_Child_Enabled;

   procedure Test_Grandparent_Disabled is
      Grandparent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Parent      : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child       : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
   begin
      Put_Line ("Test: Grandparent disabled -> grandchild Is_Disabled returns True");
      Add_Child (Grandparent.all, Parent);
      Add_Child (Parent.all, Child);
      Set_Disabled (Grandparent.all);
      Assert (Is_Disabled (Child.all),
              "Grandchild should be disabled when grandparent is disabled");
   end Test_Grandparent_Disabled;

   procedure Test_Child_Own_Flag_Preserved is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child  : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
   begin
      Put_Line ("Test: Child explicitly disabled stays disabled when parent enabled");
      Add_Child (Parent.all, Child);
      Set_Disabled (Child.all);
      Assert (Is_Disabled (Child.all), "Child should be disabled (own flag)");
      --  Parent is enabled, child should stay disabled via own flag
      Assert (not Has_State (Parent.all, State_Disabled),
              "Parent should be enabled");
      Assert (Is_Disabled (Child.all),
              "Child should remain disabled via own flag");
   end Test_Child_Own_Flag_Preserved;

   procedure Test_Child_Own_Flag_After_Parent_Toggle is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child  : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
   begin
      Put_Line ("Test: Child disabled + parent disabled then enabled -> child stays disabled");
      Add_Child (Parent.all, Child);
      Set_Disabled (Child.all);
      Set_Disabled (Parent.all);
      Assert (Is_Disabled (Child.all), "Both disabled -> child disabled");
      Set_Disabled (Parent.all, False);
      Assert (Is_Disabled (Child.all),
              "Child should stay disabled via own flag after parent re-enabled");
   end Test_Child_Own_Flag_After_Parent_Toggle;

   procedure Test_Focus_Candidate_Parent_Disabled is
      Parent : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child  : constant Adi.Widget.Button.Button_Widget_Access :=
        Adi.Widget.Button.Create ("Child");
   begin
      Put_Line ("Test: Parent disabled -> child is not a focus candidate");
      Add_Child (Parent.all, Child);
      Assert (Is_Focus_Candidate (Widget_Access (Child)),
              "Child should be focus candidate when parent enabled");
      Set_Disabled (Parent.all);
      Assert (not Is_Focus_Candidate (Widget_Access (Child)),
              "Child should not be focus candidate when parent disabled");
   end Test_Focus_Candidate_Parent_Disabled;

begin
   Put_Line ("========================================");
   Put_Line ("   Disabled State Tests");
   Put_Line ("========================================");
   New_Line;

   Test_Disabled_Default;
   Test_Set_Disabled_True;
   Test_Set_Disabled_False;
   New_Line;

   Test_Focus_Candidate_Enabled_Button;
   Test_Focus_Candidate_Disabled_Button;
   Test_Focus_Candidate_Reenabled_Button;
   Test_Focus_Candidate_Non_Focusable;
   Test_Focus_Candidate_Null;
   New_Line;

   Test_Disabled_Text_Input;
   Test_Disabled_Preserves_Other_States;
   Test_Disabled_Invisible_Not_Candidate;
   Test_Display_None_Not_Candidate;
   Test_Visibility_Hidden_Not_Candidate;
   Test_Visibility_Collapse_Not_Candidate;
   Test_Visibility_Override_Is_Candidate;
   New_Line;

   Test_Parent_Disabled_Child_Is_Disabled;
   Test_Parent_Disabled_Child_Get_States;
   Test_Parent_Reenabled_Child_Enabled;
   Test_Grandparent_Disabled;
   Test_Child_Own_Flag_Preserved;
   Test_Child_Own_Flag_After_Parent_Toggle;
   Test_Focus_Candidate_Parent_Disabled;
   New_Line;

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
end Disabled_Test;
