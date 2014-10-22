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
unit DB.Connection.SQLServer;

interface

uses
  DB, ADODB, SysUtils, Classes, Data.DataRecord,
  DB.Base, DB.Connection, DB.Settings,
  Data.Base, Data.Query;

type
  TBaseADOConnection = class(TBaseConnection)
  private
    FApplicatie: string;
    FPassword: string;
    FUsername: string;
    FServerName: string;
  protected
    FADOConnection: TADOConnection;
    FADOCommand: TADOCommand;
    function GenerateConnectionString: string; virtual;abstract;

    function DirectExecuteData(const aSQL: string): _Recordset;
    procedure HandleSQLError(aError: Exception);
  public
    procedure  AfterConstruction; override;
    destructor Destroy; override;

    function Clone: TBaseConnection; override;

    procedure Open;  override;
    procedure Close; override;

    function IsInTransaction: Boolean;override;
    function IsSQLServerCE: Boolean;

    function DirectExecute(const aSQL: string): Integer;
    //
    function QueryExecute(const aQuery: IQueryDetails): Integer;
    function QueryExecuteData(const aQuery: IQueryDetails; var aRecordsAffected: Integer; aMaxRecords: Integer = -1): _Recordset;
    function QuerySelectCount(const aQuery: IQueryDetails; var aRecordsAffected: Integer; aMaxRecords: Integer = -1): Integer;
    function QueryExecuteValidation(const aQuery: IQueryDetails): _Recordset;

    procedure QueryCreateTable(const aTableModel: TDataRecord; const Withprimarykey, DropIfExists: Boolean);

    property ADOConnection: TADOConnection read FADOConnection;

    property ServerName: string  read FServerName write FServerName;
    property Username: string    read FUsername   write FUsername;
    property Password: string    read FPassword   write FPassword;
    //for debug: to see to which application a connection belongs to
    property Applicatie: string  read FApplicatie write FApplicatie;
  end;

  TMSSQLConnection = class(TBaseADOConnection)
  private
    FDataBaseName: string;
    class var FProvider: string;
  public
    constructor Create(aDBSettings: DB.Settings.TDBConfig); override;
    procedure SetConfig(aDBSettings: DB.Settings.TDBConfig); override;

    function Clone: TBaseConnection; override;

    procedure StartTransaction; override;
    procedure CommitTransaction; override;
    procedure RollbackTransaction; override;
    function  IsInTransaction: Boolean; override;

    function GenerateConnectionString: string; override;

    class property Provider: string read FProvider write FProvider;
    property DataBase: string read FDataBaseName write FDataBaseName;
  end;

implementation

uses
   Windows, Variants, StrUtils,
   MWUtils,
   DB.SQLBuilder, DB.Settings.SQLServer, System.Win.ComObj;

var
  _Frequency: Int64;

const
  C_SecsPerDay = 24 * 60 * 60;

function VarTypeToDataType(VarType: Integer): DB.TFieldType;
begin
  Result := DB.VarTypeToDataType(VarType);
   if Result = ftShortint then
   // -5 etc does not fit in tinyint (0..255) ADODB.DataTypeValues[ftShortint] => adTinyInt, http://msdn.microsoft.com/en-us/library/ms187745.aspx
    Result := ftSmallint
  else if Result = ftUnknown then
    Result := ftVariant;
end;

{ TBaseADOConnection }

procedure TBaseADOConnection.AfterConstruction;
begin
  inherited;
  FADOConnection := TADOConnection.Create(nil);
  FADOCommand    := TADOCommand.Create(nil);
  FADOCommand.Connection := FADOConnection;
end;

function TBaseADOConnection.Clone: TBaseConnection;
begin
  Result := inherited Clone;
  (Result as TBaseADOConnection).ServerName := Self.ServerName;
  (Result as TBaseADOConnection).Applicatie := Self.Applicatie;
  (Result as TBaseADOConnection).Username   := Self.Username;
  (Result as TBaseADOConnection).Password   := Self.Password;
end;

procedure TBaseADOConnection.Close;
begin
  inherited;
  FADOConnection.Close;
end;

destructor TBaseADOConnection.Destroy;
begin
  FADOCommand.Free;
  FADOConnection.Free;
  inherited;
