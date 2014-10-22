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
unit Data.CustomSQLFields;

interface

uses Data.Datarecord, Data.EnumField, Data.Query, Generics.Collections, Meta.Data;

type
   TConvertSQLType = (csDate, csDateTime, csString, csBit, csFloat, csInt);

   ICaseNext = interface;
   ICaseThen = interface;
   ICaseWhen = interface;
   ICondition = interface;
   IConditionCompareTo = interface;
   ICaseElseCondition = interface;
   IConditionCompareOperator = interface;
   IStatementBase = interface;
   IStatement = interface;
   IStringStatement = interface;
   IFloatStatement = interface;
   IIntegerStatement = interface;
   IDateTimeStatement = interface;
   IDateStatement = interface;
   ICustomSQLType = interface;
   IConditionCompare = interface;
   IIsNullNext = interface;
   ICoalesceNext = interface;
   ICoalesceEnd = interface;

   IQueryFieldBuilder = interface
      function New: ICustomSQLType;
      function CurrentFieldCase: ICaseNext;
      function NewSub: ICustomSQLType;
      function GetCustomSQL(const aQuery: IQueryDetails; const WithAlias: Boolean): string;
   end;

   ICustomSQLType = interface
      function CaseFieldOf(const aField: TBaseField): ICaseNext; overload;
      function CaseFieldOf(const aSubStatement: IStatementBase): ICaseNext; overload;
      function CaseWhen(const aCondition: ICondition): ICaseWhen;

      function FieldCompare(const aField: TBaseField; const WithIsNull: Boolean = False): IConditionCompareOperator;
      function StatementCompare(const aSubStatement: IStatementBase): IConditionCompareOperator;

      function TrimmedFieldAndSpace(const aField: TBaseField; const WithIsNull: Boolean = True): IStringStatement;
      function FieldAsStatement(const aField: TBaseField; const WithIsNull: Boolean = False): IStatement;
      function VariantAsStatement(const aValue: Variant): IStatement;

      function IsNull(const aField: TBaseField): IIsNullNext; overload;
      function IsNull(const aSubStatement: IStatementBase): IIsNullNext; overload;
      function Coalesce(const aField: TBaseField): ICoalesceNext; overload;
      function Coalesce(const aSubStatement: IStatementBase): ICoalesceNext; overload;

      function ConvertTo(const aType: TConvertSQLType; const aField: TBaseField; const StringSize: Integer = 0): IStatement; overload;
      function ConvertTo(const aType: TConvertSQLType; const aSubStatement: IStatementBase; const StringSize: Integer = 0): IStatement; overload;

      function OpenBracket: ICustomSQLType;

      function Sum(const aField: TBaseField): IFloatStatement; overload;
      function Sum(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Min(const aField: TBaseField): IFloatStatement; overload;
      function Min(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Max(const aField: TBaseField): IFloatStatement; overload;
      function Max(const aSubStatement: IStatementBase): IFloatStatement; overload;
      //TODO
//      // Bewerkingen op strings
      function Trim(const aField: TBaseField): IStringStatement; overload;
      function Trim(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimLeft(const aField: TBaseField): IStringStatement; overload;
      function TrimLeft(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimRight(const aField: TBaseField): IStringStatement; overload;
      function TrimRight(const aSubStatement: IStringStatement): IStringStatement; overload;
//      function Left(const aField: TBaseField): IStringStatement; overload;
//      function Left(const aSubStatement: IStringStatement): IStringStatement; overload;
//      function Right(const aField: TBaseField): IStringStatement; overload;
//      function Right(const aSubStatement: IStringStatement): IStringStatement; overload;
//      function Upper(const aField: TBaseField): IStringStatement; overload;
//      function Upper(const aSubStatement: IStringStatement): IStringStatement; overload;
//      function Lower(const aField: TBaseField): IStringStatement; overload;
//      function Lower(const aSubStatement: IStringStatement): IStringStatement; overload;
//      function Replace(const aField: TBaseField; const OldPattern, NewPattern: IStringStatement): IStringStatement; overload;
//      function Replace(const aSubStatement: IStringStatement; const OldPattern, NewPattern: IStringStatement): IStringStatement; overload;
//      function Substring(const aField: TBaseField; const Start, Length: IIntegerStatement): IStringStatement; overload;
//      function Substring(const aSubStatement: IStringStatement; const Start, Length: IIntegerStatement): IStringStatement; overload;
//      // informatie van strings
//      function Length(const aSubStatement: IStringStatement): IIntegerStatement;
//      function CharIndex(const C: Char; const aField: TBaseField; const OffSet: IIntegerStatement = nil): IStringStatement; overload;
//      function CharIndex(const C: Char; const aSubStatement: IStringStatement; const OffSet: IIntegerStatement = nil): IIntegerStatement; overload;
//      // bewerkingen op getallen
//      function Floor(const aField: TBaseField): IIntegerStatement; overload;
//      function Floor(const aSubStatement: IFloatStatement): IIntegerStatement; overload;
//      function Ceiling(const aField: TBaseField): IIntegerStatement; overload;
//      function Ceiling(const aSubStatement: IFloatStatement): IIntegerStatement; overload;
      function Abs(const aField: TBaseField): IFloatStatement; overload;
      function Abs(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Round(const aField: TBaseField; const Precision: Integer): IIntegerStatement; overload;
      function Round(const aSubStatement: IFloatStatement; const Precision: Integer): IIntegerStatement; overload;
//      //Bewerkingen van DateTime
      function DateOnly(const aField: TBaseField): IDateStatement; overload;
      function DateOnly(const aSubStatement: IDateTimeStatement): IDateStatement; overload;
//      //informatie van DateTime velden
//      function Day(const aField: TBaseField): IIntegerStatement; overload;
//      function Day(const aSubStatement: IStatement): IIntegerStatement; overload;
//      function Month(const aField: TBaseField): IIntegerStatement; overload;
//      function Month(const aSubStatement: IStatement): IIntegerStatement; overload;
//      function Year(const aField: TBaseField): IIntegerStatement; overload;
//      function Year(const aSubStatement: IStatement): IIntegerStatement; overload;
//      function Between(const aField: TBaseField; StartDate, EndDate: TDateTime): ICondition; overload;
//      function Between(const aSubStatement: IStatement; StartDate, EndDate: TDateTime): ICondition; overload;

      procedure SetCustomSQL(const aSQL: string; Fields: array of TBaseField);
   end;

   ICaseEnd = interface
      function CaseEnd: IStatement;
   end;

   ICaseNext = interface(ICaseEnd)
      function When(const aValue: Variant): ICaseThen;
      function CaseElse(const aValue: Variant): IStatement;
   end;

   ICaseThen = interface
      function CaseCompareThen(const aValue: Variant): ICaseNext; overload;
      function CaseCompareThen(const aField: TBaseField): ICaseNext; overload;
      function CaseCompareThen(const aSubStatement: IStatementBase): ICaseNext; overload;
   end;

   ICaseWhen = interface
      function ThenEnd(const aValue: Variant): IStatement; overload;
      function ThenEnd(const aField: TBaseField): IStatement; overload;
      function ThenEnd(const aSubStatement: IStatementBase): IStatement; overload;
      function CaseThen(const aValue: Variant): ICaseElseCondition; overload;
      function CaseThen(const aField: TBaseField): ICaseElseCondition; overload;
      function CaseThen(const aSubStatement: IStatementBase): ICaseElseCondition; overload;
   end;

   IConditionCompare = interface
      function OpenBracketCompare: IConditionCompare;
      function Value(const aValue: Variant): IConditionCompareOperator;
      function Field(const aField: TBaseField): IConditionCompareOperator;
      function Statement(const aSubStatement: IStatementBase): IConditionCompareOperator;
   end;

   IConditionCompareOperator = interface
      function Equal: IConditionCompareTo;
      function NotEqual: IConditionCompareTo;
      function GreaterOrEqualThen: IConditionCompareTo;
      function GreaterThen: IConditionCompareTo;
      function SmallerOrEqualThen: IConditionCompareTo;
      function SmallerThen: IConditionCompareTo;
      function IsNull: ICondition;
      function IsNotNull: ICondition;
   end;

   IConditionCompareTo = interface
      function Waar: ICondition;
      function Onwaar: ICondition;
      function CompareValue(const aValue: Variant): ICondition;
      function CompareField(const aField: TBaseField): ICondition;
      function CompareStatement(const aSubStatement: IStatementBase): ICondition;
   end;

   IStatementBase = interface
      function CloseBracketStatement: IStatement;
      function Plus: ICustomSQLType;
   end;

   IStatement = interface(IStatementBase)
      function AsFloat: IFloatStatement;
      function AsString: IStringStatement;
      function AsInteger: IIntegerStatement;
      function AsDateTime: IDateTimeStatement;
      function AsDate: IDateStatement;
   end;

   IStringStatement = interface(IStatementBase)end;
   IIntegerStatement = interface(IStatementBase)
      function Min: ICustomSQLType;
      function Keer: ICustomSQLType;
      function DelenDoor: ICustomSQLType;
      function Modulo: ICustomSQLType;
   end;
   IFloatStatement = interface(IIntegerStatement)end;
   IDateTimeStatement = interface(IFloatStatement)end;
   IDateStatement = interface(IFloatStatement)end;

   ICondition = interface
      function And_: IConditionCompare;
      function Or_: IConditionCompare;
      function CloseBracket: ICondition;
   end;

   ICaseElseCondition = interface(ICaseEnd)
      function CaseEnd(const aValue: Variant): IStatement; overload;
      function CaseEnd(const aField: TBaseField): IStatement; overload;
      function CaseEnd(const aSubStatement: IStatementBase): IStatement; overload;
   end;

   IIsNullNext = interface
      function ThenIsNull(const aValue: Variant): IStatement; overload;
      function ThenIsNull(const aField: TBaseField): IStatement; overload;
      function ThenIsNull(const aSubStatement: IStatementBase): IStatement; overload;
   end;

   ICoalesceNext = interface
      function NextCoalesce(const aValue: Variant): ICoalesceEnd; overload;
      function NextCoalesce(const aField: TBaseField): ICoalesceEnd; overload;
      function NextCoalesce(const aSubStatement: IStatementBase): ICoalesceEnd; overload;
   end;

   ICoalesceEnd = interface(ICoalesceNext)
      function CoalesceEnd: IStatement;
   end;

   TQueryFieldBuilder = class;

   TQueryFieldBuilder = class(TInterfacedObject, IQueryFieldBuilder, ICustomSQLType,
      ICaseNext, ICaseThen, ICaseWhen, ICaseEnd,
      IConditionCompare, IConditionCompareOperator, IConditionCompareTo, ICondition, ICaseElseCondition,
      IStatementBase, IStatement, IStringStatement, IIntegerStatement, IFloatStatement, IDateTimeStatement, IDateStatement,
      IIsNullNext, ICoalesceNext, ICoalesceEnd)
   strict private
      FFields: TFieldList;
      FSQL: string;
      FSubStatements: TList<TQueryFieldBuilder>;
      procedure Clear;
      procedure AddField(const aField: TBaseField);
      procedure AddSQL(const aSQL: string);
      procedure AddSubStatement(const aSub: IStatementBase); overload;
      procedure AddSubStatement(const aSub: ICondition); overload;
      function ConvertTypeToSQl(const aType: TConvertSQLType; const StringSize: Integer): string;
   private
      function GetCustomSQL(const aQuery: IQueryDetails; const WithAlias: Boolean): string;
      procedure AddRequiredFields(var RequiredFields: TFieldArray);
      function DefaultIsNullValue(const aField: TBaseField): string;
      function GetUnformattedSQL: string;
      function Fields: TFieldList;
   public
      constructor Create;
      destructor Destroy; override;

      { IQueryFieldBuilder }
      function New: ICustomSQLType;
      function CurrentFieldCase: ICaseNext;
      function NewSub: ICustomSQLType;
      { ICustomSQLType }
      function CaseFieldOf(const aField: TBaseField): ICaseNext; overload;
      function CaseFieldOf(const aSubStatement: IStatementBase): ICaseNext; overload;
      function CaseWhen(const aCondition: ICondition): ICaseWhen;
      function FieldCompare(const aField: TBaseField; const WithIsNull: Boolean = False): IConditionCompareOperator;
      function StatementCompare(const aSubStatement: IStatementBase): IConditionCompareOperator;
      function FieldAsStatement(const aField: TBaseField; const WithIsNull: Boolean = False): IStatement;
      function VariantAsStatement(const aValue: Variant): IStatement;

      function TrimmedFieldAndSpace(const aField: TBaseField; const WithIsNull: Boolean = True): IStringStatement;
      function Trim(const aField: TBaseField): IStringStatement; overload;
      function Trim(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimLeft(const aField: TBaseField): IStringStatement; overload;
      function TrimLeft(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimRight(const aField: TBaseField): IStringStatement; overload;
      function TrimRight(const aSubStatement: IStringStatement): IStringStatement; overload;

      function Sum(const aField: TBaseField): IFloatStatement; overload;
      function Sum(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Min(const aField: TBaseField): IFloatStatement; overload;
      function Min(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Max(const aField: TBaseField): IFloatStatement; overload;
      function Max(const aSubStatement: IStatementBase): IFloatStatement; overload;

      function Abs(const aField: TBaseField): IFloatStatement; overload;
      function Abs(const aSubStatement: IFloatStatement): IFloatStatement; overload;

      function IsNull(const aField: TBaseField): IIsNullNext; overload;
      function IsNull(const aSubStatement: IStatementBase): IIsNullNext; overload;
      function Coalesce(const aField: TBaseField): ICoalesceNext; overload;
      function Coalesce(const aSubStatement: IStatementBase): ICoalesceNext; overload;
      function ConvertTo(const aType: TConvertSQLType; const aField: TBaseField; const StringSize: Integer = 0): IStatement; overload;
      function ConvertTo(const aType: TConvertSQLType; const aSubStatement: IStatementBase; const StringSize: Integer = 0): IStatement; overload;
      function Round(const aField: TBaseField; const Precision: Integer): IIntegerStatement; overload;
      function Round(const aSubStatement: IFloatStatement; const Precision: Integer): IIntegerStatement; overload;
      function DateOnly(const aField: TBaseField): IDateStatement; overload;
      function DateOnly(const aSubStatement: IDateTimeStatement): IDateStatement; overload;
      function OpenBracket: ICustomSQLType;
      procedure SetCustomSQL(const aSQL: string; Fields: array of TBaseField);
      { ICaseNext }
      function When(const aValue: Variant): ICaseThen;
      function CaseElse(const aValue: Variant): IStatement;
      { ICaseThen }
      function CaseCompareThen(const aValue: Variant): ICaseNext; overload;
      function CaseCompareThen(const aField: TBaseField): ICaseNext; overload;
      function CaseCompareThen(const aSubStatement: IStatementBase): ICaseNext; overload;
      { ICaseWhen }
      function ThenEnd(const aValue: Variant): IStatement; overload;
      function ThenEnd(const aField: TBaseField): IStatement; overload;
      function ThenEnd(const aSubStatement: IStatementBase): IStatement; overload;
      function CaseThen(const aValue: Variant): ICaseElseCondition; overload;
      function CaseThen(const aField: TBaseField): ICaseElseCondition; overload;
      function CaseThen(const aSubStatement: IStatementBase): ICaseElseCondition; overload;
      { IConditionCompare }
      function OpenBracketCompare: IConditionCompare;
      function Value(const aValue: Variant): IConditionCompareOperator;
      function Field(const aField: TBaseField): IConditionCompareOperator;
      function Statement(const aSubStatement: IStatementBase): IConditionCompareOperator;
      { IConditionCompareOperator }
      function Equal: IConditionCompareTo;
      function NotEqual: IConditionCompareTo;
      function GreaterOrEqualThen: IConditionCompareTo;
      function GreaterThen: IConditionCompareTo;
      function SmallerOrEqualThen: IConditionCompareTo;
      function SmallerThen: IConditionCompareTo;
      function IsNull: ICondition; overload;
      function IsNotNull: ICondition; overload;
      { IConditionCompare }
      function Waar: ICondition;
      function Onwaar: ICondition;
      function CompareValue(const aValue: Variant): ICondition;
      function CompareField(const aField: TBaseField): ICondition;
      function CompareStatement(const aSubStatement: IStatementBase): ICondition;
      { IStatementBase }
      function Plus: ICustomSQLType;
      function CloseBracketStatement: IStatement;
      { IStatement }
      function AsFloat: IFloatStatement;
      function AsString: IStringStatement;
      function AsInteger: IIntegerStatement;
      function AsDateTime: IDateTimeStatement;
      function AsDate: IDateStatement;
      { IFloatStatement }
      function Min: ICustomSQLType; overload;
      function Keer: ICustomSQLType;
      function DelenDoor: ICustomSQLType;
      function Modulo: ICustomSQLType;
      { ICondition }
      function And_: IConditionCompare;
      function Or_: IConditionCompare;
      function CloseBracket: ICondition;
      { ICaseEnd }
      function CaseEnd: IStatement; overload;
      { IElseCondition }
      function CaseEnd(const aValue: Variant): IStatement; overload;
      function CaseEnd(const aField: TBaseField): IStatement; overload;
      function CaseEnd(const aSubStatement: IStatementBase): IStatement; overload;
      { IIsNullNext }
      function ThenIsNull(const aValue: Variant): IStatement; overload;
      function ThenIsNull(const aField: TBaseField): IStatement; overload;
      function ThenIsNull(const aSubStatement: IStatementBase): IStatement; overload;
      { ICoalesceNext }
      function NextCoalesce(const aValue: Variant): ICoalesceEnd; overload;
      function NextCoalesce(const aField: TBaseField): ICoalesceEnd; overload;
      function NextCoalesce(const aSubStatement: IStatementBase): ICoalesceEnd; overload;
      { ICoalesceEnd }
      function CoalesceEnd: IStatement;
   end;

   TCustomSQLField = class abstract(TBaseField)
   protected
      FCustomSQLBuilder: IQueryFieldBuilder;
   public
      procedure AfterConstruction; override;
      destructor Destroy; override;

      property ValueAsVariant : Variant   read GetValueAsVariant;  // read-only maken

      property CustomSQL: IQueryFieldBuilder read FCustomSQLBuilder;
      function GetCustomSQL(const aQuery: IQueryDetails; const WithAlias: Boolean): string;
      function GetRequiredFields: TFieldArray;
   end;

   TSQLStringField = class(TCustomSQLField)
   private
      function GetValueOrEmptyString: string;
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedString: string read GetValueAsString;
      property ValueOrEmptyString: string read GetValueOrEmptyString;
      function IsEmptyString: Boolean;
   end;

   TSQLIntegerField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedInteger: Integer read GetValueAsInteger;
   end;

   TSQLDoubleField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedDouble: Double read GetValueAsDouble;
   end;

   TSQLCurrencyField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedCurrency: Currency read GetValueAsCurrency;
   end;

   TSQLDateTimeField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedDateTime: TDateTime read GetValueAsDateTime;
   end;

   TSQLBooleanField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedBoolean: Boolean read GetValueAsBoolean;
   end;

   TDisplayEnumfField<T: TBaseEnumField> = class(TSQLStringField)
   public
      procedure AfterConstruction; override;
   end;

   function SQL_Vandaag_Field: TSQLDateTimeField;
   function SQL_Nu_Field: TSQLDateTimeField;
   function SQL_Vandaag_Plus_1_Field: TSQLDateTimeField;
   function SQL_Nu_Plus_1_Field: TSQLDateTimeField;
   function Dummy: TSQLIntegerField;

   function GetFieldTag(const Index: Integer): string;
   function VariantToSQLString(const aValue: Variant): string;

   function AddCustomStringField(DataRecord: TDataRecord; const Name: string): TSQLStringField;
   function AddCustomIntegerField(DataRecord: TDataRecord; const Name: string): TSQLIntegerField;
   function AddCustomDoubleField(DataRecord: TDataRecord; const Name: string): TSQLDoubleField;
   function AddCustomDateTimeField(DataRecord: TDataRecord; const Name: string): TSQLDateTimeField;
   function AddCustomBooleanField(DataRecord: TDataRecord; const Name: string): TSQLBooleanField;
   procedure RemoveCustomSQLField(Field: TCustomSQLField; DataRecord: TDataRecord; const DestroyField: Boolean = True);

implementation

uses StrUtils, SysUtils, Variants, UltraStringUtils, DB.SQLBuilder;

type
   // Globaal datarecord met 'velden' zonder tabel
   TDatabaseSQLVelden = class(TMultiDataRecord)
   private
      function GetSQLDateField(index: Integer): TSQLDateTimeField;
      function GetSQLIntegerField(index: Integer): TSQLIntegerField;
   public
      procedure AfterConstruction; override;
      property  SQL_Now_Field             : TSQLDateTimeField            index   0 read GetSQLDateField;
      property  SQL_TodayField            : TSQLDateTimeField            index   1 read GetSQLDateField;
      property  SQL_Now_Plus_1_Field      : TSQLDateTimeField            index   2 read GetSQLDateField;
      property  SQL_Today_Plus_1Field     : TSQLDateTimeField            index   3 read GetSQLDateField;
      property  Dummy                     : TSQLIntegerField             index   4 read GetSQLIntegerField;
   end;

var GDatabaseSQLVelden: TDatabaseSQLVelden;
    DatabaseCompatLevel: Integer = 2008; // zolang MW dit nog niet kan bepalen

const
   FieldTag                = '$f%d$';
   SubTag                  = '$s%d$';

   SQL_Or                  = 'Or';
   SQL_And                 = 'And';
   SQL_End                 = 'end';
   SQL_Then                = 'then';
   SQL_When                = 'when';
   SQL_Else                = 'else';
   SQL_Case                = 'case';
   SQL_LTrim               = 'LTrim(';
   SQL_RTrim               = 'RTrim(';
   SQL_OpenBracket         = '(';
   SQL_CloseBracket        = ')';
   SQL_Plus                = '+';
   SQL_Min                 = '-';
   SQL_Keer                = '*';
   SQL_DelenDoor           = '/';
   SQL_Modulo              = '%';
   SQL_Spatie              = ' ';
   SQL_SpatieText          = ''' ''';
   SQL_Equal               = '=';
   SQL_Komma               = ',';
   SQL_NotEqual            = '<>';
   SQL_GreaterOrEqualThen  = '>=';
   SQL_GreaterThen         = '>';
   SQL_SmallerOrEqualThen  = '<=';
   SQL_SmallerThen         = '<';
   SQL_Is                  = 'is';
   SQL_Not                 = 'not';
   SQL_Null                = 'null';
   SQL_Convert             = 'Convert(';
   SQL_IsNull              = 'IsNull(';
   SQL_Coalesce            = 'Coalesce(';
   SQL_VarcharStr          = 'Varchar';
   SQL_Date                = 'Date';
   SQL_DateTime            = 'DateTime';
   SQL_Bit                 = 'Bit';
   SQL_Float               = 'Float';
   SQL_Integer             = 'Int';
   SQL_GetdDate            = 'GetDate()';
   SQL_DateOnlyStr         = 'Dbo.DateOnly(';
   SQL_Enter               = 'Char(13)';
   SQL_Left                = 'Left(';
   SQL_Right               = 'Right';
   SQL_CharIndex           = 'CharIndex';
   SQL_Day                 = 'Day(';
   SQL_Month               = 'Month(';
   SQL_Year                = 'Year(';
   SQL_Abs                 = 'Abs(';
   SQL_Floor               = 'Floor(';
   SQL_Ceiling             = 'Ceiling(';
   SQL_Length              = 'Len(';
   SQL_Replace             = 'Replace(';
   SQL_Lower               = 'Lower(';
   SQL_Upper               = 'Upper';
   SQL_Substring           = 'Substring(';
   SQL_Between             = 'Between';
   SQL_Round               = 'Round(';
   SQL_Sum                 = 'Sum(';
   SQL_Minimum             = 'Min(';
   SQL_Maximum             = 'Max(';


function AddExtraField(DataRecord: TDataRecord; const Name: string; const aFieldType: TFieldType): TCustomSQLField;
var Index: Integer;
    TableFieldMeta: TBaseTableAttribute;
    FieldMeta: TTypedMetaField;
begin
   Index := DataRecord.Count;
   TableFieldMeta := TBaseTableAttribute.Create(nil);
   FieldMeta := TTypedMetaField.Create(Name, aFieldType, false, '', 0, 0);
   TableFieldMeta.FieldMetaData := FieldMeta;
   case aFieldType of
      ftFieldString:                Result := TSQLStringField.Create  (Name, DataRecord, Index, TableFieldMeta);
      ftFieldBoolean:               Result := TSQLBooleanField.Create (Name, DataRecord, Index, TableFieldMeta);
      ftFieldDouble:                Result := TSQLDoubleField.Create  (Name, DataRecord, Index, TableFieldMeta);
      ftFieldInteger, ftFieldID:    Result := TSQLIntegerField.Create (Name, DataRecord, Index, TableFieldMeta);
      ftFieldDateTime:              Result := TSQLDateTimeField.Create(Name, DataRecord, Index, TableFieldMeta);
   else
      Result := TCustomSQLField.Create(Name, DataRecord, Index, TableFieldMeta);
   end;

   DataRecord.Insert(Index, Result);
   DataRecord.AllocFieldValues;
end;

function AddCustomStringField(DataRecord: TDataRecord; const Name: string): TSQLStringField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldString) as TSQLStringField;
end;

function AddCustomIntegerField(DataRecord: TDataRecord; const Name: string): TSQLIntegerField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldInteger) as TSQLIntegerField;
end;

function AddCustomDoubleField(DataRecord: TDataRecord; const Name: string): TSQLDoubleField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldDouble) as TSQLDoubleField;
end;

function AddCustomDateTimeField(DataRecord: TDataRecord; const Name: string): TSQLDateTimeField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldDateTime) as TSQLDateTimeField;
end;

function AddCustomBooleanField(DataRecord: TDataRecord; const Name: string): TSQLBooleanField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldBoolean) as TSQLBooleanField;
end;

procedure RemoveCustomSQLField(Field: TCustomSQLField; DataRecord: TDataRecord; const DestroyField: Boolean = True);
var Index: Integer;
begin
   Index := DataRecord.IndexOf(Field);
   if (Index >= 0) then
   begin
      DataRecord.Delete(Index);
      DataRecord.AllocFieldValues;
   end;
   if DestroyField then
      FreeAndNil(Field);
end;

   { Global }

function SQL_Varchar(Size: Integer): string;
begin
   Result := Format(SQL_VarcharStr+SQL_OpenBracket+'%d'+SQL_CloseBracket,[Size]);
end;

function SQL_DateOnly: string;
begin
   // Dit moet vervangen worden door UltraUtils.DateOnly (Die vraagt DatabaseCompatLevel via HulpQry op)
   Result := ifthen(DatabaseCompatLevel >= 2008, SQL_Convert+SQL_Date+SQL_Komma, SQL_DateOnlyStr)
end;

function SQL_Nu_Field: TSQLDateTimeField;
begin
   Result := GDatabaseSQLVelden.SQL_Now_Field;
end;

function SQL_Vandaag_Field: TSQLDateTimeField;
begin
   Result := GDatabaseSQLVelden.SQL_TodayField;
end;

function SQL_Vandaag_Plus_1_Field: TSQLDateTimeField;
begin
   Result := GDatabaseSQLVelden.SQL_Today_Plus_1Field;
end;

function SQL_Nu_Plus_1_Field: TSQLDateTimeField;
begin
   Result := GDatabaseSQLVelden.SQL_Now_Plus_1_Field;
end;

function Dummy: TSQLIntegerField;
begin
   Result := GDatabaseSQLVelden.Dummy;
end;

function GetFieldTag(const Index: Integer): string;
begin
   Result := Format(FieldTag, [Index]);
end;

function VariantToSQLString(const aValue: Variant): string;
begin
   case VarType(aValue) of
      varOleStr, varString, varUString:
         Result := QuotedStr(aValue);
      varDate:
         Result := QryDateToStr(aValue);
      varNull:
         Result := 'null';
      varBoolean:
         Result := QryBoolToStr(aValue);
   else
      Result := aValue;
   end;
end;

   { TQueryFieldBuilder }

   { Public }
constructor TQueryFieldBuilder.Create;
begin
   FFields := TFieldList.Create;
   FSubStatements := TList<TQueryFieldBuilder>.Create;
end;

destructor TQueryFieldBuilder.Destroy;
begin
   Clear;
   FSubStatements.Free;
   FFields.Free;
   inherited;
end;

   { strict Private }

procedure TQueryFieldBuilder.Clear;
var Sub: TQueryFieldBuilder;
begin
   for Sub in FSubStatements do
   begin
      Dec(Sub.FRefCount);
      if (Sub.FRefCount = 0) then
         Sub.Free;
   end;
   FSQL := '';
   FFields.Clear;
   FSubStatements.Clear;
end;

function TQueryFieldBuilder.DefaultIsNullValue(const aField: TBaseField): string;
begin
   case aField.FieldType of
      ftFieldID,
      ftFieldBoolean,
      ftFieldDouble,
      ftFieldInteger,
      ftFieldDateTime: Result := '0';
   else
       Result := '';
   end;
end;

procedure TQueryFieldBuilder.AddField(const aField: TBaseField);
begin
   FFields.Add(aField);
   AddSQL(GetFieldTag(FFields.Count - 1));
end;

procedure TQueryFieldBuilder.AddSQL(const aSQL: string);
begin
   if (FSQL <> '') then
      FSQL := FSQL + SQL_Spatie;
   FSQL := FSQL + aSQL;
end;

procedure TQueryFieldBuilder.AddSubStatement(const aSub: IStatementBase);
begin
   FSubStatements.Add(aSub as TQueryFieldBuilder);
   AddSQL(Format(SubTag, [FSubStatements.Count - 1]));
end;

procedure TQueryFieldBuilder.AddSubStatement(const aSub: ICondition);
begin
   FSubStatements.Add(aSub as TQueryFieldBuilder);
   AddSQL(Format(SubTag, [FSubStatements.Count - 1]));
end;

function TQueryFieldBuilder.ConvertTypeToSQl(const aType: TConvertSQLType; const StringSize: Integer): string;
var TypeStr: string;
begin
   Result := '';
   TypeStr := '';
   case atype of
      csDate: TypeStr := SQL_Date;
      csDateTime: TypeStr := SQL_DateTime;
      csString:
      begin
         if (StringSize = 0) then
            TypeStr :=  SQL_VarcharStr
         else
            TypeStr := SQL_Varchar(StringSize);
      end;
      csBit: TypeStr := SQL_Bit;
      csFloat: TypeStr := SQL_Float;
      csInt:  TypeStr := SQL_Integer;
   end;
   if (TypeStr <> '') then
      Result := Format(SQL_Convert+'%s'+SQL_Komma,[TypeStr]);
end;

   { Private }
function TQueryFieldBuilder.GetCustomSQL(const aQuery: IQueryDetails; const WithAlias: Boolean): string;
var
   i: Integer;
begin
   Result := GetUnformattedSQL;
   Assert(Result <> '');

   for i := 0 to Fields.Count - 1 do
      Result := StringReplace(Result, GetFieldTag(i), TSQLBuilder.GetFieldSQLWithAlias(aQuery, Fields[i], WithAlias), [rfReplaceAll]);

   for i := 0 to FSubStatements.Count - 1 do
      Result := StringReplace(Result, Format(SubTag, [i]), FSubStatements[i].GetCustomSQL(aQuery, WithAlias), [rfReplaceAll]);
end;

procedure TQueryFieldBuilder.AddRequiredFields(var RequiredFields: TFieldArray);
var F: TBaseField;
    Sub: TQueryFieldBuilder;
begin
   for F in Fields do
      AddFieldToArray(F, RequiredFields);
   for Sub in FSubStatements do
      Sub.AddRequiredFields(RequiredFields);
end;

function TQueryFieldBuilder.Fields: TFieldList;
begin
   Result := FFields;
end;

function TQueryFieldBuilder.GetUnformattedSQL: string;
begin
   Result := FSQL;
end;

      { IQueryFieldBuilder }
function TQueryFieldBuilder.New: ICustomSQLType;
begin
   Result := Self;
   Clear;
end;

function TQueryFieldBuilder.CurrentFieldCase: ICaseNext;
begin
   Result := Self;
end;

function TQueryFieldBuilder.NewSub: ICustomSQLType;
var
   Sub: TQueryFieldBuilder;
begin
   Sub := TQueryFieldBuilder.Create;
   Result := Sub.New;
   Inc(Sub.FRefCount);
end;

{ ICustomSQLType }
function TQueryFieldBuilder.CaseFieldOf(const aField: TBaseField): ICaseNext;
begin
   Result := Self;
   AddSQL(SQL_Case);
   AddField(aField);
end;

function TQueryFieldBuilder.CaseFieldOf(const aSubStatement: IStatementBase): ICaseNext;
begin
   Result := Self;
   AddSQL(SQL_Case);
   AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CaseWhen(const aCondition: ICondition): ICaseWhen;
begin
   Result := Self;
   AddSQL(SQL_Case + SQL_Spatie + SQL_When);
   AddSubStatement(aCondition);
end;

function TQueryFieldBuilder.FieldCompare(const aField: TBaseField; const WithIsNull: Boolean = False): IConditionCompareOperator;
begin
   Result := Self;
   OpenBracket;
   if WithIsNull then
      IsNull(aField).ThenIsNull(DefaultIsNullValue(aField))
   else
      AddField(aField);
end;

function TQueryFieldBuilder.StatementCompare(const aSubStatement: IStatementBase): IConditionCompareOperator;
begin
   Result := Self;
   OpenBracket;
   AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.FieldAsStatement(const aField: TBaseField; const WithIsNull: Boolean = False): IStatement;
begin
   Result := Self;
   if WithIsNull then
      IsNull(aField).ThenIsNull(DefaultIsNullValue(aField))
   else
      AddField(aField);
end;

function TQueryFieldBuilder.VariantAsStatement(const aValue: Variant): IStatement;
begin
   Result := Self;
   AddSQL(VariantToSQLString(aValue));
end;

function TQueryFieldBuilder.TrimmedFieldAndSpace(const aField: TBaseField; const WithIsNull: Boolean = True): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_LTrim);
   if WithIsNull then
      IsNull(aField).ThenIsNull(DefaultIsNullValue(aField))
   else
      AddField(aField);
   AddSQL(SQL_Plus + SQL_SpatieText + SQL_CloseBracket);
end;

function TQueryFieldBuilder.Trim(const aField: TBaseField): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_LTrim+SQL_RTrim);
   AddField(aField);
   AddSQL(SQL_CloseBracket+SQL_CloseBracket);
end;

function TQueryFieldBuilder.Trim(const aSubStatement: IStringStatement): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_LTrim+SQL_RTrim);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket+SQL_CloseBracket);
end;

