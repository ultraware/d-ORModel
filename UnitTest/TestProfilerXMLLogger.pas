unit TestProfilerXMLLogger;

interface
uses
  SysUtils,
  Classes,
  TestFramework, Generics.Collections;

const
   DEFAULT_FILENAME = 'dunit-profile.xml';

type
  TTestProfilerXMLLogger = class(TInterfacedObject,
                                 ITestListener, ITestListenerX)
  private
     FOutput: THandle;
     FFileName : String;
     FFilePos_teststart, FFilePos_testend: Int64;
     FSuiteDurations: TStack<TDateTime>;

     class var FActiveInstance: TTestProfilerXMLLogger;
  protected
     FTestStartTime,
     startTime : TDateTime;
     procedure WriteReport(const aStr: string; aOverwriteFromStart: Int64 = 0; aOverwriteTillEnd: Int64 = 0);
  protected
    {ITestListener}
    procedure TestingStarts; virtual;
    procedure StartTest(test: ITest); virtual;

    procedure AddSuccess(test: ITest); virtual;
    procedure AddError(error: TTestFailure); virtual;
    procedure AddFailure(failure: TTestFailure); virtual;

    procedure EndTest(test: ITest); virtual;
    procedure TestingEnds(testResult: TTestResult); virtual;

    function  ShouldRunTest(test :ITest):boolean; virtual;

    {ITestListenerX}
    procedure StartSuite(suite: ITest); virtual;
    procedure EndSuite(suite: ITest); virtual;
  public
    constructor Create; overload;
    constructor Create(outputFile : String); overload;
    procedure   AfterConstruction;override;
    destructor  Destroy; override;

    procedure AddLog(const aStr: string);

    procedure Status (test:ITest; const Msg: string);
    procedure Warning(test:ITest; const Msg: string);

    class function RunTest(suite: ITest; outputFile:String): TTestResult; overload;
    class function RunRegisteredTests(outputFile:String): TTestResult;
    class function text2sgml(const text: String): String;
    class function StringReplaceAll(const text,byt,mot: string): string;

    //:Report filename. If an empty string, then standard output is used (compile with -CC option)
    property FileName : String read FFileName write FFileName;

    class function ActiveInstance: TTestProfilerXMLLogger;
  end;

{: Run the given test suite
}
function RunTest(suite: ITest; outputFile:String=DEFAULT_FILENAME): TTestResult; overload;
function RunRegisteredTests(outputFile:String=DEFAULT_FILENAME): TTestResult; overload;

implementation

uses
  Windows;

const
   CRLF = #13#10;
   MAX_DEEP = 5;

//JwaWinBase
type
  PLARGE_INTEGER = ^LARGE_INTEGER;
  HANDLE = Windows.THandle;
function SetFilePointerEx(hFile: HANDLE; liDistanceToMove: LARGE_INTEGER;
  lpNewFilePointer: PLARGE_INTEGER; dwMoveMethod: DWORD): BOOL; stdcall; external kernel32 name 'SetFilePointerEx';
function GetFileSizeEx(hFile: HANDLE; var lpFileSize: LARGE_INTEGER): BOOL; stdcall; external kernel32 name 'GetFileSizeEx';

{ TXMLTestListener }

constructor TTestProfilerXMLLogger.Create;
begin
  inherited Create;
  FileName := DEFAULT_FILENAME;
end;

constructor TTestProfilerXMLLogger.Create(outputFile : String);
begin
  inherited Create;
  FileName := outputFile;
end;

procedure TTestProfilerXMLLogger.AfterConstruction;
begin
  inherited;
  FSuiteDurations := TStack<TDateTime>.Create;
  FActiveInstance := Self;
end;

destructor TTestProfilerXMLLogger.Destroy;
begin
  FActiveInstance := nil;
  FSuiteDurations.Free;
  inherited;
end;

procedure TTestProfilerXMLLogger.WriteReport(const aStr: string; aOverwriteFromStart: Int64 = 0; aOverwriteTillEnd: Int64 = 0);
var
  iwritten: Cardinal;
  filepos: _LARGE_INTEGER;
  sText: string;
  sUTf8: UTF8String;
