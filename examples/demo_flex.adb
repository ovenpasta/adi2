pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.Window;   use Adi.Window;

with Demo_Flex_UI;

procedure Demo_Flex is
   A  : Adi.App.App;
   package UI is new Demo_Flex_UI.Instance;
   W  : Window_Handle;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   W := UI.Build;
   A.Add_Window (W);
   A.Run;
end Demo_Flex;
