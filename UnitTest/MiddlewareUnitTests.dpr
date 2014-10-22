program MiddlewareUnitTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

//use MadExcept or Jcl to get linenumber of errors!
//{$IFNDEF USE_JEDI_JCL} {$MESSAGE ERROR 'Must define "USE_JEDI_JCL" for location info of errors'} {$ENDIF}

uses
  {$ifdef USEFASTMM4}
  FastMM4,
  FastMM4Messages,
  {$endif}
  SysUtils,
  Forms,
  TestFramework, // in 'c:\program files (x86)\embarcadero\rad studio\10.0\source\DUnit\src\TestFramework.pas',
  TextTestRunner,
  GUITestRunner,
  DB.Connector in '..\DB\DB.Connector.pas',
  DB.Settings,
  DB.Connection.SQLServer in '..\DB\DB.Connection.SQLServer.pas',
  DB.Provider.ADO in '..\DB\DB.Provider.ADO.pas',
  DB.Settings.SQLServer in '..\DB\DB.Settings.SQLServer.pas',
  Data.CustomTypes in '..\Data\Data.CustomTypes.pas',
  Data.DataRecord in '..\Data\Data.DataRecord.pas',
  Data.CRUD in '..\Data\Data.CRUD.pas',
  Meta.CustomIDTypes in 'TestCrud\Meta.CustomIDTypes.pas',
  UltraStringUtils in '..\Func\UltraStringUtils.pas',
  MWUtils in '..\Func\MWUtils.pas',
  Test.CRUD in 'Test.CRUD.pas',
  Test.DataRecord in 'Test.DataRecord.pas',
  TestProfilerXMLLogger in 'TestProfilerXMLLogger.pas',
  Test.QueryBuilder in 'Test.QueryBuilder.pas',
  CRUD.TEST in 'TestCrud\CRUD.TEST.pas',
  Meta.TEST in 'TestCrud\Meta.TEST.pas';

procedure RegisterTests;
begin
  RegisterTest(TDataRecordTester.Suite);
  RegisterTest(TCRUDTester.Suite);
  RegisterTest(TQueryTester.Suite);
end;

function doXmlOutput: boolean;
var parIndex : integer;
begin
  Result := false;
  if ParamCount > 0 then
    for parIndex := 1 to ParamCount do
      if LowerCase(ParamStr(parIndex)) = '-xml' then
        Exit(True);
end;

var
  testresult: TTestResult;
begin
  ReportMemoryLeaksOnShutdown := True;
  {$ifdef USEFASTMM4}
  FastMM4.SetMMLogFileName(
    PAnsiChar(Ansistring(
      ExtractFilePath(Application.ExeName) +
        'FastMM_' + ExtractFileName(Application.ExeName) +
        '.' + FormatDateTime('hhnnsszz', Now) + '.log'
    ))
  );
  {$endif}

  Application.Initialize;
  //"manual" register in specific order instead of done in "Initialization" section per unit
  RegisterTests;

  AddSQLDatabaseSettings('', 'TestDB.sdf',
              '', '', '', True, '',
              dbtSQLServerCE);
  //create CE db with TEST table
  DeleteFile('TestDB.sdf');
  CreateSQLCeDatabase('TestDB.sdf');
  CRUD.TEST.TESTCRUD.QueryCreateTable();

  if doXmlOutput then
  begin
    testresult := TestFramework.RunTest(RegisteredTests,
                                        [//TXMLTestListener.Create('DUnitTesting.xml'),
                                         //extra logging in xml, excluded from html via empty xls template
                                         TTestProfilerXMLLogger.Create('DUnitTesting.xml')
                                        ]);
    //note: execute XMLtoHTML.bat to get nice html result page
    testresult.Free;
  end
  else
  begin
    if IsConsole then
      with TextTestRunner.RunRegisteredTests do
        Free
    else
      GUITestRunner.RunRegisteredTests;
  end;
end.

