pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;  use Ada.Text_IO;
with Adi.SDL;      use Adi.SDL;
with Adi.SDL.TTF;
with Adi.SDL.Events;
with Adi.SDL.Render;
with Adi.Core;
with Adi.Window;   use Adi.Window;
with Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Test_Support;

procedure Window_Handle_Test is
   use type Adi.Widget.Widget_Handle;
   use type Adi.Core.Size_2D;
   use type Adi.SDL.Render.SDL_Renderer_Ptr;
   use type Tick_Signals.Connection_Id;
   use type Key_Down_Signals.Connection_Id;
   use type Post_Render_Signals.Connection_Id;
   use type Frame_Signals.Connection_Id;
   use type Close_Request_Signals.Connection_Id;
   SDL_Ready  : Boolean := False;

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok     : Adi.SDL.C_bool;
      Ttf_Ok : Adi.SDL.C_bool;
   begin
      if SDL_Ready then
         Ready := True;
         return;
      end if;

      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Test_Support.Assert (Ready, "SDL_Init(video|events) should succeed");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ttf_Ok);
         Test_Support.Assert (Ready, "TTF_Init should succeed");
      end if;

      SDL_Ready := Ready;
   end Ensure_SDL_Initialized;

   procedure On_Window_Tick (DT : Duration) is
      pragma Unreferenced (DT);
   begin
      null;
   end On_Window_Tick;

   procedure On_Window_Key
     (Scancode : Adi.SDL.Events.SDL_Scancode;
      Keycode  : Adi.SDL.Events.SDL_Keycode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean;
      Handled  : in out Boolean)
   is
      pragma Unreferenced (Scancode, Keycode, Key_Mod, Repeat, Handled);
   begin
      null;
   end On_Window_Key;

   procedure On_Post_Render
     (Win      : Window_Handle;
      Renderer : Adi.SDL.Render.SDL_Renderer_Ptr)
   is
      pragma Unreferenced (Win, Renderer);
   begin
      null;
   end On_Post_Render;

   procedure On_Frame (Win : Window_Handle) is
      pragma Unreferenced (Win);
   begin
      null;
   end On_Frame;

   procedure On_Close_Request
     (Win : Window_Handle; Allow : in out Boolean)
   is
      pragma Unreferenced (Win, Allow);
   begin
      null;
   end On_Close_Request;

   procedure Allow_Close
     (Win   : Window_Handle;
      Allow : in out Boolean)
   is
      pragma Unreferenced (Win);
   begin
      Allow := True;
   end Allow_Close;

   procedure Test_Null_Handle is
   begin
      Put_Line ("Test: Null_Window_Handle is invalid");
      Test_Support.Assert (not Is_Valid (Null_Window_Handle),
              "Null_Window_Handle should be invalid");
      Test_Support.Assert (Resolve_Window_Handle (Null_Window_Handle) = null,
              "Null_Window_Handle resolves to null");
   end Test_Null_Handle;

   procedure Test_Create_Window_Handle is
      Ready : Boolean := False;
      H     : Window_Handle;
   begin
      Put_Line ("Test: Create_Window_Handle returns a valid handle");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Window Handle Test", (320.0, 240.0));
      Test_Support.Assert (Is_Valid (H), "Create_Window_Handle returns valid handle");
      Test_Support.Assert (Resolve_Window_Handle (H) /= null,
              "Resolve_Window_Handle(valid) is non-null");

      Destroy (H);
      Test_Support.Assert (not Is_Valid (H), "Destroy(handle) invalidates handle");
   end Test_Create_Window_Handle;

   procedure Test_Handle_Overloads is
      Ready  : Boolean := False;
      H      : Window_Handle;
      Root_H : Box_Handle;
   begin
      Put_Line ("Test: Window handle overloads");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Window Handle Overloads", (420.0, 260.0));
      Root_H := Create_Handle;

      Set_Root (H, +Root_H);
      Set_Debug_Stats (H, True);
      Set_Enforce_Layout_Min_Size (H, True);
      Test_Support.Assert (Get_Enforce_Layout_Min_Size (H),
              "Get_Enforce_Layout_Min_Size(handle) should be True");

      Connect_Tick (H, On_Window_Tick'Unrestricted_Access);
      Connect_Close_Request (H, Allow_Close'Unrestricted_Access);

      Destroy (H);
      Test_Support.Assert (not Is_Valid (H), "Destroy(handle) after overload usage");
   end Test_Handle_Overloads;

   procedure Test_Destroy_By_Handle is
      Ready : Boolean := False;
      H     : Window_Handle;
   begin
      Put_Line ("Test: Destroy by Window_Handle");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Destroy Handle", (320.0, 240.0));
      Test_Support.Assert (Is_Valid (H), "handle valid before destroy");

      Destroy (H);
      Test_Support.Assert (not Is_Valid (H), "handle invalid after destroy");
      Test_Support.Assert (Resolve_Window_Handle (H) = null,
              "resolve after destroy returns null");
   end Test_Destroy_By_Handle;

   procedure Test_Destroy_Idempotent is
      Ready : Boolean := False;
      H     : Window_Handle;
   begin
      Put_Line ("Test: Destroy is idempotent");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Destroy Idempotent", (320.0, 240.0));
      Destroy (H);
      Destroy (H);
      Test_Support.Assert (not Is_Valid (H), "double destroy leaves handle invalid");
   end Test_Destroy_Idempotent;

   --  The window is told a widget is going away while that widget is
   --  still in its tree, because that membership is how the window is
   --  found.  Notifying after detachment would leave the window holding
   --  a handle to a destroyed widget.
   procedure Test_Destroy_Clears_Window_Refs is
      Ready : Boolean;
      W     : Window_Handle;
      Root  : Box_Handle;
      Child : Box_Handle;
      Child_H : Adi.Widget.Widget_Handle;
   begin
      Put_Line ("Test: destroying a focused descendant clears the window");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W     := Create_Window_Handle ("Destroy Refs", (320.0, 240.0));
      Root  := Create_Handle;
      Child := Create_Handle;
      Adi.Widget.Add_Child (+Root, +Child);
      Set_Root (W, +Root);

      Child_H := +Child;
      Adi.Widget.Set_Flag (Child_H, Adi.Widget.Focusable, True);
      Set_Focus (W, Child_H);
      Test_Support.Assert (Get_Focus_Handle (W) = Child_H,
                           "the child holds focus before the destroy");

      Adi.Widget.Destroy (Child_H);
      Adi.Widget.Pump_Widget_Store;

      --  Not merely "no longer the child": the window must hold
      --  Null_Handle, never a stale handle that happens to compare
      --  unequal.
      Test_Support.Assert
        (Get_Focus_Handle (W) = Adi.Widget.Null_Handle,
         "focus is Null_Handle, not the destroyed child's stale handle");

      --  Destroying the root clears the window's root the same way.
      declare
         Root_H : Adi.Widget.Widget_Handle := +Root;
      begin
         Adi.Widget.Destroy (Root_H);
         Adi.Widget.Pump_Widget_Store;
         Test_Support.Assert
           (Get_Root_Handle (W) = Adi.Widget.Null_Handle,
            "root is Null_Handle after the root widget is destroyed");
      end;

      Destroy (W);
   end Test_Destroy_Clears_Window_Refs;

   --  An overlay is reachable from the window without being in the root
   --  tree, so it is a separate path through Find_Host_Window.
   procedure Test_Destroy_Removes_Overlay is
      Ready   : Boolean;
      W       : Window_Handle;
      Root    : Box_Handle;
      Overlay : Box_Handle;
      Over_H  : Adi.Widget.Widget_Handle;
   begin
      Put_Line ("Test: destroying an overlay removes it from the window");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W       := Create_Window_Handle ("Destroy Overlay", (320.0, 240.0));
      Root    := Create_Handle;
      Overlay := Create_Handle;
      Set_Root (W, +Root);
      Add_Overlay (W, +Overlay);
      Test_Support.Assert (Overlay_Count (W) = 1, "overlay added");

      Over_H := +Overlay;
      Adi.Widget.Destroy (Over_H);
      Adi.Widget.Pump_Widget_Store;

      Test_Support.Assert (Overlay_Count (W) = 0,
                           "the destroyed overlay is off the window");

      Destroy (W);

      --  Answering about a window rather than acting on one: a handle
      --  that no longer resolves counts zero instead of raising.
      Test_Support.Assert (Overlay_Count (W) = 0,
                           "Overlay_Count of a destroyed window is 0");
      Test_Support.Assert (Overlay_Count (Null_Window_Handle) = 0,
                           "Overlay_Count of Null_Window_Handle is 0");
   end Test_Destroy_Removes_Overlay;

   --  Destroy nulls the handle it is given, so destroying the same
   --  variable twice never reaches a stale id.  A copy does.
   procedure Test_Destroy_Stale_Copy is
      Ready : Boolean;
      H     : Window_Handle;
      Copy  : Window_Handle;
   begin
      Put_Line ("Test: destroying a stale copy");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Destroy Stale Copy", (320.0, 240.0));
      Copy := H;
      Destroy (H);
      Pump_Window_Store;

      Test_Support.Assert (not Is_Valid (Copy), "the copy is stale");

      begin
         Destroy (Copy);
         --  Not "not Is_Valid", which was already true: the argument has
         --  to come back null.
         Test_Support.Assert (Copy = Null_Window_Handle,
                              "destroying a stale copy nulls the handle");
      exception
         when others =>
            Test_Support.Assert (False,
                                 "destroying a stale copy must not raise");
      end;
   end Test_Destroy_Stale_Copy;

   --  Every handle wrapper is written by hand, so the degraded values
   --  are checked one by one against a stale, non-null copy.
   procedure Test_Stale_Handle_Results is
      Ready : Boolean;
      H     : Window_Handle;
      C     : Window_Handle;
   begin
      Put_Line ("Test: what a stale handle answers");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Stale Results", (320.0, 240.0));
      C := H;
      Destroy (H);
      Pump_Window_Store;
      Test_Support.Assert (not Is_Valid (C), "the copy is stale, not null");

      --  Functions answer the value that means "no window".
      Test_Support.Assert (Get_Renderer (C) = null, "Get_Renderer is null");
      Test_Support.Assert (Actual_Size (C) = (0.0, 0.0),
                           "Actual_Size is zero");
      Test_Support.Assert (Get_Size (C) = (0.0, 0.0), "Get_Size is zero");
      Test_Support.Assert (Overlay_Count (C) = 0, "Overlay_Count is zero");
      Test_Support.Assert (not Is_Maximized (C), "Is_Maximized is False");
      Test_Support.Assert (not Is_Fullscreen (C), "Is_Fullscreen is False");
      Test_Support.Assert
        (Get_Root_Handle (C) = Adi.Widget.Null_Handle,
         "Get_Root_Handle is Null_Handle");
      Test_Support.Assert
        (Get_Focus_Handle (C) = Adi.Widget.Null_Handle,
         "Get_Focus_Handle is Null_Handle");

      --  Nothing is left to refuse the close.
      Test_Support.Assert (Handle_Close_Request (C),
                           "Handle_Close_Request is True");

      --  Subscribing to a window that is gone yields no connection.
      Test_Support.Assert
        (Connect_Tick (C, On_Window_Tick'Unrestricted_Access) = Tick_Signals.No_Connection,
         "Connect_Tick is No_Connection");
      Test_Support.Assert
        (Connect_Key_Down (C, On_Window_Key'Unrestricted_Access)
           = Key_Down_Signals.No_Connection,
         "Connect_Key_Down is No_Connection");
      Test_Support.Assert
        (Connect_Post_Render (C, On_Post_Render'Unrestricted_Access)
           = Post_Render_Signals.No_Connection,
         "Connect_Post_Render is No_Connection");
      Test_Support.Assert
        (Connect_Frame (C, On_Frame'Unrestricted_Access) = Frame_Signals.No_Connection,
         "Connect_Frame is No_Connection");
      Test_Support.Assert
        (Connect_Close_Request (C, On_Close_Request'Unrestricted_Access)
           = Close_Request_Signals.No_Connection,
         "Connect_Close_Request is No_Connection");

      --  Procedures do nothing rather than raising.
      begin
         Request_Redraw (C);
         Adi.Window.Tick (C, 0.016);
         On_Text_Input (C, "x");
         On_Mouse_Move (C, 1.0, 1.0);
         On_Mouse_Down (C, 1.0, 1.0, Adi.Core.Left_Button);
         On_Mouse_Up (C, 1.0, 1.0, Adi.Core.Left_Button);
         Adi.Window.Render (C);
         Adi.Window.Handle_Resize (C, (320.0, 240.0));
         Adi.Window.Clear_Overlays (C);
         Adi.Window.Set_Root (C, Adi.Widget.Null_Handle);
         Adi.Window.Maximize (C);
         Adi.Window.Minimize (C);
         Adi.Window.Restore (C);
         Adi.Window.Set_Fullscreen (C, True);
         Disconnect_Tick (C, Tick_Signals.No_Connection);
         Disconnect_Key_Down (C, Key_Down_Signals.No_Connection);
         Disconnect_Post_Render (C, Post_Render_Signals.No_Connection);
         Disconnect_Frame (C, Frame_Signals.No_Connection);
         Disconnect_Close_Request (C, Close_Request_Signals.No_Connection);
         Test_Support.Assert (True, "procedures on a stale handle are no-ops");
      exception
         when others =>
            Test_Support.Assert
              (False, "no procedure may raise on a stale handle");
      end;

      --  Borrow is the exception: it exists to produce a usable pointer,
      --  and says Constraint_Error rather than leaking the store's
      --  strict-mode Program_Error.
      declare
         Got : Boolean := False;
      begin
         begin
            declare
               R : constant Window_Ref := Borrow (C);
               pragma Unreferenced (R);
            begin
               null;
            end;
         exception
            when Constraint_Error => Got := True;
            when others          => Got := False;
         end;
         Test_Support.Assert (Got,
                              "Borrow raises Constraint_Error when stale");
      end;
   end Test_Stale_Handle_Results;

begin
   Test_Support.Start_Suite ("Window Handle Test");

   Test_Null_Handle;
   Test_Create_Window_Handle;
   Test_Handle_Overloads;
   Test_Destroy_By_Handle;
   Test_Destroy_Idempotent;
   Test_Destroy_Stale_Copy;
   Test_Stale_Handle_Results;
   Test_Destroy_Clears_Window_Refs;
   Test_Destroy_Removes_Overlay;

   Test_Support.Finish;
end Window_Handle_Test;
