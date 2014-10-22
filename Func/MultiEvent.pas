unit MultiEvent;

interface

uses
  Classes, SysUtils,
  Generics.Collections;

type
  PMethod = ^TMethod;
  //
  TEventChangeNotifyEvent = procedure(Sender: TObject; Event: TMethod; Operation: TOperation) of object;
  //
  TGenericAnonymousEvent<T> = reference to procedure(const aValue: T);
  TGenericAnonymousEventResult<TValue, TResult> = reference to procedure(const aValue1: TValue; out aResult: TResult);
  TGenericAnonymousEventCallback<TResult> = reference to procedure(const aResult: TResult; out aStop: Boolean);
  TGenericEvent<T> = procedure(const aValue: T) of object;
  TGenericEventResult<TValue, TResult> = procedure(const aValue1: TValue; out aResult: TResult) of object;

  TMultiCastEvent = class
  private
    fMethods: TList;
    FOnEventChange: TEventChangeNotifyEvent;
    function  GetMethod(const aIndex: Integer): TMethod;
    procedure SetOnEventChange(const Value: TEventChangeNotifyEvent);
  protected
    property Method[const aIndex: Integer]: TMethod read GetMethod;
    function GetCount: Integer;virtual;
  public
    constructor Create; virtual;
    destructor  Destroy; override;

    procedure Add(const aMethod: TMethod); overload;virtual;
    procedure Remove(const aMethod: TMethod); overload;virtual;

    property Count: Integer read GetCount;
    property OnEventChange: TEventChangeNotifyEvent read FOnEventChange write SetOnEventChange;
  end;

  TMultiCast<T> = class(TMultiCastEvent)
  private
    FAnonymousMethods: TList<TGenericAnonymousEvent<T>>;
    function GetEvent(aIndex: Integer): TGenericEvent<T>;
  protected
    property Event[aIndex: Integer]: TGenericEvent<T> read GetEvent;
    function GetCount: Integer;override;
  public
    destructor Destroy; override;

    procedure DoEvent(const aValue: T);overload;

    procedure Add(const aMethod: TGenericEvent<T>); overload;
    procedure Add(const aMethod: TGenericAnonymousEvent<T>); overload;

    procedure Remove(const aMethod: TGenericEvent<T>); overload;
  end;

  TMultiCastResult<TValue, TResult> = class(TMultiCastEvent)
  private
    FAnonymousMethods: TList<TGenericAnonymousEventResult<TValue,TResult>>;
    function GetEvent(aIndex: Integer): TGenericEventResult<TValue,TResult>;
  protected
    property Event[aIndex: Integer]: TGenericEventResult<TValue,TResult> read GetEvent;
    function GetCount: Integer;override;
  public
    destructor Destroy; override;

    procedure DoEvent(const aValue1: TValue; aOnEachResultCallback: TGenericAnonymousEventCallback<TResult>; out aFinalResult: TResult);

    procedure Add(const aMethod: TGenericEventResult<TValue,TResult>); overload;
    procedure Add(const aMethod: TGenericAnonymousEventResult<TValue,TResult>); overload;

    procedure Remove(const aMethod: TGenericEventResult<TValue,TResult>); overload;
  end;

implementation

{ TMultiCastEvent }

constructor TMultiCastEvent.Create;
begin
  inherited Create;
  fMethods := TList.Create;
end;

destructor TMultiCastEvent.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(fMethods.Count) do
    Dispose(fMethods[i]);
  FreeAndNIL(fMethods);
  inherited;
end;

function TMultiCastEvent.GetCount: Integer;
begin
  result := fMethods.Count;
end;

function TMultiCastEvent.GetMethod(const aIndex: Integer): TMethod;
begin
  result := TMethod(fMethods[aIndex]^);
end;

procedure TMultiCastEvent.Add(const aMethod: TMethod);
var
  i: Integer;
  handler: PMethod;
begin
  System.TMonitor.Enter(Self);
  try
    //search if already exists -> quit
    for i := 0 to Pred(fMethods.Count) do
    begin
      handler := fMethods[i];
      if (aMethod.Code = handler.Code) and (aMethod.Data = handler.Data) then
        EXIT;
    end;
    handler := New(PMethod);
    handler^ := aMethod;
    fMethods.Add(handler);
  finally
    System.TMonitor.Exit(Self);
  end;

  if Assigned(FOnEventChange) then
    FOnEventChange(Self, aMethod, opInsert);
end;

procedure TMultiCastEvent.Remove(const aMethod: TMethod);
var
  i: Integer;
  handler: PMethod;
