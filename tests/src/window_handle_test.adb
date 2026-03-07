pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;  use Ada.Text_IO;
with Adi.SDL;      use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Window;   use Adi.Window;
with Adi.Widget.Box; use Adi.Widget.Box;

procedure Window_Handle_Test is
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;
   SDL_Ready  : Boolean := False;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok     : Adi.SDL.C_bool;
      Ttf_Ok : Adi.SDL.C_bool;
   begin
      if SDL_Ready then
         Ready := True;
         return;
      end if;

      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init(video|events) should succeed");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ttf_Ok);
         Assert (Ready, "TTF_Init should succeed");
      end if;

      SDL_Ready := Ready;
   end Ensure_SDL_Initialized;

   procedure On_Window_Tick (DT : Duration) is
      pragma Unreferenced (DT);
   begin
      null;
   end On_Window_Tick;

   procedure Allow_Close
     (Win   : Window_Handle;
      Allow : in out Boolean)
   is
      pragma Unreferenced (Win);
   begin
      Allow := True;
   end Allow_Close;

   procedure Test_Null_Handle is
   begin
      Put_Line ("Test: Null_Window_Handle is invalid");
      Assert (not Is_Valid (Null_Window_Handle),
              "Null_Window_Handle should be invalid");
      Assert (Resolve_Window_Handle (Null_Window_Handle) = null,
              "Null_Window_Handle resolves to null");
   end Test_Null_Handle;

   procedure Test_Create_Window_Handle is
      Ready : Boolean := False;
      H     : Window_Handle;
   begin
      Put_Line ("Test: Create_Window_Handle returns a valid handle");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Window Handle Test", (320.0, 240.0));
      Assert (Is_Valid (H), "Create_Window_Handle returns valid handle");
      Assert (Resolve_Window_Handle (H) /= null,
              "Resolve_Window_Handle(valid) is non-null");

      Destroy (H);
      Assert (not Is_Valid (H), "Destroy(handle) invalidates handle");
   end Test_Create_Window_Handle;

   procedure Test_Handle_Overloads is
      Ready  : Boolean := False;
      H      : Window_Handle;
      Root_H : Box_Handle;
   begin
      Put_Line ("Test: Window handle overloads");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Window Handle Overloads", (420.0, 260.0));
      Root_H := Create_Handle;

      Set_Root (H, +Root_H);
      Set_Debug_Stats (H, True);
      Set_Enforce_Layout_Min_Size (H, True);
      Assert (Get_Enforce_Layout_Min_Size (H),
              "Get_Enforce_Layout_Min_Size(handle) should be True");

      Connect_Tick (H, On_Window_Tick'Unrestricted_Access);
      Connect_Close_Request (H, Allow_Close'Unrestricted_Access);

      Destroy (H);
      Assert (not Is_Valid (H), "Destroy(handle) after overload usage");
   end Test_Handle_Overloads;

   procedure Test_Destroy_By_Handle is
      Ready : Boolean := False;
      H     : Window_Handle;
   begin
      Put_Line ("Test: Destroy by Window_Handle");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Destroy Handle", (320.0, 240.0));
      Assert (Is_Valid (H), "handle valid before destroy");

      Destroy (H);
      Assert (not Is_Valid (H), "handle invalid after destroy");
      Assert (Resolve_Window_Handle (H) = null,
              "resolve after destroy returns null");
   end Test_Destroy_By_Handle;

   procedure Test_Destroy_Idempotent is
      Ready : Boolean := False;
      H     : Window_Handle;
   begin
      Put_Line ("Test: Destroy is idempotent");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      H := Create_Window_Handle ("Destroy Idempotent", (320.0, 240.0));
      Destroy (H);
      Destroy (H);
      Assert (not Is_Valid (H), "double destroy leaves handle invalid");
   end Test_Destroy_Idempotent;

begin
   Put_Line ("=== Window Handle Test ===");

   Test_Null_Handle;
   Test_Create_Window_Handle;
   Test_Handle_Overloads;
   Test_Destroy_By_Handle;
   Test_Destroy_Idempotent;

   Put_Line ("=== Results:" & Pass_Count'Image & " passed," &
             Fail_Count'Image & " failed ===");
   if Fail_Count > 0 then
      Put_Line ("WINDOW HANDLE TEST FAILED");
   end if;
end Window_Handle_Test;
