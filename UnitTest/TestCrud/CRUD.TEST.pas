unit CRUD.Test;

{ CRUD object for table: Test }

interface

{$WEAKLINKRTTI ON}

uses
  Data.CRUD, Data.DataRecord, Data.CustomTypes,
  Meta.Data, Meta.Test, Meta.CustomIDTypes,
  Func.SmartObjectPool;

type
  TTest = class(TJoinableDataRecord) 
  published
    [Test(ID)]                                 property  ID                         : TTypedTest_IDField         index   0 read GetTypedTest_IDField;
    [Test(Datum)]                              property  Datum                      : TTypedDateTimeField        index   1 read GetDateTimeField;
    [Test(Tekst)]                              property  Tekst                      : TTypedStringField          index   2 read GetStringField;
  end;

  TTestCRUD = class;
  ITestCRUDSmart = ISmartPointer<TTestCRUD>;

  TTestCRUD = class(TDataCRUD<TTest>)
  public
    class function CreateSmartInstance: ITestCRUDSmart;
  end;

  function TestCRUD: TTestCRUD;

implementation

threadvar
  localCRUD: TTestCRUD;

function TestCRUD: TTestCRUD;
begin
  Result := localCRUD;
  if Result = nil then
  begin
    localCRUD := TTestCRUD.Create;
    Result    := localCRUD;
  end;
end;

{ TTestCRUD }

class function TTestCRUD.CreateSmartInstance: ITestCRUDSmart;
begin
  Result := TPooledSmartPointer<TTestCRUD>.Create();
end;

end.
