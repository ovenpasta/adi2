pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Adi.HTML_Selectors; use Adi.HTML_Selectors;
with Test_Support;       use Test_Support;

--  Adi.HTML_Selectors against a small fixed tree:
--
--    1 html
--      2 body
--        3 div#main.note
--          4 p.first
--            5 a[href=x]          (hovered)
--          6 p.second.extra
--        7 ul
--          8 li
--          9 li
procedure Html_Selectors_Test is

   type Element is record
      Tag     : String (1 .. 4);
      Id      : String (1 .. 4);
      Classes : String (1 .. 13);
      Parent  : Natural;
      Href    : String (1 .. 1);
   end record;

   Tree : constant array (1 .. 9) of Element :=
     [1 => ("html", "    ", "             ", 0, " "),
      2 => ("body", "    ", "             ", 1, " "),
      3 => ("div ", "main", "note         ", 2, " "),
      4 => ("p   ", "    ", "first        ", 3, " "),
      5 => ("a   ", "    ", "             ", 4, "x"),
      6 => ("p   ", "    ", "second extra ", 3, " "),
      7 => ("ul  ", "    ", "             ", 2, " "),
      8 => ("li  ", "    ", "             ", 7, " "),
      9 => ("li  ", "    ", "             ", 7, " ")];

   Hovered_Element : constant := 5;

   function Trim (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   type Fixed_Document is new Document with null record;

   overriding function Tag_Of (D : Fixed_Document; E : Positive) return String is
     (Ada.Characters.Handling.To_Upper (Trim (Tree (E).Tag)));
   overriding function Id_Of (D : Fixed_Document; E : Positive) return String is
     (Trim (Tree (E).Id));
   overriding function Has_Class
     (D : Fixed_Document; E : Positive; Name : String) return Boolean is
     (Ada.Strings.Fixed.Index (" " & Tree (E).Classes, " " & Name & " ") > 0);
   overriding function Attribute_Of
     (D : Fixed_Document; E : Positive; Name : String; Found : out Boolean)
      return String;
   overriding function Parent_Of (D : Fixed_Document; E : Positive) return Natural is
     (Tree (E).Parent);
   overriding function Previous_Sibling_Of
     (D : Fixed_Document; E : Positive) return Natural;
   overriding function Next_Sibling_Of
     (D : Fixed_Document; E : Positive) return Natural;
   overriding function In_State
     (D : Fixed_Document; E : Positive; State : Dynamic_State) return Boolean;

   overriding function Attribute_Of
     (D : Fixed_Document; E : Positive; Name : String; Found : out Boolean)
      return String is
   begin
      Found := Name = "href" and then Tree (E).Href /= " ";
      return (if Found then Tree (E).Href else "");
   end Attribute_Of;

   overriding function Previous_Sibling_Of
     (D : Fixed_Document; E : Positive) return Natural is
   begin
      for K in reverse 1 .. E - 1 loop
         if Tree (K).Parent = Tree (E).Parent then
            return K;
         end if;
      end loop;
      return 0;
   end Previous_Sibling_Of;

   overriding function Next_Sibling_Of
     (D : Fixed_Document; E : Positive) return Natural is
   begin
      for K in E + 1 .. Tree'Last loop
         if Tree (K).Parent = Tree (E).Parent then
            return K;
         end if;
      end loop;
      return 0;
   end Next_Sibling_Of;

   overriding function In_State
     (D : Fixed_Document; E : Positive; State : Dynamic_State) return Boolean
   is
      P : Natural := (if State = Hovered then Hovered_Element else 0);
   begin
      while P /= 0 loop
         if P = E then
            return True;
         end if;
         P := Tree (P).Parent;
      end loop;
      return False;
   end In_State;

   Doc : Fixed_Document;

   procedure Expect (Text : String; E : Positive; Want : Boolean) is
      S : Selector;
   begin
      Assert (Parse (Text, S), "'" & Text & "' parses");
      Assert (Matches (S, Doc, E) = Want,
              "'" & Text & "' " & (if Want then "matches " else "does not match ")
              & "element" & E'Image);
   end Expect;

   procedure Rejects (Text : String) is
      S : Selector;
   begin
      Assert (not Parse (Text, S), "'" & Text & "' is refused");
      Assert (not Matches (S, Doc, 4), "'" & Text & "' then matches nothing");
   end Rejects;

   function Weight (Text : String) return Specificity is
      S : Selector;
   begin
      Assert (Parse (Text, S), "'" & Text & "' parses");
      return Specificity_Of (S);
   end Weight;

begin
   Start_Suite ("html_selectors_test");

   Section ("compounds");
   Expect ("p", 4, True);
   Expect ("P", 4, True);
   Expect ("*", 7, True);
   Expect ("div", 4, False);
   Expect ("p.first", 4, True);
   Expect ("p.second", 4, False);
   Expect ("p.second.extra", 6, True);
   Expect (".extra.second", 6, True);
   Expect ("p.second.missing", 6, False);
   Expect ("#main", 3, True);
   Expect ("#MAIN.note", 3, True);
   Expect ("div#other", 3, False);
   Expect ("a[href]", 5, True);
   Expect ("a[ href = x ]", 5, True);
   Expect ("a[href=""x""]", 5, True);
   Expect ("a[href='y']", 5, False);
   Expect ("p[href]", 4, False);

   Section ("combinators");
   Expect ("div p", 4, True);
   Expect ("body p", 4, True);
   Expect ("html body div p a", 5, True);
   Expect ("div > p", 4, True);
   Expect ("div>p", 4, True);
   Expect ("body > p", 4, False);
   Expect ("ul p", 4, False);
   Expect ("p + p", 6, True);
   Expect ("p + p", 4, False);
   Expect ("p ~ p", 6, True);
   Expect ("div ~ ul", 7, True);
   Expect ("div + ul > li", 9, True);
   Expect (".note p.second", 6, True);
   Expect ("#main > .first > a", 5, True);
   Expect ("li + li", 9, True);
   Expect ("li + li", 8, False);

   Section ("pseudo-classes");
   Expect ("a:hover", 5, True);
   Expect ("p:hover", 4, True);
   Expect ("div:hover a", 5, True);
   Expect ("p.second:hover", 6, False);
   Expect ("a:active", 5, False);
   Expect ("a:link", 5, True);
   Expect ("p:link", 4, False);
   Expect ("a:visited", 5, False);
   Expect ("li:first-child", 8, True);
   Expect ("li:first-child", 9, False);
   Expect ("li:last-child", 9, True);
   Expect ("p:first-child", 4, True);
   Expect ("p:last-child", 6, True);

   Section ("outside the grammar");
   Rejects ("");
   Rejects ("   ");
   Rejects ("p::before");
   Rejects ("a:nth-child(2)");
   Rejects ("p:not(.x)");
   Rejects ("> p");
   Rejects ("p >");
   Rejects ("p..x");
   Rejects ("#");
   Rejects ("[href");
   Rejects ("a[href~=x]");
   Rejects ("p ! q");
   Rejects ("p, q");

   Section ("specificity");
   Assert (Weight ("#a .b c") = (Ids => 1, Classes => 1, Types => 1), "#a .b c is 1,1,1");
   Assert (Weight ("a:hover") = (Ids => 0, Classes => 1, Types => 1), "a:hover is 0,1,1");
   Assert (Weight ("a[href].x") = (Ids => 0, Classes => 2, Types => 1), "an attribute counts as a class");
   Assert (Weight ("*") = (Ids => 0, Classes => 0, Types => 0), "* is 0,0,0");
   Assert (Weight ("p") < Weight (".x"), "a class outweighs a type");
   Assert (Weight (".x .y .z") < Weight ("#a"), "an id outweighs any number of classes");
   Assert (not (Weight ("p") < Weight ("p")), "equal is not less");

   Section ("dynamic");
   declare
      S : Selector;
   begin
      Assert (Parse ("div:hover p", S) and then Is_Dynamic (S), ":hover is dynamic");
      Assert (Parse ("a:active", S) and then Is_Dynamic (S), ":active is dynamic");
      Assert (Parse ("li:first-child", S) and then not Is_Dynamic (S),
              ":first-child is not");
   end;

   Finish;
end Html_Selectors_Test;
