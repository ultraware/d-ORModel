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
unit Data.CommonCustomTypes;

interface

uses Data.DataRecord
     ;

// Shared velden met afhankelijkheden van andere units voor bijvoorbeeld validatie of formatting

type
   TTypedEMailField = class(TTypedStringField)
   protected
      function InternalValidationText: string; override;
   end;

   TNonQueryEMailField = class(TNonQueryStringField)
   protected
      function InternalValidationText: string; override;
   end;

   TTypedBTWNummerField = class(TTypedStringField)
   protected
      function InternalValidationText: string; override;
   end;

   TTypedPhoneField = class(TTypedStringField)
   public
      procedure AfterConstruction; override;
   end;

   TTypedPostCodeField = class(TTypedStringField);

implementation

uses
  //UltraValidateUtils,
  UltraStringUtils;

function GetEmailFieldInternalValidationText(EmailField: TCustomField): string;
begin
   if not EmailField.IsEmptyOrNull and not ValideerEmailAdres(EmailField.ValueAsString, (not EmailField.IsRequired) or EmailField.HasDefaultValue) then
      Result := _Fmt('Emailadres "%s" is not valid.', [EmailField.ValueAsString]);
end;

{ TTypedEMailField }

function TTypedEMailField.InternalValidationText: string;
begin
   Result := inherited InternalValidationText;
   if (Result = '') then
      Result := GetEmailFieldInternalValidationText(Self);
end;

{ TNonQueryEMailField }

function TNonQueryEMailField.InternalValidationText: string;
begin
   Result := inherited InternalValidationText;
   if (Result = '') then
      Result := GetEmailFieldInternalValidationText(Self);
end;

{ TTypedBTWField }

function TTypedBTWNummerField.InternalValidationText: string;
begin
   Result := inherited InternalValidationText();
   if (Result = '') then
   begin
      if not IsEmptyOrNull and not ValideerBTWNummer(TypedString) then
         Result := _('BTWnummer is niet in een geldig formaat.');
   end;
end;

{ TTypedPhoneField }

procedure TTypedPhoneField.AfterConstruction;
begin
   inherited;
   OnFormatField := function(s: string): string
      begin
         Result := TelefoonBoom.TelefoonFormat(s);
      end;
end;

end.
