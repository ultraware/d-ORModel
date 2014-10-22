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
unit Data.CustomTypes;

interface

uses System.Generics.Collections, Data.DataRecord;

type
   // Base helper:
   // Voor custom helper moet er een kopie van deze unit worden gemaakt
   // In Data.CommonCustomTypes staan extra velden, met meer afhankelijkheid die evt gebruikt kunnen worden
   TDataRecordHelper = class helper for TBaseDataRecord
   private
      // note: Meta.CustomIDTypes contains helper for TDataRecord, but only one helper can exists, so that's why we use TBaseDataRecord here
   public
      function GetUltraBooleanField(aIndex: Integer): TUltraBooleanField;
      function GetTypedURIField(aIndex: Integer): TTypedURIField;
      function GetTypedTextField(aIndex: Integer): TTypedTextField;
      function GetTypedDateField(aIndex: Integer): TTypedDateField;
      function GetTypedTimeField(aIndex: Integer): TTypedTimeField;
//      function GetTypedMoneyField(aIndex: Integer): TTypedMoneyField;
      function GetTypedPercentageField(aIndex: Integer): TTypedPercentageField;
   end;


implementation

{ TDataRecordHelper }

function TDataRecordHelper.GetTypedDateField(aIndex: Integer): TTypedDateField;
begin
   Result := Self.Items[aIndex] as TTypedDateField;
end;

function TDataRecordHelper.GetTypedPercentageField(aIndex: Integer): TTypedPercentageField;
begin
   Result := Self.Items[aIndex] as TTypedPercentageField;
end;

function TDataRecordHelper.GetTypedTextField(aIndex: Integer): TTypedTextField;
begin
   Result := Self.Items[aIndex] as TTypedTextField;
end;

function TDataRecordHelper.GetTypedTimeField(aIndex: Integer): TTypedTimeField;
begin
   Result := Self.Items[aIndex] as TTypedTimeField;
end;

function TDataRecordHelper.GetTypedURIField(aIndex: Integer): TTypedURIField;
begin
   Result := Self.Items[aIndex] as TTypedURIField;
end;

function TDataRecordHelper.GetUltraBooleanField(aIndex: Integer): TUltraBooleanField;
begin
   Result := Self.Items[aIndex] as TUltraBooleanField;
end;

initialization
  TRegisteredCustomFields.RegisterCustomField(TUltraBooleanField);
  TRegisteredCustomFields.RegisterCustomField(TTypedURIField);
  TRegisteredCustomFields.RegisterCustomField(TTypedTextField);
  TRegisteredCustomFields.RegisterCustomField(TTypedDateField);
  TRegisteredCustomFields.RegisterCustomField(TTypedTimeField);
  TRegisteredCustomFields.RegisterCustomField(TTypedPercentageField);

end.
