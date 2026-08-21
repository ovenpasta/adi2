# Coding Conventions

## Ada Standards
- **Ada 2022** with GNAT extensions (`-gnat2022 -gnatX0`)
- Library uses `-gnatef` for full error paths
- Tests use `-g -gnatwa -gnata` (debug, all warnings, assertions)

## Naming Patterns
- Types: `Widget`, `Rectangle`, `Color_Value`
- Handle types: `Widget_Handle`, `Label_Handle`, `Image_Handle` — what callers hold
- Access types: `Widget_Access` — internal, private where the design allows
- Constructors: `Create_Handle`, returning the widget's typed handle. No constructor returns an access type; `Adi.Image`'s return an `Image_Owner`
- Functions for queries: `Get_*`, `Is_*`
- Procedures for mutation: `Set_*`, `Add_*`, `Remove_*`

## Package Hierarchy
All packages rooted under `Adi`. Core types in `Adi.Core`, styles in `Adi.CSS_Styles`/`Adi.Widget_Styles`, widgets in `Adi.Widget.*`, SDL bindings in `Adi.SDL.*`.

## Logging
- Use `Adi.Log` for runtime diagnostics (`Debug`, `Info`, `Warning`, `Error`).
- Do not call `Ada.Text_IO.Put_Line` directly from library runtime paths.
- Rationale: `Adi.Log` is a no-op in release/validation builds, and on Windows development builds it redirects to `debug.log` (no console handle available in GUI apps).

## Widget API Conventions

### Hierarchy calls take handles
`Add_Child`, `Remove_Child`, `Set_Root`, `Add_Overlay`, `Remove_Overlay` and
`Add_Page` take `Widget_Handle`. `"+"` widens a typed handle to it, so no
cast appears at a call site:

```ada
Adi.Widget.Box.Add_Child (Root, +Label1);
```

The `access Widget'Class` overloads remain for use inside the widget
bodies; new call sites use the handle form.

### Internal storage conversion
When converting anonymous access params to stored `Widget_Access`, use `C.all'Unchecked_Access` (not `Widget_Access(C)`) to avoid runtime accessibility `PROGRAM_ERROR`.

### Callbacks use named access types
e.g. `Click_Callback`, `Toggle_Callback` — Ada accessibility rules (RM 3.10.2) prevent anonymous access-to-subprogram in record fields. Examples use `'Unrestricted_Access` (GNAT extension) for callbacks declared inside `main`.

## Project Structure

```
src/adi-*.ads/adb         - Library modules (Ada package naming)
src/adi-widget-*.ads/adb  - Widget implementations
src/adi-sdl-*.ads/adb     - SDL3 bindings
src/svg/                  - SVG API and its backend
src/mcp/, src/mcp_stub/   - MCP bridge; the stub replaces it outside development
tests/src/                - Test programs
examples/                 - Example programs
examples/css/             - CSS source files
examples/xml/             - Declarative UI definitions
examples/generated/       - Ada generated from css/ and xml/
tools/                    - Build/generation scripts
config/                   - Build config (posix/, windows/, darwin/ and build profiles)
```
