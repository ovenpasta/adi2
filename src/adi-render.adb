--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Ordered_Maps;
with Ada.Unchecked_Deallocation;
with Adi.SDL.Render; use Adi.SDL.Render;
with Adi.SDL.TTF.TextEngine; use Adi.SDL.TTF.TextEngine;

package body Adi.Render is

   Max_Shadow_Cache_Size : constant := 256;

   function "<" (L, R : Shadow_Key) return Boolean is
   begin
      if L.Blur_Px /= R.Blur_Px then return L.Blur_Px < R.Blur_Px; end if;
      return L.Corner_Radius < R.Corner_Radius;
   end "<";

   package Shadow_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Shadow_Key, Element_Type => SDL_Texture_Ptr);

   type Render_Data is limited record
      Renderer     : SDL_Renderer_Ptr;
      Shadow_Cache : Shadow_Maps.Map;
      Text_Engine  : TTF_TextEngine_Access := null;
      Textures     : Adi.Texture_Cache.Cache;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation
     (Render_Data, Render_Data_Access);

   ------------
   -- Create --
   ------------

   procedure Create
     (Ctx      : in out Render_Context;
      Renderer : SDL_Renderer_Ptr)
   is
   begin
      Ctx.Data := new Render_Data;
      Ctx.Data.Renderer := Renderer;
      Adi.Texture_Cache.Set_Budget
        (Ctx.Data.Textures, Default_Texture_Budget);
   end Create;

   -------------------
   -- Texture cache --
   -------------------

   function Find_Texture
     (Ctx : Render_Context;
      Key : Adi.Texture_Cache.Texture_Key)
      return Adi.Texture_Cache.Texture_Handle
   is (if Ctx.Data = null then Adi.Texture_Cache.Null_Texture
       else Adi.Texture_Cache.Find (Ctx.Data.Textures, Key));

   function Is_Valid_Texture
     (Ctx : Render_Context;
      H   : Adi.Texture_Cache.Texture_Handle) return Boolean
   is (Ctx.Data /= null
       and then Adi.Texture_Cache.Is_Valid (Ctx.Data.Textures, H));

   function Store_Texture
     (Ctx        : in out Render_Context;
      Key        : Adi.Texture_Cache.Texture_Key;
      Texture    : SDL_Texture_Ptr;
      Width      : Natural;
      Height     : Natural;
      Bytes      : Adi.Texture_Cache.Texture_Charge;
      Build_Time : Adi.Clock.Time_Span)
      return Adi.Texture_Cache.Texture_Handle
   is (if Ctx.Data = null then Adi.Texture_Cache.Null_Texture
       else Adi.Texture_Cache.Store
              (Ctx.Data.Textures, Key, Texture, Width, Height, Bytes,
               Build_Time));

   function Borrow_Texture
     (Ctx : in out Render_Context;
      H   : Adi.Texture_Cache.Texture_Handle)
      return Adi.Texture_Cache.Texture_Ref
   is (if Ctx.Data = null then Adi.Texture_Cache.Null_Borrow
       else Adi.Texture_Cache.Borrow (Ctx.Data.Textures, H));

   procedure Clear_Textures (Ctx : in out Render_Context) is
   begin
      if Ctx.Data /= null then
         Adi.Texture_Cache.Clear (Ctx.Data.Textures);
      end if;
   end Clear_Textures;

   -------------------
   -- Advance_Frame --
   -------------------

   procedure Advance_Frame (Ctx : in out Render_Context) is
   begin
      if Ctx.Data /= null then
         Adi.Texture_Cache.Advance_Frame (Ctx.Data.Textures);
      end if;
   end Advance_Frame;

   procedure Set_Texture_Budget
     (Ctx : in out Render_Context; Bytes : Adi.Texture_Cache.Byte_Count) is
   begin
      if Ctx.Data /= null then
         Adi.Texture_Cache.Set_Budget (Ctx.Data.Textures, Bytes);
      end if;
   end Set_Texture_Budget;

   function Get_Texture_Stats (Ctx : Render_Context) return Texture_Stats is
   begin
      if Ctx.Data = null then
         return (others => <>);
      end if;
      return (Budget     => Adi.Texture_Cache.Budget (Ctx.Data.Textures),
              Bytes_Used => Adi.Texture_Cache.Bytes_Used (Ctx.Data.Textures),
              Count      => Adi.Texture_Cache.Count (Ctx.Data.Textures),
              Frames     => Adi.Texture_Cache.Frames (Ctx.Data.Textures));
   end Get_Texture_Stats;

   -------------
   -- Destroy --
   -------------

   procedure Destroy (Ctx : in out Render_Context) is
      use Shadow_Maps;
   begin
      if Ctx.Data = null then
         return;
      end if;

      --  Destroy all cached shadow textures
      for C in Ctx.Data.Shadow_Cache.Iterate loop
         SDL_DestroyTexture (Element (C));
      end loop;
      Ctx.Data.Shadow_Cache.Clear;

      --  Destroy text engine
      if Ctx.Data.Text_Engine /= null then
         TTF_DestroyRendererTextEngine (Ctx.Data.Text_Engine);
         Ctx.Data.Text_Engine := null;
      end if;

      --  Finalizes the texture cache, which destroys the textures it holds.
      --  The caller must not have destroyed the renderer yet: these textures
      --  belong to it.
      Free (Ctx.Data);
   end Destroy;

   ------------------
   -- Get_Renderer --
   ------------------

   function Get_Renderer
     (Ctx : Render_Context) return SDL_Renderer_Ptr
   is
   begin
      return Ctx.Data.Renderer;
   end Get_Renderer;

   -----------------
   -- Find_Shadow --
   -----------------

   function Find_Shadow
     (Ctx : Render_Context;
      Key : Shadow_Key) return SDL_Texture_Ptr
   is
      use Shadow_Maps;
      Pos : constant Cursor := Ctx.Data.Shadow_Cache.Find (Key);
   begin
      if Pos /= No_Element then
         return Element (Pos);
      end if;
      return null;
   end Find_Shadow;

   ------------------
   -- Store_Shadow --
   ------------------

   procedure Store_Shadow
     (Ctx : in out Render_Context;
      Key : Shadow_Key;
      Tex : SDL_Texture_Ptr)
   is
      use Shadow_Maps;
   begin
      --  Evict oldest if cache is full
      if Natural (Ctx.Data.Shadow_Cache.Length) >= Max_Shadow_Cache_Size then
         declare
            First_Pos : Cursor := Ctx.Data.Shadow_Cache.First;
            Old_Tex   : constant SDL_Texture_Ptr := Element (First_Pos);
         begin
            SDL_DestroyTexture (Old_Tex);
            Ctx.Data.Shadow_Cache.Delete (First_Pos);
         end;
      end if;

      Ctx.Data.Shadow_Cache.Insert (Key, Tex);
   end Store_Shadow;

   ---------------------
   -- Get_Text_Engine --
   ---------------------

   function Get_Text_Engine
     (Ctx : in out Render_Context)
      return TTF_TextEngine_Access
   is
   begin
      if Ctx.Data.Text_Engine = null then
         Ctx.Data.Text_Engine :=
           TTF_CreateRendererTextEngine (Ctx.Data.Renderer);
      end if;
      return Ctx.Data.Text_Engine;
   end Get_Text_Engine;

   function Get_Scroll_Y (Ctx : Render_Context) return Float is
   begin
      return Ctx.Scroll_Y;
   end Get_Scroll_Y;

   procedure Set_Scroll_Y (Ctx : in out Render_Context; Value : Float) is
   begin
      Ctx.Scroll_Y := Value;
   end Set_Scroll_Y;

end Adi.Render;
