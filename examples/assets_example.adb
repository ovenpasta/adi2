pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.Assets;
with Adi.Font;
with Adi.MCP;
with Adi.Window; use Adi.Window;
with Assets_Example_UI;
with Assets_Example_Bundle;

procedure Assets_Example is
   A : Adi.App.App;
   package UI is new Assets_Example_UI.Instance;
   W : Window_Handle;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   Assets_Example_Bundle.Register_All;
   Adi.Assets.Set_Mode (Adi.Assets.Bundle_Mode);

   --  Load bundled font and set as app default (replaces system fallback)
   Adi.Font.Set_Default_Font
     (Adi.Font.Load_Asset ("OpenSans-Regular.ttf"));

   W := UI.Build;
   Adi.MCP.Initialize (W);
   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end Assets_Example;
