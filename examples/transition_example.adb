pragma Ada_2022;
with Adi.App;
with Adi.Layout_Util;
with Adi.Log;
with Adi.MCP;
with Adi.Window; use Adi.Window;
with Transition_Example_UI;

--  Every button's transition and hover live in examples/css/transition_example.css, editable while the program runs.

procedure Transition_Example is
   A : Adi.App.App;
   package UI is new Transition_Example_UI.Instance;
   W : Window_Handle;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   W := UI.Build;

   declare
      OK : Boolean;
   begin
      UI.Set_CSS_File ("examples/css/transition_example.css", OK);
      if not OK then
         Adi.Log.Warning ("transition_example: live CSS reload not enabled");
      end if;
   end;

   Adi.MCP.Initialize (W);
   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Transition_Example;
