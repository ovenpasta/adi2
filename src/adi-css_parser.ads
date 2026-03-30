pragma Ada_2022;

with Adi.CSS_Styles;
with Adi.Widget;

package Adi.CSS_Parser is

   pragma Elaborate_Body;

   type Selector_Kind is (Tag_Selector, Class_Selector, Id_Selector);

   type Stylesheet_Metadata is record
      Has_Root_Style     : Boolean := False;
      Root_Styles        : Adi.Widget.Part_Style_Array :=
        Adi.Widget.Empty_Part_Styles;
      Has_Root_Font_Size : Boolean := False;
      Root_Font_Size     : Adi.CSS_Styles.Length_Value :=
        Adi.CSS_Styles.Default_Font_Size;
   end record;

   type Stylesheet is tagged private;

   procedure Load_File (Sheet   : in out Stylesheet;
                        Path    : String;
                        Success : out Boolean);

   procedure Load_String (Sheet       : in out Stylesheet;
                          CSS_Content : String;
                          Success     : out Boolean);

   procedure Reload_If_Changed (Sheet    : in out Stylesheet;
                                Reloaded : out Boolean;
                                Success  : out Boolean);

   function Has (Sheet : Stylesheet;
                 Kind : Selector_Kind;
                 Name : String) return Boolean;

   function Has_Class (Sheet : Stylesheet; Class_Name : String) return Boolean;
   function Has_Id (Sheet : Stylesheet; Id_Name : String) return Boolean;
   function Has_Tag (Sheet : Stylesheet; Tag_Name : String) return Boolean;

   function Styles_For (Sheet : Stylesheet;
                        Kind  : Selector_Kind;
                        Name  : String) return Adi.Widget.Part_Style_Array;

   function Styles_For_Class (Sheet : Stylesheet;
                              Class_Name : String) return Adi.Widget.Part_Style_Array;
   function Styles_For_Id (Sheet : Stylesheet;
                           Id_Name : String) return Adi.Widget.Part_Style_Array;
   function Styles_For_Tag (Sheet : Stylesheet;
                            Tag_Name : String) return Adi.Widget.Part_Style_Array;

   function Styles_For (Sheet : Stylesheet;
                        Class_Name : String) return Adi.Widget.Part_Style_Array;

   function Get_Metadata (Sheet : Stylesheet) return Stylesheet_Metadata;
   function Has_Custom_Property (Sheet : Stylesheet; Name : String) return Boolean;
   function Get_Custom_Property (Sheet : Stylesheet; Name : String) return String;

   procedure Apply_Root_Metadata
     (Sheet : Stylesheet;
      W     : in out Adi.Widget.Widget'Class);
   procedure Bind_Root_Metadata
     (Sheet : in out Stylesheet;
      W     : access Adi.Widget.Widget'Class);
   procedure Bind_Root_Metadata
     (Sheet : in out Stylesheet;
      W     : Adi.Widget.Widget_Handle);

   procedure Apply (Sheet : Stylesheet;
                    Kind  : Selector_Kind;
                    Name  : String;
                    W     : in out Adi.Widget.Widget'Class);

   procedure Apply_Class (Sheet      : Stylesheet;
                          Class_Name : String;
                          W          : in out Adi.Widget.Widget'Class);
   procedure Apply_Id (Sheet   : Stylesheet;
                       Id_Name : String;
                       W       : in out Adi.Widget.Widget'Class);
   procedure Apply_Tag (Sheet   : Stylesheet;
                        Tag_Name : String;
                        W        : in out Adi.Widget.Widget'Class);

   procedure Bind (Sheet : in out Stylesheet;
                   Kind  : Selector_Kind;
                   Name  : String;
                   W     : access Adi.Widget.Widget'Class);

   procedure Bind_Class (Sheet      : in out Stylesheet;
                         Class_Name : String;
                         W          : access Adi.Widget.Widget'Class);
   procedure Bind_Id (Sheet   : in out Stylesheet;
                      Id_Name : String;
                      W       : access Adi.Widget.Widget'Class);
   procedure Bind_Tag (Sheet   : in out Stylesheet;
                       Tag_Name : String;
                       W        : access Adi.Widget.Widget'Class);

   --  Widget_Handle overloads
   procedure Bind (Sheet : in out Stylesheet;
                   Kind  : Selector_Kind;
                   Name  : String;
                   W     : Adi.Widget.Widget_Handle);
   procedure Bind_Class (Sheet      : in out Stylesheet;
                         Class_Name : String;
                         W          : Adi.Widget.Widget_Handle);
   procedure Bind_Id (Sheet   : in out Stylesheet;
                      Id_Name : String;
                      W       : Adi.Widget.Widget_Handle);
   procedure Bind_Tag (Sheet    : in out Stylesheet;
                       Tag_Name : String;
                       W        : Adi.Widget.Widget_Handle);

   function Get_Last_Error (Sheet : Stylesheet) return String;
   function Get_Source_Path (Sheet : Stylesheet) return String;

private

   type Stylesheet_Impl;
   type Stylesheet_Impl_Access is access all Stylesheet_Impl;

   type Stylesheet is tagged record
      Impl : Stylesheet_Impl_Access := null;
   end record;

end Adi.CSS_Parser;
