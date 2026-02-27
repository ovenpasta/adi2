with Ada.Containers.Vectors;
with Adi.Core;       use Adi.Core;
with Adi.Widget;     use Adi.Widget;
with Adi.Render;     use Adi.Render;
with Adi.SDL.Video;  use Adi.SDL.Video;
with Adi.SDL.Render; use Adi.SDL.Render;
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
    --  Resolve the host window that currently contains a widget in its
    --  root tree or overlay tree. Returns null if none.
    function Find_Host_Window
      (Node : access Adi.Widget.Widget'Class) return Window_Access;

    --  Optional policy: derive window minimum size from root layout preferred size.
    procedure Set_Enforce_Layout_Min_Size
      (W       : in out Window;
       Enabled : Boolean := True);
    function Get_Enforce_Layout_Min_Size (W : Window) return Boolean;

    --  Overlay widgets render above the root tree and are hit-tested first.
    --  If focus currently points into an overlay being removed/cleared,
    --  focus is cleared to avoid stale detached targets.
    procedure Add_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class);
    procedure Remove_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class);
    procedure Clear_Overlays (W : in out Window);
    function Overlay_Count (W : Window) return Natural;

    --  Get the underlying SDL window pointer (for dialog calls, etc.)
    function Get_SDL_Window (W : Window) return SDL_Window_Ptr;

    --  Get the SDL renderer for direct rendering
    function Get_Renderer (W : in out Window) return SDL_Renderer_Ptr;

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

    --  Programmatically set keyboard focus to a widget in this window's
    --  tree or overlay tree.  Pass null to clear focus.  Silently ignored
    --  if Target does not belong to this window.  Non-focusable targets
    --  are ignored by normal focus-candidate validation.
    procedure Set_Focus
      (W      : in out Window;
       Target : access Adi.Widget.Widget'Class);

    --  Force a full re-render on the next frame (e.g. after window exposed).
    procedure Request_Redraw (W : in out Window);

    --  On-screen debug stats overlay (frame count, FPS, render time, layout count)
    procedure Set_Debug_Stats (W : in out Window; Enabled : Boolean);

    --  Post-render callback, invoked after all widget rendering (including
    --  debug stats overlay) but before SDL_RenderPresent.
    type Post_Render_Proc is access procedure
      (Win      : not null access Window'Class;
       Renderer : SDL_Renderer_Ptr);
    procedure Set_Post_Render_Callback
      (W  : in out Window;
       CB : Post_Render_Proc);

    --  Per-frame callback, invoked unconditionally every frame regardless of
    --  dirty state.  Use for polling/IPC that must run even when idle.
    type Frame_Proc is access procedure
      (Win : not null access Window'Class);
    procedure Set_Frame_Callback
      (W  : in out Window;
       CB : Frame_Proc);

    --  Read-only snapshot of per-frame performance stats
    type Frame_Stats is record
       Frame_No      : Natural := 0;
       Render_Us     : Natural := 0;
       Update_Us     : Natural := 0;
       Layout_Us     : Natural := 0;
       Draw_Us       : Natural := 0;
       Present_Us    : Natural := 0;
       Last_DT       : Duration := 0.0;
       Layout_Count  : Natural := 0;
    end record;
    function Get_Frame_Stats (W : Window) return Frame_Stats;
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
        Scroll_Claimed : Boolean       := False;
        Focused_Widget : Widget_Access := null;
        Overlays       : Overlay_Vectors.Vector;
        Enforce_Layout_Min_Size : Boolean := True;
        Needs_Layout   : Boolean       := True;
        Resize_Triggered_Layout : Boolean := False;
        Force_Redraw   : Boolean       := False;
        On_Tick_CB     : Tick_Callback := null;
        Post_Render_CB : Post_Render_Proc := null;
        Frame_CB       : Frame_Proc := null;
        --  Debug stats overlay
        Debug_Stats_On     : Boolean  := False;
        Stats_Frame_No     : Natural  := 0;
        Stats_Layout_Count : Natural  := 0;
        Stats_Render_Us    : Natural  := 0;
        Stats_Update_Us    : Natural  := 0;
        Stats_Layout_Us    : Natural  := 0;
        Stats_Draw_Us      : Natural  := 0;
        Stats_Present_Us   : Natural  := 0;
        Stats_Last_DT      : Duration := 0.0;
        Stats_Layout_Reason : Character := ' ';
        --  Per-frame perf counters (debug stats overlay)
        Stats_Style_Resolves : Natural := 0;
        Stats_Style_Hits     : Natural := 0;
        Stats_Layout_Calls   : Natural := 0;
        Stats_Layout_Skips   : Natural := 0;
        Stats_Pref_Calls     : Natural := 0;
        Stats_Pref_Hits      : Natural := 0;
    end record;

    overriding procedure Initialize (w : in out Window);
    overriding procedure Finalize (W : in out Window);

    --  Helper to find widget at position
    function Find_Widget_At
       (W : Window; X, Y : Pixel_Type) return Widget_Access;
    function Point_In_Widget
       (Wgt : Widget_Access; X, Y : Pixel_Type) return Boolean;
end Adi.Window;
