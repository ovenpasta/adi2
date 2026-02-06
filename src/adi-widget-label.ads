package Adi.Widget.Label is

   ---------------------------------------------------------------------------
   --  Label Widget - Displays text with optional icon
   --
   --  Parts:
   --    - Main_Part  : Container (controls flex layout of icon+text)
   --    - Icon_Part  : Icon/image styling
   --    - Label_Part : Text styling
   --
   --  Layout:
   --    Uses Main_Part style for flex layout (flex-direction, align-items, gap)
   --    Icon and text are positioned using item-based flex layout
   ---------------------------------------------------------------------------

   type Label_Widget is new Widget with private;
   type Label_Widget_Access is access all Label_Widget'Class;

   --  Construction
   function Create (Text : String := "") return Label_Widget_Access;

   --  Content management
   procedure Set_Text (W : in out Label_Widget; Text : String);
   function Get_Text (W : Label_Widget) return String;

   procedure Set_Icon (W : in out Label_Widget; Icon : Image_Access);
   function Get_Icon (W : Label_Widget) return Image_Access;

   --  Override abstract methods
   overriding procedure Build_Items (W : in out Label_Widget);
   overriding procedure Layout (W : in out Label_Widget);

   --  Override size calculation
   overriding function Measure_Content (W : Label_Widget) return Size_2D;

private

   --  Fixed item indices for Label_Widget items vector
   Panel_Idx : constant Positive := 1;
   Text_Idx  : constant Positive := 2;
   Icon_Idx  : constant Positive := 3;

   type Label_Widget is new Widget with record
      Text : Unbounded_String := Null_Unbounded_String;
      Icon : Image_Access := null;

      --  Layout items (positioned by flex layout, then rendered as Items)
      Layout_Items : Layout_Item_List.Vector;
   end record;

end Adi.Widget.Label;
