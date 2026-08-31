--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;
with Ada.Unchecked_Deallocation;
with Adi.Clock; use Adi.Clock;
with Ada.Environment_Variables;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Log;
with Adi.SDL; use Adi.SDL;
with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget.Window_Bridge;
with Adi.Widget_Styles;

package body Adi.Window is

   Debug_Checked : Boolean := False;
   Debug_On      : Boolean := False;
   Debug_Tick_No : Natural := 0;

   function Debug_Enabled return Boolean is
      use Ada.Environment_Variables;
   begin
      if not Debug_Checked then
         Debug_Checked := True;
         if Exists ("ADI_DEBUG_LOOP") then
            declare
               V : constant String := Value ("ADI_DEBUG_LOOP");
            begin
               Debug_On := V /= "0" and then V /= "false" and then V /= "FALSE";
            end;
         end if;
      end if;
      return Debug_On;
   end Debug_Enabled;

   procedure Debug_Log (Msg : String) is
   begin
      if Debug_Enabled then
         Adi.Log.Debug ("[ADI-DBG] " & Msg);
      end if;
   end Debug_Log;

   procedure Set_Focused_Widget
     (W         : in out Window;
      New_Focus : Widget_Handle);

   function Is_Focus_Candidate (Wgt : Widget_Handle) return Boolean;
   function Is_Focus_Candidate
     (Wgt : Widget_Handle;
      Effective_Visibility : Visibility_Value) return Boolean;
   function First_Focusable (Root : Widget_Handle) return Widget_Handle;
   function Last_Focusable (Root : Widget_Handle) return Widget_Handle;
   function Next_Focusable
     (Root    : Widget_Handle;
      Current : Widget_Handle) return Widget_Handle;
   function Prev_Focusable
     (Root    : Widget_Handle;
      Current : Widget_Handle) return Widget_Handle;
   procedure Apply_Window_Min_Size_From_Layout (W : in out Window);
   function Is_Any_Overlay_Dirty (W : Window) return Boolean;
   function Is_Any_Overlay_Layout_Dirty (W : Window) return Boolean;
   function Overlay_Index
     (W       : Window;
      Overlay : Widget_Handle) return Natural;
   function Find_Widget_At_With_Flag
     (W    : Window;
      X, Y : Pixel_Type;
      F    : Widget_Flag) return Widget_Handle;
   function Find_Scroll_Widget_At
     (W    : Window;
      X, Y : Pixel_Type) return Widget_Handle;
   function Is_In_Subtree
     (Root : Widget_Handle;
      Node : Widget_Handle) return Boolean;
   function Active_Key_Root (W : Window) return Widget_Handle;
   procedure Apply_Render_Logical_Presentation (W : in out Window);
   function Refresh_DIP_Scale (W : in out Window) return Boolean;
   procedure Refresh_Viewport_Size (W : in out Window);
   function Normalize_Visibility (V : Visibility_Value) return Visibility_Value;
   function Widget_Participates (H : Widget_Handle) return Boolean;
   function Main_Visibility_Explicit (H : Widget_Handle) return Boolean;
   function Resolve_Effective_Visibility
     (H : Widget_Handle;
      Parent_Visibility : Visibility_Value) return Visibility_Value;
   function Window_Contains_Widget
     (W    : Window;
      Node : Widget_Handle) return Boolean;
   procedure Invalidate_Subtree (Root : Widget_Handle);
   procedure Invalidate_For_Scale_Change (W : in out Window);
   procedure Register_Live_Window (W : Window_Access);
   procedure Unregister_Live_Window
     (Win_Handle : Adi.SDL.Video.SDL_Window_Ptr);
   procedure Release_Hover_In_Subtree
     (W    : in out Window;
      Root : Widget_Handle);
   procedure Release_Pressed_Widget (W : in out Window);

   type Internal is record
      win : Adi.SDL.Video.SDL_Window_Ptr;
      ren : Adi.SDL.Render.SDL_Renderer_Ptr;
   end record;

   package Window_Access_Vectors is new Ada.Containers.Vectors
     (Positive, Window_Access);

   package Window_Id_Vectors is new Ada.Containers.Vectors
     (Positive, Window_Stores.Object_Id, Window_Stores."=");

   type Dispatch_Guard is limited new Ada.Finalization.Limited_Controlled with
     null record;
   overriding procedure Initialize (G : in out Dispatch_Guard);
   overriding procedure Finalize   (G : in out Dispatch_Guard);

   Live_Windows : Window_Access_Vectors.Vector;
   Pending_Destroy_Ids : Window_Id_Vectors.Vector;
   Dispatch_Depth      : Natural := 0;

   overriding procedure Initialize (G : in out Dispatch_Guard) is
      pragma Unreferenced (G);
   begin
      Dispatch_Depth := Dispatch_Depth + 1;
   end Initialize;

   overriding procedure Finalize (G : in out Dispatch_Guard) is
      pragma Unreferenced (G);
   begin
      if Dispatch_Depth > 0 then
         Dispatch_Depth := Dispatch_Depth - 1;
      end if;
   end Finalize;

   --  Matches Adi.Widget.Get_Handle: a window that was never registered
   --  has no handle to give, and answering Null_Window_Handle would turn
   --  the construction bug into a silent no-op at every use.
   function Get_Handle (W : Window) return Window_Handle is
   begin
      if W.Store_Index = 0 then
         raise Program_Error with
           "Get_Handle: window not registered in store";
      end if;
      return
        (Id =>
           (Index => Window_Stores.Slot_Index (W.Store_Index),
            Gen   => Window_Stores.Generation (W.Store_Gen)));
   end Get_Handle;

   function Is_Valid (H : Window_Handle) return Boolean is
   begin
      return Window_Stores.Is_Valid (H.Id);
   end Is_Valid;

   --  Null for a null handle and for a stale one.  Asking about a window
   --  that is gone is a question, not an error, and every "if Ptr = null"
   --  guard below is the answer.
   function Live (H : Window_Handle) return Window_Access is
   begin
      return Window_Access (Window_Stores.Get (H.Id));
   end Live;

   function Borrow (H : Window_Handle) return Window_Ref is
      P : constant Window_Class_Access := Window_Stores.Get (H.Id);
   begin
      if P = null then
         raise Constraint_Error with "Window.Borrow: stale or null handle";
      end if;
      Window_Stores.Pin (H.Id);
      return (Ada.Finalization.Limited_Controlled with
              Ptr => P, Id => H.Id);
   end Borrow;

   overriding procedure Finalize (R : in out Window_Ref) is
      use type Window_Stores.Object_Id;
   begin
      if R.Id /= Window_Stores.Null_Id then
         Window_Stores.Unpin (R.Id);
      end if;
   end Finalize;

   procedure Pump_Window_Store is
   begin
      for Id of Pending_Destroy_Ids loop
         Window_Stores.Request_Destroy (Id);
      end loop;
      Pending_Destroy_Ids.Clear;
      Window_Stores.Pump;
   end Pump_Window_Store;

   --  Still backed by SDL. Destroy frees Internal whole rather than
   --  clearing the pointers, and creation raises on failure, so a live
   --  window has both or the record is gone.
   function Is_Live (W : Window) return Boolean is
     (W.Internal /= null
        and then W.Internal.win /= null
        and then W.Internal.ren /= null);

   procedure Apply_Render_Logical_Presentation (W : in out Window) is
      Success : Adi.SDL.C_bool;
   begin
      if not Is_Live (W) then
         return;
      end if;

      --  Render in the window's physical-pixel space (1 unit = 1 pixel) so
      --  glyphs and lines land on pixel boundaries on HiDPI displays. With
      --  SDL_WINDOW_HIGH_PIXEL_DENSITY set, the renderer's drawable already
      --  matches the physical framebuffer; STRETCH would force a logical
      --  upscale and blur everything. The dp unit (Active_DIP_Scale) is what
      --  size-independent layout should use.
      Success := Adi.SDL.Render.SDL_SetRenderLogicalPresentation
        (Renderer => W.Internal.ren,
         W        => 0,
         H        => 0,
         Mode     => Adi.SDL.Render.SDL_LOGICAL_PRESENTATION_DISABLED);
      SDL_Assert (Success, "SDL_SetRenderLogicalPresentation");
   end Apply_Render_Logical_Presentation;

   function Create_Window_Sized
     (Title     : String;
      S         : Size_2D;
      Maximized : Boolean;
      Hidden    : Boolean) return Window_Handle;

   --  The display scale everything derives from: layout units through
   --  Refresh_DIP_Scale, and a window's initial size through
   --  Create_Window_Handle. One function, so an override cannot lay a
   --  window out at one scale and size it at another.
   --
   --  ADI_DISPLAY_SCALE_OVERRIDE pins it, which is what makes a capture
   --  independent of the machine that took it. Pixel density is left
   --  alone: at an override of 1 on a 2x device, a 600px target still
   --  asks for 300 window coordinates and still yields 600 pixels.
   --
   --  Read once. It is a capture and debugging knob, not something to
   --  re-parse every frame.
   Scale_Override      : Pixel_Type := 0.0;
   Scale_Override_Read : Boolean    := False;

   function Effective_Display_Scale
     (Win : Adi.SDL.Video.SDL_Window_Ptr) return Pixel_Type
   is
      use Ada.Environment_Variables;
   begin
      if not Scale_Override_Read then
         Scale_Override_Read := True;
         if Exists ("ADI_DISPLAY_SCALE_OVERRIDE") then
            begin
               Scale_Override :=
                 Pixel_Type'Value (Value ("ADI_DISPLAY_SCALE_OVERRIDE"));
               if Scale_Override <= 0.0 then
                  Scale_Override := 0.0;
                  Adi.Log.Error
                    ("ADI_DISPLAY_SCALE_OVERRIDE must be positive; ignored");
               end if;
            exception
               when others =>
                  Scale_Override := 0.0;
                  Adi.Log.Error
                    ("ADI_DISPLAY_SCALE_OVERRIDE is not a number; ignored");
            end;
         end if;
      end if;

      if Scale_Override > 0.0 then
         return Scale_Override;
      end if;
      return Pixel_Type'Max
        (1.0, Pixel_Type (Adi.SDL.Video.SDL_GetWindowDisplayScale (Win)));
   end Effective_Display_Scale;

   function Extent
     (Width, Height : Adi.CSS_Styles.Length_Value) return Window_Extent
   is
      procedure Check (L : Length_Value) is
      begin
         if L.Amount <= 0.0 then
            raise Constraint_Error with
              "window extent must be positive, got" & L.Amount'Image;
         end if;
         case L.Unit is
            when Pix | Px | Dip | Pct =>
               null;
            when Em | Root_Em | Vw | Vh =>
               raise Constraint_Error with
                 "window extent cannot use " & L.Unit'Image
                 & ": no font context, and vw/vh would resolve against "
                 & "the viewport being defined";
         end case;
      end Check;
   begin
      Check (Width);
      Check (Height);
      return (Width => Width, Height => Height);
   end Extent;

   function Resolve_Extent
     (E              : Window_Extent;
      Display_Scale  : Pixel_Type;
      Pixel_Density  : Pixel_Type;
      Usable         : Size_2D;
      Px_Maps_To_Dip : Boolean) return Resolved_Extent
   is
      Density : constant Pixel_Type :=
        (if Pixel_Density > 0.0 then Pixel_Density else 1.0);
      --  Display scale only. Length_To_Px also applies the UI scale, but
      --  that is application zoom within the viewport: growing the window
      --  by it would undo the zoom, and it is process-global state that
      --  is usually set after the window exists.
      Logical : constant Pixel_Type := Display_Scale;

      --  Percentages are a share of the usable bounds, which SDL reports
      --  in window coordinates, so they land in that space directly.
      --  Every other unit describes framebuffer pixels.
      function Coords_Of (L : Length_Value; Bound : Pixel_Type)
        return Pixel_Type is
      begin
         case L.Unit is
            when Pct =>
               return Pixel_Type (L.Amount) / 100.0 * Bound;
            when Pix =>
               return Pixel_Type (L.Amount) / Density;
            when Dip =>
               return Pixel_Type (L.Amount) * Logical / Density;
            when Px =>
               return (if Px_Maps_To_Dip
                       then Pixel_Type (L.Amount) * Logical / Density
                       else Pixel_Type (L.Amount) / Density);
            when others =>
               return Pixel_Type (L.Amount) / Density;
         end case;
      end Coords_Of;

      W_Coords : constant Pixel_Type := Coords_Of (E.Width, Usable.Width);
      H_Coords : constant Pixel_Type := Coords_Of (E.Height, Usable.Height);
   begin
      return (Coords => (W_Coords, H_Coords),
              Pixels => (W_Coords * Density, H_Coords * Density));
   end Resolve_Extent;

   function Refresh_DIP_Scale (W : in out Window) return Boolean is
      Raw    : Pixel_Type := 1.0;
      Before : constant Pixel_Type := Get_Active_DIP_Scale;
   begin
      if not Is_Live (W) then
         return False;
      end if;

      Raw := Effective_Display_Scale (Get_SDL_Window (W));
      Set_Active_DIP_Scale (Raw);
      return abs (Get_Active_DIP_Scale - Before) > 0.0001;
   end Refresh_DIP_Scale;

   procedure Refresh_Viewport_Size (W : in out Window) is
      W_Px : aliased int := 0;
      H_Px : aliased int := 0;
      Ok   : Adi.SDL.C_bool := False;
   begin
      if W.Internal /= null and then W.Internal.win /= null then
         Ok := Adi.SDL.Video.SDL_GetWindowSizeInPixels
           (W.Internal.win,
            W_Px'Access,
            H_Px'Access);
      end if;

      if Ok then
         Set_Active_Viewport_Size
           (Width  => Pixel_Type'Max (0.0, Pixel_Type (W_Px)),
            Height => Pixel_Type'Max (0.0, Pixel_Type (H_Px)));
      else
         Set_Active_Viewport_Size
           (Width  => Pixel_Type'Max (0.0, W.Size.Width),
            Height => Pixel_Type'Max (0.0, W.Size.Height));
      end if;
   end Refresh_Viewport_Size;

   function Normalize_Visibility (V : Visibility_Value) return Visibility_Value is
   begin
      if V = Visibility_Collapse then
         return Visibility_Hidden;
      end if;
      return V;
   end Normalize_Visibility;

   function Widget_Participates (H : Widget_Handle) return Boolean is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (H, Main_Part);
   begin
      return Is_Valid (H)
        and then Has_Flag (H, Visible)
        and then Main_Style.Display /= Display_None;
   end Widget_Participates;

   function Main_Visibility_Explicit (H : Widget_Handle) return Boolean is
      Rules : constant Style_Rules := Get_Part_Style_Rules (H, Main_Part);
   begin
      return Opt_Visibility.Is_Set (Rules.Visibility);
   end Main_Visibility_Explicit;

   function Resolve_Effective_Visibility
     (H : Widget_Handle;
      Parent_Visibility : Visibility_Value) return Visibility_Value
   is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (H, Main_Part);
   begin
      if Main_Visibility_Explicit (H) then
         return Normalize_Visibility (Main_Style.Visibility);
      end if;
      return Parent_Visibility;
   end Resolve_Effective_Visibility;

   function Is_Focus_Candidate
     (Wgt : Widget_Handle;
      Effective_Visibility : Visibility_Value) return Boolean
   is
   begin
      return Is_Valid (Wgt)
        and then Effective_Visibility = Visibility_Visible
        and then Widget_Participates (Wgt)
        and then Has_Flag (Wgt, Focusable)
        and then not Is_Disabled (Wgt);
   end Is_Focus_Candidate;

   function Is_Focus_Candidate (Wgt : Widget_Handle) return Boolean is
      function Effective_Visibility_For (Node : Widget_Handle) return Visibility_Value is
         Parent : constant Widget_Handle := Get_Parent_Handle (Node);
      begin
         if not Is_Valid (Node) then
            return Visibility_Hidden;
         end if;

         if not Is_Valid (Parent) then
            return Resolve_Effective_Visibility (Node, Visibility_Visible);
         end if;

         return Resolve_Effective_Visibility
           (Node, Effective_Visibility_For (Parent));
      end Effective_Visibility_For;
   begin
      return Is_Focus_Candidate (Wgt, Effective_Visibility_For (Wgt));
   end Is_Focus_Candidate;

   function First_Focusable (Root : Widget_Handle) return Widget_Handle is
      function Visit
        (Node : Widget_Handle;
         Parent_Visibility : Visibility_Value) return Widget_Handle
      is
         Candidate : Widget_Handle;
         Node_Visibility : Visibility_Value;
      begin
         if not Is_Valid (Node) or else not Widget_Participates (Node) then
            return Null_Handle;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node, Parent_Visibility);
         if Is_Focus_Candidate (Node, Node_Visibility) then
            return Node;
         end if;

         for I in 1 .. Child_Count (Node) loop
            Candidate := Visit (Get_Child_Handle (Node, I), Node_Visibility);
            if Is_Valid (Candidate) then
               return Candidate;
            end if;
         end loop;

         return Null_Handle;
      end Visit;
   begin
      return Visit (Root, Visibility_Visible);
   end First_Focusable;

   function Last_Focusable (Root : Widget_Handle) return Widget_Handle is
      function Visit
        (Node : Widget_Handle;
         Parent_Visibility : Visibility_Value) return Widget_Handle
      is
         Candidate : Widget_Handle;
         Node_Visibility : Visibility_Value;
      begin
         if not Is_Valid (Node) or else not Widget_Participates (Node) then
            return Null_Handle;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node, Parent_Visibility);

         for I in reverse 1 .. Child_Count (Node) loop
            Candidate := Visit (Get_Child_Handle (Node, I), Node_Visibility);
            if Is_Valid (Candidate) then
               return Candidate;
            end if;
         end loop;

         if Is_Focus_Candidate (Node, Node_Visibility) then
            return Node;
         end if;
         return Null_Handle;
      end Visit;
   begin
      return Visit (Root, Visibility_Visible);
   end Last_Focusable;

   function Next_Focusable
     (Root    : Widget_Handle;
      Current : Widget_Handle) return Widget_Handle
   is
      Result       : Widget_Handle := Null_Handle;
      Seen_Current : Boolean := not Is_Valid (Current);

      procedure Visit
        (Node : Widget_Handle;
         Parent_Visibility : Visibility_Value)
      is
         Node_Visibility : Visibility_Value;
      begin
         if not Is_Valid (Node) or else Is_Valid (Result) then
            return;
         end if;
         if not Widget_Participates (Node) then
            return;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node, Parent_Visibility);
         if Seen_Current and then Is_Focus_Candidate (Node, Node_Visibility) then
            Result := Node;
            return;
         end if;

         if Node = Current then
            Seen_Current := True;
         end if;

         for I in 1 .. Child_Count (Node) loop
            Visit (Get_Child_Handle (Node, I), Node_Visibility);
            exit when Is_Valid (Result);
         end loop;
      end Visit;
   begin
      Visit (Root, Visibility_Visible);
      return Result;
   end Next_Focusable;

   function Prev_Focusable
     (Root    : Widget_Handle;
      Current : Widget_Handle) return Widget_Handle
   is
      Result : Widget_Handle := Null_Handle;
      Prev   : Widget_Handle := Null_Handle;

      procedure Visit
        (Node : Widget_Handle;
         Parent_Visibility : Visibility_Value)
      is
         Node_Visibility : Visibility_Value;
      begin
         if not Is_Valid (Node) or else Is_Valid (Result) then
            return;
         end if;
         if not Widget_Participates (Node) then
            return;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node, Parent_Visibility);
         if Node = Current then
            Result := Prev;
            return;
         end if;

         if Is_Focus_Candidate (Node, Node_Visibility) then
            Prev := Node;
         end if;

         for I in 1 .. Child_Count (Node) loop
            Visit (Get_Child_Handle (Node, I), Node_Visibility);
            exit when Is_Valid (Result);
         end loop;
      end Visit;
   begin
      Visit (Root, Visibility_Visible);
      return Result;
   end Prev_Focusable;

   function Is_In_Subtree
     (Root : Widget_Handle;
      Node : Widget_Handle) return Boolean
   is
   begin
      if not Is_Valid (Root) or else not Is_Valid (Node) then
         return False;
      end if;

      if Root = Node then
         return True;
      end if;

      for I in 1 .. Child_Count (Root) loop
         if Is_In_Subtree (Get_Child_Handle (Root, I), Node) then
            return True;
         end if;
      end loop;

      return False;
   end Is_In_Subtree;

   function Window_Contains_Widget
     (W    : Window;
      Node : Widget_Handle) return Boolean
   is
   begin
      if not Is_Valid (Node) then
         return False;
      end if;

      if Is_In_Subtree (W.Root, Node) then
         return True;
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         if Is_In_Subtree (W.Overlays.Element (I), Node) then
            return True;
         end if;
      end loop;

      return False;
   end Window_Contains_Widget;

   procedure Invalidate_Subtree (Root : Widget_Handle) is
   begin
      if not Is_Valid (Root) then
         return;
      end if;

      for I in 1 .. Child_Count (Root) loop
         Invalidate_Subtree (Get_Child_Handle (Root, I));
      end loop;

      Mark_Dirty (Root);
   end Invalidate_Subtree;

   procedure Invalidate_For_Scale_Change (W : in out Window) is
   begin
      if Is_Valid (W.Root) then
         Invalidate_Subtree (W.Root);
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (Overlay) then
               Invalidate_Subtree (Overlay);
            end if;
         end;
      end loop;

      W.Needs_Layout := True;
      W.Resize_Triggered_Layout := False;
      W.Force_Redraw := True;
   end Invalidate_For_Scale_Change;

   procedure Register_Live_Window (W : Window_Access) is
   begin
      if W = null then
         return;
      end if;

      for I in 1 .. Natural (Live_Windows.Length) loop
         if Live_Windows.Element (I) = W then
            return;
         end if;
      end loop;

      Live_Windows.Append (W);
   end Register_Live_Window;

   procedure Unregister_Live_Window
     (Win_Handle : Adi.SDL.Video.SDL_Window_Ptr)
   is
   begin
      if Win_Handle = null then
         return;
      end if;

      for I in reverse 1 .. Natural (Live_Windows.Length) loop
         declare
            Candidate : constant Window_Access := Live_Windows.Element (I);
         begin
            if Candidate /= null
              and then Candidate.Internal /= null
              and then Candidate.Internal.win = Win_Handle
            then
               Live_Windows.Delete (I);
            end if;
         end;
      end loop;
   end Unregister_Live_Window;

   function Find_Host_Window
     (Node : Widget_Handle) return Window_Handle
   is
   begin
      if not Is_Valid (Node) then
         return Null_Window_Handle;
      end if;

      for I in reverse 1 .. Natural (Live_Windows.Length) loop
         declare
            Candidate : constant Window_Access := Live_Windows.Element (I);
         begin
            if Candidate /= null
              and then Window_Contains_Widget (Candidate.all, Node)
            then
               return Get_Handle (Candidate.all);
            end if;
         end;
      end loop;

      return Null_Window_Handle;
   end Find_Host_Window;

   function Active_Key_Root (W : Window) return Widget_Handle is
   begin
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (Overlay) and then Widget_Participates (Overlay) then
               return Overlay;
            end if;
         end;
      end loop;

      return W.Root;
   end Active_Key_Root;

   function Overlay_Index
     (W       : Window;
      Overlay : Widget_Handle) return Natural
   is
   begin
      if not Is_Valid (Overlay) then
         return 0;
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         if W.Overlays.Element (I) = Overlay then
            return I;
         end if;
      end loop;
      return 0;
   end Overlay_Index;

   function Is_Any_Overlay_Dirty (W : Window) return Boolean is
   begin
      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            OH : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (OH) and then Widget_Participates (OH)
              and then Is_Dirty (OH)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Is_Any_Overlay_Dirty;

   function Is_Any_Overlay_Layout_Dirty (W : Window) return Boolean is
   begin
      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            OH : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (OH) and then Widget_Participates (OH)
              and then Is_Layout_Dirty (OH)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Is_Any_Overlay_Layout_Dirty;

   procedure Apply_Window_Min_Size_From_Layout (W : in out Window) is
      Min_W : int := 1;
      Min_H : int := 1;
      Success : Adi.SDL.C_bool;
   begin
      if not W.Enforce_Layout_Min_Size or else not Is_Live (W) then
         return;
      end if;

      --  Maximized and fullscreen windows are sized by the WM; enforcing a
      --  layout-derived minimum would prevent them from being restored to a
      --  size smaller than the current content minimum.
      if Is_Maximized (W) or else Is_Fullscreen (W) then
         return;
      end if;

      if Is_Valid (W.Root) then
         declare
            Pref : constant Size_2D := Get_Preferred_Size (W.Root);
            Floor : constant Size_2D := Effective_Min_Size (W.Root);
            Root_Geom : constant Rectangle := Get_Geometry (W.Root);

            --  How tall the content is at the width the window actually
            --  has. Preferred height would be the unwrapped one, which
            --  is too short to hold wrapped text -- and asking at the
            --  current width is what lets the floor drop again when the
            --  user widens and the text unwraps.
            Fitted : constant Size_2D :=
              (if Root_Geom.Width > 0.0
               then Measure_At_Width (W.Root, Root_Geom.Width)
               else Pref);

            --  The smallest the content can be squeezed to, which is
            --  what a minimum means. Preferred width is the max-content
            --  width -- for wrapping content, the width at which it
            --  would rather not wrap at all -- and pinning the window
            --  there would deny the wrapping the layout is willing to
            --  do. Taking the smaller of the two would instead ignore an
            --  explicit min-width that exceeds the preferred width.
            Wf   : constant Float := Float'Max (1.0, Float (Floor.Width));
            --  Same rule as the width: an explicit min-height is a
            --  floor, whatever the content at this width measures.
            Hf   : constant Float :=
              Float'Max (1.0,
                         Float'Max (Float (Fitted.Height),
                                    Float (Floor.Height)));
         begin
            Min_W := int (Integer (Float'Ceiling (Wf)));
            Min_H := int (Integer (Float'Ceiling (Hf)));
         end;
      end if;

      --  Keep minimums recoverable: never exceed monitor usable bounds.
      declare
         Display_ID : Adi.SDL.Video.SDL_DisplayID :=
           Adi.SDL.Video.SDL_GetDisplayForWindow (W.Internal.win);
         Usable : aliased SDL_Rect := (x => 0, y => 0, w => 0, h => 0);
      begin
         if Display_ID = Adi.SDL.Video.SDL_DisplayID (0) then
            Display_ID := Adi.SDL.Video.SDL_GetPrimaryDisplay;
         end if;
         if Display_ID /= Adi.SDL.Video.SDL_DisplayID (0) then
            if Adi.SDL.Video.SDL_GetDisplayUsableBounds
                 (Display_ID, Usable'Access)
            then
               Min_W := int'Min (Min_W, int'Max (1, Usable.w));
               Min_H := int'Min (Min_H, int'Max (1, Usable.h));
            end if;
         end if;
      end;

      Success := Adi.SDL.Video.SDL_SetWindowMinimumSize (W.Internal.win, Min_W, Min_H);
      SDL_Assert (Success, "SDL_SetWindowMinimumSize");

      --  SDL_SetWindowMinimumSize only prevents future resizes below the
      --  minimum; it does not resize a window that is already too small.
      --  If the user resized faster than layout could respond, clamp now.
      declare
         Cur_W : aliased int := 0;
         Cur_H : aliased int := 0;
      begin
         if Adi.SDL.Video.SDL_GetWindowSize
              (W.Internal.win, Cur_W'Access, Cur_H'Access)
         then
            if Cur_W < Min_W or else Cur_H < Min_H then
               Success := Adi.SDL.Video.SDL_SetWindowSize
                 (W.Internal.win,
                  int'Max (Cur_W, Min_W),
                  int'Max (Cur_H, Min_H));
               SDL_Assert (Success, "SDL_SetWindowSize (min clamp)");
            end if;
         end if;
      end;
   end Apply_Window_Min_Size_From_Layout;

   --------------------------
   -- Prefer_Render_Driver --
   --------------------------
   procedure Prefer_Render_Driver (Name : String) is
      use Interfaces.C.Strings;
      C_Hint  : chars_ptr := New_String (Adi.SDL.SDL_HINT_RENDER_DRIVER);
      C_Value : chars_ptr := New_String (Name);
      Unused  : Adi.SDL.C_bool;
   begin
      Unused := Adi.SDL.SDL_SetHint (C_Hint, C_Value);
      Free (C_Hint);
      Free (C_Value);
   end Prefer_Render_Driver;

   -------------------
   -- Render_Driver --
   -------------------
   function Render_Driver (W : Window) return String is
      use Interfaces.C.Strings;
      Name : chars_ptr;
   begin
      if W.Internal.ren = null then
         return "";
      end if;
      Name := Adi.SDL.Render.SDL_GetRendererName (W.Internal.ren);
      if Name = Null_Ptr then
         return "";
      end if;
      return Value (Name);
   end Render_Driver;

   function Render_Driver (H : Window_Handle) return String is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr = null then
         return "";
      end if;
      return Render_Driver (Ptr.all);
   end Render_Driver;

   -------------------
   -- Create_Window --
   -------------------
   function Create_Window_Handle
     (Title     : String;
      S         : Size_2D;
      Maximized : Boolean := False) return Window_Handle is
     (Create_Window_Sized (Title, S, Maximized, Hidden => False));

   function Create_Window_Sized
     (Title     : String;
      S         : Size_2D;
      Maximized : Boolean;
      Hidden    : Boolean) return Window_Handle
   is
      use Interfaces.C.Strings;
      C_Title_Str : chars_ptr := New_String (Title);
      Win_Ptr : aliased Adi.SDL.Video.SDL_Window_Ptr;
      Ren_Ptr : aliased Adi.SDL.Render.SDL_Renderer_Ptr;
      Success : Adi.SDL.C_bool;
      Flags   : SDL_WindowFlags :=
        SDL_WINDOW_RESIZABLE or SDL_WINDOW_HIGH_PIXEL_DENSITY;
   begin
      if Maximized then
         Flags := Flags or SDL_WINDOW_MAXIMIZED;
      end if;
      if Hidden then
         Flags := Flags or SDL_WINDOW_HIDDEN;
      end if;
      Success := Adi.SDL.Render.SDL_CreateWindowAndRenderer
        (C_Title_Str,
         int (S.Width),
         int (S.Height),
         Flags,
         Win_Ptr,
         Ren_Ptr);
      Free (C_Title_Str);
      --  Not SDL_Assert: assertions are off in release builds, and
      --  carrying on would register a Window holding null SDL pointers.
      if not Boolean (Success) or else Win_Ptr = null or else Ren_Ptr = null
      then
         raise Adi.SDL.SDL_Error with
           "SDL_CreateWindowAndRenderer failed: "
           & Interfaces.C.Strings.Value (Adi.SDL.SDL_GetError);
      end if;
      declare
         W : constant Window_Access := new Window;
         Pixel_Size : Size_2D := S;
         W_Px       : aliased int := 0;
         H_Px       : aliased int := 0;
      begin
         W.Internal := new Internal;
         W.Internal.win := Win_Ptr;
         W.Internal.ren := Ren_Ptr;
         Adi.Render.Create (W.Ctx, Ren_Ptr);
         --  S is the SDL window size (interpreted by SDL as logical points
         --  on HiDPI platforms). Adi's API exposes pixels everywhere, so
         --  store the actual framebuffer pixel size in W.Size/W.Geometry.
         if Adi.SDL.Video.SDL_GetWindowSizeInPixels
              (Win_Ptr, W_Px'Access, H_Px'Access)
         then
            Pixel_Size := (Width  => Pixel_Type (W_Px),
                           Height => Pixel_Type (H_Px));
         end if;
         W.Size := Pixel_Size;
         W.Geometry := (0.0, 0.0, Pixel_Size.Width, Pixel_Size.Height);
         Apply_Render_Logical_Presentation (W.all);
         if Refresh_DIP_Scale (W.all) then
            null;
         end if;
         Refresh_Viewport_Size (W.all);
         Register_Live_Window (W);
         declare
            Id : constant Window_Stores.Object_Id :=
              Window_Stores.Register (Window_Class_Access (W));
         begin
            W.Store_Index := Natural (Id.Index);
            W.Store_Gen   := Natural (Id.Gen);
         end;
         return Get_Handle (W.all);
      end;
   end Create_Window_Sized;


   ------------
   -- Update --
   ------------

   procedure Update (W : in out Window) is
   begin
      if Is_Valid (W.Focused_Widget)
        and then not Is_Focus_Candidate (W.Focused_Widget)
      then
         Set_Focused_Widget (W, Null_Handle);
      end if;

      if Is_Valid (W.Root) then
         Adi.Widget.Update (W.Root);
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            OH : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (OH) then
               Adi.Widget.Update (OH);
            end if;
         end;
      end loop;
   end Update;

    procedure Render_Debug_Stats (W : Window) is
       --  SDL_RenderDebugText draws an 8 px-tall bitmap font at 1:1
       --  device pixels.  On HiDPI (Retina) the window's render target
       --  is in physical pixels, so without scaling the bar comes out
       --  microscopic.  Scale by the active DIP factor (clamped to 1.0
       --  so non-Retina output is unchanged).
       Scale  : constant Float :=
         Float'Max (1.0, Float (Get_Active_DIP_Scale));
       Bar_H  : constant Float := 16.0 * Scale;
       Win_H  : constant Float := Float (W.Size.Height);
       Win_W  : constant Float := Float (W.Size.Width);
       Bar    : aliased SDL_FRect :=
         (x => 0.0, y => Win_H - Bar_H, w => Win_W, h => Bar_H);
       FPS    : Natural := 0;

       Buf : String (1 .. 512);
       Len : Natural := 0;

       procedure Append (S : String) is
       begin
          for C of S loop
             Len := Len + 1;
             Buf (Len) := C;
          end loop;
       end Append;

       procedure Append_Nat (V : Natural; Width : Positive) is
          Img : constant String := Natural'Image (V);
          Num : constant String := Img (Img'First + 1 .. Img'Last);
       begin
          for I in 1 .. Width - Num'Length loop
             Append (" ");
          end loop;
          Append (Num);
       end Append_Nat;

       procedure Append_Ms (Us : Natural) is
          Ms    : constant Float := Float (Us) / 1000.0;
          Whole : constant Natural := Natural (Float'Floor (Ms));
          Frac  : constant Natural :=
            Natural (Float'Floor ((Ms - Float (Whole)) * 10.0));
       begin
          Append_Nat (Whole, 3);
          Append (".");
          Append_Nat (Frac, 1);
       end Append_Ms;

       C_Str  : Interfaces.C.Strings.chars_ptr;
       Dummy  : Adi.SDL.C_bool;
    begin
       if W.Stats_Last_DT > 0.0 then
          FPS := Natural (1.0 / W.Stats_Last_DT);
       end if;

       --  Single line: F:nnnnnnn  FPS:nnn  Upd:nn.n  Lay:nn.n  Draw:nn.n  Pres:nn.n  L:n(R)
       --  ... S:hits+memo/resolves  LC:calls+skips  P:hits/calls  SM:hits/misses
       Append ("F:");
       Append_Nat (W.Stats_Frame_No, 7);
       Append ("  FPS:");
       Append_Nat (FPS, 3);
       Append ("  Upd:");
       Append_Ms (W.Stats_Update_Us);
       Append ("  Lay:");
       Append_Ms (W.Stats_Layout_Us);
       Append ("  Draw:");
       Append_Ms (W.Stats_Draw_Us);
       Append ("  Pres:");
       Append_Ms (W.Stats_Present_Us);
       Append ("  L:");
       Append_Nat (W.Stats_Layout_Count, 1);
       Append ([1 => W.Stats_Layout_Reason]);
       Append ("  S:");
       Append_Nat (W.Stats_Style_Hits, 4);
       Append ("+");
       Append_Nat (W.Stats_Style_Memo_Hits, 4);
       Append ("/");
       Append_Nat (W.Stats_Style_Resolves, 4);
       Append ("  LC:");
       Append_Nat (W.Stats_Layout_Calls, 3);
       Append ("+");
       Append_Nat (W.Stats_Layout_Skips, 3);
       Append ("  P:");
       Append_Nat (W.Stats_Pref_Hits, 3);
       Append ("/");
       Append_Nat (W.Stats_Pref_Calls, 3);
       Append ("  SM:");
       Append_Nat (W.Stats_Sel_Memo_Hits, 3);
       Append ("/");
       Append_Nat (W.Stats_Sel_Memo_Misses, 3);

       --  Draw background bar
       Dummy := SDL_SetRenderDrawBlendMode
         (W.Internal.ren, SDL_BLENDMODE_BLEND);
       Dummy := SDL_SetRenderDrawColor (W.Internal.ren, 0, 0, 0, 200);
       Dummy := SDL_RenderFillRect (W.Internal.ren, Bar'Access);

       --  Draw text — scale the renderer so the debug font is legible
       --  on HiDPI.  Restore scale to 1:1 afterwards.
       Dummy := SDL_SetRenderDrawColor (W.Internal.ren, 180, 255, 180, 255);
       Dummy := SDL_SetRenderScale (W.Internal.ren, Scale, Scale);
       C_Str := Interfaces.C.Strings.New_String (Buf (1 .. Len));
       Dummy := SDL_RenderDebugText
         (W.Internal.ren,
          6.0,
          (Win_H - Bar_H + 2.0 * Scale) / Scale,
          C_Str);
       Interfaces.C.Strings.Free (C_Str);
       Dummy := SDL_SetRenderScale (W.Internal.ren, 1.0, 1.0);

       --  Restore blend mode
       Dummy := SDL_SetRenderDrawBlendMode
         (W.Internal.ren, SDL_BLENDMODE_NONE);
    end Render_Debug_Stats;

    procedure Render (W : in out Window) is
       Guard                : Dispatch_Guard;
       pragma Unreferenced (Guard);
       Root_Valid           : Boolean;
       Root_Dirty           : Boolean;
       Overlay_Dirty        : Boolean;
       Root_Layout_Dirty    : Boolean;
       Overlay_Layout_Dirty : Boolean;
       Needs_Relayout       : Boolean;
       Render_Start : Time;
       Stage_Start  : Time;
    begin
       --  Keep unit conversion contexts in sync with current window state.
       Set_Active_Root_Font_Size
         (Length_To_Px (W.Root_Font_Size,
                        Root_Font_Size => Default_Root_Font_Size_Px));
       if Refresh_DIP_Scale (W) then
          Invalidate_For_Scale_Change (W);
       end if;
       Refresh_Viewport_Size (W);

       Root_Valid := Is_Valid (W.Root);
       Root_Dirty := Root_Valid and then Is_Dirty (W.Root);
       Overlay_Dirty := Is_Any_Overlay_Dirty (W);
       Root_Layout_Dirty := Root_Valid and then Is_Layout_Dirty (W.Root);
       Overlay_Layout_Dirty := Is_Any_Overlay_Layout_Dirty (W);
       Needs_Relayout :=
         W.Needs_Layout or else Root_Layout_Dirty or else Overlay_Layout_Dirty;

       --  Only render if something changed or a redraw was forced
       --  (e.g. window exposed by the compositor).
       if Root_Dirty or else Overlay_Dirty or else W.Force_Redraw
       then
          W.Force_Redraw := False;
          W.Stats_Frame_No := W.Stats_Frame_No + 1;
          W.Stats_Layout_Count := 0;
          Render_Start := Now;

          --  Only frames that are drawn count: ticks spent idle must not
          --  age cached textures that had no chance to be used.
          Adi.Render.Advance_Frame (W.Ctx);

          Debug_Log
            ("render tick=" & Natural'Image (Debug_Tick_No)
             & " root_dirty=" & Boolean'Image (Root_Dirty)
             & " overlay_dirty=" & Boolean'Image (Overlay_Dirty)
             & " needs_relayout=" & Boolean'Image (Needs_Relayout));

          --  Clear the screen
          SDL_Assert (SDL_SetRenderDrawColor (W.Internal.ren, 255, 255, 255, 255), "SDL_SetRenderDrawColor");
          SDL_Assert (SDL_RenderClear (W.Internal.ren), "SDL_RenderClear");

          --  Reset perf counters before Update so that style/pref-size
          --  work during Build_Items is included in the per-frame stats.
          Adi.Widget.Reset_Perf_Counters;

          --  Rebuild dirty items first.
          Stage_Start := Now;
          Update (W);
          W.Stats_Update_Us := Natural
            (To_Duration (Now - Stage_Start) * 1_000_000.0);

          --  Relayout only when required by geometry-affecting changes.
          Stage_Start := Now;
          if W.Needs_Layout then
             W.Stats_Layout_Reason := 'W';
          elsif Root_Layout_Dirty then
             W.Stats_Layout_Reason := 'R';
          elsif Overlay_Layout_Dirty then
             W.Stats_Layout_Reason := 'O';
          else
             W.Stats_Layout_Reason := '-';
          end if;
          if Needs_Relayout then
             if Root_Valid then
                Debug_Log ("relayout tick=" & Natural'Image (Debug_Tick_No));
                Layout_Tree (W.Root);
                Adi.Widget.Update (W.Root);
                Apply_Window_Min_Size_From_Layout (W);
                W.Stats_Layout_Count := W.Stats_Layout_Count + 1;
             end if;

             for I in 1 .. Natural (W.Overlays.Length) loop
                declare
                   OH : constant Widget_Handle := W.Overlays.Element (I);
                begin
                   if Is_Valid (OH) then
                      Layout_Tree (OH);
                      Adi.Widget.Update (OH);
                      W.Stats_Layout_Count := W.Stats_Layout_Count + 1;
                   end if;
                end;
             end loop;

             W.Needs_Layout := False;
             W.Resize_Triggered_Layout := False;
          end if;
          W.Stats_Layout_Us := Natural
            (To_Duration (Now - Stage_Start) * 1_000_000.0);

          --  Draw all widget trees
          Stage_Start := Now;
          if Root_Valid then
             Render_Tree (W.Root, W.Ctx);
          end if;

          for I in 1 .. Natural (W.Overlays.Length) loop
             declare
                OH : constant Widget_Handle := W.Overlays.Element (I);
             begin
                if Is_Valid (OH) then
                   Render_Tree (OH, W.Ctx);
                end if;
             end;
          end loop;
          W.Stats_Draw_Us := Natural
            (To_Duration (Now - Stage_Start) * 1_000_000.0);

          --  After the draw, so the counters cover the whole frame the
          --  reset above opened: drawing resolves styles too.
          W.Stats_Style_Resolves  := Adi.Widget.Get_Perf_Style_Resolves;
          W.Stats_Style_Hits      := Adi.Widget.Get_Perf_Style_Hits;
          W.Stats_Style_Memo_Hits := Adi.Widget.Get_Perf_Style_Memo_Hits;
          W.Stats_Style_Computes  := Adi.Widget.Get_Perf_Style_Computes;
          W.Stats_Layout_Calls    := Adi.Widget.Get_Perf_Layout_Calls;
          W.Stats_Layout_Skips    := Adi.Widget.Get_Perf_Layout_Skips;
          W.Stats_Pref_Calls      := Adi.Widget.Get_Perf_Pref_Calls;
          W.Stats_Pref_Hits       := Adi.Widget.Get_Perf_Pref_Hits;
          W.Stats_Sel_Memo_Hits   := Adi.Widget.Get_Perf_Selector_Memo_Hits;
          W.Stats_Sel_Memo_Misses :=
            Adi.Widget.Get_Perf_Selector_Memo_Misses;

          --  Compute total render time (before present)
          W.Stats_Render_Us := Natural
            (To_Duration (Now - Render_Start) * 1_000_000.0);

          --  Debug stats overlay
          if W.Debug_Stats_On then
             Render_Debug_Stats (W);
          end if;

          --  Post-render callback (MCP introspection, etc.)
          declare
             Win_H : constant Window_Handle := Get_Handle (W);
             Ren   : constant Adi.SDL.Render.SDL_Renderer_Ptr := W.Internal.ren;
             procedure Call (CB : Post_Render_Proc) is
             begin CB (Win_H, Ren); end Call;
             procedure Emit is new Post_Render_Signals.For_Each (Call);
          begin
             Emit (W.Post_Render);
          end;

          --  Present the rendered frame
          Stage_Start := Now;
          SDL_Assert (SDL_RenderPresent (W.Internal.ren), "SDL_RenderPresent");
          W.Stats_Present_Us := Natural
            (To_Duration (Now - Stage_Start) * 1_000_000.0);
       end if;

       --  Per-frame callback (runs unconditionally, even when idle)
       declare
          Win_H : constant Window_Handle := Get_Handle (W);
          procedure Call (CB : Frame_Proc) is begin CB (Win_H); end Call;
          procedure Emit is new Frame_Signals.For_Each (Call);
       begin
          Emit (W.Frame);
       end;
    end Render;

   procedure Set_Root (W : in out Window; Root : Widget_Handle) is
   begin
      W.Root := Root;
      if Is_Valid (W.Root) then
         Set_Geometry (W.Root, W.Geometry);
         W.Needs_Layout := True;  -- Initial layout needed
         W.Resize_Triggered_Layout := False;
      end if;
      Apply_Window_Min_Size_From_Layout (W);
   end Set_Root;

   procedure Set_Root (H : Window_Handle; Root : Widget_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Set_Root (Ptr.all, Root);
      end if;
   end Set_Root;


   function Get_Root_Handle (W : Window) return Widget_Handle is
   begin
      return W.Root;
   end Get_Root_Handle;

   function Get_Root_Handle (H : Window_Handle) return Widget_Handle is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr = null then
         return Null_Handle;
      end if;
      return Get_Root_Handle (Ptr.all);
   end Get_Root_Handle;

   procedure Set_Enforce_Layout_Min_Size
     (W       : in out Window;
      Enabled : Boolean := True)
   is
      Success : Adi.SDL.C_bool;
   begin
      W.Enforce_Layout_Min_Size := Enabled;
      if Enabled then
         Apply_Window_Min_Size_From_Layout (W);
      elsif W.Internal /= null and then W.Internal.win /= null then
         --  Restore permissive minimum when enforcement is disabled.
         Success := Adi.SDL.Video.SDL_SetWindowMinimumSize (W.Internal.win, 1, 1);
         SDL_Assert (Success, "SDL_SetWindowMinimumSize");
      end if;
   end Set_Enforce_Layout_Min_Size;

   procedure Set_Enforce_Layout_Min_Size
     (H       : Window_Handle;
      Enabled : Boolean := True)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Set_Enforce_Layout_Min_Size (Ptr.all, Enabled);
      end if;
   end Set_Enforce_Layout_Min_Size;

   function Get_Enforce_Layout_Min_Size (W : Window) return Boolean is
   begin
      return W.Enforce_Layout_Min_Size;
   end Get_Enforce_Layout_Min_Size;

   function Get_Enforce_Layout_Min_Size (H : Window_Handle) return Boolean is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         return Get_Enforce_Layout_Min_Size (Ptr.all);
      end if;
      return False;
   end Get_Enforce_Layout_Min_Size;

   procedure Set_UI_Scale (W : in out Window; Scale : Pixel_Type) is
      Before : constant Pixel_Type := Get_Active_UI_Scale;
   begin
      Set_Active_UI_Scale (Scale);
      if abs (Get_Active_UI_Scale - Before) > 0.0001 then
         Invalidate_For_Scale_Change (W);
      end if;
   end Set_UI_Scale;

   procedure Set_UI_Scale (H : Window_Handle; Scale : Pixel_Type) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Set_UI_Scale (Ptr.all, Scale);
      end if;
   end Set_UI_Scale;

   function Get_UI_Scale (W : Window) return Pixel_Type is
      pragma Unreferenced (W);
   begin
      return Get_Active_UI_Scale;
   end Get_UI_Scale;

   function Get_UI_Scale (H : Window_Handle) return Pixel_Type is
      pragma Unreferenced (H);
   begin
      return Get_Active_UI_Scale;
   end Get_UI_Scale;

   procedure Set_Text_Scale (W : in out Window; Scale : Pixel_Type) is
      Before : constant Pixel_Type := Get_Active_Text_Scale;
   begin
      Set_Active_Text_Scale (Scale);
      if abs (Get_Active_Text_Scale - Before) > 0.0001 then
         Invalidate_For_Scale_Change (W);
      end if;
   end Set_Text_Scale;

   procedure Set_Text_Scale (H : Window_Handle; Scale : Pixel_Type) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Set_Text_Scale (Ptr.all, Scale);
      end if;
   end Set_Text_Scale;

   function Get_Text_Scale (W : Window) return Pixel_Type is
      pragma Unreferenced (W);
   begin
      return Get_Active_Text_Scale;
   end Get_Text_Scale;

   function Get_Text_Scale (H : Window_Handle) return Pixel_Type is
      pragma Unreferenced (H);
   begin
      return Get_Active_Text_Scale;
   end Get_Text_Scale;

   procedure Set_Root_Font_Size
     (W    : in out Window;
      Size : CSS_Styles.Length_Value)
   is
   begin
      if W.Root_Font_Size /= Size then
         W.Root_Font_Size := Size;
         Invalidate_For_Scale_Change (W);
      end if;
   end Set_Root_Font_Size;

   procedure Set_Root_Font_Size
     (H    : Window_Handle;
      Size : CSS_Styles.Length_Value)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Set_Root_Font_Size (Ptr.all, Size);
      end if;
   end Set_Root_Font_Size;

   function Get_Root_Font_Size (W : Window) return CSS_Styles.Length_Value is
   begin
      return W.Root_Font_Size;
   end Get_Root_Font_Size;

   function Get_Root_Font_Size (H : Window_Handle)
     return CSS_Styles.Length_Value
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         return Ptr.Root_Font_Size;
      end if;
      return (Amount => Float (Default_Root_Font_Size_Px), Unit => CSS_Styles.Px);
   end Get_Root_Font_Size;

   procedure Maximize (W : in out Window) is
      Ignored : Adi.SDL.C_bool;
   begin
      Ignored := Adi.SDL.Video.SDL_MaximizeWindow (W.Internal.win);
   end Maximize;

   procedure Maximize (H : Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then Maximize (Ptr.all); end if;
   end Maximize;

   procedure Minimize (W : in out Window) is
      Ignored : Adi.SDL.C_bool;
   begin
      Ignored := Adi.SDL.Video.SDL_MinimizeWindow (W.Internal.win);
   end Minimize;

   procedure Minimize (H : Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then Minimize (Ptr.all); end if;
   end Minimize;

   procedure Restore (W : in out Window) is
      Ignored : Adi.SDL.C_bool;
   begin
      Ignored := Adi.SDL.Video.SDL_RestoreWindow (W.Internal.win);
   end Restore;

   procedure Restore (H : Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then Restore (Ptr.all); end if;
   end Restore;

   procedure Set_Fullscreen (W : in out Window; Enabled : Boolean) is
      Ignored : Adi.SDL.C_bool;
   begin
      Ignored := Adi.SDL.Video.SDL_SetWindowFullscreen
        (W.Internal.win, Adi.SDL.C_bool (Enabled));
   end Set_Fullscreen;

   procedure Set_Fullscreen (H : Window_Handle; Enabled : Boolean) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then Set_Fullscreen (Ptr.all, Enabled); end if;
   end Set_Fullscreen;

   function Is_Maximized (W : Window) return Boolean is
   begin
      return (Adi.SDL.Video.SDL_GetWindowFlags (W.Internal.win)
              and Adi.SDL.Video.SDL_WINDOW_MAXIMIZED) /= 0;
   end Is_Maximized;

   function Is_Maximized (H : Window_Handle) return Boolean is
      Ptr : constant Window_Access := Live (H);
   begin
      return Ptr /= null and then Is_Maximized (Ptr.all);
   end Is_Maximized;

   function Is_Minimized (W : Window) return Boolean is
   begin
      return (Adi.SDL.Video.SDL_GetWindowFlags (W.Internal.win)
              and Adi.SDL.Video.SDL_WINDOW_MINIMIZED) /= 0;
   end Is_Minimized;

   function Is_Minimized (H : Window_Handle) return Boolean is
      Ptr : constant Window_Access := Live (H);
   begin
      return Ptr /= null and then Is_Minimized (Ptr.all);
   end Is_Minimized;

   function Is_Fullscreen (W : Window) return Boolean is
   begin
      return (Adi.SDL.Video.SDL_GetWindowFlags (W.Internal.win)
              and Adi.SDL.Video.SDL_WINDOW_FULLSCREEN) /= 0;
   end Is_Fullscreen;

   function Is_Fullscreen (H : Window_Handle) return Boolean is
      Ptr : constant Window_Access := Live (H);
   begin
      return Ptr /= null and then Is_Fullscreen (Ptr.all);
   end Is_Fullscreen;

   procedure Connect_Tick (W : in out Window; CB : Tick_Callback) is
   begin
      W.Tick_Sig.Connect (CB);
   end Connect_Tick;

   procedure Connect_Tick
     (H : Window_Handle;
      CB : Tick_Callback)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Connect_Tick (Ptr.all, CB);
      end if;
   end Connect_Tick;

   function Connect_Tick (W : in out Window; CB : Tick_Callback)
      return Tick_Signals.Connection_Id is
   begin
      return W.Tick_Sig.Connect (CB);
   end Connect_Tick;

   procedure Disconnect_Tick
     (W : in out Window; Id : Tick_Signals.Connection_Id) is
   begin
      W.Tick_Sig.Disconnect (Id);
   end Disconnect_Tick;

   procedure Connect_Key_Down (W : in out Window; CB : Key_Down_Callback) is
   begin
      W.Key_Down_Sig.Connect (CB);
   end Connect_Key_Down;

   procedure Connect_Key_Down
     (H  : Window_Handle;
      CB : Key_Down_Callback)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Connect_Key_Down (Ptr.all, CB);
      end if;
   end Connect_Key_Down;

   function Connect_Key_Down
     (W : in out Window; CB : Key_Down_Callback)
      return Key_Down_Signals.Connection_Id is
   begin
      return W.Key_Down_Sig.Connect (CB);
   end Connect_Key_Down;

   procedure Disconnect_Key_Down
     (W : in out Window; Id : Key_Down_Signals.Connection_Id) is
   begin
      W.Key_Down_Sig.Disconnect (Id);
   end Disconnect_Key_Down;

   procedure Add_Overlay (W : in out Window; Overlay : Widget_Handle) is
   begin
      if not Is_Valid (Overlay) then
         return;
      end if;

      declare
         Existing : constant Natural := Overlay_Index (W, Overlay);
      begin
         if Existing > 0 then
            W.Overlays.Delete (Existing);
         end if;
      end;

      W.Overlays.Append (Overlay);
      Mark_Dirty (Overlay);
      if Is_Valid (W.Root) then
         Mark_Dirty (W.Root);
      end if;
      W.Needs_Layout := True;
   end Add_Overlay;

   procedure Remove_Overlay (W : in out Window; Overlay : Widget_Handle) is
      Existing : Natural;
   begin
      if not Is_Valid (Overlay) then
         return;
      end if;

      Existing := Overlay_Index (W, Overlay);
      if Existing = 0 then
         return;
      end if;

      --  Clear refs if they point into the removed overlay subtree
      if Is_Valid (W.Focused_Widget)
        and then Is_In_Subtree (Overlay, W.Focused_Widget)
      then
         Set_Focused_Widget (W, Null_Handle);
      end if;

      if Is_Valid (W.Hovered_Widget)
        and then Is_In_Subtree (Overlay, W.Hovered_Widget)
      then
         Release_Hover_In_Subtree (W, Overlay);
      end if;

      if Is_Valid (W.Pressed_Widget)
        and then Is_In_Subtree (Overlay, W.Pressed_Widget)
      then
         Release_Pressed_Widget (W);
      end if;

      W.Overlays.Delete (Existing);
      if Is_Valid (W.Root) then
         Mark_Dirty (W.Root);
      end if;
      W.Needs_Layout := True;
   end Remove_Overlay;

   procedure Clear_Overlays (W : in out Window) is
   begin
      if W.Overlays.Is_Empty then
         return;
      end if;

      --  Clear refs if they point into any overlay subtree
      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            OH : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (W.Focused_Widget)
              and then Is_In_Subtree (OH, W.Focused_Widget)
            then
               Set_Focused_Widget (W, Null_Handle);
            end if;

            if Is_Valid (W.Hovered_Widget)
              and then Is_In_Subtree (OH, W.Hovered_Widget)
            then
               Release_Hover_In_Subtree (W, OH);
            end if;

            if Is_Valid (W.Pressed_Widget)
              and then Is_In_Subtree (OH, W.Pressed_Widget)
            then
               Release_Pressed_Widget (W);
            end if;
         end;
      end loop;

      W.Overlays.Clear;
      if Is_Valid (W.Root) then
         Mark_Dirty (W.Root);
      end if;
      W.Needs_Layout := True;
   end Clear_Overlays;

   function Overlay_Count (H : Window_Handle) return Natural is
   begin
      if not Is_Valid (H) then
         return 0;
      end if;
      declare
         R : constant Window_Ref := Borrow (H);
      begin
         return Overlay_Count (R.Ptr.all);
      end;
   end Overlay_Count;

   function Overlay_Count (W : Window) return Natural is
   begin
      return Natural (W.Overlays.Length);
   end Overlay_Count;

   function Get_Overlay_Handle (W : Window; Index : Positive)
      return Widget_Handle
   is
   begin
      return W.Overlays.Element (Index);
   end Get_Overlay_Handle;

   function Get_Overlay_Handle (H : Window_Handle; Index : Positive)
      return Widget_Handle
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr = null or else Index > Overlay_Count (Ptr.all) then
         return Null_Handle;
      end if;
      return Get_Overlay_Handle (Ptr.all, Index);
   end Get_Overlay_Handle;

   function Get_Focus_Handle (W : Window) return Widget_Handle is
   begin
      return W.Focused_Widget;
   end Get_Focus_Handle;

   function Get_Focus_Handle (H : Window_Handle) return Widget_Handle is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr = null then
         return Null_Handle;
      end if;
      return Get_Focus_Handle (Ptr.all);
   end Get_Focus_Handle;

   procedure Add_Overlay (H : Window_Handle; Overlay : Widget_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Add_Overlay (Ptr.all, Overlay);
      end if;
   end Add_Overlay;

   procedure Remove_Overlay (H : Window_Handle; Overlay : Widget_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Remove_Overlay (Ptr.all, Overlay);
      end if;
   end Remove_Overlay;

   function Get_Size (H : Window_Handle) return Size_2D is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         return Get_Size (Ptr.all);
      end if;
      return (0.0, 0.0);
   end Get_Size;

   procedure Clear_Overlays (H : Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Clear_Overlays (Ptr.all);
      end if;
   end Clear_Overlays;

   procedure Render (H : Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Render (Ptr.all);
      end if;
   end Render;

   procedure Handle_Resize (H : Window_Handle; New_Size : Size_2D) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Handle_Resize (Ptr.all, New_Size);
      end if;
   end Handle_Resize;

   function Get_SDL_Window (H : Window_Handle) return SDL_Window_Ptr is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         return Get_SDL_Window (Ptr.all);
      end if;
      return null;
   end Get_SDL_Window;

   procedure On_Mouse_Wheel
      (H                : Window_Handle;
       X, Y             : Pixel_Type;
       Delta_X, Delta_Y : Pixel_Type)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Mouse_Wheel (Ptr.all, X, Y, Delta_X, Delta_Y);
      end if;
   end On_Mouse_Wheel;

   procedure On_Key_Down
      (H        : Window_Handle;
       Scancode : Adi.SDL.Events.SDL_Scancode;
       Keycode  : Adi.SDL.Events.SDL_Keycode;
       Key_Mod  : Adi.SDL.Events.SDL_Keymod;
       Repeat   : Boolean)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Key_Down (Ptr.all, Scancode, Keycode, Key_Mod, Repeat);
      end if;
   end On_Key_Down;

   procedure On_Key_Up
      (H        : Window_Handle;
       Scancode : Adi.SDL.Events.SDL_Scancode;
       Key_Mod  : Adi.SDL.Events.SDL_Keymod;
       Repeat   : Boolean)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Key_Up (Ptr.all, Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Up;

   procedure Clear_Widget_Refs_In_Subtree
     (W      : in out Window;
      Target : Widget_Handle)
   is
   begin
      if not Is_Valid (Target) then
         return;
      end if;

      if Is_Valid (W.Focused_Widget)
        and then Is_In_Subtree (Target, W.Focused_Widget)
      then
         Set_Focused_Widget (W, Null_Handle);
      end if;

      if Is_Valid (W.Hovered_Widget)
        and then Is_In_Subtree (Target, W.Hovered_Widget)
      then
         Release_Hover_In_Subtree (W, Target);
      end if;

      if Is_Valid (W.Pressed_Widget)
        and then Is_In_Subtree (Target, W.Pressed_Widget)
      then
         Release_Pressed_Widget (W);
      end if;
   end Clear_Widget_Refs_In_Subtree;

   ------------------
   -- Get_Renderer --
   ------------------

   function Get_SDL_Window (W : Window) return Adi.SDL.Video.SDL_Window_Ptr is
   begin
      if W.Internal = null then
         return null;
      end if;
      return W.Internal.win;
   end Get_SDL_Window;

   function Get_Renderer (W : in out Window) return SDL_Renderer_Ptr is
   begin
      return W.Internal.ren;
   end Get_Renderer;

   ---------------------
   -- Point_In_Widget --
   ---------------------

   function Point_In_Widget (Wgt : Widget_Handle; X, Y : Pixel_Type) return Boolean is
      G : Rectangle;
   begin
      if not Is_Valid (Wgt) then
         return False;
      end if;

      G := Get_Geometry (Wgt);
      return X >= G.X and then X <= G.X + G.Width and then
             Y >= G.Y and then Y <= G.Y + G.Height;
   end Point_In_Widget;


   ---------------------------------
   -- Map_Window_Point_To_Widget --
   --
   --  Window coordinates are what the pointer reports; widget geometry
   --  is stored unshifted by scrolling. Rendering bridges the two by
   --  translating children of a scrolled widget, so a point handed to a
   --  widget has to be translated the same way before that widget can
   --  compare it against its own geometry.
   --
   --  Adds the scroll offset of every ancestor of Target, excluding
   --  Target itself: a widget's own scrolling moves its children, not
   --  the widget.
   ---------------------------------

   function Ancestor_Scroll_Offset_Y (Target : Widget_Handle) return Pixel_Type
   is
      Node : Widget_Handle := Get_Parent_Handle (Target);
      Sum  : Pixel_Type := 0.0;
   begin
      while Is_Valid (Node) loop
         Sum := Sum + Get_Scroll_Offset_Y (Node);
         Node := Get_Parent_Handle (Node);
      end loop;
      return Sum;
   end Ancestor_Scroll_Offset_Y;

   procedure Map_Window_Point_To_Widget
     (Target : Widget_Handle;
      X, Y   : in out Pixel_Type)
   is
      --  X passes through untouched: there is no horizontal scrolling
      --  yet. It stays in the profile so call sites need not change
      --  when there is.
      pragma Unreferenced (X);
   begin
      Y := Y + Ancestor_Scroll_Offset_Y (Target);
   end Map_Window_Point_To_Widget;

   function Geometry_In_Window (Wgt : Widget_Handle) return Rectangle is
   begin
      return To_Window_Space (Wgt, Get_Geometry (Wgt));
   end Geometry_In_Window;

   function To_Window_Space
     (Wgt : Widget_Handle; R : Rectangle) return Rectangle is
   begin
      if not Is_Valid (Wgt) then
         return R;
      end if;
      return (X      => R.X,
              Y      => R.Y - Ancestor_Scroll_Offset_Y (Wgt),
              Width  => R.Width,
              Height => R.Height);
   end To_Window_Space;

   function Mapped_Y
     (Target : Widget_Handle; X, Y : Pixel_Type) return Pixel_Type
   is
      Mx : Pixel_Type := X;
      My : Pixel_Type := Y;
   begin
      Map_Window_Point_To_Widget (Target, Mx, My);
      return My;
   end Mapped_Y;

   function Find_Widget_At (W : Window; X, Y : Pixel_Type) return Widget_Handle is

      function Find_Deepest
        (Parent   : Widget_Handle;
         Hit_X    : Pixel_Type;
         Hit_Y    : Pixel_Type;
         Parent_Visibility : Visibility_Value) return Widget_Handle
      is
         Child_H  : Widget_Handle;
         Found    : Widget_Handle;
         Child_Y  : Pixel_Type;
         Node_Visibility : Visibility_Value;
      begin
         if not Is_Valid (Parent) then
            return Null_Handle;
         end if;

         if not Widget_Participates (Parent) then
            return Null_Handle;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Parent, Parent_Visibility);

         --  Check if point is in parent first
         if not Point_In_Widget (Parent, Hit_X, Hit_Y) then
            return Null_Handle;
         end if;

         --  When parent scrolls, children are rendered shifted by
         --  -Scroll_Offset_Y.  Reverse the shift so the hit coordinate
         --  maps to the child's stored (unshifted) geometry.
         Child_Y := Hit_Y;
         if Get_Scroll_Offset_Y (Parent) > 0.0 then
            Child_Y := Hit_Y + Get_Scroll_Offset_Y (Parent);
         end if;

         --  Check children in reverse order (last added = on top)
         for I in reverse 1 .. Child_Count (Parent) loop
            Child_H := Get_Child_Handle (Parent, I);
            Found := Find_Deepest (Child_H, Hit_X, Child_Y, Node_Visibility);
            if Is_Valid (Found) then
               return Found;
            end if;
         end loop;

         --  No child contains point, return this widget only when it is
         --  effectively visible. Hidden parents can still expose visible
         --  descendants via explicit visibility overrides.
         if Node_Visibility = Visibility_Visible then
            return Parent;
         end if;
         return Null_Handle;
      end Find_Deepest;

   begin
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Handle := W.Overlays.Element (I);
            Found   : Widget_Handle;
         begin
            if not Is_Valid (Overlay) then
               null;
            else
               Found := Find_Deepest (Overlay, X, Y, Visibility_Visible);
               if Is_Valid (Found) then
                  return Found;
               end if;
            end if;
         end;
      end loop;

      return Find_Deepest (W.Root, X, Y, Visibility_Visible);
   end Find_Widget_At;

   function Find_Widget_At_With_Flag
     (W    : Window;
      X, Y : Pixel_Type;
      F    : Widget_Flag) return Widget_Handle
   is
      --  Whatever is visually on top owns the point, so the search starts
      --  there and walks up. Looking for the deepest widget *carrying the
      --  flag* instead skips past whatever covers it: a dialog with
      --  nothing focusable under the cursor let the focus search fall
      --  through to the root tree and focus the widget behind it, whose
      --  focus ring then lit up through the dialog.
      --
      --  Walking ancestors keeps the bubbling the filter was there for:
      --  a click on the label inside a button still finds the button.
      Node : Widget_Handle := Find_Widget_At (W, X, Y);
   begin
      while Is_Valid (Node) loop
         if Has_Flag (Node, F) then
            return Node;
         end if;
         Node := Get_Parent_Handle (Node);
      end loop;

      return Null_Handle;
   end Find_Widget_At_With_Flag;

   function Find_Scroll_Widget_At
     (W    : Window;
      X, Y : Pixel_Type) return Widget_Handle
   is
      Node : Widget_Handle := Find_Widget_At (W, X, Y);
   begin
      --  Each candidate sits under a different set of scrolled
      --  ancestors, so the point is re-mapped per candidate rather than
      --  translated once for the whole walk.
      while Is_Valid (Node) loop
         if Get_Part_At (Node, X, Mapped_Y (Node, X, Y))
              in Scroll_Part | Knob_Part
         then
            return Node;
         end if;
         Node := Get_Parent_Handle (Node);
      end loop;

      return Null_Handle;
   end Find_Scroll_Widget_At;

   ---------------------------------------------------------------------------
   --  Hover bookkeeping.
   --
   --  The widgets carrying State_Hovered are exactly the ancestor chain
   --  of W.Hovered_Widget, and the part-level hover lives on that widget
   --  alone.  Every path that changes what is hovered goes through these
   --  so the two never disagree.
   ---------------------------------------------------------------------------

   Max_Ancestor_Depth : constant := 64;
   type Widget_Chain is array (Positive range <>) of Widget_Handle;

   procedure Build_Hover_Chain
     (Start : Widget_Handle;
      Chain : out Widget_Chain;
      Count : out Natural)
   is
      Node : Widget_Handle := Start;
   begin
      Count := 0;
      while Is_Valid (Node) and then Count < Chain'Length loop
         Count := Count + 1;
         Chain (Count) := Node;
         Node := Get_Parent_Handle (Node);
      end loop;
   end Build_Hover_Chain;

   function In_Chain
     (Node  : Widget_Handle;
      Chain : Widget_Chain;
      Count : Natural) return Boolean is
   begin
      for I in 1 .. Count loop
         if Chain (I) = Node then
            return True;
         end if;
      end loop;
      return False;
   end In_Chain;

   procedure Update_Hover_Ancestors
     (Old_Node : Widget_Handle;
      New_Node : Widget_Handle)
   is
      Old_Chain : Widget_Chain (1 .. Max_Ancestor_Depth);
      New_Chain : Widget_Chain (1 .. Max_Ancestor_Depth);
      Old_Count : Natural := 0;
      New_Count : Natural := 0;
   begin
      Build_Hover_Chain (Old_Node, Old_Chain, Old_Count);
      Build_Hover_Chain (New_Node, New_Chain, New_Count);

      --  Clear hover only for nodes that are not common ancestors anymore.
      for I in 1 .. Old_Count loop
         if not In_Chain (Old_Chain (I), New_Chain, New_Count) then
            Set_Hovered (Old_Chain (I), False);
         end if;
      end loop;

      --  Set hover for newly entered nodes.
      for I in 1 .. New_Count loop
         if not In_Chain (New_Chain (I), Old_Chain, Old_Count) then
            Set_Hovered (New_Chain (I), True);
         end if;
      end loop;
   end Update_Hover_Ancestors;

   procedure Clear_Hover_For_Part
     (Target : Widget_Handle;
      P      : Part_Kind) is
   begin
      Set_Part_State (Target, P, Adi.Widget_Styles.State_Hovered, False);
      --  Knob sits on top of scroll track; clear both when leaving knob.
      if P = Knob_Part then
         Set_Part_State (Target, Scroll_Part,
                         Adi.Widget_Styles.State_Hovered, False);
      end if;
   end Clear_Hover_For_Part;

   procedure Set_Hover_For_Part
     (Target : Widget_Handle;
      P      : Part_Kind) is
   begin
      Set_Part_State (Target, P, Adi.Widget_Styles.State_Hovered, True);
      --  Hovering knob should also visually highlight the track beneath it.
      if P = Knob_Part then
         Set_Part_State (Target, Scroll_Part,
                         Adi.Widget_Styles.State_Hovered, True);
      end if;
   end Set_Hover_For_Part;

   --  Hover is withdrawn from the subtree rooted at Root.  The pointer
   --  has not moved, so the first ancestor outside that subtree is still
   --  under it: it keeps its hover and takes over as the hovered widget.
   --  For a standalone root -- an overlay -- there is no such ancestor
   --  and the chain clears entirely.
   procedure Release_Hover_In_Subtree
     (W    : in out Window;
      Root : Widget_Handle)
   is
      Anchor : constant Widget_Handle := Get_Parent_Handle (Root);
   begin
      Update_Hover_Ancestors (W.Hovered_Widget, Anchor);
      Clear_Hover_For_Part (W.Hovered_Widget, W.Hovered_Part);

      W.Hovered_Widget := Anchor;
      if Is_Valid (Anchor) then
         W.Hovered_Part :=
           Get_Part_At (Anchor, W.Mouse_X,
                        Mapped_Y (Anchor, W.Mouse_X, W.Mouse_Y));
         Set_Hover_For_Part (Anchor, W.Hovered_Part);
      else
         W.Hovered_Part := Main_Part;
      end if;
   end Release_Hover_In_Subtree;

   --  Pressed state, unlike hover, is only ever held by the pressed
   --  widget itself, so there is no chain to walk.
   procedure Release_Pressed_Widget (W : in out Window) is
   begin
      --  A scrollbar drag is held by the widget as well as by the
      --  window, and the release that would have ended it is never
      --  going to arrive.
      if W.Scroll_Claimed then
         Handle_Scroll_Mouse_Up (W.Pressed_Widget, Left_Button);
      end if;

      Set_Part_State (W.Pressed_Widget, W.Pressed_Part,
                      Adi.Widget_Styles.State_Pressed, False);
      Set_Pressed (W.Pressed_Widget, False);

      W.Pressed_Widget := Null_Handle;
      W.Pressed_Part   := Main_Part;
      W.Scroll_Claimed := False;
   end Release_Pressed_Widget;

   ------------------------
   -- Set_Focused_Widget --
   ------------------------

   procedure Set_Focused_Widget
     (W         : in out Window;
      New_Focus : Widget_Handle)
   is
      Candidate : Widget_Handle := New_Focus;
      Ignore    : Adi.SDL.C_bool;
   begin
      if Is_Valid (Candidate) and then not Is_Focus_Candidate (Candidate) then
         Candidate := Null_Handle;
      end if;

      if Candidate = W.Focused_Widget then
         return;
      end if;

      if Is_Valid (W.Focused_Widget) then
         Set_Focused (W.Focused_Widget, False);
         On_Focus_Lost (W.Focused_Widget);
      end if;

      W.Focused_Widget := Candidate;

      if Is_Valid (W.Focused_Widget) then
         Ignore := Adi.SDL.Video.SDL_StartTextInput (W.Internal.win);
         Set_Focused (W.Focused_Widget, True);
         On_Focus_Gained (W.Focused_Widget);
      else
         Ignore := Adi.SDL.Video.SDL_StopTextInput (W.Internal.win);
      end if;
   end Set_Focused_Widget;

   ---------------
   -- Set_Focus --
   ---------------

   procedure Set_Focus (W : in out Window; Target : Widget_Handle) is
   begin
      if Target = Null_Handle then
         Set_Focused_Widget (W, Null_Handle);
         return;
      end if;

      if not Window_Contains_Widget (W, Target) then
         return;
      end if;
      Set_Focused_Widget (W, Target);
   end Set_Focus;

   procedure Set_Focus (H : Window_Handle; Target : Widget_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Set_Focus (Ptr.all, Target);
      end if;
   end Set_Focus;

   -------------------
   -- On_Mouse_Move --
   -------------------
procedure On_Mouse_Move (W : in out Window; X, Y : Pixel_Type) is
      New_Hovered : Widget_Handle;
      New_Part    : Part_Kind;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Find widget under cursor
      New_Hovered := Find_Scroll_Widget_At (W, X, Y);
      if not Is_Valid (New_Hovered) then
         New_Hovered := Find_Widget_At (W, X, Y);
      end if;

      --  Handle hover state changes
      if New_Hovered /= W.Hovered_Widget then
         --  Update widget hover state across ancestor chains.
         Update_Hover_Ancestors (W.Hovered_Widget, New_Hovered);

         if Is_Valid (W.Hovered_Widget) then
            Clear_Hover_For_Part (W.Hovered_Widget, W.Hovered_Part);
         end if;

         --  Set hover on new widget
         if Is_Valid (New_Hovered) then
            New_Part := Get_Part_At (New_Hovered, X,
                                     Mapped_Y (New_Hovered, X, Y));
            Set_Hover_For_Part (New_Hovered, New_Part);
            W.Hovered_Part := New_Part;
         else
            W.Hovered_Part := Main_Part;
         end if;

         W.Hovered_Widget := New_Hovered;
      elsif Is_Valid (W.Hovered_Widget) then
         New_Part := Get_Part_At (W.Hovered_Widget, X,
                                  Mapped_Y (W.Hovered_Widget, X, Y));
         if New_Part /= W.Hovered_Part then
            Clear_Hover_For_Part (W.Hovered_Widget, W.Hovered_Part);
            Set_Hover_For_Part (W.Hovered_Widget, New_Part);
            W.Hovered_Part := New_Part;
         end if;
      end if;

      --  Route drag motion to the pressed widget (for text selection, etc.)
      if W.Mouse_Down and then Is_Valid (W.Pressed_Widget)
        and then not Is_Disabled (W.Pressed_Widget)
      then
         declare
            MY : constant Pixel_Type :=
              Mapped_Y (W.Pressed_Widget, X, Y);
         begin
            if W.Scroll_Claimed then
               Handle_Scroll_Mouse_Move (W.Pressed_Widget, X, MY);
            else
               Adi.Widget.On_Mouse_Move (W.Pressed_Widget, X, MY);
            end if;
         end;
      end if;
   end On_Mouse_Move;

   -------------------
   -- On_Mouse_Down --
   -------------------

    procedure On_Mouse_Down
      (W      : in out Window;
       X, Y   : Pixel_Type;
       Button : Adi.Core.Mouse_Button;
       Clicks : Natural := 1)
    is
      Guard : Dispatch_Guard;
      pragma Unreferenced (Guard);
      Click_Target  : Widget_Handle := Null_Handle;
      Focus_Target  : Widget_Handle := Null_Handle;
      Scroll_Target : Widget_Handle := Null_Handle;
      Any_Target    : Widget_Handle := Null_Handle;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;
      W.Mouse_Down := (Button = Left_Button);

      --  Focus and click routing should target interactive widgets,
      --  not passive leaf children such as labels inside list rows.
      Focus_Target := Find_Widget_At_With_Flag (W, X, Y, Focusable);

      --  Right-click opens context menus without entering pressed/drag state.
      if Button = Right_Button then
         Any_Target := Find_Widget_At (W, X, Y);
         if Is_Valid (Any_Target) then
            if Bubble_Context_Menu (Any_Target, X, Y) then
               return;
            end if;
         end if;
         return;
      end if;

      Click_Target := Find_Widget_At_With_Flag (W, X, Y, Clickable);
      Scroll_Target := Find_Scroll_Widget_At (W, X, Y);

      --  Disabled widgets do not receive clicks or focus.
      if Is_Valid (Click_Target) and then Is_Disabled (Click_Target) then
         Click_Target := Null_Handle;
      end if;
      if Is_Valid (Focus_Target) and then Is_Disabled (Focus_Target) then
         Focus_Target := Null_Handle;
      end if;

      --  Allow dragging scrollbar parts on non-clickable containers
      --  (e.g. a scrollable root panel).
      if not Is_Valid (Click_Target) and then Is_Valid (Scroll_Target) then
         if Get_Part_At (Scroll_Target, X, Mapped_Y (Scroll_Target, X, Y))
              in Scroll_Part | Knob_Part
         then
            Click_Target := Scroll_Target;
         end if;
      end if;

      --  A press whose release never arrived -- the pointer left the
      --  window, or another button went down meanwhile -- must not leave
      --  its target stuck.
      Release_Pressed_Widget (W);

      if Is_Valid (Click_Target) then
         declare
            --  Translate into the target's own space before anything
            --  compares this point against its geometry.
            CY : constant Pixel_Type := Mapped_Y (Click_Target, X, Y);
         begin
            W.Pressed_Part := Get_Part_At (Click_Target, X, CY);
            Set_Pressed (Click_Target, True);
            Set_Part_State (Click_Target,
                            W.Pressed_Part,
                            Adi.Widget_Styles.State_Pressed,
                            True);
            W.Pressed_Widget := Click_Target;
            if W.Pressed_Part in Scroll_Part | Knob_Part then
               W.Scroll_Claimed :=
                 Handle_Scroll_Mouse_Down (Click_Target, X, CY, Button);
               if not W.Scroll_Claimed then
                  Adi.Widget.On_Mouse_Down (Click_Target, X, CY, Button, Clicks);
               end if;
            else
               Adi.Widget.On_Mouse_Down (Click_Target, X, CY, Button, Clicks);
            end if;
         end;
      end if;

      Set_Focused_Widget (W, Focus_Target);
   end On_Mouse_Down;

   --  A release completes a click only while the pointer is still over
   --  the widget that was pressed. Ask the hit test rather than
   --  comparing raw geometry: that way a release over a clipped-away
   --  part of the widget, or over an overlay covering it, does not
   --  count.
   function Release_Is_Within
     (W : Window; PW : Widget_Handle; X, Y : Pixel_Type) return Boolean
   is
      Hit : Widget_Handle := Find_Widget_At (W, X, Y);
   begin
      while Is_Valid (Hit) loop
         if Hit = PW then
            return True;
         end if;
         Hit := Get_Parent_Handle (Hit);
      end loop;
      return False;
   end Release_Is_Within;

   -----------------
   -- On_Mouse_Up --
   -----------------
   procedure On_Mouse_Up
      (W : in out Window; X, Y : Pixel_Type; Button : Adi.Core.Mouse_Button)
    is
      Guard : Dispatch_Guard;
      pragma Unreferenced (Guard);
      --  Save pressed widget/part before dispatching, because On_Mouse_Up
      --  or On_Click callbacks (e.g. dialog dismiss) may clear them.
      Pressed_At_Entry : constant Widget_Handle := W.Pressed_Widget;
      PW   : Widget_Handle := Pressed_At_Entry;
      Part : constant Part_Kind := W.Pressed_Part;
   begin
      W.Mouse_Down := False;
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Release pressed widget and dispatch click if applicable
      if Is_Valid (PW) then
         if W.Scroll_Claimed then
            Handle_Scroll_Mouse_Up (PW, Button);
         else
            Adi.Widget.On_Mouse_Up (PW, X, Mapped_Y (PW, X, Y), Button);
         end if;

         --  Re-read: callback may have cleared W.Pressed_Widget
         --  (e.g. Remove_Overlay from a dialog dismiss).
         if not Is_Valid (W.Pressed_Widget) then
            PW := Null_Handle;
         end if;

         if Is_Valid (PW)
            and then Release_Is_Within (W, PW, X, Y)
            and then Has_Flag (PW, Clickable)
            and then Button = Left_Button
            and then not Is_Disabled (PW)
         then
            Adi.Widget.On_Click (PW);
         end if;

         --  Releasing the state follows the widget, not the window's
         --  reference to it: a callback may have dropped that reference
         --  while the widget itself lives on.
         if Is_Valid (Pressed_At_Entry) then
            Set_Part_State (Pressed_At_Entry, Part,
                            Adi.Widget_Styles.State_Pressed, False);
            Set_Pressed (Pressed_At_Entry, False);
         end if;

         W.Pressed_Widget := Null_Handle;
         W.Pressed_Part := Main_Part;
         W.Scroll_Claimed := False;
      end if;
   end On_Mouse_Up;

   --------------------
   -- On_Mouse_Wheel --
   --------------------

   procedure On_Mouse_Wheel
      (W                : in out Window;
       X, Y             : Pixel_Type;
       Delta_X, Delta_Y : Pixel_Type)
   is
      Guard      : Dispatch_Guard;
      pragma Unreferenced (Guard);
      Target     : Widget_Handle := Null_Handle;
      In_Overlay : Boolean := False;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Check if cursor is over any overlay subtree, using the same
      --  participation/visibility eligibility as normal hit-testing.
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (Overlay)
              and then Widget_Participates (Overlay)
              and then Resolve_Effective_Visibility
                (Overlay, Visibility_Visible) = Visibility_Visible
              and then Point_In_Widget (Overlay, X, Y)
            then
               In_Overlay := True;
               exit;
            end if;
         end;
      end loop;

      Target := Find_Widget_At_With_Flag (W, X, Y, Scrollable);

      if In_Overlay then
         --  Cursor is over an overlay: only accept a scrollable target that
         --  belongs to an overlay subtree.  Discard any target found in root.
         if Is_Valid (Target) then
            declare
               In_Overlay_Tree : Boolean := False;
            begin
               for I in 1 .. Natural (W.Overlays.Length) loop
                  if Is_In_Subtree (W.Overlays.Element (I), Target) then
                     In_Overlay_Tree := True;
                     exit;
                  end if;
               end loop;
               if not In_Overlay_Tree then
                  Target := Null_Handle;
               end if;
            end;
         end if;
         --  No focus fallback when cursor is over an overlay.
      else
         --  No overlay under cursor: allow focus fallback to focused
         --  scrollable widget.
         if not Is_Valid (Target) then
            if Is_Valid (W.Focused_Widget)
              and then Has_Flag (W.Focused_Widget, Scrollable)
            then
               Target := W.Focused_Widget;
            end if;
         end if;
      end if;

      if Is_Valid (Target) and then not Is_Disabled (Target) then
         Adi.Widget.On_Mouse_Wheel (Target, Delta_X, Delta_Y);
      end if;
   end On_Mouse_Wheel;

   -----------------
   -- On_Key_Down --
   -----------------

   procedure On_Key_Down
     (W        : in out Window;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Keycode  : Adi.SDL.Events.SDL_Keycode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
      Guard : Dispatch_Guard;
      pragma Unreferenced (Guard);
      use type Adi.SDL.Events.SDL_Keymod;
      use type Adi.SDL.Events.SDL_Scancode;
      Shift_Mod : constant Boolean :=
        (Key_Mod and Adi.SDL.Events.SDL_KMOD_SHIFT) /= 0;
      Next_Focus : Widget_Handle := Null_Handle;
      Key_Root   : constant Widget_Handle := Active_Key_Root (W);
      Handled    : Boolean := False;
   begin
      declare
         SC : constant Adi.SDL.Events.SDL_Scancode := Scancode;
         KC : constant Adi.SDL.Events.SDL_Keycode  := Keycode;
         KM : constant Adi.SDL.Events.SDL_Keymod   := Key_Mod;
         R  : constant Boolean                     := Repeat;
         procedure Call (CB : Key_Down_Callback) is
         begin CB (SC, KC, KM, R, Handled); end Call;
         procedure Emit is new Key_Down_Signals.For_Each (Call);
      begin
         Emit (W.Key_Down_Sig);
      end;

      --  An app-level hook consumed the event: skip Tab traversal and the
      --  focused-widget dispatch below.  This is the contract that lets
      --  app shortcuts (Esc, Space-to-advance, F-keys) win over whatever
      --  widget happens to have focus.
      if Handled then
         return;
      end if;

      if Scancode = Adi.SDL.Events.SDL_SCANCODE_TAB then
         if Shift_Mod then
            Next_Focus := Prev_Focusable (Key_Root, W.Focused_Widget);
            if not Is_Valid (Next_Focus) then
               Next_Focus := Last_Focusable (Key_Root);
            end if;
         else
            Next_Focus := Next_Focusable (Key_Root, W.Focused_Widget);
            if not Is_Valid (Next_Focus) then
               Next_Focus := First_Focusable (Key_Root);
            end if;
         end if;

         if Is_Valid (Next_Focus) then
            Set_Focused_Widget (W, Next_Focus);
         end if;
         return;
      end if;

      if Is_Valid (W.Focused_Widget)
        and then Is_In_Subtree (Key_Root, W.Focused_Widget)
        and then not Is_Disabled (W.Focused_Widget)
      then
         Adi.Widget.On_Key_Down (W.Focused_Widget, Scancode, Key_Mod, Repeat);

         --  For overlays (modal dialogs), also let the overlay root handle
         --  Escape so that dismiss-on-escape works regardless of which
         --  child widget is focused.
         if Scancode = Adi.SDL.Events.SDL_SCANCODE_ESCAPE
           and then Key_Root /= W.Root
           and then W.Focused_Widget /= Key_Root
         then
            Adi.Widget.On_Key_Down (Key_Root, Scancode, Key_Mod, Repeat);
         end if;
      elsif Is_Valid (Key_Root) then
         Adi.Widget.On_Key_Down (Key_Root, Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Down;

   ---------------
   -- On_Key_Up --
   ---------------

   procedure On_Key_Up
     (W        : in out Window;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
      Guard : Dispatch_Guard;
      pragma Unreferenced (Guard);
   begin
      if Is_Valid (W.Focused_Widget)
        and then Is_In_Subtree (Active_Key_Root (W), W.Focused_Widget)
        and then not Is_Disabled (W.Focused_Widget)
      then
         Adi.Widget.On_Key_Up (W.Focused_Widget, Scancode, Key_Mod, Repeat);
      elsif Is_Valid (Active_Key_Root (W)) then
         Adi.Widget.On_Key_Up (Active_Key_Root (W), Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Up;

   -------------------
   -- On_Text_Input --
   -------------------

   procedure On_Text_Input (W : in out Window; Text : String) is
      Guard : Dispatch_Guard;
      pragma Unreferenced (Guard);
   begin
      if Is_Valid (W.Focused_Widget)
        and then Is_In_Subtree (Active_Key_Root (W), W.Focused_Widget)
        and then not Is_Disabled (W.Focused_Widget)
      then
         Adi.Widget.On_Text_Input (W.Focused_Widget, Text);
      elsif Is_Valid (Active_Key_Root (W)) then
         Adi.Widget.On_Text_Input (Active_Key_Root (W), Text);
      end if;
   end On_Text_Input;

   ----------
   -- Tick --
   ----------

   procedure Tick (W : in out Window; DT : Duration) is
      Guard                : Dispatch_Guard;
      pragma Unreferenced (Guard);
      Root_Dirty_Before    : constant Boolean :=
        (Is_Valid (W.Root) and then Is_Dirty (W.Root));
      Overlay_Dirty_Before : constant Boolean := Is_Any_Overlay_Dirty (W);
      Root_Dirty_After     : Boolean;
      Overlay_Dirty_After  : Boolean;
   begin
      Debug_Tick_No := Debug_Tick_No + 1;
      W.Stats_Last_DT := DT;

      declare
         D : constant Duration := DT;
         procedure Call (CB : Tick_Callback) is begin CB (D); end Call;
         procedure Emit is new Tick_Signals.For_Each (Call);
      begin
         Emit (W.Tick_Sig);
      end;

      if Is_Valid (W.Root) then
         Tick_Animations (W.Root, DT);
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Handle := W.Overlays.Element (I);
         begin
            if Is_Valid (Overlay) then
               Tick_Animations (Overlay, DT);
            end if;
         end;
      end loop;

      Root_Dirty_After := (Is_Valid (W.Root) and then Is_Dirty (W.Root));
      Overlay_Dirty_After := Is_Any_Overlay_Dirty (W);

      if Root_Dirty_After /= Root_Dirty_Before
        or else Overlay_Dirty_After /= Overlay_Dirty_Before
      then
         Debug_Log
           ("tick=" & Natural'Image (Debug_Tick_No)
            & " dt=" & Duration'Image (DT)
            & " root_dirty " & Boolean'Image (Root_Dirty_Before)
            & "->" & Boolean'Image (Root_Dirty_After)
            & " overlay_dirty " & Boolean'Image (Overlay_Dirty_Before)
            & "->" & Boolean'Image (Overlay_Dirty_After));
      end if;
   end Tick;

   -------------
   -- Reshape --
   -------------

   procedure Reshape (W : in out Window; SZ : Size_2D) is
   begin
      Handle_Resize(W, (Width => SZ.Width, Height => SZ.Height));
   end Reshape;
   --------------
   -- Get_Size --
   --------------
function Get_Size (W : in out Window) return Size_2D is
   begin
      return (Width => W.Size.Width, Height => W.Size.Height);
   end Get_Size;

    function Actual_Size(W: in out Window) return Size_2D is
       W_Width, W_Height : aliased int;
    begin
       --  Pixel size, not point size: the layout system, mouse coords (via
       --  SDL_ConvertEventToRenderCoordinates) and the renderer all operate
       --  in physical pixels.
       SDL_Assert (SDL_GetWindowSizeInPixels (W.Internal.win, W_Width'Access, W_Height'Access), "SDL_GetWindowSizeInPixels");
       return (Width => Pixel_Type (W_Width), Height => Pixel_Type (W_Height));
    end Actual_Size;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (W : in out Window) is
   begin
      null;
   end Initialize;

   --------------
   --------------------------
   -- Destroy_Widget_Tree --
   --------------------------

   procedure Destroy_Widget_Tree (W : in out Window) is
   begin
      --  Clear all widget refs first so Destroy hooks don't chase stale state.
      W.Focused_Widget := Null_Handle;
      W.Hovered_Widget := Null_Handle;
      W.Pressed_Widget := Null_Handle;

      --  Destroy overlay widgets (snapshot list since Destroy modifies it)
      declare
         Snapshot : constant Overlay_Vectors.Vector := W.Overlays;
      begin
         W.Overlays.Clear;
         for OH of Snapshot loop
            if Is_Valid (OH) then
               declare
                  H : Widget_Handle := OH;
               begin
                  Destroy (H);
               end;
            end if;
         end loop;
      end;

      --  Destroy root widget tree
      if Is_Valid (W.Root) then
         declare
            H : Widget_Handle := W.Root;
         begin
            W.Root := Null_Handle;
            Destroy (H);
         end;
      end if;
   end Destroy_Widget_Tree;

   procedure Destroy (H : in out Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr = null then
         H.Id := Window_Stores.Null_Id;
         return;
      end if;

      Destroy_Widget_Tree (Ptr.all);
      if Dispatch_Depth > 0 then
         Pending_Destroy_Ids.Append (H.Id);
      else
         Window_Stores.Request_Destroy (H.Id);
      end if;
      H.Id := Window_Stores.Null_Id;
   end Destroy;

   -- Finalize --
   --------------

   overriding procedure Finalize (W : in out Window) is
      procedure Free is new Ada.Unchecked_Deallocation
        (Internal, Internal_Access);
   begin
      --  Destroy widget trees if not already done by Destroy_Widget_Tree.
      --  Flip the library-finalization flag so that Adi.Widget skips the
      --  dispatching On_Destroy / Clear_Items calls — by this point the
      --  widget's tagged-type vtable may already be torn down (its scope
      --  has been finalized) and a dispatching call would fault below
      --  the level where GNAT's signal-to-exception mapping is still
      --  active.  See Destroy_Subtree's comment for the full rationale.
      if Is_Valid (W.Root) or else not W.Overlays.Is_Empty then
         Adi.Widget.Begin_Library_Finalization;
         Destroy_Widget_Tree (W);
         Adi.Widget.End_Library_Finalization;
      end if;

      if W.Internal /= null then
         Unregister_Live_Window (W.Internal.win);
      end if;
      Adi.Render.Destroy (W.Ctx);
      if W.Internal /= null then
         if W.Internal.ren /= null then
            SDL_DestroyRenderer (W.Internal.ren);
         end if;
         if W.Internal.win /= null then
            SDL_DestroyWindow (W.Internal.win);
         end if;
         Free (W.Internal);
      end if;
   end Finalize;

    procedure Handle_Resize (W : in out Window; New_Size : Size_2D) is
      Size_Changed  : constant Boolean :=
        W.Size.Width /= New_Size.Width or else W.Size.Height /= New_Size.Height;
      Scale_Changed : Boolean := False;
    begin
       if Size_Changed then
          W.Size := New_Size;
          W.Geometry := (0.0, 0.0, New_Size.Width, New_Size.Height);

          --  Re-layout root widget if exists
          if Is_Valid (W.Root) then
             Set_Geometry (W.Root, W.Geometry);
             Mark_Dirty (W.Root);
          end if;

          --  Overlays (e.g. dialogs) often recompute their internal panel
          --  geometry during Update/Build_Items, so they must also be dirtied
          --  on size changes, not just scale changes.
          for I in 1 .. Natural (W.Overlays.Length) loop
             declare
                Overlay : constant Widget_Handle := W.Overlays.Element (I);
             begin
                if Is_Valid (Overlay) then
                   Mark_Dirty (Overlay);
                end if;
             end;
          end loop;

          W.Needs_Layout := True;  -- Flag for layout recalculation
          W.Resize_Triggered_Layout := True;
       end if;

       Apply_Render_Logical_Presentation (W);
       Scale_Changed := Refresh_DIP_Scale (W);
       Refresh_Viewport_Size (W);
       if Scale_Changed then
          Invalidate_For_Scale_Change (W);
       end if;
    end Handle_Resize;

    ---------------------
    -- Request_Redraw --
    ---------------------

    procedure Request_Redraw (W : in out Window) is
    begin
       W.Force_Redraw := True;
    end Request_Redraw;

    procedure Set_Debug_Stats (W : in out Window; Enabled : Boolean) is
    begin
       W.Debug_Stats_On := Enabled;
       W.Force_Redraw := True;
    end Set_Debug_Stats;

    procedure Set_Debug_Stats (H : Window_Handle; Enabled : Boolean) is
       Ptr : constant Window_Access := Live (H);
    begin
       if Ptr /= null then
          Set_Debug_Stats (Ptr.all, Enabled);
       end if;
    end Set_Debug_Stats;

    procedure Set_Texture_Budget
      (W : in out Window; Bytes : Adi.Texture_Cache.Byte_Count) is
    begin
       Adi.Render.Set_Texture_Budget (W.Ctx, Bytes);
    end Set_Texture_Budget;

    procedure Set_Texture_Budget
      (H : Window_Handle; Bytes : Adi.Texture_Cache.Byte_Count)
    is
       Ptr : constant Window_Access := Live (H);
    begin
       if Ptr /= null then
          Set_Texture_Budget (Ptr.all, Bytes);
       end if;
    end Set_Texture_Budget;

    function Get_Texture_Stats (W : Window) return Texture_Stats
    is (Adi.Render.Get_Texture_Stats (W.Ctx));

    function Get_Texture_Stats (H : Window_Handle) return Texture_Stats is
       Ptr : constant Window_Access := Live (H);
    begin
       if Ptr = null then
          return (others => <>);
       end if;
       return Get_Texture_Stats (Ptr.all);
    end Get_Texture_Stats;

    procedure Connect_Post_Render
      (W : in out Window; CB : Post_Render_Proc) is
    begin
       W.Post_Render.Connect (CB);
    end Connect_Post_Render;

    function Connect_Post_Render
      (W : in out Window; CB : Post_Render_Proc)
       return Post_Render_Signals.Connection_Id is
    begin
       return W.Post_Render.Connect (CB);
    end Connect_Post_Render;

    procedure Disconnect_Post_Render
      (W : in out Window; Id : Post_Render_Signals.Connection_Id) is
    begin
       W.Post_Render.Disconnect (Id);
    end Disconnect_Post_Render;

    procedure Connect_Frame
      (W : in out Window; CB : Frame_Proc) is
    begin
       W.Frame.Connect (CB);
    end Connect_Frame;

    function Connect_Frame
      (W : in out Window; CB : Frame_Proc)
       return Frame_Signals.Connection_Id is
    begin
       return W.Frame.Connect (CB);
    end Connect_Frame;

    procedure Disconnect_Frame
      (W : in out Window; Id : Frame_Signals.Connection_Id) is
    begin
       W.Frame.Disconnect (Id);
    end Disconnect_Frame;

    procedure Connect_Close_Request
      (W : in out Window; CB : Close_Request_Callback) is
    begin
       W.Close_Request.Connect (CB);
    end Connect_Close_Request;

    procedure Connect_Close_Request
      (H  : Window_Handle;
       CB : Close_Request_Callback)
    is
       Ptr : constant Window_Access := Live (H);
    begin
       if Ptr /= null then
          Connect_Close_Request (Ptr.all, CB);
       end if;
    end Connect_Close_Request;

    function Connect_Close_Request
      (W : in out Window; CB : Close_Request_Callback)
       return Close_Request_Signals.Connection_Id is
    begin
       return W.Close_Request.Connect (CB);
    end Connect_Close_Request;

    procedure Disconnect_Close_Request
      (W : in out Window; Id : Close_Request_Signals.Connection_Id) is
    begin
       W.Close_Request.Disconnect (Id);
    end Disconnect_Close_Request;

    function Handle_Close_Request (W : in out Window) return Boolean is
       Guard : Dispatch_Guard;
       pragma Unreferenced (Guard);
       Allow : Boolean := True;
       H : constant Window_Handle := Get_Handle (W);
       procedure Call (CB : Close_Request_Callback) is
       begin
          CB (H, Allow);
       end Call;
       procedure Emit is new Close_Request_Signals.For_Each (Call);
    begin
       Emit (W.Close_Request);
       return Allow;
    end Handle_Close_Request;

    function Get_Frame_Stats (W : Window) return Frame_Stats is
    begin
       return (Frame_No             => W.Stats_Frame_No,
               Render_Us            => W.Stats_Render_Us,
               Update_Us            => W.Stats_Update_Us,
               Layout_Us            => W.Stats_Layout_Us,
               Draw_Us              => W.Stats_Draw_Us,
               Present_Us           => W.Stats_Present_Us,
               Last_DT              => W.Stats_Last_DT,
               Layout_Count         => W.Stats_Layout_Count,
               Style_Resolves       => W.Stats_Style_Resolves,
               Style_Hits           => W.Stats_Style_Hits,
               Style_Memo_Hits      => W.Stats_Style_Memo_Hits,
               Style_Computes       => W.Stats_Style_Computes,
               Layout_Calls         => W.Stats_Layout_Calls,
               Layout_Skips         => W.Stats_Layout_Skips,
               Pref_Calls           => W.Stats_Pref_Calls,
               Pref_Hits            => W.Stats_Pref_Hits,
               Selector_Memo_Hits   => W.Stats_Sel_Memo_Hits,
               Selector_Memo_Misses => W.Stats_Sel_Memo_Misses);
    end Get_Frame_Stats;

    function Get_Frame_Stats (H : Window_Handle) return Frame_Stats is
       Ptr : constant Window_Access := Live (H);
    begin
       if Ptr = null then
          return (others => <>);
       end if;
       return Get_Frame_Stats (Ptr.all);
    end Get_Frame_Stats;

   ---------------------------------------------------------------------------
   --  Destroy detach hook (registered into Adi.Widget at elaboration)
   ---------------------------------------------------------------------------

   procedure On_Widget_Destroy (H : Widget_Handle) is
      Host : constant Window_Handle := Find_Host_Window (H);
   begin
      if not Is_Valid (Host) then
         return;
      end if;

      --  Borrowed for this call only: the widget is detached and its
      --  subtree destroyed after this returns, and nothing here may
      --  outlive that.
      declare
         R : constant Window_Ref := Borrow (Host);
      begin
         Clear_Widget_Refs_In_Subtree (R.Ptr.all, H);

         if R.Ptr.Root = H then
            Set_Root (R.Ptr.all, Null_Handle);
         end if;

         Remove_Overlay (R.Ptr.all, H);
      end;
   end On_Widget_Destroy;

   function Create_Window_Handle
     (Title     : String;
      S         : Window_Extent;
      Maximized : Boolean := False) return Window_Handle
   is
      --  Bootstrapped hidden and unmaximized: the scale and density are
      --  only knowable once a window exists, and SDL_SetWindowSize has no
      --  effect on a maximized window, so maximizing waits until the
      --  restore size has been established. Nothing is shown until the
      --  requested size has actually been applied.
      H : Window_Handle :=
        Create_Window_Sized (Title, (100.0, 100.0), Maximized => False,
                             Hidden => True);

      Wants_Bounds : constant Boolean :=
        S.Width.Unit = Pct or else S.Height.Unit = Pct;

      --  SDL's error is thread-local and cleanup may overwrite it, so it
      --  is read before Destroy. Omitted where the failure is ours rather
      --  than SDL's, since the last error would then be unrelated.
      procedure Fail (Message : String; From_SDL : Boolean := True) is
         Detail : constant String :=
           (if From_SDL
            then ": " & Interfaces.C.Strings.Value (Adi.SDL.SDL_GetError)
            else "");
      begin
         Destroy (H);
         raise Adi.SDL.SDL_Error with Message & Detail;
      end Fail;
      Win : constant Adi.SDL.Video.SDL_Window_Ptr := Get_SDL_Window (H);
   begin
      if Win = null then
         Fail ("window could not be created");
      end if;

      declare
         Raw_Den : constant Pixel_Type :=
           Pixel_Type (Adi.SDL.Video.SDL_GetWindowPixelDensity (Win));
         --  A failed query reads as zero; treating that as a tiny density
         --  would turn a modest extent into tens of thousands of
         --  coordinates, so fall back to parity.
         Density : constant Pixel_Type :=
           (if Raw_Den > 0.0 then Raw_Den else 1.0);
         Scale   : constant Pixel_Type := Effective_Display_Scale (Win);
         Bounds  : aliased SDL_Rect := (0, 0, 0, 0);
         --  Only percentages need the display's bounds, so a failure to
         --  read them is only fatal when one is in play.
         Got_Bounds : constant Boolean :=
           (if Wants_Bounds
            then Boolean (Adi.SDL.Video.SDL_GetDisplayUsableBounds
                            (Adi.SDL.Video.SDL_GetDisplayForWindow (Win),
                             Bounds'Access))
            else True);
         Usable  : constant Size_2D :=
           (Pixel_Type (Bounds.w), Pixel_Type (Bounds.h));
         W_Px, H_Px : aliased int := 0;
      begin
         if Wants_Bounds
           and then (not Got_Bounds
                     or else Usable.Width <= 0.0 or else Usable.Height <= 0.0)
         then
            Fail ("a percentage extent needs the display's usable bounds, "
                  & "which SDL did not report",
                  From_SDL => not Got_Bounds);
         end if;

         declare
            R : constant Resolved_Extent :=
              Resolve_Extent (S, Scale, Density, Usable,
                              Adi.Layout_Util.Get_Px_Maps_To_Dip);
         begin
            if not Boolean (Adi.SDL.Video.SDL_SetWindowSize
                              (Win, int (R.Coords.Width),
                               int (R.Coords.Height)))
            then
               Fail ("window could not be sized to its requested extent");
            end if;
         end;

         --  SetWindowSize is asynchronous, so read back only once the
         --  window manager has acted on it.
         if not Boolean (Adi.SDL.Video.SDL_SyncWindow (Win)) then
            Fail ("window size change was not applied");
         end if;

         --  The size a window ends up with is whatever was granted, so
         --  take it from SDL rather than from the request. Leaving the
         --  bootstrap size in place would be worse than failing.
         if not Boolean (Adi.SDL.Video.SDL_GetWindowSizeInPixels
                           (Win, W_Px'Access, H_Px'Access))
         then
            Fail ("window size could not be read back");
         end if;
         Handle_Resize (H, (Pixel_Type (W_Px), Pixel_Type (H_Px)));

         if not Boolean (Adi.SDL.Video.SDL_ShowWindow (Win)) then
            Fail ("window could not be shown");
         end if;

         if Maximized then
            Maximize (H);
         end if;
      end;
      return H;
   end Create_Window_Handle;


   ---------------------------------------------------------------------------
   --  Handle overloads for the operations the frame loop drives
   ---------------------------------------------------------------------------

   function Get_Renderer (H : Window_Handle) return SDL_Renderer_Ptr is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then null else Get_Renderer (Ptr.all));
   end Get_Renderer;

   procedure Request_Redraw (H : Window_Handle) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Request_Redraw (Ptr.all);
      end if;
   end Request_Redraw;

   --  True for a window that is gone: there is nothing left to veto the
   --  close, and the caller is asking whether it may proceed.
   function Handle_Close_Request (H : Window_Handle) return Boolean is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then True else Handle_Close_Request (Ptr.all));
   end Handle_Close_Request;

   function Actual_Size (H : Window_Handle) return Size_2D is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then (0.0, 0.0) else Actual_Size (Ptr.all));
   end Actual_Size;

   procedure Tick (H : Window_Handle; DT : Duration) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Tick (Ptr.all, DT);
      end if;
   end Tick;

   procedure On_Text_Input (H : Window_Handle; Text : String) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Text_Input (Ptr.all, Text);
      end if;
   end On_Text_Input;

   procedure On_Mouse_Move (H : Window_Handle; X, Y : Pixel_Type) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Mouse_Move (Ptr.all, X, Y);
      end if;
   end On_Mouse_Move;

   procedure On_Mouse_Down
     (H      : Window_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Mouse_Down (Ptr.all, X, Y, Button, Clicks);
      end if;
   end On_Mouse_Down;

   procedure On_Mouse_Up
     (H      : Window_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         On_Mouse_Up (Ptr.all, X, Y, Button);
      end if;
   end On_Mouse_Up;

   ---------------------------------------------------------------------------
   --  Subscription management by handle
   ---------------------------------------------------------------------------

   function Connect_Tick (H : Window_Handle; CB : Tick_Callback)
      return Tick_Signals.Connection_Id
   is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then Tick_Signals.No_Connection
              else Connect_Tick (Ptr.all, CB));
   end Connect_Tick;

   procedure Disconnect_Tick
     (H : Window_Handle; Id : Tick_Signals.Connection_Id)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Disconnect_Tick (Ptr.all, Id);
      end if;
   end Disconnect_Tick;

   function Connect_Key_Down (H : Window_Handle; CB : Key_Down_Callback)
      return Key_Down_Signals.Connection_Id
   is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then Key_Down_Signals.No_Connection
              else Connect_Key_Down (Ptr.all, CB));
   end Connect_Key_Down;

   procedure Disconnect_Key_Down
     (H : Window_Handle; Id : Key_Down_Signals.Connection_Id)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Disconnect_Key_Down (Ptr.all, Id);
      end if;
   end Disconnect_Key_Down;

   procedure Connect_Post_Render (H : Window_Handle; CB : Post_Render_Proc) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Connect_Post_Render (Ptr.all, CB);
      end if;
   end Connect_Post_Render;

   function Connect_Post_Render (H : Window_Handle; CB : Post_Render_Proc)
      return Post_Render_Signals.Connection_Id
   is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then Post_Render_Signals.No_Connection
              else Connect_Post_Render (Ptr.all, CB));
   end Connect_Post_Render;

   procedure Disconnect_Post_Render
     (H : Window_Handle; Id : Post_Render_Signals.Connection_Id)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Disconnect_Post_Render (Ptr.all, Id);
      end if;
   end Disconnect_Post_Render;

   procedure Connect_Frame (H : Window_Handle; CB : Frame_Proc) is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Connect_Frame (Ptr.all, CB);
      end if;
   end Connect_Frame;

   function Connect_Frame (H : Window_Handle; CB : Frame_Proc)
      return Frame_Signals.Connection_Id
   is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then Frame_Signals.No_Connection
              else Connect_Frame (Ptr.all, CB));
   end Connect_Frame;

   procedure Disconnect_Frame
     (H : Window_Handle; Id : Frame_Signals.Connection_Id)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Disconnect_Frame (Ptr.all, Id);
      end if;
   end Disconnect_Frame;

   function Connect_Close_Request
     (H : Window_Handle; CB : Close_Request_Callback)
      return Close_Request_Signals.Connection_Id
   is
      Ptr : constant Window_Access := Live (H);
   begin
      return (if Ptr = null then Close_Request_Signals.No_Connection
              else Connect_Close_Request (Ptr.all, CB));
   end Connect_Close_Request;

   procedure Disconnect_Close_Request
     (H : Window_Handle; Id : Close_Request_Signals.Connection_Id)
   is
      Ptr : constant Window_Access := Live (H);
   begin
      if Ptr /= null then
         Disconnect_Close_Request (Ptr.all, Id);
      end if;
   end Disconnect_Close_Request;


begin
   Adi.Widget.Window_Bridge.Install_Destroy_Notice
     (On_Widget_Destroy'Access);



end Adi.Window;
