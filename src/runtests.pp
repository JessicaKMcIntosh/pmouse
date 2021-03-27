(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Program:      RUNTESTS - Run various tests against pmouse.               */
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
program runtests;

{$mode objfpc}
{$h+}

uses  fpcunit, testregistry, consoletestrunner, charutil,
      testutil, testexamples, testtests;

Var
  Application : TTestRunner;

begin
  RegisterTest(TTestUtil);
  RegisterTest(TTestExamples);
  RegisterTest(TTestTests);
{$IF FPC_FULLVERSION > 30100}
  TTestCase.CheckAssertCalled:=true;
{$ENDIF}
  DefaultFormat:=fPlain;
  DefaultRunAllTests:=True;
  Application:=TTestRunner.Create(Nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.