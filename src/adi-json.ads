pragma Ada_2022;

with JSON.Types;
with JSON.Parsers;

package Adi.JSON is

   package Types   is new Standard.JSON.Types (Long_Integer, Long_Float);
   package Parsers  is new Standard.JSON.Parsers (Types);

end Adi.JSON;
