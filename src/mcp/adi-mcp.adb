pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Tags;
with Ada.Text_IO;
with GNAT.OS_Lib;

with Adi.Core;          use Adi.Core;
with Adi.JSON;
with Adi.Screenshot;
with Adi.SDL.Render;    use Adi.SDL.Render;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package body Adi.MCP is

   Active     : Boolean := False;
   MCP_Dir    : Unbounded_String;
   MCP_Window : access Adi.Window.Window'Class := null;

   --  Deferred screenshot: queued by the frame callback, executed by the
   --  post-render callback (which has a valid renderer with fresh content).
   Pending_Screenshot    : Boolean := False;
   Pending_Screenshot_Id : Unbounded_String;

   ---------------------------------------------------------------------------
   --  JSON Helpers
   ---------------------------------------------------------------------------

   function Escape_JSON_String (S : String) return String is
      Result : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '"'    => Append (Result, "\""");
            when '\'    => Append (Result, "\\");
            when ASCII.BS  => Append (Result, "\b");
            when ASCII.HT  => Append (Result, "\t");
            when ASCII.LF  => Append (Result, "\n");
            when ASCII.FF  => Append (Result, "\f");
            when ASCII.CR  => Append (Result, "\r");
            when others =>
               if Character'Pos (C) < 32 or else Character'Pos (C) >= 128 then
                  --  Control character or non-ASCII: emit \u00XX
                  declare
                     Hex : constant String := "0123456789abcdef";
                     Hi  : constant Natural := Character'Pos (C) / 16;
                     Lo  : constant Natural := Character'Pos (C) mod 16;
                  begin
                     Append (Result, "\u00");
                     Append (Result, Hex (Hex'First + Hi));
                     Append (Result, Hex (Hex'First + Lo));
                  end;
               else
                  Append (Result, C);
               end if;
         end case;
      end loop;
      return To_String (Result);
   end Escape_JSON_String;

   --  JSON key-value pair builders (append to Unbounded_String)
   procedure JKV_String
     (Buf : in out Unbounded_String;
      Key : String;
      Val : String;
      First : Boolean := False) is
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, """" & Key & """:""" & Escape_JSON_String (Val) & """");
   end JKV_String;

   procedure JKV_Int
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Integer;
      First : Boolean := False) is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Integer'Image (Val), Ada.Strings.Left);
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, """" & Key & """:" & Img);
   end JKV_Int;

   procedure JKV_Float
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Float;
      First : Boolean := False) is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Float'Image (Val), Ada.Strings.Left);
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, """" & Key & """:" & Img);
   end JKV_Float;

   procedure JKV_Bool
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Boolean;
      First : Boolean := False) is
   begin
      if not First then Append (Buf, ","); end if;
      if Val then
         Append (Buf, """" & Key & """:true");
      else
         Append (Buf, """" & Key & """:false");
      end if;
   end JKV_Bool;

   procedure JKV_Duration
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Duration;
      First : Boolean := False) is
      Ms : constant Float := Float (Val) * 1000.0;
   begin
      JKV_Float (Buf, Key, Ms, First);
   end JKV_Duration;

   ---------------------------------------------------------------------------
   --  File Helpers
   ---------------------------------------------------------------------------

   function Read_File (Path : String) return String is
      use Ada.Text_IO;
      F      : File_Type;
      Result : Unbounded_String;
      Line   : String (1 .. 4096);
      Last   : Natural;
   begin
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Get_Line (F, Line, Last);
         if Length (Result) > 0 then
            Append (Result, ASCII.LF);
         end if;
         Append (Result, Line (1 .. Last));
      end loop;
      Close (F);
      return To_String (Result);
   exception
      when others =>
         if Is_Open (F) then Close (F); end if;
         return "";
   end Read_File;

   procedure Write_File (Path : String; Content : String) is
      use Ada.Text_IO;
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   exception
      when others =>
         if Is_Open (F) then Close (F); end if;
   end Write_File;

   procedure Atomic_Write (Path : String; Content : String) is
      Tmp     : constant String := Path & ".tmp";
      Success : Boolean;
   begin
      Write_File (Tmp, Content);
      GNAT.OS_Lib.Rename_File (Tmp, Path, Success);
      if not Success then
         --  Fallback: direct write (less safe but works on some FS)
         Write_File (Path, Content);
         Ada.Directories.Delete_File (Tmp);
      end if;
   end Atomic_Write;

   ---------------------------------------------------------------------------
   --  Command Parsing (uses json-ada)
   ---------------------------------------------------------------------------

   --  Parse a JSON string and extract a field value.
   --  Returns "" if the key is missing or the value is not a string.
   function JSON_Get_String
     (JSON_Text : String; Key : String) return String
   is
      use Adi.JSON;
      P    : Parsers.Parser := Parsers.Create (JSON_Text);
      Root : constant Types.JSON_Value := P.Parse;
   begin
      if Root.Contains (Key) then
         return Root.Get (Key).Value;
      else
         return "";
      end if;
   exception
      when others => return "";
   end JSON_Get_String;

   ---------------------------------------------------------------------------
   --  Widget Tree Serialization
   ---------------------------------------------------------------------------

   procedure Serialize_Widget_Tree
     (W    : Widget_Access;
      Path : String;
      Buf  : in out Unbounded_String)
   is
      Geom : constant Rectangle := Get_Geometry (W.all);
   begin
      Append (Buf, "{");
      JKV_String (Buf, "type",
                  Ada.Characters.Handling.To_Lower
                    (Ada.Tags.External_Tag (W.all'Tag)),
                  First => True);
      JKV_String (Buf, "path", Path);
      JKV_Float (Buf, "x", Float (Geom.X));
      JKV_Float (Buf, "y", Float (Geom.Y));
      JKV_Float (Buf, "w", Float (Geom.Width));
      JKV_Float (Buf, "h", Float (Geom.Height));

      --  States
      declare
         States : constant Widget_States := Get_States (W.all);
         S_Buf  : Unbounded_String;
      begin
         Append (S_Buf, "[");
         declare
            First_S : Boolean := True;
         begin
            for St in Widget_State loop
               if States (St) then
                  if not First_S then Append (S_Buf, ","); end if;
                  Append (S_Buf, """" &
                    Ada.Characters.Handling.To_Lower
                      (Widget_State'Image (St)) & """");
                  First_S := False;
               end if;
            end loop;
         end;
         Append (S_Buf, "]");
         Append (Buf, ",""states"":" & To_String (S_Buf));
      end;

      JKV_Bool (Buf, "visible", Has_Flag (W.all, Visible));
      JKV_Bool (Buf, "clickable", Has_Flag (W.all, Clickable));
      JKV_Bool (Buf, "focusable", Has_Flag (W.all, Focusable));

      JKV_Int (Buf, "child_count", Child_Count (W.all));
      JKV_Int (Buf, "items_count", Item_Count (W.all));

      --  Children
      declare
         N : constant Natural := Child_Count (W.all);
      begin
         if N > 0 then
            Append (Buf, ",""children"":[");
            for I in 1 .. N loop
               if I > 1 then Append (Buf, ","); end if;
               declare
                  Child_Path : constant String :=
                    (if Path'Length = 0
                     then Ada.Strings.Fixed.Trim
                       (Positive'Image (I), Ada.Strings.Left)
                     else Path & "." & Ada.Strings.Fixed.Trim
                       (Positive'Image (I), Ada.Strings.Left));
                  C : constant Widget_Access := Get_Child (W.all, I);
               begin
                  Serialize_Widget_Tree (C, Child_Path, Buf);
               end;
            end loop;
            Append (Buf, "]");
         end if;
      end;

      Append (Buf, "}");
   end Serialize_Widget_Tree;

   ---------------------------------------------------------------------------
   --  Widget Lookup by Path
   ---------------------------------------------------------------------------

   function Find_Widget_By_Path
     (Root : Widget_Access;
      Path : String) return Widget_Access
   is
      use Ada.Strings.Fixed;
      --  Normalize to 1-based bounds so Index results are predictable
      Norm    : constant String (1 .. Path'Length) := Path;
      Current : Widget_Access := Root;
      Pos     : Positive := 1;
   begin
      if Norm'Length = 0 then return Root; end if;

      while Pos <= Norm'Last loop
         declare
            Dot     : constant Natural :=
              Index (Norm (Pos .. Norm'Last), ".");
            End_Pos : constant Natural :=
              (if Dot = 0 then Norm'Last else Dot - 1);
            Idx_Str : constant String := Norm (Pos .. End_Pos);
            Idx     : constant Positive := Positive'Value (Idx_Str);
         begin
            if Idx > Child_Count (Current.all) then
               return null;
            end if;
            Current := Get_Child (Current.all, Idx);
            Pos := End_Pos + 2;  --  Skip past the dot
         end;
      end loop;
      return Current;
   exception
      when others => return null;
   end Find_Widget_By_Path;

   ---------------------------------------------------------------------------
   --  Widget Info Serialization
   ---------------------------------------------------------------------------

   procedure Serialize_Widget_Info
     (W    : Widget_Access;
      Path : String;
      Buf  : in out Unbounded_String)
   is
      Geom : constant Rectangle := Get_Geometry (W.all);
   begin
      Append (Buf, "{");
      JKV_String (Buf, "type",
                  Ada.Characters.Handling.To_Lower
                    (Ada.Tags.External_Tag (W.all'Tag)),
                  First => True);
      JKV_String (Buf, "path", Path);
      JKV_Float (Buf, "x", Float (Geom.X));
      JKV_Float (Buf, "y", Float (Geom.Y));
      JKV_Float (Buf, "w", Float (Geom.Width));
      JKV_Float (Buf, "h", Float (Geom.Height));
      JKV_Int (Buf, "child_count", Child_Count (W.all));
      JKV_Int (Buf, "items_count", Item_Count (W.all));

      --  States
      declare
         States : constant Widget_States := Get_States (W.all);
      begin
         for St in Widget_State loop
            JKV_Bool (Buf, "state_" &
              Ada.Characters.Handling.To_Lower (Widget_State'Image (St)),
              States (St));
         end loop;
      end;

      --  Flags
      for Fl in Widget_Flag loop
         JKV_Bool (Buf, "flag_" &
           Ada.Characters.Handling.To_Lower (Widget_Flag'Image (Fl)),
           Has_Flag (W.all, Fl));
      end loop;

      Append (Buf, "}");
   end Serialize_Widget_Info;

   ---------------------------------------------------------------------------
   --  Command Execution
   ---------------------------------------------------------------------------

   function Execute_Command
     (Cmd      : String;
      Req_Id   : String) return String
   is
   begin
      if Cmd = "widget_tree" then
         declare
            Root : constant Widget_Access := Adi.Window.Get_Root (MCP_Window.all);
            Buf  : Unbounded_String;
         begin
            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            if Root /= null then
               Append (Buf, ",""tree"":");
               Serialize_Widget_Tree (Root, "", Buf);
            else
               Append (Buf, ",""tree"":null");
            end if;
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "perf_stats" then
         declare
            Stats : constant Adi.Window.Frame_Stats :=
              Adi.Window.Get_Frame_Stats (MCP_Window.all);
            Buf   : Unbounded_String;
         begin
            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "frame_no", Stats.Frame_No);
            JKV_Int (Buf, "render_us", Stats.Render_Us);
            JKV_Int (Buf, "update_us", Stats.Update_Us);
            JKV_Int (Buf, "layout_us", Stats.Layout_Us);
            JKV_Int (Buf, "draw_us", Stats.Draw_Us);
            JKV_Int (Buf, "present_us", Stats.Present_Us);
            JKV_Duration (Buf, "last_dt_ms", Stats.Last_DT);
            JKV_Int (Buf, "layout_count", Stats.Layout_Count);
            if Stats.Last_DT > 0.0 then
               JKV_Float (Buf, "fps",
                 Float'Min (9999.0, 1.0 / Float (Stats.Last_DT)));
            else
               JKV_Float (Buf, "fps", 0.0);
            end if;
            Append (Buf, "}");
            return To_String (Buf);
         end;

      else
         declare
            Buf : Unbounded_String;
         begin
            Append (Buf, "{");
            JKV_String (Buf, "status", "error", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_String (Buf, "error", "unknown command: " & Cmd);
            Append (Buf, "}");
            return To_String (Buf);
         end;
      end if;
   end Execute_Command;

   --  Extended version that receives full JSON for commands with parameters
   function Execute_Command_Full
     (JSON     : String;
      Cmd      : String;
      Req_Id   : String) return String
   is
   begin
      if Cmd = "widget_info" then
         declare
            Path_Str : constant String := JSON_Get_String (JSON, "path");
            Root     : constant Widget_Access :=
              Adi.Window.Get_Root (MCP_Window.all);
            Target   : Widget_Access;
            Buf      : Unbounded_String;
         begin
            if Root = null then
               Append (Buf, "{");
               JKV_String (Buf, "status", "error", First => True);
               JKV_String (Buf, "req_id", Req_Id);
               JKV_String (Buf, "error", "no root widget");
               Append (Buf, "}");
               return To_String (Buf);
            end if;

            if Path_Str'Length = 0 then
               Target := Root;
            else
               Target := Find_Widget_By_Path (Root, Path_Str);
            end if;

            if Target = null then
               Append (Buf, "{");
               JKV_String (Buf, "status", "error", First => True);
               JKV_String (Buf, "req_id", Req_Id);
               JKV_String (Buf, "error",
                 "widget not found at path: " & Path_Str);
               Append (Buf, "}");
               return To_String (Buf);
            end if;

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            Append (Buf, ",""widget"":");
            Serialize_Widget_Info (Target, Path_Str, Buf);
            Append (Buf, "}");
            return To_String (Buf);
         end;
      else
         return Execute_Command (Cmd, Req_Id);
      end if;
   end Execute_Command_Full;

   ---------------------------------------------------------------------------
   --  Polling & Callbacks
   ---------------------------------------------------------------------------

   --  Post-render callback: runs inside the render block (valid renderer).
   --  Only used for deferred screenshot capture.
   procedure Post_Render_Handler
     (Win      : not null access Adi.Window.Window'Class;
      Renderer : SDL_Renderer_Ptr)
   is
      pragma Unreferenced (Win);
   begin
      if not Pending_Screenshot then return; end if;

      declare
         Req_Id : constant String := To_String (Pending_Screenshot_Id);
         Dir    : constant String := To_String (MCP_Dir);
         Path   : constant String :=
           Dir & "/screenshot_" & Req_Id & ".png";
         Buf    : Unbounded_String;
         Resp_Path : constant String :=
           Dir & "/resp_" & Req_Id & ".json";
      begin
         Pending_Screenshot := False;
         Adi.Screenshot.Capture (Renderer, Path);
         Append (Buf, "{");
         JKV_String (Buf, "status", "ok", First => True);
         JKV_String (Buf, "req_id", Req_Id);
         JKV_String (Buf, "path", Path);
         Append (Buf, "}");
         Atomic_Write (Resp_Path, To_String (Buf));
      exception
         when others =>
            Pending_Screenshot := False;
            declare
               Err_Buf : Unbounded_String;
            begin
               Append (Err_Buf, "{");
               JKV_String (Err_Buf, "status", "error", First => True);
               JKV_String (Err_Buf, "req_id", Req_Id);
               JKV_String (Err_Buf, "error", "screenshot capture failed");
               Append (Err_Buf, "}");
               Atomic_Write (Resp_Path, To_String (Err_Buf));
            end;
      end;
   exception
      when others => null;  --  Never crash the render loop
   end Post_Render_Handler;

   --  Frame callback: runs unconditionally every frame.
   --  Polls for commands and handles non-screenshot commands immediately.
   --  Screenshot commands are deferred to the post-render callback.
   procedure Frame_Handler
     (Win : not null access Adi.Window.Window'Class)
   is
      use Ada.Directories;
      Dir  : constant String := To_String (MCP_Dir);
      Srch : Search_Type;
      Ent  : Directory_Entry_Type;
   begin
      --  Scan for cmd_*.json files
      Start_Search (Srch, Dir, "cmd_*.json",
                    [Ordinary_File => True, others => False]);
      if More_Entries (Srch) then
         Get_Next_Entry (Srch, Ent);
         End_Search (Srch);

         declare
            Cmd_Path  : constant String := Full_Name (Ent);
            Cmd_Name  : constant String := Simple_Name (Ent);
            JSON      : constant String := Read_File (Cmd_Path);
            Cmd       : constant String := JSON_Get_String (JSON, "command");
            Req_Id_J  : constant String := JSON_Get_String (JSON, "req_id");

            --  Fallback: extract req_id from filename "cmd_<id>.json"
            function Req_Id_From_Filename return String is
               --  "cmd_XXXX.json" -> strip "cmd_" prefix and ".json" suffix
               Prefix : constant String := "cmd_";
               Suffix : constant String := ".json";
            begin
               if Cmd_Name'Length > Prefix'Length + Suffix'Length
                 and then Cmd_Name (Cmd_Name'First ..
                   Cmd_Name'First + Prefix'Length - 1) = Prefix
                 and then Cmd_Name (Cmd_Name'Last - Suffix'Length + 1 ..
                   Cmd_Name'Last) = Suffix
               then
                  return Cmd_Name (Cmd_Name'First + Prefix'Length ..
                    Cmd_Name'Last - Suffix'Length);
               end if;
               return "";
            end Req_Id_From_Filename;

            Req_Id : constant String :=
              (if Req_Id_J'Length > 0 then Req_Id_J
               else Req_Id_From_Filename);
         begin
            --  Delete command file before processing (single-flight)
            if Exists (Cmd_Path) then
               Delete_File (Cmd_Path);
            end if;

            if Req_Id'Length = 0 then
               return;  --  No req_id anywhere — truly unrecoverable
            end if;

            if Cmd'Length = 0 then
               --  Missing command field — write error response
               declare
                  Err_Buf   : Unbounded_String;
                  Resp_Path : constant String :=
                    Dir & "/resp_" & Req_Id & ".json";
               begin
                  Append (Err_Buf, "{");
                  JKV_String (Err_Buf, "status", "error", First => True);
                  JKV_String (Err_Buf, "req_id", Req_Id);
                  JKV_String (Err_Buf, "error", "missing command field");
                  Append (Err_Buf, "}");
                  Atomic_Write (Resp_Path, To_String (Err_Buf));
               end;
               return;
            end if;

            if Cmd = "screenshot" then
               --  Defer to post-render callback (needs valid renderer)
               Pending_Screenshot := True;
               Pending_Screenshot_Id := To_Unbounded_String (Req_Id);
               Adi.Window.Request_Redraw (Win.all);
            else
               --  Non-screenshot commands execute immediately
               declare
                  Response  : constant String :=
                    Execute_Command_Full (JSON, Cmd, Req_Id);
                  Resp_Path : constant String :=
                    Dir & "/resp_" & Req_Id & ".json";
               begin
                  Atomic_Write (Resp_Path, Response);
               end;
            end if;
         end;
      else
         End_Search (Srch);
      end if;
   exception
      when others => null;  --  Never crash the render loop
   end Frame_Handler;

   ---------------------------------------------------------------------------
   --  Public API
   ---------------------------------------------------------------------------

   --  Check whether a process is alive via kill(pid, 0).
   function Is_Process_Alive (Pid : Integer) return Boolean is
      function C_Kill (P : Integer; Sig : Integer) return Integer
        with Import, Convention => C, External_Name => "kill";
   begin
      return C_Kill (Pid, 0) = 0;
   end Is_Process_Alive;

   --  Remove a stale MCP session directory and all its contents.
   procedure Remove_Directory_Recursive (Path : String) is
      use Ada.Directories;
      Srch : Search_Type;
      Ent  : Directory_Entry_Type;
   begin
      if not Exists (Path) then return; end if;
      Start_Search (Srch, Path, "",
                    [Ordinary_File => True, others => False]);
      while More_Entries (Srch) loop
         Get_Next_Entry (Srch, Ent);
         Delete_File (Full_Name (Ent));
      end loop;
      End_Search (Srch);
      Delete_Directory (Path);
   exception
      when others => null;
   end Remove_Directory_Recursive;

   --  Clean up stale session directories left by dead processes.
   procedure Cleanup_Stale_Dirs (Parent : String) is
      use Ada.Directories;
      Srch : Search_Type;
      Ent  : Directory_Entry_Type;
   begin
      if not Exists (Parent) then return; end if;
      Start_Search (Srch, Parent, "",
                    [Directory => True, others => False]);
      while More_Entries (Srch) loop
         Get_Next_Entry (Srch, Ent);
         declare
            Name : constant String := Simple_Name (Ent);
         begin
            --  Skip "." and ".."
            if Name /= "." and then Name /= ".." then
               declare
                  Dir_Pid : constant Integer := Integer'Value (Name);
               begin
                  if not Is_Process_Alive (Dir_Pid) then
                     Remove_Directory_Recursive (Full_Name (Ent));
                  end if;
               exception
                  when Constraint_Error => null;  --  Non-numeric dir name
               end;
            end if;
         end;
      end loop;
      End_Search (Srch);
   exception
      when others => null;
   end Cleanup_Stale_Dirs;

   procedure Initialize
     (Win      : not null access Adi.Window.Window'Class;
      Base_Dir : String := "/tmp/adi_mcp")
   is
      use GNAT.OS_Lib;
      Pid_Str : constant String := Ada.Strings.Fixed.Trim
        (Integer'Image (Pid_To_Integer (Current_Process_Id)),
         Ada.Strings.Left);
      Parent  : constant String := Ada.Directories.Full_Name (Base_Dir);
      Dir     : constant String := Parent & "/" & Pid_Str;
   begin
      if Active then return; end if;

      --  Create base directory if needed
      if not Ada.Directories.Exists (Parent) then
         Ada.Directories.Create_Directory (Parent);
      end if;

      --  Clean up stale session directories from prior runs
      Cleanup_Stale_Dirs (Parent);

      if not Ada.Directories.Exists (Dir) then
         Ada.Directories.Create_Directory (Dir);
      end if;

      MCP_Dir := To_Unbounded_String (Dir);
      MCP_Window := Win;
      Active := True;

      --  Write ready sentinel with PID
      Write_File (Dir & "/ready", Pid_Str);

      --  Register callbacks:
      --  Frame callback: polls for commands every frame (unconditional)
      --  Post-render callback: captures deferred screenshots (in render block)
      Adi.Window.Set_Frame_Callback
        (Win.all, Frame_Handler'Access);
      Adi.Window.Set_Post_Render_Callback
        (Win.all, Post_Render_Handler'Access);
   end Initialize;

   procedure Finalize is
      use Ada.Directories;
      Dir : constant String := To_String (MCP_Dir);
   begin
      if not Active then return; end if;

      --  Clear callbacks
      if MCP_Window /= null then
         Adi.Window.Set_Frame_Callback (MCP_Window.all, null);
         Adi.Window.Set_Post_Render_Callback (MCP_Window.all, null);
      end if;

      --  Clean up directory contents
      if Exists (Dir) then
         declare
            Srch : Search_Type;
            Ent  : Directory_Entry_Type;
         begin
            Start_Search (Srch, Dir, "",
                          [Ordinary_File => True, others => False]);
            while More_Entries (Srch) loop
               Get_Next_Entry (Srch, Ent);
               Delete_File (Full_Name (Ent));
            end loop;
            End_Search (Srch);
         exception
            when others => null;
         end;
         begin
            Delete_Directory (Dir);
         exception
            when others => null;
         end;
      end if;

      Active := False;
      MCP_Window := null;
   end Finalize;

   function Is_Active return Boolean is
   begin
      return Active;
   end Is_Active;

end Adi.MCP;
