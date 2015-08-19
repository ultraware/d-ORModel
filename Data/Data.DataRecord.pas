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
unit Data.DataRecord;

interface

{$TYPEDADDRESS ON}

uses // Delphi
  Generics.Collections,
  Data.Base,
  Meta.Data, MultiEvent, SysUtils;

type
  TDataRecord = class;
  TDataRecordClass = class of TDataRecord;

  TBaseField = class;
  TBaseFieldClass = class of TBaseField;
  TFieldArray = array of TBaseField;
  TFieldList = class(TList<TBaseField>)
  public
    function GetFieldByName(const aFieldname: string): TBaseField;
  end;

//  TTypedIDField       = class;
  TBaseIDField        = class;
  TTypedStringField   = class;
  TTypedBooleanField  = class;
  TTypedDoubleField   = class;
  TTypedCurrencyField = class;
  TTypedIntegerField  = class;
  TTypedDateTimeField = class;

  TTypedDoubleCalcField  = class;
  TTypedIntegerCalcField = class;
  TTypedStringCalcField  = class;
  TTypedDateTimeCalcField = class;

  TNonQueryBooleanField = class;
  TNonQueryStringField  = class;
  TNonQueryDoubleField  = class;
  TNonQueryIntegerField  = class;
  TNonQueryDateTimeField  = class;
  TNonQueryDateField  = class;
  TNonQueryTimeField  = class;

  ISlotMaster = interface
    ['{BABF675A-108A-47C2-B7C2-0727E89EA6D1}']
    function RegisterListSlot: Integer;
    function RegisterSingleSlot: Integer;
    function ListSlotCount: Integer;
    function SingleSlotCount: Integer;
  end;

  TValidationRecord = record
    Field: TBaseField;
    Error: string;
    Error_ID:  Integer;
    procedure Clear;
    function HasError: Boolean;
  end;
  PValidationRecord = ^TValidationRecord;
  TValidationErrors = array of TValidationRecord;

  TFieldFilter = function(aField: TBaseField): Boolean of object;

  TFieldValueChangeEvent = procedure(aField: TBaseField; const aOldValue, aNewValue: Variant);

  //base list for fields, no data functions (usable for normal field lists)
  {$METHODINFO ON}  //otherwise compiler warnings with published properties
  TBaseDataRecord = class(TList<TBaseField>)
  protected
    FOwner: TObject;
  public
    function GetIDField      (aIndex: Integer): TBaseIDField;
    function GetBooleanField (aIndex: Integer): TTypedBooleanField;
    function GetDoubleField  (aIndex: Integer): TTypedDoubleField;
    function GetCurrencyField  (aIndex: Integer): TTypedCurrencyField;
    function GetIntegerField (aIndex: Integer): TTypedIntegerField;
    function GetDateTimeField(aIndex: Integer): TTypedDateTimeField;
    function GetStringField  (aIndex: Integer): TTypedStringField;

    function GetTypedDoubleCalcField (aIndex: integer): TTypedDoubleCalcField;//inline;
    function GetTypedIntegerCalcField(aIndex: integer): TTypedIntegerCalcField;//inline;
    function GetTypedStringCalcField (aIndex: integer): TTypedStringCalcField;
    function GetTypedDateTimeCalcField (aIndex: integer): TTypedDateTimeCalcField;

    function GetNonQueryDoubleField (aIndex: integer): TNonQueryDoubleField;//inline;
    function GetNonQueryIntegerField(aIndex: integer): TNonQueryIntegerField;//inline;
    function GetNonQueryStringField (aIndex: integer): TNonQueryStringField;
    function GetNonQueryDateTimeField (aIndex: integer): TNonQueryDateTimeField;
    function GetNonQueryDateField (aIndex: integer): TNonQueryDateField;
    function GetNonQueryTimeField (aIndex: integer): TNonQueryTimeField;
    function GetNonQueryBooleanField (aIndex: integer): TNonQueryBooleanField;

    constructor Create(aOwner: TObject = nil); virtual;
    procedure   AfterConstruction; override;
    destructor  Destroy; override;

    function FieldByName(const aFieldName: string; const aTablename: string = ''): TBaseField;
    function FieldByProperty(const aPropertyName: string): TBaseField;

    function  IsModified: Boolean;
    procedure UndoChanges;
    procedure ResetModifiedState;
    //
    function  IsValidField(aField: TBaseField; aValidationFilter: TFieldFilter = nil): Boolean;
    function  IsValid(aSkipEmptyFields: Boolean = false; aValidationFilter: TFieldFilter = nil): Boolean;
    function  GetFirstValidationError(aSkipEmptyFields: Boolean = false; aValidationFilter: TFieldFilter = nil): TValidationRecord;
    function  GetAllValidationErrors(aSkipEmptyFields: Boolean = false; aValidationFilter: TFieldFilter = nil): TValidationErrors;

    function GetFieldForID: TBaseIDField;
    procedure AssignValueOfSameTableFields(aSource: TBaseDataRecord);
  end;

  TBaseField = class
  private
    type TMultiValidationEvent = class(TMultiCastResult<TBaseField, string>);
    type TMultiChangeEvent = class(TMultiCast<TBaseField>);
  private
    FPropertyName: string;
    FMetaField: TBaseTableAttribute;
    FOnValidation: TMultiValidationEvent;
    FEditMaskFunction: TFunc<string>;
    FOnChange: TMultiChangeEvent;
    function GetRequired: Boolean;
    function GetDisplayLabel: String; virtual;
    function GetFieldName: String;
    function GetTableName: String;
    function GetDatabaseName: String;
    function GetOrigFieldValue: Variant;
    function GetOnValidation: TMultiValidationEvent;
    function GetDefaultValue: Variant;
    function GetTableClassName: String;
    procedure SetMetaField(const Value: TBaseTableAttribute);
    procedure SetDisplayLabel(const Value: String); virtual;
    procedure SetRequired(const Value: Boolean);
    function GetEditMask: string;
    procedure SetEditMask(const Value: string);
    function GetOrigFieldValueOrFieldValue: Variant;
    procedure SetDatbaseName(const Name: string);
    function GetDisplayFormat: string;
    function GetDisplayWidth: Integer;
    function GetEditFormat: string;
    procedure SetDisplayFormat(const Value: string);
    procedure SetDisplayWidth(const Value: Integer);
    procedure SetEditFormat(const Value: string);
    function GetDisplayText: string;
    function GetMaxValue: Double;
    function GetMinValue: Double;
    procedure SetMaxValue(const Value: Double);
    procedure SetMinValue(const Value: Double);
    function GetOnChange: TMultiChangeEvent;
    function GetIsAutoInc: Boolean;
    function GetVisible: Boolean;
    procedure SetVisible(const Value: Boolean);
  protected
    FDataRecord: TDataRecord;
    FPosition  : Integer;
    property  MetaField: TBaseTableAttribute read FMetaField write SetMetaField;
    function  GetFieldType: TFieldType;virtual;

    function  InternalGetFieldValueRecord: PFieldData; virtual;
    //
    function  GetFieldValue: Variant; virtual;
    procedure SetFieldValue(const Value: Variant);
    //
    function GetValueAsVariant: Variant;
    function GetValueAsInteger: Integer; virtual;
    function GetValueAsString: String; virtual;
    function GetValueAsDateTime: TDateTime; virtual;
    function GetValueAsDouble: Double; virtual;
    function GetValueAsCurrency: Currency; virtual;
    function GetValueAsBoolean: Boolean;
    function GetValueAsInt64: Int64; virtual;
    function GetValueAsDate: TDate; virtual;
    function GetValueAsTime: TTime; virtual;
    procedure SetValueAsVariant(const aValue: Variant);
    procedure SetValueAsInteger(const aValue: Integer);
    procedure SetNullableValueAsInteger(const aValue: Integer);
    procedure InternalSetValueAsInteger(const aValue: Integer; ZeroAsNull: Boolean);

    function GetValueOrEmptyString: string;
    function GetIsEmptyString: Boolean;
    function GetIntValueOrZero: Integer;
    function GetDoubleValueOrZero: Double;
    function GetCurrencyValueOrZero: Currency;

    procedure SetValueAsString(const aValue: String);
    procedure SetValueAsDateTime(const aValue: TDateTime);
    procedure SetValueAsDouble(const aValue: Double);
    procedure SetValueAsCurrency(const aValue: Currency);
    procedure SetValueAsBoolean(const aValue: Boolean);
    procedure SetValueAsInt64(const aValue: Int64);
    procedure SetValueAsDate(const Value: TDate);
    procedure SetValueAsTime(const Value: TTime);
  protected
    constructor Create(const aPropertyName, TableName: string; aFieldType: TFieldType); overload; virtual;
    function InternalValidationText: string; virtual;
    property ValueOrEmptyString: string read GetValueOrEmptyString;
    property IsEmptyString: Boolean read GetIsEmptyString;
  public
    constructor Create(const aPropertyName: string; aDataRecord: TDataRecord; aPosition: Integer; aMetaField: TBaseTableAttribute); overload; virtual;
    constructor Create(const aPropertyName: string; aMetaField: TBaseTableAttribute);overload; virtual;
    constructor Create(const aPropertyName: string; aFieldType: TFieldType); overload; virtual;
    constructor Create();overload; virtual;
    destructor  Destroy; override;

    property DataRecord: TDataRecord read FDataRecord;  //owner
    property Position  : Integer     read FPosition;    //index in TDataRecord list

    procedure Clear2Empty;
    procedure Clear2Null;

    function IsEmpty: Boolean; virtual;        //empty = not loaded from db
    function IsNull: Boolean; virtual;         //null  = load from db, but db contains null
    function IsEmptyOrNull: Boolean;
    function NotEmptyOrNull: Boolean;
    //
    function  IsModified: Boolean;virtual;
    procedure UndoChange;
    procedure ResetModifiedState;
    procedure CopyFieldValue(FromField: TBaseField);
    function  HasSameValue(CompareField: TBaseField): Boolean;

    procedure LoadValue(const aValue: Variant);
    property  OrigFieldValue: Variant read GetOrigFieldValue;
    property  OrigFieldValueOrFieldValue: Variant read GetOrigFieldValueOrFieldValue;

    property DatabaseTypeName : String  read GetDatabaseName write SetDatbaseName;
    //
    property TableName    : String  read GetTableName;
    property TableClassName: String read GetTableClassName;
    property FieldName    : String  read GetFieldName;
    property PropertyName : string  read FPropertyName;
    procedure SetTableParameter(const aValue: Variant; const Index: Integer); overload;
    //
    property DisplayLabel : String     read GetDisplayLabel  write SetDisplayLabel;
    property IsRequired   : Boolean    read GetRequired      write SetRequired;
    property IsAutoInc    : Boolean    read GetIsAutoInc;
    property FieldType    : TFieldType read GetFieldType;
    property MinValue     : Double     read GetMinValue write SetMinValue;
    property MaxValue     : Double     read GetMaxValue write SetMaxValue;
    property DisplayWidth : Integer    read GetDisplayWidth  write SetDisplayWidth;
    //floating point formats for data aware controls using FormatFloat: http://docwiki.embarcadero.com/Libraries/XE2/en/Data.DB.TNumericField.EditFormat
    property DisplayFormat: string     read GetDisplayFormat write SetDisplayFormat;
    property DisplayText  : string     read GetDisplayText;
    property EditFormat   : string     read GetEditFormat    write SetEditFormat;
    //generic editmask: http://docwiki.embarcadero.com/Libraries/XE5/en/Vcl.Mask.TCustomMaskEdit.EditMask
    property EditMask: string          read GetEditMask      write SetEditMask;
    property Visible: Boolean          read GetVisible       write SetVisible;
    //can depend on other data....
    property EditMaskFunction: TFunc<string> read FEditMaskFunction write FEditMaskFunction;
    //
    function HasDefaultValue: Boolean;
    property DefaultValue: Variant read GetDefaultValue;

    property ValueAsVariant : Variant   read GetValueAsVariant  write SetValueAsVariant;
    property ValueAsInteger : Integer   read GetValueAsInteger  ;//write SetValueAsInteger;
    property ValueAsInt64   : Int64     read GetValueAsInt64    ;//write SetValueAsInt64;
    property ValueAsString  : String    read GetValueAsString   ;//write SetValueAsString;
    property ValueAsDouble  : Double    read GetValueAsDouble   ;//write SetValueAsDouble;
    property ValueAsCurrency: Currency  read GetValueAsCurrency ;//write SetValueAsCurrency;
    property ValueAsDateTime: TDateTime read GetValueAsDateTime ;//write SetValueAsDateTime;
    property ValueAsBoolean : Boolean   read GetValueAsBoolean  ;//write SetValueAsBoolean;
    property ValueAsDate    : TDate     read GetValueAsDate     ;//write SetValueAsDate;
    property ValueAsTime    : TTime     read GetValueAsTime     ;//write SetValueAsTime;

    function IsValid: Boolean;
    property OnValidation: TMultiValidationEvent read GetOnValidation;
    function GetValidationErrorText: string;

    //function HasOnChangeEvents: boolean;
    property OnChange: TMultiChangeEvent read GetOnChange;

    function ToString: string; override;
  end;

  TCustomField = class(TBaseField)
  public
    property ValueAsVariant : Variant   read GetValueAsVariant  write SetValueAsVariant;
    property ValueAsInteger : Integer   read GetValueAsInteger  write SetValueAsInteger;
    property ValueAsInt64   : Int64     read GetValueAsInt64    write SetValueAsInt64;
    property ValueAsString  : String    read GetValueAsString   write SetValueAsString;
    property ValueAsDouble  : Double    read GetValueAsDouble   write SetValueAsDouble;
    property ValueAsCurrency: Currency  read GetValueAsCurrency write SetValueAsCurrency;
    property ValueAsDateTime: TDateTime read GetValueAsDateTime write SetValueAsDateTime;
    property ValueAsBoolean : Boolean   read GetValueAsBoolean  write SetValueAsBoolean;
    property ValueAsDate    : TDate     read GetValueAsDate     write SetValueAsDate;
    property ValueAsTime    : TTime     read GetValueAsTime     write SetValueAsTime;
  end;

  TNonQueryField = class(TCustomField)
  private
     FFieldType: TFieldType;
     FDisplayLabel: string;
     function  GetDisplayLabel: string; override; final;
     procedure SetDisplayLabel(const Value: string); override; final;
  protected
     function GetFieldType: TFieldType; override;
  public
      constructor Create(const aPropertyName: string; aDataRecord: TDataRecord; aPosition: Integer; aMetaField: TBaseTableAttribute); override;
      property DisplayLabel : String  read FDisplayLabel write FDisplayLabel;
  end;

  //--------------------------------------------------------------------

  //real datarecord, including data
  TDataRecord = class(TBaseDataRecord)
  private
    function GetField(aIndex: Integer): TCustomField;
    function GetOnChange: TBaseField.TMultiChangeEvent;
  protected
    FOwnData: TRowData;
    FRecordData: PRowData;
    FUpdateCount: Integer;
    //FPendingUpdates: Integer;
    FOnChange: TBaseField.TMultiChangeEvent;
    function  GetRecordData: PRowData;
    procedure CreateFieldsByRTTI;
    procedure LoadSharedData(aSingleRecord: TDataRecord);virtual;  //used to clone/share data with same BO object

    function GetTypedField<T: TBaseField>(aIndex: Integer): T; inline;

    procedure Notify(const Item: TBaseField; Action: TCollectionNotification); override; // dit gaat niet goed
  public
    class procedure CreateFieldsByRTTIForObject(const aObject: TObject; aDestination: TDataRecord);
    class function  ObjectHasFieldsByRTTI(const aObject: TObject): boolean;
  public
    constructor CreateWithData(aRowData: PRowData); virtual;
    procedure   AfterConstruction; override; //must always be executed, regardless which Create function is used

    procedure AllocFieldValues;
    procedure LoadRecordData(aRowData: PRowData);virtual;  //load data from a list (crud, bo list, etc))

    procedure BeginUpdate;
    procedure EndUpdate;
    procedure DoOnChangeEvents;

    //function HasOnChangeEvents: boolean;
    property OnChange: TBaseField.TMultiChangeEvent read GetOnChange;

    procedure Clear2Empty;virtual;
    procedure Clear2Null;virtual;
    procedure Clear2EmptyOrDefault;

    property Fields[aIndex: Integer]: TCustomField read GetField;
  end;

  TJoinableDataRecord = class(TDataRecord)
  protected
    FChildData: TList<TJoinableDataRecord>;
    procedure AddChildData(aChildDataRecord: TJoinableDataRecord);
  public
    ExternalJoinField, OwnJoinField: TCustomField;
    destructor Destroy; override;

    procedure Clear2Empty; override;
    procedure Clear2Null; override;
  end;

  TMultiDataRecordClass = class of TMultiDataRecord;
  TMultiDataRecord = class(TDataRecord)
  protected
    FOwnMultiRecordData: TMultiRowData;
    FMultiRecordData: PMultiRowData;

    function RegisterSingleSlot: Integer;
    function RegisterListSlot: Integer;
    function SingleSlotCount: Integer;
    function ListSlotCount: Integer;

    procedure LoadSharedData(aSingleRecord: TDataRecord);override;   //used to clone/share data with same BO object
  public
    constructor CreateWithData(aRowData: PMultiRowData); reintroduce; virtual;
    procedure   AfterConstruction; override; //must always be executed, regardless which Create function is used

    procedure LoadRecordData(aRowData: PRowData);override;           //load data from a list (crud, bo list, etc))
    procedure LoadMultiRecordData(aRowData: PMultiRowData);virtual;  //load data from a list (crud, bo list, etc))

    procedure Clear2Empty;override;
    procedure Clear2Null;override;
  end;

  //--------------------------------------------------------------------

  TNonQueryBooleanField = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedBoolean: Boolean read GetValueAsBoolean write SetValueAsBoolean;
  end;

  TNonQueryStringField  = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedString: string read GetValueAsString write SetValueAsString;
    property ValueOrEmptyString;
  end;

  TNonQueryDoubleField  = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedDouble: Double read GetValueAsDouble write SetValueAsDouble;
  end;

  TNonQueryIntegerField  = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedInteger: Integer read GetValueAsInteger write SetValueAsInteger;
    property ValueOrZero: Integer read GetIntValueOrZero;
  end;

  TNonQueryDateTimeField  = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedDateTime: TDateTime read GetValueAsDateTime write SetValueAsDateTime;
  end;

  TNonQueryTimeField = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedTime: TTime read GetValueAsTime write SetValueAsTime;
  end;

  TNonQueryDateField = class(TNonQueryField)
  protected
    function GetFieldType: TFieldType; override;
  public
    property TypedDate: TDate read GetValueAsDate write SetValueAsDate;
  end;

  TTypedBooleanField = class(TCustomField)
  public
    constructor Create(const aPropertyName: string);overload; virtual;

    property TypedBoolean: Boolean read GetValueAsBoolean write SetValueAsBoolean;
  end;

  TTypedStringField  = class(TCustomField)
  private
    FOnFormatField: TFunc<string, string>;
    procedure SetValueAsString(const aValue: String); overload;
  public
    constructor Create(const aPropertyName: string = ''; const StringSize: Integer = 0);overload; virtual;

    property OnFormatField: TFunc<string, string> read FOnFormatField write FOnFormatField;
    property TypedString: string read GetValueAsString write SetValueAsString;
    property ValueOrEmptyString;
    property IsEmptyString;
    function StringSize: Integer;
  end;

  TTypedDoubleField  = class(TCustomField)
  public
    constructor Create(const aPropertyName: string);overload; virtual;

    property TypedDouble: Double read GetValueAsDouble write SetValueAsDouble;
    property ValueOrZero: Double read GetDoubleValueOrZero;
  end;

  TTypedCurrencyField  = class(TCustomField)
  public
    constructor Create(const aPropertyName: string = '');overload; virtual;

    property TypedCurrency: Currency read GetValueAsCurrency write SetValueAsCurrency;
    property ValueOrZero: Currency read GetCurrencyValueOrZero;
  end;

  TTypedIntegerField  = class(TCustomField)
  public
    constructor Create(const aPropertyName: string = '');overload; virtual;

    property TypedInteger: Integer read GetValueAsInteger write SetValueAsInteger;

    property NullableInteger: Integer write SetNullableValueAsInteger;
    property ValueOrZero: Integer read GetIntValueOrZero;
  end;

  TTypedDateTimeField  = class(TCustomField)
  public
    constructor Create(const aPropertyName: string = '');overload; virtual;

    property TypedDateTime: TDateTime read GetValueAsDateTime write SetValueAsDateTime;
  end;

  TTypedDateField  = class(TCustomField)
  public
    constructor Create(const aPropertyName: string = '');overload; virtual;

    property TypedDate: TDate read GetValueAsDate write SetValueAsDate;
  end;

  TTypedTimeField  = class(TCustomField)
  public
    constructor Create(const aPropertyName: string = '');overload; virtual;

    property TypedTime: TTime read GetValueAsTime write SetValueAsTime;
  end;

  //------------------------------------

  TBaseIDField = class(TCustomField)
  private
    function GetTypedIDValue: Int64;
    procedure SetTypedIDValue(const Value: Int64);
  public
    constructor Create(const aPropertyName, TableName: string; aFieldType: TFieldType); override;
    property ValueOrZero: Integer read GetIntValueOrZero;
    property TypedIDValue: Int64 read GetTypedIDValue; //no write! must do via "SetTypedID" below!
    property UnsafeTypedIDValue: Int64 read GetTypedIDValue write SetTypedIDValue;
  end;

  {$RTTI EXPLICIT METHODS([vcPublished]) PROPERTIES([vcPublished]) FIELDS([vcPublished, vcPublic]) }   // make visible for RTTI
  //!vcPublic fields is needed to be able to check if ID field is present!
  TBaseIDValue = record
    ID: Int64;
