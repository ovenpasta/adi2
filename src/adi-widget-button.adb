with Adi.Widget.Part_Styles; use Adi.Widget.Part_Styles;

package body Adi.Widget.Button is

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

      --  Apply default button template styles
      Button_Template.Apply_To (Result.all);

      return Result;
   end Create;

   --------------------
   -- Set_On_Clicked --
   --------------------

   procedure Set_On_Clicked (W : in out Button_Widget; CB : Click_Callback) is
   begin
      W.On_Clicked := CB;
   end Set_On_Clicked;

   --------------------
   -- Set_On_Toggled --
   --------------------

   procedure Set_On_Toggled (W : in out Button_Widget; CB : Toggle_Callback) is
   begin
      W.On_Toggled := CB;
   end Set_On_Toggled;

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
         if W.On_Toggled /= null then
            W.On_Toggled (Self, Is_Toggled (W));
         end if;
      end if;

      --  Always fire click callback
      if W.On_Clicked /= null then
         W.On_Clicked (Self);
      end if;
   end On_Click;

end Adi.Widget.Button;