end;

function TBaseADOConnection.IsInTransaction: Boolean;
begin
  Result := inherited IsInTransaction;
end;

function TBaseADOConnection.IsSQLServerCE: Boolean;
begin
  Result := ContainsText(ADOConnection.ConnectionString, '.SQLSERVER.CE.');
end;

procedure TBaseADOConnection.Open;
begin
  inherited;
  try
    FADOConnection.ConnectionString := Self.GenerateConnectionString;
    FADOConnection.LoginPrompt      := False;
    FADOConnection.Open;
  except
      on e: Exception do
        HandleSQLError(e);
  end;
end;

procedure TBaseADOConnection.QueryCreateTable(const aTableModel: TDataRecord; const WithPrimaryKey, DropIfExists: Boolean);
var
  sql: string;
  params: TVariantArray;
  iStart, iEnd: Int64;
begin
   FADOCommand.Connection := Self.FADOConnection;

   sql := TSQLBuilder.GenerateCreateTableSQL(aTableModel, WithPrimaryKey, DropIfExists);
   FADOCommand.CommandText := SQL;

   QueryPerformanceCounter(iStart);

   if Assigned(OnSQLExecuting) then
      OnSQLExecuting(sql, params);

   try
      Self.LastExecutedSQL := PreparedQueryToString(FADOCommand.CommandText, params);
      FADOCommand.Execute;
   except
      on e: Exception do
         HandleSQLError(e);
   end;

  QueryPerformanceCounter(iEnd);
   if Assigned(OnSQLExecuted) then
      OnSQLExecuted(sql, params, (iEnd - iStart)/_Frequency/C_SecsPerDay, 0);
end;

function TBaseADOConnection.QueryExecute(const aQuery: IQueryDetails): Integer;
var iStart, iEnd: Int64;
begin
  QueryPerformanceCounter(iStart);

  QueryExecuteData(aQuery, Result);

  QueryPerformanceCounter(iEnd);
end;

function TBaseADOConnection.QuerySelectCount(const aQuery: IQueryDetails; var aRecordsAffected: Integer; aMaxRecords: Integer): Integer;
var
  sql: string;
  params: TVariantArray;
   iInputParams, i: Integer;
   Data: _Recordset;
var
   iStart, iEnd: Int64;
begin
  Assert(aQuery <> nil);

  sql := 'select count(*) from ('#13#10 + TSQLBuilder.GenerateSQL(FADOConnection.DefaultDatabase, aQuery, params, aMaxRecords) + #13#10 + ') as dummy';

  FADOCommand.Connection := Self.FADOConnection;

  //fill params
  FADOCommand.ParamCheck  := True;  //auto determine type (must be done in case of null values, otherwise also manual possible)
  FADOCommand.Prepared    := False;
  FADOCommand.CommandType := cmdText;

  FADOCommand.CommandText := sql;      //does not always create params? at least not on my laptop :(
  iInputParams  := 0;
  for i := 0 to FADOCommand.Parameters.Count - 1 do
  begin
    if FADOCommand.Parameters.Items[i].Direction = pdInput then
      inc(iInputParams);
  end;
  //create missing params?
  for i := iInputParams to High(params) do
      FADOCommand.Parameters.CreateParameter('', VarTypeToDataType(VarType(params[i])), // ftVariant,
                                        pdInput, 0, params[i]);
  Assert(Length(params) = FADOCommand.Parameters.Count);
  //fill param values
  for i := 0 to High(params) do
    FADOCommand.Parameters.Items[i].Value := params[i];

  if IsSQLServerCE  then
  begin
     for i := 0 to High(params) do
     begin
        FADOCommand.Parameters.Items[i].Direction := pdInput;
        FADOCommand.Parameters.Items[i].Value     := params[i];
        sql := StringReplace(sql,'?', QuotedStr(VarToStr(params[i])),[]);
     end;

     FADOCommand.CommandText := sql;
  end;

  if Assigned(OnSQLExecuting) then
    OnSQLExecuting(sql, params);
  QueryPerformanceCounter(iStart);

  try
      Self.LastExecutedSQL := PreparedQueryToString(FADOCommand.CommandText, params);
      Data := FADOCommand.Execute(aRecordsAffected, EmptyParam);
  except
      on e: Exception do
         HandleSQLError(e);
  end;

  QueryPerformanceCounter(iEnd);
  if Assigned(OnSQLExecuted) then
    OnSQLExecuted(sql, params, (iEnd - iStart)/_Frequency/C_SecsPerDay, aRecordsAffected);

   if (Data = nil) or (Data.RecordCount = 0) then
      Exit(-1);

   Assert(Data.Fields.Count = 1);
   Result := Data.Fields[0].Value;
