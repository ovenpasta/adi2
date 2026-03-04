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
with Ada.Real_Time; use Ada.Real_Time;
with Adi.Dispatch;
with Adi.Log;

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

        --  Unchecked conversions to access specific event data
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

        Now        : Time;
        Next_Frame : Time;
        DT         : Duration;

        procedure Convert_Event_To_Render_Coordinates is
           Renderer  : Adi.SDL.Render.SDL_Renderer_Ptr := null;
           Converted : Adi.SDL.C_bool;
           pragma Unreferenced (Converted);
        begin
           if A.Main_Window = null then
              return;
           end if;

           Renderer := A.Main_Window.Get_Renderer;
           if Renderer = null then
              return;
           end if;

           Converted := Adi.SDL.Render.SDL_ConvertEventToRenderCoordinates
             (Renderer, Event'Access);
        end Convert_Event_To_Render_Coordinates;
    begin
        A.Last_Frame := Clock;

        while not Should_Quit loop
            Close_Handled := False;

            Poll_Events :
            while SDL_PollEvent (Event'Access) loop
                case Event.Event_Type is
                    when SDL_EVENT_WINDOW_CLOSE_REQUESTED =>
                        if not Should_Quit and not Close_Handled
                           and A.Main_Window /= null
                        then
                            Close_Handled := True;
                            if A.Main_Window.Handle_Close_Request then
                                Should_Quit := True;
                                exit Poll_Events;
                            end if;
                        end if;

                    when SDL_EVENT_QUIT =>
                        if not Should_Quit then
                            if A.Main_Window /= null then
                                if A.Main_Window.Handle_Close_Request then
                                    Should_Quit := True;
                                    exit Poll_Events;
                                end if;
                            else
                                Should_Quit := True;
                                exit Poll_Events;
                            end if;
                        end if;

                    when SDL_EVENT_WINDOW_EXPOSED =>
                        if A.Main_Window /= null then
                            A.Main_Window.Request_Redraw;
                        end if;

                    when SDL_EVENT_WINDOW_RESIZED
                       | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
                       | SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED =>
                        if A.Main_Window /= null then
                            declare
                                Actual_Size : constant Size_2D :=
                                   A.Main_Window.Actual_Size;
                            begin
                                A.Main_Window.Handle_Resize (Actual_Size);
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_MOTION =>
                        if A.Main_Window /= null then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Motion_Event : constant SDL_MouseMotionEvent :=
                                   To_Mouse_Motion_Event (Event);
                            begin
                                A.Main_Window.On_Mouse_Move
                                   (X => Adi.Core.Pixel_Type (Motion_Event.X),
                                    Y => Adi.Core.Pixel_Type (Motion_Event.Y));
                            end;
                        end if;

                    when SDL_EVENT_WINDOW_MOUSE_LEAVE =>
                        if A.Main_Window /= null then
                            --  Force hover clear when cursor leaves window.
                            A.Main_Window.On_Mouse_Move (X => -1.0, Y => -1.0);
                        end if;

                    when SDL_EVENT_MOUSE_BUTTON_DOWN =>
                        if A.Main_Window /= null then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Button_Event : constant SDL_MouseButtonEvent :=
                                   To_Mouse_Button_Event (Event);
                            begin
                                A.Main_Window.On_Mouse_Down
                                   (X      => Adi.Core.Pixel_Type (Button_Event.X),
                                    Y      => Adi.Core.Pixel_Type (Button_Event.Y),
                                    Button => To_Mouse_Button (Button_Event.Button),
                                    Clicks => Natural (Button_Event.Clicks));
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_BUTTON_UP =>
                        if A.Main_Window /= null then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Button_Event : constant SDL_MouseButtonEvent :=
                                   To_Mouse_Button_Event (Event);
                            begin
                                A.Main_Window.On_Mouse_Up
                                   (X      => Adi.Core.Pixel_Type (Button_Event.X),
                                    Y      => Adi.Core.Pixel_Type (Button_Event.Y),
                                    Button => To_Mouse_Button (Button_Event.Button));
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_WHEEL =>
                        if A.Main_Window /= null then
                            Convert_Event_To_Render_Coordinates;
                            declare
                                Wheel_Event : constant SDL_MouseWheelEvent :=
                                   To_Mouse_Wheel_Event (Event);
                            begin
                                A.Main_Window.On_Mouse_Wheel
                                   (X       => Adi.Core.Pixel_Type (Wheel_Event.Mouse_X),
                                    Y       => Adi.Core.Pixel_Type (Wheel_Event.Mouse_Y),
                                    Delta_X => Adi.Core.Pixel_Type (Wheel_Event.Integer_X),
                                    Delta_Y => Adi.Core.Pixel_Type (Wheel_Event.Integer_Y));
                            end;
                        end if;

                    when SDL_EVENT_KEY_DOWN =>
                        if A.Main_Window /= null then
                            declare
                                Key_Event : constant SDL_KeyboardEvent :=
                                   To_Keyboard_Event (Event);
                            begin
                                A.Main_Window.On_Key_Down
                                  (Scancode => Key_Event.Scancode,
                                   Key_Mod  => Key_Event.Key_Mod,
                                   Repeat   => Boolean (Key_Event.Is_Repeat));
                            end;
                        end if;

                    when SDL_EVENT_KEY_UP =>
                        if A.Main_Window /= null then
                            declare
                                Key_Event : constant SDL_KeyboardEvent :=
                                   To_Keyboard_Event (Event);
                            begin
                                A.Main_Window.On_Key_Up
                                  (Scancode => Key_Event.Scancode,
                                   Key_Mod  => Key_Event.Key_Mod,
                                   Repeat   => Boolean (Key_Event.Is_Repeat));
                            end;
                        end if;

                    when SDL_EVENT_TEXT_INPUT =>
                        if A.Main_Window /= null then
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
                                   A.Main_Window.On_Text_Input (Input_Text);
                                end if;
                            end;
                        end if;

                    when others =>
                        null;
                end case;
            end loop Poll_Events;

            --  Drain deferred dispatch queue (posted from background
            --  tasks or previous-frame callbacks).
            Adi.Dispatch.Drain;

            --  Compute delta time
            Now := Clock;
            DT := To_Duration (Now - A.Last_Frame);
            A.Current_Delta := DT;
            A.Last_Frame := Now;

            --  Tick animations before rendering
            if A.Main_Window /= null then
                A.Main_Window.Tick (DT);
            end if;

            --  Render the main window
            if A.Main_Window /= null then
                A.Main_Window.Render;
            end if;

            --  Frame rate limiting: delay until next frame
            Next_Frame := Now + A.Frame_Period;
            delay until Next_Frame;
        end loop;
    end Run;

    ----------------
    -- Add_Window --
    ----------------

    procedure Add_Window (A : in out App; W : access Window.Window) is
    begin
        A.Main_Window := W;
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