begin
  if FOutput <> 0 then
  begin
    if aOverwriteFromStart > 0 then
    begin
      filepos.QuadPart := aOverwriteFromStart;
      //move back
      if not SetFilePointerEx(FOutput, filepos, @filepos, FILE_BEGIN) then RaiseLastOSError;

      sText := aStr;
      //check string length: may no overwrite other stuff
      if Length(sText) > (aOverwriteTillEnd - aOverwriteFromStart) then
        sText := Copy(sText, 1, aOverwriteTillEnd - aOverwriteFromStart)
      //smaller? then add spaces (to overwrite old tags etc)
      else if Length(sText) < (aOverwriteTillEnd - aOverwriteFromStart) then
        sText := sText + StringOfChar(' ', (aOverwriteTillEnd - aOverwriteFromStart) - Length(sText));

      //write
      try
        sUTf8 := UTF8Encode(sText);
        if not Windows.WriteFile(FOutput, sUTf8[1], Length(sUTf8), iwritten, nil) then RaiseLastOSError;
      finally
        //always restore to end of file
        if not GetFileSizeEx(FOutput, filepos) then RaiseLastOSError;
        if not SetFilePointerEx(FOutput, filepos, @filepos, FILE_BEGIN) then RaiseLastOSError;
      end;
    end
    else
    begin
      sUTf8 := UTF8Encode(aStr);
      if not Windows.WriteFile(FOutput, sUTf8[1], Length(sUTf8), iwritten, nil) then
        RaiseLastOSError;
    end;
  end;
end;

procedure TTestProfilerXMLLogger.TestingStarts;
begin
  startTime := now;

  if FFileName <> '' then
  begin
    if FOutput <> 0 then
      CloseHandle(FOutput);

    FOutput := FileCreate(FFileName, fmShareDenyNone);
    if (FOutput = INVALID_HANDLE_VALUE) then
      RaiseLastOSError;
  end;

  WriteReport('<?xml version="1.0" encoding="ISO-8859-1" standalone="yes" ?>'+CRLF+
              '<TestRun>'+CRLF);
  FlushFileBuffers(FOutput);
end;

procedure TTestProfilerXMLLogger.StartSuite(suite: ITest);
begin
  WriteReport('  <TestSuite name="'+suite.getName+'">'+CRLF);
  FSuiteDurations.Push(Now);
end;

procedure TTestProfilerXMLLogger.StartTest(test: ITest);
var
  filepos: _LARGE_INTEGER;
begin
  FTestStartTime := Now;

  //no sub tests? so the "real" single test
  if test.tests.Count<=0 then
  begin
    //get file pos: GetFileSize or:
    //You can also use the SetFilePointer function to query the current file pointer position.
    //To do this, specify a move method of FILE_CURRENT and a distance of 0 (zero).
    filepos.QuadPart := 0;
    if SetFilePointerEx(FOutput, filepos, @filepos, FILE_CURRENT) then
      FFilePos_teststart := filepos.QuadPart
    else
      RaiseLastOSError;

    //write temp start tag, will be overwritten later
    WriteReport('    <Test name="'+test.GetName+'" result="BUSY" duration="' + FormatDateTime('hh:nn:ss.zzz', 0) + '">'+CRLF);

    //get file pos of end, boundary till which it can be overwritten
    filepos.QuadPart := 0;
    if SetFilePointerEx(FOutput, filepos, @filepos, FILE_CURRENT) then
      FFilePos_testend := filepos.QuadPart
    else
      RaiseLastOSError;
  end;
end;

procedure TTestProfilerXMLLogger.AddSuccess(test: ITest);
begin
  //no sub tests? so the "real" single test
  if test.tests.Count<=0 then
  begin
     WriteReport('    <Test name="'+test.GetName+'" result="PASS" duration="' + FormatDateTime('hh:nn:ss.zzz', Now - FTestStartTime) + '">'+CRLF,
                 FFilePos_teststart, FFilePos_testend);
  end;
end;

class function TTestProfilerXMLLogger.ActiveInstance: TTestProfilerXMLLogger;
begin
  Result := FActiveInstance;
end;

procedure TTestProfilerXMLLogger.AddError(error: TTestFailure);
begin
   WriteReport('    <Test name="'+error.FailedTest.GetName+'" result="ERROR" duration="' + FormatDateTime('hh:nn:ss.zzz', Now - FTestStartTime) + '">'+CRLF,
               FFilePos_teststart, FFilePos_testend);

   WriteReport('<FailureType>'+error.ThrownExceptionName+'</FailureType>'+CRLF+
               '<Location>'+error.LocationInfo+'</Location>'+CRLF+
               '<Message>'+text2sgml(error.ThrownExceptionMessage)+'</Message>'+CRLF);
end;

