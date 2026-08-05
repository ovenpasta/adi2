pragma Ada_2022;
with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;       use Adi.Window;
with Stack_Example_UI; use Stack_Example_UI;

procedure Stack_Example is
   A : Adi.App.App;
   W : Window_Handle;
   package UI is new Stack_Example_UI.Instance;

   procedure On_Tab (Value : Tab) is
   begin
      My_Stack.Set_Active (UI.Pages, Value);
   end On_Tab;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);
   UI.On_Tab := On_Tab'Unrestricted_Access;
   W := UI.Build;
   Adi.MCP.Initialize (W);
   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Stack_Example;
