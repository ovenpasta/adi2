--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Vectors;
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
--  How often an entry is used counts as well as what it cost, and that
--  is what earns the policy its keep. An animation draws its frames in a
--  cycle; when the cycle is longer than the cache, ranking by recency
--  alone evicts precisely the frame wanted next, and every frame is
--  rebuilt every loop. Weighting by use retains a stable subset instead.
--  Measured against plain recency on mixed shadow, raster and vector
--  workloads, no regression was observed. That is the extent of the
--  claim: those workloads, that harness, which is not kept.
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

   --  Bumped when a source's content changes, so entries built from
   --  the old content are simply never found again.
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
   --  Groups
   ---------------------------------------------------------------------------

   --  Textures that live and die together. An animation's frames are a
   --  hundred unrelated images as far as this cache can tell: nothing in
   --  a key says they came from one source or that they stop being wanted
   --  at the same moment. A group says it.
   --
   --  The token belongs to whatever the textures belong to -- an
   --  animation, not a widget drawing one. Two widgets sharing an
   --  animation share its residency, and destroying either leaves the
   --  other's frames alone.
   --
   --  A group spans caches. One animation drawn in two windows has
   --  frames in two renderers' caches, and releasing it must reach both;
   --  a group therefore remembers the caches it has stored into rather
   --  than being owned by one. A cache whose renderer has already gone
   --  reports as much, and releasing there does nothing.
   type Texture_Group is tagged limited private;

   --  A group starts open. Storing into it after release is refused
   --  rather than silently reopening it: the release said those textures
   --  are finished with, and a late arrival would outlive the decision.
   --
   --  Groups and caches alike belong to the thread that renders. Nothing
   --  here is synchronised, and none of it needs to be: a texture is made
   --  and drawn on that thread, so its lifetime is decided there too. A
   --  producer working elsewhere hands its result over on the render
   --  thread, as Adi.RLottie does with its rasterised frames.
   --  For whoever keeps a group rather than merely passing one: an image
   --  holds it for the lifetime of its textures, which an anonymous
   --  access parameter cannot outlive. Storing takes an anonymous one,
   --  since the cache reads the group and does not retain it.
   type Texture_Group_Access is access all Texture_Group'Class;

   procedure Release (G : in out Texture_Group);
   function Is_Open (G : Texture_Group) return Boolean;

   ---------------------------------------------------------------------------
   --  Residency
   ---------------------------------------------------------------------------

   --  The budget limits idle residency -- textures the cache is holding
   --  in case they are wanted again -- and not the scene. A texture being
   --  drawn is not something to reclaim: taking it would rebuild it on the
   --  next frame that drew it, having freed nothing for longer than a
   --  frame. Bytes_Used therefore exceeds Budget by whatever the scene is
   --  using, and by anything awaiting the end of a borrow.
   --
   --  Lowering it trims idle entries at once, and only those. Residency
   --  falls to the new figure as entries leave the scene, not before.
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
   --  owns the texture. Two things cause it. The charge may not be
   --  accountable -- residency plus this entry would exceed what
   --  Byte_Count can represent, and nothing idle remains to drop, entries
   --  in use being unavailable for it. Or the group given may already
   --  have been released, in which case the texture is refused rather
   --  than admitted to outlive its siblings.
   --
   --  Storing never evicts to fit the budget: what arrives is about to be
   --  drawn, and the budget governs what is idle.
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
      Build_Time : Adi.Clock.Time_Span;
      Group      : access Texture_Group'Class := null)
      return Texture_Handle;

   --  Drop everything. Entries under borrow are unfindable at once and
   --  destroyed when their last borrow ends.
   procedure Clear (C : in out Cache);

   --  Includes entries awaiting the end of a borrow: their bytes are not
   --  reclaimable yet, and pretending otherwise would overrun the budget.
   function Bytes_Used (C : Cache) return Byte_Count;

   --  Findable entries only.
   function Count (C : Cache) return Natural;

   ---------------------------------------------------------------------------
   --  Diagnostics
   ---------------------------------------------------------------------------

   --  Per kind, because choosing a budget means knowing which producer
   --  fills it. A total says the cache is full; it does not say whether
   --  shadows or rasterised artwork put it there, and those answer to
   --  different fixes.
   --
   --  Peak_Bytes is total residency at its highest, so it describes the
   --  working set the program needs rather than the budget it wants. What
   --  sizes the budget is idle residency together with pressure: idle
   --  bytes are what a budget retains, and pressure evictions are what a
   --  budget too small produces.
   --
   --  Evictions are separated by cause. Only Pressure means the budget
   --  was too small; a replacement is a source changing under a stable
   --  key, and clearing and teardown are the program's own doing. Counting
   --  them together would make any budget look thrashed at shutdown.
   --  Events accumulate for as long as the program runs, so a counter
   --  that can raise on overflow would make diagnostics a source of
   --  failure. Modular, and wide enough that the wrap is unreachable: a
   --  million cache events a second would take a quarter of a million
   --  years. One bit short of the full word so that every value converts
   --  to a signed 64-bit integer, which is what serialising it needs.
   type Event_Count is mod 2 ** 63;

   type Kind_Stats is record
      Bytes        : Byte_Count := 0;
      Peak_Bytes   : Byte_Count := 0;
      --  Residency, bounded by what is resident rather than by history.
      Count        : Natural := 0;
      Peak_Count   : Natural := 0;
      --  How that residency divides right now. Active is what the scene
      --  is drawing and the budget does not govern; Idle is what the
      --  cache is holding on speculation and the budget does; Retired is
      --  unfindable already and alive only until a borrow ends.
      --
      --  Active_Bytes + Idle_Bytes + Retired_Bytes = Bytes, and
      --  Active_Count + Idle_Count = Count -- retired entries are outside
      --  Count, which means findable.
      Active_Bytes  : Byte_Count := 0;
      Active_Count  : Natural := 0;
      Idle_Bytes    : Byte_Count := 0;
      Idle_Count    : Natural := 0;
      Retired_Bytes : Byte_Count := 0;
      Retired_Count : Natural := 0;
      --  Lookups that found a live entry, and those that did not. A miss
      --  is what costs a rebuild.
      Hits         : Event_Count := 0;
      Misses       : Event_Count := 0;
      Stores       : Event_Count := 0;
      --  Dropped to make room. Counted against the kind that was evicted,
      --  not the kind whose arrival caused the pressure. This is the
      --  number that says a budget is too small, and the one to read
      --  against Misses: evictions feeding misses feeding stores is
      --  thrashing.
      Pressure     : Event_Count := 0;
      --  Dropped so that residency plus an arriving charge stays inside
      --  what Byte_Count can hold. Arithmetic, not policy: a figure here
      --  says the type is near its ceiling, not that the budget is small.
      Headroom     : Event_Count := 0;
      Replaced     : Event_Count := 0;
      --  Dropped by an explicit Clear, and by the cache going away with
      --  its renderer. Neither says anything about the budget.
      Cleared      : Event_Count := 0;
      Discarded    : Event_Count := 0;
      --  Dropped because the group they belonged to was released. Also
      --  not a budget signal: the program said these were finished with.
      Released     : Event_Count := 0;
      --  Stores the cache would not take: a charge that could not be
      --  accounted for, or a group already released. The former needs
      --  entries in use holding down most of a terabyte and would be a
      --  defect; the latter is ordinary lifecycle. They share a counter,
      --  so a figure here says which only in context -- worth separating
      --  if it ever needs reading without one.
      Refused      : Event_Count := 0;
      --  What building this kind has cost over the cache's life, so a
      --  budget can be weighed against the work it saves.
      Build_Time   : Adi.Clock.Time_Span := Adi.Clock.Zero_Span;
   end record;

   type Kind_Stats_Array is array (Texture_Kind) of Kind_Stats;

   function Statistics (C : Cache) return Kind_Stats_Array;

   --  Residency across all kinds at its highest, which is not the sum of
   --  the per-kind peaks: those need not have happened together.
   function Peak_Bytes_Used (C : Cache) return Byte_Count;

   --  What the budget is actually compared against.
   function Idle_Bytes_Used (C : Cache) return Byte_Count;

private

   --  Groups are told apart by a counter. It is modular, so values do
   --  repeat in principle; at 2**64 they do not in practice, which is
   --  what keeps a stale token from naming a live group. Zero is skipped,
   --  being the value that means no group at all.
   type Group_Id is mod 2 ** 64;
   No_Group : constant Group_Id := 0;

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

   package Owner_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cache_Data_Access);

   type Texture_Group is new Ada.Finalization.Limited_Controlled with record
      Id     : Group_Id := No_Group;
      Open   : Boolean := True;
      --  The caches this group has stored into. Each is held by a
      --  reference so the block survives long enough to be visited, even
      --  if its renderer went first.
      Owners : Owner_Vectors.Vector;
   end record;

   overriding procedure Finalize (G : in out Texture_Group);

   Null_Region : aliased constant Texture_Region := (others => <>);

   type Texture_Ref (Region : access constant Texture_Region) is
     limited new Ada.Finalization.Limited_Controlled with record
      Data : Cache_Data_Access := null;
      Slot : Slot_Index := No_Slot;
   end record;

   overriding procedure Finalize (R : in out Texture_Ref);

end Adi.Texture_Cache;
