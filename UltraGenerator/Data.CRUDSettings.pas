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
unit Data.CRUDSettings;

interface

uses
  Graphics, Classes, SysUtils, Controls,
  XMLFile, RttiClasses
  ;

const
  cCRUDSettings_XML = 'CRUDSettings.xml';

type
  TCRUDField = class(TRttiEnabled)
  private
    FFieldName: string;
    FFieldDisplaylabel: string;
    FFieldType: string;
    FRequired: Boolean;
    FCustomType: string;
    FIsFK: boolean;
    FIsPK: Boolean;
    FFKTable: string;
    FFKField: string;
    FPosition: Integer;
    FComment: string;
    FDescription: string;
    FDefaultValue: string;
    FHasDefaultValue: Boolean;
    FGenerateDirectJoin: boolean;
    FDisplayWidth: Integer;
    FEditFormat: string;
    FDisplayFormat: string;
    FEditMask: string;
    FMax: Double;
    FMin: Double;
    FSkipDefault: Boolean;
  public
    procedure AfterConstruction; override;
    function  FieldNameDelphi: string;
  published
    property FieldName    : string   read FFieldName          write FFieldName;
    property Displaylabel : string   read FFieldDisplaylabel  write FFieldDisplaylabel;
    property FieldType    : string   read FFieldType          write FFieldType;
    property CustomType   : string   read FCustomType         write FCustomType;

    property DisplayWidth : Integer  read FDisplayWidth       write FDisplayWidth;
    //Formats a floating-point value.
    property DisplayFormat: string   read FDisplayFormat      write FDisplayFormat;
    //Determines how a numeric field's value is formatted when it is being edited in a data-aware control.
    property EditFormat   : string   read FEditFormat         write FEditFormat;
    //generic editmask: http://docwiki.embarcadero.com/Libraries/XE5/en/Vcl.Mask.TCustomMaskEdit.EditMask
    property EditMask     : string   read FEditMask           write FEditMask;

    property Required     : Boolean  read FRequired           write FRequired;

    property MinValue     : Double   read FMin                write FMin;
    property MaxValue     : Double   read FMax                write FMax;

    property IsPK         : Boolean  read FIsPK               write FIsPK;
    property IsFK         : boolean  read FIsFK               write FIsFK;
    property FKTable      : string   read FFKTable            write FFKTable;
    property FKField      : string   read FFKField            write FFKField;
    property GenerateDirectJoin: boolean read FGenerateDirectJoin write FGenerateDirectJoin;

    property Position     : Integer  read FPosition           write FPosition;

    property DefaultValue : string   read FDefaultValue       write FDefaultValue;

    property Description  : string   read FDescription        write FDescription;
    property Comment      : string   read FComment            write FComment;
  	 property HasDefault   : Boolean  read FHasDefaultValue    write FHasDefaultValue;
    property SkipDefault  : Boolean  read FSkipDefault        write FSkipDefault;
  end;

  TCRUDFieldArray = array of TCRUDField;

  TCRUDTable = class(TRttiEnabled)
  private
    FName: string;
    FFields: TCRUDFieldArray;
    FComment: string;
    FDescription: string;
  public
    function  FieldCount: Integer;
    function  FindField(const aFieldName: string; const toevoegen: boolean): TCRUDField;
    function  AddField: TCRUDField;
    procedure DeleteField(aField: TCRUDField);

    function  TableNameDelphi: string;
  published
    property TableName : string         read FName   write FName;
    property Fields    : TCRUDFieldArray read FFields write FFields;

    property Description  : string   read FDescription        write FDescription;
    property Comment      : string   read FComment            write FComment;
  end;

  TCRUDTableArray = array of TCRUDTable;

  TCRUDSettings = class(TRttiEnabled)
  private
    FTables: TCRUDTableArray;
  public
    function  TableCount: Integer;

    procedure SaveToSettingsFile;
    procedure LoadFromSettingsFile;

    function  FindTable(const aTableName : string; const toevoegen : boolean) : TCRUDTable;
    procedure DeleteTable(const aTableRow: TCRUDTable);

    function AddTable : TCRUDTable;
  published
    property Tables : TCRUDTableArray read FTables write FTables;
  end;

function  CRUDSettings: TCRUDSettings;

implementation

uses
  Forms, Windows, fMain, Dialogs, UltraStringUtils;

{ TCRUDSettings }

var
  _CRUDSettings: TCRUDSettings;
function CRUDSettings: TCRUDSettings;
begin
  if _CRUDSettings = nil then
  begin
    _CRUDSettings := TCRUDSettings.Create;
    _CRUDSettings.LoadFromSettingsFile;
  end;

  Result := _CRUDSettings;
end;

function DelphiName(const FieldName: string): string;
begin
  Result := FieldName;
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '$', '', [rfReplaceAll]);
  if StringIn(Result, 'Object,Type,Procedure,Sort')  then
    Result := Result + '_'
