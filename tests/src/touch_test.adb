--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.Core;           use Adi.Core;
with Adi.CSS_Styles;     use Adi.CSS_Styles;
with Adi.SDL;            use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Slider;
with Adi.Widget.Text_Editor;
with Adi.Widget.Text_Input;
with Adi.Widget_Styles;  use Adi.Widget_Styles;
with Adi.Window;         use Adi.Window;
with Test_Support;       use Test_Support;

--  Finger input through Adi.Window, under SDL's dummy video driver: taps,
--  drags that scroll, flings, long presses, and widgets that take drags
procedure Touch_Test is

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Text_Input.Text_Input_Handle;
   use type Adi.Widget.Text_Editor.Text_Editor_Handle;

   package Float_Slider is new Adi.Widget.Slider (Float);
   use type Float_Slider.Slider_Handle;

   Clicks        : Natural := 0;
   Context_Menus : Natural := 0;

   procedure Count_Click (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      Clicks := Clicks + 1;
   end Count_Click;

   function Is_Pressed (H : Widget_Handle) return Boolean is
     (Has_State (H, State_Pressed));

   procedure On_Context_Menu (W : Widget_Handle; X, Y : Pixel_Type) is
      pragma Unreferenced (W, X, Y);
   begin
      Context_Menus := Context_Menus + 1;
   end On_Context_Menu;

   --  A 300 x 200 window whose root scrolls a column of ten 80px buttons;
   --  the first is at y 0 .. 80, the second at 80 .. 160
   Win     : Window_Handle;
   Root    : Adi.Widget.Box.Box_Handle;
   Buttons : array (1 .. 10) of Adi.Widget.Button.Button_Handle;

   --  Event times: each test starts its fingers well after the last
   Now : Duration := 0.0;

   procedure Build is
      Root_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Adi.CSS_Styles.Column),
         Overflow_Y     => Set (Overflow_Auto),
         others         => <>);
      Item_Rules : constant Style_Rules :=
        (Height     => Set (Size (Px (80.0))),
         Min_Height => Set (Size (Px (80.0))),
         others     => <>);
   begin
      Root := Adi.Widget.Box.Create_Handle;
      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      for I in Buttons'Range loop
         Buttons (I) := Adi.Widget.Button.Create_Handle ("Item" & I'Image);
         Set_Part_Style (+Buttons (I), Main_Part, From (Item_Rules).Build);
         Adi.Widget.Button.Connect_Clicked
           (Buttons (I), Count_Click'Unrestricted_Access);
         Add_Child (+Root, +Buttons (I));
      end loop;
      Connect_Context_Menu (+Buttons (1), On_Context_Menu'Unrestricted_Access);

      Win := Create_Window_Handle ("Touch", (300.0, 200.0));
      Set_Enforce_Layout_Min_Size (Win, False);
      Set_Root (Win, +Root);
      Render (Win);
   end Build;

   procedure Reset is
   begin
      Set_Scroll_Velocity_Y (+Root, 0.0);
      Set_Scroll_Offset_Y (+Root, 0.0);
      Render (Win);
      Clicks := 0;
      Context_Menus := 0;
      Now := Now + 10.0;
   end Reset;

   --  Advance the clock and the window's timers by Seconds
   procedure Wait (Seconds : Duration) is
   begin
      Now := Now + Seconds;
      Tick (Win, Seconds);
   end Wait;

   --  A finger from Y0 to Y1 at X 150, in Steps moves over Seconds
   procedure Drag
     (Y0, Y1 : Pixel_Type; Steps : Positive; Seconds : Duration;
      Lift   : Boolean := True)
   is
   begin
      On_Finger_Down (Win, 1, 150.0, Y0, Now);
      for K in 1 .. Steps loop
         Now := Now + Seconds / Steps;
         On_Finger_Move
           (Win, 1, 150.0,
            Y0 + (Y1 - Y0) * Pixel_Type (K) / Pixel_Type (Steps), Now);
      end loop;
      if Lift then
         On_Finger_Up (Win, 1, 150.0, Y1, Now);
      end if;
   end Drag;

   procedure Test_Tap is
   begin
      Section ("tap");
      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Assert (not Is_Pressed (+Buttons (1)),
              "not pressed the moment the finger lands");
      On_Finger_Up (Win, 1, 152.0, 43.0, Now + 0.05);
      Assert (Clicks = 1, "a tap clicks");
      Assert (not Is_Pressed (+Buttons (1)), "nothing stays pressed");

      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Tick (Win, 0.0);  --  the frame it lands in
      Wait (0.15);
      Assert (Is_Pressed (+Buttons (1)),
              "pressed once the finger has rested");
      On_Finger_Up (Win, 1, 150.0, 40.0, Now);
      Assert (Clicks = 1, "a slower tap still clicks");
      Assert (not Is_Pressed (+Buttons (1)), "and is released");
   end Test_Tap;

   procedure Test_Drag_Scrolls is
   begin
      Section ("drag");
      Reset;
      Drag (150.0, 50.0, Steps => 10, Seconds => 1.0, Lift => False);
      Assert (Get_Scroll_Offset_Y (+Root) > 80.0,
              "the content follows the finger up");
      Assert (Get_Scroll_Offset_Y (+Root) <= 100.0,
              "by no more than the finger moved");
      --  Held still before lifting
      Now := Now + 0.2;
      On_Finger_Up (Win, 1, 150.0, 50.0, Now);
      Assert (Clicks = 0, "a drag does not click");
      Assert (Get_Scroll_Velocity_Y (+Root) = 0.0,
              "a drag that stops before lifting leaves the content still");

      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Tick (Win, 0.0);  --  the frame it lands in
      Wait (0.15);
      Assert (Is_Pressed (+Buttons (1)), "pressed while resting");
      Now := Now + 0.05;
      On_Finger_Move (Win, 1, 150.0, 10.0, Now);
      Assert (not Is_Pressed (+Buttons (1)),
              "a drag releases the pressed style");
      On_Finger_Up (Win, 1, 150.0, 10.0, Now);
      Assert (Clicks = 0, "and clicks nothing");
   end Test_Drag_Scrolls;

   procedure Test_Fling is
      Offset : Pixel_Type;
   begin
      Section ("fling");
      Reset;
      Drag (180.0, 80.0, Steps => 5, Seconds => 0.05);
      Offset := Get_Scroll_Offset_Y (+Root);
      Assert (Get_Scroll_Velocity_Y (+Root) > 500.0,
              "a quick flick leaves the content moving on");
      Wait (0.05);
      Assert (Get_Scroll_Offset_Y (+Root) > Offset,
              "and it keeps scrolling");

      Offset := Get_Scroll_Offset_Y (+Root);
      On_Finger_Down (Win, 1, 150.0, 100.0, Now);
      Assert (Get_Scroll_Velocity_Y (+Root) = 0.0,
              "a touch stops it");
      On_Finger_Up (Win, 1, 150.0, 100.0, Now + 0.05);
      Assert (Clicks = 0, "without clicking what it lands on");
      Wait (0.05);
      Assert (Get_Scroll_Offset_Y (+Root) = Offset, "and it stays put");
   end Test_Fling;

   procedure Test_Long_Press is
   begin
      Section ("long press");
      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Tick (Win, 0.0);  --  the frame it lands in
      Wait (0.3);
      Assert (Context_Menus = 0, "not yet a long press");
      Wait (0.3);
      Assert (Context_Menus = 1, "a long press opens the context menu");
      Assert (not Is_Pressed (+Buttons (1)), "and releases the press");
      On_Finger_Up (Win, 1, 150.0, 40.0, Now);
      Assert (Clicks = 0, "and does not click");
   end Test_Long_Press;

   procedure Test_Second_Finger is
   begin
      Section ("second finger");
      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      On_Finger_Down (Win, 2, 150.0, 120.0, Now);
      On_Finger_Move (Win, 2, 150.0, 20.0, Now + 0.1);
      On_Finger_Up (Win, 2, 150.0, 20.0, Now + 0.1);
      Assert (Get_Scroll_Offset_Y (+Root) = 0.0,
              "a second finger does not scroll");
      On_Finger_Up (Win, 1, 150.0, 40.0, Now + 0.1);
      Assert (Clicks = 1, "and the first still taps");
   end Test_Second_Finger;

   procedure Test_Cancel is
   begin
      Section ("cancel");
      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Tick (Win, 0.0);  --  the frame it lands in
      Wait (0.15);
      On_Finger_Cancel (Win, 1);
      Assert (not Is_Pressed (+Buttons (1)), "a cancel releases the press");
      On_Finger_Up (Win, 1, 150.0, 40.0, Now);
      Assert (Clicks = 0, "and nothing clicks");
   end Test_Cancel;

   procedure Test_Recovery is
   begin
      Section ("timing and recovery");
      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      --  A frame that stalls as the finger lands
      Wait (0.6);
      Assert (Context_Menus = 0,
              "a frame begun before the finger landed is not a long press");
      On_Finger_Up (Win, 1, 150.0, 40.0, Now);
      Assert (Clicks = 1, "so the touch is still a tap");

      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      On_Finger_Up (Win, 1, 150.0, 140.0, Now + 0.05);
      Assert (Clicks = 0,
              "a lift reported far from where it went down is no tap");

      Reset;
      --  The lift of this one is lost
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Tick (Win, 0.0);
      Wait (0.15);
      On_Finger_Down (Win, 1, 150.0, 120.0, Now);
      Assert (not Is_Pressed (+Buttons (1)),
              "the same finger down again drops the gesture it left");
      On_Finger_Up (Win, 1, 150.0, 120.0, Now + 0.05);
      Assert (Clicks = 1, "and taps anew");

      Reset;
      On_Finger_Down (Win, 1, 150.0, 40.0, Now);
      Tick (Win, 0.0);
      Wait (0.15);
      Cancel_Touch (Win);
      Assert (not Is_Pressed (+Buttons (1)),
              "losing focus releases the press");
      On_Finger_Down (Win, 2, 150.0, 120.0, Now);
      On_Finger_Up (Win, 2, 150.0, 120.0, Now + 0.05);
      Assert (Clicks = 1, "and the next finger is followed");
   end Test_Recovery;

   --  A short scroll container in a long page scrolls nothing, so a
   --  finger on it moves the page, and stops the page
   procedure Test_Nested_Scrollers is
      W     : Window_Handle;
      Page  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Inner : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Scroll_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Adi.CSS_Styles.Column),
         Overflow_Y     => Set (Overflow_Auto),
         others         => <>);
      Inner_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Adi.CSS_Styles.Column),
         Overflow_Y     => Set (Overflow_Auto),
         Height         => Set (Size (Px (80.0))),
         Min_Height     => Set (Size (Px (80.0))),
         others         => <>);
      Item_Rules : constant Style_Rules :=
        (Height     => Set (Size (Px (80.0))),
         Min_Height => Set (Size (Px (80.0))),
         others     => <>);
   begin
      Section ("nested scrollers");
      Set_Part_Style (+Page, Main_Part, From (Scroll_Rules).Build);
      Set_Part_Style (+Inner, Main_Part, From (Inner_Rules).Build);
      Add_Child (+Page, +Inner);
      for I in 1 .. 8 loop
         declare
            Item : constant Adi.Widget.Box.Box_Handle :=
              Adi.Widget.Box.Create_Handle;
         begin
            Set_Part_Style (+Item, Main_Part, From (Item_Rules).Build);
            Add_Child (+Page, +Item);
         end;
      end loop;

      W := Create_Window_Handle ("Nested", (300.0, 200.0));
      Set_Enforce_Layout_Min_Size (W, False);
      Set_Root (W, +Page);
      Render (W);

      Now := Now + 10.0;
      On_Finger_Down (W, 1, 150.0, 70.0, Now);
      On_Finger_Move (W, 1, 150.0, 40.0, Now + 0.5);
      On_Finger_Move (W, 1, 150.0, 10.0, Now + 1.0);
      On_Finger_Up (W, 1, 150.0, 10.0, Now + 1.2);
      Assert (Get_Scroll_Offset_Y (+Page) > 20.0,
              "a drag on a container with nothing to scroll moves the page");

      Set_Scroll_Velocity_Y (+Page, 1000.0);
      Now := Now + 10.0;
      On_Finger_Down (W, 1, 150.0, 20.0, Now);
      Assert (Get_Scroll_Velocity_Y (+Page) = 0.0,
              "and a touch on it stops the page");
      On_Finger_Up (W, 1, 150.0, 20.0, Now + 0.05);

      Destroy (W);
   end Test_Nested_Scrollers;

   --  A slider takes a finger drag as a mouse drag; a text field selects
   --  the word under a long press
   procedure Test_Widgets is
      W      : Window_Handle;
      Column : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Slider : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (0.0, 100.0, 0.0);
      Field  : constant Adi.Widget.Text_Input.Text_Input_Handle :=
        Adi.Widget.Text_Input.Create_Handle ("hello world");
      Editor : constant Adi.Widget.Text_Editor.Text_Editor_Handle :=
        Adi.Widget.Text_Editor.Create_Handle
          ("line one" & ASCII.LF & "line two");
      Editor_Rules : constant Style_Rules :=
        (Width      => Set (Size (Px (200.0))),
         Height     => Set (Size (Px (80.0))),
         Min_Height => Set (Size (Px (80.0))),
         others     => <>);
      Column_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Adi.CSS_Styles.Column),
         Overflow_Y     => Set (Overflow_Auto),
         others         => <>);
      Fixed_Rules : constant Style_Rules :=
        (Width      => Set (Size (Px (200.0))),
         Height     => Set (Size (Px (40.0))),
         Min_Height => Set (Size (Px (40.0))),
         others     => <>);
      Tall_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (600.0))),
         Min_Height => Set (Size (Px (600.0))),
         others => <>);
      Filler : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Slider_G : Rectangle;
   begin
      Section ("slider and text field");
      Set_Part_Style (+Column, Main_Part, From (Column_Rules).Build);
      Set_Part_Style (+Slider, Main_Part, From (Fixed_Rules).Build);
      Set_Part_Style (+Field, Main_Part, From (Fixed_Rules).Build);
      Set_Part_Style (+Filler, Main_Part, From (Tall_Rules).Build);
      Add_Child (+Column, +Slider);
      Add_Child (+Column, +Field);
      Set_Part_Style (+Editor, Main_Part, From (Editor_Rules).Build);
      Add_Child (+Column, +Editor);
      Add_Child (+Column, +Filler);

      W := Create_Window_Handle ("Touch Widgets", (300.0, 200.0));
      Set_Enforce_Layout_Min_Size (W, False);
      Set_Root (W, +Column);
      Render (W);

      Now := Now + 10.0;
      Slider_G := Get_Geometry (+Slider);
      On_Finger_Down
        (W, 1, Slider_G.X + 5.0, Slider_G.Y + Slider_G.Height / 2.0, Now);
      On_Finger_Move
        (W, 1, Slider_G.X + Slider_G.Width - 5.0,
         Slider_G.Y + Slider_G.Height / 2.0 + 30.0, Now + 0.1);
      On_Finger_Up
        (W, 1, Slider_G.X + Slider_G.Width - 5.0,
         Slider_G.Y + Slider_G.Height / 2.0 + 30.0, Now + 0.1);
      Assert (Float_Slider.Get_Value (Slider) > 80.0,
              "a finger drags the slider's knob");
      Assert (Get_Scroll_Offset_Y (+Column) = 0.0,
              "rather than scrolling the page");

      Now := Now + 10.0;
      declare
         G : constant Rectangle := Get_Geometry (+Field);
      begin
         --  On "hello", the first word
         On_Finger_Down (W, 1, G.X + 12.0, G.Y + G.Height / 2.0, Now);
         Tick (W, 0.0);  --  the frame it lands in
         Now := Now + 0.6;
         Tick (W, 0.6);
         Assert (Overlay_Count (W) = 0,
                 "in a text field the menu waits for the finger to lift");
         On_Finger_Up (W, 1, G.X + 12.0, G.Y + G.Height / 2.0, Now);
         Assert (Overlay_Count (W) > 0, "and opens when it lifts");
      end;
      Clear_Overlays (W);
      On_Text_Input (W, "X");
      Assert (Adi.Widget.Text_Input.Get_Text (Field) = "X world",
              "a long press in a text field selects the word");

      --  Two quick taps on the same word select it
      Adi.Widget.Text_Input.Set_Text (Field, "hello world");
      Render (W);
      Now := Now + 10.0;
      declare
         G : constant Rectangle := Get_Geometry (+Field);
         Y : constant Pixel_Type := G.Y + G.Height / 2.0;
      begin
         On_Finger_Down (W, 1, G.X + 12.0, Y, Now);
         On_Finger_Up (W, 1, G.X + 12.0, Y, Now + 0.05);
         On_Finger_Down (W, 1, G.X + 13.0, Y, Now + 0.15);
         On_Finger_Up (W, 1, G.X + 13.0, Y, Now + 0.2);
      end;
      On_Text_Input (W, "X");
      Assert (Adi.Widget.Text_Input.Get_Text (Field) = "X world",
              "a double tap in a text field selects the word");

      --  Held, then dragged from the start of the text past its end
      Adi.Widget.Text_Input.Set_Text (Field, "hello world");
      Render (W);
      Now := Now + 10.0;
      declare
         G : constant Rectangle := Get_Geometry (+Field);
         Y : constant Pixel_Type := G.Y + G.Height / 2.0;
      begin
         On_Finger_Down (W, 1, G.X + 1.0, Y, Now);
         Tick (W, 0.0);  --  the frame it lands in
         Now := Now + 0.6;
         Tick (W, 0.6);
         On_Finger_Move (W, 1, G.X + G.Width / 2.0, Y, Now + 0.1);
         On_Finger_Move (W, 1, G.X + G.Width - 1.0, Y, Now + 0.2);
         On_Finger_Up (W, 1, G.X + G.Width - 1.0, Y, Now + 0.2);
      end;
      Clear_Overlays (W);
      On_Text_Input (W, "X");
      Assert (Adi.Widget.Text_Input.Get_Text (Field) = "X",
              "a long press dragged across the field selects all of it");

      --  The same down across both lines of an editor
      Now := Now + 10.0;
      declare
         G : constant Rectangle := Get_Geometry (+Editor);
      begin
         On_Finger_Down (W, 1, G.X + 1.0, G.Y + 4.0, Now);
         Tick (W, 0.0);  --  the frame it lands in
         Now := Now + 0.6;
         Tick (W, 0.6);
         On_Finger_Move
           (W, 1, G.X + G.Width - 1.0, G.Y + G.Height - 4.0, Now + 0.1);
         On_Finger_Up
           (W, 1, G.X + G.Width - 1.0, G.Y + G.Height - 4.0, Now + 0.1);
      end;
      Clear_Overlays (W);
      On_Text_Input (W, "X");
      Assert (Adi.Widget.Text_Editor.Get_Text (Editor) = "X",
              "a long press dragged across the editor selects both lines");

      Destroy (W);
   end Test_Widgets;

begin
   Start_Suite ("Touch Test");

   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   if not Boolean (SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS))
     or else not Boolean (Adi.SDL.TTF.TTF_Init)
   then
      Assert (False, "SDL and SDL_ttf initialise");
      Finish;
      return;
   end if;

   Build;
   Test_Tap;
   Test_Drag_Scrolls;
   Test_Fling;
   Test_Long_Press;
   Test_Second_Finger;
   Test_Cancel;
   Test_Recovery;
   Destroy (Win);

   Test_Nested_Scrollers;

   Test_Widgets;

   Finish;
end Touch_Test;
