pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Tags;

with Adi.Widget.Label;
with Adi.Widget.Text_Input;
with Adi.Widget.Text_Editor;
with Adi.Widget.Combo_Box;
with Adi.Widget.Html_View;

package body Adi.Widget.Introspection is

   function Child_Access
     (W     : Widget'Class;
      Index : Positive) return Widget_Access
   is
      H : constant Widget_Handle := Get_Child_Handle (W, Index);
   begin
      return Widget_Stores.Get (H.Id);
   end Child_Access;

   function Tag_Name (W : not null access Widget'Class) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Tags.External_Tag (W.all'Tag));
   end Tag_Name;

   --------------
   -- Get_Text --
   --------------

   function Get_Text (W : not null access Widget'Class) return String is
   begin
      if W.all in Label.Label_Widget'Class then
         return Label.Get_Text (Label.Label_Widget'Class (W.all));
      elsif W.all in Text_Input.Text_Input_Widget'Class then
         return Text_Input.Get_Text
           (Text_Input.Text_Input_Widget'Class (W.all));
      elsif W.all in Text_Editor.Text_Editor_Widget'Class then
         return Text_Editor.Get_Text
           (Text_Editor.Text_Editor_Widget'Class (W.all));
      elsif W.all in Combo_Box.Combo_Box_Widget'Class then
         return Combo_Box.Get_Selected_Text
           (Combo_Box.Combo_Box_Widget'Class (W.all));
      elsif W.all in Html_View.Html_View'Class then
         return Html_View.Get_HTML (Html_View.Html_View'Class (W.all));
      else
         return Get_Label (W.all);
      end if;
   end Get_Text;

   --------------
   -- Get_Info --
   --------------

   function Get_Info
     (W    : not null access Widget'Class;
      Path : String) return Widget_Info
   is
      Geom : constant Rectangle := Get_Geometry (W.all);
   begin
      return
        (Id          => Get_Id (W.all),
         Tag_Name    => To_Unbounded_String (Tag_Name (W)),
         Path        => To_Unbounded_String (Path),
         Text        => To_Unbounded_String (Get_Text (W)),
         Geometry    => Geom,
         States      => Get_States (W.all),
         Flags       =>
           [Clickable  => Has_Flag (W.all, Clickable),
            Focusable  => Has_Flag (W.all, Focusable),
            Scrollable => Has_Flag (W.all, Scrollable),
            Draggable  => Has_Flag (W.all, Draggable),
            Visible    => Has_Flag (W.all, Visible)],
         Child_Count => Child_Count (W.all),
         Items_Count => Item_Count (W.all));
   end Get_Info;

   ----------------
   -- Find_By_Id --
   ----------------

   function Find_By_Id
     (Root : not null Widget_Access;
      Id   : Natural) return Widget_Access
   is
   begin
      if Get_Id (Root.all) = Id then
         return Root;
      end if;

      for I in 1 .. Child_Count (Root.all) loop
         declare
            C      : constant Widget_Access := Child_Access (Root.all, I);
            Result : constant Widget_Access := Find_By_Id (C, Id);
         begin
            if Result /= null then
               return Result;
            end if;
         end;
      end loop;

      return null;
   end Find_By_Id;

   ------------------
   -- Find_By_Path --
   ------------------

   function Find_By_Path
     (Root : not null Widget_Access;
      Path : String) return Widget_Access
   is
      use Ada.Strings.Fixed;
      Norm    : constant String (1 .. Path'Length) := Path;
      Current : Widget_Access := Root;
      Pos     : Positive := 1;
   begin
      if Norm'Length = 0 then return Root; end if;

      while Pos <= Norm'Last loop
         declare
            Dot     : constant Natural :=
              Index (Norm (Pos .. Norm'Last), ".");
            End_Pos : constant Natural :=
              (if Dot = 0 then Norm'Last else Dot - 1);
            Idx_Str : constant String := Norm (Pos .. End_Pos);
            Idx     : constant Positive := Positive'Value (Idx_Str);
         begin
            if Idx > Child_Count (Current.all) then
               return null;
            end if;
            Current := Child_Access (Current.all, Idx);
            Pos := End_Pos + 2;
         end;
      end loop;
      return Current;
   exception
      when others => return null;
   end Find_By_Path;

   ---------------
   -- Find_Path --
   ---------------

   function Find_Path
     (Root   : not null Widget_Access;
      Target : not null Widget_Access) return String
   is
      function Walk
        (W      : not null Widget_Access;
         Prefix : String) return String
      is
      begin
         if W = Target then
            return Prefix;
         end if;

         for I in 1 .. Child_Count (W.all) loop
            declare
               C     : constant Widget_Access := Child_Access (W.all, I);
               I_Str : constant String := Ada.Strings.Fixed.Trim
                 (Positive'Image (I), Ada.Strings.Left);
               Child_Path : constant String :=
                 (if Prefix'Length = 0 then I_Str
                  else Prefix & "." & I_Str);
               Result : constant String := Walk (C, Child_Path);
            begin
               if Result'Length > 0 or else C = Target then
                  return (if C = Target then Child_Path else Result);
               end if;
            end;
         end loop;

         return "";
      end Walk;
   begin
      return Walk (Root, "");
   end Find_Path;

   ------------------
   -- Find_By_Text --
   ------------------

   function Find_By_Text
     (Root  : not null Widget_Access;
      Query : String;
      Exact : Boolean := False) return Match_Vectors.Vector
   is
      use Ada.Characters.Handling;
      use Ada.Strings.Fixed;

      Lower_Query : constant String := To_Lower (Query);
      Results     : Match_Vectors.Vector;

      procedure Walk
        (W    : not null Widget_Access;
         Path : String)
      is
         Txt       : constant String := Get_Text (W);
         Lower_Txt : constant String := To_Lower (Txt);
         Matches   : constant Boolean :=
           (if Exact then Lower_Txt = Lower_Query
            else Index (Lower_Txt, Lower_Query) > 0);
      begin
         if Matches and then Txt'Length > 0 then
            Results.Append
              (Widget_Match'
                (Id       => Get_Id (W.all),
                 Path     => To_Unbounded_String (Path),
                 Tag_Name => To_Unbounded_String (Tag_Name (W)),
                 Text     => To_Unbounded_String (Txt)));
         end if;

         for I in 1 .. Child_Count (W.all) loop
            declare
               C     : constant Widget_Access := Child_Access (W.all, I);
               I_Str : constant String := Ada.Strings.Fixed.Trim
                 (Positive'Image (I), Ada.Strings.Left);
               Child_Path : constant String :=
                 (if Path'Length = 0 then I_Str
                  else Path & "." & I_Str);
            begin
               Walk (C, Child_Path);
            end;
         end loop;
      end Walk;
   begin
      Walk (Root, "");
      return Results;
   end Find_By_Text;

   ------------------
   -- Find_By_Type --
   ------------------

   function Find_By_Type
     (Root      : not null Widget_Access;
      Type_Name : String) return Match_Vectors.Vector
   is
      use Ada.Characters.Handling;
      use Ada.Strings.Fixed;

      Lower_Name : constant String := To_Lower (Type_Name);
      Results    : Match_Vectors.Vector;

      procedure Walk
        (W    : not null Widget_Access;
         Path : String)
      is
         TN      : constant String := Tag_Name (W);
         Matches : constant Boolean := Index (TN, Lower_Name) > 0;
      begin
         if Matches then
            Results.Append
              (Widget_Match'
                (Id       => Get_Id (W.all),
                 Path     => To_Unbounded_String (Path),
                 Tag_Name => To_Unbounded_String (TN),
                 Text     => To_Unbounded_String (Get_Text (W))));
         end if;

         for I in 1 .. Child_Count (W.all) loop
            declare
               C     : constant Widget_Access := Child_Access (W.all, I);
               I_Str : constant String := Ada.Strings.Fixed.Trim
                 (Positive'Image (I), Ada.Strings.Left);
               Child_Path : constant String :=
                 (if Path'Length = 0 then I_Str
                  else Path & "." & I_Str);
            begin
               Walk (C, Child_Path);
            end;
         end loop;
      end Walk;
   begin
      Walk (Root, "");
      return Results;
   end Find_By_Type;

end Adi.Widget.Introspection;
