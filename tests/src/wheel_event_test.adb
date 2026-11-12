pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.App;
with Adi.Core;             use Adi.Core;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.SDL;              use Adi.SDL;
with Adi.SDL.Events;       use Adi.SDL.Events;
with Adi.SDL.TTF;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Integer_Slider;
with Adi.Widget_Styles;    use Adi.Widget_Styles;
with Adi.Window;           use Adi.Window;
with Interfaces.C;         use Interfaces.C;
with Test_Support;

--  A mouse wheel event from SDL, through the application loop, to the
--  box under the pointer. The event carries its notches in x and y, as
--  SDL 3.2 and 3.4 both do; the bytes past mouse_y are zero, as they are
--  on SDL 3.2, which has no integer_x and integer_y. A widget that steps
--  per notch gathers a touchpad's fractions into whole ones.

procedure Wheel_Event_Test is

   package Int_Slider is new Adi.Widget.Integer_Slider (Integer);
   use type Adi.Widget.Box.Box_Handle;
   use type Int_Slider.Slider_Handle;

   A      : Adi.App.App;
   Main   : Window_Handle := Null_Window_Handle;
   Scroll : Adi.Widget.Box.Box_Handle;
   Slider : Int_Slider.Slider_Handle;
   Ticks  : Natural := 0;

   --  What the app had made of the event by the tick after the push
   Offset_After_Notch : Pixel_Type := 0.0;

   --  The slider's value after each wheel delta handed to it
   type Value_List is array (Positive range <>) of Integer;
   Deltas : constant array (1 .. 5) of Pixel_Type :=
     [0.5, -0.5, 0.5, 0.5, 2.0];
   Values : Value_List (Deltas'Range) := [others => 0];

   --  The pointer over the scroll box
   Over_Scroll : constant := 80.0;

   procedure Push_Wheel (X, Y : Float; Notches : Float) is
      Event : aliased SDL_Event :=
        (Event_Type => SDL_EVENT_MOUSE_WHEEL, others => <>);
      Wheel : SDL_MouseWheelEvent
        with Import, Address => Event'Address;
      Ok : Adi.SDL.C_bool;
   begin
      Wheel.Y := C_float (Notches);
      Wheel.Mouse_X := C_float (X);
      Wheel.Mouse_Y := C_float (Y);
      Ok := SDL_PushEvent (Event'Access);
      Test_Support.Assert (Boolean (Ok), "SDL accepts the wheel event");
   end Push_Wheel;

   --  Each push is handled by the next frame's poll, before its tick
   procedure Drive (DT : Duration) is
      pragma Unreferenced (DT);
   begin
      Ticks := Ticks + 1;
      case Ticks is
         when 1 =>
            Push_Wheel (Over_Scroll, 120.0, -1.0);
         when 2 =>
            Offset_After_Notch := Get_Scroll_Offset_Y (+Scroll);
            for I in Deltas'Range loop
               On_Mouse_Wheel (+Slider, 0.0, Deltas (I));
               Values (I) := Int_Slider.Get_Value (Slider);
            end loop;
            Adi.App.Request_Quit;
         when others =>
            null;
      end case;
   end Drive;

   procedure Build is
      Root    : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Content : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
   begin
      Scroll := Adi.Widget.Box.Create_Handle;
      Slider := Int_Slider.Create_Handle (0, 100, 50);
      Int_Slider.Set_Step (Slider, 1);

      Set_Part_Style
        (+Root, Main_Part,
         From ((Display        => Set (Flex),
                Flex_Direction => Set (Row),
                Align_Items    => Set (Flex_Start),
                others         => <>)).Build);
      Set_Part_Style
        (+Scroll, Main_Part,
         From ((Display     => Set (Flex),
                Width       => Set (Size (Px (160.0))),
                Height      => Set (Size (Px (240.0))),
                Flex_Shrink => Set (Flex_Shrink_Value (0.0)),
                Overflow_Y  => Set (Overflow_Auto),
                others      => <>)).Build);
      Set_Part_Style
        (+Content, Main_Part,
         From ((Height      => Set (Size (Px (2000.0))),
                Width       => Set (Size (Px (100.0))),
                Flex_Shrink => Set (Flex_Shrink_Value (0.0)),
                others      => <>)).Build);
      Set_Part_Style
        (+Slider, Main_Part,
         From ((Width  => Set (Size (Px (120.0))),
                Height => Set (Size (Px (30.0))),
                others => <>)).Build);

      Adi.Widget.Box.Add_Child (Scroll, +Content);
      Adi.Widget.Box.Add_Child (Root, +Scroll);
      Adi.Widget.Box.Add_Child (Root, +Slider);
      Set_Root (Main, +Root);
   end Build;

   Ready : Boolean;
begin
   Test_Support.Start_Suite ("Wheel Event Test");

   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   Ready := Boolean (SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS))
     and then Boolean (Adi.SDL.TTF.TTF_Init);
   Test_Support.Assert (Ready, "SDL and TTF initialise");
   if not Ready then
      Test_Support.Finish;
      return;
   end if;

   A.Init;
   Main := Create_Window_Handle ("Wheel", (320.0, 240.0));
   Build;
   Connect_Tick (Main, Drive'Unrestricted_Access);
   A.Add_Window (Main);
   A.Run;

   Test_Support.Section ("A notch scrolls the box under the pointer");
   Test_Support.Assert (Offset_After_Notch > 0.0,
                        "one notch down moves the scroll offset");

   Test_Support.Section ("A stepping widget steps once per whole notch");
   Test_Support.Assert (Values (1) = 50,
                        "half a notch leaves the slider where it was");
   Test_Support.Assert (Values (2) = 50,
                        "half a notch back cancels it, no step");
   Test_Support.Assert (Values (3) = 50,
                        "the turn back dropped the half gathered before");
   Test_Support.Assert (Values (4) = 51,
                        "a second half makes a notch: one step");
   Test_Support.Assert (Values (5) = 52,
                        "two notches at once step once");

   Test_Support.Finish;
end Wheel_Event_Test;
