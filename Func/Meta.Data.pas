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
unit Meta.Data;

interface

uses // Delphi
  Types;

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublished]) FIELDS([])}
  //!vcPublic is needed for attribute constructor to be visible!
  TMetaAttribute = class(TCustomAttribute)
  protected
    FRefCount: Integer;
  public
    procedure IncRef;
    procedure DecRef;
    property  RefCount: Integer read FRefCount;
  end;

  TBaseTableAttribute = class;
  TBaseTableAttributeClass = class of TBaseTableAttribute;

  TTableMeta = class(TMetaAttribute)
  private
    function GetTable: string; virtual;
  protected
    FDatabase,
    FTable: string;
  public
    constructor Create(const aTable: string; const aDBName: string = '');
    //todo: specific "group" in case multiple DB's or other types (excel etc)?
    destructor  Destroy; override;

    function  Clone: TTableMeta;
    procedure Assign(aSource: TTableMeta); virtual;

    property DBName: string read FDatabase write FDatabase;
    property Table : string read GetTable;
  end;

  TFunctionTableMeta = class(TTableMeta)
  private
    Parameters: array of Variant;
    function GetTable: string; override;
  public
    constructor Create(const aTable: string; aParameterCount: Integer; const aDBName: string = '');

    procedure SetParameter(const aValue: Variant; const Index: Integer);
  end;

  TBaseFieldMeta   = class(TMetaAttribute);

  TFieldType  = (
                  ftFieldUnknown,
                  ftFieldID,       //PK field (can be without autoinc!)
                  ftFieldString,
                  ftFieldBoolean,
                  ftFieldDouble,
                  ftFieldInteger,
                  ftFieldDateTime,
                  ftFieldCurrency
                );

  TKeyMetaField  = class(TBaseFieldMeta);
  TPKMetaField   = class(TKeyMetaField)
  private
    FIsAutoInc: boolean;
  public
    constructor Create(const aIsAutoInc: Boolean = True);
    property IsAutoInc: boolean read FIsAutoInc;
  end;

  TFKMetaField   = class(TKeyMetaField)
  private
    FFKTable: string;
    FFKField: string;
  public
    constructor Create(const aFKTable, aFKField: string);
    property FKTable: string read FFKTable; // write FFKTable;
    property FKField: string read FFKField; // write FFKField;
  end;

  TDefaultValueMeta = class(TBaseFieldMeta)
  private
    FDefaultValue: string;
  public
    constructor Create(const aDefaultValue: string);

    property DefaultValue: string read FDefaultValue;
  end;

  TBaseTableField = class;
  TBaseTableFieldClass = class of TBaseTableField;
  TFieldConstraintMeta = class(TBaseFieldMeta)
  private
    FFKField: TBaseTableAttribute;
    FTableField: TBaseTableAttribute;
    FValueConstraints: TStringDynArray;
  public
    constructor Create(const aTableField: TBaseTableAttribute; const aValueConstraints: TStringDynArray); overload;
    constructor Create(const aFKField, aTableField: TBaseTableAttribute; const aValueConstraints: TStringDynArray); overload;
    constructor Create(const aFKTable: TBaseTableAttributeClass;  const aFKField: TBaseTableFieldClass;
                       const aFKTable2: TBaseTableAttributeClass; const aFKField2: TBaseTableFieldClass;
                       const aValueConstraint: string); overload;
    destructor Destroy; override;

    function IsSameTableField(aTableField: TBaseTableAttribute): Boolean;
    function IsValidLocalValue(aValue: string): Boolean;
    procedure CheckLocalValue(aValue: string);

    property FKField: TBaseTableAttribute read FFKField;
    property TableField: TBaseTableAttribute read FTableField;
    property ValueConstraints: TStringDynArray read FValueConstraints;
  end;

  TTypedMetaField  = class(TBaseFieldMeta)
  private
    FFieldName    : string;
    FDisplayLabel : string;
    FFieldType    : TFieldType;
    FRequired: Boolean;
    FDefaultValue: TDefaultValueMeta;
    FTableAttribute: TBaseTableAttribute;
    FDisplayWidth: Integer;
    FEditFormat: string;
    FDisplayFormat: string;
    FEditMask: string;
    FMinValue: Double;
    FMaxValue: Double;
    FVisible: Boolean;
    procedure SetDisplayLabel(const Value: string);
    procedure SetDefaultValue(const Value: TDefaultValueMeta);
    procedure SetRequired(const Value: Boolean);
    procedure SetDisplayFormat(const Value: string);
    procedure SetDisplayWidth(const Value: Integer);
    procedure SetEditFormat(const Value: string);
    procedure SetEditMask(const Value: string);
    function  GetDisplayLabel: string;
    procedure SetMaxValue(const Value: Double);
    procedure SetMinValue(const Value: Double);
    procedure SetVisible(const Value: Boolean);
  public
    constructor Create(const aFieldName: string;
                       aFieldType: TFieldType;
                       aRequired: Boolean;
                       const aDisplayLabel: string;
                       //aStringSize: Integer = 0;
                       aMinValue: Double;
                       aMaxValue: Double;
                       const aDisplayFormat: string = '';
                       const aDisplayWidth: Integer = 0;
                       const aEditFormat: string = '';
                       const aEditMask: string = '';
                       const aVisible: Boolean = True
                       ); overload;
    //compatible with older metadata:
    constructor Create(const aFieldName: string;
                       aFieldType: TFieldType;
                       aRequired: Boolean;
                       const aDisplayLabel: string;
                       aMaxValue: Integer = 0); overload;
    destructor  Destroy; override;

    function  Clone: TTypedMetaField;
    procedure Assign(aSource: TTypedMetaField); virtual;

    property TableAttribute: TBaseTableAttribute read FTableAttribute write FTableAttribute;
    property DefaultValue : TDefaultValueMeta read FDefaultValue write SetDefaultValue;

    property FieldName    : string        read FFieldName;
    property DisplayLabel : string        read GetDisplayLabel write SetDisplayLabel;
    property FieldType    : TFieldType    read FFieldType;
    property Required     : Boolean       read FRequired write SetRequired;
    property MinValue     : Double        read FMinValue write SetMinValue;
    property MaxValue     : Double        read FMaxValue write SetMaxValue;
    property DisplayWidth : Integer       read FDisplayWidth write SetDisplayWidth;
    //floating point formats for data aware controls using FormatFloat: http://docwiki.embarcadero.com/Libraries/XE2/en/Data.DB.TNumericField.EditFormat
    property DisplayFormat: string        read FDisplayFormat write SetDisplayFormat;
    property EditFormat   : string        read FEditFormat write SetEditFormat;
    //generic editmask: http://docwiki.embarcadero.com/Libraries/XE5/en/Vcl.Mask.TCustomMaskEdit.EditMask
    property EditMask     : string        read FEditMask write SetEditMask;
    property Visible      : Boolean       read FVisible write SetVisible;
  end;

  TBaseTableField      = class(TObject);

  TBaseTableAttribute  = class(TMetaAttribute)
  private
    FConstraintMeta: TFieldConstraintMeta;
    procedure SetFieldMetaData(const Value: TTypedMetaField);
    procedure SetTableMetaData(const Value: TTableMeta);  //[RelatieStam(ID)]
  protected
    FField: TBaseTableFieldClass;
    FTableMetaData: TTableMeta;
    FFieldMetaData: TTypedMetaField;
    FKeyMetaData  : TKeyMetaField;
    FDefaultMeta  : TDefaultValueMeta;
  public
    constructor Create(const aField: TBaseTableFieldClass);
    procedure   AfterConstruction; override;
    destructor  Destroy; override;

    function  Clone: TBaseTableAttribute;
    procedure Assign(aSource: TBaseTableAttribute); virtual;

    property Field: TBaseTableFieldClass      read FField;
    property TableMetaData: TTableMeta        read FTableMetaData write SetTableMetaData;
    property FieldMetaData: TTypedMetaField   read FFieldMetaData write SetFieldMetaData;
    property KeyMetaData  : TKeyMetaField     read FKeyMetaData   write FKeyMetaData;
    property DefaultMeta  : TDefaultValueMeta read FDefaultMeta;

    property ConstraintMeta: TFieldConstraintMeta read FConstraintMeta write FConstraintMeta;
  end;

  TCustomTableAttribute  = class(TBaseTableAttribute)
  public
    destructor Destroy; override;
  end;