end;

function TBaseADOConnection.QueryExecuteData(const aQuery: IQueryDetails; var aRecordsAffected: Integer; aMaxRecords: Integer = -1): _Recordset;
var
  sql, spart: string;
  queries: array of string;
  v: Variant;
  params: TVariantArray;
   iInputParams, i, icount: Integer;
   iStart, iEnd: Int64;
begin
   Assert(aQuery <> nil);
   SetLength(queries, 1);

   if Self.IsSQLServerCE then
   begin
      sql := TSQLBuilder.GenerateSQL('', aQuery, params, -1 {no top}, dbtSQLServerCE);
      sql := StringReplace(sql, ' ..', ' ', [rfReplaceAll]);         //no .. in CE

      queries[0] := sql;

      i := Pos('select SCOPE_IDENTITY()', sql);
      if i > 0 then
         sql := StringReplace(sql, 'SCOPE_IDENTITY()', '@@IDENTITY', [rfReplaceAll]);

      i := Pos(';', sql);
      while i > 0 do
      begin
         spart := Copy(sql, i+1, Length(sql));
         sql    := Copy(sql, 1, i-1);
         queries[High(queries)] := sql;
         spart := Trim(spart);
         if spart = '' then
            Break;
         SetLength(queries, Length(queries)+1);
         queries[High(queries)] := spart;
         sql := spart;
         i := Pos(';', sql);
      end;
   end
   else
   begin
      sql := TSQLBuilder.GenerateSQL(FADOConnection.DefaultDatabase, aQuery, params, aMaxRecords);
      queries[0] := sql;
   end;

  FADOCommand.Connection := Self.FADOConnection;

  //fill params
  FADOCommand.ParamCheck  := False;  //auto determine type (must be done in case of null values, otherwise also manual possible)
  for v in params do
    if VarIsNull(v) or VarIsEmpty(v) then
    begin
      FADOCommand.ParamCheck  := True;  //auto determine type (must be done in case of null values, otherwise also manual possible)
      Break;
    end;

  for icount := 0 to High(queries) do
  begin
    sql := queries[icount];
    if IsSQLServerCE then
      sql := PreparedQueryToString(sql, params);

    FADOCommand.CommandType := cmdText;
    FADOCommand.CommandText := sql;      //does not always create params? at least not on my laptop :(
    FADOCommand.Prepared    := False;

    //contains params? (sql server style)
    if Pos('?', sql) > 0  then
    begin
        iInputParams  := 0;
      //  iOutputParams := 0;
        for i := 0 to FADOCommand.Parameters.Count - 1 do
        begin
          if FADOCommand.Parameters.Items[i].Direction = pdInput then
            inc(iInputParams);
      //    if FADOCommand.Parameters.Items[i].Direction = pdOutput then
      //      inc(iOutputParams);
        end;

        for i := iInputParams to High(params) do
            FADOCommand.Parameters.CreateParameter('', VarTypeToDataType(VarType(params[i])), // ftVariant,
                                              pdInput, 0, params[i]);

        Assert(Length(params) = FADOCommand.Parameters.Count);
        for i := 0 to High(params) do
        begin
          FADOCommand.Parameters.Items[i].Direction := pdInput;
            if not VarIsNull(params[i]) and not VarIsEmpty(params[i]) and (VarToStr(params[i]) = '') then
               FADOCommand.Parameters.Items[i].Size := 1;
          FADOCommand.Parameters.Items[i].Value     := params[i];
        end;
    end;

      if Assigned(OnSQLExecuting) then
         OnSQLExecuting(sql, params);
      QueryPerformanceCounter(iStart);

    if IsSQLServerCE then
    begin
      FADOCommand.Connection.CursorLocation := clUseServer;   //vage fout icm not null field en left join (E_FAIL)
      FADOCommand.CommandText := sql;      //params does not always work?
    end;

    try
       Self.LastExecutedSQL := PreparedQueryToString(FADOCommand.CommandText, params);
       Result := FADOCommand.Execute(aRecordsAffected, EmptyParam);
    except
       on e: Exception do
          HandleSQLError(e);
    end;

    QueryPerformanceCounter(iEnd);
      if Assigned(OnSQLExecuted) then
    OnSQLExecuted(sql, params, (iEnd - iStart)/_Frequency/C_SecsPerDay, aRecordsAffected);
  end;

  FADOCommand.Connection := nil;
