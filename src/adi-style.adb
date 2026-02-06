pragma Ada_2022;

package body Adi.Style is

   function Hash_Property (Key : Property_Kind) return Ada.Containers.Hash_Type
   is
   begin
      return Ada.Containers.Hash_Type (Property_Kind'Pos (Key));
   end Hash_Property;

   ------------------
   -- Has_Property --
   ------------------

   function Has_Property (S : Style; id : Property_Kind) return Boolean is
   begin
      return S.properties.Contains (id);
   end Has_Property;

   ------------------
   -- Get_Property --
   ------------------

   function Get_Property (S : Style; id : Property_Kind) return Property_Value
   is
   begin
      if Has_Property (S, id) then
         return S.properties.Constant_Reference (id);
      else
         return Property_Specs_Array (id).Default_Value.Element;
      end if;
   end Get_Property;

   procedure Initialize_Specs is

      function Create_Keyword (K : Keyword) return Property_Value_Holder.Holder
      is
         Tmp : constant Property_Value :=
           (Kind => Keyword_Value, Value_Keyword => K);
      begin
         return Property_Value_Holder.To_Holder (Tmp);
      end Create_Keyword;

      function Create_Number (N : Integer) return Property_Value_Holder.Holder
      is
         Tmp : constant Property_Value := (Kind => Int_Value, Value_Int => N);
      begin
         return Property_Value_Holder.To_Holder (Tmp);
      end Create_Number;
   begin
      for Id in Property_Kind loop
         case Id is
            when Prop_Display              =>
               Property_Specs_Array (Prop_Display) :=
                 (Default_Value => Create_Keyword (Kw_Flex),
                  Layout        => True,
                  Inherit       => False,
                  Draw          => False,
                  kinds         => [Keyword_Value => True, others => False],
                  Check         => null);
            -- ZERO

            when Prop_X .. Prop_Max_Height =>
               Property_Specs_Array (Id) :=
                 (Default_Value => Create_Number (0),
                  Layout        => False,
                  Inherit       => False,
                  Draw          => False,
                  kinds         => [Int_Value => True, others => False],
                  Check         => null);

            when others                    =>
               null; -- FIXME PROVIDE VALUES FOR ALL THE SPEC
         end case;
      end loop;
   end Initialize_Specs;

end Adi.Style;