procedure TTestProfilerXMLLogger.AddFailure(failure: TTestFailure);
begin
   WriteReport('    <Test name="'+failure.FailedTest.GetName+'" result="FAILS" duration="' + FormatDateTime('hh:nn:ss.zzz', Now - FTestStartTime) + '">'+CRLF,
               FFilePos_teststart, FFilePos_testend);

   WriteReport('    <FailureType>'+failure.ThrownExceptionName+'</FailureType>'+CRLF+
               '    <Location>'+failure.LocationInfo+'</Location>'+CRLF+
               '    <Message>'+text2sgml(failure.ThrownExceptionMessage)+'</Message>'+CRLF);
end;

procedure TTestProfilerXMLLogger.AddLog(const aStr: string);
begin
  WriteReport(aStr);
end;

procedure TTestProfilerXMLLogger.EndTest(test: ITest);
begin
  //no sub tests? so the "real" single test
  if test.tests.Count<=0 then
    WriteReport('    </Test>'+CRLF);
end;

procedure TTestProfilerXMLLogger.EndSuite(suite: ITest);
var
  tstart: TDateTime;
begin
  tstart := FSuiteDurations.Pop;

  WriteReport('  <SuiteDuration>' + FormatDateTime('hh:nn:ss.zzz', Now - tstart) + '</SuiteDuration>' + CRLF +
              '  </TestSuite>'+CRLF);
end;

procedure TTestProfilerXMLLogger.TestingEnds(testResult: TTestResult);
var
  runTime : TDateTime;
  successRate : Integer;
begin
  successRate := 0;
  runTime     := now-startTime;
  if testResult.runCount > 0 then
    successRate :=  Trunc(
       ( (testResult.runCount - testResult.failureCount - testResult.errorCount)
         /testResult.runCount)
       * 100);

  WriteReport('<Statistics>'+CRLF+
              '  <Stat name="Tests" result="'+intToStr(testResult.runCount)+'" />'+CRLF+
              '  <Stat name="Failures" result="'+intToStr(testResult.failureCount)+'" />'+CRLF+
              '  <Stat name="Errors" result="'+intToStr(testResult.errorCount)+'" />'+CRLF+
              '  <Stat name="Success Rate" result="'+intToStr(successRate)+'%" />'+CRLF+
              '  <Stat name="Started At" result="'+DateTimeToStr(startTime)+'" />'+CRLF+
              '  <Stat name="Finished At" result="'+DateTimeToStr(now)+'" />'+CRLF+
                 //'<Stat name="Runtime" result="'+timeToStr(runTime)+'" />'+CRLF+
              '  <Stat name="Runtime" result="'+FormatDateTime('hh:nn:ss.zzz',runTime)+'" />'+CRLF+
              '</Statistics>'+CRLF+
              '</TestRun>');

  CloseHandle(FOutput);
  FOutput := 0;
end;

class function TTestProfilerXMLLogger.RunTest(suite: ITest; outputFile:String): TTestResult;
begin
  Result := TestFramework.RunTest(suite, [TTestProfilerXMLLogger.Create(outputFile)]);
end;

class function TTestProfilerXMLLogger.RunRegisteredTests(outputFile:String): TTestResult;
begin
  Result := RunTest(registeredTests, outputFile);
end;

function RunTest(suite: ITest; outputFile:String=DEFAULT_FILENAME): TTestResult;
begin
  Result := TestFramework.RunTest(suite, [TTestProfilerXMLLogger.Create(outputFile)]);
end;

function RunRegisteredTests(outputFile:String=DEFAULT_FILENAME): TTestResult;
begin
  Result := RunTest(registeredTests, outputFile);
end;


procedure TTestProfilerXMLLogger.Status(test: ITest; const Msg: string);
begin
  WriteReport(Format('INFO: %s: %s', [test.Name, Msg]));
end;

procedure TTestProfilerXMLLogger.Warning(test :ITest; const Msg :string);
begin
  WriteReport(Format('WARNING: %s: %s', [test.Name, Msg]));
end;

function TTestProfilerXMLLogger.ShouldRunTest(test: ITest): boolean;
begin
  Result := test.Enabled;
end;

class function TTestProfilerXMLLogger.StringReplaceAll(const text, byt, mot: string):string;
begin
  Result := StringReplace(text, byt, mot, [rfReplaceAll]);
end;

{:
 Replace special character by sgml compliant characters
 }
class function TTestProfilerXMLLogger.text2sgml(const text: String): String;
begin
//  "   &quot;
//  <   &lt;
//  >   &gt;
//  &   &amp;
  result := text;
  result := stringreplaceall(result,'&','&amp;');
  result := stringreplaceall(result,'<','&lt;');
  result := stringreplaceall(result,'>','&gt;');
  result := stringreplaceall(result,'"','&quot;');
  result := stringreplaceall(result,'?','&#63;');
end;

end.
