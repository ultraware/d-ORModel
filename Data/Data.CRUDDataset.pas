{***************************************************************************}
{                                                                           }
{           d'ORModel - Model based ORM for Delphi                          }
{           Copyright (C) 2013-2014 www.ultraware.nl                        }
{                                                                           }
{           Dataset is based on part of "Delphi Spring Framework"           }
{           http://delphi-spring-framework.googlecode.com                   }
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

{$I compilers.inc}

unit Data.CRUDDataset;

interface

uses
  Classes, Windows, TypInfo, SysUtils,
  RTTI, DB, Generics.Collections,
  Data.DataRecord, Data.CRUD, Data.DataRecordList;

type
  TBaseRecordDataset = class abstract(TDataSet)
  protected
    type
      PRecInfo = ^TRecInfo;
      TRecInfo = record
        Index: Integer;
        Bookmark: TBookmark;
        BookmarkFlag: TBookmarkFlag;
      end;

      const
        fCRecordSize = 4; // actual data without house-keeping
  protected
    function  GetSortString: String; virtual; abstract;
    procedure SetSortString(const Value: String); virtual; abstract;
  protected
    fIsOpen: Boolean;
    fRecordBufferSize: Integer; // actual data without housekeeping
    fActiveRecordIndex: Integer;
    FFieldDictionary: TDictionary<string ,TBaseField>;
    function  GetActiveRecordBuffer: TRecordBuffer;
    procedure DoBeforeInsert; override;
    procedure DoBeforeDelete; override;
    function  AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
    procedure InternalInitRecord(Buffer: TRecordBuffer); override;

    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark); override;
    function  GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override;

    function  GetRecordSize: Word; override;
    procedure InternalFirst; override;

    procedure InternalGotoBookmark(Bookmark: Pointer); override;
    procedure InternalGotoBookmark(Bookmark: TBookmark); override;

    procedure InternalLast; override;
    procedure InternalSetToRecord(Buffer: TRecordBuffer); override;
    procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag); override;

    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark); override;

    procedure SetRecNo(Value: Integer); override;
    function  GetRecordCount: Integer; override;
    function  GetRecNo: Integer; override;

    procedure DoAfterScroll; override;

    procedure SetFieldData(aField: TField; aBuffer: Pointer);overload; override;
    //{$ifdef COMPILER_12_UP}
    procedure SetFieldData(aField: TField; aBuffer: TValueBuffer); overload; override;
    procedure SetFieldData(aField: TField; aBuffer: TValueBuffer; aNativeFormat: Boolean); overload; override;
    //{$endif}
  protected
    { Abstract Methods }
    function  GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override;
    procedure InternalClose; override;
    procedure InternalHandleException; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    function  IsCursorOpen: Boolean; override;

    function GetCurrentDataRecord: TDataRecord; virtual; abstract;
    function GetCurrentBookmark: TBookmark; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); overload; override;
    destructor  Destroy; override;

    function IsSequenced: Boolean; override;
    function GetFieldData(aField: TField; aBuffer: Pointer): Boolean; overload; override;
    //{$ifdef COMPILER_12_UP}
    function GetFieldData(aField: TField; aBuffer: TValueBuffer): Boolean; overload; override;
    function GetFieldData(aFieldNo: Integer; aBuffer: TValueBuffer): Boolean; overload; override;
    function GetFieldData(aField: TField; aBuffer: TValueBuffer; aNativeFormat: Boolean): Boolean; overload; override;
    //{$endif}

    procedure Resync(Mode: TResyncMode); override;
    function  CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer; override;
    function  BookmarkValid(Bookmark: TBookmark): Boolean; override;

    property SortString: String read GetSortString write SetSortString;
  end;

  TCustomRecordDataset = class(TBaseRecordDataset)
  published
    property Active;
    //property AutoCalcFields;

    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property BeforeRefresh;
    property AfterRefresh;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
  end;

  TBaseCRUDDataset = class(TCustomRecordDataset)
  private
    FRowRecNo: Integer;
    FSourceCRUD: TBaseDataCRUD;
    FOwnsSourceCRUD: boolean;
    procedure SetSourceCRUD(const Value: TBaseDataCRUD);
  protected
    function  GetSortString: String; override;
    procedure SetSortString(const Value: String); override;
  protected
    procedure InternalGotoBookmark(Bookmark: TBookmark); override;
    function  GetCurrentBookmark: TBookmark; override;

    procedure InternalOpen; override;
    function  IsCursorOpen: Boolean; override;
    function  GetRecordCount: Integer; override;

    procedure InternalFirst; override;
    procedure InternalLast; override;

    function GetNextRecords: Integer; override;
    function GetNextRecord: Boolean; override;
    function GetPriorRecords: Integer; override;
    function GetPriorRecord: Boolean; override;
  public
    destructor Destroy; override;

    function MoveBy(Distance: Integer): Integer; override;
    function GetCurrentDataRecord: TDataRecord; override;

    property SourceCRUD: TBaseDataCRUD read FSourceCRUD write SetSourceCRUD;
    property OwnsSourceCRUD: boolean read FOwnsSourceCRUD write FOwnsSourceCRUD;
  end;

  TCustomCRUDDataset<T:TBaseDataCRUD> = class(TBaseCRUDDataset)
  private
    function  GetSourceCRUD: T;
    procedure SetSourceCRUD(const aValue: T);
  public
    constructor Create(aCRUD: T); overload; virtual;
    constructor Create(AOwner: TComponent); overload; override;

    property SourceCRUD: T read GetSourceCRUD write SetSourceCRUD;
  end;

  //----------------------------------------------------------------

  TBaseListDataset = class(TCustomRecordDataset)
  private
    FRowRecNo: Integer;
    FSourceList: TBaseDataRecordList;
    procedure SetSourceList(const Value: TBaseDataRecordList);
  protected
    function  GetCurrentDataRecord: TDataRecord;override;
    procedure InternalOpen; override;
    function  IsCursorOpen: Boolean; override;
    function  GetRecordCount: Integer; override;
  public
    property SourceList: TBaseDataRecordList read FSourceList write SetSourceList;
  end;

  TCustomListDataset<T:TBaseDataRecordList> = class(TBaseListDataset)
  private
    function  GetSourceList: T;
    procedure SetSourceList(const aValue: T);
  public
    constructor Create(aList: T); overload; virtual;
    property SourceList: T read GetSourceList write SetSourceList;
  end;


