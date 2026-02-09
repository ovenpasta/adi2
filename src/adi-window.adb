pragma Ada_2022;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Core;
with Adi.SDL; use Adi.SDL;
with Adi.SDL.Video;
with Adi.SDL.Render;
with Adi.Widget_Styles;

package body Adi.Window is

   procedure Set_Focused_Widget
     (W         : in out Window;
      New_Focus : Widget_Access);

   function Is_Focus_Candidate (Wgt : Widget_Access) return Boolean;
   function First_Focusable (Root : Widget_Access) return Widget_Access;
   function Last_Focusable (Root : Widget_Access) return Widget_Access;
   function Next_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access;
   function Prev_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access;
   function Find_Widget_At_With_Flag
     (W    : Window;
      X, Y : Pixel_Type;
      F    : Widget_Flag) return Widget_Access;

   type Internal is record
      win : Adi.SDL.Video.SDL_Window_Ptr;
      ren : Adi.SDL.Render.SDL_Renderer_Ptr;
   end record;

   function Is_Focus_Candidate (Wgt : Widget_Access) return Boolean is
   begin
      return Wgt /= null
        and then Has_Flag (Wgt.all, Focusable)
        and then Has_Flag (Wgt.all, Visible);
   end Is_Focus_Candidate;

   function First_Focusable (Root : Widget_Access) return Widget_Access is
      Candidate : Widget_Access;
   begin
      if Root = null then
         return null;
      end if;

      if not Has_Flag (Root.all, Visible) then
         return null;
      end if;

      if Is_Focus_Candidate (Root) then
         return Root;
      end if;

      for I in 1 .. Child_Count (Root.all) loop
         Candidate := First_Focusable (Get_Child (Root.all, I));
         if Candidate /= null then
            return Candidate;
         end if;
      end loop;

      return null;
   end First_Focusable;

   function Last_Focusable (Root : Widget_Access) return Widget_Access is
      Candidate : Widget_Access;
   begin
      if Root = null then
         return null;
      end if;

      if not Has_Flag (Root.all, Visible) then
         return null;
      end if;

      for I in reverse 1 .. Child_Count (Root.all) loop
         Candidate := Last_Focusable (Get_Child (Root.all, I));
         if Candidate /= null then
            return Candidate;
         end if;
      end loop;

      if Is_Focus_Candidate (Root) then
         return Root;
      end if;
      return null;
   end Last_Focusable;

   function Next_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access
   is
      Result       : Widget_Access := null;
      Seen_Current : Boolean := Current = null;

      procedure Visit (Node : Widget_Access) is
      begin
         if Node = null or else Result /= null then
            return;
         end if;

         if not Has_Flag (Node.all, Visible) then
            return;
         end if;

         if Seen_Current and then Is_Focus_Candidate (Node) then
            Result := Node;
            return;
         end if;

         if Node = Current then
            Seen_Current := True;
         end if;

         for I in 1 .. Child_Count (Node.all) loop
            Visit (Get_Child (Node.all, I));
            exit when Result /= null;
         end loop;
      end Visit;
   begin
      Visit (Root);
      return Result;
   end Next_Focusable;

   function Prev_Focusable
     (Root    : Widget_Access;
      Current : Widget_Access) return Widget_Access
   is
      Result : Widget_Access := null;
      Prev   : Widget_Access := null;

      procedure Visit (Node : Widget_Access) is
      begin
         if Node = null or else Result /= null then
            return;
         end if;

         if not Has_Flag (Node.all, Visible) then
            return;
         end if;

         if Node = Current then
            Result := Prev;
            return;
         end if;

         if Is_Focus_Candidate (Node) then
            Prev := Node;
         end if;

         for I in 1 .. Child_Count (Node.all) loop
            Visit (Get_Child (Node.all, I));
            exit when Result /= null;
         end loop;
      end Visit;
   begin
      Visit (Root);
      return Result;
   end Prev_Focusable;

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
         Adi.SDL.Video.SDL_WINDOW_RESIZABLE,
         Win_Ptr,
         Ren_Ptr);
      SDL_Assert (Success, "SDL_CreateWindowAndRenderer");
      return W : Window_Access := new Window do
        W.Internal := new Internal;
        W.Internal.win := Win_Ptr;
        W.Internal.ren := Ren_Ptr;
        Adi.Render.Create (W.Ctx, Ren_Ptr);
        W.Size := S;
        W.Geometry := (0.0, 0.0, S.Width, S.Height);
      end return;
   end Create_Window;


   --------------
   -- On_Event --
   --------------

   procedure On_Event (W : in Out Window; E : Event.Event) is
   begin
      --  Generic event handler (can be extended)
      null;
   end On_Event;

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
   end Update;

    procedure Render (W : in Out Window) is
       use Adi.SDL.Render;
       use Ada.Text_IO;
    begin
       --  Only render if something changed
       if W.Root /= null and then Is_Dirty(W.Root.all) then
          Put_Line ("*** RENDERING (root is dirty) ***");

          --  Clear the screen
          SDL_Assert (SDL_SetRenderDrawColor (W.Internal.ren, 255, 255, 255, 255), "SDL_SetRenderDrawColor");
          SDL_Assert (SDL_RenderClear (W.Internal.ren), "SDL_RenderClear");

          --  Phase 1: Build items so content measurement works
          --  (on first render, items don't exist yet, so Measure_Content
          --  returns 0 for all widgets, causing containers with auto height
          --  to get 0 height from the flex algorithm)
          Update(W.Root.all);

          --  Phase 2: Layout with correct content sizes, then rebuild items
          Mark_Dirty(W.Root.all);
          Layout_Tree(W.Root.all);
          Update(W.Root.all);
          Render_Tree(W.Root.all, W.Ctx);

          --  Present the rendered frame
          SDL_Assert (SDL_RenderPresent (W.Internal.ren), "SDL_RenderPresent");
       end if;
    end Render;

    procedure Set_Root (W : in Out Window; Root : Widget_Access) is
    begin
       W.Root := Root;
       if Root /= null then
          Set_Geometry (Root.all, W.Geometry);
          W.Needs_Layout := True;  -- Initial layout needed
       end if;
    end Set_Root;


   --------------
   -- Get_Root --
   --------------

   function Get_Root (W : Window) return Widget_Access is
   begin
      return W.Root;
   end Get_Root;

   ------------------
   -- Get_Renderer --
   ------------------

   function Get_Renderer (W : in Out Window) return SDL_Renderer_Ptr is
   begin
      return W.Internal.ren;
   end Get_Renderer;

   ------------------
   -- Load_Image --
   ------------------

   function Load_Image
      (W    : in out Window;
       Path : String) return Image_Access
   is
      Renderer : SDL_Renderer_Ptr;
   begin
      Renderer := Get_Renderer (W);
      if Renderer = null then
         Ada.Text_IO.Put_Line ("ERROR: Cannot load image, window has no renderer");
         return null;
      end if;

      return Adi.Image.Load_From_File (Renderer, Path);
   end Load_Image;

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

      function Find_Deepest (Parent : Widget_Access) return Widget_Access is
         Child  : Widget_Access;
         Found  : Widget_Access;
      begin
         if Parent = null then
            return null;
         end if;

         --  Skip invisible widgets (matches Render_Tree behavior)
         if not Has_Flag (Parent.all, Visible) then
            return null;
         end if;

         --  Check if point is in parent first
         if not Point_In_Widget (Parent, X, Y) then
            return null;
         end if;

         --  Check children in reverse order (last added = on top)
         for I in reverse 1 .. Child_Count (Parent.all) loop
            Child := Get_Child (Parent.all, I);
            Found := Find_Deepest (Child);
            if Found /= null then
               return Found;
            end if;
         end loop;

         --  No child contains point, return this widget
         return Parent;
      end Find_Deepest;

   begin
      return Find_Deepest (W.Root);
   end Find_Widget_At;

   function Find_Widget_At_With_Flag
     (W    : Window;
      X, Y : Pixel_Type;
      F    : Widget_Flag) return Widget_Access
   is
      function Find_Deepest_Eligible (Parent : Widget_Access) return Widget_Access is
         Child : Widget_Access;
         Found : Widget_Access;
      begin
         if Parent = null then
            return null;
         end if;

         if not Has_Flag (Parent.all, Visible) then
            return null;
         end if;

         if not Point_In_Widget (Parent, X, Y) then
            return null;
         end if;

         for I in reverse 1 .. Child_Count (Parent.all) loop
            Child := Get_Child (Parent.all, I);
            Found := Find_Deepest_Eligible (Child);
            if Found /= null then
               return Found;
            end if;
         end loop;

         if Has_Flag (Parent.all, F) then
            return Parent;
         end if;

         return null;
      end Find_Deepest_Eligible;
   begin
      return Find_Deepest_Eligible (W.Root);
   end Find_Widget_At_With_Flag;

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

   -------------------
   -- On_Mouse_Move --
   -------------------
