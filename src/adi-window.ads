--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
with Ada.Containers.Vectors;
with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles;
with Adi.Widget;     use Adi.Widget;
with Adi.Render;     use Adi.Render;
with Adi.SDL.Video;  use Adi.SDL.Video;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Handle_Store;
with Adi.Texture_Cache;

package Adi.Window is
    --  Windows and their handles belong to the thread that runs the
    --  event loop. The handle store is not synchronized, and the
    --  operations below validate a handle and then work through an
    --  unpinned pointer, which only holds while nothing else can destroy
    --  a window in between. A worker task hands work back with
    --  Adi.Dispatch.Post rather than calling these directly; the queue
    --  drains on the event-loop thread, where the same rule applies to
    --  the callback it runs.
    type Window is new Ada.Finalization.Limited_Controlled with private;
    type Window_Handle is private;
    Null_Window_Handle : constant Window_Handle;

    function Create_Window_Handle (Title     : String;
                                    S         : Size_2D;
                                    Maximized : Boolean := False)
      return Window_Handle;

    --  Ask SDL for a particular 2D backend: "opengl", "opengles2",
    --  "vulkan", "gpu", "software". Only a request -- SDL keeps its own
    --  choice if the driver is unavailable, so call Render_Driver
    --  afterwards to find out what happened rather than assuming.
    --
    --  Has to run before the first window is created; SDL reads the hint
    --  when it builds the renderer and ignores it after. Matters to an
    --  application that draws with OpenGL itself, because a GL texture
    --  cannot be handed to a Direct3D or Metal renderer -- and those are
    --  the defaults on Windows and macOS.
    procedure Prefer_Render_Driver (Name : String);

    --  The backend SDL actually built, e.g. "opengl". Empty if the window
    --  has no renderer.
    function Render_Driver (W : Window) return String;
    function Render_Driver (H : Window_Handle) return String;

    --  A window size carrying its own unit, so the caller states whether
    --  it means framebuffer pixels or something that scales with the
    --  display. S : Size_2D above is unchanged: it is handed to SDL as
    --  window coordinates, which equal pixels only where the pixel
    --  density is 1 -- not on macOS or Wayland.
    --
    --    pix  target framebuffer pixels
    --    dp   multiplied by the window's display scale; UI zoom does not
    --         resize the native window
    --    px   uses that display scale when Set_Px_Maps_To_Dip is enabled
    --    %    fraction of the display's usable bounds
    --
    --  A size is a request: window coordinates are integers and the
    --  window manager may constrain them, so the size a window ends up
    --  with is whatever SDL reports afterwards.
    type Window_Extent is private;

    --  Raises Constraint_Error for units that cannot describe a window:
    --  em and rem have no font context here, and vw/vh would resolve
    --  against the viewport being defined.
    function Extent
      (Width, Height : Adi.CSS_Styles.Length_Value) return Window_Extent;

    function Create_Window_Handle (Title     : String;
                                    S         : Window_Extent;
                                    Maximized : Boolean := False)
      return Window_Handle;

    --  Both sizes a caller needs: what the framebuffer should end up
    --  being, and what SDL_CreateWindow/SDL_SetWindowSize take, which is
    --  the same thing divided by the window's pixel density. The two
    --  differ on macOS and Wayland.
    type Resolved_Extent is record
       Pixels : Size_2D;
       Coords : Size_2D;
    end record;

    --  Pure: every input is explicit so the platform combinations can be
    --  tested without a display. Usable is in window coordinates, as SDL
    --  reports display bounds.
    function Resolve_Extent
      (E              : Window_Extent;
       Display_Scale  : Pixel_Type;
       Pixel_Density  : Pixel_Type;
       Usable         : Size_2D;
       Px_Maps_To_Dip : Boolean) return Resolved_Extent;
    function Get_Handle (W : Window) return Window_Handle;
    function Is_Valid (H : Window_Handle) return Boolean;
    type Window_Ref (Ptr : access Window'Class) is
      limited new Ada.Finalization.Limited_Controlled with private
      with Implicit_Dereference => Ptr;
    function Borrow (H : Window_Handle) return Window_Ref;
    procedure Destroy (H : in out Window_Handle);
    procedure Pump_Window_Store;

    procedure Update (W : in out Window);

    --  Render the window (draws all widgets)
    procedure Render (W : in out Window);

    --  Set the root widget for this window
    procedure Set_Root (W : in out Window; Root : Widget_Handle);
    procedure Set_Root (H : Window_Handle; Root : Widget_Handle);
    function Get_Root_Handle (W : Window) return Widget_Handle;
    function Get_Root_Handle (H : Window_Handle) return Widget_Handle;
    --  The window that currently contains a widget in its root tree or
    --  overlay tree. Null_Window_Handle when no live window does.
    function Find_Host_Window
      (Node : Widget_Handle) return Window_Handle;

    --  Optional policy: derive window minimum size from root layout preferred size.
    procedure Set_Enforce_Layout_Min_Size
      (W       : in out Window;
       Enabled : Boolean := True);
    procedure Set_Enforce_Layout_Min_Size
      (H       : Window_Handle;
       Enabled : Boolean := True);
    function Get_Enforce_Layout_Min_Size (W : Window) return Boolean;
    function Get_Enforce_Layout_Min_Size (H : Window_Handle) return Boolean;

    --  App-level user scaling layered on top of the OS display scale.
    --  UI scale affects logical layout units such as dp/dip.
    --  Text scale affects font-related pixel conversion only.
    --  Both settings are currently process-global; setting them through a
    --  window also invalidates that window's root and overlays for relayout.
    procedure Set_UI_Scale (W : in out Window; Scale : Pixel_Type);
    procedure Set_UI_Scale (H : Window_Handle; Scale : Pixel_Type);
    function Get_UI_Scale (W : Window) return Pixel_Type;
    function Get_UI_Scale (H : Window_Handle) return Pixel_Type;

    procedure Set_Text_Scale (W : in out Window; Scale : Pixel_Type);
    procedure Set_Text_Scale (H : Window_Handle; Scale : Pixel_Type);
    function Get_Text_Scale (W : Window) return Pixel_Type;
    function Get_Text_Scale (H : Window_Handle) return Pixel_Type;

    --  Root font size used for CSS `rem` units (default 16px).
    --  Accepts any CSS length unit (px, dip, vh, …); the pixel value is
    --  recomputed each frame so dip/vh values track the current scale.
    --  Setting this through a window invalidates the window for relayout.
    procedure Set_Root_Font_Size
      (W    : in out Window;
       Size : Adi.CSS_Styles.Length_Value);
    procedure Set_Root_Font_Size
      (H    : Window_Handle;
       Size : Adi.CSS_Styles.Length_Value);
    function Get_Root_Font_Size (W : Window)
      return Adi.CSS_Styles.Length_Value;
    function Get_Root_Font_Size (H : Window_Handle)
      return Adi.CSS_Styles.Length_Value;

    --  Window state control. SDL may not honor all requests on every platform
    --  (e.g. tiling window managers may ignore maximize/fullscreen).
    procedure Maximize       (W : in out Window);
    procedure Maximize       (H : Window_Handle);
    procedure Minimize       (W : in out Window);
    procedure Minimize       (H : Window_Handle);
    procedure Restore        (W : in out Window);
    procedure Restore        (H : Window_Handle);
    procedure Set_Fullscreen (W : in out Window; Enabled : Boolean);
    procedure Set_Fullscreen (H : Window_Handle; Enabled : Boolean);
    function  Is_Maximized   (W : Window)        return Boolean;
    function  Is_Maximized   (H : Window_Handle) return Boolean;
    function  Is_Minimized   (W : Window)        return Boolean;
    function  Is_Minimized   (H : Window_Handle) return Boolean;
    function  Is_Fullscreen  (W : Window)        return Boolean;
    function  Is_Fullscreen  (H : Window_Handle) return Boolean;

    --  Overlay widgets render above the root tree and are hit-tested first.
    --  Focus, hover and pressed state pointing into an overlay being
    --  removed/cleared are released, so an overlay shown again comes back
    --  in the state it would have if it had just been built.
    procedure Add_Overlay (W : in out Window; Overlay : Widget_Handle);
    procedure Remove_Overlay (W : in out Window; Overlay : Widget_Handle);
    procedure Clear_Overlays (W : in out Window);

    --  Where a widget actually is on screen: its stored geometry with
    --  its ancestors' scrolling undone. Overlays are placed in window
    --  space, so anything anchored to a widget — a dropdown under its
    --  combo box, say — must use this rather than Get_Geometry, or it
    --  will sit where the widget would be if nothing had scrolled.
    function Geometry_In_Window (Wgt : Widget_Handle) return Rectangle;

    --  Same conversion for a rectangle already expressed in Adi's stored
    --  layout coordinates — one derived from Get_Geometry, not a
    --  widget-local rectangle: this does not offset by the widget's own
    --  position. Prefer Geometry_In_Window unless you have adjusted the
    --  rectangle yourself.
    function To_Window_Space
       (Wgt : Widget_Handle; R : Rectangle) return Rectangle;
    function Overlay_Count (W : Window) return Natural;
    function Get_Overlay_Handle (W : Window; Index : Positive)
      return Widget_Handle
      with Pre => Index <= Overlay_Count (W);
    function Get_Overlay_Handle (H : Window_Handle; Index : Positive)
      return Widget_Handle;
    function Get_Focus_Handle (W : Window) return Widget_Handle;
    function Get_Focus_Handle (H : Window_Handle) return Widget_Handle;

    procedure Add_Overlay    (H : Window_Handle; Overlay : Widget_Handle);
    procedure Remove_Overlay (H : Window_Handle; Overlay : Widget_Handle);
    procedure Clear_Overlays (H : Window_Handle);
    function  Overlay_Count  (H : Window_Handle) return Natural;
    function  Get_Size       (H : Window_Handle) return Size_2D;

    --  Render / resize / input via handle
    procedure Render        (H : Window_Handle);
    procedure Handle_Resize (H : Window_Handle; New_Size : Size_2D);
    function  Get_SDL_Window (H : Window_Handle) return SDL_Window_Ptr;
    procedure On_Mouse_Wheel
       (H                : Window_Handle;
        X, Y             : Pixel_Type;
        Delta_X, Delta_Y : Pixel_Type);
    procedure On_Key_Down
       (H        : Window_Handle;
        Scancode : Adi.SDL.Events.SDL_Scancode;
        Keycode  : Adi.SDL.Events.SDL_Keycode;
        Key_Mod  : Adi.SDL.Events.SDL_Keymod;
        Repeat   : Boolean);
    procedure On_Key_Up
       (H        : Window_Handle;
        Scancode : Adi.SDL.Events.SDL_Scancode;
        Key_Mod  : Adi.SDL.Events.SDL_Keymod;
        Repeat   : Boolean);

    --  Clear Focused/Hovered/Pressed refs if they point at Target or any
    --  widget in Target's subtree, releasing the state those widgets hold
    --  along with the reference.  Hover above the subtree is left alone:
    --  the pointer has not moved, so Target's parent takes over as the
    --  hovered widget.  Called from Destroy before detaching.
    procedure Clear_Widget_Refs_In_Subtree
      (W      : in out Window;
       Target : Widget_Handle);

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
        Keycode  : Adi.SDL.Events.SDL_Keycode;
        Key_Mod  : Adi.SDL.Events.SDL_Keymod;
        Repeat   : Boolean);
    procedure On_Key_Up
       (W        : in out Window;
        Scancode : Adi.SDL.Events.SDL_Scancode;
        Key_Mod  : Adi.SDL.Events.SDL_Keymod;
        Repeat   : Boolean);
    procedure On_Text_Input (W : in out Window; Text : String);

    ---------------------------------------------------------------------
    --  The same operations by handle.  A handle that no longer resolves
    --  is not an error here: a procedure does nothing, and a function
    --  answers the value that means "no window" -- null, zero, False.
    --  Handle_Close_Request answers True, because a window that is gone
    --  cannot veto closing.
    ---------------------------------------------------------------------

    function  Get_Renderer         (H : Window_Handle) return SDL_Renderer_Ptr;
    procedure Request_Redraw       (H : Window_Handle);
    function  Handle_Close_Request (H : Window_Handle) return Boolean;
    function  Actual_Size          (H : Window_Handle) return Size_2D;
    procedure Tick                 (H : Window_Handle; DT : Duration);
    procedure On_Text_Input        (H : Window_Handle; Text : String);
    procedure On_Mouse_Move        (H : Window_Handle; X, Y : Pixel_Type);
    procedure On_Mouse_Down
       (H      : Window_Handle;
        X, Y   : Pixel_Type;
        Button : Mouse_Button;
        Clicks : Natural := 1);
    procedure On_Mouse_Up
       (H      : Window_Handle;
        X, Y   : Pixel_Type;
        Button : Mouse_Button);

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
    function Connect_Tick
      (H : Window_Handle; CB : Tick_Callback)
       return Tick_Signals.Connection_Id;
    procedure Disconnect_Tick
      (H : Window_Handle; Id : Tick_Signals.Connection_Id);

    --  Window-level key-down hook.  Fires for every key-down event the
    --  window receives, regardless of which (if any) widget currently
    --  has focus, BEFORE the event reaches the focused widget.  Set
    --  Handled := True to consume the event — the focused widget will
    --  not see it.  Leave Handled untouched (it stays False) to let the
    --  event continue through the normal focus-dispatch path.  This is
    --  the right hook for app-wide shortcuts (Esc, function keys,
    --  Ctrl+combinations) that should win over widget-local behaviour.
    --
    --  Scancode is the physical key position (US-layout); Keycode is the
    --  post-layout character (typically an ASCII/Unicode code point).
    --  Match on Keycode when you want layout-independent shortcuts (e.g.
    --  `+` / `-` for zoom — these live at different physical positions
    --  on AZERTY / QWERTZ / Italian QWERTY); match on Scancode for keys
    --  with no printable character (arrows, function keys, Esc, Home).
    type Key_Down_Callback is access procedure
      (Scancode : Adi.SDL.Events.SDL_Scancode;
       Keycode  : Adi.SDL.Events.SDL_Keycode;
       Key_Mod  : Adi.SDL.Events.SDL_Keymod;
       Repeat   : Boolean;
       Handled  : in out Boolean);

    package Key_Down_Signals is new Adi.Signal (Key_Down_Callback, null);

    procedure Connect_Key_Down
      (W : in out Window; CB : Key_Down_Callback);
    procedure Connect_Key_Down
      (H : Window_Handle; CB : Key_Down_Callback);
    function Connect_Key_Down
      (W : in out Window; CB : Key_Down_Callback)
       return Key_Down_Signals.Connection_Id;
    procedure Disconnect_Key_Down
      (W : in out Window; Id : Key_Down_Signals.Connection_Id);
    function Connect_Key_Down
      (H : Window_Handle; CB : Key_Down_Callback)
       return Key_Down_Signals.Connection_Id;
    procedure Disconnect_Key_Down
      (H : Window_Handle; Id : Key_Down_Signals.Connection_Id);

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
    procedure Set_Focus (W : in out Window; Target : Widget_Handle);
    procedure Set_Focus (H : Window_Handle; Target : Widget_Handle);

    --  Force a full re-render on the next frame (e.g. after window exposed).
    procedure Request_Redraw (W : in out Window);

    --  On-screen debug stats overlay (frame count, FPS, render time, layout count)
    procedure Set_Debug_Stats (W : in out Window; Enabled : Boolean);
    procedure Set_Debug_Stats (H : Window_Handle; Enabled : Boolean);

    --  How many bytes of GPU textures this window keeps resident, defaulting
    --  to Adi.Render.Default_Texture_Budget. Per window rather than per
    --  process: a texture belongs to the renderer that made it, so two
    --  windows cannot share one.
    --
    --  Lowering it evicts down to the new figure at once, except for entries
    --  a draw currently holds.
    procedure Set_Texture_Budget
      (W : in out Window; Bytes : Adi.Texture_Cache.Byte_Count);
    procedure Set_Texture_Budget
      (H : Window_Handle; Bytes : Adi.Texture_Cache.Byte_Count);

    --  What the cache holds now, for a program sizing its budget against
    --  what it actually uses. Frames counts only the frames this window
    --  drew, which is what the cache ages entries by.
    subtype Texture_Stats is Adi.Render.Texture_Stats;

    function Get_Texture_Stats (W : Window) return Texture_Stats;
    function Get_Texture_Stats (H : Window_Handle) return Texture_Stats;

    --  Post-render callback, invoked after all widget rendering (including
    --  debug stats overlay) but before SDL_RenderPresent.
    type Post_Render_Proc is access procedure
      (Win      : Window_Handle;
       Renderer : SDL_Renderer_Ptr);

    package Post_Render_Signals is new Adi.Signal (Post_Render_Proc, null);

    procedure Connect_Post_Render
      (W : in out Window; CB : Post_Render_Proc);
    function Connect_Post_Render
      (W : in out Window; CB : Post_Render_Proc)
       return Post_Render_Signals.Connection_Id;
    procedure Disconnect_Post_Render
      (W : in out Window; Id : Post_Render_Signals.Connection_Id);
    procedure Connect_Post_Render
      (H : Window_Handle; CB : Post_Render_Proc);
    function Connect_Post_Render
      (H : Window_Handle; CB : Post_Render_Proc)
       return Post_Render_Signals.Connection_Id;
    procedure Disconnect_Post_Render
      (H : Window_Handle; Id : Post_Render_Signals.Connection_Id);

    --  Per-frame callback, invoked unconditionally every frame regardless of
    --  dirty state.  Use for polling/IPC that must run even when idle.
    type Frame_Proc is access procedure (Win : Window_Handle);

    package Frame_Signals is new Adi.Signal (Frame_Proc, null);

    procedure Connect_Frame
      (W : in out Window; CB : Frame_Proc);
    function Connect_Frame
      (W : in out Window; CB : Frame_Proc)
       return Frame_Signals.Connection_Id;
    procedure Disconnect_Frame
      (W : in out Window; Id : Frame_Signals.Connection_Id);
    procedure Connect_Frame
      (H : Window_Handle; CB : Frame_Proc);
    function Connect_Frame
      (H : Window_Handle; CB : Frame_Proc)
       return Frame_Signals.Connection_Id;
    procedure Disconnect_Frame
      (H : Window_Handle; Id : Frame_Signals.Connection_Id);

    --  Close-request callback. Fired when the user requests window close
    --  (title-bar X) or application quit (Cmd+Q / Alt+F4).
    --  Set Allow to False to prevent closing.
    type Close_Request_Callback is access procedure
      (Win   : Window_Handle;
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
    function Connect_Close_Request
      (H : Window_Handle; CB : Close_Request_Callback)
       return Close_Request_Signals.Connection_Id;
    procedure Disconnect_Close_Request
      (H : Window_Handle; Id : Close_Request_Signals.Connection_Id);

    --  Emit Close_Request signal. Returns True if close is allowed
    --  (no subscriber vetoed). Called by App.Run; not normally called
    --  by application code.
    function Handle_Close_Request (W : in out Window) return Boolean;

    --  Read-only snapshot of per-frame performance stats. The counters
    --  are those of Adi.Widget over the whole frame, drawing included:
    --  Style_Hits, Style_Memo_Hits and Style_Computes partition
    --  Style_Resolves between the per-widget cache, the global memo and
    --  the cascade.
    type Frame_Stats is record
       Frame_No        : Natural := 0;
       Render_Us       : Natural := 0;
       Update_Us       : Natural := 0;
       Layout_Us       : Natural := 0;
       Draw_Us         : Natural := 0;
       Present_Us      : Natural := 0;
       Last_DT         : Duration := 0.0;
       Layout_Count    : Natural := 0;
       Style_Resolves  : Natural := 0;
       Style_Hits      : Natural := 0;
       Style_Memo_Hits : Natural := 0;
       Style_Computes  : Natural := 0;
       Layout_Calls    : Natural := 0;
       Layout_Skips    : Natural := 0;
       Pref_Calls      : Natural := 0;
       Pref_Hits       : Natural := 0;
    end record;
    function Get_Frame_Stats (W : Window) return Frame_Stats;
    function Get_Frame_Stats (H : Window_Handle) return Frame_Stats;
private

    type Window_Extent is record
       Width, Height : Adi.CSS_Styles.Length_Value;
    end record;

    package Overlay_Vectors is new Ada.Containers.Vectors (Positive, Widget_Handle);

    type Internal;
    type Internal_Access is access Internal;
    type Window is new Ada.Finalization.Limited_Controlled with record
        Internal       : Internal_Access;
        Store_Index    : Natural := 0;
        Store_Gen      : Natural := 0;
        Ctx            : Render_Context;
        Root           : Widget_Handle := Null_Handle;
        Geometry       : Rectangle;
        Size           : Size_2D;  -- NEW: Track current size
        --  Track mouse state
        Mouse_X        : Pixel_Type    := 0.0;
        Mouse_Y        : Pixel_Type    := 0.0;
        Mouse_Down     : Boolean       := False;
        Hovered_Widget : Widget_Handle := Null_Handle;
        Pressed_Widget : Widget_Handle := Null_Handle;
        Hovered_Part   : Part_Kind     := Main_Part;
        Pressed_Part   : Part_Kind     := Main_Part;
        Scroll_Claimed : Boolean       := False;
        Focused_Widget : Widget_Handle := Null_Handle;
        Overlays       : Overlay_Vectors.Vector;
        Root_Font_Size  : Adi.CSS_Styles.Length_Value :=
                            (Amount => 16.0, Unit => Adi.CSS_Styles.Px);
        Enforce_Layout_Min_Size : Boolean := True;
        Needs_Layout   : Boolean       := True;
        Resize_Triggered_Layout : Boolean := False;
        Force_Redraw   : Boolean       := False;
        Tick_Sig       : Tick_Signals.Signal;
        Key_Down_Sig   : Key_Down_Signals.Signal;
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
        Stats_Style_Resolves  : Natural := 0;
        Stats_Style_Hits      : Natural := 0;
        Stats_Style_Memo_Hits : Natural := 0;
        Stats_Style_Computes  : Natural := 0;
        Stats_Layout_Calls    : Natural := 0;
        Stats_Layout_Skips    : Natural := 0;
        Stats_Pref_Calls      : Natural := 0;
        Stats_Pref_Hits       : Natural := 0;
    end record;

    overriding procedure Initialize (w : in out Window);
    overriding procedure Finalize (W : in out Window);

    --  Helper to find widget at position
    function Find_Widget_At
       (W : Window; X, Y : Pixel_Type) return Widget_Handle;
    function Point_In_Widget
       (Wgt : Widget_Handle; X, Y : Pixel_Type) return Boolean;

    type Window_Class_Access is access all Window'Class;

    package Window_Stores is new Adi.Handle_Store
      (Window, Window_Class_Access);

    type Window_Handle is record
       Id : Window_Stores.Object_Id := Window_Stores.Null_Id;
    end record;

    Null_Window_Handle : constant Window_Handle :=
      (Id => Window_Stores.Null_Id);

    type Window_Access is access all Window;

    type Window_Ref (Ptr : access Window'Class) is
      limited new Ada.Finalization.Limited_Controlled with record
        Id : Window_Stores.Object_Id := Window_Stores.Null_Id;
      end record;
    overriding procedure Finalize (R : in out Window_Ref);
end Adi.Window;
