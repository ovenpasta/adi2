with Ada.Text_IO;
with Adi.Build_Target;
with Adi_Config;

package body Adi.Log is

   Debug_Log_File : constant String := "debug.log";

   procedure Write_To_File (Msg : String) is
      F : Ada.Text_IO.File_Type;
   begin
      begin
         Ada.Text_IO.Open (File => F,
                           Mode => Ada.Text_IO.Append_File,
                           Name => Debug_Log_File);
      exception
         when others =>
            Ada.Text_IO.Create (File => F,
                                Mode => Ada.Text_IO.Out_File,
                                Name => Debug_Log_File);
      end;

      Ada.Text_IO.Put_Line (F, Msg);
      Ada.Text_IO.Close (F);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
   end Write_To_File;

   procedure Write_To_Console (Msg : String) is
   begin
      Ada.Text_IO.Put_Line (Msg);
   exception
      when others =>
         null;
   end Write_To_Console;

   procedure Write (Msg : String) is
   begin
      if Adi_Config.Build_Profile = Adi_Config.development then
         if Adi.Build_Target.Is_Windows then
            Write_To_File (Msg);
         else
            Write_To_Console (Msg);
         end if;
      end if;
   end Write;

   procedure Debug (Msg : String) is
   begin
      Write ("[DEBUG] " & Msg);
   end Debug;

   procedure Info (Msg : String) is
   begin
      Write ("[INFO] " & Msg);
   end Info;

   procedure Warning (Msg : String) is
   begin
      Write ("[WARNING] " & Msg);
   end Warning;

   procedure Error (Msg : String) is
   begin
      Write ("[ERROR] " & Msg);
   end Error;

end Adi.Log;
