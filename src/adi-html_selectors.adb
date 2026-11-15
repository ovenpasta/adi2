--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;

package body Adi.HTML_Selectors is

   function Lower (S : String) return String
     renames Ada.Characters.Handling.To_Lower;

   function Is_Space (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF
      or else C = ASCII.CR or else C = ASCII.FF);

   function Is_Name_Char (C : Character) return Boolean is
     (C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_'
      or else Character'Pos (C) >= 128);

   -----------
   -- Parse --
   -----------

   function Parse (Text : String; Result : out Selector) return Boolean is
      I       : Natural := Text'First;
      Pending : Combinator := None;

      function At_End return Boolean is (I > Text'Last);

      function Skip_Spaces return Boolean is
         Start : constant Natural := I;
      begin
         while not At_End and then Is_Space (Text (I)) loop
            I := I + 1;
         end loop;
         return I > Start;
      end Skip_Spaces;

      function Read_Name return String is
         Start : constant Natural := I;
      begin
         while not At_End and then Is_Name_Char (Text (I)) loop
            I := I + 1;
         end loop;
         return Text (Start .. I - 1);
      end Read_Name;

      --  [name] or [name=value], value an identifier or a quoted string.
      function Read_Attribute (Into : in out Compound) return Boolean is
         Test : Attribute_Test;
      begin
         I := I + 1;
         if Skip_Spaces then
            null;
         end if;
         declare
            Name : constant String := Read_Name;
         begin
            if Name = "" then
               return False;
            end if;
            Test.Name := To_Unbounded_String (Lower (Name));
         end;
         if Skip_Spaces then
            null;
         end if;
         if At_End then
            return False;
         end if;

         if Text (I) = '=' then
            I := I + 1;
            if Skip_Spaces then
               null;
            end if;
            if At_End then
               return False;
            end if;
            Test.Has_Value := True;
            if Text (I) in '"' | ''' then
               declare
                  Quote : constant Character := Text (I);
                  Start : constant Positive := I + 1;
               begin
                  I := Start;
                  while not At_End and then Text (I) /= Quote loop
                     I := I + 1;
                  end loop;
                  if At_End then
                     return False;
                  end if;
                  Test.Value := To_Unbounded_String (Text (Start .. I - 1));
                  I := I + 1;
               end;
            else
               declare
                  Value : constant String := Read_Name;
               begin
                  if Value = "" then
                     return False;
                  end if;
                  Test.Value := To_Unbounded_String (Value);
               end;
            end if;
            if Skip_Spaces then
               null;
            end if;
         end if;

         if At_End or else Text (I) /= ']' then
            return False;
         end if;
         I := I + 1;
         Into.Attributes.Append (Test);
         return True;
      end Read_Attribute;

      function Read_Pseudo (Into : in out Compound) return Boolean is
      begin
         I := I + 1;
         if At_End or else Text (I) = ':' then
            return False;
         end if;
         declare
            Name : constant String := Lower (Read_Name);
         begin
            if Name = "hover" then
               Into.Pseudos (Hover) := True;
            elsif Name = "active" then
               Into.Pseudos (Active) := True;
            elsif Name = "link" then
               Into.Pseudos (Link) := True;
            elsif Name = "visited" then
               Into.Pseudos (Visited) := True;
            elsif Name = "first-child" then
               Into.Pseudos (First_Child) := True;
            elsif Name = "last-child" then
               Into.Pseudos (Last_Child) := True;
            else
               return False;
            end if;
         end;
         return True;
      end Read_Pseudo;

      function Read_Compound (Into : out Compound) return Boolean is
         Named : Boolean := False;
      begin
         Into := (others => <>);
         if At_End then
            return False;
         end if;

         if Text (I) = '*' then
            I := I + 1;
            Named := True;
         elsif Text (I) in 'a' .. 'z' | 'A' .. 'Z' then
            Into.Tag := To_Unbounded_String (Lower (Read_Name));
            Named := True;
         end if;

         while not At_End loop
            case Text (I) is
               when '.' | '#' =>
                  declare
                     Kind : constant Character := Text (I);
                  begin
                     I := I + 1;
                     declare
                        Name : constant String := Lower (Read_Name);
                     begin
                        if Name = "" then
                           return False;
                        elsif Kind = '.' then
                           Into.Classes.Append (To_Unbounded_String (Name));
                        else
                           Into.Id := To_Unbounded_String (Name);
                        end if;
                     end;
                  end;
               when '[' =>
                  if not Read_Attribute (Into) then
                     return False;
                  end if;
               when ':' =>
                  if not Read_Pseudo (Into) then
                     return False;
                  end if;
               when others =>
                  exit;
            end case;
            Named := True;
         end loop;

         return Named;
      end Read_Compound;

   begin
      Result := (others => <>);
      if Skip_Spaces then
         null;
      end if;

      loop
         declare
            C : Compound;
         begin
            if not Read_Compound (C) then
               Result := (others => <>);
               return False;
            end if;
            C.Joined_By := (if Result.Parts.Is_Empty then None else Pending);
            Result.Parts.Append (C);
         end;

         declare
            Spaced : constant Boolean := Skip_Spaces;
         begin
            exit when At_End;

            case Text (I) is
               when '>' => Pending := Child;
               when '+' => Pending := Next_Sibling;
               when '~' => Pending := Later_Sibling;
               when others =>
                  if not Spaced then
                     Result := (others => <>);
                     return False;
                  end if;
                  Pending := Descendant;
            end case;

            if Pending /= Descendant then
               I := I + 1;
               if Skip_Spaces then
                  null;
               end if;
            end if;
         end;
      end loop;

      Result.Valid := True;
      return True;
   end Parse;

   -----------------
   -- Specificity --
   -----------------

   function "<" (L, R : Specificity) return Boolean is
     (if L.Ids /= R.Ids then L.Ids < R.Ids
      elsif L.Classes /= R.Classes then L.Classes < R.Classes
      else L.Types < R.Types);

   function Specificity_Of (S : Selector) return Specificity is
      Result : Specificity;
   begin
      for C of S.Parts loop
         if Length (C.Id) > 0 then
            Result.Ids := Result.Ids + 1;
         end if;
         Result.Classes := Result.Classes
           + Natural (C.Classes.Length) + Natural (C.Attributes.Length);
         for P in Pseudo_Class loop
            if C.Pseudos (P) then
               Result.Classes := Result.Classes + 1;
            end if;
         end loop;
         if Length (C.Tag) > 0 then
            Result.Types := Result.Types + 1;
         end if;
      end loop;
      return Result;
   end Specificity_Of;

   function Subject_Tag (S : Selector) return String is
     (if S.Parts.Is_Empty then "" else To_String (S.Parts.Last_Element.Tag));

   function Subject_Id (S : Selector) return String is
     (if S.Parts.Is_Empty then "" else To_String (S.Parts.Last_Element.Id));

   function Is_Dynamic (S : Selector) return Boolean is
     (for some C of S.Parts => C.Pseudos (Hover) or else C.Pseudos (Active));

   --------------
   -- Matching --
   --------------

   function Compound_Matches
     (C : Compound; D : Document'Class; E : Positive) return Boolean is
   begin
      if Length (C.Tag) > 0 and then Lower (D.Tag_Of (E)) /= To_String (C.Tag) then
         return False;
      end if;

      if Length (C.Id) > 0 and then Lower (D.Id_Of (E)) /= To_String (C.Id) then
         return False;
      end if;

      for Name of C.Classes loop
         if not D.Has_Class (E, To_String (Name)) then
            return False;
         end if;
      end loop;

      for A of C.Attributes loop
         declare
            Found : Boolean;
            Value : constant String := D.Attribute_Of (E, To_String (A.Name), Found);
         begin
            if not Found or else (A.Has_Value and then Value /= To_String (A.Value)) then
               return False;
            end if;
         end;
      end loop;

      if (C.Pseudos (Hover) and then not D.In_State (E, Hovered))
        or else (C.Pseudos (Active) and then not D.In_State (E, Activated))
        or else C.Pseudos (Visited)
        or else (C.Pseudos (First_Child) and then D.Previous_Sibling_Of (E) /= 0)
        or else (C.Pseudos (Last_Child) and then D.Next_Sibling_Of (E) /= 0)
      then
         return False;
      end if;

      if C.Pseudos (Link) then
         declare
            Found : Boolean;
            Href  : constant String := D.Attribute_Of (E, "href", Found);
            pragma Unreferenced (Href);
         begin
            if Lower (D.Tag_Of (E)) /= "a" or else not Found then
               return False;
            end if;
         end;
      end if;

      return True;
   end Compound_Matches;

   --  Compound K matches E, and the compounds before it match the
   --  elements its combinator reaches. Matched right to left, as browsers
   --  do: the last compound is the most selective.
   function Matches_From
     (S : Selector; K : Positive; D : Document'Class; E : Positive) return Boolean
   is
      C : Compound renames S.Parts (K);
      P : Natural;
   begin
      if not Compound_Matches (C, D, E) then
         return False;
      elsif K = 1 then
         return True;
      end if;

      case C.Joined_By is
         when None =>
            return True;
         when Child =>
            P := D.Parent_Of (E);
            return P /= 0 and then Matches_From (S, K - 1, D, P);
         when Next_Sibling =>
            P := D.Previous_Sibling_Of (E);
            return P /= 0 and then Matches_From (S, K - 1, D, P);
         when Descendant =>
            P := D.Parent_Of (E);
            while P /= 0 loop
               if Matches_From (S, K - 1, D, P) then
                  return True;
               end if;
               P := D.Parent_Of (P);
            end loop;
            return False;
         when Later_Sibling =>
            P := D.Previous_Sibling_Of (E);
            while P /= 0 loop
               if Matches_From (S, K - 1, D, P) then
                  return True;
               end if;
               P := D.Previous_Sibling_Of (P);
            end loop;
            return False;
      end case;
   end Matches_From;

   function Matches
     (S : Selector; D : Document'Class; E : Positive) return Boolean is
     (S.Valid
      and then not S.Parts.Is_Empty
      and then Matches_From (S, Positive (S.Parts.Last_Index), D, E));

end Adi.HTML_Selectors;
