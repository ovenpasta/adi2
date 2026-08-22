# Item-Based Flex Layout System

## Overview

The **Layout_Item** system lets widgets use flexbox layout for their internal visual elements (items), not just child widgets. This enables complex internal layouts without creating extra widget instances.

## Architecture

### Key Types

```ada
--  Layout_Item - An item that participates in flex layout
type Layout_Item is record
   Part        : Part_Kind;          -- Which part this represents (Icon_Part, Label_Part, etc.)

   --  Size constraints
   Min_Width   : Float := 0.0;
   Min_Height  : Float := 0.0;
   Max_Width   : Float := Float'Last;
   Max_Height  : Float := Float'Last;

   --  Content size (intrinsic size)
   Content_Width  : Float := 0.0;
   Content_Height : Float := 0.0;

   --  Flex properties
   Flex        : Flex_Item_Properties;

   --  Output: Calculated geometry from layout algorithm
   Geometry    : Rectangle := (0.0, 0.0, 0.0, 0.0);

   --  User data for identification
   Index       : Natural := 0;
end record;

--  Flex properties for a layout item
type Flex_Item_Properties is record
   Grow       : Float := 0.0;              -- flex-grow (0 = don't grow)
   Shrink     : Float := 1.0;              -- flex-shrink (1 = can shrink)
   Basis      : Float := 0.0;              -- flex-basis in pixels
   Align_Self : Align_Self_Value := Auto;  -- Override container alignment
end record;
```

### Core Function

```ada
--  Positions a list of Layout_Items using flexbox algorithm
procedure Perform_Item_Flex_Layout
   (Container_Geom  : Rectangle;        -- Container bounds
    Container_Style : Resolved_Style;   -- Container flex properties
    Items           : in out Layout_Item_List.Vector);  -- Items to position
```

## Usage Pattern

### 1. Widget Declaration

```ada
type My_Widget is new Widget with record
   --  Content data (what to display)
   Text : Unbounded_String;
   Icon : Adi.Image.Image_Handle;

   --  Layout items (positioned by flex, then rendered)
   Layout_Items : Layout_Item_List.Vector;
end record;
```

### 2. Layout Procedure (Position Items)

```ada
overriding procedure Layout (W : in out My_Widget) is
   Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
begin
   W.Layout_Items.Clear;

   --  Build layout items for each visual element
   if Adi.Image.Is_Valid (W.Icon) then
      declare
         Icon_Item : Layout_Item;
      begin
         Icon_Item := (
            Part           => Icon_Part,
            Content_Width  => 16.0,
            Content_Height => 16.0,
            Min_Width      => 16.0,
            Max_Width      => 16.0,
            Flex           => (
               Grow       => 0.0,   -- Don't grow
               Shrink     => 0.0,   -- Don't shrink
               Basis      => 16.0,
               Align_Self => Auto
            ),
            Geometry       => <>,
            Index          => 1
         );
         W.Layout_Items.Append (Icon_Item);
      end;
   end if;

   if Length (W.Text) > 0 then
      declare
         Text_Item : Layout_Item;
      begin
         Text_Item := (
            Part           => Label_Part,
            Content_Width  => 100.0,
            Content_Height => 20.0,
            Flex           => (
               Grow       => 1.0,   -- Grow to fill space
               Shrink     => 1.0,   -- Can shrink
               Basis      => 0.0,
               Align_Self => Auto
            ),
            Geometry       => <>,
            Index          => 2
         );
         W.Layout_Items.Append (Text_Item);
      end;
   end if;

   --  Run flex layout algorithm
   if not W.Layout_Items.Is_Empty then
      Perform_Item_Flex_Layout (
         Container_Geom  => W.Geometry,
         Container_Style => Main_Style,  -- Uses flex-direction, align-items, etc.
         Items           => W.Layout_Items
      );
   end if;

   --  Now Layout_Items have calculated Geometry fields
end Layout;
```

### 3. Build_Items Procedure (Create Renderables)

```ada
overriding procedure Build_Items (W : in out My_Widget) is
begin
   Clear_Items (W);

   --  Background panel
   Add_Item (W, Make_Panel (
      Part     => Main_Part,
      Geometry => W.Geometry,
      Z_Order  => 0));

   --  Create renderable items from layout items
   for L_Item of W.Layout_Items loop
      case L_Item.Part is
         when Icon_Part =>
            if Adi.Image.Is_Valid (W.Icon) then
               Add_Item (W, Make_Image (
                  Part     => Icon_Part,
                  Geometry => L_Item.Geometry,  -- Use calculated geometry
                  Source   => W.Icon,
                  Z_Order  => 1));
            end if;

         when Label_Part =>
            if Length (W.Text) > 0 then
               Add_Item (W, Make_Text (
                  Part     => Label_Part,
                  Geometry => L_Item.Geometry,  -- Use calculated geometry
                  Content  => To_String (W.Text),
                  Z_Order  => 1));
            end if;

         when others =>
            null;
      end case;
   end loop;
end Build_Items;
```

## Label Widget Example

`Adi.Widget.Label` is the in-tree widget built this way: `Main_Part` is the flex
container, `Icon_Part` and `Label_Part` are the two items it positions.