//    ID: T;
    class function Get(aValue: Int64): TBaseIDValue; overload;static;
    class function Get<T: record>(aValue: Int64): T; overload;static;
//    class function Get(aValue: T): TBaseIDValue<T>; overload;static;
//    class function Get(aValue: TBaseIDValue<T>): T; overload;static;
    function  IsEmpty: Boolean;
    procedure Empty;
  end;
  PBaseIDValue = ^TBaseIDValue;

  TCustomIDField<T: record> = class(TBaseIDField)
  private
    function  GetTypedID: T;
    procedure SetTypedID(const aValue: T);
  public
    class constructor Create;
    property TypedID: T read GetTypedID write SetTypedID;
  end;

  //------------------------------------
  TCustomCalculatedField = class(TCustomField)
  protected
    function InternalGetFieldValueRecord: PFieldData; override;

    function GetValueAsInt64    : Int64; override;
    function GetValueAsString   : string; override;
    function GetValueAsInteger  : integer; override;
    function GetValueAsDouble   : Double; override;
    function GetValueAsDateTime : TDateTime; override;
    function GetFieldValue      : Variant; override;
  public
    function IsEmpty: boolean; override;
    function IsNull: boolean; override;
    function IsModified: Boolean;override;

    property FieldValue: Variant read GetFieldValue; // no write of calc fields!    write SetFieldValue;
  end;

  TIntegerCalcEvent = reference to function(aRow: TDataRecord): Integer;
  TTypedIntegerCalcField = class(TCustomCalculatedField)
  private
    FOnCalcValue: TIntegerCalcEvent;
    procedure SetOnCalcValue(const Value: TIntegerCalcEvent);
  protected
    function  GetFieldType: TFieldType; override;
    function  GetFieldValue: Variant; override;
  public
    procedure AfterConstruction;override;

    function  IsEmpty: boolean;override;
    function  IsNull: boolean; override;

    property  TypedInteger : Integer read GetValueAsInteger;
    property  OnCalcValue: TIntegerCalcEvent read FOnCalcValue write SetOnCalcValue;
  end;

  TDoubleCalcEvent = reference to function(aRow: TDataRecord): Double;
  TTypedDoubleCalcField = class(TCustomCalculatedField)
  private
    FOnCalcValue: TDoubleCalcEvent;
    procedure SetOnCalcValue(const Value: TDoubleCalcEvent);
  protected
    function  GetFieldType: TFieldType; override;
    function  GetFieldValue: Variant; override;
  public
    procedure AfterConstruction;override;

    function  IsEmpty: boolean;override;
    function  IsNull: boolean; override;

    property  TypedDouble: Double read GetValueAsDouble;
    property  OnCalcValue: TDoubleCalcEvent read FOnCalcValue write SetOnCalcValue;
  end;

  TStringCalcEvent = reference to function(aRow: TDataRecord): String;
  TTypedStringCalcField = class(TCustomCalculatedField)
  private
    FOnCalcValue: TStringCalcEvent;
    procedure SetOnCalcValue(const Value: TStringCalcEvent);
  protected
    function  GetFieldType: TFieldType; override;
    function  GetFieldValue: Variant; override;
  public
    procedure AfterConstruction;override;

    function  IsEmpty: boolean;override;
    function  IsNull: boolean; override;

    property  TypedString: string read GetValueAsString;
    property  OnCalcValue: TStringCalcEvent read FOnCalcValue write SetOnCalcValue;
  end;

  TDateTimeCalcEvent = reference to function(aRow: TDataRecord): TDateTime;
  TTypedDateTimeCalcField = class(TCustomCalculatedField)
  private
    FOnCalcValue: TDateTimeCalcEvent;
    procedure SetOnCalcValue(const Value: TDateTimeCalcEvent);
  protected
    function  GetFieldType: TFieldType; override;
    function  GetFieldValue: Variant; override;
  public
    procedure AfterConstruction;override;

    function  IsEmpty: boolean;override;
    function  IsNull: boolean; override;

    property  TypedDateTime: TDateTime read GetValueAsDateTime;
    property  OnCalcValue: TDateTimeCalcEvent read FOnCalcValue write SetOnCalcValue;
  end;

  //-----------Shared CustomFields-------------------------

  TRegisteredCustomFields = class
  private
    class var FList: TList<TBaseFieldClass>;
    class function List: TList<TBaseFieldClass>;
    class function GetItem(aIndex: Integer): TBaseFieldClass; static;
  public
    class constructor Create;
    class destructor  Destroy;

    class procedure RegisterCustomField(aFieldClass: TBaseFieldClass);
    class function  Count: Integer;
    class property  Item[aIndex: Integer]: TBaseFieldClass read GetItem;
  end;

  TTypedURIField  = class(TTypedStringField);
  TTypedTextField  = class(TTypedStringField);
  TTypedPercentageField = class(TTypedDoubleField);

  TUltraBooleanField = class(TCustomField)
  protected
    function  GetFieldType: TFieldType; override;
    function  GetIntValueAsBoolean: Boolean;
    procedure SetIntValueAsBoolean(const aValue: Boolean);
  public
    property TypedBoolean: Boolean read GetIntValueAsBoolean write SetIntValueAsBoolean;
  end;

  //------------------------------------

