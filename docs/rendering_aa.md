# Antialiased Rendering

Adi renders rounded shapes using triangle-based geometry submitted to SDL's `SDL_RenderGeometry`. This document describes the antialiasing technique, how border and outline rings are drawn, and how to avoid common artifacts.

---

## Core Primitives

All rounded rendering in `src/adi-widget.adb` is built from three procedures:

| Procedure | Purpose |
|-----------|---------|
| `Render_Rounded_Rect` | Solid filled rounded rectangle (fan triangulation) |
| `Render_Rounded_Border_Ring` | Annulus (ring) between an outer and inner rounded rectangle |
| `Render_AA_Fringe` | 1px alpha-gradient strip along a rounded rectangle edge |

Each takes a `Min_Segments` parameter that controls arc tessellation. When multiple primitives share a boundary, they **must** use the same `Min_Segments` value to ensure identical point positions.

---

## AA Fringe Technique

`Render_AA_Fringe` creates a smooth edge by generating two vertex rings:

```
Outer ring (alpha = 0)          <- 1px offset along surface normal
 \                             /
  \  gradient triangle strip  /
   \                         /
Inner ring (alpha = full)       <- on the shape boundary
```

Each point on the shape outline has an outward-pointing normal `(cos t, sin t)` derived from the arc angle. The inner vertex sits on the shape boundary at full alpha. The outer vertex is offset 1px along the normal with alpha set to 0. Triangle strips between the two rings produce a smooth fade.

### Inward parameter

The `Inward` boolean flips the offset direction:

- **`Inward => False`** (default) — fringe extends 1px **outward** from the shape.
- **`Inward => True`** — fringe extends 1px **inward** toward the shape center.

**Critical**: `Inward => True` causes ray artifacts if the fringe and ring use different tessellation. Always pass a shared `Min_Segments` value when using inward fringes (see Ray Artifacts below).

---

## Inner Edge AA Strategies

A ring has two boundaries — outer and inner. The outer edge is antialiased with a standard outward `Render_AA_Fringe`. The inner edge can be smoothed in two ways:

### Strategy 1: Border ring + inward inner fringe (used by borders)

Borders use a ring plus two fringes. The outer edge is smoothed with an outward fringe. The inner edge is always smoothed with an **inward** fringe in border color, so transparent/semi-transparent backgrounds do not leave a jagged inner edge. Background fill is still rendered when non-transparent.

```
Render order (back to front):
  1. Border ring          -- outer+inner edges both aliased
  2. Outer AA fringe      -- smooths outer edge
  3. Background fill      -- optional (non-transparent backgrounds)
  4. Inner AA fringe      -- inward, smooths border-to-interior edge
```

```ada
Seg : constant Positive := Segments_For_Radius (Max_Outer_Radius);

--  1. Border ring
Render_Rounded_Border_Ring
  (Renderer, Outer_Rect, Inner_Rect,
   Outer_Radii, Inner_Radii, R, G, B, A,
   Min_Segments => Seg);

--  2. Outer AA fringe
Render_AA_Fringe
  (Renderer, Outer_Rect, Outer_Radii, R, G, B, A,
   Min_Segments => Seg);

--  3. Optional background fill
if Background_Is_Not_Transparent then
   Render_Rounded_Rect
     (Renderer, Inner_Rect, Inner_Radii, BG_R, BG_G, BG_B, BG_A,
      Min_Segments => Seg);
end if;

--  4. Inner AA fringe (inward, shared Seg prevents artifacts)
Render_AA_Fringe
  (Renderer, Inner_Rect, Inner_Radii, R, G, B, A,
   Min_Segments => Seg,
   Inward => True);
```

This works for transparent, semi-transparent, and opaque backgrounds. With opaque fill, the inward fringe is mostly covered; with transparent fill, it remains visible and removes inner-edge aliasing.

**Pitfall**: Do not fill with the ring's own color — it will paint over content underneath (this was tried for outline and covered the entire widget).

### Strategy 2: Render-order layering + inward fringe (used by outlines)

