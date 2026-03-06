package body Adi.Widget.Button.Options is

   ----------------
   -- Set_Button --
   ----------------

   procedure Set_Button (G : in out Option_Group;
                         O : Option_Type;
                         B : Button_Widget_Access) is
   begin
      G.Buttons (O) := B;

      --  Configure the button for group use
      Set_Toggleable (B.all, True);
      declare
         G_Acc : constant Group_Handler_Access := G'Unchecked_Access;
      begin
         Set_Group (B.all, G_Acc);
      end;

      --  Set initial toggle state
      if G.Initialized then
         Set_Toggled (B.all, O = G.Selected);
      else
         --  First button added initializes the group
         G.Selected := O;
         G.Initialized := True;
         Set_Toggled (B.all, True);
      end if;
   end Set_Button;

   procedure Set_Button (G : in out Option_Group;
                         O : Option_Type;
                         B : Button_Handle) is
      Ptr : constant Widget_Access := Resolve_Handle (+B);
   begin
      if Ptr = null then
         raise Constraint_Error with "Set_Button: stale or null handle";
      end if;
      Set_Button (G, O, Button_Widget_Access (Ptr));
   end Set_Button;

   ------------------
   -- Get_Selected --
   ------------------

   function Get_Selected (G : Option_Group) return Option_Type is
   begin
      return G.Selected;
   end Get_Selected;

   ------------------
   -- Set_Selected --
   ------------------

   procedure Set_Selected (G : in out Option_Group; O : Option_Type) is
   begin
      if G.Selected = O then
         return;
      end if;

      --  Deselect old
      if G.Buttons (G.Selected) /= null then
         Set_Toggled (G.Buttons (G.Selected).all, False);
      end if;

      --  Select new
      G.Selected := O;
      if G.Buttons (O) /= null then
         Set_Toggled (G.Buttons (O).all, True);
      end if;

      declare
         procedure Call (CB : Option_Changed_Callback) is begin CB (O); end Call;
         procedure Emit is new Option_Changed_Signals.For_Each (Call);
      begin
         Emit (G.Changed);
      end;
   end Set_Selected;

   --------------------
   -- Connect_Changed --
   --------------------

   procedure Connect_Changed (G : in out Option_Group;
                              CB : Option_Changed_Callback) is
   begin
      G.Changed.Connect (CB);
   end Connect_Changed;

   function Connect_Changed (G : in out Option_Group;
                             CB : Option_Changed_Callback)
      return Option_Changed_Signals.Connection_Id is
   begin
      return G.Changed.Connect (CB);
   end Connect_Changed;

   procedure Disconnect_Changed
     (G : in out Option_Group; Id : Option_Changed_Signals.Connection_Id) is
   begin
      G.Changed.Disconnect (Id);
   end Disconnect_Changed;

   -------------------------
   -- On_Button_Clicked --
   -------------------------

   overriding procedure On_Button_Clicked
     (G : in out Option_Group;
      W : Widget_Handle)
   is
      Ptr : constant Widget_Access := Resolve_Handle (W);
   begin
      if Ptr = null then
         return;
      end if;

      --  Find which option this button corresponds to
      for O in Option_Type loop
         if Widget_Access (G.Buttons (O)) = Ptr then
            --  Already selected? No-op (radio behavior)
            if O = G.Selected then
               --  Ensure it stays toggled (user might have un-toggled visually)
               Set_Toggled (G.Buttons (O).all, True);
               return;
            end if;

            --  Deselect old button
            if G.Buttons (G.Selected) /= null then
               Set_Toggled (G.Buttons (G.Selected).all, False);
            end if;

            --  Select new button
            G.Selected := O;
            Set_Toggled (G.Buttons (O).all, True);

            --  Fire user callback
            declare
               procedure Call (CB : Option_Changed_Callback) is
               begin CB (O); end Call;
               procedure Emit is new Option_Changed_Signals.For_Each (Call);
            begin
               Emit (G.Changed);
            end;

            return;
         end if;
      end loop;
   end On_Button_Clicked;

end Adi.Widget.Button.Options;
