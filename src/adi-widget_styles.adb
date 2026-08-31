--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Containers.Hashed_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Adi.Log;
with System;

package body Adi.Widget_Styles is

   ----------
   -- Hash --
   ----------

   function Hash (S : Style_Definition) return Ada.Containers.Hash_Type is
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
         Mix (Adi.Widget_Properties.Hash (Selector.Properties));
      end Mix;
   begin
      --  A rule-set handle stands for its value, interning being
      --  canonical, so the digest reads handles rather than the rule
      --  sets behind them.
      Mix (Ada.Containers.Hash_Type (Index (S.Base)));
      Mix (Ada.Containers.Hash_Type (S.Rule_Count));
      Mix (S.Widget_State_Mask);
      Mix (S.Part_State_Mask);

      --  Only the rules in use. Hashing the spare slots would be sound
      --  too, just wasted work.
      for I in 1 .. S.Rule_Count loop
         Mix (S.Rules (I).Selector);
         Mix (Ada.Containers.Hash_Type (Index (S.Rules (I).Style)));
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
      return Count + Adi.Widget_Properties.Condition_Count (Selector.Properties);
   end Specificity;

   -------------------------------------------------
   -- Widget Style Operations
   -------------------------------------------------

   function Same_Style (A, B : Style_Definition) return Boolean is
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

   procedure Add_Rule (WS : in out Style_Definition; Rule : State_Rule) is
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
     (WS : in out Style_Definition; Rule : State_Rule; Added : out Boolean) is
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
                           Active_Part   : Widget_States;
                           Assigned : Adi.Widget_Properties.Property_Assignment
                             := Adi.Widget_Properties.Empty_Assignment)
     return Style_Rules is
      Def    : constant Style_Definition := Definition (WS);
      Result : Style_Rules := Rules_Of (Def.Base);

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
      for I in 1 .. Def.Rule_Count loop
         if Matches (Def.Rules (I).Selector, Active_Widget, Active_Part,
                     Assigned)
         then
            Match_Count := Match_Count + 1;
            Matched (Match_Count) := (
               Index    => I,
               Priority => (if Def.Rules (I).Priority > 0
                           then Def.Rules (I).Priority
                           else Specificity (Def.Rules (I).Selector))
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
         Result :=
           Merge (Result, Rules_Ref (Def.Rules (Matched (I).Index).Style).all);
      end loop;

      return Result;
   end Compute_Style;

   function Compute_Style (WS : Widget_Style;
                           Active : Widget_States;
                           Assigned : Adi.Widget_Properties.Property_Assignment
                             := Adi.Widget_Properties.Empty_Assignment)
     return Style_Rules is
   begin
      return Compute_Style (WS, Active, No_States, Assigned);
   end Compute_Style;

   function Compute_Resolved (WS : Widget_Style;
                              Active_Widget : Widget_States;
                              Active_Part   : Widget_States;
                              Assigned : Adi.Widget_Properties.Property_Assignment
                                := Adi.Widget_Properties.Empty_Assignment)
     return Resolved_Style is
   begin
      return Resolve
        (Compute_Style (WS, Active_Widget, Active_Part, Assigned));
   end Compute_Resolved;

   function Compute_Resolved (WS : Widget_Style;
                              Active : Widget_States;
                              Assigned : Adi.Widget_Properties.Property_Assignment
                                := Adi.Widget_Properties.Empty_Assignment)
     return Resolved_Style is
   begin
      return Resolve (Compute_Style (WS, Active, Assigned));
   end Compute_Resolved;

   -------------------------------------------------
   -- The Style Store
   -------------------------------------------------

   type Rule_Index_Array is array (Positive range <>) of Positive;

   --  A style as the store keeps it, sized to the rules it names.
   --  Ordered indexes Rules in cascade order: priority ascending,
   --  source order ascending within a priority.
   type Prepared_Style_Entry (Rule_Count : Natural) is record
      Base              : Rules_Handle  := Empty_Rules;
      Widget_State_Mask : Widget_States := No_States;
      Part_State_Mask   : Widget_States := No_States;
      --  Whether any rule names a widget property. A widget setting one
      --  where no rule reads it changes nothing, and this is what says
      --  so without resolving.
      Uses_Property     : Boolean       := False;
      Rules             : State_Rule_Array (1 .. Rule_Count);
      Ordered           : Rule_Index_Array (1 .. Rule_Count);
   end record;

   type Prepared_Style_Entry_Access is access constant Prepared_Style_Entry;

   function Prepare_Style (S : Style_Definition) return Prepared_Style_Entry is
      Priorities : array (Positive range 1 .. Max_Style_Rules) of Natural :=
        [others => 0];
   begin
      return Result : Prepared_Style_Entry (Rule_Count => S.Rule_Count) do
         Result.Base := S.Base;
         Result.Widget_State_Mask := S.Widget_State_Mask;
         Result.Part_State_Mask := S.Part_State_Mask;
         Result.Uses_Property := False;

         --  Precompute a stable rule order: priority asc, source order asc.
         for I in 1 .. S.Rule_Count loop
            Result.Rules (I) := S.Rules (I);
            Result.Ordered (I) := I;
            if Adi.Widget_Properties.Condition_Count
                 (S.Rules (I).Selector.Properties) > 0
            then
               Result.Uses_Property := True;
            end if;
            Priorities (I) :=
              (if S.Rules (I).Priority > 0
               then S.Rules (I).Priority
               else Specificity (S.Rules (I).Selector));
         end loop;

         for I in 2 .. S.Rule_Count loop
            declare
               Key_Index : constant Positive := Result.Ordered (I);
               Key_Prio  : constant Natural := Priorities (I);
               J         : Natural := I;
            begin
               while J > 1 loop
                  declare
                     Prev_Index : constant Positive := Result.Ordered (J - 1);
                     Prev_Prio  : constant Natural := Priorities (J - 1);
                  begin
                     exit when Prev_Prio < Key_Prio
                       or else (Prev_Prio = Key_Prio
                                and then Prev_Index < Key_Index);

                     Result.Ordered (J) := Prev_Index;
                     Priorities (J) := Prev_Prio;
                     J := J - 1;
                  end;
               end loop;

               Result.Ordered (J) := Key_Index;
               Priorities (J) := Key_Prio;
            end;
         end loop;
      end return;
   end Prepare_Style;

   Empty_Prepared_Style : aliased constant Prepared_Style_Entry :=
     Prepare_Style (Empty_Style_Definition);

   package Style_Entry_Ptr_Vectors is new Ada.Containers.Vectors
     (Positive, Prepared_Style_Entry_Access);

   Style_Store : Style_Entry_Ptr_Vectors.Vector;

   --  Handles grouped by style hash, so interning probes a handful of
   --  candidates instead of the whole store. Keyed by hash rather than
   --  by definition: the map would otherwise hold a second copy of each.
   package Handle_Vectors is new Ada.Containers.Vectors
     (Positive, Widget_Style);

   function Same_Hash (H : Ada.Containers.Hash_Type)
     return Ada.Containers.Hash_Type is (H);

   package Style_Index_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Ada.Containers.Hash_Type,
      Element_Type    => Handle_Vectors.Vector,
      Hash            => Same_Hash,
      Equivalent_Keys => Ada.Containers."=",
      "="             => Handle_Vectors."=");

   Style_Index : Style_Index_Maps.Map;

   Interned_Style_Count : Natural := 0;
   Interned_Style_Byte_Count : Natural := 0;

   function Interned_Styles return Natural is (Interned_Style_Count);
   function Interned_Style_Bytes return Natural is (Interned_Style_Byte_Count);

   function Index (S : Widget_Style) return Natural is (Natural (S));

   function Entry_From_Handle (H : Widget_Style)
     return Prepared_Style_Entry_Access is
   begin
      if H = Empty_Widget_Style
        or else Natural (H) > Natural (Style_Store.Length)
      then
         return Empty_Prepared_Style'Access;
      end if;
      return Style_Store.Element (Positive (H));
   end Entry_From_Handle;

   --  Same_Style against the stored form, over the live rules alone.
   function Same_Prepared
     (E : Prepared_Style_Entry; S : Style_Definition) return Boolean is
   begin
      if E.Rule_Count /= S.Rule_Count
        or else E.Widget_State_Mask /= S.Widget_State_Mask
        or else E.Part_State_Mask /= S.Part_State_Mask
        or else E.Base /= S.Base
      then
         return False;
      end if;

      for I in 1 .. E.Rule_Count loop
         if E.Rules (I) /= S.Rules (I) then
            return False;
         end if;
      end loop;

      return True;
   end Same_Prepared;

   function Definition (S : Widget_Style) return Style_Definition is
      Prepared : constant Prepared_Style_Entry_Access :=
        Entry_From_Handle (S);
   begin
      return Result : Style_Definition do
         Result.Base := Prepared.Base;
         Result.Rule_Count := Prepared.Rule_Count;
         Result.Widget_State_Mask := Prepared.Widget_State_Mask;
         Result.Part_State_Mask := Prepared.Part_State_Mask;
         for I in 1 .. Prepared.Rule_Count loop
            Result.Rules (I) := Prepared.Rules (I);
         end loop;
      end return;
   end Definition;

   function Intern (D : Style_Definition) return Widget_Style is
   begin
      if Same_Style (D, Empty_Style_Definition) then
         return Empty_Widget_Style;
      end if;

      declare
         Key      : constant Ada.Containers.Hash_Type := Hash (D);
         Bucket   : constant Style_Index_Maps.Cursor := Style_Index.Find (Key);
         Interned : Widget_Style;
      begin
         if Style_Index_Maps.Has_Element (Bucket) then
            for H of Style_Index_Maps.Element (Bucket) loop
               if Same_Prepared (Style_Store.Element (Positive (H)).all, D)
               then
                  return H;
               end if;
            end loop;
         end if;

         Style_Store.Append (new Prepared_Style_Entry'(Prepare_Style (D)));
         Interned := Widget_Style (Style_Store.Length);
         Interned_Style_Count := Natural (Style_Store.Length);
         Interned_Style_Byte_Count := Interned_Style_Byte_Count
           + Style_Store.Last_Element.all'Size / System.Storage_Unit;

         if Style_Index_Maps.Has_Element (Bucket) then
            Style_Index.Reference (Bucket).Append (Interned);
         else
            declare
               Fresh : Handle_Vectors.Vector;
            begin
               Fresh.Append (Interned);
               Style_Index.Insert (Key, Fresh);
            end;
         end if;

         return Interned;
      end;
   end Intern;

   function Uses_Widget_State
     (WS : Widget_Style; S : Widget_State) return Boolean is
     (Entry_From_Handle (WS).Widget_State_Mask (S));

   function Uses_Part_State
     (WS : Widget_Style; S : Widget_State) return Boolean is
     (Entry_From_Handle (WS).Part_State_Mask (S));

   function Uses_Properties (WS : Widget_Style) return Boolean is
     (Entry_From_Handle (WS).Uses_Property);

   function Compute_Style_Prepared
     (WS            : Widget_Style;
      Active_Widget : Widget_States;
      Active_Part   : Widget_States;
      Assigned      : Adi.Widget_Properties.Property_Assignment
        := Adi.Widget_Properties.Empty_Assignment)
     return Style_Rules
   is
      Prepared : constant Prepared_Style_Entry_Access :=
        Entry_From_Handle (WS);
      Result   : Style_Rules := Rules_Of (Prepared.Base);
   begin
      for I in 1 .. Prepared.Rule_Count loop
         declare
            Rule_Slot : constant Positive := Prepared.Ordered (I);
         begin
            if Matches (Prepared.Rules (Rule_Slot).Selector,
                        Active_Widget,
                        Active_Part,
                        Assigned)
            then
               Result :=
                 Merge (Result,
                        Rules_Ref (Prepared.Rules (Rule_Slot).Style).all);
            end if;
         end;
      end loop;
      return Result;
   end Compute_Style_Prepared;

   -------------------------------------------------
   -- Fluent Builder Implementation
   -------------------------------------------------

   function Create return Style_Builder is
   begin
      return (WS => Empty_Style_Definition);
   end Create;

   function From (Base : Style_Rules) return Style_Builder is
   begin
      return (WS => (Base => Intern_Rules (Base), others => <>));
   end From;

   function Base (B : Style_Builder; S : Style_Rules) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Result.WS.Base := Intern_Rules (S);
      return Result;
   end Base;

   function On (B : Style_Builder; Sel : State_Selector; S : Style_Rules) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Add_Rule (Result.WS,
                (Selector => Sel, Style => Intern_Rules (S), Priority => 0));
      return Result;
   end On;

   function On (B : Style_Builder;
                Sel : State_Selector;
                S : Style_Rules;
                Priority : Natural) return Style_Builder is
      Result : Style_Builder := B;
   begin
      Add_Rule (Result.WS,
                (Selector => Sel,
                 Style    => Intern_Rules (S),
                 Priority => Priority));
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
   begin
      return B.With_Transition (Duration, All_Properties, Easing);
   end With_Transition;

   function With_Transition (B          : Style_Builder;
                             Duration   : Float;
                             Properties : Property_Set;
                             Easing     : Easing_Kind := Ease_In_Out) return Style_Builder is
      Result : Style_Builder := B;
      Rules  : Style_Rules := Rules_Of (B.WS.Base);
   begin
      Rules.Transition := Set ((Duration   => Duration,
                                Easing     => Easing,
                                Properties => Properties));
      Result.WS.Base := Intern_Rules (Rules);
      return Result;
   end With_Transition;

   function Build (B : Style_Builder) return Widget_Style is
   begin
      return Intern (B.WS);
   end Build;

end Adi.Widget_Styles;
