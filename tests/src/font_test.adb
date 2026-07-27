with Ada.Text_IO;          use Ada.Text_IO;
with Adi.SDL;
with Adi.SDL.TTF;
with Adi.Build_Target;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Font;
with Test_Support;

procedure Font_Test is
   Sdl_OK   : Adi.SDL.C_bool;
   Ttf_OK   : Adi.SDL.C_bool;

   procedure Check (Name : String; H : Font_Handle; Expect_Found : Boolean) is
   begin
      Test_Support.Assert
        ((H /= Null_Font) = Expect_Found,
         "Find (" & Name & ") -> handle"
         & Font_Handle'Image (H)
         & (if Expect_Found then " (expected non-zero)"
                            else " (expected zero)"));
   end Check;

begin
   Sdl_OK := Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO);
   if not Boolean (Sdl_OK) then
      Put_Line ("SDL_Init failed"); return;
   end if;
   Ttf_OK := Adi.SDL.TTF.TTF_Init;
   if not Boolean (Ttf_OK) then
      Put_Line ("TTF_Init failed"); return;
   end if;

   Adi.Font.Enable_System_Font_Search;

   case Adi.Build_Target.Platform is
      when Adi.Build_Target.macOS =>
         Put_Line ("Test: macOS system fonts");
         Check ("Helvetica", Adi.Font.Find ("Helvetica"),      True);
         Check ("Menlo",     Adi.Font.Find ("Menlo"),          True);
         Check ("Arial",     Adi.Font.Find ("Arial"),          True);
      when Adi.Build_Target.Linux =>
         Put_Line ("Test: Linux system fonts");
         --  DejaVu / Noto are standard on Debian/Fedora/Arch; if neither is
         --  installed (minimal CI image) skip rather than fail.
         declare
            DJ : constant Font_Handle := Adi.Font.Find ("DejaVu Sans");
            NS : constant Font_Handle := Adi.Font.Find ("Noto Sans");
         begin
            if DJ = Null_Font and NS = Null_Font then
               Put_Line ("  [SKIP] no DejaVu Sans or Noto Sans installed");
            else
               Check ("DejaVu Sans or Noto Sans",
                      (if DJ /= Null_Font then DJ else NS), True);
            end if;
         end;
      when Adi.Build_Target.Windows =>
         Put_Line ("Test: Windows system fonts");
         Check ("Segoe UI",  Adi.Font.Find ("Segoe UI"),       True);
         Check ("Arial",     Adi.Font.Find ("Arial"),          True);
   end case;

   Put_Line ("Test: missing font");
   Check ("ThisDoesNotExist",
          Adi.Font.Find ("ThisDoesNotExist"), False);

   Test_Support.Finish;
end Font_Test;