implementation

uses
  StrUtils, Meta.Data, Data.Query, Data.DatasetFields, GlobalRTTI,
  Data.Win.ADOConst, System.Math;

{ TBaseRecordDataset }

//todo: move to functions via CRUD
function TBaseRecordDataset.BookmarkValid(Bookmark: TBookmark): Boolean;
begin
  Result := Length(Bookmark) > 0;
end;

//todo: move to functions via CRUD
function TBaseRecordDataset.CompareBookmarks(Bookmark1,
  Bookmark2: TBookmark): Integer;
begin
  Result := 0;
  if Length(Bookmark1) = SizeOf(Integer) then
    Result := CompareValue( PInteger(Bookmark1)^, PInteger(Bookmark2)^ )
  else if Length(Bookmark1) = SizeOf(Double) then   //ado recordset uses double as bookmark, todo: move compare to ado recordset
    Result := CompareValue( PDouble(Bookmark1)^, PDouble(Bookmark2)^ )
  else
    Assert(false);
end;

constructor TBaseRecordDataset.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   fRecordBufferSize := SizeOf(TRecInfo);
   BookmarkSize := SizeOf(Integer);
   FFieldDictionary := TDictionary<string ,TBaseField>.Create;
end;

destructor TBaseRecordDataset.Destroy;
begin
   FFieldDictionary.Free;
   inherited;
end;

procedure TBaseRecordDataset.InternalInitFieldDefs;
var
  f: TBaseField;
  UniqueName: string;
  Index: Integer;
