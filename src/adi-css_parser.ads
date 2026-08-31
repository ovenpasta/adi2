--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles;
with Adi.Handle_Store;
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

   --  Release what the sheet holds -- its selectors, its bindings and
   --  around a quarter of a megabyte of metadata -- and stop it being
   --  reached when a widget is destroyed. Every copy of the sheet
   --  answers Is_Valid False from here on, and reads through one answer
   --  as they do for a sheet that holds nothing. Destroying it again, or
   --  destroying a copy, does nothing. Loading into it again builds a
   --  fresh one.
   procedure Destroy (Sheet : in out Stylesheet);

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

   --  True while the sheet holds a loaded stylesheet: from the first
   --  Load until Destroy, for this value and for every copy of it.
   function Is_Valid (Sheet : Stylesheet) return Boolean;

private

   --  What one parsed selector costs to hold; a sheet keeps one per
   --  selector it names. Read through Adi.CSS_Parser.Testing.
   function Selector_Entry_Bytes return Natural;

   --  Bindings a sheet holds, and the widgets one is current for. Also
   --  read through Adi.CSS_Parser.Testing: a destroyed widget must take
   --  its entry out of both.
   function Binding_Count (Sheet : Stylesheet) return Natural;
   function Effective_Count (Sheet : Stylesheet) return Natural;

   --  Impls allocated and not yet destroyed, over all sheets.
   function Live_Impl_Count return Natural;

   --  The store owns what a sheet holds, and a Stylesheet is a
   --  generational handle into it. Copying one copies the handle: every
   --  copy answers Is_Valid False once any of them is destroyed, and a
   --  second Destroy does nothing.
   type Sheet_Impl_Base is abstract tagged limited null record;
   type Sheet_Impl_Access is access all Sheet_Impl_Base'Class;

   package Sheet_Stores is new Adi.Handle_Store
     (Sheet_Impl_Base, Sheet_Impl_Access);

   type Stylesheet is tagged record
      Id : Sheet_Stores.Object_Id := Sheet_Stores.Null_Id;
   end record;

end Adi.CSS_Parser;
