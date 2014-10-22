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
unit DB.SettingsHelper;

interface

uses DB.Settings;

const
   cDBSettings_XML = 'DBSettings.xml';

type
   TDBSettingsHelper = class helper for TDBSettings
   public
      procedure LoadFromFile;
      procedure SaveToFile;
   end;

implementation

uses SysUtils, XMLFile;

procedure TDBSettingsHelper.LoadFromFile;
var
   oldThousandSeparator, oldDecimalSeparator: Char;
   sFile: string;
begin
   sFile := ExtractFilePath(ParamStr(0) { Application.ExeName } ) + cDBSettings_XML;

   // default XML floating point is US style
   oldThousandSeparator := FormatSettings.ThousandSeparator;
   oldDecimalSeparator := FormatSettings.DecimalSeparator;
   FormatSettings.ThousandSeparator := ',';
   FormatSettings.DecimalSeparator := '.';
   try
      if FileExists(sFile) then
         XMLFile.LoadFromFile(sFile, Self);
   finally
      FormatSettings.ThousandSeparator := oldThousandSeparator;
      FormatSettings.DecimalSeparator := oldDecimalSeparator;
   end;
end;

procedure TDBSettingsHelper.SaveToFile;
var
   oldThousandSeparator, oldDecimalSeparator: Char;
   sFile: string;
begin
   sFile := ExtractFilePath(ParamStr(0) { Application.ExeName } ) + cDBSettings_XML;

   // default XML floating point is US style
   oldThousandSeparator := FormatSettings.ThousandSeparator;
   oldDecimalSeparator := FormatSettings.DecimalSeparator;
   FormatSettings.ThousandSeparator := ',';
   FormatSettings.DecimalSeparator := '.';
   try
      // remove readonly attribute
      if FileIsReadOnly(sFile) then
         FileSetReadOnly(sFile, false);

      XMLFile.SaveToFile(sFile, Self);
   finally
      FormatSettings.ThousandSeparator := oldThousandSeparator;
      FormatSettings.DecimalSeparator := oldDecimalSeparator;
   end;
end;

end.
