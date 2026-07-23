pragma Ada_2022;

with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Text_IO;  use Ada.Text_IO;
with Adi.SDL;      use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Window;   use Adi.Window;

procedure Close_Request_Test is
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   function Resolve (H : Window_Handle) return Window_Access is
   begin
      return Resolve_Window_Handle (H);
   end Resolve;

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
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init(video|events) should succeed");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ttf_Ok);
         Assert (Ready, "TTF_Init should succeed");
      end if;
   end Ensure_SDL_Initialized;

   ---------------------------------------------------------------------------
   --  Callback handlers
   ---------------------------------------------------------------------------

   procedure Allow_Close
     (Win   : Window_Handle;
      Allow : in out Boolean)
   is
      pragma Unreferenced (Win);
   begin
      --  Leave Allow as True (default)
      Allow := True;
   end Allow_Close;

   procedure Veto_Close
     (Win   : Window_Handle;
      Allow : in out Boolean)
   is
      pragma Unreferenced (Win);
   begin
      Allow := False;
   end Veto_Close;

   ---------------------------------------------------------------------------
   --  Tests
   ---------------------------------------------------------------------------

   procedure Test_Default_Allow is
      W     : Window_Handle;
      Ready : Boolean := False;
   begin
      Put_Line ("Test: Handle_Close_Request returns True with no subscribers");
      Ensure_SDL_Initialized (Ready);
      if not Ready then return; end if;

      W := Create_Window_Handle ("Close Request Test", (320.0, 240.0));
      declare
         Ptr : constant Window_Access := Resolve (W);
      begin
         Assert (Ptr /= null and then Ptr.Handle_Close_Request,
                 "default (no subscribers) returns True");
      end;
   end Test_Default_Allow;

   procedure Test_Single_Veto is
      W     : Window_Handle;
      Ready : Boolean := False;
   begin
      Put_Line ("Test: single veto subscriber prevents close");
      Ensure_SDL_Initialized (Ready);
      if not Ready then return; end if;

      W := Create_Window_Handle ("Close Request Test", (320.0, 240.0));
      Connect_Close_Request (W, Veto_Close'Unrestricted_Access);
      declare
         Ptr : constant Window_Access := Resolve (W);
      begin
         Assert (Ptr /= null and then not Ptr.Handle_Close_Request,
                 "veto subscriber returns False");
      end;
   end Test_Single_Veto;

   procedure Test_Multiple_Subscribers_One_Veto is
      W     : Window_Handle;
      Ready : Boolean := False;
   begin
      Put_Line ("Test: one veto among multiple subscribers prevents close");
      Ensure_SDL_Initialized (Ready);
      if not Ready then return; end if;

      W := Create_Window_Handle ("Close Request Test", (320.0, 240.0));
      Connect_Close_Request (W, Allow_Close'Unrestricted_Access);
      Connect_Close_Request (W, Veto_Close'Unrestricted_Access);
      declare
         Ptr : constant Window_Access := Resolve (W);
      begin
         Assert (Ptr /= null and then not Ptr.Handle_Close_Request,
                 "any veto wins, returns False");
      end;
   end Test_Multiple_Subscribers_One_Veto;

   procedure Test_All_Allow is
      W     : Window_Handle;
      Ready : Boolean := False;
   begin
      Put_Line ("Test: all subscribers allow close");
      Ensure_SDL_Initialized (Ready);
      if not Ready then return; end if;

      W := Create_Window_Handle ("Close Request Test", (320.0, 240.0));
      Connect_Close_Request (W, Allow_Close'Unrestricted_Access);
      Connect_Close_Request (W, Allow_Close'Unrestricted_Access);
      declare
         Ptr : constant Window_Access := Resolve (W);
      begin
         Assert (Ptr /= null and then Ptr.Handle_Close_Request,
                 "all allow, returns True");
      end;
   end Test_All_Allow;

   procedure Test_Disconnect_Restores_Default is
      W     : Window_Handle;
      Id    : Close_Request_Signals.Connection_Id;
      Ready : Boolean := False;
   begin
      Put_Line ("Test: disconnect veto subscriber restores default allow");
      Ensure_SDL_Initialized (Ready);
      if not Ready then return; end if;

      W := Create_Window_Handle ("Close Request Test", (320.0, 240.0));
      declare
         Ptr : constant Window_Access := Resolve (W);
      begin
         if Ptr = null then
            Assert (False, "window handle should resolve");
            return;
         end if;
         Id := Ptr.Connect_Close_Request (Veto_Close'Unrestricted_Access);

         Assert (not Ptr.Handle_Close_Request,
                 "veto connected, returns False");

         Ptr.Disconnect_Close_Request (Id);

         Assert (Ptr.Handle_Close_Request,
                 "veto disconnected, returns True");
      end;
   end Test_Disconnect_Restores_Default;

begin
   Put_Line ("=== Close Request Test ===");

   Test_Default_Allow;
   Test_Single_Veto;
   Test_Multiple_Subscribers_One_Veto;
   Test_All_Allow;
   Test_Disconnect_Restores_Default;

   Put_Line ("=== Results:" & Pass_Count'Image & " passed," &
             Fail_Count'Image & " failed ===");
   if Fail_Count > 0 then
      Put_Line ("CLOSE REQUEST TEST FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Close_Request_Test;
