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
unit DB.Connector;

interface

uses
  DB.Base, DB.Connection, DB.Settings;

type
  TDBConnector = class
  private
    class var FEnabled: boolean;
    class var FAutoConnect: boolean;

    class function GetOnSQLExecuted: TSQLExecutedEvent; static;
    class function GetOnSQLExecuting: TSQLExecutingEvent; static;
    class procedure SetOnSQLExecuted(const Value: TSQLExecutedEvent); static;
    class procedure SetOnSQLExecuting(const Value: TSQLExecutingEvent); static;
  public
    //allowed to connect at all?
    class property Enabled    : boolean read FEnabled write FEnabled;
    //auto connect at application startup?
    class property AutoConnect: boolean read FAutoConnect write FAutoConnect;

    class procedure Connect    (aDBConnection: DB.Settings.TDBConfig = nil);
    class function  TryConnect (aDBConnection: DB.Settings.TDBConfig      ): boolean;
    class function  IsConnected(aDBConnection: DB.Settings.TDBConfig = nil): boolean;
    class procedure AddConnection(aDBConnection: DB.Settings.TDBConfig = nil);

    class property OnSQLExecuting: TSQLExecutingEvent read GetOnSQLExecuting write SetOnSQLExecuting;
    class property OnSQLExecuted : TSQLExecutedEvent  read GetOnSQLExecuted  write SetOnSQLExecuted;
  end;

implementation

uses
  SysUtils, DB.ConnectionPool;

{ TDBConnector }

class procedure TDBConnector.AddConnection(
  aDBConnection: DB.Settings.TDBConfig);
var
  conclass: TBaseConnectionClass;
  con: TBaseConnection;
begin
  Assert(not IsConnected(aDBConnection));

  con := nil;
  conclass := TBaseConnection.GetDBConnectionClass(aDBConnection.DBType);
  Assert(conclass <> nil);
  try
    con := conclass.Create(aDBConnection);
    //con.Open;
    TDBConnectionPool.PutConnectionToPool(aDBConnection, con);
  except
    con.Free;
  end;
end;

class procedure TDBConnector.Connect(aDBConnection: DB.Settings.TDBConfig = nil);
var
  dbcon: DB.Settings.TDBConfig;
begin
  if Enabled then
  begin
    if aDBConnection = nil then
    begin
      for dbcon in TDBSettings.Instance.DBConnections do
        if not TryConnect(dbcon) then
           raise EDBException.CreateFmt('Could not connect to databasename "%s"', [dbcon.Name])
    end
    else if not TryConnect(aDBConnection) then
      raise EDBException.CreateFmt('Could not connect to databasename "%s"', [aDBConnection.Name])
  end
  else
    raise EDBException.Create('Not allowed to make a connection to the database');
end;

class function TDBConnector.GetOnSQLExecuted: TSQLExecutedEvent;
begin
  Result := TBaseConnection.OnSQLExecuted;
end;

class function TDBConnector.GetOnSQLExecuting: TSQLExecutingEvent;
begin
  Result := TBaseConnection.OnSQLExecuting;
end;

class function TDBConnector.IsConnected(aDBConnection: DB.Settings.TDBConfig = nil): boolean;
begin
  Result := TDBConnectionPool.HasConnections(aDBConnection);
end;

class procedure TDBConnector.SetOnSQLExecuted(const Value: TSQLExecutedEvent);
begin
  TBaseConnection.OnSQLExecuted := Value;
end;

class procedure TDBConnector.SetOnSQLExecuting(const Value: TSQLExecutingEvent);
begin
  TBaseConnection.OnSQLExecuting := Value;
end;

class function TDBConnector.TryConnect(aDBConnection: DB.Settings.TDBConfig): boolean;
var
  conclass: TBaseConnectionClass;
  con: TBaseConnection;
begin
  Result := False;
  Assert(not IsConnected(aDBConnection));

  con := nil;
  conclass := TBaseConnection.GetDBConnectionClass(aDBConnection.DBType);
  Assert(conclass <> nil);
  try
    con := conclass.Create(aDBConnection);
    con.Open;
    TDBConnectionPool.PutConnectionToPool(aDBConnection, con);
    Result := True;
  except
    con.Free;
  end;
end;

initialization
  TDBConnector.Enabled     := True;

end.
