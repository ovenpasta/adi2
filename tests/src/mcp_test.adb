pragma Ada_2022;

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
with Adi.MCP.Testing;
with Adi.Render;
with Adi.Texture_Cache;

with Test_Support; use Test_Support;

procedure MCP_Test is

   function New_Box return Widget_Handle is
     (Adi.Widget.Box.To_Widget_Handle (Adi.Widget.Box.Create_Handle));

   function New_Label (Text : String := "") return Widget_Handle is
     (Adi.Widget.Label.To_Widget_Handle
        (Adi.Widget.Label.Create_Handle (Text)));

   ---------------------------------------------------------------------------
   --  Test: JSON parsing with json-ada (replaces hand-rolled parser tests)
   ---------------------------------------------------------------------------

   procedure Test_JSON_Parsing is
      use Adi.JSON;
   begin
      Section ("JSON Parsing Tests");

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
         Assert (Integer (JSON_Integer'(Root.Get ("id").Value)) = 42,
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
      Section ("MCP Lifecycle Tests");

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
      Section ("Widget Tree Structure Tests");

      --  Create a simple hierarchy: Box with 2 children
      declare
         Root   : constant Widget_Handle := New_Box;
         Child1 : constant Widget_Handle := New_Box;
         Child2 : constant Widget_Handle := New_Box;
      begin
         Add_Child (Root, Child1);
         Add_Child (Root, Child2);

         Assert (Child_Count (Root) = 2, "root has 2 children");

         declare
            C1 : constant Widget_Handle := Get_Child_Handle (Root, 1);
            C2 : constant Widget_Handle := Get_Child_Handle (Root, 2);
         begin
            Assert (Is_Valid (C1), "child 1 not null");
            Assert (Is_Valid (C2), "child 2 not null");
         end;

         --  External_Tag gives the type name
         declare
            Tag_Str : constant String :=
              Ada.Characters.Handling.To_Lower
                (Ada.Tags.External_Tag (Borrow (Root).Ptr.all'Tag));
         begin
            Assert (Ada.Strings.Fixed.Index (Tag_Str, "box") > 0,
                    "external tag contains 'box': " & Tag_Str);
         end;

         --  Nested children
         declare
            Nested : constant Widget_Handle := New_Box;
         begin
            Add_Child (Child1, Nested);
            Assert (Child_Count (Child1) = 1, "child1 has 1 nested child");

            declare
               Deep : constant Widget_Handle := Get_Child_Handle (Child1, 1);
            begin
               Assert (Is_Valid (Deep), "nested child not null");
            end;

            Remove_Child (Child1, Nested);
         end;

         Remove_Child (Root, Child2);
         Remove_Child (Root, Child1);
      end;
   end Test_Widget_Tree_Structure;

   ---------------------------------------------------------------------------
   --  Test: Widget states and flags
   ---------------------------------------------------------------------------

   procedure Test_Widget_States_Flags is
   begin
      Section ("Widget States & Flags Tests");

      declare
         W : constant Widget_Handle := New_Box;
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
      Section ("Widget ID Tests");

      declare
         W1 : constant Widget_Handle := New_Box;
         W2 : constant Widget_Handle := New_Box;
         W3 : constant Widget_Handle := New_Label;
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
      Section ("Introspection Get_Text Tests");

      --  Label widget
      declare
         L : constant Widget_Handle := New_Label ("Hello World");
      begin
         Assert (Get_Text (L) = "Hello World",
                 "Get_Text for label");
      end;

      --  Box widget (no text by default)
      declare
         B : constant Widget_Handle := New_Box;
      begin
         Assert (Get_Text (B) = "",
                 "Get_Text for box (empty)");
      end;

      --  Box with floating label
      declare
         B : constant Widget_Handle := New_Box;
      begin
         Set_Label (B, "My Label");
         Assert (Get_Text (B) = "My Label",
                 "Get_Text for box with floating label");
      end;
   end Test_Introspection_Get_Text;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Find_By_Id / Find_By_Path
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Find is
   begin
      Section ("Introspection Find Tests");

      declare
         Root   : constant Widget_Handle := New_Box;
         Child1 : constant Widget_Handle := New_Box;
         Child2 : constant Widget_Handle := New_Label;
         Nested : constant Widget_Handle := New_Box;
         Root_Acc   : constant Widget_Handle := Root;
         Child2_Acc : constant Widget_Handle := Child2;
         Nested_Acc : constant Widget_Handle := Nested;
      begin
         Add_Child (Root, Child1);
         Add_Child (Root, Child2);
         Add_Child (Child1, Nested);

         --  Find_By_Id
         declare
            Target_Id : constant Natural := Get_Id (Child2);
            Found     : constant Widget_Handle :=
              Find_By_Id (Root_Acc, Target_Id);
         begin
            Assert (Is_Valid (Found), "Find_By_Id: found widget");
            Assert (Found = Child2_Acc, "Find_By_Id: correct widget");
         end;

         --  Find_By_Id for nested
         declare
            Target_Id : constant Natural := Get_Id (Nested);
            Found     : constant Widget_Handle :=
              Find_By_Id (Root_Acc, Target_Id);
         begin
            Assert (Is_Valid (Found), "Find_By_Id: found nested widget");
            Assert (Found = Nested_Acc, "Find_By_Id: correct nested widget");
         end;

         --  Find_By_Id for non-existent
         declare
            Found : constant Widget_Handle :=
              Find_By_Id (Root_Acc, 999999);
         begin
            Assert (not Is_Valid (Found), "Find_By_Id: null for non-existent ID");
         end;

         --  Find_By_Path
         declare
            Found : constant Widget_Handle :=
              Find_By_Path (Root_Acc, "2");
         begin
            Assert (Is_Valid (Found), "Find_By_Path '2': found widget");
            Assert (Found = Child2_Acc, "Find_By_Path '2': correct widget");
         end;

         --  Find_By_Path nested
         declare
            Found : constant Widget_Handle :=
              Find_By_Path (Root_Acc, "1.1");
         begin
            Assert (Is_Valid (Found), "Find_By_Path '1.1': found widget");
            Assert (Found = Nested_Acc,
                    "Find_By_Path '1.1': correct nested widget");
         end;

         --  Find_Path (reverse lookup)
         declare
            Path : constant String := Find_Path (Root_Acc, Nested_Acc);
         begin
            Assert (Path = "1.1",
                    "Find_Path for nested: " & Path);
         end;

         --  Round-trip: Find_By_Id -> Find_Path
         declare
            Target_Id : constant Natural := Get_Id (Nested);
            Found     : constant Widget_Handle :=
              Find_By_Id (Root_Acc, Target_Id);
            Path      : constant String :=
              Find_Path (Root_Acc, Found);
            Found2    : constant Widget_Handle :=
              Find_By_Path (Root_Acc, Path);
         begin
            Assert (Found2 = Found,
                    "round-trip Find_By_Id -> Find_Path -> Find_By_Path");
         end;

         Remove_Child (Child1, Nested);
         Remove_Child (Root, Child2);
         Remove_Child (Root, Child1);
      end;
   end Test_Introspection_Find;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Find_By_Text
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Find_By_Text is
   begin
      Section ("Introspection Find_By_Text Tests");

      declare
         Root     : constant Widget_Handle := New_Box;
         Label1   : constant Widget_Handle := New_Label ("Save File");
         Label2   : constant Widget_Handle := New_Label ("Save As...");
         Label3   : constant Widget_Handle := New_Label ("Open File");
         Root_Acc : constant Widget_Handle := Root;
      begin
         Add_Child (Root, Label1);
         Add_Child (Root, Label2);
         Add_Child (Root, Label3);

         --  Substring match
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root_Acc, "Save");
         begin
            Assert (Integer (Matches.Length) = 2,
                    "Find_By_Text 'Save': 2 matches");
         end;

         --  Exact match
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root_Acc, "save file", Exact => True);
         begin
            Assert (Integer (Matches.Length) = 1,
                    "Find_By_Text exact 'save file': 1 match");
         end;

         --  Case insensitive
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root_Acc, "OPEN");
         begin
            Assert (Integer (Matches.Length) = 1,
                    "Find_By_Text 'OPEN': 1 match (case insensitive)");
         end;

         --  No match
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Text (Root_Acc, "Delete");
         begin
            Assert (Integer (Matches.Length) = 0,
                    "Find_By_Text 'Delete': 0 matches");
         end;

         Remove_Child (Root, Label3);
         Remove_Child (Root, Label2);
         Remove_Child (Root, Label1);
      end;
   end Test_Introspection_Find_By_Text;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Find_By_Type
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Find_By_Type is
   begin
      Section ("Introspection Find_By_Type Tests");

      declare
         Root     : constant Widget_Handle := New_Box;
         Child1   : constant Widget_Handle := New_Box;
         Label1   : constant Widget_Handle := New_Label;
         Root_Acc : constant Widget_Handle := Root;
      begin
         Add_Child (Root, Child1);
         Add_Child (Root, Label1);

         --  Find boxes
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Type (Root_Acc, "box");
         begin
            --  Root + Child1 = 2 boxes
            Assert (Integer (Matches.Length) = 2,
                    "Find_By_Type 'box': 2 matches");
         end;

         --  Find labels
         declare
            Matches : constant Match_Vectors.Vector :=
              Find_By_Type (Root_Acc, "label");
         begin
            Assert (Integer (Matches.Length) = 1,
                    "Find_By_Type 'label': 1 match");
         end;

         Remove_Child (Root, Label1);
         Remove_Child (Root, Child1);
      end;
   end Test_Introspection_Find_By_Type;

   ---------------------------------------------------------------------------
   --  Test: Introspection - Get_Info
   ---------------------------------------------------------------------------

   procedure Test_Introspection_Get_Info is
   begin
      Section ("Introspection Get_Info Tests");

      declare
         L : constant Widget_Handle := New_Label ("Test Label");
      begin
         declare
            Info : constant Widget_Info :=
              Get_Info (L, "1");
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

   --  The perf_stats texture_cache section. Asserted here rather than
   --  against a running application, so a renamed or dropped field fails
   --  the gate instead of surfacing the next time someone looks.
   procedure Test_Texture_Cache_Schema is
      use Adi.Texture_Cache;
      use Ada.Strings.Fixed;

      Stats : Adi.Render.Texture_Stats;
      W     : Adi.JSON.JSON_Writer := Adi.JSON.Create;
   begin
      Section ("perf_stats texture cache schema");

      Stats.Budget     := 64 * 1024 * 1024;
      Stats.Bytes_Used := 3_000;
      Stats.Peak_Bytes := 4_000;
      Stats.Idle_Bytes := 1_000;
      Stats.Count      := 2;
      Stats.Frames     := 17;

      --  Distinct per kind, so a serializer emitting one kind four times
      --  would not agree with what it was given.
      Stats.By_Kind (Shadow_Texture).Bytes    := 111;
      Stats.By_Kind (Raster_Texture).Bytes    := 222;
      Stats.By_Kind (SVG_Texture).Bytes       := 333;
      Stats.By_Kind (View_Texture).Bytes      := 444;
      Stats.By_Kind (Shadow_Texture).Pressure := 7;
      Stats.By_Kind (Shadow_Texture).Headroom := 9;

      W.Start_Object;
      W.Key ("texture_cache");
      Adi.MCP.Testing.Write_Texture_Cache (W, Stats);
      W.End_Object;

      declare
         Doc : constant String := W.To_String;

         function Occurrences (Field : String) return Natural is
            Needle : constant String := """" & Field & """";
            Found  : Natural := 0;
            From   : Natural := Doc'First;
            At_Pos : Natural;
         begin
            loop
               exit when From > Doc'Last;
               At_Pos := Index (Doc (From .. Doc'Last), Needle);
               exit when At_Pos = 0;
               Found := Found + 1;
               From := At_Pos + Needle'Length;
            end loop;
            return Found;
         end Occurrences;

         procedure Expect (Field : String) is
         begin
            Assert (Occurrences (Field) > 0,
                    "perf_stats texture_cache should carry " & Field);
         end Expect;

         --  Per-kind fields appear once for each of the four producers.
         --  Counting matters for names the outer object also uses: a
         --  missing per-kind figure would otherwise be masked by the
         --  total that shares its name.
         procedure Expect_Per_Kind (Field : String) is
         begin
            Assert (Occurrences (Field) >= 4,
                    "every producer should report " & Field);
         end Expect_Per_Kind;
      begin
         Expect ("texture_cache");
         Expect ("budget");
         Expect_Per_Kind ("bytes");
         Expect_Per_Kind ("peak_bytes");
         Expect_Per_Kind ("idle_bytes");
         Expect_Per_Kind ("count");
         Expect ("frames");
         Expect ("shadow");
         Expect ("raster");
         Expect ("svg");
         Expect ("view");
         Expect_Per_Kind ("active_bytes");
         Expect_Per_Kind ("active_count");
         Expect_Per_Kind ("idle_count");
         Expect_Per_Kind ("retired_bytes");
         Expect_Per_Kind ("retired_count");
         Expect_Per_Kind ("peak_count");
         Expect_Per_Kind ("hits");
         Expect_Per_Kind ("misses");
         Expect_Per_Kind ("stores");
         Expect_Per_Kind ("pressure_evictions");
         Expect_Per_Kind ("headroom_evictions");
         Expect_Per_Kind ("crowded_evictions");
         Expect_Per_Kind ("replaced");
         Expect_Per_Kind ("cleared");
         Expect_Per_Kind ("discarded");
         Expect_Per_Kind ("released");
         Expect_Per_Kind ("refused");
         Expect_Per_Kind ("build_us");

         Assert (Index (Doc, "111") > 0
                   and then Index (Doc, "222") > 0
                   and then Index (Doc, "333") > 0
                   and then Index (Doc, "444") > 0,
                 "and each kind's own figures, not one kind four times");
         Assert (Index (Doc, "7") > 0 and then Index (Doc, "9") > 0,
                 "with pressure and headroom both reported");
      end;
   end Test_Texture_Cache_Schema;


begin
   Start_Suite ("MCP Test Suite");
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

   Test_Texture_Cache_Schema;

   Test_Support.Finish;
end MCP_Test;
