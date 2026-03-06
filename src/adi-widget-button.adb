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

      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle (Text : String := "") return Button_Handle is
      Result : constant Button_Widget_Access := Create (Text);
   begin
      return (Id => Get_Handle (Result.all).Id);
   end Create_Handle;

   -----------------------
   -- To_Widget_Handle --
   -----------------------

   function To_Widget_Handle (H : Button_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   --------------------
   -- Try_As_Button --
   --------------------

   function Try_As_Button (H : Widget_Handle) return Button_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Button_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Button_Handle;
   end Try_As_Button;

   function Is_Valid (H : Button_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

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

   ---------------------------------------------------------------------------
   --  Typed handle method overloads
   ---------------------------------------------------------------------------

   procedure Connect_Clicked (H : Button_Handle; CB : Click_Callback) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Clicked (Button_Widget (Ptr.all), CB);
      end if;
   end Connect_Clicked;

   function Connect_Clicked (H : Button_Handle; CB : Click_Callback)
     return Click_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Clicked (Button_Widget (Ptr.all), CB);
      end if;
      return Click_Signals.No_Connection;
   end Connect_Clicked;

   procedure Set_Toggleable (H : Button_Handle; Value : Boolean := True) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Toggleable (Button_Widget (Ptr.all), Value);
      end if;
   end Set_Toggleable;

   procedure Set_Toggled (H : Button_Handle; Value : Boolean) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Toggled (Button_Widget (Ptr.all), Value);
      end if;
   end Set_Toggled;

   procedure Disconnect_Clicked
     (H : Button_Handle; Id : Click_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Clicked (Button_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Clicked;

   procedure Connect_Toggled (H : Button_Handle; CB : Toggle_Callback) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Toggled (Button_Widget (Ptr.all), CB);
      end if;
   end Connect_Toggled;

   function Connect_Toggled (H : Button_Handle; CB : Toggle_Callback)
     return Toggle_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Toggled (Button_Widget (Ptr.all), CB);
      end if;
      return Toggle_Signals.No_Connection;
   end Connect_Toggled;

   procedure Disconnect_Toggled
     (H : Button_Handle; Id : Toggle_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Toggled (Button_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Toggled;

   function Is_Toggleable (H : Button_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Toggleable (Button_Widget (Ptr.all));
      end if;
      return False;
   end Is_Toggleable;

   function Is_Toggled (H : Button_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Toggled (Button_Widget (Ptr.all));
      end if;
      return False;
   end Is_Toggled;

   procedure Set_Text (H : Button_Handle; Text : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Label.Set_Text (Label_Widget (Ptr.all), Text);
      end if;
   end Set_Text;

   function Get_Text (H : Button_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Label.Get_Text (Label_Widget (Ptr.all));
      end if;
      return "";
   end Get_Text;

   function "+" (H : Button_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Button_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------
   -- On_Click --
   --------------

   overriding procedure On_Click (W : in out Button_Widget) is
      H : constant Widget_Handle := Get_Handle (W);
   begin
      if W.Group /= null then
         --  Delegate toggle coordination to the group
         On_Button_Clicked (W.Group.all, H);
      elsif W.Toggleable then
         --  Local toggle
         Set_Toggled (W, not Is_Toggled (W));
         declare
            Active : constant Boolean := Is_Toggled (W);
            procedure Call (CB : Toggle_Callback) is
            begin
               CB (H, Active);
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
            CB (H);
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
