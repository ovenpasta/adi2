pragma Ada_2022;
with Adi.Core; use Adi.Core;
with Adi.SDL;
with Adi.SDL.TTF;
with Adi.SDL.Events;
with Adi.SDL.Mouse;
with Interfaces.C; use Interfaces.C;
with Ada.Unchecked_Conversion;

package body Adi.App is

    ----------
    -- Init --
    ----------

    procedure Init (A : in out App) is
      use Adi.SDL;
    begin
      SDL_Assert (SDL_Init(Adi.SDL.SDL_INIT_VIDEO or Adi.SDL.SDL_INIT_EVENTS),"SDL_Init");
      SDL_Assert (Adi.SDL.TTF.TTF_Init,"TTF_Init");
    end Init;

    function To_Mouse_Button (B : Adi.SDL.Uint8) return Adi.Window.Mouse_Button is
    begin
       case B is
          when Adi.SDL.Mouse.SDL_BUTTON_LEFT =>
             return Adi.Window.Left_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_MIDDLE =>
             return Adi.Window.Middle_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_RIGHT =>
             return Adi.Window.Right_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_X1 =>
             return Adi.Window.X1_Button;
          when Adi.SDL.Mouse.SDL_BUTTON_X2 =>
             return Adi.Window.X2_Button;
          when others =>
             return Adi.Window.Left_Button;
       end case;
    end To_Mouse_Button;

    ---------
    -- Run --
    ---------

    procedure Run (A : in out App) is
        use SDL.Events;

        Event       : aliased SDL_Event;
        Should_Quit : Boolean := False;

        --  Unchecked conversions to access specific event data
        function To_Window_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_WindowEvent);
        function To_Mouse_Motion_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_MouseMotionEvent);
        function To_Mouse_Button_Event is new Ada.Unchecked_Conversion
           (SDL_Event, SDL_MouseButtonEvent);
    begin
        while not Should_Quit loop
            Poll_Events :
            while SDL_PollEvent (Event'Access) loop
                case Event.Event_Type is
                    when SDL_EVENT_QUIT =>
                        Should_Quit := True;

                    when SDL_EVENT_WINDOW_RESIZED | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED =>
                        --  Handle window resize events
                        if A.Main_Window /= null then
                            declare
                                Actual_Size : constant Size_2D :=
                                   A.Main_Window.Actual_Size;
                            begin
                                A.Main_Window.Handle_Resize (Actual_Size);
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_MOTION =>
                        --  Mouse move event
                        if A.Main_Window /= null then
                            declare
                                Motion_Event : constant SDL_MouseMotionEvent :=
                                   To_Mouse_Motion_Event (Event);
                            begin
                                A.Main_Window.On_Mouse_Move
                                   (X => Adi.Core.Pixel_Type (Motion_Event.X),
                                    Y => Adi.Core.Pixel_Type (Motion_Event.Y));
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_BUTTON_DOWN =>
                        --  Mouse button down event
                        if A.Main_Window /= null then
                            declare
                                Button_Event : constant SDL_MouseButtonEvent :=
                                   To_Mouse_Button_Event (Event);
                            begin
                                A.Main_Window.On_Mouse_Down
                                   (X      => Adi.Core.Pixel_Type (Button_Event.X),
                                    Y      => Adi.Core.Pixel_Type (Button_Event.Y),
                                    Button => To_Mouse_Button (Button_Event.Button));
                            end;
                        end if;

                    when SDL_EVENT_MOUSE_BUTTON_UP =>
                        --  Mouse button up event
                        if A.Main_Window /= null then
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

                    when others =>
                        null;
                end case;
            end loop Poll_Events;

            --  Render the main window
            if A.Main_Window /= null then
                A.Main_Window.Render;
            end if;

            delay 1.0 / 20.0;  -- ~60 FPS
        end loop;
    end Run;

    ----------------
    -- Add_Window --
    ----------------

    procedure Add_Window (A : in out App; W : access Window.Window) is
    begin
        A.Main_Window := W;
    end Add_Window;

end Adi.App;