implementation

uses // Delphi
     RTTI, System.StrUtils, Variants, System.SysUtils, GlobalRTTI, Data.Base,
     // Shared
     UltraUtilsBasic;

{ TTableMeta }

procedure TTableMeta.Assign(aSource: TTableMeta);
begin
  Self.FDatabase := aSource.FDatabase;
  Self.FTable    := aSource.FTable;
end;

function TTableMeta.Clone: TTableMeta;
begin
  Result := Self.ClassType.Create as TTableMeta;
  Result.Assign(Self);
end;

constructor TTableMeta.Create(const aTable, aDBName: string);
begin
  FDatabase := aDBName;
  FTable    := aTable;
end;

destructor TTableMeta.Destroy;
begin
  inherited;
end;

function TTableMeta.GetTable: string;
begin
   Result := FTable;
end;

{ TTypedMetaField }

procedure TTypedMetaField.Assign(aSource: TTypedMetaField);
begin
  Self.TableAttribute := aSource.FTableAttribute;
  Self.DefaultValue   := aSource.FDefaultValue;

  Self.FFieldName      := aSource.FFieldName;
  Self.FDisplayLabel   := aSource.FDisplayLabel;
  Self.FFieldType      := aSource.FFieldType;
  Self.FRequired       := aSource.FRequired;
  Self.FMinValue       := aSource.FMinValue;
  Self.FMaxValue       := aSource.FMaxValue;
  Self.FVisible         := aSource.FVisible;
