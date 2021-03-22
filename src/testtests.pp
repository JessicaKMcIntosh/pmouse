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

implementation

Procedure TTestTests.testelse_mou;
var
  output: string;
begin
  RunCommand('pmouse',['tests' + DirectorySeparator + 'testelse.mou'],output);
  AssertEquals('Testing "testelse.mou".', output, testelse_mou_output);
end;

end.