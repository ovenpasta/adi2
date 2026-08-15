# CLAUDE.md

## Project Overview

Adi is a GUI library in Ada 2022 using SDL3 for windowing/rendering and SDL3_ttf for text. It provides a widget-based UI framework with CSS-like styling, declarative XML UI generation, and runtime CSS live-reload.

## Read the Docs First

Before making changes, read the relevant documentation. Do not guess at APIs or conventions — the docs are authoritative.

| Topic | File |
|-------|------|
| First application, from an empty directory | `docs/getting_started.md` |
| Architecture & core components | `docs/architecture.md` |
| Handle ownership model (stores, handles, borrow, lifecycle) | `docs/handle_ownership.md` |
| Coding conventions | `docs/coding_conventions.md` |
| CSS styling (selectors, properties, runtime API, code generation) | `docs/css_styling.md` |
| XML UI system (declarative widgets, code generation, components) | `docs/xml_ui_system.md` |
| Internal style-storage optimization (interning/prepared rules/global memo) | `docs/style_storage_optimization.md` |
| Build system (Alire, gprbuild, configure) | `docs/build.md` |
| gprbuild without Alire | `docs/gprbuild_without_alire.md` |
| MCP runtime introspection | `docs/mcp.md` |
| HTML view widget | `docs/html_view_spec.md` |
| Adding a new CSS property | `docs/adding_css_property.md` |
| Adding a new example | `docs/adding_example.md` |
| Adding a new test | `docs/adding_test.md` |
| Antialiased rendering (AA fringe, ring patterns) | `docs/rendering_aa.md` |
| OS integration (dialogs, paths, clipboard) | `docs/os_integration.md` |
| Static asset bundling | `docs/static_assets.md` |
| Signals and deferred dispatch | `docs/signals.md` |
| Internationalization (i18n, translations, .po files, plural forms) | `docs/i18n.md` |
| Program settings (Setting_Value, Settings_Store, JSON backend) | `docs/settings.md` |
| WebAssembly port (build, toolchain, JSPI, example status) | `wasm/README.md`, `wasm/PORT_REPORT.md`, `wasm/FINDINGS.md` |
| Finalization ordering issue (Window vs. widget tagged-type packages) and structural fix options | `docs/finalization_ordering.md` |
| Ada 2022 Reference Manual | `rm-22-txt/RM-TOC.TXT` (chapters: `rm-22-txt/RM-*.TXT`) — local-only, gitignored; if absent, fetch the plain-text RM into `rm-22-txt/` |

## Build Commands

> ⚠️ Build safety: never run more than one `gprbuild` command at the same time in this repo. Concurrent `gprbuild` processes can race on shared artifacts and produce truncated/corrupted archives.

```bash
# Build the library only (tests and examples are NOT built here)
alr build -- -j0

# Build + run the whole test suite (Ada + Python); also the alr test action
tools/run_tests.sh

# Build a specific test
alr exec -- gprbuild -j0 -P tests/tests.gpr -XTEST_KIND=css_parser_test

# Build examples (regenerates their generated sources first)
tools/build_examples.sh stack_example

# Build a specific example directly (generated sources must be current)
alr exec -- gprbuild -j0 -P examples/examples.gpr -XEXAMPLE_KIND=stack_example

# Run Ada tests (built to tests/bin/)
./tests/bin/styles
./tests/bin/layout_test
./tests/bin/css_parser_test
./tests/bin/css_source_test
./tests/bin/text_buffer_test
./tests/bin/text_layout_test
./tests/bin/html_view_test
./tests/bin/disabled_test
./tests/bin/image_widget_test
./tests/bin/mcp_test
./tests/bin/bundle_test
./tests/bin/settings_test
./tests/bin/close_request_test
./tests/bin/text_editor_test
./tests/bin/dialog_test
./tests/bin/font_test
./tests/bin/scroll_primitives_test
./tests/bin/handle_store_test
./tests/bin/label_wrap_test
./tests/bin/clock_test
./tests/bin/texture_cache_test
./tests/bin/render_textures_test

# Run Python tests (no build step needed)
python3 tools/test_css_to_ada.py
python3 tools/test_xml_to_ada.py
python3 tools/test_adi_mcp.py
python3 tools/test_binary_to_ada.py
python3 tools/test_po_to_ada.py
```

For direct gprbuild (no Alire), see `docs/gprbuild_without_alire.md` and `docs/build.md`.

## Code Generation Pipelines

### CSS → Ada (`tools/css_to_ada.py`)

```bash
python3 tools/css_to_ada.py input.css output.ads --package-name=My_Styles
```

Writes a companion `output.adb` beside the spec, holding the stylesheet's
`Register_Selectors` procedure.

Incremental build for all examples: `tools/generate_example_styles.sh`. Full reference in `docs/css_styling.md`.

