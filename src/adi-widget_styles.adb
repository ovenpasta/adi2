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

   use type Chain_Refs.Var_Access;

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

   -------------------------------------------------
   -- Composer Implementation
   -------------------------------------------------

   function Open_Chains return Natural is (Chain_Pool.Held);
   function Reclaimed_Chains return Natural is (Reclaimed_Chain_Count);
   function Dropped_Chain_Slots return Natural is (Dropped_Slot_Count);

   --  The reports the chain makes. Each builds a message, which is what
   --  spends the secondary stack, so they stand apart from the steps
   --  below that carry Local_Restrictions.
   procedure Report_Reclaimed is
   begin
      Adi.Log.Error
        ("style chain buffer taken back: all" & Max_Open_Chains'Image
         & " were held, so the one held longest was reclaimed -- a chain "
         & "somewhere ended in neither .Build nor .Discard");
   end Report_Reclaimed;

   --  Said at the call site that got the wrong answer, which is where
   --  someone debugging is looking. Report_Reclaimed says it at the
   --  chain that did the evicting; this says it at the one evicted.
   procedure Report_Built_After_Reclaim is
   begin
      Adi.Log.Error
        ("style chain built with no buffer: it was taken back before "
         & ".Build, so the properties this chain named did not apply and "
         & "it answered the style it opened on");
   end Report_Built_After_Reclaim;

   procedure Report_Uncomposable (P : CSS_Property) is
   begin
      Adi.Log.Error
        ("no composed form for CSS property " & CSS_Property'Image (P));
   end Report_Uncomposable;

   procedure Report_Full_Buffer (P : CSS_Property) is
   begin
      Adi.Log.Error
        ("style chain already holds" & Max_Chain_Slots'Image
         & " properties, no room for " & CSS_Property'Image (P));
   end Report_Full_Buffer;

   procedure Report_Full_Rules is
   begin
      Adi.Log.Error
        ("style chain already holds" & Max_Style_Rules'Image
         & " state rules, no room for another");
   end Report_Full_Rules;

   -------------------------------------------------
   -- The buffer ledger
   -------------------------------------------------

   --  Which hand-out of each buffer is live and when the pool made it,
   --  so a chain that finds every buffer held can take back the oldest.
   --  Taken_At is zero for a buffer the pool holds free.
   --
   --  Reclaimed_Serial is the hand-out this buffer was last taken back
   --  from, which is what lets .Build tell a chain whose buffer was
   --  reclaimed from one that has simply already built: both find no
   --  buffer, and only the first matches here. It remembers one
   --  hand-out per buffer, so a second reclaim of the same buffer
   --  forgets the first -- which costs a report, never a wrong one.
   type Chain_Record is record
      Serial           : Natural := 0;
      Taken_At         : Natural := 0;
      Reclaimed_Serial : Natural := 0;
   end record;

   Chain_Ledger : array (1 .. Max_Open_Chains) of Chain_Record :=
     [others => (others => <>)];

   --  Orders the buffers held now, and nothing else, so it is renumbered
   --  rather than allowed to climb. It resets whenever the pool goes
   --  empty, which is every chain in ordinary use; Restamp_Held covers
   --  what that misses -- one buffer leaked beside steady traffic leaves
   --  the pool never empty and never full, so the clock would otherwise
   --  climb until Natural'Last aborted on it. Adi.Slot_Pool's own Serial
   --  is bounded the other way, by 2**31 hand-outs of a single slot.
   Chain_Clock : Natural := 0;

   --  Renumbers the held buffers to 1 .. Max_Open_Chains in the order
   --  they were taken. Only their order matters and there are never
   --  more than Max_Open_Chains of them, so this is exact.
   procedure Restamp_Held
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   procedure Restamp_Held is
      Done   : array (Chain_Ledger'Range) of Boolean := [others => False];
      Ranked : Natural := 0;
   begin
      loop
         declare
            Pick    : Natural := 0;
            Pick_At : Natural := 0;
         begin
            for I in Chain_Ledger'Range loop
               if not Done (I)
                 and then Chain_Ledger (I).Taken_At /= 0
                 and then (Pick = 0
                           or else Chain_Ledger (I).Taken_At < Pick_At)
               then
                  Pick := I;
                  Pick_At := Chain_Ledger (I).Taken_At;
               end if;
            end loop;

            exit when Pick = 0;

            Done (Pick) := True;
            Ranked := Ranked + 1;
            Chain_Ledger (Pick).Taken_At := Ranked;
         end;
      end loop;

      Chain_Clock := Ranked;
   end Restamp_Held;

   procedure Note_Taken (S : Chain_Pool.Slot)
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   procedure Note_Taken (S : Chain_Pool.Slot) is
   begin
      if Chain_Clock = Natural'Last then
         Restamp_Held;
      end if;

      Chain_Clock := Chain_Clock + 1;
      Chain_Ledger (Chain_Pool.Ordinal (S)) :=
        (Serial           => Chain_Pool.Serial (S),
         Taken_At         => Chain_Clock,
         Reclaimed_Serial =>
           Chain_Ledger (Chain_Pool.Ordinal (S)).Reclaimed_Serial);
   end Note_Taken;

   --  Released says the pool held the slot under this name and let it
   --  go. A caller that acts on a release -- counting it, or reporting
   --  capacity freed -- asks rather than assumes.
   procedure Return_Buffer
     (S : in out Chain_Pool.Slot; Released : out Boolean)
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   procedure Return_Buffer
     (S : in out Chain_Pool.Slot; Released : out Boolean) is
   begin
      Released := Chain_Pool.Live (S);

      if Released then
         Chain_Ledger (Chain_Pool.Ordinal (S)).Taken_At := 0;
      end if;

      Chain_Pool.Release (S);

      --  Nothing is held, so no Taken_At is meaningful and the clock
      --  can start again.
      if Chain_Pool.Held = 0 then
         Chain_Clock := 0;
      end if;
   end Return_Buffer;

   --  Takes back the buffer held longest, and answers whether it took
   --  one. Acquire raises that buffer's serial, so the chain it came
   --  from reads as holding none rather than as sharing this one.
   function Reclaim_Oldest return Boolean
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   function Reclaim_Oldest return Boolean is
      Ord    : Natural := 0;
      Oldest : Natural := 0;
   begin
      for I in Chain_Ledger'Range loop
         if Chain_Ledger (I).Taken_At /= 0
           and then (Ord = 0 or else Chain_Ledger (I).Taken_At < Oldest)
         then
            Ord := I;
            Oldest := Chain_Ledger (I).Taken_At;
         end if;
      end loop;

      if Ord = 0 then
         return False;
      end if;

      declare
         Victim   : constant Natural := Chain_Ledger (Ord).Serial;
         Held     : Chain_Pool.Slot := Chain_Pool.Named (Ord, Victim);
         Released : Boolean;
      begin
         Return_Buffer (Held, Released);

         --  The ledger named a hand-out the pool no longer held, so
         --  nothing was freed and there is no reclaim to count.
         if not Released then
            return False;
         end if;

         Chain_Ledger (Ord).Reclaimed_Serial := Victim;
      end;

      Reclaimed_Chain_Count := Reclaimed_Chain_Count + 1;
      return True;
   end Reclaim_Oldest;

   function Slot_Bytes return Natural is (Slot'Max_Size_In_Storage_Elements);
   function Composer_Bytes return Natural is
     (Composer'Max_Size_In_Storage_Elements);

   --  The buffer the composer names, or No_Slot when it names none.
   function Where (C : Composer) return Chain_Pool.Slot
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   function Where (C : Composer) return Chain_Pool.Slot is
     (Chain_Pool.Named (Natural (C.Ordinal), C.Serial));

   function Is_Live (C : Composer) return Boolean is
     (Chain_Pool.Live (Where (C)));

   --  Whether this hand-out is the one the ledger records as taken
   --  back, which separates a reclaimed chain from one already built.
   function Was_Reclaimed (C : Composer) return Boolean
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   function Was_Reclaimed (C : Composer) return Boolean is
     (C.Serial /= 0
      and then Natural (C.Ordinal) in Chain_Ledger'Range
      and then Chain_Ledger (Natural (C.Ordinal)).Reclaimed_Serial
                 = C.Serial);

   function To_Chain (Sel : State_Selector) return Chain_Selector is
     ((Widget_Required => Sel.Widget_Required,
       Widget_Excluded => Sel.Widget_Excluded,
       Part_Required   => Sel.Part_Required,
       Part_Excluded   => Sel.Part_Excluded,
       Properties      => Sel.Properties));

   function To_Selector (S : Chain_Selector) return State_Selector is
     ((Widget_Required => S.Widget_Required,
       Widget_Excluded => S.Widget_Excluded,
       Part_Required   => S.Part_Required,
       Part_Excluded   => S.Part_Excluded,
       Properties      => S.Properties));

   function Take_Buffer (Seed : Widget_Style; Reclaimed : out Boolean)
     return Composer
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   function Take_Buffer (Seed : Widget_Style; Reclaimed : out Boolean)
     return Composer
   is
      Taken : Chain_Pool.Slot := Chain_Pool.Acquire;
   begin
      Reclaimed := False;

      if not Chain_Pool.Live (Taken) then
         Reclaimed := Reclaim_Oldest;
         Taken := Chain_Pool.Acquire;
      end if;

      if not Chain_Pool.Live (Taken) then
         --  Nothing was held and nothing is free, which asks a pool of
         --  no capacity. Every step is a no-op and .Build answers Seed.
         return (Serial => 0, Seed => Seed, Ordinal => 0, Active => 0);
      end if;

      Note_Taken (Taken);

      declare
         B : constant Chain_Refs.Var_Access := Chain_Refs.Mutable (Taken);
      begin
         B.Count := 0;
         B.Rule_Count := 0;
         B.Dropped := False;
      end;

      return (Serial  => Chain_Pool.Serial (Taken),
              Seed    => Seed,
              Ordinal => Chain_Ordinal (Chain_Pool.Ordinal (Taken)),
              Active  => 0);
   end Take_Buffer;

   function Open (Seed : Widget_Style) return Composer is
      Reclaimed : Boolean;
      Result    : constant Composer := Take_Buffer (Seed, Reclaimed);
   begin
      if Reclaimed then
         Report_Reclaimed;
      end if;
      return Result;
   end Open;

   function Style_Of return Composer is (Open (Empty_Widget_Style));

   function Style_Of (Base : Widget_Style) return Composer is (Open (Base));

   procedure Discard (C : in out Composer) is
      Held            : Chain_Pool.Slot := Where (C);
      Unused_Released : Boolean;
   begin
      Return_Buffer (Held, Unused_Released);
      C := (Serial => 0, Seed => C.Seed, Ordinal => 0, Active => 0);
   end Discard;

   --  One chain step: the slot every setter shares. Split so the write
   --  carries the restrictions and the reporting, which builds a message
   --  and so spends the secondary stack, sits outside them. A call is
   --  charged to its caller unless the callee declares the restriction
   --  too, which is why the two are separate subprograms rather than one
   --  with an if.
   type Step_Outcome is
     (Stored, No_Buffer, Not_Composable, Buffer_Full, Dropped_Quietly);

   function Append_Step (C       : Composer;
                         P       : CSS_Property;
                         Op      : Slot_Op;
                         Val     : Value_Ref;
                         Outcome : out Step_Outcome) return Composer
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   function Append_Step (C       : Composer;
                         P       : CSS_Property;
                         Op      : Slot_Op;
                         Val     : Value_Ref;
                         Outcome : out Step_Outcome) return Composer
   is
      B : constant Chain_Refs.Var_Access := Chain_Refs.Mutable (Where (C));
   begin
      if B = null then
         Outcome := No_Buffer;
         return C;
      end if;

      if not Composable_Properties (P) then
         Outcome := Not_Composable;
         return C;
      end if;

      if B.Count >= Max_Chain_Slots then
         Dropped_Slot_Count := Dropped_Slot_Count + 1;
         Outcome := (if B.Dropped then Dropped_Quietly else Buffer_Full);
         B.Dropped := True;
         return C;
      end if;

      B.Count := B.Count + 1;
      B.Slots (B.Count) :=
        (Rule => C.Active, Prop => P, Op => Op, Val => Val);
      Outcome := Stored;
      return C;
   end Append_Step;

   function Append (C   : Composer;
                    P   : CSS_Property;
                    Op  : Slot_Op;
                    Val : Value_Ref) return Composer
   is
      Outcome : Step_Outcome;
      Result  : constant Composer := Append_Step (C, P, Op, Val, Outcome);
   begin
      case Outcome is
         when Stored | No_Buffer | Dropped_Quietly => null;
         when Not_Composable => Report_Uncomposable (P);
         when Buffer_Full    => Report_Full_Buffer (P);
      end case;
      return Result;
   end Append;

   function Set_Slot (C : Composer; P : CSS_Property; Val : Value_Ref)
     return Composer is (Append (C, P, Set_Value, Val));

   function Clear (C : Composer; P : CSS_Property) return Composer is
     (Append (C, P, Clear_Value, No_Value_Ref));

   -------------------------------------------------
   -- Moving the active rule
   -------------------------------------------------

   function On (C : Composer; Sel : State_Selector) return Composer is
      B    : constant Chain_Refs.Var_Access := Chain_Refs.Mutable (Where (C));
      Want : constant Chain_Selector := To_Chain (Sel);
   begin
      if B = null then
         return C;
      end if;

      for I in 1 .. B.Rule_Count loop
         if B.Selectors (I) = Want then
            return (C with delta Active => Rule_Slot (I));
         end if;
      end loop;

      if B.Rule_Count >= Max_Style_Rules then
         Report_Full_Rules;
         return C;
      end if;

      B.Rule_Count := B.Rule_Count + 1;
      B.Selectors (B.Rule_Count) := Want;
      return (C with delta Active => Rule_Slot (B.Rule_Count));
   end On;

   function On_Base (C : Composer) return Composer is
     ((C with delta Active => 0));

   function On_Normal (C : Composer) return Composer is (C.On (Sel_Normal));
   function On_Hover (C : Composer) return Composer is (C.On (Sel_Hovered));
   function On_Press (C : Composer) return Composer is (C.On (Sel_Pressed));
   function On_Focus (C : Composer) return Composer is (C.On (Sel_Focused));
   function On_Disabled (C : Composer) return Composer is
     (C.On (Sel_Disabled));
   function On_Selected (C : Composer) return Composer is
     (C.On (Sel_Selected));

   -------------------------------------------------
   -- Setters
   -------------------------------------------------

   function Text_Color (C : Composer; V : Color_Value) return Composer is
     (Set_Slot (C, Prop_Color, Intern (V)));

   function Background (C : Composer; V : Color_Value) return Composer is
     (Set_Slot (C, Prop_Background_Color, Intern (V)));

   function Radius (C : Composer; V : Border_Radius_Value) return Composer is
     (Set_Slot (C, Prop_Border_Radius, Intern (V)));

   function Border_Width (C : Composer; V : Border_Width_Value)
     return Composer is (Set_Slot (C, Prop_Border_Width, Intern (V)));

   function Border_Color (C : Composer; V : Border_Color_Value)
     return Composer is (Set_Slot (C, Prop_Border_Color, Intern (V)));

   function Border_Style (C : Composer; V : Border_Style_Value)
     return Composer is (Set_Slot (C, Prop_Border_Style, Intern (V)));

   function Outline_Width (C : Composer; V : Length_Value) return Composer is
     (Set_Slot (C, Prop_Outline_Width, Intern (V)));

   function Outline_Color (C : Composer; V : Color_Value) return Composer is
     (Set_Slot (C, Prop_Outline_Color, Intern (V)));

   function Outline_Offset (C : Composer; V : Length_Value) return Composer is
     (Set_Slot (C, Prop_Outline_Offset, Intern (V)));

   function Padding (C : Composer; V : CSS_Box_Value) return Composer is
     (Set_Slot (C, Prop_Padding, Intern (V)));

   function Margin (C : Composer; V : CSS_Box_Value) return Composer is
     (Set_Slot (C, Prop_Margin, Intern (V)));

   function Width (C : Composer; V : Size_Value) return Composer is
     (Set_Slot (C, Prop_Width, Intern (V)));

   function Height (C : Composer; V : Size_Value) return Composer is
     (Set_Slot (C, Prop_Height, Intern (V)));

   function Min_Width (C : Composer; V : Size_Value) return Composer is
     (Set_Slot (C, Prop_Min_Width, Intern (V)));

   function Max_Width (C : Composer; V : Size_Value) return Composer is
     (Set_Slot (C, Prop_Max_Width, Intern (V)));

   function Min_Height (C : Composer; V : Size_Value) return Composer is
     (Set_Slot (C, Prop_Min_Height, Intern (V)));

   function Max_Height (C : Composer; V : Size_Value) return Composer is
     (Set_Slot (C, Prop_Max_Height, Intern (V)));

   function Font_Size (C : Composer; V : Length_Value) return Composer is
     (Set_Slot (C, Prop_Font_Size, Intern (V)));

   function Font_Weight (C : Composer; V : Font_Weight_Value)
     return Composer is (Set_Slot (C, Prop_Font_Weight, Intern (V)));

   function Text_Align (C : Composer; V : Text_Align_Value) return Composer is
     (Set_Slot (C, Prop_Text_Align, Intern (V)));

   function Text_Wrap_Mode (C : Composer; V : Text_Wrap_Mode_Value)
     return Composer is (Set_Slot (C, Prop_Text_Wrap_Mode, Intern (V)));

   function Display (C : Composer; V : Display_Value) return Composer is
     (Set_Slot (C, Prop_Display, Intern (V)));

   function Overflow_X (C : Composer; V : Overflow_Value) return Composer is
     (Set_Slot (C, Prop_Overflow_X, Intern (V)));

   function Overflow_Y (C : Composer; V : Overflow_Value) return Composer is
     (Set_Slot (C, Prop_Overflow_Y, Intern (V)));

   function Opacity (C : Composer; V : Opacity_Value) return Composer is
     (Set_Slot (C, Prop_Opacity, Intern (V)));

   function Cursor_Style (C : Composer; V : Cursor_Value) return Composer is
     (Set_Slot (C, Prop_Cursor, Intern (V)));

   function Box_Shadow (C : Composer; V : Box_Shadow_Value) return Composer is
     (Set_Slot (C, Prop_Box_Shadow, Intern (V)));

   function Flex_Direction (C : Composer; V : Flex_Direction_Value)
     return Composer is (Set_Slot (C, Prop_Flex_Direction, Intern (V)));

   function Justify_Content (C : Composer; V : Justify_Content_Value)
     return Composer is (Set_Slot (C, Prop_Justify_Content, Intern (V)));

   function Align_Items (C : Composer; V : Align_Items_Value)
     return Composer is (Set_Slot (C, Prop_Align_Items, Intern (V)));

   function Gap (C : Composer; V : Gap_Value) return Composer is
     (Set_Slot (C, Prop_Gap, Intern (V)));

   function Flex_Grow (C : Composer; V : Flex_Grow_Value) return Composer is
     (Set_Slot (C, Prop_Flex_Grow, Intern (V)));

   function Flex_Shrink (C : Composer; V : Flex_Shrink_Value)
     return Composer is (Set_Slot (C, Prop_Flex_Shrink, Intern (V)));

   function Transition (C : Composer; V : Transition_Spec) return Composer is
     (Set_Slot (C, Prop_Transition, Intern (V)));

   -------------------------------------------------
   -- Building
   -------------------------------------------------

   --  Folds the slots naming rule K into the rule set that rule already
   --  carries, and re-interns it. One Style_Rules is live at a time,
   --  which is where the chain's whole materialisation cost sits.
   procedure Fold_Rule
     (Def : in out Style_Definition; K : Rule_Slot; B : Chain_Buffer)
   is
      Target : Natural := 0;  --  index into Def.Rules; 0 is the base
      Source : Rules_Handle;
   begin
      if K = 0 then
         Source := Def.Base;
      else
         declare
            Sel   : constant State_Selector :=
              To_Selector (B.Selectors (Natural (K)));
            Added : Boolean;
         begin
            for I in 1 .. Def.Rule_Count loop
               if Def.Rules (I).Selector = Sel then
                  Target := I;
                  exit;
               end if;
            end loop;

            if Target = 0 then
               Try_Add_Rule
                 (Def,
                  (Selector => Sel, Style => Empty_Rules, Priority => 0),
                  Added);
               if not Added then
                  return;
               end if;
               Target := Def.Rule_Count;
            end if;

            Source := Def.Rules (Target).Style;
         end;
      end if;

      declare
         R : Style_Rules := Rules_Of (Source);
      begin
         for I in 1 .. B.Count loop
            if B.Slots (I).Rule = K then
               case B.Slots (I).Op is
                  when Set_Value =>
                     Apply_Property (R, B.Slots (I).Prop, B.Slots (I).Val);
                  when Clear_Value =>
                     Clear_Property (R, B.Slots (I).Prop);
               end case;
            end if;
         end loop;

         if K = 0 then
            Def.Base := Intern_Rules (R);
         else
            Def.Rules (Target).Style := Intern_Rules (R);
         end if;
      end;
   end Fold_Rule;

   function Build (C : Composer) return Widget_Style is
      B      : constant Chain_Refs.Var_Access := Chain_Refs.Mutable (Where (C));
      Held   : Chain_Pool.Slot := Where (C);
      Result : Widget_Style := C.Seed;
      Unused_Released : Boolean;
   begin
      if B = null then
         --  The buffer was taken back, or never granted. The style the
         --  chain opened on is what stands: the overrides it named did
         --  not apply, and Is_Live says so to a caller that asks.
         if Was_Reclaimed (C) then
            Report_Built_After_Reclaim;
         end if;
         return C.Seed;
      end if;

      declare
         Def : Style_Definition :=
           (if C.Seed = Empty_Widget_Style
            then Empty_Style_Definition
            else Definition (C.Seed));
      begin
         for K in Rule_Slot'Range loop
            declare
               Named : Boolean := False;
            begin
               for I in 1 .. B.Count loop
                  if B.Slots (I).Rule = K then
                     Named := True;
                     exit;
                  end if;
               end loop;

               if Named then
                  Fold_Rule (Def, K, B.all);
               end if;
            end;
         end loop;

         Result := Intern (Def);
      end;

      Return_Buffer (Held, Unused_Released);
      return Result;
   end Build;

end Adi.Widget_Styles;