//  procedure AppendBOerror(ErrorText: string; var aValidationArray: TValidationErrors; Error_ID: Integer = 0);
  procedure AppendValidationArray(var left: TValidationErrors; const right: TValidationErrors);
  function  AppendValidationError(var aValidationArray: TValidationErrors): PValidationRecord;
//  function ExecuteCheck(Count: Integer; aValidationArray: TValidationErrors): Boolean;
//  function ContainsError_ID(aValidationArray: TValidationErrors; Error_ID: Integer): Boolean;

  procedure AddFieldToArray(const aField: TBaseField; var aArray: TFieldArray; const Unique: Boolean = False);
  procedure AddFieldsToArray(const aFieldArray: array of TBaseField; var aArray: TFieldArray; const Unique: Boolean = False);

implementation

uses // Delphi
     RTTI, TypInfo, GlobalRTTI, Variants, System.DateUtils,
     Math, System.StrUtils,
     // Shared
     UltraUtilsBasic;

procedure AddFieldsToArray(const aFieldArray: array of TBaseField; var aArray: TFieldArray; const Unique: Boolean = False);
var Field: TBaseField;
begin
   for Field in aFieldArray do
      AddFieldToArray(Field, aArray, Unique);
end;

procedure AddFieldToArray(const aField: TBaseField; var aArray: TFieldArray; const Unique: Boolean = False);

   function FieldIn: Boolean;
   var Field2: TBaseField;
   begin
      Result := False;
      for Field2 in aArray do
      begin
         if (aField = Field2) then
            Exit(True);
      end;
   end;

var Index: Integer;
begin
  if (not (Unique and FieldIn)) then
  begin
    Index := Length(aArray);
    SetLength(aArray, (Index + 1));
    aArray[Index] := aField;
  end;
end;

function AppendValidationError(var aValidationArray: TValidationErrors): PValidationRecord;
begin
  SetLength(aValidationArray, Length(aValidationArray)+1);
  Result := @aValidationArray[High(aValidationArray)];
end;

procedure AppendValidationArray(var left: TValidationErrors; const right: TValidationErrors);
var istart, ibo, ipos: Integer;
begin
   istart := Length(left);
   ibo    := 0;
   SetLength(left, Length(left) + Length(right));
   for ipos := istart to High(left) do
   begin
      left[ipos] := right[ibo];
      Inc(ibo);
   end;
end;


{ TBaseDataRecord }

procedure TBaseDataRecord.AfterConstruction;
begin
  inherited;
end;

procedure TBaseDataRecord.AssignValueOfSameTableFields(aSource: TBaseDataRecord);
var
  fdest, fsource: TBaseField;
  i: Integer;
begin
   for fsource in aSource do
   begin
      for i := 0 to Self.Count - 1 do
      begin
         fdest := Self.Items[i];
         if (fsource.FieldName = fdest.FieldName) and (fsource.TableName = fdest.TableName) then
         begin
            // fast copy complete record values
            fdest.InternalGetFieldValueRecord^ := fsource.InternalGetFieldValueRecord^;
         end;
      end;
   end;
end;

constructor TBaseDataRecord.Create(aOwner: TObject = nil);
begin
   FOwner := aOwner;
   inherited Create; //(True{owns});
end;

destructor TBaseDataRecord.Destroy;
var f: TBaseField;
begin
   for f in Self do
   begin
      if f.FDataRecord = Self then // only free when we are owner
         f.Free;
   end;
   Self.Clear;
   inherited;
end;

function TBaseDataRecord.FieldByName(const aFieldName: string; const aTablename: string = ''): TBaseField;
var f: TBaseField;
begin
   Result := nil;
   for f in Self do
   begin
      if SameText(aFieldName, f.FieldName) and ((aTablename = '') or SameText(aTablename, f.TableName)) then
         Exit(f);
   end;
end;

function TBaseDataRecord.FieldByProperty(const aPropertyName: string): TBaseField;
var f: TBaseField;
begin
   Result := nil;
   for f in Self do
   begin
      if SameText(aPropertyName, f.PropertyName) then
         Exit(f);
   end;
end;

function TBaseDataRecord.IsModified: Boolean;
var
  f: TBaseField;
begin
   Result := false;
   for f in Self do
   begin
      if f.IsModified then
         Exit(True);
   end;
end;

function TBaseDataRecord.IsValid(aSkipEmptyFields: Boolean = false; aValidationFilter: TFieldFilter = nil): Boolean;
var
  f: TBaseField;
begin
   Result := True;
   for f in Self do
   begin
      if aSkipEmptyFields and f.IsEmpty then
         Continue;

      if (not IsValidField(f, aValidationFilter)) then
         Exit(False);
   end;
end;

function TBaseDataRecord.IsValidField(aField: TBaseField; aValidationFilter: TFieldFilter): Boolean;
begin
   // Field is valid or field is filtered from validation errors
   Result := aField.IsValid or (Assigned(aValidationFilter) and  aValidationFilter(aField));
end;

function TBaseDataRecord.GetFieldForID: TBaseIDField;
//find PK/indentity field
var
  i: Integer;
  f: TBaseField;
