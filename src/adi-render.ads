--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.SDL;
with Adi.SDL.Render;
with Adi.SDL.TTF.TextEngine;
with Adi.Clock;
with Adi.Texture_Cache;

package Adi.Render is

   type Render_Context is limited private;
   type Render_Context_Access is access all Render_Context;

   procedure Create
     (Ctx      : in out Render_Context;
      Renderer : Adi.SDL.Render.SDL_Renderer_Ptr);

   procedure Destroy (Ctx : in out Render_Context);

   function Get_Renderer
     (Ctx : Render_Context) return Adi.SDL.Render.SDL_Renderer_Ptr;

   ---------------------------------------------------------------------------
   --  Texture cache
   ---------------------------------------------------------------------------

   --  Textures belong to a renderer, so the cache holding them belongs to
   --  the context that owns one. Destroy releases it before the renderer
   --  goes, and there is deliberately no process-global cache: two windows
   --  have two renderers, and a texture from one cannot be drawn with the
   --  other.
   --
   --  How much the cache retains for reuse. It bounds idle textures, not
   --  what the scene may display: a window drawing more than this holds
   --  it all, and the budget governs only what stops being drawn.
   --
   --  A fixed per-renderer figure, roughly two decoded 4K RGBA images.
   --  It is a policy, not a measurement: the example suite here is far
   --  too small to derive one from, and an application's size is not the
   --  sizing variable anyway -- what it draws now is protected regardless,
   --  and this bounds only what it has stopped drawing. An image-heavy
   --  program raises it through Set_Texture_Budget.
   Default_Texture_Budget : constant Adi.Texture_Cache.Byte_Count :=
     Adi.Texture_Cache.Byte_Count (64 * 1024 * 1024);

   --  The cache itself is not handed out. A reference to it could be kept
   --  past Destroy and used against freed storage, which is the failure
   --  handles exist to prevent; these operations reach it without a caller
   --  ever holding it. A handle taken from one context and offered to
   --  another is refused, as it always was.
   function Find_Texture
     (Ctx : Render_Context;
      Key : Adi.Texture_Cache.Texture_Key)
      return Adi.Texture_Cache.Texture_Handle;

   function Is_Valid_Texture
     (Ctx : Render_Context;
      H   : Adi.Texture_Cache.Texture_Handle) return Boolean;

   function Store_Texture
     (Ctx        : in out Render_Context;
      Key        : Adi.Texture_Cache.Texture_Key;
      Texture    : Adi.SDL.Render.SDL_Texture_Ptr;
      Width      : Natural;
      Height     : Natural;
      Bytes      : Adi.Texture_Cache.Texture_Charge;
      Build_Time : Adi.Clock.Time_Span;
      --  The lifetime this texture shares with others, if any.
      Group      : access Adi.Texture_Cache.Texture_Group'Class := null)
      return Adi.Texture_Cache.Texture_Handle;

   --  Safe to hold across the context's destruction: the borrow keeps the
   --  bookkeeping alive on its own, and reports a null texture once the
   --  renderer that owned it has gone. Borrowing from a context that is
   --  already destroyed yields the same empty borrow rather than raising,
   --  as looking one up there yields no handle.
   function Borrow_Texture
     (Ctx : in out Render_Context;
      H   : Adi.Texture_Cache.Texture_Handle)
      return Adi.Texture_Cache.Texture_Ref;

   procedure Clear_Textures (Ctx : in out Render_Context);

   --  Call once per frame that is actually drawn. Entries are ranked partly
   --  by how long since they were last used, and counting frames nobody
   --  rendered would age them for time the program spent idle.
   procedure Advance_Frame (Ctx : in out Render_Context);

   procedure Set_Texture_Budget
     (Ctx : in out Render_Context; Bytes : Adi.Texture_Cache.Byte_Count);

   type Texture_Stats is record
      Budget     : Adi.Texture_Cache.Byte_Count := 0;
      Bytes_Used : Adi.Texture_Cache.Byte_Count := 0;
      Peak_Bytes : Adi.Texture_Cache.Byte_Count := 0;
      --  What the budget is compared against.
      Idle_Bytes : Adi.Texture_Cache.Byte_Count := 0;
      Count      : Natural := 0;
      Frames     : Adi.Texture_Cache.Frame_Count := 0;
      --  What each producer costs and how often the budget bit for it.
      By_Kind    : Adi.Texture_Cache.Kind_Stats_Array := [others => <>];
   end record;

   function Get_Texture_Stats (Ctx : Render_Context) return Texture_Stats;

   --  Text engine (created lazily on first call)
   function Get_Text_Engine
     (Ctx : in out Render_Context)
      return Adi.SDL.TTF.TextEngine.TTF_TextEngine_Access;

   --  Scroll offset (accumulated from parent scrollable containers)
   function Get_Scroll_Y (Ctx : Render_Context) return Float;
   procedure Set_Scroll_Y (Ctx : in out Render_Context; Value : Float);

private
   type Render_Data;
   type Render_Data_Access is access Render_Data;

   type Render_Context is limited record
      Data     : Render_Data_Access;
      Scroll_Y : Float := 0.0;
   end record;

end Adi.Render;
