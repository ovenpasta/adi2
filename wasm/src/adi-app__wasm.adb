--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  WebAssembly body of Adi.App: Emscripten cannot block the main JS
--  thread, so the native `while not Should_Quit loop` becomes SDL3's
--  main-callback API. Run registers App_Init/App_Iterate/App_Event/
--  App_Quit via SDL_EnterAppMainCallbacks and never returns
--  (emscripten_exit_with_live_runtime); the browser then calls
--  App_Iterate once per requestAnimationFrame and App_Event per event.
--
--  The event dispatch deliberately duplicates src/adi-app.adb (kept in
--  callback form rather than sharing helpers, so the desktop tree stays
--  untouched). When changing event handling, update BOTH bodies.
--
--  Examples need no changes: they build their UI before calling Run, so
--  App_Init has nothing left to do; frame pacing (Sleep_Until) is
--  absent because the browser drives cadence.

with Adi.Core; use Adi.Core;
with Adi.SDL;
with Adi.SDL.TTF;
with Adi.SDL.Events;
with Adi.SDL.Render;
with Adi.SDL.Mouse;
with Adi.Widget;
with Ada.Exceptions;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Ada.Unchecked_Conversion;
with Adi.Clock; use Adi.Clock;
with Adi.Dispatch;
with Adi.Log;
with Adi.Widget.Context_Menu;
with System;

