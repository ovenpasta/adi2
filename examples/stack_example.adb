pragma Ada_2022;
with Adi.App;
with Stack_Example_UI; use Stack_Example_UI;

procedure Stack_Example is
   A : Adi.App.App;
   package UI is new Stack_Example_UI.Instance;

   procedure On_Tab (Value : Tab) is
   begin
      My_Stack.Set_Active (UI.Pages, Value);
   end On_Tab;

begin
   A.Init;
   A.Set_Target_FPS (60);
   UI.On_Tab := On_Tab'Unrestricted_Access;
   A.Add_Window (UI.Build);
   A.Run;
end Stack_Example;
