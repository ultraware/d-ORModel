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
unit DB.Base;

interface

uses
  Data.Base;

type
  EDBException = class(EUltraException)
  private
    FSQL: string;
  public
    constructor Create(const aMsg, aSQL: string); overload; virtual;

    property SQL: string read FSQL write FSQL;
  end;

implementation

{ EDBException }

constructor EDBException.Create(const aMsg, aSQL: string);
begin
  inherited Create(aMsg);
  FSQL := aSQL;
end;

end.
