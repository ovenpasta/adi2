--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Resolved_Styles; use Adi.Resolved_Styles;

package Adi.Animation is

   ---------------------------------------------------------------------------
   --  Easing Functions
   ---------------------------------------------------------------------------

   function Apply_Easing (T : Float; E : Easing_Kind) return Float;

   ---------------------------------------------------------------------------
   --  Part Transition State
   ---------------------------------------------------------------------------

   --  Where a part stands between two styles. The styles themselves sit
   --  in the resolved-style store and, while the transition runs, in a
   --  scratch slot, so the record is a handful of scalars.
   type Part_Transition is record
      Active   : Boolean := False;
      Elapsed  : Float := 0.0;
      Duration : Float := 0.0;
      Easing   : Easing_Kind := Linear;
      Slot     : Scratch_Slot := No_Scratch;
      From     : Resolved_Handle := Default_Handle;
      Target   : Resolved_Handle := Default_Handle;
   end record;

   No_Part_Transition : constant Part_Transition := (Active => False, others => <>);

   ---------------------------------------------------------------------------
   --  Core API
   ---------------------------------------------------------------------------

   --  Aims a part at Target over Duration seconds. A transition already
   --  running carries on from where it stands. Started is False when the
   --  scratch pool has no slot left, and the caller then assigns the
   --  target directly, as a part with a zero duration does.
   procedure Start (PT       : in out Part_Transition;
                    From     : Resolved_Handle;
                    Target   : Resolved_Handle;
                    Duration : Float;
                    Easing   : Easing_Kind;
                    Started  : out Boolean);

   --  Stops a transition and returns its scratch slot to the pool.
   procedure Cancel (PT : in out Part_Transition);

   --  Advance a transition by DT seconds.
   --  Sets Result to the style at the current point: a scratch cell
   --  while the transition runs, the target once it completes.
   --  Sets Active to False when the transition completes.
   procedure Advance (PT     : in out Part_Transition;
                      DT     : Float;
                      Result : out Resolved_Handle);

   --  Interpolate all animatable fields between From and To at parameter T (0..1)
   function Interpolate (From, To : Resolved_Style;
                         T        : Float) return Resolved_Style;

   ---------------------------------------------------------------------------
   --  Lerp Helpers
   ---------------------------------------------------------------------------

   function Lerp_Float (A, B, T : Float) return Float;
   function Lerp_Color (A, B : Color_Value; T : Float) return Color_Value;
   function Lerp_Length (A, B : Length_Value; T : Float) return Length_Value;
   function Lerp_Box (A, B : CSS_Box_Value; T : Float) return CSS_Box_Value;
   function Lerp_Border_Width (A, B : Border_Width_Value; T : Float) return Border_Width_Value;
   function Lerp_Border_Color (A, B : Border_Color_Value; T : Float) return Border_Color_Value;
   function Lerp_Border_Radius (A, B : Border_Radius_Value; T : Float) return Border_Radius_Value;
   function Lerp_Box_Shadow (A, B : Box_Shadow_Value; T : Float) return Box_Shadow_Value;

end Adi.Animation;
