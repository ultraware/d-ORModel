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
unit DB.Settings.SQLServer;

interface

uses
  DB.Settings;

type
  TBaseMSSqlServerDBConnectionSettings = class(TDBConfigSettings)
  private
    FProvider: string;
    FPassword: string;
  published
    property Password: string read FPassword write FPassword;
    property Provider: string read FProvider write FProvider;
  end;

  TMSSqlServerDBConnectionSettings = class(TBaseMSSqlServerDBConnectionSettings)
  private
    FServer: string;
    FDatabase: string;
    FUsername: string;
  public
    function DatabaseName: string; override;
  published
    property Server  : string read FServer   write FServer;
    property Database: string read FDatabase write FDatabase;
    property Username: string read FUsername write FUsername;
  end;

  TMSSqlServerCEDBConnectionSettings = class(TBaseMSSqlServerDBConnectionSettings)
  private
    FFileName: string;
  public
    procedure AfterConstruction; override;
    procedure Init; override;
  published
    property FileName: string read FFileName write FFileName;
  end;

  procedure AddSQLDatabaseSettings(const aServer, aDatabase, aUserName, aPassword: string; const aDBname: string = ''; aUseAsDefault: Boolean = True; const aProvider: string = ''; aDBType: TDBConnectionType = dbtSQLServer); overload;
  procedure CreateSQLCeDatabase(const aDataBase: string);

implementation

uses
  SysUtils, ComObj,
  Data.CRUD;

procedure AddSQLDatabaseSettings(const aServer, aDatabase, aUserName, aPassword: string; const aDBname: string = '';
  aUseAsDefault: Boolean = True; const aProvider: string = ''; aDBType: TDBConnectionType = dbtSQLServer);
var Connectie: TDBConfig;
begin
   Connectie := TDBSettings.Instance.GetDBConnection(aDBname, aDBType);
   if (not Assigned(Connectie)) then
   begin
      Connectie := TDBConfig.Create;
      TDBSettings.Instance.AddDBConnection(Connectie);
   end;

   with Connectie do
   begin
      Name   := aDBname;
      DBType := aDBType;

      case aDBType of
        dbtSQLServer:
          with (Settings as TMSSqlServerDBConnectionSettings) do
          begin
             Server   := aServer;
             Database := aDatabase;
             Username := aUserName;
             Password := aPassword;
             if aProvider <> '' then  //do not overwrte default provider
               Provider := aProvider;
          end;
        dbtSQLServerCE:
          with (Settings as TMSSqlServerCEDBConnectionSettings) do
          begin
             FileName := aDatabase;
             Password := aPassword;
             if aProvider <> '' then  //do not overwrte default provider
               Provider := aProvider;
          end;
      else
        Assert(False);
      end;
   end;

   if aUseAsDefault then
      TBaseDataCRUD.SetDefaultDBTypeForDBName(aDBname, aDBType);
end;

procedure CreateSQLCeDatabase(const aDataBase: string);
var Catalog : OleVariant;
begin
  Catalog := CreateOleObject('ADOX.Catalog');
  Catalog.Create(Format('Provider=Microsoft.SQLSERVER.CE.OLEDB.4.0;Data Source=%s;SSCE:Max Database Size=500;',[aDataBase]));
end;

{ TMSSqlServerDBConnectionSettings }

function TMSSqlServerDBConnectionSettings.DatabaseName: string;
begin
  Result := Database;
end;

procedure TMSSqlServerCEDBConnectionSettings.AfterConstruction;
begin
  inherited;
  FProvider := 'Microsoft.SQLSERVER.CE.OLEDB.4.0';
end;

procedure TMSSqlServerCEDBConnectionSettings.Init;
begin
  inherited;
  FProvider := 'Microsoft.SQLSERVER.CE.OLEDB.4.0'; //4.0';
end;

initialization
  TDBConfig.RegisterDBSettingsClass(dbtSQLServer,   TMSSqlServerDBConnectionSettings);
  TDBConfig.RegisterDBSettingsClass(dbtSQLServerCE, TMSSqlServerCEDBConnectionSettings);

end.
