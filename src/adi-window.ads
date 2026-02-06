with Adi.Core;       use Adi.Core;
with Adi.Event;      use Adi.Event;
with Adi.Widget;     use Adi.Widget;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.Image;      use Adi.Image;
with System;

package Adi.Window is
    type Window is new Ada.Finalization.Limited_Controlled with private;
    type Window_Access is access all Window;

    type Mouse_Button is
       (Left_Button, Middle_Button, Right_Button, X1_Button, X2_Button);

    function Create_Window (Title : String; S : Size_2D) return Window_Access;

    procedure On_Event (W : in out Window; E : Event.Event);
    procedure Update (W : in out Window);

    --  Render the window (draws all widgets)
    procedure Render (W : in out Window);

    --  Set the root widget for this window
    procedure Set_Root (W : in out Window; Root : Widget_Access);
    function Get_Root (W : Window) return Widget_Access;

    --  Get the SDL renderer for direct rendering
    function Get_Renderer (W : in out Window) return SDL_Renderer_Ptr;

    --  Image loading convenience function
    --  Loads an image using the window's renderer
    function Load_Image
       (W    : in out Window;
        Path : String) return Image_Access;

    --  Mouse event handling
    procedure On_Mouse_Move (W : in out Window; X, Y : Pixel_Type);
    procedure On_Mouse_Down
       (W : in out Window; X, Y : Pixel_Type; Button : Mouse_Button);
    procedure On_Mouse_Up
       (W : in out Window; X, Y : Pixel_Type; Button : Mouse_Button);

    procedure Reshape (W : in out Window; SZ : Size_2D);
    function Get_Size (W : in out Window) return Size_2D;
    function Actual_Size (W : in out Window) return Size_2D;
    --  Resize handling
    procedure Handle_Resize (W : in out Window; New_Size : Size_2D);
private
    type Internal;
    type Internal_Access is access Internal;
    type Window is new Ada.Finalization.Limited_Controlled with record
        Internal       : Internal_Access;
        Root           : Widget_Access;
        Geometry       : Rectangle;
        Size           : Size_2D;  -- NEW: Track current size
        --  Track mouse state
        Mouse_X        : Pixel_Type    := 0.0;
        Mouse_Y        : Pixel_Type    := 0.0;
        Mouse_Down     : Boolean       := False;
        Hovered_Widget : Widget_Access := null;
        Pressed_Widget : Widget_Access := null;
        Needs_Layout   : Boolean       := True;
    end record;

    overriding procedure Initialize (w : in out Window);
    overriding procedure Finalize (W : in out Window);

    --  Helper to find widget at position
    function Find_Widget_At
       (W : Window; X, Y : Pixel_Type) return Widget_Access;
    function Point_In_Widget
       (Wgt : Widget_Access; X, Y : Pixel_Type) return Boolean;
end Adi.Window;
