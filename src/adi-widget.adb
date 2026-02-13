
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Unchecked_Conversion;
with Adi.Animation; use Adi.Animation;
with Adi.Core; use Adi.Core;
with Adi.Font;
with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.Log;
with Adi.SDL; use Adi.SDL;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
with Adi.SDL.TTF; use Adi.SDL.TTF;
with Adi.SDL.TTF.TextEngine; use Adi.SDL.TTF.TextEngine;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with System;

package body Adi.Widget is
   --  Default resolved style for initialization
   Default_Resolved : constant Resolved_Style := Resolve (Empty_Style);
   Wheel_Step_Px       : constant Pixel_Type := 36.0;
   Wheel_Impulse_Px_S  : constant Pixel_Type := 820.0;
   Max_Scroll_Speed    : constant Pixel_Type := 2200.0;
   Velocity_Epsilon    : constant Pixel_Type := 10.0;
   Momentum_Friction   : constant Float := 7.0;
   Launch_Threshold    : constant Pixel_Type := 620.0;
   Drag_Velocity_Scale : constant Pixel_Type := 55.0;
   Scroll_Inertia_Enabled : Boolean := True;
   Debug_Layout_Overlay_Enabled : Boolean := False;

   type Scrollbar_Metrics is record
      Width       : Pixel_Type := 10.0;
      Before_Gap  : Pixel_Type := 6.0;
      Inset_Top   : Pixel_Type := 2.0;
      Inset_Right : Pixel_Type := 2.0;
      Inset_Bot   : Pixel_Type := 2.0;
      Knob_Width  : Pixel_Type := 10.0;
      Min_Knob_H  : Pixel_Type := 24.0;
   end record;

   function Point_In_Rect (R : Rectangle; X, Y : Pixel_Type) return Boolean;

   ---------------------------------------------------------------------------
   --  Generate_Shadow_Texture
   ---------------------------------------------------------------------------

   function Generate_Shadow_Texture
      (Renderer : SDL_Renderer_Ptr;
       Key      : Shadow_Key) return SDL_Texture_Ptr
   is
      Blur   : constant Natural := Key.Blur_Px;
      Radius : constant Natural := Key.Corner_Radius;

      --  Texture size: 3-pass box blur extends 3*Blur from shape edge
      Pad : constant Natural := 3 * Blur;
      Tex_Size : constant Natural :=
         Natural'Max (4, 2 * (Pad + Radius) + 4);
      Total_Px : constant Natural := Tex_Size * Tex_Size;
      Pad_F    : constant Float := Float (Pad);
      Rect_Sz  : constant Float := Float (Tex_Size) - 2.0 * Pad_F;
      Half_X   : constant Float := Rect_Sz / 2.0;
      Half_Y   : constant Float := Rect_Sz / 2.0;
      Center_X : constant Float := Float (Tex_Size) / 2.0;
      Center_Y : constant Float := Float (Tex_Size) / 2.0;
      CR       : constant Float := Float'Min (Float (Radius),
                                              Float'Min (Half_X, Half_Y));

      Surface : SDL_Surface_Ptr;
      Texture : SDL_Texture_Ptr;
      Success : Adi.SDL.C_bool;

      --  Pack pixel from RGBA components (RGBA32 = ABGR8888 on little-endian:
      --  bytes in memory are R, G, B, A)
      function Pack_Pixel (R, G, B, A : Uint8) return Uint32 is
      begin
         return Uint32 (R)
            or (Uint32 (G) * 256)
            or (Uint32 (B) * 65536)
            or (Uint32 (A) * 16777216);
      end Pack_Pixel;

      --  Extract alpha byte from packed pixel
      function Unpack_Alpha (P : Uint32) return Uint8 is
      begin
         return Uint8 (P / 16777216);
      end Unpack_Alpha;

      --  Signed distance from point to rounded rect centered at (cx, cy)
      --  with half-extents (hx, hy) and corner radius cr.
      --  Negative inside, positive outside.
      function SDF_Rounded_Rect
         (Px, Py : Float;
          Cx, Cy : Float;
          Hx, Hy : Float;
          CR     : Float) return Float
      is
         Dx : constant Float := Float'Max (0.0, abs (Px - Cx) - Hx + CR);
         Dy : constant Float := Float'Max (0.0, abs (Py - Cy) - Hy + CR);
      begin
         return Sqrt (Dx * Dx + Dy * Dy) - CR;
      end SDF_Rounded_Rect;

   begin
      --  Create surface
      Surface := SDL_CreateSurface
         (int (Tex_Size), int (Tex_Size), SDL_PIXELFORMAT_RGBA32);
      if Surface = null then
         return null;
      end if;

      --  Work with pixel buffer via constrained array overlay
      declare
         Pitch : constant Natural := Natural (Surface.pitch) / 4;

         --  Constrained pixel buffer matching the surface
         subtype Pixel_Index is Natural range 0 .. Pitch * Tex_Size - 1;
         type Pixel_Buffer is array (Pixel_Index) of aliased Uint32
            with Convention => C;
         type Pixel_Buffer_Ptr is access all Pixel_Buffer;

         function To_Pixels is new Ada.Unchecked_Conversion
            (System.Address, Pixel_Buffer_Ptr);

         Pixels : constant Pixel_Buffer_Ptr := To_Pixels (Surface.pixels);

         --  Alpha buffers for blur (heap-allocated)
         type Alpha_Array is array (0 .. Total_Px - 1) of Float;
         type Alpha_Ptr is access Alpha_Array;
         Buf_A : Alpha_Ptr;
         Buf_B : Alpha_Ptr;
      begin
         --  Rasterize: rounded-rect mask centered in texture.
         for Y in 0 .. Tex_Size - 1 loop
            for X in 0 .. Tex_Size - 1 loop
               declare
                  Dist : constant Float := SDF_Rounded_Rect
                     (Float (X) + 0.5, Float (Y) + 0.5,
                      Center_X, Center_Y,
                      Half_X, Half_Y, CR);
                  A : Uint8;
               begin
                  if Dist <= 0.0 then
                     A := 255;
                  else
                     A := 0;
                  end if;
                  Pixels (Y * Pitch + X) :=
                     Pack_Pixel (255, 255, 255, A);
               end;
            end loop;
         end loop;

         --  Apply box blur x3 (approximates Gaussian) on alpha channel only
         if Blur > 0 then
            Buf_A := new Alpha_Array;
            Buf_B := new Alpha_Array;

            --  Extract alpha into Buf_A
            for Y in 0 .. Tex_Size - 1 loop
               for X in 0 .. Tex_Size - 1 loop
                  Buf_A (Y * Tex_Size + X) :=
                     Float (Unpack_Alpha (Pixels (Y * Pitch + X))) / 255.0;
               end loop;
            end loop;

            --  Three passes of box blur
            for Pass in 1 .. 3 loop
               --  Horizontal blur into Buf_B
               for Y in 0 .. Tex_Size - 1 loop
                  for X in 0 .. Tex_Size - 1 loop
                     declare
                        Sum : Float := 0.0;
                        KX  : Integer;
                     begin
                        for K in -Blur .. Blur loop
                           KX := X + K;
                           if KX >= 0 and then KX < Tex_Size then
                              Sum := Sum + Buf_A (Y * Tex_Size + KX);
                           end if;
                        end loop;
                        Buf_B (Y * Tex_Size + X) := Sum / Float (2 * Blur + 1);
                     end;
                  end loop;
               end loop;

               --  Vertical blur into Buf_A
               for Y in 0 .. Tex_Size - 1 loop
                  for X in 0 .. Tex_Size - 1 loop
                     declare
                        Sum : Float := 0.0;
                        KY  : Integer;
                     begin
                        for K in -Blur .. Blur loop
                           KY := Y + K;
                           if KY >= 0 and then KY < Tex_Size then
                              Sum := Sum + Buf_B (KY * Tex_Size + X);
                           end if;
                        end loop;
                        Buf_A (Y * Tex_Size + X) := Sum / Float (2 * Blur + 1);
                     end;
                  end loop;
               end loop;
            end loop;

            --  Write blurred alpha back into pixels
            for Y in 0 .. Tex_Size - 1 loop
               for X in 0 .. Tex_Size - 1 loop
                  declare
                     Alpha_F : constant Float :=
                        Float'Min (1.0, Float'Max (0.0,
                           Buf_A (Y * Tex_Size + X)));
                     A : constant Uint8 := Uint8 (Alpha_F * 255.0);
                  begin
                     Pixels (Y * Pitch + X) :=
                        Pack_Pixel (255, 255, 255, A);
                  end;
               end loop;
            end loop;
         end if;

      end;

      --  Upload to GPU texture
      Texture := SDL_CreateTextureFromSurface (Renderer, Surface);
      SDL_DestroySurface (Surface);

      if Texture = null then
         return null;
      end if;

      --  Enable alpha blending and linear scaling
      Success := SDL_SetTextureBlendMode (Texture, SDL_BLENDMODE_BLEND);
      Success := SDL_SetTextureScaleMode (Texture, SDL_SCALEMODE_LINEAR);

      return Texture;
   end Generate_Shadow_Texture;

   ---------------------------------------------------------------------------
   --  Render_Box_Shadow
   ---------------------------------------------------------------------------

   procedure Render_Box_Shadow
      (Ctx   : in out Render_Context;
       Geom  : Rectangle;
       Style : Resolved_Style)
   is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Shadow   : Box_Shadow_Value renames Style.Box_Shadow;

      --  Convert shadow parameters to pixels
      Offset_X : constant Float :=
         Float (Length_To_Px (Shadow.Offset_X, Geom.Width));
      Offset_Y : constant Float :=
         Float (Length_To_Px (Shadow.Offset_Y, Geom.Height));
      Blur_Px  : constant Natural :=
         Natural'Max (0, Natural (Length_To_Px (Shadow.Blur_Radius, Geom.Width)));
      Spread_Px : constant Float :=
         Float (Length_To_Px (Shadow.Spread_Radius, Geom.Width));

      --  Get corner radius from style
      Radius_Vals : constant Corner_Pixels :=
         Get_Border_Radius_Px (Style.Border_Radius);
      Max_Rad : constant Natural :=
         Natural (Float'Max
            (Float'Max (Radius_Vals.Top_Left, Radius_Vals.Top_Right),
             Float'Max (Radius_Vals.Bottom_Right, Radius_Vals.Bottom_Left)));
      Max_Geom_Rad : constant Natural :=
         (if Geom.Width > 0.0 and then Geom.Height > 0.0 then
             Natural (Float'Max (0.0,
                Float'Min (Float (Geom.Width), Float (Geom.Height)) / 2.0))
          else
             0);
      Effective_Rad : constant Natural := Natural'Min (Max_Rad, Max_Geom_Rad);

      --  Get shadow color
      SR, SG, SB, SA : Uint8;

      Key     : Shadow_Key;
      Texture : SDL_Texture_Ptr;
      Success : Adi.SDL.C_bool;

      --  9-grid border = full blur extent (3*blur) + corner_radius
      Grid_Border : constant Float := Float (3 * Blur_Px + Effective_Rad);
      Grid_Left   : Float;
      Grid_Right  : Float;
      Grid_Top    : Float;
      Grid_Bottom : Float;

      --  Destination rect: widget rect expanded by spread + blur, offset
      Dst : aliased SDL_FRect;
   begin
      CSS_Color_To_SDL (Shadow.Color, SR, SG, SB, SA);

      if SA = 0 then
         return;  --  Fully transparent shadow
      end if;

      Key := (Blur_Px       => Blur_Px,
              Corner_Radius => Effective_Rad);

      --  Cache lookup or generate
      Texture := Find_Shadow (Ctx, Key);
      if Texture = null then
         Texture := Generate_Shadow_Texture (Renderer, Key);
         if Texture = null then
            return;
         end if;
         Store_Shadow (Ctx, Key, Texture);
      end if;

      --  Compute destination rect
      declare
         Expand_Amt : constant Float := Spread_Px + Float (3 * Blur_Px);
      begin
         Dst.x := Float (Geom.X) - Expand_Amt + Offset_X;
         Dst.y := Float (Geom.Y) - Expand_Amt + Offset_Y;
         Dst.w := Float (Geom.Width) + 2.0 * Expand_Amt;
         Dst.h := Float (Geom.Height) + 2.0 * Expand_Amt;
      end;

      if Dst.w <= 0.0 or else Dst.h <= 0.0 then
         return;
      end if;

      --  Clamp 9-grid edges so they never overlap on very small widgets.
      --  Without this, corners can cross and alpha blends twice, causing
      --  dark seams/sharp artifacts.
      Grid_Left := Float'Min (Grid_Border, Dst.w / 2.0);
      Grid_Right := Grid_Left;
      Grid_Top := Float'Min (Grid_Border, Dst.h / 2.0);
      Grid_Bottom := Grid_Top;

      --  Texture stores only alpha; tint and alpha are applied at draw time.
      Success := SDL_SetTextureColorMod (Texture, SR, SG, SB);
      Success := SDL_SetTextureAlphaMod (Texture, SA);

      --  Render using 9-grid stretching
      Success := SDL_RenderTexture9Grid
         (Renderer      => Renderer,
          Texture       => Texture,
          Srcrect       => null,
          Left_Width    => Grid_Left,
          Right_Width   => Grid_Right,
          Top_Height    => Grid_Top,
          Bottom_Height => Grid_Bottom,
          Scale         => 1.0,
          Dstrect       => Dst'Access);
   end Render_Box_Shadow;

   ---------------------------------------------------------------------------
   --  Widget State Management
   ---------------------------------------------------------------------------

   function Effective_Part_Style
     (W : Widget'Class;
      P : Part_Kind) return Widget_Style
   is
   begin
      if W.Part_Styles (P).Style = Empty_Widget_Style
        and then P /= Any_Part
        and then W.Part_Styles (Any_Part).Style /= Empty_Widget_Style
      then
         return W.Part_Styles (Any_Part).Style;
      end if;
      return W.Part_Styles (P).Style;
   end Effective_Part_Style;

   function Widget_State_Affects_Resolved_Styles
     (W          : Widget'Class;
      Old_States : Widget_States) return Boolean
   is
      WS : Widget_Style;
   begin
      for P in Part_Kind loop
         if W.Part_Styles (P).Enabled then
            WS := Effective_Part_Style (W, P);
            if WS /= Empty_Widget_Style then
               declare
                  Old_Resolved : constant Resolved_Style :=
                    Resolve (Compute_Style (WS, Old_States, W.Part_States (P)));
                  New_Resolved : constant Resolved_Style :=
                    Resolve (Compute_Style (WS, W.States, W.Part_States (P)));
               begin
                  if Old_Resolved /= New_Resolved then
                     return True;
                  end if;
               end;
            end if;
         end if;
      end loop;
      return False;
   end Widget_State_Affects_Resolved_Styles;

   function Part_State_Affects_Resolved_Styles
     (W          : Widget'Class;
      Changed    : Part_Kind;
      Old_States : Widget_States) return Boolean
   is
      WS : Widget_Style;
   begin
      for P in Part_Kind loop
         if W.Part_Styles (P).Enabled then
            WS := Effective_Part_Style (W, P);
            if WS /= Empty_Widget_Style then
               declare
                  Old_Part_States : constant Widget_States :=
                    (if P = Changed then Old_States else W.Part_States (P));
                  Old_Resolved : constant Resolved_Style :=
                    Resolve (Compute_Style (WS, W.States, Old_Part_States));
                  New_Resolved : constant Resolved_Style :=
                    Resolve (Compute_Style (WS, W.States, W.Part_States (P)));
               begin
                  if Old_Resolved /= New_Resolved then
                     return True;
                  end if;
               end;
            end if;
         end if;
      end loop;
      return False;
   end Part_State_Affects_Resolved_Styles;

   procedure Set_State (W : in out Widget'Class;
                        S : Widget_State;
                        Active : Boolean) is
      Was_Active : constant Boolean := W.States (S);
      Old_States : Widget_States;
   begin
      if Was_Active /= Active then
         Old_States := W.States;
         W.States (S) := Active;
         On_State_Changed (W, S, Active);
         if Widget_State_Affects_Resolved_Styles (W, Old_States) then
            Mark_Dirty (W);
         end if;
      end if;
   end Set_State;

   function Has_State (W : Widget'Class; S : Widget_State) return Boolean is
   begin
      return W.States (S);
   end Has_State;

   function Get_States (W : Widget'Class) return Widget_States is
   begin
      return W.States;
   end Get_States;

   procedure Set_Part_State (W : in out Widget'Class;
                             P : Part_Kind;
                             S : Widget_State;
                             Active : Boolean) is
      Was_Active : constant Boolean := W.Part_States (P) (S);
      Old_States : Widget_States;
   begin
      if Was_Active /= Active then
         Old_States := W.Part_States (P);
         W.Part_States (P) (S) := Active;
         if Part_State_Affects_Resolved_Styles (W, P, Old_States) then
            Mark_Dirty (W);
         end if;
      end if;
   end Set_Part_State;

   function Get_Part_States (W : Widget'Class; P : Part_Kind) return Widget_States is
   begin
      return W.Part_States (P);
   end Get_Part_States;

   procedure Clear_States (W : in out Widget'Class) is
   begin
      W.States := No_States;
      Mark_Dirty (W);
   end Clear_States;

   procedure Clear_Part_States (W : in out Widget'Class) is
   begin
      W.Part_States := [others => No_States];
      Mark_Dirty (W);
   end Clear_Part_States;

   --  Convenience state setters
   procedure Set_Hovered (W : in out Widget'Class; Value : Boolean := True) is
   begin
      Set_State (W, State_Hovered, Value);
   end Set_Hovered;

   procedure Set_Pressed (W : in out Widget'Class; Value : Boolean := True) is
   begin
      Set_State (W, State_Pressed, Value);
   end Set_Pressed;

   procedure Set_Focused (W : in out Widget'Class; Value : Boolean := True) is
   begin
      Set_State (W, State_Focused, Value);
   end Set_Focused;

   procedure Set_Disabled (W : in out Widget'Class; Value : Boolean := True) is
   begin
      Set_State (W, State_Disabled, Value);
   end Set_Disabled;

   procedure Set_Selected (W : in out Widget'Class; Value : Boolean := True) is
   begin
      Set_State (W, State_Selected, Value);
   end Set_Selected;

   ---------------------------------------------------------------------------
   --  Part Style Management
   ---------------------------------------------------------------------------

   procedure Set_Part_Style (W : in out Widget'Class;
                             P : Part_Kind;
                             S : Widget_Style) is
   begin
      W.Part_Styles (P) := (Style => S, Enabled => True);
      Mark_Dirty (W);
   end Set_Part_Style;

   procedure Set_Part_Styles (W : in out Widget'Class;
                              Styles : Part_Style_Array) is
   begin
      W.Part_Styles := Styles;
      Mark_Dirty (W);
   end Set_Part_Styles;

   function Get_Part_Style (W : Widget'Class;
                            P : Part_Kind) return Widget_Style is
   begin
      return W.Part_Styles (P).Style;
   end Get_Part_Style;

   function Get_Part_Style_Rules (W : Widget'Class;
                                  P : Part_Kind) return Style_Rules is
   begin
      if W.Part_Styles (P).Style = Empty_Widget_Style
        and then P /= Any_Part
        and then W.Part_Styles (Any_Part).Style /= Empty_Widget_Style
      then
         return Compute_Style (W.Part_Styles (Any_Part).Style,
                               W.States,
                               W.Part_States (P));
      end if;

      return Compute_Style (W.Part_Styles (P).Style,
                            W.States,
                            W.Part_States (P));
   end Get_Part_Style_Rules;

   function Get_Resolved_Part_Style (W : Widget'Class;
                                     P : Part_Kind) return Resolved_Style is
   begin
      return Resolve (Get_Part_Style_Rules (W, P));
   end Get_Resolved_Part_Style;

   ---------------------------------------------------------------------------
   --  Item Management
   ---------------------------------------------------------------------------

   procedure Add_Item (W : in out Widget'Class; I : Item) is
      New_Item : Item := I;
   begin
      New_Item.Computed_Style := Get_Resolved_Part_Style (W, I.Part);
      W.Items.Append (New_Item);
      Mark_Dirty (W);
   end Add_Item;

   procedure Clear_Items (W : in out Widget'Class) is
      use Adi.SDL.TTF.TextEngine;
   begin
      for I in 1 .. Natural (W.Items.Length) loop
         declare
            It : Item renames W.Items.Reference (I).Element.all;
         begin
            if It.Cached_TTF_Text /= null then
               TTF_DestroyText (It.Cached_TTF_Text);
               It.Cached_TTF_Text := null;
            end if;
         end;
      end loop;
      W.Items.Clear;
      Mark_Dirty (W);
   end Clear_Items;

   procedure Update_Item (W : in out Widget'Class;
                          Index : Positive;
                          I : Item) is
      New_Item : Item := I;
   begin
      if Index <= Positive (W.Items.Length) then
         New_Item.Computed_Style := Get_Resolved_Part_Style (W, I.Part);
         W.Items.Replace_Element (Index, New_Item);
         Mark_Dirty (W);
      end if;
   end Update_Item;

   function Item_Count (W : Widget'Class) return Natural is
   begin
      return Natural (W.Items.Length);
   end Item_Count;

   function Get_Item (W : Widget'Class; Index : Positive) return Item is
   begin
      return W.Items.Element (Index);
   end Get_Item;

   procedure Apply_Styles_To_Items (W : in out Widget'Class) is
      Parts_Seen : array (Part_Kind) of Boolean := [others => False];
   begin
      --  First pass: for each part encountered, check if target changed
      for I in 1 .. Natural (W.Items.Length) loop
         declare
            Current_Item : Item := W.Items.Element (I);
            P : constant Part_Kind := Current_Item.Part;
         begin
            if not Parts_Seen (P) then
               Parts_Seen (P) := True;
               declare
                  New_Target : constant Resolved_Style :=
                     Get_Resolved_Part_Style (W, P);
               begin
                  if not W.Last_Target_Init (P) then
                     --  First time: no transition, just snap
                     W.Last_Target (P) := New_Target;
                     W.Last_Target_Init (P) := True;
                  elsif New_Target.Transition.Duration > 0.0
                     and then New_Target /= W.Last_Target (P)
                  then
                     --  Target changed and transition configured: start animation.
                     --  From_Style is current interpolated position if a transition
                     --  is already running, otherwise the previous target.
                     declare
                        From : Resolved_Style;
                     begin
                        if W.Transitions (P).Active then
                           Advance (W.Transitions (P), 0.0, From);
                        else
                           From := W.Last_Target (P);
                        end if;
                        W.Transitions (P) := (
                           Active       => True,
                           Elapsed      => 0.0,
                           Duration     => New_Target.Transition.Duration,
                           Easing       => New_Target.Transition.Easing,
                           From_Style   => From,
                           Target_Style => New_Target);
                        W.Has_Any_Animation := True;
                     end;
                  elsif New_Target /= W.Last_Target (P) then
                     --  Changed but no transition: snap and cancel any running transition
                     W.Transitions (P).Active := False;
                  end if;
                  W.Last_Target (P) := New_Target;
               end;
            end if;

            --  Apply the current visual style to this item
            if W.Transitions (P).Active then
               declare
                  Interpolated : Resolved_Style;
               begin
                  Advance (W.Transitions (P), 0.0, Interpolated);
                  Current_Item.Computed_Style := Interpolated;
               end;
            else
               Current_Item.Computed_Style := W.Last_Target (P);
            end if;

            W.Items.Replace_Element (I, Current_Item);
         end;
      end loop;
   end Apply_Styles_To_Items;

   function Get_Items_For_Part (W : Widget'Class;
                                P : Part_Kind) return Items_List.Vector is
      Result : Items_List.Vector;
   begin
      for I of W.Items loop
         if I.Part = P or else P = Any_Part then
            Result.Append (I);
         end if;
      end loop;
      return Result;
   end Get_Items_For_Part;

   function Get_Part_At (W : Widget'Class;
                         X, Y : Pixel_Type) return Part_Kind is
   begin
      if W.Scroll_Show_Bar then
         if Point_In_Rect (W.Scroll_Knob_Geom, X, Y) then
            return Knob_Part;
         elsif Point_In_Rect (W.Scroll_Track_Geom, X, Y) then
            return Scroll_Part;
         end if;
      end if;

      for I in reverse 1 .. Natural (W.Items.Length) loop
         declare
            Current : constant Item := W.Items.Element (I);
            G       : constant Rectangle := Current.Geometry;
         begin
            if X >= G.X and then X <= G.X + G.Width
              and then Y >= G.Y and then Y <= G.Y + G.Height
            then
               return Current.Part;
            end if;
         end;
      end loop;
      return Main_Part;
   end Get_Part_At;

   ---------------------------------------------------------------------------
   --  Hierarchy Management
   ---------------------------------------------------------------------------

   procedure Add_Child (W : in out Widget'Class; C : access Widget'Class) is
      CA : Widget_Access := null;
   begin
      if C /= null then
         --  Capture a stable class-wide pointer without triggering
         --  anonymous-to-named access runtime accessibility checks.
         CA := C.all'Unchecked_Access;
         W.Children.Append (CA);
         C.Parent := W'Unchecked_Access;
         Mark_Dirty (W);
      end if;
   end Add_Child;

   procedure Remove_Child (W : in out Widget'Class; C : access Widget'Class) is
      use Widget_List;
      CA     : Widget_Access := null;
      Cursor : Widget_List.Cursor;
   begin
      if C /= null then
         CA := C.all'Unchecked_Access;
      end if;
      Cursor := W.Children.Find (CA);
      if Cursor /= No_Element then
         C.Parent := null;
         W.Children.Delete (Cursor);
         Mark_Dirty (W);
      end if;
   end Remove_Child;

   procedure Set_Parent (W : in out Widget'Class; P : access Widget'Class) is
   begin
      if W.Parent /= null then
         Remove_Child (W.Parent.all, W'Unchecked_Access);
      end if;

      W.Parent := P;

      if P /= null then
         declare
            WA : constant Widget_Access := W'Unchecked_Access;
         begin
            P.Children.Append (WA);
         end;
      end if;

      Mark_Dirty (W);
   end Set_Parent;

   function Get_Parent (W : Widget'Class) return access Widget'Class is
   begin
      return W.Parent;
   end Get_Parent;

   function Child_Count (W : Widget'Class) return Natural is
   begin
      return Natural (W.Children.Length);
   end Child_Count;

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

   --------------------
   -- Find_Widget_At --
   --------------------
   function Get_Child (W : Widget'Class; Index : Positive) return Widget_Access is
     use Widget_List;
     Cursor : Widget_List.Cursor := W.Children.First;
     Count  : Natural := 0;
  begin
     while Cursor /= No_Element loop
        Count := Count + 1;
        if Count = Index then
           return Element (Cursor);
        end if;
        Next (Cursor);
     end loop;
     return null;
  end Get_Child;
   ---------------------------------------------------------------------------
   --  Geometry and Layout
   ---------------------------------------------------------------------------

   procedure Set_Geometry (W : in out Widget'Class; G : Rectangle) is
   begin
      if W.Geometry /= G then
         W.Geometry := G;
         On_Geometry_Changed (W);
      end if;
   end Set_Geometry;

   function Get_Geometry (W : Widget'Class) return Rectangle is
   begin
      return W.Geometry;
   end Get_Geometry;

   function Clamp (Value, Lo, Hi : Pixel_Type) return Pixel_Type is
   begin
      if Value < Lo then
         return Lo;
      elsif Value > Hi then
         return Hi;
      else
         return Value;
      end if;
   end Clamp;

   function Point_In_Rect (R : Rectangle; X, Y : Pixel_Type) return Boolean is
   begin
      return X >= R.X and then X <= R.X + R.Width
        and then Y >= R.Y and then Y <= R.Y + R.Height;
   end Point_In_Rect;

   function Get_Content_Box (W : Widget'Class) return Rectangle is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      return Content_Box (W.Geometry, Style);
   end Get_Content_Box;

   function Supports_Scrollbar (W : Widget'Class) return Boolean is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      return Style.Overflow in Overflow_Scroll | Overflow_Auto;
   end Supports_Scrollbar;

   function Is_Scroll_Enabled (W : Widget'Class) return Boolean is
   begin
      return Supports_Scrollbar (W) or else Has_Flag (W, Scrollable);
   end Is_Scroll_Enabled;

   procedure Clamp_Scroll_Offset (W : in out Widget'Class) is
      Max_Offset : constant Pixel_Type :=
        Pixel_Type'Max (0.0, W.Scroll_Content_H - W.Scroll_Viewport_H);
   begin
      W.Scroll_Offset_Y := Clamp (W.Scroll_Offset_Y, 0.0, Max_Offset);
   end Clamp_Scroll_Offset;

   function Get_Scroll_Max_Offset_Y (W : Widget'Class) return Pixel_Type is
   begin
      return Pixel_Type'Max (0.0, W.Scroll_Content_H - W.Scroll_Viewport_H);
   end Get_Scroll_Max_Offset_Y;

   procedure Set_Scroll_Offset_Y (W : in out Widget'Class; Offset : Pixel_Type) is
      Old : constant Pixel_Type := W.Scroll_Offset_Y;
   begin
      W.Scroll_Offset_Y := Offset;
      Clamp_Scroll_Offset (W);
      if W.Scroll_Offset_Y /= Old then
         Mark_Dirty (W);
      end if;
   end Set_Scroll_Offset_Y;

   function Get_Scroll_Offset_Y (W : Widget'Class) return Pixel_Type is
   begin
      return W.Scroll_Offset_Y;
   end Get_Scroll_Offset_Y;

   procedure Scroll_By_Y (W : in out Widget'Class; Delta_Y : Pixel_Type) is
   begin
      Set_Scroll_Offset_Y (W, W.Scroll_Offset_Y + Delta_Y);
   end Scroll_By_Y;

   function Get_Scroll_Content_Height (W : Widget'Class) return Pixel_Type is
   begin
      return W.Scroll_Content_H;
   end Get_Scroll_Content_Height;

   function Resolve_Scrollbar_Metrics (W : Widget'Class) return Scrollbar_Metrics is
      Content        : constant Rectangle := Get_Content_Box (W);
      Scroll_Style   : constant Resolved_Style := Get_Resolved_Part_Style (W, Scroll_Part);
      Knob_Style     : constant Resolved_Style := Get_Resolved_Part_Style (W, Knob_Part);
      Scroll_Margin  : constant Edge_Pixels := Get_Margin_Px (Scroll_Style);
      Scroll_Padding : constant Edge_Pixels := Get_Padding_Px (Scroll_Style);
      Result         : Scrollbar_Metrics;
      W_Px           : Pixel_Type;
      Knob_W_Px      : Pixel_Type;
      Min_H_Px       : Pixel_Type;
   begin
      W_Px := Size_To_Px (Scroll_Style.Width, Container_Size => Content.Width);
      if W_Px <= 0.0 then
         W_Px := Size_To_Px (Knob_Style.Width, Container_Size => Content.Width);
      end if;
      if W_Px > 0.0 then
         Result.Width := W_Px;
      end if;

      Result.Before_Gap :=
        Pixel_Type'Max (0.0, Scroll_Margin.Left + Scroll_Padding.Left);
      Result.Inset_Top :=
        Pixel_Type'Max (0.0, Scroll_Margin.Top + Scroll_Padding.Top);
      Result.Inset_Right :=
        Pixel_Type'Max (0.0, Scroll_Margin.Right + Scroll_Padding.Right);
      Result.Inset_Bot :=
        Pixel_Type'Max (0.0, Scroll_Margin.Bottom + Scroll_Padding.Bottom);

      Knob_W_Px := Size_To_Px (Knob_Style.Width, Container_Size => Result.Width);
      if Knob_W_Px > 0.0 then
         Result.Knob_Width := Knob_W_Px;
      else
         Result.Knob_Width := Result.Width;
      end if;

      Min_H_Px := Size_To_Px (Knob_Style.Min_Height, Container_Size => Content.Height);
      if Min_H_Px <= 0.0 then
         Min_H_Px := Size_To_Px (Knob_Style.Height, Container_Size => Content.Height);
      end if;
      if Min_H_Px > 0.0 then
         Result.Min_Knob_H := Min_H_Px;
      end if;

      return Result;
   end Resolve_Scrollbar_Metrics;

   procedure Update_Scrollbar_Geometry (W : in out Widget'Class) is
      Content    : constant Rectangle := Get_Content_Box (W);
      Style      : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Max_Offset : constant Pixel_Type := Get_Scroll_Max_Offset_Y (W);
      Metrics    : constant Scrollbar_Metrics := Resolve_Scrollbar_Metrics (W);
      Ratio      : Float;
      Knob_H     : Pixel_Type;
      Knob_Y     : Pixel_Type;
      Track_H    : Pixel_Type;
      Want_Bar   : Boolean := False;
   begin
      W.Scroll_Track_Geom := (0.0, 0.0, 0.0, 0.0);
      W.Scroll_Knob_Geom := (0.0, 0.0, 0.0, 0.0);
      W.Scroll_Show_Bar := False;

      if not Is_Scroll_Enabled (W) or else Content.Width <= 0.0 or else Content.Height <= 0.0 then
         return;
      end if;

      if Supports_Scrollbar (W) then
         case Style.Overflow is
            when Overflow_Scroll =>
               Want_Bar := True;
            when Overflow_Auto =>
               Want_Bar := Max_Offset > 0.0;
            when others =>
               Want_Bar := False;
         end case;
      else
         Want_Bar := Max_Offset > 0.0;
      end if;

      if not Want_Bar then
         return;
      end if;

      Track_H :=
        Pixel_Type'Max (0.0, Content.Height - Metrics.Inset_Top - Metrics.Inset_Bot);
      if Track_H <= 0.0 or else Metrics.Width <= 0.0 then
         return;
      end if;

      W.Scroll_Track_Geom :=
        (X      => Content.X + Content.Width - Metrics.Width - Metrics.Inset_Right,
         Y      => Content.Y + Metrics.Inset_Top,
         Width  => Metrics.Width,
         Height => Track_H);

      Ratio := Float'Min (1.0, Float (W.Scroll_Viewport_H / Pixel_Type'Max (1.0, W.Scroll_Content_H)));
      Knob_H := Pixel_Type'Max (Metrics.Min_Knob_H, Track_H * Pixel_Type (Ratio));
      Knob_H := Pixel_Type'Min (Track_H, Knob_H);

      if Max_Offset > 0.0 and then Track_H > Knob_H then
         Knob_Y := W.Scroll_Track_Geom.Y + (W.Scroll_Offset_Y / Max_Offset) * (Track_H - Knob_H);
      else
         Knob_Y := W.Scroll_Track_Geom.Y;
      end if;

      W.Scroll_Knob_Geom :=
        (X      => W.Scroll_Track_Geom.X
                     + (W.Scroll_Track_Geom.Width - Pixel_Type'Min (W.Scroll_Track_Geom.Width, Metrics.Knob_Width)) / 2.0,
         Y      => Knob_Y,
         Width  => Pixel_Type'Min (W.Scroll_Track_Geom.Width, Metrics.Knob_Width),
         Height => Knob_H);
      W.Scroll_Show_Bar := True;
   end Update_Scrollbar_Geometry;

   procedure Update_Shared_Scroll_Layout (W : in out Widget'Class) is
      Content        : constant Rectangle := Get_Content_Box (W);
      Content_Bottom : Pixel_Type := Content.Y;
      Min_Top        : Pixel_Type := Content.Y;
      Has_Content    : Boolean := False;
      Max_Offset     : Pixel_Type;
      Shift_Y        : constant Pixel_Type := -W.Scroll_Offset_Y;
   begin
      W.Scroll_Viewport_H := Pixel_Type'Max (0.0, Content.Height);
      if Is_Scroll_Enabled (W) then
         W.Flags (Scrollable) := True;
      end if;
      for Child of W.Children loop
         declare
            G : constant Rectangle := Get_Geometry (Child.all);
            Pref : constant Size_2D := Get_Preferred_Size (Child.all);
            Effective_H : constant Pixel_Type := Pixel_Type'Max (G.Height, Pref.Height);
         begin
            Has_Content := True;
            Min_Top := Pixel_Type'Min (Min_Top, G.Y);
            Content_Bottom := Pixel_Type'Max (Content_Bottom, G.Y + Effective_H);
         end;
      end loop;

      if Has_Content then
         W.Scroll_Content_H := Pixel_Type'Max (W.Scroll_Viewport_H, Content_Bottom - Min_Top);
      end if;

      Clamp_Scroll_Offset (W);
      Max_Offset := Get_Scroll_Max_Offset_Y (W);
      if Max_Offset <= 0.0 then
         W.Scroll_Dragging := False;
      end if;

      if Is_Scroll_Enabled (W) and then W.Scroll_Offset_Y > 0.0 then
         for I in 1 .. Child_Count (W) loop
            declare
               Child   : constant Widget_Access := Get_Child (W, I);
               Child_G : Rectangle;
            begin
               if Child /= null then
                  Child_G := Get_Geometry (Child.all);
                  Child_G.Y := Child_G.Y + Shift_Y;
                  Set_Geometry (Child.all, Child_G);
               end if;
            end;
         end loop;
      end if;

      Update_Scrollbar_Geometry (W);
   end Update_Shared_Scroll_Layout;

   ---------------------------------------------------------------------------
   --  Flags
   ---------------------------------------------------------------------------

   procedure Set_Flag (W : in out Widget'Class;
                       F : Widget_Flag;
                       Value : Boolean) is
   begin
      W.Flags (F) := Value;
   end Set_Flag;

   function Has_Flag (W : Widget'Class; F : Widget_Flag) return Boolean is
   begin
      return W.Flags (F);
   end Has_Flag;

   procedure Set_On_Context_Menu
     (W  : in out Widget'Class;
      CB : Context_Menu_Callback)
   is
   begin
      W.On_Context_Menu := CB;
   end Set_On_Context_Menu;

   function Has_Context_Menu (W : Widget'Class) return Boolean is
   begin
      return W.On_Context_Menu /= null;
   end Has_Context_Menu;

   function Show_Context_Menu
     (W    : in out Widget'Class;
      X, Y : Pixel_Type) return Boolean
   is
      Self : constant Widget_Access := W'Unchecked_Access;
   begin
      if W.On_Context_Menu = null then
         return False;
      end if;

      W.On_Context_Menu (Self, X, Y);
      return True;
   end Show_Context_Menu;

   function Bubble_Context_Menu
     (Start : Widget_Access;
      X, Y  : Pixel_Type) return Boolean
   is
      Node         : Widget_Access := Start;
      Parent_Access : access Widget'Class;
   begin
      while Node /= null loop
         if Show_Context_Menu (Node.all, X, Y) then
            return True;
         end if;

         Parent_Access := Get_Parent (Node.all);
         if Parent_Access = null then
            Node := null;
         else
            Node := Parent_Access.all'Unchecked_Access;
         end if;
      end loop;

      return False;
   end Bubble_Context_Menu;

   ---------------------------------------------------------------------------
   --  Dirty/Update Tracking
   ---------------------------------------------------------------------------

   procedure Mark_Dirty (W : in out Widget'Class) is
   begin
      W.Dirty := True;
      if W.Parent /= null then
         Mark_Dirty (W.Parent.all);
      end if;
   end Mark_Dirty;

   procedure Mark_Clean (W : in out Widget'Class) is
   begin
      W.Dirty := False;
   end Mark_Clean;

   function Is_Dirty (W : Widget'Class) return Boolean is
   begin
      return W.Dirty;
   end Is_Dirty;

   ---------------------------------------------------------------------------
   --  Event Handlers
   ---------------------------------------------------------------------------

    procedure On_State_Changed (W : in out Widget'Class;
                               S : Widget_State;
                               Active : Boolean) is
      pragma Unreferenced (S, Active);
   begin
      null;
   end On_State_Changed;

   procedure On_Geometry_Changed (W : in out Widget'Class) is
   begin
      Mark_Dirty (W);
   end On_Geometry_Changed;

   function Handle_Scroll_Mouse_Down
     (W      : in out Widget'Class;
      X, Y   : Pixel_Type;
      Button : Mouse_Button) return Boolean
   is
      Content : constant Rectangle := Get_Content_Box (W);
      Knob_Hit_Slop_Px : constant Pixel_Type := 4.0;
      Knob_Hit : Rectangle;
      Offset_Y : Pixel_Type;
   begin
      if Button /= Left_Button or else not W.Scroll_Show_Bar then
         return False;
      end if;

      if not Point_In_Rect (W.Scroll_Track_Geom, X, Y) then
         return False;
      end if;

      Knob_Hit :=
        (X      => W.Scroll_Knob_Geom.X - Knob_Hit_Slop_Px,
         Y      => W.Scroll_Knob_Geom.Y - Knob_Hit_Slop_Px,
         Width  => W.Scroll_Knob_Geom.Width + 2.0 * Knob_Hit_Slop_Px,
         Height => W.Scroll_Knob_Geom.Height + 2.0 * Knob_Hit_Slop_Px);

      if Point_In_Rect (Knob_Hit, X, Y) then
         W.Scroll_Dragging := True;
         Offset_Y := Y - W.Scroll_Knob_Geom.Y;
         W.Scroll_Drag_Offset :=
           Clamp (Offset_Y, 0.0, Pixel_Type'Max (0.0, W.Scroll_Knob_Geom.Height));
         W.Scroll_Velocity_Y := 0.0;
      elsif Y < W.Scroll_Knob_Geom.Y then
         Scroll_By_Y (W, -Content.Height * 0.9);
      else
         Scroll_By_Y (W, Content.Height * 0.9);
      end if;

      Mark_Dirty (W);
      return True;
   end Handle_Scroll_Mouse_Down;

   procedure Handle_Scroll_Mouse_Move
     (W    : in out Widget'Class;
      X, Y : Pixel_Type)
   is
      pragma Unreferenced (X);
      Travel      : Pixel_Type;
      Top_Y       : Pixel_Type;
      Max_Offset  : Pixel_Type;
      Ratio       : Pixel_Type;
      Prev_Offset : Pixel_Type;
   begin
      if not W.Scroll_Dragging then
         return;
      end if;

      if not W.Scroll_Show_Bar then
         W.Scroll_Dragging := False;
         return;
      end if;

      Travel := Pixel_Type'Max (0.0, W.Scroll_Track_Geom.Height - W.Scroll_Knob_Geom.Height);
      if Travel <= 0.0 then
         Set_Scroll_Offset_Y (W, 0.0);
         return;
      end if;

      Top_Y := Clamp (Y - W.Scroll_Drag_Offset,
                      W.Scroll_Track_Geom.Y,
                      W.Scroll_Track_Geom.Y + Travel);
      Ratio := (Top_Y - W.Scroll_Track_Geom.Y) / Travel;
      Max_Offset := Get_Scroll_Max_Offset_Y (W);
      Prev_Offset := W.Scroll_Offset_Y;
      Set_Scroll_Offset_Y (W, Ratio * Max_Offset);
      if Scroll_Inertia_Enabled then
         W.Scroll_Velocity_Y :=
           Clamp ((W.Scroll_Offset_Y - Prev_Offset) * Drag_Velocity_Scale,
                  -Max_Scroll_Speed,
                  Max_Scroll_Speed);
      else
         W.Scroll_Velocity_Y := 0.0;
      end if;
   end Handle_Scroll_Mouse_Move;

   procedure Handle_Scroll_Mouse_Up
     (W      : in out Widget'Class;
      Button : Mouse_Button)
   is
   begin
      if Button = Left_Button and then W.Scroll_Dragging then
         W.Scroll_Dragging := False;
         Mark_Dirty (W);
      end if;
   end Handle_Scroll_Mouse_Up;

   procedure Handle_Scroll_Mouse_Wheel
     (W                : in out Widget'Class;
      Delta_X, Delta_Y : Pixel_Type)
   is
      pragma Unreferenced (Delta_X);
   begin
      if Delta_Y = 0.0 or else not Is_Scroll_Enabled (W) then
         return;
      end if;

      Set_Scroll_Offset_Y (W, W.Scroll_Offset_Y - (Delta_Y * Wheel_Step_Px));
      if Scroll_Inertia_Enabled then
         W.Scroll_Velocity_Y :=
           Clamp (W.Scroll_Velocity_Y - (Delta_Y * Wheel_Impulse_Px_S),
                  -Max_Scroll_Speed,
                  Max_Scroll_Speed);
      else
         W.Scroll_Velocity_Y := 0.0;
      end if;
   end Handle_Scroll_Mouse_Wheel;

   procedure Tick_Scroll_Animations (W : in out Widget'Class; DT : Duration) is
      DT_Float   : constant Float := Float (DT);
      Max_Offset : constant Pixel_Type := Get_Scroll_Max_Offset_Y (W);
      Old_Offset : Pixel_Type;
      Fast       : Boolean;
   begin
      if not Is_Scroll_Enabled (W) then
         if W.Scroll_Dragging or else W.Scroll_Velocity_Y /= 0.0 then
            W.Scroll_Dragging := False;
            W.Scroll_Velocity_Y := 0.0;
            Set_Part_State (W, Scroll_Part, State_Pressed, False);
            Set_Part_State (W, Knob_Part, State_Pressed, False);
         end if;
         return;
      end if;

      if not Scroll_Inertia_Enabled then
         W.Scroll_Velocity_Y := 0.0;
      elsif not W.Scroll_Dragging and then abs W.Scroll_Velocity_Y > Velocity_Epsilon then
         Old_Offset := W.Scroll_Offset_Y;
         Set_Scroll_Offset_Y (W, W.Scroll_Offset_Y + W.Scroll_Velocity_Y * Pixel_Type (DT_Float));

         if (W.Scroll_Offset_Y = 0.0 and then W.Scroll_Velocity_Y < 0.0)
           or else (W.Scroll_Offset_Y = Max_Offset and then W.Scroll_Velocity_Y > 0.0)
         then
            W.Scroll_Velocity_Y := 0.0;
         else
            W.Scroll_Velocity_Y :=
              W.Scroll_Velocity_Y * Pixel_Type (Exp (-Momentum_Friction * DT_Float));
         end if;

         if abs W.Scroll_Velocity_Y < Velocity_Epsilon
           or else W.Scroll_Offset_Y = Old_Offset
         then
            W.Scroll_Velocity_Y := 0.0;
         end if;
      end if;

      Fast := W.Scroll_Dragging
        or else (Scroll_Inertia_Enabled and then abs W.Scroll_Velocity_Y >= Launch_Threshold);
      Set_Part_State (W, Scroll_Part, State_Pressed, Fast);
      Set_Part_State (W, Knob_Part, State_Pressed, Fast);
   end Tick_Scroll_Animations;

   procedure Set_Scroll_Inertia_Enabled (Enabled : Boolean := True) is
   begin
      Scroll_Inertia_Enabled := Enabled;
   end Set_Scroll_Inertia_Enabled;

   function Get_Scroll_Inertia_Enabled return Boolean is
   begin
      return Scroll_Inertia_Enabled;
   end Get_Scroll_Inertia_Enabled;

   procedure Set_Debug_Layout_Overlay_Enabled (Enabled : Boolean := True) is
   begin
      Debug_Layout_Overlay_Enabled := Enabled;
   end Set_Debug_Layout_Overlay_Enabled;

   function Get_Debug_Layout_Overlay_Enabled return Boolean is
   begin
      return Debug_Layout_Overlay_Enabled;
   end Get_Debug_Layout_Overlay_Enabled;

   procedure On_Mouse_Down
     (W      : in out Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (Clicks);
   begin
      if Handle_Scroll_Mouse_Down (W, X, Y, Button) then
         return;
      end if;
   end On_Mouse_Down;

   procedure On_Mouse_Move
     (W    : in out Widget;
      X, Y : Pixel_Type)
   is
   begin
      Handle_Scroll_Mouse_Move (W, X, Y);
   end On_Mouse_Move;

   procedure On_Mouse_Up
     (W      : in out Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button)
   is
      pragma Unreferenced (X, Y);
   begin
      Handle_Scroll_Mouse_Up (W, Button);
   end On_Mouse_Up;

   procedure On_Mouse_Wheel
     (W                : in out Widget;
      Delta_X, Delta_Y : Pixel_Type)
   is
   begin
      Handle_Scroll_Mouse_Wheel (W, Delta_X, Delta_Y);
   end On_Mouse_Wheel;

   procedure On_Tick (W : in out Widget; DT : Duration) is
   begin
      Tick_Scroll_Animations (W, DT);
   end On_Tick;


   ---------------------------------------------------------------------------
   --  Item Creation Helpers
   ---------------------------------------------------------------------------

   function Make_Panel (Part : Part_Kind;
                        Geometry : Rectangle;
                        Z_Order : Natural := 0) return Item is
   begin
      return (Kind           => Panel_Item,
              Geometry       => Geometry,
              Part           => Part,
              Z_Order        => Z_Order,
              Computed_Style => Default_Resolved,
              others         => <>);
   end Make_Panel;

   function Make_Text (Part : Part_Kind;
                       Geometry : Rectangle;
                       Content : String;
                       Z_Order : Natural := 0) return Item is
   begin
      return (Kind           => Text_Item,
              Geometry       => Geometry,
              Part           => Part,
              Z_Order        => Z_Order,
              Computed_Style => Default_Resolved,
              Text_Content   => To_Unbounded_String (Content),
              others         => <>);
   end Make_Text;

   function Make_Image (Part : Part_Kind;
                        Geometry : Rectangle;
                        Source : Image_Access;
                        Z_Order : Natural := 0;
                        Is_Background : Boolean := False) return Item is
   begin
      return (Kind           => Image_Item,
              Geometry       => Geometry,
              Part           => Part,
              Z_Order        => Z_Order,
              Computed_Style => Default_Resolved,
              Image_Source   => Source,
              Is_Background  => Is_Background,
              others         => <>);
   end Make_Image;

   ---------------------------------------------------------------------------
   --  Color Conversion Helpers
   ---------------------------------------------------------------------------

   --  Convert CSS Color_Value to SDL RGBA components
   procedure CSS_Color_To_SDL
      (C : Color_Value;
       R, G, B, A : out Adi.SDL.Uint8)
   is
   begin
      case C.Kind is
         when Named =>
            case C.Name is
               when Black       => R := 0;   G := 0;   B := 0;   A := 255;
               when White       => R := 255; G := 255; B := 255; A := 255;
               when Red         => R := 255; G := 0;   B := 0;   A := 255;
               when Green       => R := 0;   G := 128; B := 0;   A := 255;
               when Blue        => R := 0;   G := 0;   B := 255; A := 255;
               when Yellow      => R := 255; G := 255; B := 0;   A := 255;
               when Orange      => R := 255; G := 165; B := 0;   A := 255;
               when Purple      => R := 128; G := 0;   B := 128; A := 255;
               when Gray        => R := 128; G := 128; B := 128; A := 255;
               when Light_Gray  => R := 211; G := 211; B := 211; A := 255;
               when Dark_Gray   => R := 64;  G := 64;  B := 64;  A := 255;
               when Transparent => R := 0;   G := 0;   B := 0;   A := 0;
               when Inherit | Current_Color => R := 0; G := 0; B := 0; A := 255;
            end case;
         when RGB =>
            R := Uint8 (C.R);
            G := Uint8 (C.G);
            B := Uint8 (C.B);
            A := 255;
         when RGBA =>
            R := Uint8 (C.RA);
            G := Uint8 (C.GA);
            B := Uint8 (C.BA);
            A := Uint8 (C.Alpha * 255.0);
      end case;
   end CSS_Color_To_SDL;

   ---------------------------------------------------------------------------
   --  SDL3 Rendering
   ---------------------------------------------------------------------------

   procedure Render_Rounded_Rect
      (Renderer      : SDL_Renderer_Ptr;
       Rect          : SDL_FRect;
       Corner_Radius : Float;
       R, G, B, A    : Uint8)
   is
      --  Clamp radius to half the smallest dimension
      Max_Radius : constant Float :=
         Float'Min (Rect.w, Rect.h) / 2.0;
      Rad : constant Float :=
         Float'Min (Corner_Radius, Max_Radius);

      --  Number of segments per corner arc
      Num_Seg : constant Positive :=
         Positive'Max (8, Natural (Float'Floor (Rad * 0.5)) + 1);

      --  Vertex/index counts:
      --  Center rect:  4 vertices, 6 indices
      --  4 edge rects: 4*4=16 vertices, 4*6=24 indices
      --  4 corners:    4*(Num_Seg+1) vertices at rim + shared center = 4*(Num_Seg+2)
      --                4*Num_Seg*3 indices
      Total_Verts   : constant Natural :=
         4 + 16 + 4 * (Num_Seg + 2);
      Total_Indices : constant Natural :=
         6 + 24 + 4 * Num_Seg * 3;

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;  --  next vertex index
      II : Natural := 0;  --  next index index

      FC : constant SDL_FColor :=
         (r => Float (R) / 255.0,
          g => Float (G) / 255.0,
          b => Float (B) / 255.0,
          a => Float (A) / 255.0);

      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      procedure Add_Vertex (X, Y : Float) is
      begin
         Verts (VI) := (position  => (x => X, y => Y),
                        color     => FC,
                        tex_coord => Zero_TC);
         VI := VI + 1;
      end Add_Vertex;

      procedure Add_Triangle (A, B, C : Natural) is
      begin
         Idxs (II)     := int (A);
         Idxs (II + 1) := int (B);
         Idxs (II + 2) := int (C);
         II := II + 3;
      end Add_Triangle;

      procedure Add_Rect (X1, Y1, X2, Y2 : Float) is
         Base : constant Natural := VI;
      begin
         Add_Vertex (X1, Y1);
         Add_Vertex (X2, Y1);
         Add_Vertex (X2, Y2);
         Add_Vertex (X1, Y2);
         Add_Triangle (Base, Base + 1, Base + 2);
         Add_Triangle (Base, Base + 2, Base + 3);
      end Add_Rect;

      procedure Add_Corner_Fan
         (Cx, Cy : Float;
          Start_Angle : Float)
      is
         Center_Idx : constant Natural := VI;
         Step       : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);
      begin
         --  Center vertex of the fan
         Add_Vertex (Cx, Cy);

         --  Arc vertices
         for I in 0 .. Num_Seg loop
            declare
               Angle : constant Float := Start_Angle + Float (I) * Step;
            begin
               Add_Vertex (Cx + Rad * Cos (Angle), Cy + Rad * Sin (Angle));
            end;
         end loop;

         --  Fan triangles
         for I in 0 .. Num_Seg - 1 loop
            Add_Triangle (Center_Idx, Center_Idx + 1 + I, Center_Idx + 2 + I);
         end loop;
      end Add_Corner_Fan;

      --  Rectangle edges
      X0 : constant Float := Rect.x;
      Y0 : constant Float := Rect.y;
      X1 : constant Float := Rect.x + Rect.w;
      Y1 : constant Float := Rect.y + Rect.h;

      Success : Adi.SDL.C_bool;
   begin
      if Rad < 1.0 then
         --  Fallback to regular rect for very small radii
         declare
            R2 : aliased SDL_FRect := Rect;
         begin
            SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                        "SDL_SetRenderDrawColor");
            SDL_Assert (SDL_RenderFillRect (Renderer, R2'Access),
                        "SDL_RenderFillRect");
            return;
         end;
      end if;

      --  Center rectangle (between all corner circles)
      Add_Rect (X0 + Rad, Y0 + Rad, X1 - Rad, Y1 - Rad);

      --  Top edge rectangle
      Add_Rect (X0 + Rad, Y0, X1 - Rad, Y0 + Rad);
      --  Bottom edge rectangle
      Add_Rect (X0 + Rad, Y1 - Rad, X1 - Rad, Y1);
      --  Left edge rectangle
      Add_Rect (X0, Y0 + Rad, X0 + Rad, Y1 - Rad);
      --  Right edge rectangle
      Add_Rect (X1 - Rad, Y0 + Rad, X1, Y1 - Rad);

      --  Corner fans (angles in standard math convention, Y-down)
      --  Top-left corner: arc from PI to 3*PI/2
      Add_Corner_Fan (X0 + Rad, Y0 + Rad, Ada.Numerics.Pi);
      --  Top-right corner: arc from 3*PI/2 to 2*PI
      Add_Corner_Fan (X1 - Rad, Y0 + Rad, 3.0 * Ada.Numerics.Pi / 2.0);
      --  Bottom-right corner: arc from 0 to PI/2
      Add_Corner_Fan (X1 - Rad, Y1 - Rad, 0.0);
      --  Bottom-left corner: arc from PI/2 to PI
      Add_Corner_Fan (X0 + Rad, Y1 - Rad, Ada.Numerics.Pi / 2.0);

      --  Set blend mode for alpha support
      SDL_Assert (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
                  "SDL_SetRenderDrawBlendMode");

      --  Render all geometry in one call
      Success := SDL_RenderGeometry
         (Renderer     => Renderer,
          Texture      => null,
          Vertices     => Verts (0)'Access,
          Num_Vertices => int (VI),
          Indices      => Idxs (0)'Access,
          Num_Indices  => int (II));
   end Render_Rounded_Rect;

   --  Rounded rectangle with per-corner radii using center-fan triangulation.
   --  The outline is built from 4 arcs (one per corner) and filled with
   --  triangles fanning from the rectangle center.  Corners with radius 0
   --  collapse to a single point, producing degenerate (zero-area) triangles
   --  that are harmlessly discarded by the GPU.

   procedure Render_Rounded_Rect
      (Renderer : SDL_Renderer_Ptr;
       Rect     : SDL_FRect;
       Radii    : Corner_Pixels;
       R, G, B, A : Uint8)
   is
      --  Clamp each radius to half the smallest dimension
      Max_Dim : constant Float := Float'Min (Rect.w, Rect.h) / 2.0;
      R_TL : constant Float := Float'Min (Radii.Top_Left, Max_Dim);
      R_TR : constant Float := Float'Min (Radii.Top_Right, Max_Dim);
      R_BR : constant Float := Float'Min (Radii.Bottom_Right, Max_Dim);
      R_BL : constant Float := Float'Min (Radii.Bottom_Left, Max_Dim);

      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));

      --  Segments per corner arc (based on largest radius)
      Num_Seg : constant Positive :=
         Positive'Max (8, Natural (Float'Floor (Max_R * 0.5)) + 1);

      --  Outline: 4 arcs of (Num_Seg + 1) points each
      --  + 1 center vertex for fan triangulation
      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := N_Outline + 1;
      Total_Indices : constant Natural := N_Outline * 3;

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;
      II : Natural := 0;

      FC : constant SDL_FColor :=
         (r => Float (R) / 255.0,
          g => Float (G) / 255.0,
          b => Float (B) / 255.0,
          a => Float (A) / 255.0);

      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      procedure Add_Vertex (X, Y : Float) is
      begin
         Verts (VI) := (position  => (x => X, y => Y),
                        color     => FC,
                        tex_coord => Zero_TC);
         VI := VI + 1;
      end Add_Vertex;

      procedure Add_Triangle (IA, IB, IC : Natural) is
      begin
         Idxs (II)     := int (IA);
         Idxs (II + 1) := int (IB);
         Idxs (II + 2) := int (IC);
         II := II + 3;
      end Add_Triangle;

      X0 : constant Float := Rect.x;
      Y0 : constant Float := Rect.y;
      X1 : constant Float := Rect.x + Rect.w;
      Y1 : constant Float := Rect.y + Rect.h;

      Center_Idx    : Natural;
      First_Outline : Natural;
      Step : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);
      Success : Adi.SDL.C_bool;
   begin
      if Max_R < 1.0 then
         declare
            R2 : aliased SDL_FRect := Rect;
         begin
            SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                        "SDL_SetRenderDrawColor");
            SDL_Assert (SDL_RenderFillRect (Renderer, R2'Access),
                        "SDL_RenderFillRect");
            return;
         end;
      end if;

      --  Center vertex for fan
      Center_Idx := VI;
      Add_Vertex ((X0 + X1) / 2.0, (Y0 + Y1) / 2.0);

      First_Outline := VI;

      --  Top-left arc: center (X0+R_TL, Y0+R_TL), from PI to 3*PI/2
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               Ada.Numerics.Pi + Float (I) * Step;
         begin
            Add_Vertex (X0 + R_TL + R_TL * Cos (Angle),
                        Y0 + R_TL + R_TL * Sin (Angle));
         end;
      end loop;

      --  Top-right arc: center (X1-R_TR, Y0+R_TR), from 3*PI/2 to 2*PI
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               3.0 * Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (X1 - R_TR + R_TR * Cos (Angle),
                        Y0 + R_TR + R_TR * Sin (Angle));
         end;
      end loop;

      --  Bottom-right arc: center (X1-R_BR, Y1-R_BR), from 0 to PI/2
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Float (I) * Step;
         begin
            Add_Vertex (X1 - R_BR + R_BR * Cos (Angle),
                        Y1 - R_BR + R_BR * Sin (Angle));
         end;
      end loop;

      --  Bottom-left arc: center (X0+R_BL, Y1-R_BL), from PI/2 to PI
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (X0 + R_BL + R_BL * Cos (Angle),
                        Y1 - R_BL + R_BL * Sin (Angle));
         end;
      end loop;

      --  Fan triangles from center to consecutive outline pairs
      for I in 0 .. N_Outline - 1 loop
         declare
            Next_I : constant Natural := (I + 1) mod N_Outline;
         begin
            Add_Triangle (Center_Idx,
                          First_Outline + I,
                          First_Outline + Next_I);
         end;
      end loop;

      SDL_Assert (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
                  "SDL_SetRenderDrawBlendMode");

      Success := SDL_RenderGeometry
         (Renderer     => Renderer,
          Texture      => null,
          Vertices     => Verts (0)'Access,
          Num_Vertices => int (VI),
          Indices      => Idxs (0)'Access,
          Num_Indices  => int (II));
   end Render_Rounded_Rect;

   --  Render a rounded-rectangle border ring (annulus) between an outer and
   --  inner rounded rect.  Used when the background is transparent so we
   --  cannot use the "fill outer, overlay inner" approach.

   procedure Render_Rounded_Border_Ring
      (Renderer       : SDL_Renderer_Ptr;
       Outer_Rect     : SDL_FRect;
       Inner_Rect     : SDL_FRect;
       Outer_Radii    : Corner_Pixels;
       Inner_Radii    : Corner_Pixels;
       R, G, B, A     : Uint8)
   is
      Max_Dim_O : constant Float := Float'Min (Outer_Rect.w, Outer_Rect.h) / 2.0;
      O_TL : constant Float := Float'Min (Outer_Radii.Top_Left, Max_Dim_O);
      O_TR : constant Float := Float'Min (Outer_Radii.Top_Right, Max_Dim_O);
      O_BR : constant Float := Float'Min (Outer_Radii.Bottom_Right, Max_Dim_O);
      O_BL : constant Float := Float'Min (Outer_Radii.Bottom_Left, Max_Dim_O);

      Max_Dim_I : constant Float := Float'Min (Inner_Rect.w, Inner_Rect.h) / 2.0;
      I_TL : constant Float := Float'Min (Float'Max (0.0, Inner_Radii.Top_Left), Max_Dim_I);
      I_TR : constant Float := Float'Min (Float'Max (0.0, Inner_Radii.Top_Right), Max_Dim_I);
      I_BR : constant Float := Float'Min (Float'Max (0.0, Inner_Radii.Bottom_Right), Max_Dim_I);
      I_BL : constant Float := Float'Min (Float'Max (0.0, Inner_Radii.Bottom_Left), Max_Dim_I);

      Max_R : constant Float :=
         Float'Max (Float'Max (O_TL, O_TR), Float'Max (O_BR, O_BL));

      Num_Seg : constant Positive :=
         Positive'Max (8, Natural (Float'Floor (Max_R * 0.5)) + 1);

      --  Two outlines (outer + inner), each with 4*(Num_Seg+1) points
      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := 2 * N_Outline;
      Total_Indices : constant Natural := N_Outline * 6;  --  2 triangles per segment

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;
      II : Natural := 0;

      FC : constant SDL_FColor :=
         (r => Float (R) / 255.0,
          g => Float (G) / 255.0,
          b => Float (B) / 255.0,
          a => Float (A) / 255.0);

      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      procedure Add_Vertex (X, Y : Float) is
      begin
         Verts (VI) := (position  => (x => X, y => Y),
                        color     => FC,
                        tex_coord => Zero_TC);
         VI := VI + 1;
      end Add_Vertex;

      procedure Add_Triangle (IA, IB, IC : Natural) is
      begin
         Idxs (II)     := int (IA);
         Idxs (II + 1) := int (IB);
         Idxs (II + 2) := int (IC);
         II := II + 3;
      end Add_Triangle;

      --  Outer rect edges
      OX0 : constant Float := Outer_Rect.x;
      OY0 : constant Float := Outer_Rect.y;
      OX1 : constant Float := Outer_Rect.x + Outer_Rect.w;
      OY1 : constant Float := Outer_Rect.y + Outer_Rect.h;

      --  Inner rect edges
      IX0 : constant Float := Inner_Rect.x;
      IY0 : constant Float := Inner_Rect.y;
      IX1 : constant Float := Inner_Rect.x + Inner_Rect.w;
      IY1 : constant Float := Inner_Rect.y + Inner_Rect.h;

      Step : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);

      Outer_Start : Natural;
      Inner_Start : Natural;
      Success     : Adi.SDL.C_bool;
   begin
      --  Generate outer outline points
      Outer_Start := VI;

      --  Top-left arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi + Float (I) * Step;
         begin
            Add_Vertex (OX0 + O_TL + O_TL * Cos (Angle),
                        OY0 + O_TL + O_TL * Sin (Angle));
         end;
      end loop;
      --  Top-right arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := 3.0 * Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (OX1 - O_TR + O_TR * Cos (Angle),
                        OY0 + O_TR + O_TR * Sin (Angle));
         end;
      end loop;
      --  Bottom-right arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Float (I) * Step;
         begin
            Add_Vertex (OX1 - O_BR + O_BR * Cos (Angle),
                        OY1 - O_BR + O_BR * Sin (Angle));
         end;
      end loop;
      --  Bottom-left arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (OX0 + O_BL + O_BL * Cos (Angle),
                        OY1 - O_BL + O_BL * Sin (Angle));
         end;
      end loop;

      --  Generate inner outline points (same arc order)
      Inner_Start := VI;

      --  Top-left arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi + Float (I) * Step;
         begin
            Add_Vertex (IX0 + I_TL + I_TL * Cos (Angle),
                        IY0 + I_TL + I_TL * Sin (Angle));
         end;
      end loop;
      --  Top-right arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := 3.0 * Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (IX1 - I_TR + I_TR * Cos (Angle),
                        IY0 + I_TR + I_TR * Sin (Angle));
         end;
      end loop;
      --  Bottom-right arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Float (I) * Step;
         begin
            Add_Vertex (IX1 - I_BR + I_BR * Cos (Angle),
                        IY1 - I_BR + I_BR * Sin (Angle));
         end;
      end loop;
      --  Bottom-left arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (IX0 + I_BL + I_BL * Cos (Angle),
                        IY1 - I_BL + I_BL * Sin (Angle));
         end;
      end loop;

      --  Build triangle strip between outer and inner outlines
      for I in 0 .. N_Outline - 1 loop
         declare
            Next_I : constant Natural := (I + 1) mod N_Outline;
         begin
            --  Triangle 1: outer[i], outer[i+1], inner[i+1]
            Add_Triangle (Outer_Start + I,
                          Outer_Start + Next_I,
                          Inner_Start + Next_I);
            --  Triangle 2: outer[i], inner[i+1], inner[i]
            Add_Triangle (Outer_Start + I,
                          Inner_Start + Next_I,
                          Inner_Start + I);
         end;
      end loop;

      SDL_Assert (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
                  "SDL_SetRenderDrawBlendMode");

      Success := SDL_RenderGeometry
         (Renderer     => Renderer,
          Texture      => null,
          Vertices     => Verts (0)'Access,
          Num_Vertices => int (VI),
          Indices      => Idxs (0)'Access,
          Num_Indices  => int (II));
   end Render_Rounded_Border_Ring;

   --  Apply opacity to an alpha byte
   function Apply_Opacity (A : Uint8; O : Float) return Uint8 is
   begin
      if O >= 1.0 then
         return A;
      elsif O <= 0.0 then
         return 0;
      else
         return Uint8 (Float (A) * O);
      end if;
   end Apply_Opacity;

   procedure Render_Panel (
      Renderer : SDL_Renderer_Ptr;
      Geom     : Rectangle;
      Style    : Resolved_Style)
   is
      Border_W : Edge_Pixels;
      R, G, B, A : Uint8;
      Rect : aliased SDL_FRect;
      Radius_Px  : Corner_Pixels;
      Max_Rad    : Float;
      Has_Radius : Boolean;
      Has_Border : Boolean;
      Uniform_Border_Width : Boolean;
      BW_Top     : Float;
      BW_Right   : Float;
      BW_Bottom  : Float;
      BW_Left    : Float;
      Uniform    : Boolean;
      Op         : constant Float := Float (Style.Opacity);
      function Edge_Style (E : Edge) return Border_Style_Kind is
      begin
         case Style.Border_Style.Kind is
            when Gap_Uniform =>
               return Style.Border_Style.All_Edges;
            when Per_Edge =>
               return Style.Border_Style.Edges (E);
         end case;
      end Edge_Style;

      function Is_Visible_Edge (E : Edge; Width : Float) return Boolean is
         S : constant Border_Style_Kind := Edge_Style (E);
      begin
         return Width > 0.0 and then S /= None_Style and then S /= Hidden;
      end Is_Visible_Edge;

      procedure Set_Edge_Color (E : Edge) is
      begin
         case Style.Border_Color.Kind is
            when Gap_Uniform =>
               CSS_Color_To_SDL (Style.Border_Color.All_Edges, R, G, B, A);
            when Per_Edge =>
               CSS_Color_To_SDL (Style.Border_Color.Edges (E), R, G, B, A);
         end case;
         A := Apply_Opacity (A, Op);
         SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                     "SDL_SetRenderDrawColor");
      end Set_Edge_Color;
   begin
      if Style.Visibility = Visibility_Hidden then
         return;
      end if;

      Border_W := Get_Border_Width_Px (Style);
      Radius_Px := Get_Border_Radius_Px (Style.Border_Radius);
      Max_Rad := Float'Max
         (Float'Max (Radius_Px.Top_Left, Radius_Px.Top_Right),
          Float'Max (Radius_Px.Bottom_Right, Radius_Px.Bottom_Left));
      Has_Radius := Max_Rad > 0.0;
      BW_Top := Float (Border_W.Top);
      BW_Right := Float (Border_W.Right);
      BW_Bottom := Float (Border_W.Bottom);
      BW_Left := Float (Border_W.Left);
      Has_Border :=
        Is_Visible_Edge (Top, BW_Top)
        or else Is_Visible_Edge (Right, BW_Right)
        or else Is_Visible_Edge (Bottom, BW_Bottom)
        or else Is_Visible_Edge (Left, BW_Left);
      Uniform_Border_Width :=
        BW_Top = BW_Right and then BW_Right = BW_Bottom and then BW_Bottom = BW_Left;
      Uniform := Radius_Px.Top_Left = Radius_Px.Top_Right
         and then Radius_Px.Top_Right = Radius_Px.Bottom_Right
         and then Radius_Px.Bottom_Right = Radius_Px.Bottom_Left;

      --  Set up outer rectangle geometry
      Rect.x := Float (Geom.X);
      Rect.y := Float (Geom.Y);
      Rect.w := Float (Geom.Width);
      Rect.h := Float (Geom.Height);

      if Has_Radius then

         if Has_Border and then Uniform_Border_Width and then BW_Top > 0.0 then
            --  Render border as a ring (annulus), then fill the interior.
            declare
               Inner : constant SDL_FRect :=
                  (x => Rect.x + BW_Top,
                   y => Rect.y + BW_Top,
                   w => Float'Max (0.0, Rect.w - 2.0 * BW_Top),
                   h => Float'Max (0.0, Rect.h - 2.0 * BW_Top));
               Inner_Radii : constant Corner_Pixels :=
                  (Top_Left     => Float'Max (0.0, Radius_Px.Top_Left - BW_Top),
                   Top_Right    => Float'Max (0.0, Radius_Px.Top_Right - BW_Top),
                   Bottom_Right => Float'Max (0.0, Radius_Px.Bottom_Right - BW_Top),
                   Bottom_Left  => Float'Max (0.0, Radius_Px.Bottom_Left - BW_Top));
            begin
               --  Border ring
               Set_Edge_Color (Top);
               Render_Rounded_Border_Ring
                  (Renderer, Rect, Inner, Radius_Px, Inner_Radii, R, G, B, A);

               --  Background fill (skip for fully transparent)
               if Style.Background_Color.Kind /= Named
                  or else Style.Background_Color.Name /= Transparent
               then
                  CSS_Color_To_SDL (Style.Background_Color, R, G, B, A);
                  A := Apply_Opacity (A, Op);
                  if Inner.w > 0.0 and then Inner.h > 0.0 then
                     if Uniform then
                        Render_Rounded_Rect
                           (Renderer, Inner,
                            Float'Max (0.0, Max_Rad - BW_Top), R, G, B, A);
                     else
                        Render_Rounded_Rect
                           (Renderer, Inner, Inner_Radii, R, G, B, A);
                     end if;
                  end if;
               end if;
            end;

         else
            --  No border: just fill background
            if Style.Background_Color.Kind /= Named
               or else Style.Background_Color.Name /= Transparent
            then
               CSS_Color_To_SDL (Style.Background_Color, R, G, B, A);
               A := Apply_Opacity (A, Op);
               if Uniform then
                  Render_Rounded_Rect (Renderer, Rect, Max_Rad, R, G, B, A);
               else
                  Render_Rounded_Rect (Renderer, Rect, Radius_Px, R, G, B, A);
               end if;
            end if;
         end if;

      else
         --  No border radius: use fast SDL rect primitives

         --  Background
         if Style.Background_Color.Kind /= Named
            or else Style.Background_Color.Name /= Transparent
         then
            CSS_Color_To_SDL (Style.Background_Color, R, G, B, A);
            A := Apply_Opacity (A, Op);
            SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                        "SDL_SetRenderDrawColor");
            SDL_Assert (SDL_RenderFillRect (Renderer, Rect'Access),
                        "SDL_RenderFillRect");
         end if;

         --  Border
         if Has_Border then
            declare
               Edge_Rect : aliased SDL_FRect;
            begin
               if Is_Visible_Edge (Top, BW_Top) then
                  Set_Edge_Color (Top);
                  Edge_Rect :=
                    (x => Rect.x,
                     y => Rect.y,
                     w => Rect.w,
                     h => BW_Top);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
               end if;

               if Is_Visible_Edge (Bottom, BW_Bottom) then
                  Set_Edge_Color (Bottom);
                  Edge_Rect :=
                    (x => Rect.x,
                     y => Rect.y + Float'Max (0.0, Rect.h - BW_Bottom),
                     w => Rect.w,
                     h => BW_Bottom);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
               end if;

               if Is_Visible_Edge (Left, BW_Left) then
                  Set_Edge_Color (Left);
                  Edge_Rect :=
                    (x => Rect.x,
                     y => Rect.y,
                     w => BW_Left,
                     h => Rect.h);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
               end if;

               if Is_Visible_Edge (Right, BW_Right) then
                  Set_Edge_Color (Right);
                  Edge_Rect :=
                    (x => Rect.x + Float'Max (0.0, Rect.w - BW_Right),
                     y => Rect.y,
                     w => BW_Right,
                     h => Rect.h);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
               end if;
            end;
         end if;
      end if;
   end Render_Panel;

   procedure Render_Text_Item (
      Ctx : in out Render_Context;
      It  : in out Item)
   is
      use Interfaces.C;
      use Interfaces.C.Strings;
      use type Adi.Font.Font_Attributes;

      Content    : constant String := To_String (It.Text_Content);
      Style      : Resolved_Style renames It.Computed_Style;
      Geom       : Rectangle renames It.Geometry;
      Text_Obj   : TTF_Text_Access;
      Font       : TTF_Font_Access;
      Prev_Font  : constant TTF_Font_Access := It.Cached_Font;
      C_Text     : chars_ptr;
      Font_Sz    : Float;
      Font_Attrs : Adi.Font.Font_Attributes;
      Font_Key_Changed : Boolean;
      R, G, B, A : Uint8;
      Success    : Adi.SDL.C_bool;
      Engine     : TTF_TextEngine_Access;
      Renderer   : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Prev_Clip  : aliased Adi.SDL.SDL_Rect;
      Clip_Rect  : aliased Adi.SDL.SDL_Rect;
      Had_Clip   : Boolean := False;
      Use_Clip   : constant Boolean :=
        Renderer /= null and then Geom.Width > 0.0 and then Geom.Height > 0.0;
      X1, Y1, X2, Y2 : Integer;
   begin
      if Style.Visibility = Visibility_Hidden or else Content'Length = 0 then
         return;
      end if;

      --  Zero/negative text geometry must render nothing; otherwise clip can
      --  be skipped and text may reappear when constrained to height 0.
      if Geom.Width <= 0.0 or else Geom.Height <= 0.0 then
         return;
      end if;

      --  Get text engine from render context (created lazily)
      Engine := Get_Text_Engine (Ctx);
      if Engine = null then
         Adi.Log.Error ("Failed to create text engine");
         return;
      end if;

      --  Calculate font size
      Font_Sz := Float (Length_To_Px (Style.Font_Size, Container_Size => Geom.Height));
      if Font_Sz = 0.0 then
         Font_Sz := Adi.Font.Default_Font_Size_Px;
      end if;

      Font_Attrs := Adi.Font.Make_Attributes
        (Family     => Style.Font_Family,
         Size       => Font_Sz,
         Weight     => Style.Font_Weight,
         Style      => Style.Font_Style,
         Decoration => Style.Text_Decoration);

      Font_Key_Changed :=
        It.Cached_Font = null
        or else It.Cached_Font_Attrs /= Font_Attrs;

      if Font_Key_Changed then
         Font := Adi.Font.Get_TTF_Font (Font_Attrs);
         if Font = null then
            return;
         end if;

         It.Cached_Font := Font;
         It.Cached_Font_Attrs := Font_Attrs;
      else
         Font := It.Cached_Font;
      end if;

      --  Reuse or create cached text object
      Text_Obj := It.Cached_TTF_Text;

      if Text_Obj /= null and then (Font_Key_Changed or else Prev_Font /= Font) then
         Success := TTF_SetTextFont (Text_Obj, Font);
         if not Boolean (Success) then
            TTF_DestroyText (Text_Obj);
            Text_Obj := null;
            It.Cached_TTF_Text := null;
            It.Cached_Text_String := Null_Unbounded_String;
         end if;
      end if;

      if Text_Obj = null then
         --  First time: create text object
         C_Text := New_String (Content);
         Text_Obj := TTF_CreateText (Engine, Font, C_Text,
                                     size_t (Content'Length));
         Free (C_Text);

         if Text_Obj = null then
            Adi.Log.Error ("Failed to create text object");
            return;
         end if;

         It.Cached_TTF_Text := Text_Obj;
         It.Cached_Text_String := To_Unbounded_String (Content);

      elsif It.Cached_Text_String /= It.Text_Content then
         --  Text content changed: update in-place
         C_Text := New_String (Content);
         Success := TTF_SetTextString (Text_Obj, C_Text, size_t (Content'Length));
         Free (C_Text);
         It.Cached_Text_String := It.Text_Content;
      end if;

      --  Set text color (with opacity)
      CSS_Color_To_SDL (Style.Color, R, G, B, A);
      A := Apply_Opacity (A, Float (Style.Opacity));
      Success := TTF_SetTextColor (Text_Obj, R, G, B, A);

      --  Configure wrapping per item.
      if It.Wrap_Text and then Geom.Width > 0.0 then
         Success := TTF_SetTextWrapWidth (Text_Obj, int (Geom.Width));
      else
         Success := TTF_SetTextWrapWidth (Text_Obj, 0);
      end if;

      --  Clip text to item bounds to prevent overflow bleed.
      if Use_Clip then
         Had_Clip := Boolean (SDL_RenderClipEnabled (Renderer));
         if Had_Clip then
            Success := SDL_GetRenderClipRect (Renderer, Prev_Clip'Access);
         end if;

         X1 := Integer (Float'Floor (Float (Geom.X)));
         Y1 := Integer (Float'Floor (Float (Geom.Y)));
         X2 := X1 + Integer (Float'Ceiling (Float (Geom.Width)));
         Y2 := Y1 + Integer (Float'Ceiling (Float (Geom.Height)));

         if Had_Clip then
            X1 := Integer'Max (X1, Integer (Prev_Clip.x));
            Y1 := Integer'Max (Y1, Integer (Prev_Clip.y));
            X2 := Integer'Min (X2, Integer (Prev_Clip.x + Prev_Clip.w));
            Y2 := Integer'Min (Y2, Integer (Prev_Clip.y + Prev_Clip.h));
         end if;

         if X2 <= X1 or else Y2 <= Y1 then
            if Had_Clip then
               Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
            else
               Success := SDL_SetRenderClipRect (Renderer, null);
            end if;
            return;
         end if;

         Clip_Rect :=
           (x => int (X1),
            y => int (Y1),
            w => int (X2 - X1),
            h => int (Y2 - Y1));
         Success := SDL_SetRenderClipRect (Renderer, Clip_Rect'Access);
      end if;

      --  Draw the text (snap to integer pixels to avoid sub-pixel blurring)
      Success := TTF_DrawRendererText
        (Text_Obj,
         C_float (Float'Floor (Float (Geom.X + It.Text_Offset_X))),
         C_float (Float'Floor (Float (Geom.Y + It.Text_Offset_Y))));

      if Use_Clip then
         if Had_Clip then
            Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
         else
            Success := SDL_SetRenderClipRect (Renderer, null);
         end if;
      end if;
   end Render_Text_Item;

   --  Render a texture clipped to a rounded rectangle via UV-mapped
   --  triangle-fan geometry.  When all radii are < 1 px the image is
   --  rendered as a plain textured quad for speed.

   procedure Render_Rounded_Image
      (Renderer     : SDL_Renderer_Ptr;
       Rect         : SDL_FRect;
       Radii        : Corner_Pixels;
       Texture      : SDL_Texture_Ptr;
       Src_U0       : Float := 0.0;
       Src_V0       : Float := 0.0;
       Src_U1       : Float := 1.0;
       Src_V1       : Float := 1.0;
       Opacity      : Float := 1.0)
   is
      Max_Dim : constant Float := Float'Min (Rect.w, Rect.h) / 2.0;
      R_TL : constant Float := Float'Min (Radii.Top_Left, Max_Dim);
      R_TR : constant Float := Float'Min (Radii.Top_Right, Max_Dim);
      R_BR : constant Float := Float'Min (Radii.Bottom_Right, Max_Dim);
      R_BL : constant Float := Float'Min (Radii.Bottom_Left, Max_Dim);

      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));

      Num_Seg : constant Positive :=
         Positive'Max (8, Natural (Float'Floor (Max_R * 0.5)) + 1);

      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := N_Outline + 1;
      Total_Indices : constant Natural := N_Outline * 3;

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;
      II : Natural := 0;

      FC : constant SDL_FColor := (r => 1.0, g => 1.0, b => 1.0, a => Opacity);

      X0 : constant Float := Rect.x;
      Y0 : constant Float := Rect.y;
      X1 : constant Float := Rect.x + Rect.w;
      Y1 : constant Float := Rect.y + Rect.h;

      Inv_W : constant Float := (if Rect.w > 0.0 then 1.0 / Rect.w else 0.0);
      Inv_H : constant Float := (if Rect.h > 0.0 then 1.0 / Rect.h else 0.0);

      --  UV range to map across the rect
      DU : constant Float := Src_U1 - Src_U0;
      DV : constant Float := Src_V1 - Src_V0;

      procedure Add_Vertex (X, Y : Float) is
      begin
         Verts (VI) := (position  => (x => X, y => Y),
                        color     => FC,
                        tex_coord => (x => Src_U0 + (X - X0) * Inv_W * DU,
                                      y => Src_V0 + (Y - Y0) * Inv_H * DV));
         VI := VI + 1;
      end Add_Vertex;

      procedure Add_Triangle (IA, IB, IC : Natural) is
      begin
         Idxs (II)     := int (IA);
         Idxs (II + 1) := int (IB);
         Idxs (II + 2) := int (IC);
         II := II + 3;
      end Add_Triangle;

      Center_Idx    : Natural;
      First_Outline : Natural;
      Step : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);
      Success : Adi.SDL.C_bool;
   begin
      if Max_R < 1.0 then
         --  No rounding — simple quad with UV mapping
         declare
            Q : SDL_Vertex_Array (0 .. 3);
            QI : Int_Array (0 .. 5) := (0, 1, 2, 0, 2, 3);
         begin
            Q (0) := (position => (x => X0, y => Y0), color => FC,
                      tex_coord => (x => Src_U0, y => Src_V0));
            Q (1) := (position => (x => X1, y => Y0), color => FC,
                      tex_coord => (x => Src_U1, y => Src_V0));
            Q (2) := (position => (x => X1, y => Y1), color => FC,
                      tex_coord => (x => Src_U1, y => Src_V1));
            Q (3) := (position => (x => X0, y => Y1), color => FC,
                      tex_coord => (x => Src_U0, y => Src_V1));
            Success := SDL_SetTextureBlendMode (Texture, SDL_BLENDMODE_BLEND);
            Success := SDL_RenderGeometry
               (Renderer, Texture, Q (0)'Access, 4, QI (0)'Access, 6);
            return;
         end;
      end if;

      --  Center vertex for fan
      Center_Idx := VI;
      Add_Vertex ((X0 + X1) / 2.0, (Y0 + Y1) / 2.0);

      First_Outline := VI;

      --  Top-left arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               Ada.Numerics.Pi + Float (I) * Step;
         begin
            Add_Vertex (X0 + R_TL + R_TL * Cos (Angle),
                        Y0 + R_TL + R_TL * Sin (Angle));
         end;
      end loop;

      --  Top-right arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               3.0 * Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (X1 - R_TR + R_TR * Cos (Angle),
                        Y0 + R_TR + R_TR * Sin (Angle));
         end;
      end loop;

      --  Bottom-right arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Float (I) * Step;
         begin
            Add_Vertex (X1 - R_BR + R_BR * Cos (Angle),
                        Y1 - R_BR + R_BR * Sin (Angle));
         end;
      end loop;

      --  Bottom-left arc
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               Ada.Numerics.Pi / 2.0 + Float (I) * Step;
         begin
            Add_Vertex (X0 + R_BL + R_BL * Cos (Angle),
                        Y1 - R_BL + R_BL * Sin (Angle));
         end;
      end loop;

      --  Fan triangles
      for I in 0 .. N_Outline - 1 loop
         declare
            Next_I : constant Natural := (I + 1) mod N_Outline;
         begin
            Add_Triangle (Center_Idx,
                          First_Outline + I,
                          First_Outline + Next_I);
         end;
      end loop;

      Success := SDL_SetTextureBlendMode (Texture, SDL_BLENDMODE_BLEND);
      SDL_Assert (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
                  "SDL_SetRenderDrawBlendMode");

      Success := SDL_RenderGeometry
         (Renderer     => Renderer,
          Texture      => Texture,
          Vertices     => Verts (0)'Access,
          Num_Vertices => int (VI),
          Indices      => Idxs (0)'Access,
          Num_Indices  => int (II));
   end Render_Rounded_Image;

   procedure Render_Image_Item (
      Renderer : SDL_Renderer_Ptr;
      Geom     : Rectangle;
      Source   : Image_Access;
      Style    : Resolved_Style)
   is
      Texture          : SDL_Texture_Ptr;
      Src_W, Src_H     : Pixel_Type;
      Dst_X, Dst_Y     : Pixel_Type;
      Dst_W, Dst_H     : Pixel_Type;
      Scale_X, Scale_Y : Float;
      Dst_Rect         : aliased SDL_FRect;
      U0, V0, U1, V1  : Float;
      Radius_Px        : Corner_Pixels;
      Max_Rad          : Float;
      Success          : Adi.SDL.C_bool;
   begin
      if Style.Visibility = Visibility_Hidden then
         return;
      end if;

      if Source = null or else not Is_Valid (Source.all) then
         return;
      end if;

      Texture := Get_Texture (Source.all);
      if Texture = null then
         return;
      end if;

      Get_Size (Source.all, Src_W, Src_H);
      if Src_W = 0.0 or Src_H = 0.0 then
         return;
      end if;

      --  Border radius for clipping
      Radius_Px := Get_Border_Radius_Px (Style.Border_Radius);
      Max_Rad := Float'Max
         (Float'Max (Radius_Px.Top_Left, Radius_Px.Top_Right),
          Float'Max (Radius_Px.Bottom_Right, Radius_Px.Bottom_Left));

      --  Default: full texture
      U0 := 0.0; V0 := 0.0; U1 := 1.0; V1 := 1.0;

      case Style.Object_Fit is
         when Fit_Fill =>
            Dst_X := Geom.X;
            Dst_Y := Geom.Y;
            Dst_W := Geom.Width;
            Dst_H := Geom.Height;

         when Fit_Cover =>
            --  Fill geometry preserving aspect ratio, crop via UV
            Dst_X := Geom.X;
            Dst_Y := Geom.Y;
            Dst_W := Geom.Width;
            Dst_H := Geom.Height;
            if Geom.Width > 0.0 and then Geom.Height > 0.0 then
               declare
                  Img_Asp  : constant Float :=
                     Float (Src_W) / Float (Src_H);
                  Geom_Asp : constant Float :=
                     Float (Geom.Width) / Float (Geom.Height);
               begin
                  if Img_Asp > Geom_Asp then
                     --  Image wider: crop sides
                     declare
                        U_Span : constant Float := Geom_Asp / Img_Asp;
                     begin
                        U0 := (1.0 - U_Span) / 2.0;
                        U1 := U0 + U_Span;
                     end;
                  else
                     --  Image taller: crop top/bottom
                     declare
                        V_Span : constant Float := Img_Asp / Geom_Asp;
                     begin
                        V0 := (1.0 - V_Span) / 2.0;
                        V1 := V0 + V_Span;
                     end;
                  end if;
               end;
            end if;

         when Fit_Contain =>
            Scale_X := Float (Geom.Width) / Float (Src_W);
            Scale_Y := Float (Geom.Height) / Float (Src_H);
            declare
               S : constant Float := Float'Min (Scale_X, Scale_Y);
            begin
               Dst_W := Pixel_Type (Float (Src_W) * S);
               Dst_H := Pixel_Type (Float (Src_H) * S);
            end;
            Dst_X := Geom.X + (Geom.Width - Dst_W) / 2.0;
            Dst_Y := Geom.Y + (Geom.Height - Dst_H) / 2.0;

         when Fit_None =>
            Dst_W := Pixel_Type (Src_W);
            Dst_H := Pixel_Type (Src_H);
            Dst_X := Geom.X;
            Dst_Y := Geom.Y;

         when Fit_Scale_Down =>
            if Pixel_Type (Src_W) > Geom.Width
               or Pixel_Type (Src_H) > Geom.Height
            then
               Scale_X := Float (Geom.Width) / Float (Src_W);
               Scale_Y := Float (Geom.Height) / Float (Src_H);
               declare
                  S : constant Float := Float'Min (Scale_X, Scale_Y);
               begin
                  Dst_W := Pixel_Type (Float (Src_W) * S);
                  Dst_H := Pixel_Type (Float (Src_H) * S);
               end;
            else
               Dst_W := Pixel_Type (Src_W);
               Dst_H := Pixel_Type (Src_H);
            end if;
            Dst_X := Geom.X + (Geom.Width - Dst_W) / 2.0;
            Dst_Y := Geom.Y + (Geom.Height - Dst_H) / 2.0;
      end case;

      --  Object-position (for non-Cover/Fill modes)
      if Style.Object_Fit /= Fit_Fill and Style.Object_Fit /= Fit_Cover then
         case Style.Object_Position.Kind is
            when Keyword_Pos =>
               case Style.Object_Position.H_Keyword is
                  when Pos_Left   => Dst_X := Geom.X;
                  when Pos_Center => null;
                  when Pos_Right  => Dst_X := Geom.X + Geom.Width - Dst_W;
                  when others     => null;
               end case;
               case Style.Object_Position.V_Keyword is
                  when Pos_Top    => Dst_Y := Geom.Y;
                  when Pos_Center => null;
                  when Pos_Bottom => Dst_Y := Geom.Y + Geom.Height - Dst_H;
                  when others     => null;
               end case;
            when Length_Pos =>
               Dst_X := Geom.X +
                  Length_To_Px (Style.Object_Position.X_Offset, Geom.Width);
               Dst_Y := Geom.Y +
                  Length_To_Px (Style.Object_Position.Y_Offset, Geom.Height);
         end case;
      end if;

      Dst_Rect.x := Float (Dst_X);
      Dst_Rect.y := Float (Dst_Y);
      Dst_Rect.w := Float (Dst_W);
      Dst_Rect.h := Float (Dst_H);

      --  For modes where the image may not fill the container (Contain,
      --  None, Scale_Down), reduce corner radii based on how much the
      --  image is inset from each container edge.  If the image edge
      --  doesn't reach the container's rounded corner region, that
      --  corner needs no rounding.
      if Style.Object_Fit /= Fit_Fill
         and then Style.Object_Fit /= Fit_Cover
         and then Max_Rad > 0.0
      then
         declare
            Inset_L : constant Float := Float (Dst_X - Geom.X);
            Inset_T : constant Float := Float (Dst_Y - Geom.Y);
            Inset_R : constant Float :=
               Float ((Geom.X + Geom.Width) - (Dst_X + Dst_W));
            Inset_B : constant Float :=
               Float ((Geom.Y + Geom.Height) - (Dst_Y + Dst_H));
         begin
            Radius_Px.Top_Left := Float'Max (0.0, Float'Min (
               Radius_Px.Top_Left - Inset_L,
               Radius_Px.Top_Left - Inset_T));
            Radius_Px.Top_Right := Float'Max (0.0, Float'Min (
               Radius_Px.Top_Right - Inset_R,
               Radius_Px.Top_Right - Inset_T));
            Radius_Px.Bottom_Right := Float'Max (0.0, Float'Min (
               Radius_Px.Bottom_Right - Inset_R,
               Radius_Px.Bottom_Right - Inset_B));
            Radius_Px.Bottom_Left := Float'Max (0.0, Float'Min (
               Radius_Px.Bottom_Left - Inset_L,
               Radius_Px.Bottom_Left - Inset_B));
            Max_Rad := Float'Max
               (Float'Max (Radius_Px.Top_Left, Radius_Px.Top_Right),
                Float'Max (Radius_Px.Bottom_Right, Radius_Px.Bottom_Left));
         end;
      end if;

      if Max_Rad > 0.0 then
         Render_Rounded_Image
            (Renderer, Dst_Rect, Radius_Px, Texture,
             U0, V0, U1, V1, Float (Style.Opacity));
      else
         Success := SDL_SetTextureAlphaModFloat (Texture, Float (Style.Opacity));
         if U0 /= 0.0 or else V0 /= 0.0
            or else U1 /= 1.0 or else V1 /= 1.0
         then
            --  Cropped source (Cover mode without rounding)
            declare
               Src_Rect : aliased SDL_FRect :=
                  (x => U0 * Float (Src_W),
                   y => V0 * Float (Src_H),
                   w => (U1 - U0) * Float (Src_W),
                   h => (V1 - V0) * Float (Src_H));
            begin
               Success := SDL_RenderTexture
                  (Renderer, Texture, Src_Rect'Access, Dst_Rect'Access);
            end;
         else
            Success := SDL_RenderTexture
               (Renderer, Texture, null, Dst_Rect'Access);
         end if;
      end if;
   end Render_Image_Item;

   ---------------------------------------------------------------------------
   --  Public Rendering Interface
   ---------------------------------------------------------------------------

   procedure Draw_Debug_Rect
     (Renderer : SDL_Renderer_Ptr;
      Geom     : Rectangle;
      R, G, B, A : Uint8;
      Filled   : Boolean := False)
   is
      Rect : aliased SDL_FRect :=
        (x => Float (Geom.X),
         y => Float (Geom.Y),
         w => Float (Geom.Width),
         h => Float (Geom.Height));
   begin
      if Renderer = null
        or else Geom.Width <= 0.0
        or else Geom.Height <= 0.0
      then
         return;
      end if;

      SDL_Assert (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
                  "SDL_SetRenderDrawBlendMode");
      SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                  "SDL_SetRenderDrawColor");
      if Filled then
         SDL_Assert (SDL_RenderFillRect (Renderer, Rect'Access),
                     "SDL_RenderFillRect");
      else
         SDL_Assert (SDL_RenderRect (Renderer, Rect'Access),
                     "SDL_RenderRect");
      end if;
   end Draw_Debug_Rect;

   procedure Debug_Item_Color
     (Index : Positive;
      Kind  : Item_Kind;
      R, G, B : out Uint8)
   is
      Seed : constant Natural := Index * 67 + Item_Kind'Pos (Kind) * 97;
   begin
      R := Uint8 (45 + ((Seed * 29) mod 160));
      G := Uint8 (45 + ((Seed * 53) mod 160));
      B := Uint8 (45 + ((Seed * 83) mod 160));
   end Debug_Item_Color;

   procedure Render_Items (W : in out Widget'Class; Ctx : in out Render_Context) is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
   begin
      for I in 1 .. Natural (W.Items.Length) loop
         declare
            Current : Item renames W.Items.Reference (I).Element.all;
            Style   : Resolved_Style renames Current.Computed_Style;
         begin
            case Current.Kind is
               when Panel_Item =>
                  if Style.Box_Shadow /= No_Shadow then
                     Render_Box_Shadow (Ctx, Current.Geometry, Style);
                  end if;
                  Render_Panel (Renderer, Current.Geometry, Style);

               when Text_Item =>
                  Render_Text_Item (Ctx, Current);

               when Image_Item =>
                  Render_Image_Item (
                     Renderer,
                     Current.Geometry,
                     Current.Image_Source,
                     Style);
            end case;

            if Debug_Layout_Overlay_Enabled and then Renderer /= null then
               declare
                  R, G, B : Uint8;
               begin
                  Debug_Item_Color (I, Current.Kind, R, G, B);
                  Draw_Debug_Rect (Renderer, Current.Geometry, R, G, B, 26, True);
                  Draw_Debug_Rect (Renderer, Current.Geometry, R, G, B, 170, False);
               end;
            end if;
         end;
      end loop;
   end Render_Items;

   procedure Render_Shared_Scrollbar
     (W   : in out Widget'Class;
      Ctx : in out Render_Context)
   is
      Renderer     : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Scroll_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Scroll_Part);
      Knob_Style   : constant Resolved_Style := Get_Resolved_Part_Style (W, Knob_Part);
   begin
      if Renderer = null or else not W.Scroll_Show_Bar then
         return;
      end if;

      Render_Panel (Renderer, W.Scroll_Track_Geom, Scroll_Style);
      Render_Panel (Renderer, W.Scroll_Knob_Geom, Knob_Style);
   end Render_Shared_Scrollbar;

   procedure Render_Tree (W : in out Widget'Class; Ctx : in out Render_Context) is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Prev_Clip  : aliased Adi.SDL.SDL_Rect;
      Clip_Rect  : aliased Adi.SDL.SDL_Rect;
      Had_Clip   : Boolean := False;
      Use_Clip   : Boolean := False;
      Skip_Children : Boolean := False;
      Success    : Adi.SDL.C_bool;
      X1, Y1, X2, Y2 : Integer;
   begin
      if not Has_Flag (W, Visible) then
         return;
      end if;

      --  Render this widget's own visuals first; overflow clipping applies to
      --  descendant content, not the widget's own background/border panel.
      Render_Items (W, Ctx);

      if Debug_Layout_Overlay_Enabled and then Renderer /= null then
         declare
            Main_Style : constant Resolved_Style :=
              Get_Resolved_Part_Style (W, Main_Part);
            Geom : constant Rectangle := Get_Geometry (W);
            Margin : constant Edge_Pixels := Get_Margin_Px (Main_Style);
            Margin_Box : constant Rectangle :=
              (X => Geom.X - Margin.Left,
               Y => Geom.Y - Margin.Top,
               Width => Geom.Width + Margin.Left + Margin.Right,
               Height => Geom.Height + Margin.Top + Margin.Bottom);
            Padding : constant Rectangle := Padding_Box (Geom, Main_Style);
            Content : constant Rectangle := Content_Box (Geom, Main_Style);
         begin
            Draw_Debug_Rect (Renderer, Margin_Box, 219, 153, 62, 20, True);
            Draw_Debug_Rect (Renderer, Padding, 59, 130, 246, 24, True);
            Draw_Debug_Rect (Renderer, Content, 34, 197, 94, 28, True);

            Draw_Debug_Rect (Renderer, Margin_Box, 219, 153, 62, 140, False);
            Draw_Debug_Rect (Renderer, Geom, 234, 88, 12, 170, False);
            Draw_Debug_Rect (Renderer, Padding, 59, 130, 246, 160, False);
            Draw_Debug_Rect (Renderer, Content, 34, 197, 94, 180, False);
         end;
      end if;

      if Renderer /= null then
         declare
            Main_Style : constant Resolved_Style :=
              Get_Resolved_Part_Style (W, Main_Part);
            Clip_By_Overflow : constant Boolean :=
              Main_Style.Overflow in Overflow_Hidden | Overflow_Scroll | Overflow_Auto;
            Clip_By_Scrollable : constant Boolean := Has_Flag (W, Scrollable);
            Content : constant Rectangle :=
              Padding_Box (Get_Geometry (W), Main_Style);
         begin
            if Clip_By_Overflow or else Clip_By_Scrollable then
               if Content.Width <= 0.0 or else Content.Height <= 0.0 then
                  Skip_Children := True;
               else
                  Use_Clip := True;
                  Had_Clip := Boolean (SDL_RenderClipEnabled (Renderer));
                  if Had_Clip then
                     Success := SDL_GetRenderClipRect (Renderer, Prev_Clip'Access);
                  end if;

                  X1 := Integer (Float'Floor (Float (Content.X)));
                  Y1 := Integer (Float'Floor (Float (Content.Y)));
                  X2 := X1 + Integer (Float'Ceiling (Float (Content.Width)));
                  Y2 := Y1 + Integer (Float'Ceiling (Float (Content.Height)));

                  if Had_Clip then
                     X1 := Integer'Max (X1, Integer (Prev_Clip.x));
                     Y1 := Integer'Max (Y1, Integer (Prev_Clip.y));
                     X2 := Integer'Min (X2, Integer (Prev_Clip.x + Prev_Clip.w));
                     Y2 := Integer'Min (Y2, Integer (Prev_Clip.y + Prev_Clip.h));
                  end if;

                  if X2 > X1 and then Y2 > Y1 then
                     Clip_Rect :=
                       (x => int (X1),
                        y => int (Y1),
                        w => int (X2 - X1),
                        h => int (Y2 - Y1));
                     Success := SDL_SetRenderClipRect (Renderer, Clip_Rect'Access);
                  else
                     Use_Clip := False;
                     Skip_Children := True;
                  end if;
               end if;
            end if;
         end;
      end if;

      if not Skip_Children then
         for Child of W.Children loop
            Render_Tree (Child.all, Ctx);
         end loop;
      end if;

      if Use_Clip then
         if Had_Clip then
            Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
         else
            Success := SDL_SetRenderClipRect (Renderer, null);
         end if;
      end if;

      Render_Shared_Scrollbar (W, Ctx);
   end Render_Tree;

   procedure Update_And_Render (W : in out Widget'Class; Ctx : in out Render_Context) is
   begin
      Update (W);
      Render_Tree (W, Ctx);
   end Update_And_Render;
---------------------------------------------------------------------------
   --  Content Measurement
   ---------------------------------------------------------------------------

   function Measure_Content(W : Widget) return Size_2D is
      Result : Size_2D := (0.0, 0.0);


   begin
      --  Measure based on items
      for I in 1 .. Item_Count(W) loop
         declare
            Current : constant Item := Get_Item(W, I);
         begin
            case Current.Kind is
               when Panel_Item =>
                  --  Panel contributes its geometry
                  Result := Max(Result, (Current.Geometry.Width, Current.Geometry.Height));

               when Text_Item =>
                  --  For text, we'd ideally measure the text
                  --  For now, use geometry as approximation
                  Result := Max(Result, (Current.Geometry.Width, Current.Geometry.Height));

               when Image_Item =>
                  --  Get image dimensions (skip background images)
                  if not Current.Is_Background
                     and then Current.Image_Source /= null
                     and then Is_Valid(Current.Image_Source.all)
                  then
                     declare
                        Img_W, Img_H : Pixel_Type;
                     begin
                        Get_Size(Current.Image_Source.all, Img_W, Img_H);
                        Result := Max(Result, (Img_W, Img_H));
                     end;
                  end if;
            end case;
         end;
      end loop;

      --  Also consider children
      for Child of W.Children loop
         declare
            Child_Size : constant Size_2D := Measure_Content(Child.all);
         begin
            Result := Max(Result, Child_Size);
         end;
      end loop;

      return Result;
   end Measure_Content;

   function Get_Min_Size(W : Widget'Class) return Size_2D is
      Style : constant Resolved_Style := Get_Resolved_Part_Style(W, Main_Part);
      Min_W, Min_H : Pixel_Type := 0.0;
   begin
      --  Check explicit min-width/min-height
      case Style.Min_Width.Kind is
         when Fixed =>
            Min_W := Size_To_Px(Style.Min_Width, W.Geometry.Width);
         when others =>
            Min_W := 0.0;
      end case;

      case Style.Min_Height.Kind is
         when Fixed =>
            Min_H := Size_To_Px(Style.Min_Height, W.Geometry.Height);
         when others =>
            Min_H := 0.0;
      end case;

      --  When no explicit min is set, use 0 rather than Measure_Content.
      --  Measure_Content on containers reads item geometry from the previous
      --  frame, so during window shrink the stale (larger) size becomes the
      --  minimum, preventing the flex shrink algorithm from reducing items.
      --  Explicit min-width/min-height values are still respected above.

      return (Min_W, Min_H);
   end Get_Min_Size;

   function Get_Preferred_Size(W : Widget'Class) return Size_2D is
      Style : constant Resolved_Style := Get_Resolved_Part_Style(W, Main_Part);
      Pref_W, Pref_H : Pixel_Type := 0.0;
   begin
      --  Check explicit width/height
      case Style.Width.Kind is
         when Fixed =>
            Pref_W := Size_To_Px(Style.Width, W.Geometry.Width);
         when others =>
            Pref_W := 0.0;  -- Auto
      end case;

      case Style.Height.Kind is
         when Fixed =>
            Pref_H := Size_To_Px(Style.Height, W.Geometry.Height);
         when others =>
            Pref_H := 0.0;  -- Auto
      end case;

      --  If auto, use content size
      if Pref_W = 0.0 or Pref_H = 0.0 then
         declare
            Content : constant Size_2D := Measure_Content(W);
         begin
            if Pref_W = 0.0 then
               Pref_W := Content.Width;
            end if;
            if Pref_H = 0.0 then
               Pref_H := Content.Height;
            end if;
         end;
      end if;

      return (Pref_W, Pref_H);
   end Get_Preferred_Size;

   ---------------------------------------------------------------------------
   --  Flex Layout
   ---------------------------------------------------------------------------

   function Is_Flex_Container(W : Widget'Class) return Boolean is
      Style : constant Resolved_Style := Get_Resolved_Part_Style(W, Main_Part);
   begin
      return Style.Display = Flex or Style.Display = Inline_Flex;
   end Is_Flex_Container;

   procedure Perform_Flex_Layout(W : in out Widget'Class) is
      Style : constant Resolved_Style := Get_Resolved_Part_Style(W, Main_Part);
      Num_Children : constant Natural := Natural(W.Children.Length);

      --  Content box (after padding/border)
      Content : constant Rectangle := Content_Box(W.Geometry, Style);
   begin
      if Num_Children = 0 then
         return;
      end if;

      --  Build flex context
      declare
         Context : Flex_Layout_Context;
         Children_Info : Flex_Child_Info_Array(1 .. Num_Children);
         Child_Index : Positive := 1;
      begin
         Context := (
            Container       => Content,
            Direction       => Style.Flex_Direction,
            Wrap            => Style.Flex_Wrap,
            Justify_Content => Style.Justify_Content,
            Align_Items     => Style.Align_Items,
            Align_Content   => Style.Align_Content,
            Row_Gap         => Get_Main_Gap(Style.Gap, Style.Flex_Direction),
            Column_Gap      => Get_Cross_Gap(Style.Gap, Style.Flex_Direction)
         );

         --  Collect child information
         for Child of W.Children loop
            declare
               Child_Style : constant Resolved_Style :=
                  Get_Resolved_Part_Style(Child.all, Main_Part);
               Child_Pref : constant Size_2D := Get_Preferred_Size(Child.all);
               Child_Min  : constant Size_2D := Get_Min_Size(Child.all);

               Info : Flex_Child_Info;
               Flex_Basis_Px : Pixel_Type := 0.0;
            begin
               --  Flex properties
               Info.Flex_Grow := Float(Child_Style.Flex_Grow);
               Info.Flex_Shrink := Float(Child_Style.Flex_Shrink);

               --  Flex basis--  Flex basis
                case Child_Style.Flex_Basis.Kind is
                   when Auto =>
                      Flex_Basis_Px := Get_Main_Size(Child_Pref, Style.Flex_Direction);
                   when CSS_Styles.Content =>
                      Flex_Basis_Px := Get_Main_Size(Child_Min, Style.Flex_Direction);
                   when Fixed =>
                      Flex_Basis_Px := Length_To_Px(
                         Child_Style.Flex_Basis.Size,
                         Get_Main_Size((Content.Width, Content.Height), Style.Flex_Direction));
                end case;
                Info.Flex_Basis := Flex_Basis_Px;

               --  Align self
               Info.Align_Self := Child_Style.Align_Self;

               --  Size constraints
               Info.Min_Main := Get_Main_Size(Child_Min, Style.Flex_Direction);
               Info.Min_Cross := Get_Cross_Size(Child_Min, Style.Flex_Direction);

               --  For visible overflow, preserve preferred main size only for
               --  non-shrinkable children. Shrinkable children must be allowed
               --  to contract (and rely on their own clipping/wrapping rules).
               if Style.Overflow = Overflow_Visible
                 and then Float (Child_Style.Flex_Shrink) = 0.0
               then
                  Info.Min_Main := Pixel_Type'Max
                    (Info.Min_Main, Get_Main_Size (Child_Pref, Style.Flex_Direction));
               end if;

               --  Max constraints
               declare
                  Max_W : Pixel_Type := Pixel_Type'Last;
                  Max_H : Pixel_Type := Pixel_Type'Last;
               begin
                  case Child_Style.Max_Width.Kind is
                     when Fixed =>
                        Max_W := Size_To_Px(Child_Style.Max_Width, Content.Width);
                     when others =>
                        null;
                  end case;
                  case Child_Style.Max_Height.Kind is
                     when Fixed =>
                        Max_H := Size_To_Px(Child_Style.Max_Height, Content.Height);
                     when others =>
                        null;
                  end case;
                  Info.Max_Main := Get_Main_Size((Max_W, Max_H), Style.Flex_Direction);
                  Info.Max_Cross := Get_Cross_Size((Max_W, Max_H), Style.Flex_Direction);
               end;

               --  Content sizes
               Info.Content_Main := Get_Main_Size(Child_Pref, Style.Flex_Direction);
               Info.Content_Cross := Get_Cross_Size(Child_Pref, Style.Flex_Direction);

               --  Margins
               Info.Margin := Get_Margin_Px(Child_Style);

               Children_Info(Child_Index) := Info;
               Child_Index := Child_Index + 1;
            end;
         end loop;

         --  Run flex algorithm
         Compute_Flex_Layout(Context, Children_Info);

         --  Convert to rectangles and apply; save assigned rects for
         --  second-pass comparison
         declare
            Assigned : constant Rectangle_Array :=
               Flex_To_Rectangles(Context, Children_Info);
            Rect_Index : Positive := 1;
         begin
            for Child of W.Children loop
               Set_Geometry(Child.all, Assigned(Rect_Index));
               Rect_Index := Rect_Index + 1;
            end loop;

            --  Recursively layout children
            for Child of W.Children loop
               Layout(Child.all);
            end loop;

            --  Second pass: if any child grew (e.g. text wrapping
            --  increased height), re-run flex layout with updated
            --  sizes so siblings shift.
            declare
               Any_Grew    : Boolean := False;
               Recheck_Idx : Positive := 1;
            begin
               for Child of W.Children loop
                  declare
                     Child_Geom : constant Rectangle :=
                        Get_Geometry(Child.all);
                     Actual_Main : constant Pixel_Type := Get_Main_Size
                       ((Child_Geom.Width, Child_Geom.Height),
                        Style.Flex_Direction);
                     Assigned_Main : constant Pixel_Type := Get_Main_Size
                       ((Assigned(Recheck_Idx).Width,
                         Assigned(Recheck_Idx).Height),
                        Style.Flex_Direction);
                  begin
                     if Actual_Main > Assigned_Main then
                        Children_Info(Recheck_Idx).Flex_Basis :=
                           Actual_Main;
                        Children_Info(Recheck_Idx).Min_Main :=
                           Actual_Main;
                        Children_Info(Recheck_Idx).Content_Main :=
                           Actual_Main;
                        Any_Grew := True;
                     end if;
                  end;
                  Recheck_Idx := Recheck_Idx + 1;
               end loop;

               if Any_Grew then
                  Compute_Flex_Layout(Context, Children_Info);
                  declare
                     Rects2 : constant Rectangle_Array :=
                        Flex_To_Rectangles(Context, Children_Info);
                     Rect_Idx2 : Positive := 1;
                  begin
                     for Child of W.Children loop
                        Set_Geometry(Child.all, Rects2(Rect_Idx2));
                        Layout(Child.all);
                        Rect_Idx2 := Rect_Idx2 + 1;
                     end loop;
                  end;
               end if;
            end;
         end;
      end;
   end Perform_Flex_Layout;

   ---------------------------------------------------------------------------
   --  Perform_Item_Flex_Layout - Flex layout for items within a widget
   ---------------------------------------------------------------------------

   procedure Perform_Item_Flex_Layout
      (Container_Geom  : Rectangle;
       Container_Style : Resolved_Style;
       Items           : in out Layout_Item_List.Vector)
   is
      use Adi.Layout_Util;

      Num_Items : constant Natural := Natural (Items.Length);
   begin
      --  Preconditions
      pragma Assert (Container_Geom.Width >= 0.0,
         "Container width must be non-negative");
      pragma Assert (Container_Geom.Height >= 0.0,
         "Container height must be non-negative");

      if Num_Items = 0 then
         return;
      end if;

      declare
         Context       : Flex_Layout_Context;
         Children_Info : Flex_Child_Info_Array (1 .. Num_Items);
         Rectangles    : Rectangle_Array (1 .. Num_Items);
         Index         : Positive := 1;
      begin
         --  Build flex context from container style
         Context := (
            Container       => Container_Geom,
            Direction       => Container_Style.Flex_Direction,
            Wrap            => Container_Style.Flex_Wrap,
            Justify_Content => Container_Style.Justify_Content,
            Align_Items     => Container_Style.Align_Items,
            Align_Content   => Container_Style.Align_Content,
            Row_Gap         => Get_Main_Gap (Container_Style.Gap, Container_Style.Flex_Direction),
            Column_Gap      => Get_Cross_Gap (Container_Style.Gap, Container_Style.Flex_Direction)
         );

         --  Convert Layout_Items to Flex_Child_Info
         for Item of Items loop
            declare
               Info : Flex_Child_Info;
            begin
               --  Flex properties
               Info.Flex_Grow   := Item.Flex.Grow;
               Info.Flex_Shrink := Item.Flex.Shrink;
               Info.Flex_Basis  := Pixel_Type (Item.Flex.Basis);

               --  Alignment
               case Item.Flex.Align_Self is
                  when Auto =>
                     Info.Align_Self := Auto;
                  when Flex_Start =>
                     Info.Align_Self := Flex_Start;
                  when Flex_End =>
                     Info.Align_Self := Flex_End;
                  when Center =>
                     Info.Align_Self := Center;
                  when Baseline =>
                     Info.Align_Self := Baseline;
                  when Stretch =>
                     Info.Align_Self := Stretch;
               end case;

               --  Size constraints (convert to main/cross axis)
               if Is_Row_Direction (Container_Style.Flex_Direction) then
                  Info.Min_Main    := Pixel_Type (Item.Min_Width);
                  Info.Max_Main    := Pixel_Type (Item.Max_Width);
                  Info.Min_Cross   := Pixel_Type (Item.Min_Height);
                  Info.Max_Cross   := Pixel_Type (Item.Max_Height);
                  Info.Content_Main  := Pixel_Type (Item.Content_Width);
                  Info.Content_Cross := Pixel_Type (Item.Content_Height);
               else
                  Info.Min_Main    := Pixel_Type (Item.Min_Height);
                  Info.Max_Main    := Pixel_Type (Item.Max_Height);
                  Info.Min_Cross   := Pixel_Type (Item.Min_Width);
                  Info.Max_Cross   := Pixel_Type (Item.Max_Width);
                  Info.Content_Main  := Pixel_Type (Item.Content_Height);
                  Info.Content_Cross := Pixel_Type (Item.Content_Width);
               end if;

               --  Keep overflow-visible content floor for non-shrinkable or
               --  explicitly constrained items. Shrinkable items with no min
               --  (e.g. wrapping text) must still be allowed to contract.
               if Container_Style.Overflow = Overflow_Visible
                 and then (Info.Min_Main > 0.0 or else Info.Flex_Shrink = 0.0)
               then
                  Info.Min_Main := Pixel_Type'Max (Info.Min_Main, Info.Content_Main);
               end if;

               --  No margins for items (can be added later if needed)
               Info.Margin := Zero_Edges;

               Children_Info (Index) := Info;
               Index := Index + 1;
            end;
         end loop;

         --  Compute flex layout
         Compute_Flex_Layout (Context, Children_Info);

         --  Convert to rectangles
         Rectangles := Flex_To_Rectangles (Context, Children_Info);

         --  Update Layout_Items with calculated geometry
         Index := 1;
         for Item of Items loop
            Item.Geometry := Rectangles (Index);

            --  Postconditions for each item
            pragma Assert (Item.Geometry.Width >= 0.0,
               "Item width must be non-negative");
            pragma Assert (Item.Geometry.Height >= 0.0,
               "Item height must be non-negative");
            pragma Assert (Item.Geometry.X >= Container_Geom.X,
               "Item X must be >= container X");
            pragma Assert (Item.Geometry.Y >= Container_Geom.Y,
               "Item Y must be >= container Y");
            pragma Assert (Item.Geometry.X + Item.Geometry.Width <=
                          Container_Geom.X + Container_Geom.Width + 1.0,
               "Item must fit within container width (with 1px tolerance)");
            pragma Assert (Item.Geometry.Y + Item.Geometry.Height <=
                          Container_Geom.Y + Container_Geom.Height + 1.0,
               "Item must fit within container height (with 1px tolerance)");

            Index := Index + 1;
         end loop;
      end;
   end Perform_Item_Flex_Layout;

   -- In Adi.Widget (new procedures):

   procedure Full_Layout (W : in out Widget'Class) is
   begin
      -- Phase 1: Measure content sizes (bottom-up via recursion in Measure_Content)
      -- Already exists but may need explicit call

      -- Phase 2: Layout (top-down)
      Layout (W);  -- This sets children's geometry

      -- Phase 3: Build items with final geometry
      Build_Items (W);
      Apply_Styles_To_Items (W);

      -- Recurse to children (they've been laid out, now build their items)
      for Child of W.Children loop
         -- Child geometry was set by parent's Layout
         Build_Items (Child.all);
         Apply_Styles_To_Items (Child.all);
         -- Recurse for grandchildren
         for Grandchild of Child.Children loop
            Full_Layout (Grandchild.all);
         end loop;
      end loop;
   end Full_Layout;

    procedure Update (W : in Out Widget'Class) is
    begin
       -- Layout must have been called before this!
       -- Now build items using correct geometry
       Build_Items (W);
       Apply_Styles_To_Items (W);

       for Child of W.Children loop
          Update (Child.all);
       end loop;
       Mark_Clean (W);
    end Update;

procedure Rebuild_All_Items (W : in out Widget'Class) is
begin
   Build_Items (W);
   Apply_Styles_To_Items (W);

   for Child of W.Children loop
      Rebuild_All_Items (Child.all);
   end loop;
   Mark_Clean (W);
end Rebuild_All_Items;


procedure Layout_Tree (W : in out Widget'Class) is
begin
   Layout (W);
   Update_Shared_Scroll_Layout (W);
   for Child of W.Children loop
      Layout_Tree (Child.all);
   end loop;
   Mark_Clean (W);
end Layout_Tree;

---------------------------------------------------------------------------
--  Tick_Animations
---------------------------------------------------------------------------

procedure Tick_Animations (W : in out Widget'Class; DT : Duration) is
   Any_Active : Boolean := False;
   Had_Active : Boolean := False;
   DT_Float   : constant Float := Float (DT);
begin
   On_Tick (W, DT);

   for P in Part_Kind loop
      if W.Transitions (P).Active then
         Had_Active := True;
         declare
            Interpolated : Resolved_Style;
         begin
            Advance (W.Transitions (P), DT_Float, Interpolated);

            --  Apply interpolated style to all items of this part
            for I in 1 .. Natural (W.Items.Length) loop
               declare
                  Current_Item : Item := W.Items.Element (I);
               begin
                  if Current_Item.Part = P then
                     Current_Item.Computed_Style := Interpolated;
                     W.Items.Replace_Element (I, Current_Item);
                  end if;
               end;
            end loop;

            if W.Transitions (P).Active then
               Any_Active := True;
            end if;
         end;
      end if;
   end loop;

   W.Has_Any_Animation := Any_Active;
   if Any_Active or else Had_Active then
      Mark_Dirty (W);
   end if;

   --  Recurse to children
   for Child of W.Children loop
      Tick_Animations (Child.all, DT);
   end loop;
end Tick_Animations;

end Adi.Widget;