end;

function TTypedMetaField.Clone: TTypedMetaField;
begin
  Result := Self.ClassType.Create as TTypedMetaField;
  Result.Assign(Self);
end;

constructor TTypedMetaField.Create(const aFieldName: string;
  aFieldType: TFieldType; aRequired: Boolean; const aDisplayLabel: string;
  aMaxValue: Integer = 0);
begin
  Create(aFieldName, aFieldType, aRequired, aDisplayLabel, 0, aMaxValue);
end;

constructor TTypedMetaField.Create(const aFieldName: string;
  aFieldType: TFieldType; aRequired: Boolean; const aDisplayLabel: string;
  aMinValue: Double; aMaxValue: Double;
  const aDisplayFormat: string = ''; const aDisplayWidth: Integer = 0; const aEditFormat: string = '';
  const aEditMask: string = ''; const aVisible: Boolean = True);
begin
  FFieldName     := aFieldName;
  FFieldType     := aFieldType;
  FDisplayLabel  := aDisplayLabel;
  FRequired      := aRequired;
  FMinValue      := aMinValue;
  FMaxValue      := aMaxValue;

  FDisplayFormat := aDisplayFormat;
  FDisplayWidth  := aDisplayWidth;
  FEditFormat    := aEditFormat;
  FEditMask      := aEditMask;
  FVisible       := aVisible;
end;

destructor TTypedMetaField.Destroy;
begin
  inherited Destroy;
end;

function TTypedMetaField.GetDisplayLabel: string;
begin
   if (FDisplayLabel <> '') then
      Result := _(FDisplayLabel) // translate
   else
      Result := '';
end;

procedure TTypedMetaField.SetDefaultValue(const Value: TDefaultValueMeta);
begin
  if FDefaultValue = Value then Exit;
  if FDefaultValue <> nil then
    FDefaultValue.DecRef;

  FDefaultValue := Value;

  if FDefaultValue <> nil then
    FDefaultValue.IncRef;
