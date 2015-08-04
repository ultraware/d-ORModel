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
unit DB.Provider;

interface

uses
  Generics.Collections,
  DB.Settings,
  Data.Base,
  Data.Query, Data.DataRecord, DB;

type
  TBaseDBProvider = class;
  TDBProviderClass = class of TBaseDBProvider;

  TDBProvider = class
  protected
    class var FDBProviderClasses: TDictionary<TDBConnectionType,TDBProviderClass>;
  public
    class constructor Create;
    class destructor  Destroy;

    class procedure RegisterDBProvider(aDBType: TDBConnectionType; aProviderClass: TDBProviderClass);
    class function  GetRegisteredDBProvider(aDBType: TDBConnectionType): TDBProviderClass;
  end;

  TBaseFindResults = class;

  IDBProvider = interface
  ['{2A2E05CD-0301-46FD-B097-0409957B041D}']
    function GetDBType: TDBConnectionType;
    function GetDBSettings: DB.Settings.TDBConfig;

    procedure DataCreate(const aData: TBaseDataRecord);
    function DataUpdate(const aData: TBaseDataRecord): Integer;
    procedure DataDelete(const aData: TBaseDataRecord);

    function QuerySearchSingle(aQuery: IQueryDetails{; aFillRecord: TDataRecord}): Boolean;
    function QuerySearchCount (aQuery: IQueryDetails): Integer;

    function  QueryFindFirst(aQuery: IQueryDetails; var aDataStore: TBaseFindResults{; aFillRecord: TDataRecord}): Boolean;
    function  QueryFindCount(aDataStore: TBaseFindResults): Integer;
    function  QueryFindNext (aDataStore: TBaseFindResults{; aFillRecord: TDataRecord}): Boolean;
    function  QueryFindMove (aDataStore: TBaseFindResults; aMoveNumRecords: Integer): Boolean;
    function  QueryFindGetRecNo(aDataStore: TBaseFindResults): Integer;
    function  QueryFindSetRecNo(aDataStore: TBaseFindResults; aRecNo: Integer): Boolean;
    function  QueryFindGetSortString(aDataStore: TBaseFindResults): string;
    procedure QueryFindSetSortString(aDataStore: TBaseFindResults; const aSortString: string);
    function  QueryFindGetBookmark(aDataStore: TBaseFindResults): TBookmark;
    procedure QueryFindSetBookmark(aDataStore: TBaseFindResults; const aBookmark: TBookmark);
    function  QueryFindCompareBookmark(aDataStore: TBaseFindResults; Bookmark1, Bookmark2: TBookmark): Integer;
    //
    procedure QueryExecute(aQuery: IQueryDetails; aNoErrorIfNoneAffected: boolean = false);
    function  QueryExecuteCount(const aQuery: IQueryDetails): Integer;

    function  QueryFillRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TRowDataArray;
    function  QueryFillMultiRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TMultiRowDataArray;

    procedure QueryCreateTable(const aTableModel: TDataRecord; const Withprimarykey, DropIfExists: Boolean);

    function  ValidationExecute(aQuery: IQueryDetails): TValidationErrors;
  end;

  TBaseDBProvider = class(TInterfacedObject,
                          IDBProvider)
  private
    FDBSettings: DB.Settings.TDBConfig;
  public
    class function GetOrCreateThreadProvider(aDBSettings: DB.Settings.TDBConfig): IDBProvider;
    constructor Create(aDBSettings: DB.Settings.TDBConfig); virtual;

    property DBSettings: DB.Settings.TDBConfig read FDBSettings;
  protected
    function GenerateInsertQuery(const aData: TBaseDataRecord): IQueryBuilder;
    function GenerateUpdateQuery(const aData: TBaseDataRecord): IQueryBuilder;
    function GenerateDeleteQuery(const aData: TBaseDataRecord): IQueryBuilder;
    function GenerateUpdateAllQuery(const AData: TBaseDataRecord): IQueryBuilder;

    {IDBProvider}
    function GetDBType: TDBConnectionType;
    function GetDBSettings: DB.Settings.TDBConfig;

    procedure DataCreate(const aData: TBaseDataRecord); virtual; abstract;
    function DataUpdate(const aData: TBaseDataRecord): integer; virtual; abstract;
    procedure DataDelete(const aData: TBaseDataRecord); virtual; abstract;

    function QuerySearchSingle(aQuery: IQueryDetails{; aFillRecord: TDataRecord}): Boolean; virtual; abstract;
    function QuerySearchCount (aQuery: IQueryDetails): Integer; virtual; abstract;

    function  QueryFindFirst(aQuery: IQueryDetails; var aDataStore: TBaseFindResults{; aFillRecord: TDataRecord}): Boolean; virtual; abstract;
    function  QueryFindCount(aDataStore: TBaseFindResults): Integer; virtual; abstract;
    function  QueryFindNext (aDataStore: TBaseFindResults{; aFillRecord: TDataRecord}): Boolean; virtual; abstract;
    function  QueryFindMove (aDataStore: TBaseFindResults; aMoveNumRecords: Integer): Boolean; virtual; abstract;
    function  QueryFindGetRecNo(aDataStore: TBaseFindResults): Integer; virtual; abstract;
    function  QueryFindSetRecNo(aDataStore: TBaseFindResults; aRecNo: Integer): Boolean; virtual; abstract;
    function  QueryFindGetSortString(aDataStore: TBaseFindResults): string; virtual; abstract;
    procedure QueryFindSetSortString(aDataStore: TBaseFindResults; const aSortString: string); virtual; abstract;
    function  QueryFindGetBookmark(aDataStore: TBaseFindResults): TBookmark; virtual; abstract;
    procedure QueryFindSetBookmark(aDataStore: TBaseFindResults; const aBookmark: TBookmark); virtual; abstract;
    function  QueryFindCompareBookmark(aDataStore: TBaseFindResults;Bookmark1, Bookmark2: TBookmark): Integer; virtual; abstract;
    //
    procedure QueryExecute(aQuery: IQueryDetails; aNoErrorIfNoneAffected: boolean = false); virtual; abstract;
    function  QueryExecuteCount(const aQuery: IQueryDetails): Integer; virtual; abstract;

    function  QueryFillRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TRowDataArray; virtual; abstract;
    function  QueryFillMultiRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TMultiRowDataArray; virtual; abstract;

    procedure QueryCreateTable(const aTableModel: TDataRecord; const WithPrimaryKey, DropIfExists: Boolean); virtual; // abstract;
    function  ValidationExecute(aQuery: IQueryDetails): TValidationErrors; virtual; abstract;
  end;

  TBaseFindResults = class
  protected
    FQuery: IQueryDetails;
  public
    property Query: IQueryDetails read FQuery write FQuery;
  end;

