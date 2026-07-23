--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Vectors;

package body Adi.Dispatch is

   package Proc_Vectors is new Ada.Containers.Vectors
     (Positive, Deferred_Proc);

   ---------------------------------------------------------------------------
   --  Thread-safe queue using a protected type.
   --  Drain_All swaps the pending vector out so new Posts during Drain
   --  go into a fresh vector — preventing unbounded recursion.
   ---------------------------------------------------------------------------

   protected Queue is
      procedure Enqueue (Proc : Deferred_Proc);
      procedure Drain_All (Into : out Proc_Vectors.Vector);
      function Count return Natural;
   private
      Pending : Proc_Vectors.Vector;
   end Queue;

   protected body Queue is
      procedure Enqueue (Proc : Deferred_Proc) is
      begin
         Pending.Append (Proc);
      end Enqueue;

      procedure Drain_All (Into : out Proc_Vectors.Vector) is
      begin
         Into := Pending;
         Pending.Clear;
      end Drain_All;

      function Count return Natural is
      begin
         return Natural (Pending.Length);
      end Count;
   end Queue;

   ----------
   -- Post --
   ----------

   procedure Post (Proc : Deferred_Proc) is
   begin
      if Proc /= null then
         Queue.Enqueue (Proc);
      end if;
   end Post;

   -----------
   -- Drain --
   -----------

   procedure Drain is
      Batch : Proc_Vectors.Vector;
   begin
      Queue.Drain_All (Batch);
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
      return Queue.Count;
   end Pending_Count;

end Adi.Dispatch;
