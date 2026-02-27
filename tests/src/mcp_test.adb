pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Tags;

with Adi.JSON;
with Adi.Widget;     use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.MCP;

procedure MCP_Test is

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      Test_Count := Test_Count + 1;
      if Cond then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Msg);
      else
         Put_Line ("  [FAIL] " & Msg);
      end if;
   end Assert;

   ---------------------------------------------------------------------------
   --  Test: JSON parsing with json-ada (replaces hand-rolled parser tests)
   ---------------------------------------------------------------------------

   procedure Test_JSON_Parsing is
      use Adi.JSON;
   begin
      Put_Line ("-- JSON Parsing Tests --");

      --  Basic key extraction (no spaces after colon — old format)
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""command"":""widget_tree"",""req_id"":""abc123""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Root.Get ("command").Value = "widget_tree",
                 "parse compact: command field");
         Assert (Root.Get ("req_id").Value = "abc123",
                 "parse compact: req_id field");
      end;

      --  Spaces after colons (Python json.dumps format — the original bug)
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""command"": ""perf_stats"", ""req_id"": ""def456""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Root.Get ("command").Value = "perf_stats",
                 "parse with spaces: command field");
         Assert (Root.Get ("req_id").Value = "def456",
                 "parse with spaces: req_id field");
      end;

      --  Optional field: Contains check
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""command"": ""widget_info"", ""req_id"": ""x"", ""path"": ""1.2""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Root.Contains ("path"),
                 "contains existing key");
         Assert (Root.Get ("path").Value = "1.2",
                 "optional path field value");
         Assert (not Root.Contains ("nonexistent"),
                 "does not contain missing key");
      end;

      --  Missing optional field
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""command"": ""widget_tree"", ""req_id"": ""y""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (not Root.Contains ("path"),
                 "path absent when not provided");
      end;

      --  Escaped strings in values
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""msg"": ""say \""hi\""""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Root.Get ("msg").Value = "say ""hi""",
                 "parse escaped quotes in value");
      end;

      --  Newlines in values
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""text"": ""line1\nline2""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Root.Get ("text").Value = "line1" & ASCII.LF & "line2",
                 "parse escaped newline in value");
      end;
   end Test_JSON_Parsing;

   ---------------------------------------------------------------------------
   --  Test: MCP Initialize / Finalize lifecycle
   ---------------------------------------------------------------------------

   procedure Test_Lifecycle is
   begin
      Put_Line ("-- MCP Lifecycle Tests --");

      Assert (not Adi.MCP.Is_Active, "not active before init");

      --  We can't truly test Initialize without a real Window + SDL context,
      --  but we can verify Is_Active stays False
      Assert (not Adi.MCP.Is_Active, "still not active without init");

      --  Finalize should be safe when not active
      Adi.MCP.Finalize;
      Assert (not Adi.MCP.Is_Active, "finalize when not active is no-op");
   end Test_Lifecycle;

   ---------------------------------------------------------------------------
   --  Test: Widget tree structure
   ---------------------------------------------------------------------------

   procedure Test_Widget_Tree_Structure is
   begin
      Put_Line ("-- Widget Tree Structure Tests --");

      --  Create a simple hierarchy: Box with 2 children
      declare
         Root  : aliased Adi.Widget.Box.Box_Widget;
         Child1 : aliased Adi.Widget.Box.Box_Widget;
         Child2 : aliased Adi.Widget.Box.Box_Widget;
      begin
         Add_Child (Root, Child1'Unchecked_Access);
         Add_Child (Root, Child2'Unchecked_Access);

         Assert (Child_Count (Root) = 2, "root has 2 children");

         declare
            C1 : constant Widget_Access := Get_Child (Root, 1);
            C2 : constant Widget_Access := Get_Child (Root, 2);
         begin
            Assert (C1 /= null, "child 1 not null");
            Assert (C2 /= null, "child 2 not null");
         end;

         --  External_Tag gives the type name
         declare
            CW      : Widget'Class renames Widget'Class (Root);
            Tag_Str : constant String :=
              Ada.Characters.Handling.To_Lower
                (Ada.Tags.External_Tag (CW'Tag));
         begin
            Assert (Ada.Strings.Fixed.Index (Tag_Str, "box") > 0,
                    "external tag contains 'box': " & Tag_Str);
         end;

         --  Nested children
         declare
            Nested : aliased Adi.Widget.Box.Box_Widget;
         begin
            Add_Child (Child1, Nested'Unchecked_Access);
            Assert (Child_Count (Child1) = 1, "child1 has 1 nested child");

            declare
               Deep : constant Widget_Access := Get_Child (Child1, 1);
            begin
               Assert (Deep /= null, "nested child not null");
            end;

            Remove_Child (Child1, Nested'Unchecked_Access);
         end;

         Remove_Child (Root, Child2'Unchecked_Access);
         Remove_Child (Root, Child1'Unchecked_Access);
      end;
   end Test_Widget_Tree_Structure;

   ---------------------------------------------------------------------------
   --  Test: Widget states and flags
   ---------------------------------------------------------------------------

   procedure Test_Widget_States_Flags is
   begin
      Put_Line ("-- Widget States & Flags Tests --");

      declare
         W : aliased Adi.Widget.Box.Box_Widget;
      begin
         --  Default states
         declare
            States : constant Widget_States := Get_States (W);
         begin
            Assert (not States (State_Hovered), "not hovered by default");
            Assert (not States (State_Pressed), "not pressed by default");
            Assert (not States (State_Disabled), "not disabled by default");
         end;

         --  Set a state
         Set_Hovered (W, True);
         Assert (Has_State (W, State_Hovered), "hovered after set");

         --  Check flags
         Assert (Has_Flag (W, Visible), "visible by default");
         Assert (not Has_Flag (W, Focusable), "not focusable by default (Box)");

         Set_Hovered (W, False);
      end;
   end Test_Widget_States_Flags;

begin
   Put_Line ("=== MCP Test Suite ===");
   Put_Line ("");

   Test_JSON_Parsing;
   Test_Lifecycle;
   Test_Widget_Tree_Structure;
   Test_Widget_States_Flags;

   Put_Line ("");
   Put_Line ("Results:" & Natural'Image (Pass_Count) &
             " /" & Natural'Image (Test_Count) & " passed");
   if Pass_Count /= Test_Count then
      Put_Line ("SOME TESTS FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end MCP_Test;