Begin
  FieldDefs.Clear;
  FFieldDictionary.Clear;

  for f in GetCurrentDataRecord do
  begin
    UniqueName := f.DisplayLabel;
    Index := 1;
    while (FieldDefs.IndexOf(UniqueName) >= 0) do
    begin
      UniqueName := f.DisplayLabel + IntToStr(Index);
      Inc(Index);
    end;

    FFieldDictionary.Add(UniqueName, f);
    case f.FieldType of
      ftFieldID:           FieldDefs.Add(UniqueName, ftLargeint,  0, f.IsRequired);
      ftFieldString:
      begin
        if f.MaxValue = 0 then
          FieldDefs.Add(UniqueName, ftWideString, 255, f.IsRequired)
        else
          FieldDefs.Add(UniqueName, ftWideString, Round(f.MaxValue), f.IsRequired);
      end;
      ftFieldBoolean:      FieldDefs.Add(UniqueName, ftBoolean,   0, f.IsRequired);
      ftFieldDouble:       FieldDefs.Add(UniqueName, ftFloat,     0, f.IsRequired);
      ftFieldInteger:      FieldDefs.Add(UniqueName, ftInteger,   0, f.IsRequired);
      ftFieldDateTime:     FieldDefs.Add(UniqueName, ftDateTime,  0, f.IsRequired);
      ftFieldCurrency:     FieldDefs.Add(UniqueName, ftCurrency,  0, f.IsRequired);
      //
      //not implemented yet
//      ftFieldBLOB:         ; //ignore FieldDefs.Add(f.FieldName, ftBlob,      0, f.Required);
//      ftFieldVariant:      ; //FieldDefs.Add(f.FieldName, ftVariant,  0, f.Required);
    else
        raise Exception.Create(f.PropertyName + ' can not be made into a valid TField');
    end;
  end;
end;

function TBaseRecordDataset.GetFieldData(aField: TField; aBuffer: Pointer): Boolean;
var
  TempID: Int64;
  TempDouble: Double;
  TempStr: String;
  TempInt: Integer;
  TempBool: Boolean;
  f: TBaseField;
begin
  Result := false;
  if not FisOpen or (RecordCount <= 0) then
    exit;
  if aBuffer = nil then
  begin
    //Dataset checks if field is null by passing a nil buffer
    //Tell it is not null by passing back a result of True
    Result := True;
    exit;
  end;
  if (aField.FieldKind = fkCalculated) or (aField.FieldKind = fkLookup) then
  begin
    Assert(False);
  end
  else
  begin
    GetCurrentDataRecord;
    FFieldDictionary.TryGetValue(aField.FieldName, f);
    Assert(f <> nil, 'Field not found: ' + aField.FieldName);
    if f.IsEmptyOrNull then Exit(False);

    case f.FieldType of
      ftFieldID:
      begin
        TempID := f.ValueAsInt64;
        CopyMemory(aBuffer, @TempID, SizeOf(TempID));
      end;
      ftFieldString:
      begin
        TempStr := f.ValueAsString;
        if (TempStr = '') then
          Exit(True);
        Assert( Length(TValueBuffer(aBuffer)) >= Length(TempStr) * StringElementSize(TempStr) );
        StrLCopy(PWideChar(aBuffer), PWideChar(@TempStr[1]), Length(TempStr));
      end;
      ftFieldBoolean:
      begin
        TempBool := f.ValueAsBoolean;
        CopyMemory(aBuffer, @TempBool, SizeOf(TempBool));
      end;
      ftFieldDouble, ftFieldDateTime, ftFieldCurrency:
      begin
        TempDouble := f.ValueAsDouble;
        CopyMemory(aBuffer, @TempDouble, SizeOf(TempDouble));
      end;
      ftFieldInteger:
      begin
        TempInt := f.ValueAsInteger;
        CopyMemory(aBuffer, @TempInt, SizeOf(TempInt));
      end;
    else
      Assert(False);
    end;
  end;
  Result := True;
end;

procedure TBaseRecordDataset.SetFieldData(aField: TField; aBuffer: Pointer);
var
  f: TBaseField;
  TempID: Int64;
  TempDouble: Double;
  TempStr: String;
  TempInt: Integer;
  TempBool: Boolean;
