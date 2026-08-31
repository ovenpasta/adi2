pragma Ada_2022;

with Adi.Widget_Properties.Enumerated;
pragma Elaborate_All (Adi.Widget_Properties.Enumerated);

--  The vocabulary examples/css/runtime_css_example.css selects on: one
--  enumeration and one instantiation over it, at library level, where
--  elaboration registers the property and every literal.
--
--  tools/css_to_ada.py names the instantiation and the literal from the
--  CSS text, so a name the sheet spells and this package does not
--  declare stops the build here rather than at run time.
package Runtime_Css_Properties is

   type Severity_Level is (Ok, Warning, Critical);

   package Severity is new Adi.Widget_Properties.Enumerated
     (Name => "severity", Values => Severity_Level);

end Runtime_Css_Properties;
