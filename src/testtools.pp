(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Unit:         testtools - Tools for running tests.                       */
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
unit testtools;

{$mode objfpc}
{$h+}

interface

uses Process, sysutils;

function RunProcessWithInput(executable, parameter: string; input: array of string) : string;

implementation

{ Execute a process that takes input and return the output. }
function RunProcessWithInput(executable, parameter: string; input: array of string) : string;
var
  TestProcess: TProcess;
  Buffer: array[0..1024] of char;
  ReadSize: Integer;
  item: string;
  output: string;
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
    TestProcess.Output.Read(Buffer, ReadSize)
  else
    Buffer := '';

  { Free the process. }
  TestProcess.Free;

  { Return the output. }
  SetString(output, Buffer, ReadSize);
  RunProcessWithInput := output;
end;

end.