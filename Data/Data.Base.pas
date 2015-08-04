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
unit Data.Base;

interface

uses
  SysUtils,
  Meta.Data;

type
  EUltraException = class(Exception);
  EDataException  = class(EUltraException);

  TVariantArray = array of variant;

  TInterfacedNoRefObject = class(TObject, IInterface)
  protected
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  TValueFillState = (fsEmpty, fsNull, fsValue);
  TValueRecord = packed record
  public
    procedure Clear2Null;
    procedure Clear2Empty;

    function IsEmpty: Boolean;
    function IsNull : Boolean;

    function  GetFieldValueFromType(aType: TFieldType): Variant;
    procedure SetFieldValueForType (aType: TFieldType; const aValue: Variant);

    function  GetStringFromType (aType: TFieldType): String;
    function  GetIntegerFromType(aType: TFieldType): Integer;
    function  GetInt64FromType  (aType: TFieldType): Int64;
    function  GetDoubleFromType (aType: TFieldType): Double;
    function  GetBooleanFromType(aType: TFieldType): Boolean;
    //
    procedure SetStringForType (aType: TFieldType; const aValue: String);
    procedure SetIntegerForType(aType: TFieldType; const aValue: Integer);
    procedure SetInt64ForType  (aType: TFieldType; const aValue: Int64);
    procedure SetDoubleForType (aType: TFieldType; const aValue: Double);
    procedure SetBooleanForType(aType: TFieldType; const aValue: Boolean);
  private
    FFillState: TValueFillState;
    var
      FString  : String;
    case Byte of
      0: (FInteger : Integer);
      1: (FInt64   : Int64);
      //2: (FCardinal: Cardinal);
      //3: (FByte    : Byte);
      4: (FDouble  : Double);
      //5: (FCurrency: Currency);
      6: (FDatetime: TDatetime);
      7: (FBoolean : Boolean);
      //8: (FChar    : Char);
      //9: (FBlob    : TBlobStream);
  end;

   TFieldData = packed record
  private
    FFieldValue: TValueRecord;
    FOrigValue : TValueRecord;
    function  GetFieldValue: Variant;
    function  GetOrigValue: Variant;
    function  GetValueAsInteger: Integer;
    function  GetValueAsString: String;
    function  GetValueAsDateTime: TDateTime;
    function  GetValueAsDouble: Double;
    function  GetValueAsBoolean: Boolean;
    function  GetValueAsInt64: Int64;
    procedure SetFieldValue(const aValue: Variant);
    procedure SetValueAsDateTime(const aValue: TDateTime);
    procedure SetValueAsDouble(const aValue: Double);
    procedure SetValueAsInteger(const aValue: Integer);
    procedure SetValueAsString(const aValue: String);
    procedure SetValueAsBoolean(const aValue: Boolean);
    procedure SetValueAsInt64(const aValue: Int64);
  public
    DataType  : TFieldType;
    Modified  : Boolean;
    //todo: validation state?

    procedure Clear2Empty;
    procedure Clear2Null;
    function  IsEmpty: Boolean;
    function  IsNull : Boolean;
    function  IsEmptyOrNull: Boolean;

    procedure UndoChange;
    procedure ResetModifiedState;

    procedure LoadValue(aValue: Variant);  //direct load value, without conversions or checks, and without touching .Modified
    property  FieldValue: Variant read GetFieldValue write SetFieldValue;
    property  OrigValue : Variant read GetOrigValue;

    property ValueAsInteger : Integer   read GetValueAsInteger  write SetValueAsInteger;
    property ValueAsInt64   : Int64     read GetValueAsInt64    write SetValueAsInt64;
    property ValueAsString  : String    read GetValueAsString   write SetValueAsString;
    property ValueAsDouble  : Double    read GetValueAsDouble   write SetValueAsDouble;
    property ValueAsDateTime: TDateTime read GetValueAsDateTime write SetValueAsDateTime;
    property ValueAsBoolean : Boolean   read GetValueAsBoolean  write SetValueAsBoolean;
  end;

  TFieldDataArray   = packed array of TFieldData;  //data of one row for each field
//  {$ifNdef NOPOINTERS}  //todo: also make "safer" pointerless version (but then we need more data container objects)
  PFieldData        = ^TFieldData;
  PFieldDataArray   = ^TFieldDataArray;
//  {$ENDIF}

  function AllocFieldValueArray(aFieldCount: Integer): TFieldDataArray;

