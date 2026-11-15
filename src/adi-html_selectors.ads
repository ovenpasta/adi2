--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

private with Ada.Containers.Vectors;
private with Ada.Strings.Unbounded;

--  CSS selectors over a document tree, for a caller that cascades a
--  document itself.
--
--  A selector is compounds joined by combinators: descendant (space),
--  child (>), next sibling (+) and later sibling (~). A compound is a
--  type selector or *, then any of .class, #id, [attr], [attr=value] and
--  the pseudo-classes :hover, :active, :link, :visited, :first-child and
--  :last-child. Names match case-insensitively. A pseudo-element or any
--  other pseudo-class makes the selector one that matches nothing.
package Adi.HTML_Selectors is

   type Selector is private;

   --  False, with Result matching nothing, for text outside the grammar.
   function Parse (Text : String; Result : out Selector) return Boolean;

   --  CSS specificity: ids, then classes, attributes and pseudo-classes,
   --  then types.
   type Specificity is record
      Ids, Classes, Types : Natural := 0;
   end record;

   function "<" (L, R : Specificity) return Boolean;

   function Specificity_Of (S : Selector) return Specificity;

   --  The type and id the last compound requires, lower case, or "" for
   --  any: an element without them cannot match.
   function Subject_Tag (S : Selector) return String;
   function Subject_Id (S : Selector) return String;

   --  Whether any compound names :hover or :active, so a change in which
   --  element is under the pointer can change what the selector matches.
   function Is_Dynamic (S : Selector) return Boolean;

   type Dynamic_State is (Hovered, Activated);

   --  A document as the matcher reads it. Elements are positive indices,
   --  0 is none. Names come back as written; the matcher folds case.
   type Document is limited interface;

   function Tag_Of (D : Document; E : Positive) return String is abstract;
   function Id_Of (D : Document; E : Positive) return String is abstract;
   function Has_Class
     (D : Document; E : Positive; Name : String) return Boolean is abstract;
   --  The attribute's value, with Found False when E has none.
   function Attribute_Of
     (D : Document; E : Positive; Name : String; Found : out Boolean)
      return String is abstract;
   function Parent_Of (D : Document; E : Positive) return Natural is abstract;
   --  The element siblings either side, skipping text.
   function Previous_Sibling_Of (D : Document; E : Positive) return Natural is abstract;
   function Next_Sibling_Of (D : Document; E : Positive) return Natural is abstract;
   function In_State
     (D : Document; E : Positive; State : Dynamic_State) return Boolean is abstract;

   function Matches
     (S : Selector; D : Document'Class; E : Positive) return Boolean;

private

   use Ada.Strings.Unbounded;

   type Combinator is (None, Descendant, Child, Next_Sibling, Later_Sibling);

   type Pseudo_Class is (Hover, Active, Link, Visited, First_Child, Last_Child);
   type Pseudo_Set is array (Pseudo_Class) of Boolean;

   type Attribute_Test is record
      Name      : Unbounded_String;
      Has_Value : Boolean := False;
      Value     : Unbounded_String;
   end record;

   package Name_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Unbounded_String);
   package Attribute_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Attribute_Test);

   --  One compound, and how it joins the compound written before it.
   type Compound is record
      Joined_By  : Combinator := None;
      Tag        : Unbounded_String;  --  "" for any
      Id         : Unbounded_String;  --  "" for none
      Classes    : Name_Vectors.Vector;
      Attributes : Attribute_Vectors.Vector;
      Pseudos    : Pseudo_Set := [others => False];
   end record;

   package Compound_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Compound);

   type Selector is record
      Parts : Compound_Vectors.Vector;  --  as written, left to right
      Valid : Boolean := False;
   end record;

end Adi.HTML_Selectors;
