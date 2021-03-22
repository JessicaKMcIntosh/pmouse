(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Unit:         testutil - Tests the unit charutil.pas                     */
/*                                                                           */
/*  Programmer:   Jessica K McIntosh                                         */
/*                https://github.com/JessicaKMcIntosh/pmouse                 */
/*                                                                           */
/*  Language:     Pascal                                                     */
/*                                                                           */
/*  Description:  Test runner for the various test Units.                    */
/*                                                                           */
/*  Notes:        Taken from the fpcunit example needassert.pp.              */
/*                                                                           */
******************************************************************************)
unit testutil;

{$mode objfpc}
{$h+}

interface

uses fpcunit, testregistry, consoletestrunner, charutil;

type
  TTestUtil = class(TTestCase)
  published
    Procedure isdigit_True;
    Procedure isgitit_False;
    Procedure islower_True;
    Procedure islower_False;
    Procedure isupper_True;
    Procedure isupper_False;
    Procedure test_charvalue;
    Procedure test_uppercase;
  end;

implementation

Procedure TTestUtil.isdigit_True;
var
  testChar: char;
begin
  for testChar := '0' to '9' do
    AssertTrue('Test that "' + testChar + '" is a digit.', isdigit(testChar));
end;

Procedure TTestUtil.isgitit_False;
var
  testChar: char;
begin
  for testChar := 'A' to 'a' do
    AssertFalse('Test that "' + testChar + '" is NOT a digit.', isdigit(testChar));
end;

Procedure TTestUtil.islower_True;
var
  testChar: char;
begin
  for testChar := 'a' to 'z' do
    AssertTrue('Test that "' + testChar + '" is lowercase.', islower(testChar));
end;

Procedure TTestUtil.islower_False;
var
  testChar: char;
begin
  for testChar := 'A' to 'A' do
    AssertFalse('Test that "' + testChar + '" is NOT lowercase.', islower(testChar));
end;

Procedure TTestUtil.isupper_True;
var
  testChar: char;
begin
  for testChar := 'A' to 'Z' do
    AssertTrue('Test that "' + testChar + '" is uppercase.', isupper(testChar));
end;

Procedure TTestUtil.isupper_False;
var
  testChar: char;
begin
  for testChar := 'a' to 'z' do
    AssertFalse('Test that "' + testChar + '" is NOT uppercase.', isupper(testChar));
end;

procedure TTestUtil.test_charvalue;
begin
  AssertTrue('Test that value returns the correct number.', (charvalue('0') = 0));
end;

procedure TTestUtil.test_uppercase;
var
  testChar: char;
begin
  for testChar := 'a' to 'z' do
    AssertEquals('Testing uppercasing "' + testChar + '".', upcase(testChar), uppercase(testChar));
end;

end.