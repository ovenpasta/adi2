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

   --  Let everything stored so far fall out of the scene. An entry is
   --  active for the frame it was used in and the one after, so two
   --  advances make it idle; the second is also what runs the trim.
   procedure Settle (C : in out Cache) is
   begin
      Advance_Frame (C);
      Advance_Frame (C);
   end Settle;

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
      Settle (C);

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

      Settle (C);

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

      Settle (C);

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

      Settle (C);

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

      Settle (C);

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

      Settle (C);

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
      for N in 0 .. 400 loop
         Touch (C, Shadow_Key (2));
         Put (C, (Kind => Shadow_Texture, Extent_A => 900 + N,
                  others => <>), 64, Micros => 100);
         --  A round is a frame: without one nothing falls out of the
         --  scene, and a cache holding a scene evicts nothing.
         Advance_Frame (C);
      end loop;

      Assert (not Held (C, Shadow_Key (1)),
              "An entry left untouched should be overtaken as the floor"
              & " rises beneath it");
      Assert (Held (C, Shadow_Key (2)),
              "An entry used through the churn should keep its place");
      Clear (C);
   end;

   --  Recency alone, with nothing else to separate the candidates. Equal
   --  charge, equal cost and one use each leave the standings identical,
   --  so the idle tiebreak is the only thing that can pick a victim.
   --
   --  Neither entry is touched: borrowing counts a hit, which raises a
   --  standing and settles the choice before recency is consulted. The
   --  keys are stored in reverse, so the older entry is the one the key
   --  map visits second -- without the tiebreak the first visited is
   --  taken, which is the newer entry, and the assertions fail.
   declare
      C : Cache;
   begin
      --  Room for one idle entry, so exactly one of the two must go.
      Set_Budget (C, Charge (64));

      Put (C, Shadow_Key (2), 64, Micros => 100);   --  older, sorts later
      Advance_Frame (C);
      Put (C, Shadow_Key (1), 64, Micros => 100);   --  newer, sorts first
      Advance_Frame (C);
      Advance_Frame (C);   --  both are idle now, and the trim runs

      Assert (Held (C, Shadow_Key (1)),
              "Between entries of equal standing, the more recently used"
              & " should stay");
      Assert (not Held (C, Shadow_Key (2)),
              "and the idlest should be the one dropped, whatever order"
              & " the keys happen to sort in");
      Clear (C);
   end;

   --  The frame serial is modular and only breaks ties, but a wrap must
   --  not turn a recent entry into the idlest one. Sit near the end of the
   --  serial, store the two a frame apart, then cross the wrap before
   --  forcing an eviction, so recency is read across the discontinuity.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64));

      --  Two calls of Positive'Last leave the serial two short of wrapping.
      Advance_Frame (C, Frames => Positive'Last);
      Advance_Frame (C, Frames => Positive'Last);

      --  Reversed, as above: the older entry sorts later, so map order
      --  alone would keep the wrong one. Neither is touched, since a hit
      --  would settle the choice on standing before recency is read.
      Put (C, Shadow_Key (2), 64, Micros => 100);   --  older, sorts later
      Advance_Frame (C);
      Put (C, Shadow_Key (1), 64, Micros => 100);   --  newer, sorts first

      Advance_Frame (C, Frames => 8);       --  crosses the wrap

      Put (C, Shadow_Key (3), 64, Micros => 100);
      Advance_Frame (C);   --  1 and 2 are idle; 3 is not, and the trim runs

      Assert (Held (C, Shadow_Key (1)),
              "Crossing the serial's wrap should not make the most recently"
              & " used entry look like the idlest");
      Assert (not Held (C, Shadow_Key (2)),
              "and the genuinely idler entry should still be the victim");
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

      --  Idle, so the budget applies to them at all.
      Settle (C);
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

   --  A budget bounds what the cache retains, not what the scene needs.
   --  Two textures that are both drawn every frame do not fit together
   --  under this budget, and evicting either to admit the other rebuilds
   --  it a frame later: the pair would be rebuilt for as long as the
   --  scene is displayed, having been used the whole time.
   declare
      C : Cache;
      A : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 1, others => <>);
      B : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 2, others => <>);
   begin
      --  Room for one of them, not both.
      Set_Budget (C, Charge (64) + Charge (64) / 2);

      Advance_Frame (C);
      Put (C, A, 64, Micros => 1_000);
      Put (C, B, 64, Micros => 1_000);

      Assert (Held (C, A) and then Held (C, B),
              "Both textures the frame is drawing should be resident, even"
              & " together exceeding the budget");

      --  Second frame: both are drawn again, so both should be found
      --  rather than rebuilt.
      Advance_Frame (C);
      Touch (C, A);
      Touch (C, B);

      Assert (Statistics (C) (Shadow_Texture).Stores = 2,
              "and drawing them again should build nothing: a texture used"
              & " every frame is not what a budget is meant to reclaim");
      Assert (Statistics (C) (Shadow_Texture).Pressure = 0,
              "nor evict anything under pressure");
      Clear (C);
   end;

   --  An entry is protected for the frame it was drawn in and the one
   --  after, because the frame advances before the scene is traversed: a
   --  texture drawn last frame is about to be asked for again.
   declare
      C : Cache;
   begin
      Set_Budget (C, 0);   --  retain nothing idle

      Put (C, Shadow_Key (1), 64, Micros => 100);

      Advance_Frame (C);
      Assert (Held (C, Shadow_Key (1)),
              "An entry drawn in the previous frame is still in the scene"
              & " and must survive a budget that retains nothing");

      Advance_Frame (C);
      Assert (not Held (C, Shadow_Key (1)),
              "A second frame without it makes it idle, and a budget of"
              & " nothing keeps nothing");
      Clear (C);
   end;

   --  Drawing two things in either order must not make them take turns.
   --  A cache that evicted to admit would rebuild whichever was drawn
   --  first, every frame, for as long as both were on screen.
   declare
      C : Cache;
      A : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 1, others => <>);
      B : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 2, others => <>);
   begin
      Set_Budget (C, 0);
      Put (C, A, 64, Micros => 1_000);
      Put (C, B, 64, Micros => 1_000);

      for Frame in 1 .. 20 loop
         Advance_Frame (C);
         --  Alternating, so neither is consistently the older.
         if Frame mod 2 = 0 then
            Touch (C, A);
            Touch (C, B);
         else
            Touch (C, B);
            Touch (C, A);
         end if;
      end loop;

      Assert (Held (C, A) and then Held (C, B),
              "Two textures drawn every frame should both survive twenty"
              & " frames of it, in whichever order they are drawn");
      Assert (Statistics (C) (Shadow_Texture).Pressure = 0,
              "and nothing should have been evicted under pressure");
      Clear (C);
   end;

   --  A texture the scene keeps using survives a budget lowered beneath
   --  it, while what has fallen out of the scene does not.
   declare
      C : Cache;
      Live : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 1, others => <>);
      Gone : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 2, others => <>);
   begin
      Set_Budget (C, Charge (64) * 4);
      Put (C, Live, 64, Micros => 100);
      Put (C, Gone, 64, Micros => 100);

      --  Two frames on, with only one of them still drawn.
      Advance_Frame (C);
      Touch (C, Live);
      Advance_Frame (C);
      Touch (C, Live);

      Set_Budget (C, 0);

      Assert (Held (C, Live),
              "Lowering the budget must not take what the scene is drawing");
      Assert (not Held (C, Gone),
              "but should take what it is not");
      Clear (C);
   end;

   --  Protection is a modular distance, so an entry drawn just before the
   --  serial wraps must not look ancient just after it.
   declare
      C : Cache;
   begin
      Set_Budget (C, 0);
      Advance_Frame (C, Frames => Positive'Last);
      Advance_Frame (C, Frames => Positive'Last);
      Advance_Frame (C);   --  one short of the wrap

      --  Drawn in the last frame before the serial turns over.
      Put (C, Shadow_Key (1), 64, Micros => 100);

      Advance_Frame (C);   --  crosses it: the distance is one, not 2**32

      Assert (Held (C, Shadow_Key (1)),
              "An entry drawn in the frame before the serial wraps is one"
              & " frame old after it, not an age, and stays protected");

      --  And it still goes idle on schedule afterwards.
      Advance_Frame (C);
      Assert (not Held (C, Shadow_Key (1)),
              "and becomes idle a frame later as it would anywhere else");
      Clear (C);
   end;

   --  A texture too large for the budget, drawn every frame, is stored
   --  once and found thereafter. Rebuilding it per frame is the failure a
   --  scene-aware budget exists to prevent.
   declare
      C : Cache;
      Big : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 1, others => <>);
   begin
      Set_Budget (C, Charge (64));      --  far smaller than the entry
      Put (C, Big, 512, Micros => 50_000);

      for Frame in 1 .. 30 loop
         Advance_Frame (C);
         Touch (C, Big);
      end loop;

      Assert (Statistics (C) (Raster_Texture).Stores = 1,
              "A texture larger than the budget but drawn every frame"
              & " should be built once");
      Assert (Statistics (C) (Raster_Texture).Pressure = 0,
              "and never evicted while the scene is using it");
      Assert (Held (C, Big), "and still be there at the end");
      Clear (C);
   end;

   --  Diagnostics exist to choose a budget, so what they have to get
   --  right is which producer filled it and whether the budget was the
   --  thing that bit.
   declare
      C : Cache;
      SK : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 1, others => <>);
      RK : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 7, others => <>);
   begin
      Set_Budget (C, Byte_Count (400) * KB);

      Put (C, SK, 64, Micros => 100);
      Put (C, RK, 32, Micros => 400);

      Assert (Statistics (C) (Shadow_Texture).Bytes = Charge (64)
                and then Statistics (C) (Raster_Texture).Bytes = Charge (32),
              "Residency should be attributed to the kind that stored it");
      Assert (Statistics (C) (SVG_Texture).Bytes = 0,
              "and a kind that stored nothing should show nothing");
      Assert (Statistics (C) (Shadow_Texture).Stores = 1
                and then Statistics (C) (Raster_Texture).Stores = 1,
              "each store counted against its own kind");

      --  The per-kind figures are a partition of residency, not a
      --  parallel tally: if they drift, the budget and the diagnostics
      --  disagree about the same bytes.
      declare
         Sum : Byte_Count := 0;
      begin
         for K in Texture_Kind loop
            Sum := Sum + Statistics (C) (K).Bytes;
         end loop;
         Assert (Sum = Bytes_Used (C),
                 "Per-kind residency should sum to what the budget works"
                 & " against");
      end;

      --  A lookup that resolves and one that does not.
      declare
         Ignore : Texture_Handle;
      begin
         Ignore := Find (C, SK);
         Ignore := Find (C, (Kind => Shadow_Texture, Extent_A => 999,
                             others => <>));
      end;

      Assert (Statistics (C) (Shadow_Texture).Hits = 1
                and then Statistics (C) (Shadow_Texture).Misses = 1,
              "A lookup that finds an entry is a hit and one that does not"
              & " is a miss, which is what costs a rebuild");

      --  Peak outlives the residency that set it: a budget has to cover
      --  the worst moment, and a cache read while idle looks comfortable
      --  at any figure.
      declare
         Was : constant Byte_Count := Bytes_Used (C);
      begin
         Clear (C);
         Assert (Bytes_Used (C) = 0, "Clear empties the cache");
         Assert (Peak_Bytes_Used (C) >= Was,
                 "but peak residency should remember what it held");
      end;
   end;

   --  Only pressure reflects on the budget. Replacing a key, clearing,
   --  and teardown are the program's own doing, and counting them as
   --  pressure would make any budget look thrashed at shutdown.
   declare
      C : Cache;
   begin
      Set_Budget (C, Charge (64) * 2);

      Put (C, Shadow_Key (1), 64, Micros => 100);
      Put (C, Shadow_Key (2), 64, Micros => 100);
      Put (C, Shadow_Key (3), 64, Micros => 100);
      Settle (C);   --  all idle, so the budget now applies to them

      Assert (Statistics (C) (Shadow_Texture).Pressure = 1,
              "An entry dropped to make room counts as pressure");
      Assert (Statistics (C) (Shadow_Texture).Replaced = 0,
              "and nothing was replaced");

      --  Same key again: the entry it displaces did not go for room.
      Put (C, Shadow_Key (3), 64, Micros => 100);

      Assert (Statistics (C) (Shadow_Texture).Replaced = 1,
              "A source rebuilt under a stable key replaces rather than"
              & " being evicted for room");

      declare
         Before : constant Event_Count :=
           Statistics (C) (Shadow_Texture).Pressure;
      begin
         Clear (C);
         Assert (Statistics (C) (Shadow_Texture).Pressure = Before,
                 "and clearing the cache is not pressure either");
         Assert (Statistics (C) (Shadow_Texture).Cleared > 0,
                 "though it is counted, under its own cause");
         Assert (Statistics (C) (Shadow_Texture).Discarded = 0,
                 "and an explicit Clear is not the cache going away");
      end;

      --  Checked again now that entries have been evicted, replaced and
      --  cleared: an attribution that only adds would still agree with
      --  residency before anything left.
      declare
         Sum : Byte_Count := 0;
      begin
         for K in Texture_Kind loop
            Sum := Sum + Statistics (C) (K).Bytes;
         end loop;
         Assert (Sum = Bytes_Used (C),
                 "Per-kind residency should still sum to the total after"
                 & " entries have left by every route");
      end;
   end;

   --  The partitions describe the same cache the trim works on, so they
   --  have to divide residency exactly. All three states are held at
   --  once: one entry the scene keeps drawing, one that has fallen out of
   --  it, and one displaced under an open lease.
   declare
      C : Cache;
      Live : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 1, others => <>);
      Aged : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 2, others => <>);
      Slot_Key : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 3, others => <>);
      H : Texture_Handle;
   begin
      --  Generous, so nothing is trimmed and the partitions are what the
      --  test arranged rather than what eviction left.
      Set_Budget (C, Byte_Count (400) * KB);

      Put (C, Live, 64, Micros => 100);
      Put (C, Aged, 48, Micros => 100);
      H := Store (C, Slot_Key, New_Texture, Width => 32, Height => 32,
                  Bytes => Charge (32),
                  Build_Time => Adi.Clock.Microseconds (100));

      declare
         Lease : constant Texture_Ref := Borrow (C, H);
      begin
         pragma Assert (Lease.Texture /= null);

         --  Two frames on, drawing Live and the leased entry but not
         --  Aged, which therefore goes idle.
         Advance_Frame (C);
         Touch (C, Live);
         Advance_Frame (C);
         Touch (C, Live);

         --  The same key again while the first is still leased: the old
         --  value becomes retired, the replacement is active.
         declare
            Replacement : constant Texture_Handle :=
              Store (C, Slot_Key, New_Texture, Width => 32, Height => 32,
                     Bytes => Charge (32),
                     Build_Time => Adi.Clock.Microseconds (100));
         begin
            Assert (Is_Valid (C, Replacement),
                    "A key stored again under an open lease should take");
            Assert (not Is_Valid (C, H),
                    "and the handle to what it displaced should stop"
                    & " resolving");
         end;

         declare
            S : constant Kind_Stats_Array := Statistics (C);
            Bytes_Sum : Byte_Count := 0;
            Count_Sum : Natural := 0;
         begin
            --  Exact figures, so a branch that never ran would show.
            Assert (S (Shadow_Texture).Active_Bytes = Charge (64),
                    "The entry drawn this frame is active");
            Assert (S (Shadow_Texture).Idle_Bytes = Charge (48),
                    "the one nothing has drawn for two frames is idle");
            Assert (S (Shadow_Texture).Retired_Bytes = 0,
                    "and neither is retired");
            Assert (S (Raster_Texture).Active_Bytes = Charge (32),
                    "The replacement is active");
            Assert (S (Raster_Texture).Retired_Bytes = Charge (32),
                    "and what it displaced is retired, still charged"
                    & " because a lease holds it");
            Assert (S (Raster_Texture).Idle_Bytes = 0,
                    "with nothing idle");

            Assert (S (Shadow_Texture).Active_Count = 1
                      and then S (Shadow_Texture).Idle_Count = 1
                      and then S (Raster_Texture).Active_Count = 1
                      and then S (Raster_Texture).Retired_Count = 1,
                    "and the counts should agree with the bytes");

            for K in Texture_Kind loop
               Assert (S (K).Active_Bytes + S (K).Idle_Bytes
                         + S (K).Retired_Bytes = S (K).Bytes,
                       "Active, idle and retired bytes should divide what"
                       & " the kind holds");
               Assert (S (K).Active_Count + S (K).Idle_Count = S (K).Count,
                       "and the findable counts should divide Count, which"
                       & " retired entries are outside of");
               Bytes_Sum := Bytes_Sum + S (K).Bytes;
               Count_Sum := Count_Sum + S (K).Count;
            end loop;

            Assert (Bytes_Sum = Bytes_Used (C),
                    "summing to total residency");
            Assert (Count_Sum = Count (C), "and to the findable count");
            Assert (Idle_Bytes_Used (C) = Charge (48),
                    "and the figure the budget is compared against should"
                    & " be the idle one alone");
         end;
      end;
      Clear (C);
   end;

   --  Headroom is arithmetic, not policy. An eviction made so that a
   --  charge can be added without leaving what Byte_Count can hold says
   --  nothing about the budget, and reporting it as pressure would.
   declare
      C : Cache;
      Huge : constant Texture_Charge := (Byte_Count'Last / 4) * 3;
   begin
      Set_Budget (C, Byte_Count'Last);

      Put (C, Shadow_Key (1), 1, Micros => 100);
      Advance_Frame (C);
      Advance_Frame (C);   --  idle, so it can be taken for headroom

      declare
         Ignore : constant Texture_Handle :=
           Store (C, Shadow_Key (2), New_Texture, Width => 1, Height => 1,
                  Bytes => Huge, Build_Time => Adi.Clock.Microseconds (10));
         pragma Unreferenced (Ignore);
      begin
         null;
      end;

      declare
         Ignore : constant Texture_Handle :=
           Store (C, Shadow_Key (3), New_Texture, Width => 1, Height => 1,
                  Bytes => Huge, Build_Time => Adi.Clock.Microseconds (10));
         pragma Unreferenced (Ignore);
      begin
         null;
      end;

      Assert (Statistics (C) (Shadow_Texture).Headroom > 0,
              "An eviction made for arithmetic room should be counted as"
              & " headroom");
      Assert (Statistics (C) (Shadow_Texture).Pressure = 0,
              "and never as budget pressure: the budget was never the"
              & " thing that bit");
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

         --  Nothing was displaced. The only entry resident is borrowed,
         --  so it is in use and not a candidate; the arriving charge is
         --  refused rather than paid for by dropping what the caller is
         --  drawing with.
         Assert (Held (C, Shadow_Key (1)),
                 "A refused charge should leave the entry it could not fit"
                 & " beside untouched");

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

      --  A long run of frames, each storing something and dropping what
      --  went idle. Every eviction lifts the floor, so by the end entries
      --  start far above where the first ones did. The cost here is
      --  modest on purpose: the churn is meant to raise the floor, not to
      --  leave behind entries that outrank everything stored later.
      for N in 0 .. 400 loop
         Put (C, (Kind => Shadow_Texture, Extent_A => 3_000 + N,
                  others => <>), 64, Micros => 1_000);
         Advance_Frame (C);
      end loop;

      --  Cost must still separate entries afterwards: an expensive one
      --  stored now should outlive a cheap one stored beside it.
      Put (C, Shadow_Key (1), 64, Micros => 100_000);
      Put (C, Shadow_Key (2), 64, Micros => 1);
      Put (C, Shadow_Key (3), 64, Micros => 100_000);
      Settle (C);

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
      --  Nothing idle may be retained, so each round's entry goes as soon
      --  as the next frame makes it idle, and every eviction lifts the
      --  floor by the most a single entry can contribute.
      Set_Budget (C, 0);

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

         --  A round is a frame: the previous round's entry becomes idle
         --  here and is evicted, which is what raises the floor.
         Advance_Frame (C);
      end loop;

      --  Room for the tiny entry and two ordinary ones. Cost has to pick
      --  the victim; were the floor saturated, all three standings would
      --  be equal and the first entry visited would go instead.
      Set_Budget (C, Charge (64) * 2 + 1);
      Put (C, Shadow_Key (1), 64, Micros => 100_000);
      Put (C, Shadow_Key (2), 64, Micros => 1);
      Put (C, Shadow_Key (3), 64, Micros => 100_000);
      Settle (C);

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
      Settle (C);

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

         --  Pressure cannot reach it: a borrowed entry is in use, and the
         --  budget only ever takes idle ones. Clear is the route that can,
         --  being an explicit instruction rather than a policy decision.
         Clear (C);

         Assert (not Held (C, Shadow_Key (1)),
                 "An entry cleared under an open borrow should stop being"
                 & " findable at once");
         Assert (Ref.Texture /= null,
                 "The borrowed texture must stay usable until the borrow"
                 & " ends");
         Assert (Bytes_Used (C) = Charge (64),
                 "Bytes awaiting the end of a borrow are still charged");
      end;

      --  Borrow over: the deferred destruction can complete.
      Assert (Bytes_Used (C) = 0,
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

   ---------------------------------------------------------------------------
   --  Groups
   ---------------------------------------------------------------------------

   --  Releasing a group takes its members and nothing else. An animation
   --  finishing must not disturb the shadows and images beside it.
   declare
      C : Cache;
      G : aliased Texture_Group;
      Member_1 : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 10, others => <>);
      Member_2 : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 11, others => <>);
      Stranger : constant Texture_Key :=
        (Kind => Shadow_Texture, Extent_A => 5, others => <>);
      H1, H2 : Texture_Handle;
   begin
      Set_Budget (C, Byte_Count (400) * KB);

      H1 := Store (C, Member_1, New_Texture, Width => 32, Height => 32,
                   Bytes => Charge (32),
                   Build_Time => Adi.Clock.Microseconds (100),
                   Group => G'Access);
      H2 := Store (C, Member_2, New_Texture, Width => 32, Height => 32,
                   Bytes => Charge (32),
                   Build_Time => Adi.Clock.Microseconds (100),
                   Group => G'Access);
      Put (C, Stranger, 64, Micros => 100);

      Assert (Count (C) = 3, "three entries, two of them grouped");

      Release (G);

      Assert (not Is_Valid (C, H1) and then not Is_Valid (C, H2),
              "Every member of a released group stops being findable at"
              & " once, without waiting for pressure");
      Assert (not Held (C, Member_1) and then not Held (C, Member_2),
              "and their keys stop resolving");
      Assert (Held (C, Stranger),
              "while a texture that was never in the group is untouched:"
              & " releasing one thing must not disturb another");
      Assert (Count (C) = 1, "leaving only the stranger");
      Assert (Bytes_Used (C) = Charge (64),
              "and charging only what remains");

      --  Accounted as lifecycle, not as the budget biting.
      Assert (Statistics (C) (Raster_Texture).Released = 2,
              "The two are counted as released with their group");
      Assert (Statistics (C) (Raster_Texture).Pressure = 0,
              "and not as pressure: the program said they were finished"
              & " with, which says nothing about the budget");
      Assert (Statistics (C) (Raster_Texture).Replaced = 0
                and then Statistics (C) (Raster_Texture).Cleared = 0
                and then Statistics (C) (Raster_Texture).Discarded = 0
                and then Statistics (C) (Raster_Texture).Headroom = 0,
              "nor as any of the other ways an entry can leave");
      Clear (C);
   end;

   --  A group spans caches. One animation drawn in two windows has frames
   --  in two renderers' caches, and releasing it has to reach both.
   declare
      A, B : Cache;
      G : aliased Texture_Group;
      K : constant Texture_Key :=
        (Kind => SVG_Texture, Source => 20, others => <>);
      HA, HB : Texture_Handle;
   begin
      Set_Budget (A, Byte_Count (400) * KB);
      Set_Budget (B, Byte_Count (400) * KB);

      HA := Store (A, K, New_Texture, Width => 16, Height => 16,
                   Bytes => Charge (16),
                   Build_Time => Adi.Clock.Microseconds (100),
                   Group => G'Access);
      HB := Store (B, K, New_Texture, Width => 16, Height => 16,
                   Bytes => Charge (16),
                   Build_Time => Adi.Clock.Microseconds (100),
                   Group => G'Access);

      Assert (Is_Valid (A, HA) and then Is_Valid (B, HB),
              "the same group stores into two caches");

      Release (G);

      Assert (not Is_Valid (A, HA) and then not Is_Valid (B, HB),
              "Releasing reaches every cache the group stored into, not"
              & " merely the last or the first");
      Assert (Count (A) = 0 and then Count (B) = 0,
              "leaving neither holding anything");
   end;

   --  Released while borrowed: unfindable at once, destroyed when the
   --  borrow ends, readable throughout.
   declare
      C : Cache;
      G : aliased Texture_Group;
      K : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 30, others => <>);
      H : Texture_Handle;
   begin
      Set_Budget (C, Byte_Count (400) * KB);
      H := Store (C, K, New_Texture, Width => 32, Height => 32,
                  Bytes => Charge (32),
                  Build_Time => Adi.Clock.Microseconds (100),
                  Group => G'Access);

      declare
         Ref : constant Texture_Ref := Borrow (C, H);
      begin
         Release (G);

         Assert (not Held (C, K),
                 "A released member stops being findable even while a"
                 & " draw holds it");
         Assert (Ref.Texture /= null,
                 "but the draw keeps what it is drawing with");
         Assert (Bytes_Used (C) = Charge (32),
                 "and its bytes stay charged, being unreclaimable yet");

         declare
            S : constant Kind_Stats_Array := Statistics (C);
         begin
            Assert (S (Raster_Texture).Retired_Bytes = Charge (32),
                    "counted as retired rather than active or idle");
            Assert (S (Raster_Texture).Active_Bytes = 0
                      and then S (Raster_Texture).Idle_Bytes = 0,
                    "with the partition still exact");
         end;
      end;

      Assert (Bytes_Used (C) = 0,
              "Ending the last borrow completes the deferred destruction");
      Clear (C);
   end;

   --  Releasing twice is not an error, and the second does nothing.
   declare
      C : Cache;
      G : aliased Texture_Group;
      K : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 40, others => <>);
      H : Texture_Handle;
   begin
      Set_Budget (C, Byte_Count (400) * KB);
      H := Store (C, K, New_Texture, Width => 16, Height => 16,
                  Bytes => Charge (16),
                  Build_Time => Adi.Clock.Microseconds (100),
                  Group => G'Access);
      pragma Assert (Is_Valid (C, H));

      Release (G);
      Release (G);

      Assert (Statistics (C) (Raster_Texture).Released = 1,
              "Releasing an already released group counts nothing further:"
              & " there is nothing left in it to release");
      Assert (not Is_Open (G), "and it stays closed");
      Clear (C);
   end;

   --  A closed group refuses stores rather than admitting a texture that
   --  would outlive the decision that released its siblings -- and
   --  refuses before displacing anything, which only a store under an
   --  occupied key can show.
   declare
      C : Cache;
      G : aliased Texture_Group;
      Occupied : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 50, others => <>);
      Sitting : Texture_Handle;
      Tex     : SDL_Texture_Ptr;
      H       : Texture_Handle;
   begin
      Set_Budget (C, Byte_Count (400) * KB);

      Sitting := Store (C, Occupied, New_Texture, Width => 32, Height => 32,
                        Bytes => Charge (32),
                        Build_Time => Adi.Clock.Microseconds (100));
      Assert (Is_Valid (C, Sitting), "an entry is sitting under the key");

      Release (G);

      --  Same key, so accepting this would retire what is there. The
      --  refusal has to come first.
      Tex := New_Texture;
      H := Store (C, Occupied, Tex, Width => 32, Height => 32,
                  Bytes => Charge (32),
                  Build_Time => Adi.Clock.Microseconds (100),
                  Group => G'Access);

      Assert (not Is_Valid (C, H),
              "A store into a released group is refused");
      Assert (Is_Valid (C, Sitting),
              "and refused before displacing: the entry already under that"
              & " key is still the one there");
      Assert (Held (C, Occupied) and then Count (C) = 1,
              "so the cache is exactly as it was");

      --  Refused means the caller still owns what it offered.
      SDL_DestroyTexture (Tex);
      Clear (C);
   end;

   --  Two groups are two lifetimes. Releasing one must leave the other
   --  alone, which only members of a second group can show -- an
   --  ungrouped bystander would survive a release that ignored group
   --  identity altogether.
   declare
      C : Cache;
      G1, G2 : aliased Texture_Group;
      In_1 : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 60, others => <>);
      In_2 : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 61, others => <>);
      H1, H2 : Texture_Handle;
   begin
      Set_Budget (C, Byte_Count (400) * KB);
      H1 := Store (C, In_1, New_Texture, Width => 32, Height => 32,
                   Bytes => Charge (32),
                   Build_Time => Adi.Clock.Microseconds (100),
                   Group => G1'Access);
      H2 := Store (C, In_2, New_Texture, Width => 32, Height => 32,
                   Bytes => Charge (32),
                   Build_Time => Adi.Clock.Microseconds (100),
                   Group => G2'Access);

      Release (G1);

      Assert (not Is_Valid (C, H1), "the released group's member goes");
      Assert (Is_Valid (C, H2),
              "and the other group's member stays: releasing is by group,"
              & " not by being grouped at all");
      Assert (Is_Open (G2), "the untouched group is still open");

      Release (G2);
      Assert (not Is_Valid (C, H2), "and releasing it takes its member");
      Clear (C);
   end;

   --  A group need not be released explicitly. Leaving its scope is the
   --  same instruction, which is what makes an animation's frames go when
   --  the animation does.
   declare
      C : Cache;
      K : constant Texture_Key :=
        (Kind => SVG_Texture, Source => 70, others => <>);
      H : Texture_Handle;
   begin
      Set_Budget (C, Byte_Count (400) * KB);

      declare
         G : aliased Texture_Group;
      begin
         H := Store (C, K, New_Texture, Width => 32, Height => 32,
                     Bytes => Charge (32),
                     Build_Time => Adi.Clock.Microseconds (100),
                     Group => G'Access);
         Assert (Is_Valid (C, H), "resident while the group lives");
      end;

      Assert (not Is_Valid (C, H),
              "Leaving a group's scope releases it, so its members go"
              & " without anybody having said so");
      Assert (Count (C) = 0, "and the cache is empty");
      Clear (C);
   end;

   --  Releasing a group whose renderer has already gone. The group holds
   --  the cache's bookkeeping alive to be able to reach it, and finds it
   --  reporting that there is nothing left to do.
   declare
      G : aliased Texture_Group;
      CP : Cache_Access := new Cache;
      K : constant Texture_Key :=
        (Kind => Raster_Texture, Source => 80, others => <>);
      H : Texture_Handle;
   begin
      Set_Budget (CP.all, Byte_Count (400) * KB);
      H := Store (CP.all, K, New_Texture, Width => 32, Height => 32,
                  Bytes => Charge (32),
                  Build_Time => Adi.Clock.Microseconds (100),
                  Group => G'Access);
      pragma Assert (Is_Valid (CP.all, H));

      --  The renderer goes first, taking its textures with it.
      Free_Cache (CP);

      --  Reaching the next line at all is the assertion: the group still
      --  points at that cache and must find it safely gone rather than
      --  walking freed slots.
      Release (G);

      Assert (not Is_Open (G),
              "Releasing a group after its cache has gone should be a safe"
              & " no-op there, not a walk through freed bookkeeping");
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
