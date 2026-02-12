# CSS Styling System

## Style Generation

```bash
python tools/css_to_ada.py input.css output.ads --package-name=My_Styles
```

Example styles generated incrementally via `tools/generate_example_styles.sh`.

### Selector Conventions
- `.widget` applies to `Main_Part`
- `.widget::label`, `::cursor`, `::selected`, etc. target specific parts
- Generated constants: `*_Class_Part_Styles`, `*_Id_Part_Styles`, `*_Tag_Part_Styles`

### State Pseudo-class Placement
- Before `::part` => widget-scoped state: `.list:hover::scroll`
- After `::part` => part-scoped state: `.list::scroll:hover`, `.list::knob:pressed`
- For `::main`, interactive pseudos remain widget-scoped: `.button::main:hover`

## Runtime CSS Parser (`Adi.CSS_Parser`)

Loads stylesheets from strings/files with optional file-change reload.

Selector API pattern: `Has/Styles_For/Apply/Bind` + `_Class`/`_Id`/`_Tag` variants, or generic with `Selector_Kind`.

File reload: `Reload_If_Changed` reapplies to bound widgets.

## CSS Source (`Adi.CSS_Source`)

Higher-level entry point unifying dev-time and release-time styling.

- `Dynamic_Mode`: load from disk (`Set_Dynamic_File`), optional auto-reload with `Tick`
- `Static_Mode`: compiled entries (`Set_Static_Entries`) from `css_to_ada.py`
- Single selector: `Bind_Class`, `Bind_Id`, `Bind_Tag`
- Composite selector: `Bind_Selector_Set` / `Apply_Selector_Set` with CSS specificity (tag < class < id)

## Supported CSS Properties

- **Box model**: width, height, min/max-width/height, padding, margin (+ individual sides)
- **Borders**: border, border-width/color/style, border-radius
- **Colors**: color, background-color (named, hex, rgb, rgba)
- **Typography**: font-size, font-weight, font-style, text-align, vertical-align, text-decoration, line-height, white-space, text-overflow, text-wrap-mode
- **Layout**: display, position, overflow, visibility, opacity
- **Flexbox**: flex-direction/wrap, justify-content, align-items/self/content, gap, flex-grow/shrink/basis, order
- **Grid**: grid-template-columns/rows, grid-column/row
- **Effects**: box-shadow (offset, blur, spread, color), cursor
- **Images**: object-fit, object-position
- **Transitions**: transition (duration, easing, property filter)

### Box Shadow Syntax
Standard CSS: `box-shadow: 2px 4px 10px rgba(0, 0, 0, 0.25);`
With spread: `box-shadow: 0 8px 16px 0 rgba(0, 0, 0, 0.15);`
Disable: `box-shadow: none;`
