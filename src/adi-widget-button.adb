package body Adi.Widget.Button is
   use type Adi.SDL.Events.SDL_Scancode;

   ------------
   -- Create --
   ------------

   function Create (Text : String := "") return Button_Widget_Access is
      Result : constant Button_Widget_Access := new Button_Widget;
   begin
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);
      Set_Flag (Result.all, Visible, True);
      if Text /= "" then
         Set_Text (Result.all, Text);
      end if;

      return Result;
   end Create;

   ---------------------
   -- Connect_Clicked --
   ---------------------

   procedure Connect_Clicked
     (W : in out Button_Widget; CB : Click_Callback) is
   begin
      W.Clicked.Connect (CB);
   end Connect_Clicked;

   function Connect_Clicked
     (W : in out Button_Widget; CB : Click_Callback)
      return Click_Signals.Connection_Id is
   begin
      return W.Clicked.Connect (CB);
   end Connect_Clicked;

   procedure Disconnect_Clicked
     (W : in out Button_Widget; Id : Click_Signals.Connection_Id) is
   begin
      W.Clicked.Disconnect (Id);
   end Disconnect_Clicked;

   ---------------------
   -- Connect_Toggled --
   ---------------------

   procedure Connect_Toggled
     (W : in out Button_Widget; CB : Toggle_Callback) is
   begin
      W.Toggled.Connect (CB);
   end Connect_Toggled;

   function Connect_Toggled
     (W : in out Button_Widget; CB : Toggle_Callback)
      return Toggle_Signals.Connection_Id is
   begin
      return W.Toggled.Connect (CB);
   end Connect_Toggled;

   procedure Disconnect_Toggled
     (W : in out Button_Widget; Id : Toggle_Signals.Connection_Id) is
   begin
      W.Toggled.Disconnect (Id);
   end Disconnect_Toggled;

   --------------------
   -- Set_Toggleable --
   --------------------

   procedure Set_Toggleable (W : in out Button_Widget;
                             Value : Boolean := True) is
   begin
      W.Toggleable := Value;
   end Set_Toggleable;

   -------------------
   -- Is_Toggleable --
   -------------------

   function Is_Toggleable (W : Button_Widget) return Boolean is
   begin
      return W.Toggleable;
   end Is_Toggleable;

   ----------------
   -- Is_Toggled --
   ----------------

   function Is_Toggled (W : Button_Widget) return Boolean is
   begin
      return Has_State (W, State_Selected);
   end Is_Toggled;

   -----------------
   -- Set_Toggled --
   -----------------

   procedure Set_Toggled (W : in out Button_Widget; Value : Boolean) is
   begin
      Set_Selected (W, Value);
   end Set_Toggled;

   ---------------
   -- Set_Group --
   ---------------

   procedure Set_Group (W : in out Button_Widget;
                        G : Group_Handler_Access) is
   begin
      W.Group := G;
   end Set_Group;

   --------------
   -- On_Click --
   --------------

   overriding procedure On_Click (W : in out Button_Widget) is
      Self : constant Button_Widget_Access := W'Unchecked_Access;
   begin
      if W.Group /= null then
         --  Delegate toggle coordination to the group
         On_Button_Clicked (W.Group.all, Self);
      elsif W.Toggleable then
         --  Local toggle
         Set_Toggled (W, not Is_Toggled (W));
         declare
            Active : constant Boolean := Is_Toggled (W);
            procedure Call (CB : Toggle_Callback) is
            begin
               CB (Self, Active);
            end Call;
            procedure Emit_Toggled is new Toggle_Signals.For_Each (Call);
         begin
            Emit_Toggled (W.Toggled);
         end;
      end if;

      --  Always fire click signal
      declare
         procedure Call (CB : Click_Callback) is
         begin
            CB (Self);
         end Call;
         procedure Emit_Clicked is new Click_Signals.For_Each (Call);
      begin
         Emit_Clicked (W.Clicked);
      end;
   end On_Click;

   overriding procedure On_Key_Down
     (W        : in out Button_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean) is
      pragma Unreferenced (Key_Mod);
   begin
      if Repeat then
         return;
      end if;

      if Scancode = Adi.SDL.Events.SDL_SCANCODE_RETURN
        or else Scancode = Adi.SDL.Events.SDL_SCANCODE_SPACE
      then
         Set_Pressed (W, True);
      end if;
   end On_Key_Down;

   overriding procedure On_Key_Up
     (W        : in out Button_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean) is
      pragma Unreferenced (Key_Mod, Repeat);
   begin
      if Scancode = Adi.SDL.Events.SDL_SCANCODE_RETURN
        or else Scancode = Adi.SDL.Events.SDL_SCANCODE_SPACE
      then
         if Has_State (W, State_Pressed) then
            Set_Pressed (W, False);
            On_Click (W);
         end if;
      end if;
   end On_Key_Up;

end Adi.Widget.Button;
