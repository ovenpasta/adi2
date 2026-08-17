--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Core;         use Adi.Core;
with Adi.Clock;
with Adi.Image;        use Adi.Image;
with Adi.Texture_Cache;
with Adi.SDL.Surface;  use Adi.SDL.Surface;
with Interfaces;
with System;

package Adi.RLottie is

   --  Limited: an animation owns a model handle, a worker task, frame
   --  sets and the group its textures belong to. None of that is
   --  meaningfully copyable, and saying so lets the compiler point at any
   --  attempt rather than leaving two owners of one worker.
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

   --  Rasterise the frame set at exactly this pixel extent -- physical
   --  pixels, not logical units, since pixels are what a frame is made
   --  of. Idempotent: asking again for the extent already prepared does
   --  nothing at all.
   --
   --  Asking for a different extent begins a new generation. The frames
   --  already prepared stay drawable until the replacement is ready, so
   --  preparation never blanks a running animation, and a generation
   --  superseded before it finishes is discarded rather than installed.
   --
   --  Deciding when to call this is the caller's: rasterising on every
   --  extent a resize passes through would rebuild the set continuously.
   procedure Prepare
     (Anim         : in out RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive);

   --  Frames exist and can be drawn.
   function Is_Prepared (Anim : RLottie_Animation) return Boolean;

   --  What is prepared now, zero on both counts before the first
   --  generation is installed.
   procedure Prepared_Extent
     (Anim   : RLottie_Animation;
      Width  : out Natural;
      Height : out Natural);

   --  What preparing at an extent would cost, so a caller can decide
   --  before committing to it.
   --
   --  The surface figure is what this package will hold: one ARGB frame
   --  per frame of the animation. The texture figure is what uploading
   --  all of them would add, and is an estimate rather than a claim
   --  about residency -- textures live in the renderer's cache, which
   --  decides for itself what to keep.
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
   function Get_Preloaded_Frame_Count (Anim : RLottie_Animation) return Natural;
   function Is_Preload_Complete (Anim : RLottie_Animation) return Boolean;
   procedure Set_Preload_Threshold
     (Anim              : in out RLottie_Animation;
      Min_Ready_Frames  : Natural);

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
   --  animation first. What they hold is a plain Image_Access into its
   --  frame set, which this frees; there is no invalidation to catch a
   --  widget that still draws afterwards.
   --
   --  Call it on the render thread. It releases the animation's texture
   --  group, which reaches into the cache of every renderer that drew the
   --  frames, and those caches belong to that thread.
   procedure Destroy (Anim : in out RLottie_Animation);

private

   type Surface_Array is array (Positive range <>) of SDL_Surface_Ptr;
   type Surface_Array_Access is access Surface_Array;

   type Image_Array is array (Positive range <>) of Image_Access;
   type Image_Array_Access is access Image_Array;

   --  One rasterisation of the animation at one extent. A set is built
   --  privately by a worker and published whole; once published it is
   --  never modified, so drawing from it needs no interlock with a build
   --  going on beside it.
   type Frame_Set is record
      Surfaces    : Surface_Array_Access := null;
      Images      : Image_Array_Access := null;
      Width       : Natural := 0;
      Height      : Natural := 0;
      Frame_Count : Natural := 0;
      Generation  : Natural := 0;
   end record;
   type Frame_Set_Access is access Frame_Set;

   protected type Preload_State is
      procedure Set_Ready_Count (Value : Natural);
      function Ready_Count return Natural;
      procedure Mark_Done;
      function Done return Boolean;
      procedure Signal_Stop;
      function Stop_Requested return Boolean;

      --  Blocks until the worker has finished touching the animation and
      --  its set. Teardown has to establish that before freeing either,
      --  and waiting on an event is how, rather than sleeping in a loop
      --  and hoping the interval was long enough.
      entry Wait_Done;
   private
      Ready      : Natural := 0;
      Completed  : Boolean := False;
      Stop_Flag  : Boolean := False;
   end Preload_State;
   type Preload_State_Access is access all Preload_State;

   type Address_Access is access all System.Address;

   --  The worker allocates the surfaces as well as rendering into them.
   --  Allocating a frame set is itself expensive -- tens of megabytes for
   --  a large extent -- and doing it on the UI path would stall the frame
   --  that asked for a resize.
   task type Preload_Task
     (Animation   : not null Address_Access;
      Set         : not null Frame_Set_Access;
      State       : not null Preload_State_Access);
   type Preload_Task_Access is access Preload_Task;

   --  Advances the preparation state machine: reaps a finished build,
   --  publishes it if still wanted, and starts one when the requested
   --  extent has settled. Called from the frame loop, and from the tests
   --  that drive it without one.
   procedure Service_Pending (Anim : in out RLottie_Animation);

   type RLottie_Animation is tagged limited record
      Handle            : aliased System.Address := System.Null_Address;
      --  Every texture made from this animation's frames belongs to it,
      --  so all of them go when it does rather than lingering as a
      --  hundred unrelated images nothing will ask for again.
      Group             : aliased Adi.Texture_Cache.Texture_Group;
      --  The generation last handed to a worker. A set arriving with an
      --  older number is one nobody wants any more, and is destroyed
      --  rather than published.
      Generation        : Natural := 0;

      --  The extent most recently asked for, and when it was last asked
      --  for. A resize passes through every intermediate extent, so a
      --  build starts only once the asking has stopped.
      Pending_W         : Natural := 0;
      Pending_H         : Natural := 0;
      Pending_Since     : Adi.Clock.Time := Adi.Clock.Zero;
      Pending_Live      : Boolean := False;
      Width             : Pixel_Type := 0.0;
      Height            : Pixel_Type := 0.0;
      Buffer_Width      : Natural := 0;
      Buffer_Height     : Natural := 0;
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
      Min_Ready_Frames  : Natural := 8;
      --  What is drawable now. Immutable once installed.
      Active            : Frame_Set_Access := null;

      --  What a worker is building, with the state it reports through and
      --  the task itself. Never drawn from, and there is never more than
      --  one: a superseded build is told to stop and kept until it ends,
      --  rather than abandoned beside a replacement. A resize therefore
      --  coalesces to its final extent instead of leaving a worker behind
      --  for every size it passed through.
      Building          : Frame_Set_Access := null;
      Build_State       : Preload_State_Access := null;
      Worker            : Preload_Task_Access := null;

      --  Set when the build in flight is for an extent nobody wants any
      --  more. It is reaped rather than published.
      Build_Superseded  : Boolean := False;

      --  How many builds have been started. Nothing in the library reads
      --  it; it is what lets a test tell one build from three, which no
      --  amount of looking at the frames can.
      Build_Count       : Natural := 0;
   end record;

end Adi.RLottie;
