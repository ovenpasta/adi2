--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;
with Adi.Core; use Adi.Core;
with Adi.SDL;
with Adi.SDL.TTF;
with Adi.SDL.Events;
with Adi.SDL.Render;
with Adi.SDL.Mouse;
with Adi.Widget;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Ada.Unchecked_Conversion;
with Adi.Clock; use Adi.Clock;
with Adi.Dispatch;
with Adi.Log;
with Adi.Widget.Context_Menu;

package body Adi.App is

    use type Adi.SDL.Render.SDL_Renderer_Ptr;

    ----------
    -- Init --
    ----------

    procedure Init (A : in out App) is
      use Adi.SDL;
    begin
      SDL_Assert (SDL_Init(Adi.SDL.SDL_INIT_VIDEO or Adi.SDL.SDL_INIT_EVENTS),"SDL_Init");
      SDL_Assert (Adi.SDL.TTF.TTF_Init,"TTF_Init");
    end Init;

    function To_Mouse_Button (B : Adi.SDL.Uint8) return Adi.Core.Mouse_Button is
    begin
       case B is
          when Adi.SDL.Mouse.SDL_BUTTON_LEFT =>
             return Adi.Core.Left_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_MIDDLE =>
             return Adi.Core.Middle_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_RIGHT =>
             return Adi.Core.Right_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_X1 =>
             return Adi.Core.X1_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_X2 =>
             return Adi.Core.X2_Button;
          when others =>
             return Adi.Core.Left_Button;
       end case;
    end To_Mouse_Button;

    ---------
    -- Run --
    ---------

    procedure Run (A : in out App) is
        use SDL.Events;

        Event         : aliased SDL_Event;
        Should_Quit   : Boolean := False;
        Close_Handled : Boolean;

        --  Unchecked conversions to access specific event data.
        --  SDL_Event is C's event union; every sub-event record is a
        --  prefix of it, so converting the (larger) union to a sub-event
        --  reads exactly the bytes SDL wrote. The size-mismatch warning
        --  is expected and harmless here.
        pragma Warnings
          (Off, "types for unchecked conversion have different sizes");
        function To_Mouse_Motion_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_MouseMotionEvent);
        function To_Mouse_Button_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_MouseButtonEvent);
        function To_Mouse_Wheel_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_MouseWheelEvent);
        function To_Keyboard_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_KeyboardEvent);
        function To_Text_Input_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_TextInputEvent);
        pragma Warnings
          (On, "types for unchecked conversion have different sizes");

        Frame_Start : Time;
        Next_Frame : Time;
        DT         : Duration;

        --  A handle rather than a cached pointer or a borrow held across
        --  the frame.  Destroying a window from a callback that runs
        --  under a dispatch guard -- Tick, the input handlers -- queues
        --  the destroy, and Pump_Window_Store at the top of the next
        --  frame carries it out; the check below then ends the loop.
        --  A borrow spanning that pump would defer the destroy past it
        --  and the loop would keep driving a window the application
        --  believes it closed.
        function Main return Adi.Window.Window_Handle is (A.Main_Window);

        function Have_Main return Boolean
        is (Adi.Window.Is_Valid (A.Main_Window));

        procedure Convert_Event_To_Render_Coordinates is
           Renderer  : Adi.SDL.Render.SDL_Renderer_Ptr := null;
           Converted : Adi.SDL.C_bool;
           pragma Unreferenced (Converted);
        begin
           if not Have_Main then
              return;
           end if;

           Renderer := Adi.Window.Get_Renderer (Main);
           if Renderer = null then
              return;
           end if;

           Converted := Adi.SDL.Render.SDL_ConvertEventToRenderCoordinates
             (Renderer, Event'Access);
        end Convert_Event_To_Render_Coordinates;
    begin
        A.Last_Frame := Now;

        while not Should_Quit loop
            Close_Handled := False;

            --  The event dispatch below is duplicated in
            --  wasm/src/adi-app__wasm.adb (SDL main-callback body used by
            --  the WASM callbacks mode). Apply changes to both.
            Poll_Events :
            while SDL_PollEvent (Event'Access) loop
                case Event.Event_Type is
                    when SDL_EVENT_WINDOW_CLOSE_REQUESTED =>
                        if not Should_Quit and not Close_Handled
                           and Have_Main
                        then
                            Close_Handled := True;
                            if Adi.Window.Handle_Close_Request (Main) then
                                Should_Quit := True;
                                exit Poll_Events;
                            end if;
                        end if;

                    when SDL_EVENT_QUIT =>
                        if not Should_Quit then
                            if Have_Main then
                                if Adi.Window.Handle_Close_Request (Main) then
                                    Should_Quit := True;
                                    exit Poll_Events;
                                end if;
                            else
                                Should_Quit := True;
                                exit Poll_Events;
                            end if;
                        end if;

                    when SDL_EVENT_WINDOW_EXPOSED =>
                        if Have_Main then
                            Adi.Window.Request_Redraw (Main);
                        end if;

                    when SDL_EVENT_WINDOW_RESIZED
                       | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
                       | SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED =>
                        if Have_Main then
                            declare
                                Actual_Size : constant Size_2D :=
                                   Adi.Window.Actual_Size (Main);
                            begin
                                Adi.Window.Handle_Resize (Main, Actual_Size);
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_MOTION =>
                        if Have_Main then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Motion_Event : constant SDL_MouseMotionEvent :=
                                   To_Mouse_Motion_Event (Event);
                            begin
                                Adi.Window.On_Mouse_Move
                                  (Main,
                                   X => Adi.Core.Pixel_Type (Motion_Event.X),
                                   Y => Adi.Core.Pixel_Type (Motion_Event.Y));
                            end;
                        end if;

                    when SDL_EVENT_WINDOW_MOUSE_LEAVE =>
                        if Have_Main then
                            --  Force hover clear when cursor leaves window.
                            Adi.Window.On_Mouse_Move
                                  (Main,
                                   X => -1.0, Y => -1.0);
                        end if;

                    when SDL_EVENT_MOUSE_BUTTON_DOWN =>
                        if Have_Main then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Button_Event : constant SDL_MouseButtonEvent :=
                                   To_Mouse_Button_Event (Event);
                            begin
                                Adi.Window.On_Mouse_Down
                                  (Main,
                                   X => Adi.Core.Pixel_Type (Button_Event.X),
                                   Y => Adi.Core.Pixel_Type (Button_Event.Y),
                                   Button =>
                                     To_Mouse_Button (Button_Event.Button),
                                   Clicks =>
                                     Natural (Button_Event.Clicks));
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_BUTTON_UP =>
                        if Have_Main then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Button_Event : constant SDL_MouseButtonEvent :=
                                   To_Mouse_Button_Event (Event);
                            begin
                                Adi.Window.On_Mouse_Up
                                  (Main,
                                   X => Adi.Core.Pixel_Type (Button_Event.X),
                                    Y      => Adi.Core.Pixel_Type (Button_Event.Y),
                                    Button => To_Mouse_Button (Button_Event.Button));
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_WHEEL =>
                        if Have_Main then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Wheel_Event : constant SDL_MouseWheelEvent :=
                                   To_Mouse_Wheel_Event (Event);
                            begin
                                Adi.Window.On_Mouse_Wheel
                                  (Main,
                                   X => Adi.Core.Pixel_Type (Wheel_Event.Mouse_X),
                                    Y       => Adi.Core.Pixel_Type (Wheel_Event.Mouse_Y),
                                    Delta_X => Adi.Core.Pixel_Type (Wheel_Event.Integer_X),
                                    Delta_Y => Adi.Core.Pixel_Type (Wheel_Event.Integer_Y));
                            end;
                        end if;

                    when SDL_EVENT_KEY_DOWN =>
                        if Have_Main then
                            declare
                                Key_Event : constant SDL_KeyboardEvent :=
                                   To_Keyboard_Event (Event);
                            begin
                                Adi.Window.On_Key_Down
                                  (Main,
                                   Scancode => Key_Event.Scancode,
                                   Keycode  => Key_Event.Key,
                                   Key_Mod  => Key_Event.Key_Mod,
                                   Repeat   => Boolean (Key_Event.Is_Repeat));
                            end;
                        end if;

                    when SDL_EVENT_KEY_UP =>
                        if Have_Main then
                            declare
                                Key_Event : constant SDL_KeyboardEvent :=
                                   To_Keyboard_Event (Event);
                            begin
                                Adi.Window.On_Key_Up
                                  (Main,
                                   Scancode => Key_Event.Scancode,
                                   Key_Mod  => Key_Event.Key_Mod,
                                   Repeat   => Boolean (Key_Event.Is_Repeat));
                            end;
                        end if;

                    when SDL_EVENT_TEXT_INPUT =>
                        if Have_Main then
                            declare
                                use Interfaces.C.Strings;
                                Text_Event : constant SDL_TextInputEvent :=
                                  To_Text_Input_Event (Event);
                                Input_Text : constant String :=
                                  (if Text_Event.Text = Null_Ptr
                                   then ""
                                   else Value (Text_Event.Text));
                            begin
                                if Input_Text'Length > 0 then
                                   Adi.Window.On_Text_Input (Main, Input_Text);
                                end if;
                            end;
                        end if;

                    when others =>
                        null;
                end case;
            end loop Poll_Events;

            --  Drain deferred dispatch queue (posted from background
            --  tasks or previous-frame callbacks).
            declare
               Had_Dispatch : constant Boolean :=
                 Adi.Dispatch.Pending_Count > 0;
            begin
               Adi.Dispatch.Drain;
               if Had_Dispatch and then Have_Main then
                  Adi.Window.Request_Redraw (Main);
               end if;
            end;

            --  Drain deferred handle-store destroys.
            Adi.Widget.Pump_Widget_Store;
            Adi.Widget.Context_Menu.Pump_Menu_Store;
            Adi.Window.Pump_Window_Store;

            --  Main window can be destroyed from callbacks; terminate cleanly.
            if not Have_Main then
               Should_Quit := True;
               exit;
            end if;

            --  Compute delta time
            Frame_Start := Now;
            DT := To_Duration (Frame_Start - A.Last_Frame);
            A.Current_Delta := DT;
            A.Last_Frame := Frame_Start;

            --  Tick animations before rendering
            if Have_Main then
                Adi.Window.Tick (Main, DT);
            end if;

            --  Render the main window
            if Have_Main then
                Adi.Window.Render (Main);
            end if;

            --  Frame rate limiting: delay until next frame
            Next_Frame := Frame_Start + A.Frame_Period;
            Sleep_Until (Next_Frame);
        end loop;

        --  Destroy window/store entry eagerly while caller scopes are alive.
        Adi.Window.Destroy (A.Main_Window);
    end Run;

    ----------------
    -- Add_Window --
    ----------------

    procedure Add_Window (A : in out App; W : Window_Handle) is
    begin
        if Is_Valid (W) then
           A.Main_Window := W;
        else
           A.Main_Window := Null_Window_Handle;
        end if;
    end Add_Window;

    ------------------
    -- Request_Quit --
    ------------------

    procedure Request_Quit is
       use Adi.SDL.Events;
       Event  : aliased SDL_Event := (Event_Type => SDL_EVENT_QUIT);
    begin
       if not Boolean (SDL_PushEvent (Event'Access)) then
          Adi.Log.Error ("Request_Quit: SDL_PushEvent failed");
       end if;
    end Request_Quit;

    ---------------------
    -- Set_Target_FPS --
    ---------------------

    procedure Set_Target_FPS (A : in out App; FPS : Positive) is
    begin
        A.Target_FPS := FPS;
        A.Frame_Period := Microseconds (1_000_000 / FPS);
    end Set_Target_FPS;

    --------------------
    -- Get_Target_FPS --
    --------------------

    function Get_Target_FPS (A : App) return Positive is
    begin
        return A.Target_FPS;
    end Get_Target_FPS;

    --------------------
    -- Get_Delta_Time --
    --------------------

    function Get_Delta_Time (A : App) return Duration is
    begin
        return A.Current_Delta;
    end Get_Delta_Time;

end Adi.App;