begin
  Result := nil;  //default nil: each table needs a PK! otherwise no ID veld which we need for updates

  for i := 0 to Self.Count - 1 do
  begin
    f := Items[i];
    if (f.FieldType = ftFieldID) then
    begin
      //default nog niet ingevuld, deze later expliciet testen? dus moet én ID field én PK zijn?
      //want met deze extra info weten we of het een autoinc ID of handmatige PK field is
      if (f.MetaField.KeyMetaData is TPKMetaField) then
        Exit(f as TBaseIDField)
      //vooralsnog is ftFieldID = ID field is goed genoeg, dit is ook backwards compatible (dit werd al gedaan)
      else
        Exit(f as TBaseIDField);
    end;
  end;
end;

function TBaseDataRecord.GetFirstValidationError(aSkipEmptyFields: Boolean; aValidationFilter: TFieldFilter): TValidationRecord;
var
  f: TBaseField;
begin
   Result.Clear;
   for f in Self do
   begin
      if aSkipEmptyFields and f.IsEmpty then
         Continue;

      if (not IsValidField(f, aValidationFilter)) then
      begin
         Result.Field := f;
         Result.Error := f.GetValidationErrorText;
         Exit;
      end;
   end;
end;

procedure TBaseDataRecord.ResetModifiedState;
var
  f: TBaseField;
begin
   for f in Self do
   begin
      if (not(f is TCustomCalculatedField)) and f.IsModified then
         f.ResetModifiedState;
   end;
end;

procedure TBaseDataRecord.UndoChanges;
var
  f: TBaseField;
begin
   for f in Self do
   begin
      if f.IsModified then
         f.UndoChange;
   end;
end;

function TBaseDataRecord.GetStringField(aIndex: Integer): TTypedStringField;
begin
   Result := Self.Items[aIndex] as TTypedStringField;
end;

function TBaseDataRecord.GetTypedDoubleCalcField(aIndex: integer): TTypedDoubleCalcField;
begin
   Result := Self.Items[aIndex] as TTypedDoubleCalcField;
end;

function TBaseDataRecord.GetTypedIntegerCalcField(aIndex: integer): TTypedIntegerCalcField;
begin
   Result := Self.Items[aIndex] as TTypedIntegerCalcField;
end;

function TBaseDataRecord.GetTypedStringCalcField(aIndex: integer): TTypedStringCalcField;
begin
   Result := Self.Items[aIndex] as TTypedStringCalcField;
end;

function TBaseDataRecord.GetTypedDateTimeCalcField(aIndex: integer): TTypedDateTimeCalcField;
begin
   Result := Self.Items[aIndex] as TTypedDateTimeCalcField;
end;

function TBaseDataRecord.GetAllValidationErrors(aSkipEmptyFields: Boolean; aValidationFilter: TFieldFilter): TValidationErrors;
var
  f: TBaseField;
  error: PValidationRecord;
begin
  Result := nil;
   for f in Self do
   begin
      if aSkipEmptyFields and f.IsEmpty then
         Continue;

      if (not IsValidField(f, aValidationFilter)) then
      begin
         Error := AppendValidationError(Result);
         Error.Field := f;
         Error.Error := f.GetValidationErrorText;
      end;
   end;
end;

function TBaseDataRecord.GetBooleanField(aIndex: Integer): TTypedBooleanField;
begin
  Result := Self.Items[aIndex] as TTypedBooleanField;
end;

function TBaseDataRecord.GetCurrencyField(aIndex: Integer): TTypedCurrencyField;
begin
  Result := Self.Items[aIndex] as TTypedCurrencyField;
end;

function TBaseDataRecord.GetDateTimeField(aIndex: Integer): TTypedDateTimeField;
begin
  Result := Self.Items[aIndex] as TTypedDateTimeField;
end;

function TBaseDataRecord.GetDoubleField(aIndex: Integer): TTypedDoubleField;
begin
  Result := Self.Items[aIndex] as TTypedDoubleField;
end;

function TBaseDataRecord.GetIDField(aIndex: Integer): TBaseIDField;
begin
  Result := Self.Items[aIndex] as TBaseIDField;
end;

function TBaseDataRecord.GetIntegerField(aIndex: Integer): TTypedIntegerField;
begin
  Result := Self.Items[aIndex] as TTypedIntegerField;
end;

function TBaseDataRecord.GetNonQueryDateField(aIndex: integer): TNonQueryDateField;
begin
   Result := Self.Items[aIndex] as TNonQueryDateField;
end;

function TBaseDataRecord.GetNonQueryDateTimeField(aIndex: integer): TNonQueryDateTimeField;
begin
   Result := Self.Items[aIndex] as TNonQueryDateTimeField;
end;

function TBaseDataRecord.GetNonQueryBooleanField (aIndex: integer): TNonQueryBooleanField;
begin
   Result := Self.Items[aIndex] as TNonQueryBooleanField;
end;

function TBaseDataRecord.GetNonQueryDoubleField(aIndex: integer): TNonQueryDoubleField;
begin
   Result := Self.Items[aIndex] as TNonQueryDoubleField;
end;

function TBaseDataRecord.GetNonQueryIntegerField(aIndex: integer): TNonQueryIntegerField;
begin
   Result := Self.Items[aIndex] as TNonQueryIntegerField;
end;

function TBaseDataRecord.GetNonQueryStringField(aIndex: integer): TNonQueryStringField;
begin
   Result := Self.Items[aIndex] as TNonQueryStringField;
end;

function TBaseDataRecord.GetNonQueryTimeField(aIndex: integer): TNonQueryTimeField;
begin
   Result := Self.Items[aIndex] as TNonQueryTimeField;
end;

{ TDataRecord }

procedure TDataRecord.AfterConstruction;
begin
   inherited AfterConstruction;
   CreateFieldsByRTTI;

   // standalone datarecord/model should be possible!
   if FRecordData = nil then
   begin
      AllocFieldValues;
   end;
end;

procedure TDataRecord.AllocFieldValues;
begin
   if FRecordData = nil then
   begin
      // standalone datarecord/model should be possible!
      FOwnData.FieldValues := AllocFieldValueArray(Self.Count);
      FRecordData := @FOwnData;
   end
   else
      FRecordData.FieldValues := AllocFieldValueArray(Self.Count);
end;

procedure TDataRecord.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TDataRecord.Clear2Empty;
var f: TBaseField;
begin
   Assert(FRecordData <> nil);
   for f in Self do
      f.Clear2Empty;
end;

procedure TDataRecord.Clear2EmptyOrDefault;
var f: TBaseField;
begin
   Clear2Empty;
   for f in Self do
   begin
      if f.HasDefaultValue then
      begin
         if not StartsText('@', f.DefaultValue) and // @getdate() op server uitvoeren, niet letterlijk als text invullen!
            not EndsText(')', f.DefaultValue) // @getdate() op server uitvoeren, niet letterlijk als text invullen!
         then
            f.LoadValue(f.DefaultValue);
      end;
   end;
end;

procedure TDataRecord.Clear2Null;
var f: TBaseField;
begin
   Assert(FRecordData <> nil);
   for f in Self do
    f .Clear2Null;
end;

procedure TDataRecord.CreateFieldsByRTTI;
begin
   CreateFieldsByRTTIForObject(Self, Self);
end;

class procedure TDataRecord.CreateFieldsByRTTIForObject(const aObject: TObject; aDestination: TDataRecord);
var
  t: TRttiType;
  pa: TArray<TRttiProperty>;
  p: TRttiProperty;
  f: TBaseField;
  ip: TRttiInstanceProperty;
  typeinfo: PTypeInfo;
  classtype: TClass;
  aa: TArray<TCustomAttribute>;
  a: TCustomAttribute;
  fieldmeta: TTypedMetaField;
  tablefieldmeta: TBaseTableAttribute;
  defaultmeta: TDefaultValueMeta;
  fieldconstraint: TFieldConstraintMeta;
  pkmeta: TPKMetaField;
  ft: TFieldType;
begin
  //todo: keep one instance of each type in memory for fast cloning?
   // create fields from RTTI
   T := RTTICache.GetType(aObject.classtype);

   pa := T.GetProperties();
   for p in pa do
   begin
      if p is TRttiInstanceProperty then // property ID: TTypedIDField index 0 read GetTypedIDField;
      begin
         ip := TRttiInstanceProperty(p);
         typeinfo := ip.PropInfo.PropType^;
         if typeinfo.Kind <> tkClass then
            Continue;
         classtype := GetTypeData(typeinfo).classtype;
         if not classtype.InheritsFrom(TBaseField) then
            Continue;
         if ip.Index < 0 then
            Continue;

         tablefieldmeta := nil;
         defaultmeta := nil;
         fieldmeta := nil;
         fieldconstraint := nil;
         pkmeta := nil;
         aa := ip.GetAttributes();
         for a in aa do
         begin
            if a is TBaseTableAttribute then // [RelatieStam(ID)]
            begin
               tablefieldmeta := (a as TBaseTableAttribute);
               // rtticache has one reference
               if tablefieldmeta.RefCount = 0 then
                  tablefieldmeta.IncRef;
               tablefieldmeta.IncRef; // own ref
               Break;
            end
            else if a is TTypedMetaField then // [RelatieStam(ID)]
            begin
               fieldmeta := (a as TTypedMetaField); // [TTypedMetaField('ID', ftFieldInteger, True{required}, 'ID')]
               // rtticache has one reference
               if fieldmeta.RefCount = 0 then
                  fieldmeta.IncRef;
               fieldmeta.IncRef; // own ref
               if defaultmeta <> nil then
                  fieldmeta.DefaultValue := defaultmeta;
            end
            else if a is TDefaultValueMeta then
            begin
               defaultmeta := (a as TDefaultValueMeta); // [TDefaultValueMeta('0')
               // rtticache has one reference
               if defaultmeta.RefCount = 0 then
                  defaultmeta.IncRef;
               defaultmeta.IncRef; // own ref
               if fieldmeta <> nil then
                  fieldmeta.DefaultValue := defaultmeta;
            end
            else if a is TPKMetaField then
            begin
               pkmeta := (a as TPKMetaField); //[TPKMetaField(True{autoinc})]
               // rtticache has one reference
               if pkmeta.RefCount = 0 then
                  pkmeta.IncRef;
               pkmeta.IncRef; // own ref
            end
            else if a is TFieldConstraintMeta then
            begin
               fieldconstraint := a as TFieldConstraintMeta;
            end
            else
               raise EUltraException.CreateFmt('Unhandled attribute "%s"', [a.ClassName]);
         end;

         // create meta on the fly (in case not attribute supplied)
         if (fieldmeta = nil) then
         begin
            if classtype.InheritsFrom(TBaseIDField) then
               ft := ftFieldID
            else if classtype.InheritsFrom(TTypedStringField) then
               ft := ftFieldString
            else if classtype.InheritsFrom(TTypedBooleanField) then
               ft := ftFieldBoolean
            else if classtype.InheritsFrom(TTypedDoubleField) then
               ft := ftFieldDouble
            else if classtype.InheritsFrom(TTypedIntegerField) then
               ft := ftFieldInteger
            else if classtype.InheritsFrom(TTypedDateTimeField) then
               ft := ftFieldDateTime
            else if classtype.InheritsFrom(TTypedCurrencyField) then
               ft := ftFieldCurrency
            else
               ft := ftFieldUnknown;

            if (tablefieldmeta = nil) or (tablefieldmeta.FieldMetaData = nil) then
              fieldmeta := TTypedMetaField.Create(p.Name, ft, false, '', 0, 0);
         end;
         if tablefieldmeta = nil then
            tablefieldmeta := TCustomTableAttribute.Create(nil);
         if (tablefieldmeta.FieldMetaData = nil) then
            tablefieldmeta.FieldMetaData := fieldmeta;
         if (tablefieldmeta.KeyMetaData = nil) then
            tablefieldmeta.KeyMetaData := pkmeta;

         if fieldconstraint <> nil then
           tablefieldmeta.ConstraintMeta := fieldconstraint;
         //optimization: ip.name generates new string everytime whereas FieldMetaData.FieldName uses string reference counting
         if (tablefieldmeta.FieldMetaData <> nil) and (ip.Name = tablefieldmeta.FieldMetaData.FieldName) then
           f := TBaseFieldClass(p.PropertyType.AsInstance.MetaclassType).Create(tablefieldmeta.FieldMetaData.FieldName, aDestination, ip.Index, tablefieldmeta)
         else
           f := TBaseFieldClass(p.PropertyType.AsInstance.MetaclassType).Create(ip.Name, aDestination, ip.Index, tablefieldmeta); // bijv TTypedIDField

         //aDestination.Insert(ip.Index, f);
         while (aDestination.Count <= ip.Index) do
            aDestination.Add(nil);
         Assert(not assigned( aDestination[ip.Index]), 'Duplicate index in datarecord'+IntToStr(ip.Index) +' !!!' );
         aDestination[ip.Index] := f;


      end;
   end;
