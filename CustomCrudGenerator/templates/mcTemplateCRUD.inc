unit CRUD.%TableName%;

{ CRUD object for table: %Database%.%DBTableName% }

interface

{$WEAKLINKRTTI ON}

uses
  Data.CRUD, Data.DataRecord, Data.CustomTypes,
  Meta.Data, Meta.%TableName%, Meta.CustomIDTypes;

type
  T%TableName% = class(TDataRecord)
  public
    %DataPropertyFields%
  end;

  T%TableName%CRUD = class(TDataCRUD<T%TableName%>);

  function %TableName%CRUD: T%TableName%CRUD;

implementation

threadvar
  localCRUD: T%TableName%CRUD;

function %TableName%CRUD: T%TableName%CRUD;
begin
  Result := localCRUD;
  if Result = nil then
  begin
    localCRUD := T%TableName%CRUD.Create;
    Result    := localCRUD;
  end;
end;

end.
