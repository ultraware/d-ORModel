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
unit Data.CRUD;

interface

uses // Delphi
  Classes, SysUtils, Generics.Collections,
  DB.Settings, DB.Provider,
  Data.Query, Data.Base, Data.DataRecord, DB;

type
  TBaseDataCRUDClass = class of TBaseDataCRUD;
  TBaseDataCRUD = class(TObject)
  protected
    function GetIDField: TBaseIDField; virtual;
    function CTEName: string; virtual;
  private
    function GetQueryFindSortString: String;
    procedure SetQueryFindSortString(const Value: String);
  protected
    FData: TDataRecord;
    FRowData: TRowData;
    FQuery: IQueryBuilder;
    FFindData: TBaseFindResults;
  protected
    class var FDefaultDBTypePerName: TDictionary<string,TDBConnectionType>;
    class var FDBConnectionTypeOverride: TDBConnectionType;
    class var FDBConnectionNameOverride: string;
  public
    class constructor Create;
    class destructor  Destroy;

    class procedure SetDefaultDBTypeForDBName(const aDBName: string; aDefaultType: TDBConnectionType);
    class function  GetDefaultDBTypeOfDBName(const aDBName: string): TDBConnectionType;

    class procedure SetDBConnectionTypeAndNameOverride(const aDBConnectionTypeOverride: TDBConnectionType; const aDBName: string); static;
    class procedure SetDBConnectionTypeOverride(const aDBConnectionTypeOverride: TDBConnectionType); static;
    class function  GetDBConnectionTypeOverride: TDBConnectionType; static;
    class property  DBConnectionTypeOverride: TDBConnectionType read GetDBConnectionTypeOverride write SetDBConnectionTypeOverride;
    class function  GetDBConnectionNameOverride: string;

    function GetProvider: IDBProvider;
  public
    constructor Create; virtual;
    procedure   AfterConstruction; override;
    destructor  Destroy; override;

    procedure ClearAll;

    function GetByID(aID: Integer; Fields: array of TBaseField): Boolean;

    function HasQuery: Boolean;
    function Query   : IQueryBuilder;
    function NewQuery: IQueryBuilder; virtual;
    //
    function  QuerySearchSingle: Boolean;
    function  QuerySearchCount : Integer;
    //
    function  QueryFindFirst   : Boolean;
    function  QueryFindCount   : Integer;
    function  QueryFindNext    : Boolean;
    procedure QueryFindClose;
    function  QueryFindMove(aMoveNumRecords: Integer): Boolean;
    function  QueryFindGetRecNo: Integer;
    function  QueryFindSetRecNo(aRecNo: Integer): Boolean;
    property  QueryFindSortString: String read GetQueryFindSortString write SetQueryFindSortString;
    function  QueryFindCompareBookmark(Bookmark1, Bookmark2: TBookmark): Integer;
    function  QueryFindGetBookmark: TBookmark;
    procedure QueryFindSetBookmark(const aBookmark: TBookmark);
    //
    procedure QueryCreateTable(const WithPrimaryKey: Boolean = True; const DropIfExists: Boolean = True);
    //
    procedure QueryExecute(aNoErrorIfNoneAffected: boolean = False {default errors! must specify manually if query can skip records, so no "hidden" errors});
    //
    function  DoFullValidation(aSkipEmptyFields: Boolean = false; aValidationFilter: TFieldFilter = nil): TValidationErrors;
    procedure RecordCreate; virtual; 
    procedure RecordRetrieve(aID: Int64);overload;
    procedure RecordRetrieve(aID: Int64; aFields: array of TBaseField);overload;
    function  RecordUpdate: Integer;
    procedure RecordDelete;
    //
    function Fetch(aFields: array of TBaseField): Boolean;

    property IDField: TBaseIDField read GetIDField;
    property Data: TDataRecord read FData;
    property FindData: TBaseFindResults read FFindData;
  end;

  //tip: keep generic class as small as possible, otherwise big exe size because of large code generation
  TDataCRUD<T:TDataRecord, constructor> = class(TBaseDataCRUD)
  private
    function GetData: T;
  public
    constructor Create; override;
    procedure   AfterConstruction; override;

    property Data: T read GetData;
  end;

   TBaseCTE_CRUD = class(TBaseDataCRUD)
   private
      CTEQery: IQueryBuilder;
   protected
      function GetIDField: TBaseIDField; override;
      function MainField: TBaseIDField; virtual; abstract;
      procedure MaakQuery(var Qry: IQueryBuilder); virtual; abstract;
   public
      procedure AfterConstruction; override;
      function NewQuery: IQueryBuilder; override;
   end;

  TCTEDataRecord = class(TMultiDataRecord)
  private
    FCTEQuery: IQueryBuilder;
  public
    property CTEQuery: IQueryBuilder read FCTEQuery;
  end;

  TCTE_CRUD<T:TCTEDataRecord, constructor> = class(TBaseCTE_CRUD)
  private
    function GetData: T;
  public
    constructor Create; override;
    procedure AfterConstruction; override;

    property Data: T read GetData;
  end;

