pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;   use Adi.Window;

with Demo_Block_UI;

procedure Demo_Block is
   A  : Adi.App.App;
   package UI is new Demo_Block_UI.Instance;
   W  : Window_Handle;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   W := UI.Build;
   Adi.MCP.Initialize (W);
   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Demo_Block;