type
  //data for one row
  TRowData = packed record
    FieldValues: TFieldDataArray;
  end;
  PRowData = ^TRowData;

  //TRowValueArray = array of TFieldValueArray;   //data for each row
  TRowDataArray = packed array of TRowData;         //data for each row

  //data for all rows in a list
  //note: seperate record so lists can share a pointer to this record. Changes to "RowValues" array are
  //shared with all lists this way (pointer to an array can/will change with each SetLength() call)
  TRowListData = packed record
    RowValues: TRowDataArray;
  end;
  PRowListData = ^TRowListData;

  //data for one row, that contains sub data (single rows/models and/or lists)
  //for example, a Relation row (.RowData) can contain a list of Emailaddresses and a list of Addresses (2 entries in .RecordListData)
  TMultiRowData = packed record
  public
    //inner/nested type, otherwise no recursive forward type decl. possible for "array of TMultiRowListData"
    type
      TMultiRowDataArray = packed array of TMultiRowData;
      TMultiRowListData  = packed record
        RowValues: TMultiRowDataArray;
        FDataLoaded: Boolean;    //better alignment for RowValues
      end;
      PMultiRowListData  = ^TMultiRowListData;
  public
    RowData       : TRowData;                 //normal record data (for each field/column)
    //todo: how to fill single sub rows? also lazyload?
    SingleRowData : packed array of TRowData;      //data for sub data records (single row); Note: "TRowDataArray" has different meaning (but same type) so explicit new "array of" type here
    RecordListData: packed array of TMultiRowListData;   //data for sub data lists (one entry for each list)
    function  AddSlotForSingleRow: Integer;
    procedure AllocSlotsForSingleRow(aSlotCount: Integer);
    //add to RecordListData and get index
    function  AddSlotForList: Integer;
    procedure AllocSlotsForLists(aSlotCount: Integer);

    procedure ClearData;
  end;
  PMultiRowData = ^TMultiRowData;

  //re-type of inner/nested types
  TMultiRowDataArray = TMultiRowData.TMultiRowDataArray;
  TMultiRowListData  = TMultiRowData.TMultiRowListData;
  PMultiRowListData  = ^TMultiRowListData;

implementation

uses
  Variants;

function AllocFieldValueArray(aFieldCount: Integer): TFieldDataArray;
var
  i: Integer;
begin
  SetLength(Result, aFieldCount);
  for i := 0 to aFieldCount-1 do
    Result[i].Clear2Empty;
end;

{ TFieldValueRecord }

procedure TFieldData.Clear2Empty;
begin
  FFieldValue.Clear2Empty;
  FOrigValue.Clear2Empty;
  Modified := False;
end;

procedure TFieldData.Clear2Null;
begin
  if not Modified then
    FOrigValue := FFieldValue;
  Modified := (not FFieldValue.IsNull);
  FFieldValue.Clear2Null;
end;

function TFieldData.GetFieldValue: Variant;
begin
  Result := FFieldValue.GetFieldValueFromType(Self.DataType);
end;

function TFieldData.GetOrigValue: Variant;
begin
  Result := FOrigValue.GetFieldValueFromType(Self.DataType);
end;

procedure TFieldData.LoadValue(aValue: Variant);
begin
  FFieldValue.SetFieldValueForType(Self.DataType, aValue);
  FOrigValue.Clear2Empty;
  Self.Modified := False;   //loaded from db
end;

procedure TFieldData.ResetModifiedState;
begin
  FOrigValue.Clear2Empty;
  Self.Modified    := False;
end;

procedure TFieldData.SetFieldValue(const aValue: Variant);
var
  vardata: PVarData;
  bIsEmpty, bIsNull: Boolean;
  vValue: Variant;
begin
  vardata  := FindVarData(aValue);
  bIsEmpty := (vardata^.VType = varEmpty);

  //'' = null and date 0 = null
  bIsNull  := bIsEmpty or
              (vardata^.VType = varNull) or
              (
                ( ( (vardata^.VType = varString) or
                    (vardata^.VType = varUString) or
                    (vardata^.VType = varOleStr)
                  ) and
                  (aValue = '')
                )
              ) or
              ( (vardata^.VType = varDate) and
                (aValue = 0)
              );

  if bIsEmpty then
    vValue := Unassigned
  else if bIsNull then
    vValue := Null
  else
  begin
    vValue := aValue;
  end;

  //                                                                  Oldvalue is empty/null, new value is null
  if (FFieldValue.GetFieldValueFromType(Self.DataType) <> vValue) or (IsEmptyOrNull and (not bIsEmpty or bIsNull)) then
  begin
    //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
    if FOrigValue.IsEmpty then
      FOrigValue := FFieldValue;
    Modified     := True;
    FFieldValue.SetFieldValueForType(Self.DataType, vValue);
  end;
end;

