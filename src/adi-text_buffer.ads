with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Adi.Text_Buffer is

   type Position is record
      Line   : Positive := 1;
      Column : Natural  := 0;  -- 0-based character offset in line
   end record;

   type Text_Buffer is tagged private;
   type Text_Buffer_Access is access all Text_Buffer;

   procedure Clear (B : in out Text_Buffer);
   procedure Set_Text (B : in out Text_Buffer; Text : String);
   function Get_Text (B : Text_Buffer) return String;

   function Get_Line_Count (B : Text_Buffer) return Natural;
   function Get_Line (B : Text_Buffer; Line : Positive) return String;

   function Get_Caret (B : Text_Buffer) return Position;
   procedure Set_Caret
     (B                : in out Text_Buffer;
      P                : Position;
      Extend_Selection : Boolean := False);

   function Has_Selection (B : Text_Buffer) return Boolean;
   function Get_Selected_Text (B : Text_Buffer) return String;
   procedure Get_Selection_Range
     (B      : Text_Buffer;
      Start  : out Position;
      Stop   : out Position;
      Active : out Boolean);
   procedure Clear_Selection (B : in out Text_Buffer);
   procedure Select_All (B : in out Text_Buffer);

   procedure Insert_Text (B : in out Text_Buffer; Text : String);
   procedure Delete_Backward (B : in out Text_Buffer);
   procedure Delete_Forward (B : in out Text_Buffer);
   function Copy_Selection_To_Clipboard (B : Text_Buffer) return Boolean;
   function Cut_Selection_To_Clipboard (B : in out Text_Buffer) return Boolean;
   function Paste_From_Clipboard
     (B           : in out Text_Buffer;
      Single_Line : Boolean := False) return Boolean;
   function Undo (B : in out Text_Buffer) return Boolean;
   function Redo (B : in out Text_Buffer) return Boolean;
   function Can_Undo (B : Text_Buffer) return Boolean;
   function Can_Redo (B : Text_Buffer) return Boolean;

   procedure Move_Left  (B : in out Text_Buffer; Extend_Selection : Boolean := False);
   procedure Move_Right (B : in out Text_Buffer; Extend_Selection : Boolean := False);
   procedure Move_Home  (B : in out Text_Buffer; Extend_Selection : Boolean := False);
   procedure Move_End   (B : in out Text_Buffer; Extend_Selection : Boolean := False);
   procedure Move_Up    (B : in out Text_Buffer; Extend_Selection : Boolean := False);
   procedure Move_Down  (B : in out Text_Buffer; Extend_Selection : Boolean := False);

   procedure Move_Page_Up
     (B              : in out Text_Buffer;
      Lines_Per_Page : Positive;
      Extend_Selection : Boolean := False);
   procedure Move_Page_Down
     (B              : in out Text_Buffer;
      Lines_Per_Page : Positive;
      Extend_Selection : Boolean := False);
   procedure Move_To_Start
     (B : in out Text_Buffer; Extend_Selection : Boolean := False);
   procedure Move_To_End
     (B : in out Text_Buffer; Extend_Selection : Boolean := False);

private
   package Line_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Unbounded_String);

   type Selection_State is record
      Active : Boolean := False;
      Anchor : Position := (Line => 1, Column => 0);
   end record;

   type Buffer_Snapshot is record
      Lines     : Line_Vectors.Vector;
      Caret     : Position := (Line => 1, Column => 0);
      Selection : Selection_State;
   end record;

   package Snapshot_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Buffer_Snapshot);

   type Text_Buffer is tagged record
      Lines     : Line_Vectors.Vector;
      Caret     : Position := (Line => 1, Column => 0);
      Selection : Selection_State;
      Undo_Stack : Snapshot_Vectors.Vector;
      Redo_Stack : Snapshot_Vectors.Vector;
   end record;

end Adi.Text_Buffer;