implementation

{ TBaseDataCRUD }

uses // Delphi
     ThreadFinalization{, Meta.Data},
     // Shared
     UltraUtilsBasic;

procedure TBaseDataCRUD.AfterConstruction;
begin
  inherited;
  if FData = nil then
  begin
    FRowData.FieldValues := AllocFieldValueArray(0);
    FData := TDataRecord.CreateWithData(@FRowData);
  end
  else
  begin
    FRowData.FieldValues := AllocFieldValueArray(FData.Count);
    FData.LoadRecordData(@FRowData);
  end;
end;

procedure TBaseDataCRUD.ClearAll;
begin
  Data.Clear2Empty;
  FQuery := nil;
  FreeAndNil(Self.FFindData);  //clear previous find data
end;

class constructor TBaseDataCRUD.Create;
begin
  FDefaultDBTypePerName := TDictionary<string,TDBConnectionType>.Create;
end;

constructor TBaseDataCRUD.Create;
begin
  //note: cruds are created as threadvar so we must free these objects ourselves
  //in case the thread terminates (no reference count etc possible)
  TThreadFinalization.RegisterThreadObject(self);
end;

function TBaseDataCRUD.CTEName: string;
begin
   Result := ''; // alleen voor CTE
end;

destructor TBaseDataCRUD.Destroy;
begin
  TThreadFinalization.UnRegisterThreadObject(self);
  FQuery := nil;   //not needed but in case it goes wrong we see which interface.free gives problems
  FreeAndNil(Self.FFindData);  //clear previous find data
  FData.Free;
  inherited;
end;

class destructor TBaseDataCRUD.Destroy;
begin
  FDefaultDBTypePerName.Free;
end;

function TBaseDataCRUD.DoFullValidation(aSkipEmptyFields: Boolean; aValidationFilter: TFieldFilter): TValidationErrors;
var
  query: IQueryBuilder;
  f: TBaseField;
  qd: IQueryDetails;
  dberrors: TValidationErrors;
  iResult, iDB: Integer;
begin
  Result := Data.GetAllValidationErrors(aSkipEmptyFields, aValidationFilter);

  query := TQueryBuilder.Create(IDField);
  for f in Self.Data do
  begin
    if aSkipEmptyFields and f.IsEmpty then Continue;
    if Assigned(aValidationFilter) and
       aValidationFilter(f) then Continue;

    query.Update.SetField(f).WithValue(f.ValueAsVariant);
  end;
  qd := query as IQueryDetails;
  dberrors :=  GetProvider.ValidationExecute(qd);

  iResult := Length(Result);
  SetLength(Result, Length(Result) + Length(dberrors));
  for iDB := 0 to High(dberrors) do
  begin
    Result[iResult] := dberrors[iDB];
    Inc(iResult);
  end;
end;

function TBaseDataCRUD.Fetch(aFields: array of TBaseField): Boolean;
var
  query: IQueryBuilder;
  qd: IQueryDetails;
