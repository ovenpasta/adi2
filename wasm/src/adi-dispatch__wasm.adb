--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  WebAssembly body of Adi.Dispatch: single-threaded, no tasks exist,
--  so a plain vector replaces the native protected queue. Drain still
--  swaps the queue out first so a deferred proc that calls Post
--  re-queues for the next frame instead of recursing.

with Ada.Containers.Vectors;

package body Adi.Dispatch is

   package Proc_Vectors is new Ada.Containers.Vectors
     (Positive, Deferred_Proc);

   Pending : Proc_Vectors.Vector;

   ----------
   -- Post --
   ----------

   procedure Post (Proc : Deferred_Proc) is
   begin
      if Proc /= null then
         Pending.Append (Proc);
      end if;
   end Post;

   -----------
   -- Drain --
   -----------

   procedure Drain is
      Batch : Proc_Vectors.Vector;
   begin
      Batch := Pending;
      Pending.Clear;
      for P of Batch loop
         if P /= null then
            P.all;
         end if;
      end loop;
   end Drain;

   -------------------
   -- Pending_Count --
   -------------------

   function Pending_Count return Natural is
   begin
      return Natural (Pending.Length);
   end Pending_Count;

end Adi.Dispatch;
