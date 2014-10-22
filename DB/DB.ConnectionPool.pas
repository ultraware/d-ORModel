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
unit DB.ConnectionPool;

interface

uses
  SyncObjs,
  Contnrs,
  DB.Connection, DB.Settings,
  Classes,
  Generics.Collections;

type
  TPoolItem = class;
  TPool = class(TObjectList<TPoolItem>)
  public
    procedure Lock;
    procedure UnLock;
  end;

  TDBConnectionPool = class
  private
    class var FConfigPool: TDictionary<TDBConfig,TPool>;
    class var FMaxPoolSize: Integer;
    class procedure SetMaxPoolSize(const Value: Integer); static;
    class function GetPool(aDBConfig: TDBConfig): TPool;
  public
    class constructor Create;
    class destructor  Destroy;

    class procedure Lock;
    class procedure UnLock;

    class property  MaxPoolSize: Integer read FMaxPoolSize write SetMaxPoolSize;

    class function  GetConnectionFromPool(aDBConfig: TDBConfig): TBaseConnection;
    class function  HasConnections(aDBConfig: TDBConfig): Boolean;
    class procedure PutConnectionToPool(aDBConfig: TDBConfig; aConnection: TBaseConnection);
  end;

  TPoolItem = class
  protected
    Connection: TBaseConnection;
    Lock      : TCriticalSection;
  public
    procedure  AfterConstruction;override;
    destructor Destroy;override;
  end;

implementation

uses
  SysUtils,
  Windows,
  DB.Connector, ThreadFinalization;

type
  TCriticalSection_Ext = class(TCriticalSection);

threadvar
  _ThreadTransactionConnections: TDictionary<TDBConfig, TBaseConnection>;

{ TPoolItem }

procedure TPoolItem.AfterConstruction;
begin
  inherited;
  Lock := TCriticalSection.Create;
end;

destructor TPoolItem.Destroy;
begin
  Lock.Enter;
  Lock.Free;
  Connection.Free;
  inherited;
end;

{ TDBConnectionPool }

class constructor TDBConnectionPool.Create;
begin
  FConfigPool := TObjectDictionary<TDBConfig,TPool>.Create([doOwnsValues]);
  MaxPoolSize := 10;
end;

class destructor TDBConnectionPool.Destroy;
begin
  System.TMonitor.Enter(FConfigPool);
  FConfigPool.Free;
end;

class function TDBConnectionPool.GetConnectionFromPool(aDBConfig: TDBConfig): TBaseConnection;
var
  pi: TPoolItem;
  hndlArr : array of THandle;
  i: Integer;
  lpool: TPool;
begin
  //pending transaction in current tread? then use the same connection!
  if _ThreadTransactionConnections <> nil then
  begin
    if _ThreadTransactionConnections.TryGetValue(aDBConfig, Result) then
      if Result <> nil then
      begin
        Assert( Result.IsInTransaction);
        Exit;
      end;
  end;

  lpool := GetPool(aDBConfig);

  //on demand connection: if no connection yet, then connect now
  if (lPool.Count = 0) then
    TDBConnector.Connect(aDBConfig);

  Result := nil;
  repeat
    lpool.Lock;
    try
      //search for available connection in pool
      for pi in lpool do
      begin
        if pi.Lock.TryEnter then
        begin
          Result := pi.Connection;
          Assert( (Result.OwnerThreadId = GetCurrentThreadId) or
                  (Result.OwnerThreadId = 0) );
          Result.OwnerThreadId := GetCurrentThreadId;
          //item.Lock.Enter;  already locked
          Exit;
        end;
      end;

      //no one available, create new one (if not max)
      if (Result = nil) and
         (lpool.Count < MaxPoolSize) then
      begin
        pi := TPoolItem.Create;
        pi.Lock.Enter;       //lock!

        Assert(lpool.First <> nil);
        pi.Connection := lpool.First.Connection.Clone;
        pi.Connection.Open;
        pi.Connection.Name := pi.Connection.Name + format('<poolitem_%d>',[lpool.Count+1]);
        lpool.Add(pi);

        Result := pi.Connection;
        assert( (Result.OwnerThreadId = GetCurrentThreadId) or
                (Result.OwnerThreadId = 0) );
        Result.OwnerThreadId := GetCurrentThreadId;
        Exit;
      end;

      //fill wait list
      if (Result = nil) and (Length(hndlArr) = 0) then
      begin
        SetLength(hndlArr, lpool.Count);
        //fill all lock handles in array
        for i := 0 to lpool.Count - 1 do
        begin
          pi         := lpool.Items[i];
          hndlArr[i] := TCriticalSection_Ext(pi.Lock).FSection.LockSemaphore;
        end;
      end;

    finally
      lpool.UnLock;
    end;

    //wait 5sec, then force retry. In case one gets available early, we do a direct retry
    WaitForMultipleObjects(lpool.Count, pwohandlearray(@hndlArr), False, 5 * 1000);

  until Result <> nil;
end;

class function TDBConnectionPool.GetPool(aDBConfig: TDBConfig): TPool;
begin
  Self.Lock;
  try
    if not FConfigPool.TryGetValue(aDBConfig, Result) then
    begin
      Result := TPool.Create(True{owns});
      FConfigPool.Add(aDBConfig, Result);
    end;
  finally
    UnLock;
  end;
end;

class function TDBConnectionPool.HasConnections(aDBConfig: TDBConfig): Boolean;
var
  lpool: TPool;
begin
  lpool  := GetPool(aDBConfig);
  Result := lpool.Count > 0;
end;

class procedure TDBConnectionPool.Lock;
begin
  System.TMonitor.Enter(FConfigPool);
end;

class procedure TDBConnectionPool.PutConnectionToPool(aDBConfig: TDBConfig; aConnection: TBaseConnection);
var
  item: TPoolItem;
  lpool: TPool;
begin
  //pending transaction in current tread? then store so all other actions can use the same connection
  if aConnection.IsInTransaction then
  begin
    if _ThreadTransactionConnections = nil then
    begin
      _ThreadTransactionConnections := TDictionary<TDBConfig, TBaseConnection>.Create;
      TThreadFinalization.RegisterThreadObject(_ThreadTransactionConnections);
    end;
     _ThreadTransactionConnections.AddOrSetValue(aDBConfig, aConnection);
    Exit;
  end
  else if _ThreadTransactionConnections <> nil then
   _ThreadTransactionConnections.AddOrSetValue(aDBConfig, nil);

  lpool := GetPool(aDBConfig);
  lpool.Lock;
  try
    //search the connection in pool
    for item in lpool do
    begin
      if item.Connection = aConnection then
      begin
        Assert( not aConnection.IsInTransaction);
        Assert( (aConnection.OwnerThreadId = GetCurrentThreadId) or
                (aConnection.OwnerThreadId = 0) );
        aConnection.OwnerThreadId := 0;

        item.Lock.Release;
        Exit;
      end;
    end;

    //not in list? (because no exit is done we reached this point)
    //then add to pool (in case we create a connection at startup etc)
    begin
      item := TPoolItem.Create;
      item.Connection := aConnection;
      lpool.Add(item);
    end;

  finally
    lpool.UnLock;
  end;
end;

class procedure TDBConnectionPool.SetMaxPoolSize(const Value: Integer);
begin
  FMaxPoolSize := Value;
end;

class procedure TDBConnectionPool.UnLock;
begin
  System.TMonitor.Exit(FConfigPool);
end;

{ TPool }

procedure TPool.Lock;
begin
  System.TMonitor.Enter(Self);
end;

procedure TPool.UnLock;
begin
  System.TMonitor.Exit(Self);
end;

end.

