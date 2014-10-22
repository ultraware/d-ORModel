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
unit Data.DatasetFields;

interface

uses
  Db, Classes,
  Meta.Data;

type
  TBaseUltraField = class(TField)
  private
    function GetStringValue(var Value: string): Boolean;
    function GetIntegerValue(var Value: Integer): Boolean;
    function GetDatetimeValue(var Value: TDateTime): Boolean;
    function GetBooleanValue(var Value: Boolean): Boolean;
    function GetExtendedValue(var Value: Extended): Boolean;
  protected
    function GetAsSingle: Single; override;
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsLargeInt: Largeint; override;
    function GetAsLongWord: LongWord; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    procedure SetAsSingle(Value: Single); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsLargeInt(Value: Largeint); override;
    procedure SetAsLongWord(Value: LongWord); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  end;

  TUltraSpecialJoinField = class(TBaseUltraField)
  private
    FSourceField: TBaseTableAttribute;
    FJoinField: TBaseTableAttribute;
    FSelectField: TBaseTableAttribute;
  public
    constructor Create(AOwner: TComponent); override;

    procedure ChangeDataType(Value: Data.DB.TFieldType);
  published
    property SourceFKField: TBaseTableAttribute read FSourceField write FSourceField;
    property JoinPKField  : TBaseTableAttribute read FJoinField   write FJoinField;
    property SelectField  : TBaseTableAttribute read FSelectField write FSelectField;
  end;

  function Own2DelphiFieldType(const aOwnFieldType: Meta.Data.TFieldType): DB.TFieldType;

implementation

uses
  SysUtils, TypInfo, Variants;

function Own2DelphiFieldType(const aOwnFieldType: Meta.Data.TFieldType): DB.TFieldType;
begin
  case aOwnFieldType of
    ftFieldID:       Result := ftAutoInc;
    ftFieldString:   Result := ftWideString;
    ftFieldInteger:  Result := ftInteger;
    ftFieldBoolean:  Result := ftBoolean;
    ftFieldDouble:   Result := DB.ftExtended;
    ftFieldDateTime: Result := ftDateTime;
  else
    //Result := ftFieldUnknown;
    raise Exception.Create('Unsupported type: ' + TypInfo.GetEnumName( TypeInfo(Meta.Data.TFieldType), Ord(aOwnFieldType)) );
  end;
end;

{ TUltraSpecialJoinField }

procedure TUltraSpecialJoinField.ChangeDataType(Value: Data.DB.TFieldType);
begin
  SetDataType(Value);
end;

constructor TUltraSpecialJoinField.Create(AOwner: TComponent);
begin
  inherited;
  FieldKind := fkData;
  SetDataType(ftWideString);
end;

{ TBaseUltraField }

function TBaseUltraField.GetAsFloat: Double;
begin
  Result := GetAsVariant;
end;

function TBaseUltraField.GetAsInteger: Longint;
begin
  Result := GetAsVariant;
end;

function TBaseUltraField.GetAsLargeInt: Largeint;
begin
  Result := GetAsVariant;
end;

function TBaseUltraField.GetAsLongWord: LongWord;
begin
  Result := GetAsVariant;
end;

function TBaseUltraField.GetAsSingle: Single;
begin
  Result := GetAsVariant;
end;

function TBaseUltraField.GetAsString: string;
begin
  Result := GetAsVariant;
end;

function TBaseUltraField.GetAsVariant: Variant;
var i: Integer; s: string; b: Boolean; dt: TDateTime; e: Extended;
begin
  case Self.DataType of
    ftAutoInc     : if not GetIntegerValue(i) then Result := null else Result := i;
    ftWideString  : if not GetStringValue(s)  then Result := null else Result := s;
    ftInteger     : if not GetIntegerValue(i) then Result := null else Result := i;
    ftBoolean     : if not GetBooleanValue(b) then Result := null else Result := b;
    DB.ftExtended : if not GetExtendedValue(e) then Result := null else Result := e;
    ftDateTime    : if not GetDatetimeValue(dt) then Result := null else Result := dt;
  else
    Assert(False);
  end;