end;

constructor TDataRecord.CreateWithData(aRowData: PRowData);
begin
   inherited Create;
   FRecordData := aRowData;
end;

procedure TDataRecord.DoOnChangeEvents;
var f: TBaseField;
begin
  if FUpdateCount > 0 then
  begin
//    Inc(FPendingUpdates);
    Exit;
  end;

//  if FPendingUpdates <= 0 then Exit;         must also fire on row change!
//  FPendingUpdates := 0;

   for f in Self do
   begin
     if f.FOnChange <> nil then
       f.OnChange.DoEvent(f);
   end;

   if Self.FOnChange <> nil then
     Self.FOnChange.DoEvent(nil);
end;

procedure TDataRecord.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount < 0 then
    FUpdateCount := 0;

  if FUpdateCount = 0 then
    DoOnChangeEvents;
end;

function TDataRecord.GetTypedField<T>(aIndex: Integer): T;
begin
   Result := T(Items[aIndex]);
end;

function TDataRecord.GetField(aIndex: Integer): TCustomField;
begin
  Result := Items[aIndex] as TCustomField;
end;

function TDataRecord.GetOnChange: TBaseField.TMultiChangeEvent;
begin
  if FOnChange = nil then
    FOnChange := TBaseField.TMultiChangeEvent.Create;
  Result := FOnChange;
end;

function TDataRecord.GetRecordData: PRowData;
begin
   Result := FRecordData;
end;

procedure TDataRecord.LoadRecordData(aRowData: PRowData);
begin
   FRecordData := aRowData;
   FOwnData.FieldValues := nil;

   DoOnChangeEvents;
end;

procedure TDataRecord.LoadSharedData(aSingleRecord: TDataRecord);
begin
   if aSingleRecord.ClassType <> Self.ClassType then
      raise EDataException.Create('Cannot shared data between different classes!');
   Self.LoadRecordData(aSingleRecord.GetRecordData);
end;

procedure TDataRecord.Notify(const Item: TBaseField;
  Action: TCollectionNotification);
begin
  if (Action = cnAdded) and Assigned(Item) then
  begin
    if Item.DataRecord = nil then
      Item.FDataRecord := Self;

    //manual added to list? (not auto by rtti etc)
    if Item.Position < 0 then
    begin
      Item.FPosition := Self.IndexOf(Item);
      AllocFieldValues;
    end;
  end;

  inherited;
end;

class function TDataRecord.ObjectHasFieldsByRTTI(
  const aObject: TObject): boolean;
var
  t: TRttiType;
  pa: TArray<TRttiProperty>;
  p: TRttiProperty;
  ip: TRttiInstanceProperty;
  typeinfo: PTypeInfo;
  classtype: TClass;
begin
   Result := false;
   T := RTTICache.GetType(aObject.classtype); // TRelatieStam
   pa := T.GetProperties();
   for p in pa do
   begin
      if p is TRttiInstanceProperty then // property ID: TTypedIDField index 0 read GetTypedIDField;
      begin
         ip := TRttiInstanceProperty(p);
         typeinfo := ip.PropInfo.PropType^;
         if typeinfo.Kind <> tkClass then
            Continue;
         classtype := GetTypeData(typeinfo).classtype;
         if not classtype.InheritsFrom(TBaseField) then
            Continue;
         if ip.Index < 0 then
            Continue;

         Exit(True);
      end;
   end;
end;

{ TBaseField }

procedure TBaseField.Clear2Empty;
begin
   if not(Self is TCustomCalculatedField) then // calcalated fields niet meenemen
      InternalGetFieldValueRecord.Clear2Empty; // modified = false!
end;

procedure TBaseField.Clear2Null;
begin
   if not(Self is TCustomCalculatedField) then
      InternalGetFieldValueRecord.Clear2Null; // modified = true!
end;

constructor TBaseField.Create(const aPropertyName: string; aDataRecord: TDataRecord; aPosition: Integer; aMetaField: TBaseTableAttribute);
begin
   FPropertyName := aPropertyName;
  if (FPropertyName = '') and (aMetaField <> nil) and (aMetaField.FieldMetaData <> nil) then
    FPropertyName := aMetaField.FieldMetaData.FieldName;
   FDataRecord := aDataRecord as TDataRecord;
   FPosition := aPosition;

   MetaField := aMetaField;

   FEditMaskFunction := nil;
   inherited Create;
end;

destructor TBaseField.Destroy;
begin
   if FMetaField <> nil then
   begin
      if FMetaField.RefCount = 1 then
        FMetaField.FieldMetaData := nil;   //can be cloned by ourself, e.g. setdisplaylabel. We can't do this in FMetaField.Destroy itself due to different order of freeing by rtti
      FMetaField.DecRef;
      FMetaField := nil;
   end;

   FOnValidation.Free;
   inherited;
end;

function TBaseField.IsEmpty: Boolean;
begin
   Assert(FDataRecord <> nil);
   if FDataRecord.FRecordData = nil then
     Exit(True);

   Result := InternalGetFieldValueRecord.IsEmpty;
end;

function TBaseField.IsEmptyOrNull: Boolean;
begin
   Result := IsEmpty or IsNull;
end;

function TBaseField.NotEmptyOrNull: Boolean;
begin
  Result := not (IsEmpty or IsNull);
end;

function TBaseField.IsNull: Boolean;
begin
   Result := InternalGetFieldValueRecord.IsNull;
end;

function TBaseField.IsValid: Boolean;
begin
  //todo: validation state in TFieldValueRecord? Because validation only needs to be done once? (so optimization)
  //TValidationState: None, DataLoaded, DataChanged(needs recheck?), ValidationOK, ValidationError

   Result := InternalValidationText() = '';
end;

procedure TBaseField.LoadValue(const aValue: Variant);
var
  prec: PFieldData;
begin
  //ugly but fast direct write of value to array of current row
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;
   prec.LoadValue(aValue);
end;

procedure TBaseField.ResetModifiedState;
begin
   InternalGetFieldValueRecord.ResetModifiedState;
end;

procedure TBaseField.CopyFieldValue(FromField: TBaseField);
begin
   if FromField.IsNull then
      Clear2Null
   else if FromField.IsEmpty then
      Clear2Empty
   else
      ValueAsVariant := FromField.ValueAsVariant;
end;

constructor TBaseField.Create;
begin
  Create('', ftFieldUnknown);
end;

constructor TBaseField.Create(const aPropertyName, TableName: string; aFieldType: TFieldType);
var
  fieldmeta: TTypedMetaField;
  tablefieldmeta: TCustomTableAttribute;
begin
  tablefieldmeta := TCustomTableAttribute.Create(nil);
  if (TableName <> '') then
     tablefieldmeta.TableMetaData := TTableMeta.Create(TableName);
  fieldmeta      := TTypedMetaField.Create(aPropertyName, aFieldType, false, '', 0, 0);
  tablefieldmeta.FieldMetaData := fieldmeta;
  Create(aPropertyName, tablefieldmeta);
end;

constructor TBaseField.Create(const aPropertyName: string; aFieldType: TFieldType);
begin
   Create(aPropertyName, '', aFieldType);
end;

constructor TBaseField.Create(const aPropertyName: string; aMetaField: TBaseTableAttribute);
begin
  Create(aPropertyName, nil, -1, aMetaField);
end;

function TBaseField.HasSameValue(CompareField: TBaseField): Boolean;
begin
   if IsEmptyOrNull or CompareField.IsEmptyOrNull then
      Result := False
   else
      Result := (ValueAsVariant = CompareField.ValueAsVariant);
end;

function TBaseField.GetDatabaseName: String;
begin
  Assert( (FMetaField <> nil) and
            (FMetaField.TableMetaData <> nil) );
  Result := FMetaField.TableMetaData.DBName;
end;

procedure TBaseField.SetDatbaseName(const Name: string);
begin
  //set dbname globally for all cruds at once?
   FMetaField.TableMetaData.DBName := Name;
end;

function TBaseField.HasDefaultValue: Boolean;
begin
  Result := (FMetaField <> nil) and
            (FMetaField.FieldMetaData <> nil) and
            (FMetaField.FieldMetaData.DefaultValue <> nil);
end;

function TBaseField.GetDefaultValue: Variant;
begin
   //Assert(HasDefaultValue);
   if HasDefaultValue then
     Result := FMetaField.FieldMetaData.DefaultValue.DefaultValue
   else
     Result := Null;
end;

function TBaseField.GetDisplayFormat: string;
begin
   Assert((FMetaField <> nil) and (FMetaField.FieldMetaData <> nil));
   Result := FMetaField.FieldMetaData.DisplayFormat;
end;

function TBaseField.GetDisplayLabel: String;
begin
   Assert((FMetaField <> nil) and (FMetaField.FieldMetaData <> nil));
   Result := FMetaField.FieldMetaData.DisplayLabel;
   if Trim(Result) = '' then
      Result := FieldName;