function TQueryFieldBuilder.TrimLeft(const aField: TBaseField): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_LTrim);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.TrimLeft(const aSubStatement: IStringStatement): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_LTrim);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.TrimRight(const aField: TBaseField): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_RTrim);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.TrimRight(const aSubStatement: IStringStatement): IStringStatement;
begin
   Result := Self;
   AddSQL(SQL_RTrim);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

procedure TQueryFieldBuilder.SetCustomSQL(const aSQL: string; Fields: array of TBaseField);
begin
   Clear;
   FSQL := aSQL;
   FFields.AddRange(Fields);
end;

      { ICaseNext }
function TQueryFieldBuilder.When(const aValue: Variant): ICaseThen;
begin
   Result := Self;
   AddSQL(SQL_When + SQL_Spatie + VariantToSQLString(aValue));
end;

function TQueryFieldBuilder.CaseElse(const aValue: Variant): IStatement;
begin
   Result := Self;
   AddSQL(SQL_Else + SQL_Spatie + VariantToSQLString(aValue)+ SQL_Spatie + SQL_End);
end;

      { ICaseWhen }
function TQueryFieldBuilder.CaseCompareThen(const aValue: Variant): ICaseNext;
begin
   Result := Self;
   AddSQL(SQL_Then + SQL_Spatie + VariantToSQLString(aValue));
