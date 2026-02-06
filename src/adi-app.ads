with Adi.Window; use Adi.Window;

package Adi.App is

    type App is tagged private;

    procedure Init (A : in out App);

    procedure Run (A : in out App);

    procedure Add_Window (A : in out App; W : access Window.Window);

private

    type App is tagged record
        Main_Window : access Window.Window;
    end record;
end Adi.App;