procedure TFieldData.SetValueAsBoolean(const aValue: Boolean);
begin
  //changed?
  if IsEmptyOrNull or (DataType <> ftFieldBoolean) or (ValueAsBoolean <> aValue) then
  begin
    //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
    if FOrigValue.IsEmpty then
      FOrigValue := FFieldValue;
    Modified     := True;
    FFieldValue.SetBooleanForType(Self.DataType, aValue);
  end;
end;

procedure TFieldData.SetValueAsDateTime(const aValue: TDateTime);
begin
  //empty date = 0 = null
  if aValue = 0 then
    Clear2Null
  else
    //changed?
    if IsEmptyOrNull or (DataType <> ftFieldDateTime) or (ValueAsDateTime <> aValue) then
    begin
      //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
      if FOrigValue.IsEmpty then
        FOrigValue := FFieldValue;
      Modified     := True;
      FFieldValue.SetDoubleForType(Self.DataType, aValue);
    end;
end;

procedure TFieldData.SetValueAsDouble(const aValue: Double);
begin
  //changed?
  if IsEmptyOrNull or (DataType <> ftFieldDouble) or (ValueAsDouble <> aValue) then
  begin
    //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
    if FOrigValue.IsEmpty then
      FOrigValue := FFieldValue;
    Modified     := True;
    FFieldValue.SetDoubleForType(Self.DataType, aValue);
  end;
end;

procedure TFieldData.SetValueAsInt64(const aValue: Int64);
begin
  //changed?
  if IsEmptyOrNull or (DataType <> ftFieldInteger) or (ValueAsInteger <> aValue) then
  begin
    //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
    if FOrigValue.IsEmpty then
      FOrigValue := FFieldValue;
    Modified     := True;
    FFieldValue.SetInt64ForType(Self.DataType, aValue);
  end;
end;

procedure TFieldData.SetValueAsInteger(const aValue: Integer);
begin
  //changed?
  if IsEmptyOrNull or (DataType <> ftFieldInteger) or (ValueAsInteger <> aValue) then
  begin
    //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
    if FOrigValue.IsEmpty then
      FOrigValue := FFieldValue;
    Modified     := True;
    FFieldValue.SetIntegerForType(Self.DataType, aValue);
  end;
end;

procedure TFieldData.SetValueAsString(const aValue: String);
begin
  //'' = null
  if aValue = '' then
    Clear2Null
  else
    //changed?
    if IsEmptyOrNull or (ValueAsString <> aValue) then
    begin
      //only copy the original value for the first "real" value (so "undo" restores initial values and not previous value because an user can change a field multiple times)
      if FOrigValue.IsEmpty then
        FOrigValue := FFieldValue;
      Modified     := True;
      FFieldValue.SetStringForType(Self.DataType, aValue);
    end;
end;

procedure TFieldData.UndoChange;
begin
  if not Modified then Exit;

  //copy value
  FFieldValue := FOrigValue;
  //empty
  FOrigValue.Clear2Empty;
  //reset
  Modified    := False;
end;

function TFieldData.GetValueAsBoolean: Boolean;
begin
  Result := FFieldValue.GetBooleanFromType(Self.DataType);
end;

function TFieldData.GetValueAsDateTime: TDateTime;
begin
  Result := FFieldValue.GetDoubleFromType(Self.DataType);
end;

function TFieldData.GetValueAsDouble: Double;
begin
  Result := FFieldValue.GetDoubleFromType(Self.DataType);
end;

function TFieldData.GetValueAsInt64: Int64;
begin
  Result := FFieldValue.GetInt64FromType(Self.DataType);
end;

function TFieldData.GetValueAsInteger: Integer;
begin
  Result := FFieldValue.GetIntegerFromType(Self.DataType);
end;

function TFieldData.GetValueAsString: String;
begin
  Result := FFieldValue.GetStringFromType(Self.DataType);
end;

function TFieldData.IsEmpty: Boolean;
begin
  Result := FFieldValue.IsEmpty;
end;

function TFieldData.IsEmptyOrNull: Boolean;
begin
  Result := FFieldValue.IsEmpty or FFieldValue.IsNull;
end;

function TFieldData.IsNull: Boolean;
begin
  Result := FFieldValue.IsNull;
end;

{ TMultiRowData }

function TMultiRowData.AddSlotForList: Integer;
begin
  SetLength(RecordListData, Length(RecordListData)+1);
  Result := High(RecordListData);
end;

function TMultiRowData.AddSlotForSingleRow: Integer;
begin
  SetLength(SingleRowData, Length(SingleRowData)+1);
  Result := High(SingleRowData);
end;

