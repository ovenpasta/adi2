--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Core;         use Adi.Core;
with Adi.Clock;
with Adi.Image;        use Adi.Image;
with Adi.Texture_Cache;
with Interfaces;
with System;

package Adi.RLottie is

   --  Limited: an animation owns a model handle and the frame sets its
   --  textures belong to. None of that is meaningfully copyable, and
   --  saying so lets the compiler point at any attempt rather than
   --  leaving two owners of one model.
   type RLottie_Animation is tagged limited private;
   type RLottie_Animation_Access is access all RLottie_Animation'Class;

   --  Loading parses the animation and reads its metadata. Nothing is
   --  rasterised: a Lottie file states a viewport, not the size it will
   --  be drawn at, and rasterising at the former costs the memory of a
   --  frame set that is then scaled away. A thousand-pixel emoji shown
   --  as an icon is the case this exists to avoid.
   function Load_From_File
     (Path : String) return RLottie_Animation_Access;

   --  The model is loaded. Says nothing about whether frames exist yet.
   function Is_Valid (Anim : RLottie_Animation) return Boolean;

   --  The extent the file declares, for measuring a widget before
   --  anything has been rasterised.
   procedure Get_Size
     (Anim   : RLottie_Animation;
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
     (Anim         : in out RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive);

   --  The current frame exists and can be drawn. An extent that has been
   --  accepted but whose frames nothing has asked for yet is not this:
   --  a set holds no frames until playback reaches them.
   function Is_Prepared (Anim : RLottie_Animation) return Boolean;

   --  The extent frames are being rasterised at, zero on both counts
   --  before one has been accepted. Reports the new extent from the
   --  moment it is accepted, which is before every frame of it exists.
   procedure Prepared_Extent
     (Anim   : RLottie_Animation;
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
   function Get_Current_Image (Anim : RLottie_Animation) return Image_Access;

   procedure Start (Anim : in out RLottie_Animation);
   procedure Stop (Anim : in out RLottie_Animation);
   function Is_Playing (Anim : RLottie_Animation) return Boolean;
   procedure Set_Looping (Anim : in out RLottie_Animation; Value : Boolean := True);
   function Is_Looping (Anim : RLottie_Animation) return Boolean;
   procedure Set_Playback_Speed
     (Anim       : in out RLottie_Animation;
      Multiplier : Float := 1.0);
   function Get_Playback_Speed (Anim : RLottie_Animation) return Float;
   procedure Reset (Anim : in out RLottie_Animation);

   --  Advance by an elapsed span. Deterministic, and the way to drive an
   --  animation from a fixed step rather than from the clock.
   --
   --  Returns True when a new frame becomes visible.
   function Advance
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Boolean;

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
     (Anim   : in out RLottie_Animation;
      Sample : Adi.Clock.Time) return Boolean;

   --  Detach or destroy every widget and backend referring to this
   --  animation first. What they hold is a plain Image_Access into a
   --  frame set, which this frees; there is no invalidation to catch a
   --  widget that still draws afterwards. Replacing an extent does not
   --  free those records -- only this does.
   --
   --  Call it on the render thread. It releases the texture group of
   --  every extent the animation has held, which reaches into the cache
   --  of each renderer that drew those frames, and those caches belong
   --  to that thread.
   procedure Destroy (Anim : in out RLottie_Animation);

private

   type Image_Array is array (Positive range <>) of Image_Access;
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

      --  Retired sets are chained rather than freed. A widget in another
      --  window holds a plain Image_Access into whatever it last drew,
      --  and a resize completed by one viewer must not turn that into a
      --  dangling pointer before the other has rebuilt.
      Next_Retired : Frame_Set_Access := null;
   end record;

   --  Settles the requested extent, and replaces the drawable set once it
   --  has stood still. Preparation is not playback: this runs from the
   --  tick whether or not the playhead is moving.
   procedure Service_Pending (Anim : in out RLottie_Animation);

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

      --  Where the sampled clock last stood, and whether it stands
      --  anywhere yet. Cleared whenever the timeline moves by any means
      --  other than sampling, so the next sample anchors instead of
      --  charging the animation for the gap.
      Last_Sample       : Adi.Clock.Time := Adi.Clock.Zero;
      Anchored          : Boolean := False;
      Looping           : Boolean := True;
      Playback_Speed    : Float := 1.0;

      --  What is drawable now.
      Active            : Frame_Set_Access := null;

      --  Replaced sets, kept as image shells with their pixels and
      --  textures already gone, until Destroy. Bounded by the number of
      --  settled extent changes, not by time.
      Retired           : Frame_Set_Access := null;
      Retired_Count     : Natural := 0;

      --  How many frames have been rasterised. Nothing in the library
      --  reads it; it is what lets a test tell one rasterisation from
      --  none, which looking at the frames cannot.
      Rasterisations    : Natural := 0;

      --  One-shot failure injection, per animation. Allocation failure
      --  cannot be provoked honestly by exhausting memory.
      Fail_Next_Raster  : Boolean := False;
   end record;

end Adi.RLottie;
