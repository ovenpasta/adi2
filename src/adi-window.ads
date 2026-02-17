with Ada.Containers.Vectors;
with Adi.Core;       use Adi.Core;
with Adi.Widget;     use Adi.Widget;
with Adi.Render;     use Adi.Render;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.Image;      use Adi.Image;
with Adi.Animated_Image; use Adi.Animated_Image;
with Adi.SDL.Events;
with System;

package Adi.Window is
    type Window is new Ada.Finalization.Limited_Controlled with private;
    type Window_Access is access all Window;

    function Create_Window (Title : String; S : Size_2D) return Window_Access;

    procedure Update (W : in out Window);

    --  Render the window (draws all widgets)
    procedure Render (W : in out Window);

    --  Set the root widget for this window
    procedure Set_Root (W : in out Window; Root : access Adi.Widget.Widget'Class);
    function Get_Root (W : Window) return Widget_Access;

    --  Optional policy: derive window minimum size from root layout preferred size.
    procedure Set_Enforce_Layout_Min_Size
      (W       : in out Window;
       Enabled : Boolean := True);
    function Get_Enforce_Layout_Min_Size (W : Window) return Boolean;

    --  Overlay widgets render above the root tree and are hit-tested first.
    procedure Add_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class);
    procedure Remove_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class);
    procedure Clear_Overlays (W : in out Window);
    function Overlay_Count (W : Window) return Natural;

    --  Get the SDL renderer for direct rendering
    function Get_Renderer (W : in out Window) return SDL_Renderer_Ptr;

    --  Image loading convenience function
    --  Loads an image using the window's renderer
    function Load_Image
       (W    : in out Window;
        Path : String) return Image_Access;

    --  Animated image loading convenience function.
    function Load_Animated_Image
       (W    : in out Window;
        Path : String) return Animated_Image_Access;

    --  Mouse event handling
    procedure On_Mouse_Move (W : in out Window; X, Y : Pixel_Type);
    procedure On_Mouse_Down
       (W      : in out Window;
        X, Y   : Pixel_Type;
        Button : Adi.Core.Mouse_Button;
        Clicks : Natural := 1);
    procedure On_Mouse_Up
       (W : in out Window; X, Y : Pixel_Type; Button : Adi.Core.Mouse_Button);
    procedure On_Mouse_Wheel
       (W                : in out Window;
        X, Y             : Pixel_Type;
        Delta_X, Delta_Y : Pixel_Type);
    procedure On_Key_Down
       (W        : in out Window;
        Scancode : Adi.SDL.Events.SDL_Scancode;
        Key_Mod  : Adi.SDL.Events.SDL_Keymod;
        Repeat   : Boolean);
    procedure On_Key_Up
       (W        : in out Window;
        Scancode : Adi.SDL.Events.SDL_Scancode;
        Key_Mod  : Adi.SDL.Events.SDL_Keymod;
        Repeat   : Boolean);
    procedure On_Text_Input (W : in out Window; Text : String);

    --  Per-frame callback, invoked before animations
    type Tick_Callback is access procedure (DT : Duration);
    procedure Set_On_Tick (W : in out Window; CB : Tick_Callback);

    --  Advance animations by DT seconds on all widgets in this window
    procedure Tick (W : in out Window; DT : Duration);

    procedure Reshape (W : in out Window; SZ : Size_2D);
    function Get_Size (W : in out Window) return Size_2D;
    function Actual_Size (W : in out Window) return Size_2D;
    --  Resize handling
    procedure Handle_Resize (W : in out Window; New_Size : Size_2D);
private
    package Overlay_Vectors is new Ada.Containers.Vectors (Positive, Widget_Access);

    type Internal;
    type Internal_Access is access Internal;
    type Window is new Ada.Finalization.Limited_Controlled with record
        Internal       : Internal_Access;
        Ctx            : Render_Context;
        Root           : Widget_Access;
        Geometry       : Rectangle;
        Size           : Size_2D;  -- NEW: Track current size
        --  Track mouse state
        Mouse_X        : Pixel_Type    := 0.0;
        Mouse_Y        : Pixel_Type    := 0.0;
        Mouse_Down     : Boolean       := False;
        Hovered_Widget : Widget_Access := null;
        Pressed_Widget : Widget_Access := null;
        Hovered_Part   : Part_Kind     := Main_Part;
        Pressed_Part   : Part_Kind     := Main_Part;
        Focused_Widget : Widget_Access := null;
        Overlays       : Overlay_Vectors.Vector;
        Enforce_Layout_Min_Size : Boolean := True;
        Needs_Layout   : Boolean       := True;
        On_Tick_CB     : Tick_Callback := null;
    end record;

    overriding procedure Initialize (w : in out Window);
    overriding procedure Finalize (W : in out Window);

    --  Helper to find widget at position
    function Find_Widget_At
       (W : Window; X, Y : Pixel_Type) return Widget_Access;
    function Point_In_Widget
       (Wgt : Widget_Access; X, Y : Pixel_Type) return Boolean;
end Adi.Window;
