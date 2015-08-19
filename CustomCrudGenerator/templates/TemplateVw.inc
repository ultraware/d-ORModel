unit mc%TableName%;

{ CRUDGenerator 5.0.0.00 -----------------------------------------------------
  CRUD Objecten voor tabel: %Database%.%DBTableName%
-----------------------------------------------------------------------------}

interface

{$WEAKLINKRTTI ON}

uses
    mcField, mcCRUD, mcCRUDLib
  , mc%TableName%Meta%UseCustomFields%;

type
  T%TableName% = class(TDataRecord)%GetDataFields%
  public
    %DataPropertyFields%
  end;

  T%TableName%Search = class(TBaseDataCRUD)
  private
    function GetData: T%TableName%; inline;
  protected
    function GetDataClass: TDataRecordClass; override;
  public
    property Data: T%TableName% read GetData;
  end;

  function %TableName%Search: T%TableName%Search;

implementation

threadvar
  localCRUD: T%TableName%Search;

function %TableName%Search: T%TableName%Search;
begin
  if localCRUD = nil then
    localCRUD := T%TableName%Search.Create;
  Result := localCRUD;
end;
%GetDataFieldsImplementation%
{ T%TableName%Search }

function T%TableName%Search.GetData: T%TableName%;
begin
  Result := T%TableName%(FData);
end;

function T%TableName%Search.GetDataClass: TDataRecordClass;
begin
  Result := T%TableName%;
end;

end.