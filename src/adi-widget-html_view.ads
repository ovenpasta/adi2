with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Adi.Core;              use Adi.Core;
with Adi.CSS_Parser;
with Adi.CSS_Styles;
with Adi.Image;
with Adi.Widget;            use Adi.Widget;

package Adi.Widget.Html_View is

   type Html_View is new Widget with private;
   type Html_View_Access is access all Html_View'Class;

   type Link_Click_Callback is access procedure
     (Self : access Html_View;
      Href : String);

   type Asset_Load_Callback is access function
     (Self : access Html_View;
      URI  : String) return Adi.Image.Image_Access;

   type Resource_Load_Callback is access function
     (Self : access Html_View;
      URI  : String) return String;

   function Create return Html_View_Access;

   procedure Set_HTML
     (Self   : in out Html_View;
      Source : String);
   function Get_HTML (Self : Html_View) return String;
   procedure Clear (Self : in out Html_View);

   procedure Set_Content_Scale
     (Self  : in out Html_View;
      Scale : Pixel_Type);
   function Get_Content_Scale (Self : Html_View) return Pixel_Type;

   procedure Set_On_Link_Click
     (Self     : in out Html_View;
      Callback : Link_Click_Callback);

   procedure Set_On_Load_Asset
     (Self     : in out Html_View;
      Callback : Asset_Load_Callback);

   procedure Set_On_Load_Resource
     (Self     : in out Html_View;
      Callback : Resource_Load_Callback);

   overriding procedure Build_Items (Self : in out Html_View);
   overriding procedure Layout (Self : in out Html_View);
   overriding function Measure_Content (Self : Html_View) return Size_2D;

   overriding procedure On_Mouse_Down
     (Self   : in out Html_View;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Move
     (Self : in out Html_View;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (Self   : in out Html_View;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);

private
   type Node_Kind is (Element_Node, Text_Node, Break_Node);

   type Element_Attributes is record
      Id_Attr    : Unbounded_String := Null_Unbounded_String;
      Class_Attr : Unbounded_String := Null_Unbounded_String;
      Style_Attr : Unbounded_String := Null_Unbounded_String;
      Href_Attr  : Unbounded_String := Null_Unbounded_String;
      Src_Attr   : Unbounded_String := Null_Unbounded_String;
      Alt_Attr   : Unbounded_String := Null_Unbounded_String;
      Value_Attr : Unbounded_String := Null_Unbounded_String;
      Svg_Source_Attr : Unbounded_String := Null_Unbounded_String;
   end record;

   package Node_Index_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Natural);

   type Node (Kind : Node_Kind := Text_Node) is record
      Parent : Natural := 0;
      case Kind is
         when Element_Node =>
            Tag_Name : Unbounded_String := Null_Unbounded_String;
            Attrs    : Element_Attributes;
            Children : Node_Index_Vectors.Vector;
         when Text_Node =>
            Text : Unbounded_String := Null_Unbounded_String;
         when Break_Node =>
            null;
      end case;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Node);

   type Link_Fragment is record
      Geometry : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Href     : Unbounded_String := Null_Unbounded_String;
   end record;

   package Link_Fragment_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Link_Fragment);

   type Cached_Image is record
      Src : Unbounded_String := Null_Unbounded_String;
      Img : Adi.Image.Image_Access := null;
   end record;

   package Cached_Image_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cached_Image);

   type Inline_Style_Cache_Entry is record
      Inline_Text : Unbounded_String := Null_Unbounded_String;
      Rules       : Adi.CSS_Styles.Style_Rules := Adi.CSS_Styles.Empty_Style;
   end record;

   package Inline_Style_Cache_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Inline_Style_Cache_Entry);

   type Html_View is new Widget with record
      Source          : Unbounded_String := Null_Unbounded_String;
      Nodes           : Node_Vectors.Vector;
      Links           : Link_Fragment_Vectors.Vector;
      Image_Cache     : Cached_Image_Vectors.Vector;
      Inline_Style_Cache : Inline_Style_Cache_Vectors.Vector;
      On_Link_Click   : Link_Click_Callback := null;
      On_Load_Asset   : Asset_Load_Callback := null;
      On_Load_Resource : Resource_Load_Callback := null;
      CSS_Sheet       : Adi.CSS_Parser.Stylesheet;
      Hovered_Href    : Unbounded_String := Null_Unbounded_String;
      Pressed_Href    : Unbounded_String := Null_Unbounded_String;
      Pressed_Is_Link : Boolean := False;
      Content_Scale   : Pixel_Type := 1.0;
   end record;

end Adi.Widget.Html_View;