end;

function TQueryFieldBuilder.CaseCompareThen(const aField: TBaseField): ICaseNext;
begin
   Result := Self;
   AddSQL(SQL_Then);
   AddField(aField);
end;

function TQueryFieldBuilder.CaseCompareThen(const aSubStatement: IStatementBase): ICaseNext;
begin
   Result := Self;
   AddSQL(SQL_Then);
   AddSubStatement(aSubStatement);
end;

      { ICaseThenEnd }
function TQueryFieldBuilder.ThenEnd(const aValue: Variant): IStatement;
begin
   Result := Self;
   CaseThen(aValue);
   AddSQL(SQL_End);
end;

function TQueryFieldBuilder.ThenEnd(const aField: TBaseField): IStatement;
begin
   Result := Self;
   CaseThen(aField);
   AddSQL(SQL_End);
end;

function TQueryFieldBuilder.ThenEnd(const aSubStatement: IStatementBase): IStatement;
begin
   Result := Self;
   CaseThen(aSubStatement);
   AddSQL(SQL_End);
end;

function TQueryFieldBuilder.ThenIsNull(const aValue: Variant): IStatement;
begin
   Result := Self;
   AddSQL(VariantToSQLString(aValue));
   CloseBracket;
end;

function TQueryFieldBuilder.ThenIsNull(const aField: TBaseField): IStatement;
begin
   Result := Self;
   AddField(aField);
   CloseBracket