begin
  if not Active then
    exit;
  if aBuffer = nil then
    exit;
  if (aField.FieldKind = fkCalculated) or (aField.FieldKind = fkLookup) then
  begin
    //?
  end;

  GetCurrentDataRecord;
  FFieldDictionary.TryGetValue(aField.FieldName, f);
  Assert(f <> nil, 'Field not found: ' + aField.FieldName);

  case f.FieldType of
    ftFieldID:
    begin
      CopyMemory(@TempID, aBuffer, SizeOf(TempID));
      f.ValueAsVariant := TempID;
    end;
    ftFieldString:
    begin
      TempStr := PWideChar(aBuffer);
      f.ValueAsVariant := TempStr;
    end;
    ftFieldBoolean:
    begin
      CopyMemory(@TempBool, aBuffer, SizeOf(TempBool));
      f.ValueAsVariant := TempBool;
    end;
    ftFieldDouble, ftFieldDateTime, ftFieldCurrency:
    begin
      CopyMemory(@TempDouble, aBuffer, SizeOf(TempDouble));
      f.ValueAsVariant := TempDouble;
    end;
    ftFieldInteger:
    begin
      CopyMemory(@TempInt, aBuffer, SizeOf(TempInt));
      f.ValueAsVariant := TempInt;
    end;
  else
    Assert(False);
  end;
  if not (State in [dsCalcFields, dsFilter, dsNewValue]) then
    DataEvent(deFieldChange, Longint(aField));
end;

function TBaseRecordDataset.GetActiveRecordBuffer: TRecordBuffer;
begin
  case State of
    dsBrowse:
      begin
        if IsEmpty then
          Result := nil
        else
          Result := ActiveBuffer;
      end;
    dsEdit, dsInsert:
      begin
        Result := ActiveBuffer;
      end;
    else
      begin
        Result := nil;
      end;
  end;
end;

function TBaseRecordDataset.AllocRecordBuffer: TRecordBuffer;
begin
  Result := AllocMem(fRecordBufferSize);
end;

procedure TBaseRecordDataset.InternalInitRecord(Buffer: TRecordBuffer);
begin
  ZeroMemory(Buffer, fRecordBufferSize);
end;

procedure TBaseRecordDataset.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
  PRecInfo(Buffer).Bookmark := nil;
  FreeMem(Buffer);
end;

procedure TBaseRecordDataset.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  Assert(False);
end;

procedure TBaseRecordDataset.GetBookmarkData(Buffer: TRecordBuffer;
  Data: TBookmark);
var
  i: Integer;
begin
  for i := 0 to Min( High(Data), High(PRecInfo(Buffer).Bookmark) ) do
    Data[i] := PRecInfo(Buffer).Bookmark[i];
end;

function TBaseRecordDataset.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
  Result := PRecInfo(Buffer).BookmarkFlag;
end;

//{$ifndef COMPILER_12_UP}
function TBaseRecordDataset.GetFieldData(aField: TField; aBuffer: TValueBuffer): Boolean;
begin
  Result := GetFieldData(aField, @aBuffer[0]);
end;
//{$ENDIF}

function TBaseRecordDataset.GetRecNo: Integer;
begin
  if GetActiveRecordBuffer <> nil then
    Result := PRecInfo(GetActiveRecordBuffer).Index + 1
  else
    Result := 0;
end;

function TBaseRecordDataset.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
begin
  if (BookmarkSize = 0) and (BufferCount > 1) then
    DatabaseError(SBookmarksRequired);

  Result := grOK; // default
  case GetMode of
    gmNext: // move on
      if fActiveRecordIndex < RecordCount - 1 then
        Inc(fActiveRecordIndex)
      else
        Result := grEOF; // end of file
    gmPrior: // move back
      if fActiveRecordIndex > 0 then
        Dec(fActiveRecordIndex)
      else
        Result := grBOF; // begin of file
    gmCurrent: // check if empty
      if fActiveRecordIndex > RecordCount then
        Result := grEOF
      else if fActiveRecordIndex < 0 then
        Result := grBOF; // begin of file
  end;

  if Result = grOK then // read the data
  with PRecInfo(Buffer)^ do
  begin
    Index := fActiveRecordIndex;
    BookmarkFlag := bfCurrent;
    Bookmark := GetCurrentBookmark;
  end;
