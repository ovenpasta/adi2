--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Adi.Clock;
with Adi.Window; use Adi.Window;

package Adi.App is

    type App is tagged private;

    procedure Init (A : in out App);

    procedure Run (A : in out App);

    procedure Add_Window (A : in out App; W : Window_Handle);

    --  Post an SDL_EVENT_QUIT so the event loop processes a quit request.
    --  Useful for programmatic quit (e.g. after a confirmation dialog).
    procedure Request_Quit;

    --  Frame rate management
    procedure Set_Target_FPS (A : in out App; FPS : Positive);
    function Get_Target_FPS (A : App) return Positive;
    function Get_Delta_Time (A : App) return Duration;

private

    type App is tagged record
        Main_Window   : Window_Handle := Null_Window_Handle;
        Target_FPS    : Positive := 60;
        Frame_Period  : Adi.Clock.Time_Span :=
           Adi.Clock.Microseconds (16_667);  -- ~60 FPS
        Last_Frame    : Adi.Clock.Time := Adi.Clock.Zero;
        Current_Delta : Duration := 0.0;
    end record;
end Adi.App;
