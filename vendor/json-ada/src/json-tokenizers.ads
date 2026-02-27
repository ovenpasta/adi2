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

with JSON.Types;
with JSON.Streams;

generic
   with package Types is new JSON.Types (<>);
package JSON.Tokenizers with SPARK_Mode => On is
   pragma Preelaborate;

   type Token_Kind is
     (Begin_Array_Token,
      Begin_Object_Token,
      End_Array_Token,
      End_Object_Token,
      Name_Separator_Token,
      Value_Separator_Token,
      String_Token,
      Integer_Token,
      Float_Token,
      Boolean_Token,
      Null_Token,
      EOF_Token,
      Invalid_Token);

   type Token (Kind : Token_Kind := Invalid_Token) is record
      case Kind is
         when String_Token =>
            String_Offset, String_Length : Streams.AS.Stream_Element_Offset;
         when Integer_Token =>
            Integer_Value : Types.Integer_Type;
         when Float_Token =>
            Float_Value   : Types.Float_Type;
         when Boolean_Token =>
            Boolean_Value : Boolean;
         when others =>
            null;
      end case;
   end record;

   procedure Read_Token
     (Stream     : in out Streams.Stream;
      Next_Token : out Token;
      Expect_EOF : Boolean := False)
   with Post => Next_Token.Kind /= Invalid_Token and Expect_EOF = (Next_Token.Kind = EOF_Token);

   Tokenizer_Error : exception;

end JSON.Tokenizers;
