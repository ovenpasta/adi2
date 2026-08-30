--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Animation is

   ---------------------------------------------------------------------------
   --  Easing Functions
   ---------------------------------------------------------------------------

   function Apply_Easing (T : Float; E : Easing_Kind) return Float is
      Clamped : constant Float := Float'Min (1.0, Float'Max (0.0, T));
   begin
      case E is
         when Linear =>
            return Clamped;
         when Ease_In =>
            return Clamped * Clamped * Clamped;
         when Ease_Out =>
            declare
               Inv : constant Float := 1.0 - Clamped;
            begin
               return 1.0 - Inv * Inv * Inv;
            end;
         when Ease_In_Out =>
            if Clamped < 0.5 then
               return 4.0 * Clamped * Clamped * Clamped;
            else
               declare
                  Inv : constant Float := -2.0 * Clamped + 2.0;
               begin
                  return 1.0 - Inv * Inv * Inv / 2.0;
               end;
            end if;
      end case;
   end Apply_Easing;

   ---------------------------------------------------------------------------
   --  Lerp Helpers
   ---------------------------------------------------------------------------

   function Lerp_Float (A, B, T : Float) return Float is
   begin
      return A + (B - A) * T;
   end Lerp_Float;

   function Lerp_Natural (A, B : Natural; T : Float) return Natural is
      Result : constant Float := Float (A) + (Float (B) - Float (A)) * T;
   begin
      return Natural (Float'Max (0.0, Float'Min (255.0, Result)));
   end Lerp_Natural;

   function Lerp_Color (A, B : Color_Value; T : Float) return Color_Value is
      AR, AG, AB, BR, BG, BB : Natural;
      AA, BA : Float;
   begin
      Normalize_Color (A, AR, AG, AB, AA);
      Normalize_Color (B, BR, BG, BB, BA);
      return RGBA (Lerp_Natural (AR, BR, T),
                   Lerp_Natural (AG, BG, T),
                   Lerp_Natural (AB, BB, T),
                   Lerp_Float (AA, BA, T));
   end Lerp_Color;

   function Lerp_Length (A, B : Length_Value; T : Float) return Length_Value is
   begin
      if A.Unit = B.Unit then
         return (Amount => Lerp_Float (A.Amount, B.Amount, T), Unit => A.Unit);
      else
         --  Different units: snap at halfway
         if T < 0.5 then
            return A;
         else
            return B;
         end if;
      end if;
   end Lerp_Length;

   --  Expand CSS_Box_Value to per-side array
   function Expand_Box (V : CSS_Box_Value) return CSS_Box_Sides is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => V.All_Sides];
         when Axis =>
            return [Top => V.Vertical, Bottom => V.Vertical,
                    Left => V.Horizontal, Right => V.Horizontal];
         when Per_Side =>
            return V.Sides;
      end case;
   end Expand_Box;

   function Lerp_Box (A, B : CSS_Box_Value; T : Float) return CSS_Box_Value is
      SA : constant CSS_Box_Sides := Expand_Box (A);
      SB : constant CSS_Box_Sides := Expand_Box (B);
   begin
      return (Kind  => Per_Side,
              Sides => [for E in Edge =>
                           Lerp_Length (SA (E), SB (E), T)]);
   end Lerp_Box;

   --  Expand Border_Width_Value to per-edge array
   function Expand_Border_Width (V : Border_Width_Value) return Edge_Lengths is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => V.All_Edges];
         when Per_Edge =>
            return V.Edges;
      end case;
   end Expand_Border_Width;

   function Lerp_Border_Width (A, B : Border_Width_Value; T : Float) return Border_Width_Value is
      EA : constant Edge_Lengths := Expand_Border_Width (A);
      EB : constant Edge_Lengths := Expand_Border_Width (B);
   begin
      return (Kind  => Per_Edge,
              Edges => [for E in Edge =>
                           Lerp_Length (EA (E), EB (E), T)]);
   end Lerp_Border_Width;

   --  Expand Border_Color_Value to per-edge array
   function Expand_Border_Color (V : Border_Color_Value) return Edge_Colors is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => V.All_Edges];
         when Per_Edge =>
            return V.Edges;
      end case;
   end Expand_Border_Color;

   function Lerp_Border_Color (A, B : Border_Color_Value; T : Float) return Border_Color_Value is
      EA : constant Edge_Colors := Expand_Border_Color (A);
      EB : constant Edge_Colors := Expand_Border_Color (B);
   begin
      return (Kind  => Per_Edge,
              Edges => [for E in Edge =>
                           Lerp_Color (EA (E), EB (E), T)]);
   end Lerp_Border_Color;

   --  Expand Border_Radius_Value to per-corner array
   function Expand_Border_Radius (V : Border_Radius_Value) return Corner_Radii is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => V.All_Corners];
         when Per_Corner =>
            return V.Corners;
      end case;
   end Expand_Border_Radius;

   function Lerp_Border_Radius (A, B : Border_Radius_Value; T : Float) return Border_Radius_Value is
      CA : constant Corner_Radii := Expand_Border_Radius (A);
      CB : constant Corner_Radii := Expand_Border_Radius (B);
   begin
      return (Kind    => Per_Corner,
              Corners => [for C in Corner =>
                             Lerp_Length (CA (C), CB (C), T)]);
   end Lerp_Border_Radius;

   function Lerp_Box_Shadow (A, B : Box_Shadow_Value; T : Float) return Box_Shadow_Value is
   begin
      return (Offset_X      => Lerp_Length (A.Offset_X, B.Offset_X, T),
              Offset_Y      => Lerp_Length (A.Offset_Y, B.Offset_Y, T),
              Blur_Radius   => Lerp_Length (A.Blur_Radius, B.Blur_Radius, T),
              Spread_Radius => Lerp_Length (A.Spread_Radius, B.Spread_Radius, T),
              Color         => Lerp_Color (A.Color, B.Color, T));
   end Lerp_Box_Shadow;

   ---------------------------------------------------------------------------
   --  Interpolate
   ---------------------------------------------------------------------------

   --  Properties with no meaningful value in between: below the
   --  midpoint they read from the start style, above it from the
   --  target. Every literal is named, so a new property has to be
   --  decided here.
   Snaps_At_Midpoint : constant CSS_Property_Set :=
     [Prop_Border_Style | Prop_Font_Weight | Prop_Font_Style |
      Prop_Text_Align | Prop_Vertical_Align | Prop_Text_Decoration |
      Prop_List_Style_Type | Prop_List_Style_Image |
      Prop_List_Style_Position | Prop_White_Space | Prop_Text_Overflow |
      Prop_Text_Wrap_Mode | Prop_Display | Prop_Position |
      Prop_Overflow_X | Prop_Overflow_Y | Prop_Visibility | Prop_Cursor |
      Prop_Object_Fit | Prop_Object_Position | Prop_Flex_Direction |
      Prop_Flex_Wrap | Prop_Justify_Content | Prop_Align_Items |
      Prop_Align_Content | Prop_Align_Self
        => True,
      Prop_Color | Prop_Background_Color | Prop_Background_Image |
      Prop_Border_Radius | Prop_Border_Width | Prop_Border_Color |
      Prop_Outline_Width | Prop_Outline_Color | Prop_Outline_Style |
      Prop_Outline_Offset | Prop_Padding | Prop_Margin | Prop_Width |
      Prop_Height | Prop_Min_Width | Prop_Max_Width | Prop_Min_Height |
      Prop_Max_Height | Prop_Font_Family | Prop_Font_Size |
      Prop_Line_Height | Prop_Overflow | Prop_Top | Prop_Right |
      Prop_Bottom | Prop_Left | Prop_Opacity | Prop_Box_Shadow | Prop_Gap |
      Prop_Grid_Columns | Prop_Grid_Rows | Prop_Flex_Grow |
      Prop_Flex_Shrink | Prop_Flex_Basis | Prop_Order | Prop_Grid_Column |
      Prop_Grid_Row | Prop_Grid_Column_Span | Prop_Grid_Row_Span |
      Prop_Transition
        => False];

   function Interpolate (From, To : Resolved_Style;
                         T        : Float) return Resolved_Style is
      Result : Resolved_Style := To;  --  Start with target for non-animatable fields
      P      : Property_Set renames To.Transition.Properties;
   begin
      --  Only lerp properties that are in the transition's property set.
      --  Properties not in the set keep the target value (snap).

      --  Colors
      if P (Prop_Color) then
         Result.Color := Lerp_Color (From.Color, To.Color, T);
      end if;
      if P (Prop_Background_Color) then
         Result.Background_Color :=
            Lerp_Color (From.Background_Color, To.Background_Color, T);
      end if;

      --  Border
      if P (Prop_Border_Radius) then
         Result.Border_Radius :=
            Lerp_Border_Radius (From.Border_Radius, To.Border_Radius, T);
      end if;
      if P (Prop_Border_Width) then
         Result.Border_Width :=
            Lerp_Border_Width (From.Border_Width, To.Border_Width, T);
      end if;
      if P (Prop_Border_Color) then
         Result.Border_Color :=
            Lerp_Border_Color (From.Border_Color, To.Border_Color, T);
      end if;

      --  Spacing
      if P (Prop_Padding) then
         Result.Padding := Lerp_Box (From.Padding, To.Padding, T);
      end if;
      if P (Prop_Margin) then
         --  Auto margins cannot be interpolated; if either side is auto the
         --  result snaps to the From side (T < 0.5) or To side (T >= 0.5).
         Result.Margin :=
           [for E in Edge =>
              (if From.Margin (E).Kind = Auto or else To.Margin (E).Kind = Auto
               then (if T < 0.5 then From.Margin (E) else To.Margin (E))
               else Margin (Lerp_Length (From.Margin (E).Length,
                                         To.Margin (E).Length, T)))];
      end if;

      --  Visual
      if P (Prop_Opacity) then
         Result.Opacity := Opacity_Value (Float'Max (0.0, Float'Min (1.0,
            Lerp_Float (Float (From.Opacity), Float (To.Opacity), T))));
      end if;
      if P (Prop_Box_Shadow) then
         Result.Box_Shadow := Lerp_Box_Shadow (From.Box_Shadow, To.Box_Shadow, T);
      end if;

      --  Font size
      if P (Prop_Font_Size) then
         Result.Font_Size := Lerp_Length (From.Font_Size, To.Font_Size, T);
      end if;

      if T < 0.5 then
         for Prop in CSS_Property loop
            if Snaps_At_Midpoint (Prop) then
               Copy_Property (Prop, From, Result);
            end if;
         end loop;
      end if;

      --  Keep transition spec from target
      Result.Transition := To.Transition;

      return Result;
   end Interpolate;

   ---------------------------------------------------------------------------
   --  Advance
   ---------------------------------------------------------------------------

   procedure Start (PT       : in out Part_Transition;
                    From     : Resolved_Handle;
                    Target   : Resolved_Handle;
                    Duration : Float;
                    Easing   : Easing_Kind;
                    Started  : out Boolean) is
   begin
      if PT.Active and then PT.Slot /= No_Scratch then
         --  Carry on from where the running transition stands.
         Write (From_Cell (PT.Slot), Value (Current_Cell (PT.Slot)));
         PT.From := From_Cell (PT.Slot);
      else
         PT.Slot := Acquire_Scratch;
         if PT.Slot = No_Scratch then
            PT.Active := False;
            Started := False;
            return;
         end if;
         PT.From := From;
         Write (From_Cell (PT.Slot), Value (From));
      end if;

      Write (Current_Cell (PT.Slot), Value (PT.From));

      PT.Active := True;
      PT.Elapsed := 0.0;
      PT.Duration := Duration;
      PT.Easing := Easing;
      PT.Target := Target;
      Started := True;
   end Start;

   procedure Cancel (PT : in out Part_Transition) is
   begin
      PT.Active := False;
      Release_Scratch (PT.Slot);
      PT.From := PT.Target;
   end Cancel;

   procedure Advance (PT     : in out Part_Transition;
                      DT     : Float;
                      Result : out Resolved_Handle) is
   begin
      if not PT.Active then
         Result := PT.Target;
         return;
      end if;

      PT.Elapsed := PT.Elapsed + DT;

      if PT.Elapsed >= PT.Duration then
         --  Transition complete
         PT.Active := False;
         PT.Elapsed := PT.Duration;
         Release_Scratch (PT.Slot);
         PT.From := PT.Target;
         Result := PT.Target;
      else
         declare
            Raw_T   : constant Float := PT.Elapsed / PT.Duration;
            Eased   : constant Float := Apply_Easing (Raw_T, PT.Easing);
            Current : constant Resolved_Handle := Current_Cell (PT.Slot);
         begin
            Write (Current,
                   Interpolate (Ref (PT.From).all, Ref (PT.Target).all, Eased));
            Result := Current;
         end;
      end if;
   end Advance;

end Adi.Animation;