begin
  Assert(IDField <> nil);
  Assert(not IDField.IsEmptyOrNull);

  //get aditional data for fields of current loaded record (by ID field)
  query := TQueryBuilder.Create(IDField);
  query.Select.Fields    (aFields)
        .Where.FieldValue(IDField)
              .Equal     (IDField.TypedIDValue);

  qd := query as IQueryDetails;
  Result := GetProvider.QuerySearchSingle(qd);
end;

function TBaseDataCRUD.GetByID(aID: Integer; Fields: array of TBaseField): Boolean;
begin
   NewQuery
      .Select.Fields(Fields)
      .Where.FieldValue(IDField).Equal(aID);
   Result := QuerySearchSingle;
   if (not Result) then
      raise Exception.Create(_Fmt('Geen data gevonden met ID = "%d"',[aID]));
end;

class function TBaseDataCRUD.GetDefaultDBTypeOfDBName(
  const aDBName: string): TDBConnectionType;
begin
  if not FDefaultDBTypePerName.TryGetValue(aDBName, Result) then
    Result := dbtNone;
end;

class function TBaseDataCRUD.GetDBConnectionTypeOverride: TDBConnectionType;
begin
   Result := FDBConnectionTypeOverride;
end;

class function TBaseDataCRUD.GetDBConnectionNameOverride: string;
begin
   Result := FDBConnectionNameOverride;
end;

class procedure TBaseDataCRUD.SetDBConnectionTypeAndNameOverride(const aDBConnectionTypeOverride: TDBConnectionType; const aDBName: string);
begin
   FDBConnectionTypeOverride := aDBConnectionTypeOverride;
   FDBConnectionNameOverride := aDBName;
end;

class procedure TBaseDataCRUD.SetDBConnectionTypeOverride(const aDBConnectionTypeOverride: TDBConnectionType);
begin
   FDBConnectionTypeOverride := aDBConnectionTypeOverride;
end;

function TBaseDataCRUD.GetIDField: TBaseIDField;
begin
  //todo: we assume/require that the first field is an ID field
  Result := Data.GetFieldForID;
//  Assert(Self.Data.Count >= 1);
//  Assert(Self.Data.Items[0] is TBaseIDField);
//  Result := Data.Items[0] as TBaseIDField;
end;

function TBaseDataCRUD.GetProvider: IDBProvider;
var
  dbtype: TDBConnectionType;
  dbconn: TDBConfig;
  dbc: TDBProviderClass;
  dbName: string;
begin
  Result := nil;

  if FDBConnectionTypeOverride <> dbtNone then
  begin
    dbtype := FDBConnectionTypeOverride;
    dbName := FDBConnectionNameOverride;
  end
  else
  begin
    Assert(Self.Data.Count > 0, 'no published fields found');  //field properties must be published instead of public
    Assert(Self.IDField <> nil, 'no primary key found');
    dbtype := GetDefaultDBTypeOfDBName(Self.IDField.DatabaseTypeName);  //note: default can be empty!
    dbName := Self.IDField.DatabaseTypeName;
  end;

  dbconn := TDBSettings.Instance.GetDBConnection(dbName, dbtype);  //get specific settings or first in case no dbtype etc

  dbc := nil;
  if dbconn <> nil then
    dbc := TDBProvider.GetRegisteredDBProvider(dbconn.DBType);
  if dbc = nil then                       // Use a DB.Provider.XXXXX.pas (in dpr) to avoid _always_ getting this error
    raise EUltraException.CreateFmt('No provider found for table "%s" of databasename "%s"', [Self.IDField.TableName, Self.IDField.DatabaseTypeName])
  else
    Result := dbc.GetOrCreateThreadProvider(dbconn);
end;

function TBaseDataCRUD.GetQueryFindSortString: String;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindGetSortString(Self.FFindData);
end;

function TBaseDataCRUD.HasQuery: Boolean;
begin
  Result := (FQuery <> nil);
end;

