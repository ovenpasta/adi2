pragma Ada_2022;

package body Runtime_Css_Live_Root is

   use type Adi.CSS_Source.Source_Mode;

   function Create_Handle return Handle
   is (Ref => Impl.New_Widget);

   function "+" (H : Handle) return Widget_Handle
   is (Impl."+" (H.Ref));

   procedure Set_Status_Label
     (H : Handle; Label : Adi.Widget.Label.Label_Handle)
   is
      R : constant Impl.Ref := Impl.Borrow (H.Ref);
   begin
      R.Status_Label := Label;
   end Set_Status_Label;

   overriding procedure On_Tick (W : in out Live_Root_Widget; DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded : Boolean := False;
      Success  : Boolean := False;
   begin
      Adi.CSS_Source.Tick (Source, Reloaded, Success);

      if not Adi.Widget.Label.Is_Valid (W.Status_Label) then
         return;
      end if;

      if not Success then
         if W.Last_OK then
            Adi.Widget.Label.Set_Text (W.Status_Label,
              "CSS reload error: " & Adi.CSS_Source.Get_Last_Error (Source));
         end if;
         W.Last_OK := False;
         return;
      end if;

      if Reloaded
        and then Adi.CSS_Source.Get_Mode (Source) = Adi.CSS_Source.Dynamic_Mode
      then
         W.Reload_Count := W.Reload_Count + 1;
         Adi.Widget.Label.Set_Text (W.Status_Label,
           "Live reload OK (" & W.Reload_Count'Image
           & ") - edit css/runtime_css_example.css");
      end if;

      W.Last_OK := True;
   end On_Tick;

end Runtime_Css_Live_Root;
