# Static Asset Bundling

Adi supports embedding assets (images, fonts, SVG sprites, CSS, text) directly
into the executable as byte arrays, eliminating filesystem I/O dependencies
at runtime.

## Resolution Modes

The app chooses one resolution strategy at startup via `Adi.Assets.Set_Mode`:

- **`File_Mode`** (default) — resolve via registered search directories
  (`Add_Path`). This is the existing behavior.
- **`Bundle_Mode`** — resolve exclusively from the in-memory bundle registry.
  The filesystem is never consulted.

Modes are **exclusive**: in `Bundle_Mode`, `Add_Path` directories are ignored;
in `File_Mode`, bundle entries are ignored.

### Mode immutability

`Set_Mode` must be called **before any asset is loaded** (`Get_Image`,
`Get_String`, `Get_Animated_Image`, or `Font.Load_Asset`). Calling it after
any cache is populated raises `Program_Error`. The sequence is always:

```ada
Register_All;                            --  from generated bundle package
Adi.Assets.Set_Mode (Bundle_Mode);       --  switch to bundle mode
--  ... now load assets normally ...
```

## Bundle Registration

Register embedded data with `Adi.Assets.Register`:

```ada
Adi.Assets.Register ("icons.svg", Data'Address, Data'Length);
```

- `Data` must point to static-lifetime memory (e.g. library-level
  `Storage_Array` constant). Data is **not copied**.
- Keys are **exact strings** — no normalization, no case folding.
- Plain relative paths (`icons.svg`) and scheme URIs (`app://icons.svg`)
  are both supported.
- Lookup matches the **base path before `?`** as extracted by `Split_Query`.
  For example, `Get_Image("icons.svg?id=home")` looks up `"icons.svg"`.

## Code Generator

`tools/binary_to_ada.py` converts files into Ada `Storage_Array` constants:

```bash
python3 tools/binary_to_ada.py \
  --output-dir examples/generated/ \
  --package-name Assets_Example_Bundle \
  --base-dir examples/assets/ \
  examples/assets/icons.svg examples/assets/happycat.png
```

`--base-dir` strips the directory prefix so registered paths are clean
relative paths (e.g. `icons.svg` instead of `examples/assets/icons.svg`).

The generated package exposes a single `Register_All` procedure. Constants are
placed in the package **body** to avoid recompilation churn — body-level
constants still have static (program) lifetime in Ada.

## Memory-Based Font Loading

`Adi.Font.Load_From_Memory` registers a font from in-memory data:

```ada
H := Adi.Font.Load_From_Memory (Data'Address, Data'Length);
```

**Lifetime requirement**: The backing memory must outlive all font instances
because `TTF_OpenFontIO` reads glyphs on demand. Library-level
`Storage_Array` constants have program lifetime — this is always safe.

Each sized font instance gets its own IO stream via `SDL_IOFromConstMem`,
and `closeio=True` means SDL closes the stream struct when `TTF_CloseFont`
is called (does NOT free the backing `Storage_Array`).

`Font.Load_Asset` automatically uses `Load_From_Memory` when in `Bundle_Mode`.

### Default font override

`Adi.Font.Set_Default_Font` replaces the automatic system font fallback
(DejaVu Sans, Noto Sans, etc.) with a specific handle. All widgets that
do not set `font-family` will use this font.

```ada
Adi.Font.Set_Default_Font
  (Adi.Font.Load_Asset ("OpenSans-Regular.ttf"));
```

Note: Adi does not cascade `font-family` from parent to child widgets.
Setting `font-family` on a container only affects that container's own
text parts — child widgets still use the default. Use `Set_Default_Font`
to set the app-wide font.

## Build Integration

### With Alire

The `alire.toml` post-build action runs `tools/generate_example_bundles.sh`
automatically. Generated files go to `examples/generated/` which is already
in the `Source_Dirs`.

### Without Alire (direct gprbuild)

Run the generation scripts manually before building:

```bash
bash tools/generate_example_styles.sh
bash tools/generate_example_ui.sh
bash tools/generate_example_bundles.sh
gprbuild -j0 -P examples/examples.gpr -XEXAMPLE_KIND=assets_example
```

## Example Usage

```ada
with Adi.App;
with Adi.Assets;
with Adi.Font;
with Assets_Example_Bundle;

procedure My_App is
   A : Adi.App.App;
begin
   A.Init;
   Assets_Example_Bundle.Register_All;
   Adi.Assets.Set_Mode (Adi.Assets.Bundle_Mode);

   --  Load bundled font and set as app default
   Adi.Font.Set_Default_Font
     (Adi.Font.Load_Asset ("OpenSans-Regular.ttf"));

   --  Now Get_Image("icons.svg?id=home") works from embedded data
   --  and all text renders with the bundled font
end My_App;
```

## API Reference

### `Adi.Assets`

| Declaration | Description |
|------------|-------------|
| `type Asset_Mode is (File_Mode, Bundle_Mode)` | Resolution strategy |
| `procedure Set_Mode (Mode : Asset_Mode)` | Switch mode (before any load) |
| `function Get_Mode return Asset_Mode` | Query current mode |
| `type Asset_Data` | Record with `Addr` and `Length` |
| `Null_Asset : constant Asset_Data` | Empty/not-found sentinel |
| `procedure Register (Path, Addr, Length)` | Register bundle entry |
| `function Bundle_Lookup (Path) return Asset_Data` | Look up entry |

### `Adi.Image`

| Declaration | Description |
|------------|-------------|
| `function Load_From_Memory (Data, Length) return Image_Owner` | Load raster image from memory |

### `Adi.Animated_Image`

| Declaration | Description |
|------------|-------------|
| `function Load_From_Memory (Data, Length) return Adi.Animated_Image.Animation_Handle` | Load animated image from memory |

### `Adi.Font`

| Declaration | Description |
|------------|-------------|
| `function Load_From_Memory (Data, Length, Name) return Font_Handle` | Register font from memory |
| `procedure Set_Default_Font (Handle)` | Override system fallback font |

### `Adi.SDL.IO`

| Declaration | Description |
|------------|-------------|
| `function SDL_IOFromConstMem (Mem, Size) return SDL_IOStream_Ptr` | Create IO stream from const memory |
| `function SDL_CloseIO (Context) return C_bool` | Close IO stream |