end;

function TBaseRecordDataset.GetRecordCount: Integer;
begin
  Result := 1;
end;

function TBaseRecordDataset.GetRecordSize: Word;
begin
  Result := fCRecordSize;
end;

procedure TBaseRecordDataset.InternalClose;
begin
  BindFields(False);
  if DefaultFields then
  begin
    DestroyFields;
  end;
  fActiveRecordIndex := -1;
  fIsOpen := False;
end;

procedure TBaseRecordDataset.InternalFirst;
begin
  if IsEmpty then
    fActiveRecordIndex := -1
  else
    fActiveRecordIndex := 0;
end;

procedure TBaseRecordDataset.InternalGotoBookmark(Bookmark: TBookmark);
begin
  Assert(false, 'function must be overriden in descendant');
end;

procedure TBaseRecordDataset.InternalGotoBookmark(Bookmark: Pointer);
begin
  Assert(false);
end;

procedure TBaseRecordDataset.InternalHandleException;
begin
  Assert(False);
end;

procedure TBaseRecordDataset.InternalLast;
begin
  fActiveRecordIndex := RecordCount;
end;

procedure TBaseRecordDataset.InternalOpen;
var
  f: TBaseField;
  i: Integer;
begin
  fActiveRecordIndex := -1;
  InternalInitFieldDefs;
  if DefaultFields then
    CreateFields;
  BindFields(True);
  fIsOpen := True;

  for f in GetCurrentDataRecord do
  begin
    for i := 0 to Fields.Count - 1 do
    begin
      if Fields.Fields[i].FieldName = f.PropertyName then
      begin
        Fields.Fields[i].DisplayLabel := f.DisplayLabel;
        Fields.Fields[i].DisplayWidth := f.DisplayWidth;
        Fields.Fields[i].EditMask     := f.EditMask;
        if Fields.Fields[i] is TNumericField then
        begin
          (Fields.Fields[i] as TNumericField).DisplayFormat := f.DisplayFormat;
          (Fields.Fields[i] as TNumericField).EditFormat    := f.EditFormat;
        end
        else if Fields.Fields[i] is TIntegerField then
        begin
          (Fields.Fields[i] as TIntegerField).MinValue := Round(f.MinValue);
          (Fields.Fields[i] as TIntegerField).MaxValue := Round(f.MaxValue);
        end
        else if Fields.Fields[i] is TLongWordField then
        begin
          (Fields.Fields[i] as TLongWordField).MinValue := Round(f.MinValue);
          (Fields.Fields[i] as TLongWordField).MaxValue := Round(f.MaxValue);
        end
        else if Fields.Fields[i] is TLargeintField then
        begin
          (Fields.Fields[i] as TLargeintField).MinValue := Round(f.MinValue);
          (Fields.Fields[i] as TLargeintField).MaxValue := Round(f.MaxValue);
        end
        else if Fields.Fields[i] is TFloatField then
        begin
          (Fields.Fields[i] as TFloatField).MinValue := f.MinValue;
          (Fields.Fields[i] as TFloatField).MaxValue := f.MaxValue;
        end
        else if Fields.Fields[i] is TSingleField then
        begin
          (Fields.Fields[i] as TSingleField).MinValue := f.MinValue;
          (Fields.Fields[i] as TSingleField).MaxValue := f.MaxValue;
        end
        else if Fields.Fields[i] is TExtendedField then
        begin
          (Fields.Fields[i] as TExtendedField).MinValue := f.MinValue;
          (Fields.Fields[i] as TExtendedField).MaxValue := f.MaxValue;
        end
        else if Fields.Fields[i] is TBCDField then
        begin
          (Fields.Fields[i] as TBCDField).MinValue := f.MinValue;
          (Fields.Fields[i] as TBCDField).MaxValue := f.MaxValue;
        end;
        Break;
      end;
    end;
  end;
end;

