--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
with Adi.Clock;
with Adi.SDL.Render;

--  GPU textures belonging to one renderer, held under one memory budget.
--
--  Producer-agnostic rather than renderer-agnostic: the keys say nothing
--  about what built a texture, but every texture in one cache belongs to
--  the renderer that created it and dies with it.
--
--  Textures are cached because rebuilding them costs time and evicted
--  because holding them costs memory. Counting entries measures neither: a
--  blurred shadow runs from under two kilobytes to several megabytes, so a
--  fixed entry count permits either a gigabyte or a megabyte of residency.
--
--  Eviction ranks entries by the rebuilding time each byte of them buys.
--  Building costs roughly per pixel, so that ratio is about what a pixel
--  cost to make, which is what separates rasterised vector art from an
--  uploaded bitmap of the same dimensions. The cost is measured by the
--  caller rather than guessed: a fixed guess would not scale with size,
--  and dividing it by size would charge an entry for being large twice.
--
--  Entries lose ground as the cache works rather than as the clock runs.
--  Each eviction raises a floor that later arrivals are measured from, so
--  a once-popular entry falls behind whatever has been used since, without
--  a wall-time constant deciding how fast. A cache under no pressure ages
--  nobody, which is the behaviour worth having: nothing is discarded while
--  there is room for it.
--
--  What a caller keeps is a handle, not a pointer. A cache that evicts
--  cannot also hand out durable pointers -- the next eviction would leave
--  the holder dereferencing freed GPU memory -- so the pointer is reachable
--  only inside a scoped borrow, which pins the entry for as long as it
--  lasts. An evicted entry that is still borrowed is unfindable at once and
--  destroyed when the last borrow ends. A handle to it simply stops being
--  valid, which a caller discovers by looking rather than by crashing.

package Adi.Texture_Cache is

   type Texture_Kind is (Shadow_Texture, Raster_Texture, SVG_Texture);

   --  Identity of whatever produced a texture -- an image, a document --
   --  wide enough that a program need not reuse values, and modular so a
   --  counter handing them out cannot overflow into an exception.
   type Source_Id is mod 2 ** 64;

   --  Bumped when a source's content changes, so entries built from the
   --  old content are simply never found again.
   type Generation_Id is mod 2 ** 32;

   --  Names a texture without naming what produced it, so this package
   --  depends on neither the image nor the shadow machinery. Consumers
   --  give the remaining fields whatever meaning they need:
   --
   --    Shadow  Extent_A = blur, Extent_B = corner radius
   --    Raster  Source identifies the image, Variant the scale mode it
   --            was built for -- scale mode is texture state, so one
   --            texture cannot serve two modes
   --    SVG     as Raster, plus the size it was rasterised at
   type Texture_Key is record
      Kind       : Texture_Kind := Shadow_Texture;
      Source     : Source_Id := 0;
      Generation : Generation_Id := 0;
      Extent_A   : Natural := 0;
      Extent_B   : Natural := 0;
      Variant    : Natural := 0;
   end record;

   --  What an entry occupies, given rather than derived from dimensions:
   --  pitch, format and compression all sit between a texture's size and
   --  its footprint, and none of them are this package's business.
   --
   --  A terabyte, holding the sum of everything resident. Cards today
   --  reach a hundred gigabytes or so, and this is not a claim that one
   --  will reach a terabyte -- only that arithmetic on the total will not
   --  overflow before the hardware makes the question interesting.
   type Byte_Count is range 0 .. 2 ** 40;

   --  What a single texture is charged. A zero charge would let entries
   --  accumulate without ever reaching the budget, so nothing occupies
   --  nothing.
   subtype Texture_Charge is Byte_Count range 1 .. Byte_Count'Last;

   type Cache is limited private;

   ---------------------------------------------------------------------------
   --  Handles
   ---------------------------------------------------------------------------

   --  A slot and the generation that occupied it, plus the cache it came
   --  from: two caches recycling slots independently would otherwise hand
   --  out pairs that each other would accept.
   type Texture_Handle is private;
   Null_Texture : constant Texture_Handle;

   --  True when the handle still names the entry it was issued for. False
   --  once that entry has been evicted, whether or not the slot has since
   --  been reused.
   function Is_Valid (C : Cache; H : Texture_Handle) return Boolean;

   --  What a borrow exposes. Texture_Region can represent a sub-rectangle.
   --  Current consumers require whole-texture regions; an atlas migration
   --  must make each drawing path honour X, Y, Width and Height.
   type Texture_Region is record
      Texture : Adi.SDL.Render.SDL_Texture_Ptr := null;
      X, Y    : Natural := 0;
      Width   : Natural := 0;
      Height  : Natural := 0;
   end record;

   --  Pins the entry for as long as the returned value lives, so an
   --  eviction during the draw defers rather than frees underneath it.
   --  Keep it to the draw; a borrow held across frames holds bytes the
   --  budget cannot reclaim, and the budget cannot be met below them.
   --
   --  Borrowing is what counts as using an entry: a consumer that keeps a
   --  handle and borrows each frame is drawing it every frame, and would
   --  otherwise look untouched since the day it was found. Find only
   --  resolves; it does not count.
   --
   --  A borrow may outlive its cache. The bookkeeping survives until the
   --  last one ends, and the textures do not: a cache goes away because
   --  its renderer is going, so a borrow still open at that point sees a
   --  null texture rather than a freed one.
   type Texture_Ref (Region : access constant Texture_Region) is
     limited new Ada.Finalization.Limited_Controlled with private
     with Implicit_Dereference => Region;

   function Borrow (C : in out Cache; H : Texture_Handle) return Texture_Ref;

   --  A borrow of nothing: an empty region, holding no entry. What Borrow
   --  itself returns for a handle that no longer names anything, and what
   --  a caller with no cache left to borrow from can return in its place
   --  rather than raising.
   function Null_Borrow return Texture_Ref;

   ---------------------------------------------------------------------------
   --  Residency
   ---------------------------------------------------------------------------

   --  A texture larger than the whole budget is kept when it is stored,
   --  rather than rebuilt every frame: evicting it would free room nothing
   --  else can use and repeat the work at once. Bytes_Used can therefore
   --  exceed Budget by that one entry.
   --
   --  Lowering the budget is strict over everything evictable, including
   --  an entry that was oversized when it arrived. Entries under borrow
   --  cannot be evicted, so residency may stay above the budget until
   --  those borrows end.
   procedure Set_Budget (C : in out Cache; Bytes : Byte_Count);
   function Budget (C : Cache) return Byte_Count;

   --  What recency is measured in. Wraps, and is only ever compared as a
   --  difference, so the wrap costs nothing.
   type Frame_Count is mod 2 ** 32;

   --  Call once per drawn frame. Recency breaks ties between entries of
   --  equal standing, and is counted in frames that were actually drawn: a
   --  serial advancing while nothing renders would penalise entries that
   --  never had the chance to be used. Frames above one covers a stretch
   --  that went undrawn.
   procedure Advance_Frame (C : in out Cache; Frames : Positive := 1);

   --  How far the count has got, so a caller can confirm what it is
   --  advancing and how often.
   function Frames (C : Cache) return Frame_Count;

   --  Resolves a key to a handle without counting as a use. Null_Texture
   --  on a miss.
   function Find (C : Cache; Key : Texture_Key) return Texture_Handle;

   --  Hand a freshly built texture over. On success the cache owns it and
   --  destroys it on eviction, on replacement, or when the cache goes out
   --  of scope, and the returned handle is valid on return so the caller
   --  can borrow and draw at once.
   --
   --  Null_Texture means the cache did not take it and the caller still
   --  owns the texture. That happens only when the charge cannot be
   --  accounted for -- residency plus this entry would exceed what
   --  Byte_Count can represent, which needs pinned entries holding down
   --  most of a terabyte. Room is made before that is known, so a refused
   --  store still evicts whatever it displaced.
   --
   --  Build_Time is what producing it actually took -- the whole path, not
   --  only the upload. Measure it with Adi.Clock. There is no default: an
   --  unmeasured entry cannot be compared with a measured one on any honest
   --  basis, and inventing a figure for it only hides that.
   function Store
     (C          : in out Cache;
      Key        : Texture_Key;
      Texture    : Adi.SDL.Render.SDL_Texture_Ptr;
      Width      : Natural;
      Height     : Natural;
      Bytes      : Texture_Charge;
      Build_Time : Adi.Clock.Time_Span) return Texture_Handle;

   --  Drop everything. Entries under borrow are unfindable at once and
   --  destroyed when their last borrow ends.
   procedure Clear (C : in out Cache);

   --  Includes entries awaiting the end of a borrow: their bytes are not
   --  reclaimable yet, and pretending otherwise would overrun the budget.
   function Bytes_Used (C : Cache) return Byte_Count;

   --  Findable entries only.
   function Count (C : Cache) return Natural;