end;

function TBaseADOConnection.QueryExecuteValidation(const aQuery: IQueryDetails): _Recordset;
var
  sql: string;
  iRecordsAffected: Integer;
var iStart, iEnd: Int64;
begin
  Assert(aQuery <> nil);

  sql := TSQLBuilder.GenerateValidationSQL(aQuery);

  FADOCommand.Connection  := Self.FADOConnection;
  //fill params
  FADOCommand.ParamCheck  := True;  //auto determine type (must be done in case of null values, otherwise also manual possible)
  FADOCommand.Prepared    := False;
  FADOCommand.CommandType := cmdText;

  FADOCommand.CommandText := sql;      //does not always create params? at least not on my laptop :(
  if sql = '' then Exit(nil);

  if Assigned(OnSQLExecuting) then
    OnSQLExecuting(sql, nil);
  QueryPerformanceCounter(iStart);

  try
      Self.LastExecutedSQL := FADOCommand.CommandText;
      Result := FADOCommand.Execute(iRecordsAffected, EmptyParam);
  except
      on e: Exception do
         HandleSQLError(e);
  end;
  QueryPerformanceCounter(iEnd);

  if Assigned(OnSQLExecuted) then
    OnSQLExecuted(sql, nil, (iEnd - iStart)/_Frequency/C_SecsPerDay, iRecordsAffected);
end;

function TBaseADOConnection.DirectExecute(const aSQL: string): Integer;
var iStart, iEnd: Int64;
begin
  if Assigned(OnSQLExecuting) then
    OnSQLExecuting(aSQL, nil);
  QueryPerformanceCounter(iStart);

  Self.LastExecutedSQL := aSQL;
  FADOConnection.Execute(aSQL, Result);

  QueryPerformanceCounter(iEnd);
  if Assigned(OnSQLExecuted) then
    OnSQLExecuted(aSQL, nil, (iEnd - iStart)/_Frequency/C_SecsPerDay, Result);
end;

function TBaseADOConnection.DirectExecuteData(const aSQL: string): _Recordset;
var iStart, iEnd: Int64;
    RowsAffected: Integer;
begin
   FADOCommand.Connection := Self.FADOConnection;
   FADOCommand.CommandText := aSQL;
   RowsAffected := 0;

   if Assigned(OnSQLExecuting) then
      OnSQLExecuting(aSQL, nil);
   QueryPerformanceCounter(iStart);

   try
      Self.LastExecutedSQL := FADOCommand.CommandText;
      Result := FADOCommand.Execute;
      RowsAffected :=  Result.RecordCount;
   except
      on e: Exception do
         HandleSQLError(e);
   end;

   QueryPerformanceCounter(iEnd);
   if Assigned(OnSQLExecuted) then
      OnSQLExecuted(aSQL, nil, (iEnd - iStart)/_Frequency/C_SecsPerDay, RowsAffected);
end;

procedure TBaseADOConnection.HandleSQLError(aError: Exception);
var
  i: Integer;
  s: string;
begin
  s := '';
  for i := 0 to FADOConnection.Errors.Count-1 do
  begin
    s := s + #13#10;
    s := s +
         'Source: ' + FADOConnection.Errors[i].Source + #13#10 +
         'Description: ' + FADOConnection.Errors[i].Description + #13#10 +
         'SQLState: ' + FADOConnection.Errors[i].SQLState + #13#10 +
         'Number: ' + IntToHex(FADOConnection.Errors[i].Number, 8) + #13#10 +  //http://technet.microsoft.com/en-us/library/ms171852.aspx
         'NativeError: ' + IntToStr(FADOConnection.Errors[i].NativeError);     //http://technet.microsoft.com/en-us/library/ms172060.aspx
  end;
  raise EDBException.Create('Error occured while executing query: '#13#10 +
                            aError.Message + #13#10 +
                            //'Query: ' + #13#10 +
                            //FADOCommand.CommandText + #13#10 +
                            'Extended error: ' + s,
                            Self.LastExecutedSQL);