function TBaseDataCRUD.NewQuery: IQueryBuilder;
begin
  {$IFDEF DEBUG}  //do not show error in production (in case a previous loop was aborted due to an exception)
  if (Self.FFindData <> nil) then  //pending QueryFindFirst must be finished first!
    raise EDataException.Create('Cannot create a new query because a pending multi-record loop is busy!');
  {$ENDIF}

  ClearAll;
  Result := Query;
end;

function TBaseDataCRUD.Query: IQueryBuilder;
begin
  if FQuery = nil then
    FQuery := TQueryBuilder.Create(IDField, CTEName);
  Result := FQuery;
end;

procedure TBaseDataCRUD.QueryCreateTable(const WithPrimaryKey: Boolean = True; const DropIfExists: Boolean = True);
begin
   GetProvider.QueryCreateTable(FData, WithPrimaryKey, DropIfExists);
end;

procedure TBaseDataCRUD.QueryExecute(aNoErrorIfNoneAffected: boolean = False);
var
  qd: IQueryDetails;
begin
  Assert(Self.HasQuery);

  qd := Self.Query as IQueryDetails;
  GetProvider.QueryExecute(qd, aNoErrorIfNoneAffected);
end;

procedure TBaseDataCRUD.QueryFindClose;
begin
  FreeAndNil(Self.FFindData);  //clear pending find data
end;

function TBaseDataCRUD.QueryFindCompareBookmark(Bookmark1, Bookmark2: TBookmark): Integer;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindCompareBookmark(Self.FFindData, Bookmark1, Bookmark2);
end;

function TBaseDataCRUD.QueryFindCount: Integer;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindCount(Self.FFindData);
end;

function TBaseDataCRUD.QueryFindFirst: Boolean;
var
  qd: IQueryDetails;
begin
  Assert(Self.HasQuery);

  {$IFDEF DEBUG}  //do not show error in production (in case a previous loop was aborted due to an exception)
  if (Self.FFindData <> nil) then  //pending QueryFindFirst must be finished first!
    raise EDataException.Create('Cannot open query because a pending multi-record loop is busy!');
  {$ENDIF}
  FreeAndNil(Self.FFindData);  //clear previous find data

  qd := Self.Query as IQueryDetails;
  Result := GetProvider.QueryFindFirst(qd, Self.FFindData);
  if not Result then
    FreeAndNil(Self.FFindData);  //clear pending find data
end;

function TBaseDataCRUD.QueryFindMove(aMoveNumRecords: Integer): Boolean;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindMove(Self.FFindData, aMoveNumRecords);
end;

function TBaseDataCRUD.QueryFindNext: Boolean;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindNext(Self.FFindData {,Self.Data});

  //last record processed?
  if not Result then
    FreeAndNil(Self.FFindData);  //clear find data
end;

function TBaseDataCRUD.QueryFindGetBookmark: TBookmark;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindGetBookmark(Self.FFindData);
end;

function TBaseDataCRUD.QueryFindGetRecNo: Integer;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindGetRecNo(Self.FFindData);
end;

procedure TBaseDataCRUD.QueryFindSetBookmark(const aBookmark: TBookmark);
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  GetProvider.QueryFindSetBookmark(Self.FFindData, aBookmark);
end;

function TBaseDataCRUD.QueryFindSetRecNo(aRecNo: Integer): Boolean;
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  Result := GetProvider.QueryFindSetRecNo(Self.FFindData, aRecNo);
end;

function TBaseDataCRUD.QuerySearchCount: Integer;
var
  qd: IQueryDetails;
begin
  Assert(Self.HasQuery);

  qd := Self.Query as IQueryDetails;
  Result := GetProvider.QuerySearchCount(qd);
end;

function TBaseDataCRUD.QuerySearchSingle: Boolean;
var
  qd: IQueryDetails;
begin
  Assert(Self.HasQuery);

  {$IFDEF DEBUG}  //do not show error in production (in case a previous loop was aborted due to an exception)
  if (Self.FFindData <> nil) then  //pending QueryFindFirst must be finished first!
    raise EDataException.Create('Cannot open query because a pending multi-record loop is busy!');
  {$ENDIF}

  qd := Self.Query as IQueryDetails;
  Result := GetProvider.QuerySearchSingle(qd);
