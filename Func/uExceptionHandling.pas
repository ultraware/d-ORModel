unit uExceptionHandling;

interface

type
  TExceptionHandling = class
  private
  public
    class function LogDir: string;

    class procedure AppendExtraInfoToLastExceptionFile(
      const aExtraInfo: string); static;
  end;

implementation

uses
  Sysutils, Classes, IOUtils, Windows, StrUtils,
  {$ifdef FMX}
  FMX.Forms,
  {$else}
  VCL.Forms,
  {$endif}
  IdException, IdExceptionCore, IdStack,
  JclDebug, JclHookExcept, DB.Base;

var
  GLastStackTraceFile: string;

procedure WriteStackListToFile(const aError: Exception; const AStackTrace: TJclStackInfoList; const aErrorText: string);
var
  str:TStrings;
  sdir, sfile: string;
begin
  str    := TStringList.create;
  try
    //ignore some exceptions (but write full stack to OutputDebugString?!)
    if (aError is EAbort) or
       (aError is EIdSilentException) or
       (aError is EIdReadTimeout) or
       (aError is EIdConnectTimeout) or
       (aError is EIdSocketError) then
    begin
      //always write debug string, so we can see all exceptions with Sysinternals DebugView.exe
      OutputDebugString(PChar('Exception: IGNORED - ' + aErrorText + str.Text) );
      Exit;
    end;

    if AStackTrace <> nil then
      AStackTrace.AddToStrings(Str,True,False,True);

    if aError is EDBException then
    begin
      str.Add('');
      str.Add('----------------------------');
      str.Add('SQL (last known) = ');
      str.Add( (aError as EDBException).SQL );
      str.Add('----------------------------');
    end;

    //always write debug string, so we can see all exceptions with Sysinternals DebugView.exe
    OutputDebugString(PChar('Exception: ' + aErrorText + str.Text) );

    sdir := ExtractFilePath(Application.ExeName) + 'Log\' + FormatDateTime('yyyymmdd', Now) + '\';
    ForceDirectories(sdir);

    if aError = nil then
      sfile := sdir + 'Exception_' + FormatDateTime('yyyymmdd-hhnnsszzz', Now) + '.log'
    else
      sfile := sdir + aError.ClassName + '_' + FormatDateTime('yyyymmdd-hhnnsszzz', Now) + '.log';
    GLastStackTraceFile := sFile;

    TFile.WriteAllText(sfile, aErrorText + str.Text);
  finally
    str.Free;
  end;
end;

procedure WriteAnyException(ExceptObj: Exception; ExceptAddr: Pointer; OSException: Boolean);
var
  sError:string;
  lstack: TJclStackInfoList;
  iTID: Cardinal;
begin
  if ExceptObj = nil then
    sError := 'Unknown/Empty exception'
  else
  begin
    sError := Format('%s at adress %p: %s',
                    [ExceptObj.ClassName, ExceptAddr,
                     ExceptObj.Message]);

//MOVED TO WriteStackListToFile so we always write all exception to debug viewers
//    if (ExceptObj is EAbort) or
//       (ExceptObj is EIdSilentException) or
//       (ExceptObj is EIdReadTimeout) or
//       (ExceptObj is EIdConnectTimeout) or
//       (ExceptObj is EIdSocketError)
//    then
//      Exit;   MOVED TO WriteStackListToFile so we always write all exception to debug viewers
  end;

  //if exception in our own code?
  if OSException then
    sError := 'OS ' + sError;
  //if GetCurrentProcessId <> FMainProcessId then
  //  sError := format('External process (%d) %s',[GetCurrentProcessId, sError]);

  iTID := GetCurrentThreadId;
  if GetCurrentThreadId = MainThreadID then
    sError := format('%s' + #13 + '{occured in main thread}',[sError])
  else
  begin
    sError := format('%s' + #13 + '{occured in sub thread(TID=%d, class=%s, name=%s, created=%s, parent=%s)}',
                     [sError, iTID,
                      JclDebugThreadList.ThreadClassNames[iTID],
                      JclDebugThreadList.ThreadNames[iTID],
                      DateTimeToStr(JclDebugThreadList.ThreadCreationTime[iTID]),
                      IfThen(JclDebugThreadList.ThreadParentIDs[iTID] <> iTID,
                             JclDebugThreadList.ThreadInfos[ JclDebugThreadList.ThreadParentIDs[iTID] ],
                             '')
                     ]);
  end;
  sError := 'HOOK: ' + sError;

  //WriteMemoryDump(0)
  //if ExceptObj is ETestFailure then
  //  lStack := jclDebug.JclCreateStackList(False, 0, nil)
  //else
    lStack := jclDebug.JclLastExceptStackList;
  try
    if (lstack = nil) or (lstack.Count < 3) then
    begin
      lstack.Free;
      lStack := TJclStackInfoList.Create(True, 0, nil);
    end;

    sError := sError + #13#13'Stack:'#13;

    {$IOCHECKS OFF}
    WriteStackListToFile(ExceptObj, lStack, sError);
    {$IOCHECKS ON}
  finally
    lstack.Free;
  end;
end;

procedure AnyExceptionNotify(ExceptObj: TObject; ExceptAddr: Pointer; OSException: Boolean);
begin
  try
    //terminated? -> do not quit, always write exception logs!
    //if Application.Terminated then exit;

    //delphi thread name, ignore
    if (ExceptObj is EExternalexception) and
       {$WARN SYMBOL_PLATFORM OFF}
       (EExternalexception(ExceptObj).Exceptionrecord^.ExceptionCode = 1080890248) then
    begin
      Exit;
    end;
    if ExceptObj is EIdSilentException then exit;    //EIdClosedSocket
    //if ExceptObj is EIdSocketError then exit;
    //if (ExceptObj is EAbort) and not (ExceptObj is ETestFailure) then exit;
    if not (ExceptObj is Exception) then Exit;

    WriteAnyException(ExceptObj as Exception, ExceptAddr, OSException);
  except
    //eat exceptions during exception handling...
  end;
end;

{ TExceptionHandling }

class function TExceptionHandling.LogDir: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'Log/' + FormatDateTime('yyyymmdd',Now) + '/';
  ForceDirectories(Result);
end;

class procedure TExceptionHandling.AppendExtraInfoToLastExceptionFile(
  const aExtraInfo: string);
var
  str: TStrings;
  iStackPos: Integer;
  sData: string;
begin
  if GLastStackTraceFile = '' then
    WriteAnyException(nil, nil, False);
  Assert(GLastStackTraceFile <> '');
  if not FileExists(GLastStackTraceFile) then Exit;

  str := TStringList.Create;
  try
    str.LoadFromFile(GLastStackTraceFile);

    sData := 'Extra info:'#13 + aExtraInfo;
    //need newline between?
    iStackPos := str.Count;
    if (iStackPos > 0) and (str[iStackPos-1] <> '') then
      sData := #13 + sData;
    //newline after
    sData := sData + #13;

    str.Add(sData);

    str.SaveToFile(GLastStackTraceFile);
  finally
    str.Free;
  end;
end;

procedure LoadDebugInfoAsync;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      DebugInfoAvailable(MainInstance);
    end).Start;
end;

initialization
  JclHookThreads;
  //{$IFDEF ShowAllExceptions}
  JclHookExceptions;
  // Assign notification procedure for hooked RaiseException API call. This
  // allows being notified of any exception
  JclAddExceptNotifier(AnyExceptionNotify);
  //{$ENDIF}

  LoadDebugInfoAsync;

finalization
  JclStopExceptionTracking;
  JclUnhookThreads;

end.