end;

function TCRUDSettings.AddTable: TCRUDTable;
begin
  SetLength( FTables, length(FTables) + 1);
  Result := TCRUDTable.Create;
  FTables[High(FTables)] := Result;
end;

procedure TCRUDSettings.DeleteTable(const aTableRow: TCRUDTable);
var
  idxRow : Integer;
  temp   : TCRUDTableArray;
  j : integer;
begin
  for idxRow := Low(FTables) to High(FTables) do
  begin
    if FTables[idxRow] = aTableRow then
    begin
      temp := Copy(FTables, Low(FTables), idxRow);
      SetLength(temp, Length(FTables)-1);
      for j := idxRow+1 to High(FTables) do
        temp[j-1] := FTables[j];
      FTables := temp;
    end;
  end;
end;

function TCRUDSettings.FindTable(const aTableName: string; const toevoegen : boolean) : TCRUDTable;
var
  idxName : integer;
begin
  Result := nil;
  if aTableName <> '' then
  begin
    for idxName := 0 to TableCount - 1 do
    begin
      if SameText(Tables[idxName].TableName, aTableName) then
      begin
        Result := Tables[idxname];
        break;
      end;
    end;
    if (Result = nil) and toevoegen then
    begin
      Result           := AddTable;
      Result.TableName := aTableName;
    end;
  end;
end;

procedure TCRUDSettings.LoadFromSettingsFile;
var
  sFile: string;
begin
   sFile := TfrmMain.OutputCRUDPath + cCRUDSettings_XML;
  if FileExists(sFile) then
    LoadFromFile(sFile, Self)
end;

procedure TCRUDSettings.SaveToSettingsFile;
var
  oldThousandSeparator, oldDecimalSeparator: Char;
  sFile: string;
begin
  sFile := TfrmMain.OutputCRUDPath + cCRUDSettings_XML;

  //default XML floating point is US style
  oldThousandSeparator := FormatSettings.ThousandSeparator;
  oldDecimalSeparator  := FormatSettings.DecimalSeparator;
  FormatSettings.ThousandSeparator    := ',';
  FormatSettings.DecimalSeparator     := ',';
  try
    //remove readonly attribute
    if FileIsReadOnly(sFile) then
      FileSetReadOnly(sFile, false);

    SaveToFile(sFile, CRUDSettings);
  finally
    FormatSettings.ThousandSeparator := oldThousandSeparator;
    FormatSettings.DecimalSeparator  := oldDecimalSeparator;
  end;
end;

function TCRUDSettings.TableCount: Integer;
begin
  Result := Length(FTables);
end;

{ TCRUDTable }

function TCRUDTable.AddField: TCRUDField;
begin
  SetLength( FFields, length(FFields) + 1);
  Result := TCRUDField.Create;
  FFields[High(FFields)] := Result;
end;

function ConcatArrays(A1, A2: TCRUDFieldArray): TCRUDFieldArray;
var
  i: Integer;
begin
  SetLength( Result, High(A1) + High(A2) + 2 );
  for i := 0 to High(A1) do
    Result[i]:= A1[i];

  for i := 0 to High(A2) do
    Result[High(A1)+1+i]:= A2[i];
end;

procedure TCRUDTable.DeleteField(aField: TCRUDField);
var
  i, iFound: Integer;
  temparray: TCRUDFieldArray;
begin
  iFound := -1;
  for i := Low(FFields) to High(FFields) do
    if FFields[i] = aField then
    begin
      iFound := i;
      Break;
    end;

  if iFound < 0 then
    raise Exception.CreateFmt('Field "%s" not found in table "%s"',[aField.FieldName, Self.TableName]);

  temparray := ConcatArrays(
                 Copy(FFields, 0, iFound),
                 Copy(FFields, iFound+1, Length(FFields))
                 );
  FFields := temparray;
end;

function TCRUDTable.FieldCount: Integer;
begin
  Result := Length(FFields);
end;

function TCRUDTable.FindField(const aFieldName: string; const toevoegen : boolean) : TCRUDField;
var
  idxField : integer;
begin
  Result := nil;
  if aFieldName <> '' then
  begin
    for idxField := 0 to FieldCount - 1 do
    begin
      if SameText(Fields[idxField].FieldName, aFieldName) then
      begin
        Result := Fields[idxField];
        break;
      end;
    end;
    if (Result = nil) and toevoegen then
    begin
      Result           := AddField;
      Result.FieldName := aFieldName;
    end;
  end;
end;

function TCRUDTable.TableNameDelphi: string;
begin
   Result := DelphiName(TableName);
end;

{ TCRUDField }

procedure TCRUDField.AfterConstruction;
begin
  inherited;
  GenerateDirectJoin := True; //default
end;

function TCRUDField.FieldNameDelphi: string;
begin
   Result := DelphiName(FieldName);
end;

initialization
finalization
  FreeAndNil( _CRUDSettings );

end.
