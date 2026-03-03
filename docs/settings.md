# Program Settings (`Adi.Settings`)

`Adi.Settings` provides persistent key-value storage for application settings. Settings are stored as a recursive value tree (scalars, lists, maps) with dot-path keys, backed by JSON files on disk. Memory management is automatic via controlled types.

## Quick Start

```ada
with Adi.Settings; use Adi.Settings;

procedure My_App is
   Config : Settings_Store;
begin
   Config.Initialize (Org => "MyCompany", App => "MyApp");
   Config.Load;  --  Load from disk (no-op if file missing)

   --  Read with defaults
   Width  := Config.Get_Integer ("window.width", Default => 800);
   Theme  := Config.Get_String  ("ui.theme", Default => "light");

   --  Write
   Config.Set ("window.width", Long_Integer (1024));
   Config.Set ("ui.theme", "dark");

   Config.Save;  --  Persist to disk
end My_App;
```

Settings file location: `Pref_Path(Org, App) & "settings.json"` (see `Adi.OS.Pref_Path`). On Linux this is typically `~/.local/share/Org/App/settings.json`.

## Setting_Value

`Setting_Value` is a managed recursive variant type. Assignment produces independent deep copies; scope exit frees the entire tree automatically (controlled semantics).

### Value Kinds

| Kind | Constructor | Extractor |
|------|-------------|-----------|
| `Null_Kind` | `Null_Value` | (check with `Kind`) |
| `String_Kind` | `To_Value ("text")` | `As_String (V)` |
| `Integer_Kind` | `To_Value (Long_Integer (42))` | `As_Integer (V)` |
| `Float_Kind` | `To_Value (Long_Float (3.14))` | `As_Float (V)` |
| `Boolean_Kind` | `To_Value (True)` | `As_Boolean (V)` |
| `List_Kind` | `Empty_List` | `Length`, `Element` |
| `Map_Kind` | `Empty_Map` | `Contains`, `Get`, `Keys` |

Extractors raise `Constraint_Error` if called on a value of the wrong kind.

### List Operations

```ada
L : Setting_Value := Empty_List;
Append (L, To_Value ("first"));
Append (L, To_Value (Long_Integer (2)));

N : Natural       := Length (L);       --  2
V : Setting_Value := Element (L, 1);   --  "first"
```

### Map Operations

```ada
M : Setting_Value := Empty_Map;
Insert (M, "name", To_Value ("Adi"));
Insert (M, "version", To_Value (Long_Integer (2)));

B : Boolean       := Contains (M, "name");  --  True
V : Setting_Value := Get (M, "name");       --  "Adi"
K : Key_Array     := Keys (M);              --  sorted keys
```

`Insert` replaces the value if the key already exists. `Get` returns `Null_Value` for missing keys. `Keys` returns keys in sorted (ascending) order.

### Deep Copy Semantics

```ada
A : Setting_Value := To_Value ("original");
B : Setting_Value := A;   --  independent deep copy
B := To_Value ("changed");
--  As_String (A) is still "original"
```

This applies to all kinds, including nested lists and maps.

## Settings_Store

`Settings_Store` is a typed wrapper around a `Setting_Value` map root, with dot-path key navigation and a pluggable persistence backend.

### Initialization

```ada
Store : Settings_Store;

--  Default JSON backend (allocated and owned by the store):
Store.Initialize (Org => "MyCompany", App => "MyApp");

--  Explicit backend (caller must keep backend alive):
B : aliased JSON_Settings_Backend;
Store.Initialize ("MyCompany", "MyApp", Backend => B'Unchecked_Access);
```

When `Backend` is null (the default), the store allocates a `JSON_Settings_Backend` internally and frees it when the store goes out of scope.

### Load and Save

```ada
Store.Load;   --  Read settings.json into memory
Store.Save;   --  Write memory to settings.json
```

`Load` replaces all in-memory settings. If the file does not exist or cannot be parsed, the store starts with an empty map. `Save` writes atomically (temp file + rename, with direct-write fallback).

Both raise `Program_Error` if called before `Initialize`.

### Typed Getters

All getters accept a `Default` parameter returned when the key is missing or has a different type:

```ada
function Get_String  (Store; Key; Default : String := "")          return String;
function Get_Integer (Store; Key; Default : Long_Integer := 0)     return Long_Integer;
function Get_Float   (Store; Key; Default : Long_Float := 0.0)     return Long_Float;
function Get_Boolean (Store; Key; Default : Boolean := False)      return Boolean;
function Get         (Store; Key)                                  return Setting_Value;
function Contains    (Store; Key)                                  return Boolean;
```