end;

{ TMSSQLConnection }

function TMSSQLConnection.Clone: TBaseConnection;
begin
  Result := inherited Clone;
  (Result as TMSSQLConnection).DataBase := Self.DataBase;
end;

procedure TMSSQLConnection.CommitTransaction;
var
  sql: string;
begin
  inherited CommitTransaction;

  if FTransactionLevel >= 1 then
  begin
    sql := 'COMMIT TRANSACTION';
    sql := sql + ' CRUD' + IntToStr(FTransactionLevel-1);
    DirectExecute(sql);
  end
  else
    raise EDBException.Create('Trying to commit without having a transaction', LastExecutedSQL);
end;

constructor TMSSQLConnection.Create(aDBSettings: DB.Settings.TDBConfig);
var
  mssqlsettings: TBaseMSSqlServerDBConnectionSettings;
begin
  inherited;

  mssqlsettings := aDBSettings.Settings as TBaseMSSqlServerDBConnectionSettings;
  if mssqlsettings is TMSSqlServerDBConnectionSettings then
  begin
    ServerName := (mssqlsettings as TMSSqlServerDBConnectionSettings).Server;
      DataBase := (mssqlsettings as TMSSqlServerDBConnectionSettings).DataBase;
    Username   := (mssqlsettings as TMSSqlServerDBConnectionSettings).Username;
  end
  else if mssqlsettings is TMSSqlServerCEDBConnectionSettings then
    ServerName := (mssqlsettings as TMSSqlServerCEDBConnectionSettings).FileName;
  Password     := mssqlsettings.Password;
  Applicatie   := ParamStr(0); //Application.Name;
  Provider     := mssqlsettings.Provider;
end;

procedure TMSSQLConnection.SetConfig(aDBSettings: DB.Settings.TDBConfig);
var
  mssqlsettings: TBaseMSSqlServerDBConnectionSettings;
begin
  mssqlsettings := aDBSettings.Settings as TBaseMSSqlServerDBConnectionSettings;
  if mssqlsettings is TMSSqlServerDBConnectionSettings then
  begin
    ServerName := (mssqlsettings as TMSSqlServerDBConnectionSettings).Server;
      DataBase := (mssqlsettings as TMSSqlServerDBConnectionSettings).DataBase;
    Username   := (mssqlsettings as TMSSqlServerDBConnectionSettings).Username;
  end
  else if mssqlsettings is TMSSqlServerCEDBConnectionSettings then
    ServerName := (mssqlsettings as TMSSqlServerCEDBConnectionSettings).FileName;
  Password     := mssqlsettings.Password;
  Applicatie   := ParamStr(0); //Application.Name;
  Provider     := mssqlsettings.Provider;

  try
     FADOConnection.Close;
     FADOConnection.ConnectionString := Self.GenerateConnectionString;
     FADOConnection.Open;
  except
      on e: Exception do
      HandleSQLError(e);
  end;
end;

