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
unit ThreadFinalization;

interface

uses
  Classes, Contnrs, Types,
  Generics.Collections;

type
  TThreadFinalization = class
  private
    class var FThreadObjects: TObjectDictionary<NativeUInt, TObjectList>;
  public
    class constructor Create;
    class destructor  Destroy;

    class procedure RegisterThreadObject(aObject: TObject);
    class procedure UnRegisterThreadObject(aObject: TObject);
    class function  ContainsThreadObject(aObject: TObject): Boolean;

    class procedure FreeObjectsOfThread(aThreadID: NativeUInt);
  end;

implementation

uses
  Windows;

{ TThreadFinalization }
class function TThreadFinalization.ContainsThreadObject(
  aObject: TObject): Boolean;
var
  objlist: TObjectList;
begin
  Result := False;
  System.TMonitor.Enter(FThreadObjects);  //lock
  try
    if FThreadObjects.TryGetValue(GetCurrentThreadId, objlist) then
      Result := (objlist.IndexOf(aObject) >= 0);
  finally
    System.TMonitor.Exit(FThreadObjects); //unlock
  end;
end;

class constructor TThreadFinalization.Create;
begin
  FThreadObjects := TObjectDictionary<NativeUint, TObjectList>.Create([doOwnsValues]);
end;

class destructor TThreadFinalization.Destroy;
begin
  System.TMonitor.Enter(FThreadObjects);
  FThreadObjects.Clear;
  FThreadObjects.Free;
  FThreadObjects := nil;
end;

class procedure TThreadFinalization.FreeObjectsOfThread(aThreadID: NativeUInt);
begin
  if FThreadObjects = nil then Exit;
  System.TMonitor.Enter(FThreadObjects);  //lock
  try
    FThreadObjects.Remove(aThreadID);
  finally
    System.TMonitor.Exit(FThreadObjects); //unlock
  end;
end;

class procedure TThreadFinalization.RegisterThreadObject(aObject: TObject);
var
  objlist: TObjectList;
begin
  System.TMonitor.Enter(FThreadObjects);  //lock
  try
    if not FThreadObjects.TryGetValue(GetCurrentThreadId, objlist) then
    begin
      objlist := TObjectList.Create(True{ownsobjects});
      FThreadObjects.Add(GetCurrentThreadId, objlist);
    end;
    objlist.Add(aObject);
  finally
    System.TMonitor.Exit(FThreadObjects); //unlock
  end;

  //todo:
  //- use WaitForMultipleObjects in a seperate thread to wait/get signaled
  //  when thread terminates/crashes to clean up thread objects
  //- or use EndThread (windows api) hook...  this done in "OwnThreadFinalization" now
end;

class procedure TThreadFinalization.UnRegisterThreadObject(aObject: TObject);
var
  objlist: TObjectList;
begin
  System.TMonitor.Enter(FThreadObjects);  //lock
  try
    if FThreadObjects.TryGetValue(GetCurrentThreadId, objlist) then
      objlist.Extract(aObject);
  finally
    System.TMonitor.Exit(FThreadObjects); //unlock
  end;
end;

procedure OwnThreadFinalization(ExitCode: Integer);
begin
  TThreadFinalization.FreeObjectsOfThread( GetCurrentThreadId() );
end;

var _OldThreadEndProc: TSystemThreadEndProc;
initialization
  //save
  _OldThreadEndProc   := SystemThreadEndProc;
  //replace
  SystemThreadEndProc := OwnThreadFinalization;
finalization
  //restore
  if @SystemThreadEndProc = @OwnThreadFinalization then
    SystemThreadEndProc := _OldThreadEndProc;

end.
