pragma Ada_2022;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Adi.Core;
with Adi.SDL; use Adi.SDL;
with Adi.SDL.Video;
with Adi.SDL.Render;

package body Adi.Window is

   type Internal is record
      win : Adi.SDL.Video.SDL_Window_Ptr;
      ren : Adi.SDL.Render.SDL_Renderer_Ptr;
   end record;

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
          Render_Tree(W.Root.all, W.Internal.ren);

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
   -------------------
   -- On_Mouse_Move --
   -------------------
procedure On_Mouse_Move (W : in Out Window; X, Y : Pixel_Type) is
      use Ada.Text_IO;
      New_Hovered : Widget_Access;
   begin
      W.Mouse_X := X;
      W.Mouse_Y := Y;

      --  Find widget under cursor
      New_Hovered := Find_Widget_At (W, X, Y);

      --  Handle hover state changes
      if New_Hovered /= W.Hovered_Widget then
         --  Remove hover from old widget
         if W.Hovered_Widget /= null then
            Ada.Text_IO.Put_Line ("Unhover widget");
            Set_Hovered (W.Hovered_Widget.all, False);
         end if;

         --  Set hover on new widget
         if New_Hovered /= null then
            Ada.Text_IO.Put_Line ("Hover widget at " & X'Image & "," & Y'Image);
            Set_Hovered (New_Hovered.all, True);
         end if;

         W.Hovered_Widget := New_Hovered;
      end if;
   end On_Mouse_Move;

   -------------------
   -- On_Mouse_Down --
   -------------------

    procedure On_Mouse_Down (W : in out Window; X, Y : Pixel_Type; Button : Mouse_Button) is
      pragma Unreferenced (Button);
      Target : Widget_Access;
   begin
      W.Mouse_Down := True;

      --  Find widget under cursor
      Target := Find_Widget_At (W, X, Y);

      if Target /= null then
         Set_Pressed (Target.all, True);
         W.Pressed_Widget := Target;
      end if;
   end On_Mouse_Down;

   -----------------
   -- On_Mouse_Up --
   -----------------
    procedure On_Mouse_Up (W : in out Window; X, Y : Pixel_Type; Button : Mouse_Button) is
      pragma Unreferenced (X, Y, Button);
   begin
      W.Mouse_Down := False;

      --  Release pressed widget
      if W.Pressed_Widget /= null then
         Set_Pressed (W.Pressed_Widget.all, False);
         W.Pressed_Widget := null;
      end if;
   end On_Mouse_Up;

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
