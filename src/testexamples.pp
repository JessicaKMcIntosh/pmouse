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

uses fpcunit, testregistry, consoletestrunner, Process, sysutils;

type
  TTestExamples = class(TTestCase)
  published
    Procedure test_mou;
    Procedure mcdonald_mou;
    Procedure bottles_mou;
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
  mcdonald_mou_output =
    '' + LineEnding +
    '' + LineEnding +
    'How many verses? ' + LineEnding +
    '' + LineEnding +
    'Old MacDonald had a farm, ee-igh, ee-igh, oh,' + LineEnding +
    'And on this farm he had some chicks, ee-igh, ee-igh, oh,' + LineEnding +
    'With a Chick Chick here and a Chick Chick there,' + LineEnding +
    'Here a Chick,there a Chick,everywhere a Chick Chick,' + LineEnding +
    'Old MacDonald had a farm, ee-igh, ee-igh, oh.' + LineEnding +
    '' + LineEnding +
    'Old MacDonald had a farm, ee-igh, ee-igh, oh,' + LineEnding +
    'And on this farm he had some ducks, ee-igh, ee-igh, oh,' + LineEnding +
    'With a Quack Quack here and a Quack Quack there,' + LineEnding +
    'Here a Quack,there a Quack,everywhere a Quack Quack,' + LineEnding +
    'Chick Chick here and a Chick Chick there,' + LineEnding +
    'Here a Chick,there a Chick,everywhere a Chick Chick,' + LineEnding +
    'Old MacDonald had a farm, ee-igh, ee-igh, oh.' + LineEnding +
    '' + LineEnding +
    'How many verses? ';
  bottles_mou_output =
    'HOW MANY VERSES? TWO GREEN BOTTLES STANDING ON THE WALL,' + LineEnding +
    'TWO GREEN BOTTLES;' + LineEnding +
    'IF ONE OF THOSE BOTTLES SHOULD HAPPEN TO FALL,' + LineEnding +
    'ONE GREEN BOTTLES STANDING ON THE WALL.' + LineEnding +
    '' + LineEnding +
    'ONE GREEN BOTTLES STANDING ON THE WALL,' + LineEnding +
    'ONE GREEN BOTTLES;' + LineEnding +
    'IF ONE OF THOSE BOTTLES SHOULD HAPPEN TO FALL,' + LineEnding +
    'NO GREEN BOTTLES STANDING ON THE WALL.' + LineEnding +
    '' + LineEnding +
    'HOW MANY VERSES? ';

implementation

{ A test program that exercises various bits of standard mouse. }
Procedure TTestExamples.test_mou;
var
  output: string;
begin
  RunCommand('pmouse',['examples' + DirectorySeparator + 'test.mou'],output);
  AssertEquals('Testing "test.mou".', test_mou_output, output);
end;

{ Execute a process that takes input and return the output. }
function RunProcessWithInput(executable, parameter: string; input: array of string) : string;
var
  TestProcess: TProcess;
  Buffer: array[0..1024] of char;
  ReadCount: Integer;
  ReadSize: Integer;
  item: string;
begin
  { Setup the process. }
  TestProcess            := TProcess.Create(nil);
  TestProcess.Options    := [poUsePipes,poStderrToOutPut];
  TestProcess.Executable := executable;
  TestProcess.Parameters.Add(parameter);
  TestProcess.Execute;

  { Send the input to the program. }
  for item in input do
  begin
    Buffer :=  item + LineEnding;
    TestProcess.Input.Write(Buffer, length(Buffer));
  end;
  TestProcess.CloseInput;

  { Wait for the process to finish. }
  while TestProcess.Running do
    Sleep(1);

  { Read the output. }
  ReadSize := TestProcess.Output.NumBytesAvailable;
  if ReadSize > SizeOf(Buffer) then
    ReadSize := SizeOf(Buffer);
  if ReadSize > 0 then
  begin
    ReadCount := TestProcess.Output.Read(Buffer, ReadSize);
    WriteLn(Copy(Buffer,0, ReadCount));
  end
  else
    Buffer := '';

  { Free the process. }
  TestProcess.Free;

  { Return the output. }
  RunProcessWithInput := Buffer;

end;

{
  The example mcdonald.mou asks for input.
  Without input it will hang.
  This is the 'Old MacDonald' song.
}
Procedure TTestExamples.mcdonald_mou;
var
  output: string;
  input: array [1..2] of string = ('2', '0');
begin
  output := RunProcessWithInput('pmouse', 'examples/mcdonald.mou', input);
  AssertEquals('Testing "mcdonald.mou".', mcdonald_mou_output, output);
end;

{
  The example mcdonald.mou asks for input.
  Without input it will hang.
  This is a common variation of the 'Bottles on the wall' song.
}
Procedure TTestExamples.bottles_mou;
var
  output: string;
  input: array [1..2] of string = ('2', '0');
begin
  output := RunProcessWithInput('pmouse', 'examples/bottles.mou', input);
  AssertEquals('Testing "bottles.mou".', bottles_mou_output, output);
end;

end.