end;

function TBaseField.GetDisplayText: string;
begin
   if (DisplayFormat = '') then
      Result := ValueAsString
   else
      Result := FormatFloat(DisplayFormat, Self.ValueAsDouble);
end;

function TBaseField.GetDisplayWidth: Integer;
begin
    Assert((FMetaField <> nil) and (FMetaField.FieldMetaData <> nil));
    Result := FMetaField.FieldMetaData.DisplayWidth;
end;

function TBaseField.GetEditFormat: string;
begin
   Assert((FMetaField <> nil) and (FMetaField.FieldMetaData <> nil));
   Result := FMetaField.FieldMetaData.EditFormat;
   if (Result = '') then
      Result := DisplayFormat; // When EditFormat is unassigned, but the DisplayFormat property has a value, the DisplayFormat string is used.
end;

function TBaseField.GetEditMask: string;
begin
   if Assigned(FEditMaskFunction) then
      Result := FEditMaskFunction
   else
   begin
      Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
      Result := FMetaField.FieldMetaData.EditMask;
   end;
end;

procedure TBaseField.SetEditFormat(const Value: string);
begin
   Assert((MetaField <> nil) and (MetaField.FieldMetaData <> nil));
   // clone: should not change the global metadata!
   if MetaField.RefCount > 1 then
      MetaField := MetaField.Clone;
   if MetaField.FieldMetaData.RefCount > 1 then
      MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
   MetaField.FieldMetaData.EditFormat := Value;
end;

procedure TBaseField.SetEditMask(const Value: string);
begin
   Assert((MetaField <> nil) and (MetaField.FieldMetaData <> nil));
   // clone: should not change the global metadata!
   if MetaField.RefCount > 1 then
      MetaField := MetaField.Clone;
   if MetaField.FieldMetaData.RefCount > 1 then
      MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
   MetaField.FieldMetaData.EditMask := Value;
   FEditMaskFunction := nil;
end;

function TBaseField.GetFieldName: String;
begin
   Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
   Result := FMetaField.FieldMetaData.FieldName;
end;

function TBaseField.GetFieldType: TFieldType;
begin
   Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
   Result := FMetaField.FieldMetaData.FieldType;
end;

function TBaseField.GetFieldValue: Variant;
begin
   Result := InternalGetFieldValueRecord.FieldValue;
   if VarIsEmpty(Result) then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',[Self.TableName+'.'+Self.FieldName]);
   if VarIsNull(Result) and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetMaxValue: Double;
begin
  Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
  Result := FMetaField.FieldMetaData.MaxValue;
end;

function TBaseField.GetMinValue: Double;
begin
  Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
  Result := FMetaField.FieldMetaData.MinValue;
end;

function TBaseField.GetOnChange: TMultiChangeEvent;
begin
  if FOnChange = nil then
    FOnChange := TMultiChangeEvent.Create;
  Result := FOnChange;
end;

function TBaseField.GetOnValidation: TMultiValidationEvent;
begin
   if FOnValidation = nil then
      FOnValidation := TMultiValidationEvent.Create;
   Result := FOnValidation;
end;

function TBaseField.GetOrigFieldValue: Variant;
begin
   Result := InternalGetFieldValueRecord.OrigValue;
end;

function TBaseField.GetOrigFieldValueOrFieldValue: Variant;
begin
   if IsModified then
      Result := OrigFieldValue
   else
      Result := ValueAsVariant
end;

function TBaseField.GetRequired: Boolean;
begin
   Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
   Result := FMetaField.FieldMetaData.Required;
end;

function TBaseField.GetTableClassName: String;
begin
   Result := '';
   if (FMetaField <> nil)
   then
    Result := FMetaField.ClassName;
end;

function TBaseField.GetTableName: String;
begin
   Result := '';
   if (FMetaField <> nil) and
      (FMetaField.TableMetaData <> nil)
   then
    Result := FMetaField.TableMetaData.Table;
end;

procedure TBaseField.SetTableParameter(const aValue: Variant; const Index: Integer);
begin
   if (FMetaField <> nil) and (FMetaField.TableMetaData <> nil) and (FMetaField.TableMetaData is TFunctionTableMeta) then
      (FMetaField.TableMetaData as TFunctionTableMeta).SetParameter(aValue, Index);
end;

function TBaseField.GetValueAsTime: TTime;
begin
   Result :=  TimeOf(ValueAsDateTime);
end;

function TBaseField.GetValidationErrorText: string;
begin
   Result := InternalValidationText;
end;

function TBaseField.InternalGetFieldValueRecord: PFieldData;
begin
   Assert(FDataRecord <> nil);
   if FDataRecord.FRecordData = nil then
      raise EDataException.CreateFmt('Current record contains no data: no value for field "%s"',[Self.TableName+'.'+Self.FieldName]);

   if FPosition >= Length(FDataRecord.FRecordData.FieldValues) then
     Assert(false,'Positie ligt buiten bereik van datarecord: Veld:'+Self.TableName+'.'+Self.FieldName);

   //ugly but fast direct read of value from array of current row
   Result := @(FDataRecord.FRecordData.FieldValues[Self.FPosition]);
end;

function TBaseField.InternalValidationText: string;
var
  finaltest: string;
begin
   Result := '';
   if IsRequired and
      not IsAutoInc and    //autoinc fields are automatic filled in DB so needs/allowed to be empty  
      IsEmptyOrNull and (not HasDefaultValue) 
   then
      Result := _Fmt('"%s" is required and empty, please fill in a value', [DisplayLabel]);

   if Result <> '' then Exit;
   if IsEmpty then Exit;
   if (MaxValue <> 0) or (MinValue <> 0) then
   begin
      if (Self.FieldType = ftFieldString) then
      begin
        // strings kleiner dan 0 is onzin
        if (Self.MaxValue > 0) and (Length(ValueAsString) > MaxValue) then
          Result := _Fmt('"%s" bevat te veel tekens (max: %1.0f)',[DisplayLabel, MaxValue]);
        if (Self.MinValue > 0) and (Length(ValueAsString) < MinValue) then
          Result := _Fmt('"%s" bevat te weinig tekens (min: %1.0f)',[DisplayLabel, MinValue]);
      end
      else
      begin
        if (ValueAsDouble > MaxValue) then
          Result := _Fmt('"%s" overschrijdt maximum waarde',[DisplayLabel]);
        if (ValueAsDouble < MinValue) then
          Result := _Fmt('"%s" zit onder minimum waarde',[DisplayLabel]);
      end;
   end;

   if (Result = '') and (FOnValidation <> nil) then
  begin
    FOnValidation.DoEvent(Self,
      //callback for each validation
      procedure(const aError: string; out aStop: Boolean)
      begin
        if aError <> '' then
          aStop := True;
         end, finaltest);
    Result := finaltest;
  end;
end;

function TBaseField.IsModified: Boolean;
begin
   Result := (not (Self is TCustomCalculatedField)) and InternalGetFieldValueRecord.Modified;
end;

procedure TBaseField.SetDisplayFormat(const Value: string);
begin
   Assert((MetaField <> nil) and (MetaField.FieldMetaData <> nil));
   // clone: should not change the global metadata!
   if MetaField.RefCount > 1 then
      MetaField := MetaField.Clone;
   if MetaField.FieldMetaData.RefCount > 1 then
      MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
   MetaField.FieldMetaData.DisplayFormat := Value;
end;

procedure TBaseField.SetDisplayLabel(const Value: String);
begin
   Assert((FMetaField <> nil) and (FMetaField.FieldMetaData <> nil));
   // clone: should not change the global metadata!
   if MetaField.RefCount > 1 then
      MetaField := FMetaField.Clone;
   if MetaField.FieldMetaData.RefCount > 1 then
      MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;

   MetaField.FieldMetaData.DisplayLabel := Value;
end;

procedure TBaseField.SetDisplayWidth(const Value: Integer);
begin
   Assert((FMetaField <> nil) and (FMetaField.FieldMetaData <> nil));
   // clone: should not change the global metadata!
   if MetaField.RefCount > 1 then
      MetaField := FMetaField.Clone;
   if MetaField.FieldMetaData.RefCount > 1 then
      MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
   MetaField.FieldMetaData.DisplayWidth := Value;
end;

procedure TBaseField.SetFieldValue(const Value: Variant);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if (FOnChange <> nil) or (DataRecord.FOnChange <> nil) then
     old := prec.FieldValue;

   prec.FieldValue := Value;

   if ( (FOnChange <> nil) or (DataRecord.FOnChange <> nil) ) and
      (old <> Value) then
   begin
     if (FOnChange <> nil) then
       OnChange.DoEvent(Self);
     if (DataRecord.FOnChange <> nil) then
       DataRecord.OnChange.DoEvent(Self);
   end;
end;

procedure TBaseField.SetMaxValue(const Value: Double);
begin
  Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
  //clone: should not change the global metadata!
  if MetaField.RefCount > 1 then
    MetaField := MetaField.Clone;
  if MetaField.FieldMetaData.RefCount > 1 then
    MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
  MetaField.FieldMetaData.MaxValue := Value;
end;

procedure TBaseField.SetMetaField(const Value: TBaseTableAttribute);
begin
   if FMetaField = Value then
      Exit;
   if FMetaField <> nil then
      FMetaField.DecRef;

   FMetaField := Value;

   if FMetaField <> nil then
      FMetaField.IncRef;
end;

procedure TBaseField.SetNullableValueAsInteger(const aValue: Integer);
begin
   InternalSetValueAsInteger(aValue, True);
end;

procedure TBaseField.InternalSetValueAsInteger(const aValue: Integer; ZeroAsNull: Boolean);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if FOnChange <> nil then
     old := prec.FieldValue;

   if (aValue = 0) and ZeroAsNull then
      prec.Clear2Null
   else
      prec.ValueAsInteger := aValue;

   if (FOnChange <> nil) and (old <> aValue) then
     OnChange.DoEvent(Self);
end;

procedure TBaseField.SetMinValue(const Value: Double);
begin
  Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
  //clone: should not change the global metadata!
  if MetaField.RefCount > 1 then
    MetaField := MetaField.Clone;
  if MetaField.FieldMetaData.RefCount > 1 then
    MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
  MetaField.FieldMetaData.MinValue := Value;
end;

procedure TBaseField.SetRequired(const Value: Boolean);
begin
   Assert((MetaField <> nil) and (MetaField.FieldMetaData <> nil));
   // clone: should not change the global metadata!
   if MetaField.RefCount > 1 then
      MetaField := MetaField.Clone;
   if MetaField.FieldMetaData.RefCount > 1 then
      MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;

   MetaField.FieldMetaData.Required := Value;
end;

procedure TBaseField.SetValueAsTime(const Value: TTime);
begin
   SetValueAsDateTime(TimeOf(Value));
end;

