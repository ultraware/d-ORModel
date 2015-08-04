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
unit DB.Connection;

interface

uses
  Classes, Generics.Collections,
  DB.Settings,
  Data.Base, Data.Query;

type
  TSQLExecutingEvent = procedure(const aSQL: string; aParams: TVariantArray) of object;
  TSQLExecutedEvent  = procedure(const aSQL: string; aParams: TVariantArray; aDuration: TDateTime;  aRowsAffected: Integer) of object;

  TBaseConnection = class;
  TBaseConnectionClass = class of TBaseConnection;

  TBaseConnection = class
  private
    FOwnerThreadId: NativeUInt;
    FName: string;
    FLastExecutedSQL: string;
  protected
    FIsOpened: Boolean;
    FTransactionLevel: Integer;
    procedure StartTransaction;virtual;
    procedure CommitTransaction;virtual;
    procedure RollbackTransaction;virtual;

    class var FOnSQLExecuted: TSQLExecutedEvent;
    class var FOnSQLExecuting: TSQLExecutingEvent;
    class var FDBConnectionClassPerType: TDictionary<TDBConnectionType, TBaseConnectionClass>;
  public
    constructor Create(aDBSettings: DB.Settings.TDBConfig); virtual;
    procedure SetConfig(aDBSettings: DB.Settings.TDBConfig); virtual;

    function Clone: TBaseConnection;virtual;

    function  IsOpened: Boolean;
    function  IsOpen: Boolean;virtual;abstract;
    procedure Open;virtual;
    procedure Close;virtual;

    function  IsInTransaction: Boolean;virtual;

    property OwnerThreadId: NativeUInt read FOwnerThreadId write FOwnerThreadId;
    property Name: string read FName write FName;
    property LastExecutedSQL: string read FLastExecutedSQL write FLastExecutedSQL;
  public
    class constructor Create;
    class destructor  Destroy;

    class property OnSQLExecuting: TSQLExecutingEvent read FOnSQLExecuting write FOnSQLExecuting;
    class property OnSQLExecuted : TSQLExecutedEvent  read FOnSQLExecuted  write FOnSQLExecuted;

    class procedure RegisterDBConnection(aDBType: TDBConnectionType; aDBConnectionClass: TBaseConnectionClass);
    class function  GetDBConnectionClass(aDBType: TDBConnectionType): TBaseConnectionClass;
  end;

implementation

uses
  SysUtils, Variants, Data.DataRecord,
  Windows;

{ TBaseConnection }

function TBaseConnection.Clone: TBaseConnection;
begin
  //create new object of same class
  Result := Self.ClassType.Create as TBaseConnection;
end;

procedure TBaseConnection.Close;
begin
  //
end;

procedure TBaseConnection.CommitTransaction;
begin
  Dec(FTransactionLevel);
end;

class constructor TBaseConnection.Create;
begin
  FDBConnectionClassPerType := TDictionary<TDBConnectionType, TBaseConnectionClass>.Create;
end;

constructor TBaseConnection.Create(aDBSettings: DB.Settings.TDBConfig);
begin
  //
end;

procedure TBaseConnection.SetConfig(aDBSettings: DB.Settings.TDBConfig);
begin
  //
end;

function TBaseConnection.IsInTransaction: Boolean;
begin
  Result := (FTransactionLevel > 0);
end;

function TBaseConnection.IsOpened: Boolean;
begin
  Result := FIsOpened;
end;

procedure TBaseConnection.Open;
begin
  //
end;

class procedure TBaseConnection.RegisterDBConnection(aDBType: TDBConnectionType;
  aDBConnectionClass: TBaseConnectionClass);
begin
  FDBConnectionClassPerType.Add(aDBType, aDBConnectionClass);
end;

procedure TBaseConnection.RollbackTransaction;
begin
  Dec(FTransactionLevel);
end;

procedure TBaseConnection.StartTransaction;
begin
  Inc(FTransactionLevel);
end;

class destructor TBaseConnection.Destroy;
begin
  FDBConnectionClassPerType.Free;
end;

class function TBaseConnection.GetDBConnectionClass(
  aDBType: TDBConnectionType): TBaseConnectionClass;
begin
  if not FDBConnectionClassPerType.TryGetValue(aDBType, Result) then
    Result := nil;
end;

end.