procedure TBaseRecordDataset.InternalSetToRecord(Buffer: TRecordBuffer);
begin
  fActiveRecordIndex := PRecInfo(Buffer).Index;   //index is our own stored fActiveRecordIndex
end;

function TBaseRecordDataset.IsCursorOpen: Boolean;
begin
  Result := fIsOpen;
end;

function TBaseRecordDataset.IsSequenced: Boolean;
begin
   Result := True;
end;

procedure TBaseRecordDataset.Resync(Mode: TResyncMode);
begin
  inherited Resync(Mode);
end;

procedure TBaseRecordDataset.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  Assert(False);
end;

procedure TBaseRecordDataset.SetBookmarkData(Buffer: TRecordBuffer;
  Data: TBookmark);
begin
  PRecInfo(Buffer).Bookmark := Data;
end;

procedure TBaseRecordDataset.SetBookmarkFlag(Buffer: TRecordBuffer;
  Value: TBookmarkFlag);
begin
  PRecInfo(Buffer).BookmarkFlag := Value;
end;

//{$IFNDEF COMPILER_12_UP}
procedure TBaseRecordDataset.SetFieldData(aField: TField; aBuffer: TValueBuffer);
begin
  SetFieldData(aField, @aBuffer[0]);
end;

procedure TBaseRecordDataset.SetFieldData(aField: TField; aBuffer: TValueBuffer;
  aNativeFormat: Boolean);
begin
  SetFieldData(aField, @aBuffer[0]);
end;
//{$ENDIF}


procedure TBaseRecordDataset.SetRecNo(Value: Integer);
begin
  if (Value < 0) or (Value > RecordCount) then
    raise Exception.Create('SetRecNo: out of range');

  if fActiveRecordIndex <> Value - 1 then
  begin
    DoBeforeScroll;
    fActiveRecordIndex := Value - 1;
    Resync([rmCenter]);
    DoAfterScroll;
  end;
end;

procedure TBaseRecordDataset.DoBeforeInsert;
begin
  SysUtils.Abort;
end;

procedure TBaseRecordDataset.DoAfterScroll;
begin
  GetCurrentDataRecord;   //update attached sourcecrud

  inherited DoAfterScroll;
end;

procedure TBaseRecordDataset.DoBeforeDelete;
begin
  SysUtils.Abort;
end;

//{$IFNDEF COMPILER_12_UP}
function TBaseRecordDataset.GetFieldData(aFieldNo: Integer; aBuffer: TValueBuffer): Boolean;
begin
  Result := GetFieldData(Self.Fields[aFieldNo], @aBuffer[0]);
end;

function TBaseRecordDataset.GetFieldData(aField: TField; aBuffer: TValueBuffer; aNativeFormat: Boolean): Boolean;
begin
  if Length(aBuffer)= 0 then
    Result := GetFieldData(aField, nil)
  else
    Result := GetFieldData(aField, @aBuffer[0]);
end;
//{$ENDIF}

{ TBaseCRUDDataset }

procedure TBaseCRUDDataset.InternalFirst;
begin
  inherited InternalFirst;
end;

procedure TBaseCRUDDataset.InternalGotoBookmark(Bookmark: TBookmark);
begin
  if (Bookmark <> nil) and (SourceCRUD <> nil) then
  begin
    SourceCRUD.QueryFindSetBookmark(Bookmark);
    fActiveRecordIndex := SourceCRUD.QueryFindGetRecNo - 1;
  end;
end;

procedure TBaseCRUDDataset.InternalLast;
begin
  inherited;
end;

procedure TBaseCRUDDataset.InternalOpen;
var
  bResult: Boolean;
  select: ISelect;
  i: Integer;
  f, fs: TBaseField;
  jf: TUltraSpecialJoinField;
  bfieldsadded: Boolean;
  sfieldname: string;