end;

procedure TTypedMetaField.SetDisplayFormat(const Value: string);
begin
  FDisplayFormat := Value;
end;

procedure TTypedMetaField.SetDisplayLabel(const Value: string);
begin
  //todo: clone object (copy on write/change)
  FDisplayLabel := Value;
end;

procedure TTypedMetaField.SetDisplayWidth(const Value: Integer);
begin
  FDisplayWidth := Value;
end;

procedure TTypedMetaField.SetEditFormat(const Value: string);
begin
  FEditFormat := Value;
end;

procedure TTypedMetaField.SetEditMask(const Value: string);
begin
  FEditMask := Value;
end;

procedure TTypedMetaField.SetMaxValue(const Value: Double);
begin
  FMaxValue := Value;
end;

procedure TTypedMetaField.SetMinValue(const Value: Double);
begin
  FMinValue := Value;
end;

procedure TTypedMetaField.SetRequired(const Value: Boolean);
begin
  FRequired := Value;
end;

procedure TTypedMetaField.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
end;

{ TBaseTableAttribute }

procedure TBaseTableAttribute.AfterConstruction;
var
  t: TRttiType;
  aa: TArray<TCustomAttribute>;
  a: TCustomAttribute;
begin
  inherited;
  //table meta data
  t  := RTTICache.GetType(Self.ClassType);

  while Self.FTableMetaData = nil do
  begin
    aa := t.GetAttributes;
    for a in aa do
    begin
      //example:
      //meta:
      //  [TTableMeta('Tekst')]
      //  Tekst = class(TBaseTableAttribute)
      //  public
      //    constructor Create(const aField: TTekstFieldClass);
      //  end;
      //  [TTypedMetaField('ID', ftFieldID, True{required}, '')]  ID = class(TTekstField);
      //crud:
      //  [Tekst(ID)]  property  ID: TTypedTekst_IDField  index   0 read GetTypedTekst_IDField;
      if a is TFunctionTableMeta then
      begin
        Self.FTableMetaData := a as TFunctionTableMeta;        
        if Self.FTableMetaData.RefCount = 0 then
          Self.FTableMetaData.IncRef; //rtti ref
        Self.FTableMetaData.IncRef; //own ref
        Break;
      end
      else if a is TTableMeta then
      begin
        Self.FTableMetaData := a as TTableMeta;         //[TTableMeta('MainDB', 'RelatieStam')]
        if Self.FTableMetaData.RefCount = 0 then
          Self.FTableMetaData.IncRef; //rtti ref
        Self.FTableMetaData.IncRef; //own ref
        Break;
      end;
    end;
    if FTableMetaData = nil then
      t := t.AsInstance.BaseType;
    if t = nil then Break;
  end;

  //field meta
  if FField <> nil then
  begin
     t  := RTTICache.GetType(FField);
     aa := t.GetAttributes;
     for a in aa do
     begin
       if a is TTypedMetaField then
       begin
         Self.FFieldMetaData := a as TTypedMetaField;     //[TTypedMetaField('ID', ftFieldInteger, True{required}, 'ID')]
         if Self.FFieldMetaData.RefCount = 0 then
           Self.FFieldMetaData.IncRef; //rtti ref
         Self.FFieldMetaData.IncRef; //own ref

         FFieldMetaData.TableAttribute := Self; //back link for table name
         if FDefaultMeta <> nil then
           FFieldMetaData.DefaultValue := Self.FDefaultMeta;
       end
       else if a is TPKMetaField then
       begin
         Self.FKeyMetaData := a as TPKMetaField;     //[TPKMetaField]
         if Self.FKeyMetaData.RefCount = 0 then
           Self.FKeyMetaData.IncRef; //rtti ref
         Self.FKeyMetaData.IncRef; //own ref
       end
       else if a is TFKMetaField then
       begin
         Self.FKeyMetaData := a as TFKMetaField;     //[TFKMetaField(table,field)]
         if Self.FKeyMetaData.RefCount = 0 then
           Self.FKeyMetaData.IncRef; //rtti ref
         Self.FKeyMetaData.IncRef; //own ref
       end
       else if a is TDefaultValueMeta then
       begin
         Self.FDefaultMeta := a as TDefaultValueMeta;     //[TDefaultValueMeta('0')]
         if Self.FDefaultMeta.RefCount = 0 then
           Self.FDefaultMeta.IncRef; //rtti ref
         Self.FDefaultMeta.IncRef; //own ref

         if FFieldMetaData <> nil then
           FFieldMetaData.DefaultValue := Self.FDefaultMeta;
       end
       else if a is TFieldConstraintMeta then
       begin
         Self.FConstraintMeta := a as TFieldConstraintMeta;     //[StamSoortConstraint('Adres type')]
         if Self.FConstraintMeta.RefCount = 0 then
           Self.FConstraintMeta.IncRef; //rtti ref
         Self.FConstraintMeta.IncRef; //own ref
       end
       else
         raise EUltraException.CreateFmt('Unhandles attribute "%s"', [a.ClassName]);
     end;
  end;