end;

procedure TBaseDataCRUD.RecordCreate;
begin
  if not Self.Data.IsValid then
    raise EDataException.CreateFmt('Cannot create record with non-valid data: %s',
                                   [Self.Data.GetFirstValidationError().Error]);
  GetProvider.DataCreate(Self.Data);
end;

procedure TBaseDataCRUD.RecordDelete;
begin
  GetProvider.DataDelete(Self.Data);
end;

procedure TBaseDataCRUD.RecordRetrieve(aID: Int64);
begin
  RecordRetrieve(aID, []);
end;

procedure TBaseDataCRUD.RecordRetrieve(aID: Int64; aFields: array of TBaseField);
begin
  if Length(aFields) = 0 then
    NewQuery.Select
      .AllFieldsOf     (Self.Data)
      .Where.FieldValue(Self.IDField)
            .Equal     (aID)
  else
    NewQuery.Select
      .Fields          (aFields)
      .Where.FieldValue(Self.IDField)
            .Equal     (aID);

  if not Self.QuerySearchSingle then
    raise EDataException.CreateFmt('Record with ID "%d" does not exist in database', [aID]);
end;

function TBaseDataCRUD.RecordUpdate: Integer;
begin
  if not Self.Data.IsValid(True {only filled fields!}) then
    raise EDataException.Create('Cannot update record with non-valid data');
  Result := GetProvider.DataUpdate(Self.Data);
end;

class procedure TBaseDataCRUD.SetDefaultDBTypeForDBName(const aDBName: string;
  aDefaultType: TDBConnectionType);
begin
  FDefaultDBTypePerName.AddOrSetValue(aDBName, aDefaultType);
end;

procedure TBaseDataCRUD.SetQueryFindSortString(const Value: String);
begin
  Assert(Self.FFindData <> nil);  //a QueryFindFirst must be done before this
  GetProvider.QueryFindSetSortString(Self.FFindData, Value);

  //goto first record
  //QueryFindFirst     do not use this function, re-executes query!
  QueryFindMove( 1 - QueryFindGetRecNo );
end;

{ TDataCRUD<T> }

procedure TDataCRUD<T>.AfterConstruction;
begin
  {$IFDEF VER210}
  FData := TDataRecord(T.Create)
  {$ELSE}
  FData := T.Create as TDataRecord;
  {$ENDIF}

  inherited;
end;

constructor TDataCRUD<T>.Create;
begin
  inherited Create;
end;

function TDataCRUD<T>.GetData: T;
begin
  {$IFDEF VER210}
  Result := T(FData);
  {$ELSE}
  Result := FData as T;
  {$ENDIF}
end;

{ TBaseCTE_CRUD }

procedure TBaseCTE_CRUD.AfterConstruction;
begin
  inherited;
   CTEQery := TQueryBuilder.Create(MainField, CTEname);
   MaakQuery(CTEQery);
end;

function TBaseCTE_CRUD.GetIDField: TBaseIDField;
begin
   Result := MainField;
end;

function TBaseCTE_CRUD.NewQuery: IQueryBuilder;
begin
   Result := inherited;
   CTEQery.Details.SetParentQuery(nil); // niks onthouden van vorige keer
   Result.AddCTE(CTEQery);
end;

{ TDataCRUD<T> }

procedure TCTE_CRUD<T>.AfterConstruction;
begin
  {$IFDEF VER210}
  FData := TDataRecord(T.Create)
  {$ELSE}
  FData := T.Create as TDataRecord;
  {$ENDIF}

  inherited;
  Data.FCTEQuery := CTEQery; //join can see that a CTE is used
end;

constructor TCTE_CRUD<T>.Create;
begin
  inherited;
end;

function TCTE_CRUD<T>.GetData: T;
begin
  {$IFDEF VER210}
  Result := T(FData);
  {$ELSE}
  Result := FData as T;
  {$ENDIF}
end;

end.
