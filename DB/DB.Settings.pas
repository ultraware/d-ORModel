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
unit DB.Settings;

interface

uses
   Classes, SysUtils,
   Generics.Collections,
   RttiClasses;

type
   TBaseSetting = class(TRttiEnabled)
   protected
      procedure Init; virtual;
   public
      procedure AfterConstruction; override;
   end;

   TDBConfig = class;
   TDBConnectionArray = array of TDBConfig;
   TDBConnectionType = (dbtNone, dbtSQLServer, dbtSQLServerCE, dbtREST, dbtSQLLite, dbtMYSQL);
   TDBConfigSettings = class(TBaseSetting)
   public
      function DatabaseName: string; virtual;
   end;
   TDBConnectionSettingsClass = class of TDBConfigSettings;

   TDBSettings = class(TBaseSetting)
   private
      FDBConnections: TDBConnectionArray;
      class var FInstance: TDBSettings;
      class var FDBConnectionOverride: TDBConfig;
   public
      class constructor Create;
      class destructor Destroy;
      destructor Destroy; override;

      function GetDBConnection(const aName: string; aDBType: TDBConnectionType): TDBConfig;
      procedure AddDBConnection(aDBConnection: TDBConfig; OverrideCon: Boolean = False);

      class property Instance: TDBSettings read FInstance;
      class property DBConnectionOverride: TDBConfig read FDBConnectionOverride;
   published
      property DBConnections: TDBConnectionArray read FDBConnections write FDBConnections;
   end;

   TDBConfig = class(TBaseSetting)
   private
      FDBType: TDBConnectionType;
      FSettings: TDBConfigSettings;
      FName: string;
      procedure SetDBType(const Value: TDBConnectionType);
   protected
      class var FDBSettingsClasses: TDictionary<TDBConnectionType, TDBConnectionSettingsClass>;
   public
      class constructor Create;
      class destructor Destroy;
      destructor Destroy; override;
      class procedure RegisterDBSettingsClass(aDBType: TDBConnectionType; aSettingsClass: TDBConnectionSettingsClass);
   published
      property Name: string read FName write FName;
      property DBType: TDBConnectionType read FDBType write SetDBType;
      property Settings: TDBConfigSettings read FSettings write FSettings;
   end;

implementation

{ TBaseSetting }

procedure TBaseSetting.AfterConstruction;
begin
   inherited;
   //
end;

procedure TBaseSetting.Init;
begin
   //
end;

{ TDBConnection }

class constructor TDBConfig.Create;
begin
   FDBSettingsClasses := TDictionary<TDBConnectionType, TDBConnectionSettingsClass>.Create;
end;

class destructor TDBConfig.Destroy;
begin
   FDBSettingsClasses.Free;
end;

destructor TDBConfig.Destroy;
begin
  inherited;
end;

class procedure TDBConfig.RegisterDBSettingsClass(aDBType: TDBConnectionType; aSettingsClass: TDBConnectionSettingsClass);
begin
   FDBSettingsClasses.Add(aDBType, aSettingsClass);
end;

procedure TDBConfig.SetDBType(const Value: TDBConnectionType);
var
   csettings: TDBConnectionSettingsClass;
begin
   FDBType := Value;

   FreeAndNil(FSettings);
   if FDBSettingsClasses.ContainsKey(FDBType) then
   begin
      csettings := FDBSettingsClasses.Items[FDBType];
      FSettings := csettings.Create;
   end;
end;

{ TDBSettings }

procedure TDBSettings.AddDBConnection(aDBConnection: TDBConfig; OverrideCon: Boolean = False);
begin
   SetLength(FDBConnections, Length(FDBConnections) + 1);
   FDBConnections[High(FDBConnections)] := aDBConnection;

   if OverrideCon then
      FDBConnectionOverride := aDBConnection;
end;

class constructor TDBSettings.Create;
begin
   FInstance := TDBSettings.Create;
end;

destructor TDBSettings.Destroy;
begin
  inherited;
end;

class destructor TDBSettings.Destroy;
begin
   FInstance.Free;
end;

function TDBSettings.GetDBConnection(const aName: string; aDBType: TDBConnectionType): TDBConfig;
var
   DB: TDBConfig;
begin
   Result := nil;

   if Assigned(FDBConnectionOverride) then
      Exit(FDBConnectionOverride);

   for DB in FDBConnections do
      if SameText(DB.Name, aName) then
         if DB.DBType = aDBType then
            Exit(DB);

   // get first available by name if nothing found
   if Result = nil then
   begin
      for DB in FDBConnections do
         if SameText(DB.Name, aName) then
            Exit(DB);
   end;

   // get first available by type
   if Result = nil then
   begin
      for DB in FDBConnections do
         if DB.DBType = aDBType then
            Exit(DB);
   end;

   // no type? dan take first available
   if (Result = nil) and (aDBType = dbtNone) then
   begin
      Assert(Length(FDBConnections) = 1, 'No DB type specified, should have exactely one DB config!');
      Exit(FDBConnections[0]);
   end;
end;

{ TDBConfigSettings }

function TDBConfigSettings.DatabaseName: string;
begin
   Result := '';
end;

end.
