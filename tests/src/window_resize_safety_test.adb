pragma Ada_2022;

with Ada.Characters.Latin_1;
with Ada.Environment_Variables;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Text_IO;             use Ada.Text_IO;
with Interfaces.C;            use Interfaces.C;
with Adi.CSS_Source;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.SDL;                 use Adi.SDL;
with Adi.SDL.Events;          use Adi.SDL.Events;
with Adi.SDL.TTF;
with Adi.SDL.Video;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Stack;
with Adi.Widget.Text_Editor;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Adi.Window;

procedure Window_Resize_Safety_Test is
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
      W : Adi.Window.Window_Access := null;
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
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

      Set_Part_Style (Root.all, Main_Part, From (Main_Rules).Build);

      W := Adi.Window.Create_Window ("Window Resize Safety", (320.0, 240.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W.all, False);
      Adi.Window.Set_Root (W.all, Root);

      --  Baseline render.
      Adi.Window.Render (W.all);

      --  Regression case: zero-height geometry must not trigger range checks
      --  in rounded rendering paths.
      Adi.Window.Handle_Resize (W.all, (Width => 320.0, Height => 0.0));
      Adi.Window.Render (W.all);

      --  Fully degenerate geometry.
      Adi.Window.Handle_Resize (W.all, (Width => 0.0, Height => 0.0));
      Adi.Window.Render (W.all);

      --  Recover to non-zero size and render again.
      Adi.Window.Handle_Resize (W.all, (Width => 320.0, Height => 1.0));
      Adi.Window.Render (W.all);

      Assert (True, "Render path survives zero-height resize without exception");
   exception
      when E : others =>
         Assert
           (False,
            "Unexpected exception: " & Exception_Name (E));
   end Test_Zero_Height_Render_Does_Not_Raise;

   procedure Test_Text_Editor_Page_Navigation_Zero_Viewport_Does_Not_Raise is
      Ready : Boolean := False;
      Editor : constant Adi.Widget.Text_Editor.Text_Editor_Widget_Access :=
        Adi.Widget.Text_Editor.Create
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
        (Editor.all, (X => 0.0, Y => 0.0, Width => 280.0, Height => 120.0));
      Layout_Tree (Editor.all);

      Set_Geometry
        (Editor.all, (X => 0.0, Y => 0.0, Width => 280.0, Height => 0.0));
      Layout_Tree (Editor.all);
      On_Key_Down
        (Widget'Class (Editor.all), SDL_SCANCODE_PAGEUP, SDL_Keymod (0), False);
      On_Key_Down
        (Widget'Class (Editor.all),
         SDL_SCANCODE_PAGEDOWN,
         SDL_Keymod (0),
         False);

      Set_Geometry
        (Editor.all, (X => 0.0, Y => 0.0, Width => 280.0, Height => 1.0));
      Layout_Tree (Editor.all);
      On_Key_Down
        (Widget'Class (Editor.all), SDL_SCANCODE_PAGEUP, SDL_Keymod (0), False);
      On_Key_Down
        (Widget'Class (Editor.all),
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
      W : Adi.Window.Window_Access := null;
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Lbl : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Minimum width live reload probe");
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

      Root.Add_Child (Lbl);

      Write_Text_File (Css_Path, Css_V1);
      Adi.CSS_Source.Add_Dynamic_File (Source, Css_Path, OK);
      Assert (OK, "Add_Dynamic_File should succeed");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "Set_Mode dynamic should succeed");
      Adi.CSS_Source.Bind_Class (Source, "probe", Lbl);

      W := Adi.Window.Create_Window ("Window Min Reload", (420.0, 180.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W.all, True);
      Adi.Window.Set_Root (W.all, Root);
      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_1'Access, Min_H_1'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (baseline)");

      delay 1.1;
      Write_Text_File (Css_Path, Css_V2);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Tick should succeed after css update");
      Assert (Reloaded, "Tick should report reload after css update");
      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_2'Access, Min_H_2'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (reloaded)");
      Assert (Min_W_2 > 0, "Window minimum width should stay positive after reload");

      delay 1.1;
      Write_Text_File (Css_Path, Css_V3);
      Adi.CSS_Source.Tick (Source, Reloaded, Tick_OK);
      Assert (Tick_OK, "Tick should succeed after css downsize update");
      Assert (Reloaded, "Tick should report reload after css downsize update");
      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_3'Access, Min_H_3'Access);
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
      W : Adi.Window.Window_Access := null;
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Red Page");
      Lbl : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
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

      Set_Part_Style (Root.all, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (Title.all, Main_Part, From (Title_Main_Rules).Build);
      Set_Part_Style (Title.all, Label_Part, From (Title_Label_Rules).Build);
      Set_Part_Style (Lbl.all, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (Lbl.all, Label_Part, From (Label_Rules).Build);
      Root.Add_Child (Title);
      Root.Add_Child (Lbl);

      W := Adi.Window.Create_Window ("Wrap Ratchet Probe", (900.0, 420.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W.all, True);
      Adi.Window.Set_Root (W.all, Root);

      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_1'Access, Min_H_1'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (initial)");
      Got_Size := Adi.SDL.Video.SDL_GetWindowSize
        (Adi.Window.Get_SDL_Window (W.all), Cur_W'Access, Cur_H'Access);
      Assert (Boolean (Got_Size), "SDL_GetWindowSize should succeed (initial)");
      Assert
        (Min_W_1 <= Cur_W - 50,
         "Wrapped text should not lock startup min width to current window width");

      --  Simulate widening. First render is resize-triggered (min update skipped).
      Adi.Window.Handle_Resize (W.all, (Width => 1300.0, Height => 420.0));
      Adi.Window.Render (W.all);

      --  Simulate a normal post-resize dirty frame (hover/state update, etc.).
      --  This is where min-size reapplication can ratchet if width-dependent.
      Mark_Dirty (Root.all);
      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_2'Access, Min_H_2'Access);
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
      W : Adi.Window.Window_Access := null;
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Page : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Lbl : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
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

      Set_Part_Style (Root.all, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (Page.all, Main_Part, From (Page_Rules).Build);
      Set_Part_Style (Lbl.all, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (Lbl.all, Label_Part, From (Label_Rules).Build);

      Page.Add_Child (Lbl);
      Root.Add_Child (Page);
      Set_Flag (Page.all, Visible, False);

      W := Adi.Window.Create_Window ("Hidden Activation Probe", (900.0, 420.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W.all, True);
      Adi.Window.Set_Root (W.all, Root);
      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_Before'Access, Min_H_Before'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (before show)");

      Set_Flag (Page.all, Visible, True);
      Mark_Dirty (Root.all);
      Adi.Window.Render (W.all);

      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_After'Access, Min_H_After'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (after show)");

      Got_Size := Adi.SDL.Video.SDL_GetWindowSize
        (Adi.Window.Get_SDL_Window (W.all), Cur_W'Access, Cur_H'Access);
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
      W : Adi.Window.Window_Access := null;
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Lbl : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
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

      Set_Part_Style (Root.all, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (Lbl.all, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (Lbl.all, Label_Part, From (Label_Rules).Build);
      Root.Add_Child (Lbl);

      W := Adi.Window.Create_Window ("Unwrap Height Probe", (520.0, 900.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W.all, True);
      Adi.Window.Set_Root (W.all, Root);

      --  Narrow width => more wrapping => higher min height.
      Adi.Window.Handle_Resize (W.all, (Width => 420.0, Height => 900.0));
      Adi.Window.Render (W.all);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_Narrow'Access, Min_H_Narrow'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (narrow)");

      --  Wider width => less wrapping => lower/equal min height.
      Adi.Window.Handle_Resize (W.all, (Width => 1200.0, Height => 900.0));
      Adi.Window.Render (W.all);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_Wide'Access, Min_H_Wide'Access);
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

   procedure Test_Stack_Page_Switch_Does_Not_Ratchet_Min_Size is
      type Page_Id is (Red_Page, Green_Page);
      package Probe_Stack is new Adi.Widget.Stack (Page_Id);

      Ready : Boolean := False;
      W : Adi.Window.Window_Access := null;
      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Stack : constant Probe_Stack.Stack_Widget_Access :=
        Probe_Stack.Create;

      Red_Box : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Red_Label : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Red");

      Green_Box : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Green_Label : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
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

      Set_Part_Style (Root.all, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (Stack.all, Main_Part, From (Stack_Rules).Build);

      Set_Part_Style (Red_Box.all, Main_Part, From (Page_Rules).Build);
      Set_Part_Style (Red_Label.all, Main_Part, From (Label_Main_Rules).Build);
      Red_Box.Add_Child (Red_Label);

      Set_Part_Style (Green_Box.all, Main_Part, From (Page_Rules).Build);
      Set_Part_Style (Green_Label.all, Main_Part, From (Label_Main_Rules).Build);
      Set_Part_Style (Green_Label.all, Label_Part, From (Green_Label_Rules).Build);
      Green_Box.Add_Child (Green_Label);

      Probe_Stack.Add_Page (Stack.all, Red_Page, Red_Box);
      Probe_Stack.Add_Page (Stack.all, Green_Page, Green_Box);
      Root.Add_Child (Stack);

      W := Adi.Window.Create_Window ("Stack Ratchet Probe", (900.0, 700.0));
      Adi.Window.Set_Enforce_Layout_Min_Size (W.all, True);
      Adi.Window.Set_Root (W.all, Root);
      Adi.Window.Render (W.all);

      Probe_Stack.Set_Active (Stack.all, Green_Page);
      Mark_Dirty (Root.all);
      Adi.Window.Render (W.all);

      --  Narrow width: wrapped text grows vertically.
      Adi.Window.Handle_Resize (W.all, (Width => 650.0, Height => 1200.0));
      Adi.Window.Render (W.all);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_Narrow'Access, Min_H_Narrow'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (stack narrow)");

      --  Widen: text unwraps; min-height should reduce, and not lock to current.
      Adi.Window.Handle_Resize (W.all, (Width => 1300.0, Height => 1200.0));
      Adi.Window.Render (W.all);
      Got_Min := Adi.SDL.Video.SDL_GetWindowMinimumSize
        (Adi.Window.Get_SDL_Window (W.all), Min_W_Wide'Access, Min_H_Wide'Access);
      Assert (Boolean (Got_Min), "SDL_GetWindowMinimumSize should succeed (stack wide)");
      Assert
        (Min_H_Wide <= Min_H_Narrow,
         "Stack min height should decrease or stay equal after widening active page");

      Got_Size := Adi.SDL.Video.SDL_GetWindowSize
        (Adi.Window.Get_SDL_Window (W.all), Cur_W'Access, Cur_H'Access);
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