end;

function TQueryFieldBuilder.ThenIsNull(const aSubStatement: IStatementBase): IStatement;
begin
   Result := Self;
   AddSubStatement(aSubStatement);
   CloseBracket;
end;

function TQueryFieldBuilder.CaseThen(const aValue: Variant): ICaseElseCondition;
begin
   Result := Self;
   AddSQL(SQL_Then+ SQL_Spatie + VariantToSQLString(aValue));
end;

function TQueryFieldBuilder.CaseThen(const aField: TBaseField): ICaseElseCondition;
begin
   Result := Self;
   AddSQL(SQL_Then);
   AddField(aField);
end;

function TQueryFieldBuilder.CaseThen(const aSubStatement: IStatementBase): ICaseElseCondition;
begin
   Result := Self;
   AddSQL(SQL_Then);
   AddSubStatement(aSubStatement);
end;

      { IConditionCompare }
function TQueryFieldBuilder.OpenBracketCompare: IConditionCompare;
begin
   Result := Self;
   AddSQL(SQL_OpenBracket);
end;

function TQueryFieldBuilder.Value(const aValue: Variant): IConditionCompareOperator;
begin
   Result := Self;
   AddSQL(VariantToSQLString(aValue));
end;

function TQueryFieldBuilder.Field(const aField: TBaseField): IConditionCompareOperator;
begin
   Result := Self;
   AddField(aField);
