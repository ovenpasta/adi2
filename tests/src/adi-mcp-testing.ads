--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.JSON;
with Adi.Render;

--  Instrumentation the tests need and applications do not.
package Adi.MCP.Testing is

   --  The texture_cache section of a perf_stats response, built from
   --  figures the caller supplies rather than from a running window. It
   --  is the only way to assert the schema in the ordinary gate: against
   --  a live application a renamed or dropped field shows up whenever
   --  somebody next looks, which is too late.
   procedure Write_Texture_Cache
     (W     : in out Adi.JSON.JSON_Writer;
      Stats : Adi.Render.Texture_Stats);

end Adi.MCP.Testing;