end;

procedure TBaseTableAttribute.Assign(aSource: TBaseTableAttribute);
begin
  Self.FField         := aSource.FField;
  Self.TableMetaData  := aSource.FTableMetaData;
  Self.FieldMetaData  := aSource.FFieldMetaData;
  Self.FKeyMetaData   := aSource.FKeyMetaData;
  Self.FDefaultMeta   := aSource.FDefaultMeta;
  Self.ConstraintMeta := aSource.FConstraintMeta;
end;

function TBaseTableAttribute.Clone: TBaseTableAttribute;
begin
  Result := Self.ClassType.Create as TBaseTableAttribute;
  Result.Assign(Self);
end;

constructor TBaseTableAttribute.Create(const aField: TBaseTableFieldClass);
begin
  FField := aField;
end;

destructor TBaseTableAttribute.Destroy;
begin
  //note: owned by rtti, so no .DecRef here! (object are freed by rtti in DIFFERENT ORDER)
  //if FTableMetaData <> nil then FTableMetaData.DecRef;
  //if FFieldMetaData <> nil then FFieldMetaData.DecRef;
  //if FKeyMetaData <> nil   then FKeyMetaData.DecRef;
  //if FDefaultMeta <> nil then FDefaultMeta.DecRef;
  inherited Destroy;
end;

procedure TBaseTableAttribute.SetFieldMetaData(const Value: TTypedMetaField);
begin
  if FFieldMetaData = Value then Exit;
  if FFieldMetaData <> nil then
    FFieldMetaData.DecRef;

  FFieldMetaData := Value;

  if FFieldMetaData <> nil then
    FFieldMetaData.IncRef;
end;

procedure TBaseTableAttribute.SetTableMetaData(const Value: TTableMeta);
begin
  if FTableMetaData = Value then Exit;
  if FTableMetaData <> nil then
    FTableMetaData.DecRef;

  FTableMetaData := Value;

  if FTableMetaData <> nil then
    FTableMetaData.IncRef;
end;

{ TDefaultValueMeta }

constructor TDefaultValueMeta.Create(const aDefaultValue: string);
begin
  FDefaultValue := aDefaultValue;
end;

{ TMetaAttribute }

procedure TMetaAttribute.DecRef;
begin
  Dec(FRefCount);
  if FRefCount <= 0 then
    Self.Free;
end;

procedure TMetaAttribute.IncRef;
begin
  Inc(FRefCount);
end;

{ TCustomTableAttribute }

