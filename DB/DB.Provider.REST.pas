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
unit DB.Provider.REST;

interface

uses
  System.Generics.Collections, Classes, SysUtils,
  DB.Provider, DB.Connection, DB.Settings,
  Data.Base, Data.CRUD, Data.Query, Data.DataRecord,
  IdHTTP, superobject, Meta.Data, IdSSL, IdSSLOpenSSL;

type
  TRESTDBProvider = class(TBaseDBProvider)
  private
    class var FOnAfterExecuted: TNotifyEvent;
  protected
    procedure EncryptStream(const aText: string; aDest: TStream);
    function  DecryptStream(aStream: TStream): string;

    var FHttpClient: TIdHTTP;

    procedure LoadFieldValues(aQuery: IQueryDetails; aRow: ISuperObject);
  public
    procedure  AfterConstruction; override;
    destructor Destroy; override;

    procedure DataCreate(const aData: TBaseDataRecord); override;
    function  DataUpdate(const aData: TBaseDataRecord): Integer; override;
    procedure DataDelete(const aData: TBaseDataRecord); override;

    function QuerySearchSingle(aQuery: IQueryDetails): Boolean; override;
    function QuerySearchCount (aQuery: IQueryDetails): Integer; override;

    function  QueryFindFirst(aQuery: IQueryDetails; var aDataStore: TBaseFindResults): Boolean; override;
    function  QueryFindCount(aDataStore: TBaseFindResults): Integer; override;
    function  QueryFindNext (aDataStore: TBaseFindResults): Boolean; override;
    function  QueryFindMove (aDataStore: TBaseFindResults; aMoveNumRecords: Integer): Boolean; override;
    function  QueryFindGetRecNo(aDataStore: TBaseFindResults): Integer; override;
    function  QueryFindSetRecNo(aDataStore: TBaseFindResults; aRecNo: Integer): Boolean; override;
    //
    procedure QueryExecute(aQuery: IQueryDetails; aNoErrorIfNoneAffected: boolean = false); override;
    function  QueryExecuteCount(const aQuery: IQueryDetails): Integer; override;

    function  QueryFillRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TRowDataArray; override;
    function  QueryFillMultiRowArray(aQuery: IQueryDetails; aFieldCount: Integer; aMaxRecords: Integer = -1): TMultiRowDataArray; override;

    function  ValidationExecute(aQuery: IQueryDetails): TValidationErrors; override;

    function  GetDataUpdate(const aData: TBaseDataRecord): string;
    function  GetDataInsert(const aData: TBaseDataRecord): string;
    function  ExecuteRESTQuery(const aJSONQuery, aAction: string; const aParams: TStrings = nil): string;
   // function  IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate: TIdX509; AOk: Boolean; ADepth, AError: Integer): Boolean;

    class property OnAfterExecuted: TNotifyEvent read FOnAfterExecuted write FOnAfterExecuted;
  end;

  TCRUDCacheDictionary = class(TDictionary<string,TBaseDataCRUD>)
  protected
    procedure ValueNotify(const Value: TBaseDataCRUD; Action: System.Generics.Collections.TCollectionNotification); override;
  public
    destructor Destroy; override;
  end;

  TRESTDBExecutor = class
  protected
    class var FTableCRUDs: TDictionary<string,TList<TBaseDataCRUD>>;
    class function GetCRUDByTablename(const aTable, aAlias: string): TBaseDataCRUD;
    class function GetCRUDByTablenameCache(const aTable, aAlias: string; var aCache: TCRUDCacheDictionary): TBaseDataCRUD;
    class function JSON2Query(const aJSON: string; var aCache: TCRUDCacheDictionary): IQueryDetails;
    //class procedure AddFieldvalues2JSON(const aRow: ISuperObject; const aSelectQuery: IQueryDetails);
    class function Fieldvalues2JSON(const aRow: ISuperObject; const aSelectQuery: IQueryDetails): string;
  public
    class constructor Create;
    class destructor  Destroy;

    procedure EncryptStream(const aText: string; aDest: TStream);
    function  DecryptStream(aStream: TStream): string;

    function DataCreate(const aQuery: string): string;
    function DataUpdate(const aQuery: string): string;
    function DataDelete(const aQuery: string): string;

    function QuerySearchSingle(const aQuery: string): string;
    function QuerySearchCount (const aQuery: string): string;

    function  QueryFindFirst(const aQuery: string): string;
    //
    function QueryExecute(const aQuery: string): string;
    function QueryExecuteCount(const aQuery: string): string;

    function  QueryFillMultiRowArray(aQuery: string; aFieldCount: Integer; aMaxRecords: Integer = -1): string;
  end;

  TRESTFindResults = class(TBaseFindResults)
  protected
    FRowsJSON: ISuperObject;
    FRows: TSuperArray;
    FCurrentRow: Integer;
  end;

  TBaseDataCRUD_Locking = class helper for TBaseDataCRUD
  public
    procedure Lock;
    function  TryLock: boolean;
    procedure UnLock;
  end;

  var RESTFormatsettings: TFormatSettings;
  function  Query2JSON(const aQuery: IQueryDetails): string;
  function  LoadAmericanJSON(const aJSON: string): ISuperObject;

implementation

uses
  Variants, TypInfo, Rtti,
  GlobalRTTI, ThreadFinalization, DB.Settings.REST, DB.Base,
  SymmetricCrypt, IdAuthentication, IdCompressionIntercept, IdCompressorZLib,
  StrUtils;

const
 //no plain readable password in exe but stored as GUID record :)
 C_Password: TGUID = '{701728AE-1D61-410B-9303-16DA3EC56993}';

procedure _EncryptStream(const aSource, aDest: TStream);
var
  pass: string;
  i: Integer;
begin
  aSource.Position := 0;
  aDest.Position   := 0;
  pass := GUIDToString(C_Password);
  try
    CryptStream(aSource, aDest, pass, True{encrypt});
  finally
    //clear password in mem!
    for i := 1 to Length(pass) do pass[i] := #$FF;
  end;
  aDest.Position   := 0;
end;

procedure _DecryptStream(const aSource, aDest: TStream);
var
  pass: string;
  i: Integer;
begin
  aSource.Position := 0;
  aDest.Position   := 0;
  pass := GUIDToString(C_Password);
  try
    CryptStream(aSource, aDest, pass, False{decrypt});
  finally
    //clear password in mem!
    for i := 1 to Length(pass) do pass[i] := #$FF;
  end;
  aDest.Position   := 0;
end;

