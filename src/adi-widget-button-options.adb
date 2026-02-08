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

      if G.On_Changed /= null then
         G.On_Changed (O);
      end if;
   end Set_Selected;

   --------------------
   -- Set_On_Changed --
   --------------------

   procedure Set_On_Changed (G : in out Option_Group;
                             CB : Option_Changed_Callback) is
   begin
      G.On_Changed := CB;
   end Set_On_Changed;

   -------------------------
   -- On_Button_Clicked --
   -------------------------

   overriding procedure On_Button_Clicked
     (G   : in out Option_Group;
      Btn : Button_Widget_Access)
   is
   begin
      --  Find which option this button corresponds to
      for O in Option_Type loop
         if G.Buttons (O) = Btn then
            --  Already selected? No-op (radio behavior)
            if O = G.Selected then
               --  Ensure it stays toggled (user might have un-toggled visually)
               Set_Toggled (Btn.all, True);
               return;
            end if;

            --  Deselect old button
            if G.Buttons (G.Selected) /= null then
               Set_Toggled (G.Buttons (G.Selected).all, False);
            end if;

            --  Select new button
            G.Selected := O;
            Set_Toggled (Btn.all, True);

            --  Fire user callback
            if G.On_Changed /= null then
               G.On_Changed (O);
            end if;

            return;
         end if;
      end loop;
   end On_Button_Clicked;

end Adi.Widget.Button.Options;