begin
  FRowRecNo := -1;
  if (SourceCRUD = nil) then
  begin
    Exit;
  end;

  inherited InternalOpen;

  if not Self.OwnsSourceCRUD or
     not SourceCRUD.HasQuery then
  begin
    bfieldsadded := False;

    if SourceCRUD.HasQuery then
      select := SourceCRUD.Query.Select
    else
      select := SourceCRUD.NewQuery.Select;
    for i := 0 to Self.Fields.Count-1 do
    begin
      FFieldDictionary.TryGetValue(Fields[i].FieldName, f);

      //unknown field? probably an custom join field
      if f = nil then
      begin
        if Self.Fields[i] is TUltraSpecialJoinField then
        begin
          jf := (Self.Fields[i] as TUltraSpecialJoinField);
          Assert(jf.SourceFKField.FieldMetaData <> nil);

          //unique name
          sfieldname := jf.SourceFKField.FieldMetaData.FieldName + '_' +
                        jf.JoinPKField.TableMetaData.Table + '_' +
                        jf.JoinPKField.FieldMetaData.FieldName;
          //join field: PK of the remote/join table
          f  := TCustomField.Create(sfieldname, SourceCRUD.Data, SourceCRUD.Data.Count,
                                    jf.JoinPKField);
          SourceCRUD.Data.Add(f);
          //source field: FK of current/source table
          fs := SourceCRUD.Data.FieldByName(jf.SourceFKField.FieldMetaData.FieldName);
          Assert(fs <> nil, 'Sourcefield "' + jf.SourceFKField.FieldMetaData.FieldName + '" not found in dataset!');

          //add join
          select.Fields([]).LeftOuterJoin.OnFields(f, fs);

          //select field: the field of the remote/join table you want to get
          f  := TCustomField.Create(jf.FieldName, SourceCRUD.Data, SourceCRUD.Data.Count,
                                    jf.SelectField);
          SourceCRUD.Data.Add(f);

          jf.ChangeDataType( Own2DelphiFieldType(f.FieldType) );
          bfieldsadded := True;
        end;
      end;

      if Assigned(f) and (not (select as iqueryDetails).SelectFields_Ordered.Contains(f)) then
        select.Fields([f]);
    end;

    if bfieldsadded then
      SourceCRUD.Data.AllocFieldValues;
  end;

  if (Self.Owner <> nil) and
     (csDesigning in Self.Owner.ComponentState) then
    bResult := SourceCRUD.QuerySearchSingle
  else
    bResult := SourceCRUD.QueryFindFirst;

  if bResult then
    FRowRecNo := 0
  else
    FRowRecNo := -1;
end;

destructor TBaseCRUDDataset.Destroy;
begin
  if OwnsSourceCRUD then
    SourceCRUD.Free;
  inherited;
end;

function TBaseCRUDDataset.GetCurrentBookmark: TBookmark;
var iRow, iDiff: Integer;
begin
  Result := nil;

  iRow := fActiveRecordIndex + 1;
  if SourceCRUD <> nil then
  begin
    //position row on row which we are currently loading (note: different to RecNo!)
    iDiff := iRow - SourceCRUD.QueryFindGetRecNo;
    if iDiff <> 0 then
      SourceCRUD.QueryFindMove(iDiff);

    Result := SourceCRUD.QueryFindGetBookmark;
    BookmarkSize := Length(Result);
  end;
end;

function TBaseCRUDDataset.GetCurrentDataRecord: TDataRecord;
var iRow, iDiff: Integer;
begin
  Result := nil;

  if RecordCount <= 0 then
    Exit(SourceCRUD.Data);

  iRow := RecNo;
  if SourceCRUD <> nil then
  begin
    iDiff := iRow - SourceCRUD.QueryFindGetRecNo;
    if iDiff <> 0 then
      SourceCRUD.QueryFindMove(iDiff);
    Result := SourceCRUD.Data;
  end;
end;

function TBaseCRUDDataset.GetNextRecord: Boolean;
begin
  Result := inherited;
end;

function TBaseCRUDDataset.GetNextRecords: Integer;
begin
  Result := inherited;
end;

function TBaseCRUDDataset.GetPriorRecord: Boolean;
begin
  Result := inherited; // and (FRowOffset > 0);
end;

function TBaseCRUDDataset.GetPriorRecords: Integer;
begin
  Result := inherited;
end;

