(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Program:      PMOUSE - Pascal Mouse                                      */
/*                                                                           */
/*  Unit:         CharUtils                                                  */
/*                Utilities for detecting a character type.                  */
/*                                                                           */
/*  Originally by:                                                           */
/*  Programmer:   Dr Peter Grogono                                           */
/*                MOUSE: A Language for Microcomputers                       */
/*                Petrocelli Books, 1983                                     */
/*                                                                           */
/*  Translated from the book and corrections by:                             */
/*  Programmer:   David G. Simpson                                           */
/*                Laurel, Maryland                                           */
/*                February 3, 2002                                           */
/*                http://mouse.davidgsimpson.com/                            */
/*                                                                           */
/*  Further updates by:                                                      */
/*  Programmer:   Jessica K McIntosh                                         */
/*                https://github.com/JessicaKMcIntosh/pmouse                 */
/*                                                                           */
/*  Language:     Pascal                                                     */
/*                                                                           */
/*  Description:  This is an interpreter for the Mouse-83 programming        */
/*                language.                                                  */
/*                                                                           */
/*  Notes:        This interpreter is based on the original Pascal           */
/*                implementation in "Mouse: A Language for Microcomputers"   */
/*                by Peter Grogono.                                          */
/*                                                                           */
/*                Syntax:   MOUSE  <filename>                                */
/*                                                                           */
/*                If no file extension is given, an extension of ".mou" is   */
/*                assumed.                                                   */
/*                                                                           */
******************************************************************************)
unit CharUtils;

interface

function isdigit(check: char): boolean;
function islower(check: char): boolean;
function isupper(check: char): boolean;
function Value(digit: char): byte;
function uppercase(Character: char) :char;

implementation

{ Return True if the character is a number. }
function isdigit(check: char): boolean;
begin
  isdigit := check in ['0'..'9'];
end;  { isdigit }

{ Return True if the character is a lowercase latter. }
function islower(check: char): boolean;
begin
  islower := check in ['a'..'z'];
end;  { islower }

{ Return True if the character is a uppercase latter. }
function isupper(check: char): boolean;
begin
  isupper := check in ['A'..'Z'];
end;   { isupper }

{ Return the binary value of an ASCII digit. }
function Value(digit: char): byte;
begin
  Value := Ord(digit) - Ord('0');
end;  { value }

{ Convert a lower case letter to upper case. }
function uppercase(Character: char) :char;
begin
  if islower(Character) then
    Character := chr(Ord(Character) - Ord('a') + Ord('A'));
    uppercase := Character;
end;  { uppercase }

end.