program runtests;

{$mode objfpc}
{$h+}

uses fpcunit, testregistry, consoletestrunner, charutil, testutil;

Var
  Application : TTestRunner;

begin
  RegisterTest(TTestUtil);
  TTestCase.CheckAssertCalled:=true;
  DefaultFormat:=fPlain;
  DefaultRunAllTests:=True;
  Application:=TTestRunner.Create(Nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.