private

   subtype Frame_Serial is Frame_Count;
   type Slot_Generation is mod 2 ** 64;
   type Slot_Index is new Natural;
   type Cache_Serial is mod 2 ** 64;

   No_Slot : constant Slot_Index := 0;

   type Texture_Handle is record
      Owner : Cache_Serial := 0;
      Slot  : Slot_Index := No_Slot;
      Gen   : Slot_Generation := 0;
   end record;

   Null_Texture : constant Texture_Handle :=
     (Owner => 0, Slot => No_Slot, Gen => 0);

   --  Saturating, so a texture drawn every frame for hours cannot wrap its
   --  own count back to nothing and become the next thing evicted.
   Hit_Ceiling : constant := 2 ** 16;

   --  Longest build worth distinguishing: about eighteen minutes. Nothing
   --  in a frame takes that, and capping it bounds the ranking arithmetic.
   Micros_Ceiling : constant := 2 ** 30;

   --  Fixed-point scale, so that a ratio of microseconds to bytes below
   --  one survives integer division.
   Ratio_Scale : constant := 2 ** 12;

   --  An entry's standing: a floor, plus what its use has earned above
   --  that floor. Comparing absolute standings needs no separate ageing
   --  pass, and the floor only rises when something is actually evicted.
   --
   --  The range is what the ranking needs before dividing: hits at most
   --  2**16, times microseconds at most 2**30, times the scale 2**12,
   --  which is 2**58. The floor accumulates above that, and saturates.
   type Priority is range 0 .. 2 ** 60;

   type Cache_Data;
   type Cache_Data_Access is access Cache_Data;

   --  The cache holds a controlled component rather than being controlled
   --  itself: an operation may dispatch on only one tagged type, and
   --  Borrow has to be primitive for Texture_Ref.
   type Cache_Owner is new Ada.Finalization.Limited_Controlled with record
      Data : Cache_Data_Access := null;
   end record;

   overriding procedure Finalize (O : in out Cache_Owner);

   type Cache is limited record
      Owner : Cache_Owner;
   end record;

   Null_Region : aliased constant Texture_Region := (others => <>);

   type Texture_Ref (Region : access constant Texture_Region) is
     limited new Ada.Finalization.Limited_Controlled with record
      Data : Cache_Data_Access := null;
      Slot : Slot_Index := No_Slot;
   end record;

   overriding procedure Finalize (R : in out Texture_Ref);

end Adi.Texture_Cache;
