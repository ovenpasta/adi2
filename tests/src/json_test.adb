--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.JSON;     use Adi.JSON;
with Test_Support; use Test_Support;

--  What Adi.JSON reads back from text, through the vendored json-ada
procedure JSON_Test is

   function B (Code : Natural) return Character is (Character'Val (Code));

   --  Escapes are spelled out as BS & "u...", the text the parser sees
   BS : constant Character := '\';

   --  UTF-8 test texts. The second byte of each of the first four is in
   --  16#80# .. 16#9F#, which Latin-1 counts as control characters.
   E_Grave : constant String := B (16#C3#) & B (16#88#);           --  U+00C8
   Euro    : constant String := B (16#E2#) & B (16#82#) & B (16#AC#);
   Em_Dash : constant String := B (16#E2#) & B (16#80#) & B (16#94#);
   Emoji   : constant String :=
     B (16#F0#) & B (16#9F#) & B (16#98#) & B (16#80#);            --  U+1F600
   A_Grave : constant String := B (16#C3#) & B (16#A0#);           --  U+00E0
   --  U+FFFD, what a surrogate without its pair reads as: it has no UTF-8
   Replacement : constant String := B (16#EF#) & B (16#BF#) & B (16#BD#);

   --  True if the JSON string literal Literal (without quotes) parses
   --  and its value reads as Expected
   function Reads_As (Literal, Expected : String) return Boolean is
   begin
      declare
         P    : Parsers.Parser := Parsers.Create ("[""" & Literal & """]");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         return Root.Get (1).Value = Expected;
      end;
   exception
      when others =>
         return False;
   end Reads_As;

   --  True if the only key of {"Literal": 1} reads as Expected
   function Key_Reads_As (Literal, Expected : String) return Boolean is
   begin
      declare
         P     : Parsers.Parser := Parsers.Create ("{""" & Literal & """: 1}");
         Root  : constant Types.JSON_Value := P.Parse;
         Found : Boolean := False;
      begin
         for Key of Root loop
            Found := Key.Value = Expected;
         end loop;
         return Found;
      end;
   exception
      when others =>
         return False;
   end Key_Reads_As;

   --  True if parsing Text raises Parse_Error, rather than succeeding or
   --  raising anything else
   function Is_Parse_Error (Text : String) return Boolean is
   begin
      declare
         P    : Parsers.Parser := Parsers.Create (Text);
         Root : constant Types.JSON_Value := P.Parse;
         pragma Unreferenced (Root);
      begin
         return False;
      end;
   exception
      when Parsers.Parse_Error =>
         return True;
      when others =>
         return False;
   end Is_Parse_Error;

   --  True if {"Literal": 1} has the key Key, by Contains and by Get
   function Has_Key (Literal, Key : String) return Boolean is
   begin
      declare
         P    : Parsers.Parser := Parsers.Create ("{""" & Literal & """: 1}");
         Root : constant Types.JSON_Value := P.Parse;
      begin
         if not Root.Contains (Key) then
            return False;
         end if;
         return Long_Integer (JSON_Integer'(Root.Get (Key).Value)) = 1;
      end;
   exception
      when others =>
         return False;
   end Has_Key;

   procedure Test_Raw_UTF_8 is
   begin
      Section ("Raw UTF-8 in strings");

      Assert (Reads_As (A_Grave, A_Grave),
              "U+00E0 reads back unchanged");
      Assert (Reads_As (E_Grave, E_Grave),
              "U+00C8 (second byte 16#88#) reads back unchanged");
      Assert (Reads_As (Euro, Euro),
              "U+20AC (second byte 16#82#) reads back unchanged");
      Assert (Reads_As (Em_Dash, Em_Dash),
              "U+2014 (second byte 16#80#) reads back unchanged");
      Assert (Reads_As (Emoji, Emoji),
              "U+1F600 (four bytes) reads back unchanged");
      Assert (Reads_As ("a" & B (16#7F#) & "b", "a" & B (16#7F#) & "b"),
              "DEL needs no escape and reads back unchanged");
      Assert (Key_Reads_As (Euro, Euro),
              "a key holding U+20AC reads back unchanged");
   end Test_Raw_UTF_8;

   procedure Test_Unicode_Escapes is
   begin
      Section ("Unicode escapes");

      Assert (Reads_As (BS & "u0041", "A"),
              "escape u0041 reads as A");
      Assert (Reads_As (BS & "u00e0", A_Grave),
              "escape u00e0 reads as the two UTF-8 bytes of U+00E0");
      Assert (Reads_As (BS & "u20AC", Euro),
              "escape u20AC (upper-case hex) reads as the bytes of U+20AC");
      Assert (Reads_As (BS & "u001b", [1 => B (16#1B#)]),
              "escape u001b reads as ESC");
      Assert (Reads_As (BS & "u0000", [1 => B (0)]),
              "escape u0000 reads as NUL");
      Assert (Reads_As ("gi" & BS & "u00e0 fatto", "gi" & A_Grave & " fatto"),
              "an escape among plain characters");
      Assert (Key_Reads_As ("gi" & BS & "u00e0", "gi" & A_Grave),
              "an escape in a key");

      Section ("Surrogate pairs");

      Assert (Reads_As (BS & "uD83D" & BS & "uDE00", Emoji),
              "escape uD83D uDE00 reads as the four bytes of U+1F600");
      Assert (Reads_As (BS & "udbff" & BS & "udfff",
                        B (16#F4#) & B (16#8F#) & B (16#BF#) & B (16#BF#)),
              "escape udbff udfff reads as U+10FFFF");

      Section ("Lone surrogates and bad escapes");

      Assert (Reads_As (BS & "uD800", Replacement),
              "a high surrogate alone reads as U+FFFD");
      Assert (Reads_As (BS & "uDC00", Replacement),
              "a low surrogate alone reads as U+FFFD");
      Assert (Reads_As (BS & "uD800abc", Replacement & "abc"),
              "a high surrogate followed by text reads as U+FFFD and the text");
      Assert (Reads_As (BS & "uD800" & BS & "uD800", Replacement & Replacement),
              "two high surrogates read as two U+FFFD");
      Assert (Reads_As (BS & "uDE00" & BS & "uD83D", Replacement & Replacement),
              "a pair in the wrong order reads as two U+FFFD");
      Assert (Reads_As (BS & "uD800" & BS & "u0041", Replacement & "A"),
              "a high surrogate before another escape: U+FFFD, then A");
      Assert (Is_Parse_Error ("[""" & BS & "u00G0""]"),
              "a non-hex digit raises Parse_Error");
      Assert (Is_Parse_Error ("[""" & BS & "u00""]"),
              "fewer than four digits raise Parse_Error");
      Assert (Is_Parse_Error ("[""" & BS & "u00"),
              "text ending inside an escape raises Parse_Error");
   end Test_Unicode_Escapes;

   --  Contains and Get find a key by what it decodes to, as Value and
   --  iteration read it, never by its escaped text
   procedure Test_Key_Lookup is
   begin
      Section ("Keys looked up by their decoded text");

      Assert (Has_Key ("a", "a"), "a plain key");
      Assert (not Has_Key ("a", "b"), "a plain key does not match another");
      Assert (Has_Key ("a" & BS & BS & "b", "a" & BS & "b"),
              "an escaped backslash matches one backslash");
      Assert (not Has_Key ("a" & BS & BS & "b", "a" & BS & BS & "b"),
              "an escaped backslash does not match its escaped text");
      Assert (Has_Key ("say " & BS & """hi" & BS & """", "say ""hi"""),
              "escaped quotes match plain quotes");
      Assert (Has_Key (BS & "u20AC", Euro), "a u20AC escape matches U+20AC");
      Assert (not Has_Key (BS & "u20AC", BS & "u20AC"),
              "a u20AC escape does not match its escaped text");
      Assert (not Has_Key (BS & "u20AC", "x"),
              "an escaped key does not match another");
      Assert (not Has_Key (BS & "u20AC" & "x", "x"),
              "nor a lookup shorter than its decoded text");
   end Test_Key_Lookup;

begin
   Start_Suite ("Adi.JSON Test Suite");

   Test_Raw_UTF_8;
   Test_Unicode_Escapes;
   Test_Key_Lookup;

   Finish;
end JSON_Test;
