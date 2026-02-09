pragma Ada_2022;

with Adi.CSS_Styles; use Adi.CSS_Styles;

package Adi.Animation is

   ---------------------------------------------------------------------------
   --  Easing Functions
   ---------------------------------------------------------------------------

   function Apply_Easing (T : Float; E : Easing_Kind) return Float;

   ---------------------------------------------------------------------------
   --  Part Transition State
   ---------------------------------------------------------------------------

   type Part_Transition is record
      Active       : Boolean := False;
      Elapsed      : Float := 0.0;
      Duration     : Float := 0.0;
      Easing       : Easing_Kind := Linear;
      From_Style   : Resolved_Style;
      Target_Style : Resolved_Style;
   end record;

   No_Part_Transition : constant Part_Transition := (Active => False, others => <>);

   ---------------------------------------------------------------------------
   --  Core API
   ---------------------------------------------------------------------------

   --  Advance a transition by DT seconds.
   --  Sets Result to the interpolated style at the current point.
   --  Sets Active to False when the transition completes.
   procedure Advance (PT     : in out Part_Transition;
                      DT     : Float;
                      Result : out Resolved_Style);

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
