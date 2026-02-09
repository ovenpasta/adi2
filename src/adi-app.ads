with Ada.Real_Time;
with Adi.Window; use Adi.Window;

package Adi.App is

    type App is tagged private;

    procedure Init (A : in out App);

    procedure Run (A : in out App);

    procedure Add_Window (A : in out App; W : access Window.Window);

    --  Frame rate management
    procedure Set_Target_FPS (A : in out App; FPS : Positive);
    function Get_Target_FPS (A : App) return Positive;
    function Get_Delta_Time (A : App) return Duration;

private

    type App is tagged record
        Main_Window   : access Window.Window;
        Target_FPS    : Positive := 60;
        Frame_Period  : Ada.Real_Time.Time_Span :=
           Ada.Real_Time.Microseconds (16_667);  -- ~60 FPS
        Last_Frame    : Ada.Real_Time.Time := Ada.Real_Time.Clock;
        Current_Delta : Duration := 0.0;
    end record;
end Adi.App;
