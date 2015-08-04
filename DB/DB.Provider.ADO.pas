{***************************************************************************}
{                                                                           }
{           d'ORModel - Model based ORM for Delphi                          }
{			https://github.com/ultraware/d-ORModel							}
{           Copyright (C) 2013-2014 www.ultraware.nl                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}
unit DB.Provider.ADO;

interface

uses
  DB.Provider,
  ADOInt, ADODB,
  Data.Base,
  Data.Query, Data.DataRecord,
  DB.Connection, DB.Settings, DB;

type
  TADODBProvider = class(TBaseDBProvider)
  public
    procedure DataCreate(const aData: TBaseDataRecord); override;
    function DataUpdate(const aData: TBaseDataRecord): Integer; override;
    procedure DataDelete(const aData: TBaseDataRecord); override;

    function QuerySearchSingle(aQuery: IQueryDetails): Boolean; override;
    function QuerySearchCount (aQuery: IQueryDetails): Integer; override;

    function  QueryFindFirst(aQuery: IQueryDetails; var aDataStore: TBaseFindResults): Boolean; override;
    function  QueryFindCount(aDataStore: TBaseFindResults): Integer; override;
    function  QueryFindNext (aDataStore: TBaseFindResults): Boolean; override;
    function  QueryFindMove (aDataStore: TBaseFindResults; aMoveNumRecords: Integer): Boolean; override;
    function  QueryFindGetRecNo(aDataStore: TBaseFindResults): Integer; override;
    function  QueryFindSetRecNo(aDataStore: TBaseFindResults; aRecNo: Integer): Boolean; override;
    function  QueryFindGetSortString(aDataStore: TBaseFindResults): string; override;
    procedure QueryFindSetSortString(aDataStore: TBaseFindResults; const aSortString: string); override;
    function  QueryFindGetBookmark(aDataStore: TBaseFindResults): TBookmark; override;
    procedure QueryFindSetBookmark(aDataStore: TBaseFindResults; const aBookmark: TBookmark); override;
    function  QueryFindCompareBookmark(aDataStore: TBaseFindResults; Bookmark1, Bookmark2: TBookmark): Integer; override;
    //
    procedure QueryExecute(aQuery: IQueryDetails; aNoErrorIfNoneAffected: boolean = false); override;
    function  QueryExecuteCount(const aQuery: IQueryDetails): Integer; override;

    function  QueryFillRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TRowDataArray; override;
    function  QueryFillMultiRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TMultiRowDataArray; override;

    procedure QueryCreateTable(const aTableModel: TDataRecord; const WithPrimaryKey, DropIfExists: Boolean); override;

    function  ValidationExecute(aQuery: IQueryDetails): TValidationErrors; override;
  end;

  TADOFindResults = class(TBaseFindResults)
  protected
    FRecordset: _Recordset;
  end;

implementation

uses
  SysUtils, Math,
  DB.ConnectionPool, DB.ADODataConverter, Meta.Data, DB.Base, Variants,
  DB.Connection.SQLServer, DB.Settings.SQLServer, Winapi.Windows;

{ TADODBProvider }

procedure TADODBProvider.DataCreate(const aData: TBaseDataRecord);
var
  connection : TBaseConnection;
  insert: IQueryBuilder;
  f: TBaseField;
  adodata: _Recordset;
  v: OleVariant;
  iInserted: Integer;
begin
  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    insert := GenerateInsertQuery(aData);

    //execute
    adodata := (connection as TBaseADOConnection).QueryExecuteData(insert as IQueryDetails, iInserted);

    if adodata.State = adStateClosed then
      adodata := adodata.NextRecordset(v);
    if adodata.Fields.Count = 0 then
      raise EDBException.Create('Identity value could not be fetched after insert');

    //find first ID field and put value in it
    for f in aData do
      if f.FieldType = ftFieldID then
      begin
        f.LoadValue( adodata.Fields[0].Value );
        Break;
      end;
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

procedure TADODBProvider.DataDelete(const aData: TBaseDataRecord);
var
  connection : TBaseConnection;
  delete: IQueryBuilder;
  iUpdated: Integer;
begin
  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    delete := GenerateDeleteQuery(aData);

    //execute
    (connection as TBaseADOConnection).QueryExecuteData(delete as IQueryDetails, iUpdated);

    if iUpdated = 0 then
      raise EDataException.Create('No records are deleted!');
    if iUpdated > 1 then
      raise EDataException.CreateFmt('More than 1 records (%d) are deleted!', [iUpdated]);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

type
  TBaseField_Ext = class(TBaseField);

function TADODBProvider.DataUpdate(const aData: TBaseDataRecord): Integer;
var
  connection : TBaseConnection;
  update: IQueryBuilder;
  iUpdated: Integer;
begin
  Result := 0;
  if not aData.IsModified then
     Exit;

  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    update := GenerateUpdateQuery(aData);

    //execute
    (connection as TBaseADOConnection).QueryExecuteData(update as IQueryDetails, iUpdated);
    if iUpdated = 0 then
      raise EDataException.Create('No records are updated!');
    if iUpdated > 1 then
      raise EDataException.CreateFmt('More than 1 records (%d) are updated!', [iUpdated]);

    Result := iUpdated;
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

procedure TADODBProvider.QueryCreateTable(const aTableModel: TDataRecord; const WithPrimaryKey, DropIfExists: Boolean);
var
  connection: TBaseConnection;
begin
  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    (connection as TBaseADOConnection).QueryCreateTable(aTableModel, WithPrimaryKey, DropIfExists);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

procedure TADODBProvider.QueryExecute(aQuery: IQueryDetails; aNoErrorIfNoneAffected: boolean);
var
  connection: TBaseConnection;
  iDummy: Integer;
begin
  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    iDummy := (connection as TBaseADOConnection).QueryExecute(aQuery);

    if (iDummy = 0) and
       not aNoErrorIfNoneAffected then
      raise EDBException.Create('No rows affected', connection.LastExecutedSQL);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

function TADODBProvider.QueryExecuteCount(const aQuery: IQueryDetails): Integer;
var
  connection: TBaseConnection;
begin
  Result := -1;
  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    Result := (connection as TBaseADOConnection).QueryExecute(aQuery);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

function TADODBProvider.QueryFillRowArray(
  aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TRowDataArray;
var
  connection: TBaseConnection;
  adodata: _Recordset;
begin
  Result  := nil;
  adodata := nil;

  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    adodata := (connection as TBaseADOConnection).QueryExecuteData(aQuery, aMaxRecords);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
  //geen data?
  if adodata = nil then Exit;

  //data inladen (complete array)
  if adodata <> nil then
    Result := TADODataConverter.FillFieldArrayByQuery(adodata, aQuery, aFieldCount);
end;

function TADODBProvider.QueryFillMultiRowArray(aQuery: IQueryDetails; aFieldCount,
  aMaxRecords: Integer): TMultiRowDataArray;
var
  connection: TBaseConnection;
  adodata: _Recordset;
begin
  Result  := nil;
  adodata := nil;

  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    adodata := (connection as TBaseADOConnection).QueryExecuteData(aQuery, aMaxRecords);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
  //geen data?
  if adodata = nil then Exit;

  //data inladen (complete array)
  if adodata <> nil then
    Result := TADODataConverter.FillMultiRowArrayByQuery(adodata, aQuery, aFieldCount);
end;

function TADODBProvider.QueryFindCompareBookmark(aDataStore: TBaseFindResults; Bookmark1, Bookmark2: TBookmark): Integer;
var
  rs: _Recordset;
  b: OleVariant;
  ipos1, ipos2: NativeUInt;
begin
   rs := (aDataStore as TADOFindResults).FRecordset;//TADOFindResults_Ext(SourceCRUD.FindData as TADOFindResults).FRecordset;
   b  := rs.Bookmark;
   rs.Bookmark := PDouble(Bookmark1)^;
   ipos1 := rs.AbsolutePosition;
   rs.Bookmark := PDouble(Bookmark2)^;
   ipos2 := rs.AbsolutePosition;
   rs.Bookmark := b;

   Result := CompareValue( ipos1, ipos2 );
end;

function TADODBProvider.QueryFindCount(
  aDataStore: TBaseFindResults): Integer;
var
  adodata: _Recordset;
begin
  Result := -1;
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    adodata := (aDataStore as TADOFindResults).FRecordset;
    Result  := adodata.RecordCount;

    if adodata.CursorLocation = adUseServer then
      Assert(False, 'Cannot determine RecordCount when using cursorlocation = server!');
  end
  else
    Assert(False);
end;

function TADODBProvider.QueryFindFirst(aQuery: IQueryDetails;
  var aDataStore: TBaseFindResults): Boolean;
var
  connection: TBaseConnection;
  adodata: _Recordset;
  iDummy: Integer;
begin
  Result  := False;
  adodata := nil;
  Assert(aDataStore = nil); //moet initieel leeg zijn, WIJ vullen hem hier

  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    adodata := (connection as TBaseADOConnection).QueryExecuteData(aQuery, iDummy);
    Result := (adodata <> nil) and
              ( (adodata.RecordCount > 0) or   //igv cursorlocation=server dan -1!
                not adodata.EOF);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
  //geen data?
  if not Result then Exit;

  //data inladen
  if adodata <> nil then
  begin
    //store recordset in temp object (for FindNext etc)
    aDataStore := TADOFindResults.Create;
    aDataStore.Query := aQuery;
    (aDataStore as TADOFindResults).FRecordset := adodata;

    TADODataConverter.FillDataByQuery(adodata, aQuery);
  end;
end;

function TADODBProvider.QueryFindMove(aDataStore: TBaseFindResults; aMoveNumRecords: Integer): Boolean;
var
  adodata: _Recordset;
  query: IQueryDetails;
begin
  Result  := False;
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    if aMoveNumRecords = 0 then Exit(True)
    else if aMoveNumRecords > 0 then
    begin
      Result := not adodata.EOF;
      if not Result then Exit;
    adodata.Move(aMoveNumRecords, EmptyParam);
    Result  := not adodata.EOF;
    end
    else if aMoveNumRecords < 0 then
    begin
      Result := not adodata.BOF;
      if not Result then Exit;
      adodata.Move(aMoveNumRecords, EmptyParam);
      Result := not adodata.BOF;
    end;

    if Result then
    begin
      //fill via query
      query := aDataStore.Query;
      TADODataConverter.FillDataByQuery(adodata, query);
    end;
  end
  else
    Assert(False);
end;

function TADODBProvider.QueryFindNext(aDataStore: TBaseFindResults): Boolean;
var
  adodata: _Recordset;
  query: IQueryDetails;
begin
  Result  := False;
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    adodata.MoveNext;
    Result  := not adodata.EOF;

    if Result then
    begin
      //fill via query
      query := aDataStore.Query;
      TADODataConverter.FillDataByQuery(adodata, query);
    end;
  end
  else
    Assert(False);
end;

function TADODBProvider.QueryFindGetBookmark(
  aDataStore: TBaseFindResults): TBookmark;
var
  adodata: _Recordset;
begin
  Result := nil;
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    Assert( TVarData(adodata.Bookmark).VType = varDouble);
    SetLength(Result, SizeOf(Double));
    PDouble(Result)^ := adodata.Bookmark;
  end
  else
    Assert(False);
end;

procedure TADODBProvider.QueryFindSetBookmark(aDataStore: TBaseFindResults;
  const aBookmark: TBookmark);
var
  adodata: _Recordset;
begin
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    adodata.Bookmark := PDouble(aBookmark)^;
  end
  else
    Assert(False);
end;

function TADODBProvider.QueryFindGetRecNo(aDataStore: TBaseFindResults): Integer;
var
  adodata: _Recordset;
begin
  Result := -1;
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    if adodata.EOF then    //AbsolutePosition = 4294967293 if eof...
    begin
      adodata.MovePrevious;
      Result  := adodata.AbsolutePosition;
      adodata.MoveNext;
    end
    else if adodata.BOF then    //AbsolutePosition = 4294967293 if eof...
    begin
      adodata.MoveNext;
      Result  := adodata.AbsolutePosition;
      adodata.MovePrevious;
    end
    else
      Result  := adodata.AbsolutePosition;
  end
  else
    Assert(False);
end;

function TADODBProvider.QueryFindSetRecNo(aDataStore: TBaseFindResults; aRecNo: Integer): Boolean;
var
  adodata: _Recordset;
begin
  Result := False;
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    adodata.AbsolutePosition := aRecNo;
    Result  := True;
  end
  else
    Assert(False);
end;

function TADODBProvider.QueryFindGetSortString(
  aDataStore: TBaseFindResults): string;
var
  adodata: _Recordset;
begin
  Result := '';
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    Result  := adodata.Sort;
  end
  else
    Assert(False);
end;

procedure TADODBProvider.QueryFindSetSortString(aDataStore: TBaseFindResults;
  const aSortString: string);
var
  adodata: _Recordset;
begin
  Assert(aDataStore <> nil); //moet nu gevuld zijn met data van de FindFirst

  if aDataStore is TADOFindResults then
  begin
    //next record in dataset
    adodata := (aDataStore as TADOFindResults).FRecordset;
    adodata.Sort := aSortString;
  end
  else
    Assert(False);
end;

function TADODBProvider.QuerySearchCount(aQuery: IQueryDetails): Integer;
var
  connection: TBaseConnection;
  adodata: _Recordset;
  iDummy: Integer;
begin
  Result  := -1;
  adodata := nil;

  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    Result := (connection as TBaseADOConnection).QuerySelectCount(aQuery, iDummy);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

function TADODBProvider.QuerySearchSingle(aQuery: IQueryDetails): Boolean;
var
  connection: TBaseConnection;
  adodata: _Recordset;
  iDummy: Integer;
begin
  Result  := False;
  adodata := nil;

  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    adodata := (connection as TBaseADOConnection).QueryExecuteData(aQuery, iDummy, 1);

    Result := (adodata <> nil) and
              ( (adodata.RecordCount > 0) or   //igv cursorlocation=server dan -1!
                not adodata.EOF);
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
  //geen data?
  if not Result then Exit;

  //data inladen
  if adodata <> nil then
    TADODataConverter.FillDataByQuery(adodata, aQuery);
end;

function TADODBProvider.ValidationExecute(
  aQuery: IQueryDetails): TValidationErrors;
var
  connection : TBaseConnection;
  errors: _Recordset;
  v: OleVariant;
  sField: string;
begin
  connection := TDBConnectionPool.GetConnectionFromPool(Self.DBSettings);
  try
    if not (connection is TBaseADOConnection) then
      raise EDataException.Create('Unsupported connection type: ' + connection.ClassName);
    if not connection.IsOpen then
      connection.Open;

    //execute
    errors := (connection as TBaseADOConnection).QueryExecuteValidation(aQuery);
    while (errors <> nil) do //and (errors.RecordCount > 0) do
    begin
      SetLength(Result, Length(Result)+1);
      with Result[High(Result)] do
      begin
        sField := errors.Fields[0].Value;
        if aQuery.UpdateFieldValues <> nil then
          Field := aQuery.UpdateFieldValues.GetFieldByName(sfield);
        if Field = nil then
          if aQuery.UpdateIncFieldValues <> nil then
            Field := aQuery.UpdateIncFieldValues.GetFieldByName(sfield);
        Error := errors.Fields[1].Value;
      end;
      errors := errors.NextRecordset(v);
    end;
  finally
    TDBConnectionPool.PutConnectionToPool(Self.DBSettings, connection);
  end;
end;

initialization
  TDBProvider.RegisterDBProvider(dbtSQLServer, TADODBProvider);
  TDBProvider.RegisterDBProvider(dbtSQLServerCE, TADODBProvider);

end.