function JSONString2Value(aFieldType: TFieldType; const aJSON: ISuperObject; const aFieldName: string): Variant;
var Date: TDateTime;
begin
    if aJSON.O[aFieldName] = nil then
      Result := null
    else if (aFieldType = ftFieldDouble) then
      Result := aJSON.D[aFieldName]
    else if (aFieldType = ftFieldDateTime) then
    begin
      if TryStrToDateTime(stringReplace(aJSON.S[aFieldName],'''','',[rfReplaceAll]), Date, RESTFormatsettings) then
         Result := Date
      else
         Result := aJSON.D[aFieldName];
    end
    else
      Result := aJSON.S[aFieldName]
end;

function VariantToJSONString(const aValue: Variant): string;
var
  oldThousandSeparator, oldDecimalSeparator: Char;
begin
  //default floating point is US style
  oldThousandSeparator := FormatSettings.ThousandSeparator;
  oldDecimalSeparator  := FormatSettings.DecimalSeparator;
  FormatSettings.ThousandSeparator    := ',';
  FormatSettings.DecimalSeparator     := '.';
  try
    if (Vartype(aValue) = varDate) then
       Result := DateTimeToStr(aValue, RESTFormatsettings)
    else if VarType(aValue) in [varSingle, varDouble, varCurrency, varDate] then
      Result := FloatToStr(aValue)
    else
      Result := VarToStr(aValue);
  finally
    FormatSettings.ThousandSeparator := oldThousandSeparator;
    FormatSettings.DecimalSeparator  := oldDecimalSeparator;
  end;
end;

function LoadAmericanJSON(const aJSON: string): ISuperObject;
var
  oldThousandSeparator, oldDecimalSeparator: Char;
begin
  //default floating point is US style
  oldThousandSeparator := FormatSettings.ThousandSeparator;
  oldDecimalSeparator  := FormatSettings.DecimalSeparator;
  FormatSettings.ThousandSeparator    := ',';
  FormatSettings.DecimalSeparator     := '.';
  try
    Result := SO(aJSON);
  finally
    FormatSettings.ThousandSeparator := oldThousandSeparator;
    FormatSettings.DecimalSeparator  := oldDecimalSeparator;
  end;
end;

{ TRESTDBProvider }

procedure TRESTDBProvider.EncryptStream(const aText: string; aDest: TStream);
var str: TStringStream;
begin
  str := TStringStream.Create(aText,TEncoding.UTF8);
  try
    //ENcrypt
    _EncryptStream(str, aDest);
  finally
    str.Free;
  end;
end;

function TRESTDBProvider.ExecuteRESTQuery(const aJSONQuery, aAction: string; const aParams: TStrings = nil): string;
var
  strmdata, strmCrypt: TMemoryStream;
  s, surl: string;
  restsettings: TRESTDBConnectionSettings;
begin
  if FHttpClient = nil then
  begin
    FHttpClient := TIdHTTP.Create(nil);
    //very important: otherwise no automatic decompression!
    FHttpClient.Compressor := TIdCompressorZLib.Create(FHttpClient);
  end;

  //force reset
  //FHttpClient.Disconnect(False);  only in case of errors?
  if FHttpClient.IOHandler <> nil then
    FHttpClient.IOHandler.InputBuffer.Clear;

  strmCrypt := TMemoryStream.Create;
  strmdata  := TMemoryStream.Create;
  try
    //ENcrypt
    EncryptStream(aJSONQuery, strmCrypt);

    restsettings := (Self.DBSettings.Settings as TRESTDBConnectionSettings);
    surl := Format('%s:%d/%s/%s', [restsettings.Host, restsettings.Port, restsettings.Url, aAction]);
    surl := 'http://' + StringReplace(surl, '//', '/', [rfReplaceAll]);

    if aParams <> nil then
    begin
      surl := surl + '?';
      for s in aParams do
        surl := surl + s + '&';
    end;

    try
      FHttpClient.UseNagle := False;
      if (Self.DBSettings.Settings as TRESTDBConnectionSettings).Username <> '' then
      begin
        FHttpClient.Request.BasicAuthentication := True;
        if FHttpClient.Request.Authentication = nil then
          FHttpClient.Request.Authentication := TIdBasicAuthentication.Create;
        FHttpClient.Request.Authentication.Username := restsettings.Username;
        FHttpClient.Request.Authentication.Password := restsettings.Password;
      end;
     //todo: FHttpClient.Request.AcceptEncoding := 'gzip, deflate';

      FHttpClient.Put(surl, strmCrypt, strmdata);

      if ContainsText(FHttpClient.Response.ContentEncoding, 'encrypted') then
      begin
        //TODO: custom "encrypt" encoding? so we compress first, then encrypt:
        //at this client side we should manual decrypt and decompress
        Assert(false, 'not implemented yet');
      end;
    except
      FHttpClient.Disconnect(False);
      raise;
    end;

    Result := DecryptStream(strmdata);
  finally
    strmCrypt.Free;
    strmdata.Free;
  end;

  if Assigned(OnAfterExecuted) then
    OnAfterExecuted(Self);
end;

procedure TRESTDBProvider.LoadFieldValues(aQuery: IQueryDetails; aRow: ISuperObject);
var
  a: TSuperArray;
  i: Integer;
  item: ISuperObject;
  f: TBaseField;
begin
  f := nil;
  a := aRow.O['FieldValues'].AsArray;
  for i := 0 to a.Length-1 do
  begin
    item := a.O[i];
    if aQuery.QueryType = qtSelect then
      f  := aQuery.SelectFields_Ordered.Items[i]
    else if aQuery.QueryType = qtInsert then
      f  := aQuery.MainTableField
    else
      Assert(False);
    Assert(f.FieldName = item.S['F']);

    f.LoadValue(JSONString2Value(f.FieldType, item, 'V') )
  end;
end;

procedure TRESTDBProvider.AfterConstruction;
begin
  inherited;
end;

procedure TRESTDBProvider.DataCreate(const aData: TBaseDataRecord);
var
  sjson, sdata: string;
  json: ISuperObject;
  insert: IQueryBuilder;
begin
  insert := GenerateInsertQuery(aData);
  sjson  := Query2JSON(insert as IQueryDetails);

  sdata  := ExecuteRESTQuery(sjson, 'DataCreate');
  json   := LoadAmericanJSON(sdata);

  if (json = nil) then
    raise EDataException.Create('No results received after DataCreate')
  else if (json.O['Error'] <> nil) then
    raise EDataException.CreateFmt('DataCreate failed with error = "%s: %s"',[json.O['Error'].S['Class'], json.O['Error'].S['Message']]);

  LoadFieldValues(insert as IQueryDetails, json);
end;

procedure TRESTDBProvider.DataDelete(const aData: TBaseDataRecord);
var
  sjson, sdata: string;
  json: ISuperObject;
  insert: IQueryBuilder;
  iUpdated: Integer;
begin
  insert := GenerateDeleteQuery(aData);
  sjson  := Query2JSON(insert as IQueryDetails);

  sdata  := ExecuteRESTQuery(sjson, 'DataDelete');
  json   := LoadAmericanJSON(sdata);

  if (json = nil) then
    raise EDataException.Create('No results received after DataDelete')
  else if (json.O['Error'] <> nil) then
    raise EDataException.CreateFmt('DataDelete failed with error = "%s: %s"',[json.O['Error'].S['Class'], json.O['Error'].S['Message']]);

  iUpdated := json.I['Affected'];
  if iUpdated = 0 then
    raise EDataException.Create('No records are deleted!');
  if iUpdated > 1 then
    raise EDataException.CreateFmt('More than 1 records (%d) are deleted!', [iUpdated]);
end;

function TRESTDBProvider.DataUpdate(const aData: TBaseDataRecord): Integer;
var
  sjson, sdata: string;
  json: ISuperObject;
  insert: IQueryBuilder;
  iUpdated: Integer;
begin
  insert := GenerateUpdateQuery(aData);
  sjson  := Query2JSON(insert as IQueryDetails);

  sdata  := ExecuteRESTQuery(sjson, 'DataUpdate');
  json   := LoadAmericanJSON(sdata);

  if (json = nil) then
    raise EDataException.Create('No results received after DataUpdate')
  else if (json.O['Error'] <> nil) then
    raise EDataException.CreateFmt('DataUpdate failed with error = "%s: %s"',[json.O['Error'].S['Class'], json.O['Error'].S['Message']]);

  iUpdated := json.I['Affected'];
  if iUpdated = 0 then
    raise EDataException.Create('No records are deleted!');
  if iUpdated > 1 then
    raise EDataException.CreateFmt('More than 1 records (%d) are deleted!', [iUpdated]);
  Result := iUpdated;
end;

function  TRESTDBProvider.GetDataUpdate(const aData: TBaseDataRecord): string;
var sjson: string;
    insert: IQueryBuilder;
begin
   insert := GenerateUpdateAllQuery(aData);
   sjson  := Query2JSON(insert as IQueryDetails);
   Result := sjson;
end;

function  TRESTDBProvider.GetDataInsert(const aData: TBaseDataRecord): string;
var sjson: string;
    insert: IQueryBuilder;
begin
   insert := GenerateInsertQuery(aData);
   sjson  := Query2JSON(insert as IQueryDetails);
   Result := sjson;
end;

function TRESTDBProvider.DecryptStream(aStream: TStream): string;
var
  str: TStringStream;
  s: RawByteString;
begin
  str  := TStringStream.Create('',TEncoding.UTF8);
  try
    _DecryptStream(aStream, str);
    Result := str.DataString;

    if (Result = '') and (str.Size > 0) then
    begin
      SetLength(s, str.Size);
      Move(str.Bytes[0], s[1], str.Size);
      Result := UTF8Decode(s);
    end;
  finally
    str.Free;
  end;
end;

destructor TRESTDBProvider.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

type
  TQueryBuilder_Loader = class(TQueryBuilder)
  public
    constructor Create;
  end;

{ TQueryBuilder_Loader }

constructor TQueryBuilder_Loader.Create;
begin
  //inherited Create;
end;

function Query2JSON(const aQuery: IQueryDetails): string;
var
  json, item: ISuperObject;
  f: TBaseField;
  a, a2: TSuperArray;
  wp: TWherePart;
  jp: TJoinPart;
  op: TOrderByPart;
  v: Variant;
  P: array of Variant;
begin
  json := SO();
  json.S['QueryType']  := TypInfo.GetEnumName( TypeInfo(TQueryType), Ord(aQuery.QueryType) );
  json.S['Table']      := aQuery.Table;
  json.S['TableAlias'] := aQuery.GetAliasForField(aQuery.MainTableField);
  json.S['MainTableField'] := aQuery.MainTableField.FieldName;

  json.O['SelectFields'] := SA([]);
  a := json.O['SelectFields'].AsArray;
  for f in aQuery.SelectFields_Ordered do
  begin
    a.Add( SO(['FieldName', f.FieldName,
               'TableName', f.TableName,
               'TableAlias', aQuery.GetAliasForField(f),
               'SelectOperation', TypInfo.GetEnumName( TypeInfo(TSelectOperation), Ord(aQuery.SelectFields.Items[f]))
              ]) );
  end;

  json.O['WhereParts'] := SA([]);
  a := json.O['WhereParts'].AsArray;
  for wp in aQuery.WhereParts do
  begin
    item := SO(['Class', wp.ClassName,
                'Operation', TypInfo.GetEnumName( TypeInfo(TWhereOperation), Ord(wp.FOperation) )
               ]);
    if wp is TWherePartField then
    begin
      with (wp as TWherePartField) do
      begin
        item.O['Field'] := SO(['FieldName', FField.FieldName,
                               'TableName', FField.TableName,
                               'TableAlias', aQuery.GetAliasForField(FField)
                               ]);
        item.S['Compare'] := TypInfo.GetEnumName( TypeInfo(TWhereCompare), Ord(FCompare) );

        if wp is TWherePartFieldValue then
          with (wp as TWherePartFieldValue) do
            if not VarIsNull(CompareValue) and
               not VarIsEmpty(CompareValue)
            then
              item.S['CompareValue'] := VariantToJSONString(CompareValue);

        if wp is TWherePartFieldField then
          with (wp as TWherePartFieldField) do
            item.O['CompareField'] := SO(['FieldName', FCompareField.FieldName,
                                          'TableAlias', aQuery.GetAliasForField(FCompareField),
                                          'TableName', FCompareField.TableName]);

        if wp is TWherePartFieldSet then
          with (wp as TWherePartFieldSet) do
          begin
            item.O['CompareSet'] := SA([]);
            a2 := Item.O['CompareSet'].AsArray;
            p := FCompareSet[0];  //Arjen: zit 1 niveau dieper?
            for v in p do
              a2.Add( SO(v) );
          end;
      end;
    end;

    a.Add(item);
  end;

  json.O['JoinParts'] := SA([]);
  a := json.O['JoinParts'].AsArray;
  for jp in aQuery.JoinParts do
  begin
    item := SO(['Class', jp.ClassName,
                'Operation', TypInfo.GetEnumName( TypeInfo(TJoinOperation), Ord(jp.FOperation) )
               ]);
    if jp is TJoinPartField then
    begin
      with (jp as TJoinPartField) do
      begin
        item.O['JoinField'] := SO(['FieldName', FJoinField.FieldName,
                                   'TableAlias', aQuery.GetAliasForField(FJoinField),
                                   'TableName', FJoinField.TableName]);
        item.S['Compare'] := TypInfo.GetEnumName( TypeInfo(TJoinCompare), Ord(FCompare) );

        if jp is TJoinPartFieldValue then
          with (jp as TJoinPartFieldValue) do
            if not VarIsNull(JoinValue) and
               not VarIsEmpty(JoinValue)
            then
              item.S['JoinValue'] := VariantToJSONString(JoinValue);

        if jp is TJoinPartFieldField then
          with (jp as TJoinPartFieldField) do
            item.O['SourceField'] := SO(['FieldName', FSourceField.FieldName,
                                         'TableAlias', aQuery.GetAliasForField(FSourceField),
                                         'TableName', FSourceField.TableName]);

        if jp is TJoinPartFieldSet then
          with (jp as TJoinPartFieldSet) do
          begin
            item.O['JoinSet'] := SA([]);
            a2 := json.O['JoinSet'].AsArray;
            for v in FJoinSet do
              a2.Add( SO(v) );
          end;
      end;
    end;

    a.Add(item);
  end;

  json.O['OrderByParts'] := SA([]);
  a := json.O['OrderByParts'].AsArray;
  for op in aQuery.OrderByParts do
  begin
    item := SO(['Class', op.ClassName,
                'Operation', TypInfo.GetEnumName( TypeInfo(TOrderByOperation), Ord(op.FOperation) )
               ]);
    item.O['OrderByField'] := SO(['FieldName', op.FOrderByField.FieldName,
                                  'TableAlias', aQuery.GetAliasForField(op.FOrderByField),
                                  'TableName', op.FOrderByField.TableName]);
    a.Add(item);
  end;

  if aQuery.GroupByPart <> nil then
  begin
    json.O['GroupByPart'] := SA([]);
    a := json.O['GroupByPart'].AsArray;
    for f in aQuery.GroupByPart.FGroupBySet do
    begin
      a.Add( SO(['FieldName', f.FieldName,
                 'TableAlias', aQuery.GetAliasForField(f),
                 'TableName', f.TableName]) );
    end;
  end;

  if aQuery.InsertFieldValues <> nil then
  begin
    json.O['InsertFieldValues'] := SA([]);
    a := json.O['InsertFieldValues'].AsArray;
    for f in aQuery.InsertFieldValues.Keys do
    begin
      v := aQuery.InsertFieldValues.Items[f];
      if VarIsNull(v) or VarIsEmpty(v) then
        a.Add( SO(['FieldName', f.FieldName,
                   'TableAlias', aQuery.GetAliasForField(f),
                   'TableName', f.TableName
                  ]) )
      else
        a.Add( SO(['FieldName', f.FieldName,
                   'TableName', f.TableName,
                   'TableAlias', aQuery.GetAliasForField(f),
                   'Value'    , VariantToJSONString(v)
                  ]) );
    end;
  end;

  json.B['RetrieveIdentityAfterInsert'] := aQuery.RetrieveIdentityAfterInsert;
  json.B['ActivateIdentityInsert']      := aQuery.ActivateIdentityInsert;

  if aQuery.UpdateFieldValues <> nil then
  begin
    json.O['UpdateFieldValues'] := SA([]);
    a := json.O['UpdateFieldValues'].AsArray;
    for f in aQuery.UpdateFieldValues.Keys do
    begin
      v := aQuery.UpdateFieldValues.Items[f];
      if VarIsNull(v) or VarIsEmpty(v) then
        a.Add( SO(['FieldName', f.FieldName,
                   'TableAlias', aQuery.GetAliasForField(f),
                   'TableName', f.TableName
                  ]) )
      else
        a.Add( SO(['FieldName', f.FieldName,
                   'TableName', f.TableName,
                   'TableAlias', aQuery.GetAliasForField(f),
                   'Value'    , VariantToJSONString(v)
                  ]) );
    end;
  end;
  //
  if aQuery.UpdateIncFieldValues <> nil then
  begin
    json.O['UpdateIncFieldValues'] := SA([]);
    a := json.O['UpdateIncFieldValues'].AsArray;
    for f in aQuery.UpdateIncFieldValues.Keys do
    begin
      v := aQuery.UpdateIncFieldValues.Items[f];
      if VarIsNull(v) or VarIsEmpty(v) then
        a.Add( SO(['FieldName', f.FieldName,
                   'TableAlias', aQuery.GetAliasForField(f),
                   'TableName', f.TableName
                  ]) )
      else
        a.Add( SO(['FieldName', f.FieldName,
                   'TableName', f.TableName,
                   'TableAlias', aQuery.GetAliasForField(f),
                   'Value'    , VarToStr(v)
                  ]) );
    end;
  end;

  Result := json.AsJSon();
end;

procedure TRESTDBProvider.QueryExecute(aQuery: IQueryDetails;
  aNoErrorIfNoneAffected: boolean);
var
  sjson, sdata: string;
  json: ISuperObject;
  iUpdated: Integer;
begin
  sjson := Query2JSON(aQuery);
  sdata := ExecuteRESTQuery(sjson, 'QueryExecute');
  json  := LoadAmericanJSON(sdata);

  if (json = nil) then
    raise EDataException.Create('No results received after QueryExecute')
  else if (json.O['Error'] <> nil) then
    raise EDataException.CreateFmt('QueryExecute failed with error = "%s: %s"',[json.O['Error'].S['Class'], json.O['Error'].S['Message']]);

  iUpdated := json.I['Affected'];
  if (iUpdated = 0) and
     not aNoErrorIfNoneAffected then
    raise EDBException.Create('No rows affected');
end;

function TRESTDBProvider.QueryExecuteCount(
  const aQuery: IQueryDetails): Integer;
var
  sjson, sdata: string;
  json: ISuperObject;
begin
  sjson := Query2JSON(aQuery);
  sdata := ExecuteRESTQuery(sjson, 'QueryExecuteCount');
  json  := LoadAmericanJSON(sdata);

  if (json = nil) then
    raise EDataException.Create('No results received after QueryExecute')
  else if (json.O['Error'] <> nil) then
    raise EDataException.CreateFmt('QueryExecute failed with error = "%s: %s"',[json.O['Error'].S['Class'], json.O['Error'].S['Message']]);

  Result := json.I['Count'];
end;

function TRESTDBProvider.QueryFillMultiRowArray(aQuery: IQueryDetails;
  aFieldCount, aMaxRecords: Integer): TMultiRowDataArray;
var
  sjson, sdata: string;
  json: ISuperObject;
  aRows: TSuperArray;
  row: ISuperObject;

  procedure _LoadRows;
  var
    a: TSuperArray;
    item: ISuperObject;
    emptyrow: TFieldDataArray;
    prow: PFieldDataArray;
    iRow, iField: Integer;
    f: TBaseField;
    datarecord: TDataRecord;
  begin
    Assert(aRows <> nil);
    if aRows.Length <= 0 then Exit;

    row := aRows.O[0];
    a   := row.O['FieldValues'].AsArray;
    Assert(a.Length = aQuery.SelectFields.Count);
    Assert(aQuery.SelectFields.Count > 0);

    datarecord := aQuery.SelectFields_Ordered[0].DataRecord;
    for f in aQuery.SelectFields_Ordered do
      Assert(datarecord = f.DataRecord, 'all fields must be of same TDataRecord!'); //we fill here multiple TFieldValueArray for TRowValueArray of the same tdatarecord, no suited for mixed/joined models

    SetLength(Result, aRows.Length);
    for iRow := 0 to aRows.Length-1 do
    begin
      row := aRows.O[iRow];
      a   := row.O['FieldValues'].AsArray;

      emptyrow     := AllocFieldValueArray(aFieldCount);
      //note: only direct data is filled (.RowData), not the data of sub rows (done via lazy load)
      Result[iRow].RowData.FieldValues := emptyrow;
      prow         := @Result[iRow].RowData.FieldValues;

      for iField := 0 to aQuery.SelectFields_Ordered.Count-1 do
      begin
        f    := aQuery.SelectFields_Ordered[iField];
        item := a.O[iField];
        //fast direct load value into array
        prow^[f.Position].DataType := f.FieldType;
        prow^[f.Position].LoadValue( JSONString2Value(f.FieldType, item, 'V') )
      end;
    end;
  end;

var
  str: TStringList;
begin
  sjson := Query2JSON(aQuery);
  str   := TStringList.Create;
  try
    str.Values['aFieldCount'] := IntToStr(aFieldCount);
    str.Values['aMaxRecords'] := IntToStr(aMaxRecords);

    sdata := ExecuteRESTQuery(sjson, 'QueryFillMultiRowArray', str);
  finally
    str.Free;
  end;

  json := LoadAmericanJSON(sdata);
  if json = nil then Exit;
  if not json.B['Result'] then Exit;

  aRows := json.O['Rows'].AsArray;
  _LoadRows;
end;

function TRESTDBProvider.QueryFillRowArray(aQuery: IQueryDetails; aFieldCount,
  aMaxRecords: Integer): TRowDataArray;
begin
  Assert(False, 'not implemented yet');
end;

function TRESTDBProvider.QueryFindCount(aDataStore: TBaseFindResults): Integer;
begin
  Assert(aDataStore <> nil);
  Result := (aDataStore as TRESTFindResults).FRows.Length;
end;

function TRESTDBProvider.QueryFindFirst(aQuery: IQueryDetails;
  var aDataStore: TBaseFindResults): Boolean;
var
  sjson, sdata: string;
  json: ISuperObject;
  aRows: TSuperArray;
  row: ISuperObject;
begin
  Assert(aDataStore = nil);
  sjson := Query2JSON(aQuery);
  sdata := ExecuteRESTQuery(sjson, 'QueryFindFirst');

  json := LoadAmericanJSON(sdata);
  if json = nil then Exit(False);
  if not json.B['Result'] then
     Exit(False);

  aRows := json.O['Rows'].AsArray;
  aDataStore := TRESTFindResults.Create;
  aDataStore.Query := aQuery;
  (aDataStore as TRESTFindResults).FRowsJSON := json.O['Rows'];
  (aDataStore as TRESTFindResults).FRows := aRows;
  (aDataStore as TRESTFindResults).FCurrentRow := 0;

  if aRows.Length > 0 then
  begin
    row := aRows.O[0];
    LoadFieldValues(aQuery, row);
    Result := True;
  end
  else
    Result := False;
end;

function TRESTDBProvider.QueryFindMove(aDataStore: TBaseFindResults;
  aMoveNumRecords: Integer): Boolean;
var
  results: TRESTFindResults;
  row: ISuperObject;
begin
  Result := False;
  Assert(aDataStore <> nil);
  results := (aDataStore as TRESTFindResults);
  if results.FRows.Length > results.FCurrentRow then
  begin
    Inc(results.FCurrentRow, aMoveNumRecords);

    if results.FRows.Length <= results.FCurrentRow then
      Exit(False);

    row := results.FRows.O[results.FCurrentRow];
    LoadFieldValues(aDataStore.Query, row);
    Result := True;
  end;
end;

function TRESTDBProvider.QueryFindNext(aDataStore: TBaseFindResults): Boolean;
var
  results: TRESTFindResults;
  row: ISuperObject;
begin
  Result := False;
  Assert(aDataStore <> nil);
  results := (aDataStore as TRESTFindResults);
  if results.FRows.Length > results.FCurrentRow then
  begin
    Inc(results.FCurrentRow);
    if results.FRows.Length <= results.FCurrentRow then
      Exit(False);

    row := results.FRows.O[results.FCurrentRow];
    LoadFieldValues(aDataStore.Query, row);
    Result := True;
  end;
end;

function TRESTDBProvider.QueryFindGetRecNo(aDataStore: TBaseFindResults): Integer;
var
  results: TRESTFindResults;
begin
  Assert(aDataStore <> nil);
  results := (aDataStore as TRESTFindResults);
  Result  := results.FCurrentRow;
end;

function TRESTDBProvider.QueryFindSetRecNo(aDataStore: TBaseFindResults; aRecNo: Integer): Boolean;
var
  results: TRESTFindResults;
  row: ISuperObject;
begin
  Result := False;
  Assert(aDataStore <> nil);
  results := (aDataStore as TRESTFindResults);

  if results.FRows.Length > aRecNo then
  begin
    results.FCurrentRow := aRecNo;
    if results.FRows.Length <= results.FCurrentRow then
      Exit(False);

    row := results.FRows.O[results.FCurrentRow];
    LoadFieldValues(aDataStore.Query, row);
    Result := True;
  end;
end;

function TRESTDBProvider.QuerySearchCount(aQuery: IQueryDetails): Integer;
var
  sjson, sdata: string;
  json: ISuperObject;
begin
  sjson := Query2JSON(aQuery);
  sdata := ExecuteRESTQuery(sjson, 'QuerySearchCount');
  json  := LoadAmericanJSON(sdata);

  if (json = nil) then
    raise EDataException.Create('No results received after QuerySearchCount')
  else if (json.O['Error'] <> nil) then
    raise EDataException.CreateFmt('QuerySearchCount failed with error = "%s: %s"',[json.O['Error'].S['Class'], json.O['Error'].S['Message']]);

  Result := json.I['Count'];
end;

function TRESTDBProvider.QuerySearchSingle(aQuery: IQueryDetails): Boolean;
var
  sjson, sdata: string;
  json: ISuperObject;
begin
  sjson := Query2JSON(aQuery);
  sdata := ExecuteRESTQuery(sjson, 'QuerySearchSingle');

  json := LoadAmericanJSON(sdata);
  if json = nil then Exit(False);
  if not json.B['Result'] then Exit(False);
  Result := True;

  LoadFieldValues(aQuery, json);
end;

function TRESTDBProvider.ValidationExecute(
  aQuery: IQueryDetails): TValidationErrors;
begin
  Assert(False, 'not implemented yet');
end;

{ TRESTDBExecutor }

type
  TCRUDQuery = class(TBaseDataCRUD);

class constructor TRESTDBExecutor.Create;
begin
  FTableCRUDs := TObjectDictionary<string,TList<TBaseDataCRUD>>.Create([doOwnsValues]);
end;

function TRESTDBExecutor.DataCreate(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  json: ISuperObject;
  a: TSuperArray;
  rows: TRowDataArray;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      rows   := provider.QueryFillRowArray(query, 1{only id field will be returned});
    finally
      cache.Free;
    end;

    b := (Length(rows) > 0) and (Length(rows[0].FieldValues) > 0);
    json.B['Result'] := b;

    json.O['FieldValues'] := SA([]);
    a := json.O['FieldValues'].AsArray;

    if b then
      a.Add( SO(['F', 'ID',
                 'V',     VariantToJSONString(rows[0].FieldValues[0].FieldValue)]) );
  except
    on e:exception do
      json.O['Error'] := SO(['Class', e.ClassName,
                             'Message', e.Message]);
  end;

  Result := json.AsJSon();
end;

function TRESTDBExecutor.DataDelete(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  icount: Integer;
  json: ISuperObject;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      icount := provider.QueryExecuteCount(query);
    finally
      cache.Free;
    end;

    b      := (icount > 0);

    json.B['Result']   := b;
    json.I['Affected'] := icount;
  except
    on e:exception do
      json.O['Error'] := SO(['Class', e.ClassName,
                             'Message', e.Message]);
  end;

  Result := json.AsJSon();
end;

function TRESTDBExecutor.DataUpdate(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  icount: Integer;
  json: ISuperObject;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      icount := provider.QueryExecuteCount(query);
    finally
      cache.Free;
    end;

    b := (icount > 0);
    json.B['Result']   := b;
    json.I['Affected'] := icount;
  except
    on e:exception do
      json.O['Error'] := SO(['Class', e.ClassName,
                             'Message', e.Message]);
  end;

  Result := json.AsJSon();
end;

function TRESTDBExecutor.DecryptStream(aStream: TStream): string;
var
  str: TStringStream;
  s: RawByteString;
begin
  str  := TStringStream.Create('',TEncoding.UTF8);
  try
    _DecryptStream(aStream, str);
    Result := str.DataString;

    if (Result = '') and (str.Size > 0) then
    begin
      SetLength(s, str.Size);
      Move(str.Bytes[0], s[1], str.Size);
      Result := UTF8Decode(s);
    end;
  finally
    str.Free;
  end;
end;

class destructor TRESTDBExecutor.Destroy;
begin
  FTableCRUDs.Free;
end;

procedure TRESTDBExecutor.EncryptStream(const aText: string; aDest: TStream);
var str: TStringStream;
begin
  str := TStringStream.Create(aText,TEncoding.UTF8);
  try
    //ENcrypt
    _EncryptStream(str, aDest);
  finally
    str.Free;
  end;
end;

class function TRESTDBExecutor.Fieldvalues2JSON(const aRow: ISuperObject; const aSelectQuery: IQueryDetails): string;
var
  f: TBaseField;
  a: TSuperArray;
var
  oldThousandSeparator, oldDecimalSeparator: Char;
begin
  aRow.O['FieldValues'] := SA([]);
  a := aRow.O['FieldValues'].AsArray;
  for f in aSelectQuery.SelectFields_Ordered do
  begin
    if f.IsEmptyOrNull then
      a.Add( SO(['F', f.FieldName]) )
    else if (f.FieldType = ftFieldDateTime) then
          a.Add( SO(['F', f.FieldName,
                 'V', DateTimeToStr(f.ValueAsDateTime, RESTFormatsettings)
                ]) )

    else if f.FieldType in [ftFieldDouble, ftFieldDateTime] then
      a.Add( SO(['F', f.FieldName,
                 'V', f.ValueAsDouble
                ]) )
    else
      a.Add( SO(['F', f.FieldName,
                 'V', f.ValueAsVariant
                ]) )
  end;

  //default floating point is US style
  oldThousandSeparator := FormatSettings.ThousandSeparator;
  oldDecimalSeparator  := FormatSettings.DecimalSeparator;
  FormatSettings.ThousandSeparator    := ',';
  FormatSettings.DecimalSeparator     := '.';
  try
    Result := aRow.AsJSon();
  finally
    FormatSettings.ThousandSeparator := oldThousandSeparator;
    FormatSettings.DecimalSeparator  := oldDecimalSeparator;
  end;
end;

class function TRESTDBExecutor.GetCRUDByTablename(
  const aTable, aAlias: string): TBaseDataCRUD;
var
  packages: TArray<TRttiPackage>;
  pack: TRttiPackage;
  types: TArray<TRttiType>;
  rtype, rdata: TRttiType;
  p: TRttiProperty;
  aa: TArray<TCustomAttribute>;
  rtype_crud: TRttiType;
  crud: TBaseDataCRUD;
  sKey: string;
  list: TList<TBaseDataCRUD>;
begin
  Result := nil;

  sKey := aTable + '_' + aAlias;
  System.TMonitor.Enter(FTableCRUDs);  //note: global lock
  try
    if FTableCRUDs.TryGetValue(sKey, list) then
    begin
      for Result in list do
        if Result.TryLock then
          Exit;   //we have one, quit
    end;
  finally
    System.TMonitor.Exit(FTableCRUDs);
  end;

  //we haven't get one from the pool, create new one here
  rtype_crud := GlobalRTTI.RTTICache.GetType(TypeInfo(TBaseDataCRUD));
  packages   := GlobalRTTI.RTTICache.GetPackages;
  for pack in packages do
  begin
    types := pack.GetTypes;
    for rtype in types do
    begin
      if rtype.IsInstance and
         ( (rtype.AsInstance.BaseType = rtype_crud) and
           (rtype <> rtype_crud) //skip TBaseDataCRUD itself
         ) then
      begin
        if (rtype.AsInstance.BaseType = rtype_crud) then
        begin
          if rtype.GetProperty('Data') = nil then Continue;
          rdata := rtype.GetProperty('Data').PropertyType;
          if rdata = nil then Continue;
          p := rdata.GetProperty('ID');
          if p = nil then Continue;
          aa := p.GetAttributes;
          if aa = nil then Continue;
          if not (aa[0] is TBaseTableAttribute) then Continue;
          if (aa[0] as TBaseTableAttribute).TableMetaData = nil then Continue;
          if (aa[0] as TBaseTableAttribute).TableMetaData.Table = aTable then
          begin
            crud := TBaseDataCRUDClass(rtype.AsInstance.MetaclassType).Create;
            TThreadFinalization.UnRegisterThreadObject(crud); //we manage it ourselves

            System.TMonitor.Enter(FTableCRUDs);   //note: global lock
            try
              if not FTableCRUDs.TryGetValue(sKey, list) then
              begin
                list := TObjectList<TBaseDataCRUD>.Create(true{owns});
                FTableCRUDs.Add(sKey, list);
              end;
              crud.Lock;
              list.Add(crud);
              Exit(crud);
            finally
              System.TMonitor.Exit(FTableCRUDs);
            end;
          end;
        end;
      end;
    end;
  end;
end;

class function TRESTDBExecutor.GetCRUDByTablenameCache(const aTable,
  aAlias: string; var aCache: TCRUDCacheDictionary): TBaseDataCRUD;
var
  skey: string;
begin
  Assert(aCache <> nil);
  sKey := aTable + '_' + aAlias;

  if aCache.TryGetValue(skey, Result) then
    Exit
  else
  begin
    Result := GetCRUDByTablename(aTable, aAlias);
    aCache.Add(skey, Result);
  end;
end;

class function TRESTDBExecutor.JSON2Query(const aJSON: string; var aCache: TCRUDCacheDictionary): IQueryDetails;
var
  query: TQueryBuilder_Loader;
  json, item, field: ISuperObject;
  f: TBaseField;
  a: TSuperArray;
  i,j: Integer;
  crud: TBaseDataCRUD;
  sclass: string;
  wp: TWherePart;
  jp: TJoinPart;
  op: TOrderByPart;
  WhereOperation: String;
begin
  json := LoadAmericanJSON(aJSON);
  if json = nil then Exit(nil);

  query  := TQueryBuilder_Loader.Create();
  Result := query;
  query.FQueryType      := TQueryType( TypInfo.GetEnumValue( TypeInfo(TQueryType), json.S['QueryType']) );
  query.FTable          := json.S['Table'];

  crud := Self.GetCRUDByTablenameCache(query.FTable, json.S['TableAlias'], aCache);
  if crud = nil then
    raise EUltraException.CreateFmt('Table "%s" not found in executable',[query.FTable]);
  query.FMainTableField := crud.Data.FieldByName(json.S['MainTableField']);
  if query.FMainTableField = nil then
    raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[json.S['MainTableField'], query.FTable]);
  query.DetermineAliasForField(query.FMainTableField);

  a := json.O['WhereParts'].AsArray;
  for i := 0 to a.Length-1 do
  begin
    item := a.O[i];

    wp := nil;
    sclass := item.S['Class'];
    if sclass = TWherePartFieldValue.ClassName then
    begin
      wp := TWherePartFieldValue.Create;
    end
    else if sclass = TWherePartFieldSet.ClassName then
    begin
      wp := TWherePartFieldSet.Create;
      with wp as TWherePartFieldSet do
      begin
        a := item['CompareSet'].AsArray;
        SetLength(FCompareSet, a.Length);
        for j := 0 to a.Length-1 do
         FCompareSet[j] := a.S[j];
      end;
    end
    else if sclass = TWherePartFieldField.ClassName then
    begin
      wp := TWherePartFieldField.Create;
      with wp as TWherePartFieldField do
      begin
        field := item.O['CompareField'];
        crud  := Self.GetCRUDByTablenameCache(field.S['TableName'], field.S['TableAlias'], aCache);
        if crud = nil then
          raise EUltraException.CreateFmt('Table "%s" not found in executable',[field.S['TableName']]);
        f := crud.Data.FieldByName(field.S['FieldName']);
        if f = nil then
          raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[field.S['FieldName'], field.S['TableName']]);
        FCompareField := f;
      end;
    end
    else if sclass = TWherePart.ClassName then
    begin
       wp := TWherePart.Create;
       WhereOperation := item.S['Operation'];
       if WhereOperation = 'woOr' then
          wp.FOperation := woOr;
    end
    else
      Assert(false);

    if wp is TWherePartField then
    with (wp as TWherePartField) do
    begin
      field := item.O['Field'];
      crud  := Self.GetCRUDByTablenameCache(field.S['TableName'], field.S['TableAlias'], aCache);
      if crud = nil then
        raise EUltraException.CreateFmt('Table "%s" not found in executable',[field.S['TableName']]);
      f := crud.Data.FieldByName(field.S['FieldName']);
      if f = nil then
        raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[field.S['FieldName'], field.S['TableName']]);

      FField       := f;
      FCompare     := TWhereCompare( TypInfo.GetEnumValue( TypeInfo(TWhereCompare), item.S['Compare']) );
      FOperation   := TWhereOperation( TypInfo.GetEnumValue( TypeInfo(TWhereOperation), item.S['Operation']) );

      if wp is TWherePartFieldValue then
      with wp as TWherePartFieldValue do
        CompareValue := JSONString2Value(f.FieldType, item, 'CompareValue')
    end;

    query.WhereParts.Add(wp);
  end;

  a := json.O['JoinParts'].AsArray;
  for i := 0 to a.Length-1 do
  begin
    item := a.O[i];

    jp := nil;
    sclass := item.S['Class'];
    if sclass = TJoinPartFieldValue.ClassName then
    begin
      jp := TJoinPartFieldValue.Create;
    end
    else if sclass = TJoinPartFieldSet.ClassName then
    begin
      jp := TJoinPartFieldSet.Create;
      with jp as TJoinPartFieldSet do
      begin
        a := json.O['JoinSet'].AsArray;
        SetLength(FJoinSet, a.Length);
        for j := 0 to a.Length-1 do
         FJoinSet[j] := a.S[j];
      end;
    end
    else if sclass = TJoinPartFieldField.ClassName then
    begin
      jp := TJoinPartFieldField.Create;
      with jp as TJoinPartFieldField do
      begin
        field := item.O['SourceField'];
        crud  := Self.GetCRUDByTablenameCache(field.S['TableName'], field.S['TableAlias'], aCache);
        if crud = nil then
          raise EUltraException.CreateFmt('Table "%s" not found in executable',[field.S['TableName']]);
        f := crud.Data.FieldByName(field.S['FieldName']);
        if f = nil then
          raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[field.S['FieldName'], field.S['TableName']]);
        FSourceField := f;
      end;
    end
    else if sclass = TJoinPart.ClassName then
      jp := TJoinPart.Create
    else
      Assert(false);

    if jp is TJoinPartField then
    with (jp as TJoinPartField) do
    begin
      field := item.O['JoinField'];
      crud  := Self.GetCRUDByTablenameCache(field.S['TableName'], field.S['TableAlias'], aCache);
      if crud = nil then
        raise EUltraException.CreateFmt('Table "%s" not found in executable',[field.S['TableName']]);
      f := crud.Data.FieldByName(field.S['FieldName']);
      if f = nil then
        raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[field.S['FieldName'], field.S['TableName']]);

      FJoinField   := f;
      FCompare     := TJoinCompare( TypInfo.GetEnumValue( TypeInfo(TJoinCompare), item.S['Compare']) );

      if jp is TJoinPartFieldValue then
      with jp as TJoinPartFieldValue do
        JoinValue := JSONString2Value(f.FieldType, item, 'JoinValue')
    end;
    jp.FOperation  := TJoinOperation( TypInfo.GetEnumValue( TypeInfo(TJoinOperation), item.S['Operation']) );

    query.JoinParts.Add(jp);
  end;

  item := json.O['OrderByParts'];
  if item <> nil then
  begin
    a := item.AsArray;
    for i := 0 to a.Length-1 do
    begin
      item  := a.O[i];
      field := item.O['OrderByField'];
      crud  := Self.GetCRUDByTablenameCache(field.S['TableName'], field.S['TableAlias'], aCache);
      if crud = nil then
        raise EUltraException.CreateFmt('Table "%s" not found in executable',[field.S['TableName']]);
      f := crud.Data.FieldByName(field.S['FieldName']);
      if f = nil then
        raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[field.S['FieldName'], field.S['TableName']]);

      if query.FOrderByPartList = nil then
        query.FOrderByPartList := TOrderByPartList.Create();
      op := TOrderByPart.Create;
      op.FOrderByField := f;
      op.FOperation    := TOrderByOperation( TypInfo.GetEnumValue( TypeInfo(TOrderByOperation), item.S['Operation']) );
      query.FOrderByPartList.Add(op);
    end;
  end;

  item := json.O['GroupByPart'];
  if item <> nil then
  begin
    a := item.AsArray;
    for i := 0 to a.Length-1 do
    begin
      item := a.O[i];
      crud := Self.GetCRUDByTablenameCache(item.S['TableName'], item.S['TableAlias'], aCache);
      if crud = nil then
        raise EUltraException.CreateFmt('Table "%s" not found in executable',[item.S['TableName']]);
      f := crud.Data.FieldByName(item.S['FieldName']);
      if f = nil then
        raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[item.S['FieldName'], item.S['TableName']]);

      if query.FGroupByPart = nil then
        query.FGroupByPart := TGroupByPart.Create();
      SetLength(query.FGroupByPart.FGroupBySet, Length(query.FGroupByPart.FGroupBySet)+1);
      query.FGroupByPart.FGroupBySet[High(query.FGroupByPart.FGroupBySet)] := f;
    end;
  end;

  if query.FQueryType = qtSelect then
  begin
    a := json.O['SelectFields'].AsArray;
    for i := 0 to a.Length-1 do
    begin
      item := a.O[i];
      crud := Self.GetCRUDByTablenameCache(item.S['TableName'], item.S['TableAlias'], aCache);
      if crud = nil then
        raise EUltraException.CreateFmt('Table "%s" not found in executable',[item.S['TableName']]);
      f := crud.Data.FieldByName(item.S['FieldName']);
      if f = nil then
        raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[item.S['FieldName'], item.S['TableName']]);

      query.FSelectFields.Add(f,
        TSelectOperation( TypInfo.GetEnumValue( TypeInfo(TSelectOperation), item.S['SelectOperation']) ) );
      query.FSelectFields_Ordered.Add(f);
    end;
  end
  else if query.FQueryType = qtInsert then
  begin
    query.Select.Fields([query.FMainTableField]);  //add select field for ID retrieve

    a := json.O['InsertFieldValues'].AsArray;
    for i := 0 to a.Length-1 do
    begin
      item := a.O[i];
      crud := Self.GetCRUDByTablenameCache(item.S['TableName'], item.S['TableAlias'], aCache);
      if crud = nil then
        raise EUltraException.CreateFmt('Table "%s" not found in executable',[item.S['TableName']]);
      f := crud.Data.FieldByName(item.S['FieldName']);
      if f = nil then
        raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[item.S['FieldName'], item.S['TableName']]);

      query.Insert.SetFieldWithValue(f, JSONString2Value(f.FieldType, item, 'Value') );
    end;

    if json.B['RetrieveIdentityAfterInsert'] then
      query.Insert.RetrieveIdentity;
    if json.B['ActivateIdentityInsert'] then
      query.Insert.EnableIdentityInsert;
  end
  else if query.FQueryType = qtDelete then
  begin
    //
  end
  else if query.FQueryType = qtUpdate then
  begin
    item := json.O['UpdateFieldValues'];
    if item <> nil then
    begin
      a := item.AsArray;
      for i := 0 to a.Length-1 do
      begin
        item := a.O[i];
        crud := Self.GetCRUDByTablenameCache(item.S['TableName'], item.S['TableAlias'], aCache);
        if crud = nil then
          raise EUltraException.CreateFmt('Table "%s" not found in executable',[item.S['TableName']]);
        f := crud.Data.FieldByName(item.S['FieldName']);
        if f = nil then
          raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[item.S['FieldName'], item.S['TableName']]);

        if query.FUpdateFieldValues = nil then
          query.FUpdateFieldValues := TUpdateFieldValues.Create();
        query.FUpdateFieldValues.Add(f, JSONString2Value(f.FieldType, item, 'Value'))
      end;
    end;

    item := json.O['UpdateIncFieldValues'];
    if item <> nil then
    begin
      a := item.AsArray;
      for i := 0 to a.Length-1 do
      begin
        item := a.O[i];
        crud := Self.GetCRUDByTablenameCache(item.S['TableName'], item.S['TableAlias'], aCache);
        if crud = nil then
          raise EUltraException.CreateFmt('Table "%s" not found in executable',[item.S['TableName']]);
        f := crud.Data.FieldByName(item.S['FieldName']);
        if f = nil then
          raise EUltraException.CreateFmt('Field "%s" not found in table "%s" in executable',[item.S['FieldName'], item.S['TableName']]);

        if query.FIncrementFieldValues = nil then
          query.FIncrementFieldValues := TUpdateFieldValues.Create();
        query.FIncrementFieldValues.Add(f, JSONString2Value(f.FieldType, item, 'Value'))
      end;
    end;
  end
  else
    Assert(False);
end;

function TRESTDBExecutor.QueryFillMultiRowArray(aQuery: string; aFieldCount,
  aMaxRecords: Integer): string;
begin
  Result := Self.QueryFindFirst(aQuery);
  Exit;
end;

function TRESTDBExecutor.QueryExecute(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  icount: Integer;
  json: ISuperObject;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      icount := provider.QueryExecuteCount(query);
    finally
      cache.Free;
    end;

    b := (icount > 0);
    json.B['Result']   := b;
    json.I['Affected'] := icount;
  except
    on e:exception do
      json.O['Error'] := SO(['Class', e.ClassName,
                             'Message', e.Message]);
  end;

  Result := json.AsJSon();
end;

function TRESTDBExecutor.QueryExecuteCount(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  icount: Integer;
  json: ISuperObject;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      icount := provider.QueryExecuteCount(query);
    finally
      cache.Free;
    end;
    b := (icount > 0);

    json.B['Result']   := b;
    json.I['Count'] := icount;
  except
    on e:exception do
      json.O['Error'] := SO(['Class', e.ClassName,
                             'Message', e.Message]);
  end;

  Result := json.AsJSon();
end;

function TRESTDBExecutor.QueryFindFirst(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  //json,
  row: ISuperObject;
  //aRows: TSuperArray;
  results: TBaseFindResults;
  iRow: Integer;
  cache: TCRUDCacheDictionary;
  srow, srows: string;
begin
  results := nil;

  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      b      := provider.QueryFindFirst(query, results);
      iRow   := 0;

      if b then
      repeat
        inc(iRow);
        row := SO(['Row', iRow]);
        srow := Fieldvalues2JSON(row, query);
        if srows = '' then
          srows := srow
        else
          srows := srows + ', ' + srow;
      until not TCRUDQuery(crud).GetProvider.QueryFindNext(results);
    finally
      cache.Free;
    end;
  finally
    results.Free;
  end;

  //'{"Result":true,"Rows":[]}'
  //Result := json.AsJSon();
  Result := Format('{"Result":true,"Rows":[%s]}',[srows]);
end;

function TRESTDBExecutor.QuerySearchCount(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  icount: Integer;
  json: ISuperObject;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  try
    cache := TCRUDCacheDictionary.Create;
    try
      query  := JSON2Query(aQuery, cache);
      crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
      provider := TCRUDQuery(crud).GetProvider;
      if provider.GetDBType = dbtREST then
        Assert(false, 'circular REST providers!');
      icount := provider.QuerySearchCount(query);
    finally
      cache.Free;
    end;

    b := (icount > 0);

    json.B['Result']   := b;
    json.I['Count'] := icount;
  except
    on e:exception do
      json.O['Error'] := SO(['Class', e.ClassName,
                             'Message', e.Message]);
  end;

  Result := json.AsJSon();
end;

function TRESTDBExecutor.QuerySearchSingle(const aQuery: string): string;
var
  query: IQueryDetails;
  crud: TBaseDataCRUD;
  provider: IDBProvider;
  b: Boolean;
  json: ISuperObject;
  cache: TCRUDCacheDictionary;
begin
  json := SO();
  cache := TCRUDCacheDictionary.Create;
  try
    query  := JSON2Query(aQuery, cache);
    crud   := Self.GetCRUDByTablenameCache(query.MainTableField.TableName, '', cache);
    provider := TCRUDQuery(crud).GetProvider;
    if provider.GetDBType = dbtREST then
      Assert(false, 'circular REST providers!');
    b      := provider.QuerySearchSingle(query);
  finally
    cache.Free;
  end;

  json   := SO(['Result',b]);
  Result := Fieldvalues2JSON(json, query);
end;

{ TBaseDataCRUD_Locking }

procedure TBaseDataCRUD_Locking.Lock;
begin
  System.TMonitor.Enter(Self);
end;

function TBaseDataCRUD_Locking.TryLock: boolean;
begin
  Result := System.TMonitor.TryEnter(Self);
end;

procedure TBaseDataCRUD_Locking.UnLock;
begin
  System.TMonitor.Exit(Self);
end;

{ TCRUDCacheDictionary }

destructor TCRUDCacheDictionary.Destroy;
begin
  Clear;
  inherited;
end;

procedure TCRUDCacheDictionary.ValueNotify(const Value: TBaseDataCRUD;
  Action: System.Generics.Collections.TCollectionNotification);
begin
  inherited;
  if Action in [cnRemoved, cnExtracted] then
    Value.UnLock;
end;

initialization
  TDBProvider.RegisterDBProvider(dbtREST, TRESTDBProvider);
  RESTFormatsettings := TFormatSettings.Create();
  RESTFormatsettings.DateSeparator := '-';
  RESTFormatsettings.ShortDateFormat := 'yyyy-mm-dd';
  RESTFormatsettings.TimeSeparator := ':';
  RESTFormatsettings.LongTimeFormat := 'hh:nn:ss.zzz';

end.