procedure TBaseField.SetValueAsBoolean(const aValue: Boolean);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if FOnChange <> nil then
     old := prec.FieldValue;

   prec.ValueAsBoolean := aValue;

   if (FOnChange <> nil) and (old <> aValue) then
     OnChange.DoEvent(Self);
end;

procedure TBaseField.SetValueAsCurrency(const aValue: Currency);
begin
   SetValueAsDouble(RoundF(aValue));
end;

procedure TBaseField.SetValueAsDate(const Value: TDate);
begin
   SetValueAsDateTime(DateOf(Value));
end;

procedure TBaseField.SetValueAsDateTime(const aValue: TDateTime);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if FOnChange <> nil then
     old := prec.FieldValue;

   prec.ValueAsDateTime := aValue;

   if (FOnChange <> nil) and (old <> aValue) then
     OnChange.DoEvent(Self);
end;

procedure TBaseField.SetValueAsDouble(const aValue: Double);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if FOnChange <> nil then
     old := prec.FieldValue;

   prec.ValueAsDouble := aValue;

   if (FOnChange <> nil) and (old <> aValue) then
     OnChange.DoEvent(Self);
end;

procedure TBaseField.SetValueAsInt64(const aValue: Int64);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if FOnChange <> nil then
     old := prec.FieldValue;

   prec.ValueAsInt64 := aValue;

   if (FOnChange <> nil) and (old <> aValue) then
     OnChange.DoEvent(Self);
end;

procedure TBaseField.SetValueAsInteger(const aValue: Integer);
begin
  InternalSetValueAsInteger(aValue, False);
end;

procedure TBaseField.SetValueAsString(const aValue: String);
var
   prec: PFieldData;
   old: Variant;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;

   if FOnChange <> nil then
     old := prec.FieldValue;

   prec.ValueAsString := aValue;

   if (FOnChange <> nil) and (old <> aValue) then
     OnChange.DoEvent(Self);
end;

procedure TBaseField.SetValueAsVariant(const aValue: Variant);
begin
   SetFieldValue(aValue);
end;

procedure TBaseField.SetVisible(const Value: Boolean);
begin
  Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
  //clone: should not change the global metadata!
  if MetaField.RefCount > 1 then
    MetaField := MetaField.Clone;
  if MetaField.FieldMetaData.RefCount > 1 then
    MetaField.FieldMetaData := MetaField.FieldMetaData.Clone;
  MetaField.FieldMetaData.Visible := Value;
end;

function TBaseField.ToString: string;
begin
  Result := Self.ValueAsString;
end;

procedure TBaseField.UndoChange;
begin
   InternalGetFieldValueRecord.UndoChange;
end;

function TBaseField.GetValueAsBoolean: Boolean;
var
   p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := p.ValueAsBoolean;

   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);

   if p.IsNull and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetValueAsCurrency: Currency;
begin
   Result := RoundF(GetValueAsDouble);
end;

function TBaseField.GetValueAsDate: TDate;
begin
   Result := DateOf(ValueAsDateTime);
end;

function TBaseField.GetValueAsDateTime: TDateTime;
var
   p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := p.ValueAsDateTime;
   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);
   if p.IsNull and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetValueAsDouble: Double;
var
   p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := p.ValueAsDouble;
   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);
   if p.IsNull and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetValueAsInt64: Int64;
var
   p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := p.ValueAsInt64;
   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);
   if p.IsNull and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetValueAsInteger: Integer;
var
   p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := p.ValueAsInteger;
   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);
   if p.IsNull and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetValueAsString: String;
var
   p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := p.ValueAsString;
   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);
   if p.IsNull and Self.HasDefaultValue then
      Result := Self.DefaultValue;
end;

function TBaseField.GetValueAsVariant: Variant;
begin
   Result := GetFieldValue;
end;

function TBaseField.GetIsAutoInc: Boolean;
begin
  Result := False;
  if (MetaField.KeyMetaData is TPKMetaField) then
    Result := (MetaField.KeyMetaData as TPKMetaField).IsAutoInc;
end;

function TBaseField.GetIsEmptyString: Boolean;
begin
   Result := IsEmptyOrNull or (ValueAsString = '')
end;

function TBaseField.GetValueOrEmptyString: string;
begin
   if IsEmptyOrNull then
      Result := ''
   else
      Result := ValueAsString;
end;

function TBaseField.GetVisible: Boolean;
begin
  Assert( (FMetaField <> nil) and (FMetaField.FieldMetaData <> nil) );
  Result := FMetaField.FieldMetaData.Visible;
end;

function TBaseField.GetIntValueOrZero: Integer;
begin
   if IsEmptyOrNull then
      Result := 0
   else
      Result := ValueAsInteger;
end;

function TBaseField.GetDoubleValueOrZero: Double;
begin
   if IsEmptyOrNull then
      Result := 0.0
   else
      Result := ValueAsDouble;
end;

function TBaseField.GetCurrencyValueOrZero: Currency;
begin
   if IsEmptyOrNull then
      Result := 0.0
   else
      Result := ValueAsCurrency;
end;

{ TMultiDataRecord }

procedure TMultiDataRecord.AfterConstruction;
begin
   inherited AfterConstruction;

   // standalone datarecord/model should be possible!
   if FMultiRecordData = nil then
   begin
      FOwnMultiRecordData.RowData.FieldValues := AllocFieldValueArray(Self.Count);
      FMultiRecordData := @FOwnMultiRecordData;

      // overwrite TDataRecord fields:
      FRecordData := @FOwnMultiRecordData.RowData;
      FOwnData.FieldValues := nil;
   end;
end;

procedure TMultiDataRecord.Clear2Empty;
var
   I: Integer;
begin
   inherited Clear2Empty;

   if FRecordData <> nil then
      for I := 0 to High(FRecordData.FieldValues) do
      begin
         FRecordData.FieldValues[I].Clear2Empty;
      end;

   // clear list data
   if FMultiRecordData <> nil then
     FMultiRecordData.ClearData;
end;

procedure TMultiDataRecord.Clear2Null;
var
   I: Integer;
begin
   inherited Clear2Null;

   if FRecordData <> nil then
      for I := 0 to High(FRecordData.FieldValues) do
      begin
         FRecordData.FieldValues[I].Clear2Null;
      end;
end;

constructor TMultiDataRecord.CreateWithData(aRowData: PMultiRowData);
begin
   FMultiRecordData := aRowData;

   if aRowData = nil then
      inherited CreateWithData(nil)
   else
      inherited CreateWithData(@aRowData.RowData)
end;

function TMultiDataRecord.ListSlotCount: Integer;
var master: ISlotMaster;
begin
   Result := -1;
   Assert(FOwner <> nil, 'no owner, multi record with subdata not possible!');
   if FOwner.GetInterface(ISlotMaster, master) then
      Result := master.ListSlotCount
   else
      Assert(false, 'no BO owner, multi record with subdata not possible (yet)!');
end;

procedure TMultiDataRecord.LoadMultiRecordData(aRowData: PMultiRowData);
begin
   if @FOwnMultiRecordData <> aRowData then
   begin
      FOwnMultiRecordData.RowData.FieldValues := nil;
      FOwnMultiRecordData.RecordListData := nil;
   end;
   if aRowData = nil then
     LoadRecordData(nil)
   else
     LoadRecordData(@aRowData.RowData);

   FMultiRecordData := aRowData;
end;

procedure TMultiDataRecord.LoadRecordData(aRowData: PRowData);
var istart, i: Integer;
begin
   inherited LoadRecordData(aRowData);

   if (FRecordData <> nil) and (Length(FRecordData.FieldValues) < Self.Count) then
   begin
      istart := Length(FRecordData.FieldValues);
      SetLength(FRecordData.FieldValues, Self.Count);
      for I := istart to Self.Count - 1 do
         FRecordData.FieldValues[I].Clear2Empty;
      // see AllocFieldValueArray
   end;

   if @FOwnMultiRecordData.RowData <> aRowData then
      FOwnMultiRecordData.RowData.FieldValues := nil;
   FMultiRecordData := nil;
end;

procedure TMultiDataRecord.LoadSharedData(aSingleRecord: TDataRecord);
begin
   inherited LoadSharedData(aSingleRecord);
   if aSingleRecord is TMultiDataRecord then
      Self.LoadMultiRecordData((aSingleRecord as TMultiDataRecord).FMultiRecordData);
end;

function TMultiDataRecord.RegisterListSlot: Integer;
var master: ISlotMaster;
begin
   Result := -1;
   Assert(FOwner <> nil, 'no owner, multi record with subdata not possible!');
   if FOwner.GetInterface(ISlotMaster, master) then
      Result := master.RegisterListSlot
   else
      Assert(false, 'no BO owner, multi record with subdata not possible (yet)!');
end;

function TMultiDataRecord.RegisterSingleSlot: Integer;
var master: ISlotMaster;
begin
   Result := -1;
   Assert(FOwner <> nil, 'no owner, multi record with subdata not possible!');
   if FOwner.GetInterface(ISlotMaster, master) then
      Result := master.RegisterSingleSlot
   else
      Assert(false, 'no BO owner, multi record with subdata not possible (yet)!');
end;

function TMultiDataRecord.SingleSlotCount: Integer;
var master: ISlotMaster;
begin
   Result := -1;
   Assert(FOwner <> nil, 'no owner, multi record with subdata not possible!');
   if FOwner.GetInterface(ISlotMaster, master) then
      Result := master.SingleSlotCount
   else
      Assert(false, 'no BO owner, multi record with subdata not possible (yet)!');
end;

{ TBaseFKField }

constructor TBaseIDField.Create(const aPropertyName, TableName: string; aFieldType: TFieldType);
begin
   inherited; //override is alleen om public te maken
end;

function TBaseIDField.GetTypedIDValue: Int64;
begin
   Result := GetValueAsInteger;
end;

procedure TBaseIDField.SetTypedIDValue(const Value: Int64);
begin
   if (Value <= 0) then // ID bestaat zeker niet, dus veld wordt NULL
      Clear2Null
   else
      SetValueAsInt64(Value);
end;


{ TCustomIDField<T> }

class constructor TCustomIDField<T>.Create;
var
  rt: TRttiType;
  ft: TRttiField;
begin
   // sanitycheck, must be a TBaseIDValue like record
   rt := GlobalRTTI.RTTICache.GetType(typeinfo(T));
   ft := rt.GetField('ID');
   Assert(ft <> nil, 'record must contain ID field');
   Assert(ft.Offset = 0, 'ID field must be the first field'); // important, otherwise memory corruptions...
   Assert(ft.FieldType.TypeKind = tkInt64, 'ID field must be Int64'); // important, otherwise memory corruptions...
end;

function TCustomIDField<T>.GetTypedID: T;
begin
   PBaseIDValue(@Result).ID := GetTypedIDValue;
end;

