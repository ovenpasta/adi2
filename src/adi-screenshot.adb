pragma Ada_2022;

with Interfaces.C.Strings;
with Adi.SDL;         use Adi.SDL;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SDL.Image;   use Adi.SDL.Image;

package body Adi.Screenshot is

   procedure Capture
     (Renderer : SDL_Renderer_Ptr;
      Path     : String)
   is
      Surf : constant SDL_Surface_Ptr :=
        SDL_RenderReadPixels (Renderer, Rect => null);
   begin
      if Surf = null then
         raise Program_Error with "SDL_RenderReadPixels failed";
      end if;

      declare
         C_Path : Interfaces.C.Strings.chars_ptr :=
           Interfaces.C.Strings.New_String (Path);
         Ok     : constant Adi.SDL.C_bool := IMG_SavePNG (Surf, C_Path);
      begin
         Interfaces.C.Strings.Free (C_Path);
         SDL_DestroySurface (Surf);
         SDL_Assert (Ok, "IMG_SavePNG");
      end;
   end Capture;

end Adi.Screenshot;
