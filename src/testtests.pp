(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Unit:         testtests - Tests pmouse using the test files.             */
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
unit testtests;

{$mode objfpc}
{$h+}

interface

uses fpcunit, testregistry, consoletestrunner, Process;

type
  TTestTests = class(TTestCase)
  published
    Procedure testelse_mou;
    Procedure testtrc_mou;
    Procedure testfor_mou;
  end;

const
  testelse_mou_output =
    'OK-1  ' + LineEnding +
    'OK-2  OK-3  ' + LineEnding +
    'OK-4  OK-5  ' + LineEnding +
    'OK-6  OK-7  OK-8  ' + LineEnding +
    'OK-9  OK-10  OK-11  ' + LineEnding +
    'OK-12  OK-13  ' + LineEnding +
    'OK-14  OK-15  OK-16  OK-17  ' + LineEnding +
    'OK-18  OK-19  OK-20  OK-21  OK-22  OK-23  OK-24  OK-25  ' + LineEnding;
    testtrc_mou_output =
      '                                      {1 2 3++!}$                              ' + LineEnding +
      '                                       ^ SP: 0 Stack: NULL' + LineEnding +
      '                                    {1 2 3++!}$                                ' + LineEnding +
      '                                       ^ SP: 1 Stack: 1' + LineEnding +
      '                                  {1 2 3++!}$                                  ' + LineEnding +
      '                                       ^ SP: 2 Stack: 2, 1' + LineEnding +
      '                                 {1 2 3++!}$                                   ' + LineEnding +
      '                                       ^ SP: 3 Stack: 3, 2, 1' + LineEnding +
      '                                {1 2 3++!}$                                    ' + LineEnding +
      '                                       ^ SP: 2 Stack: 5, 1' + LineEnding +
      '                               {1 2 3++!}$                                     ' + LineEnding +
      '                                       ^ SP: 1 Stack: 6' + LineEnding +
      '6                              {1 2 3++!}$                                      ' + LineEnding +
      '                                       ^ SP: 0 Stack: NULL' + LineEnding;
    testfor_mou_output =
      '1  2  3  4  5  6  7  8  9  10  ' + LineEnding +
      '10  9  8  7  6  5  4  3  2  1  ' + LineEnding;

implementation

{ Tests the new else statement that David G. Simpson came up with. }
Procedure TTestTests.testelse_mou;
var
  output: string;
begin
  RunCommand('pmouse',['tests' + DirectorySeparator + 'testelse.mou'],output);
  AssertEquals('Testing "testelse.mou".', testelse_mou_output, output);
end;

{ Tests the trace functionality. }
Procedure TTestTests.testtrc_mou;
var
  output: string;
begin
  RunCommand('pmouse',['tests' + DirectorySeparator + 'testtrc.mou'],output);
  AssertEquals('Testing "testtrc.mou".', testtrc_mou_output, output);
end;

{ Tests for loops. }
Procedure TTestTests.testfor_mou;
var
  output: string;
begin
  RunCommand('pmouse',['tests' + DirectorySeparator + 'testfor.mou'],output);
  AssertEquals('Testing "testfor.mou".', testfor_mou_output, output);
end;

end.