function TBaseCRUDDataset.GetRecordCount: Integer;
begin
  if (State = dsInactive) and
     not IsCursorOpen then Exit(-1);

  if SourceCRUD = nil then
    Result := -1
  else
  begin
    if not IsCursorOpen then
      Result := 0
    else
      Result := SourceCRUD.QueryFindCount
  end;
end;

function TBaseCRUDDataset.GetSortString: String;
begin
  Result := '';
  if SourceCRUD <> nil then
    Result := SourceCRUD.QueryFindSortString;
end;

procedure TBaseCRUDDataset.SetSortString(const Value: String);
begin
  CheckActive;
  UpdateCursorPos;

  if SourceCRUD <> nil then
    SourceCRUD.QueryFindSortString := Value;

  Resync([]);
end;

function TBaseCRUDDataset.IsCursorOpen: Boolean;
begin
  Result := inherited IsCursorOpen and
            (SourceCRUD <> nil) and
            (FRowRecNo >= 0);
end;

function TBaseCRUDDataset.MoveBy(Distance: Integer): Integer;
begin
  Result := inherited;
end;

procedure TBaseCRUDDataset.SetSourceCRUD(const Value: TBaseDataCRUD);
begin
  //reset, must do new ".Open"
  Close;
  FRowRecNo := -1;
  fActiveRecordIndex := -1;

  FSourceCRUD := Value;
end;

{ TCustomCRUDDataset<T> }

constructor TCustomCRUDDataset<T>.Create(aCRUD: T);
begin
  inherited Create(nil);
  SourceCRUD := aCRUD;
end;

constructor TCustomCRUDDataset<T>.Create(AOwner: TComponent);
begin
  inherited;
end;

function TCustomCRUDDataset<T>.GetSourceCRUD: T;
begin
  Result := T(FSourceCRUD);
end;

procedure TCustomCRUDDataset<T>.SetSourceCRUD(const aValue: T);
begin
  inherited SetSourceCRUD(aValue);
end;

{ TBaseListDataset }

function TBaseListDataset.GetCurrentDataRecord: TDataRecord;
begin
  Result := nil;

  if SourceList <> nil then
  begin
    if (fActiveRecordIndex = -1) and (GetRecordCount > 0) then  //first time?
      FRowRecNo := 0
    else if (fActiveRecordIndex >= 0) and (fActiveRecordIndex <= GetRecordCount-1) then
    begin
      if FRowRecNo <> fActiveRecordIndex then
      begin
        SourceList.ScrollToRow(fActiveRecordIndex);
        FRowRecNo := fActiveRecordIndex;
      end;
    end;

    Result := SourceList.Data;
  end;
end;

function TBaseListDataset.GetRecordCount: Integer;
begin
  if (State = dsInactive) and
     not IsCursorOpen then Exit(-1);

  if SourceList = nil then
    Result := -1
  else
  begin
    if not SourceList.HasDataLoaded then
      Result := 0
    else
      Result := SourceList.Count
  end;
end;

procedure TBaseListDataset.InternalOpen;
begin
  inherited InternalOpen;

  if (SourceList <> nil) then
  begin
    if not SourceList.HasDataLoaded then
      Assert(False);
    FRowRecNo := 0;
  end
  else
    FRowRecNo := -1;
end;

function TBaseListDataset.IsCursorOpen: Boolean;
begin
  Result := inherited IsCursorOpen and
            (SourceList <> nil) and
            SourceList.HasDataLoaded and
            (FRowRecNo >= 0);
end;

procedure TBaseListDataset.SetSourceList(const Value: TBaseDataRecordList);
begin
  //reset, must do new ".Open"
  Close;
  FRowRecNo := -1;
  fActiveRecordIndex := -1;

  FSourceList := Value;
end;

{ TCustomListDataset<T> }

constructor TCustomListDataset<T>.Create(aList: T);
begin
  inherited Create(nil);
  SourceList := aList;
end;

function TCustomListDataset<T>.GetSourceList: T;
begin
  Result := T(FSourceList);
end;

procedure TCustomListDataset<T>.SetSourceList(const aValue: T);
begin
  inherited SetSourceList(aValue);
end;

end.
