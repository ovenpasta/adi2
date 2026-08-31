--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;

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

   ---------------------------------------------------------------------------
   --  Rules, without interning
   ---------------------------------------------------------------------------

   --  A caller that cascades a stylesheet itself -- Adi.Widget.Html_View
   --  does, per document element -- reads the rules a selector names and
   --  folds them into rules of its own. It asks for no part and no
   --  state, so it needs nothing a Widget_Style carries, and a
   --  Stylesheet's round trip through Intern_Rules and Intern leaves an
   --  entry in the rule-set store and the style store per distinct rule
   --  block for the life of the process.
   --
   --  A Rule_Sheet answers the same question and interns none of it: it
   --  holds the Style_Rules each selector's main part folds to and
   --  releases them with itself. It is an ordinary object rather than a
   --  handle into a store, so it lives and dies with the variable
   --  holding it. Text a rule names still reaches Intern_Text, which is
   --  where a Style_Rules holds text at all.
   --
   --  Load_Rules shares the whole parse with Load_String -- one
   --  Parse_Rules over the same grammar. What diverges is what the parse
   --  is folded into.
   type Rule_Sheet is tagged limited private;

   procedure Load_Rules (Sheet       : in out Rule_Sheet;
                         CSS_Content : String;
                         Success     : out Boolean);

   function Has (Sheet : Rule_Sheet;
                 Kind  : Selector_Kind;
                 Name  : String) return Boolean;

   --  What the selector's main part carries with no state selector,
   --  which is the whole of what a document cascade reads.
   --  Empty_Style for a selector the sheet does not name.
   function Base_Rules (Sheet : Rule_Sheet;
                        Kind  : Selector_Kind;
                        Name  : String) return Adi.CSS_Styles.Style_Rules;

   --  The :root font size. The block's other declarations are parsed and
   --  dropped: answering them as styles is what would intern them.
   function Has_Root_Font_Size (Sheet : Rule_Sheet) return Boolean;
   function Root_Font_Size (Sheet : Rule_Sheet)
     return Adi.CSS_Styles.Length_Value;

   function Last_Error (Sheet : Rule_Sheet) return String;

private

   --  What one parsed selector costs to hold; a sheet keeps one per
   --  selector it names. Read through Adi.CSS_Parser.Testing.
   function Selector_Entry_Bytes return Natural;

   --  Bindings a sheet holds, one per widget bound. Read through
   --  Adi.CSS_Parser.Testing: a destroyed widget must take its entry
   --  with it.
   function Binding_Count (Sheet : Stylesheet) return Natural;

   --  Stored keys the binding map has compared against, over every
   --  bind, every prune and every lookup, on every sheet alive in the
   --  process -- one counter for all of them. A bucket's worth per
   --  operation while the lookup is a hash; every binding held were it
   --  ever a scan.
   --
   --  Modular, so instrumentation that runs for the life of the process
   --  wraps rather than raising.
   type Binding_Counter is mod 2 ** 32;
   Probed_Bindings : Binding_Counter := 0;

   --  Impls allocated and not yet destroyed, over all sheets.
   function Live_Impl_Count return Natural;

   --  Rule sheets holding rules and not yet finalized, over all of
   --  them. Read through Adi.CSS_Parser.Testing: a Rule_Sheet released
   --  with the scope or the widget that held it leaves none.
   function Live_Rule_Sheets return Natural;

   --  The selectors a sheet names, and the scan the selector index
   --  replaced -- the answer Styles_For must agree with. Read through
   --  Adi.CSS_Parser.Testing.
   function Selector_Count (Sheet : Stylesheet) return Natural;
   function Selector_Kind_At (Sheet : Stylesheet;
                              Index : Positive) return Selector_Kind;
   function Selector_Name_At (Sheet : Stylesheet;
                              Index : Positive) return String;
   function Styles_For_Scanned
     (Sheet : Stylesheet;
      Kind  : Selector_Kind;
      Name  : String) return Adi.Widget.Part_Style_Array;

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

   --  Completed in the body, so the containers a Rule_Sheet holds stay
   --  out of this spec.
   type Rule_Sheet_Data;
   type Rule_Sheet_Data_Ptr is access Rule_Sheet_Data;

   type Rule_Sheet is limited new Ada.Finalization.Limited_Controlled with
   record
      Data : Rule_Sheet_Data_Ptr := null;
   end record;

   overriding procedure Finalize (Sheet : in out Rule_Sheet);

end Adi.CSS_Parser;