end;

function TQueryFieldBuilder.Statement(const aSubStatement: IStatementBase): IConditionCompareOperator;
begin
   Result := Self;
   AddSubStatement(aSubStatement);
end;

      { IConditionCompareOperator }
function TQueryFieldBuilder.Equal: IConditionCompareTo;
begin
   Result := Self;
   AddSQL(SQL_Equal);
end;

function TQueryFieldBuilder.NotEqual: IConditionCompareTo;
begin
   Result := Self;
   AddSQL(SQL_NotEqual);
end;

function TQueryFieldBuilder.GreaterOrEqualThen: IConditionCompareTo;
begin
   Result := Self;
   AddSQL(SQL_GreaterOrEqualThen);
end;

function TQueryFieldBuilder.GreaterThen: IConditionCompareTo;
begin
   Result := Self;
   AddSQL(SQL_GreaterThen);
end;

function TQueryFieldBuilder.Sum(const aField: TBaseField): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Sum);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Sum(const aSubStatement: IStatementBase): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Sum);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Min(const aField: TBaseField): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Minimum);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Min(const aSubStatement: IStatementBase): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Minimum);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Max(const aField: TBaseField): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Maximum);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Max(const aSubStatement: IStatementBase): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Maximum);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Abs(const aField: TBaseField): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Abs);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Abs(const aSubStatement: IFloatStatement): IFloatStatement;
begin
   Result := Self;
   AddSQL(SQL_Abs);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.IsNull(const aField: TBaseField): IIsNullNext;
