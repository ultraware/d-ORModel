unit CRUD.TEST;

{ CRUD object for table: CompendaAppDemo.TEST }

interface

{$WEAKLINKRTTI ON}

uses
  Data.CRUD, DataRecord, Meta.Data,
  Meta.TEST, Data.CustomTypes, Meta.CustomIDTypes;

type
  TTEST = class(TDataRecord)
  public
    [TEST(ID)]                                 property  ID                         : TTypedTEST_IDField         index   0 read GetTypedTEST_IDField;
    [TEST(Datum)]                              property  Datum                      : TTypedDateTimeField        index   1 read GetDateTimeField;
    [TEST(Tekst)]                              property  Tekst                      : TTypedStringField          index   2 read GetStringField;
  end;

  TTESTCRUD = class(TDataCRUD<TTEST>);

  function TESTCRUD: TTESTCRUD;

implementation

threadvar
  localCRUD: TTESTCRUD;

function TESTCRUD: TTESTCRUD;
begin
  Result := localCRUD;
  if Result = nil then
  begin
    localCRUD := TTESTCRUD.Create;
    Result    := localCRUD;
  end;
end;

end.
