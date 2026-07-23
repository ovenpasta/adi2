pragma Ada_2022;

with Ada.Directories;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;

with Adi.Settings;              use Adi.Settings;
with Adi.Settings.JSON_Backend; use Adi.Settings.JSON_Backend;

procedure Settings_Test is

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Put_Line ("  [FAIL] " & Msg);
      end if;
   end Assert;

   --  Temporary directory for test files
   Tmp_Dir : constant String := "/tmp/adi_settings_test/";

   procedure Ensure_Tmp_Dir is
   begin
      if not Ada.Directories.Exists (Tmp_Dir) then
         Ada.Directories.Create_Path (Tmp_Dir);
      end if;
   end Ensure_Tmp_Dir;

   procedure Cleanup is
   begin
      if Ada.Directories.Exists (Tmp_Dir & "settings.json") then
         Ada.Directories.Delete_File (Tmp_Dir & "settings.json");
      end if;
      if Ada.Directories.Exists (Tmp_Dir & "settings.json.tmp") then
         Ada.Directories.Delete_File (Tmp_Dir & "settings.json.tmp");
      end if;
      if Ada.Directories.Exists (Tmp_Dir) then
         Ada.Directories.Delete_Directory (Tmp_Dir);
      end if;
   exception
      when others => null;
   end Cleanup;

   ---------------------------------------------------------------------------
   --  Test: Setting_Value scalar constructors and extractors
   ---------------------------------------------------------------------------

   procedure Test_Scalar_Values is
   begin
      Put_Line ("-- Scalar Value Tests --");

      --  Null
      declare
         V : constant Setting_Value := Null_Value;
      begin
         Assert (Kind (V) = Null_Kind, "Null_Value kind");
      end;

      --  String
      declare
         V : constant Setting_Value := To_Value ("hello");
      begin
         Assert (Kind (V) = String_Kind, "String kind");
         Assert (As_String (V) = "hello", "String value");
      end;

      --  Integer
      declare
         V : constant Setting_Value := To_Value (Long_Integer (42));
      begin
         Assert (Kind (V) = Integer_Kind, "Integer kind");
         Assert (As_Integer (V) = 42, "Integer value");
      end;

      --  Negative integer
      declare
         V : constant Setting_Value := To_Value (Long_Integer (-99));
      begin
         Assert (As_Integer (V) = -99, "Negative integer value");
      end;

      --  Float
      declare
         V : constant Setting_Value := To_Value (Long_Float (3.14));
      begin
         Assert (Kind (V) = Float_Kind, "Float kind");
         Assert (abs (As_Float (V) - 3.14) < 0.001, "Float value");
      end;

      --  Boolean
      declare
         V_True  : constant Setting_Value := To_Value (True);
         V_False : constant Setting_Value := To_Value (False);
      begin
         Assert (Kind (V_True) = Boolean_Kind, "Boolean kind");
         Assert (As_Boolean (V_True) = True, "Boolean true");
         Assert (As_Boolean (V_False) = False, "Boolean false");
      end;
   end Test_Scalar_Values;

   ---------------------------------------------------------------------------
   --  Test: Wrong kind extractors raise Constraint_Error
   ---------------------------------------------------------------------------

   procedure Test_Wrong_Kind is
      V : constant Setting_Value := To_Value ("text");
   begin
      Put_Line ("-- Wrong Kind Tests --");

      begin
         declare
            Dummy : constant Long_Integer := As_Integer (V);
            pragma Unreferenced (Dummy);
         begin
            Assert (False, "As_Integer on string should raise");
         end;
      exception
         when Constraint_Error =>
            Assert (True, "As_Integer on string raises Constraint_Error");
      end;

      begin
         declare
            Dummy : constant Boolean := As_Boolean (V);
            pragma Unreferenced (Dummy);
         begin
            Assert (False, "As_Boolean on string should raise");
         end;
      exception
         when Constraint_Error =>
            Assert (True, "As_Boolean on string raises Constraint_Error");
      end;
   end Test_Wrong_Kind;

   ---------------------------------------------------------------------------
   --  Test: List operations
   ---------------------------------------------------------------------------

   procedure Test_List is
   begin
      Put_Line ("-- List Tests --");

      declare
         L : Setting_Value := Empty_List;
      begin
         Assert (Kind (L) = List_Kind, "Empty list kind");
         Assert (Length (L) = 0, "Empty list length");

         Append (L, To_Value ("first"));
         Append (L, To_Value ("second"));
         Append (L, To_Value (Long_Integer (3)));

         Assert (Length (L) = 3, "List length after appends");
         Assert (As_String (Element (L, 1)) = "first", "List element 1");
         Assert (As_String (Element (L, 2)) = "second", "List element 2");
         Assert (As_Integer (Element (L, 3)) = 3, "List element 3");
      end;
   end Test_List;

   ---------------------------------------------------------------------------
   --  Test: Map operations
   ---------------------------------------------------------------------------

   procedure Test_Map is
   begin
      Put_Line ("-- Map Tests --");

      declare
         M : Setting_Value := Empty_Map;
      begin
         Assert (Kind (M) = Map_Kind, "Empty map kind");
         Assert (not Contains (M, "key"), "Empty map contains");

         Insert (M, "name", To_Value ("Adi"));
         Insert (M, "version", To_Value (Long_Integer (2)));

         Assert (Contains (M, "name"), "Map contains 'name'");
         Assert (As_String (Get (M, "name")) = "Adi", "Map get 'name'");
         Assert (As_Integer (Get (M, "version")) = 2, "Map get 'version'");
         Assert (Kind (Get (M, "missing")) = Null_Kind,
                 "Map get missing returns Null");

         --  Insert replacing existing key
         Insert (M, "name", To_Value ("Adi2"));
         Assert (As_String (Get (M, "name")) = "Adi2",
                 "Map replace existing key");
      end;
   end Test_Map;

   ---------------------------------------------------------------------------
   --  Test: Value assignment produces independent deep copies
   ---------------------------------------------------------------------------

   procedure Test_Deep_Copy is
   begin
      Put_Line ("-- Deep Copy Tests --");

      --  Scalar copy independence
      declare
         A : constant Setting_Value := To_Value ("original");
         B : Setting_Value := A;
         pragma Unreferenced (B);
      begin
         --  B is a copy; modifying B doesn't affect A
         B := To_Value ("modified");
         Assert (As_String (A) = "original",
                 "Scalar assignment produces independent copy");
      end;

      --  Map copy independence
      declare
         M1 : Setting_Value := Empty_Map;
         M2 : Setting_Value;
      begin
         Insert (M1, "key", To_Value ("val1"));
         M2 := M1;
         Insert (M2, "key", To_Value ("val2"));
         Assert (As_String (Get (M1, "key")) = "val1",
                 "Map copy is independent");
         Assert (As_String (Get (M2, "key")) = "val2",
                 "Map copy has new value");
      end;

      --  List copy independence
      declare
         L1 : Setting_Value := Empty_List;
         L2 : Setting_Value;
      begin
         Append (L1, To_Value ("a"));
         L2 := L1;
         Append (L2, To_Value ("b"));
         Assert (Length (L1) = 1, "List copy: original unchanged");
         Assert (Length (L2) = 2, "List copy: copy has new element");
      end;
   end Test_Deep_Copy;

   ---------------------------------------------------------------------------
   --  Test: Settings_Store basic operations (no file I/O)
   ---------------------------------------------------------------------------

   procedure Test_Store_Basic is
      Store : Settings_Store;
      B     : aliased JSON_Settings_Backend;
   begin
      Put_Line ("-- Store Basic Tests --");

      Store.Initialize ("test_org", "test_app",
                        Backend => B'Unchecked_Access);

      --  Set and get scalar types
      Store.Set ("name", "Adi");
      Store.Set ("width", Long_Integer (800));
      Store.Set ("scale", Long_Float (1.5));
      Store.Set ("fullscreen", True);

      Assert (Store.Get_String ("name") = "Adi", "Store get string");
      Assert (Store.Get_Integer ("width") = 800, "Store get integer");
      Assert (abs (Store.Get_Float ("scale") - 1.5) < 0.001,
              "Store get float");
      Assert (Store.Get_Boolean ("fullscreen") = True, "Store get boolean");

      --  Defaults for missing keys
      Assert (Store.Get_String ("missing", "def") = "def",
              "Default string");
      Assert (Store.Get_Integer ("missing", 99) = 99,
              "Default integer");
      Assert (Store.Get_Float ("missing", 2.0) = 2.0,
              "Default float");
      Assert (Store.Get_Boolean ("missing", True) = True,
              "Default boolean");

      --  Contains
      Assert (Store.Contains ("name"), "Contains existing key");
      Assert (not Store.Contains ("missing"), "Contains missing key");

      --  Remove
      Store.Remove ("name");
      Assert (not Store.Contains ("name"), "Remove key");

      --  Clear
      Store.Set ("a", "1");
      Store.Set ("b", "2");
      Store.Clear;
      Assert (not Store.Contains ("a"), "Clear removes all (a)");
      Assert (not Store.Contains ("b"), "Clear removes all (b)");
   end Test_Store_Basic;

   ---------------------------------------------------------------------------
   --  Test: Dot-path navigation and auto-creation
   ---------------------------------------------------------------------------

   procedure Test_Dot_Paths is
      Store : Settings_Store;
      B     : aliased JSON_Settings_Backend;
   begin
      Put_Line ("-- Dot-Path Tests --");

      Store.Initialize ("test_org", "test_app",
                        Backend => B'Unchecked_Access);

      --  Set creates intermediate maps
      Store.Set ("window.width", Long_Integer (1024));
      Store.Set ("window.height", Long_Integer (768));
      Store.Set ("window.title", "My App");

      Assert (Store.Get_Integer ("window.width") = 1024,
              "Dot-path get nested integer");
      Assert (Store.Get_String ("window.title") = "My App",
              "Dot-path get nested string");

      --  Deeper nesting
      Store.Set ("ui.theme.name", "dark");
      Assert (Store.Get_String ("ui.theme.name") = "dark",
              "Dot-path 3-level nesting");

      --  The parent should be a map
      declare
         Window_Val : constant Setting_Value := Store.Get ("window");
      begin
         Assert (Kind (Window_Val) = Map_Kind,
                 "Dot-path parent is a map");
         Assert (As_Integer (Get (Window_Val, "width")) = 1024,
                 "Dot-path parent map contents");
      end;

      --  Remove nested key
      Store.Remove ("window.title");
      Assert (not Store.Contains ("window.title"),
              "Remove nested key");
      Assert (Store.Contains ("window.width"),
              "Remove nested key preserves siblings");
   end Test_Dot_Paths;

   ---------------------------------------------------------------------------
   --  Test: Escaped dots in key segments
   ---------------------------------------------------------------------------

   procedure Test_Escaped_Dots is
      Store : Settings_Store;
      B     : aliased JSON_Settings_Backend;
   begin
      Put_Line ("-- Escaped Dot Tests --");

      Store.Initialize ("test_org", "test_app",
                        Backend => B'Unchecked_Access);

      --  "app\.version" -> single segment "app.version"
      Store.Set ("app\.version", "1.0");
      Assert (Store.Get_String ("app\.version") = "1.0",
              "Escaped dot in key");

      --  "meta.app\.name" -> segments ["meta", "app.name"]
      Store.Set ("meta.app\.name", "MyApp");
      Assert (Store.Get_String ("meta.app\.name") = "MyApp",
              "Escaped dot in nested key");
   end Test_Escaped_Dots;

   ---------------------------------------------------------------------------
   --  Test: JSON save/load round-trip
   ---------------------------------------------------------------------------

   procedure Test_JSON_Round_Trip is
   begin
      Put_Line ("-- JSON Round-Trip Tests --");

      Ensure_Tmp_Dir;

      declare
         B    : aliased JSON_Settings_Backend;
         Path : constant String := Tmp_Dir & "settings.json";
         Data : Setting_Value := Empty_Map;
      begin
         --  Build a value tree
         Insert (Data, "name", To_Value ("TestApp"));
         Insert (Data, "count", To_Value (Long_Integer (42)));
         Insert (Data, "ratio", To_Value (Long_Float (2.5)));
         Insert (Data, "enabled", To_Value (True));

         --  Nested map
         declare
            Window : Setting_Value := Empty_Map;
         begin
            Insert (Window, "width", To_Value (Long_Integer (800)));
            Insert (Window, "height", To_Value (Long_Integer (600)));
            Insert (Data, "window", Window);
         end;

         --  List
         declare
            Tags : Setting_Value := Empty_List;
         begin
            Append (Tags, To_Value ("gui"));
            Append (Tags, To_Value ("ada"));
            Insert (Data, "tags", Tags);
         end;

         --  Null
         Insert (Data, "optional", Null_Value);

         --  Save
         B.Save (Path, Data);

         --  Verify file was created
         Assert (Ada.Directories.Exists (Path),
                 "JSON file created");

         --  Load into fresh value
         declare
            Loaded : constant Setting_Value := B.Load (Path);
         begin
            Assert (Kind (Loaded) = Map_Kind, "Loaded is a map");
            Assert (As_String (Get (Loaded, "name")) = "TestApp",
                    "Round-trip string");
            Assert (As_Integer (Get (Loaded, "count")) = 42,
                    "Round-trip integer");
            Assert (abs (As_Float (Get (Loaded, "ratio")) - 2.5) < 0.001,
                    "Round-trip float");
            Assert (As_Boolean (Get (Loaded, "enabled")) = True,
                    "Round-trip boolean");
            Assert (Kind (Get (Loaded, "optional")) = Null_Kind,
                    "Round-trip null");

            --  Nested map
            declare
               W : constant Setting_Value := Get (Loaded, "window");
            begin
               Assert (Kind (W) = Map_Kind, "Round-trip nested map kind");
               Assert (As_Integer (Get (W, "width")) = 800,
                       "Round-trip nested integer");
            end;

            --  List
            declare
               T : constant Setting_Value := Get (Loaded, "tags");
            begin
               Assert (Kind (T) = List_Kind, "Round-trip list kind");
               Assert (Length (T) = 2, "Round-trip list length");
               Assert (As_String (Element (T, 1)) = "ada"
                       or else As_String (Element (T, 1)) = "gui",
                       "Round-trip list element present");
            end;
         end;
      end;
   end Test_JSON_Round_Trip;

   ---------------------------------------------------------------------------
   --  Test: Special character string preservation
   ---------------------------------------------------------------------------

   procedure Test_Special_Chars is
   begin
      Put_Line ("-- Special Character Tests --");

      declare
         B    : aliased JSON_Settings_Backend;
         Path : constant String := Tmp_Dir & "settings.json";
         Data : Setting_Value := Empty_Map;
      begin
         Ensure_Tmp_Dir;

         --  Strings with JSON-special characters
         Insert (Data, "quotes", To_Value ("He said ""hello"""));
         Insert (Data, "backslash", To_Value ("path\to\file"));
         Insert (Data, "newlines", To_Value ("line1" & ASCII.LF & "line2"));
         Insert (Data, "tabs", To_Value ("col1" & ASCII.HT & "col2"));
         Insert (Data, "empty", To_Value (""));

         B.Save (Path, Data);

         declare
            Loaded : constant Setting_Value := B.Load (Path);
         begin
            Assert (As_String (Get (Loaded, "quotes")) =
                    "He said ""hello""",
                    "Escaped quotes round-trip");
            Assert (As_String (Get (Loaded, "backslash")) =
                    "path\to\file",
                    "Backslash round-trip");
            Assert (As_String (Get (Loaded, "newlines")) =
                    "line1" & ASCII.LF & "line2",
                    "Newline round-trip");
            Assert (As_String (Get (Loaded, "tabs")) =
                    "col1" & ASCII.HT & "col2",
                    "Tab round-trip");
            Assert (As_String (Get (Loaded, "empty")) = "",
                    "Empty string round-trip");
         end;
      end;
   end Test_Special_Chars;

   ---------------------------------------------------------------------------
   --  Test: Load from non-existent file returns Null_Value
   ---------------------------------------------------------------------------

   procedure Test_Missing_File is
   begin
      Put_Line ("-- Missing File Tests --");

      declare
         B : aliased JSON_Settings_Backend;
         V : constant Setting_Value :=
           B.Load ("/tmp/adi_settings_test_nonexistent/settings.json");
      begin
         Assert (Kind (V) = Null_Kind,
                 "Load non-existent file returns Null");
      end;
   end Test_Missing_File;

   ---------------------------------------------------------------------------
   --  Test: Save to an unwritable path propagates the failure
   --  (regression: write errors used to be swallowed, so disk-full and
   --  permission failures looked like successful saves)
   ---------------------------------------------------------------------------

   procedure Test_Save_Failure_Raises is
      B : aliased JSON_Settings_Backend;
      V : Setting_Value := Empty_Map;
   begin
      Put_Line ("-- Save Failure Tests --");

      Insert (V, "key", To_Value ("value"));
      begin
         B.Save ("/nonexistent_adi_dir/settings.json", V);
         Assert (False, "Save to unwritable path should raise");
      exception
         when others =>
            Assert (True, "Save to unwritable path raises");
      end;
   end Test_Save_Failure_Raises;

   ---------------------------------------------------------------------------
   --  Test: Empty store
   ---------------------------------------------------------------------------

   procedure Test_Empty_Store is
      Store : Settings_Store;
      B     : aliased JSON_Settings_Backend;
   begin
      Put_Line ("-- Empty Store Tests --");

      Store.Initialize ("test_org", "test_app",
                        Backend => B'Unchecked_Access);

      Assert (Store.Get_String ("any") = "", "Empty store default string");
      Assert (Store.Get_Integer ("any") = 0, "Empty store default integer");
      Assert (not Store.Contains ("any"), "Empty store contains");
   end Test_Empty_Store;

   ---------------------------------------------------------------------------
   --  Test: Nested structure operations
   ---------------------------------------------------------------------------

   procedure Test_Nested_Structures is
      Store : Settings_Store;
      B     : aliased JSON_Settings_Backend;
   begin
      Put_Line ("-- Nested Structure Tests --");

      Store.Initialize ("test_org", "test_app",
                        Backend => B'Unchecked_Access);

      --  Set a complex nested value via Setting_Value
      declare
         Servers : Setting_Value := Empty_List;
         S1      : Setting_Value := Empty_Map;
         S2      : Setting_Value := Empty_Map;
      begin
         Insert (S1, "host", To_Value ("localhost"));
         Insert (S1, "port", To_Value (Long_Integer (8080)));
         Insert (S2, "host", To_Value ("remote.example.com"));
         Insert (S2, "port", To_Value (Long_Integer (443)));
         Append (Servers, S1);
         Append (Servers, S2);
         Store.Set ("network.servers", Servers);
      end;

      --  Retrieve and check
      declare
         V : constant Setting_Value := Store.Get ("network.servers");
      begin
         Assert (Kind (V) = List_Kind, "Nested list via store");
         Assert (Length (V) = 2, "Nested list length");

         declare
            First : constant Setting_Value := Element (V, 1);
         begin
            Assert (As_String (Get (First, "host")) = "localhost",
                    "Nested list element map field");
            Assert (As_Integer (Get (First, "port")) = 8080,
                    "Nested list element map int field");
         end;
      end;
   end Test_Nested_Structures;

   ---------------------------------------------------------------------------
   --  Test: Contains with null-valued keys
   ---------------------------------------------------------------------------

   procedure Test_Null_Value_Contains is
      Store : Settings_Store;
      B     : aliased JSON_Settings_Backend;
   begin
      Put_Line ("-- Null Value Contains Tests --");

      Store.Initialize ("test_org", "test_app",
                        Backend => B'Unchecked_Access);

      --  Set a key to Null_Value explicitly
      Store.Set ("explicit_null", Null_Value);

      --  Contains should report the key as present even though value is null
      Assert (Store.Contains ("explicit_null"),
              "Contains returns True for explicitly-set null key");

      --  Get should return Null_Kind
      Assert (Kind (Store.Get ("explicit_null")) = Null_Kind,
              "Get returns Null_Kind for null-valued key");

      --  A key that was never set should still be absent
      Assert (not Store.Contains ("never_set"),
              "Contains returns False for never-set key");
   end Test_Null_Value_Contains;

   ---------------------------------------------------------------------------
   --  Test: Default backend (Initialize with null)
   ---------------------------------------------------------------------------

   procedure Test_Default_Backend is
      Store : Settings_Store;
   begin
      Put_Line ("-- Default Backend Tests --");

      --  Initialize with no backend argument (defaults to null -> JSON)
      Store.Initialize ("test_org", "test_app");

      --  Store should work without explicit backend
      Store.Set ("key", "value");
      Assert (Store.Get_String ("key") = "value",
              "Default backend: set/get works");
      Assert (Store.Contains ("key"),
              "Default backend: contains works");
   end Test_Default_Backend;

   ---------------------------------------------------------------------------
   --  Test: Long JSON lines (>4096 chars)
   ---------------------------------------------------------------------------

   procedure Test_Long_Lines is
   begin
      Put_Line ("-- Long Line Tests --");

      declare
         B    : aliased JSON_Settings_Backend;
         Path : constant String := Tmp_Dir & "settings.json";
         Data : Setting_Value := Empty_Map;
         Long : constant String (1 .. 8000) := [others => 'x'];
      begin
         Ensure_Tmp_Dir;

         Insert (Data, "long_value", To_Value (Long));

         B.Save (Path, Data);

         declare
            Loaded : constant Setting_Value := B.Load (Path);
         begin
            Assert (Kind (Loaded) = Map_Kind,
                    "Long line: loaded as map");
            Assert (As_String (Get (Loaded, "long_value"))'Length = 8000,
                    "Long line: value length preserved");
            Assert (As_String (Get (Loaded, "long_value")) = Long,
                    "Long line: value content preserved");
         end;
      end;
   end Test_Long_Lines;

begin
   Put_Line ("=== Adi.Settings Test Suite ===");
   Put_Line ("");

   Test_Scalar_Values;
   Test_Wrong_Kind;
   Test_List;
   Test_Map;
   Test_Deep_Copy;
   Test_Store_Basic;
   Test_Dot_Paths;
   Test_Escaped_Dots;
   Test_JSON_Round_Trip;
   Test_Special_Chars;
   Test_Missing_File;
   Test_Save_Failure_Raises;
   Test_Empty_Store;
   Test_Nested_Structures;
   Test_Null_Value_Contains;
   Test_Default_Backend;
   Test_Long_Lines;

   --  Cleanup temp files
   Cleanup;

   Put_Line ("");
   Put_Line ("Results:" & Natural'Image (Passed) & " passed," &
             Natural'Image (Failed) & " failed out of" &
             Natural'Image (Passed + Failed) & " tests.");

   if Failed > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Settings_Test;
