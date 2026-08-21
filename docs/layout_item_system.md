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
   if W.Icon /= null then
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
            if W.Icon /= null then
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

### Creating and Styling a Label

```ada
--  Create label with text
Label := Adi.Widget.Label.Create ("Save");
Set_Geometry (Label.all, (100.0, 50.0, 200.0, 40.0));

--  Add icon
My_Icon := W.Load_Image ("icons/save.png");
Label.Set_Icon (My_Icon);

--  Main_Part controls layout of icon+text
Set_Part_Style (Label.all, Main_Part,
   Make_Style
      .Display (Flex)
      .Flex_Direction (Row)        -- [Icon] Text (horizontal)
      .Align_Items (Center)        -- Vertically center both
      .Justify_Content (Flex_Start)
      .Gap (Px (8.0))              -- 8px between icon and text
      .Padding (Px (10.0))
      .Background_Color (RGB (240, 240, 240))
      .Border_Radius (Px (4.0))
      .Build);

--  Icon_Part controls icon appearance
Set_Part_Style (Label.all, Icon_Part,
   Make_Style
      .Width (Px (16.0))
      .Height (Px (16.0))
      .Object_Fit (Contain)
      .Build);

--  Label_Part controls text appearance
Set_Part_Style (Label.all, Label_Part,
   Make_Style
      .Color (RGB (0, 0, 0))
      .Font_Size (Px (14.0))
      .Build);
```

### Layout Variations

**Vertical (Icon above text):**
```ada
Set_Part_Style (Label.all, Main_Part,
   Make_Style
      .Display (Flex)
      .Flex_Direction (Column)  -- Icon / Text
      .Align_Items (Center)
      .Build);
```

**Reverse (Text before icon):**
```ada
Set_Part_Style (Label.all, Main_Part,
   Make_Style
      .Flex_Direction (Row_Reverse)  -- Text [Icon]
      .Build);
```

**Spaced apart:**
```ada
Set_Part_Style (Label.all, Main_Part,
   Make_Style
      .Justify_Content (Space_Between)  -- [Icon]    Text
      .Build);
```

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