### XML → Ada (`tools/xml_to_ada.py`)

```bash
python3 tools/xml_to_ada.py input.xml --output-dir out/ --package-name My_UI
```

Incremental build for examples: `tools/generate_example_ui.sh`. Full reference in `docs/xml_ui_system.md`.

Widget grammar is defined in `tools/widgets.xml` (13 widget types). Extensible via `--grammar`.

### Binary → Ada (`tools/binary_to_ada.py`)

```bash
python3 tools/binary_to_ada.py \
  --output-dir examples/generated/ \
  --package-name Assets_Example_Bundle \
  --base-dir examples/assets/ \
  examples/assets/icons.svg examples/assets/happycat.png
```

Incremental build for examples: `tools/generate_example_bundles.sh`. Full reference in `docs/static_assets.md`.

## Key Architecture Points

- **Ada 2022** with GNAT extensions (`-gnat2022 -gnatX0`)
- All packages rooted under `Adi`
- **Item record** is flattened (no discriminant variant); `Kind` distinguishes usage
- **Build_Items convention**: create items once (when vector is empty), update in-place on subsequent calls
- **Font system**: `Font_Handle` = font family. Sized `TTF_Font` instances cached per `(handle, size)` pair. Never call `TTF_SetFontSize` on shared fonts.
- **TTF_Text caching**: stored in `Item.Cached_TTF_Text`, created on first render, updated via `TTF_SetTextString`
- **Style_Rules** carries optional/unset values for CSS cascade; **Resolved_Style** is fully concrete
- **Widget_Style** fluent builder: `From(base).On(When_State(...), style).Build`
- **Hierarchy calls** use `access Widget'Class` (no `Widget_Access` cast needed at call sites)
- **Callbacks** use named access types; `'Unrestricted_Access` required for local subprograms

## Common Pitfalls

- `C_bool` ambiguity: both `Adi.SDL` and `Interfaces.C` define it. Qualify as `Adi.SDL.C_bool`.
- `Indefinite_Vectors` vs `Vectors`: only needed for discriminated types without defaults. Item is flattened, so use regular Vectors.
- SDL3_ttf font sharing: each `TTF_Font` is at a specific size. Changing size invalidates all `TTF_Text` objects. Use separate instances per size.
- Generic access types: local generic instantiation creates local access types. Convert via intermediate `access Widget'Class` variable with `'Unchecked_Access`, then cast to `Widget_Access`.
- `others` not allowed in delta aggregates: use `[for I in T => I = X]` pattern.

## CSS Quick Reference

- Selectors: `.class`, `#id`, `tag`; part selectors `::main`, `::label`, `::icon`, `::cursor`, `::selected`, `::indicator`, `::scroll`, `::knob`, `::items`
- Pseudo-classes: `:hover`, `:pressed`/`:active`, `:focus`, `:disabled`, `:checked`/`:selected`, `:not()`
- Pseudo placement: before `::part` = widget-scoped; after `::part` = part-scoped
- Runtime: `Adi.CSS_Source` (Dynamic_Mode for dev live-reload, Static_Mode for release)
- Full property list and details in `docs/css_styling.md`

## SDL Bindings

When adding new SDL API bindings (new functions, new subsystems), follow this workflow:

1. **Check `bindings/` first** — it contains 80+ auto-generated Ada bindings from SDL3/SDL3_ttf/SDL3_image C headers. These are the reference for function signatures, types, and constants.
2. **Do not use the auto-generated bindings directly** — they have complex dependency chains (`stddef_h`, `SDL3_SDL_stdinc_h`, etc.) and raw C types.
3. **Create or extend hand-crafted bindings in `src/adi-sdl*.ads`** — scan the relevant auto-generated file in `bindings/` for the function signature, then write a clean Ada binding in the appropriate `Adi.SDL.*` child package.
4. **Follow the established binding pattern** documented in `docs/sdl_bindings.md`:
   - Use native Ada types from `Adi.SDL` (`Uint8`, `Uint32`, `C_bool`, `int`, `Float`)
   - Use incomplete types for opaque structures: `type T is limited null record;`
   - Use Ada enumerations with `Convention => C` for C enums
   - Use constants with `new Uint32` for bitflags
   - No dependencies on auto-generated bindings

Existing hand-crafted binding modules:

| Module | File | Covers |
|--------|------|--------|
| `Adi.SDL` | `adi-sdl.ads` | Core types, init, clipboard |
| `Adi.SDL.Video` | `adi-sdl-video.ads` | Window management |
| `Adi.SDL.Render` | `adi-sdl-render.ads` | 2D rendering, textures |
| `Adi.SDL.TTF` | `adi-sdl-ttf.ads` | Font loading, text rendering |
| `Adi.SDL.TTF.TextEngine` | `adi-sdl-ttf-textengine.ads` | Advanced text layout |
| `Adi.SDL.Events` | `adi-sdl-events.ads` | Event handling, scancodes |
| `Adi.SDL.Mouse` | `adi-sdl-mouse.ads` | Mouse state, cursors |
| `Adi.SDL.Surface` | `adi-sdl-surface.ads` | Pixel buffers |
| `Adi.SDL.PixelFormat` | `adi-sdl-pixelformat.ads` | Pixel format constants |
| `Adi.SDL.IO` | `adi-sdl-io.ads` | IO streams (memory) |
| `Adi.SDL.Image` | `adi-sdl-image.ads` | Image file loading |

## Code Navigation (ALS)

An Ada Language Server is available via MCP (`ada-ls`). **Prefer it over grep for semantic queries** — finding definitions, references, and type info.

| Tool | Use instead of |
|------|---------------|
| `goto_definition(file, line, column)` | Grepping for `procedure Foo` / `type Bar` |
| `find_references(file, line, column)` | Grepping for a symbol name |
| `document_symbols(file)` | Reading a whole file to find declarations |
| `hover(file, line, column)` | Guessing a symbol's type or signature |

Coordinates are **1-based**. Still use grep/glob for pattern matching (string literals, CSS class names, comments).

## Git (MCP)

A Git MCP server is available (`git`). **Use MCP git tools for git commands whenever an MCP equivalent exists** — status, diff, log, add, commit, branch, checkout, show.

| Tool | Use instead of |
|------|---------------|
| `git_status(repo_path)` | `git status` |
| `git_diff_unstaged(repo_path)` | `git diff` |
| `git_diff_staged(repo_path)` | `git diff --cached` |
| `git_diff(repo_path, target)` | `git diff <target>` |
| `git_log(repo_path)` | `git log` |
| `git_add(repo_path, files)` | `git add` |
| `git_commit(repo_path, message)` | `git commit` |
| `git_show(repo_path, revision)` | `git show` |
| `git_create_branch(repo_path, branch_name)` | `git checkout -b` |
| `git_checkout(repo_path, branch_name)` | `git checkout` |
| `git_branch(repo_path, branch_type)` | `git branch` |

`repo_path` is always `/src/ada/adi2`. Use shell git only for operations not covered by MCP (push, rebase, stash, etc.).

## Filesystem (MCP)

A Filesystem MCP server is available (`filesystem`). Priority order: **built-in tools first** (Read, Write, Edit, Glob, Grep), then **MCP filesystem** for operations not covered by built-ins, then **shell commands** as last resort.

Use MCP filesystem for operations that built-in tools cannot do:

| Tool | Use instead of |
|------|---------------|
| `read_multiple_files(paths)` | Multiple sequential Read calls |
| `read_media_file(path)` | Reading binary/image files via shell |
| `list_directory(path)` | `ls` |
| `list_directory_with_sizes(path)` | `ls -l` |
| `directory_tree(path)` | `find`, `tree` |
| `create_directory(path)` | `mkdir -p` |
| `move_file(source, destination)` | `mv` |
| `get_file_info(path)` | `stat` |

Paths must be absolute (e.g., `/src/ada/adi2/src/adi-widget.ads`).

## Adi Runtime Introspection (MCP)

An Adi MCP server is available (`adi`) for inspecting a **running** Adi application. Requires the app to call `Adi.MCP.Initialize` (development builds only — release builds get a no-op stub).

| Tool | Description |
|------|-------------|
| `screenshot()` | Capture PNG screenshot, returns file path |
| `widget_tree()` | Full widget hierarchy as JSON (type, path, bounds, states, flags, children) |
| `widget_info(path)` | Detailed info for one widget by dot-path (e.g. `"1.2.3"`) |
| `perf_stats()` | Frame timing, FPS, layout counts |

Communication uses file-based IPC via `/tmp/adi_mcp/<PID>/`. Each request carries a unique `req_id` for correlation. See `docs/mcp.md` for setup and usage.

## Project Structure

```
src/                  Main library (adi-*.ads/adb)
src/mcp/              MCP introspection (development builds only)
src/mcp_stub/         MCP no-op stubs (release/validation builds)
bindings/             Auto-generated SDL3 bindings (reference only, do not use directly)
tests/src/            Test programs (built to tests/bin/)
examples/             Example programs (built to examples/bin/)
examples/css/         CSS source files
examples/xml/         XML UI definitions
examples/generated/   Auto-generated Ada from CSS and XML
tools/                Code generators, MCP servers, and build scripts
docs/                 Reference documentation
```

## Testing

- Always write tests for new functionality when feasible, covering all corner cases
- Never fix or weaken a test to accommodate a missing or incorrect implementation — ask for clarification on how to proceed instead

## Git Conventions

- Never add co-authored-by line on commit messages
- Always provide both a short subject line and a brief multi-line body describing what changed and why
