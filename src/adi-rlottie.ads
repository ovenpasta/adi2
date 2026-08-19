--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Core;         use Adi.Core;
with Adi.Clock;
with Adi.Image;        use Adi.Image;
with Adi.Playback_Clock;
with Adi.Handle_Store;
with Adi.Texture_Cache;
with Interfaces;
with System;

--  Every operation here runs on the render thread, and none is safe
--  against another running beside it. A handle is resolved and used
--  within one call rather than held, which keeps a destroy from cutting
--  the ground out from under a call in progress -- but only because the
--  destroy cannot be concurrent. Nothing pins a slot.
package Adi.RLottie is

   --  What callers hold. Generational, so every copy of a handle goes
   --  stale together the moment the animation is destroyed, and a slot
   --  reused for a later animation does not revive them.
   type Animation_Handle is private;
   Null_Animation_Handle : constant Animation_Handle;


   --  Loading parses the animation and reads its metadata. Nothing is
   --  rasterised: a Lottie file states a viewport, not the size it will
   --  be drawn at, and rasterising at the former costs the memory of a
   --  frame set that is then scaled away. A thousand-pixel emoji shown
   --  as an icon is the case this exists to avoid.
   --  A file that cannot be read or parsed, or that describes nothing to
   --  draw, is answered with Null_Animation_Handle. Anything else --
   --  exhaustion, or a defect -- propagates, having reclaimed whatever
   --  had been built.
   function Load_From_File (Path : String) return Animation_Handle;

   --  The model is loaded. Says nothing about whether frames exist yet.
   function Is_Valid (H : Animation_Handle) return Boolean;

   --  The extent the file declares, for measuring a widget before
   --  anything has been rasterised.
   procedure Get_Size
     (H      : Animation_Handle;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);

   ---------------------------------------------------------------------------
   --  Preparation
   ---------------------------------------------------------------------------

   --  Draw at exactly this pixel extent -- physical pixels, not logical
   --  units, since pixels are what a frame is made of. Idempotent:
   --  asking again for the extent in use does nothing at all.
   --
   --  Accepting the first extent rasterises nothing. Frames are
   --  rasterised as playback reaches them and kept afterwards, so a
   --  looping animation pays for each frame once and a frame never
   --  reached costs nothing.
   --
   --  Asking for a different extent replaces the frames once the asking
   --  has stood still for a moment. That replacement does rasterise: the
   --  current frame is drawn at the new extent before the replacement is
   --  installed, so preparation never blanks a running animation. A call
   --  that finds a settled request outstanding therefore takes it up,
   --  and costs that one frame. If it fails, what was drawable stays
   --  drawable and the extent is asked for again after the interval.
   procedure Prepare
     (H            : Animation_Handle;
      Pixel_Width  : Positive;
      Pixel_Height : Positive);

   --  The current frame exists and can be drawn. An extent that has been
   --  accepted but whose frames nothing has asked for yet is not this:
   --  a set holds no frames until playback reaches them.
   function Is_Prepared (H : Animation_Handle) return Boolean;

   --  The extent frames are being rasterised at, zero on both counts
   --  before one has been accepted. Reports the new extent from the
   --  moment it is accepted, which is before every frame of it exists.
   procedure Prepared_Extent
     (H      : Animation_Handle;
      Width  : out Natural;
      Height : out Natural);

   --  What preparing at an extent would cost, so a caller can decide
   --  before committing to it.
   --
   --  Both are worst cases, reached only once every frame has been
   --  played at that extent: one ARGB surface per frame, and what
   --  uploading all of them would add. Neither is a claim about
   --  residency -- frames not yet reached cost nothing, and textures
   --  live in the renderer's cache, which decides what to keep.
   function Estimated_Surface_Bytes
     (H            : Animation_Handle;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer;

   function Estimated_Max_Texture_Bytes
     (H            : Animation_Handle;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer;

   function Get_Frame_Count (H : Animation_Handle) return Natural;
   function Get_Frame_Rate (H : Animation_Handle) return Float;
   function Get_Duration (H : Animation_Handle) return Duration;

   function Get_Current_Frame_Index (H : Animation_Handle) return Natural;

   --  A view of the frame to draw now, naming nothing when there is
   --  none. The animation owns its frames: replacing an extent ends the
   --  frames of the old one, and Destroy ends them all. A copy kept
   --  across either goes stale with them and draws nothing.
   function Get_Current_Image (H : Animation_Handle) return Image_Handle;

   procedure Start (H : Animation_Handle);
   procedure Stop (H : Animation_Handle);
   function Is_Playing (H : Animation_Handle) return Boolean;
   procedure Set_Looping (H : Animation_Handle; Value : Boolean := True);
   function Is_Looping (H : Animation_Handle) return Boolean;
   procedure Set_Playback_Speed
     (H          : Animation_Handle;
      Multiplier : Float := 1.0);
   function Get_Playback_Speed (H : Animation_Handle) return Float;
   procedure Reset (H : Animation_Handle);

   --  Advance by an elapsed span. Deterministic, and the way to drive an
   --  animation from a fixed step rather than from the clock.
   --
   --  Returns True when a new frame becomes visible.
   function Advance (H : Animation_Handle; DT : Duration) return Boolean;

   --  Advance to a point in time rather than by a duration. Several
   --  viewers may draw one animation -- two widgets, two windows -- and
   --  each of them ticking would otherwise advance the single playhead
   --  once per viewer, running the animation at a multiple of its speed.
   --  Sampling an instant instead means every viewer contributes only the
   --  time that actually passed.
   --
   --  Returns True when a new frame becomes visible, which is true for at
   --  most one viewer per step. A viewer therefore cannot use this to
   --  decide whether to redraw: it has to compare the frame it last drew
   --  against the current one, since the viewer that advanced the
   --  animation is rarely the only one showing it.
   --
   --  The first call anchors without adding elapsed time, as do Reset and
   --  any return from paused: an animation must not leap forward by the
   --  time it spent stopped. Anchoring can still make a frame visible --
   --  a freshly prepared animation shows its first at time zero rather
   --  than staying blank until a second sample arrives -- so it returns
   --  True in that case and False when a frame was already showing.
   function Advance_At
     (H      : Animation_Handle;
      Sample : Adi.Clock.Time) return Boolean;

   --  Destroy the animation and reclaim it. Every copy of the handle
   --  goes stale together, and a slot reused later does not revive them.
   --  Sets H to null; a null or stale handle is no work at all.
   --
   --  The frames go with it, so a render item still naming one is left
   --  with a stale handle and draws nothing. Widgets and backends need
   --  not be detached first.
   --
   --  Call it on the render thread. It releases the texture group of
   --  the extent in use, which reaches into the cache of each renderer
   --  that drew those frames, and those caches belong to that thread.
   procedure Destroy (H : in out Animation_Handle);

private

   type RLottie_Animation;

   --  Set by Adi.RLottie.Testing to fail one load after the model is
   --  owned, which is the only way to reach the cleanup path.
   Fail_After_Model : Boolean := False;

   --  Owners: the frames belong to the extent they were rasterised for,
   --  and go when it is replaced. Viewers get handles.
   type Image_Array is array (Positive range <>) of Image_Owner;
   type Image_Array_Access is access Image_Array;

   type Frame_Set;
   type Frame_Set_Access is access Frame_Set;

   --  One extent's frames, rasterised as playback reaches them and kept
   --  afterwards. Images starts all null; a null slot is a frame nothing
   --  has asked for yet.
   type Frame_Set is limited record
      Images       : Image_Array_Access := null;
      Width        : Natural := 0;
      Height       : Natural := 0;
      Frame_Count  : Natural := 0;

      --  Every texture made from these frames, so replacing this extent
      --  takes them out of every renderer that held them rather than
      --  leaving them to be evicted under pressure later.
      Group        : aliased Adi.Texture_Cache.Texture_Group;

   end record;

   --  Settles the requested extent, and replaces the drawable set once it
   --  has stood still. Preparation is not playback: this runs from the
   --  tick whether or not the playhead is moving.
   procedure Service_Pending (Anim : in out RLottie_Animation);

   --  Limited: an animation owns a model handle and the frame sets its
   --  textures belong to. None of that is meaningfully copyable. Callers
   --  work through handles; this is for the body and the children.
   type RLottie_Animation is tagged limited record
      Handle            : aliased System.Address := System.Null_Address;

      --  The extent most recently asked for, and when it was last asked
      --  for. A resize passes through every intermediate extent, so the
      --  replacement happens only once the asking has stopped.
      Pending_W         : Natural := 0;
      Pending_H         : Natural := 0;
      Pending_Since     : Adi.Clock.Time := Adi.Clock.Zero;
      Pending_Live      : Boolean := False;
      Width             : Pixel_Type := 0.0;
      Height            : Pixel_Type := 0.0;
      Frame_Count       : Natural := 0;
      Frame_Rate        : Float := 0.0;
      Duration_S        : Float := 0.0;
      Current_Frame     : Natural := 0;
      Elapsed_S         : Float := 0.0;
      Playing           : Boolean := True;

      --  Where the sampled clock stands. Re-anchored whenever the
      --  timeline moves by any means other than sampling, so the next
      --  sample anchors instead of charging for the gap.
      Clock             : Adi.Playback_Clock.Clock_State;
      Looping           : Boolean := True;
      Playback_Speed    : Float := 1.0;

      --  What is drawable now.
      Active            : Frame_Set_Access := null;

      --  How many frames have been rasterised. Nothing in the library
      --  reads it; it is what lets a test tell one rasterisation from
      --  none, which looking at the frames cannot.
      Rasterisations    : Natural := 0;

      --  One-shot failure injection, per animation. Allocation failure
      --  cannot be provoked honestly by exhausting memory.
      Fail_Next_Raster  : Boolean := False;
   end record;

   --  The object-level operations. Callers use the handle versions; these
   --  are what those resolve to, and what Adi.RLottie.Testing reaches for.
   function Is_Valid (Anim : RLottie_Animation) return Boolean;
   procedure Get_Size
     (Anim   : RLottie_Animation;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);
   procedure Prepare
     (Anim         : in out RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive);
   function Is_Prepared (Anim : RLottie_Animation) return Boolean;
   procedure Prepared_Extent
     (Anim   : RLottie_Animation;
      Width  : out Natural;
      Height : out Natural);
   function Estimated_Surface_Bytes
     (Anim         : RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer;
   function Estimated_Max_Texture_Bytes
     (Anim         : RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer;
   function Get_Frame_Count (Anim : RLottie_Animation) return Natural;
   function Get_Frame_Rate (Anim : RLottie_Animation) return Float;
   function Get_Duration (Anim : RLottie_Animation) return Duration;
   function Get_Current_Frame_Index (Anim : RLottie_Animation) return Natural;
   function Get_Current_Image (Anim : RLottie_Animation) return Image_Handle;
   procedure Start (Anim : in out RLottie_Animation);
   procedure Stop (Anim : in out RLottie_Animation);
   function Is_Playing (Anim : RLottie_Animation) return Boolean;
   procedure Set_Looping
     (Anim : in out RLottie_Animation; Value : Boolean := True);
   function Is_Looping (Anim : RLottie_Animation) return Boolean;
   procedure Set_Playback_Speed
     (Anim       : in out RLottie_Animation;
      Multiplier : Float := 1.0);
   function Get_Playback_Speed (Anim : RLottie_Animation) return Float;
   procedure Reset (Anim : in out RLottie_Animation);
   function Advance
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Boolean;
   function Advance_At
     (Anim   : in out RLottie_Animation;
      Sample : Adi.Clock.Time) return Boolean;
   procedure Destroy (Anim : in out RLottie_Animation);

   type RLottie_Animation_Access is access all RLottie_Animation'Class;

   package Animation_Stores is new Adi.Handle_Store
     (Object_Type   => RLottie_Animation,
      Object_Access => RLottie_Animation_Access);

   type Animation_Handle is record
      Id : Animation_Stores.Object_Id := Animation_Stores.Null_Id;
   end record;
   Null_Animation_Handle : constant Animation_Handle :=
     (Id => Animation_Stores.Null_Id);

end Adi.RLottie;