function TMSSQLConnection.GenerateConnectionString: string;
var DBSize: Integer;
begin
  if Provider = '' then
    Result := 'Provider=SQLOLEDB.1;'
  else
    Result := 'Provider=' + Provider + ';';   //e.g. SQLNCLI11

  if ContainsText(Result, '.SQLSERVER.CE.') then         // 'Microsoft.SQLSERVER.CE.OLEDB.4.0';
  begin
    if Password <> '' then
         Result := Result + 'SSCE:Database Password=' + Password + ';';
      Result := Result + 'Data Source=' + ServerName + ';';

      DBSize := 4090;       //4 Gig is MAx

      Result := Result + 'Mode=ReadWrite|Share Deny None;SSCE:Max Buffer Size=4096;Persist Security Info=False;SSCE:Max Database Size='+IntToStr(DBSize);

      //'Provider=Microsoft.SQLSERVER.CE.OLEDB.3.5;Data Source=c:\temp\localdb.sdf;
      //Mode=ReadWrite|Share Deny None;SSCE:Max Buffer Size=4096;SSCE:Database Password=sprvsr;
      //SSCE:Encrypt Database=False;SSCE:Default Lock Escalation=100;SSCE:Temp File Directory="";
      //SSCE:Default Lock Timeout=5000;SSCE:AutoShrink Threshold=60;SSCE:Flush Interval=10;
      //SSCE:Test Callback Pointer=0;SSCE:Max Database Size=256;SSCE:Temp File Max Size=128;
      //SSCE:Encryption Mode=0;SSCE:Case Sensitive=False'
  end
  else
  begin
    if (Username = '') and (Password = '') then
    //Windows Authentication
    begin
      //Provider=SQLNCLI11.1;Integrated Security=SSPI;Persist Security Info=False;User ID="";Initial Catalog="";Data Source=localhost;Initial File Name="";Server SPN=""
      Result := Result +
                'Integrated Security=SSPI;' +
                'Persist Security Info=' + 'false' + ';' +
                'Initial Catalog=' +       DataBase + ';' +
                //vanaf SQL Server 2005?
                //'MultipleActiveResultSets=true;MarsConn=yes;MARS_Connection=yes;MARS Connection=True;' +
                'Data Source=' +           ServerName;
    end
    else
      //SQL Server Authentication
      Result := Result +
                'Password=' +              Password + ';' +
                'Persist Security Info=' + 'true' + ';' +
                'User ID=' +               Username + ';' +
                'Initial Catalog=' +       DataBase + ';' +
                //vanaf SQL Server 2005?
                //'MultipleActiveResultSets=true;MarsConn=yes;MARS_Connection=yes;MARS Connection=True;' +
                'Data Source=' +           ServerName;

    if Applicatie <> '' then
      Result := Result + ';' + 'Application Name=[' + Applicatie + ']';
  end;
end;

function TMSSQLConnection.IsInTransaction: Boolean;
begin
  Result := inherited IsInTransaction;
end;

procedure TMSSQLConnection.RollbackTransaction;
var
  sql: string;
begin
  if FTransactionLevel >= 1 then
  begin
    sql := 'ROLLBACK TRANSACTION';
    sql := sql + ' CRUD' + IntToStr(FTransactionLevel-1);
    try
      DirectExecute(sql);   //rollback savepoint, does not rollback transaction! (@@TRANCOUNT still the same)
      CommitTransaction;   //commit "empty" transaction to decrement transaction level (weird MS stuff!)
    except
      FTransactionLevel := 0;     //full rollback done, so level = 0
      //make full rollback (also other sub transactions)
      sql := 'ROLLBACK TRANSACTION';
      try
        DirectExecute(sql);
      except
        //in case of "EOleException: The ROLLBACK TRANSACTION request has no corresponding BEGIN TRANSACTION"
        //this rollback will also fail, so just 'eat' it: we just want to be sure that a rollback is done
      end;
    end;
  end
  else
    raise EDBException.Create('Trying to rollback without having a transaction', LastExecutedSQL);
end;

procedure TMSSQLConnection.StartTransaction;
var
  sql: string;
begin
  inherited StartTransaction;

  //nested transactions:
  //http://support.microsoft.com/kb/238163

  sql := 'BEGIN TRANSACTION' + ' CRUD' + IntToStr(FTransactionLevel);
  //make savepoint, to be able to rollback a nested transaction
  //http://msdn.microsoft.com/en-us/library/ms181299.aspx     : rollback
  //http://msdn.microsoft.com/en-us/library/ms188378.aspx     : savepoint
  sql := sql + ';' +   //single execute of 2 statements
         'SAVE TRANSACTION CRUD' + IntToStr(FTransactionLevel);
  DirectExecute(sql);
end;

initialization
  QueryPerformanceFrequency(_Frequency);
  TBaseConnection.RegisterDBConnection(dbtSQLServer, TMSSQLConnection);
  TBaseConnection.RegisterDBConnection(dbtSQLServerCE, TMSSQLConnection);

end.
