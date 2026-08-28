--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.Build_Target; use type Adi.Build_Target.Platform_Kind;
with Adi.OS;
with Test_Support; use Test_Support;

procedure Os_Paths_Test is

   Windows : constant Boolean :=
     Adi.Build_Target.Platform = Adi.Build_Target.Windows;

   Sep : constant Character := Adi.OS.Path_Separator;

   --  Every variable Temp_Directory consults, so a case starts from a
   --  known state rather than from whatever the shell exported.
   procedure Clear_Env is
      use Ada.Environment_Variables;
   begin
      Clear ("TMPDIR");
      Clear ("TEMP");
      Clear ("TMP");
   end Clear_Env;

   procedure Set_Temp (Value : String) is
   begin
      Clear_Env;
      Ada.Environment_Variables.Set ("TMPDIR", Value);
   end Set_Temp;

   procedure Test_Joins_With_Separator is
   begin
      Section ("Temp_Path joins");
      Set_Temp ("/scratch");
      Assert (Adi.OS.Temp_Path ("a.css") = "/scratch" & Sep & "a.css",
              "Temp_Path puts the name inside Temp_Directory");
   end Test_Joins_With_Separator;

   procedure Test_Trailing_Separator_Trimmed is
   begin
      Section ("trailing separators");

      Set_Temp ("/scratch/");
      Assert (Adi.OS.Temp_Directory = "/scratch",
              "one trailing separator is dropped");
      Assert (Adi.OS.Temp_Path ("a.css") = "/scratch" & Sep & "a.css",
              "and the join stays single");

      Set_Temp ("/scratch///");
      Assert (Adi.OS.Temp_Directory = "/scratch",
              "repeated trailing separators are dropped");
      Assert (Adi.OS.Temp_Path ("a.css") = "/scratch" & Sep & "a.css",
              "a repeated run still joins singly");
   end Test_Trailing_Separator_Trimmed;

   procedure Test_Root_Keeps_Its_Separator is
   begin
      Section ("root directories");

      Set_Temp ("/");
      Assert (Adi.OS.Temp_Directory = "/",
              "the posix root is not trimmed away");
      Assert (Adi.OS.Temp_Path ("a.css") = "/a.css",
              "a root does not gain a second separator");

      Set_Temp ("//");
      Assert (Adi.OS.Temp_Path ("a.css") = "/a.css",
              "nor does a doubled root");

      Set_Temp ("C:\");
      Assert (Adi.OS.Temp_Directory = "C:\",
              "a drive root keeps its slash: C: alone is not the root");
      Assert (Adi.OS.Temp_Path ("a.css") = "C:\a.css",
              "and joins without doubling");
   end Test_Root_Keeps_Its_Separator;

   procedure Test_Precedence is
      use Ada.Environment_Variables;
   begin
      Section ("environment precedence");

      Clear_Env;
      Set ("TMP", "/from_tmp");
      Assert (Adi.OS.Temp_Directory = "/from_tmp", "TMP is used when alone");

      Set ("TEMP", "/from_temp");
      Assert (Adi.OS.Temp_Directory = "/from_temp", "TEMP outranks TMP");

      Set ("TMPDIR", "/from_tmpdir");
      Assert (Adi.OS.Temp_Directory = "/from_tmpdir",
              "TMPDIR outranks both");
   end Test_Precedence;

   procedure Test_Empty_Is_Not_A_Directory is
      use Ada.Environment_Variables;
   begin
      Section ("empty values");

      Clear_Env;
      Set ("TMPDIR", "");
      Set ("TEMP", "/from_temp");
      Assert (Adi.OS.Temp_Directory = "/from_temp",
              "an empty TMPDIR falls through to TEMP");
   end Test_Empty_Is_Not_A_Directory;

   procedure Test_Fallback is
   begin
      Section ("fallback");

      Clear_Env;
      Assert (Adi.OS.Temp_Directory =
                (if Windows then "C:\Windows\Temp" else "/tmp"),
              "with nothing set the platform default is used");
      Assert (Adi.OS.Temp_Path ("adi_mcp") =
                (if Windows then "C:\Windows\Temp\adi_mcp"
                 else "/tmp/adi_mcp"),
              "which is the MCP directory the tools expect");
   end Test_Fallback;

begin
   Start_Suite ("OS paths test");

   Test_Joins_With_Separator;
   Test_Trailing_Separator_Trimmed;
   Test_Root_Keeps_Its_Separator;
   Test_Precedence;
   Test_Empty_Is_Not_A_Directory;
   Test_Fallback;

   Finish;
end Os_Paths_Test;
