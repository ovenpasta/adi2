pragma Ada_2022;

with Ada.Characters.Latin_1;
with Ada.Environment_Variables;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Text_IO;             use Ada.Text_IO;
with Interfaces.C;            use Interfaces.C;
with Adi.Core;                use Adi.Core;
with Adi.CSS_Source;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.SDL;                 use Adi.SDL;
with Adi.SDL.Events;          use Adi.SDL.Events;
with Adi.SDL.TTF;
with Adi.SDL.Video;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Button;
with Adi.Widget.Box;
with Adi.Widget.Dialog;
with Adi.Widget.Label;
with Adi.Widget.Stack;
with Adi.Widget.Text_Editor;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Adi.Window;

procedure Window_Resize_Safety_Test is
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Dialog.Dialog_Handle;
   use type Adi.Widget.Text_Editor.Text_Editor_Handle;

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

   procedure Write_Text_File (Path : String; Content : String) is
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   end Write_Text_File;

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok : Adi.SDL.C_bool;
      Ttf_Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init(video|events) should succeed");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ttf_Ok);
         Assert (Ready, "TTF_Init should succeed");
      end if;
   end Ensure_SDL_Initialized;

   procedure Test_Zero_Height_Render_Does_Not_Raise is
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ready : Boolean := False;
      Main_Rules : constant Style_Rules :=
        (Background_Color => Set_Bg (RGB (40, 140, 90)),
         Border_Radius    => Set (Radius (Px (18.0))),
         Border_Width     => Set (Border_Width (Px (3.0))),
         Border_Color     => Set (Border_Color (RGB (20, 90, 60))),
         others           => <>);
   begin
      Put_Line ("Test: zero-height window render with rounded corners is safe");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Main_Rules).Build);

      W := Adi.Window.Create_Window_Handle ("Window Resize Safety", (320.0, 240.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, +Root);

      --  Baseline render.
      Adi.Window.Render (W);

      --  Regression case: zero-height geometry must not trigger range checks
      --  in rounded rendering paths.
      Adi.Window.Handle_Resize (W, (Width => 320.0, Height => 0.0));
      Adi.Window.Render (W);

      --  Fully degenerate geometry.
      Adi.Window.Handle_Resize (W, (Width => 0.0, Height => 0.0));
      Adi.Window.Render (W);

      --  Recover to non-zero size and render again.
      Adi.Window.Handle_Resize (W, (Width => 320.0, Height => 1.0));
      Adi.Window.Render (W);

      Assert (True, "Render path survives zero-height resize without exception");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Zero_Height_Render_Does_Not_Raise;

   procedure Test_Text_Editor_Page_Navigation_Zero_Viewport_Does_Not_Raise is
      Ready : Boolean := False;
      Editor : constant Adi.Widget.Text_Editor.Text_Editor_Handle :=
        Adi.Widget.Text_Editor.Create_Handle
          ("line 1" & Ada.Characters.Latin_1.LF
           & "line 2" & Ada.Characters.Latin_1.LF
           & "line 3");
   begin
      Put_Line ("Test: text editor page navigation is safe at zero/near-zero viewport");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      --  Establish line-skip metrics first, then force tiny/zero viewport.
      Set_Geometry
        (+Editor, (X => 0.0, Y => 0.0, Width => 280.0, Height => 120.0));
      Layout_Tree (+Editor);

      Set_Geometry
        (+Editor, (X => 0.0, Y => 0.0, Width => 280.0, Height => 0.0));
      Layout_Tree (+Editor);
      On_Key_Down
        (+Editor, SDL_SCANCODE_PAGEUP, SDL_Keymod (0), False);
      On_Key_Down
        (+Editor,
         SDL_SCANCODE_PAGEDOWN,
         SDL_Keymod (0),
         False);

      Set_Geometry
        (+Editor, (X => 0.0, Y => 0.0, Width => 280.0, Height => 1.0));
      Layout_Tree (+Editor);
      On_Key_Down
        (+Editor, SDL_SCANCODE_PAGEUP, SDL_Keymod (0), False);
      On_Key_Down
        (+Editor,
         SDL_SCANCODE_PAGEDOWN,
         SDL_Keymod (0),
         False);

      Assert (True, "PageUp/PageDown do not raise for zero/near-zero viewport");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Text_Editor_Page_Navigation_Zero_Viewport_Does_Not_Raise;

   procedure Test_Window_Min_Width_Updates_On_Live_Font_Reload is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Lbl : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Minimum width live reload probe");
      Source : Adi.CSS_Source.Style_Source;
      OK : Boolean := False;
      Reloaded : Boolean := False;
      Tick_OK : Boolean := False;
      Min_W_1 : aliased int := 0;
      Min_H_1 : aliased int := 0;
      Min_W_2 : aliased int := 0;
      Min_H_2 : aliased int := 0;
      Min_W_3 : aliased int := 0;
      Min_H_3 : aliased int := 0;
      Got_Min : Adi.SDL.C_bool;
      Css_Path : constant String := "/tmp/adi_window_min_font_reload.css";
      Css_V1 : constant String := ".probe { font-size: 12px; }" & ASCII.LF;
      Css_V2 : constant String := ".probe { font-size: 30px; }" & ASCII.LF;
      Css_V3 : constant String := ".probe { font-size: 10px; }" & ASCII.LF;
   begin
      Put_Line ("Test: window minimum width updates after live font-size reload");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Add_Child (+Root, +Lbl);

      Write_Text_File (Css_Path, Css_V1);
      Adi.CSS_Source.Add_Dynamic_File (Source, Css_Path, OK);
      Assert (OK, "Add_Dynamic_File should succeed");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Set_Mode dynamic should succeed");
      Adi.CSS_Source.Bind_Class (Source, "probe", +Lbl);

      W := Adi.Window.Create_Window_Handle ("Window Min Reload", (420.0, 180.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, True);
      Adi.Window.Set_Root (W, +Root);
      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_1'Access, Min_H_1'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (baseline)");

      delay 1.1;
      Write_Text_File (Css_Path, Css_V2);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Tick should succeed after css update");
      Assert (Reloaded, "Tick should report reload after css update");
      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_2'Access, Min_H_2'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (reloaded)");
      Assert (Min_W_2 > 0, "Window minimum width should stay positive after reload");

      delay 1.1;
      Write_Text_File (Css_Path, Css_V3);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Tick should succeed after css downsize update");
      Assert (Reloaded, "Tick should report reload after css downsize update");
      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_3'Access, Min_H_3'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (downsized)");
      Assert (Min_W_3 > 0, "Window minimum width should stay positive after downsize");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Window_Min_Width_Updates_On_Live_Font_Reload;

   procedure Test_Wrap_Label_Min_Width_Does_Not_Ratchet_With_Window_Width is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Red Page");
      Lbl : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("This wrapping probe text should not force window min width to "
           & "track the current window width after resizing.");
      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Gap            => Set (Gap (Px (8.0))),
         Padding        => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
         others         => <>);
      Title_Main_Rules : constant Style_Rules :=
        (Display     => Set (Inline_Flex),
         Flex_Shrink => Set (0.0),
         others      => <>);
      Title_Label_Rules : constant Style_Rules :=
        (Font_Size   => Set_Font (Px (24.0)),
         Font_Weight => Set (Weight_Bold),
         others      => <>);
      Label_Main_Rules : constant Style_Rules :=
        (Display => Set (Inline_Flex),
         others  => <>);
      Label_Rules : constant Style_Rules :=
        (Font_Size => Set_Font (Px (111.0)),
         others    => <>);
      Min_W_1 : aliased int := 0;
      Min_H_1 : aliased int := 0;
      Min_W_2 : aliased int := 0;
      Min_H_2 : aliased int := 0;
      Cur_W : aliased int := 0;
      Cur_H : aliased int := 0;
      Got_Min : Adi.SDL.C_bool;
      Got_Size : Adi.SDL.C_bool;
   begin
      Put_Line ("Test: wrapped label min width does not ratchet with window width");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Title, Main_Part, From (Title_Main_Rules).Build);
      Set_Part_Style (+Title, Label_Part, From (Title_Label_Rules).Build);
      Set_Part_Style (+Lbl, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (+Lbl, Label_Part, From (Label_Rules).Build);
      Add_Child (+Root, +Title);
      Add_Child (+Root, +Lbl);

      W := Adi.Window.Create_Window_Handle ("Wrap Ratchet Probe", (900.0, 420.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, True);
      Adi.Window.Set_Root (W, +Root);

      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_1'Access, Min_H_1'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (initial)");
      Got_Size := Adi.SDL.Video.SDL_GetWindowSize
        (Adi.Window.Get_SDL_Window (W), Cur_W'Access, Cur_H'Access);
      Assert (Boolean (Got_Size), "SDL_GetWindowSize should succeed (initial)");
      Assert
        (Min_W_1 <= Cur_W - 50,
         "Wrapped text should not lock startup min width to current window width");

      --  Simulate widening. First render is resize-triggered (min update skipped).
      Adi.Window.Handle_Resize (W, (Width => 1300.0, Height => 420.0));
      Adi.Window.Render (W);

      --  Simulate a normal post-resize dirty frame (hover/state update, etc.).
      --  This is where min-size reapplication can ratchet if width-dependent.
      Mark_Dirty (+Root);
      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_2'Access, Min_H_2'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (after widen)");
      Assert
        (Min_W_2 <= Min_W_1 + 2,
         "Wrapped text min width should not ratchet upward with current window width");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Wrap_Label_Min_Width_Does_Not_Ratchet_With_Window_Width;

   procedure Test_Hidden_Page_Activation_Does_Not_Lock_Window_Min_Width is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Page : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Lbl : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a "
           & "a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a");
      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Padding        => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
         others         => <>);
      Page_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Gap            => Set (Gap (Px (8.0))),
         others         => <>);
      Label_Main_Rules : constant Style_Rules :=
        (Display => Set (Inline_Flex),
         others  => <>);
      Label_Rules : constant Style_Rules :=
        (Font_Size => Set_Font (Px (111.0)),
         others    => <>);
      Min_W_Before : aliased int := 0;
      Min_H_Before : aliased int := 0;
      Min_W_After  : aliased int := 0;
      Min_H_After  : aliased int := 0;
      Cur_W        : aliased int := 0;
      Cur_H        : aliased int := 0;
      Got_Min      : Adi.SDL.C_bool;
      Got_Size     : Adi.SDL.C_bool;
   begin
      Put_Line ("Test: hidden page activation should not lock window min width");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Page, Main_Part, From (Page_Rules).Build);
      Set_Part_Style (+Lbl, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (+Lbl, Label_Part, From (Label_Rules).Build);

      Add_Child (+Page, +Lbl);
      Add_Child (+Root, +Page);
      Set_Flag (+Page, Visible, False);

      W := Adi.Window.Create_Window_Handle ("Hidden Activation Probe", (900.0, 420.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, True);
      Adi.Window.Set_Root (W, +Root);
      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_Before'Access, Min_H_Before'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (before show)");

      Set_Flag (+Page, Visible, True);
      Mark_Dirty (+Root);
      Adi.Window.Render (W);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_After'Access, Min_H_After'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (after show)");

      Got_Size := Adi.SDL.Video.SDL_GetWindowSize
        (Adi.Window.Get_SDL_Window (W), Cur_W'Access, Cur_H'Access);
      Assert (Boolean (Got_Size), "SDL_GetWindowSize should succeed (after show)");
      Assert
        (Min_W_After <= Cur_W - 50,
         "Showing hidden wrapped content should not lock min width to current width");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Hidden_Page_Activation_Does_Not_Lock_Window_Min_Width;

   procedure Test_Widening_Unwraps_Text_And_Lowers_Min_Height is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Lbl : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("This text is intentionally long so wrapping increases the "
           & "required height at narrow widths and should shrink when widened.");
      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Padding        => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
         others         => <>);
      Label_Main_Rules : constant Style_Rules :=
        (Display => Set (Inline_Flex),
         others  => <>);
      Label_Rules : constant Style_Rules :=
        (Font_Size => Set_Font (Px (64.0)),
         others    => <>);
      Min_W_Narrow : aliased int := 0;
      Min_H_Narrow : aliased int := 0;
      Min_W_Wide   : aliased int := 0;
      Min_H_Wide   : aliased int := 0;
      Got_Min      : Adi.SDL.C_bool;
   begin
      Put_Line ("Test: widening wrapped text lowers window minimum height");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Lbl, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (+Lbl, Label_Part, From (Label_Rules).Build);
      Add_Child (+Root, +Lbl);

      W := Adi.Window.Create_Window_Handle ("Unwrap Height Probe", (520.0, 900.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, True);
      Adi.Window.Set_Root (W, +Root);

      --  Narrow width => more wrapping => higher min height.
      Adi.Window.Handle_Resize (W, (Width => 420.0, Height => 900.0));
      Adi.Window.Render (W);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_Narrow'Access, Min_H_Narrow'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (narrow)");

      --  Wider width => less wrapping => lower/equal min height.
      Adi.Window.Handle_Resize (W, (Width => 1200.0, Height => 900.0));
      Adi.Window.Render (W);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_Wide'Access, Min_H_Wide'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (wide)");
      Assert
        (Min_H_Wide <= Min_H_Narrow,
         "Window minimum height should decrease or stay equal after widening");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Widening_Unwraps_Text_And_Lowers_Min_Height;

   procedure Test_Dialog_Overlay_Reflows_On_Resize_Without_Hover is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Dlg : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
      Panel_H  : Widget_Handle := Null_Handle;
      Before_W : Pixel_Type := 0.0;
      After_W  : Pixel_Type := 0.0;
      Long_Msg : constant String :=
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW";
   begin
      Put_Line ("Test: dialog overlay reflows on resize without hover");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("Dialog Resize Probe", (900.0, 420.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, +Root);

      Adi.Widget.Dialog.Attach_Window (Dlg, W);
      Adi.Widget.Dialog.Set_Title (Dlg, "Resize Probe");
      Adi.Widget.Dialog.Set_Message (Dlg, Long_Msg);
      Adi.Widget.Dialog.Set_OK_Button (Dlg);
      Adi.Widget.Dialog.Show (Dlg);

      Adi.Window.Render (W);

      Panel_H := Get_Child_Handle (+Dlg, 1);
      Assert (Panel_H /= Null_Handle, "Dialog content panel should exist");
      if Panel_H = Null_Handle then
         return;
      end if;

      Before_W := Get_Geometry (Panel_H).Width;
      Assert (Before_W > 0.0, "Dialog panel width should be initialized");

      --  Resize and render once. Regression: panel used to reflow only after
      --  a later hover/state dirtied frame.
      Adi.Window.Handle_Resize (W, (Width => 520.0, Height => 420.0));
      Adi.Window.Render (W);

      After_W := Get_Geometry (Panel_H).Width;
      Assert
        (After_W < Before_W - 1.0,
         "Dialog panel should reflow immediately on resize (no hover needed)");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Dialog_Overlay_Reflows_On_Resize_Without_Hover;

   procedure Test_Dialog_Default_Button_Demotion_Resets_Style is
      Ready : Boolean := False;
      Dlg : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
      Btn_1 : Adi.Widget.Button.Button_Handle;
      Btn_2 : Adi.Widget.Button.Button_Handle;
      Primary_Color : constant Color_Value := RGB (250, 10, 10);
      Primary_Main_Rules : constant Style_Rules :=
        (Background_Color => Set_Bg (Primary_Color),
         others           => <>);
      Primary_Styles : constant Part_Style_Array := [
        Main_Part => (Style => From (Primary_Main_Rules).Build, Enabled => True),
        others => <>];
      Style_1 : Resolved_Style;
      Style_2 : Resolved_Style;
   begin
      Put_Line ("Test: default-button demotion reapplies normal style");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      --  Ensure no package-level normal/primary style masks this regression.
      Adi.Widget.Dialog.Set_Default_Button_Style (Empty_Part_Styles);
      Adi.Widget.Dialog.Set_Default_Primary_Button_Style (Empty_Part_Styles);

      Adi.Widget.Dialog.Add_Button (Dlg, "A");
      Adi.Widget.Dialog.Add_Button (Dlg, "B");
      Adi.Widget.Dialog.Set_Primary_Button_Style (Dlg, Primary_Styles);
      Adi.Widget.Dialog.Set_Default_Button (Dlg, 1);

      Btn_1 := Adi.Widget.Dialog.Get_Button_Handle (Dlg, 1);
      Btn_2 := Adi.Widget.Dialog.Get_Button_Handle (Dlg, 2);
      Assert
        (Adi.Widget.Button.Is_Valid (Btn_1)
         and then Adi.Widget.Button.Is_Valid (Btn_2),
         "Dialog buttons should exist");
      if not Adi.Widget.Button.Is_Valid (Btn_1)
        or else not Adi.Widget.Button.Is_Valid (Btn_2)
      then
         return;
      end if;

      Style_1 := Get_Resolved_Part_Style (+Btn_1, Main_Part);
      Assert
        (Style_1.Background_Color = Primary_Color,
         "Initial default button should receive primary style");

      Adi.Widget.Dialog.Set_Default_Button (Dlg, 2);
      Style_1 := Get_Resolved_Part_Style (+Btn_1, Main_Part);
      Style_2 := Get_Resolved_Part_Style (+Btn_2, Main_Part);

      Assert
        (Style_1.Background_Color /= Primary_Color,
         "Demoted button should no longer retain primary style");
      Assert
        (Style_2.Background_Color = Primary_Color,
         "New default button should receive primary style");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Dialog_Default_Button_Demotion_Resets_Style;

   procedure Test_Clear_Overlays_Clears_Focus_When_Focus_In_Overlay is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Dlg : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
      Btn_1 : Adi.Widget.Button.Button_Handle;
   begin
      Put_Line ("Test: Clear_Overlays clears focus from overlay widgets");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("Dialog Focus Cleanup Probe", (640.0, 360.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, +Root);

      Adi.Widget.Dialog.Attach_Window (Dlg, W);
      Adi.Widget.Dialog.Set_OK_Button (Dlg);
      Adi.Widget.Dialog.Show (Dlg);

      Btn_1 := Adi.Widget.Dialog.Get_Button_Handle (Dlg, 1);
      Assert (Adi.Widget.Button.Is_Valid (Btn_1), "Dialog default button should exist");
      if not Adi.Widget.Button.Is_Valid (Btn_1) then
         return;
      end if;

      Assert
        (Has_State (+Btn_1, State_Focused),
         "Default button should be focused before Clear_Overlays");

      Adi.Window.Clear_Overlays (W);

      Assert
        (not Has_State (+Btn_1, State_Focused),
         "Clear_Overlays should clear focused state on detached overlay button");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Clear_Overlays_Clears_Focus_When_Focus_In_Overlay;

   procedure Test_Show_Autofocus_Default_And_Override is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Dlg : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
      Btn_1 : Adi.Widget.Button.Button_Handle;
      Btn_2 : Adi.Widget.Button.Button_Handle;
      Last_Index : Natural := 0;

      procedure On_Result
        (WH           : Widget_Handle;
         Button_Index : Natural;
         Button_Text  : String)
      is
         pragma Unreferenced (WH, Button_Text);
      begin
         Last_Index := Button_Index;
      end On_Result;
   begin
      Put_Line ("Test: Show autofocuses default button and supports focus override");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("Dialog Enter Probe", (640.0, 360.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, +Root);

      Adi.Widget.Dialog.Attach_Window (Dlg, W);
      Adi.Widget.Dialog.Set_OK_Cancel (Dlg);  --  default index = 2 (OK)
      Adi.Widget.Dialog.Connect_Result (Dlg, On_Result'Unrestricted_Access);

      Btn_1 := Adi.Widget.Dialog.Get_Button_Handle (Dlg, 1);
      Btn_2 := Adi.Widget.Dialog.Get_Button_Handle (Dlg, 2);
      Assert
        (Adi.Widget.Button.Is_Valid (Btn_1)
         and then Adi.Widget.Button.Is_Valid (Btn_2),
         "Dialog buttons should exist");
      if not Adi.Widget.Button.Is_Valid (Btn_1)
        or else not Adi.Widget.Button.Is_Valid (Btn_2)
      then
         return;
      end if;

      --  First show: Enter should activate default button (index 2).
      Last_Index := 0;
      Adi.Widget.Dialog.Show (Dlg);
      Assert
        (Has_State (+Btn_2, State_Focused),
         "Show should autofocus default button");
      Adi.Window.On_Key_Down (W, SDL_SCANCODE_RETURN, 0, SDL_Keymod (0), False);
      Adi.Window.On_Key_Up (W, SDL_SCANCODE_RETURN, SDL_Keymod (0), False);
      Assert
        (Last_Index = 2,
         "Enter should activate default button immediately after Show");

      --  Second show: explicit focus override should change Enter target.
      Last_Index := 0;
      Adi.Widget.Dialog.Show (Dlg);
      Adi.Window.Set_Focus (W, +Btn_1);
      Assert
        (Has_State (+Btn_1, State_Focused),
         "Explicit Set_Focus should override initial default focus");
      Adi.Window.On_Key_Down (W, SDL_SCANCODE_RETURN, 0, SDL_Keymod (0), False);
      Adi.Window.On_Key_Up (W, SDL_SCANCODE_RETURN, SDL_Keymod (0), False);
      Assert
        (Last_Index = 1,
         "Enter should activate override-focused non-default button");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Show_Autofocus_Default_And_Override;

   procedure Test_Wheel_Blocked_By_Overlay_Backdrop is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      --  Tall child to ensure root can scroll.
      Tall_Child : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Dlg : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
         others         => <>);
      Child_Rules : constant Style_Rules :=
        (Min_Height => Set (Size (Px (2000.0))),
         others     => <>);
      Offset_Before : Pixel_Type := 0.0;
      Offset_After  : Pixel_Type := 0.0;
   begin
      Put_Line ("Test: wheel events are blocked by overlay backdrop");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Tall_Child, Main_Part, From (Child_Rules).Build);
      Add_Child (+Root, +Tall_Child);

      W := Adi.Window.Create_Window_Handle ("Overlay Wheel Block Probe", (320.0, 240.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, +Root);
      Adi.Window.Render (W);

      --  Verify wheel scrolls root when no overlay is present.
      Adi.Window.On_Mouse_Wheel (W, 160.0, 120.0, 0.0, -30.0);
      Assert
        (Get_Scroll_Offset_Y (+Root) > 0.0,
         "Root should scroll without overlay");

      --  Reset scroll position.
      Set_Scroll_Offset_Y (+Root, 0.0);

      --  Show dialog overlay and render so it gets laid out.
      Adi.Widget.Dialog.Attach_Window (Dlg, W);
      Adi.Widget.Dialog.Set_Title (Dlg, "Probe");
      Adi.Widget.Dialog.Set_Message (Dlg, "blocking");
      Adi.Widget.Dialog.Set_OK_Button (Dlg);
      Adi.Widget.Dialog.Show (Dlg);
      Adi.Window.Render (W);

      --  Send wheel event at a point over the overlay backdrop (top-left
      --  corner, which is outside the centered dialog panel).
      Offset_Before := Get_Scroll_Offset_Y (+Root);
      Adi.Window.On_Mouse_Wheel (W, 5.0, 5.0, 0.0, -30.0);
      Offset_After := Get_Scroll_Offset_Y (+Root);

      Assert
        (Offset_After = Offset_Before,
         "Root scroll should not change while overlay backdrop is shown");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Wheel_Blocked_By_Overlay_Backdrop;

   procedure Test_Wheel_Root_Works_Without_Overlay is
      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Tall_Child : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
         others         => <>);
      Child_Rules : constant Style_Rules :=
        (Min_Height => Set (Size (Px (2000.0))),
         others     => <>);
   begin
      Put_Line ("Test: wheel events reach root when no overlay is present (no regression)");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Tall_Child, Main_Part, From (Child_Rules).Build);
      Add_Child (+Root, +Tall_Child);

      W := Adi.Window.Create_Window_Handle ("No Overlay Wheel Probe", (320.0, 240.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, +Root);
      Adi.Window.Render (W);

      Assert
        (Get_Scroll_Offset_Y (+Root) = 0.0,
         "Root scroll offset should start at 0");

      Adi.Window.On_Mouse_Wheel (W, 160.0, 120.0, 0.0, -30.0);

      Assert
        (Get_Scroll_Offset_Y (+Root) > 0.0,
         "Root should scroll after wheel event without overlay");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Wheel_Root_Works_Without_Overlay;

   procedure Test_Stack_Page_Switch_Does_Not_Ratchet_Min_Size is
      type Page_Id is (Red_Page, Green_Page);
      package Probe_Stack is new Adi.Widget.Stack (Page_Id);
      use type Probe_Stack.Stack_Handle;

      Ready : Boolean := False;
      W : Adi.Window.Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Stack : constant Probe_Stack.Stack_Handle :=
        Probe_Stack.Create_Handle;

      Red_Box : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Red_Label : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Red");

      Green_Box : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Green_Label : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("This is the second page with a natural green background.");

      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Padding        => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
         others         => <>);
      Stack_Rules : constant Style_Rules :=
        (Display => Set (Flex),
         others  => <>);
      Page_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Padding        => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
         Gap            => Set (Gap (Px (8.0))),
         others         => <>);
      Label_Main_Rules : constant Style_Rules :=
        (Display => Set (Inline_Flex),
         others  => <>);
      Green_Label_Rules : constant Style_Rules :=
        (Font_Size => Set_Font (Px (111.0)),
         others    => <>);

      Min_W_Narrow : aliased int := 0;
      Min_H_Narrow : aliased int := 0;
      Min_W_Wide   : aliased int := 0;
      Min_H_Wide   : aliased int := 0;
      Cur_W        : aliased int := 0;
      Cur_H        : aliased int := 0;
      Got_Min      : Adi.SDL.C_bool;
      Got_Size     : Adi.SDL.C_bool;
   begin
      Put_Line ("Test: stack page switch should not ratchet min size on resize");

      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Stack, Main_Part, From (Stack_Rules).Build);

      Set_Part_Style (+Red_Box, Main_Part, From (Page_Rules).Build);
      Set_Part_Style (+Red_Label, Main_Part, From (Label_Main_Rules).Build);
      Add_Child (+Red_Box, +Red_Label);

      Set_Part_Style (+Green_Box, Main_Part, From (Page_Rules).Build);
      Set_Part_Style (+Green_Label, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (+Green_Label, Label_Part, From (Green_Label_Rules).Build);
      Add_Child (+Green_Box, +Green_Label);

      Probe_Stack.Add_Page (Stack, Red_Page, +Red_Box);
      Probe_Stack.Add_Page (Stack, Green_Page, +Green_Box);
      Add_Child (+Root, +Stack);

      W := Adi.Window.Create_Window_Handle ("Stack Ratchet Probe", (900.0, 700.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, True);
      Adi.Window.Set_Root (W, +Root);
      Adi.Window.Render (W);

      Probe_Stack.Set_Active (Stack, Green_Page);
      Mark_Dirty (+Root);
      Adi.Window.Render (W);

      --  Narrow width: wrapped text grows vertically.
      Adi.Window.Handle_Resize (W, (Width => 650.0, Height => 1200.0));
      Adi.Window.Render (W);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_Narrow'Access, Min_H_Narrow'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (stack narrow)");

      --  Widen: text unwraps; min-height should reduce, and not lock to current.
      Adi.Window.Handle_Resize (W, (Width => 1300.0, Height => 1200.0));
      Adi.Window.Render (W);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W), Min_W_Wide'Access, Min_H_Wide'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (stack wide)");
      Assert
        (Min_H_Wide <= Min_H_Narrow,
         "Stack min height should decrease or stay equal after widening active page");

      Got_Size := Adi.SDL.Video.SDL_GetWindowSize
        (Adi.Window.Get_SDL_Window (W), Cur_W'Access, Cur_H'Access);
      Assert (Boolean (Got_Size), "SDL_GetWindowSize should succeed (stack wide)");
      Assert
        (Min_H_Wide <= Cur_H - 50,
         "Stack min height should not ratchet to current window height");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Stack_Page_Switch_Does_Not_Ratchet_Min_Size;

begin
   Put_Line ("========================================");
   Put_Line ("   Window Resize Safety Tests");
   Put_Line ("========================================");
   New_Line;

   Test_Zero_Height_Render_Does_Not_Raise;
   Test_Text_Editor_Page_Navigation_Zero_Viewport_Does_Not_Raise;
   Test_Window_Min_Width_Updates_On_Live_Font_Reload;
   Test_Wrap_Label_Min_Width_Does_Not_Ratchet_With_Window_Width;
   Test_Hidden_Page_Activation_Does_Not_Lock_Window_Min_Width;
   Test_Widening_Unwraps_Text_And_Lowers_Min_Height;
   Test_Dialog_Overlay_Reflows_On_Resize_Without_Hover;
   Test_Dialog_Default_Button_Demotion_Resets_Style;
   Test_Clear_Overlays_Clears_Focus_When_Focus_In_Overlay;
   Test_Show_Autofocus_Default_And_Override;
   Test_Wheel_Blocked_By_Overlay_Backdrop;
   Test_Wheel_Root_Works_Without_Overlay;
   Test_Stack_Page_Switch_Does_Not_Ratchet_Min_Size;
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
end Window_Resize_Safety_Test;
