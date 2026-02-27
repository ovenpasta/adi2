--  SPDX-License-Identifier: Apache-2.0
--
--  Copyright (c) 2016 onox <denkpadje@gmail.com>
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.

with Ada.Characters.Latin_1;
with Ada.IO_Exceptions;
with Ada.Strings.Bounded;

package body JSON.Tokenizers is

   procedure Read_String
     (Stream     : in out Streams.Stream;
      Next_Token : out Token)
   is
      C : Character;
      Index, Length : Streams.AS.Stream_Element_Offset := 0;
      Escaped : Boolean := False;

      use type Streams.AS.Stream_Element_Offset;
      use Ada.Characters.Latin_1;
   begin
      loop
         Stream.Read_Character (Index, C);

         --  An unescaped '"' character denotes the end of the string
         exit when not Escaped and C = '"';

         Length := Length + 1;

         if Escaped then
            case C is
               when '"' | '\' | '/' | 'b' | 'f' | 'n' | 'r' | 't' =>
                  null;
               when 'u' =>
                  --  TODO Support escaped unicode
                  raise Program_Error with "Escaped unicode not supported yet";
               when others =>
                  raise Tokenizer_Error with "Unexpected escaped character in string";
            end case;
         elsif C /= '\' then
            --  Check C is not a control character
            if C in NUL .. US then
               raise Tokenizer_Error with "Unexpected control character in string";
            end if;
         end if;
         Escaped := not Escaped and C = '\';
      end loop;
      Next_Token := Token'
        (Kind => String_Token, String_Offset => Index - Length, String_Length => Length);
   end Read_String;

   procedure Test_Leading_Zeroes (First : Character; Value : String) is
      Leading_Zero_Message : constant String := "Leading zeroes in number are not allowed";
      Minus_Digit_Message  : constant String := "Expected at least one digit after - sign";
   begin
      if First = '-' then
         if Value'Length >= 3 and then Value (Value'First .. Value'First + 1) = "-0" then
            raise Tokenizer_Error with Leading_Zero_Message;
         elsif Value'Length = 1 then
            raise Tokenizer_Error with Minus_Digit_Message;
         end if;
      elsif First = '0' and Value'Length >= 2 then
         raise Tokenizer_Error with Leading_Zero_Message;
      end if;
   end Test_Leading_Zeroes;

   procedure Read_Number
     (Stream     : in out Streams.Stream;
      First      : Character;
      Next_Token : out Token)
   is
      package SB is new Ada.Strings.Bounded.Generic_Bounded_Length
        (Max => Types.Maximum_String_Length_Numbers);

      Value : SB.Bounded_String;
      C     : Character;
      Is_Float, Checked_Leading_Zeroes : Boolean := False;

      Error_Dot_Message : constant String
        := "Number must contain at least one digit after decimal point";
      Error_Exp_Message : constant String
        := "Expected optional +/- sign after e/E and then at least one digit";
      Error_Plus_Message : constant String
        := "Prefixing number with '+' character is not allowed";
      Error_One_Digit_Message : constant String
        := "Expected at least one digit after +/- sign in number";
      Error_Length_Message : constant String
        := "Number is longer than" & Types.Maximum_String_Length_Numbers'Image & " characters";

      procedure Create_Token_From_Number is
         Number : constant String := SB.To_String (Value);
      begin
         if Is_Float then
            Next_Token := Token'(Kind => Float_Token,
              Float_Value => Types.Float_Type'Value (Number));
         else
            Next_Token := Token'(Kind => Integer_Token,
              Integer_Value => Types.Integer_Type'Value (Number));
         end if;
      end Create_Token_From_Number;
   begin
      if First = '+' then
         raise Tokenizer_Error with Error_Plus_Message;
      end if;
      SB.Append (Value, First);

      --  Accept sequence of digits, including leading zeroes
      loop
         Stream.Read_Character (C);
         exit when C not in '0' .. '9';
         SB.Append (Value, C);
      end loop;

      --  Test whether value contains leading zeroes
      Test_Leading_Zeroes (First, SB.To_String (Value));
      Checked_Leading_Zeroes := True;

      --  Tokenize fraction part
      if C = '.' then
         Is_Float := True;

         --  Append the dot
         SB.Append (Value, C);

         --  Require at least one digit after decimal point
         begin
            Stream.Read_Character (C);
            if C not in '0' .. '9' then
               raise Tokenizer_Error with Error_Dot_Message;
            end if;
            SB.Append (Value, C);
         exception
            when Ada.IO_Exceptions.End_Error =>
               raise Tokenizer_Error with Error_Dot_Message;
         end;

         --  Accept sequence of digits
         loop
            Stream.Read_Character (C);
            exit when C not in '0' .. '9';
            SB.Append (Value, C);
         end loop;
      end if;

      --  Tokenize exponent part
      if C in 'e' | 'E' then
         --  Append the 'e' or 'E' character
         SB.Append (Value, C);

         begin
            Stream.Read_Character (C);
            --  Append optional '+' or '-' character
            if C in '+' | '-' then
               --  If exponent is negative, number will be a float
               if C = '-' then
                  Is_Float := True;
               end if;

               SB.Append (Value, C);

               --  Require at least one digit after +/- sign
               Stream.Read_Character (C);
               if C not in '0' .. '9' then
                  raise Tokenizer_Error with Error_One_Digit_Message;
               end if;
               SB.Append (Value, C);
            elsif C in '0' .. '9' then
               SB.Append (Value, C);
            else
               raise Tokenizer_Error with Error_Exp_Message;
            end if;
         exception
            when Ada.IO_Exceptions.End_Error =>
               raise Tokenizer_Error with Error_Exp_Message;
         end;

         --  Accept sequence of digits
         loop
            Stream.Read_Character (C);
            exit when C not in '0' .. '9';
            SB.Append (Value, C);
         end loop;
      end if;

      Create_Token_From_Number;
      Stream.Write_Character (C);
   exception
      --  End_Error is raised if the number if followed by an EOF
      when Ada.IO_Exceptions.End_Error =>
         --  Test whether value contains leading zeroes
         if not Checked_Leading_Zeroes then
            Test_Leading_Zeroes (First, SB.To_String (Value));
         end if;

         Create_Token_From_Number;
      when Ada.Strings.Length_Error =>
         raise Tokenizer_Error with Error_Length_Message;
   end Read_Number;

   procedure Read_Literal
     (Stream     : in out Streams.Stream;
      First      : Character;
      Next_Token : out Token)
   is
      package SB is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 5);

      Value : SB.Bounded_String;
      C     : Character;

      Unexpected_Literal_Message : constant String
        := "Expected literal 'true', 'false', or 'null'";

      procedure Create_Token_From_Literal is
         Literal : constant String := SB.To_String (Value);
      begin
         if Literal = "true" then
            Next_Token := Token'(Kind => Boolean_Token, Boolean_Value => True);
         elsif Literal = "false" then
            Next_Token := Token'(Kind => Boolean_Token, Boolean_Value => False);
         elsif Literal = "null" then
            Next_Token := Token'(Kind => Null_Token);
         else
            raise Tokenizer_Error with Unexpected_Literal_Message;
         end if;
      end Create_Token_From_Literal;
   begin
      SB.Append (Value, First);
      loop
         Stream.Read_Character (C);
         exit when C not in 'a' .. 'z' or else SB.Length (Value) = SB.Max_Length;
         SB.Append (Value, C);
      end loop;

      Create_Token_From_Literal;
      Stream.Write_Character (C);
   exception
      --  End_Error is raised if the literal if followed by an EOF
      when Ada.IO_Exceptions.End_Error =>
         Create_Token_From_Literal;
      when Ada.Strings.Length_Error =>
         raise Tokenizer_Error with Unexpected_Literal_Message;
   end Read_Literal;

   procedure Read_Token
     (Stream     : in out Streams.Stream;
      Next_Token : out Token;
      Expect_EOF : Boolean := False)
   is
      C : Character;

      use Ada.Characters.Latin_1;
   begin
      loop
         --  Read the first next character and decide which token it could be part of
         Stream.Read_Character (C);

         --  Skip whitespace
         exit when C not in Space | HT | LF | CR;
      end loop;

      if Expect_EOF then
         raise Tokenizer_Error with "Expected to read EOF";
      end if;

      case C is
         when '[' =>
            Next_Token := Token'(Kind => Begin_Array_Token);
         when '{' =>
            Next_Token := Token'(Kind => Begin_Object_Token);
         when ']' =>
            Next_Token := Token'(Kind => End_Array_Token);
         when '}' =>
            Next_Token := Token'(Kind => End_Object_Token);
         when ':' =>
            Next_Token := Token'(Kind => Name_Separator_Token);
         when ',' =>
            Next_Token := Token'(Kind => Value_Separator_Token);
         when '"' =>
            Read_String (Stream, Next_Token);
         when '0' .. '9' | '+' | '-' =>
            Read_Number (Stream, C, Next_Token);
         when 'a' .. 'z' =>
            Read_Literal (Stream, C, Next_Token);
         when others =>
            raise Tokenizer_Error with "Unexpected character";
      end case;
   exception
      when Ada.IO_Exceptions.End_Error =>
         if Expect_EOF then
            Next_Token := Token'(Kind => EOF_Token);
         else
            raise Tokenizer_Error with "Unexpectedly read EOF";
         end if;
   end Read_Token;

end JSON.Tokenizers;