package body Adi.App is

    use SDL.Events;

    use type Adi.SDL.Render.SDL_Renderer_Ptr;

    ------------------------------------------------------------------
    --  SDL main-callback bindings (local: the desktop Adi.SDL tree is
    --  not touched by the WASM port)
    ------------------------------------------------------------------

    type SDL_App_Result is
      (SDL_APP_CONTINUE,
       SDL_APP_SUCCESS,
       SDL_APP_FAILURE)
      with Convention => C;

    type App_Init_Func is access function
      (Appstate : System.Address;
       Argc     : int;
       Argv     : System.Address) return SDL_App_Result
      with Convention => C;

    type App_Iterate_Func is access function
      (Appstate : System.Address) return SDL_App_Result
      with Convention => C;

    type App_Event_Func is access function
      (Appstate : System.Address;
       Event    : access SDL_Event) return SDL_App_Result
      with Convention => C;

    type App_Quit_Func is access procedure
      (Appstate : System.Address;
       Result   : SDL_App_Result)
      with Convention => C;

    function SDL_EnterAppMainCallbacks
      (Argc     : int;
       Argv     : System.Address;
       Appinit  : App_Init_Func;
       Appiter  : App_Iterate_Func;
       Appevent : App_Event_Func;
       Appquit  : App_Quit_Func) return int
      with Import => True, Convention => C,
           External_Name => "SDL_EnterAppMainCallbacks";

    procedure Emscripten_Exit_With_Live_Runtime
      with Import => True, Convention => C,
           External_Name => "emscripten_exit_with_live_runtime",
           No_Return => True;

    ------------------------------------------------------------------
    --  App state. SDL_EnterAppMainCallbacks RETURNS IMMEDIATELY on
    --  Emscripten (the browser then drives the callbacks), so the
    --  caller's stack — including its App variable and every example
    --  local — is gone by the first frame. The App record is therefore
    --  copied BY VALUE to package level here. Widgets and windows are
    --  unaffected: handles are plain IDs and the objects live in the
    --  package-level stores.
    ------------------------------------------------------------------

    State : App;

    function Main return Window_Access is
    begin
       return Adi.Window.Resolve_Window_Handle (State.Main_Window);
    end Main;

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

    ----------
    -- Init --
    ----------

    procedure Init (A : in out App) is
      use Adi.SDL;
    begin
      SDL_Assert (SDL_Init (Adi.SDL.SDL_INIT_VIDEO or Adi.SDL.SDL_INIT_EVENTS), "SDL_Init");
      SDL_Assert (Adi.SDL.TTF.TTF_Init, "TTF_Init");
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

    procedure Convert_Event_To_Render_Coordinates
      (Event : access SDL_Event)
    is
       Renderer  : Adi.SDL.Render.SDL_Renderer_Ptr := null;
       Converted : Adi.SDL.C_bool;
       pragma Unreferenced (Converted);
    begin
       if Main = null then
          return;
       end if;

       Renderer := Main.Get_Renderer;
       if Renderer = null then
          return;
       end if;

       Converted := Adi.SDL.Render.SDL_ConvertEventToRenderCoordinates
         (Renderer, Event);
    end Convert_Event_To_Render_Coordinates;

    --------------
    -- App_Init --
    --------------

    function App_Init
      (Appstate : System.Address;
       Argc     : int;
       Argv     : System.Address) return SDL_App_Result
      with Convention => C;

    function App_Init
      (Appstate : System.Address;
       Argc     : int;
       Argv     : System.Address) return SDL_App_Result
    is
       pragma Unreferenced (Appstate, Argc, Argv);
    begin
       --  SDL init, window creation and UI setup already happened in the
       --  example's main procedure, before Run was called.
       return SDL_APP_CONTINUE;
    end App_Init;

    ---------------
    -- App_Event --
    ---------------

    function App_Event
      (Appstate : System.Address;
       Event    : access SDL_Event) return SDL_App_Result
      with Convention => C;

    function App_Event
      (Appstate : System.Address;
       Event    : access SDL_Event) return SDL_App_Result
    is
       pragma Unreferenced (Appstate);
    begin
       case Event.Event_Type is
           when SDL_EVENT_WINDOW_CLOSE_REQUESTED =>
               if Main /= null then
                   if Main.Handle_Close_Request then
                       return SDL_APP_SUCCESS;
                   end if;
               end if;

           when SDL_EVENT_QUIT =>
               if Main /= null then
                   if Main.Handle_Close_Request then
                       return SDL_APP_SUCCESS;
                   end if;
               else
                   return SDL_APP_SUCCESS;
               end if;

           when SDL_EVENT_WINDOW_EXPOSED =>
               if Main /= null then
                   Main.Request_Redraw;
               end if;

           when SDL_EVENT_WINDOW_RESIZED
              | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
              | SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED =>
               if Main /= null then
                   declare
                       Actual_Size : constant Size_2D :=
                          Main.Actual_Size;
                   begin
                       Main.Handle_Resize (Actual_Size);
                   end;
               end if;

           when SDL_EVENT_MOUSE_MOTION =>
               if Main /= null then
                   Convert_Event_To_Render_Coordinates (Event);
                   declare
                       Motion_Event : constant SDL_MouseMotionEvent :=
                          To_Mouse_Motion_Event (Event.all);
                   begin
                       Main.On_Mouse_Move
                          (X => Adi.Core.Pixel_Type (Motion_Event.X),
                           Y => Adi.Core.Pixel_Type (Motion_Event.Y));
                   end;
               end if;

           when SDL_EVENT_WINDOW_MOUSE_LEAVE =>
               if Main /= null then
                   --  Force hover clear when cursor leaves window.
                   Main.On_Mouse_Move (X => -1.0, Y => -1.0);
               end if;

           when SDL_EVENT_MOUSE_BUTTON_DOWN =>
               if Main /= null then
                   Convert_Event_To_Render_Coordinates (Event);
                   declare
                       Button_Event : constant SDL_MouseButtonEvent :=
                          To_Mouse_Button_Event (Event.all);
                   begin
                       Main.On_Mouse_Down
                          (X      => Adi.Core.Pixel_Type (Button_Event.X),
                           Y      => Adi.Core.Pixel_Type (Button_Event.Y),
                           Button => To_Mouse_Button (Button_Event.Button),
                           Clicks => Natural (Button_Event.Clicks));
                   end;
               end if;

           when SDL_EVENT_MOUSE_BUTTON_UP =>
               if Main /= null then
                   Convert_Event_To_Render_Coordinates (Event);
                   declare
                       Button_Event : constant SDL_MouseButtonEvent :=
                          To_Mouse_Button_Event (Event.all);
                   begin
                       Main.On_Mouse_Up
                          (X      => Adi.Core.Pixel_Type (Button_Event.X),
                           Y      => Adi.Core.Pixel_Type (Button_Event.Y),
                           Button => To_Mouse_Button (Button_Event.Button));
                   end;
               end if;

           when SDL_EVENT_MOUSE_WHEEL =>
               if Main /= null then
                   Convert_Event_To_Render_Coordinates (Event);
                   declare
                       Wheel_Event : constant SDL_MouseWheelEvent :=
                          To_Mouse_Wheel_Event (Event.all);
                   begin
                       Main.On_Mouse_Wheel
                          (X       => Adi.Core.Pixel_Type (Wheel_Event.Mouse_X),
                           Y       => Adi.Core.Pixel_Type (Wheel_Event.Mouse_Y),
                           Delta_X => Adi.Core.Pixel_Type (Wheel_Event.Integer_X),
                           Delta_Y => Adi.Core.Pixel_Type (Wheel_Event.Integer_Y));
                   end;
               end if;

           when SDL_EVENT_KEY_DOWN =>
               if Main /= null then
                   declare
                       Key_Event : constant SDL_KeyboardEvent :=
                          To_Keyboard_Event (Event.all);
                   begin
                       Main.On_Key_Down
                         (Scancode => Key_Event.Scancode,
                          Keycode  => Key_Event.Key,
                          Key_Mod  => Key_Event.Key_Mod,
                          Repeat   => Boolean (Key_Event.Is_Repeat));
                   end;
               end if;

           when SDL_EVENT_KEY_UP =>
               if Main /= null then
                   declare
                       Key_Event : constant SDL_KeyboardEvent :=
                          To_Keyboard_Event (Event.all);
                   begin
                       Main.On_Key_Up
                         (Scancode => Key_Event.Scancode,
                          Key_Mod  => Key_Event.Key_Mod,
                          Repeat   => Boolean (Key_Event.Is_Repeat));
                   end;
               end if;

           when SDL_EVENT_TEXT_INPUT =>
               if Main /= null then
                   declare
                       use Interfaces.C.Strings;
                       Text_Event : constant SDL_TextInputEvent :=
                         To_Text_Input_Event (Event.all);
                       Input_Text : constant String :=
                         (if Text_Event.Text = Null_Ptr
                          then ""
                          else Value (Text_Event.Text));
                   begin
                       if Input_Text'Length > 0 then
                          Main.On_Text_Input (Input_Text);
                       end if;
                   end;
               end if;

           when others =>
               null;
       end case;

       return SDL_APP_CONTINUE;
    exception
       when E : others =>
          --  Never let an Ada exception unwind into SDL's C frames.
          Adi.Log.Error
            ("unhandled exception in event dispatch: "
             & Ada.Exceptions.Exception_Information (E));
          return SDL_APP_FAILURE;
    end App_Event;

    -----------------
    -- App_Iterate --
    -----------------

    function App_Iterate
      (Appstate : System.Address) return SDL_App_Result
      with Convention => C;

    function App_Iterate
      (Appstate : System.Address) return SDL_App_Result
    is
       pragma Unreferenced (Appstate);
       Frame_Start : Time;
       DT          : Duration;
    begin
       --  Drain deferred dispatch queue (posted from previous-frame
       --  callbacks).
       declare
          Had_Dispatch : constant Boolean :=
            Adi.Dispatch.Pending_Count > 0;
       begin
          Adi.Dispatch.Drain;
          if Had_Dispatch and then Main /= null then
             Main.Request_Redraw;
          end if;
       end;

       --  Drain deferred handle-store destroys.
       Adi.Widget.Pump_Widget_Store;
       Adi.Widget.Context_Menu.Pump_Menu_Store;
       Adi.Window.Pump_Window_Store;

       --  Main window can be destroyed from callbacks; terminate cleanly.
       if Main = null then
          return SDL_APP_SUCCESS;
       end if;

       --  Compute delta time
       Frame_Start := Now;
       DT := To_Duration (Frame_Start - State.Last_Frame);
       State.Current_Delta := DT;
       State.Last_Frame := Frame_Start;

       --  Tick animations before rendering
       Main.Tick (DT);

       --  Render the main window (the browser paces us; no delay)
       if Main /= null then
           Main.Render;
       end if;

       return SDL_APP_CONTINUE;
    exception
       when E : others =>
          --  Never let an Ada exception unwind into SDL's C frames.
          Adi.Log.Error
            ("unhandled exception in frame iterate: "
             & Ada.Exceptions.Exception_Information (E));
          return SDL_APP_FAILURE;
    end App_Iterate;

    --------------
    -- App_Quit --
    --------------

    procedure App_Quit
      (Appstate : System.Address;
       Result   : SDL_App_Result)
      with Convention => C;

    procedure App_Quit
      (Appstate : System.Address;
       Result   : SDL_App_Result)
    is
       pragma Unreferenced (Appstate, Result);
    begin
       Adi.Window.Destroy (State.Main_Window);
    end App_Quit;

    ---------
    -- Run --
    ---------

    procedure Run (A : in out App) is
        Status : int;
    begin
        State := A;
        State.Last_Frame := Now;

        Status := SDL_EnterAppMainCallbacks
          (Argc     => 0,
           Argv     => System.Null_Address,
           Appinit  => App_Init'Access,
           Appiter  => App_Iterate'Access,
           Appevent => App_Event'Access,
           Appquit  => App_Quit'Access);

        if Status = 0 then
           --  Keep the WASM instance alive: the browser keeps calling the
           --  registered callbacks after "main" exits.
           Emscripten_Exit_With_Live_Runtime;
        end if;
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
