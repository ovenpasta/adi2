pragma Ada_2022;

with Adi.SDL;             use Adi.SDL;
with Adi.SDL.Render;      use Adi.SDL.Render;
with Adi.SDL.Surface;     use Adi.SDL.Surface;
with Adi.SDL.PixelFormat; use Adi.SDL.PixelFormat;
with Ada.Unchecked_Deallocation;
with Adi.Clock;
with Adi.Texture_Cache;   use Adi.Texture_Cache;
with Test_Support;        use Test_Support;

--  The cache holds GPU textures under a byte budget. Counting entries would
--  bound nothing useful: a blurred shadow runs from under two kilobytes to
--  several megabytes, so a fixed entry count permits either a gigabyte or a
--  megabyte. Eviction asks what an entry returns for the room it occupies --
--  how often used, how recently, how costly to rebuild, how large.

procedure Texture_Cache_Test is

   KB : constant Byte_Count := 1024;

   Canvas   : constant SDL_Surface_Ptr :=
     SDL_CreateSurface (8, 8, SDL_PIXELFORMAT_RGBA32);
   Renderer : SDL_Renderer_Ptr;

   function New_Texture return SDL_Texture_Ptr is
      Surf : constant SDL_Surface_Ptr :=
        SDL_CreateSurface (4, 4, SDL_PIXELFORMAT_RGBA32);
      Tex  : SDL_Texture_Ptr;
   begin
      Tex := SDL_CreateTextureFromSurface (Renderer, Surf);
      SDL_DestroySurface (Surf);
      return Tex;
   end New_Texture;

   function Shadow_Key (N : Natural) return Texture_Key is
     ((Kind => Shadow_Texture, Extent_A => N, others => <>));

   --  Store a texture that will be charged Side * Side * 4 bytes, whatever
   --  the real texture behind it is: the cache is told the dimensions, so a
   --  test can weigh entries without allocating megabytes of GPU memory.
   --  Charge an entry as Side * Side * 4 bytes without allocating that
   --  much: the cache is told the footprint, so a test can weigh entries
   --  against each other cheaply.
   procedure Put (C     : in out Cache;
                  Key   : Texture_Key;
                  Side  : Positive;
                  Micros : Integer)
   is
      Ignore : Texture_Handle;
   begin
      Ignore := Store (C, Key, New_Texture,
                       Width  => Side, Height => Side,
                       Bytes  => Byte_Count (Side) * Byte_Count (Side) * 4,
                       Build_Time => Adi.Clock.Microseconds (Micros));
   end Put;

   --  Resident and findable.
   function Held (C : Cache; Key : Texture_Key) return Boolean is
     (Is_Valid (C, Find (C, Key)));

   --  Using an entry means drawing it, which means borrowing it. Find
   --  alone resolves a key and deliberately does not count as use.
   procedure Touch (C : in out Cache; Key : Texture_Key) is
      H : constant Texture_Handle := Find (C, Key);
   begin
      if Is_Valid (C, H) then
         declare
            Ref : constant Texture_Ref := Borrow (C, H);
         begin
            pragma Assert (Ref.Texture /= null);
         end;
      end if;
   end Touch;

   function Charge (Side : Positive) return Byte_Count is
     (Byte_Count (Side) * Byte_Count (Side) * 4);

   type Cache_Access is access Cache;
   procedure Free_Cache is
     new Ada.Unchecked_Deallocation (Cache, Cache_Access);