implementation

uses
  Meta.Data, ThreadFinalization
  ;

threadvar
  //provider per dbconfig per thread
  _ThreadProviders: TDictionary<DB.Settings.TDBConfig, IDBProvider>;

{ TDBProvider }

class constructor TDBProvider.Create;
begin
  FDBProviderClasses := TDictionary<TDBConnectionType,TDBProviderClass>.Create;
end;

class destructor TDBProvider.Destroy;
begin
  FDBProviderClasses.Free;
end;

class function TDBProvider.GetRegisteredDBProvider(
  aDBType: TDBConnectionType): TDBProviderClass;
begin
  if not FDBProviderClasses.TryGetValue(aDBType, Result) then
    Result := nil;
end;

class procedure TDBProvider.RegisterDBProvider(aDBType: TDBConnectionType;
  aProviderClass: TDBProviderClass);
begin
  FDBProviderClasses.Add(aDBType, aProviderClass);
end;

{ TBaseDBProvider }

constructor TBaseDBProvider.Create(aDBSettings: TDBConfig);
begin
  FDBSettings := aDBSettings;
end;

function TBaseDBProvider.GenerateDeleteQuery(
  const aData: TBaseDataRecord): IQueryBuilder;
var
  f: TBaseField;
begin
  if aData.Count = 0 then Exit(nil);

  //find first ID field and usevalue of it
  for f in aData do
    if f.FieldType = ftFieldID then
    begin
      Result := TQueryBuilder.Create(f);
      Result
        .Delete
        .Where
          .FieldValue(f)
          .Equal     (f.ValueAsVariant);
      Break;
    end;
  Assert(Result <> nil, 'no ID field found!');
end;

function TBaseDBProvider.GenerateInsertQuery(
  const aData: TBaseDataRecord): IQueryBuilder;
var
  f: TBaseField;
  val: variant;
begin
  if aData.Count = 0 then Exit(nil);
  Result := TQueryBuilder.Create( aData.Items[0] );
  for f in aData do
  begin
    if not f.IsEmpty then   //Alleen f.IsEmpty!
    begin
      if (f.FieldType = ftFieldID) and f.IsNull then
         continue; // niet in insert values, al helemaal geen identity insert aanzetten

      if f.IsNull And f.HasDefaultValue then
         val := f.DefaultValue
      else
         val := f.ValueAsVariant;

      Result.Insert
        .SetFieldWithValue(f, val);

      //value supplied for ID field? then use identity insert
      if (f.FieldType = ftFieldID) then
      begin
        if f.IsAutoInc then      //PK can be without autoinc!
          Result.Insert
            .EnableIdentityInsert;
      end;
    end;
    //get ID value after insert
    Result.Insert.RetrieveIdentity;
  end;
