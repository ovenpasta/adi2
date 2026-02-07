
with Ada.Containers.Ordered_Maps;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Adi.Core; use Adi.Core;
with Adi.Font;
with Adi.Layout_Util; use Adi.Layout_Util;
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

   ---------------------------------------------------------------------------
   --  Shadow Texture Cache
   ---------------------------------------------------------------------------

   type Shadow_Cache_Key is record
      Blur_Px       : Natural;
      Corner_Radius : Natural;
      Color_R       : Uint8;
      Color_G       : Uint8;
      Color_B       : Uint8;
      Color_A       : Uint8;
   end record;

   function "<" (L, R : Shadow_Cache_Key) return Boolean is
   begin
      if L.Blur_Px /= R.Blur_Px then return L.Blur_Px < R.Blur_Px; end if;
      if L.Corner_Radius /= R.Corner_Radius then return L.Corner_Radius < R.Corner_Radius; end if;
      if L.Color_R /= R.Color_R then return L.Color_R < R.Color_R; end if;
      if L.Color_G /= R.Color_G then return L.Color_G < R.Color_G; end if;
      if L.Color_B /= R.Color_B then return L.Color_B < R.Color_B; end if;
      return L.Color_A < R.Color_A;
   end "<";

   package Shadow_Maps is new Ada.Containers.Ordered_Maps
      (Key_Type => Shadow_Cache_Key, Element_Type => SDL_Texture_Ptr);

   Shadow_Cache : Shadow_Maps.Map;
   Max_Shadow_Cache_Size : constant := 32;

   ---------------------------------------------------------------------------
   --  Generate_Shadow_Texture
   ---------------------------------------------------------------------------

   function Generate_Shadow_Texture
      (Renderer : SDL_Renderer_Ptr;
       Key      : Shadow_Cache_Key) return SDL_Texture_Ptr
   is
      Blur   : constant Natural := Key.Blur_Px;
      Radius : constant Natural := Key.Corner_Radius;

      --  Texture size: 3-pass box blur extends 3*Blur from shape edge
      Pad : constant Natural := 3 * Blur;
      Tex_Size : constant Natural :=
         Natural'Max (4, 2 * (Pad + Radius) + 4);
      Total_Px : constant Natural := Tex_Size * Tex_Size;

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
         --  Rasterize: the rounded rect shape is centered in the texture,
         --  with Blur pixels of padding on each side.
         declare
            Pad      : constant Float := Float (3 * Blur);
            Rect_Sz  : constant Float := Float (Tex_Size) - 2.0 * Pad;
            Half_X   : constant Float := Rect_Sz / 2.0;
            Half_Y   : constant Float := Rect_Sz / 2.0;
            Center_X : constant Float := Float (Tex_Size) / 2.0;
            Center_Y : constant Float := Float (Tex_Size) / 2.0;
            CR       : constant Float := Float'Min (Float (Radius),
                                                    Float'Min (Half_X, Half_Y));
         begin
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
                        A := Key.Color_A;
                     else
                        A := 0;
                     end if;
                     Pixels (Y * Pitch + X) :=
                        Pack_Pixel (Key.Color_R, Key.Color_G, Key.Color_B, A);
                  end;
               end loop;
            end loop;
         end;

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
                        Pack_Pixel (Key.Color_R, Key.Color_G, Key.Color_B, A);
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
      (Renderer : SDL_Renderer_Ptr;
       Geom     : Rectangle;
       Style    : Resolved_Style)
   is
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

      --  Get shadow color
      SR, SG, SB, SA : Uint8;

      Key     : Shadow_Cache_Key;
      Texture : SDL_Texture_Ptr;
      Success : Adi.SDL.C_bool;

      --  9-grid border = full blur extent (3*blur) + corner_radius
      Grid_Border : constant Float := Float (3 * Blur_Px + Max_Rad);

      --  Destination rect: widget rect expanded by spread + blur, offset
      Dst : aliased SDL_FRect;
   begin
      CSS_Color_To_SDL (Shadow.Color, SR, SG, SB, SA);

      if SA = 0 then
         return;  --  Fully transparent shadow
      end if;

      Key := (Blur_Px       => Blur_Px,
              Corner_Radius => Max_Rad,
              Color_R       => SR,
              Color_G       => SG,
              Color_B       => SB,
              Color_A       => SA);

      --  Cache lookup or generate
      declare
         use Shadow_Maps;
         Pos : constant Cursor := Shadow_Cache.Find (Key);
      begin
         if Pos /= No_Element then
            Texture := Element (Pos);
         else
            --  Evict oldest if cache is full
            if Natural (Shadow_Cache.Length) >= Max_Shadow_Cache_Size then
               declare
                  First_Pos : Cursor := Shadow_Cache.First;
                  Old_Tex   : constant SDL_Texture_Ptr := Element (First_Pos);
               begin
                  SDL_DestroyTexture (Old_Tex);
                  Shadow_Cache.Delete (First_Pos);
               end;
            end if;

            Texture := Generate_Shadow_Texture (Renderer, Key);
            if Texture = null then
               return;
            end if;
            Shadow_Cache.Insert (Key, Texture);
         end if;
      end;

      --  Compute destination rect
      declare
         Expand_Amt : constant Float := Spread_Px + Float (3 * Blur_Px);
      begin
         Dst.x := Float (Geom.X) - Expand_Amt + Offset_X;
         Dst.y := Float (Geom.Y) - Expand_Amt + Offset_Y;
         Dst.w := Float (Geom.Width) + 2.0 * Expand_Amt;
         Dst.h := Float (Geom.Height) + 2.0 * Expand_Amt;
      end;

      --  Render using 9-grid stretching
      Success := SDL_RenderTexture9Grid
         (Renderer      => Renderer,
          Texture       => Texture,
          Srcrect       => null,
          Left_Width    => Grid_Border,
          Right_Width   => Grid_Border,
          Top_Height    => Grid_Border,
          Bottom_Height => Grid_Border,
          Scale         => 1.0,
          Dstrect       => Dst'Access);
   end Render_Box_Shadow;

   ---------------------------------------------------------------------------
   --  Widget State Management
   ---------------------------------------------------------------------------

   procedure Set_State (W : in out Widget'Class;
                        S : Widget_State;
                        Active : Boolean) is
      Was_Active : constant Boolean := W.States (S);
   begin
      if Was_Active /= Active then
         W.States (S) := Active;
         On_State_Changed (W, S, Active);
      end if;

      Mark_Dirty (W);
   end Set_State;

   function Has_State (W : Widget'Class; S : Widget_State) return Boolean is
   begin
      return W.States (S);
   end Has_State;

   function Get_States (W : Widget'Class) return Widget_States is
   begin
      return W.States;
   end Get_States;

   procedure Clear_States (W : in out Widget'Class) is
   begin
      W.States := No_States;
      Mark_Dirty (W);
   end Clear_States;

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
         return Compute_Style (W.Part_Styles (Any_Part).Style, W.States);
      end if;

      return Compute_Style (W.Part_Styles (P).Style, W.States);
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
   begin
      for I in 1 .. Natural (W.Items.Length) loop
         declare
            Current_Item : Item := W.Items.Element (I);
         begin
            Current_Item.Computed_Style := Get_Resolved_Part_Style (W, Current_Item.Part);
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

   ---------------------------------------------------------------------------
   --  Hierarchy Management
   ---------------------------------------------------------------------------

   procedure Add_Child (W : in out Widget'Class; C : Widget_Access) is
   begin
      if C /= null then
         W.Children.Append (C);
         C.Parent := W'Unchecked_Access;
         Mark_Dirty (W);
      end if;
   end Add_Child;

   procedure Remove_Child (W : in out Widget'Class; C : Widget_Access) is
      use Widget_List;
      Cursor : Widget_List.Cursor := W.Children.Find (C);
   begin
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
         P.Children.Append (W'Unchecked_Access);
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
      W.Dirty := True;
   end On_State_Changed;

   procedure On_Geometry_Changed (W : in out Widget'Class) is
   begin
      Mark_Dirty (W);
   end On_Geometry_Changed;


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
                        Z_Order : Natural := 0) return Item is
   begin
      return (Kind           => Image_Item,
              Geometry       => Geometry,
              Part           => Part,
              Z_Order        => Z_Order,
              Computed_Style => Default_Resolved,
              Image_Source   => Source,
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
      BW_Top     : Float;
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
      Has_Border := BW_Top > 0.0;

      --  Set up outer rectangle geometry
      Rect.x := Float (Geom.X);
      Rect.y := Float (Geom.Y);
      Rect.w := Float (Geom.Width);
      Rect.h := Float (Geom.Height);

      --  Strategy for rounded border: draw the full outer rect in the
      --  border color first, then draw the inner rect (inset by border
      --  width) in the background color on top.  This gives clean,
      --  uniform borders without triangle-strip artefacts.

      if Has_Radius then
         --  1) Draw border fill (outer rounded rect with border color)
         if Has_Border then
            case Style.Border_Color.Kind is
               when Gap_Uniform =>
                  CSS_Color_To_SDL (Style.Border_Color.All_Edges, R, G, B, A);
               when Per_Edge =>
                  CSS_Color_To_SDL (Style.Border_Color.Edges (Top), R, G, B, A);
            end case;
            Render_Rounded_Rect (Renderer, Rect, Max_Rad, R, G, B, A);
         end if;

         --  2) Draw background (inner rounded rect)
         if Style.Background_Color.Kind /= Named
            or else Style.Background_Color.Name /= Transparent
         then
            CSS_Color_To_SDL (Style.Background_Color, R, G, B, A);

            if Has_Border then
               --  Inset rect by border width on all sides
               declare
                  Inner : constant SDL_FRect :=
                     (x => Rect.x + BW_Top,
                      y => Rect.y + BW_Top,
                      w => Float'Max (0.0, Rect.w - 2.0 * BW_Top),
                      h => Float'Max (0.0, Rect.h - 2.0 * BW_Top));
                  Inner_Rad : constant Float :=
                     Float'Max (0.0, Max_Rad - BW_Top);
               begin
                  if Inner.w > 0.0 and then Inner.h > 0.0 then
                     Render_Rounded_Rect
                        (Renderer, Inner, Inner_Rad, R, G, B, A);
                  end if;
               end;
            else
               Render_Rounded_Rect (Renderer, Rect, Max_Rad, R, G, B, A);
            end if;
         end if;

      else
         --  No border radius: use fast SDL rect primitives

         --  Background
         if Style.Background_Color.Kind /= Named
            or else Style.Background_Color.Name /= Transparent
         then
            CSS_Color_To_SDL (Style.Background_Color, R, G, B, A);
            SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                        "SDL_SetRenderDrawColor");
            SDL_Assert (SDL_RenderFillRect (Renderer, Rect'Access),
                        "SDL_RenderFillRect");
         end if;

         --  Border
         if Has_Border then
            case Style.Border_Color.Kind is
               when Gap_Uniform =>
                  CSS_Color_To_SDL (Style.Border_Color.All_Edges, R, G, B, A);
               when Per_Edge =>
                  CSS_Color_To_SDL (Style.Border_Color.Edges (Top), R, G, B, A);
            end case;
            SDL_Assert (SDL_SetRenderDrawColor (Renderer, R, G, B, A),
                        "SDL_SetRenderDrawColor");
            SDL_Assert (SDL_RenderRect (Renderer, Rect'Access),
                        "SDL_RenderRect");
         end if;
      end if;
   end Render_Panel;

   --  Global text engine (created once per renderer)
   Global_Text_Engine : TTF_TextEngine_Access := null;

   procedure Render_Text_Item (
      Renderer : SDL_Renderer_Ptr;
      It       : in out Item)
   is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Content  : constant String := To_String (It.Text_Content);
      Style    : Resolved_Style renames It.Computed_Style;
      Geom     : Rectangle renames It.Geometry;
      Text_Obj : TTF_Text_Access;
      Font     : TTF_Font_Access;
      C_Text   : chars_ptr;
      Font_Sz  : Float;
      R, G, B, A : Uint8;
      Success  : Adi.SDL.C_bool;
   begin
      if Style.Visibility = Visibility_Hidden or else Content'Length = 0 then
         return;
      end if;

      --  Create text engine if not already created
      if Global_Text_Engine = null then
         Global_Text_Engine := TTF_CreateRendererTextEngine (Renderer);
         if Global_Text_Engine = null then
            Ada.Text_IO.Put_Line ("ERROR: Failed to create text engine");
            return;
         end if;
      end if;

      --  Calculate font size
      Font_Sz := Float (Length_To_Px (Style.Font_Size, Container_Size => Geom.Height));
      if Font_Sz = 0.0 then
         Font_Sz := 16.0;
      end if;

      --  Get the correctly-sized font from the cache
      Font := Adi.Font.Get_TTF_Font (Style.Font_Family, Font_Sz);
      if Font = null then
         return;
      end if;

      --  Reuse or create cached text object
      Text_Obj := It.Cached_TTF_Text;

      if Text_Obj = null then
         --  First time: create text object
         C_Text := New_String (Content);
         Text_Obj := TTF_CreateText (Global_Text_Engine, Font, C_Text,
                                     size_t (Content'Length));
         Free (C_Text);

         if Text_Obj = null then
            Ada.Text_IO.Put_Line ("ERROR: Failed to create text object");
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

      --  Set text color
      CSS_Color_To_SDL (Style.Color, R, G, B, A);
      Success := TTF_SetTextColor (Text_Obj, R, G, B, A);

      --  Set wrap width if needed
      if Geom.Width > 0.0 then
         Success := TTF_SetTextWrapWidth (Text_Obj, int (Geom.Width));
      end if;

      --  Draw the text
      Success := TTF_DrawRendererText (Text_Obj, C_float (Geom.X), C_float (Geom.Y));
   end Render_Text_Item;

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
      Success          : Adi.SDL.C_bool;
   begin
      if Style.Visibility = Visibility_Hidden then
         return;
      end if;

      if Source = null or else not Is_Valid (Source.all) then
         return;
      end if;

      --  Get the SDL texture from the image
      Texture := Get_Texture (Source.all);
      if Texture = null then
         return;
      end if;

      --  Get image size (already cached in the Image object)
      Get_Size (Source.all, Src_W, Src_H);
      if Src_W = 0.0 or Src_H = 0.0 then
         return;
      end if;

      case Style.Object_Fit is
         when Fit_Fill =>
            Dst_X := Geom.X;
            Dst_Y := Geom.Y;
            Dst_W := Geom.Width;
            Dst_H := Geom.Height;

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

         when Fit_Cover =>
            Scale_X := Float (Geom.Width) / Float (Src_W);
            Scale_Y := Float (Geom.Height) / Float (Src_H);
            declare
               S : constant Float := Float'Max (Scale_X, Scale_Y);
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
            if Pixel_Type (Src_W) > Geom.Width or Pixel_Type (Src_H) > Geom.Height then
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
            Dst_X := Geom.X + Length_To_Px (Style.Object_Position.X_Offset, Geom.Width);
            Dst_Y := Geom.Y + Length_To_Px (Style.Object_Position.Y_Offset, Geom.Height);
      end case;

      --  Set up destination rectangle
      Dst_Rect.x := Float (Dst_X);
      Dst_Rect.y := Float (Dst_Y);
      Dst_Rect.w := Float (Dst_W);
      Dst_Rect.h := Float (Dst_H);

      --  Set texture alpha modulation for opacity
      Success := SDL_SetTextureAlphaModFloat (Texture, Float (Style.Opacity));

      --  Render the texture
      Success := SDL_RenderTexture (Renderer, Texture, null, Dst_Rect'Access);
   end Render_Image_Item;

   procedure Render_Background_Image (
      Renderer : SDL_Renderer_Ptr;
      Geom     : Rectangle;
      Style    : Resolved_Style)
   is
   begin
      case Style.Background_Image.Kind is
         when No_Image =>
            return;
         when Picture_Image =>
            if Style.Background_Image.Image /= null then
               Render_Image_Item (Renderer, Geom, Style.Background_Image.Image, Style);
            end if;
         when Url_Image =>
            null;
      end case;
   end Render_Background_Image;

   ---------------------------------------------------------------------------
   --  Public Rendering Interface
   ---------------------------------------------------------------------------

   procedure Render_Items (W : in out Widget'Class; Renderer : SDL_Renderer_Ptr) is
   begin
      for I in 1 .. Natural (W.Items.Length) loop
         declare
            Current : Item renames W.Items.Reference (I).Element.all;
            Style   : Resolved_Style renames Current.Computed_Style;
         begin
            case Current.Kind is
               when Panel_Item =>
                  if Style.Box_Shadow /= No_Shadow then
                     Render_Box_Shadow (Renderer, Current.Geometry, Style);
                  end if;
                  Render_Panel (Renderer, Current.Geometry, Style);
                  Render_Background_Image (Renderer, Current.Geometry, Style);

               when Text_Item =>
                  Render_Text_Item (Renderer, Current);

               when Image_Item =>
                  Render_Image_Item (
                     Renderer,
                     Current.Geometry,
                     Current.Image_Source,
                     Style);
            end case;
         end;
      end loop;
   end Render_Items;

   procedure Render_Tree (W : in out Widget'Class; Renderer : SDL_Renderer_Ptr) is
   begin
      if not Has_Flag (W, Visible) then
         return;
      end if;

      Render_Items (W, Renderer);

      for Child of W.Children loop
         Render_Tree (Child.all, Renderer);
      end loop;
   end Render_Tree;

   procedure Update_And_Render (W : in out Widget'Class; Renderer : SDL_Renderer_Ptr) is
   begin
      Update (W);
      Render_Tree (W, Renderer);
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
                  --  Get image dimensions
                  if Current.Image_Source /= null and then Is_Valid(Current.Image_Source.all) then
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
               Ada.Text_IO.Put_Line ("  == Second pass check ==");
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
                     Ada.Text_IO.Put_Line
                       ("    child" & Recheck_Idx'Image
                        & " assigned_main=" & Integer'Image (Integer (Assigned_Main))
                        & " actual_main=" & Integer'Image (Integer (Actual_Main))
                        & " geom=(" & Integer'Image (Integer (Child_Geom.X))
                        & "," & Integer'Image (Integer (Child_Geom.Y))
                        & "," & Integer'Image (Integer (Child_Geom.Width))
                        & "," & Integer'Image (Integer (Child_Geom.Height)) & ")");
                     if Actual_Main > Assigned_Main then
                        Ada.Text_IO.Put_Line
                          ("    >>> GREW: updating basis/min/content");
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

               Ada.Text_IO.Put_Line
                 ("  == Any_Grew=" & Any_Grew'Image & " ==");

               if Any_Grew then
                  Compute_Flex_Layout(Context, Children_Info);
                  declare
                     Rects2 : constant Rectangle_Array :=
                        Flex_To_Rectangles(Context, Children_Info);
                     Rect_Idx2 : Positive := 1;
                  begin
                     for Child of W.Children loop
                        Ada.Text_IO.Put_Line
                          ("    re-assign child" & Rect_Idx2'Image
                           & " rect=(" & Integer'Image (Integer (Rects2(Rect_Idx2).X))
                           & "," & Integer'Image (Integer (Rects2(Rect_Idx2).Y))
                           & "," & Integer'Image (Integer (Rects2(Rect_Idx2).Width))
                           & "," & Integer'Image (Integer (Rects2(Rect_Idx2).Height)) & ")");
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
      use Ada.Text_IO;

      Num_Items : constant Natural := Natural (Items.Length);
   begin
      --  Preconditions
      pragma Assert (Container_Geom.Width >= 0.0,
         "Container width must be non-negative");
      pragma Assert (Container_Geom.Height >= 0.0,
         "Container height must be non-negative");

      --  Debug output
      Put_Line ("=== Perform_Item_Flex_Layout ===");
      Put_Line ("  Container: X=" & Integer'Image(Integer(Container_Geom.X))
         & " Y=" & Integer'Image(Integer(Container_Geom.Y))
         & " W=" & Integer'Image(Integer(Container_Geom.Width))
         & " H=" & Integer'Image(Integer(Container_Geom.Height)));
      Put_Line ("  Direction: " & Container_Style.Flex_Direction'Image);
      Put_Line ("  Num Items: " & Num_Items'Image);

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

            --  Debug output for each item
            Put_Line ("  Item " & Index'Image & ":");
            Put_Line ("    Input: Content=" & Integer'Image(Integer(Item.Content_Width))
               & "x" & Integer'Image(Integer(Item.Content_Height)));
            Put_Line ("    Output: X=" & Integer'Image(Integer(Item.Geometry.X))
               & " Y=" & Integer'Image(Integer(Item.Geometry.Y))
               & " W=" & Integer'Image(Integer(Item.Geometry.Width))
               & " H=" & Integer'Image(Integer(Item.Geometry.Height)));

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


-- Add to Adi.Widget body:
procedure Layout_Tree (W : in out Widget'Class) is
begin
   Layout (W);  -- Layout this widget (computes children geometry)
   for Child of W.Children loop
      Layout_Tree (Child.all);  -- Recurse
   end loop;
   Mark_Clean (W);
end Layout_Tree;

end Adi.Widget;