procedure On_Mouse_Move (W : in Out Window; X, Y : Pixel_Type) is
      New_Hovered : Widget_Access;
      New_Part    : Part_Kind;
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
      New_Hovered := Find_Widget_At (W, X, Y);

      --  Handle hover state changes
      if New_Hovered /= W.Hovered_Widget then
         --  Remove hover from old widget
         if W.Hovered_Widget /= null then
            Set_Hovered (W.Hovered_Widget.all, False);
            Clear_Hover_For_Part (W.Hovered_Widget.all, W.Hovered_Part);
         end if;

         --  Set hover on new widget
         if New_Hovered /= null then
            New_Part := Get_Part_At (New_Hovered.all, X, Y);
            Set_Hovered (New_Hovered.all, True);
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
      if W.Mouse_Down and then W.Pressed_Widget /= null then
         On_Mouse_Move (W.Pressed_Widget.all, X, Y);
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
   begin
      W.Mouse_Down := True;
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Focus and click routing should target interactive widgets,
      --  not passive leaf children such as labels inside list rows.
      Focus_Target := Find_Widget_At_With_Flag (W, X, Y, Focusable);
      Click_Target := Find_Widget_At_With_Flag (W, X, Y, Clickable);
      Set_Focused_Widget (W, Focus_Target);

      if Click_Target /= null then
         W.Pressed_Part := Get_Part_At (Click_Target.all, X, Y);
         Set_Pressed (Click_Target.all, True);
         Set_Part_State (Click_Target.all,
                         W.Pressed_Part,
                         Adi.Widget_Styles.State_Pressed,
                         True);
         W.Pressed_Widget := Click_Target;
         On_Mouse_Down (Click_Target.all, X, Y, Button, Clicks);
      else
         W.Pressed_Widget := null;
         W.Pressed_Part := Main_Part;
      end if;
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
         On_Mouse_Up (W.Pressed_Widget.all, X, Y, Button);
         if Point_In_Widget (W.Pressed_Widget, X, Y)
            and then Has_Flag (W.Pressed_Widget.all, Clickable)
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
      Target : Widget_Access;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      Target := Find_Widget_At_With_Flag (W, X, Y, Scrollable);
      if Target = null then
         if W.Focused_Widget /= null
           and then Has_Flag (W.Focused_Widget.all, Scrollable)
         then
            Target := W.Focused_Widget;
         end if;
      end if;

      if Target /= null then
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
   begin
      if Scancode = Adi.SDL.Events.SDL_SCANCODE_TAB then
         if Shift_Mod then
            Next_Focus := Prev_Focusable (W.Root, W.Focused_Widget);
            if Next_Focus = null then
               Next_Focus := Last_Focusable (W.Root);
            end if;
         else
            Next_Focus := Next_Focusable (W.Root, W.Focused_Widget);
            if Next_Focus = null then
               Next_Focus := First_Focusable (W.Root);
            end if;
         end if;

         if Next_Focus /= null then
            Set_Focused_Widget (W, Next_Focus);
         end if;
         return;
      end if;

      if W.Focused_Widget /= null then
         On_Key_Down (W.Focused_Widget.all, Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Down;

   -------------------
   -- On_Text_Input --
   -------------------

   procedure On_Text_Input (W : in out Window; Text : String) is
   begin
      if W.Focused_Widget /= null then
         On_Text_Input (W.Focused_Widget.all, Text);
      end if;
   end On_Text_Input;

   ----------
   -- Tick --
   ----------

   procedure Tick (W : in out Window; DT : Duration) is
   begin
      if W.Root /= null then
         Tick_Animations (W.Root.all, DT);
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
      Adi.Render.Destroy (W.Ctx);
      if W.Internal /= null then
         if W.Internal.ren /= null then
            SDL_DestroyRenderer (W.Internal.ren);
         end if;
         if W.Internal.win /= null then
            SDL_DestroyWindow (W.Internal.win);
         end if;
      end if;
   end Finalize;

    procedure Handle_Resize (W : in out Window; New_Size : Size_2D) is
    begin
       Ada.Text_IO.Put_Line
	 ("Handle_Resize called: "
	  & New_Size.Width'Image
	  & "x"
	  & New_Size.Height'Image);
       Ada.Text_IO.Put_Line
	 ("  Old size: " & W.Size.Width'Image & "x" & W.Size.Height'Image);
       if W.Size.Width = New_Size.Width and W.Size.Height = New_Size.Height then
	  Ada.Text_IO.Put_Line ("  Skipping - same size");
	  return;  -- No change

       end if;
       Ada.Text_IO.Put_Line ("  Processing resize...");

       W.Size := New_Size;
       W.Geometry := (0.0, 0.0, New_Size.Width, New_Size.Height);

       --  Re-layout root widget if exists
       if W.Root /= null then
	  Set_Geometry (W.Root.all, W.Geometry);
	  Mark_Dirty (W.Root.all);
       end if;
       W.Needs_Layout := True;  -- Flag for layout recalculation
       Render(W);
    end Handle_Resize;



end Adi.Window;
