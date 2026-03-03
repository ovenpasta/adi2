pragma Ada_2022;

package body Adi.I18N.Plural is

   --  Recursive descent parser for gettext plural expressions.
   --  Grammar (precedence low to high):
   --    ternary   := or_expr ('?' ternary ':' ternary)?
   --    or_expr   := and_expr ('||' and_expr)*
   --    and_expr  := eq_expr  ('&&' eq_expr)*
   --    eq_expr   := rel_expr (('=='|'!=') rel_expr)*
   --    rel_expr  := add_expr (('<'|'>'|'<='|'>=') add_expr)*
   --    add_expr  := mul_expr (('+'|'-') mul_expr)*
   --    mul_expr  := unary    (('*'|'%') unary)*
   --    unary     := '!' unary | primary
   --    primary   := 'n' | integer | '(' ternary ')'

   type Parser_State is record
      Source : access constant String;
      Pos    : Positive;
   end record;

   procedure Skip_Spaces (S : in out Parser_State) is
   begin
      while S.Pos <= S.Source'Last
        and then S.Source (S.Pos) = ' '
      loop
         S.Pos := S.Pos + 1;
      end loop;
   end Skip_Spaces;

   function At_End (S : Parser_State) return Boolean is
     (S.Pos > S.Source'Last);

   function Peek (S : Parser_State) return Character is
     (if At_End (S) then ASCII.NUL else S.Source (S.Pos));

   function Match (S : in out Parser_State; C : Character) return Boolean is
   begin
      Skip_Spaces (S);
      if not At_End (S) and then S.Source (S.Pos) = C then
         S.Pos := S.Pos + 1;
         return True;
      end if;
      return False;
   end Match;

   function Match2
     (S : in out Parser_State; C1, C2 : Character) return Boolean is
   begin
      Skip_Spaces (S);
      if S.Pos + 1 <= S.Source'Last
        and then S.Source (S.Pos) = C1
        and then S.Source (S.Pos + 1) = C2
      then
         S.Pos := S.Pos + 2;
         return True;
      end if;
      return False;
   end Match2;

   --  Forward declarations
   function Parse_Ternary (S : in out Parser_State; N : Natural) return Natural;

   function Parse_Primary
     (S : in out Parser_State; N : Natural) return Natural
   is
      Result : Natural := 0;
   begin
      Skip_Spaces (S);
      if not At_End (S) and then S.Source (S.Pos) = 'n' then
         S.Pos := S.Pos + 1;
         return N;
      elsif not At_End (S) and then S.Source (S.Pos) = '(' then
         S.Pos := S.Pos + 1;
         Result := Parse_Ternary (S, N);
         Skip_Spaces (S);
         if not At_End (S) and then S.Source (S.Pos) = ')' then
            S.Pos := S.Pos + 1;
         end if;
         return Result;
      elsif not At_End (S)
        and then S.Source (S.Pos) in '0' .. '9'
      then
         while not At_End (S)
           and then S.Source (S.Pos) in '0' .. '9'
         loop
            Result := Result * 10
              + Character'Pos (S.Source (S.Pos)) - Character'Pos ('0');
            S.Pos := S.Pos + 1;
         end loop;
         return Result;
      else
         raise Constraint_Error
           with "Plural formula parse error at position" & S.Pos'Image;
      end if;
   end Parse_Primary;

   function Parse_Unary
     (S : in out Parser_State; N : Natural) return Natural is
   begin
      if Match (S, '!') then
         return (if Parse_Unary (S, N) = 0 then 1 else 0);
      end if;
      return Parse_Primary (S, N);
   end Parse_Unary;

   function Parse_Mul
     (S : in out Parser_State; N : Natural) return Natural
   is
      Left : Natural := Parse_Unary (S, N);
   begin
      loop
         Skip_Spaces (S);
         if Match (S, '%') then
            declare
               Right : constant Natural := Parse_Unary (S, N);
            begin
               Left := (if Right = 0 then 0 else Left mod Right);
            end;
         elsif Match (S, '*') then
            Left := Left * Parse_Unary (S, N);
         else
            exit;
         end if;
      end loop;
      return Left;
   end Parse_Mul;

   function Parse_Add
     (S : in out Parser_State; N : Natural) return Natural
   is
      Left : Natural := Parse_Mul (S, N);
   begin
      loop
         Skip_Spaces (S);
         if Match (S, '+') then
            Left := Left + Parse_Mul (S, N);
         elsif Match (S, '-') then
            declare
               Right : constant Natural := Parse_Mul (S, N);
            begin
               Left := (if Right > Left then 0 else Left - Right);
            end;
         else
            exit;
         end if;
      end loop;
      return Left;
   end Parse_Add;

   function Parse_Rel
     (S : in out Parser_State; N : Natural) return Natural
   is
      Left : constant Natural := Parse_Add (S, N);
   begin
      Skip_Spaces (S);
      if Match2 (S, '<', '=') then
         return (if Left <= Parse_Add (S, N) then 1 else 0);
      elsif Match2 (S, '>', '=') then
         return (if Left >= Parse_Add (S, N) then 1 else 0);
      elsif not At_End (S) and then Peek (S) = '<'
        and then (S.Pos + 1 > S.Source'Last or else S.Source (S.Pos + 1) /= '=')
      then
         if Match (S, '<') then
            return (if Left < Parse_Add (S, N) then 1 else 0);
         end if;
      elsif not At_End (S) and then Peek (S) = '>'
        and then (S.Pos + 1 > S.Source'Last or else S.Source (S.Pos + 1) /= '=')
      then
         if Match (S, '>') then
            return (if Left > Parse_Add (S, N) then 1 else 0);
         end if;
      end if;
      return Left;
   end Parse_Rel;

   function Parse_Eq
     (S : in out Parser_State; N : Natural) return Natural
   is
      Left : Natural := Parse_Rel (S, N);
   begin
      loop
         Skip_Spaces (S);
         if Match2 (S, '=', '=') then
            Left := (if Left = Parse_Rel (S, N) then 1 else 0);
         elsif Match2 (S, '!', '=') then
            Left := (if Left /= Parse_Rel (S, N) then 1 else 0);
         else
            exit;
         end if;
      end loop;
      return Left;
   end Parse_Eq;

   function Parse_And
     (S : in out Parser_State; N : Natural) return Natural
   is
      Left : Natural := Parse_Eq (S, N);
   begin
      loop
         Skip_Spaces (S);
         if Match2 (S, '&', '&') then
            declare
               Right : constant Natural := Parse_Eq (S, N);
            begin
               Left := (if Left /= 0 and then Right /= 0 then 1 else 0);
            end;
         else
            exit;
         end if;
      end loop;
      return Left;
   end Parse_And;

   function Parse_Or
     (S : in out Parser_State; N : Natural) return Natural
   is
      Left : Natural := Parse_And (S, N);
   begin
      loop
         Skip_Spaces (S);
         if Match2 (S, '|', '|') then
            declare
               Right : constant Natural := Parse_And (S, N);
            begin
               Left := (if Left /= 0 or else Right /= 0 then 1 else 0);
            end;
         else
            exit;
         end if;
      end loop;
      return Left;
   end Parse_Or;

   function Parse_Ternary
     (S : in out Parser_State; N : Natural) return Natural
   is
      Cond : constant Natural := Parse_Or (S, N);
   begin
      Skip_Spaces (S);
      if Match (S, '?') then
         declare
            Then_Val : constant Natural := Parse_Ternary (S, N);
            Discard  : Boolean;
         begin
            Skip_Spaces (S);
            Discard := Match (S, ':');
            declare
               Else_Val : constant Natural := Parse_Ternary (S, N);
            begin
               return (if Cond /= 0 then Then_Val else Else_Val);
            end;
         end;
      end if;
      return Cond;
   end Parse_Ternary;

   function Evaluate (Formula : String; N : Natural) return Natural is
      F : aliased constant String := Formula;
      S : Parser_State := (Source => F'Unchecked_Access, Pos => F'First);
   begin
      return Parse_Ternary (S, N);
   end Evaluate;

end Adi.I18N.Plural;
