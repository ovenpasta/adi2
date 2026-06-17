pragma Ada_2022;
with Adi.App;
with Adi.Layout_Util;
with Adi.Log;
with Adi.Widget;        use Adi.Widget;
with Adi.Window;        use Adi.Window;
with Hello_Example_UI;

procedure Hello_Example is
   A : Adi.App.App;
   package UI is new Hello_Example_UI.Instance;
   W : Window_Handle;

   procedure On_Hello_Click (Btn : Widget_Handle) is
      pragma Unreferenced (Btn);
   begin
      Adi.Log.Info ("Hello from Adi!");
   end On_Hello_Click;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);
   UI.On_Hello_Click := On_Hello_Click'Unrestricted_Access;
   W := UI.Build;
   declare
      OK : Boolean;
   begin
      UI.Set_CSS_File ("examples/css/hello_example.css", OK);
      if not OK then
         Adi.Log.Warning ("hello_example: live CSS reload not enabled");
      end if;
   end;
   A.Add_Window (W);
   A.Run;
end Hello_Example;