procedure TMultiRowData.AllocSlotsForLists(aSlotCount: Integer);
begin
  SetLength(RecordListData, aSlotCount);
end;

procedure TMultiRowData.AllocSlotsForSingleRow(aSlotCount: Integer);
begin
  SetLength(SingleRowData, aSlotCount);
end;

procedure TMultiRowData.ClearData;
var
   I: Integer;
begin
   for I := 0 to High(RecordListData) do
   begin
      RecordListData[I].FDataLoaded := false;
      RecordListData[I].RowValues := nil;
   end;
end;

{ TValueRecord }

procedure TValueRecord.Clear2Empty;
begin
  FFillState := fsEmpty;
  FString    := '';
  FDouble    := 0;
end;

procedure TValueRecord.Clear2Null;
begin
  FFillState := fsNull;
  FString    := '';
  FDouble    := 0;
end;

function TValueRecord.IsEmpty: Boolean;
begin
  Result := (FFillState = fsEmpty);
end;

function TValueRecord.IsNull: Boolean;
begin
  Result := (FFillState = fsNull);
end;

function TValueRecord.GetBooleanFromType(aType: TFieldType): Boolean;
begin
  if FFillState <> fsValue then Exit(False);
  case aType of
    ftFieldID:       Result := (FInt64 <> 0);
    ftFieldString:   Result := StrToBool(FString);
    ftFieldBoolean:  Result := FBoolean;
    ftFieldDouble:   Result := (FDouble <> 0);
    ftFieldInteger:  Result := (FInteger <> 0);
    ftFieldDateTime: Result := (FDatetime <> 0);
    ftFieldCurrency: Result := (FDouble <> 0);
  else
    Assert(False, 'Unhandled type');
    Exit(False);
  end;
end;

function TValueRecord.GetDoubleFromType(aType: TFieldType): Double;
begin
  if FFillState <> fsValue then Exit(0);
  case aType of
    ftFieldID:       Result := FInt64;
    ftFieldString:   Result := StrToFloat(FString);
    ftFieldBoolean:  Result := Ord(FBoolean);
    ftFieldDouble:   Result := FDouble;
    ftFieldInteger:  Result := FInteger;
    ftFieldDateTime: Result := FDatetime;
    ftFieldCurrency: Result := FDouble;
  else
    Assert(False, 'Unhandled type');
    Exit(0);
  end;
end;

function TValueRecord.GetInt64FromType(aType: TFieldType): Int64;
begin
  if FFillState <> fsValue then Exit(0);
  case aType of
    ftFieldID:       Result := FInt64;
    ftFieldString:   Result := StrToInt(FString);
    ftFieldBoolean:  Result := Ord(FBoolean);
    ftFieldDouble:   Result := Trunc(FDouble);
    ftFieldInteger:  Result := FInteger;
    ftFieldDateTime: Result := Trunc(FDatetime);
    ftFieldCurrency: Result := Trunc(FDouble);
  else
    Assert(False, 'Unhandled type');
    Exit(0);
  end;
end;

function TValueRecord.GetIntegerFromType(aType: TFieldType): Integer;
begin
  if FFillState <> fsValue then Exit(0);
  case aType of
    ftFieldID:       Result := FInt64;
    ftFieldString:   Result := StrToInt(FString);
    ftFieldBoolean:  Result := Ord(FBoolean);
    ftFieldDouble:   Result := Trunc(FDouble);
    ftFieldInteger:  Result := FInteger;
    ftFieldDateTime: Result := Trunc(FDatetime);
    ftFieldCurrency: Result := Trunc(FDouble);
  else
    Assert(False, 'Unhandled type');
    Exit(0);
  end;
end;

function TValueRecord.GetStringFromType(aType: TFieldType): String;
begin
  if FFillState <> fsValue then Exit('');
  case aType of
    ftFieldID:       Result := IntToStr(FInt64);
    ftFieldString:   Result := FString;
    ftFieldBoolean:  Result := BoolToStr(FBoolean, True);
    ftFieldDouble:   Result := FloatToStr(FDouble);
    ftFieldInteger:  Result := IntToStr(FInteger);
    ftFieldDateTime: Result := DateTimeToStr(FDatetime);
    ftFieldCurrency: Result := FloatToStr(FDouble);
  else
    Assert(False, 'Unhandled type');
    Exit('');
  end;
end;

