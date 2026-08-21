pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Text_IO;             use Ada.Text_IO;
with Adi.Core;                use Adi.Core;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.SDL;                 use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Adi.Window;
with Test_Support;            use Test_Support;

--  A scrollbar drag is recorded in two places: the window notes which
--  widget claimed the press, the widget notes that its knob is held.
--  Whatever ends the press ends both halves -- and a press that lands on
--  the track rather than the knob is not a drag at all.
procedure Scroll_Drag_Teardown_Test is

   use type Adi.Widget.Box.Box_Handle;

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok     : Adi.SDL.C_bool;
      Ttf_Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok    := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init should succeed with dummy driver");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready  := Boolean (Ttf_Ok);
         Assert (Ready, "TTF_Init should succeed");
      end if;
   end Ensure_SDL_Initialized;

   --  The scrollable is an overlay, so it keeps the geometry it is given
   --  and the track and knob land where the test can name them.
   Panel_X : constant Pixel_Type := 20.0;
   Panel_Y : constant Pixel_Type := 20.0;
   Panel_W : constant Pixel_Type := 200.0;
   Panel_H : constant Pixel_Type := 120.0;
   Bar_W   : constant Pixel_Type := 16.0;

   Content_H  : constant Pixel_Type := 480.0;
   Max_Offset : constant Pixel_Type := Content_H - Panel_H;

   --  Track and knob run down the right edge; the knob is a quarter of
   --  the track, the viewport being a quarter of the content.
   Bar_X    : constant Pixel_Type := Panel_X + Panel_W - Bar_W / 2.0;
   Knob_H   : constant Pixel_Type := Panel_H * (Panel_H / Content_H);
   Grab_Y   : constant Pixel_Type := Panel_Y + Knob_H / 2.0;
   Track_Y  : constant Pixel_Type := Panel_Y + Panel_H - 8.0;

   Knob_Idle_Bg    : constant Color_Value := RGB (60, 60, 60);
   Knob_Pressed_Bg : constant Color_Value := RGB (220, 40, 40);

   Panel_Rules : constant Style_Rules :=
     (Display        => Set (Flex),
      Flex_Direction => Set (Adi.CSS_Styles.Column),
      Overflow_Y     => Set_Overflow_Y (Overflow_Scroll),
      others         => <>);
   Content_Rules : constant Style_Rules :=
     (Height     => Set (Size (Px (Float (Content_H)))),
      Min_Height => Set (Size (Px (Float (Content_H)))),
      others     => <>);
   Track_Rules : constant Style_Rules :=
     (Width  => Set (Size (Px (Float (Bar_W)))),
      others => <>);
   Knob_Rules : constant Style_Rules :=
     (Width            => Set (Size (Px (Float (Bar_W)))),
      Background_Color => Set_Bg (Knob_Idle_Bg),
      others           => <>);
   Knob_Pressed_Rules : constant Style_Rules :=
     (Background_Color => Set_Bg (Knob_Pressed_Bg),
      others           => <>);

   --  The knob's own style says how it paints, and the bar being held is
   --  a state of the knob part, not of the widget around it.
   function Knob_Paints_Pressed (H : Widget_Handle) return Boolean is
     (Get_Resolved_Part_Style (H, Knob_Part).Background_Color
        = Knob_Pressed_Bg);

   procedure Open_Scrollable
     (Title : String;
      Win   : out Adi.Window.Window_Handle;
      H     : out Widget_Handle)
   is
      Panel   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Content : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
   begin
      Set_Part_Style (+Panel, Main_Part, From (Panel_Rules).Build);
      Set_Part_Style (+Panel, Scroll_Part, From (Track_Rules).Build);
      Set_Part_Style
        (+Panel, Knob_Part,
         From (Knob_Rules)
           .On (When_Part_State (State_Pressed), Knob_Pressed_Rules)
           .Build);
      Set_Part_Style (+Content, Main_Part, From (Content_Rules).Build);
      Add_Child (+Panel, +Content);
      Set_Geometry (+Panel, (Panel_X, Panel_Y, Panel_W, Panel_H));

      H   := +Panel;
      Win := Adi.Window.Create_Window_Handle (Title, (320.0, 240.0));
      Adi.Window.Add_Overlay (Win, H);
      Adi.Window.Render (Win);
   end Open_Scrollable;

   --  A held knob is read off the bar staying "fast", so momentum must
   --  not be able to hold it there instead -- and the coordinates the
   --  test presses have to be the parts it means to press.
   procedure Assert_Scrollbar_Ready (H : Widget_Handle) is
   begin
      Assert (not Get_Scroll_Inertia_Enabled,
              "inertia is off, so only a held knob can keep the bar fast");
      Assert (Get_Scroll_Max_Offset_Y (H) = Max_Offset,
              "the panel scrolls" & Pixel_Type'Image (Max_Offset) & " px");
      Assert (Get_Part_At (H, Bar_X, Grab_Y) = Knob_Part,
              "the knob is where the test aims for it");
      Assert (Get_Part_At (H, Bar_X, Track_Y) = Scroll_Part,
              "the track below the knob is where the test aims for it");
      Assert (not Knob_Paints_Pressed (H),
              "an untouched knob paints idle");
   end Assert_Scrollbar_Ready;

   --  Grab the knob and drag it down, leaving the button held.
   procedure Start_Knob_Drag
     (Win : Adi.Window.Window_Handle;
      H   : Widget_Handle) is
   begin
      Adi.Window.On_Mouse_Move (Win, Bar_X, Grab_Y);
      Adi.Window.On_Mouse_Down (Win, Bar_X, Grab_Y, Adi.Core.Left_Button);
      Adi.Window.On_Mouse_Move (Win, Bar_X, Grab_Y + 30.0);
      Assert (Get_Scroll_Offset_Y (H) > 0.0,
              "dragging the knob scrolls the panel");
      Adi.Window.Tick (Win, 0.016);
      Assert (Knob_Paints_Pressed (H),
              "a knob being dragged paints pressed");
   end Start_Knob_Drag;

   --  A press on the track pages the content once.  It is not a knob
   --  grab, so the motion that follows must leave the content where the
   --  page put it.
   procedure Assert_Track_Press_Does_Not_Drag
     (Win : Adi.Window.Window_Handle;
      H   : Widget_Handle)
   is
      Before : constant Pixel_Type := Get_Scroll_Offset_Y (H);
      Paged  : Pixel_Type;
   begin
      Assert (Get_Part_At (H, Bar_X, Track_Y) = Scroll_Part,
              "the press lands on the track, clear of the knob");
      Adi.Window.On_Mouse_Down (Win, Bar_X, Track_Y, Adi.Core.Left_Button);
      Paged := Get_Scroll_Offset_Y (H);
      Assert (Paged > Before, "the track press pages the content down");

      Adi.Window.On_Mouse_Move (Win, Bar_X, Track_Y + 40.0);
      Assert (Get_Scroll_Offset_Y (H) = Paged,
              "moving after a track press does not drag the content");

      Adi.Window.On_Mouse_Up (Win, Bar_X, Track_Y + 40.0, Adi.Core.Left_Button);
      Adi.Window.Tick (Win, 0.016);
      Assert (not Knob_Paints_Pressed (H),
              "the bar is idle once the button is up");
   end Assert_Track_Press_Does_Not_Drag;

   ---------------------------------------------------------------------------
   --  The overlay hosting the scrollable is taken away under the held
   --  button, so no release ever reaches the widget.
   ---------------------------------------------------------------------------

   procedure Test_Overlay_Removed_Mid_Drag is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      H     : Widget_Handle;
   begin
      Section ("overlay removed mid-drag");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Open_Scrollable ("Scroll Drag", Win, H);
      Assert_Scrollbar_Ready (H);
      Start_Knob_Drag (Win, H);

      Adi.Window.Remove_Overlay (Win, H);
      Adi.Window.On_Mouse_Up (Win, Bar_X, Grab_Y + 30.0, Adi.Core.Left_Button);

      Adi.Window.Add_Overlay (Win, H);
      Adi.Window.Render (Win);
      Adi.Window.Tick (Win, 0.016);
      Assert (not Knob_Paints_Pressed (H),
              "a panel shown again after its press was torn down does not"
              & " paint its knob pressed");

      Assert_Track_Press_Does_Not_Drag (Win, H);

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Overlay_Removed_Mid_Drag;

   ---------------------------------------------------------------------------
   --  The pointer leaves the window under the held button, so the next
   --  press arrives with the previous one still outstanding.
   ---------------------------------------------------------------------------

   procedure Test_Second_Press_Without_Release is
      Ready : Boolean := False;
      Win   : Adi.Window.Window_Handle;
      H     : Widget_Handle;
   begin
      Section ("second press without a release");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         Put_Line ("  [SKIP] SDL not available");
         return;
      end if;

      Open_Scrollable ("Scroll Repress", Win, H);
      Assert_Scrollbar_Ready (H);
      Start_Knob_Drag (Win, H);

      Assert_Track_Press_Does_Not_Drag (Win, H);

      Adi.Window.Destroy (Win);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Second_Press_Without_Release;

begin
   Start_Suite ("Scroll Drag Teardown Tests");

   Set_Scroll_Inertia_Enabled (False);

   Test_Overlay_Removed_Mid_Drag;
   Test_Second_Press_Without_Release;

   Set_Scroll_Inertia_Enabled (True);

   Finish;
end Scroll_Drag_Teardown_Test;
