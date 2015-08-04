unit CRUD.%UnitName%;

{ CRUD object for table: %DBTableName% }

interface

{$WEAKLINKRTTI ON}

uses
  Data.CRUD, Data.DataRecord, Data.CustomTypes%Uses%,
  Meta.Data, Meta.%UnitName%, Meta.CustomIDTypes%DataAutoJoinChildUses%;

type
  T%TableName% = class(%TJoinableDataRecord%) %DataAutoJoinChildData%
  published
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
%DataAutoJoinChildDataFunctions%
%DataSetParamFunctions%
end.
