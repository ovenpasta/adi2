pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Characters.Handling;
with Ada.Tags;

with Adi.JSON;
with Adi.Widget;               use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Introspection; use Adi.Widget.Introspection;
with Adi.Widget_Styles;        use Adi.Widget_Styles;
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

      --  Integer values
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""id"": 42, ""name"": ""test""}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Integer (Long_Integer'(Root.Get ("id").Value)) = 42,
                 "parse integer value");
      end;

      --  Boolean values
      declare
         P    : Parsers.Parser := Parsers.Create
           ("{""exact"": true, ""flag"": false}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         Assert (Boolean'(Root.Get ("exact").Value) = True,
                 "parse boolean true");
         Assert (Boolean'(Root.Get ("flag").Value) = False,
                 "parse boolean false");
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

   ---------------------------------------------------------------------------
   --  Test: Unique Widget IDs
   ---------------------------------------------------------------------------

   procedure Test_Widget_Ids is
   begin
      Put_Line ("-- Widget ID Tests --");

      declare
         W1 : aliased Adi.Widget.Box.Box_Widget;
         W2 : aliased Adi.Widget.Box.Box_Widget;
         W3 : aliased Adi.Widget.Label.Label_Widget;
      begin
         --  IDs should be unique
         Assert (Get_Id (W1) /= Get_Id (W2),
                 "w1 and w2 have different IDs");
         Assert (Get_Id (W2) /= Get_Id (W3),
                 "w2 and w3 have different IDs");

         --  IDs should be monotonically increasing
         Assert (Get_Id (W1) < Get_Id (W2),
                 "w1 ID < w2 ID (monotonic)");
         Assert (Get_Id (W2) < Get_Id (W3),
                 "w2 ID < w3 ID (monotonic)");

         --  IDs should be positive
         Assert (Get_Id (W1) > 0, "widget ID > 0");
      end;
   end Test_Widget_Ids;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Get_Text
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Get_Text is
   begin
      Put_Line ("-- Introspection Get_Text Tests --");

      --  Label widget
      declare
         L : aliased Adi.Widget.Label.Label_Widget;
      begin
         Adi.Widget.Label.Set_Text (L, "Hello World");
         Assert (Get_Text (L'Unchecked_Access) = "Hello World",
                 "Get_Text for label");
      end;

      --  Box widget (no text by default)
      declare
         B : aliased Adi.Widget.Box.Box_Widget;
      begin
         Assert (Get_Text (B'Unchecked_Access) = "",
                 "Get_Text for box (empty)");
      end;

      --  Box with floating label
      declare
         B : aliased Adi.Widget.Box.Box_Widget;
      begin
         Set_Label (B, "My Label");
         Assert (Get_Text (B'Unchecked_Access) = "My Label",
                 "Get_Text for box with floating label");
      end;
   end Test_Introspection_Get_Text;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Find_By_Id / Find_By_Path
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Find is
   begin
      Put_Line ("-- Introspection Find Tests --");

      declare
         Root   : aliased Adi.Widget.Box.Box_Widget;
         Child1 : aliased Adi.Widget.Box.Box_Widget;
         Child2 : aliased Adi.Widget.Label.Label_Widget;
         Nested : aliased Adi.Widget.Box.Box_Widget;
      begin
         Add_Child (Root, Child1'Unchecked_Access);
         Add_Child (Root, Child2'Unchecked_Access);
         Add_Child (Child1, Nested'Unchecked_Access);

         --  Find_By_Id
         declare
            Target_Id : constant Natural := Get_Id (Child2);
            Found     : constant Widget_Access :=
              Find_By_Id (Root'Unchecked_Access, Target_Id);
         begin
            Assert (Found /= null, "Find_By_Id: found widget");
            Assert (Found = Child2'Unchecked_Access,
                    "Find_By_Id: correct widget");
         end;

         --  Find_By_Id for nested
         declare
            Target_Id : constant Natural := Get_Id (Nested);
            Found     : constant Widget_Access :=
              Find_By_Id (Root'Unchecked_Access, Target_Id);
         begin
            Assert (Found /= null, "Find_By_Id: found nested widget");
            Assert (Found = Nested'Unchecked_Access,
                    "Find_By_Id: correct nested widget");
         end;

         --  Find_By_Id for non-existent
         declare
            Found : constant Widget_Access :=
              Find_By_Id (Root'Unchecked_Access, 999999);
         begin
            Assert (Found = null, "Find_By_Id: null for non-existent ID");
         end;

         --  Find_By_Path
         declare
            Found : constant Widget_Access :=
              Find_By_Path (Root'Unchecked_Access, "2");
         begin
            Assert (Found /= null, "Find_By_Path '2': found widget");
            Assert (Found = Child2'Unchecked_Access,
                    "Find_By_Path '2': correct widget");
         end;

         --  Find_By_Path nested
         declare
            Found : constant Widget_Access :=
              Find_By_Path (Root'Unchecked_Access, "1.1");
         begin
            Assert (Found /= null, "Find_By_Path '1.1': found widget");
            Assert (Found = Nested'Unchecked_Access,
                    "Find_By_Path '1.1': correct nested widget");
         end;

         --  Find_Path (reverse lookup)
         declare
            Path : constant String :=
              Find_Path (Root'Unchecked_Access, Nested'Unchecked_Access);
         begin
            Assert (Path = "1.1",
                    "Find_Path for nested: " & Path);
         end;

         --  Round-trip: Find_By_Id -> Find_Path
         declare
            Target_Id : constant Natural := Get_Id (Nested);
            Found     : constant Widget_Access :=
              Find_By_Id (Root'Unchecked_Access, Target_Id);
            Path      : constant String :=
              Find_Path (Root'Unchecked_Access, Found);
            Found2    : constant Widget_Access :=
              Find_By_Path (Root'Unchecked_Access, Path);
         begin
            Assert (Found2 = Found,
                    "round-trip Find_By_Id -> Find_Path -> Find_By_Path");
         end;

         Remove_Child (Child1, Nested'Unchecked_Access);
         Remove_Child (Root, Child2'Unchecked_Access);
         Remove_Child (Root, Child1'Unchecked_Access);
      end;
   end Test_Introspection_Find;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Find_By_Text
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Find_By_Text is
   begin
      Put_Line ("-- Introspection Find_By_Text Tests --");

      declare
         Root   : aliased Adi.Widget.Box.Box_Widget;
         Label1 : aliased Adi.Widget.Label.Label_Widget;
         Label2 : aliased Adi.Widget.Label.Label_Widget;
         Label3 : aliased Adi.Widget.Label.Label_Widget;
      begin
         Adi.Widget.Label.Set_Text (Label1, "Save File");
         Adi.Widget.Label.Set_Text (Label2, "Save As...");
         Adi.Widget.Label.Set_Text (Label3, "Open File");

         Add_Child (Root, Label1'Unchecked_Access);
         Add_Child (Root, Label2'Unchecked_Access);
         Add_Child (Root, Label3'Unchecked_Access);

         --  Substring match
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root'Unchecked_Access, "Save");
         begin
            Assert (Integer (Matches.Length) = 2,
                    "Find_By_Text 'Save': 2 matches");
         end;

         --  Exact match
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root'Unchecked_Access, "save file", Exact => True);
         begin
            Assert (Integer (Matches.Length) = 1,
                    "Find_By_Text exact 'save file': 1 match");
         end;

         --  Case insensitive
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root'Unchecked_Access, "OPEN");
         begin
            Assert (Integer (Matches.Length) = 1,
                    "Find_By_Text 'OPEN': 1 match (case insensitive)");
         end;

         --  No match
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root'Unchecked_Access, "Delete");
         begin
            Assert (Integer (Matches.Length) = 0,
                    "Find_By_Text 'Delete': 0 matches");
         end;

         Remove_Child (Root, Label3'Unchecked_Access);
         Remove_Child (Root, Label2'Unchecked_Access);
         Remove_Child (Root, Label1'Unchecked_Access);
      end;
   end Test_Introspection_Find_By_Text;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Find_By_Type
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Find_By_Type is
   begin
      Put_Line ("-- Introspection Find_By_Type Tests --");

      declare
         Root   : aliased Adi.Widget.Box.Box_Widget;
         Child1 : aliased Adi.Widget.Box.Box_Widget;
         Label1 : aliased Adi.Widget.Label.Label_Widget;
      begin
         Add_Child (Root, Child1'Unchecked_Access);
         Add_Child (Root, Label1'Unchecked_Access);

         --  Find boxes
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Type (Root'Unchecked_Access, "box");
         begin
            --  Root + Child1 = 2 boxes
            Assert (Integer (Matches.Length) = 2,
                    "Find_By_Type 'box': 2 matches");
         end;

         --  Find labels
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Type (Root'Unchecked_Access, "label");
         begin
            Assert (Integer (Matches.Length) = 1,
                    "Find_By_Type 'label': 1 match");
         end;

         Remove_Child (Root, Label1'Unchecked_Access);
         Remove_Child (Root, Child1'Unchecked_Access);
      end;
   end Test_Introspection_Find_By_Type;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Get_Info
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Get_Info is
   begin
      Put_Line ("-- Introspection Get_Info Tests --");

      declare
         L : aliased Adi.Widget.Label.Label_Widget;
      begin
         Adi.Widget.Label.Set_Text (L, "Test Label");

         declare
            Info : constant Widget_Info :=
              Get_Info (L'Unchecked_Access, "1");
         begin
            Assert (Info.Id = Get_Id (L),
                    "Get_Info: correct ID");
            Assert (To_String (Info.Text) = "Test Label",
                    "Get_Info: correct text");
            Assert (To_String (Info.Path) = "1",
                    "Get_Info: correct path");
            Assert (Ada.Strings.Fixed.Index
                      (To_String (Info.Tag_Name), "label") > 0,
                    "Get_Info: tag contains 'label'");
            Assert (Info.Flags (Visible),
                    "Get_Info: visible flag");
         end;
      end;
   end Test_Introspection_Get_Info;

begin
   Put_Line ("=== MCP Test Suite ===");
   Put_Line ("");

   Test_JSON_Parsing;
   Test_Lifecycle;
   Test_Widget_Tree_Structure;
   Test_Widget_States_Flags;
   Test_Widget_Ids;
   Test_Introspection_Get_Text;
   Test_Introspection_Find;
   Test_Introspection_Find_By_Text;
   Test_Introspection_Find_By_Type;
   Test_Introspection_Get_Info;

   Put_Line ("");
   Put_Line ("Results:" & Natural'Image (Pass_Count) &
             " /" & Natural'Image (Test_Count) & " passed");
   if Pass_Count /= Test_Count then
      Put_Line ("SOME TESTS FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end MCP_Test;
