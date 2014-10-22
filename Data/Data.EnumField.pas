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
unit Data.EnumField;

interface

uses
  TypInfo,
  Data.DataRecord, Meta.Data;

type
   RPickOption = record // Key value pair voor combo's e.d.
      Key: Variant;
      Value: string;
      class function PO(aKey: Variant; aValue: string): RPickOption; static;
   end;

   RPickOptions = array of RPickOption;

   TBaseEnumField = class abstract (TBaseField)
   // Generieke enumveld om waarde toe te kunnen kennen, zonder precies te weten wat voor enumfield het is
   // Hierdoor, is het niet voor app niet nodig om alle enumvelden langs te lopen en kijken of die van hetzelfde type zijn
   private
      procedure SetUnsafeValueAsVariant(const aValue: Variant); virtual; abstract;
   public
      property UnsafeValueAsVariant: Variant write SetUnsafeValueAsVariant;
      class function GetPickList: RPickOptions; virtual; // om comboboxen te vullen
   end;

  TBaseEnumField<T> = class abstract (TBaseEnumField)
  private
    procedure SetTypedEnum(const aTypedValue: T);
    function  GetTypedEnum: T;
      procedure SetUnsafeValueAsVariant(const aValue: Variant); override; final;
  protected
      class function ConvertEnumToVariant(const aEnum: T): Variant; virtual; abstract;
      class function ConvertEnumToDisplayString(const aEnum: T): string; virtual;
      class function GetPickOption(const aEnum: T): RPickOption;
      class function ConvertVariantToEnum(const aValue: Variant): T; virtual; abstract;
   public
      function ValueAsDisplayString: string;
      property TypedEnum: T read GetTypedEnum write SetTypedEnum;
    //todo: property FieldValue: Variant to copy null/empty value, but with enum value check?
  end;

   TTypedStringEnumField<T> = class (TBaseEnumField<T>)
   private
      procedure SetUnsafeValueAsString(const aValue: string);
   protected
      function GetFieldType: TFieldType; override;
   public
      property UnsafeValueAsString: string write SetUnsafeValueAsString;
   end;

   TTypedIntegerEnumField<T> = class (TBaseEnumField<T>)
   private
      procedure SetUnsafeValueAsInteger(const aValue: Integer);
   protected
      function GetFieldType: TFieldType; override;
   public
      property UnsafeValueAsInteger: Integer write SetUnsafeValueAsInteger;
   end;

implementation

uses
  Variants, SysUtils, Rtti, System.Character;

{ TBaseEnumField }

class function TBaseEnumField.GetPickList: RPickOptions;
begin
   SetLength(Result, 0);
end;

{ TBaseEnumField<T> }

class function TBaseEnumField<T>.ConvertEnumToDisplayString(const aEnum: T): string;
// basis omzetting van Enum naar tekst, alles vanaf de 1e hoofdletter wordt meegeneomen
var FirstUpper, i: Integer;
begin
   Result := TValue.From<T>(aEnum).ToString;
   FirstUpper := -1;
   i := 0;
   while (FirstUpper = -1) and (i < length(Result)) do
   begin
      if IsUpper(Result[i]) then
         FirstUpper := i;
      Inc(i);
   end;
   Result := Copy(Result, FirstUpper, length(Result));
end;

function TBaseEnumField<T>.ValueAsDisplayString: string;
begin
   Result := ConvertEnumToDisplayString(TypedEnum);
end;

class function TBaseEnumField<T>.GetPickOption(const aEnum: T): RPickOption;
begin
   Result := RPickOption.PO(ConvertEnumToVariant(aEnum), ConvertEnumToDisplayString(aEnum));
end;

function TBaseEnumField<T>.GetTypedEnum: T;
begin
   Result := ConvertVariantToEnum(ValueAsVariant);
end;

procedure TBaseEnumField<T>.SetTypedEnum(const aTypedValue: T);
begin
   SetValueAsVariant(ConvertEnumToVariant(aTypedValue));
end;

procedure TBaseEnumField<T>.SetUnsafeValueAsVariant(const aValue: Variant);
begin
   TypedEnum := ConvertVariantToEnum(aValue);
end;

{ TTypedStringEnumField<T> }

function TTypedStringEnumField<T>.GetFieldType: TFieldType;
begin
  Result := inherited GetFieldType;
  if Result = ftFieldUnknown then      //no metadata attribute?
    Result := ftFieldString;
end;

procedure TTypedStringEnumField<T>.SetUnsafeValueAsString(const aValue: string);
begin
   SetUnsafeValueAsVariant(aValue);
end;

{ TTypedIntegerEnumField<T> }

function TTypedIntegerEnumField<T>.GetFieldType: TFieldType;
begin
  Result := inherited GetFieldType;
  if Result = ftFieldUnknown then      //no metadata attribute?
    Result := ftFieldInteger;
end;

procedure TTypedIntegerEnumField<T>.SetUnsafeValueAsInteger(const aValue: Integer);
begin
   SetUnsafeValueAsVariant(aValue);
end;

{ RPickOption }
class function RPickOption.PO(aKey: Variant; aValue: string): RPickOption;
begin
   Result.Key := aKey;
   Result.Value := aValue;
end;

end.
