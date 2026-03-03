pragma Ada_2022;

package Adi.I18N.Plural is

   function Evaluate (Formula : String; N : Natural) return Natural;
   --  Evaluate a gettext plural formula with the given N value.
   --  The formula uses C-like syntax: integer literals, variable 'n',
   --  operators (!, %, *, +, -, <, >, <=, >=, ==, !=, &&, ||),
   --  ternary (? :), and parentheses.
   --  Returns the plural form index.
   --  Raises Constraint_Error on parse failure.

end Adi.I18N.Plural;
