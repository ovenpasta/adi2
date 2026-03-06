with Ada.Finalization;
with Ada.Containers.Vectors;
with Adi.Core;       use Adi.Core;
with Adi.Widget;     use Adi.Widget;
with Adi.Render;     use Adi.Render;
with Adi.SDL.Video;  use Adi.SDL.Video;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Handle_Store;

package Adi.Window is
    type Window is new Ada.Finalization.Limited_Controlled with private;
    type Window_Access is access all Window;
    type Window_Handle is private;
    Null_Window_Handle : constant Window_Handle;

    function Create_Window (Title : String; S : Size_2D) return Window_Access
      with Obsolescent => "Use Create_Window_Handle";
    function Create_Window_Handle (Title : String; S : Size_2D)
      return Window_Handle;
    function Get_Handle (W : Window) return Window_Handle;
    function Is_Valid (H : Window_Handle) return Boolean;
    function Resolve_Window_Handle (H : Window_Handle) return Window_Access;
    type Window_Ref (Ptr : access Window'Class) is
      limited new Ada.Finalization.Limited_Controlled with private
      with Implicit_Dereference => Ptr;
    function Borrow (H : Window_Handle) return Window_Ref;
    procedure Destroy (H : in out Window_Handle);
    procedure Destroy (W : in out Window_Access)
      with Obsolescent => "Use Destroy (H : in out Window_Handle)";
    procedure Pump_Window_Store;

    procedure Update (W : in out Window);

    --  Render the window (draws all widgets)
    procedure Render (W : in out Window);

    --  Set the root widget for this window
    procedure Set_Root (W : in out Window; Root : access Adi.Widget.Widget'Class)
      with Obsolescent => "Use Set_Root with Widget_Handle";
    procedure Set_Root (W : in out Window; Root : Widget_Handle);
    procedure Set_Root (H : Window_Handle; Root : access Adi.Widget.Widget'Class)
      with Obsolescent => "Use Set_Root (H, Root : Widget_Handle)";
    procedure Set_Root (H : Window_Handle; Root : Widget_Handle);
    function Get_Root (W : Window) return Widget_Access
      with Obsolescent => "Use Get_Root_Handle";
    function Get_Root_Handle (W : Window) return Widget_Handle;
    function Get_Root_Handle (H : Window_Handle) return Widget_Handle;
    --  Resolve the host window that currently contains a widget in its
    --  root tree or overlay tree. Returns null if none.
    function Find_Host_Window
      (Node : access Adi.Widget.Widget'Class) return Window_Access;

    --  Optional policy: derive window minimum size from root layout preferred size.
    procedure Set_Enforce_Layout_Min_Size
      (W       : in out Window;
       Enabled : Boolean := True);
    procedure Set_Enforce_Layout_Min_Size
      (H       : Window_Handle;
       Enabled : Boolean := True);
    function Get_Enforce_Layout_Min_Size (W : Window) return Boolean;
    function Get_Enforce_Layout_Min_Size (H : Window_Handle) return Boolean;

    --  Overlay widgets render above the root tree and are hit-tested first.
    --  If focus currently points into an overlay being removed/cleared,
    --  focus is cleared to avoid stale detached targets.
    procedure Add_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class)
      with Obsolescent => "Use Add_Overlay with Widget_Handle";
    procedure Add_Overlay (W : in out Window; Overlay : Widget_Handle);
    procedure Remove_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class)
      with Obsolescent => "Use Remove_Overlay with Widget_Handle";
    procedure Remove_Overlay (W : in out Window; Overlay : Widget_Handle);
    procedure Clear_Overlays (W : in out Window);
    function Overlay_Count (W : Window) return Natural;
    function Get_Overlay (W : Window; Index : Positive) return Widget_Access
      with Pre => Index <= Overlay_Count (W),
           Obsolescent => "Use Get_Overlay_Handle";
    function Get_Overlay_Handle (W : Window; Index : Positive)
      return Widget_Handle
      with Pre => Index <= Overlay_Count (W);
    function Get_Overlay_Handle (H : Window_Handle; Index : Positive)
      return Widget_Handle;
    function Get_Focus (W : Window) return Widget_Access
      with Obsolescent => "Use Get_Focus_Handle";
    function Get_Focus_Handle (W : Window) return Widget_Handle;
    function Get_Focus_Handle (H : Window_Handle) return Widget_Handle;

    --  Clear Focused/Hovered/Pressed refs if they point at Target or any
    --  widget in Target's subtree.  Called from Destroy before detaching.
    procedure Clear_Widget_Refs_In_Subtree
      (W      : in out Window;
       Target : not null access Adi.Widget.Widget'Class);

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

    package Tick_Signals is new Adi.Signal (Tick_Callback, null);

    procedure Connect_Tick
      (W : in out Window; CB : Tick_Callback);
    procedure Connect_Tick
      (H : Window_Handle; CB : Tick_Callback);
    function Connect_Tick
      (W : in out Window; CB : Tick_Callback)
       return Tick_Signals.Connection_Id;
    procedure Disconnect_Tick
      (W : in out Window; Id : Tick_Signals.Connection_Id);

    --  Advance animations by DT seconds on all widgets in this window
    procedure Tick (W : in out Window; DT : Duration);

    --  Destroy overlay and root widget trees eagerly.
    --  Must be called while the caller's scope (and any local generic
    --  instantiations that created widgets) is still alive, because
    --  Unchecked_Deallocation needs valid dispatch tables.
    --  Finalize skips widget destruction when this has already been called.
    procedure Destroy_Widget_Tree (W : in out Window);

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
       Target : access Adi.Widget.Widget'Class)
      with Obsolescent => "Use Set_Focus with Widget_Handle";
    procedure Set_Focus (W : in out Window; Target : Widget_Handle);
    procedure Set_Focus (H : Window_Handle; Target : Widget_Handle);

    --  Force a full re-render on the next frame (e.g. after window exposed).
    procedure Request_Redraw (W : in out Window);

    --  On-screen debug stats overlay (frame count, FPS, render time, layout count)
    procedure Set_Debug_Stats (W : in out Window; Enabled : Boolean);
    procedure Set_Debug_Stats (H : Window_Handle; Enabled : Boolean);

    --  Post-render callback, invoked after all widget rendering (including
    --  debug stats overlay) but before SDL_RenderPresent.
    type Post_Render_Proc is access procedure
      (Win      : not null access Window'Class;
       Renderer : SDL_Renderer_Ptr);

    package Post_Render_Signals is new Adi.Signal (Post_Render_Proc, null);

    procedure Connect_Post_Render
      (W : in out Window; CB : Post_Render_Proc);
    function Connect_Post_Render
      (W : in out Window; CB : Post_Render_Proc)
       return Post_Render_Signals.Connection_Id;
    procedure Disconnect_Post_Render
      (W : in out Window; Id : Post_Render_Signals.Connection_Id);

    --  Per-frame callback, invoked unconditionally every frame regardless of
    --  dirty state.  Use for polling/IPC that must run even when idle.
    type Frame_Proc is access procedure
      (Win : not null access Window'Class);

    package Frame_Signals is new Adi.Signal (Frame_Proc, null);

    procedure Connect_Frame
      (W : in out Window; CB : Frame_Proc);
    function Connect_Frame
      (W : in out Window; CB : Frame_Proc)
       return Frame_Signals.Connection_Id;
    procedure Disconnect_Frame
      (W : in out Window; Id : Frame_Signals.Connection_Id);

    --  Close-request callback. Fired when the user requests window close
    --  (title-bar X) or application quit (Cmd+Q / Alt+F4).
    --  Set Allow to False to prevent closing.
    type Close_Request_Callback is access procedure
      (Win   : not null access Window'Class;
       Allow : in out Boolean);

    package Close_Request_Signals is new Adi.Signal
      (Close_Request_Callback, null);

    procedure Connect_Close_Request
      (W : in out Window; CB : Close_Request_Callback);
    procedure Connect_Close_Request
      (H : Window_Handle; CB : Close_Request_Callback);
    function Connect_Close_Request
      (W : in out Window; CB : Close_Request_Callback)
       return Close_Request_Signals.Connection_Id;
    procedure Disconnect_Close_Request
      (W : in out Window; Id : Close_Request_Signals.Connection_Id);

    --  Emit Close_Request signal. Returns True if close is allowed
    --  (no subscriber vetoed). Called by App.Run; not normally called
    --  by application code.
    function Handle_Close_Request (W : in out Window) return Boolean;

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
        Store_Index    : Natural := 0;
        Store_Gen      : Natural := 0;
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
        Tick_Sig       : Tick_Signals.Signal;
        Post_Render    : Post_Render_Signals.Signal;
        Frame          : Frame_Signals.Signal;
        Close_Request  : Close_Request_Signals.Signal;
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

    type Window_Class_Access is access all Window'Class;

    package Window_Stores is new Adi.Handle_Store
      (Window, Window_Class_Access);

    type Window_Handle is record
       Id : Window_Stores.Object_Id := Window_Stores.Null_Id;
    end record;

    Null_Window_Handle : constant Window_Handle :=
      (Id => Window_Stores.Null_Id);

    type Window_Ref (Ptr : access Window'Class) is
      limited new Ada.Finalization.Limited_Controlled with record
        Id : Window_Stores.Object_Id := Window_Stores.Null_Id;
      end record;
    overriding procedure Finalize (R : in out Window_Ref);
end Adi.Window;
