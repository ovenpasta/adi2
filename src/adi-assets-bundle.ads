--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with System.Storage_Elements;

private package Adi.Assets.Bundle is

   procedure Register
     (Path   : String;
      Addr   : System.Address;
      Length : System.Storage_Elements.Storage_Count);

   function Lookup (Path : String) return Asset_Data;

   procedure Clear;

end Adi.Assets.Bundle;