end;

function TBaseUltraField.GetIntegerValue(var Value: Longint): Boolean;
var
  Data: TValueBuffer;
begin
  //note: copied from Data.DB.TIntegerField.GetValue

  SetLength(Data, SizeOf(Integer));
  Result := GetData(Data);
  case DataType of
    ftShortint:
      begin
        if Result then
          Value := TBitConverter.ToShortInt(Data);
      end;
    ftByte:
      begin
        if Result then
          Value := TBitConverter.ToByte(Data);
      end;
    ftSmallint:
      begin
        if Result then
          Value := TBitConverter.ToSmallInt(Data);
      end;
    ftWord:
      begin
        if Result then
          Value := TBitConverter.ToWord(Data);
      end;
    ftLongWord:
      begin
        if Result then
          Value := TBitConverter.ToLongWord(Data);
      end;
    else
      begin
        if Result then
          Value := TBitConverter.ToLongInt(Data);
      end;
    end;
end;

function TBaseUltraField.GetStringValue(var Value: string): Boolean;
var
  Buffer: TValueBuffer;
  NullIndex: Integer;
  Str: string;
begin
  //note: copied from Data.DB.TWideStringField.GetValue

  if DataSize > dsMaxStringSize + SizeOf(Char) then
    SetLength(Buffer, ((DataSize div 2) + 1) * SizeOf(Char))
  else
    SetLength(Buffer, dsMaxStringSize + SizeOf(Char));
  Result := GetData(Buffer, False);
  if Result then
  begin
    Str := TEncoding.Unicode.GetString(Buffer);
    NullIndex := Str.IndexOf(#0);
    if NullIndex >= 0 then
      Value := Str.Remove(NullIndex)
    else
      Value := Str;
  end;
end;

function TBaseUltraField.GetDatetimeValue(var Value: TDateTime): Boolean;
var
  Data: TValueBuffer;
begin
  SetLength(Data, SizeOf(TDateTime));
  Result := GetData(Data, False);
  Value := TBitConverter.ToDouble(Data);
end;

function TBaseUltraField.GetBooleanValue(var Value: Boolean): Boolean;
var
  B: TValueBuffer;
begin
  SetLength(B, SizeOf(WordBool));
  Result := GetData(B);
  if Result then
    Value := TBitConverter.ToWordBool(B);
end;

function TBaseUltraField.GetExtendedValue(var Value: Extended): Boolean;
var
  Data: TValueBuffer;
begin
  Result := GetData(Data);
  if Result then
    Value := TBitConverter.ToExtended(Data);
end;

function TBaseUltraField.GetDataSize: Integer;
begin
  case Self.DataType of
    ftAutoInc     : Result := SizeOf(Integer);
    ftWideString  : Result := (Size + 1) * 2;
    ftInteger     : Result := SizeOf(Integer);
    ftBoolean     : Result := SizeOf(Boolean);
    DB.ftExtended : Result := SizeOf(Extended);
    ftDateTime    : Result := SizeOf(TDatetime);
  else
    Result := 0;
    Assert(False);
  end;
end;

procedure TBaseUltraField.SetAsFloat(Value: Double);
begin
  SetVarValue(Value);
end;

procedure TBaseUltraField.SetAsInteger(Value: Integer);
begin
  SetVarValue(Value);
end;

procedure TBaseUltraField.SetAsLargeInt(Value: Largeint);
begin
  SetVarValue(Value);
end;

procedure TBaseUltraField.SetAsLongWord(Value: LongWord);
begin
  SetVarValue(Value);
end;

procedure TBaseUltraField.SetAsSingle(Value: Single);
begin
  SetVarValue(Value);
end;

procedure TBaseUltraField.SetAsString(const Value: string);
begin
  SetVarValue(Value);
end;

procedure TBaseUltraField.SetVarValue(const Value: Variant);
begin
  Assert(False, 'todo');
end;

end.
