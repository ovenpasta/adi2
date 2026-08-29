--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Adi.Log;

package body Adi.Widget_Styles is

   ----------
   -- Hash --
   ----------

   function Hash (S : Widget_Style) return Ada.Containers.Hash_Type is
      use type Ada.Containers.Hash_Type;

      --  FNV-1a over a stream of small numbers.
      H : Ada.Containers.Hash_Type := 16#811C_9DC5#;

      procedure Mix (Value : Ada.Containers.Hash_Type) is
         Rest : Ada.Containers.Hash_Type := Value;
      begin
         for Unused_Byte in 1 .. 4 loop
            H := (H xor (Rest and 16#FF#)) * 16#0100_0193#;
            Rest := Rest / 256;
         end loop;
      end Mix;

      procedure Mix (Flag : Boolean) is
      begin
         Mix (if Flag then 1 else 0);
      end Mix;

      procedure Mix (States : Widget_States) is
      begin
         for St in Widget_State loop
            Mix (States (St));
         end loop;
      end Mix;

      procedure Mix (Selector : State_Selector) is
      begin
         Mix (Selector.Widget_Required);
         Mix (Selector.Widget_Excluded);
         Mix (Selector.Part_Required);
         Mix (Selector.Part_Excluded);
      end Mix;

      procedure Mix (Named : CSS_Property_Set) is
      begin
         for P in CSS_Property loop
            Mix (Named (P));
         end loop;
      end Mix;
   begin
      Mix (Set_Properties (S.Base));
      Mix (Ada.Containers.Hash_Type (S.Rule_Count));
      Mix (S.Widget_State_Mask);
      Mix (S.Part_State_Mask);

      --  Only the rules in use. Hashing the spare slots would be sound
      --  too, just wasted work.
      for I in 1 .. S.Rule_Count loop
         Mix (S.Rules (I).Selector);
         Mix (Set_Properties (S.Rules (I).Style));
         Mix (Ada.Containers.Hash_Type (S.Rules (I).Priority));
      end loop;

      return H;
   end Hash;

   -----------------
   -- Specificity --
   -----------------

   function Specificity (Selector : State_Selector) return Natural is
      Count : Natural := 0;
   begin
      for S in Widget_State loop
         if Selector.Widget_Required (S) then Count := Count + 1; end if;
         if Selector.Widget_Excluded (S) then Count := Count + 1; end if;
         if Selector.Part_Required (S) then Count := Count + 1; end if;
         if Selector.Part_Excluded (S) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Specificity;

   -------------------------------------------------
   -- Widget Style Operations
   -------------------------------------------------

   function Same_Style (A, B : Widget_Style) return Boolean is
   begin
      if A.Rule_Count /= B.Rule_Count
        or else A.Widget_State_Mask /= B.Widget_State_Mask
        or else A.Part_State_Mask /= B.Part_State_Mask
        or else A.Base /= B.Base
      then
         return False;
      end if;

      for I in 1 .. A.Rule_Count loop
         if A.Rules (I) /= B.Rules (I) then
            return False;
         end if;
      end loop;

      return True;
   end Same_Style;

   --  How a state selector reads in a diagnostic.
   function Selector_Image (Selector : State_Selector) return String;

   function Selector_Image (Selector : State_Selector) return String is
      Result : Unbounded_String;

      function Name (S : Widget_State) return String is
         Prefix : constant String := "state_";
         Image  : constant String :=
           Ada.Characters.Handling.To_Lower (Widget_State'Image (S));
      begin
         if Image'Length > Prefix'Length
           and then Image (Image'First .. Image'First + Prefix'Length - 1)
                      = Prefix
         then
            return Image (Image'First + Prefix'Length .. Image'Last);
         end if;
         return Image;
      end Name;

      procedure Append_States (Required, Excluded : Widget_States;
                               Prefix             : String) is
      begin
         for S in Widget_State loop
            if Required (S) then
               Append (Result, Prefix & ":" & Name (S));
            end if;
            if Excluded (S) then
               Append (Result, Prefix & ":not(" & Name (S) & ")");
            end if;
         end loop;
      end Append_States;

   begin
      Append_States (Selector.Widget_Required, Selector.Widget_Excluded, "");
      Append_States (Selector.Part_Required, Selector.Part_Excluded, "::part");

      if Length (Result) = 0 then
         return "any state";
      end if;

      return To_String (Result);
   end Selector_Image;

   procedure Add_Rule (WS : in out Widget_Style; Rule : State_Rule) is
   begin
      if WS.Rule_Count >= Max_Style_Rules then
         raise Too_Many_Style_Rules with
           "style already holds" & Max_Style_Rules'Image
           & " state rules, no room for " & Selector_Image (Rule.Selector);
      end if;

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

   procedure Try_Add_Rule
     (WS : in out Widget_Style; Rule : State_Rule; Added : out Boolean) is
   begin
      Added := WS.Rule_Count < Max_Style_Rules;

      if Added then
         Add_Rule (WS, Rule);
      else
         Dropped_Rule_Count := Dropped_Rule_Count + 1;
         Adi.Log.Error
           ("style rule dropped: already at" & Max_Style_Rules'Image
            & " state rules, no room for " & Selector_Image (Rule.Selector));
      end if;
   end Try_Add_Rule;

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