### Creating and Styling a Label

A part style is a `Style_Rules` aggregate wrapped by the `Adi.Widget_Styles`
builder and attached with `Set_Part_Style`. `examples/hello_raw_example.adb`
has the same shape end to end.

```ada
with Adi.Image;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;

use type Adi.Widget.Label.Label_Handle;   --  makes "+" visible

function Style return Style_Builder renames Adi.Widget_Styles.Create;

--  Main_Part lays out icon and text
Main_Rules : constant Style_Rules :=
  (Display          => Set (Flex),
   Flex_Direction   => Set (Row),                          --  [Icon] Text
   Align_Items      => Set (Align_Items_Value'(Center)),
   Justify_Content  => Set (Justify_Content_Value'(Flex_Start)),
   Gap              => Set (Gap (Px (8.0))),
   Padding          => Set (CSS_Box (Px (10.0))),
   Background_Color => Set_Bg (RGB (240, 240, 240)),
   Border_Radius    => Set (Radius (Px (4.0))),
   others           => <>);

--  Icon_Part sizes the icon item
Icon_Rules : constant Style_Rules :=
  (Width      => Set (Size (Px (16.0))),
   Height     => Set (Size (Px (16.0))),
   Object_Fit => Set (Fit_Contain),
   others     => <>);

--  Label_Part styles the text item
Label_Rules : constant Style_Rules :=
  (Color     => Set (RGB (0, 0, 0)),
   Font_Size => Set_Font (Px (14.0)),
   others    => <>);

Lbl  : constant Adi.Widget.Label.Label_Handle :=
         Adi.Widget.Label.Create_Handle ("Save");
Icon : Adi.Image.Image_Owner;
```

```ada
Set_Geometry (Widget_Handle'(+Lbl), (100.0, 50.0, 200.0, 40.0));

--  An image owner must outlive the widgets drawing it
Icon := Adi.Image.Load_SVG_Path
          (Path_Data => "M5 3 H19 V21 H5 Z",
           Size      => (24.0, 24.0),
           Fill      => (R => 242, G => 248, B => 255, A => 255));
if Adi.Image.Is_Owned (Icon) then
   Adi.Widget.Label.Set_Icon (Lbl, Adi.Image.To_Handle (Icon));
end if;

Set_Part_Style (Widget_Handle'(+Lbl), Main_Part,
                Style.Base (Main_Rules).Build);
Set_Part_Style (Widget_Handle'(+Lbl), Icon_Part,
                Style.Base (Icon_Rules).Build);
Set_Part_Style (Widget_Handle'(+Lbl), Label_Part,
                Style.Base (Label_Rules).Build);
```

`Adi.Image.Load_From_File` takes a path instead, for a raster or an SVG file.
`examples/label_example.adb` builds its icon the same way.

### Layout Variations

Only the `Main_Part` rules change; the item styles stay as they are.

**Vertical (icon above text):**
```ada
(Display        => Set (Flex),
 Flex_Direction => Set (Column),
 Align_Items    => Set (Align_Items_Value'(Center)),
 others         => <>)
```

**Reverse (text before icon):**
```ada
(Display        => Set (Flex),
 Flex_Direction => Set (Row_Reverse),
 others         => <>)
```

**Spaced apart:**
```ada
(Display         => Set (Flex),
 Justify_Content => Set (Justify_Content_Value'(Space_Between)),
 others          => <>)
```

The same three parts are reachable from CSS: a bare class selector targets
`Main_Part`, `::icon` targets `Icon_Part` and `::label` targets `Label_Part`.

## Benefits

1. **Reuses existing flex infrastructure** - Leverages `Compute_Flex_Layout` and `Flex_To_Rectangles`
2. **No extra widgets** - Items are lightweight, not full widget instances
3. **Flexible layouts** - Full flexbox power for internal widget structure
4. **Clean separation** - Layout (positioning) vs Build_Items (rendering)
5. **Extensible** - Easy to add more complex widgets (buttons with badge, menus, etc.)

## Workflow

```
Widget contains:
├── Content (Text, Icon, etc.)       ← Data to display
└── Layout_Items                     ← Positioning information

Layout():
   1. Build Layout_Items from content
   2. Run Perform_Item_Flex_Layout
   3. Layout_Items.Geometry is calculated

Build_Items():
   1. Create renderable Items
   2. Use Layout_Items.Geometry for positioning
   3. Items are drawn during render
```

## Implementation Details

The `Perform_Item_Flex_Layout` function:
1. Converts `Layout_Item` → `Flex_Child_Info` (existing flex type)
2. Calls `Compute_Flex_Layout` (existing flex algorithm)
3. Calls `Flex_To_Rectangles` to get final positions
4. Updates `Layout_Item.Geometry` with results

This means all flex features work automatically:
- flex-direction (row, column, row-reverse, column-reverse)
- justify-content (flex-start, center, space-between, etc.)
- align-items (flex-start, center, stretch, etc.)
- gap (row-gap, column-gap)
- flex-grow, flex-shrink, flex-basis
- align-self (per-item alignment override)