begin
   Result := Self;
   AddSQL(SQL_IsNull);
   AddField(aField);
   AddSQL(SQL_Komma);
end;

function TQueryFieldBuilder.IsNull(const aSubStatement: IStatementBase): IIsNullNext;
begin
   Result := Self;
   AddSQL(SQL_IsNull);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_Komma);
end;

function TQueryFieldBuilder.SmallerOrEqualThen: IConditionCompareTo;
begin
   Result := Self;
   AddSQL(SQL_SmallerOrEqualThen);
end;

function TQueryFieldBuilder.SmallerThen: IConditionCompareTo;
begin
   Result := Self;
   AddSQL(SQL_SmallerThen);
end;

function TQueryFieldBuilder.IsNull: ICondition;
begin
   Result := Self;
   AddSQL(SQL_Is + SQL_Spatie + SQL_Null + SQL_CloseBracket);
end;

function TQueryFieldBuilder.IsNotNull: ICondition;
begin
   Result := Self;
   AddSQL(SQL_Is + SQL_Spatie + SQL_Not + SQL_Spatie + SQL_Null + SQL_CloseBracket)
end;

      { IConditionCompare }
function TQueryFieldBuilder.Coalesce(const aField: TBaseField): ICoalesceNext;
begin
   Result := Self;
   AddSQL(SQL_Coalesce);
   AddField(aField);
   AddSQL(SQL_Komma);
