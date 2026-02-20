pragma Ada_2022;

package body Adi.Widget_Styles is

   -------------------------------------------------
   -- Widget Style Operations
   -------------------------------------------------

   procedure Add_Rule (WS : in out Widget_Style; Rule : State_Rule) is
   begin
      WS.Rule_Count := WS.Rule_Count + 1;
      WS.Rules (WS.Rule_Count) := Rule;
      --  Accumulate state relevance masks for fast-reject
      for S in Widget_State loop
         if Rule.Selector.Widget_Required (S)
            or else Rule.Selector.Widget_Excluded (S)
         then
            WS.Widget_State_Mask (S) := True;
         end if;
         if Rule.Selector.Part_Required (S)
            or else Rule.Selector.Part_Excluded (S)
         then
            WS.Part_State_Mask (S) := True;
         end if;
      end loop;
   end Add_Rule;

   function Compute_Style (WS : Widget_Style;
                           Active_Widget : Widget_States;
                           Active_Part   : Widget_States) return Style_Rules is
      Result : Style_Rules := WS.Base;
      
      --  Collect matching rules with their effective priority
      type Scored_Rule is record
         Index    : Positive;
         Priority : Natural;
      end record;
      
      type Scored_Array is array (1 .. Max_Style_Rules) of Scored_Rule;
      
      Matched : Scored_Array;
      Match_Count : Natural := 0;
   begin
      --  Find all matching rules
      for I in 1 .. WS.Rule_Count loop
         if Matches (WS.Rules (I).Selector, Active_Widget, Active_Part) then
            Match_Count := Match_Count + 1;
            Matched (Match_Count) := (
               Index    => I,
               Priority => (if WS.Rules (I).Priority > 0 
                           then WS.Rules (I).Priority
                           else Specificity (WS.Rules (I).Selector))
            );
         end if;
      end loop;
      
      --  Sort by priority (simple bubble sort, fine for small N)
      for I in 1 .. Match_Count - 1 loop
         for J in I + 1 .. Match_Count loop
            if Matched (J).Priority < Matched (I).Priority then
               declare
                  Tmp : constant Scored_Rule := Matched (I);
               begin
                  Matched (I) := Matched (J);
                  Matched (J) := Tmp;
               end;
            end if;
         end loop;
      end loop;
      
      --  Apply rules in priority order (lowest first, highest wins)
      for I in 1 .. Match_Count loop
         Result := Merge (Result, WS.Rules (Matched (I).Index).Style);
      end loop;
      
      return Result;
   end Compute_Style;

   function Compute_Style (WS : Widget_Style; Active : Widget_States) return Style_Rules is
   begin
      return Compute_Style (WS, Active, No_States);
   end Compute_Style;

   function Compute_Resolved (WS : Widget_Style;
                              Active_Widget : Widget_States;
                              Active_Part   : Widget_States) return Resolved_Style is
   begin
      return Resolve (Compute_Style (WS, Active_Widget, Active_Part));
   end Compute_Resolved;

   function Compute_Resolved (WS : Widget_Style; Active : Widget_States) return Resolved_Style is
   begin
      return Resolve (Compute_Style (WS, Active));
   end Compute_Resolved;

   -------------------------------------------------
   -- Fluent Builder Implementation
   -------------------------------------------------

   function Create return Style_Builder is
   begin
      return (WS => Empty_Widget_Style);
   end Create;

   function From (Base : Style_Rules) return Style_Builder is
   begin
      return (WS => (Base => Base, others => <>));
   end From;

   function Base (B : Style_Builder; S : Style_Rules) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Result.WS.Base := S;
      return Result;
   end Base;

   function On (B : Style_Builder; Sel : State_Selector; S : Style_Rules) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Add_Rule (Result.WS, (Selector => Sel, Style => S, Priority => 0));
      return Result;
   end On;

   function On (B : Style_Builder;
                Sel : State_Selector;
                S : Style_Rules;
                Priority : Natural) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Add_Rule (Result.WS, (Selector => Sel, Style => S, Priority => Priority));
      return Result;
   end On;

   function On_Normal (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Normal, S);
   end On_Normal;

   function On_Hover (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Hovered, S);
   end On_Hover;

   function On_Press (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Pressed, S);
   end On_Press;

   function On_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Focused, S);
   end On_Focus;

   function On_Disabled (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Disabled, S);
   end On_Disabled;

   function On_Selected (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Selected, S);
   end On_Selected;

   function On_Hover_And_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Hover_And_Focus, S);
   end On_Hover_And_Focus;

   function On_Press_And_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (When_State (State_Pressed) and When_State (State_Focused), S);
   end On_Press_And_Focus;

   function On_Hover_Not_Disabled (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (Sel_Hover_Not_Disabled, S);
   end On_Hover_Not_Disabled;

   function On_Selected_And_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder is
   begin
      return B.On (When_State (State_Selected) and When_State (State_Focused), S);
   end On_Selected_And_Focus;

   function With_Transition (B : Style_Builder;
                             Duration : Float;
                             Easing   : Easing_Kind := Ease_In_Out) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Result.WS.Base.Transition := Set ((Duration   => Duration,
                                         Easing     => Easing,
                                         Properties => All_Properties));
      return Result;
   end With_Transition;

   function With_Transition (B          : Style_Builder;
                             Duration   : Float;
                             Properties : Property_Set;
                             Easing     : Easing_Kind := Ease_In_Out) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Result.WS.Base.Transition := Set ((Duration   => Duration,
                                         Easing     => Easing,
                                         Properties => Properties));
      return Result;
   end With_Transition;

   function Build (B : Style_Builder) return Widget_Style is
   begin
      return B.WS;
   end Build;

end Adi.Widget_Styles;
