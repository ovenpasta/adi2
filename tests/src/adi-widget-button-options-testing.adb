--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Button.Options.Testing is

   type Other_Group is limited new Group_Handler with null record;
   overriding procedure On_Button_Clicked
     (G : in out Other_Group; W : Widget_Handle) is null;

   Elsewhere : aliased Other_Group;

   function Elsewhere_Access return Group_Handler_Access is
      View : constant access Group_Handler'Class :=
        Group_Handler'Class (Elsewhere)'Unchecked_Access;
   begin
      return Group_Handler_Access (View);
   end Elsewhere_Access;

   function Resolve (B : Button_Handle) return Button_Widget_Access
   is (if Widget_Stores.Is_Valid (B.Id)
       then Button_Widget_Access (Widget_Stores.Get (B.Id))
       else null);

   function Recorded
     (G : Option_Group; O : Option_Type) return Button_Handle
   is (G.Impl.Buttons (O));

   procedure Click (G : in out Option_Group; B : Button_Handle) is
   begin
      On_Button_Clicked (G.Impl, To_Widget_Handle (B));
   end Click;

   function Is_Linked (B : Button_Handle) return Boolean is
      Btn : constant Button_Widget_Access := Resolve (B);
   begin
      return Btn /= null and then Group_Of (Btn.all) /= null;
   end Is_Linked;

   procedure Rebind_Elsewhere (B : Button_Handle) is
      Btn : constant Button_Widget_Access := Resolve (B);
   begin
      if Btn /= null then
         Set_Group (Btn.all, Elsewhere_Access);
      end if;
   end Rebind_Elsewhere;

   function Links_Elsewhere (B : Button_Handle) return Boolean is
      Btn : constant Button_Widget_Access := Resolve (B);
   begin
      return Btn /= null and then Group_Of (Btn.all) = Elsewhere_Access;
   end Links_Elsewhere;

end Adi.Widget.Button.Options.Testing;