begin
   Start_Suite ("Texture cache test");

   if Canvas = null then
      Assert (False, "SDL should provide a surface");
      Finish;
      return;
   end if;

   Renderer := SDL_CreateSoftwareRenderer (Canvas);
   if Renderer = null then
      Assert (False, "SDL should provide a software renderer");
      Finish;
      return;
   end if;

   --  The budget is bytes. Two entries of wildly different size are not
   --  interchangeable, which an entry count would treat them as.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (300) * KB);

      Put (C, Shadow_Key (1), 64, Micros => 100);    --  16 KB
      Put (C, Shadow_Key (2), 256, Micros => 100);   --  256 KB

      Assert (Bytes_Used (C) = Charge (64) + Charge (256),
              "Entries should be charged by their pixels, not counted");
      Assert (Count (C) = 2, "Both should fit inside the budget");

      --  One more of any size pushes past 300 KB and forces an eviction,
      --  though only two entries are held.
      Put (C, Shadow_Key (3), 64, Micros => 100);
      Assert (Bytes_Used (C) <= Byte_Count (300) * KB,
              "Storing past the budget should evict until it fits:"
              & Byte_Count'Image (Bytes_Used (C)));
      Clear (C);
   end;

   --  Size alone is not a reason to evict. A texture whose pixels were
   --  expensive earns its room against one whose pixels were cheap,
   --  whatever their totals: twenty milliseconds over 351 KB beats twenty
   --  microseconds over 4 KB, per byte, by a wide margin.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (32) + Charge (300));
      Put (C, Shadow_Key (1), 32,  Micros => 20);   --   4 KB,  20us
      Put (C, Shadow_Key (2), 300, Micros => 20_000);   -- 351 KB,  20ms
      Put (C, Shadow_Key (3), 32,  Micros => 20);   --   4 KB, tips over

      Assert (Held (C, Shadow_Key (2)),
              "A large texture that was expensive to build should keep its"
              & " room");
      Assert (not Held (C, Shadow_Key (1))
                or else not Held (C, Shadow_Key (3)),
              "One of the cheap small entries should have gone instead");
      Clear (C);
   end;

   --  The converse: large and cheap is exactly what should go, because
   --  reclaiming its room costs little to undo.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (32) + Charge (300));
      Put (C, Shadow_Key (1), 32,  Micros => 10_000);   --   4 KB,  10ms
      Put (C, Shadow_Key (2), 300, Micros => 50);   -- 351 KB,  50us
      Put (C, Shadow_Key (3), 32,  Micros => 10_000);   --   4 KB, tips over

      Assert (not Held (C, Shadow_Key (2)),
              "A large texture that was cheap to build should go first");
      Assert (Held (C, Shadow_Key (1))
                and then Held (C, Shadow_Key (3)),
              "The small expensive entries should both survive");
      Clear (C);
   end;

   --  Where total cost and cost per byte disagree, per byte decides. The
   --  large entry cost twenty-five times more to build in total, yet each
   --  of its bytes bought a quarter as much time; keeping it would spend
   --  88 times the room to save 25 times the work. Ranking on total cost
   --  alone would keep it and evict the small one.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (32) + Charge (300));
      Put (C, Shadow_Key (1), 32,  Micros => 200);  --   4 KB, 200us
      Put (C, Shadow_Key (2), 300, Micros => 5_000);  -- 351 KB,   5ms
      Put (C, Shadow_Key (3), 32,  Micros => 200);  --   4 KB, tips over

      Assert (not Held (C, Shadow_Key (2)),
              "The entry buying least time per byte should go, even though"
              & " it cost the most to build outright");
      Assert (Held (C, Shadow_Key (1))
                and then Held (C, Shadow_Key (3)),
              "The entries buying most time per byte should stay");
      Clear (C);
   end;

   --  Two textures of equal size are separated by what they cost.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (40) * KB);
      Put (C, Shadow_Key (1), 64, Micros => 5_000);   --  16 KB, 5ms
      Put (C, Shadow_Key (2), 64, Micros => 10);   --  16 KB, 10us
      Put (C, Shadow_Key (3), 64, Micros => 1_000);   --  16 KB, tips over

      Assert (not Held (C, Shadow_Key (2)),
              "The cheapest to rebuild should be evicted first");
      Assert (Held (C, Shadow_Key (1)),
              "The most expensive to rebuild should be kept");
      Clear (C);
   end;

   --  Use beats recency: an entry drawn every frame survives newcomers.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (40) * KB);
      Put (C, Shadow_Key (1), 64, Micros => 100);
      Put (C, Shadow_Key (2), 64, Micros => 100);

      for I in 1 .. 50 loop
         Touch (C, Shadow_Key (1));
      end loop;

      Put (C, Shadow_Key (3), 64, Micros => 100);

      Assert (Held (C, Shadow_Key (1)),
              "A heavily used entry should outlive a newly stored one");
      Assert (not Held (C, Shadow_Key (2)),
              "The entry used once should be the one dropped");
      Clear (C);
   end;

   --  Standing decays under pressure rather than with the clock. An entry
   --  that stops being used keeps whatever it earned, but every eviction
   --  raises the floor that newcomers start from, so it is overtaken by
   --  what is being used now. Nothing decays while there is room, which is
   --  the point: an idle cache should discard nothing.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64) * 3);
      Put (C, Shadow_Key (1), 64, Micros => 100);
      for I in 1 .. 50 loop
         Touch (C, Shadow_Key (1));
      end loop;
      Put (C, Shadow_Key (2), 64, Micros => 100);

      --  Churn: each store evicts something and lifts the floor. Entry 2
      --  is touched every round and keeps being re-based to the current
      --  floor; entry 1 is never touched again.
      for N in 0 .. 80 loop
         Touch (C, Shadow_Key (2));
         Put (C, (Kind => Shadow_Texture, Extent_A => 900 + N,
                  others => <>), 64, Micros => 100);
      end loop;

      Assert (not Held (C, Shadow_Key (1)),
              "An entry left untouched should be overtaken as the floor"
              & " rises beneath it");
      Assert (Held (C, Shadow_Key (2)),
              "An entry used through the churn should keep its place");
      Clear (C);
   end;

   --  The frame serial is modular and only breaks ties, but a wrap must
   --  not turn a just-used entry into the idlest one. Sit near the end of
   --  the serial, touch the entry, then cross the wrap before forcing an
   --  eviction, so recency is read across the discontinuity.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64) * 2);

      --  Two calls of Positive'Last leave the serial two short of wrapping.
      Advance_Frame (C, Frames => Positive'Last);
      Advance_Frame (C, Frames => Positive'Last);

      Put (C, Shadow_Key (1), 64, Micros => 100);
      Advance_Frame (C);                    --  so the two differ in age
      Put (C, Shadow_Key (2), 64, Micros => 100);
      Touch (C, Shadow_Key (2));   --  touched just before the wrap

      Advance_Frame (C, Frames => 8);       --  crosses it

      Put (C, Shadow_Key (3), 64, Micros => 100);

      Assert (Held (C, Shadow_Key (2)),
              "Crossing the serial's wrap should not make the most recently"
              & " used entry look like the idlest");
      Clear (C);
   end;

   --  A texture handed over must survive the call that hands it over, so
   --  the caller can draw with it. Storing one that alone exceeds the
   --  budget, with other entries resident, would otherwise let it be
   --  chosen as its own victim and destroyed under the caller.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64) * 2);
      Put (C, Shadow_Key (1), 64, Micros => 10_000);
      Put (C, Shadow_Key (2), 64, Micros => 10_000);

      --  Far past the budget, and worth far less per byte than either
      --  resident entry: exactly the entry the policy would discard.
      Put (C, Shadow_Key (3), 512, Micros => 1);

      Assert (Held (C, Shadow_Key (3)),
              "A newly stored texture must survive its own store, whatever"
              & " it is worth");
      Clear (C);
   end;

   --  Lowering the budget evicts now, rather than waiting for the next
   --  store: a budget describes what is resident.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64) * 4);
      for N in 1 .. 4 loop
         Put (C, Shadow_Key (N), 64, Micros => 100);
      end loop;
      Assert (Count (C) = 4, "All four should fit the original budget");

      Set_Budget (C, Charge (64));
      Assert (Count (C) = 1,
              "Lowering the budget should evict immediately:"
              & Natural'Image (Count (C)));
      Assert (Bytes_Used (C) <= Charge (64),
              "And should reach the new budget, not merely approach it");
      Clear (C);
   end;

   --  A texture bigger than the whole budget is kept rather than thrashed:
   --  evicting it would only mean rebuilding it on the next frame.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (16) * KB);
      Put (C, Shadow_Key (1), 512, Micros => 100);   --  1 MB, far past the budget

      Assert (Count (C) = 1,
              "An oversized texture should be held rather than dropped and"
              & " rebuilt every frame");
      Clear (C);
   end;

   --  Storing the same key twice replaces rather than accumulates.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (400) * KB);
      Put (C, Shadow_Key (1), 64, Micros => 100);
      Put (C, Shadow_Key (1), 64, Micros => 100);

      Assert (Count (C) = 1, "Re-storing a key should replace its entry");
      Assert (Bytes_Used (C) = Charge (64),
              "Re-storing should not charge for the entry twice:"
              & Byte_Count'Image (Bytes_Used (C)));
      Clear (C);
   end;

   --  Kinds share the budget but not their keys.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (400) * KB);
      Put (C, (Kind => Shadow_Texture, Extent_A => 7, others => <>), 64, Micros => 100);
      Put (C, (Kind => Raster_Texture, Extent_A => 7, others => <>), 64, Micros => 100);
      Put (C, (Kind => SVG_Texture, Extent_A => 7, others => <>), 64, Micros => 100);

      Assert (Count (C) = 3,
              "The same extents under different kinds are different keys");
      Clear (C);
   end;

   --  Charges near the type's ceiling must not be summed with what is
   --  already resident: two individually legal charges can exceed
   --  Byte_Count together, and forming that sum would raise before the
   --  cache had the chance to evict anything.
   declare
      C : Cache;
      --  Three quarters each: any two of them sum past Byte_Count'Last,
      --  so forming that sum at all raises.
      Huge : constant Texture_Charge := (Byte_Count'Last / 4) * 3;
   begin
      Set_Budget (C, Byte_Count'Last);
      for N in 1 .. 3 loop
         declare
            Ignore : constant Texture_Handle :=
              Store (C, Shadow_Key (N), New_Texture,
                     Width => 1, Height => 1, Bytes => Huge,
                     Build_Time => Adi.Clock.Microseconds (100));
         begin
            null;
         end;
      end loop;

      Assert (Bytes_Used (C) <= Byte_Count'Last,
              "Residency should stay inside the budget without overflowing"
              & " on the way");
      Clear (C);
   end;

   --  A borrow cannot be evicted, so its bytes stay charged even under
   --  pressure. When what is pinned leaves no room the arriving charge can
   --  be accounted for, the cache has to refuse rather than form a total
   --  its own type cannot hold.
   declare
      C : Cache;
      H : Texture_Handle;
      Huge : constant Texture_Charge := (Byte_Count'Last / 4) * 3;
   begin
      Set_Budget (C, Byte_Count'Last);
      H := Store (C, Shadow_Key (1), New_Texture, Width => 1, Height => 1,
                  Bytes => Huge,
                  Build_Time => Adi.Clock.Microseconds (100));
      Assert (Is_Valid (C, H), "The first oversized entry should be taken");

      declare
         Pin      : constant Texture_Ref := Borrow (C, H);
         Rejected : constant SDL_Texture_Ptr := New_Texture;
         Result   : Texture_Handle;
      begin
         pragma Assert (Pin.Texture /= null);

         Result := Store (C, Shadow_Key (2), Rejected,
                          Width => 1, Height => 1, Bytes => Huge,
                          Build_Time => Adi.Clock.Microseconds (100));

         Assert (not Is_Valid (C, Result),
                 "A charge that cannot be accounted for beside a pinned"
                 & " entry should be refused");
         Assert (Bytes_Used (C) = Byte_Count (Huge),
                 "A refused charge should leave residency where it was");

         --  Room was made before the charge was found unaccountable, so
         --  the resident it displaced is gone regardless. Its bytes stay
         --  charged only because a borrow still holds them.
         Assert (not Held (C, Shadow_Key (1)),
                 "Making room for a charge that is then refused still"
                 & " evicts what it displaced");

         --  Refused means the cache never took ownership, so releasing it
         --  is the caller's to do.
         SDL_DestroyTexture (Rejected);
      end;
      Clear (C);
   end;

   --  Cost keeps deciding after a run of evictions has driven the floor
   --  above where entries start. The floor stays far below the point at
   --  which standings saturate; that case is driven separately below.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64) * 2);

      --  Each store costs the ceiling in microseconds, so standings climb
      --  as fast as the type allows and the floor is driven upward hard.
      for N in 0 .. 400 loop
         Put (C, (Kind => Shadow_Texture, Extent_A => 3_000 + N,
                  others => <>), 64, Micros => Integer'Last / 4);
      end loop;

      --  Cost must still separate entries afterwards: an expensive one
      --  stored now should outlive a cheap one stored beside it.
      Put (C, Shadow_Key (1), 64, Micros => 100_000);
      Put (C, Shadow_Key (2), 64, Micros => 1);
      Put (C, Shadow_Key (3), 64, Micros => 100_000);

      Assert (not Held (C, Shadow_Key (2)),
              "With the floor raised, cost should still decide -- the cheap"
              & " entry is the one to drop");
      Assert (Held (C, Shadow_Key (1))
                or else Held (C, Shadow_Key (3)),
              "An expensive entry should have survived beside it");
      Clear (C);
   end;

   --  A standing is the floor plus what use has earned above it, so an
   --  unbounded floor eventually pins every standing at the top of the
   --  range, where cost and frequency separate nothing and the policy
   --  degrades to iteration order. Renormalising is what bounds it.
   --
   --  Driving that needs the extremes the ranking allows: an entry
   --  charged one byte, built at the longest cost the cache distinguishes,
   --  and used until its hit count saturates. Each eviction then lifts the
   --  floor by the most a single entry can contribute, and a handful of
   --  rounds would reach saturation if nothing brought the floor back.
   declare
      C : Cache;
      H : Texture_Handle;
   begin
      --  One byte holds one entry, so every store evicts its predecessor
      --  and every round contributes a full lift to the floor.
      Set_Budget (C, 1);

      for Round in 1 .. 8 loop
         H := Store (C, Shadow_Key (1_000 + Round), New_Texture,
                     Width => 1, Height => 1, Bytes => 1,
                     Build_Time => Adi.Clock.Microseconds (2 ** 30));

         --  Past any hit ceiling the cache imposes: once the count
         --  saturates the remaining borrows leave the standing where it is.
         for I in 1 .. 70_000 loop
            declare
               Ref : constant Texture_Ref := Borrow (C, H);
            begin
               pragma Assert (Ref.Texture /= null);
            end;
         end loop;
      end loop;

      --  Room for the tiny entry and two ordinary ones. Cost has to pick
      --  the victim; were the floor saturated, all three standings would
      --  be equal and the first entry visited would go instead.
      Set_Budget (C, Charge (64) * 2 + 1);
      Put (C, Shadow_Key (1), 64, Micros => 100_000);
      Put (C, Shadow_Key (2), 64, Micros => 1);
      Put (C, Shadow_Key (3), 64, Micros => 100_000);

      Assert (not Held (C, Shadow_Key (2)),
              "Renormalising should keep the floor low enough for cost to"
              & " decide, rather than letting every standing saturate");
      Assert (Held (C, Shadow_Key (1)) and then Held (C, Shadow_Key (3)),
              "Both expensive entries should have survived the cheap one");
      Clear (C);
   end;

   --  A handle stops being valid when its entry is evicted, and says so
   --  rather than resolving to freed memory.
   declare
      C : Cache;
      H : Texture_Handle;
   begin
      Set_Budget (C, Charge (64) * 2);
      H := Store (C, Shadow_Key (1), New_Texture, Width => 64, Height => 64,
                  Bytes => Charge (64),
                  Build_Time => Adi.Clock.Microseconds (10));
      Assert (Is_Valid (C, H), "A handle should be valid on return");

      Put (C, Shadow_Key (2), 64, Micros => 10_000);
      Put (C, Shadow_Key (3), 64, Micros => 10_000);

      Assert (not Is_Valid (C, H),
              "A handle should stop being valid once its entry is evicted");

      declare
         Ref : constant Texture_Ref := Borrow (C, H);
      begin
         Assert (Ref.Texture = null,
                 "Borrowing a stale handle should yield nothing to draw");
      end;
      Clear (C);
   end;

   --  A borrow pins: eviction during one defers, the texture stays usable
   --  for the length of the borrow, and its bytes stay charged because
   --  they cannot be reused yet.
   declare
      C : Cache;
      H : Texture_Handle;
   begin
      Set_Budget (C, Charge (64) * 2);
      H := Store (C, Shadow_Key (1), New_Texture, Width => 64, Height => 64,
                  Bytes => Charge (64),
                  Build_Time => Adi.Clock.Microseconds (10));

      declare
         Ref : constant Texture_Ref := Borrow (C, H);
      begin
         Assert (Ref.Texture /= null, "A live handle should borrow");

         --  Force it out while the borrow is open.
         Put (C, Shadow_Key (2), 64, Micros => 10_000);
         Put (C, Shadow_Key (3), 64, Micros => 10_000);

         Assert (not Held (C, Shadow_Key (1)),
                 "An evicted entry should stop being findable at once");
         Assert (Ref.Texture /= null,
                 "The borrowed texture must stay usable until the borrow"
                 & " ends");
         Assert (Bytes_Used (C) > Charge (64) * 2 - Charge (64),
                 "Bytes awaiting the end of a borrow are still charged");
      end;

      --  Borrow over: the deferred destruction can complete.
      Assert (Bytes_Used (C) <= Charge (64) * 2,
              "Ending the last borrow should release the bytes");
      Clear (C);
   end;

   --  Two caches recycle slots independently, so a handle from one must
   --  not resolve in the other even when slot and generation coincide.
   declare
      A, B : Cache;
      H    : Texture_Handle;
   begin
      Set_Budget (A, Charge (64) * 4);
      Set_Budget (B, Charge (64) * 4);
      H := Store (A, Shadow_Key (1), New_Texture,
                  Width => 64, Height => 64, Bytes => Charge (64),
                  Build_Time => Adi.Clock.Microseconds (10));
      Put (B, Shadow_Key (1), 64, Micros => 10);

      Assert (Is_Valid (A, H), "The issuing cache should accept it");
      Assert (not Is_Valid (B, H),
              "Another cache must not accept a handle it never issued");
      Clear (A);
      Clear (B);
   end;

   --  A borrow may outlive the cache. The bookkeeping has to survive
   --  until that borrow ends -- otherwise ending it reads freed memory --
   --  and the texture must not, because its renderer is going.
   --
   --  The cache is on the heap so that it can be finalized from inside the
   --  borrow's scope. A cache in an enclosing block would be finalized
   --  after the borrow, which is the ordering this is not about.
   declare
      C : Cache_Access := new Cache;
      H : Texture_Handle;
   begin
      Set_Budget (C.all, Charge (64) * 4);
      H := Store (C.all, Shadow_Key (1), New_Texture,
                  Width => 64, Height => 64, Bytes => Charge (64),
                  Build_Time => Adi.Clock.Microseconds (10));

      declare
         Ref : constant Texture_Ref := Borrow (C.all, H);
      begin
         Assert (Ref.Texture /= null, "Borrowed while the cache lives");

         Free_Cache (C);

         Assert (Ref.Texture = null,
                 "A texture should go with the renderer that owns it, even"
                 & " under borrow");
         Assert (Ref.Width = 64 and then Ref.Height = 64,
                 "The borrowed region should still be readable after its"
                 & " cache is gone");
      end;
      --  Reaching here means the borrow's finalization ran after its
      --  cache's and did not touch freed bookkeeping.
      Assert (True, "A borrow outliving its cache should unwind cleanly");
   end;

   --  Borrowed regions must not move when the slot table grows. Storing
   --  many entries while one is borrowed reallocates that table; a region
   --  pointing into it would be left dangling.
   declare
      C : Cache;
      H : Texture_Handle;
   begin
      Set_Budget (C, Charge (64) * 200);
      H := Store (C, Shadow_Key (1), New_Texture, Width => 64, Height => 64,
                  Bytes => Charge (64),
                  Build_Time => Adi.Clock.Microseconds (10_000));

      declare
         Ref : constant Texture_Ref := Borrow (C, H);
         Before : constant Adi.SDL.Render.SDL_Texture_Ptr := Ref.Texture;
      begin
         for N in 0 .. 150 loop
            Put (C, (Kind => Shadow_Texture, Extent_A => 6_000 + N,
                     others => <>), 64, Micros => 10);
         end loop;

         Assert (Ref.Texture = Before,
                 "A borrowed region should survive the slot table growing"
                 & " under it");
         Assert (Ref.Width = 64 and then Ref.Height = 64,
                 "And should still describe the same texture");
      end;
      Clear (C);
   end;

   --  Clear releases everything.
   declare
      C : Cache;
   begin
      Set_Budget (C, Byte_Count (400) * KB);
      Put (C, Shadow_Key (1), 64, Micros => 100);
      Clear (C);
      Assert (Count (C) = 0 and then Bytes_Used (C) = 0,
              "Clear should release every entry");
      Assert (not Held (C, Shadow_Key (1)),
              "Nothing should be findable after Clear");
   end;

   SDL_DestroyRenderer (Renderer);
   SDL_DestroySurface (Canvas);

   Finish;
end Texture_Cache_Test;