end;

function TQueryFieldBuilder.Coalesce(const aSubStatement: IStatementBase): ICoalesceNext;
begin
   Result := Self;
   AddSQL(SQL_Coalesce);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_Komma);
end;

function TQueryFieldBuilder.ConvertTo(const aType: TConvertSQLType; const aField: TBaseField; const StringSize: Integer = 0): IStatement;
begin
   Result := Self;
   AddSQL(ConvertTypeToSQl(aType, StringSize));
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.ConvertTo(const aType: TConvertSQLType; const aSubStatement: IStatementBase; const StringSize: Integer = 0): IStatement;
begin
   Result := Self;
   AddSQL(ConvertTypeToSQl(aType, StringSize));
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.Round(const aField: TBaseField; const Precision: Integer): IIntegerStatement;
begin
   Result := Self;
   AddSQL(SQL_Round);
   AddField(aField);
   AddSQL(SQL_Komma+IntToStr(Precision)+SQL_CloseBracket);
end;

function TQueryFieldBuilder.Round(const aSubStatement: IFloatStatement; const Precision: Integer): IIntegerStatement;
begin
   Result := Self;
   AddSQL(SQL_Round);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_Komma+IntToStr(Precision)+SQL_CloseBracket);
end;

function TQueryFieldBuilder.DateOnly(const aField: TBaseField): IDateStatement;
begin
   Result := Self;
   AddSQL(SQL_DateOnly);
   AddField(aField);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.DateOnly(const aSubStatement: IDateTimeStatement): IDateStatement;
begin
   Result := Self;
   AddSQL(SQL_DateOnly);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_CloseBracket);
end;

function TQueryFieldBuilder.OpenBracket: ICustomSQLType;
begin
   Result := Self;
   AddSQL(SQL_OpenBracket);
end;

function TQueryFieldBuilder.Waar: ICondition;
begin
   Result := CompareValue(1);
end;

function TQueryFieldBuilder.Onwaar: ICondition;
begin
   Result := CompareValue(0);
end;

function TQueryFieldBuilder.CompareField(const aField: TBaseField): ICondition;
begin
   Result := Self;
   AddField(aField);
   CloseBracket;
end;

function TQueryFieldBuilder.CompareValue(const aValue: Variant): ICondition;
begin
   Result := Self;
   AddSQL(VariantToSQLString(aValue));
   CloseBracket;
end;

function TQueryFieldBuilder.CompareStatement(const aSubStatement: IStatementBase): ICondition;
begin
   Result := Self;
   AddSubStatement(aSubStatement);
   CloseBracket;
end;

      { IStatementBase }
function TQueryFieldBuilder.Plus: ICustomSQLType;
begin
   Result := Self;
   AddSQL(SQL_Plus);
end;

function TQueryFieldBuilder.CloseBracketStatement: IStatement;
begin
   Result := Self;
   AddSQL(SQL_CloseBracket);
end;

      { IStatement }
function TQueryFieldBuilder.AsFloat: IFloatStatement;
begin
   Result := Self;
end;

function TQueryFieldBuilder.AsString: IStringStatement;
begin
   Result := Self;
end;

function TQueryFieldBuilder.AsInteger: IIntegerStatement;
begin
   Result := Self;
end;

function TQueryFieldBuilder.AsDateTime: IDateTimeStatement;
begin
   Result := Self;
end;

function TQueryFieldBuilder.AsDate: IDateStatement;
begin
   Result := Self;
