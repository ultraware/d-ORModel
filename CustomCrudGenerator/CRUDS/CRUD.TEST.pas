unit CRUD.Test;

{ CRUD object for table: %Database%.Test }

interface

{$WEAKLINKRTTI ON}

uses
  Data.CRUD, Data.DataRecord, Data.CustomTypes,
  Meta.Data, Meta.Test, Meta.CustomIDTypes;

type
  TTest = class(TDataRecord)
  published
    [Test(ID)]                                 property  ID                         : TTypedTest_IDField         index   0 read GetTypedTest_IDField;
    [Test(Datum)]                              property  Datum                      : TTypedDateTimeField        index   1 read GetDateTimeField;
    [Test(Tekst)]                              property  Tekst                      : TTypedStringField          index   2 read GetStringField;
  end;

  TTestCRUD = class(TDataCRUD<TTest>);

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

end.