procedure TCustomIDField<T>.SetTypedID(const aValue: T);
begin
   SetTypedIDValue( PBaseIDValue(@aValue).ID );
end;

{ TBaseIDValue }

class function TBaseIDValue.Get(aValue: Int64): TBaseIDValue;
begin
   Result.ID := aValue;
end;

class function TBaseIDValue.Get<T>(aValue: Int64): T;
begin
   PBaseIDValue(@Result).ID := aValue;
end;

function TBaseIDValue.IsEmpty: Boolean;
begin
   Result := (Integer(ID) = 0);
end;

procedure TBaseIDValue.Empty;
begin
   ID := 0;
end;

{ TCustomCalculatedField }

function TCustomCalculatedField.GetFieldValue: Variant;
begin
   Result := FieldValue;
end;

function TCustomCalculatedField.GetValueAsDateTime: TDateTime;
begin
   Result := FieldValue;
end;

function TCustomCalculatedField.GetValueAsDouble: Double;
begin
   Result := FieldValue;
end;

function TCustomCalculatedField.GetValueAsInt64: Int64;
begin
   Result := FieldValue;
end;

function TCustomCalculatedField.GetValueAsInteger: integer;
begin
   Result := FieldValue;
end;

function TCustomCalculatedField.GetValueAsString: string;
begin
   Result := FieldValue;
end;

function TCustomCalculatedField.InternalGetFieldValueRecord: PFieldData;
begin
   Assert(False, 'no fielddata for calculated fields!');
   Result := nil;
end;

function TCustomCalculatedField.IsEmpty: boolean;
begin
   Result := True;
end;

function TCustomCalculatedField.IsModified: Boolean;
begin
   Result := False;
end;

function TCustomCalculatedField.IsNull: boolean;
begin
   Result := True;
end;

{ TTypedIntegerCalcField }

procedure TTypedIntegerCalcField.AfterConstruction;
begin
  inherited;
end;

function TTypedIntegerCalcField.GetFieldType: TFieldType;
begin
   Result := ftFieldInteger;
end;

function TTypedIntegerCalcField.GetFieldValue: Variant;
begin
   Assert(Assigned(OnCalcValue));
   Result := OnCalcValue(Self.DataRecord as TDataRecord);
end;

function TTypedIntegerCalcField.IsEmpty: boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

function TTypedIntegerCalcField.IsNull: boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

procedure TTypedIntegerCalcField.SetOnCalcValue(const Value: TIntegerCalcEvent);
begin
   FOnCalcValue := Value;
end;

{ TTypedDoubleCalcField }

procedure TTypedDoubleCalcField.AfterConstruction;
begin
  inherited;
end;

function TTypedDoubleCalcField.GetFieldType: TFieldType;
begin
   Result := ftFieldDouble;
end;

function TTypedDoubleCalcField.GetFieldValue: Variant;
begin
   Assert(Assigned(OnCalcValue));
   Result := OnCalcValue(Self.DataRecord as TDataRecord);
end;

function TTypedDoubleCalcField.IsEmpty: boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

function TTypedDoubleCalcField.IsNull: boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

procedure TTypedDoubleCalcField.SetOnCalcValue(const Value: TDoubleCalcEvent);
begin
   FOnCalcValue := Value;
end;

{ TTypedStringCalcField }

procedure TTypedStringCalcField.AfterConstruction;
begin
  inherited;
end;

function TTypedStringCalcField.GetFieldType: TFieldType;
begin
   Result := ftFieldString;
end;

function TTypedStringCalcField.GetFieldValue: Variant;
begin
   Assert(Assigned(OnCalcValue));
   Result := OnCalcValue(Self.DataRecord as TDataRecord);
end;

function TTypedStringCalcField.IsEmpty: Boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

function TTypedStringCalcField.IsNull: Boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

procedure TTypedStringCalcField.SetOnCalcValue(const Value: TStringCalcEvent);
begin
   FOnCalcValue := Value;
end;

{ TJoinableDataRecord }

procedure TJoinableDataRecord.AddChildData(aChildDataRecord: TJoinableDataRecord);
begin
   if FChildData = nil then
      FChildData := TObjectList<TJoinableDataRecord>.Create(True{owns});
   FChildData.Add(aChildDataRecord);
end;

procedure TJoinableDataRecord.Clear2Empty;
var child: TJoinableDataRecord;
begin
   inherited;
   if FChildData = nil then
      Exit;

   for child in FChildData do
      child.Clear2Empty;
end;

procedure TJoinableDataRecord.Clear2Null;
var child: TJoinableDataRecord;
begin
   inherited;
   if FChildData = nil then
      Exit;

   for child in FChildData do
      child.Clear2Null;
end;

destructor TJoinableDataRecord.Destroy;
begin
   FChildData.Free;
   inherited;
end;

{ TTypedDateTimeCalcField }

procedure TTypedDateTimeCalcField.AfterConstruction;
begin
  inherited;
end;

function TTypedDateTimeCalcField.GetFieldType: TFieldType;
begin
   Result := ftFieldDateTime;
end;

function TTypedDateTimeCalcField.GetFieldValue: Variant;
begin
   Assert(Assigned(OnCalcValue));
   Result := OnCalcValue(Self.DataRecord as TDataRecord);
end;

function TTypedDateTimeCalcField.IsEmpty: boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

function TTypedDateTimeCalcField.IsNull: boolean;
begin
   Result := not Assigned(OnCalcValue);
end;

procedure TTypedDateTimeCalcField.SetOnCalcValue(const Value: TDateTimeCalcEvent);
begin
   FOnCalcValue := Value;
end;

{ TNonQueryField }

constructor TNonQueryField.Create(const aPropertyName: string; aDataRecord: TDataRecord; aPosition: Integer; aMetaField: TBaseTableAttribute);
begin
   inherited;
   FDisplayLabel := aPropertyName;
end;

function TNonQueryField.GetDisplayLabel: string;
begin
   Result := _(FDisplayLabel);
end;

function TNonQueryField.GetFieldType: TFieldType;
begin
   Result := FFieldType;
end;

procedure TNonQueryField.SetDisplayLabel(const Value: string);
begin
   FDisplayLabel := Value;
end;

{ TNonQueryBooleanField }

function TNonQueryBooleanField.GetFieldType: TFieldType;
begin
   Result := ftFieldBoolean;
end;

{ TNonQueryStringField }

function TNonQueryStringField.GetFieldType: TFieldType;
begin
   Result := ftFieldString;
end;

{ TNonQueryDoubleField }

function TNonQueryDoubleField.GetFieldType: TFieldType;
begin
   Result := ftFieldDouble;
end;

{ TNonQueryIntegerField }

function TNonQueryIntegerField.GetFieldType: TFieldType;
begin
   Result := ftFieldInteger;
end;

{ TNonQueryDateTimeField }

function TNonQueryDateTimeField.GetFieldType: TFieldType;
begin
   Result := ftFieldDateTime;
end;

{ TNonQueryTimeField }

function TNonQueryTimeField.GetFieldType: TFieldType;
begin
   Result := ftFieldDateTime;
end;

{ TNonQueryDateField }

function TNonQueryDateField.GetFieldType: TFieldType;
begin
   Result := ftFieldDateTime;
end;

{ TTypedStringField }

constructor TTypedStringField.Create(const aPropertyName: string = ''; const StringSize: Integer = 0);
begin
  Create(aPropertyName, ftFieldString);
  MaxValue := StringSize;
end;

procedure TTypedStringField.SetValueAsString(const aValue: String);
var s: string;
begin
   if Assigned(FOnFormatField) then
      s := FOnFormatField(aValue)
   else
      s := aValue;

   inherited SetValueAsString(s);
end;

function TTypedStringField.StringSize: Integer;
begin
   Result := Round(MaxValue)
end;

{ TRegisteredCustomFields }

class function TRegisteredCustomFields.Count: Integer;
begin
   Result := List.Count;
end;

class constructor TRegisteredCustomFields.Create;
begin
//   FList := TList<TBaseFieldClass>.Create;
end;

class destructor TRegisteredCustomFields.Destroy;
begin
   FList.Free;
end;

class function TRegisteredCustomFields.GetItem(aIndex: Integer): TBaseFieldClass;
begin
   Result := List.Items[aIndex];
end;

class function TRegisteredCustomFields.List: TList<TBaseFieldClass>;
begin
   if (not Assigned(FList)) then
      FList := TList<TBaseFieldClass>.Create;
   Result := FList;
end;

class procedure TRegisteredCustomFields.RegisterCustomField(aFieldClass: TBaseFieldClass);
begin
   if not List.Contains(aFieldClass) then
      List.Add(aFieldClass);
end;

{ TUltraBooleanField }

function TUltraBooleanField.GetFieldType: TFieldType;
begin
   Result := ftFieldBoolean;
end;

function TUltraBooleanField.GetIntValueAsBoolean: Boolean;
var p: PFieldData;
begin
   p := InternalGetFieldValueRecord;
   Result := (p.ValueAsInteger <> 0); // alleen 0 is false, rest is true
   if p.IsEmpty then
      raise EDataException.CreateFmt('No value loaded for field "%s" (probably not included in the select statement?)',
         [Self.TableName + '.' + Self.FieldName]);
end;

procedure TUltraBooleanField.SetIntValueAsBoolean(const aValue: Boolean);
var prec: PFieldData;
begin
   prec := InternalGetFieldValueRecord;
   if prec.DataType = ftFieldUnknown then // first time?
      prec.DataType := Self.FieldType;
   prec.ValueAsInteger := IfThen(aValue, 1, 0);
end;

function TFieldList.GetFieldByName(const aFieldname: string): TBaseField;
var f: TBaseField;
begin
  Result := nil;
  for f in Self do
    if SameText(f.FieldName, aFieldname) then
      Exit(f);
end;

{ TTypedDoubleField }

constructor TTypedDoubleField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldDouble);
end;

{ TTypedBooleanField }

constructor TTypedBooleanField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldBoolean);
end;

{ TTypedTimeField }

constructor TTypedTimeField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldDateTime);
end;

{ TTypedDateField }

constructor TTypedDateField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldDateTime);
end;

{ TTypedDateTimeField }

constructor TTypedDateTimeField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldDateTime);
end;

{ TTypedCurrencyField }

constructor TTypedCurrencyField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldCurrency);
end;

{ TTypedIntegerField }

constructor TTypedIntegerField.Create(const aPropertyName: string);
begin
  Create(aPropertyName, ftFieldInteger);
end;

{ TValidationRecord }

procedure TValidationRecord.Clear;
begin
   Field := nil;
   Error := '';
   Error_ID := 0;
end;

function TValidationRecord.HasError: Boolean;
begin
   Result := Assigned(Field) or (Error <> '');
end;

initialization
  Variants.NullStrictConvert := False;   //null to 0, null to '', etc
end.
