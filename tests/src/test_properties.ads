--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Widget_Properties.Enumerated;
pragma Elaborate_All (Adi.Widget_Properties.Enumerated);

--  The vocabulary tests/css/widget_property.css spells, declared the way
--  an application declares its own: one enumeration per property and one
--  instantiation over it, at library level, where elaboration registers
--  the property and every literal.
--
--  Power and Radio carry the same literal names on purpose. The
--  generated sheet names the literal alone, and the instantiation it is
--  handed to is what tells the two apart.
package Test_Properties is

   type Severity_Level is (Ok, Warning, Critical);
   type Link_State is (Degraded, Offline);
   type Power_State is (Off, On);
   type Radio_State is (Off, On);
   type Quiet_State is (No, Yes);

   --  "severity" again, over a wider enumeration. One name naming two
   --  vocabularies is a declaration the registry refuses, and Clash.Id
   --  reads as No_Property.
   type Wide_Severity is (Ok, Warning, Critical, Fatal);

   package Severity is new Adi.Widget_Properties.Enumerated
     (Name => "severity", Values => Severity_Level);

   package Link is new Adi.Widget_Properties.Enumerated
     (Name => "link", Values => Link_State);

   package Power is new Adi.Widget_Properties.Enumerated
     (Name => "power", Values => Power_State);

   package Radio is new Adi.Widget_Properties.Enumerated
     (Name => "radio", Values => Radio_State);

   package Clash is new Adi.Widget_Properties.Enumerated
     (Name => "severity", Values => Wide_Severity);

   --  Reachable through the constants alone: no name of it reaches the
   --  registry, so a stylesheet read at run time cannot name it and is
   --  rejected for trying, while the generated sheet styles by it.
   package Quiet is new Adi.Widget_Properties.Enumerated
     (Name => "quiet", Values => Quiet_State, Dynamic_Lookup => False);

end Test_Properties;