end;

      { IFloatStatement }
function TQueryFieldBuilder.Min: ICustomSQLType;
begin
   Result := Self;
   AddSQL(SQL_Min);
end;

function TQueryFieldBuilder.Keer: ICustomSQLType;
begin
   Result := Self;
   AddSQL(SQL_Keer);
end;

function TQueryFieldBuilder.DelenDoor: ICustomSQLType;
begin
   Result := Self;
   AddSQL(SQL_DelenDoor);
end;

function TQueryFieldBuilder.Modulo: ICustomSQLType;
begin
   Result := Self;
   AddSQL(SQL_Modulo);
end;

      { ICondition }
function TQueryFieldBuilder.Or_: IConditionCompare;
begin
   Result := Self;
   AddSQL(SQL_Or);
   OpenBracket;
end;

function TQueryFieldBuilder.And_: IConditionCompare;
begin
   Result := Self;
   AddSQL(SQL_And);
   OpenBracket;
end;

function TQueryFieldBuilder.CloseBracket: ICondition;
begin
   Result := Self;
   AddSQL(SQL_CloseBracket);
end;

      { ICaseEnd }
function TQueryFieldBuilder.CaseEnd: IStatement;
begin
   Result := Self;
   AddSQL(SQL_End);
end;

      { IElseCondition }
function TQueryFieldBuilder.CaseEnd(const aValue: Variant): IStatement;
begin
   Result := Self;
   AddSQL(SQL_Else+ SQL_Spatie + VariantToSQLString(aValue) + SQL_Spatie +SQL_End);
end;

function TQueryFieldBuilder.CaseEnd(const aField: TBaseField): IStatement;
begin
   Result := Self;
   AddSQL(SQL_Else);
   AddField(aField);
   AddSQL(SQL_End);
end;

function TQueryFieldBuilder.CaseEnd(const aSubStatement: IStatementBase): IStatement;
begin
   Result := Self;
   AddSQL(SQL_Else);
   AddSubStatement(aSubStatement);
   AddSQL(SQL_End);
end;

      { ICoalesceNext }
function TQueryFieldBuilder.NextCoalesce(const aValue: Variant): ICoalesceEnd;
begin
   Result := Self;
   AddSQL(VariantToSQLString(aValue) + SQL_Komma);
end;

function TQueryFieldBuilder.NextCoalesce(const aField: TBaseField): ICoalesceEnd;
begin
   Result := Self;
   AddField(aField);
   AddSQL(SQL_Komma);
end;

function TQueryFieldBuilder.NextCoalesce(const aSubStatement: IStatementBase): ICoalesceEnd;
begin
   Result := Self;
   AddSubStatement(aSubStatement);
   AddSQL(SQL_Komma);
end;

      { CoalesceEnd }
function TQueryFieldBuilder.CoalesceEnd: IStatement;
begin
   Result := Self;
   // laatste , eraf halen en ) ervoor in de plaats zetten
   FSQL := RTrim(FSQL, SQL_Komma)+SQL_CloseBracket;
end;

{ TCustomSQLField }

procedure TCustomSQLField.AfterConstruction;
begin
   inherited;
   FCustomSQLBuilder := TQueryFieldBuilder.Create;
end;

destructor TCustomSQLField.Destroy;
begin
   FCustomSQLBuilder := nil;
   inherited;
end;

function TCustomSQLField.GetCustomSQL(const aQuery: IQueryDetails; const WithAlias: Boolean): string;
begin
   Result := CustomSQL.GetCustomSQL(aQuery, WithAlias);
end;

function TCustomSQLField.GetRequiredFields: TFieldArray;
begin
   SetLength(Result, 0);
   (FCustomSQLBuilder as TQueryFieldBuilder).AddRequiredFields(Result);
end;

{ TCustomSQLStringField }

function TSQLStringField.GetValueOrEmptyString: string;
begin
   if IsEmptyOrNull then
      Result := ''
   else
      Result := TypedString;
end;

function TSQLStringField.IsEmptyString: Boolean;
begin
   Result := IsEmptyOrNull or (ValueAsString = '');
end;

function TSQLStringField.GetFieldType: TFieldType;
begin
   Result := ftFieldString;
end;

{ TCustomSQLIntegerField }

function TSQLIntegerField.GetFieldType: TFieldType;
begin
   Result := ftFieldInteger;
end;

{ TCustomSQLDoubleField }

function TSQLDoubleField.GetFieldType: TFieldType;
begin
   Result := ftFieldCurrency;
end;

{ TSQLCurrencyField }

function TSQLCurrencyField.GetFieldType: TFieldType;
begin
   Result := ftFieldCurrency;
end;

{ TCustomSQLDateTimeField }

function TSQLDateTimeField.GetFieldType: TFieldType;
begin
   Result := ftFieldDateTime;
end;

{ TSQLBooleanField }

function TSQLBooleanField.GetFieldType: TFieldType;
begin
   Result := ftFieldBoolean;
end;

{ TDisplayEnumfFIeld<T> }

procedure TDisplayEnumfField<T>.AfterConstruction;
var PO: RPickOption;
begin
   inherited;
   with CustomSQL do
   begin
      New.CaseFieldOf(Self);
      for PO in T.GetPickList do
         CurrentFieldCase.When(VariantToSQLString(PO.Key)).CaseCompareThen(QuotedStr(PO.Value));
      CurrentFieldCase.CaseEnd;
   end;
end;

{ TCustomSQLVelden }

procedure TDatabaseSQLVelden.AfterConstruction;
begin
   inherited;

   SQL_Now_Field.CustomSQL          .New.SetCustomSQL(SQL_GetdDate,[]);
   SQL_TodayField.CustomSQL         .New.DateOnly(SQL_Now_Field);
   SQL_Now_Plus_1_Field.CustomSQL   .New.FieldAsStatement(SQL_Now_Field).Plus.VariantAsStatement(1);
   SQL_Today_Plus_1Field.CustomSQL  .New.FieldAsStatement(SQL_TodayField).Plus.VariantAsStatement(1);
   Dummy.CustomSQL                  .New.VariantAsStatement(1);
end;

function TDatabaseSQLVelden.GetSQLDateField(Index: Integer): TSQLDateTimeField;
begin
   Result := Items[Index] as TSQLDateTimeField;
end;

function TDatabaseSQLVelden.GetSQLIntegerField(index: Integer): TSQLIntegerField;
begin
   Result := Items[Index] as TSQLIntegerField;
end;

initialization
   GDatabaseSQLVelden := TDatabaseSQLVelden.Create(nil);

finalization
   GDatabaseSQLVelden.Free;


end.
