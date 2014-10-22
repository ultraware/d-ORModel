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
unit DB.Settings.REST;

interface

uses
  DB.Settings;

type
  TRESTDBConnectionSettings = class(TDBConfigSettings)
  private
    FPort: Integer;
    FUrl: string;
    FServer: string;
    FPassword: string;
    FUsername: string;
//    FCompressionLevel: Integer;
  public
    function DatabaseName: string; override;
  published
    property Host    : string  read FServer   write FServer;
    property Url     : string  read FUrl      write FUrl;
    property Port    : Integer read FPort     write FPort;

    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;

    //property CompressionLevel: Integer read FCompressionLevel write FCompressionLevel;  tcp compression?
  end;

implementation

{ TRESTDBConnectionSettings }

function TRESTDBConnectionSettings.DatabaseName: string;
begin
  Result := '';
end;

initialization
  TDBConfig.RegisterDBSettingsClass(dbtREST, TRESTDBConnectionSettings);

end.