function TValueRecord.GetFieldValueFromType(aType: TFieldType): Variant;
begin
  if FFillState = fsEmpty then
    Exit(Unassigned)
  else if FFillState = fsNull then
    Exit(Null)
  else
    case aType of
      ftFieldID:       Result := FInt64;
      ftFieldString:   Result := FString;
      ftFieldBoolean:  Result := FBoolean;
      ftFieldDouble:   Result := FDouble;
      ftFieldInteger:  Result := FInteger;
      ftFieldDateTime: Result := FDatetime;
      ftFieldCurrency: Result := FDouble;
    else
      Assert(False, 'Unhandled type');
    end;
end;

procedure TValueRecord.SetBooleanForType(aType: TFieldType; const aValue: Boolean);
begin
  FFillState := fsValue;
  case aType of
    ftFieldID:       FInt64    := Ord(aValue);
    ftFieldString:   FString   := BoolToStr(aValue, True);
    ftFieldBoolean:  FBoolean  := aValue;
    ftFieldDouble:   FDouble   := Ord(aValue);
    ftFieldInteger:  FInteger  := Ord(aValue);
    ftFieldDateTime: FDatetime := Ord(aValue);
    ftFieldCurrency: FDouble   := Ord(aValue);
  else
    Assert(False, 'Unhandled type');
  end;
end;

procedure TValueRecord.SetDoubleForType(aType: TFieldType; const aValue: Double);
begin
  FFillState := fsValue;
  case aType of
    ftFieldID:       FInt64    := Trunc(aValue);
    ftFieldString:   FString   := FloatToStr(aValue);
    ftFieldBoolean:  FBoolean  := (aValue <> 0);
    ftFieldDouble:   FDouble   := aValue;
    ftFieldInteger:  FInteger  := Trunc(aValue);
    ftFieldDateTime: FDatetime := aValue;
    ftFieldCurrency: FDouble   := aValue;
  else
    Assert(False, 'Unhandled type');
  end;
end;

procedure TValueRecord.SetFieldValueForType(aType: TFieldType; const aValue: Variant);
begin
  if VarIsEmpty(aValue) then
    Clear2Empty
  else if VarIsNull(aValue) then
    Clear2Null
  else
  begin
    FFillState := fsValue;
    case aType of
      ftFieldID:       FInt64    := aValue;
      ftFieldString:   FString   := aValue;
      ftFieldBoolean:  FBoolean  := aValue;
      ftFieldDouble:   FDouble   := aValue;
      ftFieldInteger:  FInteger  := aValue;
      ftFieldDateTime: FDatetime := aValue;
      ftFieldCurrency: FDouble   := aValue;
    else
      Assert(False, 'Unhandled type');
    end;
  end;
end;

procedure TValueRecord.SetInt64ForType(aType: TFieldType; const aValue: Int64);
begin
  FFillState := fsValue;
  case aType of
    ftFieldID:       FInt64    := aValue;
    ftFieldString:   FString   := IntToStr(aValue);
    ftFieldBoolean:  FBoolean  := (aValue <> 0);
    ftFieldDouble:   FDouble   := aValue;
    ftFieldInteger:  FInteger  := aValue;
    ftFieldDateTime: FDatetime := aValue;
    ftFieldCurrency: FDouble   := aValue;
  else
    Assert(False, 'Unhandled type');
  end;
end;

procedure TValueRecord.SetIntegerForType(aType: TFieldType; const aValue: Integer);
begin
  FFillState := fsValue;
  case aType of
    ftFieldID:       FInt64    := aValue;
    ftFieldString:   FString   := IntToStr(aValue);
    ftFieldBoolean:  FBoolean  := (aValue <> 0);
    ftFieldDouble:   FDouble   := aValue;
    ftFieldInteger:  FInteger  := aValue;
    ftFieldDateTime: FDatetime := aValue;
    ftFieldCurrency: FDouble   := aValue;
  else
    Assert(False, 'Unhandled type');
  end;
end;

procedure TValueRecord.SetStringForType(aType: TFieldType; const aValue: String);
begin
  FFillState := fsValue;
  case aType of
    ftFieldID:       FInt64    := StrToInt(aValue);
    ftFieldString:   FString   := aValue;
    ftFieldBoolean:  FBoolean  := StrToBool(aValue);
    ftFieldDouble:   FDouble   := StrToFloat(aValue);
    ftFieldInteger:  FInteger  := StrToInt(aValue);
    ftFieldDateTime: FDatetime := StrToDateTime(aValue);
    ftFieldCurrency: FDouble   := StrToFloat(aValue);
  else
    Assert(False, 'Unhandled type');
  end;
end;

{ TInterfacedNoRefObject }

function TInterfacedNoRefObject.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE
end;

function TInterfacedNoRefObject._AddRef: Integer;
begin
  Result := -1;
end;

function TInterfacedNoRefObject._Release: Integer;
begin
  Result := -1;
end;

end.
