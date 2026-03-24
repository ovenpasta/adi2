
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Containers; use Ada.Containers;
with Ada.Containers.Hashed_Maps;
with Ada.Containers.Vectors;
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
with Interfaces;
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

   --  Global layout epoch: incremented per Layout_Tree pass, used by
   --  containers to avoid laying out children that were already processed
   --  in the current pass.
   Current_Layout_Epoch : Natural := 0;

   --  Widget ID counter: monotonically increasing, assigned at creation
   Id_Counter : Natural := 0;

   function Allocate_Widget_Id return Natural is
   begin
      Id_Counter := Id_Counter + 1;
      return Id_Counter;
   end Allocate_Widget_Id;

   function Get_Id (W : Widget'Class) return Natural is (W.Widget_Id);

   ---------------------------------------------------------------------------
   --  Handle Store operations
   ---------------------------------------------------------------------------

   function Is_Valid (H : Widget_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function Get_Handle (W : Widget'Class) return Widget_Handle is
   begin
      if W.Store_Index = 0 and then Widget_Stores.Is_Strict then
         raise Program_Error with
           "Get_Handle: widget not registered in store";
      end if;
      return (Id => (Index => Widget_Stores.Slot_Index (W.Store_Index),
                     Gen   => Widget_Stores.Generation (W.Store_Gen)));
   end Get_Handle;

   function Resolve_Handle (H : Widget_Handle) return Widget_Access is
   begin
      return Widget_Stores.Get (H.Id);
   end Resolve_Handle;

   function Borrow (H : Widget_Handle) return Widget_Ref is
      P : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if P = null then
         raise Constraint_Error with "Widget.Borrow: stale or null handle";
      end if;
      Widget_Stores.Pin (H.Id);
      return (Ada.Finalization.Limited_Controlled with
              Ptr => P, Id => H.Id);
   end Borrow;

   overriding procedure Finalize (R : in out Widget_Ref) is
      use type Widget_Stores.Object_Id;
   begin
      if R.Id /= Widget_Stores.Null_Id then
         Widget_Stores.Unpin (R.Id);
      end if;
   end Finalize;

   --  Forward declaration for recursive child destruction
   procedure Destroy_Subtree (W : not null Widget_Access);

   procedure Destroy (H : in out Widget_Handle) is
      Obj : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Obj = null then
         H.Id := Widget_Stores.Null_Id;
         return;
      end if;

      --  Let the window layer clean up refs/root/overlays BEFORE detaching
      --  from parent (Find_Host_Window uses subtree membership).
      if Destroy_Detach_Hook /= null then
         Destroy_Detach_Hook (Obj);
      end if;

      --  Detach from parent
      if Obj.Parent /= null then
         Remove_Child (Obj.Parent.all, Obj);
      end if;

      --  Recursively mark children for destruction (bottom-up), then self
      Destroy_Subtree (Obj);
      H.Id := Widget_Stores.Null_Id;
   end Destroy;

   procedure Destroy_Subtree (W : not null Widget_Access) is
      use Widget_List;
   begin
      --  Recurse into children first (bottom-up destruction)
      declare
         C : Widget_List.Cursor := W.Children.First;
      begin
         while C /= No_Element loop
            declare
               Child : constant Widget_Access := Element (C);
            begin
               Next (C);
               if Child /= null then
                  Child.Parent := null;
                  if Child.Store_Index > 0 then
                     Destroy_Subtree (Child);
                  end if;
               end if;
            end;
         end loop;
      end;

      On_Destroy (Widget'Class (W.all));

      W.Children.Clear;
      Clear_Items (Widget'Class (W.all));

      if W.Store_Index > 0 then
         Widget_Stores.Request_Destroy
           ((Index => Widget_Stores.Slot_Index (W.Store_Index),
             Gen   => Widget_Stores.Generation (W.Store_Gen)));
      end if;
   end Destroy_Subtree;

   procedure Register_Widget (Obj : not null Widget_Access) is
      Id : constant Widget_Stores.Object_Id := Widget_Stores.Register (Obj);
   begin
      Obj.Store_Index := Natural (Id.Index);
      Obj.Store_Gen   := Natural (Id.Gen);
   end Register_Widget;

   procedure Pump_Widget_Store is
   begin
      Widget_Stores.Pump;
   end Pump_Widget_Store;

   ---------------------------------------------------------------------------
   --  Generic handle-wrapper templates
   --
   --  These eliminate the boilerplate Resolve_Handle + null-check + delegate
   --  pattern.  Each instantiation + rename serves as the body completion for
   --  the corresponding Widget_Handle overload declared in the spec.
   ---------------------------------------------------------------------------

   --  Class-wide procedure, 0 extra args
   generic
      with procedure Op (W : in out Widget'Class);
   procedure Wrap_CW_Proc (H : Widget_Handle);
   procedure Wrap_CW_Proc (H : Widget_Handle) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then Op (Ptr.all); end if;
   end Wrap_CW_Proc;

   --  Dispatching procedure, 0 extra args
   generic
      with procedure Op (W : in out Widget) is abstract;
   procedure Wrap_Prim_Proc (H : Widget_Handle);
   procedure Wrap_Prim_Proc (H : Widget_Handle) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then Op (Ptr.all); end if;
   end Wrap_Prim_Proc;

   --  Class-wide function, 0 extra args
   generic
      type R is private;
      Default : R;
      with function Op (W : Widget'Class) return R;
   function Wrap_CW_Func (H : Widget_Handle) return R;
   function Wrap_CW_Func (H : Widget_Handle) return R is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then return Op (Ptr.all); end if;
      return Default;
   end Wrap_CW_Func;

   --  Dispatching function, 0 extra args
   generic
      type R is private;
      Default : R;
      with function Op (W : Widget) return R is abstract;
   function Wrap_Prim_Func (H : Widget_Handle) return R;
   function Wrap_Prim_Func (H : Widget_Handle) return R is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then return Op (Ptr.all); end if;
      return Default;
   end Wrap_Prim_Func;

   function Adopt_Widget (W : not null Widget_Access) return Widget_Handle is
   begin
      Set_Flag (W.all, Visible, True);
      Register_Widget (W);
      return Get_Handle (W.all);
   end Adopt_Widget;

   --  Per-frame perf counters for debug stats overlay.
   --  Reset by the Window before each frame, read after rendering.
   Perf_Style_Resolves : Natural := 0;
   Perf_Style_Hits     : Natural := 0;
   Perf_Layout_Calls   : Natural := 0;
   Perf_Layout_Skips   : Natural := 0;
   Perf_Pref_Calls     : Natural := 0;
   Perf_Pref_Hits      : Natural := 0;

   --  Saturating increment for perf counters: caps at Natural'Last
   --  instead of raising CONSTRAINT_ERROR on long-idle frames.
   procedure Inc_Sat (Counter : in out Natural) with Inline;
   procedure Inc_Sat (Counter : in out Natural) is
   begin
      if Counter < Natural'Last then
         Counter := Counter + 1;
      end if;
   end Inc_Sat;

   subtype Packed_State_Bits is Interfaces.Unsigned_16;
   use type Packed_State_Bits;

   type Ordered_Rule_Index_Array is
     array (Positive range 1 .. Max_Style_Rules) of Positive;

   type Prepared_Style_Entry is record
      Style : Widget_Style := Empty_Widget_Style;
      Ordered_Rules : Ordered_Rule_Index_Array := [others => 1];
      Ordered_Count : Natural := 0;
   end record;

   function Prepare_Style (S : Widget_Style) return Prepared_Style_Entry;
   function Intern_Style (S : Widget_Style) return Style_Handle;
   function Entry_From_Handle (H : Style_Handle)
     return access constant Prepared_Style_Entry;
   function Style_From_Handle (H : Style_Handle)
     return access constant Widget_Style;
   function Compute_Style_Prepared
     (Prepared      : Prepared_Style_Entry;
      Active_Widget : Widget_States;
      Active_Part   : Widget_States) return Style_Rules;
   function Pack_States (S : Widget_States) return Packed_State_Bits;

   type Prepared_Style_Entry_Access is access constant Prepared_Style_Entry;
   package Style_Entry_Ptr_Vectors is new Ada.Containers.Vectors
     (Positive, Prepared_Style_Entry_Access);

   type Resolved_Cache_Key is record
      Part_Handle        : Style_Handle := 0;
      Main_Handle        : Style_Handle := 0;
      Widget_States      : Packed_State_Bits := 0;
      Part_States        : Packed_State_Bits := 0;
      Main_Part_States   : Packed_State_Bits := 0;
   end record;

   function Hash_Resolved_Cache_Key
     (K : Resolved_Cache_Key) return Hash_Type;

   package Resolved_Cache_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Resolved_Cache_Key,
      Element_Type    => Resolved_Style,
      Hash            => Hash_Resolved_Cache_Key,
      Equivalent_Keys => "=");

   Style_Store : Style_Entry_Ptr_Vectors.Vector;
   Max_Global_Resolved_Entries : constant Count_Type := 32_768;
   Global_Resolved_Cache : Resolved_Cache_Maps.Map;

   function Prepare_Style (S : Widget_Style) return Prepared_Style_Entry is
      Result : Prepared_Style_Entry := (Style => S, others => <>);
      Priorities : array (Positive range 1 .. Max_Style_Rules) of Natural := [others => 0];
   begin
      Result.Ordered_Count := S.Rule_Count;

      --  Precompute a stable rule order: priority asc, source order asc.
      for I in 1 .. S.Rule_Count loop
         Result.Ordered_Rules (I) := I;
         Priorities (I) :=
           (if S.Rules (I).Priority > 0
            then S.Rules (I).Priority
            else Specificity (S.Rules (I).Selector));
      end loop;

      if S.Rule_Count > 1 then
         for I in 2 .. S.Rule_Count loop
            declare
               Key_Index : constant Positive := Result.Ordered_Rules (I);
               Key_Prio  : constant Natural := Priorities (I);
               J         : Natural := I;
            begin
               while J > 1 loop
                  declare
                     Prev_Index : constant Positive := Result.Ordered_Rules (J - 1);
                     Prev_Prio  : constant Natural := Priorities (J - 1);
                  begin
                     exit when Prev_Prio < Key_Prio
                       or else (Prev_Prio = Key_Prio and then Prev_Index < Key_Index);

                     Result.Ordered_Rules (J) := Prev_Index;
                     Priorities (J) := Prev_Prio;
                     J := J - 1;
                  end;
               end loop;

               Result.Ordered_Rules (J) := Key_Index;
               Priorities (J) := Key_Prio;
            end;
         end loop;
      end if;

      return Result;
   end Prepare_Style;

   Empty_Prepared_Style : aliased constant Prepared_Style_Entry :=
     Prepare_Style (Empty_Widget_Style);

   function Entry_From_Handle (H : Style_Handle)
     return access constant Prepared_Style_Entry
   is
   begin
      if H = 0 then
         return Empty_Prepared_Style'Access;
      end if;
      return Style_Store.Element (Positive (H));
   end Entry_From_Handle;

   function Style_From_Handle (H : Style_Handle)
     return access constant Widget_Style
   is
      Prepared : constant access constant Prepared_Style_Entry := Entry_From_Handle (H);
   begin
      return Prepared.Style'Unrestricted_Access;
   end Style_From_Handle;

   function Intern_Style (S : Widget_Style) return Style_Handle is
   begin
      if S = Empty_Widget_Style then
         return 0;
      end if;

      for I in 1 .. Natural (Style_Store.Length) loop
         if Style_Store.Element (I).Style = S then
            return Style_Handle (I);
         end if;
      end loop;

      Style_Store.Append (new Prepared_Style_Entry'(Prepare_Style (S)));
      return Style_Handle (Style_Store.Length);
   end Intern_Style;

   function Compute_Style_Prepared
     (Prepared      : Prepared_Style_Entry;
      Active_Widget : Widget_States;
      Active_Part   : Widget_States) return Style_Rules
   is
      Result : Style_Rules := Prepared.Style.Base;
   begin
      for I in 1 .. Prepared.Ordered_Count loop
         declare
            Rule_Index : constant Positive := Prepared.Ordered_Rules (I);
         begin
            if Matches (Prepared.Style.Rules (Rule_Index).Selector,
                        Active_Widget,
                        Active_Part)
            then
               Result := Merge (Result, Prepared.Style.Rules (Rule_Index).Style);
            end if;
         end;
      end loop;
      return Result;
   end Compute_Style_Prepared;

   function Pack_States (S : Widget_States) return Packed_State_Bits is
      Result : Packed_State_Bits := 0;
   begin
      for State in Widget_State loop
         if S (State) then
            Result := Result
              or Interfaces.Shift_Left
                (Packed_State_Bits (1), Widget_State'Pos (State));
         end if;
      end loop;
      return Result;
   end Pack_States;

   function Hash_Resolved_Cache_Key
     (K : Resolved_Cache_Key) return Hash_Type
   is
      H : Hash_Type :=
        Hash_Type (Natural (K.Part_Handle) * 16#9E37# + Natural (K.Main_Handle));
   begin
      H := H xor Hash_Type (K.Widget_States);
      H := H xor Hash_Type (Interfaces.Shift_Left (K.Part_States, 4));
      H := H xor Hash_Type (Interfaces.Shift_Left (K.Main_Part_States, 8));
      return H;
   end Hash_Resolved_Cache_Key;

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
   function Normalize_Visibility (V : Visibility_Value) return Visibility_Value;
   function Main_Visibility_Explicit (W : Widget'Class) return Boolean;
   function Resolve_Effective_Visibility
     (W : Widget'Class;
      Parent_Effective : Visibility_Value) return Visibility_Value;
   function Widget_Participates (W : Widget'Class) return Boolean;
   function Item_Is_Rendered (Style : Resolved_Style) return Boolean;

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
         (if Has_Visible_Area (Geom) then
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

   function Effective_Part_Handle
     (W : Widget'Class;
      P : Part_Kind) return Style_Handle
   is
   begin
      if W.Part_Style_Handles (P) = 0
        and then P /= Any_Part
        and then W.Part_Style_Handles (Any_Part) /= 0
      then
         return W.Part_Style_Handles (Any_Part);
      end if;
      return W.Part_Style_Handles (P);
   end Effective_Part_Handle;

   function Effective_Part_Style
     (W : Widget'Class;
      P : Part_Kind) return Widget_Style
   is
      H : constant Style_Handle := Effective_Part_Handle (W, P);
   begin
      return Style_From_Handle (H).all;
   end Effective_Part_Style;

   function Widget_State_Affects_Resolved_Styles
     (W          : Widget'Class;
      Old_States : Widget_States) return Boolean
   is
      Changed : Widget_State;
      Found   : Boolean := False;
      Eff_States : constant Widget_States := Get_States (W);
   begin
      --  Identify which state changed
      for S in Widget_State loop
         if Old_States (S) /= W.States (S) then
            Changed := S;
            Found := True;
            exit;
         end if;
      end loop;
      if not Found then
         return False;
      end if;

      --  Only check parts whose rules reference the changed state
      for P in Part_Kind loop
         if W.Part_Style_Enabled (P) then
            declare
               H : constant Style_Handle := Effective_Part_Handle (W, P);
               Prepared : constant access constant Prepared_Style_Entry :=
                 Entry_From_Handle (H);
            begin
               if H /= 0 and then Uses_Widget_State (Prepared.Style, Changed)
               then
                  declare
                     Old_Resolved : constant Resolved_Style :=
                       Resolve
                         (Compute_Style_Prepared
                            (Prepared.all, Old_States, W.Part_States (P)));
                     New_Resolved : constant Resolved_Style :=
                       Resolve
                         (Compute_Style_Prepared
                            (Prepared.all, Eff_States, W.Part_States (P)));
                  begin
                     if Old_Resolved /= New_Resolved then
                        return True;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Widget_State_Affects_Resolved_Styles;

   function Part_State_Affects_Resolved_Styles
     (W          : Widget'Class;
      Changed    : Part_Kind;
      Old_States : Widget_States) return Boolean
   is
      Changed_State : Widget_State;
      Found         : Boolean := False;
      Eff_States    : constant Widget_States := Get_States (W);
   begin
      --  Identify which part state changed
      for S in Widget_State loop
         if Old_States (S) /= W.Part_States (Changed) (S) then
            Changed_State := S;
            Found := True;
            exit;
         end if;
      end loop;
      if not Found then
         return False;
      end if;

      --  Only the changed part can be affected, and only if rules use this state
      for P in Part_Kind loop
         if P = Changed and then W.Part_Style_Enabled (P) then
            declare
               H : constant Style_Handle := Effective_Part_Handle (W, P);
               Prepared : constant access constant Prepared_Style_Entry :=
                 Entry_From_Handle (H);
            begin
               if H /= 0 and then Uses_Part_State (Prepared.Style, Changed_State)
               then
                  declare
                     Old_Resolved : constant Resolved_Style :=
                       Resolve
                         (Compute_Style_Prepared
                            (Prepared.all, Eff_States, Old_States));
                     New_Resolved : constant Resolved_Style :=
                       Resolve
                         (Compute_Style_Prepared
                            (Prepared.all, Eff_States, W.Part_States (P)));
                  begin
                     if Old_Resolved /= New_Resolved then
                        return True;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Part_State_Affects_Resolved_Styles;

   procedure Bump_Style_Version (W : in out Widget'Class) is
   begin
      if W.Style_Version = Natural'Last then
         W.Style_Version := 0;
         W.Last_Applied_Version := Natural'Last;
      else
         W.Style_Version := W.Style_Version + 1;
      end if;
   end Bump_Style_Version;

   procedure Bump_Content_Version (W : in out Widget'Class) is
   begin
      if W.Content_Version = Natural'Last then
         W.Content_Version := 1;
      else
         W.Content_Version := W.Content_Version + 1;
      end if;
   end Bump_Content_Version;

   procedure Set_State (W : in out Widget'Class;
                        S : Widget_State;
                        Active : Boolean) is
      Was_Active : constant Boolean := W.States (S);
      Old_States : Widget_States;
   begin
      if Was_Active /= Active then
         Old_States := W.States;
         W.States (S) := Active;
         Bump_Style_Version (W);
         On_State_Changed (W, S, Active);
         if Widget_State_Affects_Resolved_Styles (W, Old_States) then
            Mark_Render_Dirty (W);
         end if;
      end if;
   end Set_State;

   function Has_State (W : Widget'Class; S : Widget_State) return Boolean is
   begin
      return W.States (S);
   end Has_State;

   function Get_States (W : Widget'Class) return Widget_States is
      Result : Widget_States := W.States;
   begin
      if not Result (State_Disabled) and then Is_Disabled (W) then
         Result (State_Disabled) := True;
      end if;
      return Result;
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
         Bump_Style_Version (W);
         if Part_State_Affects_Resolved_Styles (W, P, Old_States) then
            Mark_Render_Dirty (W);
         end if;
      end if;
   end Set_Part_State;

   procedure Set_Part_State (H : Widget_Handle;
                             P : Part_Kind;
                             S : Widget_State;
                             Active : Boolean) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Set_Part_State (Ptr.all, P, S, Active);
      end if;
   end Set_Part_State;

   function Get_Part_States (W : Widget'Class; P : Part_Kind) return Widget_States is
   begin
      return W.Part_States (P);
   end Get_Part_States;

   procedure Clear_States (W : in out Widget'Class) is
   begin
      W.States := No_States;
      Bump_Style_Version (W);
      Mark_Render_Dirty (W);
   end Clear_States;

   procedure Clear_Part_States (W : in out Widget'Class) is
   begin
      W.Part_States := [others => No_States];
      Bump_Style_Version (W);
      Mark_Render_Dirty (W);
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
      procedure Mark_Children_Dirty (Parent : in out Widget'Class) is
      begin
         for Child of Parent.Children loop
            Bump_Style_Version (Child.all);
            Mark_Dirty (Child.all);
            Mark_Children_Dirty (Child.all);
         end loop;
      end Mark_Children_Dirty;
   begin
      Set_State (W, State_Disabled, Value);
      Mark_Children_Dirty (W);
   end Set_Disabled;

   function Is_Disabled (W : Widget'Class) return Boolean is
      P : access constant Widget'Class := W'Access;
   begin
      while P /= null loop
         if P.States (State_Disabled) then
            return True;
         end if;
         P := P.Parent;
      end loop;
      return False;
   end Is_Disabled;

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
      W.Part_Style_Handles (P) := Intern_Style (S);
      W.Part_Style_Enabled (P) := True;
      Bump_Style_Version (W);
      Mark_Dirty (W);
   end Set_Part_Style;

   procedure Set_Part_Styles (W : in out Widget'Class;
                              Styles : Part_Style_Array) is
   begin
      for P in Part_Kind loop
         W.Part_Style_Handles (P) := Intern_Style (Styles (P).Style);
         W.Part_Style_Enabled (P) := Styles (P).Enabled;
      end loop;
      Bump_Style_Version (W);
      Mark_Dirty (W);
   end Set_Part_Styles;

   procedure Set_Part_Style (H : Widget_Handle;
                             P : Part_Kind;
                             S : Widget_Style) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Part_Style (Ptr.all, P, S);
      end if;
   end Set_Part_Style;

   procedure Set_Part_Styles (H : Widget_Handle;
                              Styles : Part_Style_Array) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Part_Styles (Ptr.all, Styles);
      end if;
   end Set_Part_Styles;

   ---------------------------------------------------------------------------
   --  Common Widget_Handle base overloads
   ---------------------------------------------------------------------------

   procedure Set_Visible (H : Widget_Handle; Value : Boolean) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Flag (Ptr.all, Visible, Value);
      end if;
   end Set_Visible;

   function Is_Visible (H : Widget_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Has_Flag (Ptr.all, Visible);
      end if;
      return False;
   end Is_Visible;

   procedure Set_Disabled (H : Widget_Handle; Value : Boolean := True) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Disabled (Ptr.all, Value);
      end if;
   end Set_Disabled;

   function Is_Disabled (H : Widget_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Disabled (Ptr.all);
      end if;
      return False;
   end Is_Disabled;

   procedure Set_Focusable (H : Widget_Handle; Value : Boolean) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Flag (Ptr.all, Focusable, Value);
      end if;
   end Set_Focusable;

   procedure Set_Label (H : Widget_Handle; Label : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Label (Ptr.all, Label);
      end if;
   end Set_Label;

   function Get_Label (H : Widget_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Label (Ptr.all);
      end if;
      return "";
   end Get_Label;

   procedure Mark_Dirty_W is new Wrap_CW_Proc (Mark_Dirty);
   procedure Mark_Dirty (H : Widget_Handle) renames Mark_Dirty_W;

   function Get_Id (H : Widget_Handle) return Natural is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Get_Id (Ptr.all);
      end if;
      return 0;
   end Get_Id;

   procedure Set_State (H : Widget_Handle;
                         S : Widget_State;
                         Active : Boolean) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Set_State (Ptr.all, S, Active);
      end if;
   end Set_State;

   function Has_State (H : Widget_Handle;
                       S : Widget_State) return Boolean is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Has_State (Ptr.all, S);
      end if;
      return False;
   end Has_State;

   function Get_States (H : Widget_Handle) return Widget_States is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Get_States (Ptr.all);
      end if;
      return [others => False];
   end Get_States;

   procedure Set_Hovered (H : Widget_Handle;
                           Value : Boolean := True) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Set_Hovered (Ptr.all, Value);
      end if;
   end Set_Hovered;

   procedure Set_Pressed (H : Widget_Handle;
                           Value : Boolean := True) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Set_Pressed (Ptr.all, Value);
      end if;
   end Set_Pressed;

   procedure Set_Focused (H : Widget_Handle;
                           Value : Boolean := True) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Set_Focused (Ptr.all, Value);
      end if;
   end Set_Focused;

   procedure Set_Selected (H : Widget_Handle;
                            Value : Boolean := True) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Set_Selected (Ptr.all, Value);
      end if;
   end Set_Selected;

   function Get_Part_Style (W : Widget'Class;
                            P : Part_Kind) return Widget_Style is
   begin
      return Style_From_Handle (W.Part_Style_Handles (P)).all;
   end Get_Part_Style;

   function Get_Part_Style (H : Widget_Handle;
                            P : Part_Kind) return Widget_Style is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Part_Style (Ptr.all, P);
      end if;
      return Empty_Widget_Style;
   end Get_Part_Style;

   function Get_Part_Style_Rules (W : Widget'Class;
                                  P : Part_Kind) return Style_Rules is
      H : constant Style_Handle := Effective_Part_Handle (W, P);
      Prepared : constant access constant Prepared_Style_Entry :=
        Entry_From_Handle (H);
   begin
      return Compute_Style_Prepared
        (Prepared.all,
         Get_States (W),
         W.Part_States (P));
   end Get_Part_Style_Rules;

   function Get_Resolved_Part_Style (W : Widget'Class;
                                     P : Part_Kind) return Resolved_Style is
      --  NOTE: This function is nominally read-only (in-mode Widget'Class),
      --  but we cache the resolved result in the Widget record to avoid
      --  recomputing Compute_Style + Resolve (~60 fields each) on every
      --  call.  The cache is keyed on (Style_Version, effective states,
      --  Part_States) so staleness is impossible.  'Unrestricted_Access is
      --  safe here because the cache is a pure memo — same inputs always
      --  produce the same output.
      W_Mut : constant access Widget'Class := W'Unrestricted_Access;
      Eff   : constant Widget_States := Get_States (W);
      Part_Handle : constant Style_Handle := Effective_Part_Handle (W, P);
      Main_Handle : constant Style_Handle := Effective_Part_Handle (W, Main_Part);
      Key : constant Resolved_Cache_Key := (
        Part_Handle      => Part_Handle,
        Main_Handle      => Main_Handle,
        Widget_States    => Pack_States (Eff),
        Part_States      => Pack_States (W.Part_States (P)),
        Main_Part_States => Pack_States (W.Part_States (Main_Part)));
      Result : Resolved_Style;
   begin
      Inc_Sat (Perf_Style_Resolves);

      --  When the widget-level key (version or effective states) changes,
      --  ALL per-part entries are stale — invalidate them.  This prevents
      --  a subtle bug where resolving Main_Part after a state change
      --  updates the shared key, making a subsequent Label_Part lookup
      --  appear cached even though Label_Part inherits from Main_Part
      --  and should also change.
      if W_Mut.Cached_Style_Version /= W.Style_Version
        or else W_Mut.Cached_Eff_States /= Eff
      then
         W_Mut.Cached_Resolved_Init := [others => False];
         W_Mut.Cached_Style_Version := W.Style_Version;
         W_Mut.Cached_Eff_States := Eff;
      end if;

      --  Cache hit?  (per-part key: init flag + part states)
      if W_Mut.Cached_Resolved_Init (P)
        and then W_Mut.Cached_Part_States (P) = W.Part_States (P)
      then
         Inc_Sat (Perf_Style_Hits);
         return W_Mut.Cached_Resolved (P);
      end if;

      --  Cache miss: probe global memo before computing.
      declare
         Cur : constant Resolved_Cache_Maps.Cursor :=
           Global_Resolved_Cache.Find (Key);
      begin
         if Resolved_Cache_Maps.Has_Element (Cur) then
            Result := Resolved_Cache_Maps.Element (Cur);
         else
            declare
               Part_Entry : constant access constant Prepared_Style_Entry :=
                 Entry_From_Handle (Part_Handle);
               Part_Rules : Style_Rules :=
                 Compute_Style_Prepared
                   (Part_Entry.all, Eff, W.Part_States (P));
            begin
               --  Sub-parts inherit text/typography properties from Main_Part.
               --  Explicit ::part rules override inherited values.
               if P /= Main_Part and then P /= Any_Part then
                  declare
                     Main_Entry : constant access constant Prepared_Style_Entry :=
                       Entry_From_Handle (Main_Handle);
                     Main_Rules : constant Style_Rules :=
                       Compute_Style_Prepared
                         (Main_Entry.all, Eff, W.Part_States (Main_Part));
                  begin
                     Part_Rules := Inherit_From (Main_Rules, Part_Rules);
                  end;
               end if;

               Result := Resolve (Part_Rules);
            end;

            if Global_Resolved_Cache.Length >= Max_Global_Resolved_Entries then
               Global_Resolved_Cache.Clear;
            end if;
            Global_Resolved_Cache.Insert (Key, Result);
         end if;
      end;

      W_Mut.Cached_Resolved (P) := Result;
      W_Mut.Cached_Resolved_Init (P) := True;
      W_Mut.Cached_Part_States (P) := W.Part_States (P);
      return Result;
   end Get_Resolved_Part_Style;

   function Get_Part_Style_Rules (H : Widget_Handle;
                                  P : Part_Kind) return Style_Rules is
      Ptr : constant Widget_Access := Resolve_Handle (H);
      Default : Style_Rules;
   begin
      if Ptr /= null then
         return Get_Part_Style_Rules (Ptr.all, P);
      end if;
      return Default;
   end Get_Part_Style_Rules;

   function Get_Resolved_Part_Style (H : Widget_Handle;
                                     P : Part_Kind) return Resolved_Style is
      Ptr : constant Widget_Access := Resolve_Handle (H);
      Default_Rules : Style_Rules;
   begin
      if Ptr /= null then
         return Get_Resolved_Part_Style (Ptr.all, P);
      end if;
      return Resolve (Default_Rules);
   end Get_Resolved_Part_Style;

   ---------------------------------------------------------------------------
   --  Item Management
   ---------------------------------------------------------------------------

   procedure Add_Item (W : in out Widget'Class; I : Item) is
      New_Item : Item := I;
   begin
      if New_Item.Has_Style_Override then
         New_Item.Computed_Style := New_Item.Style_Override;
      else
         New_Item.Computed_Style := Get_Resolved_Part_Style (W, I.Part);
      end if;
      W.Items.Append (New_Item);
      Mark_Render_Dirty (W);
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
      W.Label_Item_Base := 0;
      Mark_Render_Dirty (W);
   end Clear_Items;

   ---------------------------------------------------------------------------
   --  Label Management
   ---------------------------------------------------------------------------

   procedure Set_Label (W : in out Widget'Class; Label : String) is
   begin
      W.Label_Text := To_Unbounded_String (Label);
      Mark_Dirty (W);
   end Set_Label;

   function Get_Label (W : Widget'Class) return String is
   begin
      return To_String (W.Label_Text);
   end Get_Label;

   procedure Build_Label_Overlay (W : in out Widget'Class) is
      Lbl_Text : constant String := To_String (W.Label_Text);
   begin
      --  No label text and no items allocated: nothing to do
      if Lbl_Text'Length = 0 and then W.Label_Item_Base = 0 then
         return;
      end if;

      --  Guard against stale index: if items were removed without going
      --  through Clear_Items (e.g. Html_View's Delete_Last loop), the
      --  saved base may point past the end of the vector.  Reset so
      --  the items are re-created on the next frame that needs them.
      if W.Label_Item_Base > 0
        and then W.Label_Item_Base + 1 > Item_Count (W)
      then
         W.Label_Item_Base := 0;
      end if;

      --  Label cleared and stale index was just reset: nothing left to do
      if Lbl_Text'Length = 0 and then W.Label_Item_Base = 0 then
         return;
      end if;

      --  Allocate label items on first use
      if Lbl_Text'Length > 0 and then W.Label_Item_Base = 0 then
         Add_Item (W, Make_Panel (Label_Part, (0.0, 0.0, 0.0, 0.0), 100));
         Add_Item (W, Make_Text (Label_Part, (0.0, 0.0, 0.0, 0.0), "", 101));
         W.Label_Item_Base := Item_Count (W) - 1;
      end if;

      declare
         Bg_Idx  : constant Positive := W.Label_Item_Base;
         Txt_Idx : constant Positive := W.Label_Item_Base + 1;
         Lbl_Bg  : Item renames W.Items.Reference (Bg_Idx).Element.all;
         Lbl     : Item renames W.Items.Reference (Txt_Idx).Element.all;
      begin
         if Lbl_Text'Length > 0 then
            declare
               Lbl_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Label_Part);
               Lbl_Attrs : constant Adi.Font.Font_Attributes :=
                 Adi.Font.Make_Attributes
                   (Family     => Lbl_Style.Font_Family,
                    Size       => Float (Length_To_Px (Lbl_Style.Font_Size)),
                    Weight     => Lbl_Style.Font_Weight,
                    Style      => Lbl_Style.Font_Style,
                    Decoration => Lbl_Style.Text_Decoration);
               Lbl_Size : constant Size_2D :=
                 Adi.Font.Measure_Text (Attrs => Lbl_Attrs, Content => Lbl_Text);
               Pad      : constant Edge_Pixels := Get_Padding_Px (Lbl_Style);
               Offset_X : constant Pixel_Type :=
                 Inset_To_Px (Lbl_Style.Left, W.Geometry.Width);
               Offset_Y : constant Pixel_Type :=
                 Inset_To_Px (Lbl_Style.Top, W.Geometry.Height);
               Label_X  : constant Pixel_Type := W.Geometry.X + Offset_X;
               Label_Y  : constant Pixel_Type := W.Geometry.Y + Offset_Y;
            begin
               Lbl_Bg.Geometry := (X      => Label_X,
                                   Y      => Label_Y,
                                   Width  => Pad.Left + Lbl_Size.Width + Pad.Right,
                                   Height => Pad.Top + Lbl_Size.Height + Pad.Bottom);
               Lbl.Text_Content := To_Unbounded_String (Lbl_Text);
               Lbl.Geometry := (X      => Label_X + Pad.Left,
                                Y      => Label_Y + Pad.Top,
                                Width  => Lbl_Size.Width,
                                Height => Lbl_Size.Height);
            end;
         else
            Lbl_Bg.Geometry  := (0.0, 0.0, 0.0, 0.0);
            Lbl.Text_Content := Null_Unbounded_String;
            Lbl.Geometry     := (0.0, 0.0, 0.0, 0.0);
         end if;
      end;
   end Build_Label_Overlay;

   procedure Update_Item (W : in out Widget'Class;
                          Index : Positive;
                          I : Item) is
      New_Item : Item := I;
   begin
      if Index <= Positive (W.Items.Length) then
         if New_Item.Has_Style_Override then
            New_Item.Computed_Style := New_Item.Style_Override;
         else
            New_Item.Computed_Style := Get_Resolved_Part_Style (W, I.Part);
         end if;
         W.Items.Replace_Element (Index, New_Item);
         Mark_Render_Dirty (W);
      end if;
   end Update_Item;

   function Item_Count (W : Widget'Class) return Natural is
   begin
      return Natural (W.Items.Length);
   end Item_Count;

   function Item_Count_W is
     new Wrap_CW_Func (Natural, 0, Item_Count);
   function Item_Count (H : Widget_Handle) return Natural
     renames Item_Count_W;

   function Get_Item (W : Widget'Class; Index : Positive) return Item is
   begin
      return W.Items.Element (Index);
   end Get_Item;

   function Get_Item (H : Widget_Handle; Index : Positive) return Item is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Get_Item (Ptr.all, Index);
      end if;
      raise Constraint_Error with "invalid widget handle";
   end Get_Item;

   procedure Apply_Styles_To_Items (W : in out Widget'Class) is
      Parts_Seen : array (Part_Kind) of Boolean := [others => False];
   begin
      --  Skip if styles haven't changed since last apply and no animations
      if W.Style_Version = W.Last_Applied_Version
         and then W.Last_Target_Init (Main_Part)
         and then not W.Has_Any_Animation
      then
         return;
      end if;
      W.Last_Applied_Version := W.Style_Version;

      --  First pass: for each part encountered, check if target changed.
      --  Use a direct reference rename instead of Element/Replace_Element to
      --  avoid copying Cached_TTF_Text through Ada controlled-type assignment.
      for I in 1 .. Natural (W.Items.Length) loop
         declare
            It : Item renames W.Items.Reference (I).Element.all;
            P  : constant Part_Kind := It.Part;
         begin
            if It.Has_Style_Override then
               It.Computed_Style := It.Style_Override;
            else
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
                     It.Computed_Style := Interpolated;
                  end;
               else
                  It.Computed_Style := W.Last_Target (P);
               end if;
            end if;
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

   function Get_Items_For_Part (H : Widget_Handle;
                                P : Part_Kind) return Items_List.Vector is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Get_Items_For_Part (Ptr.all, P);
      end if;
      return Items_List.Empty_Vector;
   end Get_Items_For_Part;

   function Get_Part_At (W : Widget'Class;
                         X, Y : Pixel_Type) return Part_Kind is
   begin
      if W.Scroll_Show_Bar then
         declare
            Scroll_Style : constant Resolved_Style :=
              Get_Resolved_Part_Style (W, Scroll_Part);
            Knob_Style   : constant Resolved_Style :=
              Get_Resolved_Part_Style (W, Knob_Part);
         begin
            if Item_Is_Rendered (Knob_Style)
              and then Point_In_Rect (W.Scroll_Knob_Geom, X, Y)
            then
               return Knob_Part;
            elsif Item_Is_Rendered (Scroll_Style)
              and then Point_In_Rect (W.Scroll_Track_Geom, X, Y)
            then
               return Scroll_Part;
            end if;
         end;
      end if;

      for I in reverse 1 .. Natural (W.Items.Length) loop
         declare
            Current : constant Item := W.Items.Element (I);
            G       : constant Rectangle := Current.Geometry;
            Style   : Resolved_Style renames Current.Computed_Style;
         begin
            if not Item_Is_Rendered (Style) then
               null;
            elsif X >= G.X and then X <= G.X + G.Width
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
         Mark_Dirty (C.all);
         Mark_Dirty (W);
      end if;
   end Add_Child;

   procedure Add_Child (W : in out Widget'Class; C : Widget_Handle) is
   begin
      declare
         R : Widget_Ref := Borrow (C);
      begin
         Add_Child (W, R.Ptr);
      end;
   exception
      when Constraint_Error =>
         null;
   end Add_Child;

   procedure Add_Child (Parent : Widget_Handle; Child : Widget_Handle) is
   begin
      declare
         P_Ref : Widget_Ref := Borrow (Parent);
      begin
         Add_Child (P_Ref.Ptr.all, Child);
      end;
   exception
      when Constraint_Error =>
         null;
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
         Mark_Dirty (C.all);
         Mark_Dirty (W);
      end if;
   end Remove_Child;

   procedure Remove_Child (Parent : Widget_Handle; Child : Widget_Handle) is
   begin
      declare
         P_Ref : Widget_Ref := Borrow (Parent);
         C_Ref : Widget_Ref := Borrow (Child);
      begin
         Remove_Child (P_Ref.Ptr.all, C_Ref.Ptr);
      end;
   exception
      when Constraint_Error =>
         null;
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

   procedure Set_Parent (W : Widget_Handle; P : Widget_Handle) is
   begin
      declare
         W_Ref : Widget_Ref := Borrow (W);
      begin
         if P = Null_Handle then
            Set_Parent (W_Ref.Ptr.all, null);
         else
            declare
               P_Ref : Widget_Ref := Borrow (P);
            begin
               Set_Parent (W_Ref.Ptr.all, P_Ref.Ptr);
            end;
         end if;
      end;
   exception
      when Constraint_Error =>
         null;
   end Set_Parent;

   function Get_Parent (W : Widget'Class) return access Widget'Class is
   begin
      return W.Parent;
   end Get_Parent;

   function Get_Parent_Handle (W : Widget'Class) return Widget_Handle is
   begin
      if W.Parent = null then
         return Null_Handle;
      end if;
      return Get_Handle (W.Parent.all);
   end Get_Parent_Handle;

   function Get_Parent_Handle (H : Widget_Handle) return Widget_Handle is
   begin
      declare
         R : Widget_Ref := Borrow (H);
      begin
         return Get_Parent_Handle (R.Ptr.all);
      end;
   exception
      when Constraint_Error =>
         return Null_Handle;
   end Get_Parent_Handle;

   function Child_Count (W : Widget'Class) return Natural is
   begin
      return Natural (W.Children.Length);
   end Child_Count;

   function Child_Count (H : Widget_Handle) return Natural is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Child_Count (Ptr.all);
      end if;
      return 0;
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

   function Get_Child_Handle (W : Widget'Class; Index : Positive)
      return Widget_Handle
   is
      Child : constant Widget_Access := Get_Child (W, Index);
   begin
      if Child = null then
         return Null_Handle;
      end if;
      return Get_Handle (Child.all);
   end Get_Child_Handle;

   function Get_Child_Handle (H : Widget_Handle; Index : Positive)
      return Widget_Handle
   is
   begin
      declare
         R : Widget_Ref := Borrow (H);
      begin
         return Get_Child_Handle (R.Ptr.all, Index);
      end;
   exception
      when Constraint_Error =>
         return Null_Handle;
   end Get_Child_Handle;
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

   procedure Set_Geometry (H : Widget_Handle; G : Rectangle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Geometry (Ptr.all, G);
      end if;
   end Set_Geometry;

   function Get_Geometry (W : Widget'Class) return Rectangle is
   begin
      return W.Geometry;
   end Get_Geometry;

   function Get_Geometry (H : Widget_Handle) return Rectangle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Geometry (Ptr.all);
      end if;
      return (0.0, 0.0, 0.0, 0.0);
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

   function Overflow_Is_Scrollable (V : Overflow_Value) return Boolean is
   begin
      return V in Overflow_Scroll | Overflow_Auto;
   end Overflow_Is_Scrollable;

   function Overflow_Clips (V : Overflow_Value) return Boolean is
   begin
      return V in Overflow_Hidden | Overflow_Scroll | Overflow_Auto;
   end Overflow_Clips;

   function Normalize_Visibility (V : Visibility_Value) return Visibility_Value is
   begin
      if V = Visibility_Collapse then
         return Visibility_Hidden;
      end if;
      return V;
   end Normalize_Visibility;

   function Main_Visibility_Explicit (W : Widget'Class) return Boolean is
      Rules : constant Style_Rules := Get_Part_Style_Rules (W, Main_Part);
   begin
      return Opt_Visibility.Is_Set (Rules.Visibility);
   end Main_Visibility_Explicit;

   function Resolve_Effective_Visibility
     (W : Widget'Class;
      Parent_Effective : Visibility_Value) return Visibility_Value
   is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      if Main_Visibility_Explicit (W) then
         return Normalize_Visibility (Main_Style.Visibility);
      end if;
      return Parent_Effective;
   end Resolve_Effective_Visibility;

   function Widget_Participates (W : Widget'Class) return Boolean is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      return Has_Flag (W, Visible)
        and then Main_Style.Display /= Display_None;
   end Widget_Participates;

   function Item_Is_Rendered (Style : Resolved_Style) return Boolean is
   begin
      return Style.Display /= Display_None
        and then Normalize_Visibility (Style.Visibility) = Visibility_Visible;
   end Item_Is_Rendered;

   function Main_Axis_Overflow
     (Style     : Resolved_Style;
      Direction : Flex_Direction_Value) return Overflow_Value
   is
   begin
      if Is_Row_Direction (Direction) then
         return Style.Overflow_X;
      else
         return Style.Overflow_Y;
      end if;
   end Main_Axis_Overflow;

   function Build_Content_Clip_Rect
     (Renderer : SDL_Renderer_Ptr;
     Content  : Rectangle;
      Clip_X   : Boolean;
      Clip_Y   : Boolean;
      Had_Clip : Boolean;
      Prev_Clip : Adi.SDL.SDL_Rect;
      Out_Clip : out Adi.SDL.SDL_Rect) return Boolean
   is
      Viewport : aliased Adi.SDL.SDL_Rect;
      Success  : Adi.SDL.C_bool;
      X1, Y1, X2, Y2 : Integer;
      Prev_X1 : Integer := 0;
      Prev_Y1 : Integer := 0;
      Prev_X2 : Integer := 0;
      Prev_Y2 : Integer := 0;
      Fallback_Min : constant Integer := -1_000_000_000;
      Fallback_Max : constant Integer := 1_000_000_000;
   begin
      if not Has_Visible_Area (Content) or else (not Clip_X and then not Clip_Y) then
         return False;
      end if;

      if not Had_Clip then
         Success := SDL_GetRenderViewport (Renderer, Viewport'Access);
         if not Boolean (Success)
           or else Integer (Viewport.w) <= 0
           or else Integer (Viewport.h) <= 0
         then
            Viewport :=
              (x => int (Fallback_Min),
               y => int (Fallback_Min),
               w => int (Fallback_Max - Fallback_Min),
               h => int (Fallback_Max - Fallback_Min));
         end if;
      end if;

      if Had_Clip then
         Prev_X1 := Integer (Prev_Clip.x);
         Prev_Y1 := Integer (Prev_Clip.y);
         Prev_X2 := Integer (Prev_Clip.x) + Integer (Prev_Clip.w);
         Prev_Y2 := Integer (Prev_Clip.y) + Integer (Prev_Clip.h);
      end if;

      X1 :=
        (if Clip_X
         then Integer (Float'Floor (Float (Content.X)))
         elsif Had_Clip
         then Prev_X1
         else Integer (Viewport.x));
      Y1 :=
        (if Clip_Y
         then Integer (Float'Floor (Float (Content.Y)))
         elsif Had_Clip
         then Prev_Y1
         else Integer (Viewport.y));
      X2 :=
        (if Clip_X
         then X1 + Integer (Float'Ceiling (Float (Content.Width)))
         elsif Had_Clip
         then Prev_X2
         else Integer (Viewport.x) + Integer (Viewport.w));
      Y2 :=
        (if Clip_Y
         then Y1 + Integer (Float'Ceiling (Float (Content.Height)))
         elsif Had_Clip
         then Prev_Y2
         else Integer (Viewport.y) + Integer (Viewport.h));

      if Had_Clip then
         X1 := Integer'Max (X1, Prev_X1);
         Y1 := Integer'Max (Y1, Prev_Y1);
         X2 := Integer'Min (X2, Prev_X2);
         Y2 := Integer'Min (Y2, Prev_Y2);
      end if;

      if X2 <= X1 or else Y2 <= Y1 then
         return False;
      end if;

      Out_Clip :=
        (x => int (X1),
         y => int (Y1),
         w => int (X2 - X1),
         h => int (Y2 - Y1));
      return True;
   end Build_Content_Clip_Rect;

   function Get_Content_Box (W : Widget'Class) return Rectangle is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      return Content_Box (W.Geometry, Style);
   end Get_Content_Box;

   function Supports_Scrollbar (W : Widget'Class) return Boolean is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      return Overflow_Is_Scrollable (Style.Overflow_Y);
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
         Update_Scrollbar_Geometry (W);
         Mark_Render_Dirty (W);
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

   function Get_Scroll_Content_Height_W is
     new Wrap_CW_Func (Pixel_Type, 0.0, Get_Scroll_Content_Height);
   function Get_Scroll_Content_Height (H : Widget_Handle) return Pixel_Type
     renames Get_Scroll_Content_Height_W;

   function Get_Scroll_Max_Offset_Y_W is
     new Wrap_CW_Func (Pixel_Type, 0.0, Get_Scroll_Max_Offset_Y);
   function Get_Scroll_Max_Offset_Y (H : Widget_Handle) return Pixel_Type
     renames Get_Scroll_Max_Offset_Y_W;

   procedure Set_Scroll_Offset_Y (H : Widget_Handle; Offset : Pixel_Type) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then Set_Scroll_Offset_Y (Ptr.all, Offset); end if;
   end Set_Scroll_Offset_Y;

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

      if not Is_Scroll_Enabled (W) or else not Has_Visible_Area (Content) then
         return;
      end if;

      if Supports_Scrollbar (W) then
         case Style.Overflow_Y is
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
      if not Is_Visible_Px (Track_H) or else not Is_Visible_Px (Metrics.Width) then
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
   begin
      W.Scroll_Viewport_H := Pixel_Type'Max (0.0, Content.Height);
      if Is_Scroll_Enabled (W) then
         W.Flags (Scrollable) := True;
      end if;
      for Child of W.Children loop
         if Widget_Participates (Child.all) then
            declare
               G : constant Rectangle := Get_Geometry (Child.all);
               Pref : constant Size_2D := Get_Preferred_Size (Child.all);
               Effective_H : constant Pixel_Type := Pixel_Type'Max (G.Height, Pref.Height);
            begin
               Has_Content := True;
               Min_Top := Pixel_Type'Min (Min_Top, G.Y);
               Content_Bottom := Pixel_Type'Max (Content_Bottom, G.Y + Effective_H);
            end;
         end if;
      end loop;

      if Has_Content then
         W.Scroll_Content_H := Pixel_Type'Max (W.Scroll_Viewport_H, Content_Bottom - Min_Top);
      end if;

      Clamp_Scroll_Offset (W);
      Max_Offset := Get_Scroll_Max_Offset_Y (W);
      if Max_Offset <= 0.0 then
         W.Scroll_Dragging := False;
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
      if W.Flags (F) = Value then
         return;
      end if;
      W.Flags (F) := Value;
      if F = Visible then
         Mark_Dirty (W);
      end if;
   end Set_Flag;

   procedure Set_Flag (H : Widget_Handle;
                       F : Widget_Flag;
                       Value : Boolean) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Flag (Ptr.all, F, Value);
      end if;
   end Set_Flag;

   function Has_Flag (W : Widget'Class; F : Widget_Flag) return Boolean is
   begin
      return W.Flags (F);
   end Has_Flag;

   function Has_Flag (H : Widget_Handle;
                      F : Widget_Flag) return Boolean is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Has_Flag (Ptr.all, F);
      end if;
      return False;
   end Has_Flag;

   procedure Connect_Context_Menu
     (W : in out Widget'Class; CB : Context_Menu_Callback)
   is
   begin
      W.Context_Menu_Sig.Connect (CB);
   end Connect_Context_Menu;

   function Connect_Context_Menu
     (W : in out Widget'Class; CB : Context_Menu_Callback)
      return Context_Menu_Signals.Connection_Id
   is
   begin
      return W.Context_Menu_Sig.Connect (CB);
   end Connect_Context_Menu;

   procedure Disconnect_Context_Menu
     (W : in out Widget'Class; Id : Context_Menu_Signals.Connection_Id)
   is
   begin
      W.Context_Menu_Sig.Disconnect (Id);
   end Disconnect_Context_Menu;

   function Has_Context_Menu (W : Widget'Class) return Boolean is
   begin
      return W.Context_Menu_Sig.Subscriber_Count > 0;
   end Has_Context_Menu;

   function Has_Context_Menu_W is
     new Wrap_CW_Func (Boolean, False, Has_Context_Menu);
   function Has_Context_Menu (H : Widget_Handle) return Boolean
     renames Has_Context_Menu_W;

   procedure Connect_Context_Menu
     (H : Widget_Handle; CB : Context_Menu_Callback)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Connect_Context_Menu (Ptr.all, CB);
      end if;
   end Connect_Context_Menu;

   function Show_Context_Menu
     (W    : in out Widget'Class;
      X, Y : Pixel_Type) return Boolean
   is
      H : constant Widget_Handle := Get_Handle (W);
   begin
      if W.Context_Menu_Sig.Subscriber_Count = 0 then
         return False;
      end if;

      declare
         procedure Call (CB : Context_Menu_Callback) is
         begin CB (H, X, Y); end Call;
         procedure Emit is new Context_Menu_Signals.For_Each (Call);
      begin
         Emit (W.Context_Menu_Sig);
      end;
      return True;
   end Show_Context_Menu;

   function Bubble_Context_Menu
     (Start : Widget_Handle;
      X, Y  : Pixel_Type) return Boolean
   is
      Node : Widget_Handle := Start;
   begin
      while Node /= Null_Handle loop
         begin
            declare
               R : Widget_Ref := Borrow (Node);
            begin
               if Show_Context_Menu (R.Ptr.all, X, Y) then
                  return True;
               end if;
               Node := Get_Parent_Handle (R.Ptr.all);
            end;
         exception
            when Constraint_Error =>
               Node := Null_Handle;
         end;
      end loop;

      return False;
   end Bubble_Context_Menu;

   ---------------------------------------------------------------------------
   --  Dirty/Update Tracking
   ---------------------------------------------------------------------------

   procedure Mark_Dirty (W : in out Widget'Class) is
   begin
      W.Dirty := True;
      W.Layout_Dirty := True;
      --  Bump content version so that the preferred-size cache detects
      --  content mutations (Set_Text, Add_Child, etc.) that don't
      --  affect Style_Version.  Propagates upward because a child's
      --  content change affects the parent's Measure_Content result.
      Bump_Content_Version (W);
      if W.Parent /= null then
         Mark_Dirty (W.Parent.all);
      end if;
   end Mark_Dirty;

   procedure Mark_Render_Dirty (W : in out Widget'Class) is
   begin
      W.Dirty := True;
      if W.Parent /= null then
         Mark_Render_Dirty (W.Parent.all);
      end if;
   end Mark_Render_Dirty;

   procedure Mark_Render_Dirty_W is new Wrap_CW_Proc (Mark_Render_Dirty);
   procedure Mark_Render_Dirty (H : Widget_Handle)
     renames Mark_Render_Dirty_W;

   procedure Mark_Clean (W : in out Widget'Class) is
   begin
      W.Dirty := False;
   end Mark_Clean;

   function Is_Dirty (W : Widget'Class) return Boolean is
   begin
      return W.Dirty;
   end Is_Dirty;

   function Is_Layout_Dirty (W : Widget'Class) return Boolean is
   begin
      return W.Layout_Dirty;
   end Is_Layout_Dirty;

   function Is_Dirty_W is new Wrap_CW_Func (Boolean, False, Is_Dirty);
   function Is_Dirty (H : Widget_Handle) return Boolean renames Is_Dirty_W;

   function Is_Layout_Dirty_W is
     new Wrap_CW_Func (Boolean, False, Is_Layout_Dirty);
   function Is_Layout_Dirty (H : Widget_Handle) return Boolean
     renames Is_Layout_Dirty_W;

   ---------------------------------------------------------------------------
   --  Handle Overloads — Dispatching Methods
   ---------------------------------------------------------------------------

   procedure Render_Tree (H : Widget_Handle; Ctx : in out Render_Context) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Render_Tree (Ptr.all, Ctx);
      end if;
   end Render_Tree;

   procedure Update_W is new Wrap_CW_Proc (Update);
   procedure Update (H : Widget_Handle) renames Update_W;

   procedure Tick_Animations (H : Widget_Handle; DT : Duration) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Tick_Animations (Ptr.all, DT);
      end if;
   end Tick_Animations;

   function Get_Part_At (H : Widget_Handle;
                         X, Y : Pixel_Type) return Part_Kind is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Get_Part_At (Ptr.all, X, Y);
      end if;
      return Main_Part;
   end Get_Part_At;

   function Get_Scroll_Offset_Y_W is
     new Wrap_CW_Func (Pixel_Type, 0.0, Get_Scroll_Offset_Y);
   function Get_Scroll_Offset_Y (H : Widget_Handle) return Pixel_Type
     renames Get_Scroll_Offset_Y_W;

   function Handle_Scroll_Mouse_Down
     (H      : Widget_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button) return Boolean
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         return Handle_Scroll_Mouse_Down (Ptr.all, X, Y, Button);
      end if;
      return False;
   end Handle_Scroll_Mouse_Down;

   procedure Handle_Scroll_Mouse_Move
     (H    : Widget_Handle;
      X, Y : Pixel_Type)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Handle_Scroll_Mouse_Move (Ptr.all, X, Y);
      end if;
   end Handle_Scroll_Mouse_Move;

   procedure Handle_Scroll_Mouse_Up
     (H      : Widget_Handle;
      Button : Mouse_Button)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         Handle_Scroll_Mouse_Up (Ptr.all, Button);
      end if;
   end Handle_Scroll_Mouse_Up;

   procedure On_Click_W is new Wrap_Prim_Proc (On_Click);
   procedure On_Click (H : Widget_Handle) renames On_Click_W;

   procedure On_Mouse_Down
     (H      : Widget_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Mouse_Down (Ptr.all, X, Y, Button, Clicks);
      end if;
   end On_Mouse_Down;

   procedure On_Mouse_Move
     (H    : Widget_Handle;
      X, Y : Pixel_Type)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Mouse_Move (Ptr.all, X, Y);
      end if;
   end On_Mouse_Move;

   procedure On_Mouse_Up
     (H      : Widget_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Mouse_Up (Ptr.all, X, Y, Button);
      end if;
   end On_Mouse_Up;

   procedure On_Mouse_Wheel
     (H                : Widget_Handle;
      Delta_X, Delta_Y : Pixel_Type)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Mouse_Wheel (Ptr.all, Delta_X, Delta_Y);
      end if;
   end On_Mouse_Wheel;

   procedure On_Key_Down
     (H        : Widget_Handle;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Key_Down (Ptr.all, Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Down;

   procedure On_Key_Up
     (H        : Widget_Handle;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Key_Up (Ptr.all, Scancode, Key_Mod, Repeat);
      end if;
   end On_Key_Up;

   procedure On_Text_Input (H : Widget_Handle; Text : String) is
      Ptr : constant Widget_Access := Resolve_Handle (H);
   begin
      if Ptr /= null then
         On_Text_Input (Ptr.all, Text);
      end if;
   end On_Text_Input;

   procedure On_Focus_Gained_W is new Wrap_Prim_Proc (On_Focus_Gained);
   procedure On_Focus_Gained (H : Widget_Handle) renames On_Focus_Gained_W;

   procedure On_Focus_Lost_W is new Wrap_Prim_Proc (On_Focus_Lost);
   procedure On_Focus_Lost (H : Widget_Handle) renames On_Focus_Lost_W;

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
      Mark_Render_Dirty (W);
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

      Mark_Render_Dirty (W);
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
         Mark_Render_Dirty (W);
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
      Rn, Gn, Bn : Natural := 0;
      An         : Float := 1.0;
   begin
      Normalize_Color (C, Rn, Gn, Bn, An);
      R := Uint8 (Rn);
      G := Uint8 (Gn);
      B := Uint8 (Bn);
      A := Uint8 (An * 255.0);
   end CSS_Color_To_SDL;

   function CSS_Color_To_SDL_F
     (C : Color_Value; Opacity : Float) return SDL_FColor
   is
      Rn, Gn, Bn : Natural := 0;
      An         : Float   := 1.0;
   begin
      Normalize_Color (C, Rn, Gn, Bn, An);
      return (r => Float (Rn) / 255.0,
              g => Float (Gn) / 255.0,
              b => Float (Bn) / 255.0,
              a => An * Opacity);
   end CSS_Color_To_SDL_F;

   ---------------------------------------------------------------------------
   --  SDL3 Rendering
   ---------------------------------------------------------------------------

   function Is_Visible_FRect (R : SDL_FRect) return Boolean is
   begin
      return Is_Visible_Px (Pixel_Type (R.w))
        and then Is_Visible_Px (Pixel_Type (R.h));
   end Is_Visible_FRect;

   function Half_Min_Dimension_Non_Neg (R : SDL_FRect) return Float is
   begin
      return Float'Max (0.0, Float'Min (R.w, R.h) / 2.0);
   end Half_Min_Dimension_Non_Neg;

   function Clamp_Radius_To_Max (Radius, Max_Dim : Float) return Float is
   begin
      return Float'Min (Float'Max (0.0, Radius), Max_Dim);
   end Clamp_Radius_To_Max;

   function Clamp_Corner_Radii_To_Max
     (Radii   : Corner_Pixels;
      Max_Dim : Float) return Corner_Pixels
   is
   begin
      return
        (Top_Left     => Clamp_Radius_To_Max (Radii.Top_Left, Max_Dim),
         Top_Right    => Clamp_Radius_To_Max (Radii.Top_Right, Max_Dim),
         Bottom_Right => Clamp_Radius_To_Max (Radii.Bottom_Right, Max_Dim),
         Bottom_Left  => Clamp_Radius_To_Max (Radii.Bottom_Left, Max_Dim));
   end Clamp_Corner_Radii_To_Max;

   function Safe_Floor_To_Natural (V : Float) return Natural is
   begin
      return Natural (Float'Floor (Float'Max (0.0, V)));
   end Safe_Floor_To_Natural;

   function Segments_For_Radius (Radius : Float) return Positive is
   begin
      return Positive'Max (8, Safe_Floor_To_Natural (Radius * 0.5) + 1);
   end Segments_For_Radius;

   function Segments_For_Span
     (Base_Seg : Positive;
      Span     : Float) return Positive
   is
      Safe_Span : constant Float := Float'Max (0.0, Span);
   begin
      return Positive'Max
        (2,
         Safe_Floor_To_Natural
           (Float (Base_Seg) * Safe_Span / (Ada.Numerics.Pi / 2.0)) + 1);
   end Segments_For_Span;

   procedure Render_Rounded_Rect
      (Renderer      : SDL_Renderer_Ptr;
       Rect          : SDL_FRect;
       Corner_Radius : Float;
       R, G, B, A    : Uint8;
       Min_Segments  : Natural := 0)
   is
      --  Clamp radius to half the smallest dimension
      Max_Radius : constant Float := Half_Min_Dimension_Non_Neg (Rect);
      Rad : constant Float :=
         Clamp_Radius_To_Max (Corner_Radius, Max_Radius);

      --  Number of segments per corner arc
      Num_Seg : constant Positive :=
         Positive'Max (Segments_For_Radius (Rad),
                       (if Min_Segments > 0 then Min_Segments else 1));

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
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

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
       R, G, B, A : Uint8;
       Min_Segments : Natural := 0)
   is
      --  Clamp each radius to half the smallest dimension
      Max_Dim : constant Float := Half_Min_Dimension_Non_Neg (Rect);
      Clamped_Radii : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Radii, Max_Dim);
      R_TL : constant Float := Clamped_Radii.Top_Left;
      R_TR : constant Float := Clamped_Radii.Top_Right;
      R_BR : constant Float := Clamped_Radii.Bottom_Right;
      R_BL : constant Float := Clamped_Radii.Bottom_Left;

      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));

      --  Segments per corner arc (based on largest radius)
      Num_Seg : constant Positive :=
         Positive'Max (Segments_For_Radius (Max_R),
                       (if Min_Segments > 0 then Min_Segments else 1));

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
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

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
       R, G, B, A     : Uint8;
       Min_Segments   : Natural := 0)
   is
      Max_Dim_O : constant Float := Half_Min_Dimension_Non_Neg (Outer_Rect);
      Clamped_Outer : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Outer_Radii, Max_Dim_O);
      O_TL : constant Float := Clamped_Outer.Top_Left;
      O_TR : constant Float := Clamped_Outer.Top_Right;
      O_BR : constant Float := Clamped_Outer.Bottom_Right;
      O_BL : constant Float := Clamped_Outer.Bottom_Left;

      Max_Dim_I : constant Float := Half_Min_Dimension_Non_Neg (Inner_Rect);
      Clamped_Inner : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Inner_Radii, Max_Dim_I);
      I_TL : constant Float := Clamped_Inner.Top_Left;
      I_TR : constant Float := Clamped_Inner.Top_Right;
      I_BR : constant Float := Clamped_Inner.Bottom_Right;
      I_BL : constant Float := Clamped_Inner.Bottom_Left;

      Max_R : constant Float :=
         Float'Max (Float'Max (O_TL, O_TR), Float'Max (O_BR, O_BL));

      Num_Seg : constant Positive :=
         Positive'Max (Segments_For_Radius (Max_R),
                       (if Min_Segments > 0 then Min_Segments else 1));

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
      if not Is_Visible_FRect (Outer_Rect) then
         return;
      end if;

      if not Is_Visible_FRect (Inner_Rect) then
         Render_Rounded_Rect
           (Renderer     => Renderer,
            Rect         => Outer_Rect,
            Radii        => Outer_Radii,
            R            => R,
            G            => G,
            B            => B,
            A            => A,
            Min_Segments => Min_Segments);
         return;
      end if;

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

   --  Render a 1px anti-aliasing fringe along the edge of a rounded
   --  rectangle.  The fringe is a triangle strip between the shape's outline
   --  (full color/alpha) and a ring offset 1px along normals (same color but
   --  alpha = 0).  When Inward is False (default) the fringe extends outward;
   --  when True it extends inward (for inner border edges).
   procedure Render_AA_Fringe
      (Renderer     : SDL_Renderer_Ptr;
       Rect         : SDL_FRect;
       Radii        : Corner_Pixels;
       R, G, B, A   : Uint8;
       Min_Segments : Natural := 0;
       Inward       : Boolean := False)
   is
      Fringe : constant Float := (if Inward then -1.0 else 1.0);

      Max_Dim : constant Float := Half_Min_Dimension_Non_Neg (Rect);
      Clamped_Radii : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Radii, Max_Dim);
      R_TL : constant Float := Clamped_Radii.Top_Left;
      R_TR : constant Float := Clamped_Radii.Top_Right;
      R_BR : constant Float := Clamped_Radii.Bottom_Right;
      R_BL : constant Float := Clamped_Radii.Bottom_Left;

      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));

      Num_Seg : constant Positive :=
         Positive'Max (Segments_For_Radius (Max_R),
                       (if Min_Segments > 0 then Min_Segments else 1));

      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := 2 * N_Outline;
      Total_Indices : constant Natural := N_Outline * 6;

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;
      II : Natural := 0;

      FC_Solid : constant SDL_FColor :=
         (r => Float (R) / 255.0,
          g => Float (G) / 255.0,
          b => Float (B) / 255.0,
          a => Float (A) / 255.0);

      FC_Clear : constant SDL_FColor :=
         (r => Float (R) / 255.0,
          g => Float (G) / 255.0,
          b => Float (B) / 255.0,
          a => 0.0);

      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      procedure Add_Pair (X, Y, NX, NY : Float) is
      begin
         --  Inner vertex (on shape outline) — full alpha
         Verts (VI) := (position  => (x => X, y => Y),
                        color     => FC_Solid,
                        tex_coord => Zero_TC);
         VI := VI + 1;
         --  Outer vertex (offset by fringe along normal) — alpha 0
         Verts (VI) := (position  => (x => X + NX * Fringe,
                                      y => Y + NY * Fringe),
                        color     => FC_Clear,
                        tex_coord => Zero_TC);
         VI := VI + 1;
      end Add_Pair;

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

      Step    : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);
      Success : Adi.SDL.C_bool;
   begin
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

      --  Generate inner/outer vertex pairs along the outline.
      --  Each Add_Pair emits 2 vertices: inner at index VI, outer at VI+1.
      --  So pair K has inner at 2*K, outer at 2*K+1.

      --  Top-left arc: center (X0+R_TL, Y0+R_TL), from PI to 3*PI/2
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi + Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X0 + R_TL + R_TL * CA,
                      Y0 + R_TL + R_TL * SA,
                      CA, SA);
         end;
      end loop;

      --  Top-right arc: center (X1-R_TR, Y0+R_TR), from 3*PI/2 to 2*PI
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := 3.0 * Ada.Numerics.Pi / 2.0
                                       + Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X1 - R_TR + R_TR * CA,
                      Y0 + R_TR + R_TR * SA,
                      CA, SA);
         end;
      end loop;

      --  Bottom-right arc: center (X1-R_BR, Y1-R_BR), from 0 to PI/2
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X1 - R_BR + R_BR * CA,
                      Y1 - R_BR + R_BR * SA,
                      CA, SA);
         end;
      end loop;

      --  Bottom-left arc: center (X0+R_BL, Y1-R_BL), from PI/2 to PI
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi / 2.0
                                       + Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X0 + R_BL + R_BL * CA,
                      Y1 - R_BL + R_BL * SA,
                      CA, SA);
         end;
      end loop;

      --  Build triangle strip between inner ring and outer ring.
      --  Pair K: inner = 2*K, outer = 2*K+1.
      for K in 0 .. N_Outline - 1 loop
         declare
            Next_K  : constant Natural := (K + 1) mod N_Outline;
            Inner_A : constant Natural := 2 * K;
            Outer_A : constant Natural := 2 * K + 1;
            Inner_B : constant Natural := 2 * Next_K;
            Outer_B : constant Natural := 2 * Next_K + 1;
         begin
            Add_Triangle (Inner_A, Inner_B, Outer_A);
            Add_Triangle (Outer_A, Inner_B, Outer_B);
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
   end Render_AA_Fringe;

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

   ---------------------------------------------------------------------------
   --  Linear Gradient Rendering Helpers
   ---------------------------------------------------------------------------

   type Resolved_Stop is record
      Pos   : Float;
      Color : SDL_FColor;
   end record;
   type Resolved_Stop_Array is array (1 .. Max_Gradient_Stops) of Resolved_Stop;

   --  Auto-distribute positions for stops without explicit positions,
   --  then convert colors via CSS_Color_To_SDL_F.
   procedure Resolve_Gradient_Stops
     (G       : Linear_Gradient_Value;
      Opacity : Float;
      Stops   : out Resolved_Stop_Array;
      Count   : out Natural)
   is
      N       : constant Natural := G.Stop_Count;
      Pos_Arr : array (1 .. Max_Gradient_Stops) of Float :=
        [others => -1.0];
   begin
      Count := N;
      if N = 0 then
         return;
      end if;

      --  Collect explicit positions; use -1.0 as sentinel for auto
      for I in 1 .. N loop
         if G.Stops (I).Has_Pos then
            Pos_Arr (I) := G.Stops (I).Position;
         end if;
      end loop;

      --  Anchor endpoints
      if Pos_Arr (1) < 0.0 then Pos_Arr (1) := 0.0; end if;
      if Pos_Arr (N) < 0.0 then Pos_Arr (N) := 1.0; end if;

      --  Distribute interior auto-stops by interpolating between neighbors
      declare
         I : Natural := 2;
      begin
         while I < N loop
            if Pos_Arr (I) < 0.0 then
               declare
                  Run_Start : constant Natural := I;
                  J         : Natural          := I + 1;
               begin
                  --  Find first following stop with an explicit position
                  while J < N and then Pos_Arr (J) < 0.0 loop
                     J := J + 1;
                  end loop;
                  --  Positions (Run_Start-1) and Positions (J) are anchored
                  declare
                     P0   : constant Float   := Pos_Arr (Run_Start - 1);
                     P1   : constant Float   := Pos_Arr (J);
                     Span : constant Natural := J - Run_Start + 1;
                  begin
                     for K in Run_Start .. J - 1 loop
                        Pos_Arr (K) :=
                           P0 + Float (K - Run_Start + 1)
                                / Float (Span) * (P1 - P0);
                     end loop;
                  end;
                  I := J + 1;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end;

      --  Build output
      for I in 1 .. N loop
         Stops (I) :=
           (Pos   => Pos_Arr (I),
            Color => CSS_Color_To_SDL_F (G.Stops (I).Color, Opacity));
      end loop;
   end Resolve_Gradient_Stops;

   --  Sample gradient at T in [0,1] by linearly interpolating between stops.
   function Sample_Gradient
     (Stops : Resolved_Stop_Array; Count : Natural; T : Float)
      return SDL_FColor
   is
      Tc : constant Float := Float'Max (0.0, Float'Min (1.0, T));
   begin
      if Count = 0 then
         return (r => 0.0, g => 0.0, b => 0.0, a => 0.0);
      end if;
      if Count = 1 then
         return Stops (1).Color;
      end if;
      if Tc <= Stops (1).Pos then
         return Stops (1).Color;
      end if;
      if Tc >= Stops (Count).Pos then
         return Stops (Count).Color;
      end if;
      for I in 1 .. Count - 1 loop
         if Tc >= Stops (I).Pos and then Tc <= Stops (I + 1).Pos then
            declare
               Span : constant Float := Stops (I + 1).Pos - Stops (I).Pos;
               F    : constant Float :=
                  (if Span < 1.0e-6 then 0.0
                   else (Tc - Stops (I).Pos) / Span);
               C0   : constant SDL_FColor := Stops (I).Color;
               C1   : constant SDL_FColor := Stops (I + 1).Color;
            begin
               return (r => C0.r + F * (C1.r - C0.r),
                       g => C0.g + F * (C1.g - C0.g),
                       b => C0.b + F * (C1.b - C0.b),
                       a => C0.a + F * (C1.a - C0.a));
            end;
         end if;
      end loop;
      return Stops (Count).Color;
   end Sample_Gradient;

   --  Project point (X,Y) onto the CSS gradient line and return T in [0,1].
   --  Angle_Deg: 0=to top, 90=to right, 180=to bottom (CSS convention).
   function Gradient_T_For_Point
     (X, Y : Float; Rect : SDL_FRect; Angle_Deg : Float) return Float
   is
      Angle_Rad : constant Float :=
         (Angle_Deg - 90.0) * Ada.Numerics.Pi / 180.0;
      Dx       : constant Float := Cos (Angle_Rad);
      Dy       : constant Float := Sin (Angle_Rad);
      W        : constant Float := Rect.w;
      H        : constant Float := Rect.h;
      Grad_Len : constant Float := abs (W * Dx) + abs (H * Dy);
      Cx       : constant Float := Rect.x + W / 2.0;
      Cy       : constant Float := Rect.y + H / 2.0;
      T        : Float;
   begin
      if Grad_Len < 1.0e-6 then
         return 0.5;
      end if;
      T := (Dx * (X - Cx) + Dy * (Y - Cy)) / Grad_Len + 0.5;
      return Float'Max (0.0, Float'Min (1.0, T));
   end Gradient_T_For_Point;

   --  Render a gradient-filled rectangle (no border radius).
   --  Uses clip rect to contain non-axis-aligned gradient strips.
   procedure Render_Gradient_Rect
     (Renderer : SDL_Renderer_Ptr;
      Rect     : SDL_FRect;
      G        : Linear_Gradient_Value;
      Opacity  : Float)
   is
      G_Stops : Resolved_Stop_Array;
      G_Count : Natural;

      Angle_Rad : constant Float :=
         (G.Angle - 90.0) * Ada.Numerics.Pi / 180.0;
      Dx       : constant Float := Cos (Angle_Rad);
      Dy       : constant Float := Sin (Angle_Rad);
      W        : constant Float := Rect.w;
      H        : constant Float := Rect.h;
      Grad_Len : constant Float := abs (W * Dx) + abs (H * Dy);
      Cx       : constant Float := Rect.x + W / 2.0;
      Cy       : constant Float := Rect.y + H / 2.0;
      Half_Ext : constant Float := W + H;   --  safe over-extension
      Nx       : constant Float := -Dy;
      Ny       : constant Float :=  Dx;

      Had_Clip  : Boolean             := False;
      Prev_Clip : aliased Adi.SDL.SDL_Rect;
      Clip      : aliased Adi.SDL.SDL_Rect;
      Success   : Adi.SDL.C_bool;

      Verts   : SDL_Vertex_Array (0 .. 3);
      Idxs    : Int_Array (0 .. 5);
      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      procedure Render_Strip (T0, T1 : Float; C0, C1 : SDL_FColor) is
         Off0 : constant Float := (T0 - 0.5) * Grad_Len;
         Off1 : constant Float := (T1 - 0.5) * Grad_Len;
         P0x  : constant Float := Cx + Dx * Off0;
         P0y  : constant Float := Cy + Dy * Off0;
         P1x  : constant Float := Cx + Dx * Off1;
         P1y  : constant Float := Cy + Dy * Off1;
      begin
         Verts (0) :=
           (position  => (x => P0x - Nx * Half_Ext, y => P0y - Ny * Half_Ext),
            color     => C0,
            tex_coord => Zero_TC);
         Verts (1) :=
           (position  => (x => P0x + Nx * Half_Ext, y => P0y + Ny * Half_Ext),
            color     => C0,
            tex_coord => Zero_TC);
         Verts (2) :=
           (position  => (x => P1x + Nx * Half_Ext, y => P1y + Ny * Half_Ext),
            color     => C1,
            tex_coord => Zero_TC);
         Verts (3) :=
           (position  => (x => P1x - Nx * Half_Ext, y => P1y - Ny * Half_Ext),
            color     => C1,
            tex_coord => Zero_TC);
         Idxs (0) := 0; Idxs (1) := 1; Idxs (2) := 2;
         Idxs (3) := 0; Idxs (4) := 2; Idxs (5) := 3;
         SDL_Assert (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
                     "SDL_SetRenderDrawBlendMode");
         Success := SDL_RenderGeometry
           (Renderer     => Renderer,
            Texture      => null,
            Vertices     => Verts (0)'Access,
            Num_Vertices => 4,
            Indices      => Idxs (0)'Access,
            Num_Indices  => 6);
      end Render_Strip;

   begin
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

      Resolve_Gradient_Stops (G, Opacity, G_Stops, G_Count);
      if G_Count < 2 then
         return;
      end if;

      --  Set clip rect to contain strips within the widget bounds
      Had_Clip := Boolean (SDL_RenderClipEnabled (Renderer));
      if Had_Clip then
         Success := SDL_GetRenderClipRect (Renderer, Prev_Clip'Access);
      end if;
      Clip := (x => int (Float'Floor (Rect.x)),
               y => int (Float'Floor (Rect.y)),
               w => int (Float'Ceiling (Rect.w)),
               h => int (Float'Ceiling (Rect.h)));
      Success := SDL_SetRenderClipRect (Renderer, Clip'Access);

      --  Solid band before the first stop (CSS spec: first color extends back)
      if G_Stops (1).Pos > 0.0 then
         Render_Strip (0.0, G_Stops (1).Pos,
                       G_Stops (1).Color, G_Stops (1).Color);
      end if;

      for I in 1 .. G_Count - 1 loop
         Render_Strip (G_Stops (I).Pos, G_Stops (I + 1).Pos,
                       G_Stops (I).Color, G_Stops (I + 1).Color);
      end loop;

      --  Solid band after the last stop (CSS spec: last color extends forward)
      if G_Stops (G_Count).Pos < 1.0 then
         Render_Strip (G_Stops (G_Count).Pos, 1.0,
                       G_Stops (G_Count).Color, G_Stops (G_Count).Color);
      end if;

      if Had_Clip then
         Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
      else
         Success := SDL_SetRenderClipRect (Renderer, null);
      end if;
   end Render_Gradient_Rect;

   --  Render a gradient-filled rounded rectangle.
   --  Mirrors Render_Rounded_Rect (per-corner radii variant) but with
   --  per-vertex color sampling from the gradient.
   --  No AA fringe in v1. Geometrically correct for 2 stops; 3+ stops may
   --  show per-triangle interpolation artifacts on non-axis-aligned gradients.
   procedure Render_Gradient_Rounded_Rect
     (Renderer     : SDL_Renderer_Ptr;
      Rect         : SDL_FRect;
      Radii        : Corner_Pixels;
      G            : Linear_Gradient_Value;
      Opacity      : Float;
      Min_Segments : Natural := 0)
   is
      Max_Dim       : constant Float := Half_Min_Dimension_Non_Neg (Rect);
      Clamped_Radii : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Radii, Max_Dim);
      R_TL : constant Float := Clamped_Radii.Top_Left;
      R_TR : constant Float := Clamped_Radii.Top_Right;
      R_BR : constant Float := Clamped_Radii.Bottom_Right;
      R_BL : constant Float := Clamped_Radii.Bottom_Left;

      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));

      Num_Seg : constant Positive :=
         Positive'Max (Segments_For_Radius (Max_R),
                       (if Min_Segments > 0 then Min_Segments else 1));

      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := N_Outline + 1;
      Total_Indices : constant Natural := N_Outline * 3;

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;
      II : Natural := 0;

      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      X0 : constant Float := Rect.x;
      Y0 : constant Float := Rect.y;
      X1 : constant Float := Rect.x + Rect.w;
      Y1 : constant Float := Rect.y + Rect.h;

      Center_Idx    : Natural;
      First_Outline : Natural;
      Step    : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);
      Success : Adi.SDL.C_bool;

      G_Stops : Resolved_Stop_Array;
      G_Count : Natural;

      procedure Add_Vertex (X, Y : Float) is
         T  : constant Float :=
            Gradient_T_For_Point (X, Y, Rect, G.Angle);
         FC : constant SDL_FColor :=
            Sample_Gradient (G_Stops, G_Count, T);
      begin
         Verts (VI) :=
           (position  => (x => X, y => Y),
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

   begin
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

      Resolve_Gradient_Stops (G, Opacity, G_Stops, G_Count);

      if Max_R < 1.0 then
         Render_Gradient_Rect (Renderer, Rect, G, Opacity);
         return;
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
   end Render_Gradient_Rounded_Rect;

   --  AA fringe for gradient-filled rounded rects.
   --  Same tessellation as Render_AA_Fringe (outward, Fringe=+1) but each
   --  inner vertex is colored by sampling the gradient at that point, so the
   --  fade matches the gradient edge rather than a single uniform color.
   procedure Render_Gradient_AA_Fringe
     (Renderer     : SDL_Renderer_Ptr;
      Rect         : SDL_FRect;
      Radii        : Corner_Pixels;
      G            : Linear_Gradient_Value;
      Opacity      : Float;
      Min_Segments : Natural := 0)
   is
      Max_Dim : constant Float := Half_Min_Dimension_Non_Neg (Rect);
      Clamped_Radii : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Radii, Max_Dim);
      R_TL : constant Float := Clamped_Radii.Top_Left;
      R_TR : constant Float := Clamped_Radii.Top_Right;
      R_BR : constant Float := Clamped_Radii.Bottom_Right;
      R_BL : constant Float := Clamped_Radii.Bottom_Left;
      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));
      Num_Seg : constant Positive :=
         Positive'Max (Segments_For_Radius (Max_R),
                       (if Min_Segments > 0 then Min_Segments else 1));
      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := 2 * N_Outline;
      Total_Indices : constant Natural := N_Outline * 6;
      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);
      VI : Natural := 0;
      II : Natural := 0;
      G_Stops : Resolved_Stop_Array;
      G_Count : Natural;
      Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);

      procedure Add_Pair (X, Y, NX, NY : Float) is
         T        : constant Float      :=
            Gradient_T_For_Point (X, Y, Rect, G.Angle);
         FC_Solid : constant SDL_FColor :=
            Sample_Gradient (G_Stops, G_Count, T);
         FC_Clear : constant SDL_FColor :=
           (r => FC_Solid.r, g => FC_Solid.g, b => FC_Solid.b, a => 0.0);
      begin
         Verts (VI) := (position  => (x => X, y => Y),
                        color     => FC_Solid,
                        tex_coord => Zero_TC);
         VI := VI + 1;
         Verts (VI) := (position  => (x => X + NX, y => Y + NY),
                        color     => FC_Clear,
                        tex_coord => Zero_TC);
         VI := VI + 1;
      end Add_Pair;

      procedure Add_Triangle (IA, IB, IC : Natural) is
      begin
         Idxs (II)     := int (IA);
         Idxs (II + 1) := int (IB);
         Idxs (II + 2) := int (IC);
         II := II + 3;
      end Add_Triangle;

      X0   : constant Float := Rect.x;
      Y0   : constant Float := Rect.y;
      X1   : constant Float := Rect.x + Rect.w;
      Y1   : constant Float := Rect.y + Rect.h;
      Step : constant Float := Ada.Numerics.Pi / 2.0 / Float (Num_Seg);
      Success : Adi.SDL.C_bool;
   begin
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

      Resolve_Gradient_Stops (G, Opacity, G_Stops, G_Count);

      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Ada.Numerics.Pi + Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X0 + R_TL + R_TL * CA, Y0 + R_TL + R_TL * SA, CA, SA);
         end;
      end loop;
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               3.0 * Ada.Numerics.Pi / 2.0 + Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X1 - R_TR + R_TR * CA, Y0 + R_TR + R_TR * SA, CA, SA);
         end;
      end loop;
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float := Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X1 - R_BR + R_BR * CA, Y1 - R_BR + R_BR * SA, CA, SA);
         end;
      end loop;
      for I in 0 .. Num_Seg loop
         declare
            Angle : constant Float :=
               Ada.Numerics.Pi / 2.0 + Float (I) * Step;
            CA    : constant Float := Cos (Angle);
            SA    : constant Float := Sin (Angle);
         begin
            Add_Pair (X0 + R_BL + R_BL * CA, Y1 - R_BL + R_BL * SA, CA, SA);
         end;
      end loop;

      for K in 0 .. N_Outline - 1 loop
         declare
            Next_K  : constant Natural := (K + 1) mod N_Outline;
            Inner_A : constant Natural := 2 * K;
            Outer_A : constant Natural := 2 * K + 1;
            Inner_B : constant Natural := 2 * Next_K;
            Outer_B : constant Natural := 2 * Next_K + 1;
         begin
            Add_Triangle (Inner_A, Inner_B, Outer_A);
            Add_Triangle (Outer_A, Inner_B, Outer_B);
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
   end Render_Gradient_AA_Fringe;

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
      Uniform      : Boolean;
      Has_Gradient : Boolean;
      Op           : constant Float := Float (Style.Opacity);
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

      procedure Draw_Edge_Borders (Respect_Radius : Boolean := False) is
         Edge_Rect : aliased SDL_FRect;
         Top_X     : Float;
         Top_W     : Float;
         Bottom_X  : Float;
         Bottom_W  : Float;
         Left_Y    : Float;
         Left_H    : Float;
         Right_Y   : Float;
         Right_H   : Float;
      begin
         if Is_Visible_Edge (Top, BW_Top) then
            Top_X := Rect.x;
            Top_W := Rect.w;
            if Respect_Radius then
               Top_X := Top_X + Radius_Px.Top_Left;
               Top_W := Top_W - Radius_Px.Top_Left - Radius_Px.Top_Right;
            end if;
            if Top_W > 0.0 then
               Set_Edge_Color (Top);
               Edge_Rect :=
                 (x => Top_X,
                  y => Rect.y,
                  w => Top_W,
                  h => BW_Top);
               SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                           "SDL_RenderFillRect");
            end if;
         end if;

         if Is_Visible_Edge (Bottom, BW_Bottom) then
            Bottom_X := Rect.x;
            Bottom_W := Rect.w;
            if Respect_Radius then
               Bottom_X := Bottom_X + Radius_Px.Bottom_Left;
               Bottom_W := Bottom_W - Radius_Px.Bottom_Left - Radius_Px.Bottom_Right;
            end if;
            if Bottom_W > 0.0 then
               Set_Edge_Color (Bottom);
               Edge_Rect :=
                 (x => Bottom_X,
                  y => Rect.y + Float'Max (0.0, Rect.h - BW_Bottom),
                  w => Bottom_W,
                  h => BW_Bottom);
               SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                           "SDL_RenderFillRect");
            end if;
         end if;

         if Is_Visible_Edge (Left, BW_Left) then
            Left_Y := Rect.y;
            Left_H := Rect.h;
            if Respect_Radius then
               Left_Y := Left_Y + Radius_Px.Top_Left;
               Left_H := Left_H - Radius_Px.Top_Left - Radius_Px.Bottom_Left;
            end if;
            if Left_H > 0.0 then
               Set_Edge_Color (Left);
               Edge_Rect :=
                 (x => Rect.x,
                  y => Left_Y,
                  w => BW_Left,
                  h => Left_H);
               SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                           "SDL_RenderFillRect");
            end if;
         end if;

         if Is_Visible_Edge (Right, BW_Right) then
            Right_Y := Rect.y;
            Right_H := Rect.h;
            if Respect_Radius then
               Right_Y := Right_Y + Radius_Px.Top_Right;
               Right_H := Right_H - Radius_Px.Top_Right - Radius_Px.Bottom_Right;
            end if;
            if Right_H > 0.0 then
               Set_Edge_Color (Right);
               Edge_Rect :=
                 (x => Rect.x + Float'Max (0.0, Rect.w - BW_Right),
                  y => Right_Y,
                  w => BW_Right,
                  h => Right_H);
               SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                           "SDL_RenderFillRect");
            end if;
         end if;
      end Draw_Edge_Borders;

      procedure Draw_Corner_Sector
        (Cx, Cy      : Float;
         Outer_R     : Float;
         Start_Thickness : Float;
         End_Thickness   : Float;
         Start_Angle : Float;
         End_Angle   : Float)
      is
         Span    : constant Float := End_Angle - Start_Angle;
         Safe_Span : constant Float := Float'Max (0.0, Span);
         Base_Seg : constant Positive :=
           Segments_For_Radius (Float'Max (1.0, Outer_R));
         Num_Seg : constant Positive :=
           Segments_For_Span (Base_Seg, Span);

         Total_Verts   : constant Natural := 2 * (Num_Seg + 1);
         Total_Indices : constant Natural := Num_Seg * 6;
         Verts         : SDL_Vertex_Array (0 .. Total_Verts - 1);
         Idxs          : Int_Array (0 .. Total_Indices - 1);
         VI            : Natural := 0;
         II            : Natural := 0;

         FC : constant SDL_FColor :=
           (r => Float (R) / 255.0,
            g => Float (G) / 255.0,
            b => Float (B) / 255.0,
            a => Float (A) / 255.0);
         Zero_TC : constant SDL_FPoint := (x => 0.0, y => 0.0);
         Success : Adi.SDL.C_bool;
         begin
         if Outer_R <= 0.0
           or else Float'Max (Start_Thickness, End_Thickness) <= 0.0
           or else Safe_Span <= 0.0
         then
            return;
         end if;

         for I in 0 .. Num_Seg loop
            declare
               T     : constant Float := Float (I) / Float (Num_Seg);
               Angle : constant Float := Start_Angle + T * Safe_Span;
               Thickness : constant Float :=
                 Float'Max
                   (0.0,
                    Start_Thickness + T * (End_Thickness - Start_Thickness));
               Inner_R : constant Float := Float'Max (0.0, Outer_R - Thickness);
               CA    : constant Float := Cos (Angle);
               SA    : constant Float := Sin (Angle);
            begin
               --  Outer
               Verts (VI) :=
                 (position  => (x => Cx + Outer_R * CA, y => Cy + Outer_R * SA),
                  color     => FC,
                  tex_coord => Zero_TC);
               VI := VI + 1;
               --  Inner
               Verts (VI) :=
                 (position  => (x => Cx + Inner_R * CA, y => Cy + Inner_R * SA),
                  color     => FC,
                  tex_coord => Zero_TC);
               VI := VI + 1;
            end;
         end loop;

         for I in 0 .. Num_Seg - 1 loop
            declare
               O_A : constant Natural := 2 * I;
               I_A : constant Natural := 2 * I + 1;
               O_B : constant Natural := 2 * (I + 1);
               I_B : constant Natural := 2 * (I + 1) + 1;
            begin
               Idxs (II) := int (O_A);
               Idxs (II + 1) := int (O_B);
               Idxs (II + 2) := int (I_B);
               II := II + 3;

               Idxs (II) := int (O_A);
               Idxs (II + 1) := int (I_B);
               Idxs (II + 2) := int (I_A);
               II := II + 3;
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
      end Draw_Corner_Sector;

      procedure Draw_Rounded_Corner_Borders is
         Split_Angle : constant Float := Ada.Numerics.Pi / 4.0;
         Mid_T       : Float;
      begin
         --  Top-left corner
         if Radius_Px.Top_Left > 0.0 then
            if Is_Visible_Edge (Left, BW_Left)
              and then Is_Visible_Edge (Top, BW_Top)
            then
               Mid_T := 0.5 * (BW_Left + BW_Top);
               Set_Edge_Color (Left);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Top_Left,
                 Cy => Rect.y + Radius_Px.Top_Left,
                 Outer_R => Radius_Px.Top_Left,
                 Start_Thickness => BW_Left,
                 End_Thickness => Mid_T,
                 Start_Angle => Ada.Numerics.Pi,
                 End_Angle => Ada.Numerics.Pi + Split_Angle);

               Set_Edge_Color (Top);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Top_Left,
                 Cy => Rect.y + Radius_Px.Top_Left,
                 Outer_R => Radius_Px.Top_Left,
                 Start_Thickness => Mid_T,
                 End_Thickness => BW_Top,
                 Start_Angle => Ada.Numerics.Pi + Split_Angle,
                 End_Angle => 3.0 * Ada.Numerics.Pi / 2.0);
            elsif Is_Visible_Edge (Left, BW_Left) then
               Set_Edge_Color (Left);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Top_Left,
                 Cy => Rect.y + Radius_Px.Top_Left,
                 Outer_R => Radius_Px.Top_Left,
                 Start_Thickness => BW_Left,
                 End_Thickness => BW_Left,
                 Start_Angle => Ada.Numerics.Pi,
                 End_Angle => 3.0 * Ada.Numerics.Pi / 2.0);
            elsif Is_Visible_Edge (Top, BW_Top) then
               Set_Edge_Color (Top);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Top_Left,
                 Cy => Rect.y + Radius_Px.Top_Left,
                 Outer_R => Radius_Px.Top_Left,
                 Start_Thickness => BW_Top,
                 End_Thickness => BW_Top,
                 Start_Angle => Ada.Numerics.Pi,
                 End_Angle => 3.0 * Ada.Numerics.Pi / 2.0);
            end if;
         end if;

         --  Top-right corner
         if Radius_Px.Top_Right > 0.0 then
            if Is_Visible_Edge (Top, BW_Top)
              and then Is_Visible_Edge (Right, BW_Right)
            then
               Mid_T := 0.5 * (BW_Top + BW_Right);
               Set_Edge_Color (Top);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Top_Right,
                 Cy => Rect.y + Radius_Px.Top_Right,
                 Outer_R => Radius_Px.Top_Right,
                 Start_Thickness => BW_Top,
                 End_Thickness => Mid_T,
                 Start_Angle => 3.0 * Ada.Numerics.Pi / 2.0,
                 End_Angle => 3.0 * Ada.Numerics.Pi / 2.0 + Split_Angle);

               Set_Edge_Color (Right);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Top_Right,
                 Cy => Rect.y + Radius_Px.Top_Right,
                 Outer_R => Radius_Px.Top_Right,
                 Start_Thickness => Mid_T,
                 End_Thickness => BW_Right,
                 Start_Angle => 3.0 * Ada.Numerics.Pi / 2.0 + Split_Angle,
                 End_Angle => 2.0 * Ada.Numerics.Pi);
            elsif Is_Visible_Edge (Top, BW_Top) then
               Set_Edge_Color (Top);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Top_Right,
                 Cy => Rect.y + Radius_Px.Top_Right,
                 Outer_R => Radius_Px.Top_Right,
                 Start_Thickness => BW_Top,
                 End_Thickness => BW_Top,
                 Start_Angle => 3.0 * Ada.Numerics.Pi / 2.0,
                 End_Angle => 2.0 * Ada.Numerics.Pi);
            elsif Is_Visible_Edge (Right, BW_Right) then
               Set_Edge_Color (Right);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Top_Right,
                 Cy => Rect.y + Radius_Px.Top_Right,
                 Outer_R => Radius_Px.Top_Right,
                 Start_Thickness => BW_Right,
                 End_Thickness => BW_Right,
                 Start_Angle => 3.0 * Ada.Numerics.Pi / 2.0,
                 End_Angle => 2.0 * Ada.Numerics.Pi);
            end if;
         end if;

         --  Bottom-right corner
         if Radius_Px.Bottom_Right > 0.0 then
            if Is_Visible_Edge (Right, BW_Right)
              and then Is_Visible_Edge (Bottom, BW_Bottom)
            then
               Mid_T := 0.5 * (BW_Right + BW_Bottom);
               Set_Edge_Color (Right);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Bottom_Right,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Right,
                 Outer_R => Radius_Px.Bottom_Right,
                 Start_Thickness => BW_Right,
                 End_Thickness => Mid_T,
                 Start_Angle => 0.0,
                 End_Angle => Split_Angle);

               Set_Edge_Color (Bottom);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Bottom_Right,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Right,
                 Outer_R => Radius_Px.Bottom_Right,
                 Start_Thickness => Mid_T,
                 End_Thickness => BW_Bottom,
                 Start_Angle => Split_Angle,
                 End_Angle => Ada.Numerics.Pi / 2.0);
            elsif Is_Visible_Edge (Right, BW_Right) then
               Set_Edge_Color (Right);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Bottom_Right,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Right,
                 Outer_R => Radius_Px.Bottom_Right,
                 Start_Thickness => BW_Right,
                 End_Thickness => BW_Right,
                 Start_Angle => 0.0,
                 End_Angle => Ada.Numerics.Pi / 2.0);
            elsif Is_Visible_Edge (Bottom, BW_Bottom) then
               Set_Edge_Color (Bottom);
               Draw_Corner_Sector (
                 Cx => Rect.x + Rect.w - Radius_Px.Bottom_Right,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Right,
                 Outer_R => Radius_Px.Bottom_Right,
                 Start_Thickness => BW_Bottom,
                 End_Thickness => BW_Bottom,
                 Start_Angle => 0.0,
                 End_Angle => Ada.Numerics.Pi / 2.0);
            end if;
         end if;

         --  Bottom-left corner
         if Radius_Px.Bottom_Left > 0.0 then
            if Is_Visible_Edge (Bottom, BW_Bottom)
              and then Is_Visible_Edge (Left, BW_Left)
            then
               Mid_T := 0.5 * (BW_Bottom + BW_Left);
               Set_Edge_Color (Bottom);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Bottom_Left,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Left,
                 Outer_R => Radius_Px.Bottom_Left,
                 Start_Thickness => BW_Bottom,
                 End_Thickness => Mid_T,
                 Start_Angle => Ada.Numerics.Pi / 2.0,
                 End_Angle => Ada.Numerics.Pi / 2.0 + Split_Angle);

               Set_Edge_Color (Left);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Bottom_Left,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Left,
                 Outer_R => Radius_Px.Bottom_Left,
                 Start_Thickness => Mid_T,
                 End_Thickness => BW_Left,
                 Start_Angle => Ada.Numerics.Pi / 2.0 + Split_Angle,
                 End_Angle => Ada.Numerics.Pi);
            elsif Is_Visible_Edge (Bottom, BW_Bottom) then
               Set_Edge_Color (Bottom);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Bottom_Left,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Left,
                 Outer_R => Radius_Px.Bottom_Left,
                 Start_Thickness => BW_Bottom,
                 End_Thickness => BW_Bottom,
                 Start_Angle => Ada.Numerics.Pi / 2.0,
                 End_Angle => Ada.Numerics.Pi);
            elsif Is_Visible_Edge (Left, BW_Left) then
               Set_Edge_Color (Left);
               Draw_Corner_Sector (
                 Cx => Rect.x + Radius_Px.Bottom_Left,
                 Cy => Rect.y + Rect.h - Radius_Px.Bottom_Left,
                 Outer_R => Radius_Px.Bottom_Left,
                 Start_Thickness => BW_Left,
                 End_Thickness => BW_Left,
                 Start_Angle => Ada.Numerics.Pi / 2.0,
                 End_Angle => Ada.Numerics.Pi);
            end if;
         end if;
      end Draw_Rounded_Corner_Borders;
   begin
      if Style.Display = Display_None
        or else Normalize_Visibility (Style.Visibility) = Visibility_Hidden
      then
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

      Has_Gradient :=
         Style.Background_Image.Kind = Linear_Gradient_Image;

      --  Outline (drawn outside the border box, does not affect layout).
      --  Rendered BEFORE background/border so the widget's own background
      --  fill naturally covers the outline's inner aliased edge — same
      --  layering principle that makes border inner-edge AA work.
      if Style.Outline_Style /= Outline_None
        and then Style.Outline_Width.Amount > 0.0
      then
         declare
            OW : constant Float := Style.Outline_Width.Amount;
            OO : constant Float := Style.Outline_Offset.Amount;
            Expand : constant Float := OO + OW;
            Outline_Outer : aliased SDL_FRect :=
              (x => Rect.x - Expand,
               y => Rect.y - Expand,
               w => Rect.w + 2.0 * Expand,
               h => Rect.h + 2.0 * Expand);
            Outline_Inner : aliased SDL_FRect :=
              (x => Rect.x - OO,
               y => Rect.y - OO,
               w => Rect.w + 2.0 * OO,
               h => Rect.h + 2.0 * OO);
            OR_Val, OG_Val, OB_Val, OA_Val : Uint8;
         begin
            CSS_Color_To_SDL (Style.Outline_Color, OR_Val, OG_Val, OB_Val, OA_Val);
            OA_Val := Apply_Opacity (OA_Val, Op);

            if Has_Radius then
               declare
                  Outer_Radii : constant Corner_Pixels :=
                    (Top_Left     => Radius_Px.Top_Left + Expand,
                     Top_Right    => Radius_Px.Top_Right + Expand,
                     Bottom_Right => Radius_Px.Bottom_Right + Expand,
                     Bottom_Left  => Radius_Px.Bottom_Left + Expand);
                  Inner_Radii : constant Corner_Pixels :=
                    (Top_Left     => Radius_Px.Top_Left + OO,
                     Top_Right    => Radius_Px.Top_Right + OO,
                     Bottom_Right => Radius_Px.Bottom_Right + OO,
                     Bottom_Left  => Radius_Px.Bottom_Left + OO);
                  --  Shared segment count so ring and fringe use identical
                  --  tessellation (prevents ray artifacts).
                  Seg : constant Positive :=
                     Segments_For_Radius
                       (Float'Max
                          (Float'Max (Outer_Radii.Top_Left,
                                      Outer_Radii.Top_Right),
                           Float'Max (Outer_Radii.Bottom_Right,
                                      Outer_Radii.Bottom_Left)));
               begin
                  Render_Rounded_Border_Ring
                    (Renderer, Outline_Outer, Outline_Inner,
                     Outer_Radii, Inner_Radii,
                     OR_Val, OG_Val, OB_Val, OA_Val,
                     Min_Segments => Seg);
                  --  AA fringe on outer outline edge
                  Render_AA_Fringe
                    (Renderer, Outline_Outer, Outer_Radii,
                     OR_Val, OG_Val, OB_Val, OA_Val,
                     Min_Segments => Seg);
                  --  AA fringe on inner outline edge (shared Seg
                  --  ensures tessellation matches the ring boundary)
                  Render_AA_Fringe
                    (Renderer, Outline_Inner, Inner_Radii,
                     OR_Val, OG_Val, OB_Val, OA_Val,
                     Min_Segments => Seg,
                     Inward => True);
               end;
            else
               declare
                  Edge_Rect : aliased SDL_FRect;
               begin
                  SDL_Assert (SDL_SetRenderDrawColor
                    (Renderer, OR_Val, OG_Val, OB_Val, OA_Val),
                    "SDL_SetRenderDrawColor");
                  --  Top
                  Edge_Rect := (x => Outline_Outer.x, y => Outline_Outer.y,
                                w => Outline_Outer.w, h => OW);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
                  --  Bottom
                  Edge_Rect := (x => Outline_Outer.x,
                                y => Outline_Outer.y + Outline_Outer.h - OW,
                                w => Outline_Outer.w, h => OW);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
                  --  Left
                  Edge_Rect := (x => Outline_Outer.x, y => Outline_Outer.y,
                                w => OW, h => Outline_Outer.h);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
                  --  Right
                  Edge_Rect := (x => Outline_Outer.x + Outline_Outer.w - OW,
                                y => Outline_Outer.y,
                                w => OW, h => Outline_Outer.h);
                  SDL_Assert (SDL_RenderFillRect (Renderer, Edge_Rect'Access),
                              "SDL_RenderFillRect");
               end;
            end if;
         end;
      end if;

      if Has_Radius then

         if Has_Border and then Uniform_Border_Width and then BW_Top > 0.0 then
            --  Render border as a ring (annulus), then fill the interior.
            --  Compute segment count once from the outer radius so the
            --  ring's inner boundary and the fill share identical tessellation.
            declare
               Seg : constant Positive :=
                  Segments_For_Radius
                     (if Uniform then Max_Rad
                      else Float'Max
                        (Float'Max (Radius_Px.Top_Left, Radius_Px.Top_Right),
                         Float'Max (Radius_Px.Bottom_Right, Radius_Px.Bottom_Left)));
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
               BR, BG, BB, BA : Uint8;
            begin
               --  Border ring
               Set_Edge_Color (Top);
               BR := R; BG := G; BB := B; BA := A;
               Render_Rounded_Border_Ring
                  (Renderer, Rect, Inner, Radius_Px, Inner_Radii, R, G, B, A,
                   Min_Segments => Seg);

               --  AA fringe on outer border edge
               Render_AA_Fringe
                  (Renderer, Rect, Radius_Px,
                   BR, BG, BB, BA,
                   Min_Segments => Seg);

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
                            Float'Max (0.0, Max_Rad - BW_Top), R, G, B, A,
                            Min_Segments => Seg);
                     else
                        Render_Rounded_Rect
                           (Renderer, Inner, Inner_Radii, R, G, B, A,
                            Min_Segments => Seg);
                     end if;
                  end if;
               end if;

               --  Gradient fill (renders over background-color,
               --  under inner AA fringe — no AA fringe for gradient in v1)
               if Has_Gradient
                 and then Inner.w > 0.0 and then Inner.h > 0.0
               then
                  if Uniform then
                     Render_Gradient_Rounded_Rect
                       (Renderer, Inner,
                        (Top_Left     => Float'Max (0.0, Max_Rad - BW_Top),
                         Top_Right    => Float'Max (0.0, Max_Rad - BW_Top),
                         Bottom_Right => Float'Max (0.0, Max_Rad - BW_Top),
                         Bottom_Left  => Float'Max (0.0, Max_Rad - BW_Top)),
                        Style.Background_Image.Gradient.all, Op,
                        Min_Segments => Seg);
                  else
                     Render_Gradient_Rounded_Rect
                       (Renderer, Inner, Inner_Radii,
                        Style.Background_Image.Gradient.all, Op,
                        Min_Segments => Seg);
                  end if;
               end if;

               --  Inner AA fringe (always render — smooths border inner
               --  edge regardless of background transparency)
               if Inner.w > 0.0 and then Inner.h > 0.0 then
                  Render_AA_Fringe
                     (Renderer, Inner, Inner_Radii,
                      BR, BG, BB, BA,
                      Min_Segments => Seg,
                      Inward => True);
               end if;
            end;

         else
            --  Rounded corners with non-uniform/partial borders: render
            --  rounded background, then draw per-edge borders as strips.
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
               --  AA fringe on outer background edge (skip when gradient
               --  covers the fill — gradient has no AA fringe in v1)
               if not Has_Gradient then
                  Render_AA_Fringe (Renderer, Rect, Radius_Px, R, G, B, A);
               end if;
            end if;

            --  Gradient fill + gradient-aware AA fringe
            if Has_Gradient then
               if Uniform then
                  Render_Gradient_Rounded_Rect
                    (Renderer, Rect,
                     (Top_Left | Top_Right | Bottom_Right | Bottom_Left =>
                        Max_Rad),
                     Style.Background_Image.Gradient.all, Op);
                  Render_Gradient_AA_Fringe
                    (Renderer, Rect,
                     (Top_Left | Top_Right | Bottom_Right | Bottom_Left =>
                        Max_Rad),
                     Style.Background_Image.Gradient.all, Op);
               else
                  Render_Gradient_Rounded_Rect
                    (Renderer, Rect, Radius_Px,
                     Style.Background_Image.Gradient.all, Op);
                  Render_Gradient_AA_Fringe
                    (Renderer, Rect, Radius_Px,
                     Style.Background_Image.Gradient.all, Op);
               end if;
            end if;

            if Has_Border then
               Draw_Edge_Borders (Respect_Radius => True);
               Draw_Rounded_Corner_Borders;
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

         --  Gradient fill
         if Has_Gradient then
            Render_Gradient_Rect
              (Renderer, Rect, Style.Background_Image.Gradient.all, Op);
         end if;

         --  Border
         if Has_Border then
            Draw_Edge_Borders;
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
      Text_Size  : Size_2D;
      Deco_Rect  : aliased SDL_FRect;
      Text_Draw_X : Pixel_Type;
      Text_Draw_Y : Pixel_Type;
      Deco_X     : Pixel_Type;
      Deco_W     : Pixel_Type;
      Deco_H     : Pixel_Type;
      Deco_Y     : Pixel_Type;
      Deco_Offset_Y : Pixel_Type;
      Deco_Y_Raw : Pixel_Type;
      Ascent_Px  : Pixel_Type;
      Descent_Px : Pixel_Type;
      Baseline_Y_I : Integer;
      Deco_Y_I     : Integer;
      Deco_H_I     : Integer;
      Draw_Underline : constant Boolean :=
        (Style.Text_Decoration = Decoration_Underline);
      Draw_Overline : constant Boolean :=
        (Style.Text_Decoration = Decoration_Overline);
      Draw_Strike : constant Boolean :=
        (Style.Text_Decoration = Decoration_Line_Through);
      Manual_Decoration : constant Boolean :=
        Draw_Underline or else Draw_Overline or else Draw_Strike;
      Engine     : TTF_TextEngine_Access;
      Renderer   : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Prev_Clip  : aliased Adi.SDL.SDL_Rect;
      Clip_Rect  : aliased Adi.SDL.SDL_Rect;
      Had_Clip   : Boolean := False;
      Use_Clip   : constant Boolean :=
        Renderer /= null and then Has_Visible_Area (Geom);
      X1, Y1, X2, Y2 : Integer;
   begin
      if Style.Display = Display_None
        or else Normalize_Visibility (Style.Visibility) = Visibility_Hidden
        or else Content'Length = 0
      then
         return;
      end if;

      --  Sub-pixel text geometry must render nothing; otherwise clip can
      --  be skipped and text may reappear when constrained to zero height.
      if not Has_Visible_Area (Geom) then
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
         Decoration =>
           (if Manual_Decoration then Decoration_None else Style.Text_Decoration));

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
      if It.Wrap_Text and then Is_Visible_Px (Geom.Width) then
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
      Text_Draw_X := Pixel_Type (Float'Floor (Float (Geom.X + It.Text_Offset_X)));
      Text_Draw_Y := Pixel_Type (Float'Floor (Float (Geom.Y + It.Text_Offset_Y)));

      --  SDL_ttf text decorations (underline/strikethrough) can render with
      --  incorrect RGB in renderer text-engine path; keep draw color aligned.
      SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                  "SDL_SetRenderDrawColor");
      Success := TTF_DrawRendererText
        (Text_Obj,
         C_float (Text_Draw_X),
         C_float (Text_Draw_Y));

      --  Workaround for SDL_ttf renderer text engine decoration color handling:
      --  in current upstream versions, underline/strikethrough draw ops can be
      --  emitted as non-alpha fill sequences that render with white RGB.
      --  Draw these two decorations manually using the resolved text color.
      if Manual_Decoration then
         Text_Size := Adi.Font.Measure_Text (Attrs => Font_Attrs, Content => Content);
         Deco_W := Pixel_Type'Min (Geom.Width, Pixel_Type'Max (0.0, Text_Size.Width));
         Deco_H := Pixel_Type'Max
           (1.0,
            Pixel_Type
                  (Float'Ceiling
                     (Float (Pixel_Type'Max (1.0, Pixel_Type (Font_Sz) / 14.0)))));
         Deco_H_I := Integer (Float'Ceiling (Float (Deco_H)));
         if Deco_H_I < 1 then
            Deco_H_I := 1;
         end if;
         Deco_H := Pixel_Type (Deco_H_I);

         Ascent_Px := Pixel_Type (TTF_GetFontAscent (Font));
         Descent_Px := Pixel_Type (TTF_GetFontDescent (Font));
         if Descent_Px < 0.0 then
            Descent_Px := -Descent_Px;
         end if;

         if Draw_Underline then
            Deco_Y_Raw :=
              Ascent_Px
              + Pixel_Type'Max (1.0, Descent_Px * 0.55)
              - Deco_H / 2.0;
         elsif Draw_Overline then
            --  Place overline near the ascent top (not x-height), slightly
            --  inset to avoid clipping while keeping it visibly high.
            Deco_Y_Raw :=
              Pixel_Type'Max
                (1.0,
                 Ascent_Px * 0.12
                 - Deco_H / 2.0);
         else
            Deco_Y_Raw :=
              --  Place strike-through around the visual middle of lowercase
              --  glyph bodies (closer to x-height center than ascent top).
              Ascent_Px * 0.72
              - Deco_H / 2.0;
         end if;

         if Deco_W > 0.0 and then Deco_H > 0.0 then
            --  Clamp relative offset against already clamped text origin, then
            --  clamp again for final target placement to avoid scroll jitter.
            Deco_Offset_Y := Pixel_Type (Float'Floor (Float (Deco_Y_Raw)));
            Deco_X := Pixel_Type (Float'Floor (Float (Text_Draw_X)));
            Deco_Y_I := Integer (Float'Floor (Float (Text_Draw_Y + Deco_Offset_Y)));

            if Draw_Underline then
               Baseline_Y_I := Integer (Float'Floor (Float (Text_Draw_Y + Ascent_Px)));
               --  After all integer roundings, keep at least 1 px gap from
               --  text baseline to underline top.
               if Deco_Y_I - Baseline_Y_I < 1 then
                  Deco_Y_I := Baseline_Y_I + 1;
               end if;
            elsif Draw_Overline then
               declare
                  Ascent_Top_I : constant Integer :=
                    Integer (Float'Floor (Float (Text_Draw_Y)));
               begin
                  --  After all integer roundings, keep at least 1 px gap from
                  --  the ascent top to overline top.
                  if Deco_Y_I - Ascent_Top_I < 1 then
                     Deco_Y_I := Ascent_Top_I + 1;
                  end if;
               end;
            end if;

            Deco_Y := Pixel_Type (Deco_Y_I);

            Deco_W := Pixel_Type'Max (1.0, Pixel_Type (Float'Ceiling (Float (Deco_W))));

            Deco_Rect :=
              (x => Float (Deco_X),
               y => Float (Deco_Y),
               w => Float (Deco_W),
               h => Float (Deco_H));

            SDL_Assert
              (SDL_SetRenderDrawBlendMode (Renderer, SDL_BLENDMODE_BLEND),
               "SDL_SetRenderDrawBlendMode");
            SDL_Assert
              (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
               "SDL_SetRenderDrawColor");
            SDL_Assert (SDL_RenderFillRect (Renderer, Deco_Rect'Access),
                        "SDL_RenderFillRect");
         end if;
      end if;

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
       Opacity      : Float := 1.0;
       Tint_R       : Float := 1.0;
       Tint_G       : Float := 1.0;
       Tint_B       : Float := 1.0)
   is
      Max_Dim : constant Float := Half_Min_Dimension_Non_Neg (Rect);
      Clamped_Radii : constant Corner_Pixels :=
        Clamp_Corner_Radii_To_Max (Radii, Max_Dim);
      R_TL : constant Float := Clamped_Radii.Top_Left;
      R_TR : constant Float := Clamped_Radii.Top_Right;
      R_BR : constant Float := Clamped_Radii.Bottom_Right;
      R_BL : constant Float := Clamped_Radii.Bottom_Left;

      Max_R : constant Float :=
         Float'Max (Float'Max (R_TL, R_TR), Float'Max (R_BR, R_BL));

      Num_Seg : constant Positive := Segments_For_Radius (Max_R);

      N_Outline     : constant Natural := 4 * (Num_Seg + 1);
      Total_Verts   : constant Natural := N_Outline + 1;
      Total_Indices : constant Natural := N_Outline * 3;

      Verts : SDL_Vertex_Array (0 .. Total_Verts - 1);
      Idxs  : Int_Array (0 .. Total_Indices - 1);

      VI : Natural := 0;
      II : Natural := 0;

      FC : constant SDL_FColor := (r => Tint_R, g => Tint_G, b => Tint_B, a => Opacity);

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
      if not Is_Visible_FRect (Rect) then
         return;
      end if;

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
      Renderer   : SDL_Renderer_Ptr;
      Geom       : Rectangle;
      Source     : Image_Access;
      Style      : Resolved_Style)
   is
      use Interfaces.C;
      Color_Tint : constant Boolean :=
        Source /= null and then Adi.Image.Is_Tintable (Source.all);
      Texture          : SDL_Texture_Ptr;
      Img_W, Img_H     : Pixel_Type;
      Req_W, Req_H     : Pixel_Type;
      Dst_X, Dst_Y     : Pixel_Type;
      Dst_W, Dst_H     : Pixel_Type;
      Scale_X, Scale_Y : Float;
      Dst_Rect         : aliased SDL_FRect;
      Tex_W_F, Tex_H_F : aliased Float := 0.0;
      U0, V0, U1, V1  : Float;
      Radius_Px        : Corner_Pixels;
      Max_Rad          : Float;
      Success          : Adi.SDL.C_bool;
      Prev_Clip        : aliased Adi.SDL.SDL_Rect;
      Clip_Rect        : aliased Adi.SDL.SDL_Rect;
      Had_Clip         : Boolean := False;
      Use_Clip         : constant Boolean :=
        Renderer /= null and then Has_Visible_Area (Geom);
      X1, Y1, X2, Y2   : Integer;
   begin
      if Style.Display = Display_None
        or else Normalize_Visibility (Style.Visibility) = Visibility_Hidden
      then
         return;
      end if;

      if not Has_Visible_Area (Geom) then
         return;
      end if;

      if Source = null or else not Is_Valid (Source.all) then
         return;
      end if;

      Get_Size (Source.all, Img_W, Img_H);
      if not Is_Visible_Px (Img_W) or else not Is_Visible_Px (Img_H) then
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
            if Has_Visible_Area (Geom) then
               declare
                  Img_Asp  : constant Float :=
                     Float (Img_W) / Float (Img_H);
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
            Scale_X := Float (Geom.Width) / Float (Img_W);
            Scale_Y := Float (Geom.Height) / Float (Img_H);
            declare
               S : constant Float := Float'Min (Scale_X, Scale_Y);
            begin
               Dst_W := Pixel_Type (Float (Img_W) * S);
               Dst_H := Pixel_Type (Float (Img_H) * S);
            end;
            Dst_X := Geom.X + (Geom.Width - Dst_W) / 2.0;
            Dst_Y := Geom.Y + (Geom.Height - Dst_H) / 2.0;

         when Fit_None =>
            Dst_W := Pixel_Type (Img_W);
            Dst_H := Pixel_Type (Img_H);
            Dst_X := Geom.X;
            Dst_Y := Geom.Y;

         when Fit_Scale_Down =>
            if Pixel_Type (Img_W) > Geom.Width
               or Pixel_Type (Img_H) > Geom.Height
            then
               Scale_X := Float (Geom.Width) / Float (Img_W);
               Scale_Y := Float (Geom.Height) / Float (Img_H);
               declare
                  S : constant Float := Float'Min (Scale_X, Scale_Y);
               begin
                  Dst_W := Pixel_Type (Float (Img_W) * S);
                  Dst_H := Pixel_Type (Float (Img_H) * S);
               end;
            else
               Dst_W := Pixel_Type (Img_W);
               Dst_H := Pixel_Type (Img_H);
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

      --  Snap image target geometry to integral pixels to avoid sub-pixel
      --  filtering blur for fine SVG details.
      Dst_X := Pixel_Type (Float'Floor (Float (Dst_X)));
      Dst_Y := Pixel_Type (Float'Floor (Float (Dst_Y)));
      Dst_W := Pixel_Type (Float'Ceiling (Float (Dst_W)));
      Dst_H := Pixel_Type (Float'Ceiling (Float (Dst_H)));
      if Dst_W < 1.0 then
         Dst_W := 1.0;
      end if;
      if Dst_H < 1.0 then
         Dst_H := 1.0;
      end if;

      Req_W := Dst_W;
      Req_H := Dst_H;
      if Style.Object_Fit = Fit_Cover and then Img_W > 0.0 and then Img_H > 0.0 then
         declare
            Img_Asp : constant Float := Float (Img_W) / Float (Img_H);
            Dst_Asp : constant Float := Float (Dst_W) / Float (Dst_H);
         begin
            if Img_Asp > Dst_Asp then
               Req_H := Dst_H;
               Req_W := Pixel_Type (Float (Req_H) * Img_Asp);
            else
               Req_W := Dst_W;
               Req_H := Pixel_Type (Float (Req_W) / Img_Asp);
            end if;
         end;
      end if;

      Texture := Get_Texture_For_Size (Source.all, Renderer, Req_W, Req_H);
      if Texture = null then
         Texture := Get_Texture (Source.all, Renderer);
      end if;
      if Texture = null then
         return;
      end if;

      Tex_W_F := Float (Img_W);
      Tex_H_F := Float (Img_H);
      Success := SDL_GetTextureSize (Texture, Tex_W_F'Access, Tex_H_F'Access);
      if not Boolean (Success) or else Tex_W_F <= 0.0 or else Tex_H_F <= 0.0 then
         Tex_W_F := Float (Img_W);
         Tex_H_F := Float (Img_H);
      end if;

      Dst_Rect.x := Float (Dst_X);
      Dst_Rect.y := Float (Dst_Y);
      Dst_Rect.w := Float (Dst_W);
      Dst_Rect.h := Float (Dst_H);

      --  Clip image rendering to item bounds so object-fit:none and oversized
      --  images are cropped instead of bleeding outside the widget viewport.
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
         if Color_Tint then
            declare
               CR, CG, CB, CA : Uint8;
            begin
               CSS_Color_To_SDL (Style.Color, CR, CG, CB, CA);
               Render_Rounded_Image
                  (Renderer, Dst_Rect, Radius_Px, Texture,
                   U0, V0, U1, V1, Float (Style.Opacity),
                   Tint_R => Float (CR) / 255.0,
                   Tint_G => Float (CG) / 255.0,
                   Tint_B => Float (CB) / 255.0);
            end;
         else
            Render_Rounded_Image
               (Renderer, Dst_Rect, Radius_Px, Texture,
                U0, V0, U1, V1, Float (Style.Opacity));
         end if;
      else
         if Color_Tint then
            declare
               CR, CG, CB, CA : Uint8;
            begin
               CSS_Color_To_SDL (Style.Color, CR, CG, CB, CA);
               Success := SDL_SetTextureColorModFloat
                 (Texture,
                  Float (CR) / 255.0,
                  Float (CG) / 255.0,
                  Float (CB) / 255.0);
            end;
         end if;
         Success := SDL_SetTextureAlphaModFloat
           (Texture, Float (Style.Opacity));
         if U0 /= 0.0 or else V0 /= 0.0
            or else U1 /= 1.0 or else V1 /= 1.0
         then
            --  Cropped source (Cover mode without rounding)
            declare
               Src_Rect : aliased SDL_FRect :=
                  (x => U0 * Tex_W_F,
                   y => V0 * Tex_H_F,
                   w => (U1 - U0) * Tex_W_F,
                   h => (V1 - V0) * Tex_H_F);
            begin
               Success := SDL_RenderTexture
                  (Renderer, Texture, Src_Rect'Access, Dst_Rect'Access);
            end;
         else
            Success := SDL_RenderTexture
               (Renderer, Texture, null, Dst_Rect'Access);
         end if;
      end if;

      if Use_Clip then
         if Had_Clip then
            Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
         else
            Success := SDL_SetRenderClipRect (Renderer, null);
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
      if Renderer = null or else not Has_Visible_Area (Geom) then
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

   procedure Build_Items_W is new Wrap_Prim_Proc (Build_Items);
   procedure Build_Items (H : Widget_Handle) renames Build_Items_W;

   procedure Render_Items (W : in out Widget'Class; Ctx : in out Render_Context) is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Padding_Box (Get_Geometry (W), Main_Style);
      Clip_X : constant Boolean := Overflow_Clips (Main_Style.Overflow_X);
      Clip_Y : constant Boolean := Overflow_Clips (Main_Style.Overflow_Y);
      Clip_By_Scrollable : constant Boolean := Has_Flag (W, Scrollable);
      Prev_Clip : aliased Adi.SDL.SDL_Rect;
      Clip_Rect : aliased Adi.SDL.SDL_Rect;
      Had_Clip  : Boolean := False;
      Use_Clip  : Boolean := False;
      Clip_Valid : Boolean := False;
      Clip_Active : Boolean := False;
      Success : Adi.SDL.C_bool;

      procedure Restore_Previous_Clip is
      begin
         if Renderer = null then
            return;
         end if;

         if Had_Clip then
            Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
         else
            Success := SDL_SetRenderClipRect (Renderer, null);
         end if;
         Clip_Active := False;
      end Restore_Previous_Clip;

      procedure Set_Item_Clip (Need_Clip : Boolean) is
      begin
         if not Use_Clip or else Renderer = null then
            return;
         end if;

         if Need_Clip and then not Clip_Active then
            if Clip_Valid then
               Success := SDL_SetRenderClipRect (Renderer, Clip_Rect'Access);
               Clip_Active := True;
            end if;
         elsif not Need_Clip and then Clip_Active then
            Restore_Previous_Clip;
         end if;
      end Set_Item_Clip;
   begin
      if Renderer /= null and then (Clip_X or else Clip_Y or else Clip_By_Scrollable) then
         if Has_Visible_Area (Content) then
            Use_Clip := True;
            Had_Clip := Boolean (SDL_RenderClipEnabled (Renderer));
            if Had_Clip then
               Success := SDL_GetRenderClipRect (Renderer, Prev_Clip'Access);
            end if;
            Clip_Valid :=
              Build_Content_Clip_Rect (
                Renderer  => Renderer,
                Content   => Content,
                Clip_X    => Clip_X,
                Clip_Y    => (Clip_Y or else Clip_By_Scrollable),
                Had_Clip  => Had_Clip,
                Prev_Clip => Prev_Clip,
                Out_Clip  => Clip_Rect);
         end if;
      end if;

      for I in 1 .. Natural (W.Items.Length) loop
         declare
            Current : Item renames W.Items.Reference (I).Element.all;
            Style   : Resolved_Style renames Current.Computed_Style;
            Need_Item_Clip : constant Boolean :=
              Use_Clip and then not
                (Current.Kind = Panel_Item and then Current.Part = Main_Part);
            Scroll_Shift : constant Pixel_Type := Pixel_Type (Get_Scroll_Y (Ctx));
         begin
            --  Temporarily apply scroll offset for rendering
            Current.Geometry.Y := Current.Geometry.Y + Scroll_Shift;

            if Need_Item_Clip and then not Clip_Valid then
               null;
            elsif not Item_Is_Rendered (Style) then
               null;
            else
               Set_Item_Clip (Need_Item_Clip);

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
            end if;

            --  Restore original geometry
            Current.Geometry.Y := Current.Geometry.Y - Scroll_Shift;
         end;
      end loop;

      if Clip_Active then
         Restore_Previous_Clip;
      end if;
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

   procedure Render_Tree_Impl
     (W                : in out Widget'Class;
      Ctx              : in out Render_Context;
      Parent_Visibility : Visibility_Value)
   is
      Renderer : constant SDL_Renderer_Ptr := Get_Renderer (Ctx);
      Widget_Visibility : constant Visibility_Value :=
        Resolve_Effective_Visibility (W, Parent_Visibility);
      Widget_Is_Visible : constant Boolean :=
        Widget_Visibility = Visibility_Visible;
      Prev_Clip  : aliased Adi.SDL.SDL_Rect;
      Clip_Rect  : aliased Adi.SDL.SDL_Rect;
      Had_Clip   : Boolean := False;
      Use_Clip   : Boolean := False;
      Skip_Children : Boolean := False;
      Success    : Adi.SDL.C_bool;
   begin
      if not Widget_Participates (W) then
         return;
      end if;

      if Widget_Is_Visible then
         --  Render this widget's own visuals first; overflow clipping applies to
         --  descendant content, not the widget's own background/border panel.
         Render_Items (W, Ctx);
      end if;

      if Widget_Is_Visible and then Debug_Layout_Overlay_Enabled and then Renderer /= null then
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
            Clip_X : constant Boolean := Overflow_Clips (Main_Style.Overflow_X);
            Clip_Y : constant Boolean := Overflow_Clips (Main_Style.Overflow_Y);
            Clip_By_Scrollable : constant Boolean := Has_Flag (W, Scrollable);
            Content : constant Rectangle :=
              Padding_Box (Get_Geometry (W), Main_Style);
         begin
            if Clip_X or else Clip_Y or else Clip_By_Scrollable then
               if not Has_Visible_Area (Content) then
                  Skip_Children := True;
               else
                  Use_Clip := True;
                  Had_Clip := Boolean (SDL_RenderClipEnabled (Renderer));
                  if Had_Clip then
                     Success := SDL_GetRenderClipRect (Renderer, Prev_Clip'Access);
                  end if;
                  if Build_Content_Clip_Rect (
                     Renderer  => Renderer,
                     Content   => Content,
                     Clip_X    => Clip_X,
                     Clip_Y    => (Clip_Y or else Clip_By_Scrollable),
                     Had_Clip  => Had_Clip,
                     Prev_Clip => Prev_Clip,
                     Out_Clip  => Clip_Rect)
                  then
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
         declare
            Saved_Scroll_Y : constant Float := Get_Scroll_Y (Ctx);
         begin
            if Is_Scroll_Enabled (W) and then W.Scroll_Offset_Y > 0.0 then
               Set_Scroll_Y (Ctx, Saved_Scroll_Y - Float (W.Scroll_Offset_Y));
            end if;
            for Child of W.Children loop
               Render_Tree_Impl (Child.all, Ctx, Widget_Visibility);
            end loop;
            Set_Scroll_Y (Ctx, Saved_Scroll_Y);
         end;
      end if;

      if Use_Clip then
         if Had_Clip then
            Success := SDL_SetRenderClipRect (Renderer, Prev_Clip'Access);
         else
            Success := SDL_SetRenderClipRect (Renderer, null);
         end if;
      end if;

      if Widget_Is_Visible then
         Render_Shared_Scrollbar (W, Ctx);
      end if;
   end Render_Tree_Impl;

   procedure Render_Tree (W : in out Widget'Class; Ctx : in out Render_Context) is
   begin
      Render_Tree_Impl (W, Ctx, Visibility_Visible);
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
            if Current.Computed_Style.Display /= Display_None then
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
            end if;
         end;
      end loop;

      --  Also consider children
      for Child of W.Children loop
         if Widget_Participates (Child.all) then
            declare
               Child_Size : constant Size_2D := Measure_Content(Child.all);
            begin
               Result := Max(Result, Child_Size);
            end;
         end if;
      end loop;

      return Result;
   end Measure_Content;

   function Measure_Content_W is
     new Wrap_Prim_Func (Size_2D, (0.0, 0.0), Measure_Content);
   function Measure_Content (H : Widget_Handle) return Size_2D
     renames Measure_Content_W;

   function Get_Min_Size(W : Widget) return Size_2D is
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

   function Get_Preferred_Size (W : Widget'Class) return Size_2D is
      --  Pass-scoped + mutation-keyed cache.  Same 'Unrestricted_Access
      --  pattern as Get_Resolved_Part_Style — safe because the cache is
      --  a pure memo (same inputs always produce the same output).
      W_Mut : constant access Widget'Class := W'Unrestricted_Access;
      Eff   : constant Widget_States := Get_States (W);
   begin
      Inc_Sat (Perf_Pref_Calls);

      --  Cache hit?  Same epoch + style version + content version +
      --  states + geometry + layout epoch.  Content_Version detects mutations like
      --  Set_Text or Add_Child that affect Measure_Content without
      --  changing Style_Version.
      if W_Mut.Cached_Pref_Epoch = Current_Layout_Epoch
        and then W_Mut.Cached_Pref_Version = W.Style_Version
        and then W_Mut.Cached_Pref_Content = W.Content_Version
        and then W_Mut.Cached_Pref_States = Eff
        and then W_Mut.Cached_Pref_Geom_W = W.Geometry.Width
        and then W_Mut.Cached_Pref_Geom_H = W.Geometry.Height
        and then W_Mut.Cached_Pref_Layout_Epoch = W.Last_Layout_Epoch
      then
         Inc_Sat (Perf_Pref_Hits);
         return W_Mut.Cached_Pref_Size;
      end if;

      --  Cache miss: compute.
      declare
         Style : constant Resolved_Style :=
           Get_Resolved_Part_Style (W, Main_Part);
         Scrollable_X : constant Boolean :=
           Is_Scroll_Enabled (W)
             or else Overflow_Is_Scrollable (Style.Overflow_X);
         Scrollable_Y : constant Boolean :=
           Is_Scroll_Enabled (W);
         Pref_W, Pref_H : Pixel_Type := 0.0;
         Need_Content_W : Boolean := False;
         Need_Content_H : Boolean := False;
         Result : Size_2D;
      begin
         --  Check explicit width/height
         case Style.Width.Kind is
            when Fixed =>
               Pref_W := Size_To_Px (Style.Width, W.Geometry.Width);
            when others =>
               if Scrollable_X then
                  Pref_W := Outer_Size
                    ((Get_Min_Size (W).Width, 0.0), Style).Width;
               else
                  Need_Content_W := True;
               end if;
         end case;

         case Style.Height.Kind is
            when Fixed =>
               Pref_H := Size_To_Px (Style.Height, W.Geometry.Height);
            when others =>
               --  Scrollable containers should not report full content
               --  height as preferred size — use min-height instead so the
               --  window can shrink and let the scroll mechanism activate.
               --  Always include padding + border so the container chrome
               --  is never clipped.
               if Scrollable_Y then
                  Pref_H := Outer_Size
                    ((0.0, Get_Min_Size (W).Height), Style).Height;
               else
                  Need_Content_H := True;
               end if;
         end case;

         if Need_Content_W or Need_Content_H then
            declare
               Content : constant Size_2D := Measure_Content (W);
            begin
               if Need_Content_W then
                  Pref_W := Content.Width;
               end if;
               if Need_Content_H then
                  Pref_H := Content.Height;
               end if;
            end;
         end if;

         Result := (Pref_W, Pref_H);

         W_Mut.Cached_Pref_Size    := Result;
         W_Mut.Cached_Pref_Epoch   := Current_Layout_Epoch;
         W_Mut.Cached_Pref_Version := W.Style_Version;
         W_Mut.Cached_Pref_Content := W.Content_Version;
         W_Mut.Cached_Pref_States  := Eff;
         W_Mut.Cached_Pref_Geom_W  := W.Geometry.Width;
         W_Mut.Cached_Pref_Geom_H  := W.Geometry.Height;
         W_Mut.Cached_Pref_Layout_Epoch := W.Last_Layout_Epoch;
         return Result;
      end;
   end Get_Preferred_Size;

   function Get_Min_Size_W is
     new Wrap_Prim_Func (Size_2D, (0.0, 0.0), Get_Min_Size);
   function Get_Min_Size (H : Widget_Handle) return Size_2D
     renames Get_Min_Size_W;

   function Get_Preferred_Size_W is
     new Wrap_CW_Func (Size_2D, (0.0, 0.0), Get_Preferred_Size);
   function Get_Preferred_Size (H : Widget_Handle) return Size_2D
     renames Get_Preferred_Size_W;

   procedure Layout_W is new Wrap_Prim_Proc (Layout);
   procedure Layout (H : Widget_Handle) renames Layout_W;

   ---------------------------------------------------------------------------
   --  Flex Layout
   ---------------------------------------------------------------------------

   function Is_Flex_Container(W : Widget'Class) return Boolean is
      Style : constant Resolved_Style := Get_Resolved_Part_Style(W, Main_Part);
   begin
      return Style.Display = Flex or Style.Display = Inline_Flex;
   end Is_Flex_Container;

   --  Resolve inset offsets and position an absolute child within a container
   --  content box.  Applies top/right/bottom/left offsets, with dual-inset
   --  sizing when both horizontal or both vertical insets are present and no
   --  explicit CSS width/height is set.
   procedure Position_Absolute_Child
     (Child       : in out Widget'Class;
      Child_Style : Resolved_Style;
      Container   : Rectangle)
   is
      L : constant Pixel_Type := Inset_To_Px (Child_Style.Left, Container.Width);
      R : constant Pixel_Type := Inset_To_Px (Child_Style.Right, Container.Width);
      T : constant Pixel_Type := Inset_To_Px (Child_Style.Top, Container.Height);
      B : constant Pixel_Type := Inset_To_Px (Child_Style.Bottom, Container.Height);
      Pref : constant Size_2D := Get_Preferred_Size (Child);
      CX   : Pixel_Type := Container.X + L;
      CY   : Pixel_Type := Container.Y + T;
      CW   : Pixel_Type := Pref.Width;
      CH   : Pixel_Type := Pref.Height;
   begin
      --  Explicit CSS width overrides preferred
      case Child_Style.Width.Kind is
         when Fixed =>
            CW := Size_To_Px (Child_Style.Width, Container.Width);
         when others =>
            --  Dual horizontal insets → derive width
            if Child_Style.Left.Kind = Fixed
              and then Child_Style.Right.Kind = Fixed
            then
               CW := Pixel_Type'Max (0.0, Container.Width - L - R);
            end if;
      end case;

      --  Explicit CSS height overrides preferred
      case Child_Style.Height.Kind is
         when Fixed =>
            CH := Size_To_Px (Child_Style.Height, Container.Height);
         when others =>
            --  Dual vertical insets → derive height
            if Child_Style.Top.Kind = Fixed
              and then Child_Style.Bottom.Kind = Fixed
            then
               CH := Pixel_Type'Max (0.0, Container.Height - T - B);
            end if;
      end case;

      --  Right-only anchor (left not set)
      if Child_Style.Left.Kind = Auto
        and then Child_Style.Right.Kind = Fixed
      then
         CX := Container.X + Container.Width - R - CW;
      end if;

      --  Bottom-only anchor (top not set)
      if Child_Style.Top.Kind = Auto
        and then Child_Style.Bottom.Kind = Fixed
      then
         CY := Container.Y + Container.Height - B - CH;
      end if;

      Set_Geometry (Child, (CX, CY, CW, CH));
      Layout_Child (Child);
   end Position_Absolute_Child;

   --  Apply relative offset to a child after normal flow placement.
   --  Container is the parent content box, used as percentage basis.
   procedure Apply_Relative_Offset
     (Child     : in out Widget'Class;
      Container : Rectangle)
   is
      CS : constant Resolved_Style := Get_Resolved_Part_Style (Child, Main_Part);
   begin
      if CS.Position /= Relative then
         return;
      end if;
      declare
         G : Rectangle := Get_Geometry (Child);
         DX : constant Pixel_Type :=
           Inset_To_Px (CS.Left, Container.Width)
           - Inset_To_Px (CS.Right, Container.Width);
         DY : constant Pixel_Type :=
           Inset_To_Px (CS.Top, Container.Height)
           - Inset_To_Px (CS.Bottom, Container.Height);
      begin
         if DX /= 0.0 or else DY /= 0.0 then
            G.X := G.X + DX;
            G.Y := G.Y + DY;
            Set_Geometry (Child, G);
            --  Re-layout so descendants get updated coordinates
            Layout_Child (Child);
         end if;
      end;
   end Apply_Relative_Offset;

   procedure Perform_Flex_Layout(W : in out Widget'Class) is
      Style : constant Resolved_Style := Get_Resolved_Part_Style(W, Main_Part);
      Total_Children : constant Natural := Natural (W.Children.Length);
      Num_Children : Natural := 0;
      Num_Absolute : Natural := 0;

      --  Content box (after padding/border)
      Content : constant Rectangle := Content_Box(W.Geometry, Style);
   begin
      if Total_Children = 0 then
         return;
      end if;

      --  Count flow vs absolute children
      for Child of W.Children loop
         if Child /= null and then Widget_Participates (Child.all) then
            declare
               CS : constant Resolved_Style :=
                 Get_Resolved_Part_Style (Child.all, Main_Part);
            begin
               if CS.Position = Absolute then
                  Num_Absolute := Num_Absolute + 1;
               else
                  Num_Children := Num_Children + 1;
               end if;
            end;
         end if;
      end loop;

      if Num_Children = 0 and then Num_Absolute = 0 then
         return;
      end if;

      --  Build flex context
      declare
         type Child_Array is array (Positive range <>) of Widget_Access;
         Active_Children  : Child_Array (1 .. Natural'Max (Num_Children, 1));
         Abs_Children     : Child_Array (1 .. Natural'Max (Num_Absolute, 1));
         Abs_Index        : Natural := 0;
         Context : Flex_Layout_Context;
         Children_Info : Flex_Child_Info_Array
           (1 .. Natural'Max (Num_Children, 1));
         Child_Index : Natural := 0;
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

         --  Collect child information, separating absolute children
         for Child of W.Children loop
            if Child /= null and then Widget_Participates (Child.all) then
               declare
                  Child_Style : constant Resolved_Style :=
                     Get_Resolved_Part_Style(Child.all, Main_Part);
               begin
                  if Child_Style.Position = Absolute then
                     Abs_Index := Abs_Index + 1;
                     Abs_Children (Abs_Index) := Child;
                  else
                     Child_Index := Child_Index + 1;
                     Active_Children (Child_Index) := Child;

                     declare
                        Child_Pref : constant Size_2D :=
                          Get_Preferred_Size(Child.all);
                        Child_Min  : constant Size_2D :=
                          Get_Min_Size(Child.all);

                        Info : Flex_Child_Info;
                        Flex_Basis_Px : Pixel_Type := 0.0;
                     begin
                        --  Flex properties
                        Info.Flex_Grow := Float(Child_Style.Flex_Grow);
                        Info.Flex_Shrink := Float(Child_Style.Flex_Shrink);

                        --  Flex basis
                        case Child_Style.Flex_Basis.Kind is
                           when Auto =>
                              Flex_Basis_Px := Get_Main_Size
                                (Child_Pref, Style.Flex_Direction);
                           when CSS_Styles.Content =>
                              Flex_Basis_Px := Get_Main_Size
                                (Child_Min, Style.Flex_Direction);
                           when Fixed =>
                              Flex_Basis_Px := Length_To_Px(
                                 Child_Style.Flex_Basis.Size,
                                 Get_Main_Size
                                   ((Content.Width, Content.Height),
                                    Style.Flex_Direction));
                        end case;
                        Info.Flex_Basis := Flex_Basis_Px;

                        --  Align self
                        Info.Align_Self := Child_Style.Align_Self;

                        --  Size constraints
                        Info.Min_Main := Get_Main_Size
                          (Child_Min, Style.Flex_Direction);
                        Info.Min_Cross := Get_Cross_Size
                          (Child_Min, Style.Flex_Direction);

                        --  For visible overflow, preserve preferred main
                        --  size only for non-shrinkable children.
                        if Main_Axis_Overflow
                             (Style, Style.Flex_Direction) = Overflow_Visible
                          and then Float (Child_Style.Flex_Shrink) = 0.0
                        then
                           Info.Min_Main := Pixel_Type'Max
                             (Info.Min_Main,
                              Get_Main_Size
                                (Child_Pref, Style.Flex_Direction));
                        end if;

                        --  Max constraints
                        declare
                           Max_W : Pixel_Type := Pixel_Type'Last;
                           Max_H : Pixel_Type := Pixel_Type'Last;
                        begin
                           case Child_Style.Max_Width.Kind is
                              when Fixed =>
                                 Max_W := Size_To_Px
                                   (Child_Style.Max_Width, Content.Width);
                              when others => null;
                           end case;
                           case Child_Style.Max_Height.Kind is
                              when Fixed =>
                                 Max_H := Size_To_Px
                                   (Child_Style.Max_Height, Content.Height);
                              when others => null;
                           end case;
                           Info.Max_Main := Get_Main_Size
                             ((Max_W, Max_H), Style.Flex_Direction);
                           Info.Max_Cross := Get_Cross_Size
                             ((Max_W, Max_H), Style.Flex_Direction);
                        end;

                        --  Content sizes
                        Info.Content_Main := Get_Main_Size
                          (Child_Pref, Style.Flex_Direction);
                        Info.Content_Cross := Get_Cross_Size
                          (Child_Pref, Style.Flex_Direction);

                        --  Margins
                        Info.Margin := Get_Margin_Px(Child_Style);

                        Children_Info(Child_Index) := Info;
                     end;
                  end if;
               end;
            end if;
         end loop;

         --  Run flex algorithm on flow children
         if Num_Children > 0 then
            Compute_Flex_Layout(Context,
              Children_Info (1 .. Num_Children));

            --  Convert to rectangles and apply
            declare
               Assigned : constant Rectangle_Array :=
                  Flex_To_Rectangles(Context,
                    Children_Info (1 .. Num_Children));
            begin
               for I in 1 .. Num_Children loop
                  Set_Geometry (Active_Children (I).all, Assigned (I));
               end loop;

               --  Recursively layout children
               for I in 1 .. Num_Children loop
                  Layout_Child (Active_Children (I).all);
               end loop;

               --  Second pass: if any child grew (e.g. text wrapping
               --  increased height), re-run flex layout with updated
               --  sizes so siblings shift.
               declare
                  Any_Grew : Boolean := False;
               begin
                  for I in 1 .. Num_Children loop
                     declare
                        Child_Geom : constant Rectangle :=
                           Get_Geometry (Active_Children (I).all);
                        Actual_Main : constant Pixel_Type := Get_Main_Size
                          ((Child_Geom.Width, Child_Geom.Height),
                           Style.Flex_Direction);
                        Assigned_Main : constant Pixel_Type := Get_Main_Size
                          ((Assigned(I).Width,
                            Assigned(I).Height),
                           Style.Flex_Direction);
                     begin
                        if Actual_Main > Assigned_Main then
                           Children_Info(I).Flex_Basis := Actual_Main;
                           Children_Info(I).Min_Main := Actual_Main;
                           Children_Info(I).Content_Main := Actual_Main;
                           Any_Grew := True;
                        end if;
                     end;
                  end loop;

                  if Any_Grew then
                     Compute_Flex_Layout(Context,
                       Children_Info (1 .. Num_Children));
                     declare
                        Rects2 : constant Rectangle_Array :=
                           Flex_To_Rectangles(Context,
                             Children_Info (1 .. Num_Children));
                     begin
                        for I in 1 .. Num_Children loop
                           Set_Geometry
                             (Active_Children (I).all, Rects2 (I));
                           Layout_Child (Active_Children (I).all);
                        end loop;
                     end;
                  end if;
               end;
            end;

            --  Apply relative offsets after flow layout
            for I in 1 .. Num_Children loop
               Apply_Relative_Offset (Active_Children (I).all, Content);
            end loop;
         end if;

         --  Position absolute children against the content box
         for I in 1 .. Abs_Index loop
            declare
               CS : constant Resolved_Style :=
                 Get_Resolved_Part_Style (Abs_Children (I).all, Main_Part);
            begin
               Position_Absolute_Child
                 (Abs_Children (I).all, CS, Content);
            end;
         end loop;
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
               if Main_Axis_Overflow (Container_Style, Container_Style.Flex_Direction) = Overflow_Visible
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
       if Is_Dirty (W) then
          --  Layout must have been called before this.
          --  Build items using the current geometry.
          Build_Items (W);
          Build_Label_Overlay (W);
          Apply_Styles_To_Items (W);
       end if;

       for Child of W.Children loop
          if Is_Dirty (Child.all) then
             Update (Child.all);
          end if;
       end loop;

       if Is_Dirty (W) then
          Mark_Clean (W);
       end if;
    end Update;

procedure Rebuild_All_Items (W : in out Widget'Class) is
begin
   Build_Items (W);
   Build_Label_Overlay (W);
   Apply_Styles_To_Items (W);

   for Child of W.Children loop
      Rebuild_All_Items (Child.all);
   end loop;
   Mark_Clean (W);
end Rebuild_All_Items;

procedure Rebuild_All_Items_W is new Wrap_CW_Proc (Rebuild_All_Items);
procedure Rebuild_All_Items (H : Widget_Handle)
  renames Rebuild_All_Items_W;


---------------------------------------------------------------------------
--  Layout_Child: lay out a single child and stamp the current epoch
--  so that Layout_Tree will not re-lay-out it.  Containers (flex, grid,
--  list_box, stack) should call this instead of bare Layout(Child.all).
---------------------------------------------------------------------------

procedure Layout_Child (Child : in out Widget'Class) is
begin
   Inc_Sat (Perf_Layout_Calls);
   Layout (Child);
   Child.Last_Layout_Epoch := Current_Layout_Epoch;
end Layout_Child;

---------------------------------------------------------------------------
--  Bump_Layout_Epoch: safely increment the global layout epoch counter.
--  Wraps to 1 (not 0) because 0 is the default value of
--  Last_Layout_Epoch in new widgets — wrapping to 0 would cause a
--  false cache hit for any widget that was never laid out.
---------------------------------------------------------------------------

procedure Bump_Layout_Epoch is
begin
   if Current_Layout_Epoch = Natural'Last then
      Current_Layout_Epoch := 1;
   else
      Current_Layout_Epoch := Current_Layout_Epoch + 1;
   end if;
end Bump_Layout_Epoch;

---------------------------------------------------------------------------
--  Layout_Tree_Impl: recursive layout with epoch-based duplicate
--  elimination.  Containers that call Layout_Child during their own
--  Layout stamp their children with the current epoch so that this
--  recursion skips the redundant call.
---------------------------------------------------------------------------

procedure Layout_Tree_Impl (W : in out Widget'Class) is
begin
   if not Widget_Participates (W) then
      W.Layout_Dirty := False;
      return;
   end if;

   if W.Last_Layout_Epoch = Current_Layout_Epoch then
      --  Already laid out by parent container in this epoch — skip.
      Inc_Sat (Perf_Layout_Skips);
   else
      Inc_Sat (Perf_Layout_Calls);
      Layout (W);
      W.Last_Layout_Epoch := Current_Layout_Epoch;
   end if;

   Update_Shared_Scroll_Layout (W);

   for Child of W.Children loop
      Layout_Tree_Impl (Child.all);
   end loop;
   W.Layout_Dirty := False;
end Layout_Tree_Impl;

---------------------------------------------------------------------------
--  Layout_Tree: public entry point.  Bumps the epoch once so that this
--  pass gets a fresh epoch distinct from any previous pass, then
--  delegates to Layout_Tree_Impl for recursive descent.  Every external
--  call (root, overlay, dialog subtree) gets its own epoch.
---------------------------------------------------------------------------

procedure Layout_Tree (W : in out Widget'Class) is
begin
   Bump_Layout_Epoch;
   Layout_Tree_Impl (W);
end Layout_Tree;

procedure Layout_Tree_W is new Wrap_CW_Proc (Layout_Tree);
procedure Layout_Tree (H : Widget_Handle) renames Layout_Tree_W;

---------------------------------------------------------------------------
--  Performance counter accessors
---------------------------------------------------------------------------

procedure Reset_Perf_Counters is
begin
   Perf_Style_Resolves := 0;
   Perf_Style_Hits     := 0;
   Perf_Layout_Calls   := 0;
   Perf_Layout_Skips   := 0;
   Perf_Pref_Calls     := 0;
   Perf_Pref_Hits      := 0;
end Reset_Perf_Counters;

function Get_Perf_Style_Resolves return Natural is (Perf_Style_Resolves);
function Get_Perf_Style_Hits return Natural is (Perf_Style_Hits);
function Get_Perf_Layout_Calls return Natural is (Perf_Layout_Calls);
function Get_Perf_Layout_Skips return Natural is (Perf_Layout_Skips);
function Get_Perf_Pref_Calls return Natural is (Perf_Pref_Calls);
function Get_Perf_Pref_Hits return Natural is (Perf_Pref_Hits);

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

            --  Apply interpolated style to all items of this part.
            --  Use a direct reference rename to avoid copying Cached_TTF_Text
            --  through Ada controlled-type assignment.
            for I in 1 .. Natural (W.Items.Length) loop
               declare
                  It : Item renames W.Items.Reference (I).Element.all;
               begin
                  if It.Part = P and then not It.Has_Style_Override then
                     It.Computed_Style := Interpolated;
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
      --  If any transition animates layout-affecting properties, trigger
      --  relayout; otherwise a render-only dirty is sufficient.
      declare
         Needs_Layout : Boolean := False;
      begin
         for P in Part_Kind loop
            if W.Transitions (P).Active then
               declare
                  Props : Property_Set renames
                    W.Transitions (P).Target_Style.Transition.Properties;
               begin
                  if Props (Prop_Padding) or else Props (Prop_Margin)
                    or else Props (Prop_Border_Width)
                    or else Props (Prop_Font_Size)
                  then
                     Needs_Layout := True;
                     exit;
                  end if;
               end;
            end if;
         end loop;
         if Needs_Layout then
            Mark_Dirty (W);
         else
            Mark_Render_Dirty (W);
         end if;
      end;
   end if;

   --  Recurse to children
   for Child of W.Children loop
      Tick_Animations (Child.all, DT);
   end loop;
end Tick_Animations;

end Adi.Widget;