`Contains` returns `True` if a key exists in the store, even if its value is `Null_Kind`.

### Typed Setters

```ada
Store.Set ("name", "Adi");
Store.Set ("count", Long_Integer (42));
Store.Set ("scale", Long_Float (1.5));
Store.Set ("visible", True);
Store.Set ("complex", some_setting_value);
```

### Remove and Clear

```ada
Store.Remove ("window.title");  --  Remove one key (no-op if missing)
Store.Clear;                    --  Remove all settings
```

### Query

```ada
Store.Is_Loaded  --  True after a successful Load
Store.File_Path  --  Full path to the settings file
```

## Dot-Path Keys

The `.` character is the path separator for nested maps. Setting a dot-path key auto-creates intermediate maps:

```ada
Store.Set ("window.width", Long_Integer (800));
--  Equivalent to: root["window"]["width"] = 800
--  Creates the "window" map if it doesn't exist.
```

### Escaping Literal Dots

Use `\.` to include a literal dot in a key segment:

```ada
Store.Set ("app\.version", "1.0");
--  Stores key "app.version" (single segment, no nesting)

Store.Set ("meta.app\.name", "MyApp");
--  Segments: ["meta", "app.name"]
```

## JSON Backend

`Adi.Settings.JSON_Backend` is the default (and currently only) backend. It serializes the setting tree as pretty-printed JSON via `Adi.JSON.JSON_Writer` and reads it back via `Adi.JSON.Parsers`.

### Type Mapping

| Setting_Value Kind | JSON |
|-------------------|------|
| `Null_Kind` | `null` |
| `String_Kind` | `"string"` |
| `Integer_Kind` | `123` |
| `Float_Kind` | `1.5` |
| `Boolean_Kind` | `true` / `false` |
| `List_Kind` | `[...]` |
| `Map_Kind` | `{...}` |

### Example Output

```json
{
  "ui": {
    "theme": "dark",
    "scale": 1.5
  },
  "window": {
    "fullscreen": false,
    "height": 600,
    "width": 800
  }
}
```

Map keys are written in sorted order (from `Indefinite_Ordered_Maps`).

### Convenience Constructor

```ada
with Adi.Settings.JSON_Backend; use Adi.Settings.JSON_Backend;

Store : Settings_Store;
Create_With_JSON_Backend (Store, "MyCompany", "MyApp");
```

This is equivalent to `Store.Initialize ("MyCompany", "MyApp")` — both create and own a JSON backend.

## Custom Backends

Extend `Settings_Backend` to implement alternative storage formats (TOML, binary, database, etc.):

```ada
type My_Backend is new Settings_Backend with null record;

overriding function Load
  (B : My_Backend; Path : String) return Setting_Value;

overriding procedure Save
  (B : My_Backend; Path : String; Data : Setting_Value);
```

`Load` receives the file path and returns a `Map_Kind` value (or `Null_Value` if the file is missing). `Save` receives the file path and the root map to persist.

Pass the backend to `Initialize`:

```ada
B : aliased My_Backend;
Store.Initialize ("Org", "App", Backend => B'Unchecked_Access);
```

When providing an explicit backend, the caller owns it and must ensure it outlives the store. The store does not free caller-provided backends.

## Files

| File | Description |
|------|-------------|
| `src/adi-settings.ads` | `Setting_Value`, `Settings_Backend`, `Settings_Store` |
| `src/adi-settings.adb` | Node tree, controlled ops, dot-path parsing, store logic |
| `src/adi-settings-json_backend.ads` | `JSON_Settings_Backend` type |
| `src/adi-settings-json_backend.adb` | JSON load/save, atomic file I/O |
| `tests/src/settings_test.adb` | Test suite (86 tests) |

## JSON Writer (`Adi.JSON`)

The settings backend uses `Adi.JSON.JSON_Writer`, a streaming JSON builder also used by the MCP module. Key features:

- **Automatic comma tracking** between elements (no manual separator management)
- **Pretty-printing** with 2-space indentation (`Create (Pretty => True)`)
- **UTF-8 safe escaping** via `Escape_String` (only escapes `"`, `\`, and control chars 0x00-0x1F; bytes >= 0x80 pass through verbatim)
- **Structure validation** via depth tracking (max 64 levels)

`Adi.JSON.JSON_Writer` and `Adi.JSON.Escape_String` are public and available for use outside of settings.
