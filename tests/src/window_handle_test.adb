pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;  use Ada.Text_IO;
with Adi.SDL;      use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Window;   use Adi.Window;
with Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Test_Support;

procedure Window_Handle_Test is
   use type Adi.Widget.Widget_Handle;
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

begin
   Test_Support.Start_Suite ("Window Handle Test");

   Test_Null_Handle;
   Test_Create_Window_Handle;
   Test_Handle_Overloads;
   Test_Destroy_By_Handle;
   Test_Destroy_Idempotent;
   Test_Destroy_Clears_Window_Refs;
   Test_Destroy_Removes_Overlay;

   Test_Support.Finish;
end Window_Handle_Test;