end;

function TBaseDBProvider.GenerateUpdateQuery(const aData: TBaseDataRecord): IQueryBuilder;
var updateEnd: IUpdateEnd;
  f: TBaseField;
  val: Variant;
begin
  if aData.Count = 0 then Exit;
  Result := TQueryBuilder.Create( aData.Items[0] );
  for f in aData do
  begin
    if not f.IsEmpty and
       f.IsModified and
       (F.FieldType <> ftFieldID) then
    begin
       if f.IsNull And f.HasDefaultValue then
          val := f.DefaultValue
       else
          val := f.ValueAsVariant;

       //check local constraint
       //todo: also on server possible:
       //  select 1 where 'test' in ('test', 'test2')
       //  select 1 from Table where id = :id and (field2 in ('test', 'test2'))
       (*
       if (TBaseField_Ext(f).MetaField <> nil) and
          (TBaseField_Ext(f).MetaField.ConstraintMeta <> nil) then
       begin
         constraint := TBaseField_Ext(f).MetaField.ConstraintMeta;
         //same table?
         if constraint.IsSameTableField(TBaseField_Ext(f).MetaField) then
         begin
           f2 := aData.FieldByName( constraint.TableField.FieldMetaData.FieldName );
           Assert(f2 <> nil);
           if f2.IsEmpty then Assert(False, 'Can''t check constraint on empty value');
           constraint.CheckLocalValue(f2.ValueAsString);
         end;
         //(update as IQueryDetails)
       end;
       *)

       updateEnd := Result.Update
                          .SetField(f)
                          .WithValue(val);
    end;
  end;

  Assert(updateEnd <> nil);

  //find first ID field and usevalue of it
  for f in aData do
    if f.FieldType = ftFieldID then
    begin
      updateEnd.Where
        .FieldValue(f)
        .Equal     (f.ValueAsVariant);
      updateEnd := nil;
      Break;
    end;
  Assert(updateEnd = nil, 'no ID field found!');
end;

function TBaseDBProvider.GenerateUpdateAllQuery(const AData: TBaseDataRecord): IQueryBuilder;
var updateEnd: IUpdateEnd;
  f: TBaseField;
  val: Variant;
begin
   if aData.Count = 0 then
      Exit;

   Result := TQueryBuilder.Create( aData.Items[0] );
   for f in aData do
   begin
      if not f.IsEmpty and f.IsModified and (F.FieldType <> ftFieldID) then
      begin
         if f.IsNull And f.HasDefaultValue then
            val := f.DefaultValue
         else
            val := f.ValueAsVariant;

         updateEnd := Result.Update
                          .SetField(f)
                          .WithValue(val);
      end;
   end;

   Assert(updateEnd <> nil);
   //find first ID field and usevalue of it
   for f in aData do
   begin
      if f.FieldType = ftFieldID then
      begin
        updateEnd.Where
         .FieldValue(f)
         .Equal     (f.ValueAsVariant);
        updateEnd := nil;
        Break;
      end;
   end;
   Assert(updateEnd = nil, 'no ID field found!');
end;

function TBaseDBProvider.GetDBSettings: DB.Settings.TDBConfig;
begin
  Result := FDBSettings;
end;

function TBaseDBProvider.GetDBType: TDBConnectionType;
begin
  Result := DBSettings.DBType;
end;

class function TBaseDBProvider.GetOrCreateThreadProvider(aDBSettings: DB.Settings.TDBConfig): IDBProvider;
begin
  if _ThreadProviders = nil then
  begin
    _ThreadProviders := TDictionary<DB.Settings.TDBConfig, IDBProvider>.Create();
    TThreadFinalization.RegisterThreadObject(_ThreadProviders);  //auto free when thread terminates
  end;

  if not _ThreadProviders.TryGetValue(aDBSettings, Result) then
  begin
    Result := Self.Create(aDBSettings);
    _ThreadProviders.Add(aDBSettings, Result);
  end;
end;

procedure TBaseDBProvider.QueryCreateTable(const aTableModel: TDataRecord; const WithPrimaryKey, DropIfExists: Boolean);
begin
   Assert(False, 'Not implemented for this provider');
end;

end.