begin
  System.TMonitor.Enter(Self);
  try
    for i := 0 to Pred(fMethods.Count) do
    begin
      handler := fMethods[i];
      if (aMethod.Code = handler.Code) and (aMethod.Data = handler.Data) then
      begin
        Dispose(handler);
        fMethods.Delete(i);
        BREAK;
      end;
    end;
  finally
    System.TMonitor.Exit(Self);
  end;

  if Assigned(FOnEventChange) then
    FOnEventChange(Self, aMethod, opRemove);
end;

procedure TMultiCastEvent.SetOnEventChange(
  const Value: TEventChangeNotifyEvent);
begin
  FOnEventChange := Value;
end;

{ TMultiCast<T> }

procedure TMultiCast<T>.Add(const aMethod: TGenericEvent<T>);
begin
  Add(TMethod(aMethod));
end;

procedure TMultiCast<T>.Add(const aMethod: TGenericAnonymousEvent<T>);
begin
  if FAnonymousMethods = nil then
    FAnonymousMethods := TList<TGenericAnonymousEvent<T>>.Create;
  FAnonymousMethods.Add(aMethod);
end;

destructor TMultiCast<T>.Destroy;
begin
  FAnonymousMethods.Free;
  inherited;
end;

procedure TMultiCast<T>.DoEvent(const aValue: T);
var
  i: Integer;
  e: TGenericEvent<T>;
  a: TGenericAnonymousEvent<T>;
begin
  for i := 0 to fMethods.Count-1 do
  begin
    e := Event[i];
    if not Assigned(e) then Continue;
    e(aValue);
  end;

  if FAnonymousMethods <> nil then
  begin
    for a in FAnonymousMethods do
      a(aValue);
  end;
end;

function TMultiCast<T>.GetCount: Integer;
begin
  Result := inherited GetCount;
  if FAnonymousMethods <> nil then
    Inc(Result, FAnonymousMethods.Count);
end;

function TMultiCast<T>.GetEvent(aIndex: Integer): TGenericEvent<T>;
begin
  Result := TGenericEvent<T>(Method[aIndex]);
end;

procedure TMultiCast<T>.Remove(const aMethod: TGenericEvent<T>);
begin
  Remove(TMethod(aMethod));
end;

{ TMultiCastResult<T1, T2> }

procedure TMultiCastResult<TValue, TResult>.Add(const aMethod: TGenericEventResult<TValue, TResult>);
begin
  Add(TMethod(aMethod));
end;

procedure TMultiCastResult<TValue, TResult>.Add(const aMethod: TGenericAnonymousEventResult<TValue, TResult>);
begin
  if FAnonymousMethods = nil then
    FAnonymousMethods := TList<TGenericAnonymousEventResult<TValue, TResult>>.Create;
  FAnonymousMethods.Add(aMethod);
end;

destructor TMultiCastResult<TValue, TResult>.Destroy;
begin
  FAnonymousMethods.Free;
  inherited;
end;

procedure TMultiCastResult<TValue, TResult>.DoEvent(const aValue1: TValue;
  aOnEachResultCallback: TGenericAnonymousEventCallback<TResult>; out aFinalResult: TResult);
var
  i: Integer;
  e: TGenericEventResult<TValue,TResult>;
  a: TGenericAnonymousEventResult<TValue,TResult>;
  _result: TResult;
  bStop: Boolean;
begin
  bStop := False;

  for i := 0 to fMethods.Count-1 do
  begin
    e := Event[i];
    if not Assigned(e) then Continue;

    e(aValue1, _result);
    if not Assigned(aOnEachResultCallback) then Continue;
    aOnEachResultCallback(_result, bStop);
    if bStop then Exit;
  end;

  if FAnonymousMethods <> nil then
  begin
    for a in FAnonymousMethods do
    begin
      a(aValue1, _result);
      if not Assigned(aOnEachResultCallback) then Continue;
      aOnEachResultCallback(_result, bStop);
      aFinalResult := _result;
      if bStop then Exit;
    end;
  end;
end;

function TMultiCastResult<TValue, TResult>.GetCount: Integer;
begin
  Result := inherited GetCount;
  if FAnonymousMethods <> nil then
    Inc(Result, FAnonymousMethods.Count);
end;

function TMultiCastResult<TValue, TResult>.GetEvent(aIndex: Integer): TGenericEventResult<TValue, TResult>;
begin
  Result := TGenericEventResult<TValue, TResult>(Method[aIndex]);
end;

procedure TMultiCastResult<TValue, TResult>.Remove(const aMethod: TGenericEventResult<TValue, TResult>);
begin
  Remove(TMethod(aMethod));
end;

end.
