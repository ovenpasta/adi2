with Adi.SDL;
with Adi.SDL.Render;
with Adi.SDL.TTF.TextEngine;

package Adi.Render is

   type Shadow_Key is record
      Blur_Px       : Natural;
      Corner_Radius : Natural;
   end record;

   type Render_Context is limited private;
   type Render_Context_Access is access all Render_Context;

   procedure Create
     (Ctx      : in out Render_Context;
      Renderer : Adi.SDL.Render.SDL_Renderer_Ptr);

   procedure Destroy (Ctx : in out Render_Context);

   function Get_Renderer
     (Ctx : Render_Context) return Adi.SDL.Render.SDL_Renderer_Ptr;

   --  Shadow texture cache
   function Find_Shadow
     (Ctx : Render_Context;
      Key : Shadow_Key) return Adi.SDL.Render.SDL_Texture_Ptr;

   procedure Store_Shadow
     (Ctx : in out Render_Context;
      Key : Shadow_Key;
      Tex : Adi.SDL.Render.SDL_Texture_Ptr);

   --  Text engine (created lazily on first call)
   function Get_Text_Engine
     (Ctx : in out Render_Context)
      return Adi.SDL.TTF.TextEngine.TTF_TextEngine_Access;

private
   type Render_Data;
   type Render_Data_Access is access Render_Data;

   type Render_Context is limited record
      Data : Render_Data_Access;
   end record;

end Adi.Render;
