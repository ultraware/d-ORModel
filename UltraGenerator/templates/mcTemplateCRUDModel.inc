unit Model.%UnitName%;

{ Model for table: %DBTableName% }

interface

{$WEAKLINKRTTI ON}

uses
  Data.DataRecord, Data.CustomTypes%Uses%,
  Meta.%TableName%, Meta.CustomIDTypes;

type
  T%TableName% = class(TJoinableDataRecord) 
  public
    %DataPropertyFields%
  end;

implementation

end.
