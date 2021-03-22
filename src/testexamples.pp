(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Unit:         testexamples - Tests pmouse using the example files.       */
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
unit testexamples;

{$mode objfpc}
{$h+}

interface

uses fpcunit, testregistry, consoletestrunner, Process;

type
  TTestExamples = class(TTestCase)
  published
    Procedure test_mou;

  end;

const
  test_mou_output = LineEnding +
    'Arithmetic Expressions: 1000=1000=1000=1000=1000=1000' + LineEnding +
    'Boolean Expressions: 0=0=0=0=0=0=0=0=0    1=1=1=1=1=1=1=1=1' + LineEnding +
    'Assignments: 1000=1000=1000=1000' + LineEnding +
    'Conditional Statements: OK' + LineEnding +
    'Loops: 0 1 2 3 4 5 6 7 8 9 10 ' + LineEnding +
    '' + LineEnding +
    '   0 0 0 0 0 0 ' + LineEnding +
    '   0 1 2 3 4 5 ' + LineEnding +
    '   0 2 4 6 8 10 ' + LineEnding +
    '   0 3 6 9 12 15 ' + LineEnding +
    '   0 4 8 12 16 20 ' + LineEnding +
    '   0 5 10 15 20 25 ' + LineEnding +
    '   ' + LineEnding +
    'Macro Calls:  A: OK' + LineEnding +
    'Parameters:  B: OK OK C: 10=10 D: 10=10' + LineEnding +
    'Scope of Variables:  E: 1000=1000' + LineEnding +
    'Recursive Macros:  G: 2 3 3 5 7 ' + LineEnding +
    'End of tests.' + LineEnding;

implementation

Procedure TTestExamples.test_mou;
var
  output: string;
begin
  RunCommand('pmouse',['examples' + DirectorySeparator + 'test.mou'],output);
  AssertEquals('Testing "test.mou".', output, test_mou_output);
end;

end.