destructor TCustomTableAttribute.Destroy;
begin
  //we created this object, so safe to .DecRef here?
  if FTableMetaData <> nil then FTableMetaData.DecRef;
  if FFieldMetaData <> nil then FFieldMetaData.DecRef;
  if FKeyMetaData <> nil   then FKeyMetaData.DecRef;
  if FDefaultMeta <> nil then FDefaultMeta.DecRef;
  FTableMetaData := nil;
  FFieldMetaData := nil;
  FKeyMetaData   := nil;
  FDefaultMeta   := nil;

  inherited;
end;

{ TFieldConstraintMeta }

procedure TFieldConstraintMeta.CheckLocalValue(aValue: string);
begin
  if not IsValidLocalValue(aValue) then
    raise EDataException.Createfmt('Constraint error: "%s" is not allowed', [aValue]);
end;

constructor TFieldConstraintMeta.Create(const aTableField: TBaseTableAttribute;
  const aValueConstraints: TStringDynArray);
begin
  FTableField := aTableField;
  FValueConstraints := aValueConstraints;
end;

constructor TFieldConstraintMeta.Create(const aFKField,
  aTableField: TBaseTableAttribute; const aValueConstraints: TStringDynArray);
begin
  FFKField := aFKField;
  FTableField := aTableField;
  FValueConstraints := aValueConstraints;
end;

function TFieldConstraintMeta.IsSameTableField(
  aTableField: TBaseTableAttribute): Boolean;
begin
  Result := (aTableField.FTableMetaData = Self.FTableField.FTableMetaData);
end;

function TFieldConstraintMeta.IsValidLocalValue(aValue: string): Boolean;
begin
  Result := MatchText(aValue, Self.FValueConstraints);
end;

constructor TFieldConstraintMeta.Create(
  const aFKTable: TBaseTableAttributeClass;
  const aFKField: TBaseTableFieldClass;
  const aFKTable2: TBaseTableAttributeClass;
  const aFKField2: TBaseTableFieldClass; const aValueConstraint: string);
var
  fkattr, fkattr2: TBaseTableAttribute;
  sa: TStringDynArray;
begin
  fkattr  := aFKTable.Create(aFKField);
  fkattr2 := aFKTable2.Create(aFKField2);
  setLength(sa, 1);
  sa[0] := aValueConstraint;
  Create(fkattr, fkattr2, sa);
end;

destructor TFieldConstraintMeta.Destroy;
begin
  if (FFKField <> nil) and (FFKField.FRefCount = 0) then
    FFKField.Free;
  if (FTableField <> nil) and (FTableField.FRefCount = 0) then
    FTableField.Free;
  inherited;
end;

{ TFKMetaField }

constructor TFKMetaField.Create(const aFKTable, aFKField: string);
begin
  FFKTable := aFKTable;
  FFKField := aFKField;
end;

{ TFunctionTableMeta }

constructor TFunctionTableMeta.Create(const aTable: string; aParameterCount: Integer; const aDBName: string);
begin
   inherited Create(aTable, aDBName);
   SetLength(Parameters, aParameterCount);
end;

function TFunctionTableMeta.GetTable: string;
var i: Integer;
    parameter: Variant;
    parametersStr, parameterStr: string;
begin
   parametersStr := '';
   for i := 0 to Length(Parameters) -1 do
   begin
      parameter := Parameters[i];
      case VarType(parameter) of
         varString, varUString, varWord, varLongWord:
            parameterStr := QuotedStr(VarToStr(parameter));
         varDate:
            parameterStr := QryDateToStr(VarToDateTime(parameter));
         else
            parameterStr := VarToStr(parameter);
      end;
      if (parameterStr = '') then
         parameterStr := 'null';
      AddToCSVList(parameterStr, parametersStr)
   end;
   Result := FTable +'('+parametersStr+')';
end;

procedure TFunctionTableMeta.SetParameter(const aValue: Variant; const Index: Integer);
begin
   Parameters[Index] := aValue;
end;

{ TPKMetaField }

constructor TPKMetaField.Create(const aIsAutoInc: Boolean);
begin
  FIsAutoInc := aIsAutoInc;
end;

end.
