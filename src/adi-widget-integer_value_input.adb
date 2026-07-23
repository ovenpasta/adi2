--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

package body Adi.Widget.Integer_Value_Input is

   function Conv_Image (V : Value_Type) return String is
   begin
      return Trim (Value_Type'Image (V), Both);
   end Conv_Image;

end Adi.Widget.Integer_Value_Input;
