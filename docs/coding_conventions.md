# Coding Conventions

## Ada Standards
- **Ada 2022** with GNAT extensions (`-gnat2022 -gnatX0`)
- Library uses `-gnatef` for full error paths
- Tests use `-g -gnatwa -gnata` (debug, all warnings, assertions)

## Naming Patterns
- Types: `Widget`, `Rectangle`, `Color_Value`
- Access types: `Widget_Access`, `Window_Access`
- Functions returning accessors: `Create`, `Get_*`
- Procedures for mutation: `Set_*`, `Add_*`, `Remove_*`

## Package Hierarchy
All packages rooted under `Adi`. Core types in `Adi.Core`, styles in `Adi.Style`/`Adi.CSS_Styles`/`Adi.Widget_Styles`, widgets in `Adi.Widget.*`, SDL bindings in `Adi.SDL.*`.

## Logging
- Use `Adi.Log` for runtime diagnostics (`Debug`, `Info`, `Warning`, `Error`).
- Do not call `Ada.Text_IO.Put_Line` directly from library runtime paths.
- Rationale: `Adi.Log` is a no-op in release/validation builds, and on Windows development builds it redirects to `debug.log` (no console handle available in GUI apps).

## Widget API Conventions

### Hierarchy calls use `access Widget'Class`
`Add_Child`, `Remove_Child`, `Set_Root`, `Add_Overlay`, `Remove_Overlay`, `Add_Page` accept anonymous access — no `Widget_Access(...)` casts at call sites.

### Dot notation
```ada
Root.Add_Child (Label1);  -- not Add_Child (Root.all, Widget_Access (Label1))
```

### Internal storage conversion
When converting anonymous access params to stored `Widget_Access`, use `C.all'Unchecked_Access` (not `Widget_Access(C)`) to avoid runtime accessibility `PROGRAM_ERROR`.

### Callbacks use named access types
e.g. `Click_Callback`, `Toggle_Callback` — Ada accessibility rules (RM 3.10.2) prevent anonymous access-to-subprogram in record fields. Examples use `'Unrestricted_Access` (GNAT extension) for callbacks declared inside `main`.

## Project Structure

```
src/adi-*.ads/adb         - Library modules (Ada package naming)
src/adi-widget-*.ads/adb  - Widget implementations
src/adi-sdl-*.ads/adb     - SDL3 bindings
tests/src/                - Test programs
examples/                 - Example programs
examples/css/             - CSS source files
examples/generated/       - Auto-generated Ada style packages
tools/                    - Build/generation scripts
config/                   - Build config (posix/ and windows/ variants)
```