When there is no known fill color (the ring floats over arbitrary content), use two complementary techniques:

1. **Render the ring before subsequent content** — the widget's background/border painted later covers most of the inner aliased edge
2. **Add an inward AA fringe with shared `Min_Segments`** — smooths the exposed inner edge, especially visible when `outline-offset > 0` creates a gap between the outline and the widget

```
Render order (back to front):
  1. Outline ring              -- rendered BEFORE background/border
  2. Outer AA fringe           -- smooths outer edge
  3. Inner AA fringe (inward)  -- smooths inner edge
  4. Border ring               -- (later, partially covers outline inner edge)
  5. Background fill           -- (later, further covers outline inner edge)
```

```ada
Seg : constant Positive := Segments_For_Radius (Max_Outer_Radius);

--  1. Outline ring (rendered before background/border)
Render_Rounded_Border_Ring
  (Renderer, Outline_Outer, Outline_Inner,
   Outer_Radii, Inner_Radii, R, G, B, A,
   Min_Segments => Seg);

--  2. Outer AA fringe
Render_AA_Fringe
  (Renderer, Outline_Outer, Outer_Radii, R, G, B, A,
   Min_Segments => Seg);

--  3. Inner AA fringe (shared Seg prevents ray artifacts)
Render_AA_Fringe
  (Renderer, Outline_Inner, Inner_Radii, R, G, B, A,
   Min_Segments => Seg,
   Inward => True);

--  (background/border rendering follows, further covering the inner edge)
```

The combination works because:
- The inward fringe smooths the inner edge in the gap area (where nothing else covers it)
- The background/border rendering later paints over any remaining artifacts near the widget boundary
- The shared `Min_Segments` prevents ray artifacts from tessellation mismatch

---

## Ray Artifacts

Rays appear as bright spikes radiating from corners of a rounded shape. Two causes:

### 1. Tessellation mismatch (primary cause)

When `Render_Rounded_Border_Ring` and `Render_AA_Fringe` compute their segment counts independently, the arc points may not align at shared boundaries. Misaligned points create tiny gaps or overlaps that appear as faint rays or dark seams. This affects both inward and outward fringes, but is much more visible with inward fringes because the converging vertices amplify small misalignments.

**Fix**: Compute a single `Seg` value from the largest radius involved and pass it as `Min_Segments` to every call that shares a boundary.

```ada
Seg : constant Positive :=
   Segments_For_Radius
     (Float'Max
        (Float'Max (Radii.Top_Left, Radii.Top_Right),
         Float'Max (Radii.Bottom_Right, Radii.Bottom_Left)));
```

### 2. Inward fringe without shared segments

When `Inward => True` is used without a shared segment count, the inward-pointing vertices converge toward arc centers. Any tessellation mismatch causes adjacent fringe triangles to overlap at corners. In the overlap zone, alpha values compound (double-blended), producing visible bright rays.

**Fix**: Always pass the same `Min_Segments` to both the ring and any inward fringe on its inner boundary. With matched tessellation, the vertices align exactly and no overlap occurs.

---

## Segment Count

`Segments_For_Radius` returns the number of line segments per 90-degree arc. More segments produce smoother curves but more triangles. The function scales with radius — small radii get fewer segments, large radii get more.

When rendering a ring, the outer radii are always larger than the inner radii, so computing `Seg` from the outer radii and sharing it guarantees both boundaries have sufficient tessellation.

---

## Checklist for New Ring-Based Visuals

When adding a new visual that renders as a ring (like border or outline):

1. Compute a shared `Seg` from the largest outer radius
2. Pass `Min_Segments => Seg` to **all** calls that share boundaries (ring, fringes, fills)
3. Call `Render_AA_Fringe` on the outer boundary (outward, default)
4. For the inner edge, choose one of:
   - **Always-on inward fringe** (recommended for borders): optional fill + `Inward => True` fringe with shared `Seg`
   - **Render-order + inward fringe** (if interior is unknown): render ring before overlapping content, add `Inward => True` fringe with shared `Seg`
5. Never fill the ring interior with the ring's own color — it covers content underneath
