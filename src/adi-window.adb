pragma Ada_2022;
with Ada.Containers.Vectors;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Environment_Variables;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Core;
with Adi.Log;
with Adi.SDL; use Adi.SDL;
with Adi.SDL.Video;
with Adi.SDL.Render;
with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.Image;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget_Styles;

package body Adi.Window is
   use type Adi.SDL.Video.SDL_Window_Ptr;
   use type Adi.SDL.Video.SDL_WindowFlags;

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
      New_Focus : Widget_Access);

   function Is_Focus_Candidate (Wgt : Widget_Access) return Boolean;
   function Is_Focus_Candidate
     (Wgt : Widget_Access;
      Effective_Visibility : Visibility_Value) return Boolean;
   function First_Focusable (Root : Widget_Access) return Widget_Access;
   function Last_Focusable (Root : Widget_Access) return Widget_Access;
   function Next_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access;
   function Prev_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access;
   procedure Apply_Window_Min_Size_From_Layout (W : in out Window);
   function Is_Any_Overlay_Dirty (W : Window) return Boolean;
   function Is_Any_Overlay_Layout_Dirty (W : Window) return Boolean;
   function Overlay_Index
     (W       : Window;
      Overlay : Widget_Access) return Natural;
   function Find_Widget_At_With_Flag
     (W    : Window;
      X, Y : Pixel_Type;
      F    : Widget_Flag) return Widget_Access;
   function Find_Scroll_Widget_At
     (W    : Window;
      X, Y : Pixel_Type) return Widget_Access;
   function Is_In_Subtree
     (Root : Widget_Access;
      Node : Widget_Access) return Boolean;
   function Active_Key_Root (W : Window) return Widget_Access;
   procedure Apply_Render_Logical_Presentation (W : in out Window);
   function Refresh_DIP_Scale (W : in out Window) return Boolean;
   procedure Refresh_Viewport_Size (W : in out Window);
   function Normalize_Visibility (V : Visibility_Value) return Visibility_Value;
   function Widget_Participates (Wgt : Adi.Widget.Widget'Class) return Boolean;
   function Main_Visibility_Explicit (Wgt : Adi.Widget.Widget'Class) return Boolean;
   function Resolve_Effective_Visibility
     (Wgt : Adi.Widget.Widget'Class;
      Parent_Visibility : Visibility_Value) return Visibility_Value;
   function Window_Contains_Widget
     (W    : Window;
      Node : Widget_Access) return Boolean;
   procedure Register_Live_Window (W : Window_Access);
   procedure Unregister_Live_Window
     (Win_Handle : Adi.SDL.Video.SDL_Window_Ptr);

   type Internal is record
      win : Adi.SDL.Video.SDL_Window_Ptr;
      ren : Adi.SDL.Render.SDL_Renderer_Ptr;
   end record;

   package Window_Access_Vectors is new Ada.Containers.Vectors
     (Positive, Window_Access);

   Live_Windows : Window_Access_Vectors.Vector;

   procedure Apply_Render_Logical_Presentation (W : in out Window) is
      Success : Adi.SDL.C_bool;
   begin
      if W.Internal = null
        or else W.Internal.ren = null
      then
         return;
      end if;

      Success := Adi.SDL.Render.SDL_SetRenderLogicalPresentation
        (Renderer => W.Internal.ren,
         W        => int (Integer (Float'Ceiling (Float (W.Size.Width)))),
         H        => int (Integer (Float'Ceiling (Float (W.Size.Height)))),
         Mode     => Adi.SDL.Render.SDL_LOGICAL_PRESENTATION_STRETCH);
      SDL_Assert (Success, "SDL_SetRenderLogicalPresentation");
   end Apply_Render_Logical_Presentation;

   function Refresh_DIP_Scale (W : in out Window) return Boolean is
      Raw    : constant Pixel_Type :=
        Pixel_Type (Adi.SDL.Video.SDL_GetWindowDisplayScale (W.Internal.win));
      Scale  : constant Pixel_Type := Pixel_Type'Max (1.0, Raw);
      Before : constant Pixel_Type := Get_Active_DIP_Scale;
   begin
      Set_Active_DIP_Scale (Scale);
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

   function Widget_Participates (Wgt : Adi.Widget.Widget'Class) return Boolean is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (Wgt, Main_Part);
   begin
      return Has_Flag (Wgt, Visible)
        and then Main_Style.Display /= Display_None;
   end Widget_Participates;

   function Main_Visibility_Explicit (Wgt : Adi.Widget.Widget'Class) return Boolean is
      Rules : constant Style_Rules := Get_Part_Style_Rules (Wgt, Main_Part);
   begin
      return Opt_Visibility.Is_Set (Rules.Visibility);
   end Main_Visibility_Explicit;

   function Resolve_Effective_Visibility
     (Wgt : Adi.Widget.Widget'Class;
      Parent_Visibility : Visibility_Value) return Visibility_Value
   is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (Wgt, Main_Part);
   begin
      if Main_Visibility_Explicit (Wgt) then
         return Normalize_Visibility (Main_Style.Visibility);
      end if;
      return Parent_Visibility;
   end Resolve_Effective_Visibility;

   function Is_Focus_Candidate
     (Wgt : Widget_Access;
      Effective_Visibility : Visibility_Value) return Boolean
   is
   begin
      return Wgt /= null
        and then Effective_Visibility = Visibility_Visible
        and then Widget_Participates (Wgt.all)
        and then Has_Flag (Wgt.all, Focusable)
        and then not Is_Disabled (Wgt.all);
   end Is_Focus_Candidate;

   function Is_Focus_Candidate (Wgt : Widget_Access) return Boolean is
      function Effective_Visibility_For (Node : Widget_Access) return Visibility_Value is
         Parent : access Adi.Widget.Widget'Class;
      begin
         if Node = null then
            return Visibility_Hidden;
         end if;

         Parent := Get_Parent (Node.all);
         if Parent = null then
            return Resolve_Effective_Visibility (Node.all, Visibility_Visible);
         end if;

         return Resolve_Effective_Visibility
           (Node.all, Effective_Visibility_For (Parent.all'Unchecked_Access));
      end Effective_Visibility_For;
   begin
      return Is_Focus_Candidate (Wgt, Effective_Visibility_For (Wgt));
   end Is_Focus_Candidate;

   function First_Focusable (Root : Widget_Access) return Widget_Access is
      function Visit
        (Node : Widget_Access;
         Parent_Visibility : Visibility_Value) return Widget_Access
      is
         Candidate : Widget_Access;
         Node_Visibility : Visibility_Value;
      begin
         if Node = null or else not Widget_Participates (Node.all) then
            return null;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node.all, Parent_Visibility);
         if Is_Focus_Candidate (Node, Node_Visibility) then
            return Node;
         end if;

         for I in 1 .. Child_Count (Node.all) loop
            Candidate := Visit (Get_Child (Node.all, I), Node_Visibility);
            if Candidate /= null then
               return Candidate;
            end if;
         end loop;

         return null;
      end Visit;
   begin
      return Visit (Root, Visibility_Visible);
   end First_Focusable;

   function Last_Focusable (Root : Widget_Access) return Widget_Access is
      function Visit
        (Node : Widget_Access;
         Parent_Visibility : Visibility_Value) return Widget_Access
      is
         Candidate : Widget_Access;
         Node_Visibility : Visibility_Value;
      begin
         if Node = null or else not Widget_Participates (Node.all) then
            return null;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node.all, Parent_Visibility);

         for I in reverse 1 .. Child_Count (Node.all) loop
            Candidate := Visit (Get_Child (Node.all, I), Node_Visibility);
            if Candidate /= null then
               return Candidate;
            end if;
         end loop;

         if Is_Focus_Candidate (Node, Node_Visibility) then
            return Node;
         end if;
         return null;
      end Visit;
   begin
      return Visit (Root, Visibility_Visible);
   end Last_Focusable;

   function Next_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access
   is
      Result       : Widget_Access := null;
      Seen_Current : Boolean := Current = null;

      procedure Visit
        (Node : Widget_Access;
         Parent_Visibility : Visibility_Value)
      is
         Node_Visibility : Visibility_Value;
      begin
         if Node = null or else Result /= null then
            return;
         end if;
         if not Widget_Participates (Node.all) then
            return;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node.all, Parent_Visibility);
         if Seen_Current and then Is_Focus_Candidate (Node, Node_Visibility) then
            Result := Node;
            return;
         end if;

         if Node = Current then
            Seen_Current := True;
         end if;

         for I in 1 .. Child_Count (Node.all) loop
            Visit (Get_Child (Node.all, I), Node_Visibility);
            exit when Result /= null;
         end loop;
      end Visit;
   begin
      Visit (Root, Visibility_Visible);
      return Result;
   end Next_Focusable;

   function Prev_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access
   is
      Result : Widget_Access := null;
      Prev   : Widget_Access := null;

      procedure Visit
        (Node : Widget_Access;
         Parent_Visibility : Visibility_Value)
      is
         Node_Visibility : Visibility_Value;
      begin
         if Node = null or else Result /= null then
            return;
         end if;
         if not Widget_Participates (Node.all) then
            return;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Node.all, Parent_Visibility);
         if Node = Current then
            Result := Prev;
            return;
         end if;

         if Is_Focus_Candidate (Node, Node_Visibility) then
            Prev := Node;
         end if;

         for I in 1 .. Child_Count (Node.all) loop
            Visit (Get_Child (Node.all, I), Node_Visibility);
            exit when Result /= null;
         end loop;
      end Visit;
   begin
      Visit (Root, Visibility_Visible);
      return Result;
   end Prev_Focusable;

   function Is_In_Subtree
     (Root : Widget_Access;
      Node : Widget_Access) return Boolean
   is
   begin
      if Root = null or else Node = null then
         return False;
      end if;

      if Root = Node then
         return True;
      end if;

      for I in 1 .. Child_Count (Root.all) loop
         if Is_In_Subtree (Get_Child (Root.all, I), Node) then
            return True;
         end if;
      end loop;

      return False;
   end Is_In_Subtree;

   function Window_Contains_Widget
     (W    : Window;
      Node : Widget_Access) return Boolean
   is
   begin
      if Node = null then
         return False;
      end if;

      if Is_In_Subtree (W.Root, Node) then
         return True;
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Is_In_Subtree (Overlay, Node) then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Window_Contains_Widget;

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
     (Node : access Adi.Widget.Widget'Class) return Window_Access
   is
      Node_Access : Widget_Access;
   begin
      if Node = null then
         return null;
      end if;

      Node_Access := Node.all'Unchecked_Access;

      for I in reverse 1 .. Natural (Live_Windows.Length) loop
         declare
            Candidate : constant Window_Access := Live_Windows.Element (I);
         begin
            if Candidate /= null
              and then Window_Contains_Widget (Candidate.all, Node_Access)
            then
               return Candidate;
            end if;
         end;
      end loop;

      return null;
   end Find_Host_Window;

   function Active_Key_Root (W : Window) return Widget_Access is
   begin
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Overlay /= null and then Widget_Participates (Overlay.all) then
               return Overlay;
            end if;
         end;
      end loop;

      return W.Root;
   end Active_Key_Root;

   function Overlay_Index
     (W       : Window;
      Overlay : Widget_Access) return Natural
   is
   begin
      if Overlay = null then
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
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Overlay /= null
              and then Widget_Participates (Overlay.all)
              and then Is_Dirty (Overlay.all)
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
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Overlay /= null
              and then Widget_Participates (Overlay.all)
              and then Is_Layout_Dirty (Overlay.all)
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
      if not W.Enforce_Layout_Min_Size
        or else W.Internal = null
        or else W.Internal.win = null
      then
         return;
      end if;

      if W.Root /= null then
         declare
            Pref : constant Size_2D := Get_Preferred_Size (W.Root.all);
            Floor : constant Size_2D := Get_Min_Size (W.Root.all);
            Root_Geom : constant Rectangle := Get_Geometry (W.Root.all);
            Pref_W : constant Float := Float (Pref.Width);
            Floor_W : constant Float := Float (Floor.Width);
            Root_W : constant Float := Float (Root_Geom.Width);
            Width_Is_Geometry_Dependent : constant Boolean :=
              Root_W > 0.0
              and then abs (Pref_W - Root_W) <= 1.0
              and then Floor_W + 1.0 < Pref_W;
            Effective_W : constant Float :=
              (if Width_Is_Geometry_Dependent then Floor_W else Pref_W);
            Wf   : constant Float := Float'Max (1.0, Effective_W);
            Hf   : constant Float := Float'Max (1.0, Float (Pref.Height));
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

   -------------------
   -- Create_Window --
   -------------------
   function Create_Window(Title: String; S : Size_2D) return Window_Access is
      use Interfaces.C.Strings;
      C_Title_Str : chars_ptr := New_String (Title);
      Win_Ptr : aliased Adi.SDL.Video.SDL_Window_Ptr;
      Ren_Ptr : aliased Adi.SDL.Render.SDL_Renderer_Ptr;
      Success : Adi.SDL.C_bool;
   begin
      Success := Adi.SDL.Render.SDL_CreateWindowAndRenderer(
         C_Title_Str,
         int(S.Width),
         int(S.Height),
         Adi.SDL.Video.SDL_WINDOW_RESIZABLE
           or Adi.SDL.Video.SDL_WINDOW_HIGH_PIXEL_DENSITY,
         Win_Ptr,
         Ren_Ptr);
      Free (C_Title_Str);
      SDL_Assert (Success, "SDL_CreateWindowAndRenderer");
      return W : Window_Access := new Window do
        W.Internal := new Internal;
        W.Internal.win := Win_Ptr;
        W.Internal.ren := Ren_Ptr;
        Adi.Render.Create (W.Ctx, Ren_Ptr);
        W.Size := S;
        W.Geometry := (0.0, 0.0, S.Width, S.Height);
        Apply_Render_Logical_Presentation (W.all);
        if Refresh_DIP_Scale (W.all) then
           null;
        end if;
        Refresh_Viewport_Size (W.all);
        Register_Live_Window (W);
      end return;
   end Create_Window;


   ------------
   -- Update --
   ------------

   procedure Update (W : in Out Window) is
   begin
      if W.Focused_Widget /= null
        and then not Is_Focus_Candidate (W.Focused_Widget)
      then
         Set_Focused_Widget (W, null);
      end if;

      if W.Root /= null then
         Adi.Widget.Update (W.Root.all);
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Overlay /= null then
               Adi.Widget.Update (Overlay.all);
            end if;
         end;
      end loop;
   end Update;

    procedure Render_Debug_Stats (W : Window) is
       use Adi.SDL.Render;
       Bar_H  : constant Float := 16.0;
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
       Append ((1 => W.Stats_Layout_Reason));
       Append ("  S:");
       Append_Nat (W.Stats_Style_Hits, 4);
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

       --  Draw background bar
       Dummy := SDL_SetRenderDrawBlendMode
         (W.Internal.ren, SDL_BLENDMODE_BLEND);
       Dummy := SDL_SetRenderDrawColor (W.Internal.ren, 0, 0, 0, 200);
       Dummy := SDL_RenderFillRect (W.Internal.ren, Bar'Access);

       --  Draw text
       Dummy := SDL_SetRenderDrawColor (W.Internal.ren, 180, 255, 180, 255);
       C_Str := Interfaces.C.Strings.New_String (Buf (1 .. Len));
       Dummy := SDL_RenderDebugText
         (W.Internal.ren, 6.0, Win_H - Bar_H + 2.0, C_Str);
       Interfaces.C.Strings.Free (C_Str);

       --  Restore blend mode
       Dummy := SDL_SetRenderDrawBlendMode
         (W.Internal.ren, SDL_BLENDMODE_NONE);
    end Render_Debug_Stats;

    procedure Render (W : in Out Window) is
       use Adi.SDL.Render;
       Root_Dirty          : constant Boolean :=
         (W.Root /= null and then Is_Dirty (W.Root.all));
       Overlay_Dirty       : constant Boolean := Is_Any_Overlay_Dirty (W);
       Root_Layout_Dirty   : constant Boolean :=
         (W.Root /= null and then Is_Layout_Dirty (W.Root.all));
       Overlay_Layout_Dirty : constant Boolean :=
         Is_Any_Overlay_Layout_Dirty (W);
       Needs_Relayout      : constant Boolean :=
         W.Needs_Layout or else Root_Layout_Dirty or else Overlay_Layout_Dirty;
       Render_Start : Time;
       Stage_Start  : Time;
    begin
       --  Keep unit conversion contexts in sync with current window state.
       if W.Internal /= null and then W.Internal.win /= null then
          Set_Active_DIP_Scale
            (Pixel_Type'Max
               (1.0, Pixel_Type (Adi.SDL.Video.SDL_GetWindowDisplayScale (W.Internal.win))));
       end if;
       Refresh_Viewport_Size (W);

       --  Only render if something changed or a redraw was forced
       --  (e.g. window exposed by the compositor).
       if Root_Dirty or else Overlay_Dirty or else W.Force_Redraw
       then
          W.Force_Redraw := False;
          W.Stats_Frame_No := W.Stats_Frame_No + 1;
          W.Stats_Layout_Count := 0;
          Render_Start := Clock;

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
          Stage_Start := Clock;
          Update (W);
          W.Stats_Update_Us := Natural
            (To_Duration (Clock - Stage_Start) * 1_000_000.0);

          --  Relayout only when required by geometry-affecting changes.
          Stage_Start := Clock;
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
             if W.Root /= null then
                Debug_Log ("relayout tick=" & Natural'Image (Debug_Tick_No));
                Layout_Tree (W.Root.all);
                Adi.Widget.Update (W.Root.all);
                --  Re-apply SDL minimum after every layout pass so wrapped
                --  text changes (including unwrap on widen) update the
                --  enforce-min policy immediately.
                --  Width ratchet protection is handled inside
                --  Apply_Window_Min_Size_From_Layout via geometry-dependent
                --  width fallback.
                Apply_Window_Min_Size_From_Layout (W);
                W.Stats_Layout_Count := W.Stats_Layout_Count + 1;
             end if;

             for I in 1 .. Natural (W.Overlays.Length) loop
                declare
                   Overlay : constant Widget_Access := W.Overlays.Element (I);
                begin
                   if Overlay /= null then
                      Layout_Tree (Overlay.all);
                      Adi.Widget.Update (Overlay.all);
                      W.Stats_Layout_Count := W.Stats_Layout_Count + 1;
                   end if;
                end;
             end loop;

             W.Needs_Layout := False;
             W.Resize_Triggered_Layout := False;
          end if;
          W.Stats_Layout_Us := Natural
            (To_Duration (Clock - Stage_Start) * 1_000_000.0);
          W.Stats_Style_Resolves := Adi.Widget.Get_Perf_Style_Resolves;
          W.Stats_Style_Hits     := Adi.Widget.Get_Perf_Style_Hits;
          W.Stats_Layout_Calls   := Adi.Widget.Get_Perf_Layout_Calls;
          W.Stats_Layout_Skips   := Adi.Widget.Get_Perf_Layout_Skips;
          W.Stats_Pref_Calls     := Adi.Widget.Get_Perf_Pref_Calls;
          W.Stats_Pref_Hits      := Adi.Widget.Get_Perf_Pref_Hits;

          --  Draw all widget trees
          Stage_Start := Clock;
          if W.Root /= null then
             Render_Tree (W.Root.all, W.Ctx);
          end if;

          for I in 1 .. Natural (W.Overlays.Length) loop
             declare
                Overlay : constant Widget_Access := W.Overlays.Element (I);
             begin
                if Overlay /= null then
                   Render_Tree (Overlay.all, W.Ctx);
                end if;
             end;
          end loop;
          W.Stats_Draw_Us := Natural
            (To_Duration (Clock - Stage_Start) * 1_000_000.0);

          --  Compute total render time (before present)
          W.Stats_Render_Us := Natural
            (To_Duration (Clock - Render_Start) * 1_000_000.0);

          --  Debug stats overlay
          if W.Debug_Stats_On then
             Render_Debug_Stats (W);
          end if;

          --  Post-render callback (MCP introspection, etc.)
          declare
             Win_Acc : constant not null access Window'Class := W'Unchecked_Access;
             Ren     : constant Adi.SDL.Render.SDL_Renderer_Ptr := W.Internal.ren;
             procedure Call (CB : Post_Render_Proc) is
             begin CB (Win_Acc, Ren); end Call;
             procedure Emit is new Post_Render_Signals.For_Each (Call);
          begin
             Emit (W.Post_Render);
          end;

          --  Present the rendered frame
          Stage_Start := Clock;
          SDL_Assert (SDL_RenderPresent (W.Internal.ren), "SDL_RenderPresent");
          W.Stats_Present_Us := Natural
            (To_Duration (Clock - Stage_Start) * 1_000_000.0);
       end if;

       --  Per-frame callback (runs unconditionally, even when idle)
       declare
          Win_Acc : constant not null access Window'Class := W'Unchecked_Access;
          procedure Call (CB : Frame_Proc) is begin CB (Win_Acc); end Call;
          procedure Emit is new Frame_Signals.For_Each (Call);
       begin
          Emit (W.Frame);
       end;
    end Render;

   procedure Set_Root (W : in Out Window; Root : access Adi.Widget.Widget'Class) is
   begin
      if Root = null then
         W.Root := null;
      else
         W.Root := Root.all'Unchecked_Access;
      end if;
      if Root /= null then
         Set_Geometry (Root.all, W.Geometry);
         W.Needs_Layout := True;  -- Initial layout needed
         W.Resize_Triggered_Layout := False;
      end if;
      Apply_Window_Min_Size_From_Layout (W);
   end Set_Root;


   --------------
   -- Get_Root --
   --------------

   function Get_Root (W : Window) return Widget_Access is
   begin
      return W.Root;
   end Get_Root;

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

   function Get_Enforce_Layout_Min_Size (W : Window) return Boolean is
   begin
      return W.Enforce_Layout_Min_Size;
   end Get_Enforce_Layout_Min_Size;

   procedure Connect_Tick (W : in out Window; CB : Tick_Callback) is
   begin
      W.Tick_Sig.Connect (CB);
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

   procedure Add_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class) is
      OA : Widget_Access := null;
   begin
      if Overlay = null then
         return;
      end if;
      OA := Overlay.all'Unchecked_Access;

      declare
         Existing : constant Natural := Overlay_Index (W, OA);
      begin
         if Existing > 0 then
            W.Overlays.Delete (Existing);
         end if;
      end;

      W.Overlays.Append (OA);
      Mark_Dirty (OA.all);
      if W.Root /= null then
         Mark_Dirty (W.Root.all);
      end if;
      W.Needs_Layout := True;
   end Add_Overlay;

   procedure Remove_Overlay (W : in out Window; Overlay : access Adi.Widget.Widget'Class) is
      OA       : Widget_Access := null;
      Existing : Natural;
   begin
      if Overlay = null then
         return;
      end if;
      OA := Overlay.all'Unchecked_Access;

      Existing := Overlay_Index (W, OA);
      if Existing = 0 then
         return;
      end if;

      --  Clear focus if it was on a widget inside the removed overlay
      if W.Focused_Widget /= null
        and then Is_In_Subtree (OA, W.Focused_Widget)
      then
         Set_Focused_Widget (W, null);
      end if;

      W.Overlays.Delete (Existing);
      if W.Root /= null then
         Mark_Dirty (W.Root.all);
      end if;
      W.Needs_Layout := True;
   end Remove_Overlay;

   procedure Clear_Overlays (W : in out Window) is
   begin
      if W.Overlays.Is_Empty then
         return;
      end if;

      --  Clear focus if it was on a widget inside any overlay
      if W.Focused_Widget /= null then
         for I in 1 .. Natural (W.Overlays.Length) loop
            if Is_In_Subtree (W.Overlays.Element (I), W.Focused_Widget) then
               Set_Focused_Widget (W, null);
               exit;
            end if;
         end loop;
      end if;

      W.Overlays.Clear;
      if W.Root /= null then
         Mark_Dirty (W.Root.all);
      end if;
      W.Needs_Layout := True;
   end Clear_Overlays;

   function Overlay_Count (W : Window) return Natural is
   begin
      return Natural (W.Overlays.Length);
   end Overlay_Count;

   function Get_Overlay (W : Window; Index : Positive) return Widget_Access is
   begin
      return W.Overlays.Element (Index);
   end Get_Overlay;

   function Get_Focus (W : Window) return Widget_Access is
   begin
      return W.Focused_Widget;
   end Get_Focus;

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

   function Get_Renderer (W : in Out Window) return SDL_Renderer_Ptr is
   begin
      return W.Internal.ren;
   end Get_Renderer;

   ---------------------
   -- Point_In_Widget --
   ---------------------

   function Point_In_Widget (Wgt : Widget_Access; X, Y : Pixel_Type) return Boolean is
      G : Rectangle;
   begin
      if Wgt = null then
         return False;
      end if;

      G := Get_Geometry (Wgt.all);
      return X >= G.X and then X <= G.X + G.Width and then
             Y >= G.Y and then Y <= G.Y + G.Height;
   end Point_In_Widget;


   function Find_Widget_At (W : Window; X, Y : Pixel_Type) return Widget_Access is

      function Find_Deepest
        (Parent   : Widget_Access;
         Hit_X    : Pixel_Type;
         Hit_Y    : Pixel_Type;
         Parent_Visibility : Visibility_Value) return Widget_Access
      is
         Child    : Widget_Access;
         Found    : Widget_Access;
         Child_Y  : Pixel_Type;
         Node_Visibility : Visibility_Value;
      begin
         if Parent = null then
            return null;
         end if;

         if not Widget_Participates (Parent.all) then
            return null;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Parent.all, Parent_Visibility);

         --  Check if point is in parent first
         if not Point_In_Widget (Parent, Hit_X, Hit_Y) then
            return null;
         end if;

         --  When parent scrolls, children are rendered shifted by
         --  -Scroll_Offset_Y.  Reverse the shift so the hit coordinate
         --  maps to the child's stored (unshifted) geometry.
         Child_Y := Hit_Y;
         if Get_Scroll_Offset_Y (Parent.all) > 0.0 then
            Child_Y := Hit_Y + Get_Scroll_Offset_Y (Parent.all);
         end if;

         --  Check children in reverse order (last added = on top)
         for I in reverse 1 .. Child_Count (Parent.all) loop
            Child := Get_Child (Parent.all, I);
            Found := Find_Deepest (Child, Hit_X, Child_Y, Node_Visibility);
            if Found /= null then
               return Found;
            end if;
         end loop;

         --  No child contains point, return this widget only when it is
         --  effectively visible. Hidden parents can still expose visible
         --  descendants via explicit visibility overrides.
         if Node_Visibility = Visibility_Visible then
            return Parent;
         end if;
         return null;
      end Find_Deepest;

   begin
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
            Found   : Widget_Access;
         begin
            if Overlay = null then
               null;
            else
               Found := Find_Deepest (Overlay, X, Y, Visibility_Visible);
               if Found /= null then
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
      F    : Widget_Flag) return Widget_Access
   is
      function Find_Deepest_Eligible
        (Parent : Widget_Access;
         Hit_X  : Pixel_Type;
         Hit_Y  : Pixel_Type;
         Parent_Visibility : Visibility_Value) return Widget_Access
      is
         Child   : Widget_Access;
         Found   : Widget_Access;
         Child_Y : Pixel_Type;
         Node_Visibility : Visibility_Value;
      begin
         if Parent = null then
            return null;
         end if;

         if not Widget_Participates (Parent.all) then
            return null;
         end if;

         Node_Visibility :=
           Resolve_Effective_Visibility (Parent.all, Parent_Visibility);

         if not Point_In_Widget (Parent, Hit_X, Hit_Y) then
            return null;
         end if;

         Child_Y := Hit_Y;
         if Get_Scroll_Offset_Y (Parent.all) > 0.0 then
            Child_Y := Hit_Y + Get_Scroll_Offset_Y (Parent.all);
         end if;

         for I in reverse 1 .. Child_Count (Parent.all) loop
            Child := Get_Child (Parent.all, I);
            Found := Find_Deepest_Eligible (Child, Hit_X, Child_Y, Node_Visibility);
            if Found /= null then
               return Found;
            end if;
         end loop;

         if Node_Visibility = Visibility_Visible
           and then Has_Flag (Parent.all, F)
         then
            return Parent;
         end if;

         return null;
      end Find_Deepest_Eligible;
   begin
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
            Found   : Widget_Access;
         begin
            if Overlay = null then
               null;
            else
               Found := Find_Deepest_Eligible
                 (Overlay, X, Y, Visibility_Visible);
               if Found /= null then
                  return Found;
               end if;
            end if;
         end;
      end loop;

      return Find_Deepest_Eligible (W.Root, X, Y, Visibility_Visible);
   end Find_Widget_At_With_Flag;

   function Find_Scroll_Widget_At
     (W    : Window;
      X, Y : Pixel_Type) return Widget_Access
   is
      Node : Widget_Access := Find_Widget_At (W, X, Y);
      Parent : access Adi.Widget.Widget'Class;
   begin
      while Node /= null loop
         declare
            P : constant Part_Kind := Get_Part_At (Node.all, X, Y);
         begin
            if P in Scroll_Part | Knob_Part then
               return Node;
            end if;
         end;

         Parent := Get_Parent (Node.all);
         if Parent = null then
            Node := null;
         else
            Node := Parent.all'Unchecked_Access;
         end if;
      end loop;

      return null;
   end Find_Scroll_Widget_At;

   ------------------------
   -- Set_Focused_Widget --
   ------------------------

   procedure Set_Focused_Widget
     (W         : in out Window;
      New_Focus : Widget_Access)
   is
      Candidate : Widget_Access := New_Focus;
      Ignore    : Adi.SDL.C_bool;
   begin
      if Candidate /= null and then not Is_Focus_Candidate (Candidate) then
         Candidate := null;
      end if;

      if Candidate = W.Focused_Widget then
         return;
      end if;

      if W.Focused_Widget /= null then
         Set_Focused (W.Focused_Widget.all, False);
         On_Focus_Lost (W.Focused_Widget.all);
      end if;

      W.Focused_Widget := Candidate;

      if W.Focused_Widget /= null then
         Ignore := Adi.SDL.Video.SDL_StartTextInput (W.Internal.win);
         Set_Focused (W.Focused_Widget.all, True);
         On_Focus_Gained (W.Focused_Widget.all);
      else
         Ignore := Adi.SDL.Video.SDL_StopTextInput (W.Internal.win);
      end if;
   end Set_Focused_Widget;

   ---------------
   -- Set_Focus --
   ---------------

   procedure Set_Focus
     (W      : in out Window;
      Target : access Adi.Widget.Widget'Class)
   is
   begin
      if Target = null then
         Set_Focused_Widget (W, null);
         return;
      end if;

      declare
         WA : constant Widget_Access := Target.all'Unchecked_Access;
      begin
         if not Window_Contains_Widget (W, WA) then
            return;
         end if;
         Set_Focused_Widget (W, WA);
      end;
   end Set_Focus;

   -------------------
   -- On_Mouse_Move --
   -------------------
procedure On_Mouse_Move (W : in Out Window; X, Y : Pixel_Type) is
      New_Hovered : Widget_Access;
      New_Part    : Part_Kind;
      Max_Ancestor_Depth : constant := 64;
      type Widget_Chain is array (Positive range <>) of Widget_Access;

      procedure Build_Hover_Chain
        (Start : Widget_Access;
         Chain : out Widget_Chain;
         Count : out Natural) is
         Node   : Widget_Access := Start;
         Parent : access Adi.Widget.Widget'Class;
      begin
         Count := 0;
         while Node /= null and then Count < Chain'Length loop
            Count := Count + 1;
            Chain (Count) := Node;
            Parent := Get_Parent (Node.all);
            if Parent = null then
               Node := null;
            else
               Node := Parent.all'Unchecked_Access;
            end if;
         end loop;
      end Build_Hover_Chain;

      function In_Chain
        (Node  : Widget_Access;
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
        (Old_Node : Widget_Access;
         New_Node : Widget_Access) is
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
               Set_Hovered (Old_Chain (I).all, False);
            end if;
         end loop;

         --  Set hover for newly entered nodes.
         for I in 1 .. New_Count loop
            if not In_Chain (New_Chain (I), Old_Chain, Old_Count) then
               Set_Hovered (New_Chain (I).all, True);
            end if;
         end loop;
      end Update_Hover_Ancestors;

      procedure Clear_Hover_For_Part
        (Target : in out Adi.Widget.Widget'Class;
         P      : Part_Kind) is
      begin
         Set_Part_State (Target, P, Adi.Widget_Styles.State_Hovered, False);
         --  Knob sits on top of scroll track; clear both when leaving knob.
         if P = Knob_Part then
            Set_Part_State (Target, Scroll_Part, Adi.Widget_Styles.State_Hovered, False);
         end if;
      end Clear_Hover_For_Part;

      procedure Set_Hover_For_Part
        (Target : in out Adi.Widget.Widget'Class;
         P      : Part_Kind) is
      begin
         Set_Part_State (Target, P, Adi.Widget_Styles.State_Hovered, True);
         --  Hovering knob should also visually highlight the track beneath it.
         if P = Knob_Part then
            Set_Part_State (Target, Scroll_Part, Adi.Widget_Styles.State_Hovered, True);
         end if;
      end Set_Hover_For_Part;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Find widget under cursor
      New_Hovered := Find_Scroll_Widget_At (W, X, Y);
      if New_Hovered = null then
         New_Hovered := Find_Widget_At (W, X, Y);
      end if;

      --  Handle hover state changes
      if New_Hovered /= W.Hovered_Widget then
         --  Update widget hover state across ancestor chains.
         Update_Hover_Ancestors (W.Hovered_Widget, New_Hovered);

         if W.Hovered_Widget /= null then
            Clear_Hover_For_Part (W.Hovered_Widget.all, W.Hovered_Part);
         end if;

         --  Set hover on new widget
         if New_Hovered /= null then
            New_Part := Get_Part_At (New_Hovered.all, X, Y);
            Set_Hover_For_Part (New_Hovered.all, New_Part);
            W.Hovered_Part := New_Part;
         else
            W.Hovered_Part := Main_Part;
         end if;

         W.Hovered_Widget := New_Hovered;
      elsif W.Hovered_Widget /= null then
         New_Part := Get_Part_At (W.Hovered_Widget.all, X, Y);
         if New_Part /= W.Hovered_Part then
            Clear_Hover_For_Part (W.Hovered_Widget.all, W.Hovered_Part);
            Set_Hover_For_Part (W.Hovered_Widget.all, New_Part);
            W.Hovered_Part := New_Part;
         end if;
      end if;

      --  Route drag motion to the pressed widget (for text selection, etc.)
      if W.Mouse_Down and then W.Pressed_Widget /= null
        and then not Is_Disabled (W.Pressed_Widget.all)
      then
         if W.Scroll_Claimed then
            Handle_Scroll_Mouse_Move (W.Pressed_Widget.all, X, Y);
         else
            On_Mouse_Move (W.Pressed_Widget.all, X, Y);
         end if;
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
      Click_Target : Widget_Access;
      Focus_Target : Widget_Access;
      Scroll_Target : Widget_Access;
      Any_Target : Widget_Access;
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
         if Any_Target /= null then
            if Bubble_Context_Menu (Any_Target, X, Y) then
               return;
            end if;
         end if;
         return;
      end if;

      Click_Target := Find_Widget_At_With_Flag (W, X, Y, Clickable);
      Scroll_Target := Find_Scroll_Widget_At (W, X, Y);

      --  Disabled widgets do not receive clicks or focus.
      if Click_Target /= null
        and then Is_Disabled (Click_Target.all)
      then
         Click_Target := null;
      end if;
      if Focus_Target /= null
        and then Is_Disabled (Focus_Target.all)
      then
         Focus_Target := null;
      end if;

      --  Allow dragging scrollbar parts on non-clickable containers
      --  (e.g. a scrollable root panel).
      if Click_Target = null and then Scroll_Target /= null then
         declare
            P : constant Part_Kind := Get_Part_At (Scroll_Target.all, X, Y);
         begin
            if P in Scroll_Part | Knob_Part then
               Click_Target := Scroll_Target;
            end if;
         end;
      end if;

      if Click_Target /= null then
         W.Pressed_Part := Get_Part_At (Click_Target.all, X, Y);
         Set_Pressed (Click_Target.all, True);
         Set_Part_State (Click_Target.all,
                         W.Pressed_Part,
                         Adi.Widget_Styles.State_Pressed,
                         True);
         W.Pressed_Widget := Click_Target;
         if W.Pressed_Part in Scroll_Part | Knob_Part then
            W.Scroll_Claimed :=
              Handle_Scroll_Mouse_Down (Click_Target.all, X, Y, Button);
            if not W.Scroll_Claimed then
               On_Mouse_Down (Click_Target.all, X, Y, Button, Clicks);
            end if;
         else
            On_Mouse_Down (Click_Target.all, X, Y, Button, Clicks);
         end if;
      else
         W.Pressed_Widget := null;
         W.Pressed_Part := Main_Part;
      end if;

      Set_Focused_Widget (W, Focus_Target);
   end On_Mouse_Down;

   -----------------
   -- On_Mouse_Up --
   -----------------
   procedure On_Mouse_Up
      (W : in out Window; X, Y : Pixel_Type; Button : Adi.Core.Mouse_Button)
    is
   begin
      W.Mouse_Down := False;
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Release pressed widget and dispatch click if applicable
      if W.Pressed_Widget /= null then
         if W.Scroll_Claimed then
            Handle_Scroll_Mouse_Up (W.Pressed_Widget.all, Button);
         else
            On_Mouse_Up (W.Pressed_Widget.all, X, Y, Button);
         end if;
         if Point_In_Widget (W.Pressed_Widget, X, Y)
            and then Has_Flag (W.Pressed_Widget.all, Clickable)
            and then Button = Left_Button
            and then not Is_Disabled (W.Pressed_Widget.all)
         then
            On_Click (W.Pressed_Widget.all);
         end if;
         Set_Part_State (W.Pressed_Widget.all,
                         W.Pressed_Part,
                         Adi.Widget_Styles.State_Pressed,
                         False);
         Set_Pressed (W.Pressed_Widget.all, False);
         W.Pressed_Widget := null;
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
      Target     : Widget_Access;
      In_Overlay : Boolean := False;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Check if cursor is over any overlay subtree, using the same
      --  participation/visibility eligibility as normal hit-testing.
      for I in reverse 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Overlay /= null
              and then Widget_Participates (Overlay.all)
              and then Resolve_Effective_Visibility
                (Overlay.all, Visibility_Visible) = Visibility_Visible
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
         if Target /= null then
            declare
               In_Overlay_Tree : Boolean := False;
            begin
               for I in 1 .. Natural (W.Overlays.Length) loop
                  if Is_In_Subtree
                    (W.Overlays.Element (I), Target)
                  then
                     In_Overlay_Tree := True;
                     exit;
                  end if;
               end loop;
               if not In_Overlay_Tree then
                  Target := null;
               end if;
            end;
         end if;
         --  No focus fallback when cursor is over an overlay.
      else
         --  No overlay under cursor: allow focus fallback to focused
         --  scrollable widget.
         if Target = null then
            if W.Focused_Widget /= null
              and then Has_Flag (W.Focused_Widget.all, Scrollable)
            then
               Target := W.Focused_Widget;
            end if;
         end if;
      end if;

      if Target /= null and then not Is_Disabled (Target.all) then
         On_Mouse_Wheel (Target.all, Delta_X, Delta_Y);
      end if;
   end On_Mouse_Wheel;

   -----------------
   -- On_Key_Down --
   -----------------

   procedure On_Key_Down
     (W        : in out Window;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
      use type Adi.SDL.Events.SDL_Keymod;
      use type Adi.SDL.Events.SDL_Scancode;
      Shift_Mod : constant Boolean :=
        (Key_Mod and Adi.SDL.Events.SDL_KMOD_SHIFT) /= 0;
      Next_Focus : Widget_Access := null;
      Key_Root   : constant Widget_Access := Active_Key_Root (W);
   begin
      if Scancode = Adi.SDL.Events.SDL_SCANCODE_TAB then
         if Shift_Mod then
            Next_Focus := Prev_Focusable (Key_Root, W.Focused_Widget);
            if Next_Focus = null then
               Next_Focus := Last_Focusable (Key_Root);
            end if;
         else
            Next_Focus := Next_Focusable (Key_Root, W.Focused_Widget);
            if Next_Focus = null then
               Next_Focus := First_Focusable (Key_Root);
            end if;
         end if;

         if Next_Focus /= null then
            Set_Focused_Widget (W, Next_Focus);
         end if;
         return;
      end if;

      if W.Focused_Widget /= null
        and then Is_In_Subtree (Key_Root, W.Focused_Widget)
        and then not Is_Disabled (W.Focused_Widget.all)
      then
         On_Key_Down (W.Focused_Widget.all, Scancode, Key_Mod, Repeat);

         --  For overlays (modal dialogs), also let the overlay root handle
         --  Escape so that dismiss-on-escape works regardless of which
         --  child widget is focused.
         if Scancode = Adi.SDL.Events.SDL_SCANCODE_ESCAPE
           and then Key_Root /= W.Root
           and then Widget_Access (W.Focused_Widget) /= Key_Root
         then
            On_Key_Down (Key_Root.all, Scancode, Key_Mod, Repeat);
         end if;
      elsif Key_Root /= null then
         On_Key_Down (Key_Root.all, Scancode, Key_Mod, Repeat);
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
   begin
      if W.Focused_Widget /= null
        and then Is_In_Subtree (Active_Key_Root (W), W.Focused_Widget)
        and then not Is_Disabled (W.Focused_Widget.all)
      then
         On_Key_Up (W.Focused_Widget.all, Scancode, Key_Mod, Repeat);
      elsif Active_Key_Root (W) /= null then
         On_Key_Up (Active_Key_Root (W).all, Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Up;

   -------------------
   -- On_Text_Input --
   -------------------

   procedure On_Text_Input (W : in out Window; Text : String) is
   begin
      if W.Focused_Widget /= null
        and then Is_In_Subtree (Active_Key_Root (W), W.Focused_Widget)
        and then not Is_Disabled (W.Focused_Widget.all)
      then
         On_Text_Input (W.Focused_Widget.all, Text);
      elsif Active_Key_Root (W) /= null then
         On_Text_Input (Active_Key_Root (W).all, Text);
      end if;
   end On_Text_Input;

   ----------
   -- Tick --
   ----------

   procedure Tick (W : in out Window; DT : Duration) is
      Root_Dirty_Before    : constant Boolean :=
        (W.Root /= null and then Is_Dirty (W.Root.all));
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

      if W.Root /= null then
         Tick_Animations (W.Root.all, DT);
      end if;

      for I in 1 .. Natural (W.Overlays.Length) loop
         declare
            Overlay : constant Widget_Access := W.Overlays.Element (I);
         begin
            if Overlay /= null then
               Tick_Animations (Overlay.all, DT);
            end if;
         end;
      end loop;

      Root_Dirty_After := (W.Root /= null and then Is_Dirty (W.Root.all));
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
       use Adi.SDL.Video;
       W_Width, W_Height : aliased int;
    begin
       SDL_Assert (SDL_GetWindowSize (W.Internal.win, W_Width'Access, W_Height'Access), "SDL_GetWindowSize");
       return (Width => Pixel_Type (W_Width), Height => Pixel_Type (W_Height));
    end Actual_Size;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (W : in Out Window) is
   begin
      null;
   end Initialize;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (W : in Out Window) is
      use Adi.SDL.Video;
      use Adi.SDL.Render;
   begin
      if W.Internal /= null then
         Unregister_Live_Window (W.Internal.win);
      end if;
      W.Overlays.Clear;
      Adi.Render.Destroy (W.Ctx);
      if W.Internal /= null then
         if W.Internal.ren /= null then
            --  Evict per-renderer texture caches from all live images
            Adi.Image.Release_All_Textures_For_Renderer (W.Internal.ren);
            SDL_DestroyRenderer (W.Internal.ren);
         end if;
         if W.Internal.win /= null then
            SDL_DestroyWindow (W.Internal.win);
         end if;
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
          if W.Root /= null then
             Set_Geometry (W.Root.all, W.Geometry);
             Mark_Dirty (W.Root.all);
          end if;

          --  Overlays (e.g. dialogs) often recompute their internal panel
          --  geometry during Update/Build_Items, so they must also be dirtied
          --  on size changes, not just scale changes.
          for I in 1 .. Natural (W.Overlays.Length) loop
             declare
                Overlay : constant Widget_Access := W.Overlays.Element (I);
             begin
                if Overlay /= null then
                   Mark_Dirty (Overlay.all);
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
          if W.Root /= null then
             Mark_Dirty (W.Root.all);
          end if;
          for I in 1 .. Natural (W.Overlays.Length) loop
             declare
                Overlay : constant Widget_Access := W.Overlays.Element (I);
             begin
                if Overlay /= null then
                   Mark_Dirty (Overlay.all);
                end if;
             end;
          end loop;
          W.Needs_Layout := True;
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
       Allow : Boolean := True;
       procedure Call (CB : Close_Request_Callback) is
       begin
          CB (W'Unchecked_Access, Allow);
       end Call;
       procedure Emit is new Close_Request_Signals.For_Each (Call);
    begin
       Emit (W.Close_Request);
       return Allow;
    end Handle_Close_Request;

    function Get_Frame_Stats (W : Window) return Frame_Stats is
    begin
       return (Frame_No     => W.Stats_Frame_No,
               Render_Us    => W.Stats_Render_Us,
               Update_Us    => W.Stats_Update_Us,
               Layout_Us    => W.Stats_Layout_Us,
               Draw_Us      => W.Stats_Draw_Us,
               Present_Us   => W.Stats_Present_Us,
               Last_DT      => W.Stats_Last_DT,
               Layout_Count => W.Stats_Layout_Count);
    end Get_Frame_Stats;

end Adi.Window;
